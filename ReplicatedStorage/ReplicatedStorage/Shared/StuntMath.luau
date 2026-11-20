--!strict
-- V8-1.1 (the CRASH score): what a flight is worth (pure; StuntScore and the HUD use it, T117 checks
-- it). A flight is what the server measured from a launch to the landing: air time, distance, flips,
-- bounces, machine hits on the way and the bullseye. Named, mild tricks; a chain of flights within
-- CHAIN_GAP s multiplies the next one.

local StuntMath = {}

StuntMath.PER_AIR_SECOND = 100
StuntMath.PER_STUD = 4
StuntMath.PER_FLIP = 150
StuntMath.PER_BOUNCE = 75
StuntMath.PER_MACHINE = 200
StuntMath.BULLSEYE = 1000
StuntMath.CHAIN_GAP = 12 -- s from one landing to the next launch that keeps a chain
StuntMath.CHAIN_STEP = 0.25 -- each flight in a chain adds this to the multiplier
StuntMath.CHAIN_MAX = 2 -- the multiplier at most

export type Flight = {
	air: number, -- s in the air
	distance: number, -- studs from launch to landing, flat
	flips: number, -- whole turns of the body
	bounces: number, -- times it hit the ground and went up again
	machines: number, -- machines that hit it on the way
	bullseye: boolean,
}

export type Result = { score: number, tricks: { string }, multiplier: number }

-- The score of one flight, and the named tricks in it. `chain` is how many flights came just
-- before it (0: none).
function StuntMath.score(f: Flight, chain: number?): Result
	local base = f.air * StuntMath.PER_AIR_SECOND
		+ f.distance * StuntMath.PER_STUD
		+ f.flips * StuntMath.PER_FLIP
		+ f.bounces * StuntMath.PER_BOUNCE
		+ f.machines * StuntMath.PER_MACHINE
		+ (if f.bullseye then StuntMath.BULLSEYE else 0)
	local tricks = {}
	if f.bullseye then
		table.insert(tricks, "BULLSEYE!")
	end
	if f.air >= 2.5 then
		table.insert(tricks, "BIG AIR")
	end
	if f.flips >= 3 then
		table.insert(tricks, "MEGA FLIP")
	elseif f.flips >= 1 then
		table.insert(tricks, if f.flips == 1 then "FLIP" else string.format("FLIP x%d", f.flips))
	end
	if f.bounces >= 2 then
		table.insert(tricks, string.format("BOUNCE x%d", f.bounces))
	end
	if f.distance >= 80 then
		table.insert(tricks, "LONG SHOT")
	end
	if f.machines >= 1 then
		table.insert(tricks, if f.machines == 1 then "MACHINE HIT" else string.format("MACHINE x%d", f.machines))
	end
	local mult = math.min(StuntMath.CHAIN_MAX, 1 + StuntMath.CHAIN_STEP * math.max(0, chain or 0))
	if mult > 1 then
		table.insert(tricks, string.format("CHAIN x%.2g", mult))
	end
	return { score = math.floor(base * mult + 0.5), tricks = tricks, multiplier = mult }
end

-- "12,345"
function StuntMath.format(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return out
end

return StuntMath
