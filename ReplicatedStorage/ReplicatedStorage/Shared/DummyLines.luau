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
DummyLines.BOX_ALPHA = 0.3 -- the box's transparency
DummyLines.HOLD = 2.2 -- s a line stays up
DummyLines.IDLE_GAP = Vector2.new(35, 75) -- s between one dummy's idle lines (random in the range)
DummyLines.IDLE_MAX = 1 -- idle lines on one screen at once (UI audit 21 Nov 2026: 2 -> 1, fewer floating words)
DummyLines.OUCH_WINDOW = 1.5 -- s after getting up an ouch line may show
DummyLines.OUCH_CHANCE = 0.45
DummyLines.DISTANCE = 45 -- studs: further away no line is drawn (UI audit 21 Nov 2026: 60 -> 45)

-- 0.36.7 (owner, 22 Nov 2026: "they say something different by where you shoot them"): a line for the
-- spot a hit landed on (the newest wound in the body's Wounds list), and one for a blow (a bat, a punch).
DummyLines.HIT = table.freeze({
	Head = table.freeze({ "My head!", "Right in the noggin!", "I saw stars!", "Not the face!", "My brain hurts!", "Hey, I need that!" }),
	Neck = table.freeze({ "My neck!", "Ack! The neck!", "Can't turn my head now!" }),
	Chest = table.freeze({ "Oof, my chest!", "Right in the ribs!", "Can't... breathe...", "My heart!", "That one went deep!" }),
	Belly = table.freeze({ "My tummy!", "There goes lunch!", "Oof, the belly!", "I just ate!" }),
	Hips = table.freeze({ "My hips!", "There goes my dancing!", "Ow, my back!" }),
	Arm = table.freeze({ "My arm!", "I need that to wave!", "Ow, my elbow!", "Not my good arm!" }),
	Hand = table.freeze({ "My fingers!", "Ow, my hand!", "How will I high-five now?" }),
	Leg = table.freeze({ "My leg!", "I can't run now!", "Ow, my knee!", "Right in the shin!" }),
	Foot = table.freeze({ "My toes!", "Ow, my foot!", "I just got new shoes!" }),
	Blast = table.freeze({ "KABOOM?!", "My ears are ringing!", "I'm on fire! Kind of!" }),
	Blunt = table.freeze({ "Bonk!", "Hey, no hitting!", "That's gonna bruise!", "Ow ow ow!", "Watch the bat!" }),
})

-- The group a wound zone id falls in (DummyLines.HIT).
function DummyLines.hitGroup(zoneId: string): string
	if zoneId == "Brain" or zoneId == "Skull" or zoneId == "Jaw" then
		return "Head"
	elseif zoneId == "Neck" then
		return "Neck"
	elseif zoneId == "Blast" then
		return "Blast"
	elseif zoneId == "Pelvis" then
		return "Hips"
	elseif zoneId == "Liver" or zoneId == "Stomach" or zoneId == "Intestines" or string.find(zoneId, "Kidney", 1, true) then
		return "Belly"
	elseif string.find(zoneId, "Hand", 1, true) then
		return "Hand"
	elseif string.find(zoneId, "Foot", 1, true) then
		return "Foot"
	elseif string.find(zoneId, "Arm", 1, true) or string.find(zoneId, "Forearm", 1, true) then
		return "Arm"
	elseif string.find(zoneId, "Thigh", 1, true) or string.find(zoneId, "Femoral", 1, true) or string.find(zoneId, "Shin", 1, true) then
		return "Leg"
	end
	return "Chest"
end
DummyLines.HIT_GAP = 1.2 -- s between hit lines on this screen (one dummy talks at a time, never a wall of text)
DummyLines.TEXT_SIZE = 16
-- One line of a list, picked by a seed (the same dummy does not say the same thing twice in a row:
-- the turn moves on each time).
-- 21 Nov 2026 (Config.ICON_SIGNS): the same moods as faces, no reading (DummyLife shows these).
DummyLines.EMOJI_IDLE = { "\u{1F634}", "\u{1F914}", "\u{1F643}", "\u{1F440}", "\u{1F62C}", "\u{1F971}", "\u{1F60E}" }
DummyLines.EMOJI_FEAR = { "\u{1F631}", "\u{1F640}", "\u{1F628}", "\u{1F62D}" }
DummyLines.EMOJI_OUCH = { "\u{1F915}", "\u{1F4AB}", "\u{1F635}", "\u{1F92F}" }

function DummyLines.pick(list: { string }, seed: number, turn: number): string
	local n = #list
	return list[((math.floor(seed * 7) + turn) % n) + 1]
end


-- (V11 item 13, owner: "they mourn their mates, kneel and say oh noo, try CPR"): what a mourner says as its
-- Mood changes (Server/Mourning). Saved: the CPR worked. Gone: it gave up.
DummyLines.MOURN = {
	Shock = { "Oh no!", "NOOO!", "What happened?!", "Is he... dead?!" },
	Mourn = { "Oh noo...", "Not you, buddy!", "Wake up! Please!", "Why him?!", "Noooo..." },
	CPR = { "Come on! Breathe!", "Stay with me!", "1, 2, 3, 4...", "Don't you die on me, %s!", "Come on, %s!", "28, 29, 30!" },
	Saved = { "It worked!", "You're back!", "YES! Alive!" },
	Gone = { "I tried...", "Rest easy, pal...", "He's gone..." },
	Gasp = { "*gasp* %s?!", "Oh my... %s!", "Not %s!", "I can't look!" },
	Point = { "LOOK! %s!", "%s is down!", "Somebody help %s!", "Did you SEE that?!" },
	Check = { "%s? Can you hear me?", "No pulse!", "Is he breathing?", "Shh, let me listen...", "I think I feel something!" },
	Breath = { "Deep breath... now!", "Breathe, %s, breathe!", "Here comes air!", "*puff* *puff*" },
	CPRFast = { "Come on come on come on!", "Faster! FASTER!", "Don't panic don't panic!", "Stay with me, %s!" },
	CPRSlam = { "WAKE UP, %s!", "LIVE! LIVE!", "One... BIG... hit!", "Beat, you stupid heart!" },
	CPROne = { "I saw this on TV...", "What comes next?!", "Where's the doctor?!", "Think, think, think!" },
	Cheer = { "It worked!", "YES! %s is alive!", "I'm a hero!", "WOOHOO!" },
	Relief = { "It worked... phew!", "You scared me, %s!", "Never do that again!", "Oh, thank you..." },
	Hug = { "%s! You're back!", "It worked! Come here!", "I missed you, %s!", "Bring it in, buddy!" },
	Despair = { "I tried everything...", "It's my fault!", "What do I tell his mom?", "No... no... no..." },
	Sky = { "WHYYY?!", "NOOOOO!", "Goodbye, %s...", "Take care of %s up there!" },
	Rage = { "YOU! You did this!", "You killed my %s!", "That was %s, you monster!", "Now I'm MAD!" },
	Thanks = { "I saw a light...", "You saved me!", "What did I miss?", "Ow, my ribs!" },
	Angry = { "You killed my %s!", "You'll pay for %s!", "%s was my best friend!", "Come here, you!", "I'm gonna get you!" },
	Box = { "This is for %s!", "Take THAT!", "How do you like it?!", "Not so tough now!", "That's for my %s!" },
} :: { [string]: { string } }

return table.freeze(DummyLines)
