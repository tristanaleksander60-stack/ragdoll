--!strict
-- LOOK_V3 (19 Nov 2026, the owner: the HUD of the big ragdoll games, "down to the smallest
-- detail"). One quiet style for every piece: dark glass squares with a white picture and one word.
--   left, bottom:   SHOP, WEAPONS, LAB (big squares, stacked)
--   right, top:     MAPS and MENU (two squares side by side)
--   bottom left:    the keys as plain chips ("F Ragdoll  X Revive  Z Slow-mo  V View"), with a keyboard
--   top bar right:  a gift (REWARDS) and the "Next: <weapon> 2/3" pill with a thin bar
-- The old pieces step aside while it is on (HudPlus's big WEAPONS, deal and sandbox column, the
-- level badge, the chaos meter, the event packs, the kit's launcher column, and RAGDOLL off a touch
-- screen): they ask HudV3.active(). A phone keeps the round 5 HUD (its touch buttons are measured
-- by LayoutCheck); the windows are the same everywhere.
-- The LAB window (new) holds the sandbox controls the column had: slow-mo, first person, revive
-- all, reset, build mode and the lab view.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Client = script.Parent
local HudGate = require(Client:WaitForChild("HudGate"))
local HudPlus = require(Client:WaitForChild("HudPlus"))
local ViewMode = require(Client:WaitForChild("ViewMode"))

local HudV3 = {}

HudV3.CARD = Vector2.new(132, 120) -- px at a 1080 px tall screen
HudV3.GAP = 6
HudV3.MARGIN = 12
HudV3.GLASS = Color3.fromRGB(18, 18, 22)
HudV3.GLASS_ALPHA = 0.22
HudV3.CHIPS_H = 50

local player = Players.LocalPlayer

-- On for this screen now: LOOK_V3 and not a phone (HudGate).
HudV3.active = HudGate.active

local gui: ScreenGui? = nil
local topGui: ScreenGui? = nil
local scaleObj: UIScale? = nil
local nextLabel: TextLabel? = nil
local nextCount: TextLabel? = nil
local nextFill: Frame? = nil
local chips: Frame? = nil
-- Audit area 1: the first-visit flow (FirstVisit) holds parts back until it reveals them.
local leftCol: Frame? = nil
local rightCol: Frame? = nil
local held: { [string]: boolean } = {}
function HudV3.hold(name: string, on: boolean)
	held[name] = if on then true else nil
end

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

-- UI_3D: a square that lifts towards the pointer and sinks when pressed (a 3 px drop, its shadow
-- shrinks), springing back. Only position and a shadow: cheap on every device.
local function depth(button: GuiButton, shadow: Frame)
	-- lihfolk-ignore: findfirstchild-chain (cast only; nil-checked on the next line)
	local face = button:FindFirstChild("Face") :: Frame?
	if not face then
		return
	end
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
	local function to(y: number, s: number)
		TweenService:Create(face, info, { Position = UDim2.fromOffset(0, y) }):Play()
		TweenService:Create(shadow, info, { BackgroundTransparency = s }):Play()
	end
	button.MouseEnter:Connect(function()
		to(-2, 0.55)
	end)
	button.MouseLeave:Connect(function()
		to(0, 0.7)
	end)
	button.MouseButton1Down:Connect(function()
		to(3, 0.9)
	end)
	button.MouseButton1Up:Connect(function()
		to(-2, 0.55)
	end)
end

local function card(name: string, word: string, icon: string, parent: Instance, onActivated: () -> ()): TextButton
	local Icons = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIIcons"))
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Size = UDim2.fromOffset(HudV3.CARD.X, HudV3.CARD.Y)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(0, 4)
	shadow.BackgroundColor3 = Color3.new(0, 0, 0)
	shadow.BackgroundTransparency = 0.7
	shadow.BorderSizePixel = 0
	corner(shadow, 8)
	shadow.Parent = b
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundColor3 = HudV3.GLASS
	face.BackgroundTransparency = HudV3.GLASS_ALPHA
	face.BorderSizePixel = 0
	corner(face, 8)
	face.Parent = b
	local pic = Icons.make(icon, UDim2.fromOffset(56, 56), Color3.new(1, 1, 1))
	pic.AnchorPoint = Vector2.new(0.5, 0)
	pic.Position = UDim2.new(0.5, 0, 0, 16)
	pic.Parent = face
	local label = Instance.new("TextLabel")
	label.Name = "Word"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -12)
	label.Size = UDim2.new(1, -8, 0, 26)
	label.Font = Enum.Font.BuilderSansBold
	label.TextSize = 24
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = word
	label.Parent = face
	if Config.UI_3D then
		depth(b, shadow)
	end
	b.Activated:Connect(onActivated)
	b.Parent = parent
	return b
