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

function LabV10.build(folder: Instance, origin: Vector3)
	local into = Instance.new("Folder")
	into.Name = "LabV10"
	local plot = plotOf(origin)
	local floorPart = plot and plot:FindFirstChild("LabFloor", true)
	local floorY = if floorPart and floorPart:IsA("BasePart") then floorPart.Position.Y + floorPart.Size.Y / 2 else origin.Y + 0.5

	-- The floor: warm light concrete instead of the green tiles.
	if floorPart and floorPart:IsA("BasePart") then
		floorPart.Color = C.concrete
		floorPart.Material = Enum.Material.SmoothPlastic
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
			if c.Name == "Plaza" or c.Name == "PlazaRim" or c.Name == "Edge" or c.Name == "Barrier" or c.Name == "Cone" then
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
