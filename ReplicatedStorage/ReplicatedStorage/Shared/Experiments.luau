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
	{ id = "Lava", text = "Jump in the LAVA or ride the WRECKING BALL", kind = "Hazard", target = 1, seconds = 90, stars = 1 },
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
	-- V6-5: the creature yard in front of the lab (Server/Systems/LabCreatures).
	{ id = "Spider", text = "FEED THE SPIDER a dummy", kind = "Spider", target = 1, seconds = 120, stars = 1 },
	{ id = "Plant", text = "Let the GIANT PLANT chomp a dummy", kind = "Plant", target = 1, seconds = 120, stars = 1 },
	{ id = "Frog", text = "Bring a dummy near the FROG", kind = "Frog", target = 1, seconds = 120, stars = 1 },
	{ id = "Whale", text = "Throw a dummy in the WHALE pool", kind = "Whale", target = 1, seconds = 120, stars = 1 },
	{ id = "Chicken", text = "Put a dummy in the CHICKEN coop", kind = "Chicken", target = 1, seconds = 120, stars = 1 },
	{ id = "Washer", text = "Spin a dummy in the WASHING MACHINE", kind = "Washer", target = 1, seconds = 120, stars = 1 },
	{ id = "Slingshot", text = "Fire a dummy from the SLINGSHOT TREE", kind = "Slingshot", target = 1, seconds = 120, stars = 1 },
	{ id = "Mole", text = "Let the MOLE pop a dummy", kind = "Mole", target = 1, seconds = 150, stars = 1 },
	{ id = "Vacuum", text = "Let the ROBOT VACUUM suck up a dummy", kind = "Vacuum", target = 1, seconds = 150, stars = 1 },
}
-- V9-NOW 17 / V9-0ae (Config.BULLSEYE false): no card asks for the bullseye.
local NO_BULLSEYE = (require(script.Parent:WaitForChild("Config")) :: any).BULLSEYE == false
if NO_BULLSEYE then
	for i = #LIST, 1, -1 do
		if LIST[i].kind == "Bullseye" then
			table.remove(LIST, i)
		end
	end
end
Experiments.LIST = table.freeze(LIST)
Experiments.KINDS = table.freeze({ Takedown = true, Cannon = true, Bullseye = true, Hazard = true, Egg = true, Chimney = true, Present = true, Toss = true, Tower = true, Map = true, Spider = true, Plant = true, Frog = true, Whale = true, Chicken = true, Washer = true, Slingshot = true, Mole = true, Vacuum = true,
	-- (V8-1.3: the mission chain's own: a tool used, the wrecking ball, CRASH points.)
	["Tool:Bat"] = true, ["Tool:Grenade"] = true, Wrecking = true, Crash = true })

-- V8-1.3 (Config.MISSION_CHAIN): the first missions, always in this order, one card at a time, no
-- timer (SKIP from SKIP_AFTER s), each paying its stars (BOLTS through ExperimentService.onReward).
-- The position is kept for every visit (ExperimentService, DataStore Missions_v1).
Experiments.NO_TIMER = 1e9
Experiments.SKIP_AFTER = 60 -- s a chain card stays before it may be skipped
Experiments.CHAIN = table.freeze({
	{ id = "Chain1", text = "KO a dummy", kind = "Takedown", target = 1, seconds = Experiments.NO_TIMER, stars = 1 },
	{ id = "Chain2", text = "Swing the BAT", kind = "Tool:Bat", target = 1, seconds = Experiments.NO_TIMER, stars = 1 },
	{ id = "Chain3", text = "Fire the CANNON", kind = "Cannon", target = 1, seconds = Experiments.NO_TIMER, stars = 1 },
	-- (V9-NOW 17: with the bullseye gone, the 4th mission is the lava; the id stays, so saved places are kept.)
	if NO_BULLSEYE then { id = "Chain4", text = "Jump in the LAVA", kind = "Hazard", target = 1, seconds = Experiments.NO_TIMER, stars = 2 }
		else { id = "Chain4", text = "Hit the BULLSEYE", kind = "Bullseye", target = 1, seconds = Experiments.NO_TIMER, stars = 2 },
	{ id = "Chain5", text = "Throw the GRENADE", kind = "Tool:Grenade", target = 1, seconds = Experiments.NO_TIMER, stars = 1 },
	{ id = "Chain6", text = "Ride the WRECKING BALL", kind = "Wrecking", target = 1, seconds = Experiments.NO_TIMER, stars = 2 },
	{ id = "Chain7", text = "Get 10 KOs", kind = "Takedown", target = 10, seconds = Experiments.NO_TIMER, stars = 2 },
	{ id = "Chain8", text = "Score 2,000 CRASH", kind = "Crash", target = 2000, seconds = Experiments.NO_TIMER, stars = 3 },
} :: { Def })
-- Cards about a creature or a map: never for a newcomer (they have not met them yet).
Experiments.SEEN_FIRST = table.freeze({ Spider = true, Plant = true, Frog = true, Whale = true, Chicken = true, Washer = true, Slingshot = true, Mole = true, Vacuum = true, Map = true, Tower = true }) :: { [string]: boolean }

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
	if NO_BULLSEYE then { "Cannon", "Blast off the CANNON 3 times", 3 } else { "Bullseye", "Land on the BULLSEYE", 1 },
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
