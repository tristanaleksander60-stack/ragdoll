--!strict
-- PerfReport (LAG-FREE 2 items 0 and 1, PERF_MOBILE.md §6; owner: "Sørg for ALT er lagfri på telefon og tablet").
--   0 (Config.LAGFREE_TELEMETRY): once a minute each client sends its FPS p50 and p10, frames over 50 ms, memory and
--     the bodies it simulates; the server logs them as custom events (Fps_p10, Fps_p50, Hitches, MemoryMb) with the
--     device, so the Creator Hub shows the real numbers per device. Never in Studio.
--   1 (Config.LAGFREE_SERVER_KNOWS): the client's quality level (0-3) when it changes; stored as the player's
--     PerfLevel, which the server's caps follow (RagdollDirector near cap, the background boxing).
-- Every value is checked: numbers, clamped, whole; a Stats packet at most once per 30 s, a Level once per 4 s.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PerfReport = {}

local lastStats: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
local lastLevel: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function num(v: unknown, lo: number, hi: number): number?
	if type(v) ~= "number" or v ~= v then
		return nil
	end
	return math.floor(math.clamp(v, lo, hi) + 0.5)
end

local function log(player: Player, name: string, value: number, device: string)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, name, value, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = device })
	end)
end

function PerfReport.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not (Config.LAGFREE_TELEMETRY or Config.LAGFREE_SERVER_KNOWS) then
		return
	end
	local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any
	Net.event(Net.Names.PerfReport).OnServerEvent:Connect(function(player: Player, kind: unknown, data: unknown)
		if type(kind) ~= "string" or (kind ~= "Level" and kind ~= "Stats") then
			return
		end
		local now = os.clock()
		if kind == "Level" and Config.LAGFREE_SERVER_KNOWS then
			if now - (lastLevel[player] or -math.huge) < 4 then
				return
			end
			local l = num(data, 0, 3)
			if l then
				lastLevel[player] = now
				player:SetAttribute("PerfLevel", l)
			end
		elseif kind == "Stats" and Config.LAGFREE_TELEMETRY and type(data) == "table" then
			if now - (lastStats[player] or -math.huge) < 30 then
				return
			end
			lastStats[player] = now
			local d = data :: any
			local p50, p10 = num(d.p50, 0, 240), num(d.p10, 0, 240)
			local hitches, mem = num(d.hitches, 0, 3600), num(d.mem, 0, 16000)
			if not (p50 and p10 and hitches and mem) then
				return
			end
			if RunService:IsStudio() then
				return -- (Studio numbers are not real devices)
			end
			local device = tostring(player:GetAttribute("Device") or "?")
			log(player, "Fps_p50", p50, device)
			log(player, "Fps_p10", p10, device)
			log(player, "Hitches", hitches, device)
			log(player, "MemoryMb", mem, device)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		lastStats[p] = nil
		lastLevel[p] = nil
	end)
	-- (LAG-FREE 2 item 8: the server's own step time, once a minute: the slowest step and the share of steps over
	-- 1/45 s, logged on the first player as ServerStepMaxMs / ServerSlowPct; never in Studio)
	if Config.LAGFREE_TELEMETRY and not RunService:IsStudio() then
		local steps, slow, worst = 0, 0, 0
		RunService.Heartbeat:Connect(function(dt)
			steps += 1
			if dt > 1 / 45 then
				slow += 1
			end
			if dt > worst then
				worst = dt
			end
		end)
		task.spawn(function()
			while true do
				task.wait(60)
				local first = Players:GetPlayers()[1]
				if first and steps > 0 then
					log(first, "ServerStepMaxMs", math.floor(worst * 1000 + 0.5), "server")
					log(first, "ServerSlowPct", math.floor(slow / steps * 100 + 0.5), "server")
				end
				steps, slow, worst = 0, 0, 0
			end
		end)
	end
end

return PerfReport
