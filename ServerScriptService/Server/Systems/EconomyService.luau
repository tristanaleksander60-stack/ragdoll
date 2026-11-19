--!strict
-- Phase 2 (19 Nov 2026): BOLTS, the BONE JOURNAL, Daily Experiments and like-milestone codes
-- (Shared\Economy; kept in the profile's `eco`, ProgressService). Remote Economy:
--   client Hello / BuyNext / Redeem(code)   server State { bolts, journal, daily, next, price, codes }
-- Daily Experiments: the same Config.DAILY_COUNT cards on every server for the UTC day
-- (Experiments.daily), dealt first; each pays DAILY_BONUS on top. Nothing here is a reward for a
-- like: codes are public and the owner turns them on by hand (Config.LIKE_CODES).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Economy = require(Shared:WaitForChild("Economy"))
local Experiments = require(Shared:WaitForChild("Experiments"))
local Toys = require(Shared:WaitForChild("Toys"))

local ProgressService = require(script.Parent.ProgressService)
local ExperimentService = require(script.Parent.ExperimentService)

local EconomyService = {}

EconomyService.REDEEM_GAP = 2 -- s between code tries
EconomyService.REDEEM_MAX = 10 -- tries a visit

local remote: RemoteEvent? = nil
local tries: { [Player]: { n: number, at: number } } = {}

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
	end)
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
function EconomyService.give(player: Player, n: number, text: string?): boolean
	local e = ProgressService.ecoOf(player)
	if not e or n <= 0 then
		return false
	end
	local times = if player:GetAttribute("DoubleBolts") == true then 2 else 1 -- (Shop.OFFERS DoubleBolts)
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
	end)
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

function EconomyService.redeem(player: Player, code: string): number?
	local now = os.clock()
	local t = tries[player] or { n = 0, at = -math.huge }
	tries[player] = t
	if t.n >= EconomyService.REDEEM_MAX or now - t.at < EconomyService.REDEEM_GAP then
		return nil
	end
	t.n += 1
	t.at = now
	local e = ProgressService.ecoOf(player)
	if not e then
		return nil
	end
	local bolts = Economy.redeem(e, code)
	if bolts then
		EconomyService.give(player, bolts, string.format("Code! +%d BOLTS", bolts))
	end
	return bolts
end

local function loaded(player: Player)
	local e = ProgressService.ecoOf(player)
	if not e then
		return
	end
	Economy.rollDay(e, today())
	player:SetAttribute("Bolts", e.bolts)
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
	end)
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, kind: unknown, arg: unknown)
		if kind == "Hello" then
			EconomyService.send(player)
		elseif kind == "BuyNext" then
			local id = EconomyService.buyNext(player)
			if not id then
				ProgressService.notice(player, "Not enough BOLTS yet. Do experiments!")
			end
		elseif kind == "Redeem" and type(arg) == "string" and #arg <= 24 then
			if not EconomyService.redeem(player, arg) then
				ProgressService.notice(player, "That code does not work (or you used it)")
			end
		end
	end)
end

return EconomyService
