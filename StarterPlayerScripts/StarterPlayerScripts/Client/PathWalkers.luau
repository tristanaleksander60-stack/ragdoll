--!strict
-- OVERVIEW 0.1568 PEOPLE ON EVERY PATH (owner; docs/LIFE_IDLE.md 4; Config.PATH_WALKERS): client-only walkers that look
-- like our ragdolls (the same mannequin skins and face, copied once from a dressed lab ragdoll) walk the walkways of the
-- map (Shared/OwnerMapPlan ROADS: the ring, the cross, the spine and the tower walks), so a path in view is never empty.
--   * per device: phone 14, tablet 20, PC 30 (the Device attribute the server sets);
--   * anchored, no collision, never queried; moved with one Workspace:BulkMoveTo a step; the legs and arms swing by a
--     simple walk cycle; near ones every frame, mid every 3rd, far every 6th (banded rates);
--   * never in your face: within 26 studs of the camera a walker fades out (the real ragdolls are the ones you meet),
--     beyond 30 it fades in again; it keeps walking either way, so nothing pops in view;
--   * a walker keeps to its lane (a little left of the middle, so two pass each other), and at a lane's end goes on along
--     a lane that starts there (or turns back).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local PathWalkers = {}

PathWalkers.COUNT = { phone = 14, tablet = 20, pc = 30 }
PathWalkers.SPEED = { 4.2, 5.6 } -- studs/s, per walker
PathWalkers.HIDE_NEAR, PathWalkers.SHOW_FAR = 26, 30
PathWalkers.NEAR, PathWalkers.MID = 80, 160 -- studs: every frame / every 3rd / every 6th

