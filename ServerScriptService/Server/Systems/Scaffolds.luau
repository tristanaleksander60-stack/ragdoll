--!strict
-- Scaffolds (24 Nov 2026, owner: "satisfying wooden scaffolds round about that you can knock over"). Wooden towers in
-- every lab, alone and in a row like dominoes. At rest everything is anchored (no cost). A shot or two, a blast, a car,
-- a thrown ragdoll or a running player tips one: it creaks, leans and goes over as one piece, smashes into loose
-- planks with a crash and dust, and takes the next one in the row with it. A while later the planks fly back, one after
-- the other from the bottom, and it stands again. Knockables tells of shots, blasts and RESET.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Knockables = require(script.Parent:WaitForChild("Knockables")) :: any

local Scaffolds = {}

Scaffolds.LEVELS = 3
Scaffolds.LEVEL_H = 4.4
Scaffolds.WIDE = 5.2 -- along
Scaffolds.DEEP = 3.8 -- across (it falls this way most easily)
Scaffolds.TOUCH_SPEED = 19 -- studs/s: what bumps it must be this fast (a run, not a walk)
Scaffolds.SHOTS = 2 -- rounds that tip it
Scaffolds.SHOT_MEMORY = 4
Scaffolds.TIP = 7 -- studs/s its top gets
Scaffolds.BREAK_TILT = 52 -- degrees it leans when it breaks up
Scaffolds.BREAK_MAX = 3 -- s at most in one piece
Scaffolds.REBUILD_AFTER = 14
Scaffolds.CREAK = { 9120829478, 9114496277, 9114496341 } -- (Pro Sound Effects)
Scaffolds.CRASH = { 9120964951, 9126254743, 9120871246 }
Scaffolds.KNOCKS = { 9126254743, 9120871246 }

type Piece = { part: BasePart, home: CFrame }
type Tower = {
	model: Model,
	pieces: { Piece },
	base: CFrame,
	state: string, -- "Up" | "Tipping" | "Down" | "Rebuild"
	hits: number,
	hitAt: number,
	token: number,
	owner: Vector3,
}
local towers: { Tower } = {}
local rng = Random.new()

local WOODS = { Color3.fromRGB(176, 132, 84), Color3.fromRGB(160, 118, 72), Color3.fromRGB(190, 148, 98), Color3.fromRGB(148, 108, 66) }

local function sound(at: BasePart, ids: { number }, volume: number, speed: number)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. ids[rng:NextInteger(1, #ids)]
	s.Volume = volume
	s.PlaybackSpeed = speed * rng:NextNumber(0.93, 1.07)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = 130
	s.Parent = at
	s:Play()
	Debris:AddItem(s, 6)
end

local function dust(at: Vector3, n: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = Workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(206, 190, 160))
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 5) })
	e.Lifetime = NumberRange.new(0.7, 1.5)
	e.Speed = NumberRange.new(3, 9)
	e.SpreadAngle = Vector2.new(85, 85)
	e.Drag = 2
	e.Rate = 0
	e.Parent = a
	e:Emit(n)
	Debris:AddItem(a, 2.5)
end

local tip: (Tower, Vector3, number) -> ()

local function fastEnough(part: BasePart): boolean
	return not part.Anchored and part.AssemblyLinearVelocity.Magnitude >= Scaffolds.TOUCH_SPEED
end

