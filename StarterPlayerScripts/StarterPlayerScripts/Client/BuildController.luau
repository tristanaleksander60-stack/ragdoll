--!strict
-- The Workshop on the client: build mode, the parts drawer, the tools and the placement ghost.
-- Phone first: a tap places (or deletes, paints, tunes, wires, pins), a drag still turns the camera,
-- and every control is a big thumb-sized button. The server owns the blueprint (BuildService);
-- this only asks for operations and shows the result.
--
-- Pointer routing comes from LabCamera:
--   pressAt(at)  while playing, a press on one of your Buttons presses it
--   tapAt(at)    in build mode, a tap uses the current tool

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Build = Shared:WaitForChild("Build")
local Catalog = require(Build:WaitForChild("Catalog"))
local Orientation = require(Build:WaitForChild("Orientation"))
local Factory = require(Build:WaitForChild("Factory"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))

local Client = script.Parent
local PokeController = require(Client:WaitForChild("PokeController"))
local Toast = require(Client:WaitForChild("Toast"))
local SaveController = require(Client:WaitForChild("SaveController"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local HudSlots = require(Client:WaitForChild("HudSlots"))
local ReplayController = require(Client:WaitForChild("ReplayController"))
local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))
local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController"))
local Icons = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIIcons"))

local player = Players.LocalPlayer

type Tool = "Place" | "Delete" | "Paint" | "Tune" | "Wire" | "Pin"

local BuildController = {}

-- Dark glass (round 2, N5): the drawer and palette are the kit's panel, buttons the HUD's dark slab,
-- the picked tool lit in its own colour (darkened so white text reads on it), gold only for the
-- picked part and the wire being drawn.
local DARK = Theme.Palette.dusk
local IDLE = KitStyle.SLAB
local ACCENT = Theme.Palette.gold
local RAIL_CHIP = 20 -- px: a rail button's key chip (its word keeps clear of it)
local TOOL_COLORS: { [Tool]: Color3 } = {
	Place = Color3.fromRGB(120, 230, 140),
	Delete = Color3.fromRGB(255, 90, 70),
	Paint = Color3.fromRGB(255, 120, 190),
	Tune = Color3.fromRGB(80, 170, 255),
	Wire = Color3.fromRGB(255, 205, 60),
	Pin = Color3.fromRGB(170, 110, 240),
}

-- State
local active = false -- build mode on
local playing = false
local tool: Tool = "Place"
local category: Catalog.Category = "Blocks"
local selectedItem = "Block"
local blockRot = 0 -- rotation for blocks (0-23)
local turn = 0 -- quarter turns around the surface normal for parts that stand on it
local paintColor = 3
local paintChosen = false -- until you pick a paint, parts come in their own colors
local wireFrom: number? = nil
local pieceCount = 0
local wires: { { number } } = {}
local busy = false
local toyBarWasOn = true
local ownsToyBar = false -- build mode has taken over the toy bar
local ownsToastFloor = false -- build mode pushed toasts under BUILD/PLAY (an upright phone)
local unlocked = false -- the first minute is over: build mode can be opened
local sandboxHud: any = nil -- the left column's SANDBOX (round 2, N5)

-- UI
local gui: ScreenGui
local modeButton: TextButton
local playButton: TextButton
local drawer: Frame
local tabsRow: Frame
local itemsRow: ScrollingFrame
local rail: Frame
local palette: Frame
local counter: TextLabel
local toolButtons: { [string]: TextButton } = {}
local tabButtons: { [string]: TextButton } = {}
local itemCards: { [string]: TextButton } = {}
local keyHints: { [string]: TextLabel } = {} -- rail button name -> its key chip (keyboards)
local RAIL_KEYS: { [string]: string } = {
	Place = "ToolPlace", Delete = "ToolDelete", Paint = "ToolPaint", Tune = "ToolTune", Wire = "ToolWire", Pin = "ToolPin",
	Turn = "Turn", Tilt = "Tilt", Undo = "Undo", Saves = "Saves",
}
local TOOL_ORDER: { Tool } = { "Place", "Delete", "Paint", "Tune", "Wire", "Pin" }

-- World visuals
local ghost: Model? = nil
local ghostKey = ""
local hoverHighlight: Highlight
local wireFolder: Folder

-- Your build stands in your own lab (the server says where: LabOrigin on you; the plaza's, on the
-- Workspace, when you have no lab).
local function buildOrigin(): Vector3
	local o = Players.LocalPlayer:GetAttribute("LabOrigin")
	if typeof(o) ~= "Vector3" then
		o = Workspace:GetAttribute("LabOrigin")
	end
	if typeof(o) ~= "Vector3" then
		return Vector3.zero
	end
	return Vector3.new(math.round(o.X), 0, math.round(o.Z))
