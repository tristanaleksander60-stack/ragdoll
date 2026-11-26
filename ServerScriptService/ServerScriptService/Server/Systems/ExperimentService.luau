--!strict
-- Phase 1 (19 Nov 2026): Experiment cards. Each player has one card at a time (Shared\Experiments):
-- a one-line goal, a timer, stars. The server counts what it already sees (ExperimentService.event,
-- called from ProgressService and Playground) and tells the client (remote Experiment):
--   Card  { id, text, target, count, seconds, left }   Done { id, stars, total }   Late { id }
-- The client may only ask to Skip (a new card, at most every SKIP_GAP s). Stars are the reward;
-- ExperimentService.onReward (set by Main) turns them into more (phase 2: Bolts). A leaf module: it
-- requires no other system, so any system may count into it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Experiments = require(Shared:WaitForChild("Experiments"))

local ExperimentService = {}

ExperimentService.NEXT_AFTER = 4 -- s between a finished card and the next
ExperimentService.SKIP_GAP = 3
ExperimentService.onReward = nil :: ((player: Player, def: Experiments.Def) -> ())?
-- Phase 2: every event, card or not (EconomyService counts them into the BONE JOURNAL).
ExperimentService.onEvent = nil :: ((player: Player, kind: string, n: number) -> ())?

type Player_ = {
	state: Experiments.State?,
	done: number, -- cards finished or skipped this visit
	stars: number, -- this visit
	deck: { Experiments.Def }?, -- phase 2: today's daily cards first
	lastSkip: number,
}

local players: { [Player]: Player_ } = {}
-- Release 0.20 (throw your friend): who threw whom, and when (PlayerGrab.throw), and each thrower's
-- run of combos.
local tossed: { [Player]: { by: Player, at: number } } = {}
local chains: { [Player]: { n: number, at: number } } = {}
-- Where a thrown friend may land for a TOSS COMBO, and how the pop names it.
ExperimentService.COMBO_KINDS = table.freeze({ Cannon = "the CANNON", Bullseye = "the BULLSEYE", Hazard = "a TRAP", Chimney = "the CHIMNEY", Present = "the PRESENT" }) :: { [string]: string }
-- Phase 3: Prank Party cards, by the lab owner; partyOf: a member's owner.
type Party = { state: Experiments.State, members: { Player } }
local parties: { [Player]: Party } = {}
local partyOf: { [Player]: Player } = {}
local remote: RemoteEvent? = nil

local function send(player: Player, kind: string, data: any)
	local r = remote
	if r and player.Parent then
		r:FireClient(player, kind, data)
	end
end

local function cardData(s: Experiments.State, now: number): any
	return {
		id = s.def.id,
		text = s.def.text,
		target = s.def.target,
		count = s.count,
		seconds = s.def.seconds,
		left = math.max(0, math.floor(s.def.seconds - (now - s.startedAt))),
		stars = s.def.stars,
	}
end

-- V8-1.3 (Config.MISSION_CHAIN): each player's place in Experiments.CHAIN, kept for every visit in
-- DataStore Missions_v1 (UpdateAsync, only ever forward; memory in Studio and for test visits).
local chainAt: { [Player]: number } = {}
local missionStore: DataStore? = nil
local function chainOn(): boolean
	return (Config :: any).MISSION_CHAIN == true
end
local function isChain(def: Experiments.Def): boolean
	return string.sub(def.id, 1, 5) == "Chain"
end
local function testVisit(player: Player): boolean
	return (require(script.Parent:WaitForChild("TestAccount")) :: any).is(player)
end
local function saveChain(player: Player, at: number)
	local ds = missionStore
	if not ds or testVisit(player) then
		return
	end
	task.spawn(function()
		pcall(function()
			ds:UpdateAsync(tostring(player.UserId), function(old: unknown)
				if type(old) == "number" and old >= at then
					return nil
				end
				return at, { player.UserId }
			end)
		end)
	end)
