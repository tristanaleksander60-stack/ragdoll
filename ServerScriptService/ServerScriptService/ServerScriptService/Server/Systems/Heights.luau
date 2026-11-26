--!strict
-- Heights (0.37.9, owner 22 Nov 2026: "build bridges and platforms"; the reviewer: "more verticality:
-- towers, bridges, ramps, stairs and platforms"). In the height area (west, behind the spawn):
--   * (0.37.10: the sky bridge went with the castle) a SLIDE TOP platform off the stair tower's roof;
--   * a SLIDE from that platform down to the grass, towards the plaza;
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
local function bridge(into: Instance, name: string, a: Vector3, b: Vector3, ground: number, pillar: boolean?)
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
	if len > 14 and pillar ~= false then
		local h = mid.Y - ground
		part(into, name .. "Pillar", Vector3.new(1.6, h, 1.6), CFrame.new(mid.X, ground + h / 2 - 0.8, mid.Z), STEEL, Enum.Material.Metal)
	end
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
	-- SLIDE TOP: (0.37.10, owner: "remove the castle", "remove the railing so you can slide down") an open
	-- platform off the stair tower's west side, level with its roof, railed only to the south and west; the
	-- slide starts at its open north edge and runs down to the grass towards the plaza.
	local padCenter = tower + Vector3.new(-7 - 5, 0, 0)
	part(into, "SlideTop", Vector3.new(10, 1, 12), CFrame.new(padCenter - Vector3.new(0, 0.5, 0)), CONCRETE, Enum.Material.Concrete)
	part(into, "SlideTopPillar", Vector3.new(2, Heights.TOP - 1, 2), CFrame.new(padCenter.X, ground + (Heights.TOP - 1) / 2, padCenter.Z), STEEL, Enum.Material.Metal)
	for _, r in { { Vector3.new(0, 1.6, -6), Vector3.new(10, 0.3, 0.3) }, { Vector3.new(-5, 1.6, 0), Vector3.new(0.3, 0.3, 12) } } do
		local rail = part(into, "SlideTopRail", r[2] + Vector3.new(0, 0, 0), CFrame.new(padCenter + r[1] + Vector3.new(0, 1.6, 0)), STEEL, Enum.Material.Metal)
		rail.CastShadow = false
		local posts = part(into, "SlideTopRailBase", Vector3.new(math.max(r[2].X, 0.3), 3.2, math.max(r[2].Z, 0.3)) * Vector3.new(1, 1, 1), CFrame.new(padCenter + r[1]), STEEL, Enum.Material.Metal)
		posts.Transparency = 0.6 -- (a see-through guard under the rail)
		posts.CastShadow = false
	end
	do
		local start = padCenter + Vector3.new(0, -0.15, 6)
		local finish = Vector3.new(padCenter.X + 2, ground + 0.6, padCenter.Z + 56)
		local d = finish - start
		local cf = CFrame.lookAt((start + finish) / 2, finish)
		local slide = part(into, "Slide", Vector3.new(6, 0.6, d.Magnitude), cf, SLIDE, Enum.Material.SmoothPlastic)
		slide.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.1, 100, 1) -- (no grip: bodies slide down)
		slide:SetAttribute("Slide", true)
		for _, side in { -1, 1 } do
			part(into, "SlideWall", Vector3.new(0.5, 1.6, d.Magnitude - 2), cf * CFrame.new(side * 3.25, 0.8, 1), SLIDE:Lerp(Color3.new(1, 1, 1), 0.25))
		end
		-- (a landing pad of soft blue at the bottom)
		part(into, "SlideLanding", Vector3.new(9, 0.4, 9), CFrame.new(finish.X, ground + 0.2, finish.Z + 5), Color3.fromRGB(70, 150, 230), Enum.Material.Fabric)
		local upper = start + d * 0.35
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
	bridge(into, "DeckBridge", plankEnd, Vector3.new(deckCenter.X, top, deckCenter.Z - 5), ground, false) -- (no pillar: the giant trampoline is under it)
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
