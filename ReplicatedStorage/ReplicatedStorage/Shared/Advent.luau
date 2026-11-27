--!strict
-- AUDIT 27 Nov 2: the CHRISTMAS ADVENT CALENDAR (Config.ADVENT; Systems/AdventService, Client/AdventCalendar).
-- 24 doors in December 2026. Every UTC day from 1 December you may open ONE door: the next one not yet open, so a
-- missed day is never lost (you catch up one a day, until 31 December). The rewards are fixed and shown in advance.
-- Kept in the profile's eco.codes set (no new field): "ADV26-<door>" = that door is open, "ADV26-T<day>" = a door was
-- opened on that December day. Free for everyone; nothing is sold here.

local Advent = {}

Advent.YEAR = 2026
Advent.MONTH = 12
Advent.LAST_DAY = 31 -- (catching up allowed until the end of December)
Advent.TAG = "ADV26-"

export type Door = { bolts: number?, cosmetic: string?, hours: number?, egg: boolean?, text: string, glyph: string }

-- cosmetic: a map-shop key (Shop.OFFERS map items) given as a timed gift in eco.perks (like a code's cosmetic).
Advent.DOORS = table.freeze({
	{ bolts = 100, text = "100 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 100, text = "100 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 150, text = "150 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 100, text = "100 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 150, text = "150 BOLTS", glyph = "\u{1F529}" },
	{ cosmetic = "RainbowTrail", hours = 72, bolts = 50, text = "Rainbow Trail for 3 days + 50 BOLTS", glyph = "\u{1F308}" },
	{ bolts = 150, text = "150 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 150, text = "150 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 200, text = "200 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 150, text = "150 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 200, text = "200 BOLTS", glyph = "\u{1F529}" },
	{ cosmetic = "FireTrail", hours = 72, bolts = 50, text = "Fire Trail for 3 days + 50 BOLTS", glyph = "\u{1F525}" },
	{ bolts = 200, text = "200 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 200, text = "200 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 250, text = "250 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 200, text = "200 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 250, text = "250 BOLTS", glyph = "\u{1F529}" },
	{ egg = true, text = "A free weapon egg", glyph = "\u{1F95A}" },
	{ bolts = 250, text = "250 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 300, text = "300 BOLTS", glyph = "\u{1F529}" },
	{ cosmetic = "CrashSuit", hours = 72, bolts = 100, text = "Crash-Test Suit for 3 days + 100 BOLTS", glyph = "\u{1F9BA}" },
	{ bolts = 300, text = "300 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 400, text = "400 BOLTS", glyph = "\u{1F529}" },
	{ bolts = 1000, egg = true, cosmetic = "GoldDummies", hours = 168, text = "CHRISTMAS EVE: 1,000 BOLTS, a weapon egg and Gold Dummies for 7 days", glyph = "\u{1F381}" },
} :: { Door })

-- The December day (1..31) at UTC time `t`, or nil outside December of YEAR.
function Advent.dayOf(t: number): number?
	local d = os.date("!*t", math.floor(t)) :: any
	if d.year ~= Advent.YEAR or d.month ~= Advent.MONTH or d.day > Advent.LAST_DAY then
		return nil
	end
	return d.day
end

-- How many doors are open in a codes set.
function Advent.opened(codes: { [string]: boolean }): number
	local n = 0
	for i = 1, #Advent.DOORS do
		if codes[Advent.TAG .. i] then
			n = i
		else
			break
		end
	end
	return n
end

-- The door that may be opened now (nil: none today). `day` from dayOf.
function Advent.next(codes: { [string]: boolean }, day: number?): number?
	if not day then
		return nil
	end
	if codes[Advent.TAG .. "T" .. day] then
		return nil -- (one door a day)
	end
	local n = Advent.opened(codes) + 1
	if n > #Advent.DOORS or n > day then
		return nil
	end
	return n
end

return Advent
