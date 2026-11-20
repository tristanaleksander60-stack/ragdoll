--!strict
-- V7-2: paths to everything (Shared/PathPlan, PathBuilder).
--   every lab route has stones and its last stone reaches its goal; the lab stays in its budget;
--   the stones never collide or block a ray (pictures only); the lab is built with them;
--   the plaza and every open-air map got repainted paths.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PathPlan = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PathPlan"))

local function waitFor(check: () -> boolean, seconds: number): boolean
	local t0 = os.clock()
	while not check() do
		if os.clock() - t0 > seconds then
			return false
		end
		task.wait(0.25)
	end
	return true
end

return {
	name = "T106_Paths",
	timeout = 45,
	run = function(): string?
		for i, r in PathPlan.LAB_ROUTES do
			local stones = PathPlan.curve(PathPlan.LAB_HUB, r.to, i)
			assert(#stones >= 2, r.name .. " has no path")
			assert((stones[#stones].at - r.to).Magnitude < 1.5, r.name .. "'s path does not reach it")
			for _, s in stones do
				assert(s.width >= PathPlan.WIDTH_MIN and s.width <= PathPlan.WIDTH_MAX, "a stone out of the width range")
			end
		end
		assert(#PathPlan.lab() <= PathPlan.BUDGET, "the lab's paths are over budget")
		-- Built in the lab: pictures only.
		local folder: Instance? = nil
		assert(waitFor(function()
			local pg = Workspace:FindFirstChild("Playground")
			local lab = pg and pg:FindFirstChild("Lab1")
			folder = lab and lab:FindFirstChild("Paths")
			return folder ~= nil
		end, 15), "the lab has no paths")
		local n = 0
		for _, d in (folder :: Instance):GetDescendants() do
			if d:IsA("BasePart") then
				n += 1
				assert(not d.CanCollide and not d.CanQuery and not d.CanTouch, d.Name .. " collides or blocks rays")
			end
		end
		assert(n > 50 and n <= PathPlan.BUDGET, string.format("%d path stones in the lab", n))
		-- The open-air places got painted paths.
		local missing = {}
		assert(waitFor(function()
			missing = {}
			for id in PathPlan.TERRAIN do
				local painted = Workspace:GetAttribute("Paths_" .. id)
				if type(painted) ~= "number" or painted <= 0 then
					table.insert(missing, id)
				end
			end
			return #missing == 0
		end, 30), "no painted paths on: " .. table.concat(missing, ", "))
		return string.format("%d lab routes, %d stones in the lab; paths on %s", #PathPlan.LAB_ROUTES, n, "plaza and every open-air map")
	end,
}
