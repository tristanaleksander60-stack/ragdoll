--!strict
-- S2 REAL HANDS, NOT HOOKS (owner, 26 Nov 2026 late: "Sørg for ragdolls har ægte hænder ikke bare kroge"; Config.REAL_HANDS;
-- docs/BODY_V2.md 4c "REAL HANDS" + "Real fingers"). Plan B until the skinned mannequin body exists: on this screen only,
-- every ragdoll near the camera gets two real hands built from small rounded parts:
--   * a palm with a soft rounded back (an ellipsoid), set where the forearm's skin ends, so the wrist blends into it;
--   * 4 fingers of 3 tapering segments (overlapping ends read as knuckles) and a thumb of 2, set apart at an angle;
--   * Motor6D joints, posed by the body's state: relaxed curl, loose and open (limp, out cold, dead), spread wide
--     (crawling, bracing, fleeing), a fist (angry, the revenge shove), eased between poses, never a snap.
-- The old hook-shaped hand skin (DummySkins) is shrunk away while the real hand is on and comes back when it goes.
-- The parts are massless, never collide, never queried, live in the body's Skins model (so a machine hiding the
-- body hides them too) and copy the hand skin's colour (bruises) and its X-ray see-through each update.
-- Cost (phones): built for the nearest MAX_BODIES within BUILD_REACH, fingers animated within ANIM_REACH (else frozen),
-- removed beyond DROP_REACH; 30 parts a body; updated 15 times a second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local RealHands = {}

RealHands.BUILD_REACH = 70
RealHands.DROP_REACH = 100
RealHands.ANIM_REACH = 40
RealHands.MAX_BODIES = 14
RealHands.RATE = 1 / 15

local rad = math.rad

type Finger = { motors: { Motor6D }, bias: number }
type Hand = {
	side: number, -- Right -1, Left +1 (the palm faces side * X, toward the body)
	part: BasePart, -- the physics hand block
	skin: BasePart?, -- the old hook skin (shrunk while this hand is on)
	skinSize: Vector3?,
	parts: { BasePart },
	fingers: { Finger },
	thumb: Finger,
	curl: { number }, -- current pose: 3 finger segments, 2 thumb segments, spread
}
type Body = { model: Model, folder: Model, hands: { Hand } }

local bodies: { [Model]: Body } = {}

-- The poses (degrees): finger segments 1-3, thumb segments 1-2, then the spread.
local POSES: { [string]: { number } } = {
	Relaxed = { 16, 22, 14, 10, 12, 0.6 },
	Loose = { 6, 8, 4, 4, 4, 0.9 },
	Spread = { 2, 3, 0, 0, 0, 1.7 },
	Fist = { 88, 100, 72, 38, 55, 0 },
}

local function poseOf(model: Model): string
	local state = model:GetAttribute("RagdollState")
	if model:GetAttribute("Vital") == "Dead" or state == "Ragdoll" or state == "Out" then
		return "Loose"
	end
	if state == "Crawling" or state == "Stumble" or state == "Fleeing" or state == "Flinch" then
		return "Spread"
	end
	local mood = model:GetAttribute("Mood")
	local angry = model:GetAttribute("AngryUntil")
	if mood == "Rage" or mood == "Box" or (type(angry) == "number" and angry > Workspace:GetServerTimeNow()) then
		return "Fist"
	end
	return "Relaxed"
end

