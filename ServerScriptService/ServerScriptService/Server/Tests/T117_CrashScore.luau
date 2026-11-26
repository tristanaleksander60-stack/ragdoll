--!strict
-- V8-1.1 (the CRASH score):
--   the same flight scores the same every time; tricks and chains are named;
--   the player fired from their own lab's cannon flies the long arc (2.5 s or more in the air with
--   the slow-mo beat), lands on the bullseye, is scored, and the best is kept.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local StuntMath = require(Shared:WaitForChild("StuntMath")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")
local StuntScore = require(Systems:WaitForChild("StuntScore")) :: any
local Lab = require(Systems:WaitForChild("Lab")) :: any
local PlayerRagdoll = require(Systems:WaitForChild("PlayerRagdoll")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T117_CrashScore",
	timeout = 60,
	run = function(): string?
		if not Config.STUNT_SCORE then
			return "skipped (STUNT_SCORE off)"
		end
		-- The sums.
		local f = { air = 2.6, distance = 70, flips = 2, bounces = 2, machines = 0, bullseye = true }
		local a, b = StuntMath.score(f, 0), StuntMath.score(f, 0)
		assert(a.score == b.score and a.score > 0, "the same flight scored differently")
		assert(table.find(a.tricks, "BULLSEYE!") and table.find(a.tricks, "BIG AIR") and table.find(a.tricks, "BOUNCE x2"), "tricks not named: " .. table.concat(a.tricks, ","))
		local chained = StuntMath.score(f, 2)
		assert(chained.score > a.score and chained.multiplier == 1.5, "a chain did not multiply")
		assert(StuntMath.format(12345) == "12,345", "the number format is wrong")
		-- The cannon, for real.
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil and p.Character:FindFirstChild("HumanoidRootPart") ~= nil
		end, 20)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "sums right; skipped the flight (no player)"
		end
		local pad: BasePart? = nil
		for _, d in (Workspace:WaitForChild("Playground") :: Instance):GetDescendants() do
			if d.Name == "CannonPad" and d:IsA("BasePart") and Lab.ownerAt(d.Position) == p then
				pad = d
			end
		end
		if not pad then
			return "sums right; skipped the flight (no own lab with a cannon)"
		end
		local bestBefore = StuntScore.bestOf(p, "Cannon")
		pcall(PlayerRagdoll.getUp, p)
		task.wait(1.5)
		StuntScore.lastForTest = nil
		local character = p.Character :: Model
		character:PivotTo(CFrame.new((pad :: BasePart).Position + Vector3.new(0, 3.5, 0)))
		assert(TestLib.waitFor(function()
			return StuntScore.isFlying(p)
		end, 4), "the cannon did not start a flight")
		assert(TestLib.waitFor(function()
			return StuntScore.lastForTest ~= nil
		end, 14), "the flight never landed")
		local last = StuntScore.lastForTest
		assert(last.player == p, "the flight is someone else's")
		assert(last.flight.air >= 2.5, string.format("only %.1f s in the air (want 2.5+)", last.flight.air))
		assert(last.flight.bullseye, "the long arc missed the bullseye")
		assert(StuntScore.bestOf(p, "Cannon") >= math.max(bestBefore, last.result.score), "the best was not kept")
		pcall(PlayerRagdoll.getUp, p)
		return string.format("sums right, tricks named, chains x1.5; cannon: %.1f s in the air, bullseye, CRASH %d, best kept", last.flight.air, last.result.score)
	end,
}
