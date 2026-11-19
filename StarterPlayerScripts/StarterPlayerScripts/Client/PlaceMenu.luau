--!strict
-- The MAPS window (phase E): every place as a card (its colour, its name, one line about it, how
-- many people live there) and a GO button; the one you are in reads YOU ARE HERE. Under them, the
-- other players' labs (round 2): one card each, by their display name, to go and visit. Going asks
-- the server (WorldMaps checks it); on arrival the screen flashes the place's colour and its name,
-- and ZoneLighting sets the mood. M opens and closes it on a keyboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Net = require(Shared:WaitForChild("Net"))
local Places = require(Shared:WaitForChild("Places"))
local Zones = require(Shared:WaitForChild("Zones"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))
local ViewMode = require(Client:WaitForChild("ViewMode"))

local player = Players.LocalPlayer
local SP = Theme.Space
local CARD = Vector2.new(220, 228)
local PRESS_LOCK = 2.2 -- s: one trip at a time (the server allows one per 2 s)

local PlaceMenu = {}

local LAB_COLOR = "#5FB0E8"
local LAB_GLYPH = "🧫"

local remote: RemoteEvent
local buttons: { [string]: any } = {}
local labsGrid: Frame? = nil
-- Card order in the one grid: My Lab and the plaza first, then everyone else's lab (right where
-- you see them without scrolling), then the rooms.
local ORDER_STEP = 100
local LABS_AT = 2 * ORDER_STEP + 1
local locked = false
local flash: Frame? = nil
local flashTitle: TextLabel? = nil

local function here(): string
	local place = player:GetAttribute("Place")
	return if type(place) == "string" then place else "Lab"
end

local function refresh()
	local current = here()
	-- Without a lab of your own (every lab taken), My Lab is the plaza: it says so.
	local labless = player:GetAttribute("LabPlot") == nil
	for id, button in buttons do
		local isHere = id == current
		if id == "Lab" and labless then
			button.setRole("done")
			button.setText("ALL LABS TAKEN")
			button.setEnabled(false)
		else
			button.setRole(if isHere then "done" else "go")
			button.setText(if isHere then "YOU ARE HERE" else "GO")
			button.setEnabled(not isHere and not locked)
		end
	end
end

