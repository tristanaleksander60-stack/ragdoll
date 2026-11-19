--!strict
-- Streamer Mode (phase M), through the server's own code:
--   off: gift actions are refused; on (Studio counts as the streamer's own server): they queue
--   unknown actions and more than QUEUE_MAX waiting are refused
--   a drop brings bodies in, marked NoCredit; knocking one down is never a takedown (gifts give no
--     lasting value); they leave by themselves
--   the keys a gift tool presses are their own group in Keybinds, clashing with nothing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local StreamerService = require(Systems:WaitForChild("StreamerService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local Blasts = require(Systems:WaitForChild("Blasts"))
local Dummies = require(ReplicatedStorage.Shared.Dummies)
local Keybinds = require(ReplicatedStorage.Shared.Keybinds)

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

local function body(results: { string }, player: Player)
	-- 1. Off: nothing queues.
	StreamerService.setOn(player, false)
	assert(StreamerService.queue(player, "Drop") == nil, "a gift queued with Streamer Mode off")
	-- 2. On.
	assert(StreamerService.setOn(player, true), "Streamer Mode did not switch on in Studio")
	assert(player:GetAttribute("Streamer") == true, "the Streamer attribute is not set")
	assert(StreamerService.queue(player, "Teleport") == nil, "an unknown action queued")
	for i = 1, StreamerService.QUEUE_MAX do
		assert(StreamerService.queue(player, "Party") == i, "the queue did not take gift " .. i)
	end
	assert(StreamerService.queue(player, "Party") == nil, "more than QUEUE_MAX gifts queued")
	table.clear(StreamerService.queueOf(player))
	table.insert(results, string.format("off refuses; on queues; unknown and over %d refused", StreamerService.QUEUE_MAX))

	-- 3. A drop: bodies that never count.
	local folder = Workspace:FindFirstChild("Dummies")
	local function guests(): { Model }
		local list = {}
		for _, m in if folder then folder:GetChildren() else {} do
			if m:IsA("Model") and m:GetAttribute("NoCredit") == true then
				table.insert(list, m)
			end
		end
		return list
	end
	local before = #guests()
	StreamerService.queue(player, "Drop")
	StreamerService.runNextForTest(player)
	assert(waitFor(function()
		return #guests() >= before + 3
	end, 4), "the drop brought no bodies (NoCredit)")
	local profile = assert(ProgressService.profileForTest(player), "no profile")
	local takedowns = profile.takedowns
	local guest = guests()[1]
	Dummies.setBlame(guest, player.UserId)
	DummyControl.stampServerHit(guest, player.UserId)
	ProgressService.onDownForTest(guest, "Ragdoll")
	assert(profile.takedowns == takedowns, "a stream's body counted as a takedown")
	for _, m in guests() do
		m:Destroy()
	end
	table.insert(results, "a drop brings 3 bodies marked NoCredit; knocking one down is no takedown")

	-- 4. A gift's boom has nobody behind it: a dummy the streamer just hit, then blown over by a
	-- gift, is no takedown.
	do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local at = if root then root.Position + root.CFrame.LookVector * 30 else Vector3.new(0, 5, 40)
		local model = DummyFactory.spawn(at, nil, nil, 2)
		task.wait(0.3)
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart?
		Dummies.setBlame(model, player.UserId)
		DummyControl.stampServerHit(model, player.UserId)
		local before = profile.takedowns
		Blasts.explode(if pelvis then pelvis.Position else at, nil, nil)
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") ~= "Standing"
		end, 3), "the gift's boom did not knock the dummy over")
		task.wait(0.5)
		assert(profile.takedowns == before, "a gift's boom gave the streamer a takedown")
		model:Destroy()
		table.insert(results, "a gift's boom on a dummy the streamer just hit: no takedown")
	end

	-- 5. Only where the streamer may: a public server (stubbed) refuses the switch.
	StreamerService.setOn(player, false)
	StreamerService.setMayStreamForTest(function()
		return false
	end)
	local refused = not StreamerService.setOn(player, true)
	StreamerService.setMayStreamForTest(nil)
	assert(refused and player:GetAttribute("Streamer") ~= true, "Streamer Mode switched on where it may not")
	table.insert(results, "not the streamer's own private server: the switch is refused")

	-- 6. The gift pairings kept with the profile: a fixed list, nothing else.
	local good = ProgressService.cleanGifts({ 1, 2, 3, 8, 4, 7, 9, 5 })
	assert(good and good[4] == 8 and #good == 8, "a good set of pairings was not kept")
	for _, bad in { { 1, 2, 3 }, { 1, 2, 3, 4, 5, 6, 7, 11 }, { 1, 2, 3, 4, 5, 6, 7, 0 }, { 1, 2, 3, 4, 5, 6, 7, 1.5 }, { 1, 2, 3, 4, 5, 6, 7, "Rose" }, "Rose" } do
		assert(ProgressService.cleanGifts(bad) == nil, "junk gift pairings were kept")
	end
	table.insert(results, "gift pairings: only 8 picks from the list of 10 are kept")

	-- 7. A gift while the streamer has no body (respawning) waits in the queue for the next turn.
	StreamerService.setOn(player, true)
	table.clear(StreamerService.queueOf(player))
	local realRoot = StreamerService.rootOf
	StreamerService.rootOf = function(_p: Player): BasePart?
		return nil
	end
	StreamerService.queue(player, "Party")
	StreamerService.runNextForTest(player)
	local waited = #StreamerService.queueOf(player)
	StreamerService.rootOf = realRoot
	assert(waited == 1, string.format("a gift with no body to act on: %d waiting (want 1)", waited))
	StreamerService.runNextForTest(player)
	assert(#StreamerService.queueOf(player) == 0 and StreamerService.lastResultOf(player) == "Ran", "the waiting gift did not run once the body was back")
	StreamerService.setOn(player, false)
	table.insert(results, "a gift while the streamer respawns waits, then runs")

	-- 8. The pairings round trip: sent, kept with the profile, answered again on Prefs.
	local keptGifts = profile.gifts
	ProgressService.onRequest(player, "Gifts", { 2, 1, 3, 8, 4, 7, 9, 5 })
	assert(profile.gifts and profile.gifts[1] == 2 and profile.gifts[2] == 1, "the gift pairings were not kept")
	ProgressService.onRequest(player, "Gifts", { 2, 1, 3, 8, 4, 7, 9, 99 })
	assert(profile.gifts[8] == 5, "junk pairings replaced the kept ones")
	ProgressService.onRequest(player, "Prefs")
	profile.gifts = keptGifts
	table.insert(results, "gift pairings kept with the profile, junk refused, Prefs answered")

	-- 9. Its keys.
	local clashes = Keybinds.clashList()
	assert(#clashes == 0, "keys that clash: " .. table.concat(clashes, ", "))
	assert(Keybinds.byId.GiftDrop and Keybinds.byId.GiftDrop.group == "STREAMER", "no STREAMER keys")
	StreamerService.setOn(player, false)
	table.insert(results, "STREAMER keys F1-F8 in Controls, no key clashes in any context")
end

return {
	name = "streamer-mode-gifts-no-lasting-value",
	timeout = 45,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and ProgressService.profileForTest(first) ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		local results = {}
		local ok, err = pcall(body, results, player)
		StreamerService.setOn(player, false)
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
