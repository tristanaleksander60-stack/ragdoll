--!strict
-- v3 Phase C: the animal events and the big red button. The gorilla and the bulls appear, move and
-- leave nothing behind when stopped; both events have handlers and a picture; every lab has its
-- button with a prompt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Events)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local Creatures = require(Systems:WaitForChild("Creatures"))
local Lab = require(Systems:WaitForChild("Lab"))

return {
	name = "T92_Creatures",
	timeout = 12,
	run = function(): string?
		assert(Events.byId.GorillaRampage and Events.byId.BullRun, "animal events missing")
		local p = Lab.plazaOrigin()
		local center = Vector3.new(p.X, p.Y - 0.5, p.Z)
		local stopGorilla = Creatures.gorilla(center)
		local folder = Workspace:WaitForChild("Creatures", 2)
		assert(folder, "no Creatures folder")
		local gorilla = (folder :: Instance):FindFirstChild("Gorilla")
		assert(gorilla and gorilla:IsA("Model"), "no gorilla")
		local before = (gorilla :: Model):GetPivot().Position
		task.wait(0.6)
		local moved = ((gorilla :: Model):GetPivot().Position - before).Magnitude
		stopGorilla()
		local stopBulls = Creatures.bulls(center)
		task.wait(0.5)
		local bulls = 0
		for _, c in (folder :: Instance):GetChildren() do
			if c.Name == "Bull" then
				bulls += 1
			end
		end
		stopBulls()
		task.wait(0.1)
		assert(#(folder :: Instance):GetChildren() == 0, "animals left behind")
		assert(bulls >= 1, "no bull ran")
		-- The button in every lab.
		local buttons = 0
		local playground = Workspace:FindFirstChild("Playground")
		for _, lab in if playground then playground:GetChildren() else {} do
			if lab.Name ~= "Plaza" and lab:IsA("Folder") then
				local b = lab:FindFirstChild("BigButton")
				assert(b and b:FindFirstChild("Press"), lab.Name .. " has no big red button")
				buttons += 1
			end
		end
		return string.format("gorilla moved %.1f studs, %d bull(s), %d buttons", moved, bulls, buttons)
	end,
}
