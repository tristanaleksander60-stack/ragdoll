--!strict
-- Target poses for the active ragdoll, as AnimationConstraint.Transform per joint.
-- Measured on AJU R15 rigs (Nov 2026):
--   shoulders: +X raises the arm forward; Z raises it sideways (right +Z, left -Z)
--   elbows: +X bends; knees: -X bends (BallSocket twist limits enforce these ranges)
--   hips: +X swings the leg forward; neck: -X tucks the chin, +X looks up
-- Transform does not replicate, so poses only matter on the machine that simulates the rig
-- and only while the joints are non-kinematic.
-- The poses played every frame (brace, flail, dangle, kneel, sitUp) fill one table each instead
-- of making a new one per frame; use the result at once (applyPose does) and do not keep it.

export type Pose = { [string]: CFrame }

local rad = math.rad
local sin = math.sin

local function ang(x: number, y: number, z: number): CFrame
	return CFrame.Angles(rad(x), rad(y), rad(z))
end

local Poses = {}

Poses.REST = table.freeze({}) :: Pose

-- Small hit: forearms up in front of the face, head turned away from the hit.
-- side: +1 if the hit came from the dummy's right, -1 from its left.
function Poses.guard(side: number): Pose
	return {
		RightShoulder = ang(80, 0, 20),
		LeftShoulder = ang(80, 0, -20),
		RightElbow = ang(110, 0, 0),
		LeftElbow = ang(110, 0, 0),
		Neck = ang(-15, -30 * side, 0),
		Waist = ang(-8, 0, 0),
	}
end

export type Region = "head" | "torso" | "arm" | "leg"

local REGION_OF: { [string]: Region } = {
	Head = "head",
	UpperTorso = "torso",
	LowerTorso = "torso",
	HumanoidRootPart = "torso",
	LeftUpperArm = "arm",
	LeftLowerArm = "arm",
	LeftHand = "arm",
	RightUpperArm = "arm",
	RightLowerArm = "arm",
	RightHand = "arm",
	LeftUpperLeg = "leg",
	LeftLowerLeg = "leg",
	LeftFoot = "leg",
	RightUpperLeg = "leg",
	RightLowerLeg = "leg",
	RightFoot = "leg",
}

function Poses.regionOf(partName: string): Region
	return REGION_OF[partName] or "torso"
end

-- A small hit reacts where it landed.
--   head:  head snaps back, both hands fly up to it
--   torso: curls around the hit, forearms up (guard)
--   arm:   the struck arm swings back, the head turns to look at it
--   leg:   that knee buckles, arms go out for balance
-- side: +1 if the hit came from the dummy's right; limbSide: +1 if the struck limb is the right one.
function Poses.flinch(region: Region, side: number, limbSide: number, t: number): Pose
	if region == "head" then
		return {
			Neck = ang(42, -18 * side, 8 * side), -- (V9-NOW: snaps further back, it reads from the shooter)
			Waist = ang(14, 0, 0),
			RightShoulder = ang(140, 0, 25),
			LeftShoulder = ang(140, 0, -25),
			RightElbow = ang(120, 0, 0),
			LeftElbow = ang(120, 0, 0),
		}
	elseif region == "arm" then
		local struck = if limbSide > 0 then "Right" else "Left"
		local other = if limbSide > 0 then "Left" else "Right"
		return {
			[struck .. "Shoulder"] = ang(-35, 0, 45 * limbSide),
			[struck .. "Elbow"] = ang(15, 0, 0),
			[other .. "Shoulder"] = ang(60, 0, -15 * limbSide),
			[other .. "Elbow"] = ang(80, 0, 0),
			Neck = ang(-10, -45 * limbSide, 0),
			Waist = ang(0, -22 * limbSide, 0), -- (V9-NOW: the trunk turns with the struck arm)
		}
	elseif region == "leg" then
		local struck = if limbSide > 0 then "Right" else "Left"
		local wobble = sin(t * 30) * 8
		return {
			[struck .. "Hip"] = ang(28, 0, 0),
			[struck .. "Knee"] = ang(-55, 0, 0),
			RightShoulder = ang(15, 0, 70 + wobble),
			LeftShoulder = ang(15, 0, -70 + wobble),
			RightElbow = ang(15, 0, 0),
			LeftElbow = ang(15, 0, 0),
			Neck = ang(-25, 0, 0),
			Waist = ang(-6, 0, 6 * limbSide),
		}
	end
	return Poses.guard(side)
end

