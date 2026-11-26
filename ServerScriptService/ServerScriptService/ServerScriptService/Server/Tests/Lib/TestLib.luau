--!strict
-- V8-0.9 (brought forward from V8-6.4): small helpers the self-tests share. Lives in the Folder
-- Tests/Lib, so the runner (which takes only ModuleScripts directly in Tests) never runs it as a test.
--   local Lib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib"))
--   Lib.waitFor(function() return x ~= nil end, 10)      -> true, or false after 10 s
--   Lib.withHold(ServerStorage, "StudioFresh", true, fn)  -> fn's results; the attribute put back,
--                                                           even when fn errors (the error goes on)

local TestLib = {}

-- Waits until check() is true (every `step` s, default 0.2); false after `seconds`.
function TestLib.waitFor(check: () -> boolean, seconds: number, step: number?): boolean
	local t0 = os.clock()
	while not check() do
		if os.clock() - t0 > seconds then
			return false
		end
		task.wait(step or 0.2)
	end
	return true
end

-- Sets an attribute for the length of fn and puts the old value back after, error or not.
function TestLib.withHold(target: Instance, attribute: string, value: any, fn: () -> ...any): ...any
	local was = target:GetAttribute(attribute)
	target:SetAttribute(attribute, value)
	local results = table.pack(pcall(fn))
	target:SetAttribute(attribute, was)
	if not results[1] then
		error(results[2], 0)
	end
	return table.unpack(results, 2, results.n)
end

return TestLib
