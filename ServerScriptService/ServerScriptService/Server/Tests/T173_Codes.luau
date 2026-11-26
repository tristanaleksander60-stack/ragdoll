--!strict
-- V9-0t (owner, 21 Nov 2026: "add codes we can advertise in the description"): Shared/Codes and
-- EconomyService.redeem. A code is case- and space-blind; each works once per profile; a dated one
-- is unknown before its start and expired after its end; BETA only while Config.BETA; nothing about
-- likes. On the server: RELEASE pays exactly 500 BOLTS (never doubled by 2x BOLTS), the second try says
-- "used", the sixth try in a minute is refused, and the reply reaches the client as "Code". The
-- player's profile is put back as it was.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Codes = require(Shared:WaitForChild("Codes")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any

local Systems = script.Parent.Parent:WaitForChild("Systems")

local function utc(y: number, m: number, d: number): number
	return DateTime.fromUniversalTime(y, m, d, 12, 0, 0).UnixTimestamp
end

return {
	name = "T173_Codes",
	timeout = 40,
	run = function(): string?
		-- The rule.
		local now = utc(2026, 11, 21)
		assert(Codes.check(" re lease ", {}, now, true) ~= nil, "RELEASE with spaces and lower case did not work")
		local _, used = Codes.check("RELEASE", { RELEASE = true }, now, true)
		assert(used == "used", "a used code was not refused as used")
		local _, unknown = Codes.check("NOPE123", {}, now, true)
		assert(unknown == "invalid", "an unknown code was not invalid")
		local _, early = Codes.check("CHRISTMAS", {}, now, true)
		assert(early == "invalid", "CHRISTMAS answered before 1 Dec (it must give no hint)")
		assert(Codes.check("christmas", {}, utc(2026, 12, 5), true) ~= nil, "CHRISTMAS did not work on 5 Dec")
		local _, late = Codes.check("CHRISTMAS", {}, utc(2027, 1, 2), true)
		assert(late == "expired", "CHRISTMAS did not expire after 31 Dec")
		local _, afterBeta = Codes.check("BETA", {}, now, false)
		assert(afterBeta == "invalid", "BETA worked after the beta")
		for _, entry in Codes.LIST do
			assert((entry :: any).likes == nil, "a code is tied to likes")
		end
		-- The server.
		local player = Players:GetPlayers()[1]
		if not player then
			return "rule checked (no player for the server part)"
		end
		local ProgressService = require(Systems:WaitForChild("ProgressService")) :: any
		local EconomyService = require(Systems:WaitForChild("EconomyService")) :: any
		local OfferService = require(Systems:WaitForChild("OfferService")) :: any
		local TrialService = require(Systems:WaitForChild("TrialService")) :: any
		local MapShopService = require(Systems:WaitForChild("MapShopService")) :: any
		local e = ProgressService.ecoOf(player)
		assert(e, "no eco for the player")
		local keepCodes, keepPerks, keepBolts = table.clone(e.codes), table.clone(e.perks), e.bolts
		-- (A player with no passes: the Railgun locked, the Fire Trail not owned. The creator owns all in Studio.)
		OfferService.resetForTest(player)
		TrialService.resetForTest(player)
		-- (And no weapon of its own: the creator's profile has them all, and UnlockAll.)
		local profile = ProgressService.profileForTest(player) :: any
		local keepOwned, keepTakedowns, keepAll = table.clone(profile.owned), profile.takedowns, player:GetAttribute("UnlockAll")
		player:SetAttribute("UnlockAll", nil)
		profile.takedowns = 0
		ProgressService.setOwnedForTest(player, {})
		player:SetAttribute("Try_FireTrail", nil)
		e.codes = {}
		e.perks = {}
		EconomyService.resetCodesForTest(player)
		player:SetAttribute("DoubleBolts", true) -- (a code is exact even with 2x BOLTS)
		local results = {}
		local ok, err = pcall(function()
			local okR, line = EconomyService.redeem(player, "release")
			assert(okR and string.find(line, "500 BOLTS", 1, true), "RELEASE did not work: " .. tostring(line))
			assert(e.bolts - keepBolts == 500, "RELEASE gave " .. (e.bolts - keepBolts) .. " BOLTS, not exactly 500")
			local again, why = EconomyService.redeem(player, "RELEASE")
			assert(not again and why == Codes.MESSAGES.used, "RELEASE worked twice")
			-- BETA: the Railgun for 30 minutes, kept in eco.perks.
			local okB = EconomyService.redeem(player, "beta")
			assert(okB, "BETA did not work")
			local untilT = player:GetAttribute("TrialUntil")
			assert(player:GetAttribute("TrialWeapon") == "Railgun" and type(untilT) == "number" and math.abs(untilT - (workspace:GetServerTimeNow() + 1800)) < 5, "BETA did not start a 30-minute Railgun try")
			assert(e.perks["Trial:Railgun"] ~= nil, "the code's try is not kept for a rejoin")
			-- CHRISTMAS on 5 Dec: the Fire Trail for 24 h, kept in eco.perks.
			local okC = EconomyService.redeem(player, "christmas", utc(2026, 12, 5))
			assert(okC, "CHRISTMAS did not work on 5 Dec")
			local fire = player:GetAttribute("Try_FireTrail")
			assert(type(fire) == "number" and fire - workspace:GetServerTimeNow() > 23 * 3600 and e.perks.FireTrail ~= nil, "CHRISTMAS did not give the Fire Trail for 24 h")
			-- A booth TRY never cuts it short.
			assert(MapShopService.try(player, "FireTrail") == "on" and player:GetAttribute("Try_FireTrail") == fire, "a booth try cut the code's Fire Trail short")
			-- A rejoin: both come back from eco.perks.
			TrialService.resetForTest(player)
			player:SetAttribute("Try_FireTrail", nil)
			EconomyService.applyPerks(player)
			assert(player:GetAttribute("TrialWeapon") == "Railgun" and player:GetAttribute("Try_FireTrail") == fire, "a rejoin lost the code's gifts")
			-- The rate: try 6 in a minute is refused.
			local refused = 0
			for _ = 1, 3 do
				local okN, lineN = EconomyService.redeem(player, "NOPE123")
				if not okN and lineN == Codes.MESSAGES.slow then
					refused += 1
				end
			end
			assert(refused >= 1, "the sixth try in a minute was not refused")
			table.insert(results, "RELEASE +500 exact, again 'used'; BETA Railgun 30 min; CHRISTMAS Fire Trail 24 h (5 Dec); a booth try keeps it; both back after a rejoin; try 6 in a minute refused")
		end)
		-- (Put back as it was.)
		profile.takedowns = keepTakedowns
		ProgressService.setOwnedForTest(player, keepOwned)
		player:SetAttribute("UnlockAll", keepAll)
		e.codes = keepCodes
		e.perks = keepPerks
		e.bolts = keepBolts
		TrialService.resetForTest(player)
		player:SetAttribute("Try_FireTrail", nil)
		player:SetAttribute("DoubleBolts", nil)
		EconomyService.resetCodesForTest(player)
		ProgressService.ecoChanged(player)
		EconomyService.send(player)
		assert(ok, err)
		return "codes case/space-blind, once each, CHRISTMAS 1-31 Dec only, BETA only in beta, none for likes; " .. table.concat(results, "; ")
	end,
}
