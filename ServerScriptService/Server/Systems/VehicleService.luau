--!strict
-- v3, Phase C (19 Nov 2026; research: "vehicle into the crowd" is one of the top video formats and
-- every leader sells cars): cars in every lab. A family car and a monster truck stand on their pads
-- on the lab's east side; walk up and press the prompt (or sit in) to drive.
--   Driving is the driver's screen (Client\VehicleClient): the car's body belongs to the driver
--   while someone sits in it (network owner), so steering is instant. Nothing new is trusted: a car
--   is a moving unanchored body like a built machine, so the lab owner's screen knocks the dummies
--   it hits through the same rule (PropContacts machine hits, HitMath.MACHINE_MAX_SPEED).
--   The server keeps them tidy: an empty car that has fallen, flipped or wandered off goes back to
--   its pad; a car never leaves its lab's floor.
-- Everything is built by code (parts only), so the place file needs nothing new.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local VehicleService = {}

export type Kind = string -- "Car" or "Truck" (a key of SPECS)

type Spec = {
	label: string,
	body: Vector3,
	color: Color3,
	wheel: number, -- wheel diameter
	lift: number, -- body bottom over the floor
	pad: Vector2, -- where it stands (lab space, x and z)
	look: string?, -- (V9-NOW 26) the V3Assets model drawn over it
	flip: boolean?, -- (0.37.13) the model faces backwards from its import: turned round
}

VehicleService.SPECS = {
	-- (V9-NOW 26, owner 21 Nov 2026: "new cars that people think are cool": the "Car" is now an open-top off-road jeep and a
	-- go-kart joins; Creator Store models (cleaned: no scripts), driven by our own drive, cockpit and rules.)
	-- (Owner, 21 Nov 2026: "cars with the brands kids love": the Car is a lime supercar, the jeep has its own pad.)
	-- (session v849, owner: "ryk rundt på tingene så de står psykologisk bedst"): vehicles split into two
	-- zones so the player sees MORE vehicles the further they explore (progression hook):
	--   * Zone B (near spawn): Kart and Supercar — fast dopamine, flashy, to the sides of the spawn's
	--     front view.
	--   * Zone C (far): Jeep, MuscleCar, Truck — the row on the east stays as a vehicle garage.
	-- 0.37.12 (owner, 22 Nov 2026: "remove the cars completely, put in these, they must cost Robux"): three Creator Store
	-- models (ServerStorage.V3Assets Silvia, FordTruck, Panzer; every script, sound and light stripped), on the kinds the
	-- drive tuning already has (Config.VEHICLES Car, Truck, MuscleCar). Each needs its game pass (PASSES) to drive.
	Car = { label = "Silvia Drift Car", body = Vector3.new(6.4, 1.4, 14), color = Color3.fromRGB(230, 230, 235), wheel = 2.6, lift = 0.6, pad = Vector2.new(62, -8), look = "Silvia", flip = true } :: Spec,
	-- (session v850, owner: "fjern Jeepen"): the Jeep slot was dropped — four vehicles left (Supercar,
	-- Kart, Truck, MuscleCar). All lookups of "Jeep" in Shop, Progression, VehicleFeel, Assets etc. are
	-- safe since SPECS[kind] returns nil and those systems iterate or key-check.
	Truck = { label = "Ford Truck", body = Vector3.new(8.4, 2.2, 19), color = Color3.fromRGB(60, 70, 90), wheel = 3.4, lift = 1.2, pad = Vector2.new(68, -32), look = "FordTruck", flip = true } :: Spec,
	-- (session v842: 5th slot — 70s muscle car. Look model Phoenix Slayer (8x5x20), script-stripped, chassis-compatible wheel names FL/FR/RL/RR.)
	-- (23 Nov 2026: the owner's bike, a ragdoll rides it round the lab: BikeService.)
	Bike = { label = "Bike", body = Vector3.new(2.4, 1.6, 6.4), color = Color3.fromRGB(40, 42, 48), wheel = 2.4, lift = 0.85, pad = Vector2.new(27, -12), look = "Bike" } :: Spec,
	-- (F76: the FREE bicycle, a Creator Store model (V3Assets "Bicycle", 3 meshes, no scripts) on the plan's BikeStand2.)
	Bicycle = { label = "Bicycle", body = Vector3.new(2.4, 1.2, 6.4), color = Color3.fromRGB(60, 120, 200), wheel = 2.2, lift = 0.9, pad = Vector2.new(30, -14), look = "Bicycle" } :: Spec,
	-- (Row 14 WHEELCHAIRS: 3 free wheelchairs in a row by the boxing ring (Creator Store 16829312238, 1 mesh, no scripts; V3Assets
	-- "Wheelchair"). Drive one yourself; slow, about 18.)
	Wheelchair = { label = "Wheelchair", body = Vector3.new(2.6, 1, 3.4), color = Color3.fromRGB(40, 40, 44), wheel = 1.6, lift = 0.6, pad = Vector2.new(20, -20), look = "Wheelchair" } :: Spec,
	Wheelchair2 = { label = "Wheelchair", body = Vector3.new(2.6, 1, 3.4), color = Color3.fromRGB(40, 40, 44), wheel = 1.6, lift = 0.6, pad = Vector2.new(24, -20), look = "Wheelchair" } :: Spec,
	Wheelchair3 = { label = "Wheelchair", body = Vector3.new(2.6, 1, 3.4), color = Color3.fromRGB(40, 40, 44), wheel = 1.6, lift = 0.6, pad = Vector2.new(28, -20), look = "Wheelchair" } :: Spec,
	-- F76 (owner 27 Nov: "build them fully now"; Config.NEW_VEHICLES): the 5 new paid vehicles, built from parts in our
	-- own code (no store scripts), each with its feature on ONE button (VehicleAction): SOON until the owner's pass ids.
	GoKart = { label = "Go-Kart", body = Vector3.new(4.4, 0.8, 7), color = Color3.fromRGB(255, 120, 20), wheel = 1.7, lift = 0.25, pad = Vector2.new(40, -14) } :: Spec,
	Police = { label = "Police Car", body = Vector3.new(6.6, 1.6, 15), color = Color3.fromRGB(245, 245, 248), wheel = 2.6, lift = 0.6, pad = Vector2.new(46, -14) } :: Spec,
	MonsterTruck = { label = "Monster Truck", body = Vector3.new(8.6, 2.2, 15), color = Color3.fromRGB(70, 200, 60), wheel = 5.6, lift = 3.2, pad = Vector2.new(52, -14) } :: Spec,
	Bulldozer = { label = "Bulldozer", body = Vector3.new(8, 2.6, 12), color = Color3.fromRGB(250, 196, 20), wheel = 2.8, lift = 0.5, pad = Vector2.new(58, -14) } :: Spec,
	FireTruck = { label = "Fire Truck", body = Vector3.new(7.6, 2.4, 20), color = Color3.fromRGB(215, 30, 30), wheel = 3, lift = 0.8, pad = Vector2.new(64, -14) } :: Spec,
	MuscleCar = { label = "Panzer Tank", body = Vector3.new(11, 2.6, 23), color = Color3.fromRGB(90, 96, 80), wheel = 3, lift = 0.9, pad = Vector2.new(66, -60), look = "Panzer" } :: Spec,
}

-- 0.37.12: the game pass that unlocks each vehicle (the owner creates them on the dashboard and sends the ids).
-- 0 = no pass yet: free to drive until the id is filled in.
VehicleService.PASSES = { Car = 2092302232, Truck = 0, MuscleCar = 2093220108, Bike = 0, Bicycle = 0, Wheelchair = 0, Wheelchair2 = 0, Wheelchair3 = 0 } -- (24 Nov 2026, owner: they cost Robux again, the Ford is free (its pass: 2092632252); the bike the ragdoll rides stays free) -- (Silvia, Ford, Panzer; owner 22 Nov 2026) :: { [string]: number }
for _, k in { "GoKart", "Police", "MonsterTruck", "Bulldozer", "FireTruck" } do
	VehicleService.PASSES[k] = VehicleService.PASSES[k] or 0
end
-- (F76: a kind here with pass 0 is SOON: it stands in its bay and cannot be driven until the owner sends its pass id;
-- never free by mistake. Suggested prices: go-kart 49, police car 99, monster truck 149, bulldozer 149, fire truck 199.)
VehicleService.SOON = { GoKart = true, Police = true, MonsterTruck = true, Bulldozer = true, FireTruck = true } :: { [string]: boolean }
-- The feature each kind has (VehicleAction): one button while you drive.
VehicleService.FEATURE = { GoKart = "Boost", MonsterTruck = "Jump", Police = "Siren", FireTruck = "Spray", Bulldozer = "Blade" } :: { [string]: string }
local MarketplaceService = game:GetService("MarketplaceService")
-- (F76: only the bicycle and the dirt bike are free now. The Ford's pass 2092632252 is used when Roblox says it is for
-- sale; else the Ford stays free as before and the owner is asked (NOW.md).)
VehicleService.FORD_PASS = 2092632252
VehicleService.PRICES = {} :: { [string]: number } -- (Robux per kind, read once for the plaques; 0 = free)
task.spawn(function()
	if not (Config :: any).ENTRANCE_ROW then
		return
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(VehicleService.FORD_PASS, Enum.InfoType.GamePass)
	end)
	if ok and info and info.IsForSale then
		VehicleService.PASSES.Truck = VehicleService.FORD_PASS
	end
	for kind, id in VehicleService.PASSES do
		if id > 0 then
			local ok2, i2 = pcall(function()
				return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)
			end)
			VehicleService.PRICES[kind] = if ok2 and i2 and i2.PriceInRobux then i2.PriceInRobux else 0
		else
			VehicleService.PRICES[kind] = 0
		end
	end
end)
local owned: { [Player]: { [number]: boolean } } = {}
game:GetService("Players").PlayerRemoving:Connect(function(p)
	owned[p] = nil
end)
-- Whether `player` may drive `kind` (asks Roblox once per pass, then remembers; a failed ask says no this time).
function VehicleService.mayDrive(player: Player, kind: string): boolean
	local id = VehicleService.PASSES[kind] or 0
	if id <= 0 then
		return not VehicleService.SOON[kind] -- (F76: 0 = SOON for the new kinds, never free by mistake)
	end
	local mine = owned[player] or {}
	owned[player] = mine
	if mine[id] then
		return true
	end
	local ok, has = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	if ok and has then
		mine[id] = true
		return true
	end
	return false
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, bought)
	if bought then
		local mine = owned[player] or {}
		owned[player] = mine
		mine[id] = true
	end
