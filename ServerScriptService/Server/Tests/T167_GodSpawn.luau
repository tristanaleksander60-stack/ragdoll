--!strict
-- V9-0l (owner, 21 Nov 2026: "give everyone GOD MODE free in the beta ... and make it easy to spawn e.g.
-- 10 quickly where you want"):
--   * the beta gift: given once a visit (attribute GodBeta, remembered in the profile), a newcomer only
--     after a first wow or 90 s and a calm moment (DummySpawn.betaDue), no trial while it is free; the
--     SHOP calls it FREE during beta; a pass owner is a FOUNDER;
--   * a 10-dummy line comes down where it is aimed, all ten in your own lab; a spot outside the lab is
--     refused; a 25-grid is cut to the cap and the cap holds; a second pattern at once is paced.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local GodPattern = require(Shared:WaitForChild("GodPattern")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T167_GodSpawn",
	timeout = 60,
	run = function(): string?
		if not (Config.GOD_FREE_BETA and Config.DUMMY_TYPES) then
			return "skipped (GOD_FREE_BETA or DUMMY_TYPES off)"
		end
		-- The patterns.
		local line = GodPattern.offsets("Line", 10, 4, 0)
		assert(#line == 10 and math.abs((line[10] - line[1]).Magnitude - 36) < 0.01, "a 10-line is not 10 spaced 4 apart")
		local tower = GodPattern.offsets("Tower", 5, 4, 0)
		assert(tower[5].Y > tower[1].Y + 15 and tower[5].X == 0, "a tower does not stack up")
		assert(#GodPattern.offsets("Grid", 25, 4, 1) == 25 and #GodPattern.offsets("Rain", 99, 4, 0) == 25, "amounts are not cut to 1-25")
		-- The moment that fits.
		local DummySpawn = require(Systems:WaitForChild("DummySpawn")) :: any
		assert(not DummySpawn.betaDue(0, false, 30, 10), "a newcomer got it before a wow and before 90 s")
		assert(not DummySpawn.betaDue(3, false, 30, 0.5), "it came in the middle of the action")
		assert(DummySpawn.betaDue(3, false, 30, 3) and DummySpawn.betaDue(0, true, 20, 3) and DummySpawn.betaDue(0, false, 91, 3), "it did not come after a wow or at 90 s, calm")
		-- The SHOP.
		local ShopArt = require(Shared:WaitForChild("ShopArt")) :: any
		local god = ShopArt.byKey("God")
		assert(god and string.find(god.line, "FREE", 1, true), "the SHOP does not call GOD MODE free in the beta")
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			-- (and Roblox's first word on the passes: its apply() would set God back mid-test)
			return p ~= nil and p.Character ~= nil and (require(Systems:WaitForChild("MoneyService")) :: any).passesCheckedForTest(p)
		end, 30)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "patterns, moment and SHOP checked (no player for the rest)"
		end
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		local MoneyService = require(Systems:WaitForChild("MoneyService")) :: any
		local ProgressService = require(Systems:WaitForChild("ProgressService")) :: any
		local character = p.Character :: Model
		local home = character:GetPivot()
		local hadGod = p:GetAttribute("God")
		local e = ProgressService.ecoOf(p)
		local hadSeen = e and e.codes.GODBETA
		local results = {}
		local ok, err = pcall(function()
			-- A pass owner is a FOUNDER (the creator owns every pass in Studio).
			if MoneyService.owns(p, "God") then
				assert(p:GetAttribute("Founder") == true, "a GOD MODE owner is not a FOUNDER in the beta")
				table.insert(results, "the pass owner is a FOUNDER")
			end
			-- The gift: once a visit, remembered.
			p:SetAttribute("God", false)
			DummySpawn.resetBetaForTest(p)
			assert(DummySpawn.grantBeta(p) and p:GetAttribute("GodBeta") == true, "the beta gift was not given")
			assert(not DummySpawn.grantBeta(p), "the beta gift was given twice in a visit")
			assert(DummySpawn.mayCreate(p) and not DummySpawn.tryFor(p), "with the beta gift it cannot create, or it got a trial")
			if e then
				assert(e.codes.GODBETA == true, "the profile does not remember the first reveal")
			end
			-- A 10-line where it is aimed, all in the lab.
			local origin = Lab.originFor(p)
			character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, 0)))
			task.wait(0.4)
			DummySpawn.clear(p)
			local aim = origin + Vector3.new(0, 0, 18)
			task.wait(DummySpawn.MANY_GAP + 0.05)
			local n, why = DummySpawn.spawnMany(p, "MINI", aim, "Line", 10, 4, 0)
			assert(n == 10, "a 10-line came down as " .. n .. " (" .. tostring(why) .. ")")
			task.wait(DummySpawn.STAGGER + 0.4)
			local inLab = 0
			for _, m in DummySpawn.of(p) do
				local pelvis = m:FindFirstChild("LowerTorso")
				if pelvis and pelvis:IsA("BasePart") and Lab.ownerAt(pelvis.Position) == p and (pelvis.Position - aim).Magnitude < 25 then
					inLab += 1
				end
			end
			assert(inLab == 10, inLab .. " of the 10 came down where aimed, in the lab")
			-- Paced: a second pattern at once is refused.
			local again, slow = DummySpawn.spawnMany(p, "MINI", aim, "Grid", 5, 4, 0)
			assert(again == 0 and slow == "slow down", "a second pattern at once was not paced")
			-- Outside the lab: refused.
			task.wait(DummySpawn.MANY_GAP + 0.05)
			local outside, refused = DummySpawn.spawnMany(p, "MINI", Lab.plazaOrigin() + Vector3.new(0, 0, 30), "Point", 1, 4, 0)
			assert(outside == 0 and refused ~= nil, "a spot outside the lab was not refused")
			-- 25 is cut to the cap, and the cap holds.
			task.wait(DummySpawn.MANY_GAP + 0.05)
			local cap = DummySpawn.capFor(p)
			local big = DummySpawn.spawnMany(p, "HEAVY", aim, "Grid", 25, 4, 0)
			task.wait(DummySpawn.STAGGER + 0.4)
			assert(big <= cap and #DummySpawn.of(p) <= cap, string.format("%d came, %d stand (cap %d)", big, #DummySpawn.of(p), cap))
			table.insert(results, string.format("a 10-line where aimed, all in the lab; paced; outside refused; 25 cut to %d (cap %d)", big, cap))
		end)
		DummySpawn.clear(p)
		DummySpawn.resetBetaForTest(p)
		p:SetAttribute("God", hadGod)
		if e then
			e.codes.GODBETA = hadSeen
			ProgressService.ecoChanged(p)
		end
		character:PivotTo(home)
		assert(ok, err)
		return "patterns right; given after a wow or 90 s and calm, once, remembered, no trial; SHOP says FREE; " .. table.concat(results, "; ")
	end,
}
