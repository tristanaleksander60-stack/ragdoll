--!strict
-- Bullet holes (round 3, M2). A round that misses leaves a small dark hole with a grey scorch ring
-- where it struck a wall, the floor or a crate; one that hits a body leaves a small dark purple hole
-- on that very spot of the limb, which moves with the body and is where the body bleeds from
-- (BloodFx drips from its open holes). Holes on bodies go when the body is patched up or gone;
-- holes in the world fade after a while, and the oldest make way when there are too many.
--
-- Client only, purely visual: plain parts (no textures), anchored or welded, never colliding,
-- queried or touched, casting no shadow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Anatomy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anatomy"))
local DummySkins = require(script.Parent:WaitForChild("DummySkins"))

local BulletHoles = {}

BulletHoles.MAX_WORLD = 60 -- holes in the world on this screen
BulletHoles.WORLD_HOLD = 25 -- s a hole in the world stays
BulletHoles.MAX_PER_BODY = 8
BulletHoles.BLEEDS_FOR = 60 -- s a hole on a body is a place it bleeds from
BulletHoles.SKIN_FIT = 0.86 -- (0.36.6: the ellipse a hole sits on, as a share of the skin box; well inside, since the sculpted mesh is thinner than its box)
BulletHoles.SKIN_SINK = 0.06 -- studs a hole ball sits under that ellipse

local HOLE = Color3.fromRGB(26, 24, 30)
local SCORCH = Color3.fromRGB(92, 88, 84)
local BODY_HOLE = Anatomy.BLOOD_DARK

type Hole = { parts: { BasePart }, at: number }
local world: { Hole } = {}
type BodyHole = { part: BasePart, at: number }
local bodies: { [Model]: { BodyHole } } = {}
local watched: { [Model]: boolean } = {}
local sweeping = false

