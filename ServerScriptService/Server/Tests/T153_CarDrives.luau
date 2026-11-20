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
	timeout = 10,
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
			local _, _, after = run(spec, 0.5, 1, 0, speed, steerNow)
			local _, s2, stillTurning = run(spec, 0.1, 1, 0, speed, 0)
			assert(s2 == 0 and math.abs(stillTurning) < 0.01, kind .. " kept turning after the steer was let go")
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
		local kmh, gear = CarDrive.reading(40)
		assert(kmh == 40 and gear == "D" and select(2, CarDrive.reading(-5)) == "R" and select(2, CarDrive.reading(0)) == "N", "the gauge reads wrong")
		return table.concat(lines, "; ") .. "; gauge km/h and D/R/N"
	end,
}
