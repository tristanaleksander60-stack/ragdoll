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

-- F2 (owner, 26 Nov 2026: "hænderne flyver bare op i luften når man skyder dem i benene"; Config.HIT_REACT_V2): the
-- reaction is picked by the exact spot hit and where the shot came from, three variants a spot (the rig never plays
-- the same one twice in a row), scaled by the weapon's force (strength 0.6 light to 3 heavy). The arms come up ONLY
-- for a head or upper-chest hit (a protective flinch); a leg, hip, arm or back hit never lifts them.
--   spot: "foot" (foot or shin), "thigh", "belly" (hip or belly), "chest", "back", "arm" (forearm or hand),
--   "shoulder" (upper arm), "head", "side" (the trunk hit from the side).
Poses.HIT_SPOTS = { "foot", "thigh", "belly", "chest", "back", "arm", "shoulder", "head", "side" }

-- The spot for a struck part. front: the shot came from in front of the body; sideways: mostly from one side.
function Poses.spotOf(partName: string, front: boolean, sideways: boolean): string
	if partName == "Head" then
		return "head"
	elseif string.find(partName, "Foot", 1, true) or string.find(partName, "LowerLeg", 1, true) then
		return "foot"
	elseif string.find(partName, "UpperLeg", 1, true) then
		return "thigh"
	elseif string.find(partName, "UpperArm", 1, true) then
		return "shoulder"
	elseif string.find(partName, "LowerArm", 1, true) or string.find(partName, "Hand", 1, true) then
		return "arm"
	end
	if sideways then
		return "side"
	elseif not front then
		return "back"
	elseif partName == "LowerTorso" then
		return "belly"
	end
	return "chest"
end