end

local function myFolder(): Folder?
	local builds = Workspace:FindFirstChild("Builds")
	local f = builds and builds:FindFirstChild(tostring(player.UserId))
	return if f and f:IsA("Folder") then f else nil
end

local function modelOfIndex(index: number): Model?
	local folder = myFolder()
	if not folder then
		return nil
	end
	for _, m in folder:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("Piece") == index then
			return m
		end
	end
	return nil
end

-- The piece of my build a part belongs to: (model, piece index, part BuildIndex).
local function myPieceOf(part: Instance): (Model?, number?, number?)
	local folder = myFolder()
	if not folder or not part:IsDescendantOf(folder) then
		return nil, nil, nil
	end
	local model = part:FindFirstAncestorOfClass("Model")
	while model and model.Parent ~= folder do
		model = model:FindFirstAncestorOfClass("Model")
	end
	if not model then
		return nil, nil, nil
	end
	return model, model:GetAttribute("Piece") :: number?, part:GetAttribute("BuildIndex") :: number?
end

local function isDummyOrProp(part: Instance): boolean
	local m = part:FindFirstAncestorOfClass("Model")
	while m do
		if m:GetAttribute("IsDummy") == true then
			return true
		end
		m = m:FindFirstAncestorOfClass("Model")
	end
	local props = Workspace:FindFirstChild("Props")
	return props ~= nil and part:IsDescendantOf(props)
end

local function raycast(at: Vector2): RaycastResult?
	local camera = Workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(at.X, at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local fx = Workspace:FindFirstChild("LocalFx")
	if fx then
		table.insert(ignore, fx)
	end
	if ghost then
		table.insert(ignore, ghost)
	end
	table.insert(ignore, wireFolder)
	params.FilterDescendantsInstances = ignore
	return Workspace:Raycast(ray.Origin, ray.Direction * 400, params)
end

------------------------------------------------------------------------------------------------
-- Placement

type Placement = { pos: Vector3, rot: number, parent: number, parentPart: number, ok: boolean }

local function placementAt(at: Vector2): Placement?
	local result = raycast(at)
	if not result or isDummyOrProp(result.Instance) then
		return nil
	end
	local item = Catalog.byId[selectedItem]
	local parent, parentPart = 0, 1
	local _, index, partIndex = myPieceOf(result.Instance)
	if index then
		parent = index
		parentPart = partIndex or 1
	elseif result.Instance:FindFirstAncestor("Builds") then
		return nil -- someone else's build
	end
	local normal = Orientation.snapAxis(result.Normal)
	local rot = if item.facesOut then Orientation.facingUp(normal, turn) else blockRot
	local ext = Orientation.extents(rot, item.size)
	local origin = buildOrigin()
	local p = result.Position - origin
	local function axisSnap(value: number, extent: number): number
		return math.round(value - extent / 2) + extent / 2
	end
	local x = axisSnap(p.X, ext.X)
	local y = axisSnap(p.Y, ext.Y)
	local z = axisSnap(p.Z, ext.Z)
	-- Along the normal, sit exactly on the surface that was hit.
	local surface = math.round(p:Dot(normal) * 2) / 2
	local extentAlong = math.abs(normal.X) * ext.X + math.abs(normal.Y) * ext.Y + math.abs(normal.Z) * ext.Z
	local along = surface + extentAlong / 2
	if math.abs(normal.X) > 0.5 then
		x = along * normal.X
	elseif math.abs(normal.Y) > 0.5 then
		y = along * normal.Y
	else
		z = along * normal.Z
	end
	local pos = Vector3.new(x, y, z)
	local flat = Vector3.new(pos.X, 0, pos.Z)
	local ok = flat.Magnitude <= Catalog.BUILD_RADIUS and pos.Y >= -2 and pos.Y <= Catalog.BUILD_HEIGHT and pieceCount < Catalog.MAX_PARTS
	return { pos = pos, rot = rot, parent = parent, parentPart = parentPart, ok = ok }
end

local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	ghostKey = ""
end

local function showGhost(placement: Placement?)
	if not placement or tool ~= "Place" then
		clearGhost()
		return
	end
	local key = string.format("%s|%s|%d|%s", selectedItem, tostring(placement.pos), placement.rot, tostring(placement.ok))
	if key == ghostKey and ghost then
		return
	end
	clearGhost()
	ghostKey = key
	local model = Factory.build({
		item = selectedItem,
		pos = placement.pos,
		rot = placement.rot,
		color = 0,
		setting = 1,
		pinned = true,
		parent = 0,
		parentPart = 1,
	}, buildOrigin())
	Factory.ghost(model, placement.ok)
	model.Name = "BuildGhost"
	model.Parent = Workspace:FindFirstChild("LocalFx") or Workspace
	ghost = model
end

------------------------------------------------------------------------------------------------
-- Requests

local request: RemoteFunction

local function ask(op: string, args: { [string]: any }?): (boolean, string?)
	if busy then
		return false, nil
	end
	busy = true
	local okCall, success, message = pcall(function()
		return request:InvokeServer(op, args or {})
	end)
	busy = false
	if not okCall then
		Toast.show("Could not reach the server")
		return false, nil
	end
	if not success and message then
		Toast.show(message, Color3.fromRGB(255, 120, 100))
	end
	return success, message
end

local function pop(object: GuiObject)
	local s = Instance.new("UIScale")
	s.Scale = 0.88
	s.Parent = object
	local t = TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 })
	t:Play()
	t.Completed:Once(function()
		s:Destroy()
	end)
