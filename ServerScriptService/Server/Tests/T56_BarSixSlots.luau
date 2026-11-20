--!strict
-- Phase 0 (19 Nov 2026): the 0.16 / 0.17 bar changes undone for new players (AUDIT.md 1.3: the
-- likely ~19 s session drop):
--   the bar has 6 slots again and a saved 6-tool bar is kept whole (a longer one keeps its first 6)
--   the three locked NEXT cards stay hidden under Config.NEXT_UNLOCKS_MIN_TAKEDOWNS takedowns and in
--   the first Config.NEXT_UNLOCKS_AFTER s of a visit (BarRules.nextUnlocksShown)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local LoadoutStore = require(Systems:WaitForChild("LoadoutStore"))
local Toys = require(ReplicatedStorage.Shared.Toys)
local BarRules = require(ReplicatedStorage.Shared.BarRules)
local Config = require(ReplicatedStorage.Shared.Config)

return {
	name = "T56_BarSixSlots",
	timeout = 3,
	run = function(): string?
		assert(Toys.SLOTS == 6, "the bar should have 6 slots, has " .. Toys.SLOTS)
		local six = { "Grab", "Shove", "Launch", "TNT", "Rocket", "Freeze" }
		local kept = LoadoutStore.validate(six)
		assert(kept and #kept == 6, "a 6-tool bar was not kept whole")
		local seven = table.clone(six)
		table.insert(seven, "Blaster")
		local cut = LoadoutStore.validate(seven)
		assert(cut and #cut == 6 and cut[6] == "Freeze", "a 7-tool list should keep its first 6")
		local three = LoadoutStore.validate(Toys.defaultLoadout)
		assert(three and #three == #Toys.defaultLoadout, "the starting bar was refused") -- (V8-0.3: 5 tools)

		local n, after = Config.NEXT_UNLOCKS_MIN_TAKEDOWNS, Config.NEXT_UNLOCKS_AFTER
		assert(n >= 1 and after >= 30, "the NEXT cards' thresholds are not set") -- (V7: 45 s)
		assert(not BarRules.nextUnlocksShown(0, 10), "a brand new player sees the NEXT cards")
		assert(not BarRules.nextUnlocksShown(n - 1, after + 600), "NEXT cards under the takedown threshold")
		assert(not BarRules.nextUnlocksShown(n + 500, after - 1), "NEXT cards in the first minutes of a visit")
		assert(BarRules.nextUnlocksShown(n, after), "the NEXT cards never come back")
		return string.format("6 slots; NEXT cards from %d takedowns and %d s into a visit", n, after)
	end,
}
