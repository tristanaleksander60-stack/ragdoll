--!strict
-- V9-0m / Phase S (owner, 21 Nov 2026: "add a compressor that squashes ragdolls flat"; Config.COMPRESSOR):
-- a hydraulic press in every lab, with its own terminal (LabGuide.addTerminal: PRESS, spam queued up to
-- QUEUE, one press every COOLDOWN s; the lab's player or a party guest, within reach).
-- One press: the nearest free dummy is sent in an arc onto the plate; the PRESS lamp blinks, and the
-- plate slams down (the machine's PressAt, server time: every screen animates the plate, the THUD, the
-- dust, the camera punch and a SQUISH! sticker, Client/CompressorClient). Every body on the plate then is
-- knocked flat and marked Flat (server time) for FLAT_TIME s: every screen draws it as a cartoon pancake
-- (a flattened copy of its look; the body's physics never changes, no gore), and when the plate lifts it
-- pops back with a boing and walks off dizzy. A player standing on the plate is squashed the same way.
-- The plate itself is a picture (CanCollide off): nothing is ever stuck under it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any

local Compressor = {}

-- 0.37.15 (owner, 22 Nov 2026: "make the compressor 10x bigger, so it is huge"): built as before, then scaled
-- SCALE times round its footing. At that size it does not fit in the lab: it stands behind it, past the portals and the
-- back edge of the floor (z -113), its open side to the spawn; Landscape keeps the ground flat out to it (BACK_ROOM).
Compressor.SCALE = 3 -- (0.37.16, owner: "10x is FAR too big, it fills the whole map")
Compressor.AT = if Compressor.SCALE > 2 then Vector2.new(0, -136) else Vector2.new(-20, 35) * (Config.LAB_SPREAD or 1) -- lab x, z (on the hub's rim; V9-0n fine-tunes it)
Compressor.PLATE = 8 -- studs across the press bed
Compressor.HEIGHT = 13 -- studs from the bed to the top beam
Compressor.COOLDOWN = 2.5 -- s between two presses
Compressor.QUEUE = 3
Compressor.LAND_WAIT = 1.0 -- s for the tossed dummy to land on the bed
Compressor.SLAM_AFTER = 0.45 -- s from the lamp to the slam (the clients time the plate by it)
Compressor.FLAT_TIME = 3.4 -- s a body stays a pancake (0.37.6: was 2; the plate squeezes on SQUEEZE_TIME s of it)
Compressor.THUD = 9114397505 -- (a heavy metal slam)
Compressor.AGAIN = 8 -- s before the same body may be pressed again (no KO farm)
-- V9-overhaul (Tier 1, lab-overhaul, 21 Jan 2027): the press is an industrial machine that
-- loads pressure between hits, not a dumb tween. While the bed is empty and no press is running,
-- the PressurePSI attribute climbs from 0 to 100 over RECHARGE_TIME seconds. On every press it
-- resets. The plate's slam then applies a radial shove to bodies standing within BOOM_RADIUS of
-- the bed (bystanders only - bodies on the bed get the normal squish), scaled by the PSI at that
-- moment. If the bed stays empty long enough for PSI to top out, the valve releases: an empty
-- press fires anyway (safety-valve), which is funny and keeps the recharge loop from stalling.
Compressor.RECHARGE_TIME = 10 -- s from empty bed to full pressure
Compressor.BOOM_RADIUS = if Compressor.SCALE > 2 then 24 else 14 -- studs around the bed centre that feels the boom
Compressor.BACK_ROOM = if Compressor.SCALE > 2 then -(136 + Compressor.PLATE * Compressor.SCALE / 2 + 30) else nil :: number? -- (lab z the flat ground must reach behind the lab)
Compressor.BOOM_MAX_VELOCITY = 120 -- studs/s outward kick at PSI = 100 (0 at PSI = 0, linear)
Compressor.BOOM_MAX_UP = 55 -- studs/s upward kick at PSI = 100 (adds a little lift so bodies tumble)

local presses = 0
local boomPresses = 0 -- (tests: how many presses actually applied the radial boom)
local valveReleases = 0 -- (tests: how many empty presses the safety valve fired)
local machines: { Model } = {}

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, collide: boolean): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Bodies on the bed now: dummies (pelvis) and players (root) inside its square, near its top.
function Compressor.onBed(machine: Model): { Model }
	local bed = machine:FindFirstChild("Bed")
	if not (bed and bed:IsA("BasePart")) then
		return {}
	end
	local out: { Model } = {}
	local function check(model: Model, p: Instance?)
		-- (22 Nov 2026, owner: a ragdoll carried in with GRAB flew to the top): a body still held is not
		-- on the bed yet; it is pressed once it is let go.
		if model:GetAttribute("Held") == true then
			return
		end
		if p and p:IsA("BasePart") then
			local rel = bed.CFrame:PointToObjectSpace(p.Position)
			local half = bed.Size / 2
			if math.abs(rel.X) < half.X + 0.5 and math.abs(rel.Z) < half.Z + 0.5 and rel.Y > -1 and rel.Y < 7 then
				table.insert(out, model)
			end
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		for _, m in dummies:GetChildren() do
			if m:IsA("Model") then
				check(m, m:FindFirstChild("LowerTorso"))
			end
		end
	end
	for _, plr in Players:GetPlayers() do
		local c = plr.Character
		if c then
			check(c, c:FindFirstChild("HumanoidRootPart"))
		end
	end
	return out
end

-- V9-overhaul: bodies standing near the bed but NOT on it, i.e. the bystanders the boom reaches.
-- Reuses onBed to skip anyone already being squished, so we never double-apply forces.
local function nearBed(machine: Model, radius: number, exclude: { Model }): { { model: Model, part: BasePart } }
	local bed = machine:FindFirstChild("Bed")
	if not (bed and bed:IsA("BasePart")) then
		return {}
	end
	local skip: { [Model]: boolean } = {}
	for _, m in exclude do
		skip[m] = true
	end
	local centre = bed.Position
	local out: { { model: Model, part: BasePart } } = {}
	local function consider(model: Model, p: Instance?)
		if skip[model] or not (p and p:IsA("BasePart")) or model:GetAttribute("Held") == true then
			return
		end
		local d = (p.Position - centre)
		local flat = Vector3.new(d.X, 0, d.Z).Magnitude
		-- Inside the disc horizontally, and within a vertical band around bed height (not above the
		-- top beam, not deep underground): the boom is a ground-level shockwave.
		if flat > 0.5 and flat < radius and math.abs(d.Y) < 8 then
			table.insert(out, { model = model, part = p })
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		for _, m in dummies:GetChildren() do
			if m:IsA("Model") then
				consider(m, m:FindFirstChild("LowerTorso"))
			end
		end
	end
	for _, plr in Players:GetPlayers() do
		local c = plr.Character
		if c then
			consider(c, c:FindFirstChild("HumanoidRootPart"))
		end
	end
	return out
end

-- V9-overhaul: the radial shove on PressAt. Pure physics - no new remotes, no attributes that
-- clients need to know about. Bodies get a horizontal push away from the bed plus a lift, scaled
-- by the pressure built up before this press. Dummies use DummyControl.hit (same path the squish
-- uses); players get an AssemblyLinearVelocity nudge. Everything is best-effort; a missing part
-- is skipped silently.
local function radialBoom(machine: Model, psi: number, onBed: { Model }, owner: Player?)
	if psi <= 1 then
		return
	end
	local scale = math.clamp(psi / 100, 0, 1)
	local pushOut = Compressor.BOOM_MAX_VELOCITY * scale
	local pushUp = Compressor.BOOM_MAX_UP * scale
	local targets = nearBed(machine, Compressor.BOOM_RADIUS, onBed)
	if #targets == 0 then
		return
	end
	local bed = machine:FindFirstChild("Bed") :: BasePart
	local DummyControl = lazy("DummyControl")
	for _, t in targets do
		local d = t.part.Position - bed.Position
		local outward = Vector3.new(d.X, 0, d.Z)
		if outward.Magnitude < 0.1 then
			continue
		end
		outward = outward.Unit
		local kick = outward * pushOut + Vector3.new(0, pushUp, 0)
		-- Falloff: closer to the bed = more kick. Linear from 1.0 at centre to 0.2 at the rim.
		local flat = Vector3.new(d.X, 0, d.Z).Magnitude
		local fall = 1 - 0.8 * math.clamp(flat / Compressor.BOOM_RADIUS, 0, 1)
		kick = kick * fall
		if t.model:GetAttribute("IsDummy") == true then
			local mass = (t.model:GetAttribute("Mass") :: number?) or 6.4
			pcall(DummyControl.hit, t.model, t.part, kick * mass, t.part.Position, 20, owner)
		else
			pcall(function()
				t.part.AssemblyLinearVelocity = t.part.AssemblyLinearVelocity + kick
			end)
		end
		boomPresses += 1
	end
end

-- (22 Nov 2026, owner: "ragdolls go FLAT as pancakes in there"): the body hides on every screen
-- (MachineHidden, DummySkins: its skins and its face) and a flat copy of it lies on the bed.
-- 0.37.6 (owner: "you must still see it is a ragdoll, hear the blood splat, see it squeeze more with blood
-- dripping from the edges before the press opens"): the copy keeps the ragdoll's shape: every limb a flat
-- piece along the way it lay, the head a round flat disc with its face looking up, purple splotches on top.
-- At the touch a wet SPLAT plays, and blood drips off all four edges of the bed while the plate squeezes on.
Compressor.PANCAKE_TIME = 5.5 -- s the pancake lies there (the plate is down FLAT_TIME of it)
Compressor.SQUEEZE_GAP = 0.9 -- studs over its lowest point where the plate first touches
Compressor.SQUEEZE_TIME = 1.3 -- s it then squeezes on down to the bed
Compressor.SPLAT = 9120572784 -- Pro Sound Effects "Watermelon Splat 1" (Roblox-licensed)
local Anatomy = require(Shared:WaitForChild("Anatomy"))
local function bleeds(): boolean
	return Config.BLOOD ~= "off"
end
local function pancake(machine: Model, body: Model)
	local bed = machine:FindFirstChild("Bed")
	if not (bed and bed:IsA("BasePart")) or body:GetAttribute("MachineHidden") == true then
		return
	end
	local top = bed.Position.Y + bed.Size.Y / 2
	local half = bed.Size.X / 2 - 0.4
	local flat = Instance.new("Model")
	flat.Name = "Pancake"
	local function onBed(p: Vector3): Vector3
		local rel = bed.CFrame:PointToObjectSpace(p)
		local w = bed.CFrame:PointToWorldSpace(Vector3.new(math.clamp(rel.X, -half, half), 0, math.clamp(rel.Z, -half, half)))
		return Vector3.new(w.X, top, w.Z)
	end
	local function slab(name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
		local s = Instance.new("Part")
		s.Name = name
		s.Anchored, s.CanCollide, s.CanQuery, s.CanTouch, s.CastShadow = true, false, false, false, false
		if shape then
			s.Shape = shape
		end
		s.Size = size
		s.CFrame = cf
		s.Color = color
		s.Material = Enum.Material.SmoothPlastic
		s.Parent = flat
		return s
	end
	local torso = body:FindFirstChild("UpperTorso")
	for _, p in body:GetChildren() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 1 then
			local at = onBed(p.Position)
			local s = p.Size
			if p.Name == "Head" then
				-- A round flat head, bigger than it was, its face drawn on top and turned away from the chest.
				local d = math.max(s.X, s.Z) * 1.6
				slab("FlatHead", Vector3.new(0.14, d, d), CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), p.Color, Enum.PartType.Cylinder)
				local away = if torso and torso:IsA("BasePart") then (at - onBed(torso.Position)) else Vector3.zAxis
				away = Vector3.new(away.X, 0, away.Z)
				if away.Magnitude < 0.05 then
					away = Vector3.zAxis
				end
				local holder = slab("FlatFace", Vector3.new(d * 0.8, 0.05, d * 0.8), CFrame.lookAt(at + Vector3.new(0, 0.19, 0), at + Vector3.new(0, 0.19, 0) - away.Unit), p.Color)
				holder.Transparency = 1
				local face = p:FindFirstChild("Face")
				if face and face:IsA("SurfaceGui") then
					local copy = face:Clone()
					copy.Face = Enum.NormalId.Top
					copy.Enabled = true
					copy.Parent = holder
				end
			else
				-- A limb or the trunk: flat along its long side as it lay, a little wider than it was.
				local long = Vector3.new(p.CFrame.YVector.X, 0, p.CFrame.YVector.Z)
				if long.Magnitude < 0.25 then
					long = Vector3.new(p.CFrame.XVector.X, 0, p.CFrame.XVector.Z)
				end
				if long.Magnitude < 0.05 then
					long = Vector3.xAxis
				end
				local width = math.max(s.X, s.Z) * 1.45
				local length = s.Y * 1.15
				slab("Flat" .. p.Name, Vector3.new(width, 0.12, length), CFrame.lookAt(at + Vector3.new(0, 0.07, 0), at + Vector3.new(0, 0.07, 0) + long.Unit), p.Color)
			end
		end
	end
	if bleeds() then
		-- Purple splotches on the pancake.
		for i = 1, 5 do
			local a = i * 1.26 + math.random()
			local r = math.random() * half * 0.7
			local d = 0.8 + math.random() * 1.3
			slab("Splotch", Vector3.new(0.03, d, d * (0.6 + math.random() * 0.4)), CFrame.new(bed.Position.X + math.cos(a) * r, top + 0.16 + i * 0.004, bed.Position.Z + math.sin(a) * r) * CFrame.Angles(0, a, math.rad(90)), Anatomy.BLOOD, Enum.PartType.Cylinder)
		end
	end
	flat.Parent = machine
	body:SetAttribute("MachineHidden", true)
	task.delay(Compressor.PANCAKE_TIME, function()
		flat:Destroy()
		if body.Parent then
			body:SetAttribute("MachineHidden", nil)
		end
	end)
end

-- The squeeze: a wet splat at the touch, and blood dripping off all four edges of the bed while the plate
-- goes on down, pooling on the floor beside it; all of it gone after the pancake.
local function squeezeFx(machine: Model)
	local bed = machine:FindFirstChild("Bed")
	if not (bed and bed:IsA("BasePart")) then
		return
	end
	local splat = Instance.new("Sound")
	splat.SoundId = "rbxassetid://" .. Compressor.SPLAT
	splat.Volume = 1.2
	splat.PlaybackSpeed = 0.85
	splat.RollOffMaxDistance = 120
	splat.Parent = bed
	splat:Play()
	game:GetService("Debris"):AddItem(splat, 4)
	if not bleeds() then
		return
	end
	local TweenService = game:GetService("TweenService")
	local top = bed.Size.Y / 2
	local floorY = bed.Position.Y - bed.Size.Y / 2 + 0.05
	local fx: { Instance } = {}
	for _, side in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		local edge = Vector3.new(side.X * bed.Size.X / 2, top, side.Z * bed.Size.Z / 2)
		local a = Instance.new("Attachment")
		a.Name = "Drip"
		a.Position = edge
		a.Parent = bed
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(Anatomy.BLOOD)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0.16) })
		e.Transparency = NumberSequence.new(0.05)
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Speed = NumberRange.new(1, 3)
		e.SpreadAngle = Vector2.new(20, 20)
		e.EmissionDirection = Enum.NormalId.Top
		e.Acceleration = Vector3.new(side.X * 4, -45, side.Z * 4)
		e.Rate = 30
		e.LightInfluence = 1
		e.Parent = a
		table.insert(fx, a)
		-- A pool growing on the floor under that edge.
		local pool = Instance.new("Part")
		pool.Name = "PressPool"
		pool.Shape = Enum.PartType.Cylinder
		pool.Anchored, pool.CanCollide, pool.CanQuery, pool.CanTouch, pool.CastShadow = true, false, false, false, false
		pool.Material = Enum.Material.SmoothPlastic
		pool.Color = Anatomy.BLOOD
		pool.Size = Vector3.new(0.04, 0.4, 0.4)
		local w = bed.CFrame:PointToWorldSpace(edge + side * 1.2)
		pool.CFrame = CFrame.new(w.X, floorY, w.Z) * CFrame.Angles(0, 0, math.rad(90))
		pool.Parent = machine
		TweenService:Create(pool, TweenInfo.new(Compressor.SQUEEZE_TIME + 1, Enum.EasingStyle.Quad), { Size = Vector3.new(0.04, 3.4, 3.4) }):Play()
		table.insert(fx, pool)
	end
	task.delay(Compressor.SQUEEZE_TIME + 1.2, function()
		for _, f in fx do
			local e = f:FindFirstChildOfClass("ParticleEmitter")
			if e then
				e.Enabled = false
			end
		end
	end)
	task.delay(Compressor.PANCAKE_TIME, function()
		for _, f in fx do
			if f:IsA("BasePart") then
				local t = TweenService:Create(f, TweenInfo.new(0.8), { Transparency = 1 })
				t.Completed:Once(function()
					f:Destroy()
				end)
				t:Play()
			else
				f:Destroy()
			end
		end
	end)
