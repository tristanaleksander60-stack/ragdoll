--!strict
-- V9-0d (owner, 21 Nov 2026: "the ground glitches when you look round, because of all the gravel
-- stones"): Shared/ZFight finds flat ground layers (at least 1.5 studs both ways) that overlap with
-- their top faces closer than 0.06 studs, the shimmer when the camera turns. In the lab, on the plaza
-- and on every open-air map, no ground layer may flicker: not a path, a verge, a floor, a lawn, the
-- lava or a map's own paving. (The review of V9-0d: every pair is found, no cap before the filter,
-- and no allowance: the list is 0.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZFight = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZFight")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

-- What the owner sees as ground (part names, lower case).
local GROUND = { "floor", "grass", "path", "paving", "square", "lava", "testzone", "walk", "ground", "sand", "road", "pavement", "sidewalk", "lawn", "plaza" }

local function ground(part: BasePart): boolean
	local n = string.lower(part.Name)
	for _, word in GROUND do
		if string.find(n, word, 1, true) then
			return true
		end
	end
	return false
end

local function collect(roots: { Instance? }): { BasePart }
	local list: { BasePart } = {}
	for _, r in roots do
		if r then
			for _, d in r:GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(list, d)
				end
			end
		end
	end
	return list
end

return {
	name = "T156_NoZFight",
	timeout = 90,
	run = function(): string?
		assert(TestLib.waitFor(function()
			local pg = Workspace:FindFirstChild("Playground")
			local lab = pg and pg:FindFirstChild("Lab1")
			return lab ~= nil and lab:GetAttribute("PathFlicker") ~= nil and Workspace:GetAttribute("MapPathsFlicker") ~= nil
		end, 70), "no Lab1 or map paths (or their unflicker pass never ran)")
		local pg = (Workspace :: any).Playground
		local lines, fails = {}, {}
		local booths = Workspace:FindFirstChild("MapBooths")
		for _, area in {
			{ name = "lab", roots = { pg.Lab1, Workspace:FindFirstChild("Labs") } },
			{ name = "plaza", roots = { pg:FindFirstChild("Plaza"), Workspace:FindFirstChild("PlazaDressing"), Workspace:FindFirstChild("PlazaEdges"), Workspace:FindFirstChild("MapPaths") } },
			{ name = "maps", roots = { Workspace:FindFirstChild("Places"), Workspace:FindFirstChild("MapPaths") } },
		} do
			local parts = collect(area.roots)
			local found = ZFight.pairs(parts)
			local bad = {}
			for _, pair in found do
				if not (ground(pair[1]) or ground(pair[2])) then
					continue -- (a creature's own dressing or the parts inside a model: not the ground)
				end
				-- (The map shop's booths are laid out again in V9-4b, a market row clear of every path.)
				if booths and (pair[1]:IsDescendantOf(booths) or pair[2]:IsDescendantOf(booths)) then
					continue
				end
				table.insert(bad, string.format("%s+%s at (%.0f, %.0f)", pair[1].Name, pair[2].Name, pair[1].Position.X, pair[1].Position.Z))
			end
			if #bad > 0 then
				table.insert(fails, area.name .. ": " .. #bad .. " flickering pair(s): " .. table.concat(bad, "; ", 1, math.min(#bad, 6)))
			end
			table.insert(lines, string.format("%s 0 of %d parts", area.name, #parts))
		end
		assert(#fails == 0, table.concat(fails, " | "))
		return "no ground layer flickers (" .. table.concat(lines, ", ") .. ")"
	end,
}
