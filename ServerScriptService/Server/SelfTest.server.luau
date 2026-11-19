--!strict
-- Studio only: runs every ModuleScript in Server/Tests when ServerStorage has the attribute RunSelfTest = true.
-- SelfTestOnly = "T15" (a module name prefix, or several: "T15,T28") runs just the matching tests.
-- Each test module returns { name: string, timeout: number?, run: () -> string? }.
-- run() errors to fail; an optional returned string is printed as detail.
-- Output lines (read them from the console or LogService):
--   [SelfTest] PASS <name> <detail>
--   [SelfTest] FAIL <name> <error>
--   [SelfTest] DONE pass=<n> fail=<n>

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

	task.spawn(function()
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
		for prefix in string.gmatch(only :: string, "[^,%s]+") do
			if string.sub(child.Name, 1, #prefix) == prefix then
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

local passed, failed = 0, 0
for _, moduleScript in modules do
	local loaded, test = pcall(require, moduleScript)
	if not loaded or type(test) ~= "table" or type((test :: any).run) ~= "function" then
		failed += 1
		print("[SelfTest] FAIL", moduleScript.Name, "could not load:", tostring(test))
		continue
	end

	local t = test :: TestModule
	local ok, detail = runWithTimeout(t.run, t.timeout or DEFAULT_TIMEOUT)
	if ok then
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
print(string.format("[SelfTest] DONE pass=%d fail=%d", passed, failed))
if labLive ~= nil then
	ServerStorage:SetAttribute("LabLive", labLive)
end
