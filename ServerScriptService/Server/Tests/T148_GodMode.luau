--!strict
-- 21 Nov 2026 (the owner: "a pass called God: it gives access to creating life, spawning ragdolls";
-- Config.GOD_PASS): GOD MODE is in the shop's passes; in Studio creating life is the pass's. Without
-- it the first creation starts the free TRIAL (GodTrialUntil, the GOD MODE! banner line), and once
-- the trial is over a creation is refused with "god" (the client opens the GOD MODE window). With the
-- pass it always works, twice the cap, and every creation comes down in a beam of light.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Shop = require(Shared:WaitForChild("Shop")) :: any
local BannerRules = require(Shared:WaitForChild("BannerRules")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummySpawn = require(Systems:WaitForChild("DummySpawn")) :: any
local Lab = require(Systems:WaitForChild("Lab")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T148_GodMode",
	timeout = 60,
	run = function(): string?
		local pass = Shop.byKey.God
		assert(pass and string.find(pass.name, "GOD") and #pass.perks == 3, "no GOD MODE pass in Shop.PASSES")
		local banner = BannerRules.of("GOD MODE! 60 seconds to create life")
		assert(banner and banner.title == "GOD MODE!" and banner.icon == "god", "the GOD MODE! line is no banner")
		-- V9-0f: the GOD launcher only for an owner of the pass or during the trial (or everyone while free).
		local GodRules = require(Shared:WaitForChild("GodRules")) :: any
		assert(not GodRules.launcherShown(true, false, nil, 100), "a player without the pass sees the GOD launcher")
		assert(GodRules.launcherShown(true, false, 160, 100), "the GOD launcher is hidden during the trial")
		assert(not GodRules.launcherShown(true, false, 90, 100), "the GOD launcher stayed after the trial")
		assert(GodRules.launcherShown(true, true, nil, 100), "an owner of the pass has no GOD launcher")
		assert(GodRules.launcherShown(false, false, nil, 100), "creating is free but the GOD launcher is hidden")
		assert(GodRules.trialState(nil, 100) == "try" and GodRules.trialState(130, 100) == "running" and GodRules.trialState(90, 100) == "used", "the TRY button's states are wrong")
		if not (Config.GOD_PASS and Config.DUMMY_TYPES) then
			return "pass listed; skipped (GOD_PASS or DUMMY_TYPES off)"
		end
		assert(DummySpawn.godGated(), "creating life is not the pass's in Studio")
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			-- (and Roblox's first word on the passes: its apply() would set God back mid-test)
			return p ~= nil and p.Character ~= nil and Lab.plotIndex(p) ~= nil and (require(Systems:WaitForChild("MoneyService")) :: any).passesCheckedForTest(p)
		end, 30)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "pass listed; skipped (no player with a lab)"
		end
		local character = p.Character :: Model
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart or not rootPart:IsA("BasePart") then
			return "pass listed; skipped (no avatar root)"
		end
		local root = rootPart :: BasePart
		character:PivotTo(CFrame.new(Lab.focusFor(p) + Vector3.new(0, 4, 0)))
		task.wait(0.5)
		local here = root.Position + Vector3.new(6, -2, 0)
		local hadGod = p:GetAttribute("God")
		local ok, err = pcall(function()
			p:SetAttribute("God", false)
			DummySpawn.resetTrialForTest(p)
			DummySpawn.resetBetaForTest(p)
			assert(not DummySpawn.mayCreate(p), "creates life without the pass or a trial")
			-- (V9-0f: the SHOP card's TRY starts the trial once; an owner has nothing to try. V9-0l: while
			-- GOD MODE is free in the beta there is no trial to try: the card claims it instead.)
			if Config.GOD_FREE_BETA then
				assert(not DummySpawn.tryFor(p), "a trial started while GOD MODE is free in the beta")
			else
				assert(DummySpawn.tryFor(p) and type(p:GetAttribute("GodTrialUntil")) == "number", "TRY 60 s did not start the trial")
				assert(not DummySpawn.tryFor(p), "TRY started a second trial")
			end
			DummySpawn.resetTrialForTest(p)
			p:SetAttribute("God", true)
			assert(not DummySpawn.tryFor(p), "an owner of the pass got a trial")
			p:SetAttribute("God", false)
			if Config.GOD_FREE_BETA then
				-- (V9-0l: in the beta the first creation gives GOD MODE for free, no trial.)
				DummySpawn.resetBetaForTest(p)
				task.wait(DummySpawn.GAP + 0.05)
				local m, why = DummySpawn.spawnFor(p, "MINI", here)
				assert(m, "the first creation in the beta was refused: " .. tostring(why))
				assert(p:GetAttribute("GodBeta") == true and p:GetAttribute("GodTrialUntil") == nil, "the first creation in the beta did not give GOD MODE (or started a trial)")
				assert(Workspace:FindFirstChild("CreationBeam"), "no beam of light")
				DummySpawn.resetBetaForTest(p)
			else
				-- The first creation starts the free trial.
				task.wait(DummySpawn.GAP + 0.05)
				local m, why = DummySpawn.spawnFor(p, "MINI", here)
				assert(m, "the trial's first creation was refused: " .. tostring(why))
				local untilAt = p:GetAttribute("GodTrialUntil")
				assert(type(untilAt) == "number" and math.abs(untilAt - (Workspace:GetServerTimeNow() + DummySpawn.TRIAL)) < 3, "no trial clock")
				assert(Workspace:FindFirstChild("CreationBeam"), "no beam of light")
				-- The trial is over: refused with "god", and no second trial.
				p:SetAttribute("GodTrialUntil", Workspace:GetServerTimeNow() - 1)
				task.wait(DummySpawn.GAP + 0.05)
				local none, refused = DummySpawn.spawnFor(p, "HEAVY", here)
				assert(none == nil and refused == "god", "after the trial a creation was not refused with god: " .. tostring(refused))
			end
			-- With the pass: always, twice the cap.
			p:SetAttribute("God", true)
			for _ = 1, 9 do
				task.wait(DummySpawn.GAP + 0.05)
				local g, gwhy = DummySpawn.spawnFor(p, "BOUNCY", here)
				assert(g, "GOD MODE was refused: " .. tostring(gwhy))
			end
			assert(#DummySpawn.of(p) > 6, "GOD MODE did not double the cap: " .. #DummySpawn.of(p))
		end)
		DummySpawn.clear(p)
		DummySpawn.resetTrialForTest(p)
		p:SetAttribute("God", hadGod)
		assert(ok, err)
		return "GOD MODE listed with its banner; launcher only for owners and the trial (V9-0f); no pass = no life; " .. (if Config.GOD_FREE_BETA then "in the beta no trial: the first creation gives GOD MODE free with a beam" else "TRY starts the trial once; the first creation starts the 60 s trial with a beam; after it refused with god") .. "; with the pass always and twice the cap"
	end,
}
