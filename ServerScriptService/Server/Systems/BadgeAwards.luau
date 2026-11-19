--!strict
-- Badges (phase D, 10 Nov 2026): Roblox badges for the first steps that keep a new player here
-- (welcome, first takedown, first egg, 5 minutes, bullseye) and two long goals. Ids live in
-- Shared/Badges (0 = not created yet: nothing is sent). Each badge is asked for at most once per
-- visit per player, off the caller's thread, and a failing call never breaks the game. Studio and
-- the self-tests never send (the session table still records it, so tests can read `earned`).

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badges = require(ReplicatedStorage.Shared.Badges)

local BadgeAwards = {}

local earned: { [Player]: { [string]: boolean } } = {}

local function sends(): boolean
	return not RunService:IsStudio() and ServerStorage:GetAttribute("RunSelfTest") ~= true
end

-- Gives `key` to the player (once per visit; Roblox itself ignores a badge already owned).
function BadgeAwards.award(player: Player, key: string)
	local badge = Badges.byKey[key]
	if not badge or not player.Parent then
		return
	end
	local mine = earned[player]
	if not mine then
		mine = {}
		earned[player] = mine
	end
	if mine[key] then
		return
	end
	mine[key] = true
	if badge.id == 0 or not sends() then
		return
	end
	task.spawn(function()
		for attempt = 1, 3 do
			local ok, result = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badge.id)
			if ok or not player.Parent then
				return
			end
			warn(string.format("[Badges] %s for %d failed (%s), try %d", key, player.UserId, tostring(result), attempt))
			task.wait(5 * attempt)
		end
	end)
end

function BadgeAwards.earned(player: Player, key: string): boolean
	local mine = earned[player]
	return mine ~= nil and mine[key] == true
end

-- The takedown badges follow the player's lifetime total (ProgressService calls this).
function BadgeAwards.takedowns(player: Player, total: number)
	if total >= 1 then
		BadgeAwards.award(player, "FirstTakedown")
	end
	if total >= 100 then
		BadgeAwards.award(player, "Takedowns100")
	end
	if total >= 1000 then
		BadgeAwards.award(player, "Takedowns1000")
	end
end

local function join(player: Player)
	BadgeAwards.award(player, "Welcome")
	task.delay(Badges.FIVE_MINUTES, function()
		if player.Parent then
			BadgeAwards.award(player, "FiveMinutes")
		end
	end)
end

function BadgeAwards.start()
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		task.spawn(join, player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		earned[player] = nil
	end)
end

return BadgeAwards
