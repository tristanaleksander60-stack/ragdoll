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
		-- (V8-1.7: with the birds off their models are moved to ServerStorage at boot.)
		if not (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BIRDS then
			return "skipped (birds off: Config.BIRDS)"
		end
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
		-- V7-3: a grounded bird stands on its feet: placed by feetOffset, its lowest point is on the floor.
		for _, def in Birds.FLOCKS.Plaza do
			if def.ground then
				local m = ((models :: Instance):FindFirstChild(def.model) :: Model):Clone()
				m:ScaleTo(m:GetScale() * (def.size or 1))
				local floorY = 100
				local feet = Birds.feetOffset(m)
				m:PivotTo(CFrame.new(0, floorY + feet, 0))
				local cf, size = m:GetBoundingBox()
				local bottom = cf.Position.Y - size.Y / 2
				m:Destroy()
				assert(math.abs(bottom - floorY) < 0.15, string.format("a %s stands %.2f studs off the floor", def.model, bottom - floorY))
			end
		end
		-- 20 Nov: every bird in the air beats real wings: a flying flock's model, and a walker's flyer,
		-- has wing bones on both sides (shoulder to hand), and one flap frame moves them.
		for place, defs in Birds.FLOCKS do
			for _, def in defs do
				local name = if def.ground then Birds.FLYER else def.model
				local m = ((models :: Instance):FindFirstChild(name) :: Model):Clone()
				local wings = Birds.wingsOf(m)
				local left, right = 0, 0
				for _, w in wings do
					if w.side > 0 then left += 1 else right += 1 end
				end
				assert(left >= 3 and right >= 3, place .. ": the " .. name .. " flying there has no wings to beat")
				local before = wings[1].bone.Transform
				Birds.flap(wings, 1, 1, math.pi / 2)
				assert(wings[1].bone.Transform ~= before, "a flap frame did not move the wing")
				m:Destroy()
			end
		end
		local caps = Config.BIRDS_MAX
		assert(caps and caps.phone < caps.tablet and caps.tablet <= caps.pc, "bird budgets are not phone < tablet <= pc")
		return string.format("%d flock birds over %d models; budgets pc %d / tablet %d / phone %d", n, #(models :: Instance):GetChildren(), caps.pc, caps.tablet, caps.phone)
	end,
}
