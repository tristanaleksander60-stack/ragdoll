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

local S = (require(Shared:WaitForChild("Config")) :: any).LAB_SPREAD or 1 -- (0.37.0: the bigger lab)
LabGarden.CORE_HALF = 80 * S -- where the garden starts: just past the concrete floor (Lab.CORE_HALF 85 less the 6-stud floor margin)
LabGarden.Z_BACK = -92 * S
LabGarden.Z_FRONT = 70 * S
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
	-- (V9-0d: its seats stay put when a sitting player is moved: V3Assets.guardSeat.)
	for _, d in m:GetDescendants() do
		if d:IsA("Seat") then
			(require(script.Parent:WaitForChild("V3Assets")) :: any).guardSeat(d)
		end
	end
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
		-- (V9-0 F2: where the walk's centre really is at a given z: the walk curves gently, and its lamps,
		-- benches, beds and trees follow it so none stands on the paving.)
		local walkPts: { Vector2 }? = nil
		local function walkX(z: number): number
			local pts = walkPts
			if not pts then
				return pathX
			end
			local wz = origin.Z + z
			for i = 1, #pts - 1 do
				local a, b = pts[i], pts[i + 1]
				if (wz - a.Y) * (wz - b.Y) <= 0 and math.abs(b.Y - a.Y) > 0.001 then
					return a.X + (b.X - a.X) * (wz - a.Y) / (b.Y - a.Y) - origin.X
				end
			end
			return pathX
		end
		-- Grass and the path (thin, a hair above the ground so nothing flickers).
		part(folder, "GardenGrass", Vector3.new(width, 0.2, depth), CFrame.new(origin + Vector3.new(xMid, 0.1, zMid)), GRASS, Enum.Material.Grass)
		if (require(Shared:WaitForChild("Config")) :: any).LAB_NO_PATHS then
			-- (0.37.8, owner: no paths in the lab, its garden included)
		elseif (require(Shared:WaitForChild("Config")) :: any).PATHS then
			-- (V7-2: the walk curves gently, its stones overlap: soft edges, no hard rectangle.)
			local PathBuilder = require(script.Parent:WaitForChild("PathBuilder")) :: any
			local o2 = Vector2.new(origin.X, origin.Z)
			-- (21 Nov 2026, Config.LAYOUT_V2: the walk starts by the spider or the plant, never in the open;
			-- its south end meets the yard road; the crossing at -30 ran into the lab's side barriers and goes;
			-- the warm paving of the lab's paths.)
			local v2 = (require(Shared:WaitForChild("Config")) :: any).LAYOUT_V2 == true
			local PathPlan = require(Shared:WaitForChild("PathPlan")) :: any
			local walkColor = if v2 then PathBuilder.PAVING_V3 else PATH
			local northZ = if v2 then PathPlan.GARDEN_WALK_NORTH else LabGarden.Z_BACK + 4
			PathBuilder.trail(folder, o2 + Vector2.new(pathX, northZ), o2 + Vector2.new(pathX, LabGarden.Z_FRONT - 3), origin.Y + 0.34, walkColor, Enum.Material.Cobblestone, if side > 0 then 101 else 102)
			if v2 then
				walkPts = PathBuilder.trailPoints(o2 + Vector2.new(pathX, northZ), o2 + Vector2.new(pathX, LabGarden.Z_FRONT - 3), if side > 0 then 101 else 102)
			end
			for k, z in if v2 then (if side > 0 then { 30 } else {}) else { -30, 30 } do
				PathBuilder.trail(folder, o2 + Vector2.new(side * (inner - 1), z), o2 + Vector2.new(pathX, z), origin.Y + 0.44, walkColor, Enum.Material.Cobblestone, 110 + k + (if side > 0 then 0 else 5))
			end
		else
			part(folder, "GardenPath", Vector3.new(6, 0.24, depth - 6), CFrame.new(origin + Vector3.new(pathX, 0.12, zMid)), PATH, Enum.Material.Cobblestone)
			for _, z in { -30, 30 } do
				local len = math.abs(pathX) - inner + 3
				part(folder, "GardenPath", Vector3.new(len, 0.24, 5), CFrame.new(origin + Vector3.new(side * (inner + len / 2 - 3), 0.12, z)), PATH, Enum.Material.Cobblestone)
			end
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
			-- (V9-0 review: with the wide walks the shed moved to the west walk's outer side, onto this
			-- tree's spot (z Z_BACK + 14): the shed stands there instead.)
			local shedSpot = side < 0 and tz == LabGarden.Z_BACK + 14 and (require(Shared:WaitForChild("Config")) :: any).LAYOUT_V2 == true
			if not shedSpot then
				place(folder, if i % 2 == 0 then "TreePine" else "TreeRound", origin + Vector3.new(side * math.max(half - 13, math.abs(walkX(tz)) + 8.5), 0, tz), (i * 47) % 360, if i % 2 == 0 then 0.55 else 0.75, true)
			end
		end
		-- (V9-0 F2: the walks are wider since 0.30 (Config.LAYOUT_V2): beds, benches, lamps and the shed
		-- step back so nothing stands on the paving.)
		local wideWalk = (require(Shared:WaitForChild("Config")) :: any).LAYOUT_V2 == true
		local bedOff, benchOff, lampOff = if wideWalk then 10.5 else 9, if wideWalk then 7 else 6, if wideWalk then 5.3 else 4.5
		-- Flower beds along the path's inner side, benches and lamps on its outer side.
		-- (20 Nov: the spider and the plant live at z -70, the frog at -5: their beds made room.)
		for _, fz in if side > 0 and not wideWalk then { -45, 10, 50 } else { -45, 50 } do -- (V9-0 review: the fountain at z 16 takes the z 10 bed's place)
			place(folder, "FlowerBed", origin + Vector3.new(walkX(fz) - side * bedOff, 0.2, fz), 0, 0.8)
		end
		for _, bz in { -12, 45 } do
			place(folder, "Bench", origin + Vector3.new(walkX(bz) + side * benchOff, 0.2, bz), if side > 0 then 90 else -90, 1.1, true) -- (V9-0d: the bench with real seats faces -Z: turned to face the walk)
		end
		for _, lz in { -78, -40, 0, 40 } do
			place(folder, "StreetLamp", origin + Vector3.new(walkX(lz) + side * lampOff, 0.2, lz), if side > 0 then 180 else 0, 0.8, true)
		end
		if side > 0 then
			place(folder, "GardenFountain", origin + Vector3.new(side * (inner + 9.5), 0.2, if wideWalk then 16 else 24), 0, 0.9, true) -- (V9-0: clear of the crossing at z 30)
		else
			place(folder, "GardenShed", origin + Vector3.new(if wideWalk then pathX + side * 11 else pathX - 4, 0.2, LabGarden.Z_BACK + 14), 90, 1.1, true)
		end
		place(folder, "Rock", origin + Vector3.new(side * (half - 20), 0, LabGarden.Z_FRONT - 18), 30, 0.35, true)
	end
	-- (The walks' kerbs, laid last: they open where a crossing meets the long walk. V9-0 review: with
	-- LAYOUT_V2 the lab's paths come next and lay both folders' kerbs in one pass: PathBuilder.lab.)
	local cfg = require(Shared:WaitForChild("Config")) :: any
	if cfg.PATHS and not cfg.LAYOUT_V2 then
		(require(script.Parent:WaitForChild("PathBuilder")) :: any).finishKerbs(folder)
	end
	return folder
end

return LabGarden
