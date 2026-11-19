--!strict
-- Weapons for Robux (round 2, N4). A locked weapon's BUY button in the catalog asks for it here:
-- the weapon is remembered on the profile for its price tier (pending), then Roblox's prompt opens
-- for that tier's developer product (Shop.WEAPON_PRODUCTS, one per Toys.priceTiers entry).
--
-- The weapon chosen is written into the order itself the moment the receipt arrives (Purchases'
-- describe: the order's d), so a second BUY made afterwards never changes what this purchase
-- gives. The order (saved before Roblox hears PurchaseGranted) is delivered from that note (or
-- the pending choice), or the lowest locked one at that price or dearer when it is owned already.
-- A weapon nearly earned (Toys.canBuy) is never sold. The purchase id
-- goes into the profile with the weapon (one save), and only once that save has landed is the
-- order completed. A failed save releases the order (claimed again later: this server finds the
-- id in the profile and only saves again; another server reads the stored profile and delivers
-- it there). A repeated receipt never gives a second weapon.
--
-- Robux only: nothing here is reachable from Streamer Mode (TikTok gifts never give lasting value).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local Shop = require(Shared:WaitForChild("Shop"))
local Toys = require(Shared:WaitForChild("Toys"))

local ProgressService = require(script.Parent.ProgressService)
local Purchases = require(script.Parent.Purchases)
local Metrics = require(script.Parent.Metrics)

local log = Log.new("WeaponShop")

local WeaponShop = {}

local PROMPT_GAP = 1.5 -- s between two prompts of one player (a double tap)

local remote: RemoteEvent? = nil
local lastPrompt: { [Player]: number } = {}

local function tell(player: Player, kind: string, data: { [string]: any })
	if remote then
		remote:FireClient(player, kind, data)
	end
end

-- After the delivery is in the profile: saved, then the order is done (or released to try again).
local function settle(player: Player, purchaseId: string, direct: boolean)
	if direct then
		ProgressService.saveNow(player) -- (Studio's direct give: no order to complete)
	elseif ProgressService.saveNow(player) then
		Purchases.complete(player.UserId, purchaseId)
	else
		log.warn("weapon purchase " .. purchaseId .. " not saved yet: released, delivered again later")
		Purchases.release(player.UserId, { purchaseId })
	end
end

-- Delivers one order (never yields: Purchases' rule). Returns what it gave (tests read it).
-- direct: Studio's give without a purchase (no order behind it).
function WeaponShop.deliver(player: Player, tierKey: string, purchaseId: string, earlier: boolean?, direct: boolean?, chosen: string?): (string, string?)
	local result, id = ProgressService.deliverWeapon(player, tierKey, purchaseId, chosen)
	if result == "wait" then
		error("profile not ready") -- (Purchases releases the claim: claimed again once it is)
	end
	if result == "weapon" and id then
		local toy = Toys.byId[id]
		tell(player, "Bought", { id = id, name = toy.label, earlier = earlier == true })
	elseif result == "eggs" then
		tell(player, "Bought", { eggs = 2, earlier = earlier == true })
	end
	task.spawn(settle, player, purchaseId, direct == true)
	return result, id
end

local function onRequest(player: Player, kind: unknown, arg: unknown)
	if kind ~= "Buy" or type(arg) ~= "string" then
		return
	end
	local toy = Toys.byId[arg]
	local tier = toy and Toys.priceTier(toy)
	if not toy or not tier then
		return
	end
	local now = os.clock()
	if lastPrompt[player] and now - lastPrompt[player] < PROMPT_GAP then
		return
	end
	lastPrompt[player] = now
	if not ProgressService.isLoaded(player) then
		tell(player, "Refused", { text = "Your progress is still loading. Try again in a moment" })
		return
	elseif ProgressService.isUnlocked(player, toy, true) then
		tell(player, "Refused", { text = toy.label .. " is yours already!" })
		return
	elseif not Toys.canBuy(toy, ProgressService.takedownsOf(player) or 0) then
		local left = math.max(1, toy.unlockAt - (ProgressService.takedownsOf(player) or 0))
		tell(player, "Refused", { text = string.format("Only %d more takedowns for the %s!", left, toy.label) })
		return
	elseif Purchases.isClosing() then
		tell(player, "Refused", { text = "The server is restarting. Try again in the next one!" })
		return
	end
	if not ProgressService.choosePending(player, tier.key, toy.id) then
		return
	end
	Metrics.event(player, "Weapon_Prompt", 1, toy.id)
	local productId = Shop.WEAPON_PRODUCTS[tier.key] or 0
	if productId ~= 0 then
		-- (Saved first, so the weapon chosen is known to whichever server delivers the order.)
		task.spawn(function()
			ProgressService.saveNow(player)
		end)
		MarketplaceService:PromptProductPurchase(player, productId)
	elseif RunService:IsStudio() then
		-- Not on sale yet: in Studio the BUY button gives it straight away (as if bought).
		WeaponShop.deliver(player, tier.key, "studio-" .. HttpService:GenerateGUID(false), false, true, toy.id)
	else
		tell(player, "Refused", { text = "Buying weapons is coming soon!" })
	end
end

-- What a tier's orders do (registered with Purchases; tests register it under a test product id).
function WeaponShop.handlerFor(key: string): Purchases.OnOrder
	return function(player: Player, order: Purchases.Order)
		WeaponShop.deliver(player, key, order.p, os.time() - order.t > 60, false, order.d)
	end
end

-- What a tier's receipt writes into its order: the weapon chosen for that tier right now.
function WeaponShop.describerFor(key: string): Purchases.Describe
	return function(player: Player): string?
		return ProgressService.pendingOf(player, key)
	end
end

WeaponShop.onRequest = onRequest -- (tests)
function WeaponShop.resetForTest(player: Player)
	lastPrompt[player] = nil
end

function WeaponShop.start()
	remote = Net.event(Net.Names.Weapons)
	;(remote :: RemoteEvent).OnServerEvent:Connect(onRequest)
	for _, tier in Toys.priceTiers do
		Purchases.register(tier.key, Shop.WEAPON_PRODUCTS[tier.key] or 0, WeaponShop.handlerFor(tier.key), WeaponShop.describerFor(tier.key))
	end
	-- An order that arrived before the profile was read waits for it.
	ProgressService.onLoaded(function(player: Player)
		task.spawn(Purchases.claimOwed, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastPrompt[player] = nil
	end)
	log.info("ready")
end

return WeaponShop
