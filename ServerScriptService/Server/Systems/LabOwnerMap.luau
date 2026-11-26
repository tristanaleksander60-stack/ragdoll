--!strict
-- GO NOW: THE MAP (owner, 26 Nov 2026; docs/NOW.md "GO NOW", docs/LAB_TARGET.md ROUND 3; Config.LAB_OWNERMAP): the
-- owner's own map from the screenshots (art/store/look_target/lab_ref ref_1..ref_10), 10x the area (about 950 x 820
-- studs: every distance of the R3.2 plan times S = 3.2). North is -Z, the spawn circle's middle is the lab origin.
-- Built in phases; this file grows a phase at a time (MAP RUN STATE in NOW.md):
--   M1 the ground: grass base, the light-concrete walkway grid (22 wide), the spawn circle, the raised leaderboard
--      plaza (granite wall, cap, pipe railing, stair), the railway loop round the west and south, the ring of hills.
-- Everything is anchored; decoration has CanQuery and CastShadow off.

local Workspace = game:GetService("Workspace")

local LabOwnerMap = {}

LabOwnerMap.S = 1.3 -- (M4: Plan.K) the R3.2 plan's distances are multiplied by this (was 3.2 on the big round-3 map)
LabOwnerMap.SIZE = Vector2.new(980, 850) -- (M4: set from Plan.BOUNDS below, plus the edge band)
LabOwnerMap.CENTER = Vector2.new(-22, 22) -- (M4: the middle of Plan.BOUNDS, below)
LabOwnerMap.WALK = 15 -- walkway width (map round 2: was 22)

