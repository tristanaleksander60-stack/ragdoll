--!strict
-- The rules around tools, through the real remote handler (HitService.onRequest):
--   bad input never errors and never does anything; taps on a player's body are refused
--   the first minute allows the starters only (and says so); the big tools share a budget (and
--     say so), and a use the budget refuses is not counted
--   whoever sends a dummy flying is blamed for it (only they can be knocked over by it); a client
--     can blame itself or a moving thing next to the dummy, never someone's wall
--   the server opens the catalog on its own clock after SPAWN; the saved bar takes good bars only
--   a second rocket on a dummy replaces the first; gadgets count towards the prop cap

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local HitService = require(Systems:WaitForChild("HitService"))
local ToyService = require(Systems:WaitForChild("ToyService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local OnboardingService = require(Systems:WaitForChild("OnboardingService"))
local EventService = require(Systems:WaitForChild("EventService"))
local Dummies = require(ReplicatedStorage.Shared.Dummies)
local Toys = require(ReplicatedStorage.Shared.Toys)
local LoadoutStore = require(Systems:WaitForChild("LoadoutStore"))

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

local function propCount(player: Player): number
	return (player:GetAttribute("PropCount") :: number?) or 0
end

local function propsOut(): number
	local folder = Workspace:FindFirstChild("Props")
	return if folder then #folder:GetChildren() else 0
end

local function body(player: Player, root: BasePart): string
	local results = {}
	-- A patch of open ground 60 studs from the player (out of reach of their own blasts).
	local probe = root.Position + Vector3.new(60, 40, 0)
	local hit = Workspace:Raycast(probe, Vector3.new(0, -120, 0))
	assert(hit and hit.Instance:IsA("BasePart"), "no ground next to the player")
	local ground = hit.Instance :: BasePart
	local at = hit.Position
	local dir = Vector3.new(1, -0.3, 0).Unit

	-- 1. Nonsense from a client: no error, nothing happens.
	local before = propsOut()
	local nan = 0 / 0
	local junk: { { any } } = {
		{ "x", at, dir, "TNT" },
		{ ground, "here", dir, "TNT" },
		{ ground, at, dir, 42 },
		{ ground, at, dir, "NoSuchTool" },
		{ ground, Vector3.new(nan, 0, 0), dir, "TNT" },
		{ ground, at, Vector3.zero, "TNT" },
		{ ground, at + Vector3.new(0, 0, 5000), dir, "TNT" }, -- far from the part it names
		{ root, root.Position, dir, "TNT" }, -- a player's body
		{ root, root.Position, dir, "Shove" },
		{ workspace, at, dir, "TNT" },
	}
	for i, args in junk do
		local ok, err = pcall(HitService.onRequest, player, table.unpack(args))
		assert(ok, string.format("bad request %d raised an error: %s", i, tostring(err)))
	end
	task.wait(0.3)
	assert(propsOut() == before, "a bad request put something in the lab")
	table.insert(results, #junk .. " bad requests ignored")

	-- 2. The first minute: only the starters, and the refusal is told.
	HitService.lastRefusal[player] = nil
	local step = OnboardingService.stepOf(player)
	if step and step < 4 then
		HitService.onRequest(player, ground, at, dir, "BigBoom")
		local r = HitService.lastRefusal[player]
		assert(r and r.toy == "BigBoom" and r.reason == "Locked", "a locked tool was not refused with a reason")
		table.insert(results, "locked tool refused")
		OnboardingService.finishForTest(player)
	end

	-- 3. The big tools share a budget: five in three seconds, the sixth is refused (and told), and
	-- once the window has passed it works again.
	task.wait(3.2)
	HitService.lastRefusal[player] = nil
	-- (The game's creator owns ULTRA, whose no-wait lifts this budget: off for this part, as for
	-- everyone without the pass; the join-time pass check is waited for first, as T29 does.)
	local started = os.clock()
	while player:GetAttribute("Ultra") == nil and os.clock() - started < 6 do
		task.wait(0.1)
	end
	local zeroWas = player:GetAttribute("ZeroDelay")
	player:SetAttribute("ZeroDelay", false)
	local heavy = { "TNT", "Cannon", "Shockwave", "BigBoom", "BlackHole" }
	local firstAt = os.clock()
	for _, id in heavy do
		assert(Toys.byId[id].heavy, id .. " is not a heavy tool")
		HitService.onRequest(player, ground, at, dir, id)
		task.wait(0.12)
	end
	assert(HitService.lastRefusal[player] == nil, "a use within the budget was refused")
	task.wait(0.8) -- past TNT's own cooldown
	HitService.onRequest(player, ground, at, dir, "TNT")
	local r = HitService.lastRefusal[player]
	assert(r and r.toy == "TNT" and r.reason == "Busy", "the sixth big tool in three seconds was not refused as Busy")
	for _ = 1, 3 do -- more refused tries: if refusals counted, they would fill the next window
		task.wait(0.05)
		HitService.onRequest(player, ground, at, dir, "TNT")
	end
	-- Refused uses do not eat the budget: once the first five age out (and every cooldown is over),
	-- five more in a row all work.
	assert(waitFor(function()
		return os.clock() - firstAt > 3.75
	end, 5), "clock")
	HitService.lastRefusal[player] = nil
	for _, id in heavy do
		HitService.onRequest(player, ground, at, dir, id)
		task.wait(0.05)
	end
	local after = HitService.lastRefusal[player]
	assert(after == nil, "refused tries ate the budget: " .. (if after then after.toy .. " " .. after.reason else ""))
	table.insert(results, "heavy budget 5 per 3 s, refusal told, refused tries cost nothing")
	player:SetAttribute("ZeroDelay", zeroWas)
	ToyService.cleanUp(player)
	task.wait(4) -- the blasts and the black hole finish

	-- 3b. Out of reach is told; a point that is not on the part it names does nothing.
	HitService.lastRefusal[player] = nil
	local far = Workspace:Raycast(root.Position + Vector3.new(400, 40, 0), Vector3.new(0, -120, 0))
	if far and far.Instance:IsA("BasePart") then
		HitService.onRequest(player, far.Instance, far.Position, dir, "Anvil")
		local rf = HitService.lastRefusal[player]
		assert(rf and rf.reason == "TooFar", "a tap out of reach was not refused as TooFar")
	end
	local before2 = propsOut()
	HitService.onRequest(player, ground, at + Vector3.new(0, 40, 0), dir, "Anvil")
	task.wait(0.2)
	assert(propsOut() == before2, "a point 40 studs above the part it names put something down")
	table.insert(results, "out of reach told, off-part points ignored")

	-- 3c. A refused use costs nothing: Freeze refused on an ice statue works at once on another dummy.
	local iceAt = at + Vector3.new(0, 0, -30)
	local ice = DummyFactory.spawn(iceAt, iceAt + Vector3.zAxis)
	local other = DummyFactory.spawn(iceAt + Vector3.new(8, 0, 0), iceAt + Vector3.new(8, 0, 1))
	task.wait(0.8)
	local iceChest = ice:FindFirstChild("UpperTorso") :: BasePart
	local otherChest = other:FindFirstChild("UpperTorso") :: BasePart
	ToyService.onDummy(nil, "Freeze", iceChest, iceChest.Position)
	assert(ice:GetAttribute("Frozen") == true, "the test dummy did not freeze")
	HitService.lastRefusal[player] = nil
	HitService.onRequest(player, iceChest, iceChest.Position, dir, "Freeze")
	local rz = HitService.lastRefusal[player]
	assert(rz and rz.reason == "Frozen", "Freeze on an ice statue was not refused as Frozen")
	HitService.lastRefusal[player] = nil
	HitService.onRequest(player, otherChest, otherChest.Position, dir, "Freeze")
	assert(HitService.lastRefusal[player] == nil and other:GetAttribute("Frozen") == true, "the refused Freeze used up its cooldown")
	ice:Destroy()
	other:Destroy()
	table.insert(results, "refused uses cost nothing")

	-- 3d. A player's blast never sets off or pushes someone else's bomb.
	local theirs = at + Vector3.new(-20, 0, -20)
	ToyService.place(nil, "TNT", theirs, Vector3.zAxis)
	local folder = Workspace:FindFirstChild("Props") :: Folder
	local crate: Instance? = nil
	for _, prop in folder:GetChildren() do
		if prop.Name == "TNT" and prop:GetAttribute("Owner") == 0 then
			crate = prop
		end
	end
	assert(crate, "the test crate was not placed")
	local c = crate :: BasePart
	c:SetAttribute("Owner", 999999) -- someone else's (nobody on this server)
	c.Anchored = true -- held still, so any push would show as a chain mark only
	ToyService.blast(c.Position + Vector3.new(4, 0, 0), ToyService.BLASTS.TNT, nil, player)
	task.wait(0.4)
	assert(c:GetAttribute("Chain") ~= true, "a player's blast set off someone else's TNT")
	c:Destroy()
	table.insert(results, "others' bombs never chained")

	-- 3e. The saved bar: one to six different catalog tools, nothing else.
	assert(LoadoutStore.validate({ "Grab", "Shove", "Launch", "TNT", "Rocket", "Freeze" }), "a good bar was refused")
	assert(not LoadoutStore.validate({ "Grab", "Grab", "Launch", "TNT", "Rocket", "Freeze" }), "a bar with a tool twice was kept")
	assert(not LoadoutStore.validate({ "Grab", "NotATool", "Launch", "TNT", "Rocket", "Freeze" }), "a bar with an unknown tool was kept")
	assert(LoadoutStore.validate({ "Grab" }), "a bar with one tool (the rest unequipped) was refused")
	assert(not LoadoutStore.validate({}), "an empty bar was kept")
	-- (Release fix: since 0.17 a longer saved bar keeps its first Toys.SLOTS tools: LoadoutStore.validate, T56.)
	local seven = LoadoutStore.validate({ "Grab", "Shove", "Launch", "TNT", "Rocket", "Freeze", "Bat" })
	assert(seven and #seven == Toys.SLOTS and seven[1] == "Grab" and table.find(seven, "Bat") == nil, "a bar of seven was not cut to its first " .. Toys.SLOTS)
	assert(not LoadoutStore.validate("Grab"), "a string was kept as a bar")
	local good = { "Shove", "Grab", "Launch", "TNT", "Rocket", "Freeze" }
	LoadoutStore.onSet(player, "Set", good)
	local kept = LoadoutStore.get(player)
	assert(kept and table.concat(kept, ",") == table.concat(good, ","), "a good bar sent by the client was not kept")
	LoadoutStore.onSet(player, "Set", { "Shove", "Shove", "Launch", "TNT", "Rocket", "Freeze" })
	LoadoutStore.onSet(player, "Load", good)
	kept = LoadoutStore.get(player)
	assert(kept and kept[1] == "Shove" and kept[2] == "Grab", "a bad bar replaced the kept one")
	table.insert(results, "bar validated and kept")

	-- 3f. Blame from the simulating client: itself, yes; a moving thing of someone else's next to
	-- the dummy, yes; someone's anchored wall, or a report from a client that does not simulate it, no.
	local spotB = at + Vector3.new(-30, 0, 30)
	local framed = DummyFactory.spawn(spotB, spotB + Vector3.zAxis)
	task.wait(0.5)
	DummyControl.setOwner(framed, player)
	local pelvisB = framed:FindFirstChild("LowerTorso") :: BasePart
	local wall = Instance.new("Part")
	wall.Size = Vector3.new(4, 4, 1)
	wall.Anchored = true
	wall.CanCollide = false
	wall.Transparency = 1
	wall.CFrame = pelvisB.CFrame + Vector3.new(0, 0, 2.5)
	wall:SetAttribute("Owner", 999999)
	wall.Parent = workspace:FindFirstChild("Props") or workspace
	ToyService.onBlame(player, framed, wall)
	assert(framed:GetAttribute("HitBy") ~= 999999, "an anchored part of someone else's framed them")
	local pad = Instance.new("Part")
	pad.Name = "SpringPad" -- someone else's launch pad (anchored, but it throws what lands on it)
	pad.Size = Vector3.new(4.4, 0.5, 4.4)
	pad.Anchored = true
	pad.CanCollide = false
	pad.Transparency = 1
	pad.CFrame = pelvisB.CFrame - Vector3.new(0, 3, 0)
	pad:SetAttribute("Owner", 888888)
	pad.Parent = workspace:FindFirstChild("Props") or workspace
	ToyService.onBlame(player, framed, pad)
	assert(framed:GetAttribute("HitBy") == 888888, "someone else's launch pad was not blamed for the launch")
	pad:Destroy()
	local rootPart = root
	ToyService.onBlame(player, framed, rootPart)
	assert(framed:GetAttribute("HitBy") == player.UserId, "self-blame from the holder was not taken")
	wall.Anchored = false
	wall.CFrame = pelvisB.CFrame + Vector3.new(0, 0, 2.5)
	wall.AssemblyLinearVelocity = Vector3.new(0, 0, -30)
	ToyService.onBlame(player, framed, wall)
	assert(framed:GetAttribute("HitBy") == 999999, "a moving thing of someone else's next to the dummy was not blamed")
	DummyControl.setOwner(framed, nil)
	ToyService.onBlame(player, framed, rootPart)
	assert(framed:GetAttribute("HitBy") == 999999, "a client that does not simulate the dummy changed its blame")
	wall:Destroy()
	framed:Destroy()
	table.insert(results, "client blame only for self, a launch pad or a moving thing")

	-- 3g. The server opens the catalog on its own clock after you appear (no client message needed).
	OnboardingService.restartForTest(player, 1)
	OnboardingService.onSpawned(player)
	assert(not OnboardingService.isAllowed(player, "BigBoom"), "the catalog was open right after appearing")
	local opened = waitFor(function()
		return OnboardingService.isAllowed(player, "BigBoom")
	end, 3)
	OnboardingService.finishForTest(player)
	assert(opened, "the server did not open the catalog after its fallback time")
	table.insert(results, "catalog opens on the server's clock")

	-- 4. Blame: the player behind a hit, and nobody for an event.
	local spotA = at + Vector3.new(0, 0, 30)
	local model = DummyFactory.spawn(spotA, spotA + Vector3.zAxis)
	assert(waitFor(function()
		return model:GetAttribute("RagdollState") == "Standing"
	end, 3), "a fresh dummy did not stand")
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	DummyControl.hit(model, chest, Vector3.new(0, 20, 0) * 10, chest.Position, nil, player)
	assert(Dummies.sentBy(model, player.UserId), "a player's hit was not blamed on them")
	task.wait(0.6)
	DummyControl.hit(model, chest, Vector3.new(0, 20, 0) * 10, chest.Position, nil, nil)
	assert(not Dummies.sentBy(model, player.UserId), "an event's hit was still blamed on the player")
	HitService.applyToy(Toys.byId.Shove, chest, chest.Position, Vector3.xAxis, player)
	assert(Dummies.sentBy(model, player.UserId), "a tool hit through HitService was not blamed")
	table.insert(results, "blame follows the hitter")

	-- 5. One rocket per dummy; gadgets count against the cap.
	task.wait(2.5)
	ToyService.onDummy(player, "Rocket", chest, chest.Position)
	ToyService.onDummy(player, "Rocket", chest, chest.Position)
	local rockets = 0
	for _, d in model:GetDescendants() do
		if d.Name == "Rocket" and d:GetAttribute("Gadget") == true then
			rockets += 1
		end
	end
	assert(rockets == 1, string.format("%d rockets on one dummy", rockets))
	ToyService.cleanUp(player)
	assert(waitFor(function()
		return propCount(player) == 0
	end, 2), "clean up left props counted")
	-- (ULTRA's no-wait doubles the cap: Props; the creator owns ULTRA.)
	local max = ((player:GetAttribute("PropMax") :: number?) or 10) * (if player:GetAttribute("ZeroDelay") == true then 2 else 1)
	for i = 1, max + 2 do
		ToyService.place(player, "Banana", at + Vector3.new(i * 3, 0, -20), Vector3.zAxis)
	end
	assert(propCount(player) == max, string.format("%d props out (cap %d)", propCount(player), max))
	local fresh = DummyFactory.spawn(spotA + Vector3.new(15, 0, 0), spotA + Vector3.new(15, 0, 1))
	task.wait(0.5)
	local freshChest = fresh:FindFirstChild("UpperTorso") :: BasePart
	ToyService.onDummy(player, "Balloon", freshChest, freshChest.Position)
	assert(propCount(player) == max, string.format("a gadget pushed the count to %d (cap %d)", propCount(player), max))
	table.insert(results, "one rocket per dummy, gadgets capped")

	ToyService.cleanUp(player)
	model:Destroy()
	fresh:Destroy()
	return table.concat(results, "; ")
end

return {
	name = "tool-rules-remote-budget-blame",
	timeout = 120,
	run = function(): string?
		-- Run on its own (SelfTestOnly), the suite may start before the player's avatar is in.
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
		if not ok then
			error(result, 0)
		end
		return result
	end,
}
