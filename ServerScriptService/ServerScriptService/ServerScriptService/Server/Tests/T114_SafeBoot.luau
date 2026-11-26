--!strict
-- V8-0.9 (safe boot): a system that errors while starting no longer stops the ones after it, the
-- failure is reported by name, and this Studio boot itself started every system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeStart = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SafeStart")) :: any

return {
	name = "T114_SafeBoot",
	timeout = 15,
	run = function(): string?
		local reported: string? = nil
		local safe = SafeStart.new(function(list: string)
			reported = list
		end, "T114")
		local order: { string } = {}
		local okFirst = safe("Fine", function()
			table.insert(order, "Fine")
		end)
		local okBroken = safe("Broken", function()
			table.insert(order, "Broken")
			error("a fake start error (T114)")
		end)
		local okLater = safe("Later", function()
			table.insert(order, "Later")
		end)
		assert(okFirst and okLater and not okBroken, "the runner's answers are wrong")
		assert(table.concat(order, ",") == "Fine,Broken,Later", "a later system did not start after the error: " .. table.concat(order, ","))
		assert(reported == "Broken", "the failure was not reported by name: " .. tostring(reported))
		-- This boot (Server Main): nothing failed, and the systems it guards are running.
		local failed = workspace:GetAttribute("BootFailed")
		assert(failed == nil, "this Studio boot had a failing system: " .. tostring(failed))
		return "an error in one start leaves the later ones starting; reported by name; this boot clean"
	end,
}
