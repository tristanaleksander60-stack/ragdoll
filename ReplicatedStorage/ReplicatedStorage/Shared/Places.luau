--!strict
-- The places you can go (phase E; labs in round 2): your own lab, where you start, the plaza in the
-- middle of the labs, and indoor scenes full of people to crash out in. The labs and the plaza are
-- on the ground (slot 0); each room is closed and far above them (you never see one from another),
-- built by the server (WorldMaps) and lit by the client (ZoneLighting) while you are in it.
-- Other players' labs are not in this list: the MAPS window lists them from the players
-- (travel id "Lab:<plot>"). Shared so the MAPS window, the server's travel check and the tests
-- read the same list.

export type Place = {
	id: string,
	name: string,
	blurb: string,
	slot: number, -- 0: on the ground (your lab, the plaza); 1..n: rooms in a row high above it
	size: Vector3, -- inside, studs (rooms only)
	crowd: number, -- people living there
	roles: { string }, -- who they are (CrowdService dresses each role)
	light: string, -- ZoneLighting profile
	color: string, -- the card's colour
	glyph: string, -- its picture (a colour emoji, unique among places; T21 checks)
}

local Places = {}

Places.ROOM_HEIGHT = 1600 -- studs above the lab's floor where the rooms stand (out of sight from it)
Places.ROOM_SPACING = 420 -- studs between rooms (further than the crowd's wake-up range)
Places.TRAVEL_GAP = 2 -- s between two trips (server-checked)

Places.list = table.freeze({
	{ id = "Lab", name = "My Lab", blurb = "Your own lab: your dummies, your machines.", slot = 0, size = Vector3.zero, crowd = 0, roles = {}, light = "Lab", color = "#7CC8FF", glyph = "🧪" },
	{ id = "Plaza", name = "The Plaza", blurb = "The square between the labs. The horde comes here.", slot = 0, size = Vector3.zero, crowd = 12, roles = { "Barista", "Office", "Tourist" }, light = "Lab", color = "#9AD66B", glyph = "⛲️" },
	{ id = "Hangar", name = "Night Hangar", blurb = "A jet, crates and travellers at 2 AM.", slot = 1, size = Vector3.new(150, 44, 116), crowd = 8, roles = { "Traveler", "Guard", "Tourist" }, light = "Night", color = "#4F5BD5", glyph = "✈️" },
	{ id = "Cafe", name = "Coffee Bar", blurb = "Lattes, laptops and small tables.", slot = 2, size = Vector3.new(96, 28, 76), crowd = 9, roles = { "Barista", "Office", "Tourist" }, light = "Warm", color = "#B5763A", glyph = "☕️" },
	{ id = "Office", name = "Office", blurb = "Desks, a printer and a long Monday.", slot = 3, size = Vector3.new(104, 28, 84), crowd = 10, roles = { "Office", "Guard" }, light = "Cool", color = "#5C7A99", glyph = "💼" },
	{ id = "FoodCourt", name = "Food Court", blurb = "Burgers, pizza and a packed lunch rush.", slot = 4, size = Vector3.new(124, 30, 100), crowd = 12, roles = { "Chef", "Tourist", "Office" }, light = "Warm", color = "#F25A5A", glyph = "🍔" },
	{ id = "Market", name = "Supermarket", blurb = "Aisles, carts and the checkout queue.", slot = 5, size = Vector3.new(116, 28, 96), crowd = 10, roles = { "Cashier", "Guard", "Tourist" }, light = "Cool", color = "#25C773", glyph = "🧺" },
	{ id = "WhiteRoom", name = "White Room", blurb = "A giant empty test room. Go wild.", slot = 6, size = Vector3.new(150, 44, 150), crowd = 10, roles = { "Office", "Tourist", "Traveler", "Chef" }, light = "White", color = "#E6E6EE", glyph = "🔬" },
	{ id = "Metro", name = "Metro Station", blurb = "Platform 1. The 8:15 is late again.", slot = 8, size = Vector3.new(140, 30, 96), crowd = 10, roles = { "Office", "Traveler", "Tourist", "Guard" }, light = "Cool", color = "#3A7BD5", glyph = "🚇" },
	{ id = "Arena", name = "Game Arena", blurb = "Red light, green light and Shoot 'em. Beat your best!", slot = 7, size = Vector3.new(120, 40, 140), crowd = 0, roles = {}, light = "Cool", color = "#F2C230", glyph = "🎮" },
} :: { Place })

Places.byId = {} :: { [string]: Place }
for _, place in Places.list do
	Places.byId[place.id] = place
end

local rooms = 0
for _, place in Places.list do
	if place.slot > 0 then
		rooms += 1
	end
end
Places.ROOMS = rooms

-- The middle of a room's floor (its top surface), from the plaza's middle. Ground places: nil.
function Places.floorCenter(labOrigin: Vector3, id: string): Vector3?
	local place = Places.byId[id]
	if not place or place.slot == 0 then
		return nil
	end
	return labOrigin + Vector3.new((place.slot - 1) * Places.ROOM_SPACING - (rooms - 1) * Places.ROOM_SPACING / 2, Places.ROOM_HEIGHT, 0)
end

-- A travel id for someone's lab ("Lab:3"), and back.
function Places.labId(plot: number): string
	return "Lab:" .. plot
end
function Places.labPlot(id: unknown): number?
	if type(id) ~= "string" then
		return nil
	end
	local n = string.match(id, "^Lab:(%d+)$")
	return if n then tonumber(n) else nil
end

-- Ground places are where you walk between without a trip.
function Places.onGround(id: unknown): boolean
	if Places.labPlot(id) then
		return true
	end
	local place = type(id) == "string" and Places.byId[id] or nil
	return place ~= nil and place.slot == 0
end

return table.freeze(Places)
