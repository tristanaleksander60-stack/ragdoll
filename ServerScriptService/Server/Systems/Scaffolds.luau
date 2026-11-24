--!strict
-- Scaffolds (24 Nov 2026, owner: "satisfying wooden scaffolds round about that you can knock over", "they break one
-- post at a time: the little piece you shoot flies off"). Wooden towers in every lab, alone and in a row. At rest every
-- piece is anchored (no cost). A shot takes off the very piece it hit; a car, a thrown ragdoll, a falling plank or a
-- running player the pieces they run into; a blast all in its reach. When too few posts are left to hold a storey up,
-- what stands on it leans over to the weak side and comes down in planks. A while after the last hit the pieces fly
-- back, from the bottom up. Knockables tells of shots, blasts and RESET.

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
Scaffolds.SHOT_MARGIN = 0.9 -- studs from a piece's surface a round still hits it
Scaffolds.BREAK_TILT = 52 -- degrees it leans when it breaks up
Scaffolds.BREAK_MAX = 3 -- s at most in one piece
Scaffolds.REBUILD_AFTER = 14
Scaffolds.CREAK = { 9120829478, 9114496277, 9114496341 } -- (Pro Sound Effects)
Scaffolds.CRASH = { 9120964951, 9126254743, 9120871246 }
Scaffolds.KNOCKS = { 9126254743, 9120871246 }

type Piece = { part: BasePart, home: CFrame, kind: string, level: number, x: number, z: number, loose: boolean }
type Tower = {
	model: Model,
	pieces: { Piece },
	byPart: { [BasePart]: Piece },
	base: CFrame,
	state: string, -- "Up" (whole or in part) | "Rebuild" | "Gone"
	falling: { [number]: boolean }, -- storeys that come down now
	damagedAt: number,
	token: number,
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

local breakOff: (Tower, Piece, Vector3, boolean?) -> ()

local function fastEnough(part: BasePart): boolean
	return not part.Anchored and part.AssemblyLinearVelocity.Magnitude >= Scaffolds.TOUCH_SPEED
end

local function build(folder: Instance, base: CFrame, origin: Vector3): Tower
	local model = Instance.new("Model")
	model.Name = "Scaffold"
	local tower: Tower = { model = model, pieces = {}, byPart = {}, base = base, state = "Up", falling = {}, damagedAt = 0, token = 0 }
	local function plank(size: Vector3, at: CFrame, kind: string, level: number, x: number, z: number)
		local p = Instance.new("Part")
		p.Name = "ScaffoldPlank"
		p.Size = size
		p.CFrame = base * at
		p.Color = WOODS[rng:NextInteger(1, #WOODS)]
		p.Material = Enum.Material.WoodPlanks
		p.Anchored = true
		p.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.55, 0.12)
		p.Parent = model
		local piece: Piece = { part = p, home = p.CFrame, kind = kind, level = level, x = x, z = z, loose = false }
		table.insert(tower.pieces, piece)
		tower.byPart[p] = piece
		p.Touched:Connect(function(other: BasePart)
			if tower.state == "Up" and not piece.loose and p.Anchored and fastEnough(other) and other.Name ~= "HeadBit" then
				local v = other.AssemblyLinearVelocity
				breakOff(tower, piece, v.Unit * math.min(v.Magnitude * 0.6, 34))
			end
		end)
	end
	local W, D, H = Scaffolds.WIDE, Scaffolds.DEEP, Scaffolds.LEVEL_H
	for level = 0, Scaffolds.LEVELS - 1 do
		local y = level * H
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				plank(Vector3.new(0.42, H, 0.42), CFrame.new(x * (W / 2 - 0.25), y + H / 2, z * (D / 2 - 0.25)), "post", level, x, z)
			end
		end
		-- (The deck, three boards.)
		for k = -1, 1 do
			plank(Vector3.new(W + 0.7, 0.24, D / 3 - 0.06), CFrame.new(rng:NextNumber(-0.15, 0.15), y + H + 0.12, k * D / 3), "deck", level, 0, k)
		end
		-- (A brace across on each long side, turning over every level; a rail at the ends.)
		local way = if level % 2 == 0 then 1 else -1
		local long = math.sqrt((W - 0.5) ^ 2 + (H - 0.6) ^ 2)
		local lean = math.atan2(H - 0.6, W - 0.5)
		for _, z in { -1, 1 } do
			plank(Vector3.new(long, 0.3, 0.16), CFrame.new(0, y + H / 2, z * (D / 2 + 0.06)) * CFrame.Angles(0, 0, lean * way * z), "brace", level, 0, z)
		end
		for _, x in { -1, 1 } do
			plank(Vector3.new(0.16, 0.3, D), CFrame.new(x * (W / 2 + 0.06), y + H * 0.45, 0), "rail", level, x, 0)
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
	if tower.state ~= "Up" then
		return
	end
	tower.state = "Rebuild"
	tower.token += 1
	local token = tower.token
	local n = 0
	for _, piece in tower.pieces do
		if piece.loose then
			n += 1
			local at = n
			local p = piece.part
			for _, w in p:GetChildren() do
				if w:IsA("WeldConstraint") then
					w:Destroy()
				end
			end
			p.Anchored = true
			p.CanCollide = false
			-- (From the bottom up, each with a little overshoot.)
			task.delay((at - 1) * 0.045, function()
				if tower.token ~= token or not p.Parent then
					return
				end
				TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = piece.home }):Play()
				if at % 4 == 0 then
					sound(p, Scaffolds.KNOCKS, 0.35, 1.5)
				end
			end)
		end
	end
	task.delay(n * 0.045 + 0.65, function()
		if tower.token ~= token or not tower.model.Parent then
			return
		end
		for _, piece in tower.pieces do
			piece.part.CFrame = piece.home
			piece.part.CanCollide = true
			piece.loose = false
		end
		tower.falling = {}
		tower.state = "Up"
	end)
end

-- Rebuilt REBUILD_AFTER s after the last damage.
local function hurt(tower: Tower)
	tower.damagedAt = os.clock()
	local at = tower.damagedAt
	task.delay(Scaffolds.REBUILD_AFTER, function()
		if tower.damagedAt == at and tower.model.Parent then
			rebuild(tower)
		end
	end)
end

local function free(piece: Piece)
	piece.loose = true
	local p = piece.part
	p.Anchored = false
	pcall(function()
		p:SetNetworkOwner(nil)
	end)
end

local function splinters(at: Vector3, color: Color3)
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = Workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.16), NumberSequenceKeypoint.new(1, 0.06) })
	e.Lifetime = NumberRange.new(0.3, 0.7)
	e.Speed = NumberRange.new(5, 14)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -50, 0)
	e.LightInfluence = 1
	e.Rate = 0
	e.Parent = a
	e:Emit(9)
	Debris:AddItem(a, 1.2)
