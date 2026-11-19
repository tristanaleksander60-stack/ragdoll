--!strict
-- The arena game on screen (phase F): a bar at the top while a game runs (its name, who plays,
-- the time left, the score, lives as hearts), and for Red Light, Green Light the light itself, big
-- and coloured with its word (never colour alone). Points pop up under it (+100 CAUGHT!, -50 They
-- stood still!) and the end card shows the score and whether it is your best. Only what the
-- server sends is drawn; the bar is rebuilt never, only its texts change.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Places = require(Shared:WaitForChild("Places"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))
local HudSlots = require(Client:WaitForChild("HudSlots"))

local player = Players.LocalPlayer
local P = Theme.Palette

local MinigameHud = {}

-- Where the bar and the light sit (top middle of the safe area; LayoutCheck reads these).
MinigameHud.BAR_TOP = 8
MinigameHud.BAR_SIZE = Vector2.new(190, 60)
MinigameHud.TOAST_UNDER_GAP = 12 -- px between the horde bar and a toast under it (outlines 10 apart)
-- (Red Light, Green Light shows the light on the bar itself: its word in big letters in its colour
-- and the bar's outline in it too; no second box under the bar.)
local POP_Y = MinigameHud.BAR_TOP + MinigameHud.BAR_SIZE.Y + 10
-- The points line under the bar: up to two lines, as wide as the screen allows (LayoutCheck checks
-- the longest messages the server sends fit it on every screen).
MinigameHud.POP_TEXT = 22
MinigameHud.POP_LINES = 2
function MinigameHud.popWidth(screenWidth: number): number
	return math.min(screenWidth - 32, 380)
end
-- The longest bar titles (names cut to 10 letters, 7 beside a game's name, in the widest letters)
-- and their sizes. A title too wide shrinks to fit (TextScaled under a cap of its size), never
-- below TITLE_MIN: LayoutCheck measures how far each one shrinks.
MinigameHud.TITLE_MIN = 11
MinigameHud.TITLES_LONGEST = {
	{ text = "SHOOT 'EM  \u{00B7}  WWWWWWW", size = 15 },
	{ text = "WWWWWWWWWW'S GAME", size = 16 },
	{ text = "WWWWWWWWWW: GREEN", size = 16 },
	{ text = "GAME OVER \u{00B7} BEST 99999", size = 16 },
	{ text = "HORDE! KNOCK 'EM DOWN", size = 15 },
	{ text = "SUPERLONGD: READY", size = 16 },
	{ text = "GREEN LIGHT", size = 18 },
}
MinigameHud.POP_LONGEST = {
	"Knock down the ones that move on RED!",
	"Knock them down! Quick hits build a combo.",
	"-50  They stood still!",
	"-25  Only on RED!",
	"A runner got past you!",
	"SuperLongDisplayName is playing. Wait for the next round!", -- (the longest display name)
}
local showingEnd = false
local setBar: (on: boolean) -> ()

local LIGHTS = {
	Green = { color = Color3.fromRGB(60, 220, 110), text = "GREEN LIGHT", short = "GREEN" },
	Yellow = { color = Color3.fromRGB(255, 205, 40), text = "GET READY", short = "READY" },
	Red = { color = Color3.fromRGB(240, 60, 70), text = "RED LIGHT", short = "RED" },
}
local NAMES = { RLGL = "RED LIGHT, GREEN LIGHT", Shoot = "SHOOT 'EM" }

local gui: ScreenGui
local titleLabel: TextLabel
local timeLabel: TextLabel
local scoreLabel: TextLabel
local livesLabel: TextLabel
local barStroke: UIStroke
local popLabel: TextLabel
local current: { [string]: any }? = nil
local shownSeconds = -1
-- The co-op horde (HordeService) uses the same bar in the lab: how many are left, and the time.
local horde: { left: number, total: number, endsAt: number }? = nil
local HORDE_RED = Color3.fromRGB(255, 90, 90)

local function label(parent: Instance, name: string, font: Font, size: number, color: Color3, pos: UDim2, extent: UDim2, align: Enum.TextXAlignment?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.FontFace = font
	l.TextSize = size
	l.TextColor3 = color
	l.Position = pos
	l.Size = extent
	l.TextXAlignment = align or Enum.TextXAlignment.Center
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

-- The title's size (a cap: a wide name shrinks under it, never below TITLE_MIN).
local function setTitleSize(size: number)
	local fit = titleLabel:FindFirstChildOfClass("UITextSizeConstraint")
	if fit then
		fit.MaxTextSize = size
	else
		titleLabel.TextSize = size
	end
end

local function build()
	local g = Instance.new("ScreenGui")
	g.Name = "MinigameHud"
	g.ResetOnSpawn = false
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	g.DisplayOrder = 28
	g.Enabled = false
	-- The bar: top middle, under Roblox's top bar, 190 wide (clear of the chaos meter and LAB VIEW
	-- on the smallest phone; LayoutCheck measures it as "GameBar").
	local b = Instance.new("Frame")
	b.Name = "Bar"
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.new(0.5, 0, 0, MinigameHud.BAR_TOP)
	b.Size = UDim2.fromOffset(MinigameHud.BAR_SIZE.X, MinigameHud.BAR_SIZE.Y)
	b.BackgroundColor3 = P.dusk
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = P.ink
	stroke.Parent = b
	barStroke = stroke
	titleLabel = label(b, "Title", Theme.Fonts.display, 14, P.textHi, UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 18))
	-- (Shrinks to fit a wide name instead of cutting it; setTitleSize sets the cap.)
	titleLabel.TextScaled = true
	titleLabel.TextTruncate = Enum.TextTruncate.None
	local titleFit = Instance.new("UITextSizeConstraint")
	titleFit.MinTextSize = MinigameHud.TITLE_MIN
	titleFit.MaxTextSize = 14
	titleFit.Parent = titleLabel
	timeLabel = label(b, "Time", Theme.Fonts.display, 20, P.gold, UDim2.fromOffset(8, 26), UDim2.fromOffset(52, 30), Enum.TextXAlignment.Left)
	scoreLabel = label(b, "Score", Theme.Fonts.display, 22, P.textHi, UDim2.new(0.5, -35, 0, 26), UDim2.fromOffset(70, 30))
	livesLabel = label(b, "Lives", Theme.Fonts.display, 18, Color3.fromRGB(255, 110, 130), UDim2.new(1, -60, 0, 26), UDim2.fromOffset(52, 30), Enum.TextXAlignment.Right)
	b.Parent = g
	-- Points (two lines at most, wrapped, never cut off).
	popLabel = label(g, "Pop", Theme.Fonts.display, MinigameHud.POP_TEXT, P.positive, UDim2.new(0.5, 0, 0, POP_Y), UDim2.fromOffset(240, MinigameHud.POP_TEXT * MinigameHud.POP_LINES + 8))
	popLabel.AnchorPoint = Vector2.new(0.5, 0)
	popLabel.TextWrapped = true
	popLabel.TextTruncate = Enum.TextTruncate.None
	popLabel.TextYAlignment = Enum.TextYAlignment.Top
	local function fitPop()
		local camera = Workspace.CurrentCamera
		local w = if camera then camera.ViewportSize.X else 800
		popLabel.Size = UDim2.fromOffset(MinigameHud.popWidth(w), MinigameHud.POP_TEXT * MinigameHud.POP_LINES + 8)
	end
	fitPop()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPop)
	end
	local ps = Instance.new("UIStroke")
	ps.Thickness = 3
	ps.Color = P.ink
	ps.Parent = popLabel
	popLabel.TextTransparency = 1
	ps.Transparency = 1
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
end

