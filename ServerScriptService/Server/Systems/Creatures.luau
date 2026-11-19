--!strict
-- v3 Phase C (19 Nov 2026; research: animals and "escalating chaos" are top requests and video
-- formats): the animals of two lab events, built by code (blocky, cartoon, no blood).
--   Gorilla Rampage: a big gorilla stomps after the nearest dummy and swats it across the lab
--     (players who get in its way fly too, unhurt).
--   Bull Run: three bulls thunder across the lab one after another, throwing whatever is in the lane.
-- The server moves them (anchored, PivotTo) and knocks bodies through DummyControl.hit and
-- PlayerRagdoll.knock, as a blast does. Each returns a stop function for the event's clean-up.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent
local DummyControl = require(Systems.DummyControl)
local FxService = require(Systems.FxService)
local PlayerRagdoll = require(Systems.PlayerRagdoll)
local V3Assets = require(Systems.V3Assets)

local Creatures = {}

Creatures.GORILLA_SPEED = 16 -- studs/s
Creatures.GORILLA_REACH = 8 -- studs from its middle to swat
Creatures.GORILLA_SWAT = 85 -- body speed a swat gives
Creatures.GORILLA_GAP = 0.7 -- s between swats
Creatures.BULL_SPEED = 48
Creatures.BULL_REACH = 5.5
Creatures.BULL_THROW = 95
Creatures.HALF = 70 -- studs from the lab's middle the animals keep inside

local function block(model: Model, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = offset
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function folder(): Folder
	local f = Workspace:FindFirstChild("Creatures")
	if f and f:IsA("Folder") then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "Creatures"
	made.Parent = Workspace
	return made
end

-- A gorilla standing at the origin facing -Z (feet on y = 0).
local function gorillaModel(): (Model, { [string]: BasePart })
	local fur = Color3.fromRGB(46, 44, 48)
	local skin = Color3.fromRGB(96, 84, 80)
	local m = Instance.new("Model")
	m.Name = "Gorilla"
	local parts: { [string]: BasePart } = {}
	parts.body = block(m, "Body", Vector3.new(6, 6, 4.5), CFrame.new(0, 7.5, 0), fur)
	m.PrimaryPart = parts.body
	block(m, "Chest", Vector3.new(4, 3.4, 0.4), CFrame.new(0, 7.8, -2.3), skin)
	parts.head = block(m, "Head", Vector3.new(3.4, 3, 3), CFrame.new(0, 11.6, -0.8), fur)
	block(m, "Face", Vector3.new(2.6, 2, 0.4), CFrame.new(0, 11.3, -2.4), skin)
	for _, side in { -1, 1 } do
		block(m, "Eye", Vector3.new(0.5, 0.5, 0.2), CFrame.new(side * 0.6, 11.8, -2.62), Color3.fromRGB(250, 250, 250))
		parts["arm" .. side] = block(m, "Arm", Vector3.new(1.8, 7, 1.8), CFrame.new(side * 4, 6.2, -0.6), fur)
		parts["fist" .. side] = block(m, "Fist", Vector3.new(2.2, 1.6, 2.2), CFrame.new(side * 4, 2.4, -0.6), skin)
		parts["leg" .. side] = block(m, "Leg", Vector3.new(2, 4.5, 2), CFrame.new(side * 1.7, 2.25, 0.4), fur)
	end
	return m, parts
end

-- A bull standing at the origin facing -Z.
local function bullModel(): Model
	local hide = Color3.fromRGB(70, 44, 32)
	local m = Instance.new("Model")
	m.Name = "Bull"
	local body = block(m, "Body", Vector3.new(4, 4, 8), CFrame.new(0, 4.5, 0), hide)
	m.PrimaryPart = body
	block(m, "Head", Vector3.new(3, 3, 3), CFrame.new(0, 5.2, -5), hide)
	block(m, "Snout", Vector3.new(2.2, 1.4, 0.8), CFrame.new(0, 4.4, -6.7), Color3.fromRGB(190, 140, 130))
	for _, side in { -1, 1 } do
		block(m, "Horn", Vector3.new(2.2, 0.6, 0.6), CFrame.new(side * 2.4, 6.6, -5.2) * CFrame.Angles(0, 0, side * math.rad(-25)), Color3.fromRGB(240, 232, 210))
		for _, z in { -2.8, 2.8 } do
			block(m, "Leg", Vector3.new(1.1, 2.6, 1.1), CFrame.new(side * 1.4, 1.3, z), hide)
		end
	end
	return m
end

local function knock(model: Model, from: Vector3, speed: number, lift: number)
	local pelvis = model:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") then
		return
	end
	local offset = pelvis.Position - from
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) + Vector3.new(0, lift, 0)).Unit
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	DummyControl.hit(model, pelvis, dir * speed * mass, pelvis.Position)
end

