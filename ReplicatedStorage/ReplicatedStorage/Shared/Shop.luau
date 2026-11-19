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

return table.freeze(Shop)
