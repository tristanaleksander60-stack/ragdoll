--!strict
-- DESTRUCTION 2 (owner, 26 Nov 2026; docs/DESTRUCTION.md, Config.BREAKABLES): wooden crates you can shoot to pieces.
-- A few stacks of crates in every lab (by the cannon, the rocket and the car bays). A round leaves a small dark hole
-- in the wood (at most HOLE_MAX a crate, gone after HOLE_HOLD s); SHOTS_TO_BREAK rounds, a blast near it, or a body
-- flying into it faster than BODY_BREAK studs/s break it into planks and splinters. The planks lie REBUILD s, then go,
-- and the crate stands there again. The server decides; the pieces are ordinary physics parts (capped per lab).
-- Hooked into Knockables' listeners (HitService's shots and the blasts).

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Knockables = require(script.Parent.Knockables)

local Breakables = {}

Breakables.SHOTS_TO_BREAK = 4
Breakables.BODY_BREAK = 45
Breakables.REBUILD = 20
Breakables.HOLE_MAX = 10
Breakables.HOLE_HOLD = 30
Breakables.PLANKS = 6
Breakables.SIZE = 4

-- Crate stacks in lab space (x, z): two crates side by side and one on top.
Breakables.STACKS = {
	Vector2.new(42, 18), -- by the cannon
	Vector2.new(-48, 4), -- by the rocket and the slingshot
	Vector2.new(20, 46), -- by the car bays
}

local WOOD = Color3.fromRGB(150, 112, 72)
local HOLE = Color3.fromRGB(34, 26, 20)

type Crate = { part: BasePart, hits: number, holes: { BasePart }, broken: boolean }
local crates: { [BasePart]: Crate } = {}
local hooked = false

local function restore(c: Crate)
	c.broken = false
	c.hits = 0
	c.part.Transparency = 0
	c.part.CanCollide = true
	c.part.CanQuery = true
	for _, h in c.holes do
		h:Destroy()
	end
	table.clear(c.holes)
end

local function breakCrate(c: Crate, push: Vector3)
	if c.broken then
		return
	end
	c.broken = true
	local p = c.part
	for _, h in c.holes do
		h:Destroy()
	end
	table.clear(c.holes)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	local into = p.Parent
	for i = 1, Breakables.PLANKS do
		local plank = Instance.new("Part")
		plank.Name = "CratePlank"
		plank.Size = Vector3.new(0.5, 0.35, Breakables.SIZE * (0.6 + math.random() * 0.4))
		plank.Color = WOOD:Lerp(Color3.fromRGB(110, 80, 50), math.random() * 0.5)
		plank.Material = Enum.Material.WoodPlanks
		plank.CFrame = p.CFrame * CFrame.new((math.random() - 0.5) * 3, (math.random() - 0.5) * 3, 0) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		plank.CanQuery = false
		plank.CastShadow = false
		plank.Parent = into
		plank.AssemblyLinearVelocity = push * (0.4 + math.random() * 0.4) + Vector3.new((math.random() - 0.5) * 18, 10 + math.random() * 14, (math.random() - 0.5) * 18)
		plank.AssemblyAngularVelocity = Vector3.new(math.random() * 12, math.random() * 12, math.random() * 12)
		Debris:AddItem(plank, Breakables.REBUILD)
	end
	-- Splinters and wood dust.
	local burst = Instance.new("Attachment")
	burst.WorldPosition = p.Position
	burst.Parent = Workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(200, 180, 150))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.8, 1.6)
	e.Speed = NumberRange.new(4, 10)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = burst
	e:Emit(14)
	Debris:AddItem(burst, 3)
	task.delay(Breakables.REBUILD, function()
		if p.Parent then
			restore(c)
		end
	end)
end

local function crateAt(point: Vector3): Crate?
	for part, c in crates do
		if not c.broken and part.Parent then
			local l = part.CFrame:PointToObjectSpace(point)
			local s = part.Size / 2 + Vector3.one * 0.6
			if math.abs(l.X) <= s.X and math.abs(l.Y) <= s.Y and math.abs(l.Z) <= s.Z then
				return c
			end
		end
	end
	return nil
end

