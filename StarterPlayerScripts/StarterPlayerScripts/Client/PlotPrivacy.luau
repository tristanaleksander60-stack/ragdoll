--!strict
-- Private labs on this screen (round 3, M1). You see, and can walk into, only the plaza, your own
-- lab and the labs of friends who let you in (FriendsService: the owner's LabGuests; the rule is
-- Zones.mayEnter, the server's own). Everything in the other labs is taken off this screen (their
-- floor and props, their dummies, their builds, their playground, their blood, bangs and blast
-- flashes, the avatars standing there and whatever they hold), which also spares this client the
-- drawing and the physics of up to nine labs. Each lab you may not enter is a solid block on this
-- screen only, as long as the ground (your own avatar and your own thrown dummies bump into it),
-- with a glass fence and signs on each side you can stand by. The server checks all of it too
-- (Lab.keepOut; HitService and Blasts touch nothing in such a lab).
--
-- Things are moved into a folder outside the Workspace, never destroyed: whatever the server
-- changes on them still arrives, and they come back the moment you may see them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zones = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Zones"))

local player = Players.LocalPlayer

local PlotPrivacy = {}

PlotPrivacy.WALL_LENGTH = 4000 -- studs along z: the whole ground

local hidden = Instance.new("Folder")
hidden.Name = "HiddenLabs" -- (client only)
local homes: { [Instance]: Instance } = {} -- a hidden thing -> where it came from
local walls: { [number]: Model } = {}
local allowedSet: { [number]: boolean } = {}
local hiddenBodies: { [Model]: boolean } = {}

local ownerOf = Zones.ownerOf

function PlotPrivacy.allowed(index: number?): boolean
	if index == nil or index == 0 then
		return true -- the rooms and the plaza
	end
	return allowedSet[index] == true
end

-- Whether a point is in a lab this screen shows.
function PlotPrivacy.visibleAt(position: Vector3): boolean
	return PlotPrivacy.allowed(Zones.plotAt(position))
end

