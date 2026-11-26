--!strict
-- One setting the owner chooses for every server (round 3, M9; the pattern the Christmas switch
-- uses, M7): kept as a record { value, at = server time it was chosen, from = the server }, the
-- newest wins everywhere whatever order messages come in, a server never takes back its own
-- message, the store is read back every CHECK s (a missed message is caught up), saving is tried
-- three times and a failure is told (onSaveFailed). Values are checked by `valid`.

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

local log = Log.new("OwnerSetting")

local OwnerSetting = {}

local STORE = "OwnerSettings_v1"
local CHECK = 60

export type Setting = {
	key: string,
	value: any,
	at: number,
	valid: (unknown) -> boolean,
	changed: (any) -> (),
	onSaveFailed: ((any) -> ())?,
	store: DataStore?,
}

local function adopt(s: Setting, record: unknown): boolean
	if type(record) ~= "table" then
		return false
	end
	local r = record :: any
	local at = tonumber(r.at) or 0
	if not s.valid(r.value) or at <= s.at then
		return false
	end
	s.value, s.at = r.value, at
	s.changed(s.value)
	return true
end

-- A setting with its default; `changed` runs on every change (here or from another server).
function OwnerSetting.new(key: string, default: any, valid: (unknown) -> boolean, changed: (any) -> (), useStore: boolean): Setting
	local s: Setting = { key = key, value = default, at = -1, valid = valid, changed = changed, onSaveFailed = nil, store = nil }
	if useStore then
		local ok, ds = pcall(function()
			return DataStoreService:GetDataStore(STORE)
		end)
		if ok and ds then
			s.store = ds
			local okGet, stored = pcall(function()
				return ds:GetAsync(key)
			end)
			if okGet then
				adopt(s, stored)
			else
				log.warn("could not read " .. key .. " (the default until the next check)")
			end
			pcall(function()
				MessagingService:SubscribeAsync("Owner_" .. key, function(message)
					local data = message.Data
					if type(data) == "table" and data.from ~= game.JobId then
						adopt(s, data)
					end
				end)
			end)
			task.spawn(function()
				while true do
					task.wait(CHECK)
					local okRead, again = pcall(function()
						return ds:GetAsync(key)
					end)
					if okRead then
						adopt(s, again)
					end
				end
			end)
		end
	end
	changed(s.value)
	return s
end

-- The owner's choice: applied here at once, kept, told to every server. False for junk.
function OwnerSetting.set(s: Setting, value: unknown): boolean
	if not s.valid(value) then
		return false
	end
	local record = { value = value, at = Workspace:GetServerTimeNow(), from = game.JobId }
	s.value, s.at = value, record.at
	s.changed(value)
	local ds = s.store
	if ds then
		task.spawn(function()
			local saved = false
			for attempt = 1, 3 do
				saved = pcall(function()
					ds:UpdateAsync(s.key, function(old: any)
						if type(old) == "table" and (tonumber(old.at) or 0) > record.at then
							return nil -- (never over a newer choice made elsewhere meanwhile)
						end
						return record
					end)
				end)
				if saved or attempt == 3 then
					break
				end
				task.wait(2 ^ attempt)
			end
			if not saved then
				log.warn("could not keep " .. s.key)
				local tell = s.onSaveFailed
				if tell then
					tell(value)
				end
			end
			pcall(function()
				MessagingService:PublishAsync("Owner_" .. s.key, record)
			end)
		end)
	end
	return true
end

OwnerSetting.adoptForTest = adopt

return OwnerSetting
