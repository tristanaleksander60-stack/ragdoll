--!strict
-- What happens on the calendar (round 3, M9). Pure: the servers act on it, every screen counts down
-- with it, the self-tests check it. All times are UTC (os.time()).
--   The weekly ADMIN SHOW: every Saturday at 18:00 UTC (19:00 in Denmark in winter) every server
--   gets three free events for everyone in a row, counted down on every screen from LEAD s before.
--   The FREE WEEKEND: from Friday 00:00 to Sunday 23:59 UTC one weapon you would otherwise unlock
--   or buy is free to use for everyone, a different one each week (it is never kept: nothing saved).
--   The LAUNCH: the owner can make every pass free for everyone until a date (AdminService).

local Schedule = {}

Schedule.SHOW = table.freeze({ weekday = 7, hour = 18, minute = 0 }) -- (os.date wday: 1 = Sunday)
Schedule.SHOW_LEAD = 600 -- s of countdown before it
Schedule.SHOW_EVENTS = table.freeze({ "DummyRain", "ZeroG", "MegaBomb" })
Schedule.SHOW_GAP = 45 -- s between its events
Schedule.SHOW_LENGTH = 150 -- s the show is "on" (its events and a little after)
Schedule.WEEKEND_DAYS = table.freeze({ [6] = true, [7] = true, [1] = true }) -- Friday, Saturday, Sunday

local WEEK = 7 * 86400

-- The start (os.time) of the show running now or the next one.
function Schedule.nextShow(now: number): number
	local d = os.date("!*t", now) :: any
	local daysAhead = (Schedule.SHOW.weekday - d.wday) % 7
	local midnight = now - (d.hour * 3600 + d.min * 60 + d.sec)
	local start = midnight + daysAhead * 86400 + Schedule.SHOW.hour * 3600 + Schedule.SHOW.minute * 60
	if start + Schedule.SHOW_LENGTH <= now then
		start += WEEK
	end
	return start
end

-- Whether a time is in the free weekend.
function Schedule.isWeekend(now: number): boolean
	local d = os.date("!*t", now) :: any
	return Schedule.WEEKEND_DAYS[d.wday] == true
end

-- The week's free weapon, from a list of ids (the same in every server; a new one each week).
function Schedule.weekendPick(now: number, ids: { string }): string?
	if #ids == 0 then
		return nil
	end
	local week = math.floor((now + 3 * 86400) / WEEK) -- (weeks counted from a Monday)
	return ids[(week % #ids) + 1]
end

return Schedule