local function hole(c: Crate, point: Vector3, from: Vector3)
	local p = c.part
	-- On the face the round went into: the box axis with the largest share of the way in.
	local l = p.CFrame:PointToObjectSpace(point)
	local h = p.Size / 2
	local ax = math.abs(l.X) / h.X
	local ay = math.abs(l.Y) / h.Y
	local az = math.abs(l.Z) / h.Z
	local normal = if ax >= ay and ax >= az then Vector3.new(math.sign(l.X), 0, 0) elseif ay >= az then Vector3.new(0, math.sign(l.Y), 0) else Vector3.new(0, 0, math.sign(l.Z))
	local onFace = Vector3.new(
		if normal.X ~= 0 then normal.X * h.X else math.clamp(l.X, -h.X * 0.85, h.X * 0.85),
		if normal.Y ~= 0 then normal.Y * h.Y else math.clamp(l.Y, -h.Y * 0.85, h.Y * 0.85),
		if normal.Z ~= 0 then normal.Z * h.Z else math.clamp(l.Z, -h.Z * 0.85, h.Z * 0.85)
	)
	local world = p.CFrame:PointToWorldSpace(onFace)
	local worldNormal = p.CFrame:VectorToWorldSpace(normal)
	local d = Instance.new("Part")
	d.Name = "CrateHole"
	d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
	d.Shape = Enum.PartType.Cylinder
	d.Color = HOLE
	d.Material = Enum.Material.SmoothPlastic
	local size = 0.28 + math.random() * 0.14
	d.Size = Vector3.new(0.04, size, size)
	d.CFrame = CFrame.lookAt(world + worldNormal * 0.02, world + worldNormal) * CFrame.Angles(0, math.rad(90), 0)
	d.Parent = p
	table.insert(c.holes, d)
	if #c.holes > Breakables.HOLE_MAX then
		table.remove(c.holes, 1):Destroy()
	end
	task.delay(Breakables.HOLE_HOLD, function()
		local i = table.find(c.holes, d)
		if i then
			table.remove(c.holes, i)
		end
		d:Destroy()
	end)
end

local function hook()
	if hooked then
		return
	end
	hooked = true
	table.insert(Knockables.listeners, {
		shot = function(point: Vector3, from: Vector3)
			local c = crateAt(point)
			if not c then
				return
			end
			hole(c, point, from)
			c.hits += 1
			if c.hits >= Breakables.SHOTS_TO_BREAK then
				local dir = point - from
				breakCrate(c, (if dir.Magnitude > 0.01 then dir.Unit else Vector3.zAxis) * 30)
			end
		end,
		blast = function(center: Vector3, radius: number)
			for part, c in crates do
				local off = part.Position - center
				if not c.broken and off.Magnitude < radius then
					breakCrate(c, (if off.Magnitude > 0.01 then off.Unit else Vector3.yAxis) * 50)
				end
			end
		end,
		reset = function(center: Vector3, radius: number)
			for part, c in crates do
				if c.broken and (part.Position - center).Magnitude < radius then
					restore(c)
				end
			end
		end,
	})
end

-- The crate stacks of one lab (Playground.build calls this after the lab stands).
function Breakables.buildLab(folder: Instance, origin: Vector3)
	hook()
	local into = Instance.new("Folder")
	into.Name = "Breakables"
	into.Parent = folder
	local dummies = Workspace:FindFirstChild("Dummies")
	local s = Breakables.SIZE
	for _, spot in Breakables.STACKS do
		local base = Vector3.new(origin.X + spot.X, origin.Y + 0.5 + s / 2, origin.Z + spot.Y)
		for _, off in { Vector3.new(-s / 2 - 0.05, 0, 0), Vector3.new(s / 2 + 0.05, 0, 0), Vector3.new(0, s, 0) } do
			local p = Instance.new("Part")
			p.Name = "BreakCrate"
			p.Anchored = true
			p.Size = Vector3.one * s
			p.Color = WOOD
			p.Material = Enum.Material.WoodPlanks
			p.CFrame = CFrame.new(base + off) * CFrame.Angles(0, math.rad(math.random(-8, 8)), 0)
			p.Parent = into
			local c: Crate = { part = p, hits = 0, holes = {}, broken = false }
			crates[p] = c
			p.Touched:Connect(function(other: BasePart)
				if c.broken then
					return
				end
				local live = dummies or Workspace:FindFirstChild("Dummies")
				if live and other:IsDescendantOf(live) and other.AssemblyLinearVelocity.Magnitude > Breakables.BODY_BREAK then
					breakCrate(c, other.AssemblyLinearVelocity * 0.5)
				end
			end)
			p.Destroying:Connect(function()
				crates[p] = nil
			end)
		end
	end
end

return Breakables
