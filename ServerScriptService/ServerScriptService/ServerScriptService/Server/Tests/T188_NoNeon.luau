--!strict
-- V9-NOW 18 (owner, 21 Nov 2026: "no neon glow"): with Config.NO_NEON, no Neon part with a side over
-- NoNeon.KEEP_SIZE is left in the labs, the plaza or the maps once they are built (short effects, the lava,
-- characters and tools excepted, as NoNeon.shouldDull says), and no world screen is brighter than 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local NoNeon = require(Shared:WaitForChild("NoNeon")) :: any

return {
	name = "T188_NoNeon",
	timeout = 40,
	run = function(): string?
		if not Config.NO_NEON then
			return "skipped (NO_NEON off)"
		end
		task.wait(NoNeon.SETTLE + 7) -- (the first pass runs 6 s after the start; late parts SETTLE s after they come)
		local bad, bright, looked = {}, {}, 0
		for _, root in { Workspace:FindFirstChild("Labs"), Workspace:FindFirstChild("Playground"), Workspace:FindFirstChild("Places") } do
			if root then
				for _, d in root:GetDescendants() do
					if d:IsA("BasePart") then
						looked += 1
						if NoNeon.shouldDull(d) then
							table.insert(bad, d:GetFullName())
						end
					elseif d:IsA("SurfaceGui") and d.Brightness > 1 then
						table.insert(bright, d:GetFullName())
					end
				end
			end
		end
		assert(#bad == 0, #bad .. " glowing parts left, e.g. " .. table.concat(bad, ", ", 1, math.min(5, #bad)))
		assert(#bright == 0, #bright .. " screens brighter than 1, e.g. " .. table.concat(bright, ", ", 1, math.min(3, #bright)))
		return string.format("%d world parts looked at: no Neon over %.1f stud, no screen over brightness 1 (%d dulled)", looked, NoNeon.KEEP_SIZE, NoNeon.count())
	end,
}
