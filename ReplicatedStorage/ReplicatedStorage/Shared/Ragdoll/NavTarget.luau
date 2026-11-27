--!strict
-- F72 step 4 (Config.NAV_SNAP; docs/FIXES_26NOV.md F72): only VALID goals. Every Home a walker heads for goes through
-- NavTarget.snap(point): if the spot is inside or within about 1.5 studs of a solid part (a bench, a lamp, a machine, a
-- wall) or in a place bodies avoid (DummyAvoid: the lava), it moves to the nearest free walkable point on a ring of 8
-- at 2, 4 and 6 studs (a ground ray down plus a body-box overlap check). The answer is cached per half-stud spot for
-- 30 s, so a Home read every frame costs one table lookup.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local NavTarget = {}

local BODY = Vector3.new(2.2 + 3, 3.6, 1.6 + 3) -- the body's box plus 1.5 studs each side
local CACHE_TIME = 30

type Entry = { at: number, point: Vector3 }
local cache: { [string]: Entry } = {}
local cacheCount = 0

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.RespectCanCollide = true
local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.RespectCanCollide = true

local function excludes(): { Instance }
	local list: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(list, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	return list
end

local function avoided(p: Vector3): boolean
	for _, part in CollectionService:GetTagged("DummyAvoid") do
		if part:IsA("BasePart") then
			local rel = part.CFrame:PointToObjectSpace(p)
			if math.abs(rel.X) < part.Size.X / 2 + 1.5 and math.abs(rel.Z) < part.Size.Z / 2 + 1.5 then
				return true
			end
		end
	end
	return false
end

-- The ground under a point (within 6 studs up or down), or nil.
local function groundAt(p: Vector3): Vector3?
	local hit = Workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -12, 0), ray)
	return if hit then hit.Position else nil
end

-- Is a body free to stand here (the ground point)?
local function free(ground: Vector3): boolean
	if avoided(ground) then
		return false
	end
	-- (the box starts 0.8 studs over the ground, so the floor itself and kerbs never count)
	local parts = Workspace:GetPartBoundsInBox(CFrame.new(ground + Vector3.new(0, 0.8 + BODY.Y / 2, 0)), BODY, overlap)
	for _, part in parts do
		if part.CanCollide and part.Transparency < 1 then
			return false
		end
	end
	return true
end

function NavTarget.snap(point: Vector3): Vector3
	local key = string.format("%d,%d,%d", math.floor(point.X * 2 + 0.5), math.floor(point.Y * 2 + 0.5), math.floor(point.Z * 2 + 0.5))
	local now = os.clock()
	local hit = cache[key]
	if hit and now - hit.at < CACHE_TIME then
		return hit.point
	end
	if cacheCount > 2000 then
		table.clear(cache)
		cacheCount = 0
	end
	local ex = excludes()
	overlap.FilterDescendantsInstances = ex
	ray.FilterDescendantsInstances = ex
	local result = point
	local ground = groundAt(point)
	if ground and not free(ground) then
		local found = false
		for _, r in { 2, 4, 6 } do
			for i = 0, 7 do
				local a = i * math.pi / 4
				local p = point + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local g = groundAt(p)
				if g and math.abs(g.Y - ground.Y) < 2.5 and free(g) then
					result = Vector3.new(p.X, point.Y + (g.Y - ground.Y), p.Z)
					found = true
					break
				end
			end
			if found then
				break
			end
		end
	end
	cache[key] = { at = now, point = result }
	cacheCount += 1
	return result
end

return NavTarget
