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
LabOwnerMap.SIZE = Vector2.new(950, 820)
LabOwnerMap.CENTER = Vector2.new(-30, 24) -- (lab space: the plan runs x -150..130, z -105..120, times S)
LabOwnerMap.WALK = 22 -- walkway width

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

-- M1: the ground.
local function ground(into: Instance, o: Vector3)
	local S = LabOwnerMap.S
	local c = LabOwnerMap.CENTER
	local size = LabOwnerMap.SIZE
	local top = o.Y - 0.05 -- (just under the old floor, so nothing flickers while both are there)
	part(into, "OwnerGrass", Vector3.new(size.X, 2, size.Y), CFrame.new(o.X + c.X, top - 1, o.Z + c.Y), GRASS, Enum.Material.Grass)
	local W = LabOwnerMap.WALK
	local x0, x1 = c.X - size.X / 2 + 20, c.X + size.X / 2 - 20
	local z0, z1 = c.Y - size.Y / 2 + 20, c.Y + size.Y / 2 - 20
	-- The walkway grid (ref_10): rows between the plan's rows, columns between its zones.
	for _, z in { -82 * S, -18 * S, 58 * S, 104 * S } do
		part(into, "OwnerWalk", Vector3.new(x1 - x0, 0.3, W), CFrame.new(o.X + (x0 + x1) / 2, top + 0.15, o.Z + z), WALK, Enum.Material.Pavement)
	end
	for _, x in { -100 * S, -55 * S, 0, 28 * S, 68 * S, 112 * S } do
		part(into, "OwnerWalk", Vector3.new(W, 0.3, z1 - z0), CFrame.new(o.X + x, top + 0.14, o.Z + (z0 + z1) / 2), WALK, Enum.Material.Pavement)
	end
	-- The spawn circle (white, round) where the central walkway meets the tower row.
	part(into, "OwnerSpawnCircle", Vector3.new(0.4, 26 * S, 26 * S), CFrame.new(o.X, top + 0.2, o.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(226, 226, 222), Enum.Material.Pavement, false, Enum.PartType.Cylinder)
	-- The raised leaderboard plaza (north, on the central walkway): granite wall, light cap, pipe railing, a stair down
	-- to the south.
	local pz = -95 * S
	local pw, pd, ph = 50 * S, 26 * S, 5
	local plaza = part(into, "OwnerPlaza", Vector3.new(pw, ph, pd), CFrame.new(o.X, top + ph / 2, o.Z + pz), GRANITE, Enum.Material.Slate)
	plaza:SetAttribute("OwnerPlaza", true)
	part(into, "OwnerPlazaTop", Vector3.new(pw - 2, 0.3, pd - 2), CFrame.new(o.X, top + ph + 0.15, o.Z + pz), CAP, Enum.Material.Pavement)
	for _, side in { -1, 1 } do
		part(into, "OwnerPlazaCap", Vector3.new(pw + 1, 0.6, 1.6), CFrame.new(o.X, top + ph + 0.3, o.Z + pz + side * (pd / 2)), CAP, Enum.Material.Concrete, true)
		part(into, "OwnerPlazaCap", Vector3.new(1.6, 0.6, pd + 1), CFrame.new(o.X + side * (pw / 2), top + ph + 0.3, o.Z + pz), CAP, Enum.Material.Concrete, true)
	end
	-- The pipe railing on the three closed sides (the stair side stays open in its middle).
	local railY = top + ph + 3.4
	local function railRun(a: Vector3, b: Vector3)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		part(into, "OwnerRail", Vector3.new(len, 0.35, 0.35), CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0), STEEL, Enum.Material.Metal, true)
		local posts = math.max(1, math.floor(len / 8))
		for i = 0, posts do
			local at = a:Lerp(b, i / posts)
			part(into, "OwnerRailPost", Vector3.new(0.3, 3.2, 0.3), CFrame.new(at.X, top + ph + 1.7, at.Z), STEEL, Enum.Material.Metal, true)
		end
	end
	local hx, hz = pw / 2 - 1, pd / 2 - 1
	railRun(Vector3.new(o.X - hx, railY, o.Z + pz - hz), Vector3.new(o.X + hx, railY, o.Z + pz - hz))
	railRun(Vector3.new(o.X - hx, railY, o.Z + pz - hz), Vector3.new(o.X - hx, railY, o.Z + pz + hz))
	railRun(Vector3.new(o.X + hx, railY, o.Z + pz - hz), Vector3.new(o.X + hx, railY, o.Z + pz + hz))
	railRun(Vector3.new(o.X - hx, railY, o.Z + pz + hz), Vector3.new(o.X - 14, railY, o.Z + pz + hz))
	railRun(Vector3.new(o.X + 14, railY, o.Z + pz + hz), Vector3.new(o.X + hx, railY, o.Z + pz + hz))
	-- The stair (south side, as wide as the walkway).
	local steps = 6
	for i = 1, steps do
		local h = ph * (steps - i + 1) / (steps + 1)
		part(into, "OwnerPlazaStep", Vector3.new(24, h, 2), CFrame.new(o.X, top + h / 2, o.Z + pz + pd / 2 + (i - 0.5) * 2), CAP, Enum.Material.Concrete)
	end
	-- The railway: a loop down the west side, round the south-west corner and along the south (ref_1, ref_10).
	local pts = {
		Vector2.new(-125 * S, -120 * S), Vector2.new(-128 * S, -40 * S), Vector2.new(-130 * S, 40 * S),
		Vector2.new(-122 * S, 100 * S), Vector2.new(-95 * S, 125 * S), Vector2.new(-30 * S, 132 * S), Vector2.new(60 * S, 132 * S),
	}
	for i = 1, #pts - 1 do
		local a = Vector3.new(o.X + pts[i].X, top, o.Z + pts[i].Y)
		local b = Vector3.new(o.X + pts[i + 1].X, top, o.Z + pts[i + 1].Y)
		local len = (b - a).Magnitude
		local along = CFrame.lookAt((a + b) / 2, b)
		part(into, "OwnerBallast", Vector3.new(9, 0.5, len + 4), along * CFrame.new(0, 0.25, 0), BALLAST, Enum.Material.Pebble, true)
		for _, side in { -1, 1 } do
			part(into, "OwnerRail", Vector3.new(0.4, 0.5, len + 4), along * CFrame.new(side * 2.4, 1, 0), RAIL, Enum.Material.Metal, true)
		end
		local n = math.floor(len / 6)
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
		local rx, rz = LabOwnerMap.SIZE.X / 2 + 110, LabOwnerMap.SIZE.Y / 2 + 110
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
	local c = Vector3.new(o.X + LabOwnerMap.TOWER_AT.X * S, top, o.Z + LabOwnerMap.TOWER_AT.Y * S)
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
		c + Vector3.new(-h - 40, roofY - top - 26, 0),
		c + Vector3.new(-h - 80, roofY - top - 52, 30),
		c + Vector3.new(-h - 104, roofY - top - 72, 80),
		c + Vector3.new(-h - 112, 2.5, 140),
		c + Vector3.new(-h - 114, 0.6, 170),
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
	local to = Vector3.new(o.X + 50 * S, top + 0.4, o.Z + 32 * S)
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
	local g = Vector3.new(o.X + 5 * S, top, o.Z + 78 * S)
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
			hide(c)
		end
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
		local pz = -95 * S
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
					local at = Vector3.new(origin.X + x, origin.Y + 5 + size.Y / 2, origin.Z + pz - 18)
					b:PivotTo(CFrame.lookAt(at, at - Vector3.new(0, 0, 1))) -- (their faces to the stair, south)
					local _, newSize = b:GetBoundingBox()
					local cf2 = b:GetBoundingBox()
					b:PivotTo(b:GetPivot() + Vector3.new(0, (origin.Y + 5.3) - (cf2.Position.Y - newSize.Y / 2), 0))
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
	hills(origin)
end

return LabOwnerMap
