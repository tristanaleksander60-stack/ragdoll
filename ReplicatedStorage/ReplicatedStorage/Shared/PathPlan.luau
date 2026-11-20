--!strict
-- V7-2: the paths that lead to everything (pure: PathBuilder draws them, T106 checks them).
-- A path is a gentle curve from a start to a goal: points about STEP studs apart, bowing a little
-- to one side (seeded, so every server draws the same), with a width that breathes between
-- WIDTH_MIN and WIDTH_MAX. In the lab the routes are fixed below (from the hub in front of the
-- spawn to each thing to do); on the open-air maps and the plaza they run from the arrival to
-- every launcher and shop booth (found at build time).

local PathPlan = {}

PathPlan.STEP = 2.4 -- studs between two path stones (they overlap well: smooth soft edges, not scallops)
PathPlan.WIDTH_MIN = 4.6
PathPlan.WIDTH_MAX = 5.6
PathPlan.BOW = 0.12 -- how far a path bows sideways, as a share of its length (at most 9 studs)
PathPlan.BUDGET = 400 -- stones per lab at most (phones: flat, anchored, no shadows, no collisions)

-- The lab: x, z from the lab's origin. The hub is the open floor in front of the spawn.
PathPlan.LAB_HUB = Vector2.new(0, 24)
PathPlan.LAB_ROUTES = table.freeze({
	{ name = "Cannon", to = Vector2.new(40, 8) },
	{ name = "Button", to = Vector2.new(14, 20) },
	{ name = "Stations", to = Vector2.new(10, 44) },
	{ name = "Bullseye", to = Vector2.new(-6, -33) },
	{ name = "Lava", to = Vector2.new(-27, -29) },
	{ name = "Mace", to = Vector2.new(-22, 26) },
	{ name = "Tower", to = Vector2.new(-58, -20) },
	{ name = "Portals", to = Vector2.new(-58, 37) },
	{ name = "Wrecking", to = Vector2.new(40, -14) },
	{ name = "Yard", to = Vector2.new(0, 74) },
	{ name = "GardenEast", to = Vector2.new(78, 30) },
	{ name = "GardenWest", to = Vector2.new(-78, -30) },
})

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
	local bow = math.min(length * PathPlan.BOW, 9) * (if hash(seed) > 0.5 then 1 else -1)
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

-- Every stone of the lab's paths.
function PathPlan.lab(): { Stone }
	local all: { Stone } = {}
	for i, r in PathPlan.LAB_ROUTES do
		for _, s in PathPlan.curve(PathPlan.LAB_HUB, r.to, i) do
			table.insert(all, s)
		end
	end
	return all
end

-- Whether a path's stones keep clear of the given circles { at, radius } (machines, walls).
function PathPlan.clear(stones: { Stone }, obstacles: { { at: Vector2, radius: number } }): boolean
	for _, s in stones do
		for _, o in obstacles do
			if (s.at - o.at).Magnitude < o.radius then
				return false
			end
		end
	end
	return true
end

return PathPlan
