--!strict
-- V9-3b (owner, 21 Nov 2026: "bigger gaps between unlocking new weapons"; Config.LADDER_V9): the first
-- rungs as they were, then one smooth growing curve; the order kept; the top 2-3x the old one and under
-- LADDER_V9_TOP; the Rocket still among the hardest; every weapon its old price (Robux tier and
-- Bolts); a profile from before keeps everything its takedowns had reached (ladder 6).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local Economy = require(Shared:WaitForChild("Economy")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T178_LadderV9",
	timeout = 10,
	run = function(): string?
		if not Config.LADDER_V9 then
			return "skipped (LADDER_V9 off)"
		end
		local keep = Config.LADDER_V9_KEEP
		local oldTop, newTop = 0, 0
		-- The first rungs and the start bar as they were; the old rung kept for every weapon.
		for _, toy in Toys.list do
			local old = Toys.V8_UNLOCK[toy.id]
			assert(old ~= nil, toy.id .. " has no old rung kept")
			if old <= keep then
				assert(toy.unlockAt == old, string.format("%s moved from %d to %d although it is one of the first rungs", toy.id, old, toy.unlockAt))
			else
				assert(toy.unlockAt > old, string.format("%s did not move up (%d -> %d)", toy.id, old, toy.unlockAt))
				assert(toy.priceRung == old, toy.id .. " lost its old rung for the Bolts price")
			end
			if old ~= math.huge then
				oldTop = math.max(oldTop, old)
				newTop = math.max(newTop, toy.unlockAt)
			end
		end
		-- The order kept (ties stay ties).
		for _, a in Toys.list do
			for _, b in Toys.list do
				local oa, ob = Toys.V8_UNLOCK[a.id], Toys.V8_UNLOCK[b.id]
				if oa < ob then
					assert(a.unlockAt < b.unlockAt, a.id .. " and " .. b.id .. " swapped places")
				elseif oa == ob then
					assert(a.unlockAt == b.unlockAt, a.id .. " and " .. b.id .. " no longer share a rung")
				end
			end
		end
		-- The gaps grow (after the kept rungs), and the top is 2-3x the old one, under LADDER_V9_TOP.
		local rungs: { number } = {}
		for _, toy in Toys.list do
			if toy.unlockAt > keep and not table.find(rungs, toy.unlockAt) then
				table.insert(rungs, toy.unlockAt)
			end
		end
		table.sort(rungs)
		local prevGap = 0
		for i, r in rungs do
			local gap = r - (rungs[i - 1] or keep)
			assert(gap >= prevGap - 1, string.format("the gap before %d (%d) is smaller than the one before it (%d)", r, gap, prevGap))
			prevGap = gap
		end
		assert(newTop <= Config.LADDER_V9_TOP and newTop >= 2 * oldTop and newTop <= 3 * oldTop, string.format("the top is %d (old %d, cap %d)", newTop, oldTop, Config.LADDER_V9_TOP))
		-- The Rocket keeps its place among the hardest.
		local rocket, portal, blade = Toys.byId.Rocket, Toys.byId.Portal, Toys.byId.PlasmaBlade
		if rocket and portal and blade then
			assert(portal.unlockAt < rocket.unlockAt and rocket.unlockAt < blade.unlockAt, "the Rocket left its place between the Portal and the Plasma Blade")
		end
		-- Every weapon its old Robux tier: the old bounds on the old rungs give the same tier.
		local function squeeze(r: number): number
			if Config.LADDER_V2 and r > Config.LADDER_KEEP and r ~= math.huge then
				return math.floor(Config.LADDER_KEEP + (r - Config.LADDER_KEEP) * Config.LADDER_V2_SCALE + 0.5)
			end
			return r
		end
		local oldBounds = { squeeze(60), squeeze(200), squeeze(500), math.huge }
		local robux = { 25, 49, 99, 199 }
		for _, toy in Toys.list do
			local old = Toys.V8_UNLOCK[toy.id]
			if old > 0 and old ~= math.huge then
				local was = 0
				for i, bound in oldBounds do
					if old <= bound then
						was = robux[i]
						break
					end
				end
				local tier = Toys.priceTier(toy)
				assert(tier and tier.robux == was, string.format("%s costs R$%s now, R$%d before", toy.id, tostring(tier and tier.robux), was))
			end
		end
		-- Bolts: the price of the old rung.
		local id, price = Economy.nextBuy(Toys.list, function()
			return false
		end, 100)
		local bought = id and Toys.byId[id]
		assert(bought and price == Economy.priceOf(Toys.V8_UNLOCK[bought.id]), "the Bolts price is not the price before V9 (" .. tostring(price) .. ")")
		-- A profile from before keeps everything it had reached.
		local ProgressService = require(Systems:WaitForChild("ProgressService")) :: any
		local profile = { owned = {}, oldEggs = 0, eggs = 0, ladder = 5 } :: any
		ProgressService.grandfather(profile, 100, 0, 5)
		local kept = 0
		for _, toy in Toys.list do
			local old = Toys.V8_UNLOCK[toy.id]
			if old > 0 and old <= 100 and toy.unlockAt > 100 then
				assert(profile.owned[toy.id], toy.id .. " was taken away from a profile with 100 takedowns")
				kept += 1
			end
		end
		assert(profile.ladder == 6, "the profile did not move to ladder 6")
		return string.format("first rungs kept (<= %d); %d rungs on a growing curve, order kept; top %d (old %d, cap %d); Rocket between Portal and Plasma Blade; every Robux tier and the Bolts price as before; 100 takedowns keep %d stretched weapons", keep, #rungs, newTop, oldTop, Config.LADDER_V9_TOP, kept)
	end,
}
