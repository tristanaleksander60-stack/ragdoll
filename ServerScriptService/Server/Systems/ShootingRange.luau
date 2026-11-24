--!strict
-- ShootingRange (24 Nov 2026, owner): a small indoor range behind the creature yard of every lab (behind the compressor,
-- the washer and the mole). Four lanes, eight humanoid plates at two distances a lane. A shot, a blast or something thrown
-- swings a plate back on its hinge; it stands up again by itself. Everything is anchored; no loop runs. Knockables tells
-- of shots, blasts and RESET, so every weapon works as it is.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Knockables = require(script.Parent:WaitForChild("Knockables")) :: any

local ShootingRange = {}

ShootingRange.Z = 134 -- lab z of the open front (the yard ends at 129)
ShootingRange.WIDE = 52
ShootingRange.DEEP = 44
ShootingRange.HIGH = 13
ShootingRange.LANES = 4
ShootingRange.ROWS = { { 19, 34 }, { 25, 40 } } -- studs in from the front, odd and even lanes
ShootingRange.UP_AFTER = 3 -- s down
ShootingRange.TOUCH_SPEED = 16
ShootingRange.MARGIN = 0.7
ShootingRange.DING = 9113525391 -- (Pro Sound Effects, already in the game)

local WALL = Color3.fromRGB(112, 84, 62)
local DARK = Color3.fromRGB(58, 46, 38)
local FLOOR = Color3.fromRGB(128, 124, 118)
local ORANGE = Color3.fromRGB(240, 122, 32)
local PLATE = Color3.fromRGB(222, 214, 200)
local HIT = Color3.fromRGB(230, 70, 40)

type Target = { hinge: BasePart, home: CFrame, pieces: { BasePart }, down: boolean, token: number }
local targets: { Target } = {}

local function stand(t: Target)
	t.token += 1
	t.down = false
	for _, p in t.pieces do
		p.Color = PLATE
	end
	TweenService:Create(t.hinge, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = t.home }):Play()
end

local function fall(t: Target, piece: BasePart?)
	if piece then
		piece.Color = HIT
	end
	if t.down or not t.hinge.Parent then
		return
	end
	t.down = true
	t.token += 1
	local mine = t.token
	-- (The shooters stand towards -Z: it swings away from them.)
	TweenService:Create(t.hinge, TweenInfo.new(0.28, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = t.home * CFrame.Angles(math.rad(82), 0, 0) }):Play()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. ShootingRange.DING
	s.Volume = 0.7
	s.PlaybackSpeed = 1.5
	s.RollOffMaxDistance = 90
	s.Parent = t.hinge
	s:Play()
	Debris:AddItem(s, 3)
	task.delay(ShootingRange.UP_AFTER, function()
		if t.token == mine and t.hinge.Parent then
			stand(t)
		end
	end)
end

local function each(fn: (Target) -> ())
	for i = #targets, 1, -1 do
		local t = targets[i]
		if t.hinge.Parent then
			fn(t)
		else
			table.remove(targets, i)
		end
	end
end

table.insert(Knockables.listeners, {
	shot = function(point: Vector3, _from: Vector3)
		each(function(t)
			if (t.home.Position - point).Magnitude > 9 then
				return
			end
			for _, p in t.pieces do
				local l = p.CFrame:PointToObjectSpace(point)
				local h = p.Size / 2 + Vector3.one * ShootingRange.MARGIN
				if math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z then
					fall(t, p)
					return
				end
			end
		end)
	end,
	blast = function(center: Vector3, radius: number)
		each(function(t)
			if (t.home.Position - center).Magnitude < radius then
				fall(t, nil)
			end
		end)
	end,
	reset = function(center: Vector3, radius: number)
		each(function(t)
			if t.down and (t.home.Position - center).Magnitude < radius then
				stand(t)
			end
		end)
	end,
})

