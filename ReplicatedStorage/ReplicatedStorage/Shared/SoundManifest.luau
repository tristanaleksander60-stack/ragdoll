--!strict
-- Round 4, M10: the source and asset id of every sound FxController plays.
--
-- Most assets are Creator Store uploads from the "Pro Sound Effects (SFX)" library, licensed to
-- Roblox for use in experiences. The real guns (G17, Deagle, shotgun) use public community uploads,
-- each with its creator recorded.
--
-- The client builds its BANK from this manifest (FxController), so the two cannot drift, and all
-- gun sound settings live here (GUNS), where server tests can check them (T41_SoundManifest).
--
-- Columns: bank key -> list of { id, title, source, creator? }.
--   bank    key FxController plays by (hit, bat, g17, shotgunPump, ...).
--   id      numeric Roblox asset id (no "rbxassetid://" prefix).
--   title   Creator Store listing name (verbatim).
--   source  where the asset came from: one of SOURCES.
--   creator the uploader, for community uploads.

local SoundManifest = {}

local PSE = "Roblox Creator Store / Pro Sound Effects (SFX)"
local APM = "Roblox Creator Store / APM Music"
local COMMUNITY = "Roblox Creator Store / community upload"
local ROBLOX = "Roblox Creator Store / Roblox"

SoundManifest.SOURCES = table.freeze({ PSE = PSE, APM = APM, COMMUNITY = COMMUNITY, ROBLOX = ROBLOX })

type Entry = { id: number, title: string, source: string, creator: string? }

