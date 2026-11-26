--!strict
-- Server events (phase 4a): every event does what it says and puts everything back when it ends.
-- Purchases: a receipt is saved as an order exactly once (a repeat grants nothing), unknown
-- products and absent buyers wait, and an order survives everything that can happen before its
-- event runs: a failed hand-over, a closing server, a crashed server (stale claim), the buyer
-- leaving, a failed start. A full queue refuses free events but never a paid one. Whatever the
-- test changes (order store, test product, closing flag) is put back, pass or fail.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local EventService = require(Systems:WaitForChild("EventService"))
local Purchases = require(Systems:WaitForChild("Purchases"))
local Lab = require(Systems:WaitForChild("Lab"))

local TEST_PRODUCT = 990001
local TEST_KEY = "Test:Grant"

local function waitFor(check: () -> boolean, timeout: number): boolean
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if check() then
			return true
		end
		task.wait(0.1)
	end
	return check()
end

local function labDummies(): { Model }
	local list = {}
	local folder = Workspace:FindFirstChild("Dummies")
	for _, model in if folder then folder:GetChildren() else {} do
		if model:IsA("Model") and model:GetAttribute("Slot") ~= nil then
			table.insert(list, model)
		end
	end
	return list
end

local function guests(): number
	local n = 0
	local folder = Workspace:FindFirstChild("Dummies")
	for _, model in if folder then folder:GetChildren() else {} do
		if model:GetAttribute("Guest") == true then
			n += 1
		end
	end
	return n
end

