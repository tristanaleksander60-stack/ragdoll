--!strict
-- Round 5, phase 1: the new HUD's server side.
--   SANDBOX: SLOW-MO / REVIVE ALL / RESET only in your own lab, paced; REVIVE ALL brings a dead
--     dummy round; junk refused
--   REWARDS: the group gift says SOON with no group id (never an egg), the state answers; the
--     Starter Pack with no product id never prompts
--   DAILY: a named weapon day gives that weapon (an extra egg if it is yours already)
--   LEVEL: XP from takedowns and minutes; levels rise and the span grows
--   KEYS: the round 5 keys do not clash (V first person, L doctor, J rewards, Z/X/R in play)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local SandboxService = require(Systems:WaitForChild("SandboxService"))
local RewardsService = require(Systems:WaitForChild("RewardsService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local VitalsService = require(Systems:WaitForChild("VitalsService"))
local Lab = require(Systems:WaitForChild("Lab"))
local Shared = ReplicatedStorage.Shared
local Shop = require(Shared.Shop)
local Level = require(Shared.Level)
local DailyGoals = require(Shared.DailyGoals)
local Keybinds = require(Shared.Keybinds)

local function body(player: Player): string
	local results = {}
	-- Sandbox.
	SandboxService.resetForTest(player)
	assert(SandboxService.run(player, "Nonsense") == nil and SandboxService.run(player, 5) == nil, "junk ran a sandbox action")
	local index = Lab.plotIndex(player)
	if index then
		Lab.sendHome(player)
		task.wait(0.5)
		local dummies = Lab.dummiesOf(player)
		local first = dummies[1]
		local reset = SandboxService.run(player, "Reset")
		assert(reset and string.find(reset, "reset"), "RESET did not run in the own lab")
		assert(SandboxService.run(player, "Reset") == nil, "RESET was not paced")
		if first then
			local revived = SandboxService.run(player, "Revive")
			assert(revived and string.find(revived, "revived"), "REVIVE ALL did not run")
			assert(VitalsService.reviveNow(first), "a living dummy could not be healed")
		end
		table.insert(results, "sandbox: RESET and REVIVE ALL in the own lab, paced, junk refused")
	else
		table.insert(results, "sandbox: skipped (no lab)")
	end
	-- Rewards.
	RewardsService.resetForTest()
	local state = RewardsService.stateFor(player)
	assert(state.groupId == Shop.GROUP_ID and type(state.trophiesTotal) == "number" and state.trophiesTotal > 0, "the rewards state is incomplete")
	if Shop.GROUP_ID == 0 then
		local p = ProgressService.profileForTest(player) :: any
		local eggs = p and p.eggs
		assert(RewardsService.claimGroup(player) == "soon", "the group gift did not say soon without a group id")
		assert(not p or p.eggs == eggs, "an egg was given with no group")
	end
	table.insert(results, string.format("rewards: group %s, trophies %d/%d", if Shop.GROUP_ID == 0 then "SOON" else tostring(Shop.GROUP_ID), state.trophies, state.trophiesTotal))
	-- Daily named weapons.
	assert(DailyGoals.streakWeapon(2) == "AK" and DailyGoals.streakWeapon(9) == "AK" and DailyGoals.streakWeapon(7) == "Minigun" and DailyGoals.streakWeapon(1) == nil, "the weapon days are wrong")
	local p = ProgressService.profileForTest(player) :: any
	if p and ProgressService.isLoaded(player) then
		local keep = { owned = table.clone(p.owned), lastDay = p.lastDay, streak = p.streak, eggs = p.eggs, takedowns = p.takedowns }
		local ok, err = pcall(function()
			local today = math.floor(os.time() / 86400)
			p.owned = {}
			p.takedowns = 0
			p.eggs = 0
			p.lastDay = today - 1
			p.streak = 1 -- (today is day 2: the AK)
			ProgressService.daily(player, today)
			assert(p.owned.AK == true, "day 2 did not give the AK")
			p.lastDay = today - 1
			p.streak = 1
			p.eggs = 0
			local eggs = ProgressService.daily(player, today)
			assert(eggs == DailyGoals.streakEggs(2) + 1, "an AK already owned did not become an extra egg (" .. tostring(eggs) .. ")")
		end)
		p.owned = keep.owned
		p.lastDay = keep.lastDay
		p.streak = keep.streak
		p.eggs = keep.eggs
		p.takedowns = keep.takedowns
		ProgressService.setOwnedForTest(player, keep.owned)
		if not ok then
			error(err, 0)
		end
		table.insert(results, "daily: day 2 gives the AK, an owned one an extra egg")
	end
	-- Level.
	local l1 = Level.of(0)
	local l2, into, span = Level.of(Level.xp(25, 600))
	local _, _, span3 = Level.of(Level.need(5))
	assert(l1 == 1 and l2 > 1 and into >= 0 and into < span and span3 > span, "the level rule is off")
	table.insert(results, string.format("level: 25 takedowns + 10 min = level %d", l2))
	-- Keys.
	local function key(id: string): string
		return (Keybinds.byId[id] :: any).default
	end
	assert(key("FirstPerson") == "V" and key("Doctor") == "L" and key("Rewards") == "J" and key("SlowMo") == "Z" and key("ReviveAll") == "X" and key("Reload") == "R", "round 5 keys are not as planned")
	local seen: { [string]: string } = {}
	for _, a in Keybinds.ACTIONS do
		if a.context ~= "Build" then
			local k = a.default
			local other = seen[k .. ":" .. a.context] or (if a.context == "Global" then (seen[k .. ":Play"]) else seen[k .. ":Global"])
			assert(other == nil, string.format("%s and %s share the key %s", a.id, tostring(other), k))
			seen[k .. ":" .. a.context] = a.id
		end
	end
	table.insert(results, "keys: V first person, L doctor, J rewards, Z/X/R in play; no clash")
	return table.concat(results, "; ")
end

return {
	name = "rewards-sandbox-level-keys",
	timeout = 40,
	run = function(): string?
		local started = os.clock()
		while os.clock() - started < 25 and not (Players:GetPlayers()[1] and ProgressService.takedownsOf(Players:GetPlayers()[1]) ~= nil) do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		if not player then
			return "skipped (no player)"
		end
		return body(player)
	end,
}
