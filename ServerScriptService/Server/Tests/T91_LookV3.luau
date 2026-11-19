--!strict
-- v3 (19 Nov 2026): the look and the lab cars. Every lab has its car and monster truck, each with
-- a driver's seat, four wheels and a Drive prompt, loose (it moves) and at home on its pad; the
-- dummy lines are kid-safe and the switches hold together.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local DummyLines = require(ReplicatedStorage.Shared.DummyLines)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local VehicleService = require(Systems:WaitForChild("VehicleService"))

local BAD = { "kill", "blood", "die", "dead", "gun" }

return {
	name = "T91_LookV3",
	timeout = 10,
	run = function(): string?
		-- Lines: every list filled, short, and mild.
		for name, list in { FEAR = DummyLines.FEAR, OUCH = DummyLines.OUCH, IDLE = DummyLines.IDLE } do
			assert(#list >= 6, name .. " has too few lines")
			for _, line in list do
				assert(#line <= 40, "line too long: " .. line)
				local low = string.lower(line)
				for _, word in BAD do
					assert(not string.find(low, word, 1, true), "line not mild: " .. line)
				end
			end
		end
		assert(DummyLines.pick(DummyLines.IDLE, 3.2, 1) ~= DummyLines.pick(DummyLines.IDLE, 3.2, 2), "the same line twice in a row")
		if Config.LOOK_V3 then
			assert(not Config.WORLD_V2, "LOOK_V3 wants the WORLD_V2 dressing off")
		end
		-- Cars: in every lab that has a playground.
		if not (Config.VEHICLES and Config.VEHICLES.enabled) then
			return "vehicles off"
		end
		local playground = Workspace:WaitForChild("Playground", 5)
		assert(playground, "no playground")
		local labs, count = 0, 0
		for _, lab in (playground :: Instance):GetChildren() do
			if lab.Name ~= "Plaza" and lab:IsA("Folder") then
				labs += 1
				local holder = lab:FindFirstChild("Vehicles")
				assert(holder, lab.Name .. " has no vehicles")
				for _, model in (holder :: Instance):GetChildren() do
					assert(model:IsA("Model"), "not a model")
					count += 1
					local seat = model:FindFirstChild("Seat")
					assert(seat and seat:IsA("VehicleSeat") and seat:GetAttribute("LabCar") ~= nil, model.Name .. " seat")
					local wheels = 0
					for _, p in model:GetChildren() do
						if p.Name == "Wheel" then
							wheels += 1
						end
					end
					assert(wheels == 4, model.Name .. " has " .. wheels .. " wheels")
					local body = model.PrimaryPart
					assert(body and not body.Anchored, model.Name .. " body anchored")
					assert(body:FindFirstChild("Drive"), model.Name .. " has no Drive prompt")
				end
			end
		end
		assert(count == labs * 2, string.format("%d cars for %d labs", count, labs))
		assert(#VehicleService.carsForTest() >= count, "service lost track of a car")
		return string.format("%d labs, %d cars; lines %d/%d/%d", labs, count, #DummyLines.FEAR, #DummyLines.OUCH, #DummyLines.IDLE)
	end,
}
