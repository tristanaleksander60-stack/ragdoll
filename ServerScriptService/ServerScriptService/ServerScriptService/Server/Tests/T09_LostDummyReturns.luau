--!strict
-- A lab dummy that falls out of the world must pop back to its slot, standing and clean, within 2 s.

local Workspace = game:GetService("Workspace")

return {
	name = "fallen-dummy-returns-home",
	timeout = 10,
	run = function(): string?
		local dummies = Workspace:WaitForChild("Dummies", 5)
		assert(dummies, "no lab")
		local model: Model? = nil
		for _, d in (dummies :: Instance):GetChildren() do
			if d:GetAttribute("Slot") == 1 and d:IsA("Model") then
				model = d
			end
		end
		assert(model, "slot 1 dummy missing")
		local m = model :: Model
		local pelvis = m:FindFirstChild("LowerTorso") :: BasePart
		-- Its slot (where it lives), not where it stands now: an earlier test may have knocked it
		-- away (against the lab's crash wall, say) and it may still be walking back.
		local homeAttr = m:GetAttribute("Home")
		local home = if typeof(homeAttr) == "Vector3" then Vector3.new(homeAttr.X, pelvis.Position.Y, homeAttr.Z) else pelvis.Position
		m:PivotTo(CFrame.new(pelvis.Position.X, -80, pelvis.Position.Z))
		local started = os.clock()
		while os.clock() - started < 2 do
			if pelvis.Position.Y > 0 and m:GetAttribute("RagdollState") == "Standing" then
				break
			end
			task.wait(0.05)
		end
		local back = os.clock() - started
		assert(pelvis.Position.Y > 0, string.format("still below the world (y=%.1f)", pelvis.Position.Y))
		local off = Vector3.new(pelvis.Position.X - home.X, 0, pelvis.Position.Z - home.Z).Magnitude
		assert(off < 3, string.format("not back at its slot (%.1f studs off)", off))
		assert(m:GetAttribute("RagdollState") == "Standing", "not standing after return")
		return string.format("home after %.2fs", back)
	end,
}
