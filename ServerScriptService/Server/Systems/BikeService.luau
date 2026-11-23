--!strict
-- BikeService (23 Nov 2026, owner: "one rides round the whole lab on this bike until it is shot or hit and comes off, then
-- you can ride it yourself"). The bike is one of VehicleService's vehicles ("Bike"). One of the lab's ragdolls sits on it
-- (an ObjectValue SeatOn in the body: ActiveRagdoll holds it over the bike on the screen that simulates both), and the
-- bike is steered from here with an AlignPosition and an AlignOrientation between clear spots of the lab. Any new wound,
-- a knock-down, a grab or a machine takes the rider off; the bike drops and is an ordinary vehicle until it stands on its
-- pad again (VehicleService takes it home), where the next ragdoll takes it after AGAIN s.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BikeService = {}
BikeService.SPEED = 13 -- studs/s
BikeService.TURN = 2.2 -- rad/s
BikeService.FIRST = 8 -- s before the first rider gets on
BikeService.AGAIN = 40 -- s on the pad before the next one
BikeService.OVER = 1.65 -- studs from the floor to the body's middle
local MINE = -5 -- CommandedBy while it rides

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function free(m: Model): boolean
	local state = m:GetAttribute("RagdollState")
	local vital = m:GetAttribute("Vital")
	return m.Parent ~= nil and (state == "Standing" or state == "Walking") and vital ~= "Dead" and vital ~= "Unconscious"
		and m:GetAttribute("Severed") == nil and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("Mood") == nil
		and m:GetAttribute("Greeter") == nil and m:GetAttribute("Seat") == nil and m:GetAttribute("InMachine") == nil
		and m:GetAttribute("Held") ~= true
end

-- A clear spot to ride to from `at` (the farthest of a few), or nil.
local function nextSpot(owner: Player, origin: Vector3, at: Vector3, skip: { Instance }): Vector3?
	local Visitors = lazy("VisitorService")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = skip
	local best: Vector3? = nil
	local bestD = 0
	for _ = 1, 10 do
		local floor = Visitors.floorAt(owner, origin + Vector3.new(math.random(-85, 85), 0, math.random(-80, 42)))
		if floor then
			local way = Vector3.new(floor.X - at.X, 0, floor.Z - at.Z)
			if way.Magnitude > 18 and way.Magnitude > bestD and not Workspace:Spherecast(Vector3.new(at.X, floor.Y + 3, at.Z), 1.8, way, params) then
				-- (Not through a machine or a creature on the way either.)
				local open = true
				for k = 1, math.floor(way.Magnitude / 7) do
					local p = Visitors.floorAt(owner, at + way.Unit * (k * 7))
					if not p or #Workspace:GetPartBoundsInRadius(p + Vector3.new(0, 3.5, 0), 2.6, overlap) > 0 then
						open = false
						break
					end
				end
				if open then
					best, bestD = floor, way.Magnitude
				end
			end
		end
	end
	return best
end

local function ride(car: any, owner: Player, rider: Model)
	local body: BasePart = car.body
	local colliding: { BasePart } = {}
	for _, d in car.model:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide then
			d.CanCollide = false
			table.insert(colliding, d)
		end
	end
	car.model:SetAttribute("Ridden", true)
	car.seat.Disabled = true
	local prompt = body:FindFirstChild("Drive")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = false
	end
	local at = Instance.new("Attachment")
	at.Name = "RideAt"
	at.Parent = body
	local pos = Instance.new("AlignPosition")
	pos.Mode = Enum.PositionAlignmentMode.OneAttachment
	pos.Attachment0 = at
	pos.MaxForce = 1e7
	pos.MaxVelocity = BikeService.SPEED
	pos.Responsiveness = 25
	pos.Position = body.Position
	pos.Parent = body
	local turn = Instance.new("AlignOrientation")
	turn.Mode = Enum.OrientationAlignmentMode.OneAttachment
	turn.Attachment0 = at
	turn.MaxTorque = 1e7
	turn.Responsiveness = 20
	turn.CFrame = body.CFrame.Rotation
	turn.Parent = body
	rider:SetAttribute("CommandedBy", MINE)
	rider:SetAttribute("Mood", "Sit")
	rider:SetAttribute("MachineCool", os.clock() + 1e6) -- (no creature takes it off the saddle)
	local link = Instance.new("ObjectValue")
	link.Name = "SeatOn"
	link.Value = body
	link.Parent = rider
	pcall(function()
		lazy("DummyControl").move(rider, body.CFrame * CFrame.new(0, 2.4, 1.1))
	end)
	-- (It brushes past crates and people instead of being knocked off by them.)
	local solid: { BasePart } = {}
	for _, d in rider:GetChildren() do
		if d:IsA("BasePart") and d.CanCollide then
			d.CanCollide = false
			table.insert(solid, d)
		end
	end
	local wounds = rider:GetAttribute("Wounds") or ""
	local look = body.CFrame.LookVector
	local heading = math.atan2(-look.X, -look.Z)
	local floorY = car.home.Position.Y - BikeService.OVER
	local goal: Vector3? = nil
	local goalAt = os.clock()
	local started = os.clock()
	while true do
		local dt = task.wait(0.1)
		local state = rider:GetAttribute("RagdollState")
		if not body.Parent or not rider.Parent or not owner.Parent then
			break
		end
		local now = rider:GetAttribute("Wounds") or ""
		if now ~= wounds and now ~= "" then
			break
		end
		if rider:GetAttribute("CommandedBy") ~= MINE or rider:GetAttribute("Held") == true or rider:GetAttribute("InMachine") ~= nil
			or rider:GetAttribute("Vital") == "Dead" or rider:GetAttribute("Vital") == "Unconscious" then
			break
		end
		local pelvis = rider:FindFirstChild("LowerTorso")
		if os.clock() - started > 3 and pelvis and pelvis:IsA("BasePart") and (pelvis.Position - body.Position).Magnitude > 9 then
			break
		end
		if os.clock() - started > 2 and (state == "Ragdoll" or state == "Out") then
			break
		end
		local here = body.Position
		local to = goal
		if not to or Vector3.new(to.X - here.X, 0, to.Z - here.Z).Magnitude < 7 or os.clock() - goalAt > 20 then
			local skip: { Instance } = { car.model }
			local dummies = Workspace:FindFirstChild("Dummies")
			if dummies then
				table.insert(skip, dummies)
			end
			for _, p in Players:GetPlayers() do
				if p.Character then
					table.insert(skip, p.Character)
				end
			end
			to = nextSpot(owner, car.origin, here, skip)
			goal, goalAt = to, os.clock()
		end
		if to then
			local want = math.atan2(-(to.X - here.X), -(to.Z - here.Z))
			local off = math.atan2(math.sin(want - heading), math.cos(want - heading))
			heading += math.clamp(off, -BikeService.TURN * dt, BikeService.TURN * dt)
			floorY += (to.Y - floorY) * math.min(1, dt * 2)
			local ahead = Vector3.new(-math.sin(heading), 0, -math.cos(heading))
			-- (Slower in a tight turn, leaning into it.)
			local pace = if math.abs(off) > 1.2 then 0.12 elseif math.abs(off) > 0.35 then 0.35 else 1
			pos.MaxVelocity = math.max(1.5, BikeService.SPEED * pace)
			pos.Position = Vector3.new(here.X, floorY + BikeService.OVER, here.Z) + ahead * BikeService.SPEED * 0.5
			turn.CFrame = CFrame.Angles(0, heading, 0) * CFrame.Angles(0, 0, math.clamp(off, -1, 1) * 0.22)
		else
			pos.Position = Vector3.new(here.X, floorY + BikeService.OVER, here.Z)
		end
	end
	-- Off.
	link:Destroy()
	for _, d in solid do
		if d.Parent then
			d.CanCollide = true
		end
	end
	local speed = if body.Parent then body.AssemblyLinearVelocity else Vector3.zero
	pos:Destroy()
	turn:Destroy()
	at:Destroy()
	for _, d in colliding do
		d.CanCollide = true
	end
	car.model:SetAttribute("Ridden", nil)
	car.idleSince = os.clock()
	car.seat.Disabled = false
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = true
	end
	if rider.Parent then
		rider:SetAttribute("MachineCool", os.clock() + 3)
		if rider:GetAttribute("Mood") == "Sit" then
			rider:SetAttribute("Mood", nil)
		end
		if rider:GetAttribute("CommandedBy") == MINE then
			rider:SetAttribute("CommandedBy", nil)
		end
		task.wait(0.1)
		pcall(function()
			local flat = Vector3.new(speed.X, 0, speed.Z)
			local dir = if flat.Magnitude > 1 then flat.Unit else Vector3.zAxis
			lazy("DummyControl").push(rider, dir * 20 + Vector3.new(0, 14, 0), nil)
		end)
	end
end

function BikeService.start()
	task.spawn(function()
		local since: { [any]: number } = {}
		local riding: { [any]: boolean } = {}
		local ridden: { [any]: boolean } = {}
		while true do
			task.wait(1)
			for _, car in lazy("VehicleService").carsForTest() do
				if car.kind ~= "Bike" then
					continue
				end
				local owner = lazy("Lab").ownerAt(car.origin)
				if riding[car] or not owner or not car.model.Parent or car.seat.Occupant ~= nil
					or (car.body.Position - car.home.Position).Magnitude > 6 then
					since[car] = nil
					continue
				end
				since[car] = since[car] or os.clock()
				if os.clock() - since[car] < (if ridden[car] then BikeService.AGAIN else BikeService.FIRST) then
					continue
				end
				for _, m in lazy("Lab").dummiesOf(owner) do
					-- (Not one of the first three: they walk the spawn circle.)
					if free(m) and ((m:GetAttribute("Slot") :: number?) or 0) > 3 then
						riding[car], ridden[car], since[car] = true, true, nil
						task.spawn(function()
							local ok, err = pcall(ride, car, owner, m)
							if not ok then
								warn("[Bike] " .. tostring(err))
								car.model:SetAttribute("Ridden", nil)
							end
							riding[car] = nil
						end)
						break
					end
				end
			end
		end
	end)
end

return BikeService
