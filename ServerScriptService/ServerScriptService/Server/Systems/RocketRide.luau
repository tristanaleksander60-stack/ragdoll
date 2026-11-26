--!strict
-- RocketRide (0.37.18, owner 22 Nov 2026: "at the big rocket you press E to strap a ragdoll on, then watch the
-- rocket work"). The lab's rocket (LabDress, V3Assets "Rocket") gets a prompt. E takes the lab's nearest free
-- dummy and straps a still copy of it to the rocket's side with two straps (the real body is hidden meanwhile,
-- so nothing fights the physics); a three-second countdown with smoke, ignition, the rocket climbs faster and
-- faster with fire under it, wobbling, and bursts high up. The real body falls out of the burst, flung, often
-- missing a piece (VitalsService.sever). The rocket fades back onto its spot after a moment.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RocketRide = {}

RocketRide.REACH = 16 -- studs: the prompt's reach
RocketRide.COUNTDOWN = 3 -- s of smoke before the lift-off
RocketRide.FLIGHT = 5 -- s of climbing
RocketRide.ACCEL = 30 -- studs/s^2
RocketRide.BACK_AFTER = 4 -- s after the burst before it stands on its spot again

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function emitter(parent: Instance, color: Color3, size: number, speed: number, rate: number, life: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 2.5) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = Vector2.new(18, 18)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Lifetime = NumberRange.new(life * 0.6, life)
	e.Rate = rate
	e.Enabled = false
	e.Parent = parent
	return e
end

-- A still copy of `model` (its pose round the pelvis, its face) standing at `at`, parented into `into`.
local function stillCopy(model: Model, at: CFrame, into: Instance)
	local pelvis = model:FindFirstChild("LowerTorso")
	if not (pelvis and pelvis:IsA("BasePart")) then
		return
	end
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 1 then
			local c = Instance.new("Part")
			c.Name = "Strapped" .. p.Name
			c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch = true, false, false, false
			c.Size = p.Size
			c.Color = p.Color
			c.Material = Enum.Material.SmoothPlastic
			c.CFrame = at * pelvis.CFrame:ToObjectSpace(p.CFrame)
			c:SetAttribute("RideTemp", true)
			c.Parent = into
			local face = p:FindFirstChild("Face")
			if face and face:IsA("SurfaceGui") then
				local f2 = face:Clone()
				f2.Enabled = true
				f2.Parent = c
			end
		end
	end
end