end
local function loadChain(player: Player)
	local ds = missionStore
	if not ds or testVisit(player) then
		chainAt[player] = chainAt[player] or 0
		return
	end
	local ok, value = pcall(function()
		return ds:GetAsync(tostring(player.UserId))
	end)
	chainAt[player] = if ok and type(value) == "number" then math.clamp(math.floor(value), 0, #Experiments.CHAIN) else 0
end
-- Tests: a player's place in the chain (and set it).
function ExperimentService.chainOf(player: Player): number
	return chainAt[player] or 0
end
function ExperimentService.setChainForTest(player: Player, at: number)
	chainAt[player] = at
end

-- Deals the next card (today's deck first, then the list) and tells the client.
function ExperimentService.deal(player: Player): Experiments.Def?
	local p = players[player]
	if not p then
		return nil
	end
	local def: Experiments.Def
	local deck = p.deck
	local at = chainAt[player] or 0
	if chainOn() and at < #Experiments.CHAIN then
		def = Experiments.CHAIN[at + 1]
	elseif deck and #deck > 0 then
		def = table.remove(deck, 1) :: Experiments.Def
	else
		def = Experiments.nextFor(p.done)
	end
	-- (V8-1.3: never a creature or map card for a newcomer: they have not met it yet.)
	if chainOn() and not isChain(def) and player:GetAttribute("Newcomer") == true then
		local tries = 0
		while Experiments.SEEN_FIRST[def.kind] and tries < #Experiments.LIST do
			tries += 1
			p.done += 1
			def = Experiments.nextFor(p.done)
		end
	end
	local now = os.clock()
	local s: Experiments.State = { def = def, count = 0, startedAt = now }
	p.state = s
	send(player, "Card", cardData(s, now))
	return def
end

local function finish(player: Player, p: Player_, result: string)
	local s = p.state
	if not s then
		return
	end
	p.state = nil
	p.done += 1
	-- (V8-1.3: a chain card done, or skipped after SKIP_AFTER s, moves the chain on, for good.)
	if chainOn() and isChain(s.def) then
		local at = math.min(#Experiments.CHAIN, (chainAt[player] or 0) + 1)
		chainAt[player] = at
		saveChain(player, at)
	end
	if result == "done" then
		pcall(function()
			(require(script.Parent:WaitForChild("SessionStats")) :: any).mark(player, "firstMissionDoneAt")
		end)
		p.stars += s.def.stars
		player:SetAttribute("Stars", ((player:GetAttribute("Stars") :: number?) or 0) + s.def.stars)
		send(player, "Done", { id = s.def.id, stars = s.def.stars, total = p.stars })
		local reward = ExperimentService.onReward
		if reward then
			task.spawn(reward, player, s.def)
		end
	else
		send(player, "Late", { id = s.def.id })
	end
	task.delay(ExperimentService.NEXT_AFTER, function()
		if players[player] == p and p.state == nil then
			ExperimentService.deal(player)
		end
	end)
end

-- Release 0.20: `held` was just thrown by `by` (PlayerGrab). Landing somewhere in COMBO_KINDS within
-- Config.THROW_COMBO_WINDOW s is a TOSS COMBO.
function ExperimentService.thrown(held: Player, by: Player)
	if Config.EXPERIMENTS and held.Parent and by.Parent then
		tossed[held] = { by = by, at = os.clock() }
	end
end

-- A thrown player landed in `kind` (named `what` on the pop, e.g. "the LAVA"): the combo pop for both
-- and one "Toss" for the thrower (their card, their party's card, the journal). Returns the combo
-- count (nil: no combo).
local function tossCombo(held: Player, kind: string, what: string?): number?
	local t = tossed[held]
	if not t then
		return nil
	end
	tossed[held] = nil
	local by = t.by
	local now = os.clock()
	if now - t.at > Config.THROW_COMBO_WINDOW or not by.Parent then
		return nil
	end
	local last = chains[by]
	local c: { n: number, at: number } = if last and now - last.at <= Config.THROW_COMBO_CHAIN
		then { n = last.n + 1, at = now }
		else { n = 1, at = now }
	chains[by] = c
	local where = what or ExperimentService.COMBO_KINDS[kind] or "a TRAP"
	local times = if c.n > 1 then string.format(" x%d", c.n) else ""
	send(by, "Combo", { text = string.format("TOSS COMBO%s! %s into %s", times, held.DisplayName, where), n = c.n })
	if held ~= by then
		send(held, "Combo", { text = string.format("%s tossed you into %s!", by.DisplayName, where), n = c.n })
	end
	ExperimentService.event(by, "Toss", 1)
	return c.n
end
ExperimentService.tossComboForTest = tossCombo

-- Something a card may count happened (kind: Shared\Experiments.KINDS). `what` names the place for
-- a TOSS COMBO pop ("the LAVA"; release 0.20).
function ExperimentService.event(player: Player, kind: string, n: number?, what: string?)
	-- (V8-0.8: the first use of each machine and creature this visit, for the visit record.)
	pcall(function()
		local SessionStats = require(script.Parent:WaitForChild("SessionStats")) :: any
		SessionStats.used(player, kind)
		if kind == "Cannon" then
			SessionStats.mark(player, "firstLaunchAt")
		end
	end)
	-- (V8-0.4: the hazard tip is never shown for a hazard already tried.)
	if kind == "Hazard" and player:GetAttribute("HazardDone") ~= true then
		player:SetAttribute("HazardDone", true)
	end
	if tossed[player] and ExperimentService.COMBO_KINDS[kind] then
		tossCombo(player, kind, what)
	end
	local hook = ExperimentService.onEvent
	if hook then
		task.spawn(hook, player, kind, n or 1)
	end
	local owner = partyOf[player]
	if owner then
		ExperimentService.partyEvent(owner, kind, n or 1)
	end
	local p = players[player]
	local s = p and p.state
	if not p or not s then
		return
	end
	local result = Experiments.step(s, kind, n or 1, os.clock())
	if result then
		finish(player, p, result)
	elseif kind == s.def.kind then
		send(player, "Card", cardData(s, os.clock()))
	end
end

-- Phase 3 (Prank Party): one card for everyone in a lab. Ends the owner's party first if one runs.
function ExperimentService.startParty(owner: Player, members: { Player }, def: Experiments.Def)
	ExperimentService.endParty(owner)
	local party: Party = { state = { def = def, count = 0, startedAt = os.clock() }, members = table.clone(members) }
	parties[owner] = party
	for _, m in members do
		partyOf[m] = owner
		m:SetAttribute("PartyLab", owner.UserId) -- (release 0.20: party members may toss each other here: Zones.mayGrab)
		send(m, "Party", cardData(party.state, os.clock()))
	end
end

function ExperimentService.endParty(owner: Player)
	local party = parties[owner]
	if not party then
		return
	end
	parties[owner] = nil
	for _, m in party.members do
		if partyOf[m] == owner then
			partyOf[m] = nil
			if m.Parent then
				m:SetAttribute("PartyLab", nil)
			end
		end
		send(m, "PartyEnd", {})
	end
end

function ExperimentService.partyEvent(owner: Player, kind: string, n: number)
	local party = parties[owner]
	if not party then
		return
	end
	local result = Experiments.step(party.state, kind, n, os.clock())
	if result == "done" then
		local def = party.state.def
		for _, m in party.members do
			local p = players[m]
			if p and m.Parent then
				p.stars += def.stars
				m:SetAttribute("Stars", ((m:GetAttribute("Stars") :: number?) or 0) + def.stars)
				send(m, "Done", { id = def.id, stars = def.stars, total = p.stars, party = true })
				local reward = ExperimentService.onReward
				if reward then
					task.spawn(reward, m, def)
				end
			end
		end
		ExperimentService.endParty(owner)
	elseif result == "late" then
		ExperimentService.endParty(owner)
	elseif kind == party.state.def.kind then
		for _, m in party.members do
			send(m, "Party", cardData(party.state, os.clock()))
		end
	end
end

-- Tests / PartyService: the owner's party (nil: none).
function ExperimentService.partyOf(owner: Player): Party?
	return parties[owner]
end

-- Phase 2: cards to deal first (today's Daily Experiments).
function ExperimentService.setDeck(player: Player, deck: { Experiments.Def })
	local p = players[player]
	if p then
		p.deck = table.clone(deck)
	end
end

-- Tests: the player's card and visit stars.
function ExperimentService.stateOf(player: Player): (Experiments.State?, number)
	local p = players[player]
	return if p then p.state else nil, if p then p.stars else 0
end

function ExperimentService.join(player: Player)
	if players[player] then
		return
	end
	players[player] = { state = nil, done = 0, stars = 0, lastSkip = -math.huge }
end

function ExperimentService.start()
	remote = Net.event(Net.Names.Experiment)
	if not Config.EXPERIMENTS then
		return
	end
	if chainOn() and not game:GetService("RunService"):IsStudio() then
		local ok, result = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore("Missions_v1")
		end)
		if ok then
			missionStore = result
		end
	end
	local function joined(player: Player)
		ExperimentService.join(player)
		if chainOn() then
			task.spawn(loadChain, player)
		end
		task.delay(Config.EXPERIMENT_FIRST_AT, function()
			local p = players[player]
			if p and p.state == nil and p.done == 0 then
				ExperimentService.deal(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(joined)
	for _, player in Players:GetPlayers() do
		joined(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		players[player] = nil
		ExperimentService.endParty(player)
		partyOf[player] = nil
		tossed[player] = nil
		chains[player] = nil
		chainAt[player] = nil
	end)
	-- lihfolk-ignore: remote-unvalidated-args (kind is only compared with "Skip"; nothing else is read)
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, kind: unknown)
		local p = players[player]
		if not p or kind ~= "Skip" then
			return
		end
		local now = os.clock()
		if now - p.lastSkip < ExperimentService.SKIP_GAP then
			return
		end
		-- (V8-1.3: a mission has no timer and may be skipped only after SKIP_AFTER s.)
		local s = p.state
		if chainOn() and s and now - s.startedAt < Experiments.SKIP_AFTER then
			send(player, "SkipLater", { left = math.ceil(Experiments.SKIP_AFTER - (now - s.startedAt)) })
			return
		end
		p.lastSkip = now
		finish(player, p, "late")
	end)
	-- The timers: a card whose time ran out ends.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for player, p in players do
				local s = p.state
				if s and now - s.startedAt > s.def.seconds then
					finish(player, p, "late")
				end
			end
			-- (Release fix: a party card whose time ran out with nobody scoring stayed up for good,
			-- and no new one could be dealt in that lab.)
			for owner, party in parties do
				if now - party.state.startedAt > party.state.def.seconds then
					ExperimentService.endParty(owner)
				end
			end
		end
	end)
end

return ExperimentService
