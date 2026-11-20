--!strict
-- V7-2: the paths that lead to everything (pure: PathBuilder draws them, T106 checks them).
-- A path is a gentle curve from a start to a goal: points about STEP studs apart, bowing a little
-- to one side (seeded, so every server draws the same), with a width that breathes between
-- WIDTH_MIN and WIDTH_MAX. On the open-air maps and the plaza they run from the arrival to every
-- launcher and shop booth (found at build time).

local PathPlan = {}

PathPlan.STEP = 2.4 -- studs between two path stones (they overlap well: smooth soft edges, not scallops)
PathPlan.WIDTH_MIN = 4.6
PathPlan.WIDTH_MAX = 5.6
PathPlan.BOW = 0.08 -- how far a path bows sideways, as a share of its length (at most 4 studs)
PathPlan.BUDGET = 400 -- stones per lab at most (phones: flat, anchored, no shadows, no collisions)

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
	TowerWest = Vector2.new(-64, -4),
	TowerSouth = Vector2.new(-68, -36), -- (inside the side barriers and cones)
	YardWest = Vector2.new(-46, 70),
	VehSouth = Vector2.new(56, -44),
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
	GardenEast = Vector2.new(80, -44),
	GardenWest = Vector2.new(-80, -38),
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
	{ "Vehicles", "VehSouth" },
	{ "VehSouth", "GardenEast" },
	{ "West", "Lava" },
	{ "West", "Tower" },
	{ "Tower", "Portals" },
	{ "Tower", "TowerWest" },
	{ "TowerWest", "TowerSouth" },
	{ "TowerSouth", "GardenWest" },
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
} :: { Obstacle })

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

-- The stones of one path from a to b (seeded by `seed`).
function PathPlan.curve(a: Vector2, b: Vector2, seed: number): { Stone }
	local d = b - a
	local length = d.Magnitude
	if length < 1 then
		return {}
	end
	local side = Vector2.new(-d.Y, d.X).Unit
	local bow = math.min(length * PathPlan.BOW, 4) * (if hash(seed) > 0.5 then 1 else -1)
	local n = math.max(2, math.floor(length / PathPlan.STEP))
	local out: { Stone } = {}
	for i = 0, n do
		local t = i / n
		local along = a + d * t
		local offset = side * (math.sin(t * math.pi) * bow + math.sin(t * math.pi * 3 + seed) * 0.6)
		local w = PathPlan.WIDTH_MIN + (PathPlan.WIDTH_MAX - PathPlan.WIDTH_MIN) * hash(seed * 31 + i)
		table.insert(out, { at = along + offset, width = w })
	end
	return out
end

-- The stones of one lab segment (index i in LAB_SEGMENTS).
function PathPlan.segment(i: number): { Stone }
	local seg = PathPlan.LAB_SEGMENTS[i]
	local P = PathPlan.LAB_POINTS :: any
	return PathPlan.curve(P[seg[1]], P[seg[2]], i)
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

return PathPlan
