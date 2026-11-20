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
function PathBuilder.trailStones(into: Instance, a: Vector2, b: Vector2, y: number, color: Color3, material: Enum.Material, seed: number): number
	local n = 0
	for i, s in PathPlan.curve(a, b, seed) do
		stone(into, Vector3.new(s.at.X, y + (i % 4) * 0.004, s.at.Y), s.width, color, material)
		n += 1
	end
	return n
end

-- The lab's paths, into its Playground folder; `floorY` is the top of the lab floor.
function PathBuilder.labStones(into: Instance, origin: Vector3, floorY: number): Folder
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

-- 20 Nov 2026 (the owner: "fix the paths"; the overlapping discs read as spilt mud): a real
-- walkway. Straight slabs from point to point along the curve, a round disc at every joint (no notch
-- on a bend), and a darker kerb a hair wider underneath: a gravel path with a stone edge in the lab,
-- cobbles in the garden. Pictures only, like before.
-- 20 Nov, round 2 (the owner: "improve the paths markedly"): a built path. Raised paving (cobbles
-- in a warm stone) between two raised stone kerbs, and a wooden signpost at every fork.
PathBuilder.WALK_WIDTH = 4.2
PathBuilder.GRAVEL = Color3.fromRGB(176, 160, 136) -- (the paving's stone)
PathBuilder.KERB = Color3.fromRGB(112, 108, 102)
PathBuilder.KERB_W = 0.45
PathBuilder.KERB_H = 0.34
PathBuilder.PAVE_H = 0.16
PathBuilder.EVERY = 3 -- (one corner every this many plan points: about 7 studs, still a smooth curve)

local function flatPart(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, round: boolean)
	local p = Instance.new("Part")
	p.Name = name
	if round then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
end

-- Walkways drawn into a folder whose kerbs are still to be laid (PathBuilder.finishKerbs).
type Kerb = { cf: CFrame, size: Vector3, color: Color3, line: number, samples: { Vector2 } }
local pending: { [Instance]: { lines: { { points: { Vector2 }, width: number } }, kerbs: { Kerb } } } = {}

-- A walkway through the points (world x, z), its floor at height y: raised paving slabs from
-- point to point, a round paving disc at every joint (no notch on a bend), and a raised stone kerb
-- along both edges (a hair longer than its slab, so the kerb runs on round a gentle bend).
function PathBuilder.walkway(into: Instance, points: { Vector2 }, y: number, width: number, color: Color3, material: Enum.Material, kerb: Color3?): number
	local n = 0
	local flat = CFrame.Angles(0, 0, math.rad(90))
	local h = PathBuilder.PAVE_H
	local state = pending[into] or { lines = {}, kerbs = {} }
	pending[into] = state
	table.insert(state.lines, { points = points, width = width })
	local lineIndex = #state.lines
	for i, a in points do
		flatPart(into, "PathJoint", Vector3.new(h - 0.004, width, width), CFrame.new(a.X, y + h / 2 - 0.002, a.Y) * flat, color, material, true)
		n += 1
		local b = points[i + 1]
		if b and (b - a).Magnitude > 0.05 then
			local mid = (a + b) / 2
			local cf = CFrame.lookAt(Vector3.new(mid.X, y + h / 2, mid.Y), Vector3.new(b.X, y + h / 2, b.Y))
			local len = (b - a).Magnitude
			flatPart(into, "PathSlab", Vector3.new(width, h, len), cf, color, material, false)
			n += 1
			if kerb then
				-- (Kept for finishKerbs: a kerb piece is only laid where no other path crosses it,
				-- so the kerbs open where two paths meet instead of running across one another.)
				local kh = PathBuilder.KERB_H
				local dir = (b - a).Unit
				local across = Vector2.new(-dir.Y, dir.X)
				for _, side in { -1, 1 } do
					local at = cf * CFrame.new(side * (width / 2 + PathBuilder.KERB_W / 2), kh / 2 - h / 2, 0)
					local c2 = mid + across * (-side) * (width / 2 + PathBuilder.KERB_W / 2)
					table.insert(state.kerbs, {
						cf = at,
						size = Vector3.new(PathBuilder.KERB_W, kh, len + 0.5),
						color = kerb,
						line = lineIndex,
						samples = { c2, c2 - dir * (len / 2), c2 + dir * (len / 2) },
					})
				end
			end
		end
	end
	return n
end

-- Distance from a point to a line through points (2D).
local function toLine(p: Vector2, pts: { Vector2 }): number
	local best = math.huge
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local ab = b - a
		local t = if ab.Magnitude > 0.001 then math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1) else 0
		best = math.min(best, (p - (a + ab * t)).Magnitude)
	end
	if #pts == 1 then
		best = (p - pts[1]).Magnitude
	end
	return best
end

-- Lays the kerbs of every walkway drawn into `into` so far, leaving out the pieces that would lie
-- inside another walkway (the junctions). Returns how many it laid.
function PathBuilder.finishKerbs(into: Instance): number
	local state = pending[into]
	if not state then
		return 0
	end
	pending[into] = nil
	local n = 0
	for _, k in state.kerbs do
		local inside = false
		for li, line in state.lines do
			if li ~= k.line then
				for _, s in k.samples do
					if toLine(s, line.points) < line.width / 2 + 0.1 then
						inside = true
						break
					end
				end
			end
			if inside then
				break
			end
		end
		if not inside then
			flatPart(into, "PathKerb", k.size, k.cf, k.color, Enum.Material.Slate, false)
			n += 1
		end
	end
	return n
