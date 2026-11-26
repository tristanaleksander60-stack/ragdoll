--!strict
-- Your own avatar as a ragdoll, the way the vault says players' ragdolls work: the player's client
-- simulates the limp body the whole time (it stays the network owner, the server never touches the
-- Humanoid), the server mirrors the loose joints. Going limp drops the body (and it keeps its root
-- part), a knock the server saw sends it flying, getting up hands everything back exactly as it was.
-- Needs a player in the session.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local PlayerRagdoll = require(Systems:WaitForChild("PlayerRagdoll"))

local function waitFor(check: () -> boolean, timeout: number): boolean
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if check() then
			return true
		end
		task.wait(0.1)
	end
	return check()
end

return {
	name = "own-avatar-ragdoll-and-get-up",
	timeout = 40,
	run = function(): string?
		local waited = os.clock()
		while (#Players:GetPlayers() == 0 or not Players:GetPlayers()[1].Character) and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player and player.Character, "needs a player with a character in the session")
		local character = player.Character :: Model
		local labOrigin = Workspace:GetAttribute("LabOrigin")
		local spot = (if typeof(labOrigin) == "Vector3" then labOrigin else Vector3.zero) + Vector3.new(-30, 4, 25)
		character:PivotTo(CFrame.new(spot))
		task.wait(0.8)

		-- Go limp and stay down.
		PlayerRagdoll.goLimp(player, true)
		assert(waitFor(function()
			return PlayerRagdoll.isDown(player)
		end, 3), "the client never reported the body limp")
		local chest = character:FindFirstChild("UpperTorso") :: BasePart
		assert(waitFor(function()
			return chest.CFrame.UpVector.Y < 0.6
		end, 3), "the body did not fall over")
		local root = character:FindFirstChild("HumanoidRootPart")
		assert(root and root:IsA("BasePart"), "the avatar lost its root part")
		assert(chest:GetNetworkOwner() == player, "the player does not simulate their own limp body")
		local loose = 0
		for _, d in character:GetDescendants() do
			if d:IsA("AnimationConstraint") and not d.IsKinematic then
				loose += 1
			end
		end
		assert(loose >= 14, string.format("the server mirrors only %d loose joints", loose))
		task.wait(1.5)
		assert(PlayerRagdoll.isDown(player), "got up while told to stay down")

		-- A knock the server saw sends it flying.
		local before = chest.Position
		PlayerRagdoll.knock(player, Vector3.new(0, 25, -50))
		task.wait(0.6)
		local flew = (chest.Position - before).Magnitude
		assert(flew > 8, string.format("the knock moved the body only %.1f studs", flew))

		-- Get up: everything back as it was.
		assert(waitFor(function()
			PlayerRagdoll.getUp(player)
			return not PlayerRagdoll.isDown(player)
		end, 12), "the body never got up")
		local rigid, total = 0, 0
		for _, d in character:GetDescendants() do
			if d:IsA("AnimationConstraint") then
				total += 1
				if d.IsKinematic then
					rigid += 1
				end
			end
		end
		assert(rigid == total, string.format("only %d of %d joints are rigid again", rigid, total))
		local r = character:FindFirstChild("HumanoidRootPart") :: BasePart
		assert(r:GetNetworkOwner() == player, "the player does not simulate their body")
		assert(waitFor(function()
			return math.abs(r.CFrame.UpVector.Y) > 0.95
		end, 1), "the avatar is not upright")
		return string.format("fell (client-simulated, %d joints mirrored loose), flew %.0f studs, stood up with %d rigid joints", loose, flew, rigid)
	end,
}