end

------------------------------------------------------------------------------------------------
-- Wires (shown in build mode)

local function drawWires()
	wireFolder:ClearAllChildren()
	if not active or playing then
		return
	end
	for _, w in wires do
		local a, b = modelOfIndex(w[1]), modelOfIndex(w[2])
		local pa, pb = a and a.PrimaryPart, b and b.PrimaryPart
		if pa and pb then
			local a0 = Instance.new("Attachment")
			a0.WorldPosition = pa.Position
			local a1 = Instance.new("Attachment")
			a1.WorldPosition = pb.Position
			local holder = Instance.new("Part")
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanQuery = false
			holder.CanTouch = false
			holder.Transparency = 1
			holder.Size = Vector3.one * 0.1
			holder.CFrame = CFrame.new()
			a0.Parent = holder
			a1.Parent = holder
			local beam = Instance.new("Beam")
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Width0 = 0.25
			beam.Width1 = 0.25
			beam.CurveSize0 = 3
			beam.CurveSize1 = -3
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.Color = ColorSequence.new(ACCENT)
			beam.Transparency = NumberSequence.new(0.15)
			beam.Parent = holder
			holder.Parent = wireFolder
		end
	end
end

------------------------------------------------------------------------------------------------
-- UI

local function setTool(t: Tool)
	tool = t
	wireFrom = nil
	for name, button in toolButtons do
		local color = TOOL_COLORS[name :: Tool]
		if color then
			local on = name == t
			button.BackgroundColor3 = if on then color:Lerp(Color3.new(0, 0, 0), 0.3) else IDLE
			KitStyle.button(button)
		end
	end
	palette.Visible = active and t == "Paint"
	drawer.Visible = active and not playing and t == "Place"
	if t ~= "Place" then
		clearGhost()
	end
end

local function refreshItems()
	for id, card in itemCards do
		local item = Catalog.byId[id]
		card.Visible = item.category == category
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if id == selectedItem then ACCENT else Color3.fromRGB(90, 90, 104)
			stroke.Thickness = if id == selectedItem then 3 else 1
		end
	end
	for name, tab in tabButtons do
		local on = name == category
		tab.BackgroundColor3 = if on then KitStyle.PICK else IDLE
		KitStyle.button(tab)
	end
	itemsRow.CanvasPosition = Vector2.zero
end

-- SANDBOX opens build mode from the left column (round 2, N5) where the column shows (tablets
-- and computers); a phone's column is just MENU, so there the BUILD button opens it. While
-- building, the button reads DONE everywhere (the way out sits by PLAY).
local function modeShown(): boolean
	if not unlocked then
		return false
	end
	-- (Off a phone the column's SANDBOX tile reads DONE while building: one way out, not two.)
	-- Phase 0: a phone starts building from MENU's SANDBOX; the button shows only while building
	-- (the way back to playing), so the first minute has one button less.
	return HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()).phone and active
end

local function refreshMode()
	modeButton.Visible = modeShown()
	local tile = sandboxHud
	if tile then
		tile.setCaption(if active then "Done" else nil)
		tile.setLit(active)
	end
	modeButton.Text = if active then "DONE" else "BUILD"
	modeButton.BackgroundColor3 = KitStyle.GO
	KitStyle.button(modeButton)
	playButton.Visible = active
	playButton.Text = if playing then "STOP" else "PLAY"
	playButton.BackgroundColor3 = if playing then KitStyle.STOP else KitStyle.GO
	KitStyle.button(playButton)
	rail.Visible = active and not playing
	counter.Visible = active
	Players.LocalPlayer:SetAttribute("Building", active) -- (a phone's chaos meter steps aside: ChaosMeter)
	-- A phone held upright: BUILD/PLAY have the toasts' top row, so toasts go under them while
	-- building (on a phone nothing else sets the toast floor: MinigameHud redirects there).
	local upright = HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()).portrait == true
	if active and upright then
		Toast.setMinTop(function(): number
			return HudSlots.PORTRAIT_TOAST_TOP + HudSlots.PORTRAIT_BUILD_ROW
		end)
		ownsToastFloor = true
	elseif ownsToastFloor then
		Toast.setMinTop(nil)
		ownsToastFloor = false
	end
	counter.Text = string.format("%d/%d parts", pieceCount, Catalog.MAX_PARTS)
	setTool(tool)
	-- While building, the toy bar steps aside; while playing your machine, it is back.
	if active then
		PokeController.setEnabled(playing)
	elseif ownsToyBar then
		PokeController.setEnabled(toyBarWasOn)
	end
	ownsToyBar = active
	drawWires()
