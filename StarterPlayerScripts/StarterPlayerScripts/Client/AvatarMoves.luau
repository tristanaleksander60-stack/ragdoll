--!strict
-- Your avatar really does it: a punch throws the right arm, a kick the right leg, the bat and the
-- other smackers swing in a full arc, the Blaster comes up to aim and kicks back, a bomb is thrown.
-- Every move has anticipation, contact and recovery (vault: Hit Reactions and Hit-Stop); the
-- contact moment is when a hit lands (PokeController sends melee hits then), and it holds for the
-- hit-stop so a heavy hit feels heavy.
--
-- Procedural: each frame, after Roblox's Animator has posed the joints, the move's offsets are laid
-- on top of their Transform (no animation assets). Every client plays the moves of every avatar it
-- sees (yours when you use a tool, others' from the hit effects the server shares), so everyone sees
-- the same thing (others' moves join at the contact, since their hit has landed by then). Your avatar
-- turns to face what it hits and steps in to land a blow by hand. Which move a tool makes is on the
-- tool (Toys: move, byHand); the distances and hit-stop are in HitFeel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys"))
local HitFeel = require(Shared:WaitForChild("HitFeel"))
local Net = require(Shared:WaitForChild("Net"))

local AvatarMoves = {}

type Key = { t: number, x: number, y: number, z: number } -- radians at a point of the move (0-1)
type Track = { joint: string, keys: { Key } }
-- tool: for a move made with a held tool, where the tool points through the move, in the body's
-- frame (0 = as it is held at rest). The wrist turns against the arm so the tool follows these keys
-- instead of being carried round with the shoulder (a blaster stays level as the arm comes up to
-- aim; a bat lies flat as it reaches the target, not pointing at the sky). The golf club has none: it
-- is swung low by both arms and follows the arc as it is (measured: at the ball at the contact).
type Move = { duration: number, contact: number, tracks: { Track }, tool: { Key }? }

local function k(t: number, x: number, y: number?, z: number?): Key
	return { t = t, x = x, y = y or 0, z = z or 0 }
end

-- Angles: +x raises a limb forward (arm up in front, leg kicked forward); a knee bends with -x; y
-- then sweeps it round the body's upright (+y towards the left: a flat arc at the height x gave);
-- the waist turns with y.
local MOVES: { [string]: Move } = {
	Jab = { duration = 0.3, contact = 0.4, tracks = {
		{ joint = "RightShoulder", keys = { k(0, 0), k(0.25, -0.35), k(0.4, 1.6), k(0.6, 1.5), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.25, 0, -0.3), k(0.4, 0, 0.35), k(1, 0) } },
	} },
	Slap = { duration = 0.3, contact = 0.42, tracks = {
		-- Out to the right, then across.
		{ joint = "RightShoulder", keys = { k(0, 0), k(0.25, 1.1, -0.9), k(0.42, 1.3, 0.3), k(0.65, 1.1, 0.8), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.25, 0, -0.35), k(0.42, 0, 0.35), k(1, 0) } },
	} },
	Push = { duration = 0.34, contact = 0.45, tracks = {
		{ joint = "RightShoulder", keys = { k(0, 0), k(0.25, 0.6), k(0.45, 1.55), k(0.65, 1.5), k(1, 0) } },
		{ joint = "LeftShoulder", keys = { k(0, 0), k(0.25, 0.6), k(0.45, 1.55), k(0.65, 1.5), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.25, -0.15), k(0.45, 0.2), k(1, 0) } },
	} },
	Uppercut = { duration = 0.34, contact = 0.45, tracks = {
		{ joint = "RightShoulder", keys = { k(0, 0), k(0.25, -0.6), k(0.45, 2.5), k(0.65, 2.4), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.25, -0.2, -0.3), k(0.45, 0.25, 0.3), k(1, 0) } },
	} },
	Kick = { duration = 0.36, contact = 0.45, tracks = {
		{ joint = "RightHip", keys = { k(0, 0), k(0.25, -0.5), k(0.45, 1.5), k(0.65, 1.4), k(1, 0) } },
		{ joint = "RightKnee", keys = { k(0, 0), k(0.25, -1.3), k(0.45, -0.1), k(0.65, -0.2), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.45, -0.25), k(1, 0) } },
	} },
	Swing = {
		duration = 0.4,
		contact = 0.5,
		tracks = {
			-- Both hands up at chest height, cocked back to the right, then a flat arc through the
			-- target and on across the body.
			{ joint = "RightShoulder", keys = { k(0, 0), k(0.3, 1.4, -1.3), k(0.5, 1.45, 0.1), k(0.7, 1.3, 1.0), k(1, 0) } },
			{ joint = "LeftShoulder", keys = { k(0, 0), k(0.3, 1.0, -0.9), k(0.5, 1.2, 0.2), k(0.7, 1.1, 0.8), k(1, 0) } },
			{ joint = "Waist", keys = { k(0, 0), k(0.3, 0, -0.6), k(0.5, 0, 0.3), k(0.7, 0, 0.6), k(1, 0) } },
		},
		-- Cocked back over the shoulder, flat and straight at the target at the contact, across the
		-- body after.
		tool = { k(0, 0), k(0.3, 0.5, -0.9), k(0.5, -0.95, 0), k(0.7, -0.9, 1.2), k(1, 0) },
	},
	Chop = {
		duration = 0.42,
		contact = 0.5,
		tracks = {
			-- Overhead and down (the hammer).
			{ joint = "RightShoulder", keys = { k(0, 0), k(0.3, 2.9), k(0.5, 0.9), k(0.7, 0.8), k(1, 0) } },
			{ joint = "LeftShoulder", keys = { k(0, 0), k(0.3, 2.7), k(0.5, 0.9), k(1, 0) } },
			{ joint = "Waist", keys = { k(0, 0), k(0.3, -0.25), k(0.5, 0.3), k(1, 0) } },
		},
		-- Back over the head, then down onto the target.
		tool = { k(0, 0), k(0.3, 1.1), k(0.5, -1.5), k(0.7, -1.6), k(1, 0) },
	},
	Golf = { duration = 0.42, contact = 0.5, tracks = {
		-- Low: back to the right, through the ball, and up over the left shoulder.
		{ joint = "RightShoulder", keys = { k(0, 0), k(0.3, 0.6, -1.1), k(0.5, 0.6, 0), k(0.75, 1.6, 1.0), k(1, 0) } },
		{ joint = "LeftShoulder", keys = { k(0, 0), k(0.3, 0.6, -0.9), k(0.5, 0.6, 0.1), k(0.75, 1.3, 0.9), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.3, 0, -0.6), k(0.6, 0, 0.6), k(1, 0) } },
	} },
	Shoot = {
		duration = 0.26,
		contact = 0.25,
		tracks = {
			-- Up to aim, a small kick back on the shot.
			{ joint = "RightShoulder", keys = { k(0, 0), k(0.25, 1.57), k(0.4, 1.85), k(0.7, 1.57), k(1, 0) } },
		},
		-- Level at the target, the muzzle kicking up a little on the shot.
		tool = { k(0, 0), k(0.25, -0.35), k(0.4, -0.12), k(0.7, -0.35), k(1, 0) },
	},
	-- A two-handed gun at the shoulder (crossbow, nail gun, portal gun): both arms up, the left
	-- holding it steady, the shoulders square to the target, a kick back through the body.
	Aim = {
		duration = 0.3,
		contact = 0.3,
		tracks = {
			{ joint = "RightShoulder", keys = { k(0, 0), k(0.3, 1.5, 0.15), k(0.45, 1.75, 0.15), k(0.75, 1.5, 0.15), k(1, 0) } },
			{ joint = "LeftShoulder", keys = { k(0, 0), k(0.3, 1.45, -0.55), k(0.45, 1.6, -0.55), k(0.75, 1.45, -0.55), k(1, 0) } },
			{ joint = "Waist", keys = { k(0, 0), k(0.3, -0.05, 0.12), k(0.45, -0.12, 0.12), k(1, 0) } },
		},
		tool = { k(0, 0), k(0.3, -0.3), k(0.45, -0.05), k(0.75, -0.3), k(1, 0) },
	},
	-- A spell: the wand goes up high, then sweeps down to point at the target with a flick.
	Cast = {
		duration = 0.42,
		contact = 0.55,
		tracks = {
			{ joint = "RightShoulder", keys = { k(0, 0), k(0.35, 2.8, -0.3), k(0.55, 1.45), k(0.75, 1.55), k(1, 0) } },
			{ joint = "LeftShoulder", keys = { k(0, 0), k(0.35, 0.6, 0.4), k(0.55, 0.2), k(1, 0) } },
			{ joint = "Waist", keys = { k(0, 0), k(0.35, -0.2, -0.25), k(0.55, 0.15, 0.2), k(1, 0) } },
		},
		tool = { k(0, 0), k(0.35, 1.0), k(0.55, -0.4), k(0.75, -0.2), k(1, 0) },
	},
	Throw = { duration = 0.34, contact = 0.5, tracks = {
		{ joint = "RightShoulder", keys = { k(0, 0), k(0.3, 2.7), k(0.5, 1.2), k(0.7, 0.9), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.3, 0, -0.35), k(0.5, 0, 0.3), k(1, 0) } },
	} },
}

