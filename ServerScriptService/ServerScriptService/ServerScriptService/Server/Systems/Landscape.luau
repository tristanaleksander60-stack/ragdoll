--!strict
-- LOOK_V3 (19 Nov 2026): the world around the labs is a green landscape, not a grey slab.
--   Ground: the baseplate becomes grass (the labs' concrete floors stay as test pads on it).
--   Hills: real rolling terrain from a noise height map in the open land in front of, behind and
--     beside the lab line: flat near the labs, rising to big soft hills far off, rock on the
--     steep slopes. (v2 of this file: the first try's terrain balls read as blobs.)
--   Trees, bushes, rocks: real models from the Creator Store when the place has them
--     (V3Assets roles TreeRound, TreePine, Bush, Rock), scattered on the land. No code-built
--     stand-ins: the owner judged ball-on-stick trees as junk, so without models there are none.
-- Built once at start, after a short wait so the first players are not held up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local V3Assets = require(script.Parent.V3Assets)

local Landscape = {}

Landscape.GRASS = if (Config :: any).LOOK_THUMB then Color3.fromRGB(96, 158, 62) else Color3.fromRGB(104, 128, 66) -- (V9-0b: the thumbnails' lush green)
Landscape.SEED = 1119 -- the same land on every server
Landscape.STEP = 8 -- studs per terrain column
Landscape.FLAT = 30 -- studs of flat land next to the labs before the hills start
Landscape.DEPTH = 360 -- studs of land in front of and behind the lab line
Landscape.SIDE = 420 -- studs of land past each end of the lab line
Landscape.PEAK = 110 -- the far hills' height
-- The plaza's front (its leaderboards stand at z 130-136, PC play test 19 Nov: they stood on a hill)
-- is play area too: flat, no trees, within this box round the middle of the lab line.
Landscape.PLAZA_HALF_X = 70
Landscape.PLAZA_FRONT = 150
Landscape.TREES = 220
Landscape.TREE_ROLES = { "TreeRound", "TreePine", "TreeRound", "Bush", "Rock" }

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- The height of the land at (x, z) in lab space, given how far the point is from the play area.
local function heightAt(x: number, z: number, away: number): number
	if away <= Landscape.FLAT then
		return 0
	end
	local rise = smooth((away - Landscape.FLAT) / 260)
	local n = math.noise(x / 230, z / 230, 0.37) * 0.6 + math.noise(x / 90, z / 90, 4.1) * 0.25 + math.noise(x / 35, z / 35, 9.3) * 0.08
	return math.max(0, rise * Landscape.PEAK * (0.55 + n))
end

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
	-- (23 Nov 2026, owner's picture: one smooth green floor with a thin grid over the whole lab. The sizes and edges of the
	-- three base plates are whole tiles, so the lines run on from one to the next.)
	local tiles = (Config :: any).GREEN_TILES
	if tiles then
		for _, name in { "Baseplate", "BaseplateEast", "BaseplateWest" } do
			local plate = Workspace:FindFirstChild(name)
			if plate and plate:IsA("BasePart") then
				plate.Material = tiles.material or Enum.Material.SmoothPlastic
				plate.MaterialVariant = ""
				plate.Reflectance = 0
				plate.Color = tiles.color
				if not tiles.texture then
					continue
				end
				local grid = Instance.new("Texture")
				grid.Name = "Tiles"
				grid.Face = Enum.NormalId.Top
				grid.Texture = tiles.texture
				grid.StudsPerTileU = tiles.studs
				grid.StudsPerTileV = tiles.studs
				grid.Parent = plate
			end
		end
	end
	local terrain = Workspace.Terrain
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Grass, Landscape.GRASS)
		terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(120, 118, 112))
	end)
	-- The play area: the labs' line along X (each lab 85 studs either side of its middle, from
	-- z -95 to +72). Land starts outside it.
	local reach = (math.ceil(plotCount / 2) + 0.5) * plotSpacing
	-- (V6-5: the creature yard in front of the labs keeps the land flat out to z 112.)
	local sp = (Config :: any).LAB_SPREAD or 1 -- (0.37.0: the bigger lab)
	local front, back = (if (Config :: any).LAB_CREATURES then 112 else 75) * sp, -98 * sp
	if (Config :: any).SHOOTING_RANGE then
		front = math.max(front, 172) -- (24 Nov 2026: flat, no trees, under and round the weapon range: ShootingRange)
	end
	-- (0.37.15: the giant compressor stands behind the lab: flat ground out to it.)
	local okC, Compressor = pcall(require, script.Parent:WaitForChild("Compressor"))
	if okC and (Compressor :: any).BACK_ROOM then
		back = math.min(back, (Compressor :: any).BACK_ROOM)
	end
	task.spawn(function()
		task.wait(3)
		local step = Landscape.STEP
		local done = 0
		local heights: { [number]: { [number]: number } } = {}
		for x = -reach - Landscape.SIDE, reach + Landscape.SIDE, step do
			local column: { [number]: number } = {}
			heights[x] = column
			for z = back - Landscape.DEPTH, front + Landscape.DEPTH, step do
				local ax = math.max(0, math.abs(x) - reach)
				local az = if z > front then z - front elseif z < back then back - z else 0
				local away = math.sqrt(ax * ax + az * az)
				local px = math.max(0, math.abs(x) - Landscape.PLAZA_HALF_X)
				local pz = if z > Landscape.PLAZA_FRONT then z - Landscape.PLAZA_FRONT elseif z < back then back - z else 0
				away = math.min(away, math.sqrt(px * px + pz * pz))
				if away > 0 then
					local h = heightAt(x, z, away)
					column[z] = h
					if h > 1 then
						local slope = 0
						local left = heights[x - step]
						if left and left[z] then
							slope = math.abs(h - left[z])
						end
						local material = if slope > step * 0.9 then Enum.Material.Rock else Enum.Material.Grass
						terrain:FillBlock(CFrame.new(labOrigin.X + x, ground + h / 2 - 2, labOrigin.Z + z), Vector3.new(step, h + 4, step), material)
						done += 1
						if done % 400 == 0 then
							task.wait()
						end
					end
				end
			end
		end
		-- Trees, bushes and rocks on the land (real models only).
		local roles: { string } = {}
		for _, role in Landscape.TREE_ROLES do
			if V3Assets.has(role) then
				table.insert(roles, role)
			end
		end
		if #roles == 0 then
			return
		end
		local folder = Instance.new("Folder")
		folder.Name = "Landscape"
		folder.Parent = Workspace
		local rng = Random.new(Landscape.SEED)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		local hitList: { Instance } = { terrain }
		if base then
			table.insert(hitList, base)
		end
		params.FilterDescendantsInstances = hitList
		for i = 1, Landscape.TREES do
			local x = rng:NextNumber(-reach - Landscape.SIDE + 20, reach + Landscape.SIDE - 20)
			local inFront = rng:NextNumber() < 0.5
			local z = if inFront then rng:NextNumber(front + 12, front + Landscape.DEPTH - 30) else rng:NextNumber(back - Landscape.DEPTH + 30, back - 12)
			local inPlaza = math.abs(x) < Landscape.PLAZA_HALF_X + 12 and z < Landscape.PLAZA_FRONT + 12 and z > back - 12
			local from = Vector3.new(labOrigin.X + x, ground + 300, labOrigin.Z + z)
			local hit = Workspace:Raycast(from, Vector3.new(0, -400, 0), params)
			if hit and hit.Normal.Y > 0.75 and not inPlaza then
				local role = roles[rng:NextInteger(1, #roles)]
				local height = if role == "Bush" then rng:NextNumber(3, 5) elseif role == "Rock" then rng:NextNumber(3, 9) else rng:NextNumber(18, 32)
				V3Assets.place(role, folder, CFrame.new(hit.Position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), { height = height, collide = role == "Rock" })
			end
			if i % 20 == 0 then
				task.wait()
			end
		end
	end)
end

return Landscape
