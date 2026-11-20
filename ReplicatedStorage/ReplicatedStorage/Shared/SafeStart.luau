--!strict
-- V8-0.9 (safe boot): starts each system under pcall, so one error no longer stops the systems after
-- it (saving above all). Server Main and client Main each make one runner:
--   local safe = SafeStart.new(function(failedList) workspace:SetAttribute("BootFailed", failedList) end)
--   safe("Purchases", function() Purchases.start() end)
-- A failure is warned and reported as a comma list of names. A start that yields long is warned
-- too (it still holds the ones after it: pcall cannot help an endless wait), so the log says which.

local SafeStart = {}

SafeStart.SLOW_AFTER = 8 -- s a start may take before the log names it

export type Runner = (name: string, fn: () -> ()) -> boolean

function SafeStart.new(report: ((failedList: string) -> ())?, tag: string?): Runner
	local failed: { string } = {}
	local label = tag or "Boot"
	return function(name: string, fn: () -> ()): boolean
		local finished = false
		task.delay(SafeStart.SLOW_AFTER, function()
			if not finished then
				warn(string.format("[%s] %s is still starting after %d s", label, name, SafeStart.SLOW_AFTER))
			end
		end)
		local ok, err = pcall(fn)
		finished = true
		if not ok then
			warn(string.format("[%s] %s failed: %s", label, name, tostring(err)))
			table.insert(failed, name)
			if report then
				pcall(report, table.concat(failed, ","))
			end
		end
		return ok
	end
end

return SafeStart
