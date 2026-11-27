--!strict
-- RexAnim (FIXES_28NOV 16, Config.REX_ANIM): the T-rex is a real skinned dinosaur (V3Assets "TRex", Creator Store
-- 12948588771, no scripts) with its own clips saved inside it (AnimSaves: idle 27 s, walk 4 s, attacc 10 s).
-- KeyframeSequenceProvider can only play saved sequences in Studio, so this screen reads the clips once and writes
-- them onto the mesh's bones itself (as ClipGait does for the ragdolls):
--   * idle loops all the time (breathing, the head looking about);
--   * walk loops while the rex moves (the rampage);
--   * attacc (the roar) plays every 20-40 s, then back to idle.
-- Only within 150 studs, at 30 Hz; nothing runs when no rex is near.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local RexAnim = {}
RexAnim.REACH = 150

type Track = { times: { number }, frames: { CFrame } }
type Clip = { length: number, loop: boolean, tracks: { [string]: Track } }
type Rex = { model: Model, bones: { [string]: Bone }, clips: { [string]: Clip }, t: number, playing: string, nextRoar: number, lastPos: Vector3 }

local rexes: { [Model]: Rex } = {}

local function read(ks: KeyframeSequence): Clip
	local tracks: { [string]: Track } = {}
	local length = 0
	local keys = {}
	for _, k in ks:GetChildren() do
		if k:IsA("Keyframe") then
			table.insert(keys, k)
		end
	end
	table.sort(keys, function(a, b)
		return a.Time < b.Time
	end)
	for _, k in keys do
		length = math.max(length, k.Time)
		for _, p in k:GetDescendants() do
			if p:IsA("Pose") then
				local tr = tracks[p.Name]
				if not tr then
					tr = { times = {}, frames = {} }
					tracks[p.Name] = tr
				end
				table.insert(tr.times, k.Time)
				table.insert(tr.frames, p.CFrame)
			end
		end
	end
	return { length = math.max(length, 0.01), loop = ks.Loop, tracks = tracks }
end

local function sample(tr: Track, t: number): CFrame
	local n = #tr.times
	if n == 1 or t <= tr.times[1] then
		return tr.frames[1]
	end
	for i = 1, n - 1 do
		local a, b = tr.times[i], tr.times[i + 1]
		if t <= b then
			local k = if b > a then (t - a) / (b - a) else 0
			return tr.frames[i]:Lerp(tr.frames[i + 1], k)
		end
	end
	return tr.frames[n]
end

local function adopt(model: Model)
	if rexes[model] then
		return
	end
	local saves = model:FindFirstChild("AnimSaves", true)
	if not saves then
		return
	end
	local clips: { [string]: Clip } = {}
	for _, ks in saves:GetChildren() do
		if ks:IsA("KeyframeSequence") then
			clips[ks.Name] = read(ks)
		end
	end
	local bones: { [string]: Bone } = {}
	for _, b in model:GetDescendants() do
		if b:IsA("Bone") and not b:FindFirstAncestorOfClass("KeyframeSequence") then
			bones[b.Name] = b
		end
	end
	if not clips.idle then
		return
	end
	rexes[model] = { model = model, bones = bones, clips = clips, t = 0, playing = "idle", nextRoar = os.clock() + math.random(20, 40), lastPos = model:GetPivot().Position }
end

local acc = 0
local function step(dt: number)
	acc += dt
	if acc < 1 / 30 then
		return
	end
	local d = acc
	acc = 0
	local cam = Workspace.CurrentCamera
	local eye = if cam then cam.CFrame.Position else Vector3.zero
	local now = os.clock()
	for model, r in rexes do
		if not model.Parent then
			rexes[model] = nil
			continue
		end
		local at = model:GetPivot().Position
		if (at - eye).Magnitude > RexAnim.REACH then
			r.lastPos = at
			continue
		end
		local speed = (at - r.lastPos).Magnitude / d
		r.lastPos = at
		local want = r.playing
		if r.playing == "attacc" then
			if r.t >= r.clips.attacc.length then
				want = "idle"
				r.nextRoar = now + math.random(20, 40)
			end
		elseif speed > 2 and r.clips.walk then
			want = "walk"
		elseif r.clips.attacc and now >= r.nextRoar then
			want = "attacc"
		else
			want = "idle"
		end
		if want ~= r.playing then
			r.playing = want
			r.t = 0
		end
		local clip = r.clips[r.playing]
		r.t += d
		local t = if clip.loop then r.t % clip.length else math.min(r.t, clip.length)
		for name, tr in clip.tracks do
			local b = r.bones[name]
			if b then
				b.Transform = sample(tr, t)
			end
		end
	end
end

function RexAnim.start()
	if not Config.REX_ANIM then
		return
	end
	local function look(d: Instance)
		if d:IsA("Model") and d.Name == "TRex" then
			task.defer(adopt, d)
		end
	end
	for _, d in Workspace:GetDescendants() do
		look(d)
	end
	Workspace.DescendantAdded:Connect(look)
	RunService.Heartbeat:Connect(function(dt)
		if next(rexes) then
			step(dt)
		end
	end)
end

return RexAnim
