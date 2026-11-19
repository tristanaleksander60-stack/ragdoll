--!strict
-- The Christmas theme's season (round 3, M7). The owner's words: on from now until 6 January, and
-- he can switch it on and off himself. Every later year: 1 December to 6 January.
--   "auto"  the season decides (the default)
--   "on"    on whatever the date
--   "off"   off whatever the date
-- Pure (the self-tests check the dates); ChristmasService keeps the owner's choice and sets the
-- Workspace attribute "Christmas" every screen reads.

local Christmas = {}

export type Mode = "auto" | "on" | "off"
Christmas.MODES = { "auto", "on", "off" } :: { Mode }

-- The first season starts the day the owner asked for it.
-- (Phase 3, Config.CHRISTMAS_FROM_DEC1: from 1 December 2026 instead of 7 November.)
local Config = require(script.Parent:WaitForChild("Config"))
Christmas.FIRST_START = if Config.CHRISTMAS_FROM_DEC1 then { year = 2026, month = 12, day = 1 } else { year = 2026, month = 11, day = 7 }
Christmas.SEASON_START = { month = 12, day = 1 } -- every year after the first
Christmas.SEASON_END = { month = 1, day = 6 } -- (the last day it is on, inclusive)

local function dayOf(year: number, month: number, day: number): number
	return year * 400 + month * 32 + day -- (ordering only)
end

-- Whether the season is on at a UTC date (os.date("!*t") fields).
function Christmas.inSeason(date: { year: number, month: number, day: number }): boolean
	local y, m, d = date.year, date.month, date.day
	-- Up to and including 6 January: the season that began the year before.
	local first = Christmas.FIRST_START
	if dayOf(0, m, d) <= dayOf(0, Christmas.SEASON_END.month, Christmas.SEASON_END.day) then
		return y > first.year -- (no season before the first one)
	end
	local startMonth, startDay = Christmas.SEASON_START.month, Christmas.SEASON_START.day
	if y == first.year then
		startMonth, startDay = first.month, first.day
	elseif y < first.year then
		return false
	end
	return dayOf(0, m, d) >= dayOf(0, startMonth, startDay)
end

-- On or off, from the owner's choice and the date.
function Christmas.isOn(mode: string?, date: { year: number, month: number, day: number }): boolean
	if mode == "on" then
		return true
	elseif mode == "off" then
		return false
	end
	return Christmas.inSeason(date)
end

function Christmas.validMode(mode: unknown): boolean
	return mode == "auto" or mode == "on" or mode == "off"
end

-- Licensed Christmas music for the radio while it is on (Creator Store, APMOfficial, free).
Christmas.TRACKS = table.freeze({
	{ id = 1839945406, name = "Jingle Bells" },
	{ id = 1838667168, name = "We Wish You A Merry Christmas" },
	{ id = 1841342574, name = "Santa Claus is Coming" },
	{ id = 1845653124, name = "Deck The Halls" },
	{ id = 1836686862, name = "Xmas Winter" },
	{ id = 9046740461, name = "Winter Holidays" },
})

return Christmas
