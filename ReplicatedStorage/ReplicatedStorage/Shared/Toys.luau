--!strict
-- The weapons. Every weapon is data here; what it does lives in HitService (hits), ToyService
-- (props, gadgets, blasts) and GrabController (grab). Four shelves (round 2, N4):
--
--   Melee       fists, feet and things you swing: a crowbar and a bat first, then a pan, a golf club,
--               a hammer, an axe, a cleaver, a katana, a chainsaw and, last, the plasma blade
--   Guns        the G17 you start with, then a crossbow, a nail gun, the Deagle and a shotgun
--   Explosives  everything that goes bang: firecracker, TNT, sticky bomb, cannon, shockwave, big boom
--   Specials    grab, heal and the odd ones: rockets, ice, balloons, props, spells and the portal gun
--
-- A new player has five weapons (the G17, punch, shove, bat and crowbar) and Grab; every other one
-- is earned with kills (takedowns, unlockAt: a long ladder, so there is always a next one), found
-- in an egg (ProgressService), or bought now with Robux (its price tier: priceTier).
--
-- Kinds (how a tap is used):
--   "hit"    tap a dummy; speed = how fast the hit would push the whole dummy (studs/s); lift adds an
--            upward share of the push
--   "dummy"  tap a dummy; the server does something special to it
--   "place"  tap any surface; the server puts something there (or sets it off there)
--   "grab"   press on a dummy and drag; let go to throw (on the client)
--
-- power and chaos (0-1) are the two bars on a catalog card: how hard it hits, how much it messes up
-- the lab. fx picks the sound and sparks (FxController).

export type Kind = "hit" | "dummy" | "place" | "grab"
export type Category = "Melee" | "Guns" | "Explosives" | "Specials"
export type Fx = "Dart" | "Light" | "Smack" | "Clang" | "Big" | "Boom" | "Pop" | "Zap" | "Ice" | "Heal" | "Prop" | "Grab" | "Suck"

export type Toy = {
	id: string,
	label: string,
	short: string, -- the label on a bar button (one word that fits a phone-sized button)
	kind: Kind,
	speed: number,
	lift: number,
	cooldown: number,
	color: Color3,
	category: Category,
	blurb: string, -- one short line on its card
	glyph: string, -- its picture (a colour emoji, one per tool, never two the same; T21 checks)
	power: number,
	chaos: number,
	fx: Fx,
	big: boolean, -- a moment worth an Instant Replay
	heavy: boolean, -- shares the per-player budget for big tools (HitService), whatever tool is cycled
	held: boolean, -- shown in your avatar's hand while it is the picked tool (HeldService)
	-- The move your avatar makes with it (AvatarMoves: "Jab", "Swing", "Throw", ...; nil: none, as
	-- for the tools that work from afar with their own visual: the glove, the giant hand, Launch).
	move: string?,
	-- Done with your own hand or foot, or with a smacker in your fist: you must be close in the walk
	-- view, the hit lands when the move connects (with a hit-stop), and no floating stand-in is drawn.
	-- Other hit tools (the glove on a spring, the giant hand) work from afar with their own visual.
	byHand: boolean,
	-- Takedowns it takes to unlock (phase H; 0: open from the start). The server refuses a locked
	-- tool (ProgressService.isUnlocked); the catalog shows the lock and the number.
	unlockAt: number,
	-- A gun (round 2, N2): it fires wherever you aim, a dummy or not (a miss hits the ground, a wall
	-- or the air: HitService's Shot), and every shot is heard far.
	gun: boolean,
	-- How hard its wounds are (VitalsService: blood lost and bled, 1 = a pistol round).
	wound: number,
	-- The chance a hit on a limb cuts it off (heavy blades, a shotgun up close; Config.SEVERING).
	sever: number,
	-- Only this close (studs from the hitter) can it cut (a shotgun up close; nil: any range).
	severRange: number?,
	-- How a body carries it between moves (round 3, M4: AvatarMoves): "Pistol", "Rifle", "Melee", or nil.
	stance: string?,
	-- Fully automatic (Dec 2026, the owner: "hold to spam, pistols one tap at a time"). Holding the
	-- trigger keeps firing at the toy's own cooldown until released; a non-auto gun (the G17, the
	-- Deagle, the Shotgun, the Sniper, the Revolver, the Crossbow, the DoubleBarrel, the FlareGun,
	-- the DMR, the Railgun, the RPG, the GoldenDeagle) is tap per round. LabCamera's hold-to-fire
	-- loop only starts when this is true.
	auto: boolean,
}

