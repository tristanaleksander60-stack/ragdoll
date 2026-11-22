--!strict
-- What you are shooting (round 2, N2; round 3, M2: it adds up). Two short lines, white with a dark
-- edge, just above the tool bar:
--     Skull · Stomach · Left thigh  +2
--     61% blood · pulse 92 ▼ · OUT COLD
-- The server works each hit out (VitalsService) and sends it to the one who hit. Every hit on the
-- same body adds what it hit to the top line (the newest first and brightest, the oldest dropped
-- when there is no more room, counted at the end); the bottom line follows the body live while the
-- lines show (its blood running out, its pulse, out cold or dead), the arrow showing which way the
-- pulse went since the hit before. It stays HOLD seconds after the last hit and starts over the
-- moment you hit another body. Nothing else pops up on a hit (no chart, no TAKEDOWN or COMBO).
--
-- It takes the first minute's hint's place for its moment: it says so on the Onboarding screen
-- (attribute HitLine), and the hint's own code steps it aside and back. It is not drawn while the
-- view card asks its question.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local V3 = Config.LOOK_V3 -- (LOOK_V3: the black hit card)
local Net = require(Shared:WaitForChild("Net"))
local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))

local HitInfo = {}

HitInfo.ABOVE_BAR = 12 -- px between the lines' box and the top of the tool bar
HitInfo.TEXT = 14 -- (22 Nov 2026, owner: smaller; was 18) -- px (16 on a phone): the bottom line; the top one is LEAD_UP bigger
HitInfo.TEXT_PHONE = 13
HitInfo.LEAD_UP = 2
HitInfo.MAX_W = 420 -- px, at most (less on a narrow screen: 24 px from each side)
HitInfo.MAX_W_PHONE = 280 -- (a phone: clear of GRAB and THROW on the right)
-- Its width on `screen`: on a landscape phone also clear of GRAB/SHOOT on both sides (196 px from
-- each edge, like the bar: PC LayoutCheck 19 Nov, iPhone SE).
function HitInfo.widthOn(screen: Vector2): number
	local phone = math.min(screen.X, screen.Y) <= 500
	if not phone then
		return math.min(HitInfo.MAX_W, screen.X - 48)
	end
	if screen.X > screen.Y then
		return math.min(HitInfo.MAX_W_PHONE, screen.X - 2 * 196)
	end
	return math.min(HitInfo.MAX_W_PHONE, screen.X - 24)