local function knockPlayers(from: Vector3, reach: number, speed: number, lift: number, center: Vector3, done: { [Player]: boolean }?)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and not (done and done[player]) and math.abs(root.Position.Y - center.Y) < 20 then
			local offset = root.Position - from
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude < reach and math.abs(root.Position.X - center.X) < Creatures.HALF + 10 then
				local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) + Vector3.new(0, lift, 0)).Unit
				PlayerRagdoll.knock(player, dir * speed * 0.7)
				if done then
					done[player] = true
				end
			end
		end
	end
end

type Body = { model: Model, pelvis: BasePart }
local function dummiesIn(center: Vector3): { Body }
	local out: { Body } = {}
	local f = Workspace:FindFirstChild("Dummies")
	for _, model in if f then f:GetChildren() else {} do
		local pelvis = model:FindFirstChild("LowerTorso")
		if model:IsA("Model") and pelvis and pelvis:IsA("BasePart") then
			local o = pelvis.Position - center
			if math.abs(o.X) < Creatures.HALF and o.Z > -95 and o.Z < 72 then
				table.insert(out, { model = model, pelvis = pelvis })
			end
		end
	end
	return out
end

-- Gorilla Rampage in the lab around `center` (the lab's middle at floor height).
function Creatures.gorilla(center: Vector3): () -> ()
	local model, parts = gorillaModel()
	local base: { [BasePart]: CFrame } = {}
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			base[p] = p.CFrame
		end
	end
	local at = center + Vector3.new(0, 0, 60)
	local facing = 0
	-- v3: the Creator Store gorilla when the place has one (V3Assets "Gorilla"); the blocky one is
	-- the fallback.
	local look = V3Assets.place("Gorilla", folder(), CFrame.new(at), { height = 13, collide = false })
	if look then
		table.clear(base)
		model:Destroy()
		model = look
	end
	local function place(t: number)
		local bob = math.abs(math.sin(t * 6)) * 0.6
		local root = CFrame.new(at) * CFrame.Angles(0, facing, 0) * CFrame.new(0, bob, 0)
		if look then
			look:PivotTo(root)
			return
		end
		for p, cf in base do
			local extra = CFrame.identity
			-- (An arm and its fist swing together about the shoulder, 9.7 studs up.)
			local side = if p == parts["arm-1"] or p == parts["fist-1"] then -1 elseif p == parts["arm1"] or p == parts["fist1"] then 1 else 0
			if side ~= 0 then
				local swing = math.sin(t * 6 + (if side == 1 then math.pi else 0)) * 0.5
				local shoulder = CFrame.new(0, 9.7, -0.6)
				p.CFrame = root * shoulder * CFrame.Angles(swing, 0, 0) * shoulder:Inverse() * cf
				continue
			end
			p.CFrame = root * cf * extra
		end
	end
	place(0)
	model.Parent = folder()
	FxService.hit(at + Vector3.new(0, 4, 0), 120, "BigBoom")
	local lastSwat = 0
	local t = 0
	local bodies: { Body } = {}
	local scannedAt = -1
	local connection = RunService.Heartbeat:Connect(function(dt)
		t += dt
		-- (The lab's dummies, looked up five times a second, not every frame.)
		if t - scannedAt > 0.2 then
			scannedAt = t
			bodies = dummiesIn(center)
		end
		-- The nearest dummy standing in the lab.
		local target: Vector3? = nil
		local best = math.huge
		for _, d in bodies do
			if not d.pelvis.Parent then
				continue
			end
			local dist = (d.pelvis.Position - at).Magnitude
			if dist < best then
				best, target = dist, d.pelvis.Position
			end
		end
		local goal = target or center
		local flat = Vector3.new(goal.X - at.X, 0, goal.Z - at.Z)
		if flat.Magnitude > 2 then
			local step = flat.Unit * math.min(flat.Magnitude, Creatures.GORILLA_SPEED * dt)
			at += step
			facing = math.atan2(-flat.X, -flat.Z)
		end
		local o = at - center
		at = center + Vector3.new(math.clamp(o.X, -Creatures.HALF, Creatures.HALF), 0, math.clamp(o.Z, -90, 68))
		place(t)
		if os.clock() - lastSwat > Creatures.GORILLA_GAP then
			local swatted = false
			for _, d in bodies do
				if d.pelvis.Parent and (d.pelvis.Position - at).Magnitude < Creatures.GORILLA_REACH then
					knock(d.model, at, Creatures.GORILLA_SWAT, 0.9)
					swatted = true
				end
			end
			if swatted then
				lastSwat = os.clock()
				FxService.hit(at + Vector3.new(0, 3, 0), 90, "BigBoom")
				knockPlayers(at, Creatures.GORILLA_REACH, Creatures.GORILLA_SWAT, 0.9, center)
			end
		end
	end)
	return function()
		connection:Disconnect()
		model:Destroy()
	end
end

-- Bull Run in the lab around `center`: three bulls across the lab, one after another.
function Creatures.bulls(center: Vector3): () -> ()
	local running = true
	local made: { Model } = {}
	local connections: { RBXScriptConnection } = {}
	task.spawn(function()
		for i = 1, 3 do
			if not running then
				return
			end
			local z = -40 + (i - 1) * 30 -- three lanes across the lab
			local fromLeft = i % 2 == 1
			local x0 = if fromLeft then -Creatures.HALF else Creatures.HALF
			local dirX = if fromLeft then 1 else -1
			local facing = if fromLeft then -math.pi / 2 else math.pi / 2
			local at = center + Vector3.new(x0, 0, z)
			-- (v3: the Creator Store bull when the place has one; the blocky one is the fallback.)
			local asset = V3Assets.place("Bull", folder(), CFrame.new(at) * CFrame.Angles(0, facing, 0), { height = 7, collide = false })
			local bull = asset or bullModel()
			local base: { [BasePart]: CFrame } = {}
			if not asset then
				for _, p in bull:GetChildren() do
					if p:IsA("BasePart") then
						base[p] = p.CFrame
					end
				end
			end
			local hit: { [Model]: boolean } = {}
			local hitPlayers: { [Player]: boolean } = {}
			bull.Parent = folder()
			table.insert(made, bull)
			FxService.hit(at, 70, "BigBoom")
			local t = 0
			local scanned = -1
			local bodies: { Body } = {}
			local c: RBXScriptConnection
			c = RunService.Heartbeat:Connect(function(dt)
				t += dt
				at += Vector3.new(dirX * Creatures.BULL_SPEED * dt, 0, 0)
				local root = CFrame.new(at) * CFrame.Angles(0, facing, 0) * CFrame.new(0, math.abs(math.sin(t * 14)) * 0.5, 0)
				if asset then
					asset:PivotTo(root)
				end
				for p, cf in base do
					p.CFrame = root * cf
				end
				if t - scanned > 0.15 then
					scanned = t
					bodies = dummiesIn(center)
				end
				for _, d in bodies do
					if not d.pelvis.Parent then
						continue
					end
					local o = d.pelvis.Position - at
					if not hit[d.model] and math.abs(o.Z) < Creatures.BULL_REACH and math.abs(o.X) < Creatures.BULL_REACH + 1 then
						hit[d.model] = true
						knock(d.model, at - Vector3.new(dirX * 4, 0, 0), Creatures.BULL_THROW, 1.1)
					end
				end
				knockPlayers(at, Creatures.BULL_REACH, Creatures.BULL_THROW, 1.1, center, hitPlayers)
				if math.abs(at.X - center.X) > Creatures.HALF + 2 then
					c:Disconnect()
					bull:Destroy()
				end
			end)
			table.insert(connections, c)
			task.wait(4)
		end
	end)
	return function()
		running = false
		for _, c in connections do
			c:Disconnect()
		end
		for _, m in made do
			m:Destroy()
		end
	end
end

------------------------------------------------------------------------------------------------
-- v3 Phase C disasters (19 Nov 2026): a tornado that wanders the lab and spins everything into the
-- sky, and a meteor shower that craters it. Pictures and pushes only (nothing stays behind).

Creatures.TORNADO_SPEED = 14 -- studs/s
Creatures.TORNADO_REACH = 16 -- studs: inside this a body is lifted
Creatures.TORNADO_LIFT = 70 -- studs/s up (plus a spin of half that)
Creatures.METEOR_GAP = 0.55 -- s between two meteors
Creatures.METEOR_FALL = 1.1 -- s from the sky to the ground
Creatures.METEOR_REACH = 15
Creatures.METEOR_THROW = 75

local function tornadoModel(): Model
	local m = Instance.new("Model")
	m.Name = "Tornado"
	-- A funnel of faint thin rings (narrow at the ground, wide at the top) wrapped in swirling dust:
	-- the dust makes the shape; the rings only hint at it. (PC look 19 Nov: thick grey disks read
	-- as code-built.)
	local root: BasePart? = nil
	for i = 0, 15 do
		local w = 4 + i * 2.4
		local ring = block(m, "Funnel", Vector3.new(1.2, w, w), CFrame.new(0, 1.5 + i * 2.8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(130, 124, 116), Enum.PartType.Cylinder)
		ring.Material = Enum.Material.SmoothPlastic
		ring.Transparency = 0.78 + i * 0.008
		ring.CastShadow = false
		root = root or ring
		if i % 3 == 0 then
			local dust = Instance.new("ParticleEmitter")
			dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
			dust.Color = ColorSequence.new(Color3.fromRGB(150, 140, 125), Color3.fromRGB(100, 94, 86))
			dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2 + i * 0.4), NumberSequenceKeypoint.new(1, 6 + i * 0.8) })
			dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
			dust.Lifetime = NumberRange.new(0.8, 1.4)
			dust.Rate = 26
			dust.Shape = Enum.ParticleEmitterShape.Cylinder
			dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			dust.Speed = NumberRange.new(2, 5)
			dust.RotSpeed = NumberRange.new(-260, 260)
			dust.Rotation = NumberRange.new(0, 360)
			dust.Parent = ring
		end
	end
	m.PrimaryPart = root
	return m
