--!strict
-- V9-0h (owner, 21 Nov 2026: "do the same as the leader": art/store/look_target/leader_hub.webp):
-- with Config.LAYOUT_V3 the lab is one big open hub. The floor wears the big-tile texture; no
-- path crosses the floor (only the yard road starts at its back edge); the spawn has a 40-stud
-- clear circle; every attraction stands on the rim between 40 and 150 studs; the dummies' test
-- row is out on the rim too; the lab boards are the bigger wall.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local PathPlan = require(Shared:WaitForChild("PathPlan")) :: any
local Zones = require(Shared:WaitForChild("Zones")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

-- The attractions by the name of the part or model that marks each.
local ATTRACTIONS = {
	"BigButton", "Ramp", "CannonModel", "Bullseye", "LavaPool", "SwingBall", "Tower", "TrampolinePad",
	"StationPad", "MacePost", "PortalSolo", "PortalMulti", "LabCar", "LabTruck", "Rocket", "ThrowTower",
}

return {
	name = "T163_HubLayout",
	timeout = 60,
	run = function(): string?
		if not Config.LAYOUT_V3 then
			return "skipped (LAYOUT_V3 off)"
		end
		assert(TestLib.waitFor(function()
			local pg = Workspace:FindFirstChild("Playground")
			local lab = pg and pg:FindFirstChild("Lab1")
			return lab ~= nil and lab:FindFirstChild("Vehicles") ~= nil and lab:FindFirstChild("CreatureYard") ~= nil
		end, 40), "no Lab1")
		local lab = (Workspace :: any).Playground.Lab1 :: Instance
		local o = Vector3.new(Zones.plotCenterX(1), 0, 0)
		-- The floor: the big-tile texture.
		local floor: BasePart? = nil
		for _, d in (Workspace :: any).Labs:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "LabFloor" and math.abs(d.Position.X - o.X) < 30 then
				floor = d
			end
		end
		assert(floor, "no LabFloor in Lab1")
		local tiles = (floor :: BasePart):FindFirstChild("Tiles")
		-- (V9-0k: the soft pads, a MaterialVariant on the same one flat floor, or the V9-0h tiles.)
		local padded = (floor :: BasePart).MaterialVariant ~= ""
		assert(padded or (tiles and tiles:IsA("Texture") and tiles.StudsPerTileU >= 10), "the floor has neither the pads nor the big-tile texture")
		if padded then
			local variant = game:GetService("MaterialService"):FindFirstChild((floor :: BasePart).MaterialVariant, true)
			assert(variant and variant:IsA("MaterialVariant") and variant.StudsPerTile >= 20, "the pads' MaterialVariant is missing or too small")
			-- (Still one thin flat layer: the solid ground under it is unchanged, so bodies and cars move as before.)
			assert((floor :: BasePart).Size.Y < 1 and #(floor :: BasePart):GetChildren() == 0, "the floor is no longer one flat layer")
		end
		-- No path on the floor: every paving piece is beyond the floor's back edge (z >= 66) or out
		-- in the gardens (|x| >= 80).
		local inside = 0
		for _, d in lab:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "PathSlab" or d.Name == "PathJoint") and d.Parent and d.Parent.Name == "Paths" then
				local p = d.Position - o
				if math.abs(p.X) < 78 and p.Z < 66 then
					inside += 1
				end
			end
		end
		assert(inside == 0, inside .. " paving piece(s) on the open floor")
		-- Every attraction on the rim (40-150 studs from the spawn), the spawn circle clear.
		local found, report = 0, {}
		for _, name in ATTRACTIONS do
			local thing = lab:FindFirstChild(name, true)
			if thing and (thing:IsA("BasePart") or thing:IsA("Model")) then
				found += 1
				local p = (thing :: any):GetPivot().Position - o
				local r = math.sqrt(p.X * p.X + p.Z * p.Z)
				-- (V9-0h review: its nearest corner too, not only its middle.)
				local cf: CFrame, size: Vector3
				if thing:IsA("Model") then
					cf, size = thing:GetBoundingBox()
				else
					cf, size = (thing :: BasePart).CFrame, (thing :: BasePart).Size
				end
				local near = math.huge
				for _, sx in { -0.5, 0.5 } do
					for _, sz in { -0.5, 0.5 } do
						local c = (cf * Vector3.new(size.X * sx, 0, size.Z * sz)) - o
						near = math.min(near, math.sqrt(c.X * c.X + c.Z * c.Z))
					end
				end
				-- (The bullseye, flat on the floor, may reach in: it blocks nothing. Only it: the BIG RED BUTTON's
				-- 1-stud base is checked like the rest, V9-0d review.)
				local flatThing = name == "Bullseye"
				assert(flatThing or near >= PathPlan.HUB_CLEAR - 2, string.format("%s reaches %.0f studs from the spawn (want %d)", name, near, PathPlan.HUB_CLEAR))
				assert(r >= PathPlan.HUB_CLEAR and r <= 150, string.format("%s is %.0f studs from the spawn (want %d-150)", name, r, PathPlan.HUB_CLEAR))
				table.insert(report, string.format("%s %.0f", name, r))
			end
		end
		assert(found >= 12, "only " .. found .. " attractions found")
		-- The dummies' test zone is out on the rim too.
		local zone: BasePart? = nil
		for _, d in (Workspace :: any).Labs:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "TestZone" and math.abs(d.Position.X - o.X) < 30 then
				zone = d
			end
		end
		assert(zone and math.abs((zone :: BasePart).Position.Z - o.Z) >= PathPlan.HUB_CLEAR, "the test row is inside the spawn's clear circle")
		-- (V9-0h review) No Christmas spot stands on the test row.
		local Playground = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("Playground")) :: any
		for spot, at in Playground.CHRISTMAS_SPOTS or {} do
			local onRow = math.abs(at.X) < 21 + 6 and math.abs(at.Y - PathPlan.ROW_Z) < 8 + 9
			assert(not onRow, "the Christmas " .. spot .. " stands on the dummies' test row")
		end
		-- The lab boards: the bigger wall.
		local board = (Workspace :: any).Labs:FindFirstChild("Board_Takedowns", true)
		if board and board:IsA("Model") then
			local _, size = board:GetBoundingBox()
			assert(size.Y >= 24, "the lab board is not the big wall: " .. size.Y)
		end
		return string.format("%s floor, no path on it, spawn circle %d clear, %d attractions on the rim (%s), test row out", if (floor :: BasePart).MaterialVariant ~= "" then "padded (" .. (floor :: BasePart).MaterialVariant .. ")" else "big-tile", PathPlan.HUB_CLEAR, found, table.concat(report, ", "))
	end,
}