end

local function chip(parent: Instance, key: string, word: string, order: number)
	local f = Instance.new("Frame")
	f.Name = "Chip_" .. word
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromOffset(0, 40)
	f.AutomaticSize = Enum.AutomaticSize.X
	f.LayoutOrder = order
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 8)
	list.Parent = f
	local k = Instance.new("TextLabel")
	k.Name = "Key"
	k.Size = UDim2.fromOffset(36, 36)
	k.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
	k.BackgroundTransparency = 0.1
	k.Font = Enum.Font.BuilderSansBold
	k.TextSize = 22
	k.TextColor3 = Color3.new(1, 1, 1)
	k.Text = key
	corner(k, 6)
	k.Parent = f
	local w = Instance.new("TextLabel")
	w.Name = "Word"
	w.BackgroundTransparency = 1
	w.Size = UDim2.fromOffset(0, 36)
	w.AutomaticSize = Enum.AutomaticSize.X
	w.Font = Enum.Font.BuilderSansBold
	w.TextSize = 26
	w.TextColor3 = Color3.new(1, 1, 1)
	w.Text = word
	w.Parent = f
	f.Parent = parent
end

local function keyOf(id: string): string?
	local Keybinds = require(Shared:WaitForChild("Keybinds"))
	local badge = Keybinds.badgeOf(id)
	return if badge ~= "" then badge else nil
end

local function drawChips()
	local c = chips
	if not c then
		return
	end
	for _, child in c:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local order = 0
	for _, pair in { { "Ragdoll", "Ragdoll" }, { "ReviveAll", "Revive" }, { "SlowMo", "Slow-mo" }, { "FirstPerson", "View" } } do
		local key = keyOf(pair[1])
		if key then
			order += 1
			chip(c, key, pair[2], order)
		end
	end
end

-- The top bar's pill: "Next: <weapon>   2/3" and a thin bar under it.
local function buildTop(onRewards: () -> ())
	local Icons = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIIcons"))
	local g = Instance.new("ScreenGui")
	g.Name = "HudV3Top"
	g.ResetOnSpawn = false
	g.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
	g.DisplayOrder = 6
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(1, 0.5)
	row.Position = UDim2.new(1, -8, 0.5, 0)
	row.Size = UDim2.fromOffset(260, 44)
	row.Parent = g
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 8)
	list.Parent = row
	local gift = Instance.new("ImageButton")
	gift.Name = "Gift"
	gift.LayoutOrder = 1
	gift.Size = UDim2.fromOffset(44, 44)
	gift.BackgroundColor3 = HudV3.GLASS
	gift.BackgroundTransparency = 0.1
	gift.AutoButtonColor = true
	corner(gift, 22)
	local gp = Icons.make("gift", UDim2.fromOffset(26, 26), Color3.new(1, 1, 1))
	gp.AnchorPoint = Vector2.new(0.5, 0.5)
	gp.Position = UDim2.fromScale(0.5, 0.5)
	gp.Parent = gift
	gift.Activated:Connect(onRewards)
	gift.Parent = row
	local pill = Instance.new("Frame")
	pill.Name = "Next"
	pill.LayoutOrder = 2
	pill.Size = UDim2.fromOffset(200, 44)
	pill.BackgroundColor3 = HudV3.GLASS
	pill.BackgroundTransparency = 0.1
	corner(pill, 22)
	pill.Parent = row
	local trophy = Icons.make("crown", UDim2.fromOffset(22, 22), Color3.new(1, 1, 1))
	trophy.AnchorPoint = Vector2.new(0, 0.5)
	trophy.Position = UDim2.new(0, 12, 0.5, -3)
	trophy.Parent = pill
	local t = Instance.new("TextLabel")
	t.Name = "Title"
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(40, 6)
	t.Size = UDim2.new(1, -96, 0, 22)
	t.Font = Enum.Font.BuilderSansBold
	t.TextSize = 15
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextTruncate = Enum.TextTruncate.AtEnd
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Text = "Next"
	t.Parent = pill
	nextLabel = t
	local n = Instance.new("TextLabel")
	n.Name = "Count"
	n.BackgroundTransparency = 1
	n.AnchorPoint = Vector2.new(1, 0)
	n.Position = UDim2.new(1, -14, 0, 6)
	n.Size = UDim2.fromOffset(52, 22)
	n.Font = Enum.Font.BuilderSansBold
	n.TextSize = 15
	n.TextXAlignment = Enum.TextXAlignment.Right
	n.TextColor3 = Color3.new(1, 1, 1)
	n.Text = ""
	n.Parent = pill
	nextCount = n
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.new(0, 40, 1, -12)
	track.Size = UDim2.new(1, -54, 0, 3)
	track.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
	track.BorderSizePixel = 0
	corner(track, 2)
	track.Parent = pill
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(80, 210, 110)
	fill.BorderSizePixel = 0
	corner(fill, 2)
	fill.Parent = track
	nextFill = fill
	g.Parent = player:WaitForChild("PlayerGui")
	topGui = g
