--!strict
-- DropSpots (owner 27 Nov late: "der er slet ingen DROP HERE ved hver maskine når du holder en ragdoll ... kun ved 1 maskine
-- ad gangen"). Every machine, ride or station that takes a ragdoll you carry marks WHERE it goes with one invisible anchored
-- part tagged "DropSpot". Client/LabGuideClient shows the DROP HERE sign (a fixed size on screen) over the ONE nearest spot
-- within 40 studs while you carry a body (DROP_HERE_V2), and never over two at once.
-- Use: DropSpots.add(machineModel, worldPosition, "Bowling") once when the machine is built; the spot is parented to the
-- machine, so it goes with it (a hidden lab takes it off the screen too).

local CollectionService = game:GetService("CollectionService")

local DropSpots = {}

function DropSpots.add(parent: Instance, at: Vector3, name: string): BasePart
	local old = parent:FindFirstChild("DropSpot_" .. name)
	if old and old:IsA("BasePart") then
		old.Position = at
		return old
	end
	local p = Instance.new("Part")
	p.Name = "DropSpot_" .. name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.CastShadow = false
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.Position = at
	p:SetAttribute("Machine", name)
	CollectionService:AddTag(p, "DropSpot")
	p.Parent = parent
	return p
end

-- (FIXES_28NOV 4: every machine that takes a carried ragdoll gets its spot. Rather than a call in a dozen machine
-- systems, scan() finds each machine's load part in a lab by its name and marks the point just above it. It runs a few
-- times after the labs are built (cheap: named lookups only), never per frame.)
local function top(p: BasePart, up: number?): Vector3
	-- (a lying cylinder (a round pad) has its height on X, not Y: its top is just over its middle)
	local half = if p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then p.Size.X / 2 else p.Size.Y / 2
	return p.Position + Vector3.new(0, half + (up or 1), 0)
end
local function find(root: Instance, name: string): BasePart?
	local d = root:FindFirstChild(name, true)
	return if d and d:IsA("BasePart") then d else nil
end
-- (DROPSPOT_STABLE, RUN 1.8: scan() runs a few times, and a spot is a child of its machine's model, so the next scan's
-- GetBoundingBox took the spot in too: the bear's DROP HERE crept out 4 studs and more each scan (53 studs off the
-- bear, far past its 16-stud reach, so a body dropped there was never taken) and the stretch machine's crept up.
-- Now a model is measured without its own DropSpot children.)
local function boxOf(m: Model): (CFrame, Vector3)
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.DROPSPOT_STABLE then
		return m:GetBoundingBox()
	end
	local away: { Instance } = {}
	for _, c in m:GetChildren() do
		if string.sub(c.Name, 1, 9) == "DropSpot_" then
			table.insert(away, c)
			c.Parent = nil
		end
	end
	local cf, size = m:GetBoundingBox()
	for _, c in away do
		c.Parent = m
	end
	return cf, size
end
function DropSpots.scan(lab: Instance)
	local om = lab:FindFirstChild("OwnerMap")
	local function at(name: string, part: BasePart?, up: number?)
		if part then
			DropSpots.add(part.Parent :: Instance, top(part, up), name)
		end
	end
	local stretch = lab:FindFirstChild("StretchMachine")
	if stretch and stretch:IsA("Model") then
		local cf, size = boxOf(stretch)
		DropSpots.add(stretch, cf.Position + Vector3.new(0, size.Y / 2 + 1, 0), "Stretch")
	end
	at("Boxing", find(lab, "RingCanvas"))
	local compressor = lab:FindFirstChild("Compressor", true)
	at("Press", compressor and find(compressor, "Bed"))
	local fan = lab:FindFirstChild("GiantFan")
	local mouth = fan and find(fan, "FanMouth")
	if mouth and fan then
		local ground = mouth.Position + mouth.CFrame.LookVector * 0 -- (in front of the mouth, at the floor)
		local away = Vector3.new(mouth.Position.X - fan:GetPivot().Position.X, 0, mouth.Position.Z - fan:GetPivot().Position.Z)
		local spot = Vector3.new(ground.X, fan:GetPivot().Position.Y + 1, ground.Z) + (if away.Magnitude > 0.1 then away.Unit * 4 else Vector3.zero)
		DropSpots.add(fan, spot, "Fan")
	end
	if om then
		at("Rocket", find(om, "RocketPad"))
		at("Gyro", find(om, "GyroPad"))
		at("Sweeper", find(om, "SweeperPad"))
		at("Shredder", find(om, "ShredderPit"))
		at("Seesaw", find(om, "SeesawPlank"))
		at("TRex", find(om, "TRexGround"))
		-- (the bear: the DROP HERE sign sat ON the bear (its box middle); now on the ground in front of its mouth)
		local bearModel = om:FindFirstChild("Bear", true)
		if bearModel and bearModel:IsA("Model") then
			local bcf, bsize = boxOf(bearModel)
			local front = bcf.Position + bearModel:GetPivot().LookVector * (bsize.Z / 2 + 4)
			DropSpots.add(bearModel, Vector3.new(front.X, bcf.Position.Y - bsize.Y / 2 + 1, front.Z), "Bear")
		else
			at("Bear", find(om, "BearPoke"), -1)
		end
		local whale = om:FindFirstChild("PoolWhale")
		if whale and whale:IsA("Model") then
			DropSpots.add(whale, whale:GetPivot().Position + Vector3.new(0, 2, 0), "Whale")
		end
		local tesla = find(om, "TeslaBase")
		if tesla then
			DropSpots.add(tesla.Parent :: Instance, tesla.Position + Vector3.new(0, 1, 6), "Tesla")
		end
		-- the tower: its highest floor (DropScore's drop)
		local best: BasePart? = nil
		for _, d in om:GetChildren() do
			if d.Name == "TowerFloor" and d:IsA("BasePart") and (not best or d.Position.Y > best.Position.Y) then
				best = d
			end
		end
		at("Tower", best)
	end
	local bowling = lab:FindFirstChild("RagdollBowling")
	local lever = bowling and find(bowling, "LeverBase")
	local bed = bowling and find(bowling, "Bed")
	if lever and bed and bowling then
		-- the lane's start: the bed's top at the lever's end
		local half = bed.Size.X / 2 - 4
		local dir = if lever.Position.X > bed.Position.X then 1 else -1
		DropSpots.add(bowling, Vector3.new(bed.Position.X + dir * half, bed.Position.Y + bed.Size.Y / 2 + 1, bed.Position.Z), "Bowling")
	end
	local vehicles = lab:FindFirstChild("Vehicles")
	for _, v in if vehicles then vehicles:GetChildren() else {} do
		if string.sub(v.Name, 1, 13) == "LabWheelchair" then
			local body = find(v, "Body")
			at("Chair", body)
		end
	end
end

function DropSpots.start()
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
	if Config.DROP_SPOTS_SCAN == false then
		return
	end
	task.spawn(function()
		for _ = 1, 12 do
			task.wait(5)
			local root = workspace:FindFirstChild("Playground")
			for _, lab in if root then root:GetChildren() else {} do
				pcall(DropSpots.scan, lab)
			end
		end
	end)
end

return DropSpots
