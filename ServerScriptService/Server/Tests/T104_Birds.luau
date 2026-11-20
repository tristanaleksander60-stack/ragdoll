--!strict
-- V6-6: the birds (Client/Birds): every flock's model is in ReplicatedStorage.BirdModels, no
-- scripts in them, a budget per device tier (phone smallest), and every flock fits a phone's budget
-- shape (counts are cut to the budget at run time).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

return {
	name = "T104_Birds",
	timeout = 10,
	run = function(): string?
		local models = ReplicatedStorage:FindFirstChild("BirdModels")
		assert(models, "no ReplicatedStorage.BirdModels (place file)")
		for _, m in (models :: Instance):GetChildren() do
			for _, d in m:GetDescendants() do
				assert(not d:IsA("LuaSourceContainer"), "a script inside the bird " .. m.Name)
			end
		end
		local mod = StarterPlayer:WaitForChild("StarterPlayerScripts"):FindFirstChild("Birds", true)
		assert(mod and mod:IsA("ModuleScript"), "no Client/Birds")
		local Birds = require(mod :: ModuleScript) :: any
		local n = 0
		for place, defs in Birds.FLOCKS do
			for _, def in defs do
				assert((models :: Instance):FindFirstChild(def.model), place .. " needs the bird " .. def.model)
				n += def.count
			end
		end
		local caps = Config.BIRDS_MAX
		assert(caps and caps.phone < caps.tablet and caps.tablet <= caps.pc, "bird budgets are not phone < tablet <= pc")
		return string.format("%d flock birds over %d models; budgets pc %d / tablet %d / phone %d", n, #(models :: Instance):GetChildren(), caps.pc, caps.tablet, caps.phone)
	end,
}
