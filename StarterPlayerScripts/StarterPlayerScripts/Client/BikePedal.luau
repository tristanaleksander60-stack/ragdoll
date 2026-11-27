--!strict
-- F76 (Config.BIKE_PEDAL; docs/FIXES_26NOV.md F76 "FREE: a BICYCLE": "your legs pedal (a pedal animation tied to the
-- speed)"): every rider on a bicycle within 120 studs of this screen pedals: both legs turn the cranks half a turn
-- apart, the hips swing and the knees bend with the stroke, one crank turn per about 2.2 studs ridden; standing still
-- the feet rest on the pedals. Written on top of the sitting pose each frame (Stepped, after the animator).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local BikePedal = {}

local STROKE = 2.2 -- studs per crank turn
local REACH = 120

local phases: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function motor(char: Model, part: string, name: string): Motor6D?
	local p = char:FindFirstChild(part)
	local m = p and p:FindFirstChild(name)
	return if m and m:IsA("Motor6D") then m else nil
end

function BikePedal.start()
	if not Config.BIKE_PEDAL then
		return
	end
	RunService.Stepped:Connect(function(_, dt)
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local eye = cam.CFrame.Position
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local seat = hum and hum.SeatPart
			if not (char and seat and seat:IsA("VehicleSeat") and seat:GetAttribute("LabCar") == "Bicycle") then
				continue
			end
			if (seat.Position - eye).Magnitude > REACH then
				continue
			end
			local v = seat.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			local phase = ((phases[char] or 0) + speed * dt / STROKE) % 1
			phases[char] = phase
			local a = phase * 2 * math.pi
			for _, side in { "Right", "Left" } do
				local s = if side == "Right" then math.sin(a) else math.sin(a + math.pi)
				local c = if side == "Right" then math.cos(a) else math.cos(a + math.pi)
				local hip = motor(char, side .. "UpperLeg", side .. "Hip")
				local knee = motor(char, side .. "LowerLeg", side .. "Knee")
				if hip then
					hip.Transform = hip.Transform * CFrame.Angles(math.rad(18 * s + 6), 0, 0)
				end
				if knee then
					knee.Transform = knee.Transform * CFrame.Angles(math.rad(-22 * (0.5 + 0.5 * c)), 0, 0)
				end
			end
		end
	end)
end

return BikePedal
