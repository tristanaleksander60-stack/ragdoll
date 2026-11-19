--!strict
-- Global build info and switches. Read-only at runtime.

local Config = {
	GameName = "Ragdoll Havoc", -- (the owner's name for the game, 10 Nov 2026)
	-- Bumped with every change that goes live (round 5): SessionStats keeps it per visit, so the
	-- numbers of one build can be told from another's.
	Version = "0.19.0", -- (0.18.0 phase 0; 0.19.0 phases 1-3, 19 Nov 2026; SessionStats also keeps game.PlaceVersion)
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
	EXPERIMENT_FIRST_AT = 30, -- s into a visit (the first-minute bar must be free too)
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
	--   CHRISTMAS_FROM_DEC1: the season starts 1 December (it was on since 7 November 2026; Santa hats
	--   in mid-November read as stale). CHRISTMAS_LAB: the chimney launcher, the present trap and the
	--   sleigh ramp in every lab while the season is on; ADVENT: a daily advent experiment 1-24 Dec.
	CHRISTMAS_FROM_DEC1 = true,
	CHRISTMAS_LAB = true,
	ADVENT = true,
	-- Update rhythm: what the title shows in an update week, and the days updates go out. The newest
	-- entry of Shop.WHATS_NEW must carry Config.Version (T67 checks it).
	UPDATE_TITLE = "[UPD] Ragdoll Havoc \u{1F4A5}",
	UPDATE_DAYS = table.freeze({ "Thursday", "Saturday" }),
	-- Extra ragdolls a device simulates for its own lab (Shared\DeviceTier: phone low, tablet and
	-- console mid, computer high).
	DEVICE_CAPS = table.freeze({
		low = table.freeze({ visitors = 1, chasers = 4 }),
		mid = table.freeze({ visitors = 2, chasers = 7 }),
		high = table.freeze({ visitors = 3, chasers = 10 }),
	}),
}

return table.freeze(Config)