end

-- A wooden signpost at a fork: a post with one arrow board per way out, each pointing along its
-- path with the place's name on both faces (fixed words, PathPlan.LABELS).
PathBuilder.WOOD = Color3.fromRGB(150, 108, 70)
PathBuilder.BOARD = Color3.fromRGB(196, 156, 104)
function PathBuilder.signpost(into: Instance, at: Vector3, ways: { { dir: Vector2, label: string } }): number
	local post = Instance.new("Part")
	post.Name = "PathSignPost"
	post.Size = Vector3.new(0.5, 6.6, 0.5)
	post.CFrame = CFrame.new(at + Vector3.new(0, 3.3, 0))
	post.Anchored = true
	post.CanCollide = false
	post.CanQuery = false
	post.CanTouch = false
	post.Color = PathBuilder.WOOD
	post.Material = Enum.Material.Wood
	post.Parent = into
	local n = 1
	for k, way in ways do
		if k > 4 then
			break
		end
		local dir = if way.dir.Magnitude > 0.01 then way.dir.Unit else Vector2.new(1, 0)
		local d3 = Vector3.new(dir.X, 0, dir.Y)
		local height = 6.1 - (k - 1) * 0.9
		local board = Instance.new("Part")
		board.Name = "PathSignBoard"
		board.Size = Vector3.new(0.14, 0.72, 3.6)
		board.CFrame = CFrame.lookAt(at + Vector3.new(0, height, 0) + d3 * 1.9, at + Vector3.new(0, height, 0) + d3 * 4)
		board.Anchored = true
		board.CanCollide = false
		board.CanQuery = false
		board.CanTouch = false
		board.Color = PathBuilder.BOARD
		board.Material = Enum.Material.WoodPlanks
		board.Parent = into
		for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.CanvasSize = Vector2.new(360, 72)
			gui.LightInfluence = 1
			gui.MaxDistance = 90
			local text = Instance.new("TextLabel")
			text.BackgroundTransparency = 1
			text.Size = UDim2.fromScale(1, 1)
			text.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
			text.TextScaled = true
			text.TextColor3 = Color3.fromRGB(58, 40, 26)
			-- (The arrow points the way on whichever face you read.)
			text.Text = if face == Enum.NormalId.Right then way.label .. "  >" else "<  " .. way.label
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 14)
			pad.PaddingRight = UDim.new(0, 14)
			pad.PaddingTop = UDim.new(0, 8)
			pad.PaddingBottom = UDim.new(0, 8)
			pad.Parent = text
			text.Parent = gui
			gui.Parent = board
		end
		n += 1
	end
	return n
end

-- Every EVERY-th point of a planned curve, and its end.
local function corners(stones: { PathPlan.Stone }, offset: Vector2): { Vector2 }
	local out: { Vector2 } = {}
	for k, s in stones do
		if (k - 1) % PathBuilder.EVERY == 0 or k == #stones then
			table.insert(out, offset + s.at)
		end
	end
	return out
end

-- One walkway from a to b (world x, z) at height y (the garden's cobbled walks use it).
function PathBuilder.trail(into: Instance, a: Vector2, b: Vector2, y: number, color: Color3, material: Enum.Material, seed: number): number
	return PathBuilder.walkway(into, corners(PathPlan.curve(a, b, seed), Vector2.zero), y, PathBuilder.WALK_WIDTH, color, material, PathBuilder.KERB)
end

-- The lab's paths, into its Playground folder; `floorY` is the top of the lab floor.
function PathBuilder.lab(into: Instance, origin: Vector3, floorY: number): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Paths"
	local count = 0
	local o2 = Vector2.new(origin.X, origin.Z)
	for i in PathPlan.LAB_SEGMENTS do
		-- (Each segment a hair apart in height: where two meet they never flicker.)
		count += PathBuilder.walkway(folder, corners(PathPlan.segment(i), o2), floorY + 0.01 + (i % 3) * 0.003, PathBuilder.WALK_WIDTH, PathBuilder.GRAVEL, Enum.Material.Cobblestone, PathBuilder.KERB)
	end
	count += PathBuilder.finishKerbs(folder)
	-- The signposts: at each fork, one board per way out, beside the path on the side no path takes.
	local P = PathPlan.LAB_POINTS :: any
	for _, name in PathPlan.SIGNS do
		local here = P[name] :: Vector2
		local ways = {}
		local sum = Vector2.zero
		for i, seg in PathPlan.LAB_SEGMENTS do
			local label = PathPlan.LABELS[seg[2]]
			if seg[1] == name and label then
				local stones = PathPlan.segment(i)
				local ahead = stones[math.min(#stones, 4)].at - here
				table.insert(ways, { dir = ahead, label = label })
				sum += if ahead.Magnitude > 0.01 then ahead.Unit else Vector2.zero
			end
			if seg[2] == name then
				local stones = PathPlan.segment(i)
				local back = stones[math.max(1, #stones - 3)].at - here
				sum += if back.Magnitude > 0.01 then back.Unit else Vector2.zero
			end
		end
		if #ways > 0 then
			local away = if sum.Magnitude > 0.05 then -sum.Unit else Vector2.new(1, 0)
			local spot = o2 + here + away * (PathBuilder.WALK_WIDTH / 2 + 1.6)
			count += PathBuilder.signpost(folder, Vector3.new(spot.X, floorY, spot.Y), ways)
		end
	end
	folder:SetAttribute("Stones", count)
	folder.Parent = into
	return folder
end

return PathBuilder
