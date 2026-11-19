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
}

VehicleService.SPECS = {
	Car = { label = "Family Car", body = Vector3.new(6, 1.6, 11), color = Color3.fromRGB(52, 98, 168), wheel = 3, lift = 1.2, pad = Vector2.new(66, 20) } :: Spec,
	Truck = { label = "Monster Truck", body = Vector3.new(7.5, 2.2, 12), color = Color3.fromRGB(46, 112, 64), wheel = 6, lift = 3.6, pad = Vector2.new(68, -32) } :: Spec,
}

local DARK = Color3.fromRGB(26, 26, 30)
local GLASS = Color3.fromRGB(150, 190, 220)

type Car = { model: Model, body: BasePart, seat: VehicleSeat, home: CFrame, origin: Vector3, kind: Kind, idleSince: number, badSince: number }
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
	-- The cabin with glass, the bonnet, bumpers and lights.
	local cabin = piece(model, body, "Cabin", Vector3.new(b.X - 0.6, b.Y * 1.1, b.Z * 0.45), top * CFrame.new(0, b.Y * 0.55, b.Z * 0.08), spec.color)
	piece(model, body, "Windscreen", Vector3.new(b.X - 0.8, b.Y * 0.9, 0.2), cabin.CFrame * CFrame.new(0, 0.05, -cabin.Size.Z / 2 - 0.05), GLASS, Enum.Material.Glass).Transparency = 0.35
	for _, side in { -1, 1 } do
		piece(model, body, "Window", Vector3.new(0.2, b.Y * 0.7, cabin.Size.Z * 0.8), cabin.CFrame * CFrame.new(side * (cabin.Size.X / 2 + 0.05), 0.1, 0), GLASS, Enum.Material.Glass).Transparency = 0.35
	end
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
	model:SetAttribute("Vehicle", kind)
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
	for _, kind in kinds do
		local spec = VehicleService.SPECS[kind]
		local cf = CFrame.new(origin + Vector3.new(spec.pad.X, spec.lift + spec.body.Y / 2 + 0.1, spec.pad.Y))
		local model, body, seat = make(kind, cf)
		model.Parent = holder
		local car: Car = { model = model, body = body, seat = seat, home = cf, origin = origin, kind = kind, idleSince = os.clock(), badSince = 0 }
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
			local off = math.abs(away.X) > reach or away.Z > 75 or away.Z < -96 or away.Y < -20
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
				if off and now - car.badSince > 0.5 then
					local occupant = car.seat.Occupant
					if occupant then
						occupant.Sit = false
						occupant.Jump = true
					end
					task.delay(0.3, home, car)
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
