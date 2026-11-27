--!strict
-- F57 (owner: "Fiks så launch pads virker med biler"; Config.PAD_CARS): the 3 launch pads in the Crash Yard (OwnerMap
-- "LaunchPad", aimed west at the brick wall; small, medium, BIG from south to north) launch CARS and ragdolls.
--   * Found on the server by position, every 0.1 s: a car whose body is over a pad and moving faster than MIN_SPEED,
--     or a standing/walking/lying ragdoll on it.
--   * A car is simulated by its driver's screen, so the server takes it over for a moment (network owner = server),
--     sets its speed (forward along the pad's arrow and up at ANGLE degrees, less for a heavy car), and gives it back
--     to the driver 0.6 s later. The driver stays in (F56).
--   * A ragdoll gets the push through DummyControl.
--   * A cooldown of 2 s per thing per pad. On landing: "AIR TIME 2.4 s" pops over the car, NEW BEST for the driver.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LaunchPads = {}

LaunchPads.MIN_SPEED = 8
LaunchPads.ANGLE = 45
LaunchPads.SPEEDS = { 95, 115, 135 } -- small, medium, BIG (gravity is 196: these give about 12-23 studs up)
LaunchPads.DIR = Vector3.new(-1, 0, 0) -- (west, at the wall)

local cooldown: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any

local function pop(at: Vector3, text: string)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one * 0.2
	p.Position = at + Vector3.new(0, 6, 0)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 64)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 300
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(255, 220, 80)
	l.TextStrokeTransparency = 0.1
	l.Text = text
	l.Parent = bb
	bb.Parent = p
	p.Parent = Workspace
	game:GetService("Debris"):AddItem(p, 3)
end

local function launchCar(model: Model, seat: VehicleSeat, strength: number)
	local root = seat.AssemblyRootPart or seat
	local mass = root.AssemblyMass
	local scale = math.clamp((1500 / math.max(mass, 1)) ^ 0.25, 0.6, 1.15) -- (a heavy one jumps less)
	local v = LaunchPads.SPEEDS[strength] * scale
	local a = math.rad(LaunchPads.ANGLE)
	local vel = LaunchPads.DIR * (v * math.cos(a)) + Vector3.new(0, v * math.sin(a), 0)
	local driver = seat.Occupant and Players:GetPlayerFromCharacter(seat.Occupant.Parent)
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	root.AssemblyLinearVelocity = vel
	pcall(function()
		require(script.Parent:WaitForChild("FxService")).hit(root.Position, 80, "CannonPad")
	end)
	task.delay(0.6, function()
		if root.Parent and driver and seat.Occupant and Players:GetPlayerFromCharacter(seat.Occupant.Parent) == driver then
			pcall(function()
				root:SetNetworkOwner(driver)
			end)
		end
	end)
	-- the air time
	task.spawn(function()
		local t0 = os.clock()
		model:SetAttribute("PadLaunched", true) -- (3.32 RIDE_AIR: VehicleService leaves this flight's air time to us)
		task.delay(9, function()
			model:SetAttribute("PadLaunched", nil)
		end)
		task.wait(0.4)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { model }
		while model.Parent and os.clock() - t0 < 8 do
			if Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params) then
				break
			end
			task.wait(0.1)
		end
		local air = os.clock() - t0
		if model.Parent and air > 0.6 then
			local text = string.format("AIR TIME %.1f s", air)
			if driver then
				local best = (driver:GetAttribute("AirBest") :: number?) or 0
				if air > best then
					driver:SetAttribute("AirBest", air)
					text ..= "\nNEW BEST!"
				end
			end
			pop(root.Position, text)
		end
	end)
end

local seats: { [VehicleSeat]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local pads: { { part: BasePart, strength: number } } = {}
local function findPads()
	local root = Workspace:FindFirstChild("Playground")
	pads = {}
	for _, lab in if root then root:GetChildren() else {} do
		local om = lab:FindFirstChild("OwnerMap")
		if om then
			local list = {}
			for _, p in om:GetChildren() do
				if p.Name == "LaunchPad" and p:IsA("BasePart") then
					table.insert(list, p)
				end
			end
			table.sort(list, function(x, y)
				return x.Position.Z > y.Position.Z -- (south first: small, medium, BIG)
			end)
			for i, p in list do
				table.insert(pads, { part = p, strength = math.clamp(i, 1, 3) })
			end
		end
	end
end

local function step()
	if #pads == 0 then
		return
	end
	local now = os.clock()
	-- cars (the seats are listed once, as they come)
	for d in seats do
		if d.Parent then
			local model = d:FindFirstAncestorOfClass("Model")
			local body = d.AssemblyRootPart or d
			if model and body.AssemblyLinearVelocity.Magnitude > LaunchPads.MIN_SPEED then
				for _, pad in pads do
					local l = pad.part.CFrame:PointToObjectSpace(body.Position)
					if math.abs(l.X) < pad.part.Size.X / 2 + 2 and math.abs(l.Z) < pad.part.Size.Z / 2 + 2 and l.Y > -2 and l.Y < 8 then
						local key = model
						if not cooldown[key] or now - cooldown[key] > 2 then
							cooldown[key] = now
							launchCar(model, d, pad.strength)
						end
					end
				end
			end
		end
	end
	-- ragdolls
	local dummies = Workspace:FindFirstChild("Dummies")
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = m:FindFirstChild("LowerTorso")
		if m:IsA("Model") and pe and pe:IsA("BasePart") and m:GetAttribute("Held") ~= true and m:GetAttribute("InMachine") == nil then
			for _, pad in pads do
				local l = pad.part.CFrame:PointToObjectSpace(pe.Position)
				if math.abs(l.X) < pad.part.Size.X / 2 and math.abs(l.Z) < pad.part.Size.Z / 2 and l.Y > -1 and l.Y < 5 then
					if not cooldown[m] or now - cooldown[m] > 2 then
						cooldown[m] = now
						local v = LaunchPads.SPEEDS[pad.strength] * 2.2 -- (a body needs a bigger push than a car: as the cannon)
						local a = math.rad(LaunchPads.ANGLE + 10)
						local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
						pcall(DC.push, m, LaunchPads.DIR * (v * math.cos(a)) + Vector3.new(0, v * math.sin(a), 0))
					end
				end
			end
		end
	end
end

function LaunchPads.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.PAD_CARS or not Config.LAB_OWNERMAP then
		return
	end
	for _, d in Workspace:GetDescendants() do
		if d:IsA("VehicleSeat") then
			seats[d] = true
		end
	end
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("VehicleSeat") then
			seats[d] = true
		end
	end)
	task.spawn(function()
		local t = 0
		while true do
			task.wait(0.1)
			t += 0.1
			if t > 5 or #pads == 0 then
				t = 0
				pcall(findPads)
			end
			pcall(step)
		end
	end)
end

return LaunchPads