-- Losing balance: arms out in front to catch the fall, chin tucked, knees soft.
local braceOut: Pose = {}
function Poses.brace(t: number): Pose
	local wobble = sin(t * 9) * 12
	local out = braceOut
	out.RightShoulder = ang(65 + wobble, 0, 30)
	out.LeftShoulder = ang(65 - wobble, 0, -30)
	out.RightElbow = ang(20, 0, 0)
	out.LeftElbow = ang(20, 0, 0)
	out.Neck = ang(-20, 0, 0)
	out.RightHip = ang(15, 0, 0)
	out.LeftHip = ang(15, 0, 0)
	out.RightKnee = ang(-30, 0, 0)
	out.LeftKnee = ang(-30, 0, 0)
	return out
end

-- V9-P3 (fix round 1): about to land: both arms straight out ahead to take the ground (no wobble,
-- elbows nearly locked), chin tucked, the trunk curled a little, hips and knees bent to soak it up. Held
-- from about a third of a second before impact through the first contact (ActiveRagdoll catchUntil).
local catchOut: Pose = {}
function Poses.catch(_t: number): Pose
	local out = catchOut
	out.RightShoulder = ang(100, 0, 22)
	out.LeftShoulder = ang(100, 0, -22)
	out.RightElbow = ang(10, 0, 0)
	out.LeftElbow = ang(10, 0, 0)
	out.Neck = ang(-28, 0, 0)
	out.Waist = ang(-12, 0, 0)
	out.RightHip = ang(30, 0, 0)
	out.LeftHip = ang(30, 0, 0)
	out.RightKnee = ang(-45, 0, 0)
	out.LeftKnee = ang(-45, 0, 0)
	return out
end

-- In the air: cartoon windmill arms and bicycling legs.
local flailOut: Pose = {}
function Poses.flail(t: number): Pose
	local a = sin(t * 13)
	local b = sin(t * 13 + math.pi)
	local l = sin(t * 10)
	local out = flailOut
	out.RightShoulder = ang(60 + 40 * a, 0, 70)
	out.LeftShoulder = ang(60 + 40 * b, 0, -70)
	out.RightElbow = ang(30 + 30 * a, 0, 0)
	out.LeftElbow = ang(30 + 30 * b, 0, 0)
	out.RightHip = ang(35 + 30 * l, 0, 0)
	out.LeftHip = ang(35 - 30 * l, 0, 0)
	out.RightKnee = ang(-40 - 30 * l, 0, 0)
	out.LeftKnee = ang(-40 + 30 * l, 0, 0)
	out.Neck = ang(15, 0, 10 * a)
	return out
end

-- Held up by a grab: legs kick and pedal, arms flap, head looks down at the drop.
-- Slower and smaller than flail so it reads as dangling, not flying.
local dangleOut: Pose = {}
function Poses.dangle(t: number): Pose
	local kick = sin(t * 8)
	local flap = sin(t * 6.5)
	local shake = sin(t * 17) * 6
	local out = dangleOut
	out.RightHip = ang(20 + 35 * kick, 0, 6)
	out.LeftHip = ang(20 - 35 * kick, 0, -6)
	out.RightKnee = ang(-35 - 30 * kick, 0, 0)
	out.LeftKnee = ang(-35 + 30 * kick, 0, 0)
	out.RightShoulder = ang(25 + 20 * flap, 0, 40 + 15 * flap)
	out.LeftShoulder = ang(25 - 20 * flap, 0, -40 - 15 * flap)
	out.RightElbow = ang(35, 0, 0)
	out.LeftElbow = ang(35, 0, 0)
	out.Neck = ang(-25, shake, 0)
	out.Waist = ang(-6, 0, 0)
	return out
end

-- Getting up from lying face down: on the knees, hands pushing on the ground, head up.
local kneelOut: Pose = {}
function Poses.kneel(t: number): Pose
	local push = sin(t * 18) * 6 -- a little effort shake
	local out = kneelOut
	out.RightHip = ang(10, 0, 0)
	out.LeftHip = ang(10, 0, 0)
	out.RightKnee = ang(-95, 0, 0)
	out.LeftKnee = ang(-95, 0, 0)
	out.Waist = ang(-25, 0, 0)
	out.RightShoulder = ang(45 + push, 0, 15)
	out.LeftShoulder = ang(45 - push, 0, -15)
	out.RightElbow = ang(10, 0, 0)
	out.LeftElbow = ang(10, 0, 0)
	out.Neck = ang(25, 0, 0)
	return out
end

