--!strict
-- IMPACT_FX 1 (owner, 26 Nov 2026; docs/IMPACT_FX.md, Config.IMPACT_FX): a body hitting the ground throws up what that
-- ground is made of, scaled by speed:
--   18-35 studs/s  a small puff
--   35-70          a dust cloud and bits
--   70+            a big burst, more bits and a ground shock ring
-- Grass/earth: brown-grey dust rolling out low; concrete/stone: light grey dust and stone chips; wood: splinters;
-- metal: sparks; brick: red-brown dust; water: a white splash; sand: a sand spray. Client only, pooled emitters (one
-- per surface, moved to the spot and emitted), at most MAX_PER_SECOND bursts, only within REACH studs of the camera,
-- half the particles on a phone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local ImpactDust = {}

ImpactDust.MIN_SPEED = 18
ImpactDust.REACH = 90
ImpactDust.MAX_PER_SECOND = 6

local PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

type Look = { dust: { Color3 }, bits: { Color3 }?, bitSize: number?, glow: boolean? }
local LOOKS: { [string]: Look } = {
	grass = { dust = { Color3.fromRGB(132, 118, 96), Color3.fromRGB(150, 140, 120) }, bits = { Color3.fromRGB(96, 140, 64), Color3.fromRGB(110, 86, 60) }, bitSize = 0.25 },
	concrete = { dust = { Color3.fromRGB(205, 203, 198), Color3.fromRGB(180, 178, 172) }, bits = { Color3.fromRGB(150, 148, 142), Color3.fromRGB(120, 118, 112) }, bitSize = 0.22 },
	wood = { dust = { Color3.fromRGB(200, 180, 150) }, bits = { Color3.fromRGB(150, 110, 70), Color3.fromRGB(120, 86, 56) }, bitSize = 0.3 },
	metal = { dust = { Color3.fromRGB(190, 190, 195) }, bits = { Color3.fromRGB(255, 210, 120), Color3.fromRGB(255, 170, 60) }, bitSize = 0.18, glow = true },
	brick = { dust = { Color3.fromRGB(170, 100, 80), Color3.fromRGB(150, 90, 72) }, bits = { Color3.fromRGB(140, 70, 54) }, bitSize = 0.24 },
	water = { dust = { Color3.fromRGB(235, 245, 255), Color3.fromRGB(190, 220, 245) } },
	sand = { dust = { Color3.fromRGB(226, 204, 150), Color3.fromRGB(205, 182, 128) }, bits = { Color3.fromRGB(214, 190, 136) }, bitSize = 0.18 },
}

local GRASS = { [Enum.Material.Grass] = true, [Enum.Material.Ground] = true, [Enum.Material.Mud] = true, [Enum.Material.LeafyGrass] = true }
local STONE = { [Enum.Material.Concrete] = true, [Enum.Material.Slate] = true, [Enum.Material.Rock] = true, [Enum.Material.Cobblestone] = true, [Enum.Material.Pavement] = true, [Enum.Material.Asphalt] = true, [Enum.Material.Basalt] = true, [Enum.Material.Granite] = true, [Enum.Material.Marble] = true, [Enum.Material.Pebble] = true, [Enum.Material.SmoothPlastic] = true, [Enum.Material.Plastic] = true, [Enum.Material.Limestone] = true }
local WOOD = { [Enum.Material.Wood] = true, [Enum.Material.WoodPlanks] = true }
local METAL = { [Enum.Material.Metal] = true, [Enum.Material.DiamondPlate] = true, [Enum.Material.CorrodedMetal] = true, [Enum.Material.Foil] = true }

-- What the ground under a point is: a surface name, the point on it and its normal.
local function surfaceAt(at: Vector3): (string?, Vector3, Vector3)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	params.FilterDescendantsInstances = skip
	params.IgnoreWater = false
	local hit = Workspace:Raycast(at + Vector3.new(0, 3, 0), Vector3.new(0, -9, 0), params)
	if not hit then
		return nil, at, Vector3.yAxis
	end
	local m = hit.Material
	local kind = if m == Enum.Material.Water then "water"
		elseif m == Enum.Material.Sand then "sand"
		elseif m == Enum.Material.Brick then "brick"
		elseif GRASS[m] then "grass"
		elseif WOOD[m] then "wood"
		elseif METAL[m] then "metal"
		elseif STONE[m] then "concrete"
		else "concrete"
	return kind, hit.Position, hit.Normal
