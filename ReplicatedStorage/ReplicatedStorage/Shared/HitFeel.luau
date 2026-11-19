--!strict
-- How a hit by hand feels, in numbers (vault: Hit Reactions; Hit-Stop and Screen Shake Tuning by
-- Numbers). Which tools are done by hand and which move each makes is on the tool itself (Toys:
-- byHand, move); this is the tuning shared by PokeController, AvatarMoves and FxController.

local HitFeel = {}

-- A tool done by hand needs you this close (walk view; in the lab view, closer than this your
-- avatar does it, further away the tool works from afar with its own visual).
HitFeel.MELEE_REACH = 9
-- During the wind-up your avatar steps in, at most this far, to land the blow from STRIKE_DISTANCE
-- (so a hit from the edge of the reach still connects instead of punching the air).
HitFeel.LUNGE_MAX = 6.5
HitFeel.STRIKE_DISTANCE = 2.8

-- Hit-stop (only for blows by hand: a ranged shot gets none, or rapid fire feels like lag): the
-- contact pose and your camera hold for this long. None for light hits, 50 ms medium, 66 heavy,
-- 75 finisher, 89 the very biggest; at most BUDGET of stops in any WINDOW.
HitFeel.STOP_BUDGET = 0.14
HitFeel.STOP_WINDOW = 0.6
local TIERS = { -- { below this speed, stop }
	{ 20, 0 },
	{ 45, 0.05 },
	{ 85, 0.066 },
	{ 120, 0.075 },
}
local TOP = 0.089

-- The hit-stop a tool's blow asks for (before the budget).
function HitFeel.stopFor(toy: { speed: number, byHand: boolean, kind: string }): number
	if not toy.byHand or toy.kind ~= "hit" then
		return 0
	end
	for _, tier in TIERS do
		if toy.speed < tier[1] then
			return tier[2]
		end
	end
	return TOP
end

return table.freeze(HitFeel)
