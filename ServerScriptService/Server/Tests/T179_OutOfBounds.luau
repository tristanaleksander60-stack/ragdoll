--!strict
-- V9-0ab (owner, 21 Nov 2026: "if you fall out of your map you spawn back in your lab"; Config.OUT_OF_BOUNDS):
--   * the rule: the labs, the plaza and a cannon flight high over the lab are inside; under the floor, far
--     off a map's edge and between the ground and the maps are out (OutOfBounds.inside);
--   * a player dropped under the Island comes home to their lab within 2 s, tools kept;
--   * a player high over the lab (a legal flight) is left alone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Places = require(Shared:WaitForChild("Places")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T179_OutOfBounds",
	timeout = 40,
	run = function(): string?
		if not Config.OUT_OF_BOUNDS then
			return "skipped (OUT_OF_BOUNDS off)"
		end
		local OutOfBounds = require(Systems:WaitForChild("OutOfBounds")) :: any
		local o = Vector3.new(0, 0.5, 0)
		local island = Places.floorCenter(o, "Island") :: Vector3
		-- The rule.
		assert(OutOfBounds.inside(o + Vector3.new(250, 3, 0), o), "a lab is out of bounds")
		assert(OutOfBounds.inside(o + Vector3.new(0, 3, 85), o), "the plaza is out of bounds")
		assert(OutOfBounds.inside(o + Vector3.new(250, 300, 40), o), "a cannon flight high over the lab is out of bounds")
		assert(OutOfBounds.inside(island + Vector3.new(0, 5, 0), o), "standing on the Island is out of bounds")
		assert(not OutOfBounds.inside(o + Vector3.new(250, -60, 0), o), "under the lab's floor is in bounds")
		assert(not OutOfBounds.inside(island + Vector3.new(0, -80, 0), o), "under the Island is in bounds")
		assert(not OutOfBounds.inside(island + Vector3.new(600, 0, 0), o), "far off the Island's edge is in bounds")
		assert(not OutOfBounds.inside(o + Vector3.new(0, 2000, 0), o), "between the ground and the maps is in bounds")
		-- A real player under the Island.
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil and Lab.plotIndex(p) ~= nil
		end, 20)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "the rule holds; skipped the player part (no player with a lab)"
		end
		local character = p.Character :: Model
		local home = character:GetPivot()
		local labOrigin = (Workspace:GetAttribute("LabOrigin") :: Vector3?) or o
		local tools = #p:WaitForChild("Backpack"):GetChildren() + #character:GetChildren()
		local ok, err = pcall(function()
			local root = character:WaitForChild("HumanoidRootPart") :: BasePart
			root.Anchored = true -- (held under the Island: it must not fall forever while it waits)
			character:PivotTo(CFrame.new((Places.floorCenter(labOrigin, "Island") :: Vector3) + Vector3.new(0, -90, 0)))
			local t0 = os.clock()
			local back = false
			while os.clock() - t0 < 2.5 do
				task.wait(0.1)
				if OutOfBounds.inside(root.Position, labOrigin) then
					back = true
					break
				end
			end
			root.Anchored = false
			assert(back, "a player under the Island was not sent home within 2 s")
			assert(Lab.ownerAt(root.Position) == p, "the player came home somewhere else than their lab")
			assert(#p.Backpack:GetChildren() + #character:GetChildren() >= tools - 1, "tools were lost on the way home")
			-- High over the lab: left alone.
			character:PivotTo(CFrame.new(Lab.originFor(p) + Vector3.new(0, 300, 0)))
			root.Anchored = true
			local before = root.Position
			task.wait(1.2)
			root.Anchored = false
			assert((root.Position - before).Magnitude < 1, "a player high over the lab was sent somewhere")
		end)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.Anchored = false
		end
		character:PivotTo(home)
		assert(ok, err)
		return "inside: labs, the plaza, a flight high over the lab, the Island; out: under the floor, under the Island, off its edge, between the ground and the maps; a player under the Island came home to their lab with their tools; one high over the lab was left alone"
	end,
}