end

-- The pill's numbers: kills since the last exciting unlock, out of the step to the next one.
function HudV3.drawNext(takedowns: number)
	local owned: { [string]: boolean } = {}
	local raw = player:GetAttribute("Owned")
	if type(raw) == "string" then
		for id in string.gmatch(raw, "[^,]+") do
			owned[id] = true
		end
	end
	local toy, from = HudPlus.goalOf(takedowns, owned)
	local t, n, fill = nextLabel, nextCount, nextFill
	if not (t and n and fill) then
		return
	end
	if toy then
		local need = math.max(1, toy.unlockAt - from)
		local have = math.clamp(takedowns - from, 0, need)
		t.Text = "Next: " .. toy.short
		n.Text = string.format("%d / %d", have, need)
		TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(have / need, 1) }):Play()
	else
		t.Text = "Every weapon is yours"
		n.Text = ""
		fill.Size = UDim2.fromScale(1, 1)
	end
end

-- The LAB window: the sandbox controls as rows (a picture, a name, a line, a button on the right).
local function buildLab()
	local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
	local C = require(UI:WaitForChild("LihFolkUIComponents"))
	local Controller = require(UI:WaitForChild("LihFolkUIController"))
	local Theme = require(UI:WaitForChild("LihFolkUITheme"))
	local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
	local FirstPerson = require(Client:WaitForChild("FirstPerson"))
	local BuildController = require(Client:WaitForChild("BuildController"))
	local window = C.Window({ name = "Lab", title = "Lab", theme = "settings", icon = "sandbox", size = Vector2.new(640, 600) })
	local W = 150
	local function row(order: number, label: string, line: string, icon: string, button: string, role: string, go: () -> ()): any
		local cardObj = C.Card({ name = "Lab_" .. label, size = UDim2.new(1, 0, 0, 78), layout = "none", padding = Theme.Space.md, layoutOrder = order })
		local content = cardObj.content
		local picture = Icons.make(icon, UDim2.fromOffset(40, 40))
		picture.AnchorPoint = Vector2.new(0, 0.5)
		picture.Position = UDim2.fromScale(0, 0.5)
		picture.Parent = content
		local left = 40 + Theme.Space.md
		local textW = -(left + W + Theme.Space.lg)
		C.Text("small", label, { name = "Label", align = Enum.TextXAlignment.Left, size = UDim2.new(1, textW, 0, 26), position = UDim2.new(0, left, 0, 2), parent = content } :: any)
		C.Text("caption", line, { name = "Description", color = (Theme.Palette :: any).textLow, align = Enum.TextXAlignment.Left, size = UDim2.new(1, textW, 0, 20), position = UDim2.new(0, left, 1, -2), anchor = Vector2.new(0, 1), parent = content } :: any)
		local b = C.Button({ text = button, role = role :: any, size = UDim2.fromOffset(W, 46), parent = content, onActivated = go })
		b.root.AnchorPoint = Vector2.new(1, 0.5)
		b.root.Position = UDim2.fromScale(1, 0.5)
		cardObj.root.Parent = window.body
		return b
	end
	local function keyed(id: string, line: string): string
		local k = keyOf(id)
		return if k then line .. "  (" .. k .. ")" else line
	end
	row(1, "Slow-mo", keyed("SlowMo", "A slow-motion bubble over your lab"), "motion", "SLOW", "info", function()
		HudPlus.sandbox("SlowMo")
	end)
	local fp = row(2, "First person", keyed("FirstPerson", "See the weapon in your hands"), "eye", "OFF", "neutral", function()
		FirstPerson.toggle()
	end)
	FirstPerson.onChanged(function(on: boolean)
		fp.setText(if on then "ON" else "OFF")
		fp.setRole(if on then "go" else "neutral")
	end)
	row(3, "Revive all", keyed("ReviveAll", "Every dummy in your lab stands up again"), "heart", "REVIVE", "go", function()
		HudPlus.sandbox("Revive")
	end)
	row(4, "Reset the lab", "Clear the props and put the dummies back", "shake", "RESET", "danger", function()
		HudPlus.sandbox("Reset")
	end)
	row(5, "Build mode", "Place ramps, walls and machines", "sandbox", "BUILD", "info", function()
		Controller.closeAll()
		BuildController.toggle()
	end)
	local view = row(6, "Lab view", "Fly the camera over your lab", "camera", "OFF", "neutral", function()
		Controller.closeAll()
		ViewMode.set(if ViewMode.isLab() then "Player" else "Lab")
	end)
	ViewMode.onChanged(function()
		view.setText(if ViewMode.isLab() then "ON" else "OFF")
		view.setRole(if ViewMode.isLab() then "go" else "neutral")
	end)
	Controller.register(window)
