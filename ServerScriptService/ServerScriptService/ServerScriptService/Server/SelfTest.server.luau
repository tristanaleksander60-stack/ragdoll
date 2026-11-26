--!strict
-- Studio only: runs every ModuleScript in Server/Tests when ServerStorage has the attribute RunSelfTest = true.
-- SelfTestOnly = "T15" (a test number, or several: "T15,T28"; V8-0.9: exact, so "T4" no longer runs T40-T49;
-- a full module name works too) runs just the matching tests.
-- Each test module returns { name: string, timeout: number?, run: () -> string? }.
-- run() errors to fail; an optional returned string is printed as detail.
-- Output lines (read them from the console or LogService):
--   [SelfTest] PASS <name> <detail>
--   [SelfTest] FAIL <name> <error>
--   [SelfTest] SKIP <name> <detail>   (V8-0.9: a test whose detail starts with "skipped")
--   [SelfTest] DONE pass=<n> fail=<n> skip=<n>

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Never in a live server, whatever the attribute says: the tests spawn dummies and run events.
if not RunService:IsStudio() or ServerStorage:GetAttribute("RunSelfTest") ~= true then
	return
end

type TestModule = {
	name: string,
	timeout: number?,
	run: () -> string?,
}

local DEFAULT_TIMEOUT = 10

local function runWithTimeout(fn: () -> string?, timeout: number): (boolean, string?)
	local done = false
	local ok = false
	local result: string? = nil

	local thread = task.spawn(function()
		local success, value = pcall(fn)
		ok = success
		result = if value ~= nil then tostring(value) else nil
		done = true
	end)

	local started = os.clock()
	while not done and os.clock() - started < timeout do
		task.wait(0.1)
	end

	if not done then
		-- (V8-0.9: a timed-out test stops here instead of running on into the next test.)
		pcall(task.cancel, thread)
		return false, string.format("timeout after %ds", timeout)
	end
	return ok, result
end

-- LabLive (watching the lab's dummies live by hand after a run) makes their social life and their
-- vitals run during the tests too, which then fail at random: it is off while the tests run and
-- back as it was after.
local labLive = ServerStorage:GetAttribute("LabLive")
if labLive ~= nil then
	warn("[SelfTest] LabLive was on: off for the run, back after it")
	ServerStorage:SetAttribute("LabLive", nil)
end

-- The weapon ladder (round 2, N4) locks most tools behind takedowns. The tests use any tool, so
-- every player has UnlockAll (Studio only: ProgressService.isUnlocked) while they run; the tests of
-- the locks themselves turn it off for their player and back on after.
local Players = game:GetService("Players")
local function unlockAll(player: Player)
	player:SetAttribute("UnlockAll", true)
end
for _, player in Players:GetPlayers() do
	unlockAll(player)
end
local unlockJoin = Players.PlayerAdded:Connect(unlockAll)

local testsFolder = script.Parent:WaitForChild("Tests")
local modules = {}
for _, child in testsFolder:GetChildren() do
	local only = ServerStorage:GetAttribute("SelfTestOnly")
	-- (Several groups at once: "T28,T31".)
	local wanted = type(only) ~= "string" or only == ""
	if not wanted then
		-- (V8-0.9: exact: "T4" is T4_..., not T40-T49.)
		for prefix in string.gmatch(only :: string, "[^,%s]+") do
			if child.Name == prefix or string.sub(child.Name, 1, #prefix + 1) == prefix .. "_" then
				wanted = true
			end
		end
	end
	if child:IsA("ModuleScript") and wanted then
		table.insert(modules, child)
	end
end
table.sort(modules, function(a, b)
	return a.Name < b.Name
end)

local passed, failed, skipped = 0, 0, 0
for _, moduleScript in modules do
	local loaded, test = pcall(require, moduleScript)
	if not loaded or type(test) ~= "table" or type((test :: any).run) ~= "function" then
		failed += 1
		print("[SelfTest] FAIL", moduleScript.Name, "could not load:", tostring(test))
		continue
	end

	local t = test :: TestModule
	local ok, detail = runWithTimeout(t.run, t.timeout or DEFAULT_TIMEOUT)
	if ok and detail and string.lower(string.sub(detail, 1, 7)) == "skipped" then
		skipped += 1
		print("[SelfTest] SKIP", t.name, detail)
	elseif ok then
		passed += 1
		print("[SelfTest] PASS", t.name, detail or "")
	else
		failed += 1
		print("[SelfTest] FAIL", t.name, detail or "")
	end
end

unlockJoin:Disconnect()
for _, player in Players:GetPlayers() do
	player:SetAttribute("UnlockAll", nil)
end
print(string.format("[SelfTest] DONE pass=%d fail=%d skip=%d", passed, failed, skipped))
if labLive ~= nil then
	ServerStorage:SetAttribute("LabLive", labLive)
end
