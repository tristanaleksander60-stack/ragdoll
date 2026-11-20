--!strict
-- A developer product's price, always Roblox's own (GetProductInfoAsync: regional pricing
-- included), never a number typed into the game (round 2, N5). One place for the shop's events,
-- the HUD's packs and the catalog's weapon tiers: asked once per product, again a few times when
-- the web call fails (2, 4 and 8 s apart, no wait after the last try), then the answer is kept. A
-- failure is kept only for a while (RETRY_AFTER): asked again after that (opening the shop or the
-- catalog asks), so a bad minute on Roblox's side never locks a product for the whole visit.

local MarketplaceService = game:GetService("MarketplaceService")

local RobuxPrice = {}

local TRIES = 4
RobuxPrice.RETRY_AFTER = 30 -- s a failed answer is kept before it is asked again

-- productId -> price (number), false (asked and failed), or nil (not asked yet / asking).
local known: { [number]: number | false } = {}
local waiting: { [number]: { (number?) -> () } } = {}
local failedAt: { [number]: number } = {}

-- A failure old enough is forgotten (the next get asks again).
local function forgetStale(productId: number)
	if known[productId] == false and os.clock() - (failedAt[productId] or 0) >= RobuxPrice.RETRY_AFTER then
		known[productId] = nil
	end
end

-- A player asked again (tapped a pack whose price failed): the failure is forgotten now, so the
-- next get really asks Roblox again.
function RobuxPrice.forget(productId: number)
	if known[productId] == false then
		known[productId] = nil
	end
end

-- What a price button shows for a known answer: the number, or N/A (then the button is off).
function RobuxPrice.text(price: number?): string
	return if price then tostring(price) else "N/A"
end

-- Calls back with the price (nil when Roblox never answered); at once if it is already known.
function RobuxPrice.get(productId: number, callback: (number?) -> (), pass: boolean?)
	-- (V9-0i: a game pass too; its answers are kept under the negative id, apart from products.)
	local infoType = if pass then Enum.InfoType.GamePass else Enum.InfoType.Product
	local askId = productId
	if pass then
		productId = -productId
	end
	forgetStale(productId)
	local have = known[productId]
	if have ~= nil then
		callback(if have == false then nil else have)
		return
	end
	local list = waiting[productId]
	if list then
		table.insert(list, callback)
		return
	end
	waiting[productId] = { callback }
	task.spawn(function()
		local price: number | false = false
		for try = 1, TRIES do
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfoAsync(askId, infoType)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				price = info.PriceInRobux
				break
			end
			if try < TRIES then
				task.wait(2 ^ try)
			end
		end
		known[productId] = price
		if price == false then
			failedAt[productId] = os.clock()
		end
		local callbacks = waiting[productId] or {}
		waiting[productId] = nil
		for _, cb in callbacks do
			task.spawn(cb, if price == false then nil else price)
		end
	end)
end

-- V9-0i: a game pass's price (Roblox's own, as for products).
function RobuxPrice.getPass(passId: number, callback: (number?) -> ())
	RobuxPrice.get(passId, callback, true)
end

-- The price if Roblox has answered, else nil; `asked` says whether it has (false: still asking).
function RobuxPrice.peek(productId: number): (number?, boolean)
	forgetStale(productId)
	local have = known[productId]
	if have == nil then
		return nil, false
	end
	return if have == false then nil else have, true
end

return RobuxPrice
