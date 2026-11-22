--!strict
-- FunnelReport (V10 phase 1): the new-player funnel per device, READ-ONLY, from Session_v1 (SessionStats).
-- Run in Studio (Edit, the MCP's execute_luau or the command bar) with API access on. Never writes.
-- SINCE: a UTC time (os.time) to count from, e.g. when a build went live; MAX_READ caps the slow reads
-- (Roblox lets Studio read about one record a second), newest first.
-- Steps, each the share of the device's new players who reached it:
--   joined, first frame, lab loaded (LoadCover), first shot, a hit, a ragdoll down, a machine (first
--   launch), a new weapon (first unlock), then still there at 1, 3, 5 and 10 minutes.

local SINCE = os.time() - 24 * 3600
local MAX_READ = 150

local store = game:GetService("DataStoreService"):GetDataStore("Session_v1")
local keys = {}
local pages = store:ListKeysAsync()
while true do
	for _, k in pages:GetCurrentPage() do
		local u, j = string.match(k.KeyName, "^(%d+)_(%d+)$")
		if u and tonumber(j) and (tonumber(j) :: number) >= SINCE and tonumber(u) ~= game.CreatorId then
			table.insert(keys, { k = k.KeyName, at = tonumber(j) :: number })
		end
	end
	if pages.IsFinished then
		break
	end
	pages:AdvanceToNextPageAsync()
end
table.sort(keys, function(a, b)
	return a.at > b.at
end)

local STEPS = { "joined", "frame", "loaded", "shot", "hit", "down", "machine", "unlock", "1min", "3min", "5min", "10min" }
local by: { [string]: { [string]: number } } = {}
for i, k in keys do
	if i > MAX_READ then
		break
	end
	local ok, r = pcall(store.GetAsync, store, k.k)
	if ok and type(r) == "table" and r.owner ~= true and r.test ~= true and r.newPlayer == true then
		local dev = if r.plat == "phone" or r.plat == "tablet" then r.plat else "pc"
		local t = by[dev] or {}
		by[dev] = t
		local played = (r.left or 0) - (r.frame0 or 0)
		local reached = {
			joined = true,
			frame = r.frame0 ~= nil,
			loaded = r.loadedAt ~= nil,
			shot = r.firstShot ~= nil or r.clientShot ~= nil,
			hit = (r.hits or 0) > 0,
			down = r.firstKnockAt ~= nil or (r.knocks or 0) > 0,
			machine = r.firstLaunchAt ~= nil,
			unlock = r.firstUnlockAt ~= nil,
			["1min"] = played >= 60,
			["3min"] = played >= 180,
			["5min"] = played >= 300,
			["10min"] = played >= 600,
		}
		for _, s in STEPS do
			if reached[s] then
				t[s] = (t[s] or 0) + 1
			end
		end
	end
end
for dev, t in by do
	local n = t.joined or 0
	local line = {}
	for _, s in STEPS do
		table.insert(line, string.format("%s %d%%", s, math.floor(100 * (t[s] or 0) / math.max(n, 1) + 0.5)))
	end
	print(string.format("[Funnel] %s n=%d | %s", dev, n, table.concat(line, " | ")))
end
