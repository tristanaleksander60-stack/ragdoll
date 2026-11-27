--!strict
-- v4 C2 (owner: "the cars must look and sound like real cars"). Everything here is on this screen
-- only, for the lab cars near the camera (VehicleService builds them; their wheels hang on Welds and
-- the rest of the model on a "RollWeld"):
--   * wheels roll with the car's speed and the front ones steer with the driver's steering;
--   * the body leans a little out of a turn and dips when braking (springs feel);
--   * headlamps on, a red brake glow when slowing down or reversing;
--   * an engine loop whose pitch and volume follow the speed, a crash sound on a hard stop, and
--     dust from the rear wheels at speed;
--   * H (or the pad's DPad right while driving) honks: the server plays the horn for everyone.
-- Config.VEHICLES.feel switches it off.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent
local SoundMix = require(Client:WaitForChild("SoundMix"))

local VehicleFeel = {}

VehicleFeel.REACH = 160 -- studs from the camera a car gets the full treatment
VehicleFeel.LIGHT_REACH = 90 -- studs: headlamps only this close (light budget)
VehicleFeel.ROLL_MAX = math.rad(5)
VehicleFeel.PITCH_MAX = math.rad(3)
VehicleFeel.STEER_MAX = math.rad(28)
VehicleFeel.CRASH_DROP = 28 -- studs/s of speed lost in one frame that counts as a crash
VehicleFeel.HORN_ACTION = "VehicleHorn"

type Wheel = { weld: Weld, base: CFrame, axle: Vector3, radius: number, front: boolean }
type CarFeel = {
	model: Model,
	body: BasePart,
	seat: VehicleSeat?,
	wheels: { Wheel },
	roll: Weld?,
	spin: number,
	steer: number,
	lean: number,
	dive: number,
	lastSpeed: number,
	lastVel: Vector3,
	engine: Sound?,
	dust: ParticleEmitter?,
	lamps: { SpotLight },
	brake: PointLight?,
	crashAt: number,
}

local player = Players.LocalPlayer
local feels: { [Model]: CarFeel } = {}
local V = Config.VEHICLES :: any

local function sound(id: number, parent: Instance, looped: boolean, volume: number): Sound
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Looped = looped
	s.Volume = volume
	s.RollOffMaxDistance = 180
	s.RollOffMinDistance = 12
	s.SoundGroup = SoundMix.group("World")
	s.Parent = parent
	return s
end

local function build(model: Model): CarFeel?
	local body = model:FindFirstChild("Body")
	if not (body and body:IsA("BasePart")) then
		return nil
	end
	local wheels: { Wheel } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Weld") and d.Name == "WheelWeld" then
			local corner = d:GetAttribute("Corner")
			local axle = if type(corner) == "string" then model:GetAttribute("Axle" .. corner) else nil
			local radius = if type(corner) == "string" then model:GetAttribute("Radius" .. corner) else nil
			local base = d:GetAttribute("BaseC0")
			if typeof(axle) == "Vector3" and type(radius) == "number" and typeof(base) == "CFrame" then
				table.insert(wheels, { weld = d, base = base, axle = axle, radius = radius, front = string.sub(corner :: string, 1, 1) == "F" })
			end
		end
	end
	local rootPart = model:FindFirstChild("LookRoot")
	local roll = rootPart and rootPart:FindFirstChild("RollWeld")
	local seat = model:FindFirstChild("Seat")
	local lamps: { SpotLight } = {}
	for _, d in body:GetDescendants() do
		if d:IsA("SpotLight") and d.Name == "Headlamp" then
			table.insert(lamps, d)
		end
	end
	local brakeAt = body:FindFirstChild("BrakeAt")
	local brake = brakeAt and brakeAt:FindFirstChild("BrakeLight")
	local f: CarFeel = {
		model = model,
		body = body,
		seat = if seat and seat:IsA("VehicleSeat") then seat else nil,
		wheels = wheels,
		roll = if roll and roll:IsA("Weld") then roll else nil,
		spin = 0,
		steer = 0,
		lean = 0,
		dive = 0,
		lastSpeed = 0,
		lastVel = Vector3.zero,
		engine = nil,
		dust = nil,
		lamps = lamps,
		brake = if brake and brake:IsA("PointLight") then brake else nil,
		crashAt = 0,
	}
	if V.engineSound then
		local e = sound(V.engineSound, body, true, 0)
		e.PlaybackSpeed = 0.7
		f.engine = e
	end
	-- Dust behind the rear wheels.
	local a = Instance.new("Attachment")
	a.Name = "DustAt"
	a.Position = Vector3.new(0, -body.Size.Y / 2, body.Size.Z / 2)
	a.Parent = body
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "TyreDust"
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(196, 186, 170))
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 4) })
	dust.Lifetime = NumberRange.new(0.6, 1.1)
	dust.Speed = NumberRange.new(2, 5)
	dust.SpreadAngle = Vector2.new(30, 30)
	dust.EmissionDirection = Enum.NormalId.Back
	dust.Rate = 0
	dust.LightEmission = 0
	dust.Parent = a
	f.dust = dust
	return f
