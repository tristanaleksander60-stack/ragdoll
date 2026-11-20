--!strict
-- Who owns the game (round 3, M7; was MoneyService's): the place's creator, or rank 255 in its
-- group. Always checked on the server. In Studio the tester is the owner, unless a test says
-- otherwise (Owner.studioOwnerForTest = false, to check a refusal).

local RunService = game:GetService("RunService")

local Owner = {}

Owner.studioOwnerForTest = true

function Owner.isOwner(player: Player): boolean
	-- (V8-0.8: a play-as-newcomer visit, in Studio too, gets no owner perks.)
	if (require(script.Parent:WaitForChild("TestAccount")) :: any).is(player) then
		return false
	end
	if RunService:IsStudio() then
		return Owner.studioOwnerForTest
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local ok, rank = pcall(function()
		return player:GetRankInGroup(game.CreatorId)
	end)
	return ok and type(rank) == "number" and rank >= 255
end

return Owner