type Spec = {
	label: string,
	short: string?,
	kind: Kind,
	category: Category,
	blurb: string,
	glyph: string,
	color: Color3,
	cooldown: number,
	speed: number?,
	lift: number?,
	power: number?,
	chaos: number,
	fx: Fx,
	big: boolean?,
	heavy: boolean?,
	held: boolean?,
	move: string?,
	byHand: boolean?,
	unlockAt: number?,
	gun: boolean?,
	wound: number?,
	sever: number?,
	severRange: number?,
	stance: string?,
	auto: boolean?,
}

local list: { Toy } = {}
local byId: { [string]: Toy } = {}

local MAX_HIT_SPEED = 135 -- the hardest hit sets the power bar to full

local function add(id: string, spec: Spec)
	assert(byId[id] == nil, "tool " .. id .. " listed twice")
	local speed = spec.speed or 0
	local toy: Toy = table.freeze({
		id = id,
		label = spec.label,
		short = spec.short or spec.label,
		kind = spec.kind,
		speed = speed,
		lift = spec.lift or 0,
		cooldown = spec.cooldown,
		color = spec.color,
		category = spec.category,
		blurb = spec.blurb,
		glyph = spec.glyph,
		power = spec.power or math.clamp(speed / MAX_HIT_SPEED, 0.05, 1),
		chaos = spec.chaos,
		fx = spec.fx,
		big = spec.big == true,
		heavy = spec.heavy == true,
		held = spec.held == true,
		-- Whatever you put down or stick on a dummy is thrown.
		move = spec.move or (if spec.kind == "place" or spec.kind == "dummy" then "Throw" else nil),
		byHand = spec.byHand == true,
		unlockAt = spec.unlockAt or 0,
		gun = spec.gun == true,
		-- (Default: from how hard it hits; a poke barely bruises, a bat hurts.)
		wound = spec.wound or math.clamp(speed / 45, 0.15, 1.6),
		sever = spec.sever or 0,
		severRange = spec.severRange,
		-- (From its move, unless it says: a shotgun is fired from the hip but carried as a long gun.)
		stance = spec.stance or (if not spec.held then nil
			elseif spec.move == "Shoot" then "Pistol"
			elseif spec.move == "Aim" then "Rifle"
			elseif spec.move == "Swing" or spec.move == "Chop" or spec.move == "Golf" then "Melee"
			else nil),
		auto = spec.auto == true,
	})
	table.insert(list, toy)
	byId[id] = toy
end

local rgb = Color3.fromRGB

-- The first five --------------------------------------------------------------------------------
-- The G17 is in your hand from the first second (the first five seconds: aim, tap, they drop). Its
-- id stays "Blaster" (saved bars and loadouts keep it).
add("Blaster", { label = "G17", short = "G17", kind = "hit", category = "Guns", blurb = "A real handgun. Quick, clean shots", glyph = "🔫", color = rgb(120, 130, 150), cooldown = 0.1, speed = 36, lift = 0.2, chaos = 0.3, fx = "Dart", held = true, move = "Shoot", gun = true, wound = 1 })
add("Grab", { label = "Grab", kind = "grab", category = "Specials", blurb = "Pick a dummy up, swing it, throw it", glyph = "✋️", color = rgb(120, 230, 140), cooldown = 0.2, power = 0.3, chaos = 0.4, fx = "Grab" })
add("Poke", { label = "Poke", kind = "hit", category = "Melee", blurb = "A tiny prod. They flinch", glyph = "👉", color = rgb(255, 205, 60), cooldown = 0.12, speed = 7, chaos = 0.05, fx = "Light", move = "Jab", byHand = true, unlockAt = 3})
add("Slap", { label = "Slap", kind = "hit", category = "Melee", blurb = "A quick open hand. Wobbly", glyph = "👋", color = rgb(255, 180, 150), cooldown = 0.15, speed = 15, lift = 0.05, chaos = 0.1, fx = "Smack", move = "Slap", byHand = true, unlockAt = 7})
add("Shove", { label = "Shove", kind = "hit", category = "Melee", blurb = "A good push. Down they go", glyph = "🤚", color = rgb(255, 160, 50), cooldown = 0.2, speed = 22, lift = 0.1, chaos = 0.2, fx = "Smack", move = "Push", byHand = true, unlockAt = 6 })
add("Punch", { label = "Punch", kind = "hit", category = "Melee", blurb = "Right where you tap", glyph = "👊", color = rgb(255, 130, 80), cooldown = 0.25, speed = 32, lift = 0.15, chaos = 0.25, fx = "Smack", move = "Jab", byHand = true })
add("Kick", { label = "Kick", kind = "hit", category = "Melee", blurb = "A big boot. Up and away", glyph = "🦵", color = rgb(255, 110, 110), cooldown = 0.3, speed = 42, lift = 0.45, chaos = 0.3, fx = "Smack", move = "Kick", byHand = true, unlockAt = 15})
add("Uppercut", { label = "Uppercut", short = "Upper", kind = "hit", category = "Melee", blurb = "Straight up into the sky", glyph = "🥊", color = rgb(255, 90, 140), cooldown = 0.35, speed = 50, lift = 1.8, chaos = 0.35, fx = "Big", big = true, move = "Uppercut", byHand = true, unlockAt = 110})

