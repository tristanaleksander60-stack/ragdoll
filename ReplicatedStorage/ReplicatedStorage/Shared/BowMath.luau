--!strict
-- V9-NOW 23 (owner, 21 Nov 2026: "a bow on the start bar"): the Bow's numbers, pure (the client draws and flies the
-- arrow with them, the server caps the draw with them, the tests check them).
--   draw  0..1: how far the string is back (FULL_DRAW s of holding = 1)
--   a short draw is a soft, slow, high arc; a full draw a hard, fast, long, flat shot

local BowMath = {}

BowMath.FULL_DRAW = 1.2 -- s to full draw
BowMath.MIN_DRAW = 0.12 -- below this the arrow just drops at your feet
BowMath.SPEED_MIN = 55 -- studs/s at the lightest draw
BowMath.SPEED_MAX = 210 -- studs/s at full draw
BowMath.GRAVITY = 110 -- studs/s^2 on the arrow (a little under the world's: arrows read better)
BowMath.LIFT_MIN = 0.32 -- a light draw is aimed this much higher (a lob), a full one straight
BowMath.WOBBLE_AFTER = 3 -- s held at full draw before the aim starts to wobble
BowMath.WOBBLE_DEG = 1.6
BowMath.FLY_MAX = 3 -- s an arrow flies at most
BowMath.SERVER_SLACK = 0.1 -- draw the server allows over what the held time gives (lag)

-- How far the string is back after `held` seconds.
function BowMath.drawOf(held: number): number
	return math.clamp(held / BowMath.FULL_DRAW, 0, 1)
end

function BowMath.speedOf(draw: number): number
	return BowMath.SPEED_MIN + (BowMath.SPEED_MAX - BowMath.SPEED_MIN) * math.clamp(draw, 0, 1)
end

-- What a round of this draw does, against a pistol's: the wound and the push.
function BowMath.woundScale(draw: number): number
	return 0.45 + 0.8 * math.clamp(draw, 0, 1)
end
function BowMath.pushScale(draw: number): number
	return 0.5 + 1.1 * math.clamp(draw, 0, 1)
end

-- The arrow's first velocity for an aim direction (a light draw lobs: aimed higher).
function BowMath.launch(aim: Vector3, draw: number): Vector3
	local d = if aim.Magnitude > 1e-3 then aim.Unit else Vector3.new(0, 0, -1)
	local lift = BowMath.LIFT_MIN * (1 - math.clamp(draw, 0, 1))
	return (d + Vector3.new(0, lift, 0)).Unit * BowMath.speedOf(draw)
end

-- Where the arrow is `t` s after leaving `from` with velocity `v`.
function BowMath.at(from: Vector3, v: Vector3, t: number): Vector3
	return from + v * t + Vector3.new(0, -0.5 * BowMath.GRAVITY * t * t, 0)
end

-- The most draw the server accepts for a string held `held` s (nil: no draw was seen: a light one only).
function BowMath.serverCap(held: number?): number
	if not held then
		return 0.25
	end
	return math.clamp(BowMath.drawOf(held) + BowMath.SERVER_SLACK, BowMath.MIN_DRAW, 1)
end

-- How far an arrow of this draw can land from where it left (flat ground, launched level): the reach check.
function BowMath.reach(draw: number): number
	local v = BowMath.speedOf(draw)
	return v * BowMath.FLY_MAX + 10
end

return BowMath
