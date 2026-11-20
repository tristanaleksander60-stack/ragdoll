--!strict
-- V7-2: draws the paths of Shared/PathPlan (Config.PATHS). Pictures only: nothing collides,
-- nothing is queried, so cars, players and ragdolls move exactly as before.
--   Lab:  round flat "stepping stones" of packed earth that overlap (soft edges, a width that
--         breathes), a hair above the lab floor, with a few pebbles along the edge.
--   Maps: the terrain's grass under the path is repainted (Terrain:ReplaceMaterial: the ground's
--         shape never changes) in the place's own material (PathPlan.TERRAIN), from the arrival to
--         every launcher (MapActivities' Launch parts) and every shop booth.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PathPlan = require(Shared:WaitForChild("PathPlan"))

local PathBuilder = {}

PathBuilder.EARTH = Color3.fromRGB(122, 98, 72)
PathBuilder.PEBBLE = Color3.fromRGB(150, 142, 130)

local function stone(into: Instance, at: Vector3, width: number, color: Color3, material: Enum.Material)
	local p = Instance.new("Part")
	p.Name = "PathStone"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.06, width, width) -- (a Cylinder is round: the width varies stone to stone instead)
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, (at.X * 13 + at.Z) % math.pi, math.rad(90))
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = color
	p.Material = material
	p.Parent = into
end

