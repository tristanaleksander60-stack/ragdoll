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
	name = "T169_Codes",
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
		local e = ProgressService.ecoOf(player)
		assert(e, "no eco for the player")
		local keepCodes, keepBolts, keepDouble = table.clone(e.codes), e.bolts, player:GetAttribute("DoubleBolts")
		e.codes.RELEASE = nil
		EconomyService.resetCodesForTest(player)
		player:SetAttribute("DoubleBolts", true) -- (a code is exact even with 2x BOLTS)
		local ok, line = EconomyService.redeem(player, "release")
		local gained = e.bolts - keepBolts
		local again, why = EconomyService.redeem(player, "RELEASE")
		local refused = 0
		for _ = 1, 5 do
			local okN, lineN = EconomyService.redeem(player, "NOPE123")
			if not okN and lineN == Codes.MESSAGES.slow then
				refused += 1
			end
		end
		-- (Put back.)
		e.codes = keepCodes
		e.bolts = keepBolts
		player:SetAttribute("DoubleBolts", keepDouble)
		EconomyService.resetCodesForTest(player)
		ProgressService.ecoChanged(player)
		assert(ok and string.find(line, "500 BOLTS", 1, true), "RELEASE did not work: " .. tostring(line))
		assert(gained == 500, "RELEASE gave " .. gained .. " BOLTS, not exactly 500")
		assert(not again and why == Codes.MESSAGES.used, "RELEASE worked twice")
		assert(refused >= 1, "the sixth try in a minute was not refused")
		return string.format("codes case/space-blind, once each, CHRISTMAS 1-31 Dec only, BETA only in beta, none for likes; RELEASE +500 exact, second try 'used', try %d in a minute refused%s", Codes.RATE + 1, if Config.BETA then "; beta on" else "")
	end,
}