-- Swung, and the giant hands ------------------------------------------------------------------
add("Pan", { label = "Pan", kind = "hit", category = "Melee", blurb = "BONK. Cartoon stars included", glyph = "🍳", color = rgb(150, 155, 170), cooldown = 0.3, speed = 38, lift = 0.3, chaos = 0.3, fx = "Clang", held = true, move = "Swing", byHand = true, unlockAt = 50})
add("Glove", { label = "Glove", kind = "hit", category = "Melee", blurb = "A boxing glove on a spring", glyph = "🧤", color = rgb(230, 50, 60), cooldown = 0.3, speed = 52, lift = 0.2, chaos = 0.35, fx = "Smack", unlockAt = 360})
add("Bat", { label = "Bat", kind = "hit", category = "Melee", blurb = "Home run swing", glyph = "🏏", color = rgb(200, 150, 90), cooldown = 0.35, speed = 70, lift = 0.75, chaos = 0.45, fx = "Smack", big = true, held = true, move = "Swing", byHand = true, unlockAt = 2 })
add("Golf", { label = "Golf", kind = "hit", category = "Melee", blurb = "FORE! A long high arc", glyph = "⛳️", color = rgb(110, 200, 120), cooldown = 0.4, speed = 78, lift = 1.3, chaos = 0.5, fx = "Big", big = true, held = true, move = "Golf", byHand = true, unlockAt = 60})
add("Hammer", { label = "Hammer", kind = "hit", category = "Melee", blurb = "A huge mallet. Heavy hitter", glyph = "🔨", color = rgb(170, 110, 70), cooldown = 0.45, speed = 85, lift = 0.5, chaos = 0.6, fx = "Clang", big = true, held = true, move = "Chop", byHand = true, unlockAt = 180})
add("Launch", { label = "Launch", kind = "hit", category = "Specials", blurb = "Sends them flying across the lab", glyph = "💨", color = rgb(255, 90, 70), cooldown = 0.35, speed = 110, lift = 0.8, chaos = 0.75, fx = "Big", big = true, unlockAt = 12})
add("MegaSlap", { label = "Mega Slap", short = "Mega", kind = "hit", category = "Melee", blurb = "A giant hand. Slow, but WOW", glyph = "🖐️", color = rgb(255, 60, 200), cooldown = 1.0, speed = 135, lift = 0.35, chaos = 0.9, fx = "Big", big = true, unlockAt = 620})

-- Explosives -----------------------------------------------------------------------------------
add("Firecracker", { label = "Firecracker", short = "Cracker", kind = "place", category = "Explosives", blurb = "A small pop. Hops dummies nearby", glyph = "🎉", color = rgb(255, 200, 80), cooldown = 0.5, power = 0.25, chaos = 0.3, fx = "Boom", unlockAt = 20})
add("TNT", { label = "TNT", kind = "place", category = "Explosives", blurb = "Ticks, then BOOM. Sets off other TNT", glyph = "🧨", color = rgb(230, 60, 60), cooldown = 0.8, power = 0.7, chaos = 0.8, fx = "Boom", big = true, heavy = true, unlockAt = 45})
add("Shockwave", { label = "Shockwave", short = "Shock", kind = "place", category = "Explosives", blurb = "A ring that sweeps everyone flat", glyph = "⭕️", color = rgb(120, 200, 255), cooldown = 1.2, power = 0.45, chaos = 0.7, fx = "Boom", big = true, heavy = true, unlockAt = 240})
add("StickyBomb", { label = "Sticky Bomb", short = "Sticky", kind = "dummy", category = "Explosives", blurb = "Sticks to a dummy. Blinks... BOOM", glyph = "🧷", color = rgb(90, 220, 90), cooldown = 1.0, power = 0.6, chaos = 0.65, fx = "Boom", big = true, heavy = true, unlockAt = 90})
add("Cannon", { label = "Cannon", kind = "place", category = "Explosives", blurb = "Fires a cannonball where you tap", glyph = "💣", color = rgb(70, 70, 85), cooldown = 0.8, power = 0.65, chaos = 0.6, fx = "Boom", big = true, heavy = true, unlockAt = 165})
add("BigBoom", { label = "Big Boom", short = "Kaboom", kind = "place", category = "Explosives", blurb = "The biggest bang in the lab", glyph = "💥", color = rgb(255, 120, 30), cooldown = 3.0, power = 1, chaos = 1, fx = "Boom", big = true, heavy = true, unlockAt = 560})

