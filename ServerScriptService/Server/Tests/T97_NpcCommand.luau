--!strict
-- v4 B4: talk to NPCs. The server refuses what it should (unknown command, too far, a player as the
-- target, a weapon that is not a hitting one, a 4th follower) and takes the rest: Follow marks the
-- body, Attack with Punch hands it the job, Bye lets it go.

local Players = game:GetService("Players")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local NpcCommand = require(Systems:WaitForChild("NpcCommand"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))

return {
	name = "T97_NpcCommand",
	timeout = 25,
	run = function(): string?
		local player = Players:GetPlayers()[1]
		if not player then
			return "no player"
		end
		local char = player.Character
		-- lihfolk-ignore: findfirstchild-chain (guarded by `char and`, checked on the next line)
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return "no character"
		end
		local made: { Model } = {}
		local result: string? = nil
		local ok, err = pcall(function()
			local base = root.Position
			for i = 1, 5 do
				table.insert(made, DummyFactory.spawn(base + Vector3.new(4 + i * 1.5, 1, 4)))
			end
			local far = DummyFactory.spawn(base + Vector3.new(40, 1, 40))
			table.insert(made, far)
			task.wait(0.6)
			local a, b = made[1], made[2]
			assert(NpcCommand.refusal(player, "Dance", a, nil, nil) ~= nil, "an unknown command was taken")
			assert(NpcCommand.refusal(player, "Follow", far, nil, nil) ~= nil, "a body 56 studs away took a command")
			assert(NpcCommand.refusal(player, "Follow", char, nil, nil) ~= nil, "a player took a command")
			assert(NpcCommand.refusal(player, "Attack", a, char, "Punch") ~= nil, "a player was accepted as a target")
			assert(NpcCommand.refusal(player, "Attack", a, b, "NoSuchTool") ~= nil, "an unknown weapon was accepted")
			assert(NpcCommand.refusal(player, "Attack", a, a, "Punch") ~= nil, "a body was told to attack itself")
			-- Follow.
			local fine, why = NpcCommand.command(player, "Follow", a, nil, nil)
			assert(fine, "Follow refused: " .. tostring(why))
			assert(a:GetAttribute("CommandedBy") == player.UserId and a:GetAttribute("Command") == "Follow", "Follow did not mark the body")
			-- Three followers at most.
			assert(NpcCommand.command(player, "Stay", made[3], nil, nil), "a 2nd follower was refused")
			assert(NpcCommand.command(player, "Stay", made[4], nil, nil), "a 3rd follower was refused")
			assert(not (NpcCommand.command(player, "Follow", made[5], nil, nil)), "a 4th follower was taken")
			-- Attack: the job is taken (Punch is on every starting bar).
			local hit, whyHit = NpcCommand.command(player, "Attack", a, b, "Punch")
			assert(hit, "Attack with Punch refused: " .. tostring(whyHit))
			assert(a:GetAttribute("Command") == "Attack", "Attack did not mark the body")
			-- Bye.
			assert(NpcCommand.command(player, "Bye", a, nil, nil), "Bye refused")
			assert(a:GetAttribute("CommandedBy") == nil, "Bye did not let the body go")
			NpcCommand.command(player, "Bye", made[3], nil, nil)
			NpcCommand.command(player, "Bye", made[4], nil, nil)
		end)
		if not ok then
			result = tostring(err)
		end
		for _, m in made do
			if m.Parent then
				m:Destroy()
			end
		end
		return result
	end,
}
