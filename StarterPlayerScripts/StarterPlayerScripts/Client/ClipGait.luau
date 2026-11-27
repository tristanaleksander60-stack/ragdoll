--!strict
-- S1 SMOOTH MOTION (owner: "gør ragdolls smooth så de er mere realistiske og ikke så klodsede"; Config.SMOOTH_MOTION;
-- docs/RAGDOLL_FEEL.md "SMOOTH AND REAL"): real human motion instead of hand-made sine waves. Roblox's own R15 walk and
-- run clips (the ones every Roblox avatar uses) are read ONCE on this screen (KeyframeSequenceProvider) into per-joint
-- key lists, and DummyLife samples them every frame into the active ragdoll's AnimationConstraint Transforms (the same
-- convention as a Motor6D's Transform, so the clips fit the R15 rig). If the clips cannot be read, ready() stays false
-- and DummyLife keeps its old gait.
--   * blend(speed, phase): walk and run mixed by the real ground speed (run from 9 to 14 studs/s), one shared phase
--     advanced by ground speed / stride, so the feet stay planted at every speed (no sliding).

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local ClipGait = {}

local runPoseOn: boolean? = nil
local function runPose(): boolean
	if runPoseOn == nil then
		local ok, Config = pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
		end)
		runPoseOn = ok and Config.RUN_POSE == true
	end
	return runPoseOn == true
end

ClipGait.CLIPS = { walk = "rbxassetid://913402848", run = "rbxassetid://913376220" }
ClipGait.STRIDE = { walk = 4.7, run = 9.4 } -- studs a full cycle (two steps)
ClipGait.RUN_FROM, ClipGait.RUN_FULL = 9, 14

-- The rig's part (a Pose's name) -> the joint that moves it (DummyLife's joint names).
local JOINT_OF: { [string]: string } = {
	UpperTorso = "Waist", Head = "Neck",
	RightUpperArm = "RightShoulder", RightLowerArm = "RightElbow", RightHand = "RightWrist",
	LeftUpperArm = "LeftShoulder", LeftLowerArm = "LeftElbow", LeftHand = "LeftWrist",
	RightUpperLeg = "RightHip", RightLowerLeg = "RightKnee", RightFoot = "RightAnkle",
	LeftUpperLeg = "LeftHip", LeftLowerLeg = "LeftKnee", LeftFoot = "LeftAnkle",
}

type Track = { times: { number }, frames: { CFrame } }
type Clip = { length: number, tracks: { [string]: Track } }
local clips: { [string]: Clip } = {}
local loaded = false

local function read(id: string): Clip?
	local ok, ks = pcall(function()
		return KeyframeSequenceProvider:GetKeyframeSequenceAsync(id)
	end)
	if not ok or not ks then
		return nil
	end
	local kfs = (ks :: KeyframeSequence):GetKeyframes()
	table.sort(kfs, function(a, b)
		return (a :: Keyframe).Time < (b :: Keyframe).Time
	end)
	local tracks: { [string]: Track } = {}
	local length = 0
	for _, kf in kfs do
		local k = kf :: Keyframe
		length = math.max(length, k.Time)
		for _, p in k:GetDescendants() do
			local joint = p:IsA("Pose") and JOINT_OF[p.Name]
			if joint and (p :: Pose).Weight > 0 then
				local tr = tracks[joint]
				if not tr then
					tr = { times = {}, frames = {} }
					tracks[joint] = tr
				end
				table.insert(tr.times, k.Time)
				table.insert(tr.frames, (p :: Pose).CFrame)
			end
		end
	end
	if length <= 0 then
		return nil
	end
	return { length = length, tracks = tracks }
end

function ClipGait.load()
	task.spawn(function()
		for name, id in ClipGait.CLIPS do
			local c = read(id)
			if not c then
				return -- (no clips: the old gait stays)
			end
			clips[name] = c
		end
		loaded = true
	end)
end

function ClipGait.ready(): boolean
	return loaded
end

local function sample(tr: Track, t: number, length: number): CFrame
	local times, frames = tr.times, tr.frames
	local n = #times
	if n == 1 then
		return frames[1]
	end
	-- the keys around t (looping: after the last key comes the first again)
	local i = n
	for k = 1, n do
		if times[k] > t then
			i = k - 1
			break
		end
	end
	if i == 0 then
		local span = times[1] + (length - times[n])
		local a = if span > 0 then (t + (length - times[n])) / span else 0
		return frames[n]:Lerp(frames[1], math.clamp(a, 0, 1))
	end
	local j = if i == n then 1 else i + 1
	local t0, t1 = times[i], if i == n then times[1] + length else times[j]
	local a = if t1 > t0 then (t - t0) / (t1 - t0) else 0
	return frames[i]:Lerp(frames[j], math.clamp(a, 0, 1))
end

-- How far through the cycle a body moves this frame (one shared phase 0..1 for walk and run).
function ClipGait.advance(phase: number, speed: number, dt: number): number
	local w = math.clamp((speed - ClipGait.RUN_FROM) / (ClipGait.RUN_FULL - ClipGait.RUN_FROM), 0, 1)
	local stride = ClipGait.STRIDE.walk + (ClipGait.STRIDE.run - ClipGait.STRIDE.walk) * w
	return (phase + speed * dt / stride) % 1
end

-- The pose of every joint at this phase and speed (nil before the clips are read).
function ClipGait.blend(speed: number, phase: number): { [string]: CFrame }?
	local walk, run = clips.walk, clips.run
	if not (loaded and walk and run) then
		return nil
	end
	local w = math.clamp((speed - ClipGait.RUN_FROM) / (ClipGait.RUN_FULL - ClipGait.RUN_FROM), 0, 1)
	local out: { [string]: CFrame } = {}
	for joint in JOINT_OF do
		local jn = JOINT_OF[joint]
		local a = walk.tracks[jn]
		local b = run.tracks[jn]
		local ca = if a then sample(a, phase * walk.length, walk.length) else CFrame.identity
		local cb = if b then sample(b, phase * run.length, run.length) else CFrame.identity
		out[jn] = if w <= 0 then ca elseif w >= 1 then cb else ca:Lerp(cb, w)
	end
	-- (v6 FIT PASS D, Config.RUN_POSE: a jog that reads as running: the elbows bend towards 90 degrees, pumping with
	-- the clip's arm swing; grows with the run share w, so a walk is untouched and the switch is eased. No extra lean:
	-- measured, the run clip already leans the body forward, more than the 10 degrees asked)
	if w > 0 and runPose() then
		local bend = CFrame.Angles(math.rad(55) * w, 0, 0)
		out.RightElbow = out.RightElbow * bend
		out.LeftElbow = out.LeftElbow * bend
	end
	return out
end

return ClipGait
