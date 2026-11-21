--!strict
-- V9-P (owner, 21 Nov 2026: "make the BEST physics on all of Roblox. It is the most important thing"): the
-- physics bench's automated scenes (Tests/Lib/PhysicsBench) against the targets: no limb through the
-- floor, no speed explosions, settled within SETTLE_MAX s, next to no jitter at rest. The numbers are
-- printed ([PhysicsBench]) for docs/PHYSICS.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local SETTLE_MAX = 1.5 -- s (the target, fix round 1)
local JITTER_MAX = 0.3 -- studs/s at rest

return {
	name = "T183_PhysicsBench",
	timeout = 600,
	run = function(): string?
		local Bench = require(script.Parent:WaitForChild("Lib"):WaitForChild("PhysicsBench")) :: any
		-- (Fix round 1: one run is noisy (±50% on a settle time). ServerStorage attribute BenchRuns = N runs
		-- the bench N times and reports each scene's median; spikes, sunk and down frames are the worst run's.)
		local runs = math.clamp(tonumber(game:GetService("ServerStorage"):GetAttribute("BenchRuns")) or 1, 1, 7)
		local byName: { [string]: { any } } = {}
		local order: { string } = {}
		for _ = 1, runs do
			for _, r in Bench.run() do
				if not byName[r.name] then
					byName[r.name] = {}
					table.insert(order, r.name)
				end
				table.insert(byName[r.name], r)
			end
		end
		local function median(list: { any }, key: string): number
			local values = {}
			for _, r in list do
				table.insert(values, r[key] or math.huge)
			end
			table.sort(values)
			return values[math.floor((#values + 1) / 2)]
		end
		local results = {}
		for _, name in order do
			local list = byName[name]
			local m = table.clone(list[1])
			for _, key in { "trunk", "rel", "peak", "jitter", "spin", "physicsMs", "settle" } do
				local v = median(list, key)
				m[key] = if v == math.huge then nil else v
			end
			for _, r in list do
				m.spikes = math.max(m.spikes, r.spikes)
				m.sunk = math.max(m.sunk, r.sunk)
				m.down = math.max(m.down, r.down)
				if not r.settle then
					m.settle = nil -- (never settled in some run: shown as NEVER)
				end
			end
			if runs > 1 then
				m.trace = string.format(" (median of %d)", runs)
			end
			table.insert(results, m)
		end
		local lines = {}
		local problems = {}
		for _, r in results do
			table.insert(lines, Bench.format(r))
			print("[PhysicsBench] " .. Bench.format(r)) -- (the numbers also when a target fails)
			if r.sunk > 0 then
				table.insert(problems, r.name .. ": a limb through the floor in " .. r.sunk .. " frames")
			end
			if r.spikes > 0 then
				table.insert(problems, string.format("%s: %d frames over the cap (trunk %.0f of %.0f, limb against pelvis %.0f)", r.name, r.spikes, r.trunk, r.cap, r.rel))
			end
			if not r.settle or r.settle > SETTLE_MAX then
				table.insert(problems, r.name .. ": settled " .. (if r.settle then string.format("in %.1f s", r.settle) else "never"))
			end
			if r.down > 0 then
				table.insert(problems, r.name .. ": a living body was down in " .. r.down .. " frames")
			end
			if r.jitter > JITTER_MAX then
				table.insert(problems, string.format("%s: jitter %.2f studs/s at rest", r.name, r.jitter))
			end
		end
		assert(#results >= 7, #results .. " bench scenes ran")
		if Config.PHYSICS_V9 then
			assert(#problems == 0, table.concat(problems, "; "))
		end
		return (if #problems > 0 then "BASELINE (PHYSICS_V9 off): " .. table.concat(problems, "; ") .. " | " else "") .. table.concat(lines, " | ")
	end,
}