-- Phase H: the other hand (or the backhand) for the next blow of the same kind, so a flurry is
-- left-right-left, never the same blow twice in a row. Mirror images of the moves above.
local VARIANTS: { [string]: string } = { Jab = "JabL", Slap = "Backhand", Swing = "SwingBack", Kick = "KickL", Push = "Shoulder" }
MOVES.JabL = { duration = 0.3, contact = 0.4, tracks = {
	{ joint = "LeftShoulder", keys = { k(0, 0), k(0.25, -0.35), k(0.4, 1.6), k(0.6, 1.5), k(1, 0) } },
	{ joint = "Waist", keys = { k(0, 0), k(0.25, 0, 0.3), k(0.4, 0, -0.35), k(1, 0) } },
} }
MOVES.Backhand = { duration = 0.3, contact = 0.42, tracks = {
	-- Across the body to the left first, then back out.
	{ joint = "RightShoulder", keys = { k(0, 0), k(0.25, 1.1, 0.9), k(0.42, 1.3, -0.3), k(0.65, 1.1, -0.8), k(1, 0) } },
	{ joint = "Waist", keys = { k(0, 0), k(0.25, 0, 0.35), k(0.42, 0, -0.35), k(1, 0) } },
} }
MOVES.SwingBack = {
	duration = 0.4,
	contact = 0.5,
	tracks = {
		{ joint = "RightShoulder", keys = { k(0, 0), k(0.3, 1.3, 1.0), k(0.5, 1.45, -0.1), k(0.7, 1.4, -1.2), k(1, 0) } },
		{ joint = "LeftShoulder", keys = { k(0, 0), k(0.3, 1.1, 0.8), k(0.5, 1.2, -0.2), k(0.7, 1.0, -0.9), k(1, 0) } },
		{ joint = "Waist", keys = { k(0, 0), k(0.3, 0, 0.6), k(0.5, 0, -0.3), k(0.7, 0, -0.6), k(1, 0) } },
	},
	tool = { k(0, 0), k(0.3, 0.5, 0.9), k(0.5, -0.95, 0), k(0.7, -0.9, -1.2), k(1, 0) },
}
MOVES.KickL = { duration = 0.36, contact = 0.45, tracks = {
	{ joint = "LeftHip", keys = { k(0, 0), k(0.25, -0.5), k(0.45, 1.5), k(0.65, 1.4), k(1, 0) } },
	{ joint = "LeftKnee", keys = { k(0, 0), k(0.25, -1.3), k(0.45, -0.1), k(0.65, -0.2), k(1, 0) } },
	{ joint = "Waist", keys = { k(0, 0), k(0.45, 0.25), k(1, 0) } },
} }
MOVES.Shoulder = { duration = 0.34, contact = 0.45, tracks = {
	-- A shoulder barge: arms tucked, the waist turned into it.
	{ joint = "RightShoulder", keys = { k(0, 0), k(0.25, 0.3, 0.6), k(0.45, 0.6, 0.9), k(1, 0) } },
	{ joint = "LeftShoulder", keys = { k(0, 0), k(0.25, 0.4), k(0.45, 0.5), k(1, 0) } },
	{ joint = "Waist", keys = { k(0, 0), k(0.25, 0, 0.6), k(0.45, 0.15, -0.5), k(1, 0) } },
} }
local VARIANT_GAP = 1.5 -- s: the next blow of the same kind within this alternates
local lastBlow: { [Model]: { name: string, at: number, flip: boolean } } = setmetatable({}, { __mode = "k" }) :: any

