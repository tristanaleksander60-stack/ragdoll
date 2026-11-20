--!strict
-- V9-0c (owner, 21 Nov 2026: "the car just drives round in a circle, fix it and make a speedometer"):
-- the lab cars' drive (Shared/CarDrive, the step VehicleClient runs each frame), for both the Car
-- and the Truck: 3 s of throttle alone turns the heading less than 3 degrees; a steer turns the way
-- it says and stops turning within 0.5 s of letting go; no turn at 0 speed; S brakes, then reverses;
-- the gauge reads km/h and the gear. (The circle came from AvatarMoves turning a seated body, which
-- is welded to the car: seated it no longer turns; checked live in Studio with AimTestPoint.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local CarDrive = require(Shared:WaitForChild("CarDrive")) :: any

local DT = 1 / 60

-- Drives for `seconds` with the given input; returns the speed, eased steer and heading change (deg).
local function run(spec: any, seconds: number, throttle: number, steer: number, along0: number?, steer0: number?): (number, number, number)
	local along, steerNow, heading = along0 or 0, steer0 or 0, 0
	for _ = 1, math.floor(seconds / DT) do
		local yawRate
		along, steerNow, yawRate = CarDrive.step(spec, along, steerNow, throttle, steer, DT)
		heading += math.deg(yawRate * DT)
	end
	return along, steerNow, heading
end

return {
	name = "T153_CarDrives",
	timeout = 30,
	run = function(): string?
		if not (Config.VEHICLES and Config.VEHICLES.enabled) then
			return "skipped (VEHICLES off)"
		end
		local lines = {}
		for _, kind in { "Car", "Truck" } do
			local spec = Config.VEHICLES[kind]
			assert(spec, "no spec for " .. kind)
			-- Throttle only: straight.
			local speed, _, turned = run(spec, 3, 1, 0)
			assert(math.abs(turned) < 3, kind .. " turned " .. turned .. " deg on throttle alone")
			assert(speed > spec.speed * 0.8, kind .. " is slow: " .. speed)
			-- Steer left at speed: turns left (+); let go: stops turning within 0.5 s.
			local _, steerNow, left = run(spec, 1, 1, -1, speed, 0)
			assert(left > 10, kind .. " did not turn left: " .. left)
			local _, s2, after = run(spec, 0.5, 1, 0, speed, steerNow)
			assert(s2 == 0, kind .. " still steers 0.5 s after the steer was let go")
			local _, _, stillTurning = run(spec, 0.2, 1, 0, speed, s2)
			assert(math.abs(stillTurning) < 0.01, kind .. " kept turning after the steer was let go")
			assert(math.abs(after) < 20, kind .. " turned " .. after .. " deg in the 0.5 s after letting go")
			local _, _, right = run(spec, 1, 1, 1, speed, 0)
			assert(right < -10, kind .. " did not turn right")
			-- No turn on the spot.
			local _, _, spot = run(spec, 1, 0, 1, 0, 0)
			assert(math.abs(spot) < 0.5, kind .. " turned " .. spot .. " deg standing still")
			-- S: brakes, then drives backwards.
			local braked = run(spec, 0.6, -1, 0, speed, 0)
			assert(braked < speed * 0.5, kind .. " did not brake: " .. braked)
			local back = run(spec, 3, -1, 0, 0, 0)
			assert(back < -spec.reverse * 0.8, kind .. " does not reverse: " .. back)
			table.insert(lines, string.format("%s straight (%.1f deg in 3 s), left/right, stops turning, brake + reverse", kind, turned))
		end
		-- (V9-0c review) Live, the cause itself: seated in the lab car with the aim 90 degrees to the side
		-- (the Studio hook AimTestPoint), the car does not turn. Before the fix it turned 80 degrees in 2 s.
		local Players = game:GetService("Players")
		local p = Players:GetPlayers()[1]
		local humanoid = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		local seat: VehicleSeat? = nil
		local pg = workspace:FindFirstChild("Playground")
		local lab = pg and pg:FindFirstChild("Lab1")
		for _, d in if lab then lab:GetDescendants() else {} do
			if d:IsA("VehicleSeat") and d:GetAttribute("LabCar") == "Car" then
				seat = d
			end
		end
		local live = "no live check (no player or car)"
		if p and humanoid and seat and seat.Parent and seat.Parent:IsA("Model") then
			local car = seat.Parent :: Model
			local home = car:GetPivot()
			local ok, err = pcall(function()
				car:PivotTo(home + Vector3.new(0, 1, 0))
				task.wait(0.3)
				;(seat :: VehicleSeat):Sit(humanoid)
				task.wait(1)
				local body = (seat :: VehicleSeat).AssemblyRootPart :: BasePart
				local function heading(): number
					local lv = body.CFrame.LookVector
					return math.deg(math.atan2(-lv.X, -lv.Z))
				end
				p:SetAttribute("AimTestPoint", body.Position + body.CFrame.RightVector * 40)
				local h0 = heading()
				task.wait(2)
				local turned = math.abs((heading() - h0 + 180) % 360 - 180)
				assert(turned < 3, string.format("seated with the aim to the side the car turned %.0f degrees", turned))
				live = string.format("seated + aim 90 deg to the side: turned %.1f deg", turned)
			end)
			p:SetAttribute("AimTestPoint", nil)
			local weld = (seat :: VehicleSeat):FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
			task.wait(0.3)
			car:PivotTo(home)
			assert(ok, err)
		end
		local kmh, gear = CarDrive.reading(40)
		assert(kmh == 40 and gear == "D" and select(2, CarDrive.reading(-5)) == "R" and select(2, CarDrive.reading(0)) == "N", "the gauge reads wrong")
		return table.concat(lines, "; ") .. "; gauge km/h and D/R/N; " .. live
	end,
}
