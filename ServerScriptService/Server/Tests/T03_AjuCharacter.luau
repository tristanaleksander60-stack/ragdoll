--!strict
-- Checks that a live R15 player character uses Avatar Joint Upgrade joints
-- (AnimationConstraint + BallSocketConstraint) and no Motor6D. Needs a player in the session.

local Players = game:GetService("Players")

local EXPECTED_JOINTS = 15 -- R15 has 15 parts, so 15 animated joints including Root

local function firstCharacter(timeout: number): Model?
	local started = os.clock()
	while os.clock() - started < timeout do
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character and character.Parent then
				return character
			end
		end
		task.wait(0.2)
	end
	return nil
end

return {
	name = "live-character-uses-aju",
	timeout = 25,
	run = function(): string?
		local character = firstCharacter(20)
		assert(character, "no player character within 20 s (run a Play session with a player)")
		task.wait(1) -- let the joint upgrade finish building constraints

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		assert(humanoid and humanoid.RigType == Enum.HumanoidRigType.R15, "character is not R15")

		local counts: { [string]: number } = { AnimationConstraint = 0, BallSocketConstraint = 0, Motor6D = 0 }
		for _, d in character:GetDescendants() do
			local c = counts[d.ClassName]
			if c ~= nil then
				counts[d.ClassName] = c + 1
			end
		end

		local detail = string.format(
			"AnimationConstraint=%d BallSocket=%d Motor6D=%d",
			counts.AnimationConstraint,
			counts.BallSocketConstraint,
			counts.Motor6D
		)
		assert(counts.Motor6D == 0, "Motor6D joints found, AJU is off: " .. detail)
		assert(counts.AnimationConstraint >= EXPECTED_JOINTS - 1, "too few AnimationConstraints: " .. detail)
		return detail
	end,
}
