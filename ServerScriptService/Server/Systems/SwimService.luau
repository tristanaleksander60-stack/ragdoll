--!strict
-- F78 part 1 (owner: "ragdollen skal svømme eller drukne"; Config.REAL_WATER): ragdolls in the real terrain water. Every
-- water body has an invisible box tagged WaterVolume (LabOwnerMap realWater). 5 times a second each ragdoll near one is
-- tested (pelvis inside the box):
--   * going in: a splash cry ("Help!", "I can't swim!", "Cold!") and the attribute InWater (the terrain water itself
--     makes the limp body float and bob);
--   * a living, awake one that is not held climbs out after SWIM_FOR s: it is set standing on the bank just outside the
--     nearest side of the box, facing away from the water, and says "Brr!" (attribute Wet for 20 s: drips on screens);
--   * a knocked-out or dead one just floats (kid-friendly: no drowning effects beyond that).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SwimService = {}

SwimService.SWIM_FOR = 8
SwimService.LINES_IN = { "Help!", "I can't swim!", "Cold!", "Splash!" }
SwimService.LINES_OUT = { "Brr!", "So cold!", "I'm soaked!" }

local since: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local SPLASH_FLOAT = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).SPLASH_FLOAT == true
local BUOYANCY_V2 = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BUOYANCY_V2 == true