end

-- A tornado wandering the lab around `center` for `seconds`.
function Creatures.tornado(center: Vector3, seconds: number?): () -> ()
	local m = tornadoModel()
	m.Parent = folder()
	local parts: { [BasePart]: CFrame } = {}
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") then
			parts[p] = p.CFrame
		end
	end
	local at = center + Vector3.new(-Creatures.HALF + 10, 0, -30)
	local goal = center
	local t = 0
	local spun: { [Model]: number } = {}
	local scanned = -1
	local bodies: { Body } = {}
	local lifted: { [Player]: number } = {}
	FxService.hit(at, 80, "BigBoom")
	local c = RunService.Heartbeat:Connect(function(dt)
		t += dt
		-- Wander: a new goal in the lab every few seconds.
		if (goal - at).Magnitude < 6 then
			goal = center + Vector3.new(math.random(-Creatures.HALF + 10, Creatures.HALF - 10), 0, math.random(-80, 60))
		end
		local step = goal - at
		at += step.Unit * math.min(step.Magnitude, Creatures.TORNADO_SPEED * dt)
		local spin = CFrame.Angles(0, t * 6, 0)
		for p, cf in parts do
			local wobble = math.sin(t * 3 + cf.Position.Y * 0.2) * 1.5
			p.CFrame = CFrame.new(at + Vector3.new(wobble, 0, 0)) * spin * cf
		end
		if t - scanned > 0.15 then
			scanned = t
			bodies = dummiesIn(center)
		end
		for _, d in bodies do
			if not d.pelvis.Parent then
				continue
			end
			local o = d.pelvis.Position - at
			local flat = Vector3.new(o.X, 0, o.Z)
			if flat.Magnitude < Creatures.TORNADO_REACH and (not spun[d.model] or t - spun[d.model] > 1.2) then
				spun[d.model] = t
				local around = Vector3.new(-flat.Z, 0, flat.X).Unit
				local mass = (d.model:GetAttribute("Mass") :: number?) or 10
				local v = Vector3.new(0, Creatures.TORNADO_LIFT, 0) + around * Creatures.TORNADO_LIFT * 0.5 - flat.Unit * 6
				DummyControl.hit(d.model, d.pelvis, v * mass, d.pelvis.Position)
			end
		end
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and math.abs(root.Position.Y - center.Y) < 30 then
				local o = root.Position - at
				local flat = Vector3.new(o.X, 0, o.Z)
				if flat.Magnitude < Creatures.TORNADO_REACH and (not lifted[player] or t - lifted[player] > 2.5) then
					lifted[player] = t
					PlayerRagdoll.knock(player, Vector3.new(0, Creatures.TORNADO_LIFT, 0) + Vector3.new(-flat.Z, 0, flat.X).Unit * 30)
				end
			end
		end
	end)
	local function stop()
		c:Disconnect()
		if m.Parent then
			m:Destroy()
		end
	end
	if seconds then
		task.delay(seconds, stop)
	end
	return stop
