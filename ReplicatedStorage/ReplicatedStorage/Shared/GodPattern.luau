--!strict
-- V9-0l (owner, 21 Nov 2026: "make GOD MODE much better so it is easy to spawn e.g. 10 quickly where you
-- want, not just random places"): where the ragdolls of one creation go, round the aim point. Pure: the
-- server's DummySpawn places them (and checks each), the client's GodMode draws the ghost preview from
-- the same offsets, T167 checks them.
--   Point  one spot (more pile up a little round it)
--   Line   a row across where you look, `spacing` apart
--   Circle a ring round the point
--   Grid   rows and columns
--   Tower  stacked up, each on the one under it
--   Rain   scattered over the spot from high up

local GodPattern = {}

GodPattern.PATTERNS = table.freeze({ "Point", "Line", "Circle", "Grid", "Tower", "Rain" })
GodPattern.AMOUNTS = table.freeze({ 1, 5, 10, 25 })
GodPattern.SPACING_MIN = 2.5
GodPattern.SPACING_MAX = 9
GodPattern.SPACING = 4
GodPattern.TOWER_STEP = 4.4 -- studs between two in a tower
GodPattern.RAIN_HEIGHT = 22

local function rot(v: Vector3, yaw: number): Vector3
	local c, s = math.cos(yaw), math.sin(yaw)
	return Vector3.new(v.X * c + v.Z * s, v.Y, -v.X * s + v.Z * c)
end

-- A small repeatable scatter (no math.random: the preview and the server agree).
local function hash(i: number, salt: number): number
	local x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453
	return x - math.floor(x)
end

-- The offsets (studs, from the aim point on the floor) of `count` bodies in `pattern`, `spacing`
-- apart, turned by `yaw` (radians about the up axis: the way the player looks).
function GodPattern.offsets(pattern: string, count: number, spacing: number, yaw: number): { Vector3 }
	local n = math.clamp(math.floor(count), 1, 25)
	local s = math.clamp(spacing, GodPattern.SPACING_MIN, GodPattern.SPACING_MAX)
	local out: { Vector3 } = {}
	if pattern == "Line" then
		for i = 1, n do
			table.insert(out, Vector3.new((i - (n + 1) / 2) * s, 0, 0))
		end
	elseif pattern == "Circle" then
		local r = math.max(s, s * n / (2 * math.pi))
		for i = 1, n do
			local a = (i - 1) / n * math.pi * 2
			table.insert(out, Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
		end
	elseif pattern == "Grid" then
		local cols = math.ceil(math.sqrt(n))
		local rows = math.ceil(n / cols)
		for i = 1, n do
			local c = (i - 1) % cols
			local r = (i - 1) // cols
			table.insert(out, Vector3.new((c - (cols - 1) / 2) * s, 0, (r - (rows - 1) / 2) * s))
		end
	elseif pattern == "Tower" then
		for i = 1, n do
			table.insert(out, Vector3.new(0, (i - 1) * GodPattern.TOWER_STEP, 0))
		end
	elseif pattern == "Rain" then
		local radius = s * math.sqrt(n) * 0.8
		for i = 1, n do
			local a = hash(i, 1) * math.pi * 2
			local r = math.sqrt(hash(i, 2)) * radius
			table.insert(out, Vector3.new(math.cos(a) * r, GodPattern.RAIN_HEIGHT + hash(i, 3) * 8, math.sin(a) * r))
		end
	else -- Point
		for i = 1, n do
			if i == 1 then
				table.insert(out, Vector3.zero)
			else
				local a = i * 2.39996 -- (the golden angle: a tidy little heap)
				local r = 1.6 * math.sqrt(i)
				table.insert(out, Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
			end
		end
	end
	for i, v in out do
		out[i] = rot(v, yaw)
	end
	return out
end

-- The next pattern or amount in a list (the keys, the pad's D-pad).
function GodPattern.step(list: { any }, current: any, by: number): any
	local i = table.find(list, current) or 1
	return list[((i - 1 + by) % #list) + 1]
end

return GodPattern
