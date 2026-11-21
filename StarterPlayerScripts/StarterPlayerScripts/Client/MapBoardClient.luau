--!strict
-- V9-0e / Phase M (Config.MAP_BOARD): this screen's side of the Map Board and the ring portals
-- (Server/Systems/MapBoard).
--   * Each board's screen (tag MapBoardScreen) gets a SurfaceGui in PlayerGui (only there can its tiles be
--     tapped or clicked): a tile per place with its picture, its name, the players there now (the
--     server's Count_<id>), NEW for a place not visited this visit, and YOU ARE HERE. A map's copy (Home)
--     has My Lab first. A tile opens the travel confirm (MapGo: the picture, one line, GO); GO goes through
--     PlaceMenu, as the MAPS window does.
--   * The board's prompt (E / a pad's X) opens the MAPS window.
--   * The portals' swirl arms (tag PortalSwirl) turn on this screen, near ones only.
--   * Once a visit, after HINT_AFTER s in the lab without a trip, the nearest PLACES portal sparkles for a
--     moment and one tip says where it leads.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Places = require(Shared:WaitForChild("Places")) :: any

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any

local Client = script.Parent

local MapBoardClient = {}

MapBoardClient.PIXELS = 50 -- per stud on the screen
MapBoardClient.SPIN = 0.6 -- rad/s of a portal's swirl arms
MapBoardClient.SPIN_RANGE = 160 -- studs: farther swirls rest
MapBoardClient.HINT_AFTER = 180 -- s

local player = Players.LocalPlayer
local visited: { [string]: boolean } = {}
local boards: { [BasePart]: { gui: SurfaceGui, redraw: () -> () } } = {}
local confirm: any = nil
local confirmImage: ImageLabel? = nil
local confirmName: TextLabel? = nil
local confirmLine: TextLabel? = nil
local confirmId: string? = nil

local function here(): string
	local p = player:GetAttribute("Place")
	return if type(p) == "string" then p else "Lab"
end

