--!strict
-- Row 14 (docs/WHEELCHAIRS.md; owner's answer 27 Nov: "build the ride-welded state"; Config.WHEELCHAIR_RIDE): a ragdoll
-- RIDES a wheelchair. It uses the riding state the bike already has (ActiveRagdoll.seatOf / holdSeat with a SeatOn
-- link: the body is held seated over the moving part on the screen that simulates it, the legs bent, the balance
-- facing forward), with the chair's own seat offset (the link's Offset attribute).
--   * "Seat a ragdoll" on an empty chair: a free ragdoll near (never the one by a player, held, hit in 5 s or in a mood)
--     RUNS over and sits in (F92: never a teleport from afar).
--   * "PUSH!" while one sits: the chair rolls off forward (the server holds the chair while it is ridden).
--   * It falls OUT on a hard stop (the chair loses 16+ studs/s in a tenth of a second: thrown on forward) or a hit
--     (knocked over), or after RIDE_MAX s; then the chair is an ordinary drivable one again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WheelchairRide = {}

WheelchairRide.RIDE_MAX = 90
WheelchairRide.PUSH = 24 -- studs/s
WheelchairRide.OFFSET = CFrame.new(0, -1.1, 0.2) -- (the floor point under the chair's seat, facing forward)
local MINE = -6 -- CommandedBy while it rides

local riding: { [BasePart]: Model } = {}

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pelvis(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function free(m: Model, pe: BasePart): boolean
	local st = m:GetAttribute("RagdollState")
	local vital = m:GetAttribute("Vital")
	local hitAt = m:GetAttribute("ServerHitAt")
	if not ((st == nil or st == "Standing" or st == "Walking") and vital ~= "Dead" and vital ~= "Unconscious"
		and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("Mood") == nil and m:GetAttribute("InMachine") == nil
		and m:GetAttribute("MachineHidden") == nil and m:GetAttribute("Held") ~= true and m:GetAttribute("Seat") == nil
		and m:FindFirstChild("SeatOn") == nil and not (type(hitAt) == "number" and Workspace:GetServerTimeNow() - hitAt < 5)) then
		return false
	end
	for _, pl in Players:GetPlayers() do
		local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") and (r.Position - pe.Position).Magnitude < 8 then
			return false
		end
	end
	return true
end

local function release(body: BasePart, seat: VehicleSeat, rider: Model, throw: Vector3?)
	riding[body] = nil
	seat.Disabled = false
	local link = rider:FindFirstChild("SeatOn")
	if link then
		link:Destroy()
	end
	if rider.Parent then
		rider:SetAttribute("CommandedBy", nil)
		rider:SetAttribute("Mood", nil)
		rider:SetAttribute("MachineCool", nil)
		rider:SetAttribute("InMachine", nil)
		for _, d in rider:GetChildren() do
			if d:IsA("BasePart") and d:GetAttribute("RideNoCollide") then
				d.CanCollide = true
				d:SetAttribute("RideNoCollide", nil)
			end
		end
		if throw then
			pcall(lazy("DummyControl").push, rider, throw, nil)
		end
	end
	local prompt = body:FindFirstChild("RagdollRide")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = "Seat a ragdoll"
	end
end

local function ride(body: BasePart, seat: VehicleSeat, rider: Model)
	riding[body] = rider
	seat.Disabled = true -- (no player sits in it while a ragdoll does)
	rider:SetAttribute("CommandedBy", MINE)
	rider:SetAttribute("Mood", "Ride")
	rider:SetAttribute("InMachine", "Wheelchair")
	rider:SetAttribute("MachineCool", os.clock() + 1e6)
	local link = Instance.new("ObjectValue")
	link.Name = "SeatOn"
	link.Value = body
	link:SetAttribute("Offset", WheelchairRide.OFFSET)
	link.Parent = rider
	for _, d in rider:GetChildren() do
		if d:IsA("BasePart") and d.CanCollide then
			d.CanCollide = false
			d:SetAttribute("RideNoCollide", true)
		end
	end
	pcall(function()
		lazy("DummyControl").move(rider, body.CFrame * CFrame.new(0, 2.2, 0.2))
	end)
	pcall(function()
		body:SetNetworkOwner(nil) -- (the server holds the chair while it is ridden: PUSH moves it)
	end)
	local prompt = body:FindFirstChild("RagdollRide")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = "PUSH!"
	end
	task.spawn(function()
		local started = os.clock()
		local lastV = body.AssemblyLinearVelocity
		while riding[body] == rider do
			task.wait(0.1)
			if not (rider.Parent and body.Parent) then
				release(body, seat, rider, nil)
				return
			end
			local st = rider:GetAttribute("RagdollState")
			if st == "Ragdoll" or st == "Out" or rider:GetAttribute("Held") == true or rider:GetAttribute("Vital") == "Dead" then
				release(body, seat, rider, nil) -- (knocked out of it)
				return
			end
			local v = body.AssemblyLinearVelocity
			if lastV.Magnitude - v.Magnitude > 16 then
				-- a hard stop: it flies on out of the chair
				release(body, seat, rider, lastV * 1.05 + Vector3.new(0, 12, 0))
				return
			end
			lastV = v
			if os.clock() - started > WheelchairRide.RIDE_MAX then
				release(body, seat, rider, nil)
				return
			end
		end
	end)
end

local function adopt(seat: VehicleSeat)
	local car = seat.Parent
	local body = car and car:FindFirstChild("Body")
	if not (body and body:IsA("BasePart")) or body:FindFirstChild("RagdollRide") then
		return
	end
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "RagdollRide"
	pp.ActionText = "Seat a ragdoll"
	pp.ObjectText = "Wheelchair"
	pp.MaxActivationDistance = 10
	pp.HoldDuration = 0.3 -- (F92: no start by a tap while walking past)
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.R
	pp.Parent = body
	local busy = false
	pp.Triggered:Connect(function(player: Player)
		if busy then
			return
		end
		local rider = riding[body]
		if rider then
			-- PUSH: it rolls off forward
			local look = body.CFrame.LookVector
			pcall(function()
				body.AssemblyLinearVelocity = Vector3.new(look.X, 0, look.Z).Unit * WheelchairRide.PUSH
			end)
			pcall(function() -- (row 14: the funnel, "Wheelchair" Seat / Push)
				lazy("Funnels").event(player, "Wheelchair", "Push")
			end)
			return
		end
		if seat.Occupant then
			return
		end
		busy = true
		task.spawn(function()
			-- the nearest free ragdoll within 40 studs RUNS over
			local best, bestD = nil :: Model?, 40
			local dummies = Workspace:FindFirstChild("Dummies")
			for _, m in if dummies then dummies:GetChildren() else {} do
				local pe = m:IsA("Model") and pelvis(m)
				if pe and free(m, pe) then
					local d = (pe.Position - body.Position).Magnitude
					if d < bestD then
						best, bestD = m, d
					end
				end
			end
			local m = best
			if not m then
				pcall(function()
					lazy("Playground").pop(body.Position + Vector3.new(0, 5, 0), "No ragdoll near!", Color3.fromRGB(255, 200, 120))
				end)
				busy = false
				return
			end
			m:SetAttribute("CommandedBy", MINE)
			m:SetAttribute("Home", body.Position + body.CFrame.RightVector * 2.5)
			m:SetAttribute("Pace", 2.2)
			local t0 = os.clock()
			local there = false
			while os.clock() - t0 < 8 do
				local pe = pelvis(m)
				if not (pe and m.Parent) or m:GetAttribute("Held") == true then
					break
				end
				if (Vector3.new(pe.Position.X, 0, pe.Position.Z) - Vector3.new(body.Position.X, 0, body.Position.Z)).Magnitude < 5 then
					there = true
					break
				end
				task.wait(0.2)
			end
			m:SetAttribute("Pace", nil)
			if there and not seat.Occupant then
				pcall(function()
					lazy("RagdollDirector").logRemoval(m, "Wheelchair", "called; ran over and sat in")
				end)
				ride(body, seat, m)
				pcall(function()
					lazy("Funnels").event(player, "Wheelchair", "Seat")
				end)
			else
				m:SetAttribute("CommandedBy", nil)
			end
			busy = false
		end)
	end)
end

function WheelchairRide.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.WHEELCHAIR_RIDE then
		return
	end
	task.spawn(function()
		for _ = 1, 40 do
			for _, d in Workspace:GetDescendants() do
				if d:IsA("VehicleSeat") then
					local kind = d:GetAttribute("LabCar")
					if type(kind) == "string" and string.sub(kind, 1, 10) == "Wheelchair" then
						adopt(d)
					end
				end
			end
			task.wait(6)
		end
	end)
end

return WheelchairRide