-- The R15 rest pose (studs from the LowerTorso's middle; our dummy, read in Studio 27 Nov 2026).
local REST: { [string]: Vector3 } = {
	LowerTorso = Vector3.new(0, 0, 0), UpperTorso = Vector3.new(0, 1, 0), Head = Vector3.new(0, 2.386, 0),
	LeftUpperArm = Vector3.new(-1.425, 1.169, 0), LeftLowerArm = Vector3.new(-1.425, 0.576, 0), LeftHand = Vector3.new(-1.425, -0.05, 0),
	RightUpperArm = Vector3.new(1.425, 1.169, 0), RightLowerArm = Vector3.new(1.425, 0.576, 0), RightHand = Vector3.new(1.425, -0.05, 0),
	LeftUpperLeg = Vector3.new(-0.475, -0.621, 0), LeftLowerLeg = Vector3.new(-0.475, -1.401, 0), LeftFoot = Vector3.new(-0.475, -2.05, 0),
	RightUpperLeg = Vector3.new(0.475, -0.621, 0), RightLowerLeg = Vector3.new(0.475, -1.401, 0), RightFoot = Vector3.new(0.475, -2.05, 0),
}
local HIP_Y, KNEE_Y, SHOULDER_Y, STAND = -0.2, -1.022, 1.563, 2.2 -- (STAND: the LowerTorso's height over the ground)

type Piece = { part: BasePart, name: string, skin: CFrame }
type Walker = {
	pieces: { Piece }, lane: number, t: number, dir: number, speed: number, phase: number, side: number,
	shown: boolean, fade: number, wait: number,
}

local lanes: { { a: Vector3, b: Vector3, len: number } } = {}
local walkers: { Walker } = {}
local template: { { name: string, src: BasePart, skin: CFrame } }? = nil
local folder: Folder? = nil

local function laneAt(origin: Vector3)
	local Plan = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
	for _, r in Plan.ROADS or {} do
		for i = 1, #r.points - 1 do
			local a, b = r.points[i], r.points[i + 1]
			local A = Vector3.new(origin.X + a.X, origin.Y, origin.Z + a.Y)
			local B = Vector3.new(origin.X + b.X, origin.Y, origin.Z + b.Y)
			if (B - A).Magnitude > 8 then
				table.insert(lanes, { a = A, b = B, len = (B - A).Magnitude })
			end
		end
	end
end

-- The look, copied once from a dressed lab ragdoll: its skins (where they sit on their physics parts) and its head with
-- the face.
local function readTemplate(): boolean
	local dummies = Workspace:FindFirstChild("Dummies")
	for _, m in if dummies then dummies:GetChildren() else {} do
		local skins = m:FindFirstChild("Skins")
		local head = m:FindFirstChild("Head")
		if skins and head and head:IsA("BasePart") then
			local list = {}
			for name in REST do
				local src = if name == "Head" then head else skins:FindFirstChild(name)
				local body = m:FindFirstChild(name)
				if src and src:IsA("BasePart") and body and body:IsA("BasePart") then
					table.insert(list, { name = name, src = src, skin = body.CFrame:ToObjectSpace(src.CFrame) })
				end
			end
			if #list >= 12 then
				template = list
				return true
			end
		end
	end
	return false
end

local function makeWalker(): Walker?
	local t = template
	local f = folder
	if not t or not f or #lanes == 0 then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "PathWalker"
	local pieces: { Piece } = {}
	for _, e in t do
		local p = e.src:Clone()
		for _, c in p:GetChildren() do
			if not (c:IsA("SurfaceGui") or c:IsA("Decal") or c:IsA("SpecialMesh")) then
				c:Destroy()
			end
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.Transparency = 0
		p.LocalTransparencyModifier = 0
		p.Size = e.src.Size
		p.Parent = model
		table.insert(pieces, { part = p, name = e.name, skin = e.skin })
	end
	model.Parent = f
	local lane = math.random(1, #lanes)
	return {
		pieces = pieces, lane = lane, t = math.random() * lanes[lane].len, dir = if math.random() < 0.5 then 1 else -1,
		speed = PathWalkers.SPEED[1] + math.random() * (PathWalkers.SPEED[2] - PathWalkers.SPEED[1]),
		phase = math.random() * math.pi * 2, side = (math.random() - 0.5) * 3, shown = true, fade = 0, wait = 0,
	}
end

-- At a lane's end: on along a lane that touches this end (not the same one), else turn back.
local function nextLane(w: Walker)
	local L = lanes[w.lane]
	local at = if w.dir > 0 then L.b else L.a
	local options = {}
	for i, o in lanes do
		if i ~= w.lane then
			if (o.a - at).Magnitude < 3 then
				table.insert(options, { i = i, dir = 1 })
			elseif (o.b - at).Magnitude < 3 then
				table.insert(options, { i = i, dir = -1 })
			end
		end
	end
	if #options > 0 and math.random() < 0.85 then
		local pick = options[math.random(1, #options)]
		w.lane, w.dir = pick.i, pick.dir
		w.t = if pick.dir > 0 then 0 else lanes[pick.i].len
	else
		w.dir = -w.dir
	end
end

local parts: { BasePart } = {}
local cfs: { CFrame } = {}
local frame = 0
local function step(dt: number)
	local cam = Workspace.CurrentCamera
	if not cam or #walkers == 0 then
		return
	end
	frame += 1
	local eye = cam.CFrame.Position
	table.clear(parts)
	table.clear(cfs)
	for i, w in walkers do
		local L = lanes[w.lane]
		w.t += w.dir * w.speed * dt
		if w.t > L.len or w.t < 0 then
			w.t = math.clamp(w.t, 0, L.len)
			nextLane(w)
			L = lanes[w.lane]
		end
		local along = (L.b - L.a).Unit * w.dir
		local right = Vector3.new(-along.Z, 0, along.X)
		local pos = L.a + (L.b - L.a).Unit * w.t + right * w.side
		local dist = (pos - eye).Magnitude
		-- banded rates (the far ones skip frames; their walk still advances by time)
		local band = if dist < PathWalkers.NEAR then 1 elseif dist < PathWalkers.MID then 3 else 6
		if (frame + i) % band ~= 0 then
			continue
		end
		-- fade near the camera, back beyond
		local want = if dist < PathWalkers.HIDE_NEAR then 1 elseif dist > PathWalkers.SHOW_FAR then 0 else w.fade
		if want ~= w.fade then
			w.fade += math.clamp(want - w.fade, -dt * band * 3, dt * band * 3)
			for _, pc in w.pieces do
				pc.part.LocalTransparencyModifier = w.fade
			end
		end
		w.phase += dt * band * w.speed / 2.35 * math.pi -- (a stride of 4.7 studs per cycle)
		local s = math.sin(w.phase)
		local bob = math.abs(math.cos(w.phase)) * 0.12
		local root = CFrame.lookAt(pos + Vector3.new(0, STAND + bob, 0), pos + Vector3.new(0, STAND + bob, 0) + along)
		local swing = math.rad(26) * s
		for _, pc in w.pieces do
			local name = pc.name
			local rest = REST[name]
			local cf = root * CFrame.new(rest)
			local left = string.sub(name, 1, 4) == "Left"
			local sign = if left then 1 else -1
			if string.find(name, "Leg") or string.find(name, "Foot") then
				local hx = if left then -0.475 else 0.475
				local a = swing * sign
				local hip = CFrame.new(hx, HIP_Y, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(-hx, -HIP_Y, 0)
				local local_ = hip
				if name ~= "LeftUpperLeg" and name ~= "RightUpperLeg" then
					local knee = math.rad(28) * math.max(0, -math.sin(w.phase + (if left then 0 else math.pi)) )
					local_ = local_ * CFrame.new(hx, KNEE_Y, 0) * CFrame.Angles(knee, 0, 0) * CFrame.new(-hx, -KNEE_Y, 0)
				end
				cf = root * local_ * CFrame.new(rest)
			elseif string.find(name, "Arm") or string.find(name, "Hand") then
				local sx = if left then -0.95 else 0.95
				local a = -swing * sign * 0.8
				cf = root * CFrame.new(sx, SHOULDER_Y, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(-sx, -SHOULDER_Y, 0) * CFrame.new(rest)
			end
			table.insert(parts, pc.part)
			table.insert(cfs, cf * pc.skin)
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function PathWalkers.start()
	if not Config.PATH_WALKERS then
		return
	end
	task.spawn(function()
		-- the lab: the raised spawn plaza (OwnerPlaza) nearest to this player tells where the map's origin is
		local player = Players.LocalPlayer
		local plaza: BasePart? = nil
		for _ = 1, 60 do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local best = math.huge
			for _, d in Workspace:GetDescendants() do
				if d.Name == "OwnerPlaza" and d:IsA("BasePart") then
					local dist = if root and root:IsA("BasePart") then (d.Position - root.Position).Magnitude else 0
					if dist < best then
						plaza, best = d, dist
					end
				end
			end
			if plaza and readTemplate() then
				break
			end
			task.wait(1)
		end
		if not plaza or not template then
			return
		end
		local Plan = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
		local pz = Plan.PLAZAS and Plan.PLAZAS.SpawnPlaza
		if not pz then
			return
		end
		local origin = Vector3.new(plaza.Position.X - pz.at.X, plaza.Position.Y - 2 + 0.05 + 0.3, plaza.Position.Z - pz.at.Y)
		laneAt(origin)
		local f = Instance.new("Folder")
		f.Name = "PathWalkers"
		f.Parent = Workspace
		folder = f
		local count = PathWalkers.COUNT[tostring(player:GetAttribute("Device"))] or PathWalkers.COUNT.pc
		for _ = 1, count do
			local w = makeWalker()
			if w then
				table.insert(walkers, w)
			end
			task.wait() -- (one a frame: no hitch)
		end
		RunService.Heartbeat:Connect(step)
	end)
end

return PathWalkers
