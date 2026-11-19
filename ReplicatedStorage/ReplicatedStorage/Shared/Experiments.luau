--!strict
-- Phase 1 (19 Nov 2026): Experiment cards, one short goal at a time ("Fly from the CANNON onto the
-- BULLSEYE"): a goal, a timer and stars. Pure (the server's ExperimentService keeps each player's
-- card and counts; T60 drives it). Every kind is something the server already sees:
--   Takedown  takedowns credited (ProgressService.addTakedowns)
--   Cannon    the lab cannon fired you (Playground)
--   Bullseye  you landed on the bullseye (Playground.watchBullseye)
--   Hazard    the lava, the spikes, the mace or the wrecking ball threw you (Playground.throwOnTouch)
--   Egg       you opened a toy egg (ProgressService)
--   Toss      a friend you threw landed in the cannon, a station, the bullseye or a trap (release
--             0.20: a TOSS COMBO, ExperimentService.thrown; Prank Party cards only)
-- Phase 2 adds Daily Experiments: Experiments.daily picks the same three on every server each day.

local Experiments = {}

export type Def = {
	id: string,
	text: string, -- one line
	kind: string,
	target: number,
	seconds: number, -- the timer
	stars: number, -- the reward
}

local LIST: { Def } = {
	{ id = "Takedown3", text = "Take down 3 dummies", kind = "Takedown", target = 3, seconds = 60, stars = 1 },
	{ id = "Cannon", text = "Blast off the CANNON", kind = "Cannon", target = 1, seconds = 90, stars = 1 },
	{ id = "Lava", text = "Jump in the LAVA or hit the SPIKES", kind = "Hazard", target = 1, seconds = 90, stars = 1 },
	{ id = "Bullseye", text = "Fly from the CANNON onto the BULLSEYE", kind = "Bullseye", target = 1, seconds = 120, stars = 2 },
	{ id = "Takedown10", text = "Take down 10 dummies", kind = "Takedown", target = 10, seconds = 120, stars = 2 },
	{ id = "Egg", text = "Open a toy egg", kind = "Egg", target = 1, seconds = 120, stars = 1 },
	{ id = "Hazard3", text = "Get thrown by 3 traps", kind = "Hazard", target = 3, seconds = 120, stars = 2 },
	{ id = "Takedown25", text = "Take down 25 dummies", kind = "Takedown", target = 25, seconds = 240, stars = 3 },
	{ id = "Bullseye2", text = "Land on the BULLSEYE twice", kind = "Bullseye", target = 2, seconds = 240, stars = 3 },
	{ id = "Cannon3", text = "Blast off the CANNON 3 times", kind = "Cannon", target = 3, seconds = 150, stars = 2 },
	-- v3 phase C: the throw tower in your lab and the launchers on the open-air maps.
	{ id = "Tower", text = "Jump off the THROW TOWER", kind = "Tower", target = 1, seconds = 120, stars = 1 },
	{ id = "MapLaunch", text = "Get launched on any MAP", kind = "Map", target = 1, seconds = 240, stars = 2 },
}
Experiments.LIST = table.freeze(LIST)
Experiments.KINDS = table.freeze({ Takedown = true, Cannon = true, Bullseye = true, Hazard = true, Egg = true, Chimney = true, Present = true, Toss = true, Tower = true, Map = true })

-- Phase 3: Prank Party (2-6 players in one lab): one shared card, everyone's events count, everyone
-- gets the stars (ExperimentService.startParty; PartyService deals it).
Experiments.PARTY = table.freeze({
	{ id = "PartyDown", text = "TOGETHER: take down 15 dummies", kind = "Takedown", target = 15, seconds = 120, stars = 2 },
	{ id = "PartyCannon", text = "TOGETHER: 5 cannon shots", kind = "Cannon", target = 5, seconds = 120, stars = 2 },
	{ id = "PartyTraps", text = "TOGETHER: get thrown by 6 traps", kind = "Hazard", target = 6, seconds = 150, stars = 2 },
	-- (Release 0.20, Config.PARTY_THROWS: grab a friend, throw them into the cannon, a station or a
	-- trap: each TOSS COMBO counts. PartyService skips it with PARTY_THROWS off.)
	{ id = "PartyToss", text = "TOGETHER: toss friends into 3 traps", kind = "Toss", target = 3, seconds = 180, stars = 3 },
} :: { Def })

-- Phase 3: the daily advent experiment, 1-24 December (Christmas lab: CHIMNEY launcher and the
-- PRESENT trap). Kinds go round so every day differs from the day before.
local ADVENT_KINDS: { { any } } = {
	{ "Chimney", "Go up the CHIMNEY", 1 },
	{ "Present", "Open the PRESENT trap", 1 },
	{ "Takedown", "Take down 12 dummies", 12 },
	{ "Cannon", "Blast off the CANNON twice", 2 },
	{ "Bullseye", "Land on the BULLSEYE", 1 },
	{ "Chimney", "Go up the CHIMNEY 3 times", 3 },
}
function Experiments.advent(day: number): Def?
	if day < 1 or day > 24 then
		return nil
	end
	local k = ADVENT_KINDS[((day - 1) % #ADVENT_KINDS) + 1]
	return {
		id = "Advent" .. day,
		text = string.format("\u{1F381} Day %d: %s", day, k[2]),
		kind = k[1] :: string,
		target = k[3] :: number,
		seconds = 300,
		stars = 3,
	}
end

Experiments.byId = {} :: { [string]: Def }
for _, def in LIST do
	Experiments.byId[def.id] = def
end
for _, def in Experiments.PARTY do
	Experiments.byId[def.id] = def
end

-- The card after `done` finished (or skipped) ones this visit: the list in order, then round again.
function Experiments.nextFor(done: number): Def
	return LIST[(done % #LIST) + 1]
end

export type State = { def: Def, count: number, startedAt: number }

-- Counts one event into a card. Returns "done" when this finished it, "late" when its time ran
-- out, nil otherwise (other kinds are ignored).
function Experiments.step(state: State, kind: string, n: number, now: number): string?
	if now - state.startedAt > state.def.seconds then
		return "late"
	end
	if kind ~= state.def.kind or n <= 0 then
		return nil
	end
	state.count = math.min(state.def.target, state.count + n)
	return if state.count >= state.def.target then "done" else nil
end

-- Phase 2 (Daily Experiments): the same `n` cards on every server for one UTC day (day = os.time()
-- // 86400). A seeded shuffle, no repeats.
function Experiments.daily(day: number, n: number): { Def }
	local rng = Random.new(day * 7919 + 13)
	local pool = table.clone(LIST)
	local out = {}
	for _ = 1, math.min(n, #pool) do
		table.insert(out, table.remove(pool, rng:NextInteger(1, #pool)) :: Def)
	end
	return out
end

return Experiments
