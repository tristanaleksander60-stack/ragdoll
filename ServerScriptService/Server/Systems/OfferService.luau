--!strict
-- Release 0.20.0: sells and grants Shop.OFFERS (what each gives: Shared\Offers). The owner pastes
-- each id into Shop.OFFERS and nothing else.
--   remote Offers   client Buy <key>   server Refused <text>
--   products  (kind "product")  the one ProcessReceipt (Purchases, store Orders_v1): an order per
--             purchase id, delivered here, then completed. deliver also remembers the purchase id
--             in the profile's eco.got, so a re-delivered order (a server that died before
--             Purchases.complete landed) is completed without granting twice.
--   passes    (kind "pass")  asked of Roblox on join (UserOwnsGamePassAsync, retried) and on
--             PromptGamePassPurchaseFinished; kept for the session only and turned into the
--             attributes the game reads (Offers.effectsOf): PassToys (ProgressService.isUnlocked,
--             ToolCatalog), DoubleBolts (EconomyService), VipLab (VisitorService), EventsPass
--             (EventService), plus Offer_<key> = true for the shop's OWNED.
-- Id 0: never on sale live; in Studio BUY grants it at once for testing (a pass for the session, a
-- product with a made-up purchase id).

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Shop = require(Shared:WaitForChild("Shop"))
local Offers = require(Shared:WaitForChild("Offers"))
local Toys = require(Shared:WaitForChild("Toys"))
local Log = require(Shared:WaitForChild("Log"))

local Purchases = require(script.Parent.Purchases)
local ProgressService = require(script.Parent.ProgressService)
local EconomyService = require(script.Parent.EconomyService)

local log = Log.new("Offers")

local OfferService = {}

OfferService.BUY_GAP = 2 -- s between two Buy asks
OfferService.OWNERSHIP_TRIES = 4
OfferService.OWNERSHIP_RETRY = 10 -- s
OfferService.LOAD_WAIT = 30 -- s a delivery waits for the buyer's profile

-- Swappable for tests (no real weapons or bolts handed out by T68).
OfferService.giveBolts = function(player: Player, n: number, text: string): boolean
	return EconomyService.give(player, n, text, true)
end
OfferService.giveWeapon = function(player: Player, id: string): boolean
	return ProgressService.grantWeapon(player, id, "Offer")
end
OfferService.complete = function(userId: number, purchaseId: string)
	Purchases.complete(userId, purchaseId)
end
OfferService.askOwns = function(userId: number, passId: number): boolean
	-- (V8-0.8: a play-as-newcomer visit owns no pass, so it sees what a new player sees.)
	local who = game:GetService("Players"):GetPlayerByUserId(userId)
	if who and (require(script.Parent:WaitForChild("TestAccount")) :: any).is(who) then
		return false
	end
	return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
end

local remote: RemoteEvent? = nil
local owned: { [Player]: { [string]: boolean } } = {}
local lastBuy: { [Player]: number } = {}

local function refuse(player: Player, text: string)
	local r = remote
	if r and player.Parent then
		r:FireClient(player, "Refused", text)
	end
end

-- The game's attributes from the passes a player owns now.
function OfferService.apply(player: Player)
	local mine = owned[player] or {}
	local e = Offers.effectsOf(mine)
	player:SetAttribute("PassToys", e.PassToys)
	player:SetAttribute("DoubleBolts", e.DoubleBolts)
	player:SetAttribute("VipLab", e.VipLab)
	player:SetAttribute("EventsPass", e.EventsPass)
	player:SetAttribute("LabControls", e.LabControls)
	for _, offer in Shop.OFFERS do
		if offer.kind == "pass" then
			player:SetAttribute("Offer_" .. offer.key, if mine[offer.key] then true else nil)
		end
	end
end

-- A pass is the player's (Roblox said so, or a Studio test).
function OfferService.grantPass(player: Player, key: string)
	local mine = owned[player] or {}
	owned[player] = mine
	if not mine[key] then
		mine[key] = true
		OfferService.apply(player)
		local offer = Offers.byKey[key]
		ProgressService.notice(player, string.format("%s is yours. Thank you!", if offer then offer.name else key))
	end
end

-- Tests: forget the session's passes.
function OfferService.resetForTest(player: Player)
	owned[player] = {}
	OfferService.apply(player)
end

function OfferService.owns(player: Player, key: string): boolean
	local mine = owned[player]
	return mine ~= nil and mine[key] == true
end

