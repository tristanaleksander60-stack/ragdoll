--!strict
-- V9-0d (owner, 21 Nov 2026: "the ground glitches when you look round, because of all the gravel
-- stones I think"): finds flat parts that overlap with their top faces closer than GAP studs, the
-- z-fighting that shimmers when the camera turns. Pure geometry over a list of parts: T156 and the
-- Studio check read it. Only flat, visible, roughly level parts count (a floor, a slab, a stone, a
-- verge, a rug): no tall props.

local ZFight = {}

ZFight.GAP = 0.06 -- studs between two top faces that still flicker
ZFight.FLAT = 1.2 -- a part thicker than this is a prop, not a ground layer
ZFight.MIN = 1.5 -- studs: a ground layer is at least this wide both ways (a rim tile or a flower is no ground)

-- The top face's height and its footprint (centre, half sizes, rotation about Y) of a level part.
local function topOf(p: BasePart): (number?, Vector2?, Vector2?, number?)
	local up = p.CFrame.UpVector
	local size = p.Size
	local round = p:IsA("Part") and p.Shape == Enum.PartType.Cylinder
	if round then
		-- (A flat disc: a cylinder whose axis, its X, stands up.)
		local axis = p.CFrame.RightVector
		if math.abs(axis.Y) < 0.98 or size.X > ZFight.FLAT or size.Y < ZFight.MIN then
			return nil
		end
		return p.Position.Y + size.X / 2, Vector2.new(p.Position.X, p.Position.Z), Vector2.new(size.Y / 2, size.Y / 2), 0
	end
	if math.abs(up.Y) < 0.98 or size.Y > ZFight.FLAT or size.X < ZFight.MIN or size.Z < ZFight.MIN then
		return nil
	end
	local look = p.CFrame.LookVector
	return p.Position.Y + size.Y / 2, Vector2.new(p.Position.X, p.Position.Z), Vector2.new(size.X / 2, size.Z / 2), math.atan2(look.X, look.Z)
end

-- Whether two footprints overlap (by a margin inside both): a sample grid of a's footprint in b's.
local function overlap(ca: Vector2, ha: Vector2, ra: number, cb: Vector2, hb: Vector2, rb: number): boolean
	if (ca - cb).Magnitude > ha.Magnitude + hb.Magnitude then
		return false
	end
	local ca_, sa = math.cos(ra), math.sin(ra)
	local cb_, sb = math.cos(rb), math.sin(rb)
	for i = -1, 1 do
		for j = -1, 1 do
			local lx, lz = i * ha.X * 0.8, j * ha.Y * 0.8
			local w = ca + Vector2.new(lx * ca_ + lz * sa, -lx * sa + lz * ca_)
			local d = w - cb
			local bx, bz = d.X * cb_ - d.Y * sb, d.X * sb + d.Y * cb_
			if math.abs(bx) < hb.X * 0.95 and math.abs(bz) < hb.Y * 0.95 then
				return true
			end
		end
	end
	return false
end

-- The pairs of parts in `parts` whose top faces are within GAP of each other where they overlap.
function ZFight.pairs(parts: { BasePart }, limit: number?): { { BasePart } }
	local tops = {}
	for _, p in parts do
		if p.Transparency < 0.9 then
			local y, c, h, r = topOf(p)
			if y then
				table.insert(tops, { p = p, y = y, c = c :: Vector2, h = h :: Vector2, r = r :: number })
			end
		end
	end
	table.sort(tops, function(a, b)
		return a.c.X < b.c.X
	end)
	local out: { { BasePart } } = {}
	for i = 1, #tops do
		local a = tops[i]
		for j = i + 1, #tops do
			local b = tops[j]
			if b.c.X - a.c.X > a.h.Magnitude + b.h.Magnitude + 1 then
				break
			end
			if math.abs(a.y - b.y) < ZFight.GAP and overlap(a.c, a.h, a.r, b.c, b.h, b.r) then
				table.insert(out, { a.p, b.p })
				if limit and #out >= limit then
					return out
				end
			end
		end
	end
	return out
end

return ZFight
