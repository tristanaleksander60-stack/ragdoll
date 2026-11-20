--!strict
-- V9-0i (owner, 21 Nov 2026: "fix all the icons in the shop so they match the right things"): every
-- thing the SHOP sells (Shop.PASSES, Shop.OFFERS, Events.list) has a card in Shared/ShopArt with its
-- own uploaded picture (DrawnIcons), never the old fallback egg or gift, and no two things share a
-- picture; each sits in a real tab, with 2-3 "what you get" lines.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopArt = require(Shared:WaitForChild("ShopArt")) :: any
local Shop = require(Shared:WaitForChild("Shop")) :: any
local Events = require(Shared:WaitForChild("Events")) :: any
local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any

return {
	name = "T164_ShopPictures",
	timeout = 10,
	run = function(): string?
		local items = ShopArt.items()
		local byKey, used = {}, {}
		for _, item in items do
			byKey[item.key] = item
			assert(DrawnIcons.ASSETS[item.picture], item.key .. " has no uploaded picture (" .. item.picture .. ")")
			assert(item.picture ~= "gift" and item.picture ~= "egg", item.key .. " still shows the fallback " .. item.picture)
			assert(not used[item.picture], item.key .. " shares its picture with " .. tostring(used[item.picture]))
			used[item.picture] = item.key
			assert(table.find(ShopArt.TABS, item.tab) and item.tab ~= "FEATURED", item.key .. " is in no tab")
			assert(#item.bullets >= 2 and #item.bullets <= 3, item.key .. " has " .. #item.bullets .. " lines of what you get")
		end
		local n = 0
		for _, pass in Shop.PASSES do
			assert(byKey[pass.key], "the pass " .. pass.key .. " has no card")
			n += 1
		end
		for _, o in Shop.OFFERS do
			assert(byKey[o.key], "the offer " .. o.key .. " has no card")
			n += 1
		end
		for _, e in Events.list do
			assert(byKey[e.id], "the event " .. e.id .. " has no card")
			n += 1
		end
		assert(byKey[ShopArt.HERO], "the hero " .. ShopArt.HERO .. " is not sold")
		for _, key in ShopArt.FEATURED do
			assert(byKey[key], "the featured " .. key .. " is not sold")
		end
		return string.format("%d sold things, each its own uploaded picture (no egg, no gift, none shared), in its tab, with what you get", n)
	end,
}
