--!strict
-- Benches in every lab that its ragdolls sit down on now and then (owner, 23 Nov 2026). Each bench stands on level floor
-- that really is free (measured once the lab is up: nothing solid or seen there, clear of every machine's footprint, room
-- to walk up in front), faces the middle of the lab and has two seats. A seat is booked by one ragdoll before it sets out,
-- so two never share it. The server walks it to the front of the seat (CommandedBy -4), then sets Seat (a CFrame on the
-- floor under the seat, facing out) and Mood "Sit"; the machine that simulates it sits it down and holds it there
-- (ActiveRagdoll.holdSeat). Rounds do not move it: it stays until it has sat its time, also through a death (slumped)
-- and its waking up. A grab, a blast or a player's command takes it off the seat.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Lab = require(Systems:WaitForChild("Lab")) :: any
local PathPlan = require(Shared:WaitForChild("PathPlan")) :: any

local BenchService = {}

BenchService.PER_LAB = 6
BenchService.SEAT_TOP = 1.7 -- studs over the floor (ActiveRagdoll.SEAT_TOP is the same)
local SEAT_SIDE = 1.6 -- a seat's distance from the bench's middle
local STAND_OFF = 2.9 -- where it stands before it sits, in front of the bench's middle
local APART = 24 -- studs between two benches
local MINE = -4 -- CommandedBy while it is on its way or sits
local SIT_MIN, SIT_MAX = 20, 45
local REST_MIN, REST_MAX = 25, 70 -- s on its feet before it may sit again
local TRIP_MAX = 28 -- s to get there
local SHARE = 0.34 -- of a lab's ragdolls that may sit at once

type Seat = { cf: CFrame, by: Model? }
type Job = { seat: Seat, phase: "Walk" | "Sit", since: number, untilAt: number, wasDown: boolean, owner: Player }

local seatsOf: { [number]: { folder: Folder, seats: { Seat }, owner: Player } } = {}
local ownedAt: { [number]: { owner: Player, at: number, tries: number } } = {}
local jobs: { [Model]: Job } = {}
local restUntil: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local rng = Random.new()

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function skipList(): { Instance }
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	return skip
end

-- The floor frame for a bench at this spot of the lab, or nil when it does not fit there.
local function fits(origin: Vector3, spot: Vector2): CFrame?
	if math.abs(spot.X) > Lab.CORE_HALF - 8 or spot.Y > 44 or spot.Y < -100 then
		return nil
	end
	for _, o in PathPlan.OBSTACLES do
		if o.at and o.radius and (spot - o.at).Magnitude < o.radius + 7 then
			return nil
		elseif o.min and o.max and spot.X > o.min.X - 7 and spot.X < o.max.X + 7 and spot.Y > o.min.Y - 7 and spot.Y < o.max.Y + 7 then
			return nil
		end
	end
	local at = Vector3.new(origin.X + spot.X, origin.Y, origin.Z + spot.Y)
	local L10 = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("LabLayout10")) :: any
	local faceZ = if L10.on then L10.TEST_FLOOR.Y else 0 -- (LAB10: they face the test floor)
	local frame = CFrame.lookAt(at, Vector3.new(origin.X, origin.Y, origin.Z + faceZ))
	local skip = skipList()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	params.RespectCanCollide = true
	local low, high = math.huge, -math.huge
	for _, off in { Vector3.zero, Vector3.new(-3.2, 0, 1), Vector3.new(3.2, 0, 1), Vector3.new(-3.2, 0, -4), Vector3.new(3.2, 0, -4) } do
		local p = frame * off
		local hit = Workspace:Raycast(Vector3.new(p.X, origin.Y + 30, p.Z), Vector3.new(0, -60, 0), params)
		if not hit or hit.Normal.Y < 0.97 or math.abs(hit.Position.Y - origin.Y) > 2.5 or string.find(hit.Instance.Name, "Lava") or hit.Material == Enum.Material.Water then
			return nil
		end
		low, high = math.min(low, hit.Position.Y), math.max(high, hit.Position.Y)
	end
	if high - low > 0.15 then
		return nil
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = skip
	for _, part in Workspace:GetPartBoundsInBox(frame * CFrame.new(0, high - origin.Y + 3.2, -1.6), Vector3.new(8.4, 5, 8), overlap) do
		if part.CanCollide or part.Transparency < 0.9 then
			return nil
		end
	end
	return CFrame.lookAt(Vector3.new(at.X, high, at.Z), Vector3.new(origin.X, high, origin.Z))
end

