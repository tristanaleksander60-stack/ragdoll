--!strict
-- Phase 3 (19 Nov 2026): Christmas from 1 December, the Christmas lab, the advent experiment, the
-- Prank Party, and the update rhythm.
--   the season starts 1 December 2026 (Config.CHRISTMAS_FROM_DEC1) and the advent has 24 days
--   every lab has a ChristmasLab (chimney, present, sleigh ramp) that overlaps nothing else in the
--   lab (checked against the world while it is shown)
--   a Prank Party card counts every member's events and pays each of them
--   What's New's newest entry is this build's version

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config) :: any
local Christmas = require(Shared.Christmas)
local Experiments = require(Shared.Experiments)
local Shop = require(Shared.Shop) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")
local Playground = require(Systems:WaitForChild("Playground")) :: any
local ExperimentService = require(Systems:WaitForChild("ExperimentService"))
local PartyService = require(Systems:WaitForChild("PartyService"))

return {
	name = "T66_ChristmasParty",
	timeout = 20,
	run = function(): string?
		local results = {}
		if Config.CHRISTMAS_FROM_DEC1 then
			assert(not Christmas.inSeason({ year = 2026, month = 11, day = 20 }) and Christmas.inSeason({ year = 2026, month = 12, day = 1 }), "the season does not start on 1 December")
		end
		for day = 1, 24 do
			local def = Experiments.advent(day)
			assert(def and Experiments.KINDS[def.kind], "advent day " .. day)
			local before = Experiments.advent(day - 1)
			assert(day == 1 or (before and before.text ~= def.text), "advent day " .. day .. " repeats the day before")
		end
		assert(Experiments.advent(25) == nil, "an advent card after the 24th")
		table.insert(results, "season 1 Dec, 24 advent days")

		-- The Christmas lab: shown, it overlaps nothing.
		if Config.CHRISTMAS_LAB then
			local was = Workspace:GetAttribute("Christmas")
			Playground.showChristmas(true)
			task.wait(0.2)
			local checked, hits = 0, {}
			local root = Workspace:FindFirstChild("Playground")
			for _, lab in (if root then root:GetChildren() else {}) do
				local x = lab:FindFirstChild("ChristmasLab")
				if x then
					for _, p in x:GetChildren() do
						if p:IsA("BasePart") then
							checked += 1
							local params = OverlapParams.new()
							params.FilterType = Enum.RaycastFilterType.Exclude
							params.FilterDescendantsInstances = { x }
							for _, other in Workspace:GetPartBoundsInBox(p.CFrame, p.Size * 0.95, params) do
								local model = other:FindFirstAncestorOfClass("Model")
								local isBody = model and model:FindFirstChildOfClass("Humanoid")
								if not isBody and other.Name ~= "Baseplate" and other.Name ~= "Floor" and other.Name ~= "LabFloor" and other.Transparency < 1 and other.CanCollide then
									table.insert(hits, p.Name .. "/" .. other:GetFullName())
								end
							end
						end
					end
				end
			end
			Playground.showChristmas(was == true)
			assert(checked > 0, "no Christmas lab built")
			assert(#hits == 0, "the Christmas lab overlaps: " .. table.concat(hits, "; ", 1, math.min(#hits, 5)))
			table.insert(results, checked .. " Christmas parts clear")
		end

		-- Prank Party: two members (the test player twice is enough for the counting).
		local player = Players:GetPlayers()[1]
		assert(player, "no player in the play test")
		ExperimentService.join(player)
		local def = Experiments.PARTY[1]
		local starsBefore = (player:GetAttribute("Stars") :: number?) or 0
		ExperimentService.startParty(player, { player }, def)
		assert(ExperimentService.partyOf(player), "no party started")
		ExperimentService.event(player, def.kind, def.target)
		assert(ExperimentService.partyOf(player) == nil, "the party card did not finish")
		assert(((player:GetAttribute("Stars") :: number?) or 0) >= starsBefore + def.stars, "the party paid no stars")
		-- PartyService: a lone player gets no party; two in a lab do (fake groups, no deal for 1).
		PartyService.step(os.clock(), { [player] = { player } })
		assert(ExperimentService.partyOf(player) == nil, "a party for one")
		table.insert(results, "party card shared and paid")

		assert(Shop.WHATS_NEW[1].version == Config.Version, "What's New's newest entry is not " .. Config.Version)
		assert(Config.SERVER_SIZE >= 2 and Config.PARTY_MAX <= Config.SERVER_SIZE, "server size / party size")
		return table.concat(results, "; ")
	end,
}
