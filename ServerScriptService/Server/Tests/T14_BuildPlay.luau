--!strict
-- The Workshop end to end on the server: placing with the build rules, wiring, Play (welds, pins,
-- a wired motor waiting for its button), Stop, deleting a piece with everything built on it, undo.
-- Needs a player in the session (builds belong to players).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local BuildService = require(Systems:WaitForChild("BuildService"))
local Build = ReplicatedStorage.Shared.Build
local Orientation = require(Build.Orientation)
local Factory = require(Build.Factory)

local function ok(player: Player, op: string, args: { [string]: any }?)
	local success, message = BuildService.request(player, op, args)
	assert(success, op .. " failed: " .. tostring(message))
	return message
end

local function fails(player: Player, op: string, args: { [string]: any }, label: string)
	local success = BuildService.request(player, op, args)
	assert(not success, label .. " was allowed")
end

return {
	name = "workshop-build-play-stop-undo",
	timeout = 30,
	run = function(): string?
		-- Tests can start before the player has joined; give them a moment.
		local waited = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player, "needs a player in the session")
		ok(player, "stop")
		ok(player, "clear")
		local up = Orientation.facingUp(Vector3.yAxis, 0)
		-- Far corner of the build area so nothing else is in the way.
		local x, z = 40, 40

		ok(player, "place", { item = "Plate", pos = Vector3.new(x, 0.5, z), rot = 0, parent = 0 }) -- 1
		ok(player, "place", { item = "Motor", pos = Vector3.new(x, 2, z), rot = up, parent = 1, parentPart = 1 }) -- 2
		ok(player, "place", { item = "Beam", pos = Vector3.new(x, 3.5, z), rot = 0, parent = 2, parentPart = 2 }) -- 3 on the motor's top
		ok(player, "place", { item = "Button", pos = Vector3.new(x + 5, 0.5, z), rot = up, parent = 0 }) -- 4

		fails(player, "place", { item = "Block", pos = Vector3.new(x, 1, z), rot = 0, parent = 0 }, "overlapping block")
		fails(player, "place", { item = "Block", pos = Vector3.new(500, 1, 0), rot = 0, parent = 0 }, "block far outside the lab")
		fails(player, "place", { item = "Block", pos = Vector3.new(x + 10, 1.3, z), rot = 0, parent = 0 }, "off-grid block")
		fails(player, "place", { item = "Nope", pos = Vector3.new(x + 10, 1, z), rot = 0, parent = 0 }, "unknown item")
		fails(player, "wire", { from = 1, to = 2 }, "wire from a plate")
		fails(player, "wire", { from = 4, to = 3 }, "wire into a beam")
		ok(player, "wire", { from = 4, to = 2 })

		local bp = BuildService.blueprintOf(player)
		assert(#bp.pieces == 4 and #bp.wires == 1, "blueprint has the wrong shape")
		assert(bp.pieces[1].pinned and not bp.pieces[3].pinned, "pinning rule broken")

		-- Play: everything welded, the plate pinned, the motor waiting for its button.
		ok(player, "play")
		assert(BuildService.isPlaying(player), "not playing")
		fails(player, "place", { item = "Block", pos = Vector3.new(x + 10, 1, z), rot = 0, parent = 0 }, "building while playing")
		local models = BuildService.modelsOf(player)
		local plate = Factory.parts(models[1])[1]
		local motorParts = Factory.parts(models[2])
		local beam = Factory.parts(models[3])[1]
		assert(plate.Anchored, "plate on the floor is not pinned")
		assert(not beam.Anchored, "beam is frozen")
		local joint = models[2]:FindFirstChild("Joint", true) :: HingeConstraint
		assert(joint and joint.AngularVelocity == 0, "wired motor started without a signal")
		local startLook = beam.CFrame.LookVector
		BuildService.press(player, 4)
		assert(joint.AngularVelocity ~= 0, "button did not start the motor")
		task.wait(1.2)
		local turned = math.deg(math.acos(math.clamp(beam.CFrame.LookVector:Dot(startLook), -1, 1)))
		assert(turned > 20, string.format("beam only turned %.0f degrees", turned))
		assert((motorParts[1].Position - plate.Position).Magnitude < 3, "motor came off the plate")
		BuildService.press(player, 4)
		assert(joint.AngularVelocity == 0, "second press did not stop the motor")

		-- Stop: frozen again, exactly as built.
		ok(player, "stop")
		models = BuildService.modelsOf(player)
		for _, model in models do
			for _, part in Factory.parts(model) do
				assert(part.Anchored, "part still loose after Stop")
			end
		end

		-- Delete the plate: the motor and beam on it go too, the button stays, the wire goes.
		ok(player, "delete", { index = 1 })
		bp = BuildService.blueprintOf(player)
		assert(#bp.pieces == 1 and bp.pieces[1].item == "Button" and #bp.wires == 0, "delete did not take the subtree")
		ok(player, "undo")
		bp = BuildService.blueprintOf(player)
		assert(#bp.pieces == 4 and #bp.wires == 1, "undo did not restore the build")

		-- Tune and paint.
		local setting = ok(player, "tune", { index = 2 })
		assert(setting == "Fast", "tune did not cycle the motor (" .. tostring(setting) .. ")")
		ok(player, "paint", { index = 1, color = 3 })
		assert(BuildService.blueprintOf(player).pieces[1].color == 3, "paint did not stick")

		ok(player, "clear")
		assert(#BuildService.blueprintOf(player).pieces == 0, "clear left pieces")
		return string.format("placed 4, rules held, motor turned %.0f degrees on the button, stop/delete/undo/tune/paint ok", turned)
	end,
}
