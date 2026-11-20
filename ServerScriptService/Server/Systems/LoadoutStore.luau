--!strict
-- Your tool bar, kept between visits: up to six tools in the order you put them (round 2, N4: a
-- slot can be left empty with UNEQUIP). The client says what it wants ("Set"), the server checks
-- it (one to six different tools from the catalog) and keeps it;
-- on join the server sends it back ("Load"). Saved when you leave and a few seconds after a change.
-- In Studio without DataStore access (and during self-tests) it lives in memory for the session.
-- Unlocks are not checked here: a bar may name a tool its owner has not unlocked on this account
-- (or not loaded yet); using it is refused by HitService ("Unlock"/"Loading") and the hand stays
-- empty of it (HeldService), so a bar is only ever a list of wishes.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Toys = require(Shared.Toys)
local Config = require(Shared.Config)
local Log = require(Shared.Log)

local log = Log.new("Loadout")

local STORE = "Loadout_v1"
local SAVE_DELAY = 8 -- s after the last change
local SETS_PER_MINUTE = 30
local RETRIES = 3

local LoadoutStore = {}

local remote: RemoteEvent
local store: DataStore? = nil
local memory: { [number]: { string } } = {}
local current: { [Player]: { string } } = {}
local dirty: { [Player]: number } = {} -- a token per pending save
local window: { [Player]: { start: number, count: number } } = {}
-- Saving waits until the player's stored bar has been read: a bar set before then is kept (it is
-- newer) and saved once the read is done; if the read failed, nothing is saved this session, so a
-- hiccup at join never overwrites what was stored.
local loaded: { [Player]: boolean } = {}
local readFailed: { [Player]: boolean } = {}