-- Runs one event and waits for it to start; returns once it is running. Events run in the order
-- they came: an order an earlier step gave back may be delivered first (Purchases' reclaim), so
-- this waits for whatever is ahead of it too.
-- (Set off for the tester: an event happens in the lab of whoever it is for, while they are in it,
-- and the tester stands in their own lab with its dummies.)
local function start(id: string)
	local tester = game:GetService("Players"):GetPlayers()[1]
	assert(EventService.trigger(id, if tester then tester.DisplayName else "Tester", "Test", nil, nil, if tester then tester.UserId else nil), "could not queue " .. id)
	assert(waitFor(function()
		return EventService.current() == id
	end, 60), id .. " never started")
end

local function finish(id: string)
	assert(waitFor(function()
		return EventService.current() ~= id
	end, 30), id .. " never ended")
end

local function body(player: Player, results: { string })
	local Granted = Enum.ProductPurchaseDecision.PurchaseGranted
	local NotYet = Enum.ProductPurchaseDecision.NotProcessedYet
	local me = player.UserId

	local function owed(purchaseId: string): any
		local doc = Purchases.peek(me)
		for _, order in if doc then doc.owed else {} do
			if order.p == purchaseId then
				return order
			end
		end
		return nil
	end

	-- Receipts: saved and handed over once; unknown products and absent buyers wait.
	local handed = 0
	local failNext = false
	Purchases.register(TEST_KEY, TEST_PRODUCT, function()
		if failNext then
			failNext = false
			error("could not queue it, on purpose")
		end
		handed += 1
	end)
	local function receipt(id: string, userId: number?, product: number?): { [string]: any }
		return { PurchaseId = id, PlayerId = userId or me, ProductId = product or TEST_PRODUCT, CurrencySpent = 25 }
	end
	local once = receipt("test-once")
	assert(Purchases.processReceipt(once) == Granted, "the first receipt was not granted")
	assert(Purchases.processReceipt(once) == Granted, "the repeated receipt was not acknowledged")
	assert(handed == 1, string.format("one purchase was handed over %d times", handed))
	local order = owed("test-once")
	assert(order and order.c ~= nil, "the purchase was not saved as an order claimed by this server")
	assert(Purchases.processReceipt(receipt("test-unknown", nil, TEST_PRODUCT + 1)) == NotYet, "an unknown product was acknowledged")
	assert(Purchases.processReceipt(receipt("test-absent", 1)) == NotYet, "a receipt for someone not here was acknowledged")
	assert(Purchases.peek(1) == nil, "a receipt for someone not here was saved")
	table.insert(results, "receipts: saved once; wait when absent or unknown")

	-- An order that cannot be queued is released, and the buyer's next claim picks it up.
	failNext = true
	assert(Purchases.processReceipt(receipt("test-flaky")) == Granted, "a saved order was not acknowledged")
	assert(waitFor(function()
		local o = owed("test-flaky")
		return o ~= nil and o.c == nil
	end, 3), "an order that could not be queued was not released")
	assert(Purchases.claimOwed(player) == 1 and handed == 2, "the released order was not claimed again")
	assert(Purchases.claimOwed(player) == 0, "an order was claimed twice")
	-- A closing server saves orders unclaimed and claims nothing.
	Purchases.setClosingForTest(true)
	local closingOk = Purchases.processReceipt(receipt("test-closing")) == Granted
	local closingClaims = Purchases.claimOwed(player)
	Purchases.setClosingForTest(false)
	assert(closingOk, "a closing server refused a receipt")
	assert(handed == 2 and closingClaims == 0, "a closing server queued an order")
	local unclaimed = owed("test-closing")
	assert(unclaimed and unclaimed.c == nil, "a closing server claimed its order")
	assert(Purchases.claimOwed(player) == 1 and handed == 3, "the next server did not pick up the order")
	-- A claim by a server that is gone expires.
	table.insert(Purchases.peek(me).owed, { k = TEST_KEY, p = "test-stale", t = os.time() - 3600, c = "gone-server", ct = os.time() - 3600 })
	assert(Purchases.claimOwed(player) == 1 and handed == 4, "a stale claim was not taken over")
	-- A hand-over that was lost (claimed here, never queued) is picked up again: by a repeat of
	-- the receipt, and by a claim.
	local here = owed("test-once").c
	local lostDoc = Purchases.peek(me)
	table.insert(lostDoc.seen, "test-lost")
	table.insert(lostDoc.owed, { k = TEST_KEY, p = "test-lost", t = os.time(), c = here, ct = os.time() })
	assert(Purchases.processReceipt(receipt("test-lost")) == Granted and handed == 5, "a repeat did not hand over its lost order")
	assert(Purchases.processReceipt(receipt("test-lost")) == Granted and handed == 5, "a repeat handed an order over twice")
	table.insert(Purchases.peek(me).owed, { k = TEST_KEY, p = "test-lost-2", t = os.time(), c = here, ct = os.time() })
	assert(Purchases.claimOwed(player) == 1 and handed == 6, "a claim did not pick up a lost hand-over")
	Purchases.unregister(TEST_KEY)
	table.insert(results, "orders survive a failed hand-over, a lost one, a closing server and a crashed one")

	-- The queue: full refuses free events, a paid one still goes in.
	for i = 1, 4 do
		assert(EventService.trigger("FlashFreeze", "Q" .. i, "Test"), "queue refused event " .. i)
	end
	assert(not EventService.trigger("FlashFreeze", "Q5", "Test"), "a full queue took a free event")
	assert(EventService.trigger("FlashFreeze", "Paid", "Robux", true), "a full queue refused a paid event")
	EventService.clearQueue()
	finish("FlashFreeze") -- the first one may have started already
	table.insert(results, "queue limit holds")

	-- A paid event owed from before: claimed on join, given back when the buyer leaves, claimed
	-- again, and no longer owed once it has run.
	-- (The order document is replaced on every write: always add to the latest one.)
	local function addOwed(key: string, purchaseId: string)
		table.insert(Purchases.peek(me).owed, { k = key, p = purchaseId, t = os.time() - 600 })
	end
	addOwed("Event:FlashFreeze", "test-event")
	assert(Purchases.claimOwed(player) == 1 and EventService.queued() == 1, "the owed event was not queued")
	EventService.buyerLeftForTest(me)
	assert(EventService.queued() == 0, "a buyer who left kept their event in the queue")
	assert(waitFor(function()
		local o = owed("test-event")
		return o ~= nil and o.c == nil
	end, 3), "the event of a buyer who left was not given back")
	assert(Purchases.claimOwed(player) == 1, "the given-back event was not claimed again")
	assert(waitFor(function()
		return owed("test-event") == nil
	end, 10), "the event ran but is still owed")
	finish("FlashFreeze")
	table.insert(results, "owed events follow the buyer and are done once run")

	-- A paid event that fails to start goes again; failing twice, it goes back to the buyer.
	EventService.failStartsForTest(1)
	addOwed("Event:ZeroG", "test-retry")
	Purchases.claimOwed(player)
	assert(waitFor(function()
		return owed("test-retry") == nil
	end, 15), "a paid event that failed once never ran")
	finish("ZeroG")
	EventService.failStartsForTest(2)
	addOwed("Event:ZeroG", "test-broken")
	Purchases.claimOwed(player)
	assert(waitFor(function()
		local o = owed("test-broken")
		return o ~= nil and o.c == nil and EventService.queued() == 0 and EventService.current() == nil
	end, 15), "a paid event that kept failing was not given back")
	EventService.failStartsForTest(0)
	table.insert(results, "a failed paid start gets one retry, then goes back to the buyer")

	-- Zero-G: gravity drops, then comes back.
	local gravity = Workspace.Gravity
	start("ZeroG")
	assert(Workspace.Gravity < 60, "Zero-G did not lower gravity")
	finish("ZeroG")
	assert(math.abs(Workspace.Gravity - gravity) < 0.01, "gravity was not put back")
	table.insert(results, "zero-g restored")

	-- Bouncy Floor: every big floor (nested ones too) turns to rubber, then back. (A painted floor
	-- nothing lands on, a lab's or the plaza's, is not one.)
	local floors: { { part: BasePart, was: PhysicalProperties? } } = {}
	for _, part in Workspace:GetDescendants() do
		if part:IsA("BasePart") and not part:IsA("Terrain") and part.Anchored and part.CanCollide and part.Size.X >= 40 and part.Size.Z >= 40 then
			table.insert(floors, { part = part, was = part.CustomPhysicalProperties })
		end
	end
	assert(#floors > 0, "no floor to test")
	start("BouncyFloor")
	for _, floor in floors do
		local props = floor.part.CustomPhysicalProperties
		assert(props and props.Elasticity > 0.9, floor.part:GetFullName() .. " is not bouncy")
	end
	finish("BouncyFloor")
	for _, floor in floors do
		assert(floor.part.CustomPhysicalProperties == floor.was, floor.part:GetFullName() .. " was not put back")
	end
	table.insert(results, string.format("bouncy floor: %d floors restored", #floors))

	-- Flash Freeze: the lab dummies are ice.
	start("FlashFreeze")
	task.wait(0.5)
	local frozen = 0
	for _, model in labDummies() do
		if model:GetAttribute("Frozen") == true then
			frozen += 1
		end
	end
	assert(frozen >= 4, string.format("only %d lab dummies froze", frozen))
	finish("FlashFreeze")
	assert(waitFor(function()
		for _, model in labDummies() do
			if model:GetAttribute("Frozen") == true then
				return false
			end
		end
		return true
	end, 6), "the ice never thawed")
	table.insert(results, string.format("froze %d dummies", frozen))

	-- Mega Bomb: the lab dummies go flying.
	task.wait(3)
	start("MegaBomb")
	local knocked = 0
	waitFor(function()
		knocked = 0
		for _, model in labDummies() do
			local s = model:GetAttribute("RagdollState")
			if s == "Ragdoll" or s == "Out" then
				knocked += 1
			end
		end
		return knocked >= 4
	end, 3)
	assert(knocked >= 4, string.format("the bomb knocked only %d dummies over", knocked))
	finish("MegaBomb")
	table.insert(results, string.format("bomb knocked %d over", knocked))

	-- Dummy Rain: guests fall in, and are all gone afterwards.
	start("DummyRain")
	assert(waitFor(function()
		return guests() >= 8
	end, 6), string.format("only %d dummies rained down", guests()))
	local most = guests()
	local folder = Workspace:FindFirstChild("Dummies")
	local owned = 0
	for _, model in if folder then folder:GetChildren() else {} do
		if model:GetAttribute("Guest") == true and model:GetAttribute("Owner") == player.UserId then
			owned += 1
		end
	end
	finish("DummyRain")
	assert(waitFor(function()
		return guests() == 0
	end, 3), "rain dummies were left behind")
	table.insert(results, string.format("rained %d (%d on the lab owner's client), all gone after", most, owned))
end

return {
	name = "server-events-and-receipts",
	timeout = 220,
	run = function(): string?
		local waited = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player, "needs a player in the session")
		assert(waitFor(EventService.isReady, 20), "the event service never started")
		EventService.clearQueue()
		assert(waitFor(function()
			return EventService.current() == nil
		end, 30), "an event is already running")
		local results: { string } = {}
		Lab.sendHome(player) -- (earlier tests leave the avatar about the plaza)
		task.wait(0.5)
		local wasMemory = Purchases.setMemoryStore(true)
		local ok, err = pcall(body, player, results)
		-- Put back what the test changed, pass or fail.
		Purchases.unregister(TEST_KEY)
		Purchases.setClosingForTest(false)
		EventService.failStartsForTest(0)
		EventService.clearQueue()
		Purchases.setMemoryStore(wasMemory)
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
