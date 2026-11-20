--!strict
-- V8-6.2 (sync check): run in Studio (command bar or the MCP's execute_luau, Edit). Every script in
-- ServerScriptService.Server.BuildStamp's manifest is looked up and checksummed the same way as
-- tools/stamp.pl (FNV-1a 32-bit, carriage returns left out). Returns "OK n scripts" or the list of
-- scripts that differ or are missing. RELEASE.md's gate refuses a publish with any.

local function fnv(text: string): number
	local h = 2166136261
	for i = 1, #text do
		local c = string.byte(text, i)
		if c ~= 13 then
			h = bit32.bxor(h, c)
			-- (h * 16777619 mod 2^32, without losing bits: 16777619 = 2^24 + 403.)
			h = (h * 403 + bit32.lshift(h, 24)) % 4294967296
		end
	end
	return h
end

local function find(path: string): Instance?
	local node: Instance? = game
	for name in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local stampScript = game:GetService("ServerScriptService"):FindFirstChild("Server")
stampScript = stampScript and stampScript:FindFirstChild("BuildStamp")
if not stampScript or not stampScript:IsA("ModuleScript") then
	return "no BuildStamp in Studio: run perl tools/stamp.pl and let it sync"
end
local stamp = (loadstring((stampScript :: any).Source) :: any)()
local bad = {}
local n = 0
for path, want in stamp.scripts do
	n += 1
	local s = find(path)
	if not s or not s:IsA("LuaSourceContainer") then
		table.insert(bad, "missing " .. path)
	else
		local got = fnv((s :: any).Source)
		if got ~= want then
			table.insert(bad, "differs " .. path)
		end
	end
end
table.sort(bad)
local result = if #bad == 0 then string.format("OK %d scripts match build %s (%s)", n, stamp.commit, stamp.made) else string.format("%d of %d scripts differ from build %s:\n%s", #bad, n, stamp.commit, table.concat(bad, "\n"))
print(result)
return result
