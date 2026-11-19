--!strict
-- The own-body ragdoll's edge cases (found by review): a flood of reports is paced but the server
-- still ends up agreeing with the client (a throttled report is applied late, never lost); going
-- limp again while getting up drops the body back down; a body that falls out of the world while
-- limp is respawned, also twice in a row; dying while limp respawns; a respawn while limp leaves
-- nothing behind and the new avatar can go limp and get up again. Needs a player in the session.

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

local function allRigid(character: Model): (number, number)
	local rigid, total = 0, 0
	for _, d in character:GetDescendants() do
		if d:IsA("AnimationConstraint") then
			total += 1
			if d.IsKinematic then
				rigid += 1
			end
		end
	end
	return rigid, total
end

local function placeAndLimp(player: Player): Model
	local character = player.Character :: Model
	local labOrigin = Workspace:GetAttribute("LabOrigin")
	local spot = (if typeof(labOrigin) == "Vector3" then labOrigin else Vector3.zero) + Vector3.new(-30, 4, 25)
	character:PivotTo(CFrame.new(spot))
	task.wait(0.8)
	PlayerRagdoll.goLimp(player, true)
	assert(waitFor(function()
		return PlayerRagdoll.isDown(player)
	end, 3), "the client never reported the body limp")
	return character
end

local function getUp(player: Player, character: Model)
	assert(waitFor(function()
		PlayerRagdoll.getUp(player)
		return not PlayerRagdoll.isDown(player)
	end, 12), "the body never got up")
	local rigid, total = allRigid(character)
	assert(rigid == total, string.format("only %d of %d joints are rigid again", rigid, total))
	assert(character:GetAttribute("BodyLoose") == nil, "the server still marks the body loose")
end

return {
	name = "own-avatar-ragdoll-edge-cases",
	timeout = 150,
	run = function(): string?
		local waited = os.clock()
		while (#Players:GetPlayers() == 0 or not Players:GetPlayers()[1].Character) and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player and player.Character, "needs a player with a character in the session")

		-- 1. A flood of reports: paced, and the last one still lands.
		local character = placeAndLimp(player)
		for i = 1, 20 do
			PlayerRagdoll.receive(player, if i % 2 == 0 then "Stumble" else "Ragdoll")
		end
		PlayerRagdoll.receive(player, "Ragdoll")
		assert(waitFor(function()
			return character:GetAttribute("RagdollState") == "Ragdoll"
		end, 3), "the last report of a flood was lost")
		-- The client's own get-up report arrives while the bucket is still empty: applied late.
		getUp(player, character)

		-- 2. Ragdoll pressed while getting up: back down, and it stays down.
		character = placeAndLimp(player)
		PlayerRagdoll.getUp(player)
		task.wait(0.7) -- past the earliest get-up
		assert(waitFor(function()
			PlayerRagdoll.getUp(player)
			return character:GetAttribute("RagdollState") == "GettingUp"
		end, 6), "never started getting up")
		PlayerRagdoll.goLimp(player, true)
		task.wait(2.5)
		assert(PlayerRagdoll.isDown(player) and character:GetAttribute("RagdollState") == "Ragdoll",
			"going limp during the get-up was ignored")
		getUp(player, character)

		-- 3. Out of the world while limp: respawned, and again straight after (no cooldown then).
		for round = 1, 2 do
			assert(waitFor(function()
				return player.Character ~= nil and player.Character:FindFirstChild("LowerTorso") ~= nil
			end, 8), "no avatar")
			task.wait(1)
			character = placeAndLimp(player)
			character:PivotTo(CFrame.new(0, Workspace.FallenPartsDestroyHeight + 20, 0))
			assert(waitFor(function()
				return player.Character ~= character and player.Character ~= nil
			end, 6), "a limp body under the world was not respawned (round " .. round .. ")")
			assert(not PlayerRagdoll.isDown(player), "the respawned avatar counts as limp")
		end

		-- 4. Dying while limp: the normal death and respawn.
		assert(waitFor(function()
			return player.Character ~= nil and player.Character:FindFirstChild("LowerTorso") ~= nil
		end, 8), "no avatar")
		task.wait(1)
		character = placeAndLimp(player)
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		humanoid.Health = 0
		assert(waitFor(function()
			return player.Character ~= character and player.Character ~= nil
		end, Players.RespawnTime + 6), "dying while limp never respawned")
		assert(not PlayerRagdoll.isDown(player), "the respawned avatar counts as limp")

		-- 5. Respawned while limp: the new avatar is whole and works.
		assert(waitFor(function()
			return player.Character ~= nil and player.Character:FindFirstChild("LowerTorso") ~= nil
		end, 6), "no new avatar")
		task.wait(1)
		character = placeAndLimp(player)
		player:LoadCharacter()
		assert(waitFor(function()
			return player.Character ~= character and player.Character ~= nil and player.Character:FindFirstChild("LowerTorso") ~= nil
		end, 6), "no new avatar after a respawn")
		local fresh = player.Character :: Model
		assert(not PlayerRagdoll.isDown(player), "the new avatar counts as limp")
		local rigid, total = allRigid(fresh)
		assert(rigid == total and total >= 15, string.format("the new avatar has %d of %d rigid joints", rigid, total))
		task.wait(1.5)
		character = placeAndLimp(player)
		getUp(player, character)
		return "flood paced without losing the last report; limp during get-up drops back down; void respawn twice; death while limp respawns; respawn while limp leaves a clean, working avatar"
	end,
}
