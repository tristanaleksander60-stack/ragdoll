--!strict
-- PlanSpot (MAP ROUND 4, OVERVIEW M4): one place for "where does plan item X stand" (Shared/OwnerMapPlan ITEMS, lab-space
-- studs: x east, z south). Systems that used to hard-code a spot of the big round-3 map ask here, so the compact plan
-- (and any later plan change) moves them with the map. A missing id gives the caller's fallback.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ok, Plan = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
end)

local PlanSpot = {}

-- The item's middle (+ an optional nudge), or the fallback.
function PlanSpot.at(id: string, fallback: Vector2, dx: number?, dz: number?): Vector2
	local it = ok and Plan and Plan.ITEMS and Plan.ITEMS[id]
	if not it then
		return fallback
	end
	return it.at + Vector2.new(dx or 0, dz or 0)
end

-- The item's footprint (w x d), or the fallback.
function PlanSpot.size(id: string, fallback: Vector2): Vector2
	local it = ok and Plan and Plan.ITEMS and Plan.ITEMS[id]
	return if it and it.size then it.size else fallback
end

-- A road's points by id (Plan.ROADS), or nil.
function PlanSpot.road(id: string): { Vector2 }?
	if not (ok and Plan and Plan.ROADS) then
		return nil
	end
	for _, r in Plan.ROADS do
		if r.id == id then
			return r.points
		end
	end
	return nil
end

-- True on the compact map (round 4).
PlanSpot.compact = ok and Plan ~= nil and type(Plan.K) == "number" and Plan.K < 2

return PlanSpot
