--!strict
-- The calendar acted on (round 3, M9: Shared/Schedule).
--   ADMIN SHOW: the Workspace attribute "AdminShowAt" (server time of the start) is set SHOW_LEAD
--   s before, so every screen counts down; at the start the show's events are queued, free, for
--   everyone in this server (once per show; never during the self-tests).
--   FREE WEEKEND: the Workspace attribute "FreeWeapon" names the week's free weapon from Friday to
--   Sunday (ProgressService.isUnlocked lets everyone use it; nothing is saved).
-- Checked every CHECK s; tests set the clock.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Schedule = require(Shared:WaitForChild("Schedule"))
local Toys = require(Shared:WaitForChild("Toys"))
local Log = require(Shared:WaitForChild("Log"))
local EventService = require(script.Parent.EventService)
local Metrics = require(script.Parent.Metrics)

local log = Log.new("Schedule")

local ScheduleService = {}

local CHECK = 5
ScheduleService.clockForTest = nil :: (() -> number)?
ScheduleService.allowInTestsForTest = false
local shown: { [number]: boolean } = {} -- show starts already run here
local pending: { thread } = {} -- the show's events still to come

local function now(): number
	local clock = ScheduleService.clockForTest
	return if clock then clock() else os.time()
end

-- The weapons a weekend can make free: every one earned by takedowns (never a starting one).
function ScheduleService.weekendList(): { string }
	local ids = {}
	for _, toy in Toys.list do
		if toy.unlockAt > 0 then
			table.insert(ids, toy.id)
		end
	end
	table.sort(ids)
	return ids
end

local function testing(): boolean
	return RunService:IsStudio() and ServerStorage:GetAttribute("RunSelfTest") == true and not ScheduleService.allowInTestsForTest
end

-- One look at the calendar. Returns the show events queued now (tests).
function ScheduleService.tick(): { string }
	local t = now()
	-- The free weekend.
	local free = if Schedule.isWeekend(t) then Schedule.weekendPick(t, ScheduleService.weekendList()) else nil
	if Workspace:GetAttribute("FreeWeapon") ~= free then
		Workspace:SetAttribute("FreeWeapon", free)
		if free then
			log.info("free this weekend: " .. free)
		end
	end
	-- The admin show.
	local start = Schedule.nextShow(t)
	Workspace:SetAttribute("AdminShowAt", if t >= start - Schedule.SHOW_LEAD then start else nil)
	local queued = {}
	if t >= start and not shown[start] and not testing() then
		shown[start] = true
		log.info("the admin show starts")
		for i, id in Schedule.SHOW_EVENTS do
			table.insert(pending, task.delay((i - 1) * Schedule.SHOW_GAP, function()
				EventService.trigger(id, "THE ADMIN SHOW", "Free", true)
			end))
			table.insert(queued, id)
		end
		for _, p in Players:GetPlayers() do
			Metrics.event(p, "AdminShow_Watched")
		end
	end
	return queued
end

function ScheduleService.resetForTest()
	table.clear(shown)
	for _, t in pending do
		pcall(task.cancel, t)
	end
	table.clear(pending)
end

function ScheduleService.start()
	ScheduleService.tick()
	task.spawn(function()
		while true do
			task.wait(CHECK)
			ScheduleService.tick()
		end
	end)
end

return ScheduleService
