--!strict
-- OVERVIEW 0.7 (owner, 26 Nov 2026: "Der skal være en ragdoll ved hver maskine og stå og kigge, minimum 1"; docs/ALWAYS3.md
-- "Spectators at every machine"; Config.MACHINE_WATCHERS): where a watcher stands at each attraction of the master plan
-- (Shared/OwnerMapPlan), in lab space. Next to the end of the attraction's inner path, off the path, facing the thing.
-- The server (Systems/Watchers) puts a real ragdoll on the spots near the player; the client (Client/WatcherStandIns)
-- draws light stand-ins on the others.

local Plan = require(script.Parent:WaitForChild("OwnerMapPlan")) :: any

local WatchSpots = {}

export type Spot = { id: string, at: Vector2, look: Vector2 }

local spots: { Spot } = {}
local seen: { [string]: boolean } = {}
for _, path in Plan.INNER do
	local id = path.to
	local item = Plan.ITEMS[id]
	if id ~= "entrance" and item and not seen[id] and #path.points >= 2 then
		seen[id] = true
		local n = #path.points
		local last, prev = path.points[n], path.points[n - 1]
		local k = n - 1
		while k > 1 and (last - prev).Magnitude < 4 do
			k -= 1
			prev = path.points[k]
		end
		local dir = if (last - prev).Magnitude > 0.1 then (last - prev).Unit else Vector2.new(0, 1)
		local side = Vector2.new(-dir.Y, dir.X)
		-- (left of the path end, a step back from the thing: off the path and out of its launch line)
		table.insert(spots, { id = id, at = last - dir * 7 - side * (Plan.INNER_W / 2 + 4), look = item.at })
	end
end
WatchSpots.LIST = spots

return WatchSpots
