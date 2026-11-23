--!strict
-- V8-0.9 (safe boot): starts each system under pcall, so one error no longer stops the systems after
-- it (saving above all). Server Main and client Main each make one runner:
--   local safe = SafeStart.new(function(failedList) workspace:SetAttribute("BootFailed", failedList) end)
--   safe("Purchases", function() Purchases.start() end)
-- A failure is warned and reported as a comma list of names. A start that yields long is warned
-- too (it still holds the ones after it: pcall cannot help an endless wait), so the log says which.

local SafeStart = {}

SafeStart.CLIENT_WAIT = 4 -- s
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
		local t0 = os.clock()
		local ok, err = true, nil :: any
		if game:GetService("RunService"):IsServer() then
			ok, err = pcall(fn)
		else
			-- (23 Nov 2026: a client start that waits for something holds the rest up 4 s at most, never for ever.)
			local done = false
			task.spawn(function()
				ok, err = pcall(fn)
				if done then
					finished = true
					if not ok then
						warn(string.format("[%s] %s failed late: %s", label, name, tostring(err)))
					end
				end
				done = true
			end)
			while not done and os.clock() - t0 < SafeStart.CLIENT_WAIT do
				task.wait()
			end
			if not done then
				done = true
				warn(string.format("[%s] %s is slow: the rest goes on without it", label, name))
				return true
			end
		end
		local took = os.clock() - t0
		if took > 0.1 then
			print(string.format("[%s] %s took %.2f s", label, name, took)) -- (what a join waits for)
		end
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