end

-- One press: a dummy onto the bed, the slam, the pancakes, the lift.
function Compressor.press(machine: Model, presser: Player?, owner: Player?)
	local bed = machine:WaitForChild("Bed") :: BasePart
	local top = bed.Position + Vector3.new(0, bed.Size.Y / 2 + 1.5, 0)
	if presser and owner then
		if #Compressor.onBed(machine) == 0 then
			lazy("LabGuide").toss(presser, owner, top)
			task.wait(Compressor.LAND_WAIT)
		end
	end
	-- V9-overhaul: read the pressure the machine built up before the slam, then drain it. Bodies
	-- on the bed still get the normal squish below; the radial boom runs for bystanders after the
	-- plate lands. PressurePSI is a server-owned attribute that replicates for free to a cosmetic
	-- needle gauge (added in a follow-up). Safety-valve presses with no onBed() targets still get
	-- credit for draining the pressure, same contract.
	local psiAtPress = (machine:GetAttribute("PressurePSI") :: number?) or 0
	machine:SetAttribute("PressurePSI", 0)
	machine:SetAttribute("PressAt", Workspace:GetServerTimeNow())
	task.wait(Compressor.SLAM_AFTER)
	-- (Owner, 21 Nov 2026: the plate itself slams down and lifts again, on every screen.)
	local plate = machine:FindFirstChild("Plate")
	if plate and plate:IsA("BasePart") then
		local TweenService = game:GetService("TweenService")
		local up, down = plate:GetAttribute("UpY"), plate:GetAttribute("DownY")
		if type(up) == "number" and type(down) == "number" then
			local function at(y: number): CFrame
				return plate.CFrame - Vector3.new(0, plate.Position.Y - y, 0)
			end
			-- (22 Nov 2026, owner: "the press must hang together with the thing that presses"): the ram
			-- stretches from the top beam down to the plate all the way, so plate and machine stay one.
			local ram = machine:FindFirstChild("Ram")
			local beam = machine:FindFirstChild("TopBeam")
			local function ramFor(y: number): { [string]: any }?
				if not (ram and ram:IsA("BasePart") and beam and beam:IsA("BasePart")) then
					return nil
				end
				local top = beam.Position.Y - beam.Size.Y / 2
				local bottom = y + plate.Size.Y / 2
				local len = math.max(0.5, top - bottom)
				return { Size = Vector3.new(ram.Size.X, len, ram.Size.Z), CFrame = ram.CFrame - Vector3.new(0, ram.Position.Y - (bottom + len / 2), 0) }
			end
			-- (0.37.6: a slam to the touch, then a slow squeeze on down to the bed.)
			local touch = down + Compressor.SQUEEZE_GAP
			local downInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(plate, downInfo, { CFrame = at(touch) }):Play()
			local ramTouch = ramFor(touch)
			if ramTouch then
				TweenService:Create(ram :: BasePart, downInfo, ramTouch):Play()
			end
			task.delay(0.12, function()
				local squeezeInfo = TweenInfo.new(Compressor.SQUEEZE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				TweenService:Create(plate, squeezeInfo, { CFrame = at(down) }):Play()
				local ramDown = ramFor(down)
				if ramDown then
					TweenService:Create(ram :: BasePart, squeezeInfo, ramDown):Play()
				end
			end)
			task.delay(Compressor.FLAT_TIME, function()
				if plate.Parent then
					local upInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine)
					TweenService:Create(plate, upInfo, { CFrame = at(up) }):Play()
					local ramUp = ramFor(up)
					if ramUp then
						TweenService:Create(ram :: BasePart, upInfo, ramUp):Play()
					end
				end
			end)
			-- (session v850, owner: "compressoren GRISKRIG, gør den helt lydløs"): the press's metal-slam
			-- played every COOLDOWN s (2.5 s) at full volume; dropped altogether. Other feedback (the plate
			-- tween, the shockwave, the body's own land sound) keeps the press readable.
		end
	end
	local flatUntil = Workspace:GetServerTimeNow() + Compressor.FLAT_TIME
	local DummyControl = lazy("DummyControl")
	local onBedNow = Compressor.onBed(machine)
	-- V9-overhaul: shockwave to the bystanders right as the plate lands (bodies on the bed are
	-- excluded so the squish stays authoritative over the kick).
	radialBoom(machine, psiAtPress, onBedNow, owner)
	if #onBedNow > 0 then
		task.delay(0.12, squeezeFx, machine) -- (0.37.6: the splat and the drips as the plate touches)
	end
	for _, m in onBedNow do
		m:SetAttribute("Flat", flatUntil)
		m:SetAttribute("PressedAt", Workspace:GetServerTimeNow()) -- (a body left on the bed is not pressed again for AGAIN s)
		if m:GetAttribute("IsDummy") == true then
			local pelvis = m:FindFirstChild("LowerTorso")
			if pelvis and pelvis:IsA("BasePart") then
				-- (Knocked flat on the bed: down and out cold a moment, never hurt.)
				local mass = (m:GetAttribute("Mass") :: number?) or 6.4
				pcall(DummyControl.hit, m, pelvis, Vector3.new(0, -40, 0) * mass, pelvis.Position, 40, owner)
			end
			task.delay(0.12, pancake, machine, m) -- (as the plate lands: flat as a pancake)
		end
		task.delay(Compressor.FLAT_TIME, function()
			if m.Parent and m:GetAttribute("Flat") == flatUntil then
				m:SetAttribute("Flat", nil)
			end
		end)
	end
	presses += 1
	local tally = (machine:GetAttribute("Pancakes") :: number?) or 0
	machine:SetAttribute("Pancakes", tally + 1)
	local screen = machine:FindFirstChild("PressScreen", true)
	if screen then
		screen:SetAttribute("Tally", "PANCAKE \u{00D7}" .. (tally + 1))
	end
end

-- The press in one lab (Playground builds the lab): the bed, four steel pillars with pistons, the top
-- beam, the press plate (a picture: the clients move it), the PRESS lamp, warning stripes, and the
-- terminal on the side you come from.
function Compressor.build(folder: Instance, origin: Vector3, at: Vector3?)
	if not Config.COMPRESSOR then
		return
	end
	local m = Instance.new("Model")
	m.Name = "Compressor"
	local base = at or (origin + Vector3.new(Compressor.AT.X, 0, Compressor.AT.Y))
	local face = CFrame.lookAt(base, Vector3.new(origin.X, base.Y, origin.Z)) -- (its open side to the spawn)
	local steel = Color3.fromRGB(70, 76, 88)
	local dark = Color3.fromRGB(38, 42, 52)
	local yellow = Color3.fromRGB(255, 196, 40)
	local S = Compressor.PLATE
	part(m, "Footing", Vector3.new(S + 3, 0.6, S + 3), face * CFrame.new(0, 0.3, 0), dark, Enum.Material.DiamondPlate, true)
	local bed = part(m, "Bed", Vector3.new(S, 1, S), face * CFrame.new(0, 1.1, 0), Color3.fromRGB(110, 116, 128), Enum.Material.Metal, true)
	-- Warning stripes round the bed (yellow and black blocks).
	for i = -3, 3 do
		local c = if i % 2 == 0 then yellow else Color3.fromRGB(20, 20, 24)
		part(m, "Stripe", Vector3.new(S / 7, 0.12, 0.5), face * CFrame.new(i * S / 7, 1.66, -S / 2 - 0.1), c, Enum.Material.SmoothPlastic, false)
		part(m, "Stripe", Vector3.new(S / 7, 0.12, 0.5), face * CFrame.new(i * S / 7, 1.66, S / 2 + 0.1), c, Enum.Material.SmoothPlastic, false)
	end
	-- Four pillars with piston sleeves, and the top beam.
	local H = Compressor.HEIGHT
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * (S / 2 + 0.9), sz * (S / 2 + 0.9)
			-- (0.37.17, owner: "the four posts must hang together with the rest of the machine": they stood on air, a stud
			-- over the footing; now from the footing's top all the way up into the top beam, on a foot plate, with a brace.)
			part(m, "Pillar", Vector3.new(1.2, H + 2, 1.2), face * CFrame.new(x, 0.6 + (H + 2) / 2, z), steel, Enum.Material.Metal, true)
			part(m, "PillarFoot", Vector3.new(2.2, 0.4, 2.2), face * CFrame.new(x, 0.8, z), dark, Enum.Material.Metal, false)
			if sz < 0 then
				part(m, "PillarBrace", Vector3.new(0.5, 0.5, S + 1.8), face * CFrame.new(x, 1.6 + H * 0.45, 0), steel, Enum.Material.Metal, false)
			end -- (one brace per side, not two on top of each other)
			part(m, "Sleeve", Vector3.new(1.7, 3, 1.7), face * CFrame.new(x, 1.6 + H - 2.2, z), yellow, Enum.Material.Metal, false)
		end
	end
	local topBeam = 	part(m, "TopBeam", Vector3.new(S + 3.4, 2, S + 3.4), face * CFrame.new(0, 1.6 + H + 1, 0), dark, Enum.Material.Metal, true)
	-- (22 Nov 2026, owner: a ragdoll carried in with GRAB jumped onto the roof): the grab aims by a ray,
	-- and it stopped on the beam. The beam and pillars stay solid but let that ray through to the bed.
	topBeam.CanQuery = false
	topBeam.CanCollide = false -- (22 Nov 2026: a carried ragdoll passes in under or through the roof; the bed stays solid)
	for _, d in m:GetChildren() do
		if d:IsA("BasePart") and (d.Name == "Pillar" or d.Name == "Sleeve" or d.Name == "PillarBrace" or d.Name == "PillarFoot") then
			d.CanQuery = false
			d.CanCollide = false
		end
	end
	-- The main ram and the press plate (up; the clients drop it on PressAt).
	part(m, "Ram", Vector3.new(2.2, 4, 2.2), face * CFrame.new(0, 1.6 + H - 2, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal, false)
	local plate = part(m, "Plate", Vector3.new(S - 0.4, 1.4, S - 0.4), face * CFrame.new(0, 1.6 + H - 4.7, 0), steel, Enum.Material.DiamondPlate, false)
	plate:SetAttribute("UpY", plate.Position.Y)
	plate:SetAttribute("DownY", bed.Position.Y + bed.Size.Y / 2 + 0.75)
	-- The PRESS lamp and sign on the beam.
	local lamp = part(m, "Lamp", Vector3.new(1.2, 1.2, 1.2), face * CFrame.new(S / 2, 1.6 + H + 2.6, -S / 2), Color3.fromRGB(255, 60, 40), Enum.Material.Neon, false)
	lamp.Shape = Enum.PartType.Ball
	local sign = part(m, "Sign", Vector3.new(6, 1.6, 0.2), face * CFrame.new(0, 1.6 + H + 1, -S / 2 - 1.75), dark, Enum.Material.Metal, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	t.TextScaled = true
	t.TextColor3 = yellow
	t.Text = "\u{1F95E} PRESS"
	t.Parent = gui
	gui.Parent = sign
	if Compressor.SCALE ~= 1 then
		m.WorldPivot = face -- (round its footing on the ground)
		m:ScaleTo(Compressor.SCALE)
		plate:SetAttribute("UpY", plate.Position.Y)
		plate:SetAttribute("DownY", bed.Position.Y + bed.Size.Y / 2 + plate.Size.Y / 2 + 0.05)
		S = Compressor.PLATE * Compressor.SCALE
	end
	m:SetAttribute("Compressor", true)
	m.Parent = folder
	table.insert(machines, m)
	-- (Owner, 21 Nov 2026: no computers. A ragdoll thrown onto the bed is pressed by itself, one every COOLDOWN s;
	-- its fall is the lab player's KO.)
	-- V9-overhaul: start the pressure attribute at zero so clients always see a defined value.
	m:SetAttribute("PressurePSI", 0)
	task.spawn(function()
		local last = 0
		while m.Parent do
			task.wait(0.3)
			if os.clock() - last >= Compressor.COOLDOWN then
				local fresh = 0
				for _, body in Compressor.onBed(m) do
					local was = body:GetAttribute("PressedAt")
					if type(was) ~= "number" or Workspace:GetServerTimeNow() - was > Compressor.AGAIN then
						fresh += 1
					end
				end
				if fresh > 0 then
					last = os.clock()
					local ok, err = pcall(Compressor.press, m, nil, lazy("Lab").ownerAt(origin + Vector3.new(0, 1, 0)))
					if not ok then
						warn("[Compressor] " .. tostring(err))
					end
			end
			end
		end
	end)
	-- V9-overhaul: pressure recharge + safety valve. One loop per machine, ticks at 0.2 s. While
	-- no fresh bodies are on the bed, PSI climbs linearly to 100 over RECHARGE_TIME. When it caps
	-- out AND the main auto-press loop has not fired recently, the valve releases: an empty press
	-- fires so the gauge resets and bystanders get a free comedy shove. The press() path drains
	-- PSI itself, so this loop just tops up.
	task.spawn(function()
		local lastValve = 0
		while m.Parent do
			task.wait(0.2)
			local fresh = false
			for _, body in Compressor.onBed(m) do
				local was = body:GetAttribute("PressedAt")
				if type(was) ~= "number" or Workspace:GetServerTimeNow() - was > Compressor.AGAIN then
					fresh = true
					break
				end
			end
			local psi = (m:GetAttribute("PressurePSI") :: number?) or 0
			if fresh then
				-- A fresh body on the bed: the main loop is about to press. Let it do its thing and
				-- let PSI stay where it is; press() itself drains it.
			else
				local step = (100 / Compressor.RECHARGE_TIME) * 0.2
				psi = math.min(100, psi + step)
				m:SetAttribute("PressurePSI", psi)
			end
			-- Safety valve: empty press to drain the gauge, no more often than every 2 × COOLDOWN
			-- so we never fight the main loop.
			if psi >= 100 and os.clock() - lastValve > Compressor.COOLDOWN * 2 then
				lastValve = os.clock()
				valveReleases += 1
				local ok, err = pcall(Compressor.press, m, nil, lazy("Lab").ownerAt(origin + Vector3.new(0, 1, 0)))
				if not ok then
					warn("[Compressor] valve " .. tostring(err))
				end
			end
		end
	end)
	-- Its terminal (the same family as the feed terminals): PRESS, one every COOLDOWN s, QUEUE queued.
	pcall(function()
		if not Config.FEED_TERMINAL then
			return
		end
		local LabGuide = lazy("LabGuide")
		local guideFolder = folder:FindFirstChild("Guide") or folder
		local screen = LabGuide.addTerminal(guideFolder, origin, "Compressor", function(): Vector3
			return bed.Position + Vector3.new(0, 1.5, 0)
		end, { "Press", "Compressor", "" }, {
			action = function(term: any)
				local Lab = lazy("Lab")
				Compressor.press(m, term.presser, Lab.ownerAt(origin + Vector3.new(0, 1, 0)))
			end,
			every = Compressor.COOLDOWN,
			queueMax = Compressor.QUEUE,
			out = S / 2 + 5,
		})
		screen.Name = "PressScreen"
		screen:SetAttribute("Tally", "PANCAKE \u{00D7}0")
		local term = screen.Parent
		if term then
			term.Parent = m -- (it belongs to the press)
		end
	end)
end

-- Tests: how many presses ran, and the machines built.
function Compressor.pressesForTest(): number
	return presses
end
function Compressor.machinesForTest(): { Model }
	return machines
end
-- V9-overhaul tests: how many bystander kicks the boom applied, and how many empty presses the
-- safety valve fired. Both monotonic counters since module load.
function Compressor.boomsForTest(): number
	return boomPresses
end
function Compressor.valveReleasesForTest(): number
	return valveReleases
end

return Compressor
