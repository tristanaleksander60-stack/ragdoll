--!strict
-- Saved builds and share codes.
--
-- Every player has three save slots (DataStore "Builds_v1", key "u<userId>"). A slot holds the
-- packed blueprint (Codec.pack: binary, zstd, base64), its part count and when it was saved. Loading
-- always goes through Codec.unpack (size, format and every build rule checked) and then
-- BuildService.load, so a damaged or tampered save can never put anything odd in the world.
--
-- Sharing: a build gets a 6-character code (DataStore "Shares_v1", key "c<code>"). Codes are drawn
-- from consonants and digits only, so they never spell words, and there is no other text anywhere:
-- no names, no descriptions. Sharing the same build again gives the same code. Anyone who types a
-- code gets a copy of that build in their own workshop.
--
-- Studio without API access (and any session where the DataStores cannot be reached at start)
-- falls back to an in-memory store, so everything still works there for the session.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Log)
local Codec = require(Shared.Build.Codec)
local ShareCode = require(Shared.Build.ShareCode)

local BuildService = require(script.Parent.BuildService)

local log = Log.new("Saves")

local BuildStore = {}

BuildStore.SLOTS = 3
local RECORD_VERSION = 1
local COOLDOWN = { save = 3, load = 1, share = 10, code = 2, delete = 1, list = 0.5 }
local CODE_TRIES = 6
local RETRIES = 3

export type SlotInfo = { pieces: number, at: number }
type SlotRecord = { data: string, pieces: number, at: number }
type UserRecord = { v: number, slots: { [string]: SlotRecord }, share: { code: string, data: string }? }
type ShareRecord = { v: number, data: string, by: number, pieces: number, at: number }

type Store = {
	get: (key: string) -> (boolean, any),
	update: (key: string, transform: (any) -> any) -> (boolean, any),
}

local function dataStore(name: string): Store
	local ds = DataStoreService:GetDataStore(name)
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
		log.warn(name .. ": " .. tostring(lastError))
		return false, lastError
	end
	return {
		get = function(key: string)
			return retry(function()
				return ds:GetAsync(key)
			end)
		end,
		update = function(key: string, transform: (any) -> any)
			return retry(function()
				return ds:UpdateAsync(key, transform)
			end)
		end,
	}
end

-- Same behaviour as a DataStore (a transform returning nil cancels), kept in this server only.
local function memoryStore(): Store
	local data: { [string]: any } = {}
	return {
		get = function(key: string)
			return true, data[key]
		end,
		update = function(key: string, transform: (any) -> any)
			local result = transform(data[key])
			if result == nil then
				return true, nil
			end
			data[key] = result
			return true, result
		end,
	}
end

local builds: Store
local shares: Store
local inMemory = false
local ready = false

local records: { [Player]: UserRecord } = {}
local loading: { [Player]: boolean } = {}
local busy: { [Player]: boolean } = {}
local lastUse: { [Player]: { [string]: number } } = {}

local function emptyRecord(): UserRecord
	return { v = RECORD_VERSION, slots = {} }
end

-- A record read from the store, checked field by field (anything malformed is dropped).
local function sanitize(raw: any): UserRecord
	local record = emptyRecord()
	if type(raw) ~= "table" then
		return record
	end
	if type(raw.slots) == "table" then
		for i = 1, BuildStore.SLOTS do
			local slot = raw.slots[tostring(i)]
			if type(slot) == "table" and type(slot.data) == "string" and type(slot.pieces) == "number" and type(slot.at) == "number" then
				record.slots[tostring(i)] = { data = slot.data, pieces = slot.pieces, at = slot.at }
			end
		end
	end
	if type(raw.share) == "table" and type(raw.share.code) == "string" and type(raw.share.data) == "string" then
		record.share = { code = raw.share.code, data = raw.share.data }
	end
	return record
end

local function keyOf(player: Player): string
	return "u" .. player.UserId
end

local function recordOf(player: Player): UserRecord?
	if records[player] then
		return records[player]
	end
	if loading[player] then
		local t0 = os.clock()
		while loading[player] and os.clock() - t0 < 15 do
			task.wait(0.1)
		end
		return records[player]
	end
	loading[player] = true
	local ok, raw = builds.get(keyOf(player))
	loading[player] = nil
	if not ok then
		return nil
	end
	if player.Parent then
		records[player] = sanitize(raw)
	end
	return records[player]
end

local function slotList(record: UserRecord): { SlotInfo | false }
	local list: { SlotInfo | false } = {}
	for i = 1, BuildStore.SLOTS do
		local slot = record.slots[tostring(i)]
		list[i] = if slot then { pieces = slot.pieces, at = slot.at } else false
	end
	return list
end

local function isSlot(v: unknown): boolean
	return type(v) == "number" and v % 1 == 0 and v >= 1 and v <= BuildStore.SLOTS
end

------------------------------------------------------------------------------------------------
-- Operations (each returns ok, message, payload)

local ops: { [string]: (Player, any) -> (boolean, string?, any) } = {}

ops.list = function(player)
	local record = recordOf(player)
	if not record then
		return false, "Saves are not available right now", nil
	end
	return true, nil, { slots = slotList(record), share = if record.share then record.share.code else nil }
end