end

local function corner(object: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = object
end

local function button(name: string, text: string, size: UDim2, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.BackgroundColor3 = color
	b.Text = text
	b.AutoButtonColor = true
	KitStyle.button(b)
	return b
end

-- A small 3D picture of a catalog item.
local function thumbnail(item: Catalog.Item, parent: GuiObject)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Picture"
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.new(1, -8, 1, -26)
	vp.Position = UDim2.fromOffset(4, 4)
	vp.Ambient = Color3.fromRGB(170, 170, 180)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-1, -2, -1)
	local model = Factory.build({ item = item.id, pos = Vector3.zero, rot = 0, color = 0, setting = 1, pinned = true, parent = 0, parentPart = 1 }, Vector3.zero)
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	model.Parent = vp
	local cam = Instance.new("Camera")
	local radius = item.size.Magnitude / 2
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(1, 0.8, 1.3).Unit * radius * 3.1, Vector3.zero)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
end

local function buildUi()
	gui = Instance.new("ScreenGui")
	gui.Name = "Workshop"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)

	modeButton = button("Mode", "BUILD", UDim2.fromOffset(92, 56), KitStyle.GO)
	KitStyle.icon(modeButton, KitStyle.HUD_ICONS.Mode, "top") -- (UI v2: the crate over the word)
	modeButton.AnchorPoint = Vector2.new(0, 1)
	modeButton.Position = UDim2.new(0, 14, 1, -14)
	modeButton.Visible = false
	modeButton.Parent = gui

	playButton = button("Play", "PLAY", UDim2.fromOffset(92, 56), KitStyle.GO)
	KitStyle.icon(playButton, KitStyle.HUD_ICONS.Play, "top")
	playButton.AnchorPoint = Vector2.new(0, 1)
	playButton.Position = UDim2.new(0, 14, 1, -80)
	playButton.Visible = false
	playButton.Parent = gui

	counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	-- (On a small dark-glass pill, as the HUD's other words are.)
	counter.BackgroundColor3 = Theme.Palette.dusk
	counter.BackgroundTransparency = Theme.Glass.panel
	local counterCorner = Instance.new("UICorner")
	counterCorner.CornerRadius = UDim.new(0, 4)
	counterCorner.Parent = counter
	counter.AnchorPoint = Vector2.new(0, 1)
	counter.Position = UDim2.new(0, 118, 1, -104) -- (placed by HudSlots "Counter")
	counter.Size = UDim2.fromOffset(90, 18)
	counter.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	counter.TextSize = 13
	counter.TextXAlignment = Enum.TextXAlignment.Center
	counter.TextColor3 = Theme.Palette.textHi
	counter.TextStrokeTransparency = 1
	counter.Visible = false
	counter.Parent = gui

	-- Drawer: category tabs over a row of part cards.
	drawer = Instance.new("Frame")
	drawer.Name = "Drawer"
	drawer.AnchorPoint = Vector2.new(0.5, 1)
	drawer.Position = UDim2.new(0.5, 0, 1, -10)
	drawer.Size = UDim2.new(1, -340, 0, 140)
	drawer.BackgroundColor3 = DARK
	drawer.BackgroundTransparency = 0.15
	drawer.Visible = false
	drawer.Parent = gui
	corner(drawer, 16)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(820, 140)
	limit.Parent = drawer

	tabsRow = Instance.new("Frame")
	tabsRow.Name = "Tabs"
	tabsRow.BackgroundTransparency = 1
	tabsRow.Position = UDim2.fromOffset(8, 6)
	tabsRow.Size = UDim2.new(1, -16, 0, 30)
	tabsRow.Parent = drawer
	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.Padding = UDim.new(0, 6)
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Parent = tabsRow
	for i, cat in Catalog.categories do
		local tab = button(cat, cat, UDim2.fromOffset(96, 30), IDLE)
		tab.LayoutOrder = i
		tab.TextSize = 14
		tab.TextColor3 = Color3.new(1, 1, 1)
		tab.Parent = tabsRow
		tab.Activated:Connect(function()
			BuildController.selectCategory(cat)
		end)
		tabButtons[cat] = tab
	end

	itemsRow = Instance.new("ScrollingFrame")
	itemsRow.Name = "Items"
	itemsRow.BackgroundTransparency = 1
	itemsRow.BorderSizePixel = 0
	itemsRow.Position = UDim2.fromOffset(8, 40)
	itemsRow.Size = UDim2.new(1, -16, 0, 94)
	itemsRow.ScrollingDirection = Enum.ScrollingDirection.X
	itemsRow.ScrollBarThickness = 4
	itemsRow.AutomaticCanvasSize = Enum.AutomaticSize.X
	itemsRow.CanvasSize = UDim2.new()
	itemsRow.Parent = drawer
	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.FillDirection = Enum.FillDirection.Horizontal
	itemsLayout.Padding = UDim.new(0, 8)
	itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemsLayout.Parent = itemsRow
	for i, item in Catalog.list do
		local card = Instance.new("TextButton")
		card.Name = item.id
		card.LayoutOrder = i
		card.Size = UDim2.fromOffset(84, 86)
		card.BackgroundColor3 = IDLE
		card.Text = ""
		card.AutoButtonColor = true
		corner(card, 12)
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = card
		thumbnail(item, card)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 1, -3)
		label.Size = UDim2.new(1, -4, 0, 18)
		label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
		label.TextSize = 12
		label.TextScaled = false
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = item.label
		label.Parent = card
		card.Parent = itemsRow
		card.Activated:Connect(function()
			BuildController.selectItem(item.id)
		end)
		itemCards[item.id] = card
	end

	-- Tool rail on the right.
	rail = Instance.new("Frame")
	rail.Name = "Tools"
	rail.AnchorPoint = Vector2.new(1, 0)
	rail.Position = UDim2.new(1, -12, 0, 64)
	rail.Size = UDim2.fromOffset(150, 0)
	rail.AutomaticSize = Enum.AutomaticSize.Y
	rail.BackgroundTransparency = 1
	rail.Visible = false
	rail.Parent = gui
	local railLayout = Instance.new("UIGridLayout")
	railLayout.CellSize = UDim2.fromOffset(72, 44)
	railLayout.CellPadding = UDim2.fromOffset(6, 6)
	railLayout.FillDirectionMaxCells = 2
	railLayout.SortOrder = Enum.SortOrder.LayoutOrder
	railLayout.Parent = rail
	local order = 0
	local function railButton(name: string, text: string, onClick: () -> ())
		order += 1
		local b = button(name, text, UDim2.fromOffset(76, 44), IDLE)
		b.LayoutOrder = order
		b.TextColor3 = Color3.new(1, 1, 1)
		-- The word fits beside the key chip in the top right corner (never under it): scaled into
		-- the room left of it, 11 px at the least.
		b.TextScaled = true
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = 17
		fit.MinTextSize = 11
		fit.Parent = b
		local room = Instance.new("UIPadding")
		room.PaddingLeft = UDim.new(0, 4)
		room.PaddingRight = UDim.new(0, if RAIL_KEYS[name] then RAIL_CHIP + 2 else 4)
		room.PaddingTop = UDim.new(0, 8)
		room.PaddingBottom = UDim.new(0, 8)
		room.Parent = b
		b.Parent = rail
		if RAIL_KEYS[name] then
			-- The key for it, in the corner (only with a keyboard).
			local chip = Instance.new("TextLabel")
			chip.Name = "KeyHint"
			chip.AnchorPoint = Vector2.new(1, 0)
			chip.Position = UDim2.new(1, RAIL_CHIP + 2 - 3, 0, 3 - 8) -- (the button's padding moves it in)
			chip.Size = UDim2.fromOffset(RAIL_CHIP, 18)
			chip.BackgroundColor3 = Color3.fromRGB(5, 6, 8)
			chip.BackgroundTransparency = 0.2
			chip.TextColor3 = ACCENT
			chip.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
			chip.TextSize = 14
			chip.AutomaticSize = Enum.AutomaticSize.X
			chip.ZIndex = b.ZIndex + 2
			corner(chip, 4)
			chip.Parent = b
			keyHints[name] = chip
		end
		b.Activated:Connect(function()
			pop(b)
			onClick()
		end)
		toolButtons[name] = b
	end
	for _, t in { "Place", "Delete", "Paint", "Tune", "Wire", "Pin" } :: { Tool } do
		railButton(t, t, function()
			setTool(t)
			if t == "Wire" then
				Toast.show("Tap a button, timer or sensor, then what it should switch")
			elseif t == "Pin" then
				Toast.show("Tap a part on the floor to pin it down or set it free")
			elseif t == "Tune" then
				Toast.show("Tap a motor, piston, wheel or timer to change it")
			end
		end)
	end
	railButton("Turn", "Turn", function()
		BuildController.turnPart()
	end)
	railButton("Tilt", "Tilt", function()
		BuildController.tiltPart()
	end)
	railButton("Undo", "Undo", function()
		ask("undo")
	end)
	railButton("Saves", "Saves", function()
		clearGhost()
		SaveController.open()
	end)


	-- Paint colors.
	palette = Instance.new("Frame")
	palette.Name = "Palette"
	palette.AnchorPoint = Vector2.new(0.5, 1)
	palette.Position = UDim2.new(0.5, 0, 1, -14)
	palette.Size = UDim2.fromOffset(#Catalog.palette * 46 + 12, 56)
	palette.BackgroundColor3 = DARK
	palette.BackgroundTransparency = 0.15
	palette.Visible = false
	palette.Parent = gui
	corner(palette, 16)
	local paletteLayout = Instance.new("UIListLayout")
	paletteLayout.FillDirection = Enum.FillDirection.Horizontal
	paletteLayout.Padding = UDim.new(0, 6)
	paletteLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	paletteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	paletteLayout.Parent = palette
	for i, color in Catalog.palette do
		local dot = Instance.new("TextButton")
		dot.Name = "Color" .. i
		dot.Text = ""
		dot.Size = UDim2.fromOffset(40, 40)
		dot.BackgroundColor3 = color
		dot.LayoutOrder = i
		corner(dot, 20)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = if i == paintColor then 3 else 1
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Parent = dot
		dot.Parent = palette
		dot.Activated:Connect(function()
			BuildController.setPaint(i)
		end)
	end

	modeButton.Activated:Connect(function()
		BuildController.toggle()
	end)
	playButton.Activated:Connect(function()
		pop(playButton)
		ask(if playing then "stop" else "play")
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
	refreshItems()

	-- SANDBOX in the left column: a crate as its picture (the hand-drawn one, Shared.DrawnIcons;
	-- the workshop's 3D crate without it).
	local drawn = Icons.has("sandbox")
	local picture: Frame? = nil
	if not drawn then
		local crate = Instance.new("Frame")
		crate.Name = "Crate"
		crate.BackgroundTransparency = 1
		crate.Size = UDim2.fromScale(1, 1)
		thumbnail(Catalog.byId.Crate, crate)
		local vp = crate:FindFirstChild("Picture") :: ViewportFrame?
		if vp then
			vp.Size = UDim2.fromScale(1, 1)
			vp.Position = UDim2.new()
		end
		picture = crate
	end
	Controller.setHudShown("Sandbox", unlocked)
	sandboxHud = Controller.addHudButton({
		label = "Sandbox",
		icon = if drawn then "sandbox" else "toolbox",
		theme = "neutral",
		layoutOrder = 3,
		picture = picture,
		onActivated = function()
			BuildController.toggle()
		end,
	})
end

-- BUILD, PLAY and the part counter sit where HudSlots puts them (on a phone, around the Events
-- launcher: the thumbstick owns the bottom-left corner and the screen is short).
local function layoutForView()
	if not modeButton then
		return
	end
	local ctx = HudSlots.context(ViewMode.isTouch(), ViewMode.isLab())
	HudSlots.apply(modeButton, "Mode", ctx)
	modeButton.Visible = modeShown()
	HudSlots.apply(playButton, "Play", ctx)
	HudSlots.apply(counter, "Counter", ctx)
end

------------------------------------------------------------------------------------------------
-- Pointer routing (called by LabCamera)

-- A press while playing: your own Button pieces can be pressed. Returns true if used.
function BuildController.pressAt(at: Vector2): boolean
	if not playing then
		return false
	end
	local result = raycast(at)
	if not result then
		return false
	end
	local model, index = myPieceOf(result.Instance)
	if model and index and model:GetAttribute("Item") == "Button" then
		Net.event(Net.Names.BuildSignal):FireServer("Press", index)
		return true
	end
	return false
end

-- A tap in build mode uses the current tool. Returns true if build mode handled it.
function BuildController.tapAt(at: Vector2): boolean
	if not active or playing then
		return false
	end
	if tool == "Place" then
		local placement = placementAt(at)
		if not placement then
			return true
		end
		if not placement.ok then
			Toast.show(if pieceCount >= Catalog.MAX_PARTS then "Your build is full" else "Too far from the lab", Color3.fromRGB(255, 120, 100))
			return true
		end
		local color = if Catalog.byId[selectedItem].paintable and paintChosen then paintColor else 0
		ask("place", { item = selectedItem, pos = placement.pos, rot = placement.rot, parent = placement.parent, parentPart = placement.parentPart, color = color })
		clearGhost()
		return true
	end
	local result = raycast(at)
	local index: number? = nil
	if result then
		local _model, i = myPieceOf(result.Instance)
		index = i
	end
	if tool == "Wire" then
		if not index then
			if wireFrom then
				wireFrom = nil
				Toast.show("Wiring done")
			end
			return true
		end
		local model = modelOfIndex(index)
		local item = model and Catalog.byId[model:GetAttribute("Item") :: string]
		if not wireFrom then
			if item and item.output then
				wireFrom = index
				Toast.show("Now tap what " .. item.label .. " should switch")
			else
				Toast.show("Start a wire at a button, timer or sensor")
			end
		else
			ask("wire", { from = wireFrom, to = index })
		end
		return true
	end
	if not index then
		return true
	end
	if tool == "Delete" then
		ask("delete", { index = index })
	elseif tool == "Paint" then
		ask("paint", { index = index, color = paintColor })
	elseif tool == "Tune" then
		local ok, setting = ask("tune", { index = index })
		if ok and setting then
			Toast.show(setting)
		end
	elseif tool == "Pin" then
		local ok, message = ask("pin", { index = index })
		if ok and message then
			Toast.show(message)
		end
	end
	return true
end

function BuildController.isActive(): boolean
	return active
end

-- Build mode on or off (the BUILD / DONE button, or B).
-- Whether build mode is open with its machine stopped (its keys pick and turn parts); while the
-- machine plays, the play keys (camera turn, tools) are back.
function BuildController.editing(): boolean
	return active and not playing
end

function BuildController.toggle()
	if not unlocked then
		return -- (not before the first minute is over)
	end
	if ReplayController.isPlaying() then
		return -- (the replay has the screen and the bar; it gives the bar back when it ends)
	end
	pop(modeButton)
	if active and playing then
		ask("stop")
	end
	if not active then
		toyBarWasOn = PokeController.isEnabled()
	end
	active = not active
	player:SetAttribute("Building", active)
	if not active then
		clearGhost()
		SaveController.close()
	end
	refreshMode()
	if active and pieceCount == 0 then
		Toast.show(if UserInputService.KeyboardEnabled
			then string.format("Pick a part (%s / %s), then click the floor to place it", Keybinds.labelOf("PrevPart"), Keybinds.labelOf("NextPart"))
			else "Pick a part, then tap the floor to place it")
	end
end

-- Shows an item's group and picks it; scrolls the drawer so its card is in view.
function BuildController.selectItem(id: string, quiet: boolean?)
	local item = Catalog.byId[id]
	if not item then
		return
	end
	category = item.category
	selectedItem = id
	turn = 0
	refreshItems()
	clearGhost()
	local card = itemCards[id]
	if card then
		local x = card.AbsolutePosition.X - itemsRow.AbsolutePosition.X + itemsRow.CanvasPosition.X
		local view = itemsRow.AbsoluteSize.X
		itemsRow.CanvasPosition = Vector2.new(math.max(0, x - (view - card.AbsoluteSize.X) / 2), 0)
	end
	if not quiet then
		Toast.show(item.hint)
	end
end

function BuildController.selectCategory(cat: string)
	for _, item in Catalog.list do
		if item.category == cat then
			BuildController.selectItem(item.id, true)
			return
		end
	end
end

-- The next (or previous) part in the drawer's group, round and round.
function BuildController.stepItem(delta: number)
	local inGroup = {}
	local at = 1
	for _, item in Catalog.list do
		if item.category == category then
			table.insert(inGroup, item.id)
			if item.id == selectedItem then
				at = #inGroup
			end
		end
	end
	if #inGroup > 0 then
		BuildController.selectItem(inGroup[(at - 1 + delta) % #inGroup + 1])
	end
end

function BuildController.stepCategory()
	local at = table.find(Catalog.categories, category) or 1
	BuildController.selectCategory(Catalog.categories[at % #Catalog.categories + 1])
end

-- Picks a paint colour (a dot, or the [ and ] keys) and rings it.
function BuildController.setPaint(i: number)
	paintColor = ((i - 1) % #Catalog.palette) + 1
	paintChosen = true
	for _, other in palette:GetChildren() do
		local s = other:FindFirstChildOfClass("UIStroke")
		if s then
			s.Thickness = if other.Name == "Color" .. paintColor then 3 else 1
		end
	end
end

function BuildController.turnPart()
	if Catalog.byId[selectedItem].facesOut then
		turn = (turn + 1) % 4
	else
		blockRot = Orientation.turn(blockRot, Vector3.yAxis, 1)
	end
	clearGhost()
end

function BuildController.tiltPart()
	if Catalog.byId[selectedItem].facesOut then
		-- (Machines, toys and logic stand on the face they are put on: they turn, they do not tilt.)
		Toast.show(string.format("This part stands on what you put it on. Turn it with %s", Keybinds.labelOf("Turn")))
		return
	end
	blockRot = Orientation.turn(blockRot, Vector3.xAxis, 1)
	clearGhost()
end

local function redrawKeyHints()
	local keyboard = UserInputService.KeyboardEnabled
	for name, chip in keyHints do
		chip.Text = " " .. Keybinds.labelOf(RAIL_KEYS[name]) .. " "
		chip.Visible = keyboard
	end
end

-- Build keys (Keybinds): B on/off anywhere; while building: tools, turn, tilt, parts, undo, play.
local function onKey(input: InputObject, processed: boolean)
	if not Keybinds.live(processed) or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	local key = input.KeyCode
	if Keybinds.is("Build", key) then
		BuildController.toggle()
		return
	end
	if not active then
		return
	end
	if Keybinds.is("PlayStop", key) then
		pop(playButton)
		ask(if playing then "stop" else "play")
		return
	end
	if playing then
		return -- (the toy bar has the keys while the machine runs)
	end
	if Keybinds.is("Undo", key) then
		ask("undo")
	elseif Keybinds.is("Saves", key) then
		clearGhost()
		SaveController.open()
	elseif Keybinds.is("ColourNext", key) or Keybinds.is("ColourPrev", key) then
		setTool("Paint")
		BuildController.setPaint(paintColor + (if Keybinds.is("ColourNext", key) then 1 else -1))
	elseif Keybinds.is("Turn", key) then
		BuildController.turnPart()
	elseif Keybinds.is("Tilt", key) then
		BuildController.tiltPart()
	elseif Keybinds.is("NextPart", key) then
		setTool("Place")
		BuildController.stepItem(1)
	elseif Keybinds.is("PrevPart", key) then
		setTool("Place")
		BuildController.stepItem(-1)
	elseif Keybinds.is("NextTab", key) then
		setTool("Place")
		BuildController.stepCategory()
	else
		for _, t in TOOL_ORDER do
			if Keybinds.is("Tool" .. t, key) then
				setTool(t)
				local b = toolButtons[t]
				if b then
					pop(b)
				end
				return
			end
		end
	end
end

local function onRender()
	if not active or playing then
		if hoverHighlight.Adornee then
			hoverHighlight.Adornee = nil
		end
		return
	end
	-- Desktop: preview where the mouse is. Touch has no hover; the tap places directly.
	if UserInputService.MouseEnabled and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch then
		local at = UserInputService:GetMouseLocation()
		if tool == "Place" then
			showGhost(placementAt(at))
			hoverHighlight.Adornee = nil
		else
			local result = raycast(at)
			local model = if result then (myPieceOf(result.Instance)) else nil
			hoverHighlight.Adornee = model
			hoverHighlight.OutlineColor = TOOL_COLORS[tool]
			hoverHighlight.FillColor = TOOL_COLORS[tool]
		end
	end
end

function BuildController.start()
	request = Net.func(Net.Names.BuildRequest)
	wireFolder = Instance.new("Folder")
	wireFolder.Name = "BuildWires"
	wireFolder.Parent = Workspace
	hoverHighlight = Instance.new("Highlight")
	hoverHighlight.FillTransparency = 0.75
	hoverHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	hoverHighlight.Parent = wireFolder
	SaveController.start(function()
		return pieceCount
	end)
	buildUi()
	HudSlots.watch(layoutForView)
	ViewMode.onChanged(layoutForView)

	Net.event(Net.Names.BuildState).OnClientEvent:Connect(function(state: any)
		if type(state) ~= "table" then
			return
		end
		local wasPlaying = playing
		pieceCount = tonumber(state.pieces) or 0
		playing = state.playing == true
		wires = if type(state.wires) == "table" then state.wires else {}
		if playing ~= wasPlaying then
			Toast.show(if playing then "Playing! Press STOP to keep building" else "Back to building")
		end
		refreshMode()
		-- Models are rebuilt by the server; redraw wires once they have arrived.
		task.delay(0.2, drawWires)
	end)

	-- The BUILD button appears once the first minute (onboarding) is over.
	task.spawn(function()
		local Onboarding = require(Client:WaitForChild("OnboardingController")) :: any
		Onboarding.whenFree(function()
			unlocked = true
			Controller.setHudShown("Sandbox", true)
			modeButton.Visible = modeShown()
			if modeButton.Visible then
				pop(modeButton)
			end
		end)
	end)

	RunService:BindToRenderStep("RagdollLabBuild", Enum.RenderPriority.Input.Value + 2, onRender)
	UserInputService.InputBegan:Connect(onKey)
	Keybinds.onChanged(redrawKeyHints)
	UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(redrawKeyHints)
	redrawKeyHints()
end

return BuildController