local function piece(size: Vector3, colour: Color3, material: Enum.Material, folder: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = "RealHand"
	p.Size = size
	p.Color = colour
	p.Material = material
	p.Massless = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Anchored = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere -- (an ellipsoid the size of the part: rounded, no box edges)
	mesh.Parent = p
	p.Parent = folder
	return p
end

local function joint(parent: BasePart, child: BasePart, c0: CFrame, c1: CFrame): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = "Knuckle"
	m.Part0 = parent
	m.Part1 = child
	m.C0 = c0
	m.C1 = c1
	m.Parent = child
	return m
end

-- One hand on the block `part` (its +Y toward the wrist; the fingers point down).
local function buildHand(part: BasePart, side: number, skin: BasePart?, folder: Model): Hand
	local colour = if skin then skin.Color else part.Color
	local material = if skin then skin.Material else part.Material
	local s = math.max(0.6, part.Size.X / 0.95) -- (bigger or smaller bodies: the hand scales with the block)
	local x0 = side * 0.2 * s -- (the forearm's skin sits this far toward the body: the hand follows it)
	local parts: { BasePart } = {}
	local palm = piece(Vector3.new(0.3, 0.52, 0.56) * s, colour, material, folder)
	table.insert(parts, palm)
	joint(part, palm, CFrame.new(x0, -0.16 * s, 0), CFrame.identity)
	-- (a soft heel of the hand toward the thumb, so the palm is not one flat egg)
	local heel = piece(Vector3.new(0.26, 0.3, 0.26) * s, colour, material, folder)
	table.insert(parts, heel)
	joint(palm, heel, CFrame.new(side * 0.04 * s, -0.02 * s, -0.17 * s), CFrame.identity)
	local fingers: { Finger } = {}
	-- index (front, -Z) to pinky; length scale, splay direction
	local spec = { { z = -0.19, len = 1.0, splay = 1 }, { z = -0.063, len = 1.08, splay = 0.35 }, { z = 0.063, len = 1.0, splay = -0.35 }, { z = 0.19, len = 0.8, splay = -1 } }
	for i, f in spec do
		local motors: { Motor6D } = {}
		local parent: BasePart = palm
		local parentHalf = 0.2 * s
		local lengths = { 0.2, 0.15, 0.12 }
		for k, l in lengths do
			local len = l * f.len * s
			local thick = (0.14 - 0.012 * k) * s
			local seg = piece(Vector3.new(thick, len * 1.35, thick * 0.95), colour, material, folder)
			table.insert(parts, seg)
			local c0 = if k == 1 then CFrame.new(0, -parentHalf, (f.z * s)) * CFrame.Angles(rad(6 * f.splay), 0, 0) else CFrame.new(0, -parentHalf, 0)
			table.insert(motors, joint(parent, seg, c0, CFrame.new(0, len / 2, 0)))
			parent, parentHalf = seg, len / 2
		end
		fingers[i] = { motors = motors, bias = if i == 4 then 6 else 0 }
	end
	-- The thumb: from the heel of the hand, down and forward, set apart at an angle.
	local thumbMotors: { Motor6D } = {}
	local parent: BasePart = heel
	local parentHalf = 0.0
	for k, l in { 0.19, 0.15 } do
		local len = l * s
		local thick = (0.15 - 0.015 * k) * s
		local seg = piece(Vector3.new(thick, len * 1.35, thick), colour, material, folder)
		table.insert(parts, seg)
		local c0 = if k == 1 then CFrame.new(side * 0.03 * s, -0.08 * s, -0.06 * s) * CFrame.Angles(rad(38), 0, rad(side * 18)) else CFrame.new(0, -parentHalf, 0)
		table.insert(thumbMotors, joint(parent, seg, c0, CFrame.new(0, len / 2, 0)))
		parent, parentHalf = seg, len / 2
	end
	local skinSize: Vector3? = nil
	if skin then
		skinSize = skin.Size
		skin.Size = Vector3.new(0.05, 0.05, 0.05) -- (the hook skin goes away under the real hand)
	end
	local p = POSES.Relaxed
	return {
		side = side, part = part, skin = skin, skinSize = skinSize, parts = parts,
		fingers = fingers, thumb = { motors = thumbMotors, bias = 0 },
		curl = { p[1], p[2], p[3], p[4], p[5], p[6] },
	}
end

local function dropHand(hand: Hand)
	for _, p in hand.parts do
		p:Destroy()
	end
	local skin = hand.skin
	if skin and skin.Parent and hand.skinSize then
		skin.Size = hand.skinSize
	end
end

local function dropBody(body: Body)
	for _, h in body.hands do
		dropHand(h)
	end
	bodies[body.model] = nil
end

local function buildBody(model: Model): Body?
	local folder = model:FindFirstChild("Skins")
	if not (folder and folder:IsA("Model")) then
		return nil -- (DummySkins dresses it first; the hand follows the skin)
	end
	local hands: { Hand } = {}
	for _, name in { "RightHand", "LeftHand" } do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			local skin = folder:FindFirstChild(name)
			table.insert(hands, buildHand(part, if name == "RightHand" then -1 else 1, if skin and skin:IsA("BasePart") then skin else nil, folder))
		end
	end
	if #hands == 0 then
		return nil
	end
	local body = { model = model, folder = folder, hands = hands }
	bodies[model] = body
	return body
end

local function pose(hand: Hand, target: { number }, k: number)
	local c = hand.curl
	for i = 1, 6 do
		c[i] += (target[i] - c[i]) * k
	end
	local sd = hand.side
	for i, f in hand.fingers do
		local splay = (({ 1, 0.35, -0.35, -1 }) :: { number })[i] * 7 * c[6]
		for kk, m in f.motors do
			-- (curl: the tip goes toward the palm, which faces side * X: a turn about Z)
			local a = rad(c[kk] + f.bias)
			m.Transform = if kk == 1 then CFrame.Angles(rad(splay), 0, sd * a) else CFrame.Angles(0, 0, sd * a)
		end
	end
	for kk, m in hand.thumb.motors do
		m.Transform = CFrame.Angles(0, 0, sd * rad(c[3 + kk]))
	end
end

local function mirror(hand: Hand)
	local skin = hand.skin
	if not (skin and skin.Parent) then
		return
	end
	local t = skin.Transparency
	local col = skin.Color
	for _, p in hand.parts do
		if p.Transparency ~= t then
			p.Transparency = t
		end
		if p.Color ~= col then
			p.Color = col
		end
	end
end

local acc = 0
local function step(dt: number)
	acc += dt
	if acc < RealHands.RATE then
		return
	end
	local elapsed = acc
	acc = 0
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local folder = Workspace:FindFirstChild("Dummies")
	-- Drop the ones gone or too far.
	for model, body in bodies do
		local pelvis = model:FindFirstChild("LowerTorso")
		local gone = not model.Parent or not body.folder.Parent or not (pelvis and pelvis:IsA("BasePart"))
		if not gone then
			for _, h in body.hands do
				if not h.part.Parent or h.part.Parent ~= model then
					gone = true
				end
			end
		end
		if gone or ((pelvis :: BasePart).Position - eye).Magnitude > RealHands.DROP_REACH then
			dropBody(body)
		end
	end
	-- Build for the nearest bodies within reach.
	if folder then
		local list: { { m: Model, d: number } } = {}
		local count = 0
		for _ in bodies do
			count += 1
		end
		if count < RealHands.MAX_BODIES then
			for _, m in folder:GetChildren() do
				if m:IsA("Model") and not bodies[m] then
					local pelvis = m:FindFirstChild("LowerTorso")
					if pelvis and pelvis:IsA("BasePart") then
						local d = (pelvis.Position - eye).Magnitude
						if d <= RealHands.BUILD_REACH then
							table.insert(list, { m = m, d = d })
						end
					end
				end
			end
			table.sort(list, function(a, b)
				return a.d < b.d
			end)
			for i = 1, math.min(#list, RealHands.MAX_BODIES - count, 2) do -- (at most 2 new bodies an update: no hitch)
				buildBody(list[i].m)
			end
		end
	end
	-- Pose and mirror.
	local k = 1 - math.exp(-10 * elapsed)
	for model, body in bodies do
		-- lihfolk-ignore: findfirstchild-chain (nil-checked on the next line)
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart?
		local near = pelvis ~= nil and (pelvis.Position - eye).Magnitude <= RealHands.ANIM_REACH
		local target = POSES[poseOf(model)]
		for _, h in body.hands do
			mirror(h)
			if near then
				pose(h, target, k)
			end
		end
	end
end

function RealHands.start()
	if Config.REAL_HANDS == false then
		return
	end
	local _ = Players.LocalPlayer
	RunService.Heartbeat:Connect(step)
end

return RealHands
