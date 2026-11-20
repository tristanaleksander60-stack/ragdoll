--!strict
-- V8-0.6 (a calm first three minutes): no NPC chase for a newcomer before CALM_CHASE_AFTER s in the
-- game AND CALM_CHASE_KOS takedowns this visit; a returner is never held back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local ChaseService = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("ChaseService")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T123_ChaseGate",
	timeout = 20,
	run = function(): string?
		if not Config.V8_CALM_START then
			return "skipped (V8_CALM_START off)"
		end
		TestLib.waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		local wasNew, wasJoined = p:GetAttribute("Newcomer"), p:GetAttribute("V8JoinedAt")
		local ok, err = pcall(function()
			local now = Workspace:GetServerTimeNow()
			p:SetAttribute("Newcomer", true)
			p:SetAttribute("V8JoinedAt", now - 10)
			assert(not ChaseService.calmAllows(p, 100), "a newcomer 10 s in got a chase")
			-- (The first call above set this visit's starting takedowns to 100.)
			p:SetAttribute("V8JoinedAt", now - (Config.CALM_CHASE_AFTER + 5))
			assert(not ChaseService.calmAllows(p, 100 + Config.CALM_CHASE_KOS - 1), "a newcomer with too few KOs got a chase")
			p:SetAttribute("V8JoinedAt", now - (Config.CALM_CHASE_AFTER - 5))
			assert(not ChaseService.calmAllows(p, 100 + Config.CALM_CHASE_KOS), "a newcomer short of the time got a chase")
			p:SetAttribute("V8JoinedAt", now - (Config.CALM_CHASE_AFTER + 5))
			assert(ChaseService.calmAllows(p, 100 + Config.CALM_CHASE_KOS), "a newcomer past both never gets a chase")
			p:SetAttribute("Newcomer", false)
			p:SetAttribute("V8JoinedAt", now)
			assert(ChaseService.calmAllows(p, 0), "a returner was held back")
		end)
		p:SetAttribute("Newcomer", wasNew)
		p:SetAttribute("V8JoinedAt", wasJoined)
		assert(ok, err)
		return string.format("newcomer: no chase before %d s and %d KOs (both); returners unaffected", Config.CALM_CHASE_AFTER, Config.CALM_CHASE_KOS)
	end,
}
