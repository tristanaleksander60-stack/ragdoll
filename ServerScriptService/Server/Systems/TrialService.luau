--!strict
-- Round 5, phase 1b: TRY FREE (the big ragdoll games' Weapons window). A locked weapon can be tried
-- for TRIAL_SECONDS, once per weapon per UTC day, one trial at a time. The server decides it all:
-- the player's attributes TrialWeapon (its id) and TrialUntil (server time) open the weapon in
-- ProgressService.isUnlocked while they last; when time is up both are cleared (the client's bar
-- lets it go: PokeController.pruneLocked). The day's tries are kept in the DataStore Trials_v1
-- (one UpdateAsync per try), in memory in Studio tests and without DataStore access.
-- Remote Trial: client "Try" (a weapon id); server "Started" { id, until } / "Refused" { text }.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local Config = require(Shared:WaitForChild("Config"))
local ProgressService = require(script.Parent.ProgressService)
local Metrics = require(script.Parent.Metrics)

local TrialService = {}

TrialService.SECONDS = 120
TrialService.GAP = 1.5 -- s between two requests from one player
local STORE = "Trials_v1"
local store: DataStore? = nil
local memory: { [number]: { day: number, ids: { string } } } = {}
local lastAsk: { [Player]: number } = {}
local busy: { [Player]: boolean } = {}
local remote: RemoteEvent

local function today(): number
	return math.floor(os.time() / 86400)
end

-- Takes today's try of `id` for this user: "ok" (now used), "taken" (used today) or "error" (the
-- store did not answer: nothing used, try again).
local function take(userId: number, id: string): string
	local day = today()
	local ds = store
	if not ds then
		local m = memory[userId]
		if not m or m.day ~= day then
			m = { day = day, ids = {} }
			memory[userId] = m
		end
		if table.find(m.ids, id) then
			return "taken"
		end
		table.insert(m.ids, id)
		return "ok"
	end
	local took = false
	local ok = pcall(function()
		ds:UpdateAsync(tostring(userId), function(old: any)
			local rec = if type(old) == "table" and old.day == day and type(old.ids) == "table" then old else { day = day, ids = {} }
			if table.find(rec.ids, id) or #rec.ids >= #Toys.list then
				took = false
				return nil
			end
			table.insert(rec.ids, id)
			took = true
			return rec
		end)
	end)
	return if not ok then "error" elseif took then "ok" else "taken"
end

-- Whether a trial is running for this player now.
function TrialService.running(player: Player): string?
	local id = player:GetAttribute("TrialWeapon")
	local untilAt = player:GetAttribute("TrialUntil")
	if type(id) == "string" and type(untilAt) == "number" and untilAt > Workspace:GetServerTimeNow() then
		return id
	end
	return nil
end

local function finish(player: Player, token: number)
	if player:GetAttribute("TrialToken") ~= token then
		return
	end
	player:SetAttribute("TrialWeapon", nil)
	player:SetAttribute("TrialUntil", nil)
	-- (TrialToken stays: an old timer of an earlier trial never ends a newer one.)
end

-- Starts a trial. Returns nil when it started, or why not.
function TrialService.try(player: Player, id: unknown): string?
	-- (Owner, 26 Nov 2026: no TRY FREE for weapons. Admin and code grants still use `grant`.)
	if (Config :: any).WEAPONS_NO_TRY then
		return "junk"
	end
	if type(id) ~= "string" then
		return "junk"
	end
	local toy = Toys.byId[id]
	if not toy or toy.unlockAt <= 0 then
		return "junk"
	end
	if not ProgressService.isLoaded(player) then
		return "Your progress is still loading. Try again in a moment"
	end
	if ProgressService.isUnlocked(player, toy, true) then
		return toy.label .. " is yours already!"
	end
	-- (Busy while the store answers: two quick tries can never both start: review fix.)
	if TrialService.running(player) or busy[player] then
		return "One free try at a time. Wait for this one to end"
	end
	busy[player] = true
	local result = take(player.UserId, toy.id)
	busy[player] = nil
	if result == "error" then
		return "Roblox did not answer. Try again in a moment"
	elseif result == "taken" then
		return "You tried the " .. toy.label .. " today. Come back tomorrow, or unlock it!"
	end
	local prev = player:GetAttribute("TrialToken")
	local token = (if type(prev) == "number" then prev else 0) + 1
	local untilAt = Workspace:GetServerTimeNow() + TrialService.SECONDS
	player:SetAttribute("TrialToken", token)
	player:SetAttribute("TrialWeapon", toy.id)
	player:SetAttribute("TrialUntil", untilAt)
	Metrics.event(player, "Weapon_Trial", 1, toy.id)
	task.delay(TrialService.SECONDS, finish, player, token)
	return nil
end

-- V6-2: the owner gives a player a free try from the admin menu (no store, no daily limit; the
-- same attributes and timer as a normal try, so it ends the same way).
-- (V9-0t: `seconds` for a code's longer try; TRIAL_SECONDS when nil.)
function TrialService.grant(player: Player, id: string, seconds: number?): boolean
	local toy = Toys.byId[id]
	if not toy or toy.unlockAt <= 0 then
		return false
	end
	local length = seconds or TrialService.SECONDS
	local prev = player:GetAttribute("TrialToken")
	local token = (if type(prev) == "number" then prev else 0) + 1
	player:SetAttribute("TrialToken", token)
	player:SetAttribute("TrialWeapon", toy.id)
	player:SetAttribute("TrialUntil", Workspace:GetServerTimeNow() + length)
	task.delay(length, finish, player, token)
	return true
end

function TrialService.start()
	if ProgressService.usesDataStores() then
		local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, STORE)
		store = if ok then ds else nil
	end
	remote = Net.event(Net.Names.Trial)
	remote.OnServerEvent:Connect(function(player: Player, kind: unknown, id: unknown)
		if type(kind) ~= "string" or kind ~= "Try" or type(id) ~= "string" or #id > 40 then
			return
		end
		local now = os.clock()
		if now - (lastAsk[player] or -math.huge) < TrialService.GAP then
			return
		end
		lastAsk[player] = now
		local why = TrialService.try(player, id)
		if why == nil then
			remote:FireClient(player, "Started", { id = id, untilAt = player:GetAttribute("TrialUntil") })
		elseif why ~= "junk" then
			remote:FireClient(player, "Refused", { text = why })
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAsk[player] = nil
		busy[player] = nil
	end)
end

-- Tests: forget today's tries and end a running one.
function TrialService.resetForTest(player: Player)
	memory[player.UserId] = nil
	lastAsk[player] = nil
	finish(player, player:GetAttribute("TrialToken") :: any)
end

return TrialService
