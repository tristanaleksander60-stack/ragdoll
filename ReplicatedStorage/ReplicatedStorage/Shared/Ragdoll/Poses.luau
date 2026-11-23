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
-- (23 Nov 2026, owner: "hits you like a boxer".) Guard: fists up by the chin, bouncing. Box: straight punches in turn
-- out of it, the body turning with them.
local fistsOut: Pose = {}
function Poses.fists(t: number): Pose
	local bob = sin(t * 8) * 4
	local out = fistsOut
	out.RightShoulder = ang(55 + bob, 0, -12)
	out.LeftShoulder = ang(55 - bob, 0, 12)
	out.RightElbow = ang(115, 0, 0)
	out.LeftElbow = ang(115, 0, 0)
	out.Waist = ang(-10, 0, 0)
	out.Neck = ang(-4, 0, 0)
	return out
end
-- One straight punch: u 0..1 through it (out fast, held, back), side 1 = right, -1 = left. The other fist guards.
local punchOut: Pose = {}
function Poses.punch(u: number, side: number): Pose
	local x = if u < 0.12 then -0.35 * (u / 0.12) elseif u < 0.4 then -0.35 + 1.35 * ((u - 0.12) / 0.28) elseif u < 0.55 then 1 else 1 - (u - 0.55) / 0.45
	local hit = math.max(0, x)
	local hand, other = if side > 0 then "Right" else "Left", if side > 0 then "Left" else "Right"
	local out = punchOut
	out[hand .. "Shoulder"] = ang(55 + 45 * x, 0, side * (-12 + 10 * hit))
	out[hand .. "Elbow"] = ang(115 - 113 * hit, 0, 0)
	out[other .. "Shoulder"] = ang(58, 0, side * 14)
	out[other .. "Elbow"] = ang(120, 0, 0)
	out.Waist = ang(-10 - 12 * hit, side * 34 * x, 0)
	out.Neck = ang(0, side * -22 * x, 0)
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
-- (23 Nov 2026, owner: better CPR, and a different body every time.) Kneeling poses share the legs.
local function kneeling(out: Pose, waist: number, neck: number)
	out.RightHip = ang(20, 0, 4)
	out.LeftHip = ang(20, 0, -4)
	out.RightKnee = ang(-98, 0, 0)
	out.LeftKnee = ang(-98, 0, 0)
	out.Waist = ang(waist, 0, 0)
	out.Neck = ang(neck, 0, 0)
end
-- Presses: quick down, slower up, hands on top of each other, the whole back in it.
local function press(out: Pose, t: number, speed: number, depth: number)
	local p = (0.5 - 0.5 * math.cos(t * speed)) ^ 1.6
	kneeling(out, -30 - depth * p, -14 + 6 * p)
	out.RightShoulder = ang(72 + 14 * p, 0, -16)
	out.LeftShoulder = ang(72 + 14 * p, 0, 16)
	out.RightElbow = ang(16 - 16 * p, 0, 0)
	out.LeftElbow = ang(16 - 16 * p, 0, 0)
end
local cprOut: Pose = {}
function Poses.cpr(t: number): Pose
	press(cprOut, t, 11.5, 22)
	return cprOut
end
function Poses.cprFast(t: number): Pose
	press(cprOut, t, 19, 15) -- (in a panic, the head shaking)
	cprOut.Neck = ang(-10, sin(t * 9) * 22, 0)
	return cprOut
end
-- Both fists up over the head and down on the chest.
function Poses.cprSlam(t: number): Pose
	local up = (0.5 + 0.5 * math.cos(t * 5.5)) ^ 0.7
	kneeling(cprOut, -46 + 50 * up, -10 + 12 * up)
	cprOut.RightShoulder = ang(78 + 82 * up, 0, -14)
	cprOut.LeftShoulder = ang(78 + 82 * up, 0, 14)
	cprOut.RightElbow = ang(8 + 45 * up, 0, 0)
	cprOut.LeftElbow = ang(8 + 45 * up, 0, 0)
	return cprOut
end
-- One hand presses, the other holds its head.
function Poses.cprOne(t: number): Pose
	press(cprOut, t, 10, 18)
	cprOut.LeftShoulder = ang(125, 0, -25)
	cprOut.LeftElbow = ang(110, 0, 0)
	cprOut.Neck = ang(-14, 0, 10 * sin(t * 4))
	return cprOut
