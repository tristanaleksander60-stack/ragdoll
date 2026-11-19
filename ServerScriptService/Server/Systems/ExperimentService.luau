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

-- Deals the next card (today's deck first, then the list) and tells the client.
function ExperimentService.deal(player: Player): Experiments.Def?
	local p = players[player]
	if not p then
		return nil
	end
	local def: Experiments.Def
	local deck = p.deck
	if deck and #deck > 0 then
		def = table.remove(deck, 1) :: Experiments.Def
	else
		def = Experiments.nextFor(p.done)
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
	if result == "done" then
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

-- Something a card may count happened (kind: Shared\Experiments.KINDS).
function ExperimentService.event(player: Player, kind: string, n: number?)
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
	local function joined(player: Player)
		ExperimentService.join(player)
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
	end)
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, kind: unknown)
		local p = players[player]
		if not p or kind ~= "Skip" then
			return
		end
		local now = os.clock()
		if now - p.lastSkip < ExperimentService.SKIP_GAP then
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
		end
	end)
end

return ExperimentService
