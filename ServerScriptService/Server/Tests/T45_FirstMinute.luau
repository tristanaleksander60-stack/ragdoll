--!strict
-- Round 5, phase 00: the first minute, through the server code a new player meets:
--   the first shot on your greeter (sent the way a tap or SHOOT sends it) takes takedowns up by one
--   a knock-down whose state report came before the server's own hit still counts (the retry)
--   three rounds in the limbs take a body down (a phone's taps land there)
--   a minute in, a player who never opened an egg gets one to open by itself
--   the visit record counts shots, approved hits, knock-downs and takedowns, and reads the device

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local GreeterService = require(Systems:WaitForChild("GreeterService"))
local OnboardingService = require(Systems:WaitForChild("OnboardingService"))
local HitService = require(Systems:WaitForChild("HitService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local EventService = require(Systems:WaitForChild("EventService"))
local SessionStats = require(Systems:WaitForChild("SessionStats"))
local Dummies = require(ReplicatedStorage.Shared.Dummies)
local ActiveRagdoll = require(ReplicatedStorage.Shared.Ragdoll.ActiveRagdoll)

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

local function body(player: Player, root: BasePart): string
	local results = {}
	local record = SessionStats.recordFor(player)
	assert(record, "no visit record for the player")
	local r = record :: SessionStats.Record

	-- 1. The greeter's first shot: +1 takedown, counted in the visit record.
	GreeterService.resetForTest(player, 2)
	OnboardingService.restartForTest(player, 60)
	OnboardingService.onSpawned(player)
	-- (V8-0.2: the greeter may wait for the move into the lab first, up to 3 s.)
	local t0 = os.clock()
	while GreeterService.of(player) == nil and os.clock() - t0 < 5 do
		task.wait(0.1)
	end
	local greeter = GreeterService.of(player)
	assert(greeter, "no greeter came")
	local g = greeter :: Model
	local chestPart = g:FindFirstChild("UpperTorso")
	local armPart = g:FindFirstChild("LeftUpperArm")
	assert(chestPart and chestPart:IsA("BasePart") and armPart and armPart:IsA("BasePart"), "the greeter has no chest or arm")
	local chest, arm = chestPart :: BasePart, armPart :: BasePart
	local before = ProgressService.takedownsOf(player) or 0
	local shots0, hits0, td0 = r.shots, r.hits, r.takedowns
	HitService.lastRefusal[player] = nil
	-- (An arm: the round only flinches the body, and it still counts.)
	HitService.onRequest(player, arm, arm.Position, (arm.Position - root.Position).Unit, "Blaster")
	assert(HitService.lastRefusal[player] == nil, "the first G17 shot was refused: " .. tostring((HitService.lastRefusal[player] :: any) and (HitService.lastRefusal[player] :: any).reason))
	assert(waitFor(function()
		return (ProgressService.takedownsOf(player) or 0) >= before + 1
	end, 2), string.format("the first shot on the greeter gave no takedown (%d -> %d)", before, ProgressService.takedownsOf(player) or 0))
	local after = ProgressService.takedownsOf(player) or 0
	assert(r.shots > shots0 and r.hits > hits0 and r.takedowns > td0, string.format("the visit record did not count it (shots %d hits %d takedowns %d)", r.shots, r.hits, r.takedowns))
	assert(type(r.firstShot) == "number", "the first shot was not timed")
	-- A second hit on the same greeter is not another free takedown.
	task.wait(0.2)
	HitService.onRequest(player, chest, chest.Position, (chest.Position - root.Position).Unit, "Blaster")
	task.wait(0.5)
	assert((ProgressService.takedownsOf(player) or 0) == after, "the greeter gave a second free takedown")
	table.insert(results, string.format("greeter's first shot (an arm): takedowns %d -> %d, once", before, after))
	GreeterService.resetForTest(player)

	-- 2. The fall reported before the server's own hit: counted when the hit arrives.
	local at = root.Position + root.CFrame.LookVector * 10
	local dummy = DummyFactory.spawn(at, root.Position, nil)
	task.wait(0.3)
	local t0 = ProgressService.takedownsOf(player) or 0
	Dummies.setBlame(dummy, player.UserId)
	dummy:SetAttribute("ServerHitAt", nil)
	dummy:SetAttribute("ServerHitBy", nil)
	ProgressService.onDownForTest(dummy, "Ragdoll")
	task.wait(0.3)
	DummyControl.stampServerHit(dummy, player.UserId)
	assert(waitFor(function()
		return (ProgressService.takedownsOf(player) or 0) > t0
	end, 2), "a fall reported a moment before the hit was not counted")
	-- And a fall nobody's server hit backs never counts, retry or not.
	local t1 = ProgressService.takedownsOf(player) or 0
	local other = DummyFactory.spawn(at + Vector3.new(4, 0, 0), root.Position, nil)
	task.wait(0.2)
	Dummies.setBlame(other, player.UserId)
	ProgressService.onDownForTest(other, "Ragdoll")
	task.wait(ProgressService.DOWN_RETRY + 0.5)
	assert((ProgressService.takedownsOf(player) or 0) == t1, "a fall without a server hit was counted")
	dummy:Destroy()
	other:Destroy()
	table.insert(results, "a fall reported before its hit counts after the retry; one without a server hit never does")

	-- 3. Rounds in the limbs add up.
	local rig: any = {}
	local now = os.clock()
	assert(ActiveRagdoll.gunReaction(rig, "arm", 1, now) == "Flinch", "one arm shot took it down")
	assert(ActiveRagdoll.gunReaction(rig, "leg", 1, now + 0.4, 1) == "Flinch", "an arm and a leg took it down")
	assert(ActiveRagdoll.gunReaction(rig, "arm", 1, now + 0.8, 1) == "Ragdoll", "three rounds in the limbs did not take it down")
	table.insert(results, "three rounds in the limbs fell it")

	-- 4. The first egg opens by itself for a player who never opened one.
	local p = ProgressService.profileForTest(player)
	assert(p, "no profile")
	local profile = p :: any
	local keepOwned, keepHats, keepEggs = table.clone(profile.owned), table.clone(profile.hats), profile.eggs
	ProgressService.setOwnedForTest(player, {})
	profile.hats = {}
	profile.eggs = 0
	local ok, err = pcall(function()
		if ProgressService.isLoaded(player) then
			assert(ProgressService.neverOpened(player), "a player with nothing opened is not seen as new")
			assert(ProgressService.firstEgg(player), "the first egg was not given")
			assert(profile.eggs == 1, "no egg to open (eggs " .. tostring(profile.eggs) .. ")")
			assert(r.autoEgg, "the visit record missed the egg")
			profile.owned = { Grenade = true }
			assert(not ProgressService.neverOpened(player) and not ProgressService.firstEgg(player), "an egg-opener got the first egg again")
		end
	end)
	ProgressService.setOwnedForTest(player, keepOwned)
	profile.hats = keepHats
	profile.eggs = keepEggs
	if not ok then
		error(err, 0)
	end
	table.insert(results, if ProgressService.isLoaded(player) then "first egg given to open by itself, only to someone who never opened one" else "first egg: skipped (profile not loaded)")

	-- 5. The device, as the client says it (junk ignored).
	local plat = r.plat
	if plat == "?" then
		SessionStats.onClient(player, "Hello", { touch = true, keys = false, pad = false, w = 844, h = 390, boot = 3.2 })
		assert(r.plat == "phone" and r.boot == 3.2, "a phone was read as " .. r.plat)
		r.plat = "?"
	end
	SessionStats.onClient(player, 42, { touch = "yes" })
	SessionStats.onClient(player, "Hello", "nonsense")
	table.insert(results, "device read from Hello (" .. (if plat == "?" then "phone check" else "client said " .. plat) .. "); junk ignored")
	return table.concat(results, "; ")
end

return {
	name = "first-minute-takedown-egg-session",
	timeout = 60,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and first.Character:FindFirstChild("HumanoidRootPart") ~= nil and ProgressService.takedownsOf(first) ~= nil
		end, 30)
		local player = Players:GetPlayers()[1]
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not player or not root or not root:IsA("BasePart") then
			return "skipped (no player)"
		end
		EventService.holdForTest(true)
		local ok, result = pcall(body, player, root)
		EventService.holdForTest(false)
		GreeterService.resetForTest(player)
		OnboardingService.finishForTest(player)
		if not ok then
			error(result, 0)
		end
		return result
	end,
}