end

local function drop(f: CarFeel)
	if f.engine then
		f.engine:Destroy()
	end
	if f.dust and f.dust.Parent then
		(f.dust.Parent :: Instance):Destroy()
	end
	for _, w in f.wheels do
		if w.weld.Parent then
			w.weld.C0 = w.base
		end
	end
	if f.roll and f.roll.Parent then
		f.roll.C0 = CFrame.identity
	end
	for _, l in f.lamps do
		l.Enabled = false
	end
	if f.brake then
		f.brake.Enabled = false
	end
end

local function step(f: CarFeel, dt: number, camPos: Vector3)
	local body = f.body
	local cf = body.CFrame
	local vel = body.AssemblyLinearVelocity
	local along = vel:Dot(cf.LookVector)
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	-- Wheels: roll by distance over radius; the front ones steer.
	local steerIn = if f.seat then f.seat.SteerFloat else 0
	f.steer += (steerIn * VehicleFeel.STEER_MAX - f.steer) * math.min(1, dt * 10)
	f.spin -= along * dt -- (radius applied per wheel)
	for _, w in f.wheels do
		local turn = CFrame.Angles(f.spin / w.radius, 0, 0)
		local steer = if w.front then CFrame.Angles(0, -f.steer, 0) else CFrame.identity
		w.weld.C0 = CFrame.new(w.axle) * steer * turn * CFrame.new(-w.axle) * w.base
	end
	-- Lean out of a turn, dip on braking (springy).
	local accel = (vel - f.lastVel) / math.max(dt, 1 / 240)
	local sideways = accel:Dot(cf.RightVector)
	local forward = accel:Dot(cf.LookVector)
	local leanTo = math.clamp(-sideways / 160, -1, 1) * VehicleFeel.ROLL_MAX
	local diveTo = math.clamp(forward / 160, -1, 1) * VehicleFeel.PITCH_MAX
	f.lean += (leanTo - f.lean) * math.min(1, dt * 6)
	f.dive += (diveTo - f.dive) * math.min(1, dt * 6)
	if f.roll then
		local foot = Vector3.new(0, -body.Size.Y / 2, 0)
		f.roll.C0 = CFrame.new(foot) * CFrame.Angles(f.dive, 0, f.lean) * CFrame.new(-foot)
	end
	-- Lights.
	local near = (body.Position - camPos).Magnitude < VehicleFeel.LIGHT_REACH
	local driven = f.seat ~= nil and f.seat.Occupant ~= nil
	for _, l in f.lamps do
		l.Enabled = near and driven
	end
	local braking = driven and ((f.seat :: VehicleSeat).ThrottleFloat < 0 or (speed < f.lastSpeed - 0.4 and speed > 3))
	if f.brake then
		f.brake.Enabled = near and driven
		f.brake.Brightness = if braking then 4 else 0.6
	end
	-- Engine: idles when someone sits in it, revs with speed.
	local e = f.engine
	if e then
		if driven then
			if not e.IsPlaying then
				e:Play()
			end
			local k = math.clamp(speed / 60, 0, 1)
			e.PlaybackSpeed = 0.75 + k * 0.9
			e.Volume = (0.25 + k * 0.4) * (if body:GetAttribute("CockpitLocal") then 1.5 else 1) -- (V9-NOW 16: louder inside, Cockpit)
		elseif e.IsPlaying then
			e:Stop()
		end
	end
	-- Crash: a lot of speed gone at once.
	local now = os.clock()
	if f.lastSpeed - speed > VehicleFeel.CRASH_DROP * math.max(1, dt * 60) and now - f.crashAt > 0.8 and V.crashSound then
		f.crashAt = now
		local s = sound(V.crashSound, body, false, 0.7)
		s.PlaybackSpeed = 0.9 + math.random() * 0.2
		s:Play()
		task.delay(5, function() -- (a sound that never loads never ends: gone anyway)
			if s.Parent then
				s:Destroy()
			end
		end)
		s.Ended:Once(function()
			s:Destroy()
		end)
	end
	if f.dust then
		f.dust.Rate = if speed > 22 and math.abs(body.AssemblyLinearVelocity.Y) < 6 then 18 else 0
	end
	f.lastSpeed = speed
	f.lastVel = vel
end

