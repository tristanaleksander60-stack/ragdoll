--!strict
-- TerrainClear (Config.KEEP_CLEAR). The owner: "Weapon testing still sits in the mountain" / "fix the maps so nothing is
-- inside a mountain". The cause: the weapon range stands just outside the compact plan, inside the ring of grass hills
-- round the map (LabOwnerMap hills, FillBall up to ~100 studs wide), and the old fix (RANGE_CLEAR) only cut a 6-stud gap
-- round its walls, so the hill still rose right against its sides and roof. On the older map the slow Landscape fill
-- also put the hill back after that cut.
-- Now a building tagged "KeepTerrainClear" stands in an open, terraced bowl: everything over its floor inside its box
-- plus MARGIN studs is air, and wider rings step up gently (each STEP_OUT studs out, the cut starts STEP_UP higher), so
-- the hill opens round it like a dug-out site instead of a wall at the window. The cut is done at once and again
-- later (a hill filled after the building, the Landscape's slow fill), always from the same box, so it never grows.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local TerrainClear = {}
TerrainClear.TAG = "KeepTerrainClear"
TerrainClear.MARGIN = 14 -- studs of flat open ground round the building
TerrainClear.RINGS = 5 -- terraces outside that
TerrainClear.STEP_OUT = 9 -- studs each terrace reaches further out
TerrainClear.STEP_UP = 5 -- studs each terrace starts higher
TerrainClear.AGAIN = { 4, 20, 60, 120 } -- s: cut again (hills and fills that come later)

local done: { [Instance]: boolean } = {}

local function cut(inst: Instance)
	local cf: CFrame, size: Vector3
	if inst:IsA("Model") then
		if not inst.Parent then
			return
		end
		cf, size = inst:GetBoundingBox()
	elseif inst:IsA("BasePart") then
		cf, size = inst.CFrame, inst.Size
	else
		return
	end
	local terrain = Workspace.Terrain
	local floorY = cf.Position.Y - size.Y / 2
	local turn = cf - cf.Position
	local function air(extra: number, fromY: number)
		local h = 160
		pcall(function()
			terrain:FillBlock(
				CFrame.new(cf.Position.X, fromY + h / 2, cf.Position.Z) * turn,
				Vector3.new(size.X + extra * 2, h, size.Z + extra * 2),
				Enum.Material.Air
			)
		end)
	end
	-- the site: flat to the floor round the building, then the terraces outward and upward
	air(TerrainClear.MARGIN, floorY + 0.3)
	for k = 1, TerrainClear.RINGS do
		air(TerrainClear.MARGIN + k * TerrainClear.STEP_OUT, floorY + 0.3 + k * TerrainClear.STEP_UP)
	end
end

-- Frees a building now and a few times later. Safe to call twice.
function TerrainClear.free(inst: Instance)
	CollectionService:AddTag(inst, TerrainClear.TAG)
	if done[inst] then
		return
	end
	done[inst] = true
	cut(inst)
	task.spawn(function()
		local waited = 0
		for _, t in TerrainClear.AGAIN do
			task.wait(t - waited)
			waited = t
			if not inst.Parent then
				done[inst] = nil
				return
			end
			cut(inst)
		end
	end)
end

-- Every tagged building, now (the Landscape calls this when its slow fill ends).
function TerrainClear.all()
	for _, inst in CollectionService:GetTagged(TerrainClear.TAG) do
		cut(inst)
	end
end

function TerrainClear.start()
	CollectionService:GetInstanceAddedSignal(TerrainClear.TAG):Connect(function(inst)
		task.defer(TerrainClear.free, inst)
	end)
	for _, inst in CollectionService:GetTagged(TerrainClear.TAG) do
		TerrainClear.free(inst)
	end
end

return TerrainClear
