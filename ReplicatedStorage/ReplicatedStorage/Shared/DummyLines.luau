--!strict
-- LOOK_V3 (19 Nov 2026): what a dummy says. Pure lists and a picker, so a test can read them.
-- Three kinds, drawn by DummyLife in a small black box over the head:
--   Fear: a gun points at it (its hands go up), yellow text.
--   Ouch: it just got up again after a fall, yellow text.
--   Idle: chatter now and then while it stands about, white text.
-- Our own lines, all kid-friendly (no threats, no gore words).

local DummyLines = {}

DummyLines.FEAR = table.freeze({
	"Easy with that thing!",
	"I'm only a test dummy!",
	"Not the face!",
	"Can we talk about this?",
	"Aim at the other guy!",
	"Nope, nope, nope!",
	"This was not in my contract!",
	"Is that thing loaded?",
	"I bruise easily!",
	"Put it down, please!",
})

DummyLines.OUCH = table.freeze({
	"Ouch!",
	"Again?!",
	"I felt that one.",
	"Best. Flight. Ever.",
	"My bolts!",
	"Rude!",
	"Ten out of ten landing.",
	"Who turned the floor on?",
})

DummyLines.IDLE = table.freeze({
	"Is it lunch yet?",
	"Do my bolts look loose?",
	"Today feels like a cannon day.",
	"I wish I had a dog.",
	"Bet I fly further than you.",
	"I could really go for a nap.",
	"Who left the tank there?",
	"New record: zero launches today!",
	"Nice weather for a crash test.",
	"I used to model jackets, you know.",
	"Does anyone else hear the cannon?",
	"Hello? Anybody?",
})

-- v4 B2 (owner: "they talk about where they are"): idle chatter per place (the body's Zone
-- attribute, CrowdService). Short, kid-safe, about the place and what they do there.
DummyLines.PLACE = table.freeze({
	Plaza = table.freeze({
		"Has anyone seen the fountain work?",
		"Those labs are so loud today.",
		"I'm just here for the hot cocoa.",
		"Who keeps launching people over the fence?",
		"Meet you by the big tree!",
		"Is the arena open yet?",
	}),
	Island = table.freeze({
		"Sunscreen? Anyone? Anyone?",
		"The water is perfect today.",
		"Don't go near the catapult!",
		"I saw someone dive off the cliff!",
		"This sand gets everywhere.",
		"Is that the lighthouse beeping?",
		"I'm building the biggest sandcastle.",
		"Coconut, anyone?",
	}),
	City = table.freeze({
		"Has anyone seen the 8:15 bus?",
		"Late for work. Again.",
		"That manhole just shot a guy up!",
		"Coffee first, then meetings.",
		"Watch out, the light is red!",
		"I parked right here. I think.",
		"These towers are so tall.",
		"Taxi! TAXI!",
	}),
	Site = table.freeze({
		"Hard hats on, people!",
		"Who moved my wheelbarrow?",
		"That crane is not a ride!",
		"Lunch break in five.",
		"Mind the pit!",
		"Another day, another wall.",
		"Did someone order more bricks?",
	}),
	Farm = table.freeze({
		"The bison are grumpy today.",
		"Who left the gate open?",
		"Hay bales don't stack themselves.",
		"The tractor won't start again.",
		"Fresh eggs this morning!",
		"Stay out of the paddock!",
		"Smells like rain. And bison.",
	}),
	Military = table.freeze({
		"Left, right, left, right!",
		"Nobody touches the tanks.",
		"Range is hot! Stay back!",
		"Ten more laps of the course.",
		"Is that a mortar or a trampoline?",
		"At ease, everyone.",
		"Helipad is clear!",
	}),
})

-- The idle list for a body in `zone` (the generic one in the labs and anywhere unknown).
function DummyLines.idleFor(zone: unknown): { string }
	local list = if type(zone) == "string" then DummyLines.PLACE[zone] else nil
	return list or DummyLines.IDLE
end

DummyLines.FEAR_COLOR = Color3.fromRGB(255, 205, 64)
DummyLines.IDLE_COLOR = Color3.fromRGB(245, 245, 245)
DummyLines.BOX_COLOR = Color3.fromRGB(16, 16, 18)
DummyLines.BOX_ALPHA = 0.12 -- the box's transparency
DummyLines.HOLD = 2.6 -- s a line stays up
DummyLines.IDLE_GAP = Vector2.new(18, 40) -- s between one dummy's idle lines (random in the range)
DummyLines.IDLE_MAX = 1 -- idle lines on one screen at once (UI audit 21 Nov 2026: 2 -> 1, fewer floating words)
DummyLines.OUCH_WINDOW = 1.5 -- s after getting up an ouch line may show
DummyLines.OUCH_CHANCE = 0.45
DummyLines.DISTANCE = 45 -- studs: further away no line is drawn (UI audit 21 Nov 2026: 60 -> 45)

-- One line of a list, picked by a seed (the same dummy does not say the same thing twice in a row:
-- the turn moves on each time).
function DummyLines.pick(list: { string }, seed: number, turn: number): string
	local n = #list
	return list[((math.floor(seed * 7) + turn) % n) + 1]
end

return table.freeze(DummyLines)
