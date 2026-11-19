--!strict
-- Round 5, phase 1: the LEVEL by the weapon bar. No new economy: it is read from what the profile
-- already keeps, takedowns and minutes played. XP = takedowns * PER_TAKEDOWN + minutes * PER_MINUTE;
-- level n needs STEP * n * (n + 1) / 2 XP in all (each level a little longer than the last).

local Level = {}

Level.PER_TAKEDOWN = 10
Level.PER_MINUTE = 4
Level.STEP = 60
Level.MAX = 999

function Level.xp(takedowns: number, playSeconds: number): number
	return math.max(0, math.floor(takedowns)) * Level.PER_TAKEDOWN + math.floor(math.max(0, playSeconds) / 60) * Level.PER_MINUTE
end

-- XP needed in all to reach level n (level 1 needs 0).
function Level.need(n: number): number
	local k = n - 1
	return Level.STEP * k * (k + 1) / 2
end

-- (level, XP into it, XP the level spans).
function Level.of(xp: number): (number, number, number)
	local n = 1
	while n < Level.MAX and xp >= Level.need(n + 1) do
		n += 1
	end
	local from = Level.need(n)
	return n, xp - from, Level.need(n + 1) - from
end

return Level
