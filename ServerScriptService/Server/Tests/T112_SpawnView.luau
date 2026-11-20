--!strict
-- V8-0.4 (cannon in view): through the camera an avatar gets at the lab's spawn (Roblox's default
-- follow camera: 12.5 studs behind, a little above, 70 degrees tall), the 3 middle dummies of the
-- row and the cannon are both on screen at 1920x1080 and on a landscape phone (800x360). Also: no
-- machine stands in the spawn's keep-clear circle, and no signpost stands at the spawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local PathPlan = require(Shared:WaitForChild("PathPlan")) :: any
local Lab = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("Lab")) :: any

-- Is a world point inside a screen of `size` seen from `cam` (70 degrees tall)?
local function onScreen(cam: CFrame, point: Vector3, size: Vector2): boolean
	local rel = cam:PointToObjectSpace(point)
	if rel.Z >= -0.5 then
		return false -- behind the camera
	end
	local tanV = math.tan(math.rad(35))
	local tanH = tanV * size.X / size.Y
	return math.abs(rel.X / -rel.Z) <= tanH * 0.96 and math.abs(rel.Y / -rel.Z) <= tanV * 0.96
end

return {
	name = "T112_SpawnView",
	timeout = 30,
	run = function(): string?
		if not Config.V8_ONE_VOICE then
			return "skipped (V8_ONE_VOICE off)"
		end
		-- The keep-clear circle: no machine in it, no signpost at the spawn.
		local clear = PathPlan.SPAWN_CLEAR
		for _, o in PathPlan.OBSTACLES do
			if o.at then
				assert((o.at - clear.at).Magnitude > clear.radius + (o.radius or 0), o.name .. " stands in the spawn's keep-clear circle")
			elseif o.min and o.max then
				local nearest = Vector2.new(math.clamp(clear.at.X, o.min.X, o.max.X), math.clamp(clear.at.Y, o.min.Y, o.max.Y))
				assert((nearest - clear.at).Magnitude > clear.radius, o.name .. " stands in the spawn's keep-clear circle")
			end
		end
		for _, name in PathPlan.SIGNS do
			local p = PathPlan.LAB_POINTS[name]
			assert(p and (p - clear.at).Magnitude > clear.radius, "the " .. name .. " signpost stands at the spawn")
		end
		-- The view from the spawn, in lab 1 (built for the test player).
		local lab = (Workspace:WaitForChild("Playground", 10) :: Instance):WaitForChild("Lab1", 20)
		assert(lab, "no lab 1")
		local cannon = lab:FindFirstChild("CannonModel", true) or lab:FindFirstChild("CannonPad", true)
		assert(cannon, "lab 1 has no cannon")
		local cannonAt = if cannon:IsA("Model") then cannon:GetPivot().Position else (cannon :: BasePart).Position
		-- The spawn: the lab's origin, where Lab.placeOnPlot puts the avatar; the cannon model stands
		-- 52 studs east and 10 south of it (measured in Studio, 21 Nov).
		local cannonPivot = if cannon:IsA("Model") then cannon:GetPivot().Position else (cannon :: BasePart).Position
		local o = cannonPivot - Vector3.new(52, 0, 10)
		local y = cannonAt.Y
		local facing = Lab.SPAWN_FACING
		local head = Vector3.new(o.X, y + 1.5, o.Z)
		local cam = CFrame.lookAt(head - facing * 12.5 + Vector3.new(0, 2.5, 0), head + facing * 4)
		-- The 3 middle dummies of the lab's row, at home (earlier tests knock them about): about 20
		-- studs in front of the spawn, 5 apart.
		local row = { Vector3.new(o.X - 3, y, o.Z - 21), Vector3.new(o.X + 2, y, o.Z - 21), Vector3.new(o.X + 7, y, o.Z - 20) }
		if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).LAYOUT_V3 then
			-- (V9-0h: the row stands behind the bullseye, a 40-degree arc at r 58; the spawn faces 50 degrees
			-- right, towards the cannon, so its 3 slots on the right are the ones in view.)
			-- (V9-0d review: read from the lab's own slots, not typed in.)
			local n = Lab.slotCount()
			row = {}
			for index = n - 2, n do
				local at = Lab.slotPosition(Vector3.new(o.X, y, o.Z), index)
				table.insert(row, Vector3.new(at.X, y, at.Z))
			end
		end
		for _, size in { Vector2.new(1920, 1080), Vector2.new(800, 360) } do
			assert(onScreen(cam, cannonAt + Vector3.new(0, 2, 0), size), string.format("the cannon is off screen at %dx%d", size.X, size.Y))
			for i = 1, 3 do
				assert(onScreen(cam, row[i] + Vector3.new(0, 1, 0), size), string.format("a middle dummy is off screen at %dx%d", size.X, size.Y))
			end
		end
		return "the cannon and the 3 middle dummies in the spawn view at 1920x1080 and 800x360; no machine or signpost in the spawn circle"
	end,
}