local function show(s: { [string]: any })
	current = s
	showingEnd = false
	titleLabel.TextColor3 = P.textHi
	setBar(true)
	scoreLabel.Text = tostring(s.score)
	livesLabel.Text = if s.game == "RLGL" then string.rep("\u{2665}", math.max(0, s.lives)) else (if (s.combo or 0) > 1 then "x" .. s.combo else "")
	-- Red Light, Green Light: the light is the bar's headline (word and colour) and its outline.
	local l = if s.game == "RLGL" then LIGHTS[s.light] else nil
	if l then
		-- The player sees the light word big; anyone watching also sees whose game it is.
		local mine = s.hostId == nil or s.hostId == player.UserId
		titleLabel.Text = if mine then l.text else string.upper(string.sub(tostring(s.host), 1, 10)) .. ": " .. (l.short or l.text)
		titleLabel.TextColor3 = l.color
		setTitleSize(if mine then 18 else 16)
		barStroke.Color = l.color
		barStroke.Thickness = 4
	else
		titleLabel.Text = (NAMES[s.game] or "GAME") .. "  \u{00B7}  " .. string.upper(string.sub(tostring(s.host), 1, 7))
		setTitleSize(15)
		barStroke.Color = P.ink
		barStroke.Thickness = 3
	end
end

local function pop(text: string, good: boolean)
	popLabel.Text = text
	popLabel.TextColor3 = if good then P.positive else P.negative
	popLabel.TextTransparency = 0
	local stroke = popLabel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	popLabel.Position = UDim2.new(0.5, 0, 0, POP_Y)
	-- (Long lines stay a little longer: time to read them.)
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, if #text > 24 then 1.6 else 0.6)
	TweenService:Create(popLabel, info, { TextTransparency = 1, Position = UDim2.new(0.5, 0, 0, POP_Y - 14) }):Play()
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
end

