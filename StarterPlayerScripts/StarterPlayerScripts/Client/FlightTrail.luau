--!strict
-- IMPACT_FX "smoke trail" (owner, 26 Nov 2026; docs/IMPACT_FX.md, Config.FLIGHT_TRAIL): a thin grey smoke trail behind
-- a ragdoll flying faster than FAST studs/s (the cannon, a throw, a SLAM, a blast), ending in the impact dust
-- (ImpactDust). Client only: one Trail per body, made once and switched on and off; looked at every TICK s, only the
-- bodies within REACH studs of the camera, at most MAX_ON at once (fewer on a phone).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local FlightTrail = {}

FlightTrail.FAST = 60
FlightTrail.SLOW = 35 -- below this a trail switches off again
FlightTrail.TICK = 0.1
FlightTrail.REACH = 120
local PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
FlightTrail.MAX_ON = if PHONE then 3 else 6

local trails: { [Model]: Trail } = setmetatable({}, { __mode = "k" }) :: any

local function trailFor(model: Model, pelvis: BasePart): Trail
	local have = trails[model]
	if have and have.Parent then
		return have
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailTop"
	a0.Position = Vector3.new(0, 0.5, 0)
	a0.Parent = pelvis
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailBottom"
	a1.Position = Vector3.new(0, -0.5, 0)
	a1.Parent = pelvis
	local t = Instance.new("Trail")
	t.Name = "FlightTrail"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(Color3.fromRGB(225, 225, 228), Color3.fromRGB(180, 180, 186))
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 2.2) })
	t.Lifetime = 0.6
	t.MinLength = 0.2
	t.FaceCamera = true
	t.LightEmission = 0
	t.Enabled = false
	t.Parent = pelvis
	trails[model] = t
	return t
end

function FlightTrail.start()
	if not Config.FLIGHT_TRAIL then
		return
	end
	task.spawn(function()
		while true do
			task.wait(FlightTrail.TICK)
			local dummies = Workspace:FindFirstChild("Dummies")
			local camera = Workspace.CurrentCamera
			if not dummies or not camera then
				continue
			end
			local eye = camera.CFrame.Position
			local on = 0
			for model, t in trails do
				if t.Enabled then
					on += 1
				end
			end
			for _, model in dummies:GetChildren() do
				local pelvis = model:IsA("Model") and model:FindFirstChild("LowerTorso")
				if pelvis and pelvis:IsA("BasePart") then
					local speed = pelvis.AssemblyLinearVelocity.Magnitude
					local t = trails[model]
					if t and t.Enabled and (speed < FlightTrail.SLOW or (pelvis.Position - eye).Magnitude > FlightTrail.REACH) then
						t.Enabled = false
						on -= 1
					elseif speed >= FlightTrail.FAST and on < FlightTrail.MAX_ON and (pelvis.Position - eye).Magnitude <= FlightTrail.REACH then
						local trail = trailFor(model :: Model, pelvis)
						if not trail.Enabled then
							trail.Enabled = true
							on += 1
						end
					end
				end
			end
		end
	end)
end

return FlightTrail
