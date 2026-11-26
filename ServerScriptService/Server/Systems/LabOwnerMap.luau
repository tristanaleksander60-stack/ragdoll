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

LabOwnerMap.S = 3.2 -- the R3.2 plan's distances are multiplied by this
LabOwnerMap.SIZE = Vector2.new(980, 850) -- (map round 3: the master plan plus the railway round it)
LabOwnerMap.CENTER = Vector2.new(-22, 22) -- (lab space; the master plan runs x -472..425, z -372..425)
LabOwnerMap.WALK = 15 -- walkway width (map round 2: was 22)

local GRASS = Color3.fromRGB(118, 168, 84)
local WALK = Color3.fromRGB(212, 212, 206)
local GRANITE = Color3.fromRGB(128, 128, 132)
local CAP = Color3.fromRGB(196, 196, 192)
local STEEL = Color3.fromRGB(170, 174, 180)
local RAIL = Color3.fromRGB(96, 92, 88)
local SLEEPER = Color3.fromRGB(110, 84, 60)
local BALLAST = Color3.fromRGB(150, 146, 140)

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

-- MAP ROUND 3 (owner: "Det her map er 1/10"; docs/MAP_MASTERPLAN.md): the ground is built FROM the master plan
-- (Shared/OwnerMapPlan, lab-space studs, x east, z south): the grass, every road, plaza and inner path as large
-- light-grey slabs (a tile texture, a low kerb, raised a little), round paved junction plazas, the raised spawn plaza
-- (4 high, granite wall, cap, railing, a wide stair down to the boulevard), and the railway round the west, south and
-- east with a station at the south end. The old grid walkways are gone.
local Plan = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
LabOwnerMap.Plan = Plan
-- A plan item's spot on the floor (lab space + the lab origin), with an optional nudge.
local function planAt(o: Vector3, top: number, id: string, dx: number?, dz: number?): Vector3
	local it = Plan.ITEMS[id]
	local v = if it then it.at else Vector2.zero
	return Vector3.new(o.X + v.X + (dx or 0), top, o.Z + v.Y + (dz or 0))
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
	for i = 1, #pts - 1 do
		local a, b = w(pts[i]), w(pts[i + 1])
		local len = (b - a).Magnitude
		local along = CFrame.lookAt((a + b) / 2, b)
		part(into, "OwnerBallast", Vector3.new(9, 0.5, len + 4), along * CFrame.new(0, 0.25, 0), BALLAST, Enum.Material.Pebble, true)
		for _, side in { -1, 1 } do
			part(into, "OwnerRail", Vector3.new(0.4, 0.5, len + 4), along * CFrame.new(side * 2.4, 1, 0), RAIL, Enum.Material.Metal, true)
		end
		local n = math.floor(len / 10) -- (M9: a sleeper every 10)
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
	local n = 22
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local rx, rz = LabOwnerMap.SIZE.X / 2 + 260, LabOwnerMap.SIZE.Y / 2 + 260 -- (map round 3: outside the rim and the forest)
		local at = mid + Vector3.new(math.cos(a) * rx, -40 + (i % 3) * 6, math.sin(a) * rz)
		pcall(function()
			terrain:FillBall(at, 95 + (i % 4) * 18, Enum.Material.Grass)
		end)
	end
end

-- M2: the hero (ref_5, ref_8, ref_10): the 5-floor grey steel scaffold stair tower (about 56 x 56, 95 high) just south of
-- the spawn circle, zig-zag stairs in an open middle well, diamond-plate floors, railings on every edge and a roof deck;
-- the green steel slide from the roof's west side curving down to the south-west on a steel truss, a round button at
-- its top; the wooden plank bridge from the second floor down to the east; the grey grandstand with wooden seats on
-- its own plot south of the tower. Today's code tower and the Heights set go (hidden).
LabOwnerMap.TOWER_AT = Vector2.new(5, 40) -- (plan; x S)
LabOwnerMap.TOWER_SIZE = 56
LabOwnerMap.FLOOR_H = 19
LabOwnerMap.FLOORS = 5
local GALV = Color3.fromRGB(150, 154, 160)
local PLATE = Color3.fromRGB(128, 132, 138)
local SLIDE = Color3.fromRGB(86, 118, 92)
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

