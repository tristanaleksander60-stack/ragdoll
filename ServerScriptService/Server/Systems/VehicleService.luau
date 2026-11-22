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
	Car = { label = "Supercar", body = Vector3.new(6.6, 1.4, 12.5), color = Color3.fromRGB(150, 220, 40), wheel = 2.6, lift = 0.6, pad = Vector2.new(45, 30), look = "SportsCar" } :: Spec, -- (session v849: moved from (66,20) to (45,30), spawn's right-front)
	-- (session v850, owner: "fjern Jeepen"): the Jeep slot was dropped — four vehicles left (Supercar,
	-- Kart, Truck, MuscleCar). All lookups of "Jeep" in Shop, Progression, VehicleFeel, Assets etc. are
	-- safe since SPECS[kind] returns nil and those systems iterate or key-check.
	Kart = { label = "Go-Kart", body = Vector3.new(4.6, 0.8, 7.5), color = Color3.fromRGB(60, 90, 220), wheel = 1.8, lift = 0.35, pad = Vector2.new(-45, -8), look = "GoKart" } :: Spec, -- (session v849: moved from (66,-6) to (-45,-8), spawn's left-front — first vehicle a new player sees)
	Truck = { label = "Monster Truck", body = Vector3.new(7.5, 2.2, 12), color = Color3.fromRGB(46, 112, 64), wheel = 6, lift = 3.6, pad = Vector2.new(68, -32) } :: Spec,
	-- (session v842: 5th slot — 70s muscle car. Look model Phoenix Slayer (8x5x20), script-stripped, chassis-compatible wheel names FL/FR/RL/RR.)
	MuscleCar = { label = "Muscle Car", body = Vector3.new(5.8, 1.4, 13), color = Color3.fromRGB(200, 40, 40), wheel = 2.6, lift = 0.6, pad = Vector2.new(66, -58), look = "MuscleCar" } :: Spec,
}

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
		if humanoid and humanoid.Health > 0 and not seat.Occupant and humanoid.SeatPart == nil then
			seat:Sit(humanoid)
		end
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		prompt.Enabled = seat.Occupant == nil
	end)
	-- v3: a real car model over the driving box when the place has one (V3Assets "Car" /
	-- "MonsterTruck"): welded on, weightless and without collisions; the code-built shell goes
	-- see-through but keeps doing the physics.
	local V3Assets = require(script.Parent.V3Assets)
	local role = spec.look or (if kind == "Truck" then "MonsterTruck" else "Car")
	local bottom = home * CFrame.new(0, -b.Y / 2 - spec.lift, 0)
	local look = V3Assets.place(role, model, bottom, { size = b.Z + 1.5, collide = false, anchored = false, name = "Look" })
	if look then
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

-- The cars of one lab (Playground.build calls this for every lab, never the plaza).
function VehicleService.build(into: Folder, origin: Vector3)
	if not (Config.VEHICLES and Config.VEHICLES.enabled) then
		return
	end
	local holder = Instance.new("Folder")
	holder.Name = "Vehicles"
	holder.Parent = into
	local kinds: { Kind } = { "Car", "Truck" }
	for _, extra in { "Kart", "Jeep", "MuscleCar" } do
		if (Config.VEHICLES :: any)[extra] and VehicleService.SPECS[extra] then
			table.insert(kinds, extra)
		end
	end
	for _, kind in kinds do
		local spec = VehicleService.SPECS[kind]
		local cf = CFrame.new(origin + Vector3.new(spec.pad.X, spec.lift + spec.body.Y / 2 + 0.1, spec.pad.Y))
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
					end
				end
			end
		end
	end)
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
			local p = car.body.Position
			local away = p - car.origin
			-- (V6-5: the creature yard in front of the lab is in play too.)
			local front = if (Config :: any).LAB_CREATURES then 112 else 75
			local off = math.abs(away.X) > reach or away.Z > front or away.Z < -96 or away.Y < -20
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
					-- (The seat's weld goes: that frees the driver even though their screen owns
					-- their humanoid.)
					local weld = car.seat:FindFirstChild("SeatWeld")
					if weld then
						weld:Destroy()
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