-- Specials: gadgets ----------------------------------------------------------------------------
add("Rocket", { label = "Rocket", kind = "dummy", category = "Specials", blurb = "Strap a rocket on. Whoosh!", glyph = "🚀", color = rgb(240, 110, 40), cooldown = 0.8, power = 0.6, chaos = 0.7, fx = "Big", big = true, unlockAt = 30})
add("Balloon", { label = "Balloon", kind = "dummy", category = "Specials", blurb = "Floats them up... then POP", glyph = "🎈", color = rgb(255, 120, 200), cooldown = 0.8, power = 0.2, chaos = 0.4, fx = "Pop", unlockAt = 55})
add("Freeze", { label = "Freeze", kind = "dummy", category = "Specials", blurb = "Ice cube. Hit it to shatter", glyph = "❄️", color = rgb(150, 230, 255), cooldown = 0.6, power = 0.2, chaos = 0.4, fx = "Ice", unlockAt = 40})
add("Zap", { label = "Zap", kind = "dummy", category = "Specials", blurb = "Bzzt. Out cold for a moment", glyph = "⚡️", color = rgb(255, 240, 90), cooldown = 0.6, power = 0.35, chaos = 0.3, fx = "Zap", unlockAt = 80})
add("BlackHole", { label = "Black Hole", short = "Hole", kind = "place", category = "Specials", blurb = "Sucks everything in, spits it out", glyph = "🕳️", color = rgb(110, 70, 200), cooldown = 4.0, power = 0.5, chaos = 1, fx = "Suck", big = true, heavy = true, unlockAt = 800})
add("Heal", { label = "Heal", kind = "dummy", category = "Specials", blurb = "Mends broken limbs. Good as new", glyph = "🩹", color = rgb(120, 230, 170), cooldown = 0.5, power = 0, chaos = 0, fx = "Heal", unlockAt = 8})

-- Specials: props ------------------------------------------------------------------------------
add("Anvil", { label = "Anvil", kind = "place", category = "Specials", blurb = "Drops from the sky. Classic", glyph = "⚓️", color = rgb(120, 125, 140), cooldown = 0.6, power = 0.5, chaos = 0.4, fx = "Prop", big = true, unlockAt = 100})
add("Trampoline", { label = "Trampoline", short = "Trampo", kind = "place", category = "Specials", blurb = "Boing. Throw dummies on it", glyph = "🦘", color = rgb(80, 170, 255), cooldown = 0.8, power = 0.4, chaos = 0.4, fx = "Prop", big = true, unlockAt = 135})
add("SpringPad", { label = "Spring Pad", short = "Spring", kind = "place", category = "Specials", blurb = "Step on it and get FLUNG", glyph = "⏫️", color = rgb(255, 160, 220), cooldown = 0.8, power = 0.7, chaos = 0.5, fx = "Prop", big = true, unlockAt = 200})
add("Banana", { label = "Banana", kind = "place", category = "Specials", blurb = "Walk on it. Slip. Every time", glyph = "🍌", color = rgb(255, 225, 60), cooldown = 0.5, power = 0.2, chaos = 0.35, fx = "Prop", unlockAt = 25})
add("Fan", { label = "Fan", kind = "place", category = "Specials", blurb = "A giant fan. Blows them away", glyph = "🌬️", color = rgb(170, 220, 255), cooldown = 1.0, power = 0.3, chaos = 0.5, fx = "Prop", unlockAt = 300})
add("Bowling", { label = "Bowling", kind = "place", category = "Specials", blurb = "Strike! Bowls dummies like pins", glyph = "🎳", color = rgb(150, 90, 220), cooldown = 0.6, power = 0.45, chaos = 0.5, fx = "Prop", big = true, unlockAt = 260})