-- A name on a lab card: at most CARD_NAME_MAX characters, then an ellipsis (a 20-letter name of
-- wide letters would shrink under 11 px on a phone).
local CARD_NAME_MAX = 14
function PlaceMenu.cardName(name: string): string
	if utf8.len(name) and (utf8.len(name) :: number) > CARD_NAME_MAX then
		local cut = utf8.offset(name, CARD_NAME_MAX)
		return string.sub(name, 1, (cut or #name + 1) - 1) .. "\u{2026}"
	end
	return name
end

local go: (id: string) -> () -- (below: the cards press it)

-- The name a lab is listed by (its owner's display name; nobody types anything here).
local function labTitle(owner: Player): string
	return owner.DisplayName .. "'s Lab"
end

local function placeCard(parent: Instance, id: string, order: number, color: string, glyph: string, title: string, caption: string): any
	local card = C.Card({ name = id, gap = SP.xs, layoutOrder = order, parent = parent })
	-- The place's colour with its picture.
	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Size = UDim2.new(1, 0, 0, 64)
	preview.BackgroundColor3 = Color3.fromHex(color)
	preview.LayoutOrder = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = preview
	-- Its picture in the kit's picture style (the emoji on a darkened shape with a white edge),
	-- as every tool, event and window draws it.
	local name = "place_" .. (if Places.labPlot(id) then "OtherLab" else id)
	if not Icons.Fallbacks[name] then
		Icons.Fallbacks[name] = { glyph = glyph, shape = "square", color = Color3.fromHex(color) }
	end
	local pic = Icons.make(name, UDim2.fromOffset(56, 56))
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	pic.Position = UDim2.fromScale(0.5, 0.5)
	pic.Parent = preview
	preview.Parent = card.content
	C.Text("title", title, { scaled = true, size = UDim2.new(1, 0, 0, 26), layoutOrder = 2, parent = card.content })
	C.Text("caption", caption, {
		color = Theme.Palette.textMid,
		wrap = true,
		size = UDim2.new(1, 0, 0, 38),
		layoutOrder = 3,
		parent = card.content,
	})
	local button = C.Button({
		text = "GO",
		role = "go",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 4,
		parent = card.content,
		onActivated = function()
			go(id)
		end,
	})
	buttons[id] = button
	return button
end

-- The other players' labs, rebuilt whenever someone comes, goes or gets a lab.
local function refreshLabs()
	local grid = labsGrid
	if not grid then
		return
	end
	for id in buttons do
		if Places.labPlot(id) then
			buttons[id] = nil
		end
	end
	for _, child in grid:GetChildren() do
		if child:IsA("GuiObject") and Places.labPlot(child.Name) then
			child:Destroy()
		end
	end
	local owners = {}
	for _, other in Players:GetPlayers() do
		local plot = other:GetAttribute("LabPlot")
		-- (Only the labs whose owners invited you: labs are private, round 3.)
		if other ~= player and type(plot) == "number" and Zones.isGuest(other, player.UserId) then
			table.insert(owners, { player = other, plot = plot })
		end
	end
	table.sort(owners, function(a, b)
		return a.plot < b.plot
	end)
	for i, entry in owners do
		-- (The name alone as the title, so a long one stays readable on a phone: LayoutCheck.)
		placeCard(grid, Places.labId(entry.plot), LABS_AT + i, LAB_COLOR, LAB_GLYPH, PlaceMenu.cardName(entry.player.DisplayName), "They invited you: visit their lab.")
	end
	refresh()
end

function go(id: string)
	if locked or id == here() then
		return
	end
	locked = true
	refresh()
	remote:FireServer(id)
	task.delay(PRESS_LOCK, function()
		locked = false
		refresh()
	end)
end

local function build()
	local window = C.Window({ name = "Maps", title = "Places", theme = "codes", icon = "map" })
	C.Text("caption", "Your lab, the plaza, other players' labs and rooms full of people.", {
		color = Theme.Palette.textMid,
		wrap = true,
		size = UDim2.new(1, 0, 0, 24),
		layoutOrder = 0,
		parent = window.body,
	})
	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = 1
	C.Grid(grid, CARD, SP.md)
	grid.Parent = window.body
	for index, place in Places.list do
		local caption = if place.crowd > 0 then string.format("%s %d people.", place.blurb, place.crowd) else place.blurb
		local button = placeCard(grid, place.id, index * ORDER_STEP, place.color, place.glyph, place.name, caption)
		if index == 2 then
			window.defaultSelection = button.hit
		end
	end
	-- (Everyone else's lab goes into the same grid, after the plaza.)
	labsGrid = grid
	Controller.register(window)
	Controller.addHudButton({ window = "Maps", label = "Places", icon = "map", theme = "codes", layoutOrder = 4 })
end

-- The arrival flash: the place's colour over the screen, its name, then gone.
local function buildFlash()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ArrivalFlash"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Active = false
	frame.Parent = gui
	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.42)
	title.Size = UDim2.new(0.8, 0, 0, 56)
	title.BackgroundTransparency = 1
	title.FontFace = Theme.Fonts.display
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(5, 6, 8)
	stroke.Transparency = 1
	stroke.Parent = title
	title.Parent = frame
	gui.Parent = player:WaitForChild("PlayerGui")
	flash = frame
	flashTitle = title
end

local function arrived(id: string)
	-- (Your own lab by its number is your lab: the lab view stays.)
	if Places.labPlot(id) ~= nil and Places.labPlot(id) == player:GetAttribute("LabPlot") then
		id = "Lab"
	end
	local place = Places.byId[id]
	local frame, title = flash, flashTitle
	if not frame or not title then
		return
	end
	Controller.closeAll()
	local plot = Places.labPlot(id)
	local owner: Player? = nil
	if plot then
		for _, other in Players:GetPlayers() do
			if other:GetAttribute("LabPlot") == plot then
				owner = other
			end
		end
	end
	if not place and not plot then
		return
	end
	-- The lab view only looks at your own lab: away from it, you see through your avatar's eyes.
	if id ~= "Lab" and ViewMode.isLab() then
		ViewMode.set("Player")
	end
	-- The camera swings round behind the avatar, looking into the room (the arrival pad faces in).
	task.delay(0.15, function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		if root and root:IsA("BasePart") and camera and camera.CameraType == Enum.CameraType.Custom then
			local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
			if look.Magnitude > 0.1 then
				look = look.Unit
				camera.CFrame = CFrame.lookAt(root.Position - look * 12 + Vector3.new(0, 5, 0), root.Position + look * 8)
			end
		end
	end)
	local color = if place then place.color else LAB_COLOR
	frame.BackgroundColor3 = if id == "Hangar" then Color3.fromRGB(10, 12, 30) else Color3.fromHex(color)
	frame.BackgroundTransparency = 0
	title.Text = string.upper(if place then place.name elseif owner then labTitle(owner) else "A lab")
	title.TextTransparency = 0
	local stroke = title:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15)
	TweenService:Create(frame, info, { BackgroundTransparency = 1 }):Play()
	local textInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.1)
	TweenService:Create(title, textInfo, { TextTransparency = 1 }):Play()
	if stroke then
		TweenService:Create(stroke, textInfo, { Transparency = 1 }):Play()
	end
end

function PlaceMenu.start()
	remote = Net.event(Net.Names.Travel)
	build()
	buildFlash()
	refresh()
	player:GetAttributeChangedSignal("Place"):Connect(refresh)
	player:GetAttributeChangedSignal("LabPlot"):Connect(refresh)
	-- Labs come and go with their owners.
	local function watchOwner(other: Player)
		other:GetAttributeChangedSignal("LabPlot"):Connect(refreshLabs)
		other:GetAttributeChangedSignal("LabGuests"):Connect(refreshLabs) -- (an invite in or out)
	end
	for _, other in Players:GetPlayers() do
		watchOwner(other)
	end
	Players.PlayerAdded:Connect(function(other)
		watchOwner(other)
		refreshLabs()
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(refreshLabs)
	end)
	refreshLabs()
	remote.OnClientEvent:Connect(function(kind: unknown, detail: unknown)
		if kind == "Arrived" and type(detail) == "string" then
			arrived(detail)
		elseif kind == "LabReady" then
			-- A lab came free and it is ours now (we lived in the plaza).
			Toast.show("A lab came free: it's yours! Open Places > My Lab", Color3.fromRGB(124, 200, 255))
			refresh()
		elseif kind == "Refused" and type(detail) == "string" then
			Toast.show(detail)
			locked = false
			refresh()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("Places", input.KeyCode) then
			Controller.toggle("Maps")
		end
	end)
end

-- Tests and LayoutCheck: what the window would do.
function PlaceMenu.goForTest(id: string)
	go(id)
end

return PlaceMenu
