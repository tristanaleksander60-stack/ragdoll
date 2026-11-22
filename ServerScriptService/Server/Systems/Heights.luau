--!strict
-- Heights (0.37.9, owner 22 Nov 2026: "build bridges and platforms"; the reviewer: "more verticality:
-- towers, bridges, ramps, stairs and platforms"). In the height area (west, behind the spawn):
--   * a SKY BRIDGE from the top of the stair tower across to the top of the throw tower;
--   * a SLIDE from the middle of that bridge down to the grass, towards the plaza;
--   * a SKY DECK beside the stair tower, joined to its diving plank by a short bridge;
--   * six JUMP STEPS climbing from the grass up to the sky deck.
-- All anchored, solid parts in the lab's folder; nothing here moves or runs. Positions follow the stair
-- tower (Playground.buildTower: x -52, z0 -8, 20 steps of 1.5 x 2.5, the tower 6 past them, top 30) and the
-- throw tower (LabDress.TOWER), both times Config.LAB_SPREAD, so the pieces stay joined if the lab grows.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local Heights = {}

Heights.TOP = 30 -- studs: the stair tower's top
Heights.DECK_W = 6 -- studs: a bridge's walking width
Heights.STEP_RISE = 4.5 -- studs between two jump steps (a jump is about 7)

local WOOD = Color3.fromRGB(176, 128, 82)
local STEEL = Color3.fromRGB(70, 74, 82)
local YELLOW = Color3.fromRGB(240, 196, 40)
local SLIDE = Color3.fromRGB(240, 120, 40)
local CONCRETE = Color3.fromRGB(196, 198, 202)

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

-- A walkable span from a to b (both on the deck's top): planks, two rails on posts, and a steel pillar
-- under its middle when it is long.
local function bridge(into: Instance, name: string, a: Vector3, b: Vector3, ground: number)
	local d = b - a
	local len = d.Magnitude
	if len < 1 then
		return
	end
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b) -- (along the span; tilted if the ends differ in height)
	local w = Heights.DECK_W
	part(into, name .. "Deck", Vector3.new(w, 0.8, len), cf * CFrame.new(0, -0.4, 0), WOOD, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		part(into, name .. "Edge", Vector3.new(0.3, 0.25, len), cf * CFrame.new(side * (w / 2 - 0.15), 0.12, 0), YELLOW)
		local rail = part(into, name .. "Rail", Vector3.new(0.3, 0.3, len), cf * CFrame.new(side * (w / 2), 3.2, 0), STEEL, Enum.Material.Metal)
		rail.CastShadow = false
		local posts = math.max(2, math.floor(len / 4) + 1)
		for i = 0, posts - 1 do
			local z = -len / 2 + len * i / (posts - 1)
			local post = part(into, name .. "Post", Vector3.new(0.35, 3.2, 0.35), cf * CFrame.new(side * (w / 2), 1.6, z), STEEL, Enum.Material.Metal)
			post.CastShadow = false
		end
	end
	if len > 14 then
		local h = mid.Y - ground
		part(into, name .. "Pillar", Vector3.new(1.6, h, 1.6), CFrame.new(mid.X, ground + h / 2 - 0.8, mid.Z), STEEL, Enum.Material.Metal)
	end
end

-- The throw tower's top at its middle (a ray down onto the model), or nil.
local function throwTowerTop(folder: Instance, at: Vector3): Vector3?
	local tower = folder:FindFirstChild("ThrowTower", true)
	if not tower then
		return nil
	end
	local only = RaycastParams.new()
	only.FilterType = Enum.RaycastFilterType.Include
	only.FilterDescendantsInstances = { tower }
	local hit = Workspace:Raycast(Vector3.new(at.X, at.Y + 120, at.Z), Vector3.new(0, -160, 0), only)
	return if hit then hit.Position else nil
end

function Heights.build(folder: Instance, origin: Vector3)
	if Config.HEIGHTS == false then -- (on unless switched off)
		return
	end
	local S = Config.LAB_SPREAD or 1
	local into = Instance.new("Folder")
	into.Name = "Heights"
	local ground = origin.Y
	local top = ground + Heights.TOP
	-- The stair tower (Playground.buildTower) and its diving plank.
	local towerX = -52 * S
	local towerZ = -8 * S - 20 * 2.5 - 6
	local tower = origin + Vector3.new(towerX, Heights.TOP, towerZ)
	-- SKY BRIDGE: from the stair tower's west edge to just short of the throw tower's top.
	local throwXZ = origin + Vector3.new(-70 * S, 0, -28 * S)
	local throwTop = throwTowerTop(folder, throwXZ + Vector3.new(0, 40, 0))
	local bridgeMid: Vector3? = nil
	if throwTop then
		local from = tower + Vector3.new(-7, 0, 0)
		local flatDir = Vector3.new(throwTop.X - from.X, 0, throwTop.Z - from.Z)
		local to = Vector3.new(throwTop.X, throwTop.Y, throwTop.Z) - flatDir.Unit * 5 -- (stops at the tower's rim)
		bridge(into, "SkyBridge", from, to, ground)
		bridgeMid = (from + to) / 2
	end
	-- SLIDE: from the bridge's middle down to the grass, towards the plaza (north, a little east).
	if bridgeMid then
		local m = bridgeMid :: Vector3
		local start = m + Vector3.new(0, -0.1, 3.2)
		local finish = Vector3.new(m.X + 5, ground + 0.6, m.Z + 48)
		local d = finish - start
		local cf = CFrame.lookAt((start + finish) / 2, finish)
		local slide = part(into, "Slide", Vector3.new(5, 0.6, d.Magnitude), cf, SLIDE, Enum.Material.SmoothPlastic)
		slide.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.1, 100, 1) -- (no grip: bodies slide down)
		slide:SetAttribute("Slide", true)
		for _, side in { -1, 1 } do
			part(into, "SlideWall", Vector3.new(0.5, 1.6, d.Magnitude), cf * CFrame.new(side * 2.75, 0.8, 0), SLIDE:Lerp(Color3.new(1, 1, 1), 0.25))
		end
		-- (a landing pad of soft blue at the bottom)
		part(into, "SlideLanding", Vector3.new(8, 0.4, 8), CFrame.new(finish.X, ground + 0.2, finish.Z + 5), Color3.fromRGB(70, 150, 230), Enum.Material.Fabric)
		-- (a support under its upper half)
		local upper = start + d * 0.3
		local h = upper.Y - ground
		part(into, "SlidePillar", Vector3.new(1.2, h, 1.2), CFrame.new(upper.X, ground + h / 2 - 0.6, upper.Z), STEEL, Enum.Material.Metal)
	end
	-- SKY DECK: a platform beside the stair tower, joined to the end of its diving plank.
	local deckCenter = origin + Vector3.new(-48 * S + 14.4, Heights.TOP, -36 * S)
	part(into, "SkyDeck", Vector3.new(10, 1, 10), CFrame.new(deckCenter - Vector3.new(0, 0.5, 0)), CONCRETE, Enum.Material.Concrete)
	part(into, "SkyDeckEdge", Vector3.new(10.3, 0.3, 10.3), CFrame.new(deckCenter + Vector3.new(0, 0.05, 0)), YELLOW)
	part(into, "SkyDeckPillar", Vector3.new(2, Heights.TOP - 1, 2), CFrame.new(deckCenter.X, ground + (Heights.TOP - 1) / 2, deckCenter.Z), STEEL, Enum.Material.Metal)
	-- (the plank runs east from the tower, 14 long, its far end at towerX + 21)
	local plankEnd = Vector3.new(origin.X + towerX + 18, top + 1, origin.Z + towerZ + 2)
	bridge(into, "DeckBridge", plankEnd, Vector3.new(deckCenter.X, top, deckCenter.Z - 5), ground)
	-- JUMP STEPS: six blocks up from the grass to the sky deck's north edge, zigzagging.
	for i = 0, 5 do
		local h = Heights.STEP_RISE * (i + 1)
		local x = deckCenter.X + (if i % 2 == 0 then -4 else 4)
		local z = deckCenter.Z + 7 + (5 - i) * 4.6
		local step = part(into, "JumpStep", Vector3.new(5, 1, 5), CFrame.new(x, ground + h - 0.5, z), CONCRETE, Enum.Material.Concrete)
		step:SetAttribute("Step", i + 1)
		part(into, "JumpStepEdge", Vector3.new(5.2, 0.25, 5.2), CFrame.new(x, ground + h + 0.05, z), YELLOW)
		local post = part(into, "JumpStepPost", Vector3.new(0.8, h - 1, 0.8), CFrame.new(x, ground + (h - 1) / 2, z), STEEL, Enum.Material.Metal)
		post.CastShadow = false
	end
	into.Parent = folder
end

return Heights