function ShootingRange.buildLab(folder: Instance, origin: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "ShootingRange"
	local W, D, H = ShootingRange.WIDE, ShootingRange.DEEP, ShootingRange.HIGH
	local at = CFrame.new(origin + Vector3.new(0, 0.2, ShootingRange.Z)) -- (floor level, the middle of the open front; +Z goes in)
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material, solid: boolean?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = at * CFrame.new(offset)
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if solid == false then
			p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
		end
		p.Parent = model
		return p
	end
	local concrete, metal, neon = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.Neon
	part("Floor", Vector3.new(W, 0.6, D), Vector3.new(0, -0.3, D / 2), FLOOR, concrete)
	part("WallLeft", Vector3.new(1, H, D), Vector3.new(-W / 2 + 0.5, H / 2, D / 2), WALL, concrete)
	part("WallRight", Vector3.new(1, H, D), Vector3.new(W / 2 - 0.5, H / 2, D / 2), WALL, concrete)
	part("WallBack", Vector3.new(W, H, 1), Vector3.new(0, H / 2, D - 0.5), WALL, concrete)
	part("Roof", Vector3.new(W, 0.8, D), Vector3.new(0, H + 0.4, D / 2), DARK, concrete)
	part("Lintel", Vector3.new(W, 2, 1), Vector3.new(0, H - 1, 0.5), WALL, concrete)
	part("LintelLine", Vector3.new(W, 0.35, 0.1), Vector3.new(0, H - 1.9, -0.05), ORANGE, Enum.Material.SmoothPlastic, false)
	part("Backstop", Vector3.new(W - 2, 5, 0.6), Vector3.new(0, 2.5, D - 1.4), DARK, Enum.Material.DiamondPlate)
	part("FireLine", Vector3.new(W - 2, 0.06, 0.5), Vector3.new(0, 0.04, 12.5), ORANGE, Enum.Material.SmoothPlastic, false)
	local lane = (W - 2) / ShootingRange.LANES
	for i = 1, ShootingRange.LANES - 1 do
		local x = -W / 2 + 1 + lane * i
		part("LaneLine", Vector3.new(0.35, 0.06, D - 14), Vector3.new(x, 0.04, D / 2 + 5.5), ORANGE, Enum.Material.SmoothPlastic, false)
		part("Divider", Vector3.new(0.6, 6, 5), Vector3.new(x, 3, 9.5), DARK, metal)
	end
	for i = 1, ShootingRange.LANES do
		local x = -W / 2 + 1 + lane * (i - 0.5)
		part("Counter", Vector3.new(lane - 4, 0.4, 1.6), Vector3.new(x, 3, 11), DARK, metal)
		for _, deep in ShootingRange.ROWS[(i - 1) % 2 + 1] do
			local off = if deep > 30 then 2 else -2
			local hinge = part("Hinge", Vector3.new(3, 0.3, 0.3), Vector3.new(x + off, 0.15, deep), DARK, metal)
			hinge.CanTouch = false
			local t: Target = { hinge = hinge, home = hinge.CFrame, pieces = {}, down = false, token = 0 }
			local function piece(name: string, size: Vector3, y: number)
				local p = part(name, size, Vector3.new(x + off, y, deep), PLATE, metal)
				p.Massless = true
				p.CanCollide = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = hinge, p
				weld.Parent = p
				p.Anchored = false
				p.Touched:Connect(function(other)
					if not other.Anchored and other.AssemblyLinearVelocity.Magnitude > ShootingRange.TOUCH_SPEED then
						fall(t, nil)
					end
				end)
				table.insert(t.pieces, p)
			end
			piece("Legs", Vector3.new(1.5, 2.4, 0.35), 1.4)
			piece("Torso", Vector3.new(2.7, 2.4, 0.35), 3.8)
			piece("Head", Vector3.new(1.3, 1.3, 0.35), 5.7)
			table.insert(targets, t)
		end
	end
	for i, z in { 8, 22, 36 } do
		local lamp = part("Lamp" .. i, Vector3.new(W - 14, 0.25, 0.8), Vector3.new(0, H - 0.15, z), Color3.fromRGB(255, 206, 140), neon, false)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 120)
		light.Range = 30
		light.Brightness = 1.1
		light.Shadows = false
		light.Enabled = false -- (Client/WorldLights lights the nearest few)
		light.Parent = lamp
		CollectionService:AddTag(light, "WorldLight")
	end
	model.Parent = folder
	return model
end

return ShootingRange