-- The owner's SPECTATE (Spectate): the lab of the one watched shows on this screen while watching
-- (seeing only: the server still keeps the owner's avatar out, Lab.keepOut).
local peek: number? = nil

local function computeAllowed()
	table.clear(allowedSet)
	for index = 1, Zones.PLOT_COUNT do
		allowedSet[index] = Zones.mayEnter(player, index) or index == peek -- (the server's own rule: Lab.keepOut)
	end
end

local function hide(thing: Instance)
	if homes[thing] or not thing.Parent then
		return
	end
	homes[thing] = thing.Parent
	thing.Parent = hidden
	-- (Gone for good while hidden, a dummy that respawned: its entry goes too. Audit fix.)
	thing.Destroying:Once(function()
		homes[thing] = nil
	end)
end

local function show(thing: Instance)
	local home = homes[thing]
	homes[thing] = nil
	if home and home.Parent and thing.Parent == hidden then
		thing.Parent = home
	end
end

-- Where a thing belongs: a plot index, or nil (not a lab's).
local function plotOfThing(thing: Instance, container: string): number?
	if container == "Playground" then
		local index = tonumber(string.match(thing.Name, "^Lab(%d+)$"))
		return index
	elseif container == "Labs" or container == "Dummies" then
		local plot = thing:GetAttribute("Plot")
		return if type(plot) == "number" then plot else nil
	elseif container == "Builds" then
		local owner = Players:GetPlayerByUserId(tonumber(thing.Name) or 0)
		local plot = owner and owner:GetAttribute("LabPlot")
		return if type(plot) == "number" then plot else nil
	elseif thing:IsA("Model") or thing:IsA("BasePart") then
		local at = if thing:IsA("Model") then thing:GetPivot().Position else (thing :: BasePart).Position
		local plot = Zones.plotAt(at)
		return if plot and plot > 0 then plot else nil
	end
	return nil
end

local CONTAINERS = { "Labs", "Dummies", "Builds", "Props", "Playground" }

local function sweep()
	for _, name in CONTAINERS do
		local container = Workspace:FindFirstChild(name)
		if container then
			for _, thing in container:GetChildren() do
				if not PlotPrivacy.allowed(plotOfThing(thing, name)) then
					hide(thing)
				end
			end
		end
	end
	-- Back on screen: what may be seen again (an invite, a lab that changed hands).
	for thing, home in homes do
		local name = home.Name
		if PlotPrivacy.allowed(plotOfThing(thing, name)) then
			show(thing)
		elseif not home.Parent then
			homes[thing] = nil -- its container went
		end
	end
end

-- Other avatars standing in a lab this screen does not show: not drawn (and their name tags off).
local function setBodyHidden(model: Model, on: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if on then 1 else 0
		elseif d:IsA("BillboardGui") then
			d.Enabled = not on
		end
	end
end

local function sweepBodies()
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if other ~= player and character then
			local root = character:FindFirstChild("HumanoidRootPart")
			local hide_ = root ~= nil and root:IsA("BasePart") and not PlotPrivacy.visibleAt(root.Position)
			if (hiddenBodies[character] == true) ~= hide_ or hide_ then
				-- (Again on every look while hidden: a tool taken out or a hat put on since.)
				hiddenBodies[character] = if hide_ then true else nil
				setBodyHidden(character, hide_)
			end
		end
	end
	for model in hiddenBodies do
		if not model.Parent then
			hiddenBodies[model] = nil
		end
	end
end

-- The ground's length along z and its middle (the Baseplate's; the whole strip is the lab).
local function groundSpan(): (number, number)
	local base = Workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		return base.Size.Z, base.Position.Z
	end
	local origin = Workspace:GetAttribute("LabOrigin")
	return PlotPrivacy.WALL_LENGTH, if typeof(origin) == "Vector3" then origin.Z else 0
end

local function fencePart(model: Model, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, transparency: number?)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = material
	part.Color = color
	part.Transparency = transparency or 0
	part.Size = size
	part.CFrame = cframe
	part.Parent = model
	return part
end

PlotPrivacy.FENCE_HEIGHT = 10
PlotPrivacy.POST_EVERY = 32 -- studs between the fence's posts
PlotPrivacy.SIGN_EVERY = 96 -- studs between two signs (one is always in sight)
PlotPrivacy.BOARD_CLEAR = 22 -- studs a fence sign keeps from a plaza edge board in front of it

-- Where the plaza's edge boards stand along a fence line at `x` (their z), if that line is a plaza
-- edge (WorldMaps builds them for everyone).
function PlotPrivacy.edgeBoardsZ(x: number): { number }
	local out = {}
	local edges = Workspace:FindFirstChild("PlazaEdges")
	if edges then
		for _, d in edges:GetChildren() do
			if d:IsA("BasePart") and d.Name == "Sign" and math.abs(d.Position.X - x) < 12 then
				table.insert(out, d.Position.Z)
			end
		end
	end
	return out
end

-- The block over a lab you may not enter (as long as the ground: nobody walks round it), with a
-- glass fence on each side that faces ground you may walk on: glass panes between metal posts, a
-- rail along the top and the foot, and a sign on the fence every SIGN_EVERY studs.
local function makeWall(index: number): Model
	local origin = Workspace:GetAttribute("LabOrigin")
	local y = if typeof(origin) == "Vector3" then origin.Y - 0.5 else 0 -- (the floor)
	local length, midZ = groundSpan()
	local x = Zones.plotCenterX(index)
	local model = Instance.new("Model")
	model.Name = "PrivateLab" .. index
	local block = Instance.new("Part")
	block.Name = "Block"
	block.Anchored = true
	block.CanQuery = false
	block.CanTouch = false
	block.Transparency = 1
	-- (As high as the fence: nothing stops at an invisible wall above it. Whoever flies over is
	-- put back by the server, Lab.keepOut, and sees nothing of the lab meanwhile.)
	block.Size = Vector3.new(Zones.PLOT_SPACING - 0.2, PlotPrivacy.FENCE_HEIGHT, length)
	block.CFrame = CFrame.new(x, y + PlotPrivacy.FENCE_HEIGHT / 2, midZ)
	block.Parent = model
	local h = PlotPrivacy.FENCE_HEIGHT
	local metal = Color3.fromRGB(58, 62, 74)
	local owner = ownerOf(index)
	local text = if owner then string.format("%s'S LAB\nPRIVATE: ask for an invite", string.upper(owner.DisplayName)) else "FREE LAB\nClosed until someone owns it"
	for _, side in { -1, 1 } do
		local neighbourX = x + side * Zones.PLOT_SPACING
		local neighbour = Zones.plotAt(Vector3.new(neighbourX, y + 1, midZ))
		-- (The strip past the last lab is that lab's own: no fence on the outer side.)
		local outer = neighbour == index
		if PlotPrivacy.allowed(neighbour) and not outer then
			local edgeX = x + side * (Zones.PLOT_HALF - 0.3)
			fencePart(model, "Glass", Vector3.new(0.2, h, length), CFrame.new(edgeX, y + h / 2, midZ), Enum.Material.Glass, Color3.fromRGB(150, 205, 255), 0.6)
			fencePart(model, "TopRail", Vector3.new(0.5, 0.5, length), CFrame.new(edgeX, y + h, midZ), Enum.Material.Metal, metal)
			fencePart(model, "FootRail", Vector3.new(0.5, 0.5, length), CFrame.new(edgeX, y + 0.25, midZ), Enum.Material.Metal, metal)
			local first = midZ - length / 2
			for z = first + PlotPrivacy.POST_EVERY / 2, first + length, PlotPrivacy.POST_EVERY do
				fencePart(model, "Post", Vector3.new(0.6, h + 0.4, 0.6), CFrame.new(edgeX, y + (h + 0.4) / 2, z), Enum.Material.Metal, metal)
			end
			-- Signs mounted on the fence's face (between two posts), on the side you stand.
			local faceX = x + side * (Zones.PLOT_HALF + 0.15)
			-- (Centred between two posts: posts stand at POST_EVERY/2 + k * POST_EVERY.)
			-- (Not right behind one of the plaza's own edge boards: WorldMaps' PlazaEdges.)
			local boards = PlotPrivacy.edgeBoardsZ(edgeX)
			for z = first + PlotPrivacy.POST_EVERY, first + length, PlotPrivacy.SIGN_EVERY do
				local clear = true
				for _, bz in boards do
					if math.abs(bz - z) < PlotPrivacy.BOARD_CLEAR then
						clear = false
					end
				end
				if not clear then
					continue
				end
				local sign = fencePart(model, "Sign", Vector3.new(0.2, 5, 24), CFrame.new(faceX, y + 5.5, z), Enum.Material.SmoothPlastic, Color3.fromRGB(16, 18, 23), 1)
				local gui = Instance.new("SurfaceGui")
				gui.Face = if side == 1 then Enum.NormalId.Right else Enum.NormalId.Left
				gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				gui.PixelsPerStud = 24
				gui.LightInfluence = 0
				gui.MaxDistance = 220
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundColor3 = Color3.fromRGB(16, 18, 23)
				label.BackgroundTransparency = 0.1
				label.TextColor3 = Color3.new(1, 1, 1)
				label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
				label.TextScaled = true
				label.Text = text
				local pad = Instance.new("UIPadding")
				pad.PaddingTop = UDim.new(0.1, 0)
				pad.PaddingBottom = UDim.new(0.1, 0)
				pad.PaddingLeft = UDim.new(0.04, 0)
				pad.PaddingRight = UDim.new(0.04, 0)
				pad.Parent = label
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 10)
				corner.Parent = label
				local edge = Instance.new("UIStroke")
				edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				edge.Color = Color3.fromRGB(124, 200, 255)
				edge.Thickness = 4
				edge.Parent = label
				label.Parent = gui
				gui.Parent = sign
			end
		end
	end
	return model
end

local function rebuildWalls()
	for _, wall in walls do
		wall:Destroy()
	end
	table.clear(walls)
	local folder = Workspace:FindFirstChild("PrivateLabs") or Instance.new("Folder")
	folder.Name = "PrivateLabs"
	folder.Parent = Workspace
	for index = 1, Zones.PLOT_COUNT do
		if not allowedSet[index] then
			local wall = makeWall(index)
			wall.Parent = folder
			walls[index] = wall
		end
	end
end

local function refresh()
	computeAllowed()
	rebuildWalls()
	sweep()
	sweepBodies()
end

-- Shows one more lab on this screen (nil: none). Only for the owner's SPECTATE.
function PlotPrivacy.setPeek(index: number?)
	if index == peek then
		return
	end
	peek = index
	refresh()
end

function PlotPrivacy.start()
	hidden.Parent = ReplicatedStorage
	local function watchPlayer(p: Player)
		p:GetAttributeChangedSignal("LabPlot"):Connect(refresh)
		p:GetAttributeChangedSignal("LabGuests"):Connect(refresh)
	end
	for _, p in Players:GetPlayers() do
		watchPlayer(p)
	end
	Players.PlayerAdded:Connect(function(p)
		watchPlayer(p)
		refresh()
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(refresh)
	end)
	-- New things in the containers are judged as they arrive (a dummy respawns, a prop is placed).
	local function watchContainer(container: Instance)
		container.ChildAdded:Connect(function(thing)
			task.defer(function()
				if thing.Parent == container and not PlotPrivacy.allowed(plotOfThing(thing, container.Name)) then
					hide(thing)
				end
			end)
		end)
	end
	for _, name in CONTAINERS do
		local container = Workspace:FindFirstChild(name)
		if container then
			watchContainer(container)
		end
	end
	Workspace.ChildAdded:Connect(function(child)
		-- (A blast's flash in a lab this screen does not show: not drawn.)
		if child:IsA("Explosion") then
			if not PlotPrivacy.visibleAt(child.Position) then
				child.Visible = false
			end
			return
		end
		if child.Name == "PlazaEdges" then
			task.defer(refresh) -- (its boards: the fence signs keep clear of them)
			return
		end
		if table.find(CONTAINERS, child.Name) then
			watchContainer(child)
			task.defer(sweep)
		end
	end)
	-- The private-lab notice from the server (Lab.keepOut put you back in the plaza).
	player:GetAttributeChangedSignal("PrivateLabAt"):Connect(function()
		local name = player:GetAttribute("PrivateLab")
		local Toast = require(script.Parent:WaitForChild("Toast")) :: any
		Toast.show(if type(name) == "string" and name ~= "" then string.format("That's %s's lab. Ask them to let you in!", name) else "That lab is private")
	end)
	refresh()
	-- Props that move into or out of a lab, avatars walking about: looked at twice a second (a
	-- table walk over a few hundred children, nothing per frame).
	task.spawn(function()
		while true do
			task.wait(0.5)
			sweepBodies()
			sweep()
		end
	end)
end

return PlotPrivacy
