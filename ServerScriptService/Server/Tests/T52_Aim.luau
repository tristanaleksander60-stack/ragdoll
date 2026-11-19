--!strict
-- Round 5: the gun follows the mouse (AimService on the server; the pose itself is client-side and
-- was measured live: the barrel within 1 degree of the point, ahead, up, down, to the sides, behind).
--   an aim lands on the character as Aim, clamped and rounded; tiny changes are not written again
--   nil clears it; the remote exists (unreliable)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local AimService = require(Systems:WaitForChild("AimService"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

return {
	name = "aim-follows-mouse",
	timeout = 15,
	run = function(): string?
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		local character = player.Character or player.CharacterAdded:Wait()
		assert(AimService.set(player, 0.305, -0.5), "an aim was not written")
		local a = character:GetAttribute("Aim")
		assert(typeof(a) == "Vector2", "no Aim attribute")
		assert(math.abs((a :: Vector2).X - 0.30) < 1e-3 and math.abs((a :: Vector2).Y + 0.5) < 1e-3, "not rounded to the step: " .. tostring(a))
		assert(not AimService.set(player, 0.3005, -0.5), "a change smaller than the step was written")
		AimService.set(player, 9, 99)
		local b = character:GetAttribute("Aim") :: Vector2
		assert(b.X <= AimService.PITCH + 1e-6 and b.Y <= math.pi + 1e-6, "not clamped: " .. tostring(b))
		AimService.set(player, nil, nil)
		assert(character:GetAttribute("Aim") == nil, "nil did not clear the aim")
		assert(Net.unreliable(Net.Names.Aim):IsA("UnreliableRemoteEvent"), "no Aim remote")
		return "set, rounded, clamped, cleared; unreliable remote"
	end,
}
