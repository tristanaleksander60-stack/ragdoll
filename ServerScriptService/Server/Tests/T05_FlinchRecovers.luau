--!strict
-- A Poke must only flinch a dummy, and it must be back to Standing within 1.5 s without falling.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local HitService = require(Systems:WaitForChild("HitService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

return {
	name = "poke-flinches-and-recovers",
	timeout = 10,
	run = function(): string?
		local model = DummyFactory.spawn(Vector3.new(640, 0, 600))
		task.wait(0.5)
		local arm = model:FindFirstChild("RightUpperArm") :: BasePart
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
		HitService.applyToy(Toys.byId.Poke, arm, arm.Position, Vector3.new(0, 0, -1))
		assert(model:GetAttribute("RagdollState") == "Flinch", "expected Flinch, got " .. tostring(model:GetAttribute("RagdollState")))

		local started = os.clock()
		local sawRagdoll = false
		while os.clock() - started < 1.5 do
			if model:GetAttribute("RagdollState") == "Ragdoll" then
				sawRagdoll = true
			end
			if model:GetAttribute("RagdollState") == "Standing" then
				break
			end
			task.wait(0.05)
		end
		local back = os.clock() - started
		assert(not sawRagdoll, "a Poke made the dummy fall over")
		assert(model:GetAttribute("RagdollState") == "Standing", "not Standing 1.5 s after a Poke")
		local up = pelvis.CFrame.UpVector.Y
		assert(up > 0.95, string.format("tilted after a Poke (up.Y=%.2f)", up))
		model:Destroy()
		return string.format("back to Standing after %.2fs, upright %.2f", back, up)
	end,
}