local folder: Folder? = nil
local function container(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "BulletHoles"
	made.Parent = Workspace
	folder = made
	return made
end

-- (Pooled: a hole that goes is kept aside and used again, so a nail gun at the cap moves parts
-- about instead of making and destroying two dozen a second.)
local SPARE_MAX = 140
local spare: { Part } = {}
local function disc(diameter: number, color: Color3, cframe: CFrame, transparency: number?): Part
	local p = table.remove(spare)
	if not p then
		p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
	end
	local part = p :: Part
	part.Shape = Enum.PartType.Cylinder
	part.Name = "Hole"
	part.Size = Vector3.new(0.03, diameter, diameter)
	part.Color = color
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CFrame = cframe
	return part
end

-- Back to the spare pile (its weld, if it was on a body, goes).
local release: (BasePart) -> ()
function release(p: BasePart)
	-- (V9-NOW: a mild hole carries its scorch ring: that goes back first.)
	local ring = p:FindFirstChild("BulletScorch")
	if ring and ring:IsA("BasePart") then
		release(ring)
	end
	-- (Gone with its limb already, a torn-off arm that fell out of the world: nothing to keep.)
	local ok = pcall(function()
		local weld = p:FindFirstChildOfClass("WeldConstraint")
		if weld then
			weld:Destroy()
		end
		p.Parent = nil
	end)
	if ok and #spare < SPARE_MAX and p:IsA("Part") then
		table.insert(spare, p)
	elseif ok then
		p:Destroy()
	end
end

-- A Cylinder lies flat on a surface when its X axis is the surface's normal.
local function flatOn(at: Vector3, normal: Vector3, lift: number): CFrame
	local up = normal.Unit
	local across = up:Cross(if math.abs(up.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis).Unit
	return CFrame.fromMatrix(at + up * lift, up, across)
end

local function fadeOut(parts: { BasePart }, seconds: number)
	for _, p in parts do
		if p.Parent then
			local t = TweenService:Create(p, TweenInfo.new(seconds), { Transparency = 1 })
			t:Play()
			t.Completed:Once(function()
				release(p)
			end)
		end
	end
end

-- A miss struck `instance` at `at` (surface normal `normal`): a hole there, if it is something that
-- stands still (a moving prop or a body takes none).
function BulletHoles.surface(at: Vector3, normal: Vector3, instance: Instance?)
	if instance and instance:IsA("BasePart") and not (instance :: BasePart).Anchored and not instance:IsA("Terrain") then
		return
	end
	if normal.Magnitude < 0.5 then
		return
	end
	while #world >= BulletHoles.MAX_WORLD do
		local oldest = table.remove(world, 1) :: Hole
		fadeOut(oldest.parts, 0.2)
	end
	local f = container()
	-- (On a floor, above the paint: lab floors and lines are thin parts no ray hits, up to a tenth
	-- of a stud over the ground.)
	local lift = if normal.Y > 0.9 then 0.12 else 0.015
	local ring = disc(0.62, SCORCH, flatOn(at, normal, lift), 0.45)
	local hole = disc(0.28, HOLE, flatOn(at, normal, lift + 0.015))
	ring.Parent = f
	hole.Parent = f
	local record: Hole = { parts = { ring, hole }, at = os.clock() }
	table.insert(world, record)
	-- (One sweep for all of them, once a second while any are out: the oldest are first in the list.)
	if not sweeping then
		sweeping = true
		task.spawn(function()
			while #world > 0 do
				task.wait(1)
				local now = os.clock()
				while world[1] and now - world[1].at >= BulletHoles.WORLD_HOLD do
					local old = table.remove(world, 1) :: Hole
					fadeOut(old.parts, 1)
				end
			end
			sweeping = false
		end)
	end
end

-- The part of a body nearest a point, and the face it is on (its outward normal), or nil.
local function nearestPart(model: Model, at: Vector3): (BasePart?, Vector3)
	local best: BasePart? = nil
	local bestDistance = math.huge
	local bestNormal = Vector3.yAxis
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" and child.Name ~= "Stump" and child.Transparency < 1 then
			local l = child.CFrame:PointToObjectSpace(at)
			local half = child.Size / 2
			local clamped = Vector3.new(math.clamp(l.X, -half.X, half.X), math.clamp(l.Y, -half.Y, half.Y), math.clamp(l.Z, -half.Z, half.Z))
			local d = (l - clamped).Magnitude
			if d < bestDistance then
				-- The face: the axis the point sits furthest out on (for its size).
				local rx, ry, rz = math.abs(l.X) / math.max(half.X, 0.01), math.abs(l.Y) / math.max(half.Y, 0.01), math.abs(l.Z) / math.max(half.Z, 0.01)
				local n
				if rx >= ry and rx >= rz then
					n = Vector3.new(math.sign(l.X), 0, 0)
				elseif ry >= rz then
					n = Vector3.new(0, math.sign(l.Y), 0)
				else
					n = Vector3.new(0, 0, math.sign(l.Z))
				end
				best, bestDistance, bestNormal = child, d, n
			end
		end
	end
	if not best or bestDistance > 2.5 then
		return nil, Vector3.yAxis
	end
	return best, bestNormal
end

local function clearBody(model: Model)
	local list = bodies[model]
	bodies[model] = nil
	if list then
		for _, h in list do
			release(h.part)
		end
	end
end

-- A round hit a body at `at`: a hole on that spot of the limb, which moves with it. Returns the
-- part it is on (nil: no body part there).
function BulletHoles.body(model: Model, at: Vector3, mild: boolean?): BasePart?
	local part, normal = nearestPart(model, at)
	if not part then
		return nil
	end
	local list = bodies[model] or {}
	bodies[model] = list
	while #list >= BulletHoles.MAX_PER_BODY do
		local oldest = table.remove(list, 1) :: BodyHole
		release(oldest.part)
	end
	-- On the part's surface right under the point, lying flat on that face.
	local l = part.CFrame:PointToObjectSpace(at)
	local half = part.Size / 2
	local onFace = Vector3.new(
		if normal.X ~= 0 then normal.X * half.X else math.clamp(l.X, -half.X * 0.85, half.X * 0.85),
		if normal.Y ~= 0 then normal.Y * half.Y else math.clamp(l.Y, -half.Y * 0.85, half.Y * 0.85),
		if normal.Z ~= 0 then normal.Z * half.Z else math.clamp(l.Z, -half.Z * 0.85, half.Z * 0.85)
	)
	local worldAt = part.CFrame:PointToWorldSpace(onFace)
	local worldNormal = part.CFrame:VectorToWorldSpace(normal)
	-- On a dummy's sculpted skin (DummySkins): onto the skin's real surface under that spot, lying
	-- on it (the block underneath is hidden on this screen).
	local skin = DummySkins.skinOf(part)
	if skin then
		-- V9-NOW 13 (owner, 21 Nov 2026: "holes hang outside the dummy"): the skins' collision is their box
		-- (CollisionFidelity Box, not changeable in a live game), so a ray stopped on the box, off the visible
		-- mesh. The limb is about an elliptic cylinder inscribed in that box (the torso and the feet too): the
		-- hole goes on that ellipse under the hit point, facing out along its normal, and is welded to the limb.
		local l = skin.CFrame:PointToObjectSpace(at)
		local a = skin.Size.X / 2 * BulletHoles.SKIN_FIT
		local b = skin.Size.Z / 2 * BulletHoles.SKIN_FIT
		local x, z = l.X, l.Z
		if math.abs(x) < 1e-3 and math.abs(z) < 1e-3 then
			local back = skin.CFrame:VectorToObjectSpace(worldNormal)
			x, z = back.X, back.Z
			if math.abs(x) < 1e-3 and math.abs(z) < 1e-3 then
				z = -1
			end
		end
		local k = 1 / math.sqrt((x / a) ^ 2 + (z / b) ^ 2)
		local px, pz = x * k, z * k
		local py = math.clamp(l.Y, -skin.Size.Y / 2 * 0.85, skin.Size.Y / 2 * 0.85)
		local n = Vector3.new(px / (a * a), 0, pz / (b * b)).Unit
		worldAt = skin.CFrame:PointToWorldSpace(Vector3.new(px, py, pz))
		worldNormal = skin.CFrame:VectorToWorldSpace(n)
	end
	-- (V9-NOW: mild = BLOOD off: a dark hole in a grey scorch ring, a little bigger so it reads on the grey
	-- matte skin from a few studs off; the ring is welded to the hole and goes with it.)
	-- (0.36.6, owner: holes still stood out from the dummy. On a skin the hole is a small ball sunk into the
	-- limb, so only a round dark spot shows where it breaks the real mesh, wherever that surface really is.)
	-- (V10, owner: "the flat holes lie on top of the ragdoll when you shoot its edge": a hole whose surface faces
	-- away from the camera, a graze on the outline, would stand off the silhouette; none is drawn there.)
	do
		local cam = workspace.CurrentCamera
		if skin and cam and worldNormal:Dot((cam.CFrame.Position - worldAt).Unit) < 0.45 then
			return part
		end
	end
	-- (V10 phase 2, owner: "the bullet holes and blood still sit out on the ragdoll like bubbles": the sunk balls
	-- showed as domes. Now every hole is a flat disc lying on the surface, thin as paint; on a skin it lies on the
	-- ellipse a little inside the box, where the sculpted mesh is.)
	local hole = disc(if mild then 0.3 else 0.26, if mild then HOLE else BODY_HOLE, flatOn(worldAt, worldNormal, if skin then 0 else 0.03))
	if skin then
		hole.Size = Vector3.new(0.02, hole.Size.Y, hole.Size.Z)
	end
	hole.Name = "BulletHole"
	hole.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = hole
	weld.Parent = hole
	hole.Parent = part
	if mild and not skin then
		local ring = disc(0.56, SCORCH, flatOn(worldAt, worldNormal, 0.02), 0.35)
		ring.Name = "BulletScorch"
		ring.Anchored = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = hole
		w.Part1 = ring
		w.Parent = ring
		ring.Parent = hole
	end
	table.insert(list, { part = hole, at = os.clock() })
	if not watched[model] then
		watched[model] = true
		-- Patched up (its wound list cleared) or gone: the holes go too.
		model:GetAttributeChangedSignal("Wounds"):Connect(function()
			local w = model:GetAttribute("Wounds")
			if w == nil or w == "" then
				clearBody(model)
			end
		end)
		model.Destroying:Once(function()
			bodies[model] = nil
			watched[model] = nil
		end)
	end
	return part
end

-- Where a body bleeds from: its holes made in the last BLEEDS_FOR seconds (world positions).
function BulletHoles.openHoles(model: Model): { Vector3 }
	local out = {}
	local list = bodies[model]
	if list then
		local now = os.clock()
		for _, h in list do
			if h.part.Parent and now - h.at < BulletHoles.BLEEDS_FOR then
				table.insert(out, h.part.Position)
			end
		end
	end
	return out
end

-- Where a body bleeds from most: its newest open hole (world position), or nil.
function BulletHoles.newestHole(model: Model): Vector3?
	local list = bodies[model]
	if list then
		local h = list[#list]
		if h and h.part.Parent and os.clock() - h.at < BulletHoles.BLEEDS_FOR then
			return h.part.Position
		end
	end
	return nil
end

-- Tests: holes now in the world and on a body.
function BulletHoles.spare(): number
	return #spare
end
function BulletHoles.counts(model: Model?): (number, number)
	return #world, if model and bodies[model] then #(bodies[model] :: { BodyHole }) else 0
end

return BulletHoles
