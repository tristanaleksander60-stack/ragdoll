--!strict
-- Release 0.20 (19 Nov 2026): throw your friend (Config.PARTY_THROWS).
--   Zones.mayGrab: the plaza always; inside a lab only for two members of the Prank Party running
--   there (their PartyLab attribute = the owner's UserId, both in the owner's plot), never with the
--   switch off
--   a Prank Party sets PartyLab on its members and clears it when it ends
--   a thrown player landing in a trap (or the cannon...) is a TOSS COMBO: it counts for the party's
--   TOSS card, combos count up, a landing of another kind does not use the throw up, and a player
--   nobody threw is no combo
--   PartyService deals the TOSS card in turn (only with PARTY_THROWS on)
-- The test player plays both parts (thrower and thrown); the grab itself needs two real players
-- (TEST-ALT.md, two players).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config) :: any
local Experiments = require(Shared.Experiments)
local Zones = require(Shared.Zones)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local ExperimentService = require(Systems:WaitForChild("ExperimentService"))
local PartyService = require(Systems:WaitForChild("PartyService")) :: any
local PlayerGrab = require(Systems:WaitForChild("PlayerGrab")) :: any

local function tossDef(): Experiments.Def?
	for _, def in Experiments.PARTY do
		if def.kind == "Toss" then
			return def
		end
	end
	return nil
end

return {
	name = "T67_PartyToss",
	timeout = 15,
	run = function(): string?
		local results = {}
		local player = Players:GetPlayers()[1]
		assert(player, "no player in the play test")
		assert(Experiments.KINDS.Toss, "Toss is not an experiment kind")
		local def = tossDef()
		assert(def, "no TOSS party card")
		assert(type(PlayerGrab.placeAllows) == "function", "PlayerGrab has no placeAllows")

		-- 1. Where a grab may happen.
		local o = Workspace:GetAttribute("LabOrigin")
		local origin = if typeof(o) == "Vector3" then o else Vector3.zero
		local plaza = origin + Vector3.new(0, 3, 0)
		assert(Zones.mayGrab(player, player, plaza, plaza, false) and Zones.mayGrab(player, player, plaza, plaza, true), "the plaza should always allow a grab")
		local savedParty = player:GetAttribute("PartyLab")
		local plot = player:GetAttribute("LabPlot")
		if type(plot) == "number" and plot > 0 then
			local lab = Vector3.new(Zones.plotCenterX(plot), origin.Y + 3, origin.Z)
			player:SetAttribute("PartyLab", nil)
			assert(not Zones.mayGrab(player, player, lab, lab, true), "a grab in a lab with no party")
			player:SetAttribute("PartyLab", player.UserId)
			assert(Zones.mayGrab(player, player, lab, lab, true), "party members could not grab in their party's lab")
			assert(not Zones.mayGrab(player, player, lab, lab, false), "a lab grab with PARTY_THROWS off")
			assert(not Zones.mayGrab(player, player, lab, plaza, true), "a grab from the lab into the plaza")
			player:SetAttribute("PartyLab", player.UserId + 1)
			assert(not Zones.mayGrab(player, player, lab, lab, true), "a party of another lab's owner allowed a grab here")
			player:SetAttribute("PartyLab", savedParty)
			table.insert(results, "grab rule: plaza always, lab only in its own party")
		else
			table.insert(results, "grab rule: plaza always (no lab for the test player: lab cases skipped)")
		end

		-- 2. A party with the TOSS card: three combos finish it.
		local d = def :: Experiments.Def
		ExperimentService.join(player)
		ExperimentService.startParty(player, { player }, d)
		assert(player:GetAttribute("PartyLab") == player.UserId, "the party did not mark its member")
		local party = ExperimentService.partyOf(player)
		assert(party, "no party started")
		-- Nobody threw them: no combo.
		ExperimentService.event(player, "Hazard", 1, "the LAVA")
		assert(party.state.count == 0, "a combo without a throw")
		-- Thrown, but the next event is not a landing: the throw is kept for the landing.
		ExperimentService.thrown(player, player)
		ExperimentService.event(player, "Takedown", 1)
		assert(party.state.count == 0, "a takedown counted as a toss")
		ExperimentService.event(player, "Hazard", 1, "the LAVA")
		assert(party.state.count == 1, "a thrown player in the lava was not a TOSS COMBO (count " .. party.state.count .. ")")
		-- A throw counts once.
		ExperimentService.event(player, "Hazard", 1, "the LAVA")
		assert(party.state.count == 1, "one throw counted twice")
		ExperimentService.thrown(player, player)
		ExperimentService.event(player, "Cannon", 1, "the CANNON")
		assert(party.state.count == 2, "a throw into the cannon did not count")
		ExperimentService.thrown(player, player)
		ExperimentService.event(player, "Bullseye", 1, "the BULLSEYE")
		assert(ExperimentService.partyOf(player) == nil, "three combos did not finish the TOSS card")
		assert(player:GetAttribute("PartyLab") == nil, "the ended party left PartyLab on its member")
		player:SetAttribute("PartyLab", savedParty)
		table.insert(results, "TOSS card: 3 combos (lava, cannon, bullseye) finish it; no throw, no combo; one throw, one combo")

		-- 3. The chain: combos close together count up.
		ExperimentService.thrown(player, player)
		local n1 = ExperimentService.tossComboForTest(player, "Hazard", "the SPIKES")
		ExperimentService.thrown(player, player)
		local n2 = ExperimentService.tossComboForTest(player, "Hazard", "the SPIKES")
		assert(n1 and n2 and n2 == n1 + 1, string.format("the combo chain did not count up (%s, %s)", tostring(n1), tostring(n2)))
		table.insert(results, string.format("chain x%d", n2 :: number))

		-- 4. PartyService deals the TOSS card in turn.
		local seen = false
		for _ = 1, #Experiments.PARTY + 1 do
			local next = PartyService.nextCard(player)
			if next.kind == "Toss" then
				seen = true
			end
		end
		assert(seen == (Config.PARTY_THROWS == true), "the TOSS card is " .. (if seen then "dealt" else "never dealt") .. " with PARTY_THROWS " .. tostring(Config.PARTY_THROWS))
		table.insert(results, "party deck " .. (if seen then "has" else "skips") .. " the TOSS card")
		return table.concat(results, "; ")
	end,
}
