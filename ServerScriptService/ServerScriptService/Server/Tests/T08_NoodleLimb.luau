--!strict
-- A Launch sends a dummy flying unhurt and a limb breaks on the landing (noodle limb with a plaster);
-- a Shove on a limb breaks nothing.
-- Healing mends it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local HitService = require(Systems:WaitForChild("HitService"))
local Toys = require(ReplicatedStorage.Shared.Toys)
local ActiveRagdoll = require(ReplicatedStorage.Shared.Ragdoll.ActiveRagdoll)

local function plasters(model: Model): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d.Name == "Plaster" then
			n += 1
		end
	end
	return n
end

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.05)
	end
	return check()
end

return {
	name = "noodle-limb-breaks-and-heals",
	timeout = 20,
	run = function(): string?
		local soft = DummyFactory.spawn(Vector3.new(920, 0, 560))
		task.wait(0.3)
		local softArm = soft:FindFirstChild("RightLowerArm") :: BasePart
		HitService.applyToy(Toys.byId.Shove, softArm, softArm.Position, Vector3.xAxis)
		assert(not ActiveRagdoll.isBroken(soft, "RightElbow"), "a Shove broke an elbow")
		soft:Destroy()

		local model = DummyFactory.spawn(Vector3.new(960, 0, 560))
		task.wait(0.3)
		local arm = model:FindFirstChild("LeftLowerArm") :: BasePart
		HitService.applyToy(Toys.byId.Launch, arm, arm.Position, Vector3.xAxis)
		-- Hurt by the landing, not the launch (phase C): nothing broken in the air, a limb on impact.
		assert((model:GetAttribute("Broken") :: number? or 0) == 0, "the launch itself broke a limb")
		local landed = waitFor(function()
			return (model:GetAttribute("Broken") :: number? or 0) >= 1
		end, 5)
		assert(landed, "the landing after a Launch broke nothing")
		-- The limb that was struck is the one that breaks (carried from the launch to the landing).
		assert(ActiveRagdoll.isBroken(model, "LeftElbow"), "the struck arm (left elbow) is not the limb that broke")
		assert(plasters(model) >= 2, "expected a plaster cross (2 strips) per break, found " .. plasters(model))

		ActiveRagdoll.heal(model)
		assert((model:GetAttribute("Broken") :: number? or 0) == 0, "heal did not mend the limb")
		assert(plasters(model) == 0, "plasters left after heal")
		model:Destroy()
		return "Shove intact, Launch: unhurt in the air, the struck arm breaks on landing, heal mends"
	end,
}
