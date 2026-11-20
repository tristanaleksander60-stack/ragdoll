--!strict
-- V8-3.4 (a reason for tomorrow): the next day adds one; one missed day a week is forgiven by a
-- freeze (once a week); two missed days start over; the same day changes nothing; tomorrow's prize
-- is named; a profile keeps freezeWeek through clean().

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local DailyGoals = require(Shared:WaitForChild("DailyGoals")) :: any
local ProgressService = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("ProgressService")) :: any

return {
	name = "T137_Streak",
	timeout = 10,
	run = function(): string?
		if not Config.STREAK_V8 then
			return "skipped (STREAK_V8 off)"
		end
		local day = 20000
		local s, f = DailyGoals.nextStreak(day - 1, 4, day, 0)
		assert(s == 5 and not f, "the next day did not add one")
		s, f = DailyGoals.nextStreak(day - 2, 4, day, 0)
		assert(s == 5 and f, "one missed day was not forgiven")
		s, f = DailyGoals.nextStreak(day - 2, 4, day, day // 7)
		assert(s == 1 and not f, "a second freeze in one week was given")
		s = DailyGoals.nextStreak(day - 3, 4, day, 0)
		assert(s == 1, "two missed days did not start over")
		s = DailyGoals.nextStreak(day, 4, day, 0)
		assert(s == 4, "the same day changed the streak")
		local weapon, eggs = DailyGoals.tomorrowOf(1)
		assert(weapon == "AK" and eggs >= 1, "tomorrow after day 1 is not the AK day")
		local p = ProgressService.clean({ takedowns = 3, lastDay = day, streak = 2, freezeWeek = day // 7 })
		assert(p.freezeWeek == day // 7, "clean() lost freezeWeek")
		return "next day +1, one missed day a week forgiven, two missed start over, tomorrow named, freezeWeek kept"
	end,
}
