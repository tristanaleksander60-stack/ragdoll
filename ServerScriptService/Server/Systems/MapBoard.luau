--!strict
-- V9-0e / Phase M (owner, 21 Nov 2026: "much nicer portals, and a place with a sign of the maps where you
-- choose which map to switch to"; priority, right after the physics; Config.MAP_BOARD).
--
-- In every lab, in the spawn's view and angled to it:
--   * the MAP BOARD (BOARD_ANGLE left of the spawn's facing, BOARD_DISTANCE studs out): a lit frame with a
--     big screen. The screen part is tagged MapBoardScreen; each player's client draws its tiles
--     (Client/MapBoardClient: a SurfaceGui in PlayerGui, so the tiles can be tapped) from the place list and
--     the counts the server keeps on it (attributes Count_<id>, every COUNT_EVERY s). A ProximityPrompt
--     (MapBoardPrompt) opens the MAPS window for keys and pads;
--   * the PLACES portal (gold): a carved ring gate with a living swirl (beam arms the client turns,
--     sparkles, a glow on the floor). Walking in opens the places (remote Portal "Open" PortalPlaces).
-- Every open-air map gets a smaller board (My lab first: attribute Home) and a portal by its arrival.
-- The lab's SINGLEPLAYER / MULTIPLAYER portals are the same ring family (PortalService: blue Solo,
-- green Multi), each with its own colour and icon, never to be mixed up with the gold PLACES.
-- Everything here is anchored and pictures only (CanCollide off), except what a player walks into.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net"))
local Places = require(Shared:WaitForChild("Places")) :: any

local MapBoard = {}

MapBoard.BOARD_ANGLE = 10 -- degrees left of the spawn's facing (fix round 1: the whole board in an upright phone's view)
MapBoard.BOARD_DISTANCE = 24 -- studs from the spawn
MapBoard.PORTAL_ANGLE = -26 -- (fix round 1: right of the wrecking ball, clear of the dummies' row, the leaderboard and the cannon)
MapBoard.PORTAL_DISTANCE = 27
MapBoard.SCREEN = Vector2.new(13, 7.4) -- studs (a lab's; a map's copy is MAP_SCALE of it)
MapBoard.SCREEN_LIFT = 3.2 -- studs from the floor to the screen's bottom edge
MapBoard.RING_RADIUS = 6 -- studs (the PLACES gate; Solo/Multi are RING_SMALL of it)
MapBoard.RING_SMALL = 0.85
MapBoard.MAP_SCALE = 0.9
MapBoard.DWELL = 0.6 -- s standing in the swirl before the maps open (a run or a fling through it opens nothing)
MapBoard.POLL = 0.2 -- s between two looks at who stands in a swirl
MapBoard.COUNT_EVERY = 3 -- s
MapBoard.TOUCH_GAP = 4 -- s between two openings for one player

MapBoard.COLORS = table.freeze({
	Places = Color3.fromRGB(255, 196, 64), -- gold
	Solo = Color3.fromRGB(80, 170, 255), -- blue
	Multi = Color3.fromRGB(80, 220, 120), -- green
})
MapBoard.LABELS = table.freeze({ Places = "MAPS", Solo = "SINGLEPLAYER", Multi = "MULTIPLAYER" })
MapBoard.GLYPHS = table.freeze({ Places = "\u{1F5FA}\u{FE0F}", Solo = "\u{1F464}", Multi = "\u{1F465}" })

local STONE = Color3.fromRGB(70, 66, 80)
local STONE_DARK = Color3.fromRGB(48, 45, 56)
local FRAME = Color3.fromRGB(38, 40, 50)

local function piece(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The floor under a point (the first thing a ray down meets that is not a body), or the point itself.
local function floorUnder(at: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(at + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
	return if hit then hit.Position else at
end

local function label(parent: BasePart, face: Enum.NormalId, text: string, color: Color3, pixels: number)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixels
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.MaxDistance = 220
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(20, 16, 30)
	stroke.Parent = t
	t.Parent = gui
	gui.Parent = parent
end

-- A ring gate of `kind` standing on `base` (its floor point), facing `toward`. Returns the model and the
-- swirl part a player walks into (CanTouch on, CanCollide off).
function MapBoard.gate(parent: Instance, base: Vector3, toward: Vector3, kind: string, scale: number?): (Model, BasePart)
	local s = scale or 1
	local color = MapBoard.COLORS[kind] or MapBoard.COLORS.Places
	local R = MapBoard.RING_RADIUS * s
	local m = Instance.new("Model")
	m.Name = "Gate" .. kind
	m:SetAttribute("GateKind", kind)
	local flat = Vector3.new(toward.X, base.Y, toward.Z)
	local cf = CFrame.lookAt(base, if (flat - base).Magnitude > 0.1 then flat else base - Vector3.zAxis)
	-- The plinth: two steps of stone.
	piece(m, "Plinth", Vector3.new(2 * R + 4 * s, 0.8 * s, 5 * s), cf * CFrame.new(0, 0.4 * s, 0), STONE_DARK, Enum.Material.Slate)
	piece(m, "Step", Vector3.new(2 * R + 1 * s, 0.5 * s, 3.4 * s), cf * CFrame.new(0, 1.05 * s, 0), STONE, Enum.Material.Slate)
	local centre = cf * CFrame.new(0, 1.3 * s + R + 0.9 * s, 0)
	-- The ring: N carved stones round the swirl, a glowing rune on every other one.
	local N = 26
	local segLen = 2 * math.pi * (R + 0.8 * s) / N + 0.25 * s
	for i = 0, N - 1 do
		local a = 2 * math.pi * i / N
		local at = centre * CFrame.new(math.cos(a) * (R + 0.8 * s), math.sin(a) * (R + 0.8 * s), 0) * CFrame.Angles(0, 0, a + math.pi / 2)
		piece(m, "Stone", Vector3.new(segLen, 1.6 * s, 2.2 * s), at, if i % 2 == 0 then STONE else STONE_DARK, Enum.Material.Slate)
		if i % 2 == 0 then
			local rune = piece(m, "Rune", Vector3.new(segLen * 0.42, 0.42 * s, 0.12 * s), at * CFrame.new(0, 0, -1.12 * s), color, Enum.Material.Neon)
			rune.CastShadow = false
		end
	end
	-- The keystone on top: the kind's word and glyph, both faces.
	local key = piece(m, "Keystone", Vector3.new(5.4 * s, 2.6 * s, 2.6 * s), centre * CFrame.new(0, R + 1.9 * s, 0), STONE, Enum.Material.Slate)
	label(key, Enum.NormalId.Front, MapBoard.GLYPHS[kind] .. " " .. MapBoard.LABELS[kind], color, 40)
	label(key, Enum.NormalId.Back, MapBoard.GLYPHS[kind] .. " " .. MapBoard.LABELS[kind], color, 40)
	-- The swirl: a glowing disc (what you walk into), arms the client turns (SwirlArms), sparkles drifting
	-- out, and a light that colours the floor in front (WorldLight: lit within the device's cap).
	local swirl = piece(m, "Swirl", Vector3.new(0.4 * s, 2 * R, 2 * R), centre * CFrame.Angles(0, math.pi / 2, 0), color, Enum.Material.ForceField)
	swirl.Shape = Enum.PartType.Cylinder
	swirl.Transparency = 0 -- (ForceField: the engine's own living shimmer, see-through by itself)
	swirl.CastShadow = false
	swirl.CanTouch = true
	local inner = piece(m, "SwirlCore", Vector3.new(0.5 * s, R * 0.55, R * 0.55), centre * CFrame.Angles(0, math.pi / 2, 0), color:Lerp(Color3.new(1, 1, 1), 0.6), Enum.Material.Neon)
	inner.Shape = Enum.PartType.Cylinder
	inner.Transparency = 0.55
	inner.CastShadow = false
	local arms = piece(m, "SwirlArms", Vector3.new(0.2, 0.2, 0.2), centre, color, Enum.Material.SmoothPlastic)
	arms.Transparency = 1
	arms.CastShadow = false
	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2
		local core = Instance.new("Attachment")
		core.Name = "Core" .. i
		core.CFrame = CFrame.Angles(0, 0, a + math.pi / 2)
		core.Parent = arms
		local rim = Instance.new("Attachment")
		rim.Name = "Rim" .. i
		rim.CFrame = CFrame.new(math.cos(a) * (R - 0.6 * s), math.sin(a) * (R - 0.6 * s), -0.15) * CFrame.Angles(0, 0, a + math.pi)
		rim.Parent = arms
		local beam = Instance.new("Beam")
		beam.Name = "Arm" .. i
		beam.Attachment0 = core
		beam.Attachment1 = rim
		beam.CurveSize0 = R * 0.55
		beam.CurveSize1 = -R * 0.35
		beam.Width0 = 0.35 * s
		beam.Width1 = 2.4 * s
		beam.Segments = 24
		beam.FaceCamera = false
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 1) })
		beam.Parent = arms
	end
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "Sparkles"
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Shape = Enum.ParticleEmitterShape.Disc
	sparkle.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	sparkle.EmissionDirection = Enum.NormalId.Right -- (the cylinder's axis: out of the swirl's face)
	sparkle.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5), color)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * s), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Transparency = NumberSequence.new(0.2)
	sparkle.Lifetime = NumberRange.new(1.4, 2.4)
	sparkle.Speed = NumberRange.new(1, 2.5)
	sparkle.Rate = 14
	sparkle.RotSpeed = NumberRange.new(-90, 90)
	sparkle.Parent = swirl
	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = color
	light.Range = 16 * s
	light.Brightness = 1.6
	light.Enabled = false -- (Client/WorldLights lights the nearest within the device's cap)
	light.Parent = swirl
	CollectionService:AddTag(light, "WorldLight")
	CollectionService:AddTag(arms, "PortalSwirl")
	-- (Fix round 1: the stone is solid: nobody walks through a plinth or a ring stone.)
	for _, d in m:GetChildren() do
		if d:IsA("BasePart") and (d.Name == "Plinth" or d.Name == "Step" or d.Name == "Stone" or d.Name == "Keystone") then
			d.CanCollide = true
		end
	end
	m.Parent = parent
	return m, swirl
end

-- The Map Board standing on `base`, facing `toward`. `home`: a map's copy (My lab first).
function MapBoard.board(parent: Instance, base: Vector3, toward: Vector3, scale: number?, home: boolean?): Model
	local s = scale or 1
	local W, H = MapBoard.SCREEN.X * s, MapBoard.SCREEN.Y * s
	local m = Instance.new("Model")
	m.Name = "MapBoard"
	local flat = Vector3.new(toward.X, base.Y, toward.Z)
	local cf = CFrame.lookAt(base, if (flat - base).Magnitude > 0.1 then flat else base - Vector3.zAxis)
	local lift = MapBoard.SCREEN_LIFT * s
	local top = lift + H
	-- The frame: two posts on feet, a crossbeam with lamps, a thick bezel round the screen.
	for _, x in { -W / 2 - 0.9 * s, W / 2 + 0.9 * s } do
		piece(m, "Post", Vector3.new(1.1 * s, top + 1.6 * s, 1.1 * s), cf * CFrame.new(x, (top + 1.6 * s) / 2, 0.3 * s), FRAME, Enum.Material.Metal)
		piece(m, "Foot", Vector3.new(2.2 * s, 0.5 * s, 3 * s), cf * CFrame.new(x, 0.25 * s, 0.3 * s), FRAME, Enum.Material.Metal)
	end
	piece(m, "Beam", Vector3.new(W + 3.4 * s, 0.9 * s, 1.3 * s), cf * CFrame.new(0, top + 1.3 * s, 0.3 * s), FRAME, Enum.Material.Metal)
	piece(m, "Bezel", Vector3.new(W + 1 * s, H + 1 * s, 0.6 * s), cf * CFrame.new(0, lift + H / 2, 0.45 * s), Color3.fromRGB(26, 28, 36), Enum.Material.SmoothPlastic)
	local glow = piece(m, "Trim", Vector3.new(W + 1.2 * s, 0.18 * s, 0.2 * s), cf * CFrame.new(0, lift - 0.55 * s, 0.05 * s), MapBoard.COLORS.Places, Enum.Material.Neon)
	glow.CastShadow = false
	for i = -1, 1 do
		local lamp = piece(m, "Lamp", Vector3.new(1.4 * s, 0.5 * s, 1.2 * s), cf * CFrame.new(i * W / 3, top + 0.7 * s, -0.5 * s), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
		lamp.CastShadow = false
		if i == 0 then
			local spot = Instance.new("SpotLight")
			spot.Face = Enum.NormalId.Bottom
			spot.Angle = 100
			spot.Range = 14 * s
			spot.Brightness = 1.5
			spot.Color = Color3.fromRGB(255, 236, 200)
			spot.Enabled = false
			spot.Parent = lamp
			CollectionService:AddTag(spot, "WorldLight")
		end
	end
	-- The screen (its Front faces the spawn): the client draws the tiles on it.
	local screen = piece(m, "Screen", Vector3.new(W, H, 0.25 * s), cf * CFrame.new(0, lift + H / 2, 0.05 * s), Color3.fromRGB(16, 20, 34), Enum.Material.SmoothPlastic)
	screen.CastShadow = false
	screen.CanQuery = true -- (taps reach the SurfaceGui on it)
	screen:SetAttribute("Home", home == true or nil)
	CollectionService:AddTag(screen, "MapBoardScreen")
	-- E / a pad's button: the MAPS window (the client handles it: MapBoardClient).
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MapBoardPrompt"
	prompt.Enabled = false -- (24 Nov 2026, owner: no E on the map board; its pictures are pressed, pads use MENU)
	prompt.ActionText = "Choose a map"
	prompt.ObjectText = "Maps"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = screen
	for _, d in m:GetChildren() do
		if d:IsA("BasePart") and (d.Name == "Post" or d.Name == "Foot" or d.Name == "Beam" or d.Name == "Bezel") then
			d.CanCollide = true -- (fix round 1: a solid frame)
		end
	end
	m.Parent = parent
	return m
end

-- How far round from the spawn's facing (degrees, + = left) and how far out: a point on the floor.
local function aroundSpawn(origin: Vector3, facing: Vector3, degrees: number, distance: number): Vector3
	local dir = CFrame.Angles(0, math.rad(degrees), 0):VectorToWorldSpace(facing)
	return floorUnder(origin + dir * distance)
end

-- V9-NOW 20 + 22 (Config.TRAVEL_CORNER; owner, 21 Nov 2026: "the Map Board with the portals", then "out of the middle,
-- to the edge of the hub", then "swap the red button and all the portals"): one travel corner on the hub's rim, 42 studs
-- out where the BIG RED BUTTON stood (the button took the board's old spot, PathPlan.BUTTON_AT): the MAPS board in the
-- middle, SINGLEPLAYER and MULTIPLAYER either side along the rim, all turned to the hub's middle.
MapBoard.TRAVEL_SPOTS = table.freeze({
	-- (0.37.14, owner: "the portals and the map where the 3 white blocks stand behind the spider, one portal each
	-- side of the map board"): in a row across the back of the lab, the board in the middle (lab studs, not spread).
	Board = Vector2.new(30, -24), -- (V10 phase 4, owner: "the maps up beside the event button": PathPlan.BUTTON_AT (16, -19) x LAB_SPREAD)
	-- (23 Nov 2026, owner: "the 2 portals up here, smooth against the edge of the circle you spawn in"): just outside
	-- the spawn plaza's rim (radius 30) towards the Heights decks, turned to the middle.
	PortalSolo = Vector2.new(-31, -14),
	PortalMulti = Vector2.new(-23.5, -25),
}) :: { [string]: Vector2 }
-- Where a piece of the travel corner stands (lab space -> world, on the floor) and the point it faces.
function MapBoard.travelSpot(origin: Vector3, name: string): (Vector3, Vector3)
	local s = MapBoard.TRAVEL_SPOTS[name] or Vector2.zero
	return floorUnder(origin + Vector3.new(s.X, 0, s.Y)), origin -- (turned to the hub's middle)
end

-- The board and the PLACES portal in one lab (Playground builds the lab).
function MapBoard.buildLab(folder: Instance, origin: Vector3)
	if not Config.MAP_BOARD then
		return
	end
	local Lab = require(script.Parent:WaitForChild("Lab")) :: any
	local facing = Lab.SPAWN_FACING :: Vector3
	local spawn = origin
	local holder = Instance.new("Folder")
	holder.Name = "MapPlace"
	local boardAt = aroundSpawn(origin, facing, MapBoard.BOARD_ANGLE, MapBoard.BOARD_DISTANCE)
	local boardFace = spawn
	if (Config :: any).TRAVEL_CORNER then
		boardAt, boardFace = MapBoard.travelSpot(origin, "Board") -- (V9-NOW 22: on the rim with the portals)
	end
	if (Config :: any).LAB_OWNERMAP then
		-- (Map round 2: the MAPS board stands on the raised plaza beside the leaderboards, facing the stair.)
		local mb = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).at("MapsBoard", (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).at("Spawn", Vector2.new(25, -320), 38, -6))
		boardAt = origin + Vector3.new(mb.X, 4, mb.Y) -- (OwnerMapPlan MapsBoard, facing west across the plaza; M4: the east end of the compact spawn plaza)
		boardFace = boardAt + Vector3.new(-20, 0, 0)
	end
	MapBoard.board(holder, boardAt, boardFace)
	-- (V9-NOW: Config.MAP_PORTAL false = no gold ring portal; the board is the one map place.)
	if (Config :: any).MAP_PORTAL then
		local gateAt = aroundSpawn(origin, facing, MapBoard.PORTAL_ANGLE, MapBoard.PORTAL_DISTANCE)
		local _, swirl = MapBoard.gate(holder, gateAt, spawn, "Places")
		MapBoard.watchSwirl(swirl)
	end
	holder.Parent = folder
end

-- A map's copy by its arrival: My lab first on the board, the PLACES portal beside it. (Fix round 1: to
-- the sides of the way in, not across the map's first view.)
function MapBoard.buildMap(id: string, arrival: CFrame, into: Instance)
	local holder = Instance.new("Folder")
	holder.Name = "MapPlace"
	local look = arrival.LookVector
	local right = arrival.RightVector
	local at = arrival.Position
	local boardAt = floorUnder(at + look * 7 - right * 15)
	MapBoard.board(holder, boardAt, at + look * 4, MapBoard.MAP_SCALE, true)
	if (Config :: any).MAP_PORTAL then
		local gateAt = floorUnder(at + look * 7 + right * 16)
		local _, swirl = MapBoard.gate(holder, gateAt, at + look * 4, "Places", MapBoard.MAP_SCALE)
		MapBoard.watchSwirl(swirl)
	end
	holder:SetAttribute("Place", id)
	holder.Parent = into
end

local remote: RemoteEvent? = nil
local lastOpen: { [Player]: number } = {}
local dwellSince: { [Player]: number } = {}
local swirls: { BasePart } = {}

-- (Fix round 1) A PLACES swirl is stepped into, not touched: the server looks every POLL s at who stands in
-- one (CanTouch off: no touch traffic from the dummies lying round it).
function MapBoard.watchSwirl(swirl: BasePart)
	swirl.CanTouch = false
	table.insert(swirls, swirl)
	swirl.Destroying:Connect(function()
		local i = table.find(swirls, swirl)
		if i then
			table.remove(swirls, i)
		end
	end)
end

-- Whether a point stands in a swirl: inside the ring, within 2.5 studs of its face (pure but for the part).
function MapBoard.insideSwirl(swirl: BasePart, at: Vector3): boolean
	-- (The swirl is a cylinder turned so its axis (local X) points out of the ring's face.)
	local p = swirl.CFrame:PointToObjectSpace(at)
	local radius = swirl.Size.Y / 2
	return math.abs(p.X) < 2.5 and (p.Y * p.Y + p.Z * p.Z) < (radius * 0.85) ^ 2
end

-- Whether a player may be taken to the maps by stepping in: standing on their feet, not in a seat, not
-- holding or held, not in a chase, past a newcomer's quiet start (fix round 1: a run, a fling, a car or a
-- throw through the portal opens nothing).
function MapBoard.mayWalkIn(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local state = character:GetAttribute("RagdollState")
	if character:GetAttribute("BodyLoose") or (state ~= nil and state ~= "Standing") then
		return false
	end
	local seat = humanoid.SeatPart
	if seat and seat.Parent then
		return false
	end
	local okGrab, busy = pcall(function()
		local PlayerGrab = require(script.Parent:WaitForChild("PlayerGrab")) :: any
		return PlayerGrab.holdingOf(player) ~= nil or PlayerGrab.heldByOf(player) ~= nil
	end)
	if okGrab and busy then
		return false
	end
	if type(player:GetAttribute("ChaseLeft")) == "number" and (player:GetAttribute("ChaseLeft") :: number) > 0 then -- (a chase on: ChaseService)
		return false
	end
	-- (A newcomer's quiet start, as the server knows it: Newcomer and the join time, Config.QUIET_START s.)
	local joined = player:GetAttribute("V8JoinedAt")
	if player:GetAttribute("Newcomer") == true and type(joined) == "number" and Workspace:GetServerTimeNow() - joined < (Config.QUIET_START or 0) then
		return false
	end
	return true
end

local function openFor(player: Player)
	lastOpen[player] = os.clock()
	remote = remote or Net.event(Net.Names.Portal)
	;(remote :: RemoteEvent):FireClient(player, "Open", { portal = "PortalPlaces" })
	pcall(function()
		(require(script.Parent:WaitForChild("SessionStats")) :: any).used(player, "portalPlaces")
	end)
end

local function poll()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local inside = false
		if root and root:IsA("BasePart") then
			for _, swirl in swirls do
				if (swirl.Position - root.Position).Magnitude < swirl.Size.Y and MapBoard.insideSwirl(swirl, root.Position) then
					inside = true
					break
				end
			end
		end
		if inside and MapBoard.mayWalkIn(player) then
			dwellSince[player] = dwellSince[player] or now
			if now - (dwellSince[player] :: number) >= MapBoard.DWELL and now - (lastOpen[player] or -math.huge) >= MapBoard.TOUCH_GAP then
				openFor(player)
			end
		else
			dwellSince[player] = nil
		end
	end
end
MapBoard.pollForTest = poll
function MapBoard.lastOpenForTest(player: Player): number?
	return lastOpen[player]
end

-- Players in each place now (by their Place attribute), written on every board.
function MapBoard.counts(): { [string]: number }
	local counts: { [string]: number } = {}
	for _, p in Players:GetPlayers() do
		local place = p:GetAttribute("Place")
		if type(place) == "string" then
			counts[place] = (counts[place] or 0) + 1
		end
	end
	return counts
end

function MapBoard.start()
	if not Config.MAP_BOARD then
		return
	end
	-- The maps' copies, once the maps stand.
	task.spawn(function()
		local WorldMaps = require(script.Parent:WaitForChild("WorldMaps")) :: any
		for _ = 1, 60 do
			if WorldMaps.folder() then
				break
			end
			task.wait(1)
		end
		local mapsFolder = WorldMaps.folder()
		-- (V10 phase 4, owner: "a map at the plaza, so you can get away from it again": the same board at the
		-- plaza's arrival.)
		pcall(function()
			local arrival = WorldMaps.arrival("Plaza")
			local playground = workspace:FindFirstChild("Playground")
			local plaza = playground and playground:FindFirstChild("Plaza")
			if arrival and plaza and not plaza:FindFirstChild("MapPlace") then
				MapBoard.buildMap("Plaza", arrival - Vector3.new(0, 3.5, 0), plaza)
			end
		end)
		for _, place in Places.list do
			if place.outdoor then
				local ok, err = pcall(function()
					local arrival = WorldMaps.arrival(place.id)
					local built = mapsFolder and mapsFolder:FindFirstChild(place.id)
					if arrival and built then
						MapBoard.buildMap(place.id, arrival, built)
					end
				end)
				if not ok then
					warn("[MapBoard] " .. place.id .. ": " .. tostring(err))
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			local counts = MapBoard.counts()
			for _, screen in CollectionService:GetTagged("MapBoardScreen") do
				for _, place in Places.list do
					local n = counts[place.id] or 0
					if screen:GetAttribute("Count_" .. place.id) ~= n then
						screen:SetAttribute("Count_" .. place.id, n)
					end
				end
			end
			task.wait(MapBoard.COUNT_EVERY)
		end
	end)
	-- (Fix round 1: who stands in a PLACES swirl, every POLL s.)
	task.spawn(function()
		while true do
			task.wait(MapBoard.POLL)
			local ok, err = pcall(poll)
			if not ok then
				warn("[MapBoard] " .. tostring(err))
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		lastOpen[p] = nil
		dwellSince[p] = nil
	end)
end

return MapBoard