ops.save = function(player, slot)
	if not isSlot(slot) then
		return false, "Pick a slot", nil
	end
	local bp = BuildService.blueprintOf(player)
	if #bp.pieces == 0 then
		return false, "Build something first", nil
	end
	local data = Codec.pack(bp)
	local entry: SlotRecord = { data = data, pieces = #bp.pieces, at = os.time() }
	local ok, result = builds.update(keyOf(player), function(old)
		local record = sanitize(old)
		record.slots[tostring(slot)] = entry
		return record
	end)
	if not ok or result == nil then
		return false, "Could not save, try again in a moment", nil
	end
	records[player] = sanitize(result)
	return true, "Saved to slot " .. slot, { slots = slotList(records[player]) }
end

ops.delete = function(player, slot)
	if not isSlot(slot) then
		return false, "Pick a slot", nil
	end
	local ok, result = builds.update(keyOf(player), function(old)
		local record = sanitize(old)
		record.slots[tostring(slot)] = nil
		return record
	end)
	if not ok or result == nil then
		return false, "Could not delete, try again in a moment", nil
	end
	records[player] = sanitize(result)
	return true, "Slot " .. slot .. " is empty", { slots = slotList(records[player]) }
end

ops.load = function(player, slot)
	if not isSlot(slot) then
		return false, "Pick a slot", nil
	end
	local record = recordOf(player)
	if not record then
		return false, "Saves are not available right now", nil
	end
	local entry = record.slots[tostring(slot)]
	if not entry then
		return false, "That slot is empty", nil
	end
	local bp = Codec.unpack(entry.data)
	if not bp then
		return false, "That save could not be read", nil
	end
	local ok = BuildService.load(player, bp)
	if not ok then
		return false, "That save could not be loaded", nil
	end
	return true, "Loaded slot " .. slot, nil
end

ops.share = function(player)
	local bp = BuildService.blueprintOf(player)
	if #bp.pieces == 0 then
		return false, "Build something first", nil
	end
	local data = Codec.pack(bp)
	local record = recordOf(player)
	if record and record.share and record.share.data == data then
		return true, nil, { code = record.share.code }
	end
	local rng = Random.new()
	for _ = 1, CODE_TRIES do
		local code = ShareCode.generate(rng)
		local entry: ShareRecord = { v = RECORD_VERSION, data = data, by = player.UserId, pieces = #bp.pieces, at = os.time() }
		local ok, result = shares.update("c" .. code, function(old)
			if old ~= nil then
				return nil -- taken: try another code
			end
			return entry
		end)
		if not ok then
			return false, "Could not share, try again in a moment", nil
		end
		if result ~= nil then
			-- Remember it, so sharing the same build again gives the same code.
			local saved, updated = builds.update(keyOf(player), function(old)
				local r = sanitize(old)
				r.share = { code = code, data = data }
				return r
			end)
			if saved and updated then
				records[player] = sanitize(updated)
			end
			return true, nil, { code = code }
		end
	end
	return false, "Could not share, try again in a moment", nil
end

ops.code = function(player, raw)
	local code = ShareCode.normalize(raw)
	if not code then
		return false, "Codes are " .. ShareCode.LENGTH .. " letters and numbers", nil
	end
	local ok, entry = shares.get("c" .. code)
	if not ok then
		return false, "Could not look that up, try again in a moment", nil
	end
	if type(entry) ~= "table" or type(entry.data) ~= "string" then
		return false, "No build with that code", nil
	end
	local bp = Codec.unpack(entry.data)
	if not bp then
		return false, "That build could not be read", nil
	end
	if not BuildService.load(player, bp) then
		return false, "That build could not be loaded", nil
	end
	return true, "Loaded build " .. code, nil
end

function BuildStore.request(player: Player, op: unknown, arg: unknown): (boolean, string?, any)
	if type(op) ~= "string" or not ops[op] then
		return false, nil, nil
	end
	local t0 = os.clock()
	while not ready and os.clock() - t0 < 10 do
		task.wait(0.1)
	end
	if busy[player] then
		return false, "One moment...", nil
	end
	local uses = lastUse[player]
	if not uses then
		uses = {}
		lastUse[player] = uses
	end
	local now = os.clock()
	local wait = COOLDOWN[op] or 1
	if uses[op] and now - uses[op] < wait then
		return false, "One moment...", nil
	end
	uses[op] = now
	busy[player] = true
	local okCall, success, message, payload = pcall(ops[op], player, arg)
	busy[player] = nil
	if not okCall then
		log.warn(op .. " failed: " .. tostring(success))
		return false, "Something went wrong, try again", nil
	end
	return success, message, payload
end

function BuildStore.isInMemory(): boolean
	return inMemory
end

function BuildStore.start()
	builds = dataStore("Builds_v1")
	shares = dataStore("Shares_v1")
	-- Studio without API access fails every call straight away: probe once and use memory there.
	-- A live server always uses the real stores (a hiccup there is retried and reported, never
	-- silently swapped for something that forgets).
	-- Self-tests in Studio never touch real saves either.
	if RunService:IsStudio() then
		local testing = game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true
		local probeOk = not testing and pcall(function()
			DataStoreService:GetDataStore("Builds_v1"):GetAsync("probe")
		end)
		if not probeOk then
			inMemory = true
			builds = memoryStore()
			shares = memoryStore()
			log.info(if testing
				then "self-test run: saves and codes use a memory store"
				else "no DataStore access in Studio: saves and codes last for this session only")
		end
	end
	ready = true

	local fn = Net.func(Net.Names.BuildStore)
	fn.OnServerInvoke = function(player: Player, op: unknown, arg: unknown)
		return BuildStore.request(player, op, arg)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(recordOf, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(recordOf, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		records[player] = nil
		loading[player] = nil
		busy[player] = nil
		lastUse[player] = nil
	end)
	log.info("ready" .. (if inMemory then " (in memory)" else ""))
end

-- Tests: run an operation without the cooldowns.
function BuildStore.direct(player: Player, op: string, arg: any): (boolean, string?, any)
	return ops[op](player, arg)
end

return BuildStore
