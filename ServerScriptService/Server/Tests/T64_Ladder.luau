--!strict
-- Phase 2: the retuned ladder (Config.LADDER_V2). The first five weapons to earn come within ten
-- minutes of play (at an easy 2 takedowns a minute), the top is within reach (<= 650), the order of
-- the weapons is the old one, and every weapon keeps its Robux price tier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Toys = require(ReplicatedStorage.Shared.Toys)
local Config = require(ReplicatedStorage.Shared.Config) :: any

return {
	name = "T64_Ladder",
	timeout = 3,
	run = function(): string?
		local rungs = {}
		for _, toy in Toys.list do
			if toy.unlockAt > 0 then
				table.insert(rungs, toy.unlockAt)
			end
		end
		table.sort(rungs)
		-- (V9-3b, LADDER_V9: the gaps grow on purpose after the first rungs; the fifth comes one curve step
		-- later, still inside the first ~12 minutes.)
		local fifthMax = if Config.LADDER_V9 then Config.LADDER_V9_KEEP + 2 * Config.LADDER_V9_FIRST_GAP + 1 else 20
		assert(rungs[5] <= fifthMax, "the fifth weapon needs " .. rungs[5] .. " takedowns (at most " .. fifthMax .. ")")
		if Config.LADDER_V2 then
			assert(rungs[#rungs] <= (if Config.LADDER_V9 then Config.LADDER_V9_TOP else 650), "the top of the ladder is " .. rungs[#rungs])
			-- The Minigun (58 on the old ladder) and the Railgun (1,050) keep their places.
			assert(Toys.byId.Minigun.unlockAt < Toys.byId.Deagle.unlockAt and Toys.byId.Railgun.unlockAt < Toys.byId.GoldenDeagle.unlockAt, "the order changed")
			-- (V8-0.3 moves the first rungs on purpose: the full start bar, T110.)
			assert(Config.V8_START_BAR or (Toys.byId.Bat.unlockAt == 2 and Toys.byId.Grenade.unlockAt == 10), "the first rungs moved")
			-- Prices: the old tier bounds moved with the ladder.
			-- (V8-0.3: the Bat is free from the start now; the Crowbar is the cheapest rung.)
			local top, low = Toys.priceTier(Toys.byId.GoldenDeagle), Toys.priceTier(if Config.V8_START_BAR then Toys.byId.Crowbar else Toys.byId.Bat)
			assert(top and low and top.robux == 199 and low.robux == 25, "price tiers moved")
		end
		return string.format("%d rungs, the fifth at %d, the top at %d", #rungs, rungs[5], rungs[#rungs])
	end,
}
