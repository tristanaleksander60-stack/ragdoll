--!strict
-- Workshop machines in the real lab: a four-wheel car built facing the dummies drives forward (not
-- backwards), runs a dummy over and knocks it down, poofs away once it leaves the lab, and Stop puts
-- the build and the dummy back. Also: every piece is one connected thing (no loose parts on Play).
-- Needs a player in the session (builds belong to players).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local BuildService = require(Systems:WaitForChild("BuildService"))
local Build = ReplicatedStorage.Shared.Build
local Catalog = require(Build.Catalog)
local Orientation = require(Build.Orientation)
local Factory = require(Build.Factory)

local function ok(player: Player, op: string, args: { [string]: any }?)
	local success, message = BuildService.request(player, op, args)
	assert(success, op .. " failed: " .. tostring(message))
	return message
end

local function slotDummy(slot: number): Model?
	local folder = Workspace:FindFirstChild("Dummies")
	if folder then
		for _, model in folder:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("Slot") == slot then
				return model
			end
		end
	end
	return nil
end

return {
	name = "workshop-machines-hit-leash-rewind",
	timeout = 60,
	run = function(): string?
		-- Tests can start before the player has joined; give them a moment.
		local waited = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player, "needs a player in the session")

		-- Every catalog piece is one connected thing: each extra part is welded or jointed to the
		-- attach part (a loose part would fall off or fly away on Play).
		for _, item in Catalog.list do
			local model = Factory.build({ item = item.id, pos = Vector3.zero, rot = 0, color = 0, setting = 1, pinned = true, parent = 0, parentPart = 1 }, Vector3.new(0, 600, 0))
			model.Parent = Workspace
			local parts = Factory.parts(model)
			-- Welds and joints (hinges, sliders, springs) link parts; no-collide pairs do not.
			local links: { [BasePart]: { BasePart } } = {}
			local function link(a: Instance?, b: Instance?)
				if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
					links[a] = links[a] or {}
					links[b] = links[b] or {}
					table.insert(links[a], b)
					table.insert(links[b], a)
				end
			end
			for _, d in model:GetDescendants() do
				if d:IsA("WeldConstraint") then
					link(d.Part0, d.Part1)
				elseif d:IsA("Constraint") and not d:IsA("NoCollisionConstraint") and d.Attachment0 and d.Attachment1 then
					link(d.Attachment0.Parent, d.Attachment1.Parent)
				end
			end
			local connected: { [BasePart]: boolean } = { [parts[1]] = true }
			local queue = { parts[1] }
			while #queue > 0 do
				local p = table.remove(queue) :: BasePart
				for _, q in links[p] or {} do
					if not connected[q] then
						connected[q] = true
						table.insert(queue, q)
					end
				end
			end
			for _, p in parts do
				assert(connected[p], item.id .. " part " .. p.Name .. " is not attached to the rest")
			end
			model:Destroy()
		end

		ok(player, "stop")
		ok(player, "clear")
		-- The lab's dummies are handed to the player's client shortly after it joins.
		waited = os.clock()
		while player:GetAttribute("LabOrigin") == nil or not slotDummy(2) or (slotDummy(2) :: Model):GetAttribute("SimulatedBy") ~= player.UserId do
			if os.clock() - waited > 10 then
				break
			end
			task.wait(0.2)
		end
		local dummy = slotDummy(2)
		assert(dummy, "no dummy in slot 2")
		-- Players walk around the lab now; step the tester's avatar out of the car's path.
		local character = player.Character
		local labOrigin = player:GetAttribute("LabOrigin") -- (the player's own lab: their build is there)
		if character and typeof(labOrigin) == "Vector3" then
			character:PivotTo(CFrame.new(labOrigin + Vector3.new(0, 3, 45)))
		end
		local pelvis = dummy:FindFirstChild("LowerTorso") :: BasePart
		-- Wait for the dummy to stand at home.
		local t0 = os.clock()
		while dummy:GetAttribute("RagdollState") ~= "Standing" and os.clock() - t0 < 8 do
			task.wait(0.1)
		end
		local home = pelvis.Position
		local origin = BuildService.originFor(player)
		local start = Vector3.new(math.round(home.X - origin.X), 1.5, math.round(home.Z - origin.Z) + 22)

		-- A plate on four wheels, unpinned, 22 studs in front of the dummy, facing it.
		ok(player, "place", { item = "Plate", pos = start, rot = 0, parent = 0 })
		ok(player, "pin", { index = 1 })
		for _, dz in { -1.5, 1.5 } do
			ok(player, "place", { item = "Wheel", pos = start + Vector3.new(3, 0, dz), rot = Orientation.facingUp(Vector3.xAxis, 0), parent = 1, parentPart = 1 })
			ok(player, "place", { item = "Wheel", pos = start + Vector3.new(-3, 0, dz), rot = Orientation.facingUp(-Vector3.xAxis, 0), parent = 1, parentPart = 1 })
		end
		ok(player, "play")
		local chassis = Factory.parts(BuildService.modelsOf(player)[1])[1]
		local startZ = chassis.Position.Z

		-- It drives towards the dummy and knocks it down.
		local knocked = false
		t0 = os.clock()
		while os.clock() - t0 < 4 and not knocked do
			local s = dummy:GetAttribute("RagdollState")
			knocked = s == "Ragdoll" or s == "Stumble"
			task.wait()
		end
		assert(chassis.Position.Z < startZ - 5, string.format("the car went the wrong way (z %.0f -> %.0f)", startZ, chassis.Position.Z))
		assert(knocked, string.format("the car did not knock the dummy over (the dummy: %s, %s, %.1f studs from where it stood; the car at %.1f studs from it)",
		tostring(dummy:GetAttribute("Personality")), tostring(dummy:GetAttribute("RagdollState")), (pelvis.Position - home).Magnitude, (chassis.Position - pelvis.Position).Magnitude))
		local hitAfter = os.clock() - t0

		-- It keeps going, leaves the lab and poofs instead of driving on forever.
		t0 = os.clock()
		while os.clock() - t0 < 14 and chassis.Transparency < 1 do
			task.wait(0.1)
		end
		local poofed = chassis.Transparency >= 1 and chassis.Anchored
		local flat = Vector3.new(chassis.Position.X - origin.X, 0, chassis.Position.Z - origin.Z).Magnitude
		-- A car that stopped on the body it ran over is fine too; one that drove on must be leashed.
		assert(poofed or flat < Catalog.BUILD_RADIUS + 8, string.format("the car is %.0f studs out and still there", flat))

		-- Stop: the build is back as built and the dummy is home.
		ok(player, "stop")
		task.wait(0.8)
		local back = Factory.parts(BuildService.modelsOf(player)[1])[1]
		assert((back.Position - (origin + start)).Magnitude < 0.01, "the car is not back where it was built")
		local away = Vector3.new(pelvis.Position.X - home.X, 0, pelvis.Position.Z - home.Z).Magnitude
		assert(away < 2, string.format("the dummy is %.1f studs from home after Stop", away))
		ok(player, "clear")
		return string.format("all pieces connected; car hit the dummy after %.1fs, %s; Stop rewound build and dummy",
			hitAfter, if poofed then "poofed at the lab edge" else "stopped in the lab")
	end,
}
