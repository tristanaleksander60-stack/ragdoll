--!strict
-- Global build info and switches. Read-only at runtime.

local Config = {
	GameName = "Ragdoll Havoc", -- (the owner's name for the game, 10 Nov 2026)
	-- Bumped with every change that goes live (round 5): SessionStats keeps it per visit, so the
	-- numbers of one build can be told from another's.
	Version = "0.17.2",
	Phase = 3,
	-- Heavy weapons and close blasts can cut a limb off (round 2, N2). Roblox lists severed body
	-- parts as Restricted (18+, ID-checked players only): switching this off keeps the game at a
	-- lower maturity label (purple blood counts as unrealistic) without touching anything else.
	SEVERING = true,
	-- Phase 0 (19 Nov 2026): nothing that interrupts in a new visit's first QUIET_START s: no view
	-- card, no egg window, at most one hint at a time; tips and gift notes wait until after it. On a
	-- phone LAB VIEW and RUN wait too (HudSlots.PHONE_LATER).
	QUIET_START = 90,
}

return table.freeze(Config)
