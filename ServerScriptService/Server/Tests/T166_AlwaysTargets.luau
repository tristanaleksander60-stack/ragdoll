--!strict
-- V9-0j (owner, 21 Nov 2026: "make sure ragdolls walk round your lab so there is always one to
-- shoot"): with every body of the lab out of play (here: the row taken by the machines), within 3 s
-- at least Config.LAB_MIN_TARGETS stand again: walkers in from the hub's rim. All bodies of the lab
-- stay under the device's ragdoll cap (FX_CAPS), and with the player out of the lab nothing walks in.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T166_AlwaysTargets",
	timeout = 40,
	run = function(): string?
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player and player.Character, "no player in the play test")
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		local VisitorService = require(Systems:WaitForChild("VisitorService")) :: any
		local origin = Lab.originFor(player)
		local character = player.Character :: Model
		local home = character:GetPivot()
		local wasNewcomer = player:GetAttribute("Newcomer")
		player:SetAttribute("Newcomer", nil)
		VisitorService.clearForTest(player)
		-- Every row dummy out of play.
		local row = Lab.dummiesOf(player)
		for _, m in row do
			m:SetAttribute("InMachine", true)
		end
		local ok, err = pcall(function()
			-- Out of the lab: nothing walks in.
			character:PivotTo(CFrame.new(Lab.plazaOrigin() + Vector3.new(0, 4, 60)))
			task.wait(0.4)
			assert(VisitorService.keepTargets(player) == 0, "walkers came in while the player was out of the lab")
			-- In the lab: the minimum stands again within 3 s.
			character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, 0)))
			task.wait(0.4)
			local tier = "high"
			pcall(function()
				local SessionStats = require(Systems:WaitForChild("SessionStats")) :: any
				local DeviceTier = require(ReplicatedStorage.Shared.DeviceTier) :: any
				local record = SessionStats.recordFor(player)
				tier = DeviceTier.of(record and record.plat)
			end)
			local want = Config.LAB_MIN_TARGETS[tier]
			local started = os.clock()
			local up = 0
			while os.clock() - started < 3 do
				VisitorService.keepTargets(player)
				up = 0
				for _, m in VisitorService.bodiesOf(player) do
					if VisitorService.standing(m) then
						up += 1
					end
				end
				if up >= want then
					break
				end
				task.wait(0.5)
			end
			assert(up >= want, string.format("only %d standing after 3 s (want %d)", up, want))
			-- Never past the cap.
			for _ = 1, 4 do
				VisitorService.keepTargets(player)
			end
			local total = #VisitorService.bodiesOf(player)
			local cap = Config.FX_CAPS[tier].ragdolls
			assert(total <= cap, string.format("%d bodies in the lab (cap %d)", total, cap))
			-- The walkers came in from the rim.
			local rim = 0
			for _, m in VisitorService.of(player) do
				if m:GetAttribute("WalkIn") then
					rim += 1
				end
			end
			assert(rim >= 1, "no walker came in")
			return string.format("%d standing within 3 s (want %d, %s), %d bodies (cap %d), %d walked in", up, want, tier, total, cap, rim)
		end)
		for _, m in row do
			m:SetAttribute("InMachine", nil)
		end
		VisitorService.clearForTest(player)
		player:SetAttribute("Newcomer", wasNewcomer)
		character:PivotTo(home)
		assert(ok, err)
		return err
	end,
}
