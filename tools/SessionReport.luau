--!strict
-- Round 5, phase 00: reads the visit records (DataStore Session_v1, SessionStats) and prints one
-- table: PC vs phone vs tablet (and console), per build. Run it in Studio's command bar or with the
-- Roblox Studio MCP (execute_luau, Edit) with "Enable Studio Access to API Services" on.
-- Set VERSION to one build ("0.14.0") or nil for all; SINCE_HOURS to look back.

local VERSION: string? = nil
local SINCE_HOURS = 48
local MAX_KEYS = 4000

local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("Session_v1")
local since = os.time() - SINCE_HOURS * 3600

local rows: { any } = {}
local pages = store:ListKeysAsync()
local read = 0
while read < MAX_KEYS do
	for _, key in pages:GetCurrentPage() do
		local name = key.KeyName
		local joined = tonumber(string.match(name, "_(%d+)$"))
		if joined and joined >= since then
			local ok, r = pcall(store.GetAsync, store, name)
			if ok and type(r) == "table" and (VERSION == nil or r.v == VERSION) then
				table.insert(rows, r)
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

local groups: { [string]: { any } } = {}
for _, r in rows do
	local k = string.format("%s %s", tostring(r.v), tostring(r.plat))
	groups[k] = groups[k] or {}
	table.insert(groups[k], r)
end

local lines = { string.format("%d visits since %d h ago (%s)", #rows, SINCE_HOURS, VERSION or "all builds"),
	string.format("%-16s %5s %7s %6s %6s %6s %7s %7s %6s %6s %6s %5s", "build device", "n", "medLeft", "<1m", "<3m", ">=5m", "0 taked", "medShot", "hits", "knock", "eggOp", "lab") }
local keys = {}
for k in groups do
	table.insert(keys, k)
end
table.sort(keys)
for _, k in keys do
	local g = groups[k]
	local left, shot, hits, knocks = {}, {}, {}, {}
	local under1, under3, over5, zero, egg, lab = 0, 0, 0, 0, 0, 0
	for _, r in g do
		local l = tonumber(r.left) or 0
		table.insert(left, l)
		if r.firstShot then
			table.insert(shot, r.firstShot)
		end
		table.insert(hits, r.hits or 0)
		table.insert(knocks, r.knocks or 0)
		under1 += if l < 60 then 1 else 0
		under3 += if l < 180 then 1 else 0
		over5 += if l >= 300 then 1 else 0
		zero += if (r.takedowns or 0) == 0 then 1 else 0
		egg += if (r.eggOpened or 0) > 0 then 1 else 0
		lab += if r.lab then 1 else 0
	end
	local n = #g
	local function pct(x: number): string
		return string.format("%d%%", math.floor(x / n * 100 + 0.5))
	end
	table.insert(lines, string.format("%-16s %5d %6ds %6s %6s %6s %7s %6.1fs %6d %6d %6s %5s", k, n, median(left), pct(under1), pct(under3), pct(over5), pct(zero), median(shot), median(hits), median(knocks), pct(egg), pct(lab)))
end
local text = table.concat(lines, "\n")
print(text)
return text
