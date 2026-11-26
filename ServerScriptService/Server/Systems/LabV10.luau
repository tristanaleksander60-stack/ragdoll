--!strict
-- LAB 10/10 (owner, 26 Nov 2026: "Hele labbet skal tages fra 2/10 til 10/10, ikke vær bange for at ændre
-- ALT"; docs/LAB10.md): the CRASH TEST LAB frame over a player's lab, built last by Playground.build when
-- Config.LAB_V10 is on. Where the machines and creatures stand is Shared/LabLayout10 (their own builders
-- read it); this adds the compound round them and takes away what made the old lab look like a junkyard:
--   - the floor in warm light concrete (was green tiles), the plain white spawn disc gone;
--   - the TEST FLOOR: a darker round floor with a yellow rim and painted rings, the dummies on it;
--   - the SPAWN PAD: a raised black-and-orange pad with an arrow to the test floor;
--   - WALKWAYS from the test floor and the spawn to every zone (flat, each layer at its own height: no flicker);
--   - the COMPOUND WALL: concrete with a yellow-black hazard cap, gates south, west and east;
--   - a SKYLINE outside: hangars, a teal control tower and a water tower;
--   - the tower in lab white with a hazard crown, the crash wall padded orange;
--   - hidden: the edge lines, barriers and cones of the plot, the trees and rocks inside the wall.
-- One style, max six colours (LabLayout10.COLORS). Nothing here does anything to play.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local L = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LabLayout10")) :: any

local LabV10 = {}

local C = L.COLORS

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = into
	return p
end

-- A flat painted layer (no collisions, no shadow, out of rays): the floor under it carries you.
local function paint(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = part(into, name, size, cf, color, Enum.Material.SmoothPlastic, shape)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

-- A flat disc of radius r, its top `top` studs over y.
local function disc(into: Instance, name: string, at: Vector3, r: number, thick: number, color: Color3): Part
	return paint(into, name, Vector3.new(thick, r * 2, r * 2), CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
end

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

-- This lab's plot folder (Labs/LabN: its floor and edge), the one under this origin.
local function plotOf(origin: Vector3): Instance?
	local labs = Workspace:FindFirstChild("Labs")
	for _, plot in if labs then labs:GetChildren() else {} do
		local floorPart = plot:FindFirstChild("LabFloor", true)
		if floorPart and floorPart:IsA("BasePart") and math.abs(floorPart.Position.X - origin.X) < 60 then
			return plot
		end
	end
	return nil
end

-- The compound wall: concrete with a hazard cap of yellow and black blocks, open at the gates.
local WALL_H = 6
local WALL_T = 2.4
local CAP = 6 -- studs per hazard block
local function wall(into: Instance, origin: Vector3, floorY: number)
	local w = L.WALL
	local sides = {
		{ side = "N", a = Vector3.new(w.minX, 0, w.minZ), b = Vector3.new(w.maxX, 0, w.minZ) },
		{ side = "S", a = Vector3.new(w.minX, 0, w.maxZ), b = Vector3.new(w.maxX, 0, w.maxZ) },
		{ side = "W", a = Vector3.new(w.minX, 0, w.minZ), b = Vector3.new(w.minX, 0, w.maxZ) },
		{ side = "E", a = Vector3.new(w.maxX, 0, w.minZ), b = Vector3.new(w.maxX, 0, w.maxZ) },
	}
	for _, s in sides do
		local along = (s.b - s.a).Unit
		local length = (s.b - s.a).Magnitude
		-- The open stretches of this side, from its start (a): gaps at its gates.
		local cuts: { { number } } = {}
		for _, g in L.GATES do
			if g.side == s.side then
				local at = if s.side == "N" or s.side == "S" then g.at - w.minX else g.at - w.minZ
				table.insert(cuts, { at - g.width / 2, at + g.width / 2 })
			end
		end
		table.sort(cuts, function(x, y)
			return x[1] < y[1]
		end)
		local runs: { { number } } = {}
		local from = 0
		for _, c in cuts do
			table.insert(runs, { from, c[1] })
			from = c[2]
		end
		table.insert(runs, { from, length })
		for _, run in runs do
			local len = run[2] - run[1]
			if len > 0.5 then
				local mid = s.a + along * (run[1] + run[2]) / 2
				local look = CFrame.lookAt(origin + Vector3.new(mid.X, floorY - origin.Y + WALL_H / 2, mid.Z), origin + Vector3.new(mid.X, floorY - origin.Y + WALL_H / 2, mid.Z) + along)
				part(into, "CompoundWall", Vector3.new(WALL_T, WALL_H, len + WALL_T), look, C.concrete, Enum.Material.Concrete)
				-- The hazard cap: blocks of yellow and black along the top.
				local n = math.max(1, math.floor(len / CAP + 0.5))
				local step = len / n
				for i = 0, n - 1 do
					local c = s.a + along * (run[1] + step * (i + 0.5))
					local cf = CFrame.lookAt(origin + Vector3.new(c.X, floorY - origin.Y + WALL_H + 0.45, c.Z), origin + Vector3.new(c.X, floorY - origin.Y + WALL_H + 0.45, c.Z) + along)
					local p = part(into, "HazardCap", Vector3.new(WALL_T + 0.3, 0.9, step), cf, if i % 2 == 0 then C.yellow else C.black)
					p.CastShadow = false
				end
				-- Gate posts at each end that opens onto a gate.
				for _, e in { run[1], run[2] } do
					if e > 0.5 and e < length - 0.5 then
						local c = s.a + along * e
						local post = part(into, "GatePost", Vector3.new(3.4, WALL_H + 3, 3.4), CFrame.new(origin + Vector3.new(c.X, floorY - origin.Y + (WALL_H + 3) / 2, c.Z)), C.orange, Enum.Material.SmoothPlastic)
						part(into, "GatePostCap", Vector3.new(3.8, 0.8, 3.8), post.CFrame * CFrame.new(0, (WALL_H + 3) / 2 + 0.4, 0), C.black)
					end
				end
			end
		end
	end
end

-- A walkway: a darker concrete strip with yellow edge lines, from a to b (lab space, y ignored).
local function walkway(into: Instance, origin: Vector3, floorY: number, a: Vector2, b: Vector2, width: number)
	local d = b - a
	local len = d.Magnitude
	if len < 1 then
		return
	end
	local mid = (a + b) / 2
	local base = CFrame.lookAt(Vector3.new(origin.X + mid.X, floorY, origin.Z + mid.Y), Vector3.new(origin.X + b.X, floorY, origin.Z + b.Y))
	paint(into, "Walkway", Vector3.new(width, 0.1, len), base * CFrame.new(0, 0.05, 0), C.concreteDark)
	for _, side in { -1, 1 } do
		paint(into, "WalkwayLine", Vector3.new(0.5, 0.1, len), base * CFrame.new(side * (width / 2 - 0.45), 0.09, 0), C.yellow)
	end
	-- (R2: yellow chevrons along it, pointing the way of the tour.)
	local z = -len / 2 + 7
	while z < len / 2 - 4 do
		for _, side in { -1, 1 } do
			paint(into, "WalkwayArrow", Vector3.new(0.6, 0.06, 2.4), base * CFrame.new(side * 0.8, 0.13, -z) * CFrame.Angles(0, math.rad(side * 40), 0), C.yellow)
		end
		z += 12
	end
end

-- A hangar outside the wall: a long white shed with a rounded teal roof and a big dark door.
local function hangar(into: Instance, at: CFrame, w: number, d: number, h: number)
	part(into, "Hangar", Vector3.new(w, h, d), at * CFrame.new(0, h / 2, 0), C.white, Enum.Material.SmoothPlastic)
	-- (A barrel roof: a cylinder as wide as the shed, sunk so a quarter of it shows over the walls.)
	part(into, "HangarRoof", Vector3.new(d, w, w), at * CFrame.new(0, h - w * 0.25, 0) * CFrame.Angles(0, math.rad(90), 0), C.teal, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	part(into, "HangarDoor", Vector3.new(w * 0.6, h * 0.75, 0.4), at * CFrame.new(0, h * 0.375, d / 2 + 0.1), C.black)
	part(into, "HangarStripe", Vector3.new(w + 0.2, 0.9, d + 0.2), at * CFrame.new(0, h - 0.6, 0), C.yellow)
end

local function waterTower(into: Instance, at: CFrame)
	for _, o in { Vector3.new(-4, 0, -4), Vector3.new(4, 0, -4), Vector3.new(-4, 0, 4), Vector3.new(4, 0, 4) } do
		part(into, "TowerLeg", Vector3.new(1, 26, 1), at * CFrame.new(o.X, 13, o.Z), C.black, Enum.Material.Metal)
	end
	part(into, "WaterTank", Vector3.new(12, 13, 13), at * CFrame.new(0, 32, 0) * CFrame.Angles(0, 0, math.rad(90)), C.white, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	part(into, "WaterBand", Vector3.new(2, 13.3, 13.3), at * CFrame.new(0, 31, 0) * CFrame.Angles(0, 0, math.rad(90)), C.orange, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	part(into, "WaterCap", Vector3.new(3, 9, 9), at * CFrame.new(0, 39.5, 0) * CFrame.Angles(0, 0, math.rad(90)), C.teal, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
end

local function controlTower(into: Instance, at: CFrame)
	part(into, "ControlShaft", Vector3.new(8, 34, 8), at * CFrame.new(0, 17, 0), C.white, Enum.Material.SmoothPlastic)
	local glass = part(into, "ControlGlass", Vector3.new(14, 6, 14), at * CFrame.new(0, 37, 0), C.teal, Enum.Material.Glass)
	glass.Transparency = 0.15
	part(into, "ControlRoof", Vector3.new(16, 1.4, 16), at * CFrame.new(0, 40.7, 0), C.black)
	part(into, "ControlBand", Vector3.new(14.4, 1, 14.4), at * CFrame.new(0, 33.6, 0), C.orange)
end

---------------------------------------------------------------------------------------------------
-- LAB TARGET (owner, 26 Nov 2026; docs/LAB_TARGET.md, Config.LAB_PARK): the realistic park look over the
-- same spots. A light concrete field with tile joints; a GRASS PLOT with a concrete kerb under every
-- attraction (so each one fills its own plot and the concrete between them is the walkway); a raised spawn
-- plaza with a wooden railing, a wide ramp and the 4 boards (LeaderboardService); the tower in galvanised
-- steel; a railway round it all; tree groups and boulders outside. Calm natural colours, no painted stripes.
local GRASS = Color3.fromRGB(104, 146, 70)
local KERB = Color3.fromRGB(188, 186, 180)
local TILE = Color3.fromRGB(214, 212, 206)
local STEEL = Color3.fromRGB(138, 143, 148)
local WOOD = Color3.fromRGB(120, 86, 58)
local GRAVEL = Color3.fromRGB(128, 124, 118)

-- The axis-aligned XZ box (lab space) of everything visible in a list of instances.
local function boxOf(list: { Instance }, origin: Vector3): (Vector2?, Vector2?)
	local mn: Vector2? = nil
	local mx: Vector2? = nil
	for _, inst in list do
		local parts = if inst:IsA("BasePart") then { inst } else inst:GetDescendants()
		for _, p in parts do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local cf, s = p.CFrame, p.Size
				local hx = math.abs(cf.RightVector.X) * s.X / 2 + math.abs(cf.UpVector.X) * s.Y / 2 + math.abs(cf.LookVector.X) * s.Z / 2
				local hz = math.abs(cf.RightVector.Z) * s.X / 2 + math.abs(cf.UpVector.Z) * s.Y / 2 + math.abs(cf.LookVector.Z) * s.Z / 2
				local a = Vector2.new(p.Position.X - origin.X - hx, p.Position.Z - origin.Z - hz)
				local b = Vector2.new(p.Position.X - origin.X + hx, p.Position.Z - origin.Z + hz)
				mn = if mn then mn:Min(a) else a
				mx = if mx then mx:Max(b) else b
			end
		end
	end
	return mn, mx
end

local LOOSE: { [string]: { [string]: boolean } } = {
	Tower = { Stair = true, StairEdge = true, Tower = true, TowerBand = true, TowerStripe = true, Plank = true, TrampolineBase = true, TrampolinePad = true },
	Wrecking = { Post = true, Beam = true, Walkway = true, SwingArm = true, SwingBall = true, BallBand = true, Lug = true, LugPin = true, Leg = true, Footing = true, Brace = true, BeamWeb = true, BeamFlange = true, Pulley = true, RunStripe = true },
	Stations = { StationPad = true, StationRail = true, StationWall = true, CrashWallBadge = true },
	Cannon = { CannonPad = true, CannonArrow = true, CannonBarrel = true, CannonStand = true },
}

local function park(into: Instance, folder: Instance, origin: Vector3, floorY: number, floorPart: BasePart?)
	local V3Assets = require(script.Parent:WaitForChild("V3Assets")) :: any
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	-- The field: light concrete with big tile joints.
	if floorPart then
		floorPart.Color = TILE
		floorPart.Material = Enum.Material.SmoothPlastic
		local tex = floorPart:FindFirstChildOfClass("Texture")
		if not tex and Config.LAYOUT_V3_FLOOR then
			local made = Instance.new("Texture")
			made.Texture = Config.LAYOUT_V3_FLOOR.texture
			made.Face = Enum.NormalId.Top
			made.Parent = floorPart
			tex = made
		end
		if tex then
			tex.Color3 = Color3.new(1, 1, 1)
			tex.Transparency = 0.25
			tex.StudsPerTileU = 10
			tex.StudsPerTileV = 10
		end
	end

	-- A grass plot with a kerb under every attraction.
	local groups: { { Instance } } = {}
	local yard = folder:FindFirstChild("CreatureYard")
	for _, c in if yard then yard:GetChildren() else {} do
		if c.Name ~= "YardGrass" then
			table.insert(groups, { c })
		end
	end
	for _, n in { "Vehicles", "BoxingPit", "StretchMachine", "CannonModel", "MegaTrampoline", "GiantFan" } do
		local c = folder:FindFirstChild(n)
		if c then
			table.insert(groups, { c })
		end
	end
	local dress = folder:FindFirstChild("Dress")
	for _, n in { "Rocket", "MechArmsStand" } do
		local c = dress and dress:FindFirstChild(n)
		if c then
			table.insert(groups, { c })
		end
	end
	for key, names in LOOSE do
		local list: { Instance } = {}
		for _, c in folder:GetChildren() do
			if c:IsA("BasePart") and names[c.Name] then
				table.insert(list, c)
			end
		end
		if key == "Tower" then
			local heights = folder:FindFirstChild("Heights")
			if heights then
				table.insert(list, heights)
			end
		end
		if #list > 0 then
			table.insert(groups, list)
		end
	end
	for i, list in groups do
		local mn, mx = boxOf(list, origin)
		if mn and mx then
			mn -= Vector2.new(4, 4)
			mx += Vector2.new(4, 4)
			local size = mx - mn
			local mid = (mn + mx) / 2
			local top = floorY + 0.1 + i * 0.004
			local grass = paint(into, "GrassPlot", Vector3.new(size.X, 0.2, size.Y), CFrame.new(origin.X + mid.X, top - 0.1, origin.Z + mid.Y), GRASS)
			grass.Material = Enum.Material.Grass
			for _, e in {
				{ Vector3.new(size.X + 1, 0.4, 1), Vector3.new(0, 0, -size.Y / 2) },
				{ Vector3.new(size.X + 1, 0.4, 1), Vector3.new(0, 0, size.Y / 2) },
				{ Vector3.new(1, 0.4, size.Y + 1), Vector3.new(-size.X / 2, 0, 0) },
				{ Vector3.new(1, 0.4, size.Y + 1), Vector3.new(size.X / 2, 0, 0) },
			} do
				paint(into, "PlotKerb", e[1], CFrame.new(Vector3.new(origin.X + mid.X, top + 0.05, origin.Z + mid.Y) + e[2]), KERB)
			end
		end
	end

	-- The TEST FLOOR: a plain concrete circle with one painted white ring.
	local tf = Vector3.new(origin.X + L.TEST_FLOOR.X, floorY, origin.Z + L.TEST_FLOOR.Y)
	local r = L.TEST_RADIUS
	disc(into, "TestFloor", tf + Vector3.new(0, 0.05, 0), r, 0.1, Color3.fromRGB(196, 194, 188))
	disc(into, "TestRing", tf + Vector3.new(0, 0.08, 0), r - 1, 0.1, Color3.fromRGB(240, 240, 236))
	disc(into, "TestRingInner", tf + Vector3.new(0, 0.11, 0), r - 1.8, 0.1, Color3.fromRGB(196, 194, 188))

	-- The raised SPAWN PLAZA with a wooden railing (back and sides) and a wide ramp to the lab.
	local P = L.PLAZA
	local pSize = P.max - P.min
	local pMid = (P.min + P.max) / 2
	local slab = part(into, "SpawnPlaza", Vector3.new(pSize.X, P.height, pSize.Y), CFrame.new(origin.X + pMid.X, floorY + P.height / 2, origin.Z + pMid.Y), TILE, Enum.Material.SmoothPlastic)
	if Config.LAYOUT_V3_FLOOR then
		local t = Instance.new("Texture")
		t.Texture = Config.LAYOUT_V3_FLOOR.texture
		t.Face = Enum.NormalId.Top
		t.StudsPerTileU = 8
		t.StudsPerTileV = 8
		t.Transparency = 0.2
		t.Parent = slab
	end
	part(into, "SpawnPlazaEdge", Vector3.new(pSize.X + 0.4, 0.5, pSize.Y + 0.4), CFrame.new(origin.X + pMid.X, floorY + 0.25, origin.Z + pMid.Y), KERB, Enum.Material.Concrete).CanCollide = false
	local ramp = Instance.new("WedgePart")
	ramp.Name = "SpawnRamp"
	ramp.Anchored = true
	ramp.Size = Vector3.new(P.stairWidth, P.height, P.stairRun)
	ramp.CFrame = CFrame.new(origin.X + pMid.X, floorY + P.height / 2, origin.Z + P.min.Y - P.stairRun / 2)
	ramp.Color = TILE
	ramp.Material = Enum.Material.SmoothPlastic
	ramp.Parent = into
	local railTop = floorY + P.height + 3
	local function railRun(a: Vector3, b: Vector3)
		local len = (b - a).Magnitude
		local n = math.max(1, math.floor(len / 6))
		for k = 0, n do
			local p = a:Lerp(b, k / n)
			part(into, "RailPost", Vector3.new(0.5, 3, 0.5), CFrame.new(p.X, floorY + P.height + 1.5, p.Z), WOOD, Enum.Material.Wood)
		end
		for _, h in { 1.4, 2.8 } do
			local mid = (a + b) / 2
			part(into, "RailBar", Vector3.new(0.35, 0.35, len), CFrame.lookAt(Vector3.new(mid.X, floorY + P.height + h, mid.Z), Vector3.new(b.X, floorY + P.height + h, b.Z)), WOOD, Enum.Material.Wood)
		end
	end
	local function at(x: number, z: number): Vector3
		return Vector3.new(origin.X + x, railTop, origin.Z + z)
	end
	railRun(at(P.min.X + 0.4, P.max.Y - 0.4), at(P.max.X - 0.4, P.max.Y - 0.4))
	railRun(at(P.min.X + 0.4, P.min.Y + 0.4), at(P.min.X + 0.4, P.max.Y - 0.4))
	railRun(at(P.max.X - 0.4, P.min.Y + 0.4), at(P.max.X - 0.4, P.max.Y - 0.4))
	for _, side in { -1, 1 } do -- (the front, either side of the ramp)
		railRun(at(pMid.X + side * (P.stairWidth / 2 + 0.4), P.min.Y + 0.4), at(if side < 0 then P.min.X + 0.4 else P.max.X - 0.4, P.min.Y + 0.4))
	end

	-- The RAILWAY round it all: gravel bed, sleepers, two steel rails (nothing on it trips you).
	local R = L.RAIL
	local corners = { Vector2.new(R.minX, R.minZ), Vector2.new(R.maxX, R.minZ), Vector2.new(R.maxX, R.maxZ), Vector2.new(R.minX, R.maxZ) }
	for k = 1, 4 do
		local a2, b2 = corners[k], corners[k % 4 + 1]
		local a = Vector3.new(origin.X + a2.X, floorY, origin.Z + a2.Y)
		local b = Vector3.new(origin.X + b2.X, floorY, origin.Z + b2.Y)
		local len = (b - a).Magnitude
		local base = CFrame.lookAt((a + b) / 2, b)
		paint(into, "RailBed", Vector3.new(7, 0.3, len + 7), base * CFrame.new(0, 0.15, 0), GRAVEL).Material = Enum.Material.Pebble
		for _, side in { -1, 1 } do
			paint(into, "Rail", Vector3.new(0.35, 0.45, len + 7), base * CFrame.new(side * 2.4, 0.75, 0), STEEL).Material = Enum.Material.Metal
		end
		local n = math.floor(len / 6)
		for s = 0, n do
			paint(into, "Sleeper", Vector3.new(6.4, 0.3, 1.1), base * CFrame.new(0, 0.42, -len / 2 + s * len / n), WOOD).Material = Enum.Material.Wood
		end
	end

	-- Tree groups and boulders outside the railway (round trees and pines, one style).
	local rng = Random.new(26)
	local outside = 18
	for k = 1, 4 do
		local a2, b2 = corners[k], corners[k % 4 + 1]
		local along = (b2 - a2)
		local len = along.Magnitude
		local dir = along.Unit
		local out = Vector2.new(dir.Y, -dir.X) -- (to the outside: the corners run clockwise seen from above)
		local d = 10
		while d < len - 10 do
			local p = a2 + dir * d + out * (outside + rng:NextNumber(0, 22))
			local role = if rng:NextNumber() < 0.5 then "TreePine" elseif rng:NextNumber() < 0.8 then "TreeRound" else "Rock"
			if V3Assets.has(role) then
				local placed = V3Assets.place(role, into, CFrame.new(origin.X + p.X, floorY, origin.Z + p.Y) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), { height = if role == "Rock" then rng:NextNumber(4, 7) else rng:NextNumber(18, 28) })
				if placed then
					for _, q in placed:GetDescendants() do
						if q:IsA("BasePart") then
							q.CanCollide = false
							q.CanQuery = false
							q.CanTouch = false
						end
					end
				end
			end
			d += rng:NextNumber(16, 30)
		end
	end

	-- The tower in galvanised steel, the slide grey-green; the crash pads' hazard rims in plain concrete.
	local function steel(p: Instance)
		if p:IsA("BasePart") and p.Transparency < 1 then
			p.Material = Enum.Material.Metal
			p.Color = if string.find(p.Name, "Slide") then Color3.fromRGB(112, 124, 112) else STEEL
		end
	end
	for _, c in folder:GetChildren() do
		if c:IsA("BasePart") and LOOSE.Tower[c.Name] and not string.find(c.Name, "Trampoline") then
			steel(c)
		elseif c:IsA("BasePart") and c.Name == "HazardRim" then
			c.Color = KERB
			c.Material = Enum.Material.Concrete
		elseif c:IsA("BasePart") and c.Name == "StationWall" then
			c.Color = Color3.fromRGB(150, 70, 52)
			c.Material = Enum.Material.Brick
		end
	end
	local heights = folder:FindFirstChild("Heights")
	for _, d in if heights then heights:GetDescendants() else {} do
		steel(d)
	end
end

function LabV10.build(folder: Instance, origin: Vector3)
	local into = Instance.new("Folder")
	into.Name = "LabV10"
	local plot = plotOf(origin)
	local floorPart = plot and plot:FindFirstChild("LabFloor", true)
	local floorY = if floorPart and floorPart:IsA("BasePart") then floorPart.Position.Y + floorPart.Size.Y / 2 else origin.Y + 0.5

	-- The floor: warm light concrete instead of the green tiles.
	if floorPart and floorPart:IsA("BasePart") then
		floorPart.Color = Color3.fromRGB(206, 200, 188) -- (R2: warm mid-grey concrete with its grain, not a white slab)
		floorPart.Material = Enum.Material.Concrete
		floorPart.Transparency = 0 -- (it was see-through over the grass)
		for _, t in floorPart:GetChildren() do
			if t:IsA("Texture") then
				t.Color3 = Color3.fromRGB(214, 208, 196)
				t.Transparency = 0.55
			end
		end
	end
	-- The plot's leftovers: the white spawn disc, the edge lines, the barriers and cones.
	if plot then
		for _, c in plot:GetChildren() do
			if c.Name == "Plaza" or c.Name == "PlazaRim" or c.Name == "Edge" or c.Name == "Barrier" or c.Name == "Cone" or c.Name == "LabSign" or c.Name == "LabSignPost" then -- (R2: the lab sign was cut off behind the web; its place is the hero tower)
				hide(c)
			end
		end
	end
	-- (The light-blue edge lines of every plot, built or not, go too.)
	local labs = Workspace:FindFirstChild("Labs")
	for _, p in if labs then labs:GetChildren() else {} do
		for _, c in p:GetChildren() do
			if c.Name == "Edge" then
				hide(c)
			end
		end
	end

	if L.PARK then
		park(into, folder, origin, floorY, if floorPart and floorPart:IsA("BasePart") then floorPart else nil)
	else
	-- The TEST FLOOR (its middle L.TEST_FLOOR): a yellow rim, a darker floor, a white ring and a target.
	local tf = Vector3.new(origin.X + L.TEST_FLOOR.X, floorY, origin.Z + L.TEST_FLOOR.Y)
	local r = L.TEST_RADIUS
	disc(into, "TestRim", tf + Vector3.new(0, 0.04, 0), r + 1.2, 0.08, C.yellow)
	disc(into, "TestFloor", tf + Vector3.new(0, 0.07, 0), r, 0.1, C.concreteDark)
	disc(into, "TestRing", tf + Vector3.new(0, 0.1, 0), r * 0.55 + 0.5, 0.1, C.white)
	disc(into, "TestRingInner", tf + Vector3.new(0, 0.13, 0), r * 0.55 - 0.5, 0.1, C.concreteDark)
	disc(into, "TestTarget", tf + Vector3.new(0, 0.16, 0), 2.4, 0.1, C.yellow)
	disc(into, "TestTargetDot", tf + Vector3.new(0, 0.19, 0), 1.1, 0.1, C.black)

	-- The SPAWN PAD: raised, black with an orange top and an arrow to the test floor.
	local sp = Vector3.new(origin.X, floorY, origin.Z)
	local padBase = part(into, "SpawnPad", Vector3.new(0.6, L.SPAWN_RADIUS * 2 + 1.2, L.SPAWN_RADIUS * 2 + 1.2), CFrame.new(sp + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), C.black, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	padBase.CastShadow = false
	local padTop = part(into, "SpawnPadTop", Vector3.new(0.64, L.SPAWN_RADIUS * 2, L.SPAWN_RADIUS * 2), CFrame.new(sp + Vector3.new(0, 0.32, 0)) * CFrame.Angles(0, 0, math.rad(90)), C.orange, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	padTop.CastShadow = false
	local arrow = CFrame.new(sp + Vector3.new(0, 0.66, -1)) -- (a shaft and a head pointing north, -Z)
	paint(into, "SpawnArrow", Vector3.new(1.4, 0.06, 5), arrow, C.white)
	paint(into, "SpawnArrowHead", Vector3.new(2.8, 0.06, 2.8), CFrame.new(sp + Vector3.new(0, 0.66, -4.4)) * CFrame.Angles(0, math.rad(45), 0), C.white)

	-- WALKWAYS: from the spawn and the test floor to every zone.
	local W = 6
	local t2 = L.TEST_FLOOR
	for _, ab in {
		{ Vector2.new(0, -L.SPAWN_RADIUS - 0.6), Vector2.new(0, t2.Y + r) }, -- spawn to the test floor
		{ Vector2.new(0, t2.Y - r), Vector2.new(0, L.BUTTON.Y + 2) }, -- north: the BIG RED BUTTON
		{ Vector2.new(0, L.SPAWN_RADIUS + 0.6), Vector2.new(0, L.WALL.maxZ) }, -- south gate: the weapon range
		{ Vector2.new(-L.SPAWN_RADIUS - 0.6, 0), Vector2.new(-50, 0) }, -- launch range
		{ Vector2.new(-50, 0), Vector2.new(-50, 30) },
		{ Vector2.new(-50, 30), Vector2.new(L.WALL.minX, 30) }, -- west gate
		{ Vector2.new(L.SPAWN_RADIUS + 0.6, 0), Vector2.new(30, 0) }, -- the cannon and the car bays
		{ Vector2.new(30, 0), Vector2.new(30, 30) },
		{ Vector2.new(30, 30), Vector2.new(L.WALL.maxX, 30) }, -- east gate
	} do
		walkway(into, origin, floorY, ab[1], ab[2], W)
	end

	-- R2: each zone on its own coloured pad with yellow hazard corners; bays painted on the crash track.
	for _, z in L.ZONE_PADS or {} do
		local size = z.max - z.min
		local mid = (z.min + z.max) / 2
		local at = Vector3.new(origin.X + mid.X, floorY + 0.02, origin.Z + mid.Y)
		paint(into, "ZonePad_" .. z.name, Vector3.new(size.X, 0.04, size.Y), CFrame.new(at), z.color)
		for _, cx in { -1, 1 } do
			for _, cz in { -1, 1 } do
				local corner = at + Vector3.new(cx * (size.X / 2 - 0.6), 0.03, cz * (size.Y / 2 - 0.6))
				paint(into, "ZoneCorner", Vector3.new(6, 0.06, 1.2), CFrame.new(corner + Vector3.new(-cx * 2.4, 0, 0)), C.yellow)
				paint(into, "ZoneCorner", Vector3.new(1.2, 0.06, 6), CFrame.new(corner + Vector3.new(0, 0, -cz * 2.4)), C.yellow)
			end
		end
	end
	local bays = L.BAY_LINES
	if bays then
		for _, x in bays.x do
			paint(into, "BayLine", Vector3.new(0.6, 0.06, bays.z2 - bays.z1), CFrame.new(origin.X + x, floorY + 0.07, origin.Z + (bays.z1 + bays.z2) / 2), C.white)
		end
	end

	-- The COMPOUND WALL with its gates.
	wall(into, origin, floorY)

	-- The SKYLINE outside the north wall (each lab has its own strip; the labs lie side by side on X).
	local north = L.WALL.minZ - 30
	hangar(into, CFrame.new(origin + Vector3.new(-62, floorY - origin.Y, north - 6)), 44, 30, 18)
	hangar(into, CFrame.new(origin + Vector3.new(60, floorY - origin.Y, north - 2)), 38, 26, 15)
	controlTower(into, CFrame.new(origin + Vector3.new(-6, floorY - origin.Y, north - 14)))
	waterTower(into, CFrame.new(origin + Vector3.new(110, floorY - origin.Y, -60)))

	-- The things already standing, in the lab's colours: the tower white with a hazard crown, the crash
	-- wall padded orange.
	local bands = 0
	for _, c in folder:GetChildren() do
		if c:IsA("BasePart") then
			if c.Name == "Tower" then
				c.Color = C.white
				c.Material = Enum.Material.SmoothPlastic
			elseif c.Name == "TowerBand" then
				bands += 1
				c.Color = if bands % 2 == 0 then C.black else C.yellow
				c.Material = Enum.Material.SmoothPlastic
			elseif c.Name == "TowerStripe" then
				c.Color = C.orange
			elseif c.Name == "StationWall" then
				c.Color = C.orange
				c.Material = Enum.Material.Fabric
			elseif c.Name == "StationRail" then
				c.Color = C.yellow
			end
		end
	end

	end -- (LAB10 cartoon frame)
	-- Trees, bushes and rocks of the landscape that stand inside the wall go (grass and trees only outside).
	local land = Workspace:FindFirstChild("Landscape")
	local w = L.WALL
	for _, m in if land then land:GetChildren() else {} do
		local at: Vector3? = if m:IsA("Model") then m:GetPivot().Position elseif m:IsA("BasePart") then m.Position else nil
		if at then
			local lx, lz = at.X - origin.X, at.Z - origin.Z
			if lx > w.minX - 4 and lx < w.maxX + 4 and lz > w.minZ - 4 and lz < w.maxZ + 4 then
				hide(m)
			end
		end
	end

	into.Parent = folder
end

return LabV10
