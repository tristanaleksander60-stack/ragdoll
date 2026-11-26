--!strict
-- A Launch hit must ragdoll a dummy, and it must get up again on its own, upright and intact.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local HitService = require(Systems:WaitForChild("HitService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

return {
	name = "launch-ragdolls-and-gets-up",
	timeout = 20,
	run = function(): string?
		local model = DummyFactory.spawn(Vector3.new(600, 0, 600))
		task.wait(0.5)
		local chest = model:FindFirstChild("UpperTorso") :: BasePart
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
		local ok = pcall(function()
			HitService.applyToy(Toys.byId.Launch, chest, chest.Position, Vector3.new(1, 0, 0))
		end)
		assert(ok, "hit errored")
		assert(model:GetAttribute("RagdollState") == "Ragdoll", "expected Ragdoll right after a Launch hit, got " .. tostring(model:GetAttribute("RagdollState")))

		local flew = false
		local maxHeight = 0
		local started = os.clock()
		local standing = false
		local upTime = 0
		while os.clock() - started < 15 do
			maxHeight = math.max(maxHeight, pelvis.Position.Y)
			if model:GetAttribute("Airborne") == true then
				flew = true
			end
			if model:GetAttribute("RagdollState") == "Standing" then
				standing = true
				upTime = os.clock() - started
				break
			end
			task.wait(0.05)
		end
		assert(flew, "never detected as airborne, so no flailing")
		assert(standing, "did not get up within 15 s (state " .. tostring(model:GetAttribute("RagdollState")) .. ")")
		task.wait(0.5)
		local up = pelvis.CFrame.UpVector.Y
		local p = pelvis.Position
		assert(p.X == p.X and p.Y == p.Y, "NaN position")
		assert(up > 0.9, string.format("not upright after getting up (up.Y=%.2f)", up))
		model:Destroy()
		return string.format("flew to y=%.1f, standing after %.1fs, upright %.2f", maxHeight, upTime, up)
	end,
}
