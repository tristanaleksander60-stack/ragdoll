--!strict
-- 3.26 THE WHALE (docs/MACHINES_10.md "3.26 WHALE (Splash Zone big pool)"; Config.WHALE_10): the big pool's whale.
--   * A ragdoll in the pool: after 2-4 s the whale surfaces right under it (a big dark-blue back rises out of the water)
--     and BLOWS: a white water spout column with spray, and the body is launched sky-high, "SPOUT! 48 studs" (+ NEW
--     BEST for the lab's owner: SpoutBest). Then the whale sinks again. At most once every 6 s.
--   * Every 25-40 s, or after a spout, it slaps its tail: the fluke rises at the pool's end and comes down with a splash
--     ring that pushes every ragdoll in or beside the pool away (a wave).
-- The whale is parts (back, head bump, fluke) under the water at rest; nothing runs when no pool is on the map.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WhaleSpout = {}

WhaleSpout.LAUNCH = 120 -- studs/s up
WhaleSpout.GAP = 6
WhaleSpout.SLAP_PUSH = 45

local SPLASH_ID = "rbxassetid://9125742262" -- (PSE wind/whoosh, a spout blast)
local BLUE = Color3.fromRGB(46, 70, 104)

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pop(at: Vector3, text: string, color: Color3)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).WORLD_POPS == false then
		return -- (owner 27 Nov late: "Fjern ALLE de her tekster", also from the machines)
	end
	pcall(function()
		lazy("Playground").pop(at, text, color)
	end)
end

local function blob(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	p.Parent = into
	return p
end

type Whale = { box: BasePart, model: Model, back: Part, fluke: Part, top: number, busy: boolean, lastSpout: number, slapAt: number }
local whales: { Whale } = {}

local function build(box: BasePart): Whale
	local model = Instance.new("Model")
	model.Name = "PoolWhale"
	local top = box.Position.Y + box.Size.Y / 2
	local rest = CFrame.new(box.Position.X, top - 3.2, box.Position.Z)
	local back = blob(model, "WhaleBack", Vector3.new(7, 4, 16), rest, BLUE)
	local belly = blob(model, "WhaleBelly", Vector3.new(6, 2.4, 12), rest * CFrame.new(0, -1.1, 0.5), Color3.fromRGB(214, 220, 228))
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = back, belly
	weld.Parent = belly
	local fluke = Instance.new("Part")
	fluke.Name = "WhaleFluke"
	fluke.Size = Vector3.new(9, 0.6, 3.4)
	fluke.Color = BLUE
	fluke.Material = Enum.Material.SmoothPlastic
	fluke.Anchored, fluke.CanCollide, fluke.CanQuery, fluke.CanTouch, fluke.CastShadow = true, false, false, false, false
	local end_ = box.CFrame * CFrame.new(0, 0, box.Size.Z / 2 - 4)
	fluke.CFrame = CFrame.new(end_.Position.X, top - 2.5, end_.Position.Z)
	fluke.Parent = model
	model.Parent = box.Parent
	return { box = box, model = model, back = back, fluke = fluke, top = top, busy = false, lastSpout = 0, slapAt = os.clock() + math.random(15, 30) }
end

local function inBox(box: BasePart, p: Vector3, margin: number): boolean
	local rel = box.CFrame:PointToObjectSpace(p)
	return math.abs(rel.X) < box.Size.X / 2 + margin and math.abs(rel.Z) < box.Size.Z / 2 + margin and math.abs(rel.Y) < box.Size.Y / 2 + 4
end

local function spray(at: Vector3, count: number, speed: number)
	local holder = Instance.new("Part")
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.CFrame = CFrame.new(at)
	holder.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	e.LightEmission = 0.4
	e.Size = NumberSequence.new(0.7, 0.2)
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = Vector2.new(25, 25)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -Workspace.Gravity * 0.5, 0)
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Rate = 0
	e.Parent = holder
	e:Emit(count)
	local s = Instance.new("Sound")
	s.SoundId = SPLASH_ID
	s.Volume = 1
	s.PlaybackSpeed = 1.4
	s.RollOffMaxDistance = 140
	s.Parent = holder
	s:Play()
	Debris:AddItem(holder, 3)
end

