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

DummyLines.FEAR_COLOR = Color3.fromRGB(255, 205, 64)
DummyLines.IDLE_COLOR = Color3.fromRGB(245, 245, 245)
DummyLines.BOX_COLOR = Color3.fromRGB(16, 16, 18)
DummyLines.BOX_ALPHA = 0.12 -- the box's transparency
DummyLines.HOLD = 2.6 -- s a line stays up
DummyLines.IDLE_GAP = Vector2.new(18, 40) -- s between one dummy's idle lines (random in the range)
DummyLines.IDLE_MAX = 2 -- idle lines on one screen at once
DummyLines.OUCH_WINDOW = 1.5 -- s after getting up an ouch line may show
DummyLines.OUCH_CHANCE = 0.45
DummyLines.DISTANCE = 60 -- studs: further away no line is drawn

-- One line of a list, picked by a seed (the same dummy does not say the same thing twice in a row:
-- the turn moves on each time).
function DummyLines.pick(list: { string }, seed: number, turn: number): string
	local n = #list
	return list[((math.floor(seed * 7) + turn) % n) + 1]
end

return table.freeze(DummyLines)
