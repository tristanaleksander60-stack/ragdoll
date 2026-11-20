--!strict
-- Release 0.20.0: what each Shop.OFFERS item gives (the ids live in Shop.OFFERS; this is the
-- meaning). Pure: the server's OfferService applies it, the client's catalog reads the PassToys
-- attribute it writes, T68 checks it.
--   toys        shelves (Toys categories) a pass unlocks for as long as it is owned ("*" = all);
--               checked every join with Roblox, never saved (a refund takes it away)
--   doubleBolts the "DoubleBolts" attribute EconomyService reads
--   vipLab      the "VipLab" attribute: more visitor ragdolls in your lab (VisitorService)
--   labControls the "LabControls" attribute: the lab's BIG RED BUTTON every LAB_CONTROLS_GAP s
--   eventsPass  the "EventsPass" attribute: server events start free (EventService, one per
--               Config.EVENTS_PASS_GAP s)
--   bolts/weapon a developer product's one-off grant (OfferService.deliver, once per purchase id)

local Shop = require(script.Parent:WaitForChild("Shop"))

local Offers = {}

export type Grant = {
	toys: { string }?,
	doubleBolts: boolean?,
	vipLab: boolean?,
	eventsPass: boolean?,
	labControls: boolean?,
	bolts: number?,
	weapon: string?,
}

Offers.GRANTS = table.freeze({
	EntryPack = table.freeze({ bolts = 300, weapon = "AK" }), -- (AK = the Rattler)
	AllMelee = table.freeze({ toys = { "Melee" } }),
	AllExplosives = table.freeze({ toys = { "Explosives" } }),
	AllGuns = table.freeze({ toys = { "Guns" } }),
	LabControls = table.freeze({ labControls = true }),
	DoubleBolts = table.freeze({ doubleBolts = true }),
	VipLab = table.freeze({ vipLab = true }),
	EventsPass = table.freeze({ eventsPass = true }),
	Everything = table.freeze({ toys = { "*" }, doubleBolts = true, vipLab = true, eventsPass = true, labControls = true }),
	-- V6-7 map items: their effects live in MapShopService (it reads Offer_<key> or the TRY).
	RainbowTrail = table.freeze({}),
	FireTrail = table.freeze({}),
	CrashSuit = table.freeze({}),
	GoldDummies = table.freeze({}),
	RobotDog = table.freeze({}),
	Parrot = table.freeze({}),
	MegaTrampoline = table.freeze({}),
	GiantFan = table.freeze({}),
	SpiderDeluxe = table.freeze({}),
	BoltCrate = table.freeze({ bolts = 500 }),
} :: { [string]: Grant })

Offers.byKey = {} :: { [string]: any }
for _, offer in Shop.OFFERS do
	Offers.byKey[offer.key] = offer
end

-- The effects of a set of owned passes, as the attributes the rest of the game reads.
export type Effects = { PassToys: string?, DoubleBolts: boolean?, VipLab: boolean?, EventsPass: boolean?, LabControls: boolean? }
function Offers.effectsOf(ownedKeys: { [string]: boolean }): Effects
	local shelves: { [string]: boolean } = {}
	local all = false
	local e: Effects = {}
	for key, has in ownedKeys do
		local g = Offers.GRANTS[key]
		local offer = Offers.byKey[key]
		if has and g and offer and offer.kind == "pass" then
			local shelfList: { string } = g.toys or {}
			for _, shelf in shelfList do
				if shelf == "*" then
					all = true
				else
					shelves[shelf] = true
				end
			end
			e.DoubleBolts = e.DoubleBolts or g.doubleBolts or nil
			e.VipLab = e.VipLab or g.vipLab or nil
			e.EventsPass = e.EventsPass or g.eventsPass or nil
			e.LabControls = e.LabControls or g.labControls or nil
		end
	end
	if all then
		e.PassToys = "*"
	elseif next(shelves) then
		local list = {}
		for shelf in shelves do
			table.insert(list, shelf)
		end
		table.sort(list)
		e.PassToys = "," .. table.concat(list, ",") .. ","
	end
	return e
end

-- Whether the PassToys attribute covers a toy's shelf.
function Offers.covers(passToys: unknown, category: string?): boolean
	if type(passToys) ~= "string" or category == nil then
		return false
	end
	return passToys == "*" or string.find(passToys, "," .. category .. ",", 1, true) ~= nil
end

return Offers
