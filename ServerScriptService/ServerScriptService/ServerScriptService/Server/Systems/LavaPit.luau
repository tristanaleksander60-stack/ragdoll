--!strict
-- 21 Nov 2026 (the owner: "make the lava much nicer"; Config.LAVA_V2). The lab's lava pit as a
-- real pit instead of a flat orange box with hazard tape:
--   * a rounded pool made of overlapping discs (cracked lava under a glowing layer the clients make
--     breathe: Client/LavaClient), dark crust islands drifting on it;
--   * a rim of dark volcanic rocks, half sunk, uneven, on a scorched ring of ground;
--   * embers rising, heat haze and blobs that pop, a warm light, a bubbling sound;
--   * a warning picture on a post (a flame in a red triangle), no words.
-- The pool part keeps its name and job (LavaPool: the touch that throws you up, LaunchVelocity for
-- dummies, the DummyAvoid tag): Playground keeps wiring it. Pictures never collide.

local CollectionService = game:GetService("CollectionService")

local LavaPit = {}

LavaPit.HOT = Color3.fromRGB(255, 120, 30)
LavaPit.CORE = Color3.fromRGB(255, 70, 20)
LavaPit.CRUST = Color3.fromRGB(46, 30, 26)
LavaPit.ROCK = Color3.fromRGB(44, 38, 36)
LavaPit.SCORCH = Color3.fromRGB(36, 30, 28)
LavaPit.BUBBLE_SOUND = "rbxassetid://9112752570" -- (Pro Sound Effects "Bubbles Dribble Small Bloops 1", slowed: thick lava)
LavaPit.TAG = "LavaGlow"

