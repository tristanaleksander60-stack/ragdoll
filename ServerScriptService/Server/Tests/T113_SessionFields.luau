--!strict
-- V8-0.8 (see why they leave): the visit record carries the V8 fields and the funnel stage is right,
-- and the play-as-newcomer mode (TestAccount) is what Owner and the record use.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local SessionStats = require(Systems:WaitForChild("SessionStats")) :: any
local TestAccount = require(Systems:WaitForChild("TestAccount")) :: any
local Owner = require(Systems:WaitForChild("Owner")) :: any

local function waitFor(check: () -> boolean, seconds: number): boolean
	local t0 = os.clock()
	while not check() do
		if os.clock() - t0 > seconds then
			return false
		end
		task.wait(0.2)
	end
	return true
end

return {
	name = "T113_SessionFields",
	timeout = 40,
	run = function(): string?
		-- The funnel stage, from a bare record.
		local r: any = { left = 0, frame0 = 0, hits = 0, knocks = 0 }
		assert(SessionStats.stageOf(r) == 1, "a bare visit is not stage 1")
		r.hits = 2
		assert(SessionStats.stageOf(r) == 2, "a hit is not stage 2")
		r.knocks = 1
		assert(SessionStats.stageOf(r) == 3, "a knock-down is not stage 3")
		r.firstLaunchAt = 30
		assert(SessionStats.stageOf(r) == 4, "a launch is not stage 4")
		r.firstMissionDoneAt = 50
		assert(SessionStats.stageOf(r) == 5, "a mission is not stage 5")
		r.left, r.frame0 = 190, 5
		assert(SessionStats.stageOf(r) == 6, "3 minutes from the first frame is not stage 6")
		r.left = 700
		assert(SessionStats.stageOf(r) == 8, "10 minutes is not stage 8")
		-- The live record of the test player takes the V8 fields.
		waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		waitFor(function()
			return SessionStats.recordFor(p) ~= nil -- (run first, the record may not exist yet)
		end, 15)
		local rec = SessionStats.recordFor(p)
		assert(rec, "no visit record for the player")
		SessionStats.onClient(p, "Frame0")
		SessionStats.onClient(p, "Orient", { t = 30, p = true })
		SessionStats.onClient(p, "Orient", { t = "rot", p = false })
		SessionStats.onClient(p, "Perf", { p50 = 58, p5 = 41, mem = 900, errs = 0, sig = "", vol = 3 })
		SessionStats.onClient(p, "Screen", "window")
		SessionStats.onClient(p, "Screen", "<script>") -- (refused: not one of the four)
		SessionStats.used(p, "Cannon")
		SessionStats.used(p, "Cannon")
		SessionStats.count(p, "knocks", 1)
		SessionStats.mark(p, "firstLaunchAt")
		assert(rec.frame0 ~= nil, "no frame0")
		assert(rec.orient30 == "p" and (rec.rot or 0) >= 1, "orientation not kept")
		assert(rec.fpsP50 == 58 and rec.fpsP5 == 41 and rec.vol == 3, "perf not kept")
		assert(rec.screen == "window", "screen state not kept or a bad one taken")
		assert(rec.used and rec.used.Cannon ~= nil, "first use not kept")
		assert(rec.firstKnockAt ~= nil and rec.firstLaunchAt ~= nil, "first times not kept")
		-- The play-as-newcomer mode: under StudioFresh the Studio user is a test visit, never the owner.
		local was = ServerStorage:GetAttribute("StudioFresh")
		ServerStorage:SetAttribute("StudioFresh", true)
		local isTest, isOwner = TestAccount.is(p), Owner.isOwner(p)
		ServerStorage:SetAttribute("StudioFresh", was)
		assert(isTest, "StudioFresh does not make a test visit")
		assert(not isOwner, "a test visit still gets owner perks")
		return "stage 1-8 right; frame0, orientation, perf, screen, first use and first times kept; StudioFresh = newcomer without owner perks"
	end,
}
