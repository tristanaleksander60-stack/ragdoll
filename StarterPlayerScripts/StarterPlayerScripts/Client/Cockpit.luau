--!strict
-- V9-NOW 16 / V9-0y cockpit (owner, 21 Nov 2026: "cars done properly: sit right, first person with interior,
-- and sounds"). This screen only, for the lab car you drive (VehicleService builds them):
--   * the driver's-seat camera at eye height from the moment you sit (Config.VEHICLES.cockpit); V, the pad's
--     Select or the VIEW button swap to the chase camera and back;
--   * your own body is hidden from you in the cockpit (nothing blocks the view); the car's own interior
--     shows, plus a steering wheel that turns with your steering and a speedometer on the dash;
--   * sounds: the engine starting as you get in, tyres screeching in hard turns and hard braking, wind that
--     grows with speed; inside, the engine is louder and the world a little muffled (VehicleFeel, SoundMix).
-- The horn, engine loop and crash stay in VehicleFeel (heard by everyone near).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any

local Client = script.Parent
local SoundMix = require(Client:WaitForChild("SoundMix")) :: any

local Cockpit = {}

Cockpit.EYE_FORWARD = 0.25 -- studs ahead of the (hidden) head, so the head's inside never shows
Cockpit.EYE_UP = 0.15
Cockpit.STEER_LOOK = math.rad(10) -- the view leans into a turn a little
Cockpit.WHEEL_TURN = math.rad(120) -- the steering wheel's turn at full lock
Cockpit.SCREECH_SPEED = 28 -- studs/s: a hard turn or hard braking above this screeches
Cockpit.WIND_FROM = 18 -- studs/s: wind from here, full at WIND_FULL
Cockpit.WIND_FULL = 60
Cockpit.ACTION = "CockpitView"

local player = Players.LocalPlayer
local V = Config.VEHICLES or {}

type Ride = {
	seat: VehicleSeat,
	body: BasePart,
	extras: { Instance },
	wheel: BasePart?,
	wheelBase: CFrame?,
	speedText: TextLabel?,
	start: Sound?,
	screech: Sound?,
	wind: Sound?,
	lastAlong: number,
}

local ride: Ride? = nil
local cockpitOn = false
local hidden: { [Instance]: boolean } = {}
local eq: EqualizerSoundEffect? = nil
local button: TextButton? = nil

local function sound(id: number?, parent: Instance, looped: boolean, volume: number): Sound?
	if not id then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Looped = looped
	s.Volume = volume
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = 120
	s.Parent = parent
	return s
end

-- Your own body: hidden from you in the cockpit (LocalTransparencyModifier: other screens still see you).
local function hideSelf(on: boolean)
	local character = player.Character
	if on and character then
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				(d :: any).LocalTransparencyModifier = 1
				hidden[d] = true
			end
		end
	else
		for d in hidden do
			if d.Parent then
				(d :: any).LocalTransparencyModifier = 0
			end
		end
		table.clear(hidden)
	end
end

-- The world a little muffled while you sit inside (the World group; the engine is boosted to make up).
local function muffle(on: boolean)
	local ok, group = pcall(SoundMix.group, "World")
	if not ok or not group then
		return
	end
	if on and not eq then
		local e = Instance.new("EqualizerSoundEffect")
		e.Name = "CockpitMuffle"
		e.HighGain = -9
		e.MidGain = -2
		e.LowGain = 0
		e.Parent = group
		eq = e
	elseif not on and eq then
		(eq :: EqualizerSoundEffect):Destroy()
		eq = nil
	end
end

local function setCockpit(on: boolean)
	local r = ride
	cockpitOn = on and r ~= nil
	local camera = Workspace.CurrentCamera
	if camera then
		if cockpitOn then
			camera.CameraType = Enum.CameraType.Scriptable
		else
			camera.CameraType = Enum.CameraType.Custom
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
	end
	hideSelf(cockpitOn)
	muffle(cockpitOn)
	if r then
		r.body:SetAttribute("CockpitLocal", if cockpitOn then true else nil) -- (VehicleFeel: the engine louder inside)
	end
	local b = button
	if b then
		b.Text = if cockpitOn then "CHASE" else "INSIDE"
	end
end

function Cockpit.isOn(): boolean
	return cockpitOn
end

-- The steering wheel and the speedometer, built on this screen in front of the driver's seat and welded to the car.
local function buildExtras(r: Ride)
	local seat, body = r.seat, r.body
	local function piece(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		if shape then
			p.Shape = shape
		end
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
		p.Anchored = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = p
		w.Parent = p
		p.Parent = seat.Parent
		table.insert(r.extras, p)
		return p
	end
	local kind = seat:GetAttribute("LabCar")
	local reach = if kind == "Truck" then 1.9 else 1.7
	local height = if kind == "Truck" then 2.3 else 2.1
	-- The wheel: a ring of 14 short pieces round a hub, tilted towards the driver, on a column. The ring is its own
	-- assembly welded to a hub that turns (a Weld whose C0 this screen sets: Cockpit's step).
	local center = seat.CFrame * CFrame.new(0, height, -reach) * CFrame.Angles(math.rad(-25), 0, 0)
	local hub = Instance.new("Part")
	hub.Name = "CockpitWheelHub"
	hub.Shape = Enum.PartType.Cylinder
	hub.Size = Vector3.new(0.12, 0.42, 0.42)
	hub.CFrame = center * CFrame.Angles(0, math.rad(90), 0)
	hub.Color = Color3.fromRGB(30, 30, 34)
	hub.Material = Enum.Material.SmoothPlastic
	hub.CanCollide, hub.CanQuery, hub.CanTouch, hub.Massless, hub.CastShadow = false, false, false, true, false
	local turn = Instance.new("Weld")
	turn.Name = "Turn"
	turn.Part0 = body
	turn.Part1 = hub
	turn.C0 = body.CFrame:ToObjectSpace(hub.CFrame)
	turn.Parent = hub
	hub.Parent = seat.Parent
	table.insert(r.extras, hub)
	r.wheel = hub
	r.wheelBase = turn.C0
	local radius = 0.62
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local p = Instance.new("Part")
		p.Name = "CockpitWheelRim"
		p.Size = Vector3.new(0.3, 0.1, 0.12)
		p.CFrame = center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a + math.pi / 2)
		p.Color = Color3.fromRGB(24, 24, 28)
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
		local w = Instance.new("WeldConstraint")
		w.Part0 = hub
		w.Part1 = p
		w.Parent = p
		p.Parent = seat.Parent
		table.insert(r.extras, p)
	end
	for _, a in { 0, math.pi } do -- (two spokes)
		local p = Instance.new("Part")
		p.Name = "CockpitWheelSpoke"
		p.Size = Vector3.new(radius * 2, 0.08, 0.08)
		p.CFrame = center * CFrame.Angles(0, 0, a)
		p.Color = Color3.fromRGB(60, 60, 66)
		p.Material = Enum.Material.Metal
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
		local w = Instance.new("WeldConstraint")
		w.Part0 = hub
		w.Part1 = p
		w.Parent = p
		p.Parent = seat.Parent
		table.insert(r.extras, p)
	end
	piece("CockpitColumn", Vector3.new(0.16, 0.16, 0.9), center * CFrame.new(0, 0, -0.5), Color3.fromRGB(30, 30, 34))
	-- The speedometer: a small lit panel on the dash, right of the wheel.
	local dash = piece("CockpitDash", Vector3.new(0.9, 0.5, 0.06), center * CFrame.new(0.95, 0.15, -0.35), Color3.fromRGB(14, 16, 20))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 120
	gui.Parent = dash
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextColor3 = Color3.fromRGB(120, 240, 255)
	t.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	t.TextScaled = true
	t.Text = "0 mph"
	t.Parent = gui
	r.speedText = t
end

local function leave()
	local r = ride
	if not r then
		return
	end
	setCockpit(false)
	ContextActionService:UnbindAction(Cockpit.ACTION)
	for _, x in r.extras do
		x:Destroy()
	end
	for _, s in { r.start, r.screech, r.wind } do
		if s then
			s:Destroy()
		end
	end
	local b = button
	if b then
		b.Visible = false
	end
	ride = nil
end

local function enter(seat: VehicleSeat)
	local body = seat.AssemblyRootPart or seat.Parent:FindFirstChild("Body")
	if not (body and body:IsA("BasePart")) then
		return
	end
	local r: Ride = { seat = seat, body = body, extras = {}, lastAlong = 0 }
	ride = r
	pcall(buildExtras, r)
	r.start = sound(V.startSound, body, false, 0.9)
	r.screech = sound(V.screechSound, body, true, 0)
	r.wind = sound(V.windSound, body, true, 0)
	if r.start then
		(r.start :: Sound):Play()
	end
	ContextActionService:BindActionAtPriority(Cockpit.ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			setCockpit(not cockpitOn)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 200, Enum.KeyCode.V, Enum.KeyCode.ButtonSelect)
	local b = button
	if b then
		b.Visible = true
	end
	setCockpit(V.cockpit ~= false)
end

local function step(dt: number)
	local r = ride
	if not r then
		return
	end
	local seat, body = r.seat, r.body
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (humanoid and humanoid.SeatPart == seat and seat.Parent and body.Parent) then
		leave()
		return
	end
	local v = body.AssemblyLinearVelocity
	local fwd = body.CFrame.LookVector
	local along = Vector3.new(v.X, 0, v.Z):Dot(Vector3.new(fwd.X, 0, fwd.Z).Unit)
	local speed = math.abs(along)
	local steer = seat.SteerFloat
	-- The wheel turns with the steering.
	local hub, base = r.wheel, r.wheelBase
	if hub and base then
		local turn = hub:FindFirstChild("Turn")
		if turn and turn:IsA("Weld") then
			turn.C0 = base * CFrame.Angles(-steer * Cockpit.WHEEL_TURN, 0, 0) -- (the hub's axis is its X)
		end
	end
	local t = r.speedText
	if t then
		t.Text = string.format("%d mph", math.floor(speed * 0.682 + 0.5)) -- (a stud as a foot: studs/s -> mph)
	end
	-- Sounds.
	local hardTurn = math.abs(steer) > 0.6 and speed > Cockpit.SCREECH_SPEED
	local hardBrake = speed > Cockpit.SCREECH_SPEED and seat.ThrottleFloat ~= 0 and math.sign(seat.ThrottleFloat) ~= math.sign(along)
	local sc = r.screech
	if sc then
		local want = if hardTurn or hardBrake then 0.55 else 0
		sc.Volume += (want - sc.Volume) * math.min(1, dt * 10)
		if sc.Volume > 0.02 and not sc.IsPlaying then
			sc:Play()
		elseif sc.Volume <= 0.02 and sc.IsPlaying then
			sc:Stop()
		end
	end
	local wd = r.wind
	if wd then
		local k = math.clamp((speed - Cockpit.WIND_FROM) / (Cockpit.WIND_FULL - Cockpit.WIND_FROM), 0, 1)
		wd.Volume = k * (if cockpitOn then 0.25 else 0.45)
		wd.PlaybackSpeed = 0.9 + k * 0.3
		if k > 0 and not wd.IsPlaying then
			wd:Play()
		elseif k == 0 and wd.IsPlaying then
			wd:Stop()
		end
	end
	r.lastAlong = along
	-- The cockpit camera: at the (hidden) head, facing along the car, leaning a little into the turn.
	if cockpitOn then
		local camera = Workspace.CurrentCamera
		local head = character and character:FindFirstChild("Head")
		if camera and head and head:IsA("BasePart") then
			camera.CameraType = Enum.CameraType.Scriptable
			local rot = body.CFrame.Rotation * CFrame.Angles(0, -steer * Cockpit.STEER_LOOK, 0)
			camera.CFrame = CFrame.new(head.Position + body.CFrame.UpVector * Cockpit.EYE_UP + fwd * Cockpit.EYE_FORWARD) * rot
		end
		-- (Anything put on later, a hat or a tool: hidden too.)
		if character then
			for _, d in character:GetDescendants() do
				if (d:IsA("BasePart") or d:IsA("Decal")) and not hidden[d] then
					(d :: any).LocalTransparencyModifier = 1
					hidden[d] = true
				end
			end
		end
	end
end

-- Tests and LayoutCheck: the VIEW button (nil until a car is entered once).
function Cockpit.button(): TextButton?
	return button
end

function Cockpit.start()
	if not (V.enabled and V.cockpit ~= nil) then
		return
	end
	-- The touch screen's swap button, right edge, shown only while you drive.
	local gui = Instance.new("ScreenGui")
	gui.Name = "CockpitView"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 7
	local b = Instance.new("TextButton")
	b.Name = "View"
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -14, 0.42, 0)
	b.Size = UDim2.fromOffset(84, 44)
	b.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	b.BackgroundTransparency = 0.15
	b.TextColor3 = Color3.new(1, 1, 1)
	b.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	b.TextSize = 16
	b.Text = "INSIDE"
	b.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = b
	b.Activated:Connect(function()
		setCockpit(not cockpitOn)
	end)
	b.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	button = b
	RunService:BindToRenderStep("Cockpit", Enum.RenderPriority.Camera.Value + 2, function(dt)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if seat and seat:IsA("VehicleSeat") and seat:GetAttribute("LabCar") ~= nil then
			if not ride then
				enter(seat)
			end
			step(dt)
		elseif ride then
			leave()
		end
	end)
end

return Cockpit
