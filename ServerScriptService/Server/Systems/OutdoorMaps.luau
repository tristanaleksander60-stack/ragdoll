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
		-- (Terrain is the ground there: the slab is only the crowd's Floor marker. Solid, it made a
		-- glass floor over the sea and over the pit: blind review 19 Nov.)
		floor.CanCollide = false
		floor.CanTouch = false
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

-- A piece of a Creator Store pack kept whole in ServerStorage.V3Packs.<pack> (imported and
-- cleaned in Studio, place file only): the first model named `name` in it, copied, every part
-- anchored, shrunk to `fit` studs across if wider, its bottom middle on `at`, turned `yaw` degrees.
-- nil when the place lacks the pack (the map is then built without it).
local function piece(m: Instance, pack: string, name: string, at: Vector3, yaw: number, fit: number?, collide: boolean?): Model?
	local packs = game:GetService("ServerStorage"):FindFirstChild("V3Packs")
	local src = packs and packs:FindFirstChild(pack)
	local found: Instance? = nil
	if src and string.find(name, ">", 1, true) then
		-- A path: "Farm Pack>Buildings>Barns>2" (a number = the nth child, packs reuse "Model").
		local node: Instance? = src
		for _, seg in string.split(name, ">") do
			local n = tonumber(seg)
			local nextNode: Instance? = nil
			if node then
				nextNode = if n then node:GetChildren()[n] else node:FindFirstChild(seg)
			end
			node = nextNode
		end
		found = node
	elseif src then
		for _, d in src:GetDescendants() do
			if (d:IsA("Model") or d:IsA("BasePart")) and d.Name == name then
				found = d
				break
			end
		end
	end
	if not found then
		return nil
	end
	local copy: Model
	if found:IsA("Model") then
		copy = found:Clone()
	else
		copy = Instance.new("Model")
		copy.Name = found.Name
		found:Clone().Parent = copy
	end
	local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if collide == false then
				d.CanCollide = false
				d.CanTouch = false
			end
			if d.Transparency < 0.95 then
				for _, sx in { -1, 1 } do
					for _, sy in { -1, 1 } do
						for _, sz in { -1, 1 } do
							local p = d.CFrame:PointToWorldSpace(d.Size / 2 * Vector3.new(sx, sy, sz))
							mn = mn:Min(p)
							mx = mx:Max(p)
						end
					end
				end
			end
		end
	end
	copy.WorldPivot = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
	local across = math.max(mx.X - mn.X, mx.Z - mn.Z)
	if fit and across > fit then
		pcall(function()
			copy:ScaleTo(copy:GetScale() * fit / across)
		end)
	end
	copy:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0))
	copy.Parent = m
	return copy
end

-- A launcher (phase C, MapActivities throws whoever touches it): a glowing pad with an arrow the
-- way it throws and a small sign. `velocity` is world studs/s.
local function launcher(m: Instance, at: Vector3, velocity: Vector3, what: string, colour: Color3, size: number?): Part
	local w = size or 8
	local pad = part(m, "Launcher", Vector3.new(w, 0.6, w), CFrame.new(at + Vector3.new(0, 0.3, 0)), colour, Enum.Material.Neon)
	pad:SetAttribute("Launch", velocity)
	pad:SetAttribute("What", what)
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	if flat.Magnitude > 1 then
		local arrow = part(m, "LauncherArrow", Vector3.new(1.2, 0.1, w * 0.7), CFrame.lookAt(at + Vector3.new(0, 0.65, 0), at + Vector3.new(0, 0.65, 0) + flat.Unit), rgb(255, 255, 255), Enum.Material.Neon, false)
		arrow.Transparency = 0.1
	end
	local ring = part(m, "LauncherRim", Vector3.new(w + 1, 0.4, w + 1), CFrame.new(at + Vector3.new(0, 0.2, 0)), rgb(30, 30, 34), Enum.Material.Metal, false)
	ring.CastShadow = false
	return pad
end

local BUILDERS: { [string]: (Model, any, Vector3) -> () } = {}

------------------------------------------------------------------------------------------------
-- CITY: one downtown block round a big crossroads (Roblox's City packs: the crossing, buildings,
-- street props; Sedan and SUV parked), straight streets to the edges, sidewalks with lamps,
-- hydrants, benches, a bus stop, a kiosk; tall towers beyond the edges for a skyline.