-- The places a board shows, in order (a map's copy: My Lab first; the Arena only while it is on).
function MapBoardClient.tilesFor(home: boolean): { string }
	local ids = {}
	if home then
		table.insert(ids, "Lab")
	end
	for _, place in Places.list do
		if place.id ~= "Lab" then
			table.insert(ids, place.id)
		end
	end
	return ids
end

local function go(id: string)
	local PlaceMenu = require(Client:WaitForChild("PlaceMenu")) :: any
	if PlaceMenu.go then
		PlaceMenu.go(id)
	end
	pcall(function()
		(require(Client:WaitForChild("SessionClient")) :: any).note("MapBoard")
	end)
end

local function openConfirm(id: string)
	local place = Places.byId[id]
	if not place or not confirm then
		return
	end
	confirmId = id
	if confirmImage then
		confirmImage.Image = place.image or ""
	end
	if confirmName then
		confirmName.Text = (place.glyph or "") .. " " .. place.name
	end
	if confirmLine then
		confirmLine.Text = place.blurb or ""
	end
	if not Controller.isOpen("MapGo") then
		Controller.open("MapGo")
	end
	C.playSound("click")
end

local function buildConfirm()
	local window = C.Window({ name = "MapGo", title = "Maps", theme = "codes", icon = "map", size = Vector2.new(520, 470), scroll = false })
	local body = window.body
	-- (Fix round 1: the window's body already lays its children out in a list; one layout only.)
	local img = Instance.new("ImageLabel")
	img.Name = "Picture"
	img.Size = UDim2.new(1, -20, 0, 170)
	img.ScaleType = Enum.ScaleType.Crop
	img.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	img.LayoutOrder = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = img
	img.Parent = body
	confirmImage = img
	confirmName = C.Text("title", "", { size = UDim2.new(1, -20, 0, 40), layoutOrder = 2, parent = body })
	confirmLine = C.Text("body", "", { wrap = true, size = UDim2.new(1, -20, 0, 44), layoutOrder = 3, parent = body })
	local goButton = C.Button({ name = "Go", text = "GO", icon = "map", role = "go", size = UDim2.new(0.6, 0, 0, 60), layoutOrder = 4, parent = body, onActivated = function()
		local id = confirmId
		if Controller.isOpen("MapGo") then
			Controller.toggle("MapGo")
		end
		if id then
			go(id)
		end
	end })
	window.defaultSelection = goButton.hit
	Controller.register(window)
	confirm = window
end

-- One tile on a board.
local function tile(parent: Instance, id: string, order: number, counts: BasePart): (ImageButton, () -> ())
	local place = Places.byId[id]
	local b = Instance.new("ImageButton")
	b.Name = id
	b.LayoutOrder = order
	b.Image = place.image or ""
	b.ScaleType = Enum.ScaleType.Crop
	b.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
	b.AutoButtonColor = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(60, 66, 90)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	-- The name on a dark band along the bottom.
	local band = Instance.new("Frame")
	band.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	band.BackgroundTransparency = 0.15
	band.Size = UDim2.new(1, 0, 0.32, 0)
	band.Position = UDim2.fromScale(0, 0.68)
	local bandCorner = Instance.new("UICorner")
	bandCorner.CornerRadius = UDim.new(0, 18)
	bandCorner.Parent = band
	band.Parent = b
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, -16, 1, 0)
	name.Position = UDim2.fromOffset(8, 0)
	name.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.Text = if id == "Lab" then "\u{1F3E0} My Lab" else place.name
	name.Parent = band
	-- Players there now; NEW; YOU ARE HERE.
	local chip = Instance.new("TextLabel")
	chip.Name = "Count"
	chip.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	chip.BackgroundTransparency = 0.1
	chip.Size = UDim2.new(0.42, 0, 0.28, 0)
	chip.Position = UDim2.fromScale(0.03, 0.04)
	chip.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	chip.TextScaled = true
	chip.TextColor3 = Color3.fromRGB(230, 240, 255)
	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(1, 0)
	chipCorner.Parent = chip
	chip.Parent = b
	local new = Instance.new("TextLabel")
	new.Name = "New"
	new.BackgroundColor3 = Color3.fromRGB(255, 196, 64)
	new.Size = UDim2.new(0.36, 0, 0.28, 0)
	new.Position = UDim2.fromScale(0.61, 0.04)
	new.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	new.TextScaled = true
	new.TextColor3 = Color3.fromRGB(40, 24, 0)
	new.Text = "NEW"
	local newCorner = Instance.new("UICorner")
	newCorner.CornerRadius = UDim.new(1, 0)
	newCorner.Parent = new
	new.Parent = b
	local hereTag = Instance.new("TextLabel")
	hereTag.Name = "Here"
	hereTag.BackgroundColor3 = Color3.fromRGB(19, 160, 76)
	hereTag.BackgroundTransparency = 0.05
	hereTag.Size = UDim2.new(0.7, 0, 0.2, 0)
	hereTag.Position = UDim2.fromScale(0.15, 0.38)
	hereTag.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	hereTag.TextScaled = true
	hereTag.TextColor3 = Color3.new(1, 1, 1)
	hereTag.Text = "YOU ARE HERE"
	local hereCorner = Instance.new("UICorner")
	hereCorner.CornerRadius = UDim.new(1, 0)
	hereCorner.Parent = hereTag
	hereTag.Parent = b
	local function redraw()
		local n = counts:GetAttribute("Count_" .. id)
		chip.Text = "\u{1F465} " .. tostring(if type(n) == "number" then n else 0)
		chip.Visible = id ~= "Lab" and type(n) == "number" and n > 0 -- (fix round 1: "0" on every tile said nobody goes there)
		local isHere = here() == id
		hereTag.Visible = isHere
		new.Visible = not isHere and not visited[id] and id ~= "Lab" and id ~= "Plaza"
		b.ImageTransparency = if isHere then 0.35 else 0
	end
	redraw()
	b:SetAttribute("Tile", true)
	b.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), { Color = Color3.fromRGB(255, 196, 64), Thickness = 6 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), { Color = Color3.fromRGB(60, 66, 90), Thickness = 3 }):Play()
	end)
	b.Activated:Connect(function()
		-- (Fix round 1: a newcomer's stray tap in the first quiet seconds never takes them out of the lab.)
		local quietUntil = player:GetAttribute("NewcomerUntil")
		if type(quietUntil) == "number" and time() < quietUntil then -- (FirstVisit sets it in time())
			return
		end
		if here() ~= id then
			openConfirm(id)
		end
	end)
	return b, redraw
end

local function buildBoard(screen: BasePart)
	if boards[screen] then
		return
	end
	local home = screen:GetAttribute("Home") == true
	local gui = Instance.new("SurfaceGui")
	gui.Name = "MapBoard"
	gui.Adornee = screen
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = MapBoardClient.PIXELS
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.MaxDistance = 160
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	local canvas = Instance.new("Frame")
	canvas.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.fromRGB(28, 36, 64), Color3.fromRGB(10, 12, 22))
	gradient.Parent = canvas
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(0.6, 0, 0.14, 0)
	title.Position = UDim2.fromScale(0.03, 0.02)
	title.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 210, 90)
	title.Text = "\u{1F5FA}\u{FE0F} MAPS"
	title.Parent = canvas
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(0.38, 0, 0.09, 0)
	sub.Position = UDim2.fromScale(0.6, 0.045)
	sub.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	sub.TextScaled = true
	sub.TextXAlignment = Enum.TextXAlignment.Right
	sub.TextColor3 = Color3.fromRGB(200, 210, 235)
	sub.Text = "Pick a map"
	sub.Parent = canvas
	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(0.96, 0, 0.8, 0)
	grid.Position = UDim2.fromScale(0.02, 0.18)
	grid.Parent = canvas
	local ids = MapBoardClient.tilesFor(home)
	local cols = math.max(1, math.ceil(#ids / 2))
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromScale(0.015, 0.04)
	layout.CellSize = UDim2.new(1 / cols - 0.015, 0, 0.48, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = grid
	local redraws: { () -> () } = {}
	for i, id in ids do
		local t, r = tile(grid, id, i, screen)
		t.Parent = grid
		table.insert(redraws, r)
	end
	local function redraw()
		for _, r in redraws do
			r()
		end
	end
	screen.AttributeChanged:Connect(function(name)
		if string.sub(name, 1, 6) == "Count_" then
			redraw()
		end
	end)
	screen.Destroying:Connect(function()
		gui:Destroy()
		boards[screen] = nil
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
	boards[screen] = { gui = gui, redraw = redraw }
end

local function redrawAll()
	for _, b in boards do
		b.redraw()
	end
end

-- The swirl arms turn (near portals only).
local swirls: { [BasePart]: CFrame } = {}
local function watchSwirl(arms: Instance)
	if arms:IsA("BasePart") then
		swirls[arms] = arms.CFrame
		arms.Destroying:Connect(function()
			swirls[arms] = nil
		end)
	end
end

local hinted = false
local function hint()
	if hinted then
		return
	end
	hinted = true
	local camera = Workspace.CurrentCamera
	local best: BasePart? = nil
	local bestD = math.huge
	for _, arms in CollectionService:GetTagged("PortalSwirl") do
		local gate = arms.Parent
		if gate and gate:IsA("Model") and gate:GetAttribute("GateKind") == "Places" then
			local swirl = gate:FindFirstChild("Swirl")
			if swirl and swirl:IsA("BasePart") and camera then
				local d = (swirl.Position - camera.CFrame.Position).Magnitude
				if d < bestD then
					best, bestD = swirl, d
				end
			end
		end
	end
	if best and bestD < 120 then
		local sparkle = best:FindFirstChild("Sparkles")
		if sparkle and sparkle:IsA("ParticleEmitter") then
			local was = sparkle.Rate
			sparkle.Rate = was * 4
			task.delay(8, function()
				sparkle.Rate = was
			end)
		end
	end
	pcall(function()
		(require(Client:WaitForChild("Notify")) :: any).say("tip", if (Config :: any).MAP_PORTAL then "Explore other maps: step into the gold portal!" else "Explore other maps: pick one on the MAPS board!", Color3.fromRGB(255, 196, 64), "placesPortal")
	end)
end

function MapBoardClient.start()
	if not Config.MAP_BOARD then
		return
	end
	visited[here()] = true
	player:GetAttributeChangedSignal("Place"):Connect(function()
		visited[here()] = true
		redrawAll()
	end)
	buildConfirm()
	for _, screen in CollectionService:GetTagged("MapBoardScreen") do
		if screen:IsA("BasePart") then
			task.spawn(buildBoard, screen)
		end
	end
	CollectionService:GetInstanceAddedSignal("MapBoardScreen"):Connect(function(screen)
		if screen:IsA("BasePart") then
			task.spawn(buildBoard, screen)
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "MapBoardPrompt" then
			Controller.open("Maps")
		end
	end)
	for _, arms in CollectionService:GetTagged("PortalSwirl") do
		watchSwirl(arms)
	end
	CollectionService:GetInstanceAddedSignal("PortalSwirl"):Connect(watchSwirl)
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local t = os.clock() * MapBoardClient.SPIN
		local eye = camera.CFrame.Position
		for arms, base in swirls do
			if (base.Position - eye).Magnitude < MapBoardClient.SPIN_RANGE then
				arms.CFrame = base * CFrame.Angles(0, 0, t)
			end
		end
	end)
	-- The once-a-visit call from the portal: in the lab, after HINT_AFTER s, no trip yet.
	task.delay(MapBoardClient.HINT_AFTER, function()
		local onlyLab = true
		for id in visited do
			if id ~= "Lab" then
				onlyLab = false
			end
		end
		if onlyLab and here() == "Lab" then
			hint()
		end
	end)
end

-- Tests: the travel confirm for a place, and GO.
function MapBoardClient.goForTest(id: string)
	openConfirm(id)
	go(id)
end

return MapBoardClient