-- Earned with kills (phase H; round 2 moved them up the ladder). -------------------------------
add("Crossbow", { label = "Crossbow", short = "X-Bow", kind = "hit", category = "Guns", blurb = "A heavy bolt that sticks in", glyph = "🏹", color = rgb(150, 100, 60), cooldown = 0.6, speed = 70, lift = 0.25, chaos = 0.4, fx = "Dart", big = true, held = true, move = "Aim", gun = true, wound = 1.4, unlockAt = 35})
add("NailGun", { label = "Nail Gun", short = "Nails", kind = "hit", category = "Guns", blurb = "Rat-a-tat. Nails everywhere", glyph = "🔩", color = rgb(150, 160, 175), cooldown = 0.085, speed = 16, lift = 0.05, chaos = 0.35, fx = "Dart", held = true, move = "Aim", gun = true, auto = true, wound = 0.5, unlockAt = 70})
add("Slime", { label = "Slime Cannon", short = "Slime", kind = "place", category = "Specials", blurb = "Lobs a glob of slime. Nobody stays up", glyph = "🐌", color = rgb(110, 230, 80), cooldown = 0.7, power = 0.25, chaos = 0.5, fx = "Prop", held = true, move = "Aim", unlockAt = 330})
add("Shrink", { label = "Shrink Spell", short = "Shrink", kind = "dummy", category = "Specials", blurb = "Tiny for a while. Tiny and angry", glyph = "🤏", color = rgb(190, 120, 255), cooldown = 0.8, power = 0.1, chaos = 0.5, fx = "Zap", held = true, move = "Cast", unlockAt = 450})
add("Chicken", { label = "Chicken Spell", short = "Chicken", kind = "dummy", category = "Specials", blurb = "Turns them into a chicken. BAWK", glyph = "🐔", color = rgb(255, 240, 200), cooldown = 0.8, power = 0.1, chaos = 0.4, fx = "Pop", held = true, move = "Cast", unlockAt = 500})
add("Float", { label = "Float Spell", short = "Float", kind = "place", category = "Specials", blurb = "No gravity here for a bit", glyph = "☁️", color = rgb(140, 200, 255), cooldown = 2.5, power = 0.3, chaos = 0.7, fx = "Suck", big = true, heavy = true, held = true, move = "Cast", unlockAt = 900})
add("Slowmo", { label = "Slow-Mo Spell", short = "Slow-Mo", kind = "place", category = "Specials", blurb = "A bubble where everything moves in slow motion", glyph = "⏳️", color = rgb(200, 140, 255), cooldown = 2.5, power = 0.3, chaos = 0.6, fx = "Suck", big = true, heavy = true, held = true, move = "Cast", unlockAt = 1000})
add("Portal", { label = "Portal Gun", short = "Portal", kind = "place", category = "Specials", blurb = "Two portals. In one, out the other", glyph = "🌀", color = rgb(255, 70, 190), cooldown = 0.5, power = 0.3, chaos = 0.7, fx = "Zap", held = true, move = "Aim", unlockAt = 1150})

