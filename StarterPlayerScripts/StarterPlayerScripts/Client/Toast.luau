--!strict
-- Short messages at the top of the screen (hints, discoveries, unlocks, refusals). One at a time,
-- a short queue: a message already showing or waiting is not repeated, at most QUEUE_MAX wait, and
-- one that waited too long is dropped (it would arrive after the moment it was about).
-- Lives in the core UI safe area like the rest of the HUD (below Roblox's top bar), in the gap
-- between the top-left and top-right controls (HudSlots.toastBox), so it never covers a button: on
-- a PC that is up to WIDTH_MAX wide and two lines, on a phone the narrower gap with up to three
-- smaller lines. Either way it ends above the tool bar's pick chip (LayoutCheck checks it against
-- every control). Kit look: dusk slab, ink outline, Fredoka.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))
local HudSlots = require(script.Parent:WaitForChild("HudSlots"))

-- (10 Nov 2026, the audit: 1.8 s for every line was too short to read a long one on a phone, and
-- a short queue dropped the launch's lines: time now follows the text, more may wait, longer.)
local function showTime(text: string): number
	return math.clamp(1.6 + #text * 0.035, 2.2, 4.5) -- s on screen
end
local QUEUE_MAX = 4
local STALE = 8 -- s a message may wait before it is no longer worth showing
local TOP = 10
local HEIGHT_MAX = 76 -- two lines at 20 px
local PHONE_HEIGHT_MAX = 86 -- three lines at 18 px
local PORTRAIT_HEIGHT_MAX = 110 -- phase 0: four lines at 18 px across an upright phone (nothing cut)

local Toast = {}

type Item = { text: string, color: Color3, top: (() -> number)?, at: number, pinned: boolean?, icon: string?, onTap: (() -> ())? }

local gui: ScreenGui? = nil
local floor: (() -> number)? = nil -- the lowest a toast's bottom may reach (above the bar's chip)
local paused = false -- something sits where toasts go (the view choice card): they wait
local holds: { [string]: boolean } = {} -- who holds them back (each lets go on its own)
local minTop: (() -> number)? = nil -- a bar at the top of the screen: toasts sit below it
local goalTop: (() -> number)? = nil -- the first-visit objective line: toasts sit below it too (Audit area 1)
local current: TextLabel? = nil -- the toast on screen
local currentItem: Item? = nil
local queue: { Item } = {}
local showing: string? = nil

local function ensureGui(): ScreenGui
	if gui then
		return gui
	end
	local g = Instance.new("ScreenGui")
	g.Name = "Toasts"
	g.ResetOnSpawn = false
	g.DisplayOrder = 20
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the HUD (HudSlots)
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = g
	return g
end

local showNext: () -> ()

local function hide(label: TextLabel)
	if current ~= label then
		return -- already taken off (paused)
	end
	local reduced = Theme.isReducedMotion()
	local goal = if reduced
		then { TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1 }
		else { Position = UDim2.new(label.Position.X.Scale, label.Position.X.Offset, 0, -100) }
	local out = TweenService:Create(label, TweenInfo.new(0.2), goal)
	out:Play()
	local outline = label:FindFirstChildOfClass("UIStroke")
	if reduced and outline then
		TweenService:Create(outline, TweenInfo.new(0.2), { Transparency = 1 }):Play() -- fades with it
	end
	out.Completed:Once(function()
		if current == label then
			current = nil
			label:Destroy()
			showNext()
		end
	end)
end

function showNext()
	if paused then
		showing = nil
		return
	end
	local now = os.clock()
	local item: Item? = nil
	while #queue > 0 do
		local candidate = table.remove(queue, 1) :: Item
		if now - candidate.at <= STALE then
			item = candidate
			break
		end
	end
	if not item then
		showing = nil
		return
	end
	showing = item.text
	currentItem = item
	local g = ensureGui()
	local P = Theme.Palette
	local ctx = HudSlots.context(false, false)
	local centre, width, boxTop = HudSlots.toastBox(g.AbsoluteSize, ctx)
	local tallest = if ctx.portrait then PORTRAIT_HEIGHT_MAX elseif ctx.phone then PHONE_HEIGHT_MAX else HEIGHT_MAX
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Size = UDim2.fromOffset(0, 44)
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.TextWrapped = true
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(width, tallest)
	limit.Parent = label
	label.BackgroundColor3 = P.dusk
	label.BackgroundTransparency = 0.05
	label.TextColor3 = item.color
	label.FontFace = Theme.Fonts.display
	label.TextSize = if ctx.phone then 18 else 20
	label.TextStrokeColor3 = P.ink
	label.TextStrokeTransparency = 0.3
	local outline = Instance.new("UIStroke")
	outline.Color = P.ink
	outline.Thickness = Theme.Stroke.card
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Parent = label
	label.Text = item.text
	-- Phase 0 ("Play 2 more min for a", "Daily egg! Come" were cut): a text that still does not
	-- fit the box at its size steps down until it does (14 px at the least).
	task.defer(function()
		local size = label.TextSize
		while label.Parent and not label.TextFits and size > 14 do
			size -= 1
			label.TextSize = size
			task.wait()
		end
	end)
	current = label
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = label
	-- (V6-1: a small picture left of the line, and a tap takes the card away.)
	local iconId = item.icon
	if iconId and iconId ~= "" then
		pad.PaddingLeft = UDim.new(0, 48)
		local pic = Instance.new("ImageLabel")
		pic.Name = "Icon"
		pic.BackgroundTransparency = 1
		pic.Image = iconId
		pic.ScaleType = Enum.ScaleType.Fit
		pic.AnchorPoint = Vector2.new(0, 0.5)
		pic.Size = UDim2.fromOffset(28, 28)
		pic.Position = UDim2.new(0, -38, 0.5, 0)
		pic.Parent = label
	end
	-- (Only a card that can be switched off (a tip) takes taps, through a small x at its right edge:
	-- the rest of the card never eats a shot at a dummy behind it.)
	local onTap = item.onTap
	if onTap then
		pad.PaddingRight = UDim.new(0, 44)
		local tap = Instance.new("TextButton")
		tap.Name = "Dismiss"
		tap.Text = "\u{00D7}"
		tap.FontFace = Theme.Fonts.display
		tap.TextSize = 22
		tap.TextColor3 = Color3.fromRGB(200, 205, 215)
		tap.BackgroundTransparency = 1
		tap.Selectable = false
		tap.AnchorPoint = Vector2.new(0, 0.5)
		tap.Size = UDim2.fromOffset(40, 40)
		tap.Position = UDim2.new(1, 2, 0.5, 0)
		tap.ZIndex = 5
		tap.Parent = label
		tap.Activated:Connect(function()
			task.spawn(onTap)
			hide(label)
		end)
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.card)
	corner.Parent = label
	if Theme.V2 then
		-- (UI v2: a solid navy card lit from above, a thicker ink edge, the message's own colour as
		-- the text; it pops in a little as it lands.)
		label.BackgroundTransparency = 0
		outline.Thickness = Theme.Stroke.button
		local shine = Instance.new("UIGradient")
		shine.Rotation = 90
		shine.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 210, 225))
		shine.Parent = label
		label.TextStrokeTransparency = 0.1
		if not Theme.isReducedMotion() then
			local pop = Instance.new("UIScale")
			pop.Scale = 0.85
			pop.Parent = label
			TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end
	local y = if item.top then math.max(TOP, item.top() - g.AbsolutePosition.Y) else TOP
	if boxTop then
		y = math.max(y, boxTop)
	end
	local under = minTop
	local goal = goalTop
	if goal then
		local prev = under
		under = function(): number
			return math.max(goal(), if prev then prev() else 0)
		end
	end
	if under then
		y = math.max(y, under())
	end
	local lowest = floor
	if lowest then
		-- Pushed down below the event banner, it still stops above the tool bar and its chip.
		y = math.max(TOP, math.min(y, lowest() - tallest))
	end
	if Theme.isReducedMotion() then
		label.Position = UDim2.fromOffset(centre, y)
		label.Parent = g
	else
		label.Position = UDim2.fromOffset(centre, -100)
		label.Parent = g
		TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(centre, y),
		}):Play()
	end
	task.delay(showTime(item.text), hide, label)
