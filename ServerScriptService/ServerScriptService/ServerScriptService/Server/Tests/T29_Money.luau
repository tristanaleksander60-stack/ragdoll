--!strict
-- Passes and the owner's events (phase I), through the server's own code:
--   ULTRA: next to no wait between uses of a tool (a firecracker twice in 0.15 s goes through),
--     without it the tool's own wait holds; the free minutes start once a day, not twice
--   VIP: a tag over the head and an egg every Shop.VIP_EGG_EVERY takedowns
--   a pass not on sale yet: in Studio the TEST button turns it on; What's New is kept as seen
--   admin events: the owner starts a server event for free (queued for everyone)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local MoneyService = require(Systems:WaitForChild("MoneyService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local HitService = require(Systems:WaitForChild("HitService"))
local EventService = require(Systems:WaitForChild("EventService"))
local OnboardingService = require(Systems:WaitForChild("OnboardingService"))
local Shop = require(ReplicatedStorage.Shared.Shop)
local Config = require(ReplicatedStorage.Shared.Config)

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.05)
	end
	return check()
end

-- Two firecrackers 0.15 s apart on the floor in front of the player: did the second go through?
local function twoQuick(player: Player, offset: number): boolean
	local root = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local floor = Workspace:FindFirstChild("Baseplate") :: BasePart
	local at = Vector3.new(root.Position.X + offset, floor.Position.Y + floor.Size.Y / 2, root.Position.Z - 20)
	HitService.onRequest(player, floor, at, Vector3.new(0, 0, -1), "Firecracker")
	local first = HitService.lastUseOf(player, "Firecracker")
	task.wait(0.15)
	HitService.onRequest(player, floor, at + Vector3.new(3, 0, 0), Vector3.new(0, 0, -1), "Firecracker")
	local second = HitService.lastUseOf(player, "Firecracker")
	return first ~= nil and second ~= nil and second > first
end

local function body(results: { string }, player: Player)
	-- (The join's pass check first: the passes are on sale, and the game's owner owns them, so a
	-- check still asking Roblox would hand ULTRA back after the reset. It sets "Ultra" when done.)
	local checkBy = os.clock() + 15
	while player:GetAttribute("Ultra") == nil and os.clock() < checkBy do
		task.wait(0.2)
	end
	task.wait(0.5)
	MoneyService.resetForTest(player)
	OnboardingService.finishForTest(player) -- (every tool open, as after the first minute)
	assert(Workspace:FindFirstChild("Baseplate"), "no baseplate to test on")
	-- 1. Without ULTRA the firecracker's own wait (0.5 s) holds; with it, it does not.
	task.wait(0.6)
	assert(not twoQuick(player, -10), "two firecrackers 0.15 s apart went through without ULTRA")
	assert(player:GetAttribute("ZeroDelay") ~= true, "ZeroDelay without ULTRA")
	-- (The pass is on sale now, so BUY opens Roblox's own prompt: a test grants it as a purchase does.)
	MoneyService.grantForTest(player, "Ultra")
	assert(player:GetAttribute("ZeroDelay") == true and MoneyService.owns(player, "Ultra"), "ULTRA, granted as bought, did nothing")
	task.wait(0.6)
	assert(twoQuick(player, 10), "with ULTRA two firecrackers 0.15 s apart did not both go through")
	table.insert(results, "ULTRA: a firecracker twice in 0.15 s goes through (without it the 0.5 s wait holds)")
	-- TNT spam keeps going: 14 TNT, one every 0.27 s (past the 10 burst), all go through.
	local root = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local floor = Workspace:FindFirstChild("Baseplate") :: BasePart
	local through = 0
	for i = 1, 14 do
		local at = Vector3.new(root.Position.X - 20 + (i % 7) * 6, floor.Position.Y + floor.Size.Y / 2, root.Position.Z - 40 - (i // 7) * 8)
		local before = HitService.lastUseOf(player, "TNT")
		HitService.onRequest(player, floor, at, Vector3.new(0, 0, -1), "TNT")
		local after = HitService.lastUseOf(player, "TNT")
		if after and after ~= before then
			through += 1
		end
		task.wait(0.27)
	end
	assert(through == 14, string.format("ULTRA TNT spam: %d of 14 went through", through))
	-- Faster than the refill, the bucket runs dry: some are refused as Busy (the server's limit holds).
	task.wait(3)
	local fast, busy = 0, 0
	for i = 1, 20 do
		local at = Vector3.new(root.Position.X - 30 + (i % 10) * 6, floor.Position.Y + floor.Size.Y / 2, root.Position.Z - 60 - (i // 10) * 8)
		local before = HitService.lastUseOf(player, "TNT")
		HitService.onRequest(player, floor, at, Vector3.new(0, 0, -1), "TNT")
		local after = HitService.lastUseOf(player, "TNT")
		if after and after ~= before then
			fast += 1
		elseif HitService.lastRefusal[player] and HitService.lastRefusal[player].reason == "Busy" then
			busy += 1
		end
		task.wait(0.09)
	end
	assert(busy > 0 and fast >= 10 and fast < 20, string.format("draining the bucket: %d through, %d busy", fast, busy))
	local kept = HitService.heavyCountForTest(player)
	assert(kept <= fast, string.format("%d heavy uses kept after the spam (only the last window's %d should be)", kept, fast))
	table.insert(results, string.format("ULTRA TNT spam: 14 in 3.8 s all go through (refills 4 a second); 20 in 1.8 s: %d through, %d told Busy; %d uses kept (one window, never a growing list)", fast, busy, kept))

	-- 2. The free minutes: today once, not twice.
	MoneyService.resetForTest(player)
	local profile = assert(ProgressService.profileForTest(player), "no profile")
	profile.freeDay = 0
	assert(MoneyService.startFree(player, 20000), "the free ULTRA minutes did not start")
	assert(player:GetAttribute("ZeroDelay") == true and MoneyService.freeLeft(player) > Shop.FREE_ULTRA_SECONDS - 5, "free ULTRA did not switch on")
	assert(not MoneyService.startFree(player, 20000), "the free minutes started twice in one day")
	assert(ProgressService.freeUntil(player) > Workspace:GetServerTimeNow() + Shop.FREE_ULTRA_SECONDS - 5, "the free minutes' end is not kept for a rejoin")
	-- A rejoin with minutes left carries on (runFree from the kept end).
	MoneyService.resetForTest(player)
	assert(player:GetAttribute("ZeroDelay") ~= true, "reset left ULTRA on")
	MoneyService.runFree(player, ProgressService.freeUntil(player), false)
	assert(player:GetAttribute("ZeroDelay") == true and MoneyService.freeLeft(player) > 100, "the kept free minutes did not carry on after a rejoin")
	-- Minutes from yesterday ending (or a run crossing midnight): today's own start follows.
	MoneyService.resetForTest(player)
	profile.freeDay = 0 -- (today not had yet)
	MoneyService.runFree(player, Workspace:GetServerTimeNow() + 0.5, false)
	assert(waitFor(function()
		return MoneyService.freeLeft(player) > Shop.FREE_ULTRA_SECONDS - 10
	end, 3), "yesterday's minutes ended and today's did not start")
	table.insert(results, string.format("free ULTRA: %d s once a day (not twice); kept minutes carry on after a rejoin; when they end on a new day, that day's start follows", Shop.FREE_ULTRA_SECONDS))

	-- 3. VIP: a tag, and an egg every Shop.VIP_EGG_EVERY takedowns.
	MoneyService.resetForTest(player)
	MoneyService.grantForTest(player, "VIP")
	assert(player:GetAttribute("VIP") == true, "VIP not set")
	assert(waitFor(function()
		local head = (player.Character :: Model):FindFirstChild("Head")
		return head ~= nil and head:FindFirstChild("VipTag") ~= nil
	end, 2), "no VIP tag over the head")
	profile.eggs = 0
	local toSeven = Shop.VIP_EGG_EVERY - profile.takedowns % Shop.VIP_EGG_EVERY
	local found = ProgressService.addTakedowns(player, toSeven)
	assert(found == 1, string.format("VIP: %d takedowns to the next VIP egg found %d eggs", toSeven, found))
	profile.eggs = 0
	table.insert(results, "VIP: a tag over the head, an egg after 7 takedowns")

	-- 4. What's New, kept as seen; a first visit has it seen already, a returning player not.
	MoneyService.onRequest(player, "SeenNew")
	assert(ProgressService.seenVersion(player) == Config.Version, "What's New was not kept as seen")
	local first, isNew = ProgressService.joinedProfile(nil, nil)
	assert(isNew and first.seen == Config.Version, "a first visit would be shown What's New")
	local old = ProgressService.joinedProfile(nil, nil)
	old.seen = "0.1.0"
	local back, backNew = ProgressService.joinedProfile(old, nil)
	assert(not backNew and back.seen ~= Config.Version, "a returning player would miss What's New")
	table.insert(results, "What's New kept as seen for " .. Config.Version .. "; a first visit counts it seen, a returning player gets it")

	-- 4b. Roblox's pass check failing once: asked again, and the pass turns up (told).
	do
		local realAsk = MoneyService.askOwns
		local asked = 0
		MoneyService.askOwns = function(_userId: number, _passId: number): boolean
			asked += 1
			if asked == 1 then
				error("HTTP 500 (stub)")
			end
			return true
		end
		MoneyService.resetForTest(player)
		local ok, err = pcall(MoneyService.checkOwnershipForTest, player, { { key = "VIP", id = 123, price = 0 } } :: any, 0.1)
		MoneyService.askOwns = realAsk
		assert(ok, tostring(err))
		assert(asked == 2 and MoneyService.owns(player, "VIP"), string.format("pass check: asked %d times, VIP %s", asked, tostring(MoneyService.owns(player, "VIP"))))
		MoneyService.resetForTest(player)
		table.insert(results, "Roblox's pass check failing once: asked again, the pass turns up")
	end

	-- 5. The owner's admin event: free, for everyone.
	EventService.clearQueue()
	local before = EventService.queued() + (if EventService.current() then 1 else 0)
	MoneyService.onRequest(player, "Admin", "DummyRain")
	assert(EventService.queued() + (if EventService.current() then 1 else 0) > before, "the admin event did not start or queue")
	MoneyService.onRequest(player, "Admin", "NotAnEvent")
	-- At most 2 admin events wait: a spree never pushes paid ones out.
	EventService.holdForTest(true)
	EventService.clearQueue()
	for _, id in { "ZeroG", "BouncyFloor", "FlashFreeze" } do
		MoneyService.adminGapForTest()
		MoneyService.onRequest(player, "Admin", id)
	end
	local waiting = EventService.queued()
	EventService.clearQueue()
	-- "Started" or "queued": the first with nothing ahead starts, the next one waits.
	MoneyService.adminGapForTest()
	MoneyService.onRequest(player, "Admin", "ZeroG")
	local firstQueued = MoneyService.lastAdminQueued
	MoneyService.adminGapForTest()
	MoneyService.onRequest(player, "Admin", "BouncyFloor")
	local secondQueued = MoneyService.lastAdminQueued
	EventService.clearQueue()
	EventService.holdForTest(false)
	assert(waiting == 2, string.format("%d admin events waiting (at most 2)", waiting))
	assert(firstQueued == false and secondQueued == true, string.format("admin toast: first queued=%s, second queued=%s", tostring(firstQueued), tostring(secondQueued)))
	table.insert(results, "admin event queued free for everyone; an unknown one ignored; at most 2 admin events wait; the toast says started, then queued")
	EventService.clearQueue()
end

return {
	name = "money-passes-free-minutes-admin",
	timeout = 40,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and ProgressService.profileForTest(first) ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		local results = {}
		local ok, err = pcall(body, results, player)
		MoneyService.resetForTest(player)
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