function Poses.hitReact(spot: string, variant: number, side: number, limbSide: number, t: number, strength: number?): Pose
	local a = math.clamp(0.55 + 0.25 * (strength or 1), 0.7, 1.35)
	local function A(x: number, y: number, z: number): CFrame
		return ang(x * a, y * a, z * a)
	end
	local s = if limbSide > 0 then "Right" else "Left"
	local o = if limbSide > 0 then "Left" else "Right"
	local l = limbSide
	local v = variant
	local shake = sin(t * 26) * 3
	if spot == "foot" then
		if v == 1 then -- the leg kicks out
			return { [s .. "Hip"] = A(38, 0, 0), [s .. "Knee"] = A(-12, 0, 0), [o .. "Knee"] = A(-22, 0, 0), Waist = A(-6, 0, 4 * l), Neck = A(-12, 0, 0), [s .. "Shoulder"] = A(18, 0, 14 * l), [o .. "Shoulder"] = A(18, 0, -14 * l) }
		elseif v == 2 then -- a hop on the other leg
			return { [s .. "Hip"] = A(12, 0, 0), [s .. "Knee"] = A(-85, 0, 0), [o .. "Knee"] = A(-18 + shake, 0, 0), Waist = A(-4, 0, -6 * l), Neck = A(-10, 0, 0), [s .. "Shoulder"] = A(22, 0, 24 * l), [o .. "Shoulder"] = A(22, 0, -24 * l) }
		end -- the knee buckles
		return { [s .. "Hip"] = A(14, 0, 0), [s .. "Knee"] = A(-62, 0, 0), [o .. "Knee"] = A(-12, 0, 0), Waist = A(-10, 0, 9 * l), Neck = A(-18, 0, 0), [s .. "Shoulder"] = A(12, 0, 10 * l), [o .. "Shoulder"] = A(12, 0, -10 * l) }
	elseif spot == "thigh" then
		-- the knee buckles, the body dips to that side, a hand goes to the thigh
		local dip = if v == 2 then 1.3 else if v == 3 then 0.8 else 1
		return { [s .. "Hip"] = A(18 * dip, 0, 0), [s .. "Knee"] = A(-58 * dip, 0, 0), [o .. "Knee"] = A(if v == 3 then -30 else -10, 0, 0), Waist = A(-14, 0, 12 * l * dip), Neck = A(-22, 8 * l, 0), [s .. "Shoulder"] = A(28, 0, -4 * l), [s .. "Elbow"] = A(25, 0, 0), [o .. "Shoulder"] = A(if v == 2 then 14 else 6, 0, -12 * l) }
	elseif spot == "belly" then
		-- doubles over, a step back, both hands to the belly
		local d = if v == 2 then 1.25 else if v == 3 then 0.85 else 1
		return { Waist = A(-34 * d, if v == 3 then 10 * side else 0, 0), Neck = A(-22, 0, 0), RightShoulder = A(48, 0, -8), LeftShoulder = A(48, 0, 8), RightElbow = A(75, 0, 0), LeftElbow = A(75, 0, 0), RightHip = A(22 * d, 0, 0), LeftHip = A(22 * d, 0, 0), RightKnee = A(-24 * d, 0, 0), LeftKnee = A(-24 * d, 0, 0) }
	elseif spot == "chest" then
		-- jolts back, a step back, the shoulders curl (variant 3: the protective flinch, an upper-chest hit)
		if v == 3 then
			return { Waist = A(12, 0, 0), Neck = A(-16, -20 * side, 0), RightShoulder = A(78, 0, 18), LeftShoulder = A(78, 0, -18), RightElbow = A(105, 0, 0), LeftElbow = A(105, 0, 0) }
		end
		return { Waist = A(if v == 2 then 20 else 14, if v == 2 then -8 * side else 0, 0), Neck = A(-14, 0, 0), RightShoulder = A(22, 0, -6), LeftShoulder = A(22, 0, 6), RightElbow = A(35, 0, 0), LeftElbow = A(35, 0, 0), RightKnee = A(-10, 0, 0), LeftKnee = A(-10, 0, 0) }
	elseif spot == "back" then
		-- arches forward (the chest pushed out, the head back), stumbles a step forward
		return { Waist = A(if v == 2 then 22 else 16, if v == 3 then 10 * side else 0, 0), Neck = A(20, 0, 0), RightShoulder = A(-22, 0, 14), LeftShoulder = A(-22, 0, -14), RightElbow = A(12, 0, 0), LeftElbow = A(12, 0, 0), RightHip = A(if v == 1 then 18 else 6, 0, 0), RightKnee = A(-14, 0, 0) }
	elseif spot == "arm" then
		-- that arm swings back with the shot and the other hand clutches it; the rest barely moves
		return { [s .. "Shoulder"] = A(-38, 0, 26 * l), [s .. "Elbow"] = A(if v == 2 then 40 else 12, 0, 0), [o .. "Shoulder"] = A(52, 0, 22 * l), [o .. "Elbow"] = A(92, 0, 0), Neck = A(-14, -34 * l, 0), Waist = A(0, (if v == 3 then -14 else -6) * l, 0) }
	elseif spot == "shoulder" then
		-- the torso twists round with the shot
		return { Waist = A(0, -36 * l, if v == 2 then 6 * l else 0), Neck = A(-8, -22 * l, 0), [s .. "Shoulder"] = A(-26, 0, 18 * l), [s .. "Elbow"] = A(14, 0, 0), [o .. "Shoulder"] = A(if v == 3 then 40 else 16, 0, -8 * l), [o .. "Elbow"] = A(if v == 3 then 70 else 20, 0, 0) }
	elseif spot == "head" then
		-- snaps back (variant 2: the hands come up to the face; variant 3: the head is knocked to one side)
		if v == 2 then
			return { Neck = A(36, -14 * side, 6 * side), Waist = A(12, 0, 0), RightShoulder = A(120, 0, 22), LeftShoulder = A(120, 0, -22), RightElbow = A(115, 0, 0), LeftElbow = A(115, 0, 0) }
		elseif v == 3 then
			return { Neck = A(18, -42 * side, 18 * side), Waist = A(6, -10 * side, 0), RightKnee = A(-14, 0, 0), LeftKnee = A(-14, 0, 0) }
		end
		return { Neck = A(44, 0, 0), Waist = A(16, 0, 0), RightKnee = A(-12, 0, 0), LeftKnee = A(-12, 0, 0) }
	elseif spot == "side" then
		-- the body turns away from the shot, leaning off it
		return { Waist = A(-6, 30 * side, -10 * side), Neck = A(-10, 24 * side, 0), [if side > 0 then "LeftKnee" else "RightKnee"] = A(if v == 2 then -28 else -14, 0, 0), RightShoulder = A(10, 0, 8), LeftShoulder = A(10, 0, -8) }
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

-- F91 (BOWLING_12 0): the bowling ball: tucked tight, knees to the chest, arms round the shins, head down.
local curlOut: Pose = {}
function Poses.curl(_t: number): Pose
	local out = curlOut
	out.RightHip = ang(118, 0, 0)
	out.LeftHip = ang(118, 0, 0)
	out.RightKnee = ang(-135, 0, 0)
	out.LeftKnee = ang(-135, 0, 0)
	out.Waist = ang(-38, 0, 0)
	out.Neck = ang(-30, 0, 0)
	out.RightShoulder = ang(75, 0, -10)
	out.LeftShoulder = ang(75, 0, 10)
	out.RightElbow = ang(115, 0, 0)
	out.LeftElbow = ang(115, 0, 0)
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
-- Presses (24 Nov 2026, owner: it must look like CPR, not like humping): the knees and hips are dead still, the body
-- leans over the chest and stays there, the arms are locked straight with the hands on top of each other, and only the
-- shoulders drop a little: a quick short push, a full let-up, some 110 a minute, with a small breather now and then.
-- (THE v6 FIT PASS item 5, Config.BODY_FIT: the v6 patient is 1.6 deep, so its chest lies about 0.55 studs higher
-- than the old body's: the medic leans CPR_LIFT degrees less and lifts its straight arms a little, so the stacked
-- hands land ON the chest plate instead of sinking into it.)
local CPR_LIFT = 0
do
	local ok, cfg = pcall(function()
		return require(script.Parent.Parent:WaitForChild("Config")) :: any
	end)
	if ok and cfg and cfg.BODY_FIT and cfg.SMOOTH_BODY_V6 then
		CPR_LIFT = 13
	end
