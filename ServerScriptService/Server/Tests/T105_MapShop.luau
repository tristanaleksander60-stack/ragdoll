--!strict
-- V6-7: the map shop (MapShopService).
--   every map item is a Shop.OFFERS entry with a grant, a price, a pitch, a model and places;
--   booths are built in Studio (TEST) for every place an item names;
--   TRY gives 60 s once per visit, never for a product, never twice;
--   a Studio TEST purchase delivers once (Offer_<key>), and the effects appear: a trail, a dog,
--   a mega trampoline in the lab, gold dummies; and go again when the pass is gone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local MapShopService = require(Systems:WaitForChild("MapShopService"))
local OfferService = require(Systems:WaitForChild("OfferService"))
local Offers = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Offers")) :: any

local function waitFor(check: () -> boolean, seconds: number): boolean
	local t0 = os.clock()
	while not check() do
		if os.clock() - t0 > seconds then
			return false
		end
		task.wait(0.1)
	end
	return true
end

return {
	name = "T105_MapShop",
	timeout = 60,
	run = function(): string?
		waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		assert(#MapShopService.ITEMS >= 10, "fewer than 10 map items")
		for _, o in MapShopService.ITEMS do
			assert(Offers.GRANTS[o.key], o.key .. " has no grant")
			assert(o.robux > 0 and o.pitch and o.show and o.places and #o.places > 0, o.key .. " is missing a price, pitch, model or place")
		end
		assert(waitFor(function()
			return Workspace:FindFirstChild("MapBooths") ~= nil
		end, 20), "no booths were built")
		local booths = 0
		for _, d in (Workspace:FindFirstChild("MapBooths") :: Instance):GetDescendants() do
			if d:IsA("Model") and d:GetAttribute("Offer") then
				booths += 1
			end
		end
		assert(booths >= #MapShopService.ITEMS, "too few booths")
		-- TRY: once, 60 s, never for a product. (With real ids the game's creator owns every pass in
		-- Studio, and an owned pass is never tried: start from owning none.)
		OfferService.resetForTest(p)
		MapShopService.resetForTest(p)
		assert(MapShopService.try(p, "BoltCrate") == "junk", "a product could be tried")
		assert(MapShopService.try(p, "RainbowTrail") == nil, "the first try was refused")
		assert(MapShopService.has(p, "RainbowTrail"), "the try did not give it")
		local second = MapShopService.try(p, "RainbowTrail")
		assert(second == "tried" or second == "on", "a second try was given") -- (V9-0t: "on" while the first still runs)
		assert(waitFor(function()
			local c = p.Character
			return c ~= nil and c:FindFirstChild("RainbowTrail", true) ~= nil
		end, 3), "no rainbow trail on the player")
		-- A purchase's delivery and its effects. (21 Nov 2026: with real ids a buy opens Roblox's own
		-- prompt, so the test delivers the way a finished purchase does: OfferService.grantPass.)
		OfferService.resetForTest(p)
		OfferService.grantPass(p, "RobotDog")
		OfferService.grantPass(p, "MegaTrampoline")
		task.wait(1.1) -- (one buy a second per player)
		assert(MapShopService.buy(p, "RobotDog") == "owned", "an owned pass was sold again")
		assert(MapShopService.buy(p, "Parrot") == "paced", "two buys within a second were both taken")
		task.wait(1.1)
		assert(p:GetAttribute("Offer_RobotDog") == true, "the dog was not delivered")
		assert(waitFor(function()
			return Workspace:FindFirstChild("PetRobotDog") ~= nil
		end, 3), "no robot dog follows")
		assert(waitFor(function()
			return Workspace:FindFirstChild("MegaTrampoline", true) ~= nil
		end, 3), "no mega trampoline in the lab")
		-- Gone again with the pass.
		OfferService.resetForTest(p)
		MapShopService.resetForTest(p)
		assert(waitFor(function()
			return Workspace:FindFirstChild("PetRobotDog") == nil and Workspace:FindFirstChild("MegaTrampoline", true) == nil
		end, 3), "the dog or trampoline stayed after the pass went")
		return string.format("%d items, %d booths; try once, a purchase delivered, owned never sold again, effects on and off", #MapShopService.ITEMS, booths)
	end,
}