end

local hidden = false
-- What the old HUD shows is set by its own modules (they ask HudV3.active()); the kit's launcher
-- column and the RAGDOLL pad are not, so they are kept off here.
local function step()
	local on = HudV3.active()
	local g, tg = gui, topGui
	if g then
		g.Enabled = on
	end
	if tg then
		tg.Enabled = on and not held.Top
	end
	local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
	local Controller = require(UI:WaitForChild("LihFolkUIController"))
	-- (Only ever hidden here; given back once when HudV3 goes off. Their own modules decide the rest.)
	local layer = Controller.getGui()
	local column = layer and layer:FindFirstChild("Launcher")
	local pg = player:FindFirstChild("PlayerGui")
	local pad = pg and pg:FindFirstChild("BodyPad")
	if on then
		if column and column:IsA("GuiObject") then
			column.Visible = false
		end
		if pad and pad:IsA("ScreenGui") and not ViewMode.isTouch() then
			pad.Enabled = false
		end
	elseif hidden then
		if column and column:IsA("GuiObject") then
			column.Visible = true
		end
		if pad and pad:IsA("ScreenGui") then
			pad.Enabled = true
		end
	end
	local c = chips
	if c then
		c.Visible = on and UserInputService.KeyboardEnabled and not ViewMode.isTouch() and not held.Chips
	end
	if leftCol then
		-- (Audit area 1: a newcomer keeps WEAPONS from the first second, research spec 0-5 s; Shop
		-- and Lab wait for the reveal.)
		for _, child in leftCol:GetChildren() do
			if child:IsA("GuiObject") and child.Name ~= "Weapons" then
				child.Visible = not held.Left
			end
		end
	end
	if rightCol then
		rightCol.Visible = not held.Right
	end
	local s = scaleObj
	if s then
		local h = (Workspace.CurrentCamera :: Camera).ViewportSize.Y
		s.Scale = math.clamp(h / 1080, 0.72, 1.1)
	end
	if on ~= hidden then
		hidden = on
	end
end

