--!strict
-- A dummy lying face down must kneel up, one lying face up must sit up, and both must end standing upright.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local ActiveRagdoll = require(ReplicatedStorage.Shared.Ragdoll.ActiveRagdoll)

local function lieAndRise(x: number, faceDown: boolean): string
	local model = DummyFactory.spawn(Vector3.new(x, 0, 640))
	task.wait(0.3)
	ActiveRagdoll.setState(model, "Ragdoll")
	local angle = if faceDown then -math.pi / 2 else math.pi / 2
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(pivot.Position.X, 1, pivot.Position.Z) * CFrame.Angles(angle, 0, 0))

	local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
	local started = os.clock()
	local style: string? = nil
	while os.clock() - started < 10 do
		style = style or (model:GetAttribute("GetUpStyle") :: string?)
		if model:GetAttribute("RagdollState") == "Standing" and style then
			break
		end
		task.wait(0.05)
	end
	local took = os.clock() - started
	assert(model:GetAttribute("RagdollState") == "Standing", "did not stand up within 10 s")
	task.wait(0.4)
	local up = pelvis.CFrame.UpVector.Y
	model:Destroy()
	local expected = if faceDown then "Kneel" else "SitUp"
	assert(style == expected, string.format("expected %s, got %s", expected, tostring(style)))
	assert(up > 0.9, string.format("%s ended tilted (up.Y=%.2f)", expected, up))
	return string.format("%s %.1fs", expected, took)
end

return {
	name = "get-up-face-down-and-face-up",
	timeout = 25,
	run = function(): string?
		local a = lieAndRise(680, true)
		local b = lieAndRise(720, false)
		return a .. ", " .. b
	end,
}
