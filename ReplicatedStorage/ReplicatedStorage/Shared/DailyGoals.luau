--!strict
-- The day's three small goals and the 7-day streak (round 3, M9). Pure: the server counts and pays
-- (ProgressService), every screen shows the same goals, the self-tests check the picks.
--   Each UTC day has three goals, the same for everyone (picked from POOL by the day's number).
--   A goal done: CLAIM it for an egg. All three claimed: a bonus egg.
--   The daily egg follows a 7-day streak: STREAK_EGGS[day of the week of the streak], again
--   from day 1 after day 7 (a missed day starts over).

local DailyGoals = {}

export type Kind = "Takedowns" | "Minutes" | "Eggs" | "Trips" | "Combo" | "Arena"
export type Goal = { kind: Kind, need: number, text: string }

-- What can be asked, and how much (one of `need` is picked). "max" kinds count the best of the
-- day (a combo), the others add up.
DailyGoals.POOL = table.freeze({
	{ kind = "Takedowns" :: Kind, need = { 15, 25, 40 }, text = "KO %d ragdolls" },
	{ kind = "Minutes" :: Kind, need = { 10, 15, 20 }, text = "Play %d minutes" },
	{ kind = "Eggs" :: Kind, need = { 1, 2 }, text = "Open %d egg%s" },
	{ kind = "Trips" :: Kind, need = { 2, 3 }, text = "Visit %d places" },
	{ kind = "Combo" :: Kind, need = { 5, 8 }, text = "Get a combo of %d" },
	{ kind = "Arena" :: Kind, need = { 1, 2 }, text = "Play %d arena round%s" },
})
-- V9-0s: no arena goals while the Game Arena is hidden (Config.ARENA_ENABLED).
if not (require(script.Parent:WaitForChild("Config")) :: any).ARENA_ENABLED then
	local kept = {}
	for _, goal in DailyGoals.POOL do
		if goal.kind ~= "Arena" then
			table.insert(kept, goal)
		end
	end
	DailyGoals.POOL = table.freeze(kept)
end
DailyGoals.MAX_KINDS = table.freeze({ Combo = true }) :: { [string]: boolean }
DailyGoals.COUNT = 3
DailyGoals.EGGS_PER_GOAL = 1
DailyGoals.BONUS_EGGS = 1
DailyGoals.STREAK_EGGS = table.freeze({ 1, 1, 2, 1, 1, 2, 3 })
-- Round 5: two days of the week are a named weapon on top (the REWARDS calendar shows them; one
-- you have already is an extra egg instead).
DailyGoals.STREAK_WEAPONS = table.freeze({ [2] = "AK", [7] = "Minigun" }) :: { [number]: string }

-- The weapon day `streak` of the streak gives (nil: eggs only).
function DailyGoals.streakWeapon(streak: number): string?
	local i = ((math.max(1, streak) - 1) % #DailyGoals.STREAK_EGGS) + 1
	return DailyGoals.STREAK_WEAPONS[i]
end

-- The UTC day number of a server time (os.time()).
function DailyGoals.dayOf(time: number): number
	return math.floor(time / 86400)
end

local function textOf(entry: any, need: number): string
	return string.format(entry.text, need, if need == 1 then "" else "s")
end

-- The day's three goals (different kinds), the same in every server.
function DailyGoals.forDay(day: number): { Goal }
	local rng = Random.new(day * 7919 + 17)
	local order = {}
	for i = 1, #DailyGoals.POOL do
		order[i] = i
	end
	for i = #order, 2, -1 do
		local j = rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local goals = {}
	for k = 1, DailyGoals.COUNT do
		local entry = DailyGoals.POOL[order[k]]
		local need = entry.need[rng:NextInteger(1, #entry.need)]
		goals[k] = { kind = entry.kind, need = need, text = textOf(entry, need) }
	end
	return goals
end

-- Eggs for a daily visit on day `streak` of the streak (1, 2, ...).
-- V8-3.4 (a reason for tomorrow, Config.STREAK_V8): the streak after a claim on UTC day `today`,
-- given the last claimed day and the week (today // 7) a freeze was last used. One missed day a week
-- is forgiven by a freeze. Returns the new streak and whether a freeze was used.
function DailyGoals.nextStreak(lastDay: number, streak: number, today: number, freezeWeek: number): (number, boolean)
	local gap = today - lastDay
	if gap <= 0 then
		return streak, false
	elseif gap == 1 then
		return streak + 1, false
	elseif gap == 2 and streak > 0 and freezeWeek < today // 7 then
		return streak + 1, true
	end
	return 1, false
end

-- What tomorrow's claim brings, for the "TOMORROW" line: a weapon id or nil, and the eggs.
function DailyGoals.tomorrowOf(streak: number): (string?, number)
	return DailyGoals.streakWeapon(streak + 1), DailyGoals.streakEggs(streak + 1)
end

function DailyGoals.streakEggs(streak: number): number
	local i = ((math.max(1, streak) - 1) % #DailyGoals.STREAK_EGGS) + 1
	return DailyGoals.STREAK_EGGS[i]
end

return DailyGoals