-- A developer product's order: granted once per purchase id (eco.got), then completed. Yields
-- (waits for the profile). Returns "granted", "repeat" or "waiting" (not loaded: the order goes
-- back to Purchases for the buyer's next server).
function OfferService.deliver(player: Player, key: string, purchaseId: string, test: boolean?): string
	local grant = Offers.GRANTS[key]
	local started = os.clock()
	local e = ProgressService.ecoOf(player)
	while not e and player.Parent and os.clock() - started < OfferService.LOAD_WAIT do
		task.wait(0.5)
		e = ProgressService.ecoOf(player)
	end
	if not e or not grant then
		if not test then
			task.spawn(Purchases.release, player.UserId, { purchaseId })
		end
		return "waiting"
	end
	local eco = e :: any
	if table.find(eco.got, purchaseId) then
		if not test then
			task.spawn(OfferService.complete, player.UserId, purchaseId)
		end
		return "repeat"
	end
	table.insert(eco.got, purchaseId)
	while #eco.got > 30 do
		table.remove(eco.got, 1)
	end
	local offer = Offers.byKey[key]
	local parts = {}
	if grant.bolts then
		OfferService.giveBolts(player, grant.bolts, string.format("+%d BOLTS", grant.bolts))
		table.insert(parts, string.format("%d BOLTS", grant.bolts))
	end
	if grant.weapon and Toys.byId[grant.weapon] then
		OfferService.giveWeapon(player, grant.weapon)
		table.insert(parts, Toys.byId[grant.weapon].label)
	end
	ProgressService.ecoChanged(player)
	ProgressService.notice(player, string.format("%s: %s. Thank you!", if offer then offer.name else key, table.concat(parts, " and ")))
	log.info(string.format("%d got %s (%s)", player.UserId, key, purchaseId))
	if not test then
		task.spawn(OfferService.complete, player.UserId, purchaseId)
	end
	return "granted"
end

-- Asks Roblox which offer passes the player owns (retried while Roblox does not answer).
local function checkOwnership(player: Player)
	local unknown = {}
	for _, offer in Shop.OFFERS do
		if offer.kind == "pass" and offer.id ~= 0 then
			table.insert(unknown, offer)
		end
	end
	for round = 1, OfferService.OWNERSHIP_TRIES do
		local still = {}
		for _, offer in unknown do
			local ok, has = pcall(OfferService.askOwns, player.UserId, offer.id)
			if not player.Parent then
				return
			end
			if ok then
				if has then
					local mine = owned[player] or {}
					owned[player] = mine
					mine[offer.key] = true
				end
			else
				table.insert(still, offer)
			end
		end
		OfferService.apply(player)
		unknown = still
		if #unknown == 0 then
			return
		end
		if round < OfferService.OWNERSHIP_TRIES then
			task.wait(OfferService.OWNERSHIP_RETRY)
		end
	end
end
OfferService.checkOwnershipForTest = checkOwnership

-- lihfolk-ignore: remote-unvalidated-args (kind must be "Buy", key a string naming a known offer; rate gap below)
local function onBuy(player: Player, kind: unknown, key: unknown)
	if kind ~= "Buy" or type(key) ~= "string" then
		return
	end
	local offer = Offers.byKey[key]
	local now = os.clock()
	if not offer or now - (lastBuy[player] or -math.huge) < OfferService.BUY_GAP then
		return
	end
	lastBuy[player] = now
	if offer.kind == "pass" and OfferService.owns(player, offer.key) then
		refuse(player, "You have it already!")
		return
	end
	if offer.id == 0 then
		if not RunService:IsStudio() then
			refuse(player, offer.name .. " is not on sale yet")
		elseif offer.kind == "pass" then
			OfferService.grantPass(player, offer.key) -- (Studio: for this session)
		else
			task.spawn(OfferService.deliver, player, offer.key, "studio-" .. HttpService:GenerateGUID(false), true)
		end
		return
	end
	if offer.kind == "pass" then
		MarketplaceService:PromptGamePassPurchase(player, offer.id)
	else
		if Purchases.isClosing() then
			refuse(player, "The server is restarting. Try again in the next one!")
			return
		end
		MarketplaceService:PromptProductPurchase(player, offer.id)
	end
end

function OfferService.start()
	remote = Net.event(Net.Names.Offers)
	for _, offer in Shop.OFFERS do
		if offer.kind == "product" then
			local key = offer.key
			Purchases.register("Offer:" .. key, offer.id, function(player: Player, order: Purchases.Order)
				task.spawn(OfferService.deliver, player, key, order.p) -- (onOrder must not yield)
			end)
		end
	end
	;(remote :: RemoteEvent).OnServerEvent:Connect(onBuy)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		if not purchased then
			return
		end
		for _, offer in Shop.OFFERS do
			if offer.kind == "pass" and offer.id ~= 0 and offer.id == passId then
				OfferService.grantPass(player, offer.key)
			end
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(checkOwnership, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(checkOwnership, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
		lastBuy[player] = nil
	end)
end

return OfferService
