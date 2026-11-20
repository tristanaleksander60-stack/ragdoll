--!strict
-- v4 C1: the lab has its zones, a featured machine that changes every UTC day (the same on every
-- server), and NEW tags only inside their window.

local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local LabZones = require(Systems:WaitForChild("LabZones"))

return {
	name = "T99_LabZones",
	timeout = 10,
	run = function(): string?
		-- Today's machine: a valid one, and it moves on from one day to the next.
		local t = 1795132800 -- (a UTC midnight)
		local a, b = LabZones.todayIndex(t), LabZones.todayIndex(t + 86400)
		assert(a >= 1 and a <= #LabZones.MACHINES and b ~= a, "today's machine does not change by the day")
		assert(LabZones.todayIndex(t + 3600) == a, "today's machine changed within the day")
		-- NEW window.
		assert(LabZones.newShowing(os.time({ year = 2026, month = 11, day = 21, hour = 12 })), "NEW does not show the day after the update")
		assert(not LabZones.newShowing(os.time({ year = 2026, month = 12, day = 10, hour = 12 })), "NEW still shows three weeks on")
		-- Built in a lab: zones, a featured machine, nothing that collides.
		local pg = Workspace:FindFirstChild("Playground")
		local lab = pg and pg:FindFirstChild("Lab1")
		local zones = lab and lab:FindFirstChild("Zones")
		assert(zones, "Lab1 has no zones")
		assert(type(zones:GetAttribute("Today")) == "string", "no machine is featured today")
		local labels = 0
		for _, d in zones:GetDescendants() do
			if d:IsA("BasePart") then
				assert(not d.CanCollide and not d.CanQuery, d.Name .. " collides")
			elseif d:IsA("TextLabel") and d.Parent and d.Parent:IsA("SurfaceGui") then
				labels += 1
			end
		end
		assert(labels >= #LabZones.ZONES, string.format("only %d zone names on the floor", labels))
		return nil
	end,
}
