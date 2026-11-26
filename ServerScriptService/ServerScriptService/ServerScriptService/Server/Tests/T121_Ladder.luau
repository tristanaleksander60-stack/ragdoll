--!strict
-- V8-1.4 (unlocks that feel like presents): one next goal (Shared/NextGoal: the nearest exciting
-- weapon not yours), BOLTS buy only weapons BOLTS_BUY_GAP or more KOs away, and the visit record
-- counts unlocks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local NextGoal = require(Shared:WaitForChild("NextGoal")) :: any
local Economy = require(Shared:WaitForChild("Economy")) :: any

return {
	name = "T121_Ladder",
	timeout = 10,
	run = function(): string?
		if not Config.LADDER_V3 then
			return "skipped (LADDER_V3 off)"
		end
		local none = function(_id: string): boolean
			return false
		end
		-- The next goal: exciting, locked, the nearest.
		for _, td in { 0, 3, 10, 40, 200 } do
			local goal, from = NextGoal.of(td, {})
			if goal then
				assert(NextGoal.exciting(goal) and goal.unlockAt > td, "the next goal at " .. td .. " is not an exciting locked weapon")
				assert(from <= td, "the count runs from ahead of the player")
				for _, toy in Toys.list do
					if NextGoal.exciting(toy) and toy.unlockAt > td then
						assert(toy.unlockAt >= goal.unlockAt, "a nearer exciting weapon was skipped at " .. td)
					end
				end
			end
		end
		-- Owning it moves the goal on.
		local first = NextGoal.of(0, {})
		local second = NextGoal.of(0, { [first.id] = true })
		assert(second == nil or second.id ~= first.id, "an owned weapon stayed the goal")
		-- BOLTS: 5+ KOs away.
		for _, td in { 0, 10, 50 } do
			local id = Economy.nextBuy(Toys.list, none, td)
			if id then
				assert(Toys.byId[id].unlockAt >= td + Config.BOLTS_BUY_GAP, string.format("BOLTS offered %s, %d KOs away at %d", id, Toys.byId[id].unlockAt - td, td))
			end
		end
		return string.format("next goal at 0 KOs: %s; BOLTS buy %d+ KOs away", first.label, Config.BOLTS_BUY_GAP)
	end,
}
