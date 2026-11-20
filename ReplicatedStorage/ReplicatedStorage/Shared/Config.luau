--!strict
-- Global build info and switches. Read-only at runtime.

local Config = {
	GameName = "Ragdoll Havoc", -- (the owner's name for the game, 10 Nov 2026)
	-- Bumped with every change that goes live (round 5): SessionStats keeps it per visit, so the
	-- numbers of one build can be told from another's.
	Version = "0.23.0", -- (0.18.0 phase 0; 0.19.0 phases 1-3; 0.20.0 the release; 0.21.0 v3 look, cars, animals; 0.22.0 open-air maps, launchers, disasters, train, throw tower, 19 Nov 2026; 0.23.0 v4: talk to NPCs, real gorilla and bulls, 11 surprises, cars, slow-mo, lab zones, 20 Nov 2026; SessionStats also keeps game.PlaceVersion)
	Phase = 3,
	-- Heavy weapons and close blasts can cut a limb off (round 2, N2). Roblox lists severed body
	-- parts as Restricted (18+, ID-checked players only): switching this off keeps the game at a
	-- lower maturity label (purple blood counts as unrealistic) without touching anything else.
	-- PHASE 0 (19 Nov 2026) CHANGED THE DEFAULT, owner decision recorded in CLAUDE.md: was true. Set
	-- it back to true to allow severing again (Restricted risk).
	SEVERING = false,
	-- Phase 0 (19 Nov 2026): nothing that interrupts in a new visit's first QUIET_START s: no view
	-- card, no egg window, at most one hint at a time; tips and gift notes wait until after it. On a
	-- phone LAB VIEW and RUN wait too (HudSlots.PHONE_LATER).
	QUIET_START = 90,
	-- The "Walk, or view from above?" card (74 % never answered it): off; everyone starts in the
	-- player view and LAB VIEW stays a button (MENU's on a phone after the quiet start).
	VIEW_CARD = false,
	-- The three locked "next weapon" cards on the bar (0.15) wait until a player has this many
	-- takedowns AND this many seconds of the visit have passed (BarRules.nextUnlocksShown).
	NEXT_UNLOCKS_MIN_TAKEDOWNS = 25,
	NEXT_UNLOCKS_AFTER = 180,
	-- Mild content (phase 0; the owner's earlier choices stay one switch away):
	--   BLOOD "off": hits show cartoon stars, sparks and dust (HitFxConfig "Stylised"), and the
	--   Settings row is hidden; "purple": the owner's purple cartoon blood, players may turn it off.
	BLOOD = "off" :: "off" | "purple",
	--   TOY_NAMES: toy-style names for the real-gun nicknames (G17 -> Popper ...; Toys.TOY_NAMES).
	--   Internal ids stay, so saves, products and sounds are untouched. false = the old names.
	TOY_NAMES = true,
	--   MILD_TEXT: the hit line names a body region ("Body", "Left arm") and "health", not organs and
	--   blood; doctor mode (opt-in) keeps its monitor.
	MILD_TEXT = true,
	-- Phase 1 (first 60 s hook):
	--   EXPERIMENTS: one-line goal cards with a timer and stars (Shared\Experiments, ExperimentService)
	--   XRAY_REPLAY: the replay shows see-through bodies with their bones, a score pop ("CRACK! +140"),
	--   CLIP IT and a SHARE CODE (Shared\ShareCode)
	--   PHONE_HUD_MAX7: a phone shows the experiment card in the big WEAPONS button's place (the bar
	--   keeps its own WEAPONS slab): fire, stick, bar, experiment, SHOP, MENU, RAGDOLL
	EXPERIMENTS = true,
	EXPERIMENT_FIRST_AT = 120, -- (audit area 1: the leaders show no card before the HUD comes in at 90 s; was 30) -- s into a visit (the first-minute bar must be free too)
	XRAY_REPLAY = true,
	PHONE_HUD_MAX7 = true,
	-- Phase 2 (reasons to stay): BOLTS, the BONE JOURNAL, Daily Experiments, rationed eggs, the
	-- retuned ladder and like-milestone codes (Shared\Economy, EconomyService).
	ECONOMY = true,
	BOLTS_PER_STAR = 10,
	DAILY_BONUS = 30, -- extra bolts for each of today's Daily Experiments
	DAILY_COUNT = 3,
	JOURNAL_BOLTS = 25,
	PLAYTIME_BOLTS = 40,
	EGG_RATION = true, -- playtime gifts give BOLTS, not eggs (eggs: the daily egg and milestones)
	BOLTS_PER_TAKEDOWN = 1.5, -- a weapon costs its ladder takedowns x this in bolts...
	BOLTS_MIN_PRICE = 20, -- ...and never less
	-- The ladder (LADDER_V2): up to LADDER_KEEP takedowns as it was; above, squeezed so the top
	-- (Golden Popper, 1,600) is ~600 and a one-hour goal is in reach. Ids and order unchanged.
	LADDER_V2 = true,
	LADDER_KEEP = 30,
	LADDER_V2_SCALE = 0.363,
	-- Codes the owner turns on by hand when the like count reaches a milestone (never a reward for
	-- liking: Roblox forbids it; anyone may type a live code). Set `code` and `live = true`.
	LIKE_CODES = table.freeze({
		table.freeze({ likes = 100, code = "", bolts = 100, live = false }),
		table.freeze({ likes = 500, code = "", bolts = 200, live = false }),
		table.freeze({ likes = 1000, code = "", bolts = 400, live = false }),
	}),
	-- Phase 3 (social, Christmas, rhythm):
	--   PRANK_PARTY: 2..PARTY_MAX players in one lab share an experiment card (PartyService).
	--   SERVER_SIZE: what the owner sets as the place's max players on the Creator Dashboard (it is not
	--   settable from code; PortalService's own servers and the tests read it). The plan: try 6.
	PRANK_PARTY = true,
	PARTY_MAX = 6,
	SERVER_SIZE = 6,
	-- Release 0.20 (throw your friend): PARTY_THROWS lets the members of a running Prank Party grab
	-- and throw each other inside that lab (PlayerGrab; everywhere else it stays plaza only, and
	-- nobody is ever hurt). A player thrown by a friend who lands in the cannon, on the bullseye, on
	-- a station or in a trap within THROW_COMBO_WINDOW s is a TOSS COMBO: a pop on both screens, a
	-- "Toss" for the thrower's cards (the party's TOSS card, the journal). Combos less than
	-- THROW_COMBO_CHAIN s apart count up (x2, x3...). false = the plaza-only grab of 0.19.
	PARTY_THROWS = true,
	-- Release 0.20.0 (Shop.OFFERS passes, OfferService): EVENTS PASS starts a server event free at
	-- most once per EVENTS_PASS_GAP s; VIP LAB adds VIP_LAB_VISITORS roaming ragdolls in your lab.
	EVENTS_PASS_GAP = 120,
	VIP_LAB_VISITORS = 2,
	THROW_COMBO_WINDOW = 4,
	THROW_COMBO_CHAIN = 20,
	--   CHRISTMAS_FROM_DEC1: the season starts 1 December (it was on since 7 November 2026; Santa hats
	--   in mid-November read as stale). CHRISTMAS_LAB: the chimney launcher, the present trap and the
	--   sleigh ramp in every lab while the season is on; ADVENT: a daily advent experiment 1-24 Dec.
	CHRISTMAS_FROM_DEC1 = true,
	CHRISTMAS_LAB = true,
	ADVENT = true,
	-- Update rhythm: what the title shows in an update week, and the days updates go out. The newest
	-- entry of Shop.WHATS_NEW must carry Config.Version (T66 checks it).
	UPDATE_TITLE = "[UPD] Ragdoll Havoc \u{1F4A5}",
	UPDATE_DAYS = table.freeze({ "Thursday", "Saturday" }),
	-- UI v2 (19 Nov 2026, branch ui-polish): one premium, phone-first look for every screen. The
	-- LihFolk kit's tokens (LihFolkUITheme: navy canvas, havoc-orange accent, Fredoka One titles,
	-- rounder corners, press squish 0.92, 14 px text floor), drawn icons on the HUD's text buttons
	-- (KitStyle.icon), press + click on every button (KitStyle.press), count-up numbers, rarity
	-- colours and readable stat bars on the weapon cards (Shared\UiRarity), a clearer hit / kill
	-- mark. false = the round 5 dark-glass look, unchanged.
	UI_V2 = true,
	-- Extra ragdolls a device simulates for its own lab (Shared\DeviceTier: phone low, tablet and
	-- console mid, computer high).
	DEVICE_CAPS = table.freeze({
		low = table.freeze({ visitors = 1, chasers = 4 }),
		mid = table.freeze({ visitors = 2, chasers = 7 }),
		high = table.freeze({ visitors = 3, chasers = 10 }),
	}),
	-- World/Feel v2 (19 Nov 2026, branch world-polish; nothing of it play-tested in Studio yet):
	--   WORLD_V2: every lab and the plaza get a code-built dressing on top of what was there (a
	--   backdrop wall, a gantry over the test zone, signposts to the cannon and the hazards, a dashed
	--   flight line from the cannon to the bullseye, light towers, crates, barrels, tyres, cables,
	--   framed station boards, warning signs; a nicer chimney, present and sleigh), and the dummies a
	--   test-suit colour and a chest number. Pictures only: not one new part collides, is hit by a ray
	--   or listens for a touch, so play is the same with it off (WorldDress). false = the 0.20 look.
	--   FEEL_V2: hit feel on this screen (a trauma shake from one strength value, a hit-stop on big
	--   moments, star/dust/spark bursts, flop sounds by landing speed, speed trails on launched and
	--   thrown bodies, a slow-mo beat on big combos, muzzle flash, casings and recoil per gun) and the
	--   ragdoll guard (limbs never fly off the body: ActiveRagdoll). false = the 0.20 feel.
	WORLD_V2 = false, -- (LOOK_V3, 19 Nov: off. Its neon boards, suits and floating bits read as clutter)
	FEEL_V2 = true,
	-- What one device draws at most (Shared\FeelTuning reads it; DeviceTier picks the tier):
	--   lights: world lamps lit at once (the nearest; WorldLights), flashes: muzzle-flash lights at
	--   once, particles: particles one burst may emit, trails: speed trails at once, casings: shell
	--   casings in the air at once, ragdolls: bodies this device simulates for its own lab (the 6 lab
	--   dummies + visitors, VIP LAB's extra ones included, + chasers; T80 checks DEVICE_CAPS fits under it).
	FX_CAPS = table.freeze({
		low = table.freeze({ lights = 4, flashes = 1, particles = 10, trails = 3, casings = 6, ragdolls = 14 }),
		mid = table.freeze({ lights = 8, flashes = 2, particles = 18, trails = 6, casings = 12, ragdolls = 18 }),
		high = table.freeze({ lights = 14, flashes = 4, particles = 30, trails = 10, casings = 24, ragdolls = 22 }),
	}),
	-- LOOK_V3 (19 Nov 2026, the owner: "copy everything graphic from the big ragdoll games"; plan:
	-- docs/V3_PLAN.md). Calm overcast daylight with soft shadows and no grey wash on the play area
	-- (ZoneLighting), plain white dummies with no glow, no crash marks and no suits (DummyFactory,
	-- NpcGlow), short lines in a black box over a dummy's head when a gun points at it, when it gets
	-- up from a fall, and idle chatter (DummyLife + Shared\DummyLines), no shouting signs in the world
	-- (Playground billboards), and the clean HUD (HudV3). false = the 0.20 look.
	LOOK_V3 = true,
	MAP_ACTIVITIES = true, -- v3 phase C: launchers on the open-air maps (Server/Systems/MapActivities)
	NPC_COMMANDS = true, -- v4 B4: talk to NPCs (E): follow, stay, attack with your weapons (Server/Systems/NpcCommand, Client/NpcTalk)
	SLOWMO_V2 = true, -- v4 C5: smooth client slow motion (Client/SlowMotion): bodies keep SLOWMO_SCALE of each speed change, grade/blur/vignette/pitch/trails
	SLOWMO_SCALE = 0.25, -- time in a slow-mo bubble runs at this speed
	SLOWMO_AUTO_GAP = 8, -- s between automatic slow moments on big hits
	LAB_SURPRISES = true, -- v4 C4: a short surprise (Surprises.MINI) by itself now and then in your own lab
	LAB_SURPRISE_GAP = Vector2.new(150, 240), -- s between them (random in the range)
	FIRST_WOW_AT = 110, -- s into a visit: a UFO over your own lab once (audit area 1: after the 90 s reveal, never during the first-shot minute; was 50)
	FIRST_VISIT = true, -- audit area 1: the first-visit flow (Client/FirstVisit): a bare screen and one objective line, the HUD slides in at QUIET_START
	NEWCOMER_SECONDS = 300, -- played in all under this = a newcomer (the first-visit flow)
	-- V6-1 notification centre (Client/Notify, Shared/NotifyRules): one big pop-up at a time, gaps by
	-- kind, dedupe, quiet after windows; false = every message straight to Toast as before.
	ADMIN_V2 = true, -- V6-2: the owner's tabbed admin menu (Client/AdminPanel, Server/Systems/AdminTools)
	NOTIFY = true,
	NOTIFY_BIG_AFTER_REVEAL = 20, -- s after a newcomer's HUD reveal before the first big pop-up
	NOTIFY_REVEAL_KEEP = 2, -- rewards that waited through a newcomer's quiet: only the newest this many show
	EXPERIENCE_NOTIFY = true, -- ask for Roblox Experience Notifications opt-in after a wow moment
	NOTIFY_OPTIN_AFTER = 480, -- s of play before that ask (never on join)
	LAB_ZONES = true, -- v4 C1: lab zones, today's machine, NEW tags (Server/Systems/LabZones)
	UI_CLEAN = true, -- v4 D2: calm hand-made look (leaderboards as wall panels, no neon frames/crowns/glow; see LeaderboardService.STYLE)
	ARENA_V2 = true, -- v4 D1: the Game Arena as a sports hall (track floor, lanes, concrete, padding) instead of the pink room
	SPIKE_BLOCKS = false, -- owner 20 Nov 2026: no red spike plates in the labs (true brings them back)
	WRECKING_V2 = true, -- owner 20 Nov 2026: the wrecking ball as a steel ball on a chain under a yellow A-frame gantry (Playground)
	NEW_SINCE = "2026-11-20", -- UTC date of the update whose things get a NEW tag
	NEW_DAYS = 7,
	NEW_IN_LAB = table.freeze({ "BigButton", "LabCar", "LabTruck", "PortalMulti" }), -- names in the lab's folder
	-- v4 A5 (owner): bodies die from enough hits, not only headshots. Every hit adds damage =
	-- weapon power x DAMAGE_PER_POWER x the region (head, limbs) x DAMAGE_BLUNT for blows; BODY_HP of it
	-- kills (about 6 Popper rounds to the body, about 10 punches). Headshots stay instant.
	-- v4 A3: the sound mix (Client/SoundMix): each group's volume under the player's Effects setting.
	SOUND_MIX = table.freeze({ Weapons = 0.95, Impacts = 0.8, Blasts = 1, World = 0.7, UI = 0.45, Ambient = 0.5 }),
	BODY_HP = 100,
	DAMAGE_DECAY = 2, -- damage points a body heals per second (100 in 50 s)
	DAMAGE_PER_POWER = 17,
	DAMAGE_HEAD = 1.5,
	DAMAGE_LIMB = 0.6,
	DAMAGE_BLUNT = 0.83,
	LOOK_V3_LIGHT = table.freeze({
		ClockTime = 13,
		Brightness = 2.2,
		Ambient = Color3.fromRGB(70, 72, 78),
		OutdoorAmbient = Color3.fromRGB(120, 124, 130),
		ExposureCompensation = 0,
		EnvironmentDiffuseScale = 1,
		EnvironmentSpecularScale = 0.6,
		ShadowSoftness = 0.35,
		airDensity = 0.3,
		airOffset = 0.1,
		airHaze = 0.4,
		airGlare = 0,
		airColor = Color3.fromRGB(199, 205, 214),
		airDecay = Color3.fromRGB(106, 112, 125),
		bloom = 0.1,
		bloomThreshold = 2,
		contrast = 0.05,
		saturation = -0.05,
	}),
	LOOK_V3_DUMMY = Color3.fromRGB(240, 240, 238), -- the plain white of a test mannequin
	LOOK_V3_DUMMY_LOW = Color3.fromRGB(232, 232, 230), -- forearms and shins, a hair darker
	LOOK_V3_DUMMY_ENDS = Color3.fromRGB(222, 222, 220), -- hands and feet
	-- v3 Phase C: cars in every lab (VehicleService builds them, VehicleClient drives them on the
	-- driver's screen). Speeds in studs/s; a hit over HitMath.MACHINE_MIN_SPEED knocks a dummy.
	VEHICLES = table.freeze({
		enabled = true,
		Car = table.freeze({ speed = 62, reverse = 22, accel = 2.2, turn = 1.9 }),
		Truck = table.freeze({ speed = 52, reverse = 18, accel = 1.8, turn = 1.5 }),
		flippedReset = 4, -- s an empty flipped or fallen car waits before it goes home
		idleReset = 30, -- s an empty car left away from its pad waits before it goes home
		-- v4 C2: sounds (free Creator Store audio): engine loop (Roblox Resources), horn, crash.
		engineSound = 80317022777602,
		hornSound = 127513531122725,
		crashSound = 70951531892215,
		feel = true, -- spinning/steering wheels, body roll, lights, engine pitch, dust (Client/VehicleFeel)
	}),
	BIG_BUTTON_GAP = 75, -- s between two presses of a lab's BIG RED BUTTON (a random free event)
	LAB_CONTROLS_GAP = 8, -- s: the same with the Lab Controls pass (its owner, in their own lab)
	-- All UI 3D and interactive (19 Nov 2026, the owner): turning weapon models on the cards and the
	-- bar, tilt and depth on the HUD buttons, windows that swing in (Client\Ui3D). Live (turning)
	-- viewports at once per device tier; the rest are drawn once and left still.
	UI_3D = true,
	UI_3D_LIVE = table.freeze({ low = 2, mid = 4, high = 6 }),
	WORLD_V2_LAB_PARTS = 320, -- parts one lab's WORLD_V2 dressing may add (T81)
	WORLD_V2_LAB_LIGHTS = 12, -- lights one lab's dressing may hold (only FX_CAPS[tier].lights are lit)
	COMBO_SLOWMO = 5, -- a combo of this many (and every this-many after) gets the slow-mo beat
}

return table.freeze(Config)