-- Getting up from lying face up: sitting with legs out, hands behind on the ground.
local sitUpOut: Pose = {}
function Poses.sitUp(t: number): Pose
	local shake = sin(t * 18) * 5
	local out = sitUpOut
	out.RightHip = ang(80, 0, 8)
	out.LeftHip = ang(80, 0, -8)
	out.RightKnee = ang(-25, 0, 0)
	out.LeftKnee = ang(-25, 0, 0)
	out.Waist = ang(-10, 0, 0)
	out.RightShoulder = ang(-20 + shake, 0, 25)
	out.LeftShoulder = ang(-20 - shake, 0, -25)
	out.RightElbow = ang(5, 0, 0)
	out.LeftElbow = ang(5, 0, 0)
	out.Neck = ang(-10, 0, 0)
	return out
end


-- (V11 item 13, owner: "ragdolls get scared of the dead, mourn their mates, kneel and say oh noo, try CPR"):
-- poses held in the Standing state while the body's Mood attribute says so (Server/Mourning sets it).
-- Shock: hands up to the head, leaning back. Mourn: on its knees, head bowed, shoulders shaking. CPR: on its
-- knees, leaning over, straight arms pumping down.
local shockOut: Pose = {}
function Poses.shock(t: number): Pose
	local shake = sin(t * 20) * 4
	local out = shockOut
	out.RightShoulder = ang(150 + shake, 0, 35)
	out.LeftShoulder = ang(150 - shake, 0, -35)
	out.RightElbow = ang(80, 0, 0)
	out.LeftElbow = ang(80, 0, 0)
	out.Waist = ang(10, 0, 0)
	out.Neck = ang(12, 0, 0)
	return out
end
local mournOut: Pose = {}
function Poses.mourn(t: number): Pose
	local sob = sin(t * 7) * 4
	local out = mournOut
	out.RightHip = ang(10, 0, 0)
	out.LeftHip = ang(10, 0, 0)
	out.RightKnee = ang(-95, 0, 0)
	out.LeftKnee = ang(-95, 0, 0)
	out.Waist = ang(-18 + sob * 0.5, 0, 0)
	out.Neck = ang(-28, 0, 0)
	out.RightShoulder = ang(30 + sob, 0, 10)
	out.LeftShoulder = ang(30 - sob, 0, -10)
	out.RightElbow = ang(35, 0, 0)
	out.LeftElbow = ang(35, 0, 0)
	return out
end
local cprOut: Pose = {}
function Poses.cpr(t: number): Pose
	local pump = sin(t * 11)
	local out = cprOut
	out.RightHip = ang(20, 0, 0)
	out.LeftHip = ang(20, 0, 0)
	out.RightKnee = ang(-95, 0, 0)
	out.LeftKnee = ang(-95, 0, 0)
	out.Waist = ang(-38 - pump * 6, 0, 0)
	out.Neck = ang(-12, 0, 0)
	out.RightShoulder = ang(75 + pump * 6, 0, 8)
	out.LeftShoulder = ang(75 + pump * 6, 0, -8)
	out.RightElbow = ang(0, 0, 0)
	out.LeftElbow = ang(0, 0, 0)
	return out
end
-- (23 Nov 2026, owner: "hits you like a boxer".) Guard: fists up by the chin, bouncing. Box: straight punches in turn
-- out of it, the body turning with them.
local guardOut: Pose = {}
function Poses.guard(t: number): Pose
	local bob = sin(t * 8) * 4
	local out = guardOut
	out.RightShoulder = ang(55 + bob, 0, -12)
	out.LeftShoulder = ang(55 - bob, 0, 12)
	out.RightElbow = ang(115, 0, 0)
	out.LeftElbow = ang(115, 0, 0)
	out.Waist = ang(-10, 0, 0)
	out.Neck = ang(-4, 0, 0)
	return out
end
local boxOut: Pose = {}
function Poses.box(t: number): Pose
	local wave = sin(t * 8.4) -- (a punch every half of HIT_GAP, right and left in turn)
	local r = math.max(0, wave) ^ 0.6
	local l = math.max(0, -wave) ^ 0.6
	local out = boxOut
	out.RightShoulder = ang(55 + 38 * r, 0, -12 + 8 * r)
	out.LeftShoulder = ang(55 + 38 * l, 0, 12 - 8 * l)
	out.RightElbow = ang(115 - 110 * r, 0, 0)
	out.LeftElbow = ang(115 - 110 * l, 0, 0)
	out.Waist = ang(-12, 22 * (r - l), 0)
	out.Neck = ang(-4, -12 * (r - l), 0)
	return out
end
Poses.MOODS = { Angry = Poses.guard, Box = Poses.box, Shock = Poses.shock, Mourn = Poses.mourn, CPR = Poses.cpr } :: { [string]: (number) -> Pose }

return Poses
