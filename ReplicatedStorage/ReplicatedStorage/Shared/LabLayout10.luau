--!strict
-- LAB 10/10 (owner, 26 Nov 2026: "Hele labbet skal tages fra 2/10 til 10/10, ikke vær bange for at ændre ALT";
-- docs/LAB10.md). One table for where everything in a player's lab stands under Config.LAB_V10, in
-- lab studs from the spawn (x across, -z ahead/north). Every builder asks here; with LAB_V10 off
-- (or an id missing) it keeps its own spot, so false brings back today's lab.
--
--   CRASH TEST LAB (top view, spawn at 0,0 facing north)
--     north  (z -115..-60):  frog . shark tank . [boards] SPIDER WEB [boards] . plant . fan
--     west   (x -80..-30):   the DROP TOWER (stairs, bridge, slide, sky deck: unchanged spot)
--     centre (0,-28):        the TEST FLOOR (dummies on its ring), the BIG RED BUTTON at its north edge
--     east   (x 40..95):     SMASH YARD: wrecking ball, boxing ring, stretch machine, chicken pen
--     test floor edges:      the portal (west) and the MAPS board (east), facing the spawn
--     south-west:            LAUNCH RANGE: rocket, slingshot, mole, washer, compressor
--     south-east:            CRASH TRACK: the three launch pads into the crash wall, car bays in front of it
--     south, outside a gate: the weapon range building

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local LabLayout10 = {}

LabLayout10.on = Config.LAB_V10 == true

-- The test floor: its middle and radius (the dummies stand on its rim).
LabLayout10.TEST_FLOOR = Vector2.new(0, -28)
LabLayout10.TEST_RADIUS = 21 -- (R2: a bigger arena, the heart of the lab)
LabLayout10.BUTTON = Vector2.new(0, -52)
LabLayout10.SPAWN_RADIUS = 7
-- The compound: the lab floor's edge (Lab: LabFloor x -96..96, z -113..85) with a wall round it.
LabLayout10.WALL = { minX = -97, maxX = 97, minZ = -115, maxZ = 87 }
-- Gates in the wall: { side, at (along the side), width }.
LabLayout10.GATES = {
	{ side = "S", at = 0, width = 18 }, -- to the weapon range
	{ side = "W", at = 30, width = 14 },
	{ side = "E", at = 30, width = 14 },
}

-- Moves (studs, lab space) for things built from a whole origin (the builder is handed origin + move).
LabLayout10.MOVES = {
	Lava = Vector3.new(186, 0, -23), -- the boxing ring (and the pool under it) into the smash yard
	-- (The portal and the MAPS board keep their spots on the test floor's west and east edge: both face the
	-- spawn from there, and a move without a turn would face them away.)
	ShootingRange = Vector3.new(0, 0, -40), -- just outside the south gate
}

