--!strict
-- 20 Nov 2026 (the owner: "give the monsters their own little area where it makes sense, e.g. the
-- spider by a giant web"): each creature in the lab's yard gets a small home of its own around its
-- machine (LabCreatures builds the machine and its trigger; this only dresses the spot):
--   Spider     a dark corner: two dead trees holding the giant web, mossy ground, rocks, old cocoons
--   Plant      a round brick planter of dark soil with flowers round its foot
--   Chicken    a fenced run on straw with a little hen house
--   Frog       a pond with a stone rim, lily pads and reeds
--   Vacuum     a living-room rug with its charging dock
--   Slingshot  a tidy lawn with a rope line in front of the trees
--   Mole       a vegetable patch: soil rows with greens
--   Washer     a laundry corner: tiles, a washing line with clothes, a basket
--   Whale      sand round its pool, rocks and a palm
-- Pictures only: anchored, no collision, no queries, no touches (the machines' triggers and the
-- bodies' physics are untouched). Kid-safe, calm colours.

local ServerStorage = game:GetService("ServerStorage")

local CreatureHabitats = {}

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

-- A flat round patch on the ground (a cylinder lying down), `h` thick, its top at `top` above `at`.
local function disc(into: Instance, name: string, diameter: number, h: number, at: CFrame, top: number, color: Color3, material: Enum.Material): Part
	return part(into, name, Vector3.new(h, diameter, diameter), at * CFrame.new(0, top - h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

-- A copy of a V3Assets model, its longest side `size`, turned, its lowest point on the ground.
local function prop(into: Instance, name: string, at: CFrame, yaw: number, size: number): Model?
	local assets = ServerStorage:FindFirstChild("V3Assets")
	local src = assets and assets:FindFirstChild(name)
	if not src or not src:IsA("Model") then
		return nil
	end
	local m = src:Clone()
	local _, s0 = m:GetBoundingBox()
	local longest = math.max(s0.X, s0.Y, s0.Z)
	if longest > 0 then
		m:ScaleTo(m:GetScale() * size / longest)
	end
	m:PivotTo(CFrame.new(at.Position) * CFrame.Angles(0, math.rad(yaw), 0))
	local cf, s = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, at.Position.Y - (cf.Position.Y - s.Y / 2), 0))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		elseif d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		end
	end
	-- (V9-0 F2, owner 21 Nov 2026: nothing stands on a path: a prop over the lab's paving is left out.)
	local lab: Instance? = into
	while lab and lab.Parent and lab.Parent.Name ~= "Playground" do
		lab = lab.Parent
	end
	if lab then
		local PathBuilder = require(script.Parent:WaitForChild("PathBuilder")) :: any
		local bcf, bsize = m:GetBoundingBox()
		if PathBuilder.overPaving(PathBuilder.pavingIn(lab), bcf, bsize, 0.2) then
			m:Destroy()
			return nil
		end
	end
	m.Parent = into
	return m
end

local GRASS_DARK = Color3.fromRGB(58, 84, 46)
local BARK = Color3.fromRGB(70, 56, 44)
local SOIL = Color3.fromRGB(86, 64, 46)
local STRAW = Color3.fromRGB(214, 186, 118)
local WATER = Color3.fromRGB(62, 118, 128)

local DRESS: { [string]: (Folder, CFrame) -> () } = {}

DRESS.Spider = function(f, at)
	disc(f, "Habitat_Moss", 19, 0.2, at, 0.24, GRASS_DARK, Enum.Material.LeafyGrass)
	-- Two dead trees: bare trunks leaning a little, a broken branch each, holding the web's corners.
	for _, side in { -1, 1 } do
		local base = at * CFrame.new(side * 14.5, 0, 0)
		part(f, "Habitat_DeadTrunk", Vector3.new(1.6, 30, 1.6), base * CFrame.new(0, 15, 0) * CFrame.Angles(0, 0, math.rad(-side * 4)), BARK, Enum.Material.Wood)
		part(f, "Habitat_DeadBranch", Vector3.new(7, 0.8, 0.8), base * CFrame.new(-side * 2.5, 22, 0) * CFrame.Angles(0, 0, math.rad(side * 35)), BARK, Enum.Material.Wood)
		part(f, "Habitat_DeadBranch", Vector3.new(5, 0.6, 0.6), base * CFrame.new(side * 2, 26, 0.3) * CFrame.Angles(0, 0, math.rad(-side * 40)), BARK, Enum.Material.Wood)
		prop(f, "Rock", base * CFrame.new(side * 3, 0, 4), side * 40, 4)
	end
	-- Old silk parcels hanging from the branches (empty: nothing was eaten for real).
	for i, x in { -9, 9 } do
		local hang = at * CFrame.new(x, 18 - i, 1.5)
		part(f, "Habitat_SilkThread", Vector3.new(0.08, 4, 0.08), hang * CFrame.new(0, 2, 0), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
		part(f, "Habitat_OldCocoon", Vector3.new(1.4, 2.4, 1.4), hang, Color3.fromRGB(232, 230, 222), Enum.Material.Fabric, Enum.PartType.Ball)
	end
	prop(f, "Bush", at * CFrame.new(-8, 0, 7), 10, 6)
	prop(f, "Bush", at * CFrame.new(9, 0, 6), 80, 5)
end

DRESS.Plant = function(f, at)
	-- A round planter: a brick ring, dark soil inside, flowers at its foot.
	disc(f, "Habitat_PlanterWall", 15, 1.4, at, 1.4, Color3.fromRGB(150, 84, 64), Enum.Material.Brick)
	disc(f, "Habitat_PlanterSoil", 13.4, 0.2, at, 1.45, SOIL, Enum.Material.Ground)
	for i = 0, 5 do
		local a = i * math.pi / 3 + 0.4
		prop(f, "Bush", at * CFrame.new(math.cos(a) * 8.5, 0, math.sin(a) * 8.5), i * 50, 3.2)
	end
end

DRESS.Chicken = function(f, at)
	disc(f, "Habitat_Straw", 20, 0.2, at * CFrame.new(0, 0, -2), 0.24, STRAW, Enum.Material.Sand)
	-- A low wooden run on three sides (the front stays open toward the lab).
	for _, spec in { { 0, -12, 0 }, { -11, -2, 90 }, { 11, -2, 90 } } do
		local post = at * CFrame.new(spec[1], 0, spec[2]) * CFrame.Angles(0, math.rad(spec[3]), 0)
		for k = -1, 1, 2 do
			part(f, "Habitat_FencePost", Vector3.new(0.6, 3.6, 0.6), post * CFrame.new(k * 9.5, 1.8, 0), Color3.fromRGB(150, 116, 78), Enum.Material.Wood)
		end
		part(f, "Habitat_FenceRail", Vector3.new(20, 0.4, 0.3), post * CFrame.new(0, 3, 0), Color3.fromRGB(176, 138, 92), Enum.Material.Wood)
		part(f, "Habitat_FenceRail", Vector3.new(20, 0.4, 0.3), post * CFrame.new(0, 1.6, 0), Color3.fromRGB(176, 138, 92), Enum.Material.Wood)
	end
	prop(f, "GardenShed", at * CFrame.new(-5, 0, -8.5), 180, 11)
	prop(f, "Barrel", at * CFrame.new(8, 0, -9), 0, 2.6)
end

DRESS.Frog = function(f, at)
	-- The pond under the frog: a stone rim of rocks, lily pads, reeds at the back.
	disc(f, "Habitat_PondBed", 21, 0.2, at, 0.12, Color3.fromRGB(48, 70, 60), Enum.Material.Mud)
	local water = disc(f, "Habitat_Water", 18, 0.1, at, 0.36, WATER, Enum.Material.Glass)
	water.Transparency = 0.15
	for i = 0, 9 do
		local a = i * math.pi / 5
		prop(f, "Rock", at * CFrame.new(math.cos(a) * 10, 0, math.sin(a) * 10), i * 37, 2.2 + (i % 3) * 0.6)
	end
	for i, spot in { Vector3.new(-5.5, 0, 3), Vector3.new(5, 0, 4.5), Vector3.new(6, 0, -2.5), Vector3.new(-4, 0, -5.5), Vector3.new(0.5, 0, 6.5) } do
		disc(f, "Habitat_LilyPad", 2.6 + (i % 2) * 0.8, 0.08, at * CFrame.new(spot), 0.44, Color3.fromRGB(78, 140, 64), Enum.Material.SmoothPlastic)
	end
	for i = 0, 6 do
		local x = -6 + i * 2
		part(f, "Habitat_Reed", Vector3.new(0.18, 3 + (i % 3), 0.18), at * CFrame.new(x, 1.5 + (i % 3) / 2, -9.5) * CFrame.Angles(0, 0, math.rad((i % 2) * 8 - 4)), Color3.fromRGB(86, 110, 52), Enum.Material.Grass)
	end
end

DRESS.Vacuum = function(f, at)
	-- The robot's living-room corner: a soft rug under its round, and its charging dock.
	local rug = part(f, "Habitat_Rug", Vector3.new(52, 0.08, 22), at * CFrame.new(0, 0.2, 0), -- (V9-0: under the yard road, never level with it: no flicker)
		 Color3.fromRGB(150, 130, 108), Enum.Material.Fabric)
	part(f, "Habitat_RugBorder", Vector3.new(54, 0.06, 24), rug.CFrame * CFrame.new(0, -0.02, 0), Color3.fromRGB(96, 80, 66), Enum.Material.Fabric)
	local dock = at * CFrame.new(0, 0, 12.5)
	part(f, "Habitat_Dock", Vector3.new(3, 1.6, 1.2), dock * CFrame.new(0, 0.8, 0), Color3.fromRGB(40, 42, 48), Enum.Material.SmoothPlastic)
	part(f, "Habitat_DockLight", Vector3.new(0.6, 0.3, 0.1), dock * CFrame.new(0, 1.2, -0.62), Color3.fromRGB(90, 230, 120), Enum.Material.Neon)
end

DRESS.Slingshot = function(f, at)
	disc(f, "Habitat_Lawn", 22, 0.2, at, 0.26, Color3.fromRGB(96, 142, 70), Enum.Material.Grass)
	-- A rope line on short posts in front: where to stand to watch the shot.
	for _, x in { -8, -4, 0, 4, 8 } do
		part(f, "Habitat_RopePost", Vector3.new(0.4, 2.4, 0.4), at * CFrame.new(x, 1.2, -9), Color3.fromRGB(180, 150, 100), Enum.Material.Wood)
	end
	part(f, "Habitat_Rope", Vector3.new(16, 0.15, 0.15), at * CFrame.new(0, 2, -9), Color3.fromRGB(196, 60, 52), Enum.Material.Fabric)
end

DRESS.Mole = function(f, at)
	-- A vegetable patch: soil rows with greens on the far side of its dirt.
	for i = -1, 1 do
		local row = at * CFrame.new(i * 5, 0, 13)
		part(f, "Habitat_SoilRow", Vector3.new(3, 0.5, 9), row * CFrame.new(0, 0.25, 0), SOIL, Enum.Material.Ground)
		for k = -1, 1 do
			prop(f, "Bush", row * CFrame.new(0, 0.5, k * 3), (i + k) * 60, 1.6)
		end
	end
	prop(f, "Crate", at * CFrame.new(11, 0, 8), 20, 2.2)
	prop(f, "Crate", at * CFrame.new(12, 0, 10.5), 70, 2)
end

DRESS.Washer = function(f, at)
	-- A laundry corner: white tiles, a washing line with clothes, a basket.
	part(f, "Habitat_Tiles", Vector3.new(16, 0.1, 14), at * CFrame.new(0, 0.28, 2), Color3.fromRGB(226, 228, 230), Enum.Material.Marble)
	local a, b = at * CFrame.new(-9, 0, 8), at * CFrame.new(9, 0, 8)
	for _, p in { a, b } do
		part(f, "Habitat_LinePost", Vector3.new(0.5, 7, 0.5), p * CFrame.new(0, 3.5, 0), Color3.fromRGB(200, 200, 204), Enum.Material.Metal)
	end
	part(f, "Habitat_Line", Vector3.new(18, 0.06, 0.06), at * CFrame.new(0, 6.6, 8), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
	for i, c in { Color3.fromRGB(230, 90, 80), Color3.fromRGB(90, 150, 220), Color3.fromRGB(250, 210, 90), Color3.fromRGB(120, 200, 140) } do
		part(f, "Habitat_Cloth", Vector3.new(2.4, 3, 0.06), at * CFrame.new(-6 + i * 3, 5.1, 8), c, Enum.Material.Fabric)
	end
	prop(f, "Barrel", at * CFrame.new(6.5, 0.3, -3), 0, 2.4)
end

DRESS.Whale = function(f, at)
	part(f, "Habitat_Sand", Vector3.new(40, 0.16, 30), at * CFrame.new(0, 0.2, 0), Color3.fromRGB(222, 204, 160), Enum.Material.Sand)
	for i, spot in { Vector3.new(-18, 0, -12), Vector3.new(17, 0, -11), Vector3.new(-17, 0, 12), Vector3.new(18, 0, 11) } do
		prop(f, "Rock", at * CFrame.new(spot), i * 70, 3 + (i % 2))
	end
	prop(f, "TreePalm", at * CFrame.new(16, 0, 13), 30, 18)
end

-- Dresses one creature's spot (`at` = its machine's CFrame in the yard).
function CreatureHabitats.dress(id: string, into: Folder, at: CFrame)
	local fn = DRESS[id]
	if not fn then
		return
	end
	local home = Instance.new("Folder")
	home.Name = "Habitat"
	home.Parent = into
	fn(home, at)
end

CreatureHabitats.KINDS = table.freeze({ "Spider", "Plant", "Chicken", "Frog", "Vacuum", "Slingshot", "Mole", "Washer", "Whale" })

return CreatureHabitats