local function build(folder: Instance, base: CFrame, origin: Vector3): Tower
	local model = Instance.new("Model")
	model.Name = "Scaffold"
	local tower: Tower = { model = model, pieces = {}, base = base, state = "Up", hits = 0, hitAt = 0, token = 0, owner = origin }
	local function plank(size: Vector3, at: CFrame, touch: boolean?)
		local p = Instance.new("Part")
		p.Name = "ScaffoldPlank"
		p.Size = size
		p.CFrame = base * at
		p.Color = WOODS[rng:NextInteger(1, #WOODS)]
		p.Material = Enum.Material.WoodPlanks
		p.Anchored = true
		p.CanTouch = touch == true
		p.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.55, 0.12)
		p.Parent = model
		table.insert(tower.pieces, { part = p, home = p.CFrame })
		if touch then
			p.Touched:Connect(function(other: BasePart)
				if tower.state == "Up" and fastEnough(other) and other.Name ~= "HeadBit" then
					tip(tower, other.AssemblyLinearVelocity, 1.2)
				end
			end)
		end
	end
	local W, D, H = Scaffolds.WIDE, Scaffolds.DEEP, Scaffolds.LEVEL_H
	for level = 0, Scaffolds.LEVELS - 1 do
		local y = level * H
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				plank(Vector3.new(0.42, H, 0.42), CFrame.new(x * (W / 2 - 0.25), y + H / 2, z * (D / 2 - 0.25)), level <= 1)
			end
		end
		-- (The deck, three boards.)
		for k = -1, 1 do
			plank(Vector3.new(W + 0.7, 0.24, D / 3 - 0.06), CFrame.new(rng:NextNumber(-0.15, 0.15), y + H + 0.12, k * D / 3))
		end
		-- (A brace across on each long side, turning over every level; a rail at the ends.)
		local way = if level % 2 == 0 then 1 else -1
		local long = math.sqrt((W - 0.5) ^ 2 + (H - 0.6) ^ 2)
		local lean = math.atan2(H - 0.6, W - 0.5)
		for _, z in { -1, 1 } do
			plank(Vector3.new(long, 0.3, 0.16), CFrame.new(0, y + H / 2, z * (D / 2 + 0.06)) * CFrame.Angles(0, 0, lean * way * z))
		end
		for _, x in { -1, 1 } do
			plank(Vector3.new(0.16, 0.3, D), CFrame.new(x * (W / 2 + 0.06), y + H * 0.45, 0))
		end
	end
	model.Parent = folder
	table.insert(towers, tower)
	model.Destroying:Connect(function()
		tower.state = "Gone"
		local i = table.find(towers, tower)
		if i then
			table.remove(towers, i)
		end
	end)
	return tower
end

local function rebuild(tower: Tower)
	if tower.state ~= "Down" then
		return
	end
	tower.state = "Rebuild"
	tower.token += 1
	local token = tower.token
	for i, piece in tower.pieces do
		local p = piece.part
		for _, w in p:GetChildren() do
			if w:IsA("WeldConstraint") then
				w:Destroy()
			end
		end
		p.Anchored = true
		p.CanCollide = false
		-- (From the bottom up, each with a little overshoot.)
		local wait_ = (i - 1) * 0.045
		task.delay(wait_, function()
			if tower.token ~= token or not p.Parent then
				return
			end
			TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = piece.home }):Play()
			if i % 4 == 0 then
				sound(p, Scaffolds.KNOCKS, 0.35, 1.5)
			end
		end)
	end
	task.delay(#tower.pieces * 0.045 + 0.65, function()
		if tower.token ~= token or not tower.model.Parent then
			return
		end
		for _, piece in tower.pieces do
			piece.part.CFrame = piece.home
			piece.part.CanCollide = true
		end
		tower.hits = 0
		tower.state = "Up"
	end)
end