-- Creatures and yard machines (LabCreatures.SPOTS by id): their new middle.
LabLayout10.CREATURES = {
	Spider = Vector2.new(0, -86), -- the web is the backdrop behind the test floor and the button
	Whale = Vector2.new(-65, -97), -- the shark tank
	Frog = Vector2.new(-93, -65),
	Plant = Vector2.new(78, -84),
	Chicken = Vector2.new(84, -18),
	Washer = Vector2.new(-62, 51),
	Vacuum = Vector2.new(-40, 50), -- (the COMPRESSOR stands on the vacuum's spot)
	Mole = Vector2.new(-88, 54),
	Slingshot = Vector2.new(-63, 17),
}

-- Cars: the middle of each car's bay (VehicleService), in front of the crash wall.
LabLayout10.CARS = {
	Car = Vector2.new(47, 42),
	Truck = Vector2.new(64, 41),
	MuscleCar = Vector2.new(84, 42),
}

-- Bought lab things (MapShopService).
LabLayout10.TRAMPOLINE = Vector2.new(-22, 66) -- (R2: off the south walkway, in the launch range)

-- The stretch machine (Playground's ramp spot) in the smash yard.
LabLayout10.STRETCH = Vector2.new(50, -15)

-- R2: each zone on its own coloured floor pad (lab space rectangles: min, max, colour), with hazard corners.
LabLayout10.ZONE_PADS = {
	{ name = "TowerZone", min = Vector2.new(-94, -80), max = Vector2.new(-26, -2), color = Color3.fromRGB(226, 196, 150) },
	{ name = "CreatureWing", min = Vector2.new(-94, -112), max = Vector2.new(94, -84), color = Color3.fromRGB(150, 196, 176) },
	{ name = "SmashYard", min = Vector2.new(36, -66), max = Vector2.new(94, -4), color = Color3.fromRGB(232, 168, 124) },
	{ name = "LaunchRange", min = Vector2.new(-94, 6), max = Vector2.new(-30, 72), color = Color3.fromRGB(160, 180, 214) },
	{ name = "CrashTrack", min = Vector2.new(10, 30), max = Vector2.new(94, 74), color = Color3.fromRGB(92, 94, 104) },
}
-- R2: car bay lines on the crash track (x of each line; from z1 to z2).
LabLayout10.BAY_LINES = { x = { 38, 56, 73, 94 }, z1 = 32, z2 = 53 }

-- LAB TARGET (owner, 26 Nov 2026; docs/LAB_TARGET.md): Config.LAB_PARK, the realistic park look over the same spots:
-- grass plots round every machine in a light concrete field, a raised spawn plaza with 4 boards, a railway round it all.
LabLayout10.PARK = LabLayout10.on and Config.LAB_PARK == true
if LabLayout10.PARK then
	LabLayout10.TEST_FLOOR = Vector2.new(0, -36) -- (clear of the plaza's stair)
	LabLayout10.BUTTON = Vector2.new(0, -62)
end
LabLayout10.PLAZA = { min = Vector2.new(-30, -6), max = Vector2.new(30, 16), height = 1.4, stairWidth = 24, stairRun = 7 }
LabLayout10.RAIL = { minX = -106, maxX = 106, minZ = -124, maxZ = 146 }

-- LabDress roles that stay (everything else of the old dressing is hidden: scattered props).
LabLayout10.DRESS_KEEP = { Rocket = true }

-- Benches: round the test floor, facing it.
LabLayout10.BENCHES = {
	Vector2.new(-24, -14),
	Vector2.new(24, -14),
	Vector2.new(-27, -36),
	Vector2.new(27, -36),
}

-- The look (docs/LAB10.md, max 6 colours).
LabLayout10.COLORS = {
	concrete = Color3.fromRGB(230, 226, 216),
	concreteDark = Color3.fromRGB(150, 150, 158),
	yellow = Color3.fromRGB(255, 200, 40),
	black = Color3.fromRGB(30, 30, 34),
	orange = Color3.fromRGB(255, 120, 40),
	white = Color3.fromRGB(245, 245, 245),
	teal = Color3.fromRGB(60, 190, 200),
}

function LabLayout10.move(id: string): Vector3
	if not LabLayout10.on then
		return Vector3.zero
	end
	return LabLayout10.MOVES[id] or Vector3.zero
end

-- A creature's or car's new middle, or nil (keep its own).
function LabLayout10.creature(id: string): Vector2?
	return if LabLayout10.on then LabLayout10.CREATURES[id] else nil
end

function LabLayout10.car(kind: string): Vector2?
	return if LabLayout10.on then LabLayout10.CARS[kind] else nil
end

-- (F76) The yaw of a car's bay, when its bay is turned (the herringbone entrance row); nil = the builder's own.
function LabLayout10.carYaw(kind: string): number?
	local t = (LabLayout10 :: any).CAR_YAW
	return if LabLayout10.on and t then t[kind] else nil
end

-- (GO NOW: THE MAP, Config.LAB_OWNERMAP: every spot here 3.2 times further from the spawn, like Config.LAB_SPREAD; sizes stay.)
if Config.LAB_OWNERMAP then
	local K = (function(): number -- (M4: the compact plan's K, 1.3; was 3.2)
		local ok, P = pcall(function() return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any end)
		return if ok and P and P.K then P.K else 3.2
	end)()
	LabLayout10.CREATURES.Spider = Vector2.new(70, -70) -- (the plan: on its own plot by the fenced pen, not on the leaderboard plaza; x3.2 below)
	LabLayout10.CREATURES.Whale = Vector2.new(-30, -95) -- (the shark tank: in the glass aquarium of the north row)
	LabLayout10.CARS.MuscleCar = Vector2.new(-62, -70) -- (the bays of the plan, west to east: the tank, the monster truck, the blue car)
	LabLayout10.CARS.Truck = Vector2.new(-50, -70)
	LabLayout10.CARS.Car = Vector2.new(-38, -70)
	LabLayout10.TRAMPOLINE = Vector2.new(45, 80) -- (the raised trampoline, south-east of the tower)
	LabLayout10.STRETCH = Vector2.new(64, 62) -- (the stretch machine beside the gyro cage)
	local function v2(v: Vector2): Vector2
		return v * K
	end
	LabLayout10.TEST_FLOOR = v2(LabLayout10.TEST_FLOOR)
	LabLayout10.BUTTON = v2(LabLayout10.BUTTON)
	LabLayout10.STRETCH = v2(LabLayout10.STRETCH)
	LabLayout10.TRAMPOLINE = v2(LabLayout10.TRAMPOLINE)
	for k, v in LabLayout10.MOVES do
		LabLayout10.MOVES[k] = Vector3.new(v.X * K, v.Y, v.Z * K)
	end
	for _, t in { LabLayout10.CREATURES, LabLayout10.CARS } do
		for k, v in t do
			t[k] = v * K
		end
	end
	for i, v in LabLayout10.BENCHES do
		LabLayout10.BENCHES[i] = v * K
	end
	for _, z in LabLayout10.ZONE_PADS do
		z.min, z.max = z.min * K, z.max * K
	end
	for _, t in { LabLayout10.WALL, LabLayout10.RAIL } do
		for k, v in t do
			t[k] = v * K
		end
	end
	LabLayout10.PLAZA.min, LabLayout10.PLAZA.max = LabLayout10.PLAZA.min * K, LabLayout10.PLAZA.max * K
	for i, v in LabLayout10.BAY_LINES.x do
		LabLayout10.BAY_LINES.x[i] = v * K
	end
	LabLayout10.BAY_LINES.z1, LabLayout10.BAY_LINES.z2 = LabLayout10.BAY_LINES.z1 * K, LabLayout10.BAY_LINES.z2 * K
	for _, g in LabLayout10.GATES do
		g.at *= K
	end
	-- (the boxing ring: buildLava keeps its own spot (-111, -28) unscaled; this moves it to the plan's (-35, -40) x 3.2)
	LabLayout10.MOVES.Lava = Vector3.new(-35 * K + 111, 0, -40 * K + 28)
	-- (map round 2: the 3-near ragdolls walk about on the raised plaza by the spawn)
	LabLayout10.TEST_FLOOR = Vector2.new(-30, -310) -- (map round 3: the spawn plaza of OwnerMapPlan)
	-- (Map round 3, P3: every code machine on its OwnerMapPlan spot, in lab-space studs; these come after the x3.2 above.)
	local V = Vector2.new
	LabLayout10.CREATURES.Spider = V(330, -220) -- SpiderPen
	LabLayout10.CREATURES.Whale = V(-230, -300) -- the shark tank in the Aquarium
	LabLayout10.CREATURES.Washer = V(335, -30)
	LabLayout10.CREATURES.Vacuum = V(150, -30) -- the Press (compressor)
	LabLayout10.CREATURES.Mole = V(280, 208)
	LabLayout10.CREATURES.Slingshot = V(318, 104) -- by the archery target, facing it
	LabLayout10.CREATURES.Frog = V(-90, 300) -- by the duck pond
	LabLayout10.CREATURES.Plant = V(30, 300) -- in the gazebo garden
	LabLayout10.CREATURES.Chicken = V(-30, 210) -- on the picnic lawn
	LabLayout10.CARS.MuscleCar = V(-394, -95) -- the bays: tank, monster truck, blue car
	LabLayout10.CARS.Truck = V(-370, -95)
	LabLayout10.CARS.Car = V(-346, -95)
	LabLayout10.CARS.Bike = V(-235, 95) -- the BikeRack
	LabLayout10.TRAMPOLINE = V(30, 90)
	LabLayout10.STRETCH = V(245, -48)
	LabLayout10.MOVES.Lava = Vector3.new(-215 + 111, 0, -85 + 28) -- the boxing ring at (-215, -85)
	LabLayout10.MOVES.ShootingRange = Vector3.new(150, 0, 151) -- the weapon range in the Danger Zone at (150, 305) (its own spot is (0, 154))
	-- MAP ROUND 4 (OVERVIEW M4, the compact plan, Plan.K = 1.3): every code machine, creature and car on its compact
	-- OwnerMapPlan spot (lab-space studs), read from Plan.ITEMS so a plan change moves them too.
	local okPlan, Plan = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
	end)
	if okPlan and Plan and Plan.K and Plan.K < 2 then
		local function item(id: string, dx: number?, dz: number?): Vector2?
			local it = Plan.ITEMS[id]
			return if it then it.at + Vector2.new(dx or 0, dz or 0) else nil
		end
		local function set(t: { [string]: any }, key: string, v: Vector2?)
			if v then
				t[key] = v
			end
		end
		local C = LabLayout10.CREATURES
		set(C, "Spider", item("SpiderPen"))
		set(C, "Whale", item("Aquarium"))
		set(C, "Washer", item("Washer"))
		set(C, "Vacuum", item("Press")) -- (the compressor stands on the press)
		set(C, "Mole", item("Mole"))
		set(C, "Slingshot", item("Archery", 0, 9)) -- (beside the target, off its line)
		set(C, "Frog", item("DuckPond", 14, 0))
		C.Plant = Vector2.new(-120, -140) -- (the open spot between the cave and the aquarium; no garden in the compact plan)
		set(C, "Chicken", item("ChickenCoop") or item("PicnicGrill", 22, 0)) -- (F88: its own coop in the south, away from the spawn)
		local bays = item("CarBays")
		if bays then
			LabLayout10.CARS.MuscleCar = bays + Vector2.new(-14.6, 0) -- the bays: tank, monster truck, blue car
			LabLayout10.CARS.Truck = bays
			LabLayout10.CARS.Car = bays + Vector2.new(14.6, 0)
		end
		set(LabLayout10.CARS, "Bike", item("BikeRack", 16, 0)) -- (F75: the motorbike's bay BESIDE the rack, never in it)
		LabLayout10.TRAMPOLINE = item("Trampoline") or LabLayout10.TRAMPOLINE
		LabLayout10.STRETCH = item("StretchMachine") or LabLayout10.STRETCH
		local ring = item("BoxingRing")
		if ring then
			LabLayout10.MOVES.Lava = Vector3.new(ring.X + 111, 0, ring.Y + 28) -- (buildLava's own spot is (-111, -28))
		end
		local sp = item("Spawn")
		if sp then
			LabLayout10.TEST_FLOOR = sp -- (the 3 near walk about on the spawn plaza)
			LabLayout10.BUTTON = sp + Vector2.new(0, -14)
		end
		-- F76 (Config.ENTRANCE_ROW): THE VEHICLE ROW by the spawn, north of the CrossN walkway and east of the spine: bays
		-- side by side going east, each turned 45 degrees (a herringbone) so every vehicle shows its nose to the walkway as you
		-- come down from the spawn. Each bay is as wide as its vehicle (+1.5); the paid cars move here from the crash yard
		-- (the CarBays stay painted, as parking). Bays without a model yet show a SOON plaque (never free by mistake).
		local row = item("EntranceVehicles")
		if row and (Config :: any).ENTRANCE_ROW then
			local plan = Plan.ITEMS.EntranceVehicles
			local spec = {
				{ id = "Bicycle", label = "BICYCLE", w = 3 },
				{ id = "Car", label = "SILVIA", w = 6.4 },
				{ id = "Truck", label = "FORD TRUCK", w = 8.4 },
				{ id = "MuscleCar", label = "PANZER", w = if (Config :: any).PANZER_BAY_FIT then 13.5 else 11 }, -- (PANZER_BAY_FIT: the tank is 12.8 wide; in an 11 bay its home was pushed into the truck and it rode up on it, tilted 13 degrees)
				{ id = "GoKart", label = "GO-KART", w = 5 },
				{ id = "Police", label = "POLICE CAR", w = 7 },
				{ id = "MonsterTruck", label = "MONSTER TRUCK", w = 10 },
				{ id = "Bulldozer", label = "BULLDOZER", w = 9 },
				{ id = "FireTruck", label = "FIRE TRUCK", w = 8.5 },
			}
			local s45 = math.sin(math.rad(45))
			-- (FIXES_28NOV 7, Config.PARKING_STRAIGHT, the owner's screenshot: the 45-degree bays overlapped each other, so the
			-- home check pushed 7 vehicles off their bays, and the plaques stood in front of the neighbours. Now STRAIGHT bays,
			-- left to right, each as wide as its vehicle + 2.5, every vehicle centred in its own bay with its nose to the walkway.)
			local straight = (Config :: any).PARKING_STRAIGHT == true
			local x = row.X - plan.size.X / 2 + 4 + (if straight then 12 + spec[1].w / 2 else 0) -- (straight: start past the spawn statue that stands at the row's west end)
			local bays = {}
			for i, b in spec do
				if i > 1 then
					x += if straight then (spec[i - 1].w / 2) + (b.w / 2) + 3.5 else ((spec[i - 1].w / 2) + (b.w / 2) + 1.5) / s45
				end
				table.insert(bays, { id = b.id, label = b.label, w = b.w, at = Vector2.new(x, row.Y) })
			end
			LabLayout10.ENTRANCE_ROW = bays
			LabLayout10.ENTRANCE_STRAIGHT = straight
			LabLayout10.ENTRANCE_DEPTH = plan.size.Y
			LabLayout10.ENTRANCE_YAW = if straight then math.pi else math.rad(135) -- (the noses point to the walkway)
			for _, b in bays do
				if (straight and b.id == "Bicycle") or b.id == "Car" or b.id == "Truck" or b.id == "MuscleCar" or ((Config :: any).NEW_VEHICLES and (b.id == "GoKart" or b.id == "Police" or b.id == "MonsterTruck" or b.id == "Bulldozer" or b.id == "FireTruck")) then
					LabLayout10.CARS[b.id] = b.at
					LabLayout10.CAR_YAW = LabLayout10.CAR_YAW or {}
					LabLayout10.CAR_YAW[b.id] = LabLayout10.ENTRANCE_YAW
				end
			end
		end
		-- (F76: the free bicycle on its own stand by the tower square, the plan's BikeStand2)
		if not (LabLayout10.ENTRANCE_STRAIGHT and LabLayout10.CARS.Bicycle) then
			set(LabLayout10.CARS, "Bicycle", item("BikeStand2"))
		end
		-- (row 14: 3 wheelchairs in a neat row west of the boxing ring, 5 studs apart, clear of the mole and the walkways)
		set(LabLayout10.CARS, "Wheelchair", item("BoxingRing", -28, -6))
		set(LabLayout10.CARS, "Wheelchair2", item("BoxingRing", -28, -1))
		set(LabLayout10.CARS, "Wheelchair3", item("BoxingRing", -28, 4))
		-- The weapon range is not in the compact plan: it stands just outside the south edge (its own spot is (0, 154)).
		LabLayout10.MOVES.ShootingRange = Vector3.new(150, 0, 255 - 154)
	end
end

return LabLayout10
