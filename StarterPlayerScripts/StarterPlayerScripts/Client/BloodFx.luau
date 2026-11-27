--!strict
-- Cartoon blood, purple (round 2, N2: the owner's choice, as Ragdoll Engine; a colour no real blood
-- has, so Roblox counts it as unrealistic blood): flat drops that fly out of a hit and fall, and
-- comic splats that pop up on the floor and stay a while (the newest ones; the oldest go first when
-- there are too many). A body that is bleeding (its Bleeding attribute, VitalsService) drips as it
-- lies or walks. Built from plain shapes (no textures), so it costs little on phones and reads as a
-- cartoon: no liquid shading, nothing on the bodies (vault: "Gore Policy and Kid-Friendly Hit
-- Feedback").
--
-- Client only, purely visual. One Heartbeat connection while drops are in the air; every part is
-- anchored, never collides, queries or touches, and casts no shadow; a cap on live parts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HitFxConfig = require(Shared:WaitForChild("HitFxConfig"))

local BloodFx = {}

local Anatomy = require(Shared:WaitForChild("Anatomy"))

local RED = Anatomy.BLOOD -- (the name stays: it is the blood's colour, now purple)
local LIGHT = Color3.fromRGB(196, 130, 255) -- highlight drops
local INK = Anatomy.BLOOD_DARK -- the thin dark edge under the blobs (cartoon outline)
local GRAVITY = 80 -- studs/s², snappier than the world: cartoon arcs
-- (V9-NOW 6: capped by device: a phone keeps far fewer.)
local UserInputService = game:GetService("UserInputService")
local MAX_PARTS = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then 110 else 260 -- live blood parts on this screen (splats past it push the oldest out)
local MAX_BURSTS = 6 -- per BURST_WINDOW
local BURST_WINDOW = 0.25
local SPLAT_HOLD = 4 -- s a splat stays before it fades (V9-NOW 6: little marks that go after a few seconds; was 10)
local DRIP_EVERY = 0.45 -- s between two drips from a bleeding body
local DRIP_RANGE = 90 -- studs from the camera: further off, nobody sees the drips
local SPLAT_FADE = 0.7

type Drop = {
	part: Part,
	mesh: SpecialMesh,
	velocity: Vector3,
	life: number,
	age: number,
	size: number,
	groundY: number,
	normal: Vector3,
	splats: boolean,
	probed: boolean, -- looked for its own landing spot (once it starts to fall)
}

local folder: Folder? = nil
local rng = Random.new()
local live = 0 -- blood parts on this screen that still count (a splat on its way out no longer does)
local counted: { [Part]: boolean } = {}
local drops: { Drop } = {}
local stepping: RBXScriptConnection? = nil
local bursts = { start = 0, count = 0 }
-- How far over a surface blood lies: on a floor, above the paint (lab floors and lines are thin
-- parts no ray hits, up to a tenth of a stud over the ground: under them a pool was hidden); on a
-- wall or a ramp, flat on it.
local function FLOOR_LIFT(normal: Vector3): number
	return if normal.Y > 0.9 then 0.12 else 0.02
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function container(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "BloodFx"
	made.Parent = Workspace
	folder = made
	return made
end

-- Floors only: bodies, effects and characters are skipped.
local function refreshFilter()
	local skip: { Instance } = { container() }
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(skip, player.Character)
		end
	end
	rayParams.FilterDescendantsInstances = skip
end


-- The splats on the floor, oldest first: when there are too many, the oldest go early.
type Splat = { parts: { Part }, gone: boolean }
local splatList: { Splat } = {}

local function fadeSplat(s: Splat, quick: boolean?)
	if s.gone then
		return
	end
	s.gone = true
	local index = table.find(splatList, s)
	if index then
		table.remove(splatList, index)
	end
	-- Its parts stop counting now, as they start to go (so making room never pushes out more than
	-- the room a new splat needs).
	for _, p in s.parts do
		if counted[p] then
			counted[p] = nil
			live -= 1
		end
	end
	local shrink = TweenInfo.new(if quick then 0.25 else SPLAT_FADE, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local last = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, (if quick then 0.25 else SPLAT_FADE) - 0.15)
	for _, p in s.parts do
		if p.Parent then
			local t = TweenService:Create(p, shrink, { Size = Vector3.new(0.04, 0.02, 0.02) })
			t:Play()
			TweenService:Create(p, last, { Transparency = 1 }):Play()
			t.Completed:Once(function()
				p:Destroy()
			end)
		end
	end
end

local function newPart(shape: Enum.PartType, size: Vector3, color: Color3, cframe: CFrame): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = cframe
	p.Parent = container()
	live += 1
	counted[p] = true
	p.Destroying:Once(function()
		if counted[p] then
			counted[p] = nil
			live -= 1
		end
	end)
	return p
end

function BloodFx.enabled(): boolean
	local player = Players.LocalPlayer
	return HitFxConfig.effectiveStyle(player and player:GetAttribute("HitFxStyle")) ~= "Stylised"
end

-- One piece of a splat: a flat disc lying on the surface.
type Piece = { offset: Vector2, r: number, color: Color3, ink: boolean }

-- A comic splat lying on the surface at `at` (normal `normal`, default straight up): a big blob, a
-- few smaller ones round it and some dots, each with a thin dark ink edge underneath. Small splats
-- (where a drop lands) are just a blob and a dot. It pops up, holds, then shrinks away in one go,
-- every piece together (so a dark edge never shows on its own).
function BloodFx.splat(at: Vector3, radius: number, normal: Vector3?)
	local small = radius < 0.4
	-- Room for it: the oldest splats make way (a few at most per new one).
	local tries = 0
	while live > MAX_PARTS - (if small then 4 else 18) and splatList[1] and tries < 6 do
		fadeSplat(splatList[1], true)
		tries += 1
	end
	if live > MAX_PARTS - (if small then 4 else 18) then
		return
	end
	local up = if normal and normal.Magnitude > 0.5 then normal.Unit else Vector3.yAxis
	local pieces: { Piece } = { { offset = Vector2.zero, r = radius, color = RED, ink = true } }
	if small then
		local angle = rng:NextNumber(0, math.pi * 2)
		table.insert(pieces, { offset = Vector2.new(math.cos(angle), math.sin(angle)) * radius * 1.1, r = radius * 0.4, color = RED, ink = false })
	else
		local blobs = rng:NextInteger(3, 5)
		for i = 1, blobs do
			local angle = (i / blobs) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
			local d = radius * rng:NextNumber(0.55, 0.95)
			table.insert(pieces, { offset = Vector2.new(math.cos(angle), math.sin(angle)) * d, r = radius * rng:NextNumber(0.35, 0.6), color = RED, ink = true })
		end
		for _ = 1, rng:NextInteger(2, 3) do
			local angle = rng:NextNumber(0, math.pi * 2)
			local d = radius * rng:NextNumber(1.25, 1.8)
			table.insert(pieces, { offset = Vector2.new(math.cos(angle), math.sin(angle)) * d, r = radius * rng:NextNumber(0.14, 0.22), color = RED, ink = false })
		end
		-- One light dab on the big blob: glossy cartoon paint.
		table.insert(pieces, { offset = Vector2.new(-radius * 0.3, -radius * 0.25), r = radius * 0.28, color = LIGHT, ink = false })
	end
	-- Ink edges first (underneath, a little larger), then the blobs on top, each layer a little
	-- higher so they never flicker.
	local layered: { Piece } = {}
	local edge = math.clamp(radius * 0.1, 0.08, 0.16)
	for _, piece in pieces do
		if piece.ink then
			table.insert(layered, { offset = piece.offset, r = piece.r + edge, color = INK, ink = false })
		end
	end
	for _, piece in pieces do
		table.insert(layered, piece)
	end
	-- The surface's own axes: discs lie flat on ramps too.
	local tangent = up:Cross(if math.abs(up.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis).Unit
	local bitangent = up:Cross(tangent)
	local base = FLOOR_LIFT(up) + 0.01 + rng:NextNumber(0, 0.02)
	local parts: { { part: Part, size: Vector3 } } = {}
	for i, piece in layered do
		local diameter = piece.r * 2
		local centre = at + tangent * piece.offset.X + bitangent * piece.offset.Y + up * (base + i * 0.01)
		-- A Cylinder's axis is its X: point it along the surface normal and it lies flat.
		local cf = CFrame.fromMatrix(centre, up, tangent)
		local size = Vector3.new(0.04, diameter, diameter)
		local p = newPart(Enum.PartType.Cylinder, Vector3.new(0.04, diameter * 0.15, diameter * 0.15), piece.color, cf)
		table.insert(parts, { part = p, size = size })
	end
	-- Pop: every piece on the same curve, so the ink never runs ahead of its blob.
	local pop = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	for _, entry in parts do
		TweenService:Create(entry.part, pop, { Size = entry.size }):Play()
	end
	-- Hold, then the whole splat shrinks away at once (staying opaque; it never turns into a dark
	-- stain), the last bit fading.
	local record: Splat = { parts = {}, gone = false }
	for _, entry in parts do
		table.insert(record.parts, entry.part)
	end
	table.insert(splatList, record)
	task.delay((if small then SPLAT_HOLD * 0.6 else SPLAT_HOLD) + rng:NextNumber(0, 0.25), fadeSplat, record)
end

local DRAG = 1.5 -- 1/s: drops slow a little in the air (cartoon arcs, not bullets)

-- A drop that hits the floor without leaving a splat squashes flat and is gone.
local function squash(p: Part)
	local mesh = p:FindFirstChildOfClass("SpecialMesh")
	if mesh then
		local flatten = TweenService:Create(mesh, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = Vector3.new(1.8, 0.15, 1.8),
		})
		flatten:Play()
		flatten.Completed:Once(function()
			local gone = TweenService:Create(mesh, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = Vector3.new(0, 0.1, 0),
			})
			gone:Play()
			gone.Completed:Once(function()
				p:Destroy()
			end)
		end)
	else
		p:Destroy()
	end
end

local function step(dt: number)
	local i = 1
	while i <= #drops do
		local d = drops[i]
		d.life -= dt
		d.age += dt
		d.velocity = Vector3.new(d.velocity.X * (1 - DRAG * dt), d.velocity.Y - GRAVITY * dt, d.velocity.Z * (1 - DRAG * dt))
		local p = d.part
		-- Coming down: find the surface below this very drop (ledges, ramps, platforms).
		if not d.probed and d.velocity.Y < 0 then
			d.probed = true
			local below = Workspace:Raycast(p.Position, Vector3.new(0, -60, 0), rayParams)
			if below then
				d.groundY, d.normal = below.Position.Y, below.Normal
			else
				d.groundY, d.splats = -math.huge, false -- nothing below: it just falls away
			end
		end
		local position = p.Position + d.velocity * dt
		local landed = position.Y <= d.groundY + 0.1
		if landed or d.life <= 0 or not p.Parent then
			if p.Parent then
				if landed and d.splats then
					BloodFx.splat(Vector3.new(position.X, d.groundY, position.Z), math.max(d.size * 0.9, 0.2), d.normal)
					p:Destroy()
				elseif landed then
					-- Lie along the surface: Y is the normal, X any direction across it.
					local across = d.normal:Cross(if math.abs(d.normal.Y) < 0.9 then Vector3.yAxis else Vector3.zAxis).Unit
					p.CFrame = CFrame.fromMatrix(Vector3.new(position.X, d.groundY + d.size * 0.2, position.Z), across, d.normal)
					squash(p)
				else
					p:Destroy() -- still in the air at the end of its life (no floor below)
				end
			end
			drops[i] = drops[#drops]
			drops[#drops] = nil
		else
			-- Stretched along the way it flies (more when fast), popping in over the first frames.
			local speed = d.velocity.Magnitude
			local grow = math.min(d.age / 0.06, 1)
			local mesh = d.mesh
			mesh.Scale = Vector3.new(grow, grow, grow * (1 + math.min(speed / 22, 1.2)))
			p.CFrame = if speed > 0.1 then CFrame.lookAt(position, position + d.velocity) else CFrame.new(position)
			i += 1
		end
	end
	if #drops == 0 and stepping then
		stepping:Disconnect()
		stepping = nil
	end
end

-- Drops fly out of a hit at `position` (most of them upwards and along `direction`, if given) and
-- splat where they land; a big splat appears on the floor under the hit as the first drops come
-- down. power: about 0.3 to 2.5.
function BloodFx.burst(position: Vector3, power: number, direction: Vector3?)
	if not BloodFx.enabled() then
		return
	end
	local now = os.clock()
	if now - bursts.start > BURST_WINDOW then
		bursts.start, bursts.count = now, 0
	end
	bursts.count += 1
	if bursts.count > MAX_BURSTS or live > MAX_PARTS - 30 then
		return
	end
	refreshFilter()
	local hit = Workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -40, 0), rayParams)
	local groundY = if hit then hit.Position.Y else position.Y - 30
	local normal = if hit then hit.Normal else Vector3.yAxis
	local count = math.clamp(math.floor(5 + 7 * power), 4, 20)
	local bias = if direction and direction.Magnitude > 0.01 then direction.Unit else Vector3.zero
	local splatting = 0
	for _ = 1, count do
		local size = rng:NextNumber(0.2, 0.46) * (0.8 + 0.25 * math.min(power, 2))
		local spread = rng:NextUnitVector()
		local dir = (bias * 0.9 + spread * 0.75 + Vector3.new(0, 0.95, 0)).Unit
		local speed = rng:NextNumber(9, 19) * (0.7 + 0.25 * math.min(power, 2.5))
		-- A block part shaped by a sphere mesh: a ball that can stretch along its flight.
		local p = newPart(Enum.PartType.Block, Vector3.one * size, if rng:NextNumber() < 0.2 then LIGHT else RED, CFrame.new(position + spread * 0.3))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.zero
		mesh.Parent = p
		-- Only some drops leave a little splat: enough to read, not a carpet of discs.
		local splats = splatting < 4 and rng:NextNumber() < 0.45
		if splats then
			splatting += 1
		end
		table.insert(drops, {
			part = p,
			mesh = mesh,
			velocity = dir * speed,
			life = 1.4,
			age = 0,
			size = size,
			groundY = groundY,
			normal = normal,
			splats = splats,
			probed = false,
		})
	end
	if not stepping then
		stepping = RunService.Heartbeat:Connect(step)
	end
	if hit and position.Y - groundY < 8 then
		local radius = 0.7 + 0.45 * math.min(power, 2.5)
		-- As the first drops come back down, not before (later from higher up).
		local height = math.max(position.Y - groundY, 0)
		task.delay(0.18 + math.sqrt(2 * height / GRAVITY), BloodFx.splat, hit.Position, radius, normal)
	end
end

-- A round's wound (round 3, M2): no burst and no big splat, a few drops out of the hole (most of
-- them out the far side, along the shot, and down), more for the head. power: the round's wound.
function BloodFx.wound(position: Vector3, power: number, direction: Vector3?, head: boolean?)
	if not BloodFx.enabled() or live > MAX_PARTS - 20 then
		return
	end
	refreshFilter()
	local hit = Workspace:Raycast(position, Vector3.new(0, -40, 0), rayParams)
	local groundY = if hit then hit.Position.Y else position.Y - 30
	local normal = if hit then hit.Normal else Vector3.yAxis
	local count = math.clamp(math.floor((3 + 3 * power) * (if head then 1.6 else 1)), 3, 12)
	local along = if direction and direction.Magnitude > 0.01 then direction.Unit else Vector3.zero
	for i = 1, count do
		local size = rng:NextNumber(0.14, 0.28)
		local dir = (along * 1.1 + rng:NextUnitVector() * 0.45 + Vector3.new(0, 0.25, 0)).Unit
		local speed = rng:NextNumber(5, 11) * (0.8 + 0.2 * math.min(power, 2))
		local p = newPart(Enum.PartType.Block, Vector3.one * size, if rng:NextNumber() < 0.15 then LIGHT else RED, CFrame.new(position + along * 0.2))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.zero
		mesh.Parent = p
		table.insert(drops, {
			part = p,
			mesh = mesh,
			velocity = dir * speed,
			life = 1.4,
			age = 0,
			size = size,
			groundY = groundY,
			normal = normal,
			splats = i <= 3, -- (a few small spots on the floor, never a puddle)
			probed = false,
		})
	end
	if not stepping then
		stepping = RunService.Heartbeat:Connect(step)
	end
end

-- One drop falling from a wound (a bleeding body's drip): it leaves a small splat where it lands.
function BloodFx.drip(position: Vector3)
	if not BloodFx.enabled() or live > MAX_PARTS - 6 then
		return
	end
	refreshFilter()
	local hit = Workspace:Raycast(position, Vector3.new(0, -30, 0), rayParams)
	local size = rng:NextNumber(0.16, 0.26)
	local p = newPart(Enum.PartType.Block, Vector3.one * size, RED, CFrame.new(position))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.zero
	mesh.Parent = p
	table.insert(drops, {
		part = p,
		mesh = mesh,
		velocity = Vector3.new(rng:NextNumber(-1, 1), -2, rng:NextNumber(-1, 1)),
		life = 1.6,
		age = 0,
		size = size,
		groundY = if hit then hit.Position.Y else position.Y - 30,
		normal = if hit then hit.Normal else Vector3.yAxis,
		splats = true,
		probed = false,
	})
	if not stepping then
		stepping = RunService.Heartbeat:Connect(step)
	end
end

-- A pool under a body that lies still and bleeds (round 3, M2): it starts small where the body
-- lies and grows slowly while it bleeds (POOL_GROW), up to POOL_MAX; it never moves with the body
-- (a body dragged away leaves it and starts another) and fades a while after the bleeding stops.
local POOL_GROW = 0.07 -- studs of radius a second
local POOL_START = 0.25
local POOL_MAX = 2.2
local POOL_STAY = 20 -- s a pool stays once its body stopped bleeding (or went)
local MAX_POOLS = 12
type Pool = { ink: Part, blob: Part, radius: number, at: Vector3, normal: Vector3, quietSince: number? }
local pools: { [Model]: Pool } = {}
local oldPools: { Pool } = {}

local BulletHoles: any = nil -- (where a body bleeds from: set by start)
-- (D12 part 3: Config.DRIPS_V2: the newest holes drip, each on its own clock)
local DRIPS_V2 = (require(Shared:WaitForChild("Config")) :: any).DRIPS_V2 == true
local PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local holeNext: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any
function BloodFx.useHoles(module: any)
	BulletHoles = module
end

local function poolCFrame(at: Vector3, normal: Vector3, lift: number): CFrame
	local up = normal.Unit
	local across = up:Cross(if math.abs(up.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis).Unit
	return CFrame.fromMatrix(at + up * lift, up, across)
end

local function sizePool(pool: Pool)
	local d = pool.radius * 2
	pool.ink.Size = Vector3.new(0.04, d + 0.18, d + 0.18)
	pool.blob.Size = Vector3.new(0.04, d, d * 0.86)
end

local function dropPool(pool: Pool)
	for _, part in { pool.ink, pool.blob } do
		if part.Parent then
			local t = TweenService:Create(part, TweenInfo.new(1), { Transparency = 1 })
			t:Play()
			t.Completed:Once(function()
				part:Destroy()
			end)
		end
	end
end

local function retire(model: Model)
	local pool = pools[model]
	if pool then
		pools[model] = nil
		pool.quietSince = pool.quietSince or os.clock()
		table.insert(oldPools, pool)
	end
end

-- One look at a bleeding body: grows its pool when it lies still near the floor.
local function tendPool(model: Model, dt: number, bleeding: boolean)
	local pelvis = model:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") then
		return
	end
	local pool = pools[model]
	if not bleeding then
		if pool and not pool.quietSince then
			pool.quietSince = os.clock()
		end
		return
	end
	if pool then
		pool.quietSince = nil
	end
	-- (Only a body lying down and still pools: one standing or walking drips.)
	local lying = model:GetAttribute("RagdollState") == "Ragdoll" or model:GetAttribute("RagdollState") == "Out"
	local still = pelvis.AssemblyLinearVelocity.Magnitude < 1.5
	if not lying or not still then
		return
	end
	-- (Under the wound it bleeds from, its newest hole; else under the hips.)
	local from = (if BulletHoles then BulletHoles.newestHole(model) else nil) or pelvis.Position
	local below = Workspace:Raycast(from, Vector3.new(0, -4, 0), rayParams)
	if not below then
		return -- (standing, or up in the air: it drips, no pool)
	end
	if pool and (Vector3.new(pool.at.X, 0, pool.at.Z) - Vector3.new(below.Position.X, 0, below.Position.Z)).Magnitude > 3 then
		retire(model) -- (moved: the old pool stays where it was)
		pool = nil
	end
	if not pool then
		local count = 0
		for _ in pools do
			count += 1
		end
		if count + #oldPools >= MAX_POOLS then
			local oldest = table.remove(oldPools, 1)
			if oldest then
				dropPool(oldest)
			else
				return
			end
		end
		local ink = Instance.new("Part")
		ink.Shape = Enum.PartType.Cylinder
		ink.Color = INK
		ink.Material = Enum.Material.SmoothPlastic
		ink.Anchored = true
		ink.CanCollide = false
		ink.CanQuery = false
		ink.CanTouch = false
		ink.CastShadow = false
		ink.CFrame = poolCFrame(below.Position, below.Normal, FLOOR_LIFT(below.Normal))
		local blob = ink:Clone()
		blob.Color = RED
		blob.CFrame = poolCFrame(below.Position, below.Normal, FLOOR_LIFT(below.Normal) + 0.01)
		ink.Parent = container()
		blob.Parent = container()
		pool = { ink = ink, blob = blob, radius = POOL_START, at = below.Position, normal = below.Normal, quietSince = nil }
		pools[model] = pool
	end
	local p = pool :: Pool
	p.radius = math.min(POOL_MAX, p.radius + POOL_GROW * dt)
	sizePool(p)
end

-- Tests: the pool under a body now (its radius), or nil.
function BloodFx.poolOf(model: Model): number?
	local pool = pools[model]
	return if pool then pool.radius else nil
end

-- Drips: every body that is bleeding (and near enough to see) loses a drop now and then, from one
-- of its bullet holes when it has any (else its chest), and grows its pool while it lies still.
local dripWait = 0
RunService.Heartbeat:Connect(function(dt)
	dripWait += dt
	if dripWait < DRIP_EVERY then
		return
	end
	local step_ = dripWait
	dripWait = 0
	local now = os.clock()
	for model, pool in pools do
		if not model.Parent then
			retire(model)
		end
	end
	local i = 1
	while i <= #oldPools do
		local pool = oldPools[i]
		if now - (pool.quietSince or now) >= POOL_STAY then
			table.remove(oldPools, i)
			dropPool(pool)
		else
			i += 1
		end
	end
	for model, pool in pools do
		if pool.quietSince and now - pool.quietSince >= POOL_STAY then
			pools[model] = nil
			dropPool(pool)
		end
	end
	if not BloodFx.enabled() then
		return
	end
	local camera = Workspace.CurrentCamera
	local dummies = Workspace:FindFirstChild("Dummies")
	if not camera or not dummies then
		return
	end
	local eye = camera.CFrame.Position
	for _, model in dummies:GetChildren() do
		local bleeding = model:GetAttribute("Bleeding") == true
		local chest = model:FindFirstChild("UpperTorso")
		if chest and chest:IsA("BasePart") and (chest.Position - eye).Magnitude < DRIP_RANGE then
			-- (A body shot dead no longer bleeds, but its fresh holes still ooze: the pool under the
			-- wound keeps growing slowly a while, up to its cap; no more drips.)
			local oozing = not bleeding and model:GetAttribute("Vital") == "Dead" and BulletHoles ~= nil
				and BulletHoles.newestHole(model) ~= nil
			if bleeding or oozing or pools[model] then
				tendPool(model, step_, bleeding or oozing)
			end
			if DRIPS_V2 and BulletHoles and (not PHONE or (chest.Position - eye).Magnitude < 40) then
				-- D12 part 3 (DAMAGE_12.md 3): only the 2-3 NEWEST holes drip (an older one stops when a newer one starts),
				-- a drop every 0.6-1.2 s from each, for about 8 s, then it stops. Phones: only within 40 studs.
				for _, hole in BulletHoles.dripHoles(model, if PHONE then 2 else 3, 8) do
					local due = holeNext[hole]
					if not due then
						holeNext[hole] = now + rng:NextNumber(0.1, 0.4)
					elseif now >= due then
						holeNext[hole] = now + rng:NextNumber(0.6, 1.2)
						BloodFx.drip(hole.Position - Vector3.new(0, 0.1, 0))
					end
				end
			end
			if not DRIPS_V2 and bleeding and rng:NextNumber() < 0.7 then
				local holes = if BulletHoles then BulletHoles.openHoles(model) else {}
				local from = if #holes > 0 then holes[rng:NextInteger(1, #holes)] else chest.Position + rng:NextUnitVector() * 0.5
				-- (23 Nov 2026, owner: it drips by where it was shot: a little from a limb, a lot from the neck.)
				local flow, neck = 0, false
				for _, w in Anatomy.parseWounds(model:GetAttribute("Wounds")) do
					if w.open and not w.blunt then
						flow += w.zone.bleed
						neck = neck or w.zone.id == "Neck"
					end
				end
				for n = 1, math.clamp(math.floor(flow / 1.6) + (if neck then 3 else 0), 1, 7) do
					local spot = from
					local head = if neck then model:FindFirstChild("Head") else nil
					if head and head:IsA("BasePart") and n % 2 == 0 then
						spot = head.Position - head.CFrame.UpVector * head.Size.Y * 0.5 + head.CFrame.LookVector * 0.35
					elseif #holes > 1 then
						spot = holes[rng:NextInteger(1, #holes)]
					end
					task.delay((n - 1) * 0.06, BloodFx.drip, spot)
				end
			end
		end
	end
end)

-- A big landing (a body slamming into the floor): a splat under it, no drops.
function BloodFx.landing(position: Vector3, speed: number)
	if not BloodFx.enabled() or speed < 40 or live > MAX_PARTS - 18 then
		return
	end
	refreshFilter()
	local hit = Workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -40, 0), rayParams)
	if hit and position.Y - hit.Position.Y < 6 then
		BloodFx.splat(hit.Position, math.clamp(speed / 55, 0.6, 1.8), hit.Normal)
	end
end

return BloodFx
