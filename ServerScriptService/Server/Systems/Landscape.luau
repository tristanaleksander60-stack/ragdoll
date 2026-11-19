--!strict
-- LOOK_V3 (19 Nov 2026, like the big ragdoll games' test grounds): the world around the labs is a
-- green landscape, not a grey slab. The baseplate becomes grass (the labs' concrete floors stay as
-- test pads on it), rolling terrain hills ring the whole play area far off, and low-poly trees
-- (round crowns and pines) stand in the open ground in front of and behind the labs. Built once at
-- start by code; trees and hills are scenery (no collisions on crowns, nothing to hit).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Landscape = {}

Landscape.GRASS = Color3.fromRGB(104, 128, 66)
Landscape.SEED = 1119 -- the same trees on every server
Landscape.TREES = 140
Landscape.FRONT = { 110, 260 } -- tree band in front of the labs (studs from the lab line, +Z)
Landscape.BACK = { -135, -280 } -- and behind them (-Z)
Landscape.HILLS_Z = { 360, -390 } -- the hill rings' distance from the lab line
Landscape.HILL_STEP = 150

local LEAF = { Color3.fromRGB(86, 140, 64), Color3.fromRGB(70, 122, 54), Color3.fromRGB(104, 152, 70) }
local PINE = Color3.fromRGB(48, 98, 60)
local BARK = Color3.fromRGB(104, 76, 54)

local function scenery(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanQuery = collide == true
	p.CanTouch = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function roundTree(parent: Instance, at: Vector3, k: number, rng: Random)
	local h = 7 * k
	scenery(parent, "Trunk", Vector3.new(h, 1.4 * k, 1.4 * k), CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), BARK, Enum.PartType.Cylinder, true)
	local leaf = LEAF[rng:NextInteger(1, #LEAF)]
	local r = 5.5 * k
	scenery(parent, "Crown", Vector3.one * r * 2, CFrame.new(at + Vector3.new(0, h + r * 0.6, 0)), leaf, Enum.PartType.Ball)
	scenery(parent, "Crown", Vector3.one * r * 1.4, CFrame.new(at + Vector3.new(r * 0.7, h + r * 0.2, r * 0.3)), leaf, Enum.PartType.Ball)
	scenery(parent, "Crown", Vector3.one * r * 1.3, CFrame.new(at + Vector3.new(-r * 0.6, h + r * 0.3, -r * 0.4)), leaf, Enum.PartType.Ball)
end

local function pine(parent: Instance, at: Vector3, k: number)
	local h = 5 * k
	scenery(parent, "Trunk", Vector3.new(h, 1.1 * k, 1.1 * k), CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), BARK, Enum.PartType.Cylinder, true)
	for i, r in { 5, 3.8, 2.6 } do
		local y = h + (i - 1) * 3.6 * k + 2 * k
		-- (A squashed ball per tier reads as a pine's layers from afar.)
		scenery(parent, "Needles", Vector3.new(r * 2 * k, 4.2 * k, r * 2 * k), CFrame.new(at + Vector3.new(0, y, 0)), PINE, Enum.PartType.Ball)
	end
end

-- Builds the landscape around the lab line (labOrigin: the plaza's middle at floor height; the labs
-- run along X from it). Safe to call once.
function Landscape.build(labOrigin: Vector3, plotSpacing: number, plotCount: number)
	if not Config.LOOK_V3 then
		return
	end
	local ground = labOrigin.Y - 0.5
	local base = Workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		base.Material = Enum.Material.Grass
		base.Color = Landscape.GRASS
		for _, child in base:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child:Destroy() -- (the concrete tiles the old finish put on it)
			end
		end
		pcall(function()
			(base :: any).MaterialVariant = ""
		end)
	end
	local reach = (math.ceil(plotCount / 2) + 0.5) * plotSpacing
	local folder = Instance.new("Folder")
	folder.Name = "Landscape"
	local rng = Random.new(Landscape.SEED)
	-- Trees in front of and behind the lab line.
	for i = 1, Landscape.TREES do
		local band = if i % 2 == 0 then Landscape.FRONT else Landscape.BACK
		local z = rng:NextNumber(math.min(band[1], band[2]), math.max(band[1], band[2]))
		local x = rng:NextNumber(-reach, reach)
		local at = Vector3.new(labOrigin.X + x, ground, labOrigin.Z + z)
		local k = rng:NextNumber(0.8, 1.35)
		if rng:NextNumber() < 0.45 then
			pine(folder, at, k)
		else
			roundTree(folder, at, k, rng)
		end
	end
	folder.Parent = Workspace
	-- Rolling hills far off (terrain grass), a ring in front, behind and at both ends.
	local terrain = Workspace.Terrain
	local function hill(x: number, z: number, r: number)
		terrain:FillBall(Vector3.new(labOrigin.X + x, ground - r * 0.55, labOrigin.Z + z), r, Enum.Material.Grass)
	end
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Grass, Landscape.GRASS)
	end)
	local x = -reach - 200
	while x <= reach + 200 do
		for _, z in Landscape.HILLS_Z do
			hill(x + rng:NextNumber(-40, 40), z + rng:NextNumber(-40, 40), rng:NextNumber(90, 150))
		end
		x += Landscape.HILL_STEP
	end
	for _, side in { -1, 1 } do
		local z = Landscape.HILLS_Z[2]
		while z <= Landscape.HILLS_Z[1] do
			hill(side * (reach + 260) + rng:NextNumber(-30, 30), z, rng:NextNumber(100, 160))
			z += Landscape.HILL_STEP
		end
	end
end

return Landscape