end

-- Meteors falling on the lab around `center`: a glowing rock, a trail, a crater-flash and a blast.
function Creatures.meteors(center: Vector3): () -> ()
	local running = true
	local made: { Instance } = {}
	task.spawn(function()
		while running do
			local target = center + Vector3.new(math.random(-Creatures.HALF + 6, Creatures.HALF - 6), 0, math.random(-85, 65))
			local rock = Instance.new("Part")
			rock.Name = "Meteor"
			rock.Shape = Enum.PartType.Ball
			rock.Size = Vector3.new(4.5, 4.5, 4.5)
			rock.Material = Enum.Material.Neon
			rock.Color = Color3.fromRGB(255, 120, 40)
			rock.Anchored = true
			rock.CanCollide = false
			rock.CanQuery = false
			rock.CanTouch = false
			local fire = Instance.new("Fire")
			fire.Size = 9
			fire.Heat = 12
			fire.Parent = rock
			local from = target + Vector3.new(math.random(-40, 40), 160, math.random(-40, 40))
			rock.Position = from
			rock.Parent = folder()
			table.insert(made, rock)
			task.spawn(function()
				local t0 = os.clock()
				while running and rock.Parent do
					local a = math.min(1, (os.clock() - t0) / Creatures.METEOR_FALL)
					rock.Position = from:Lerp(target + Vector3.new(0, 2, 0), a * a)
					if a >= 1 then
						break
					end
					RunService.Heartbeat:Wait()
				end
				if not running then
					return
				end
				rock:Destroy()
				FxService.hit(target + Vector3.new(0, 1, 0), 140, "BigBoom")
				-- A scorch mark that fades.
				local scorch = Instance.new("Part")
				scorch.Name = "Scorch"
				scorch.Shape = Enum.PartType.Cylinder
				scorch.Size = Vector3.new(0.2, 12, 12)
				scorch.CFrame = CFrame.new(target + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
				scorch.Color = Color3.fromRGB(30, 22, 18)
				scorch.Material = Enum.Material.Slate
				scorch.Anchored = true
				scorch.CanCollide = false
				scorch.CanQuery = false
				scorch.CanTouch = false
				scorch.Parent = folder()
				table.insert(made, scorch)
				task.delay(4, function()
					scorch:Destroy()
				end)
				for _, d in dummiesIn(center) do
					if (d.pelvis.Position - target).Magnitude < Creatures.METEOR_REACH then
						knock(d.model, target, Creatures.METEOR_THROW, 1.4)
					end
				end
				knockPlayers(target, Creatures.METEOR_REACH, Creatures.METEOR_THROW, 1.4, center)
			end)
			task.wait(Creatures.METEOR_GAP)
		end
	end)
	return function()
		running = false
		for _, x in made do
			if x.Parent then
				x:Destroy()
			end
		end
	end
end

return Creatures
