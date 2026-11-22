--!strict
-- World/Feel v2 (Config.FEEL_V2): the extra hit feel on this screen. FxController keeps deciding
-- what happens and calls in here for the v2 layers; nothing here sends anything anywhere.
--
--   shake      a trauma shake: every moment adds trauma from one strength value (FeelTuning), the
--              shake drawn is trauma squared, smooth noise (never random per-frame jitter), its
--              frequency capped for slow phones; recoil per gun on your own shots. Off with the
--              SETTINGS "Camera shake" switch; halved with Motion LESS.
--   particles  stars, sparks and a dust ring from a few pooled ParticleEmitters (Emit bursts; the
--              old spark parts were a part each), never more per burst than the device's cap. Mild:
--              never blood (BloodFx keeps the owner's blood switch).
--   flops      a ragdoll's landing gets a layer by speed: a soft flop, a thud, a slam, and dust.
--   trails     a launched, thrown or knocked-flying body streaks (orange: launched; blue: thrown;
--              white: hit), at most the device's trails at once, gone when it slows down.
--   guns       a muzzle flash at the gun's tip for everyone's shots (a light only within the cap),
--              casings out of the side (brass, red shells; none from a revolver or a break-action),
--              camera recoil per gun on your own (FeelTuning.GUN_FX).
--   combo      ProgressService's Combo: FeelBus "Combo", and at Config.COMBO_SLOWMO the slow-mo
--              beat (the colour drains, the view pulls in, a low whoosh: a camera beat, the
--              physics run on as ever). Motion LESS: the colour only.
--   lamps      WorldLights lights the nearest world lamps within the device's cap.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FeelTuning = require(Shared:WaitForChild("FeelTuning"))
local DeviceTier = require(Shared:WaitForChild("DeviceTier"))
local Assets = require(Shared:WaitForChild("Assets"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent
local FeelBus = require(Client:WaitForChild("FeelBus"))
local Settings = require(Client:WaitForChild("Settings"))
local WorldLights = require(Client:WaitForChild("WorldLights"))

local FeelV2 = {}

FeelV2.ON = Config.FEEL_V2 == true

local function tierHere(): DeviceTier.Tier
	local camera = Workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local plat = FeelTuning.platOf(UserInputService.TouchEnabled, UserInputService.KeyboardEnabled, UserInputService.GamepadEnabled, math.min(view.X, view.Y))
	return DeviceTier.of(plat)
end
local tier: DeviceTier.Tier = tierHere()
FeelV2.tier = tier
FeelV2.caps = FeelTuning.caps(tier)

-- Set by FxController.start: plays a sound bank (its pooled voices, its sound settings).
FeelV2.play = nil :: ((bank: string, position: Vector3, volume: number, pitch: number) -> ())?
-- Degrees FxController adds to the field of view (the slow-mo beat pulls it in).
FeelV2.fovBeat = 0

local rng = Random.new()
local player = Players.LocalPlayer

local function sound(bank: string, position: Vector3, volume: number, pitch: number)
	local fn = FeelV2.play
	if fn then
		fn(bank, position, volume, pitch)
	end
end

local function reducedMotion(): boolean
	return Settings.get().motion == 2 -- (Settings.MOTION[2]: LESS)
end

------------------------------------------------------------------------------------------------
-- The camera: trauma shake and gun recoil (FxController applies cameraStep after the camera moved)

local trauma = 0
local kick = 0
local noiseTime = 0
local fps = 60

function FeelV2.addTrauma(amount: number)
	if amount > 0 then
		trauma = math.min(1, trauma + amount)
	end
end

-- V9-NOW 9: your own shot: up by Config.RECOIL[gun].up, to a random side by .side, a little trauma (.shake);
-- scaled by Settings "Recoil" and halved by Motion LESS. Guns not in Config.RECOIL use GUN_FX kick.
local kickYaw = 0
function FeelV2.kick(toyId: string)
	local scale = Settings.recoil() * (if reducedMotion() then 0.5 else 1)
	if scale <= 0 then
		return
	end
	local own = ((Config :: any).RECOIL or {})[toyId]
	local spec = FeelTuning.GUN_FX[toyId]
	local up = if own then own.up elseif spec then spec.kick else nil
	if not up then
		return
	end
	kick = math.min(FeelTuning.KICK_MAX, kick + up * scale)
	if own then
		kickYaw = math.clamp(kickYaw + (if math.random() < 0.5 then -1 else 1) * own.side * scale, -FeelTuning.KICK_MAX / 2, FeelTuning.KICK_MAX / 2)
		if own.shake > 0 then
			trauma = math.min(1, trauma + own.shake * scale)
		end
	end
end

function FeelV2.cameraStep(dt: number): CFrame
	fps = fps + (1 / math.max(dt, 1 / 240) - fps) * math.min(1, dt * 4)
	trauma = math.max(0, trauma - FeelTuning.TRAUMA_DECAY * dt)
	kick = math.max(0, kick - (FeelTuning.KICK_RETURN + kick * 6) * dt)
	kickYaw -= kickYaw * math.min(1, dt * 10) -- (the side kick eases back smoothly)
	-- (V9-NOW 9: Shake off stops the trauma shake; the recoil has its own setting, Settings "Recoil".)
	if not Settings.shake() then
		trauma = 0
	end
	local shake = FeelTuning.shakeOf(trauma) * (if reducedMotion() then 0.5 else 1)
	if shake < 0.0005 and kick < 0.01 and math.abs(kickYaw) < 0.01 then
		return CFrame.identity
	end
	noiseTime += dt * FeelTuning.shakeHz(fps)
	local deg = FeelTuning.SHAKE_DEG * shake
	local pitch = deg * math.clamp(math.noise(noiseTime, 1.3) * 2, -1, 1)
	local yaw = deg * math.clamp(math.noise(noiseTime, 7.7) * 2, -1, 1)
	local roll = FeelTuning.SHAKE_ROLL_DEG * shake * math.clamp(math.noise(noiseTime, 13.1) * 2, -1, 1)
	return CFrame.Angles(math.rad(pitch + kick), math.rad(yaw + kickYaw), math.rad(roll))
end

------------------------------------------------------------------------------------------------
-- Particles: pooled emitters on attachments in the terrain, moved to a spot and told to Emit

type Pool = { list: { ParticleEmitter }, next: number }
local pools: { [string]: Pool } = {}
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function makeEmitter(kind: string): ParticleEmitter
	local a = Instance.new("Attachment")
	a.Name = "FeelV2" .. kind
	a.Parent = Workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.LockedToPart = false
	e.LightInfluence = 0
	e.SpreadAngle = Vector2.new(180, 180)
	if kind == "Stars" then
		e.Texture = Assets.Star
		e.Color = ColorSequence.new(Color3.fromRGB(255, 236, 120), Color3.fromRGB(255, 255, 220))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		e.Lifetime = NumberRange.new(0.35, 0.55)
		e.Speed = NumberRange.new(9, 16)
		e.Drag = 4
		e.Acceleration = Vector3.new(0, -18, 0)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-260, 260)
		e.LightEmission = 0.5
	elseif kind == "Dust" then
		e.Texture = SMOKE
		e.Color = ColorSequence.new(Color3.fromRGB(196, 190, 178))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3.4) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(0.5, 0.85)
		e.Speed = NumberRange.new(5, 9)
		e.SpreadAngle = Vector2.new(85, 85)
		e.EmissionDirection = Enum.NormalId.Top
		e.Drag = 5
		e.Acceleration = Vector3.new(0, 2, 0)
		e.Rotation = NumberRange.new(0, 360)
		e.LightInfluence = 1 -- (the dark layer: it takes the scene's light)
	else -- Sparks
		e.Texture = SPARKLE
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Lifetime = NumberRange.new(0.16, 0.3)
		e.Speed = NumberRange.new(22, 38)
		e.Drag = 3
		e.Acceleration = Vector3.new(0, -40, 0)
		e.LightEmission = 1
	end
	e.Parent = a
	return e
end

local POOL_SIZE = { Stars = 2, Dust = 2, Sparks = 4 }
local function emit(kind: string, position: Vector3, count: number, colors: { Color3 }?): ()
	count = math.min(count, FeelV2.caps.particles)
	if count <= 0 then
		return
	end
	local pool: Pool? = pools[kind]
	if not pool then
		local made: Pool = { list = {}, next = 1 }
		for _ = 1, POOL_SIZE[kind] or 1 do
			table.insert(made.list, makeEmitter(kind))
		end
		pools[kind] = made
		pool = made
	end
	assert(pool, "no emitter pool")
	-- (Round robin: a burst's colours are not repainted by the next burst while it still flies.)
	local e = pool.list[pool.next]
	pool.next = pool.next % #pool.list + 1
	local a = e.Parent :: Attachment
	a.WorldPosition = position
	if colors and #colors > 0 then
		e.Color = ColorSequence.new(colors[1], colors[math.min(2, #colors)])
	elseif kind == "Sparks" then
		e.Color = ColorSequence.new(Color3.fromRGB(255, 226, 120), Color3.fromRGB(255, 140, 40))
	end
	e:Emit(count)
end

-- The old cartoon sparks, as particles (FxController.sparks calls this with FEEL_V2 on).
function FeelV2.sparks(position: Vector3, count: number, power: number, palette: { Color3 }?)
	local e = pools.Sparks
	if e then
		local speed = math.clamp(10 + 12 * power, 10, 60)
		for _, em in e.list do
			em.Speed = NumberRange.new(speed * 0.7, speed)
		end
	end
	emit("Sparks", position, count, palette)
end

------------------------------------------------------------------------------------------------
-- Moments FxController hands over

-- A blow or a blast lands: trauma by strength and nearness, a burst, a stop for the big ones
-- (returned: FxController holds the camera, within HitFeel's budget). kind: "Hit", "Clang", "Blast".
function FeelV2.impact(position: Vector3, speed: number, near: number, kind: string): number
	local strength = FeelTuning.strength(speed)
	FeelV2.addTrauma(FeelTuning.trauma(strength) * near)
	local n = FeelTuning.burst(strength, FeelV2.caps.particles)
	if kind == "Clang" then
		emit("Stars", position, math.ceil(n * 0.6))
	elseif kind == "Blast" then
		emit("Sparks", position, n)
		emit("Dust", position, math.ceil(n * 0.5))
	elseif strength >= 0.45 then
		emit("Stars", position, math.ceil(n * 0.4))
	end
	if strength >= 0.8 and near > 0 then
		FeelBus.fire("BigHit", { position = position, strength = strength })
	end
	return if near > 0.55 then FeelTuning.stop(strength) else 0
end

-- What lies under a landing (V9-P4): its kind (FeelTuning.surface) and its colour for the dust. Bodies
-- and characters are left out of the ray.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local function surfaceAt(position: Vector3): (string, Color3?)
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	for _, plr in Players:GetPlayers() do
		if plr.Character then
			table.insert(skip, plr.Character)
		end
	end
	groundParams.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(position + Vector3.new(0, 1.5, 0), Vector3.new(0, -7, 0), groundParams)
	-- (Fix round 2: on the hidden ground (the Baseplate, the terrain) a painted floor you see answers for
	-- it, as no ray reaches a painted floor (CanQuery off): the lab's tiled hub floor is concrete, not the
	-- Baseplate's grass. A real thing hit first (a pad, a ramp) answers for itself.)
	if not hit or hit.Instance:IsA("Terrain") or hit.Instance.Name == "Baseplate" then
		for _, f in CollectionService:GetTagged("VisibleFloor") do
			if f:IsA("BasePart") then
				local localAt = f.CFrame:PointToObjectSpace(position)
				local half = f.Size / 2
				if math.abs(localAt.X) <= half.X and math.abs(localAt.Z) <= half.Z and localAt.Y > -2 and localAt.Y < 8 then
					return FeelTuning.surface(f.Material.Name), f.Color
				end
			end
		end
	end
	if not hit then
		return "hard", nil
	end
	local color: Color3? = nil
	if hit.Instance:IsA("Terrain") then
		local ok, c = pcall(function()
			return (hit.Instance :: Terrain):GetMaterialColor(hit.Material)
		end)
		color = if ok then c else nil
	elseif hit.Instance:IsA("BasePart") then
		color = hit.Instance.Color
	end
	return FeelTuning.surface(hit.Material.Name), color
end

-- A body comes down: the flop layer by speed and a dust ring.
local lastFlop = 0
function FeelV2.flop(position: Vector3, speed: number, near: number)
	local f = FeelTuning.flop(speed)
	if not f then
		return
	end
	local now = os.clock()
	if now - lastFlop < 0.06 then
		return -- (a pile landing at once is one flop, not a drum roll)
	end
	lastFlop = now
	-- (V9-P4: what it lands on: a soft thud on grass, a slap on a hard floor, a clang on metal; the dust
	-- takes the ground's colour, and water makes none.)
	local kind, ground = surfaceAt(position)
	local strength = FeelTuning.strength(speed)
	local soft = kind == "soft"
	sound(f.bank, position, f.volume * (if soft then 0.85 else 1), f.pitch * (if soft then 0.9 else 1) * rng:NextNumber(0.94, 1.06))
	if f.layer == "slam" then
		sound("slam", position, 0.35, 1.2)
	elseif f.layer == "hit" then
		sound("hit", position, 0.22, 0.8)
	end
	if kind == "metal" then
		sound("clang", position, 0.12 + 0.25 * strength, rng:NextNumber(0.9, 1.1))
	elseif kind == "hard" and f.layer ~= "hit" then
		sound("hit", position, 0.08 + 0.14 * strength, 1.15)
	end
	if kind ~= "water" then
		local colors = if ground then { ground, ground:Lerp(Color3.new(1, 1, 1), 0.35) } else nil
		emit("Dust", position - Vector3.new(0, 1, 0), math.ceil(FeelTuning.burst(strength, FeelV2.caps.particles) * (if soft then 0.7 else 0.5)), colors)
	end
	FeelV2.addTrauma(FeelTuning.trauma(FeelTuning.strength(speed) * 0.8) * near)
	FeelBus.fire("Land", { position = position, speed = speed })
end

------------------------------------------------------------------------------------------------
-- Speed trails

type TrailEntry = { body: Model, trail: Trail, a0: Attachment, a1: Attachment, born: number, slowSince: number? }
local trails: { [Model]: TrailEntry } = {}
local liveTrails = 0
local noted: { [Model]: { kind: string, at: number } } = {}

local function torsoOf(body: Model): BasePart?
	local t = body:FindFirstChild("UpperTorso") or body:FindFirstChild("Torso") or body:FindFirstChild("HumanoidRootPart")
	return if t and t:IsA("BasePart") then t else nil
end

local function dropTrail(t: TrailEntry)
	trails[t.body] = nil
	liveTrails -= 1
	t.trail.Enabled = false
	task.delay(0.4, function()
		t.trail:Destroy()
		t.a0:Destroy()
		t.a1:Destroy()
	end)
end

local function addTrail(body: Model, kind: string)
	if trails[body] or liveTrails >= FeelV2.caps.trails then
		return
	end
	local torso = torsoOf(body)
	if not torso then
		return
	end
	local color = (FeelTuning.TRAIL_COLORS :: any)[kind] or FeelTuning.TRAIL_COLORS.Fast
	local a0 = Instance.new("Attachment")
	a0.Name = "FeelTrail0"
	a0.Position = Vector3.new(0, 0.7, 0)
	a0.Parent = torso
	local a1 = Instance.new("Attachment")
	a1.Name = "FeelTrail1"
	a1.Position = Vector3.new(0, -0.7, 0)
	a1.Parent = torso
	local trail = Instance.new("Trail")
	trail.Name = "FeelTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.32
	trail.MinLength = 0.05
	trail.FaceCamera = true
	trail.LightEmission = 0.4
	trail.LightInfluence = 0
	trail.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1) })
	trail.Parent = torso
	trails[body] = { body = body, trail = trail, a0 = a0, a1 = a1, born = os.clock(), slowSince = nil }
	liveTrails += 1
end

local bodyParams = OverlapParams.new()
bodyParams.FilterType = Enum.RaycastFilterType.Include

local function bodyNear(position: Vector3, radius: number): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	local list: { Instance } = {}
	if dummies then
		table.insert(list, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	bodyParams.FilterDescendantsInstances = list
	local best: Model? = nil
	local bestD = math.huge
	for _, part in Workspace:GetPartBoundsInRadius(position, radius, bodyParams) do
		local model = part:FindFirstAncestorOfClass("Model")
		while model and model.Parent and model.Parent:IsA("Model") do
			model = model.Parent :: Model
		end
		if model and model:FindFirstChildOfClass("Humanoid") then
			local d = (part.Position - position).Magnitude
			if d < bestD then
				best, bestD = model, d
			end
		end
	end
	return best
end

-- A body near `position` was just launched or thrown: it streaks at once (kind: Launch, Throw, Hit).
function FeelV2.noteLaunch(position: Vector3, kind: string)
	local body = bodyNear(position, 8)
	if not body then
		return
	end
	noted[body] = { kind = kind, at = os.clock() }
	addTrail(body, kind)
	FeelBus.fire("Launch", { position = position, kind = kind })
end

local function watchTrails()
	local camera = Workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local now = os.clock()
	-- Fast bodies near the camera streak.
	local candidates: { Model } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		for _, m in dummies:GetChildren() do
			if m:IsA("Model") then
				table.insert(candidates, m)
			end
		end
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(candidates, p.Character)
		end
	end
	for _, body in candidates do
		if not trails[body] and liveTrails < FeelV2.caps.trails then
			local torso = torsoOf(body)
			if torso and (torso.Position - eye).Magnitude < 200 and torso.AssemblyLinearVelocity.Magnitude > FeelTuning.TRAIL_SPEED then
				local n = noted[body]
				addTrail(body, if n and now - n.at < 2 then n.kind else "Fast")
			end
		end
	end
	-- Slow, gone or too old: the trail goes.
	for body, t in trails do
		local torso = torsoOf(body)
		if not body.Parent or not torso or not body:IsDescendantOf(Workspace) or now - t.born > FeelTuning.TRAIL_MAX_TIME then
			dropTrail(t)
		elseif torso.AssemblyLinearVelocity.Magnitude < FeelTuning.TRAIL_SPEED * 0.5 then
			t.slowSince = t.slowSince or now
			if now - (t.slowSince :: number) > FeelTuning.TRAIL_KEEP then
				dropTrail(t)
			end
		else
			t.slowSince = nil
		end
	end
	for body, n in noted do
		if now - n.at > 3 then
			noted[body] = nil
		end
	end
end

------------------------------------------------------------------------------------------------
-- Guns: muzzle flash and casings

local fxFolder: Folder? = nil
local liveFlashes = 0
type Casing = { part: Part, velocity: Vector3, spin: Vector3, born: number }
local casings: { Casing } = {}

local function folder(): Folder
	local f = fxFolder
	if f and f.Parent then
		return f
	end
	local new = Instance.new("Folder")
	new.Name = "FeelV2Fx"
	new.Parent = Workspace
	fxFolder = new
	return new
end

local function flash(at: CFrame, size: number, color: Color3, own: boolean)
	local f = folder()
	local pieces = {}
	for i = 0, 1 do
		local p = Instance.new("Part")
		p.Name = "MuzzleFlash"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = 0.15
		p.Size = Vector3.new(size * 0.25, size * 0.25, size)
		p.CFrame = at * CFrame.new(0, 0, -size * 0.45) * CFrame.Angles(0, 0, math.rad(45 * i + rng:NextNumber(-20, 20)))
		p.Parent = f
		table.insert(pieces, p)
	end
	local light: PointLight? = nil
	if (own or liveFlashes == 0) and liveFlashes < FeelV2.caps.flashes then
		liveFlashes += 1
		local l = Instance.new("PointLight")
		l.Color = color
		l.Range = 6 + size * 4
		l.Brightness = 3
		l.Shadows = false
		l.Parent = pieces[1]
		light = l
	end
	-- (Two rendered frames, whatever the frame rate: a 1/30 s timer is a strobe at 240 fps.)
	local frames = 0
	local conn: RBXScriptConnection? = nil
	conn = RunService.PreRender:Connect(function()
		frames += 1
		if frames >= 2 then
			if conn then
				conn:Disconnect()
			end
			if light then
				liveFlashes -= 1
			end
			for _, p in pieces do
				p:Destroy()
			end
		end
	end)
end

local function casing(from: BasePart, kind: "brass" | "shell")
	if #casings >= FeelV2.caps.casings then
		local old = table.remove(casings, 1)
		if old then
			old.part:Destroy()
		end
	end
	local p = Instance.new("Part")
	p.Name = "Casing"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Metal
	p.Reflectance = 0.2
	if kind == "shell" then
		p.Color = Color3.fromRGB(200, 40, 40)
		p.Size = Vector3.new(0.22, 0.22, 0.5)
	else
		p.Color = Color3.fromRGB(214, 172, 80)
		p.Size = Vector3.new(0.12, 0.12, 0.3)
	end
	local cf = from.CFrame
	p.CFrame = cf * CFrame.new(0.25, 0.1, 0.4)
	p.Parent = folder()
	local out = cf.RightVector * rng:NextNumber(7, 10) + cf.UpVector * rng:NextNumber(5, 8) + cf.LookVector * rng:NextNumber(-1.5, 0.5)
	table.insert(casings, { part = p, velocity = out, spin = Vector3.new(rng:NextNumber(-20, 20), rng:NextNumber(-20, 20), rng:NextNumber(-20, 20)), born = os.clock() })
end

local function stepCasings(dt: number)
	local now = os.clock()
	local g = Workspace.Gravity * 0.35 -- (studs/s^2: a casing reads better a little floaty)
	for i = #casings, 1, -1 do
		local c = casings[i]
		local age = now - c.born
		if age > 0.9 or not c.part.Parent then
			c.part:Destroy()
			table.remove(casings, i)
		else
			c.velocity -= Vector3.new(0, g * dt, 0)
			c.part.CFrame = (c.part.CFrame + c.velocity * dt) * CFrame.Angles(c.spin.X * dt, c.spin.Y * dt, c.spin.Z * dt)
			if age > 0.6 then
				c.part.Transparency = (age - 0.6) / 0.3
			end
		end
	end
end

-- A gun fired from `from` (its Tip, or the hand) towards `toward`. own: this player's shot.
function FeelV2.muzzle(toyId: string, from: BasePart, toward: Vector3, own: boolean)
	local spec = FeelTuning.GUN_FX[toyId]
	if not spec then
		return
	end
	local camera = Workspace.CurrentCamera
	if camera and (camera.CFrame.Position - from.Position).Magnitude > 160 then
		return -- (too far to see a flash)
	end
	if spec.flash > 0 then
		flash(CFrame.lookAt(from.Position, toward), spec.flash, spec.color or FeelTuning.FLASH_COLOR, own)
	end
	if spec.casing then
		casing(from, spec.casing)
	end
	FeelBus.fire("Shot", { toyId = toyId, own = own })
end

------------------------------------------------------------------------------------------------
-- The combo slow-mo beat

local beatToken = 0
local function slowmoBeat(count: number)
	beatToken += 1
	local token = beatToken
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local cc = camera:FindFirstChild("FeelV2Beat")
	if not cc then
		local new = Instance.new("ColorCorrectionEffect")
		new.Name = "FeelV2Beat"
		new.Parent = camera
		cc = new
	end
	local effect = cc :: ColorCorrectionEffect
	effect.Saturation = -0.55
	effect.Contrast = 0.12
	effect.TintColor = Color3.fromRGB(225, 235, 255)
	local t = FeelTuning.SLOWMO_TIME
	TweenService:Create(effect, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }):Play()
	if not reducedMotion() then
		FeelV2.fovBeat = -8
		task.spawn(function()
			local start = os.clock()
			while beatToken == token and os.clock() - start < t do
				local k = (os.clock() - start) / t
				FeelV2.fovBeat = -8 * (1 - k * k)
				RunService.RenderStepped:Wait()
			end
			if beatToken == token then
				FeelV2.fovBeat = 0
			end
		end)
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		sound("whoosh", root.Position, 0.55, 0.45)
	end
	FeelBus.fire("SlowMo", { count = count })
end

------------------------------------------------------------------------------------------------

local started = false
-- (22 Nov 2026, owner: "the crosshair must follow the recoil"): the kick in screen pixels, up and to
-- the side. The crosshair (Crosshair, TouchShoot) is drawn there and the shot (PokeController,
-- TouchShoot.fire) goes there, so the crosshair climbs with the recoil and eases back with it.
function FeelV2.recoilPixelOffset(camera: Camera): Vector2
	if kick < 0.01 and math.abs(kickYaw) < 0.01 then
		return Vector2.zero
	end
	local focal = (camera.ViewportSize.Y / 2) / math.tan(math.rad(camera.FieldOfView / 2))
	return Vector2.new(-math.tan(math.rad(kickYaw)) * focal, -math.tan(math.rad(kick)) * focal)
end

function FeelV2.start()
	if started then
		return
	end
	started = true
	if Config.WORLD_V2 then
		WorldLights.start(FeelV2.caps.lights) -- (the world's lamps: WORLD_V2 builds them)
	end
	if not FeelV2.ON then
		return
	end
	RunService.Heartbeat:Connect(stepCasings)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local result = table.pack(pcall(watchTrails))
			if not result[1] then
				warn("[FeelV2] trails: " .. tostring(result[2]))
				task.wait(2)
			end
		end
	end)
	-- Your own shots kick the camera (third person and first: the viewmodel kicks itself too).
	local ammo = require(Client:WaitForChild("AmmoClient")) :: any
	if type(ammo.onSpent) == "table" then
		table.insert(ammo.onSpent, function(toyId: string)
			FeelV2.kick(toyId)
		end)
	end
	Net.event(Net.Names.Progress).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind ~= "Combo" or type(data) ~= "table" then
			return
		end
		local count = (data :: any).count
		if type(count) ~= "number" then
			return
		end
		local at = (data :: any).at
		FeelBus.fire("Combo", { count = count, at = if typeof(at) == "Vector3" then at else nil })
		if FeelTuning.slowmoAt(count) then
			slowmoBeat(count)
		end
	end)
end

return FeelV2
