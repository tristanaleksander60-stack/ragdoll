--!strict
-- Reads the visit records (DataStore Session_v1, SessionStats) READ-ONLY and prints the V8 report.
-- Run it in Studio (command bar or the MCP's execute_luau, Edit) with "Enable Studio Access to API
-- Services" on. Never writes.
--   Left out: the owner (record.owner, or the creator's userId) and play-as-newcomer visits (test).
--   Per build x device: n, the median minutes, the "gone by" curve (10 s .. 5 min, counted from the
--   client's first frame when the record has it), takedowns, the V8 funnel stage, fps p5, errors,
--   orientation after load (30 s), friends in the server, and the most used machines.
--   D1: for first visits in the window, the share of players who came back 24-48 h later.
-- Set VERSION to one build ("0.26.0") or nil for all; SINCE_HOURS to look back.

local VERSION: string? = nil
local SINCE_HOURS = 24 * 7
local MAX_KEYS = 6000

local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("Session_v1")
local since = os.time() - SINCE_HOURS * 3600
local creator = game.CreatorId

local rows: { any } = {}
local visitsByUser: { [number]: { number } } = {}
local pages = store:ListKeysAsync()
local read = 0
while read < MAX_KEYS do
	for _, key in pages:GetCurrentPage() do
		local user, joined = string.match(key.KeyName, "^(%d+)_(%d+)$")
		local uid, at = tonumber(user), tonumber(joined)
		if uid and at and at >= since and uid ~= creator then
			local ok, r = pcall(store.GetAsync, store, key.KeyName)
			if ok and type(r) == "table" and r.owner ~= true and r.test ~= true then
				r._uid = uid
				visitsByUser[uid] = visitsByUser[uid] or {}
				table.insert(visitsByUser[uid], at)
				if VERSION == nil or r.v == VERSION then
					table.insert(rows, r)
				end
			end
		end
		read += 1
	end
	if pages.IsFinished then
		break
	end
	pages:AdvanceToNextPageAsync()
end

local function median(list: { number }): number
	if #list == 0 then
		return 0
	end
	table.sort(list)
	return list[math.ceil(#list / 2)]
end
local function pct(n: number, of: number): string
	return if of == 0 then "-" else string.format("%d%%", math.floor(n / of * 100 + 0.5))
end
local function played(r: any): number
	return math.max(0, (r.left or 0) - (r.frame0 or 0))
end

local groups: { [string]: { any } } = {}
for _, r in rows do
	local k = string.format("%s %s", tostring(r.v), tostring(r.plat))
	groups[k] = groups[k] or {}
	table.insert(groups[k], r)
end
local keys = {}
for k in groups do
	table.insert(keys, k)
end
table.sort(keys)

local CURVE = { 10, 20, 30, 45, 60, 90, 120, 180, 300 }
local lines = { string.format("%d visits since %d h ago (%s); owner and test visits left out", #rows, SINCE_HOURS, VERSION or "all builds") }
local head = { "build device", "n", "med s", "TD" }
for _, t in CURVE do
	table.insert(head, "<" .. t)
end
for _, h in { "stg5+", "fpsP5", "errs", "up30", "friends" } do
	table.insert(head, h)
end
table.insert(lines, table.concat(head, "  "))
for _, k in keys do
	local list = groups[k]
	local secs, tds, fps = {}, {}, {}
	local stage5, errs, up, upN, friends = 0, 0, 0, 0, 0
	for _, r in list do
		table.insert(secs, played(r))
		table.insert(tds, r.takedowns or 0)
		if r.fpsP5 then
			table.insert(fps, r.fpsP5)
		end
		if (r.stage or 0) >= 5 then
			stage5 += 1
		end
		if (r.errs or 0) > 0 then
			errs += 1
		end
		if r.orient30 then
			upN += 1
			if r.orient30 == "p" then
				up += 1
			end
		end
		if (r.friendsMax or 0) > 0 then
			friends += 1
		end
	end
	local row = { k, tostring(#list), string.format("%.0f", median(table.clone(secs))), tostring(median(tds)) }
	for _, t in CURVE do
		local gone = 0
		for _, s in secs do
			if s < t then
				gone += 1
			end
		end
		table.insert(row, pct(gone, #list))
	end
	table.insert(row, pct(stage5, #list))
	table.insert(row, if #fps > 0 then string.format("%.0f", median(fps)) else "-")
	table.insert(row, pct(errs, #list))
	table.insert(row, if upN > 0 then pct(up, upN) else "-")
	table.insert(row, pct(friends, #list))
	table.insert(lines, table.concat(row, "  "))
end

-- D1: players whose first visit in the window is at least 48 h old; came back 24-48 h after it.
local cohort, back = 0, 0
for _, list in visitsByUser do
	table.sort(list)
	local first = list[1]
	if os.time() - first >= 48 * 3600 then
		cohort += 1
		for i = 2, #list do
			local gap = list[i] - first
			if gap >= 24 * 3600 and gap < 48 * 3600 then
				back += 1
				break
			end
		end
	end
end
table.insert(lines, string.format("D1 (came back 24-48 h after a first visit): %s of %d players", pct(back, cohort), cohort))

-- The most used machines, creatures, maps and events (share of visits that used each).
local used: { [string]: number } = {}
for _, r in rows do
	if type(r.used) == "table" then
		for name in r.used do
			used[name] = (used[name] or 0) + 1
		end
	end
end
local names = {}
for name in used do
	table.insert(names, name)
end
table.sort(names, function(a, b)
	return used[a] > used[b]
end)
local top = {}
for i = 1, math.min(15, #names) do
	table.insert(top, string.format("%s %s", names[i], pct(used[names[i]], #rows)))
end
table.insert(lines, "Used: " .. (if #top > 0 then table.concat(top, ", ") else "(no V8 records yet)"))

-- V8-5.5: the money funnel per device: shop opened, a prompt shown, bought, Robux.
local money: { [string]: { n: number, shop: number, prompt: number, bought: number, robux: number } } = {}
for _, r in rows do
	local k = tostring(r.plat)
	local m = money[k] or { n = 0, shop = 0, prompt = 0, bought = 0, robux = 0 }
	money[k] = m
	m.n += 1
	if (r.shopOpen or 0) > 0 then
		m.shop += 1
	end
	if (r.promptShown or 0) > 0 then
		m.prompt += 1
	end
	if (r.promptDone or 0) > 0 then
		m.bought += 1
	end
	m.robux += r.robux or 0
end
for k, m in money do
	table.insert(lines, string.format("Money %s: shop %s, prompt %s, bought %s, %d Robux", k, pct(m.shop, m.n), pct(m.prompt, m.n), pct(m.bought, m.n), m.robux))
end

-- What was on screen when they left.
local screens: { [string]: number } = {}
for _, r in rows do
	if r.screen then
		screens[r.screen] = (screens[r.screen] or 0) + 1
	end
end
local sc = {}
for name, n in screens do
	table.insert(sc, string.format("%s %s", name, pct(n, #rows)))
end
table.insert(lines, "On screen at leave: " .. (if #sc > 0 then table.concat(sc, ", ") else "-"))

local text = table.concat(lines, "\n")
print(text)
return text