local function spout(w: Whale, m: Model, pe: BasePart)
	w.busy = true
	w.lastSpout = os.clock()
	local under = Vector3.new(pe.Position.X, w.top - 3.2, pe.Position.Z)
	local look = CFrame.lookAt(under, under + Vector3.new(1, 0, 0.4))
	w.back.CFrame = look
	TweenService:Create(w.back, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = look + Vector3.new(0, 2.6, 0) }):Play()
	task.wait(0.6)
	if not (m.Parent and pe.Parent) then
		w.busy = false
		return
	end
	-- the spout: a white column that shoots up and fades, spray, and the body launched
	local col = Instance.new("Part")
	col.Name = "WhaleSpoutColumn"
	col.Shape = Enum.PartType.Cylinder
	col.Material = Enum.Material.Glass
	col.Color = Color3.fromRGB(230, 245, 255)
	col.Transparency = 0.35
	col.Anchored, col.CanCollide, col.CanQuery, col.CanTouch, col.CastShadow = true, false, false, false, false
	col.Size = Vector3.new(2, 1.6, 1.6)
	col.CFrame = CFrame.new(under + Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	col.Parent = Workspace
	TweenService:Create(col, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(26, 2.4, 2.4),
		CFrame = CFrame.new(under + Vector3.new(0, 16, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	}):Play()
	TweenService:Create(col, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.5), { Transparency = 1 }):Play()
	Debris:AddItem(col, 1.8)
	spray(under + Vector3.new(0, 4, 0), 40, 70)
	local y0 = pe.Position.Y
	pcall(function()
		lazy("DummyControl").push(m, Vector3.new(math.random(-8, 8), WhaleSpout.LAUNCH, math.random(-8, 8)), nil)
	end)
	task.spawn(function()
		local peak = y0
		local t0 = os.clock()
		while os.clock() - t0 < 3 and pe.Parent do
			peak = math.max(peak, pe.Position.Y)
			task.wait(0.05)
		end
		local h = math.floor(peak - y0 + 0.5)
		local text = "SPOUT! " .. h .. " studs"
		local okO, owner = pcall(function()
			return lazy("Lab").ownerAt(under)
		end)
		if okO and owner then
			local best = (owner:GetAttribute("SpoutBest") :: number?) or 0
			if h > best then
				owner:SetAttribute("SpoutBest", h)
				text ..= " NEW BEST!"
			end
		end
		pop(under + Vector3.new(0, 8, 0), text, Color3.fromRGB(150, 220, 255))
	end)
	task.wait(1.2)
	TweenService:Create(w.back, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { CFrame = look }):Play()
	task.wait(1.2)
	w.slapAt = math.min(w.slapAt, os.clock() + 2)
	w.busy = false
end

local function slap(w: Whale, dummies: Instance)
	w.busy = true
	local f = w.fluke
	local base = f.CFrame
	TweenService:Create(f, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { CFrame = base * CFrame.new(0, 5.5, 0) * CFrame.Angles(math.rad(-50), 0, 0) }):Play()
	task.wait(0.8)
	TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = base }):Play()
	task.wait(0.22)
	local at = base.Position
	spray(at + Vector3.new(0, 1, 0), 60, 45)
	-- the wave: a ring that pushes every ragdoll in or beside the pool away from the slap
	local ring = Instance.new("Part")
	ring.Name = "WhaleWave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Glass
	ring.Color = Color3.fromRGB(200, 235, 255)
	ring.Transparency = 0.4
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
	ring.Size = Vector3.new(0.4, 4, 4)
	ring.CFrame = CFrame.new(Vector3.new(at.X, w.top + 0.1, at.Z)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.4, 60, 60), Transparency = 1 }):Play()
	Debris:AddItem(ring, 1.2)
	for _, m in dummies:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		if m:IsA("Model") and pe and pe:IsA("BasePart") and inBox(w.box, pe.Position, 6) then
			local away = Vector3.new(pe.Position.X - at.X, 0, pe.Position.Z - at.Z)
			local dir = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
			pcall(function()
				lazy("DummyControl").push(m, dir * WhaleSpout.SLAP_PUSH + Vector3.new(0, 18, 0), nil)
			end)
		end
	end
	pop(at + Vector3.new(0, 6, 0), "TAIL SLAP!", Color3.fromRGB(150, 220, 255))
	w.slapAt = os.clock() + math.random(25, 40)
	w.busy = false
end

function WhaleSpout.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.WHALE_10 then
		return
	end
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		local seen: { [BasePart]: boolean } = {}
		local wetSince: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
		while true do
			task.wait(0.5)
			for _, v in CollectionService:GetTagged("WaterVolume") do
				if v:IsA("BasePart") and v.Name == "PoolWaterVolume" and not seen[v] and v.Parent then
					seen[v] = true
					table.insert(whales, build(v))
				end
			end
			local now = os.clock()
			for _, w in whales do
				if w.busy or not w.box.Parent then
					continue
				end
				local target: Model? = nil
				local targetPe: BasePart? = nil
				for _, m in dummies:GetChildren() do
					local pe = m:FindFirstChild("LowerTorso")
					if m:IsA("Model") and pe and pe:IsA("BasePart") and inBox(w.box, pe.Position, 0) and m:GetAttribute("Held") ~= true then
						wetSince[m] = wetSince[m] or now
						local seed = m:GetAttribute("Seed")
						if now - (wetSince[m] :: number) > 2 + (if type(seed) == "number" then seed % 3 else 1) then
							target, targetPe = m, pe
						end
					else
						wetSince[m] = nil
					end
				end
				if target and targetPe and now - w.lastSpout > WhaleSpout.GAP then
					wetSince[target] = nil
					task.spawn(spout, w, target, targetPe)
				elseif now >= w.slapAt then
					task.spawn(slap, w, dummies)
				end
			end
		end
	end)
end

return WhaleSpout