end

-- What stands on storey `level` comes down: it leans over to `way` as one piece, and breaks up as it hits or has leaned far.
local function collapse(tower: Tower, level: number, way: Vector3)
	if tower.falling[level] then
		return
	end
	tower.falling[level] = true
	local group: { Piece } = {}
	for _, piece in tower.pieces do
		if not piece.loose and (piece.level > level or (piece.level == level and piece.kind == "deck")) then
			table.insert(group, piece)
		end
	end
	local core = group[1]
	if not core then
		return
	end
	local dir = if way.Magnitude > 0.1 then way.Unit else Vector3.xAxis
	for i, piece in group do
		piece.loose = true
		if i > 1 then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = core.part, piece.part
			w.Parent = piece.part
		end
	end
	for _, piece in group do
		piece.part.Anchored = false
	end
	pcall(function()
		core.part:SetNetworkOwner(nil)
	end)
	core.part.AssemblyAngularVelocity = Vector3.yAxis:Cross(dir) * 0.55
	core.part.AssemblyLinearVelocity = dir * 2.2
	sound(core.part, Scaffolds.CREAK, 0.9, 1)
	hurt(tower)
	task.spawn(function()
		local t0 = os.clock()
		local start = core.part.Position.Y
		while os.clock() - t0 < Scaffolds.BREAK_MAX do
			task.wait(0.05)
			if not core.part.Parent or tower.state ~= "Up" then
				return
			end
			local lean = math.deg(math.acos(math.clamp(core.part.CFrame.UpVector:Dot(core.home.UpVector), -1, 1)))
			local fell = start - core.part.Position.Y
			if lean > Scaffolds.BREAK_TILT or (fell > 2 and core.part.AssemblyLinearVelocity.Magnitude < 6) then
				break
			end
		end
		local middle = Vector3.zero
		for _, piece in group do
			for _, w in piece.part:GetChildren() do
				if w:IsA("WeldConstraint") then
					w:Destroy()
				end
			end
			middle += piece.part.Position / #group
		end
		for _, piece in group do
			pcall(function()
				piece.part:SetNetworkOwner(nil)
			end)
			piece.part.AssemblyLinearVelocity += rng:NextUnitVector() * rng:NextNumber(1, 5)
			piece.part.AssemblyAngularVelocity += rng:NextUnitVector() * rng:NextNumber(0, 5)
		end
		sound(core.part, Scaffolds.CRASH, 1, 1)
		sound(core.part, Scaffolds.CRASH, 0.7, 0.8)
		dust(Vector3.new(middle.X, tower.base.Y + 1, middle.Z), 18)
	end)