local function smash(tower: Tower, dir: Vector3)
	if tower.state ~= "Tipping" then
		return
	end
	tower.state = "Down"
	tower.token += 1
	local token = tower.token
	local middle = Vector3.zero
	for _, piece in tower.pieces do
		for _, w in piece.part:GetChildren() do
			if w:IsA("WeldConstraint") then
				w:Destroy()
			end
		end
		middle += piece.part.Position / #tower.pieces
	end
	for _, piece in tower.pieces do
		local p = piece.part
		p.AssemblyLinearVelocity += rng:NextUnitVector() * rng:NextNumber(1, 6) + Vector3.new(0, 2, 0)
		p.AssemblyAngularVelocity += rng:NextUnitVector() * rng:NextNumber(0, 5)
	end
	local first = tower.pieces[1].part
	sound(first, Scaffolds.CRASH, 1, 1)
	sound(first, Scaffolds.CRASH, 0.8, 0.8)
	dust(Vector3.new(middle.X, tower.base.Y + 1, middle.Z), 16)
	dust(Vector3.new(middle.X, tower.base.Y + 1, middle.Z) + dir * 4, 12)
	-- (The next one in the way goes too.)
	for _, other in towers do
		if other ~= tower and other.state == "Up" then
			local gap = other.base.Position - tower.base.Position
			local flat = Vector3.new(gap.X, 0, gap.Z)
			if flat.Magnitude < Scaffolds.LEVELS * Scaffolds.LEVEL_H + 3 and flat.Magnitude > 0.1 and flat.Unit:Dot(dir) > 0.75 then
				task.delay(0.12, function()
					tip(other, dir * 20, 1)
				end)
			end
		end
	end
	task.delay(Scaffolds.REBUILD_AFTER, function()
		if tower.token == token then
			rebuild(tower)
		end
	end)
end

-- Tips a standing tower the way `push` goes.
function tip(tower: Tower, push: Vector3, force: number)
	if tower.state ~= "Up" then
		return
	end
	tower.state = "Tipping"
	tower.token += 1
	local token = tower.token
	local flat = Vector3.new(push.X, 0, push.Z)
	local dir = if flat.Magnitude > 0.1 then flat.Unit else Vector3.xAxis
	local core = tower.pieces[1].part
	for i, piece in tower.pieces do
		if i > 1 then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = core, piece.part
			w.Parent = piece.part
		end
	end
	for _, piece in tower.pieces do
		piece.part.Anchored = false
	end
	pcall(function()
		core:SetNetworkOwner(nil)
	end)
	-- (Round its far foot: the top goes the way it was pushed, the foot hardly at all.)
	local axis = Vector3.yAxis:Cross(dir)
	local spin = Scaffolds.TIP * force / (Scaffolds.LEVELS * Scaffolds.LEVEL_H)
	local height = Scaffolds.LEVELS * Scaffolds.LEVEL_H / 2
	core.AssemblyAngularVelocity = axis * spin * 1.5
	core.AssemblyLinearVelocity = dir * spin * 1.5 * height
	sound(core, Scaffolds.CREAK, 0.9, 1)
	task.spawn(function()
		local t0 = os.clock()
		local up0 = tower.base.UpVector
		while tower.token == token and os.clock() - t0 < Scaffolds.BREAK_MAX do
			task.wait(0.05)
			if not core.Parent then
				return
			end
			local lean = math.deg(math.acos(math.clamp(core.CFrame.UpVector:Dot(up0), -1, 1)))
			if lean > Scaffolds.BREAK_TILT then
				break
			end
			-- (A gentle hand on the way over, so it never stops half leaning.)
			if os.clock() - t0 > 0.5 and core.AssemblyAngularVelocity.Magnitude < 0.5 then
				core.AssemblyAngularVelocity += axis * 0.6
			end
		end
		if tower.token == token then
			smash(tower, dir)
		end
	end)
end

local function contains(tower: Tower, point: Vector3, margin: number): boolean
	local l = tower.base:PointToObjectSpace(point)
	return math.abs(l.X) <= Scaffolds.WIDE / 2 + 0.6 + margin and math.abs(l.Z) <= Scaffolds.DEEP / 2 + 0.6 + margin
		and l.Y >= -1 and l.Y <= Scaffolds.LEVELS * Scaffolds.LEVEL_H + 1 + margin
end

local function onShot(point: Vector3, from: Vector3)
	local now = os.clock()
	for _, tower in towers do
		if tower.state == "Up" and contains(tower, point, 0.6) then
			if now - tower.hitAt > Scaffolds.SHOT_MEMORY then
				tower.hits = 0
			end
			tower.hits += 1
			tower.hitAt = now
			if tower.hits >= Scaffolds.SHOTS then
				tip(tower, point - from, 1)
			else
				sound(tower.pieces[1].part, Scaffolds.KNOCKS, 0.5, 1.3)
			end
			return
		end
	end
