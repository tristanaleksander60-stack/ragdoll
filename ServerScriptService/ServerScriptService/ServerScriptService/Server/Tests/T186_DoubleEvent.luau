--!strict
-- V9-NOW 12 (owner, 21 Nov 2026: "a 2x event for 48 hours"): inside Config.DOUBLE_EVENT a KO counts 2 and bolts
-- double (and stack with the 2x BOLTS pass: 4x); bought or code bolts never double; outside the window nothing
-- doubles; the chip's text shows the time left. (The window table is shallow inside the frozen Config: the test
-- moves it and puts it back.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local DoubleEvent = require(Shared:WaitForChild("DoubleEvent"))
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T186_DoubleEvent",
	timeout = 30,
	run = function(): string?
		local cfg = Config.DOUBLE_EVENT
		assert(type(cfg) == "table" and cfg.to - cfg.from == 48 * 3600, "DOUBLE_EVENT is not a 48-hour window")
		local t0 = 1000000
		local w = { from = t0, to = t0 + 48 * 3600 }
		assert(DoubleEvent.mult(w, t0 - 1) == 1 and DoubleEvent.mult(w, t0) == 2 and DoubleEvent.mult(w, w.to - 1) == 2 and DoubleEvent.mult(w, w.to) == 1, "the window edges are wrong")
		assert(DoubleEvent.left(w, t0 + 3600) == 47 * 3600, "time left is wrong")
		assert(DoubleEvent.label(47 * 3600 + 12 * 60 + 5) == "2X \u{00B7} 47:12:05", "the chip text is " .. DoubleEvent.label(47 * 3600 + 12 * 60 + 5))
		assert(DoubleEvent.mult(nil, t0) == 1 and DoubleEvent.mult({ from = 5, to = 1 }, 3) == 1, "a broken window doubles")
		local results = { "pure window, time left and chip text right" }
		-- Live: bolts through EconomyService.give, in and out of the window.
		local p = Players:GetPlayers()[1]
		if not p then
			return table.concat(results, "; ") .. "; skipped live (no player)"
		end
		local ProgressService = require(Systems:WaitForChild("ProgressService")) :: any
		local EconomyService = require(Systems:WaitForChild("EconomyService")) :: any
		local e = ProgressService.ecoOf(p)
		if not e then
			return table.concat(results, "; ") .. "; skipped live (no eco)"
		end
		local from, to = cfg.from, cfg.to
		local passWas = p:GetAttribute("DoubleBolts")
		local ok, err = pcall(function()
			local now = os.time()
			cfg.from, cfg.to = now - 60, now + 3600
			p:SetAttribute("DoubleBolts", nil)
			local b0 = e.bolts
			EconomyService.give(p, 10)
			assert(e.bolts - b0 == 20, "in the event 10 bolts gave " .. (e.bolts - b0))
			b0 = e.bolts
			EconomyService.give(p, 10, nil, true)
			assert(e.bolts - b0 == 10, "bought bolts doubled")
			p:SetAttribute("DoubleBolts", true)
			b0 = e.bolts
			EconomyService.give(p, 10)
			assert(e.bolts - b0 == 40, "event + pass gave " .. (e.bolts - b0) .. " (want 40)")
			p:SetAttribute("DoubleBolts", nil)
			cfg.from, cfg.to = now - 7200, now - 3600
			b0 = e.bolts
			EconomyService.give(p, 10)
			assert(e.bolts - b0 == 10, "after the event 10 bolts gave " .. (e.bolts - b0))
			table.insert(results, "bolts 2x in the event, 4x with the pass, 1x bought, 1x after")
		end)
		cfg.from, cfg.to = from, to
		p:SetAttribute("DoubleBolts", passWas)
		assert(ok, err)
		return table.concat(results, "; ")
	end,
}