end

-- Whether each storey still carries what stands on it: three posts do, two across from each other do, less does not.
local function check(tower: Tower)
	for level = 0, Scaffolds.LEVELS - 1 do
		local left: { Piece } = {}
		local lost = Vector3.zero
		for _, piece in tower.pieces do
			if piece.kind == "post" and piece.level == level then
				if piece.loose then
					lost += tower.base:VectorToWorldSpace(Vector3.new(piece.x, 0, piece.z))
				else
					table.insert(left, piece)
				end
			end
		end
		local across = #left == 2 and left[1].x ~= left[2].x and left[1].z ~= left[2].z
		if #left < 2 or (#left == 2 and not across) then
			collapse(tower, level, lost)
			return
		end
	end
end

-- One piece off, flying with `velocity`.
function breakOff(tower: Tower, piece: Piece, velocity: Vector3, quiet: boolean?)
	if tower.state ~= "Up" or piece.loose then
		return
	end
	free(piece)
	local p = piece.part
	p.AssemblyLinearVelocity = velocity + Vector3.new(0, 3, 0)
	p.AssemblyAngularVelocity = rng:NextUnitVector() * rng:NextNumber(3, 9)
	if not quiet then
		sound(p, Scaffolds.KNOCKS, 0.7, 1.25)
		splinters(p.Position, p.Color)
	end
	hurt(tower)
	-- (A post takes the brace and the rail that were nailed to it, half the time.)
	if piece.kind == "post" then
		for _, other in tower.pieces do
			if not other.loose and other.level == piece.level and ((other.kind == "brace" and other.z == piece.z) or (other.kind == "rail" and other.x == piece.x)) and rng:NextNumber() < 0.5 then
				free(other)
				other.part.AssemblyAngularVelocity = rng:NextUnitVector() * rng:NextNumber(1, 4)
			end
		end
		task.delay(0.12, function()
			if tower.state == "Up" then
				check(tower)
			end
		end)
	end
end

-- How far a point is from a piece's surface.
local function distance(p: BasePart, point: Vector3): number
	local l = p.CFrame:PointToObjectSpace(point)
	local h = p.Size / 2
	return Vector3.new(math.max(math.abs(l.X) - h.X, 0), math.max(math.abs(l.Y) - h.Y, 0), math.max(math.abs(l.Z) - h.Z, 0)).Magnitude
end

local function contains(tower: Tower, point: Vector3, margin: number): boolean
	local l = tower.base:PointToObjectSpace(point)
	return math.abs(l.X) <= Scaffolds.WIDE / 2 + 1 + margin and math.abs(l.Z) <= Scaffolds.DEEP / 2 + 1 + margin
		and l.Y >= -1 and l.Y <= Scaffolds.LEVELS * Scaffolds.LEVEL_H + 1 + margin
end

local function onShot(point: Vector3, from: Vector3)
	for _, tower in towers do
		if tower.state == "Up" and contains(tower, point, 0.6) then
			local best: Piece? = nil
			local bestD = Scaffolds.SHOT_MARGIN
			for _, piece in tower.pieces do
				if not piece.loose then
					local d = distance(piece.part, point)
					if d < bestD then
						best, bestD = piece, d
					end
				end
			end
			if best then
				local way = point - from
				breakOff(tower, best, (if way.Magnitude > 0.1 then way.Unit else Vector3.xAxis) * 20)
				return
			end
		end
	end
end

local function onBlast(center: Vector3, radius: number)
	for _, tower in towers do
		local mid = tower.base.Position + Vector3.new(0, Scaffolds.LEVELS * Scaffolds.LEVEL_H / 2, 0)
		if tower.state == "Up" and (mid - center).Magnitude < radius + 10 then
			local heard = false
			for _, piece in tower.pieces do
				local gap = piece.part.Position - center
				if gap.Magnitude < radius then
					local out = (if gap.Magnitude > 0.1 then gap.Unit else Vector3.yAxis) * (44 * (1 - gap.Magnitude / radius) + 10)
					if piece.loose then
						piece.part.AssemblyLinearVelocity += out
					else
						breakOff(tower, piece, out + Vector3.new(0, 8, 0), heard)
						heard = true
					end
				end
			end
		end
	end
end

local function onReset(center: Vector3, radius: number)
	for _, tower in towers do
		if (tower.base.Position - center).Magnitude <= radius then
			for _, piece in tower.pieces do
				if piece.loose then
					rebuild(tower)
					break
				end
			end
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
