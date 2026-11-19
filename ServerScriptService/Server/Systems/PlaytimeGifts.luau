--!strict
-- (Fix round 1: a DataStore that does not answer is tried again after 30 s, 60 s, ... not every
-- second; a claim made while the player left goes back; today's minutes are kept every minute and
-- when the server closes; the clock counts real time and is sent again every 30 s; full egg slots
-- are told once.)
--
-- Free gifts for time played (10 Nov 2026, from the launch numbers: half the players left within
-- 1.6 min, only 16 % reached 5 min). A weapon egg after 2, 5, 10 and 15 minutes of play each day,
-- with the clock to the next one on screen (the WEAPONS tile's tag, client GiftClock), the way the
-- top Roblox games keep a first visit going past five minutes.
--
-- Per player per day (UTC), not per visit: today's time and the gifts already given are kept in
-- their own DataStore, so leaving and coming back carries on the same clock (nothing to farm by
-- rejoining). A gift is written (UpdateAsync) before its egg is given; when the eggs are full the
-- clock waits at READY until one is opened. The client sees two attributes on the player:
-- GiftAt (server time the next gift is due; nil when today's are done) and GiftLeft (how many
-- are left today). In Studio self-tests and without DataStore access it all lives in memory.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Log = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Log"))
local ProgressService = require(script.Parent.ProgressService)
local EconomyService = require(script.Parent.EconomyService)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local log = Log.new("Gifts")

local PlaytimeGifts = {}

PlaytimeGifts.AT = { 120, 300, 600, 900 } -- s of play today for each gift (one weapon egg each)
-- Phase 2 (Config.EGG_RATION): the gifts are BOLTS, not eggs (tests may turn it off).
PlaytimeGifts.RATION = Config.EGG_RATION and Config.ECONOMY
PlaytimeGifts.TEXT = "FREE GIFT for playing! A weapon egg is yours."
PlaytimeGifts.FULL_TEXT = "Your gift is ready! Open an egg in RANK & EGGS to make room for it."
PlaytimeGifts.RETRY = 30 -- s after a DataStore failure (doubling each time, at most 10 min)
PlaytimeGifts.SAVE_EVERY = 60 -- s: today's minutes kept while playing (and on leaving and closing)
local STORE = "PlaytimeGifts_v1"
local TICK = 1
local RESHOW = 30 -- s: the clock on the player put right again (a slow server's seconds run long)

type Day = { day: number, secs: number, got: number }

local store: DataStore? = nil
local memory: { [number]: Day } = {}
local days: { [Player]: Day } = {}
local busy: { [Player]: boolean } = {}
local retryAt: { [Player]: number } = {} -- (os.clock: after a DataStore failure, not before)
local failures: { [Player]: number } = {}
local toldFull: { [Player]: boolean } = {}
local savedAt: { [Player]: number } = {}

local function today(): number
	return math.floor(os.time() / 86400)
end

local function fresh(d: any): Day
	local now = today()
	if type(d) ~= "table" or d.day ~= now then
		return { day = now, secs = 0, got = 0 }
	end
	return {
		day = now,
		secs = if type(d.secs) == "number" and d.secs == d.secs then math.clamp(d.secs, 0, 86400) else 0,
		got = if type(d.got) == "number" then math.clamp(math.floor(d.got), 0, #PlaytimeGifts.AT) else 0,
	}
end

local function read(userId: number): Day?
	local ds = if ProgressService.isTesting() then nil else store -- (tests: memory only)
	if not ds then
		return fresh(memory[userId])
	end
	local ok, value = pcall(function()
		return ds:GetAsync(tostring(userId))
	end)
	if not ok then
		log.warn("read failed for", userId, tostring(value))
		return nil
	end
	return fresh(value)
end

type Outcome = "took" | "taken" | "failed"

-- Writes today's time; with claim, takes gift number `claim` too. "took": written (and the claim
-- is ours), "taken": another server gave that gift already, "failed": the DataStore did not answer.
local function write(userId: number, d: Day, claim: number?): Outcome
	local ds = if ProgressService.isTesting() then nil else store -- (tests: memory only)
	if not ds then
		local m = fresh(memory[userId])
		if claim and m.got >= claim then
			return "taken"
		end
		memory[userId] = { day = d.day, secs = math.max(m.secs, d.secs), got = if claim then claim else m.got }
		return "took"
	end
	local took = true
	local ok, err = pcall(function()
		ds:UpdateAsync(tostring(userId), function(old: any)
			local o = fresh(old)
			local out = { day = d.day, secs = math.max(o.secs, d.secs), got = o.got }
			if claim then
				if o.got >= claim then
					took = false
					out.got = o.got
				else
					took = true
					out.got = claim
				end
			end
			return out
		end)
	end)
	if not ok then
		log.warn("write failed for", userId, tostring(err))
		return "failed"
	end
	return if took then "took" else "taken"
end

-- Gives a claimed gift back (its egg could not go in, or the player left meanwhile).
local function unclaim(userId: number, d: Day, n: number)
	local back = { day = d.day, secs = d.secs, got = n - 1 }
	local ds = if ProgressService.isTesting() then nil else store
	if not ds then
		memory[userId] = back
		return
	end
	pcall(function()
		ds:UpdateAsync(tostring(userId), function(old: any)
			local o = fresh(old)
			return { day = o.day, secs = math.max(o.secs, back.secs), got = math.min(o.got, back.got) }
		end)
	end)
end

local function show(player: Player)
	local d = days[player]
	if not d then
		return
	end
	local left = #PlaytimeGifts.AT - d.got
	player:SetAttribute("GiftLeft", left)
	if left <= 0 then
		player:SetAttribute("GiftAt", nil)
		return
	end
	local due = PlaytimeGifts.AT[d.got + 1]
	player:SetAttribute("GiftAt", workspace:GetServerTimeNow() + math.max(0, due - d.secs))
end

local function tryGive(player: Player)
	local d = days[player]
	if not d or busy[player] or d.got >= #PlaytimeGifts.AT then
		return
	end
	if d.secs < PlaytimeGifts.AT[d.got + 1] or os.clock() < (retryAt[player] or 0) then
		return
	end
	-- (Phase 2, Config.EGG_RATION: the gift is BOLTS, so a full egg rack does not hold it.)
	local room = if PlaytimeGifts.RATION then nil else ProgressService.eggRoom(player)
	if room ~= nil then
		-- Full or loading: the clock waits at GIFT!, given once there is room; full is told once.
		if room == "full" and not toldFull[player] then
			toldFull[player] = true
			ProgressService.notice(player, PlaytimeGifts.FULL_TEXT)
		end
		return
	end
	busy[player] = true
	local n = d.got + 1
	local outcome = write(player.UserId, d, n)
	if outcome == "took" then
		failures[player] = nil
		local given = if PlaytimeGifts.RATION
			then EconomyService.give(player, Config.PLAYTIME_BOLTS, string.format("FREE GIFT for playing! +%d BOLTS", Config.PLAYTIME_BOLTS))
			else ProgressService.giveEgg(player, PlaytimeGifts.TEXT)
		if player.Parent and days[player] == d and given then
			d.got = n
			toldFull[player] = nil
		else
			-- (Gone meanwhile, or the egg could not go in: the claim goes back for next time.)
			unclaim(player.UserId, d, n)
		end
	elseif outcome == "taken" then
		-- (Given already, by another server this player was in: the stored count wins.)
		local again = read(player.UserId)
		if again then
			d.got = math.max(d.got, again.got)
		end
	else
		-- The DataStore did not answer: try again later, waiting longer each time (30 s, 60 s, ...).
		local k = (failures[player] or 0) + 1
		failures[player] = k
		retryAt[player] = os.clock() + math.min(PlaytimeGifts.RETRY * 2 ^ (k - 1), 600)
	end
	busy[player] = nil
	show(player)
end

local function join(player: Player)
	if ProgressService.isTesting() then
		return
	end
	local d = read(player.UserId)
	if not d or not player.Parent then
		return -- (no gifts this visit rather than gifts given twice)
	end
	days[player] = d
	show(player)
end

function PlaytimeGifts.start()
	if ProgressService.usesDataStores() then
		local ok, ds = pcall(function()
			return DataStoreService:GetDataStore(STORE)
		end)
		store = if ok then ds else nil
	end
	ProgressService.onLoaded(function(player: Player, _first: boolean)
		task.spawn(join, player)
	end)
	for _, player in Players:GetPlayers() do
		if ProgressService.isLoaded(player) then
			task.spawn(join, player)
		end
	end
	-- Today's minutes kept: on leaving (once more if the DataStore did not answer).
	local function keep(userId: number, d: Day)
		if d.day ~= today() then
			return
		end
		if write(userId, d, nil) == "failed" then
			task.wait(5)
			write(userId, d, nil)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		local d = days[player]
		days[player] = nil
		busy[player] = nil
		retryAt[player] = nil
		failures[player] = nil
		toldFull[player] = nil
		savedAt[player] = nil
		if d then
			task.spawn(keep, player.UserId, d)
		end
	end)
	-- ... and when the server closes (a shutdown or an update), for everyone still here.
	game:BindToClose(function()
		local waiting = 0
		for player, d in days do
			waiting += 1
			task.spawn(function()
				keep(player.UserId, d)
				waiting -= 1
			end)
		end
		local started = os.clock()
		while waiting > 0 and os.clock() - started < 20 do
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		local sinceShow = 0
		while true do
			-- (The real time passed, not the asked-for second: a slow server's clock does not drift.)
			local dt = math.min(task.wait(TICK), 5)
			sinceShow += dt
			local reshow = sinceShow >= RESHOW
			if reshow then
				sinceShow = 0
			end
			local now = today()
			for player, d in days do
				if d.day ~= now then
					-- A new day while playing: a fresh set of gifts.
					days[player] = { day = now, secs = 0, got = 0 }
					show(player)
				elseif d.got < #PlaytimeGifts.AT then
					d.secs += dt
					if d.secs >= PlaytimeGifts.AT[d.got + 1] then
						task.spawn(tryGive, player)
					elseif reshow then
						show(player)
					end
					-- Today's minutes kept every minute too (a crash loses at most one), one write each.
					if os.clock() - (savedAt[player] or os.clock()) >= PlaytimeGifts.SAVE_EVERY and not busy[player] then
						savedAt[player] = os.clock()
						task.spawn(write, player.UserId, d, nil)
					end
					if savedAt[player] == nil then
						savedAt[player] = os.clock()
					end
				end
			end
		end
	end)
	log.info("ready")
end

-- Tests: a player's day as the server holds it, and a way to move its clock on.
function PlaytimeGifts.dayOf(player: Player): Day?
	return days[player]
end

function PlaytimeGifts.joinForTest(player: Player)
	memory[player.UserId] = nil
	days[player] = { day = today(), secs = 0, got = 0 }
	show(player)
end

function PlaytimeGifts.addForTest(player: Player, secs: number)
	local d = days[player]
	if d then
		d.secs += secs
		tryGive(player)
	end
end

function PlaytimeGifts.leaveForTest(player: Player)
	days[player] = nil
	retryAt[player] = nil
	failures[player] = nil
	toldFull[player] = nil
	savedAt[player] = nil
	player:SetAttribute("GiftAt", nil)
	player:SetAttribute("GiftLeft", nil)
end

return PlaytimeGifts
