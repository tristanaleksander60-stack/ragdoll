--!strict
-- Everything you can build with in the Workshop. Data only; Factory makes the instances.
--
-- Conventions
--   size      bounding box in studs in the part's own frame. Every size is whole studs so parts
--             line up on the 1-stud grid.
--   facesOut  machines, toys and logic stand on the surface they are placed on: their local +Y
--             points out of that surface and the rotate button turns them around it. Blocks keep
--             whatever rotation you give them.
--   input     reacts to signals (wired = it waits for a signal; unwired = it just runs)
--   output    sends signals along its wires
--   settings  values the Tune tool cycles through (index 1 is the default)

export type Category = "Blocks" | "Machines" | "Toys" | "Logic"

export type Item = {
	id: string,
	code: number, -- stable byte used in saves; never reuse or renumber
	label: string,
	category: Category,
	size: Vector3,
	color: Color3,
	paintable: boolean,
	facesOut: boolean,
	input: boolean,
	output: boolean,
	settings: { string }?,
	hint: string,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local items: { Item } = {}

local function add(item: Item)
	table.insert(items, table.freeze(item))
end

-- Blocks ------------------------------------------------------------------------------------
add({ id = "Block", code = 1, label = "Block", category = "Blocks", size = Vector3.new(2, 2, 2), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A 2x2 building block" })
add({ id = "Plate", code = 2, label = "Plate", category = "Blocks", size = Vector3.new(4, 1, 4), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A flat plate for floors and decks" })
add({ id = "Beam", code = 3, label = "Beam", category = "Blocks", size = Vector3.new(6, 1, 1), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A long thin beam" })
add({ id = "Plank", code = 4, label = "Plank", category = "Blocks", size = Vector3.new(6, 1, 2), color = rgb(205, 160, 105), paintable = true, facesOut = false, input = false, output = false, hint = "A wooden plank" })
add({ id = "Wall", code = 5, label = "Wall", category = "Blocks", size = Vector3.new(6, 4, 1), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A wall panel" })
add({ id = "Wedge", code = 6, label = "Wedge", category = "Blocks", size = Vector3.new(2, 2, 2), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A sloped block" })
add({ id = "Ramp", code = 7, label = "Ramp", category = "Blocks", size = Vector3.new(4, 2, 6), color = rgb(255, 205, 60), paintable = true, facesOut = false, input = false, output = false, hint = "A long ramp to launch things off" })
add({ id = "Ball", code = 8, label = "Ball", category = "Blocks", size = Vector3.new(2, 2, 2), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A ball" })
add({ id = "Cylinder", code = 9, label = "Cylinder", category = "Blocks", size = Vector3.new(2, 2, 2), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A short round post" })
-- (Round 3, M9: more to build with.)
add({ id = "BigBlock", code = 10, label = "Big Block", category = "Blocks", size = Vector3.new(4, 4, 4), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A big 4x4 block" })
add({ id = "Pillar", code = 11, label = "Pillar", category = "Blocks", size = Vector3.new(2, 8, 2), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A tall post for towers" })
add({ id = "Glass", code = 12, label = "Glass", category = "Blocks", size = Vector3.new(6, 4, 0.5), color = rgb(170, 215, 255), paintable = true, facesOut = false, input = false, output = false, hint = "A see-through pane" })
add({ id = "Corner", code = 13, label = "Corner", category = "Blocks", size = Vector3.new(2, 2, 2), color = rgb(230, 230, 235), paintable = true, facesOut = false, input = false, output = false, hint = "A corner slope for roofs" })

-- Machines ----------------------------------------------------------------------------------
add({ id = "Hinge", code = 20, label = "Hinge", category = "Machines", size = Vector3.new(2, 2, 2), color = rgb(150, 155, 170), paintable = false, facesOut = true, input = false, output = false, hint = "Whatever you build on top swings freely" })
add({ id = "Motor", code = 21, label = "Motor", category = "Machines", size = Vector3.new(2, 2, 2), color = rgb(80, 170, 255), paintable = false, facesOut = true, input = true, output = false, settings = { "Slow", "Fast", "Reverse" }, hint = "Spins whatever you build on top" })
add({ id = "Piston", code = 22, label = "Piston", category = "Machines", size = Vector3.new(2, 2, 2), color = rgb(255, 160, 50), paintable = false, facesOut = true, input = true, output = false, settings = { "Short", "Long" }, hint = "Pushes out and pulls back" })
add({ id = "Spring", code = 23, label = "Spring", category = "Machines", size = Vector3.new(2, 2, 2), color = rgb(120, 230, 140), paintable = false, facesOut = true, input = false, output = false, settings = { "Soft", "Strong" }, hint = "Pops up when you press Play" })
add({ id = "Wheel", code = 24, label = "Wheel", category = "Machines", size = Vector3.new(3, 2, 3), color = rgb(45, 45, 52), paintable = false, facesOut = true, input = true, output = false, settings = { "Forward", "Reverse", "Free" }, hint = "A driven wheel; put four on a plate" })
add({ id = "Thruster", code = 25, label = "Thruster", category = "Machines", size = Vector3.new(2, 2, 2), color = rgb(240, 110, 40), paintable = false, facesOut = true, input = true, output = false, settings = { "Low", "High" }, hint = "A rocket engine that pushes into what it sits on" })

-- Toys --------------------------------------------------------------------------------------
add({ id = "Trampoline", code = 40, label = "Trampoline", category = "Toys", size = Vector3.new(6, 1, 6), color = rgb(80, 170, 255), paintable = false, facesOut = true, input = false, output = false, hint = "Bounces dummies sky high" })
add({ id = "Conveyor", code = 41, label = "Conveyor", category = "Toys", size = Vector3.new(6, 1, 2), color = rgb(60, 60, 70), paintable = false, facesOut = true, input = true, output = false, settings = { "Slow", "Fast", "Reverse" }, hint = "Carries whatever lands on it" })
add({ id = "Bumper", code = 42, label = "Bumper", category = "Toys", size = Vector3.new(3, 3, 3), color = rgb(255, 90, 160), paintable = false, facesOut = true, input = false, output = false, hint = "Knocks back anything that touches it" })
add({ id = "Fan", code = 43, label = "Fan", category = "Toys", size = Vector3.new(4, 2, 4), color = rgb(170, 220, 255), paintable = false, facesOut = true, input = true, output = false, settings = { "Gentle", "Gale" }, hint = "Blows away from where it stands" })
add({ id = "Cannon", code = 44, label = "Cannon", category = "Toys", size = Vector3.new(2, 4, 2), color = rgb(70, 72, 82), paintable = false, facesOut = true, input = true, output = false, settings = { "Ball", "Bowling" }, hint = "Fires out of its barrel" })
add({ id = "Crate", code = 45, label = "TNT Crate", category = "Toys", size = Vector3.new(2, 2, 2), color = rgb(205, 45, 45), paintable = false, facesOut = true, input = true, output = false, hint = "Goes off on a signal or a hard hit" })
add({ id = "Seesaw", code = 46, label = "Seesaw", category = "Toys", size = Vector3.new(10, 3, 2), color = rgb(205, 160, 105), paintable = false, facesOut = true, input = false, output = false, hint = "Drop something on one end" })
add({ id = "Swing", code = 47, label = "Wrecking Ball", category = "Toys", size = Vector3.new(12, 12, 4), color = rgb(70, 72, 82), paintable = false, facesOut = true, input = false, output = false, hint = "Swings down when you press Play" })

-- Logic -------------------------------------------------------------------------------------
add({ id = "Button", code = 60, label = "Button", category = "Logic", size = Vector3.new(2, 1, 2), color = rgb(255, 70, 70), paintable = false, facesOut = true, input = false, output = true, hint = "Tap it while playing to send a signal" })
add({ id = "Timer", code = 61, label = "Timer", category = "Logic", size = Vector3.new(2, 1, 2), color = rgb(255, 205, 60), paintable = false, facesOut = true, input = false, output = true, settings = { "1 s", "2 s", "4 s" }, hint = "Sends a signal again and again" })
add({ id = "Sensor", code = 62, label = "Sensor", category = "Logic", size = Vector3.new(4, 1, 4), color = rgb(255, 205, 60), paintable = false, facesOut = true, input = false, output = true, hint = "Sends a signal when a dummy steps on it" })

local byId: { [string]: Item } = {}
local byCode: { [number]: Item } = {}
for _, item in items do
	assert(not byId[item.id], "duplicate id " .. item.id)
	assert(not byCode[item.code], "duplicate code " .. item.code)
	byId[item.id] = item
	byCode[item.code] = item
end

-- Paint colors (index stored in saves; append only).
local PALETTE: { Color3 } = {
	rgb(230, 230, 235), -- 1 white
	rgb(40, 40, 46), -- 2 black
	rgb(255, 90, 70), -- 3 red
	rgb(255, 160, 50), -- 4 orange
	rgb(255, 205, 60), -- 5 yellow
	rgb(120, 230, 140), -- 6 green
	rgb(80, 170, 255), -- 7 blue
	rgb(170, 110, 240), -- 8 purple
	rgb(255, 120, 190), -- 9 pink
	rgb(205, 160, 105), -- 10 wood
	rgb(150, 155, 170), -- 11 steel
	rgb(120, 220, 230), -- 12 cyan
}

return table.freeze({
	list = table.freeze(items),
	byId = table.freeze(byId),
	byCode = table.freeze(byCode),
	palette = table.freeze(PALETTE),
	categories = table.freeze({ "Blocks", "Machines", "Toys", "Logic" } :: { Category }),
	MAX_PARTS = 120, -- per build; keeps phones smooth
	MAX_WIRES = 60,
	GRID = 1,
	BUILD_RADIUS = 70, -- studs from the lab origin
	BUILD_HEIGHT = 60,
})
