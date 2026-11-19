--!strict
-- Weapons and the ladder (round 2, N4), through the server's own code:
--   the ladder: a new player has the G17, punch, shove, bat and crowbar (and the grab hand), the
--     next weapon is never far, and past each rung there is always one more until the last; four
--     shelves, every weapon on one; every locked weapon has a Robux price, dearer higher up
--   eggs: one holds a weapon the player does not have (one of the next few, or now and then any),
--     owned for good (it shows in the Owned attribute and the tool can be used); with every weapon
--     owned an egg holds a hat
--   buying: the weapon chosen before the prompt is delivered by the order (Purchases' real receipt
--     handler), saved, then the order completed; a repeated receipt gives nothing twice; an order
--     whose weapon is owned meanwhile gives the next locked one; with all owned, two eggs; asking
--     to buy a weapon you have is refused
--   an old profile keeps what it had (grandfathered once): the old open tools and the old kill
--     unlocks it had reached, nothing new; also when a save meets it without a read
--   the shotgun cuts limbs off only up close (severRange); blades always can (sever); every new
--     weapon has a model in the hand, the guns a muzzle (Tip)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local WeaponShop = require(Systems:WaitForChild("WeaponShop"))
local Purchases = require(Systems:WaitForChild("Purchases"))
local HitService = require(Systems:WaitForChild("HitService"))
local HeldService = require(Systems:WaitForChild("HeldService"))
local Toys = require(ReplicatedStorage.Shared.Toys)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Progress = require(ReplicatedStorage.Shared.Progress)

local TEST_PRODUCT = 999000099
local TEST_TIER = "Weapon99"

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.05)
	end
	return check()
end

local function ownedAttr(player: Player): { [string]: boolean }
	local set = {}
	for id in string.gmatch(tostring(player:GetAttribute("Owned") or ""), "[^,]+") do
		set[id] = true
	end
	return set
