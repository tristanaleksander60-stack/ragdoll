--!strict
-- LAB 10/10 (owner, 26 Nov 2026: "Hele labbet skal tages fra 2/10 til 10/10, ikke vær bange for at ændre ALT";
-- docs/LAB10.md). One table for where everything in a player's lab stands under Config.LAB_V10, in
-- lab studs from the spawn (x across, -z ahead/north). Every builder asks here; with LAB_V10 off
-- (or an id missing) it keeps its own spot, so false brings back today's lab.
--
--   CRASH TEST LAB (top view, spawn at 0,0 facing north)
--     north  (z -115..-60):  frog . shark tank . [boards] SPIDER WEB [boards] . plant . fan
--     west   (x -80..-30):   the DROP TOWER (stairs, bridge, slide, sky deck: unchanged spot)
--     centre (0,-28):        the TEST FLOOR (dummies on its ring), the BIG RED BUTTON at its north edge
--     east   (x 40..95):     SMASH YARD: wrecking ball, boxing ring, stretch machine, chicken pen
--     test floor edges:      the portal (west) and the MAPS board (east), facing the spawn
--     south-west:            LAUNCH RANGE: rocket, slingshot, mole, washer, compressor
--     south-east:            CRASH TRACK: the three launch pads into the crash wall, car bays in front of it
--     south, outside a gate: the weapon range building

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local LabLayout10 = {}

LabLayout10.on = Config.LAB_V10 == true

-- The test floor: its middle and radius (the dummies stand on its rim).
LabLayout10.TEST_FLOOR = Vector2.new(0, -28)
LabLayout10.TEST_RADIUS = 21 -- (R2: a bigger arena, the heart of the lab)
LabLayout10.BUTTON = Vector2.new(0, -52)
LabLayout10.SPAWN_RADIUS = 7
-- The compound: the lab floor's edge (Lab: LabFloor x -96..96, z -113..85) with a wall round it.
LabLayout10.WALL = { minX = -97, maxX = 97, minZ = -115, maxZ = 87 }
-- Gates in the wall: { side, at (along the side), width }.
LabLayout10.GATES = {
	{ side = "S", at = 0, width = 18 }, -- to the weapon range
	{ side = "W", at = 30, width = 14 },
	{ side = "E", at = 30, width = 14 },
}

-- Moves (studs, lab space) for things built from a whole origin (the builder is handed origin + move).
LabLayout10.MOVES = {
	Lava = Vector3.new(186, 0, -23), -- the boxing ring (and the pool under it) into the smash yard
	-- (The portal and the MAPS board keep their spots on the test floor's west and east edge: both face the
	-- spawn from there, and a move without a turn would face them away.)
	ShootingRange = Vector3.new(0, 0, -40), -- just outside the south gate
}

