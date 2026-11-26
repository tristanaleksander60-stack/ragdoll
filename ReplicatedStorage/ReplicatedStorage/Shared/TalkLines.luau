--!strict
-- F8 (owner, 26 Nov 2026: "ragdolls snakker om præcis det de kigger på"; Config.TALK_CONTEXT): fixed lines a ragdoll says
-- about what is in front of it: a machine close by, the weapon the player holds, the guard dog, a grave. Fixed text
-- only (no free text). Client/DummyLife picks them: at most one every GAP s on a screen, never the same twice in a row.

local TalkLines = {}

TalkLines.GAP = 4
TalkLines.MACHINE_NEAR = 14 -- studs from a machine
TalkLines.PLAYER_NEAR = 18 -- studs from the player (for the weapon lines)
TalkLines.THING_NEAR = 15 -- studs from the dog or a grave

-- Machine part names in a lab (the first match wins) -> line group.
TalkLines.MACHINE_PARTS = {
	CannonBarrel = "Cannon",
	Fan = "Fan",
	Compressor = "Press",
	Washer = "Washer",
	Whale = "Shark",
	Tower = "Tower",
	Trampoline = "Trampoline",
	Spider = "Spider",
	Plant = "Plant",
	Frog = "Frog",
	Chicken = "Chicken",
	SwingBall = "Wrecking",
}

TalkLines.MACHINE = {
	Cannon = { "I'm NOT getting in that.", "Who builds a cannon for PEOPLE?", "That barrel looks tight.", "Nope. Not today, cannon.", "I can smell the gunpowder.", "Is there a seatbelt in there?" },
	Fan = { "My hair! My beautiful hair!", "Is it windy, or is it just me?", "That fan means business.", "I'll fly away like a leaf.", "Turn it OFF!", "Who needs a fan THAT big?" },
	Press = { "Flat is not a look.", "I'm not a pancake.", "That thing goes SQUISH.", "I like being 3D.", "Don't press me, bro.", "I'd fit in an envelope after that." },
	Washer = { "Is that on the delicate cycle?", "I'm not THAT dirty.", "Spin cycle? No thanks.", "I just got dry!", "It smells like soap and fear.", "Do they have fabric softener?" },
	Shark = { "Nice fishy. Good fishy.", "That fish has a LOT of teeth.", "I'm not a snack.", "Don't look at me like lunch.", "Who put a shark in a lab?", "I'll stay dry, thanks." },
	Tower = { "I'm scared of heights.", "That's a long way down.", "Who climbs that for FUN?", "My knees hurt just looking.", "Don't push me off that.", "I can see my house from here. No I can't." },
	Trampoline = { "Wheee? No. No wheee.", "Bouncy things hate me.", "I'll bounce into space.", "My lunch will come back up.", "That's not a bed.", "Boing? Absolutely not." },
	Spider = { "That spider is TOO big.", "Eight legs, zero chill.", "I'm not a fly!", "Nope. Nope. Nope.", "Who feeds that thing?", "It's looking at me." },
	Plant = { "That plant has teeth.", "Plants should NOT eat people.", "I'm not compost!", "Who waters that monster?", "It smells like salad and danger.", "Don't feed it. Especially me." },
	Frog = { "That frog could swallow a car.", "Ribbit? More like RUN-it.", "I'm not a fly either!", "Big frog, big tongue, big nope.", "Keep that tongue away.", "Who kisses THAT frog?" },
	Chicken = { "Why is the chicken so huge?", "That's a LOT of nuggets.", "It pecks. I know it pecks.", "Bawk? No, BACK.", "I'm not corn!", "It's staring at my head." },
	Wrecking = { "That ball swings HARD.", "I'm not a wall!", "Duck! Duck! Duck!", "That's a very heavy yo-yo.", "Who swings that thing?", "I'll just stand over here." },
}

TalkLines.WEAPON = {
	Pistol = { "Is that a toy?", "Point that somewhere else.", "That's a tiny gun.", "Pew pew? Really?", "Is it loaded? Don't answer.", "I've seen water guns scarier." },
	Sniper = { "Why is it so LONG?", "Can you see me from space with that?", "That's a lot of gun.", "I'll hide. Far away.", "Is that a telescope?", "You don't need to aim THAT well." },
	Bow = { "Robin Hood, is that you?", "Arrows hurt, you know.", "Who still uses a bow?", "Don't make me an apple holder.", "Aim for the target, not me!", "Very medieval of you." },
	Shotgun = { "Okay, that's a big one.", "That's TOO many bullets.", "Please don't spread me.", "That thing is LOUD.", "I'm out. Bye.", "Can we talk about this?" },
	Lasso = { "Yeehaw? No thanks.", "I'm not a cow.", "Don't you rope me!", "Howdy. Goodbye.", "Who gave you a rope?", "I'll walk on my own, partner." },
	Hammer = { "Put the hammer down, buddy.", "I'm not a nail!", "That looks heavy.", "Bonk me and I'll tell.", "Easy with the tools.", "Is this a building site?" },
}

TalkLines.DOG = { "Nice doggy...", "Good boy? Please be a good boy.", "Does he bite? He bites.", "Who's a good dog? Not me.", "Sit! Stay! Please!", "I'm not a bone!" }
TalkLines.GRAVE = { "Rest in peace, Gary.", "He was a good dummy.", "Gone too soon.", "I'll miss you, buddy.", "Who's next? Not me.", "Gary owed me five bucks." }

-- The weapon group for a held tool id.
function TalkLines.weaponGroup(toolId: string?): string?
	if type(toolId) ~= "string" then
		return nil
	end
	local t = string.lower(toolId)
	if string.find(t, "sniper", 1, true) or string.find(t, "rail", 1, true) then
		return "Sniper"
	elseif string.find(t, "shotgun", 1, true) then
		return "Shotgun"
	elseif string.find(t, "bow", 1, true) then
		return "Bow"
	elseif string.find(t, "lasso", 1, true) or string.find(t, "rope", 1, true) then
		return "Lasso"
	elseif string.find(t, "hammer", 1, true) or string.find(t, "bat", 1, true) or string.find(t, "pan", 1, true) then
		return "Hammer"
	elseif string.find(t, "gun", 1, true) or string.find(t, "pistol", 1, true) or string.find(t, "blaster", 1, true) or string.find(t, "rifle", 1, true) or string.find(t, "revolver", 1, true) then
		return "Pistol"
	end
	return nil
end

return TalkLines