local function say(m: Model, line: string)
	m:SetAttribute("MoodSay", line)
	task.delay(2.5, function()
		if m.Parent and m:GetAttribute("MoodSay") == line then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

local function boxOf(at: Vector3): BasePart?
	for _, v in CollectionService:GetTagged("WaterVolume") do
		if v:IsA("BasePart") then
			local l = v.CFrame:PointToObjectSpace(at)
			local h = v.Size / 2 + Vector3.new(0.5, 2, 0.5)
			if math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z then
				return v
			end
		end
	end
	return nil
end

local function climbOut(m: Model, box: BasePart, at: Vector3)
	local l = box.CFrame:PointToObjectSpace(at)
	local h = box.Size / 2
	-- the nearest side, 4 studs past it
	local dx, dz = h.X - math.abs(l.X), h.Z - math.abs(l.Z)
	local out = if dx < dz then Vector3.new(math.sign(l.X) * (h.X + 5), 0, l.Z) else Vector3.new(l.X, 0, math.sign(l.Z) * (h.Z + 5))
	local world = box.CFrame:PointToWorldSpace(out)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { (m.Parent or m) :: Instance } -- (every ragdoll: only real ground)
	local hit = Workspace:Raycast(world + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), params)
	if not hit then
		return
	end
	local stand = hit.Position + Vector3.new(0, 3.2, 0)
	local away = Vector3.new(stand.X - box.Position.X, 0, stand.Z - box.Position.Z)
	local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
	pcall(DC.move, m, CFrame.lookAt(stand, stand + (if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis)))
	m:SetAttribute("Home", stand)
	m:SetAttribute("Wet", true)
	say(m, SwimService.LINES_OUT[math.random(1, #SwimService.LINES_OUT)])
	task.delay(20, function()
		if m.Parent then
			m:SetAttribute("Wet", nil)
		end
	end)
end

-- F78 part 3 (Config.SPLASH_FLOAT): a splash where a body goes in (a burst of white-blue drops at the surface), and in
-- the aquarium, whose water is now parts (F87 AQUA_PARTS, no terrain water to hold a body up), code buoyancy: a body
-- below the surface is lifted toward it and slowed in the water, so it floats and bobs as in the pools.
local function splash(box: BasePart, at: Vector3)
	local top = box.Position.Y + box.Size.Y / 2
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = Vector3.new(at.X, top, at.Z)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(210, 235, 255))
	e.Size = NumberSequence.new(0.6, 0.2)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Speed = NumberRange.new(10, 18)
	e.SpreadAngle = Vector2.new(35, 35)
	e.Acceleration = Vector3.new(0, -50, 0)
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.EmissionDirection = Enum.NormalId.Top
	e.Enabled = false
	e.Parent = p
	p.Parent = Workspace
	e:Emit(36)
	game:GetService("Debris"):AddItem(p, 2)
end

local function float(box: BasePart, m: Model)
	local top = box.Position.Y + box.Size.Y / 2
	for _, pe in m:GetChildren() do
		if pe:IsA("BasePart") and not pe.Anchored then
			local depth = top - 0.8 - pe.Position.Y
			local v = pe.AssemblyLinearVelocity
			local up = if depth > 0 then math.clamp(depth * 6, 2, 14) else math.min(v.Y, 0) * 0.5
			pe.AssemblyLinearVelocity = Vector3.new(v.X * 0.8, if depth > 0 then math.max(v.Y * 0.5, up) else up, v.Z * 0.8)
		end
	end
end

-- Row 5 (Config.BUOYANCY_V2; RAGDOLL_FEEL "Water: buoyancy by part volume"): in the part-water tanks every limb gets its
-- own upward force by how much of its volume is under the surface (1.4x its own weight when fully under, so a body
-- floats about two thirds under, head and arms bobbing on their own), plus water drag on that limb. A VectorForce per
-- limb, not a velocity write, so it works on whichever screen simulates the body and never fights it. Taken off when
-- the body leaves the water or is picked up.
local BUOY_LIFT = 1.4
local BUOY_DRAG = 1.6
local function buoyancy(box: BasePart?, m: Model)
	local top = if box then box.Position.Y + box.Size.Y / 2 else 0
	for _, pe in m:GetChildren() do
		if pe:IsA("BasePart") and not pe.Anchored then
			local force = pe:FindFirstChild("BuoyForce")
			if not box then
				if force then
					force:Destroy()
					local att = pe:FindFirstChild("BuoyAttachment")
					if att then
						att:Destroy()
					end
				end
				continue
			end
			local mass = pe:GetMass()
			if mass <= 0 then
				continue
			end
			if not (force and force:IsA("VectorForce")) then
				local att = Instance.new("Attachment")
				att.Name = "BuoyAttachment"
				att.Parent = pe
				local vf = Instance.new("VectorForce")
				vf.Name = "BuoyForce"
				vf.RelativeTo = Enum.ActuatorRelativeTo.World
				vf.ApplyAtCenterOfMass = true
				vf.Attachment0 = att
				vf.Parent = pe
				force = vf
			end
			local half = pe.Size.Y / 2
			local under = math.clamp((top - (pe.Position.Y - half)) / math.max(pe.Size.Y, 0.1), 0, 1)
			local v = pe:GetVelocityAtPosition(pe.Position)
			local g = Workspace.Gravity
			local lift = Vector3.new(0, under * mass * g * BUOY_LIFT, 0)
			local drag = -v * mass * BUOY_DRAG * under
			;(force :: VectorForce).Force = lift + drag
		end
	end
end

local function step(dummies: Instance)
	if #CollectionService:GetTagged("WaterVolume") == 0 then
		return
	end
	local now = os.clock()
	for _, m in dummies:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		if not (m:IsA("Model") and pe and pe:IsA("BasePart")) then
			continue
		end
		local box = boxOf(pe.Position)
		if BUOYANCY_V2 and (not box or box.Name ~= "AquaWaterVolume" or m:GetAttribute("Held") == true) and pe:FindFirstChild("BuoyForce") then
			buoyancy(nil, m :: any) -- (out of the tank or picked up: the forces come off)
		end
		if not box then
			if since[m] then
				since[m] = nil
				m:SetAttribute("InWater", nil)
			end
			continue
		end
		if not since[m] then
			since[m] = now
			m:SetAttribute("InWater", true)
			if SPLASH_FLOAT then
				splash(box, pe.Position)
			end
			local vital = m:GetAttribute("Vital")
			if vital ~= "Dead" and vital ~= "Unconscious" then
				say(m, SwimService.LINES_IN[math.random(1, #SwimService.LINES_IN)])
			end
		end
		if BUOYANCY_V2 and box.Name == "AquaWaterVolume" and m:GetAttribute("Held") ~= true then
			buoyancy(box, m :: any)
		elseif SPLASH_FLOAT and box.Name == "AquaWaterVolume" and m:GetAttribute("Held") ~= true then
			float(box, m :: any)
		end
		local vital = m:GetAttribute("Vital")
		local awake = vital ~= "Dead" and vital ~= "Unconscious"
		if awake and m:GetAttribute("Held") ~= true and m:GetAttribute("InMachine") == nil and now - (since[m] :: number) > SwimService.SWIM_FOR then
			since[m] = nil
			m:SetAttribute("InWater", nil)
			climbOut(m, box, pe.Position)
		end
	end
end

function SwimService.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.REAL_WATER then
		return
	end
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		while true do
			task.wait(0.2)
			pcall(step, dummies)
		end
	end)
end

return SwimService
