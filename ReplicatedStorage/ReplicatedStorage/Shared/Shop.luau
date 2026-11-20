--!strict
-- Passes and what's new (phase I). Shared so the shop, the server's checks and the tests read the
-- same table. Pass ids are 0 until the owner creates them on the Creator Dashboard (a 0 id is never
-- sold: the shop says "soon"; in Studio the card's TEST button turns the pass on for the session).

export type Pass = { key: string, id: number, name: string, blurb: string, perks: { string }, color: string }

local Shop = {}

Shop.PASSES = table.freeze({
	{
		key = "Ultra",
		id = 2075722841, -- the ULTRA game pass (249 Robux)
		name = "ULTRA",
		blurb = "Spam everything. No waiting.",
		perks = { "Next to no wait on every tool", "Twice the props out at once", "Double budget for the big bangs" },
		color = "#FF7B22",
	},
	{
		key = "VIP",
		id = 2075632736, -- the VIP game pass (149 Robux)
		name = "VIP",
		blurb = "Stand out. Eggs come faster.",
		perks = { "VIP tag over your head", "An egg every 50 takedowns (not 75)", "VIP next to your name on the boards" },
		color = "#FFD24A",
	},
} :: { Pass })

Shop.byKey = {} :: { [string]: Pass }
for _, pass in Shop.PASSES do
	Shop.byKey[pass.key] = pass
end

Shop.FREE_ULTRA_SECONDS = 180 -- every player's free ULTRA minutes each day
Shop.FREE_ULTRA_AFTER = 300 -- s of play before they start (the 5-minute gift)
Shop.ZERO_DELAY = 0.08 -- s between uses of one tool with ULTRA (client and server read this)
Shop.VIP_EGG_EVERY = 50

-- Weapons for Robux (round 2, N4): one developer product per price tier (Toys.priceTiers). The
-- weapon itself is chosen in the catalog just before the prompt. 0 until the owner creates them.
Shop.WEAPON_PRODUCTS = table.freeze({
	Weapon25 = 3730106832, -- developer product "Weapon (25)"
	Weapon49 = 3730106862, -- developer product "Weapon (49)"
	Weapon99 = 3730106880, -- developer product "Weapon (99)"
	Weapon199 = 3730106940, -- developer product "Weapon (199)"
} :: { [string]: number })

-- Round 5: the game's Roblox group (REWARDS: join it for a free weapon egg; joining is allowed as
-- a reward, likes and favourites are not). 0 until the owner sends the group id: the card says SOON.
Shop.GROUP_ID = 0
-- Today's deal (round 5): the Starter Pack developer product. 0 until the owner creates it: the
-- card says SOON and never opens a prompt. What it gives: STARTER_PACK below (MoneyService).
Shop.STARTER_PACK = 0
Shop.STARTER_PACK_ROBUX = 29
Shop.STARTER_PACK_TEXT = "3 weapon eggs + the Revolver"

