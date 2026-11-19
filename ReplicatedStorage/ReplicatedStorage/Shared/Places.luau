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
	outdoor: boolean?, -- v3 phase B: an open-air map (terrain, sky, no ceiling) in the outdoor row
	row: number?, -- its place in the outdoor row (1..n)
	arrive: number?, -- an outdoor map's arrival pad, studs south of its middle (else by the south edge)
	image: string?, -- a capture of the place for its MAPS card (uploaded from art/maps)
}

local Places = {}

Places.ROOM_HEIGHT = 1600 -- studs above the lab's floor where the rooms stand (out of sight from it)
Places.ROOM_SPACING = 420 -- studs between rooms (further than the crowd's wake-up range)
Places.TRAVEL_GAP = 2 -- s between two trips (server-checked)
-- v3 phase B: the open-air maps stand in a row of their own, behind the rooms (+Z), further apart:
-- each is a few hundred studs of land, sea or site.
Places.OUTDOOR_Z = 1400 -- studs from the rooms' row
Places.OUTDOOR_SPACING = 1200 -- studs between two outdoor maps' middles

Places.list = table.freeze({
	{ id = "Lab", name = "My Lab", blurb = "Your own lab: your dummies, your machines.", slot = 0, size = Vector3.zero, crowd = 0, roles = {}, light = "Lab", color = "#7CC8FF", glyph = "🧪" },
	{ id = "Plaza", name = "The Plaza", blurb = "The square between the labs. The horde comes here.", slot = 0, size = Vector3.zero, crowd = 12, roles = { "Barista", "Office", "Tourist" }, light = "Lab", color = "#9AD66B", glyph = "⛲️" },
	{ id = "Arena", name = "Game Arena", blurb = "Red light, green light and Shoot 'em. Beat your best!", slot = 7, size = Vector3.new(120, 40, 140), crowd = 0, roles = {}, light = "Cool", color = "#F2C230", glyph = "🎮" },
	-- v3 phase B: open-air maps, in their own row (OutdoorMaps builds them).
	{ id = "Island", name = "Tropical Island", blurb = "Sand, palms, a cliff to dive off and a catapult.", slot = 101, size = Vector3.new(360, 80, 360), crowd = 6, roles = { "Tourist", "Traveler" }, light = "Lab", color = "#2EC4B6", glyph = "\u{1F3DD}\u{FE0F}", outdoor = true, row = 1, arrive = 110, image = "rbxassetid://73249753517996" },
	{ id = "City", name = "Downtown", blurb = "A big crossroads, towers, parked cars and buses.", slot = 102, size = Vector3.new(440, 120, 440), crowd = 10, roles = { "Office", "Tourist", "Guard" }, light = "Lab", color = "#8A9BB0", glyph = "\u{1F3D9}\u{FE0F}", outdoor = true, row = 2, arrive = 150, image = "rbxassetid://121412966164073" },
	{ id = "Site", name = "Building Site", blurb = "A crane, scaffolding, a pit and a half-built tower.", slot = 103, size = Vector3.new(320, 100, 320), crowd = 6, roles = { "Guard", "Office" }, light = "Lab", color = "#F2A33A", glyph = "\u{1F3D7}\u{FE0F}", outdoor = true, row = 3, arrive = 120, image = "rbxassetid://117598102089877" },
	{ id = "Farm", name = "Old Farm", blurb = "Barns, tractors, hay bales and grumpy bison.", slot = 104, size = Vector3.new(360, 90, 360), crowd = 6, roles = { "Tourist", "Chef" }, light = "Lab", color = "#C8553D", glyph = "\u{1F69C}", outdoor = true, row = 4, arrive = 150, image = "rbxassetid://94155941068741" },
	{ id = "Military", name = "Army Base", blurb = "Tanks, a firing range, an obstacle course and a helipad.", slot = 105, size = Vector3.new(340, 90, 340), crowd = 6, roles = { "Guard" }, light = "Lab", color = "#6B7A4B", glyph = "\u{1F396}\u{FE0F}", outdoor = true, row = 5, arrive = 140, image = "rbxassetid://128146376061336" },
} :: { Place })

Places.byId = {} :: { [string]: Place }
for _, place in Places.list do
	Places.byId[place.id] = place
end

local rooms, outdoors = 0, 0
for _, place in Places.list do
	if place.outdoor then
		outdoors += 1
	elseif place.slot > 0 then
		rooms += 1
	end
end
Places.ROOMS = rooms -- (the closed rooms' row; the outdoor maps are counted apart)
Places.OUTDOORS = outdoors

-- The middle of a room's floor (its top surface), from the plaza's middle. Ground places: nil.
function Places.floorCenter(labOrigin: Vector3, id: string): Vector3?
	local place = Places.byId[id]
	if not place or place.slot == 0 then
		return nil
	end
	if place.outdoor then
		local row = place.row or 1
		return labOrigin + Vector3.new((row - 1) * Places.OUTDOOR_SPACING - (outdoors - 1) * Places.OUTDOOR_SPACING / 2, Places.ROOM_HEIGHT, Places.OUTDOOR_Z)
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
