--!strict
-- Weight: a bowling ball bowls a dummy over like a pin. It used to send the body skating 200 studs
-- across the floor (uncapped impulse and plastic-slick skin). Bowled four times in a row, because
-- the outcome varies from roll to roll and an outlier is exactly what this guards against.

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local ToyService = require(Systems:WaitForChild("ToyService"))

local MAX_TRAVEL = 40 -- studs from where it stood to where it comes to rest
local ROLLS = 4

local function roll(index: number): (number, number, string)
	local base = Vector3.new(660 + index * 40, 0, 760)
	local model = DummyFactory.spawn(base, base - Vector3.new(0, 0, 60))
	task.wait(0.3)
	local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
	local start = pelvis.Position
	-- The ball is placed 18 studs behind the aim point and rolls towards it.
	ToyService.place(nil, "Bowling", Vector3.new(start.X, 0, start.Z), Vector3.new(0, 0, 1))
	local knocked = false
	local t0 = os.clock()
	local farthest = 0
	local states, last = {}, ""
	local trace = {}
	local nextSample = 0
	while os.clock() - t0 < 5 do
		local s = model:GetAttribute("RagdollState")
		knocked = knocked or s == "Ragdoll" or s == "Stumble"
		if s ~= last then
			last = s :: string
			table.insert(states, string.format("%s@%.1f", last, os.clock() - t0))
		end
		local flat = Vector3.new(pelvis.Position.X - start.X, 0, pelvis.Position.Z - start.Z)
		farthest = math.max(farthest, flat.Magnitude)
		if os.clock() - t0 >= nextSample then
			nextSample += 0.25
			table.insert(trace, string.format("%.0f/%.1f/%.0f", flat.Magnitude, pelvis.Position.Y, pelvis.AssemblyLinearVelocity.Magnitude))
		end
		task.wait()
	end
	local hits = (model:GetAttribute("PropHits") :: number?) or 0
	model:Destroy()
	assert(knocked, "roll " .. index .. ": the ball did not knock the dummy over")
	assert(hits <= 1, "roll " .. index .. ": the ball hit the same dummy " .. hits .. " times")
	local detail = table.concat(states, " ") .. " | dist/y/speed every 0.25 s: " .. table.concat(trace, " ")
	return farthest, hits, detail
end

return {
	name = "bowling-ball-bowls-the-dummy-over",
	timeout = 40,
	run = function(): string?
		local distances = {}
		for i = 1, ROLLS do
			local farthest, _, detail = roll(i)
			assert(farthest <= MAX_TRAVEL, string.format("roll %d: the dummy travelled %.0f studs; %s", i, farthest, detail))
			table.insert(distances, string.format("%.0f", farthest))
		end
		return "knocked over " .. ROLLS .. " times, travelled " .. table.concat(distances, "/") .. " studs"
	end,
}
