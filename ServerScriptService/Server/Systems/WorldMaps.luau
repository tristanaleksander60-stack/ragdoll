--!strict
-- The places (phase E): closed rooms high above the lab, each a scene full of people to crash out
-- in (a night hangar, a coffee bar, an office, a food court, a supermarket, a giant white test
-- room). Built here at start-up, each with an arrival pad. Round 2 (N7): the props are real models
-- where the place has them (ServerStorage.N7Assets.Props through N7Models: Creator Store models with their
-- scripts stripped, kept with the pivot at the bottom centre and the front facing +Z); the built
-- stand-in stays for any that is missing. Travelling is asked for by the client (the MAPS window) and checked here:
-- a known place, not too often, standing on your feet. The people in each room are CrowdService's.
--
-- Parts are kept in budget for phones: anchored, no shadows from small props, a few lights per room.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Places = require(Shared:WaitForChild("Places"))
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local N7Models = require(Shared:WaitForChild("N7Models"))
local Metrics = require(script.Parent.Metrics)
local Lab = require(script.Parent.Lab)
local Finish = require(script.Parent.Finish)
local OutdoorMaps = require(script.Parent.OutdoorMaps)

local log = Log.new("Maps")

local WorldMaps = {}

local WALL = 4 -- wall and ceiling thickness (thick enough that a thrown body does not pass through)
local FLOOR = 8 -- the floor is thick: a body thrown down hard must never pass through it
local ARRIVE_BACK = 12 -- the arrival pad: studs in from the front wall

local origin = Vector3.zero
local folder: Folder? = nil
local lastTrip: { [Player]: number } = {}
local travelRemote: RemoteEvent? = nil

------------------------------------------------------------------------------------------------
-- Building blocks

local UP_X = CFrame.Angles(0, math.rad(90), 0) -- a cylinder lying along Z (its face towards Z)

local function hex(s: string): Color3
	return Color3.fromHex(s)
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	if material == Enum.Material.Metal then
		Finish.apply(p, "Painted") -- (plain metal: painted steel with chips and scratches)
	else
		p.Material = material or Enum.Material.SmoothPlastic
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = size.Magnitude > 14
	if props then
		for key, value in props do
			(p :: any)[key] = value
		end
	end
	p.Parent = parent
	return p
end

