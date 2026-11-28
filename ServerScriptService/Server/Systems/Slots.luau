--!strict
-- Slots (SPAWN_V2 step 2, Config.SPAWN_SLOTS): the places a living ragdoll may stand and DO something, so they spread out
-- over the lab instead of bunching in front of the player.
--   * WATCH rings: 3 places round every machine's DropSpot (DropSpots tags one per machine, ride or station), 7-9 studs
--     out, on free level floor (its own check). A body sent there watches the machine.
--   * Bench seats stay with BenchService (it already books them one body a seat).
-- A slot is free when no living body has its Home within APART studs, and its 20 x 20 cell holds fewer than CELL_MAX homes.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Slots = {}

Slots.APART = 4
Slots.CELL = 20
Slots.CELL_MAX = 4
Slots.RING = { 7, 9 } -- studs from the machine's spot
Slots.PER_MACHINE = 3

local function homes(): { Vector3 }
	local out = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return out
	end
	for _, m in dummies:GetChildren() do
		local h = m:GetAttribute("Home")
		local v = m:GetAttribute("Vital")
		if typeof(h) == "Vector3" and v ~= "Dead" then
			table.insert(out, h)
		end
	end
	return out
end

-- Level, solid, free floor at `at` (a ray down past bodies and players; no lava; room for a standing body), or nil.
-- (Its own check: VisitorService.floorAt needs an old lab plot (Lab.ownerAt), which the owner map does not have.)
local function floorAt(at: Vector3): Vector3?
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	for _, p in game:GetService("Players"):GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(at + Vector3.new(0, 12, 0), Vector3.new(0, -30, 0), params)
	if not hit or hit.Normal.Y < 0.9 or string.find(hit.Instance.Name, "Lava") or string.find(hit.Instance.Name, "Water") then
		return nil
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = skip
	for _, part in Workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 3, 0)), Vector3.new(2.5, 4.5, 2.5), overlap) do
		if part.CanCollide then
			return nil
		end
	end
	return hit.Position
end

local function cellOf(p: Vector3): string
	return tostring(math.floor(p.X / Slots.CELL)) .. ":" .. tostring(math.floor(p.Z / Slots.CELL))
end

-- Is `at` free: nobody's Home within APART, and its cell not full?
function Slots.isFree(at: Vector3, taken: { Vector3 }?): boolean
	local list = taken or homes()
	local cell = cellOf(at)
	local inCell = 0
	for _, h in list do
		if Vector3.new(h.X - at.X, 0, h.Z - at.Z).Magnitude < Slots.APART then
			return false
		end
		if cellOf(h) == cell then
			inCell += 1
		end
	end
	return inCell < Slots.CELL_MAX
end

-- The watch slots of `owner`'s lab within `maxD` of `near`, nearest first (the floor is checked for each).
function Slots.watchSlots(owner: Player, near: Vector3, maxD: number): { { at: Vector3, look: Vector3 } }
	local _ = owner
	local out = {}
	for _, spot in CollectionService:GetTagged("DropSpot") do
		if spot:IsA("BasePart") and Vector3.new(spot.Position.X - near.X, 0, spot.Position.Z - near.Z).Magnitude <= maxD then
			for i = 1, Slots.PER_MACHINE do
				local a = (i / Slots.PER_MACHINE) * math.pi * 2 + (spot.Position.X % 7)
				local r = Slots.RING[1] + (i % 2) * (Slots.RING[2] - Slots.RING[1])
				local want = spot.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local top = floorAt(want)
				if top then
					table.insert(out, { at = top, look = spot.Position })
				end
			end
		end
	end
	table.sort(out, function(x, y)
		return (x.at - near).Magnitude < (y.at - near).Magnitude
	end)
	return out
end

-- One free watch slot near `near` (nil when none): where a body should go and what it looks at.
function Slots.watchSpot(owner: Player, near: Vector3, maxD: number): (Vector3?, Vector3?)
	local taken = homes()
	for _, s in Slots.watchSlots(owner, near, maxD) do
		if Slots.isFree(s.at, taken) then
			return s.at, s.look
		end
	end
	return nil, nil
end

return Slots