end

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function ladder(results: { string })
	-- 1. Who starts with what.
	local open = {}
	for _, toy in Toys.list do
		if toy.unlockAt <= 0 then
			table.insert(open, toy.id)
		end
	end
	table.sort(open)
	local want = table.clone(Toys.defaultLoadout)
	table.sort(want)
	assert(table.concat(open, ",") == table.concat(want, ","), "open from the start: " .. table.concat(open, ", "))
	local weapons = {}
	for _, id in open do
		if Toys.byId[id].kind == "hit" then
			table.insert(weapons, Toys.byId[id].label)
		end
	end
	-- (Round 5: the G17 and Punch, and Grab; Bat, Crowbar and Shove at 2, 4 and 6 takedowns.)
	assert(#weapons == 2, string.format("a new player has %d weapons (want 2)", #weapons))
	assert(Toys.SLOTS == 3 and #Toys.defaultLoadout == 3, "the bar is not 3 slots, full at the start")
	assert(Toys.byId.Bat.unlockAt == 2 and Toys.byId.Crowbar.unlockAt == 4 and Toys.byId.Shove.unlockAt == 6, "Bat, Crowbar, Shove are not at 2, 4, 6")
	-- Players from before keep them (grandfather from ladder 2).
	local old: any = { owned = {}, oldEggs = 0, eggs = 0, ladder = 2 }
	ProgressService.grandfather(old, 0, 0, 2)
	assert(old.owned.Bat and old.owned.Crowbar and old.owned.Shove and old.owned.Kick == nil, "a ladder-2 profile did not keep exactly Bat, Crowbar and Shove")
	assert(Toys.byId.Blaster.label == "G17", "the Blaster is not the G17")

	-- 2. The ladder: the first rung soon, no long empty stretch, the last one far up.
	local rungs = {}
	for _, toy in Toys.list do
		if toy.unlockAt > 0 then
			table.insert(rungs, toy.unlockAt)
		end
	end
	table.sort(rungs)
	assert(rungs[1] <= 5, "the first weapon to earn is at " .. rungs[1])
	local worst = 0
	for i = 2, #rungs do
		local gap = rungs[i] - rungs[i - 1]
		-- (Never more than a fifth of the way so far, and never more than 150 at once.)
		assert(gap <= math.max(10, rungs[i - 1] * 0.2) and gap <= 150, string.format("a gap of %d after %d", gap, rungs[i - 1]))
		worst = math.max(worst, gap)
	end
	local top = rungs[#rungs]
	for t = 0, top - 1, 7 do
		local next = false
		for _, at in rungs do
			if at > t then
				next = true
				break
			end
		end
		assert(next, "nothing to go for at " .. t)
	end

	-- 3. Shelves and prices.
	local shelves: { [string]: number } = {}
	for _, c in Toys.categories do
		shelves[c] = 0
	end
	assert(#Toys.categories == 4 and Toys.categories[1] == "Melee" and Toys.categories[2] == "Guns" and Toys.categories[3] == "Explosives" and Toys.categories[4] == "Specials", "the shelves are not Melee, Guns, Explosives, Specials")
	local lastPrice = 0
	local byLadder = table.clone(Toys.list)
	table.sort(byLadder, function(a, b)
		return a.unlockAt < b.unlockAt
	end)
	for _, toy in byLadder do
		assert(shelves[toy.category] ~= nil, toy.id .. " is on no shelf")
		shelves[toy.category] += 1
		local tier = Toys.priceTier(toy)
		if toy.unlockAt > 0 then
			assert(tier and tier.robux > 0 and Shop.WEAPON_PRODUCTS[tier.key] ~= nil, toy.id .. " has no price")
			assert(tier.robux >= lastPrice, toy.id .. " is cheaper than a weapon below it")
			lastPrice = tier.robux
		else
			assert(tier == nil, toy.id .. " is free but has a price")
		end
	end
	for c, n in shelves do
		assert(n >= 4, c .. " has only " .. n .. " weapons")
	end
	table.insert(results, string.format("a new player has 2 weapons (%s) and the grab hand, ladder-2 profiles keep Bat/Crowbar/Shove; %d to earn from %d to %d takedowns, the widest gap %d; shelves %d/%d/%d/%d; prices %d-%d R$",
		table.concat(weapons, ", "), #rungs, rungs[1], top, worst, shelves.Melee, shelves.Guns, shelves.Explosives, shelves.Specials,
		Toys.priceTiers[1].robux, Toys.priceTiers[#Toys.priceTiers].robux))
end

local function eggs(results: { string }, player: Player, profile: any)
	-- A fresh start: no takedowns, no weapons.
	profile.takedowns = 0
	ProgressService.setOwnedForTest(player, {})
	player:SetAttribute("UnlockAll", nil)
	local locked = ProgressService.lockedOf(player)
	assert(#locked == #Toys.list - #Toys.defaultLoadout, string.format("%d weapons locked at the start", #locked))
	assert(not ProgressService.isUnlocked(player, Toys.byId.Katana), "the Katana is open without takedowns")

	-- The next one up (a low roll, no lucky jump).
	profile.eggs = 3
	local a = ProgressService.openEgg(player, { pick = 0, any = 1 }) :: any
	assert(a and a.kind == "Weapon" and a.id == locked[1].id, "a low roll gave " .. tostring(a and a.id))
	assert(profile.owned[a.id] and ownedAttr(player)[a.id], a.id .. " is not owned (or not shown)")
	assert(ProgressService.isUnlocked(player, Toys.byId[a.id]), a.id .. " from the egg cannot be used")
	-- The highest of the next few.
	local b = ProgressService.openEgg(player, { pick = 0.999, any = 1 }) :: any
	local near = ProgressService.EGG_NEAR
	assert(b and b.kind == "Weapon" and b.id == locked[near + 1].id, string.format("a high roll gave %s (want the %d. locked, %s)", tostring(b and b.id), near, locked[near + 1].id))
	-- A lucky jump: any locked weapon, up to the very last.
	local c = ProgressService.openEgg(player, { pick = 0.999, any = 0 }) :: any
	assert(c and c.kind == "Weapon" and c.id == locked[#locked].id, "a lucky jump gave " .. tostring(c and c.id))
	assert(profile.eggs == 0, "eggs were not used up")
	-- Never one you have.
	local repeats = 0
	profile.eggs = 12
	for _ = 1, 12 do
		local before = count(profile.owned)
		local prize = ProgressService.openEgg(player) :: any
		assert(prize and prize.kind == "Weapon", "an egg held no weapon with weapons still locked")
		if count(profile.owned) ~= before + 1 then
			repeats += 1
		end
	end
	assert(repeats == 0, repeats .. " eggs gave a weapon already owned")
	-- Eggs saved up before the ladder (oldEggs) still hold hats, opened first.
	profile.eggs = 3
	profile.oldEggs = 2
	local h1 = ProgressService.openEgg(player) :: any
	local h2 = ProgressService.openEgg(player) :: any
	local w3 = ProgressService.openEgg(player) :: any
	assert(h1 and h1.kind == "Hat" and h2 and h2.kind == "Hat" and w3 and w3.kind == "Weapon" and profile.oldEggs == 0, "old eggs did not hold hats first")
	-- Not while the stored profile could not be read (it may own that weapon already).
	profile.eggs = 1
	ProgressService.setReadFailedForTest(player, true)
	local blocked = ProgressService.openEgg(player)
	ProgressService.setReadFailedForTest(player, false)
	assert(blocked == nil and profile.eggs == 1, "an egg opened before the profile was read")
	profile.eggs = 0
	-- All owned: a hat.
	for _, toy in Toys.list do
		if toy.unlockAt > 0 then
			profile.owned[toy.id] = true
		end
	end
	assert(#ProgressService.lockedOf(player) == 0, "weapons still locked with all owned")
	profile.eggs = 1
	local hat = ProgressService.openEgg(player) :: any
	assert(hat and hat.kind == "Hat" and Progress.hatById[hat.hat.id], "with every weapon owned the egg held no hat")
	table.insert(results, string.format("eggs: %s (next up), %s (%d. up), %s (lucky jump), 12 more never a repeat, 2 old eggs held hats first, none open before the read; then a hat (%s)", a.name, b.name, near + 1, c.name, hat.hat.name))
end

local function buying(results: { string }, player: Player, profile: any)
	local Granted = Enum.ProductPurchaseDecision.PurchaseGranted
	profile.takedowns = 0
	ProgressService.setOwnedForTest(player, {})
	player:SetAttribute("UnlockAll", nil)
	local wasMemory = Purchases.setMemoryStore(true)
	Purchases.unregister(TEST_TIER)
	Purchases.register(TEST_TIER, TEST_PRODUCT, WeaponShop.handlerFor(TEST_TIER), WeaponShop.describerFor(TEST_TIER))
	local ok, err = pcall(function()
		local function owedOrder(purchaseId: string): any
			local doc = Purchases.peek(player.UserId)
			for _, order in if doc then doc.owed else {} do
				if order.p == purchaseId then
					return order
				end
			end
			return nil
		end
		local function owed(purchaseId: string): boolean
			return owedOrder(purchaseId) ~= nil
		end
		-- The weapon chosen (the BUY button), then Roblox's receipt for its tier.
		local chicken = Toys.byId.Chicken
		assert(Toys.priceTier(chicken).key == TEST_TIER, "the Chicken Spell is not in the 99 tier")
		assert(ProgressService.choosePending(player, TEST_TIER, "Chicken"), "the choice was refused")
		assert(not ProgressService.choosePending(player, TEST_TIER, "Poke"), "a weapon of another tier was taken for this one")
		local id1 = "t35-" .. game:GetService("HttpService"):GenerateGUID(false)
		local receipt = { PurchaseId = id1, PlayerId = player.UserId, ProductId = TEST_PRODUCT, CurrencySpent = 99 }
		assert(Purchases.processReceipt(receipt) == Granted, "the receipt was not granted")
		local order = owedOrder(id1)
		assert(order == nil or order.d == "Chicken", "the order does not name the weapon chosen: " .. tostring(order and order.d))
		assert(profile.owned.Chicken and ownedAttr(player).Chicken, "the bought Chicken Spell is not owned")
		assert(ProgressService.isUnlocked(player, chicken), "the bought weapon cannot be used")
		assert(waitFor(function()
			return not owed(id1)
		end, 8), "the order was never completed after the save")
		-- The same receipt again (Roblox repeats them): nothing more.
		local before = count(profile.owned)
		assert(Purchases.processReceipt(receipt) == Granted, "the repeated receipt was not acknowledged")
		assert(count(profile.owned) == before, "a repeated receipt gave another weapon")
		local again = WeaponShop.deliver(player, TEST_TIER, id1, false, true)
		assert(again == "done" and count(profile.owned) == before, "a delivered purchase id was delivered again: " .. again)
		-- (Below: delivered straight, as Studio's BUY does: no order behind them to complete.)
		-- A second BUY of the same tier while a purchase is on its way: the order keeps its own
		-- weapon (its note), and the newer choice stays for the next purchase.
		assert(ProgressService.choosePending(player, TEST_TIER, "Fan"))
		assert(WeaponShop.describerFor(TEST_TIER)(player) == "Fan", "the receipt would not write the choice down")
		local raced, racedId = WeaponShop.deliver(player, TEST_TIER, "t35-r-" .. id1, false, true, "Slime")
		assert(raced == "weapon" and racedId == "Slime" and profile.pending[TEST_TIER] == "Fan", string.format("a raced order gave %s, pending %s", tostring(racedId), tostring(profile.pending[TEST_TIER])))
		local cheap = WeaponShop.deliver(player, TEST_TIER, "t35-x-" .. id1, false, true, "Poke")
		assert(cheap == "weapon" and not profile.owned.Poke, "a note naming a cheaper weapon was trusted")
		-- An order whose weapon is the player's meanwhile (an egg): the lowest locked one at that
		-- price or dearer instead (never a cheaper one).
		assert(ProgressService.choosePending(player, TEST_TIER, "Fan"))
		profile.owned.Fan = true
		local lowest
		for _, t in ProgressService.lockedOf(player) do
			if Toys.priceTier(t).robux >= 99 then
				lowest = t
				break
			end
		end
		local result, given = WeaponShop.deliver(player, TEST_TIER, "t35-b-" .. id1, false, true)
		assert(result == "weapon" and given == lowest.id and profile.owned[lowest.id], string.format("an owned choice gave %s (want %s)", tostring(given), lowest.id))
		-- Only dearer ones left of the 99s and below: the cheapest of the dearer ones; only cheaper
		-- ones left: the dearest of those.
		for _, toy in Toys.list do
			local tier = Toys.priceTier(toy)
			if tier and tier.robux <= 99 then
				profile.owned[toy.id] = true
			end
		end
		local _, up = WeaponShop.deliver(player, TEST_TIER, "t35-u-" .. id1, false, true)
		assert(up and Toys.priceTier(Toys.byId[up]).robux > 99, "with the tier sold out a purchase gave " .. tostring(up))
		ProgressService.setOwnedForTest(player, {})
		for _, toy in Toys.list do
			local tier = Toys.priceTier(toy)
			if tier and tier.robux >= 99 then
				profile.owned[toy.id] = true
			end
		end
		local _, down = WeaponShop.deliver(player, TEST_TIER, "t35-d-" .. id1, false, true)
		assert(down and Toys.priceTier(Toys.byId[down]).robux == 49, "with nothing at 99 or more left a purchase gave " .. tostring(down))
		-- Every weapon owned: two eggs.
		for _, toy in Toys.list do
			if toy.unlockAt > 0 then
				profile.owned[toy.id] = true
			end
		end
		local eggsBefore = profile.eggs
		local r3 = WeaponShop.deliver(player, TEST_TIER, "t35-c-" .. id1, false, true)
		assert(r3 == "eggs" and profile.eggs == math.min(Progress.MAX_EGGS, eggsBefore + 2), "with all owned a purchase gave " .. r3)
		-- A weapon nearly earned is never sold.
		ProgressService.setOwnedForTest(player, {})
		profile.pending = {}
		profile.takedowns = 0
		WeaponShop.resetForTest(player)
		WeaponShop.onRequest(player, "Buy", "Poke")
		assert(next(profile.pending) == nil and not profile.owned.Poke, "Poke, 3 takedowns away, was put up for buying")
		assert(not Toys.canBuy(Toys.byId.Pan, 43) and Toys.canBuy(Toys.byId.Pan, 35), "the buy line for the Pan is wrong")
		-- Asking to buy one you have: refused before any prompt (no new choice kept).
		ProgressService.setOwnedForTest(player, { Katana = true })
		profile.pending = {}
		WeaponShop.resetForTest(player)
		WeaponShop.onRequest(player, "Buy", "Katana")
		assert(next(profile.pending) == nil, "a weapon already owned was put up for buying")
		-- BUY on a weapon for sale: the choice is kept for whichever server delivers the order, and
		-- nothing is given before Roblox says it was paid (the product is on sale: the prompt opens).
		WeaponShop.resetForTest(player)
		local axeTier = (Toys.priceTier(Toys.byId.Axe) :: any).key
		WeaponShop.onRequest(player, "Buy", "Axe")
		if (Shop.WEAPON_PRODUCTS[axeTier] or 0) ~= 0 then
			assert(profile.pending[axeTier] == "Axe" and not profile.owned.Axe, "BUY on the Axe did not keep the choice (or gave it unpaid)")
		else
			assert(profile.owned.Axe and ownedAttr(player).Axe, "Studio's BUY did not give the Axe")
		end
		WeaponShop.resetForTest(player)
		WeaponShop.onRequest(player, "Buy", "NotAWeapon")
		WeaponShop.onRequest(player, "Buy", 42)
	end)
	Purchases.unregister(TEST_TIER)
	Purchases.register(TEST_TIER, Shop.WEAPON_PRODUCTS[TEST_TIER] or 0, WeaponShop.handlerFor(TEST_TIER), WeaponShop.describerFor(TEST_TIER))
	Purchases.setMemoryStore(wasMemory)
	if not ok then
		error(err, 0)
	end
	table.insert(results, "buying: the chosen Chicken Spell written into the order, delivered, saved, order completed; a repeated receipt gave nothing; a second BUY meanwhile never changes the weapon paid for; a cheaper note not trusted; an owned choice gave the lowest locked at that price or dearer (sold out: dearer; nothing dearer: the dearest cheaper one); all owned gave 2 eggs; nearly-earned and owned ones refused; Studio BUY gives it")
end

local function oldProfiles(results: { string })
	-- An old profile (no ladder) with 60 takedowns: every old open tool, the old unlocks to 60.
	local stored = ProgressService.clean({ takedowns = 60, eggs = 12 })
	local joined = ProgressService.joinedProfile(stored, nil)
	assert(joined.oldEggs == 12, "an old profile's 12 saved eggs are not old eggs: " .. tostring(joined.oldEggs))
	for _, id in { "TNT", "Rocket", "Freeze", "BigBoom", "Crossbow", "NailGun", "Slime", "Shrink" } do
		assert(joined.owned[id], "an old profile lost " .. id)
	end
	for _, id in { "Chicken", "Float", "Portal", "Katana", "Deagle", "PlasmaBlade" } do
		assert(not joined.owned[id], "an old profile got " .. id .. " it never had")
	end
	local kept = count(joined.owned)
	-- Once: the next join changes nothing.
	local again = ProgressService.joinedProfile(ProgressService.clean({ takedowns = 60, owned = joined.owned, ladder = joined.ladder }), nil)
	assert(count(again.owned) == kept, "grandfathered twice")
	-- A save that meets the old stored profile without having read it keeps it too.
	local session = ProgressService.clean(nil)
	local merged = ProgressService.merge(ProgressService.clean({ takedowns = 60 }), session)
	assert(merged.owned.TNT and merged.owned.Shrink and not merged.owned.Chicken, "a blind save lost an old profile's tools")
	-- A field a newer version wrote rides along on this version's saves (never wiped).
	local kept2 = ProgressService.keepUnknownForTest({ future = { 1, 2 }, takedowns = 5 }, { takedowns = 9 })
	assert(kept2.future and kept2.takedowns == 9, "a save dropped a field it does not know (or kept a stale known one)")
	-- A new player gets nothing extra.
	local newbie = ProgressService.joinedProfile(nil, nil)
	assert(count(newbie.owned) == 0, "a new player was grandfathered")
	table.insert(results, string.format("an old profile at 60 takedowns keeps %d tools (old open ones, crossbow to shrink), nothing new, its 12 saved eggs still hats; once; also through a blind save; a new player gets none; saves keep fields from newer versions", kept))
end

local function cutting(results: { string }, player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	assert(root, "no avatar")
	local here = (root :: BasePart).Position
	local shotgun = Toys.byId.Shotgun
	local range = shotgun.severRange :: number
	assert(HitService.severFor(shotgun, player, here + Vector3.new(0, 0, range - 4)) == shotgun.sever, "the shotgun up close cannot cut")
	assert(HitService.severFor(shotgun, player, here + Vector3.new(0, 0, range + 6)) == 0, "the shotgun cuts from afar")
	assert(HitService.severFor(shotgun, nil, here) == 0, "a shotgun hit with no shooter cuts")
	for _, id in { "Axe", "Cleaver", "Katana", "Chainsaw", "PlasmaBlade" } do
		local toy = Toys.byId[id]
		assert(toy.sever > 0 and HitService.severFor(toy, player, here + Vector3.new(0, 0, 200)) == toy.sever, id .. " cannot cut")
	end
	for _, id in { "Blaster", "Deagle", "Bat", "Crowbar", "Punch" } do
		assert(Toys.byId[id].sever <= 0, id .. " cuts limbs off")
	end
	-- Every new weapon in the hand; the guns with a muzzle.
	player:SetAttribute("UnlockAll", true)
	local before = HeldService.holdingOf(player)
	for _, id in { "Blaster", "Crowbar", "Deagle", "Axe", "Cleaver", "Shotgun", "Katana", "Chainsaw", "PlasmaBlade" } do
		HeldService.onHold(player, id)
		local held = (character :: Model):FindFirstChild("HeldTool")
		assert(held and held:GetAttribute("Tool") == id, id .. " is not in the hand")
		if Toys.byId[id].gun then
			assert(held:FindFirstChild("Tip"), id .. " has no muzzle")
		end
		task.wait(0.15) -- (the hold limit, 10 a second)
	end
	HeldService.onHold(player, before or "Blaster")
	table.insert(results, string.format("the shotgun cuts only within %d studs; 5 blades always can; guns and blunt ones never; 9 weapons in the hand", range))
	-- Round 3, M4: every weapon held in the hand says how it is carried (its stance), and the right
	-- one: handguns as a pistol, long guns (and the shotgun) as a rifle, clubs and blades on the shoulder.
	local counts = { Pistol = 0, Rifle = 0, Melee = 0 }
	for _, toy in Toys.list do
		if toy.held and (toy.gun or toy.move == "Swing" or toy.move == "Chop" or toy.move == "Golf") then
			assert(toy.stance ~= nil, toy.id .. " is held but has no stance")
		end
		if toy.stance then
			counts[toy.stance] += 1
			if toy.gun then
				assert(toy.stance == "Pistol" or toy.stance == "Rifle", toy.id .. " is a gun carried as " .. toy.stance)
			else
				assert(toy.stance ~= "Pistol", toy.id .. " is no gun but carried as one")
			end
		end
	end
	assert(Toys.byId.Shotgun.stance == "Rifle" and Toys.byId.Blaster.stance == "Pistol" and Toys.byId.Bat.stance == "Melee", "the G17, the shotgun or the bat carried wrong")
	table.insert(results, string.format("stances: %d pistols, %d long guns, %d on the shoulder; every held gun, club and blade has one", counts.Pistol, counts.Rifle, counts.Melee))
end

return {
	name = "weapons-ladder-eggs-buying",
	timeout = 60,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and ProgressService.profileForTest(first) ~= nil and ProgressService.isLoaded(first)
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		local profile = ProgressService.profileForTest(player) :: any
		assert(profile, "no profile")
		local saved = {
			takedowns = profile.takedowns,
			eggs = profile.eggs,
			owned = table.clone(profile.owned),
			pending = table.clone(profile.pending),
			hats = table.clone(profile.hats),
			hat = profile.hat,
			oldEggs = profile.oldEggs,
		}
		local results = {}
		ladder(results)
		local ok, err = pcall(function()
			eggs(results, player, profile)
			buying(results, player, profile)
			oldProfiles(results)
			cutting(results, player)
		end)
		-- The test leaves the profile as it found it.
		profile.takedowns = saved.takedowns
		profile.eggs = saved.eggs
		profile.pending = saved.pending
		profile.oldEggs = saved.oldEggs
		profile.hats = saved.hats
		profile.hat = saved.hat
		ProgressService.setOwnedForTest(player, saved.owned)
		ProgressService.wear(player, saved.hat or "") -- (the hat an egg put on comes off again)
		player:SetAttribute("UnlockAll", true)
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
