--!strict
-- The first five seconds (phase B), through the server code a new player meets:
--   appearing sends a greeter: a dummy a few steps in front of you, simulated by your client, that
--     walks up and stops in front of you; only the starters work, the Blaster among them
--   the first tool that works is timed (FirstToolSeconds, sent to analytics); the greeter goes in a
--     puff a while after it was hit
--   the Blaster shows in the avatar's hand while it is picked, and only real held tools do
--   the intro and the chosen view are kept for the next visit; a nonsense view is ignored

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local OnboardingService = require(Systems:WaitForChild("OnboardingService"))
local GreeterService = require(Systems:WaitForChild("GreeterService"))
local HeldService = require(Systems:WaitForChild("HeldService"))
local HitService = require(Systems:WaitForChild("HitService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local EventService = require(Systems:WaitForChild("EventService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

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

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- What stood around when the greeter failed (a failure message that says why, not just that).
local function scene(player: Player, root: BasePart, g: Model): string
	local character = player.Character
	local fired = character and character:GetAttribute("GunFiredAt")
	local held = character and character:FindFirstChild("HeldTool")
	local bits = {
		string.format("gun fired %s s ago", if type(fired) == "number" then string.format("%.1f", workspace:GetServerTimeNow() - fired) else "never"),
		"holding " .. tostring(held and held:GetAttribute("ToyId")),
	}
	for k, v in g:GetAttributes() do
		if typeof(v) ~= "Instance" then
			table.insert(bits, k .. "=" .. tostring(v))
		end
	end
	local pelvis = g:FindFirstChild("LowerTorso") :: BasePart
	local from, to = flat(pelvis.Position), flat(root.Position)
	for _, m in workspace:GetDescendants() do
		if m:IsA("Model") and m ~= g and m ~= character and m:FindFirstChild("LowerTorso") then
			local at = flat((m :: any).LowerTorso.Position)
			local along = (to - from)
			local t = math.clamp((at - from):Dot(along) / math.max(along:Dot(along), 1e-3), 0, 1)
			local gap = (at - (from + along * t)).Magnitude
			if gap < 4 then
				table.insert(bits, string.format("%s in the way (%.1f studs off the line)", m.Name, gap))
			end
		end
	end
	return table.concat(bits, "; ")
end

local function body(player: Player, root: BasePart): string
	local results = {}

	-- 1. Appearing: a greeter in front, simulated by you, walking up.
	GreeterService.resetForTest(player, 2)
	OnboardingService.restartForTest(player, 60)
	local look = flat(root.CFrame.LookVector).Unit
	OnboardingService.onSpawned(player)
	-- (V8-0.2: the greeter may wait for the move into the lab first, up to 3 s.)
	local t0 = os.clock()
	while GreeterService.of(player) == nil and os.clock() - t0 < 5 do
		task.wait(0.1)
	end
	local greeter = GreeterService.of(player)
	assert(greeter, "no greeter came")
	local g = greeter :: Model
	assert(g:GetAttribute("Greeter") == player.UserId, "the greeter is not marked as this player's")
	assert(DummyControl.ownerOf(g) == player, "the greeter is not simulated by the player's client")
	local shirt = g:FindFirstChild("UpperTorso") :: BasePart
	assert(shirt.Color.R > 0.9 and shirt.Color.B < 0.3, "the greeter does not stand out (no orange shirt)")
	local pelvis = g:FindFirstChild("LowerTorso") :: BasePart
	local offset = flat(pelvis.Position - root.Position)
	assert(offset.Magnitude >= 10 and offset.Magnitude <= 24, string.format("the greeter appeared %.1f studs away", offset.Magnitude))
	assert(offset.Unit:Dot(look) > 0.6, "the greeter did not appear in front of the player (it may come in from the side)")
	local startDistance = offset.Magnitude
	local started = os.clock()
	local arrived = waitFor(function()
		return flat(pelvis.Position - root.Position).Magnitude <= 11
	end, 9)
	local walkTime = os.clock() - started
	assert(arrived, string.format("the greeter did not walk up (still %.1f studs away; %s)", flat(pelvis.Position - root.Position).Magnitude, scene(player, root, g)))
	-- (Where it stops, not where it is as it crosses 11 studs: it comes in from up to 40 degrees
	-- off and curves to its stop in front, so mid-walk it is still off to the side.)
	waitFor(function()
		return flat(pelvis.AssemblyLinearVelocity).Magnitude < 0.6
	end, 4)
	local stopAt = flat(pelvis.Position - root.Position)
	assert(stopAt.Unit:Dot(look) > 0.8, string.format("the greeter did not stop in front of the player (%.0f deg off; %s)", math.deg(math.acos(math.clamp(stopAt.Unit:Dot(look), -1, 1))), scene(player, root, g)))
	table.insert(results, string.format("greeter appeared %.0f studs away (%.0f deg off ahead), walked up in %.1fs",
		startDistance, math.deg(math.acos(math.clamp(offset.Unit:Dot(look), -1, 1))), walkTime))

	-- 2. The first minute: the starters (Blaster first), nothing else.
	assert(Toys.defaultLoadout[1] == "Blaster" and Toys.default == "Blaster", "the Blaster is not the first tool")
	assert(OnboardingService.isAllowed(player, "Blaster"), "the Blaster is not allowed at the start")
	assert(not OnboardingService.isAllowed(player, "BigBoom"), "the whole catalog was open at the start")

	-- 3. The first shot: timed, and the greeter flies (the hit sent the way a tap's would reach it).
	local chest = g:FindFirstChild("UpperTorso") :: BasePart
	local dir = (chest.Position - root.Position).Unit
	HitService.lastRefusal[player] = nil
	HitService.onRequest(player, chest, chest.Position, dir, "Blaster")
	assert(HitService.lastRefusal[player] == nil, "the first Blaster shot was refused")
	local seconds = player:GetAttribute("FirstToolSeconds")
	assert(type(seconds) == "number" and seconds < 15, "the first shot was not timed: " .. tostring(seconds))
	HitService.applyToy(Toys.byId.Blaster, chest, chest.Position, dir)
	assert(waitFor(function()
		local s = g:GetAttribute("RagdollState")
		return s == "Ragdoll" or s == "Out" or s == "Stumble"
	end, 2), "the Blaster did not knock the greeter: " .. tostring(g:GetAttribute("RagdollState")))
	table.insert(results, string.format("first shot timed at %.1fs, greeter knocked %s", seconds, tostring(g:GetAttribute("RagdollState"))))
	assert(waitFor(function()
		return g.Parent == nil
	end, 6), "the greeter did not go away after being hit")
	assert(GreeterService.of(player) == nil, "the greeter is still listed")
	OnboardingService.onSpawned(player) -- a second appearance this visit: no second greeter
	assert(GreeterService.of(player) == nil, "a second greeter came in the same visit")
	table.insert(results, "greeter goes after its stay, once per visit")

	-- 4. Held tools: the Blaster in the hand; a tool that is not held, or nonsense, shows nothing.
	local before = HeldService.holdingOf(player)
	HeldService.onHold(player, "Blaster")
	local character = player.Character :: Model
	local held = character:FindFirstChild("HeldTool")
	assert(held and held:GetAttribute("Tool") == "Blaster", "the Blaster is not in the avatar's hand")
	local hand = character:FindFirstChild("RightHand") :: BasePart
	local grip = (held :: Model).PrimaryPart :: BasePart
	assert((grip.Position - hand.Position).Magnitude < 2, "the Blaster is not at the hand")
	for _, d in (held :: Model):GetDescendants() do
		if d:IsA("BasePart") then
			assert(not d.CanCollide and not d.CanQuery and d.Massless, "a piece of the Blaster can collide, be tapped or weighs something")
		end
	end
	HeldService.onHold(player, 42)
	HeldService.onHold(player, "NoSuchTool")
	assert(character:FindFirstChild("HeldTool"), "nonsense changed what the avatar holds")
	HeldService.onHold(player, "Grab")
	assert(character:FindFirstChild("HeldTool") == nil, "picking Grab left the Blaster in the hand")
	-- Too many picks in a second: the last one still wins a moment later.
	for i = 1, 15 do -- the last one (15th) is the Blaster
		HeldService.onHold(player, if i % 2 == 0 then "Grab" else "Blaster")
	end
	assert(waitFor(function()
		local h = character:FindFirstChild("HeldTool")
		return h ~= nil and h:GetAttribute("Tool") == "Blaster"
	end, 2), "after a burst of picks the hand did not end on the last one")
	HeldService.onHold(player, before or "Grab")
	table.insert(results, "Blaster held in the hand, only for held tools")

	-- 5. Kept for next time: the intro done, the view chosen; nonsense ignored.
	OnboardingService.finishForTest(player)
	local record = OnboardingService.recordForTest(player)
	assert(record and record.done, "the finished intro was not kept")
	OnboardingService.onClient(player, "Mode", "Lab")
	OnboardingService.onClient(player, "Mode", "Hack")
	-- View changes are saved once they settle (one write, not one per switch).
	assert(waitFor(function()
		local r = OnboardingService.recordForTest(player)
		return r ~= nil and r.mode == "Lab"
	end, 9), "the chosen view was not kept (or nonsense replaced it)")
	-- A flood of view messages: the replicated attribute changes at most once per 2 s (30 a minute),
	-- and it still ends on the last view, as does the kept record.
	task.wait(2.1)
	local changes = 0
	local watch = player:GetAttributeChangedSignal("PreferredView"):Connect(function()
		changes += 1
	end)
	for i = 1, 101 do
		OnboardingService.onClient(player, "Mode", if i % 2 == 0 then "Player" else "Lab")
	end
	task.wait(0.2)
	local duringFlood = changes
	assert(duringFlood <= 1, string.format("a flood of view messages changed the attribute %d times at once", duringFlood))
	assert(waitFor(function()
		return player:GetAttribute("PreferredView") == "Lab"
	end, 4), "after a flood the replicated view did not catch up with the last one (Lab)")
	watch:Disconnect()
	assert(waitFor(function()
		local r = OnboardingService.recordForTest(player)
		return r ~= nil and r.mode == "Lab"
	end, 9), "after a flood the last view (Lab) was not the one kept")
	OnboardingService.onClient(player, "Mode", "Player")
	table.insert(results, string.format("intro and view kept for next visit; a flood of 101 view messages changed the attribute %d time(s) at once, then caught up with the last view, which is kept", duringFlood))

	GreeterService.resetForTest(player)
	return table.concat(results, "; ")
end

return {
	name = "first-seconds-greeter-blaster-choice",
	timeout = 90,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and first.Character:FindFirstChild("HumanoidRootPart") ~= nil
		end, 20)
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
