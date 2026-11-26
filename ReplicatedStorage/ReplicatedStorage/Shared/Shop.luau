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
	{
		-- 21 Nov 2026 (the owner: "a pass called God: it gives access to creating life, spawning
		-- ragdolls"; Config.GOD_PASS, DummySpawn). 0 until it is created on the dashboard (199 Robux):
		-- while it is 0 live, spawning stays free for everyone as before.
		key = "God",
		id = 2093692966, -- the GOD MODE game pass (21 Nov 2026)
		name = "Spawn Ragdolls",
		blurb = "Create life! Spawn ragdolls.",
		perks = { "Spawn ragdolls: tiny, heavy, bouncy, floppy", "Place 1 to 25 where you aim: line, circle, grid, tower, rain", "Each one comes down in a beam of light" },
		color = "#FFE066",
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
		version = "0.53.0",
		lines = {
			"Built for phones: a clean screen, aim help, a clear next goal",
			"The first dummy you annoy gets ANGRY (and runs off)",
			"Weapons are earned with KOs; buy them in SHOP if you like",
		},
	},
	{
		version = "0.33.7",
		lines = {
			"New code: HAVOC (750 BOLTS + a free Minigun try). Type it in CODES!",
			"No more feed computers: throw your ragdolls in yourself!",
		},
	},
	{
		version = "0.33.6",
		lines = {
			"Terminals and the MAPS board: press them up close, turn the camera freely",
			"Skip a mission (-) or hide the card (=); E uses what you stand at",
		},
	},
	{
		version = "0.33.5",
		lines = {
			"The camera turns freely right next to a terminal",
			"Skip a mission (-) or hide the card (=); E uses what you stand at",
		},
	},
	{
		version = "0.33.4",
		lines = {
			"Skip a mission (-) or hide the card (=): no more mission on screen all the time",
			"Keys for everything: E uses what you stand at, 7 GOD, 8 LAB, 9 MORE (all in K)",
		},
	},
	{
		version = "0.33.3",
		lines = {
			"Run dummies over with a car: every one is a KO!",
			"Weapons sit right in your hand, whatever avatar you wear",
		},
	},
	{
		version = "0.33.2",
		lines = {
			"No more holding E: click or tap the screen or the thing itself",
			"The BOW shoots one arrow per draw; the WRECKING BALL swings all the way",
		},
	},
	{
		version = "0.33.1",
		lines = {
			"The BOW shoots one arrow per draw (no more double shot)",
			"The WRECKING BALL swings all the way again",
			"A BOW on your bar: hold to draw, let go to shoot",
		},
	},
	{
		version = "0.33.0",
		lines = {
			"A BOW on your bar: hold to draw, let go to shoot",
			"Every event you start counts its KOs for you, the BIG RED BUTTON too",
			"A calmer lab without neon glow; the MAPS board and portals moved to the edge",
		},
	},
	{
		version = "0.32.0",
		lines = {
			"\u{26A1} 2X KOs + BOLTS for 48 hours!",
			"Drive from the driver's seat: a real cockpit, a turning wheel, engine, tyres and wind",
			"Shoot the big target blocks until they topple over",
		},
	},
	{
		version = "0.31.1",
		lines = {
			"Bullet holes on every ragdoll, and they react to where you hit them",
			"Purple blood is back, real launch pads and recoil on every gun",
			"The vitals monitor pops up for the ragdoll you shoot; pick maps on the MAPS board",
		},
	},
	{
		version = "0.31.0",
		lines = {
			"GOD MODE is FREE in the beta: drop 1 to 25 ragdolls right where you aim",
			"TIME BUBBLE: press Z (or LAB) to slow time down or speed it up round you",
			"A 3D shop, codes (RELEASE, BETA, RAGDOLL) and a brand new town square",
		},
	},
	{
		version = "0.30.0",
		lines = {
			"GOD MODE: create life! Tap GOD and a ragdoll comes down in a beam of light",
			"Try GOD MODE free for 60 seconds every visit",
			"Wide new paths all round your lab",
		},
	},
	{
		version = "0.29.0",
		lines = {
			"A NEW LAB: paths that all join up, a plaza, grass, bushes, lamps and a real LAVA PIT",
			"FEED THE MONSTERS and press FIRE, TOSS or BOUNCE: a dummy flies right in",
			"Start with 6 weapons, and every weapon has its own sound",
			"Pictures instead of words, big SURPRISE banners, and the ROCKET is a rare prize",
		},
	},
	{
		version = "0.27.1",
		lines = {
			"KNOCK IT OVER: barrels, crates and cones in your lab fly when you hit them",
			"The weapon in your hand turns in 3D on your bar",
			"A cleaner screen: one WEAPONS button, keys at the bottom, one goal at a time",
			"Tap a button while a window is open to switch straight to it",
		},
	},
	{
		version = "0.27.0",
		lines = {
			"THE CANNON: a huge arc with slow-mo, a CRASH score, your best and AGAIN",
			"8 MISSIONS that pay BOLTS, with no timers",
			"DROP YOUR OWN DUMMIES: press H for MINI, HEAVY, BOUNCY and FLOPPY",
			"KO COMBOS, readable hits, a fairer chase and a weekly STREAK FREEZE",
		},
	},
	{
		version = "0.26.0",
		lines = {
			"A FULL BAR from the start: Popper, Grab, Bat, Grenade and Launch. The Rocket comes at 3 KOs",
			"EVERY HIT LANDS: your first hits knock them flat, with a big KO and a dusty THWACK",
			"NEW WEAPONS keep your bar: they take the weakest slot and land in your hand",
			"THE CANNON in view from the first second, and calmer dummies: one runs, only for a moment",
		},
	},
	{
		version = "0.25.0",
		lines = {
			"THE MONSTERS COME ALIVE: the spider on its giant web, the frog in its pond, the chicken in its run",
			"GRAVEL PATHS to every machine in your lab, and CRASH-TEST DUMMIES with test marks",
			"A NEW EVENT CARD, missions and new weapons from your first minute",
		},
	},
	{
		version = "0.24.0",
		lines = {
			"A BIGGER LAB with a garden, a fountain and tall hedges: your own private place",
			"THE CREATURE YARD: feed the SPIDER, the giant plant, a frog, a whale geyser and more",
			"BIRDS over your lab and every map",
			"NEW SHOP BOOTHS: pets, trails, the crash-test suit and lab machines (try them free)",
		},
	},
	{
		version = "0.23.0",
		lines = {
			"TALK TO PEOPLE: press E and they follow you, stay put or take on another dummy",
			"A REAL GORILLA and a stampeding BULL HERD",
			"NEW SURPRISES: lightning, sinkhole, giant fan, moon gravity and more",
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
			"BOLTS: earn them from experiments and playing, spend them on the next weapon",
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
	table.freeze({ key = "EntryPack", kind = "product", name = "Starter Crate", robux = 49, id = 3733992321, gives = "300 BOLTS and the Rattler" }),
	table.freeze({ key = "AllMelee", kind = "pass", name = "All Melee", robux = 69, id = 2093740978, gives = "Every melee toy" }),
	table.freeze({ key = "AllExplosives", kind = "pass", name = "All Explosives", robux = 99, id = 2093020938, gives = "Every explosive" }),
	table.freeze({ key = "AllGuns", kind = "pass", name = "All Guns", robux = 149, id = 2091832962, gives = "Every gun" }),
	table.freeze({ key = "LabControls", kind = "pass", name = "Lab Controls", robux = 179, id = 2093398948, gives = "BIG RED BUTTON every 8 s in your lab" }),
	table.freeze({ key = "DoubleBolts", kind = "pass", name = "2x BOLTS", robux = 129, id = 2094556882, gives = "Double BOLTS from everything" }),
	table.freeze({ key = "VipLab", kind = "pass", name = "VIP Lab", robux = 199, id = 2094598991, gives = "More dummies roaming your lab" }),
	table.freeze({ key = "EventsPass", kind = "pass", name = "Events Pass", robux = 249, id = 2095884979, gives = "Every server event, free, all season" }),
	table.freeze({ key = "Everything", kind = "pass", name = "Everything", robux = 699, id = 2094550832, gives = "Every toy, 2x BOLTS, VIP Lab and Events Pass" }),
	-- V6-7: things sold in showcase booths on the maps (MapShopService): `show` is the model on the
	-- pedestal, `places` where its booths stand, `pitch` the one line under its name. Each has a
	-- 60 s free TRY. Ids 0 = no booth live (shown as TEST in Studio).
	table.freeze({ key = "RainbowTrail", kind = "pass", name = "Rainbow Trail", robux = 49, id = 2093129058, gives = "A rainbow trail behind you", map = true, show = "Trail", pitch = "Leave a rainbow wherever you fly", places = { "Plaza", "Island" } }),
	table.freeze({ key = "FireTrail", kind = "pass", name = "Fire Trail", robux = 79, id = 2096742839, gives = "Flames at your feet and a fire trail", map = true, show = "Fire", pitch = "Run, fly and land in flames", places = { "Plaza", "Military" } }),
	table.freeze({ key = "CrashSuit", kind = "pass", name = "Crash-Test Suit", robux = 99, id = 2092577039, gives = "The yellow and black crash-test suit", map = true, show = "Suit", pitch = "Dress like the real crash dummies", places = { "Plaza", "Site" } }),
	table.freeze({ key = "GoldDummies", kind = "pass", name = "Gold Dummies", robux = 149, id = 2094202879, gives = "Every dummy in your lab in shining gold", map = true, show = "GoldDummy", pitch = "Your lab, all in gold", places = { "Plaza", "City" } }),
	table.freeze({ key = "RobotDog", kind = "pass", name = "Robot Dog", robux = 129, id = 2092618946, gives = "A robot dog that follows you everywhere", map = true, show = "PetRobotDog", pitch = "A loyal metal friend at your heels", places = { "Plaza", "City", "Farm" } }),
	table.freeze({ key = "Parrot", kind = "pass", name = "Parrot", robux = 99, id = 2096880821, gives = "A macaw on your shoulder", map = true, show = "PetParrot", pitch = "A bright macaw that rides along", places = { "Island", "Farm" } }),
	table.freeze({ key = "MegaTrampoline", kind = "pass", name = "Mega Trampoline", robux = 149, id = 2093254944, gives = "A giant trampoline in your lab", map = true, show = "Trampoline", pitch = "Bounce dummies (and you) sky high", places = { "Plaza", "Site" } }),
	table.freeze({ key = "GiantFan", kind = "pass", name = "Giant Fan", robux = 179, id = 2093398946, gives = "A giant fan that blows your lab away", map = true, show = "BigFan", pitch = "Blow every dummy across your lab", places = { "Plaza", "Military" } }),
	table.freeze({ key = "SpiderDeluxe", kind = "pass", name = "Spider Deluxe", robux = 199, id = 2097418264, gives = "A golden spider that spits twice as far", map = true, show = "MSpider", pitch = "Your lab's spider, golden and stronger", places = { "Plaza", "Farm" } }),
	table.freeze({ key = "BoltCrate", kind = "product", name = "Bolt Crate", robux = 49, id = 3733992403, gives = "500 BOLTS", map = true, show = "Crate", pitch = "500 BOLTS for your next weapons", places = { "Plaza", "City", "Island" } }),
})

return table.freeze(Shop)
