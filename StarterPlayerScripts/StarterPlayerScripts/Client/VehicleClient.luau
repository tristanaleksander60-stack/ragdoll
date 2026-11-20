--!strict
-- v3 Phase C: drives the lab car you sit in (VehicleService builds them; the body is yours while
-- you drive). Roblox's own controls fill the seat's throttle and steer from W/S A/D, the arrow
-- keys, the touch thumbstick and a gamepad, so every device drives the same way. On the ground the
-- car speeds up towards its top speed, grips sideways, and turns more the faster it goes; in the
-- air it is left to physics. Space (or the jump button) gets you out.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CarDrive = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CarDrive")) :: any

local VehicleClient = {}

VehicleClient.GRIP = 6 -- how fast a sideways slide dies (1/s)

local player = Players.LocalPlayer
local hinted = false
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function grounded(body: BasePart, car: Instance): boolean
	local character = player.Character
	rayParams.FilterDescendantsInstances = if character then { car, character } else { car }
	local reach = body.Size.Y / 2 + 8
	return Workspace:Raycast(body.Position, Vector3.new(0, -reach, 0), rayParams) ~= nil
end

local steerNow = 0 -- (V9-0c: the eased steer, CarDrive)
VehicleClient.reading = { along = 0, top = 1, seated = false } -- (the speedometer reads it: Client/Speedometer)

local function drive(seat: VehicleSeat, dt: number)
	local body = seat.AssemblyRootPart
	local car = seat.Parent
	local kind = seat:GetAttribute("LabCar")
	local spec = if type(kind) == "string" then (Config.VEHICLES :: any)[kind] else nil
	if not body or not car or not spec or body.Anchored then
		return
	end
	local look = body.CFrame.LookVector
	local fwd = Vector3.new(look.X, 0, look.Z)
	local v = body.AssemblyLinearVelocity
	VehicleClient.reading.top = spec.speed
	VehicleClient.reading.along = if fwd.Magnitude > 0.2 then Vector3.new(v.X, 0, v.Z):Dot(fwd.Unit) else 0
	-- (V9-0c: tipped well over (more than about 45 degrees, so a car on a slope is left alone): it
	-- rights itself, so it never gets stuck on its side; a set rate, the same at any frame rate.)
	local up = body.CFrame.UpVector
	if up.Y < 0.7 then
		local axis = up:Cross(Vector3.yAxis)
		if axis.Magnitude > 0.01 then
			local av = body.AssemblyAngularVelocity
			local want = axis.Unit * 2.5
			body.AssemblyAngularVelocity = av:Lerp(Vector3.new(want.X, av.Y, want.Z), math.min(1, dt * 4))
		end
		return -- (V9-0d review: no driving on its side, and no damping that would slow the righting)
	end
	if fwd.Magnitude < 0.2 or not grounded(body, car) then
		return -- (in the air or on its side: physics only)
	end
	fwd = fwd.Unit
	local flat = Vector3.new(v.X, 0, v.Z)
	local along = flat:Dot(fwd)
	local newAlong, newSteer, yawRate = CarDrive.step(spec, along, steerNow, seat.ThrottleFloat, seat.SteerFloat, dt)
	steerNow = newSteer
	local side = (flat - fwd * along) * math.max(0, 1 - dt * VehicleClient.GRIP)
	body.AssemblyLinearVelocity = fwd * newAlong + side + Vector3.new(0, v.Y, 0)
	local av = body.AssemblyAngularVelocity
	body.AssemblyAngularVelocity = Vector3.new(av.X * 0.8, yawRate, av.Z * 0.8)
end

function VehicleClient.start()
	if not (Config.VEHICLES and Config.VEHICLES.enabled) then
		return
	end
	RunService.Heartbeat:Connect(function(dt)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if seat and seat:IsA("VehicleSeat") and seat:GetAttribute("LabCar") ~= nil then
			VehicleClient.reading.seated = true
			if not hinted then
				hinted = true
				local ok, Toast = pcall(function()
					return require(script.Parent:WaitForChild("Toast")) :: any
				end)
				if ok and Toast then
					Toast.show("W/S to drive, A/D to steer, H to honk, Space to get out", Color3.fromRGB(255, 205, 64))
				end
			end
			drive(seat, dt)
		else
			VehicleClient.reading.seated = false
			steerNow = 0
		end
	end)
end

return VehicleClient
