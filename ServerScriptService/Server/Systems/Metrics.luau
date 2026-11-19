--!strict
-- What players do, counted for the Creator Dashboard (phase Å: fixes and updates follow the
-- numbers). Roblox's AnalyticsService custom events, from the server only. A few names, never a
-- flood: each name counts at most once per player every MIN_GAP seconds (a run of takedowns is one
-- "Takedowns" event with the count), and a failing call never breaks the game.
--
-- Names (Dashboard > Analytics > Custom): Place_<id> (a trip), Game_<RLGL|Shoot> (score),
-- Egg_<rarity>, RankUp_<rank>, Unlock_<tool>, Horde_<Cleared|Time>, Pass_<key> (bought),
-- FreeUltra, Streamer_On, Takedowns (a session's total, on leaving); round 3: Goal_<kind>,
-- Goals_All, AdminShow_Watched, Xmas_PresentEgg.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Metrics = {}

local MIN_GAP = 1 -- s per player per name
local last: { [Player]: { [string]: number } } = {}
local sessionTakedowns: { [Player]: number } = {}

-- Counts one event (value: a number to sum or average on the Dashboard, 1 by default).
-- item (10 Nov 2026, the audit): which weapon or place, sent as a custom field under one fixed
-- event name ("Unlock" + "Katana"), never in the name itself: Roblox keeps only a limited number of
-- distinct event names, and one per weapon ran past it.
function Metrics.event(player: Player, name: string, value: number?, item: string?)
	if RunService:IsStudio() then
		return -- (Studio sends nothing to the Dashboard)
	end
	local now = os.clock()
	local mine = last[player] or {}
	last[player] = mine
	local key = name .. "|" .. (item or "")
	if mine[key] and now - mine[key] < MIN_GAP then
		return
	end
	mine[key] = now
	pcall(function()
		if item then
			AnalyticsService:LogCustomEvent(player, string.sub(name, 1, 50), value or 1, {
				[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = string.sub(item, 1, 50),
			})
		else
			AnalyticsService:LogCustomEvent(player, string.sub(name, 1, 50), value or 1)
		end
	end)
end

-- Takedowns are summed for the session and sent once, on leaving.
function Metrics.takedowns(player: Player, count: number)
	sessionTakedowns[player] = (sessionTakedowns[player] or 0) + count
end

function Metrics.start()
	Players.PlayerRemoving:Connect(function(player)
		local n = sessionTakedowns[player]
		if n and n > 0 then
			Metrics.event(player, "Takedowns", n)
		end
		sessionTakedowns[player] = nil
		last[player] = nil
	end)
end

return Metrics
