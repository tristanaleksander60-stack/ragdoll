--!strict
-- Round 3, M9: what brings players back, and the last of the plan.
--   the day's goals: three of different kinds, the same for everyone on a day, a new set the next
--     day; counted (a "max" kind by its best); CLAIM gives an egg once, only when done, never past
--     full egg slots; all three claimed: a bonus egg; two servers' goals merge (the later day,
--     else the most of each)
--   the daily egg on the 7-day calendar 1 1 2 1 1 2 3, again from day 1 after day 7
--   the weekly ADMIN SHOW: counted down from 10 minutes before, three free events queued at the
--     start, once; the free weekend: one earnable weapon usable by anyone Friday-Sunday (not for the
--     shop's "yours already"), a new one each week, none on a weekday
--   the launch: the owner's free passes (3/7/14 days or off, junk refused, owner only) give
--     everyone ULTRA's no-wait while on, and it ends; an older choice from another server never
--     takes over
--   the Metro Station is built with its train, tracks and gates; the new building pieces exist
--   the bar: a locked tool (the free weekend's weapon after Sunday) leaves it only once the
--     progress is known, never the last one (BarRules)
--   the streamer autopilot: nothing before 90 s without a gift, then a gentle action every 45 s,
--     a gift resets it, the switch turns it off

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DailyGoals = require(Shared:WaitForChild("DailyGoals"))
local Schedule = require(Shared:WaitForChild("Schedule"))
local Progress = require(Shared:WaitForChild("Progress"))
local Toys = require(Shared:WaitForChild("Toys"))
local Catalog = require(Shared:WaitForChild("Build"):WaitForChild("Catalog"))
local BarRules = require(Shared:WaitForChild("BarRules"))
local Systems = script.Parent.Parent:WaitForChild("Systems")
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local ScheduleService = require(Systems:WaitForChild("ScheduleService"))
local MoneyService = require(Systems:WaitForChild("MoneyService"))
local AdminService = require(Systems:WaitForChild("AdminService"))
local EventService = require(Systems:WaitForChild("EventService"))
local StreamerService = require(Systems:WaitForChild("StreamerService"))
local OwnerSetting = require(Systems:WaitForChild("OwnerSetting"))
local Owner = require(Systems:WaitForChild("Owner"))

local function utc(y: number, m: number, d: number, h: number, mi: number): number
	-- (os.time reads a table as local time; the offset from UTC put back.)
	local t = os.time({ year = y, month = m, day = d, hour = h, min = mi, sec = 0 })
	local back = os.date("!*t", t) :: any
	local drift = os.time({ year = back.year, month = back.month, day = back.day, hour = back.hour, min = back.min, sec = back.sec }) - t
	return t - drift
end

local function goalsPure(results: { string })
	local a, b, c = DailyGoals.forDay(20400), DailyGoals.forDay(20400), DailyGoals.forDay(20401)
	assert(#a == 3, #a .. " goals")
	local kinds: { [string]: boolean } = {}
	for i, g in a do
		assert(not kinds[g.kind], "two goals of one kind: " .. g.kind)
		kinds[g.kind] = true
		assert(g.kind == b[i].kind and g.need == b[i].need, "the same day gave other goals")
		assert(#g.text <= 26, "a goal's text is long: " .. g.text)
	end
	local same = true
	for i = 1, 3 do
		if a[i].kind ~= c[i].kind or a[i].need ~= c[i].need then
			same = false
		end
	end
	-- (Another day may rarely pick the same set; three days in a row never all do.)
	local d = DailyGoals.forDay(20402)
	assert(not same or d[1].kind ~= a[1].kind or d[2].kind ~= a[2].kind, "the goals never change from day to day")
	local cal = {}
	for streak = 1, 9 do
		table.insert(cal, DailyGoals.streakEggs(streak))
	end
	assert(table.concat(cal, " ") == "1 1 2 1 1 2 3 1 1", "the calendar is " .. table.concat(cal, " "))
	table.insert(results, string.format("goals: 3 kinds a day, the same for everyone (%s / %s / %s), others the next day; the calendar %s", a[1].text, a[2].text, a[3].text, table.concat(cal, " ")))
end

local function goalsLive(results: { string }, p: Player)
	local profile = ProgressService.profileForTest(p) :: any
	assert(profile, "no profile")
	local eggsBefore = profile.eggs
	local lastDayBefore, streakBefore = profile.lastDay, profile.streak
	local day = 30000
	ProgressService.clockForTest = function()
		return day * 86400 + 3600
	end
	local ok, err = pcall(function()
		profile.goals = nil
		profile.eggs = 0
		local goals = DailyGoals.forDay(day)
		-- Count each goal to just under, then to done.
		for i, g in goals do
			ProgressService.goal(p, g.kind, if DailyGoals.MAX_KINDS[g.kind] then g.need - 1 else g.need - 1)
			assert(not ProgressService.claimGoal(p, i), "a goal not done was claimed")
			ProgressService.goal(p, g.kind, if DailyGoals.MAX_KINDS[g.kind] then g.need else 1)
		end
		local view = ProgressService.goalsView(p) :: any
		for i, g in view.list do
			assert(g.got == g.need, string.format("goal %d counted %d of %d", i, g.got, g.need))
		end
		assert(not ProgressService.claimGoal(p, 4), "the bonus before the three")
		assert(ProgressService.claimGoal(p, 1) and profile.eggs == 1, "a done goal gave no egg")
		assert(not ProgressService.claimGoal(p, 1) and profile.eggs == 1, "a goal claimed twice")
		profile.eggs = Progress.MAX_EGGS
		assert(not ProgressService.claimGoal(p, 2) and profile.eggs == Progress.MAX_EGGS, "a goal paid past full slots")
		profile.eggs = 1
		assert(ProgressService.claimGoal(p, 2) and ProgressService.claimGoal(p, 3) and profile.eggs == 3, "goals 2 and 3 gave no eggs")
		assert(ProgressService.claimGoal(p, 4) and profile.eggs == 4 and not ProgressService.claimGoal(p, 4), "the bonus egg (once)")
		assert(not ProgressService.claimGoal(p, 0) and not ProgressService.claimGoal(p, 2.5) and not ProgressService.claimGoal(p, "1" :: any), "junk claims")
		-- A new day: fresh goals.
		day += 1
		local fresh = ProgressService.goalsView(p) :: any
		assert(fresh.day == day and fresh.list[1].got == 0 and not fresh.list[1].claimed and not fresh.bonus, "a new day kept yesterday's goals")
		-- Two servers.
		local m = ProgressService.mergeGoals({ day = 5, p = { 3, 0, 1 }, claimed = { true, false, false }, bonus = false }, { day = 5, p = { 1, 4, 1 }, claimed = { false, false, true }, bonus = false }) :: any
		assert(m.p[1] == 3 and m.p[2] == 4 and m.claimed[1] and m.claimed[3] and not m.claimed[2], "the same day's goals did not merge")
		local later = ProgressService.mergeGoals({ day = 5, p = { 9, 9, 9 }, claimed = { true, true, true }, bonus = true }, { day = 6, p = { 0, 0, 0 }, claimed = { false, false, false }, bonus = false }) :: any
		assert(later.day == 6 and later.p[1] == 0, "an older day won the merge")
		-- The calendar through daily().
		-- (Round 5: days 2 and 7 also name a weapon; one already earned or owned is an extra egg.)
		local function expect(streak: number): number
			local id = DailyGoals.streakWeapon(streak)
			local toy = id and Toys.byId[id]
			local extra = if toy and (profile.owned[toy.id] or profile.takedowns >= toy.unlockAt) then 1 else 0
			return math.min(DailyGoals.streakEggs(streak) + extra, Progress.MAX_EGGS - profile.eggs)
		end
		profile.lastDay, profile.streak = 2000, 6
		local want7 = expect(7)
		local gotMinigun = profile.owned.Minigun ~= true and profile.takedowns < Toys.byId.Minigun.unlockAt
		assert(ProgressService.daily(p, 2001) == want7 and profile.streak == 7, "day 7 of the streak gave not " .. want7)
		if gotMinigun then
			profile.owned.Minigun = nil -- (given for the day: taken back, the test's player keeps what it had)
		end
		assert(ProgressService.daily(p, 2002) == 1 and profile.streak == 8, "day 8 did not start the calendar again")
		-- Midnight while playing: the new day's egg comes without a rejoin (and only once).
		local realToday = math.floor(os.time() / 86400)
		profile.lastDay, profile.streak = realToday - 1, 1
		local eggsNow = profile.eggs
		local want2 = expect(2)
		local hadAK = profile.owned.AK
		assert(ProgressService.checkNewDay(p) == want2 and profile.lastDay == realToday and profile.streak == 2 and profile.eggs == eggsNow + want2, "midnight in a session gave no daily egg")
		profile.owned.AK = hadAK
		assert(ProgressService.checkNewDay(p) == 0, "the daily egg twice in one day")
		-- Full slots: the day's egg waits (the streak with it) and comes once there is room.
		profile.lastDay, profile.streak = realToday - 1, 1
		profile.eggs = Progress.MAX_EGGS
		assert(ProgressService.checkNewDay(p) == 0 and profile.lastDay == realToday - 1 and profile.streak == 1 and profile.eggs == Progress.MAX_EGGS, "a daily egg past full slots was given or lost")
		profile.eggs = Progress.MAX_EGGS - 1
		assert(ProgressService.checkNewDay(p) == 1 and profile.lastDay == realToday and profile.streak == 2 and profile.eggs == Progress.MAX_EGGS, "the daily egg that waited did not come with room")
	end)
	ProgressService.clockForTest = nil
	profile.goals = nil
	profile.eggs = eggsBefore
	profile.lastDay, profile.streak = lastDayBefore, streakBefore
	assert(ok, err)
	table.insert(results, "counted to done (not before), an egg each once, none past full slots, the bonus once after all three, junk refused; a new day starts fresh; two servers merge; streak day 7 gives 3, day 8 starts over; midnight in a session gives that day's egg once; with full slots it waits, then comes")
end

local function schedule(results: { string }, p: Player?)
	-- 2026-11-14 is a Saturday.
	local sat = utc(2026, 11, 14, 17, 59)
	local start = utc(2026, 11, 14, 18, 0)
	assert(Schedule.nextShow(sat) == start, "the show is not today at 18:00 UTC")
	assert(Schedule.nextShow(start + 60) == start, "the show running now was not found")
	assert(Schedule.nextShow(start + Schedule.SHOW_LENGTH + 1) == start + 7 * 86400, "the next show is not a week later")
	assert(Schedule.nextShow(utc(2026, 11, 16, 9, 0)) == start + 7 * 86400 - 0, "from a Monday: not the coming Saturday")
	assert(Schedule.isWeekend(utc(2026, 11, 13, 0, 1)) and Schedule.isWeekend(utc(2026, 11, 15, 23, 59)) and not Schedule.isWeekend(utc(2026, 11, 16, 0, 1)) and not Schedule.isWeekend(utc(2026, 11, 12, 23, 59)), "the weekend is not Friday-Sunday")
	local ids = ScheduleService.weekendList()
	local w1 = Schedule.weekendPick(utc(2026, 11, 13, 9, 0), ids)
	assert(w1 == Schedule.weekendPick(utc(2026, 11, 15, 22, 0), ids), "the weekend's weapon changed within the weekend")
	assert(w1 ~= Schedule.weekendPick(utc(2026, 11, 20, 9, 0), ids), "the same weapon two weekends running")
	for _, id in ids do
		assert((Toys.byId[id] :: any).unlockAt > 0, id .. " is a starting weapon")
	end
	-- Acted on.
	EventService.holdForTest(true)
	ScheduleService.allowInTestsForTest = true
	ScheduleService.resetForTest()
	local clock = utc(2026, 11, 14, 17, 52)
	ScheduleService.clockForTest = function()
		return clock
	end
	local ok, err = pcall(function()
		ScheduleService.tick()
		assert(Workspace:GetAttribute("AdminShowAt") == start, "no countdown 8 minutes before")
		local free = Workspace:GetAttribute("FreeWeapon")
		assert(type(free) == "string", "no free weapon on a Saturday")
		if p then
			local toy = Toys.byId[free :: string] :: any
			local wasAll = p:GetAttribute("UnlockAll")
			p:SetAttribute("UnlockAll", false)
			local profile = ProgressService.profileForTest(p) :: any
			local wasOwned, wasTakedowns = profile.owned[toy.id], profile.takedowns
			profile.owned[toy.id] = nil
			profile.takedowns = 0
			local usable = ProgressService.isUnlocked(p, toy)
			local own = ProgressService.isUnlocked(p, toy, true)
			profile.owned[toy.id], profile.takedowns = wasOwned, wasTakedowns
			p:SetAttribute("UnlockAll", wasAll)
			assert(usable and not own, "the free weapon is not usable, or the shop thinks it is owned")
		end
		clock = start + 2
		local queued = ScheduleService.tick()
		assert(#queued == 3, #queued .. " show events")
		assert(#ScheduleService.tick() == 0, "the show ran twice")
		clock = utc(2026, 11, 17, 12, 0)
		ScheduleService.tick()
		assert(Workspace:GetAttribute("FreeWeapon") == nil and Workspace:GetAttribute("AdminShowAt") == nil, "a Tuesday kept the weekend or the countdown")
	end)
	ScheduleService.clockForTest = nil
	ScheduleService.allowInTestsForTest = false
	ScheduleService.resetForTest() -- (the show's later events: called off)
	task.wait(0.1)
	EventService.clearQueue()
	EventService.holdForTest(false)
	ScheduleService.tick()
	assert(ok, err)
	table.insert(results, "the show: Saturday 18:00 UTC, counted down 8 minutes before, three events once, the next a week on; the weekend: Friday-Sunday, one weapon a week (usable by anyone, still buyable), never on a Tuesday")
end

local function launch(results: { string }, p: Player)
	local wasDelay = p:GetAttribute("ZeroDelay")
	Owner.studioOwnerForTest = false
	AdminService.resetPaceForTest(p)
	assert(not AdminService.request(p, "FreePasses", 7), "a non-owner set the free passes")
	Owner.studioOwnerForTest = true
	AdminService.resetPaceForTest(p)
	assert(not AdminService.request(p, "FreePasses", 5), "5 days was taken")
	AdminService.resetPaceForTest(p)
	assert(AdminService.request(p, "FreePasses", 3), "the owner could not set 3 days")
	local untilAt = Workspace:GetAttribute("PassesFreeUntil") :: number
	assert(type(untilAt) == "number" and math.abs(untilAt - Workspace:GetServerTimeNow() - 3 * 86400) < 5, "not 3 days from now")
	assert(MoneyService.launchFree() and p:GetAttribute("ZeroDelay") == true, "ULTRA's no-wait is not on for everyone")
	AdminService.resetPaceForTest(p)
	assert(AdminService.request(p, "FreePasses", 0), "the owner could not end it")
	assert(not MoneyService.launchFree() and Workspace:GetAttribute("PassesFreeUntil") == nil and p:GetAttribute("ZeroDelay") == wasDelay, "it did not end")
	-- An older choice from another server never takes over.
	local s = OwnerSetting.new("TestSetting", 0, function(v: unknown): boolean
		return type(v) == "number"
	end, function() end, false)
	OwnerSetting.set(s, 5)
	assert(not OwnerSetting.adoptForTest(s, { value = 9, at = s.at - 10 }) and s.value == 5, "an older choice took over")
	assert(OwnerSetting.adoptForTest(s, { value = 9, at = s.at + 10 }) and s.value == 9, "a newer choice was not taken")
	assert(not OwnerSetting.adoptForTest(s, { value = "x", at = s.at + 20 }), "junk from another server was taken")
	AdminService.resetPaceForTest(p)
	table.insert(results, "the launch: owner only, 3/7/14/off (5 refused), everyone's ULTRA no-wait on, then off again; an older or junk choice from another server never wins")
end

-- The bar after the free weekend (BarRules: what the client keeps).
local function bar(results: { string })
	local lockedSet = { Katana = true, Axe = true }
	local function locked(id: string): boolean
		return lockedSet[id] == true
	end
	local keep, gone = BarRules.prune({ "Blaster", "Katana", "Bat" }, true, locked)
	assert(#keep == 2 and keep[1] == "Blaster" and keep[2] == "Bat" and #gone == 1 and gone[1] == "Katana", "the locked weekend weapon stayed on the bar")
	local still = BarRules.prune({ "Blaster", "Katana", "Bat" }, false, locked)
	assert(#still == 3, "the bar was pruned while the progress was still unknown")
	local last = BarRules.prune({ "Katana" }, true, locked)
	assert(#last == 1, "the last tool left the bar")
	local all = BarRules.prune({ "Axe", "Katana" }, true, locked)
	assert(#all == 1, "two locked tools: one must stay")
	table.insert(results, "the bar: a locked tool leaves it once the progress is known (never while it loads), never the last one")
end

local function world(results: { string })
	local rooms = require(Systems:WaitForChild("WorldMaps")).folder()
	local metro = rooms and rooms:FindFirstChild("Metro")
	if not metro then
		-- (19 Nov: the Metro Station was removed with the other old rooms.)
		table.insert(results, "no Metro Station any more (removed 19 Nov)")
		return
	end
	for _, name in { "Rail", "CarFloor", "Gate", "Pillar", "Bench" } do
		assert(metro:FindFirstChild(name), "the Metro Station has no " .. name)
	end
	for _, id in { "BigBlock", "Pillar", "Glass", "Corner" } do
		assert(Catalog.byId[id], "no building piece " .. id)
	end
	table.insert(results, "the Metro Station built (rails, train, gates, pillars, benches); Big Block, Pillar, Glass and Corner to build with")
end

local function autopilot(results: { string }, p: Player)
	local t = 1000
	StreamerService.clockForTest = function()
		return t
	end
	local ok, err = pcall(function()
		assert(StreamerService.setOn(p, true), "streamer mode would not go on")
		-- (Its queue drains on its own beat: emptied here so only the autopilot fills it.)
		table.clear(StreamerService.queueOf(p))
		t += 60
		assert(StreamerService.autopilot(p) == nil, "the autopilot went off before 90 s")
		t += 31
		local id = StreamerService.autopilot(p)
		assert(id and table.find(StreamerService.AUTOPILOT_ACTIONS, id), "no gentle action after 90 s")
		table.clear(StreamerService.queueOf(p))
		t += 10
		assert(StreamerService.autopilot(p) == nil, "again before 45 s")
		t += 40
		assert(StreamerService.autopilot(p) ~= nil, "not again after 45 s")
		table.clear(StreamerService.queueOf(p))
		StreamerService.queue(p, "Party")
		table.clear(StreamerService.queueOf(p))
		t += 60
		assert(StreamerService.autopilot(p) == nil, "a gift did not rest it")
		StreamerService.setAutopilot(p, false)
		t += 500
		assert(StreamerService.autopilot(p) == nil, "switched off, it still ran")
		StreamerService.setAutopilot(p, true)
	end)
	StreamerService.clockForTest = nil
	table.clear(StreamerService.queueOf(p))
	StreamerService.setOn(p, false)
	assert(ok, err)
	table.insert(results, "streamer autopilot: nothing before 90 s, then every 45 s, a gift rests it, the switch stops it")
end

return {
	name = "goals-calendar-show-weekend-launch-metro-autopilot",
	timeout = 60,
	run = function(): string?
		local results = {}
		goalsPure(results)
		bar(results)
		world(results)
		local p = Players:GetPlayers()[1]
		schedule(results, p)
		if p then
			local started = os.clock()
			while not ProgressService.isLoaded(p) and os.clock() - started < 10 do
				task.wait(0.1)
			end
			task.wait(5) -- (the day's own egg, 4 s after loading, out of the way)
			goalsLive(results, p)
			launch(results, p)
			autopilot(results, p)
		else
			table.insert(results, "player checks skipped (no player)")
		end
		return table.concat(results, "; ")
	end,
}