local function cylinder(parent: Instance, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	-- Roblox cylinders run along X: `cf` points X along the length.
	return part(parent, name, Vector3.new(length, diameter, diameter), cf, color, material, { Shape = Enum.PartType.Cylinder })
end

local function lamp(parent: Instance, at: CFrame, color: Color3, range: number, brightness: number, size: Vector3?)
	local bulb = part(parent, "Lamp", size or Vector3.new(4, 0.4, 4), at, color, Enum.Material.Neon, { CanCollide = false, CanQuery = false })
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = bulb
end

local function sign(parent: Instance, text: string, cf: CFrame, size: Vector3, back: Color3, fore: Color3)
	local board = part(parent, "Sign", size, cf, back, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = fore
	label.Text = text
	label.Parent = gui
	gui.Parent = board
	-- (Readable from behind too: a sign hanging over an aisle is seen from both ends.)
	local back = gui:Clone()
	back.Face = Enum.NormalId.Back
	back.Parent = board
end

-- A chair facing `facing` (a unit flat vector) with its seat at `at`.
local function chair(parent: Instance, at: Vector3, facing: Vector3, color: Color3)
	local cf = CFrame.lookAt(at, at + facing)
	part(parent, "Seat", Vector3.new(2.2, 0.4, 2.2), cf * CFrame.new(0, 1.6, 0), color)
	part(parent, "Back", Vector3.new(2.2, 2.4, 0.3), cf * CFrame.new(0, 3, 1), color)
	part(parent, "Legs", Vector3.new(1.6, 1.4, 1.6), cf * CFrame.new(0, 0.7, 0), color:Lerp(Color3.new(), 0.4))
end

local function roundTable(parent: Instance, at: Vector3, diameter: number, top: Color3, seats: number, seatColor: Color3)
	cylinder(parent, "TableTop", 0.4, diameter, CFrame.new(at + Vector3.new(0, 3.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), top)
	cylinder(parent, "TableLeg", 3.2, 0.6, CFrame.new(at + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	for i = 1, seats do
		local angle = (i / seats) * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		chair(parent, at + dir * (diameter / 2 + 1.6), -dir, seatColor)
	end
end

-- A real model from the place's props (N7), its bottom centre at `at`, its front facing `facing`,
-- scaled so its largest side is `size` (its kept size when nil). Nil when the place has none.
local function asset(parent: Instance, name: string, at: Vector3, facing: Vector3?, size: number?): Model?
	local model = N7Models.clone("Props", name)
	if not model then
		return nil
	end
	if size then
		local _, box = model:GetBoundingBox()
		local big = math.max(box.X, box.Y, box.Z)
		if big > 0 then
			model:ScaleTo(model:GetScale() * size / big)
		end
	end
	local dir = facing or Vector3.new(0, 0, 1)
	-- (The kept front faces +Z: CFrame.lookAt aims -Z, so aim it the other way.)
	model:PivotTo(CFrame.lookAt(at, at - dir))
	-- (Small props cast no shadow: the rooms' budget for phones. Big ones, a jet or a shelf, do.)
	local _, box = model:GetBoundingBox()
	local small = math.max(box.X, box.Y, box.Z) < 8
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false -- (props are scenery: nothing listens for touches on them)
			if small then
				d.CastShadow = false
			end
		end
	end
	model.Parent = parent
	return model
end
WorldMaps.assetForTest = asset

local function plant(parent: Instance, at: Vector3)
	if asset(parent, "Plant", at, nil, 5.5) then
		return
	end
	cylinder(parent, "Pot", 2.4, 2.4, CFrame.new(at + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 110, 70), Enum.Material.Slate)
	part(parent, "Leaves", Vector3.new(3.4, 3.4, 3.4), CFrame.new(at + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(70, 150, 70), Enum.Material.Grass, { Shape = Enum.PartType.Ball, CanCollide = false })
end

-- The room itself: floor (marked so the crowd knows where it may stand), walls, ceiling, a name
-- over the arrival pad and the pad. Returns the floor's middle (top surface).
local function shell(parent: Instance, place: Places.Place, centre: Vector3, floor: Color3, floorMat: Enum.Material, wall: Color3, wallMat: Enum.Material, ceiling: Color3)
	local size = place.size
	local floorPart = part(parent, "Floor", Vector3.new(size.X + WALL * 2, FLOOR, size.Z + WALL * 2), CFrame.new(centre - Vector3.new(0, FLOOR / 2, 0)), floor, floorMat)
	floorPart:SetAttribute("Floor", true)
	floorPart.CastShadow = false
	part(parent, "Ceiling", Vector3.new(size.X + WALL * 2, WALL, size.Z + WALL * 2), CFrame.new(centre + Vector3.new(0, size.Y + WALL / 2, 0)), ceiling, Enum.Material.SmoothPlastic)
	local h = size.Y / 2
	part(parent, "WallN", Vector3.new(size.X + WALL * 2, size.Y, WALL), CFrame.new(centre + Vector3.new(0, h, size.Z / 2 + WALL / 2)), wall, wallMat)
	part(parent, "WallS", Vector3.new(size.X + WALL * 2, size.Y, WALL), CFrame.new(centre + Vector3.new(0, h, -size.Z / 2 - WALL / 2)), wall, wallMat)
	part(parent, "WallE", Vector3.new(WALL, size.Y, size.Z), CFrame.new(centre + Vector3.new(size.X / 2 + WALL / 2, h, 0)), wall, wallMat)
	part(parent, "WallW", Vector3.new(WALL, size.Y, size.Z), CFrame.new(centre + Vector3.new(-size.X / 2 - WALL / 2, h, 0)), wall, wallMat)
	-- Arrival: by the south wall, looking into the room.
	local pad = part(parent, "Arrival", Vector3.new(8, 0.1, 8), CFrame.new(centre + Vector3.new(0, 0.05, -size.Z / 2 + ARRIVE_BACK)), hex(place.color), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false, Transparency = 0.45 })
	pad:SetAttribute("Arrival", place.id)
	-- (Its face looks into the room.)
	sign(parent, string.upper(place.name), CFrame.new(centre + Vector3.new(0, math.min(size.Y - 4, 16), -size.Z / 2 + 0.3)) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(30, 6, 0.4), hex(place.color), if place.id == "WhiteRoom" then Color3.fromRGB(60, 56, 90) else Color3.new(1, 1, 1))
	return centre
end

------------------------------------------------------------------------------------------------
-- The rooms

local BUILDERS: { [string]: (Instance, Places.Place, Vector3) -> () } = {}

BUILDERS.Cafe = function(m, place, c)
	local s = place.size
	shell(m, place, c, hex("#8A5A3C"), Enum.Material.WoodPlanks, hex("#F1E3CC"), Enum.Material.Plaster, hex("#EADBC3"))
	-- The counter along the back, an espresso machine, a cake case and the menu.
	local back = c + Vector3.new(0, 0, s.Z / 2 - 7)
	part(m, "Counter", Vector3.new(40, 4, 4), CFrame.new(back + Vector3.new(0, 2, 0)), hex("#3B2A20"), Enum.Material.Wood)
	part(m, "CounterTop", Vector3.new(41, 0.4, 4.6), CFrame.new(back + Vector3.new(0, 4.2, 0)), hex("#E8E2DA"), Enum.Material.Marble)
	if not asset(m, "Espresso", back + Vector3.new(-12, 4.4, 0.4), Vector3.new(0, 0, -1), 4.2) then
		part(m, "Espresso", Vector3.new(5, 3, 2.6), CFrame.new(back + Vector3.new(-12, 5.9, 0.4)), hex("#B8BCC4"), Enum.Material.Metal)
	end
	part(m, "CakeCase", Vector3.new(8, 2.6, 3), CFrame.new(back + Vector3.new(10, 5.7, 0)), hex("#CFE8F5"), Enum.Material.Glass, { Transparency = 0.4 })
	for i = -1, 1 do
		cylinder(m, "Cake", 1.2, 1.8, CFrame.new(back + Vector3.new(10 + i * 2.4, 5, 0)) * CFrame.Angles(0, 0, math.rad(90)), if i == 0 then hex("#F59AC0") else hex("#7A4A2C"))
	end
	sign(m, "COFFEE  \u{00B7}  TEA  \u{00B7}  CAKE", CFrame.new(c + Vector3.new(0, 14, s.Z / 2 - 0.3)), Vector3.new(30, 5, 0.3), hex("#2B211B"), hex("#F7E8C8"))
	-- Small tables in two rows, plants in the corners, lamps over the tables.
	for row = 0, 1 do
		for col = -2, 2 do
			if not (row == 0 and col == 0) then -- the walkway from the door
				local at = c + Vector3.new(col * 16, 0, -8 + row * 18)
				roundTable(m, at, 4, hex("#F4F1EA"), 2, hex("#C8743A"))
				lamp(m, CFrame.new(at + Vector3.new(0, s.Y - 4, 0)), hex("#FFD9A0"), 22, 1.2, Vector3.new(2, 1.2, 2))
			end
		end
	end
	for _, corner in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
		plant(m, c + Vector3.new(corner.X * (s.X / 2 - 3), 0, corner.Z * (s.Z / 2 - 3)))
	end
end

BUILDERS.Office = function(m, place, c)
	local s = place.size
	shell(m, place, c, hex("#5F6B7A"), Enum.Material.Fabric, hex("#E9ECF0"), Enum.Material.SmoothPlastic, hex("#F5F6F8"))
	-- Three rows of desks with screens and chairs.
	for row = 0, 2 do
		for col = -2, 2 do
			local at = c + Vector3.new(col * 17, 0, -6 + row * 14)
			-- (A real desk with its screen, N7: the screen faces the chair.)
			if not asset(m, "OfficeDesk", at, Vector3.new(0, 0, -1), 7) then
				part(m, "Desk", Vector3.new(8, 0.4, 4), CFrame.new(at + Vector3.new(0, 3.4, 0)), hex("#D8CBB4"), Enum.Material.Wood)
				part(m, "DeskLegs", Vector3.new(7.4, 3.2, 3.4), CFrame.new(at + Vector3.new(0, 1.6, 0.2)), hex("#9AA2AD"), Enum.Material.Metal, { Transparency = 0.2 })
				part(m, "Screen", Vector3.new(3.4, 2.2, 0.3), CFrame.new(at + Vector3.new(0, 4.9, 1.4)), hex("#1E2228"))
				part(m, "Glow", Vector3.new(3, 1.8, 0.05), CFrame.new(at + Vector3.new(0, 4.9, 1.23)), hex("#7FC4FF"), Enum.Material.Neon, { CanCollide = false })
			end
			-- (A real office chair, N7: it faces the desk.)
			if not asset(m, "OfficeChair", at + Vector3.new(0, 0, -3), Vector3.new(0, 0, 1), 4.2) then
				chair(m, at + Vector3.new(0, 0, -3), Vector3.new(0, 0, 1), hex("#2E3440"))
			end
		end
	end
	-- A water cooler, a printer, a meeting table by the back wall; ceiling panels.
	part(m, "Printer", Vector3.new(4, 3.4, 3), CFrame.new(c + Vector3.new(s.X / 2 - 5, 1.7, -s.Z / 2 + 20)), hex("#D9DDE2"))
	cylinder(m, "Cooler", 4, 2, CFrame.new(c + Vector3.new(s.X / 2 - 4, 2, -s.Z / 2 + 28)) * CFrame.Angles(0, 0, math.rad(90)), hex("#BFE3FF"), Enum.Material.Glass)
	part(m, "MeetingTable", Vector3.new(20, 0.5, 6), CFrame.new(c + Vector3.new(0, 3.4, s.Z / 2 - 7)), hex("#3A3F47"), Enum.Material.Wood)
	sign(m, "MONDAY", CFrame.new(c + Vector3.new(0, 13, s.Z / 2 - 0.3)), Vector3.new(22, 5, 0.3), hex("#2B4CA3"), Color3.new(1, 1, 1))
	for x = -1, 1 do
		for z = -1, 1 do
			lamp(m, CFrame.new(c + Vector3.new(x * 32, s.Y - 0.3, z * 26)), hex("#EAF3FF"), 34, 1, Vector3.new(10, 0.3, 4))
		end
	end
	plant(m, c + Vector3.new(-s.X / 2 + 3, 0, s.Z / 2 - 3))
	plant(m, c + Vector3.new(s.X / 2 - 3, 0, s.Z / 2 - 3))
end

BUILDERS.FoodCourt = function(m, place, c)
	local s = place.size
	shell(m, place, c, hex("#EDE6DA"), Enum.Material.Marble, hex("#F7D9A8"), Enum.Material.SmoothPlastic, hex("#FFF4E0"))
	-- Stalls along the back wall, each with its own colour and sign.
	local stalls = { { "BURGER", "#F25A5A" }, { "PIZZA", "#FF9F1C" }, { "NOODLES", "#2EC4B6" }, { "TACOS", "#9B5DE5" } }
	for i, stall in stalls do
		local x = (i - 2.5) * 28
		local at = c + Vector3.new(x, 0, s.Z / 2 - 6)
		part(m, "Stall", Vector3.new(22, 4, 5), CFrame.new(at + Vector3.new(0, 2, 0)), hex(stall[2]))
		part(m, "StallTop", Vector3.new(22.6, 0.4, 5.6), CFrame.new(at + Vector3.new(0, 4.2, 0)), hex("#F4F4F4"), Enum.Material.Marble)
		part(m, "Awning", Vector3.new(22, 1, 6), CFrame.new(at + Vector3.new(0, 11, -1)) * CFrame.Angles(math.rad(-15), 0, 0), hex(stall[2]), Enum.Material.Fabric, { CanQuery = false })
		sign(m, stall[1], CFrame.new(at + Vector3.new(0, 14.5, 2.2)), Vector3.new(16, 4, 0.3), hex("#1B1B22"), hex(stall[2]))
		lamp(m, CFrame.new(at + Vector3.new(0, 9.5, -3)), hex("#FFE9C2"), 20, 1.4, Vector3.new(6, 0.4, 1))
		-- What it sells (N7: real food): three on the counter and a big one over the sign.
		local food = ({ "FoodBurger", "FoodPizza", "FoodNoodles", "FoodTacos" })[i]
		for k = -1, 1 do
			asset(m, food, at + Vector3.new(k * 7, 4.4, -0.6), Vector3.new(0, 0, -1), 2.6)
		end
		local big = asset(m, food, at + Vector3.new(0, 16.8, 2.2), Vector3.new(0, 0, -1), 6.5)
		if big and food == "FoodPizza" then
			-- (A pizza lying flat up there would be a thin line: it stands up, face to the room.)
			big:PivotTo(big:GetPivot() * CFrame.new(0, 3.25, 0) * CFrame.Angles(math.rad(70), 0, 0))
		end
	end
	-- Long tables with stools, bins between them.
	for row = 0, 2 do
		for col = -2, 2 do
			local at = c + Vector3.new(col * 22, 0, -20 + row * 18)
			-- A real table with its stools (N7: one mesh).
			if asset(m, "FoodTable", at, Vector3.new(0, 0, 1), 10) then
				continue
			end
			part(m, "Table", Vector3.new(10, 0.5, 4), CFrame.new(at + Vector3.new(0, 3.4, 0)), hex("#FFFFFF"))
			part(m, "TableBase", Vector3.new(1, 3.2, 1), CFrame.new(at + Vector3.new(0, 1.6, 0)), hex("#55585E"), Enum.Material.Metal)
			for side = -1, 1, 2 do
				for k = -1, 1 do
					cylinder(m, "Stool", 2.2, 1.8, CFrame.new(at + Vector3.new(k * 3.2, 1.1, side * 3.4)) * CFrame.Angles(0, 0, math.rad(90)), hex(stalls[(row + col + 5) % 4 + 1][2]))
				end
			end
		end
	end
	for x = -1, 1 do
		for z = -1, 0 do
			lamp(m, CFrame.new(c + Vector3.new(x * 40, s.Y - 0.3, z * 30 + 5)), hex("#FFF2D6"), 40, 1, Vector3.new(8, 0.3, 8))
		end
	end
	for i = -1, 1, 2 do
		part(m, "Bin", Vector3.new(2.4, 3.6, 2.4), CFrame.new(c + Vector3.new(i * (s.X / 2 - 3), 1.8, 0)), hex("#3A3D44"), Enum.Material.Metal)
	end
end

BUILDERS.Market = function(m, place, c)
	local s = place.size
	shell(m, place, c, hex("#F2F2F0"), Enum.Material.SmoothPlastic, hex("#E2F2E6"), Enum.Material.SmoothPlastic, hex("#FAFAFA"))
	-- Aisles: shelves with rows of goods in stripes of colour.
	local goods = { "#E63946", "#F4A261", "#2A9D8F", "#457B9D", "#E9C46A", "#8E5CF5" }
	for i = -2, 2 do
		local at = c + Vector3.new(i * 18, 0, 8)
		-- Real shelves of groceries (N7: generated, plain packaging): five back to back on each side
		-- of the aisle's spine.
		local real = 0
		for k = -2, 2 do
			for side = -1, 1, 2 do
				if asset(m, "Shelf", at + Vector3.new(side * 1.8, 0, k * 8), Vector3.new(side, 0, 0), 7.6) then
					real += 1
				end
			end
		end
		if real > 0 then
			sign(m, ({ "SNACKS", "DRINKS", "FRUIT", "CEREAL", "FROZEN" })[i + 3], CFrame.new(at + Vector3.new(0, 9, -20.5)), Vector3.new(8, 2.4, 0.3), hex("#25C773"), Color3.new(1, 1, 1))
			continue
		end
		part(m, "Shelf", Vector3.new(4, 8, 40), CFrame.new(at + Vector3.new(0, 4, 0)), hex("#C9CED6"), Enum.Material.Metal)
		for tier = 0, 2 do
			for side = -1, 1, 2 do
				part(m, "Goods", Vector3.new(0.6, 1.6, 38), CFrame.new(at + Vector3.new(side * 2.3, 1.4 + tier * 2.6, 0)), hex(goods[(i + tier + 3 + side) % #goods + 1]), Enum.Material.SmoothPlastic, { CanCollide = false })
			end
		end
		sign(m, ({ "SNACKS", "DRINKS", "FRUIT", "CEREAL", "FROZEN" })[i + 3], CFrame.new(at + Vector3.new(0, 11, -20.5)), Vector3.new(8, 2.4, 0.3), hex("#25C773"), Color3.new(1, 1, 1))
	end
	-- Checkouts by the entrance, freezers along the back wall, a few carts.
	for i = -1, 1 do
		local at = c + Vector3.new(i * 22, 0, -s.Z / 2 + 26)
		part(m, "Checkout", Vector3.new(10, 3.4, 3), CFrame.new(at + Vector3.new(0, 1.7, 0)), hex("#3A3F47"))
		part(m, "Belt", Vector3.new(8, 0.2, 2.2), CFrame.new(at + Vector3.new(-0.6, 3.5, 0)), hex("#121316"), Enum.Material.Rubber)
		part(m, "Till", Vector3.new(1.6, 1.4, 1.4), CFrame.new(at + Vector3.new(4, 4.1, 0)), hex("#D9DDE2"))
	end
	part(m, "Freezers", Vector3.new(s.X - 10, 7, 4), CFrame.new(c + Vector3.new(0, 3.5, s.Z / 2 - 3)), hex("#BFE7FF"), Enum.Material.Glass, { Transparency = 0.25 })
	part(m, "FreezerGlow", Vector3.new(s.X - 12, 0.3, 3), CFrame.new(c + Vector3.new(0, 7.2, s.Z / 2 - 3)), hex("#8FD3FF"), Enum.Material.Neon, { CanCollide = false })
	for i = 0, 3 do
		local at = c + Vector3.new(-s.X / 2 + 8 + i * 4, 0, -s.Z / 2 + 16)
		if not asset(m, "Cart", at, Vector3.new(0, 0, -1), 4.2) then
			part(m, "Cart", Vector3.new(2.6, 2.2, 3.6), CFrame.new(at + Vector3.new(0, 2.2, 0)), hex("#B8BEC6"), Enum.Material.DiamondPlate, { Transparency = 0.3 })
		end
	end
	for x = -1, 1 do
		for z = -1, 1 do
			lamp(m, CFrame.new(c + Vector3.new(x * 34, s.Y - 0.3, z * 28)), hex("#F3FFF6"), 34, 1, Vector3.new(12, 0.3, 2))
		end
	end
end

BUILDERS.Hangar = function(m, place, c)
	local s = place.size
	shell(m, place, c, hex("#3C3F45"), Enum.Material.Concrete, hex("#2A2E36"), Enum.Material.Metal, hex("#1E2128"))
	-- The open door at the back: night sky with a few stars.
	local doorZ = s.Z / 2 - 0.2
	part(m, "NightSky", Vector3.new(s.X * 0.7, s.Y * 0.7, 0.2), CFrame.new(c + Vector3.new(0, s.Y * 0.35, doorZ)), hex("#0B1030"), Enum.Material.Neon, { CanCollide = false })
	local stars = Random.new(7)
	for _ = 1, 18 do
		part(m, "Star", Vector3.new(0.3, 0.3, 0.1), CFrame.new(c + Vector3.new(stars:NextNumber(-s.X * 0.33, s.X * 0.33), stars:NextNumber(8, s.Y * 0.68), doorZ - 0.2)), hex("#FFFFFF"), Enum.Material.Neon, { CanCollide = false, CanQuery = false })
	end
	-- A small jet in the middle (taxiing lines under it).
	local jet = c + Vector3.new(14, 0, 8)
	local body = Color3.fromRGB(196, 202, 214)
	local realJet = asset(m, "Jet", jet, Vector3.new(0, 0, -1), 44)
	if not realJet then
		cylinder(m, "Fuselage", 46, 8, CFrame.new(jet + Vector3.new(0, 7, 0)) * CFrame.Angles(0, math.rad(90), 0), body, Enum.Material.Metal)
		part(m, "Nose", Vector3.new(8, 8, 8), CFrame.new(jet + Vector3.new(0, 7, -23)), body, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
		part(m, "Cockpit", Vector3.new(5, 2, 4), CFrame.new(jet + Vector3.new(0, 9.4, -22)), hex("#1F2A44"), Enum.Material.Glass)
		part(m, "Wings", Vector3.new(44, 0.8, 9), CFrame.new(jet + Vector3.new(0, 5.4, 2)), body, Enum.Material.Metal)
		part(m, "Tail", Vector3.new(0.8, 9, 7), CFrame.new(jet + Vector3.new(0, 14, 20)), hex("#4F5BD5"), Enum.Material.Metal)
		part(m, "TailWings", Vector3.new(16, 0.6, 5), CFrame.new(jet + Vector3.new(0, 8.5, 21)), body, Enum.Material.Metal)
		for side = -1, 1, 2 do
			cylinder(m, "Engine", 7, 3.6, CFrame.new(jet + Vector3.new(side * 10, 4, 1)) * CFrame.Angles(0, math.rad(90), 0), hex("#9AA2AD"), Enum.Material.Metal)
			part(m, "Wheel", Vector3.new(1.4, 3, 3), CFrame.new(jet + Vector3.new(side * 4, 1.5, 4)), hex("#141518"), Enum.Material.Rubber)
		end
		part(m, "NoseWheel", Vector3.new(1.2, 3, 3), CFrame.new(jet + Vector3.new(0, 1.5, -18)), hex("#141518"), Enum.Material.Rubber)
	end
	for i = -4, 4 do
		part(m, "Line", Vector3.new(1, 0.05, 6), CFrame.new(c + Vector3.new(-30, 0.03, i * 11)), hex("#F2C230"), Enum.Material.Neon, { CanCollide = false, CanQuery = false })
	end
	-- Crates and a baggage cart.
	local crates = Random.new(11)
	for i = 0, 5 do
		local at = c + Vector3.new(-s.X / 2 + 8 + (i % 3) * 6.5, 0, s.Z / 2 - 14 - math.floor(i / 3) * 7)
		local h = crates:NextInteger(1, 2)
		for k = 0, h - 1 do
			local turn = math.rad(crates:NextNumber(-8, 8))
			local crate = asset(m, "Crate", at + Vector3.new(0, k * 6, 0), Vector3.new(math.sin(turn), 0, math.cos(turn)), 6)
			if not crate then
				part(m, "Crate", Vector3.new(6, 6, 6), CFrame.new(at + Vector3.new(0, 3 + k * 6, 0)) * CFrame.Angles(0, turn, 0), hex("#8B6A45"), Enum.Material.WoodPlanks)
			end
		end
	end
	if not asset(m, "BaggageCart", c + Vector3.new(-26, 0, -16), Vector3.new(1, 0, 0), 5.5) then
		part(m, "BaggageCart", Vector3.new(12, 1, 6), CFrame.new(c + Vector3.new(-26, 2, -16)), hex("#F2C230"), Enum.Material.Metal)
		for i = 0, 3 do
			part(m, "Suitcase", Vector3.new(2.4, 3, 1.4), CFrame.new(c + Vector3.new(-30 + i * 2.8, 4, -16)), hex(({ "#E63946", "#457B9D", "#2A9D8F", "#1B1B22" })[i + 1]))
		end
	end
	-- Rows of waiting seats along the front wall, facing the jet (N7).
	for i = -2, 2 do
		asset(m, "AirportSeats", c + Vector3.new(i * 14, 0, -s.Z / 2 + 8), Vector3.new(0, 0, 1), 10)
	end
	-- Hanging lamps: warm pools of light in the dark.
	for x = -1, 1 do
		for z = -1, 1 do
			local at = c + Vector3.new(x * 44, s.Y - 8, z * 34)
			part(m, "Cable", Vector3.new(0.2, 8, 0.2), CFrame.new(at + Vector3.new(0, 4, 0)), hex("#111111"), Enum.Material.Metal, { CanCollide = false, CanQuery = false })
			lamp(m, CFrame.new(at), hex("#FFC870"), 50, 1.4, Vector3.new(3, 1, 3)) -- (brighter blows the white jet out)
		end
	end
end

BUILDERS.WhiteRoom = function(m, place, c)
	local s = place.size
	local white = hex("#F4F4F7")
	shell(m, place, c, white, Enum.Material.SmoothPlastic, white, Enum.Material.SmoothPlastic, white)
	-- A few white blocks and a ramp to throw things off, nothing else.
	part(m, "Block", Vector3.new(12, 6, 12), CFrame.new(c + Vector3.new(40, 3, 30)), hex("#E6E6EE"))
	part(m, "Block", Vector3.new(8, 12, 8), CFrame.new(c + Vector3.new(-44, 6, 36)), hex("#E6E6EE"))
	part(m, "Ramp", Vector3.new(16, 1, 30), CFrame.new(c + Vector3.new(-40, 5, -30)) * CFrame.Angles(math.rad(18), 0, 0), hex("#E6E6EE"))
	-- A test track in the middle (N7): a ring of cones and two striped barriers to aim at.
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		asset(m, "Cone", c + Vector3.new(math.cos(a) * 22, 0, math.sin(a) * 22), nil, 2.8)
	end
	for _, x in { -12, 12 } do
		asset(m, "Barrier", c + Vector3.new(x, 0, -48), Vector3.new(0, 0, 1), 8)
	end
	for x = -1, 1 do
		for z = -1, 1 do
			lamp(m, CFrame.new(c + Vector3.new(x * 50, s.Y - 0.3, z * 50)), hex("#FFFFFF"), 52, 0.8, Vector3.new(14, 0.3, 14))
		end
	end
end

-- Round 3, M9: the metro station. A platform with a yellow edge, the tracks along the far wall
-- with a train standing at them (doors open: one can walk in), pillars, benches, ticket gates by
-- the arrival, the line's signs and a clock.
BUILDERS.Metro = function(m, place, c)
	local s = place.size
	shell(m, place, c, hex("#8E949C"), Enum.Material.Pavement, hex("#EEF1F4"), Enum.Material.SmoothPlastic, hex("#2C3138"))
	local edgeZ = s.Z / 2 - 24 -- (the platform's edge; the tracks beyond it, to the north wall)
	-- The station's tiles: a dark band at the foot of every wall and the line's colour at eye height
	-- (one long part per wall each, so the look costs a handful of parts).
	for _, w in {
		{ Vector3.new(0, 0, s.Z / 2 - 0.15), Vector3.new(s.X, 0, 0.3) },
		{ Vector3.new(0, 0, -s.Z / 2 + 0.15), Vector3.new(s.X, 0, 0.3) },
		{ Vector3.new(s.X / 2 - 0.15, 0, 0), Vector3.new(0.3, 0, s.Z) },
		{ Vector3.new(-s.X / 2 + 0.15, 0, 0), Vector3.new(0.3, 0, s.Z) },
	} do
		part(m, "TileFoot", w[2] + Vector3.new(0, 3, 0), CFrame.new(c + w[1] + Vector3.new(0, 1.5, 0)), hex("#2F3A4A"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
		part(m, "TileBand", w[2] + Vector3.new(0, 1.6, 0), CFrame.new(c + w[1] + Vector3.new(0, 8, 0)), hex(place.color), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
	end
	-- The tunnel mouths the track runs into, east and west.
	for _, side in { -1, 1 } do
		part(m, "Tunnel", Vector3.new(0.4, 13, 14), CFrame.new(c + Vector3.new(side * (s.X / 2 - 0.4), 6.5, edgeZ + 12)), hex("#07090C"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
	end
	-- Posters on the wall across the track (the game's own places, no real brands).
	sign(m, "NEXT STOP: COFFEE BAR", CFrame.new(c + Vector3.new(-39, 20, s.Z / 2 - 0.4)), Vector3.new(24, 5, 0.3), hex("#6B3E26"), hex("#FFE7C2"))
	sign(m, "VISIT THE FOOD COURT", CFrame.new(c + Vector3.new(39, 20, s.Z / 2 - 0.4)), Vector3.new(24, 5, 0.3), hex("#E05A2B"), Color3.new(1, 1, 1))
	-- The track bed: darker, two rails, sleepers.
	part(m, "TrackBed", Vector3.new(s.X, 0.2, 24), CFrame.new(c + Vector3.new(0, 0.1, edgeZ + 12)), hex("#3A3D42"), Enum.Material.Concrete)
	for _, dz in { -2.4, 2.4 } do
		part(m, "Rail", Vector3.new(s.X, 0.4, 0.4), CFrame.new(c + Vector3.new(0, 0.4, edgeZ + 12 + dz)), hex("#9AA0A8"), Enum.Material.Metal)
	end
	for x = -s.X / 2 + 4, s.X / 2 - 4, 8 do
		part(m, "Sleeper", Vector3.new(1.2, 0.25, 7), CFrame.new(c + Vector3.new(x, 0.32, edgeZ + 12)), hex("#5A4636"), Enum.Material.Wood)
	end
	-- The platform's edge: a yellow line and its tactile strip.
	part(m, "EdgeLine", Vector3.new(s.X, 0.06, 1.2), CFrame.new(c + Vector3.new(0, 0.03, edgeZ - 1.4)), hex("#F2C230"), Enum.Material.SmoothPlastic, { CanCollide = false })
	-- The train: three cars, doors open on the platform side.
	local trainZ = edgeZ + 12
	for car = -1, 1 do
		local x = car * 34
		local body = c + Vector3.new(x, 0.6, trainZ)
		part(m, "CarFloor", Vector3.new(32, 0.6, 9), CFrame.new(body + Vector3.new(0, 0.9, 0)), hex("#4A4F57"), Enum.Material.Metal)
		part(m, "CarRoof", Vector3.new(32, 1, 9.4), CFrame.new(body + Vector3.new(0, 9.6, 0)), hex("#DDE3EA"), Enum.Material.Metal)
		part(m, "CarBack", Vector3.new(32, 8.4, 0.4), CFrame.new(body + Vector3.new(0, 5.2, 4.5)), hex("#F4F6F8"), Enum.Material.Metal)
		part(m, "CarStripe", Vector3.new(32.2, 1.2, 0.5), CFrame.new(body + Vector3.new(0, 3.4, 4.5)), hex(place.color), Enum.Material.SmoothPlastic, { CanCollide = false })
		part(m, "CarEnd", Vector3.new(0.4, 8.4, 9), CFrame.new(body + Vector3.new(-16, 5.2, 0)), hex("#F4F6F8"), Enum.Material.Metal)
		part(m, "CarEnd", Vector3.new(0.4, 8.4, 9), CFrame.new(body + Vector3.new(16, 5.2, 0)), hex("#F4F6F8"), Enum.Material.Metal)
		-- The platform side: wall panels with windows between two open doors.
		for _, px in { -13.5, 0, 13.5 } do
			part(m, "CarSide", Vector3.new(if px == 0 then 13 else 5, 8.4, 0.4), CFrame.new(body + Vector3.new(px, 5.2, -4.5)), hex("#F4F6F8"), Enum.Material.Metal)
			part(m, "Window", Vector3.new(if px == 0 then 11 else 3.6, 3, 0.1), CFrame.new(body + Vector3.new(px, 6.2, -4.75)), hex("#1F2833"), Enum.Material.Glass, { CanCollide = false, Transparency = 0.25 })
		end
		part(m, "CarStripe", Vector3.new(32.2, 1.2, 0.5), CFrame.new(body + Vector3.new(0, 3.4, -4.5)), hex(place.color), Enum.Material.SmoothPlastic, { CanCollide = false })
		for _, sx in { -10, 10 } do
			part(m, "Seat", Vector3.new(6, 1.6, 2.2), CFrame.new(body + Vector3.new(sx, 2, 3)), hex(place.color), Enum.Material.Fabric)
		end
		cylinder(m, "Pole", 7, 0.25, CFrame.new(body + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90)), hex("#C9CED6"), Enum.Material.Metal)
	end
	-- Pillars along the platform, benches between them, lights over them.
	for i = -2, 2 do
		local at = c + Vector3.new(i * 26, 0, edgeZ - 10)
		part(m, "Pillar", Vector3.new(2.4, s.Y, 2.4), CFrame.new(at + Vector3.new(0, s.Y / 2, 0)), hex("#D5DAE0"), Enum.Material.SmoothPlastic)
		lamp(m, CFrame.new(at + Vector3.new(0, s.Y - 0.4, 6)), hex("#EAF3FF"), 30, 1.1, Vector3.new(12, 0.3, 1.2))
		if i < 2 then
			local bench = at + Vector3.new(13, 0, -4)
			part(m, "Bench", Vector3.new(8, 0.5, 2), CFrame.new(bench + Vector3.new(0, 1.8, 0)), hex("#7D858F"), Enum.Material.Metal)
			part(m, "BenchBack", Vector3.new(8, 2, 0.4), CFrame.new(bench + Vector3.new(0, 2.9, -0.9)), hex("#7D858F"), Enum.Material.Metal)
			part(m, "BenchLegs", Vector3.new(7, 1.6, 1.4), CFrame.new(bench + Vector3.new(0, 0.8, 0)), hex("#4D535B"), Enum.Material.Metal, { Transparency = 0.3 })
		end
	end
	-- Ticket gates between the arrival and the platform (a gap in the middle: the way in).
	local gateZ = -s.Z / 2 + 20
	for i = -4, 4 do
		if i ~= 0 then
			part(m, "Gate", Vector3.new(1, 3.6, 5), CFrame.new(c + Vector3.new(i * 5, 1.8, gateZ)), hex("#9AA0A8"), Enum.Material.Metal)
			part(m, "GateLight", Vector3.new(1.05, 0.4, 1), CFrame.new(c + Vector3.new(i * 5, 3.5, gateZ - 1.8)), hex("#5BE37D"), Enum.Material.Neon, { CanCollide = false })
		end
	end
	-- The line's signs and the clock.
	-- (Hung between the pillars, never through one: the pillars stand every 26 studs from the middle.)
	-- (Two-sided: read from the arrival and from the train.)
	for _, face in { 0, 180 } do
		local dz = if face == 0 then -0.2 else 0.2
		sign(m, "LINE 1  \u{00B7}  CITY CENTRE  \u{2192}", CFrame.new(c + Vector3.new(-13, s.Y - 7, edgeZ - 10 + dz)) * CFrame.Angles(0, math.rad(face), 0), Vector3.new(21, 4, 0.3), hex(place.color), Color3.new(1, 1, 1))
		sign(m, "NEXT TRAIN: DELAYED", CFrame.new(c + Vector3.new(13, s.Y - 7, edgeZ - 10 + dz)) * CFrame.Angles(0, math.rad(face), 0), Vector3.new(21, 4, 0.3), hex("#111418"), hex("#FFB13B"))
	end
	part(m, "ClockFace", Vector3.new(0.4, 5, 5), CFrame.new(c + Vector3.new(-s.X / 2 + 0.6, 14, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	part(m, "ClockHand", Vector3.new(0.2, 2, 0.25), CFrame.new(c + Vector3.new(-s.X / 2 + 0.85, 14.8, 0)), hex("#111418"), Enum.Material.SmoothPlastic, { CanCollide = false })
	part(m, "ClockHand", Vector3.new(0.2, 0.25, 1.6), CFrame.new(c + Vector3.new(-s.X / 2 + 0.85, 14, 0.7)), hex("#111418"), Enum.Material.SmoothPlastic, { CanCollide = false })
	plant(m, c + Vector3.new(-s.X / 2 + 3, 0, -s.Z / 2 + 3))
	plant(m, c + Vector3.new(s.X / 2 - 3, 0, -s.Z / 2 + 3))
end

BUILDERS.Arena = function(m, place, c)
	local s = place.size
	-- v4 D1 (owner: "no AI slop"): with Config.ARENA_V2 a sports hall (a red running track with white
	-- lanes, bare concrete walls over a blue padded band, painted lines), not a pink box.
	local v2 = (Config :: any).ARENA_V2 == true
	if v2 then
		shell(m, place, c, hex("#A9473A"), Enum.Material.Rubber, hex("#CFCBC3"), Enum.Material.Concrete, hex("#2A2D33"))
		for _, side in { -1, 1 } do
			part(m, "Padding", Vector3.new(0.6, 5, s.Z), CFrame.new(c + Vector3.new(side * (s.X / 2 - 0.3), 2.5, 0)), hex("#24456F"), Enum.Material.Fabric, { CanQuery = false })
		end
		for _, z in { -1, 1 } do
			part(m, "Padding", Vector3.new(s.X, 5, 0.6), CFrame.new(c + Vector3.new(0, 2.5, z * (s.Z / 2 - 0.3))), hex("#24456F"), Enum.Material.Fabric, { CanQuery = false })
		end
		-- Lanes down the run (start in the north, finish in the south).
		local laneW = 8
		for x = -s.X / 2 + 12, s.X / 2 - 12, laneW do
			part(m, "Lane", Vector3.new(0.35, 0.05, 96), CFrame.new(c + Vector3.new(x, 0.03, 8)), hex("#F2EEE6"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
		end
	else
		shell(m, place, c, hex("#E8D2A6"), Enum.Material.Sand, hex("#F7B6C8"), Enum.Material.SmoothPlastic, hex("#9FE3E0"))
	end
	-- The lines: where runners start (north), where they must not cross (the finish, south), and
	-- the guard's side behind it.
	local function line(z: number, color: Color3)
		part(m, "Line", Vector3.new(s.X - 6, 0.06, 1.4), CFrame.new(c + Vector3.new(0, 0.04, z)), color, if (Config :: any).ARENA_V2 then Enum.Material.SmoothPlastic else Enum.Material.Neon, { CanCollide = false, CanQuery = false })
	end
	line(56, hex("#FFFFFF"))
	line(-40, hex("#E63946"))
	-- Cones along both lines' ends and barriers down the side walls (N7).
	for _, z in { 56, -40 } do
		for _, side in { -1, 1 } do
			asset(m, "Cone", c + Vector3.new(side * (s.X / 2 - 5), 0, z), nil, 3)
		end
	end
	for _, side in { -1, 1 } do
		for k = -1, 1 do
			asset(m, "Barrier", c + Vector3.new(side * (s.X / 2 - 3), 0, k * 30), Vector3.new(-side, 0, 0), 8)
		end
	end
	-- The traffic light over the start line, facing the guard.
	local board = part(m, "LightBoard", Vector3.new(30, 10, 1), CFrame.new(c + Vector3.new(0, 24, s.Z / 2 - 1)), hex("#1B1B22"))
	board:SetAttribute("ArenaLights", true)
	for i, name in { "Red", "Yellow", "Green" } do
		local lampPart = part(m, name .. "Lamp", Vector3.new(0.6, 7, 7), CFrame.new(c + Vector3.new((i - 2) * 9, 24, s.Z / 2 - 1.7)) * UP_X, hex("#333338"), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })
		lampPart:SetAttribute("Lamp", name)
	end
	-- The two game buttons by the door (stand on one and press E, or tap it on a phone).
	for i, g in { { "RLGL", "RED LIGHT\nGREEN LIGHT", "#E63946" }, { "Shoot", "SHOOT 'EM", "#25C773" } } do
		local x = if i == 1 then -22 else 22
		local base = part(m, "GameButton", Vector3.new(8, 1.2, 8), CFrame.new(c + Vector3.new(x, 0.6, -s.Z / 2 + 14)), hex(g[3]), Enum.Material.SmoothPlastic)
		base:SetAttribute("Game", g[1])
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Start"
		prompt.ActionText = "Start"
		prompt.ObjectText = (string.gsub(g[2], "\n", " "))
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = base
		sign(m, g[2], CFrame.new(c + Vector3.new(x, 9, -s.Z / 2 + 0.3)) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(16, 6, 0.3), hex(g[3]), Color3.new(1, 1, 1))
	end
	for x = -1, 1 do
		for z = -1, 1 do
			lamp(m, CFrame.new(c + Vector3.new(x * 40, s.Y - 0.3, z * 44)), hex("#FFFFFF"), 46, 0.9, Vector3.new(12, 0.3, 12))
		end
	end
end

------------------------------------------------------------------------------------------------
-- The rooms' make (10 Nov 2026, the owner: the maps must not look like AI slop). A plain box with
-- flat walls is what gave them away: every room now has a skirting board and a cornice round its
-- walls, pilasters that break the long walls into bays, real windows with frames and glazing bars
-- (the rooms float in the sky: the windows show it), and an inlaid border round the floor. A few
-- parts a wall, each one long; nothing here collides with a thrown body except the pilasters, which
-- stand out only half a stud. The rooms' own extras follow (EXTRAS).

type Look = { trim: Color3, pilaster: Color3?, windows: boolean, border: Color3?, crown: Color3? }

local LOOKS: { [string]: Look } = {
	Cafe = { trim = hex("#5A3A26"), pilaster = hex("#E2CDAE"), windows = true, border = hex("#5A3A26") },
	Office = { trim = hex("#3A4250"), pilaster = hex("#D5DAE2"), windows = true, border = hex("#4A5563") },
	FoodCourt = { trim = hex("#B5532A"), pilaster = hex("#F0C88A"), windows = true, border = hex("#E0A458") },
	Market = { trim = hex("#2E7D4F"), pilaster = hex("#CDE8D4"), windows = true, border = hex("#9FD3B0") },
	Hangar = { trim = hex("#F2C230"), pilaster = hex("#454B55"), windows = true, border = hex("#F2C230") },
	WhiteRoom = { trim = hex("#D3D3DE"), pilaster = hex("#ECECF2"), windows = false, border = nil },
	Metro = { trim = hex("#2F3A4A"), pilaster = nil, windows = false, border = nil, crown = hex("#2F3A4A") },
	Arena = if (Config :: any).ARENA_V2 then { trim = hex("#24456F"), pilaster = hex("#B9B5AD"), windows = true, border = nil } else { trim = hex("#C9577A"), pilaster = hex("#F3A6BD"), windows = true, border = nil },
}

local BAY = 18 -- studs between pilasters
local SKY = hex("#A9DBFF")

local function dress(m: Instance, place: Places.Place, c: Vector3, look: Look)
	local s = place.size
	local deco = { CanQuery = false }
	-- Each wall: where it runs (its middle), along which axis, its length and which way is in.
	local walls = {
		{ mid = Vector3.new(0, 0, s.Z / 2), along = Vector3.xAxis, len = s.X, inward = -Vector3.zAxis, name = "N" },
		{ mid = Vector3.new(0, 0, -s.Z / 2), along = Vector3.xAxis, len = s.X, inward = Vector3.zAxis, name = "S" },
		{ mid = Vector3.new(s.X / 2, 0, 0), along = Vector3.zAxis, len = s.Z, inward = -Vector3.xAxis, name = "E" },
		{ mid = Vector3.new(-s.X / 2, 0, 0), along = Vector3.zAxis, len = s.Z, inward = Vector3.xAxis, name = "W" },
	}
	local function box(name: string, w: any, length: number, height: number, depth: number, y: number, offset: number, color: Color3, material: Enum.Material?, props: { [string]: any }?)
		local size = if w.along == Vector3.xAxis then Vector3.new(length, height, depth) else Vector3.new(depth, height, length)
		local at = c + w.mid + w.inward * (depth / 2) + w.along * offset + Vector3.new(0, y, 0)
		return part(m, name, size, CFrame.new(at), color, material or Enum.Material.SmoothPlastic, props)
	end
	for _, w in walls do
		box("Skirting", w, w.len, 1.2, 0.5, 0.6, 0, look.trim, nil, deco)
		box("Cornice", w, w.len, 1, 0.7, s.Y - 0.5, 0, look.crown or look.trim, nil, deco)
		-- Pilasters into bays (none behind the signs over the doors, north and south).
		if look.pilaster then
			local count = math.floor(w.len / BAY)
			for k = 1, count - 1 do
				local offset = -w.len / 2 + k * (w.len / count)
				if (w.name == "N" or w.name == "S") and math.abs(offset) < 18 then
					continue
				end
				box("Pilaster", w, 2, s.Y - 2.2, 0.6, (s.Y - 2.2) / 2 + 1.2, offset, look.pilaster)
			end
			-- Windows: on the side walls, one in each bay, high up (over anything standing there).
			if look.windows and (w.name == "E" or w.name == "W") then
				local high = math.min(s.Y - 6, 22)
				local tall = math.min(10, s.Y - 14)
				for k = 0, count - 1 do
					local offset = -w.len / 2 + (k + 0.5) * (w.len / count)
					local wide = w.len / count - 6
					box("WindowFrame", w, wide + 1.2, tall + 1.2, 0.35, high - tall / 2, offset, look.trim, nil, deco)
					box("Window", w, wide, tall, 0.45, high - tall / 2, offset, SKY, Enum.Material.Glass, { CanQuery = false, Transparency = 0.05 })
					box("GlazingBar", w, 0.35, tall, 0.55, high - tall / 2, offset, look.trim, nil, deco)
					box("GlazingBar", w, wide, 0.35, 0.55, high - tall / 2, offset, look.trim, nil, deco)
				end
			end
		end
	end
	-- An inlaid border round the floor.
	if look.border then
		local inset = 4
		for _, w in walls do
			local length = w.len - inset * 2
			local size = if w.along == Vector3.xAxis then Vector3.new(length, 0.06, 1.4) else Vector3.new(1.4, 0.06, length)
			part(m, "FloorBorder", size, CFrame.new(c + w.mid + w.inward * inset + Vector3.new(0, 0.04, 0)), look.border, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
		end
	end
end

-- Each room's own extras on top of its first build.
local EXTRAS: { [string]: (Instance, Places.Place, Vector3) -> () } = {}

EXTRAS.Office = function(m, place, c)
	local s = place.size
	-- Low cubicle walls between the desks (each row of five split into bays), a reception desk by
	-- the door, filing cabinets and a bookcase down the west wall, a whiteboard on the east wall.
	for row = 0, 2 do
		for col = -2, 1 do
			part(m, "Partition", Vector3.new(0.5, 4.6, 9), CFrame.new(c + Vector3.new((col + 0.5) * 17, 2.3, -6 + row * 14 - 1)), hex("#8FA6BD"), Enum.Material.Fabric)
		end
		part(m, "PartitionBack", Vector3.new(84, 4.6, 0.5), CFrame.new(c + Vector3.new(0, 2.3, -6 + row * 14 + 3.4)), hex("#8FA6BD"), Enum.Material.Fabric)
	end
	local desk = c + Vector3.new(-26, 0, -s.Z / 2 + 14)
	part(m, "Reception", Vector3.new(16, 4, 3), CFrame.new(desk + Vector3.new(0, 2, 0)), hex("#2E3440"), Enum.Material.Wood)
	part(m, "ReceptionTop", Vector3.new(16.6, 0.4, 3.6), CFrame.new(desk + Vector3.new(0, 4.2, 0)), hex("#E8E2DA"), Enum.Material.Marble)
	part(m, "ReceptionSide", Vector3.new(3, 4, 8), CFrame.new(desk + Vector3.new(-6.5, 2, 4)), hex("#2E3440"), Enum.Material.Wood)
	for i = 0, 5 do
		part(m, "Cabinet", Vector3.new(3, 5, 3), CFrame.new(c + Vector3.new(-s.X / 2 + 2.2, 2.5, -10 + i * 3.4)), hex("#9AA2AD"), Enum.Material.Metal)
		for d = 0, 2 do
			part(m, "Drawer", Vector3.new(0.2, 0.25, 1.4), CFrame.new(c + Vector3.new(-s.X / 2 + 3.75, 1 + d * 1.5, -10 + i * 3.4)), hex("#3A3F47"), Enum.Material.Metal, { CanCollide = false, CanQuery = false })
		end
	end
	local shelf = c + Vector3.new(-s.X / 2 + 2, 0, 20)
	part(m, "Bookcase", Vector3.new(3, 9, 12), CFrame.new(shelf + Vector3.new(0, 4.5, 0)), hex("#6B4B33"), Enum.Material.Wood)
	local books = Random.new(5)
	for tier = 0, 2 do
		for k = 0, 4 do
			part(m, "Books", Vector3.new(1.6, 2, 2), CFrame.new(shelf + Vector3.new(1.4, 1.6 + tier * 2.8, -4.4 + k * 2.2)), hex(({ "#E63946", "#457B9D", "#2A9D8F", "#E9C46A", "#F4F1EA" })[books:NextInteger(1, 5)]), Enum.Material.SmoothPlastic, { CanCollide = false })
		end
	end
	part(m, "Whiteboard", Vector3.new(0.3, 7, 16), CFrame.new(c + Vector3.new(s.X / 2 - 0.5, 8, -6)), hex("#FAFAFA"), Enum.Material.SmoothPlastic)
	part(m, "WhiteboardFrame", Vector3.new(0.2, 7.6, 16.6), CFrame.new(c + Vector3.new(s.X / 2 - 0.4, 8, -6)), hex("#9AA2AD"), Enum.Material.Metal)
	-- A scribbled chart going down (drawn with a few strokes).
	for i, seg in { { -5, 10, 25 }, { -1, 9, -35 }, { 3, 8.2, 20 }, { 6, 6.8, -50 } } do
		part(m, "Scribble" .. i, Vector3.new(0.1, 0.25, 4), CFrame.new(c + Vector3.new(s.X / 2 - 0.7, seg[2], -6 + seg[1])) * CFrame.Angles(math.rad(seg[3]), 0, 0), hex("#E63946"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
	end
end

EXTRAS.WhiteRoom = function(m, place, c)
	local s = place.size
	-- A test hall: a measuring grid on the floor every 10 studs, a stripe of colour at eye height, and
	-- a course to throw bodies through (stairs up to a jump-off deck, a padded crash wall with a
	-- target, a foam pit).
	for x = -s.X / 2 + 10, s.X / 2 - 10, 10 do
		part(m, "GridX", Vector3.new(0.2, 0.05, s.Z - 4), CFrame.new(c + Vector3.new(x, 0.04, 0)), hex("#C8C8D6"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
	end
	for z = -s.Z / 2 + 10, s.Z / 2 - 10, 10 do
		part(m, "GridZ", Vector3.new(s.X - 4, 0.05, 0.2), CFrame.new(c + Vector3.new(0, 0.04, z)), hex("#C8C8D6"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
	end
	for _, w in { { Vector3.new(0, 7, s.Z / 2 - 0.3), Vector3.new(s.X, 1.2, 0.2) }, { Vector3.new(0, 7, -s.Z / 2 + 0.3), Vector3.new(s.X, 1.2, 0.2) }, { Vector3.new(s.X / 2 - 0.3, 7, 0), Vector3.new(0.2, 1.2, s.Z) }, { Vector3.new(-s.X / 2 + 0.3, 7, 0), Vector3.new(0.2, 1.2, s.Z) } } do
		part(m, "Stripe", w[2], CFrame.new(c + w[1]), hex("#FF5A5F"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
	end
	-- The course, along the east side.
	local base = c + Vector3.new(52, 0, -10)
	for i = 0, 7 do
		local h = (i + 1) * 1.5
		part(m, "CourseStair", Vector3.new(10, h, 3), CFrame.new(base + Vector3.new(0, h / 2, -i * 3)), if i % 2 == 0 then hex("#FFC93C") else hex("#F4F4F7"), Enum.Material.SmoothPlastic)
	end
	part(m, "JumpDeck", Vector3.new(10, 12, 10), CFrame.new(base + Vector3.new(0, 6, -28.5)), hex("#4D96FF"), Enum.Material.SmoothPlastic)
	part(m, "CrashPad", Vector3.new(24, 10, 3), CFrame.new(c + Vector3.new(20, 5, -s.Z / 2 + 6)), hex("#FF5A5F"), Enum.Material.Fabric)
	for i, r in { 4, 2.6, 1.2 } do
		part(m, "Target" .. i, Vector3.new(0.2, r * 2, r * 2), CFrame.new(c + Vector3.new(20, 5, -s.Z / 2 + 7.6 + i * 0.05)) * UP_X, if i % 2 == 1 then Color3.new(1, 1, 1) else hex("#FF5A5F"), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false, CanQuery = false })
	end
	-- The foam pit: a low rim and soft blocks in it (anchored: no physics to pay for).
	local pit = c + Vector3.new(-36, 0, 14) -- (clear of the cone ring, the ramp and the tall block)
	for _, e in { { Vector3.new(0, 0.8, 9), Vector3.new(20, 1.6, 1) }, { Vector3.new(0, 0.8, -9), Vector3.new(20, 1.6, 1) }, { Vector3.new(10, 0.8, 0), Vector3.new(1, 1.6, 18) }, { Vector3.new(-10, 0.8, 0), Vector3.new(1, 1.6, 18) } } do
		part(m, "PitRim", e[2], CFrame.new(pit + e[1]), hex("#2D3142"), Enum.Material.SmoothPlastic)
	end
	local foam = Random.new(3)
	for _ = 1, 22 do
		local at = pit + Vector3.new(foam:NextNumber(-8, 8), foam:NextNumber(0.6, 1.4), foam:NextNumber(-7, 7))
		part(m, "Foam", Vector3.new(2, 2, 2), CFrame.new(at) * CFrame.Angles(foam:NextNumber(0, 1), foam:NextNumber(0, 3), 0), hex(({ "#FFC93C", "#4D96FF", "#FF5A5F", "#6BCB77" })[foam:NextInteger(1, 4)]), Enum.Material.Fabric, { CanCollide = false })
	end
end

------------------------------------------------------------------------------------------------
-- Travel

-- Where a trip ends. Your lab: by its spawn point, facing your dummies (the plaza when you have
-- none). Someone's lab: the same spot in theirs. The plaza: in front of its square, facing it.
local function arrivalOf(player: Player?, id: string): CFrame?
	local plot = Places.labPlot(id)
	if id == "Lab" or plot then
		local at = if plot then Lab.plotCenter(plot) elseif player then Lab.originFor(player) else origin
		at += Vector3.new(0, 3.5, 0)
		return CFrame.lookAt(at, at - Vector3.zAxis)
	end
	if id == "Plaza" then
		local at = origin + Vector3.new(0, 3.5, 40)
		return CFrame.lookAt(at, at + Vector3.zAxis)
	end
	local place = Places.byId[id]
	local centre = Places.floorCenter(origin, id)
	if not place or not centre then
		return nil
	end
	local at = centre + Vector3.new(0, if place.outdoor then 8 else 3, if place.outdoor then OutdoorMaps.arriveZ(place) else -place.size.Z / 2 + ARRIVE_BACK)
	-- (An open-air map stands on its measured terrain: land 3 over its built pad.)
	local built = folder and folder:FindFirstChild(id)
	local pad = built and built:FindFirstChild("Arrival")
	if place.outdoor and pad and pad:IsA("BasePart") then
		at = pad.Position + Vector3.new(0, 3, 0)
	end
	return CFrame.lookAt(at, at + Vector3.new(0, 0, 1))
end

-- Why a trip is refused (nil: it may go).
function WorldMaps.refusal(player: Player, id: unknown): string?
	local plot = Places.labPlot(id)
	if plot then
		local owner = Lab.ownerOf(plot)
		if not owner then
			return "Nobody has that lab now"
		end
		-- (Labs are private, round 3: someone else's only with their invite.)
		if owner ~= player and not Lab.mayEnter(player, plot) then
			return "Ask " .. owner.DisplayName .. " to invite you to their lab"
		end
		-- (Your own counts as "Lab": the same checks below as any trip.)
	elseif type(id) ~= "string" or not Places.byId[id] then
		return "Unknown place"
	end
	local now = os.clock()
	if now - (lastTrip[player] or -math.huge) < Places.TRAVEL_GAP then
		return "Wait a moment"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return "Not now"
	end
	local state = character:GetAttribute("RagdollState")
	if character:GetAttribute("BodyLoose") or (state ~= nil and state ~= "Standing") then
		return "Get up first to travel!"
	end
	return nil
end

-- Moves a player's avatar to a place (checked). Returns whether it went.
-- Told of every trip that landed (the daily goals count the places visited: Main wires it).
WorldMaps.onTrip = nil :: ((Player, string) -> ())?

function WorldMaps.travel(player: Player, id: unknown): (boolean, string?)
	local why = WorldMaps.refusal(player, id)
	if why then
		return false, why
	end
	local placeId = id :: string
	-- Your own lab by its number is just your lab (and without a lab, no number is yours).
	local own = Lab.plotIndex(player)
	if own and Places.labPlot(placeId) == own then
		placeId = "Lab"
	end
	local target = arrivalOf(player, placeId)
	local character = player.Character
	if not target or not character then
		return false, "Not now"
	end
	lastTrip[player] = os.clock()
	local jitter = Vector3.new(math.random() * 6 - 3, 0, math.random() * 4 - 2)
	character:PivotTo(target + jitter)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
	end
	-- (With no lab of your own, "My Lab" takes you to the plaza, and that is where you are.)
	local landed = if placeId == "Lab" and not Lab.plotIndex(player) then "Plaza" else placeId
	player:SetAttribute("Place", landed)
	Metrics.event(player, "Place", 1, if Places.labPlot(landed) then "OtherLab" else landed)
	local hook = WorldMaps.onTrip
	if hook then
		hook(player, landed)
	end
	return true, nil
end

function WorldMaps.arrival(id: string, player: Player?): CFrame?
	return arrivalOf(player, id)
end

-- Which ground place a point is in, as the player standing there would call it.
local function groundPlace(player: Player, position: Vector3): string?
	local zone, plot, owner = Lab.zoneAt(position)
	if zone == "Lab" and plot then
		if plot == Lab.plotIndex(player) then
			return "Lab"
		end
		-- (A lab nobody has is open ground, like the plaza: no card of its own.)
		return if owner then Places.labId(plot) else "Plaza"
	end
	return zone
end
WorldMaps.groundPlace = groundPlace

function WorldMaps.folder(): Folder?
	return folder
end

------------------------------------------------------------------------------------------------

-- The plaza where the crowd lives (round 2, N7): street lamps round it and benches facing its
-- middle, each with a plant either side, outside the ring the people stroll in (CrowdService: 38
-- studs round the middle, 85 behind the spawn). Only where the place has the models.
local PLAZA_MIDDLE = Vector3.new(0, 0, 85)
local PLAZA_LAMPS = { 0, 60, 120, 180, 240, 300 } -- degrees round the middle (90 is the board)
local PLAZA_BENCHES = { 30, 150, 210, 330 }

local function dressPlaza(labOrigin: Vector3)
	local dressing = Instance.new("Model")
	dressing.Name = "PlazaDressing"
	local middle = labOrigin + PLAZA_MIDDLE
	local function round(angle: number, radius: number): (Vector3, Vector3)
		local a = math.rad(angle)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local spot = Vector3.new(middle.X + out.X * radius, middle.Y, middle.Z + out.Z * radius)
		-- (Standing on whatever floor is there.)
		local hit = Workspace:Raycast(spot + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0))
		return Vector3.new(spot.X, if hit then hit.Position.Y else middle.Y, spot.Z), out
	end
	-- A fountain on a round of paving (N7), between the crowd's middle and the board (the middle
	-- itself stays open: the crowd gathers and meets there).
	-- (Round 3, M6: on the plaza's east side, 0 degrees: at 90 it stood in front of the boards.)
	local fountainAt = select(1, round(0, 22))
	local floorY = fountainAt.Y
	-- The square itself (fix round 2): a round of pale paving under the whole crowd, out to the lamps.
	local square = Instance.new("Part")
	square.Name = "Square"
	square.Shape = Enum.PartType.Cylinder
	square.Size = Vector3.new(0.04, 104, 104)
	square.CFrame = CFrame.new(middle.X, floorY + 0.02, middle.Z) * CFrame.Angles(0, 0, math.rad(90))
	square.Color = hex("#B9B2A6")
	square.Material = Enum.Material.Pavement
	square.Anchored = true
	square.CanQuery = false
	square.CanCollide = false
	square.CanTouch = false
	square.CastShadow = false
	square.Parent = dressing
	local paving = Instance.new("Part")
	paving.Name = "Paving"
	paving.Shape = Enum.PartType.Cylinder
	paving.Size = Vector3.new(0.08, 30, 30)
	paving.CFrame = CFrame.new(fountainAt.X, floorY + 0.04, fountainAt.Z) * CFrame.Angles(0, 0, math.rad(90))
	paving.Color = hex("#C9B79C")
	paving.Material = Enum.Material.Cobblestone
	paving.Anchored = true
	paving.CanQuery = false -- (the crowd's floor checks see the ground under it)
	paving.CanCollide = false -- (a lip, however thin, trips a walking body: it is only a look)
	paving.CanTouch = false
	paving.CastShadow = false
	paving.Parent = dressing
	local fountain = asset(dressing, "Fountain", Vector3.new(fountainAt.X, floorY + 0.08, fountainAt.Z), nil, 13) -- (on the paving)
	if fountain then
		fountain:SetAttribute("KeepOut", 7.5) -- (the crowd never meets inside it: CrowdService)
	end
	for _, angle in PLAZA_LAMPS do
		local at, out = round(angle, 47)
		asset(dressing, "StreetLamp", at, out, 15) -- (the kept lamp's arm reaches along -Z: over the plaza)
	end
	for _, angle in PLAZA_BENCHES do
		local at, out = round(angle, 43)
		if asset(dressing, "Bench", at, -out, 7) then
			local side = Vector3.new(-out.Z, 0, out.X)
			plant(dressing, at + side * 5.5)
			plant(dressing, at - side * 5.5)
		end
	end
	-- Round 3, M1: the plaza is everyone's, and the only place players can hit each other. Its two
	-- edges are painted along the whole ground (a yellow line), with a tall board on them every
	-- EDGE_BOARD_EVERY studs (both faces read: from the plaza and from the lab next door), and one
	-- over the spot where trips to the plaza arrive.
	local WELCOME = "PLAZA\nEVERYONE'S WELCOME"
	local RULE = "You can hit other players here.\nNobody gets hurt."
	local function board(at: Vector3, facing: Vector3, into: Instance?)
		local cf = CFrame.lookAt(at, at + facing)
		sign(into or dressing, WELCOME, cf * CFrame.new(0, 3.2, 0), Vector3.new(22, 6.5, 0.4), hex("#16181D"), hex("#FFFFFF"))
		sign(into or dressing, RULE, cf * CFrame.new(0, -1.6, 0), Vector3.new(22, 3.2, 0.4), hex("#23B262"), hex("#FFFFFF"))
		part(into or dressing, "SignPost", Vector3.new(0.8, 9, 0.8), cf * CFrame.new(-9, -7.5, 0.3), hex("#2B2F38"), Enum.Material.Metal, { CanCollide = true })
		part(into or dressing, "SignPost", Vector3.new(0.8, 9, 0.8), cf * CFrame.new(9, -7.5, 0.3), hex("#2B2F38"), Enum.Material.Metal, { CanCollide = true })
	end
	local floor = middle.Y
	local base = Workspace:FindFirstChild("Baseplate")
	local length = if base and base:IsA("BasePart") then base.Size.Z else 2048
	local midZ = if base and base:IsA("BasePart") then base.Position.Z else labOrigin.Z
	local groundTop = labOrigin.Y - 0.5
	local EDGE_BOARD_EVERY = 256
	-- (Its own model: the plaza's dressing keeps its part budget, T36.)
	local edges = Instance.new("Model")
	edges.Name = "PlazaEdges"
	-- (On every screen whatever the distance: the private fences keep their signs clear of these
	-- boards, PlotPrivacy, so they must be known even far off.)
	edges.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _, side in { -1, 1 } do
		local lineX = labOrigin.X + side * (Lab.PLOT_HALF - 1.2)
		part(edges, "PlazaEdge", Vector3.new(1.2, 0.06, length), CFrame.new(lineX, groundTop + 0.04, midZ), hex("#FFC93C"), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false, CanTouch = false })
		-- (The first board stands by the plaza's middle; the others along the line both ways.)
		local edgeX = labOrigin.X + side * (Lab.PLOT_HALF - 7) -- (V6-4: by the line, wherever the plot edge is)
		for k = -math.floor((middle.Z - (midZ - length / 2)) / EDGE_BOARD_EVERY), math.floor((midZ + length / 2 - middle.Z) / EDGE_BOARD_EVERY) do
			board(Vector3.new(edgeX, floor + 11, middle.Z + k * EDGE_BOARD_EVERY), Vector3.new(-side, 0, 0), edges)
		end
	end
	edges.Parent = Workspace
	local arrival = labOrigin + Vector3.new(0, 0, 40)
	board(Vector3.new(arrival.X, floor + 11, arrival.Z + 34), Vector3.new(0, 0, -1))
	if #dressing:GetChildren() > 0 then
		dressing.Parent = Workspace
	else
		dressing:Destroy()
	end
end

function WorldMaps.build(labOrigin: Vector3)
	origin = labOrigin
	-- The ground everywhere (plaza and around): tiled concrete instead of the flat baseplate grey.
	local base = Workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		Finish.apply(base, "Floor")
		base.Color = Color3.fromRGB(150, 154, 160)
	end
	dressPlaza(labOrigin)
	local root = Instance.new("Folder")
	root.Name = "Places"
	for _, place in Places.list do
		local centre = Places.floorCenter(labOrigin, place.id)
		local builder = BUILDERS[place.id] or (if place.outdoor and OutdoorMaps.has(place.id) then OutdoorMaps.build else nil)
		if centre and builder then
			local model = Instance.new("Model")
			model.Name = place.id
			model:SetAttribute("Place", place.id)
			-- (One failing map must not take the rest and travel down with it: blind review 19 Nov.)
			local ok, err = pcall(builder, model, place, centre)
			if not ok then
				warn(string.format("[Maps] %s failed to build: %s", place.id, tostring(err)))
			end
			local look = LOOKS[place.id]
			if look then
				dress(model, place, centre, look)
			end
			local extra = EXTRAS[place.id]
			if extra then
				extra(model, place, centre)
			end
			model.Parent = root
		end
	end
	root.Parent = Workspace
	folder = root

	travelRemote = Net.event(Net.Names.Travel)
	local remote = travelRemote :: RemoteEvent
	local lastRefusal: { [Player]: number } = {}
	remote.OnServerEvent:Connect(function(player: Player, id: unknown)
		local ok, why = WorldMaps.travel(player, id)
		if ok then
			-- (Where it landed, as the server calls it: "Lab:<your own>" arrives as "Lab".)
			remote:FireClient(player, "Arrived", player:GetAttribute("Place"))
		elseif os.clock() - (lastRefusal[player] or -math.huge) >= 1 then
			-- (One reply a second: a flood of bad requests gets no flood back.)
			lastRefusal[player] = os.clock()
			remote:FireClient(player, "Refused", why)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRefusal[player] = nil
	end)
	local function track(player: Player)
		local home = if Lab.plotIndex(player) then "Lab" else "Plaza"
		player:SetAttribute("Place", home)
		player.CharacterAdded:Connect(function()
			-- A fresh avatar starts in its own lab (the plaza without one).
			player:SetAttribute("Place", if Lab.plotIndex(player) then "Lab" else "Plaza")
		end)
	end
	for _, player in Players:GetPlayers() do
		track(player)
	end
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(player)
		lastTrip[player] = nil
	end)
	-- On the ground you walk from your lab to the plaza or a neighbour's lab without a trip: twice
	-- a second, whoever is on the ground is told where they are now.
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local current = player:GetAttribute("Place")
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if (current == nil or Places.onGround(current)) and root and root:IsA("BasePart") then
					local now = groundPlace(player, root.Position)
					if now and now ~= current then
						player:SetAttribute("Place", now)
					end
				end
			end
		end
	end)
	local count = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			count += 1
		end
	end
	log.info(string.format("%d places built (%d parts)", #root:GetChildren(), count))
end

return WorldMaps
