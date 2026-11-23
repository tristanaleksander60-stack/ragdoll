--!strict
-- Makes every dummy feel alive on this screen: a face that reacts to what happens to it, blinking,
-- breathing, a relaxed stance, looking at the nearest person, and dizzy stars after a tumble.
-- Getting about (walking home, running away, limping on a broken leg, crawling on two) is animated
-- here too, from how fast the body moves; a broken arm hangs and the other hand clutches it.
--
-- Purely cosmetic and local. Every client runs it for every dummy it can see, driven by the
-- replicated RagdollState / Held / Frozen / Broken attributes, so all screens agree on the mood.
-- Idle motion writes Transform on the kinematic joints of a Standing dummy: Transform never
-- replicates and kinematic joints follow it exactly, so it costs no network and never fights the
-- physics. It lets go of the joints the moment the dummy leaves Standing.
--
-- People in the crowd (CrowdService) talk: two who are Chatting face each other and take turns, the
-- speaker's hands going and a speech bubble ("..." or a laugh) over its head; one in a panic shows a
-- red "!" as it runs. Far away and off screen, dummies are animated less often (a phone draws a lab
-- and a plaza full of people).
--
-- Round 2 (N1): nobody just stands there. Now and then each one does something small (stretches,
-- scratches its head, checks its watch, looks around, folds its arms). Every one of them turns to
-- look at a bang it hears (a shot, a blast, a hard hit: FxController tells this module about every
-- moment it plays), the nearer and louder the sooner, with a little start. One greeting a player
-- (GreetUntil, set by the server's Lab) waves and says "HI!".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local GunThreat = require(Shared:WaitForChild("GunThreat"))
local Config = require(Shared:WaitForChild("Config"))
local DummyLines = require(Shared:WaitForChild("DummyLines"))
local Poses = require(Shared:WaitForChild("Ragdoll"):WaitForChild("Poses")) :: any
local Anatomy = require(Shared:WaitForChild("Anatomy"))

local Faces = Assets.Faces
local rad, deg, sin, cos = math.rad, math.deg, math.sin, math.cos
local TAU = 2 * math.pi

local LOOK_RANGE = 45 -- studs
local NOISE_LOOK = 2.6 -- s a dummy keeps looking at a bang it heard
local NOISE_START = 0.3 -- s of the little start it gives
local SOUND_SPEED = 300 -- studs/s: further off, it hears it a beat later
-- How far a moment is heard (studs), by what it was (FxController passes the tool's fx kind).
local HEARD = { Boom = 90, Zap = 30, Big = 35, Clang = 30, Smack = 22, Light = 14, Dart = 16, Pop = 18, Ice = 14, Suck = 26 }
local HANDS_EASE = 0.18 -- s the hands take to go up or down
local THREAT_GRACE = 2 -- s a gun can leave the aim before it counts as gone (getting used to it carries on)
local SHOT_HEARD = 120 -- the guns: a shot is heard across the lab and the plaza (round 3, M3: everyone looks)
local ROW_HEARD = 40 -- any hit is heard at least this far (a lab's row of six is 25 wide)
local GESTURE_GAP_MIN, GESTURE_GAP_MAX = 5, 13 -- s between two idle gestures
local GESTURES = { "Stretch", "Scratch", "Watch", "LookAround", "Arms", "Shrug" }
local MAX_YAW, MAX_PITCH_UP, MAX_PITCH_DOWN = 70, 30, 25
local LOOK_SMOOTH = 5 -- 1/s
local AIR_CLEARANCE = require(Shared:WaitForChild("Ragdoll"):WaitForChild("Config")).AIR_CLEARANCE
local LAND_OUCH = 0.45 -- seconds of "ouch" after hitting the ground
local STARS_AFTER = 2.6 -- seconds the stars stay after the dizzy face ends
local STARS_DELAY = 0.45 -- dizzy this long before stars appear
local GRUMPY_AFTER_GETUP = 1.4
local TALK_TURN = 2.4 -- s each speaker talks before the other answers
-- Round 4, M11 (the owner: the bubbles were far too big and distracting): small (a third of the old
-- area, the same on every screen so a phone can still read it), quiet when it is only chatter,
-- only near, and above any hat (a Santa hat or a chef's hat reaches 2.6 studs over the head).
local BUBBLES = false -- the speech bubbles (off: the owner wants faces and bodies, no text)
local BUBBLE_DISTANCE = 45 -- studs: bubbles further away are not drawn
local BUBBLE_SIZE = Vector2.new(42, 26) -- px (was 64 x 40)
local BUBBLE_OFFSET = 3 -- studs above the head's middle
-- Level of detail (distance from the camera): every frame up close, then less often, then not at all.
local LOD_NEAR, LOD_FAR = 70, 170
local LOD_MID_RATE = 1 / 15 -- s between updates beyond LOD_NEAR
local IDLE_JOINTS = { "Neck", "Waist", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow" }
local GAIT_JOINTS = {
	"Neck", "Waist", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow",
	"RightHip", "LeftHip", "RightKnee", "LeftKnee",
}
local MOVING = { Walking = true, Fleeing = true, Crawling = true }
local LEG_LIMBS = { "RightUpperLeg", "RightLowerLeg", "LeftUpperLeg", "LeftLowerLeg" }
local ARM_LIMBS = { "RightUpperArm", "RightLowerArm", "LeftUpperArm", "LeftLowerArm" }
-- The joints a broken limb hangs from: loose, so no pose may drive them.
local LOOSE_LEG = { [1] = { "RightHip", "RightKnee" }, [-1] = { "LeftHip", "LeftKnee" } }
local LOOSE_ARM = { [1] = { "RightShoulder", "RightElbow" }, [-1] = { "LeftShoulder", "LeftElbow" } }
-- Studs travelled per full step cycle.
local STRIDE = { Walking = 4.2, Fleeing = 6.5, Limp = 3, Crawling = 2.6 }

type Life = {
	model: Model,
	head: BasePart,
	chest: BasePart,
	pelvis: BasePart,
	face: ImageLabel?,
	joints: { [string]: AnimationConstraint },
	seed: number,
	shown: string?,
	blinkAt: number,
	blinkUntil: number,
	yaw: number,
	pitch: number,
	idle: boolean,
	state: string,
	stateSince: number,
	previous: string,
	airborne: boolean,
	ouchUntil: number,
	dizzySince: number?,
	starsUntil: number,
	stars: BillboardGui?,
	starImages: { ImageLabel },
	rayParams: RaycastParams,
	lookTarget: Vector3?,
	lookPickAt: number,
	threat: Vector3?, -- a gun held out close by (GunThreat), re-picked with the look target
	threatRaised: boolean, -- that gun fired a moment ago
	handsW: number, -- how far the hands are up (0-1, eased)
	threatSince: number?, -- since when a gun is pointed at it (it gets used to one that never fires)
	threatAt: number, -- when a gun was last pointed at it (a coward running from it shows "!")
	gunFlee: boolean, -- this run is from a gun ("!")
	gunFleeFor: number, -- the run (its stateSince) gunFlee was looked at for
	handsUp: boolean,
	gait: boolean, -- gait joints are being animated
	phase: number, -- step cycle, 0..1 per stride
	lastPosition: Vector3,
	groundSpeed: number, -- smoothed
	brokenAt: number, -- when the plasters were last looked at
	brokenLeg: number, -- 0 none, +1 right, -1 left, 2 both
	brokenArm: number, -- 0 none, +1 right, -1 left, 2 both
	loose: { [string]: boolean }, -- joints of broken limbs: never posed here
	bubble: BillboardGui?, -- speech or panic bubble (made when first needed)
	bubbleText: TextLabel?,
	bubbleKind: string?,
	line: BillboardGui?, -- LOOK_V3: the black line box (made when first needed)
	lineText: TextLabel?,
	lineKind: string?, -- "Fear", "Ouch" or "Idle" while one is up
	lineUntil: number,
	lineTurn: number,
	woundsRaw: string, -- 0.36.7: the Wounds list last seen (a longer one = a new hit to answer)
	idleAt: number, -- next idle line (os.clock)
	wasHandsUp: boolean,
	ouchFor: number, -- the stateSince of the last get-up already answered
	lodWait: number, -- s gathered since the last update (far away)
	noiseAt: number, -- when it heard the last bang (os.clock, after the sound's delay)
	noisePos: Vector3?,
	gesture: string?, -- the idle gesture it is doing
	gestureAt: number,
	gestureLength: number,
	nextGestureAt: number,
}

local DummyLife = {}

local lives: { [Model]: Life } = {}
local pendingModels: { [Model]: boolean } = {}
local rng = Random.new()

local function ang(x: number, y: number, z: number): CFrame
	return CFrame.Angles(rad(x), rad(y), rad(z))
end

local function build(model: Model): Life?
	local head = model:FindFirstChild("Head")
	local chest = model:FindFirstChild("UpperTorso")
	local pelvis = model:FindFirstChild("LowerTorso")
	if not (head and head:IsA("BasePart") and chest and chest:IsA("BasePart") and pelvis and pelvis:IsA("BasePart")) then
		return nil
	end
	local joints: { [string]: AnimationConstraint } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") then
			joints[d.Name] = d
		end
	end
	if not joints.Neck then
		return nil
	end
	local gui = head:FindFirstChild("Face")
	local face = gui and gui:FindFirstChild("Image")
	if not (face and face:IsA("ImageLabel")) then
		return nil -- the face arrives with the head; wait for it
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	local now = os.clock()
	return {
		model = model,
		head = head,
		chest = chest,
		pelvis = pelvis,
		face = face,
		joints = joints,
		seed = rng:NextNumber(0, 100),
		shown = nil,
		blinkAt = now + rng:NextNumber(0.5, 3),
		blinkUntil = 0,
		yaw = 0,
		pitch = 0,
		idle = false,
		state = "Standing",
		stateSince = now,
		previous = "Standing",
		airborne = false,
		ouchUntil = 0,
		dizzySince = nil,
		starsUntil = 0,
		stars = nil,
		starImages = {},
		rayParams = params,
		lookTarget = nil,
		lookPickAt = 0,
		threat = nil,
		threatRaised = false,
		handsW = 0,
		threatSince = nil,
		threatAt = -math.huge,
		gunFlee = false,
		gunFleeFor = -1,
		handsUp = false,
		gait = false,
		phase = 0,
		lastPosition = pelvis.Position,
		groundSpeed = 0,
		brokenAt = 0,
		brokenLeg = 0,
		brokenArm = 0,
		loose = {},
		bubble = nil,
		bubbleText = nil,
		bubbleKind = nil,
		line = nil,
		lineText = nil,
		lineKind = nil,
		lineUntil = 0,
		lineTurn = 0,
		woundsRaw = "",
		idleAt = os.clock() + rng:NextNumber(4, 30),
		wasHandsUp = false,
		ouchFor = -1,
		lodWait = 0,
		noiseAt = -math.huge,
		noisePos = nil,
		gesture = nil,
		gestureAt = 0,
		gestureLength = 0,
		nextGestureAt = now + rng:NextNumber(2, GESTURE_GAP_MAX),
	}
end

local function setFace(life: Life, name: string)
	if life.shown == name then
		return
	end
	life.shown = name
	local face = life.face
	if face and face.Parent then
		face.Image = (Faces :: any)[name]
	end
end

local function releaseIdle(life: Life)
	if not life.idle then
		return
	end
	life.idle = false
	for _, name in IDLE_JOINTS do
		local joint = life.joints[name]
		if joint then
			joint.Transform = CFrame.identity
		end
	end
end

local function releaseGait(life: Life)
	if not life.gait then
		return
	end
	life.gait = false
	for _, name in GAIT_JOINTS do
		local joint = life.joints[name]
		if joint then
			joint.Transform = CFrame.identity
		end
	end
end

-- Which limbs carry a plaster (the server puts one on every broken limb).
local function readBroken(life: Life, now: number)
	if now - life.brokenAt < 0.3 then
		return
	end
	life.brokenAt = now
	local legs, arms = 0, 0
	local function side(name: string): number
		return if string.sub(name, 1, 5) == "Right" then 1 else -1
	end
	for _, name in LEG_LIMBS do
		local limb = life.model:FindFirstChild(name)
		if limb and limb:FindFirstChild("Plaster") then
			legs = if legs ~= 0 and legs ~= side(name) then 2 else (if legs == 2 then 2 else side(name))
		end
	end
	for _, name in ARM_LIMBS do
		local limb = life.model:FindFirstChild(name)
		if limb and limb:FindFirstChild("Plaster") then
			arms = if arms ~= 0 and arms ~= side(name) then 2 else (if arms == 2 then 2 else side(name))
		end
	end
	-- (V9-0ac fix round 2: a leg round a while ago limps it on too, on every screen: the server notes it
	-- on the body, LegShotLeft / LegShotRight.)
	if legs == 0 then
		local ok, shot = pcall(function()
			return (require(game:GetService("ReplicatedStorage").Shared.Ragdoll.ActiveRagdoll) :: any).legShotSide(life.model)
		end)
		if ok and type(shot) == "number" and shot ~= 0 then
			legs = shot
		end
	end
	life.brokenLeg = legs
	life.brokenArm = arms
	table.clear(life.loose)
	for side, names in LOOSE_LEG do
		if legs == side or legs == 2 then
			for _, name in names do
				life.loose[name] = true
			end
		end
	end
	for side, names in LOOSE_ARM do
		if arms == side or arms == 2 then
			for _, name in names do
				life.loose[name] = true
			end
		end
	end
end

-- Whatever the poses wrote, a broken limb's joints get no target: it hangs.
local function freeLoose(life: Life)
	for name in life.loose do
		local joint = life.joints[name]
		if joint and joint.Transform ~= CFrame.identity then
			joint.Transform = CFrame.identity
		end
	end
end

-- One arm broken: it hangs (its joint is loose), the other hand holds it.
local function clutch(life: Life, strength: number)
	local broken = life.brokenArm
	if broken ~= 1 and broken ~= -1 then
		return
	end
	local j = life.joints
	-- The healthy arm reaches across the chest to the broken one.
	local shoulder = if broken == 1 then j.LeftShoulder else j.RightShoulder
	local elbow = if broken == 1 then j.LeftElbow else j.RightElbow
	local across = if broken == 1 then 32 else -32 -- towards the other side (left arm: +Z is inward)
	if shoulder then
		shoulder.Transform = shoulder.Transform:Lerp(ang(48, 0, across), strength)
	end
	if elbow then
		elbow.Transform = elbow.Transform:Lerp(ang(100, 0, 0), strength)
	end
end

local function setJoint(life: Life, name: string, cf: CFrame)
	local joint = life.joints[name]
	if joint then
		joint.Transform = cf
	end
end

-- Walking, running away, limping and crawling, timed by how fast the body really moves.
local function gaitPose(life: Life, state: string, now: number, dt: number)
	local position = life.pelvis.Position
	local moved = Vector3.new(position.X - life.lastPosition.X, 0, position.Z - life.lastPosition.Z).Magnitude
	life.lastPosition = position
	local speed = if dt > 0 then math.min(moved / dt, 30) else 0
	life.groundSpeed += (speed - life.groundSpeed) * (1 - math.exp(-8 * dt))
	local limp = state ~= "Crawling" and (life.brokenLeg == 1 or life.brokenLeg == -1)
	local stride = if state == "Crawling" then STRIDE.Crawling elseif limp then STRIDE.Limp else STRIDE[state] or STRIDE.Walking
	life.phase = (life.phase + life.groundSpeed * dt / stride) % 1
	local p = life.phase * TAU
	local s, c = sin(p), cos(p)
	-- Barely moving (setting off, turning on the spot): the cycle fades in.
	local amount = math.clamp(life.groundSpeed / 2.5, 0, 1)
	life.gait = true

	if state == "Crawling" then
		-- Face down, arms reaching forward and pulling in turn, head up, legs trailing.
		setJoint(life, "RightShoulder", ang(125 + 45 * s * amount, 0, 14))
		setJoint(life, "LeftShoulder", ang(125 - 45 * s * amount, 0, -14))
		setJoint(life, "RightElbow", ang(20 + 35 * math.max(0, c) * amount, 0, 0))
		setJoint(life, "LeftElbow", ang(20 + 35 * math.max(0, -c) * amount, 0, 0))
		setJoint(life, "Neck", ang(38, 6 * s * amount, 0))
		setJoint(life, "Waist", ang(4, 7 * s * amount, 0))
		clutch(life, 1)
		return
	end

	local fleeing = state == "Fleeing"
	if limp then
		-- Hop on the good leg, swing the broken one along (it is loose), lean onto the good side,
		-- and keep a hand on the hurt leg.
		local bad = life.brokenLeg
		local good = -bad
		local goodHip = if good == 1 then "RightHip" else "LeftHip"
		local goodKnee = if good == 1 then "RightKnee" else "LeftKnee"
		setJoint(life, goodHip, ang(14 * s * amount, 0, 0))
		setJoint(life, goodKnee, ang(-(12 + 34 * math.max(0, -s)) * amount, 0, 0))
		local lean = 9 * good
		setJoint(life, "Waist", ang(-6 - 5 * math.max(0, s) * amount, 0, lean))
		setJoint(life, "Neck", ang(4, 0, -lean * 0.5))
		local badShoulder = if bad == 1 then "RightShoulder" else "LeftShoulder"
		local badElbow = if bad == 1 then "RightElbow" else "LeftElbow"
		local goodShoulder = if good == 1 then "RightShoulder" else "LeftShoulder"
		setJoint(life, badShoulder, ang(22, 0, if bad == 1 then -6 else 6)) -- hand on the hurt thigh
		setJoint(life, badElbow, ang(28, 0, 0))
		setJoint(life, goodShoulder, ang(10 + 10 * s * amount, 0, if good == 1 then 38 else -38)) -- out for balance
		clutch(life, 1)
		return
	end

	local swing = (if fleeing then 42 else 22) * amount
	local knee = if fleeing then 62 else 34
	setJoint(life, "RightHip", ang(swing * s, 0, 0))
	setJoint(life, "LeftHip", ang(-swing * s, 0, 0))
	setJoint(life, "RightKnee", ang(-(6 + knee * math.max(0, c)) * amount, 0, 0))
	setJoint(life, "LeftKnee", ang(-(6 + knee * math.max(0, -c)) * amount, 0, 0))
	local panicUntil = life.model:GetAttribute("PanicUntil")
	local panic = fleeing and type(panicUntil) == "number" and panicUntil > Workspace:GetServerTimeNow()
	if panic then
		-- A headless chicken (10 Nov 2026): both arms up over the head, flailing out of step.
		local f = (now + life.seed) * 11
		setJoint(life, "RightShoulder", ang(150 + 30 * sin(f), 0, 25 + 20 * cos(f * 1.3)))
		setJoint(life, "LeftShoulder", ang(150 + 30 * sin(f + 2.1), 0, -25 - 20 * cos(f * 1.1)))
		setJoint(life, "RightElbow", ang(30 + 25 * sin(f * 1.7), 0, 0))
		setJoint(life, "LeftElbow", ang(30 + 25 * cos(f * 1.5), 0, 0))
	else
		setJoint(life, "RightShoulder", ang(-swing * 0.9 * s, 0, 7))
		setJoint(life, "LeftShoulder", ang(swing * 0.9 * s, 0, -7))
		local elbow = if fleeing then 80 else 14
		setJoint(life, "RightElbow", ang(elbow + 8 * c * amount, 0, 0))
		setJoint(life, "LeftElbow", ang(elbow - 8 * c * amount, 0, 0))
	end
	local lean = if fleeing then -14 else -3
	setJoint(life, "Waist", ang(lean * amount, 5 * s * amount, 0))
	if fleeing then
		-- Glances back over its shoulder at whoever it runs from.
		local back = if sin((now + life.seed) * 1.4) > 0.55 then 55 else 0
		setJoint(life, "Neck", ang(-lean * 0.6, back, 0))
	else
		setJoint(life, "Neck", ang(-lean * 0.5, 0, 0))
	end
	clutch(life, 1)
end

-- On the move it turns its head to a bang too (as far as a head turns; the legs keep going).
local function updateGait(life: Life, state: string, now: number, dt: number)
	gaitPose(life, state, now, dt)
	local since = now - life.noiseAt
	local at = life.noisePos
	if since >= 0 and since < NOISE_LOOK and at and not life.loose.Neck then
		local offset = at - life.head.Position
		if offset.Magnitude > 0.5 then
			local dir = life.chest.CFrame:VectorToObjectSpace(offset.Unit)
			local yaw = math.clamp(deg(math.atan2(-dir.X, -dir.Z)), -75, 75)
			local pitch = math.clamp(deg(math.asin(math.clamp(dir.Y, -1, 1))), -MAX_PITCH_DOWN, MAX_PITCH_UP)
			-- (Eased in and out over the look, so it does not snap.)
			local k = math.clamp(math.min(since, NOISE_LOOK - since) / 0.25, 0, 1)
			setJoint(life, "Neck", ang(pitch * k, yaw * k, 0))
		end
	end
end

local function makeStars(life: Life): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "DizzyStars"
	gui.Adornee = life.head
	gui.Size = UDim2.new(3.4, 0, 1.7, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.1, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 140
	gui.ResetOnSpawn = false
	gui.Enabled = false
	for i = 1, 3 do
		local img = Instance.new("ImageLabel")
		img.Name = "Star" .. i
		img.BackgroundTransparency = 1
		img.Image = Assets.Star
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Size = UDim2.fromScale(0.28, 0.56)
		img.Parent = gui
		table.insert(life.starImages, img)
	end
	gui.Parent = life.head
	life.stars = gui
	return gui
end

local function updateStars(life: Life, now: number)
	local visible = now < life.starsUntil and life.model:GetAttribute("MachineHidden") ~= true -- (0.37.7: not over the pancake in the press)
	local gui = life.stars
	if not visible then
		if gui then
			gui.Enabled = false
		end
		return
	end
	gui = gui or makeStars(life)
	assert(gui)
	gui.Enabled = true
	-- Fade in over the first moment and out over the last 0.4 s.
	local fade = math.clamp((life.starsUntil - now) / 0.4, 0, 1)
	local spin = (now + life.seed) * 3.6
	for i, img in life.starImages do
		local a = spin + (i - 1) * TAU / 3
		local front = sin(a) -- +1 nearest the camera side of the orbit
		local scale = 0.78 + 0.22 * front
		img.Position = UDim2.fromScale(0.5 + 0.36 * cos(a), 0.55 + 0.2 * front)
		img.Size = UDim2.fromScale(0.28 * scale, 0.56 * scale)
		img.ZIndex = if front > 0 then 2 else 1
		img.Rotation = (now * 160 + i * 40) % 360
		img.ImageTransparency = 1 - fade
	end
end

local function pickLookTarget(life: Life): Vector3?
	local best: Vector3? = nil
	local bestDistance = LOOK_RANGE
	local from = life.head.Position
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local head = character and character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			local d = (head.Position - from).Magnitude
			if d < bestDistance then
				best, bestDistance = head.Position, d
			end
		end
	end
	return best
end

-- A timed mood the server set on a person (LaughUntil, AngryUntil): still on?
local function moodOn(model: Model, attribute: string): boolean
	local untilTime = model:GetAttribute(attribute)
	return type(untilTime) == "number" and untilTime > Workspace:GetServerTimeNow()
end

local function updateIdle(life: Life, now: number, dt: number)
	local t = now + life.seed
	-- Who to look at: the nearest person, re-picked a few times a second; else a slow glance around.
	if now >= life.lookPickAt then
		life.lookPickAt = now + 0.25
		life.lookTarget = pickLookTarget(life)
		-- A gun held out close by (round 3, M3): eyes on it; all but the brave put their hands up.
		local seen, _, _, raised = GunThreat.near(life.head.Position, GunThreat.SCARE_REACH)
		if seen then
			life.threat = seen
			life.threatRaised = raised
			life.threatAt = now
			-- (A gun that fires starts the fright over.)
			if raised or not life.threatSince then
				life.threatSince = now
			end
		elseif life.threat and now - life.threatAt <= THREAT_GRACE then
			-- (Out of the aim for a moment -- the holder's facing jitters at the edge: still there,
			-- no snapping, and getting used to it carries on.)
		else
			life.threat = nil
			life.threatRaised = false
			life.threatSince = nil
		end
	end
	local wantYaw, wantPitch = 22 * sin(t * 0.21), 4 * sin(t * 0.17)
	local target = life.lookTarget
	local chatting = life.model:GetAttribute("Chatting")
	local greeting = moodOn(life.model, "GreetUntil")
	-- A bang it heard a moment ago: it looks there, whatever else (even right behind it).
	local sinceNoise = now - life.noiseAt
	local hearing = sinceNoise >= 0 and sinceNoise < NOISE_LOOK and life.noisePos ~= nil
	-- An idle gesture now and then (not while talking, greeting or looking at a bang).
	local busy = type(chatting) == "number" or greeting or hearing or life.threat ~= nil or moodOn(life.model, "LaughUntil")
		or moodOn(life.model, "AngryUntil") or life.model:GetAttribute("Dozing") == true
	if life.gesture and (busy or now >= life.gestureAt + life.gestureLength) then
		life.gesture = nil
		life.nextGestureAt = now + rng:NextNumber(GESTURE_GAP_MIN, GESTURE_GAP_MAX)
	elseif not life.gesture and not busy and now >= life.nextGestureAt then
		life.gesture = GESTURES[rng:NextInteger(1, #GESTURES)]
		life.gestureAt = now
		life.gestureLength = rng:NextNumber(2.2, 3.4)
	end
	-- How far into its gesture (eased in and out, 0..1..0).
	local g = 0
	if life.gesture then
		local u = math.clamp((now - life.gestureAt) / life.gestureLength, 0, 1)
		g = math.clamp(math.min(u, 1 - u) * 4, 0, 1)
		g = g * g * (3 - 2 * g)
		if life.gesture == "LookAround" then
			wantYaw = 65 * sin(u * TAU)
			wantPitch = 3
			target = nil
		elseif life.gesture == "Watch" then
			target = nil
		end
	end
	if type(chatting) == "number" or greeting then
		-- Talking to someone (or saying hi): look at them (they stand where this one faces), not at
		-- passers-by.
		local partner = life.model:GetAttribute("HomeLook")
		if typeof(partner) == "Vector3" then
			target = Vector3.new(partner.X, life.head.Position.Y, partner.Z)
		end
	end
	local wide = false
	local threat = life.threat
	-- Hands up: all but the brave, while the gun is new to it or has just fired; one saying hi
	-- keeps waving unless the gun just fired (M3 fix 1).
	local handsUp = threat ~= nil and life.model:GetAttribute("Personality") ~= "Brave"
		and (life.threatRaised or now - (life.threatSince or now) < GunThreat.CALM_AFTER)
		and not (greeting and not life.threatRaised)
	if threat then
		target = threat
		wide = true
	end
	if hearing then
		target = life.noisePos
		wide = true
	end
	if target then
		local offset = target - life.head.Position
		if offset.Magnitude > 0.5 then
			local dir = life.chest.CFrame:VectorToObjectSpace(offset.Unit)
			local yaw = deg(math.atan2(-dir.X, -dir.Z))
			if wide then
				-- A bang: it turns as far as it can, the chest taking half of it.
				wantYaw = math.clamp(yaw, -150, 150)
				wantPitch = math.clamp(deg(math.asin(math.clamp(dir.Y, -1, 1))), -MAX_PITCH_DOWN, MAX_PITCH_UP)
			elseif math.abs(yaw) <= 115 then -- not behind: turn to look; behind: keep glancing around
				wantYaw = math.clamp(yaw, -MAX_YAW, MAX_YAW)
				wantPitch = math.clamp(deg(math.asin(math.clamp(dir.Y, -1, 1))), -MAX_PITCH_DOWN, MAX_PITCH_UP)
			end
		end
	end
	local k = 1 - math.exp(-(if hearing then LOOK_SMOOTH * 2.2 else LOOK_SMOOTH) * dt)
	life.yaw += (wantYaw - life.yaw) * k
	life.pitch += (wantPitch - life.pitch) * k

	local breathe = sin(t * TAU * 0.27)
	local j = life.joints
	life.idle = true
	-- The chest takes a quarter of the turn so it reads as the whole body paying attention (half of
	-- a big one); the head the rest, never more than it can.
	local waistYaw = life.yaw * (if math.abs(life.yaw) > MAX_YAW then 0.5 else 0.25)
	local neckYaw = math.clamp(life.yaw - waistYaw, -75, 75)
	-- The start it gives at a bang: shoulders up, a jolt back.
	local jolt = if hearing and sinceNoise < NOISE_START then sin(sinceNoise / NOISE_START * math.pi) else 0
	if j.Waist then
		j.Waist.Transform = ang(1.3 * breathe - 5 * jolt, waistYaw + 2 * sin(t * 0.31), 0)
	end
	if j.Neck then
		j.Neck.Transform = ang(life.pitch - 1 * breathe + 4 * jolt, neckYaw, 0)
	end
	if j.RightShoulder then
		j.RightShoulder.Transform = ang(3 + 1.5 * breathe, 0, 5 + 1.2 * breathe)
	end
	if j.LeftShoulder then
		j.LeftShoulder.Transform = ang(3 + 1.5 * breathe, 0, -5 - 1.2 * breathe)
	end
	if j.RightElbow then
		j.RightElbow.Transform = ang(10 + 3 * sin(t * 0.6), 0, 0)
	end
	if type(chatting) == "number" and DummyLife.speaking(chatting) then
		-- Its turn: the hands go as it talks, the head nods along.
		local g = sin(t * 5.3)
		if j.RightShoulder and not life.loose.RightShoulder then
			j.RightShoulder.Transform = ang(35 + 18 * g, 0, 12 + 6 * sin(t * 3.1))
		end
		if j.RightElbow and not life.loose.RightElbow then
			j.RightElbow.Transform = ang(55 + 20 * sin(t * 4.1), 0, 0)
		end
		if j.LeftShoulder and not life.loose.LeftShoulder then
			j.LeftShoulder.Transform = ang(22 + 14 * sin(t * 4.4 + 1.7), 0, -10)
		end
		if j.Neck then
			j.Neck.Transform = j.Neck.Transform * ang(5 * sin(t * 6.2), 0, 0)
		end
	end
	if j.LeftElbow then
		j.LeftElbow.Transform = ang(10 + 3 * sin(t * 0.6 + 1.3), 0, 0)
	end
	-- Hands up at a gun: both arms raised, elbows bent, a nervous tremble.
	life.handsUp = handsUp
	-- (Eased up and down over about HANDS_EASE: never a snap.)
	life.handsW = math.clamp(life.handsW + (if handsUp then dt else -dt) / HANDS_EASE, 0, 1)
	if life.handsW > 0 then
		local w = life.handsW * life.handsW * (3 - 2 * life.handsW)
		local shake = 2 * sin(t * 17)
		for _, side in { "Right", "Left" } do
			local sign = if side == "Right" then 1 else -1
			local shoulder, elbow = j[side .. "Shoulder"], j[side .. "Elbow"]
			if shoulder and not life.loose[side .. "Shoulder"] then
				shoulder.Transform = shoulder.Transform:Lerp(ang(160 + shake, 0, 28 * sign), w)
			end
			if elbow and not life.loose[side .. "Elbow"] then
				elbow.Transform = elbow.Transform:Lerp(ang(55 + shake, 0, 0), w)
			end
		end
	end
	local model = life.model
	local free = function(name: string): boolean
		return j[name] ~= nil and not life.loose[name]
	end
	if jolt > 0 and not handsUp then -- (hands up stay up at a bang)
		if free("RightShoulder") then
			j.RightShoulder.Transform = ang(8 * jolt, 0, 5 + 14 * jolt)
		end
		if free("LeftShoulder") then
			j.LeftShoulder.Transform = ang(8 * jolt, 0, -5 - 14 * jolt)
		end
	end
	-- Saying hi: a big wave, the arm over its head.
	if greeting and not handsUp then
		if free("RightShoulder") then
			j.RightShoulder.Transform = ang(20, 0, 150 + 22 * sin(t * 9))
		end
		if free("RightElbow") then
			j.RightElbow.Transform = ang(25 + 20 * sin(t * 9 + 0.6), 0, 0)
		end
	end
	-- The idle gestures (blended in and out by g).
	local gesture = life.gesture
	local function blend(name: string, cf: CFrame)
		local joint = j[name]
		if joint and not life.loose[name] then
			joint.Transform = joint.Transform:Lerp(cf, g)
		end
	end
	if gesture == "Stretch" then
		blend("RightShoulder", ang(170, 0, 12))
		blend("LeftShoulder", ang(170, 0, -12))
		blend("RightElbow", ang(15, 0, 0))
		blend("LeftElbow", ang(15, 0, 0))
		blend("Waist", ang(-8, waistYaw, 0))
		blend("Neck", ang(14, neckYaw, 0))
	elseif gesture == "Scratch" then
		-- A hand behind the head, scratching; the head tilts.
		local s = 6 * sin(t * 16)
		blend("RightShoulder", ang(130, 0, 40 + s))
		blend("RightElbow", ang(120, 0, 0))
		blend("Neck", ang(-6, neckYaw * 0.5, 12))
	elseif gesture == "Watch" then
		-- The left wrist up in front, a look down at it.
		blend("LeftShoulder", ang(55, 0, -22))
		blend("LeftElbow", ang(100, 0, 0))
		blend("Neck", ang(-26, 18, 0))
	elseif gesture == "Arms" then
		-- Arms folded across the chest.
		blend("RightShoulder", ang(45, 0, -30))
		blend("LeftShoulder", ang(45, 0, 30))
		blend("RightElbow", ang(105, 0, 0))
		blend("LeftElbow", ang(105, 0, 0))
	elseif gesture == "Shrug" then
		local s = math.max(0, sin((now - life.gestureAt) * 5))
		blend("RightShoulder", ang(25, 0, 12 + 18 * s))
		blend("LeftShoulder", ang(25, 0, -12 - 18 * s))
		blend("RightElbow", ang(70, 0, 0))
		blend("LeftElbow", ang(70, 0, 0))
		blend("Neck", ang(4, neckYaw, 8 * s))
	end
	-- Personalities (CrowdService): a laugh, a shaken fist, a doze, a clown's little dance.
	if moodOn(model, "LaughUntil") then
		-- Bent over laughing, a hand on the belly, shaking.
		local shake = sin(t * 22)
		if j.Waist then
			j.Waist.Transform = ang(14 + 4 * shake, life.yaw * 0.25, 0)
		end
		if j.Neck then
			j.Neck.Transform = ang(-18 + 6 * shake, life.yaw * 0.5, 0)
		end
		if free("RightShoulder") then
			j.RightShoulder.Transform = ang(30, 0, 25)
		end
		if free("RightElbow") then
			j.RightElbow.Transform = ang(80, 0, 0)
		end
	elseif moodOn(model, "AngryUntil") then
		-- A fist up, shaking at whatever it was.
		if free("RightShoulder") then
			j.RightShoulder.Transform = ang(150 + 12 * sin(t * 14), 0, 10)
		end
		if free("RightElbow") then
			j.RightElbow.Transform = ang(40 + 10 * sin(t * 14), 0, 0)
		end
		if j.Neck then
			j.Neck.Transform = j.Neck.Transform * ang(6 * sin(t * 7), 0, 0)
		end
	elseif model:GetAttribute("Dozing") == true then
		-- Nodding off: the head drops and sways, the arms hang.
		if j.Neck then
			j.Neck.Transform = ang(-28 + 4 * sin(t * 0.9), 6 * sin(t * 0.4), 0)
		end
		if j.Waist then
			j.Waist.Transform = ang(4 + 2 * sin(t * 0.9), 0, 3 * sin(t * 0.45))
		end
	elseif model:GetAttribute("Personality") == "Clown" and type(chatting) ~= "number" then
		-- A clown never just stands there.
		local beat = sin(t * TAU * 1.1)
		if j.Waist then
			j.Waist.Transform = ang(0, 14 * beat, 6 * beat)
		end
		if free("RightShoulder") then
			j.RightShoulder.Transform = ang(120 + 30 * beat, 0, 30)
		end
		if free("LeftShoulder") then
			j.LeftShoulder.Transform = ang(120 - 30 * beat, 0, -30)
		end
	end
end

local function expressionFor(life: Life, now: number): string
	local model = life.model
	local state = life.state
	-- Dead (round 3, M2 fix 2): eyes shut, no stars (out cold has the stars).
	if model:GetAttribute("Vital") == "Dead" then
		return "Blink"
	end
	if model:GetAttribute("Frozen") == true or state == "Frozen" then
		return "Scared"
	end
	if state == "Out" then
		return "Dizzy" -- out cold
	elseif state == "Fleeing" then
		return "Scared"
	elseif state == "Crawling" then
		return "Ouch"
	elseif state == "Walking" then
		if life.brokenLeg ~= 0 then
			return "Ouch"
		end
		-- On its way to say hi or to chat: friendly; walking home after a knock: grumpy.
		return if moodOn(model, "GreetUntil") or type(model:GetAttribute("Chatting")) == "number" then "Neutral" else "Grumpy"
	end
	if state == "Ragdoll" then
		if model:GetAttribute("Held") == true or life.airborne then
			return "Scared"
		end
		if now < life.ouchUntil then
			return "Ouch"
		end
		return "Dizzy"
	elseif state == "Flinch" or state == "Stumble" or state == "Recovering" then
		return "Ouch"
	elseif state == "GettingUp" then
		return "Grumpy"
	end
	-- Standing
	local temper = model:GetAttribute("Mood")
	if temper == "Angry" or temper == "Box" then
		return "Grumpy"
	elseif temper == "Rage" then
		return "Grumpy"
	elseif temper == "Mourn" or temper == "Despair" or temper == "Sky" or temper == "CPRSlam" then
		return "Ouch"
	elseif temper == "Sit" or temper == "Cheer" or temper == "Relief" or temper == "Hug" then
		return "Neutral"
	elseif type(temper) == "string" then
		return "Scared"
	end
	if life.handsUp then
		return "Scared"
	elseif life.threat and model:GetAttribute("Personality") == "Brave" then
		return "Grumpy"
	end
	if moodOn(model, "AngryUntil") then
		return "Grumpy"
	elseif model:GetAttribute("Dozing") == true then
		return "Blink" -- eyes shut
	end
	if life.previous == "GettingUp" and now - life.stateSince < GRUMPY_AFTER_GETUP then
		return "Grumpy"
	end
	local broken = model:GetAttribute("Broken")
	if type(broken) == "number" and broken > 0 then
		return "Grumpy"
	end
	return "Neutral"
end

-- Whose turn it is in a chat: the two take turns (1 and 2) on the server's clock, so both screens
-- and both people agree.
function DummyLife.speaking(turn: number): boolean
	return math.floor(Workspace:GetServerTimeNow() / TALK_TURN) % 2 == turn - 1
end

-- The bubble over the head: "..." while talking (now and then a laugh), a red "!" in a panic.
local function updateBubble(life: Life, now: number, near: boolean)
	local model = life.model
	local kind: string? = nil
	if near then
		local chatting = model:GetAttribute("Chatting")
		local panicUntil = model:GetAttribute("PanicUntil")
		local upright = life.state == "Standing" or life.state == "Walking"
		-- A coward running from a gun (looked at once as it sets off, standing or walking).
		if life.state == "Fleeing" and life.gunFleeFor ~= life.stateSince then
			life.gunFleeFor = life.stateSince
			life.gunFlee = now - life.threatAt < 3 or GunThreat.cowardRunsFrom(life.head.Position) ~= nil
		end
		local fromGun = life.state == "Fleeing" and life.gunFlee
		if fromGun or type(panicUntil) == "number" and panicUntil > Workspace:GetServerTimeNow() and (life.state == "Fleeing" or upright) then
			-- A grumpy one shouts instead of shrieking.
			kind = if model:GetAttribute("Personality") == "Grumpy" then "Angry" else "Panic"
		elseif life.state == "Standing" and moodOn(model, "GreetUntil") and not life.handsUp then
			kind = "Hi"
		elseif upright and moodOn(model, "AngryUntil") then
			kind = "Angry"
		elseif upright and moodOn(model, "LaughUntil") then
			kind = "Laugh"
		elseif life.state == "Standing" and model:GetAttribute("Dozing") == true then
			kind = "Doze"
		elseif upright and model:GetAttribute("Chicken") == true and math.floor(now + life.seed) % 3 == 0 then
			kind = "Bawk" -- a chicken (the Chicken Spell) clucks now and then
		elseif type(chatting) == "number" and life.state == "Standing" and DummyLife.speaking(chatting) then
			-- Every third turn is a laugh.
			local turnIndex = math.floor(Workspace:GetServerTimeNow() / TALK_TURN)
			kind = if (turnIndex + math.floor(life.seed)) % 3 == 0 then "Laugh" else "Talk"
		end
	end
	local gui = life.bubble
	if not kind then
		if gui and gui.Enabled then
			gui.Enabled = false
		end
		life.bubbleKind = nil
		return
	end
	if not gui then
		local g = Instance.new("BillboardGui")
		g.Name = "Bubble"
		g.Adornee = life.head
		g.Size = UDim2.fromOffset(BUBBLE_SIZE.X, BUBBLE_SIZE.Y)
		g.StudsOffsetWorldSpace = Vector3.new(0, BUBBLE_OFFSET, 0)
		g.LightInfluence = 0
		g.MaxDistance = BUBBLE_DISTANCE
		g.ResetOnSpawn = false
		local back = Instance.new("Frame")
		back.Name = "Back"
		back.Size = UDim2.fromScale(1, 1)
		back.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		back.Parent = g
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.45, 0)
		corner.Parent = back
		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.Thickness = 1.5
		stroke.Color = Color3.fromRGB(40, 34, 70)
		stroke.Parent = back
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(40, 34, 70)
		text.Parent = back
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0.05, 0)
		pad.PaddingRight = UDim.new(0.05, 0)
		pad.PaddingTop = UDim.new(0.08, 0)
		pad.PaddingBottom = UDim.new(0.08, 0)
		pad.Parent = text
		g.Parent = life.head
		gui = g
		life.bubble = g
		life.bubbleText = text
	end
	assert(gui)
	-- Only redrawn when it changes (the dots step three times a second).
	local dots = if kind == "Talk" then 1 + math.floor(now * 3 + life.seed) % 3 else 0
	local key = kind .. dots
	if life.bubbleKind == key and gui.Enabled then
		return
	end
	gui.Enabled = true
	local text = life.bubbleText :: TextLabel
	local back = text.Parent :: Frame
	if kind == "Panic" then
		text.Text = "!"
		back.BackgroundColor3 = Color3.fromRGB(235, 60, 60)
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif kind == "Laugh" then
		text.Text = "HA!" -- (short words: big enough to read in a small bubble)
		back.BackgroundColor3 = Color3.fromRGB(255, 225, 90)
		text.TextColor3 = Color3.fromRGB(40, 34, 70)
	elseif kind == "Angry" then
		text.Text = "HEY"
		back.BackgroundColor3 = Color3.fromRGB(255, 130, 40)
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif kind == "Bawk" then
		text.Text = "BAWK"
		back.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		text.TextColor3 = Color3.fromRGB(230, 110, 30)
	elseif kind == "Hi" then
		text.Text = "HI!"
		back.BackgroundColor3 = Color3.fromRGB(130, 220, 120)
		text.TextColor3 = Color3.fromRGB(30, 50, 30)
	elseif kind == "Doze" then
		text.Text = "Zzz"
		back.BackgroundColor3 = Color3.fromRGB(170, 200, 255)
		text.TextColor3 = Color3.fromRGB(40, 34, 70)
	else
		-- Always three dots (one alone reads as an empty bubble), lit one after another.
		local lit = { "<font transparency=\"0\">.</font><font transparency=\"0.7\">..</font>", "<font transparency=\"0.7\">.</font><font transparency=\"0\">.</font><font transparency=\"0.7\">.</font>", "<font transparency=\"0.7\">..</font><font transparency=\"0\">.</font>" }
		text.RichText = true
		text.Text = lit[dots]
		back.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		text.TextColor3 = Color3.fromRGB(40, 34, 70)
	end
	if kind ~= "Talk" then
		text.RichText = false
	end
	-- Chatter and dozing are background: a little see-through, no outline. What matters (a panic, a
	-- hello, a shout) stays solid.
	local quietKind = kind == "Talk" or kind == "Doze" or kind == "Laugh"
	back.BackgroundTransparency = if quietKind then 0.3 else 0
	local stroke = back:FindFirstChild("Stroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Transparency = if quietKind then 1 else 0
	end
	life.bubbleKind = key
end

-- LOOK_V3 (19 Nov 2026, like the big ragdoll games): a short line in a small black box over the
-- head. Yellow when a gun points at it or it just got up from a fall, white for idle chatter (at
-- most DummyLines.IDLE_MAX idle lines on this screen at once). Lines: Shared\DummyLines.
local idleShown = 0

local function hideLine(life: Life)
	if life.lineKind == "Idle" then
		idleShown = math.max(0, idleShown - 1)
	end
	life.lineKind = nil
	if life.line then
		life.line.Enabled = false
	end
end

local function showLine(life: Life, kind: string, now: number, given: { string }?)
	if life.lineKind == "Idle" then
		idleShown = math.max(0, idleShown - 1)
	end
	local list = if given then given elseif kind == "Fear" then DummyLines.FEAR elseif kind == "Ouch" then DummyLines.OUCH else DummyLines.idleFor(life.model:GetAttribute("Zone")) -- (v4 B2: what they say fits the place)
	life.lineTurn += 1
	if not life.line then
		local g = Instance.new("BillboardGui")
		g.Name = "Line"
		g.Adornee = life.head
		g.Size = UDim2.fromOffset(300, 34)
		g.StudsOffsetWorldSpace = Vector3.new(0, BUBBLE_OFFSET, 0)
		g.LightInfluence = 0
		g.MaxDistance = DummyLines.DISTANCE
		g.AlwaysOnTop = false
		g.ResetOnSpawn = false
		local box = Instance.new("Frame")
		box.Name = "Box"
		box.AnchorPoint = Vector2.new(0.5, 1)
		box.Position = UDim2.fromScale(0.5, 1)
		box.Size = UDim2.fromOffset(0, 26)
		box.AutomaticSize = Enum.AutomaticSize.X
		box.BackgroundColor3 = DummyLines.BOX_COLOR
		box.BackgroundTransparency = DummyLines.BOX_ALPHA
		box.BorderSizePixel = 0
		box.Parent = g
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = box
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 9)
		pad.PaddingRight = UDim.new(0, 9)
		pad.Parent = box
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(0, 1)
		text.AutomaticSize = Enum.AutomaticSize.X
		text.Font = Enum.Font.BuilderSansBold
		text.TextSize = DummyLines.TEXT_SIZE
		text.Parent = box
		g.Parent = life.head
		life.line = g
		life.lineText = text
	end
	local text = life.lineText :: TextLabel
	local said = DummyLines.pick(list, life.seed, life.lineTurn)
	local lost = life.model:GetAttribute("MournedName")
	local friend = if type(lost) == "string" then lost else "buddy"
	local spoken = string.gsub(said, "%%s", function()
		return friend
	end)
	text.Text = spoken
	-- (0.36.7, owner: text again, like the big ragdoll games: short, small, one at a time. The faces of
	-- Config.ICON_SIGNS are gone from here.)
	text.TextColor3 = if kind == "Idle" then DummyLines.IDLE_COLOR else DummyLines.FEAR_COLOR
	;(life.line :: BillboardGui).Enabled = true
	life.lineKind = kind
	life.lineUntil = now + DummyLines.HOLD
	if kind == "Idle" then
		idleShown += 1
	end
end

local lastHitLine = -math.huge
local function updateLine(life: Life, now: number)
	-- (22 Nov 2026, owner: "no ragdoll talks when it is dead"): a dead body says nothing, and a line it had goes.
	if life.model:GetAttribute("Vital") == "Dead" then
		if life.lineKind then
			hideLine(life)
		end
		return
	end
	-- (V11 item 13: a mourner says what fits its Mood the moment it changes.)
	do
		local moodLife: any = life
		local mood = life.model:GetAttribute("Mood") or life.model:GetAttribute("MoodSay")
		local furious = mood == "Angry" or mood == "Box"
		local sinceSaid = now - (moodLife.moodAt or 0)
		if if furious then sinceSaid > 4.5 or (mood ~= moodLife.moodSaid and sinceSaid > 2.5) else mood ~= moodLife.moodSaid then
			moodLife.moodSaid = mood
			moodLife.moodAt = if furious then now else 0
			local lines = if type(mood) == "string" then (DummyLines :: any).MOURN[mood] else nil
			if lines then
				showLine(life, "Mood", now, lines)
				return
			end
		end
	end
	-- 0.36.7: a new wound = a line for where it landed (one hit line on this screen per HIT_GAP; a dead
	-- body says nothing).
	local raw = life.model:GetAttribute("Wounds")
	local rawText = if type(raw) == "string" then raw else ""
	if rawText ~= life.woundsRaw then
		local grew = #rawText > #life.woundsRaw
		life.woundsRaw = rawText
		if grew and now - lastHitLine >= DummyLines.HIT_GAP and life.model:GetAttribute("Vital") ~= "Dead" then
			local wounds = Anatomy.parseWounds(rawText)
			local newest = wounds[#wounds]
			if newest then
				lastHitLine = now
				local group = if newest.blunt and rng:NextNumber() < 0.5 then "Blunt" else DummyLines.hitGroup(newest.zone.id)
				showLine(life, "Hit", now, DummyLines.HIT[group] or DummyLines.OUCH)
				return
			end
		end
	end
	local raised = life.handsUp and not life.wasHandsUp
	life.wasHandsUp = life.handsUp
	-- (0.36.7: not every raised pair of hands talks: fewer words on the screen.)
	if raised and rng:NextNumber() < 0.4 and now - lastHitLine >= DummyLines.HIT_GAP then
		showLine(life, "Fear", now)
		return
	end
	if life.lineKind == "Fear" and life.handsUp then
		life.lineUntil = math.max(life.lineUntil, now + 0.6) -- (stays up while the gun points)
	end
	-- Just got up from a fall.
	if life.state == "Standing" and (life.previous == "GettingUp" or life.previous == "Recovering")
		and now - life.stateSince < DummyLines.OUCH_WINDOW and life.ouchFor ~= life.stateSince then
		life.ouchFor = life.stateSince
		if rng:NextNumber() < DummyLines.OUCH_CHANCE then
			showLine(life, "Ouch", now)
			return
		end
	end
	if life.lineKind and now >= life.lineUntil then
		hideLine(life)
	end
	if not life.lineKind and life.state == "Standing" and now >= life.idleAt then
		life.idleAt = now + rng:NextNumber(DummyLines.IDLE_GAP.X, DummyLines.IDLE_GAP.Y)
		-- (Audit area 1: no chatter in a newcomer's first 90 s; FirstVisit sets NewcomerUntil.)
		local quietUntil = (game:GetService("Players").LocalPlayer:GetAttribute("NewcomerUntil") :: number?) or 0
		if idleShown < DummyLines.IDLE_MAX and time() >= quietUntil then
			showLine(life, "Idle", now)
		end
	end
	-- A fallen or dead one stops talking idly.
	if life.lineKind == "Idle" and life.state ~= "Standing" and life.state ~= "Walking" then
		hideLine(life)
	end
end

-- (23 Nov 2026, owner: "one must see it give CPR, not just kneel, and see it punch".) A Mood (Server/Mourning) owns the
-- upper body: the arms, waist and neck are drawn on every screen, so the idle breathing must not run over them. The
-- legs are ActiveRagdoll's. Punch counts up on the server a moment before each hit lands: right and left in turn.
local PUNCH_TIME = 0.42 -- s
local function moodPose(life: Life, now: number, dt: number, moving: boolean): boolean
	local model = life.model
	local mood = model:GetAttribute("Mood")
	local pose = if type(mood) == "string" then Poses.MOODS[mood] else nil
	local own: any = life
	if not pose then
		own.moodAt2 = nil
		if own.satDown then
			own.satDown = nil
			for name, joint in life.joints do
				if string.find(name, "Hip", 1, true) or string.find(name, "Knee", 1, true) or string.find(name, "Ankle", 1, true) then
					joint.Transform = CFrame.identity
				end
			end
		end
		own.moodJoints = nil
		return false
	end
	if moving and mood ~= "Angry" and mood ~= "Box" then
		return false
	end
	local kept = own.moodJoints
	if not kept then
		kept = {}
		own.moodJoints = kept
		own.punchSeen = model:GetAttribute("Punch")
	end
	local want: any
	local quick = 14
	if mood == "Angry" or mood == "Box" then
		local n = model:GetAttribute("Punch")
		if n ~= own.punchSeen then
			own.punchSeen = n
			own.punchAt = now
		end
		local since = now - (own.punchAt or -10)
		if since < PUNCH_TIME then
			quick = 40
			want = Poses.punch(since / PUNCH_TIME, if type(n) == "number" and n % 2 == 0 then -1 else 1)
		else
			want = Poses.fists(now)
		end
	else
		want = pose(now)
	end
	-- (Sitting: the standing joints are welded on each screen by itself, so every screen bends the legs too.)
	local sits = mood == "Sit" and typeof(model:GetAttribute("Seat")) == "CFrame"
	if sits then
		quick = 5
		own.satDown = true
	end
	local k = 1 - math.exp(-quick * dt)
	for name, joint in life.joints do
		if sits or not string.find(name, "Hip", 1, true) and not string.find(name, "Knee", 1, true) and not string.find(name, "Ankle", 1, true) then
			local to = want[name] or CFrame.identity
			local from = kept[name] or joint.Transform
			local at = from:Lerp(to, k)
			kept[name] = at
			joint.Transform = at
		end
	end
	life.idle = true
	life.handsUp = false
	return true
end

local function step(life: Life, now: number, dt: number)
	local model = life.model
	local state = (model:GetAttribute("RagdollState") :: string?) or "Standing"
	if state ~= life.state then
		life.previous = life.state
		life.state = state
		life.stateSince = now
		if state ~= "Standing" then
			releaseIdle(life)
		end
		if not MOVING[state] then
			releaseGait(life)
		end
	end
	readBroken(life, now)

	-- Flying or dangling vs lying: checked here so every screen gets it, not just the simulator's.
	if state == "Ragdoll" or state == "Out" then
		local hit = Workspace:Raycast(life.pelvis.Position, Vector3.new(0, -AIR_CLEARANCE, 0), life.rayParams)
		local flying = hit == nil
		if life.airborne and not flying and model:GetAttribute("Held") ~= true then
			life.ouchUntil = now + LAND_OUCH
		end
		life.airborne = flying
	else
		life.airborne = false
	end

	local expression = expressionFor(life, now)

	-- Dizzy stars: after being dizzy a moment, and lingering through getting up. Out cold: at once.
	if state == "Out" then
		life.dizzySince = life.dizzySince or (now - STARS_DELAY)
	end
	if expression == "Dizzy" then
		life.dizzySince = life.dizzySince or now
		if now - (life.dizzySince :: number) >= STARS_DELAY then
			life.starsUntil = now + STARS_AFTER
		end
	else
		life.dizzySince = nil
	end
	updateStars(life, now)

	-- Blinking, only when the eyes are open and relaxed.
	if expression == "Neutral" or expression == "Grumpy" then
		if life.shown ~= "Neutral" and life.shown ~= "Grumpy" and life.shown ~= "Blink" then
			-- Eyes just opened from another expression: don't blink straight away.
			life.blinkAt = math.max(life.blinkAt, now + rng:NextNumber(0.8, 2))
		end
		if now >= life.blinkAt then
			life.blinkUntil = now + 0.11
			life.blinkAt = now + (if rng:NextNumber() < 0.15 then 0.28 else rng:NextNumber(2.2, 5.5))
		end
		if now < life.blinkUntil then
			expression = "Blink"
		end
	end
	setFace(life, expression)

	if state == "Standing" and model:GetAttribute("Frozen") ~= true then
		if not moodPose(life, now, dt, false) then
			updateIdle(life, now, dt)
			clutch(life, 1)
		end
	elseif MOVING[state] then
		updateGait(life, state, now, dt)
		if state == "Walking" then
			moodPose(life, now, dt, true)
		end
	end
	freeLoose(life)
	if not MOVING[state] then
		life.lastPosition = life.pelvis.Position
		life.groundSpeed = 0
	end
	-- (10 Nov 2026, the owner: no text bubbles; the faces and the bodies show what they feel.)
	if Config.LOOK_V3 then
		updateLine(life, now)
	else
		updateBubble(life, now, BUBBLES)
	end
end

-- Something went bang (FxController plays every moment through here too): every dummy and person in
-- earshot turns to look, the nearest first.
function DummyLife.heard(kind: string, position: Vector3, speed: number, fx: string?, gun: boolean?)
	local reach = 0
	if kind == "Hit" then
		if gun then
			reach = SHOT_HEARD
		elseif fx and HEARD[fx] then
			reach = HEARD[fx]
		elseif speed >= 60 then
			reach = 30
		elseif speed >= 6 then
			reach = 14
		end
	elseif kind == "Break" or (kind == "Land" and speed >= 40) or kind == "Shatter" then
		reach = 16
	elseif kind == "Shot" then
		reach = SHOT_HEARD -- (a shot that hit nothing still makes its bang)
	end
	if reach <= 0 then
		return
	end
	-- (Even a slap is heard along a whole lab's row: everyone there looks.)
	if kind == "Hit" then
		reach = math.max(reach, ROW_HEARD)
	end
	local now = os.clock()
	local count = 0
	for _, life in lives do
		local distance = (life.head.Position - position).Magnitude
		if distance <= reach and distance > 3 then
			-- (One it is already looking at stays; a new bang takes over.)
			life.noiseAt = now + distance / SOUND_SPEED + rng:NextNumber(0.02, 0.12)
			life.noisePos = position
			count += 1
		end
	end
	-- (This screen's own note, for checking by hand: how many heard the last bang.)
	Workspace:SetAttribute("HeardBy", count)
end

-- Tests and LayoutCheck: how many are looking at a bang right now.
function DummyLife.lookingAtNoise(): number
	local now = os.clock()
	local n = 0
	for _, life in lives do
		if now - life.noiseAt >= 0 and now - life.noiseAt < NOISE_LOOK then
			n += 1
		end
	end
	return n
end

local function track(model: Instance)
	if not model:IsA("Model") or lives[model] or pendingModels[model] then
		return
	end
	pendingModels[model] = true
end

local function onRender(dt: number)
	local now = os.clock()
	for model in pendingModels do
		if not model.Parent then
			pendingModels[model] = nil
		else
			local life = build(model)
			if life then
				pendingModels[model] = nil
				lives[model] = life
			end
		end
	end
	local camera = Workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	for model, life in lives do
		if not model.Parent or not life.head.Parent then
			lives[model] = nil
			if life.stars then
				life.stars:Destroy()
			end
			if life.bubble then
				life.bubble:Destroy()
			end
			if life.lineKind == "Idle" then
				idleShown = math.max(0, idleShown - 1)
			end
			if life.line then
				life.line:Destroy()
			end
		else
			-- Up close every frame; further off a few times a second; far away and off screen not
			-- at all (its face and pose wait where they were).
			local distance = (life.pelvis.Position - eye).Magnitude
			if distance <= LOD_NEAR then
				life.lodWait = 0
				step(life, now, dt)
			else
				life.lodWait += dt
				local onScreen = true
				if camera and distance > LOD_FAR then
					local _, visible = camera:WorldToViewportPoint(life.pelvis.Position)
					onScreen = visible
				end
				if onScreen and life.lodWait >= LOD_MID_RATE then
					local waited = life.lodWait
					life.lodWait = 0
					step(life, now, waited)
				elseif not onScreen and life.bubble then
					updateBubble(life, now, false)
				elseif not onScreen and life.lineKind then
					hideLine(life)
				end
			end
		end
	end
end

function DummyLife.start()
	-- Load every face up front so a swap never shows a blank head.
	local list = {}
	for _, id in Faces :: any do
		table.insert(list, id)
	end
	table.insert(list, Assets.Star)
	task.spawn(function()
		ContentProvider:PreloadAsync(list)
	end)

	local folder = Workspace:WaitForChild("Dummies")
	folder.ChildAdded:Connect(track)
	folder.ChildRemoved:Connect(function(child)
		pendingModels[child :: any] = nil
	end)
	for _, child in folder:GetChildren() do
		track(child)
	end
	RunService:BindToRenderStep("RagdollLabDummyLife", Enum.RenderPriority.Character.Value + 1, onRender)
end

return DummyLife