type Playing = {
	move: Move,
	name: string,
	started: number,
	holdUntil: number?,
	held: number,
	joints: { [string]: AnimationConstraint | Motor6D },
	lunge: Vector3?, -- your own blow by hand: the step in, done during the wind-up
	lunged: number, -- how much of it is done (0-1)
	lungeFrom: number, -- where the step in started (a repeat starts part-way through the wind-up)
	aim: CFrame, -- a sweep of the arm (and the tool) towards a target the body is not facing
}
local playing: { [Model]: Playing } = {}
-- What we wrote on a joint last frame and the pose under it: a joint the Animator does not drive
-- keeps our value, so the offset is laid on the pose under it again, never on top of itself.
-- (Weak keys: a joint that goes with its avatar is forgotten.)
type Written = { value: CFrame, base: CFrame }
local written: { [Instance]: Written } = setmetatable({}, { __mode = "k" }) :: any
local jointCache: { [Model]: { [string]: AnimationConstraint | Motor6D } } = setmetatable({}, { __mode = "k" }) :: any

local function baseOf(joint: AnimationConstraint | Motor6D): CFrame
	local last = written[joint]
	if last and joint.Transform == last.value then
		return last.base -- nobody touched it since: still our offset on the old base
	end
	return joint.Transform
end

local function release(joint: AnimationConstraint | Motor6D)
	if written[joint] then
		if joint.Parent then
			joint.Transform = baseOf(joint)
		end
		written[joint] = nil
	end
end

-- The avatar's joints by name (looked up once per body; again if the body was rebuilt).
local function jointsOf(character: Model): { [string]: AnimationConstraint | Motor6D }
	local cached = jointCache[character]
	if cached then
		local name = next(cached)
		local first = name and cached[name]
		if first and first.Parent then
			return cached
		end
	end
	local found = {}
	for _, d in character:GetDescendants() do
		if (d:IsA("AnimationConstraint") or d:IsA("Motor6D")) and not found[d.Name] then
			found[d.Name] = d :: any
		end
	end
	jointCache[character] = found
	return found
end

local function sample(keys: { Key }, t: number): CFrame
	local a = keys[1]
	for i = 2, #keys do
		local b = keys[i]
		if t <= b.t then
			local u = if b.t > a.t then (t - a.t) / (b.t - a.t) else 1
			u = u * u * (3 - 2 * u) -- smooth in and out
			return CFrame.fromEulerAnglesYXZ(a.x + (b.x - a.x) * u, a.y + (b.y - a.y) * u, a.z + (b.z - a.z) * u)
		end
		a = b
	end
	return CFrame.fromEulerAnglesYXZ(a.x, a.y, a.z)
end

-- Whether an avatar stands on its own (not limp from the RAGDOLL button or a hit, not dead).
local function upright(character: Model): boolean
	if character:GetAttribute("BodyLoose") == true or character:GetAttribute("RagdollState") ~= nil then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end
AvatarMoves.upright = upright

local function stop(character: Model)
	local p = playing[character]
	if p then
		for _, track in p.move.tracks do
			local joint = p.joints[track.joint]
			if joint then
				release(joint)
			end
		end
		local wrist = p.joints.RightWrist
		if wrist then
			release(wrist)
		end
		playing[character] = nil
	end
end

local function moveOf(toyId: string): (string?, Move?)
	local toy = Toys.byId[toyId]
	local name = toy and toy.move
	return name, name and MOVES[name] or nil
end

-- How far your avatar steps in towards a target to land a blow from STRIKE_DISTANCE (never through
-- a wall or off a ledge it would not walk off).
local function lungeTowards(character: Model, root: BasePart, target: Vector3, targetModel: Instance?): Vector3?
	-- (V9-0c review: seated, the body is welded to its car: a step in would shove the car.)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.SeatPart then
		return nil
	end
	local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
	local length = math.min(flat.Magnitude - HitFeel.STRIKE_DISTANCE, HitFeel.LUNGE_MAX)
	if length < 0.5 then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	-- The dummy being hit is the target, not a wall; any other dummy in the way stops the step.
	local ignore: { Instance } = { character }
	if targetModel then
		table.insert(ignore, targetModel)
	end
	params.FilterDescendantsInstances = ignore
	local offset = flat.Unit * length
	local wall = Workspace:Raycast(root.Position, offset, params)
	if wall then
		length = math.max(0, (wall.Position - root.Position).Magnitude - 1.5)
		offset = flat.Unit * length
	end
	if length < 0.5 or not Workspace:Raycast(root.Position + offset, Vector3.new(0, -8, 0), params) then
		return nil
	end
	return offset
end

export type PlayOptions = {
	hitStop: number?, -- s the contact pose holds (already within the hit-stop budget)
	lunge: boolean?, -- a blow by hand: step in during the wind-up
	targetModel: Instance?, -- what is being hit (the step in may go up to it, not through others)
	fromContact: boolean?, -- the thing has already happened (a throw): join the move at its contact
}

-- The most the arm sweeps round to a target the body is not facing (a shot on the run); further
-- round than this, the body turns after all.
local AIM_MAX = 1.0
-- The guns: a burst is one steady pose (no wind-up again), and on the run the arm sweeps round.
local SHOTS: { [string]: boolean } = { Shoot = true, Aim = true }
local REPEAT_FROM = 0.5 -- a blow repeated before the last one ended starts half-way into its wind-up