-- Creatures and yard machines (LabCreatures.SPOTS by id): their new middle.
LabLayout10.CREATURES = {
	Spider = Vector2.new(0, -86), -- the web is the backdrop behind the test floor and the button
	Whale = Vector2.new(-65, -97), -- the shark tank
	Frog = Vector2.new(-93, -65),
	Plant = Vector2.new(78, -84),
	Chicken = Vector2.new(84, -18),
	Washer = Vector2.new(-62, 51),
	Vacuum = Vector2.new(-40, 50), -- (the COMPRESSOR stands on the vacuum's spot)
	Mole = Vector2.new(-88, 54),
	Slingshot = Vector2.new(-63, 17),
}

-- Cars: the middle of each car's bay (VehicleService), in front of the crash wall.
LabLayout10.CARS = {
	Car = Vector2.new(47, 42),
	Truck = Vector2.new(64, 41),
	MuscleCar = Vector2.new(84, 42),
}

-- Bought lab things (MapShopService).
LabLayout10.TRAMPOLINE = Vector2.new(-22, 66) -- (R2: off the south walkway, in the launch range)

-- The stretch machine (Playground's ramp spot) in the smash yard.
LabLayout10.STRETCH = Vector2.new(50, -15)

-- R2: each zone on its own coloured floor pad (lab space rectangles: min, max, colour), with hazard corners.
LabLayout10.ZONE_PADS = {
	{ name = "TowerZone", min = Vector2.new(-94, -80), max = Vector2.new(-26, -2), color = Color3.fromRGB(226, 196, 150) },
	{ name = "CreatureWing", min = Vector2.new(-94, -112), max = Vector2.new(94, -84), color = Color3.fromRGB(150, 196, 176) },
	{ name = "SmashYard", min = Vector2.new(36, -66), max = Vector2.new(94, -4), color = Color3.fromRGB(232, 168, 124) },
	{ name = "LaunchRange", min = Vector2.new(-94, 6), max = Vector2.new(-30, 72), color = Color3.fromRGB(160, 180, 214) },
	{ name = "CrashTrack", min = Vector2.new(10, 30), max = Vector2.new(94, 74), color = Color3.fromRGB(92, 94, 104) },
}
-- R2: car bay lines on the crash track (x of each line; from z1 to z2).
LabLayout10.BAY_LINES = { x = { 38, 56, 73, 94 }, z1 = 32, z2 = 53 }

-- LAB TARGET (owner, 26 Nov 2026; docs/LAB_TARGET.md): Config.LAB_PARK, the realistic park look over the same spots:
-- grass plots round every machine in a light concrete field, a raised spawn plaza with 4 boards, a railway round it all.
LabLayout10.PARK = LabLayout10.on and Config.LAB_PARK == true
if LabLayout10.PARK then
	LabLayout10.TEST_FLOOR = Vector2.new(0, -36) -- (clear of the plaza's stair)
	LabLayout10.BUTTON = Vector2.new(0, -62)
end
LabLayout10.PLAZA = { min = Vector2.new(-30, -6), max = Vector2.new(30, 16), height = 1.4, stairWidth = 24, stairRun = 7 }
LabLayout10.RAIL = { minX = -106, maxX = 106, minZ = -124, maxZ = 146 }

-- LabDress roles that stay (everything else of the old dressing is hidden: scattered props).
LabLayout10.DRESS_KEEP = { Rocket = true }

-- Benches: round the test floor, facing it.
LabLayout10.BENCHES = {
	Vector2.new(-24, -14),
	Vector2.new(24, -14),
	Vector2.new(-27, -36),
	Vector2.new(27, -36),
}

-- The look (docs/LAB10.md, max 6 colours).
LabLayout10.COLORS = {
	concrete = Color3.fromRGB(230, 226, 216),
	concreteDark = Color3.fromRGB(150, 150, 158),
	yellow = Color3.fromRGB(255, 200, 40),
	black = Color3.fromRGB(30, 30, 34),
	orange = Color3.fromRGB(255, 120, 40),
	white = Color3.fromRGB(245, 245, 245),
	teal = Color3.fromRGB(60, 190, 200),
}

function LabLayout10.move(id: string): Vector3
	if not LabLayout10.on then
		return Vector3.zero
	end
	return LabLayout10.MOVES[id] or Vector3.zero
end

-- A creature's or car's new middle, or nil (keep its own).
function LabLayout10.creature(id: string): Vector2?
	return if LabLayout10.on then LabLayout10.CREATURES[id] else nil
end

function LabLayout10.car(kind: string): Vector2?
	return if LabLayout10.on then LabLayout10.CARS[kind] else nil
end

-- (GO NOW: THE MAP, Config.LAB_OWNERMAP: every spot here 3.2 times further from the spawn, like Config.LAB_SPREAD; sizes stay.)
if Config.LAB_OWNERMAP then
	local K = 3.2
	LabLayout10.CREATURES.Spider = Vector2.new(70, -70) -- (the plan: on its own plot by the fenced pen, not on the leaderboard plaza; x3.2 below)
	local function v2(v: Vector2): Vector2
		return v * K
	end
	LabLayout10.TEST_FLOOR = v2(LabLayout10.TEST_FLOOR)
	LabLayout10.BUTTON = v2(LabLayout10.BUTTON)
	LabLayout10.STRETCH = v2(LabLayout10.STRETCH)
	LabLayout10.TRAMPOLINE = v2(LabLayout10.TRAMPOLINE)
	for k, v in LabLayout10.MOVES do
		LabLayout10.MOVES[k] = Vector3.new(v.X * K, v.Y, v.Z * K)
	end
	for _, t in { LabLayout10.CREATURES, LabLayout10.CARS } do
		for k, v in t do
			t[k] = v * K
		end
	end
	for i, v in LabLayout10.BENCHES do
		LabLayout10.BENCHES[i] = v * K
	end
	for _, z in LabLayout10.ZONE_PADS do
		z.min, z.max = z.min * K, z.max * K
	end
	for _, t in { LabLayout10.WALL, LabLayout10.RAIL } do
		for k, v in t do
			t[k] = v * K
		end
	end
	LabLayout10.PLAZA.min, LabLayout10.PLAZA.max = LabLayout10.PLAZA.min * K, LabLayout10.PLAZA.max * K
	for i, v in LabLayout10.BAY_LINES.x do
		LabLayout10.BAY_LINES.x[i] = v * K
	end
	LabLayout10.BAY_LINES.z1, LabLayout10.BAY_LINES.z2 = LabLayout10.BAY_LINES.z1 * K, LabLayout10.BAY_LINES.z2 * K
	for _, g in LabLayout10.GATES do
		g.at *= K
	end
end

return LabLayout10
