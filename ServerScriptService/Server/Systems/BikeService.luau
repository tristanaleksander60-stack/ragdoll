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

-- The next spot of the round: on over the grass round the spawn circle (never across it: KEEP_OUT), each a bit further
-- round the lab the same way, at a distance of its own; a free way there with no machine, creature or thing on it.
BikeService.KEEP_OUT = 35 -- studs from the spawn's middle
local way_: { [any]: number } = {}
local function nextSpot(owner: Player, origin: Vector3, at: Vector3, skip: { Instance }): Vector3?
	local Visitors = lazy("VisitorService")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = skip
	local mid = Vector2.new(origin.X, origin.Z)
	local from = Vector2.new(at.X, at.Z)
	local now = math.atan2(from.Y - mid.Y, from.X - mid.X)
	local turnWay = way_[owner] or 1
	for try = 1, 24 do
		if try == 17 then
			turnWay = -turnWay -- (nothing open on that way round: back the other)
		end
		local angle = now + turnWay * math.rad(math.random(14, 48))
		local out = math.random(40, 84)
		local to2 = mid + Vector2.new(math.cos(angle), math.sin(angle)) * out
		local lx, lz = to2.X - mid.X, to2.Y - mid.Y
		if math.abs(lx) > 92 or lz > 44 or lz < -84 then
			continue
		end
		local floor = Visitors.floorAt(owner, Vector3.new(to2.X, origin.Y, to2.Y))
		if not floor then
			continue
		end
		local way = Vector3.new(floor.X - at.X, 0, floor.Z - at.Z)
		if way.Magnitude < 10 then
			continue
		end
		local open = true
		for k = 1, math.ceil(way.Magnitude / 5) do
			local p = at + way * math.min(1, k * 5 / way.Magnitude)
			local f = Visitors.floorAt(owner, p)
			if not f or (Vector2.new(p.X, p.Z) - mid).Magnitude < BikeService.KEEP_OUT
				or #Workspace:GetPartBoundsInRadius(f + Vector3.new(0, 3.5, 0), 2.8, overlap) > 0 then
				open = false
				break
			end
		end
		if open and not Workspace:Spherecast(Vector3.new(at.X, floor.Y + 3, at.Z), 1.8, way, params) then
			way_[owner] = turnWay
			return floor
		end
	end
	return nil
end

-- F69 (Config.BIKE_ROUTE): on the compact map the rider keeps to the walkway loop's centre line (Plan.ROADS ring:
-- CrossN, RingE, CrossS, RingW), corner to corner with the middles between, one way round. The first point is the ring
-- point nearest the bike; from its bay it rides straight to it. A point it cannot reach in 14 s is skipped (the stuck
-- guard; the dodge in clearOf steers round people and ragdolls).
local function ringRoute(origin: Vector3): { Vector3 }?
	local PS = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any
	if not PS.compact then
		return nil
	end
	local n, e, s, w = PS.road("CrossN"), PS.road("RingE"), PS.road("CrossS"), PS.road("RingW")
	if not (n and e and s and w) then
		return nil
	end
	local corners = { n[1], n[2], s[2], s[1] } -- NW, NE, SE, SW (clockwise seen from above with north up)
	local out: { Vector3 } = {}
	for i, c in corners do
		local nxt = corners[i % #corners + 1]
		for k = 0, 3 do
			local p = c:Lerp(nxt, k / 4)
			table.insert(out, Vector3.new(origin.X + p.X, origin.Y, origin.Z + p.Y))
		end
	end
	local _ = e and w
	return out
end

-- How to lean the way to keep clear of people and ragdolls ahead: radians to turn (+ left), and how near the nearest is.
BikeService.SEE = 13 -- studs
local function clearOf(body: BasePart, rider: Model, heading: number): (number, number)
	local here = body.Position
	local ahead = Vector3.new(-math.sin(heading), 0, -math.cos(heading))
	local left = Vector3.new(ahead.Z, 0, -ahead.X)
	local turnBy, nearest = 0, math.huge
	local function look(at: Vector3)
		local d = Vector3.new(at.X - here.X, 0, at.Z - here.Z)
		local far = d.Magnitude
		local on = d:Dot(ahead)
		local side = d:Dot(left)
		if far < BikeService.SEE and on > -1 and math.abs(side) < 5 then
			nearest = math.min(nearest, far)
			turnBy += (if side >= 0 then -1 else 1) * (1 - far / BikeService.SEE) * 1.5
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	for _, m in if dummies then dummies:GetChildren() else {} do
		local p = m ~= rider and m:FindFirstChild("LowerTorso")
		if p and p:IsA("BasePart") then
			look(p.Position)
		end
	end
	for _, pl in Players:GetPlayers() do
		local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			look(r.Position)
		end
	end
	return math.clamp(turnBy, -1.4, 1.4), nearest
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
	rider:SetAttribute("Mood", "Ride")
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
	local route = if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).BIKE_ROUTE then ringRoute(car.origin) else nil
	local leg = 0
	if route then
		local best = math.huge
		for i, p in route do
			local d = Vector3.new(p.X - body.Position.X, 0, p.Z - body.Position.Z).Magnitude
			if d < best then
				best, leg = d, i
			end
		end
	end
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
		if route then
			-- (F69: the walkway loop's centre line, point to point; skip one not reached in 14 s)
			local p = route[leg]
			if not to or Vector3.new(p.X - here.X, 0, p.Z - here.Z).Magnitude < 6 or os.clock() - goalAt > 14 then
				if to then
					leg = leg % #route + 1
				end
				p = route[leg]
				to = Vector3.new(p.X, floorY, p.Z)
				goal, goalAt = to, os.clock()
			end
		elseif not to or Vector3.new(to.X - here.X, 0, to.Z - here.Z).Magnitude < 7 or os.clock() - goalAt > 20 then
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
			local dodge, near = clearOf(body, rider, heading)
			want += dodge
			local off = math.atan2(math.sin(want - heading), math.cos(want - heading))
			heading += math.clamp(off, -BikeService.TURN * dt, BikeService.TURN * dt)
			floorY += (to.Y - floorY) * math.min(1, dt * 2)
			local ahead = Vector3.new(-math.sin(heading), 0, -math.cos(heading))
			-- (Slower in a tight turn, leaning into it.)
			local pace = if math.abs(off) > 1.2 then 0.12 elseif math.abs(off) > 0.35 then 0.35 else 1
			if near < 5 then
				pace = math.min(pace, 0.12)
			elseif near < 9 then
				pace = math.min(pace, 0.45)
			end
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
		if rider:GetAttribute("Mood") == "Ride" then
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
				-- (row 11, Config.CYCLIST: a ragdoll also pedals the free BICYCLE round the lab now and then; hit it and it comes off,
				-- then the bicycle is yours to ride)
				if car.kind ~= "Bike" and not (car.kind == "Bicycle" and (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).CYCLIST) then
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