end)

VehicleService.HORN_GAP = 0.8 -- s between two honks
VehicleService.RUN_OVER_SPEED = 14 -- studs/s: a car this fast that meets a dummy is the driver's hit (a KO when it falls)
VehicleService.RUN_OVER_STEP = 0.1 -- s between two looks
VehicleService.RUN_OVER_PAD = Vector3.new(3, 4, 3) -- studs round the driving box
VehicleService.SEAT_SINK = 0.15 -- studs the hips sink into the cushion (V9-NOW 16: never floating over it)

local DARK = Color3.fromRGB(26, 26, 30)
local GLASS = Color3.fromRGB(150, 190, 220)

type Car = { model: Model, body: BasePart, seat: VehicleSeat, home: CFrame, origin: Vector3, kind: Kind, idleSince: number, badSince: number, ejecting: boolean }
local cars: { Car } = {}

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function piece(model: Model, body: BasePart, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Massless = true
	p.CanTouch = true
	p.Parent = model
	weld(body, p)
	return p
end

-- One car, built facing -Z (towards the dummies) at `home` (the body's middle).
-- v4 C2: which wheel a piece of a car model belongs to ("FL", "FR", "RL", "RR"), or nil when it is
-- not a wheel. A piece is a wheel when it or a parent (up to the model) is named like one (wheel,
-- tire, tyre, rim, hub, a corner name, the truck pack's "CCW" rims) and sits out at a side.
local WHEEL_WORDS = { "wheel", "tire", "tyre", "rim", "hub", "ccw" }
local CORNER_NAMES = { fl = true, fr = true, rl = true, rr = true, lf = true, rf = true, lr = true }
function VehicleService.wheelCorner(part: BasePart, body: BasePart): string?
	local named = false
	local node: Instance? = part
	for _ = 1, 4 do
		if not node or node.Name == "Look" then
			break
		end
		local n = string.lower(node.Name)
		if CORNER_NAMES[n] then
			named = true
			break
		end
		for _, word in WHEEL_WORDS do
			if string.find(n, word, 1, true) and not string.find(n, "steering", 1, true) then
				named = true
				break
			end
		end
		if named then
			break
		end
		node = node.Parent
	end
	if not named then
		return nil
	end
	local at = body.CFrame:PointToObjectSpace(part.Position)
	if math.abs(at.X) < body.Size.X * 0.22 or math.abs(at.Z) < body.Size.Z * 0.12 then
		return nil -- (in the middle: a steering wheel, a spare, an axle)
	end
	return (if at.Z < 0 then "F" else "R") .. (if at.X < 0 then "L" else "R")
end

-- F76: the look of the 5 new vehicles (parts only, welded to the body; small ones not colliding, no shadow).
local function decorate(kind: string, model: Model, body: BasePart, home: CFrame, spec: Spec)
	local b = spec.body
	local function deco(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
		local p = piece(model, body, name, size, cf, color, material, shape)
		p.CanCollide = false
		p.CastShadow = false
		p.Massless = true
		return p
	end
	local top = home * CFrame.new(0, b.Y / 2, 0)
	if kind == "GoKart" then
		-- low and open: a seat back, a steering column, two exhaust pipes (the BOOST flames come out of them)
		deco("SeatBack", Vector3.new(2, 2, 0.4), top * CFrame.new(0, 1, 1.4), DARK)
		deco("Column", Vector3.new(0.3, 1.6, 0.3), top * CFrame.new(0, 0.7, -1.2) * CFrame.Angles(math.rad(-30), 0, 0), DARK)
		for _, sx in { -1, 1 } do
			local pipe = deco("Exhaust", Vector3.new(1.2, 0.45, 0.45), home * CFrame.new(sx * 0.9, 0.2, b.Z / 2 + 0.4) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(170, 170, 175), Enum.Material.Metal, Enum.PartType.Cylinder)
			local fire = Instance.new("Fire")
			fire.Name = "BoostFlame"
			fire.Size = 3
			fire.Heat = 6
			fire.Enabled = false
			fire.Parent = pipe
		end
		deco("Stripe", Vector3.new(0.6, 0.05, b.Z - 0.4), top * CFrame.new(0, 0.03, 0), Color3.fromRGB(20, 20, 24))
	elseif kind == "Police" then
		-- black doors and bonnet, a light bar on the roof (red and blue), POLICE on the sides
		for _, sx in { -1, 1 } do
			deco("Door", Vector3.new(0.12, b.Y * 0.8, b.Z * 0.42), home * CFrame.new(sx * (b.X / 2 + 0.05), 0, 0), Color3.fromRGB(20, 22, 28))
			local plate = deco("Word", Vector3.new(0.1, 0.9, 4), home * CFrame.new(sx * (b.X / 2 + 0.12), 0.1, 0), Color3.fromRGB(20, 22, 28))
			local g = Instance.new("SurfaceGui")
			g.Face = if sx > 0 then Enum.NormalId.Right else Enum.NormalId.Left
			g.CanvasSize = Vector2.new(400, 90)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(1, 1)
			t.Font = Enum.Font.FredokaOne
			t.TextScaled = true
			t.TextColor3 = Color3.new(1, 1, 1)
			t.Text = "POLICE"
			t.Parent = g
			g.Parent = plate
		end
		local roofY = b.Y / 2 + 4.4 + 0.35
		local bar = home * CFrame.new(0, roofY, b.Z * 0.08)
		deco("LightBarBase", Vector3.new(4.2, 0.3, 1), bar, DARK)
		deco("SirenRed", Vector3.new(1.8, 0.5, 0.9), bar * CFrame.new(-1, 0.35, 0), Color3.fromRGB(120, 20, 20), Enum.Material.Neon)
		deco("SirenBlue", Vector3.new(1.8, 0.5, 0.9), bar * CFrame.new(1, 0.35, 0), Color3.fromRGB(20, 40, 120), Enum.Material.Neon)
	elseif kind == "MonsterTruck" then
		-- big struts down to the huge wheels, a roll bar, flames painted on the side
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				deco("Strut", Vector3.new(0.6, spec.lift + 0.8, 0.6), home * CFrame.new(sx * (b.X / 2 - 0.6), -b.Y / 2 - spec.lift / 2, sz * (b.Z / 2 - spec.wheel * 0.55)), DARK)
			end
			deco("Flame", Vector3.new(0.08, b.Y * 0.5, b.Z * 0.5), home * CFrame.new(sx * (b.X / 2 + 0.04), 0, -b.Z * 0.1), Color3.fromRGB(255, 140, 20), Enum.Material.Neon)
		end
	elseif kind == "Bulldozer" then
		-- tracks along both sides, an exhaust stack, and the BLADE in front (a weld the server lifts and lowers)
		for _, sx in { -1, 1 } do
			deco("Track", Vector3.new(1.6, spec.wheel + 0.4, b.Z + 0.6), home * CFrame.new(sx * (b.X / 2 + 0.6), -b.Y / 2 - spec.lift + spec.wheel / 2, 0), Color3.fromRGB(30, 30, 32), Enum.Material.DiamondPlate)
		end
		deco("Stack", Vector3.new(0.5, 3, 0.5), top * CFrame.new(b.X * 0.3, 1.5, -b.Z * 0.3), DARK, Enum.Material.Metal)
		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(b.X + 2.4, 3.2, 0.6)
		blade.Color = Color3.fromRGB(120, 110, 90)
		blade.Material = Enum.Material.Metal
		blade.CFrame = home * CFrame.new(0, -b.Y / 2 + 0.9, -b.Z / 2 - 1.6) * CFrame.Angles(math.rad(-10), 0, 0)
		blade.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.1, 1, 1)
		blade.Parent = model
		local w = Instance.new("Weld")
		w.Name = "BladeWeld"
		w.Part0 = body
		w.Part1 = blade
		w.C0 = body.CFrame:ToObjectSpace(blade.CFrame)
		w.Parent = blade
		w:SetAttribute("Down", true)
		for _, sx in { -1, 1 } do
			deco("BladeArm", Vector3.new(0.4, 0.4, 2.4), home * CFrame.new(sx * (b.X / 2 - 0.6), -b.Y / 2 + 1.2, -b.Z / 2 - 0.6), DARK)
		end
	elseif kind == "FireTruck" then
		-- a ladder on the roof, chrome stripes, and the WATER CANNON on top at the front
		local roofY = b.Y / 2 + 4.4 + 0.4
		for _, sx in { -1, 1 } do
			deco("LadderRail", Vector3.new(0.25, 0.25, b.Z * 0.7), home * CFrame.new(sx * 0.9, roofY, b.Z * 0.12), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
			deco("Stripe", Vector3.new(0.08, 0.4, b.Z - 1), home * CFrame.new(sx * (b.X / 2 + 0.04), -0.2, 0), Color3.fromRGB(235, 235, 240), Enum.Material.Metal)
		end
		for k = 0, 8 do
			deco("LadderRung", Vector3.new(1.8, 0.15, 0.15), home * CFrame.new(0, roofY, b.Z * 0.12 - b.Z * 0.33 + k * b.Z * 0.0825), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
		end
		local cannon = deco("WaterCannon", Vector3.new(2.4, 0.6, 0.6), home * CFrame.new(0, roofY + 0.5, -b.Z * 0.28) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(200, 200, 205), Enum.Material.Metal, Enum.PartType.Cylinder)
		local att = Instance.new("Attachment")
		att.Name = "Nozzle"
		att.Position = Vector3.new(1.3, 0, 0)
		att.Parent = cannon
		local jet = Instance.new("ParticleEmitter")
		jet.Name = "WaterJet"
		jet.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		jet.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
		jet.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) })
		jet.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.9) })
		jet.Speed = NumberRange.new(60, 75)
		jet.Lifetime = NumberRange.new(0.45, 0.6)
		jet.Rate = 160
		jet.SpreadAngle = Vector2.new(4, 4)
		jet.Acceleration = Vector3.new(0, -60, 0)
		jet.EmissionDirection = Enum.NormalId.Right
		jet.Enabled = false
		jet.Parent = att
	end
