--!strict
-- Progress (phase F): takedowns, ranks, eggs and hats, and the profile that keeps them.
--
-- A takedown: a dummy or a person goes down (knocked flat or out cold) and the server's blame on
-- that body names you, recently (Dummies.blame). The same body counts once per few seconds. Every
-- Progress.EGG_EVERY takedowns you find an egg; opening one (asked by the client, rolled here) gives
-- a weapon you do not have yet (round 2, N4: one of the next few up the ladder, now and then any),
-- or, once every weapon is yours, a hat, worn on your avatar for everyone to see. A weapon is yours
-- when your kills reach it, when an egg gives it, or when you buy it (WeaponShop). Your rank and takedowns show in the player list
-- (leaderstats) and on the boards in the lab (the server's top players, and everyone's best
-- across all servers when the DataStore is reachable).
--
-- The profile (takedowns, eggs, hats, the hat you wear, minigame bests) is kept in a DataStore
-- with UpdateAsync (merged, never blindly overwritten), retried, saved a few seconds after a
-- change, when you leave and when the server closes. In Studio without API access and during
-- self-tests it lives in memory. Nothing a client sends is trusted beyond "open an egg" and "wear
-- this hat" (one you own), both rate-limited.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local Dummies = require(Shared:WaitForChild("Dummies"))
local Progress = require(Shared:WaitForChild("Progress"))
local DailyGoals = require(Shared:WaitForChild("DailyGoals"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Toys = require(Shared:WaitForChild("Toys"))
local Config = require(Shared:WaitForChild("Config"))

local DummyControl = require(script.Parent.DummyControl)
local Metrics = require(script.Parent.Metrics)
local BadgeAwards = require(script.Parent.BadgeAwards)
local SessionStats = require(script.Parent.SessionStats)
local ExperimentService = require(script.Parent.ExperimentService)
local Economy = require(Shared:WaitForChild("Economy"))
local Offers = require(Shared:WaitForChild("Offers"))

local log = Log.new("Progress")

local ProgressService = {}

-- The friend boost (FriendsService): while it says yes for a player, every second takedown counts
-- one extra.
ProgressService.boost = nil :: ((Player) -> boolean)?
local boostHalf: { [Player]: number } = {}

-- Combos (phase H): takedowns within COMBO_GAP of each other build a combo. Every COMBO_STEP-th
-- takedown in one combo gives a bonus (+1, from twice COMBO_STEP on +2), at most COMBO_BONUS_MAX
-- per combo: a reward for a run, not a multiplier that a crowd could keep up forever.
ProgressService.COMBO_GAP = 3 -- s
ProgressService.COMBO_STEP = 5
ProgressService.COMBO_BONUS_MAX = 6
local combos: { [Player]: { count: number, at: number, bonus: number } } = {}
local pranksChanged: { [Player]: boolean } = {} -- the switch was flipped this session
local loadedHooks: { (Player, boolean) -> () } = {}

local STORE = "Profile_v1"
local SAVE_DELAY = 6 -- s after the last change
local SAVE_MAX_WAIT = 60 -- s: in non-stop play it saves at least this often (a crash loses less)
local RETRIES = 3
local READ_RETRY_GAP = 15
local REQUESTS_PER_10S = 12 -- open / wear

export type Profile = {
	takedowns: number,
	eggs: number,
	hats: { [string]: boolean },
	hat: string?,
	best: { [string]: number },
	lastDay: number, -- the UTC day of the last daily egg
	streak: number, -- days in a row
	freezeWeek: number?, -- (V8-3.4) the UTC week (day // 7) a streak freeze was last used
	noPranks: boolean, -- switched "Friends can prank me" off (FriendsService)
	freeDay: number, -- the UTC day of the last free ULTRA minutes (MoneyService)
	seen: string, -- the last version whose What's New was shown
	radio: { on: boolean, track: number, volume: number }?, -- the radio's kept choice (phase J; track = asset id)
	keys: { [string]: string }?, -- the keys a player changed (phase L, Keybinds.sanitize)
	gifts: { number }?, -- Streamer Mode: which gift goes with each STREAMER key (phase M; list indexes)
	freeUntil: number, -- server time the free ULTRA minutes run to (MoneyService; survives a rejoin)
	owned: { [string]: boolean }, -- weapons from eggs and purchases (and, once, the old ladder's: LADDER)
	pending: { [string]: string }, -- a weapon chosen to buy, per price tier key (WeaponShop's receipt)
	ladder: number, -- the weapon ladder this profile knows (an older one keeps what it had: grandfather)
	bought: { string }, -- the last weapon purchase ids delivered (a repeated receipt gives nothing twice)
	oldEggs: number, -- eggs found before the weapon ladder: they still hold a hat, as they did then
	playSeconds: number, -- time played in all (round 3, M6: the MOST TIME PLAYED boards)
	settings: { sfx: number, blood: boolean, shake: boolean, motion: number, ui: number, deadMon: boolean }?, -- SETTINGS (M6, M11)
	goals: Goals?, -- the day's three goals (round 3, M9: DailyGoals)
	eco: Economy.Eco?, -- phase 2: bolts, journal, today's daily experiments, codes (Shared\Economy)
}
export type Goals = { day: number, p: { number }, claimed: { boolean }, bonus: boolean }

-- The weapon ladder (round 2, N4) moved most tools from "open from the start" up to kills. A profile
-- from before keeps every tool it had then, once: the old ladder's open tools, and its kill unlocks
-- that its takedowns had reached (OLD_UNLOCK; everything else was open).
local LADDER = 4
local ROUND5_STARTERS = { "Bat", "Crowbar", "Shove" } -- (on everyone's bar before round 5)
-- Ladder 4 (V8-0.3, Config.V8_START_BAR): Poke, Shove, Slap and Heal moved up the ladder. What a
-- player had already earned on their old rungs stays theirs (blind review, 21 Nov).
local V8_MOVED: { [string]: number } = { Poke = 3, Shove = 6, Slap = 7, Heal = 8 }
local OLD_UNLOCK: { [string]: number } = { Crossbow = 10, NailGun = 20, Slime = 30, Shrink = 50, Chicken = 75, Float = 100, Slowmo = 125, Portal = 150 }
-- Every field this version writes (anything else stored is kept as it is: keepUnknown).
local KNOWN_FIELDS: { [string]: boolean } = {}
for _, key in { "takedowns", "eggs", "hats", "hat", "best", "lastDay", "noPranks", "freeDay", "seen", "radio", "keys", "gifts", "freeUntil", "streak", "owned", "pending", "ladder", "bought", "oldEggs", "playSeconds", "settings", "goals", "eco", "freezeWeek" } do
	KNOWN_FIELDS[key] = true
end
local BOUGHT_KEPT = 30
-- The old catalog (0.12.0): its 41 tools, by id (the new ones came after).
local OLD_TOOLS: { [string]: boolean } = {}
for _, id in {
	"Blaster", "Grab", "Poke", "Slap", "Shove", "Punch", "Kick", "Uppercut", "Pan", "Glove", "Bat",
	"Golf", "Hammer", "Launch", "MegaSlap", "Firecracker", "TNT", "Shockwave", "StickyBomb", "Cannon",
	"BigBoom", "Rocket", "Balloon", "Freeze", "Zap", "BlackHole", "Heal", "Anvil", "Trampoline",
	"SpringPad", "Banana", "Fan", "Bowling", "Crossbow", "NailGun", "Slime", "Shrink", "Chicken",
	"Float", "Slowmo", "Portal",
} do
	OLD_TOOLS[id] = true
end

local store: DataStore? = nil
local memory: { [number]: Profile } = {}
local profiles: { [Player]: Profile } = {}
local loaded: { [Player]: boolean } = {}
local readFailed: { [Player]: boolean } = {}
local dirty: { [Player]: number } = {}
local window: { [Player]: { start: number, count: number } } = {}
local lastDown: { [Model]: number } = {}
-- Round 4, M10: when a body was last credited (server time): once it is dead, one takedown at most
-- for the kill and whatever is done to the body after (a knock-down while alive never blocks the kill).
local creditedAt: { [Model]: number } = {}
local remote: RemoteEvent
local rng = Random.new()
local saving = 0

local function fresh(): Profile
	return { takedowns = 0, eggs = 0, hats = {}, hat = nil, best = {}, lastDay = 0, streak = 0, noPranks = false, freeDay = 0, seen = "", freeUntil = 0, owned = {}, pending = {}, ladder = LADDER, bought = {}, oldEggs = 0, playSeconds = 0 }
end

-- The radio's kept choice: a switch, a track (an asset id; a small number from before is an index)
-- and a volume step.
function ProgressService.validRadio(r: any): boolean
	return type(r) == "table" and (r.on == nil or type(r.on) == "boolean")
		and type(r.track) == "number" and r.track >= 1 and r.track <= 1e16 and r.track % 1 == 0
		and type(r.volume) == "number" and r.volume >= 1 and r.volume <= 3 and r.volume % 1 == 0
end

-- Streamer gift pairings: up to 8 small whole numbers (indexes into the client's fixed gift list).
ProgressService.GIFT_COUNT = 10 -- (CreatorUI.GIFTS: the fixed list a streamer picks from)
function ProgressService.cleanGifts(raw: any): { number }?
	if type(raw) ~= "table" then
		return nil
	end
	local out = {}
	for i = 1, 8 do
		local g = raw[i]
		if type(g) ~= "number" or g ~= g or g < 1 or g > ProgressService.GIFT_COUNT or g % 1 ~= 0 then
			return nil
		end
		out[i] = g
	end
	return out
end

-- A stored profile made safe (anything odd dropped).
-- SETTINGS (round 3, M6), checked: three small choices and three switches (round 4, M11: the dead
-- body's monitor), nothing else kept.
local SETTING_CHOICES = { sfx = 3, motion = 3, ui = 3 }
function ProgressService.cleanSettings(raw: any): { sfx: number, blood: boolean, shake: boolean, motion: number, ui: number, deadMon: boolean }?
	if type(raw) ~= "table" then
		return nil
	end
	local out = { sfx = 1, blood = true, shake = true, motion = 1, ui = 1, deadMon = false }
	for key, most in SETTING_CHOICES do
		local n = raw[key]
		if type(n) == "number" and n == math.floor(n) and n >= 1 and n <= most then
			(out :: any)[key] = n
		end
	end
	out.blood = raw.blood ~= false
	out.shake = raw.shake ~= false
	out.deadMon = raw.deadMon == true -- (off unless chosen, 10 Nov 2026; the old 'monitor' key is dropped)
	return out
end

local function clean(raw: unknown): Profile
	local p = fresh()
	if type(raw) ~= "table" then
		return p
	end
	local t = raw :: any
	if type(t.takedowns) == "number" and t.takedowns == t.takedowns then
		p.takedowns = math.clamp(math.floor(t.takedowns), 0, 1e9)
	end
	if type(t.eggs) == "number" and t.eggs == t.eggs then
		p.eggs = math.clamp(math.floor(t.eggs), 0, Progress.MAX_EGGS)
	end
	if type(t.hats) == "table" then
		for id, owned in t.hats do
			if type(id) == "string" and Progress.hatById[id] and owned == true then
				p.hats[id] = true
			end
		end
	end
	if type(t.hat) == "string" and p.hats[t.hat] then
		p.hat = t.hat
	end
	p.noPranks = t.noPranks == true
	if type(t.freeDay) == "number" and t.freeDay == t.freeDay then
		p.freeDay = math.clamp(math.floor(t.freeDay), 0, 1e7)
	end
	if type(t.seen) == "string" and #t.seen <= 16 then
		p.seen = t.seen
	end
	if type(t.radio) == "table" then
		local r = t.radio
		if ProgressService.validRadio(r) then
			p.radio = { on = r.on ~= false, track = r.track, volume = r.volume }
		end
	end
	if type(t.keys) == "table" then
		local keys = Keybinds.sanitize(t.keys)
		p.keys = keys -- (an empty table is "all reset": it must win over older keys in a merge)
	end
	if type(t.gifts) == "table" then
		p.gifts = ProgressService.cleanGifts(t.gifts)
	end
	if type(t.freeUntil) == "number" and t.freeUntil == t.freeUntil then
		p.freeUntil = math.clamp(t.freeUntil, 0, 1e11)
	end
	if type(t.lastDay) == "number" and t.lastDay == t.lastDay then
		p.lastDay = math.clamp(math.floor(t.lastDay), 0, 1e7)
	end
	if type(t.streak) == "number" and t.streak == t.streak then
		p.streak = math.clamp(math.floor(t.streak), 0, 10000)
	end
	if type(t.freezeWeek) == "number" and t.freezeWeek == t.freezeWeek then
		p.freezeWeek = math.clamp(math.floor(t.freezeWeek), 0, 1e7)
	end
	if type(t.best) == "table" then
		for gameId, score in t.best do
			if type(gameId) == "string" and #gameId <= 24 and type(score) == "number" and score == score then
				p.best[gameId] = math.clamp(math.floor(score), 0, 1e9)
			end
		end
	end
	if type(t.owned) == "table" then
		for id, yes in t.owned do
			local toy = type(id) == "string" and Toys.byId[id]
			if toy and toy.unlockAt > 0 and yes == true then
				p.owned[id] = true
			end
		end
	end
	if type(t.pending) == "table" then
		for key, id in t.pending do
			if type(key) == "string" and type(id) == "string" and Toys.byId[id] then
				for _, tier in Toys.priceTiers do
					if tier.key == key then
						p.pending[key] = id
					end
				end
			end
		end
	end
	if t.eco ~= nil then
		p.eco = Economy.clean(t.eco) -- (phase 2)
	end
	if type(t.bought) == "table" then
		for _, id in t.bought do
			if type(id) == "string" and #id <= 64 and not table.find(p.bought, id) then
				table.insert(p.bought, id)
			end
		end
		while #p.bought > BOUGHT_KEPT do
			table.remove(p.bought, 1)
		end
	end
	if type(t.oldEggs) == "number" and t.oldEggs == t.oldEggs then
		p.oldEggs = math.clamp(math.floor(t.oldEggs), 0, p.eggs)
	end
	if type(t.playSeconds) == "number" and t.playSeconds == t.playSeconds then
		p.playSeconds = math.clamp(math.floor(t.playSeconds), 0, 1e9)
	end
	if type(t.settings) == "table" then
		p.settings = ProgressService.cleanSettings(t.settings)
	end
	if type(t.goals) == "table" and type(t.goals.day) == "number" and t.goals.day == t.goals.day then
		local g: Goals = { day = math.clamp(math.floor(t.goals.day), 0, 1e7), p = {}, claimed = {}, bonus = t.goals.bonus == true }
		for i = 1, DailyGoals.COUNT do
			local v = if type(t.goals.p) == "table" then t.goals.p[i] else nil
			g.p[i] = if type(v) == "number" and v == v then math.clamp(v, 0, 1e6) else 0
			g.claimed[i] = type(t.goals.claimed) == "table" and t.goals.claimed[i] == true
		end
		p.goals = g
	end
	-- (A stored profile without a ladder is from before round 2: grandfathered once, on join.)
	p.ladder = if type(t.ladder) == "number" and t.ladder == t.ladder then math.clamp(math.floor(t.ladder), 0, LADDER) else 0
	return p
end

-- The day's goals from two servers: the later day wins; the same day keeps the most of each
-- (progress, claimed). (Claiming twice in two servers at once gives at most one egg each server:
-- an egg is the game's own, no money involved.)
function ProgressService.mergeGoals(a: Goals?, b: Goals?): Goals?
	if not a then
		return b
	elseif not b then
		return a
	elseif a.day ~= b.day then
		return if a.day > b.day then a else b
	end
	local m: Goals = { day = a.day, p = {}, claimed = {}, bonus = a.bonus or b.bonus }
	for i = 1, DailyGoals.COUNT do
		m.p[i] = math.max(a.p[i] or 0, b.p[i] or 0)
		m.claimed[i] = a.claimed[i] == true or b.claimed[i] == true
	end
	return m
end

-- What this session knows merged with what is stored (another server may have saved since).
local function merge(stored: Profile, session: Profile): Profile
	local m = fresh()
	m.takedowns = math.max(stored.takedowns, session.takedowns)
	m.eggs = session.eggs
	for id in stored.hats do
		m.hats[id] = true
	end
	for id in session.hats do
		m.hats[id] = true
	end
	m.hat = session.hat
	m.noPranks = session.noPranks
	m.freeDay = math.max(stored.freeDay, session.freeDay)
	m.seen = if session.seen ~= "" then session.seen else stored.seen
	m.radio = session.radio or stored.radio
	m.keys = session.keys or stored.keys
	m.gifts = session.gifts or stored.gifts
	m.settings = session.settings or stored.settings
	m.goals = ProgressService.mergeGoals(stored.goals, session.goals)
	-- (Phase 2: this session's economy wins: it was read from the store and only grew since.)
	m.eco = session.eco or stored.eco
	m.playSeconds = math.max(stored.playSeconds, session.playSeconds)
	m.freeUntil = math.max(stored.freeUntil, session.freeUntil)
	-- The daily streak: whichever side saw the later day.
	if session.lastDay >= stored.lastDay then
		m.lastDay, m.streak = session.lastDay, session.streak
	else
		m.lastDay, m.streak = stored.lastDay, stored.streak
	end
	m.freezeWeek = math.max(stored.freezeWeek or 0, session.freezeWeek or 0) -- (V8-3.4)
	for gameId, score in stored.best do
		m.best[gameId] = score
	end
	for gameId, score in session.best do
		m.best[gameId] = math.max(m.best[gameId] or 0, score)
	end
	-- A weapon owned anywhere stays owned; a purchase waiting is this session's choice first.
	for id in stored.owned do
		m.owned[id] = true
	end
	for id in session.owned do
		m.owned[id] = true
	end
	for key, id in stored.pending do
		m.pending[key] = id
	end
	for key, id in session.pending do
		m.pending[key] = id
	end
	m.ladder = math.max(stored.ladder, session.ladder)
	-- (A stored profile from before the ladder, met by a session that never read it, e.g. a save
	-- after a failed read: what it had is kept here, so a ladder number never stands for a loss.)
	-- Old eggs only get opened: the fewer side is the newer.
	m.oldEggs = math.min(stored.oldEggs, session.oldEggs)
	if stored.ladder < LADDER then
		ProgressService.grandfather(m, stored.takedowns, stored.eggs, stored.ladder)
	end
	for _, list in { stored.bought, session.bought } do
		for _, id in list do
			if not table.find(m.bought, id) then
				table.insert(m.bought, id)
			end
		end
	end
	while #m.bought > BOUGHT_KEPT do
		table.remove(m.bought, 1)
	end
	return m
end

local function retry<T>(fn: () -> T): (boolean, T?)
	for attempt = 1, RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		log.warn(string.format("DataStore call failed (%d/%d): %s", attempt, RETRIES, tostring(result)))
		if attempt < RETRIES then
			task.wait(2 ^ attempt)
		end
	end
	return false, nil
end

local function load(userId: number): (boolean, Profile?)
	local ds = store
	if not ds then
		local m = memory[userId]
		return true, if m then clean(m) else nil
	end
	local ok, raw = retry(function()
		return ds:GetAsync(tostring(userId))
	end)
	if not ok then
		return false, nil
	end
	return true, if raw ~= nil then clean(raw) else nil
end

-- Eggs are kept as a change: what this session found minus what it opened since the last save
-- goes onto the stored count (a quick hop to another server neither brings back an opened egg
-- nor loses a found one).
local eggBase: { [Player]: number } = {}
-- One save per player at a time: a second one (leaving while an overdue one still retries) waits
-- for the first, then reads the egg baseline it moved (never adding the same found eggs twice).
local saveBusy: { [Player]: boolean } = {}
local SAVE_QUEUE_WAIT = 40 -- s at most a save waits for the one before it

local saveLocked: (Player, Profile) -> boolean

-- A field this version does not know (written by a newer one) rides along on every save, so a
-- server running an older version never wipes it. (Round 2, N4: the review's lesson from 0.12
-- servers, which rebuilt the profile from their own field list. Those are shut down at publish.)
local function keepUnknown(old: unknown, doc: { [string]: any }): { [string]: any }
	if type(old) == "table" then
		for key, value in old :: { [any]: any } do
			if type(key) == "string" and doc[key] == nil and not KNOWN_FIELDS[key] then
				doc[key] = value
			end
		end
	end
	return doc
end

local function save(player: Player, profile: Profile): boolean
	-- (V8-0.8: a play-as-newcomer visit is never saved over the account's real profile.)
	if (require(script.Parent:WaitForChild("TestAccount")) :: any).is(player) then
		return true
	end
	local waited = 0
	while saveBusy[player] and waited < SAVE_QUEUE_WAIT do
		waited += task.wait(0.2)
	end
	saveBusy[player] = true
	local ok, result = pcall(saveLocked, player, profile)
	saveBusy[player] = nil
	return ok and result == true
end

function saveLocked(player: Player, profile: Profile): boolean
	local userId = player.UserId
	local ds = store
	local base = eggBase[player] or profile.eggs
	local eggsNow = profile.eggs
	local function withEggs(stored: Profile, merged: Profile): Profile
		merged.eggs = math.clamp(stored.eggs + (eggsNow - base), 0, Progress.MAX_EGGS)
		return merged
	end
	if not ds then
		local stored = clean(memory[userId])
		memory[userId] = withEggs(stored, merge(stored, profile))
		eggBase[player] = eggsNow
		return true
	end
	saving += 1
	local ok = retry(function()
		ds:UpdateAsync(tostring(userId), function(old)
			local stored = clean(old)
			local merged = withEggs(stored, merge(stored, profile))
			return keepUnknown(old, {
				takedowns = merged.takedowns,
				eggs = merged.eggs,
				hats = merged.hats,
				hat = merged.hat,
				best = merged.best,
				lastDay = merged.lastDay,
				noPranks = merged.noPranks,
				freeDay = merged.freeDay,
				seen = merged.seen,
				radio = merged.radio,
				keys = merged.keys,
				gifts = merged.gifts,
				freeUntil = merged.freeUntil,
				streak = merged.streak,
				freezeWeek = merged.freezeWeek,
				owned = merged.owned,
				pending = merged.pending,
				ladder = merged.ladder,
				bought = merged.bought,
				oldEggs = math.min(merged.oldEggs, merged.eggs),
				playSeconds = merged.playSeconds,
				settings = merged.settings,
				goals = merged.goals,
				eco = merged.eco, -- (phase 2: bolts, journal, daily, codes; release fix: it was never written)
			}), { userId }
		end)
	end)
	saving -= 1
	if ok then
		eggBase[player] = eggsNow
	end
	return ok
end

local addOnto: (Profile, Profile) -> Profile

-- Leaving while the stored profile could never be read: what this session played is added on top
-- of whatever is stored, inside the update itself (no earlier read needed), so it is not lost.
local function saveOnto(player: Player, session: Profile): boolean
	local userId = player.UserId
	local ds = store
	if not ds then
		memory[userId] = addOnto(clean(memory[userId]), session)
		return true
	end
	saving += 1
	local ok = retry(function()
		ds:UpdateAsync(tostring(userId), function(old)
			local m = addOnto(clean(old), session)
			return keepUnknown(old, {
				takedowns = m.takedowns, eggs = m.eggs, hats = m.hats, hat = m.hat, best = m.best,
				lastDay = m.lastDay, noPranks = m.noPranks, freeDay = m.freeDay, seen = m.seen,
				radio = m.radio, keys = m.keys, gifts = m.gifts, freeUntil = m.freeUntil, streak = m.streak,
				freezeWeek = m.freezeWeek,
				owned = m.owned, pending = m.pending, ladder = m.ladder, bought = m.bought,
				oldEggs = math.min(m.oldEggs, m.eggs),
				playSeconds = m.playSeconds, settings = m.settings, goals = m.goals, eco = m.eco,
			}), { userId }
		end)
	end)
	saving -= 1
	return ok
end

local dirtySince: { [Player]: number } = {}
-- Time played (round 3, M6): counted on the server's clock while the player is here, added to the
-- profile every PLAY_TICK s. It rides along with the next save; a long stay with nothing else to
-- save is saved every PLAY_SAVE_EVERY s of play, and leaving always saves it.
local PLAY_TICK = 30
local PLAY_SAVE_EVERY = 300
local playCounted: { [Player]: number } = {} -- os.clock() up to which this visit's time is counted
local playUnsaved: { [Player]: number } = {} -- s counted since the last save went out
local function scheduleSave(player: Player)
	local token = (dirty[player] or 0) + 1
	dirty[player] = token
	dirtySince[player] = dirtySince[player] or os.clock()
	task.delay(SAVE_DELAY, function()
		local profile = profiles[player]
		local overdue = os.clock() - (dirtySince[player] or math.huge) >= SAVE_MAX_WAIT
		if (dirty[player] == token or overdue) and profile and loaded[player] and not readFailed[player] then
			dirtySince[player] = nil
			if save(player, profile) then
				playUnsaved[player] = 0
				if dirty[player] == token then
					dirty[player] = nil
				end
			end
		end
	end)
end

-- Adds the time since it was last counted to the player's profile (capped: a stalled server step
-- never counts as play). Returns the seconds added.
local function countPlay(player: Player): number
	local p = profiles[player]
	local from = playCounted[player]
	local now = os.clock()
	playCounted[player] = now
	if not p or not from then
		return 0
	end
	local add = math.clamp(now - from, 0, PLAY_TICK * 2)
	p.playSeconds += add
	if add > 0 then
		ProgressService.goal(player, "Minutes", add / 60)
	end
	playUnsaved[player] = (playUnsaved[player] or 0) + add
	return add
end

function ProgressService.playSecondsOf(player: Player): number?
	local p = profiles[player]
	return if p then p.playSeconds else nil
end

------------------------------------------------------------------------------------------------
-- What everyone sees

local function hatPart(model: Model, head: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Shape = shape or Enum.PartType.Block
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = head.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = p
	weld.C0 = offset
	weld.Parent = p
	p.Parent = model
	return p
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder standing up

-- Builds a hat out of simple shapes on top of the head.
local function buildHat(head: BasePart, id: string): Model
	local hat = Instance.new("Model")
	hat.Name = "Hat"
	hat:SetAttribute("Worn", true) -- never part of the body when it goes limp
	hat:SetAttribute("HatId", id)
	local s = head.Size
	local top = s.Y / 2
	local w = s.X
	if id == "PartyHat" then
		for i = 0, 3 do
			local d = w * (0.9 - i * 0.22)
			hatPart(hat, head, "Cone" .. i, Vector3.new(0.38, d, d), CFrame.new(0, top + 0.2 + i * 0.36, 0) * UP, if i % 2 == 0 then Color3.fromRGB(240, 80, 150) else Color3.fromRGB(80, 200, 255), Enum.PartType.Cylinder)
		end
		hatPart(hat, head, "Pom", Vector3.new(0.35, 0.35, 0.35), CFrame.new(0, top + 1.65, 0), Color3.fromRGB(255, 220, 60), Enum.PartType.Ball)
	elseif id == "Cone" then
		hatPart(hat, head, "Base", Vector3.new(w * 1.3, 0.15, w * 1.3), CFrame.new(0, top + 0.08, 0), Color3.fromRGB(30, 30, 30))
		for i = 0, 3 do
			local d = w * (1 - i * 0.2)
			hatPart(hat, head, "Cone" .. i, Vector3.new(0.45, d, d), CFrame.new(0, top + 0.35 + i * 0.42, 0) * UP, if i == 1 then Color3.fromRGB(250, 250, 250) else Color3.fromRGB(255, 120, 30), Enum.PartType.Cylinder)
		end
	elseif id == "Beanie" then
		hatPart(hat, head, "Cap", Vector3.new(w * 1.08, w * 0.7, w * 1.08), CFrame.new(0, top - 0.05, 0), Color3.fromRGB(200, 50, 60), Enum.PartType.Ball, Enum.Material.Fabric)
		hatPart(hat, head, "Pom", Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, top + 0.4, 0), Color3.fromRGB(250, 250, 250), Enum.PartType.Ball, Enum.Material.Fabric)
	elseif id == "Bucket" then
		hatPart(hat, head, "Bucket", Vector3.new(1.1, w * 1.1, w * 1.1), CFrame.new(0, top + 0.35, 0) * UP, Color3.fromRGB(150, 155, 165), Enum.PartType.Cylinder, Enum.Material.Metal)
		hatPart(hat, head, "Handle", Vector3.new(w * 1.2, 0.1, 0.1), CFrame.new(0, top + 0.95, 0), Color3.fromRGB(90, 90, 95), nil, Enum.Material.Metal)
	elseif id == "Cowboy" then
		hatPart(hat, head, "Brim", Vector3.new(0.12, w * 2, w * 2), CFrame.new(0, top + 0.05, 0) * UP, Color3.fromRGB(140, 90, 50), Enum.PartType.Cylinder, Enum.Material.Fabric)
		hatPart(hat, head, "Crown", Vector3.new(w * 0.8, 0.7, w * 0.8), CFrame.new(0, top + 0.4, 0), Color3.fromRGB(140, 90, 50), nil, Enum.Material.Fabric)
		hatPart(hat, head, "Band", Vector3.new(w * 0.82, 0.14, w * 0.82), CFrame.new(0, top + 0.18, 0), Color3.fromRGB(40, 30, 25))
	elseif id == "Propeller" then
		hatPart(hat, head, "Cap", Vector3.new(w * 1.06, w * 0.6, w * 1.06), CFrame.new(0, top - 0.05, 0), Color3.fromRGB(60, 120, 230), Enum.PartType.Ball)
		hatPart(hat, head, "Stick", Vector3.new(0.4, 0.1, 0.1), CFrame.new(0, top + 0.4, 0) * UP, Color3.fromRGB(240, 200, 40), Enum.PartType.Cylinder)
		hatPart(hat, head, "BladeA", Vector3.new(1.6, 0.06, 0.3), CFrame.new(0, top + 0.6, 0) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(240, 70, 60))
		hatPart(hat, head, "BladeB", Vector3.new(0.3, 0.06, 1.6), CFrame.new(0, top + 0.6, 0) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(60, 200, 90))
	elseif id == "Chef" then
		hatPart(hat, head, "Band", Vector3.new(0.9, w * 1.02, w * 1.02), CFrame.new(0, top + 0.3, 0) * UP, Color3.fromRGB(252, 252, 252), Enum.PartType.Cylinder)
		hatPart(hat, head, "Puff", Vector3.new(w * 1.3, w * 1.1, w * 1.3), CFrame.new(0, top + 0.95, 0), Color3.fromRGB(252, 252, 252), Enum.PartType.Ball)
	elseif id == "Viking" then
		hatPart(hat, head, "Dome", Vector3.new(w * 1.1, w * 0.8, w * 1.1), CFrame.new(0, top - 0.05, 0), Color3.fromRGB(160, 165, 175), Enum.PartType.Ball, Enum.Material.Metal)
		for side = -1, 1, 2 do
			hatPart(hat, head, "Horn", Vector3.new(1.1, 0.32, 0.32), CFrame.new(side * w * 0.6, top + 0.35, 0) * CFrame.Angles(0, 0, math.rad(side * 35)), Color3.fromRGB(245, 235, 210), Enum.PartType.Cylinder)
		end
	elseif id == "Halo" then
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			hatPart(hat, head, "Glow" .. i, Vector3.new(0.26, 0.26, 0.26), CFrame.new(math.cos(a) * w * 0.55, top + 0.7, math.sin(a) * w * 0.55), Color3.fromRGB(255, 240, 150), Enum.PartType.Ball, Enum.Material.Neon)
		end
	elseif id == "Crown" or id == "GoldCrown" then
		local gold = Color3.fromRGB(255, 200, 50)
		local big = if id == "GoldCrown" then 1.25 else 1
		local band = hatPart(hat, head, "Band", Vector3.new(0.45 * big, w * 0.95 * big, w * 0.95 * big), CFrame.new(0, top + 0.18, 0) * UP, gold, Enum.PartType.Cylinder, if id == "GoldCrown" then Enum.Material.Neon else Enum.Material.Metal)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			hatPart(hat, head, "Spike" .. i, Vector3.new(0.22, 0.45, 0.22) * big, CFrame.new(math.cos(a) * w * 0.4 * big, top + 0.55 * big, math.sin(a) * w * 0.4 * big), gold, nil, Enum.Material.Metal)
		end
		hatPart(hat, head, "Gem", Vector3.new(0.25, 0.25, 0.25), CFrame.new(0, top + 0.2, -w * 0.48 * big), Color3.fromRGB(230, 40, 70), Enum.PartType.Ball, Enum.Material.Glass)
		if id == "GoldCrown" then
			local light = Instance.new("PointLight")
			light.Color = gold
			light.Range = 8
			light.Brightness = 1.5
			light.Parent = band
		end
	elseif id == "Duck" then
		hatPart(hat, head, "Body", Vector3.new(1.1, 0.8, 1.3), CFrame.new(0, top + 0.35, 0.1), Color3.fromRGB(255, 220, 40), Enum.PartType.Ball)
		hatPart(hat, head, "DuckHead", Vector3.new(0.65, 0.65, 0.65), CFrame.new(0, top + 0.85, -0.35), Color3.fromRGB(255, 220, 40), Enum.PartType.Ball)
		hatPart(hat, head, "Beak", Vector3.new(0.3, 0.12, 0.3), CFrame.new(0, top + 0.8, -0.72), Color3.fromRGB(255, 130, 30))
	end
	return hat
end

local function dressHat(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not character or not head or not head:IsA("BasePart") then
		return
	end
	local old = character:FindFirstChild("Hat")
	if old then
		old:Destroy()
	end
	local profile = profiles[player]
	local id = profile and profile.hat
	if id and Progress.hatById[id] then
		buildHat(head, id).Parent = character
	end
end

local function sendState(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	local owned = {}
	for id in p.hats do
		table.insert(owned, id)
	end
	remote:FireClient(player, "State", {
		takedowns = p.takedowns,
		playSeconds = p.playSeconds, -- (round 5: the LEVEL by the bar, Shared/Level)
		eggs = p.eggs,
		eggEvery = (ProgressService.eggEvery and ProgressService.eggEvery(player)) or Progress.EGG_EVERY,
		hats = owned,
		hat = p.hat or "",
		best = p.best,
		streak = p.streak,
		dailyToday = p.lastDay >= math.floor(os.time() / 86400),
		loading = readFailed[player] == true, -- (the daily egg waits for the stored profile)
		goals = ProgressService.goalsView(player),
		streakEggs = DailyGoals.STREAK_EGGS,
	})
end

------------------------------------------------------------------------------------------------
-- The day's goals (round 3, M9: DailyGoals). Counted here as things happen; an egg for each one
-- claimed, a bonus egg for all three. A profile not read yet counts nothing (no egg can be paid).

ProgressService.clockForTest = nil :: (() -> number)? -- (tests: another day)
local function today(): number
	local clock = ProgressService.clockForTest
	return DailyGoals.dayOf(if clock then clock() else os.time())
end

-- The profile's goals for today (a new day: fresh ones).
local function goalsOf(p: Profile): Goals
	local day = today()
	local g = p.goals
	if not g or g.day ~= day then
		g = { day = day, p = { 0, 0, 0 }, claimed = { false, false, false }, bonus = false }
		p.goals = g
	end
	return g :: Goals
end

-- Something counted towards today's goals: an amount to add, or for a "max" kind the value reached.
function ProgressService.goal(player: Player, kind: string, amount: number)
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] then
		return
	end
	local g = goalsOf(p)
	local changed = false
	for i, goal in DailyGoals.forDay(g.day) do
		if goal.kind == kind and (g.p[i] or 0) < goal.need then
			local before = g.p[i] or 0
			g.p[i] = math.min(goal.need, if DailyGoals.MAX_KINDS[kind] then math.max(before, amount) else before + amount)
			if g.p[i] >= goal.need then
				remote:FireClient(player, "GoalDone", goal.text)
				scheduleSave(player) -- (a goal done is kept at once; progress rides with the next save)
			end
			changed = changed or math.floor(g.p[i]) ~= math.floor(before) or g.p[i] >= goal.need
		end
	end
	if changed then
		sendState(player)
	end
end

-- What the screen shows: today's goals, progress, claimed, and the bonus.
function ProgressService.goalsView(player: Player): { [string]: any }?
	local p = profiles[player]
	if not p then
		return nil
	end
	local g = goalsOf(p)
	local list = {}
	for i, goal in DailyGoals.forDay(g.day) do
		list[i] = { text = goal.text, need = goal.need, got = math.floor(g.p[i] or 0), claimed = g.claimed[i] == true }
	end
	return { day = g.day, list = list, bonus = g.bonus }
end

-- CLAIM: goal i (1-3) done and not claimed yet, or 4: the bonus once all three are claimed. An
-- egg each; refused (told) with full egg slots. Returns whether an egg was given.
function ProgressService.claimGoal(player: Player, i: unknown): boolean
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] or type(i) ~= "number" then
		return false
	end
	local g = goalsOf(p)
	local goals = DailyGoals.forDay(g.day)
	local ready = false
	if i >= 1 and i <= DailyGoals.COUNT and i == math.floor(i) then
		ready = not g.claimed[i] and (g.p[i] or 0) >= goals[i].need
	elseif i == DailyGoals.COUNT + 1 then
		ready = not g.bonus and g.claimed[1] and g.claimed[2] and g.claimed[3]
	end
	if not ready then
		-- (A tap on a stale screen, after midnight or twice: the screen is put right and told why.)
		local claimedAlready = (i >= 1 and i <= DailyGoals.COUNT and g.claimed[i] == true) or (i == DailyGoals.COUNT + 1 and g.bonus)
		remote:FireClient(player, "Notice", if claimedAlready then "Already claimed today" else "Not done yet: keep going!")
		sendState(player)
		return false
	end
	local eggs = if i == DailyGoals.COUNT + 1 then DailyGoals.BONUS_EGGS else DailyGoals.EGGS_PER_GOAL
	if p.eggs + eggs > Progress.MAX_EGGS then
		remote:FireClient(player, "Notice", "Your egg slots are full: open some, then claim")
		return false
	end
	if i == DailyGoals.COUNT + 1 then
		g.bonus = true
	else
		g.claimed[i :: number] = true
	end
	p.eggs += eggs
	remote:FireClient(player, "Notice", if i == DailyGoals.COUNT + 1 then "All three done today: a bonus egg!" else "Goal done: an egg!")
	Metrics.event(player, if i == DailyGoals.COUNT + 1 then "Goals_All" else "Goal_" .. goals[i :: number].kind)
	sendState(player)
	scheduleSave(player)
	return true
end

local function showStats(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		local takedowns = Instance.new("IntValue")
		takedowns.Name = "Takedowns"
		takedowns.Parent = stats
		local rank = Instance.new("StringValue")
		rank.Name = "Rank"
		rank.Parent = stats
		stats.Parent = player
	end
	assert(stats)
	local rank = Progress.rankOf(p.takedowns)
	;(stats:FindFirstChild("Takedowns") :: IntValue).Value = p.takedowns
	;(stats:FindFirstChild("Rank") :: StringValue).Value = rank.name
	player:SetAttribute("Takedowns", p.takedowns)
	player:SetAttribute("Rank", rank.name)
	local ids = {}
	for id in p.owned do
		table.insert(ids, id)
	end
	table.sort(ids)
	player:SetAttribute("Owned", table.concat(ids, ","))
end

------------------------------------------------------------------------------------------------
-- Takedowns

-- Tells a player about each tool unlocked between two takedown counts (from < unlockAt <= to).
function ProgressService.tellUnlocks(player: Player, from: number, to: number)
	for _, toy in Toys.list do
		local at = (toy :: any).unlockAt or 0
		local p = profiles[player]
		if at > 0 and from < at and to >= at and not (p and p.owned[toy.id]) then
			remote:FireClient(player, "Unlock", { id = toy.id, name = toy.label })
			SessionStats.count(player, "unlocks") -- (V8-1.4)
			SessionStats.mark(player, "firstUnlockAt")
			ProgressService.lastUnlock[player] = toy.label
			Metrics.event(player, "Unlock", 1, toy.id)
		end
	end
end

-- Gives a player takedowns (eggs found and rank changes told). Returns eggs found.
function ProgressService.addTakedowns(player: Player, count: number): number
	local p = profiles[player]
	if not p or count <= 0 then
		return 0
	end
	local before = p.takedowns
	local rankBefore = Progress.rankOf(before)
	p.takedowns += count
	ExperimentService.event(player, "Takedown", count) -- (phase 1: experiment cards)
	local every = (ProgressService.eggEvery and ProgressService.eggEvery(player)) or Progress.EGG_EVERY
	local found = math.floor(p.takedowns / every) - math.floor(before / every)
	if found > 0 then
		p.eggs = math.min(Progress.MAX_EGGS, p.eggs + found)
	end
	showStats(player)
	sendState(player)
	local rankNow = Progress.rankOf(p.takedowns)
	if found > 0 then
		remote:FireClient(player, "Egg", found)
	end
	if rankNow.name ~= rankBefore.name then
		remote:FireClient(player, "Rank", rankNow.name)
		Metrics.event(player, "RankUp_" .. rankNow.name)
	end
	-- A tool unlocked: told once, the moment its takedowns are reached.
	if not readFailed[player] then -- (counting from 0 while the store is unreadable: no false news)
		ProgressService.tellUnlocks(player, before, p.takedowns)
		BadgeAwards.takedowns(player, p.takedowns)
	end
	scheduleSave(player)
	return found
end

local credit: (player: Player, model: Model, now: number) -> ()

-- How long a knock-down waits for the server's own hit to arrive when its state report came first
-- (round 5, phase 00: the owner's client reports the fall on its own remote; the hit request can be
-- a frame behind, and the takedown was lost).
ProgressService.DOWN_RETRY = 0.8

local function onDown(model: Model, state: string, retried: boolean?)
	if not model.Parent or model:GetAttribute("NoCredit") == true then
		return -- (a stream's bodies never count: gifts give no lasting value)
	end
	local now = os.clock()
	if now - (lastDown[model] or -math.huge) < Progress.TAKEDOWN_COOLDOWN then
		return
	end
	-- (Round 4, M10: a dead body counts once, however often it is hit or moved in its DEAD_HOLD.)
	local dead = model:GetAttribute("Vital") == "Dead"
	if dead then
		local died = model:GetAttribute("DiedAt")
		local credited = creditedAt[model]
		if credited and type(died) == "number" and credited >= died - 1 then
			return
		end
	end
	local who, at = Dummies.blame(model)
	-- Only a knock-down that follows a hit the server itself carried out (a tool through
	-- HitService, a blast, a grab it accepted: DummyControl / HitService stamp ServerHitAt) counts;
	-- a client's own report of a contact never makes a takedown (no farming the board with a bot).
	-- (And that hit was by the same player the blame names: nobody claims someone else's hit.)
	local seen = model:GetAttribute("ServerHitAt")
	local fresh = who ~= 0 and Workspace:GetServerTimeNow() - at <= Dummies.BLAME_TIME
	local served = type(seen) == "number" and Workspace:GetServerTimeNow() - seen <= Dummies.BLAME_TIME and model:GetAttribute("ServerHitBy") == who
	if not fresh or not served then
		if not retried then
			-- (Once more a moment later: the hit itself may still be on its way.)
			task.delay(ProgressService.DOWN_RETRY, onDown, model, state, true)
		end
		return
	end
	local host = model:GetAttribute("GameHost")
	if host ~= nil and host ~= who then
		return -- (an arena runner in someone else's round: theirs to knock down)
	end
	local player = Players:GetPlayerByUserId(who)
	if not player then
		return
	end
	SessionStats.count(player, "knocks")
	credit(player, model, now)
end

-- Round 5, phase 00: the first hit a player lands on their own greeter is a takedown, whatever the
-- body does (a round in an arm only flinches; on a phone the first taps often land there). Once per
-- greeter; its fall a moment later does not count again (the cooldown).
function ProgressService.greeterHit(player: Player, model: Model)
	if model:GetAttribute("GreeterCredited") == true or model:GetAttribute("Greeter") ~= player.UserId then
		return
	end
	model:SetAttribute("GreeterCredited", true)
	credit(player, model, os.clock())
end

function credit(player: Player, model: Model, now: number)
	lastDown[model] = now
	creditedAt[model] = Workspace:GetServerTimeNow()
	if not model:GetAttribute("DestroyHooked") then
		model:SetAttribute("DestroyHooked", true)
		model.Destroying:Once(function()
			lastDown[model] = nil
			creditedAt[model] = nil
		end)
	end
	local c = combos[player]
	if c and now - c.at <= ProgressService.COMBO_GAP then
		c.count += 1
		c.at = now
	else
		c = { count = 1, at = now, bonus = 0 }
		combos[player] = c
	end
	assert(c)
	local bonus = 0
	if c.count % ProgressService.COMBO_STEP == 0 and c.bonus < ProgressService.COMBO_BONUS_MAX then
		bonus = math.min(if c.count >= 2 * ProgressService.COMBO_STEP then 2 else 1, ProgressService.COMBO_BONUS_MAX - c.bonus)
		c.bonus += bonus
	end
	local count = 1 + bonus
	local pelvis = model:FindFirstChild("LowerTorso")
	remote:FireClient(player, "Combo", { count = c.count, bonus = bonus, at = if pelvis and pelvis:IsA("BasePart") then pelvis.Position else nil })
	local boost = ProgressService.boost
	if boost and boost(player) then
		boostHalf[player] = (boostHalf[player] or 0) + 1
		if boostHalf[player] >= 2 then
			boostHalf[player] = 0
			count += 1
		end
	end
	ProgressService.addTakedowns(player, count)
	SessionStats.count(player, "takedowns", count)
	Metrics.takedowns(player, count)
	ProgressService.goal(player, "Takedowns", 1)
	ProgressService.goal(player, "Combo", c.count)
end

------------------------------------------------------------------------------------------------
-- Requests from the client

local function allowed(player: Player): boolean
	local now = os.clock()
	local w = window[player]
	if not w or now - w.start > 10 then
		w = { start = now, count = 0 }
		window[player] = w
	end
	w.count += 1
	return w.count <= REQUESTS_PER_10S
end

-- Tests: the last tool a player was told they unlocked (its label).
ProgressService.lastUnlock = setmetatable({}, { __mode = "k" }) :: { [Player]: string }

-- What an egg held: a weapon (new to its owner), or a hat (and whether it is new).
export type Prize = { kind: "Weapon", id: string, name: string } | { kind: "Hat", hat: Progress.Hat, new: boolean }

ProgressService.REVEAL_DELAY = 3.2 -- s: the opening plays out before the prize is given (no spoiler)
ProgressService.EGG_NEAR = 6 -- an egg's weapon is one of this many next up the ladder...
ProgressService.EGG_ANY = 0.15 -- ...or, this often, any weapon still locked (a lucky jump)
ProgressService.WOW_EGGS = 2 -- the first this many eggs give a big, loud weapon (WOW_POOL)
ProgressService.WOW_POOL = { "Grenade", "Rocket", "C4", "Minigun", "TNT", "RPG" }

-- The weapons a player cannot use yet, lowest first.
local function lockedOf(p: Profile): { Toys.Toy }
	local list = {}
	for _, toy in Toys.list do
		if toy.unlockAt > p.takedowns and not p.owned[toy.id] then
			table.insert(list, toy)
		end
	end
	table.sort(list, function(x, y)
		return if x.unlockAt ~= y.unlockAt then x.unlockAt < y.unlockAt else x.id < y.id
	end)
	return list
end
ProgressService.lockedOf = function(player: Player): { Toys.Toy }
	local p = profiles[player]
	return if p then lockedOf(p) else {}
end

local function showOwned(player: Player, p: Profile)
	local ids = {}
	for id in p.owned do
		table.insert(ids, id)
	end
	table.sort(ids)
	-- (Every screen of the player reads it: the catalog shows what is theirs at once.)
	player:SetAttribute("Owned", table.concat(ids, ","))
end

-- A weapon is the player's for good (an egg, a purchase). Returns whether it was new.
function ProgressService.grantWeapon(player: Player, id: string, how: string): boolean
	local p = profiles[player]
	local toy = Toys.byId[id]
	if not p or not toy or toy.unlockAt <= 0 or p.owned[id] then
		return false
	end
	p.owned[id] = true
	Metrics.event(player, "Weapon_" .. how, 1, id)
	scheduleSave(player)
	showOwned(player, p)
	return true
end

-- A player's takedowns (nil before the profile is there).
function ProgressService.takedownsOf(player: Player): number?
	local p = profiles[player]
	return p and p.takedowns
end

-- The weapon chosen with BUY, kept for its price tier until the order delivers it (WeaponShop).
function ProgressService.choosePending(player: Player, tierKey: string, id: string): boolean
	local p = profiles[player]
	local toy = Toys.byId[id]
	local tier = toy and Toys.priceTier(toy)
	if not p or not toy or not tier or tier.key ~= tierKey then
		return false
	end
	p.pending[tierKey] = id
	scheduleSave(player)
	return true
end

-- The weapon chosen for a tier now (written into its order as the receipt arrives), or nil.
function ProgressService.pendingOf(player: Player, tierKey: string): string?
	local p = profiles[player]
	local id = p and p.pending[tierKey]
	return if id and id ~= "" then id else nil
end

-- A weapon purchase (WeaponShop): the weapon the order names (chosen: written down as the receipt
-- came in), else the one chosen before the prompt (pending, per price tier); when that one is the
-- player's already, the lowest still locked at that price or dearer; with every weapon owned, two
-- eggs. Never yields. "done": this purchase id was delivered before (a repeated receipt); "wait":
-- the profile is not ready (the order is claimed again later).
function ProgressService.deliverWeapon(player: Player, tierKey: string, purchaseId: string, chosen: string?): (string, string?)
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] then
		return "wait", nil
	end
	if table.find(p.bought, purchaseId) then
		return "done", nil
	end
	local id = chosen or ProgressService.pendingOf(player, tierKey)
	local toy = id and Toys.byId[id]
	local tierOf = toy and Toys.priceTier(toy)
	if not tierOf or tierOf.key ~= tierKey then
		toy = nil -- (a note or choice that does not fit the price paid is not trusted)
	end
	if not toy or p.owned[toy.id] or p.takedowns >= toy.unlockAt then
		-- (The lowest locked one at the price paid or dearer; with none left there, the dearest
		-- locked one: never less than was paid for while there is a choice.)
		local paid = 0
		for _, tier in Toys.priceTiers do
			if tier.key == tierKey then
				paid = tier.robux
			end
		end
		local locked = lockedOf(p)
		toy = locked[#locked]
		for _, candidate in locked do
			local tier = Toys.priceTier(candidate)
			if tier and tier.robux >= paid then
				toy = candidate
				break
			end
		end
	end
	table.insert(p.bought, purchaseId)
	while #p.bought > BOUGHT_KEPT do
		table.remove(p.bought, 1)
	end
	-- The choice is used up: the pending one when the order had no note, or the one its note names
	-- (a newer choice made meanwhile stays for its own purchase).
	if chosen == nil or p.pending[tierKey] == chosen then
		p.pending[tierKey] = "" -- (used: "" so a save clears the stored one too; never read back)
	end
	if not toy then
		-- (V8-0.7, Config.MILD_V8: no paid random items. With every weapon of the tier owned, the
		-- purchase pays a fixed number of BOLTS, the worth of the two eggs it used to give.)
		local C = Config :: any
		if C.MILD_V8 and C.ECONOMY then
			local bolts = 2 * C.PLAYTIME_BOLTS
			local okGive, gave = pcall(function()
				return (require(script.Parent:WaitForChild("EconomyService")) :: any).give(player, bolts, nil, true)
			end)
			if okGive and gave == true then
				Metrics.event(player, "Weapon_Bought_Bolts")
				scheduleSave(player)
				sendState(player)
				return "bolts", nil
			end
		end
		p.eggs = math.min(Progress.MAX_EGGS, p.eggs + 2)
		Metrics.event(player, "Weapon_Bought_Eggs")
		scheduleSave(player)
		sendState(player)
		return "eggs", nil
	end
	p.owned[toy.id] = true
	Metrics.event(player, "Weapon_Bought", 1, toy.id)
	scheduleSave(player)
	showOwned(player, p)
	sendState(player)
	return "weapon", toy.id
end

-- Opens one of a player's eggs. rolls (tests): weapon picks within the list, any decides a lucky
-- jump, rarity and hat roll a hat.
function ProgressService.openEgg(player: Player, rolls: { pick: number?, any: number?, rarity: number?, hat: number? }?, revealDelay: number?): Prize?
	local p = profiles[player]
	if not p or p.eggs <= 0 or readFailed[player] then
		return nil -- (nothing opens before the stored profile is read: it may own that weapon)
	end
	p.eggs -= 1
	SessionStats.count(player, "eggOpened")
	ExperimentService.event(player, "Egg", 1)
	ProgressService.goal(player, "Eggs", 1)
	BadgeAwards.award(player, "FirstEgg")
	-- (A slot just came free: a daily egg that waited for room comes now. After this call.)
	task.defer(ProgressService.checkNewDay, player)
	local r = rolls or {}
	local delay = revealDelay or 0
	local locked = lockedOf(p)
	local oldEgg = p.oldEggs > 0
	if oldEgg then
		p.oldEggs -= 1 -- (found before the weapon ladder: a hat, as then)
	end
	if #locked > 0 and not oldEgg then
		local pool = if (r.any or rng:NextNumber()) < ProgressService.EGG_ANY then #locked else math.min(#locked, ProgressService.EGG_NEAR)
		local toy = locked[math.clamp(math.floor((r.pick or rng:NextNumber()) * pool) + 1, 1, pool)]
		-- The first eggs are a WOW (10 Nov 2026, from the launch audit: a free egg that gives a Poke
		-- loses the player): while they own fewer than WOW_EGGS weapons from eggs or the shop, one of
		-- the big, loud ones still locked.
		if rolls == nil then
			local ownedCount = 0
			for _ in p.owned do
				ownedCount += 1
			end
			if ownedCount < ProgressService.WOW_EGGS then
				local wow = {}
				for _, id in ProgressService.WOW_POOL do
					local t = Toys.byId[id]
					if t and table.find(locked, t) then
						table.insert(wow, t)
					end
				end
				if #wow > 0 then
					toy = wow[rng:NextInteger(1, #wow)]
				end
			end
		end
		p.owned[toy.id] = true -- (decided now: a server that closes during the opening keeps it)
		Metrics.event(player, "Egg_Weapon")
		scheduleSave(player)
		local function revealWeapon()
			if player.Parent and profiles[player] == p then
				showOwned(player, p)
				sendState(player)
			end
		end
		if delay > 0 then
			task.delay(delay, revealWeapon)
		else
			revealWeapon()
		end
		return { kind = "Weapon", id = toy.id, name = toy.label }
	end
	local hat = Progress.roll(r.rarity or rng:NextNumber(), r.hat or rng:NextNumber())
	Metrics.event(player, "Egg_" .. hat.rarity)
	local isNew = not p.hats[hat.id]
	p.hats[hat.id] = true
	if isNew then
		p.hat = hat.id -- a new hat goes on (once the opening has shown it)
	end
	scheduleSave(player)
	local function reveal()
		if player.Parent and profiles[player] == p then
			if isNew then
				dressHat(player)
			end
			sendState(player)
		end
	end
	if delay > 0 then
		task.delay(delay, reveal)
	else
		reveal()
	end
	return { kind = "Hat", hat = hat, new = isNew }
end

function ProgressService.wear(player: Player, id: unknown): boolean
	local p = profiles[player]
	if not p or type(id) ~= "string" then
		return false
	end
	if id == "" then
		p.hat = nil
	elseif p.hats[id] then
		p.hat = id
	else
		return false
	end
	dressHat(player)
	sendState(player)
	scheduleSave(player)
	return true
end

-- lihfolk-ignore: remote-unvalidated-args (kind is only compared with string literals; each branch checks arg)
local function onRequest(player: Player, kind: unknown, arg: unknown)
	if not allowed(player) then
		return
	end
	if kind == "Open" then
		local prize = ProgressService.openEgg(player, nil, ProgressService.REVEAL_DELAY)
		if prize and prize.kind == "Weapon" then
			local w = prize :: any
			remote:FireClient(player, "Opened", { kind = "Weapon", id = w.id, name = w.name, new = true })
		elseif prize then
			local h = prize :: any
			remote:FireClient(player, "Opened", { kind = "Hat", id = h.hat.id, name = h.hat.name, rarity = h.hat.rarity, new = h.new })
		else
			sendState(player) -- (no egg after all: the window shows the real count)
		end
	elseif kind == "ClaimGoal" then
		ProgressService.claimGoal(player, arg)
	elseif kind == "Wear" then
		ProgressService.wear(player, arg)
	elseif kind == "Hello" then
		sendState(player)
	elseif kind == "Radio" and type(arg) == "table" then
		-- The radio's choice, kept for the next visit (checked: a switch, an id, a small number).
		local r = arg :: any
		local p = profiles[player]
		if p and type(r.on) == "boolean" and ProgressService.validRadio(r) then
			p.radio = { on = r.on, track = r.track, volume = r.volume }
			scheduleSave(player)
		end
	elseif kind == "Keys" then
		-- The keys this player changed (Controls window), cleaned: known actions, bindable keys.
		local p = profiles[player]
		if p then
			local keys = Keybinds.sanitize(arg)
			p.keys = keys
			scheduleSave(player)
		end
	elseif kind == "Gifts" then
		-- Streamer Mode's gift pairings (checked: eight small whole numbers).
		local p = profiles[player]
		local gifts = ProgressService.cleanGifts(arg)
		if p and gifts then
			p.gifts = gifts
			scheduleSave(player)
		end
	elseif kind == "Settings" then
		-- SETTINGS (round 3, M6), checked: fixed choices only.
		local p = profiles[player]
		local settings = ProgressService.cleanSettings(arg)
		if p and settings then
			p.settings = settings
			scheduleSave(player)
		end
	elseif kind == "Prefs" then
		-- A client script asking, once it listens, for what is kept for it (sent again if loaded).
		ProgressService.sendPrefs(player)
	end
end

------------------------------------------------------------------------------------------------
-- Minigame bests

-- Keeps a score if it beats the player's best for that game. Returns whether it is a new best.
function ProgressService.setBest(player: Player, gameId: string, score: number): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	local best = p.best[gameId] or 0
	if score > best then
		p.best[gameId] = math.floor(score)
		sendState(player)
		scheduleSave(player)
		return true
	end
	return false
end

function ProgressService.best(player: Player, gameId: string): number
	local p = profiles[player]
	return if p then p.best[gameId] or 0 else 0
end

------------------------------------------------------------------------------------------------
-- The boards (round 3, M6: LeaderboardService draws them from what is here)

-- Called when someone's numbers or the players here changed (LeaderboardService sets it).
ProgressService.boardsChanged = nil :: (() -> ())?
local function drawBoards()
	local fn = ProgressService.boardsChanged
	if fn then
		task.spawn(fn)
	end
end

-- Everyone here whose stored profile has been read: (player, takedowns, seconds played). (A
-- player playing on a fresh profile while the store does not answer is left out: a board must
-- never get a session's small number in place of their real one.)
function ProgressService.eachLoaded(fn: (Player, number, number) -> ())
	for player, p in profiles do
		if loaded[player] and not readFailed[player] then
			fn(player, p.takedowns, p.playSeconds)
		end
	end
end

-- Whether the real DataStores are used (not in a Studio test run): the boards go global then.
function ProgressService.usesDataStores(): boolean
	return store ~= nil
end

------------------------------------------------------------------------------------------------

-- What a session played on a fresh profile (while the stored one could not be read) adds to the
-- stored one once it can: takedowns and eggs on top, every hat, the best scores, the hat worn.
-- The profile a player plays with once the store answers: what was stored with this session's
-- play added on top. A first visit (nothing stored) has seen this version's news already.
function ProgressService.joinedProfile(stored: Profile?, session: Profile?): (Profile, boolean)
	local isNew = stored == nil
	local older = stored ~= nil and stored.ladder < LADDER
	local profile: Profile = if session and stored then addOnto(stored, session) elseif stored then stored else (session or fresh())
	if isNew then
		profile.seen = Config.Version -- (a first visit has nothing "new" to be told about)
	end
	if older then
		ProgressService.grandfather(profile, (stored :: Profile).takedowns, (stored :: Profile).eggs, (stored :: Profile).ladder)
	end
	return profile, isNew
end

-- A profile from before the weapon ladder keeps every tool it had then: the old catalog's open
-- ones, and the old kill unlocks its takedowns had reached. Once (it then knows this ladder).
-- Its unopened eggs were found at the old rate (one per 10 takedowns) and held hats: they still do
-- (oldEggs, opened first), so a saved-up pile never opens the whole ladder at once.
-- from: the ladder the stored profile knew (nil: before any, as old profiles were). Round 5 (LADDER
-- 3): Bat, Crowbar and Shove left the starting bar for 2, 4 and 6 takedowns; a profile from before
-- keeps them.
function ProgressService.grandfather(profile: Profile, takedowns: number, eggs: number?, from: number?)
	local was = from or 0
	if was < 2 then
		for _, toy in Toys.list do
			if OLD_TOOLS[toy.id] and toy.unlockAt > 0 and (OLD_UNLOCK[toy.id] or 0) <= takedowns then
				profile.owned[toy.id] = true
			end
		end
		profile.oldEggs = math.max(profile.oldEggs, math.min(eggs or 0, profile.eggs))
	end
	if was < 3 then
		for _, id in ROUND5_STARTERS do
			profile.owned[id] = true
		end
	end
	if was < 4 and (Config :: any).V8_START_BAR then
		for id, oldRung in V8_MOVED do
			if takedowns >= oldRung and Toys.byId[id] then
				profile.owned[id] = true
			end
		end
	end
	profile.ladder = LADDER
end

function addOnto(stored: Profile, session: Profile): Profile
	local m = merge(stored, session)
	m.takedowns = stored.takedowns + session.takedowns
	m.playSeconds = stored.playSeconds + session.playSeconds
	m.eggs = math.min(Progress.MAX_EGGS, stored.eggs + session.eggs)
	m.hat = session.hat or stored.hat
	m.noPranks = stored.noPranks -- (a switch flipped this session is put back on top by onJoin)
	return m
end

-- VIP (MoneyService): an egg every so many takedowns instead of Progress.EGG_EVERY (nil: the usual).
ProgressService.eggEvery = nil :: ((Player) -> number?)?

-- The free ULTRA minutes (MoneyService): once per UTC day. True when today's are claimed now.
function ProgressService.claimFreeDay(player: Player, day: number): boolean
	local p = profiles[player]
	if not p or readFailed[player] or p.freeDay >= day then
		return false
	end
	p.freeDay = day
	scheduleSave(player)
	return true
end

function ProgressService.seenVersion(player: Player): string?
	local p = profiles[player]
	return p and p.seen
end

function ProgressService.setSeenVersion(player: Player, version: string)
	local p = profiles[player]
	if p and p.seen ~= version and #version <= 16 then
		p.seen = version
		scheduleSave(player)
	end
end

-- Whether this is a self-test run in Studio (nothing free starts on its own then).
function ProgressService.isTesting(): boolean
	return RunService:IsStudio() and ServerStorage:GetAttribute("RunSelfTest") == true
end

-- "Friends can prank me" (FriendsService), kept in the profile.
local pendingNoPranks: { [Player]: boolean } = {} -- flipped before any profile existed
function ProgressService.setNoPranks(player: Player, on: boolean)
	local p = profiles[player]
	pranksChanged[player] = true
	if not p then
		pendingNoPranks[player] = on
	elseif p.noPranks ~= on then
		p.noPranks = on
		scheduleSave(player)
	end
end

-- The radio and the keys kept for a player (only once the stored profile is known).
function ProgressService.sendPrefs(player: Player)
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] then
		return
	end
	-- (Always answered: an empty table means "nothing kept", so a first visit's radio starts now.)
	remote:FireClient(player, "Radio", p.radio or {})
	remote:FireClient(player, "Keys", p.keys or {})
	remote:FireClient(player, "Settings", p.settings or {})
	if p.gifts then
		remote:FireClient(player, "Gifts", p.gifts)
	end
end

-- Whether a player's stored profile has been read (false while it loads or cannot be read).
function ProgressService.isLoaded(player: Player): boolean
	return loaded[player] == true and not readFailed[player]
end

-- Runs once a player's stored profile is read (fn(player, isNew): isNew when nothing was stored).
function ProgressService.onLoaded(fn: (Player, boolean) -> ())
	table.insert(loadedHooks, fn)
end

-- The free ULTRA minutes' end, kept so a rejoin keeps what is left (MoneyService).
function ProgressService.freeUntil(player: Player): number
	local p = profiles[player]
	return if p then p.freeUntil else 0
end
function ProgressService.setFreeUntil(player: Player, at: number)
	local p = profiles[player]
	if p then
		p.freeUntil = at
		scheduleSave(player)
	end
end

-- An egg from a game event (round 3, M7: a Christmas present), told to the player. False when the
-- profile is not read yet (nothing to add it to) or the eggs are full.
function ProgressService.giveEgg(player: Player, why: string): boolean
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] or p.eggs >= Progress.MAX_EGGS then
		return false
	end
	p.eggs += 1
	remote:FireClient(player, "Notice", why)
	sendState(player)
	scheduleSave(player)
	return true
end

-- Eggs bought (round 5: the Starter Pack). Never yields. False before the profile is read (the
-- order waits for it). Up to MAX_EGGS, as a weapon order's eggs are.
function ProgressService.addBoughtEggs(player: Player, n: number): boolean
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] then
		return false
	end
	p.eggs = math.min(Progress.MAX_EGGS, p.eggs + n)
	sendState(player)
	scheduleSave(player)
	return true
end

-- Why an egg could not be given now (giveEgg false): "full", "loading" (or nil when it could be).
function ProgressService.eggRoom(player: Player): string?
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] then
		return "loading"
	end
	return if p.eggs >= Progress.MAX_EGGS then "full" else nil
end

-- A short line on the player's screen (the same Notice every system's news uses).
function ProgressService.notice(player: Player, text: string)
	remote:FireClient(player, "Notice", text)
end

local dailyWaitTold: { [Player]: number } = {} -- (the day a full-slots wait was told)
Players.PlayerRemoving:Connect(function(player)
	dailyWaitTold[player] = nil
end)

-- The daily egg: the first visit of a UTC day gives an egg (two on every third day in a row).
function ProgressService.daily(player: Player, today: number?): number
	local p = profiles[player]
	if not p or readFailed[player] then
		return 0
	end
	local day = today or math.floor(os.time() / 86400)
	if p.lastDay >= day then
		return 0
	end
	local streak = if p.lastDay == day - 1 then p.streak + 1 else 1
	-- (V8-3.4, Config.STREAK_V8: one missed day a week is forgiven by a freeze.)
	local froze = false
	if (Config :: any).STREAK_V8 then
		streak, froze = DailyGoals.nextStreak(p.lastDay, p.streak, day, p.freezeWeek or 0)
	end
	local eggs = DailyGoals.streakEggs(streak) -- (the 7-day calendar: 1 1 2 1 1 2 3)
	if p.eggs + eggs > Progress.MAX_EGGS then
		-- (Full slots: the day's eggs wait, the streak with them, and come as soon as there is room:
		-- after an egg is opened, or at the next look; told once a day, never lost.)
		if dailyWaitTold[player] ~= day then
			dailyWaitTold[player] = day
			remote:FireClient(player, "Notice", "Your egg slots are full: open an egg and today's daily egg comes")
		end
		return 0
	end
	p.streak = streak
	p.lastDay = day
	if froze then
		p.freezeWeek = day // 7
		remote:FireClient(player, "Notice", string.format("\u{2744}\u{FE0F} Your weekly STREAK FREEZE saved your %d-day streak!", streak - 1))
	end
	-- (V8-3.4: the visit record and the client read these.)
	player:SetAttribute("Streak", streak)
	player:SetAttribute("DailyClaimed", true)
	-- (Round 5: a named weapon day. Already yours, earned or owned: an extra egg instead.)
	local weaponId = DailyGoals.streakWeapon(streak)
	local weapon = if weaponId then Toys.byId[weaponId] else nil
	local gave: string? = nil
	if weapon then
		if p.owned[weapon.id] or p.takedowns >= weapon.unlockAt then
			eggs = math.min(eggs + 1, Progress.MAX_EGGS - p.eggs)
		else
			p.owned[weapon.id] = true
			gave = weapon.id
			Metrics.event(player, "Daily_Weapon", 1, weapon.id)
			showOwned(player, p)
		end
	end
	p.eggs += eggs
	remote:FireClient(player, "Daily", { streak = p.streak, eggs = eggs, weapon = gave })
	sendState(player)
	scheduleSave(player)
	return eggs
end

-- A session that runs past UTC midnight: the new day's egg and goals now, not on the next join.
-- Returns the daily eggs given (checked with the time played, every PLAY_TICK s).
function ProgressService.checkNewDay(player: Player): number
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] then
		return 0
	end
	if p.lastDay < math.floor(os.time() / 86400) then
		return ProgressService.daily(player)
	elseif p.goals and p.goals.day ~= today() then
		sendState(player)
	end
	return 0
end

-- Round 5, phase 00: the first egg opens by itself (no new player had opened one). A minute into a
-- visit, a player who has never opened an egg (no weapon owned, no hat) gets one if they have none,
-- and the client opens it at once (its WOW weapon goes on the bar). Later eggs use the card as before.
ProgressService.FIRST_EGG_AFTER = math.max(60, Config.QUIET_START + 5) -- (phase 0: after the quiet start)
function ProgressService.neverOpened(player: Player): boolean
	local p = profiles[player]
	return p ~= nil and loaded[player] == true and not readFailed[player] and next(p.owned) == nil and next(p.hats) == nil
end

function ProgressService.firstEgg(player: Player): boolean
	local p = profiles[player]
	if not p or not player.Parent or not ProgressService.neverOpened(player) then
		return false
	end
	if p.eggs <= 0 then
		p.eggs = 1
		scheduleSave(player)
	end
	sendState(player)
	SessionStats.flag(player, "autoEgg")
	remote:FireClient(player, "AutoEgg")
	return true
end

local function onJoin(player: Player)
	playCounted[player] = os.clock() -- (time played counts from here, added once the profile is in)
	local joined = os.clock()
	task.spawn(function()
		task.wait(ProgressService.FIRST_EGG_AFTER)
		-- (The stored profile may still be on its way: a little longer, then it is not this visit.)
		local waited = 0
		while player.Parent and not ProgressService.isLoaded(player) and waited < 60 do
			task.wait(2)
			waited += 2
		end
		if player.Parent and os.clock() - joined >= ProgressService.FIRST_EGG_AFTER then
			ProgressService.firstEgg(player)
		end
	end)
	local testVisit = (require(script.Parent:WaitForChild("TestAccount")) :: any).is(player)
	-- (V8-0.8: a play-as-newcomer visit starts from a blank profile, read as "nothing stored yet".)
	local ok, stored = true, (nil :: any)
	if not testVisit then
		ok, stored = load(player.UserId)
	end
	local told = false
	-- Until Roblox answers, play goes on (a fresh profile, nothing saved over the stored one); the
	-- read is tried again every READ_RETRY_GAP s for as long as the player stays.
	while not ok and player.Parent do
		profiles[player] = profiles[player] or fresh()
		loaded[player] = true
		readFailed[player] = true
		player:SetAttribute("ProgressLoaded", false)
		-- Until the stored "Friends can prank me" is known, nobody can prank this player.
		if not pranksChanged[player] then
			player:SetAttribute("Pranks", false)
		end
		showStats(player)
		if not told then
			told = true
			remote:FireClient(player, "Notice", "Your progress is loading. Keep playing: it will be added once Roblox answers.")
		end
		task.wait(READ_RETRY_GAP)
		ok, stored = load(player.UserId)
	end
	if not player.Parent then
		return
	end
	local session = profiles[player]
	local profile, isNew = ProgressService.joinedProfile(stored, session)
	-- Unlocks this session reached while the store was unreadable were never told: now they are
	-- (those the stored count had passed already are old news).
	if session and readFailed[player] then
		local from = if stored then stored.takedowns else 0
		task.defer(function()
			if player.Parent then
				ProgressService.tellUnlocks(player, from, profile.takedowns)
			end
		end)
	end
	if session and pranksChanged[player] then
		profile.noPranks = session.noPranks -- (flipped while it loaded: that choice stands)
	end
	if pendingNoPranks[player] ~= nil then
		profile.noPranks = pendingNoPranks[player] :: boolean
		pendingNoPranks[player] = nil
	end
	profiles[player] = profile
	eggBase[player] = if stored then stored.eggs else 0 -- (eggs are saved as the change from here)
	if told then
		remote:FireClient(player, "Notice", "Your progress is back!")
	end
	if not pranksChanged[player] then
		player:SetAttribute("Pranks", not profile.noPranks)
	end
	readFailed[player] = not ok or nil
	task.delay(4, function()
		if player.Parent then
			ProgressService.daily(player)
		end
	end)
	loaded[player] = true
	showStats(player)
	-- (The client trusts what is locked only from here, after the real takedowns and owned tools
	-- went out: BarRules.)
	-- Audit area 1 (research: the leaders show a new player almost nothing for 90 s): a player with
	-- under NEWCOMER_SECONDS played in all gets the first-visit flow (FirstVisit on the client).
	-- (Only on a real read: a failed load defaults playSeconds to 0 and must not treat a veteran as new.)
	-- (Nor after a teleport from another of our servers: they have seen the game already.)
	local fromTeleport = false
	pcall(function()
		fromTeleport = player:GetJoinData().SourcePlaceId ~= nil
	end)
	player:SetAttribute("Newcomer", ok == true and not fromTeleport and ((profile.playSeconds or 0) < (Config :: any).NEWCOMER_SECONDS))
	player:SetAttribute("ProgressLoaded", ok == true)
	sendState(player)
	ProgressService.sendPrefs(player)
	for _, fn in loadedHooks do
		task.spawn(fn, player, isNew)
	end
	dressHat(player)
	player.CharacterAppearanceLoaded:Connect(function()
		dressHat(player)
	end)
	drawBoards()
end

-- Whether a player has earned a tool (its takedowns; a test player in Studio may have them all).
-- (`ownedOnly`: the player's own, earned or bought: the free weekend's weapon does not count. The
-- shop asks it this way: a weapon free for the weekend can still be bought to keep.)
function ProgressService.isUnlocked(player: Player, toy: { unlockAt: number, id: string? }, ownedOnly: boolean?): boolean
	if toy.unlockAt <= 0 then
		return true
	end
	if not ownedOnly and toy.id ~= nil and Workspace:GetAttribute("FreeWeapon") == toy.id then
		return true -- (the free weekend, round 3, M9: ScheduleService)
	end
	if not ownedOnly and Workspace:GetAttribute("OwnerParty") == true then
		return true -- (the owner is here and gave everyone every weapon: AdminService; never kept)
	end
	if RunService:IsStudio() and player:GetAttribute("UnlockAll") == true then
		return true
	end
	-- (Round 5: TRY FREE, a few minutes with a locked weapon: TrialService sets these.)
	if not ownedOnly and toy.id ~= nil and player:GetAttribute("TrialWeapon") == toy.id then
		local untilAt = player:GetAttribute("TrialUntil")
		if type(untilAt) == "number" and untilAt > Workspace:GetServerTimeNow() then
			return true
		end
	end
	-- (Release 0.20.0: a Shop.OFFERS pass covers its shelves while owned: OfferService, Offers.covers.)
	if toy.id ~= nil and Offers.covers(player:GetAttribute("PassToys"), Toys.byId[toy.id] and Toys.byId[toy.id].category) then
		return true
	end
	local p = profiles[player]
	return p ~= nil and (p.takedowns >= toy.unlockAt or (toy.id ~= nil and p.owned[toy.id] == true))
end

-- Tests: a player's combo now.
function ProgressService.comboForTest(player: Player): number
	local c = combos[player]
	return if c then c.count else 0
end
function ProgressService.resetComboForTest(player: Player)
	combos[player] = nil
	boostHalf[player] = nil
end

-- Tests: a player's profile (live table).
function ProgressService.profileForTest(player: Player): Profile?
	return profiles[player]
end

-- Tests: what is kept for a player in the memory store.
function ProgressService.storedForTest(player: Player): Profile?
	return memory[player.UserId]
end

-- Tests: the takedown hook itself.
ProgressService.onDownForTest = onDown
ProgressService.onRequest = onRequest
ProgressService.clean = clean
ProgressService.merge = merge
ProgressService.addOntoForTest = function(stored: Profile, session: Profile): Profile
	return addOnto(stored, session)
end
ProgressService.saveOntoForTest = saveOnto
ProgressService.keepUnknownForTest = keepUnknown
function ProgressService.setReadFailedForTest(player: Player, failed: boolean)
	readFailed[player] = failed or nil
end

-- Saves a player's profile now (yields). False when it could not be saved (or never loaded).
function ProgressService.saveNow(player: Player): boolean
	local p = profiles[player]
	if not p or not loaded[player] or readFailed[player] then
		return false
	end
	return save(player, p)
end

-- Tests: the weapons a player owns, set (and shown) as given.
function ProgressService.setOwnedForTest(player: Player, owned: { [string]: boolean })
	local p = profiles[player]
	if p then
		p.owned = table.clone(owned)
		showOwned(player, p)
	end
end

-- Tests: saves now (as when leaving).
-- Tests: a request as if the client sent it (the same checks), and time played as if `seconds` had
-- passed since it was last counted.
function ProgressService.requestForTest(player: Player, kind: unknown, arg: unknown)
	onRequest(player, kind, arg)
end

function ProgressService.countPlayForTest(player: Player, seconds: number): number
	playCounted[player] = os.clock() - seconds
	return countPlay(player)
end

function ProgressService.saveNowForTest(player: Player): boolean
	local p = profiles[player]
	return p ~= nil and save(player, p)
end

function ProgressService.start(labOrigin: Vector3)
	local testing = ServerStorage:GetAttribute("RunSelfTest") == true
	if not RunService:IsStudio() then
		store = DataStoreService:GetDataStore(STORE)
	elseif not testing and ServerStorage:GetAttribute("StudioFresh") ~= true then -- (Studio only: StudioFresh = a brand-new player, never saved)
		local usable = pcall(function()
			DataStoreService:GetDataStore(STORE):GetAsync("probe")
		end)
		if usable then
			store = DataStoreService:GetDataStore(STORE)
		end
	end
	remote = Net.event(Net.Names.Progress)
	remote.OnServerEvent:Connect(onRequest)
	DummyControl.onDown = onDown

	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local p = profiles[player]
		countPlay(player)
		if p and (playUnsaved[player] or 0) > 0 then
			dirty[player] = dirty[player] or 1 -- (the time played this visit is saved on the way out)
		end
		if p and dirty[player] and loaded[player] and not readFailed[player] then
			dirty[player] = nil
			task.spawn(save, player, p)
		elseif p and readFailed[player] and dirty[player] then
			dirty[player] = nil
			task.spawn(saveOnto, player, p) -- (never read: added on top inside the update)
		end
		task.delay(1, function()
			if not player.Parent then
				profiles[player] = nil
				loaded[player] = nil
				readFailed[player] = nil
				window[player] = nil
				dirty[player] = nil
				boostHalf[player] = nil
				combos[player] = nil
				pranksChanged[player] = nil
				eggBase[player] = nil
				dirtySince[player] = nil
				pendingNoPranks[player] = nil
				playCounted[player] = nil
				playUnsaved[player] = nil
				drawBoards()
			end
		end)
	end)
	game:BindToClose(function()
		for player, p in profiles do
			countPlay(player)
			if (playUnsaved[player] or 0) > 0 then
				dirty[player] = dirty[player] or 1
			end
			if dirty[player] and loaded[player] and not readFailed[player] then
				dirty[player] = nil
				task.spawn(save, player, p)
			elseif dirty[player] and readFailed[player] then
				dirty[player] = nil
				task.spawn(saveOnto, player, p)
			end
		end
		local started = os.clock()
		while saving > 0 and os.clock() - started < 25 do
			task.wait(0.2)
		end
	end)
	-- (Studio only, for a look at TODAY: ServerStorage "GoalsDoneForTest" = n counts the first n of
	-- today's goals done for everyone here.)
	if game:GetService("RunService"):IsStudio() then
		local ServerStorageService = game:GetService("ServerStorage")
		ServerStorageService:GetAttributeChangedSignal("GoalsDoneForTest"):Connect(function()
			local n = tonumber(ServerStorageService:GetAttribute("GoalsDoneForTest")) or 0
			for player, p in profiles do
				for i, goal in DailyGoals.forDay(goalsOf(p).day) do
					if i <= n then
						ProgressService.goal(player, goal.kind, goal.need)
					end
				end
			end
		end)
	end
	-- Time played: counted every PLAY_TICK s for everyone here, saved now and then.
	task.spawn(function()
		while true do
			task.wait(PLAY_TICK)
			for player in profiles do
				countPlay(player)
				ProgressService.checkNewDay(player)
				if (playUnsaved[player] or 0) >= PLAY_SAVE_EVERY and loaded[player] and not readFailed[player] then
					playUnsaved[player] = 0
					scheduleSave(player)
				end
			end
		end
	end)
	log.info("progress ready" .. (if store then " (DataStore)" else " (memory)"))
end

-- Phase 2: the player's economy (bolts, journal, daily, codes), nil until the profile is safely
-- read (never counted from zero over a failed read). EconomyService changes it, then ecoChanged.
function ProgressService.ecoOf(player: Player): Economy.Eco?
	local p = profiles[player]
	if not p or loaded[player] ~= true or readFailed[player] then
		return nil
	end
	if not p.eco then
		p.eco = Economy.clean(nil)
	end
	return p.eco
end

function ProgressService.ecoChanged(player: Player)
	local p = profiles[player]
	local e = p and p.eco
	if e then
		player:SetAttribute("Bolts", e.bolts)
		scheduleSave(player)
	end
end

-- Phase 2: whether a weapon is yours (owned, or reached on the ladder).
function ProgressService.isMine(player: Player, id: string): boolean
	local p = profiles[player]
	local toy = Toys.byId[id]
	return p ~= nil and toy ~= nil and (p.owned[id] == true or p.takedowns >= toy.unlockAt or Offers.covers(player:GetAttribute("PassToys"), toy.category))
end

return ProgressService