-- Round 2 (N4): the crowbar every new player has, and the heavy weapons further up the ladder (the
-- blades and the shotgun up close can cut a limb off: sever, Config.SEVERING).
add("Crowbar", { label = "Crowbar", short = "Crowbar", kind = "hit", category = "Melee", blurb = "Heavy iron. A solid whack", glyph = "🔧", color = rgb(200, 60, 50), cooldown = 0.35, speed = 46, lift = 0.25, chaos = 0.35, fx = "Clang", held = true, move = "Swing", byHand = true, unlockAt = 4 })
add("Deagle", { label = "Deagle", kind = "hit", category = "Guns", blurb = "A big handgun. Slow, and it hits HARD", glyph = "🎯", color = rgb(190, 175, 140), cooldown = 0.45, speed = 70, lift = 0.25, chaos = 0.5, fx = "Dart", big = true, held = true, move = "Shoot", gun = true, wound = 1.6, unlockAt = 120 })
add("Axe", { label = "Axe", kind = "hit", category = "Melee", blurb = "Chop. It can take a limb off", glyph = "🪓", color = rgb(160, 110, 70), cooldown = 0.5, speed = 60, lift = 0.2, chaos = 0.5, fx = "Clang", big = true, held = true, move = "Chop", byHand = true, wound = 1.3, sever = 0.25, unlockAt = 150 })
add("Cleaver", { label = "Cleaver", kind = "hit", category = "Melee", blurb = "A butcher's blade. Quick and nasty", glyph = "🔪", color = rgb(200, 205, 215), cooldown = 0.35, speed = 40, lift = 0.1, chaos = 0.45, fx = "Clang", held = true, move = "Chop", byHand = true, wound = 1.2, sever = 0.2, unlockAt = 220 })
add("Shotgun", { label = "Shotgun", kind = "hit", category = "Guns", blurb = "BOOM. Up close it tears limbs off", glyph = "💢", color = rgb(110, 80, 60), cooldown = 0.9, speed = 95, lift = 0.4, chaos = 0.75, fx = "Dart", big = true, held = true, move = "Shoot", gun = true, wound = 1.8, sever = 0.4, severRange = 14, unlockAt = 280, stance = "Rifle" })
add("Katana", { label = "Katana", kind = "hit", category = "Melee", blurb = "One clean cut. Limbs fly", glyph = "🗡️", color = rgb(220, 225, 235), cooldown = 0.4, speed = 50, lift = 0.15, chaos = 0.6, fx = "Clang", big = true, held = true, move = "Swing", byHand = true, wound = 1.4, sever = 0.45, unlockAt = 400 })
add("Chainsaw", { label = "Chainsaw", short = "Saw", kind = "hit", category = "Melee", blurb = "BRRRRR. Nothing stays attached", glyph = "🪚", color = rgb(255, 150, 40), cooldown = 0.15, speed = 26, lift = 0.05, chaos = 0.85, fx = "Clang", held = true, move = "Chop", byHand = true, wound = 1.1, sever = 0.5, unlockAt = 700 })
-- The big ones (10 Nov 2026, the owner: a lot of big weapons, like the top games: People
-- Playground's and Gorebox's minigun, sniper and rocket launcher, the grenade and C4 of every
-- sandbox shooter, Garry's Mod's gravity gun, and the nuke every ragdoll game ends on).
add("Grenade", { label = "Grenade", kind = "place", category = "Explosives", blurb = "Pull the pin, throw. Two seconds", glyph = "\u{1F34D}", color = rgb(90, 120, 70), cooldown = 0.7, power = 0.6, chaos = 0.65, fx = "Boom", big = true, heavy = true, unlockAt = 10 }) -- (early: the first big bang, from the launch audit)
add("C4", { label = "C4", kind = "dummy", category = "Explosives", blurb = "Stick it on. Beep. Beep. BOOM", glyph = "\u{1F4E6}", color = rgb(200, 190, 150), cooldown = 1.2, power = 0.9, chaos = 0.85, fx = "Boom", big = true, heavy = true, unlockAt = 190 })
add("Minigun", { label = "Minigun", kind = "hit", category = "Guns", blurb = "Six barrels. It never stops", glyph = "\u{1F504}", color = rgb(70, 74, 86), cooldown = 0.045, speed = 14, lift = 0.05, chaos = 0.8, fx = "Dart", held = true, move = "Aim", gun = true, auto = true, wound = 0.7, unlockAt = 58, stance = "Rifle" }) -- (early: the first big gun)
add("Sniper", { label = "Sniper", kind = "hit", category = "Guns", blurb = "One shot from across the lab", glyph = "\u{1F52D}", color = rgb(90, 110, 80), cooldown = 1.4, speed = 95, lift = 0.3, chaos = 0.6, fx = "Dart", big = true, held = true, move = "Aim", gun = true, wound = 2.6, sever = 0.3, unlockAt = 480, stance = "Rifle" })
add("RPG", { label = "Rocket Launcher", short = "RPG", kind = "place", category = "Explosives", blurb = "A rocket where you aim. Huge boom", glyph = "\u{1F386}", color = rgb(110, 120, 80), cooldown = 1.6, power = 0.95, chaos = 0.95, fx = "Boom", big = true, heavy = true, held = true, move = "Aim", unlockAt = 760, stance = "Rifle" })
add("GravityGun", { label = "Gravity Gun", short = "Gravity", kind = "hit", category = "Specials", blurb = "Fling anything across the lab", glyph = "\u{1F9F2}", color = rgb(255, 150, 40), cooldown = 0.5, speed = 130, lift = 0.9, chaos = 0.8, fx = "Big", big = true, held = true, move = "Aim", unlockAt = 950, stance = "Rifle" })
add("Nuke", { label = "Nuke", kind = "place", category = "Explosives", blurb = "The end of the lab. Run.", glyph = "\u{2622}\u{FE0F}", color = rgb(240, 220, 60), cooldown = 8, power = 1, chaos = 1, fx = "Boom", big = true, heavy = true, unlockAt = 1450 })
add("PlasmaBlade", { label = "Plasma Blade", short = "Plasma", kind = "hit", category = "Melee", blurb = "A blade of pure energy. The very last one", glyph = "🌟", color = rgb(90, 220, 255), cooldown = 0.3, speed = 80, lift = 0.4, chaos = 0.9, fx = "Zap", big = true, held = true, move = "Swing", byHand = true, wound = 1.6, sever = 0.55, unlockAt = 1300 })

