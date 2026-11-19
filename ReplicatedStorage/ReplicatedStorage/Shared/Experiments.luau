--!strict
-- Phase 1 (19 Nov 2026): Experiment cards, one short goal at a time ("Fly from the CANNON onto the
-- BULLSEYE"): a goal, a timer and stars. Pure (the server's ExperimentService keeps each player's
-- card and counts; T60 drives it). Every kind is something the server already sees:
--   Takedown  takedowns credited (ProgressService.addTakedowns)
--   Cannon    the lab cannon fired you (Playground)
--   Bullseye  you landed on the bullseye (Playground.watchBullseye)
--   Hazard    the lava, the spikes, the mace or the wrecking ball threw you (Playground.throwOnTouch)
--   Egg       you opened a toy egg (ProgressService)
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
}
Experiments.LIST = table.freeze(LIST)
Experiments.KINDS = table.freeze({ Takedown = true, Cannon = true, Bullseye = true, Hazard = true, Egg = true })

Experiments.byId = {} :: { [string]: Def }
for _, def in LIST do
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
