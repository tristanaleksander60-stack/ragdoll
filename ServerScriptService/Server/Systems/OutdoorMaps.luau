--!strict
-- v3 phase B (19 Nov 2026): the open-air maps (Places entries with `outdoor`), built in their own
-- row far from the labs (Places.OUTDOOR_Z): terrain land and sea, real Creator Store models from
-- ServerStorage.V3Assets (V3Assets.place; nothing appears for a role the place lacks), and a few
-- code-built pieces (paths, a jetty, huts). The room contract WorldMaps and the tests rely on is
-- kept: a "Floor" part marked Floor (the crowd stands on it), an "Arrival" pad, and walls named
-- WallN/S/E/W, here invisible, at the edge of the land (no ceiling: the sky is the point).
-- Every part is anchored; decoration does not collide.

local Workspace = game:GetService("Workspace")

local V3Assets = require(script.Parent.V3Assets)

local OutdoorMaps = {}

local ARRIVE_BACK = 12 -- like WorldMaps: the pad, studs in from the south edge
local EDGE_WALL = 4

-- Where the arrival pad is: `arrive` studs south of the middle (Places), else by the south edge.
function OutdoorMaps.arriveZ(place: any): number
	return if type(place.arrive) == "number" then -place.arrive else -place.size.Z / 2 + ARRIVE_BACK
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = collide ~= false
	if collide == false then
		p.CanQuery = false
		p.CanTouch = false
	end
	p.Parent = parent
	return p
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- The room contract: the floor the crowd stands on (`look` false: invisible, the terrain shows),
-- invisible edge walls, and the arrival pad by the south edge looking north.
local function frame(m: Instance, place: any, c: Vector3, floorColor: Color3, floorMat: Enum.Material, visibleFloor: boolean)
	local s = place.size
	local floor = part(m, "Floor", Vector3.new(s.X, 8, s.Z), CFrame.new(c - Vector3.new(0, 4, 0)), floorColor, floorMat)
	floor:SetAttribute("Floor", true)
	floor.CastShadow = false
	if not visibleFloor then
		floor.Transparency = 1
	end
	local h = s.Y / 2
	for name, cf in {
		WallN = CFrame.new(c + Vector3.new(0, h, s.Z / 2 + EDGE_WALL / 2)),
		WallS = CFrame.new(c + Vector3.new(0, h, -s.Z / 2 - EDGE_WALL / 2)),
		WallE = CFrame.new(c + Vector3.new(s.X / 2 + EDGE_WALL / 2, h, 0)) * CFrame.Angles(0, math.rad(90), 0),
		WallW = CFrame.new(c + Vector3.new(-s.X / 2 - EDGE_WALL / 2, h, 0)) * CFrame.Angles(0, math.rad(90), 0),
	} do
		local long = if name == "WallE" or name == "WallW" then s.Z else s.X
		local wall = part(m, name, Vector3.new(long + EDGE_WALL * 2, s.Y, EDGE_WALL), cf, rgb(255, 255, 255))
		wall.Transparency = 1
		wall.CastShadow = false
	end
	local pad = part(m, "Arrival", Vector3.new(8, 0.1, 8), CFrame.new(c + Vector3.new(0, 0.05, OutdoorMaps.arriveZ(place))), Color3.fromHex(place.color), Enum.Material.SmoothPlastic, false)
	pad.Transparency = 0.45
	pad:SetAttribute("Arrival", place.id)
end

-- A real model standing at `at` (flat), turned `yaw` degrees; nil when the place lacks it.
local function prop(m: Instance, role: string, at: Vector3, yaw: number, height: number?, size: number?, collide: boolean?): Model?
	return V3Assets.place(role, m, CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0), { height = height, size = size, collide = collide == true })
end

-- A seeded scatter of `count` points in a ring around `c` (radius r0..r1), clear of `avoid`.
local function scatter(seed: number, c: Vector3, count: number, r0: number, r1: number, avoid: { { at: Vector3, r: number } }): { Vector3 }
	local rng = Random.new(seed)
	local out = {}
	local tries = 0
	while #out < count and tries < count * 20 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(r0, r1)
		local p = c + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local ok = true
		for _, z in avoid do
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(z.at.X, 0, z.at.Z)).Magnitude < z.r then
				ok = false
				break
			end
		end
		if ok then
			table.insert(out, p)
			table.insert(avoid, { at = p, r = 7 })
		end
	end
	return out
end

local BUILDERS: { [string]: (Model, any, Vector3) -> () } = {}

------------------------------------------------------------------------------------------------
-- ISLAND: a sand island in a blue sea, palms and rocks, a grassy middle, a cliff to dive off, a
-- wooden jetty with a boat, beach huts and a striped lighthouse.