-- (V11 A5, owner: "only the rocket flies, not the platform"): the model is a rocket on a launch tower. The
-- rocket is the stack of big square-section pieces on one upright axis plus everything close round that axis
-- from the stack's bottom up; the tower, the gantry arms and the base stay where they are.
local function rocketParts(rocket: Model): ({ BasePart }, Vector3?, number, number, number)
	local all: { BasePart } = {}
	for _, d in rocket:GetDescendants() do
		-- (23 Nov 2026, owner: "the little box flies, not the rocket": a TrussPart cannot get thinner than 2 studs, so
		-- in the scaled model the tower's trusses were the widest square pieces and were taken for the rocket.)
		if d:IsA("BasePart") and not d:IsA("TrussPart") then
			table.insert(all, d)
		end
	end
	local w = 0
	for _, p in all do
		if math.abs(p.Size.X - p.Size.Z) < 0.05 * p.Size.X and p.Size.Y > p.Size.X * 0.5 then
			w = math.max(w, p.Size.X)
		end
	end
	local sum, n, bottom = Vector3.zero, 0, math.huge
	local columns: { Vector2 } = {}
	local stackTop = -math.huge
	for _, p in all do
		if w > 0 and math.abs(p.Size.X - w) < 0.05 * w and math.abs(p.Size.Z - w) < 0.05 * w and p.Size.Y > w * 0.5 then
			sum += p.Position
			n += 1
			table.insert(columns, Vector2.new(p.Position.X, p.Position.Z))
			bottom = math.min(bottom, p.Position.Y - p.Size.Y / 2)
			stackTop = math.max(stackTop, p.Position.Y + p.Size.Y / 2)
		end
	end
	if n < 2 then
		return all, nil, 0, 0, 0
	end
	local axis = sum / n
	local fly: { BasePart } = {}
	local top = bottom
	for _, p in all do
		-- (Round any of the rocket's columns: the core and the boosters go up together.)
		local d = math.huge
		for _, c in columns do
			d = math.min(d, (Vector2.new(p.Position.X, p.Position.Z) - c).Magnitude)
		end
		if d < w * 0.8 and math.max(p.Size.X, p.Size.Z) < w * 1.5 and p.Position.Y > bottom - w * 0.6 and p.Position.Y < bottom + (stackTop - bottom) * 1.6 then -- (the nose, not the tower's crane over it)
			table.insert(fly, p)
			top = math.max(top, p.Position.Y + p.Size.Y / 2)
		end
	end
	return fly, axis, w, bottom, top
end

function RocketRide.wire(rocket: Model, origin: Vector3)
	local home = rocket:GetPivot()
	local cf, size = rocket:GetBoundingBox()
	local radius = math.min(size.X, size.Z) / 2
	local fly, axis, w, bottom, top = rocketParts(rocket)
	if axis then
		cf = CFrame.new(axis.X, (bottom + top) / 2, axis.Z)
		size = Vector3.new(w, top - bottom, w)
		radius = w / 2
	end
	local flySet: { [Instance]: boolean } = {}
	for _, p in fly do
		flySet[p] = true
	end
	local frame = if axis then CFrame.new(axis.X, bottom, axis.Z) else home
	-- Moves the flying set (the rocket, its fire, the strapped copy and straps) by `offset` from home.
	local moving: { BasePart } = {}
	local from: { CFrame } = {}
	local function gather()
		table.clear(moving)
		table.clear(from)
		local seen: { [BasePart]: boolean } = {}
		for _, p in fly do
			seen[p] = true
			table.insert(moving, p)
			table.insert(from, p.CFrame)
		end
		for _, d in rocket:GetDescendants() do
			if d:IsA("BasePart") and not seen[d] and (d:GetAttribute("RideTemp") == true or d.Name == "RocketPromptPart") then
				table.insert(moving, d)
				table.insert(from, d.CFrame)
			end
		end
	end
	local function place(offset: CFrame)
		local delta = frame * offset * frame:Inverse()
		local parts: { BasePart } = {}
		local to: { CFrame } = {}
		for i, c in from do
			local p = moving[i]
			if p.Parent then
				table.insert(parts, p)
				table.insert(to, delta * c)
			end
		end
		Workspace:BulkMoveTo(parts, to, Enum.BulkMoveMode.FireCFrameChanged)
	end
	local base = Instance.new("Part")
	base.Name = "RocketPromptPart"
	base.Anchored, base.CanCollide, base.CanQuery, base.CanTouch = true, false, false, false
	base.Transparency = 1
	base.Size = Vector3.new(2, 2, 2)
	base.CFrame = CFrame.new(cf.Position.X, cf.Position.Y - size.Y / 2 + 3, cf.Position.Z)
	base.Parent = rocket
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StrapRagdoll"
	prompt.ActionText = "Strap a ragdoll on"
	prompt.ObjectText = "Rocket"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = RocketRide.REACH
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	local fire = emitter(base, Color3.fromRGB(255, 150, 40), 2, 40, 120, 0.5)
	local smoke = emitter(base, Color3.fromRGB(200, 200, 200), 4, 18, 60, 2.2)
	local busy = false
	prompt.Triggered:Connect(function(player: Player)
		if busy then
			return
		end
		local Lab = lazy("Lab")
		local owner = Lab.ownerAt(origin + Vector3.new(0, 1, 0))
		if not owner then
			return
		end
		-- The nearest free dummy of this lab.
		local best: Model? = nil
		local bestD = math.huge
		for _, m in Lab.dummiesOf(owner) do
			local pelvis = m:FindFirstChild("LowerTorso")
			if m.Parent and pelvis and pelvis:IsA("BasePart") and m:GetAttribute("Held") ~= true and m:GetAttribute("InMachine") == nil
				and m:GetAttribute("MachineHidden") ~= true and m:GetAttribute("Vital") ~= "Dead" then
				local d = (pelvis.Position - base.Position).Magnitude
				if d < bestD then
					best, bestD = m, d
				end
			end
		end
		local body = best
		if not body then
			return
		end
		busy = true
		prompt.Enabled = false
		body:SetAttribute("InMachine", "Rocket")
		body:SetAttribute("MachineHidden", true)
		task.spawn(function()
			local ok, err = pcall(function()
				-- Strapped to the side that faces the lab's middle, with two dark straps.
				local toMid = Vector3.new(origin.X - cf.Position.X, 0, origin.Z - cf.Position.Z)
				local side = if toMid.Magnitude > 0.1 then toMid.Unit else Vector3.xAxis
				local spot = Vector3.new(cf.Position.X, cf.Position.Y - size.Y / 2 + 6.5, cf.Position.Z) + side * (radius + 0.9)
				stillCopy(body, CFrame.lookAt(spot, spot + side), rocket)
				for _, h in { 7.6, 4.6 } do
					local strap = Instance.new("Part")
					strap.Name = "Strap"
					strap.Shape = Enum.PartType.Cylinder
					strap.Anchored, strap.CanCollide, strap.CanQuery, strap.CanTouch = true, false, false, false
					strap.Color = Color3.fromRGB(40, 36, 32)
					strap.Material = Enum.Material.Fabric
					strap.Size = Vector3.new(0.5, radius * 2 + 2.6, radius * 2 + 2.6)
					strap.CFrame = CFrame.new(cf.Position.X, cf.Position.Y - size.Y / 2 + h, cf.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
					strap.Transparency = 0.1
					strap:SetAttribute("RideTemp", true)
					strap.Parent = rocket
				end
				lazy("DummyControl").move(body, CFrame.new(spot))
				gather()
				-- Countdown: smoke, a shake.
				smoke.Enabled = true
				local t0 = os.clock()
				while os.clock() - t0 < RocketRide.COUNTDOWN do
					local k = (os.clock() - t0) / RocketRide.COUNTDOWN
					place(CFrame.new(math.sin(os.clock() * 60) * 0.08 * k, 0, math.cos(os.clock() * 50) * 0.08 * k))
					RunService.Heartbeat:Wait()
				end
				-- Lift-off: faster and faster, a slight wobble.
				fire.Enabled = true
				lazy("FxService").hit(base.Position, 160, "CannonPad")
				t0 = os.clock()
				local height = 0
				while os.clock() - t0 < RocketRide.FLIGHT do
					local t = os.clock() - t0
					height = 0.5 * RocketRide.ACCEL * t * t
					local wob = CFrame.Angles(math.sin(t * 7) * 0.04, 0, math.cos(t * 5) * 0.04)
					place(CFrame.new(0, height, 0) * wob)
					RunService.Heartbeat:Wait()
				end
				-- The burst, high up: the real body falls out of it, flung, a piece or two short.
				fire.Enabled = false
				smoke.Enabled = false
				local burstAt = cf.Position + Vector3.new(0, height, 0)
				local boom = Instance.new("Explosion")
				boom.BlastPressure = 0
				boom.DestroyJointRadiusPercent = 0
				boom.BlastRadius = 14
				boom.Position = burstAt
				boom.Parent = Workspace
				for _, d in rocket:GetDescendants() do
					if d:IsA("BasePart") then
						if d:GetAttribute("RideTemp") == true then
							d:Destroy()
						elseif flySet[d] then
							d:SetAttribute("RideWas", d.Transparency)
							d.Transparency = 1
						end
					end
				end
				if body.Parent then
					lazy("DummyControl").move(body, CFrame.new(burstAt))
					body:SetAttribute("InMachine", nil)
					body:SetAttribute("MachineHidden", nil)
					task.wait(0.1)
					local a = math.random() * math.pi * 2
					pcall(lazy("DummyControl").push, body, Vector3.new(math.cos(a) * 60, 30, math.sin(a) * 60))
					local pieces = { "LeftArm", "RightArm", "LeftLeg", "RightLeg", "LeftHand", "RightFoot" }
					for _ = 1, math.random(0, 2) do
						pcall(lazy("VitalsService").sever, body, pieces[math.random(#pieces)], burstAt)
					end
				end
				-- Back on its spot after a moment.
				place(CFrame.identity)
				task.wait(RocketRide.BACK_AFTER)
				for _, d in rocket:GetDescendants() do
					if d:IsA("BasePart") and d:GetAttribute("RideWas") ~= nil then
						d.Transparency = d:GetAttribute("RideWas") :: number
						d:SetAttribute("RideWas", nil)
					end
				end
				-- (credit for the throw: a lab event, like the other machines)
				pcall(function()
					lazy("ExperimentService").event(owner, "Rocket", 1, "the ROCKET")
				end)
				pcall(function()
					lazy("ProgressService").addTakedowns(owner, 1) -- (V10 phase 2: a takedown)
				end)
			end)
			if not ok then
				warn("[RocketRide] " .. tostring(err))
				place(CFrame.identity)
				for _, d in rocket:GetDescendants() do
					if d:IsA("BasePart") and d:GetAttribute("RideTemp") == true then
						d:Destroy()
					end
				end
			end
			if body.Parent then
				body:SetAttribute("InMachine", nil)
				body:SetAttribute("MachineHidden", nil)
			end
			fire.Enabled = false
			smoke.Enabled = false
			busy = false
			prompt.Enabled = true
		end)
	end)
end

return RocketRide