-- One to SLOTS different tools that exist, or nil (a longer list, saved when the bar had six, keeps
-- its first SLOTS).
function LoadoutStore.validate(list: unknown): { string }?
	if type(list) ~= "table" then
		return nil
	end
	-- (Round 2, N4: 1 to SLOTS tools. UNEQUIP leaves a slot empty; a bar is never empty.)
	local t = list :: { any }
	if #t < 1 then
		return nil
	end
	local seen: { [string]: boolean } = {}
	local clean = {}
	for i = 1, math.min(#t, Toys.SLOTS) do
		local id = t[i]
		if type(id) ~= "string" or not Toys.byId[id] or seen[id] then
			return nil
		end
		seen[id] = true
		table.insert(clean, id)
	end
	return clean
end

local function retry(fn: () -> any): (boolean, any)
	local lastError: any = nil
	for attempt = 1, RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < RETRIES then
			task.wait(attempt)
		end
	end
	log.warn(tostring(lastError))
	return false, lastError
end

local function load(userId: number): (boolean, { string }?)
	local ds = store
	if not ds then
		return true, memory[userId]
	end
	local ok, value = retry(function()
		return ds:GetAsync(tostring(userId))
	end)
	return ok, if ok then LoadoutStore.validate(value) else nil
end

local saving = 0 -- saves in flight (BindToClose waits for them)

local function save(userId: number, list: { string }): boolean
	local ds = store
	if not ds then
		memory[userId] = table.clone(list)
		return true
	end
	saving += 1
	local ok = retry(function()
		ds:SetAsync(tostring(userId), list, { userId })
	end)
	saving -= 1
	return ok
end

local function scheduleSave(player: Player)
	local token = (dirty[player] or 0) + 1
	dirty[player] = token
	task.delay(SAVE_DELAY, function()
		if dirty[player] == token and current[player] and loaded[player] and not readFailed[player] then
			-- The flag clears only when the save went through (a change made meanwhile keeps it).
			if save(player.UserId, current[player]) and dirty[player] == token then
				dirty[player] = nil
			end
		end
	end)
end

-- V8-0.3 (Config.V8_START_BAR): a saved bar moves to the full start bar once. Poke, Slap and Heal
-- leave it; Bat, Grenade and Launch go in while there is room; the rest stays where it was (and
-- everything stays owned, in WEAPONS). A flag key beside the bar ("<userId>_v8bar") makes it run
-- once: a Poke put back later stays.
LoadoutStore.V8_OUT = table.freeze({ Poke = true, Slap = true, Heal = true }) :: { [string]: boolean }
LoadoutStore.V8_IN = table.freeze({ "Bat", "Grenade", "Launch" }) :: { string }
function LoadoutStore.migrateV8(list: { string }): { string }
	local out = {}
	for _, id in list do
		if not LoadoutStore.V8_OUT[id] then
			table.insert(out, id)
		end
	end
	for _, id in LoadoutStore.V8_IN do
		if not table.find(out, id) and #out < Toys.SLOTS and Toys.byId[id] then
			table.insert(out, id)
		end
	end
	return out
end
local migratedMemory: { [number]: boolean } = {}
local function v8Done(userId: number): (boolean, boolean)
	local ds = store
	if not ds then
		return true, migratedMemory[userId] == true
	end
	local ok, value = retry(function()
		return ds:GetAsync(tostring(userId) .. "_v8bar")
	end)
	return ok, ok and value == true
end
local function markV8(userId: number): boolean
	local ds = store
	if not ds then
		migratedMemory[userId] = true
		return true
	end
	return (retry(function()
		-- (A write-once flag: it only ever goes to true.)
		ds:UpdateAsync(tostring(userId) .. "_v8bar", function()
			return true, { userId }
		end)
	end))
end
-- Tests: whether bars live in memory only (no DataStore: Studio without API access, self-tests).
function LoadoutStore.inMemory(): boolean
	return store == nil
end
-- Run the one-time move on a stored bar as a join does.
function LoadoutStore.migrateOnce(userId: number, list: { string }): { string }
	local okFlag, done = v8Done(userId)
	if okFlag and not done then
		local moved = LoadoutStore.migrateV8(list)
		if save(userId, moved) and markV8(userId) then
			return moved
		end
	end
	return list
end

local READ_RETRIES = 3
local READ_RETRY_GAP = 20 -- s

local function onJoin(player: Player)
	local ok, list = load(player.UserId)
	-- A failed read is tried again a few times in the background; until one works nothing is saved
	-- (it would overwrite the stored bar), and the bar set meanwhile is saved as soon as it does.
	local tries = 1
	while not ok and tries <= READ_RETRIES and player.Parent do
		loaded[player] = true
		readFailed[player] = true
		task.wait(READ_RETRY_GAP)
		tries += 1
		ok, list = load(player.UserId)
	end
	if not player.Parent then
		return
	end
	loaded[player] = true
	readFailed[player] = not ok or nil
	if current[player] then
		scheduleSave(player) -- set while the read was running: newer than what was stored
		if ok and list == nil and (Config :: any).V8_START_BAR then
			task.spawn(markV8, player.UserId) -- (a new player's own bar: never moved later; fix round 2)
		end
	elseif list then
		if (Config :: any).V8_START_BAR and ok then
			list = LoadoutStore.migrateOnce(player.UserId, list)
		end
		-- (Blind review: the move yields on the store; a bar set meanwhile is newer and wins.)
		if current[player] then
			scheduleSave(player)
		elseif player.Parent then
			current[player] = list
			remote:FireClient(player, "Load", list)
		end
	elseif ok and (Config :: any).V8_START_BAR then
		-- (A new player starts on the V8 bar: marked now, so a Poke they put on it later is never
		-- moved off by the one-time move. Blind review, 21 Nov.)
		task.spawn(markV8, player.UserId)
	end
end

-- lihfolk-ignore: remote-unvalidated-args (kind is only compared with "Set"; list goes through validate)
local function onSet(player: Player, kind: unknown, list: unknown)
	if kind ~= "Set" then
		return
	end
	local now = os.clock()
	local w = window[player]
	if not w or now - w.start > 60 then
		w = { start = now, count = 0 }
		window[player] = w
	end
	w.count += 1
	if w.count > SETS_PER_MINUTE then
		return
	end
	local clean = LoadoutStore.validate(list)
	if not clean then
		return
	end
	current[player] = clean
	scheduleSave(player)
end

-- Tests: the remote handler.
LoadoutStore.onSet = function(player: Player, kind: unknown, list: unknown)
	onSet(player, kind, list)
end

-- Tests: what the server holds for a player.
function LoadoutStore.get(player: Player): { string }?
	return current[player]
end

function LoadoutStore.start()
	if not RunService:IsStudio() then
		store = DataStoreService:GetDataStore(STORE) -- live servers: never wait on a probe at boot
	else
		local testing = game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true or game:GetService("ServerStorage"):GetAttribute("StudioFresh") == true -- (StudioFresh: a brand-new player)
		local usable = not testing and pcall(function()
			DataStoreService:GetDataStore(STORE):GetAsync("probe")
		end)
		if usable then
			store = DataStoreService:GetDataStore(STORE)
		end
	end
	remote = Net.event(Net.Names.Loadout)
	remote.OnServerEvent:Connect(onSet)
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local list = current[player]
		if list and dirty[player] and loaded[player] and not readFailed[player] then
			dirty[player] = nil -- BindToClose (if the server is closing) does not save it again
			task.spawn(save, player.UserId, list)
		end
		current[player] = nil
		dirty[player] = nil
		window[player] = nil
		loaded[player] = nil
		readFailed[player] = nil
	end)
	game:BindToClose(function()
		-- All at once (the server has about 30 s), and wait for every one.
		local pending = 0
		for player, list in current do
			if dirty[player] and loaded[player] and not readFailed[player] then
				pending += 1
				task.spawn(function()
					save(player.UserId, list)
					pending -= 1
				end)
			end
		end
		local started = os.clock()
		while (pending > 0 or saving > 0) and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
	log.info("ready" .. (if store then "" else " (in memory)"))
end

return LoadoutStore
