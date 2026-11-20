--!strict
-- V6-4: the bigger lab's garden (Config.LAB_V6). The plots are wider (Zones.PLOT_SPACING), so each
-- lab has a strip on both sides of its concrete core. This fills them with a calm, cosy garden made
-- from real models (ServerStorage.V3Assets, malware pass done on insert):
--   grass, a stone path down each strip with two crossings into the lab, flower beds along it,
--   round and pine trees, benches looking at the lab, warm street lamps, a stone fountain (east)
--   and a shed (west), and a tall hedge on the plot's edge (with the client's PlotPrivacy, nobody
--   sees into the next lab). Everything anchored; the small things never collide.
-- Called from Playground.build for labs (not the plaza). Coordinates are from the lab's origin.

local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Zones = require(Shared:WaitForChild("Zones"))

local LabGarden = {}

LabGarden.CORE_HALF = 80 -- where the garden starts: just past the concrete floor (Lab.CORE_HALF 85 less the 6-stud floor margin)
LabGarden.Z_BACK = -92
LabGarden.Z_FRONT = 70
LabGarden.HEDGE_HEIGHT = 14
LabGarden.LAMP_COLOR = Color3.fromRGB(255, 196, 130)

local GRASS = Color3.fromRGB(86, 124, 64)
local PATH = Color3.fromRGB(150, 146, 138)

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = collide == true
	p.CanQuery = collide == true
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = into
	return p
end

-- A copy of a V3Assets model, scaled, turned, its lowest point on the ground at `at`.
local function place(into: Instance, name: string, at: Vector3, yaw: number, scale: number?, collide: boolean?): Model?
	local assets = ServerStorage:FindFirstChild("V3Assets")
	local src = assets and assets:FindFirstChild(name)
	if not src or not src:IsA("Model") then
		return nil
	end
	local m = src:Clone()
	if scale and scale ~= 1 then
		m:ScaleTo(m:GetScale() * scale)
	end
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0))
	local cf, size = m:GetBoundingBox()
	local bottom = cf.Position.Y - size.Y / 2
	m:PivotTo(m:GetPivot() + Vector3.new(0, at.Y - bottom, 0))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			if collide ~= true then
				d.CanCollide = false
				d.CanQuery = false
			end
		elseif d:IsA("Light") then
			d.Color = LabGarden.LAMP_COLOR
			if d:IsA("PointLight") or d:IsA("SpotLight") then
				d.Range = math.min(d.Range, 24)
				d.Brightness = math.min(d.Brightness, 1.6)
			end
			d.Shadows = false
		end
	end
	m.Parent = into
	return m
end

function LabGarden.build(into: Instance, origin: Vector3): Folder?
	local half = Zones.PLOT_HALF
	if half <= LabGarden.CORE_HALF + 20 then
		return nil -- (the old narrow plots: no room for a garden)
	end
	local folder = Instance.new("Folder")
	folder.Name = "Garden"
	folder.Parent = into
	local inner, outer = LabGarden.CORE_HALF, half - 1
	local width = outer - inner
	local depth = LabGarden.Z_FRONT - LabGarden.Z_BACK
	local zMid = (LabGarden.Z_FRONT + LabGarden.Z_BACK) / 2
	for _, side in { 1, -1 } do
		local xMid = side * (inner + outer) / 2
		local pathX = side * (inner + width * 0.45)
		-- Grass and the path (thin, a hair above the ground so nothing flickers).
		part(folder, "GardenGrass", Vector3.new(width, 0.2, depth), CFrame.new(origin + Vector3.new(xMid, 0.1, zMid)), GRASS, Enum.Material.Grass)
		part(folder, "GardenPath", Vector3.new(6, 0.24, depth - 6), CFrame.new(origin + Vector3.new(pathX, 0.12, zMid)), PATH, Enum.Material.Cobblestone)
		for _, z in { -30, 30 } do
			local len = math.abs(pathX) - inner + 3
			part(folder, "GardenPath", Vector3.new(len, 0.24, 5), CFrame.new(origin + Vector3.new(side * (inner + len / 2 - 3), 0.12, z)), PATH, Enum.Material.Cobblestone)
		end
		-- The hedge on the plot's edge (tall: the neighbour's lab stays out of view).
		local hedgeX = side * (half - 3)
		local z = LabGarden.Z_BACK + 32 -- (each piece is about 65 studs long once scaled)
		while z < LabGarden.Z_FRONT do
			place(folder, "Hedge", origin + Vector3.new(hedgeX, 0, z), 0, LabGarden.HEDGE_HEIGHT / 8, true)
			z += 60
		end
		-- (V6-5: the hedge goes on along the creature yard in front of the lab.)
		if (require(Shared:WaitForChild("Config")) :: any).LAB_CREATURES then
			place(folder, "Hedge", origin + Vector3.new(hedgeX, 0, 92), 0, LabGarden.HEDGE_HEIGHT / 8, true)
		end
		-- Trees along the hedge, round and pine by turns.
		local i = 0
		for tz = LabGarden.Z_BACK + 14, LabGarden.Z_FRONT - 8, 26 do
			i += 1
			place(folder, if i % 2 == 0 then "TreePine" else "TreeRound", origin + Vector3.new(side * (half - 13), 0, tz), (i * 47) % 360, if i % 2 == 0 then 0.55 else 0.75, true)
		end
		-- Flower beds along the path's inner side, benches and lamps on its outer side.
		for _, fz in { -70, -45, 10, 50 } do
			place(folder, "FlowerBed", origin + Vector3.new(pathX - side * 9, 0.2, fz), 0, 0.8)
		end
		for _, bz in { -12, 45 } do
			place(folder, "Bench", origin + Vector3.new(pathX + side * 6, 0.2, bz), if side > 0 then -90 else 90, 1.1, true)
		end
		for _, lz in { -78, -40, 0, 40 } do
			place(folder, "StreetLamp", origin + Vector3.new(pathX + side * 4.5, 0.2, lz), if side > 0 then 180 else 0, 0.8, true)
		end
		if side > 0 then
			place(folder, "GardenFountain", origin + Vector3.new(side * (inner + 9.5), 0.2, 24), 0, 0.9, true)
		else
			place(folder, "GardenShed", origin + Vector3.new(pathX - 4, 0.2, LabGarden.Z_BACK + 14), 90, 1.1, true)
		end
		place(folder, "Rock", origin + Vector3.new(side * (half - 20), 0, LabGarden.Z_FRONT - 18), 30, 0.35, true)
	end
	return folder
end

return LabGarden
