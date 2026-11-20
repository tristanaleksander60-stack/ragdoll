--!strict
-- v4 C3 (owner: "a realistic gorilla and bull"): every screen animates the event animals itself.
-- The server moves each animal's root and says what it is doing (attributes Kind, Gait, GaitAt on a
-- model tagged "AnimatedCreature"); this turns the joints with our own keyframe-free motion, so no
-- animation upload is needed and nothing crosses the network per frame:
--   Gorilla (R15 Motor6D joints): Roar (stands tall, arms out, head back), Walk (heavy knuckle walk,
--     leaning forward, shoulders rolling), Chest (beats its chest, left-right), Swat (a big right-arm
--     sweep).
--   Bull (skinned mesh bones): Run (a gallop: legs in pairs, head down for the charge, the body
--     pitching, the tail flicking).
-- Sounds here too: the roar (a deep creature roar, pitched down), chest thumps, hooves at a gallop
-- and snorts. Animals further than REACH from the camera are left still (cheap on phones).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Client = script.Parent
local SoundMix = require(Client:WaitForChild("SoundMix"))
local feel: any = nil -- (FeelV2, looked up once at start: its sound banks play the chest thumps)

local CreatureAnim = {}

CreatureAnim.REACH = 220 -- studs
CreatureAnim.SOUNDS = table.freeze({
	roar = 9113987603, -- Pro Sound Effects "Creature Vocal Giant Crab Monster Roars" (pitched down)
	snort = 9113636194, -- Pro Sound Effects "Bull Grunts Snorts Constant 3"
	hooves = 74590166641102, -- "LX Horse Hooves Hard Gallop" (lxstrzg)
	thump = 0, -- (chest thumps use the game's own slam bank through FeelV2.play)
})

type Joint = { motor: Motor6D? , bone: Bone? }
type Anim = {
	jointCount: number,
	jointTries: number,
	roarUntil: number,
	jointsAt: number,
	model: Model,
	kind: string,
	joints: { [string]: Joint },
	gait: string,
	gaitAt: number,
	loop: Sound?,
	lastBeat: number,
}

local anims: { [Model]: Anim } = {}

local function sound(id: number, parent: Instance, volume: number, pitch: number, looped: boolean): Sound
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.Looped = looped
	s.RollOffMinDistance = 15
	s.RollOffMaxDistance = 260
	s.SoundGroup = SoundMix.group("World")
	s.Parent = parent
	return s
end

local function oneShot(id: number, parent: Instance, volume: number, pitch: number)
	if id == 0 then
		return
	end
	local s = sound(id, parent, volume, pitch, false)
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(10, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

-- The joints by the part (Motor6D) or bone they move. (A big model streams in over a moment, so this
-- runs again until the joints are there: see `jointsAt`.)
local function findJoints(model: Model): ({ [string]: Joint }, number)
	local joints: { [string]: Joint } = {}
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Part1 then
			joints[d.Part1.Name] = { motor = d }
			n += 1
		elseif d:IsA("Bone") then
			joints[d.Name] = { bone = d }
			n += 1
		end
	end
	return joints, n
end

local function build(model: Model): Anim?
	local kind = model:GetAttribute("Kind")
	if type(kind) ~= "string" then
		return nil
	end
	local joints, count = findJoints(model)
	local a: Anim = { model = model, kind = kind, joints = joints, jointCount = count, jointTries = 0, roarUntil = 0, jointsAt = os.clock(), gait = "", gaitAt = 0, loop = nil, lastBeat = 0 }
	local root = model.PrimaryPart
	if kind == "Bull" and root then
		local loop = sound(CreatureAnim.SOUNDS.hooves, root, 0.55, 0.85, true)
		loop:Play()
		a.loop = loop
		if math.random() < 0.6 then
			oneShot(CreatureAnim.SOUNDS.snort, root, 0.8, 0.9 + math.random() * 0.2)
		end
	end
	return a
end

local function set(a: Anim, name: string, cf: CFrame)
	local j = a.joints[name]
	if not j then
		return
	end
	if j.motor then
		j.motor.Transform = cf
	elseif j.bone then
		j.bone.Transform = cf
	end
end

local rad = math.rad
local sin = math.sin

local function gorilla(a: Anim, t: number, since: number)
	local g = a.gait
	if g == "Roar" then
		-- Rears up, arms wide, head back; eases in over half a second.
		local k = math.clamp(since / 0.5, 0, 1)
		local shake = sin(t * 30) * 0.03 * k
		set(a, "UpperTorso", CFrame.Angles(rad(-12) * k, 0, 0))
		set(a, "Head", CFrame.Angles(rad(-28) * k + shake, 0, 0))
		set(a, "LeftUpperArm", CFrame.Angles(rad(20) * k, 0, rad(-70) * k))
		set(a, "RightUpperArm", CFrame.Angles(rad(20) * k, 0, rad(70) * k))
		set(a, "LeftLowerArm", CFrame.Angles(rad(40) * k, 0, 0))
		set(a, "RightLowerArm", CFrame.Angles(rad(40) * k, 0, 0))
		set(a, "LeftUpperLeg", CFrame.identity)
		set(a, "RightUpperLeg", CFrame.identity)
	elseif g == "Chest" then
		-- Beats its chest: hands to the chest in turn, about 7 beats a second.
		local beat = sin(t * 22)
		set(a, "UpperTorso", CFrame.Angles(rad(-8), 0, 0))
		set(a, "Head", CFrame.Angles(rad(-15), 0, 0))
		set(a, "LeftUpperArm", CFrame.Angles(rad(70 + math.max(0, beat) * 25), 0, rad(-25)))
		set(a, "RightUpperArm", CFrame.Angles(rad(70 + math.max(0, -beat) * 25), 0, rad(25)))
		set(a, "LeftLowerArm", CFrame.Angles(rad(70), 0, 0))
		set(a, "RightLowerArm", CFrame.Angles(rad(70), 0, 0))
		set(a, "LeftUpperLeg", CFrame.identity)
		set(a, "RightUpperLeg", CFrame.identity)
	elseif g == "Swat" then
		-- A big sweep of the right arm, from high behind to low across.
		local k = math.clamp(since / 0.5, 0, 1)
		local swing = if k < 0.35 then -k / 0.35 else (k - 0.35) / 0.65
		set(a, "UpperTorso", CFrame.Angles(rad(10), rad(-25 * swing), 0))
		set(a, "RightUpperArm", CFrame.Angles(rad(-110 + 170 * math.max(0, swing)), 0, rad(30)))
		set(a, "RightLowerArm", CFrame.Angles(rad(20), 0, 0))
		set(a, "LeftUpperArm", CFrame.Angles(rad(15), 0, rad(-15)))
		set(a, "Head", CFrame.Angles(rad(5), 0, 0))
	else -- Walk: a heavy, rolling gait, leaning forward.
		local w = t * 7
		local s = sin(w)
		set(a, "LowerTorso", CFrame.new(0, math.abs(sin(w)) * 0.25, 0))
		set(a, "UpperTorso", CFrame.Angles(rad(18), rad(s * 8), rad(s * 4)))
		set(a, "Head", CFrame.Angles(rad(-14), rad(-s * 6), 0))
		set(a, "LeftUpperLeg", CFrame.Angles(rad(s * 32), 0, 0))
		set(a, "RightUpperLeg", CFrame.Angles(rad(-s * 32), 0, 0))
		set(a, "LeftLowerLeg", CFrame.Angles(rad(math.max(0, -s) * -30), 0, 0))
		set(a, "RightLowerLeg", CFrame.Angles(rad(math.max(0, s) * -30), 0, 0))
		set(a, "LeftUpperArm", CFrame.Angles(rad(30 - s * 38), 0, rad(-12)))
		set(a, "RightUpperArm", CFrame.Angles(rad(30 + s * 38), 0, rad(12)))
		set(a, "LeftLowerArm", CFrame.Angles(rad(25), 0, 0))
		set(a, "RightLowerArm", CFrame.Angles(rad(25), 0, 0))
	end
end

local function bull(a: Anim, t: number)
	-- A gallop: front legs together, back legs together, half a stride apart.
	local w = t * 11 + (a.gaitAt % 1) * 6
	local f, b = sin(w), sin(w + math.pi * 0.6)
	set(a, "hip", CFrame.Angles(rad(f * 4), 0, 0) * CFrame.new(0, math.abs(f) * 0.12, 0))
	set(a, "chest", CFrame.Angles(rad(-f * 5), 0, 0))
	set(a, "neck", CFrame.Angles(rad(14 + f * 4), 0, 0)) -- (head down: the charge)
	set(a, "head", CFrame.Angles(rad(8), 0, 0))
	set(a, "lShldr", CFrame.Angles(rad(f * 38), 0, 0))
	set(a, "rShldr", CFrame.Angles(rad(f * 30), 0, 0))
	set(a, "lForeArm", CFrame.Angles(rad(math.max(0, -f) * 50), 0, 0))
	set(a, "rForeArm", CFrame.Angles(rad(math.max(0, -f) * 45), 0, 0))
	set(a, "lThigh", CFrame.Angles(rad(-b * 34), 0, 0))
	set(a, "rThigh", CFrame.Angles(rad(-b * 28), 0, 0))
	set(a, "lShin", CFrame.Angles(rad(math.max(0, b) * -40), 0, 0))
	set(a, "rShin", CFrame.Angles(rad(math.max(0, b) * -35), 0, 0))
	set(a, "tail01", CFrame.Angles(rad(-20 + sin(t * 9) * 15), rad(sin(t * 6) * 20), 0))
	set(a, "tail04", CFrame.Angles(0, rad(sin(t * 6 + 1) * 25), 0))
end

function CreatureAnim.start()
	pcall(function()
		feel = require(Client:WaitForChild("FeelV2", 5)) :: any
	end)
	local function add(m: Instance)
		if m:IsA("Model") and not anims[m] then
			local a = build(m)
			if a then
				anims[m] = a
			end
		end
	end
	for _, m in CollectionService:GetTagged("AnimatedCreature") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("AnimatedCreature"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("AnimatedCreature"):Connect(function(m)
		local a = anims[m :: Model]
		if a and a.loop then
			a.loop:Destroy()
		end
		anims[m :: Model] = nil
	end)
	RunService.PreSimulation:Connect(function()
		local cam = Workspace.CurrentCamera
		local camPos = if cam then cam.CFrame.Position else Vector3.zero
		local now = Workspace:GetServerTimeNow()
		local t = os.clock()
		for m, a in anims do
			if not m.Parent then
				anims[m] = nil
				continue
			end
			local root = m.PrimaryPart
			if not root or (root.Position - camPos).Magnitude > CreatureAnim.REACH then
				continue
			end
			-- (Joints still streaming in: look again, once a second, until a full rig is there.)
			if a.jointCount < (if a.kind == "Bull" then 20 else 14) and a.jointTries < 10 and t - a.jointsAt > 1 then
				a.jointTries += 1
				a.joints, a.jointCount = findJoints(m)
				a.jointsAt = t
			end
			local gait = m:GetAttribute("Gait")
			local at = (m:GetAttribute("GaitAt") :: number?) or now
			if gait ~= a.gait then
				a.gait = tostring(gait)
				-- (A new move starts from rest: nothing of the last one stays on a joint it does not set.)
				for _, j in a.joints do
					if j.motor then
						j.motor.Transform = CFrame.identity
					elseif j.bone then
						j.bone.Transform = CFrame.identity
					end
				end
				a.gaitAt = at
				-- The sound that goes with the new move.
				if a.kind == "Gorilla" and gait == "Roar" and t >= a.roarUntil then
					a.roarUntil = t + 4
					oneShot(CreatureAnim.SOUNDS.roar, root, 1, 0.55)
				elseif a.kind == "Gorilla" and gait == "Swat" and t >= a.roarUntil and math.random() < 0.3 then
					a.roarUntil = t + 4
					oneShot(CreatureAnim.SOUNDS.roar, root, 0.6, 0.75)
				end
			end
			local since = now - a.gaitAt
			if a.kind == "Gorilla" then
				gorilla(a, t, since)
				if a.gait == "Chest" and t - a.lastBeat > 0.3 then
					a.lastBeat = t
					if feel and feel.play then
						feel.play("slam", root.Position + Vector3.new(0, 8, 0), 0.5, 0.6)
					end
				end
			elseif a.kind == "Bull" then
				bull(a, t)
			end
		end
	end)
end

return CreatureAnim
