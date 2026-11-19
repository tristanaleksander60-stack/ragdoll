--!strict
-- End to end: a dummy owned by a player is simulated by their client. A hit sent from the server
-- must reach the client, the client must report the state back, the server must mirror the joint
-- topology, and the dummy must get up again. Needs a player in the session.

local Players = game:GetService("Players")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))

local function waitFor(check: () -> boolean, timeout: number): (boolean, number)
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true, os.clock() - started
		end
		task.wait(0.03)
	end
	return false, timeout
end

return {
	name = "client-simulated-dummy-round-trip",
	timeout = 25,
	run = function(): string?
		local waited = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player, "needs a player in the session")
		local model = DummyFactory.spawn(Vector3.new(45, 0, 45), nil, player) -- near the player: clients only simulate what is close to them
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
		local shoulder: AnimationConstraint? = nil
		for _, d in model:GetDescendants() do
			if d:IsA("AnimationConstraint") and d.Name == "LeftShoulder" then
				shoulder = d
			end
		end
		assert(shoulder, "no LeftShoulder joint")
		assert(model:GetAttribute("Owner") == player.UserId, "Owner attribute not set")
		assert(pelvis:GetNetworkOwner() == player, "pelvis not owned by the player")

		-- The client adopts the dummy and reports in.
		local adopted, adoptTime = waitFor(function()
			return model:GetAttribute("SimulatedBy") == player.UserId
		end, 6)
		assert(adopted, "client never took over the dummy")
		assert(model:GetAttribute("RagdollState") == "Standing", "adopted but not Standing")

		local mass = model:GetAttribute("Mass") :: number
		local chest = model:FindFirstChild("UpperTorso") :: BasePart
		local sent = DummyControl.hit(model, chest, Vector3.new(60, 40, 0) * mass, chest.Position)
		assert(sent == "Sent", "hit was not forwarded to the owner (" .. tostring(sent) .. ")")

		local reported, reportTime = waitFor(function()
			return model:GetAttribute("RagdollState") == "Ragdoll"
		end, 2)
		assert(reported, "owner never reported Ragdoll")
		assert(not (shoulder :: AnimationConstraint).IsKinematic, "server did not mirror the limp topology")

		local moved = waitFor(function()
			return (pelvis.Position - Vector3.new(45, 2.3, 45)).Magnitude > 4
		end, 2)
		assert(moved, "server never saw the body move (replication)")

		local up, upTime = waitFor(function()
			return model:GetAttribute("RagdollState") == "Standing"
		end, 12)
		assert(up, "never got up (state " .. tostring(model:GetAttribute("RagdollState")) .. ")")
		assert((shoulder :: AnimationConstraint).IsKinematic, "server did not mirror standing topology")
		model:Destroy()
		return string.format("adopted after %.2fs, Ragdoll reported after %.2fs, standing after %.1fs", adoptTime, reportTime, upTime)
	end,
}
