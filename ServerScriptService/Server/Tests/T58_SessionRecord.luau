--!strict
-- Phase 0 (19 Nov 2026): measurement. Every visit record carries the build (Config.Version and
-- game.PlaceVersion), the inputs really used (a pad on a PC is no longer "pc": 84 % of pad visits
-- never fired and nobody could see it), the screen's orientation, and the onboarding funnel's
-- furthest step (steps 5-7 lived only in Roblox Analytics). tools\SessionReport.luau reads them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local SessionStats = require(Systems:WaitForChild("SessionStats"))
local Config = require(ReplicatedStorage.Shared.Config)

local function fake(pad: boolean, keys: boolean, mouse: boolean, touch: boolean): any
	return { usedPad = pad, usedKeys = keys, usedMouse = mouse, usedTouch = touch }
end

return {
	name = "T58_SessionRecord",
	timeout = 15,
	run = function(): string?
		-- The input mix in one word.
		assert(SessionStats.inputOf(fake(true, false, false, false)) == "pad", "pad only")
		assert(SessionStats.inputOf(fake(false, true, true, false)) == "kbm", "keyboard and mouse")
		assert(SessionStats.inputOf(fake(false, false, false, true)) == "touch", "touch only")
		assert(SessionStats.inputOf(fake(true, true, false, false)) == "mixed", "pad + keys")
		assert(SessionStats.inputOf(fake(false, false, false, false)) == "none", "nothing used")
		-- (Every build has its own version and What's New entry: T67.)
		assert(Config.Version ~= "0.17.2", "Config.Version was not bumped past 0.17.2")

		local player = Players:GetPlayers()[1]
		local started = os.clock()
		while not player and os.clock() - started < 10 do
			task.wait(0.2)
			player = Players:GetPlayers()[1]
		end
		assert(player, "no player in the play test")
		local record = SessionStats.recordFor(player)
		assert(record, "no visit record for the player")
		local r = record :: any
		assert(r.v == Config.Version and type(r.pv) == "number", "the record has no build stamp")
		local before = { r.usedPad, r.usedKeys, r.step }
		SessionStats.onClient(player, "Used", "pad")
		SessionStats.onClient(player, "Used", "nonsense")
		SessionStats.onClient(player, "Used", 42)
		assert(r.usedPad == true, "a used pad was not kept")
		SessionStats.step(player, 7)
		SessionStats.step(player, 3)
		assert(r.step == 7, "the furthest funnel step was not kept: " .. tostring(r.step))
		-- (Put back what this test changed on the live record.)
		r.usedPad, r.usedKeys, r.step = before[1], before[2], before[3]
		return string.format("v%s place %d; pad/keys/mouse/touch kept; funnel step kept", r.v, r.pv)
	end,
}