local GRASS = Color3.fromRGB(110, 140, 85) -- (M4 OBJECT BY OBJECT: the table's grass; was 118, 168, 84)
local WALK = Color3.fromRGB(205, 205, 200) -- (M4 OBJECT BY OBJECT: the table's walkway; was 212, 212, 206)
local GRANITE = Color3.fromRGB(128, 128, 132)
local CAP = Color3.fromRGB(196, 196, 192)
local STEEL = Color3.fromRGB(170, 174, 180)
local RAIL = Color3.fromRGB(70, 70, 72)
local SLEEPER = Color3.fromRGB(100, 72, 48)
local BALLAST = Color3.fromRGB(120, 118, 115)

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, deco: boolean?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	if deco then
		p.CanQuery = false
		p.CastShadow = false
		p.CanTouch = false
	end
	p.Parent = into
	return p
end

-- M4 OBJECT BY OBJECT (docs/MAP_MASTERPLAN.md, owner: "Vær ultra specifik med alt kvalitet bænke osv"): one builder per
-- object kind, real-world size to a 5.2-stud player, from several clean parts, plain materials, the table's colours.
-- Small parts cast no shadow; decoration is not queried.
local PROP = {
	slat = Color3.fromRGB(124, 92, 61), iron = Color3.fromRGB(40, 40, 44),
	barrel = Color3.fromRGB(190, 40, 30), band = Color3.fromRGB(235, 235, 235), lid = Color3.fromRGB(150, 30, 25),
	crate = Color3.fromRGB(150, 110, 68), crateFrame = Color3.fromRGB(105, 74, 44), bin = Color3.fromRGB(70, 74, 78),
}
-- A park bench: 6 long, seat 1.6 high and 1.6 deep, back to 3.2; 3 seat slats and 2 back slats with gaps, 2 cast-iron
-- side frames (leg, seat support, back post). `cf` = the ground point under the seat's middle, facing the way one sits.
local function benchModel(into: Instance, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "Bench"
	for i = 0, 2 do
		local p = part(m, "BenchSeat", Vector3.new(6, 0.18, 0.46), cf * CFrame.new(0, 1.6, -0.55 + i * 0.52), PROP.slat, Enum.Material.Wood)
		p.CastShadow = false
	end
	for i = 0, 1 do
		part(m, "BenchBack", Vector3.new(6, 0.46, 0.14), cf * CFrame.new(0, 2.25 + i * 0.6, 0.86) * CFrame.Angles(math.rad(-12), 0, 0), PROP.slat, Enum.Material.Wood, true)
	end
	for _, x in { -2.6, 2.6 } do
		part(m, "BenchLeg", Vector3.new(0.18, 1.5, 0.18), cf * CFrame.new(x, 0.75, -0.6), PROP.iron, Enum.Material.Metal, true)
		part(m, "BenchLeg", Vector3.new(0.18, 1.5, 0.18), cf * CFrame.new(x, 0.75, 0.6), PROP.iron, Enum.Material.Metal, true)
		part(m, "BenchSupport", Vector3.new(0.18, 0.18, 1.6), cf * CFrame.new(x, 1.45, 0), PROP.iron, Enum.Material.Metal, true)
		part(m, "BenchPost", Vector3.new(0.18, 1.8, 0.18), cf * CFrame.new(x, 2.4, 0.9) * CFrame.Angles(math.rad(-12), 0, 0), PROP.iron, Enum.Material.Metal, true)
	end
	m.Parent = into
	return m
end
-- A red barrel: 2 wide, 2.8 high, a white band, a darker lid; `tipped` lies it on its side.
local function barrelModel(into: Instance, at: Vector3, yaw: number, tipped: boolean?)
	local m = Instance.new("Model")
	m.Name = "Barrel"
	local base = if tipped then CFrame.new(at + Vector3.new(0, 1, 0)) * CFrame.Angles(0, yaw, math.rad(90)) else CFrame.new(at + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, yaw, 0)
	local up = CFrame.Angles(0, 0, math.rad(90)) -- (a Cylinder part runs along X: turn it up)
	part(m, "Barrel", Vector3.new(2.8, 2, 2), base * up, PROP.barrel, Enum.Material.SmoothPlastic, false, Enum.PartType.Cylinder)
	part(m, "BarrelBand", Vector3.new(0.35, 2.06, 2.06), base * CFrame.new(0, 0.35, 0) * up, PROP.band, Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	part(m, "BarrelLid", Vector3.new(0.08, 1.7, 1.7), base * CFrame.new(0, 1.41, 0) * up, PROP.lid, Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	m.Parent = into
	return m
end
-- A wooden crate: side panels of horizontal planks, a darker frame on every edge, a plank lid. `cf` = its middle.
local function crateModel(into: Instance, cf: CFrame, s: number)
	local m = Instance.new("Model")
	m.Name = "Crate"
	local core = part(m, "Crate", Vector3.new(s - 0.3, s - 0.3, s - 0.3), cf, PROP.crate, Enum.Material.WoodPlanks)
	core.CastShadow = true
	local e = 0.32
	for _, a in { -1, 1 } do
		for _, b in { -1, 1 } do
			part(m, "CrateFrame", Vector3.new(e, s, e), cf * CFrame.new(a * (s / 2 - e / 2), 0, b * (s / 2 - e / 2)), PROP.crateFrame, Enum.Material.Wood, true)
			part(m, "CrateFrame", Vector3.new(s, e, e), cf * CFrame.new(0, a * (s / 2 - e / 2), b * (s / 2 - e / 2)), PROP.crateFrame, Enum.Material.Wood, true)
			part(m, "CrateFrame", Vector3.new(e, e, s), cf * CFrame.new(a * (s / 2 - e / 2), b * (s / 2 - e / 2), 0), PROP.crateFrame, Enum.Material.Wood, true)
		end
	end
	m.Parent = into
	return m
end
-- A bin: 1.4 wide, 2.4 high, a cylinder, a rim, a lid.
local function binModel(into: Instance, at: Vector3)
	local m = Instance.new("Model")
	m.Name = "Bin"
	local up = CFrame.Angles(0, 0, math.rad(90))
	part(m, "Bin", Vector3.new(2.2, 1.4, 1.4), CFrame.new(at + Vector3.new(0, 1.1, 0)) * up, PROP.bin, Enum.Material.Metal, false, Enum.PartType.Cylinder)
	part(m, "BinRim", Vector3.new(0.15, 1.5, 1.5), CFrame.new(at + Vector3.new(0, 2.2, 0)) * up, PROP.iron, Enum.Material.Metal, true, Enum.PartType.Cylinder)
	part(m, "BinLid", Vector3.new(0.2, 1.3, 1.3), CFrame.new(at + Vector3.new(0, 2.35, 0)) * up, PROP.bin, Enum.Material.Metal, true, Enum.PartType.Cylinder)
	m.Parent = into
	return m
end

-- MAP ROUND 3 (owner: "Det her map er 1/10"; docs/MAP_MASTERPLAN.md): the ground is built FROM the master plan
-- (Shared/OwnerMapPlan, lab-space studs, x east, z south): the grass, every road, plaza and inner path as large
-- light-grey slabs (a tile texture, a low kerb, raised a little), round paved junction plazas, the raised spawn plaza
-- (4 high, granite wall, cap, railing, a wide stair down to the boulevard), and the railway round the west, south and
-- east with a station at the south end. The old grid walkways are gone.
local Plan = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
LabOwnerMap.Plan = Plan
-- (M4: the compact plan sets the scale, the ground's size and its middle: Plan.BOUNDS plus a 60-stud grass band for
-- the edge trees and the railway.)
if Plan.K then
	LabOwnerMap.S = Plan.K
end
if Plan.BOUNDS then
	local b = Plan.BOUNDS
	LabOwnerMap.CENTER = (b.min + b.max) / 2
	LabOwnerMap.SIZE = (b.max - b.min) + Vector2.new(120, 120)
end
-- A plan item's spot on the floor (lab space + the lab origin), with an optional nudge.
local function planAt(o: Vector3, top: number, id: string, dx: number?, dz: number?): Vector3
	local it = Plan.ITEMS[id]
	local v = if it then it.at else Vector2.zero
	return Vector3.new(o.X + v.X + (dx or 0), top, o.Z + v.Y + (dz or 0))
end
-- (M4) A plan item's footprint (w x d studs), or the fallback when the plan has none; and whether the plan has it at all
-- (things gone from the compact plan are not built).
local function itemSize(id: string, fallback: Vector2): Vector2
	local it = Plan.ITEMS[id]
	return if it and it.size then it.size else fallback
end
local function inPlan(id: string): boolean
	return Plan.ITEMS[id] ~= nil
end
-- (M4) The water basins and the pen, sized from their plan footprints (the round-3 sizes were for the 3.2x map):
-- AQUA = the aquarium glass box (w, d, h), POOL = the big pool's water (w, d), PEN = the spider pen (w, d).
local function fit(id: string, fallback: Vector2, inset: number): Vector2
	local s = itemSize(id, fallback)
	return Vector2.new(math.max(8, s.X - inset), math.max(8, s.Y - inset))
end
local AQUA = (function()
	local s = fit("Aquarium", Vector2.new(84, 60), 4)
	return Vector3.new(s.X, s.Y, if s.X < 60 then 14 else 26)
end)()
local POOL = fit("BigPool", Vector2.new(98, 72), 8)
local PEN = fit("SpiderPen", Vector2.new(110, 76), 4)
local LOUNGE = fit("LoungePool", Vector2.new(30, 22), 0)
local CROC_R = math.min(itemSize("CrocPond", Vector2.new(80, 80)).X, itemSize("CrocPond", Vector2.new(80, 80)).Y) / 2 -- (the pond's outer radius)
-- (Map round 3, rule 3) Is a world point on a road or path of the plan? Small things are never put there.
LabOwnerMap.origin = Vector3.zero
local function onPath(p: Vector3, margin: number?): boolean
	local v = Vector2.new(p.X - LabOwnerMap.origin.X, p.Z - LabOwnerMap.origin.Z)
	local m = margin or 2
	local function near(a: Vector2, b: Vector2, half: number): boolean
		local ab = b - a
		local t = if ab.Magnitude > 0 then math.clamp((v - a):Dot(ab) / ab:Dot(ab), 0, 1) else 0
		return (a + ab * t - v).Magnitude < half + m
	end
	for _, r in Plan.ROADS do
		for i = 1, #r.points - 1 do
			if near(r.points[i], r.points[i + 1], r.width / 2) then
				return true
			end
		end
	end
	for _, path in Plan.INNER do
		for i = 1, #path.points - 1 do
			if near(path.points[i], path.points[i + 1], Plan.INNER_W / 2) then
				return true
			end
		end
	end
	return false
end
-- F40 (owner: lamp posts still stand in paths): EVERY walkable surface (the roads and paths above, plus the plazas,
-- the Tower Square, the station and the courtyards). Lamps keep `margin` studs outside all of it.
local function onWalkable(p: Vector3, margin: number): boolean
	if onPath(p, margin) then
		return true
	end
	local v = Vector2.new(p.X - LabOwnerMap.origin.X, p.Z - LabOwnerMap.origin.Z)
	for _, pz in Plan.PLAZAS do
		if pz.kind == "circle" then
			if (v - pz.at).Magnitude < pz.radius + margin then
				return true
			end
		elseif math.abs(v.X - pz.at.X) < pz.size.X / 2 + margin and math.abs(v.Y - pz.at.Y) < pz.size.Y / 2 + margin then
			return true
		end
	end
	for _, room in Plan.ROOMS do
		if room.courtyard and (v - room.courtyard).Magnitude < 16 + margin then
			return true
		end
	end
	return false
end
local SLAB_TEX = "rbxassetid://91579008413917"
local function slab(into: Instance, name: string, a: Vector3, b: Vector3, width: number, lift: number, noKerb: boolean?)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	local cf = CFrame.lookAt((a + b) / 2 + Vector3.new(0, lift, 0), b + Vector3.new(0, lift, 0))
	local p = part(into, name, Vector3.new(width, 0.4, len + width * 0.02), cf, WALK, Enum.Material.SmoothPlastic)
	local t = Instance.new("Texture")
	t.Texture = SLAB_TEX
	t.Face = Enum.NormalId.Top
	t.StudsPerTileU = math.max(6, width / 3)
	t.StudsPerTileV = 12
	t.Color3 = Color3.fromRGB(150, 150, 146)
	t.Transparency = 0.55
	t.Parent = p
	for _, side in if noKerb then {} else { -1, 1 } do
		part(into, "OwnerKerb", Vector3.new(0.8, 0.7, len), cf * CFrame.new(side * (width / 2 + 0.4), 0.1, 0), Color3.fromRGB(190, 190, 186), Enum.Material.Concrete, true)
	end
end
local function disc(into: Instance, name: string, at: Vector3, radius: number, lift: number, color: Color3)
	local d = part(into, name, Vector3.new(0.4, radius * 2, radius * 2), CFrame.new(at + Vector3.new(0, lift, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.SmoothPlastic, false, Enum.PartType.Cylinder)
	local t = Instance.new("Texture")
	t.Texture = SLAB_TEX
	t.Face = Enum.NormalId.Right
	t.StudsPerTileU = 10
	t.StudsPerTileV = 10
	t.Color3 = Color3.fromRGB(150, 150, 146)
	t.Transparency = 0.6
	t.Parent = d
	return d
end
local function ground(into: Instance, o: Vector3)
	local c = LabOwnerMap.CENTER
	local size = LabOwnerMap.SIZE
	local top = o.Y - 0.05
	local function w(v: Vector2): Vector3
		return Vector3.new(o.X + v.X, top, o.Z + v.Y)
	end
	part(into, "OwnerGrass", Vector3.new(size.X, 2, size.Y), CFrame.new(o.X + c.X, top - 1, o.Z + c.Y), GRASS, Enum.Material.Grass)
	-- Roads (boulevard 36, cross roads 26, avenues 16, spurs 14), each leg a slab; a round paved plaza at every corner.
	for _, r in Plan.ROADS do
		for i = 1, #r.points - 1 do
			slab(into, "OwnerRoad", w(r.points[i]), w(r.points[i + 1]), r.width, 0.2)
		end
		for _, p in r.points do
			disc(into, "OwnerJunction", w(p), r.width / 2 + 2, 0.19, WALK)
		end
	end
	-- Inner paths (12): entrance -> courtyard -> the front of every attraction.
	for _, path in Plan.INNER do
		for i = 1, #path.points - 1 do
			slab(into, "OwnerPath", w(path.points[i]), w(path.points[i + 1]), Plan.INNER_W, 0.18, true) -- (M9: no kerbs on the inner paths)
		end
	end
	-- The courtyards of the rooms.
	for _, room in Plan.ROOMS do
		if room.courtyard then
			disc(into, "OwnerCourtyard", w(room.courtyard), 16, 0.21, WALK)
		end
	end
	-- The plazas: the fountain circle, the Tower Square, the south cross, the station; the spawn plaza is raised.
	for id, pz in Plan.PLAZAS do
		if pz.kind == "circle" then
			disc(into, "OwnerPlazaDisc", w(pz.at), pz.radius, 0.22, WALK)
			if id == "Fountain" then
				part(into, "FountainBasin", Vector3.new(2, 26, 26), CFrame.new(w(pz.at) + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(196, 196, 190), Enum.Material.Concrete, false, Enum.PartType.Cylinder)
				local water = part(into, "FountainWater", Vector3.new(0.4, 23, 23), CFrame.new(w(pz.at) + Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 190, 225), Enum.Material.Glass, true, Enum.PartType.Cylinder)
				water.Transparency = 0.25
				part(into, "FountainSpout", Vector3.new(2, 6, 2), CFrame.new(w(pz.at) + Vector3.new(0, 3, 0)), Color3.fromRGB(196, 196, 190), Enum.Material.Concrete)
				local spray = Instance.new("ParticleEmitter")
				spray.Texture = "rbxasset://textures/particles/smoke_main.dds"
				spray.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
				spray.Size = NumberSequence.new(0.8, 2)
				spray.Transparency = NumberSequence.new(0.4, 1)
				spray.Speed = NumberRange.new(12, 16)
				spray.Lifetime = NumberRange.new(0.8, 1.2)
				spray.Acceleration = Vector3.new(0, -30, 0)
				spray.SpreadAngle = Vector2.new(12, 12)
				spray.Rate = 30
				spray.Parent = into:FindFirstChild("FountainSpout") or into
			end
		elseif id == "SpawnPlaza" then
			local at, sz, ph = w(pz.at), pz.size, 4
			local plaza = part(into, "OwnerPlaza", Vector3.new(sz.X, ph, sz.Y), CFrame.new(at + Vector3.new(0, ph / 2, 0)), GRANITE, Enum.Material.Slate)
			plaza:SetAttribute("OwnerPlaza", true)
			local topSlab = part(into, "OwnerPlazaTop", Vector3.new(sz.X - 2, 0.3, sz.Y - 2), CFrame.new(at + Vector3.new(0, ph + 0.15, 0)), CAP, Enum.Material.SmoothPlastic)
			local t = Instance.new("Texture")
			t.Texture = SLAB_TEX
			t.Face = Enum.NormalId.Top
			t.StudsPerTileU = 12
			t.StudsPerTileV = 12
			t.Color3 = Color3.fromRGB(150, 150, 146)
			t.Transparency = 0.6
			t.Parent = topSlab
			local hx, hz = sz.X / 2 - 1, sz.Y / 2 - 1
			local railY = top + ph + 3.4
			local function railRun(a: Vector3, b: Vector3)
				local len = (b - a).Magnitude
				part(into, "OwnerRail", Vector3.new(len, 0.35, 0.35), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), STEEL, Enum.Material.Metal, true)
				for i = 0, math.max(1, math.floor(len / 8)) do
					local p = a:Lerp(b, i / math.max(1, math.floor(len / 8)))
					part(into, "OwnerRailPost", Vector3.new(0.3, 3.2, 0.3), CFrame.new(p.X, top + ph + 1.7, p.Z), STEEL, Enum.Material.Metal, true)
				end
			end
			local y = railY
			railRun(Vector3.new(at.X - hx, y, at.Z - hz), Vector3.new(at.X + hx, y, at.Z - hz))
			railRun(Vector3.new(at.X - hx, y, at.Z - hz), Vector3.new(at.X - hx, y, at.Z + hz))
			railRun(Vector3.new(at.X + hx, y, at.Z - hz), Vector3.new(at.X + hx, y, at.Z + hz))
			railRun(Vector3.new(at.X - hx, y, at.Z + hz), Vector3.new(at.X - 20, y, at.Z + hz))
			railRun(Vector3.new(at.X + 20, y, at.Z + hz), Vector3.new(at.X + hx, y, at.Z + hz))
			-- The wide stair down to the boulevard (south side).
			for i = 1, 6 do
				local h = ph * (7 - i) / 7
				part(into, "OwnerPlazaStep", Vector3.new(38, h, 2), CFrame.new(at + Vector3.new(0, h / 2, sz.Y / 2 + (i - 0.5) * 2)), CAP, Enum.Material.Concrete)
			end
			-- The side paths leave the plaza at its west and east ends: small ramps down.
			for _, side in { -1, 1 } do
				part(into, "OwnerPlazaRamp", Vector3.new(10, 1, 14), CFrame.new(at + Vector3.new(side * (sz.X / 2 + 4.5), ph / 2, 0)) * CFrame.Angles(0, 0, math.rad(side * 22)), CAP, Enum.Material.Concrete)
			end
		else
			local at, sz = w(pz.at), pz.size
			part(into, "OwnerPlazaRect", Vector3.new(sz.X, 0.4, sz.Y), CFrame.new(at + Vector3.new(0, 0.22, 0)), WALK, Enum.Material.SmoothPlastic)
			if id == "Station" then
				part(into, "StationRoof", Vector3.new(sz.X, 0.6, sz.Y + 4), CFrame.new(at + Vector3.new(0, 11, 0)), Color3.fromRGB(150, 60, 50), Enum.Material.Slate)
				for _, x in { -sz.X / 2 + 2, 0, sz.X / 2 - 2 } do
					part(into, "StationPost", Vector3.new(0.8, 11, 0.8), CFrame.new(at + Vector3.new(x, 5.5, -sz.Y / 2 + 1)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)
				end
			end
		end
	end
	-- The railway: down the west side, along the south past the station, up the east side.
	local x0, x1 = c.X - size.X / 2 + 12, c.X + size.X / 2 - 12
	local zN, zS = c.Y - size.Y / 2 + 14, c.Y + size.Y / 2 - 12
	local pts = { Vector2.new(x0, zN), Vector2.new(x0, zS - 20), Vector2.new(x0 + 20, zS), Vector2.new(x1 - 20, zS), Vector2.new(x1, zS - 20), Vector2.new(x1, zN) }
	if Plan.RAILWAY then
		-- (M4: the railway runs where the compact plan puts it: up the west edge and along the south, corners rounded)
		pts = {}
		local R = Plan.RAILWAY
		for i, p in R do
			if i > 1 and i < #R then
				local a, b = (R[i - 1] - p).Unit, (R[i + 1] - p).Unit
				table.insert(pts, p + a * 14)
				table.insert(pts, p + (a + b).Unit * 4)
				table.insert(pts, p + b * 14)
			else
				table.insert(pts, p)
			end
		end
	end
	for i = 1, #pts - 1 do
		local a, b = w(pts[i]), w(pts[i + 1])
		local len = (b - a).Magnitude
		local along = CFrame.lookAt((a + b) / 2, b)
		part(into, "OwnerBallast", Vector3.new(9, 0.5, len + 4), along * CFrame.new(0, 0.25, 0), BALLAST, Enum.Material.Slate, true)
		for _, side in { -1, 1 } do
			part(into, "OwnerRail", Vector3.new(0.4, 0.5, len + 4), along * CFrame.new(side * 2.4, 1, 0), RAIL, Enum.Material.Metal, true)
		end
		local n = math.floor(len / (if LabOwnerMap.S < 2 then 4 else 10)) -- (M9: a sleeper every 10; M4 OBJECT BY OBJECT: every 4 on the compact map)
		for k = 0, n do
			part(into, "OwnerSleeper", Vector3.new(7, 0.35, 1.2), along * CFrame.new(0, 0.6, -len / 2 + k * (len / math.max(n, 1))), SLEEPER, Enum.Material.Wood, true)
		end
	end
end

-- M1: the ring of soft green hills round the lab (Terrain grass, cheap), far outside the base.
local function hills(o: Vector3)
	local terrain = Workspace.Terrain
	local c = LabOwnerMap.CENTER
	local mid = Vector3.new(o.X + c.X, o.Y, o.Z + c.Y)
	local n = 30
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local rx, rz = LabOwnerMap.SIZE.X / 2 + 75, LabOwnerMap.SIZE.Y / 2 + 75 -- (M4: smooth hills close round the edge, as in the references)
		local at = mid + Vector3.new(math.cos(a) * rx, -34 + (i % 3) * 6, math.sin(a) * rz)
		pcall(function()
			terrain:FillBall(at, 62 + (i % 4) * 12, Enum.Material.Grass)
		end)
	end
end

-- M2: the hero (ref_5, ref_8, ref_10): the 5-floor grey steel scaffold stair tower (about 56 x 56, 95 high) just south of
-- the spawn circle, zig-zag stairs in an open middle well, diamond-plate floors, railings on every edge and a roof deck;
-- the green steel slide from the roof's west side curving down to the south-west on a steel truss, a round button at
-- its top; the wooden plank bridge from the second floor down to the east; the grey grandstand with wooden seats on
-- its own plot south of the tower. Today's code tower and the Heights set go (hidden).
LabOwnerMap.TOWER_AT = Vector2.new(5, 40) -- (plan; x S)
LabOwnerMap.TOWER_SIZE = 26 -- (M4: the plan's tower footprint, as in the references; was 56)
LabOwnerMap.FLOOR_H = 10.5 -- (M4: 5 storeys = 52.5 high, the references' 50-55; was 19)
LabOwnerMap.FLOORS = 5
local GALV = Color3.fromRGB(75, 80, 86) -- (OBJECT BY OBJECT: the steel tower Metal; was 150, 154, 160)
local PLATE = Color3.fromRGB(130, 134, 140)
local SLIDE = Color3.fromRGB(110, 125, 110) -- (OBJECT BY OBJECT: grey-green; was 86, 118, 92)
local WOOD = Color3.fromRGB(132, 96, 62)
local CONCRETE = Color3.fromRGB(150, 150, 152)

local function beam(into: Instance, name: string, a: Vector3, b: Vector3, thick: number, color: Color3, deco: boolean?): Part
	local len = (b - a).Magnitude
	return part(into, name, Vector3.new(thick, thick, len), CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Metal, deco)
end

local function railing(into: Instance, a: Vector3, b: Vector3)
	beam(into, "TowerRail", a + Vector3.new(0, 3.4, 0), b + Vector3.new(0, 3.4, 0), 0.35, GALV, true)
	beam(into, "TowerRail", a + Vector3.new(0, 1.8, 0), b + Vector3.new(0, 1.8, 0), 0.25, GALV, true)
	local n = math.max(1, math.floor((b - a).Magnitude / 7))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		part(into, "TowerRailPost", Vector3.new(0.3, 3.5, 0.3), CFrame.new(p + Vector3.new(0, 1.75, 0)), GALV, Enum.Material.Metal, true)
	end
	-- (an invisible guard so nobody walks off by mistake)
	local guard = part(into, "TowerGuard", Vector3.new(0.4, 4, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 2, 0), b + Vector3.new(0, 2, 0)), GALV, Enum.Material.Metal)
	guard.Transparency = 1
	guard.CastShadow = false
end

-- F67 (owner: "Fiks trappen så man kan bruge den indendørs også"; Config.TOWER_STAIRS_V2): real switchback stairs in the
-- tower's well. Each storey: the WEST lane climbs north from the floor's south landing to a deep half landing at the
-- north end, the EAST lane climbs back south to the next floor's south landing. Everything is stacked one storey (19
-- studs) apart, so there are 18 studs of headroom over every step. Steps 0.95 up and 2 deep, 8.5 wide; a smooth
-- invisible ramp on the step noses (no catching or bouncing); a divider rail between the lanes and rails round the
-- open well; a warm light on each half landing; and an invisible TowerInside volume the client uses to switch the
-- camera to Invisicam inside (Client/TowerCam).
local function stairsV2(into: Instance, c: Vector3, top: number, wellX: number, wellZ: number, H: number, T: number, full: number)
	local half = wellX / 2
	local laneW = half - 0.5
	local compact = H < 14 -- (M4: the low compact tower: shorter flights)
	local STEPS = if compact then 6 else 10
	local RISE = (H / 2) / STEPS
	local RUN = if compact then 1.7 else 2
	local southZ = wellZ / 2 - 6 -- (the south landing: z from here to the well's end)
	local northZ = southZ - STEPS * RUN -- (the half landing: from the well's north end to here)
	local function lane(x: number, y0: number, fromZ: number, dir: number)
		for k = 1, STEPS do
			local z = fromZ + dir * (k - 0.5) * RUN
			part(into, "TowerStep", Vector3.new(laneW, RISE, RUN + 0.05), CFrame.new(c + Vector3.new(x, y0 + k * RISE - RISE / 2, z)), PLATE, Enum.Material.DiamondPlate)
		end
		-- the ramp: its top runs through the step noses, from the floor 2 studs before the first step to the last step
		local a = c + Vector3.new(x, y0, fromZ - dir * RUN)
		local b = c + Vector3.new(x, y0 + H / 2, fromZ + dir * (STEPS - 1) * RUN)
		local along = (b - a).Unit
		local up = along:Cross(Vector3.xAxis)
		if up.Y < 0 then
			up = -up
		end
		local ramp = part(into, "TowerRamp", Vector3.new(laneW, 0.4, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 - up * 0.2, b), PLATE, Enum.Material.SmoothPlastic)
		ramp.Transparency = 1
		ramp.CastShadow = false
		-- the stringer under the outer side
		beam(into, "TowerStringer", a + Vector3.new(x > 0 and laneW / 2 or -laneW / 2, -0.6, 0), b + Vector3.new(x > 0 and laneW / 2 or -laneW / 2, -0.6, 0), 0.5, GALV, true)
		-- the divider rail on the middle side
		local m = Vector3.new(-x / math.abs(x) * (laneW / 2 + 0.25), 0, 0)
		railing(into, a + m, b + m)
	end
	for f = 0, LabOwnerMap.FLOORS - 1 do
		local y0 = f * H
		local mid = y0 + H / 2
		lane(-half / 2 - 0.25, y0, southZ, -1) -- west lane, north
		part(into, "TowerLanding", Vector3.new(wellX - 0.2, 0.8, northZ + wellZ / 2), CFrame.new(c + Vector3.new(0, mid - 0.4, (northZ - wellZ / 2) / 2)), PLATE, Enum.Material.DiamondPlate)
		lane(half / 2 + 0.25, mid, northZ, 1) -- east lane, south
		part(into, "TowerLanding", Vector3.new(wellX - 0.2, 0.8, wellZ / 2 - southZ), CFrame.new(c + Vector3.new(0, y0 + H - 0.4, (southZ + wellZ / 2) / 2)), PLATE, Enum.Material.DiamondPlate)
		-- a warm light over the half landing
		local lamp = part(into, "TowerLamp", Vector3.new(1.6, 0.4, 1.6), CFrame.new(c + Vector3.new(0, mid + math.min(8.6, H * 0.42), (northZ - wellZ / 2) / 2)), Color3.fromRGB(255, 226, 170), Enum.Material.Neon, true)
		local light = Instance.new("PointLight")
		light.Range = 26
		light.Brightness = 1.3
		light.Color = Color3.fromRGB(255, 226, 170)
		light.Shadows = false
		light.Parent = lamp
		-- rails round the open well on the floor above (not over the south landing)
		local yy = y0 + H + 0.4
		local nw, ne = c + Vector3.new(-half, yy, -wellZ / 2), c + Vector3.new(half, yy, -wellZ / 2)
		railing(into, nw, ne)
		railing(into, nw, c + Vector3.new(-half, yy, southZ))
		railing(into, ne, c + Vector3.new(half, yy, southZ))
		if f == LabOwnerMap.FLOORS - 1 then
			-- on the roof nothing goes on up: the rail closes the west half too
			railing(into, c + Vector3.new(-half, yy, southZ), c + Vector3.new(0, yy, southZ))
		end
	end
	-- the inside volume for the camera
	local inside = part(into, "TowerInside", Vector3.new(T, full + 4, T), CFrame.new(c + Vector3.new(0, (full + 4) / 2, 0)), PLATE, Enum.Material.SmoothPlastic, true)
	inside.Transparency = 1
	inside.CanCollide = false
	inside.CanQuery = false
	inside.CanTouch = false
	game:GetService("CollectionService"):AddTag(inside, "TowerInside")
end

local function hero(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local T = LabOwnerMap.TOWER_SIZE
	local H = LabOwnerMap.FLOOR_H
	local c = planAt(o, top, "Tower")
	local h = T / 2
	local wellX, wellZ = 14, 34 -- the open middle well (stairs run along Z)
	if T < 40 then
		wellZ = 22 -- (M4: the compact tower: 6-step flights of 1.7 + the landings)
	end
	local STAIRS_V2 = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).TOWER_STAIRS_V2 == true
	if STAIRS_V2 then
		wellX = 18 -- (F67: two 8.5-stud lanes side by side and a divider)
	end
	-- Columns at the corners and the middles of the sides, the full height.
	local full = H * LabOwnerMap.FLOORS
	for _, x in { -h, 0, h } do
		for _, z in { -h, 0, h } do
			if not (x == 0 and z == 0) then
				part(into, "TowerColumn", Vector3.new(1.4, full + 4, 1.4), CFrame.new(c + Vector3.new(x, (full + 4) / 2, z)), GALV, Enum.Material.Metal)
			end
		end
	end
	for f = 1, LabOwnerMap.FLOORS do
		local y = f * H
		-- The floor round the well: four diamond-plate slabs.
		local sideW = (T - wellX) / 2
		part(into, "TowerFloor", Vector3.new(sideW, 0.8, T), CFrame.new(c + Vector3.new(-(wellX / 2 + sideW / 2), y, 0)), PLATE, Enum.Material.DiamondPlate)
		part(into, "TowerFloor", Vector3.new(sideW, 0.8, T), CFrame.new(c + Vector3.new(wellX / 2 + sideW / 2, y, 0)), PLATE, Enum.Material.DiamondPlate)
		local endD = (T - wellZ) / 2
		part(into, "TowerFloor", Vector3.new(wellX, 0.8, endD), CFrame.new(c + Vector3.new(0, y, -(wellZ / 2 + endD / 2))), PLATE, Enum.Material.DiamondPlate)
		if f == LabOwnerMap.FLOORS and not STAIRS_V2 then
			-- (the roof deck closes over the well, but the last flight still arrives at its north end)
			part(into, "TowerFloor", Vector3.new(wellX, 0.8, wellZ - 10), CFrame.new(c + Vector3.new(0, y, 5)), PLATE, Enum.Material.DiamondPlate)
		end
		part(into, "TowerFloor", Vector3.new(wellX, 0.8, endD), CFrame.new(c + Vector3.new(0, y, wellZ / 2 + endD / 2)), PLATE, Enum.Material.DiamondPlate)
		-- Edge beams and the railing all round.
		local yy = y + 0.4
		local corners = { Vector3.new(-h, yy, -h), Vector3.new(h, yy, -h), Vector3.new(h, yy, h), Vector3.new(-h, yy, h) }
		for i = 1, 4 do
			local a, b = c + corners[i], c + corners[i % 4 + 1]
			beam(into, "TowerEdge", a - Vector3.new(0, 0.9, 0), b - Vector3.new(0, 0.9, 0), 1, GALV)
			railing(into, a, b)
		end
		-- Cross bracing on the outside of each storey (an X on each side).
		for i = 1, 4 do
			local a, b = c + corners[i] - Vector3.new(0, H, 0), c + corners[i % 4 + 1]
			beam(into, "TowerBrace", a, b, 0.5, GALV, true)
		end
	end
	-- The zig-zag stairs in the well: one flight a storey, alternating direction, steps 1 stud up.
	if STAIRS_V2 then
		stairsV2(into, c, top, wellX, wellZ, H, T, full)
	else
	for f = 0, LabOwnerMap.FLOORS - 1 do
		local y0 = f * H
		local dir = if f % 2 == 0 then -1 else 1 -- (north, then south)
		local steps = H
		local run = (wellZ - 6) / steps
		for s = 1, steps do
			local z = -dir * ((wellZ - 6) / 2) + dir * (s - 0.5) * run
			local stepY = y0 + s
			part(into, "TowerStep", Vector3.new(wellX - 1, 1, run + 0.05), CFrame.new(c + Vector3.new(0, stepY - 0.5, z)), PLATE, Enum.Material.DiamondPlate)
		end
		-- the landing at the flight's top end
		part(into, "TowerLanding", Vector3.new(wellX - 1, 0.8, 3.2), CFrame.new(c + Vector3.new(0, y0 + H, dir * ((wellZ - 6) / 2 + 1.6))), PLATE, Enum.Material.DiamondPlate)
	end
	end
	-- A ground pad under the tower.
	part(into, "TowerPad", Vector3.new(T + 8, 0.52, T + 8), CFrame.new(c + Vector3.new(0, 0.26, 0)), CONCRETE, Enum.Material.Concrete)

	-- THE SLIDE: from the roof's west edge, down and round to the south-west on a truss.
	local roofY = top + H * LabOwnerMap.FLOORS
	local pts = {
		c + Vector3.new(-h, roofY - top + 0.5, -10),
		-- (map round 3: kept inside the Tower Square, radius 100)
		c + Vector3.new(-h - 18, roofY - top - 30, 4),
		c + Vector3.new(-h - 34, roofY - top - 58, 14),
		c + Vector3.new(-h - 40, roofY - top - 78, 26),
		c + Vector3.new(-h - 42, 2.5, 36),
		c + Vector3.new(-h - 42, 0.6, 48), -- (the plan's slide run-out, south-west of the tower)
	}
	if T < 40 then
		-- (M4: the compact tower: the slide curves from the roof's west edge down to the plan's SlideRunout)
		local ro = planAt(o, top, "SlideRunout") - c
		local R = roofY - top
		local ex, ez = ro.X, ro.Z
		pts = {
			c + Vector3.new(-h, R + 0.5, -6),
			c + Vector3.new(-h + (ex + h) * 0.3, R * 0.68, -6 + (ez + 6) * 0.22),
			c + Vector3.new(-h + (ex + h) * 0.62, R * 0.38, -6 + (ez + 6) * 0.48),
			c + Vector3.new(-h + (ex + h) * 0.88, R * 0.14, -6 + (ez + 6) * 0.72),
			c + Vector3.new(ex, 2.5, ez - 8),
			c + Vector3.new(ex, 0.6, ez),
		}
	end
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SLIDE_V2 then
		-- F58 (owner's screenshot: loose green blocks, gaps, a piece sticking up, no opening in the railing): ONE smooth
		-- chute. A Catmull-Rom curve through the same points, cut into short pieces (about SEG studs) that meet end to end
		-- with only a small angle between them: no gaps, no steps. Slippery bed, side walls, steel legs every few pieces
		-- down to the ground, an opening in the roof railing with a SLIDE sign, and a soft mat at the run-out.
		local SEG = 4
		local function cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
			local t2, t3 = t * t, t * t * t
			return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
		end
		local curve: { Vector3 } = {}
		for i = 1, #pts - 1 do
			local p0, p1, p2, p3 = pts[math.max(1, i - 1)], pts[i], pts[i + 1], pts[math.min(#pts, i + 2)]
			local n = math.max(2, math.ceil((p2 - p1).Magnitude / SEG))
			for k = 0, n - 1 do
				table.insert(curve, cr(p0, p1, p2, p3, k / n))
			end
		end
		table.insert(curve, pts[#pts])
		for i = 1, #curve - 1 do
			local a, b = curve[i], curve[i + 1]
			local len = (b - a).Magnitude
			if len < 0.05 then
				continue
			end
			local cf = CFrame.lookAt((a + b) / 2, b)
			local bed = part(into, "SlideBed", Vector3.new(10, 0.8, len + 0.35), cf, SLIDE, Enum.Material.SmoothPlastic)
			bed.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.3, 100, 1)
			for _, side in { -1, 1 } do
				part(into, "SlideWall", Vector3.new(0.6, 2.4, len + 0.35), cf * CFrame.new(side * 5.3, 1.2, 0), SLIDE, Enum.Material.SmoothPlastic, true)
			end
			if i % 3 == 0 and a.Y - top > 5 then
				for _, side in { -1, 1 } do
					local foot = (cf * CFrame.new(side * 4.2, -0.4, 0)).Position
					beam(into, "SlideLeg", Vector3.new(foot.X, top, foot.Z), foot, 0.7, GALV)
				end
				local l = (cf * CFrame.new(-4.2, -0.4, 0)).Position
				local r = (cf * CFrame.new(4.2, -0.4, 0)).Position
				part(into, "SlideBracket", Vector3.new(9.4, 0.5, 0.8), cf * CFrame.new(0, -0.65, 0), GALV, Enum.Material.Metal, true)
				beam(into, "SlideBrace", Vector3.new(l.X, top + (l.Y - top) * 0.3, l.Z), r, 0.35, GALV, true)
			end
		end
		-- the opening in the roof railing at the start, with posts and a SLIDE sign over it
		local start = pts[1]
		local ov = OverlapParams.new()
		ov.FilterType = Enum.RaycastFilterType.Include
		ov.FilterDescendantsInstances = { into }
		for _, p in Workspace:GetPartBoundsInBox(CFrame.new(start + Vector3.new(2, 2.5, 0)), Vector3.new(8, 5, 12), ov) do
			if string.find(p.Name, "Rail") or string.find(p.Name, "Guard") then
				p:Destroy()
			end
		end
		local dirOut = (curve[2] - curve[1]) * Vector3.new(1, 0, 1)
		local side = Vector3.new(-dirOut.Z, 0, dirOut.X).Unit
		for _, s in { -1, 1 } do
			part(into, "SlidePost", Vector3.new(0.6, 8, 0.6), CFrame.new(start + side * (s * 5.8) + Vector3.new(0, 4, 0)), GALV, Enum.Material.Metal, true)
		end
		local signAt = start + Vector3.new(0, 8.4, 0)
		local sign = part(into, "SlideSign", Vector3.new(12.2, 1.8, 0.4), CFrame.lookAt(signAt, signAt - dirOut.Unit), Color3.fromRGB(40, 150, 70), Enum.Material.SmoothPlastic, true)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local g = Instance.new("SurfaceGui")
			g.Face = face
			g.CanvasSize = Vector2.new(300, 44)
			g.LightInfluence = 0
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, 1)
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.TextColor3 = Color3.new(1, 1, 1)
			l.TextStrokeTransparency = 0.2
			l.Text = "SLIDE"
			l.Parent = g
			g.Parent = sign
		end
		-- the soft mat at the run-out
		local last = pts[#pts]
		part(into, "SlideMat", Vector3.new(14, 0.8, 16), CFrame.lookAt(last + Vector3.new(0, -0.1, 0), last + dirOut.Unit * 0 + (pts[#pts] - pts[#pts - 1]) * Vector3.new(1, 0, 1) + Vector3.new(0, -0.1, 0)) * CFrame.new(0, 0, -8), Color3.fromRGB(60, 120, 220), Enum.Material.Fabric)
	else
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		local bed = part(into, "SlideBed", Vector3.new(10, 0.8, len + 1), cf, SLIDE, Enum.Material.Metal)
		bed.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.3, 100, 1)
		for _, side in { -1, 1 } do
			part(into, "SlideWall", Vector3.new(0.6, 3, len + 1), cf * CFrame.new(side * 5.3, 1.4, 0), SLIDE, Enum.Material.Metal)
		end
		-- the truss under it: legs to the ground with a cross brace
		if a.Y - top > 6 then
			for _, side in { -1, 1 } do
				local foot = (cf * CFrame.new(side * 4.5, 0, 0)).Position
				beam(into, "SlideLeg", Vector3.new(foot.X, top, foot.Z), foot - Vector3.new(0, 0.5, 0), 0.9, GALV)
			end
			local l = (cf * CFrame.new(-4.5, 0, 0)).Position
			local r = (cf * CFrame.new(4.5, 0, 0)).Position
			beam(into, "SlideBrace", Vector3.new(l.X, top + (l.Y - top) * 0.3, l.Z), r - Vector3.new(0, 0.5, 0), 0.4, GALV, true)
		end
	end
	end
	part(into, "SlideButton", Vector3.new(0.8, 3, 3), CFrame.new(pts[1] + Vector3.new(4, 1.5, -8)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 40, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)

	-- THE PLANK BRIDGE: from the second floor's east edge down to the ground in the east.
	local from = c + Vector3.new(h, H * 2 + 0.4, 6)
	local to = if T < 40 then Vector3.new(c.X + h + 26, top + 0.4, c.Z - 12) else Vector3.new(c.X + h + 50, top + 0.4, c.Z - 30) -- (map round 3: down into the Tower Square; M4: the compact square)
	local len = (to - from).Magnitude
	local cf = CFrame.lookAt((from + to) / 2, to)
	local n = math.floor(len / 2.2)
	for i = 0, n - 1 do
		part(into, "BridgePlank", Vector3.new(12, 0.5, 2), cf * CFrame.new(0, 0, -len / 2 + 1.1 + i * (len / n)), WOOD:Lerp(Color3.fromRGB(150, 112, 74), (i % 3) / 3), Enum.Material.WoodPlanks)
	end
	for _, side in { -1, 1 } do
		part(into, "BridgeRail", Vector3.new(0.4, 0.4, len), cf * CFrame.new(side * 6, 3, 0), WOOD, Enum.Material.Wood, true)
		part(into, "BridgeGuard", Vector3.new(0.4, 3.5, len), cf * CFrame.new(side * 6, 1.8, 0), WOOD, Enum.Material.Wood).Transparency = 1
	end

	-- THE GRANDSTAND: south of the tower on its own plot, facing north.
	local g = c + Vector3.new(58, 0, -40) -- (map round 3: the plan's spot north-east of the tower; the rows rise to the north, the seats face south to the tower and the square)
	local W, rows = 60, 6
	local back = -1 -- (the rows rise this way along z)
	if inPlan("Grandstand") and T < 40 then
		-- (M4: the brown wooden grandstand on the plan's spot, its size; it faces the plan's way (N = the seats look north
		-- to the tower square, so the rows rise to the south))
		local it = Plan.ITEMS.Grandstand
		W, rows = it.size.X, 4
		back = if it.face == "N" then 1 else -1
		g = planAt(o, top, "Grandstand") - Vector3.new(0, 0, back * (rows - 1) * 3.2 / 2)
	end
	for r = 1, rows do
		local stepH = r * 2
		local z = g.Z + back * (r - 1) * 3.2
		part(into, "StandStep", Vector3.new(W, stepH, 3.2), CFrame.new(g.X, top + stepH / 2, z), CONCRETE, Enum.Material.Concrete)
		part(into, "StandSeat", Vector3.new(W - 4, 0.5, 1.4), CFrame.new(g.X, top + stepH + 0.25, z - back * 0.4), WOOD, Enum.Material.WoodPlanks, true)
	end
	local backZ = g.Z + back * rows * 3.2
	part(into, "StandBack", Vector3.new(W, rows * 2 + 6, 1.2), CFrame.new(g.X, top + (rows * 2 + 6) / 2, backZ), CONCRETE, Enum.Material.Concrete)
	for k = -3, 3 do
		if math.abs(k * 11) < W / 2 - 2 then
			part(into, "StandPanel", Vector3.new(4, rows * 2 + 2, 0.2), CFrame.new(g.X + k * 11, top + (rows * 2 + 2) / 2 + 1, backZ + back * 0.7), Color3.fromRGB(70, 72, 78), Enum.Material.SmoothPlastic, true)
		end
	end
	railing(into, Vector3.new(g.X - W / 2, top + rows * 2, backZ - back * 1.5), Vector3.new(g.X + W / 2, top + rows * 2, backZ - back * 1.5))
	if T >= 40 then
		part(into, "StandPlot", Vector3.new(W + 20, 0.3, 40), CFrame.new(g.X, top + 0.15, g.Z - 8), Color3.fromRGB(196, 196, 190), Enum.Material.Pavement)
	end
end

LabOwnerMap.HIDE_OLD_TOWER = { Tower = true, TowerBand = true, TowerStripe = true, Stair = true, StairEdge = true, Heights = true }

-- M3: the north row (ref_6, ref_7, ref_10), west to east: the rock cave with its stone-ringed dirt yard (and the bear,
-- V3Assets "Bear" when the place has it), the glass aquarium (the shark tank creature moves into it: LabLayout10), the
-- leaderboard plaza (M1), the open pool, the fenced dirt pen.
local ROCK = Color3.fromRGB(132, 130, 126)
local DIRT = Color3.fromRGB(122, 98, 72)
local GLASS = Color3.fromRGB(170, 210, 230)
local WATER = Color3.fromRGB(70, 150, 200)

-- F79 (owner: "Hulen er også bare en cirkel med en masse og en sort flad væk der ikke hænger sammen"; Config.CAVE_V2):
-- the bear cave is a rock HILL of Terrain grown out of the ground (overlapping Rock/Slate/Basalt shapes, a Grass and
-- Ground skin on top and its foot), with a real arched opening carved INTO it (Air): an arch about 11 wide and 10 high,
-- a short tunnel that bends, a dark chamber, two glinting eyes at the back. The yard in front is Ground with
-- half-buried rocks, a fallen log and a stump; a low natural rock line round it with a gap where the path comes in.
-- No ball parts, no black slab, no round stones. Runs once at build; the terrain never covers a path (onPath).
local function caveV2(into: Instance, o: Vector3, top: number): Vector3
	local T = Workspace.Terrain
	local it = Plan.ITEMS.CaveBear
	local size = if it then it.size else Vector2.new(50, 40)
	local c = planAt(o, top, "CaveBear", 0, -size.Y * 0.2) -- (the hill's middle: the back of the plan box)
	local R = math.min(size.X * 0.42, size.Y * 0.52, 22) -- (the hill's radius: inside the plan box)
	local function fill(cf: CFrame, s: Vector3, mat: Enum.Material)
		pcall(function()
			T:FillBlock(cf, s, mat)
		end)
	end
	local function ball(at: Vector3, r: number, mat: Enum.Material)
		pcall(function()
			T:FillBall(at, r, mat)
		end)
	end
	-- 1. The hill: a grass skin first, then the rock body just inside it, so only the top and the foot stay green.
	ball(c + Vector3.new(0, R * 0.18, 0), R + 1.2, Enum.Material.Grass)
	ball(c + Vector3.new(-R * 0.45, R * 0.05, -R * 0.25), R * 0.72 + 1, Enum.Material.Grass)
	ball(c + Vector3.new(R * 0.5, -R * 0.05, -R * 0.2), R * 0.62 + 1, Enum.Material.Ground)
	ball(c + Vector3.new(0, R * 0.1, 0), R, Enum.Material.Rock)
	ball(c + Vector3.new(-R * 0.45, R * 0.0, -R * 0.25), R * 0.72, Enum.Material.Slate)
	ball(c + Vector3.new(R * 0.5, -R * 0.1, -R * 0.2), R * 0.62, Enum.Material.Rock)
	fill(CFrame.new(c + Vector3.new(R * 0.15, R * 0.35, R * 0.35)) * CFrame.Angles(0.3, 0.6, 0.2), Vector3.new(R * 0.7, R * 0.5, R * 0.6), Enum.Material.Basalt)
	-- (the hill must not fall below the walk level inside: no terrain under the ground plate is visible anyway)
	-- 2. The opening: an arch (a box + a round top) going in from the front, bending a little west, into a chamber.
	local front = c.Z + R * 0.95
	local W, H = math.min(11, R * 0.55), math.min(10, R * 0.5)
	local depth = R * 0.9
	local mouth = Vector3.new(c.X + R * 0.12, top, front)
	fill(CFrame.new(mouth + Vector3.new(0, H * 0.35, -depth / 2 + 4)), Vector3.new(W, H * 0.7, depth + 8), Enum.Material.Air) -- (through the front skin: terrain is 4-stud voxels)
	pcall(function()
		T:FillCylinder(CFrame.new(mouth + Vector3.new(0, H * 0.68, -depth / 2 + 4)) * CFrame.Angles(math.rad(90), 0, 0), depth + 8, W / 2, Enum.Material.Air)
	end)
	local chamber = Vector3.new(c.X - R * 0.12, top + H * 0.55, c.Z - R * 0.05)
	ball(chamber, R * 0.42, Enum.Material.Air)
	-- the floor stays flat and walkable: fill back a thin ground layer under the tunnel and the chamber
	fill(CFrame.new(Vector3.new((mouth.X + chamber.X) / 2, top - 0.6, (mouth.Z + chamber.Z) / 2)), Vector3.new(W + R * 0.5, 1.2, depth + R * 0.5), Enum.Material.Ground)
	-- roots hanging over the mouth and two glinting eyes at the back of the chamber
	for k = -2, 2 do
		local r = part(into, "CaveRoot", Vector3.new(0.25, 2 + (k % 2) * 1.2, 0.25), CFrame.new(mouth + Vector3.new(k * W / 6, H - 1.2, 0.2)) * CFrame.Angles(0, 0, math.rad(k * 6)), Color3.fromRGB(92, 70, 48), Enum.Material.Wood, true)
		r.CanCollide = false
	end
	local eyesAt = chamber + Vector3.new(0, -H * 0.2, -R * 0.3)
	for _, s in { -1, 1 } do
		local e = part(into, "CaveEye", Vector3.new(0.35, 0.35, 0.1), CFrame.lookAt(eyesAt + Vector3.new(s * 0.6, 0, 0), eyesAt + Vector3.new(s * 0.6, 0, 10)), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, true)
		e.CanCollide = false
		game:GetService("CollectionService"):AddTag(e, "CaveEye")
	end
	-- (the eyes blink every few seconds: 2 parts, a cheap loop)
	task.spawn(function()
		local r = Random.new(36)
		while into.Parent do
			task.wait(r:NextNumber(2.5, 5))
			for _, e in into:GetChildren() do
				if e.Name == "CaveEye" and e:IsA("BasePart") then
					e.Transparency = 1
				end
			end
			task.wait(0.15)
			for _, e in into:GetChildren() do
				if e.Name == "CaveEye" and e:IsA("BasePart") then
					e.Transparency = 0
				end
			end
		end
	end)
	local shade = part(into, "CaveDark", Vector3.new(W + 4, H + 2, 0.2), CFrame.lookAt(chamber + Vector3.new(0, 0, -R * 0.36), chamber + Vector3.new(0, 0, 10)), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, true)
	shade.Transparency = 0.25
	shade.CanCollide = false
	-- 3. The yard: Ground in front of the mouth, half-buried rocks, a fallen log, a stump, a low rock line with a gap.
	local yard = Vector3.new(mouth.X, top, front + 9)
	local yw, yd = math.min(size.X - 6, 34), 14
	fill(CFrame.new(yard + Vector3.new(0, -0.45, 0)), Vector3.new(yw, 1, yd), Enum.Material.Ground)
	local rng = Random.new(79)
	for i = 0, 10 do
		local a = i / 11 * math.pi -- (the front half of an ellipse: the hill closes the back)
		local p = yard + Vector3.new(math.cos(a) * (yw / 2), 0, math.sin(a) * (yd / 2 + 1))
		if not onPath(p, 3) and math.abs(p.X - mouth.X) > 5 then
			ball(p + Vector3.new(0, -0.6, 0), rng:NextNumber(1.6, 2.6), if i % 3 == 0 then Enum.Material.Slate else Enum.Material.Rock)
		end
	end
	for _, d in { Vector3.new(-yw * 0.32, 0, -2), Vector3.new(yw * 0.3, 0, 1) } do
		ball(yard + d + Vector3.new(0, -0.9, 0), rng:NextNumber(1.8, 2.4), Enum.Material.Rock) -- (half-buried rocks in the yard)
	end
	local log = part(into, "CaveLog", Vector3.new(7, 1.4, 1.4), CFrame.new(yard + Vector3.new(-yw * 0.18, 0.6, 3)) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(110, 80, 52), Enum.Material.Wood, false, Enum.PartType.Cylinder)
	log.CastShadow = true
	part(into, "CaveStump", Vector3.new(1.6, 2, 2), CFrame.new(yard + Vector3.new(yw * 0.2, 0.8, -1)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(104, 76, 50), Enum.Material.Wood, false, Enum.PartType.Cylinder)
	return mouth
end

local function northRow(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local function at(x: number, z: number): Vector3
		return Vector3.new(o.X + x * S, top, o.Z + z * S)
	end
	local CAVE_V2 = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).CAVE_V2 == true
	local caveMouth: Vector3? = if CAVE_V2 then caveV2(into, o, top) else nil -- (F79: the terrain hill with a carved opening)
	-- THE CAVE: a big rounded grey rock with a dark mouth, a dirt yard in front ringed with grey stones.
	local cave = planAt(o, top, "CaveBear", 0, -6) -- (M4: the compact cave, the plan's 50 x 40; F79 rebuilds it as a terrain hill)
	if not CAVE_V2 then
	part(into, "CaveRock", Vector3.new(44, 30, 36), CFrame.new(cave + Vector3.new(0, 8, 0)), ROCK, Enum.Material.Rock, false, Enum.PartType.Ball)
	part(into, "CaveRock", Vector3.new(28, 22, 24), CFrame.new(cave + Vector3.new(-12, 6, -8)), ROCK:Lerp(Color3.new(0, 0, 0), 0.08), Enum.Material.Rock, false, Enum.PartType.Ball)
	local mouth = part(into, "CaveMouth", Vector3.new(11, 10, 3), CFrame.new(cave + Vector3.new(6, 5, 17)), Color3.fromRGB(28, 26, 24), Enum.Material.Slate, true)
	mouth.Shape = Enum.PartType.Block
	local yard = planAt(o, top, "CaveBear", 4, 14)
	part(into, "CaveYard", Vector3.new(36, 0.3, 14), CFrame.new(yard + Vector3.new(0, 0.15, 0)), DIRT, Enum.Material.Ground)
	local n = 12
	for i = 1, n do
		local a = i / n * math.pi * 2
		local r = Vector3.new(math.cos(a) * 18, 0, math.sin(a) * 7)
		local s = 4 + (i % 3) * 1.5
		if not onPath(yard + r, s) then
			part(into, "YardStone", Vector3.new(s * 1.4, s, s * 1.2), CFrame.new(yard + r + Vector3.new(0, s * 0.35, 0)) * CFrame.Angles(0, a, 0), ROCK, Enum.Material.Rock, true, Enum.PartType.Ball)
		end
	end
	end -- (CAVE_V2)
	-- THE AQUARIUM: a glass box on a concrete base with a steel frame, water inside.
	local aq = planAt(o, top, "Aquarium")
	local AW, AD, AH = AQUA.X, AQUA.Y, AQUA.Z
	part(into, "AquaBase", Vector3.new(AW + 4, 3, AD + 4), CFrame.new(aq + Vector3.new(0, 1.5, 0)), Color3.fromRGB(160, 160, 158), Enum.Material.Concrete)
	local water = part(into, "AquaWater", Vector3.new(AW - 1, AH - 3, AD - 1), CFrame.new(aq + Vector3.new(0, 3 + (AH - 3) / 2, 0)), WATER, Enum.Material.Glass, true)
	water.Transparency = 0.45
	water.CanCollide = false
	for _, side in { { Vector3.new(AW, AH, 0.6), Vector3.new(0, 0, AD / 2) }, { Vector3.new(AW, AH, 0.6), Vector3.new(0, 0, -AD / 2) }, { Vector3.new(0.6, AH, AD), Vector3.new(AW / 2, 0, 0) }, { Vector3.new(0.6, AH, AD), Vector3.new(-AW / 2, 0, 0) } } do
		local g = part(into, "AquaGlass", side[1], CFrame.new(aq + side[2] + Vector3.new(0, 3 + AH / 2, 0)), GLASS, Enum.Material.Glass)
		g.Transparency = 0.7
	end
	for _, x in { -AW / 2, -AW / 6, AW / 6, AW / 2 } do
		for _, z in { -AD / 2, AD / 2 } do
			part(into, "AquaFrame", Vector3.new(1, AH, 1), CFrame.new(aq + Vector3.new(x, 3 + AH / 2, z)), Color3.fromRGB(90, 96, 104), Enum.Material.Metal, true)
		end
	end
	part(into, "AquaTopRim", Vector3.new(AW + 1, 1, 1.2), CFrame.new(aq + Vector3.new(0, 3 + AH, AD / 2)), Color3.fromRGB(90, 96, 104), Enum.Material.Metal, true)
	part(into, "AquaTopRim", Vector3.new(AW + 1, 1, 1.2), CFrame.new(aq + Vector3.new(0, 3 + AH, -AD / 2)), Color3.fromRGB(90, 96, 104), Enum.Material.Metal, true)
	-- THE POOL: open water in a light concrete rim.
	local pool = planAt(o, top, "BigPool")
	local PW, PD = POOL.X, POOL.Y
	part(into, "PoolRim", Vector3.new(PW + 8, 1.2, 4), CFrame.new(pool + Vector3.new(0, 0.6, PD / 2 + 2)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	part(into, "PoolRim", Vector3.new(PW + 8, 1.2, 4), CFrame.new(pool + Vector3.new(0, 0.6, -PD / 2 - 2)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	part(into, "PoolRim", Vector3.new(4, 1.2, PD), CFrame.new(pool + Vector3.new(PW / 2 + 2, 0.6, 0)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	part(into, "PoolRim", Vector3.new(4, 1.2, PD), CFrame.new(pool + Vector3.new(-PW / 2 - 2, 0.6, 0)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	local pw = part(into, "PoolWater", Vector3.new(PW, 0.4, PD), CFrame.new(pool + Vector3.new(0, 0.5, 0)), Color3.fromRGB(110, 190, 225), Enum.Material.Glass)
	pw.Transparency = 0.25
	-- THE PEN: a dirt yard with a post-and-rail fence and a gate on its south side.
	local pen = planAt(o, top, "SpiderPen")
	local EW, ED = PEN.X, PEN.Y
	part(into, "PenDirt", Vector3.new(EW, 0.3, ED), CFrame.new(pen + Vector3.new(0, 0.15, 0)), DIRT:Lerp(Color3.fromRGB(150, 130, 100), 0.3), Enum.Material.Ground)
	local corners = { Vector3.new(-EW / 2, 0, -ED / 2), Vector3.new(EW / 2, 0, -ED / 2), Vector3.new(EW / 2, 0, ED / 2), Vector3.new(-EW / 2, 0, ED / 2) }
	for i = 1, 4 do
		local a, b = pen + corners[i], pen + corners[i % 4 + 1]
		local len = (b - a).Magnitude
		local posts = math.floor(len / 8)
		for k = 0, posts do
			local p = a:Lerp(b, k / posts)
			local gate = i == 3 and math.abs((p - pen).X) < 8
			if not gate and not onPath(p, 1) then
				part(into, "PenPost", Vector3.new(0.6, 5, 0.6), CFrame.new(p + Vector3.new(0, 2.5, 0)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
			end
		end
		for _, y in { 2, 4.4 } do
			if i == 3 then
				for _, seg in { { a, pen + Vector3.new(8, 0, ED / 2) }, { pen + Vector3.new(-8, 0, ED / 2), b } } do
					local l = (seg[2] - seg[1]).Magnitude
					part(into, "PenRail", Vector3.new(0.3, 0.3, l), CFrame.lookAt((seg[1] + seg[2]) / 2 + Vector3.new(0, y, 0), seg[2] + Vector3.new(0, y, 0)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
				end
			else
				part(into, "PenRail", Vector3.new(0.3, 0.3, len), CFrame.lookAt((a + b) / 2 + Vector3.new(0, y, 0), b + Vector3.new(0, y, 0)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
			end
		end
	end
	-- The bear (decoration) at the cave mouth, if the place has the model.
	local assets = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
	local bear = assets and assets:FindFirstChild("Bear")
	if bear and bear:IsA("Model") then
		local b = bear:Clone()
		for _, d in b:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanQuery = false
			elseif d:IsA("LuaSourceContainer") then
				d:Destroy()
			end
		end
		local _, size = b:GetBoundingBox()
		local bearAt = if caveMouth then caveMouth + Vector3.new(7, 0, 9) else cave + Vector3.new(6, 0, 22)
		b:PivotTo(CFrame.lookAt(bearAt + Vector3.new(0, size.Y / 2, 0), bearAt + Vector3.new(0, size.Y / 2, 40)))
		b.Parent = into
	end
end

-- M4: the west (ref_6, ref_9, ref_10): the three car bays (the tank, the monster truck and the blue car stand in them:
-- LabLayout10.CARS), red barrels, the long brick crash wall, the garage on the railway, the rocket's round pad and its
-- truss gantry, the concrete slab, the walled T-rex pen with its gate (V3Assets "TRex"), the crocodile pond with the
-- speaker wall (V3Assets "Crocodile"). The boxing ring moves to its plan spot through LabLayout10.MOVES.Lava.
local BRICK = Color3.fromRGB(150, 84, 62)
local function placeModel(into: Instance, name: string, at: Vector3, look: Vector3)
	local assets = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
	local src = assets and assets:FindFirstChild(name)
	if not (src and src:IsA("Model")) then
		return
	end
	local m = src:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanQuery = false
		elseif d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local cf, size = m:GetBoundingBox()
	local lift = size.Y / 2 + (m:GetPivot().Position.Y - cf.Position.Y)
	m:PivotTo(CFrame.lookAt(at + Vector3.new(0, lift, 0), at + Vector3.new(0, lift, 0) + look))
	m.Parent = into
end

local function west(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local function at(x: number, z: number): Vector3
		return Vector3.new(o.X + x * S, top, o.Z + z * S)
	end
	-- The car bays: a concrete slab with white bay lines and a low kerb at the back.
	local bays = planAt(o, top, "CarBays")
	part(into, "BaySlab", Vector3.new(44, 0.3, 18), CFrame.new(bays + Vector3.new(0, 0.15, 0)), Color3.fromRGB(176, 176, 172), Enum.Material.Concrete)
	for _, k in { -1.5, -0.5, 0.5, 1.5 } do
		part(into, "BayLine", Vector3.new(0.6, 0.05, 15), CFrame.new(bays + Vector3.new(k * 14.6, 0.33, 0.6)), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic, true)
	end
	part(into, "BayKerb", Vector3.new(44, 1, 1.2), CFrame.new(bays + Vector3.new(0, 0.5, -8.4)), Color3.fromRGB(200, 200, 196), Enum.Material.Concrete)
	-- Red barrels in two groups (a white band round each).
	for _, g in { planAt(o, top, "BrickWall", 6, -26), planAt(o, top, "BrickWall", 6, 22) } do
		for k = 0, 4 do
			-- (OBJECT BY OBJECT: groups of 5 touching, one tipped)
			local p = g + Vector3.new((k % 3) * 2.1, 0, math.floor(k / 3) * 2.1)
			barrelModel(into, p, k * 0.7, k == 4)
		end
	end
	-- The long brick crash wall (north-south).
	local wa, wb = planAt(o, top, "BrickWall", 0, -20), planAt(o, top, "BrickWall", 0, 20)
	local wl = (wb - wa).Magnitude
	part(into, "CrashBrickWall", Vector3.new(4, 12, wl), CFrame.new((wa + wb) / 2 + Vector3.new(0, 6, 0)), BRICK, Enum.Material.Brick)
	part(into, "CrashBrickCap", Vector3.new(4.6, 0.8, wl + 0.6), CFrame.new((wa + wb) / 2 + Vector3.new(0, 12.4, 0)), Color3.fromRGB(170, 166, 160), Enum.Material.Concrete, true)
	-- The garage on the railway (the rail runs into it).
	local gar = planAt(o, top, "Garage")
	part(into, "GarageFloor", Vector3.new(30, 0.4, 26), CFrame.new(gar + Vector3.new(0, 0.2, 0)), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
	for _, side in { -1, 1 } do
		part(into, "GarageWall", Vector3.new(1.5, 14, 26), CFrame.new(gar + Vector3.new(side * 14.25, 7, 0)), Color3.fromRGB(196, 190, 180), Enum.Material.Concrete)
	end
	part(into, "GarageBack", Vector3.new(30, 14, 1.5), CFrame.new(gar + Vector3.new(0, 7, 12.25)), Color3.fromRGB(196, 190, 180), Enum.Material.Concrete)
	part(into, "GarageRoof", Vector3.new(32, 1.5, 28), CFrame.new(gar + Vector3.new(0, 14.75, 0)), Color3.fromRGB(196, 130, 110), Enum.Material.Slate)
	-- The rocket's round pad and its steel gantry (the rocket itself is LabDress "Rocket", moved here).
	local rk = planAt(o, top, "Rocket")
	part(into, "RocketPad", Vector3.new(1, 16, 16), CFrame.new(rk + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(160, 160, 158), Enum.Material.Concrete, false, Enum.PartType.Cylinder)
	local gx = rk + Vector3.new(11, 0, 0)
	for _, dx in { -3, 3 } do
		for _, dz in { -3, 3 } do
			part(into, "GantryLeg", Vector3.new(0.9, 34, 0.9), CFrame.new(gx + Vector3.new(dx, 17, dz)), Color3.fromRGB(95, 100, 106), Enum.Material.Metal)
		end
	end
	for y = 4, 30, 6 do
		for _, e in { { Vector3.new(-3, y, -3), Vector3.new(3, y + 6, -3) }, { Vector3.new(3, y, 3), Vector3.new(-3, y + 6, 3) }, { Vector3.new(-3, y, 3), Vector3.new(-3, y + 6, -3) }, { Vector3.new(3, y, -3), Vector3.new(3, y + 6, 3) } } do
			local a, b = gx + e[1], gx + e[2]
			part(into, "GantryBrace", Vector3.new(0.35, 0.35, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), Color3.fromRGB(95, 100, 106), Enum.Material.Metal, true)
		end
	end
	part(into, "GantryArm", Vector3.new(10, 1.2, 2), CFrame.new(gx + Vector3.new(-6, 26, 0)), Color3.fromRGB(95, 100, 106), Enum.Material.Metal)
	-- The concrete slab south of the rocket.
	part(into, "ConcreteSlab", Vector3.new(60, 1, 44), CFrame.new(planAt(o, top, "LandingField") + Vector3.new(0, 0.5, 0)), Color3.fromRGB(170, 170, 168), Enum.Material.Concrete)
	-- The walled T-rex pen with its gate (east side) and the T-rex.
	local tr = planAt(o, top, "TRexPen")
	local TW = 110
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).PEN_TO_PLAN then
		-- (F55, owner: "Man kan ikke gå denne sti, fordi muren ikke har en dør": the pen was a 110 x 110 square, far bigger than
		-- its plan footprint (100 x 46), so its walls stood across the Animal Cove path by the aquarium. Now it is the plan's
		-- size, closed on the east, with its gate in the WEST wall where the courtyard path arrives.)
		local PW, PD = 100, 46
		local gx = -1 -- (the gate's side: -1 west (round 3), 1 east (M4: the plan's face E))
		if Plan.ITEMS.TRexPen and Plan.ITEMS.TRexPen.size.X < 60 then
			PW, PD, gx = Plan.ITEMS.TRexPen.size.X, Plan.ITEMS.TRexPen.size.Y, 1
		end
		local WALL = Color3.fromRGB(150, 146, 138)
		for _, sz in { -1, 1 } do
			part(into, "TRexWall", Vector3.new(PW, 12, 3), CFrame.new(tr + Vector3.new(0, 6, sz * PD / 2)), WALL, Enum.Material.Concrete)
		end
		part(into, "TRexWall", Vector3.new(3, 12, PD), CFrame.new(tr + Vector3.new(-gx * PW / 2, 6, 0)), WALL, Enum.Material.Concrete)
		for _, dz in { -1, 1 } do
			part(into, "TRexWall", Vector3.new(3, 12, PD / 2 - 8), CFrame.new(tr + Vector3.new(gx * PW / 2, 6, dz * (PD / 4 + 4))), WALL, Enum.Material.Concrete)
		end
		part(into, "TRexGate", Vector3.new(1, 11, 16), CFrame.new(tr + Vector3.new(gx * (PW / 2 + 0.6), 5.5, 0)), Color3.fromRGB(70, 70, 74), Enum.Material.DiamondPlate)
		part(into, "TRexGround", Vector3.new(PW - 3, 0.3, PD - 3), CFrame.new(tr + Vector3.new(0, 0.15, 0)), Color3.fromRGB(120, 104, 80), Enum.Material.Ground)
	else
	for _, w in { { Vector3.new(TW, 18, 3), Vector3.new(0, 9, -TW / 2) }, { Vector3.new(TW, 18, 3), Vector3.new(0, 9, TW / 2) }, { Vector3.new(3, 18, TW), Vector3.new(-TW / 2, 9, 0) } } do
		part(into, "TRexWall", w[1], CFrame.new(tr + w[2]), Color3.fromRGB(150, 146, 138), Enum.Material.Concrete)
	end
	for _, dz in { -1, 1 } do
		part(into, "TRexWall", Vector3.new(3, 18, TW / 2 - 12), CFrame.new(tr + Vector3.new(TW / 2, 9, dz * (TW / 4 + 6))), Color3.fromRGB(150, 146, 138), Enum.Material.Concrete)
	end
	part(into, "TRexGate", Vector3.new(1, 16, 24), CFrame.new(tr + Vector3.new(TW / 2 + 0.6, 8, 0)), Color3.fromRGB(70, 70, 74), Enum.Material.DiamondPlate)
	part(into, "TRexGround", Vector3.new(TW - 3, 0.3, TW - 3), CFrame.new(tr + Vector3.new(0, 0.15, 0)), Color3.fromRGB(120, 104, 80), Enum.Material.Ground)
	end
	placeModel(into, "TRex", tr, Vector3.new(1, 0, 0.3))
	-- The crocodile pond with its speaker wall.
	local pond = planAt(o, top, "CrocPond")
	local water = part(into, "CrocWater", Vector3.new(0.6, CROC_R * 2 - 8, CROC_R * 2 - 8), CFrame.new(pond + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 110, 80), Enum.Material.Glass, false, Enum.PartType.Cylinder)
	water.Transparency = 0.2
	for i = 1, 3 do
		local a = i * 2.1
		placeModel(into, "Crocodile", pond + Vector3.new(math.cos(a) * CROC_R * 0.45, 0.3, math.sin(a) * CROC_R * 0.45), Vector3.new(math.sin(a), 0, -math.cos(a)))
	end
	local sw = pond + Vector3.new(0, 0, CROC_R + 5) -- (south of the pond; the cones face the pond; M4: a smaller wall)
	for k = -2, 2 do
		for y = 0, 1 do
			part(into, "Speaker", Vector3.new(8, 7, 5), CFrame.new(sw + Vector3.new(k * 8.4, 3.5 + y * 7.2, 0)), Color3.fromRGB(32, 32, 36), Enum.Material.SmoothPlastic)
			part(into, "SpeakerCone", Vector3.new(0.4, 4.6, 4.6), CFrame.new(sw + Vector3.new(k * 8.4, 3.5 + y * 7.2, -2.6)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(70, 70, 76), Enum.Material.Metal, true, Enum.PartType.Cylinder)
		end
	end
end

-- M5: the east (ref_7, ref_8, ref_10): the giant fan (MapShopService places it at the plan's (45, -40)), the beige
-- sandcastle tower with crates, a picket fence and benches, the yellow sandbox, the round sand circle, the archery
-- target on its stand, the wooden seesaw, the GYRO CAGE (three steel rings turning round each other on a pad, with its
-- red button; the stretch machine stands beside it), the raised trampoline (LabLayout10.TRAMPOLINE), the long lava strip
-- in its sunken stone trench, the turf square and the TESLA COIL.
local SAND = Color3.fromRGB(226, 204, 150)
local function east(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local function at(x: number, z: number): Vector3
		return Vector3.new(o.X + x * S, top, o.Z + z * S)
	end
	-- The sandcastle tower: a square beige tower with battlements, crates and a picket fence round its plot.
	local sc = planAt(o, top, "Sandcastle")
	part(into, "SandcastleTower", Vector3.new(10, 22, 10), CFrame.new(sc + Vector3.new(0, 11, 0)), SAND, Enum.Material.Sandstone)
	for _, d in { Vector3.new(-4, 0, -4), Vector3.new(4, 0, -4), Vector3.new(-4, 0, 4), Vector3.new(4, 0, 4) } do
		part(into, "SandcastleMerlon", Vector3.new(2.6, 2.6, 2.6), CFrame.new(sc + d + Vector3.new(0, 23.3, 0)), SAND, Enum.Material.Sandstone)
	end
	for k = 0, 5 do
		crateModel(into, CFrame.new(sc + Vector3.new(-8.5 + (k % 3) * 4.2, 2 + math.floor(k / 3) * 4, 7)) * CFrame.Angles(0, math.rad(k * 7), 0), 4)
	end
	for k = -3, 3 do
		part(into, "Picket", Vector3.new(0.5, 3.4, 0.3), CFrame.new(sc + Vector3.new(k * 2.4, 1.7, -8.5)), Color3.fromRGB(240, 236, 226), Enum.Material.Wood, true)
	end
	part(into, "PicketRail", Vector3.new(15, 0.3, 0.3), CFrame.new(sc + Vector3.new(0, 2.6, -8.5)), Color3.fromRGB(240, 236, 226), Enum.Material.Wood, true)
	-- The yellow sandbox with a wooden rim.
	local sb = planAt(o, top, "Sandbox")
	part(into, "SandboxSand", Vector3.new(24, 0.6, 20), CFrame.new(sb + Vector3.new(0, 0.3, 0)), Color3.fromRGB(240, 200, 70), Enum.Material.Sand)
	for _, r in { { Vector3.new(26, 1.2, 1.2), Vector3.new(0, 0.6, 10.6) }, { Vector3.new(26, 1.2, 1.2), Vector3.new(0, 0.6, -10.6) }, { Vector3.new(1.2, 1.2, 22), Vector3.new(12.6, 0.6, 0) }, { Vector3.new(1.2, 1.2, 22), Vector3.new(-12.6, 0.6, 0) } } do
		part(into, "SandboxRim", r[1], CFrame.new(sb + r[2]), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
	end
	-- The round sand circle.
	part(into, "SandCircle", Vector3.new(0.4, 32, 32), CFrame.new(planAt(o, top, "SandCircle") + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), SAND, Enum.Material.Sand, false, Enum.PartType.Cylinder)
	-- The archery target on its wooden A-frame.
	local tg = planAt(o, top, "Archery")
	for _, s in { -1, 1 } do
		part(into, "TargetLeg", Vector3.new(0.6, 12, 0.6), CFrame.new(tg + Vector3.new(s * 3, 5.5, 1.5)) * CFrame.Angles(math.rad(-12), 0, math.rad(s * 10)), Color3.fromRGB(130, 96, 62), Enum.Material.Wood)
	end
	for i, ring in { { 9, Color3.fromRGB(240, 240, 240) }, { 6.6, Color3.fromRGB(30, 30, 30) }, { 4.4, Color3.fromRGB(240, 240, 240) }, { 2.2, Color3.fromRGB(210, 40, 40) } } do
		part(into, "TargetFace", Vector3.new(0.3 + i * 0.05, ring[1], ring[1]), CFrame.new(tg + Vector3.new(0, 8, -i * 0.06)) * CFrame.Angles(0, math.rad(90), 0), ring[2], Enum.Material.SmoothPlastic, i > 1, Enum.PartType.Cylinder)
	end
	-- The wooden seesaw.
	local ss = planAt(o, top, "Seesaw")
	part(into, "SeesawPivot", Vector3.new(3, 2.4, 2.4), CFrame.new(ss + Vector3.new(0, 1.2, 0)), Color3.fromRGB(70, 74, 80), Enum.Material.Metal, false, Enum.PartType.Cylinder)
	part(into, "SeesawPlank", Vector3.new(14, 0.8, 3), CFrame.new(ss + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(9)), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
	-- THE GYRO CAGE: three steel rings on a pad, turning round each other, with a red button.
	local gc = planAt(o, top, "GyroCage")
	part(into, "GyroPad", Vector3.new(0.6, 20, 20), CFrame.new(gc + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 156, 150), Enum.Material.Concrete, false, Enum.PartType.Cylinder)
	local hub = gc + Vector3.new(0, 10, 0)
	part(into, "GyroStand", Vector3.new(1.6, 10, 1.6), CFrame.new(gc + Vector3.new(-9.5, 5, 0)), Color3.fromRGB(96, 110, 96), Enum.Material.Metal)
	part(into, "GyroStand", Vector3.new(1.6, 10, 1.6), CFrame.new(gc + Vector3.new(9.5, 5, 0)), Color3.fromRGB(96, 110, 96), Enum.Material.Metal)
	local rings: { { parts: { BasePart }, r: number, axis: Vector3, speed: number, base: { CFrame } } } = {}
	-- (MAP_MACHINES_LIVE: the rings turn on each screen (Client/GateMotion "Spin"), not by the server 10 times a second)
	local gyroClient = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).MAP_MACHINES_LIVE == true
	for i, spec in { { 8.5, Vector3.xAxis, 0.6 }, { 7, Vector3.zAxis, -0.9 }, { 5.5, Vector3.xAxis, 1.3 } } do
		local list, bases = {}, {}
		local n = 16
		local ringModel = Instance.new("Model")
		ringModel.Name = "GyroRingSet"
		ringModel.Parent = into
		for k = 1, n do
			local a = k / n * math.pi * 2
			local seg = 2 * math.pi * spec[1] / n + 0.3
			local cf = CFrame.Angles(0, 0, a) * CFrame.new(spec[1], 0, 0)
			local p = part(into, "GyroRing", Vector3.new(1.2, seg, 1.2), CFrame.new(hub) * cf, Color3.fromRGB(96, 116, 98), Enum.Material.Metal, true)
			p.CanCollide = false
			if gyroClient then
				p.Parent = ringModel
			end
			table.insert(list, p)
			table.insert(bases, cf)
		end
		table.insert(rings, { parts = list, r = spec[1], axis = spec[2], speed = spec[3], base = bases })
		if gyroClient then
			ringModel.WorldPivot = CFrame.new(hub)
			game:GetService("CollectionService"):AddTag(ringModel, "Spin")
			ringModel:SetAttribute("Axis", if i == 3 then Vector3.yAxis else spec[2])
			ringModel:SetAttribute("Speed", spec[3])
		end
		local _ = i
	end
	part(into, "GyroButton", Vector3.new(0.8, 3, 3), CFrame.new(gc + Vector3.new(0, 1, -12)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 40, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	task.spawn(function()
		local t0 = os.clock()
		while into.Parent and not gyroClient do
			local t = os.clock() - t0
			local outer = CFrame.fromAxisAngle(Vector3.yAxis, t * 0.4)
			for i, ring in rings do
				local spin = outer * CFrame.fromAxisAngle(ring.axis, t * ring.speed + i)
				for k, p in ring.parts do
					p.CFrame = CFrame.new(hub) * spin * ring.base[k]
				end
			end
			task.wait(0.1)
		end
	end)
	-- The long lava strip in a sunken stone trench.
	-- (M4: the plan's strip runs north-south, 14 wide and 80 long)
	local la, lb = planAt(o, top, "LavaStrip", 0, -34), planAt(o, top, "LavaStrip", 0, 34)
	local ll = (lb - la).Magnitude
	part(into, "TrenchStone", Vector3.new(14, 0.6, ll + 6), CFrame.new((la + lb) / 2 + Vector3.new(0, 0.3, 0)), Color3.fromRGB(110, 106, 100), Enum.Material.Cobblestone)
	local lava = part(into, "LavaStrip", Vector3.new(8, 0.4, ll), CFrame.new((la + lb) / 2 + Vector3.new(0, 0.5, 0)), Color3.fromRGB(255, 110, 30), Enum.Material.CrackedLava)
	lava.CanTouch = false
	for _, s in { -1, 1 } do
		part(into, "TrenchKerb", Vector3.new(2, 2, ll + 6), CFrame.new((la + lb) / 2 + Vector3.new(s * 6, 1, 0)), Color3.fromRGB(90, 88, 86), Enum.Material.Slate)
		-- (OBJECT BY OBJECT: a dark fence along the trench: posts every 8, two rails; a gap in the middle of the west side
		-- where the path arrives)
		local fx = (la + lb) / 2 + Vector3.new(s * 7.4, 0, 0)
		for _, seg in (if s < 0 then { { -ll / 2 - 3, -5 }, { 5, ll / 2 + 3 } } else { { -ll / 2 - 3, ll / 2 + 3 } }) do
			local z0, z1 = seg[1], seg[2]
			for z = z0, z1, 8 do
				part(into, "LavaFencePost", Vector3.new(0.3, 3.4, 0.3), CFrame.new(fx + Vector3.new(0, 1.7, z)), PROP.iron, Enum.Material.Metal, true)
			end
			for _, y in { 1.6, 3.2 } do
				part(into, "LavaFenceRail", Vector3.new(0.18, 0.18, z1 - z0), CFrame.new(fx + Vector3.new(0, y, (z0 + z1) / 2)), PROP.iron, Enum.Material.Metal, true)
			end
		end
	end
	-- The turf square.
	if inPlan("Gazebo") then part(into, "TurfSquare", Vector3.new(70, 0.3, 70), CFrame.new(planAt(o, top, "Gazebo") + Vector3.new(0, 0.15, 0)), Color3.fromRGB(70, 140, 60), Enum.Material.Fabric) end
	-- THE TESLA COIL: a stepped column with a doughnut top and blue sparks.
	local tc = planAt(o, top, "TeslaCoil")
	part(into, "TeslaBase", Vector3.new(10, 3, 10), CFrame.new(tc + Vector3.new(0, 1.5, 0)), Color3.fromRGB(60, 62, 70), Enum.Material.Metal)
	part(into, "TeslaColumn", Vector3.new(18, 4.4, 4.4), CFrame.new(tc + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 120, 60), Enum.Material.Metal, false, Enum.PartType.Cylinder)
	local top2 = part(into, "TeslaTop", Vector3.new(3, 11, 11), CFrame.new(tc + Vector3.new(0, 22.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 204, 210), Enum.Material.Metal, false, Enum.PartType.Cylinder)
	local spark = Instance.new("ParticleEmitter")
	spark.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spark.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255))
	spark.LightEmission = 1
	spark.Size = NumberSequence.new(1.2, 0)
	spark.Speed = NumberRange.new(8, 16)
	spark.Lifetime = NumberRange.new(0.15, 0.35)
	spark.Rate = 12
	spark.SpreadAngle = Vector2.new(180, 180)
	spark.Parent = top2
end

-- M6: the south (ref_8, ref_9): the round sweeper pad with its turning beam, the shredder pit (a long sunken pit with
-- two rollers, a steel railing round it, a lever and a red button).
-- M8: the dressing: groves of round low-poly trees and pines, boulder fields and benches in the open grass, so no flat
-- area is left empty (decoration: no collisions for the leaves, no shadows on the small things).
local function south(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local function at(x: number, z: number): Vector3
		return Vector3.new(o.X + x * S, top, o.Z + z * S)
	end
	-- The sweeper: a round pad, a centre post and a long beam turning slowly at knee height.
	local sw = planAt(o, top, "Sweeper")
	part(into, "SweeperPad", Vector3.new(0.6, 28, 28), CFrame.new(sw + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 196, 186), Enum.Material.Concrete, false, Enum.PartType.Cylinder)
	part(into, "SweeperRing", Vector3.new(0.65, 29.5, 29.5), CFrame.new(sw + Vector3.new(0, 0.28, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	part(into, "SweeperPost", Vector3.new(6, 6, 6), CFrame.new(sw + Vector3.new(0, 3, 0)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)
	local beamPart = part(into, "SweeperBeam", Vector3.new(26, 2.4, 2.4), CFrame.new(sw + Vector3.new(0, 2.4, 0)), Color3.fromRGB(230, 120, 30), Enum.Material.Metal)
	beamPart.CanCollide = true
	task.spawn(function()
		local t0 = os.clock()
		while into.Parent do
			beamPart.CFrame = CFrame.new(sw + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, (os.clock() - t0) * 0.5, 0)
			task.wait(0.05)
		end
	end)
	-- The shredder pit: a sunken dark pit in a concrete frame, two rollers, a railing, a lever and a button.
	local sp = planAt(o, top, "Shredder")
	local PW, PD = 20, 10 -- (M4: inside the plan's 28 x 18)
	part(into, "ShredderFrame", Vector3.new(PW + 8, 1, PD + 8), CFrame.new(sp + Vector3.new(0, 0.5, 0)), Color3.fromRGB(160, 160, 158), Enum.Material.Concrete)
	local pit = part(into, "ShredderPit", Vector3.new(PW, 1.1, PD), CFrame.new(sp + Vector3.new(0, 0.55, 0)), Color3.fromRGB(26, 26, 28), Enum.Material.Slate)
	pit.CanCollide = false
	part(into, "ShredderFloor", Vector3.new(PW, 1, PD), CFrame.new(sp + Vector3.new(0, -8, 0)), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	for _, dz in { -2.4, 2.4 } do
		part(into, "ShredderRoller", Vector3.new(PW - 2, 4.6, 4.6), CFrame.new(sp + Vector3.new(0, -3, dz)), Color3.fromRGB(120, 124, 130), Enum.Material.DiamondPlate, false, Enum.PartType.Cylinder)
	end
	local corners = { Vector3.new(-PW / 2 - 3, 0, -PD / 2 - 3), Vector3.new(PW / 2 + 3, 0, -PD / 2 - 3), Vector3.new(PW / 2 + 3, 0, PD / 2 + 3), Vector3.new(-PW / 2 - 3, 0, PD / 2 + 3) }
	for i = 1, 4 do
		local a, b = sp + corners[i] + Vector3.new(0, 1, 0), sp + corners[i % 4 + 1] + Vector3.new(0, 1, 0)
		railing(into, a, b)
	end
	part(into, "ShredderLeverBox", Vector3.new(3, 4, 3), CFrame.new(sp + Vector3.new(PW / 2 + 5, 2, 0)), Color3.fromRGB(240, 200, 40), Enum.Material.Metal)
	part(into, "ShredderLever", Vector3.new(0.5, 4, 0.5), CFrame.new(sp + Vector3.new(PW / 2 + 5, 5.5, 0)) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal, true)
	part(into, "ShredderButton", Vector3.new(0.8, 3, 3), CFrame.new(sp + Vector3.new(PW / 2 + 5, 1, 4)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 40, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
end

-- M8: trees, pines, boulders and benches in the open grass (plan coordinates; times S).
LabOwnerMap.GROVES = {
	Vector2.new(-110, -40), Vector2.new(-100, 25), Vector2.new(-60, -100), Vector2.new(-15, -70), Vector2.new(20, -15),
	Vector2.new(60, -70), Vector2.new(115, -80), Vector2.new(130, 10), Vector2.new(100, 100), Vector2.new(40, 110),
	Vector2.new(-20, 95), Vector2.new(-85, 100), Vector2.new(-140, 80), Vector2.new(-140, -90), Vector2.new(-30, 60),
	Vector2.new(30, 55), Vector2.new(140, 55), Vector2.new(-60, 5),
}
local function tree(into: Instance, p: Vector3, size: number, pine: boolean, rng: Random)
	local trunkH = size * (if pine then 0.5 else 0.6)
	part(into, "TreeTrunk", Vector3.new(size * 0.12, trunkH, size * 0.12), CFrame.new(p + Vector3.new(0, trunkH / 2, 0)), Color3.fromRGB(110, 80, 56), Enum.Material.Wood, true)
	local green = Color3.fromRGB(70, 130, 60):Lerp(Color3.fromRGB(110, 160, 70), rng:NextNumber())
	if pine then
		for k = 0, 2 do
			local w = size * (0.7 - k * 0.18)
			local leaf = part(into, "PineLayer", Vector3.new(w, size * 0.35, w), CFrame.new(p + Vector3.new(0, trunkH * 0.7 + k * size * 0.28, 0)) * CFrame.Angles(0, rng:NextNumber() * 6, 0), green:Lerp(Color3.fromRGB(40, 90, 50), 0.5), Enum.Material.Grass, true, Enum.PartType.Ball)
			leaf.CanCollide = false
		end
	else
		local leaf = part(into, "TreeCrown", Vector3.new(size, size * 0.85, size), CFrame.new(p + Vector3.new(0, trunkH + size * 0.3, 0)), green, Enum.Material.Grass, true, Enum.PartType.Ball)
		leaf.CanCollide = false
	end
end
local function dress(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local rng = Random.new(7)
	for gi, g in LabOwnerMap.GROVES do
		local c = Vector3.new(o.X + g.X * S, top, o.Z + g.Y * S)
		for _ = 1, rng:NextInteger(4, 7) do
			local off = Vector3.new(rng:NextNumber(-22, 22), 0, rng:NextNumber(-22, 22))
			tree(into, c + off, rng:NextNumber(12, 20), rng:NextNumber() < 0.35, rng)
		end
		if gi % 2 == 0 then
			for _ = 1, 4 do
				local s = rng:NextNumber(3, 7)
				local off = Vector3.new(rng:NextNumber(-30, 30), s * 0.3, rng:NextNumber(-30, 30))
				part(into, "Boulder", Vector3.new(s * 1.4, s, s * 1.1), CFrame.new(c + off) * CFrame.Angles(rng:NextNumber(), rng:NextNumber() * 6, 0), Color3.fromRGB(140, 138, 132), Enum.Material.Rock, true, Enum.PartType.Ball)
			end
		end
		-- a bench at the grove's edge, facing the nearest walkway
		local b = c + Vector3.new(26, 0, 0)
		part(into, "BenchSeat", Vector3.new(7, 0.5, 2), CFrame.new(b + Vector3.new(0, 1.6, 0)), Color3.fromRGB(140, 100, 64), Enum.Material.WoodPlanks)
		part(into, "BenchBack", Vector3.new(7, 1.6, 0.4), CFrame.new(b + Vector3.new(0, 2.6, 1)), Color3.fromRGB(140, 100, 64), Enum.Material.WoodPlanks, true)
		for _, dx in { -3, 3 } do
			part(into, "BenchLeg", Vector3.new(0.4, 1.4, 1.8), CFrame.new(b + Vector3.new(dx, 0.7, 0)), Color3.fromRGB(50, 52, 56), Enum.Material.Metal, true)
		end
	end
end

-- MAP ROUND 2, R2.3 FILL THE EMPTY SPACE (owner: "ser meget tomt ud rundt omkring"): in the open plots, in the same
-- realistic low-poly style, built by code (anchored, small things without shadows): a car park with 6 parked cars, a
-- second small pool with sun loungers, a picnic and grill corner, a small playground (slide, swings), a training yard
-- with tyres and hurdles, a parked train on the railway, a hangar with open doors and a forklift, a water tower, a
-- control tower, portable toilets and a snack kiosk; lamp posts along every walkway.
local function box(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, deco: boolean?): Part
	return part(into, name, size, cf, color, material or Enum.Material.SmoothPlastic, deco)
end
local function car(into: Instance, at: Vector3, yaw: number, color: Color3)
	local cf = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	box(into, "ParkedCarBody", Vector3.new(6, 2.2, 13), cf * CFrame.new(0, 1.9, 0), color, Enum.Material.Metal)
	box(into, "ParkedCarTop", Vector3.new(5.4, 1.8, 6.5), cf * CFrame.new(0, 3.9, 0.6), color:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Metal)
	box(into, "ParkedCarGlass", Vector3.new(5.5, 1.4, 6.6), cf * CFrame.new(0, 4, 0.6), Color3.fromRGB(60, 80, 100), Enum.Material.Glass, true).Transparency = 0.3
	for _, w in { Vector3.new(-3, 0.9, -4.2), Vector3.new(3, 0.9, -4.2), Vector3.new(-3, 0.9, 4.2), Vector3.new(3, 0.9, 4.2) } do
		part(into, "ParkedCarWheel", Vector3.new(0.9, 2.2, 2.2), cf * CFrame.new(w), Color3.fromRGB(28, 28, 30), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	end
end
local function lamp(into: Instance, at: Vector3)
	if (if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).LAMP_LINT then onWalkable(at, 2) else onPath(at, 1)) then
		return -- (rule 3: never on a path)
	end
	-- (OBJECT BY OBJECT: 10 high, a thin dark post, a small square head with a warm light, no shadows)
	box(into, "LampPost", Vector3.new(0.4, 10, 0.4), CFrame.new(at + Vector3.new(0, 5, 0)), PROP.iron, Enum.Material.Metal, true)
	box(into, "LampFoot", Vector3.new(0.9, 0.5, 0.9), CFrame.new(at + Vector3.new(0, 0.25, 0)), PROP.iron, Enum.Material.Metal, true)
	box(into, "LampCap", Vector3.new(1.3, 0.25, 1.3), CFrame.new(at + Vector3.new(0, 10.55, 0)), PROP.iron, Enum.Material.Metal, true)
	local head = box(into, "LampHead", Vector3.new(1, 0.6, 1), CFrame.new(at + Vector3.new(0, 10.15, 0)), Color3.fromRGB(255, 232, 190), Enum.Material.Neon, true)
	head.CanCollide = false
	local glow = Instance.new("PointLight")
	glow.Range = 16
	glow.Brightness = 0.8
	glow.Color = Color3.fromRGB(255, 226, 180)
	glow.Shadows = false
	glow.Parent = head
end
local function fill(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local function at(x: number, z: number): Vector3
		return Vector3.new(o.X + x * S, top, o.Z + z * S)
	end
	-- The car park: an asphalt pad the plan's size with bay lines and a parked car in each bay (M4: plan sizes).
	local cp = planAt(o, top, "CarPark")
	local cps = itemSize("CarPark", Vector2.new(40, 24))
	box(into, "CarParkPad", Vector3.new(cps.X, 0.3, cps.Y), CFrame.new(cp + Vector3.new(0, 0.15, 0)), Color3.fromRGB(70, 72, 76), Enum.Material.Asphalt)
	local colours = { Color3.fromRGB(200, 40, 40), Color3.fromRGB(40, 90, 180), Color3.fromRGB(230, 230, 230), Color3.fromRGB(30, 30, 34), Color3.fromRGB(220, 180, 40), Color3.fromRGB(120, 130, 140) }
	local bays = math.max(1, math.floor(cps.X / 12))
	for k = 0, bays - 1 do
		local x = -cps.X / 2 + (k + 0.5) * (cps.X / bays)
		box(into, "CarParkLine", Vector3.new(0.4, 0.05, cps.Y * 0.7), CFrame.new(cp + Vector3.new(x - cps.X / bays / 2, 0.33, 0)), Color3.fromRGB(235, 235, 230), Enum.Material.SmoothPlastic, true)
		car(into, cp + Vector3.new(x, 0.3, 0), 0, colours[k % #colours + 1])
	end
	-- A second, smaller pool with sun loungers and umbrellas (its rim the plan's footprint).
	local pl = planAt(o, top, "LoungePool")
	local pls = itemSize("LoungePool", Vector2.new(30, 22))
	box(into, "SmallPoolRim", Vector3.new(pls.X, 1, pls.Y - 8), CFrame.new(pl + Vector3.new(0, 0.5, 4)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	local w = box(into, "SmallPoolWater", Vector3.new(pls.X - 5, 0.4, pls.Y - 13), CFrame.new(pl + Vector3.new(0, 1.05, 4)), Color3.fromRGB(110, 190, 225), Enum.Material.Glass)
	w.Transparency = 0.2
	for k = -1, 1 do
		local l = pl + Vector3.new(k * 9, 0, -pls.Y / 2 + 2.5) -- (on the pool's north side, off the path that comes from the south)
		box(into, "Lounger", Vector3.new(3, 0.6, 7), CFrame.new(l + Vector3.new(0, 1.2, 0)), Color3.fromRGB(240, 240, 236), Enum.Material.Plastic)
		box(into, "LoungerBack", Vector3.new(3, 0.5, 3), CFrame.new(l + Vector3.new(0, 2, -3)) * CFrame.Angles(math.rad(-50), 0, 0), Color3.fromRGB(240, 240, 236), Enum.Material.Plastic, true)
		if k ~= 0 then
			box(into, "UmbrellaPole", Vector3.new(0.3, 8, 0.3), CFrame.new(l + Vector3.new(4.5, 4, 0)), Color3.fromRGB(200, 200, 200), Enum.Material.Metal, true)
			part(into, "Umbrella", Vector3.new(7, 1.2, 7), CFrame.new(l + Vector3.new(4.5, 8, 0)), if k < 0 then Color3.fromRGB(230, 70, 60) else Color3.fromRGB(60, 140, 220), Enum.Material.Fabric, true, Enum.PartType.Ball)
		end
	end
	-- The picnic and grill corner: 2 tables and a grill inside the plan's footprint.
	local pc = planAt(o, top, "PicnicGrill")
	for k = 0, 1 do
		local t = pc + Vector3.new(k * 11 - 8, 0, 0)
		box(into, "PicnicTable", Vector3.new(8, 0.5, 3.2), CFrame.new(t + Vector3.new(0, 2.6, 0)), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
		for _, s in { -1, 1 } do
			box(into, "PicnicBench", Vector3.new(8, 0.4, 1.2), CFrame.new(t + Vector3.new(0, 1.6, s * 2.6)), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
		end
	end
	box(into, "Grill", Vector3.new(4, 3, 2.4), CFrame.new(pc + Vector3.new(8.5, 1.5, 0)), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	-- The small playground: a slide and swings on a rubber mat the plan's size.
	local pg = planAt(o, top, "Playground")
	local pgs = itemSize("Playground", Vector2.new(26, 18))
	box(into, "PlaygroundMat", Vector3.new(pgs.X, 0.3, pgs.Y), CFrame.new(pg + Vector3.new(0, 0.15, 0)), Color3.fromRGB(200, 90, 70), Enum.Material.Rubber)
	box(into, "PlaySlideTower", Vector3.new(5, 7, 5), CFrame.new(pg + Vector3.new(-7, 3.5, -3)), Color3.fromRGB(60, 140, 220), Enum.Material.Plastic)
	box(into, "PlaySlide", Vector3.new(3.4, 0.5, 10), CFrame.new(pg + Vector3.new(-7, 3.3, 4)) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(250, 200, 40), Enum.Material.Plastic)
	box(into, "SwingFrame", Vector3.new(11, 0.6, 0.6), CFrame.new(pg + Vector3.new(6, 9, 0)), Color3.fromRGB(200, 60, 60), Enum.Material.Metal)
	for _, sx in { 0.8, 11.2 } do
		box(into, "SwingLeg", Vector3.new(0.6, 9, 0.6), CFrame.new(pg + Vector3.new(sx, 4.5, 0)), Color3.fromRGB(200, 60, 60), Enum.Material.Metal)
	end
	for _, sx in { 4, 8 } do
		box(into, "SwingRope", Vector3.new(0.15, 6, 0.15), CFrame.new(pg + Vector3.new(sx, 6, 0)), Color3.fromRGB(90, 70, 50), Enum.Material.Fabric, true)
		box(into, "SwingSeat", Vector3.new(2, 0.3, 1), CFrame.new(pg + Vector3.new(sx, 3, 0)), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber)
	end
	-- (M4: the training yard, the water tower, the control tower, the snack kiosk and the toilets are gone from the plan.)
	-- The parked train on the west railway (M4: on Plan.RAILWAY, north of the hangar).
	local rw = Plan.RAILWAY and Plan.RAILWAY[1]
	local tr = if rw then Vector3.new(o.X + rw.X, top, o.Z + 20) else Vector3.new(o.X + LabOwnerMap.CENTER.X - LabOwnerMap.SIZE.X / 2 + 12, top, o.Z - 300)
	for k = 0, 2 do
		local c = tr + Vector3.new(0, 0, k * 18)
		box(into, if k == 0 then "Locomotive" else "Wagon", Vector3.new(7, 7, 16), CFrame.new(c + Vector3.new(0, 4.6, 0)), if k == 0 then Color3.fromRGB(180, 40, 40) else Color3.fromRGB(70, 90, 120), Enum.Material.Metal)
		box(into, "WagonRoof", Vector3.new(7.4, 0.6, 16.4), CFrame.new(c + Vector3.new(0, 8.4, 0)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
	end
	-- The train garage on the rail (ref_11-13: grey, brown doors), the plan's footprint.
	local hg = planAt(o, top, "Hangar")
	local hgs = itemSize("Hangar", Vector2.new(30, 24))
	box(into, "HangarFloor", Vector3.new(hgs.X, 0.4, hgs.Y), CFrame.new(hg + Vector3.new(0, 0.2, 0)), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
	for _, s in { -1, 1 } do
		box(into, "HangarWall", Vector3.new(hgs.X, 14, 1.2), CFrame.new(hg + Vector3.new(0, 7, s * hgs.Y / 2)), Color3.fromRGB(150, 154, 158), Enum.Material.Concrete)
	end
	box(into, "HangarBack", Vector3.new(1.2, 14, hgs.Y), CFrame.new(hg + Vector3.new(-hgs.X / 2, 7, 0)), Color3.fromRGB(150, 154, 158), Enum.Material.Concrete)
	for _, s in { -1, 1 } do
		box(into, "HangarDoor", Vector3.new(0.6, 11, hgs.Y / 2 - 1.5), CFrame.new(hg + Vector3.new(hgs.X / 2 + 0.3, 5.5, s * (hgs.Y / 4 + 0.2))), Color3.fromRGB(120, 78, 48), Enum.Material.WoodPlanks)
	end
	box(into, "HangarRoof", Vector3.new(hgs.X + 2, 1.2, hgs.Y + 2), CFrame.new(hg + Vector3.new(0, 14.6, 0)), Color3.fromRGB(110, 114, 120), Enum.Material.Metal)
	-- (Map round 3, rule 4; M4: the walkways are 12-14 wide) Lamps only along the main walkways, few: 2 studs outside the
	-- edge, every 48 studs, alternating sides; none within 10 studs of a plaza or junction.
	for _, r in Plan.ROADS do
		if r.width >= 14 then
			for i = 1, #r.points - 1 do
				local a, b = r.points[i], r.points[i + 1]
				local len = (b - a).Magnitude
				local dir = (b - a).Unit
				local side = Vector2.new(-dir.Y, dir.X)
				local k = 0
				for s = 24, len - 24, 48 do
					k += 1
					local p = a + dir * s + side * ((r.width / 2 + 2.8) * (if k % 2 == 0 then 1 else -1))
					local clear = true
					for _, pz in Plan.PLAZAS do
						local reach = if pz.kind == "circle" then pz.radius + 10 else math.max(pz.size.X, pz.size.Y) / 2 + 10
						if (p - pz.at).Magnitude < reach then
							clear = false
						end
					end
					if clear then
						lamp(into, Vector3.new(o.X + p.X, top, o.Z + p.Y))
					end
				end
			end
		end
	end
end

-- MAP ROUND 3, P4: the tree belts (docs/MAP_MASTERPLAN.md rule 5): every walled room of OwnerMapPlan is ringed inside
-- its edge by a belt BELT wide: two staggered rows of trees (Creator Store low-poly MeshParts by PopperPoppet: oak, fir,
-- poplar; V3Assets/Trees, one part each, no scripts) and a row of bushes, so you cannot see through at eye height. The
-- belt is broken only at the room's entrances (GAP wide), where an arch with the room's name stands. Leaves never
-- collide; trees vary in size (+-25 %) and turn.
local LEAF = { TreeOak = Color3.fromRGB(96, 150, 70), TreeFir = Color3.fromRGB(58, 112, 70), TreePoplar = Color3.fromRGB(120, 160, 70) }
-- OVERVIEW 1a (MAP_MASTERPLAN rule 5b, owner: "træerne er HELT grønne og ligner noget AI-lavet"; Config.TREES_V2): real
-- trees from V3Assets/YTrees ("Yasu's Stylized Tree Pack" by mvyasu, Creator Store 79689531752352, no scripts): each a
-- textured bark trunk + a leaf canopy with gaps. Mixed species per kind, 5 greens, a rare yellow-green or autumn tree,
-- a small lean, random size; the trunk is solid, the leaves are not.
local Y_KINDS: { [string]: { string } } = {
	TreeOak = { "Tree_01", "Tree_02", "Tree_03", "Tree_04", "Tree_05", "Tree_06", "Tree_09", "Tree_11", "Tree_15", "Tree_17", "Tree_18", "Tree_19" },
	TreeFir = { "Tree_07", "Tree_08", "Tree_10", "Tree_16" },
	TreePoplar = { "Tree_12", "Tree_13", "Tree_14", "Tree_16" },
	Bush = { "Bush_01", "Bush_02", "Bush_03" },
}
local GREENS = { Color3.fromRGB(93, 107, 28), Color3.fromRGB(52, 86, 40), Color3.fromRGB(112, 140, 44), Color3.fromRGB(60, 98, 78), Color3.fromRGB(84, 96, 40) }
local function yTree(into: Instance, kind: string, at: Vector3, height: number, rng: Random, tint: Color3?): boolean
	local assets = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
	local lib = assets and assets:FindFirstChild("YTrees")
	if not lib or not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).TREES_V2 then
		return false
	end
	local list = Y_KINDS[kind] or Y_KINDS.TreeOak
	local src = lib:FindFirstChild(list[rng:NextInteger(1, #list)])
	if not (src and src:IsA("Model")) then
		return false
	end
	local t = src:Clone()
	local _, size = t:GetBoundingBox()
	t:ScaleTo(math.max(0.05, height * rng:NextNumber(0.85, 1.15) / size.Y))
	local roll = rng:NextNumber()
	local leaf = if tint then tint elseif roll < 0.03 then Color3.fromRGB(196, 110, 44) elseif roll < 0.05 then Color3.fromRGB(170, 66, 44) elseif roll < 0.11 then Color3.fromRGB(150, 160, 52)
		else GREENS[rng:NextInteger(1, #GREENS)]:Lerp(Color3.fromRGB(120, 140, 60), rng:NextNumber() * 0.2)
	for _, d in t:GetDescendants() do
		if d:IsA("BasePart") then
			local trunk = string.find(d.Name, "Trunk") ~= nil
			d.Anchored = true
			d.CanCollide = trunk and kind ~= "Bush" and not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).FOLIAGE_PASS -- (F54: players, cars and ragdolls pass through foliage)
			d.CanQuery = trunk
			d.CanTouch = false
			d.CastShadow = height > 14
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			if sa and not trunk then
				sa.Color = leaf
			end
		end
	end
	local cf, sz = t:GetBoundingBox()
	local lean = CFrame.Angles(rng:NextNumber(-0.06, 0.06), 0, rng:NextNumber(-0.06, 0.06))
	local yaw = CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	local offset = t:GetPivot().Position - cf.Position -- (the pivot from the box's middle)
	local base = at + Vector3.new(0, sz.Y / 2 - 0.6, 0) -- (roots a little in the ground)
	t:PivotTo(CFrame.new(base) * yaw * lean * CFrame.new(offset))
	t.Name = kind
	t.Parent = into
	return true
end

local function plantTree(into: Instance, kind: string, at: Vector3, height: number, rng: Random, noTrunk: boolean?)
	if onPath(at, 3) then
		return -- (rule 3: never on a path)
	end
	if yTree(into, kind, at, height, rng) then
		return -- (1a: a real tree)
	end
	local assets = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
	local trees = assets and assets:FindFirstChild("Trees")
	local src = trees and trees:FindFirstChild(kind)
	if not (src and src:IsA("BasePart")) then
		return
	end
	local t = src:Clone()
	local k = height / src.Size.Y
	t.Size = src.Size * k
	t.Color = (LEAF[kind] or LEAF.TreeOak):Lerp(Color3.fromRGB(140, 170, 80), rng:NextNumber() * 0.25)
	t.Material = Enum.Material.SmoothPlastic
	t.CFrame = CFrame.new(at + Vector3.new(0, t.Size.Y / 2, 0)) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	t.Anchored, t.CanCollide, t.CanQuery, t.CanTouch = true, false, false, false
	t.CastShadow = height > 20
	t.Parent = into
	if kind ~= "TreeFir" and not noTrunk then
		-- (one mesh: a brown trunk over its lower part; only the front row: M9)
		local tr = part(into, "TreeTrunk", Vector3.new(height * 0.36, height * 0.09, height * 0.09), CFrame.new(at + Vector3.new(0, height * 0.18, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 80, 56), Enum.Material.Wood, true, Enum.PartType.Cylinder)
		tr.CanCollide = true -- (you bump into the trunk, not the leaves)
	end
end
local function bush(into: Instance, at: Vector3, rng: Random)
	if onPath(at, 3) then
		return
	end
	if yTree(into, "Bush", at, rng:NextNumber(5, 8), rng) then
		return -- (1a: a real bush)
	end
	local assets = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
	local src = assets and assets:FindFirstChild("Trees") and assets.Trees:FindFirstChild("TreeOak")
	if not (src and src:IsA("BasePart")) then
		return
	end
	local b = src:Clone()
	local h = rng:NextNumber(6, 9)
	b.Size = Vector3.new(src.Size.X * h / src.Size.Y * 1.8, h, src.Size.Z * h / src.Size.Y * 1.8)
	b.Color = Color3.fromRGB(80, 136, 62):Lerp(Color3.fromRGB(110, 150, 60), rng:NextNumber() * 0.4)
	b.Material = Enum.Material.SmoothPlastic
	b.CFrame = CFrame.new(at + Vector3.new(0, h / 2 - 1.5, 0)) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0)
	b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, false, false, false, false
	b.Name = "Bush"
	b.Parent = into
end
-- OVERVIEW 0.97 (owner, 26 Nov 2026; docs/SPAWN_11.md; Config.SPAWN_11): 3D letters (one thick block per letter, its face
-- lettered, read from `facing`), marquee bulbs (tag "Chase", Client/GateMotion makes them run) and the themed room GATES
-- that replace the flat banners: each has 3D letters on the road side, its room's look, and something that MOVES
-- (tags Spin / Bob / Swing / Barrier / Countdown / Burst, animated on each screen only near it: Client/GateMotion).
local CollectionService = game:GetService("CollectionService")
local function letters(into: Instance, text: string, center: Vector3, facing: Vector3, h: number, edge: Color3, face: Color3, mat: Enum.Material?): number
	local f = Vector3.new(facing.X, 0, facing.Z).Unit
	local right = (-f):Cross(Vector3.yAxis).Unit -- (the reader's right, standing in front)
	local w = h * 0.74
	local step = w + h * 0.08
	local n = #text
	local start = center - right * (step * (n - 1) / 2)
	for i = 1, n do
		local c = string.sub(text, i, i)
		if c ~= " " then
			local p = start + right * (step * (i - 1))
			local b = part(into, "Letter3D", Vector3.new(w, h, h * 0.32), CFrame.lookAt(p, p + f), edge, mat or Enum.Material.SmoothPlastic, true)
			local g = Instance.new("SurfaceGui")
			g.Face = Enum.NormalId.Front
			g.CanvasSize = Vector2.new(100, 135)
			g.LightInfluence = 0.3
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, 1)
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.Text = c
			l.TextColor3 = face
			l.TextStrokeColor3 = Color3.new(0, 0, 0)
			l.TextStrokeTransparency = 0.2
			l.Parent = g
			g.Parent = b
		end
	end
	return step * n
end
local function tag(p: Instance, name: string, attrs: { [string]: any }?): Instance
	CollectionService:AddTag(p, name)
	for k, v in attrs or {} do
		p:SetAttribute(k, v)
	end
	return p
end
local function bulbs(into: Instance, a: Vector3, b: Vector3, n: number, color: Color3?)
	for i = 0, n - 1 do
		local p = a:Lerp(b, if n > 1 then i / (n - 1) else 0.5)
		local bulb = part(into, "Bulb", Vector3.new(0.55, 0.55, 0.55), CFrame.new(p), color or Color3.fromRGB(255, 214, 120), Enum.Material.Neon, true, Enum.PartType.Ball)
		bulb.CanCollide = false
		tag(bulb, "Chase", { Idx = i })
	end
end
local function emitter(at: BasePart, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = at
	return e
end
local GATE_THEME: { [string]: { post: Color3, mat: Enum.Material, edge: Color3, face: Color3 } } = {
	["Animal Cove"] = { post = Color3.fromRGB(120, 82, 50), mat = Enum.Material.WoodPlanks, edge = Color3.fromRGB(96, 62, 36), face = Color3.fromRGB(255, 236, 190) },
	["Splash Zone"] = { post = Color3.fromRGB(40, 140, 230), mat = Enum.Material.SmoothPlastic, edge = Color3.fromRGB(20, 90, 180), face = Color3.fromRGB(235, 250, 255) },
	["Crash Yard"] = { post = Color3.fromRGB(40, 40, 44), mat = Enum.Material.Rubber, edge = Color3.fromRGB(120, 124, 130), face = Color3.fromRGB(255, 200, 40) },
	["Car Park"] = { post = Color3.fromRGB(150, 154, 160), mat = Enum.Material.Metal, edge = Color3.fromRGB(30, 80, 180), face = Color3.new(1, 1, 1) },
	["Machine Hall"] = { post = Color3.fromRGB(70, 74, 82), mat = Enum.Material.DiamondPlate, edge = Color3.fromRGB(150, 154, 160), face = Color3.fromRGB(255, 170, 40) },
	["Fun Fair"] = { post = Color3.fromRGB(230, 50, 60), mat = Enum.Material.SmoothPlastic, edge = Color3.fromRGB(255, 200, 40), face = Color3.fromRGB(230, 40, 120) },
	["Launch Field"] = { post = Color3.fromRGB(220, 222, 226), mat = Enum.Material.Metal, edge = Color3.fromRGB(40, 60, 120), face = Color3.fromRGB(255, 255, 255) },
	["Danger Zone"] = { post = Color3.fromRGB(250, 200, 20), mat = Enum.Material.SmoothPlastic, edge = Color3.fromRGB(30, 30, 30), face = Color3.fromRGB(250, 200, 20) },
}
local function roomByName(name: string): (string?, any)
	for key, room in Plan.ROOMS do
		if room.name == name then
			return key, room
		end
	end
	return nil, nil
end
-- F39 (owner, 26 Nov 2026: "Skiltene ligner AI slop, og grenen splitter teksten"; Config.SIGNS_V2): every sign is a real
-- sign. Two posts at its SIDES (nothing ever crosses the text), a framed board with depth in its room's material and
-- colour (timber, riveted steel, hazard metal, enamel...), corner bolts, chunky lettering with a dark outline and the
-- room's pictogram, LightInfluence 0, readable on both faces (never mirrored).
local ROOM_ICON: { [string]: string } = {
	["Animal Cove"] = "🐾", ["Splash Zone"] = "🌊", ["Crash Yard"] = "💥", ["Car Park"] = "🅿️", ["Machine Hall"] = "⚙️",
	["Fun Fair"] = "🎈", ["Launch Field"] = "🚀", ["Danger Zone"] = "⚠️",
}
local function roomAt(at: Vector3): any
	local o = LabOwnerMap.origin
	if not o then
		return nil
	end
	local l = Vector2.new(at.X - o.X, at.Z - o.Z)
	for _, room in Plan.ROOMS do
		if l.X >= room.min.X - 20 and l.X <= room.max.X + 20 and l.Y >= room.min.Y - 20 and l.Y <= room.max.Y + 20 then
			return room
		end
	end
	return nil
end
local function signV2(into: Instance, at: Vector3, face: Vector3, text: string): boolean
	if not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SIGNS_V2 then
		return false
	end
	local room = roomAt(at)
	local th = room and GATE_THEME[room.name] or { post = Color3.fromRGB(90, 66, 44), mat = Enum.Material.WoodPlanks, edge = Color3.fromRGB(70, 110, 60), face = Color3.fromRGB(255, 248, 225) }
	local icon = room and ROOM_ICON[room.name] or ""
	local f = Vector3.new(face.X, 0, face.Z).Unit
	local right = f:Cross(Vector3.yAxis).Unit
	local W, H = math.clamp(#text * 0.9 + 3, 7, 13), 2.6
	local y = 6.2
	local center = at + Vector3.new(0, y, 0)
	-- two posts at the sides, clear of the text
	for _, s in { -1, 1 } do
		local p = at + right * (s * (W / 2 + 0.55))
		part(into, "SignPost", Vector3.new(0.6, y + H / 2 + 0.6, 0.6), CFrame.new(p + Vector3.new(0, (y + H / 2 + 0.6) / 2, 0)), th.post, th.mat, true)
		part(into, "SignCap", Vector3.new(0.85, 0.35, 0.85), CFrame.new(p + Vector3.new(0, y + H / 2 + 0.75, 0)), th.edge, Enum.Material.Metal, true)
	end
	-- the frame (a bigger plate behind) and the board
	local cf = CFrame.lookAt(center, center + f)
	part(into, "SignFrame", Vector3.new(W + 0.9, H + 0.8, 0.3), cf, -- (centred: its border shows on both faces)
		 th.post:Lerp(Color3.new(0, 0, 0), 0.35), th.mat, true)
	local board = part(into, "SignBoard", Vector3.new(W, H, 0.42), cf, th.edge, th.mat, true)
	-- corner bolts on the front
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			part(into, "SignBolt", Vector3.new(0.22, 0.22, 0.22), cf * CFrame.new(sx * (W / 2 - 0.3), sy * (H / 2 - 0.3), -0.23), Color3.fromRGB(200, 200, 196), Enum.Material.Metal, true, Enum.PartType.Ball)
		end
	end
	for _, nface in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Face = nface
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 40
		g.LightInfluence = 0
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, 0.52)
		l.Size = UDim2.fromScale(0.9, 0.78) -- (never touching the frame)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = th.face
		l.TextStrokeColor3 = Color3.fromRGB(20, 20, 24)
		l.TextStrokeTransparency = 0
		l.Text = if icon ~= "" then icon .. " " .. text else text
		l.Parent = g
		g.Parent = board
	end
	return true
end

local function prettyId(id: string): string
	return string.upper((string.gsub(id, "(%l)(%u)", "%1 %2")))
end
local function themedGate(into: Instance, at: Vector3, alongX: boolean, name: string)
	local th = GATE_THEME[name] or GATE_THEME["Machine Hall"]
	local key, room = roomByName(name)
	local half = Plan.GAP / 2
	local span = if alongX then Vector3.xAxis else Vector3.zAxis
	-- which way is the room (inside) and which way the road (outside)
	local inDir = Vector3.zAxis
	if room then
		local c = (room.min + room.max) / 2
		local o = Vector3.new(at.X - LabOwnerMap.origin.X, 0, at.Z - LabOwnerMap.origin.Z)
		local d = Vector3.new(c.X, 0, c.Y) - o
		inDir = if alongX then Vector3.new(0, 0, if d.Z >= 0 then 1 else -1) else Vector3.new(if d.X >= 0 then 1 else -1, 0, 0)
	end
	local out = -inDir
	local g = Instance.new("Model")
	g.Name = "Gate_" .. string.gsub(name, " ", "")
	g.Parent = into
	local H = 17
	-- posts and beam
	for _, s in { -1, 1 } do
		local base = at + span * (s * (half + 1.5))
		if name == "Crash Yard" then
			for k = 0, 6 do -- tyre stacks
				local tyre = part(g, "Tyre", Vector3.new(2.2, 4.4, 4.4), CFrame.new(base + Vector3.new(0, 1.1 + k * 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 30, 32), Enum.Material.Rubber, false, Enum.PartType.Cylinder)
				tyre.CFrame *= CFrame.Angles(math.rad((k % 2) * 8), 0, 0)
			end
		elseif name == "Fun Fair" or name == "Danger Zone" then
			for k = 0, 7 do -- striped posts
				local col = if k % 2 == 0 then th.post else (if name == "Fun Fair" then Color3.new(1, 1, 1) else Color3.fromRGB(30, 30, 30))
				part(g, "GatePost", Vector3.new(2.4, H / 8, 2.4), CFrame.new(base + Vector3.new(0, H / 16 + k * H / 8, 0)), col, th.mat)
			end
		else
			part(g, "GatePost", Vector3.new(2.6, H, 2.6), CFrame.new(base + Vector3.new(0, H / 2, 0)), th.post, th.mat)
		end
		part(g, "GateCap", Vector3.new(3.2, 0.8, 3.2), CFrame.new(base + Vector3.new(0, H + 0.4, 0)), th.edge, th.mat, true)
	end
	local beamCF = CFrame.lookAt(at + Vector3.new(0, H + 1.6, 0), at + Vector3.new(0, H + 1.6, 0) + out)
	part(g, "GateBeam", Vector3.new(Plan.GAP + 6, 2.4, 1.6), beamCF, th.edge, th.mat)
	-- 3D letters on the road side, a plate with the name on the room side
	local tw = letters(g, string.upper(name), at + Vector3.new(0, H + 5, 0) + out * 0.4, out, 3.2, th.edge, th.face, th.mat)
	local plate = part(g, "GatePlate", Vector3.new(Plan.GAP, 2, 0.4), CFrame.lookAt(at + Vector3.new(0, H + 1.6, 0) + inDir * 0.9, at + Vector3.new(0, H + 1.6, 0) + inDir * 2), th.edge, th.mat, true)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(520, 40)
	sg.LightInfluence = 0.3
	local sl = Instance.new("TextLabel")
	sl.BackgroundTransparency = 1
	sl.Size = UDim2.fromScale(1, 1)
	sl.Font = Enum.Font.FredokaOne
	sl.TextScaled = true
	sl.Text = string.upper(name)
	sl.TextColor3 = th.face
	sl.Parent = sg
	sg.Parent = plate
	-- bulbs under the beam, both sides
	bulbs(g, at + Vector3.new(0, H + 0.2, 0) + out * 1 - span * (half + 1), at + Vector3.new(0, H + 0.2, 0) + out * 1 + span * (half + 1), 12, th.face)
	local top = at + Vector3.new(0, H + 2.8, 0)
	-- the theme's moving part
	if name == "Animal Cove" then
		for _, s in { -1, 1 } do
			local p = at + span * (s * (half + 1.5))
			for k = 1, 3 do
				part(g, "Rope", Vector3.new(0.5, 3.2, 3.2), CFrame.new(p + Vector3.new(0, k * 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 170, 110), Enum.Material.Fabric, true, Enum.PartType.Cylinder)
			end
		end
		for k = -2, 2 do
			local v = part(g, "Vine", Vector3.new(0.3, 5, 0.3), CFrame.new(at + span * (k * 4.5) + Vector3.new(0, H - 2.2, 0) + out * 0.2), Color3.fromRGB(60, 130, 50), Enum.Material.Grass, true)
			v.CanCollide = false
			tag(v, "Swing", { Amp = 0.15, Speed = 1.3 + k * 0.1, Pivot = Vector3.new(0, 2.5, 0) })
		end
		-- the croc head on top: its lower jaw snaps open and shut
		local headAt = top + out * 0.5 + Vector3.new(0, 0.2, 0) - span * (tw / 2 + 3.5)
		part(g, "CrocHead", Vector3.new(3.2, 1.4, 5), CFrame.lookAt(headAt + Vector3.new(0, 1.2, 0), headAt + Vector3.new(0, 1.2, 0) + out), Color3.fromRGB(70, 130, 60), Enum.Material.SmoothPlastic, true)
		for _, s in { -1, 1 } do
			part(g, "CrocEye", Vector3.new(0.7, 0.7, 0.7), CFrame.new(headAt + Vector3.new(0, 2.1, 0) - out * 1.4 + span * (s * 0.9)), Color3.fromRGB(255, 230, 80), Enum.Material.Neon, true, Enum.PartType.Ball)
		end
		local jaw = part(g, "CrocJaw", Vector3.new(3, 0.6, 4.6), CFrame.lookAt(headAt + Vector3.new(0, 0.2, 0), headAt + Vector3.new(0, 0.2, 0) + out), Color3.fromRGB(90, 150, 70), Enum.Material.SmoothPlastic, true)
		tag(jaw, "Swing", { Amp = 0.35, Speed = 1.6, Pivot = Vector3.new(0, 0, 2.3), Snap = true })
		-- a bear head on the other side
		local bearAt = top + out * 0.5 + span * (tw / 2 + 3.5) + Vector3.new(0, 1.6, 0)
		part(g, "BearHead", Vector3.new(3.4, 3.4, 3.4), CFrame.new(bearAt), Color3.fromRGB(110, 72, 42), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		for _, s in { -1, 1 } do
			part(g, "BearEar", Vector3.new(1.2, 1.2, 1.2), CFrame.new(bearAt + Vector3.new(0, 1.6, 0) + span * (s * 1.3)), Color3.fromRGB(110, 72, 42), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		end
		part(g, "BearSnout", Vector3.new(1.4, 1.1, 1.4), CFrame.new(bearAt + out * 1.6 - Vector3.new(0, 0.4, 0)), Color3.fromRGB(200, 160, 120), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
	elseif name == "Splash Zone" then
		-- a wave on top and water jets arcing over the way in from both posts
		for k = -3, 3 do
			local y = math.cos(k / 3 * math.pi / 2) * 3
			local wv = part(g, "Wave", Vector3.new(4.2, 1.2, 1.4), CFrame.new(top + span * (k * 4) + Vector3.new(0, y, 0) - out * 0.8) * CFrame.fromAxisAngle(out, -k * 0.18), Color3.fromRGB(110, 200, 250), Enum.Material.Glass, true)
			wv.Transparency = 0.2
		end
		for _, s in { -1, 1 } do
			local nozzle = part(g, "JetNozzle", Vector3.new(1, 1, 1), CFrame.lookAt(at + span * (s * (half + 1.5)) + Vector3.new(0, H + 1, 0), at + Vector3.new(0, H + 9, 0)), Color3.fromRGB(200, 205, 210), Enum.Material.Metal, true)
			emitter(nozzle, { Rate = 45, Speed = NumberRange.new(20, 23), Lifetime = NumberRange.new(1.3, 1.5), Acceleration = Vector3.new(0, -32, 0), EmissionDirection = Enum.NormalId.Front,
				Size = NumberSequence.new(0.45, 0.15), Color = ColorSequence.new(Color3.fromRGB(170, 225, 255)), Transparency = NumberSequence.new(0.2, 0.8), SpreadAngle = Vector2.new(3, 3), LightEmission = 0.2 })
			local buoy = part(g, "Lifebuoy", Vector3.new(0.5, 3, 3), CFrame.new(at + span * (s * (half + 1.5)) + Vector3.new(0, 9, 0) + out * 1.4) * CFrame.Angles(0, if alongX then math.rad(90) else 0, 0), Color3.fromRGB(230, 50, 50), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
			part(g, "LifebuoyHole", Vector3.new(0.56, 1.5, 1.5), buoy.CFrame, th.post, Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
		end
	elseif name == "Crash Yard" then
		-- two crashed cars on the beam, hazard stripes and amber beacons
		for _, s in { -1, 1 } do
			local carAt = top + span * (s * 5.5) + Vector3.new(0, 1.2, 0)
			local car = part(g, "WreckCar", Vector3.new(8, 2.6, 4.4), CFrame.new(carAt) * CFrame.fromAxisAngle(out, s * 0.22) * CFrame.Angles(0, if alongX then 0 else math.rad(90), 0), if s < 0 then Color3.fromRGB(200, 50, 40) else Color3.fromRGB(40, 90, 200), Enum.Material.Metal)
			part(g, "WreckCab", Vector3.new(4, 1.6, 4), car.CFrame * CFrame.new(-0.5, 2, 0) * CFrame.Angles(0, 0, 0.12), Color3.fromRGB(40, 44, 52), Enum.Material.Glass, true)
			local beacon = part(g, "Beacon", Vector3.new(0.8, 1.2, 1.2), CFrame.new(at + span * (s * (half + 1.5)) + Vector3.new(0, H + 1.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 160, 20), Enum.Material.Neon, true, Enum.PartType.Cylinder)
			local lamp = part(g, "BeaconLamp", Vector3.new(0.3, 1, 1.6), beacon.CFrame * CFrame.new(0, 0, 0.5), Color3.fromRGB(255, 220, 120), Enum.Material.Neon, true)
			lamp.CanCollide = false
			tag(lamp, "Spin", { Speed = 5, Around = beacon.Position })
		end
		for k = -5, 5 do
			part(g, "HazardStripe", Vector3.new(1, 2.5, 0.1), beamCF * CFrame.new(k * 2.6, 0, -0.85) * CFrame.Angles(0, 0, math.rad(40)), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic, true)
		end
	elseif name == "Car Park" then
		-- a striped barrier arm that lifts when you walk through
		local pivot = at - span * half + Vector3.new(0, 3.6, 0) + out * 1.6
		local arm = part(g, "BarrierArm", Vector3.new(Plan.GAP - 1, 0.7, 0.7), CFrame.lookAt(pivot + span * ((Plan.GAP - 1) / 2), pivot + span * ((Plan.GAP - 1) / 2) + out), Color3.fromRGB(230, 40, 40), Enum.Material.SmoothPlastic, true)
		arm.CanCollide = false
		tag(arm, "Barrier", { Pivot = Vector3.new(((Plan.GAP - 1) / 2) * (if (span:Cross(out)).Y > 0 then 1 else -1), 0, 0) })
		part(g, "BarrierBox", Vector3.new(1.6, 4, 1.6), CFrame.new(at - span * half + Vector3.new(0, 2, 0) + out * 1.6), Color3.fromRGB(250, 200, 20), Enum.Material.Metal)
		local pSign = part(g, "ParkingP", Vector3.new(3.4, 3.4, 0.5), CFrame.lookAt(top + Vector3.new(0, 1.6, 0) + out * 0.4 + span * (tw / 2 + 2.8), top + Vector3.new(0, 1.6, 0) + out * 2 + span * (tw / 2 + 2.8)), Color3.fromRGB(30, 80, 180), Enum.Material.SmoothPlastic, true)
		local pg = Instance.new("SurfaceGui")
		pg.Face = Enum.NormalId.Front
		pg.CanvasSize = Vector2.new(100, 100)
		local pl = Instance.new("TextLabel")
		pl.BackgroundTransparency = 1
		pl.Size = UDim2.fromScale(1, 1)
		pl.Font = Enum.Font.GothamBlack
		pl.TextScaled = true
		pl.Text = "P"
		pl.TextColor3 = Color3.new(1, 1, 1)
		pl.Parent = pg
		pg.Parent = pSign
	elseif name == "Machine Hall" then
		-- two big turning gears and a piston pumping, a steam puff now and then
		for _, s in { -1, 1 } do
			local gear = Instance.new("Model")
			gear.Name = "Gear"
			gear.Parent = g
			local c = top + span * (s * (tw / 2 + 3.2)) + Vector3.new(0, 1.4, 0) + out * 0.6
			local hub = part(gear, "GearHub", Vector3.new(1, 5, 5), CFrame.lookAt(c, c + out) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(160, 164, 172), Enum.Material.Metal, true, Enum.PartType.Cylinder)
			for t = 0, 7 do
				local a = t / 8 * math.pi * 2
				part(gear, "GearTooth", Vector3.new(1, 1.1, 1.1), CFrame.lookAt(c, c + out) * CFrame.Angles(0, 0, a) * CFrame.new(0, 2.8, 0), Color3.fromRGB(160, 164, 172), Enum.Material.Metal, true)
			end
			gear.PrimaryPart = hub
			tag(gear, "Spin", { Speed = s * 0.9, Axis = out })
		end
		local piston = part(g, "Piston", Vector3.new(1.2, 3, 1.2), CFrame.new(at + span * (half + 1.5) + Vector3.new(0, H + 2.6, 0)), Color3.fromRGB(200, 204, 210), Enum.Material.Metal, true, Enum.PartType.Cylinder)
		piston.CFrame *= CFrame.Angles(0, 0, math.rad(90))
		tag(piston, "Bob", { Amp = 0.9, Speed = 4 })
		local steam = part(g, "SteamVent", Vector3.new(0.6, 0.6, 0.6), CFrame.new(at - span * (half + 1.5) + Vector3.new(0, H + 1.2, 0)), Color3.fromRGB(90, 94, 100), Enum.Material.Metal, true)
		emitter(steam, { Rate = 0, Speed = NumberRange.new(4, 7), Lifetime = NumberRange.new(1.2, 1.8), Size = NumberSequence.new(1.2, 3.5), Transparency = NumberSequence.new(0.3, 1), Color = ColorSequence.new(Color3.fromRGB(240, 240, 240)), EmissionDirection = Enum.NormalId.Top })
		tag(steam, "Burst", { Every = 6, Count = 14 })
	elseif name == "Fun Fair" then
		-- balloons bobbing over the beam, bulbs up the posts
		local cols = { Color3.fromRGB(240, 60, 80), Color3.fromRGB(60, 170, 240), Color3.fromRGB(255, 210, 50), Color3.fromRGB(120, 210, 90), Color3.fromRGB(200, 100, 240) }
		for k = 1, 5 do
			local b = part(g, "Balloon", Vector3.new(2, 2.4, 2), CFrame.new(top + span * ((k - 3) * 5) + Vector3.new(0, 6 + (k % 2), 0) - out * 0.6), cols[k], Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
			b.CanCollide = false
			tag(b, "Bob", { Amp = 0.6, Speed = 1.2 + k * 0.15 })
		end
		for _, s in { -1, 1 } do
			local p = at + span * (s * (half + 1.5)) + out * 1.4
			bulbs(g, p + Vector3.new(0, 1.5, 0), p + Vector3.new(0, H - 0.5, 0), 8)
		end
	elseif name == "Launch Field" then
		-- a rocket nose cone on top and a countdown that "launches" a smoke puff
		local cone = top + Vector3.new(0, 2.5, 0) - span * (tw / 2 + 3)
		part(g, "RocketBody", Vector3.new(5, 3.4, 3.4), CFrame.new(cone) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(245, 245, 248), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
		part(g, "RocketNose", Vector3.new(3.4, 3.4, 3.4), CFrame.new(cone + Vector3.new(0, 2.5, 0)), Color3.fromRGB(230, 50, 50), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		local display = part(g, "Countdown", Vector3.new(4, 2.6, 0.5), CFrame.lookAt(top + Vector3.new(0, 1.3, 0) + out * 0.5 + span * (tw / 2 + 3), top + Vector3.new(0, 1.3, 0) + out * 3 + span * (tw / 2 + 3)), Color3.fromRGB(20, 22, 26), Enum.Material.SmoothPlastic, true)
		local dg = Instance.new("SurfaceGui")
		dg.Face = Enum.NormalId.Front
		dg.CanvasSize = Vector2.new(120, 80)
		dg.LightInfluence = 0
		local dl = Instance.new("TextLabel")
		dl.Name = "Digits"
		dl.BackgroundTransparency = 1
		dl.Size = UDim2.fromScale(1, 1)
		dl.Font = Enum.Font.Code
		dl.TextScaled = true
		dl.Text = "10"
		dl.TextColor3 = Color3.fromRGB(255, 80, 60)
		dl.Parent = dg
		dg.Parent = display
		local puff = part(g, "LaunchPuff", Vector3.new(0.5, 0.5, 0.5), CFrame.new(cone - Vector3.new(0, 2, 0)), Color3.fromRGB(120, 120, 120), Enum.Material.SmoothPlastic, true)
		puff.Transparency = 1
		emitter(puff, { Rate = 0, Speed = NumberRange.new(5, 10), Lifetime = NumberRange.new(1.5, 2.2), Size = NumberSequence.new(2, 5), Transparency = NumberSequence.new(0.2, 1), Color = ColorSequence.new(Color3.fromRGB(235, 235, 235)), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Bottom })
		tag(display, "Countdown", { From = 10, Every = 30 })
	elseif name == "Danger Zone" then
		-- spinning warning lights and cartoon flame bursts every 10 s
		for _, s in { -1, 1 } do
			local p = at + span * (s * (half + 1.5)) + Vector3.new(0, H + 1.6, 0)
			local base = part(g, "WarnLight", Vector3.new(0.8, 1.2, 1.2), CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 50, 30), Enum.Material.Neon, true, Enum.PartType.Cylinder)
			local lamp = part(g, "WarnLamp", Vector3.new(0.3, 1, 1.6), base.CFrame * CFrame.new(0, 0, 0.5), Color3.fromRGB(255, 120, 90), Enum.Material.Neon, true)
			lamp.CanCollide = false
			tag(lamp, "Spin", { Speed = 6, Around = base.Position })
			local jet = part(g, "FlameJet", Vector3.new(0.8, 0.8, 0.8), CFrame.new(p + Vector3.new(0, 1.2, 0) + out * 0.2), Color3.fromRGB(60, 60, 60), Enum.Material.Metal, true)
			emitter(jet, { Rate = 0, Speed = NumberRange.new(10, 14), Lifetime = NumberRange.new(0.5, 0.8), Size = NumberSequence.new(1.6, 0.2), LightEmission = 0.8,
				Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 80, 20)), Transparency = NumberSequence.new(0, 1), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(10, 10) })
			tag(jet, "Burst", { Every = 10, Count = 40 })
		end
	end
	-- inside the gate: a board listing what is in the room
	if key then
		local names = {}
		for id, item in Plan.ITEMS do
			if item.zone == key and #names < 6 then
				table.insert(names, prettyId(id))
			end
		end
		table.sort(names)
		if #names > 0 then
			local bAt = at + inDir * 7 + span * (half + 4) + Vector3.new(0, 0, 0)
			part(g, "ListPost", Vector3.new(0.5, 6, 0.5), CFrame.new(bAt + Vector3.new(0, 3, 0)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal, true)
			local board = part(g, "ListBoard", Vector3.new(6, 5, 0.3), CFrame.lookAt(bAt + Vector3.new(0, 6.5, 0), bAt + Vector3.new(0, 6.5, 0) + out), th.edge, Enum.Material.SmoothPlastic, true)
			local lg = Instance.new("SurfaceGui")
			lg.Face = Enum.NormalId.Front
			lg.CanvasSize = Vector2.new(240, 200)
			lg.LightInfluence = 0.3
			local ll = Instance.new("TextLabel")
			ll.BackgroundTransparency = 1
			ll.Size = UDim2.fromScale(1, 1)
			ll.Font = Enum.Font.FredokaOne
			ll.TextScaled = true
			ll.TextColor3 = th.face
			ll.Text = "IN HERE:\n" .. table.concat(names, "\n")
			ll.Parent = lg
			lg.Parent = board
		end
	end
end

local function arch(into: Instance, at: Vector3, alongX: boolean, name: string)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ROOM_GATES and GATE_THEME[name] then
		themedGate(into, at, alongX, name) -- (OVERVIEW 0.97: a themed gate, not a flat banner)
		return
	end
	local half = Plan.GAP / 2
	local dir = if alongX then Vector3.xAxis else Vector3.zAxis
	for _, s in { -1, 1 } do
		part(into, "ArchPost", Vector3.new(1.4, 16, 1.4), CFrame.new(at + dir * (s * half) + Vector3.new(0, 8, 0)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)
	end
	local beam = part(into, "ArchSign", if alongX then Vector3.new(Plan.GAP + 2, 4, 0.8) else Vector3.new(0.8, 4, Plan.GAP + 2), CFrame.new(at + Vector3.new(0, 16, 0)), Color3.fromRGB(40, 44, 52), Enum.Material.SmoothPlastic)
	for _, face in (if alongX then { Enum.NormalId.Front, Enum.NormalId.Back } else { Enum.NormalId.Left, Enum.NormalId.Right }) do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.CanvasSize = Vector2.new(400, 60)
		g.LightInfluence = 0
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.fromRGB(255, 214, 90)
		l.Text = string.upper(name)
		l.Parent = g
		g.Parent = beam
	end
end
local function belts(into: Instance, o: Vector3, top: number)
	local rng = Random.new(11)
	local kinds = { "TreeOak", "TreeFir", "TreePoplar", "TreeOak" }
	for _, room in Plan.ROOMS do
		if room.walled then
			local mn, mx = room.min, room.max
			local function open(p: Vector2): boolean
				for _, e in room.entrances do
					if (p - e).Magnitude < Plan.GAP / 2 + 5 then
						return false
					end
				end
				return true
			end
			-- the four edges, walked at three depths: trees at 5 and 13 in from the edge, bushes at 9
			for _, row in { { d = 5, step = 14, tree = true, off = 0 }, { d = 13, step = 14, tree = true, off = 7 }, { d = 9, step = 12, tree = false, off = 3 } } do
				local a = Vector2.new(mn.X + row.d, mn.Y + row.d)
				local b = Vector2.new(mx.X - row.d, mx.Y - row.d)
				local corners = { a, Vector2.new(b.X, a.Y), b, Vector2.new(a.X, b.Y) }
				for i = 1, 4 do
					local p0, p1 = corners[i], corners[i % 4 + 1]
					local len = (p1 - p0).Magnitude
					local dir = (p1 - p0).Unit
					for s = row.off, len - 1, row.step do
						local p = p0 + dir * s
						-- (the opening is measured on the room's own edge)
						local edgeP = if i == 1 then Vector2.new(p.X, mn.Y) elseif i == 2 then Vector2.new(mx.X, p.Y) elseif i == 3 then Vector2.new(p.X, mx.Y) else Vector2.new(mn.X, p.Y)
						if open(edgeP) then
							local w = Vector3.new(o.X + p.X + rng:NextNumber(-2, 2), top, o.Z + p.Y + rng:NextNumber(-2, 2))
							if row.tree then
								plantTree(into, kinds[rng:NextInteger(1, #kinds)], w, rng:NextNumber(20, 32), rng, row.d > 6)
							else
								bush(into, w, rng)
							end
						end
					end
				end
			end
			for _, e in room.entrances do
				local alongX = math.abs(e.Y - mn.Y) < 1 or math.abs(e.Y - mx.Y) < 1
				arch(into, Vector3.new(o.X + e.X, top, o.Z + e.Y), alongX, room.name or "")
			end
		end
	end
end

-- MAP ROUND 3, P4b: the open areas and the BACKDROP (docs/MAP_MASTERPLAN.md "Open, framed areas", rule 5; OVERVIEW 1).
--   * The Spawn Gardens, the Lawns and the Picnic Park: low hedges along their road sides (gaps where paths cross),
--     flower beds, a few trees, benches; trees along both sides of the boulevard.
--   * The Picnic Park pieces of the plan: the duck pond with ducks, the gazebo in its flower garden, the dog yard fence.
--   * The backdrop: a forest belt round the whole lab outside the railway (on a wider grass rim), the hills further out
--     and a ring of high mountains far away (Terrain), so the world does not end at the edge.
local FLOWER = { Color3.fromRGB(230, 70, 90), Color3.fromRGB(250, 200, 60), Color3.fromRGB(150, 90, 220), Color3.fromRGB(250, 250, 250), Color3.fromRGB(255, 140, 60) }
local function hedge(into: Instance, a: Vector3, b: Vector3)
	local len = (b - a).Magnitude
	if len < 4 then
		return
	end
	local h = part(into, "Hedge", Vector3.new(3, 3.4, len), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 1.7, 0), b + Vector3.new(0, 1.7, 0)), Color3.fromRGB(70, 120, 56), Enum.Material.Grass)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).FOLIAGE_PASS then
		h.CanCollide = false -- (F54: you run through hedges)
	end
	h.CastShadow = false
end
local function flowerBed(into: Instance, at: Vector3, w: number, d: number, rng: Random)
	if onPath(at, math.max(w, d) / 2 + 1) then
		return -- (rule 3: never on a path)
	end
	part(into, "FlowerBedSoil", Vector3.new(w, 0.66, d), CFrame.new(at + Vector3.new(0, 0.35, 0)), Color3.fromRGB(96, 70, 50), Enum.Material.Ground, true)
	part(into, "FlowerBedEdge", Vector3.new(w + 1, 0.8, d + 1), CFrame.new(at + Vector3.new(0, 0.2, 0)), Color3.fromRGB(190, 190, 186), Enum.Material.Concrete, true)
	for k = 1, math.floor(w * d / 18) do
		local p = at + Vector3.new(rng:NextNumber(-w / 2 + 1, w / 2 - 1), 1, rng:NextNumber(-d / 2 + 1, d / 2 - 1))
		-- (1e: no more balls as flowers: a small flowering bush from the tree set, in a flower colour)
		if k % 2 == 1 and yTree(into, "Bush", p - Vector3.new(0, 0.4, 0), rng:NextNumber(1.8, 2.8), rng, FLOWER[rng:NextInteger(1, #FLOWER)]) then
			continue
		elseif k % 2 == 0 and (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).TREES_V2 then
			continue -- (half as many: a bush is bigger than a ball)
		end
		part(into, "Flower", Vector3.new(1.4, 1.2, 1.4), CFrame.new(p), FLOWER[rng:NextInteger(1, #FLOWER)], Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		local _ = k
	end
end
local function parks(into: Instance, o: Vector3, top: number)
	local rng = Random.new(23)
	local function w(x: number, z: number): Vector3
		return Vector3.new(o.X + x, top, o.Z + z)
	end
	-- (M4: the compact map has no boulevard trees and no garden rooms: only the duck pond, the dog yard and the backdrop
	-- below are built there)
	local bigMap = LabOwnerMap.S > 2
	-- Boulevard trees, both sides, outside the lamps.
	for z = (if bigMap then -262 else 1), (if bigMap then -78 else 0), 26 do
		for _, sx in { -1, 1 } do
			plantTree(into, if (z // 26) % 2 == 0 then "TreePoplar" else "TreeOak", w(-30 + sx * 30, z), rng:NextNumber(20, 26), rng, false)
		end
	end
	-- The open areas: hedges along their road sides, flower beds, trees, benches.
	for _, id in { "GardensN", "LawnsMid", "PicnicPark" } do
		local room = Plan.ROOMS[id]
		if not room then
			continue -- (M4: no such room in the compact plan)
		end
		local mn, mx = room.min, room.max
		-- hedges along the west and east sides (the long roads), leaving gaps for the side paths
		for _, x in { mn.X + 4, mx.X - 4 } do
			hedge(into, w(x, mn.Y + 6), w(x, mn.Y + (mx.Y - mn.Y) * 0.45))
			hedge(into, w(x, mn.Y + (mx.Y - mn.Y) * 0.55), w(x, mx.Y - 6))
		end
		-- flower beds in a row on each side of the middle road, trees between
		local cx = (mn.X + mx.X) / 2
		for z = mn.Y + 20, mx.Y - 20, 40 do
			for _, sx in { -1, 1 } do
				local x = cx + sx * 60
				flowerBed(into, w(x, z), 16, 10, rng)
				plantTree(into, if rng:NextNumber() < 0.5 then "TreeOak" else "TreePoplar", w(x + sx * 22, z + 12), rng:NextNumber(18, 26), rng, false)
				-- a bench facing the road
				if not onPath(w(x - sx * 14, z), 4) then
					part(into, "BenchSeat", Vector3.new(7, 0.5, 2), CFrame.new(w(x - sx * 14, z) + Vector3.new(0, 1.6, 0)), Color3.fromRGB(140, 100, 64), Enum.Material.WoodPlanks)
				end
			end
		end
	end
	-- Flower beds along the front of the spawn plaza.
	for _, sx in (if bigMap then { -1, 1 } else {}) do
		flowerBed(into, w(-30 + sx * 50, -274), 30, 6, rng)
	end
	-- THE DUCK POND (Picnic Park).
	local dp = planAt(o, top, "DuckPond")
	local water = part(into, "DuckPondWater", Vector3.new(0.4, 11, 11), CFrame.new(dp + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 150, 190), Enum.Material.Glass, false, Enum.PartType.Cylinder)
	water.Transparency = 0.15
	part(into, "DuckPondRim", Vector3.new(0.6, 12.5, 12.5), CFrame.new(dp + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 140, 120), Enum.Material.Cobblestone, true, Enum.PartType.Cylinder)
	for k = 1, 4 do
		local a = k * 1.6
		local p = dp + Vector3.new(math.cos(a) * 10, 0.8, math.sin(a) * 10)
		part(into, "DuckBody", Vector3.new(1.6, 1.1, 2.4), CFrame.new(p) * CFrame.Angles(0, a, 0), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		part(into, "DuckHead", Vector3.new(0.9, 0.9, 0.9), CFrame.new(p) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.8, -1), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		part(into, "DuckBeak", Vector3.new(0.4, 0.3, 0.5), CFrame.new(p) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.75, -1.6), Color3.fromRGB(255, 160, 40), Enum.Material.SmoothPlastic, true)
	end
	-- THE GAZEBO in its flower garden.
	local gz = planAt(o, top, "Gazebo")
	if inPlan("Gazebo") then -- (M4: gone from the compact plan)
	part(into, "GazeboFloor", Vector3.new(1, 20, 20), CFrame.new(gz + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(230, 226, 216), Enum.Material.WoodPlanks, false, Enum.PartType.Cylinder)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		part(into, "GazeboPost", Vector3.new(0.8, 10, 0.8), CFrame.new(gz + Vector3.new(math.cos(a) * 8.5, 5.5, math.sin(a) * 8.5)), Color3.fromRGB(245, 245, 240), Enum.Material.Wood)
	end
	part(into, "GazeboRoof", Vector3.new(22, 5, 22), CFrame.new(gz + Vector3.new(0, 12.5, 0)), Color3.fromRGB(180, 70, 60), Enum.Material.Slate, false, Enum.PartType.Ball)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.5
		flowerBed(into, gz + Vector3.new(math.cos(a) * 17, 0, math.sin(a) * 17), 6, 6, rng)
	end
	end
	-- THE DOG YARD fence round the doghouse.
	local dy = planAt(o, top, "DogYard")
	local half = 9 -- (M4: the plan's 18 x 18)
	local corners = { Vector3.new(-half, 0, -half), Vector3.new(half, 0, -half), Vector3.new(half, 0, half), Vector3.new(-half, 0, half) }
	for i = 1, 4 do
		local a, b = dy + corners[i], dy + corners[i % 4 + 1]
		if i ~= 4 then -- (the west side stays open: the yard faces the road)
			part(into, "DogFence", Vector3.new(0.4, 3, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 1.5, 0), b + Vector3.new(0, 1.5, 0)), Color3.fromRGB(240, 236, 226), Enum.Material.Wood)
		end
	end
	part(into, "DogYardGrass", Vector3.new(18, 0.2, 18), CFrame.new(dy + Vector3.new(0, 0.1, 0)), Color3.fromRGB(100, 160, 80), Enum.Material.Grass, true)
	-- THE BACKDROP: a wider grass rim and a forest belt outside the railway, all the way round.
	local c = LabOwnerMap.CENTER
	local size = LabOwnerMap.SIZE
	local rim = 140
	part(into, "OwnerRim", Vector3.new(size.X + rim * 2, 2, size.Y + rim * 2), CFrame.new(o.X + c.X, top - 1.05, o.Z + c.Y), Color3.fromRGB(104, 150, 76), Enum.Material.Grass)
	local x0, x1 = c.X - size.X / 2 - 14, c.X + size.X / 2 + 14
	local z0, z1 = c.Y - size.Y / 2 - 14, c.Y + size.Y / 2 + 14
	for row = 0, 2 do
		local d = row * 22
		local edges = {
			{ Vector2.new(x0 - d, z0 - d), Vector2.new(x1 + d, z0 - d) }, { Vector2.new(x1 + d, z0 - d), Vector2.new(x1 + d, z1 + d) },
			{ Vector2.new(x1 + d, z1 + d), Vector2.new(x0 - d, z1 + d) }, { Vector2.new(x0 - d, z1 + d), Vector2.new(x0 - d, z0 - d) },
		}
		for _, e in edges do
			local len = (e[2] - e[1]).Magnitude
			local dir = (e[2] - e[1]).Unit
			for s = (row % 2) * 13, len, 26 do
				local p = e[1] + dir * s
				plantTree(into, if rng:NextNumber() < 0.6 then "TreeFir" else "TreeOak", Vector3.new(o.X + p.X + rng:NextNumber(-4, 4), top, o.Z + p.Y + rng:NextNumber(-4, 4)), rng:NextNumber(26, 40), rng, true)
			end
		end
	end
	-- The far mountains (Terrain rock with grass skirts).
	local terrain = Workspace.Terrain
	local mid = Vector3.new(o.X + c.X, top, o.Z + c.Y)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local at = mid + Vector3.new(math.cos(a) * (size.X / 2 + (if bigMap then 650 else 300)), (if bigMap then 40 else -10) + (i % 3) * 30, math.sin(a) * (size.Y / 2 + (if bigMap then 650 else 300)))
		pcall(function()
			-- (M4: the references show smooth rolling GREEN hills on the horizon, not rock mountains)
			terrain:FillBall(at, (if bigMap then 210 else 150) + (i % 4) * 40, if bigMap then Enum.Material.Rock else Enum.Material.Grass)
			terrain:FillBall(at - Vector3.new(0, 90, 0), 260, Enum.Material.Grass)
		end)
	end
end

-- MAP ROUND 3, P5: the yard of every attraction (docs/MAP_MASTERPLAN.md rule 6): where its inner path ends, 2 lamps
-- either side of the path end, a bench a little to the side facing the thing, a sign with its name on a post, and a
-- small cluster of fitting props (crates, cones or barrels). Every courtyard gets a bench, a bin, a lamp and a signpost
-- with an arm toward each attraction of the room.
local NAMES: { [string]: string } = {
	CaveBear = "BEAR CAVE", Aquarium = "AQUARIUM", CrocPond = "CROC POND", TRexPen = "T-REX", BigPool = "BIG POOL", LoungePool = "LOUNGE POOL",
	SpiderPen = "SPIDER", SnackKiosk = "SNACKS", CarBays = "CAR BAYS", BrickWall = "CRASH WALL", LaunchPads = "LAUNCH PADS", BoxingRing = "BOXING",
	WreckingBall = "WRECKING BALL", CarPark = "CAR PARK", Garage = "GARAGE", TrainingYard = "TRAINING", BikeRack = "BIKES", GiantFan = "GIANT FAN",
	TeslaCoil = "TESLA COIL", GyroCage = "GYRO CAGE", Press = "THE PRESS", StretchMachine = "STRETCHER", Washer = "WASHER", Sandcastle = "SANDCASTLE",
	Playground = "PLAYGROUND", Archery = "ARCHERY", Sandbox = "SANDBOX", Seesaw = "SEESAW", Mole = "THE MOLE", SandCircle = "SAND CIRCLE",
	Cannon = "CANNON", LandingField = "LANDING FIELD", Rocket = "ROCKET", LavaStrip = "LAVA", Shredder = "SHREDDER", Sweeper = "SWEEPER",
}
local function nameSign(into: Instance, at: Vector3, face: Vector3, text: string)
	if signV2(into, at, face, text) then
		return -- (F39: a real sign)
	end
	part(into, "SignPost", Vector3.new(0.5, 7, 0.5), CFrame.new(at + Vector3.new(0, 3.5, 0)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal, true)
	local board = part(into, "SignBoard", Vector3.new(7, 2, 0.3), CFrame.lookAt(at + Vector3.new(0, 7, 0), at + Vector3.new(0, 7, 0) + face), Color3.fromRGB(40, 44, 52), Enum.Material.SmoothPlastic, true)
	for _, f in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Face = f
		g.CanvasSize = Vector2.new(280, 80)
		g.LightInfluence = 0
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.Text = text
		l.Parent = g
		g.Parent = board
	end
end
-- F44 (owner's screenshot: a bench stuck in the boxing ring; Config.PROP_CLEAR): a yard prop only goes where nothing stands
-- within 3 studs of it (any part that is not flat ground; the ragdolls ignored). The first of the given spots that is
-- free wins; none free: no prop.
local function freeSpot(spots: { Vector3 }, size: Vector3, top: number): Vector3?
	if not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).PROP_CLEAR then
		return spots[1]
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {}
	for _, n in { "Dummies", "Terrain" } do
		local x = Workspace:FindFirstChild(n)
		if x then
			table.insert(ex, x)
		end
	end
	params.FilterDescendantsInstances = ex
	for _, at in spots do
		if not onPath(at, 2) then
			local hits = Workspace:GetPartBoundsInBox(CFrame.new(at + Vector3.new(0, size.Y / 2 + 0.6, 0)), size + Vector3.new(6, 0, 6), params)
			local blocked = false
			for _, h in hits do
				local flat = h.Size.Y < 1.3 and h.Position.Y - h.Size.Y / 2 < top + 0.9 and math.abs(h.CFrame.UpVector.Y) > 0.95
				if not flat and h.Transparency < 1 then
					blocked = true
					break
				end
			end
			if not blocked then
				return at
			end
		end
	end
	return nil
end

local function yards(into: Instance, o: Vector3, top: number)
	local rng = Random.new(31)
	local function w(v: Vector2): Vector3
		return Vector3.new(o.X + v.X, top, o.Z + v.Y)
	end
	local done: { [string]: boolean } = {}
	for _, path in Plan.INNER do
		local id = path.to
		if id ~= "entrance" and not done[id] and #path.points >= 2 then
			done[id] = true
			local n = #path.points
			local last, prev = path.points[n], path.points[n - 1]
			local k = n - 1
			while k > 1 and (last - prev).Magnitude < 4 do
				k -= 1
				prev = path.points[k]
			end
			local dir = if (last - prev).Magnitude > 0.1 then (last - prev).Unit else Vector2.new(0, 1)
			local side = Vector2.new(-dir.Y, dir.X)
			local endP = last - dir * 4
			-- 2 lamps either side of the path end
			for _, s in { -1, 1 } do
				lamp(into, w(endP + side * s * (Plan.INNER_W / 2 + 2.5)))
			end
			-- the name sign on the right, facing back along the path
			local back3, side3 = Vector3.new(-dir.X, 0, -dir.Y), Vector3.new(side.X, 0, side.Y)
			local signAt = w(endP + side * (Plan.INNER_W / 2 + 6) - dir * 6)
			signAt = freeSpot({ signAt, signAt + back3 * 5, signAt + side3 * 4, signAt + back3 * 10, signAt + side3 * 4 + back3 * 5 }, Vector3.new(10, 8, 2), top) :: any
			if signAt and not onPath(signAt, 0.5) then
				nameSign(into, signAt, Vector3.new(-dir.X, 0, -dir.Y), NAMES[id] or string.upper(id))
			end
			-- a bench on the left, facing the attraction
			local benchAt = w(endP - side * (Plan.INNER_W / 2 + 6) - dir * 8)
			benchAt = freeSpot({ benchAt, benchAt + back3 * 5, benchAt - side3 * 4, benchAt + back3 * 10, benchAt - side3 * 4 + back3 * 5, benchAt + back3 * 15 }, Vector3.new(7, 3, 3), top) :: any
			if benchAt and not onPath(benchAt, 2) then
				benchModel(into, CFrame.lookAt(benchAt, benchAt + Vector3.new(dir.X, 0, dir.Y)))
				binModel(into, benchAt + CFrame.lookAt(benchAt, benchAt + Vector3.new(dir.X, 0, dir.Y)).RightVector * 4.4) -- (a bin by every bench)
			end
			-- a small cluster of props behind the sign
			local propAt = endP + side * (Plan.INNER_W / 2 + 12) - dir * 12
			for q = 1, 3 do
				local p0 = w(propAt + Vector2.new(rng:NextNumber(-3, 3), rng:NextNumber(-3, 3)))
				local p = freeSpot({ p0, p0 + back3 * 4, p0 + Vector3.new(side.X, 0, side.Y) * 4 }, Vector3.new(3, 3, 3), top) :: any
				if p and not onPath(p, 2) then
					if q == 1 then
						crateModel(into, CFrame.new(p + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, rng:NextNumber() * 6, 0), 3)
					elseif q == 2 then
						part(into, "YardCone", Vector3.new(1.4, 2.4, 1.4), CFrame.new(p + Vector3.new(0, 1.2, 0)), Color3.fromRGB(255, 120, 40), Enum.Material.Plastic, true)
					else
						barrelModel(into, p, rng:NextNumber() * 6, false)
					end
				end
			end
		end
	end
	-- the courtyards: a bench, a bin, a lamp and a signpost
	for _, room in Plan.ROOMS do
		if room.courtyard then
			local c = room.courtyard
			lamp(into, w(c + Vector2.new(13, 13)))
			binModel(into, w(c + Vector2.new(-13, 13)))
			local sp = w(c + Vector2.new(13, -13))
			if not onPath(sp, 0.5) then
				nameSign(into, sp, Vector3.new(0, 0, 1), string.upper(room.name or ""))
			end
		end
	end
end

-- MAP ROUND 3, the plan items that had nothing built yet: the shop kiosk on the spawn plaza, the 3 launch pads aimed at
-- the brick wall, the bike rack, and the landing field's distance boards (50 / 100 / 150 from the cannon).
local function extras(into: Instance, o: Vector3, top: number)
	-- (Owner, 26 Nov: the shop kiosk is gone; the SHOP button stays.)
	-- The 3 launch pads, side by side, aimed west at the brick wall.
	local lp = planAt(o, top, "LaunchPads")
	for k = -1, 1 do
		local p = lp + Vector3.new(0, 0, k * 16)
		part(into, "LaunchPad", Vector3.new(12, 0.6, 12), CFrame.new(p + Vector3.new(0, 0.3, 0)), Color3.fromRGB(78, 82, 90), Enum.Material.DiamondPlate)
		part(into, "LaunchPadArrow", Vector3.new(6, 0.05, 1.4), CFrame.new(p + Vector3.new(0, 0.65, 0)), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic, true)
	end
	-- The bike rack.
	local br = planAt(o, top, "BikeRack")
	for k = -3, 3 do
		part(into, "BikeRackBar", Vector3.new(0.3, 2.4, 3), CFrame.new(br + Vector3.new(k * 3.6, 1.2, 0)), Color3.fromRGB(150, 154, 160), Enum.Material.Metal, true)
	end
	part(into, "BikeRackRail", Vector3.new(26, 0.3, 0.3), CFrame.new(br + Vector3.new(0, 2.4, 0)), Color3.fromRGB(150, 154, 160), Enum.Material.Metal, true)
	-- The landing field's distance boards, west of the cannon.
	local cn = planAt(o, top, "Cannon")
	for _, d in { 50, 100, 150 } do
		local at = cn + Vector3.new(-d, 0, -26)
		if not onPath(at, 1) then
			nameSign(into, at, Vector3.new(0, 0, 1), tostring(d))
		end
	end
end

-- M7: the old lab frame goes (the LAB10 compound and park, the plot's floor, spawn disc, edges, barriers, cones, signs and
-- the zone pads): invisible and walked through, the new ground is under it.
LabOwnerMap.HIDE_IN_LAB = { LabV10 = true, LabZonePads = true, ZonePads = true, LabGarden = true, Paths = true, Bullseye = true, StationPad = true, StationRail = true, StationWall = true, CrashWallBadge = true, Pedestal = true, PedestalRim = true, Guide = true, RunStripe = true, HazardRim = true, Walkway = true, Zones = true, LikePost = true, LikeSign = true, LikeSignTop = true, Spikes = true, SpikeBlock = true }
LabOwnerMap.HIDE_IN_PLOT = { LabFloor = true, Plaza = true, PlazaRim = true, Edge = true, Barrier = true, Cone = true, LabSign = true, LabSignPost = true }
local function hide(inst: Instance)
	local list = if inst:IsA("BasePart") then { inst } else {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d.Enabled = false
		end
	end
	for _, p in list do
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
	end
end
local function hideOld(folder: Instance, o: Vector3)
	for _, c in folder:GetChildren() do
		if LabOwnerMap.HIDE_IN_LAB[c.Name] or LabOwnerMap.HIDE_OLD_TOWER[c.Name] then
			if c.Name == "LabV10" or c.Name == "Heights" then
				c:Destroy() -- (M9: gone, not just hidden: they cost about 1000 parts)
			else
				hide(c)
			end
		end
	end
	local dressF = folder:FindFirstChild("Dress")
	local arms = dressF and dressF:FindFirstChild("MechArmsStand")
	if arms then
		arms:Destroy() -- (map round 2: the 4 mech arms are gone; M9: destroyed, not hidden)
	end
	local labs = Workspace:FindFirstChild("Labs")
	for _, plot in if labs then labs:GetChildren() else {} do
		local fl = plot:FindFirstChild("LabFloor", true)
		if fl and fl:IsA("BasePart") and math.abs(fl.Position.X - o.X) < 200 and math.abs(fl.Position.Z - o.Z) < 200 then
			for _, c in plot:GetDescendants() do
				if LabOwnerMap.HIDE_IN_PLOT[c.Name] then
					hide(c)
				end
			end
		end
	end
end

-- OVERVIEW 0.97 (docs/SPAWN_11.md section 1; Config.SPAWN_11): the spawn plaza's first look. The WELCOME ARCH at the stair
-- top (stone pillars, a steel truss, 3D title letters with chasing bulbs, banners), a compass rose with the bone logo
-- inlaid in the floor, 2 fountains flanking the stair, 4 flagpoles, lamps at the corners, a wayfinding signpost with an
-- arrow to every room (its distance from the spawn), 2 stone ragdoll statues at the stair foot, frames round the 4
-- leaderboards with their names in 3D letters, and a GOLD STATUE of each board's #1 player in front of it.
local STONE = Color3.fromRGB(196, 190, 178)
local STEEL_D = Color3.fromRGB(60, 64, 72)
local GOLD = Color3.fromRGB(255, 196, 60)
local function poseRig(rig: Model, poses: { [string]: CFrame })
	for name, cf in poses do
		local m = rig:FindFirstChild(name, true)
		if m and m:IsA("Motor6D") then
			m.C0 = m.C0 * cf
		end
	end
end
local function statueOf(into: Instance, desc: HumanoidDescription, at: Vector3, look: Vector3, color: Color3, mat: Enum.Material, poses: { [string]: CFrame }, keepSkin: boolean?): Model?
	local SKIN = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).STATUE_SKIN == true
	local ok, rig = pcall(function()
		return game:GetService("Players"):CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not rig then
		return nil
	end
	local animate = rig:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end
	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") then
			if not (SKIN and keepSkin) then -- (F77: a #1 statue keeps the player's own colours, face, clothes and accessories)
				d.Color = color
				d.Material = mat
			end
			d.CanCollide = false
			d.CanTouch = false
			d.CastShadow = true
			d.Massless = true
			if d:IsA("MeshPart") and not (SKIN and keepSkin) then
				d.TextureID = ""
			end
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		elseif SKIN and keepSkin then
			continue
		elseif d:IsA("SpecialMesh") then
			d.TextureId = ""
		elseif d:IsA("Decal") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			d:Destroy()
		elseif d:IsA("SurfaceAppearance") then
			d:Destroy()
		end
	end
	poseRig(rig, poses)
	local root = rig:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = true
		root.Transparency = 1
	end
	local _, size = rig:GetBoundingBox()
	local up = at + Vector3.new(0, size.Y / 2, 0)
	rig:PivotTo(CFrame.lookAt(up, up + Vector3.new(look.X, 0, look.Z)))
	if SKIN then
		-- (F77: too big with its hat or wings: scaled down to 7 tall, 5 wide; then the soles set ON the plinth top, from the
		-- feet themselves, never the bounding box: the raised arms and the hats made it float)
		local _, ext = rig:GetBoundingBox()
		local k = math.min(1, 7 / math.max(ext.Y, 0.1), 5 / math.max(math.max(ext.X, ext.Z), 0.1))
		if k < 0.99 then
			pcall(function()
				rig:ScaleTo(rig:GetScale() * k)
			end)
		end
		local low = math.huge
		for _, name in { "LeftFoot", "RightFoot" } do
			local foot = rig:FindFirstChild(name)
			if foot and foot:IsA("BasePart") then
				local h = foot.Size / 2
				for _, sx in { -1, 1 } do
					for _, sy in { -1, 1 } do
						for _, sz in { -1, 1 } do
							low = math.min(low, foot.CFrame:PointToWorldSpace(Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)).Y)
						end
					end
				end
			end
		end
		if low < math.huge then
			rig:PivotTo(rig:GetPivot() + Vector3.new(0, at.Y - low, 0))
		end
	end
	rig.Parent = into
	return rig
end
local VICTORY = { RightShoulder = CFrame.Angles(0, 0, math.rad(150)), LeftShoulder = CFrame.Angles(0, 0, math.rad(-150)) }
local function spawnSet(into: Instance, o: Vector3, top: number)
	local pz = Plan.PLAZAS.SpawnPlaza
	local ft = top + 4.3 -- the plaza floor
	local c = Vector3.new(o.X + pz.at.X, ft, o.Z + pz.at.Y)
	local south = c.Z + pz.size.Y / 2
	local set = Instance.new("Model")
	set.Name = "Spawn11"
	set.Parent = into
	-- THE WELCOME ARCH at the stair top
	local archZ = south - 3
	local ax = c.X
	local AH = 15 -- (15, not 22: on a phone the top bar hid a higher title)
	for _, s in { -1, 1 } do
		local p = Vector3.new(ax + s * 21, ft, archZ)
		part(set, "ArchPillar", Vector3.new(4, AH, 4), CFrame.new(p + Vector3.new(0, AH / 2, 0)), STONE, Enum.Material.Slate)
		part(set, "ArchPlinth", Vector3.new(5.4, 2, 5.4), CFrame.new(p + Vector3.new(0, 1, 0)), Color3.fromRGB(150, 146, 138), Enum.Material.Slate)
		part(set, "ArchCap", Vector3.new(5, 1.2, 5), CFrame.new(p + Vector3.new(0, AH + 0.6, 0)), STEEL_D, Enum.Material.Metal)
		-- a banner on each pillar, both sides
		for _, f in { -1, 1 } do
			local b = part(set, "ArchBanner", Vector3.new(3, 9, 0.15), CFrame.new(p + Vector3.new(0, AH - 7.5, f * 2.15)), Color3.fromRGB(200, 40, 50), Enum.Material.Fabric, true)
			b.CanCollide = false
			tag(b, "Swing", { Amp = 0.06, Speed = 1.1 + s * 0.2, Pivot = Vector3.new(0, 4.5, 0) })
		end
	end
	-- the truss: two chords and braces
	for _, y in { AH - 1, AH + 3.2 } do
		part(set, "ArchChord", Vector3.new(46, 0.9, 0.9), CFrame.new(ax, ft + y, archZ), STEEL_D, Enum.Material.Metal)
	end
	for k = -5, 4 do
		local x0 = ax + k * 4.2 + 2.1
		part(set, "ArchBrace", Vector3.new(0.5, 4.9, 0.5), CFrame.new(x0, ft + AH + 1.1, archZ) * CFrame.Angles(0, 0, math.rad(if k % 2 == 0 then 40 else -40)), STEEL_D, Enum.Material.Metal, true)
	end
	-- the title: 3D letters on both faces of the truss, chasing bulbs above and below
	local title = string.upper(tostring((require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SPAWN_TITLE or "RAGDOLL HAVOC"))
	for _, f in { -1, 1 } do
		local face = Vector3.new(0, 0, f)
		letters(set, title, Vector3.new(ax, ft + AH + 6.6, archZ + f * 0.9), face, 4.2, Color3.fromRGB(40, 44, 52), Color3.new(1, 1, 1))
		bulbs(set, Vector3.new(ax - 22, ft + AH + 9.3, archZ + f * 1.2), Vector3.new(ax + 22, ft + AH + 9.3, archZ + f * 1.2), 20)
		bulbs(set, Vector3.new(ax - 22, ft + AH + 4, archZ + f * 1.2), Vector3.new(ax + 22, ft + AH + 4, archZ + f * 1.2), 20)
	end
	-- THE FLOOR: a compass rose with the bone logo in the middle
	local rose = Vector3.new(c.X, ft, c.Z + 4)
	part(set, "RoseRing", Vector3.new(0.1, 34, 34), CFrame.new(rose + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 110, 96), Enum.Material.Slate, true, Enum.PartType.Cylinder)
	part(set, "RoseInner", Vector3.new(0.1, 30, 30), CFrame.new(rose + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(222, 214, 196), Enum.Material.Marble, true, Enum.PartType.Cylinder)
	for k = 0, 7 do
		local long = k % 2 == 0
		local a = k * math.pi / 4
		local len = if long then 14 else 9
		part(set, "RosePoint", Vector3.new(2.2, 0.08, len), CFrame.new(rose + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -len / 2) * CFrame.Angles(0, 0, 0), if long then Color3.fromRGB(150, 60, 50) else Color3.fromRGB(70, 74, 82), Enum.Material.Slate, true)
	end
	part(set, "RoseHub", Vector3.new(0.1, 8, 8), CFrame.new(rose + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 44, 52), Enum.Material.Slate, true, Enum.PartType.Cylinder)
	part(set, "BoneShaft", Vector3.new(4.6, 0.9, 0.9), CFrame.new(rose + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, math.rad(35), 0), Color3.fromRGB(250, 246, 236), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	for _, s in { -1, 1 } do
		for _, t in { -1, 1 } do
			part(set, "BoneKnob", Vector3.new(1.3, 1.3, 1.3), CFrame.new(rose + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, math.rad(35), 0) * CFrame.new(s * 2.4, 0, t * 0.55), Color3.fromRGB(250, 246, 236), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		end
	end
	-- 2 FOUNTAINS flanking the stair top
	for _, s in { -1, 1 } do
		local f = Vector3.new(c.X + s * 34, ft, south - 9)
		part(set, "FountainBasin", Vector3.new(1.4, 9, 9), CFrame.new(f + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Slate, false, Enum.PartType.Cylinder)
		local water = part(set, "FountainWater", Vector3.new(0.2, 7.6, 7.6), CFrame.new(f + Vector3.new(0, 1.35, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 170, 230), Enum.Material.Glass, true, Enum.PartType.Cylinder)
		water.Transparency = 0.25
		local spout = part(set, "FountainSpout", Vector3.new(3, 1, 1), CFrame.new(f + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Slate, true, Enum.PartType.Cylinder)
		emitter(spout, { Rate = 60, Speed = NumberRange.new(13, 16), Lifetime = NumberRange.new(1, 1.2), Acceleration = Vector3.new(0, -30, 0), EmissionDirection = Enum.NormalId.Right,
			Size = NumberSequence.new(0.4, 0.15), Color = ColorSequence.new(Color3.fromRGB(190, 230, 255)), Transparency = NumberSequence.new(0.15, 0.8), SpreadAngle = Vector2.new(12, 12), LightEmission = 0.2 })
	end
	-- 4 FLAGPOLES and lamps at the corners
	local flagCols = { Color3.fromRGB(230, 60, 60), Color3.fromRGB(60, 140, 230), Color3.fromRGB(255, 200, 40), Color3.fromRGB(110, 200, 90) }
	local k = 0
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			k += 1
			local p = Vector3.new(c.X + sx * (pz.size.X / 2 - 6), ft, c.Z + sz * (pz.size.Y / 2 - 6))
			part(set, "FlagPole", Vector3.new(0.5, 20, 0.5), CFrame.new(p + Vector3.new(0, 10, 0)), Color3.fromRGB(220, 222, 226), Enum.Material.Metal, true)
			part(set, "FlagTop", Vector3.new(0.9, 0.9, 0.9), CFrame.new(p + Vector3.new(0, 20.3, 0)), GOLD, Enum.Material.Metal, true, Enum.PartType.Ball)
			local flag = part(set, "Flag", Vector3.new(6, 3.6, 0.12), CFrame.new(p + Vector3.new(-sx * 3.2, 17.8, 0)), flagCols[k], Enum.Material.Fabric, true)
			flag.CanCollide = false
			tag(flag, "Swing", { Amp = 0.12, Speed = 1.6 + k * 0.1, Pivot = Vector3.new(sx * 3, 0, 0), Axis = "Y" })
			lamp(set, p + Vector3.new(sx * -3, 0, sz * -3))
		end
	end
	-- THE WAYFINDING SIGNPOST at the stair top, west of the arch: an arrow to every room
	local spawnAt = Vector2.new(pz.at.X, pz.at.Y + 25)
	local sp = Vector3.new(c.X - 48, ft, south - 20)
	part(set, "SignpostPole", Vector3.new(0.8, 19, 0.8), CFrame.new(sp + Vector3.new(0, 9.5, 0)), Color3.fromRGB(90, 66, 44), Enum.Material.WoodPlanks)
	local rooms = {}
	for key, room in Plan.ROOMS do
		if room.walled and GATE_THEME[room.name] then
			table.insert(rooms, { key = key, room = room })
		end
	end
	table.sort(rooms, function(a, b)
		return a.key < b.key
	end)
	for i, r in rooms do
		local cc = r.room.courtyard or (r.room.min + r.room.max) / 2
		local d2 = cc - spawnAt
		local d = Vector3.new(d2.X, 0, d2.Y).Unit
		local y = ft + 18 - i * 1.6
		local mid = Vector3.new(sp.X, y, sp.Z) + d * 4.6
		local th = GATE_THEME[r.room.name]
		local arm = part(set, "SignArrow", Vector3.new(8, 1.3, 0.25), CFrame.fromMatrix(mid, d, Vector3.yAxis), th.edge, Enum.Material.SmoothPlastic, true)
		part(set, "SignTip", Vector3.new(0.95, 0.95, 0.25), CFrame.fromMatrix(mid + d * 4, d, Vector3.yAxis) * CFrame.Angles(0, 0, math.rad(45)), th.edge, Enum.Material.SmoothPlastic, true)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local g = Instance.new("SurfaceGui")
			g.Face = face
			g.CanvasSize = Vector2.new(320, 52)
			g.LightInfluence = 0.2
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, 1)
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.TextColor3 = th.face
			l.TextStrokeTransparency = 0.4
			l.Text = string.upper(r.room.name) .. "  " .. tostring(math.floor(d2.Magnitude / 5 + 0.5) * 5)
			l.Parent = g
			g.Parent = arm
		end
	end
	-- 2 STONE RAGDOLL STATUES at the stair foot, funny poses
	local foot = south + 14
	local okD, plain = pcall(function()
		return Instance.new("HumanoidDescription")
	end)
	if okD then
		statueOf(set, plain, Vector3.new(c.X - 25, top + 1.4, foot), Vector3.new(0, 0, 1), STONE, Enum.Material.Slate, VICTORY)
		statueOf(set, plain:Clone(), Vector3.new(c.X + 25, top + 1.4, foot), Vector3.new(0, 0, 1), STONE, Enum.Material.Slate,
			{ RightShoulder = CFrame.Angles(0, 0, math.rad(120)) * CFrame.Angles(math.rad(60), 0, 0), Waist = CFrame.Angles(0, 0, math.rad(12)), LeftHip = CFrame.Angles(math.rad(35), 0, 0) })
		for _, s in { -1, 1 } do
			part(set, "StatuePlinth", Vector3.new(6, 1.4, 6), CFrame.new(c.X + s * 25, top + 0.7, foot), STONE, Enum.Material.Slate)
		end
	end
	-- THE LEADERBOARDS: frames, 3D names and the gold #1 statues, once the boards stand (they are placed a moment later)
	task.spawn(function()
		local LB = require(script.Parent:WaitForChild("LeaderboardService")) :: any
		local frames: { [string]: any } = {}
		for _ = 1, 30 do
			local found = 0
			for _, plot in (Workspace:FindFirstChild("Labs") or Workspace):GetChildren() do
				for _, b in plot:GetChildren() do
					if b:IsA("Model") and string.sub(b.Name, 1, 6) == "Board_" then
						local cf, size = b:GetBoundingBox()
						if math.abs(cf.Position.X - (o.X - 30)) < 80 and math.abs(cf.Position.Z - (o.Z - 360)) < 10 and not frames[b.Name] then
							local id = string.sub(b.Name, 7)
							local base = Vector3.new(cf.Position.X, ft, cf.Position.Z)
							local w = math.max(size.X, size.Z)
							part(set, "BoardBase", Vector3.new(w + 3, 1.4, 6), CFrame.new(base + Vector3.new(0, 0.7, 0)), Color3.fromRGB(46, 48, 54), Enum.Material.Granite)
							for _, s in { -1, 1 } do
								part(set, "BoardPost", Vector3.new(0.8, size.Y + 2, 0.8), CFrame.new(base + Vector3.new(s * (w / 2 + 0.9), (size.Y + 2) / 2, 0)), STEEL_D, Enum.Material.Metal)
							end
							part(set, "BoardRoof", Vector3.new(w + 3, 0.6, 4), CFrame.new(base + Vector3.new(0, size.Y + 2.3, 0)), STEEL_D, Enum.Material.Metal)
							bulbs(set, base + Vector3.new(-w / 2, size.Y + 1.9, 2.1), base + Vector3.new(w / 2, size.Y + 1.9, 2.1), 10, Color3.fromRGB(255, 240, 200))
							local titleText = id
							for _, bd in LB.BOARDS do
								if bd.id == id then
									titleText = string.gsub(bd.title, "%s+", " ")
								end
							end
							letters(set, titleText, base + Vector3.new(0, size.Y + 4.2, 0), Vector3.new(0, 0, 1), 1.9, Color3.fromRGB(40, 44, 52), GOLD)
							if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).STATUE_SKIN then
								-- (F77: the plinth BESIDE the board (its right edge + 3), not in front of the names, with a gold top trim)
								local side = base + Vector3.new(w / 2 + 5, 0, 2)
								part(set, "StatuePlinth", Vector3.new(4, 2, 4), CFrame.new(side + Vector3.new(0, 1, 0)), Color3.fromRGB(46, 48, 54), Enum.Material.Granite)
								part(set, "StatueTrim", Vector3.new(4.3, 0.22, 4.3), CFrame.new(side + Vector3.new(0, 2, 0)), GOLD, Enum.Material.Metal, true)
								frames[b.Name] = { at = side + Vector3.new(0, 2.1, 0) }
							else
							part(set, "StatuePlinth", Vector3.new(4, 2, 4), CFrame.new(base + Vector3.new(0, 1, 7)), Color3.fromRGB(46, 48, 54), Enum.Material.Granite)
							frames[b.Name] = { at = base + Vector3.new(0, 2, 7) }
							end
							frames[b.Name].id = id
						end
						found += 1
					end
				end
			end
			if next(frames) and found >= 4 then
				break
			end
			task.wait(1)
		end
		-- the #1 statue of each board, rebuilt when #1 changes
		while set.Parent do
			for _, fr in frames do
				local rows = LB.rowsOf(fr.id)
				local first = rows and rows[1]
				local who = if first then first.userId else 0
				if who ~= fr.who then
					fr.who = who
					if fr.statue then
						fr.statue:Destroy()
						fr.statue = nil
					end
					local okDesc, desc = pcall(function()
						if who > 0 then
							return game:GetService("Players"):GetHumanoidDescriptionFromUserId(who)
						end
						return Instance.new("HumanoidDescription")
					end)
					if okDesc and desc then
						local skin = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).STATUE_SKIN == true
						-- (F77: in its own skin, facing south, turned 15 degrees toward the path)
						local face = if skin then Vector3.new(-math.sin(math.rad(15)), 0, math.cos(math.rad(15))) else Vector3.new(0, 0, 1)
						fr.statue = statueOf(set, desc, fr.at, face, if who > 0 or not skin then GOLD else Color3.fromRGB(160, 160, 165), if who > 0 or not skin then Enum.Material.Foil else Enum.Material.SmoothPlastic, VICTORY, skin and who > 0)
						-- (OVERVIEW 0.99: no floating text; the name sits on a small plaque on the plinth's front)
						if fr.plaque then
							fr.plaque:Destroy()
						end
						local plaque = part(set, "StatuePlaque", Vector3.new(3.4, 0.9, 0.1), CFrame.new(fr.at + Vector3.new(0, -1, 2.05)), Color3.fromRGB(40, 36, 28), Enum.Material.Metal, true)
						local sg = Instance.new("SurfaceGui")
						sg.Face = Enum.NormalId.Back
						sg.CanvasSize = Vector2.new(200, 52)
						sg.LightInfluence = 0.3
						local l = Instance.new("TextLabel")
						l.BackgroundTransparency = 1
						l.Size = UDim2.fromScale(1, 1)
						l.Font = Enum.Font.FredokaOne
						l.TextScaled = true
						l.TextColor3 = GOLD
						l.Text = if first then "#1 " .. tostring(first.name) else "#1 COULD BE YOU"
						l.Parent = sg
						sg.Parent = plaque
						fr.plaque = plaque
					end
				end
			end
			task.wait(120)
		end
	end)
end

-- M4 (owner: "alt for mange træer buske osv ... ikke træer imellem"; Config.M4_CLEAN; docs/MAP_MASTERPLAN.md "MAP ROUND 4"): once the
-- map stands, everything that is not in the references goes: every hedge, flower bed, flower, bush, room gate and arch,
-- and every tree BETWEEN the attractions. Trees are kept only in the edge band (within EDGE studs of the map's rim or
-- outside it), at most KEEP of them, spread evenly; the rest of the rim stays clean open grass before the hills.
LabOwnerMap.M4_EDGE = 50
LabOwnerMap.M4_KEEP = 70
local function m4Clean(into: Instance, o: Vector3)
	local c, size = LabOwnerMap.CENTER, LabOwnerMap.SIZE
	local function inEdgeBand(p: Vector3): boolean
		local l = Vector2.new(p.X - o.X - c.X, p.Z - o.Z - c.Y)
		local fromEdge = math.min(size.X / 2 - math.abs(l.X), size.Y / 2 - math.abs(l.Y))
		if fromEdge >= LabOwnerMap.M4_EDGE then
			return false
		end
		-- (never by a plaza: the spawn plaza sits near the north rim)
		local q = Vector2.new(p.X - o.X, p.Z - o.Z)
		for _, pz in Plan.PLAZAS do
			local half = (if pz.size then pz.size / 2 else Vector2.new(pz.radius or 0, pz.radius or 0)) + Vector2.new(20, 20)
			if pz.at and math.abs(q.X - pz.at.X) < half.X and math.abs(q.Y - pz.at.Y) < half.Y then
				return false
			end
		end
		return true
	end
	local TREE = { TreeOak = true, TreeFir = true, TreePoplar = true }
	local GONE = { Hedge = true, FlowerBedSoil = true, FlowerBedEdge = true, Flower = true, Bush = true, ArchPost = true, ArchSign = true }
	local keep: { Instance } = {}
	local removed = 0
	for _, t in into:GetChildren() do
		local n = t.Name
		if GONE[n] or string.sub(n, 1, 5) == "Gate_" or string.find(n, "Bush") or string.find(n, "Flower") or string.find(n, "Hedge") then
			t:Destroy()
			removed += 1
		elseif TREE[n] or string.sub(n, 1, 4) == "Tree" then
			local at = if t:IsA("Model") then t:GetPivot().Position elseif t:IsA("BasePart") then t.Position else nil
			if at and inEdgeBand(at) then
				table.insert(keep, t)
			else
				t:Destroy()
				removed += 1
			end
		end
	end
	-- at most KEEP trees in the band, every n-th one (spread round the whole rim)
	if #keep > LabOwnerMap.M4_KEEP then
		local step = #keep / LabOwnerMap.M4_KEEP
		local chosen: { [Instance]: boolean } = {}
		for i = 0, LabOwnerMap.M4_KEEP - 1 do
			chosen[keep[math.floor(i * step) + 1]] = true
		end
		for _, t in keep do
			if not chosen[t] then
				t:Destroy()
				removed += 1
			end
		end
	end
	print(string.format("[OwnerMap] M4 clean: %d pieces removed, %d edge trees kept", removed, math.min(#keep, LabOwnerMap.M4_KEEP)))
end

-- F78 (owner: "det ligner ikke der er vand, ragdollen skal svømme eller drukne"; Config.REAL_WATER): every water body is
-- REAL Terrain water: the aquarium filled inside its glass to 2 studs under the rim, the big pool and the lounge pool in
-- raised basins, the croc pond a round pond with a muddy bank. The fake glass "water" parts go. Each body gets an
-- invisible WaterVolume box (tag WaterVolume: Systems/SwimService; its name keeps paths out: RagdollNav NoGo).
local function waterVolume(into: Instance, name: string, cf: CFrame, size: Vector3)
	local v = Instance.new("Part")
	v.Name = name .. "WaterVolume"
	v.Anchored, v.CanCollide, v.CanQuery, v.CanTouch, v.CastShadow = true, false, false, false, false
	v.Transparency = 1
	v.Size = size
	v.CFrame = cf
	v.Parent = into
	game:GetService("CollectionService"):AddTag(v, "WaterVolume")
end
local function realWater(into: Instance, o: Vector3, top: number)
	local T = Workspace.Terrain
	T.WaterColor = Color3.fromRGB(40, 130, 140)
	T.WaterTransparency = 0.6
	T.WaterWaveSize = 0.05
	T.WaterWaveSpeed = 4
	T.WaterReflectance = 0.4
	for _, n in { "AquaWater", "PoolWater", "CrocWater", "SmallPoolWater" } do
		for _, d in into:GetChildren() do
			if d.Name == n then
				d:Destroy()
			end
		end
	end
	-- the aquarium: inside the glass, from the base top to 2 under the rim
	local aq = planAt(o, top, "Aquarium")
	local AW, AD, AH = AQUA.X, AQUA.Y, AQUA.Z
	local acf = CFrame.new(aq + Vector3.new(0, 3 + (AH - 2) / 2, 0))
	local asz = Vector3.new(AW - 2, AH - 2, AD - 2)
	T:FillBlock(acf, asz, Enum.Material.Water)
	waterVolume(into, "Aqua", acf, asz)
	-- the big pool: its rim raised to a basin wall, 3.5 studs of water
	local pool = planAt(o, top, "BigPool")
	local PW, PD = POOL.X, POOL.Y
	for _, s in { { Vector3.new(PW + 8, 4.4, 4), Vector3.new(0, 0, PD / 2 + 2) }, { Vector3.new(PW + 8, 4.4, 4), Vector3.new(0, 0, -PD / 2 - 2) }, { Vector3.new(4, 4.4, PD), Vector3.new(PW / 2 + 2, 0, 0) }, { Vector3.new(4, 4.4, PD), Vector3.new(-PW / 2 - 2, 0, 0) } } do
		part(into, "PoolWall", s[1], CFrame.new(pool + s[2] + Vector3.new(0, 2.2, 0)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	end
	local pcf = CFrame.new(pool + Vector3.new(0, 1.9, 0))
	local psz = Vector3.new(PW, 3.6, PD)
	T:FillBlock(pcf, psz, Enum.Material.Water)
	waterVolume(into, "Pool", pcf, psz)
	-- the lounge pool: the same, smaller
	local pl = planAt(o, top, "LoungePool")
	-- (M4: the basin the plan's footprint minus the loungers' strip on the north: LOUNGE.X x (LOUNGE.Y - 8), centred 4 south)
	local LW, LD = LOUNGE.X, LOUNGE.Y - 8
	local lc = pl + Vector3.new(0, 0, 4)
	for _, s in { { Vector3.new(LW, 3.4, 1.5), Vector3.new(0, 0, LD / 2 - 0.75) }, { Vector3.new(LW, 3.4, 1.5), Vector3.new(0, 0, -LD / 2 + 0.75) }, { Vector3.new(1.5, 3.4, LD), Vector3.new(LW / 2 - 0.75, 0, 0) }, { Vector3.new(1.5, 3.4, LD), Vector3.new(-LW / 2 + 0.75, 0, 0) } } do
		part(into, "SmallPoolWall", s[1], CFrame.new(lc + s[2] + Vector3.new(0, 1.7, 0)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	end
	local lcf = CFrame.new(lc + Vector3.new(0, 1.5, 0))
	local lsz = Vector3.new(LW - 3, 2.8, LD - 3)
	T:FillBlock(lcf, lsz, Enum.Material.Water)
	waterVolume(into, "SmallPool", lcf, lsz)
	-- the croc pond: a muddy, sandy bank ring and water inside it
	local pond = planAt(o, top, "CrocPond")
	local axis = CFrame.Angles(0, 0, math.rad(90))
	-- (M4: sized from the plan's footprint: water to CROC_R - 4, the mud bank to CROC_R - 1, the sand to CROC_R)
	T:FillCylinder(CFrame.new(pond + Vector3.new(0, 1.2, 0)) * axis, 2.4, CROC_R - 1, Enum.Material.Mud)
	T:FillCylinder(CFrame.new(pond + Vector3.new(0, 0.6, 0)) * axis, 1.2, CROC_R, Enum.Material.Sand)
	T:FillCylinder(CFrame.new(pond + Vector3.new(0, 1.3, 0)) * axis, 2.6, CROC_R - 4, Enum.Material.Water)
	waterVolume(into, "Croc", CFrame.new(pond + Vector3.new(0, 1.3, 0)), Vector3.new((CROC_R - 4) * 2, 2.6, (CROC_R - 4) * 2))
	-- F78 part 2: reeds in clumps round the bank, lily pads on the water, half-buried natural rocks (no balls)
	local rng = Random.new(78)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local base = pond + Vector3.new(math.cos(a) * (CROC_R - 3), 1.4, math.sin(a) * (CROC_R - 3))
		if i % 3 ~= 0 and not onPath(base, 2) then
			for k = 1, 5 do
				local h = rng:NextNumber(2.2, 3.8)
				local r = part(into, "Reed", Vector3.new(0.18, h, 0.18), CFrame.new(base + Vector3.new(rng:NextNumber(-1.2, 1.2), h / 2, rng:NextNumber(-1.2, 1.2))) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15)), Color3.fromRGB(96, 128, 64), Enum.Material.Grass, true)
				r.CanCollide = false
			end
		elseif not onPath(base, 2) then
			pcall(function()
				T:FillBall(base + Vector3.new(0, -1, 0), rng:NextNumber(1.6, 2.4), Enum.Material.Rock)
			end)
		end
	end
	for i = 1, 6 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(3, CROC_R - 7)
		local pad = part(into, "LilyPad", Vector3.new(0.1, 2.2, 2.2), CFrame.new(pond + Vector3.new(math.cos(a) * d, 2.62, math.sin(a) * d)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(86, 140, 70), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
		pad.CanCollide = false
	end
	-- F78 part 2: THE FEEDING PLATFORM on the aquarium's east side: steps up from the front to a railed platform that
	-- reaches 3 studs over the water, so a ragdoll can be carried up and thrown (or dropped) in to the shark.
	do
		local AW2, AD2, AH2 = AQUA.X, AQUA.Y, AQUA.Z
		local rimY = 3 + AH2
		local ex = aq.X + AW2 / 2 -- (the east glass)
		local steps = math.ceil(rimY / 0.85)
		local run = math.min(1.3, (AD2 - 6) / steps)
		for k = 1, steps do
			local y = k * rimY / steps
			part(into, "FeedStep", Vector3.new(4, 0.5, run + 0.05), CFrame.new(Vector3.new(ex + 3, top + y - 0.25, aq.Z + AD2 / 2 - (k - 0.5) * run)), Color3.fromRGB(150, 150, 152), Enum.Material.DiamondPlate)
		end
		local pz = aq.Z + AD2 / 2 - steps * run - 2.5
		part(into, "FeedPlatform", Vector3.new(10, 0.6, 5), CFrame.new(Vector3.new(ex, top + rimY - 0.3, pz)), Color3.fromRGB(150, 150, 152), Enum.Material.DiamondPlate)
		for _, sx in { -1, 1 } do
			part(into, "FeedRail", Vector3.new(10, 0.25, 0.25), CFrame.new(Vector3.new(ex, top + rimY + 3, pz + sx * 2.4)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
		end
		part(into, "FeedRail", Vector3.new(0.25, 0.25, 5), CFrame.new(Vector3.new(ex + 5, top + rimY + 3, pz)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
		for _, d in { Vector3.new(-5, 0, -2.4), Vector3.new(-5, 0, 2.4), Vector3.new(5, 0, -2.4), Vector3.new(5, 0, 2.4) } do
			part(into, "FeedPost", Vector3.new(0.3, 3, 0.3), CFrame.new(Vector3.new(ex, top + rimY + 1.5, pz) + d), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
		end
		-- (the stair's side rail and the stringer down to the ground)
		part(into, "FeedStringer", Vector3.new(0.4, rimY, 0.4), CFrame.new(Vector3.new(ex + 5, top + rimY / 2, pz)), Color3.fromRGB(75, 80, 86), Enum.Material.Metal)
	end
end


function LabOwnerMap.build(folder: Instance, origin: Vector3)
	LabOwnerMap.origin = origin
	-- (OVERVIEW 0.5, Config.SPAWN_UPRIGHT: the lab's ragdolls were laid out before the raised plaza stood, so the ones on its
	-- spot were inside it and fell over. Once the map stands, every ragdoll inside the plaza is set on top of it, upright.)
	task.delay(1.5, function()
		if not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SPAWN_UPRIGHT then
			return
		end
		local pz = Plan.PLAZAS.SpawnPlaza
		local dummies = Workspace:FindFirstChild("Dummies")
		local DummyControl = require(script.Parent:WaitForChild("DummyControl")) :: any
		for _, m in if dummies then dummies:GetChildren() else {} do
			local pelvis = m:FindFirstChild("LowerTorso")
			if m:IsA("Model") and pelvis and pelvis:IsA("BasePart") then
				local l = Vector2.new(pelvis.Position.X - origin.X, pelvis.Position.Z - origin.Z) - pz.at
				if math.abs(l.X) < pz.size.X / 2 + 2 and math.abs(l.Y) < pz.size.Y / 2 + 2 and pelvis.Position.Y < origin.Y + 6 then
					local at = Vector3.new(pelvis.Position.X, origin.Y + 4 + 3.2, pelvis.Position.Z)
					pcall(DummyControl.move, m, CFrame.lookAt(at, at + Vector3.zAxis))
				end
			end
		end
	end)
	hideOld(folder, origin)
	-- (M7: the 4 leaderboards stand in a row on the raised plaza, facing the stair; LeaderboardService makes them a little
	-- later, so this waits for them.)
	task.spawn(function()
		local S = LabOwnerMap.S
		local lb = Plan.ITEMS.Leaderboards
		local pz = if lb then lb.at.Y else -360 -- (map round 3: OwnerMapPlan Leaderboards, the back of the spawn plaza)
		local px = if lb then lb.at.X else -30
		local gapX = if lb then math.min(30, lb.size.X / 3) else 30 -- (M4: the compact plaza)
		for _ = 1, 40 do
			task.wait(0.5)
			local boards: { Model } = {}
			local labs = Workspace:FindFirstChild("Labs")
			for _, plot in if labs then labs:GetChildren() else {} do
				local fl = plot:FindFirstChild("LabFloor", true)
				if fl and fl:IsA("BasePart") and math.abs(fl.Position.X - origin.X) < 200 and math.abs(fl.Position.Z - origin.Z) < 200 then
					for _, c in plot:GetChildren() do
						if c:IsA("Model") and string.sub(c.Name, 1, 6) == "Board_" then
							table.insert(boards, c)
						end
					end
				end
			end
			if #boards >= 4 then
				table.sort(boards, function(a, b)
					return a.Name < b.Name
				end)
				for i, b in boards do
					local _, size = b:GetBoundingBox()
					local x = (i - (#boards + 1) / 2) * gapX
					local at = Vector3.new(origin.X + px + x, origin.Y + 4 + size.Y / 2, origin.Z + pz)
					b:PivotTo(CFrame.lookAt(at, at + Vector3.new(0, 0, 1))) -- (OVERVIEW 0.6: measured, the screens then face +Z: south, to the spawn and the stair)
					local _, newSize = b:GetBoundingBox()
					local cf2 = b:GetBoundingBox()
					b:PivotTo(b:GetPivot() + Vector3.new(0, (origin.Y + 4.3) - (cf2.Position.Y - newSize.Y / 2), 0))
				end
				return
			end
		end
	end)
	local into = Instance.new("Folder")
	into.Name = "OwnerMap"
	into.Parent = folder
	ground(into, origin)
	hero(into, origin, origin.Y - 0.05)
	northRow(into, origin, origin.Y - 0.05)
	west(into, origin, origin.Y - 0.05)
	east(into, origin, origin.Y - 0.05)
	south(into, origin, origin.Y - 0.05)
	-- (map round 3: the ball-on-a-stick groves are gone; the tree belts come next)
	fill(into, origin, origin.Y - 0.05)
	local M4 = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).M4_CLEAN == true
	if not M4 then
		belts(into, origin, origin.Y - 0.05) -- (M4: no tree belts, bush rows or room gates)
	end
	parks(into, origin, origin.Y - 0.05)
	yards(into, origin, origin.Y - 0.05)
	extras(into, origin, origin.Y - 0.05)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SPAWN_11 then
		spawnSet(into, origin, origin.Y - 0.05) -- (OVERVIEW 0.97: the spawn to 11/10)
	end
	if M4 then
		m4Clean(into, origin) -- (at once: nobody sees the trees go)
	end
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).REAL_WATER then
		realWater(into, origin, origin.Y - 0.05)
	end
	-- F53 (owner: "Man kan ikke komme ind i Weapons Testing, fordi træerne dækker"; Config.TREE_CLEAR): once everything has
	-- stood a few seconds (other systems build their buildings too), every tree or bush whose foot stands within 4 studs
	-- of a building, wall, machine or sign (anything that is not ground or foliage) is taken away.
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).TREE_CLEAR then
		task.delay(4, function()
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			local ex = {}
			for _, n in { "Dummies", "Terrain" } do
				local x = Workspace:FindFirstChild(n)
				if x then
					table.insert(ex, x)
				end
			end
			params.FilterDescendantsInstances = ex
			local removed = 0
			for _, t in into:GetChildren() do
				if t:IsA("Model") and (t.Name == "TreeOak" or t.Name == "TreeFir" or t.Name == "TreePoplar" or t.Name == "Bush") then
					local foot = t:GetPivot().Position
					local _, size = t:GetBoundingBox()
					local base = Vector3.new(foot.X, origin.Y + 4, foot.Z)
					local blocked = false
					for _, h in Workspace:GetPartBoundsInBox(CFrame.new(base), Vector3.new(8, 7, 8), params) do
						if not h:IsDescendantOf(t) and h.Transparency < 1 and not (h.Size.Y < 1.3 and math.abs(h.CFrame.UpVector.Y) > 0.95)
							and not string.find(h.Name, "Canopy") and not string.find(h.Name, "Trunk") and h.Name ~= "Hedge" and h.Name ~= "OwnerGrass" and h.Name ~= "OwnerRim" and not string.find(h.Name, "Baseplate") then
							blocked = true
							break
						end
					end
					if blocked then
						t:Destroy()
						removed += 1
					end
					local _ = size
				end
			end
			into:SetAttribute("TreesCleared", removed)
		end)
	end
	hills(origin)
end

return LabOwnerMap
