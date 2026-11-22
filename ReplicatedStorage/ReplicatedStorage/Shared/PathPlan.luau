--!strict
-- V7-2: the paths that lead to everything (pure: PathBuilder draws them, T106 checks them).
-- A path is a gentle curve from a start to a goal: points about STEP studs apart, bowing a little
-- to one side (seeded, so every server draws the same), with a width that breathes between
-- WIDTH_MIN and WIDTH_MAX. On the open-air maps and the plaza they run from the arrival to every
-- launcher and shop booth (found at build time).

local PathPlan = {}

PathPlan.STEP = 2.4 -- studs between two path stones (they overlap well: smooth soft edges, not scallops)
PathPlan.WIDTH_MIN = 5.2 -- (the paved walk with both kerbs: what T106 keeps clear of the machines)
PathPlan.WIDTH_MAX = 5.6
PathPlan.BOW = 0.08 -- how far a path bows sideways, as a share of its length (at most 4 studs)
PathPlan.BUDGET = 1400 -- path parts per lab at most (walkway slabs, joints, kerbs, and since 21 Nov PATHS_V3 dressing up to PathBuilder.DRESS_MAX 700; phones: flat, anchored, no shadows, no collisions)

-- The lab: x, z from the lab's origin (measured from the built lab, 20 Nov 2026). Not a fan from
-- one point (that read as a code-built "spider", review fix round 2): a tree. A trunk leaves the
-- open floor in front of the spawn (the hub) for a centre fork south of the big button; an east
-- and a west walk leave the fork, and short branches end at the edge of each thing to do, never
-- inside it. The bullseye is reached round the east side of the dummies' test mat, the yard in
-- front round the west side (the mace's sweep and the station pads leave no room in the middle).
-- OBSTACLES are the machines' footprints; T106 keeps every stone, with its own half width,
-- outside them.
PathPlan.LAB_HUB = Vector2.new(0, 24)
PathPlan.LAB_POINTS = table.freeze({
	Hub = Vector2.new(0, 24),
	Fork = Vector2.new(2, 4),
	East = Vector2.new(30, 2),
	West = Vector2.new(-26, 4),
	MatEast = Vector2.new(25, -12), -- (round the east side of the dummies' test mat)
	MatSouth = Vector2.new(24, -33),
	YardWest = Vector2.new(-46, 70),
	EastGap = Vector2.new(37, 42.3), -- (the gap between the ramp and the station pads: walked straight)
	WestBend = Vector2.new(-62, 18), -- (south of the portals, between the cones)
	-- Goals: at the edge of each machine.
	Cannon = Vector2.new(38, 13),
	Button = Vector2.new(12, 23),
	Stations = Vector2.new(10, 42),
	Bullseye = Vector2.new(5, -36),
	Lava = Vector2.new(-26, -26),
	Mace = Vector2.new(-10, 38),
	Tower = Vector2.new(-50, -2),
	Portals = Vector2.new(-56, 37),
	Wrecking = Vector2.new(40, -16),
	Vehicles = Vector2.new(56, -12),
	Yard = Vector2.new(-6, 78),
	GardenEast = Vector2.new(80, 30), -- (the garden walk's crossing: the plant and the chicken live along it)
	GardenWest = Vector2.new(-80, 29), -- (the spider and the frog)
})
-- Every segment from -> to (the trunk first; branches after).
PathPlan.LAB_SEGMENTS = table.freeze({
	{ "Hub", "Fork" },
	{ "Fork", "East" },
	{ "Fork", "West" },
	{ "East", "MatEast" },
	{ "MatEast", "MatSouth" },
	{ "MatSouth", "Bullseye" },
	{ "Hub", "Button" },
	{ "Hub", "Stations" },
	{ "Hub", "Mace" },
	{ "East", "Cannon" },
	{ "East", "Wrecking" },
	{ "East", "Vehicles" },
	{ "Stations", "EastGap", true },
	{ "EastGap", "GardenEast" },
	{ "West", "Lava" },
	{ "West", "Tower" },
	{ "Tower", "Portals" },
	{ "Tower", "WestBend" },
	{ "WestBend", "GardenWest" },
	{ "Portals", "YardWest" },
	{ "YardWest", "Yard" },
})
-- What the paths lead to (T106: each one is the end of a segment).
PathPlan.LAB_ROUTES = table.freeze({
	{ name = "Cannon", to = PathPlan.LAB_POINTS.Cannon },
	{ name = "Button", to = PathPlan.LAB_POINTS.Button },
	{ name = "Stations", to = PathPlan.LAB_POINTS.Stations },
	{ name = "Bullseye", to = PathPlan.LAB_POINTS.Bullseye },
	{ name = "Lava", to = PathPlan.LAB_POINTS.Lava },
	{ name = "Mace", to = PathPlan.LAB_POINTS.Mace },
	{ name = "Tower", to = PathPlan.LAB_POINTS.Tower },
	{ name = "Portals", to = PathPlan.LAB_POINTS.Portals },
	{ name = "Wrecking", to = PathPlan.LAB_POINTS.Wrecking },
	{ name = "Vehicles", to = PathPlan.LAB_POINTS.Vehicles },
	{ name = "Yard", to = PathPlan.LAB_POINTS.Yard },
	{ name = "GardenEast", to = PathPlan.LAB_POINTS.GardenEast },
	{ name = "GardenWest", to = PathPlan.LAB_POINTS.GardenWest },
})

-- What the wooden signposts at the forks call each way (the point a segment leads to).
PathPlan.LABELS = table.freeze({
	Fork = "WORKSHOP",
	East = "CANNON",
	West = "LAVA",
	MatEast = "BULLSEYE",
	Cannon = "CANNON",
	Button = "BIG BUTTON",
	Stations = "LAUNCH PADS",
	Bullseye = "BULLSEYE",
	Lava = "LAVA",
	Mace = "MACE",
	Tower = "TOWER",
	Portals = "PORTALS",
	Wrecking = "WRECKING BALL",
	Vehicles = "CARS",
	EastGap = "GARDEN",
	WestBend = "GARDEN",
	YardWest = "MONSTERS",
})
-- The forks that get a signpost.
-- (V8-0.4, Config.V8_ONE_VOICE: no signpost on or right by the spawn; the Hub and Fork boards go.)
local V8_VOICE = (require(script.Parent:WaitForChild("Config")) :: any).V8_ONE_VOICE == true
PathPlan.SIGNS = table.freeze(if V8_VOICE then { "East", "West", "Tower", "Stations" } else { "Hub", "Fork", "East", "West", "Tower", "Stations" })
-- V8-0.4: the spawn's keep-clear circle. No machine, sign or prop stands in it (T106); the paths'
-- flat paving may cross it.
PathPlan.SPAWN_CLEAR = table.freeze({ at = Vector2.new(0, 0), radius = 10 })

export type Obstacle = { name: string, at: Vector2?, radius: number?, min: Vector2?, max: Vector2? }

-- The machines' footprints in the lab: circles (at, radius; the mace as its whole sweep) or boxes
-- (min, max).
PathPlan.OBSTACLES = table.freeze({
	{ name = "Button", at = Vector2.new(14, 14), radius = 4.5 },
	{ name = "Cannon", at = Vector2.new(50, 8), radius = 9 },
	{ name = "Mace", at = Vector2.new(-30, 32), radius = 16.5 },
	{ name = "Bullseye", at = Vector2.new(-6, -42), radius = 8 },
	{ name = "Tower", at = Vector2.new(-52, -64), radius = 9 },
	{ name = "Trampoline", at = Vector2.new(-34, -64), radius = 7 },
	{ name = "Portal", at = Vector2.new(-66, 30), radius = 6 },
	{ name = "Portal", at = Vector2.new(-66, 44), radius = 6 },
	{ name = "Ramp", min = Vector2.new(21, 21), max = Vector2.new(31, 39) },
	{ name = "StationPads", min = Vector2.new(-14.5, 45.5), max = Vector2.new(34.5, 58.5) },
	{ name = "Lava", min = Vector2.new(-39, -51), max = Vector2.new(-16, -31) },
	{ name = "Stairs", min = Vector2.new(-56, -58), max = Vector2.new(-48, -8) },
	{ name = "Wrecking", min = Vector2.new(30, -44), max = Vector2.new(50, -22) },
	{ name = "Vehicles", min = Vector2.new(61.5, -38.5), max = Vector2.new(74.5, 26.5) },
	{ name = "StationWall", min = Vector2.new(56, 45), max = Vector2.new(60, 59) },
	{ name = "TestMat", min = Vector2.new(-21, -28), max = Vector2.new(21, -11) }, -- (Workspace.Labs: where the dummies stand)
	{ name = "Barrier", min = Vector2.new(-80, -62), max = Vector2.new(-72, -58) },
	{ name = "Barrier", min = Vector2.new(-80, -28), max = Vector2.new(-72, -24) },
	{ name = "Barrier", min = Vector2.new(-80, 6), max = Vector2.new(-72, 10) },
	{ name = "Barrier", min = Vector2.new(-80, 40), max = Vector2.new(-72, 44) },
	{ name = "Barrier", min = Vector2.new(72, -62), max = Vector2.new(80, -58) },
	{ name = "Barrier", min = Vector2.new(72, -28), max = Vector2.new(80, -24) },
	{ name = "Barrier", min = Vector2.new(72, 6), max = Vector2.new(80, 10) },
	{ name = "Barrier", min = Vector2.new(72, 40), max = Vector2.new(80, 44) },
	{ name = "Cone", min = Vector2.new(-75, -52), max = Vector2.new(-73, -50) },
	{ name = "Cone", min = Vector2.new(-75, -18), max = Vector2.new(-73, -16) },
	{ name = "Cone", min = Vector2.new(-75, 16), max = Vector2.new(-73, 18) },
	{ name = "Cone", min = Vector2.new(-75, 50), max = Vector2.new(-73, 52) },
	{ name = "Cone", min = Vector2.new(73, -52), max = Vector2.new(75, -50) },
	{ name = "Cone", min = Vector2.new(73, -18), max = Vector2.new(75, -16) },
	{ name = "Cone", min = Vector2.new(73, 16), max = Vector2.new(75, 18) },
	{ name = "Cone", min = Vector2.new(73, 50), max = Vector2.new(75, 52) },
	-- The Christmas lab's machines (from 1 Dec; Playground.CHRISTMAS_SPOTS): chimney with its hearth, the
	-- present trap, the sleigh ramp.
	{ name = "XmasChimney", min = Vector2.new(41.5, 57.5), max = Vector2.new(48.5, 69.5) },
	{ name = "XmasPresent", min = Vector2.new(-43.5, 54.5), max = Vector2.new(-36.5, 61.5) },
	{ name = "XmasSleigh", min = Vector2.new(-14, -68), max = Vector2.new(-6, -52) },
} :: { Obstacle })

-- 21 Nov 2026 (Config.LAYOUT_V2, the owner: "paths must not stop out of the blue, they must all hang
-- together"; vault: a path that just ends is the strongest wrong-way signal, optional ways branch off
-- and join again). A network instead of a tree:
--   * from the spawn (the hub) to both sides of the test range: the bullseye and the lava;
--   * an east loop past the wrecking ball, the cars and the cannon, out to the east garden;
--   * a south road along the launch pads, joining both sides;
--   * a west way to the tower's stairs, and to the portals;
--   * a road through the creature yard joining the two garden walks (the garden, the yard and the
--     lab are one big loop).
-- The only ends left are at a thing: the bullseye, the lava's rocks, the tower's stairs, the portals.
local LAYOUT_V2 = (require(script.Parent:WaitForChild("Config")) :: any).LAYOUT_V2 == true
-- The garden's long walks (LabGarden): their x, and where they now start and end.
PathPlan.GARDEN_WALK_X = 99.8
PathPlan.GARDEN_WALK_NORTH = -62 -- (V9-0 F2: was -66; its end joint ran into the plant's planter)
PathPlan.GARDEN_WALK_SOUTH = 67
if LAYOUT_V2 then
	-- (21 Nov 2026, round 2, the owner: "the paths are far too narrow and still stick out at the bullseye":
	-- fewer, wide walks (WIDE_PAVING studs of paving plus kerbs, about twice the old), no stub at all
	-- by the bullseye or the lava: three arms from the spawn's plaza with loops, and the big round
	-- through the yard and the gardens.)
	PathPlan.WIDTH_MIN = 8.3
	PathPlan.WIDTH_MAX = 8.6
	PathPlan.WIDE_PAVING = 7.4
	PathPlan.LAB_HUB = Vector2.new(0, 0)
	-- (V9-NOW 20, Config.TRAVEL_CORNER: the portals moved to the MAPS board in the spawn's view, beside the spawn's
	-- plaza; the west walk to their old spot (W2 - PW - P1) is not laid, so no walk ends at nothing.)
	local corner = (require(script.Parent:WaitForChild("Config")) :: any).TRAVEL_CORNER == true
	PathPlan.LAB_POINTS = table.freeze({
		Spawn = Vector2.new(0, 0),
		E = Vector2.new(28, -2),
		C0 = Vector2.new(42, -7),
		CAR = Vector2.new(57, -7),
		WR = Vector2.new(41, -13),
		C1 = Vector2.new(37, 14),
		C2 = Vector2.new(42, 31),
		GardenEast = Vector2.new(80, 31),
		W = Vector2.new(-28, 0),
		WL = Vector2.new(-40, -3),
		TS = Vector2.new(-52, -3.5), -- (the tower's first step)
		S1 = Vector2.new(4, 22),
		S2 = Vector2.new(2, 40.5),
		SW = Vector2.new(-19.5, 40.5),
		W2 = Vector2.new(-26, 26),
		PW = Vector2.new(-46, 27),
		P1 = Vector2.new(-57.5, 37), -- (between the two portals)
		YW = Vector2.new(-19.5, 66),
		Yard = Vector2.new(-6, 80),
		YP1 = Vector2.new(-60, 78),
		YP2 = Vector2.new(45, 78),
		GardenWestEnd = Vector2.new(-PathPlan.GARDEN_WALK_X, PathPlan.GARDEN_WALK_SOUTH),
		GardenEastEnd = Vector2.new(PathPlan.GARDEN_WALK_X, PathPlan.GARDEN_WALK_SOUTH),
	})
	local segments = {
		-- East arm: a loop past the wrecking ball, the cars and the cannon; on to the east garden.
		{ "Spawn", "E" }, { "E", "WR" }, { "WR", "CAR" }, { "CAR", "C0", true }, { "C0", "E" },
		{ "E", "C1" }, { "C1", "C2" }, { "C2", "GardenEast", true },
		-- South and west: past the big button and the launch pads, round to the west arm.
		{ "Spawn", "S1" }, { "S1", "S2" }, { "S2", "SW", true }, { "SW", "W2" }, { "W2", "W", true }, { "W", "Spawn" },
		-- West: to the tower's first step; to the portals.
		{ "W", "WL" }, { "WL", "TS", true },
		-- The creature yard and the round through both gardens.
		{ "SW", "YW", true }, { "YW", "Yard" }, { "Yard", "YP1", true }, { "YP1", "GardenWestEnd", true },
		{ "Yard", "YP2", true }, { "YP2", "GardenEastEnd", true },
	}
	if not corner then
		table.insert(segments, { "W2", "PW", true })
		table.insert(segments, { "PW", "P1" })
	end
	PathPlan.LAB_SEGMENTS = table.freeze(segments)
	local routes = {
		{ name = "TS", to = PathPlan.LAB_POINTS.TS },
		{ name = "Yard", to = PathPlan.LAB_POINTS.Yard },
		{ name = "GardenEast", to = PathPlan.LAB_POINTS.GardenEast },
		{ name = "GardenWestEnd", to = PathPlan.LAB_POINTS.GardenWestEnd },
		{ name = "GardenEastEnd", to = PathPlan.LAB_POINTS.GardenEastEnd },
	}
	if not corner then
		table.insert(routes, 2, { name = "P1", to = PathPlan.LAB_POINTS.P1 })
	end
	PathPlan.LAB_ROUTES = table.freeze(routes)
	PathPlan.LABELS = table.freeze(if corner then {
		C1 = "CANNON",
		WR = "WRECKING BALL",
		WL = "TOWER",
		S2 = "LAUNCH PADS",
		SW = "MONSTERS",
		YW = "MONSTERS",
		GardenEast = "GARDEN",
	} else {
		C1 = "CANNON",
		WR = "WRECKING BALL",
		WL = "TOWER",
		S2 = "LAUNCH PADS",
		SW = "MONSTERS",
		YW = "MONSTERS",
		PW = "PORTALS",
		W2 = "PORTALS",
		GardenEast = "GARDEN",
	})
	PathPlan.SIGNS = table.freeze({ "E", "W", "SW" })
	-- (V9-0 F3, owner 21 Nov 2026: "the path also stops": what every end leads to. T150 checks each end is
	-- at its thing: a lab part by name (within `reach` studs), or the garden's own walks ("path").)
	PathPlan.END_TARGETS = table.freeze({
		TS = { kind = "part", name = "StairEdge", reach = 6 },
		P1 = if corner then nil else { kind = "part", name = "PortalSolo", reach = 12 },
		GardenEast = { kind = "path", reach = 3 },
		GardenWestEnd = { kind = "path", reach = 3 },
		GardenEastEnd = { kind = "path", reach = 3 },
	})
	-- The mace and the Christmas present moved back to make room; the lava's box takes in its rocks.
	local moved: { [string]: Obstacle } = {
		Lava = { name = "Lava", min = Vector2.new(-41, -53), max = Vector2.new(-14, -29) },
		Mace = { name = "Mace", at = Vector2.new(-41, 50), radius = 16.5 },
		XmasPresent = { name = "XmasPresent", min = Vector2.new(-61.5, 60.5), max = Vector2.new(-54.5, 67.5) },
	}
	local list: { Obstacle } = {}
	for _, o in PathPlan.OBSTACLES do
		table.insert(list, moved[o.name] or o)
	end
	PathPlan.OBSTACLES = table.freeze(list)
end

-- Where the BIG RED BUTTON and the car ramp stand (lab x, z): Playground builds them there,
-- LabZones marks the button's pad. V9-0h (LAYOUT_V3) moves both onto the rim, out of the spawn's
-- 40-stud clear circle.
PathPlan.BUTTON_AT = Vector2.new(14, 14)
PathPlan.RAMP_AT = Vector2.new(26, 30)
PathPlan.ROW_Z = -20 -- (the dummy row's test zone centre; Lab)
PathPlan.HUB_CLEAR = 0 -- (V9-0h: the radius of floor round the spawn kept free of every attraction)

-- V9-0h (Config.LAYOUT_V3, owner 21 Nov 2026, the leader's hub): one big open tiled floor. The paths
-- inside the core go (the floor is the path); what stays is the road out to the creature yard and
-- the round through both gardens, starting at the floor's back edge.
local LAYOUT_V3 = (require(script.Parent:WaitForChild("Config")) :: any).LAYOUT_V3 == true
if LAYOUT_V3 then
	PathPlan.BUTTON_AT = Vector2.new(-34, 24)
	-- (V9-NOW 22 + owner 21 Nov 2026: "swap the red button and all the portals": with Config.TRAVEL_CORNER the button stands
	-- where the MAPS board stood, in the spawn's view, and the board and both portals take the button's rim spot.)
	if (require(script.Parent:WaitForChild("Config")) :: any).TRAVEL_CORNER == true then
		PathPlan.BUTTON_AT = Vector2.new(16, -19)
	end
	PathPlan.RAMP_AT = Vector2.new(68, 28) -- (0.37.1: in the launch area, east of the cannon, clear of the stations)
	PathPlan.ROW_Z = -60
	PathPlan.HUB_CLEAR = 40
	PathPlan.FLOOR_BACK_Z = 71 -- (the open floor's back edge: Lab's LabFloor, 165 deep round z -11.5)
	PathPlan.LAB_POINTS = table.freeze({
		Spawn = Vector2.new(0, 0),
		YardIn = Vector2.new(-6, 70), -- (on the floor's back edge: the floor itself leads here)
		Yard = Vector2.new(-6, 80),
		YP1 = Vector2.new(-60, 78),
		YP2 = Vector2.new(45, 78),
		-- (V9-0d: the road stops where its round end just meets the garden walk's edge: they touch, they
		-- never lie on top of each other, so nothing flickers there.)
		GardenWestEnd = Vector2.new(-PathPlan.GARDEN_WALK_X + 7.6, PathPlan.GARDEN_WALK_SOUTH),
		GardenEastEnd = Vector2.new(PathPlan.GARDEN_WALK_X - 7.6, PathPlan.GARDEN_WALK_SOUTH),
	})
	PathPlan.LAB_SEGMENTS = table.freeze({
		{ "YardIn", "Yard", true },
		{ "Yard", "YP1", true },
		{ "YP1", "GardenWestEnd", true },
		{ "Yard", "YP2", true },
		{ "YP2", "GardenEastEnd", true },
	})
	PathPlan.LAB_ROUTES = table.freeze({
		{ name = "Yard", to = PathPlan.LAB_POINTS.Yard },
		{ name = "GardenWestEnd", to = PathPlan.LAB_POINTS.GardenWestEnd },
		{ name = "GardenEastEnd", to = PathPlan.LAB_POINTS.GardenEastEnd },
	})
	PathPlan.LABELS = table.freeze({})
	PathPlan.SIGNS = table.freeze({})
	PathPlan.END_TARGETS = table.freeze({
		YardIn = { kind = "floor", reach = 3 },
		GardenWestEnd = { kind = "path", reach = 4.5 },
		GardenEastEnd = { kind = "path", reach = 4.5 },
	})
	local list: { Obstacle } = {}
	for _, o in PathPlan.OBSTACLES do
		local moved: Obstacle? = if o.name == "Button" then { name = "Button", at = PathPlan.BUTTON_AT, radius = 4.5 }
			elseif o.name == "Ramp" then { name = "Ramp", min = PathPlan.RAMP_AT - Vector2.new(5, 9), max = PathPlan.RAMP_AT + Vector2.new(5, 9) }
			elseif o.name == "TestMat" then { name = "TestMat", min = Vector2.new(-21, PathPlan.ROW_Z - 8), max = Vector2.new(21, PathPlan.ROW_Z + 8) }
			elseif o.name == "XmasSleigh" then { name = "XmasSleigh", min = Vector2.new(58, -70), max = Vector2.new(66, -54) } -- (Playground.CHRISTMAS_SPOTS V3)
			else nil
		table.insert(list, moved or o)
	end
	PathPlan.OBSTACLES = table.freeze(list)
end

-- 0.37.0 (owner, 22 Nov 2026: "a much bigger lab, things placed so people walk to them"): every lab spot
-- above moves Config.LAB_SPREAD times further from the spawn. Footprints keep their size (a machine is as
-- big as before, only further out); the spawn's clear circle stays as it is.
local SPREAD = (require(script.Parent:WaitForChild("Config")) :: any).LAB_SPREAD or 1
PathPlan.SPREAD = SPREAD
if SPREAD ~= 1 then
	PathPlan.BUTTON_AT *= SPREAD
	PathPlan.RAMP_AT *= SPREAD
	PathPlan.ROW_Z *= SPREAD
	PathPlan.HUB_CLEAR *= SPREAD
	if PathPlan.FLOOR_BACK_Z then
		PathPlan.FLOOR_BACK_Z *= SPREAD
	end
	PathPlan.GARDEN_WALK_X *= SPREAD
	PathPlan.GARDEN_WALK_NORTH *= SPREAD
	PathPlan.GARDEN_WALK_SOUTH *= SPREAD
	local points = {}
	for name, p in PathPlan.LAB_POINTS do
		points[name] = p * SPREAD
	end
	PathPlan.LAB_POINTS = table.freeze(points) :: any
	local routes = {}
	for _, r in PathPlan.LAB_ROUTES do
		local copy = table.clone(r :: any)
		if typeof(copy.to) == "Vector2" then
			copy.to *= SPREAD
		end
		table.insert(routes, copy)
	end
	PathPlan.LAB_ROUTES = table.freeze(routes) :: any
	local list: { Obstacle } = {}
	for _, o in PathPlan.OBSTACLES do
		if o.at then
			table.insert(list, { name = o.name, at = (o.at :: Vector2) * SPREAD, radius = o.radius })
		else
			local mn, mx = o.min :: Vector2, o.max :: Vector2
			local mid, half = (mn + mx) / 2, (mx - mn) / 2
			table.insert(list, { name = o.name, min = mid * SPREAD - half, max = mid * SPREAD + half })
		end
	end
	PathPlan.OBSTACLES = table.freeze(list)
	if PathPlan.LABELS then
		local labels = {}
		for k, l in PathPlan.LABELS :: any do
			local copy = if type(l) == "table" then table.clone(l) else l
			if type(copy) == "table" then
				for key, val in copy do
					if typeof(val) == "Vector2" then
						copy[key] = val * SPREAD
					end
				end
			elseif typeof(copy) == "Vector2" then
				copy *= SPREAD
			end
			labels[k] = copy
		end
		PathPlan.LABELS = table.freeze(labels) :: any
	end
end

-- Terrain material per open-air place (what the grass under a path turns into).
PathPlan.TERRAIN = table.freeze({
	Plaza = "Cobblestone",
	Island = "Ground",
	City = "Cobblestone",
	Site = "Mud",
	Farm = "Ground",
	Military = "Ground",
})

-- A small deterministic hash 0..1 (the same bow and widths on every server).
local function hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

export type Stone = { at: Vector2, width: number }

-- The stones of one path from a to b (seeded by `seed`); `straight` = no bow, no wiggle (a narrow gap).
function PathPlan.curve(a: Vector2, b: Vector2, seed: number, straight: boolean?): { Stone }
	local d = b - a
	local length = d.Magnitude
	if length < 1 then
		return {}
	end
	local side = Vector2.new(-d.Y, d.X).Unit
	local bow = if straight then 0 else math.min(length * PathPlan.BOW, 4) * (if hash(seed) > 0.5 then 1 else -1)
	local wiggle = if straight then 0 else 0.6
	local n = math.max(2, math.floor(length / PathPlan.STEP))
	local out: { Stone } = {}
	for i = 0, n do
		local t = i / n
		local along = a + d * t
		local offset = side * (math.sin(t * math.pi) * bow + math.sin(t * math.pi * 3 + seed) * wiggle)
		local w = PathPlan.WIDTH_MIN + (PathPlan.WIDTH_MAX - PathPlan.WIDTH_MIN) * hash(seed * 31 + i)
		table.insert(out, { at = along + offset, width = w })
	end
	return out
end

-- The stones of one lab segment (index i in LAB_SEGMENTS).
function PathPlan.segment(i: number): { Stone }
	local seg = PathPlan.LAB_SEGMENTS[i]
	local P = PathPlan.LAB_POINTS :: any
	return PathPlan.curve(P[seg[1]], P[seg[2]], i, (seg :: any)[3] == true)
end

-- Every stone of the lab's paths.
function PathPlan.lab(): { Stone }
	local all: { Stone } = {}
	for i in PathPlan.LAB_SEGMENTS do
		for _, s in PathPlan.segment(i) do
			table.insert(all, s)
		end
	end
	return all
end

-- How far a point is outside an obstacle (negative: inside).
function PathPlan.gap(p: Vector2, o: Obstacle): number
	if o.at and o.radius then
		return (p - o.at).Magnitude - o.radius
	end
	local mn, mx = o.min :: Vector2, o.max :: Vector2
	local dx = math.max(mn.X - p.X, 0, p.X - mx.X)
	local dz = math.max(mn.Y - p.Y, 0, p.Y - mx.Y)
	if dx == 0 and dz == 0 then
		return -math.min(p.X - mn.X, mx.X - p.X, p.Y - mn.Y, mx.Y - p.Y)
	end
	return math.sqrt(dx * dx + dz * dz)
end

-- Whether a path's stones, each with its own half width, keep clear of the obstacles; returns
-- the first obstacle one touches, by name.
function PathPlan.clear(stones: { Stone }, obstacles: { Obstacle }): (boolean, string?)
	for _, s in stones do
		for _, o in obstacles do
			if PathPlan.gap(s.at, o) < s.width / 2 then
				return false, o.name
			end
		end
	end
	return true
end

-- V9-0l: the creature yard in front of the lab (LabCreatures.YARD_Z 92, 38 deep): no body is dropped
-- or walks in there (its creatures' triggers are boxes nobody can see from above). Lab-local x, z.
PathPlan.YARD = table.freeze({ zMin = 92 * SPREAD - 19 - 2, zMax = 92 * SPREAD + 19 + 2 }) -- (0.37.0: LabCreatures.YARD_Z moves with the spread)
function PathPlan.inYard(p: Vector2): boolean
	return p.Y > PathPlan.YARD.zMin and p.Y < PathPlan.YARD.zMax
end

return PathPlan
