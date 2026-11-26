--!strict
-- Progress and the arena games (phase F), through the server's own code:
--   a stored profile is cleaned (junk dropped) and merged (most takedowns, every hat, best scores)
--   a body knocked down with your name on it is a takedown; the same body again at once, or one
--     nobody hit, is not; takedowns show in the player list and as a rank
--   every Progress.EGG_EVERY takedowns an egg; opening one gives a weapon you do not have (T35 has
--     the details), and with every weapon yours a hat that goes on your head (worn: no collision,
--     no weight); no egg, no opening; only your own hats can be worn; requests are rate-limited
--   egg odds: common often, legendary rarely
--   the profile is saved and the board lists you
--   Red Light, Green Light: only in the arena, one game at a time; catching a sneaker scores, a
--     still runner or anyone on green costs; a runner over the red line costs a life; the best is
--     kept. Shoot 'em: targets keep coming, quick hits build a combo

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local MinigameService = require(Systems:WaitForChild("MinigameService"))
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local HitService = require(Systems:WaitForChild("HitService"))
local Places = require(ReplicatedStorage.Shared.Places)
local Progress = require(ReplicatedStorage.Shared.Progress)
local Dummies = require(ReplicatedStorage.Shared.Dummies)
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

local function body(results: { string }, player: Player)
	-- 1. Cleaning and merging.
	local c = ProgressService.clean({ takedowns = -5, eggs = 1e9, hats = { Crown = true, Fake = true, Duck = "yes" }, hat = "Fake", best = { RLGL = 0 / 0, Shoot = 120 } })
	assert(c.takedowns == 0 and c.eggs == Progress.MAX_EGGS, "bad numbers were not cleaned")
	assert(c.hats.Crown and not c.hats.Fake and not c.hats.Duck and c.hat == nil, "unknown hats were kept")
	assert(c.best.RLGL == nil and c.best.Shoot == 120, "a NaN score was kept")
	local m = ProgressService.merge(
		ProgressService.clean({ takedowns = 50, hats = { Crown = true }, best = { RLGL = 300 } }),
		ProgressService.clean({ takedowns = 40, eggs = 2, hats = { Duck = true }, hat = "Duck", best = { RLGL = 200, Shoot = 90 } })
	)
	assert(m.takedowns == 50 and m.hats.Crown and m.hats.Duck and m.hat == "Duck" and m.best.RLGL == 300 and m.best.Shoot == 90 and m.eggs == 2, "the merge lost something")
	-- Played on a fresh profile while the stored one could not be read: added on top, not lost.
	local late = ProgressService.addOntoForTest(
		ProgressService.clean({ takedowns = 50, eggs = 3, hats = { Crown = true }, hat = "Crown" }),
		ProgressService.clean({ takedowns = 7, eggs = 1 })
	)
	assert(late.takedowns == 57 and late.eggs == 4 and late.hat == "Crown" and late.hats.Crown, "a late read lost what was stored or played")
	table.insert(results, "junk in a stored profile dropped; merge keeps the most takedowns, every hat and the best scores; a late read adds the session on top")

	local profile = assert(ProgressService.profileForTest(player), "the player has no profile")
	-- 2. A takedown, for real: a dummy hit with the player's name on it goes down.
	ProgressService.resetComboForTest(player)
	local before = profile.takedowns
	local spot = (Workspace:GetAttribute("LabOrigin") :: Vector3? or Vector3.zero) + Vector3.new(30, 0, -60)
	local dummy = DummyFactory.spawn(spot, spot + Vector3.zAxis)
	task.wait(0.5)
	local chest = dummy:FindFirstChild("UpperTorso") :: BasePart
	local mass = (dummy:GetAttribute("Mass") :: number?) or 10
	DummyControl.hit(dummy, chest, Vector3.new(0, 60, 0) * mass, chest.Position, nil, player)
	assert(waitFor(function()
		return profile.takedowns == before + 1
	end, 3), "a dummy knocked down by the player was not a takedown")
	ProgressService.onDownForTest(dummy, "Ragdoll")
	assert(profile.takedowns == before + 1, "the same body down again at once counted twice")
	local stray = DummyFactory.spawn(spot + Vector3.new(8, 0, 0), spot + Vector3.new(8, 0, 1))
	task.wait(0.3)
	ProgressService.onDownForTest(stray, "Ragdoll")
	assert(profile.takedowns == before + 1, "a body nobody hit counted")
	dummy:Destroy()
	stray:Destroy()
	local stats = player:FindFirstChild("leaderstats")
	assert(stats and (stats:FindFirstChild("Takedowns") :: IntValue).Value == profile.takedowns, "the player list does not show the takedowns")
	table.insert(results, "a knock-down by the player is a takedown; again at once or by nobody is not; shown in the player list")

	-- 2b. The lab's own dummies (simulated by their owner, so the hit is "Predicted"): a hit tool
	-- through the real remote handler counts; a body the server last saw someone else hit does not.
	local root = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local near = root.Position + root.CFrame.LookVector * 5
	local owned = DummyFactory.spawn(Vector3.new(near.X, spot.Y, near.Z), root.Position, player)
	task.wait(0.5)
	assert(DummyControl.ownerOf(owned) == player, "the test dummy is not the player's")
	local ownedChest = owned:FindFirstChild("UpperTorso") :: BasePart
	ProgressService.resetComboForTest(player)
	local beforeOwned = profile.takedowns
	HitService.onRequest(player, ownedChest, ownedChest.Position, (ownedChest.Position - root.Position).Unit, "Blaster")
	assert(owned:GetAttribute("ServerHitBy") == player.UserId, "a predicted hit on the player's own dummy was not stamped as theirs")
	ProgressService.onDownForTest(owned, "Ragdoll")
	assert(profile.takedowns == beforeOwned + 1, "a Blaster shot at the player's own lab dummy (predicted) did not count")
	local claimed = DummyFactory.spawn(Vector3.new(near.X + 6, spot.Y, near.Z), root.Position, player)
	task.wait(0.3)
	DummyControl.stampServerHit(claimed, player.UserId + 1) -- (someone else's hit)
	Dummies.setBlame(claimed, player.UserId)
	ProgressService.onDownForTest(claimed, "Ragdoll")
	assert(profile.takedowns == beforeOwned + 1, "a body someone else hit counted for the player who claimed it")
	owned:Destroy()
	claimed:Destroy()
	table.insert(results, "own lab dummy: a Blaster shot through the remote (predicted) counts; someone else's hit can't be claimed")

	-- 2c. Combos: every 5th takedown in a run gives a bonus, capped per run.
	ProgressService.resetComboForTest(player)
	local beforeCombo = profile.takedowns
	local bodies = {}
	for i = 1, 25 do
		table.insert(bodies, DummyFactory.spawn(spot + Vector3.new(-12 - (i % 5) * 4, 0, -(i // 5) * 4), spot + Vector3.new(-12, 0, 10)))
	end
	task.wait(0.3)
	local afterFive = 0
	for i, d in bodies do
		Dummies.setBlame(d, player.UserId)
		DummyControl.stampServerHit(d, player.UserId)
		ProgressService.onDownForTest(d, "Ragdoll")
		if i == 5 then
			afterFive = profile.takedowns - beforeCombo
		end
	end
	for _, d in bodies do
		d:Destroy()
	end
	assert(ProgressService.comboForTest(player) == 25, "25 quick takedowns did not make a combo of 25")
	assert(afterFive == 6, string.format("a combo of 5 gave %d (want 5 + 1 bonus)", afterFive))
	local total = profile.takedowns - beforeCombo
	assert(total == 25 + ProgressService.COMBO_BONUS_MAX, string.format("a combo of 25 gave %d (want 25 + the cap of %d)", total, ProgressService.COMBO_BONUS_MAX))
	ProgressService.resetComboForTest(player)
	table.insert(results, string.format("combo of 5: +1 bonus (5 -> 6); a combo of 25: bonuses 1+2+2+1 stop at the cap (%d -> %d)", 25, total))
	-- Crossing a weapon's takedowns tells its name (the Crossbow at its rung); one already owned
	-- (an egg, a purchase) is not told again.
	local saved = profile.takedowns
	local savedOwned = table.clone(profile.owned)
	local crossbow = Toys.byId.Crossbow
	profile.owned.Crossbow = nil
	profile.takedowns = crossbow.unlockAt - 2
	ProgressService.lastUnlock[player] = nil
	ProgressService.addTakedowns(player, 3)
	assert(ProgressService.lastUnlock[player] == "Crossbow", string.format("crossing %d takedowns told: %s", crossbow.unlockAt, tostring(ProgressService.lastUnlock[player])))
	profile.owned.Crossbow = true
	profile.takedowns = crossbow.unlockAt - 2
	ProgressService.lastUnlock[player] = nil
	ProgressService.addTakedowns(player, 3)
	assert(ProgressService.lastUnlock[player] == nil, "an owned weapon was unlocked again: " .. tostring(ProgressService.lastUnlock[player]))
	profile.owned = savedOwned
	profile.takedowns = saved -- (exactly as before: the test leaves no takedowns behind)
	table.insert(results, string.format("crossing %d takedowns: UNLOCKED: Crossbow (not told when owned already)", crossbow.unlockAt))

	-- 2d. The radio's choice kept with the profile: a switch, a track id, a volume step 1-3.
	do
		for _, bad in { { on = true, track = 5, volume = 0 }, { on = true, track = 5, volume = 4 }, { on = true, track = 5, volume = 1.5 }, { on = true, track = 0, volume = 2 }, { on = true, track = 0 / 0, volume = 2 }, { on = true, track = math.huge, volume = 2 }, { on = "yes", track = 5, volume = 2 }, "loud" } do
			assert(not ProgressService.validRadio(bad), "junk radio choice accepted")
		end
		assert(ProgressService.validRadio({ on = false, track = 123456789, volume = 3 }), "a good radio choice refused")
		local keptRadio = profile.radio
		ProgressService.onRequest(player, "Radio", { on = false, track = 987654321, volume = 2 })
		assert(profile.radio and profile.radio.on == false and profile.radio.track == 987654321 and profile.radio.volume == 2, "the radio choice was not kept")
		ProgressService.onRequest(player, "Radio", { on = true, track = 5, volume = 9 })
		assert(profile.radio.volume == 2, "a junk radio choice replaced the kept one")
		ProgressService.onRequest(player, "Prefs") -- (answered without error: Radio, Keys and Gifts)
		profile.radio = keptRadio
		table.insert(results, "radio choice: kept when valid (switch, id, volume 1-3), junk refused; Prefs answered")
	end

	-- 3. Eggs and rank.
	profile.eggs = 0
	local toNext = Progress.EGG_EVERY - profile.takedowns % Progress.EGG_EVERY
	local found = ProgressService.addTakedowns(player, toNext)
	assert(found == 1 and profile.eggs == 1, string.format("%d takedowns to the next egg found %d", toNext, found))
	assert(player:GetAttribute("Rank") == Progress.rankOf(profile.takedowns).name, "the rank shown is wrong")
	-- An egg holds a weapon while there is one to get (T35 has the details)...
	local ownedBefore = table.clone(profile.owned)
	local first = ProgressService.openEgg(player) :: any
	assert(first and first.kind == "Weapon" and profile.owned[first.id] and profile.eggs == 0, "an egg did not hold a weapon")
	-- ...and once they are all yours, a hat.
	for _, toy in Toys.list do
		if toy.unlockAt > 0 then
			profile.owned[toy.id] = true
		end
	end
	profile.eggs = 1
	local prize = ProgressService.openEgg(player) :: any
	assert(prize and prize.kind == "Hat", "with every weapon owned an egg held no hat")
	local hat, isNew = prize.hat, prize.new
	assert(hat and profile.eggs == 0 and profile.hats[hat.id], "opening an egg gave no hat")
	local nothing = ProgressService.openEgg(player)
	assert(nothing == nil, "an egg opened with none left")
	-- The hat on the head (a new one goes straight on).
	if isNew then
		local worn = player.Character and player.Character:FindFirstChild("Hat")
		assert(worn and worn:GetAttribute("Worn") == true and worn:GetAttribute("HatId") == hat.id, "the new hat is not on the avatar")
		for _, d in worn:GetDescendants() do
			if d:IsA("BasePart") then
				assert(not d.CanCollide and not d.CanQuery and d.Massless, "a hat part collides, can be tapped or weighs something")
			end
		end
	end
	assert(not ProgressService.wear(player, "NotAHat"), "an unknown hat was worn")
	local notMine
	for _, h in Progress.HATS do
		if not profile.hats[h.id] then
			notMine = h.id
			break
		end
	end
	if notMine then
		assert(not ProgressService.wear(player, notMine), "a hat the player does not own was worn")
	end
	assert(ProgressService.wear(player, ""), "taking the hat off failed")
	assert(not (player.Character and player.Character:FindFirstChild("Hat")), "the hat stayed on")
	-- A flood of requests: the first dozen in 10 s go through.
	profile.eggs = 20
	for _ = 1, 20 do
		ProgressService.onRequest(player, "Open")
	end
	local opened = 20 - profile.eggs
	assert(opened <= 12 and opened >= 1, string.format("a flood of 20 opened %d eggs in a moment", opened))
	profile.eggs = 0
	ProgressService.setOwnedForTest(player, ownedBefore) -- (the test leaves no weapons behind)
	table.insert(results, string.format("%d takedowns found an egg; it held the %s; with all weapons owned one opened into a %s %s on the head; no egg, no opening; unknown or unowned hats refused; a flood of 20 opened %d", toNext, first.name, hat.rarity, hat.name, opened))

	-- The daily egg: once a day, a streak for days in a row (two eggs every third day).
	profile.eggs = 0
	profile.lastDay = 1000
	profile.streak = 2
	assert(ProgressService.daily(player, 1001) == 2 and profile.streak == 3, "day 3 in a row did not give two eggs")
	assert(ProgressService.daily(player, 1001) == 0, "a second daily egg on the same day")
	assert(ProgressService.daily(player, 1005) == 1 and profile.streak == 1, "a missed day did not restart the streak")
	profile.eggs = 0
	table.insert(results, "daily egg: day 3 in a row gives 2, the same day again nothing, after a gap the streak restarts")

	-- 4. The odds.
	local counts = { Common = 0, Rare = 0, Epic = 0, Legendary = 0 }
	local rng = Random.new(5)
	for _ = 1, 10000 do
		local h = Progress.roll(rng:NextNumber(), rng:NextNumber())
		counts[h.rarity] += 1
	end
	assert(counts.Common > 5500 and counts.Common < 6500 and counts.Legendary > 100 and counts.Legendary < 350, string.format("odds off: %d common, %d legendary in 10000", counts.Common, counts.Legendary))
	table.insert(results, string.format("10000 eggs: %d common, %d rare, %d epic, %d legendary", counts.Common, counts.Rare, counts.Epic, counts.Legendary))

	-- 5. Saved, and on the board.
	assert(ProgressService.saveNowForTest(player), "saving the profile failed")
	local stored = ProgressService.storedForTest(player)
	assert(stored and stored.takedowns == profile.takedowns, "the saved profile does not match")
	local LeaderboardService = require(script.Parent.Parent.Systems.LeaderboardService) :: any
	assert(string.find(LeaderboardService.textForTest("Takedowns"), player.DisplayName, 1, true), "the board does not list the player")
	-- Eggs are saved as a change: an egg found here adds to what is stored, even if the store
	-- changed meanwhile (another server); a session that never read its profile is added on top.
	local storedNow = assert(ProgressService.storedForTest(player), "nothing stored")
	storedNow.eggs = 4 -- (another server found some meanwhile)
	profile.eggs += 1
	assert(ProgressService.saveNowForTest(player), "saving again failed")
	assert((ProgressService.storedForTest(player) :: any).eggs == 5, "a found egg was not added to the stored count: " .. tostring((ProgressService.storedForTest(player) :: any).eggs))
	profile.eggs -= 1
	ProgressService.saveNowForTest(player)
	local before5 = (ProgressService.storedForTest(player) :: any).takedowns
	ProgressService.saveOntoForTest(player, ProgressService.clean({ takedowns = 3, eggs = 0 }))
	assert((ProgressService.storedForTest(player) :: any).takedowns == before5 + 3, "a never-read session was not added on top")
	;(ProgressService.storedForTest(player) :: any).takedowns = before5
	table.insert(results, "profile saved; eggs saved as a change (4 stored + 1 found = 5); a never-read session added on top; the board lists the player")

	-- 6. Red Light, Green Light. (V9-0s: while the Game Arena is hidden its games only refuse.)
	if not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ARENA_ENABLED then
		assert(MinigameService.refusal(player, "RLGL") == "The Game Arena is closed for now", "an arena game could start while the arena is hidden")
		assert(not WorldMaps.travel(player, "Arena"), "a trip to the hidden arena was allowed")
		table.insert(results, "arena hidden (ARENA_ENABLED off): no trip, its games refuse")
		return
	end
	MinigameService.stopForTest()
	assert(MinigameService.refusal(player, "RLGL") ~= nil, "a game started outside the arena")
	task.wait(Places.TRAVEL_GAP + 0.1)
	assert(WorldMaps.travel(player, "Arena"), "the trip to the arena was refused")
	assert(MinigameService.refusal(player, "Chess") ~= nil, "an unknown game was allowed")
	local ok = MinigameService.start(player, "RLGL")
	assert(ok, "Red Light, Green Light did not start")
	assert(MinigameService.refusal(player, "Shoot") ~= nil, "a second game started during the first")
	local s = assert(MinigameService.current(), "no game running")
	assert(#s.runners == MinigameService.RLGL.runners, string.format("%d runners", #s.runners))
	task.wait(1)
	MinigameService.setLightForTest("Red", 30)
	local sneaker, still, other = s.runners[1], s.runners[2], s.runners[3]
	sneaker.sneaking = true
	still.sneaking = false
	for _, r in { sneaker, still, other } do
		Dummies.setBlame(r.model, player.UserId)
	end
	MinigameService.downForTest(sneaker.model)
	assert(s.score == MinigameService.RLGL.caught, "catching a sneaker on red did not score")
	MinigameService.downForTest(still.model)
	assert(s.score == MinigameService.RLGL.caught + MinigameService.RLGL.wrongRed, "knocking a still runner on red did not cost")
	MinigameService.setLightForTest("Green", 30)
	MinigameService.downForTest(other.model)
	MinigameService.setLightForTest("Yellow", 30)
	local fifth = s.runners[5]
	Dummies.setBlame(fifth.model, player.UserId)
	MinigameService.downForTest(fifth.model)
	local expected = MinigameService.RLGL.caught + MinigameService.RLGL.wrongRed + MinigameService.RLGL.wrongGreen * 2
	assert(s.score == expected, "a knock-down on green did not cost")
	-- A cheater over the red line (v4 A1: an honest one is safe, T94).
	local runner = s.runners[4]
	runner.cheated = true
	local centre = Places.floorCenter((Workspace:GetAttribute("LabOrigin") :: Vector3?) or Vector3.zero, "Arena") :: Vector3
	DummyControl.reset(runner.model, CFrame.new(centre + Vector3.new(runner.laneX, 3, -46)))
	task.wait(0.2)
	MinigameService.stepForTest()
	assert(s.lives == MinigameService.RLGL.lives - 1, "a cheater over the red line did not cost a life")
	MinigameService.stopForTest()
	assert(ProgressService.best(player, "RLGL") >= expected, "the best score was not kept")
	table.insert(results, string.format("red light: sneaker caught +%d, still runner %d, on green or yellow %d (score %d, kept as best); a cheater over the line cost a life; one game at a time", MinigameService.RLGL.caught, MinigameService.RLGL.wrongRed, MinigameService.RLGL.wrongGreen, expected))

	-- 7. Shoot 'em.
	ok = MinigameService.start(player, "Shoot")
	assert(ok, "Shoot 'em did not start")
	local t = assert(MinigameService.current(), "no game running")
	assert(#t.runners == MinigameService.SHOOT.alive, string.format("%d targets", #t.runners))
	local a, b = t.runners[1], t.runners[2]
	Dummies.setBlame(a.model, player.UserId)
	Dummies.setBlame(b.model, player.UserId)
	MinigameService.downForTest(a.model)
	MinigameService.downForTest(b.model)
	local p = MinigameService.SHOOT.points
	assert(t.score == p + p * 2, string.format("two quick hits scored %d (combo?)", t.score))
	-- Someone else's knock-down in this round changes nothing (no griefing a round away).
	local c = t.runners[3]
	Dummies.setBlame(c.model, player.UserId + 1)
	MinigameService.downForTest(c.model)
	assert(not c.done and t.score == p + p * 2, "another player's knock-down counted in the host's round")
	assert(waitFor(function()
		return a.model.Parent == nil
	end, 4), "a knocked-down target stayed in the arena")
	MinigameService.stepForTest()
	local alive = 0
	for _, r in t.runners do
		if not r.done and r.model.Parent then
			alive += 1
		end
	end
	assert(alive == MinigameService.SHOOT.alive, "the targets were not topped up")
	MinigameService.stopForTest()
	table.insert(results, string.format("shoot 'em: two quick hits %d (combo x2), targets topped up to %d; someone else's knock-down ignored", t.score, alive))
end

return {
	name = "progress-takedowns-eggs-hats-games",
	timeout = 90,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and ProgressService.profileForTest(first) ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		local results = {}
		local ok, err = pcall(body, results, player)
		MinigameService.stopForTest()
		if player:GetAttribute("Place") ~= "Lab" then
			task.wait(Places.TRAVEL_GAP + 0.1)
			pcall(WorldMaps.travel, player, "Lab")
		end
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
