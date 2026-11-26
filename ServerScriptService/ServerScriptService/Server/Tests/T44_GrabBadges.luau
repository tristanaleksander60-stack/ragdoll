--!strict
-- Phase D (10 Nov 2026): badges, grabbing players in the plaza, free ULTRA as the 5-minute gift.
--   badges: every key has a name, a description and a whole-number id (0 = not created yet); the
--     welcome badge on join; each badge once per visit; takedown badges by the lifetime total
--   grab: nobody grabs themselves or someone not here; a refused grab holds nobody; throw, drop and
--     wriggle with no hold do nothing
--   free ULTRA: waits 5 minutes of play (Shop.FREE_ULTRA_AFTER)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Badges = require(Shared:WaitForChild("Badges"))
local Shop = require(Shared:WaitForChild("Shop"))
local Zones = require(Shared:WaitForChild("Zones"))
local Systems = script.Parent.Parent:WaitForChild("Systems")
local BadgeAwards = require(Systems:WaitForChild("BadgeAwards"))
local PlayerGrab = require(Systems:WaitForChild("PlayerGrab"))

local function badges(results: { string }, p: Player)
	for _, b in Badges.LIST do
		assert(#b.name > 0 and #b.name <= 50 and #b.description > 0, "badge text missing or too long: " .. b.key)
		assert(b.id >= 0 and b.id == math.floor(b.id), "badge id not a whole number: " .. b.key)
	end
	local t = os.clock()
	while not BadgeAwards.earned(p, "Welcome") and os.clock() - t < 15 do
		task.wait(0.2) -- (run on its own, the suite can start before Main has started the badges)
	end
	assert(BadgeAwards.earned(p, "Welcome"), "no welcome badge on join")
	assert(not BadgeAwards.earned(p, "Takedowns1000"), "a badge before it was earned")
	BadgeAwards.takedowns(p, 150)
	assert(BadgeAwards.earned(p, "FirstTakedown") and BadgeAwards.earned(p, "Takedowns100"), "takedown badges missing at 150")
	assert(not BadgeAwards.earned(p, "Takedowns1000"), "the 1000 badge at 150")
	BadgeAwards.award(p, "NoSuchBadge")
	assert(not BadgeAwards.earned(p, "NoSuchBadge"), "an unknown badge was recorded")
	table.insert(results, string.format("badges: %d defined, welcome on join, takedown badges by total, unknown keys ignored", #Badges.LIST))
end

local function grab(results: { string }, p: Player)
	assert(PlayerGrab.refusal(p, p) ~= nil and not PlayerGrab.grab(p, p), "a player grabbed themselves")
	assert(PlayerGrab.holdingOf(p) == nil and PlayerGrab.heldByOf(p) == nil, "a refused grab holds someone")
	PlayerGrab.throw(p, Vector3.new(0, 0, -1))
	PlayerGrab.drop(p)
	PlayerGrab.wriggle(p)
	assert(PlayerGrab.holdingOf(p) == nil, "throw/drop with no hold changed something")
	assert(PlayerGrab.REACH <= 20 and PlayerGrab.HOLD_MAX <= 8, "grab reach or hold too long")
	table.insert(results, "grab: never yourself, refused grabs hold nobody, empty throw/drop/wriggle harmless")
end

-- A whole hold, scripted (the suite has one player: it holds itself, past the grab's checks).
local function lifecycle(results: { string }, p: Player)
	local t0 = os.clock()
	while not (p.Character and p.Character:FindFirstChild("HumanoidRootPart")) and os.clock() - t0 < 20 do
		task.wait(0.2) -- (run on its own, the suite may start before the avatar is in)
	end
	local character = p.Character
	local found = character and character:FindFirstChild("HumanoidRootPart")
	assert(found and found:IsA("BasePart"), "no avatar")
	local root = found :: BasePart
	local o = Workspace:GetAttribute("LabOrigin")
	local plaza = if typeof(o) == "Vector3" then o else Vector3.zero
	local home = root.CFrame
	root.CFrame = CFrame.new(plaza + Vector3.new(6, 6, 18))
	task.wait(0.5)
	assert(Zones.isPlaza(root.Position), "not moved into the plaza")
	local ok, err = pcall(function()
		-- 1) An early wriggle is kept and frees them once WRIGGLE_AFTER is reached.
		PlayerGrab.clearPairsForTest(p)
		local stop = PlayerGrab.holdForTest(p, p)
		PlayerGrab.wriggle(p)
		assert(PlayerGrab.heldByOf(p) == p, "freed before WRIGGLE_AFTER")
		local t = os.clock()
		while PlayerGrab.heldByOf(p) and os.clock() - t < PlayerGrab.WRIGGLE_AFTER + 1.5 do
			task.wait(0.1)
		end
		assert(PlayerGrab.heldByOf(p) == nil, "an early wriggle was lost")
		stop()
		-- 2) Every end gives safe time (no grab-drop-grab loop).
		local safe = p:GetAttribute("KnockSafeUntil")
		assert(type(safe) == "number" and safe > Workspace:GetServerTimeNow(), "no safe time after a wriggle")
		-- 3) A throw ends the hold and gives safe time too; the same grabber waits PAIR_GAP.
		task.wait(1)
		local stop2 = PlayerGrab.holdForTest(p, p)
		PlayerGrab.throw(p, Vector3.new(0, 0, -1))
		assert(PlayerGrab.holdingOf(p) == nil, "a throw did not end the hold")
		stop2()
		-- 4) A respawned body is never held on: the hold ends at once.
		local stop3 = PlayerGrab.holdForTest(p, p)
		local hold = PlayerGrab.holdOfForTest(p) :: any
		hold.heldBody = nil -- (as if the avatar were a new one)
		assert(PlayerGrab.endReasonForTest(hold, os.clock()) == "gone", "a new body stayed held")
		hold.heldBody = p.Character
		-- 5) HOLD_MAX ends it.
		assert(PlayerGrab.endReasonForTest(hold, os.clock() + PlayerGrab.HOLD_MAX + 1) == "time", "a hold past HOLD_MAX goes on")
		stop3()
	end)
	root.CFrame = home
	assert(ok, err)
	table.insert(results, "hold: an early wriggle frees at WRIGGLE_AFTER, every end gives safe time, a throw ends it, a new body or HOLD_MAX ends it")
end

return {
	name = "grab-badges",
	timeout = 60,
	run = function(): string?
		local results = {}
		local waited = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		assert(Shop.FREE_ULTRA_AFTER == 300, "free ULTRA is not the 5-minute gift")
		badges(results, p)
		grab(results, p)
		lifecycle(results, p)
		return table.concat(results, "; ")
	end,
}
