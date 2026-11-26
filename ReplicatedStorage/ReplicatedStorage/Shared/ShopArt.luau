--!strict
-- V9-0i (owner, 21 Nov 2026: "fix all the icons in the shop so they match the right things and make the
-- whole shop 3D, interactive and beautiful, because people should spend money there"): what the shop
-- shows for each thing it sells. Pure: Client/ShopV9 builds the cards from it, T164 checks it.
--   items(): every sold thing (Shop.PASSES, Shop.OFFERS, Events.list) as one list, each with its tab,
--            its own picture (DrawnIcons), 2-3 "what you get" lines, a rarity by price and the 3D
--            showcase it turns in (SHOW; nil: the picture, gently moving).
-- Nothing here is typed in as a price: the card asks Roblox (RobuxPrice); `robux` is only the planned
-- price, for the rarity frame.

local Shop = require(script.Parent:WaitForChild("Shop")) :: any
local Events = require(script.Parent:WaitForChild("Events")) :: any
local Offers = require(script.Parent:WaitForChild("Offers")) :: any
local Config = require(script.Parent:WaitForChild("Config")) :: any
local Toys = require(script.Parent:WaitForChild("Toys")) :: any

local ShopArt = {}

ShopArt.TABS = table.freeze({ "FEATURED", "PASSES", "ITEMS", "EVENTS", "BOLTS" })

export type Kind = "pass" | "offer" | "event" | "weapon"
export type Item = {
	key: string, -- Shop pass key, Shop.OFFERS key, event id or "Weapon_<toy id>"
	toy: string?, -- a weapon card's toy id
	kind: Kind,
	product: boolean, -- a developer product (bought again and again), not a pass
	id: number, -- the pass or product id (0: not on sale)
	name: string,
	line: string, -- the short line on the card
	bullets: { string }, -- what you get (the detail view)
	picture: string, -- DrawnIcons name
	tab: string,
	robux: number, -- planned price (the rarity frame only)
	color: string?, -- its own colour (passes, events)
}

-- Each thing's own picture: art\shop\<key>.png uploaded as shop_<key>, GOD MODE's drawn god, an
-- event's card picture.
function ShopArt.pictureOf(kind: Kind, key: string): string
	if kind == "event" then
		return "event_" .. key
	elseif key == "God" then
		return "god"
	elseif key == "Ultra" then
		return "tool_Nuke" -- (24 Nov 2026, owner: a nuke, not the minigun)
	end
	return "shop_" .. key
end

-- The 3D showcase each one turns in on its card (Client/ShopShowcase builds it). nil: the picture.
--   weapons: real weapon models fanned out; dummy: the mannequin in a colour; model: a replicated
--   prop (ReplicatedStorage.ShopModels, Server ShopModels); extra: a code-built touch.
ShopArt.LIVE_3D = false -- (24 Nov 2026, owner: the shop is flat pictures, the 3D was load for nothing)
ShopArt.SHOW = table.freeze({
	EntryPack = { model = "Crate", weapons = { "AK" } },
	AllMelee = { weapons = { "Katana", "Bat", "Axe" } },
	AllExplosives = { weapons = { "Grenade", "C4", "RPG" } },
	AllGuns = { weapons = { "AK", "Deagle", "Shotgun" } },
	LabControls = { model = "BigButton" },
	VipLab = { dummy = "#E9ECF2", count = 3 },
	Everything = { weapons = { "Minigun", "Katana", "RPG" }, extra = "crown" },
	RainbowTrail = { dummy = "#E9ECF2", extra = "rainbow" },
	FireTrail = { dummy = "#E9ECF2", extra = "flames" },
	CrashSuit = { dummy = "#FFC93C", extra = "suit" },
	GoldDummies = { dummy = "#E7B53B", count = 2, gold = true },
	RobotDog = { model = "PetRobotDog" },
	Parrot = { model = "PetParrot" },
	MegaTrampoline = { model = "Trampoline" },
	GiantFan = { model = "BigFan" },
	SpiderDeluxe = { model = "MSpider", gold = true },
	BoltCrate = { model = "Crate" },
	Ultra = { weapons = { "Nuke" }, extra = "glow" },
	VIP = { dummy = "#E9ECF2", extra = "crown" },
	God = { dummy = "#FFE38A", gold = true, extra = "beam" },
})
ShopArt.MODELS = table.freeze({ "Crate", "BigButton", "PetRobotDog", "PetParrot", "Trampoline", "BigFan", "MSpider" })

-- FEATURED: the hero first (BEST VALUE), then a hand-picked row.
ShopArt.HERO = "Everything"
-- (NOW 8, 26 Nov 2026: a few strong, cheaper picks first instead of a wall of big passes.)
ShopArt.FEATURED = if Config.SHOP_CHEAP_FIRST
	then table.freeze({ "RainbowTrail", "AllMelee", "Ultra", "RobotDog", "AllGuns", "VIP" })
	else table.freeze({ "God", "Ultra", "VIP", "RobotDog", "GorillaRampage", "MegaTrampoline" })

-- The rarity frame by planned price (Robux).
export type Rarity = { name: string, color: Color3 }
function ShopArt.rarity(robux: number, kind: Kind?): Rarity
	if kind == "event" then
		return { name = "EVENT", color = Color3.fromRGB(255, 92, 140) }
	elseif robux >= 400 then
		return { name = "LEGENDARY", color = Color3.fromRGB(255, 196, 46) }
	elseif robux >= 179 then
		return { name = "EPIC", color = Color3.fromRGB(176, 104, 255) }
	elseif robux >= 99 then
		return { name = "RARE", color = Color3.fromRGB(70, 160, 255) }
	end
	return { name = "COMMON", color = Color3.fromRGB(64, 205, 160) }
end

local PASS_ROBUX = { Ultra = 249, VIP = 149, God = 199 }

local function offerBullets(o: any): { string }
	local out = { o.gives }
	local grant = Offers.GRANTS and Offers.GRANTS[o.key]
	if o.pitch then
		table.insert(out, o.pitch)
	end
	if o.kind == "pass" then
		table.insert(out, "Yours for good, on every server")
	elseif grant and grant.bolts then
		table.insert(out, "Spend BOLTS on your next weapons")
	end
	return out
end

-- Every sold thing, in shop order.
function ShopArt.items(): { Item }
	local out: { Item } = {}
	for _, pass in Shop.PASSES do
		table.insert(out, {
			key = pass.key,
			kind = "pass",
			product = false,
			id = pass.id,
			name = pass.name,
			line = if pass.key == "God" and Config.GOD_FREE_BETA then "FREE during beta! Create life." else pass.blurb, -- (V9-0l)
			bullets = table.clone(pass.perks),
			picture = ShopArt.pictureOf("pass", pass.key),
			tab = "PASSES",
			robux = PASS_ROBUX[pass.key] or 199,
			color = pass.color,
		})
	end
	for _, o in Shop.OFFERS do
		if o.key == "LabControls" and not (Config :: any).BIG_BUTTON then
			continue -- (24 Nov 2026: the button it speeds up is gone: not sold)
		end
		table.insert(out, {
			key = o.key,
			kind = "offer",
			product = o.kind == "product",
			id = o.id,
			name = o.name,
			line = o.gives,
			bullets = offerBullets(o),
			picture = ShopArt.pictureOf("offer", o.key),
			tab = if o.kind == "product" then "BOLTS" elseif o.map then "ITEMS" else "PASSES",
			robux = o.robux or 99,
			color = nil,
		})
	end
	for _, e in Events.list do
		table.insert(out, {
			key = e.id,
			kind = "event",
			product = true,
			id = e.productId,
			name = e.name,
			line = e.blurb,
			bullets = { e.blurb, string.format("%d seconds of it where you are: your lab or the plaza", e.duration), "Your name on the banner for the whole server" }, -- (V9-0i review: what really happens)
			picture = ShopArt.pictureOf("event", e.id),
			tab = "EVENTS",
			robux = 49,
			color = e.color,
		})
	end
	-- (Owner, 26 Nov 2026: no BUY on the WEAPONS cards, so every weapon is sold here instead, in ITEMS:
	-- its price tier's product. The server picks the product again and refuses one nearly earned.)
	if Config.WEAPONS_NO_BUY then
		local sorted = table.clone(Toys.list)
		table.sort(sorted, function(a: any, b: any)
			return a.unlockAt < b.unlockAt
		end)
		for _, toy in sorted do
			local tier = Toys.priceTier(toy)
			if tier then
				table.insert(out, {
					key = "Weapon_" .. toy.id,
					toy = toy.id,
					kind = "weapon",
					product = true,
					id = (Shop.WEAPON_PRODUCTS[tier.key] or 0) :: number,
					name = string.upper(toy.label),
					line = "Yours now, no KOs needed",
					bullets = { "The " .. toy.label .. ", yours for good", "Goes straight onto your bar" },
					picture = "tool_" .. toy.id,
					tab = "ITEMS",
					robux = tier.robux,
					color = nil,
				})
			end
		end
	end
	return out
end

-- An item by key (passes, offers and events share no keys).
function ShopArt.byKey(key: string): Item?
	for _, item in ShopArt.items() do
		if item.key == key then
			return item
		end
	end
	return nil
end

return ShopArt
