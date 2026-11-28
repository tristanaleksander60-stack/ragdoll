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
		-- (ROCKET_WHOLE: the top of the rocket (the capsule and the nose, wider than the columns or above 1.6 x the stack)
		-- stayed on the tower. Now every part centred over the rocket's footprint and narrower than 2.2 column widths goes,
		-- up to 3 widths over the stack: the tower's crane arm is long and stays.)
		local whole = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ROCKET_WHOLE == true
		local reach = if whole then w * 1.2 else w * 0.8
		local widest = if whole then w * 2.2 else w * 1.5
		local high = if whole then stackTop + w * 3 else bottom + (stackTop - bottom) * 1.6
		if d < reach and math.max(p.Size.X, p.Size.Z) < widest and p.Position.Y > bottom - w * 0.6 and p.Position.Y < high then -- (the nose, not the tower's crane over it)
			table.insert(fly, p)
			top = math.max(top, p.Position.Y + p.Size.Y / 2)
		end
	end
	return fly, axis, w, bottom, top
end

-- 3.9 ROCKET (docs/MACHINES_10.md; Config.ROCKET_10): a 3-2-1 board over the pad, fireworks at the top, the body
-- comes down under a small parachute, drifting to a random spot in the lab, the height pops ("375 studs HIGH!") with a
-- NEW BEST for the lab's owner (RocketBest), and 1 in 20 is GOLDEN: "TO THE MOON!" with stars and +5 KOs.
local function on10(): boolean
	return (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ROCKET_10 == true
end

local function fireworks(at: Vector3, golden: boolean)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.Position = at
	p.Parent = Workspace
	local colours = if golden then { Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 250, 200) } else { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 200, 255), Color3.fromRGB(120, 255, 120), Color3.fromRGB(255, 220, 80) }
	for i, c in colours do
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(c)
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.2) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		e.Speed = NumberRange.new(30, 45)
		e.Drag = 2
		e.Acceleration = Vector3.new(0, -8, 0)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Lifetime = NumberRange.new(1.2, 2)
		e.Rate = 0
		if golden then
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		end
		e.Parent = p
		task.delay((i - 1) * 0.25, function()
			e:Emit(if golden then 80 else 50)
		end)
	end
	task.delay(4, function()
		p:Destroy()
	end)
end