function HudV3.start()
	if not Config.LOOK_V3 then
		return
	end
	local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
	local Controller = require(UI:WaitForChild("LihFolkUIController"))
	local PokeController = require(Client:WaitForChild("PokeController"))
	local ProgressUI = require(Client:WaitForChild("ProgressUI"))
	buildLab()
	local g = Instance.new("ScreenGui")
	g.Name = "HudV3"
	g.ResetOnSpawn = false
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	g.DisplayOrder = 5
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = g
	local s = Instance.new("UIScale")
	s.Parent = root
	scaleObj = s
	-- (A UIScale on a full-screen frame scales from its top-left: the pieces anchor in scaled space,
	-- so the frame is sized up by 1/scale to keep the right and bottom edges where they belong.)
	RunService.RenderStepped:Connect(function()
		local k = s.Scale
		root.Size = UDim2.fromScale(1 / k, 1 / k)
	end)
	local left = Instance.new("Frame")
	left.Name = "Left"
	left.BackgroundTransparency = 1
	left.AnchorPoint = Vector2.new(0, 1)
	left.Position = UDim2.new(0, HudV3.MARGIN, 1, -(HudV3.MARGIN + HudV3.CHIPS_H + 8))
	left.Size = UDim2.fromOffset(HudV3.CARD.X, 3 * HudV3.CARD.Y + 2 * HudV3.GAP)
	left.Parent = root
	leftCol = left
	local ll = Instance.new("UIListLayout")
	ll.Padding = UDim.new(0, HudV3.GAP)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.VerticalAlignment = Enum.VerticalAlignment.Bottom
	ll.Parent = left
	card("Shop", "Shop", "shop", left, function()
		Controller.toggle("Events")
	end).LayoutOrder = 1
	card("Weapons", "Weapons", "toolbox", left, function()
		local open = (PokeController :: any).openCatalog
		if type(open) == "function" then
			open()
		end
	end).LayoutOrder = 2
	card("Lab", "Lab", "sandbox", left, function()
		Controller.toggle("Lab")
	end).LayoutOrder = 3
	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.new(1, -HudV3.MARGIN, 0, 150)
	right.Size = UDim2.fromOffset(2 * HudV3.CARD.X + HudV3.GAP, HudV3.CARD.Y)
	right.Parent = root
	rightCol = right
	local rl = Instance.new("UIListLayout")
	rl.FillDirection = Enum.FillDirection.Horizontal
	rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rl.Padding = UDim.new(0, HudV3.GAP)
	rl.SortOrder = Enum.SortOrder.LayoutOrder
	rl.Parent = right
	card("Maps", "Maps", "map", right, function()
		Controller.toggle("Maps")
	end).LayoutOrder = 1
	card("Menu", "Menu", "settings", right, function()
		Controller.toggle("Menu")
	end).LayoutOrder = 2
	local c = Instance.new("Frame")
	c.Name = "Chips"
	c.AnchorPoint = Vector2.new(0, 1)
	c.Position = UDim2.new(0, HudV3.MARGIN, 1, -HudV3.MARGIN)
	c.Size = UDim2.fromOffset(0, HudV3.CHIPS_H)
	c.AutomaticSize = Enum.AutomaticSize.X
	c.BackgroundColor3 = HudV3.GLASS
	c.BackgroundTransparency = 0.35
	corner(c, 8)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = c
	local cl = Instance.new("UIListLayout")
	cl.FillDirection = Enum.FillDirection.Horizontal
	cl.VerticalAlignment = Enum.VerticalAlignment.Center
	cl.SortOrder = Enum.SortOrder.LayoutOrder
	cl.Padding = UDim.new(0, 18)
	cl.Parent = c
	c.Parent = root
	chips = c
	drawChips()
	require(Shared:WaitForChild("Keybinds")).onChanged(drawChips)
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	buildTop(function()
		Controller.toggle("Rewards")
	end)
	local lastTakedowns = 0
	ProgressUI.onState(function(state: any)
		lastTakedowns = state.takedowns or 0
		HudV3.drawNext(lastTakedowns)
	end)
	player:GetAttributeChangedSignal("Owned"):Connect(function()
		HudV3.drawNext(lastTakedowns)
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		step()
	end)
	step()
end

-- Tests / LayoutCheck.
function HudV3.guiForTest(): (ScreenGui?, ScreenGui?)
	return gui, topGui
end

return HudV3
