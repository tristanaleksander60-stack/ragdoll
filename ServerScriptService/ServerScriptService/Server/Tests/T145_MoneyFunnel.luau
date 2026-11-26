--!strict
-- V8-5.5 (the money funnel, measured): the visit record counts the shop opening, purchase prompts
-- (shown and done) and Robux spent; junk is ignored.

local Players = game:GetService("Players")

local SessionStats = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("SessionStats")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T145_MoneyFunnel",
	timeout = 20,
	run = function(): string?
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and SessionStats.recordFor(p) ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		local r = p and SessionStats.recordFor(p)
		if not p or not r then
			return "skipped (no visit record)"
		end
		local shop, shown, done, robux = r.shopOpen or 0, r.promptShown or 0, r.promptDone or 0, r.robux or 0
		SessionStats.onClient(p, "Shop", "open")
		SessionStats.onClient(p, "Shop", "prompt")
		SessionStats.onClient(p, "Shop", "bought")
		SessionStats.onClient(p, "Shop", "free money") -- (ignored)
		SessionStats.onClient(p, "Shop", 42) -- (ignored)
		SessionStats.count(p, "robux", 29)
		assert(r.shopOpen == shop + 1, "the shop opening was not counted")
		assert(r.promptShown == shown + 2 and r.promptDone == done + 1, "prompts not counted right")
		assert(r.robux == robux + 29, "Robux not counted")
		return "shop opening, prompts (shown 2, done 1) and 29 Robux counted; junk ignored"
	end,
}
