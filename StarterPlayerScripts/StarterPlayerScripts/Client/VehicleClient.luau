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

local VehicleClient = {}

VehicleClient.GRIP = 6 -- how fast a sideways slide dies (1/s)
VehicleClient.TURN_FULL = 12 -- studs/s at which steering is at full strength

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
	if fwd.Magnitude < 0.2 or not grounded(body, car) then
		return -- (in the air or on its side: physics only)
	end
	fwd = fwd.Unit
	local throttle, steer = seat.ThrottleFloat, seat.SteerFloat
	local v = body.AssemblyLinearVelocity
	local flat = Vector3.new(v.X, 0, v.Z)
	local along = flat:Dot(fwd)
	local target = if throttle > 0 then spec.speed * throttle elseif throttle < 0 then spec.reverse * throttle else 0
	local newAlong = along + (target - along) * math.min(1, dt * spec.accel)
	local side = (flat - fwd * along) * math.max(0, 1 - dt * VehicleClient.GRIP)
	body.AssemblyLinearVelocity = fwd * newAlong + side + Vector3.new(0, v.Y, 0)
	local strength = math.clamp(math.abs(newAlong) / VehicleClient.TURN_FULL, 0, 1) * (if newAlong >= 0 then 1 else -1)
	local av = body.AssemblyAngularVelocity
	body.AssemblyAngularVelocity = Vector3.new(av.X * 0.8, -steer * spec.turn * strength, av.Z * 0.8)
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
		end
	end)
end

return VehicleClient
