--!strict
-- ActiveRagdoll drives an R15 rig built with Avatar Joint Upgrade joints
-- (AnimationConstraint + BallSocketConstraint) through these states:
--
--   Standing -> Flinch    (small hit: guard pose, springs back)
--   Standing -> Stumble   (medium hit: brace pose, weak balance, may recover or fall)
--   any      -> Ragdoll   (big hit, tipped over or grabbed: limp; windmills while flying)
--   Ragdoll  -> GettingUp (body at rest: kneels or sits up, then stands)
--   Flinch/Stumble -> Recovering -> Standing
--   any      -> Frozen    (freeze ray: rigid ice statue)
--   Ragdoll  -> Out       (a hard knock to the head, or a huge hit: out cold for a few seconds)
--
-- A lab dummy (it has a Home) also gets about on its own (see the brain below):
--   Standing -> Walking   (away from home: walks back, limping on one broken leg)
--   Standing -> Fleeing   (hurt a moment ago and someone comes close: runs away from them)
--   Ragdoll  -> Crawling  (both legs broken: drags itself along on its arms)
-- The simulator only moves the body (pelvis height, heading, speed); every screen animates the
-- legs and arms itself (DummyLife), because Transform does not replicate.
--
-- Limbs can break (noodle limbs): the joint stays floppy until healed.
--
-- It runs on the machine that simulates the rig: the owning player's client, or the server for
-- unowned dummies. Joint Transform does not replicate, so poses only exist on the simulator.
-- Which joints are kinematic changes the body's assemblies; the simulator reports every change
-- through onTransition so the server can mirror it (see Topology) and replication stays exact.

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Tone = require(script.Parent.Tone)
local Config = require(script.Parent.Config)
local Poses = require(script.Parent.Poses)
local Anatomy = require(script.Parent.Parent.Anatomy)
local GunThreat = require(script.Parent.Parent.GunThreat)
local GameConfig = require(script.Parent.Parent.Config)

export type State = "Standing" | "Walking" | "Fleeing" | "Crawling" | "Flinch" | "Stumble" | "Ragdoll" | "Out" | "GettingUp" | "Recovering" | "Frozen"

type Ramp = { [AnimationConstraint]: { strength: number, damping: number } }

type Rig = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	pelvis: BasePart,
	chest: BasePart,
	joints: { [string]: AnimationConstraint },
	parts: { BasePart },
	mass: number,
	standOffset: number,
	balance: AlignOrientation,
	lift: AlignPosition,
	drive: LinearVelocity, -- moves the body along the ground while walking, fleeing or crawling
	created: { Instance },
	connections: { RBXScriptConnection },
	state: State,
	stateTime: number,
	calmTime: number,
	ramp: Ramp,
	rampBalanceFrom: number,
	rampDuration: number,
	hitSide: number,
	hitRegion: Poses.Region,
	hitLimbSide: number, -- +1 right limb, -1 left limb (arm and leg hits)
	airborne: boolean,
	groundY: number,
	sinkCheckAt: number, -- stateTime of the last sunk-legs check (Standing)
	faceDown: boolean,
	rayParams: RaycastParams,
	broken: { [string]: boolean },
	frozenWelds: { WeldConstraint }?, -- only when this machine made the welds
	frozenLooks: { [BasePart]: { color: Color3, material: Enum.Material } }?,
	held: number, -- grab handles currently holding the rig
	limpProfile: string, -- "Ragdoll" | "Airborne" | "Held" while in the Ragdoll state
	speedCap: number, -- after a hit: the body may not go faster than the hit sent it...
	speedCapUntil: number, -- ...until this time (os.clock)
	speedCapHard: boolean, -- a physical hit (prop, machine): also in the air, no carry-over
	stayDown: boolean, -- lies limp until told to get up (a player who ragdolled on purpose)
	lastHitAt: number, -- os.clock of the last hit that hurt (a hurt dummy runs from people)
	koUntil: number, -- out cold until (os.clock)
	lastImpulseAt: number, -- os.clock of the last hit or push (impacts are measured after it)
	lastImpactAt: number, -- os.clock of the last impact that hurt
	impactSpeeds: { [BasePart]: Vector3 }, -- last step's velocities of the parts impacts are read on
	impactCheckedAt: number,
	pendingLimb: BasePart?, -- struck hard while being launched: breaks at the impact
	pendingKO: boolean, -- knocked hard while being launched: out cold at the impact
	pendingUntil: number,
	fleeFrom: Vector3?, -- where the danger is while fleeing
	fleeUntil: number,
	fledAt: number, -- when it last stopped fleeing (it does not flee again straight away)
	gunFledAt: number, -- when it last ran from a gun (it keeps its distance a while)
	gunLookAt: number, -- next look for a gun (a few times a second)
	gunWary: boolean, -- keeping away from a gun pointed at its home (till the next look)
	panicking: boolean, -- running from something it saw or heard (PanicFrom), not from a person
	speed: number, -- current ground speed while getting about (studs/s), eased
	heading: Vector3, -- flat direction it faces while getting about
	stuckTime: number, -- s without progress towards the goal (steers round obstacles)
	bestDistance: number,
	steer: number, -- detour angle (radians) around something in the way
	steerUntil: number, -- keeps to the detour until this time
	arriveTime: number, -- s at home turning to face the lab
	-- (V9-P fix round 1.)
	limpUntil: number?, -- a leg round: it limps on until then (SHOT_FLINCH)
	lastShotDir: Vector3?, -- the last round's push (flat), carried into the death fall
	lastShotAt: number?,
	bracing: boolean?, -- falling, about to land: arms out (Poses.catch)
	catchUntil: number?, -- landed from a brace: the arms keep their tone until then
	pushedAt: number?, -- the last ActiveRagdoll.push (a fan, a conveyor): no settle assist just after
	swaySeed: number?, -- a hurt body's own sway phase (swayUp)
}

-- V9-0ac fix round 1 (SHOT_FLINCH):
local LEG_LIMP_TIME = 4 -- s a leg round makes it limp on
local GUN_LOCAL_MAX = 28 -- studs/s a round's own jerk may give the struck part (a hand weighs 1/50 of the trunk)
local DEATH_PUSH = 9 -- studs/s the killing round's push carries into the fall (it falls away from the shot)
local DEATH_PUSH_WINDOW = 0.8 -- s after a round that a death still counts as that round's

-- Hit thresholds as change in body speed (studs/s) that the impulse would give the whole body.
local FLINCH_MAX = 10
local STUMBLE_MAX = 30
local MAX_LINEAR_SPEED = Config.MAX_LINEAR_SPEED
local MAX_ANGULAR_SPEED = 40
local TIP_TO_RAGDOLL_DEG = 55
local CALM_SPEED = 1.5
local CALM_TIME = 0.6
local MIN_RAGDOLL_TIME = 1.2
local AIR_CLEARANCE = Config.AIR_CLEARANCE
local GETUP_TIME = 1.15
local GETUP_FIRST_STAGE = 0.55 -- kneel (face down) or sit up (face up), then rise
local MUSCLE_TORQUE = 3000
-- Share of a hit that moves the whole body; the rest hits the struck part.
local BODY_SHARE: { [string]: number } = { Flinch = 0.1, Stumble = 0.55, Ragdoll = 0.75 }
-- Noodle limbs: a hard enough hit straight on a limb breaks the joint above it.
local BREAK_LOCAL_SPEED = 250 -- studs/s the struck limb alone would get (Launch yes, Shove no)
local MAX_BROKEN = 2
-- Hurt by the landing, not the launch: a hit that sends the body flying (the whole body gets at least
-- LAUNCH_SPEED studs/s, after the floor has taken any push into it) does no damage itself; the damage
-- comes when the body hits something hard, measured as the speed a part loses in one step (a floor,
-- a wall, a ceiling, a fall from a tower). A blow that cannot send it anywhere (a hammer on a body
-- lying on the floor) hurts at once.
local LAUNCH_SPEED = 30
local IMPACT_MIN_SPEED = 18 -- studs/s a part must have had for its stop to count as an impact
local BREAK_IMPACT = 52 -- a limb that loses this much speed at once breaks
local HEAD_KO_IMPACT = 46 -- the head stopping this hard: out cold
local KO_IMPACT = 68 -- the whole body (pelvis) stopping this hard: out cold
local IMPACT_GAP = 0.4 -- s between two impacts that hurt (one landing is one impact)
local IMPACT_AFTER_HIT = 0.25 -- s after a hit before stops count (the hit itself, and the body yanking the struck part back, change speeds)
-- What the launching hit did is not lost: the limb it struck hard breaks, and a knock to the head
-- (or a huge hit) knocks it out, when the flight ends: the trunk's (pelvis or head) velocity changing
-- by this much in one step, or the body coming to rest (a limb flailing in the air does not count).
local PENDING_IMPACT = 22
local PUSH_IMPULSE_MIN = 15 -- studs/s: a push smaller than this (wind, a magnet) is not a hit
local PENDING_TIME = 5 -- s a pending injury waits for its impact
local BREAKABLE: { [string]: string } = { -- struck part -> joint that breaks
	LeftUpperArm = "LeftShoulder",
	RightUpperArm = "RightShoulder",
	LeftLowerArm = "LeftElbow",
	RightLowerArm = "RightElbow",
	LeftHand = "LeftElbow",
	RightHand = "RightElbow",
	LeftUpperLeg = "LeftHip",
	RightUpperLeg = "RightHip",
	LeftLowerLeg = "LeftKnee",
	RightLowerLeg = "RightKnee",
	LeftFoot = "LeftKnee",
	RightFoot = "RightKnee",
}
local NOODLE_STRENGTH = 0.012
local GROUND_PUSH_MAX = 10 -- studs/s a hit may push a grounded body down into the floor
local BODY_FRICTION = 0.75
local BODY_FRICTION_WEIGHT = 3 -- the body's friction wins over the floor's
local FROZEN_TIME = Config.FROZEN_TIME
local ICE_COLOR = Config.ICE_COLOR
-- Getting about: tuning in Config.GetAbout.
local GetAbout = Config.GetAbout
local WALK_SPEED = GetAbout.WALK_SPEED
local LIMP_SPEED = GetAbout.LIMP_SPEED
local CRAWL_SPEED = GetAbout.CRAWL_SPEED
local FLEE_SPEED = GetAbout.FLEE_SPEED
local LIMP_FLEE_SPEED = GetAbout.LIMP_FLEE_SPEED
local CRAWL_FLEE_SPEED = GetAbout.CRAWL_FLEE_SPEED
local SPEED_EASE = GetAbout.SPEED_EASE
local HOME_LEAVE = GetAbout.HOME_LEAVE
local HOME_ARRIVE = GetAbout.HOME_ARRIVE
local ARRIVE_TURN_MAX = GetAbout.ARRIVE_TURN_MAX
local LOOK_AROUND_TIME = GetAbout.LOOK_AROUND_TIME
local FLEE_RADIUS = GetAbout.FLEE_RADIUS
local FLEE_MEMORY = GetAbout.FLEE_MEMORY
local FLEE_TIME = GetAbout.FLEE_TIME
local FLEE_REST = GetAbout.FLEE_REST
local GUN_FLEE = 2.5 -- s a coward runs from a gun held out close by (round 3, M3)
local GUN_WARY = 20 -- s after running from a gun that a coward keeps away from one pointed at its home
local CRAWL_HEIGHT = GetAbout.CRAWL_HEIGHT
local WALK_HOVER = GetAbout.WALK_HOVER
local LEDGE_DROP = GetAbout.LEDGE_DROP
local STUCK_DETOUR = GetAbout.STUCK_DETOUR
local DETOUR_ANGLE = GetAbout.DETOUR_ANGLE
local DETOUR_TIME = GetAbout.DETOUR_TIME
local CRAWL_PITCH = GetAbout.CRAWL_PITCH
local TRIP_DEG = GetAbout.TRIP_DEG
local KO_HEAD_SPEED = GetAbout.KO_HEAD_SPEED
local KO_SPEED = GetAbout.KO_SPEED
local KO_MIN = GetAbout.KO_MIN
local KO_MAX = GetAbout.KO_MAX
local LEG_JOINTS = { Left = { "LeftHip", "LeftKnee" }, Right = { "RightHip", "RightKnee" } }

local ActiveRagdoll = {}

-- Effects listener: ("Land" | "Break" | "Shatter", model, position, speed).
ActiveRagdoll.onEvent = nil :: ((kind: string, model: Model, position: Vector3, speed: number) -> ())?
-- V8-0.2: hits left that knock a dummy flat whatever they are (the client sets it for a newcomer).
ActiveRagdoll.firstHitsLeft = 0
-- True only around the player's own hit (PokeController): hazards, the mace, visitors and server
-- hits never use up the first hits (blind review, 21 Nov).
ActiveRagdoll.ownHit = false
ActiveRagdoll.FIRST_HIT_PUSH = 20 -- studs/s (Config.FIRST_HIT_PUSH; the client copies it)
-- Topology listener: called on every state change and every break/heal with the new state and
-- the list of broken joints. The owning client forwards this to the server.
ActiveRagdoll.onTransition = nil :: ((model: Model, state: State, broken: { string }, held: boolean) -> ())?

