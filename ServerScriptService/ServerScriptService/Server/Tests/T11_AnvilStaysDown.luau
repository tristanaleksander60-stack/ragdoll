--!strict
-- Stability: an anvil dropped on a dummy's head must flatten it where it stands. It used to push
-- the body into the floor so hard that the solver shot it 25 studs up and 55 studs sideways.

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local ToyService = require(Systems:WaitForChild("ToyService"))

local MAX_RISE = 5 -- studs the pelvis may rise above where it stood
local MAX_DRIFT = 12 -- studs it may end up from where it stood (it topples and the anvil takes its spot)

return {
	name = "anvil-keeps-the-dummy-down",
	timeout = 20,
	run = function(): string?
		local worstRise, worstDrift = 0, 0
		for i = 1, 3 do
			local model = DummyFactory.spawn(Vector3.new(700 + i * 40, 0, 640))
			task.wait(0.3)
			local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
			local start = pelvis.Position
			ToyService.place(nil, "Anvil", Vector3.new(start.X, 0, start.Z), Vector3.zAxis)
			local rise, drift = 0, 0
			local t0 = os.clock()
			local knocked = false
			while os.clock() - t0 < 3.5 do
				rise = math.max(rise, pelvis.Position.Y - start.Y)
				local flat = Vector3.new(pelvis.Position.X - start.X, 0, pelvis.Position.Z - start.Z)
				drift = math.max(drift, flat.Magnitude)
				local s = model:GetAttribute("RagdollState")
				knocked = knocked or s == "Ragdoll" or s == "Stumble"
				task.wait()
			end
			model:Destroy()
			assert(knocked, string.format("anvil %d did not knock the dummy down (touches %s, too slow %s, hit %s)", i,
				tostring(model:GetAttribute("PropTouches")), tostring(model:GetAttribute("PropSlow")), tostring(model:GetAttribute("PropHit"))))
			assert(rise <= MAX_RISE, string.format("anvil %d launched the dummy %.1f studs up", i, rise))
			assert(drift <= MAX_DRIFT, string.format("anvil %d threw the dummy %.1f studs away", i, drift))
			worstRise = math.max(worstRise, rise)
			worstDrift = math.max(worstDrift, drift)
		end
		return string.format("3 drops: worst rise %.1f, worst drift %.1f studs", worstRise, worstDrift)
	end,
}