BUILDERS.City = function(m, place, c)
	local s = place.size
	local half = s.X / 2
	local ROAD, WALK = 80, 20 -- the crossing's lanes and sidewalks (Road_Intersection_01_A)
	local CROSS = 60 -- half the crossing
	frame(m, place, c, rgb(150, 150, 154), Enum.Material.Concrete, true)
	local asphalt = rgb(70, 72, 78)
	local walk = rgb(165, 165, 168)
	piece(m, "CityRoads", "Road_Intersection_01_A", c, 0)
	-- The four streets: asphalt, raised sidewalks with a curb, a double yellow line, white dashes.
	for i = 0, 3 do
		local yaw = math.rad(i * 90)
		local function at(x: number, y: number, z: number): CFrame
			return CFrame.new(c) * CFrame.Angles(0, yaw, 0) * CFrame.new(x, y, z)
		end
		local len = half - CROSS
		local mid = CROSS + len / 2
		part(m, "Street", Vector3.new(ROAD, 1, len), at(0, 0.5, mid), asphalt, Enum.Material.Asphalt)
		for _, side in { -1, 1 } do
			part(m, "Sidewalk", Vector3.new(WALK, 1.6, len), at(side * (ROAD / 2 + WALK / 2), 0.8, mid), walk, Enum.Material.Concrete)
			part(m, "Curb", Vector3.new(0.8, 1.7, len), at(side * (ROAD / 2 + 0.4), 0.85, mid), rgb(190, 190, 192), Enum.Material.Concrete)
			part(m, "YellowLine", Vector3.new(0.5, 0.05, len), at(side * 0.6, 1.02, mid), rgb(235, 190, 40), Enum.Material.SmoothPlastic, false)
		end
		for z = CROSS + 8, half - 8, 16 do
			for _, x in { -20, 20 } do
				part(m, "LaneDash", Vector3.new(0.5, 0.05, 7), at(x, 1.02, z), rgb(240, 240, 240), Enum.Material.SmoothPlastic, false)
			end
		end
		-- Street furniture along both sidewalks, lamps facing the street.
		for k, z in { CROSS + 24, CROSS + 64, CROSS + 104, CROSS + 144 } do
			if z < half - 8 then
				for _, side in { -1, 1 } do
					local x = side * (ROAD / 2 + 3)
					local base = at(x, 1.6, z).Position
					piece(m, "CityProps", "StreetLightPole_01_A", base, i * 90 + (if side < 0 then 0 else 180), nil, false)
					local extras = { "FireHydrant_01_A", "MetalBench_01_A", "Garbage_Bin_01", "Newspaper_Stand_01_A", "Mailbox_01_A", "Planter_Round_01_A" }
					local pick = extras[((k + i * 2 + (if side < 0 then 0 else 3)) % #extras) + 1]
					piece(m, "CityProps", pick, at(side * (ROAD / 2 + 12), 1.6, z + 10).Position, i * 90 + (if side < 0 then 90 else -90), 10)
				end
			end
		end
		-- Parked cars along the curb (one side), a bus stop and a kiosk on the other.
		local carRoles = { "Car", "SUV" }
		for k, z in { CROSS + 40, CROSS + 84 } do
			local spot = at(ROAD / 2 - 6, 1, z).Position
			if carRoles[(k + i) % 2 + 1] == "Car" then
				V3Assets.place("Car", m, CFrame.new(spot) * CFrame.Angles(0, yaw, 0), { size = 19, collide = true })
			else
				piece(m, "SUV", "SUV (white)", spot, i * 90, 20)
			end
		end
		piece(m, "CityProps", "Bus_Stop_01_A", at(-(ROAD / 2 + 10), 1.6, CROSS + 80).Position, i * 90 + 90)
		if i % 2 == 0 then
			piece(m, "CityProps", "Kiosk_01_A", at(ROAD / 2 + 14, 1.6, CROSS + 120).Position, i * 90 - 90)
		end
		-- Barriers and cones where the street meets the map's edge.
		for x = -ROAD / 2 + 6, ROAD / 2 - 6, 12 do
			V3Assets.place("Barrier", m, at(x, 1, half - 6), { height = 3.2, collide = true })
		end
		for _, x in { -30, -10, 10, 30 } do
			V3Assets.place("Cone", m, at(x, 1, half - 16), { height = 2.4 })
		end
	end
	-- The four corner lots: a building each (their faces to the crossing), and a sidewalk round it.
	local lot = half - (CROSS + WALK)
	local buildings = { "building_01", "building_02", "building_07", "building_03" }
	for q = 0, 3 do
		local sx = if q == 0 or q == 3 then 1 else -1
		local sz = if q < 2 then 1 else -1
		local centre = c + Vector3.new(sx * (CROSS + WALK + lot / 2), 0, sz * (CROSS + WALK + lot / 2))
		part(m, "Plaza", Vector3.new(lot + WALK, 1.6, lot + WALK), CFrame.new(centre - Vector3.new(sx * WALK / 2, -0.8, sz * WALK / 2)), walk, Enum.Material.Concrete)
		piece(m, "CityBuildings", buildings[q + 1], centre + Vector3.new(0, 1.6, 0), q * 90 + 45 - 45, lot - 10, true)
		-- A tree planter and a bench on the lot's corner by the crossing.
		local corner = c + Vector3.new(sx * (CROSS + 12), 1.6, sz * (CROSS + 12))
		piece(m, "CityProps", "Planter_Square_01_A", corner, q * 90)
		prop(m, "TreeRound", corner + Vector3.new(sx * 8, 0, 0), q * 70, 18)
	end
	-- Phase C: burst manholes in two streets shoot you up the side of the towers.
	launcher(m, c + Vector3.new(0, 1, 120), Vector3.new(0, 190, 0), "the MANHOLE", rgb(120, 230, 255), 6)
	launcher(m, c + Vector3.new(-120, 1, 0), Vector3.new(0, 190, 0), "the MANHOLE", rgb(120, 230, 255), 6)
	-- The skyline: tall towers beyond each edge (outside the walls: scenery).
	local far = { { "building_05", Vector3.new(-1, 0, 1) }, { "building_08", Vector3.new(1, 0, 1) }, { "building_04", Vector3.new(-1, 0, -1) }, { "building_11", Vector3.new(1, 0, -1) } }
	for k, f in far do
		local at = c + f[2] * (half + 110)
		local tower = piece(m, "CityBuildings", f[1], at, k * 90, nil, true)
		if tower then
			for _, d in tower:GetDescendants() do
				if d:IsA("BasePart") then
					d.CastShadow = false
				end
			end
		end
	end
end

------------------------------------------------------------------------------------------------
-- BUILDING SITE: a fenced construction site on packed earth: a tower crane, scaffolding round a
-- concrete frame, a mixer truck, pallets, barrels, barriers, a dug pit with a ramp.

BUILDERS.Site = function(m, place, c)
	local s = place.size
	local half = s.X / 2
	local terrain = Workspace.Terrain
	-- Earth (ground), fill measured like the island's.
	terrain:FillBlock(CFrame.new(c - Vector3.new(0, 6, 0)), Vector3.new(s.X + 200, 12, s.Z + 200), Enum.Material.Ground)
	terrain:FillBlock(CFrame.new(c + Vector3.new(60, -8, 50)), Vector3.new(70, 16, 60), Enum.Material.Air) -- the pit
	terrain:FillBlock(CFrame.new(c + Vector3.new(60, -16, 50)), Vector3.new(70, 2, 60), Enum.Material.Mud)
	do
		local only = RaycastParams.new()
		only.FilterType = Enum.RaycastFilterType.Include
		only.FilterDescendantsInstances = { terrain }
		local hit = Workspace:Raycast(c + Vector3.new(-40, 80, -60), Vector3.new(0, -160, 0), only)
		if hit then
			c = Vector3.new(c.X, hit.Position.Y, c.Z)
		end
	end
	frame(m, place, c, rgb(120, 96, 70), Enum.Material.Ground, false)
	-- The pit's ramp down (driveable for ragdolls: they slide).
	part(m, "PitRamp", Vector3.new(14, 1, 40), CFrame.new(c + Vector3.new(20, -6, 50)) * CFrame.Angles(0, 0, math.rad(0)) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(-14)), rgb(150, 120, 90), Enum.Material.WoodPlanks)
	-- The concrete frame of a building going up: slabs on columns, three floors, the top one open.
	local frameAt = c + Vector3.new(-50, 0, 50)
	for floor = 0, 2 do
		local y = floor * 14
		part(m, "Slab", Vector3.new(60, 1.4, 44), CFrame.new(frameAt + Vector3.new(0, y + 0.7, 0)), rgb(170, 168, 162), Enum.Material.Concrete)
		for _, x in { -27, -9, 9, 27 } do
			for _, z in { -19, 19 } do
				part(m, "Column", Vector3.new(2, 14, 2), CFrame.new(frameAt + Vector3.new(x, y + 7.7, z)), rgb(160, 158, 152), Enum.Material.Concrete)
			end
		end
	end
	part(m, "Slab", Vector3.new(60, 1.4, 44), CFrame.new(frameAt + Vector3.new(0, 42.7, 0)), rgb(170, 168, 162), Enum.Material.Concrete)
	-- Steps up the frame (a stair of blocks at its south side) so players reach the top floor.
	for i = 0, 13 do
		part(m, "SiteStep", Vector3.new(6, 1, 3), CFrame.new(frameAt + Vector3.new(36, 1 + i * 3, -18 + i * 2.6)), rgb(140, 120, 90), Enum.Material.WoodPlanks)
	end
	piece(m, "Scaffold", "Scaffolding", frameAt + Vector3.new(0, 0, -26), 0, 64)
	-- The tower crane beside it, the mixer, site pieces.
	local crane = piece(m, "Crane", "Crane", c + Vector3.new(30, 0, 100), 200, nil, true)
	if not crane then
		-- (The crane pack is loose parts: its whole model.)
		local packs = game:GetService("ServerStorage"):FindFirstChild("V3Packs")
		local src = packs and packs:FindFirstChild("Crane")
		if src then
			local copy = src:Clone()
			copy.Name = "Crane"
			copy.Parent = m
			local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
			for _, d in copy:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					mn = mn:Min(d.Position)
					mx = mx:Max(d.Position)
				end
			end
			copy.WorldPivot = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
			copy:PivotTo(CFrame.new(c + Vector3.new(30, 0, 110)))
		end
	end
	local mixer = game:GetService("ServerStorage"):FindFirstChild("V3Packs")
	if mixer and mixer:FindFirstChild("Mixer") then
		local copy = mixer.Mixer:Clone()
		local hum = copy:FindFirstChildWhichIsA("Humanoid", true)
		if hum then
			hum:Destroy()
		end
		local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
		for _, d in copy:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				mn = mn:Min(d.Position - d.Size / 2)
				mx = mx:Max(d.Position + d.Size / 2)
			end
		end
		copy.WorldPivot = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
		local across = math.max(mx.X - mn.X, mx.Z - mn.Z)
		if across > 0 then
			pcall(function()
				copy:ScaleTo(copy:GetScale() * 26 / across)
			end)
		end
		copy:PivotTo(CFrame.new(c + Vector3.new(-80, 0, -40)) * CFrame.Angles(0, math.rad(30), 0))
		copy.Parent = m
	end
	-- The pack's site meshes scattered in groups: pallets, planks, gas bottles, a container.
	local packs = game:GetService("ServerStorage"):FindFirstChild("V3Packs")
	local meshes = packs and packs:FindFirstChild("SiteMeshes")
	if meshes then
		local rng = Random.new(91)
		local spots = scatter(91, c, 22, 30, half - 20, {
			{ at = frameAt, r = 46 }, { at = c + Vector3.new(60, 0, 50), r = 44 }, { at = c + Vector3.new(30, 0, 110), r = 24 },
			{ at = c + Vector3.new(-80, 0, -40), r = 20 }, { at = c + Vector3.new(0, 0, OutdoorMaps.arriveZ(place)), r = 24 },
		})
		local list = {}
		for _, d in meshes:GetDescendants() do
			if d:IsA("BasePart") then
				local n = d.Name:lower()
				if not (n:find("hammer") or n:find("crowbar") or n:find("wrench") or n:find("bat")) and d.Size.Magnitude > 3 then
					table.insert(list, d)
				end
			end
		end
		for i, spot in spots do
			local src = list[(i - 1) % math.max(#list, 1) + 1]
			if src then
				local copy = src:Clone()
				copy.Anchored = true
				copy.CFrame = CFrame.new(spot + Vector3.new(0, copy.Size.Y / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
				copy.Parent = m
			end
		end
	end
	-- Site edges: a chain-link fence round it, barriers and cones by the pit, barrels.
	for x = -half + 6, half - 6, 12 do
		for _, z in { -half + 3, half - 3 } do
			V3Assets.place("Fence", m, CFrame.new(c + Vector3.new(x, 0, z)), { size = 12, collide = true })
		end
	end
	for z = -half + 6, half - 6, 12 do
		for _, x in { -half + 3, half - 3 } do
			V3Assets.place("Fence", m, CFrame.new(c + Vector3.new(x, 0, z)) * CFrame.Angles(0, math.rad(90), 0), { size = 12, collide = true })
		end
	end
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		V3Assets.place("Barrier", m, CFrame.new(c + Vector3.new(60 + math.cos(a) * 42, 0, 50 + math.sin(a) * 36)) * CFrame.Angles(0, -a + math.pi / 2, 0), { height = 3.2, collide = true })
	end
	for i, p in scatter(5, c, 10, 20, half - 30, { { at = frameAt, r = 40 }, { at = c + Vector3.new(60, 0, 50), r = 44 } }) do
		V3Assets.place(if i % 2 == 0 then "Barrel" else "Cone", m, CFrame.new(p), { height = if i % 2 == 0 then 4 else 2.4, collide = i % 2 == 0 })
	end
	-- Phase C: a jump pad at the pit's edge flings you over it; one by the frame throws you onto its roof.
	launcher(m, c + Vector3.new(60, 0, 4), Vector3.new(0, 110, 95), "the PIT JUMP", rgb(255, 200, 40))
	launcher(m, frameAt + Vector3.new(0, 0, -36), Vector3.new(0, 150, 40), "the ROOF LAUNCH", rgb(255, 120, 40))
	-- (PC look 19 Nov: too empty.) Dirt heaps, a gravel track from the gate to the frame, site
	-- containers, the monster truck and a car parked, stacked crates and pallets, more barrels.
	for _, h in { { Vector3.new(-110, -6, 100), 22 }, { Vector3.new(110, -8, -80), 26 }, { Vector3.new(-120, -10, -110), 20 }, { Vector3.new(120, -6, 110), 18 }, { Vector3.new(0, -12, 130), 24 } } do
		terrain:FillBall(c + h[1], h[2], Enum.Material.Ground)
	end
	terrain:FillBlock(CFrame.new(c + Vector3.new(-25, -1.5, -60)), Vector3.new(16, 3, 150), Enum.Material.Concrete) -- (Pebble showed as grass)
	for i, at in { Vector3.new(90, 0, -120), Vector3.new(110, 0, -120), Vector3.new(-130, 0, 20) } do
		local box = Instance.new("Model")
		box.Name = "SiteContainer"
		local colour = ({ rgb(40, 90, 160), rgb(180, 60, 40), rgb(60, 120, 70) })[i]
		part(box, "Body", Vector3.new(8, 8.5, 20), CFrame.new(c + at + Vector3.new(0, 4.25, 0)) * CFrame.Angles(0, math.rad(i * 15), 0), colour, Enum.Material.CorrodedMetal)
		for k = -3, 3 do
			part(box, "Rib", Vector3.new(8.2, 8, 0.4), CFrame.new(c + at + Vector3.new(0, 4.25, 0)) * CFrame.Angles(0, math.rad(i * 15), 0) * CFrame.new(0, 0, k * 2.8), colour:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.CorrodedMetal, false)
		end
		box.Parent = m
	end
	V3Assets.place("MonsterTruck", m, CFrame.new(c + Vector3.new(-100, 0, -100)) * CFrame.Angles(0, math.rad(40), 0), { size = 18, collide = true })
	V3Assets.place("Car", m, CFrame.new(c + Vector3.new(-60, 0, -130)) * CFrame.Angles(0, math.rad(-80), 0), { size = 18, collide = true })
	for i, p in scatter(17, c, 8, 40, half - 30, { { at = frameAt, r = 44 }, { at = c + Vector3.new(60, 0, 50), r = 46 }, { at = c + Vector3.new(-25, 0, -60), r = 14 } }) do
		for k = 0, 2 do
			V3Assets.place("Crate", m, CFrame.new(p + Vector3.new(0, k * 4.4, 0)) * CFrame.Angles(0, math.rad(i * 20 + k * 7), 0), { height = 4.4, collide = true })
		end
		part(m, "Pallet", Vector3.new(5, 0.6, 5), CFrame.new(p + Vector3.new(6, 0.3, 2)), rgb(170, 130, 90), Enum.Material.WoodPlanks)
		part(m, "Planks", Vector3.new(4.6, 1.6, 9), CFrame.new(p + Vector3.new(6, 1.4, 2)), rgb(190, 150, 100), Enum.Material.Wood)
	end
	for i, p in scatter(29, c, 14, 30, half - 20, { { at = frameAt, r = 40 }, { at = c + Vector3.new(60, 0, 50), r = 44 } }) do
		V3Assets.place("Barrel", m, CFrame.new(p) * CFrame.Angles(0, i, 0), { height = 4, collide = true })
	end
	for _, at in { c + Vector3.new(-half + 20, 0, -half + 20), c + Vector3.new(half - 20, 0, -half + 20), c + Vector3.new(-half + 20, 0, half - 20), c + Vector3.new(half - 20, 0, half - 20) } do
		V3Assets.place("StreetLamp", m, CFrame.lookAt(at, c), { height = 18 })
	end
end

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
	terrain:FillBlock(CFrame.new(c - Vector3.new(0, 14, 0)), Vector3.new(s.X + 800, 16, s.Z + 800), Enum.Material.Water) -- (top about 4 under the beach)
	terrain:FillBlock(CFrame.new(c - Vector3.new(0, 26, 0)), Vector3.new(s.X + 800, 8, s.Z + 800), Enum.Material.Sand)
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
	-- Phase C: the catapult throws you across the island; the cliff top throws you out to sea.
	launcher(m, cat + Vector3.new(0, 0, -10), Vector3.new(0, 125, 115), "the CATAPULT", rgb(255, 150, 40))
	launcher(m, cliff + Vector3.new(6, 36, 6), Vector3.new(40, 60, 40), "the CLIFF DIVE", rgb(60, 200, 255), 7)
end

------------------------------------------------------------------------------------------------

-- Fill the ground, then stand everything on its measured top (terrain lands off the asked height).
local function ground(c: Vector3, s: Vector3, material: Enum.Material, extra: number): Vector3
	local terrain = Workspace.Terrain
	terrain:FillBlock(CFrame.new(c - Vector3.new(0, 6, 0)), Vector3.new(s.X + extra, 12, s.Z + extra), material)
	local only = RaycastParams.new()
	only.FilterType = Enum.RaycastFilterType.Include
	only.FilterDescendantsInstances = { terrain }
	local hit = Workspace:Raycast(c + Vector3.new(7, 80, -9), Vector3.new(0, -160, 0), only)
	return if hit then Vector3.new(c.X, hit.Position.Y, c.Z) else c
end

------------------------------------------------------------------------------------------------
-- FARM: a red barn and a big one, the farmhouse, a windmill, a water tower and silos, crop rows,
-- a fenced paddock with bison, tractors, a combine, hay bales everywhere, trees round it.
-- (Polygon-style pack, 77018828706990: only the pieces used here are copied.)

BUILDERS.Farm = function(m, place, mid)
	local s = place.size
	local half = s.X / 2
	local terrain = Workspace.Terrain
	local c = ground(mid, s, Enum.Material.Grass, 240)
	frame(m, place, c, rgb(104, 128, 66), Enum.Material.Grass, false)
	-- A dirt track from the gate to the yard.
	terrain:FillBlock(CFrame.new(c + Vector3.new(0, -1.5, -70)), Vector3.new(14, 3, 180), Enum.Material.Ground)
	terrain:FillBlock(CFrame.new(c + Vector3.new(30, -1.5, 40)), Vector3.new(120, 3, 60), Enum.Material.Ground)
	local FP = "Farm Pack>"
	-- Buildings round the yard.
	piece(m, "Farm", FP .. "Buildings>Barns>2", c + Vector3.new(40, 0, 100), 180, nil, true)
	piece(m, "Farm", FP .. "Buildings>Barns>1", c + Vector3.new(100, 0, 100), 180, nil, true)
	piece(m, "Farm", FP .. "Buildings>Houses>1", c + Vector3.new(-100, 0, -50), 90, nil, true)
	piece(m, "Farm", FP .. "Buildings>WindMill>1", c + Vector3.new(140, 0, 0), -90, nil, true)
	piece(m, "Farm", FP .. "Buildings>WaterTower>1", c + Vector3.new(-30, 0, 110), 0, nil, true)
	piece(m, "Farm", FP .. "Silos>LargeSilo", c + Vector3.new(-20, 0, 60), 0, nil, true)
	piece(m, "Farm", FP .. "Silos>1", c + Vector3.new(140, 0, 60), 0, nil, true)
	-- Crop rows (west field) and wheat (east field).
	-- (The pack's row tiles drew as white bits: plough lines of earth in the grass instead.)
	for k = 0, 9 do
		terrain:FillBlock(CFrame.new(c + Vector3.new(-150 + k * 9.5, -1.5, 60)), Vector3.new(5, 3, 76), Enum.Material.Ground)
	end
	-- Machines.
	piece(m, "Farm", FP .. "Vehicles>Tractor", c + Vector3.new(60, 0, 40), 30, nil, true)
	piece(m, "Farm", FP .. "Vehicles>Tractor Old", c + Vector3.new(-70, 0, 0), 120, nil, true)
	piece(m, "Farm", FP .. "Vehicles>Combine", c + Vector3.new(-110, 0, 90), 90, nil, true)
	piece(m, "Farm", FP .. "Vehicles>Pickup Truck", c + Vector3.new(-70, 0, -100), 10, nil, true)
	piece(m, "Farm", FP .. "Vehicles>BaleTrailerRed", c + Vector3.new(100, 0, 40), -60, nil, true)
	piece(m, "Farm", FP .. "Vehicles>Trailer", c + Vector3.new(10, 0, 30), 15, nil, true)
	-- The paddock (south-east): a painted fence round it, bison grazing.
	local pad = c + Vector3.new(80, 0, -60)
	-- (The pack's painted fence lay flat: a post-and-rail fence of our own, PC look 19 Nov.)
	local wood = rgb(120, 88, 58)
	local function rail(a: Vector3, b: Vector3)
		local mid2 = (a + b) / 2
		local len = (b - a).Magnitude
		for _, y in { 1.6, 3.2 } do
			part(m, "FenceRail", Vector3.new(0.4, 0.5, len), CFrame.lookAt(mid2 + Vector3.new(0, y, 0), b + Vector3.new(0, y, 0)), wood, Enum.Material.Wood)
		end
		local n = math.floor(len / 6)
		for k = 0, n do
			part(m, "FencePost", Vector3.new(0.7, 4.2, 0.7), CFrame.new(a:Lerp(b, k / n) + Vector3.new(0, 2.1, 0)), wood:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Wood)
		end
	end
	local corners = { pad + Vector3.new(-45, 0, -30), pad + Vector3.new(45, 0, -30), pad + Vector3.new(45, 0, 30), pad + Vector3.new(-45, 0, 30) }
	for k = 1, 4 do
		rail(corners[k], corners[k % 4 + 1])
	end
	for i, p in { Vector3.new(-15, 0, 8), Vector3.new(12, 0, -10), Vector3.new(25, 0, 14) } do
		prop(m, "Bull", pad + p, i * 70, 6, nil, true)
	end
	piece(m, "Farm", "Meshes/SM_Prop_Trough_01_SM_Prop_Trough_01", pad + Vector3.new(-30, 0, -20), 0)
	-- Hay, props and yard clutter.
	for i, p in scatter(53, c, 16, 30, half - 30, { { at = c + Vector3.new(40, 0, 100), r = 36 }, { at = c + Vector3.new(100, 0, 100), r = 30 }, { at = pad, r = 56 }, { at = c + Vector3.new(-110, 0, 60), r = 50 }, { at = c + Vector3.new(0, 0, OutdoorMaps.arriveZ(place)), r = 20 } }) do
		local names = { FP .. "Hay>RoundBale", FP .. "Hay>SquareBale", FP .. "Hay>RoundBale", "Meshes/SM_Prop_Wheelbarrow_01_SM_Prop_Wheelbarrow_01", "Meshes/SM_Prop_Wood_Stack_01", "Meshes/SM_Prop_Chicken_Coop_01", "Meshes/SM_Prop_Barrel_02", "Meshes/SM_Prop_Well_01_SM_Prop_Well_01" }
		piece(m, "Farm", names[(i - 1) % #names + 1], p, i * 37, nil, true)
	end
	piece(m, "Farm", "Meshes/SM_Prop_Truck_Rusted_01", c + Vector3.new(-140, 0, -130), 60, nil, true)
	-- Phase C: the hay slingshot throws you over the yard into the hay; a second one into the paddock.
	launcher(m, c + Vector3.new(-10, 0, -20), Vector3.new(30, 120, 110), "the HAY SLINGSHOT", rgb(255, 210, 60))
	launcher(m, c + Vector3.new(10, 0, -90), Vector3.new(80, 110, 30), "the BISON TOSS", rgb(200, 120, 60))
	piece(m, "Farm", FP .. "Hay>SquareBalesTrailer", c + Vector3.new(30, 0, -20), 80, nil, true)
	-- Trees round the edge, a few bushes.
	for i, p in scatter(61, c, 18, half - 40, half - 10, { { at = c + Vector3.new(0, 0, -half), r = 30 } }) do
		prop(m, if i % 3 == 0 then "TreePine" else "TreeRound", p, i * 41, 22 + (i % 4) * 4)
	end
	for i, p in scatter(67, c, 10, 40, half - 40, { { at = pad, r = 56 } }) do
		prop(m, "Bush", p, i * 53, 3 + (i % 3))
	end
end

------------------------------------------------------------------------------------------------
-- MILITARY BASE: the base compound (watch tower, canvas tents, light poles, fence: 1167155589) in
-- the middle of a sandy yard, tanks parked, sandbag walls, a helipad, a firing range with
-- targets, an obstacle course (walls, tyres), containers, barriers and barrels.

BUILDERS.Military = function(m, place, mid)
	local s = place.size
	local half = s.X / 2
	local c = ground(mid, s, Enum.Material.Grass, 240) -- (sand read as snow-white from above)
	frame(m, place, c, rgb(104, 128, 66), Enum.Material.Grass, false)
	do
		local rng = Random.new(83)
		for _ = 1, 12 do
			local at = c + Vector3.new(rng:NextNumber(-half + 30, half - 30), -2, rng:NextNumber(-half + 30, half - 30))
			Workspace.Terrain:FillCylinder(CFrame.new(at), 3, rng:NextNumber(10, 26), Enum.Material.Ground)
		end
		Workspace.Terrain:FillBlock(CFrame.new(c + Vector3.new(80, -1.5, 40)), Vector3.new(90, 3, 50), Enum.Material.Ground)
		Workspace.Terrain:FillBlock(CFrame.new(c + Vector3.new(-100, -1.5, -80)), Vector3.new(70, 3, 70), Enum.Material.Ground)
	end
	Workspace.Terrain:FillBlock(CFrame.new(c + Vector3.new(0, -1.5, 0)), Vector3.new(30, 3, s.Z), Enum.Material.Asphalt)
	piece(m, "Military", "Model", c + Vector3.new(-80, 0, 60), 0, nil, true)
	-- Tanks.
	for i, at in { Vector3.new(50, 0, 40), Vector3.new(80, 0, 40), Vector3.new(110, 0, 40) } do
		prop(m, "Tank", c + at, 180 + i * 4, nil, 26, true)
	end
	-- Sandbag walls (rows of tan bags) round the tanks and the gate.
	local function sandbags(at: Vector3, yaw: number, length: number)
		local n = math.floor(length / 3)
		for row = 0, 2 do
			for k = 0, n - 1 do
				local off = (k - (n - 1) / 2) * 3 + (if row % 2 == 1 then 1.5 else 0)
				part(m, "Sandbag", Vector3.new(2.8, 1.1, 1.6), CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(off, 0.55 + row * 1.05, 0), rgb(178, 160, 112), Enum.Material.Fabric)
			end
		end
	end
	sandbags(c + Vector3.new(80, 0, 15), 0, 70)
	sandbags(c + Vector3.new(-20, 0, -120), 0, 24)
	sandbags(c + Vector3.new(20, 0, -120), 0, 24)
	-- The helipad (north-east).
	local heli = c + Vector3.new(100, 0, 120)
	local padPart = part(m, "Helipad", Vector3.new(0.4, 40, 40), CFrame.new(heli + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(70, 72, 76), Enum.Material.Concrete)
	padPart.Shape = Enum.PartType.Cylinder
	part(m, "HelipadH", Vector3.new(3, 0.1, 16), CFrame.new(heli + Vector3.new(-5, 0.45, 0)), rgb(240, 240, 240), Enum.Material.SmoothPlastic, false)
	part(m, "HelipadH", Vector3.new(3, 0.1, 16), CFrame.new(heli + Vector3.new(5, 0.45, 0)), rgb(240, 240, 240), Enum.Material.SmoothPlastic, false)
	part(m, "HelipadH", Vector3.new(7, 0.1, 3), CFrame.new(heli + Vector3.new(0, 0.45, 0)), rgb(240, 240, 240), Enum.Material.SmoothPlastic, false)
	-- The firing range (south-west): a firing line and bullseye targets on posts.
	local range = c + Vector3.new(-100, 0, -80)
	part(m, "FiringLine", Vector3.new(50, 0.2, 2), CFrame.new(range + Vector3.new(0, 0.1, -30)), rgb(230, 200, 40), Enum.Material.SmoothPlastic, false)
	for k = -2, 2 do
		local at = range + Vector3.new(k * 10, 0, 20)
		part(m, "TargetPost", Vector3.new(0.6, 6, 0.6), CFrame.new(at + Vector3.new(0, 3, 0)), rgb(110, 85, 60), Enum.Material.Wood)
		local board = part(m, "Target", Vector3.new(0.4, 5, 5), CFrame.new(at + Vector3.new(0, 6.5, 0)) * CFrame.Angles(0, math.rad(90), 0), rgb(240, 240, 235), Enum.Material.SmoothPlastic)
		board:SetAttribute("Activity", "Target")
		for r, colour in { { 1.8, rgb(220, 40, 40) }, { 1.0, rgb(240, 240, 235) }, { 0.45, rgb(220, 40, 40) } } do
			local ring = part(m, "TargetRing", Vector3.new(0.1, colour[1] * 2, colour[1] * 2), CFrame.new(at + Vector3.new(0, 6.5, -0.25 - r * 0.02)) * CFrame.Angles(0, math.rad(90), 0), colour[2], Enum.Material.SmoothPlastic, false)
			ring.Shape = Enum.PartType.Cylinder
		end
	end
	-- The obstacle course (east): walls to climb, tyres to step through.
	local course = c + Vector3.new(110, 0, -70)
	for k = 0, 3 do
		part(m, "CourseWall", Vector3.new(12, 4 + k, 1.2), CFrame.new(course + Vector3.new(0, (4 + k) / 2, -30 + k * 16)), rgb(130, 105, 75), Enum.Material.WoodPlanks)
	end
	for k = 0, 7 do
		local tyre = part(m, "Tyre", Vector3.new(1.2, 3.6, 3.6), CFrame.new(course + Vector3.new(-20 + (k % 2) * 4, 0.6, -30 + k * 7)) * CFrame.Angles(0, 0, math.rad(90)), rgb(30, 30, 32), Enum.Material.Rubber)
		tyre.Shape = Enum.PartType.Cylinder
	end
	-- Phase C: the mortar fires you over the base; the course ends on an ejector seat.
	launcher(m, c + Vector3.new(-30, 0, -40), Vector3.new(60, 170, 100), "the MORTAR", rgb(255, 80, 60))
	launcher(m, course + Vector3.new(0, 0, 40), Vector3.new(0, 210, 0), "the EJECTOR SEAT", rgb(255, 220, 60), 6)
	-- Containers, crates, barrels, barriers; lamps on the corners; the perimeter fence.
	for i, at in { Vector3.new(-140, 0, -140), Vector3.new(-120, 0, -140), Vector3.new(140, 0, 140) } do
		local box = Instance.new("Model")
		box.Name = "Container"
		local colour = ({ rgb(85, 100, 70), rgb(110, 95, 70), rgb(70, 85, 95) })[i]
		part(box, "Body", Vector3.new(8, 8.5, 20), CFrame.new(c + at + Vector3.new(0, 4.25, 0)), colour, Enum.Material.CorrodedMetal)
		box.Parent = m
	end
	for i, p in scatter(73, c, 30, 30, half - 25, { { at = c + Vector3.new(-80, 0, 60), r = 60 }, { at = heli, r = 26 }, { at = range, r = 40 }, { at = course, r = 36 }, { at = c + Vector3.new(80, 0, 40), r = 50 }, { at = c + Vector3.new(0, 0, OutdoorMaps.arriveZ(place)), r = 20 } }) do
		local roles = { "Crate", "Barrel", "Barrier", "Crate" }
		prop(m, roles[(i - 1) % 4 + 1], p, i * 33, if i % 4 == 3 then 3.2 else 4.4, nil, true)
	end
	for x = -half + 6, half - 6, 12 do
		for _, z in { -half + 3, half - 3 } do
			V3Assets.place("Fence", m, CFrame.new(c + Vector3.new(x, 0, z)), { size = 12, collide = true })
		end
	end
	for z = -half + 6, half - 6, 12 do
		for _, x in { -half + 3, half - 3 } do
			V3Assets.place("Fence", m, CFrame.new(c + Vector3.new(x, 0, z)) * CFrame.Angles(0, math.rad(90), 0), { size = 12, collide = true })
		end
	end
	for _, at in { c + Vector3.new(-half + 20, 0, -half + 20), c + Vector3.new(half - 20, 0, -half + 20), c + Vector3.new(-half + 20, 0, half - 20), c + Vector3.new(half - 20, 0, half - 20) } do
		V3Assets.place("StreetLamp", m, CFrame.lookAt(at, c), { height = 18 })
	end
end

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
