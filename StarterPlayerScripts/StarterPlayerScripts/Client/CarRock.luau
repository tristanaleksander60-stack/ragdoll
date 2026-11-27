--!strict
-- Row 7 rest (impact effects; Config.CAR_ROCK): a ragdoll that slams into a car ROCKS it. The cars are simulated by the
-- lab owner's screen (VehicleService gives it the network ownership), so the rock is applied here: when a dummy part
-- hits a car's body at 22+ studs/s, the car gets a short roll and pitch kick (an angular impulse scaled by the speed
-- and the car's own mass, so a heavy car rocks less) and a small shove in the hit's direction. At most one kick a car
-- every 0.4 s. On a screen that does not simulate the car the impulse is simply overwritten (harmless).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local CarRock = {}

CarRock.MIN_SPEED = 22
CarRock.GAP = 0.4

local lastKick: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any
local hooked: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function dummyOf(part: BasePart): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return nil
	end
	local m = part:FindFirstAncestorOfClass("Model")
	while m and m.Parent ~= dummies do
		m = m:FindFirstAncestorOfClass("Model")
	end
	return m
end

local function hook(seat: Instance)
	if not seat:IsA("VehicleSeat") or seat:GetAttribute("LabCar") == nil then
		return
	end
	local model = seat:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not hooked[d] and d.CanCollide and d.Size.Magnitude > 3 then
			hooked[d] = true
			local part = d
			part.Touched:Connect(function(other: BasePart)
				local root = part.AssemblyRootPart
				if not root or root.Anchored then
					return
				end
				local now = os.clock()
				if now - (lastKick[root] or -math.huge) < CarRock.GAP then
					return
				end
				if not dummyOf(other) then
					return
				end
				local rel = other.AssemblyLinearVelocity - root.AssemblyLinearVelocity
				local speed = rel.Magnitude
				if speed < CarRock.MIN_SPEED then
					return
				end
				lastKick[root] = now
				local mass = root.AssemblyMass
				local k = math.clamp((speed - CarRock.MIN_SPEED) / 60 + 0.25, 0.25, 1.2)
				local dir = rel.Unit
				local cf = root.CFrame
				-- roll about the car's forward axis by how much the hit came from the side, pitch by front/back
				local side = dir:Dot(cf.RightVector)
				local front = dir:Dot(cf.LookVector)
				local spin = (cf.LookVector * -side * 1.0 + cf.RightVector * front * 0.6) * mass * k * 2.2
				pcall(function()
					root:ApplyAngularImpulse(spin)
					root:ApplyImpulse(Vector3.new(dir.X, 0.15, dir.Z) * mass * k * 2.5)
				end)
			end)
		end
	end
end

function CarRock.start()
	if not Config.CAR_ROCK then
		return
	end
	local function scan()
		for _, d in Workspace:GetDescendants() do
			if d:IsA("VehicleSeat") then
				hook(d)
			end
		end
	end
	scan()
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("VehicleSeat") then
			task.defer(hook, d)
		end
	end)
end

return CarRock
