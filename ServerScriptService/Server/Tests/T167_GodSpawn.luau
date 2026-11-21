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
		assert(not DummySpawn.betaDue(3, true, 45, 30), "a newcomer got it inside the busy first minute")
		assert(not DummySpawn.betaDue(0, false, 90, 10), "a newcomer got it before a wow and before BETA_LATEST")
		assert(not DummySpawn.betaDue(3, false, 70, 1), "it came in the middle of the action (a shot or a takedown just now)")
		assert(DummySpawn.betaDue(3, false, 61, 3) and DummySpawn.betaDue(0, true, 65, 3) and DummySpawn.betaDue(0, false, DummySpawn.BETA_LATEST + 1, 3), "it did not come after a wow past the first minute, or at BETA_LATEST, calm")
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
			-- Bad numbers over the remote: refused or clamped, never a crash or a flood.
			task.wait(DummySpawn.MANY_GAP + 0.05)
			local weird = DummySpawn.spawnMany(p, "MINI", aim, "Line", math.huge, math.huge, 0)
			assert(weird >= 1 and weird <= 25, "an endless count was not clamped: " .. weird)
			for _, bad in { { aim, "Line", 5, 4, math.huge }, { Vector3.new(0 / 0, 0, 0), "Line", 5, 4, 0 }, { aim, "Spiral", 5, 4, 0 }, { aim, "Line", "5", 4, 0 } } do
				task.wait(DummySpawn.MANY_GAP + 0.05)
				local got, refusedWhy = DummySpawn.spawnMany(p, "MINI", bad[1], bad[2], bad[3], bad[4], bad[5])
				assert(got == 0 and refusedWhy == "bad request", "a bad request was not refused: " .. tostring(refusedWhy))
			end
			-- A machine's footprint: no body inside it.
			local PathPlan = require(Shared:WaitForChild("PathPlan")) :: any
			local machine: Vector3? = nil
			for _, ob in PathPlan.OBSTACLES do
				if ob.at and ob.radius and ob.radius >= 3 and ob.at.Magnitude < 70 then
					machine = origin + Vector3.new(ob.at.X, 0, ob.at.Y)
					break
				end
			end
			if machine then
				character:PivotTo(CFrame.new((machine :: Vector3) + Vector3.new(0, 4, 20)))
				task.wait(0.3)
				task.wait(DummySpawn.MANY_GAP + 0.05)
				local inside, insideWhy = DummySpawn.spawnMany(p, "MINI", machine, "Point", 1, 4, 0)
				assert(inside == 0 and insideWhy == "no free floor there", "a body went into a machine: " .. tostring(insideWhy))
				character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, 0)))
				task.wait(0.3)
			end
			-- 25 is cut to the cap, and the lab's one body budget holds (visitors make room).
			task.wait(DummySpawn.MANY_GAP + 0.05)
			local cap = DummySpawn.capFor(p)
			local VisitorService = require(Systems:WaitForChild("VisitorService")) :: any
			local labCap = VisitorService.capFor(p)
			local big = DummySpawn.spawnMany(p, "HEAVY", aim, "Grid", 25, 4, 0)
			task.wait(DummySpawn.STAGGER + 0.4)
			local inLab = #VisitorService.bodiesOf(p)
			assert(big <= cap and #DummySpawn.of(p) <= cap, string.format("%d came, %d stand (cap %d)", big, #DummySpawn.of(p), cap))
			assert(inLab <= labCap, string.format("%d bodies in the lab after a 25-grid (the lab's budget %d)", inLab, labCap))
			assert(p:GetAttribute("GodCap") == cap, "the client's cap (GodCap) is not the server's")
			-- A minute's budget: once used up, refused.
			local perMinute = DummySpawn.PER_MINUTE
			DummySpawn.PER_MINUTE = 0
			task.wait(DummySpawn.MANY_GAP + 0.05)
			local over, overWhy = DummySpawn.spawnMany(p, "MINI", aim, "Point", 1, 4, 0)
			DummySpawn.PER_MINUTE = perMinute
			assert(over == 0 and overWhy == "slow down", "the minute's budget did not hold")
			-- CLEAR MINE.
			DummySpawn.clear(p)
			assert(#DummySpawn.of(p) == 0, "CLEAR MINE left bodies")
			table.insert(results, string.format("a 10-line where aimed, all in the lab; paced; outside, bad numbers and a machine's footprint refused; 25 cut to %d (cap %d), %d in the lab (budget %d); a minute's budget; CLEAR", big, cap, inLab, labCap))
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
		return "patterns right; given past the first minute after a wow (or at BETA_LATEST) and calm, once, remembered, no trial; SHOP says FREE; " .. table.concat(results, "; ")
	end,
}
