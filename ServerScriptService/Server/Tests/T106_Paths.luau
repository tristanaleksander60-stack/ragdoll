--!strict
-- V7-2: paths to everything (Shared/PathPlan, PathBuilder).
--   the lab's paths are a tree: every segment keeps clear of every machine, every goal is the end
--   of a segment; the lab stays in its budget;
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
		-- The tree: every segment has stones, keeps clear of every machine (with its own half
		-- width) and every goal is reached by the end of a segment.
		local P = PathPlan.LAB_POINTS :: any
		for i, seg in PathPlan.LAB_SEGMENTS do
			assert(P[seg[1]] and P[seg[2]], "an unknown point in segment " .. i)
			local stones = PathPlan.segment(i)
			assert(#stones >= 2, seg[1] .. "->" .. seg[2] .. " has no stones")
			for _, s in stones do
				assert(s.width >= PathPlan.WIDTH_MIN and s.width <= PathPlan.WIDTH_MAX, "a stone out of the width range")
			end
			local ok, hit = PathPlan.clear(stones, PathPlan.OBSTACLES)
			assert(ok, seg[1] .. "->" .. seg[2] .. " runs into the " .. tostring(hit))
		end
		for _, r in PathPlan.LAB_ROUTES do
			local reached = false
			for i, seg in PathPlan.LAB_SEGMENTS do
				local stones = PathPlan.segment(i)
				if seg[2] == r.name and (stones[#stones].at - r.to).Magnitude < 1.5 then
					reached = true
				end
			end
			assert(reached, r.name .. " has no path to it")
		end
		assert(#PathPlan.lab() <= PathPlan.BUDGET, "the lab's paths are over budget")
		-- V8-0.9: the Christmas lab's machines (from 1 Dec) are path obstacles too, so the paths
		-- above keep clear of them; each spot must sit inside its box (the two lists never drift).
		local Playground = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("Playground")) :: any
		for name, spot in Playground.CHRISTMAS_SPOTS do
			local covered = false
			for _, o in PathPlan.OBSTACLES do
				if string.sub(o.name, 1, 4) == "Xmas" and spot.X >= o.min.X and spot.X <= o.max.X and spot.Y >= o.min.Y and spot.Y <= o.max.Y then
					covered = true
				end
			end
			assert(covered, "the Christmas " .. name .. " is not a path obstacle")
		end
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