-- More topology listeners (a player's own body); each gets the same calls as onTransition.
local transitionListeners: { (model: Model, state: State, broken: { string }, held: boolean) -> () } = {}

function ActiveRagdoll.addTransitionListener(listener: (model: Model, state: State, broken: { string }, held: boolean) -> ()): () -> ()
	table.insert(transitionListeners, listener)
	return function()
		local i = table.find(transitionListeners, listener)
		if i then
			table.remove(transitionListeners, i)
		end
	end
end

local rigs: { [Model]: Rig } = {}
local connection: RBXScriptConnection? = nil

local function gravityTorque(rig: Rig, factor: number): number
	return factor * rig.mass * Config.NORMAL_GRAVITY * 3
end

local function tiltDegrees(rig: Rig): number
	local up = rig.pelvis.CFrame.UpVector.Y
	return math.deg(math.acos(math.clamp(up, -1, 1)))
end

local function torsoSpeed(rig: Rig): number
	return math.max(rig.pelvis.AssemblyLinearVelocity.Magnitude, rig.chest.AssemblyLinearVelocity.Magnitude)
end

-- V9-P2: a limp body lying on the ground and only slowly moving loses its energy the way a soft
-- body does (no long rolling and rocking after a big fall): every assembly's speed and spin ease
-- off by SETTLE_DAMP per second below SETTLE_SPEED. Flying, held or fast bodies are never touched.
-- Limp bodies this machine simulates that are still moving (Ragdoll/Out): their pelvis positions, gathered
-- every frame by update (fix round 2: the heap bound is per heap, not per machine).
local limpMoving: { Vector3 } = {}
local function heapAround(at: Vector3, radius: number): number
	local n = 0
	local r2 = radius * radius
	for _, p in limpMoving do
		local d = p - at
		if d:Dot(d) < r2 then
			n += 1
		end
	end
	return n
end
-- Whether the settle assist may act (pure; T185 checks every rule): not in a time bubble, not in low
-- gravity, not just after a push, not on a body that bounces by its kind, not in a big moving heap, only on
-- a flat floor that is not bouncy.
function ActiveRagdoll.settleAllowed(timeScale: number, gravity: number, sincePush: number, ownBounce: number, heap: number, floorNormalY: number, floorBounce: number): boolean
	local P = (GameConfig :: any).PHYSICS
	if not ((GameConfig :: any).PHYSICS_V9 and P and P.SETTLE_DAMP) then
		return false
	end
	return timeScale == 1 and gravity >= (P.SETTLE_MIN_GRAVITY or 150) and sincePush >= 0.4 and ownBounce <= 0.5
		and heap <= (P.SETTLE_MAX_BODIES or math.huge) and floorNormalY >= (P.SETTLE_FLAT or 0.9) and floorBounce <= 0.5
end

local function settle(rig: Rig, dt: number)
	local P = (GameConfig :: any).PHYSICS
	if not ((GameConfig :: any).PHYSICS_V9 and P and P.SETTLE_DAMP) then
		return
	end
	local pelvisV = rig.pelvis.AssemblyLinearVelocity
	local pelvisW = rig.pelvis.AssemblyAngularVelocity
	local rest = P.SETTLE_REST or 0.15
	-- (Fix round 2: a body already at rest, asleep or nearly, costs nothing here: no ray, no table.)
	if pelvisV.Magnitude < rest and pelvisW.Magnitude < rest then
		return
	end
	if pelvisV.Magnitude > P.SETTLE_SPEED * 3 then
		return -- (cheap early out: far too fast either way)
	end
	-- (Fix round 1: never where slow motion or a float is the point: a time bubble keeps its own clock,
	-- Zero-G and the owner's low gravity float bodies on purpose; nor while something keeps pushing it:
	-- a fan, a conveyor, a magnet, the gravity hole. Fix round 2: nor a body that bounces by its kind,
	-- GOD MODE's BOUNCY.)
	-- (A big heap is left to the solver, bodies in it stop each other: fix round 1 measured an assisted
	-- 20-body heap at a third more solver time. Fix round 2: counted round this body, not machine-wide.)
	local tsAttr = rig.model:GetAttribute("TimeScale")
	local ts = if type(tsAttr) == "number" then tsAttr else 1
	local sincePush = os.clock() - (rig.pushedAt or 0)
	local ownBounce = rig.pelvis.CurrentPhysicalProperties.Elasticity
	local heap = heapAround(rig.pelvis.Position, P.SETTLE_HEAP_RADIUS or 12)
	if not ActiveRagdoll.settleAllowed(ts, Workspace.Gravity, sincePush, ownBounce, heap, 1, 0) then
		return
	end
	-- What it lies on: only a flat, not bouncy floor; braked against the floor's own motion at the
	-- contact (a truck bed, a turning platform, an anchored conveyor belt with its set speed), so a body
	-- riding it rides along instead of sliding off.
	local hit = Workspace:Raycast(rig.pelvis.Position, Vector3.new(0, -(P.SETTLE_PROBE or 4), 0), rig.rayParams)
	if not hit then
		return
	end
	local support = hit.Instance
	local base = Vector3.zero
	local baseW = Vector3.zero
	local floorBounce = 0
	if support:IsA("BasePart") then
		floorBounce = support.CurrentPhysicalProperties.Elasticity -- (the Bouncy Floor: its bounces are the point)
		base = support:GetVelocityAtPosition(hit.Position)
		baseW = support.AssemblyAngularVelocity
	end
	if not ActiveRagdoll.settleAllowed(ts, Workspace.Gravity, sincePush, ownBounce, heap, hit.Normal.Y, floorBounce) then
		return
	end
	if (pelvisV - base).Magnitude > P.SETTLE_SPEED then
		return
	end
	local k = math.exp(-P.SETTLE_DAMP * dt)
	for _, part in rig.parts do
		local root = part.AssemblyRootPart
		if root == part and not root.Anchored then
			-- (Fix round 1: a part already all but still is left alone, so the body can fall asleep.)
			local v = root.AssemblyLinearVelocity - base
			local w = root.AssemblyAngularVelocity - baseW
			if v.Magnitude > rest or w.Magnitude > rest then
				root.AssemblyLinearVelocity = base + v * k
				root.AssemblyAngularVelocity = baseW + w * k
			end
		end
	end
end

local function brokenList(rig: Rig): { string }
	local list = {}
	for name in rig.broken do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

local function emit(kind: string, rig: Rig, position: Vector3, speed: number)
	local listener = ActiveRagdoll.onEvent
	if listener then
		task.spawn(listener, kind, rig.model, position, speed)
	end
end

local function reportTransition(rig: Rig)
	rig.model:SetAttribute("RagdollState", rig.state)
	rig.model:SetAttribute("Held", rig.held > 0)
	local listener = ActiveRagdoll.onTransition
	local broken = brokenList(rig)
	if listener then
		task.spawn(listener, rig.model, rig.state, broken, rig.held > 0)
	end
	for _, extra in transitionListeners do
		task.spawn(extra, rig.model, rig.state, broken, rig.held > 0)
	end
end

local function applyPose(rig: Rig, pose: Poses.Pose)
	for name, joint in rig.joints do
		joint.Transform = if rig.broken[name] then CFrame.identity else (pose[name] or CFrame.identity)
	end
end

local function isAirborne(rig: Rig): boolean
	local hit = Workspace:Raycast(rig.pelvis.Position, Vector3.new(0, -AIR_CLEARANCE, 0), rig.rayParams)
	return hit == nil
end

-- Broken joints always dangle, whatever the state wants.
local function applyBroken(rig: Rig)
	for name in rig.broken do
		local joint = rig.joints[name]
		if joint then
			joint.IsKinematic = false
			joint.AngularStrength = NOODLE_STRENGTH
			joint.AngularDamping = 0.25
			joint.LinearStrength = 0
			joint.MaxTorque = MUSCLE_TORQUE
		end
	end
end

local function setJoint(joint: AnimationConstraint, t: Tone.JointTone, hasSocket: boolean)
	joint.MaxTorque = t.maxTorque
	joint.AngularStrength = t.strength
	joint.AngularDamping = t.damping
	-- With a BallSocket holding the joint together, the muscle should only rotate.
	joint.LinearStrength = if hasSocket then 0 else t.strength
	joint.LinearDamping = t.damping
	if not hasSocket then
		-- The root joint must also hold position: a player's avatar comes with MaxForce 0 there,
		-- and its HumanoidRootPart (no collisions) would drop through the floor and be destroyed.
		joint.MaxForce = math.max(joint.MaxForce, 1e6)
	end
	joint.IsKinematic = t.kinematic
end

-- V9-2c: the time a body runs at on this screen (a time bubble: Client/SlowMotion sets the model's
-- TimeScale here, locally; 1 anywhere else).
local function timeScaleOf(rig: Rig): number
	local ts = rig.model:GetAttribute("TimeScale")
	return if type(ts) == "number" and ts > 0 then ts else 1
end

-- V9-P3: a hurt body's muscles give. 0 (whole) .. 1 (about to drop), from what VitalsService publishes:
-- Damage (the hits so far, of BODY_HP 100, wearing off) and Blood (bleeding). It sways on its feet and
-- walks slower (swayUp, updateMoving).
local function hurtOf(rig: Rig): number
	if not (GameConfig :: any).PHYSICS_V9 then
		return 0
	end
	local damage = rig.model:GetAttribute("Damage")
	local blood = rig.model:GetAttribute("Blood")
	local fromDamage = if type(damage) == "number" then math.clamp((damage - 10) / 60, 0, 1) else 0
	local fromBlood = if type(blood) == "number" then math.clamp((95 - blood) / 50, 0, 1) else 0
	return math.max(fromDamage, fromBlood)
end

-- The "up" a hurt body balances towards: a slow wander of up to ~12 degrees, each body in its own phase.
local function swayUp(rig: Rig, hurt: number, up: Vector3): Vector3
	if hurt <= 0 then
		return up
	end
	rig.swaySeed = rig.swaySeed or math.random() * 1000
	local seed = rig.swaySeed :: number
	local t = os.clock()
	local amp = 0.05 + 0.17 * hurt
	local side = rig.heading:Cross(up)
	if side.Magnitude < 1e-3 then
		return up
	end
	return (up + side.Unit * math.noise(t * 0.9, seed) * amp * 2 + rig.heading * math.noise(t * 0.7, seed + 50) * amp * 2).Unit
end

-- V9-0ac fix round 2: a leg round a while ago, as the server noted it on the body (LegShotLeft /
-- LegShotRight, server time; every screen sees it, whoever simulates the body): +1 right, -1 left, 0 none.
function ActiveRagdoll.legShotSide(model: Model): number
	local now = Workspace:GetServerTimeNow()
	local right = model:GetAttribute("LegShotRight")
	local left = model:GetAttribute("LegShotLeft")
	local r = type(right) == "number" and now - right < LEG_LIMP_TIME
	local l = type(left) == "number" and now - left < LEG_LIMP_TIME
	return if r and not l then 1 elseif l and not r then -1 elseif r and l then 1 else 0
end
local function legShotRecent(model: Model): number
	if not (GameConfig :: any).SHOT_FLINCH then
		return 0
	end
	return ActiveRagdoll.legShotSide(model)
end

-- An orientation from an up and a heading, made square (the up may lean towards the heading).
local function uprightFrame(up: Vector3, heading: Vector3): CFrame
	local back = -heading
	local y = back - up * back:Dot(up)
	if y.Magnitude < 1e-3 then
		return CFrame.fromMatrix(Vector3.zero, up, back)
	end
	return CFrame.fromMatrix(Vector3.zero, up, y.Unit)
end

local function applyProfile(rig: Rig, profile: string)
	for name, joint in rig.joints do
		local t = Tone.get(profile, name)
		if t then
			setJoint(joint, t, name ~= "Root")
		end
	end
	applyBroken(rig)
	local factor = Tone.balance(profile)
	rig.balance.MaxTorque = gravityTorque(rig, factor)
	rig.balance.Enabled = factor > 0
end

-- After a hit the body may not slide along faster than the hit sent it (plus some slack). Whatever
-- hit it (a heavy ball rolling on, a machine still pushing) can wedge a limb against the floor, and
-- the solver then fires the whole body along the ground far faster than any hit asked for. Only the
-- horizontal speed is governed: falling stays free.
local HIT_SPEED_SLACK = 1.2
local HIT_SPEED_EXTRA = 6
local HIT_SPEED_HOLD = 0.9 -- s
local HIT_SPEED_CARRY = 15 -- studs/s of earlier sliding a hit may add to

local function governSpeed(rig: Rig)
	-- After a toy hit only a body on the floor is governed (thrown and launched bodies fly freely).
	-- After a physical hit (a prop or a machine, which also shoves the body through the collision
	-- itself) the cap holds in the air too.
	if os.clock() > rig.speedCapUntil or (not rig.speedCapHard and isAirborne(rig)) then
		return
	end
	local momentum = Vector3.zero
	local mass = 0
	for _, part in rig.parts do
		local v = part.AssemblyLinearVelocity
		momentum += Vector3.new(v.X, 0, v.Z) * part.Mass
		mass += part.Mass
	end
	if mass <= 0 then
		return
	end
	local speed = (momentum / mass).Magnitude
	if speed > rig.speedCap then
		local k = rig.speedCap / speed
		for _, part in rig.parts do
			local v = part.AssemblyLinearVelocity
			part.AssemblyLinearVelocity = Vector3.new(v.X * k, v.Y, v.Z * k)
		end
	end
end

local function clampVelocities(rig: Rig, maxSpeed: number?)
	-- (V8-1.1: a push may allow more, for the human cannon's long arc on the player's own body.)
	local cap = math.max(MAX_LINEAR_SPEED, maxSpeed or 0)
	for _, part in rig.parts do
		local v = part.AssemblyLinearVelocity
		if v.Magnitude > cap then
			part.AssemblyLinearVelocity = v.Unit * cap
		end
		local w = part.AssemblyAngularVelocity
		if w.Magnitude > MAX_ANGULAR_SPEED then
			part.AssemblyAngularVelocity = w.Unit * MAX_ANGULAR_SPEED
		end
	end
end

-- World/Feel v2 (Config.FEEL_V2): the limb guard, every step on the machine that simulates the body.
-- The genre's top complaint is a ragdoll that "explodes" or flings a limb into the sky: one limb
-- (its own assembly, on its ball socket) gets a speed the rest of the body does not have, from a
-- deep overlap or a solver kick. A limb may move at most LIMB_REL_MAX studs/s against the pelvis and
-- spin at most LIMB_SPIN_MAX rad/s; the whole body keeps its own speed (a launch flies as before).
-- Not while held (a grab drags a limb on purpose) or frozen (welded ice). A body whose pelvis has
-- no sane velocity (NaN) is left alone (Lab brings lost bodies home), and so is one with a limb cut
-- off (Config.SEVERING).
local LIMB_GUARD = GameConfig.FEEL_V2 == true
local LIMB_REL_MAX = 110
local LIMB_SPIN_MAX = 32
ActiveRagdoll.LIMB_REL_MAX = LIMB_REL_MAX
local FLINCH_REL_MAX = 55 -- (V9-0ac fix round 2: a flinching limb's top speed against the pelvis)
local EXPLOSION_FACTOR = 1.5 -- a limb this far over LIMB_REL_MAX is a solver explosion, not a swing
ActiveRagdoll.FLINCH_REL_MAX = FLINCH_REL_MAX
ActiveRagdoll.explosions = 0 -- (counted by guardLimbs on this machine; the bench reads it)
ActiveRagdoll.LIMB_SPIN_MAX = LIMB_SPIN_MAX
local function guardLimbs(rig: Rig)
	if not LIMB_GUARD or rig.held > 0 or rig.state == "Frozen" then
		return
	end
	-- (A limb cut off flies on its own: a body with one is left as it is.)
	local severed = rig.model:GetAttribute("Severed")
	if type(severed) == "string" and severed ~= "" then
		return
	end
	local base = rig.pelvis.AssemblyLinearVelocity
	if base.Magnitude ~= base.Magnitude then
		return
	end
	-- (V9-0ac fix round 2: a standing body's flinch is a jolt with weight, never a puppet's snap: its limbs
	-- stay under FLINCH_REL_MAX against the pelvis.)
	local cap = if rig.state == "Flinch" or rig.state == "Recovering" then FLINCH_REL_MAX else LIMB_REL_MAX -- (and the swing back after it)
	for _, part in rig.parts do
		if part ~= rig.pelvis and part ~= rig.root and not part.Anchored then
			local rel = part.AssemblyLinearVelocity - base
			local speed = rel.Magnitude
			if speed > cap and speed == speed then
				-- (The bench counts the real explosions the guard catches: far over the cap, not a fast swing.)
				if speed > LIMB_REL_MAX * EXPLOSION_FACTOR then
					ActiveRagdoll.explosions += 1
				end
				part.AssemblyLinearVelocity = base + rel.Unit * cap
			end
			local w = part.AssemblyAngularVelocity
			local spin = w.Magnitude
			if spin > LIMB_SPIN_MAX and spin == spin then
				part.AssemblyAngularVelocity = w.Unit * LIMB_SPIN_MAX
			end
		end
	end
end

-- On the server, a body that splits into assemblies would get automatic ownership; keep the
-- server simulating the dummies it owns.
local function lockOwnership(rig: Rig)
	if not RunService:IsServer() then
		return
	end
	for _, part in rig.parts do
		if not part.Anchored then
			pcall(part.SetNetworkOwner, part, nil)
		end
	end
end

local function isMoving(state: State): boolean
	return state == "Walking" or state == "Fleeing" or state == "Crawling"
end

-- The movers go back to their resting setup (the get-up sets the lift up again itself).
local function stopMoving(rig: Rig)
	rig.drive.Enabled = false
	rig.drive.VectorVelocity = Vector3.zero
	rig.balance.AlignType = Enum.AlignType.PrimaryAxisParallel
	-- The heading (and the crawl's tilt) went into the balance CFrame, which carries the primary
	-- axis with it: put "upright" back to straight up, or every later get-up stands up slanted.
	rig.balance.PrimaryAxis = Vector3.yAxis
	rig.lift.ForceLimitMode = Enum.ForceLimitMode.Magnitude
end

local function flatLook(part: BasePart): Vector3
	local look = part.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	return if flat.Magnitude > 0.05 then flat.Unit else Vector3.new(0, 0, -1)
end

local function enter(rig: Rig, state: State)
	local was = rig.state
	rig.state = state
	rig.stateTime = 0
	rig.calmTime = 0
	if not isMoving(state) then
		stopMoving(rig)
	end
	if state == "Standing" or state == "Flinch" or state == "Stumble" or state == "Ragdoll" then
		rig.lift.Enabled = false
		applyProfile(rig, state)
	elseif state == "Out" then
		rig.lift.Enabled = false
		applyProfile(rig, "Ragdoll")
	elseif isMoving(state) then
		applyProfile(rig, if state == "Crawling" then "Crawl" else "Standing")
		local lift = rig.lift
		lift.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		lift.MaxAxesForce = Vector3.new(0, rig.mass * Config.NORMAL_GRAVITY * 4, 0)
		lift.Position = rig.pelvis.Position
		lift.Enabled = true
		-- Aim the balance before switching it to full orientation (no tug towards an old heading).
		if not isMoving(was) then
			rig.heading = flatLook(rig.pelvis)
		end
		rig.balance.CFrame = if state == "Crawling"
			then rig.balance.CFrame
			else CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, -rig.heading)
		rig.balance.AlignType = Enum.AlignType.AllAxes
		rig.balance.MaxTorque = gravityTorque(rig, Tone.STANDING_BALANCE)
		rig.balance.Enabled = true
		rig.drive.Enabled = true
		if not isMoving(was) then
			rig.speed = 0
			rig.heading = flatLook(rig.pelvis)
		end
		rig.stuckTime = 0
		rig.bestDistance = math.huge
		rig.steer = 0
		rig.steerUntil = 0
		rig.arriveTime = 0
	end
	if state == "Standing" or isMoving(state) then
		applyPose(rig, Poses.REST)
	elseif state == "Ragdoll" or state == "Out" then
		rig.airborne = false
		rig.limpProfile = "Ragdoll"
		rig.model:SetAttribute("Airborne", false)
	end
	lockOwnership(rig)
	reportTransition(rig)
end

local function startRamp(rig: Rig, state: State, duration: number)
	-- Snapshot current tone, then blend to the standing tone in update().
	local ramp: Ramp = {}
	for _, joint in rig.joints do
		ramp[joint] = { strength = joint.AngularStrength, damping = joint.AngularDamping }
		joint.IsKinematic = false
	end
	rig.ramp = ramp
	rig.rampDuration = duration
	applyPose(rig, Poses.REST)
	rig.rampBalanceFrom = if rig.balance.Enabled then rig.balance.MaxTorque else 0
	rig.balance.Enabled = true

	if state == "GettingUp" then
		local origin = rig.pelvis.Position
		local hit = Workspace:Raycast(origin + Vector3.new(0, 2, 0), Vector3.new(0, -50, 0), rig.rayParams)
		rig.groundY = if hit then hit.Position.Y else origin.Y - rig.standOffset
		rig.faceDown = rig.chest.CFrame.LookVector.Y < 0
		rig.model:SetAttribute("GetUpStyle", if rig.faceDown then "Kneel" else "SitUp")
		rig.lift.Position = origin
		rig.lift.MaxForce = 0
		rig.lift.Enabled = true
	end
	enter(rig, state)
end

-- Two stages: first kneel (face down) or sit up (face up) with the pelvis lifted part way,
-- then rise into the rest pose. Tone, balance and lift ramp up across both.
local function updateGetUp(rig: Rig)
	local t = rig.stateTime
	local pelvisPos = rig.pelvis.Position
	local firstHeight = rig.standOffset * (if rig.faceDown then 0.6 else 0.38)
	local strength: number
	local height: number
	local balanceShare: number

	if t < GETUP_FIRST_STAGE then
		local a = t / GETUP_FIRST_STAGE
		applyPose(rig, if rig.faceDown then Poses.kneel(t) else Poses.sitUp(t))
		strength = 0.15 + 0.5 * a
		height = firstHeight
		balanceShare = 0.5 * a
		rig.lift.MaxForce = rig.mass * Config.NORMAL_GRAVITY * 3 * a * math.max(1, timeScaleOf(rig) ^ 2)
	else
		local a = math.clamp((t - GETUP_FIRST_STAGE) / (GETUP_TIME - GETUP_FIRST_STAGE), 0, 1)
		local eased = 1 - (1 - a) * (1 - a)
		applyPose(rig, Poses.REST)
		strength = 0.65 + 0.35 * eased
		height = firstHeight + (rig.standOffset - firstHeight) * eased
		balanceShare = 0.5 + 0.5 * eased
		rig.lift.MaxForce = rig.mass * Config.NORMAL_GRAVITY * 4 * math.max(1, timeScaleOf(rig) ^ 2)
		if a >= 1 then
			enter(rig, "Standing")
			return
		end
	end

	for _, joint in rig.joints do
		joint.AngularStrength = strength
		joint.AngularDamping = 1
		joint.MaxTorque = MUSCLE_TORQUE
	end
	applyBroken(rig)
	rig.balance.MaxTorque = gravityTorque(rig, Tone.STANDING_BALANCE) * balanceShare
	rig.lift.Position = Vector3.new(pelvisPos.X, rig.groundY + height, pelvisPos.Z)
end

local function updateRamp(rig: Rig)
	local alpha = math.clamp(rig.stateTime / rig.rampDuration, 0, 1)
	local eased = 1 - (1 - alpha) * (1 - alpha)
	for joint, from in rig.ramp do
		joint.AngularStrength = from.strength + (1 - from.strength) * eased
		joint.AngularDamping = from.damping + (1 - from.damping) * eased
		joint.MaxTorque = MUSCLE_TORQUE
	end
	applyBroken(rig)
	local target = gravityTorque(rig, Tone.STANDING_BALANCE)
	rig.balance.MaxTorque = rig.rampBalanceFrom + (target - rig.rampBalanceFrom) * eased
	if alpha >= 1 then
		enter(rig, "Standing")
	end
end

-- Plasters are visual and shared, so only the server makes them (it learns about breaks
-- from the simulator's transition reports).
function ActiveRagdoll.addPlaster(part: BasePart)
	if part:FindFirstChild("Plaster") then
		return
	end
	local function strip(angle: number)
		local p = Instance.new("Part")
		p.Name = "Plaster"
		p.Size = Vector3.new(0.9, 0.28, part.Size.Z + 0.06)
		p.Color = Color3.fromRGB(250, 240, 225)
		p.Material = Enum.Material.Fabric
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		-- (V9-P fix round 2: on the sculpted skins the box-sized strips read as stray geometry: with
		-- Config.PLASTER_VISIBLE off they stay as the break's marker (DummyLife limps by them; the vitals
		-- monitor shows the break) but are not drawn.)
		if (GameConfig :: any).PLASTER_VISIBLE == false then
			p.Transparency = 1
			p.CastShadow = false
		end
		p.CFrame = part.CFrame * CFrame.Angles(0, 0, angle)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part
		weld.Part1 = p
		weld.Parent = p
		p.Parent = part
	end
	strip(math.rad(40))
	strip(math.rad(-40))
end

-- Limb part a broken joint dangles (the joint's child side).
function ActiveRagdoll.limbOf(model: Model, jointName: string): BasePart?
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") and d.Name == jointName then
			local a1 = d.Attachment1
			local limb = a1 and a1.Parent
			return if limb and limb:IsA("BasePart") then limb else nil
		end
	end
	return nil
end

local function breakLimb(rig: Rig, part: BasePart): boolean
	local jointName = BREAKABLE[part.Name]
	if not jointName or rig.broken[jointName] then
		return false
	end
	local count = 0
	for _ in rig.broken do
		count += 1
	end
	if count >= MAX_BROKEN then
		return false
	end
	rig.broken[jointName] = true
	applyBroken(rig)
	if RunService:IsServer() then
		local limb = ActiveRagdoll.limbOf(rig.model, jointName)
		if limb then
			ActiveRagdoll.addPlaster(limb)
		end
	end
	rig.model:SetAttribute("Broken", count + 1)
	if RunService:IsServer() then
		rig.model:SetAttribute("BrokenJoints", table.concat(brokenList(rig), ",")) -- the hospital chart
	end
	emit("Break", rig, part.Position, 0)
	reportTransition(rig)
	return true
end

-- Freeze with welds made here (server-simulated dummies). Owned dummies are frozen by the
-- server and their simulator only switches state (setExternalFrozen).
local function freezeLocal(rig: Rig)
	if rig.frozenWelds then
		return
	end
	local welds: { WeldConstraint } = {}
	local looks: { [BasePart]: { color: Color3, material: Enum.Material } } = {}
	for _, part in rig.parts do
		if part ~= rig.pelvis then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "FreezeWeld"
			weld.Part0 = rig.pelvis
			weld.Part1 = part
			weld.Parent = rig.pelvis
			table.insert(welds, weld)
		end
		if part ~= rig.root then
			looks[part] = { color = part.Color, material = part.Material }
			part.Color = ICE_COLOR
			part.Material = Enum.Material.Ice
		end
	end
	for _, joint in rig.joints do
		joint.Enabled = false
	end
	rig.frozenWelds = welds
	rig.frozenLooks = looks
	stopMoving(rig) -- an ice statue does not keep walking
	rig.balance.Enabled = false
	rig.lift.Enabled = false
	rig.state = "Frozen"
	rig.stateTime = 0
	rig.model:SetAttribute("Frozen", true)
	lockOwnership(rig)
	reportTransition(rig)
end

local function thawLocal(rig: Rig)
	local welds = rig.frozenWelds
	if welds then
		for _, weld in welds do
			weld:Destroy()
		end
		for part, look in rig.frozenLooks or {} do
			part.Color = look.color
			part.Material = look.material
		end
		for _, joint in rig.joints do
			joint.Enabled = true
		end
		rig.frozenWelds = nil
		rig.frozenLooks = nil
		rig.model:SetAttribute("Frozen", false)
	end
	enter(rig, "Ragdoll")
end

------------------------------------------------------------------------------------------------
-- Getting about: the brain of a lab dummy (one with a Home) and the movers that carry it out.

local Players = game:GetService("Players")

-- How many legs are broken (0, 1 or 2) and on which side the one broken leg is (+1 right, -1 left).
local function brokenLegs(rig: Rig): (number, number)
	local count, side = 0, 0
	for name, joints in LEG_JOINTS do
		for _, joint in joints do
			if rig.broken[joint] then
				count += 1
				side = if name == "Right" then 1 else -1
				break
			end
		end
	end
	return count, side
end

local function homeOf(rig: Rig): Vector3?
	local home = rig.model:GetAttribute("Home")
	return if typeof(home) == "Vector3" then home else nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Places a fleeing body never runs into (tag DummyAvoid: the lab's lava pit). Before, a coward shot
-- at from the front ran straight into the lava, was thrown, got up at its rim and was thrown again.
local AVOID_MARGIN = 3 -- studs round each place
local function inAvoid(p: Vector3): boolean
	for _, part in CollectionService:GetTagged("DummyAvoid") do
		if part:IsA("BasePart") then
			local rel = part.CFrame:PointToObjectSpace(p)
			if math.abs(rel.X) < part.Size.X / 2 + AVOID_MARGIN and math.abs(rel.Z) < part.Size.Z / 2 + AVOID_MARGIN then
				return true
			end
		end
	end
	return false
end

-- The run direction turned the least that keeps a body out of the places it avoids, a few studs ahead.
local function clearRun(here: Vector3, run: Vector3): Vector3
	if not inAvoid(here + run * 6) then
		return run
	end
	for _, turn in { 50, -50, 100, -100, 150, -150 } do
		local r = CFrame.Angles(0, math.rad(turn), 0):VectorToWorldSpace(run)
		if not inAvoid(here + r * 6) then
			return r
		end
	end
	return run
end

-- The nearest person within reach, if any.
local function nearestPerson(rig: Rig, reach: number): Vector3?
	local best: Vector3? = nil
	local bestDistance = reach
	local here = rig.pelvis.Position
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local d = flat(root.Position - here).Magnitude
			if d < bestDistance then
				best, bestDistance = root.Position, d
			end
		end
	end
	return best
end

-- Panic (people in the crowd, CrowdService): something they saw or heard, set on the model as
-- PanicFrom (where) and PanicUntil (server time). Seconds of it left, and where, or nil.
local function panicOf(rig: Rig): (Vector3?, number)
	local from = rig.model:GetAttribute("PanicFrom")
	local untilTime = rig.model:GetAttribute("PanicUntil")
	if typeof(from) ~= "Vector3" or type(untilTime) ~= "number" then
		return nil, 0
	end
	local left = untilTime - Workspace:GetServerTimeNow()
	if left <= 0 then
		return nil, 0
	end
	return from, left
end

-- Hurt in the last FLEE_MEMORY s, rested since the last run, and someone close: where they are.
local function scaredOf(rig: Rig, now: number): Vector3?
	if now - rig.lastHitAt >= FLEE_MEMORY or now - rig.fledAt <= FLEE_REST or now < rig.fleeUntil then
		return nil
	end
	return nearestPerson(rig, FLEE_RADIUS)
end

local function startFleeing(rig: Rig, danger: Vector3, now: number, seconds: number?)
	rig.fleeFrom = danger
	rig.fleeUntil = now + (seconds or FLEE_TIME)
	rig.panicking = seconds ~= nil
	if rig.state ~= "Crawling" then
		enter(rig, "Fleeing") -- a crawler just crawls away faster (see updateMoving)
	end
end

-- Panicked and not running yet: off it goes, straight away (no getting its bearings first).
local function panicNow(rig: Rig, now: number): boolean
	if rig.panicking and now < rig.fleeUntil then
		return false
	end
	local from, left = panicOf(rig)
	if not from then
		return false
	end
	startFleeing(rig, from, now, left)
	return true
end

-- Standing with its legs in the floor (round 2: seen in the rooms' thick floors, a body sunk to the
-- hips and resting there, the solver unable to push the limbs out): lifted back onto the floor.
local SUNK_BY = 0.8 -- studs lower than it stands before it counts
local function unsink(rig: Rig): boolean
	local here = rig.pelvis.Position
	-- The world only (no bodies, no players: a body lying under it is no floor), from just above the
	-- pelvis (higher, a ray can land on a ledge or a prop beside the body it only overlaps).
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { rig.model }
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ignore, dummies)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	local hit = Workspace:Raycast(here + Vector3.new(0, 1, 0), Vector3.new(0, -(rig.standOffset + 1.5), 0), params)
	if not hit then
		return false
	end
	local deficit = rig.standOffset - (here.Y - hit.Position.Y)
	-- (Never more than its own height: something it stands half inside, a counter, is not a floor
	-- to be lifted onto.)
	if deficit < SUNK_BY or deficit > rig.standOffset + 0.5 then
		return false
	end
	rig.model:PivotTo(rig.model:GetPivot() + Vector3.new(0, deficit + 0.05, 0))
	for _, part in rig.model:GetDescendants() do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
		end
	end
	return true
end
ActiveRagdoll.unsinkForTest = function(model: Model): boolean
	local rig = rigs[model]
	return rig ~= nil and unsink(rig)
end

-- Standing still: decide whether to set off (run from someone, crawl, or walk home).
local function think(rig: Rig)
	-- (Checked a few times a second, not every step.)
	if rig.held == 0 and rig.model:GetAttribute("IsDummy") == true and (rig.stateTime - rig.sinkCheckAt >= 0.5 or rig.stateTime < rig.sinkCheckAt) then
		rig.sinkCheckAt = rig.stateTime
		if unsink(rig) then
			emit("Unsink", rig, rig.pelvis.Position, 0)
		end
	end
	if rig.held > 0 or rig.stayDown then
		return
	end
	local home = homeOf(rig)
	if not home then
		return -- only lab dummies get about
	end
	local now = os.clock()
	if panicNow(rig, now) then
		return
	end
	if rig.stateTime < LOOK_AROUND_TIME then
		return
	end
	local danger = scaredOf(rig, now)
	if danger then
		startFleeing(rig, danger, now)
		return
	end
	-- A gun pointed at it (round 3, M3): a coward runs from a raised one (fired a moment ago) or one
	-- pushed right up to it; the others put their hands up where they stand (DummyLife).
	-- (Looked at 4 times a second, not every step: a crowd of standing bodies costs next to nothing.)
	local looking = now >= rig.gunLookAt
	if looking then
		rig.gunLookAt = now + 0.25
		rig.gunWary = false
	end
	-- (10 Nov 2026, the owner: they must be properly scared: every one but the brave runs from a gun.)
	local coward = looking and rig.model:GetAttribute("Personality") ~= "Brave" and rig.model:GetAttribute("Greeter") == nil -- (the greeter walks up to a new player holding the G17: it never runs from it)
	if coward and now - rig.fledAt > FLEE_REST then
		local gun = GunThreat.cowardRunsFrom(rig.chest.Position)
		if gun then
			rig.gunFledAt = now
			startFleeing(rig, gun, now, GUN_FLEE)
			return
		end
	end
	if flat(home - rig.pelvis.Position).Magnitude > HOME_LEAVE then
		-- (Ran from a gun that is still pointed at its place: it keeps its distance, no running
		-- back and forth.)
		if coward and now - rig.gunFledAt < GUN_WARY and GunThreat.near(home, GunThreat.SCARE_REACH) then
			rig.gunWary = true
		end
		if rig.gunWary then
			return
		end
		local legs = brokenLegs(rig)
		enter(rig, if legs >= 2 then "Crawling" else "Walking")
	end
end

-- The other dummies' pelvises, looked up a few times a second (not per mover per frame).
local neighbours: { BasePart } = {}
local neighboursAt = 0
local function refreshNeighbours(folder: Instance)
	local now = os.clock()
	if now - neighboursAt < 0.5 then
		return
	end
	neighboursAt = now
	table.clear(neighbours)
	for _, other in folder:GetChildren() do
		local pelvis = other:FindFirstChild("LowerTorso")
		if pelvis and pelvis:IsA("BasePart") then
			table.insert(neighbours, pelvis)
		end
	end
end

-- Steers round the other dummies: one standing in the corridor ahead (within reach of the way it
-- goes) is passed on the side away from it with room to spare; one right next to it pushes it
-- off. Returns the new direction and whether it had to steer.
local PASS_CLEARANCE = 3.2 -- studs between the two pelvises when passing (arms swing wide)
local function avoidDummies(rig: Rig, here: Vector3, direction: Vector3, goalDistance: number): (Vector3, boolean)
	local folder = rig.model.Parent
	if not folder then
		return direction, false
	end
	refreshNeighbours(folder)
	local side = Vector3.new(-direction.Z, 0, direction.X) -- to the left of the way it goes
	local steer = Vector3.zero
	for _, pelvis in neighbours do
		if pelvis ~= rig.pelvis and pelvis.Parent then
			local offset = flat(pelvis.Position - here)
			local d = offset.Magnitude
			local ahead = offset:Dot(direction)
			local lateral = offset:Dot(side)
			if ahead > -0.5 and ahead < math.min(goalDistance + 1, 7) and math.abs(lateral) < PASS_CLEARANCE then
				-- In the way: aim to pass it on the side it is not on (straight ahead: left).
				local away = if lateral > 0 then -side else side
				steer += away * (PASS_CLEARANCE - math.abs(lateral)) / PASS_CLEARANCE * 1.6
			end
			if d > 0.05 and d < 2.4 then
				steer += -offset.Unit * (2.4 - d) -- too close already: step off
			end
		end
	end
	if steer.Magnitude < 0.01 then
		return direction, false
	end
	local adjusted = flat(direction + steer)
	return (if adjusted.Magnitude > 0.05 then adjusted.Unit else side), true
end

-- Something solid in the way a little ahead, at knee height (crawling: just off the floor)?
local function blocked(rig: Rig, direction: Vector3, groundY: number): boolean
	local height = if rig.state == "Crawling" then 0.5 else rig.standOffset * 0.55
	local from = Vector3.new(rig.pelvis.Position.X, groundY + height, rig.pelvis.Position.Z)
	local hit = Workspace:Raycast(from, direction * (if rig.state == "Crawling" then 3 else 2.5), rig.rayParams)
	if not hit or not hit.Instance.CanCollide then
		return false
	end
	-- Other dummies are steered round separately (avoidDummies).
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	return not (model and model:GetAttribute("IsDummy") == true)
end

-- One step of walking, fleeing or crawling.
local function updateMoving(rig: Rig, dt: number)
	local state = rig.state
	local now = os.clock()
	local legs, _ = brokenLegs(rig)
	if state ~= "Crawling" and legs >= 2 then
		enter(rig, "Ragdoll") -- both legs gone while up: it collapses, then crawls
		return
	end
	if state ~= "Crawling" and tiltDegrees(rig) > TRIP_DEG then
		enter(rig, "Ragdoll")
		return
	end
	local here = rig.pelvis.Position

	-- The ground under it. None (walked off an edge) or a big drop ahead: it falls.
	local ground = Workspace:Raycast(here + Vector3.new(0, 1, 0), Vector3.new(0, -(rig.standOffset + LEDGE_DROP + 1), 0), rig.rayParams)
	if not ground then
		enter(rig, "Ragdoll")
		return
	end
	local groundY = ground.Position.Y

	-- Panic on the way (something seen or heard): it runs.
	if not (state == "Fleeing" and rig.panicking) and panicNow(rig, now) then
		if rig.state ~= state then
			return
		end
	end
	-- Someone walks up to a hurt dummy on its way home: it runs (or crawls faster) away.
	if state ~= "Fleeing" then
		local danger = scaredOf(rig, now)
		if danger then
			startFleeing(rig, danger, now)
			if rig.state ~= state then
				return
			end
		end
	end
	-- A coward walking about looks out for a gun too (a few times a second): it runs from one, and
	-- one that ran from a gun stops short of a home a gun is still pointed at.
	if state == "Walking" and now >= rig.gunLookAt then
		rig.gunLookAt = now + 0.25 -- (every walker: the personality is read 4 times a second, not every step)
		if rig.model:GetAttribute("Personality") ~= "Brave" and rig.model:GetAttribute("Greeter") == nil then
			local gun = if now - rig.fledAt > FLEE_REST then GunThreat.cowardRunsFrom(rig.chest.Position) else nil
			if gun then
				rig.gunFledAt = now
				startFleeing(rig, gun, now, GUN_FLEE)
				if rig.state ~= state then
					return
				end
			elseif now - rig.gunFledAt < GUN_WARY then
				local to = homeOf(rig)
				if to and GunThreat.near(to, GunThreat.SCARE_REACH) then
					enter(rig, "Standing")
					return
				end
			end
		end
	end

	local home = homeOf(rig)

	-- Where to.
	local goal: Vector3? = nil
	local fleeing = state == "Fleeing" or (state == "Crawling" and now < rig.fleeUntil)
	if fleeing then
		-- (Panic runs from what it saw or heard; a hurt dummy from the nearest person.)
		local danger = if rig.panicking then rig.fleeFrom else nearestPerson(rig, FLEE_RADIUS * 1.6) or rig.fleeFrom
		if danger then
			rig.fleeFrom = danger
			local away = flat(here - danger)
			local run = if away.Magnitude > 0.1 then away.Unit else rig.heading
			if rig.panicking then
				-- Like a headless chicken (10 Nov 2026): away, but zigzagging wildly, now and then
				-- darting off sideways.
				local seed = (rig.model:GetAttribute("Seed") :: number?) or 0
				local zig = math.sin(now * 5.2 + seed * 3) * 0.75 + math.sin(now * 1.7 + seed) * 0.45
				run = CFrame.Angles(0, zig, 0):VectorToWorldSpace(run)
			end
			run = clearRun(here, run)
			goal = here + run * 10
		end
	elseif home then
		goal = home
	end
	if state == "Fleeing" and now >= rig.fleeUntil then
		rig.fledAt = now
		rig.panicking = false
		enter(rig, "Standing") -- catches its breath, then heads home
		return
	elseif state == "Crawling" and rig.fleeUntil > 0 and now >= rig.fleeUntil then
		rig.fleeUntil = 0
		rig.fledAt = now
	end

	local wantSpeed = 0
	local wantHeading = rig.heading
	if goal then
		local offset = flat(goal - here)
		local distance = offset.Magnitude
		-- Something on its spot (a crate, a person): close enough and no closer for a while counts.
		local blockedHome = not fleeing and distance <= 4 and rig.stuckTime > 2
		if not fleeing and (distance <= HOME_ARRIVE or blockedHome) then
			-- Home: turn to face the way it stands (towards the lab), then stand.
			local lookAt = rig.model:GetAttribute("HomeLook")
			local face = if typeof(lookAt) == "Vector3" then flat(lookAt - here) else Vector3.zero
			wantHeading = if face.Magnitude > 0.1 then face.Unit else rig.heading
			-- Stands once the body itself (not just where it wants to go) faces the lab, or after a
			-- moment anyway (a snagged limb must not keep it turning forever).
			rig.arriveTime += dt
			local faces = rig.heading:Dot(wantHeading) > 0.97 and flatLook(rig.pelvis):Dot(wantHeading) > 0.95
			if state == "Walking" and (faces or rig.arriveTime > ARRIVE_TURN_MAX) then
				enter(rig, "Standing")
				return
			end
		else
			-- Progress towards home; without it for a while, go round whatever is in the way.
			if not fleeing then
				if distance < rig.bestDistance - 0.5 then
					rig.bestDistance = distance
					rig.stuckTime = 0
				else
					rig.stuckTime += dt
				end
			end
			local direction = offset.Unit
			if now < rig.steerUntil then
				-- Keep to the detour it chose for a moment (or it walks straight back into it).
				direction = CFrame.Angles(0, rig.steer, 0):VectorToWorldSpace(direction)
			elseif blocked(rig, direction, groundY) or rig.stuckTime > STUCK_DETOUR then
				if rig.stuckTime > STUCK_DETOUR * 2 then
					rig.steer = -rig.steer -- that side did not work: try the other one
					rig.stuckTime = 0
					rig.bestDistance = distance
				elseif rig.steer == 0 then
					rig.steer = if math.random() < 0.5 then DETOUR_ANGLE else -DETOUR_ANGLE
				end
				rig.steerUntil = now + DETOUR_TIME
				direction = CFrame.Angles(0, rig.steer, 0):VectorToWorldSpace(direction)
			end
			-- Round the other dummies (they stand in a row; the way home often passes one). Going
			-- round one is slow progress on purpose, not being stuck.
			local steered
			direction, steered = avoidDummies(rig, here, direction, distance)
			if steered then
				rig.stuckTime = 0
			end
			wantHeading = direction
			local base = if state == "Crawling"
				then (if fleeing then CRAWL_FLEE_SPEED else CRAWL_SPEED)
				elseif legs == 1 or now < (rig.limpUntil or 0) or legShotRecent(rig.model) ~= 0 then (if fleeing then LIMP_FLEE_SPEED else LIMP_SPEED) -- (a broken leg, or a leg round a while ago: V9-0ac)
				elseif fleeing then FLEE_SPEED
				else WALK_SPEED
			-- A game can hurry its runners along (Pace: a multiplier, MinigameService).
			local pace = rig.model:GetAttribute("Pace")
			if type(pace) == "number" and pace > 0 and pace <= 2 then
				base *= pace
			end
			base *= 1 - 0.45 * hurtOf(rig) -- (V9-P3: hurt, it goes slower)
			wantSpeed = if fleeing then base else math.min(base, distance * 1.8 + 0.6)
		end
	end

	-- Turn towards the way it goes (quicker when fleeing), ease the speed.
	local turnRate = if fleeing then 9 else 5
	local k = 1 - math.exp(-turnRate * dt)
	local heading = rig.heading:Lerp(wantHeading, k)
	if heading.Magnitude < 0.05 then
		heading = wantHeading
	end
	rig.heading = heading.Unit
	-- It walks where it faces, so it never moonwalks or slides sideways.
	local facing = math.max(0, rig.heading:Dot(wantHeading))
	rig.speed += (wantSpeed * facing - rig.speed) * (1 - math.exp(-SPEED_EASE * dt))
	-- (V9-2c: inside a time bubble it walks at the bubble's time: TimeScale, set on this screen by
	-- Client/SlowMotion; its lift holds the bubble's gravity.)
	local ts = timeScaleOf(rig)
	rig.drive.VectorVelocity = rig.heading * rig.speed * ts
	if ts > 1 and rig.lift.Enabled then
		rig.lift.MaxAxesForce = Vector3.new(0, rig.mass * Config.NORMAL_GRAVITY * 4 * ts * ts, 0)
	end

	-- Hold the pelvis at walking (or crawling) height over the ground below it.
	local height = if state == "Crawling" then CRAWL_HEIGHT else rig.standOffset + WALK_HOVER
	-- (V9-0z: a GOD MODE kind walks its own way: Gait "Hop" (BOUNCY) bobs up and down as it goes,
	-- "Wobble" (FLOPPY) rolls from side to side; set by DummySpawn.)
	local gait = rig.model:GetAttribute("Gait")
	if gait == "Hop" and state ~= "Crawling" and rig.speed > 1 then
		height += math.abs(math.sin(os.clock() * 7)) * 1.6
	end
	rig.lift.Position = Vector3.new(here.X, groundY + height, here.Z)

	-- Upright and facing the heading; crawling: face down, head first, chest a little up.
	local up = Vector3.yAxis
	if state == "Crawling" then
		local x = (rig.heading * math.cos(CRAWL_PITCH) + up * math.sin(CRAWL_PITCH)).Unit
		local y = (up * math.cos(CRAWL_PITCH) - rig.heading * math.sin(CRAWL_PITCH)).Unit
		rig.balance.CFrame = CFrame.fromMatrix(Vector3.zero, x, y)
	else
		local upright = swayUp(rig, hurtOf(rig), up)
		if gait == "Wobble" and rig.speed > 0.5 then
			local roll = math.sin(os.clock() * 5) * 0.18
			upright = (upright * math.cos(roll) + rig.heading:Cross(up).Unit * math.sin(roll)).Unit
		end
		rig.balance.CFrame = uprightFrame(upright, rig.heading)
	end
end

-- Hurt by what it hits: in the Ragdoll and Out states, a part that loses a lot of speed in one step
-- has hit something hard. The limb that stopped hardest may break; the head or the whole body
-- stopping hard knocks it out cold (lab dummies, as for head knocks). Dummies only (not avatars).
local function checkImpact(rig: Rig)
	if rig.model:GetAttribute("IsDummy") ~= true then
		return
	end
	local now = os.clock()
	-- Speeds from an earlier stretch on the floor or standing are not last step's: start over.
	if now - rig.impactCheckedAt > 0.1 then
		table.clear(rig.impactSpeeds)
	end
	rig.impactCheckedAt = now
	local fresh = now - rig.lastImpulseAt < IMPACT_AFTER_HIT
	local bestLimb: BasePart? = nil
	local bestLoss, headLoss, pelvisLoss = 0, 0, 0
	local trunkJolt = 0 -- the biggest change of the trunk's velocity (a landing at a slant loses
	-- little speed but turns hard: the fall is stopped while the slide goes on)
	local speeds = rig.impactSpeeds
	-- (V9-P3 fix round 1: arms that brace a fall take the ground by design: they never break doing it.)
	local catching = rig.bracing == true or (rig.catchUntil ~= nil and now < rig.catchUntil + 0.15)
	for _, p in rig.parts do
		if p ~= rig.root and (BREAKABLE[p.Name] or p == rig.pelvis or p.Name == "Head") then
			local v = p.AssemblyLinearVelocity
			local before = speeds[p]
			speeds[p] = v
			if before and not fresh and before.Magnitude >= IMPACT_MIN_SPEED then
				local loss = before.Magnitude - v.Magnitude
				if p == rig.pelvis or p.Name == "Head" then
					trunkJolt = math.max(trunkJolt, (before - v).Magnitude)
				end
				if p == rig.pelvis then
					pelvisLoss = loss
				elseif p.Name == "Head" then
					headLoss = loss
				elseif loss > bestLoss and not (catching and (string.find(p.Name, "Arm", 1, true) or string.find(p.Name, "Hand", 1, true))) then
					bestLoss, bestLimb = loss, p
				end
			end
		end
	end
	if fresh or now - rig.lastImpactAt < IMPACT_GAP then
		return
	end
	local hurt = false
	-- The injuries the launch carried, at the first real impact of the flight.
	-- A pending injury that found no impact in time is forgotten (not carried to a later flight).
	if now >= rig.pendingUntil and (rig.pendingLimb or rig.pendingKO) then
		rig.pendingLimb = nil
		rig.pendingKO = false
	end
	-- Landed: the trunk stopped hard, or the body has come to rest (a lob that rolls to a stop
	-- still lands); never while held.
	-- (Resting is on the floor, not hanging at the top of a flight; the ray only when it matters.)
	-- (A jolt only counts by the floor: in the air a struck head or limb is still being yanked about
	-- by the body for a moment after the hit.)
	local pending = now < rig.pendingUntil
		and rig.held == 0
		and (
			(trunkJolt >= PENDING_IMPACT and not isAirborne(rig))
			or (now - rig.lastImpulseAt > 0.3 and rig.pelvis.AssemblyLinearVelocity.Magnitude < 5 and not isAirborne(rig))
		)
	-- (A hard knock on the way, against a wall or another dummy, breaks the limb the launch struck,
	-- not some other one: what the player hit is what gets hurt.)
	local struck = rig.pendingLimb
	if struck and struck.Parent and now < rig.pendingUntil and (pending or bestLoss >= BREAK_IMPACT) then
		hurt = breakLimb(rig, struck) or hurt
		rig.pendingLimb = nil
	end
	-- One limb per impact: the one the launch struck, else the one that stopped hardest.
	local limb = bestLimb
	if not hurt and limb and bestLoss >= BREAK_IMPACT then
		hurt = breakLimb(rig, limb) or hurt
	end
	local knockedOut = (pending and rig.pendingKO) or headLoss >= HEAD_KO_IMPACT or pelvisLoss >= KO_IMPACT
	if pending then
		rig.pendingKO = false
		rig.pendingUntil = 0
	end
	if rig.state == "Ragdoll" and rig.held == 0 and homeOf(rig) and knockedOut then
		rig.koUntil = now + KO_MIN + math.random() * (KO_MAX - KO_MIN)
		enter(rig, "Out")
		hurt = true
	end
	if hurt then
		rig.lastImpactAt = now
		rig.lastHitAt = now -- hurt: it remembers (and runs from people for a while)
	end
end

-- Out cold or dead from its wounds (VitalsService's Vital, replicated): it goes limp and stays
-- down until it is patched up.
local function vitalDown(rig: Rig): boolean
	local vital = rig.model:GetAttribute("Vital")
	-- (V9-0z: a spent GOD MODE body, KO'd once, stays down until it goes: DummySpawn.)
	return vital == "Unconscious" or vital == "Dead" or rig.model:GetAttribute("Spent") == true
end

local function update(dt: number)
	-- (Limp bodies still moving: a heap coming down. Ones lying still, asleep, cost nothing and do not count.)
	table.clear(limpMoving)
	for _, r in rigs do
		if (r.state == "Ragdoll" or r.state == "Out") and r.pelvis.Parent and r.pelvis.AssemblyLinearVelocity.Magnitude > CALM_SPEED then
			table.insert(limpMoving, r.pelvis.Position)
		end
	end
	for model, rig in rigs do
		if not model.Parent or not rig.pelvis.Parent then
			rigs[model] = nil
			continue
		end
		rig.stateTime += dt
		governSpeed(rig)
		guardLimbs(rig)
		local state = rig.state
		if state ~= "Ragdoll" and state ~= "Out" and state ~= "Frozen" and rig.held == 0 and vitalDown(rig) then
			enter(rig, "Ragdoll")
			state = rig.state
			-- (V9-0ac fix round 1: a body killed by a round falls away from it, not in a heap where it stood.)
			local dir = rig.lastShotDir
			if dir and rig.lastShotAt and os.clock() - rig.lastShotAt < DEATH_PUSH_WINDOW then
				local push = dir * DEATH_PUSH + Vector3.new(0, -2, 0)
				for _, p in rig.parts do
					if p ~= rig.root then
						p:ApplyImpulse(push * p.Mass)
					end
				end
			end
			rig.lastShotDir = nil
		end

		if state == "Standing" then
			if tiltDegrees(rig) > 60 then
				enter(rig, "Ragdoll")
			else
				think(rig)
				-- (V9-P3: hurt, it sways on its feet; whole, it stands still as before.)
				local hurt = if rig.state == "Standing" and rig.held == 0 then hurtOf(rig) else 0
				if hurt > 0 then
					rig.balance.CFrame = uprightFrame(swayUp(rig, hurt, Vector3.yAxis), rig.heading)
				elseif rig.swaySeed and rig.state == "Standing" then
					rig.balance.CFrame = uprightFrame(Vector3.yAxis, rig.heading) -- (patched up: straight again)
					rig.swaySeed = nil
				end
			end
		elseif state == "Walking" or state == "Fleeing" or state == "Crawling" then
			updateMoving(rig, dt)
		elseif state == "Flinch" then
			applyPose(rig, Poses.flinch(rig.hitRegion, rig.hitSide, rig.hitLimbSide, rig.stateTime))
			if rig.stateTime > 0.35 then
				startRamp(rig, "Recovering", 0.3)
			end
		elseif state == "Stumble" then
			applyPose(rig, Poses.brace(rig.stateTime))
			local tilt = tiltDegrees(rig)
			if tilt > TIP_TO_RAGDOLL_DEG or rig.stateTime > 2.5 then
				enter(rig, "Ragdoll")
			elseif rig.stateTime > 0.9 and tilt < 20 and torsoSpeed(rig) < 4 then
				startRamp(rig, "Recovering", 0.35)
			end
		elseif state == "Ragdoll" or state == "Out" then
			checkImpact(rig)
			local flying = isAirborne(rig)
			local P = (GameConfig :: any).PHYSICS
			if flying ~= rig.airborne then
				if not flying and rig.held == 0 then
					emit("Land", rig, rig.pelvis.Position, rig.pelvis.AssemblyLinearVelocity.Magnitude)
					-- (V9-P3 fix round 1: braced as it came down: the arms keep their tone through the
					-- first contact, so they really catch it.)
					if rig.bracing and P and P.CATCH_TIME then
						rig.catchUntil = os.clock() + P.CATCH_TIME
					end
				end
				rig.bracing = false
				rig.airborne = flying
				rig.model:SetAttribute("Airborne", flying)
			end
			-- Held: dangle and kick. Flying free: windmill. Lying: limp.
			-- Out cold or dead: limp even in the air or in a grab (round 4, M10: no kicking).
			local down = vitalDown(rig)
			local catching = not flying and rig.catchUntil ~= nil and os.clock() < rig.catchUntil and rig.held == 0
			local profile = if state == "Out" or down then "Ragdoll" elseif rig.held > 0 then "Held" elseif flying or catching then "Airborne" else "Ragdoll"
			if profile ~= rig.limpProfile then
				rig.limpProfile = profile
				applyProfile(rig, profile)
				if profile == "Ragdoll" then
					applyPose(rig, Poses.REST)
				end
			end
			if profile == "Held" then
				applyPose(rig, Poses.dangle(rig.stateTime))
			elseif profile == "Airborne" then
				-- (V9-P3: falling towards the ground it braces: the arms reach out to catch it, the head
				-- tucks, the knees bend; high up it windmills. Fix round 1: on the time to impact (about
				-- a third of a second, at the body's own clock in a time bubble), not a fixed height.)
				local bracing = catching
				if not bracing and (GameConfig :: any).PHYSICS_V9 and P and P.BRACE_TTI then
					local ts = timeScaleOf(rig)
					local fall = -rig.pelvis.AssemblyLinearVelocity.Y / ts
					-- (Not in a fast bubble: the fall is over in a blink there, and the pose fought the
					-- bubble's own gravity forces (T157).)
					-- (Fix round 2: arms out ahead catch a fall only when the chest faces down or ahead; on its
					-- back the "ahead" is the sky, so a body falling backwards does not reach up.)
					if fall > P.BRACE_FALL and ts <= 1 and rig.chest.CFrame.LookVector.Y < 0.35 then
						local ground = Workspace:Raycast(rig.pelvis.Position, Vector3.new(0, -P.BRACE_PROBE, 0), rig.rayParams)
						if ground then
							local gap = math.max(0, rig.pelvis.Position.Y - ground.Position.Y - AIR_CLEARANCE)
							bracing = gap / fall < P.BRACE_TTI
						end
					end
				end
				if bracing ~= (rig.bracing == true) then
					rig.model:SetAttribute("Bracing", bracing or nil) -- (on a change only: the bench and the looks read it)
				end
				rig.bracing = bracing
				applyPose(rig, if bracing then Poses.catch(rig.stateTime) else Poses.flail(rig.stateTime))
			end
			-- (Fix round 2: out of the air and the catch, the brace is over: a stale flag kept arms unbreakable
			-- on later knock-downs.)
			if profile ~= "Airborne" and rig.bracing then
				rig.bracing = false
				rig.model:SetAttribute("Bracing", nil)
			end
			if not flying and rig.held == 0 then
				settle(rig, dt)
			end
			if not flying and torsoSpeed(rig) < CALM_SPEED and rig.held == 0 and not rig.stayDown then
				rig.calmTime += dt
			else
				rig.calmTime = 0
			end
			local awake = (state ~= "Out" or os.clock() >= rig.koUntil) and not down
			-- (V9-P fix round 1: the settle assist calms a body sooner; a dummy still lies MIN_DOWN s, as long
			-- as before, so the fall can be enjoyed. A player's own body gets up as before.)
			local minDown = if (GameConfig :: any).PHYSICS_V9 and P and P.MIN_DOWN and rig.model:GetAttribute("IsDummy") == true then P.MIN_DOWN else MIN_RAGDOLL_TIME
			if rig.stateTime > minDown and rig.calmTime > CALM_TIME and awake then
				-- Both legs broken: no getting up, it crawls.
				if homeOf(rig) and brokenLegs(rig) >= 2 then
					enter(rig, "Crawling")
				else
					startRamp(rig, "GettingUp", GETUP_TIME)
				end
			end
		elseif state == "Recovering" then
			updateRamp(rig)
		elseif state == "GettingUp" then
			updateGetUp(rig)
		elseif state == "Frozen" then
			if rig.frozenWelds and rig.stateTime > FROZEN_TIME then
				thawLocal(rig)
			end
		end
	end
end

local function ensureLoop()
	if connection then
		return
	end
	connection = RunService.PostSimulation:Connect(update)
end

-- Hats, hair and tools on a player's avatar ride along on the limb they are welded to; they must not
-- collide with the body (a hat knocking against the chest makes the whole body jitter) or count as
-- body parts.
-- Worn or carried, not part of the body: accessories, tools, and anything marked Worn (the tool
-- shown in an avatar's hand: it must never start colliding or weighing when the body goes limp).
-- Any model it sits in, at any depth below the body, may say so (a real weapon model keeps its
-- pieces in a nested "Body" model: the mark on the held tool covers them too).
local function isWorn(part: BasePart): boolean
	if part:FindFirstAncestorOfClass("Accessory") or part:FindFirstAncestorOfClass("Tool") then
		return true
	end
	local node = part.Parent
	while node and node ~= game do
		if node:IsA("Model") then
			if node:GetAttribute("Worn") == true then
				return true
			end
			if node:FindFirstChildOfClass("Humanoid") then
				return false -- (the body itself: as far up as it looks)
			end
		end
		node = node.Parent
	end
	return false
end
ActiveRagdoll.isWornForTest = isWorn

-- Collisions and mass of a body that may go limp. Everything here replicates when the server does
-- it, so every machine agrees on collisions and mass. Returns the body's mass.
function ActiveRagdoll.prepareParts(model: Model): number
	local root = model:FindFirstChild("HumanoidRootPart")
	local mass = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and isWorn(part) then
			part.CanCollide = false
			part.Massless = true
		elseif part:IsA("BasePart") then
			if part == root then
				part.Massless = true
				part.CanCollide = false
				-- Once the joints come loose the root is its own assembly, where Massless does not
				-- count; it follows the pelvis, so it must weigh next to nothing or it drags the body.
				part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 1, 1)
			else
				part.CanCollide = true
				-- Grippy skin: a knocked-down body tumbles and stops instead of skating across the
				-- floor (plastic's 0.3 friction let a hit dummy slide 200 studs). Same density, so
				-- the mass does not change.
				local current = part.CurrentPhysicalProperties
				local density = current.Density
				-- (V9-P1: a dummy's mass spread like a real body's (Config.PHYSICS.MASS), the same total.)
				local want = if GameConfig.PHYSICS_V9 and model:GetAttribute("IsDummy") == true then (GameConfig.PHYSICS :: any).MASS[part.Name] else nil
				if want and part.Mass > 0 then
					density = math.clamp(density * want / part.Mass, 0.01, 100)
				end
				part.CustomPhysicalProperties = PhysicalProperties.new(density, BODY_FRICTION, 0.05, BODY_FRICTION_WEIGHT, 1)
				mass += part.Mass
			end
		end
	end
	return mass
end

-- Static setup of a dummy, done once by the server right after the model is parented to the world
-- (a player's client also does it for its own avatar, before going limp).
function ActiveRagdoll.prepare(model: Model): (boolean, string?)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local pelvis = model:FindFirstChild("LowerTorso")
	if not humanoid or not (root and root:IsA("BasePart")) or not (pelvis and pelvis:IsA("BasePart")) then
		return false, "not an R15 rig"
	end
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.EvaluateStateMachine = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local lowestFoot = math.huge
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = model:FindFirstChild(name)
		if foot and foot:IsA("BasePart") then
			lowestFoot = math.min(lowestFoot, foot.Position.Y - foot.Size.Y / 2)
		end
	end
	local mass = ActiveRagdoll.prepareParts(model)
	-- (V9-P1: a dummy's neck and spine swing with more weight: Config.PHYSICS.JOINT_FRICTION, once.)
	local P = (GameConfig :: any).PHYSICS
	if (GameConfig :: any).PHYSICS_V9 and P and P.JOINT_FRICTION and model:GetAttribute("IsDummy") == true and not model:GetAttribute("JointsTuned") then
		model:SetAttribute("JointsTuned", true)
		for _, d in model:GetDescendants() do
			if d:IsA("BallSocketConstraint") and d.Parent then
				local k = P.JOINT_FRICTION[d.Parent.Name]
				if k then
					d.MaxFrictionTorque *= k
				end
			end
		end
	end
	model:SetAttribute("Mass", mass)
	model:SetAttribute("StandOffset", pelvis.Position.Y - lowestFoot)
	model:SetAttribute("RagdollState", "Standing")
	return true, nil
end

-- Runtime setup on the machine that simulates the rig. Returns false with a reason if the rig
-- is not a usable AJU R15 rig.
function ActiveRagdoll.setup(model: Model): (boolean, string?)
	if rigs[model] then
		return true, nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local pelvis = model:FindFirstChild("LowerTorso")
	local chest = model:FindFirstChild("UpperTorso")
	if not humanoid or not (root and root:IsA("BasePart")) or not (pelvis and pelvis:IsA("BasePart")) or not (chest and chest:IsA("BasePart")) then
		return false, "not an R15 rig"
	end

	local joints: { [string]: AnimationConstraint } = {}
	local parts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") and Tone.groupOf(d.Name) then
			joints[d.Name] = d
		elseif d:IsA("BasePart") and d.Name ~= "Plaster" and d.Name ~= "Rocket" and d.Name ~= "Stump" and not isWorn(d) then
			table.insert(parts, d)
		end
	end
	local count = 0
	for _ in joints do
		count += 1
	end
	if count < 15 then
		return false, string.format("expected 15 AnimationConstraints, found %d", count)
	end

	if model:GetAttribute("Mass") == nil then
		local ok, err = ActiveRagdoll.prepare(model)
		if not ok then
			return false, err
		end
	end
	local mass = model:GetAttribute("Mass") :: number
	local standOffset = model:GetAttribute("StandOffset") :: number

	-- A Humanoid turns limb collisions off on the machine that takes over a character-like model,
	-- so the simulator enforces them itself (otherwise the legs sink through the floor).
	local connections: { RBXScriptConnection } = {}
	for _, part in parts do
		if part == root then
			part.Massless = true
			part.CanCollide = false
		else
			part.CanCollide = true
			table.insert(connections, part:GetPropertyChangedSignal("CanCollide"):Connect(function()
				if not part.CanCollide and rigs[model] then
					part.CanCollide = true
				end
			end))
		end
	end

	local created: { Instance } = {}
	-- Upright balance: the attachment's primary (X) axis points along the pelvis' up axis.
	local balanceAttachment = Instance.new("Attachment")
	balanceAttachment.Name = "BalanceAttachment"
	balanceAttachment.CFrame = CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.zAxis)
	balanceAttachment.Parent = pelvis
	table.insert(created, balanceAttachment)

	local balance = Instance.new("AlignOrientation")
	balance.Name = "Balance"
	balance.Mode = Enum.OrientationAlignmentMode.OneAttachment
	balance.AlignType = Enum.AlignType.PrimaryAxisParallel
	balance.PrimaryAxis = Vector3.yAxis
	balance.Attachment0 = balanceAttachment
	balance.Responsiveness = 40
	balance.Parent = pelvis
	table.insert(created, balance)

	local liftAttachment = Instance.new("Attachment")
	liftAttachment.Name = "LiftAttachment"
	liftAttachment.Parent = pelvis
	table.insert(created, liftAttachment)

	local lift = Instance.new("AlignPosition")
	lift.Name = "Lift"
	lift.Mode = Enum.PositionAlignmentMode.OneAttachment
	lift.Attachment0 = liftAttachment
	lift.Responsiveness = 20
	lift.MaxVelocity = 30
	lift.Enabled = false
	lift.Parent = pelvis
	table.insert(created, lift)

	-- Moves the body along the ground while it walks, flees or crawls (only sideways forces; the
	-- lift holds the height).
	local drive = Instance.new("LinearVelocity")
	drive.Name = "Drive"
	drive.Attachment0 = liftAttachment
	drive.RelativeTo = Enum.ActuatorRelativeTo.World
	drive.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	drive.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	drive.MaxAxesForce = Vector3.new(1, 0, 1) * mass * Config.NORMAL_GRAVITY * 2
	drive.VectorVelocity = Vector3.zero
	drive.Enabled = false
	drive.Parent = pelvis
	table.insert(created, drive)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { model }
	rayParams.RespectCanCollide = true -- triggers and decorations are neither ground nor walls

	local broken: { [string]: boolean } = {}
	for _, d in model:GetDescendants() do
		-- A rig handed over mid-life keeps its broken limbs (the server marks them with plasters).
		if d.Name == "Plaster" and d.Parent and d.Parent:IsA("BasePart") then
			for name, joint in joints do
				local a1 = joint.Attachment1
				if a1 and a1.Parent == d.Parent then
					broken[name] = true
				end
			end
		end
	end

	local rig: Rig = {
		model = model,
		humanoid = humanoid,
		root = root,
		pelvis = pelvis,
		chest = chest,
		joints = joints,
		parts = parts,
		mass = mass,
		standOffset = standOffset,
		balance = balance,
		lift = lift,
		drive = drive,
		created = created,
		connections = connections,
		state = "Standing",
		stateTime = 0,
		calmTime = 0,
		ramp = {},
		rampBalanceFrom = 0,
		rampDuration = 1,
		hitSide = 1,
		hitRegion = "torso",
		hitLimbSide = 1,
		airborne = false,
		groundY = 0,
		sinkCheckAt = 0,
		faceDown = true,
		rayParams = rayParams,
		broken = broken,
		frozenWelds = nil,
		frozenLooks = nil,
		held = 0,
		limpProfile = "Ragdoll",
		speedCap = 0,
		speedCapUntil = 0,
		speedCapHard = false,
		stayDown = false,
		lastHitAt = -math.huge,
		koUntil = 0,
		lastImpulseAt = -math.huge,
		lastImpactAt = -math.huge,
		impactSpeeds = {},
		impactCheckedAt = -math.huge,
		pendingKO = false,
		pendingUntil = 0,
		fleeFrom = nil,
		fleeUntil = 0,
		fledAt = -math.huge,
		gunFledAt = -math.huge,
		gunLookAt = 0,
		gunWary = false,
		panicking = false,
		speed = 0,
		heading = Vector3.new(0, 0, -1),
		stuckTime = 0,
		bestDistance = math.huge,
		steer = 0,
		steerUntil = 0,
		arriveTime = 0,
	}
	rigs[model] = rig
	if model:GetAttribute("Frozen") == true then
		rig.state = "Frozen"
		rig.balance.Enabled = false
		reportTransition(rig)
	else
		-- A rig handed over while lying down gets up from there (out cold stays out a little longer).
		if model:GetAttribute("RagdollState") == "Out" then
			rig.koUntil = os.clock() + KO_MIN
			enter(rig, "Out")
		else
			enter(rig, if tiltDegrees(rig) > 45 then "Ragdoll" else "Standing")
		end
	end
	ensureLoop()
	return true, nil
end

-- Stops simulating a rig here (ownership moved away). Leaves the model intact.
function ActiveRagdoll.teardown(model: Model)
	local rig = rigs[model]
	if not rig then
		return
	end
	rigs[model] = nil
	for _, instance in rig.created do
		instance:Destroy()
	end
	for _, c in rig.connections do
		c:Disconnect()
	end
end

function ActiveRagdoll.isSimulating(model: Model): boolean
	return rigs[model] ~= nil
end

function ActiveRagdoll.getState(model: Model): State?
	local rig = rigs[model]
	return if rig then rig.state else nil
end

-- Tests: how a limp rig hangs ("Ragdoll" | "Airborne" | "Held"; nil: not simulated here).
function ActiveRagdoll.limpProfileOf(model: Model): string?
	local rig = rigs[model]
	return if rig then rig.limpProfile else nil
end

function ActiveRagdoll.getMass(model: Model): number?
	local rig = rigs[model]
	if rig then
		return rig.mass
	end
	return model:GetAttribute("Mass") :: number?
end

-- Applies a hit. impulse is in mass-studs/s; the state is chosen from the speed it would give the
-- whole body. Returns the new state, or "Shatter" when a frozen dummy breaks (caller removes it).
-- maxBodySpeed: for physical hits (props, machines), the most the whole body may end up moving
-- sideways, collision included.
-- gun (round 3, M2): the round's wound power when a gun fired it (Toys: wound). A round does not
-- throw a body about, and where it lands decides what the body does, not how hard it pushed: an arm
-- or a hand flinches; one leg buckles at the knee (the other leg shot too within SHOT_MEMORY takes
-- it down); the body (the stomach, the chest, the back) and the head take it down, a nail (under
-- GUN_FELLS) only when SHOTS_TO_FELL of them hit the body in a row. A round in a limb moves only that
-- limb a little (LIMB_PUSH of the shove).
local SHOT_MEMORY = 8 -- s a leg or body shot is remembered
local GUN_FELLS = 0.9 -- wound power from which one round to the body takes it down
local SHOTS_TO_FELL = 3 -- weaker rounds (nails) to the body that take it down
local LIMB_PUSH = 0.3 -- share of a round's shove on an arm or a leg that it still falls from
-- side: +1 the right limb, -1 the left (a leg: both legs shot within SHOT_MEMORY take it down; the
-- same leg twice only buckles it again).
local LIMB_SHOTS_TO_FELL = 3 -- rounds to the arms and legs within SHOT_MEMORY that take it down (round 5)
function ActiveRagdoll.gunReaction(rig: any, region: string, gun: number, now: number, side: number?): string
	-- V9-0ac (GameConfig.SHOT_FLINCH): a round never knocks a living body down. An arm or the head
	-- flinches, a leg buckles (it limps on), the body staggers back from a strong round and flinches
	-- from a light one. It drops when the damage kills it (VitalsService), never from the push.
	if (GameConfig :: any).SHOT_FLINCH then
		if region == "leg" then
			local shot = rig.legShotAt or {}
			rig.legShotAt = shot
			shot[if side == 1 then "Right" else "Left"] = now
			rig.limpUntil = now + LEG_LIMP_TIME -- (it limps on a while)
		end
		-- (Fix round 1: never a Stumble either; that state's weak legs and low balance tipped a body
		-- under a fast Popper or an AK burst before the damage dropped it.)
		return "Flinch"
	end
	-- Round 5, phase 00: rounds add up. A third one in the arms or legs within SHOT_MEMORY takes it
	-- down too (a phone player's taps land on limbs as often as not; they kept shooting and nothing fell).
	if region == "arm" or region == "leg" then
		rig.limbShots = (if now - (rig.limbShotAt or -math.huge) < SHOT_MEMORY then rig.limbShots or 0 else 0) + 1
		rig.limbShotAt = now
		if rig.limbShots >= LIMB_SHOTS_TO_FELL then
			rig.limbShots = 0
			return "Ragdoll"
		end
	end
	if region == "arm" then
		return "Flinch"
	elseif region == "leg" then
		local shot = rig.legShotAt or {}
		rig.legShotAt = shot
		shot[if side == 1 then "Right" else "Left"] = now
		local otherSide = if side == 1 then "Left" else "Right"
		local other = shot[otherSide]
		if other and now - other < SHOT_MEMORY then
			return "Ragdoll"
		end
		-- (Also the server's note on the body: the other leg may have been hit while another machine
		-- simulated it.)
		local model = rig.model
		local noted = if typeof(model) == "Instance" then model:GetAttribute("LegShot" .. otherSide) else nil
		return if type(noted) == "number" and Workspace:GetServerTimeNow() - noted < SHOT_MEMORY then "Ragdoll" else "Flinch"
	end
	if gun >= GUN_FELLS then
		return "Ragdoll"
	end
	rig.bodyShots = (if now - (rig.bodyShotAt or -math.huge) < SHOT_MEMORY then rig.bodyShots or 0 else 0) + 1
	rig.bodyShotAt = now
	return if rig.bodyShots >= SHOTS_TO_FELL then "Ragdoll" else "Stumble"
end

-- The names of the parts of limbs torn off this body (VitalsService's "Severed"), or nil.
local function severedParts(model: Model): { [string]: boolean }?
	local raw = model:GetAttribute("Severed")
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local out = {}
	for limb in string.gmatch(raw, "[^,]+") do
		local spec = Anatomy.LIMBS[limb]
		if spec then
			for _, name in spec.parts do
				out[name] = true
			end
		end
	end
	return out
end

function ActiveRagdoll.hit(model: Model, part: BasePart, impulse: Vector3, position: Vector3, maxBodySpeed: number?, gun: number?): string?
	local rig = rigs[model]
	if not rig or not part:IsDescendantOf(model) then
		return nil
	end
	local deltaV = impulse.Magnitude / rig.mass
	-- Hits stack while the cap holds (a second hit may send the body further). A body that was
	-- already sliding keeps a little of that speed; not all of it, because by the time a (deferred)
	-- contact hit is applied the collision itself may already have shoved the body.
	local was = rig.pelvis.AssemblyLinearVelocity
	local cap = math.min(Vector3.new(was.X, 0, was.Z).Magnitude, HIT_SPEED_CARRY) + deltaV * HIT_SPEED_SLACK + HIT_SPEED_EXTRA
	local hard = maxBodySpeed ~= nil
	if maxBodySpeed then
		cap = maxBodySpeed
	end
	local now = os.clock()
	local open = now < rig.speedCapUntil
	rig.speedCap = if open then math.max(rig.speedCap, cap) else cap
	rig.speedCapHard = if open then rig.speedCapHard and hard else hard
	rig.speedCapUntil = now + HIT_SPEED_HOLD
	local current = rig.state
	if current == "Frozen" then
		if deltaV >= FLINCH_MAX * 0.5 then
			emit("Shatter", rig, rig.chest.Position, deltaV)
			return "Shatter"
		end
		part:ApplyImpulseAtPosition(impulse, position)
		return "Frozen"
	end
	-- Hit from the dummy's right pushes towards its left.
	rig.hitSide = if impulse:Dot(rig.chest.CFrame.RightVector) < 0 then 1 else -1
	rig.hitRegion = Poses.regionOf(part.Name)
	rig.hitLimbSide = if string.sub(part.Name, 1, 5) == "Right" then 1 else -1

	if deltaV >= FLINCH_MAX * 0.5 then
		rig.lastHitAt = now -- it remembers who hurts it (and runs from people for a while)
	end
	rig.lastImpulseAt = now
	-- V8-0.2 (the first hit lands): a newcomer's first few hits with any tool knock it flat with a
	-- big, readable flop: thrown back at FIRST_HIT_PUSH studs/s at the least, a little up. (The
	-- playtest needed 7 shots for the first knock-down; time played follows takedowns.) The client
	-- sets firstHitsLeft for a newcomer; it is 0 everywhere else.
	local firstHit = ActiveRagdoll.ownHit and ActiveRagdoll.firstHitsLeft > 0 and rig.held == 0
		and (current == "Standing" or current == "Walking" or current == "Fleeing" or current == "Flinch" or current == "Stumble" or current == "Recovering")
	if firstHit then
		ActiveRagdoll.firstHitsLeft -= 1
		local flat = Vector3.new(impulse.X, 0, impulse.Z)
		local dir = if flat.Magnitude > 1e-3 then flat.Unit else -rig.chest.CFrame.LookVector
		local speed = math.max(deltaV, ActiveRagdoll.FIRST_HIT_PUSH)
		impulse = (dir + Vector3.new(0, 0.3, 0)).Unit * speed * rig.mass
		deltaV = speed
		rig.speedCap = math.max(rig.speedCap, speed + HIT_SPEED_EXTRA) -- (the round's own small cap would hold it back)
		enter(rig, "Ragdoll")
		emit("FirstHit", rig, position, speed)
	elseif current == "Out" then
		enter(rig, "Out") -- still out cold, just moved
	elseif gun and gun > 0 and (GameConfig :: any).SHOT_FLINCH and (current == "GettingUp" or current == "Crawling" or current == "Stumble" or current == "Walking" or current == "Fleeing") and rig.held == 0 then
		-- (V9-0ac fix round 1: a round on a body getting up or crawling does not floor it again; the
		-- struck part jerks, it carries on. Fix round 3: nor one stumbling (its weak legs tipped it over),
		-- nor one walking or running away (it stopped dead): it keeps going, a leg round still limps it.)
		ActiveRagdoll.gunReaction(rig, rig.hitRegion, gun, now, rig.hitLimbSide)
		impulse *= LIMB_PUSH
	elseif gun and gun > 0 and current ~= "Ragdoll" and current ~= "GettingUp" and current ~= "Crawling" and rig.held == 0 then
		local reaction = ActiveRagdoll.gunReaction(rig, rig.hitRegion, gun, now, rig.hitLimbSide)
		if reaction ~= "Ragdoll" and (rig.hitRegion == "arm" or rig.hitRegion == "leg") then
			impulse *= LIMB_PUSH -- (it stays up: the limb jerks, the body hardly moves)
		end
		-- (A stagger on a stagger is still a stagger; a flinch never undoes one.)
		enter(rig, (if reaction == "Flinch" and current == "Stumble" then "Stumble" else reaction) :: any)
	elseif deltaV >= STUMBLE_MAX or current == "Ragdoll" or current == "GettingUp" or current == "Crawling" or rig.held > 0 then
		enter(rig, "Ragdoll")
	elseif deltaV >= FLINCH_MAX or current == "Stumble" then
		enter(rig, "Stumble")
	else
		enter(rig, "Flinch")
	end
	-- Part of the hit moves the whole body (so big hits really launch it), the rest lands on the
	-- part that was struck (so it reacts where it was hit). Small hits are mostly local and softened.
	local bodyShare = BODY_SHARE[if rig.state == "Out" then "Ragdoll" else rig.state] or 0.5
	local bodyVelocity = impulse * bodyShare / rig.mass
	-- A body on the floor cannot be pushed into it: the floor takes the downward part of a hit
	-- (anvils, stomps). Pushing it in anyway makes the solver fire the body into the air.
	local grounded = not isAirborne(rig)
	if grounded and bodyVelocity.Y < -GROUND_PUSH_MAX then
		bodyVelocity = Vector3.new(bodyVelocity.X, -GROUND_PUSH_MAX, bodyVelocity.Z)
	end
	-- Sent flying (by what the body really gets): no damage now; the impact that ends the flight
	-- decides (checkImpact).
	local launched = bodyVelocity.Magnitude >= LAUNCH_SPEED
	-- A hard knock to the head (or a huge hit anywhere) leaves it out cold for a few seconds.
	local knocked = not gun and ((rig.hitRegion == "head" and deltaV >= KO_HEAD_SPEED) or deltaV >= KO_SPEED) -- (a round: the wound decides, VitalsService)
	if rig.state == "Ragdoll" and rig.held == 0 and homeOf(rig) and knocked then
		if launched then
			rig.pendingKO = true -- out cold when it lands
			rig.pendingUntil = now + PENDING_TIME
		else
			rig.koUntil = now + KO_MIN + math.random() * (KO_MAX - KO_MIN)
			enter(rig, "Out")
		end
	end
	-- (A limb torn off lies on the floor apart from the body: the body's shove is not its.)
	local off = severedParts(rig.model)
	for _, p in rig.parts do
		if p ~= rig.root and not (off and off[p.Name]) then
			p:ApplyImpulse(bodyVelocity * p.Mass)
		end
	end
	local localScale = if rig.state == "Flinch" then 0.35 else 1
	local localImpulse = impulse * (1 - bodyShare) * localScale
	if gun and gun > 0 and (GameConfig :: any).SHOT_FLINCH then
		-- (Fix round 1: a light part is never flicked: the round's own jerk is capped by its real mass.)
		local cap = part.AssemblyMass * GUN_LOCAL_MAX
		if localImpulse.Magnitude > cap then
			localImpulse = localImpulse.Unit * cap
		end
		-- (Remembered: a death from this round falls away from it.)
		local flat = Vector3.new(impulse.X, 0, impulse.Z)
		if flat.Magnitude > 1e-3 then
			rig.lastShotDir = flat.Unit
			rig.lastShotAt = now
		end
	end
	local partMass = math.max(part.AssemblyMass, 0.5)
	local breaks = not gun and localImpulse.Magnitude / partMass >= BREAK_LOCAL_SPEED -- (a round goes through: no break)
	if grounded and localImpulse.Y / partMass < -GROUND_PUSH_MAX * 2 then
		localImpulse = Vector3.new(localImpulse.X, -GROUND_PUSH_MAX * 2 * partMass, localImpulse.Z)
	end
	part:ApplyImpulseAtPosition(localImpulse, position)
	if breaks and not launched then
		breakLimb(rig, part) -- a hard blow that does not send it flying (a hammer on a body lying down)
	elseif breaks and BREAKABLE[part.Name] then
		rig.pendingLimb = part -- breaks when it lands
		rig.pendingUntil = now + PENDING_TIME
	end
	clampVelocities(rig)
	return rig.state
end

-- Adds velocity to the whole body without choosing a new state (wind, conveyor, magnet).
-- A standing dummy treats a strong push as a hit to the chest.
-- maxSpeed (optional, V8-1.1): how fast this push may leave the body (above MAX_LINEAR_SPEED only for
-- the player's own body thrown by the human cannon's long arc).
function ActiveRagdoll.push(model: Model, deltaVelocity: Vector3, maxSpeed: number?)
	local rig = rigs[model]
	if not rig or rig.state == "Frozen" then
		return
	end
	rig.pushedAt = os.clock() -- (V9-P fix round 1: the settle assist leaves a pushed body alone)
	if deltaVelocity.Magnitude >= PUSH_IMPULSE_MIN then
		rig.lastImpulseAt = os.clock() -- a real shove changes speeds too: not an impact
	end
	if rig.state == "Standing" or rig.state == "Recovering" or rig.state == "Walking" or rig.state == "Fleeing" then
		if deltaVelocity.Magnitude >= FLINCH_MAX then
			ActiveRagdoll.hit(model, rig.chest, deltaVelocity * rig.mass, rig.chest.Position)
		end
		return
	end
	for _, p in rig.parts do
		-- (V8-1.1: a launch past MAX_LINEAR_SPEED, the cannon's long arc, moves the root too: left out,
		-- the joints ate about 15% of it and the arc fell short.)
		if p ~= rig.root or maxSpeed ~= nil then
			p:ApplyImpulse(deltaVelocity * p.Mass)
		end
	end
	clampVelocities(rig, maxSpeed)
end

-- Grabbing: the grabbed body goes limp and will not get up while held.
function ActiveRagdoll.setHeld(model: Model, held: boolean)
	local rig = rigs[model]
	if not rig or rig.state == "Frozen" then
		return
	end
	local wasHeld = rig.held > 0
	rig.held = math.max(0, rig.held + (if held then 1 else -1))
	if held and rig.state ~= "Ragdoll" and rig.state ~= "Out" then
		enter(rig, "Ragdoll") -- reports, including the held flag (out cold stays out cold)
	elseif wasHeld ~= (rig.held > 0) then
		reportTransition(rig) -- same state, but everyone should see it is (no longer) held
	end
	rig.calmTime = 0
end

-- A body that should stay limp until told otherwise (a player who ragdolled on purpose). Clearing it
-- lets the body get up as soon as it is lying still.
function ActiveRagdoll.setStayDown(model: Model, stay: boolean)
	local rig = rigs[model]
	if rig then
		rig.stayDown = stay
		rig.calmTime = 0
	end
end

-- Gets up now if lying on the ground (in the air it waits until it lands and is still).
function ActiveRagdoll.getUp(model: Model)
	local rig = rigs[model]
	if not rig or rig.state ~= "Ragdoll" then
		return
	end
	rig.stayDown = false
	if not isAirborne(rig) and rig.held == 0 then
		startRamp(rig, "GettingUp", GETUP_TIME)
	end
end

-- Freeze ray on a dummy this machine simulates and owns visually (server).
function ActiveRagdoll.freeze(model: Model)
	local rig = rigs[model]
	if rig then
		freezeLocal(rig)
	end
end

-- The server froze or thawed an owned dummy; the simulator only switches state.
function ActiveRagdoll.setExternalFrozen(model: Model, frozen: boolean)
	local rig = rigs[model]
	if not rig then
		return
	end
	if frozen and rig.state ~= "Frozen" then
		stopMoving(rig)
		rig.lift.Enabled = false
		rig.state = "Frozen"
		rig.stateTime = 0
		rig.balance.Enabled = false
		rig.lift.Enabled = false
		rig.held = 0
		reportTransition(rig)
	elseif not frozen and rig.state == "Frozen" then
		enter(rig, "Ragdoll")
	end
end

-- Mends broken limbs (plasters are removed by the server).
function ActiveRagdoll.heal(model: Model)
	local rig = rigs[model]
	if not rig then
		return
	end
	rig.broken = {}
	model:SetAttribute("Broken", 0)
	if RunService:IsServer() then
		for _, d in model:GetDescendants() do
			if d.Name == "Plaster" then
				d:Destroy()
			end
		end
	end
	local state = rig.state
	if state == "Standing" or state == "Walking" or state == "Fleeing" then
		enter(rig, "Standing")
	elseif state == "Ragdoll" or state == "Crawling" then
		enter(rig, "Ragdoll") -- lying (or crawling on mended legs): gets up from there
	else
		-- Out cold, getting up, recovering, flinching or frozen: it carries on with that; only the
		-- limbs are whole again (out cold keeps its limp tone; the ramps set every joint themselves;
		-- the ice is the server's to thaw).
		if state == "Out" then
			applyProfile(rig, "Ragdoll")
		end
		reportTransition(rig)
	end
end

-- Puts a rig back to a clean standing state where it is (after a teleport home).
function ActiveRagdoll.reset(model: Model)
	local rig = rigs[model]
	if not rig then
		return
	end
	if rig.frozenWelds then
		thawLocal(rig)
	end
	rig.broken = {}
	rig.held = 0
	-- A fresh start: no memory of being hurt, not out cold, not running from anyone.
	rig.lastHitAt = -math.huge
	rig.koUntil = 0
	rig.pendingLimb = nil
	rig.pendingKO = false
	rig.pendingUntil = 0
	rig.fleeUntil = 0
	rig.fleeFrom = nil
	rig.fledAt = -math.huge
	rig.gunFledAt = -math.huge
	rig.panicking = false
	model:SetAttribute("Broken", 0)
	if RunService:IsServer() then
		model:SetAttribute("BrokenJoints", "")
		for _, d in model:GetDescendants() do
			if d.Name == "Plaster" then
				d:Destroy()
			end
		end
	end
	for _, part in rig.parts do
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end
	-- (Round 4, M10: a body out cold or dead is never stood up, not even for a frame.)
	enter(rig, if vitalDown(rig) then "Ragdoll" else "Standing")
end

function ActiveRagdoll.isBroken(model: Model, jointName: string): boolean
	local rig = rigs[model]
	return rig ~= nil and rig.broken[jointName] == true
end

-- Forces a state (debug and tests).
function ActiveRagdoll.setState(model: Model, state: State)
	local rig = rigs[model]
	if not rig then
		return
	end
	if state == "GettingUp" or state == "Recovering" then
		startRamp(rig, state, if state == "GettingUp" then GETUP_TIME else 0.3)
	elseif state == "Frozen" then
		freezeLocal(rig)
	else
		enter(rig, state)
	end
end

-- V9-P fix round 2: a body whose weight changed after its rig was set up (GOD MODE's kinds: DummySpawn
-- writes Mass and StandOffset after spawning) gets the forces that hold it up sized again.
function ActiveRagdoll.refreshMass(model: Model)
	local rig = rigs[model]
	if not rig then
		return
	end
	local mass = model:GetAttribute("Mass")
	local offset = model:GetAttribute("StandOffset")
	if type(mass) == "number" and mass > 0 then
		rig.mass = mass
	end
	if type(offset) == "number" and offset > 0 then
		rig.standOffset = offset
	end
	rig.drive.MaxAxesForce = Vector3.new(1, 0, 1) * rig.mass * Config.NORMAL_GRAVITY * 2 -- (fix round 3: the walk too)
	enter(rig, rig.state) -- (the state's forces again, at the new weight)
end

return ActiveRagdoll
