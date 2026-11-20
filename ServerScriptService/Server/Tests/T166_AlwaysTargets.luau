--!strict
-- V9-0j (owner, 21 Nov 2026: "make sure ragdolls walk round your lab so there is always one to
-- shoot"), run on the real loop (VisitorService.loopInTests), not by calling it faster:
--   * every body of the lab knocked out (Vital Dead): within 3 s at least Config.LAB_MIN_TARGETS
--     stand again, walkers in from the rim, each on free floor (no machine footprint, no lava);
--   * three mass knockouts in a row never push the lab past the device's ragdoll cap (FX_CAPS);
--   * a newcomer's first minute brings none; out of the lab, none walk in.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local PathPlan = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PathPlan")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

local function inMachine(p: Vector2): boolean
	for _, o in PathPlan.OBSTACLES do
		if o.at and o.radius and (p - o.at).Magnitude < o.radius then
			return true
		elseif o.min and o.max and p.X > o.min.X and p.X < o.max.X and p.Y > o.min.Y and p.Y < o.max.Y then
			return true
		end
	end
	return false
end

return {
	name = "T166_AlwaysTargets",
	timeout = 60,
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
		local wasNewcomer, wasSpawned = player:GetAttribute("Newcomer"), player:GetAttribute("SpawnedAt")
		local tier = "high"
		pcall(function()
			local SessionStats = require(Systems:WaitForChild("SessionStats")) :: any
			local DeviceTier = require(ReplicatedStorage.Shared.DeviceTier) :: any
			local record = SessionStats.recordFor(player)
			tier = DeviceTier.of(record and record.plat)
		end)
		local want = Config.LAB_MIN_TARGETS[tier]
		local cap = Config.FX_CAPS[tier].ragdolls
		local knocked: { [Model]: any } = {}
		local function knockAll()
			for _, m in VisitorService.bodiesOf(player) do
				if knocked[m] == nil then
					knocked[m] = m:GetAttribute("Vital") or false
				end
				m:SetAttribute("Vital", "Dead")
			end
		end
		local function standingNow(): number
			local up = 0
			for _, m in VisitorService.bodiesOf(player) do
				if VisitorService.standing(m) then
					up += 1
				end
			end
			return up
		end
		VisitorService.clearForTest(player)
		local ok, err = pcall(function()
			-- A newcomer's first minute: none.
			character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, 0)))
			task.wait(0.4)
			player:SetAttribute("Newcomer", true)
			player:SetAttribute("SpawnedAt", Workspace:GetServerTimeNow())
			knockAll()
			assert(VisitorService.keepTargets(player) == 0, "walkers came in during a newcomer's first minute")
			player:SetAttribute("Newcomer", nil)
			-- Out of the lab, on the real loop: none.
			VisitorService.loopInTests(true)
			character:PivotTo(CFrame.new(Lab.plazaOrigin() + Vector3.new(0, 4, 60)))
			task.wait(2.2)
			assert(#VisitorService.of(player) == 0, "walkers came in while the player was out of the lab")
			-- Back in, everything knocked out: the real loop brings the minimum within 3 s.
			character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, 0)))
			knockAll()
			local started = os.clock()
			local up = 0
			while os.clock() - started < 3 do
				task.wait(0.25)
				up = standingNow()
				if up >= want then
					break
				end
			end
			local took = os.clock() - started
			assert(up >= want, string.format("only %d standing after 3 s on the real loop (want %d)", up, want))
			-- Every walker came in on free floor.
			for _, m in VisitorService.of(player) do
				local at = m:GetAttribute("WalkInAt")
				if typeof(at) == "Vector3" then
					assert(not inMachine(Vector2.new(at.X - origin.X, at.Z - origin.Z)), "a walker came in inside a machine at " .. tostring(at))
					local hit = Workspace:Raycast(at + Vector3.new(0, 2, 0), Vector3.new(0, -10, 0))
					assert(not (hit and string.find(hit.Instance.Name, "Lava")), "a walker came in over the lava")
				end
			end
			-- Three mass knockouts: never past the cap.
			local most = 0
			for _ = 1, 3 do
				knockAll()
				task.wait(2.2)
				most = math.max(most, #VisitorService.bodiesOf(player))
			end
			assert(most <= cap, string.format("%d bodies in the lab after mass knockouts (cap %d)", most, cap))
			return string.format("everything knocked out: %d standing in %.1f s on the real loop (want %d, %s); walkers on free floor; after 3 mass knockouts at most %d bodies (cap %d); none for a newcomer or out of the lab", up, took, want, tier, most, cap)
		end)
		VisitorService.loopInTests(false)
		for m, was in knocked do
			if m.Parent then
				m:SetAttribute("Vital", if was == false then nil else was)
			end
		end
		VisitorService.clearForTest(player)
		player:SetAttribute("Newcomer", wasNewcomer)
		player:SetAttribute("SpawnedAt", wasSpawned)
		character:PivotTo(home)
		assert(ok, err)
		return err
	end,
}
