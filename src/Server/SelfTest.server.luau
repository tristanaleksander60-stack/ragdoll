--!strict
-- Runs every ModuleScript in Server/Tests when ServerStorage has the attribute RunSelfTest = true.
-- Each test module returns { name: string, timeout: number?, run: () -> string? }.
-- run() errors to fail; an optional returned string is printed as detail.
-- Output lines (read them from the console or LogService):
--   [SelfTest] PASS <name> <detail>
--   [SelfTest] FAIL <name> <error>
--   [SelfTest] DONE pass=<n> fail=<n>

local ServerStorage = game:GetService("ServerStorage")

if ServerStorage:GetAttribute("RunSelfTest") ~= true then
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

local testsFolder = script.Parent:WaitForChild("Tests")
local modules = {}
for _, child in testsFolder:GetChildren() do
	if child:IsA("ModuleScript") then
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

print(string.format("[SelfTest] DONE pass=%d fail=%d", passed, failed))