-- The body drifts down under a parachute from `from` to a random spot in the lab round `origin`.
local function parachute(body: Model, from: Vector3, origin: Vector3)
	local a = math.random() * math.pi * 2
	local r = math.random(15, 60)
	local target = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	local params = RaycastParams.new()
	local dummies = Workspace:FindFirstChild("Dummies")
	params.FilterDescendantsInstances = if dummies then { dummies } else {}
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = Workspace:Raycast(target + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), params)
	local ground = if hit then hit.Position.Y else origin.Y
	local start = Vector3.new(target.X + (from.X - target.X) * 0.25, ground + 70, target.Z + (from.Z - target.Z) * 0.25)
	local canopy = Instance.new("Part")
	canopy.Name = "Parachute"
	canopy.Shape = Enum.PartType.Ball
	canopy.Size = Vector3.new(7, 7, 7)
	canopy.Anchored, canopy.CanCollide, canopy.CanQuery, canopy.CanTouch = true, false, false, false
	canopy.Color = Color3.fromRGB(240, 90, 60)
	canopy.Material = Enum.Material.Fabric
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.45, 1)
	mesh.Parent = canopy
	canopy.Parent = Workspace
	body:SetAttribute("InMachine", "Parachute")
	local DC = lazy("DummyControl")
	local t0 = os.clock()
	local fall = 70 / 9 -- (9 s down)
	while body.Parent do
		local t = os.clock() - t0
		local y = start.Y - fall * t
		if y <= ground + 3 then
			break
		end
		local k = math.clamp(t / 9, 0, 1)
		local pos = start:Lerp(Vector3.new(target.X, start.Y, target.Z), k)
		local sway = math.sin(t * 1.7) * 1.2
		local at = Vector3.new(pos.X + sway, y, pos.Z)
		pcall(DC.move, body, CFrame.new(at) * CFrame.Angles(0, 0, math.sin(t * 1.7) * 0.15))
		canopy.CFrame = CFrame.new(at + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.sin(t * 1.7) * 0.15)
		task.wait(0.05)
	end
	body:SetAttribute("InMachine", nil)
	canopy.Anchored = false
	canopy.CanCollide = false
	task.delay(2, function()
		canopy:Destroy()
	end)
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
	local board: TextLabel? = nil
	if on10() then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(160, 80)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
		gui.MaxDistance = 140
		gui.AlwaysOnTop = true
		gui.Parent = base
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.fromRGB(255, 230, 90)
		l.TextStrokeTransparency = 0.2
		l.Text = ""
		l.Parent = gui
		board = l
	end
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
		-- (ROCKET_WALK: the ragdoll WALKS to the rocket's foot first (up to 14 s), then it is strapped on; no teleport
		-- from across the lab)
		if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ROCKET_WALK then
			local foot = Vector3.new(cf.Position.X, base.Position.Y, cf.Position.Z)
			local pe0 = body:FindFirstChild("LowerTorso")
			local away = if pe0 and pe0:IsA("BasePart") then Vector3.new(pe0.Position.X - foot.X, 0, pe0.Position.Z - foot.Z) else Vector3.xAxis
			local stand = foot + (if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis) * (radius + 4)
			body:SetAttribute("TryFor", owner.UserId)
			body:SetAttribute("Home", stand)
			body:SetAttribute("HomeLook", foot)
			body:SetAttribute("Pace", 1.6)
			body:SetAttribute("MoodSay", "To the moon!")
			local t0 = os.clock()
			while os.clock() - t0 < 14 do
				task.wait(0.25)
				local pe = body:FindFirstChild("LowerTorso")
				if not (pe and pe:IsA("BasePart") and body.Parent) or body:GetAttribute("Held") == true then
					break
				end
				if Vector3.new(pe.Position.X - stand.X, 0, pe.Position.Z - stand.Z).Magnitude < 3.5 then
					break
				end
			end
			body:SetAttribute("Pace", nil)
			body:SetAttribute("TryFor", nil)
			body:SetAttribute("MoodSay", nil)
		end
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
					if board then
						board.Text = if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).WORLD_POPS == false then "" else tostring(math.max(1, RocketRide.COUNTDOWN - math.floor(os.clock() - t0)))
					end
					place(CFrame.new(math.sin(os.clock() * 60) * 0.08 * k, 0, math.cos(os.clock() * 50) * 0.08 * k))
					RunService.Heartbeat:Wait()
				end
				-- Lift-off: faster and faster, a slight wobble.
				if board then
					board.Text = if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).WORLD_POPS == false then "" else "LIFT OFF!"
					task.delay(1.5, function()
						if board then
							board.Text = ""
						end
					end)
				end
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
				if body.Parent and on10() then
					local golden = math.random(20) == 1
					fireworks(burstAt, golden)
					local h = math.floor(height + 0.5)
					local text = tostring(h) .. " studs HIGH!"
					if golden then
						text = "TO THE MOON! " .. text
						pcall(function()
							lazy("ProgressService").addTakedowns(owner, 5)
						end)
					end
					local best = (owner:GetAttribute("RocketBest") :: number?) or 0
					if h > best then
						owner:SetAttribute("RocketBest", h)
						text ..= " NEW BEST!"
					end
					pcall(function()
						lazy("Playground").pop(base.Position + Vector3.new(0, 12, 0), text, if golden then Color3.fromRGB(255, 220, 80) else Color3.fromRGB(255, 255, 255))
					end)
					body:SetAttribute("MachineHidden", nil)
					task.spawn(parachute, body, burstAt, origin)
				elseif body.Parent then
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
			if body.Parent and body:GetAttribute("InMachine") ~= "Parachute" then
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
