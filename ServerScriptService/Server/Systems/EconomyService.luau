--!strict
-- Phase 2 (19 Nov 2026): BOLTS, the BONE JOURNAL, Daily Experiments and like-milestone codes
-- (Shared\Economy; kept in the profile's `eco`, ProgressService). Remote Economy:
--   client Hello / BuyNext / Redeem(code)   server State { bolts, journal, daily, next, price, codes }
-- Daily Experiments: the same Config.DAILY_COUNT cards on every server for the UTC day
-- (Experiments.daily), dealt first; each pays DAILY_BONUS on top. Nothing here is a reward for a
-- like: codes are public and the owner turns them on by hand (Config.LIKE_CODES).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DoubleEvent = require(Shared:WaitForChild("DoubleEvent")) -- (V9-NOW 12)
local Net = require(Shared:WaitForChild("Net"))
local Economy = require(Shared:WaitForChild("Economy"))
local Experiments = require(Shared:WaitForChild("Experiments"))
local Toys = require(Shared:WaitForChild("Toys"))

local ProgressService = require(script.Parent.ProgressService)
local ExperimentService = require(script.Parent.ExperimentService)

local EconomyService = {}

local remote: RemoteEvent? = nil
local tries: { [Player]: { number } } = {} -- (V9-0t: when each recent code try was)
local perkWatch: { [Player]: RBXScriptConnection } = {} -- (V9-0t: a normal try's end restarts a code's)

local function today(): number
	return os.time() // 86400
end

function EconomyService.dailyToday(): { Experiments.Def }
	local list = Experiments.daily(today(), Config.DAILY_COUNT)
	-- (Phase 3: 1-24 December, with the Christmas theme on, the day's advent card comes first.)
	local date = os.date("!*t")
	if Config.ADVENT and game:GetService("Workspace"):GetAttribute("Christmas") == true and date.month == 12 then
		local advent = Experiments.advent(date.day)
		if advent then
			table.insert(list, 1, advent)
		end
	end
	return list
end

local function state(player: Player): any?
	local e = ProgressService.ecoOf(player)
	if not e then
		return nil
	end
	local journal = {}
	for _, page in Economy.JOURNAL do
		table.insert(journal, { id = page.id, text = page.text, got = e.journal[page.id] == true })
	end
	local daily = {}
	for _, def in EconomyService.dailyToday() do
		table.insert(daily, { id = def.id, text = def.text, done = e.daily[def.id] == true })
	end
	local nextId, price = Economy.nextBuy(Toys.list, function(id: string): boolean
		return ProgressService.isMine(player, id)
	end, ProgressService.takedownsOf(player) or 0) -- (V8-1.4: 5+ KOs away)
	local codes = {}
	for _, entry in Config.LIKE_CODES do
		table.insert(codes, { likes = entry.likes, code = if entry.live then entry.code else "" })
	end
	return { bolts = e.bolts, journal = journal, daily = daily, next = nextId, nextName = nextId and Toys.byId[nextId].label, price = price, codes = codes }
end

function EconomyService.send(player: Player)
	local r = remote
	local s = state(player)
	if r and s and player.Parent then
		r:FireClient(player, "State", s)
	end
end

-- Gives bolts (a reason in a notice). False when the profile is not safely read.
-- `exact`: a bought amount (OfferService), never doubled by 2x BOLTS.
function EconomyService.give(player: Player, n: number, text: string?, exact: boolean?): boolean
	local e = ProgressService.ecoOf(player)
	if not e or n <= 0 then
		return false
	end
	local times = if not exact and player:GetAttribute("DoubleBolts") == true then 2 else 1 -- (Shop.OFFERS DoubleBolts)
	if not exact then
		times *= DoubleEvent.mult((Config :: any).DOUBLE_EVENT, os.time()) -- (V9-NOW 12: the 2X event; stacks with the pass: 4x)
	end
	e.bolts += math.floor(n) * times
	ProgressService.ecoChanged(player)
	if text then
		ProgressService.notice(player, text)
	end
	EconomyService.send(player)
	return true
end

-- Counts what happened into the journal; new pages pay JOURNAL_BOLTS each.
function EconomyService.count(player: Player, kind: string, n: number)
	if not Config.BONE_JOURNAL then
		return -- (23 Nov 2026, owner: no bone journal, no notices about it)
	end
	local e = ProgressService.ecoOf(player)
	if not e then
		return
	end
	local pages = Economy.count(e, kind, n)
	ProgressService.ecoChanged(player)
	for _, page in pages do
		EconomyService.give(player, Config.JOURNAL_BOLTS, string.format("\u{1F4D6} BONE JOURNAL: %s! +%d BOLTS", page.text, Config.JOURNAL_BOLTS))
	end
end

-- An experiment card finished (ExperimentService.onReward).
function EconomyService.experimentDone(player: Player, def: Experiments.Def)
	local e = ProgressService.ecoOf(player)
	if not e then
		return
	end
	Economy.rollDay(e, today())
	local bolts = def.stars * Config.BOLTS_PER_STAR
	local daily = false
	for _, d in EconomyService.dailyToday() do
		if d.id == def.id and not e.daily[def.id] then
			e.daily[def.id] = true
			daily = true
		end
	end
	if daily then
		bolts += Config.DAILY_BONUS
	end
	EconomyService.give(player, bolts, string.format("+%d BOLTS%s", bolts, if daily then " (daily experiment!)" else ""))
	EconomyService.count(player, "Experiment", 1)
	if daily then
		EconomyService.count(player, "Daily", 1)
	end
end

-- The next weapon on the ladder for bolts. Returns the id bought (nil: not enough, nothing left).
function EconomyService.buyNext(player: Player): string?
	local e = ProgressService.ecoOf(player)
	if not e then
		return nil
	end
	local id, price = Economy.nextBuy(Toys.list, function(toyId: string): boolean
		return ProgressService.isMine(player, toyId)
	end, ProgressService.takedownsOf(player) or 0) -- (V8-1.4: the same pick as shown)
	if not id or not price or e.bolts < price then
		return nil
	end
	e.bolts -= price
	if not ProgressService.grantWeapon(player, id, "Bolts") then
		e.bolts += price
		return nil
	end
	ProgressService.ecoChanged(player)
	ProgressService.notice(player, string.format("%s is yours! -%d BOLTS", Toys.byId[id].label, price))
	EconomyService.send(player)
	return id
end

-- Tests: forget a player's recent code tries.
function EconomyService.resetCodesForTest(player: Player)
	tries[player] = nil
end

-- V9-0t: a code from Shared/Codes. Returns whether it worked and the line to show (the reward, or why
-- not). At most Codes.RATE tries a minute; no hint which codes exist; each one once per profile.
EconomyService.REDEEM_WINDOW = 60 -- s
function EconomyService.redeem(player: Player, text: string, nowForTest: number?): (boolean, string)
	local Codes = require(Shared:WaitForChild("Codes")) :: any
	local now = os.clock()
	local list = tries[player] or {}
	tries[player] = list
	while #list > 0 and now - list[1] > EconomyService.REDEEM_WINDOW do
		table.remove(list, 1)
	end
	if #list >= Codes.RATE then
		return false, Codes.MESSAGES.slow
	end
	table.insert(list, now)
	local e = ProgressService.ecoOf(player)
	if not e then
		return false, "Your progress is still loading. Try again in a moment"
	end
	local entry, why = Codes.check(text, e.codes, nowForTest or os.time(), Config.BETA == true)
	if not entry then
		return false, Codes.MESSAGES[why or "invalid"]
	end
	e.codes[entry.code] = true
	local weaponName: string?, cosmeticName: string? = nil, nil
	if entry.bolts then
		EconomyService.give(player, entry.bolts, nil, true) -- (exact: a code is never doubled)
	end
	if entry.trialWeapon then
		local toy = Toys.byId[entry.trialWeapon]
		if toy then
			weaponName = toy.label
			if not ProgressService.isUnlocked(player, toy, true) then
				-- (Kept in eco.perks: it carries on after a rejoin, and waits for a try already running.)
				local key = "Trial:" .. toy.id
				local untilT = Workspace:GetServerTimeNow() + (entry.trialMinutes or 30) * 60
				e.perks[key] = math.max(e.perks[key] or 0, untilT)
			end
		end
	end
	if entry.cosmetic then
		local key = entry.cosmetic :: string
		for _, offer in (require(Shared:WaitForChild("Shop")) :: any).OFFERS do
			if offer.key == key then
				cosmeticName = offer.name
			end
		end
		if player:GetAttribute("Offer_" .. key) ~= true then
			local untilT = Workspace:GetServerTimeNow() + (entry.cosmeticHours or 24) * 3600
			e.perks[key] = math.max(e.perks[key] or 0, untilT)
			player:SetAttribute("Try_" .. key, e.perks[key])
		end
	end
	ProgressService.ecoChanged(player)
	EconomyService.applyPerks(player)
	EconomyService.send(player)
	return true, Codes.describe(entry, weaponName, cosmeticName)
end

-- V9-0t: a code's timed gifts in eco.perks, put on the player (on joining, after a redeem, and when a
-- normal try ends): a cosmetic is MapShopService's Try_<key>; "Trial:<weapon>" is a TrialService try
-- for the time left (only when no other try runs, and only while the weapon is not owned). Ended
-- ones are dropped.
function EconomyService.applyPerks(player: Player)
	local e = ProgressService.ecoOf(player)
	if not e then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local TrialService = require(script.Parent:WaitForChild("TrialService")) :: any
	for key, untilT in e.perks do
		if untilT <= now then
			e.perks[key] = nil
			continue
		end
		local weapon = string.match(key, "^Trial:(.+)$")
		if weapon then
			local toy = Toys.byId[weapon]
			if not toy or ProgressService.isUnlocked(player, toy, true) then
				e.perks[key] = nil
			elseif not TrialService.running(player) then
				TrialService.grant(player, toy.id, untilT - now)
			end
		elseif player:GetAttribute("Offer_" .. key) ~= true then
			player:SetAttribute("Try_" .. key, untilT)
		end
	end
end

local function loaded(player: Player)
	local e = ProgressService.ecoOf(player)
	if not e then
		return
	end
	Economy.rollDay(e, today())
	player:SetAttribute("Bolts", e.bolts)
	-- (V9-0t: a code's timed gifts carry on across visits until they end; a code's weapon try picks up
	-- again when a normal try ends.)
	EconomyService.applyPerks(player)
	if not perkWatch[player] then
		perkWatch[player] = player:GetAttributeChangedSignal("TrialWeapon"):Connect(function()
			if player:GetAttribute("TrialWeapon") == nil then
				EconomyService.applyPerks(player)
			end
		end)
	end
	local deck = {}
	for _, def in EconomyService.dailyToday() do
		if not e.daily[def.id] then
			table.insert(deck, def)
		end
	end
	ExperimentService.setDeck(player, deck)
	EconomyService.send(player)
end

function EconomyService.start()
	remote = Net.event(Net.Names.Economy)
	if not Config.ECONOMY then
		return
	end
	ExperimentService.onReward = EconomyService.experimentDone
	ExperimentService.onEvent = EconomyService.count
	ProgressService.onLoaded(function(player: Player, _first: boolean)
		loaded(player)
	end)
	for _, player in Players:GetPlayers() do
		if ProgressService.isLoaded(player) then
			task.spawn(loaded, player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		tries[player] = nil
		local watch = perkWatch[player]
		if watch then
			watch:Disconnect()
			perkWatch[player] = nil
		end
	end)
	-- lihfolk-ignore: remote-unvalidated-args (kind is only compared with fixed strings; arg is type- and length-checked)
	-- (AUDIT 27 Nov 7: a token bucket per player: 4 calls a second at most, a burst of 8; the rest is dropped and counted)
	local bucket: { [Player]: { n: number, t: number } } = setmetatable({}, { __mode = "k" }) :: any
	local dropped = 0
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, kind: unknown, arg: unknown)
		local now = os.clock()
		local bk = bucket[player] or { n = 8, t = now }
		bk.n = math.min(8, bk.n + (now - bk.t) * 4)
		bk.t = now
		bucket[player] = bk
		if bk.n < 1 or typeof(kind) ~= "string" then
			dropped += 1
			if dropped % 50 == 1 then
				warn("[Economy] dropped " .. dropped .. " requests over the limit (last: " .. player.Name .. ")")
			end
			return
		end
		bk.n -= 1
		if kind == "Hello" then
			EconomyService.send(player)
		elseif kind == "BuyNext" then
			local id = EconomyService.buyNext(player)
			if not id then
				ProgressService.notice(player, "Not enough BOLTS yet. Do experiments!")
			end
		elseif kind == "Redeem" and type(arg) == "string" and #arg <= 40 then
			local ok, line = EconomyService.redeem(player, arg)
			;(remote :: RemoteEvent):FireClient(player, "Code", { ok = ok, text = line })
		end
	end)
end

return EconomyService