local function piece(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
end

local function bench(into: Instance, frame: CFrame)
	local m = Instance.new("Model")
	m.Name = "SitBench"
	local wood, steel = Color3.fromRGB(128, 88, 54), Color3.fromRGB(52, 55, 60)
	local top = BenchService.SEAT_TOP
	for i = 0, 2 do
		piece(m, "Plank", Vector3.new(6.6, 0.22, 0.52), frame * CFrame.new(0, top - 0.11, -0.58 + i * 0.58), wood, Enum.Material.WoodPlanks)
	end
	for i = 0, 1 do
		piece(m, "Back", Vector3.new(6.6, 0.55, 0.2), frame * CFrame.new(0, top + 0.85 + i * 0.72, 1.12 + i * 0.1), wood, Enum.Material.WoodPlanks)
	end
	for _, x in { -2.9, 0, 2.9 } do
		piece(m, "Leg", Vector3.new(0.3, top - 0.22, 0.3), frame * CFrame.new(x, (top - 0.22) / 2, -0.5), steel, Enum.Material.Metal)
		piece(m, "Leg", Vector3.new(0.3, top - 0.22, 0.3), frame * CFrame.new(x, (top - 0.22) / 2, 0.6), steel, Enum.Material.Metal)
		piece(m, "Post", Vector3.new(0.25, 2.1, 0.25), frame * CFrame.new(x, top + 0.75, 1.36), steel, Enum.Material.Metal)
		piece(m, "Bar", Vector3.new(0.25, 0.2, 2.1), frame * CFrame.new(x, top - 0.32, 0.4), steel, Enum.Material.Metal)
	end
	m.Parent = into
end

local function build(index: number, owner: Player): boolean
	local origin = Lab.originFor(owner)
	local folder = Instance.new("Folder")
	folder.Name = "LabBenches" .. index
	folder.Parent = Workspace
	local spots: { Vector2 } = {}
	for _, r in { 34, 42, 50, 58, 66, 75, 85 } do
		for a = 0, 23 do
			local angle = (a + (r % 2) * 0.5) * math.pi / 12
			table.insert(spots, Vector2.new(math.cos(angle) * r, math.sin(angle) * r))
		end
	end
	local L10 = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("LabLayout10")) :: any
	if L10.on then
		spots = table.clone(L10.BENCHES) -- (LAB10: a few benches round the test floor, nothing scattered)
	end
	-- (The same order in every lab and every time.)
	local order = Random.new(7)
	for i = #spots, 2, -1 do
		local j = order:NextInteger(1, i)
		spots[i], spots[j] = spots[j], spots[i]
	end
	local seats: { Seat } = {}
	local taken: { Vector2 } = {}
	for i, spot in spots do
		if #taken >= BenchService.PER_LAB then
			break
		end
		local clear = true
		for _, t in taken do
			clear = clear and (t - spot).Magnitude >= APART
		end
		local frame = if clear then fits(origin, spot) else nil
		if frame then
			bench(folder, frame)
			table.insert(taken, spot)
			for _, side in { -1, 1 } do
				table.insert(seats, { cf = frame * CFrame.new(side * SEAT_SIDE, 0, 0.1), by = nil })
			end
		end
		if i % 24 == 0 then
			task.wait()
		end
	end
	if #taken < 2 then
		folder:Destroy()
		return false
	end
	if Lab.ownerOf(index) ~= owner then
		folder:Destroy()
		return false
	end
	seatsOf[index] = { folder = folder, seats = seats, owner = owner }
	return true
end

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

-- Off the seat (or the trip given up): it gets about by itself again.
local function leave(m: Model, job: Job)
	jobs[m] = nil
	restUntil[m] = os.clock() + rng:NextNumber(REST_MIN, REST_MAX)
	local seat = job.seat
	local function give()
		if seat.by == m then
			seat.by = nil
		end
	end
	if not m.Parent then
		give()
		return
	end
	local satOn = m:GetAttribute("Seat") ~= nil
	m:SetAttribute("Seat", nil)
	if m:GetAttribute("Mood") == "Sit" then
		m:SetAttribute("Mood", nil)
	end
	-- (Time to rise before it walks; the seat is free once it is out of it.)
	task.delay(if satOn then 2 else 0, function()
		give()
		if m.Parent and m:GetAttribute("CommandedBy") == MINE and jobs[m] == nil then
			m:SetAttribute("CommandedBy", nil)
		end
	end)
end

local function free(m: Model): boolean
	local state = m:GetAttribute("RagdollState")
	if ((m:GetAttribute("Slot") :: number?) or 0) <= Lab.PLAZA_SLOTS then
		return false -- (these always walk about on the spawn circle)
	end
	return m.Parent ~= nil and (state == "Standing" or state == "Walking") and m:GetAttribute("Vital") ~= "Dead"
		and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("Mood") == nil and m:GetAttribute("Greeter") == nil
		and m:GetAttribute("InMachine") == nil and m:GetAttribute("MachineHidden") ~= true and m:GetAttribute("Held") ~= true
		and m:GetAttribute("Frozen") ~= true and m:GetAttribute("Chatting") == nil and m:GetAttribute("GreetUntil") == nil
		and ((m:GetAttribute("Broken") :: number?) or 0) == 0
end

