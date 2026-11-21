--!strict
-- V9-0z (owner, 21 Nov 2026: "the ragdolls you spawn in GOD MODE should not just stand there", and "they
-- should disappear after they are knocked out once"):
--   * a GOD MODE body walks about after its pattern has been seen (more than 3 studs within 9 s), at its
--     kind's pace (Pace; BOUNCY hops, FLOPPY wobbles: Gait);
--   * STAY PUT keeps it standing (under 0.5 stud);
--   * one KO and it goes: a Sniper round drops it, it is Spent (never gets up), the takedown is counted,
--     and within 5 s it is gone and its slot is free.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function partOf(m: Model, name: string): BasePart
	local p = m:FindFirstChild(name)
	assert(p and p:IsA("BasePart"), "a GOD MODE body has no " .. name)
	return p
end

return {
	name = "T184_GodLife",
	timeout = 70,
	run = function(): string?
		if not (Config.GOD_FREE_BETA and Config.DUMMY_TYPES) then
			return "skipped (GOD_FREE_BETA or DUMMY_TYPES off)"
		end
		local DummySpawn = require(Systems:WaitForChild("DummySpawn")) :: any
		assert(DummySpawn.TYPES.MINI.pace > 1 and DummySpawn.TYPES.HEAVY.pace < 1, "TINY is not quick or HEAVY is not slow")
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil and (require(Systems:WaitForChild("MoneyService")) :: any).passesCheckedForTest(p)
		end, 30)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "the kinds' pace checked (no player for the rest)"
		end
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		local VitalsService = require(Systems:WaitForChild("VitalsService")) :: any
		local HitService = require(Systems:WaitForChild("HitService")) :: any
		local ProgressService = require(Systems:WaitForChild("ProgressService")) :: any
		local character = p.Character :: Model
		local home = character:GetPivot()
		local hadGod = p:GetAttribute("God")
		local results = {}
		local ok, err = pcall(function()
			p:SetAttribute("God", false)
			DummySpawn.resetBetaForTest(p)
			DummySpawn.grantBeta(p)
			local origin = Lab.originFor(p)
			character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, -20)))
			task.wait(0.4)
			DummySpawn.clear(p)
			task.wait(DummySpawn.MANY_GAP + 0.05)
			-- 1. It walks about.
			local n, why = DummySpawn.spawnMany(p, "BOUNCY", origin + Vector3.new(-10, 0, 14), "Point", 1, 4, 0)
			assert(n == 1, "no body came (" .. tostring(why) .. ")")
			task.wait(DummySpawn.STAGGER + 0.8)
			local walker = DummySpawn.of(p)[1] :: Model
			assert(walker and walker:GetAttribute("Gait") == "Hop" and walker:GetAttribute("Pace") == DummySpawn.TYPES.BOUNCY.pace, "a BOUNCY body has no hop or no pace")
			local start = flat(partOf(walker, "LowerTorso").Position)
			local moved = TestLib.waitFor(function()
				local pelvis = walker:FindFirstChild("LowerTorso")
				return pelvis ~= nil and (flat((pelvis :: BasePart).Position) - start).Magnitude > 3
			end, 9)
			assert(moved, "a GOD MODE body still stood where it came down after 9 s")
			table.insert(results, "a BOUNCY body walked off (hop gait, pace " .. DummySpawn.TYPES.BOUNCY.pace .. ")")
			-- 2. STAY PUT.
			task.wait(DummySpawn.MANY_GAP + 0.05)
			local n2 = DummySpawn.spawnMany(p, "HEAVY", origin + Vector3.new(10, 0, 14), "Point", 1, 4, 0, true)
			assert(n2 == 1, "no STAY PUT body came")
			task.wait(DummySpawn.STAGGER + 1.5)
			local post: Model? = nil
			for _, m in DummySpawn.of(p) do
				if m:GetAttribute("StayPut") == true then
					post = m
				end
			end
			assert(post, "the STAY PUT body is not marked")
			-- (V9-P fix round 1: a kind's Mass is what it really weighs, so it is held up by the right force.)
			local real = 0
			for _, d in (post :: Model):GetChildren() do
				if d:IsA("BasePart") and not d.Massless then
					real += d.Mass
				end
			end
			local said = (post :: Model):GetAttribute("Mass") :: number
			assert(math.abs(said - real) < real * 0.03 and real > 20, string.format("a HEAVY body says it weighs %.1f, really %.1f", said, real))
			assert((post :: Model):GetAttribute("RagdollState") == "Standing", "a HEAVY body is not standing: " .. tostring((post :: Model):GetAttribute("RagdollState")))
			table.insert(results, string.format("HEAVY weighs %.0f and stands", real))
			local stood = flat(partOf(post :: Model, "LowerTorso").Position)
			task.wait(DummySpawn.HOLD_SHAPE + DummySpawn.WANDER_EVERY[2])
			local drift = (flat(partOf(post :: Model, "LowerTorso").Position) - stood).Magnitude
			assert(drift < 0.5, string.format("a STAY PUT body moved %.2f studs", drift))
			table.insert(results, string.format("a STAY PUT body stood (%.2f studs in %d s)", drift, DummySpawn.HOLD_SHAPE + DummySpawn.WANDER_EVERY[2]))
			-- 3. One KO and it goes.
			VitalsService.liveForTest(true)
			local before = #DummySpawn.of(p)
			local td0 = ProgressService.takedownsOf(p) or 0
			local target = post :: Model -- (the STAY PUT one: it has not wandered into a hazard)
			local chest = partOf(target, "UpperTorso")
			HitService.applyToy(Toys.byId.Sniper, chest, chest.Position, (chest.Position - (character:GetPivot().Position)).Unit, p)
			assert(TestLib.waitFor(function()
				return target:GetAttribute("Spent") == true
			end, 2), "a Sniper round did not KO the GOD MODE body")
			local downAt = os.clock()
			local stoodUp = false
			local gone = TestLib.waitFor(function()
				local s = target:GetAttribute("RagdollState")
				if target.Parent and (s == "Standing" or s == "GettingUp") then
					stoodUp = true
				end
				return target.Parent == nil
			end, 6)
			VitalsService.liveForTest(false)
			assert(not stoodUp, "a spent GOD MODE body got up again")
			assert(gone, "a KO'd GOD MODE body was still there after 6 s")
			local took = os.clock() - downAt
			assert(took >= DummySpawn.ONE_USE_REST - 0.3, string.format("it went after %.1f s, before its fall could be enjoyed", took))
			assert(not table.find(DummySpawn.of(p), target) and #DummySpawn.of(p) < before, "its slot was not freed")
			TestLib.waitFor(function()
				return (ProgressService.takedownsOf(p) or 0) > td0
			end, 2)
			local counted = (ProgressService.takedownsOf(p) or 0) > td0
			table.insert(results, string.format("one KO: down, never up, gone after %.1f s, slot free%s", took, if counted then ", takedown counted" else " (takedown not counted here: no owner report)"))
		end)
		VitalsService.liveForTest(false)
		DummySpawn.clear(p)
		p:SetAttribute("God", hadGod)
		character:PivotTo(home)
		assert(ok, err)
		return table.concat(results, "; ")
	end,
}
