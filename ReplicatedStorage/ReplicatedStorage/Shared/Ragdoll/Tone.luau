--!strict
-- Muscle tone per ragdoll state and joint group.
-- strength/damping map to AnimationConstraint.AngularStrength/AngularDamping
-- (1 = about 60 Hz and critically damped; 0.02 = floppy noodle).
-- balance is the upright torque as a multiple of (mass * gravity * 3 studs).

export type JointTone = {
	kinematic: boolean,
	strength: number,
	damping: number,
	maxTorque: number,
}

export type Group = "root" | "core" | "arm" | "leg"

local GROUP_OF: { [string]: Group } = {
	Root = "root",
	Waist = "core",
	Neck = "core",
	LeftShoulder = "arm",
	RightShoulder = "arm",
	LeftElbow = "arm",
	RightElbow = "arm",
	LeftWrist = "arm",
	RightWrist = "arm",
	LeftHip = "leg",
	RightHip = "leg",
	LeftKnee = "leg",
	RightKnee = "leg",
	LeftAnkle = "leg",
	RightAnkle = "leg",
}

local function tone(kinematic: boolean, strength: number, damping: number, maxTorque: number): JointTone
	return table.freeze({ kinematic = kinematic, strength = strength, damping = damping, maxTorque = maxTorque })
end

local RIGID = tone(true, 1, 1, 3000)
-- The root joint ties the invisible, massless HumanoidRootPart to the pelvis; it just follows.
local FOLLOW = tone(false, 1, 1, 100000)

local PROFILES: { [string]: { [Group]: JointTone } } = {
	Standing = { root = RIGID, core = RIGID, arm = RIGID, leg = RIGID },
	Flinch = {
		root = FOLLOW,
		core = tone(false, 0.5, 0.45, 3000),
		arm = tone(false, 0.45, 0.55, 3000),
		leg = RIGID,
	},
	Stumble = {
		root = FOLLOW,
		core = tone(false, 0.35, 0.5, 3000),
		arm = tone(false, 0.4, 0.5, 3000),
		leg = tone(false, 0.55, 0.7, 3000),
	},
	-- Ragdoll while flying: enough tone to windmill, still floppy on impact.
	Airborne = {
		root = FOLLOW,
		core = tone(false, 0.2, 0.5, 3000),
		arm = tone(false, 0.3, 0.45, 3000),
		leg = tone(false, 0.22, 0.45, 3000),
	},
	-- Hanging from a grab: soft enough that gravity and swinging win, firm enough to kick.
	Held = {
		root = FOLLOW,
		core = tone(false, 0.12, 0.4, 3000),
		arm = tone(false, 0.1, 0.35, 3000),
		leg = tone(false, 0.14, 0.4, 3000),
	},
	Ragdoll = {
		root = FOLLOW,
		core = tone(false, 0.035, 0.3, 3000),
		arm = tone(false, 0.02, 0.3, 3000),
		leg = tone(false, 0.025, 0.3, 3000),
	},
	-- Crawling on both broken legs: the upper body is rigid and its arms are animated (kinematic
	-- joints follow Transform exactly); the legs trail behind.
	Crawl = {
		root = RIGID,
		core = RIGID,
		arm = RIGID,
		leg = tone(false, 0.03, 0.3, 3000),
	},
}

local BALANCE: { [string]: number } = {
	Standing = 40,
	Flinch = 4,
	Stumble = 0.3,
	Ragdoll = 0,
	Airborne = 0,
	Held = 0,
	Crawl = 40,
}

local Tone = {}

function Tone.groupOf(jointName: string): Group?
	return GROUP_OF[jointName]
end

function Tone.get(profile: string, jointName: string): JointTone?
	local group = GROUP_OF[jointName]
	local p = PROFILES[profile]
	if not group or not p then
		return nil
	end
	return p[group]
end

function Tone.balance(profile: string): number
	return BALANCE[profile] or 0
end

Tone.STANDING_BALANCE = BALANCE.Standing

return table.freeze(Tone)
