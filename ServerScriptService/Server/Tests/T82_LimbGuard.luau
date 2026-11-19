--!strict
-- World/Feel v2 (Config.FEEL_V2): the ragdoll limb guard. A limb kicked far faster than its body (the
-- "exploding ragdoll") is brought back within ActiveRagdoll.LIMB_REL_MAX of the pelvis by the next
-- step, while a whole body launched fast keeps its speed (the guard is relative, not a cap).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local ActiveRagdoll = require(ReplicatedStorage.Shared.Ragdoll.ActiveRagdoll) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))

return {
	name = "T82_LimbGuard",
	timeout = 15,
	run = function(): string?
		if not Config.FEEL_V2 then
			return "FEEL_V2 off: guard not active (nothing to check)"
		end
		local model = DummyFactory.spawn(Vector3.new(1180, 0, 560))
		task.wait(0.5)
		local pelvisPart = model:FindFirstChild("LowerTorso")
		local handPart = model:FindFirstChild("LeftHand")
		assert(pelvisPart and pelvisPart:IsA("BasePart") and handPart and handPart:IsA("BasePart"), "no body parts")
		local pelvis: BasePart = pelvisPart
		local hand: BasePart = handPart
		-- Knocked over first (limp: the limbs are free on their sockets).
		ActiveRagdoll.hit(model, pelvis, Vector3.new(0, 0, 60) * pelvis.AssemblyMass, pelvis.Position)
		task.wait(1)
		-- A wild kick on one hand.
		local worst = 0
		hand.AssemblyLinearVelocity = pelvis.AssemblyLinearVelocity + Vector3.new(900, 0, 0)
		for _ = 1, 3 do
			RunService.PostSimulation:Wait()
		end
		worst = (hand.AssemblyLinearVelocity - pelvis.AssemblyLinearVelocity).Magnitude
		assert(worst <= ActiveRagdoll.LIMB_REL_MAX * 1.5, string.format("a hand kept %.0f studs/s against its body (guard %d)", worst, ActiveRagdoll.LIMB_REL_MAX))
		-- The whole body thrown fast keeps its speed.
		ActiveRagdoll.push(model, Vector3.new(0, 140, 0))
		RunService.PostSimulation:Wait()
		local up = pelvis.AssemblyLinearVelocity.Y
		model:Destroy()
		assert(up > 60, string.format("a whole-body launch was slowed to %.0f studs/s", up))
		return string.format("a 900 studs/s hand kick settled to %.0f studs/s against the body; a launch kept %.0f studs/s up", worst, up)
	end,
}