end

-- Whether something holds toasts back for this reason now ("card": the view card is up).
-- Whether a toast is on screen now (phase 0: the first minute's hint steps aside for it).
function Toast.isShowing(): boolean
	return current ~= nil
end

function Toast.isHeld(reason: string): boolean
	return holds[reason] == true
end


-- Where a toast's top goes now (gui-space y): the top, or under a bar that has the top (horde).
function Toast.topY(): number
	local under = minTop
	local goal = goalTop
	if goal then
		local prev = under
		under = function(): number
			return math.max(goal(), if prev then prev() else 0)
		end
	end
	return if under then math.max(TOP, under()) else TOP
end

-- While set, messages go to fn instead (a bar that has the toast's place shows them itself).
local redirect: ((string, Color3?) -> ())? = nil
function Toast.setRedirect(fn: ((string, Color3?) -> ())?)
	redirect = fn
end

-- Whether messages go somewhere else now (a phone's horde bar shows them in its points line).
-- (Below the local it reads: above it, it read a global that was always nil.)
function Toast.isRedirected(): boolean
	return redirect ~= nil
end

-- Toasts sit below a bar at the top (the horde's) while fn is set (gui-space y), or at the top.
function Toast.setGoalTop(fn: (() -> number)?)
	goalTop = fn
end

function Toast.setMinTop(fn: (() -> number)?)
	minTop = fn
end

-- Holds new toasts back while something else uses their place (waiting ones still go stale).
-- Each holder has its own reason: they show again only once every holder has let go.
function Toast.hold(reason: string, on: boolean)
	holds[reason] = on or nil
	local any = next(holds) ~= nil
	if any ~= paused then
		Toast.setPausedRaw(any)
	end
end

-- Drops what waits (FirstVisit: what queued behind the objective line is old news by the reveal).
function Toast.clearQueue()
	table.clear(queue)
end

function Toast.setPaused(on: boolean)
	Toast.hold("card", on)
end

function Toast.setPausedRaw(on: boolean)
	paused = on
	local label = current
	if on and label then
		-- The one on screen steps aside at once (nothing may sit under the card) and waits at the
		-- front of the queue to be shown again in full.
		current = nil
		showing = nil
		label:Destroy()
		local item = currentItem
		if item then
			item.pinned = true -- it was already on screen: it is not the one to make way
			table.insert(queue, 1, item)
			while #queue > QUEUE_MAX + 1 do
				table.remove(queue)
			end
		end
	end
	if not on then
		-- What waited behind the card was not stale news: it is shown now, fresh.
		local now = os.clock()
		for _, waiting in queue do
			waiting.at = now
		end
		if not showing then
			showNext()
		end
	end
end

-- The bar tells where toasts must end (a gui-space y, asked when one shows).
function Toast.setFloor(callback: () -> number)
	floor = callback
end

-- top: the lowest screen Y (AbsolutePosition space) it may sit at, asked when it shows; for
-- messages that must clear something else at the top of the screen (the event banner).
-- icon: an image id drawn left of the text (V6-1). onTap: called when the player taps it away.
function Toast.show(text: string, color: Color3?, top: (() -> number)?, icon: string?, onTap: (() -> ())?)
	local elsewhere = redirect
	if elsewhere then
		elsewhere(text, color) -- (a bar has the toast's place: it shows the message itself)
		return
	end
	if showing == text then
		return
	end
	for _, waiting in queue do
		if waiting.text == text then
			waiting.at = os.clock() -- still wanted: keep it fresh
			return
		end
	end
	if #queue >= QUEUE_MAX then
		-- The oldest waiting message makes way (never one set aside mid-show for the view card).
		for i, waiting in queue do
			if not waiting.pinned then
				table.remove(queue, i)
				break
			end
		end
	end
	table.insert(queue, { text = text, color = color or Theme.Palette.gold, top = top, at = os.clock(), icon = icon, onTap = onTap })
	if not showing then
		showNext()
	end
end

return Toast
