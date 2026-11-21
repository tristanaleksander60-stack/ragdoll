--!strict
-- V9-NOW 11 (owner, 21 Nov 2026: "the big target blocks topple when shot"): the lab's three target blocks are
-- knockable Blocks; 5 pistol shots at one within 2 s tip it over (past Knockables.FALLEN_TILT), it stays near its
-- spot (inside the lab), and it goes home upright (as after RETURN_AFTER s still, or RESET).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

local function tilt(part: BasePart): number
	return math.deg(math.acos(math.clamp(part.CFrame.UpVector.Y, -1, 1)))
end

return {
	name = "T187_TargetBlocks",
	timeout = 30,
	run = function(): string?
		if not Config.TARGET_BLOCKS then
			return "skipped (TARGET_BLOCKS off)"
		end
		local Knockables = require(Systems:WaitForChild("Knockables")) :: any
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		local lab: Instance? = nil
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			local index = p and Lab.plotIndex(p)
			local labs = Workspace:FindFirstChild("Labs")
			lab = labs and labs:FindFirstChild("Lab" .. tostring(index or 1))
			return lab ~= nil and (lab :: Instance):FindFirstChild("TargetBlock") ~= nil
		end, 20)
		assert(lab, "no lab")
		local blocks = {}
		for _, m in (lab :: Instance):GetChildren() do
			if m:IsA("Model") and m.Name == "TargetBlock" then
				table.insert(blocks, m)
			end
		end
		assert(#blocks == 3, #blocks .. " target blocks (want 3)")
		local body = (blocks[2] :: Model).PrimaryPart :: BasePart
		assert(body and body.Anchored, "a target block is not resting anchored")
		local home = body.CFrame
		local toward = home.LookVector * -1 -- (the side facing the spawn: where a player shoots from)
		local hits = 0
		for _ = 1, 5 do
			-- (Aimed at the block as it is now: a rocking block moves.)
			local face = body.Position + toward * (body.Size.Z / 2) + Vector3.new(0, 2, 0)
			local from = face + toward * 25
			if Knockables.shot(face, from) then
				hits += 1
			end
			task.wait(0.3)
		end
		assert(hits == 5, hits .. " of 5 shots reached the block")
		local most = 0
		for _ = 1, 30 do
			most = math.max(most, tilt(body))
			task.wait(0.1)
		end
		local away = (body.Position - home.Position) * Vector3.new(1, 0, 1)
		assert(most >= Knockables.FALLEN_TILT, string.format("5 shots tipped it only %.0f deg", most))
		assert(away.Magnitude < 25, string.format("it ended %.0f studs from its spot", away.Magnitude))
		Knockables.sendHomeForTest(body)
		task.wait(0.2)
		assert(body.Anchored and tilt(body) < 1 and (body.Position - home.Position).Magnitude < 0.1, "it did not stand back up at its spot")
		return string.format("3 blocks; 5 shots tipped one %.0f deg, %.0f studs from its spot; back home upright", most, away.Magnitude)
	end,
}