-- One path of stones from a to b (world x, z) at height y (the garden's cobbled walks use it).
function PathBuilder.trail(into: Instance, a: Vector2, b: Vector2, y: number, color: Color3, material: Enum.Material, seed: number): number
	local n = 0
	for i, s in PathPlan.curve(a, b, seed) do
		stone(into, Vector3.new(s.at.X, y + (i % 4) * 0.004, s.at.Y), s.width, color, material)
		n += 1
	end
	return n
end

-- The lab's paths, into its Playground folder; `floorY` is the top of the lab floor.
function PathBuilder.lab(into: Instance, origin: Vector3, floorY: number): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Paths"
	local stones = PathPlan.lab()
	local count = 0
	for i, s in stones do
		if count >= PathPlan.BUDGET then
			break
		end
		-- (Each stone a hair higher than the last: overlapping stones never flicker.)
		local y = floorY + 0.035 + (i % 4) * 0.004
		stone(folder, Vector3.new(origin.X + s.at.X, y, origin.Z + s.at.Y), s.width, PathBuilder.EARTH, Enum.Material.Ground)
		count += 1
		-- A pebble now and then along the edge.
		if i % 5 == 0 and count < PathPlan.BUDGET then
			local side = if i % 10 == 0 then 1 else -1
			local p = Instance.new("Part")
			p.Name = "PathPebble"
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(0.5, 0.5, 0.5) -- (a Ball is round: one size)
			-- (Beside the path, across its own direction: never on its middle line.)
			local other = stones[i + 1]
			if not other or (other.at - s.at).Magnitude > 6 then
				other = stones[i - 1]
			end
			local along = if other then other.at - s.at else Vector2.new(1, 0)
			local across = if along.Magnitude > 0.01 then Vector2.new(-along.Y, along.X).Unit else Vector2.new(0, 1)
			local edge = s.at + across * side * (s.width / 2 + 0.3)
			p.CFrame = CFrame.new(origin.X + edge.X, floorY + 0.12, origin.Z + edge.Y)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Color = PathBuilder.PEBBLE
			p.Material = Enum.Material.Slate
			p.Parent = folder
			count += 1
		end
	end
	folder:SetAttribute("Stones", count)
	folder.Parent = into
	return folder
end

-- Repaints the terrain under one path (grass, sand or leafy grass become `material`).
local FROM = { Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Sand }
local partsInto: Folder = Instance.new("Folder")
partsInto.Name = "MapPaths"
local function paint(a: Vector3, b: Vector3, material: Enum.Material, seed: number): number
	if not partsInto.Parent then
		partsInto.Parent = Workspace
	end
	local terrain = Workspace.Terrain
	local n = 0
	for _, s in PathPlan.curve(Vector2.new(a.X, a.Z), Vector2.new(b.X, b.Z), seed) do
		-- (The ground's height there: a ray down onto the terrain itself.)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { terrain }
		local hit = Workspace:Raycast(Vector3.new(s.at.X, a.Y + 60, s.at.Y), Vector3.new(0, -160, 0), params)
		if hit then
			local half = s.width / 2
			local region = Region3.new(Vector3.new(s.at.X - half, hit.Position.Y - 3, s.at.Y - half), Vector3.new(s.at.X + half, hit.Position.Y + 1, s.at.Y + half)):ExpandToGrid(4)
			for _, from in FROM do
				pcall(function()
					terrain:ReplaceMaterial(region, 4, from, material)
				end)
			end
			n += 1
		end
		-- (No terrain here (a paved city, the plaza's floor): flat stones on whatever floor it is.)
		if not hit then
			local any = RaycastParams.new()
			any.FilterType = Enum.RaycastFilterType.Exclude
			any.FilterDescendantsInstances = { Workspace:FindFirstChild("Dummies") :: any, Workspace:FindFirstChild("MapBooths") :: any, partsInto :: any }
			local floorHit = Workspace:Raycast(Vector3.new(s.at.X, a.Y + 4, s.at.Y), Vector3.new(0, -40, 0), any) -- (from just above the arrival floor: never a roof or an awning)
			if floorHit and floorHit.Instance:IsA("BasePart") and floorHit.Instance.Size.Y < 30 then
				stone(partsInto, Vector3.new(s.at.X, floorHit.Position.Y + 0.035, s.at.Y), s.width, Color3.fromRGB(150, 146, 138), Enum.Material.Cobblestone)
				n += 1
			end
		end
	end
	return n
end

-- An open-air place: paths from the arrival to each launcher and booth inside `area` (a folder of
-- that map), plus extra goals (booth positions).
function PathBuilder.map(place: string, arrival: Vector3, area: Instance?, goals: { Vector3 }): number
	local name = PathPlan.TERRAIN[place]
	if not name then
		return 0
	end
	local material = (Enum.Material :: any)[name] :: Enum.Material
	local targets: { Vector3 } = table.clone(goals)
	if area then
		for _, d in area:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Launch") ~= nil then
				table.insert(targets, d.Position)
			end
		end
	end
	local total = 0
	for i, t in targets do
		if (t - arrival).Magnitude < 260 then
			total += paint(arrival, t, material, i + #place)
		end
	end
	return total
end

-- After the maps and the shop booths stand: paths from each arrival to every launcher and booth.
function PathBuilder.start(labOrigin: Vector3)
	if not (require(Shared:WaitForChild("Config")) :: any).PATHS then
		return
	end
	local Places = require(Shared:WaitForChild("Places")) :: any
	-- (Warm earth, not grey: the colour of the terrain's path materials.)
	pcall(function()
		Workspace.Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(128, 102, 74))
		Workspace.Terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(104, 86, 66))
	end)
	task.delay(12, function()
		local booths = Workspace:FindFirstChild("MapBooths")
		local function goalsOf(place: string): { Vector3 }
			local out = {}
			local f = booths and booths:FindFirstChild(place)
			for _, b in if f then f:GetChildren() else {} do
				if b:IsA("Model") then
					table.insert(out, b:GetPivot().Position)
				end
			end
			return out
		end
		local places = Workspace:FindFirstChild("Places")
		for id in PathPlan.TERRAIN do
			local ok, err = pcall(function()
				if id == "Plaza" then
					Workspace:SetAttribute("Paths_" .. id, PathBuilder.map(id, labOrigin + Vector3.new(0, 0, 40), nil, goalsOf(id)))
				else
					local def = Places.byId[id]
					local centre = Places.floorCenter(labOrigin, id)
					if def and centre then
						Workspace:SetAttribute("Paths_" .. id, PathBuilder.map(id, centre + Vector3.new(0, 0, def.arrive or 100), places and places:FindFirstChild(id), goalsOf(id)))
					end
				end
			end)
			if not ok then
				warn("[PathBuilder] " .. id .. ": " .. tostring(err))
			end
		end
	end)
end

return PathBuilder
