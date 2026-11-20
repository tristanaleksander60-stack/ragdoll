--!strict
-- V6-2: the owner's tabbed admin menu (AdminService -> AdminTools).
--   a non-owner is refused every tool and changes nothing;
--   junk and anything outside the fixed choices is refused;
--   the owner's gravity, time, weather, spawn (guests only, NoCredit), clear, revive and crowd work,
--   and are logged; the Debug numbers come back; everything is put back afterwards.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local AdminService = require(Systems:WaitForChild("AdminService"))
local AdminTools = require(Systems:WaitForChild("AdminTools"))
local Owner = require(Systems:WaitForChild("Owner"))

local function waitFor(check: () -> boolean, seconds: number): boolean
	local started = os.clock()
	while not check() do
		if os.clock() - started > seconds then
			return false
		end
		task.wait(0.1)
	end
	return true
end

local function guests(): number
	local n = 0
	local f = Workspace:FindFirstChild("Dummies")
	for _, m in if f then f:GetChildren() else {} do
		if m:GetAttribute("NoCredit") == true then
			n += 1
		end
	end
	return n
end

return {
	name = "T101_AdminTools",
	timeout = 40,
	run = function(): string?
		waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		waitFor(function()
			return p.Character ~= nil and p.Character:FindFirstChild("HumanoidRootPart") ~= nil
		end, 10)
		local gravity = Workspace.Gravity
		local ok, err = pcall(function()
			local function req(kind: string, arg: any?): boolean
				AdminService.resetPaceForTest(p)
				return AdminService.request(p, kind, arg)
			end
			-- Not the owner: every tool refused, nothing changed.
			Owner.studioOwnerForTest = false
			for kind in AdminTools.KINDS do
				assert(not req(kind, 25), "a non-owner was let through: " .. kind)
			end
			assert(not req("Gravity", 25) and Workspace.Gravity == gravity, "a non-owner changed gravity")
			assert(not req("Weather", "Rain") and Workspace:GetAttribute("AdminWeather") == nil, "a non-owner changed the weather")
			assert(not req("Debug"), "a non-owner got the debug numbers")
			Owner.studioOwnerForTest = true
			-- Fixed choices only.
			assert(not req("Gravity", 33), "an odd gravity was taken")
			assert(not req("Clock", "Noonish"), "an odd time was taken")
			assert(not req("Weather", "Lava"), "an odd weather was taken")
			assert(not req("Announce", "whatever text"), "a free-text announcement was taken")
			assert(not req("Kick", { target = p.UserId, reason = "because" }), "a free-text kick reason was taken")
			assert(not req("Kick", { target = p.UserId, reason = "Rude" }), "the owner kicked themselves")
			assert(not req("Spawn", { count = 50, shape = "Row" }), "50 dummies were taken")
			-- The owner's tools.
			assert(req("Gravity", 60) and Workspace.Gravity == 60, "gravity not set")
			assert(req("Clock", "Night") and Workspace:GetAttribute("AdminClock") == 0.5, "time not set")
			assert(req("Weather", "Snow") and Workspace:GetAttribute("AdminWeather") == "Snow", "weather not set")
			assert(req("Announce", "Hello"), "announce refused")
			local before = guests()
			assert(req("Spawn", { count = 5, shape = "Ring" }), "spawn refused")
			assert(guests() >= before + 1, "no guest dummies spawned")
			assert(req("ReviveAll"), "revive all refused")
			assert(req("ClearDummies") and guests() == 0, "guests not cleared")
			assert(req("Crowd", 5), "crowd refused")
			assert(req("Crowd", -5), "crowd -5 refused")
			local d = AdminTools.debug()
			assert(type(d.fps) == "number" and d.parts > 0, "no debug numbers")
			local log = AdminService.logForTest()
			assert(#log > 0, "nothing was logged")
		end)
		Owner.studioOwnerForTest = true
		AdminService.resetPaceForTest(p)
		AdminService.request(p, "Gravity", 196.2)
		AdminService.resetPaceForTest(p)
		AdminService.request(p, "Clock", "Auto")
		AdminService.resetPaceForTest(p)
		AdminService.request(p, "Weather", "Clear")
		Workspace.Gravity = gravity
		if not ok then
			error(err, 0)
		end
		return "non-owner refused, fixed choices only, gravity/time/weather/spawn/clear/crowd/debug work"
	end,
}