end
HitInfo.HEIGHT = 40 -- px: the two lines (22 Nov 2026: smaller; was 48)
if Config.LOOK_V3 then
	HitInfo.HEIGHT = 44 -- (LOOK_V3: the black card's two lines, 20 + 17, and its padding; 22 Nov 2026: smaller, was 64)
end
HitInfo.HOLD = 6 -- s fully shown after the last hit on the body
HitInfo.FADE = 0.6
HitInfo.LIVE_EVERY = 0.25 -- s between two looks at the body while the lines show
HitInfo.MAX_LISTED = 12 -- hits remembered for the top line (it shows what fits)
-- The longest one-line texts it can show (LayoutCheck measures each on every screen): the top line
-- at its biggest (one label, it never holds more than fits) and the bottom line at its longest.
HitInfo.LONGEST_TOP = { "Right femoral artery  +11", "Right leg severed  +11" }
HitInfo.LONGEST_STATUS = { "100% blood \u{00B7} pulse 188 \u{25B2} \u{00B7} OUT COLD", "100% blood \u{00B7} no pulse \u{00B7} DEAD" }

local widths: { [string]: number } = {} -- measured texts ("text|size" -> px), kept for the visit
local FINE = "#9BF5B4"
local WORRY = "#FFC25A"
local CRITICAL = "#FF7A7A"
local OLD = "#C9C4DA"
local SEP = " \u{00B7} "
local DOT = " <font color=\"" .. OLD .. "\">\u{00B7}</font> "

local function severity(fine: boolean, critical: boolean): string
	return if critical then CRITICAL elseif fine then FINE else WORRY
end

local function escape(text: string): string
	return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

-- What the server's line says: what was hit, the blood, the pulse (nil when it is in another shape).
function HitInfo.parse(line: string): (string?, number?, number?)
	local what, blood, pulse = string.match(line, "^(.-) \u{00B7} (%d+)%% blood \u{00B7} (.+)$")
	if not what then
		return nil, nil, nil
	end
	return what, tonumber(blood), tonumber(string.match(pulse, "^pulse (%d+)$"))
end

-- The bottom line in rich text: blood, pulse (nil: none) with the arrow against `before`, and the
-- body's state ("Alive" | "Unconscious" | "Dead").
function HitInfo.status(blood: number, pulse: number?, before: number?, vital: string?): string
	-- (Phase 0, Config.MILD_TEXT: "health", not blood; the server's line keeps its shape.)
	local bloodText = string.format("<font color=\"%s\">%d%% %s</font>", severity(blood >= 80, blood < 45), blood, if Config.MILD_TEXT then "health" else "blood")
	local pulseText
	if pulse and pulse > 0 and vital ~= "Dead" then
		local arrow = ""
		if before and pulse >= before + 3 then
			arrow = " \u{25B2}"
		elseif before and pulse <= before - 3 then
			arrow = " \u{25BC}"
		end
		pulseText = string.format("<font color=\"%s\">pulse %d%s</font>", severity(pulse >= 50 and pulse <= 110, pulse < 40 or pulse > 150), pulse, arrow)
	else
		pulseText = string.format("<font color=\"%s\">no pulse</font>", CRITICAL)
	end
	local tag = ""
	if vital == "Dead" then
		tag = DOT .. string.format("<font color=\"%s\">DEAD</font>", CRITICAL)
	elseif vital == "Unconscious" then
		tag = DOT .. string.format("<font color=\"%s\">OUT COLD</font>", WORRY)
	end
	return bloodText .. DOT .. pulseText .. tag
end

-- The top line: the newest hit first and brightest, then older ones while they fit in `room` px
-- at `size`; what does not fit is counted at the end ("+3"). Returns the rich text and the plain
-- text (for measuring and the tests).
function HitInfo.top(list: { string }, size: number, room: number): (string, string)
	local font = Theme.Fonts.display
	local function width(text: string): number
		local key = text .. "|" .. size
		local cached = widths[key]
		if cached then
			return cached
		end
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = font
		params.Size = size
		params.Width = 10000
		local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
		local w = if ok then (bounds :: Vector2).X else #text * size * 0.55
		widths[key] = w
		return w
	end
	local n = #list
	local shown = 0
	local plain = ""
	for count = math.min(n, 4), 1, -1 do
		local parts = {}
		for i = n, n - count + 1, -1 do
			table.insert(parts, list[i])
		end
		local text = table.concat(parts, SEP) .. (if n > count then "  +" .. (n - count) else "")
		if count == 1 or width(text) <= room then
			shown, plain = count, text
			break
		end
	end
	local rich = {}
	for i = n, n - shown + 1, -1 do
		local colour = if i == n then "#FFFFFF" else OLD
		table.insert(rich, string.format("<font color=\"%s\">%s</font>", colour, escape(list[i])))
	end
	local more = if n > shown then string.format("  <font color=\"%s\">+%d</font>", OLD, n - shown) else ""
	return table.concat(rich, DOT) .. more, plain
end

local PokeController = require(script.Parent:WaitForChild("PokeController"))
local HospitalCharts = require(script.Parent:WaitForChild("HospitalCharts"))
HitInfo.POINT_AFTER = 3 -- hit lines before the doctor's monitor is pointed out (once a visit)

local player = Players.LocalPlayer
local box: Frame? = nil
local hitBar: Frame? = nil -- (LOOK_V3: the yellow bar)
local topLabel: TextLabel? = nil
local statusLabel: TextLabel? = nil
local shownAt = 0
local fading: { Tween } = {} -- the last fade (a new hit stops it, or it would swallow the new lines)

-- The body being shot and what has hit it so far.
local version = 0 -- bumped by every hit shown (a slow measure never overwrites a newer hit)
local target: Model? = nil
local hits: { string } = {}
local lastBefore: number? = nil
local lastLine = ""

local function newLine(name: string, order: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, if order == 1 then 26 else 22)
	l.BackgroundTransparency = 1
	l.FontFace = Theme.Fonts.display
	l.TextColor3 = Color3.new(1, 1, 1)
	l.RichText = true
	l.TextTransparency = 1
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = ""
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.fromRGB(10, 10, 14)
	s.Transparency = 1
	s.Parent = l
	return l
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HitInfo"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local f = Instance.new("Frame")
	f.Name = "Lines"
	f.AnchorPoint = Vector2.new(0.5, 1)
	f.Position = UDim2.new(0.5, 0, 1, -(PokeController.height() + HitInfo.ABOVE_BAR))
	f.Size = UDim2.new(1, -48, 0, HitInfo.HEIGHT)
	f.BackgroundTransparency = 1
	f.Active = false
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(HitInfo.MAX_W, HitInfo.HEIGHT)
	limit.Parent = f
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = f
	local t = newLine("Top", 1)
	t.Parent = f
	local st = newLine("Status", 2)
	st.Parent = f
	f.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	box, topLabel, statusLabel = f, t, st
	-- LOOK_V3 (19 Nov 2026, like the big ragdoll games): the two lines in a small black box with a
	-- yellow bar on its left, hugging the text; the body part in yellow, the state in white.
	if V3 then
		f.Size = UDim2.fromOffset(0, HitInfo.HEIGHT)
		f.AutomaticSize = Enum.AutomaticSize.X
		f.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
		f.BackgroundTransparency = 1
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = f
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 9)
		pad.Parent = f
		-- (The bar hangs from the top line, not from the list's frame: the list would stack it.)
		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.Position = UDim2.new(0, -10, 0, 2)
		bar.Size = UDim2.fromOffset(3, 36)
		bar.BackgroundColor3 = Color3.fromRGB(255, 205, 64)
		bar.BackgroundTransparency = 1
		bar.BorderSizePixel = 0
		bar.Parent = t
		hitBar = bar
		for i, l in { t, st } do
			l.Size = UDim2.fromOffset(0, if i == 1 then 20 else 17) -- (22 Nov 2026: a smaller card)
			l.AutomaticSize = Enum.AutomaticSize.X
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
			l.TextSize = if i == 1 then 17 else 14
			l.TextColor3 = if i == 1 then Color3.fromRGB(255, 205, 64) else Color3.fromRGB(240, 240, 240)
			local stroke = l:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Enabled = false
			end
		end
	end
end

-- The first minute's hint steps aside while the lines show (OnboardingController reads it).
local function holdHint(on: boolean)
	local gui = player:FindFirstChild("PlayerGui") and (player.PlayerGui :: any):FindFirstChild("Onboarding")
	if gui then
		gui:SetAttribute("HitLine", if on then true else nil)
	end
end

local function setShown(alpha: number)
	local b = box
	if V3 and b then
		b.BackgroundTransparency = 0.12 + 0.88 * alpha
		local bar = hitBar
		if bar then
			bar.BackgroundTransparency = alpha
		end
	end
	for _, l in { topLabel, statusLabel } do
		if l then
			l.TextTransparency = alpha
			local stroke = l:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = alpha
			end
		end
	end
end

local function phoneNow(): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and math.min(camera.ViewportSize.X, camera.ViewportSize.Y) <= 500
end

-- The bottom line from the body as it is now (blood and pulse keep moving while it bleeds).
local function refreshStatus(fallbackBlood: number?, fallbackPulse: number?)
	local st = statusLabel
	if not st then
		return
	end
	local model = target
	local blood = model and model:GetAttribute("Blood")
	local pulse = model and model:GetAttribute("Pulse")
	local vital = model and model:GetAttribute("Vital")
	local b = if type(blood) == "number" then blood else fallbackBlood
	if not b then
		return
	end
	st.Text = HitInfo.status(b, if type(pulse) == "number" then pulse else fallbackPulse, lastBefore, if type(vital) == "string" then vital else nil)
end

-- Shows a hit (tests and LayoutCheck can call it too). before: the pulse before the hit; model:
-- the body (a new one starts the list over).
function HitInfo.show(line: string, before: number?, model: Model?)
	local f, t, st = box, topLabel, statusLabel
	if not f or not t or not st then
		return
	end
	-- Not in doctor mode (the monitor has the bar's place, and tools rest).
	if PokeController.isDoctor() then
		return
	end
	-- Round 5: not during an NPC Chase (its health bar has the middle of a phone's screen).
	if type(game:GetService("Players").LocalPlayer:GetAttribute("ChaseHP")) == "number" then
		f.Visible = false
		return
	end
	-- Not over the view card while it asks its question.
	local choice = player:FindFirstChild("PlayerGui") and (player.PlayerGui :: any):FindFirstChild("ModeChoice", true)
	if choice and choice:IsA("GuiObject") and choice.Visible then
		return
	end
	local what, blood, pulse = HitInfo.parse(line)
	if model ~= target or model == nil then
		target = model
		table.clear(hits)
	end
	if #hits >= HitInfo.MAX_LISTED then
		table.remove(hits, 1)
	end
	table.insert(hits, what or line)
	lastBefore = before
	lastLine = line
	local phone = phoneNow()
	local size = if phone then HitInfo.TEXT_PHONE else HitInfo.TEXT
	local room = HitInfo.widthOn(if workspace.CurrentCamera then workspace.CurrentCamera.ViewportSize else Vector2.new(800, 600))
	t.TextSize = size + HitInfo.LEAD_UP
	st.TextSize = size
	version += 1
	local mine = version
	-- Just above the tool bar, however tall it is right now.
	f.Position = UDim2.new(0.5, 0, 1, -(PokeController.height() + HitInfo.ABOVE_BAR))
	local limit = f:FindFirstChildOfClass("UISizeConstraint")
	if limit then
		limit.MaxSize = Vector2.new(room, HitInfo.HEIGHT)
	end
	-- The first minute's hint (same place) steps aside for the moment.
	holdHint(true)
	for _, tw in fading do
		tw:Cancel()
	end
	table.clear(fading)
	-- (Measuring can wait on the engine the first time a text is seen: a newer hit meanwhile wins.)
	local topText = HitInfo.top(hits, size + HitInfo.LEAD_UP, room)
	if version ~= mine then
		return
	end
	t.Text = topText
	if what then
		-- (The server's numbers at the hit; the body's own attributes take over as they arrive.)
		st.Text = HitInfo.status(blood :: number, pulse, before, if string.find(line, "no pulse", 1, true) then "Dead" else nil)
		refreshStatus(blood, pulse)
	else
		st.Text = ""
	end
	setShown(0)
	shownAt = os.clock()
	local shown = shownAt
	-- Live while it shows: the body's blood and pulse as they move.
	task.spawn(function()
		while shownAt == shown and os.clock() - shown < HitInfo.HOLD do
			task.wait(HitInfo.LIVE_EVERY)
			if shownAt == shown and what then
				refreshStatus(nil, nil)
			end
		end
		if shownAt ~= shown then
			return -- (a newer hit took over)
		end
		local info = TweenInfo.new(HitInfo.FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, l in { t, st } do
			table.insert(fading, TweenService:Create(l, info, { TextTransparency = 1 }))
			local stroke = l:FindFirstChildOfClass("UIStroke")
			if stroke then
				table.insert(fading, TweenService:Create(stroke, info, { Transparency = 1 }))
			end
		end
		local b = box
		if V3 and b then
			table.insert(fading, TweenService:Create(b, info, { BackgroundTransparency = 1 }))
			local bar = hitBar
			if bar then
				table.insert(fading, TweenService:Create(bar, info, { BackgroundTransparency = 1 }))
			end
		end
		for _, tw in fading do
			tw:Play()
		end
		task.wait(HitInfo.FADE)
		if shownAt == shown then
			holdHint(false) -- (the hint comes back, if it is still there)
			target = nil
			table.clear(hits)
		end
	end)
end

-- The lines' text as read (no colours): "top / status".
function HitInfo.lastText(): string
	return if topLabel and statusLabel then topLabel.ContentText .. " / " .. statusLabel.ContentText else ""
end

-- Tests: the hits listed for the body being shot, and the server's last line.
function HitInfo.listed(): ({ string }, Model?, string)
	return table.clone(hits), target, lastLine
end

function HitInfo.start()
	build()
	local lines = 0
	Net.event(Net.Names.HitInfo).OnClientEvent:Connect(function(line: unknown, model: unknown, before: unknown)
		if type(line) == "string" and #line <= 120 then
			local body = if typeof(model) == "Instance" and model:IsA("Model") then model else nil
			HitInfo.show(line, if type(before) == "number" then before else nil, body)
			-- (Counted only once the first minute is over: then doctor mode, and TOOLS, are there.)
			if not PokeController.firstMinute() and player:GetAttribute("OnboardingReady") == true then
				lines += 1
				if lines >= HitInfo.POINT_AFTER then
					HospitalCharts.pointTheWay() -- (once a visit: it remembers)
				end
			end
		end
	end)
end

return HitInfo