-- While the bar is up, toasts wait (they would sit under it): the game's own news shows on the
-- bar and in the points line; what waited shows once the bar is gone.
function setBar(on: boolean)
	if gui.Enabled ~= on then
		gui.Enabled = on
	end
	-- An arena game's own news is on its bar and points line: toasts wait. The horde is a minute
	-- in the lab: toasts go on, below its bar (TOAST_UNDER_GAP clear of it), except on a phone,
	-- where the screen is too short for a toast between the horde bar and the tool bar: there each
	-- toast shows in the bar's own points line instead (a nuke, a refusal: never a minute late).
	local arena = (on and current ~= nil) or showingEnd
	local phone = HudSlots.context(false, false).phone
	Toast.hold("GameBar", on and arena)
	Toast.setRedirect(if on and not arena and phone then function(text: string)
		pop(text, true)
	end else nil)
	Toast.setMinTop(if on and not arena and not phone then function(): number
		return MinigameHud.BAR_TOP + MinigameHud.BAR_SIZE.Y + MinigameHud.TOAST_UNDER_GAP
	end else nil)
end

-- On the ground (your lab, the plaza, someone's lab): where the horde runs.
local function inLab(): boolean
	local place = player:GetAttribute("Place")
	return place == nil or Places.onGround(place)
end

-- The horde on the bar (only in the lab, and never over an arena game).
local function showHorde()
	local h = horde
	if current or showingEnd then
		return
	end
	if not h or not inLab() then
		setBar(false)
		return
	end
	titleLabel.Text = "HORDE! KNOCK 'EM DOWN"
	titleLabel.TextColor3 = HORDE_RED
	setTitleSize(15)
	barStroke.Color = HORDE_RED
	barStroke.Thickness = 4
	scoreLabel.Text = tostring(h.left)
	livesLabel.Text = "LEFT"
	setBar(true)
end

function MinigameHud.start()
	build()
	local remote = Net.event(Net.Names.Minigame)
	remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if type(data) ~= "table" then
			return
		end
		local d = data :: any
		if kind == "State" then
			show(d)
		elseif kind == "Pop" and type(d.text) == "string" then
			pop(d.text, d.good == true)
		elseif kind == "Refused" and type(d.text) == "string" then
			if gui.Enabled then
				pop(d.text, false)
			else
				Toast.show(d.text)
			end
		elseif kind == "End" then
			-- The result stays on the bar itself for a few seconds (never under a toast).
			current = nil
			showingEnd = true
			barStroke.Color = P.ink
			barStroke.Thickness = 3
			setTitleSize(16)
			local mine = d.hostId == player.UserId
			-- (Short enough for the 190 px bar: the result, not the game's long name.)
			titleLabel.Text = if mine and d.newBest then "NEW BEST!" elseif mine then string.format("GAME OVER \u{00B7} BEST %d", d.best or 0) else string.upper(string.sub(tostring(d.host), 1, 10)) .. "'S GAME"
			titleLabel.TextColor3 = if mine and d.newBest then P.gold else P.textHi
			scoreLabel.Text = tostring(d.score or 0)
			timeLabel.Text = "END"
			livesLabel.Text = ""
			setBar(true)
			task.delay(4, function()
				if not current and showingEnd then
					showingEnd = false
					setBar(false)
					titleLabel.TextColor3 = P.textHi
					showHorde()
				end
			end)
		end
	end)
	local hordeRemote = Net.event(Net.Names.Horde)
	hordeRemote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		local d = if type(data) == "table" then data :: any else {}
		if kind == "HordeStart" then
			local total = tonumber(d.total) or 0
			horde = { left = total, total = total, endsAt = os.clock() + (tonumber(d.seconds) or 60) }
			shownSeconds = -1
			showHorde()
		elseif kind == "HordeLeft" and horde then
			(horde :: any).left = tonumber(d.left) or 0
			showHorde()
		elseif kind == "HordeEnd" or kind == "HordeCancelled" then
			horde = nil
			if not current and not showingEnd then
				setBar(false)
			end
		end
	end)
	hordeRemote:FireServer("Hello") -- (joined during a horde: its bar now)
	-- The clock, once a second (only the text changes).
	RunService.Heartbeat:Connect(function()
		local s = current
		if not s then
			local h = horde
			if h and gui.Enabled and not showingEnd then
				local left = math.max(0, math.ceil(h.endsAt - os.clock()))
				if left ~= shownSeconds then
					shownSeconds = left
					timeLabel.Text = string.format("%d:%02d", left // 60, left % 60)
				end
			end
			return
		end
		local left = math.max(0, math.ceil((s.endsAt or 0) - Workspace:GetServerTimeNow()))
		if left ~= shownSeconds then
			shownSeconds = left
			timeLabel.Text = string.format("%d:%02d", left // 60, left % 60)
		end
	end)
	-- Leaving the arena hides it.
	player:GetAttributeChangedSignal("Place"):Connect(function()
		if player:GetAttribute("Place") ~= "Arena" then
			current = nil
			showingEnd = false
			setBar(false)
		end
		showHorde() -- (back in the lab during a horde: its bar again)
	end)
end

return MinigameHud