local function watch(m: Model, job: Job, now: number)
	local pelvis = pelvisOf(m)
	if not m.Parent or not pelvis or Lab.ownerOf((m:GetAttribute("Plot") :: number?) or -1) ~= job.owner then
		leave(m, job)
		return
	end
	local state = m:GetAttribute("RagdollState")
	local away = flat(pelvis.Position - job.seat.cf.Position).Magnitude
	if m:GetAttribute("CommandedBy") ~= MINE or m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil
		or m:GetAttribute("Frozen") == true then
		leave(m, job)
		return
	end
	if job.phase == "Walk" then
		if m:GetAttribute("Vital") == "Dead" or state == "Ragdoll" or state == "Out" or now - job.since > TRIP_MAX then
			leave(m, job)
		elseif state == "Standing" and away < 5 then
			job.phase = "Sit"
			job.since = now
			job.untilAt = now + rng:NextNumber(SIT_MIN, SIT_MAX)
			m:SetAttribute("Mood", "Sit")
			m:SetAttribute("Seat", job.seat.cf)
			pcall(function() -- (MILD_EXTRAS A1: sometimes a whoopee cushion)
				(require(script.Parent:WaitForChild("CrudeHumor")) :: any).sat(m)
			end)
		end
		return
	end
	local vital = m:GetAttribute("Vital")
	local down = vital == "Dead" or vital == "Unconscious"
	if away > 6 or (not down and (state == "GettingUp" or state == "Crawling" or state == "Walking" or state == "Fleeing")) then
		leave(m, job) -- (blown off, or no longer on it)
		return
	end
	if down then
		job.wasDown = true
		return
	end
	if job.wasDown then
		-- Awake again: it sits a moment, then moves on.
		job.wasDown = false
		job.untilAt = now + rng:NextNumber(5, 9)
	end
	if now >= job.untilAt and state == "Standing" then
		-- (Where it goes once it is up: a few steps straight ahead; its lab then gives it a new place.)
		local ahead = job.seat.cf * CFrame.new(0, 0, -9)
		m:SetAttribute("Home", Vector3.new(ahead.X, pelvis.Position.Y, ahead.Z))
		m:SetAttribute("HomeLook", (job.seat.cf * CFrame.new(0, 0, -15)).Position)
		leave(m, job)
	end
end

local function send(owner: Player, index: number, now: number)
	local set = seatsOf[index]
	if not set then
		return
	end
	local bodies = Lab.dummiesOf(owner)
	local busy = 0
	local ready: { Model } = {}
	for _, m in bodies do
		if jobs[m] then
			busy += 1
		elseif restUntil[m] == nil then
			restUntil[m] = now + rng:NextNumber(5, 40) -- (the first ones sit down soon)
		elseif now >= restUntil[m] and free(m) then
			table.insert(ready, m)
		end
	end
	if #ready == 0 or busy >= math.max(1, math.floor(#bodies * SHARE)) then
		return
	end
	local m = ready[rng:NextInteger(1, #ready)]
	local pelvis = pelvisOf(m)
	if not pelvis then
		return
	end
	-- The nearest free seat that is a walk away (a body only sets out for a Home over 5 studs off).
	local best: Seat? = nil
	local bestD = 90
	for _, seat in set.seats do
		local d = flat(pelvis.Position - (seat.cf * CFrame.new(0, 0, -STAND_OFF)).Position).Magnitude
		if not seat.by and d > 7 and d < bestD then
			best, bestD = seat, d
		end
	end
	if not best then
		return
	end
	best.by = m
	jobs[m] = { seat = best, phase = "Walk", since = now, untilAt = 0, wasDown = false, owner = owner }
	local front = (best.cf * CFrame.new(0, 0, -STAND_OFF)).Position
	m:SetAttribute("CommandedBy", MINE)
	m:SetAttribute("Home", Vector3.new(front.X, pelvis.Position.Y, front.Z))
	m:SetAttribute("HomeLook", (best.cf * CFrame.new(0, 0, -STAND_OFF - 8)).Position)
end

local function step(sendNow: boolean)
	local now = os.clock()
	for m, job in jobs do
		watch(m, job, now)
	end
	local seen: { [number]: boolean } = {}
	for _, player in Players:GetPlayers() do
		local index = Lab.plotIndex(player)
		if index then
			seen[index] = true
			local own = ownedAt[index]
			if not own or own.owner ~= player then
				ownedAt[index] = { owner = player, at = now + 6, tries = 0 }
				local old = seatsOf[index]
				if old then
					old.folder:Destroy()
					seatsOf[index] = nil
				end
			elseif not seatsOf[index] and now >= own.at and own.tries < 6 then
				own.tries += 1
				own.at = now + 10
				build(index, player)
			elseif sendNow then
				send(player, index, now)
			end
		end
	end
	for index, set in seatsOf do
		if not seen[index] then
			set.folder:Destroy()
			seatsOf[index] = nil
			ownedAt[index] = nil
		end
	end
end

local running = false
function BenchService.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		local n = 0
		while true do
			task.wait(0.5)
			n += 1
			local ok, err = pcall(step, n % 6 == 0)
			if not ok then
				warn("[BenchService] " .. tostring(err))
			end
		end
	end)
end

return BenchService
