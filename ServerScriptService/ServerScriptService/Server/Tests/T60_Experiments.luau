--!strict
-- Phase 1 (19 Nov 2026): Experiment cards. Pure rules (Shared\Experiments) and the server's
-- ExperimentService with the test player:
--   every card is a known kind with a target, a timer and stars; the list goes round
--   events of the card's kind count, others do not; the target finishes it; time running out ends it
--   the daily pick (phase 2) is the same for the same day and has no repeats
--   ExperimentService deals a card, counts takedowns into it, pays its stars and deals the next

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Experiments = require(ReplicatedStorage.Shared.Experiments)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local ExperimentService = require(Systems:WaitForChild("ExperimentService"))

return {
	name = "T60_Experiments",
	timeout = 15,
	run = function(): string?
		for _, def in Experiments.LIST do
			assert(Experiments.KINDS[def.kind], def.id .. " has an unknown kind " .. def.kind)
			assert(def.target >= 1 and def.seconds >= 30 and def.stars >= 1, def.id .. " is not a fair card")
			assert(#def.text <= 44, def.id .. " is longer than one line: " .. def.text)
		end
		assert(Experiments.nextFor(0) == Experiments.LIST[1] and Experiments.nextFor(#Experiments.LIST) == Experiments.LIST[1], "the list does not go round")

		local s: Experiments.State = { def = Experiments.byId.Takedown3, count = 0, startedAt = 0 }
		assert(Experiments.step(s, "Cannon", 1, 1) == nil and s.count == 0, "another kind counted")
		assert(Experiments.step(s, "Takedown", 2, 1) == nil and s.count == 2, "a takedown did not count")
		assert(Experiments.step(s, "Takedown", 1, 2) == "done", "the target did not finish the card")
		local late: Experiments.State = { def = Experiments.byId.Cannon, count = 0, startedAt = 0 }
		assert(Experiments.step(late, "Cannon", 1, late.def.seconds + 1) == "late", "a card past its time still counted")

		local a, b = Experiments.daily(20000, 3), Experiments.daily(20000, 3)
		assert(#a == 3 and a[1] == b[1] and a[2] == b[2] and a[3] == b[3], "the daily pick differs for the same day")
		assert(a[1] ~= a[2] and a[2] ~= a[3] and a[1] ~= a[3], "the daily pick repeats a card")

		local t0 = os.clock()
		while Players:GetPlayers()[1] == nil and os.clock() - t0 < 15 do
			task.wait(0.2) -- (run first, the player may not have joined yet)
		end
		local player = Players:GetPlayers()[1]
		assert(player, "no player in the play test")
		ExperimentService.join(player)
		local savedNext = ExperimentService.NEXT_AFTER
		ExperimentService.NEXT_AFTER = 0.2
		ExperimentService.setDeck(player, { Experiments.byId.Takedown3 })
		-- (V8-1.3: the mission chain comes before the deck: done here.)
		local wasChain = ExperimentService.chainOf(player)
		ExperimentService.setChainForTest(player, #(Experiments :: any).CHAIN)
		local def = ExperimentService.deal(player)
		ExperimentService.setChainForTest(player, wasChain)
		assert(def and def.id == "Takedown3", "the deck's card was not dealt first")
		local _, starsBefore = ExperimentService.stateOf(player)
		ExperimentService.event(player, "Takedown", 3)
		local state, starsAfter = ExperimentService.stateOf(player)
		assert(state == nil and starsAfter == starsBefore + def.stars, "finishing the card paid no stars")
		task.wait(0.5)
		local nextState = ExperimentService.stateOf(player)
		ExperimentService.NEXT_AFTER = savedNext
		assert(nextState ~= nil, "no next card was dealt")
		return string.format("%d cards; dealt, counted, paid %d stars, next %s", #Experiments.LIST, def.stars, (nextState :: any).def.id)
	end,
}
