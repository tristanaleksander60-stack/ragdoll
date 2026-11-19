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

type Player_ = {
	state: Experiments.State?,
	done: number, -- cards finished or skipped this visit
	stars: number, -- this visit
	deck: { Experiments.Def }?, -- phase 2: today's daily cards first
	lastSkip: number,
}

local players: { [Player]: Player_ } = {}
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
