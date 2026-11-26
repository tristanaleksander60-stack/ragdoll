--!strict
-- Phase 0 (19 Nov 2026): no dead "SOON" cards. A product, pass or group whose id is still 0 is
-- hidden on a live server (HudPlus TODAY'S DEAL, RewardsUI GROUP GIFT, EventShop pass and event
-- cards; Studio still shows them as TEST). This lists what is hidden now, so the owner sees which
-- ids are missing, and checks every id is a whole number >= 0 (the card logic keys on 0).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Shop) :: any
local Events = require(ReplicatedStorage.Shared.Events) :: any

local function ok(id: unknown): boolean
	return type(id) == "number" and id >= 0 and id % 1 == 0
end

return {
	name = "T59_NoSoonCards",
	timeout = 2,
	run = function(): string?
		local hidden = {}
		assert(ok(Shop.STARTER_PACK) and ok(Shop.GROUP_ID), "Shop.STARTER_PACK / GROUP_ID must be whole numbers")
		if Shop.STARTER_PACK == 0 then
			table.insert(hidden, "TODAY'S DEAL (Shop.STARTER_PACK)")
		end
		if Shop.GROUP_ID == 0 then
			table.insert(hidden, "GROUP GIFT (Shop.GROUP_ID)")
		end
		for _, pass in Shop.PASSES do
			assert(ok(pass.id), "pass " .. pass.key .. " has a bad id")
			if pass.id == 0 then
				table.insert(hidden, "pass " .. pass.key)
			end
		end
		for _, event in Events.list do
			assert(ok(event.productId), "event " .. event.id .. " has a bad product id")
			if event.productId == 0 then
				table.insert(hidden, "event " .. event.id)
			end
		end
		return "hidden live until the owner sends ids: " .. (if #hidden > 0 then table.concat(hidden, ", ") else "none")
	end,
}