end
-- An ear to the mouth, two fingers on the neck.
function Poses.check(t: number): Pose
	kneeling(cprOut, -56 + 2 * sin(t * 3), -8)
	cprOut.Neck = ang(-8, 48, 0)
	cprOut.RightShoulder = ang(78, 0, -6)
	cprOut.LeftShoulder = ang(40, 0, -12)
	cprOut.RightElbow = ang(26, 0, 0)
	cprOut.LeftElbow = ang(60, 0, 0)
	return cprOut
end
-- A breath: up to fill the chest, down to the face.
function Poses.breath(t: number): Pose
	local d = 0.5 - 0.5 * math.cos(t * 5)
	kneeling(cprOut, -18 - 50 * d, 14 - 26 * d)
	cprOut.RightShoulder = ang(58 + 22 * d, 0, 6)
	cprOut.LeftShoulder = ang(58 + 22 * d, 0, -6)
	cprOut.RightElbow = ang(50, 0, 0)
	cprOut.LeftElbow = ang(50, 0, 0)
	return cprOut
end
local feelOut: Pose = {}
local function stand(out: Pose, waist: number, neck: CFrame, rs: CFrame, ls: CFrame, re: number, le: number)
	out.RightHip, out.LeftHip, out.RightKnee, out.LeftKnee = nil, nil, nil, nil
	out.Waist, out.Neck = ang(waist, 0, 0), neck
	out.RightShoulder, out.LeftShoulder = rs, ls
	out.RightElbow, out.LeftElbow = ang(re, 0, 0), ang(le, 0, 0)
end
-- Hands over the mouth.
function Poses.gasp(t: number): Pose
	local s = sin(t * 18) * 3
	stand(feelOut, 8, ang(4, 0, 0), ang(78 + s, 0, -22), ang(78 - s, 0, 22), 118, 118)
	return feelOut
end
-- Pointing at the body, the other hand on the head.
function Poses.point(t: number): Pose
	stand(feelOut, 6, ang(-10, sin(t * 10) * 8, 0), ang(62 + sin(t * 16) * 5, 0, 0), ang(150, 0, -30), 4, 85)
	return feelOut
end
-- Arms up, fists pumping.
function Poses.cheer(t: number): Pose
	local s = sin(t * 12)
	stand(feelOut, 8 + 5 * s, ang(16, 0, 0), ang(155 + 18 * s, 0, 18), ang(155 + 18 * s, 0, -18), 25 - 20 * s, 25 - 20 * s)
	return feelOut
end
-- Bent over, hands on the knees, catching its breath.
function Poses.relief(t: number): Pose
	local s = sin(t * 5)
	stand(feelOut, -38 + 5 * s, ang(-12 + 4 * s, 0, 0), ang(52, 0, 8), ang(52, 0, -8), 12, 12)
	return feelOut
end
-- Arms wide open for its friend.
function Poses.hug(t: number): Pose
	local s = sin(t * 6) * 8
	stand(feelOut, -6, ang(6, 0, s), ang(82, 0, 42 + s), ang(82, 0, -42 - s), 22, 22)
	return feelOut
end
-- Hands on the head, shaking it.
function Poses.despair(t: number): Pose
	stand(feelOut, -20, ang(-18, sin(t * 7) * 28, 0), ang(148, 0, 30), ang(148, 0, -30), 92, 92)
	return feelOut
end
-- On its knees, arms to the sky.
function Poses.sky(t: number): Pose
	local s = sin(t * 14) * 4
	kneeling(feelOut, 16, 28)
	feelOut.RightShoulder, feelOut.LeftShoulder = ang(140 + s, 0, 38), ang(140 - s, 0, -38)
	feelOut.RightElbow, feelOut.LeftElbow = ang(28, 0, 0), ang(28, 0, 0)
	return feelOut
end
-- Shaking with anger, fists down, leaning at you.
function Poses.rage(t: number): Pose
	local s = sin(t * 24) * 5
	stand(feelOut, -14 + s * 0.4, ang(-6, s, 0), ang(25 + s, 0, 28), ang(25 - s, 0, -28), 70, 70)
	return feelOut
end
Poses.MOODS = { Check = Poses.check, Breath = Poses.breath, CPRFast = Poses.cprFast, CPRSlam = Poses.cprSlam, CPROne = Poses.cprOne, Gasp = Poses.gasp, Point = Poses.point, Cheer = Poses.cheer, Relief = Poses.relief, Hug = Poses.hug, Despair = Poses.despair, Sky = Poses.sky, Rage = Poses.rage, Angry = Poses.fists, Box = Poses.box, Shock = Poses.shock, Mourn = Poses.mourn, CPR = Poses.cpr } :: { [string]: (number) -> Pose }

return Poses