local function hero(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local T = LabOwnerMap.TOWER_SIZE
	local H = LabOwnerMap.FLOOR_H
	local c = planAt(o, top, "Tower")
	local h = T / 2
	local wellX, wellZ = 14, 34 -- the open middle well (stairs run along Z)
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
		if f == LabOwnerMap.FLOORS then
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
	-- A ground pad under the tower.
	part(into, "TowerPad", Vector3.new(T + 8, 0.4, T + 8), CFrame.new(c + Vector3.new(0, 0.2, 0)), CONCRETE, Enum.Material.Concrete)

	-- THE SLIDE: from the roof's west edge, down and round to the south-west on a truss.
	local roofY = top + H * LabOwnerMap.FLOORS
	local pts = {
		c + Vector3.new(-h, roofY - top + 0.5, -10),
		-- (map round 3: kept inside the Tower Square, radius 100)
		c + Vector3.new(-h - 18, roofY - top - 30, 4),
		c + Vector3.new(-h - 36, roofY - top - 58, 20),
		c + Vector3.new(-h - 44, roofY - top - 78, 42),
		c + Vector3.new(-h - 46, 2.5, 66),
		c + Vector3.new(-h - 46, 0.6, 80),
	}
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
	part(into, "SlideButton", Vector3.new(0.8, 3, 3), CFrame.new(pts[1] + Vector3.new(4, 1.5, -8)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 40, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)

	-- THE PLANK BRIDGE: from the second floor's east edge down to the ground in the east.
	local from = c + Vector3.new(h, H * 2 + 0.4, 6)
	local to = Vector3.new(c.X + h + 50, top + 0.4, c.Z - 30) -- (map round 3: down into the Tower Square)
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
	local g = c + Vector3.new(0, 0, h + 20) -- (map round 3: on the Tower Square, south of the tower, the seats facing it)
	local W, rows = 80, 6
	for r = 1, rows do
		local stepH = r * 2
		local z = g.Z + (r - 1) * 3.2
		part(into, "StandStep", Vector3.new(W, stepH, 3.2), CFrame.new(g.X, top + stepH / 2, z), CONCRETE, Enum.Material.Concrete)
		part(into, "StandSeat", Vector3.new(W - 4, 0.5, 1.4), CFrame.new(g.X, top + stepH + 0.25, z - 0.4), WOOD, Enum.Material.WoodPlanks, true)
	end
	local backZ = g.Z + rows * 3.2
	part(into, "StandBack", Vector3.new(W, rows * 2 + 6, 1.2), CFrame.new(g.X, top + (rows * 2 + 6) / 2, backZ), CONCRETE, Enum.Material.Concrete)
	for k = -3, 3 do
		part(into, "StandPanel", Vector3.new(4, rows * 2 + 2, 0.2), CFrame.new(g.X + k * 11, top + (rows * 2 + 2) / 2 + 1, backZ + 0.7), Color3.fromRGB(70, 72, 78), Enum.Material.SmoothPlastic, true)
	end
	railing(into, Vector3.new(g.X - W / 2, top + rows * 2, backZ - 1.5), Vector3.new(g.X + W / 2, top + rows * 2, backZ - 1.5))
	part(into, "StandPlot", Vector3.new(W + 20, 0.3, 40), CFrame.new(g.X, top + 0.15, g.Z + 8), Color3.fromRGB(196, 196, 190), Enum.Material.Pavement)
end

LabOwnerMap.HIDE_OLD_TOWER = { Tower = true, TowerBand = true, TowerStripe = true, Stair = true, StairEdge = true, Heights = true }

-- M3: the north row (ref_6, ref_7, ref_10), west to east: the rock cave with its stone-ringed dirt yard (and the bear,
-- V3Assets "Bear" when the place has it), the glass aquarium (the shark tank creature moves into it: LabLayout10), the
-- leaderboard plaza (M1), the open pool, the fenced dirt pen.
local ROCK = Color3.fromRGB(132, 130, 126)
local DIRT = Color3.fromRGB(122, 98, 72)
local GLASS = Color3.fromRGB(170, 210, 230)
local WATER = Color3.fromRGB(70, 150, 200)
local function northRow(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local function at(x: number, z: number): Vector3
		return Vector3.new(o.X + x * S, top, o.Z + z * S)
	end
	-- THE CAVE: a big rounded grey rock with a dark mouth, a dirt yard in front ringed with grey stones.
	local cave = planAt(o, top, "CaveBear", 0, -10)
	part(into, "CaveRock", Vector3.new(110, 70, 90), CFrame.new(cave + Vector3.new(0, 18, 0)), ROCK, Enum.Material.Rock, false, Enum.PartType.Ball)
	part(into, "CaveRock", Vector3.new(70, 52, 60), CFrame.new(cave + Vector3.new(-30, 14, -18)), ROCK:Lerp(Color3.new(0, 0, 0), 0.08), Enum.Material.Rock, false, Enum.PartType.Ball)
	local mouth = part(into, "CaveMouth", Vector3.new(26, 22, 3), CFrame.new(cave + Vector3.new(14, 11, 43)), Color3.fromRGB(28, 26, 24), Enum.Material.Slate, true)
	mouth.Shape = Enum.PartType.Block
	local yard = planAt(o, top, "CaveBear", 10, 40)
	part(into, "CaveYard", Vector3.new(120, 0.3, 70), CFrame.new(yard + Vector3.new(0, 0.15, 0)), DIRT, Enum.Material.Ground)
	local n = 26
	for i = 1, n do
		local a = i / n * math.pi * 2
		local r = Vector3.new(math.cos(a) * 62, 0, math.sin(a) * 37)
		local s = 4 + (i % 3) * 1.5
		part(into, "YardStone", Vector3.new(s * 1.4, s, s * 1.2), CFrame.new(yard + r + Vector3.new(0, s * 0.35, 0)) * CFrame.Angles(0, a, 0), ROCK, Enum.Material.Rock, true, Enum.PartType.Ball)
	end
	-- THE AQUARIUM: a glass box on a concrete base with a steel frame, water inside.
	local aq = planAt(o, top, "Aquarium")
	local AW, AD, AH = 80, 56, 26
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
	local PW, PD = 90, 64
	part(into, "PoolRim", Vector3.new(PW + 8, 1.2, 4), CFrame.new(pool + Vector3.new(0, 0.6, PD / 2 + 2)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	part(into, "PoolRim", Vector3.new(PW + 8, 1.2, 4), CFrame.new(pool + Vector3.new(0, 0.6, -PD / 2 - 2)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	part(into, "PoolRim", Vector3.new(4, 1.2, PD), CFrame.new(pool + Vector3.new(PW / 2 + 2, 0.6, 0)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	part(into, "PoolRim", Vector3.new(4, 1.2, PD), CFrame.new(pool + Vector3.new(-PW / 2 - 2, 0.6, 0)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	local pw = part(into, "PoolWater", Vector3.new(PW, 0.4, PD), CFrame.new(pool + Vector3.new(0, 0.5, 0)), Color3.fromRGB(110, 190, 225), Enum.Material.Glass)
	pw.Transparency = 0.25
	-- THE PEN: a dirt yard with a post-and-rail fence and a gate on its south side.
	local pen = planAt(o, top, "SpiderPen")
	local EW, ED = 110, 76
	part(into, "PenDirt", Vector3.new(EW, 0.3, ED), CFrame.new(pen + Vector3.new(0, 0.15, 0)), DIRT:Lerp(Color3.fromRGB(150, 130, 100), 0.3), Enum.Material.Ground)
	local corners = { Vector3.new(-EW / 2, 0, -ED / 2), Vector3.new(EW / 2, 0, -ED / 2), Vector3.new(EW / 2, 0, ED / 2), Vector3.new(-EW / 2, 0, ED / 2) }
	for i = 1, 4 do
		local a, b = pen + corners[i], pen + corners[i % 4 + 1]
		local len = (b - a).Magnitude
		local posts = math.floor(len / 8)
		for k = 0, posts do
			local p = a:Lerp(b, k / posts)
			local gate = i == 3 and math.abs((p - pen).X) < 8
			if not gate then
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
		b:PivotTo(CFrame.lookAt(cave + Vector3.new(14, size.Y / 2, 56), cave + Vector3.new(14, size.Y / 2, 120)))
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
	part(into, "BaySlab", Vector3.new(130, 0.3, 50), CFrame.new(bays + Vector3.new(0, 0.15, 0)), Color3.fromRGB(176, 176, 172), Enum.Material.Concrete)
	for k = -2, 2 do
		part(into, "BayLine", Vector3.new(0.6, 0.05, 44), CFrame.new(bays + Vector3.new(k * 32 + (if k > 0 then -16 else 16) * 0, 0.33, 0)), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic, true)
	end
	part(into, "BayKerb", Vector3.new(130, 1, 1.6), CFrame.new(bays + Vector3.new(0, 0.5, -24)), Color3.fromRGB(200, 200, 196), Enum.Material.Concrete)
	-- Red barrels in two groups (a white band round each).
	for _, g in { planAt(o, top, "BrickWall", 14, -56), planAt(o, top, "BrickWall", 14, 50) } do
		for k = 0, 4 do
			local p = g + Vector3.new((k % 3) * 3.4, 0, math.floor(k / 3) * 3.4)
			part(into, "Barrel", Vector3.new(4.4, 3, 3), CFrame.new(p + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(196, 36, 36), Enum.Material.Metal, false, Enum.PartType.Cylinder)
			part(into, "BarrelBand", Vector3.new(0.5, 3.05, 3.05), CFrame.new(p + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(235, 235, 235), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
		end
	end
	-- The long brick crash wall (north-south).
	local wa, wb = planAt(o, top, "BrickWall", 0, -50), planAt(o, top, "BrickWall", 0, 50)
	local wl = (wb - wa).Magnitude
	part(into, "CrashBrickWall", Vector3.new(4, 22, wl), CFrame.new((wa + wb) / 2 + Vector3.new(0, 11, 0)), BRICK, Enum.Material.Brick)
	part(into, "CrashBrickCap", Vector3.new(4.6, 0.8, wl + 0.6), CFrame.new((wa + wb) / 2 + Vector3.new(0, 22.4, 0)), Color3.fromRGB(170, 166, 160), Enum.Material.Concrete, true)
	-- The garage on the railway (the rail runs into it).
	local gar = planAt(o, top, "Garage")
	part(into, "GarageFloor", Vector3.new(56, 0.4, 70), CFrame.new(gar + Vector3.new(0, 0.2, 0)), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
	for _, side in { -1, 1 } do
		part(into, "GarageWall", Vector3.new(1.5, 24, 70), CFrame.new(gar + Vector3.new(side * 27.5, 12, 0)), Color3.fromRGB(196, 190, 180), Enum.Material.Concrete)
	end
	part(into, "GarageBack", Vector3.new(56, 24, 1.5), CFrame.new(gar + Vector3.new(0, 12, -34.5)), Color3.fromRGB(196, 190, 180), Enum.Material.Concrete)
	part(into, "GarageRoof", Vector3.new(60, 1.5, 74), CFrame.new(gar + Vector3.new(0, 24.75, 0)), Color3.fromRGB(196, 130, 110), Enum.Material.Slate)
	-- The rocket's round pad and its steel gantry (the rocket itself is LabDress "Rocket", moved here).
	local rk = planAt(o, top, "Rocket")
	part(into, "RocketPad", Vector3.new(1, 46, 46), CFrame.new(rk + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(160, 160, 158), Enum.Material.Concrete, false, Enum.PartType.Cylinder)
	local gx = rk + Vector3.new(16, 0, 0)
	for _, dx in { -3, 3 } do
		for _, dz in { -3, 3 } do
			part(into, "GantryLeg", Vector3.new(0.9, 60, 0.9), CFrame.new(gx + Vector3.new(dx, 30, dz)), Color3.fromRGB(200, 200, 204), Enum.Material.Metal)
		end
	end
	for y = 6, 58, 6 do
		for _, e in { { Vector3.new(-3, y, -3), Vector3.new(3, y + 6, -3) }, { Vector3.new(3, y, 3), Vector3.new(-3, y + 6, 3) }, { Vector3.new(-3, y, 3), Vector3.new(-3, y + 6, -3) }, { Vector3.new(3, y, -3), Vector3.new(3, y + 6, 3) } } do
			local a, b = gx + e[1], gx + e[2]
			part(into, "GantryBrace", Vector3.new(0.35, 0.35, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), Color3.fromRGB(200, 200, 204), Enum.Material.Metal, true)
		end
	end
	part(into, "GantryArm", Vector3.new(14, 1.2, 2), CFrame.new(gx + Vector3.new(-8, 44, 0)), Color3.fromRGB(200, 200, 204), Enum.Material.Metal)
	-- The concrete slab south of the rocket.
	part(into, "ConcreteSlab", Vector3.new(60, 1, 44), CFrame.new(planAt(o, top, "LandingField") + Vector3.new(0, 0.5, 0)), Color3.fromRGB(170, 170, 168), Enum.Material.Concrete)
	-- The walled T-rex pen with its gate (east side) and the T-rex.
	local tr = planAt(o, top, "TRexPen")
	local TW = 110
	for _, w in { { Vector3.new(TW, 18, 3), Vector3.new(0, 9, -TW / 2) }, { Vector3.new(TW, 18, 3), Vector3.new(0, 9, TW / 2) }, { Vector3.new(3, 18, TW), Vector3.new(-TW / 2, 9, 0) } } do
		part(into, "TRexWall", w[1], CFrame.new(tr + w[2]), Color3.fromRGB(150, 146, 138), Enum.Material.Concrete)
	end
	for _, dz in { -1, 1 } do
		part(into, "TRexWall", Vector3.new(3, 18, TW / 2 - 12), CFrame.new(tr + Vector3.new(TW / 2, 9, dz * (TW / 4 + 6))), Color3.fromRGB(150, 146, 138), Enum.Material.Concrete)
	end
	part(into, "TRexGate", Vector3.new(1, 16, 24), CFrame.new(tr + Vector3.new(TW / 2 + 0.6, 8, 0)), Color3.fromRGB(70, 70, 74), Enum.Material.DiamondPlate)
	part(into, "TRexGround", Vector3.new(TW - 3, 0.3, TW - 3), CFrame.new(tr + Vector3.new(0, 0.15, 0)), Color3.fromRGB(120, 104, 80), Enum.Material.Ground)
	placeModel(into, "TRex", tr, Vector3.new(1, 0, 0.3))
	-- The crocodile pond with its speaker wall.
	local pond = planAt(o, top, "CrocPond")
	local water = part(into, "CrocWater", Vector3.new(0.6, 70, 70), CFrame.new(pond + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 110, 80), Enum.Material.Glass, false, Enum.PartType.Cylinder)
	water.Transparency = 0.2
	for i = 1, 3 do
		local a = i * 2.1
		placeModel(into, "Crocodile", pond + Vector3.new(math.cos(a) * 18, 0.3, math.sin(a) * 18), Vector3.new(math.sin(a), 0, -math.cos(a)))
	end
	local sw = pond + Vector3.new(0, 0, -44)
	for k = -3, 3 do
		for y = 0, 2 do
			part(into, "Speaker", Vector3.new(8, 7, 5), CFrame.new(sw + Vector3.new(k * 8.4, 3.5 + y * 7.2, 0)), Color3.fromRGB(32, 32, 36), Enum.Material.SmoothPlastic)
			part(into, "SpeakerCone", Vector3.new(0.4, 4.6, 4.6), CFrame.new(sw + Vector3.new(k * 8.4, 3.5 + y * 7.2, 2.6)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(70, 70, 76), Enum.Material.Metal, true, Enum.PartType.Cylinder)
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
	part(into, "SandcastleTower", Vector3.new(16, 34, 16), CFrame.new(sc + Vector3.new(0, 17, 0)), SAND, Enum.Material.Sandstone)
	for _, d in { Vector3.new(-6, 0, -6), Vector3.new(6, 0, -6), Vector3.new(-6, 0, 6), Vector3.new(6, 0, 6), Vector3.new(0, 0, -6), Vector3.new(0, 0, 6), Vector3.new(-6, 0, 0), Vector3.new(6, 0, 0) } do
		part(into, "SandcastleMerlon", Vector3.new(3.6, 3.6, 3.6), CFrame.new(sc + d + Vector3.new(0, 35.8, 0)), SAND, Enum.Material.Sandstone)
	end
	for k = 0, 5 do
		part(into, "Crate", Vector3.new(4, 4, 4), CFrame.new(sc + Vector3.new(-16 + (k % 3) * 4.2, 2 + math.floor(k / 3) * 4, 12)) * CFrame.Angles(0, math.rad(k * 7), 0), Color3.fromRGB(160, 120, 76), Enum.Material.WoodPlanks)
	end
	for k = -6, 6 do
		part(into, "Picket", Vector3.new(0.5, 3.4, 0.3), CFrame.new(sc + Vector3.new(k * 2.4, 1.7, -20)), Color3.fromRGB(240, 236, 226), Enum.Material.Wood, true)
	end
	part(into, "PicketRail", Vector3.new(31, 0.3, 0.3), CFrame.new(sc + Vector3.new(0, 2.6, -20)), Color3.fromRGB(240, 236, 226), Enum.Material.Wood, true)
	-- The yellow sandbox with a wooden rim.
	local sb = planAt(o, top, "Sandbox")
	part(into, "SandboxSand", Vector3.new(60, 0.6, 50), CFrame.new(sb + Vector3.new(0, 0.3, 0)), Color3.fromRGB(240, 200, 70), Enum.Material.Sand)
	for _, r in { { Vector3.new(62, 1.2, 1.2), Vector3.new(0, 0.6, 25.6) }, { Vector3.new(62, 1.2, 1.2), Vector3.new(0, 0.6, -25.6) }, { Vector3.new(1.2, 1.2, 52), Vector3.new(30.6, 0.6, 0) }, { Vector3.new(1.2, 1.2, 52), Vector3.new(-30.6, 0.6, 0) } } do
		part(into, "SandboxRim", r[1], CFrame.new(sb + r[2]), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
	end
	-- The round sand circle.
	part(into, "SandCircle", Vector3.new(0.4, 80, 80), CFrame.new(planAt(o, top, "SandCircle") + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), SAND, Enum.Material.Sand, false, Enum.PartType.Cylinder)
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
	part(into, "SeesawPlank", Vector3.new(26, 0.8, 3.4), CFrame.new(ss + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(9)), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
	-- THE GYRO CAGE: three steel rings on a pad, turning round each other, with a red button.
	local gc = planAt(o, top, "GyroCage")
	part(into, "GyroPad", Vector3.new(0.6, 46, 46), CFrame.new(gc + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 156, 150), Enum.Material.Concrete, false, Enum.PartType.Cylinder)
	local hub = gc + Vector3.new(0, 20, 0)
	part(into, "GyroStand", Vector3.new(2, 20, 2), CFrame.new(gc + Vector3.new(-19, 10, 0)), Color3.fromRGB(96, 110, 96), Enum.Material.Metal)
	part(into, "GyroStand", Vector3.new(2, 20, 2), CFrame.new(gc + Vector3.new(19, 10, 0)), Color3.fromRGB(96, 110, 96), Enum.Material.Metal)
	local rings: { { parts: { BasePart }, r: number, axis: Vector3, speed: number, base: { CFrame } } } = {}
	for i, spec in { { 17, Vector3.xAxis, 0.6 }, { 14, Vector3.zAxis, -0.9 }, { 11, Vector3.xAxis, 1.3 } } do
		local list, bases = {}, {}
		local n = 24
		for k = 1, n do
			local a = k / n * math.pi * 2
			local seg = 2 * math.pi * spec[1] / n + 0.3
			local cf = CFrame.Angles(0, 0, a) * CFrame.new(spec[1], 0, 0)
			local p = part(into, "GyroRing", Vector3.new(1.2, seg, 1.2), CFrame.new(hub) * cf, Color3.fromRGB(96, 116, 98), Enum.Material.Metal, true)
			p.CanCollide = false
			table.insert(list, p)
			table.insert(bases, cf)
		end
		table.insert(rings, { parts = list, r = spec[1], axis = spec[2], speed = spec[3], base = bases })
		local _ = i
	end
	part(into, "GyroButton", Vector3.new(0.8, 3, 3), CFrame.new(gc + Vector3.new(0, 1, 24)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 40, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	task.spawn(function()
		local t0 = os.clock()
		while into.Parent do
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
	local la, lb = planAt(o, top, "LavaStrip", -66, 0), planAt(o, top, "LavaStrip", 66, 0)
	local ll = (lb - la).Magnitude
	part(into, "TrenchStone", Vector3.new(ll + 12, 0.6, 46), CFrame.new((la + lb) / 2 + Vector3.new(0, 0.3, 0)), Color3.fromRGB(110, 106, 100), Enum.Material.Cobblestone)
	local lava = part(into, "LavaStrip", Vector3.new(ll, 0.4, 26), CFrame.new((la + lb) / 2 + Vector3.new(0, 0.5, 0)), Color3.fromRGB(255, 110, 30), Enum.Material.CrackedLava)
	lava.CanTouch = false
	for _, s in { -1, 1 } do
		part(into, "TrenchKerb", Vector3.new(ll + 12, 2, 3), CFrame.new((la + lb) / 2 + Vector3.new(0, 1, s * 22)), Color3.fromRGB(128, 124, 118), Enum.Material.Slate)
	end
	-- The turf square.
	part(into, "TurfSquare", Vector3.new(70, 0.3, 70), CFrame.new(planAt(o, top, "Gazebo") + Vector3.new(0, 0.15, 0)), Color3.fromRGB(70, 140, 60), Enum.Material.Fabric)
	-- THE TESLA COIL: a stepped column with a doughnut top and blue sparks.
	local tc = planAt(o, top, "TeslaCoil")
	part(into, "TeslaBase", Vector3.new(14, 4, 14), CFrame.new(tc + Vector3.new(0, 2, 0)), Color3.fromRGB(60, 62, 70), Enum.Material.Metal)
	part(into, "TeslaColumn", Vector3.new(28, 6, 6), CFrame.new(tc + Vector3.new(0, 18, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 120, 60), Enum.Material.Metal, false, Enum.PartType.Cylinder)
	local top2 = part(into, "TeslaTop", Vector3.new(4, 16, 16), CFrame.new(tc + Vector3.new(0, 34, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 204, 210), Enum.Material.Metal, false, Enum.PartType.Cylinder)
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
	part(into, "SweeperPad", Vector3.new(0.6, 90, 90), CFrame.new(sw + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 196, 186), Enum.Material.Concrete, false, Enum.PartType.Cylinder)
	part(into, "SweeperRing", Vector3.new(0.65, 92, 92), CFrame.new(sw + Vector3.new(0, 0.28, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
	part(into, "SweeperPost", Vector3.new(6, 6, 6), CFrame.new(sw + Vector3.new(0, 3, 0)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)
	local beamPart = part(into, "SweeperBeam", Vector3.new(84, 2.4, 2.4), CFrame.new(sw + Vector3.new(0, 2.4, 0)), Color3.fromRGB(230, 120, 30), Enum.Material.Metal)
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
	local PW, PD = 70, 26
	part(into, "ShredderFrame", Vector3.new(PW + 8, 1, PD + 8), CFrame.new(sp + Vector3.new(0, 0.5, 0)), Color3.fromRGB(160, 160, 158), Enum.Material.Concrete)
	local pit = part(into, "ShredderPit", Vector3.new(PW, 1.1, PD), CFrame.new(sp + Vector3.new(0, 0.55, 0)), Color3.fromRGB(26, 26, 28), Enum.Material.Slate)
	pit.CanCollide = false
	part(into, "ShredderFloor", Vector3.new(PW, 1, PD), CFrame.new(sp + Vector3.new(0, -8, 0)), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	for _, dz in { -5, 5 } do
		part(into, "ShredderRoller", Vector3.new(PW - 4, 7, 7), CFrame.new(sp + Vector3.new(0, -4, dz)), Color3.fromRGB(120, 124, 130), Enum.Material.DiamondPlate, false, Enum.PartType.Cylinder)
	end
	local corners = { Vector3.new(-PW / 2 - 3, 0, -PD / 2 - 3), Vector3.new(PW / 2 + 3, 0, -PD / 2 - 3), Vector3.new(PW / 2 + 3, 0, PD / 2 + 3), Vector3.new(-PW / 2 - 3, 0, PD / 2 + 3) }
	for i = 1, 4 do
		local a, b = sp + corners[i] + Vector3.new(0, 1, 0), sp + corners[i % 4 + 1] + Vector3.new(0, 1, 0)
		railing(into, a, b)
	end
	part(into, "ShredderLeverBox", Vector3.new(3, 4, 3), CFrame.new(sp + Vector3.new(PW / 2 + 8, 2, 0)), Color3.fromRGB(240, 200, 40), Enum.Material.Metal)
	part(into, "ShredderLever", Vector3.new(0.5, 4, 0.5), CFrame.new(sp + Vector3.new(PW / 2 + 8, 5.5, 0)) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal, true)
	part(into, "ShredderButton", Vector3.new(0.8, 3, 3), CFrame.new(sp + Vector3.new(PW / 2 + 8, 1, 6)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 40, 40), Enum.Material.SmoothPlastic, true, Enum.PartType.Cylinder)
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
	box(into, "LampPost", Vector3.new(0.5, 12, 0.5), CFrame.new(at + Vector3.new(0, 6, 0)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
	local head = box(into, "LampHead", Vector3.new(1.4, 0.6, 1.4), CFrame.new(at + Vector3.new(0, 12.2, 0)), Color3.fromRGB(250, 240, 200), Enum.Material.Neon, true)
	head.CanCollide = false
end
local function fill(into: Instance, o: Vector3, top: number)
	local S = LabOwnerMap.S
	local function at(x: number, z: number): Vector3
		return Vector3.new(o.X + x * S, top, o.Z + z * S)
	end
	-- The car park: an asphalt pad with bay lines and 6 parked cars.
	local cp = planAt(o, top, "CarPark")
	box(into, "CarParkPad", Vector3.new(86, 0.3, 46), CFrame.new(cp + Vector3.new(0, 0.15, 0)), Color3.fromRGB(70, 72, 76), Enum.Material.Asphalt)
	local colours = { Color3.fromRGB(200, 40, 40), Color3.fromRGB(40, 90, 180), Color3.fromRGB(230, 230, 230), Color3.fromRGB(30, 30, 34), Color3.fromRGB(220, 180, 40), Color3.fromRGB(120, 130, 140) }
	for k = 0, 5 do
		local x = -36 + k * 14.4
		box(into, "CarParkLine", Vector3.new(0.4, 0.05, 18), CFrame.new(cp + Vector3.new(x - 7.2, 0.33, -10)), Color3.fromRGB(235, 235, 230), Enum.Material.SmoothPlastic, true)
		car(into, cp + Vector3.new(x, 0.3, -10), 0, colours[k + 1])
	end
	-- A second, smaller pool with sun loungers and umbrellas.
	local pl = planAt(o, top, "LoungePool")
	box(into, "SmallPoolRim", Vector3.new(50, 1, 34), CFrame.new(pl + Vector3.new(0, 0.5, 0)), Color3.fromRGB(214, 212, 206), Enum.Material.Concrete)
	local w = box(into, "SmallPoolWater", Vector3.new(44, 0.4, 28), CFrame.new(pl + Vector3.new(0, 1.05, 0)), Color3.fromRGB(110, 190, 225), Enum.Material.Glass)
	w.Transparency = 0.2
	for k = -2, 2 do
		local l = pl + Vector3.new(k * 9, 0, 24)
		box(into, "Lounger", Vector3.new(3, 0.6, 7), CFrame.new(l + Vector3.new(0, 1.2, 0)), Color3.fromRGB(240, 240, 236), Enum.Material.Plastic)
		box(into, "LoungerBack", Vector3.new(3, 0.5, 3), CFrame.new(l + Vector3.new(0, 2, -3)) * CFrame.Angles(math.rad(-50), 0, 0), Color3.fromRGB(240, 240, 236), Enum.Material.Plastic, true)
		if k % 2 == 0 then
			box(into, "UmbrellaPole", Vector3.new(0.3, 8, 0.3), CFrame.new(l + Vector3.new(4.5, 4, 0)), Color3.fromRGB(200, 200, 200), Enum.Material.Metal, true)
			part(into, "Umbrella", Vector3.new(7, 1.2, 7), CFrame.new(l + Vector3.new(4.5, 8, 0)), if k == 0 then Color3.fromRGB(230, 70, 60) else Color3.fromRGB(60, 140, 220), Enum.Material.Fabric, true, Enum.PartType.Ball)
		end
	end
	-- The picnic and grill corner.
	local pc = planAt(o, top, "PicnicGrill")
	for k = 0, 3 do
		local t = pc + Vector3.new((k % 2) * 16 - 8, 0, math.floor(k / 2) * 14 - 7)
		box(into, "PicnicTable", Vector3.new(8, 0.5, 3.2), CFrame.new(t + Vector3.new(0, 2.6, 0)), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
		for _, s in { -1, 1 } do
			box(into, "PicnicBench", Vector3.new(8, 0.4, 1.2), CFrame.new(t + Vector3.new(0, 1.6, s * 2.6)), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
		end
	end
	box(into, "Grill", Vector3.new(4, 3, 2.4), CFrame.new(pc + Vector3.new(20, 1.5, 0)), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	-- The small playground: a slide, swings and a sandpit.
	local pg = planAt(o, top, "Playground")
	box(into, "PlaygroundMat", Vector3.new(50, 0.3, 40), CFrame.new(pg + Vector3.new(0, 0.15, 0)), Color3.fromRGB(200, 90, 70), Enum.Material.Rubber)
	box(into, "PlaySlideTower", Vector3.new(5, 7, 5), CFrame.new(pg + Vector3.new(-14, 3.5, 0)), Color3.fromRGB(60, 140, 220), Enum.Material.Plastic)
	box(into, "PlaySlide", Vector3.new(3.4, 0.5, 12), CFrame.new(pg + Vector3.new(-14, 3.6, 8.6)) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(250, 200, 40), Enum.Material.Plastic)
	box(into, "SwingFrame", Vector3.new(16, 0.6, 0.6), CFrame.new(pg + Vector3.new(10, 9, 0)), Color3.fromRGB(200, 60, 60), Enum.Material.Metal)
	for _, sx in { 2.5, 17.5 } do
		box(into, "SwingLeg", Vector3.new(0.6, 9, 0.6), CFrame.new(pg + Vector3.new(sx, 4.5, 0)), Color3.fromRGB(200, 60, 60), Enum.Material.Metal)
	end
	for _, sx in { 7, 13 } do
		box(into, "SwingRope", Vector3.new(0.15, 6, 0.15), CFrame.new(pg + Vector3.new(sx, 6, 0)), Color3.fromRGB(90, 70, 50), Enum.Material.Fabric, true)
		box(into, "SwingSeat", Vector3.new(2, 0.3, 1), CFrame.new(pg + Vector3.new(sx, 3, 0)), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber)
	end
	-- The training yard: tyres in two rows and hurdles.
	local ty = planAt(o, top, "TrainingYard")
	box(into, "TrainingDirt", Vector3.new(44, 0.3, 40), CFrame.new(ty + Vector3.new(0, 0.15, 0)), Color3.fromRGB(150, 120, 90), Enum.Material.Ground)
	for k = 0, 9 do
		part(into, "Tyre", Vector3.new(1.4, 4, 4), CFrame.new(ty + Vector3.new(-15 + (k % 5) * 5, 0.7, -8 + math.floor(k / 5) * 6)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(28, 28, 30), Enum.Material.Rubber, false, Enum.PartType.Cylinder)
	end
	for k = 0, 2 do
		box(into, "Hurdle", Vector3.new(8, 0.4, 0.4), CFrame.new(ty + Vector3.new(0, 2.4, 6 + k * 4)), Color3.fromRGB(240, 240, 240), Enum.Material.Plastic)
	end
	-- The parked train on the railway (west side).
	local tr = Vector3.new(o.X + LabOwnerMap.CENTER.X - LabOwnerMap.SIZE.X / 2 + 12, top, o.Z - 300) -- (on the west railway)
	for k = 0, 2 do
		local c = tr + Vector3.new(0, 0, k * 18)
		box(into, if k == 0 then "Locomotive" else "Wagon", Vector3.new(7, 7, 16), CFrame.new(c + Vector3.new(0, 4.6, 0)), if k == 0 then Color3.fromRGB(180, 40, 40) else Color3.fromRGB(70, 90, 120), Enum.Material.Metal)
		box(into, "WagonRoof", Vector3.new(7.4, 0.6, 16.4), CFrame.new(c + Vector3.new(0, 8.4, 0)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, true)
	end
	-- The hangar with open doors and a forklift (north-east corner).
	local hg = planAt(o, top, "Hangar")
	box(into, "HangarFloor", Vector3.new(60, 0.4, 44), CFrame.new(hg + Vector3.new(0, 0.2, 0)), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
	for _, s in { -1, 1 } do
		box(into, "HangarWall", Vector3.new(1.5, 22, 44), CFrame.new(hg + Vector3.new(s * 30, 11, 0)), Color3.fromRGB(170, 176, 180), Enum.Material.CorrodedMetal)
	end
	box(into, "HangarBack", Vector3.new(60, 22, 1.5), CFrame.new(hg + Vector3.new(0, 11, -22)), Color3.fromRGB(170, 176, 180), Enum.Material.CorrodedMetal)
	box(into, "HangarRoof", Vector3.new(63, 1.5, 47), CFrame.new(hg + Vector3.new(0, 22.75, 0)), Color3.fromRGB(140, 146, 150), Enum.Material.CorrodedMetal)
	box(into, "ForkliftBody", Vector3.new(4, 4, 6), CFrame.new(hg + Vector3.new(10, 2.4, 8)), Color3.fromRGB(240, 180, 30), Enum.Material.Metal)
	box(into, "ForkliftMast", Vector3.new(4, 8, 0.6), CFrame.new(hg + Vector3.new(10, 4.4, 11.4)), Color3.fromRGB(50, 50, 54), Enum.Material.Metal)
	-- The water tower (north-west) and the control tower (south-east).
	local wt = planAt(o, top, "WaterTower")
	for _, d in { Vector3.new(-5, 0, -5), Vector3.new(5, 0, -5), Vector3.new(-5, 0, 5), Vector3.new(5, 0, 5) } do
		box(into, "WaterTowerLeg", Vector3.new(1, 34, 1), CFrame.new(wt + d + Vector3.new(0, 17, 0)), Color3.fromRGB(110, 110, 114), Enum.Material.Metal)
	end
	part(into, "WaterTowerTank", Vector3.new(14, 16, 16), CFrame.new(wt + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(196, 196, 190), Enum.Material.Metal, false, Enum.PartType.Cylinder)
	local ct = planAt(o, top, "ControlTower")
	box(into, "ControlTowerShaft", Vector3.new(10, 40, 10), CFrame.new(ct + Vector3.new(0, 20, 0)), Color3.fromRGB(220, 220, 216), Enum.Material.Concrete)
	local cab = box(into, "ControlTowerCab", Vector3.new(16, 7, 16), CFrame.new(ct + Vector3.new(0, 43.5, 0)), Color3.fromRGB(80, 110, 130), Enum.Material.Glass)
	cab.Transparency = 0.25
	box(into, "ControlTowerRoof", Vector3.new(18, 1, 18), CFrame.new(ct + Vector3.new(0, 47.5, 0)), Color3.fromRGB(60, 62, 66), Enum.Material.Metal)
	-- Portable toilets and a snack kiosk (north, by the aquarium).
	local wc = planAt(o, top, "SnackKiosk", 4, 12)
	for k = 0, 2 do
		box(into, "Toilet", Vector3.new(4, 8, 4), CFrame.new(wc + Vector3.new(k * 4.6, 4, 0)), Color3.fromRGB(60, 140, 210), Enum.Material.Plastic)
	end
	local ki = planAt(o, top, "SnackKiosk", 0, -4)
	box(into, "Kiosk", Vector3.new(12, 8, 8), CFrame.new(ki + Vector3.new(0, 4, 0)), Color3.fromRGB(240, 220, 170), Enum.Material.WoodPlanks)
	box(into, "KioskAwning", Vector3.new(13, 0.4, 4), CFrame.new(ki + Vector3.new(0, 8, 5)) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(220, 60, 60), Enum.Material.Fabric, true)
	-- (Map round 3, rule 4) Lamps only along the road edges: 2 studs outside the kerb, every 32 studs, alternating
	-- sides; none within 10 studs of a plaza or junction (the spawn, the fountain, the squares).
	for _, r in Plan.ROADS do
		if r.width >= 16 then
			for i = 1, #r.points - 1 do
				local a, b = r.points[i], r.points[i + 1]
				local len = (b - a).Magnitude
				local dir = (b - a).Unit
				local side = Vector2.new(-dir.Y, dir.X)
				local k = 0
				for s = 24, len - 24, 32 do
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
local function plantTree(into: Instance, kind: string, at: Vector3, height: number, rng: Random, noTrunk: boolean?)
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
local function arch(into: Instance, at: Vector3, alongX: boolean, name: string)
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
	h.CastShadow = false
end
local function flowerBed(into: Instance, at: Vector3, w: number, d: number, rng: Random)
	part(into, "FlowerBedSoil", Vector3.new(w, 0.6, d), CFrame.new(at + Vector3.new(0, 0.3, 0)), Color3.fromRGB(96, 70, 50), Enum.Material.Ground, true)
	part(into, "FlowerBedEdge", Vector3.new(w + 1, 0.8, d + 1), CFrame.new(at + Vector3.new(0, 0.2, 0)), Color3.fromRGB(190, 190, 186), Enum.Material.Concrete, true)
	for k = 1, math.floor(w * d / 18) do
		local p = at + Vector3.new(rng:NextNumber(-w / 2 + 1, w / 2 - 1), 1, rng:NextNumber(-d / 2 + 1, d / 2 - 1))
		part(into, "Flower", Vector3.new(1.4, 1.2, 1.4), CFrame.new(p), FLOWER[rng:NextInteger(1, #FLOWER)], Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		local _ = k
	end
end
local function parks(into: Instance, o: Vector3, top: number)
	local rng = Random.new(23)
	local function w(x: number, z: number): Vector3
		return Vector3.new(o.X + x, top, o.Z + z)
	end
	-- Boulevard trees, both sides, outside the lamps.
	for z = -262, -78, 26 do
		for _, sx in { -1, 1 } do
			plantTree(into, if (z // 26) % 2 == 0 then "TreePoplar" else "TreeOak", w(-30 + sx * 30, z), rng:NextNumber(20, 26), rng, false)
		end
	end
	-- The open areas: hedges along their road sides, flower beds, trees, benches.
	for _, id in { "GardensN", "LawnsMid", "PicnicPark" } do
		local room = Plan.ROOMS[id]
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
				part(into, "BenchSeat", Vector3.new(7, 0.5, 2), CFrame.new(w(x - sx * 14, z) + Vector3.new(0, 1.6, 0)), Color3.fromRGB(140, 100, 64), Enum.Material.WoodPlanks)
			end
		end
	end
	-- Flower beds along the front of the spawn plaza.
	for _, sx in { -1, 1 } do
		flowerBed(into, w(-30 + sx * 50, -274), 30, 6, rng)
	end
	-- THE DUCK POND (Picnic Park).
	local dp = planAt(o, top, "DuckPond")
	local water = part(into, "DuckPondWater", Vector3.new(0.4, 40, 40), CFrame.new(dp + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 150, 190), Enum.Material.Glass, false, Enum.PartType.Cylinder)
	water.Transparency = 0.15
	part(into, "DuckPondRim", Vector3.new(0.6, 43, 43), CFrame.new(dp + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 140, 120), Enum.Material.Cobblestone, true, Enum.PartType.Cylinder)
	for k = 1, 4 do
		local a = k * 1.6
		local p = dp + Vector3.new(math.cos(a) * 10, 0.8, math.sin(a) * 10)
		part(into, "DuckBody", Vector3.new(1.6, 1.1, 2.4), CFrame.new(p) * CFrame.Angles(0, a, 0), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		part(into, "DuckHead", Vector3.new(0.9, 0.9, 0.9), CFrame.new(p) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.8, -1), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
		part(into, "DuckBeak", Vector3.new(0.4, 0.3, 0.5), CFrame.new(p) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.75, -1.6), Color3.fromRGB(255, 160, 40), Enum.Material.SmoothPlastic, true)
	end
	-- THE GAZEBO in its flower garden.
	local gz = planAt(o, top, "Gazebo")
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
	-- THE DOG YARD fence round the doghouse.
	local dy = planAt(o, top, "DogYard")
	local half = 15
	local corners = { Vector3.new(-half, 0, -half), Vector3.new(half, 0, -half), Vector3.new(half, 0, half), Vector3.new(-half, 0, half) }
	for i = 1, 4 do
		local a, b = dy + corners[i], dy + corners[i % 4 + 1]
		if i ~= 4 then -- (the west side stays open: the yard faces the road)
			part(into, "DogFence", Vector3.new(0.4, 3, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 1.5, 0), b + Vector3.new(0, 1.5, 0)), Color3.fromRGB(240, 236, 226), Enum.Material.Wood)
		end
	end
	part(into, "DogYardGrass", Vector3.new(30, 0.2, 30), CFrame.new(dy + Vector3.new(0, 0.1, 0)), Color3.fromRGB(100, 160, 80), Enum.Material.Grass, true)
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
		local at = mid + Vector3.new(math.cos(a) * (size.X / 2 + 650), 40 + (i % 3) * 30, math.sin(a) * (size.Y / 2 + 650))
		pcall(function()
			terrain:FillBall(at, 210 + (i % 4) * 40, Enum.Material.Rock)
			terrain:FillBall(at - Vector3.new(0, 90, 0), 260, Enum.Material.Grass)
		end)
	end
end

-- M7: the old lab frame goes (the LAB10 compound and park, the plot's floor, spawn disc, edges, barriers, cones, signs and
-- the zone pads): invisible and walked through, the new ground is under it.
LabOwnerMap.HIDE_IN_LAB = { LabV10 = true, LabZonePads = true, ZonePads = true, LabGarden = true, Paths = true }
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

function LabOwnerMap.build(folder: Instance, origin: Vector3)
	hideOld(folder, origin)
	-- (M7: the 4 leaderboards stand in a row on the raised plaza, facing the stair; LeaderboardService makes them a little
	-- later, so this waits for them.)
	task.spawn(function()
		local S = LabOwnerMap.S
		local pz = -360 -- (map round 3: OwnerMapPlan Leaderboards, the back of the spawn plaza)
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
					local x = (i - (#boards + 1) / 2) * 30
					local at = Vector3.new(origin.X - 30 + x, origin.Y + 4 + size.Y / 2, origin.Z + pz)
					b:PivotTo(CFrame.lookAt(at, at - Vector3.new(0, 0, 1))) -- (their faces to the stair, south)
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
	belts(into, origin, origin.Y - 0.05)
	parks(into, origin, origin.Y - 0.05)
	hills(origin)
end

return LabOwnerMap