local function piece(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

local function hash(a: number, b: number): number
	local v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453
	return v - math.floor(v)
end

-- A disc lying flat (a Cylinder turned up), its top at `top`.
local function disc(into: Instance, name: string, at: Vector3, diameter: number, thick: number, top: number, color: Color3, material: Enum.Material): Part
	return piece(into, name, Vector3.new(thick, diameter, diameter), CFrame.new(at.X, top - thick / 2, at.Z) * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

-- Builds the pit's pictures round an existing pool part (its footprint: pool.Size.X by pool.Size.Z,
-- centred on it). `floorY` is the top of the lab floor. Returns the folder.
function LavaPit.dress(pool: BasePart, floorY: number): Folder
	local into = Instance.new("Folder")
	into.Name = "LavaPit"
	local c = pool.Position
	local w, d = pool.Size.X, pool.Size.Z
	local rx, rz = w / 2, d / 2
	-- The pool part stays the trigger; the eye sees the rounded pool instead.
	pool.Transparency = 1
	-- (Its box shrinks to fit inside the oval: a foot on the rim rocks is never "in" the lava.)
	task.defer(function()
		pool.Size = Vector3.new(w * 0.74, pool.Size.Y, d * 0.74)
	end)
	-- Scorched ground a little wider than the pit: one disc (V9-0d review: six overlapping ones had to
	-- stack up past the lava's own beds to keep apart; one never meets itself).
	disc(into, "LavaScorch", Vector3.new(c.X, 0, c.Z), math.max(w, d) * 1.18, 0.06, floorY + 0.04, LavaPit.SCORCH, Enum.Material.Slate)
	-- The lava itself: overlapping discs that fill an oval, Roblox's cracked lava (a dark crust with
	-- glowing cracks), and a few hot spots of molten glow that breathe (LavaClient).
	local spots = {
		Vector3.new(0, 0, 0), Vector3.new(-rx * 0.45, 0, -rz * 0.3), Vector3.new(rx * 0.45, 0, rz * 0.3),
		Vector3.new(-rx * 0.4, 0, rz * 0.4), Vector3.new(rx * 0.4, 0, -rz * 0.4),
	}
	for i, s in spots do
		local diameter = (if i == 1 then math.min(w, d) * 1.0 else math.min(w, d) * 0.72)
		local at = Vector3.new(c.X + s.X, 0, c.Z + s.Z)
		local bed = disc(into, "LavaBed", at, diameter, 0.3, floorY + 0.2 + i * 0.07, -- (V9-0d: 0.07 apart, no flicker)
			 Color3.fromRGB(255, 96, 24), Enum.Material.CrackedLava)
		CollectionService:AddTag(bed, LavaPit.TAG) -- (its glow breathes: LavaClient warms and cools its colour)
	end
	-- Crust islands: dark flat rocks floating on it (LavaClient drifts them a little).
	for i = 1, 3 do
		local a = hash(i, w) * math.pi * 2
		local r = 0.25 + 0.4 * hash(d, i)
		local at = Vector3.new(c.X + math.cos(a) * rx * r, 0, c.Z + math.sin(a) * rz * r)
		local size = 1.2 + hash(i, 3) * 1.2
		local crust = piece(into, "LavaCrust", Vector3.new(size, 0.2, size * (0.6 + hash(i, 9) * 0.5)), CFrame.new(at.X, floorY + 0.2 + #spots * 0.07 + 0.08 - 0.1, at.Z) * CFrame.Angles(0, a, 0), LavaPit.CRUST, Enum.Material.Basalt)
		crust:SetAttribute("Home", crust.CFrame)
		CollectionService:AddTag(crust, "LavaCrust")
	end
	-- The rim: real rocks (V3Assets "Rock", one mesh) round the oval at uneven sizes and turns, half
	-- sunk; plain dark blocks if the place has no rock model.
	local V3Assets = require(script.Parent:WaitForChild("V3Assets")) :: any
	local hasRock = V3Assets.has("Rock")
	local around = math.max(8, math.floor((w + d) / 3.5))
	for i = 0, around - 1 do
		local a = (i + hash(i, 31) * 0.35) / around * math.pi * 2
		local wobble = 0.95 + hash(i, 17) * 0.15
		local at = Vector3.new(c.X + math.cos(a) * (rx + 0.9) * wobble, 0, c.Z + math.sin(a) * (rz + 0.9) * wobble)
		local size = 2.6 + hash(i, 5) * 2.4
		if hasRock then
			local rock = V3Assets.place("Rock", into, CFrame.new(at.X, floorY - size * 0.18, at.Z) * CFrame.Angles(0, hash(i, 2) * math.pi * 2, 0), { size = size, collide = false, name = "LavaRock" })
			if rock then
				for _, p in rock:GetDescendants() do
					if p:IsA("BasePart") then
						p.Color = LavaPit.ROCK:Lerp(LavaPit.SCORCH, hash(i, 13) * 0.7)
						p.CanQuery = false
						p.CanTouch = false
					end
				end
			end
		else
			local rock = piece(into, "LavaRock", Vector3.new(size, size * 0.6, size * 0.9), CFrame.new(at.X, floorY + size * 0.12, at.Z) * CFrame.Angles(0, a, 0), LavaPit.ROCK, Enum.Material.Basalt)
			rock.CastShadow = true
		end
	end
	-- Effects: one invisible plate over the pool carries the emitters, the light and the sound.
	local plate = piece(into, "LavaFx", Vector3.new(w * 0.8, 0.2, d * 0.8), CFrame.new(c.X, floorY + 0.4, c.Z), LavaPit.HOT, Enum.Material.SmoothPlastic)
	plate.Transparency = 1
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 90, 30))
	embers.LightEmission = 1
	embers.LightInfluence = 0
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.05) })
	embers.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	embers.Lifetime = NumberRange.new(1.4, 2.8)
	embers.Speed = NumberRange.new(3, 7)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.Acceleration = Vector3.new(0, 1.5, 0)
	embers.Rate = 10
	embers.EmissionDirection = Enum.NormalId.Top
	embers.Parent = plate
	local haze = Instance.new("ParticleEmitter")
	haze.Name = "Haze"
	haze.Texture = "rbxasset://textures/particles/smoke_main.dds"
	haze.Color = ColorSequence.new(Color3.fromRGB(255, 140, 70), Color3.fromRGB(70, 60, 60))
	haze.LightEmission = 0 -- (vault: smoke never glows)
	haze.LightInfluence = 0
	haze.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
	haze.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
	haze.Lifetime = NumberRange.new(2.5, 4)
	haze.Speed = NumberRange.new(1.5, 3)
	haze.Rate = 2
	haze.EmissionDirection = Enum.NormalId.Top
	haze.Parent = plate
	local blobs = Instance.new("ParticleEmitter")
	blobs.Name = "Blobs"
	blobs.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	blobs.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60))
	blobs.LightEmission = 0.8
	blobs.LightInfluence = 0
	blobs.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.6, 1.4), NumberSequenceKeypoint.new(1, 0) })
	blobs.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	blobs.Lifetime = NumberRange.new(0.5, 0.9)
	blobs.Speed = NumberRange.new(0.5, 1.5)
	blobs.Rate = 4
	blobs.EmissionDirection = Enum.NormalId.Top
	blobs.Parent = plate
	local light = Instance.new("PointLight")
	light.Color = LavaPit.HOT
	light.Range = 24
	light.Brightness = 2.2
	light.Shadows = false
	light.Parent = plate
	CollectionService:AddTag(plate, "LavaLight")
	local sound = Instance.new("Sound")
	sound.Name = "Bubbling"
	sound.SoundId = LavaPit.BUBBLE_SOUND
	sound.Looped = true
	sound.Volume = 0.45
	sound.PlaybackSpeed = 0.55
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = 60
	sound.Parent = plate
	sound:Play()
	if false then -- (24 Nov 2026, owner: "remove all pictograms")
	-- The warning: a post beside the pit with a flame in a red triangle (no words).
	local post = piece(into, "LavaSignPost", Vector3.new(0.4, 5.5, 0.4), CFrame.new(c.X + rx + 2.6, floorY + 2.75, c.Z + rz * 0.4), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
	post.CastShadow = true
	local board = piece(into, "LavaSign", Vector3.new(3.2, 3.2, 0.2), CFrame.new(c.X + rx + 2.6, floorY + 5.9, c.Z + rz * 0.4) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
	board.CastShadow = true
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local s = Instance.new("SurfaceGui")
		s.Face = face
		s.PixelsPerStud = 60
		s.LightInfluence = 0.2
		local pic = Instance.new("ImageLabel")
		pic.BackgroundTransparency = 1
		pic.Size = UDim2.fromScale(1, 1)
		pic.ScaleType = Enum.ScaleType.Fit
		pic.Image = "" -- (set below from DrawnIcons: sign_lava)
		pic.Parent = s
		s.Parent = board
	end
	pcall(function()
		local DrawnIcons = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("DrawnIcons")) :: any
		local id = DrawnIcons.ASSETS.sign_lava
		if id then
			for _, s in board:GetChildren() do
				local pic = s:FindFirstChildWhichIsA("ImageLabel")
				if pic then
					pic.Image = id
				end
			end
		end
	end)
	end
	into.Parent = pool.Parent
	return into
end

return LavaPit
