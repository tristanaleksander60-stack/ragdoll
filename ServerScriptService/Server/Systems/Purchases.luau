--!strict
-- The one and only MarketplaceService.ProcessReceipt in the game (vault: "Developer Products and
-- ProcessReceipt", roblox-monetization-compliance, roblox-datastore-safety).
--
-- Every developer product in this game is an order: something the buyer is owed until it has
-- happened (a server event runs later, from a queue). Each buyer has one order document
-- (DataStore "Orders_v1", key "u<userId>"):
--
--   v        schema version (1)
--   seen     the last purchase ids already granted (a repeat is acknowledged, never granted twice)
--   owed     orders not delivered yet: { k = product key, p = purchase id, t = bought at,
--            c = the server that has it queued (its claim), ct = when the claim was last renewed }
--   history  the last purchases for support and refunds: { p, k, r = Robux, t }
--
-- The grant and the purchase id go in the same write (one UpdateAsync): once Roblox hears
-- PurchaseGranted the order is saved. Whatever happens to the server afterwards (shutdown, crash),
-- the order is still owed and is claimed again by the buyer's server: on join, shortly after
-- (a fast server hop) and every few minutes. A server renews its claims while it holds them; a
-- claim that is not renewed (a crashed server) expires after CLAIM_EXPIRY. Writes still in flight
-- are waited for when the server closes.
--
-- Without a DataStore a live server never grants (NotProcessedYet). Studio keeps orders in memory
-- without API access, and in a separate test store with it (never the live one).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Log = require(ReplicatedStorage.Shared.Log)

local log = Log.new("Purchases")

local Purchases = {}

local SEEN_KEPT = 100 -- purchase ids remembered per buyer (Roblox repeats a receipt within days)
local HISTORY_KEPT = 50
local CLAIM_EXPIRY = 5 * 60 -- s: a claim not renewed for this long belongs to a server that is gone
local RENEW_EVERY = 90 -- s
local RECLAIM_EVERY = 180 -- s: every player's owed orders are looked at again
local RETRIES = 3
local COMPLETE_TRIES = 4 -- rounds of RETRIES before a delivered order is left to a later server

-- d: what the order is for, written down as the receipt arrives (a product's describe, e.g. the
-- weapon chosen: it travels with the order to whichever server delivers it).
export type Order = { k: string, p: string, t: number, c: string?, ct: number?, f: number?, d: string? }

-- Called once an order is saved, for a buyer in this server, with the order claimed by this
-- server. It queues the order in memory; it must not yield. An error releases the claim (the
-- order waits for the buyer's next server).
export type OnOrder = (player: Player, order: Order) -> ()

-- Called as a receipt arrives, before the order is saved: a short note of what was bought (at most
-- 64 characters), kept in the order as d. Must not yield.
export type Describe = (player: Player) -> string?

type Product = { key: string, productId: number, onOrder: OnOrder, describe: Describe? }

local products: { [number]: Product } = {}
local byKey: { [string]: Product } = {}
local store: DataStore? = nil
local memory: { [string]: any } = {}
local useMemory = false
local closing = false
-- Orders this server has handed over (queued, not run yet): purchase id -> buyer's user id. An
-- order claimed by this server but not handed (a lost hand-over) can be claimed again here.
local handed: { [string]: number } = {}
-- Orders with a write of this server in flight (being saved, completed or released): never
-- claimed by this server meanwhile, so one purchase can never be queued twice here.
local busy: { [string]: boolean } = {}
local inflight = 0 -- order writes not finished yet (a closing server waits for them)
local MAX_FAILED_STARTS = 3 -- an order that failed this often is kept for support, not retried
local onWaiting: ((player: Player) -> ())? = nil

-- Every Studio session is its own server: never "the same" one as an earlier test session.
local studioJob = "studio-" .. HttpService:GenerateGUID(false)
local function jobId(): string
	return if game.JobId ~= "" then game.JobId else studioJob
end

-- Registers a developer product and what to do with its orders.
function Purchases.register(key: string, productId: number, onOrder: OnOrder, describe: Describe?)
	assert(byKey[key] == nil, "product " .. key .. " registered twice")
	local product = { key = key, productId = productId, onOrder = onOrder, describe = describe }
	byKey[key] = product -- orders are redeemed by key, on sale or not
	if productId ~= 0 then
		assert(products[productId] == nil, "product id " .. productId .. " registered twice")
		products[productId] = product
	end
end

-- Tests: take a registered product off again.
function Purchases.unregister(key: string)
	local product = byKey[key]
	if product then
		byKey[key] = nil
		if product.productId ~= 0 then
			products[product.productId] = nil
		end
	end
end

local function docKey(userId: number): string
	return "u" .. tostring(userId)
end

local function emptyDoc(): { [string]: any }
	return { seen = {}, owed = {}, history = {}, v = 1 }
end

local function cleanDoc(old: any): { [string]: any }
	if type(old) ~= "table" then
		return emptyDoc()
	end
	local owed = {}
	if type(old.owed) == "table" then
		for _, order in old.owed do
			if type(order) == "table" then
				table.insert(owed, table.clone(order))
			end
		end
	end
	return {
		seen = if type(old.seen) == "table" then table.clone(old.seen) else {},
		owed = owed,
		history = if type(old.history) == "table" then table.clone(old.history) else {},
		v = 1,
	}
end

-- Runs a transform on a buyer's document, with retries. The transform may run more than once
-- (UpdateAsync retries it), so it only computes; nil cancels the write. Returns success.
local function update(userId: number, transform: (doc: { [string]: any }) -> { [string]: any }?): boolean
	local key = docKey(userId)
	if useMemory then
		local result = transform(cleanDoc(memory[key]))
		if result ~= nil then
			memory[key] = result
		end
		return true
	end
	local s = store
	if not s then
		return false
	end
	local lastError: any = nil
	for attempt = 1, RETRIES do
		local ok, err = pcall(function()
			s:UpdateAsync(key, function(old: any)
				local new = transform(cleanDoc(old))
				if new == nil then
					return nil
				end
				return new, { userId } -- tied to the user for data-erasure requests
			end)
		end)
		if ok then
			return true
		end
		lastError = err
		if attempt < RETRIES then
			task.wait(attempt)
		end
	end
	log.warn("orders of " .. userId .. ": " .. tostring(lastError))
	return false
end

local function read(userId: number): (boolean, { [string]: any })
	local key = docKey(userId)
	if useMemory then
		return true, cleanDoc(memory[key])
	end
	local s = store
	if not s then
		return false, emptyDoc()
	end
	for attempt = 1, RETRIES do
		local ok, result = pcall(function()
			return s:GetAsync(key)
		end)
		if ok then
			return true, cleanDoc(result)
		end
		if attempt < RETRIES then
			task.wait(attempt)
		end
	end
	return false, emptyDoc()
end

-- An order this server may take: unclaimed, claimed by a server that is gone, or claimed by this
-- server but never handed over (a lost hand-over).
local function claimable(order: any, now: number): boolean
	if type(order.k) ~= "string" or type(order.p) ~= "string" or not byKey[order.k] then
		return false
	end
	if busy[order.p] or (type(order.f) == "number" and order.f >= MAX_FAILED_STARTS) then
		return false
	end
	if order.c == jobId() then
		return handed[order.p] == nil
	end
	return order.c == nil or type(order.ct) ~= "number" or now - order.ct > CLAIM_EXPIRY
end

-- A write that must land: counted so a closing server waits for it.
local function tracked(fn: () -> boolean): boolean
	inflight += 1
	local ok, result = pcall(fn)
	inflight -= 1
	return ok and result
end

-- Hands an order to its product (this server has claimed it). On failure the claim is given up.
local function handOver(player: Player, order: Order)
	local product = byKey[order.k]
	if not product or handed[order.p] then
		return -- unknown, or already queued here
	end
	handed[order.p] = player.UserId
	local ok, err = pcall(product.onOrder, player, order)
	if not ok then
		handed[order.p] = nil
		log.warn(string.format("%s for %d could not be queued: %s", order.k, player.UserId, tostring(err)))
		task.spawn(Purchases.release, player.UserId, { order.p })
	end
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local product = products[receipt.ProductId]
	if not product then
		log.warn("receipt for an unknown product " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- granted in the server they are in next
	end
	local purchaseId = tostring(receipt.PurchaseId)
	local now = os.time()
	-- A closing server saves the order unclaimed: the buyer's next server picks it up at once.
	local claim = if closing then nil else jobId()
	local isNew = false
	local existing: Order? = nil -- a repeat: the order as it is saved, if still owed
	local note: string? = nil
	if product.describe then
		local ok, d = pcall(product.describe :: Describe, player)
		note = if ok and type(d) == "string" and #d <= 64 then d else nil
	end
	local order: Order = { k = product.key, p = purchaseId, t = now, c = claim, ct = if claim then now else nil, d = note }
	local wasBusy = busy[purchaseId]
	busy[purchaseId] = true
	local saved = tracked(function()
		return update(receipt.PlayerId, function(doc)
		existing = nil
		if table.find(doc.seen, purchaseId) then
			isNew = false
			for _, o in doc.owed do
				if o.p == purchaseId then
					existing = table.clone(o)
				end
			end
			return nil -- granted before: leave it as it is
		end
		isNew = true
		table.insert(doc.seen, purchaseId)
		while #doc.seen > SEEN_KEPT do
			table.remove(doc.seen, 1)
		end
		table.insert(doc.owed, table.clone(order))
		table.insert(doc.history, { p = purchaseId, k = product.key, r = receipt.CurrencySpent, t = now })
		while #doc.history > HISTORY_KEPT do
			table.remove(doc.history, 1)
		end
		return doc
		end)
	end)
	if not wasBusy then
		busy[purchaseId] = nil
	end
	if not saved then
		-- Nothing saved; Roblox asks again later. The buyer hears it is on its way.
		if onWaiting and player.Parent then
			task.spawn(onWaiting :: (Player) -> (), player)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if isNew then
		log.info(string.format("%d bought %s (%s Robux)", receipt.PlayerId, product.key, tostring(receipt.CurrencySpent)))
		-- (V8-5.5: the money funnel: Robux spent this visit, in the visit record.)
		local buyer = Players:GetPlayerByUserId(receipt.PlayerId)
		if buyer and type(receipt.CurrencySpent) == "number" then
			pcall(function()
				(require(script.Parent:WaitForChild("SessionStats")) :: any).count(buyer, "robux", receipt.CurrencySpent)
			end)
		end
	end
	-- What to hand over now: the new order, or a repeat's order this server claimed but never
	-- handed over (the first save landed but its answer was lost).
	local mine: Order? = if isNew and claim then order else nil
	local again = existing
	if not isNew and again and again.c == jobId() and handed[purchaseId] == nil then
		mine = again
	end
	if mine then
		if player.Parent and not closing then
			handOver(player, mine)
		else
			-- They left while the order was being saved: their next server gets it.
			task.spawn(Purchases.release, receipt.PlayerId, { purchaseId })
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- For tests: run a receipt through the real handler.
Purchases.processReceipt = processReceipt

-- The order has happened: it is no longer owed. Yields (keeps trying; a server that closes waits
-- for it).
function Purchases.complete(userId: number, purchaseId: string): boolean
	-- Stays handed (claim renewed, never claimed again here) until the write lands.
	busy[purchaseId] = true
	local done = tracked(function()
		for round = 1, COMPLETE_TRIES do
			local done = update(userId, function(doc)
				for i, order in doc.owed do
					if order.p == purchaseId then
						table.remove(doc.owed, i)
						return doc
					end
				end
				return nil
			end)
			if done then
				return true
			end
			if round < COMPLETE_TRIES and not closing then
				task.wait(5 * round)
			end
		end
		log.warn(string.format("delivered order %s of %d is still saved as owed", purchaseId, userId))
		return false
	end)
	if done then
		handed[purchaseId] = nil
		busy[purchaseId] = nil
	end
	return done
end

-- This server gives orders up (the buyer left, the server is closing, the event could not start):
-- the next server the buyer joins claims them at once. Yields (retries).
-- failedStart: the event could not start (counted; after MAX_FAILED_STARTS it is kept for support).
function Purchases.release(userId: number, purchaseIds: { string }, failedStart: boolean?): boolean
	for _, id in purchaseIds do
		handed[id] = nil
		busy[id] = true
	end
	local done = tracked(function()
		return update(userId, function(doc)
			local changed = false
			for _, order in doc.owed do
				if table.find(purchaseIds, order.p) and order.c == jobId() then
					order.c = nil
					order.ct = nil
					if failedStart then
						order.f = (if type(order.f) == "number" then order.f else 0) + 1
						if order.f >= MAX_FAILED_STARTS then
							log.warn(string.format("order %s of %d failed to start %d times: kept for support", order.p, userId, order.f))
						end
					end
					changed = true
				end
			end
			return if changed then doc else nil
		end)
	end)
	for _, id in purchaseIds do
		busy[id] = nil
	end
	return done
end

-- Renews this server's claims on the orders it holds (a crashed server's claims run out).
local function renewClaims()
	local byUser: { [number]: { string } } = {}
	for purchaseId, userId in handed do
		byUser[userId] = byUser[userId] or {}
		table.insert(byUser[userId], purchaseId)
	end
	local now = os.time()
	for userId, ids in byUser do
		task.spawn(update, userId, function(doc)
			local changed = false
			for _, order in doc.owed do
				if table.find(ids, order.p) and order.c == jobId() then
					order.ct = now
					changed = true
				end
			end
			return if changed then doc else nil
		end)
	end
end

-- Waits (up to timeout s) for release/complete writes still in flight. For BindToClose.
function Purchases.flush(timeout: number)
	local t0 = os.clock()
	while inflight > 0 and os.clock() - t0 < timeout do
		task.wait(0.1)
	end
end

-- Called when a receipt could not be saved yet (the buyer is told it is on its way).
function Purchases.setOnWaiting(fn: (player: Player) -> ())
	onWaiting = fn
end

-- Claims every order owed to a player that no live server has, and hands each to its product.
-- Reads first and writes only when there is something to claim. Returns how many. Yields.
function Purchases.claimOwed(player: Player): number
	if closing then
		return 0
	end
	local now = os.time()
	local ok, doc = read(player.UserId)
	if not ok then
		return 0
	end
	local any = false
	for _, order in doc.owed do
		if claimable(order, now) then
			any = true
		end
	end
	if not any then
		return 0
	end
	local claimed: { Order } = {}
	local saved = update(player.UserId, function(fresh)
		table.clear(claimed)
		for _, order in fresh.owed do
			if claimable(order, now) then
				order.c = jobId()
				order.ct = now
				table.insert(claimed, table.clone(order))
			end
		end
		return if #claimed > 0 then fresh else nil
	end)
	if not saved then
		return 0
	end
	if not player.Parent then
		local ids = {}
		for _, order in claimed do
			table.insert(ids, order.p)
		end
		Purchases.release(player.UserId, ids)
		return 0
	end
	for _, order in claimed do
		handOver(player, order)
	end
	return #claimed
end

-- Tests: a buyer's order document (memory mode only).
function Purchases.peek(userId: number): any
	return if useMemory then memory[docKey(userId)] else nil
end

-- Tests (Studio only): switch the order store to memory; returns the mode to restore.
function Purchases.setMemoryStore(on: boolean): boolean
	assert(RunService:IsStudio(), "memory orders are for Studio only")
	local was = useMemory
	useMemory = on
	if on then
		table.clear(memory)
	end
	-- Test orders are never delivered: forget them with the store.
	table.clear(handed)
	table.clear(busy)
	return was
end

-- Tests (Studio only): act as a closing server for a moment.
function Purchases.setClosingForTest(on: boolean)
	assert(RunService:IsStudio(), "for Studio tests only")
	closing = on
end

-- The server is shutting down: new orders are saved unclaimed, nothing is claimed any more.
function Purchases.close()
	closing = true
end

function Purchases.isClosing(): boolean
	return closing
end

function Purchases.start()
	local studio = RunService:IsStudio()
	-- Studio never touches live orders.
	local name = if studio then "Orders_Studio_v1" else "Orders_v1"
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(name)
	end)
	if ok then
		store = result
	end
	if studio then
		-- Studio without API access: reads fail; keep orders in memory for the session.
		local probe = ok and pcall(function()
			(result :: DataStore):GetAsync("probe")
		end)
		useMemory = not probe
		if useMemory then
			log.info("no DataStore access in Studio: orders last for this session only")
		end
	elseif not ok then
		log.warn("no DataStore: purchases wait until it is back")
	end
	game:BindToClose(Purchases.close)
	task.spawn(function()
		while not closing do
			task.wait(RENEW_EVERY)
			renewClaims()
		end
	end)
	-- Owed orders are looked at again every few minutes (a crashed server's claim ran out, or a
	-- release landed after the buyer's join), spread out over the interval.
	task.spawn(function()
		while not closing do
			task.wait(RECLAIM_EVERY)
			local players = Players:GetPlayers()
			for i, player in players do
				task.delay(RECLAIM_EVERY * (i - 1) / math.max(1, #players), function()
					if player.Parent then
						Purchases.claimOwed(player)
					end
				end)
			end
		end
	end)
	-- Set before any product registers: a receipt for a product not registered yet gets
	-- NotProcessedYet and comes back.
	MarketplaceService.ProcessReceipt = processReceipt
	log.info("ready")
end

return Purchases
