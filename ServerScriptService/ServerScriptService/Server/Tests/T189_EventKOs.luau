--!strict
-- V9-NOW 21 (owner, 21 Nov 2026: "KOs count for every event the player starts, also from the BIG RED BUTTON"): while
-- an event the player started runs (ProgressService.startEventCredit), a body that goes down in their lab with no
-- player's hit behind it is their KO (x2 in the 2X event), once; outside the window it is nobody's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local DoubleEvent = require(Shared:WaitForChild("DoubleEvent")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T189_EventKOs",
	timeout = 40,
	run = function(): string?
		local ProgressService = require(Systems:WaitForChild("ProgressService")) :: any
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and Lab.plotIndex(p) ~= nil and Lab.slotDummy(p, 1) ~= nil and ProgressService.takedownsOf(p) ~= nil
		end, 20)
		local p = Players:GetPlayers()[1]
		if not p or not Lab.slotDummy(p, 1) then
			return "skipped (no player with a lab)"
		end
		local function down(i: number): Model
			local d = Lab.slotDummy(p, i) :: Model
			d:SetAttribute("HitBy", nil)
			d:SetAttribute("HitAt", nil)
			d:SetAttribute("ServerHitBy", nil)
			ProgressService.resetComboForTest(p)
			ProgressService.onDownForTest(d, "Ragdoll", true)
			return d
		end
		-- Outside a window: nobody's.
		local t0 = ProgressService.takedownsOf(p)
		down(2)
		assert(ProgressService.takedownsOf(p) == t0, "a fall with no hit and no event counted")
		-- Inside: the starter's, x2 in the 2X event.
		ProgressService.startEventCredit(p, "Test Rampage", 3)
		local t1 = ProgressService.takedownsOf(p)
		down(3)
		local want = DoubleEvent.mult(Config.DOUBLE_EVENT, os.time())
		assert(ProgressService.takedownsOf(p) - t1 == want, string.format("an event fall gave %d KOs (want %d)", ProgressService.takedownsOf(p) - t1, want))
		assert(ProgressService.eventCountForTest(p) == 1, "the event did not count its KO")
		-- The same body again at once: the cooldown holds.
		local t2 = ProgressService.takedownsOf(p)
		down(3)
		assert(ProgressService.takedownsOf(p) == t2, "one body counted twice")
		return string.format("no event: 0; in the event: +%d for the starter, once per body", want)
	end,
}