BUILDERS.Island = function(m, place, mid)
	-- (Terrain fills on a 4-stud grid and its top lands a few studs off the asked height, more so
	-- where fills overlap: PC check 19 Nov. So the land is filled first, its real top measured, and
	-- the floor and every piece stand on that.)
	local c = mid
	local s = place.size
	local terrain = Workspace.Terrain
	-- The sea (a wide shallow block, its top a little under the beach) and the island on it.
	terrain:FillBlock(CFrame.new(c - Vector3.new(0, 14, 0)), Vector3.new(s.X + 1800, 16, s.Z + 1800), Enum.Material.Water) -- (top about 4 under the beach)
	terrain:FillBlock(CFrame.new(c - Vector3.new(0, 26, 0)), Vector3.new(s.X + 1800, 8, s.Z + 1800), Enum.Material.Sand)
	terrain:FillCylinder(CFrame.new(c - Vector3.new(0, 8, 0)), 12, s.X * 0.42, Enum.Material.Sand)
	terrain:FillCylinder(CFrame.new(c - Vector3.new(0, 8, 0)), 12, s.X * 0.3, Enum.Material.Grass)
	-- (A round island reads as code-built: coves and points along the shore, and the grass in lobes.)
	do
		local rng = Random.new(77)
		for i = 1, 14 do
			local a = (i / 14) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
			local r = s.X * rng:NextNumber(0.36, 0.44)
			local at = c + Vector3.new(math.cos(a) * r, -8, math.sin(a) * r)
			terrain:FillCylinder(CFrame.new(at), 12, rng:NextNumber(18, 38), Enum.Material.Sand)
		end
		for i = 1, 9 do
			local a = (i / 9) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
			local r = s.X * rng:NextNumber(0.2, 0.3)
			local at = c + Vector3.new(math.cos(a) * r, -8, math.sin(a) * r)
			terrain:FillCylinder(CFrame.new(at), 12, rng:NextNumber(16, 30), Enum.Material.Grass)
		end
	end
	-- A soft grass hill north-west of the middle.
	terrain:FillBall(c + Vector3.new(-40, -14, 40), 26, Enum.Material.Grass)
	do
		local only = RaycastParams.new()
		only.FilterType = Enum.RaycastFilterType.Include
		only.FilterDescendantsInstances = { terrain }
		local hit = Workspace:Raycast(mid + Vector3.new(30, 80, -60), Vector3.new(0, -160, 0), only)
		if hit then
			c = Vector3.new(mid.X, hit.Position.Y, mid.Z)
		end
	end
	frame(m, place, c, rgb(222, 205, 160), Enum.Material.Sand, false)
	-- The cliff (north-east): a rock mound with a flat top 34 studs up, to dive off into the sea.
	local cliff = c + Vector3.new(s.X * 0.28, 0, s.Z * 0.3)
	terrain:FillBall(cliff + Vector3.new(0, 4, 0), 38, Enum.Material.Rock)
	-- (Not one dome: a ridge of boulders round it, and grass on its shoulders.)
	for _, b in { { Vector3.new(-26, -6, 14), 24 }, { Vector3.new(22, -4, -18), 26 }, { Vector3.new(10, 8, 26), 20 }, { Vector3.new(-14, 14, -10), 18 }, { Vector3.new(28, 2, 20), 22 } } do
		terrain:FillBall(cliff + b[1], b[2], Enum.Material.Rock)
	end
	terrain:FillBall(cliff + Vector3.new(-30, -10, -22), 20, Enum.Material.Grass)
	terrain:FillBlock(CFrame.new(cliff + Vector3.new(0, 44, 0)), Vector3.new(90, 16, 90), Enum.Material.Air)
	local top = part(m, "CliffTop", Vector3.new(26, 2, 26), CFrame.new(cliff + Vector3.new(0, 35, 0)), rgb(120, 112, 100), Enum.Material.Slate)
	top:SetAttribute("Activity", "CliffDive")
	-- Steps up the cliff's south side.
	for i = 0, 11 do
		part(m, "CliffStep", Vector3.new(8, 3, 5), CFrame.new(cliff + Vector3.new(-14, 1.5 + i * 3, -30 + i * 2.4)), rgb(140, 132, 118), Enum.Material.Slate)
	end
	-- The jetty (west) into the sea, posts under it, a boat tied at its end.
	local jetty = c + Vector3.new(-s.X * 0.42, 0, -10)
	for i = 0, 9 do
		local at = jetty + Vector3.new(-i * 6, 0.6, 0)
		part(m, "JettyPlank", Vector3.new(5.6, 0.6, 10), CFrame.new(at), rgb(140, 100, 64), Enum.Material.WoodPlanks)
		for _, z in { -4.4, 4.4 } do
			part(m, "JettyPost", Vector3.new(0.9, 9, 0.9), CFrame.new(at + Vector3.new(0, -4, z)), rgb(96, 70, 46), Enum.Material.Wood)
		end
	end
	local boat = Instance.new("Model")
	boat.Name = "Boat"
	local bAt = jetty + Vector3.new(-50, -1, 12)
	part(boat, "Hull", Vector3.new(18, 3, 7), CFrame.new(bAt), rgb(235, 238, 242), Enum.Material.SmoothPlastic)
	part(boat, "Bow", Vector3.new(7, 3, 5), CFrame.new(bAt + Vector3.new(-12, 0, 0)) * CFrame.Angles(0, math.rad(90), 0), rgb(235, 238, 242), Enum.Material.SmoothPlastic)
	part(boat, "Stripe", Vector3.new(18.2, 0.6, 7.2), CFrame.new(bAt + Vector3.new(0, 0.6, 0)), rgb(30, 110, 200), Enum.Material.SmoothPlastic, false)
	part(boat, "Cabin", Vector3.new(6, 3, 5), CFrame.new(bAt + Vector3.new(2, 3, 0)), rgb(250, 250, 250), Enum.Material.Glass)
	boat.Parent = m
	-- Beach huts (south-east), each a box with a striped roof.
	for i, x in { 30, 46, 62 } do
		local at = c + Vector3.new(x, 0, -s.Z * 0.26)
		local hut = Instance.new("Model")
		hut.Name = "BeachHut"
		local colour = ({ rgb(240, 120, 90), rgb(90, 170, 230), rgb(250, 210, 90) })[i]
		part(hut, "Walls", Vector3.new(10, 8, 9), CFrame.new(at + Vector3.new(0, 4, 0)), rgb(245, 240, 228), Enum.Material.WoodPlanks)
		part(hut, "Roof", Vector3.new(12, 1, 11), CFrame.new(at + Vector3.new(0, 8.6, 0)) * CFrame.Angles(0, 0, math.rad(8)), colour, Enum.Material.SmoothPlastic)
		part(hut, "Door", Vector3.new(3, 6, 0.3), CFrame.new(at + Vector3.new(0, 3, -4.6)), colour, Enum.Material.SmoothPlastic, false)
		hut.Parent = m
	end
	-- The lighthouse (south-west point): white and red rings, a lamp on top.
	local lh = c + Vector3.new(-s.X * 0.3, 0, -s.Z * 0.32)
	for i = 0, 7 do
		local ring = part(m, "Lighthouse", Vector3.new(5, 10, 10), CFrame.new(lh + Vector3.new(0, 2.5 + i * 5, 0)) * CFrame.Angles(0, 0, math.rad(90)), if i % 2 == 0 then rgb(240, 240, 240) else rgb(210, 50, 50), Enum.Material.SmoothPlastic)
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(5, 10 - i * 0.4, 10 - i * 0.4)
	end
	local lamp = part(m, "LighthouseLamp", Vector3.new(5, 5, 5), CFrame.new(lh + Vector3.new(0, 44, 0)), rgb(255, 236, 160), Enum.Material.Neon, false)
	lamp.Shape = Enum.PartType.Ball
	-- A catapult (south of the middle): a code-built launch arm on a base (Phase C makes it throw).
	local cat = c + Vector3.new(-30, 0, -40)
	part(m, "CatapultBase", Vector3.new(10, 2, 14), CFrame.new(cat + Vector3.new(0, 1, 0)), rgb(110, 80, 52), Enum.Material.Wood)
	local arm = part(m, "CatapultArm", Vector3.new(2, 1.4, 18), CFrame.new(cat + Vector3.new(0, 4, 0)) * CFrame.Angles(math.rad(-25), 0, 0), rgb(130, 95, 60), Enum.Material.Wood)
	arm:SetAttribute("Activity", "Catapult")
	part(m, "CatapultCup", Vector3.new(5, 1, 5), CFrame.new(cat + Vector3.new(0, 7.6, 8)), rgb(96, 70, 46), Enum.Material.Wood)
	-- Palms round the beach, bushes and rocks: real models.
	local avoid = {
		{ at = cliff, r = 46 }, { at = jetty, r = 16 }, { at = lh, r = 14 }, { at = cat, r = 16 },
		{ at = c + Vector3.new(0, 0, OutdoorMaps.arriveZ(place)), r = 20 }, { at = c + Vector3.new(-40, 0, 40), r = 24 }, { at = c + Vector3.new(46, 0, -s.Z * 0.26), r = 26 },
	}
	for i, p in scatter(11, c, 28, s.X * 0.28, s.X * 0.4, avoid) do
		prop(m, "TreePalm", p, (i * 47) % 360, 26 + (i % 4) * 4)
	end
	for i, p in scatter(23, c, 18, 10, s.X * 0.26, avoid) do
		prop(m, "Bush", p, (i * 61) % 360, 3 + (i % 3))
	end
	for i, p in scatter(37, c, 14, s.X * 0.36, s.X * 0.44, avoid) do
		prop(m, "Rock", p, (i * 83) % 360, 4 + (i % 3) * 2, nil, true)
	end
	for i, p in scatter(41, c, 4, 14, s.X * 0.22, avoid) do
		prop(m, "Crate", p, (i * 29) % 360, 4)
	end
	prop(m, "Barrel", jetty + Vector3.new(4, 0, 8), 0, 4)
	prop(m, "Barrel", jetty + Vector3.new(7, 0, 9), 50, 4)
end

------------------------------------------------------------------------------------------------

function OutdoorMaps.has(id: string): boolean
	return BUILDERS[id] ~= nil
end

function OutdoorMaps.build(m: Model, place: any, c: Vector3)
	local builder = BUILDERS[place.id]
	if builder then
		builder(m, place, c)
	end
end

return OutdoorMaps
