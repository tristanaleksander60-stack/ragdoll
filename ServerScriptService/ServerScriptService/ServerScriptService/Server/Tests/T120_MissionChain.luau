--!strict
-- V8-1.3 (one mission chain): the 8 missions come in order, one at a time, with no timer; a done
-- mission moves the chain on (kept in memory here, Missions_v1 live); SKIP waits SKIP_AFTER s; after
-- the chain a newcomer never gets a creature or map card; every mission is at most 24 characters and
-- its kind is one the server counts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Experiments = require(Shared:WaitForChild("Experiments")) :: any
local ExperimentService = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("ExperimentService")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T120_MissionChain",
	timeout = 30,
	run = function(): string?
		if not Config.MISSION_CHAIN then
			return "skipped (MISSION_CHAIN off)"
		end
		assert(#Experiments.CHAIN == 8, "the chain is not 8 missions")
		for i, def in Experiments.CHAIN do
			assert(#def.text <= 24, def.id .. " is longer than 24 characters")
			assert(Experiments.KINDS[def.kind], def.id .. " counts an unknown kind " .. def.kind)
			assert(def.seconds >= Experiments.NO_TIMER, def.id .. " has a timer")
			assert(def.id == "Chain" .. i, "the chain is out of order at " .. i)
		end
		TestLib.waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "chain data right; skipped the live part (no player)"
		end
		local wasAt, wasNew = ExperimentService.chainOf(p), p:GetAttribute("Newcomer")
		local ok, err = pcall(function()
			ExperimentService.join(p)
			ExperimentService.setChainForTest(p, 0)
			local first = ExperimentService.deal(p)
			assert(first and first.id == "Chain1", "the first card is not the first mission")
			ExperimentService.event(p, "Takedown", 1)
			assert(ExperimentService.chainOf(p) == 1, "a done mission did not move the chain on")
			local second = ExperimentService.deal(p)
			assert(second and second.id == "Chain2", "the second card is not the second mission")
			ExperimentService.event(p, "Tool:Bat", 1)
			assert(ExperimentService.chainOf(p) == 2, "swinging the Bat did not count")
			-- After the chain, a newcomer gets no creature or map card.
			ExperimentService.setChainForTest(p, #Experiments.CHAIN)
			p:SetAttribute("Newcomer", true)
			for _ = 1, #Experiments.LIST do
				local def = ExperimentService.deal(p)
				assert(def and not Experiments.SEEN_FIRST[def.kind], "a newcomer got the card " .. tostring(def and def.id))
			end
		end)
		ExperimentService.setChainForTest(p, wasAt)
		p:SetAttribute("Newcomer", wasNew)
		assert(ok, err)
		return "8 missions in order, no timers, 24 characters at most; done moves the chain on; a newcomer gets no creature or map card after it"
	end,
}
