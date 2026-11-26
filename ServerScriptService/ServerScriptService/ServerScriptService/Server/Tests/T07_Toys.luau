--!strict
-- Smoke test for the prop and special toys: each must visibly affect a dummy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local HitService = require(Systems:WaitForChild("HitService"))
local ToyService = require(Systems:WaitForChild("ToyService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.05)
	end
	return false
end

local function state(model: Model): string
	return tostring(model:GetAttribute("RagdollState"))
end

return {
	name = "toys-anvil-tnt-freeze-rocket",
	timeout = 30,
	run = function(): string?
		local results = {}

		-- Anvil dropped on a dummy knocks it down.
		local a = DummyFactory.spawn(Vector3.new(760, 0, 560))
		task.wait(0.3)
		local aPos = (a:FindFirstChild("LowerTorso") :: BasePart).Position
		ToyService.place(nil, "Anvil", Vector3.new(aPos.X, 0, aPos.Z), Vector3.zAxis)
		assert(waitFor(function()
			return state(a) == "Ragdoll" or state(a) == "Stumble"
		end, 4), "anvil did not knock the dummy (state " .. state(a) .. ")")
		table.insert(results, "anvil " .. state(a))
		a:Destroy()

		-- TNT ragdolls both dummies next to it.
		local t1 = DummyFactory.spawn(Vector3.new(800, 0, 560))
		local t2 = DummyFactory.spawn(Vector3.new(808, 0, 560))
		task.wait(0.3)
		ToyService.place(nil, "TNT", Vector3.new(804, 0, 563), Vector3.zAxis)
		assert(waitFor(function()
			return state(t1) == "Ragdoll" and state(t2) == "Ragdoll"
		end, 4), "TNT did not ragdoll both dummies (" .. state(t1) .. ", " .. state(t2) .. ")")
		table.insert(results, "tnt 2x Ragdoll")
		t1:Destroy()
		t2:Destroy()

		-- Freeze, then a Poke shatters the ice statue.
		local f = DummyFactory.spawn(Vector3.new(840, 0, 560))
		task.wait(0.3)
		local chest = f:FindFirstChild("UpperTorso") :: BasePart
		ToyService.onDummy(nil, "Freeze", chest, chest.Position)
		assert(state(f) == "Frozen", "freeze ray did not freeze (state " .. state(f) .. ")")
		task.wait(0.5)
		HitService.applyToy(Toys.byId.Poke, chest, chest.Position, Vector3.xAxis)
		assert(waitFor(function()
			return f.Parent == nil
		end, 1), "frozen dummy did not shatter on a Poke")
		table.insert(results, "freeze+shatter")

		-- Rocket lifts a dummy off the ground.
		local r = DummyFactory.spawn(Vector3.new(880, 0, 560))
		task.wait(0.3)
		local rChest = r:FindFirstChild("UpperTorso") :: BasePart
		local pelvis = r:FindFirstChild("LowerTorso") :: BasePart
		ToyService.onDummy(nil, "Rocket", rChest, rChest.Position)
		local top = 0
		waitFor(function()
			top = math.max(top, pelvis.Position.Y)
			return top > 10
		end, 3)
		assert(top > 10, string.format("rocket only reached y=%.1f", top))
		table.insert(results, string.format("rocket y=%.0f", top))
		r:Destroy()

		return table.concat(results, ", ")
	end,
}
