--!strict
-- Release 0.20.0: Shop.OFFERS sold and granted (OfferService, Shared\Offers).
--   every offer has a grant, and the pass mapping is right: All Melee / All Explosives cover their
--   shelf, 2x BOLTS sets DoubleBolts, VIP Lab VipLab, Events Pass EventsPass, Everything all of it
--   (every shelf); a product grant is never a pass effect
--   a product order is granted once per purchase id: the same id again is a repeat (no second
--   grant), a new id grants again (the real bolts and weapon calls are swapped for counters)
--   a granted pass turns into the attributes, and the server's unlock check honours PassToys
--   ownership from Roblox: a stubbed "owns" answer sets the attributes on join
-- The prompts themselves need ids and a real purchase (TEST-ALT.md, Creator Hub).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Shop = require(Shared.Shop) :: any
local Offers = require(Shared.Offers)
local Toys = require(Shared.Toys)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local OfferService = require(Systems:WaitForChild("OfferService")) :: any
local ProgressService = require(Systems:WaitForChild("ProgressService"))

local ATTRS = { "PassToys", "DoubleBolts", "VipLab", "EventsPass", "LabControls" }

return {
	name = "T68_Offers",
	timeout = 40,
	run = function(): string?
		local results = {}
		-- 1. The mapping.
		for _, offer in Shop.OFFERS do
			assert(Offers.GRANTS[offer.key], offer.key .. " has no grant")
			assert(offer.kind == "pass" or offer.kind == "product", offer.key .. ": unknown kind")
		end
		local melee = Offers.effectsOf({ AllMelee = true })
		assert(Offers.covers(melee.PassToys, "Melee") and not Offers.covers(melee.PassToys, "Guns"), "All Melee covers the wrong shelves")
		local bombs = Offers.effectsOf({ AllExplosives = true })
		assert(Offers.covers(bombs.PassToys, "Explosives") and not Offers.covers(bombs.PassToys, "Melee"), "All Explosives covers the wrong shelves")
		local both = Offers.effectsOf({ AllMelee = true, AllExplosives = true })
		assert(Offers.covers(both.PassToys, "Melee") and Offers.covers(both.PassToys, "Explosives"), "two shelf passes do not add up")
		assert(Offers.effectsOf({ DoubleBolts = true }).DoubleBolts == true, "2x BOLTS does not set DoubleBolts")
		assert(Offers.effectsOf({ VipLab = true }).VipLab == true, "VIP Lab does not set VipLab")
		assert(Offers.effectsOf({ EventsPass = true }).EventsPass == true, "Events Pass does not set EventsPass")
		local all = Offers.effectsOf({ Everything = true })
		assert(all.DoubleBolts and all.VipLab and all.EventsPass, "Everything misses a perk")
		for _, shelf in Toys.categories do
			assert(Offers.covers(all.PassToys, shelf), "Everything misses the " .. shelf .. " shelf")
		end
		local none = Offers.effectsOf({ EntryPack = true })
		assert(none.PassToys == nil and none.DoubleBolts == nil, "a product counted as a pass")
		table.insert(results, "pass mapping right (Everything = every shelf + 2x + VIP + events)")

		-- 2. A product grant, once per purchase id.
		local player = Players:GetPlayers()[1]
		assert(player, "no player in the play test")
		local started = os.clock()
		while not ProgressService.ecoOf(player) and os.clock() - started < 10 do
			task.wait(0.2)
		end
		local eco = ProgressService.ecoOf(player) :: any
		assert(eco, "the profile's economy is not there")
		local packBolts = Offers.GRANTS.EntryPack.bolts :: number
		local savedGot = table.clone(eco.got)
		local saved = { OfferService.giveBolts, OfferService.giveWeapon, OfferService.complete }
		local bolts, weapons, completed = 0, 0, 0
		OfferService.giveBolts = function(_p: Player, n: number): boolean
			bolts += n
			return true
		end
		OfferService.giveWeapon = function(): boolean
			weapons += 1
			return true
		end
		OfferService.complete = function()
			completed += 1
		end
		local ok, err = pcall(function()
			local id = "t68-" .. tostring(os.clock())
			assert(OfferService.deliver(player, "EntryPack", id) == "granted", "the first delivery was not granted")
			assert(bolts == packBolts and weapons == 1, string.format("granted %d bolts / %d weapons", bolts, weapons))
			assert(OfferService.deliver(player, "EntryPack", id) == "repeat", "the same purchase id was granted again")
			assert(bolts == packBolts and weapons == 1, "a repeat handed out more")
			assert(OfferService.deliver(player, "EntryPack", id .. "b") == "granted" and bolts == 2 * packBolts, "a second purchase was not granted")
			task.wait(0.1) -- (complete runs in its own thread)
			assert(completed == 3, "orders completed " .. completed .. " times, want 3 (repeats complete too)")
		end)
		OfferService.giveBolts, OfferService.giveWeapon, OfferService.complete = saved[1], saved[2], saved[3]
		eco.got = savedGot
		assert(ok, err)
		table.insert(results, "a product order granted once per purchase id")

		-- 3. Passes into attributes, and the unlock check.
		local before = {}
		for _, a in ATTRS do
			before[a] = player:GetAttribute(a)
		end
		local savedAsk = OfferService.askOwns
		local ok2, err2 = pcall(function()
			OfferService.grantPass(player, "AllMelee")
			assert(Offers.covers(player:GetAttribute("PassToys"), "Melee") and player:GetAttribute("Offer_AllMelee") == true, "All Melee did not reach the attributes")
			local locked: any = nil
			for _, toy in Toys.list do
				if toy.category == "Melee" and toy.unlockAt > 0 and (locked == nil or toy.unlockAt > locked.unlockAt) then
					locked = toy
				end
			end
			if locked then
				local unlockAll = player:GetAttribute("UnlockAll")
				player:SetAttribute("UnlockAll", nil)
				local open = ProgressService.isUnlocked(player, locked)
				player:SetAttribute("UnlockAll", unlockAll)
				assert(open, "a melee weapon is still locked with All Melee")
			end
			OfferService.grantPass(player, "Everything")
			assert(player:GetAttribute("PassToys") == "*" and player:GetAttribute("DoubleBolts") == true and player:GetAttribute("VipLab") == true and player:GetAttribute("EventsPass") == true, "Everything did not set every attribute")
			-- Roblox's answer on join (stubbed: owns only the 2x BOLTS pass, when it has an id).
			OfferService.askOwns = function(_userId: number, passId: number): boolean
				for _, o in Shop.OFFERS do
					if o.key == "DoubleBolts" then
						return o.id == passId
					end
				end
				return false
			end
			OfferService.resetForTest(player)
			OfferService.checkOwnershipForTest(player)
			local doubleId = 0
			for _, o in Shop.OFFERS do
				if o.key == "DoubleBolts" then
					doubleId = o.id
				end
			end
			if doubleId ~= 0 then
				assert(player:GetAttribute("DoubleBolts") == true and player:GetAttribute("PassToys") == nil, "the join check did not map the owned pass")
			else
				assert(player:GetAttribute("DoubleBolts") == nil, "a pass with id 0 was granted on join")
			end
		end)
		OfferService.askOwns = savedAsk
		OfferService.resetForTest(player)
		for _, a in ATTRS do
			player:SetAttribute(a, before[a])
		end
		assert(ok2, err2)
		table.insert(results, "passes reach the attributes and the unlock check")
		return table.concat(results, "; ")
	end,
}
