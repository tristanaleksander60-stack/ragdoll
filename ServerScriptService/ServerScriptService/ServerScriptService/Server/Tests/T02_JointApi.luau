--!strict
-- The active ragdoll layer depends on these engine APIs. Fails loudly if Roblox renames or removes them.

return {
	name = "joint-api-present",
	run = function(): string?
		local constraint = Instance.new("AnimationConstraint")
		for _, prop in { "IsKinematic", "AngularStrength", "AngularDamping", "LinearStrength", "LinearDamping", "MaxTorque", "Transform" } do
			local ok = pcall(function()
				return (constraint :: any)[prop]
			end)
			assert(ok, "AnimationConstraint." .. prop .. " missing")
		end
		constraint:Destroy()

		local animator = Instance.new("Animator")
		assert(type((animator :: any).ApplyJointVelocities) == "function", "Animator:ApplyJointVelocities missing")
		animator:Destroy()

		local humanoid = Instance.new("Humanoid")
		for _, prop in { "RequiresNeck", "BreakJointsOnDeath", "EvaluateStateMachine" } do
			local ok = pcall(function()
				return (humanoid :: any)[prop]
			end)
			assert(ok, "Humanoid." .. prop .. " missing")
		end
		humanoid:Destroy()

		return "engine " .. version()
	end,
}