-- The gun ladder (10 Nov 2026, the owner: "many more guns, so people grind"; the launch funnel: two
-- in three stopped before trying a third tool). A new gun every few dozen takedowns early on, then
-- further apart, and a last one past the Nuke. Real-ish nicknames, no trademarks.
add("Revolver", { label = "Revolver", kind = "hit", category = "Guns", blurb = "Six shots. Each one a big kick", glyph = "🤠", color = rgb(150, 120, 90), cooldown = 0.5, speed = 60, lift = 0.25, chaos = 0.45, fx = "Dart", big = true, held = true, move = "Shoot", gun = true, wound = 1.5, unlockAt = 5 })
add("SMG", { label = "Micro SMG", short = "SMG", kind = "hit", category = "Guns", blurb = "Tiny and fast. Spray and pray", glyph = "🐝", color = rgb(60, 120, 220), cooldown = 0.07, speed = 14, lift = 0.05, chaos = 0.55, fx = "Dart", held = true, move = "Shoot", gun = true, auto = true, wound = 0.6, unlockAt = 17 })
add("AK", { label = "AK Rifle", short = "AK", kind = "hit", category = "Guns", blurb = "The classic rifle. Loud and rough", glyph = "🪖", color = rgb(150, 100, 60), cooldown = 0.11, speed = 26, lift = 0.1, chaos = 0.6, fx = "Dart", held = true, move = "Aim", gun = true, auto = true, wound = 1.0, unlockAt = 27, stance = "Rifle" })
add("FlareGun", { label = "Flare Gun", short = "Flare", kind = "hit", category = "Guns", blurb = "A burning flare. Knocks them flying", glyph = "🔥", color = rgb(255, 110, 40), cooldown = 0.8, speed = 70, lift = 0.7, chaos = 0.6, fx = "Big", big = true, held = true, move = "Shoot", gun = true, wound = 1.0, unlockAt = 65 })
add("M4", { label = "M4 Carbine", short = "M4", kind = "hit", category = "Guns", blurb = "Short, steady carbine. Hold to rip", glyph = "\u{1F396}\u{FE0F}", color = rgb(60, 66, 58), cooldown = 0.1, speed = 28, lift = 0.1, chaos = 0.6, fx = "Dart", held = true, move = "Aim", gun = true, auto = true, wound = 1.1, unlockAt = 95, stance = "Rifle" })
add("DoubleBarrel", { label = "Double Barrel", short = "Double", kind = "hit", category = "Guns", blurb = "Both barrels at once. Sends them across the lab", glyph = "🦆", color = rgb(120, 80, 50), cooldown = 1.1, speed = 115, lift = 0.45, chaos = 0.85, fx = "Dart", big = true, held = true, move = "Shoot", gun = true, wound = 2.0, sever = 0.45, severRange = 12, unlockAt = 140, stance = "Rifle" })
add("TommyGun", { label = "Tommy Gun", short = "Tommy", kind = "hit", category = "Guns", blurb = "A drum full of rounds. Rat-a-tat-tat", glyph = "🎩", color = rgb(110, 75, 45), cooldown = 0.08, speed = 20, lift = 0.08, chaos = 0.7, fx = "Dart", held = true, move = "Aim", gun = true, auto = true, wound = 0.8, unlockAt = 175, stance = "Rifle" })
add("AutoShotgun", { label = "Auto Shotgun", short = "Auto SG", kind = "hit", category = "Guns", blurb = "A shotgun that does not stop", glyph = "\u{1F32A}\u{FE0F}", color = rgb(150, 36, 40), cooldown = 0.3, speed = 80, lift = 0.35, chaos = 0.85, fx = "Dart", big = true, held = true, move = "Aim", gun = true, auto = true, wound = 1.6, sever = 0.35, severRange = 12, unlockAt = 340, stance = "Rifle" })
add("LMG", { label = "LMG", kind = "hit", category = "Guns", blurb = "A belt of a hundred rounds. Hold it down", glyph = "🐘", color = rgb(104, 118, 56), cooldown = 0.06, speed = 22, lift = 0.06, chaos = 0.85, fx = "Dart", held = true, move = "Aim", gun = true, auto = true, wound = 0.9, unlockAt = 430, stance = "Rifle" })
add("DMR", { label = "Marksman Rifle", short = "DMR", kind = "hit", category = "Guns", blurb = "Fast and precise. Every shot counts", glyph = "\u{1F441}\u{FE0F}", color = rgb(96, 104, 86), cooldown = 0.5, speed = 80, lift = 0.25, chaos = 0.6, fx = "Dart", big = true, held = true, move = "Aim", gun = true, wound = 2.0, sever = 0.2, unlockAt = 530, stance = "Rifle" })
add("LaserRifle", { label = "Laser Rifle", short = "Laser", kind = "hit", category = "Guns", blurb = "Pew pew. A beam of red light", glyph = "🔴", color = rgb(255, 60, 70), cooldown = 0.12, speed = 40, lift = 0.2, chaos = 0.75, fx = "Zap", held = true, move = "Aim", gun = true, auto = true, wound = 1.0, unlockAt = 680, stance = "Rifle" })
add("Railgun", { label = "Railgun", short = "Rail", kind = "hit", category = "Guns", blurb = "One charged shot through everything", glyph = "\u{1F6F0}\u{FE0F}", color = rgb(80, 200, 255), cooldown = 2.0, speed = 135, lift = 0.5, chaos = 1, fx = "Zap", big = true, held = true, move = "Aim", gun = true, wound = 3.0, sever = 0.5, unlockAt = 1050, stance = "Rifle" })
add("GoldenDeagle", { label = "Golden Deagle", short = "Golden", kind = "hit", category = "Guns", blurb = "Solid gold. For the very best only", glyph = "👑", color = rgb(255, 200, 60), cooldown = 0.35, speed = 95, lift = 0.3, chaos = 0.8, fx = "Dart", big = true, held = true, move = "Shoot", gun = true, wound = 2.4, sever = 0.3, unlockAt = 1600 })