-- F76: the feature each new vehicle has (mirrors VehicleService.FEATURE) and what it does on this screen.
VehicleFeel.FEATURE_ACTION = "VehicleFeature"
local FEATURE: { [string]: string } = { GoKart = "Boost", MonsterTruck = "Jump", Police = "Siren", FireTruck = "Spray", Bulldozer = "Blade" }
local boundFeature: string? = nil
local lastFeature = 0
local function featureNow(feature: string, seat: VehicleSeat)
	local t = os.clock()
	if t - lastFeature < (if feature == "Boost" or feature == "Jump" then 1.5 else 0.4) then
		return
	end
	lastFeature = t
	local body = seat.AssemblyRootPart
	if body and not body.Anchored then
		-- (the driver's screen owns the car: Boost and Jump move it here, the server shows the flames)
		if feature == "Boost" then
			local look = body.CFrame.LookVector
			body.AssemblyLinearVelocity += Vector3.new(look.X, 0, look.Z).Unit * 38
		elseif feature == "Jump" then
			body.AssemblyLinearVelocity += Vector3.new(0, 58, 0)
		end
	end
	Net.event(Net.Names.VehicleAction):FireServer(feature)
end

function VehicleFeel.start()
	if not (V and V.enabled and V.feel) then
		return
	end
	local horn = Net.event(Net.Names.VehicleHorn)
	local function seated(): boolean
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local s = h and h.SeatPart
		return s ~= nil and s:IsA("VehicleSeat") and s:GetAttribute("LabCar") ~= nil
	end
	-- H honks only while driving (bound on sitting down, so H is free otherwise).
	local bound = false
	RunService.Heartbeat:Connect(function()
		local now = seated()
		if now and not bound then
			bound = true
			-- (Above PadMap's slot keys, Medium+100, so DPad right honks while driving instead of
			-- switching weapons; no touch button: no unchecked spot on a phone screen.)
			ContextActionService:BindActionAtPriority(VehicleFeel.HORN_ACTION, function(_, state)
				if state == Enum.UserInputState.Begin then
					horn:FireServer()
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value + 200, Enum.KeyCode.H, Enum.KeyCode.DPadRight)
		elseif not now and bound then
			bound = false
			ContextActionService:UnbindAction(VehicleFeel.HORN_ACTION)
		end
		-- F76 (Config.NEW_VEHICLES): the vehicle's feature on F (PC), ButtonY (pad) and ONE big touch button (phone)
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local s = h and h.SeatPart
		local kind = if now and s then s:GetAttribute("LabCar") else nil
		local feature = if type(kind) == "string" and (Config :: any).NEW_VEHICLES then FEATURE[kind] else nil
		if feature ~= boundFeature then
			if boundFeature then
				ContextActionService:UnbindAction(VehicleFeel.FEATURE_ACTION)
			end
			boundFeature = feature
			if feature then
				ContextActionService:BindActionAtPriority(VehicleFeel.FEATURE_ACTION, function(_, state)
					if state == Enum.UserInputState.Begin then
						featureNow(feature, s :: VehicleSeat)
					end
					return Enum.ContextActionResult.Sink
				end, true, Enum.ContextActionPriority.High.Value + 200, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
				ContextActionService:SetTitle(VehicleFeel.FEATURE_ACTION, string.upper(feature))
				ContextActionService:SetPosition(VehicleFeel.FEATURE_ACTION, UDim2.new(1, -170, 1, -150))
			end
		end
	end)
	local scanAt = 0
	RunService.RenderStepped:Connect(function(dt: number)
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local camPos = cam.CFrame.Position
		local now = os.clock()
		if now >= scanAt then
			scanAt = now + 1
			-- Pick up cars near the camera, drop the far ones.
			for _, d in CollectionService:GetTagged("LabVehicle") do
				if d:IsA("Model") and d:GetAttribute("Vehicle") ~= nil and not feels[d] then
					local b = d:FindFirstChild("Body")
					if b and b:IsA("BasePart") and (b.Position - camPos).Magnitude < VehicleFeel.REACH then
						local f = build(d)
						if f then
							feels[d] = f
						end
					end
				end
			end
		end
		for model, f in feels do
			if not model.Parent or not f.body.Parent or (f.body.Position - camPos).Magnitude > VehicleFeel.REACH + 20 then
				drop(f)
				feels[model] = nil
			else
				-- (23 Nov 2026, fps: a parked car's wheels and lean were set again every frame, the dearest thing on the client:
				-- hundreds of welded pieces each. One that stands still and empty rests.)
				local rest: any = f
				local moving = (f.seat ~= nil and f.seat.Occupant ~= nil) or f.body.AssemblyLinearVelocity.Magnitude > 1.5
				if moving then
					rest.stillAt = now + 1
				end
				if now < (rest.stillAt or now + 1) or rest.stillAt == nil then
					rest.stillAt = rest.stillAt or now + 1
					step(f, dt, camPos)
				end
			end
		end
	end)
end

return VehicleFeel