-- Starts a tool's move on your own avatar, facing the target. Returns the seconds to the contact
-- moment (0: the tool makes no move, or the hit should land now).
function AvatarMoves.play(character: Model?, toyId: string, target: Vector3, options: PlayOptions?): number
	local name, move = moveOf(toyId)
	if not character or not name or not move then
		return 0
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or not upright(character) then
		return 0 -- limp, down or dead: no swing, and no turning a body lying on the floor
	end
	local opts = options or {}
	local now = os.clock()
	local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
	-- Face the target. A shot on the run leaves the walking direction alone and sweeps the arm round
	-- to it instead (unless it is too far round: then the body turns after all).
	local aim = CFrame.identity
	if flat.Magnitude > 0.5 then
		local ahead = root.CFrame:VectorToObjectSpace(flat.Unit)
		local yaw = math.atan2(-ahead.X, -ahead.Z) -- + is to the left
		if moving and SHOTS[name] and math.abs(yaw) <= AIM_MAX then
			aim = CFrame.Angles(0, yaw, 0)
		elseif humanoid == nil or humanoid.SeatPart == nil then -- (V9-0c: never turn a seated body: it turns its car)
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
		else
			aim = CFrame.Angles(0, math.clamp(yaw, -AIM_MAX, AIM_MAX), 0)
		end
	end
	-- A gun already carried in a stance: it comes up and kicks (no move of its own).
	if SHOTS[name] and AvatarMoves.kick(character, aim) then
		return 0
	end
	local before = playing[character]
	-- The same move again before the last one ended (rapid fire, a flurry of blows):
	local again = before ~= nil and before.name == name and now - before.started < move.duration
	-- (A blow with a mirror image starts that image instead, from half-way: left, right, left.)
	local mirrored = again and not SHOTS[name] and VARIANTS[name] ~= nil and not opts.fromContact
	if again and before and not mirrored then
		before.aim = aim
		before.holdUntil = nil
		before.held = opts.hitStop or 0
		if SHOTS[name] then
			-- a shot carries on from the contact: the aim stays up, a burst is one steady pose.
			before.started = now - move.duration * move.contact
			before.lunge = nil
			return 0
		end
		-- a blow winds up again from half-way (no snap to the contact, no blow from afar): a fresh
		-- step in, landing at its contact like any blow.
		before.started = now - move.duration * move.contact * REPEAT_FROM
		before.lunge = if opts.lunge then lungeTowards(character, root, target, opts.targetModel) else nil
		before.lunged = 0
		before.lungeFrom = REPEAT_FROM
		return move.duration * move.contact * (1 - REPEAT_FROM)
	end
	stop(character) -- a different move cut short: its joints go back to the pose under them first
	-- Alternate hands: the same kind of blow again soon is its mirror image (left, backhand).
	local last = lastBlow[character]
	local flip = last ~= nil and last.name == name and now - last.at < VARIANT_GAP and not last.flip
	lastBlow[character] = { name = name, at = now, flip = flip }
	local variant = VARIANTS[name]
	if flip and variant and MOVES[variant] and not opts.fromContact then
		move = MOVES[variant]
	end
	local from = if opts.fromContact then move.contact elseif mirrored then move.contact * REPEAT_FROM else 0
	playing[character] = {
		move = move,
		name = name,
		started = now - move.duration * from,
		holdUntil = nil,
		held = opts.hitStop or 0,
		joints = jointsOf(character),
		lunge = if opts.lunge and not opts.fromContact then lungeTowards(character, root, target, opts.targetModel) else nil,
		lunged = 0,
		lungeFrom = if mirrored then REPEAT_FROM else 0,
		aim = aim,
	}
	return if opts.fromContact then 0 else move.duration * (move.contact - from)
end

-- Someone else's move, seen here: it joins at the contact (their hit has already landed by the time
-- we hear of it), so the blow and the reaction are seen together, never the reaction first.
function AvatarMoves.playRemote(character: Model?, toyId: string)
	local name, move = moveOf(toyId)
	if not character or not name or not move or not upright(character) then
		return
	end
	if SHOTS[name] and AvatarMoves.kick(character, CFrame.identity) then
		return
	end
	stop(character)
	-- Their blows alternate hands here too (the same rule as for your own).
	local now = os.clock()
	local last = lastBlow[character]
	local flip = last ~= nil and last.name == name and now - last.at < VARIANT_GAP and not last.flip
	lastBlow[character] = { name = name, at = now, flip = flip }
	local variant = VARIANTS[name]
	if flip and variant and MOVES[variant] then
		move = MOVES[variant]
	end
	playing[character] = {
		move = move,
		name = name,
		started = os.clock() - move.duration * move.contact,
		holdUntil = nil,
		held = 0,
		joints = jointsOf(character),
		lunge = nil,
		lunged = 0,
		lungeFrom = 0,
		aim = CFrame.identity,
	}
end

-- Whether a hit at `position` was done by hand by that player's avatar (a tool done by hand, from
-- within reach, standing): then no floating stand-in of the tool is drawn as well. The same rule
-- PokeController uses; the hitter's own decision travels with the hit (FxController prefers it), this
-- is for hits that come without one.
function AvatarMoves.byHand(userId: number?, toyId: string, position: Vector3): boolean
	local toy = Toys.byId[toyId]
	if not toy or not toy.byHand then
		return false
	end
	local who = if userId and userId ~= 0 then Players:GetPlayerByUserId(userId) else Players.LocalPlayer
	local character = who and who.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root or not root:IsA("BasePart") or not upright(character) then
		return false
	end
	return (root.Position - position).Magnitude <= HitFeel.MELEE_REACH
end

-- Lays an offset on a joint's pose for this frame (on the stance's pose when the stance wrote it this
-- frame: a swing starts from the bat on the shoulder, never from the arm hanging).
local stanceFrameOf: (Instance) -> boolean = function(_)
	return false
end
local function write(joint: AnimationConstraint | Motor6D, offset: CFrame)
	local stanced = stanceFrameOf(joint)
	local entry = written[joint]
	local animBase = baseOf(joint)
	local base = if stanced then joint.Transform else animBase
	local value = base * offset
	joint.Transform = value
	if stanced and entry then
		animBase = entry.base -- (what the animator gave, under the stance)
	end
	if entry then
		entry.value = value
		entry.base = animBase
	else
		written[joint] = { value = value, base = animBase }
	end
end

-- Stances (round 3, M4): how a body carries what it holds (the tool's own stance, Toys), between
-- moves. With a pistol the arms stop swinging and the gun is held low and ready in both hands; on
-- the run it is tucked to the chest, muzzle up; a long gun is carried across the body; a bat, an axe
-- or a blade rests on the shoulder. A shot brings the gun up to aim at once and it stays there
-- STANCE_READY s (our own shot at once, everyone else's from GunFiredAt, the server's note), kicking
-- with each shot, the upper body turning to a target off to the side. The legs keep the walk; the
-- body leans into a run. Every screen draws every player's stance (the held tool, the speed and
-- GunFiredAt all replicate).
-- Smooth everywhere: joints ease between stances; under a move (a swing) the stance fades out fast
-- and the move is laid on the pose the stance left (never a jump to the arms hanging), then the
-- stance eases back in; out of reach it eases out (two distances: no flicker at the edge).
type Pose = { [string]: Vector3 } -- a joint and its angles (x, y, z) as the moves above
type StanceSet = { idle: Pose, run: Pose, ready: Pose?, tool: { idle: Vector3, run: Vector3, ready: Vector3? } }
local function v(x: number, y: number?, z: number?): Vector3
	return Vector3.new(x, y or 0, z or 0)
