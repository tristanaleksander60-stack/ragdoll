--!strict
-- V7-5: the event banner card. Every event has its own picture for the card (DrawnIcons
-- event_<id>), a name short enough for one line, and a duration for the countdown line.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = require(Shared:WaitForChild("Events")) :: any
local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any

return {
	name = "T107_EventBanner",
	timeout = 10,
	run = function(): string?
		assert(Config.BANNER_V7 == true, "BANNER_V7 is off")
		assert(type(Config.BANNER_CHIP_AFTER) == "number" and Config.BANNER_CHIP_AFTER >= 2 and Config.BANNER_CHIP_AFTER <= 6, "the chip comes too soon or too late")
		local n = 0
		for id, event in Events.byId do
			n += 1
			local pic = DrawnIcons.ASSETS["event_" .. id]
			assert(type(pic) == "string" and pic:match("^rbxassetid://%d+$"), id .. " has no picture for the banner")
			assert(#event.name <= 18, id .. "'s name is too long for one line on the banner")
			assert(type(event.duration) == "number" and event.duration > 0, id .. " has no duration for the countdown")
		end
		assert(n > 0, "no events")
		return string.format("%d events, each with its picture, a one-line name and a countdown", n)
	end,
}