local SOUNDS: { [string]: { Entry } } = {
	hit = {
		{ id = 9117969584, title = "Punch Kit Beefy Hit 1", source = PSE },
		{ id = 9117969687, title = "Punch Kit Beefy Hit 2", source = PSE },
		{ id = 9117969717, title = "Punch Kit Beefy Hit 3", source = PSE },
		{ id = 9117969878, title = "Punch Kit Beefy Hit 4", source = PSE },
		{ id = 9117969892, title = "Punch Kit Beefy Hit 5", source = PSE },
		{ id = 9117969990, title = "Punch Kit Beefy Hit 6", source = PSE },
		{ id = 9117970193, title = "Punch Kit Beefy Hit 7", source = PSE },
		{ id = 9117970227, title = "Punch Kit Beefy Hit 8", source = PSE },
	},
	land = {
		{ id = 9113480917, title = "Body Fall Thud 1", source = PSE },
		{ id = 9113480915, title = "Body Fall Thud 2", source = PSE },
		{ id = 9113525391, title = "Body Impact 1", source = PSE },
		{ id = 9113525643, title = "Body Impact 4", source = PSE },
		{ id = 9113479620, title = "Body Falls 4", source = PSE },
	},
	whoosh = {
		{ id = 9120728815, title = "Whoosh Heavy Punches 1", source = PSE },
		{ id = 9120728883, title = "Whoosh Heavy Punches 2", source = PSE },
		{ id = 9120729007, title = "Whoosh Heavy Punches 3", source = PSE },
		{ id = 9120729005, title = "Whoosh Heavy Punches 4", source = PSE },
		{ id = 9120729339, title = "Whoosh Heavy Punches 7", source = PSE },
		{ id = 9120729412, title = "Whoosh Heavy Punches 8", source = PSE },
		{ id = 9126045906, title = "Synth Air Whoosh Cheesy Karate Style Swishes 3", source = PSE },
	},
	whistle = {
		{ id = 9119197913, title = "Slide Whistle 2", source = PSE },
		{ id = 9119198140, title = "Slide Whistle 4", source = PSE },
		{ id = 9119198150, title = "Slide Whistle 6", source = PSE },
	},
	boom = {
		{ id = 9119236749, title = "Small Explosion 1", source = PSE },
		{ id = 9119236757, title = "Small Explosion 2", source = PSE },
	},
	-- Explosions by size (10 Nov 2026, the owner: different fitting explosion sounds).
	boomPop = { -- the firecracker: a sharp crackle
		{ id = 110394435529707, title = "firecracker1", source = COMMUNITY, creator = "fourportraits" },
		{ id = 135572512603627, title = "firecracker2", source = COMMUNITY, creator = "fourportraits" },
	},
	boomMid = { -- TNT, the sticky bomb: a grenade-sized blast
		{ id = 131756915295707, title = "Tnt Explosion", source = COMMUNITY, creator = "ThatCrypticAnomaly" },
		{ id = 134825578212679, title = "Grenade Explosion_01", source = COMMUNITY, creator = "H3xQu33n" },
		{ id = 139210252225248, title = "grenade explosion", source = COMMUNITY, creator = "coolguyVicaso" },
	},
	boomBig = { -- the Big Boom, the Mega Bomb: a huge blast with a long tail
		{ id = 18161535641, title = "explosion_large_a", source = COMMUNITY, creator = "Concoerror" },
		{ id = 138278545827368, title = "loud explosion with debris 1", source = COMMUNITY, creator = "diman's group" },
		{ id = 137966233828336, title = "loud explosion with debris 2", source = COMMUNITY, creator = "diman's group" },
	},
	debris = { -- rubble raining down after a big one
		{ id = 107480513009908, title = "Debris Explosion + Small Rocks Rumbling 1", source = COMMUNITY, creator = "GleonoffG" },
		{ id = 120212342534790, title = "Debris Explosion + Small Rocks Rumbling 2", source = COMMUNITY, creator = "GleonoffG" },
	},
	cannonShot = { -- the cannon firing (not its ball landing)
		{ id = 132049253240174, title = "Small Cannon \"Musket\" Fire", source = COMMUNITY, creator = "NickySergal" },
		{ id = 72411732778781, title = "Cannon Fire Shot Sound Effect", source = COMMUNITY, creator = "lukaian3900hm" },
	},
	slam = { -- the shockwave: a ground slam
		{ id = 91288569991875, title = "Ground Slam 3 Explosion, Impact", source = COMMUNITY, creator = "GleonoffG" },
	},
	nail = {
		{ id = 9117049383, title = "Nail Gun Large Pneumatic Air Bursts 3", source = PSE },
	},
	bat = {
		{ id = 9113321439, title = "Baseball Wood Bat Hits Hard Ball 4", source = PSE },
		{ id = 9113321672, title = "Baseball Wood Bat Practice Hits 3", source = PSE },
		{ id = 9113321776, title = "Baseball Wood Bat Practice Hits 6", source = PSE },
	},
	golf = {
		{ id = 9114627130, title = "Golf Ball Regular Hits Snappy Club Impact 1", source = PSE },
	},
	chop = {
		{ id = 9120809128, title = "Wood Chopping Exterior Single Hits 21", source = PSE },
		{ id = 9120809120, title = "Wood Chopping Exterior Single Hits 22", source = PSE },
		{ id = 9120810231, title = "Wood Chopping Exterior Single Hits 6", source = PSE },
	},
	saw = {
		{ id = 9113764695, title = "Chainsaw Pull Starter Run Revs Buzzy Grind 2", source = PSE },
	},
	arrow = {
		{ id = 9113160887, title = "Arrow In And Hit 14", source = PSE },
		{ id = 9113160992, title = "Arrow In And Hit 2", source = PSE },
		{ id = 9113160782, title = "Arrow In And Hit 13", source = PSE },
	},
	ricMetal = {
		{ id = 9118168612, title = "Ricochet Metal 1", source = PSE },
		{ id = 9118168610, title = "Ricochet Metal 2", source = PSE },
		{ id = 9118168949, title = "Ricochet Metal 3", source = PSE },
		{ id = 9118168943, title = "Ricochet Metal 4", source = PSE },
		{ id = 9118168962, title = "Ricochet Metal 5", source = PSE },
	},
	ricHard = {
		{ id = 9118169263, title = "Ricochet Reverberant 2", source = PSE },
		{ id = 9118169272, title = "Ricochet Reverberant 3", source = PSE },
		{ id = 9118169775, title = "Ricochet Reverberant 8", source = PSE },
	},
	shatter = {
		{ id = 9114592245, title = "Glass Breaks 3", source = PSE },
		{ id = 9114592102, title = "Glass Breaks 11", source = PSE },
		{ id = 9114590297, title = "Glass Break 1", source = PSE },
	},
	boing = {
		{ id = 9116421238, title = "Magic Transformation 3", source = PSE },
		{ id = 9116421550, title = "Magic Transformation 6", source = PSE },
		{ id = 9116421639, title = "Magic Transformation 8", source = PSE },
		{ id = 9116421827, title = "Magic Transformation 10", source = PSE },
	},
	noodle = {
		{ id = 9120086451, title = "Toad Tongue 1", source = PSE },
		{ id = 9120086769, title = "Toad Tongue 7", source = PSE },
		{ id = 9120086767, title = "Toad Tongue 8", source = PSE },
	},
	freeze = {
		{ id = 9116423522, title = "Magic Transformation 30", source = PSE },
		{ id = 9116423786, title = "Magic Transformation 33", source = PSE },
	},
	clang = {
		{ id = 9116650982, title = "Metal Hits 11", source = PSE },
	},
	zap = {
		{ id = 9114277338, title = "Electric Zaps 4", source = PSE },
		{ id = 9114277402, title = "Electric Zaps 6", source = PSE },
		{ id = 9114277757, title = "Electric Zaps 12", source = PSE },
	},
	pop = {
		{ id = 9113263649, title = "Balloon Pop 3", source = PSE },
		{ id = 9113263647, title = "Balloon Pop 4", source = PSE },
	},
	zip = {
		{ id = 9120991224, title = "Zip Bys Airy Rips 3", source = PSE },
		{ id = 9120991596, title = "Zip Bys Airy Rips 6", source = PSE },
	},
	suck = {
		{ id = 1837834302, title = "APM Reverse Hard Stop Noise Build 1", source = APM },
		{ id = 1837834257, title = "APM Reverse Hard Stop Noise Build 2", source = APM },
	},
	-- Round 4, M10: each real gun its own gunshot (and its own burst cap and variant memory). The
	-- owner: the pistols must sound like REAL guns, not airsoft. A bank of mixed recordings made each
	-- shot another gun, and short dry "mid" shots sound like a toy; each gun is now ONE full, close,
	-- high-quality recording with its crack, its body and its room tail, loud, and only the pitch
	-- moves a little shot to shot (SoundManifest.GUNS.vary).
	g17 = {
		{ id = 77245791056472, title = "Glock 9mm Shot Close", source = COMMUNITY, creator = "LilHuggito" },
	},
	deagle = {
		{ id = 124140337606769, title = "HM Magnum Shot", source = COMMUNITY, creator = "SoundEffects+" },
	},
	shotgun = {
		{ id = 82651111765871, title = "HM Shotgun Shot", source = COMMUNITY, creator = "SoundEffects+" },
	},
	shotgunPump = {
		{ id = 113837896417526, title = "shotgun-pump", source = COMMUNITY, creator = "RabbitFan6butreal" },
		{ id = 7129228370, title = "Shotgun Pump", source = COMMUNITY, creator = "RMSTray" },
	},
	dryfire = {
		{ id = 72166668675269, title = "dryfire 03", source = COMMUNITY, creator = "pewziier" },
		{ id = 88242783225642, title = "dryfire 04", source = COMMUNITY, creator = "pewziier" },
	},
	-- Round 5: every gun its own real recording (Creator Store community uploads; most from one
	-- consistent set, "M9K", uploaded by diman's group), and the reloads.
	revolver = { { id = 76454425681135, title = "Revolver Gunshot (v1)", source = COMMUNITY, creator = "Murklit" } },
	ak = { { id = 97861013448047, title = "M9K Ak47 fire", source = COMMUNITY, creator = "diman's group" } },
	m4 = { { id = 80364343032315, title = "M9K Hk416 fire", source = COMMUNITY, creator = "diman's group" } },
	lmg = { { id = 80013099941453, title = "M9K M249 lmg/M60 fire", source = COMMUNITY, creator = "diman's group" } },
	minigun = { { id = 130050001949841, title = "M9K Minigun fire", source = COMMUNITY, creator = "diman's group" } },
	tommy = { { id = 93497135091483, title = "M9K Tommy Gun fire", source = COMMUNITY, creator = "diman's group" } },
	smg = { { id = 104691350909652, title = "M9K TEC-9 Fire", source = COMMUNITY, creator = "diman's group" } },
	dmr = { { id = 133505875958273, title = "M9K M14 fire", source = COMMUNITY, creator = "diman's group" } },
	doubleBarrel = { { id = 90365204399312, title = "M9K Heavy Arms | Double Barrel Shotgun Fire", source = COMMUNITY, creator = "xxxnewmakcxxx" } },
	sniper = { { id = 98063753863205, title = "Sniper Rifle Single Shot 1", source = COMMUNITY, creator = "CBE_Simon" } },
	flare = { { id = 140624285620685, title = "pop", source = COMMUNITY, creator = "fur_pl" } },
	laser = { { id = 8964303934, title = "Laser Assault Rifle Shot", source = COMMUNITY, creator = "Jimmy Games" } },
	rail = { { id = 1231327271, title = "Generic Laser Shot 3 (PG3D Impulse Sniper Rifle)", source = COMMUNITY, creator = "the1oler" } },
	reloadPistol = { { id = 138248399002834, title = "Pistol Reload (Tactical)", source = COMMUNITY, creator = "SuperNoobProGamer" } },
	reloadRifle = { { id = 100629192646424, title = "AR Reload", source = COMMUNITY, creator = "BoTu_HoK" } },
	reloadAk = { { id = 122500426758721, title = "M9K Ak47 reload", source = COMMUNITY, creator = "diman's group" } },
	reloadSmg = { { id = 116417929617463, title = "M9K Uzi reload", source = COMMUNITY, creator = "diman's group" } },
	reloadTommy = { { id = 91648058477349, title = "M9K Tommy Gun reload", source = COMMUNITY, creator = "diman's group" } },
	reloadMinigun = { { id = 117169395591371, title = "M9K M134 minigun reload", source = COMMUNITY, creator = "diman's group" } },
	reloadShell = { { id = 82941311824281, title = "M9K Heavy Arms | Double Barrel Shotgun Insert", source = COMMUNITY, creator = "xxxnewmakcxxx" } },
	-- A round going into a body.
	flesh = {
		{ id = 111824338056647, title = "bullet-body-hit1", source = COMMUNITY, creator = "ChipTheTrainer2" },
		{ id = 87089702933769, title = "flesh_impact_bullet1", source = COMMUNITY, creator = "BrightToken" },
		{ id = 118310945351211, title = "flesh_impact_bullet2", source = COMMUNITY, creator = "BrightToken" },
		{ id = 117224450347034, title = "flesh_impact_bullet3", source = COMMUNITY, creator = "BrightToken" },
	},
	-- The crossbow's release, heard at the bow.
	crossbow = {
		{ id = 9114000974, title = "Crossbow Fire 5", source = PSE },
		{ id = 9114001362, title = "Crossbow Fire 14", source = PSE },
		{ id = 9114001456, title = "Crossbow Fire 16", source = PSE },
		{ id = 9114000843, title = "Crossbow Fire 2", source = PSE },
	},
	-- 21 Nov 2026 (the owner: "custom sounds for every single weapon"): each tool's own sound
	-- (SoundManifest.TOOLS says when it plays). Roblox-licensed Pro Sound Effects where one fits; a few
	-- community uploads, each with its uploader; all load-checked in Studio on 21 Nov.
	toolPoke = { { id = 9117848644, title = "Pops Mouth Popping Multiple Versions 7 (SFX)", source = PSE } },
	toolSlap = { { id = 9114771792, title = "Hand Slap Claps 3 (SFX)", source = PSE } },
	toolShove = { { id = 9113518407, title = "Body Hit Wall 2 (SFX)", source = PSE } },
	toolKick = { { id = 9117967965, title = "Punching Bag Hits 7 (SFX)", source = PSE } },
	toolUppercut = { { id = 9113502506, title = "Body Hits 8 (SFX)", source = PSE } },
	toolPan = { { id = 9125782644, title = "Pot Clank Hit Metal Pan Some Ring Handle Sto (SFX)", source = PSE } },
	toolGlove = { { id = 9117969420, title = "Punching Bag Hits 22 (SFX)", source = PSE } },
	toolHammer = { { id = 9114578351, title = "Giant Pvc Pipe Big Rubber Mallet Hits 6 (SFX)", source = PSE } },
	toolMegaSlap = { { id = 9114773313, title = "Hand Slap Single Hits 16 (SFX)", source = PSE } },
	toolCleaver = { { id = 9116333353, title = "Machete Cutting Cactus 101 (SFX)", source = PSE } },
	toolKatana = { { id = 9119749145, title = "Sword Swish 102 (SFX)", source = PSE } },
	toolPlasma = { { id = 9114330003, title = "Energy Cloud Whooshing By Very Fast 16 (SFX)", source = PSE } },
	toolGrab = { { id = 9113534108, title = "Body Pats Cloth Hits 24 (SFX)", source = PSE } },
	toolLaunch = { { id = 9125577652, title = "Giant Air Blast Low Bursts Pound Many Versio (SFX)", source = PSE } },
	toolRocket = { { id = 9126009951, title = "Super Animal Rocket By Hissing Jet Whooshes  (SFX)", source = PSE } },
	toolBalloon = { { id = 134057288, title = "Balloon Inflating", source = COMMUNITY, creator = "Polyhex" } },
	toolFreeze = { { id = 9125611419, title = "Ice Freeze Large Piece Crackles Liquid Nitro (SFX)", source = PSE } },
	toolZap = { { id = 9114277757, title = "Electric Zaps 12 (SFX)", source = PSE } },
	toolBlackHole = { { id = 9126236071, title = "Wind Suck Slow Backwards Swooshing Build Up  (SFX)", source = PSE } },
	toolHeal = { { id = 9116394545, title = "Magic Glows Soft Clusters Of Chiming Hits 1 (SFX)", source = PSE } },
	toolAnvil = { { id = 9113132828, title = "Anvil Hit Sharp Metallic Clanks Bouncing 6 (SFX)", source = PSE } },
	toolTrampoline = { { id = 12222124, title = "Short spring sound.wav", source = ROBLOX } },
	toolSpringPad = { { id = 9119529711, title = "Spring Metal Movements 11 (SFX)", source = PSE } },
	toolBanana = { { id = 9119198132, title = "Slide Whistle 5 (SFX)", source = PSE } },
	toolFan = { { id = 9113840530, title = "Cloth Whooshes Pass Bys Light And Air Wind 1 (SFX)", source = PSE } },
	toolBowling = { { id = 4692687595, title = "Bowling Strike Sound Effect", source = COMMUNITY, creator = "Yolobedstemor and Friends group" } },
	toolSlime = { { id = 9119990151, title = "Tentacle Slime 3 (SFX)", source = PSE } },
	toolShrink = { { id = 9119197920, title = "Slide Whistle 3 (SFX)", source = PSE } },
	toolChicken = { { id = 77584650945481, title = "chicken cluck", source = COMMUNITY, creator = "ShamelessShady" } },
	toolFloat = { { id = 9116395089, title = "Magic Glows Soft Clusters Of Chiming Hits 4 (SFX)", source = PSE } },
	toolSlowmo = { { id = 9120061271, title = "Time Wave Ripple Slow 1 (SFX)", source = PSE } },
	toolPortal = { { id = 9126102694, title = "Time Warp Searing Build Up Large Suck Rumble (SFX)", source = PSE } },
	toolGravity = { { id = 9116236630, title = "Laser Cannon 1702 (SFX)", source = PSE } },
	toolCannon = { { id = 9119382813, title = "Sonic Boom 4 (SFX)", source = PSE } },
	toolFirecracker = { { id = 89568781479045, title = "Firecracker Sound Effect", source = COMMUNITY, creator = "HazQ_R" } },
	toolFuse = { { id = 121953406020749, title = "fuse", source = COMMUNITY, creator = "Alika0946" } },
	toolShockwave = { { id = 9119382258, title = "Sonic Boom 1 (SFX)", source = PSE } },
	toolSticky = { { id = 9119667390, title = "Suction Cup Dart 15 (SFX)", source = PSE } },
	toolBigBoom = { { id = 9119382815, title = "Sonic Boom 5 (SFX)", source = PSE } },
	toolGrenadePin = { { id = 9114659662, title = "Grenade Pull Pin 1 (SFX)", source = PSE } },
	toolC4Beep = { { id = 9125530803, title = "Electronic Blips Sharp Crystalline Beeps Gat (SFX)", source = PSE } },
	toolRpg = { { id = 12222065, title = "Launching rocket.wav", source = ROBLOX } },
	toolNuke = { { id = 9114224354, title = "Earthquake Explosion 1 (SFX)", source = PSE } },
	autoShotgun = { { id = 9112912844, title = "12 Gauge Shotgun 301 (SFX)", source = PSE } },
	goldenDeagle = { { id = 9117402631, title = "Pistol Single Shots 5 (SFX)", source = PSE } },
}
SoundManifest.SOUNDS = SOUNDS

-- Round 4, M10: how each gun sounds (FxController plays these; T41 checks every gun has one).
--   fire        bank of the shot, played at the muzzle; volume, pitch as for any sound.
--   cut         s a shot holds its voice: the whole sample, so it is never chopped off (rapid fire
--               still frees its voices).
--   vary        how far the pitch wanders shot to shot (0.03: 3 %; a real gun sounds the same each
--               time, so far less than the cartoon sounds' 8 %).
--   maxDistance studs the shot is heard (FxService sends shots 350 studs out).
--   fallback    what plays if every fire asset failed to load (a community upload blocked live).
--   after       a bank played afterDelay s after the shot, at the muzzle (the shotgun's pump).
--   dry         a bank played when the trigger is pulled before the gun is ready.
export type Fallback = { bank: string, volume: number, pitch: number }
export type Gun = {
	fire: string,
	volume: number,
	pitch: number,
	cut: number,
	fade: number?, -- s the end of the cut fades over (a gun's room tail dies away, never stops dead)
	vary: number?,
	maxDistance: number,
	fallback: Fallback,
	after: string?,
	afterDelay: number?,
	dry: string?,
	reload: string?, -- round 5: the bank played when it reloads (Ammo)
}

local GUNS: { [string]: Gun } = {
	Blaster = { -- the G17 ("Glock 9mm Shot Close" is 1.98 s; at 10 shots a second each shot's tail
		-- fades out from 0.4 s, so a flurry holds about 8 of the 28 voices, not 13)
		fire = "g17", volume = 0.9, pitch = 1, cut = 0.8, fade = 0.4, vary = 0.03, maxDistance = 400,
		fallback = { bank = "deagle", volume = 0.72, pitch = 1.18 }, reload = "reloadPistol" -- (24 Nov 2026: a real pistol, never the small explosion),
	},
	Deagle = { -- the heaviest pistol ("HM Magnum Shot" is 1.33 s, all of it)
		fire = "deagle", volume = 1, pitch = 1, cut = 1.35, fade = 0.3, vary = 0.03, maxDistance = 450,
		fallback = { bank = "g17", volume = 1, pitch = 0.82 }, dry = "dryfire", reload = "reloadPistol",
	},
	Shotgun = { -- ("HM Shotgun Shot" is 1.47 s, all of it), then the pump
		fire = "shotgun", volume = 1, pitch = 1, cut = 1.5, fade = 0.3, vary = 0.03, maxDistance = 450,
		fallback = { bank = "deagle", volume = 1, pitch = 0.72 },
		after = "shotgunPump", afterDelay = 0.35, dry = "dryfire", reload = "reloadShell",
	},
	Crossbow = {
		fire = "crossbow", volume = 0.5, pitch = 1, cut = 0.6, maxDistance = 200,
		fallback = { bank = "zip", volume = 0.4, pitch = 1.3 },
	},
	Bow = { -- (V9-NOW 23: the string let go; the archer's own screen plays its twang in BowClient)
		fire = "crossbow", volume = 0.35, pitch = 1.2, cut = 0.5, maxDistance = 160,
		fallback = { bank = "zip", volume = 0.35, pitch = 1.4 },
	},
	NailGun = {
		fire = "nail", volume = 0.55, pitch = 1, cut = 0.3, maxDistance = 200,
		fallback = { bank = "pop", volume = 0.3, pitch = 1.9 }, reload = "reloadRifle",
	},
	Minigun = { -- its own spinning roar (0.27 s a shot)
		fire = "minigun", volume = 0.8, pitch = 1, cut = 0.27, fade = 0.08, vary = 0.03, maxDistance = 420,
		fallback = { bank = "g17", volume = 0.7, pitch = 1.12 }, reload = "reloadMinigun",
	},
	Sniper = { -- a heavy rifle crack and its bolt
		fire = "sniper", volume = 1, pitch = 1, cut = 2.2, fade = 0.8, vary = 0.02, maxDistance = 600,
		fallback = { bank = "deagle", volume = 1, pitch = 0.78 }, dry = "dryfire", reload = "reloadRifle",
	},
	-- Round 5: every gun on the ladder its own real recording (SOUNDS above), its own reload.
	Revolver = { fire = "revolver", volume = 0.95, pitch = 1, cut = 1.6, fade = 0.5, vary = 0.03, maxDistance = 450,
		fallback = { bank = "deagle", volume = 0.95, pitch = 0.92 }, dry = "dryfire", reload = "reloadPistol" },
	SMG = { fire = "smg", volume = 0.75, pitch = 1, cut = 0.2, fade = 0.08, vary = 0.04, maxDistance = 380,
		fallback = { bank = "g17", volume = 0.7, pitch = 1.22 }, reload = "reloadSmg" },
	AK = { fire = "ak", volume = 0.9, pitch = 1, cut = 0.5, fade = 0.25, vary = 0.04, maxDistance = 480,
		fallback = { bank = "deagle", volume = 0.85, pitch = 1.16 }, reload = "reloadAk" },
	FlareGun = { fire = "flare", volume = 0.8, pitch = 1, cut = 1.2, fade = 0.4, vary = 0.04, maxDistance = 400,
		fallback = { bank = "shotgun", volume = 0.7, pitch = 1.5 }, reload = "reloadShell" },
	M4 = { fire = "m4", volume = 0.88, pitch = 1, cut = 0.45, fade = 0.2, vary = 0.04, maxDistance = 480,
		fallback = { bank = "deagle", volume = 0.82, pitch = 1.24 }, reload = "reloadRifle" },
	DoubleBarrel = { fire = "doubleBarrel", volume = 1, pitch = 0.92, cut = 1.75, fade = 0.5, vary = 0.03, maxDistance = 480,
		fallback = { bank = "shotgun", volume = 1, pitch = 0.88 }, dry = "dryfire", reload = "reloadShell" },
	TommyGun = { fire = "tommy", volume = 0.82, pitch = 1, cut = 0.26, fade = 0.1, vary = 0.04, maxDistance = 420,
		fallback = { bank = "g17", volume = 0.78, pitch = 0.95 }, reload = "reloadTommy" },
	AutoShotgun = { fire = "autoShotgun", volume = 0.9, pitch = 1, cut = 0.55, fade = 0.25, vary = 0.04, maxDistance = 460,
		fallback = { bank = "shotgun", volume = 0.9, pitch = 1.1 }, reload = "reloadShell" },
	LMG = { fire = "lmg", volume = 0.85, pitch = 1, cut = 0.3, fade = 0.12, vary = 0.04, maxDistance = 500,
		fallback = { bank = "deagle", volume = 0.8, pitch = 1.3 }, reload = "reloadMinigun" },
	DMR = { fire = "dmr", volume = 0.95, pitch = 1, cut = 1.2, fade = 0.5, vary = 0.02, maxDistance = 560,
		fallback = { bank = "deagle", volume = 0.95, pitch = 0.88 }, dry = "dryfire", reload = "reloadRifle" },
	LaserRifle = { fire = "laser", volume = 0.7, pitch = 1, cut = 0.5, fade = 0.15, vary = 0.05, maxDistance = 300,
		fallback = { bank = "zip", volume = 0.6, pitch = 1.7 }, reload = "reloadRifle" },
	Railgun = { fire = "rail", volume = 1, pitch = 0.7, cut = 1, fade = 0.5, vary = 0.02, maxDistance = 650,
		fallback = { bank = "deagle", volume = 1, pitch = 0.6 }, dry = "dryfire", reload = "reloadRifle" },
	GoldenDeagle = { fire = "goldenDeagle", volume = 1, pitch = 1, cut = 1.35, fade = 0.3, vary = 0.03, maxDistance = 460,
		fallback = { bank = "deagle", volume = 1, pitch = 0.96 }, dry = "dryfire", reload = "reloadPistol" },
}
SoundManifest.GUNS = table.freeze(GUNS)

-- 21 Nov 2026 (the owner: "custom sounds for every single weapon"): each non-gun tool's own sound
-- (the guns have theirs in GUNS). FxController plays it on top of the shared thud:
--   on        "Hit"   when the tool's blow, stick or effect lands on a body (also your own,
--                     predicted the moment you tap);
--             "Place" when it is put down or thrown (your own at once, anyone else's when they do);
--   bank      a SOUNDS bank; volume, pitch as for any sound; cut s it is heard at most (fade over the
--             end); maxSpeed: only below this hit speed (a sticky bomb's stick, not its bang).
-- A tool with a sound here never gets the cartoon BONK or its old shared identity sound as well.
export type ToolSound = { on: string, bank: string, volume: number, pitch: number, cut: number, fade: number?, maxSpeed: number? }
local TOOLS: { [string]: ToolSound } = {
	-- By hand.
	Poke = { on = "Hit", bank = "toolPoke", volume = 0.55, pitch = 1.1, cut = 0.6 },
	Slap = { on = "Hit", bank = "toolSlap", volume = 0.7, pitch = 1, cut = 0.6 },
	Shove = { on = "Hit", bank = "toolShove", volume = 0.6, pitch = 1, cut = 0.6 },
	Kick = { on = "Hit", bank = "toolKick", volume = 0.65, pitch = 1, cut = 0.8 },
	Uppercut = { on = "Hit", bank = "toolUppercut", volume = 0.65, pitch = 1, cut = 0.9 },
	Pan = { on = "Hit", bank = "toolPan", volume = 0.6, pitch = 1, cut = 0.9 },
	Glove = { on = "Hit", bank = "toolGlove", volume = 0.6, pitch = 1, cut = 0.6 },
	Hammer = { on = "Hit", bank = "toolHammer", volume = 0.65, pitch = 1, cut = 1 },
	MegaSlap = { on = "Hit", bank = "toolMegaSlap", volume = 0.8, pitch = 0.92, cut = 0.7 },
	Cleaver = { on = "Hit", bank = "toolCleaver", volume = 0.5, pitch = 1.1, cut = 0.6 },
	Katana = { on = "Hit", bank = "toolKatana", volume = 0.55, pitch = 1, cut = 0.7 },
	PlasmaBlade = { on = "Hit", bank = "toolPlasma", volume = 0.5, pitch = 1, cut = 0.8 },
	Grab = { on = "Hit", bank = "toolGrab", volume = 0.5, pitch = 1, cut = 0.5 },
	Launch = { on = "Hit", bank = "toolLaunch", volume = 0.7, pitch = 1, cut = 1, fade = 0.3 },
	GravityGun = { on = "Hit", bank = "toolGravity", volume = 0.6, pitch = 1, cut = 1, fade = 0.3 },
	-- Put on a body.
	Rocket = { on = "Hit", bank = "toolRocket", volume = 0.7, pitch = 1, cut = 1.4, fade = 0.4 },
	Balloon = { on = "Hit", bank = "toolBalloon", volume = 0.6, pitch = 1, cut = 0.7 },
	Freeze = { on = "Hit", bank = "toolFreeze", volume = 0.6, pitch = 1, cut = 1.6, fade = 0.5 },
	Zap = { on = "Hit", bank = "toolZap", volume = 0.6, pitch = 1, cut = 0.9 },
	Heal = { on = "Hit", bank = "toolHeal", volume = 0.55, pitch = 1, cut = 1.4, fade = 0.4 },
	Shrink = { on = "Hit", bank = "toolShrink", volume = 0.5, pitch = 1.2, cut = 1.2, fade = 0.3 },
	Chicken = { on = "Hit", bank = "toolChicken", volume = 0.7, pitch = 1, cut = 0.95 },
	StickyBomb = { on = "Hit", bank = "toolSticky", volume = 0.6, pitch = 1, cut = 0.8, maxSpeed = 14 },
	C4 = { on = "Hit", bank = "toolC4Beep", volume = 0.55, pitch = 1, cut = 0.56, maxSpeed = 14 },
	-- Bangs that go off where they land.
	Firecracker = { on = "Hit", bank = "toolFirecracker", volume = 0.6, pitch = 1, cut = 1.5, fade = 0.5 },
	Shockwave = { on = "Hit", bank = "toolShockwave", volume = 0.75, pitch = 1, cut = 2.5, fade = 1 },
	BigBoom = { on = "Hit", bank = "toolBigBoom", volume = 0.8, pitch = 1, cut = 3, fade = 1.2 },
	Nuke = { on = "Hit", bank = "toolNuke", volume = 1, pitch = 1, cut = 5, fade = 2 },
	Anvil = { on = "Hit", bank = "toolAnvil", volume = 0.75, pitch = 1, cut = 1.6, fade = 0.5 },
	Bowling = { on = "Hit", bank = "toolBowling", volume = 0.7, pitch = 1, cut = 2, fade = 0.6 },
	Trampoline = { on = "Hit", bank = "toolTrampoline", volume = 0.7, pitch = 1, cut = 0.62 },
	SpringPad = { on = "Hit", bank = "toolSpringPad", volume = 0.65, pitch = 1, cut = 1.1, fade = 0.3 },
	Banana = { on = "Hit", bank = "toolBanana", volume = 0.55, pitch = 1, cut = 1.4, fade = 0.3 },
	-- Put down or thrown: heard as it goes.
	TNT = { on = "Place", bank = "toolFuse", volume = 0.5, pitch = 1, cut = 2.5, fade = 0.5 },
	Grenade = { on = "Place", bank = "toolGrenadePin", volume = 0.6, pitch = 1, cut = 1.3 },
	RPG = { on = "Place", bank = "toolRpg", volume = 0.8, pitch = 1, cut = 1.8, fade = 0.4 },
	Cannon = { on = "Place", bank = "toolCannon", volume = 0.7, pitch = 1, cut = 2.5, fade = 1 },
	BlackHole = { on = "Place", bank = "toolBlackHole", volume = 0.6, pitch = 1, cut = 3, fade = 1 },
	Fan = { on = "Place", bank = "toolFan", volume = 0.55, pitch = 1, cut = 2, fade = 0.6 },
	Slime = { on = "Place", bank = "toolSlime", volume = 0.6, pitch = 1, cut = 1 },
	Float = { on = "Place", bank = "toolFloat", volume = 0.55, pitch = 1, cut = 2, fade = 0.6 },
	Slowmo = { on = "Place", bank = "toolSlowmo", volume = 0.6, pitch = 1, cut = 2.5, fade = 0.8 },
	Portal = { on = "Place", bank = "toolPortal", volume = 0.6, pitch = 1, cut = 2.5, fade = 0.8 },
}
SoundManifest.TOOLS = table.freeze(TOOLS)
-- Hits that arrive under another name than their tool's (the banana's slip).
SoundManifest.TOOL_ALIAS = table.freeze({ BananaPeel = "Banana" }) :: { [string]: string }

-- Flat list for tests and asset audits.
SoundManifest.ALL = (function()
	local out: { Entry } = {}
	for _, list in SoundManifest.SOUNDS do
		for _, e in list do
			table.insert(out, e)
		end
	end
	return out
end)()

-- Convenience: a bank's asset ids as "rbxassetid://<n>" strings (for Sound.SoundId).
function SoundManifest.assetIds(bank: string): { string }
	local list = SoundManifest.SOUNDS[bank]
	if not list then
		return {}
	end
	local out: { string } = {}
	for _, e in list do
		table.insert(out, "rbxassetid://" .. tostring(e.id))
	end
	return out
end

table.freeze(SoundManifest)
return SoundManifest
