--!strict
-- V9-0d (owner, 21 Nov 2026: "the ground glitches when you look round, because of all the gravel
-- stones"): Shared/ZFight finds flat ground layers (at least 1.5 studs both ways) that overlap with
-- their top faces closer than 0.06 studs, the shimmer when the camera turns. In the lab and on the
-- plaza (with the paths of every map) no paving, path verge or floor layer may flicker (a creature's own
-- dressing and the parts inside a model are not ground), but the few where three verges meet at a
-- junction (MAX_JUNCTION).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZFight = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZFight")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

local MAX_JUNCTION = 8 -- (paving or verge pieces of two paths right where they meet: where three roads share one point,
-- not every pair can lie 0.06 apart; they are small and outside the open floor)

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
	timeout = 60,
	run = function(): string?
		assert(TestLib.waitFor(function()
			local pg = Workspace:FindFirstChild("Playground")
			local lab = pg and pg:FindFirstChild("Lab1")
			return lab ~= nil and lab:FindFirstChild("CreatureYard") ~= nil and Workspace:FindFirstChild("MapPaths") ~= nil
		end, 50), "no Lab1 or map paths")
		local pg = (Workspace :: any).Playground
		local lines = {}
		for _, area in {
			{ name = "lab", roots = { pg.Lab1, Workspace:FindFirstChild("Labs") } },
			{ name = "plaza and map paths", roots = { pg:FindFirstChild("Plaza"), Workspace:FindFirstChild("PlazaDressing"), Workspace:FindFirstChild("PlazaEdges"), Workspace:FindFirstChild("MapPaths"), Workspace:FindFirstChild("MapBooths") } },
		} do
			local found = ZFight.pairs(collect(area.roots), 200)
			local verge, other = 0, {}
			for _, pair in found do
				local a, b = pair[1].Name, pair[2].Name
				local function ground(n: string): boolean
					return string.find(n, "^Path") ~= nil or string.find(n, "^Plaza") ~= nil or n == "LabFloor" or n == "TestZone" or n == "Paving" or n == "Square"
				end
				if not (ground(a) or ground(b)) then
					continue -- (a creature's own dressing or a model's parts: not the ground the owner saw shimmer)
				end
				-- (The map shop's booths are laid out again in V9-4b, a market row clear of every path.)
				local booths = Workspace:FindFirstChild("MapBooths")
				if booths and (pair[1]:IsDescendantOf(booths) or pair[2]:IsDescendantOf(booths)) then
					continue
				end
				if string.find(a, "^Path") and string.find(b, "^Path") and pair[1].Parent == pair[2].Parent then
					verge += 1
				else
					table.insert(other, string.format("%s+%s at (%.0f, %.0f)", a, b, pair[1].Position.X, pair[1].Position.Z))
				end
			end
			assert(#other == 0, area.name .. ": " .. #other .. " flickering pair(s): " .. table.concat(other, "; ", 1, math.min(#other, 5)))
			assert(verge <= MAX_JUNCTION, area.name .. ": " .. verge .. " path pairs flicker at junctions")
			table.insert(lines, string.format("%s %d path pair(s) at junctions", area.name, verge))
		end
		return "no ground layer flickers (" .. table.concat(lines, ", ") .. ")"
	end,
}