-- What changed, newest first (the What's New window shows the top entry once per version).
Shop.WHATS_NEW = table.freeze({
	{
		version = "0.23.0",
		lines = {
			"TALK TO PEOPLE: press E and they follow you, stay put or take on another dummy",
			"A REAL GORILLA and a stampeding BULL HERD",
			"11 NEW SURPRISES: UFO beam, lightning, sinkhole, giant fan, moon gravity and more",
			"CARS with real wheels, lights, engine sound and a horn (H)",
			"Smooth SLOW-MO, a new sports-hall arena and TODAY'S MACHINE in your lab",
		},
	},
	{
		version = "0.22.0",
		lines = {
			"5 NEW MAPS: Tropical Island, Downtown, Building Site, Old Farm and Army Base",
			"LAUNCH PADS on every map: catapult, cliff dive, manholes, mortar, hay slingshot and more",
			"THROW TOWER in your lab: ride up, then fly off the top",
			"NEW EVENTS: TORNADO, METEOR SHOWER and TRAIN RUN (try the BIG RED BUTTON)",
			"New experiment cards and a phone screen that fits better",
		},
	},
	{
		version = "0.21.0",
		lines = {
			"NEW LOOK: calm daylight, green hills and trees, clean white test dummies",
			"DUMMIES TALK: point something at them and hear what they think",
			"CARS: hop in the family car or the MONSTER TRUCK and drive into the crowd",
			"BIG RED BUTTON in every lab: press it for a random event",
			"GORILLA RAMPAGE and BULL RUN: new animal events",
			"A cleaner screen, the LAB window, and weapons you can spin in 3D",
		},
	},
	{
		version = "0.20.0", -- (0.18 and 0.19 never went live: this entry is all of them)
		lines = {
			"EXPERIMENTS: a quick goal card with a timer and stars. Three DAILY EXPERIMENTS, the same for everyone",
			"X-RAY REPLAY: see the bones fly, get a score and a SHARE CODE for your friends",
			"BOLTS: earn them from experiments and playing, spend them on the next weapon",
			"BONE JOURNAL: 15 pages to fill",
			"PRANK PARTY: friends in your lab share one experiment, and can toss each other into the traps",
			"Controllers work now, and phones held upright get their own layout",
		},
	},
	{
		version = "0.13.0",
		lines = {
			"WEAPONS: Melee, Guns, Explosives and Specials. New: crowbar, Deagle, axe, cleaver, shotgun, katana, chainsaw and a plasma blade",
			"Every locked weapon shows how many takedowns are left, or buy it straight away",
			"Eggs now hold a weapon you don't have yet (a hat once you have them all)",
			"The blaster is a real G17 handgun now",
			"DOCTOR MODE (V): read a body's pulse, blood pressure, oxygen and wounds on a monitor",
			"Every tool you had before is still yours",
		},
	},
	{
		version = "0.12.0",
		lines = {
			"CLIPS & LIVE: record clips with one key, a creator mode with no buttons, and Streamer Mode for TikTok LIVE",
			"KEYS: every action has a key, and you can change them all in Controls (K)",
			"BUILD with keys: R turn, T tilt, Q/E pick parts, Z undo, Enter to play",
			"New Slow-Mo Spell, a real Slime Cannon, and every tool has a picture",
			"Free ULTRA keeps its minutes if you rejoin, and the clock shows on the Shop",
			"Combos give bonus takedowns, and new tools unlock with a cheer",
		},
	},
	{
		version = "0.11.0",
		lines = {
			"PLACES: a night hangar, coffee bar, office, food court, supermarket and a giant white room, full of people",
			"People have personalities now: cowards, brave ones, grumpy ones, clowns and sleepyheads",
			"RANK & EGGS: takedowns, ranks, a daily egg and 12 hats to collect",
			"GAME ARENA: Red Light, Green Light and Shoot 'em. Beat your best!",
			"FRIENDS: nuke or prank your Roblox friends, hit each other in the plaza, and a horde to fight together",
			"New tools to unlock: crossbow, nail gun, slime, shrink, chicken, float and a portal gun",
		},
	},
})

-- Phase 2 (MASTER_PLAN 5): the monetisation ladder. Every id is 0 until the owner makes the
-- developer product / game pass on the Creator Dashboard: PASTE THE ID INTO `id = 0` BELOW and
-- nothing else (release 0.20.0: OfferService sells and grants them, Shared\Offers says what each
-- gives, the SHOP window's OFFERS section shows every one with an id; id 0 is hidden live and
-- shown as TEST in Studio). No paid random items here (no eggs: no odds needed), and slow-mo and
-- the replay are never sold.
Shop.OFFERS = table.freeze({
	table.freeze({ key = "EntryPack", kind = "product", name = "Starter Crate", robux = 49, id = 0, gives = "300 BOLTS and the Rattler" }),
	table.freeze({ key = "AllMelee", kind = "pass", name = "All Melee", robux = 69, id = 0, gives = "Every melee toy" }),
	table.freeze({ key = "AllExplosives", kind = "pass", name = "All Explosives", robux = 99, id = 0, gives = "Every explosive" }),
	table.freeze({ key = "AllGuns", kind = "pass", name = "All Guns", robux = 149, id = 0, gives = "Every gun" }),
	table.freeze({ key = "LabControls", kind = "pass", name = "Lab Controls", robux = 179, id = 0, gives = "BIG RED BUTTON every 8 s in your lab" }),
	table.freeze({ key = "DoubleBolts", kind = "pass", name = "2x BOLTS", robux = 129, id = 0, gives = "Double BOLTS from everything" }),
	table.freeze({ key = "VipLab", kind = "pass", name = "VIP Lab", robux = 199, id = 0, gives = "More dummies roaming your lab" }),
	table.freeze({ key = "EventsPass", kind = "pass", name = "Events Pass", robux = 249, id = 0, gives = "Every server event, free, all season" }),
	table.freeze({ key = "Everything", kind = "pass", name = "Everything", robux = 699, id = 0, gives = "Every toy, 2x BOLTS, VIP Lab, Events Pass and Lab Controls" }),
})

return table.freeze(Shop)