end

local function make(kind: Kind, home: CFrame): (Model, BasePart, VehicleSeat)
	local spec = VehicleService.SPECS[kind]
	local model = Instance.new("Model")
	model.Name = "Lab" .. kind
	local b = spec.body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = b
	body.CFrame = home
	body.Color = spec.color
	body.Material = Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	-- (Heavy: it shoves a dummy aside instead of riding up on it.)
	body.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.3, 0.1, 1, 1)
	body.Parent = model
	model.PrimaryPart = body
	local top = home * CFrame.new(0, b.Y / 2, 0)
	-- The cabin: a roof on four pillars with a windscreen, open at the sides so the driver shows.
	local cabinH, cabinZ = 4.4, b.Z * 0.45 -- (tall enough for a seated avatar's head)
	local cabinCf = top * CFrame.new(0, cabinH / 2, b.Z * 0.08)
	piece(model, body, "Roof", Vector3.new(b.X - 0.4, 0.35, cabinZ), cabinCf * CFrame.new(0, cabinH / 2, 0), spec.color)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			piece(model, body, "Pillar", Vector3.new(0.35, cabinH, 0.35), cabinCf * CFrame.new(sx * (b.X / 2 - 0.4), 0, sz * (cabinZ / 2 - 0.2)), spec.color).CanCollide = false
		end
	end
	piece(model, body, "Windscreen", Vector3.new(b.X - 0.9, cabinH * 0.9, 0.15), cabinCf * CFrame.new(0, 0.05, -cabinZ / 2 + 0.2), GLASS, Enum.Material.Glass).Transparency = 0.45
	piece(model, body, "Bumper", Vector3.new(b.X + 0.2, 0.7, 0.6), home * CFrame.new(0, -b.Y * 0.2, -b.Z / 2 - 0.2), DARK)
	piece(model, body, "Bumper", Vector3.new(b.X + 0.2, 0.7, 0.6), home * CFrame.new(0, -b.Y * 0.2, b.Z / 2 + 0.2), DARK)
	for _, side in { -1, 1 } do
		piece(model, body, "Headlight", Vector3.new(1, 0.5, 0.2), home * CFrame.new(side * (b.X / 2 - 0.9), 0.2, -b.Z / 2 - 0.05), Color3.fromRGB(255, 250, 225), Enum.Material.Neon)
		piece(model, body, "Taillight", Vector3.new(1, 0.4, 0.2), home * CFrame.new(side * (b.X / 2 - 0.9), 0.2, b.Z / 2 + 0.05), Color3.fromRGB(220, 40, 40), Enum.Material.Neon)
	end
	-- Wheels (they slide; the driver's screen moves the car: VehicleClient).
	local d = spec.wheel
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local at = home * CFrame.new(sx * (b.X / 2 + 0.2), -b.Y / 2 - spec.lift + d / 2, sz * (b.Z / 2 - d * 0.55))
			-- (A cylinder's axis is its X: sideways across the car, as a wheel's.)
			local w = piece(model, body, "Wheel", Vector3.new(d * 0.45, d, d), at, DARK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			w.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.05, 0.1, 1, 1)
			piece(model, body, "Hub", Vector3.new(d * 0.47, d * 0.45, d * 0.45), at, Color3.fromRGB(200, 200, 205), Enum.Material.Metal, Enum.PartType.Cylinder).CanCollide = false
		end
	end
	if kind == "Truck" then
		-- Struts from the body down to the big wheels, so it reads as lifted.
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				piece(model, body, "Strut", Vector3.new(0.5, spec.lift + 0.6, 0.5), home * CFrame.new(sx * (b.X / 2 - 0.6), -b.Y / 2 - spec.lift / 2, sz * (b.Z / 2 - d * 0.55)), DARK).CanCollide = false
			end
		end
	end
	decorate(kind, model, body, home, spec)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.CFrame = top * CFrame.new(0, 0.5, b.Z * 0.12)
	seat.Transparency = 1
	seat.CanCollide = false
	seat.Massless = true
	seat.MaxSpeed = 0 -- (the legacy drive is off: VehicleClient drives)
	seat.HeadsUpDisplay = false
	seat.Torque = 0
	seat:SetAttribute("LabCar", kind)
	seat.Parent = model
	weld(body, seat)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Drive"
	prompt.ActionText = "Drive"
	prompt.ObjectText = spec.label
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player: Player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		-- (0.37.12: locked behind its game pass: Roblox's own buy window instead of the seat.)
		if not VehicleService.mayDrive(player, kind) then
			if (VehicleService.PASSES[kind] or 0) > 0 then
				MarketplaceService:PromptGamePassPurchase(player, VehicleService.PASSES[kind])
			end
			return
		end
		if humanoid and humanoid.Health > 0 and not seat.Occupant and humanoid.SeatPart == nil then
			seat:Sit(humanoid)
		end
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		prompt.Enabled = seat.Occupant == nil
		-- (0.37.12: whoever got in without the pass, by jumping on the seat, is put out again.)
		local h = seat.Occupant
		local p = h and game:GetService("Players"):GetPlayerFromCharacter(h.Parent)
		if h and p and not VehicleService.mayDrive(p, kind) then
			local sw = seat:FindFirstChild("SeatWeld")
			if sw then
				sw:Destroy()
			end
			h.Sit = false
			if (VehicleService.PASSES[kind] or 0) > 0 then
				MarketplaceService:PromptGamePassPurchase(p, VehicleService.PASSES[kind])
			end
		end
	end)
	-- v3: a real car model over the driving box when the place has one (V3Assets "Car" /
	-- "MonsterTruck"): welded on, weightless and without collisions; the code-built shell goes
	-- see-through but keeps doing the physics.
	local V3Assets = require(script.Parent.V3Assets)
	local role = spec.look or (if kind == "Truck" then "MonsterTruck" else "Car")
	local bottom = home * CFrame.new(0, -b.Y / 2 - spec.lift, 0)
	if spec.flip then
		bottom *= CFrame.Angles(0, math.pi, 0) -- (0.37.13, owner: "you drive the Ford and the Silvia backwards")
	end
	local look = V3Assets.place(role, model, bottom, { size = b.Z + 1.5, collide = false, anchored = false, name = "Look" })
	if look then
		-- (22 Nov 2026, owner: "sit the right way in the go-kart"): the model's own seats never take a
		-- rider (the kart's faced backwards); only our Seat does, and it faces where the car drives.
		for _, d in look:GetDescendants() do
			if d:IsA("Seat") or d:IsA("VehicleSeat") then
				d.Disabled = true
				d.CanTouch = false
			end
		end
		-- v4 C2: the wheels hang on Welds (each screen turns and steers them: Client/VehicleFeel) and
		-- the rest of the shell on one invisible root whose Weld the screens tilt a little (body roll
		-- and dive). Pictures only; the code-built box does the physics.
		local root = Instance.new("Part")
		root.Name = "LookRoot"
		root.Size = Vector3.new(1, 1, 1)
		root.CFrame = body.CFrame
		root.Transparency = 1
		root.CanCollide = false
		root.CanQuery = false
		root.CanTouch = false
		root.Massless = true
		root.Parent = model
		local rollWeld = Instance.new("Weld")
		rollWeld.Name = "RollWeld"
		rollWeld.Part0 = body
		rollWeld.Part1 = root
		rollWeld.Parent = root
		-- (24 Nov 2026, fps: the cars' hundreds of pieces were three quarters of every shadow drawn; the four largest
		-- throw the car's whole shadow.)
		local shadows: { BasePart } = {}
		for _, d in look:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 0.9 then
				table.insert(shadows, d)
			end
		end
		table.sort(shadows, function(x, y)
			return x.Size.X * x.Size.Y * x.Size.Z > y.Size.X * y.Size.Y * y.Size.Z
		end)
		for i, d in shadows do
			if i > 4 then
				d.CastShadow = false
			end
		end
		local corners: { [string]: { min: Vector3, max: Vector3 } } = {}
		for _, shell in look:GetDescendants() do
			if shell:IsA("BasePart") then
				shell.Massless = true
				local corner = VehicleService.wheelCorner(shell, body)
				if corner then
					local w = Instance.new("Weld")
					w.Name = "WheelWeld"
					w.Part0 = body
					w.Part1 = shell
					w.C0 = body.CFrame:ToObjectSpace(shell.CFrame)
					w:SetAttribute("Corner", corner)
					w:SetAttribute("BaseC0", w.C0)
					w.Parent = shell
					local local_ = body.CFrame:PointToObjectSpace(shell.Position)
					local half = shell.Size / 2
					local box = corners[corner] or { min = local_, max = local_ }
					box.min = box.min:Min(local_ - Vector3.new(0, half.Y, 0))
					box.max = box.max:Max(local_ + Vector3.new(0, half.Y, 0))
					corners[corner] = box
				else
					weld(root, shell)
				end
			end
		end
		-- v4 C2: the driver sits in the model's own driver's seat (not on the box's roof).
		local driverSpot: BasePart? = nil
		for _, d in look:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "VehicleSeat" or d.Name == "DriveSeat" or d.Name == "SeatFL" or d.Name == "DriverSeat") then
				driverSpot = d
				break
			end
		end
		if driverSpot then
			for _, c in seat:GetChildren() do
				if c:IsA("WeldConstraint") then
					c:Destroy()
				end
			end
			-- (V9-NOW 16, owner 21 Nov 2026: "sit properly": the seat's top on the cushion's top, so the hips rest on
			-- it, not 0.7 studs over its middle (floating) nor in it. The cushion's top is its highest face along
			-- the car's up.)
			local up = body.CFrame.UpVector
			local half = driverSpot.Size / 2
			local rise = math.abs(driverSpot.CFrame.RightVector:Dot(up)) * half.X + math.abs(driverSpot.CFrame.UpVector:Dot(up)) * half.Y
				+ math.abs(driverSpot.CFrame.LookVector:Dot(up)) * half.Z
			local top = driverSpot.Position + up * rise
			local at = body.CFrame:PointToObjectSpace(top)
			if kind == "Bike" then
				at += Vector3.new(0, -0.62, -0.25) -- (its saddle slopes: the box's top is well over the cushion)
			end
			-- (session v850, owner: "fiks så man vender den rigtige vej i bilen"): the look model's own driver
			-- seat could point to the rear (its DriverSeat/SeatFL inherited whichever way the import pivoted).
			-- The humanoid sits facing the seat's +LookVector; the car drives along its body's +LookVector
			-- (its wheels push it that way). We force the seat to look the same way, so the driver always
			-- faces where the car goes.
			local pos = body.CFrame:PointToWorldSpace(at - Vector3.new(0, seat.Size.Y / 2 + VehicleService.SEAT_SINK, 0))
			seat.CFrame = CFrame.lookAt(pos, pos + body.CFrame.LookVector, body.CFrame.UpVector)
			weld(body, seat)
		end
		-- Each wheel's axle (body space) and radius, for the screens.
		for corner, box in corners do
			model:SetAttribute("Axle" .. corner, (box.min + box.max) / 2)
			model:SetAttribute("Radius" .. corner, math.max(0.5, (box.max.Y - box.min.Y) / 2))
		end
		-- Lights: two headlamps and a brake glow (the screens switch them by distance and braking).
		local b2 = spec.body
		for _, side in { -1, 1 } do
			local a = Instance.new("Attachment")
			a.Name = "HeadlampAt"
			a.Position = Vector3.new(side * (b2.X / 2 - 0.9), 0.2, -b2.Z / 2 - 0.3)
			a.Parent = body
			local lamp = Instance.new("SpotLight")
			lamp.Name = "Headlamp"
			lamp.Face = Enum.NormalId.Front
			lamp.Angle = 70
			lamp.Range = 28
			lamp.Brightness = 2.5
			lamp.Color = Color3.fromRGB(255, 244, 220)
			lamp.Enabled = false
			lamp.Parent = a
		end
		local rear = Instance.new("Attachment")
		rear.Name = "BrakeAt"
		rear.Position = Vector3.new(0, 0.2, b2.Z / 2 + 0.4)
		rear.Parent = body
		local brake = Instance.new("PointLight")
		brake.Name = "BrakeLight"
		brake.Color = Color3.fromRGB(255, 40, 30)
		brake.Range = 10
		brake.Brightness = 0
		brake.Enabled = false
		brake.Parent = rear
		-- The horn (the server plays it, so everyone near hears it: VehicleService "Horn").
		local horn = Instance.new("Sound")
		horn.Name = "Horn"
		horn.SoundId = "rbxassetid://" .. tostring((Config.VEHICLES :: any).hornSound)
		horn.Volume = 0.8
		horn.RollOffMaxDistance = 220
		horn.Parent = body
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and p ~= seat then
				p.Transparency = 1
			end
		end
	end
	model:SetAttribute("Vehicle", kind)
	game:GetService("CollectionService"):AddTag(model, "LabVehicle") -- (v4 C2: Client/VehicleFeel finds them by it)
	return model, body, seat
end

local function ownerFor(car: Car): Player?
	local occupant = car.seat.Occupant
	if occupant then
		return Players:GetPlayerFromCharacter(occupant.Parent)
	end
	local Lab = require(script.Parent.Lab)
	return Lab.ownerAt(car.origin)
end

local function setOwner(car: Car)
	if not car.body:CanSetNetworkOwnership() then
		return
	end
	local owner = ownerFor(car)
	pcall(function()
		car.body:SetNetworkOwner(owner)
	end)
end

local function home(car: Car)
	car.body.AssemblyLinearVelocity = Vector3.zero
	car.body.AssemblyAngularVelocity = Vector3.zero
	car.model:PivotTo(car.home)
	car.idleSince = os.clock()
	car.badSince = 0
	setOwner(car)
end

-- V10 phase 3 (owner: "cars can be destroyed by shooting them enough or with a bomb: they explode and come back
-- on their pad"): each car has HP; a shot near its body takes 1, a blast in reach takes BLAST_DAMAGE. At 0 it
-- explodes (the driver is thrown out), vanishes, and after RESPAWN s stands on its pad again, whole.
VehicleService.HP = 20
VehicleService.BLAST_DAMAGE = 20
VehicleService.RESPAWN = 5
local function nearestCar(point: Vector3, reach: number): Car?
	local best: Car? = nil
	local bestD = math.huge
	for _, car in cars do
		if car.body.Parent and not (car :: any).wrecked then
			local d = (car.body.Position - point).Magnitude - car.body.Size.Magnitude / 2
			if d < reach and d < bestD then
				best, bestD = car, d
			end
		end
	end
	return best
end
local function wreck(car: Car)
	local c = car :: any
	c.wrecked = true
	local at = car.body.Position
	local boom = Instance.new("Explosion")
	boom.BlastPressure = 0
	boom.DestroyJointRadiusPercent = 0
	boom.BlastRadius = 12
	boom.Position = at
	boom.Parent = Workspace
	pcall(function()
		(require(script.Parent:WaitForChild("FxService")) :: any).hit(at, 200, "CannonPad")
	end)
	local sw = car.seat:FindFirstChild("SeatWeld")
	if sw then
		sw:Destroy()
	end
	local saved: { [BasePart]: number } = {}
	local collided: { [BasePart]: boolean } = {}
	for _, d in car.model:GetDescendants() do
		if d:IsA("BasePart") then
			saved[d] = d.Transparency
			collided[d] = d.CanCollide
			d.Transparency = 1
			d.CanCollide = false
		end
	end
	local prompt = car.body:FindFirstChild("Drive")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = false
	end
	task.delay(VehicleService.RESPAWN, function()
		for d, t in saved do
			if d.Parent then
				d.Transparency = t
				d.CanCollide = collided[d] == true
			end
		end
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = car.seat.Occupant == nil
		end
		home(car)
		c.hp = VehicleService.HP
		c.wrecked = false
	end)
end
function VehicleService.damageAt(point: Vector3, amount: number, reach: number?)
	local car = nearestCar(point, reach or 2)
	if not car then
		return
	end
	local c = car :: any
	c.hp = (c.hp or VehicleService.HP) - amount
	if c.hp <= 0 then
		wreck(car)
	end
end

-- The cars of one lab (Playground.build calls this for every lab, never the plaza).
-- F75 (Config.HOME_CLEAR): a vehicle's home must be clear: the motorbike stood IN the bike rack (its pad was the rack's
-- middle, among the solid bars). Once the map stands, every home is checked with the vehicle's own box; when anything
-- solid that is not the ground, a walkway or another vehicle is inside it, the home moves to the nearest clear spot (rings
-- of 6 studs out to 36) and the vehicle is set there. A count is printed ([Vehicles] homes moved: n) as the lint.
local function homeBlocked(car: any, cf: CFrame): boolean
	local size = car.body.Size
	local _, msize = car.model:GetBoundingBox()
	local box = Vector3.new(math.max(size.X, msize.X) + 1, math.max(3, msize.Y - 1), math.max(size.Z, msize.Z) + 1)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = { car.model }
	for _, n in { "Dummies", "Terrain" } do
		local x = Workspace:FindFirstChild(n)
		if x then
			table.insert(skip, x)
		end
	end
	params.FilterDescendantsInstances = skip
	for _, p in Workspace:GetPartBoundsInBox(cf + Vector3.new(0, 0.6, 0), box, params) do
		if p.CanCollide and p.Transparency < 1 and not (p.Size.Y < 1.3 and math.abs(p.CFrame.UpVector.Y) > 0.95) then
			return true
		end
	end
	return false
end
function VehicleService.homeClear(car: any): boolean
	if not homeBlocked(car, car.home) then
		return false
	end
	for r = 6, 36, 6 do
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local cf = car.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			if not homeBlocked(car, cf) then
				car.home = cf
				if car.seat.Occupant == nil then
					car.model:PivotTo(cf * car.body.CFrame:ToObjectSpace(car.model:GetPivot()))
				end
				return true
			end
		end
	end
	return false
end

function VehicleService.build(into: Folder, origin: Vector3)
	if not (Config.VEHICLES and Config.VEHICLES.enabled) then
		return
	end
	local holder = Instance.new("Folder")
	holder.Name = "Vehicles"
	holder.Parent = into
	local kinds: { Kind } = { "Car", "Truck" }
	for _, extra in { "Kart", "Jeep", "MuscleCar", "Bike", "Bicycle", "Wheelchair", "Wheelchair2", "Wheelchair3", "GoKart", "Police", "MonsterTruck", "Bulldozer", "FireTruck" } do
		if (Config.VEHICLES :: any)[extra] and VehicleService.SPECS[extra] then
			table.insert(kinds, extra)
		end
	end
	for _, kind in kinds do
		local spec = VehicleService.SPECS[kind]
		local cf = CFrame.new(origin + Vector3.new(spec.pad.X * ((Config :: any).LAB_SPREAD or 1), spec.lift + spec.body.Y / 2 + 0.1, spec.pad.Y * ((Config :: any).LAB_SPREAD or 1)))
		-- (LAB10: in its painted bay in front of the crash wall: Shared/LabLayout10.CARS.)
		local bay = (require(ReplicatedStorage.Shared:WaitForChild("LabLayout10")) :: any).car(kind)
		if bay then
			cf = CFrame.new(origin + Vector3.new(bay.X, spec.lift + spec.body.Y / 2 + 0.1, bay.Y))
			local yaw = (require(ReplicatedStorage.Shared:WaitForChild("LabLayout10")) :: any).carYaw(kind) -- (F76: the herringbone row)
			if yaw then
				cf *= CFrame.Angles(0, yaw, 0)
			end
		end
		local model, body, seat = make(kind, cf)
		model.Parent = holder
		local car: Car = { model = model, body = body, seat = seat, home = cf, origin = origin, kind = kind, idleSince = os.clock(), badSince = 0, ejecting = false }
		table.insert(cars, car)
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			car.idleSince = os.clock()
			setOwner(car)
		end)
		setOwner(car)
	end
	if (Config :: any).HOME_CLEAR then
		-- (F75: once the map and its machines stand, no home is inside anything)
		task.delay(6, function()
			local moved = 0
			for _, car in cars do
				if car.origin == origin and car.model.Parent and VehicleService.homeClear(car) then
					moved += 1
				end
			end
			print(string.format("[Vehicles] homes moved: %d", moved))
		end)
	end
	VehicleService.start()
end

local started = false
function VehicleService.start()
	if started then
		return
	end
	started = true
	local Lab = require(script.Parent.Lab)
	-- v4 C2: the horn (H, or the HORN button): only from the driver's seat, at most once per HORN_GAP.
	local Net = require(ReplicatedStorage.Shared.Net)
	local lastHorn: { [Player]: number } = {}
	-- F76 (Config.NEW_VEHICLES): the feature button. Checked: the player sits in a lab vehicle whose kind has that
	-- feature (VehicleService.FEATURE), at most one action every 0.35 s. Boost and Jump move the car on the driver's own
	-- screen (it owns the car); the server shows the flames for everyone. Siren, Spray and Blade are done here.
	local lastAction: { [Player]: number } = {}
	local sirenOn: { [Model]: boolean } = {}
	Net.event(Net.Names.VehicleAction).OnServerEvent:Connect(function(player: Player, action: unknown)
		if typeof(action) ~= "string" then
			return
		end
		local now = os.clock()
		if now - (lastAction[player] or -math.huge) < 0.35 then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local kind = seat and seat:GetAttribute("LabCar")
		if not (seat and seat:IsA("VehicleSeat") and type(kind) == "string" and VehicleService.FEATURE[kind] == action) then
			return
		end
		lastAction[player] = now
		local car = seat.Parent :: Model
		local body = car:FindFirstChild("Body") :: BasePart?
		if not body then
			return
		end
		if action == "Boost" then
			for _, f in car:GetDescendants() do
				if f:IsA("Fire") and f.Name == "BoostFlame" then
					f.Enabled = true
					task.delay(1.2, function()
						f.Enabled = false
					end)
				end
			end
		elseif action == "Siren" then
			sirenOn[car] = not sirenOn[car]
			local snd = body:FindFirstChild("Siren") :: Sound?
			if not snd then
				local s = Instance.new("Sound")
				s.Name = "Siren"
				s.SoundId = "rbxassetid://103787335792735" -- (Creator Store "main hi lo", a hi-lo police siren loop)
				s.Looped = true
				s.Volume = 0.45
				s.RollOffMaxDistance = 160
				s.Parent = body
				snd = s
			end
			if sirenOn[car] then
				(snd :: Sound):Play()
				task.spawn(function()
					local red, blue = car:FindFirstChild("SirenRed", true), car:FindFirstChild("SirenBlue", true)
					local flip = false
					while sirenOn[car] and car.Parent and seat.Occupant do
						flip = not flip
						if red and red:IsA("BasePart") then
							red.Color = if flip then Color3.fromRGB(255, 40, 40) else Color3.fromRGB(110, 20, 20)
						end
						if blue and blue:IsA("BasePart") then
							blue.Color = if flip then Color3.fromRGB(20, 40, 110) else Color3.fromRGB(60, 120, 255)
						end
						-- ragdolls within 40 studs put their hands up (the hands-up mood, 2 s at a time)
						local dummies = Workspace:FindFirstChild("Dummies")
						if dummies and flip then
							for _, m in dummies:GetChildren() do
								local pe = m:FindFirstChild("LowerTorso")
								if pe and pe:IsA("BasePart") and (pe.Position - body.Position).Magnitude < 40 and m:GetAttribute("Mood") == nil then
									m:SetAttribute("HandsUpUntil", Workspace:GetServerTimeNow() + 2)
								end
							end
						end
						task.wait(0.35)
					end
					sirenOn[car] = nil
					if snd then
						snd:Stop()
					end
				end)
			else
				(snd :: Sound):Stop()
			end
		elseif action == "Spray" then
			local jet = car:FindFirstChild("WaterJet", true)
			local cannon = car:FindFirstChild("WaterCannon", true)
			if jet and jet:IsA("ParticleEmitter") and cannon and cannon:IsA("BasePart") then
				jet.Enabled = true
				task.delay(1, function()
					jet.Enabled = false
				end)
				-- a cone 36 studs ahead of the truck: every ragdoll in it is pushed over (a water shove, no harm) and wet
				local from = cannon.Position
				local dir = body.CFrame.LookVector
				local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
				local dummies = Workspace:FindFirstChild("Dummies")
				for _, m in (if dummies then dummies:GetChildren() else {}) do
					local pe = m:FindFirstChild("UpperTorso")
					if m:IsA("Model") and pe and pe:IsA("BasePart") then
						local to = pe.Position - from
						local d = to.Magnitude
						if d < 36 and d > 0.5 and to.Unit:Dot(dir) > 0.86 then
							pcall(DC.push, m, dir * (48 - d * 0.6) + Vector3.new(0, 12, 0), player)
							m:SetAttribute("WetUntil", Workspace:GetServerTimeNow() + 20)
						end
					end
				end
			end
		elseif action == "Blade" then
			local blade = car:FindFirstChild("Blade")
			local w = blade and blade:FindFirstChild("BladeWeld")
			if w and w:IsA("Weld") then
				local down = w:GetAttribute("Down") == true
				w.C0 = w.C0 * CFrame.new(0, if down then 1.6 else -1.6, 0)
				w:SetAttribute("Down", not down)
			end
		end
	end)
	Net.event(Net.Names.VehicleHorn).OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastHorn[player] or -math.huge) < VehicleService.HORN_GAP then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if not (seat and seat:IsA("VehicleSeat") and seat:GetAttribute("LabCar") ~= nil) then
			return
		end
		lastHorn[player] = now
		local car = seat.Parent
		local body = car and car:FindFirstChild("Body")
		local horn = body and body:FindFirstChild("Horn")
		if (Config :: any).BIKE_PEDAL and seat:GetAttribute("LabCar") == "Bicycle" then
			-- (F76: the bicycle's horn button rings its bell)
			local holder = body or seat
			local bell = holder:FindFirstChild("Bell")
			if not (bell and bell:IsA("Sound")) then
				local snd = Instance.new("Sound")
				snd.Name = "Bell"
				snd.SoundId = "rbxassetid://9125390319"
				snd.Volume = 0.9
				snd.RollOffMaxDistance = 140
				snd.Parent = holder
				bell = snd
			end
			(bell :: Sound):Play()
			return
		end
		if horn and horn:IsA("Sound") then
			horn:Play()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastHorn[player] = nil
	end)
	-- (Owner, 21 Nov 2026: "running people over counts as KOs". The driver's screen knocks the dummy (PropContacts),
	-- but a takedown needs a hit the server itself saw: a car driven at RUN_OVER_SPEED+ that meets a dummy stamps
	-- the driver's hit on it, so its fall is the driver's KO, as a shot's is.)
	local Dummies = require(ReplicatedStorage.Shared.Dummies) :: any
	local DummyControl = require(script.Parent.DummyControl) :: any
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	local runAcc = 0
	local bonked: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any -- (3.17: one BONK a body per 2 s)
	RunService.Heartbeat:Connect(function(dt)
		runAcc += dt
		if runAcc < VehicleService.RUN_OVER_STEP then
			return
		end
		runAcc = 0
		local dummies = workspace:FindFirstChild("Dummies")
		if not dummies then
			return
		end
		overlap.FilterDescendantsInstances = { dummies }
		for _, car in cars do
			local occupant = car.seat.Occupant
			local driver = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
			local body = car.body
			if driver and body.Parent and body.AssemblyLinearVelocity.Magnitude >= VehicleService.RUN_OVER_SPEED then
				local seen: { [Instance]: boolean } = {}
				for _, part in workspace:GetPartBoundsInBox(body.CFrame, body.Size + VehicleService.RUN_OVER_PAD, overlap) do
					local node: Instance = part
					while node.Parent and node.Parent ~= dummies do
						node = node.Parent :: Instance
					end
					if node.Parent == dummies and node:IsA("Model") and not seen[node] and not Players:GetPlayerFromCharacter(node) then
						seen[node] = true
						Dummies.setBlame(node, driver.UserId)
						DummyControl.stampServerHit(node, driver.UserId)
						if (Config :: any).CAR_10 and os.clock() - (bonked[node] or 0) > 2 then
							-- 3.17 (docs/MACHINES_10.md "CARS"; Config.CAR_10): "BONK! 48 studs/s" over the body, NEW BEST for the
							-- driver (CarBest)
							bonked[node] = os.clock()
							local speed = math.floor(body.AssemblyLinearVelocity.Magnitude + 0.5)
							local text = "BONK! " .. tostring(speed) .. " studs/s"
							local best = (driver:GetAttribute("CarBest") :: number?) or 0
							if speed > best then
								driver:SetAttribute("CarBest", speed)
								text ..= " NEW BEST!"
							end
							local at = (part :: BasePart).Position
							pcall(function()
								(require(script.Parent:WaitForChild("Playground")) :: any).pop(at + Vector3.new(0, 4, 0), text, Color3.fromRGB(255, 200, 90))
							end)
						end
					end
				end
			end
		end
	end)
	if (Config :: any).RIDE_AIR then
		-- 3.32 (docs/MACHINES_10.md "BICYCLE, MOTORBIKE, WHEELCHAIRS"; Config.RIDE_AIR): any driven vehicle (bike,
		-- wheelchair, car) that leaves the ground for 0.6 s or more pops its air time when it lands ("AIR TIME 1.4 s"),
		-- with a NEW BEST for the driver (AirBest). The launch pads keep their own pop (they are skipped here).
		local airSince: { [any]: number } = {}
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local airAcc = 0
		RunService.Heartbeat:Connect(function(dt)
			airAcc += dt
			if airAcc < 0.1 then
				return
			end
			airAcc = 0
			for _, car in cars do
				local occupant = car.seat.Occupant
				local driver = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
				local body = car.body
				if driver and body.Parent and car.model:GetAttribute("PadLaunched") == nil then
					rayParams.FilterDescendantsInstances = { car.model, occupant.Parent :: Instance }
					local down = Workspace:Raycast(body.Position, Vector3.new(0, -(body.Size.Y / 2 + 3.5), 0), rayParams)
					local now = os.clock()
					if not down then
						airSince[car] = airSince[car] or now
					elseif airSince[car] then
						local t = now - airSince[car]
						airSince[car] = nil
						if t >= 0.6 then
							local air = math.floor(t * 10 + 0.5) / 10
							local text = "AIR TIME " .. string.format("%.1f", air) .. " s"
							local best = (driver:GetAttribute("AirBest") :: number?) or 0
							if air > best then
								driver:SetAttribute("AirBest", air)
								text ..= " NEW BEST!"
							end
							pcall(function()
								(require(script.Parent:WaitForChild("Playground")) :: any).pop(body.Position + Vector3.new(0, 5, 0), text, Color3.fromRGB(140, 220, 255))
							end)
						end
					end
				else
					airSince[car] = nil
				end
			end
		end)
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 then
			return
		end
		acc = 0
		local now = os.clock()
		local reach = Lab.PLOT_HALF - 4
		for _, car in cars do
			if not car.model.Parent then
				continue
			end
			if car.model:GetAttribute("Ridden") == true then
				car.idleSince, car.badSince = now, 0 -- (a ragdoll rides it: BikeService)
				continue
			end
			local p = car.body.Position
			local away = p - car.origin
			-- (V6-5: the creature yard in front of the lab is in play too.)
			local front = if (Config :: any).LAB_CREATURES then 112 else 75
			local off = math.abs(away.X) > reach or away.Z > front or away.Z < -96 or away.Y < -20
			if (Config :: any).CAR_STAY and (Config :: any).LAB_OWNERMAP then
				-- (F56, owner: "man bliver kicked fra bilerne": those bounds were the OLD small lab; on the big map a car is
				-- only "off" when it fell out of the world or is far beyond the map)
				off = away.Y < -20 or Vector2.new(away.X, away.Z).Magnitude > 700
			end
			local flipped = car.body.CFrame.UpVector.Y < 0.3
			if off or flipped then
				car.badSince = if car.badSince > 0 then car.badSince else now
			else
				car.badSince = 0
			end
			local occupied = car.seat.Occupant ~= nil
			if occupied then
				car.idleSince = now
				-- Off the floor with a driver: the driver gets out and the car goes home.
				if off and now - car.badSince > 0.5 and not car.ejecting then
					car.ejecting = true
					if not (Config :: any).CAR_STAY then
					-- (The seat's weld goes: that frees the driver even though their screen owns
					-- their humanoid.)
					local weld = car.seat:FindFirstChild("SeatWeld")
					if weld then
						weld:Destroy()
					end
					end
					task.delay(0.3, function()
						home(car)
						car.ejecting = false
					end)
				end
			elseif (car.badSince > 0 and now - car.badSince > (Config.VEHICLES.flippedReset or 4))
				or (now - car.idleSince > (Config.VEHICLES.idleReset or 30) and (p - car.home.Position).Magnitude > 6) then
				home(car)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(function()
			for _, car in cars do
				if car.model.Parent then
					setOwner(car)
				end
			end
		end)
	end)
end

-- Tests.
function VehicleService.carsForTest(): { Car }
	return cars
end

return VehicleService