end

local function onBlast(center: Vector3, radius: number)
	for _, tower in towers do
		local gap = tower.base.Position + Vector3.new(0, 5, 0) - center
		if tower.state == "Up" and gap.Magnitude < radius + 4 then
			tip(tower, gap, 1.8)
			local t = tower
			task.delay(0.2, function()
				if t.state == "Tipping" then
					smash(t, Vector3.new(gap.X, 0, gap.Z).Magnitude > 0.1 and Vector3.new(gap.X, 0, gap.Z).Unit or Vector3.xAxis)
					for _, piece in t.pieces do
						piece.part.AssemblyLinearVelocity += (piece.part.Position - center).Unit * 28 + Vector3.new(0, 10, 0)
					end
				end
			end)
		end
	end
end

local function onReset(center: Vector3, radius: number)
	for _, tower in towers do
		if tower.state == "Down" and (tower.base.Position - center).Magnitude <= radius then
			rebuild(tower)
		end
	end
end

-- Free ground for a tower: nothing standing in its way, flat floor under it.
local function place(at: Vector3, yaw: number, skip: { Instance }): CFrame?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(at + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), params)
	if not hit or math.abs(hit.Position.Y - at.Y) > 2.5 or hit.Normal.Y < 0.96 then
		return nil
	end
	local base = CFrame.new(hit.Position) * CFrame.Angles(0, yaw, 0)
	local over = OverlapParams.new()
	over.FilterType = Enum.RaycastFilterType.Exclude
	over.FilterDescendantsInstances = skip
	local high = Scaffolds.LEVELS * Scaffolds.LEVEL_H
	local found = Workspace:GetPartBoundsInBox(base * CFrame.new(0, high / 2 + 1.4, 0), Vector3.new(Scaffolds.WIDE + 4, high, Scaffolds.DEEP + 4), over)
	for _, p in found do
		if p.Transparency < 1 or p.CanCollide then
			return nil
		end
	end
	return base
end

-- The towers of one lab: a row of three to fall like dominoes, and up to four alone, round the lab.
function Scaffolds.buildLab(folder: Instance, origin: Vector3)
	local skip: { Instance } = {}
	for _, name in { "Dummies", "Newspapers", "LocalFx", "BloodFx" } do
		local f = Workspace:FindFirstChild(name)
		if f then
			table.insert(skip, f)
		end
	end
	local made = 0
	-- The row: tried at several spots and ways until all three fit.
	local done = false
	for _, r in { 46, 56, 66, 76, 86 } do
		for k = 0, 23 do
			if done then
				break
			end
			local a = k / 24 * math.pi * 2
			local first = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local yaw = -a
			local ahead = (CFrame.Angles(0, yaw, 0) * Vector3.new(0, 0, 1))
			local spots: { CFrame } = {}
			for n = 0, 2 do
				local c = place(first + ahead * n * 8.5, yaw, skip)
				if not c then
					break
				end
				table.insert(spots, c)
			end
			if #spots == 3 then
				for _, c in spots do
					build(folder, c, origin)
					made += 1
				end
				done = true
			end
		end
	end
	-- The ones alone, well apart.
	local singles = 0
	for _, r in { 52, 72, 88, 62 } do
		for k = 0, 15 do
			if singles >= 4 then
				break
			end
			local a = (k + r / 10) / 16 * math.pi * 2
			local at = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local far = true
			for _, t in towers do
				if (t.base.Position - at).Magnitude < 32 then
					far = false
					break
				end
			end
			local c = if far then place(at, -a, skip) else nil
			if c then
				build(folder, c, origin)
				singles += 1
				made += 1
			end
		end
	end
	return made
end

Knockables.listeners = Knockables.listeners or {}
table.insert(Knockables.listeners, { shot = onShot, blast = onBlast, reset = onReset })

return Scaffolds
