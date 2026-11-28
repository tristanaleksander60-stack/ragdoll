--!strict
-- GyroRideClient (Config.GYRO_RIDE). The gyro's rings and its padded seat turn only on each screen (GateMotion's client
-- Spin), so the server cannot hold a ragdoll in the seat. While a body has the attribute GyroRide (the server anchors it
-- at the hub for the ride), this screen holds every part of it in the nearest turning GyroSeat, keeping the pose it had
-- when it sat down, so it spins WITH the rings, smoothly, on every device. When the attribute goes, the server takes over.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local GyroRideClient = {}

type Ride = { seat: BasePart, parts: { BasePart }, offs: { CFrame } }
local rides: { [Model]: Ride } = {}

local function seatNear(at: Vector3): BasePart?
	local best: BasePart? = nil
	local bestD = 25
	for _, d in Workspace:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "GyroSeat" and d.Size.Y < 1.5 then
			local dist = (d.Position - at).Magnitude
			if dist < bestD then
				best, bestD = d, dist
			end
		end
	end
	return best
end

local function start(m: Model)
	local pe = m:FindFirstChild("LowerTorso")
	if rides[m] or not (pe and pe:IsA("BasePart")) then
		return
	end
	local seat = seatNear(pe.Position)
	if not seat then
		return
	end
	-- sat upright on the seat: the body's pose relative to the pelvis, the pelvis just over the seat's top
	local sitAt = seat.CFrame * CFrame.new(0, seat.Size.Y / 2 + pe.Size.Y / 2 + 0.2, 0)
	local parts, offs = {}, {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(offs, seat.CFrame:ToObjectSpace(sitAt * pe.CFrame:ToObjectSpace(d.CFrame)))
		end
	end
	rides[m] = { seat = seat, parts = parts, offs = offs }
end

function GyroRideClient.start()
	if not Config.GYRO_RIDE then
		return
	end
	RunService.RenderStepped:Connect(function()
		local dummies = Workspace:FindFirstChild("Dummies")
		if dummies then
			for _, m in dummies:GetChildren() do
				if m:IsA("Model") and m:GetAttribute("GyroRide") == true and not rides[m] then
					start(m)
				end
			end
		end
		for m, r in rides do
			if not m.Parent or m:GetAttribute("GyroRide") ~= true or not r.seat.Parent then
				rides[m] = nil
			else
				local cfs = table.create(#r.parts)
				for i in r.parts do
					cfs[i] = r.seat.CFrame * r.offs[i]
				end
				Workspace:BulkMoveTo(r.parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
			end
		end
	end)
end

return GyroRideClient
