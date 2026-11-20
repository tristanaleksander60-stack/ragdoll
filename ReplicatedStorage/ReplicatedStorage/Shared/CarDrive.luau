--!strict
-- V9-0c (owner, 21 Nov 2026: "the car just drives round in a circle, fix it and make a speedometer"):
-- one step of the lab car's drive, pure (Client/VehicleClient runs it each frame on the driver's
-- screen; T153 runs it with no screen at all).
--   * The speed along the car's nose eases to the throttle's target; pressing against the way you
--     roll brakes harder; S from a stop drives backwards (reverse).
--   * The steer eases to the stick (STEER_RATE a second), so it is smooth and back at 0 within a
--     quarter second of letting go; the turn rate grows with speed (no turning on the spot) and
--     flips in reverse, as a real car's does.
--   * The cause of the circle was not here: a seated avatar's body was turned to the mouse, and the
--     body is welded to the car (AvatarMoves, V9-0c). This step never turns without a steer.

local CarDrive = {}

CarDrive.STEER_RATE = 4 -- steer units a second
CarDrive.TURN_FULL = 12 -- studs/s at which the turn is at full strength
CarDrive.BRAKE = 2.5 -- times the accel when pressing against the way you roll
CarDrive.KMH_PER_STUD = 1.0 -- km/h per stud/s (1 stud is about 0.28 m: 0.28 x 3.6)

export type Spec = { speed: number, reverse: number, accel: number, turn: number }

-- (along: speed along the nose now, steerNow: the eased steer now, throttle and steer: the input
-- from -1 to 1) -> the new speed along the nose, the new eased steer, the yaw rate (rad/s, + left).
function CarDrive.step(spec: Spec, along: number, steerNow: number, throttle: number, steer: number, dt: number): (number, number, number)
	local target = if throttle > 0 then spec.speed * throttle elseif throttle < 0 then spec.reverse * throttle else 0
	local braking = throttle ~= 0 and along * throttle < -0.5
	local rate = spec.accel * (if braking then CarDrive.BRAKE else 1)
	local newAlong = along + (target - along) * math.min(1, dt * rate)
	local want = math.clamp(steer, -1, 1)
	local delta = want - steerNow
	local maxStep = CarDrive.STEER_RATE * dt
	local newSteer = steerNow + math.clamp(delta, -maxStep, maxStep)
	if math.abs(newSteer) < 1e-3 and want == 0 then
		newSteer = 0
	end
	local strength = math.clamp(math.abs(newAlong) / CarDrive.TURN_FULL, 0, 1) * (if newAlong >= 0 then 1 else -1)
	local yawRate = -newSteer * spec.turn * strength
	return newAlong, newSteer, yawRate
end

-- The gauge's reading: km/h and the gear ("D", "R" or "N").
function CarDrive.reading(along: number): (number, string)
	local kmh = math.floor(math.abs(along) * CarDrive.KMH_PER_STUD + 0.5)
	local gear = if along > 0.5 then "D" elseif along < -0.5 then "R" else "N"
	return kmh, gear
end

return CarDrive