local CATEGORIES: { Category } = { "Melee", "Guns", "Explosives", "Specials" }

-- The bar you start with (round 5, like the big ragdoll games: few things from the start, the next
-- one almost at once): the G17, Grab and Punch. Bat, Crowbar and Shove come at 2, 4 and 6
-- takedowns (players from before keep them: ProgressService.grandfather, LADDER 3).
local DEFAULT_LOADOUT = { "Blaster", "Grab", "Punch" }
-- How many slots the bar has (a fixed number, not the starting bar's length: round 5).
local SLOTS = 3 -- (the owner, 10 Nov: three weapon slots, then the three locked next weapons on the bar)

-- Buy now with Robux (round 2, N4): four price tiers by how far up the ladder a weapon is (the
-- owner makes one developer product per tier: MoneyService). R$.
local PRICE_TIERS = table.freeze({
	{ key = "Weapon25", upTo = 60, robux = 25 },
	{ key = "Weapon49", upTo = 200, robux = 49 },
	{ key = "Weapon99", upTo = 500, robux = 99 },
	{ key = "Weapon199", upTo = math.huge, robux = 199 },
})
-- BUY shows only for a weapon still this many takedowns away or more: one nearly earned is never
-- sold (the bar says how close it is). Client and server read it.
local BUY_MIN_LEFT = 15
local function canBuy(toy: Toy, takedowns: number): boolean
	return toy.unlockAt > 0 and toy.unlockAt - takedowns >= BUY_MIN_LEFT
end

local function priceTier(toy: Toy): { key: string, upTo: number, robux: number }?
	if toy.unlockAt <= 0 then
		return nil
	end
	for _, tier in PRICE_TIERS do
		if toy.unlockAt <= tier.upTo then
			return tier
		end
	end
	return nil
end

for _, id in DEFAULT_LOADOUT do
	assert(byId[id], "default loadout names an unknown tool " .. id)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	categories = table.freeze(CATEGORIES),
	defaultLoadout = table.freeze(DEFAULT_LOADOUT),
	priceTiers = PRICE_TIERS,
	priceTier = priceTier,
	canBuy = canBuy,
	BUY_MIN_LEFT = BUY_MIN_LEFT,
	SLOTS = SLOTS,
	default = "Blaster",
	-- Rules both sides use (the server enforces them, the client checks first to answer at once).
	REACH = 300, -- studs from your avatar to where a tool is used
	UNLOCK_FALLBACK = 25, -- s after SPAWN: the catalog opens even without a first big moment
	-- How many tools are open from the start (the rest are earned with takedowns).
	starterCount = function(): number
		local n = 0
		for _, toy in list do
			if ((toy :: any).unlockAt or 0) <= 0 then
				n += 1
			end
		end
		return n
	end,
})