end
local function press(out: Pose, t: number, speed: number, depth: number)
	local beat = t * speed / (2 * math.pi)
	local rest = (beat % 18) > 16.2
	local f = beat % 1
	-- (Down in a third of the beat, up in the rest.)
	local p = if rest then 0 elseif f < 0.34 then math.sin(f / 0.34 * math.pi / 2) else math.cos((f - 0.34) / 0.66 * math.pi / 2)
	kneeling(out, -43 + CPR_LIFT - depth * p - (if rest then -5 else 0), -10 + depth * 0.5 * p)
	out.RightShoulder = ang(64 - CPR_LIFT * 0.4 - depth * 0.35 * p, 0, -19)
	out.LeftShoulder = ang(64 - CPR_LIFT * 0.4 - depth * 0.35 * p, 0, 19)
	out.RightElbow = ang(if rest then 12 else 2, 0, 0)
	out.LeftElbow = ang(if rest then 12 else 2, 0, 0)
end
local cprOut: Pose = {}
function Poses.cpr(t: number): Pose
	press(cprOut, t, 11.6, 6)
	return cprOut
end
function Poses.cprFast(t: number): Pose
	press(cprOut, t, 13.6, 5) -- (in a panic: quicker, a worried little shake of the head)
	cprOut.Neck = ang(-10, sin(t * 4) * 8, 0)
	return cprOut
end
-- One thump: the fist is lifted, held, comes down on the chest and stays; the other hand lies on the chest.
function Poses.cprSlam(t: number): Pose
	local c = t % 2.4
	local up = if c < 0.5 then c / 0.5 elseif c < 0.95 then 1 elseif c < 1.1 then 1 - (c - 0.95) / 0.15 else 0
	up = up * up * (3 - 2 * up)
	kneeling(cprOut, -42 + CPR_LIFT + 8 * up, -10 + 6 * up)
	cprOut.RightShoulder = ang(62 + 46 * up, 0, -12)
	cprOut.RightElbow = ang(6 + 62 * up, 0, 0)
	cprOut.LeftShoulder = ang(62, 0, 19)
	cprOut.LeftElbow = ang(6, 0, 0)
	return cprOut
end
-- One hand presses, the other lies on its forehead.
function Poses.cprOne(t: number): Pose
	press(cprOut, t, 10.6, 5)
	cprOut.LeftShoulder = ang(60, 0, -18)
	cprOut.LeftElbow = ang(14, 0, 0)
	cprOut.Neck = ang(-12, 24 + 4 * sin(t * 1.5), 0)
	return cprOut
end
-- An ear to the mouth, two fingers on the neck: quite still, listening.
function Poses.check(t: number): Pose
	kneeling(cprOut, -56 + sin(t * 1.4), -8)
	cprOut.Neck = ang(-8, 46, 4)
	cprOut.RightShoulder = ang(74, 0, -8)
	cprOut.LeftShoulder = ang(48, 0, -10)
	cprOut.RightElbow = ang(22, 0, 0)
	cprOut.LeftElbow = ang(48, 0, 0)
	return cprOut
end
-- A breath: it fills its chest, bends slowly down, stays a while at the mouth, and comes up again.
function Poses.breath(t: number): Pose
	local c = t % 2.6
	local d = if c < 0.5 then 0 elseif c < 1.1 then (c - 0.5) / 0.6 elseif c < 2.0 then 1 else 1 - (c - 2.0) / 0.6
	d = d * d * (3 - 2 * d)
	kneeling(cprOut, -30 - 34 * d, 6 - 20 * d)
	cprOut.RightShoulder = ang(56 + 14 * d, 0, 6)
	cprOut.LeftShoulder = ang(56 + 14 * d, 0, -6)
	cprOut.RightElbow = ang(34, 0, 0)
	cprOut.LeftElbow = ang(34, 0, 0)
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
-- Sitting on a bench, hands in the lap, looking about (bend 0..1: how far down it is).
local sitOut: Pose = {}
function Poses.sit(t: number, bend: number?): Pose
	local b = bend or 1
	local out = sitOut
	out.RightHip, out.LeftHip = ang(86 * b, 0, 4 * b), ang(86 * b, 0, -4 * b)
	out.RightKnee, out.LeftKnee = ang(-84 * b, 0, 0), ang(-84 * b, 0, 0)
	out.RightShoulder, out.LeftShoulder = ang(34 * b, 0, -4 * b), ang(34 * b, 0, 4 * b)
	out.RightElbow, out.LeftElbow = ang(44 * b, 0, 0), ang(44 * b, 0, 0)
	out.Waist = ang(4 * b + sin(t * 1.6) * 1.2, 0, 0)
	out.Neck = ang(0, sin(t * 0.55) * 26 * b, 0)
	return out