end
local STANCES: { [string]: StanceSet } = {
	-- One-handed gun: low ready, the left hand under the right on the grip; tucked to the chest on
	-- the run; up at aim in both hands after a shot.
	Pistol = {
		-- (Tuned live: the hands 0.37 studs apart, both on the grip, the muzzle forward and down.)
		idle = { RightShoulder = v(0.8, 0.9), RightElbow = v(0.5), LeftShoulder = v(0.8, -1.3), LeftElbow = v(0.4), Waist = v(0) },
		run = { RightShoulder = v(0.3, 0.2), RightElbow = v(1.75), Waist = v(0.12) },
		ready = { RightShoulder = v(1.45, 0.12), RightElbow = v(0.1), LeftShoulder = v(1.35, -0.6), LeftElbow = v(0.35), Waist = v(0.02) },
		tool = { idle = v(-0.75), run = v(0.9), ready = v(-0.35) },
	},
	-- A long gun: across the body, muzzle down and forward; across the chest, muzzle up, on the run;
	-- at the shoulder after a shot.
	Rifle = {
		-- (Tuned live: the left hand's centre 0.19 studs from the gun's nearest surface: on the fore-end.)
		idle = { RightShoulder = v(0.55, 0.15), RightElbow = v(0.9), LeftShoulder = v(0.75, -1.6), LeftElbow = v(0.3), Waist = v(0) },
		run = { RightShoulder = v(0.5, 0.3), RightElbow = v(1.3), LeftShoulder = v(1.0, -0.7), LeftElbow = v(1.2), Waist = v(0.12) },
		ready = { RightShoulder = v(1.5, 0.15), RightElbow = v(0), LeftShoulder = v(1.45, -0.55), LeftElbow = v(0), Waist = v(-0.05, 0.12) },
		tool = { idle = v(-0.6, 1.9), run = v(0.45, 0.6), ready = v(-0.3) },
	},
	-- A bat, a club, an axe or a blade: on the shoulder, pointing back and up.
	Melee = {
		idle = { RightShoulder = v(0.4), RightElbow = v(2.1) },
		run = { RightShoulder = v(0.35), RightElbow = v(1.9), Waist = v(0.1) },
		tool = { idle = v(2.0), run = v(2.0) },
	},
}
AvatarMoves.STANCES = STANCES
AvatarMoves.STANCE_READY = 2.5 -- s the gun stays up at aim after a shot
AvatarMoves.STANCE_REACH = 120 -- studs from the camera: stances further off are not drawn...
AvatarMoves.STANCE_LEAVE = 140 -- ...and one drawn lets go only past this (no flicker at the edge)
AvatarMoves.RUN_UP = 0.8 -- of the body's WalkSpeed: faster than this is a run...
AvatarMoves.RUN_DOWN = 0.6 -- ...and slower than this a walk again (no flicker between the two)
local STANCE_WEIGHT = 0.9 -- of the arm's own swing, how much the stance replaces (a little sway is kept)
local STANCE_EASE = 10 -- how fast a joint eases to a new stance (per second)
local STANCE_FADE = 14 -- how fast it fades under a move (per second: gone by the swing's contact, never a jump)
local STANCE_KICK_TIME = 0.16 -- s a shot's kick takes to come back
local AIM_TURN_MAX = AIM_MAX -- radians the upper body turns to a target off to the side (the same limit
-- as a shot on the run: past it the whole body turns, so the gun always points along its tracer)
local SNAP_TIME = 0.07 -- s the gun takes to come up for a first shot (4 frames, never one jump)

-- The stance class of what a character holds (its HeldTool: the tool's own stance), or nil.
function AvatarMoves.stanceClass(character: Model): string?
	local held = character:FindFirstChild("HeldTool")
	local id = held and held:GetAttribute("Tool")
	local toy = type(id) == "string" and Toys.byId[id] or nil
	return if toy then toy.stance else nil
end

type JointEase = { cf: CFrame, w: number }
type StanceState = {
	joints: { [string]: JointEase },
	tool: CFrame,
	toolW: number,
	readyUntil: number, -- os.clock: up at aim until then (our own shot, before the server's note comes)
	kickAt: number, -- os.clock of the last shot's kick
	aim: number, -- radians the upper body is turned to a target off to the side (eased)
	aimTarget: number,
	running: boolean,
	snapUntil: number, -- os.clock: till then the pose is taken fast (a first shot brings the gun up)
	pitch: number, -- radians the arms are raised (+) or lowered to where the gun points (eased)
}
local stances: { [Model]: StanceState } = setmetatable({}, { __mode = "k" }) :: any
local aimFor: (character: Model) -> Vector2? -- (below: where a body's gun points, or nil)
local trimAim: (character: Model, dt: number, settled: boolean) -> () -- (below: your gun's aim, corrected to where it really points)
-- Which joints the stance wrote this frame (moves are laid on top of them).
local stanceFrame: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local frameNo = 0

-- Which of a class's poses fits right now: "ready" (a shot a moment ago), "run" or "idle".
function AvatarMoves.stanceMode(character: Model, set: StanceSet, state: StanceState?): string
	local fired = character:GetAttribute("GunFiredAt")
	if set.ready and ((type(fired) == "number" and Workspace:GetServerTimeNow() - fired < AvatarMoves.STANCE_READY) or (state and os.clock() < state.readyUntil)) then
		return "ready"
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local walk = if humanoid then math.max(humanoid.WalkSpeed, 1) else 16
	local speed = if root and root:IsA("BasePart") then Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude else 0
	local running = if state and state.running then speed > walk * AvatarMoves.RUN_DOWN else speed > walk * AvatarMoves.RUN_UP
	if state then
		state.running = running
	end
	-- Round 5: a gun that follows the mouse is held up at aim (not on the run).
	if set.ready and not running and aimFor(character) then
		return "ready"
	end
	return if running then "run" else "idle"
end

local function stanceWrite(joint: AnimationConstraint | Motor6D, value: CFrame, base: CFrame)
	joint.Transform = value
	local entry = written[joint]
	if entry then
		entry.value = value
		entry.base = base
	else
		written[joint] = { value = value, base = base }
	end
	stanceFrame[joint] = frameNo
end

local function releaseStance(character: Model, state: StanceState)
	local joints = jointsOf(character)
	for name in state.joints do
		local joint = joints[name]
		if joint then
			release(joint)
		end
	end
	local wrist = joints.RightWrist
	if wrist then
		release(wrist)
	end
	stances[character] = nil
end

-- One body's stance this frame: eased towards `set`'s pose for `mode`; `fade` (under a move, out of
-- reach, put away): eased out fast, the joints let go once it has gone.
local function tendStance(character: Model, set: StanceSet?, mode: string, dt: number, fade: boolean)
	local state = stances[character]
	if (not set or fade) and not state then
		return
	end
	if not state then
		state = { joints = {}, tool = CFrame.identity, toolW = 0, readyUntil = 0, kickAt = -math.huge, aim = 0, aimTarget = 0, running = false, snapUntil = 0, pitch = 0 }
		stances[character] = state
	end
	local st = state :: StanceState
	local pose: Pose = if set then ((set :: any)[mode] or set.idle) else {}
	local snap = not fade and os.clock() < st.snapUntil
	-- (Taking the pose fast for a first shot: about 45% of the way each frame, there in 4 frames;
	-- the body's turn to the target too.)
	local alpha = if snap then math.max(0.45, 1 - math.exp(-STANCE_EASE * dt)) else 1 - math.exp(-(if fade then STANCE_FADE else STANCE_EASE) * dt)
	local joints = jointsOf(character)
	for name in pose do
		if not st.joints[name] then
			st.joints[name] = { cf = CFrame.identity, w = 0 }
		end
	end
	-- A shot: the arms (and the muzzle) kick up and come straight back.
	local now = os.clock()
	-- (a first shot's kick is booked for when the gun is up: nothing until then, not a held full kick)
	local kick = if now < st.kickAt then 0 else math.clamp(1 - (now - st.kickAt) / STANCE_KICK_TIME, 0, 1)
	kick *= kick
	-- Round 5: the gun follows the mouse: the arms lift (or drop) to it, the upper body turns to it.
	local follow = if mode == "ready" and not fade then aimFor(character) else nil
	if follow then
		st.aimTarget = math.clamp(follow.Y, -AIM_TURN_MAX, AIM_TURN_MAX)
	end
	st.pitch += ((if follow then follow.X else 0) - st.pitch) * alpha
	local lift = CFrame.Angles(st.pitch, 0, 0)
	-- The upper body turns to a target off to the side while the gun is up (eased both ways).
	st.aim += ((if mode == "ready" and not fade then st.aimTarget else 0) - st.aim) * alpha
	local finals: { [string]: CFrame } = {}
	local any = false
	for name, ease in st.joints do
		local angles = if fade then nil else pose[name]
		local target = if angles then CFrame.fromEulerAnglesYXZ(angles.X, angles.Y, angles.Z) else ease.cf
		ease.cf = ease.cf:Lerp(target, alpha)
		ease.w += ((if angles then STANCE_WEIGHT else 0) - ease.w) * alpha
		local joint = joints[name]
		if joint and joint.Parent then
			if ease.w < 0.01 and not angles then
				release(joint)
				st.joints[name] = nil
			else
				any = true
				local base = baseOf(joint)
				local value
				if name == "Waist" then
					-- (The waist keeps its own turn and gets the lean, the aim's turn and the kick on top.)
					local lean = CFrame.identity:Lerp(ease.cf, ease.w / STANCE_WEIGHT)
					value = base * CFrame.Angles(0, st.aim, 0) * lean * CFrame.Angles(-0.06 * kick, 0, 0)
				elseif name == "RightShoulder" or name == "LeftShoulder" then
					value = base:Lerp(lift * ease.cf * CFrame.Angles(0.25 * kick, 0, 0), ease.w)
				else
					value = base:Lerp(ease.cf, ease.w)
				end
				stanceWrite(joint, value, base)
				finals[name] = value
			end
		end
	end
	-- The held thing points where the stance says, whatever the arm does (the wrist undoes it).
	local toolAngles = if set and not fade then ((set.tool :: any)[mode] or set.tool.idle) else nil
	local wrist = joints.RightWrist
	if wrist and wrist.Parent then
		local wantW = if toolAngles and character:FindFirstChild("HeldTool") then 1 else 0
		st.toolW += (wantW - st.toolW) * alpha
		if toolAngles then
			st.tool = st.tool:Lerp(CFrame.fromEulerAnglesYXZ(toolAngles.X, toolAngles.Y, toolAngles.Z), alpha)
		end
		if st.toolW < 0.01 and wantW == 0 then
			release(wrist)
		else
			any = true
			local arm = (finals.RightShoulder or CFrame.identity) * (finals.RightElbow or CFrame.identity)
			local base = baseOf(wrist)
			stanceWrite(wrist, base:Lerp(arm:Inverse() * lift * st.tool * CFrame.Angles(0.22 * kick, 0, 0), st.toolW), base)
		end
	end
	if follow and character == Players.LocalPlayer.Character then
		-- (Settled at the aim, no kick: measure where the gun really points.)
		local settled = kick == 0 and math.abs(st.aim - st.aimTarget) < 0.05 and math.abs(st.pitch - follow.X) < 0.05
		trimAim(character, dt, settled)
	end
	if not any and (fade or not set) and not playing[character] then
		stances[character] = nil
	end
end

-- Round 5 (the owner): the gun follows the mouse. While you hold a gun, the point under the mouse
-- (on a touch screen or a pad: the middle of the screen, where the crosshair is) sets where it
-- points: the arms lift or drop to it and the upper body turns to it; further round than the waist
-- turns, a standing body turns to face it. Sent to the server about 10 times a second (Net Aim,
-- unreliable; AimService puts it on the character as Aim), so every screen draws it.
AvatarMoves.AIM_SEND = 0.1 -- s between two aim messages, at the least
AvatarMoves.AIM_RANGE = 400 -- studs: the mouse ray goes this far
AvatarMoves.AIM_PITCH = 1.3 -- radians up or down, at most
local AIM_TURN_RATE = 9 -- radians a second a standing body turns to a mouse behind it
local AIM_CHANGE = 0.03 -- radians: smaller changes are not sent
local myAim: Vector2? = nil
local turning = false
-- The pose's own error (a stance holds a gun a little low, a model's barrel a little off): learnt
-- while you aim and added to the aim, per gun, so the barrel ends on the point. What is sent is the
-- corrected aim, so every screen draws the same pose.
local aimPoint: Vector3? = nil
local trim = Vector2.zero
local trimTool: string? = nil
local TRIM_MAX = 0.9 -- radians
local TRIM_RATE = 4 -- per second
local aimRemote: UnreliableRemoteEvent? = nil
local sentAim: Vector2? = nil
local sentAt = 0
local clearsLeft = 0

local function gunHeld(character: Model): boolean
	local class = AvatarMoves.stanceClass(character)
	return class == "Pistol" or class == "Rifle"
end

aimFor = function(character: Model): Vector2?
	if character == Players.LocalPlayer.Character then
		return myAim
	end
	local a = character:GetAttribute("Aim")
	if typeof(a) == "Vector2" and gunHeld(character) then
		return a
	end
	return nil
end

local aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude

-- Where your own gun points this frame (pitch, yaw from the body's front), or nil (no gun in hand).
local function ownAim(character: Model, dt: number): Vector2?
	local root = character:FindFirstChild("HumanoidRootPart")
	local camera = Workspace.CurrentCamera
	if not root or not root:IsA("BasePart") or not camera or not gunHeld(character) or not upright(character) or Players.LocalPlayer:GetAttribute("PhotoPose") == true then -- (V9-0d: posing in the photo frame, the body faces the camera, not the mouse)
		turning = false
		return nil
	end
	local chest = character:FindFirstChild("UpperTorso")
	local origin = (if chest and chest:IsA("BasePart") then chest.Position else root.Position) + Vector3.new(0, 0.4, 0)
	local point: Vector3
	local test = if RunService:IsStudio() then Players.LocalPlayer:GetAttribute("AimTestPoint") else nil
	if typeof(test) == "Vector3" then
		point = test -- (Studio only: a self-check aims at a set point)
	else
		local input = UserInputService:GetLastInputType()
		local centre = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
			or input == Enum.UserInputType.Touch
			or input == Enum.UserInputType.Gamepad1
			or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
		local at = if centre then camera.ViewportSize / 2 else UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(at.X, at.Y)
		aimParams.FilterDescendantsInstances = { character }
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * AvatarMoves.AIM_RANGE, aimParams)
		point = if hit then hit.Position else ray.Origin + ray.Direction * AvatarMoves.AIM_RANGE
	end
	local d = point - origin
	if d.Magnitude < 1 then
		return myAim -- (the mouse on your own chest: keep the last aim)
	end
	local rel = root.CFrame:VectorToObjectSpace(d.Unit)
	local yaw = math.atan2(-rel.X, -rel.Z) -- + is to the left
	local pitch = math.asin(math.clamp(rel.Y, -1, 1))
	-- Further round than the waist turns: a standing body turns to face it (till it is nearly ahead).
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	-- (V9-0c, owner 21 Nov 2026: "the car just drives in a circle": a seated avatar is welded to its seat,
	-- so turning its root turned the whole car towards the mouse / screen centre, and the camera
	-- following the car kept it turning. Seated, the body never turns: the upper body aims alone.)
	local standing = humanoid ~= nil and humanoid.MoveDirection.Magnitude < 0.1 and playing[character] == nil and humanoid.SeatPart == nil
	if math.abs(yaw) > AIM_TURN_MAX then
		turning = true
	elseif math.abs(yaw) < 0.15 then
		turning = false
	end
	if turning and standing then
		local turn = math.clamp(yaw, -AIM_TURN_RATE * dt, AIM_TURN_RATE * dt)
		root.CFrame *= CFrame.Angles(0, turn, 0)
		yaw -= turn
	end
	aimPoint = point
	local held = character:FindFirstChild("HeldTool")
	local tool = held and held:GetAttribute("Tool")
	if tool ~= trimTool then
		trimTool = if type(tool) == "string" then tool else nil
		trim = Vector2.zero
	end
	return Vector2.new(math.clamp(pitch + trim.X, -AvatarMoves.AIM_PITCH, AvatarMoves.AIM_PITCH), yaw + trim.Y)
end

-- Where the barrel points against where it should (the body's frame), learnt into `trim`.
trimAim = function(character: Model, dt: number, settled: boolean)
	local point = aimPoint
	local held = character:FindFirstChild("HeldTool")
	local root = character:FindFirstChild("HumanoidRootPart")
	local grip = held and held:FindFirstChild("Grip", true)
	if not settled or not point or not root or not root:IsA("BasePart") or not grip or not grip:IsA("BasePart") then
		return
	end
	local tip = held and held:FindFirstChild("Tip", true)
	local from = if tip and tip:IsA("BasePart") then tip.Position else grip.Position
	local want = point - from
	if want.Magnitude < 2 then
		return
	end
	local function angles(v: Vector3): (number, number)
		local r = root.CFrame:VectorToObjectSpace(v.Unit)
		return math.asin(math.clamp(r.Y, -1, 1)), math.atan2(-r.X, -r.Z)
	end
	local gp, gy = angles(grip.CFrame.LookVector)
	local wp, wy = angles(want)
	-- (Only while the waist can still reach it: past its turn the error is not the pose's.)
	if math.abs(wy) > AIM_TURN_MAX - 0.1 then
		return
	end
	local dy = (wy - gy + math.pi) % (2 * math.pi) - math.pi
	local k = math.min(1, TRIM_RATE * dt)
	trim = Vector2.new(math.clamp(trim.X + (wp - gp) * k, -TRIM_MAX, TRIM_MAX), math.clamp(trim.Y + dy * k, -TRIM_MAX, TRIM_MAX))
end

-- Tests: the learnt correction now.
function AvatarMoves.aimTrim(): Vector2
	return trim
end

-- Tells the server where your gun points (only real changes, at most every AIM_SEND s; "none" a
-- couple of times when the gun goes away: the remote may drop one).
local function sendAim()
	local remote = aimRemote
	if not remote then
		return
	end
	local now = os.clock()
	if now - sentAt < AvatarMoves.AIM_SEND then
		return
	end
	local a = myAim
	if a then
		if not sentAim or (a - sentAim).Magnitude >= AIM_CHANGE then
			remote:FireServer(a.X, a.Y)
			sentAim = a
			sentAt = now
		end
		clearsLeft = 2
	elseif clearsLeft > 0 then
		remote:FireServer(nil, nil)
		sentAim = nil
		sentAt = now + 0.3
		clearsLeft -= 1
	end
end

-- Tests: where your own gun points now (pitch, yaw), or nil.
function AvatarMoves.ownAim(): Vector2?
	return myAim
end

-- Every player's stance this frame, before the moves (a move is laid on top of what it leaves).
local function stanceStep(dt: number)
	frameNo += 1
	local me = Players.LocalPlayer.Character
	-- (V9-0c: seated in a car the body stays seated: no aim pose leaning out of the car.)
	local meHumanoid = me and me:FindFirstChildOfClass("Humanoid")
	local seated = meHumanoid ~= nil and meHumanoid.SeatPart ~= nil
	myAim = if me and me.Parent and not seated then ownAim(me, dt) else nil
	sendAim()
	local camera = Workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and character.Parent then
			local state = stances[character]
			if not upright(character) then
				-- Limp or dead: the physics has the joints; let go at once.
				if state then
					releaseStance(character, state)
				end
				continue
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			local reach = if state then AvatarMoves.STANCE_LEAVE else AvatarMoves.STANCE_REACH
			local near = root ~= nil and root:IsA("BasePart") and (root.Position - eye).Magnitude < reach
			local class = AvatarMoves.stanceClass(character)
			local set = if class then STANCES[class] else nil
			local fade = playing[character] ~= nil or not near or set == nil
			if set or state then
				local mode = if set then AvatarMoves.stanceMode(character, set, state) else "idle"
				tendStance(character, set, mode, dt, fade)
			end
		end
	end
	for character in stances do
		if not character.Parent then
			stances[character] = nil
		end
	end
end

-- A shot fired by a body in a gun stance: no separate move (the arms would drop and rise again
-- between shots): the gun comes up to aim at once (or stays there), the body turns to the target,
-- and it kicks. False: no gun stance here.
function AvatarMoves.kick(character: Model, aim: CFrame): boolean
	local state = stances[character]
	local class = AvatarMoves.stanceClass(character)
	if not state or (class ~= "Pistol" and class ~= "Rifle") then
		return false
	end
	local now = os.clock()
	if now >= state.readyUntil then
		state.snapUntil = now + SNAP_TIME -- (the first shot: the gun comes up in 4 frames, never fired from the hip)
		state.kickAt = now + SNAP_TIME -- (and kicks once it is up, not on the way)
	else
		state.kickAt = now
	end
	state.readyUntil = now + AvatarMoves.STANCE_READY
	local _, yaw = aim:ToEulerAnglesYXZ()
	state.aimTarget = math.clamp(yaw, -AIM_TURN_MAX, AIM_TURN_MAX)
	return true
end

-- Tests: the stance a body is in now (its class and mode), or nil.
function AvatarMoves.stanceOf(character: Model): (string?, string?)
	local state = stances[character]
	if not state then
		return nil, nil
	end
	local class = AvatarMoves.stanceClass(character)
	return class, if class then AvatarMoves.stanceMode(character, STANCES[class], state) else nil
end

stanceFrameOf = function(joint: Instance): boolean
	return stanceFrame[joint] == frameNo
end

local function step(dt: number)
	stanceStep(dt) -- (first: the moves are laid on top of the stance)
	local now = os.clock()
	for character, p in playing do
		if not character.Parent or not upright(character) then
			-- Gone, gone limp or died mid-move: the joints are not ours any more.
			stop(character)
			continue
		end
		local move = p.move
		local contactAt = p.started + move.duration * move.contact
		-- Hit-stop: the contact pose holds, then the rest of the move plays on.
		if now >= contactAt and p.held > 0 and not p.holdUntil then
			p.holdUntil = now + p.held
		end
		local holdUntil = p.holdUntil
		local elapsed = now - p.started
		if holdUntil then
			elapsed = if now < holdUntil then move.duration * move.contact else elapsed - p.held
		end
		local t = elapsed / move.duration
		if t >= 1 then
			stop(character)
			continue
		end
		-- The step in: spread over the wind-up, eased, done by the contact.
		local lunge = p.lunge
		if lunge then
			local root = character:FindFirstChild("HumanoidRootPart")
			local u = math.clamp((t / move.contact - p.lungeFrom) / (1 - p.lungeFrom), 0, 1)
			local done = u * u * (3 - 2 * u)
			if root and root:IsA("BasePart") and done > p.lunged then
				root.CFrame += lunge * (done - p.lunged)
				p.lunged = done
			end
		end
		local shoulder: CFrame? = nil
		for _, track in move.tracks do
			local joint = p.joints[track.joint]
			if joint and joint.Parent then
				local offset = sample(track.keys, t)
				if track.joint == "RightShoulder" then
					offset = p.aim * offset -- swept round to a target off to the side
					shoulder = offset
				end
				write(joint, offset)
			end
		end
		-- A held tool: the wrist undoes the arm's turn and points the tool along the move's keys.
		local tool = move.tool
		local wrist = p.joints.RightWrist
		if tool and wrist and wrist.Parent and character:FindFirstChild("HeldTool") then
			write(wrist, (shoulder or CFrame.identity):Inverse() * p.aim * sample(tool, t))
		end
	end
end

function AvatarMoves.start()
	-- Studio only: a hook to tune a stance's angles live while looking at it (never in a live game).
	if RunService:IsStudio() then
		local tune = Instance.new("BindableEvent")
		tune.Name = "StanceTune"
		tune.Event:Connect(function(class: string, mode: string, joint: string, angles: Vector3)
			local set = STANCES[class]
			if set and joint == "tool" then
				(set.tool :: any)[mode] = angles
			elseif set and (set :: any)[mode] then
				(set :: any)[mode][joint] = angles
			end
		end)
		tune.Parent = script
	end
	-- After the Animator has written this frame's pose (PreAnimation), before physics and rendering.
	RunService.PreSimulation:Connect(step)
	task.spawn(function()
		aimRemote = Net.unreliable(Net.Names.Aim)
	end)
end

-- For checks: whether a move is playing on an avatar right now.
function AvatarMoves.isPlaying(character: Model): boolean
	return playing[character] ~= nil
end

return AvatarMoves
