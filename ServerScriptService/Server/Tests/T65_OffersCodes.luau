--!strict
-- Phase 2: the monetisation ladder is data (Shop.OFFERS, ids 0 until the owner sends them) inside
-- the plan's price bands, with no paid random items and nothing that sells slow-mo or the replay;
-- like-milestone codes are only live when the owner sets them (never a like reward).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Shop) :: any
local Config = require(ReplicatedStorage.Shared.Config) :: any

return {
	name = "T65_OffersCodes",
	timeout = 2,
	run = function(): string?
		local keys = {}
		for _, o in Shop.OFFERS do
			assert(type(o.id) == "number" and o.id >= 0 and o.id % 1 == 0, o.key .. ": bad id")
			assert(o.robux >= 39 and o.robux <= 999, o.key .. ": price out of the plan's bands")
			local text = string.lower(o.name .. " " .. o.gives)
			assert(not string.find(text, "egg") and not string.find(text, "slow") and not string.find(text, "replay"), o.key .. " sells eggs, slow-mo or the replay")
			table.insert(keys, o.key)
		end
		assert(#Shop.OFFERS >= 6, "the ladder is short")
		for _, c in Config.LIKE_CODES do
			assert(type(c.likes) == "number" and c.bolts > 0, "a like code without a goal or bolts")
			assert(not c.live or c.code ~= "", "a live like code with no code")
		end
		return "offers: " .. table.concat(keys, ", ")
	end,
}