end
-- Riding the bike (BikeService): as sitting, leant forward, both hands on the handlebar.
local rideOut: Pose = {}
function Poses.ride(t: number, bend: number?): Pose
	local b = bend or 1
	local out = rideOut
	out.RightHip, out.LeftHip = ang(80 * b, 0, 7 * b), ang(80 * b, 0, -7 * b)
	out.RightKnee, out.LeftKnee = ang(-78 * b, 0, 0), ang(-78 * b, 0, 0)
	out.RightShoulder, out.LeftShoulder = ang(80 * b, 0, 7 * b), ang(80 * b, 0, -7 * b)
	out.RightElbow, out.LeftElbow = ang(10 * b, 0, 0), ang(10 * b, 0, 0)
	out.Waist = ang((-20 + sin(t * 5) * 1) * b, 0, 0)
	out.Neck = ang(14 * b, 0, 0)
	return out
end
-- (24 Nov 2026: first aid.) The two hands go round and round each other, as if winding a bandage.
local wrapOut: Pose = {}
local function winding(t: number, lift: number)
	local a, b = math.sin(t * 5.5), math.cos(t * 5.5)
	wrapOut.RightShoulder = ang(lift + 13 * a, 0, -10 + 13 * b)
	wrapOut.LeftShoulder = ang(lift - 13 * a, 0, 10 + 13 * b)
	wrapOut.RightElbow = ang(42 + 18 * b, 0, 0)
	wrapOut.LeftElbow = ang(42 - 18 * b, 0, 0)
end
function Poses.wrapHigh(t: number): Pose
	stand(wrapOut, -4, ang(4, 6 * math.sin(t * 2), 0), CFrame.identity, CFrame.identity, 0, 0)
	winding(t, 112)
	return wrapOut
end
function Poses.wrapMid(t: number): Pose
	stand(wrapOut, -14, ang(-16, 6 * math.sin(t * 2), 0), CFrame.identity, CFrame.identity, 0, 0)
	winding(t, 60)
	return wrapOut
end
function Poses.wrapLow(t: number): Pose
	kneeling(wrapOut, -32, -14 + 3 * math.sin(t * 2))
	winding(t, 58)
	return wrapOut
end
-- The one helped: the hurt arm held out, the eyes on it; or just still, a little sway.
local patientOut: Pose = {}
local function patient(t: number, side: number): Pose
	local s = math.sin(t * 9) * 1.5
	stand(patientOut, -3, ang(-10, -28 * side, 0), ang(if side > 0 then 58 + s else 4, 0, if side > 0 then 16 else 4),
		ang(if side < 0 then 58 + s else 4, 0, if side < 0 then -16 else -4), if side > 0 then 14 else 8, if side < 0 then 14 else 8)
	return patientOut
end
function Poses.patientLeft(t: number): Pose
	return patient(t, -1)
end
function Poses.patientRight(t: number): Pose
	return patient(t, 1)
end
function Poses.patientStill(t: number): Pose
	return patient(t, 0)
end

Poses.MOODS = { WrapHigh = Poses.wrapHigh, WrapMid = Poses.wrapMid, WrapLow = Poses.wrapLow, PatientLeft = Poses.patientLeft, PatientRight = Poses.patientRight, PatientStill = Poses.patientStill, Sit = Poses.sit, Ride = Poses.ride, Check = Poses.check, Breath = Poses.breath, CPRFast = Poses.cprFast, CPRSlam = Poses.cprSlam, CPROne = Poses.cprOne, Gasp = Poses.gasp, Point = Poses.point, Cheer = Poses.cheer, Relief = Poses.relief, Hug = Poses.hug, Despair = Poses.despair, Sky = Poses.sky, Rage = Poses.rage, Angry = Poses.fists, Box = Poses.box, Shock = Poses.shock, Mourn = Poses.mourn, CPR = Poses.cpr } :: { [string]: (number) -> Pose }

return Poses
