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
		-- V9-0o (Config.DUMMY_TONE): a fresh dummy is a mid-light grey (never white, darker than the hub
		-- floor pads), matte (Plastic, no reflectance), far from the dead green.
		local tone = ""
		local TONE = (Config :: any).DUMMY_TONE
		if TONE then
			local DummyFactory = require(Systems:WaitForChild("DummyFactory")) :: any
			local probe = DummyFactory.spawn(Vector3.new(0, 1, -60), nil)
			local DEAD = Color3.fromRGB(96, 196, 84)
			local floor = (Config :: any).HUB_FLOOR_PADS
			local floorLum = if floor then (floor.color.R + floor.color.G + floor.color.B) / 3 else 1
			local parts = 0
			local ok, err = pcall(function()
				for _, d in probe:GetChildren() do
					if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
						parts += 1
						local c = d.Color
						local lum = (c.R + c.G + c.B) / 3
						assert(lum >= 105 / 255 and lum <= 175 / 255, string.format("%s is %d/255 bright: not the mid-light grey", d.Name, math.floor(lum * 255)))
						assert(lum < floorLum, d.Name .. " is not darker than the hub floor pads")
						assert(math.abs(c.R - c.G) < 0.06 and math.abs(c.G - c.B) < 0.06, d.Name .. " is not a neutral grey")
						assert(d.Reflectance == 0 and d.Material == TONE.material and d.Material ~= Enum.Material.SmoothPlastic, d.Name .. " shines (material " .. d.Material.Name .. ", reflectance " .. d.Reflectance .. ")")
						local dg = math.abs(c.R - DEAD.R) + math.abs(c.G - DEAD.G) + math.abs(c.B - DEAD.B)
						assert(dg > 0.4, d.Name .. " is too close to the dead green")
					end
				end
			end)
			probe:Destroy()
			assert(ok, err)
			tone = string.format("; %d dummy parts grey %d/255, matte %s, reflectance 0", parts, math.floor(TONE.shell.R * 255), TONE.material.Name)
		end
		return string.format("%d labs, %d cars; lines %d/%d/%d", labs, count, #DummyLines.FEAR, #DummyLines.OUCH, #DummyLines.IDLE) .. tone
	end,
}