end

-- The pooled emitters: one dust and one bits emitter per surface, on one hidden part each.
local holder: Folder? = nil
local pool: { [string]: { part: Part, dust: ParticleEmitter, bits: ParticleEmitter? } } = {}
local function emitterFor(kind: string)
	local have = pool[kind]
	if have then
		return have
	end
	local h = holder
	if not h then
		local made = Instance.new("Folder")
		made.Name = "ImpactDust"
		made.Parent = Workspace
		holder = made
		h = made
	end
	local look = LOOKS[kind]
	local p = Instance.new("Part")
	p.Name = "Dust_" .. kind
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(2, 0.2, 2)
	p.Parent = h
	local function seq(colors: { Color3 }): ColorSequence
		if #colors == 1 then
			return ColorSequence.new(colors[1])
		end
		local keys = {}
		for i, c in colors do
			table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
		end
		return ColorSequence.new(keys)
	end
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = seq(look.dust)
	dust.Rate = 0
	dust.Lifetime = NumberRange.new(1.2, 2.6)
	dust.Speed = NumberRange.new(3, 9)
	dust.SpreadAngle = Vector2.new(80, 80)
	dust.Acceleration = Vector3.new(0, if kind == "water" then -30 else 1.5, 0)
	dust.Drag = 3
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 4) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	dust.RotSpeed = NumberRange.new(-40, 40)
	dust.Rotation = NumberRange.new(0, 360)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Parent = p
	local bits: ParticleEmitter? = nil
	if look.bits then
		local b = Instance.new("ParticleEmitter")
		b.Name = "Bits"
		b.Color = seq(look.bits)
		b.Rate = 0
		b.Lifetime = NumberRange.new(0.5, 1.1)
		b.Speed = NumberRange.new(10, 22)
		b.SpreadAngle = Vector2.new(60, 60)
		b.Acceleration = Vector3.new(0, -60, 0)
		b.Size = NumberSequence.new(look.bitSize or 0.2)
		b.LightEmission = if look.glow then 1 else 0
		b.EmissionDirection = Enum.NormalId.Top
		b.Parent = p
		bits = b
	end
	local entry = { part = p, dust = dust, bits = bits }
	pool[kind] = entry
	return entry
end

-- The ground shock ring of a big impact: a flat ring of dust growing and fading.
local function shockRing(at: Vector3, normal: Vector3, color: Color3)
	local ring = Instance.new("Part")
	ring.Name = "ImpactRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = color
	ring.Transparency = 0.45
	ring.Size = Vector3.new(0.1, 2, 2)
	local flat = CFrame.lookAt(at + normal * 0.08, at + normal * 2) * CFrame.Angles(0, math.rad(90), 0)
	ring.CFrame = flat
	ring.Parent = holder or Workspace
	local t = TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.1, 16, 16), Transparency = 1 })
	t:Play()
	t.Completed:Once(function()
		ring:Destroy()
	end)
end

local window = 0
local count = 0
function ImpactDust.burst(at: Vector3, speed: number)
	if not Config.IMPACT_FX or speed < ImpactDust.MIN_SPEED then
		return
	end
	local camera = Workspace.CurrentCamera
	if camera and (camera.CFrame.Position - at).Magnitude > ImpactDust.REACH then
		return
	end
	local now = os.clock()
	if now - window >= 1 then
		window, count = now, 0
	end
	if count >= ImpactDust.MAX_PER_SECOND then
		return
	end
	count += 1
	local kind, point, normal = surfaceAt(at)
	if not kind then
		return
	end
	local e = emitterFor(kind)
	e.part.CFrame = CFrame.lookAt(point, point + normal) * CFrame.Angles(math.rad(-90), 0, 0)
	local tier = if speed >= 70 then 3 elseif speed >= 35 then 2 else 1
	local half = if PHONE then 0.5 else 1
	e.dust.Speed = NumberRange.new(2 + tier * 2, 5 + tier * 4)
	e.dust:Emit(math.max(2, math.floor(({ 6, 16, 32 })[tier] * half)))
	local b = e.bits
	if b and tier >= 2 then
		b:Emit(math.max(2, math.floor(({ 0, 8, 18 })[tier] * half)))
	end
	if tier == 3 then
		shockRing(point, normal, LOOKS[kind].dust[1])
	end
end

return ImpactDust
