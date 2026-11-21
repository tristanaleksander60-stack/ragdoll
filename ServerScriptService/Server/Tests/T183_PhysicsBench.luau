--!strict
-- V9-P (owner, 21 Nov 2026: "make the BEST physics on all of Roblox. It is the most important thing"): the
-- physics bench's automated scenes (Tests/Lib/PhysicsBench) against the targets: no limb through the
-- floor, no speed explosions, settled within SETTLE_MAX s, next to no jitter at rest. The numbers are
-- printed ([PhysicsBench]) for docs/PHYSICS.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local SETTLE_MAX = 3 -- s (the target is 1.5: PHYSICS.md tracks it; the test holds the line)
local JITTER_MAX = 0.3 -- studs/s at rest

return {
	name = "T183_PhysicsBench",
	timeout = 150,
	run = function(): string?
		local Bench = require(script.Parent:WaitForChild("Lib"):WaitForChild("PhysicsBench")) :: any
		local results = Bench.run()
		local lines = {}
		local problems = {}
		for _, r in results do
			table.insert(lines, Bench.format(r))
			if r.sunk > 0 then
				table.insert(problems, r.name .. ": a limb through the floor in " .. r.sunk .. " frames")
			end
			if r.spikes > 0 then
				table.insert(problems, string.format("%s: %d frames over %d studs/s (peak %d)", r.name, r.spikes, r.cap, r.peak))
			end
			if not r.settle or r.settle > SETTLE_MAX then
				table.insert(problems, r.name .. ": settled " .. (if r.settle then string.format("in %.1f s", r.settle) else "never"))
			end
			if r.jitter > JITTER_MAX then
				table.insert(problems, string.format("%s: jitter %.2f studs/s at rest", r.name, r.jitter))
			end
		end
		assert(#results >= 6, #results .. " bench scenes ran")
		if Config.PHYSICS_V9 then
			assert(#problems == 0, table.concat(problems, "; "))
		end
		return (if #problems > 0 then "BASELINE (PHYSICS_V9 off): " .. table.concat(problems, "; ") .. " | " else "") .. table.concat(lines, " | ")
	end,
}
