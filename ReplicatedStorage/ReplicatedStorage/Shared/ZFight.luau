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
	for i = -2, 2 do
		for j = -2, 2 do
			local lx, lz = i * ha.X * 0.45, j * ha.Y * 0.45 -- (a 5 x 5 grid: a wedge where two slabs meet at a bend is found too)
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
-- `only` (optional): keep just the pairs with at least one of these parts (PathBuilder.unflicker).
function ZFight.pairs(parts: { BasePart }, limit: number?, only: { [BasePart]: any }?): { { BasePart } }
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
	-- (V9-0d review: the scan stops at the widest footprint of all, not the next one's: a big floor whose
	-- middle lies far along X still overlaps.)
	local widest = 0
	for _, t in tops do
		widest = math.max(widest, t.h.Magnitude)
	end
	local out: { { BasePart } } = {}
	for i = 1, #tops do
		local a = tops[i]
		for j = i + 1, #tops do
			local b = tops[j]
			if b.c.X - a.c.X > a.h.Magnitude + widest + 1 then
				break
			end
			-- (Both ways: a small stone on a big floor has none of the floor's sample points inside it.)
			if only and not (only[a.p] or only[b.p]) then
				continue
			end
			if math.abs(a.y - b.y) < ZFight.GAP and (overlap(a.c, a.h, a.r, b.c, b.h, b.r) or overlap(b.c, b.h, b.r, a.c, a.h, a.r)) then
				table.insert(out, { a.p, b.p })
				if limit and #out >= limit then
					return out
				end
			end
		end
	end
	return out
end

-- How far to lift each of `movable` (studs, a multiple of `step`, at most `maxSteps` of them) so its
-- top face lies at least GAP + a hair from every part it overlaps: `movable` in its given order, each
-- read against `fixed` and against the movable ones already settled. One pass, no rounds: a later
-- piece always finds a free height (V9-0d review: lifting in rounds could swing back and forth).
function ZFight.lifts(movable: { BasePart }, fixed: { BasePart }, step: number, maxSteps: number): { [BasePart]: number }
	type Item = { p: BasePart, y: number, c: Vector2, h: Vector2, r: number }
	local small: { Item } = {}
	local big: { Item } = {}
	local byPart: { [BasePart]: Item } = {}
	local function add(p: BasePart)
		if byPart[p] or p.Transparency >= 0.9 then
			return
		end
		local y, c, h, r = topOf(p)
		if y then
			local item: Item = { p = p, y = y, c = c :: Vector2, h = h :: Vector2, r = r :: number }
			byPart[p] = item
			table.insert(if item.h.Magnitude > 40 then big else small, item)
		end
	end
	for _, p in movable do
		add(p)
	end
	for _, p in fixed do
		add(p)
	end
	table.sort(small, function(a, b)
		return a.c.X < b.c.X
	end)
	local widest = 0
	for _, t in small do
		widest = math.max(widest, t.h.Magnitude)
	end
	local lift: { [BasePart]: number } = {}
	local reach = (maxSteps + 1) * step + ZFight.GAP
	local isMovable: { [BasePart]: boolean } = {}
	for _, p in movable do
		isMovable[p] = true
	end
	for _, p in movable do
		local m = byPart[p]
		if not m then
			continue
		end
		local tops: { number } = {}
		local function consider(n: Item)
			if n.p == m.p or math.abs(n.y - m.y) > reach then
				return
			end
			-- (A movable piece not settled yet adapts to this one later: only fixed and settled ones count.)
			if isMovable[n.p] and lift[n.p] == nil then
				return
			end
			if overlap(m.c, m.h, m.r, n.c, n.h, n.r) or overlap(n.c, n.h, n.r, m.c, m.h, m.r) then
				table.insert(tops, n.y + (lift[n.p] or 0))
			end
		end
		for _, n in big do
			consider(n)
		end
		-- (The small ones near it along X: a binary search to the window's start.)
		local lo, hi = 1, #small
		local from = m.c.X - m.h.Magnitude - widest - 1
		while lo < hi do
			local mid = (lo + hi) // 2
			if small[mid].c.X < from then
				lo = mid + 1
			else
				hi = mid
			end
		end
		for j = lo, #small do
			local n = small[j]
			if n.c.X > m.c.X + m.h.Magnitude + widest + 1 then
				break
			end
			consider(n)
		end
		local chosen = maxSteps * step
		for k = 0, maxSteps do
			local t = m.y + k * step
			local free = true
			for _, other in tops do
				if math.abs(t - other) < ZFight.GAP + 0.005 then
					free = false
					break
				end
			end
			if free then
				chosen = k * step
				break
			end
		end
		lift[m.p] = chosen
	end
	return lift
end

return ZFight
