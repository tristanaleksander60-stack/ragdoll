--!strict
-- V8-0.8: the play-as-newcomer mode. A listed adult test account (Config.TEST_ACCOUNTS, never the
-- owner's own account) joins the LIVE game as a brand-new player on every visit, so playtest rounds
-- see what a real newcomer sees: a blank profile kept in memory and never saved over its real one,
-- Newcomer set, passes ignored, no owner perks (IsOwner off, no admin, no OWNER or VIP tag). Its
-- Session_v1 records carry test = true and the reports leave them out. In Studio, ServerStorage
-- StudioFresh = true turns the same mode on for the Studio user.
-- Leaf module: only Config and services.

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any

local TestAccount = {}

-- Whether this player plays as a brand-new player this visit.
function TestAccount.is(player: Player): boolean
	if RunService:IsStudio() then
		return ServerStorage:GetAttribute("StudioFresh") == true
	end
	if player.UserId == game.CreatorId then
		return false -- (never the owner's own account)
	end
	for _, id in Config.TEST_ACCOUNTS or {} do
		if id == player.UserId then
			return true
		end
	end
	return false
end

return TestAccount
