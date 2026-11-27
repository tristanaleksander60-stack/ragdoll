--!strict
-- S2 THE SMOOTH BODY (owner: "krop er sammenhængende og ikke lavet ud af flere klodsede dele" + "ægte hænder ikke bare
-- kroge"; docs/BODY_V2.md 4c; Config.SMOOTH_BODY). The skinned mannequin made in Blender (art/models/mannequin,
-- imported by the owner 27 Nov 2026, kept as ReplicatedStorage.SmoothBody) is ONE connected mesh with 44 bones named
-- after the R15 parts plus fingers. On this screen only, the nearest MAX_BODIES ragdolls within BUILD_REACH wear it:
--   * each R15 bone follows its physics part every frame (bone = part * the rest offset), so the R15 parts stay the
--     physics skeleton and the mesh bends smoothly at every joint: no seams, no steps;
--   * the old block skins (and the crash-test rings and marks) are hidden while it is on; the dummy keeps its own Head
--     with today's faces; bullet holes and bandages are their own parts and stay;
--   * the fingers are posed by state (relaxed curl, loose when limp or dead, spread when crawling or fleeing, a fist
--     when angry), eased, never a snap; the part-built RealHands step aside for these bodies;
--   * X-ray: while the body's skins are see-through (the X-ray look), the smooth body steps aside so the bones show;
--   * the colour follows the torso skin (bruises, a frozen body), the material is the head's;
--   * a body hidden in a machine (MachineHidden) hides it too.
-- A body whose proportions differ from the mannequin by more than 15% (a giant, a tiny one) keeps its block skins.
-- Cost: 16 bone writes a body a frame within ANIM_REACH, 15 a second beyond; fingers only while a pose changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local SmoothBody = {}

SmoothBody.BUILD_REACH = 80
SmoothBody.DROP_REACH = 110
SmoothBody.ANIM_REACH = 45
SmoothBody.MAX_BODIES = 12
SmoothBody.FAR_RATE = 1 / 15
local SKIN_CHEAP = Config.LAGFREE_SKIN == true -- (LAG-FREE 2 item 3)
-- (THE v6 FIT PASS item 10, Config.V6_FAR_BODIES: on a PC the far ragdolls wear the SAME v6 mesh too, driven at
-- FAR_RATE without finger poses (the cheap version); a phone keeps 12 within 80 studs.)
do
	local UIS = game:GetService("UserInputService")
	local phone = UIS.TouchEnabled and not UIS.KeyboardEnabled
	if (Config :: any).V6_FAR_BODIES and (Config :: any).SMOOTH_BODY_V6 and not phone then
		SmoothBody.MAX_BODIES = 24
		SmoothBody.BUILD_REACH = 120
		SmoothBody.DROP_REACH = 150
	end
end

local rad = math.rad

-- The joint each R15 bone sits on, as the rig attachment inside that part.
local JOINT: { [string]: string } = {
	LowerTorso = "RootRigAttachment",
	UpperTorso = "WaistRigAttachment",
	Head = "NeckRigAttachment",
	LeftUpperArm = "LeftShoulderRigAttachment",
	LeftLowerArm = "LeftElbowRigAttachment",
	LeftHand = "LeftWristRigAttachment",
	RightUpperArm = "RightShoulderRigAttachment",
	RightLowerArm = "RightElbowRigAttachment",
	RightHand = "RightWristRigAttachment",
	LeftUpperLeg = "LeftHipRigAttachment",
	LeftLowerLeg = "LeftKneeRigAttachment",
	LeftFoot = "LeftAnkleRigAttachment",
	RightUpperLeg = "RightHipRigAttachment",
	RightLowerLeg = "RightKneeRigAttachment",
	RightFoot = "RightAnkleRigAttachment",
}
local HIDE_NAMES: { [string]: boolean } = { JointRing = true, TestMark = true }
for name in JOINT do
	HIDE_NAMES[name] = true
end
HIDE_NAMES.Head = nil

-- Finger poses (degrees): segments 1-3 curl, thumb 1-2 curl, spread (1 = rest).
local POSES: { [string]: { number } } = {
	Relaxed = { 14, 20, 12, 8, 10, 1 },
	Loose = { 5, 7, 4, 3, 3, 1.2 },
	Spread = { 0, 2, 0, 0, 0, 2.2 },
	Fist = { 85, 95, 70, 35, 50, 0.4 },
	-- (S2 rest, Config.HAND_POSES: holding something in the right hand (the paper, the tweezers, CPR hands) and pointing:
	-- a fist with the index straight)
	Grip = { 55, 68, 48, 28, 38, 0.8 },
	Point = { 85, 95, 70, 35, 50, 0.4 },
}
local HAND_POSES = Config.HAND_POSES == true
local LANE: { [string]: number } = { Index = 1.5, Middle = 0.5, Ring = -0.5, Pinky = -1.5 }

type Drive = { bone: Bone, part: BasePart, off: CFrame, parent: number?, localPos: Vector3, rot: CFrame }
type Digit = { bone: Bone, rest: CFrame, curlAxis: Vector3, spreadAxis: Vector3, seg: number, lane: number, thumb: boolean, left: boolean? }
type Body = {
	model: Model,
	folder: Instance,
	mesh: MeshPart,
	meshOff: CFrame,
	pelvis: BasePart,
	drives: { Drive },
	digits: { Digit },
	curl: { number },
	hidden: { [Instance]: boolean },
	acc: number,
	posed: boolean,
	ball: BasePart?, -- (v6: the round head)
	skull: { BasePart }?, -- (v6: the skull and jaw inside it, seen in X-ray)
	face: SurfaceGui?,
}

local template: Model? = nil
local restMesh: MeshPart? = nil
-- In the template's rest pose: each bone's world CFrame, and the body frame (right, up) the mannequin stands in.
local restWorld: { [string]: CFrame } = {}
local restFrame = CFrame.identity
local restLeg = 1
local bodies: { [Model]: Body } = {}
local meshPool: { MeshPart } = {} -- (AUDIT 38: dropped body meshes, reused)
local POOL_MAX = 8
local refused: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

function SmoothBody.has(model: Instance): boolean
	return bodies[model :: Model] ~= nil
end

local function poseOf(model: Model): string
	local state = model:GetAttribute("RagdollState")
	if model:GetAttribute("Vital") == "Dead" or state == "Ragdoll" or state == "Out" then
		return "Loose"
	end
	if state == "Crawling" or state == "Stumble" or state == "Fleeing" or state == "Flinch" then
		return "Spread"
	end
	local mood = model:GetAttribute("Mood")
	if HAND_POSES then
		if mood == "Point" then
			return "Point"
		end
		if model:GetAttribute("Paper") == true or mood == "Check" or mood == "CPR" or mood == "CPRFast" or mood == "CPRSlam" or mood == "CPROne" then
			return "Grip"
		end
	end
	local angry = model:GetAttribute("AngryUntil")
	if mood == "Rage" or mood == "Box" or (type(angry) == "number" and angry > Workspace:GetServerTimeNow()) then
		return "Fist"
	end
	return "Relaxed"
end

-- F89 (Config.SMOOTH_BODY_V2): the slim body (art/models/mannequin/build_mannequin_v2.py: arms down, slim, grey) is
-- ReplicatedStorage.SmoothBodyV2. Its arms are narrower than the physics arm parts, so its bones are driven
-- forward-kinematically: each bone turns like its part, but sits where its parent bone and THIS mesh's bone lengths put
-- it (no arm held out to reach the physics shoulder). Its colour is always the grey shell (the legs' skin), never the
-- torso's test-suit colour (no yellow bodies).
local V2 = Config.SMOOTH_BODY_V2 == true
-- RAGDOLL_10 THE LOOK (Config.SMOOTH_BODY_V3): the chunky toy crash-test dummy (art/models/mannequin/build_mannequin_v3.py:
-- thick limbs, joint rings, a chest plate, the yellow-and-black markings in its baked colour map) is
-- ReplicatedStorage.SmoothBodyV3 once imported; it wins over v2 and is driven the same forward-kinematic way.
local V3 = (Config :: any).SMOOTH_BODY_V3 == true
-- RAGDOLL_10 v6 (Config.SMOOTH_BODY_V6, APPROVED by the owner): the round chunky toy body; it wins over every older one.
local V6 = (Config :: any).SMOOTH_BODY_V6 == true
local function templateName(): string
	if V6 and ReplicatedStorage:FindFirstChild("SmoothBodyV6") then
		return "SmoothBodyV6"
	end
	if V3 and ReplicatedStorage:FindFirstChild("SmoothBodyV3") then
		return "SmoothBodyV3"
	end
	return if V2 and ReplicatedStorage:FindFirstChild("SmoothBodyV2") then "SmoothBodyV2" else "SmoothBody"
end

local function readTemplate(): boolean
	local t = ReplicatedStorage:FindFirstChild(templateName())
	local mesh = t and t:FindFirstChildWhichIsA("MeshPart", true)
	if not (t and t:IsA("Model") and mesh) then
		return false
	end
	for _, b in mesh:GetDescendants() do
		if b:IsA("Bone") then
			restWorld[b.Name] = b.WorldCFrame
		end
	end
	local need = { "LowerTorso", "Head", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "LeftFoot" }
	for _, n in need do
		if not restWorld[n] then
			return false
		end
	end
	local right = (restWorld.RightUpperArm.Position - restWorld.LeftUpperArm.Position).Unit
	local up0 = (restWorld.Head.Position - restWorld.LowerTorso.Position).Unit
	local up = (up0 - right * up0:Dot(right)).Unit
	restFrame = CFrame.fromMatrix(Vector3.zero, right, up)
	restLeg = (restWorld.LeftUpperLeg.Position - restWorld.LeftFoot.Position).Magnitude
	template = t
	restMesh = mesh
	return true
end

local function attachment(part: BasePart, name: string): Attachment?
	local a = part:FindFirstChild(name)
	return if a and a:IsA("Attachment") then a else nil
end

local function showBlocks(body: Body)
	for inst in body.hidden do
		if inst.Parent then
			if inst:IsA("BasePart") then
				inst.LocalTransparencyModifier = 0
			elseif inst:IsA("Decal") then
				inst.Transparency = 0
			end
		end
	end
	table.clear(body.hidden)
end

local function drop(body: Body)
	if body.face and body.face.Parent then
		body.face.Adornee = nil
		body.face.Enabled = true
	end
	if body.ball and body.ball.Parent then
		body.ball:Destroy() -- (the skull goes with it)
	end
	showBlocks(body)
	if body.mesh.Parent then
		if #meshPool < POOL_MAX and body.mesh.Name == "SmoothBody" then
			body.mesh.Parent = nil -- (AUDIT 38: kept for the next body, no clone/destroy at the edge)
			table.insert(meshPool, body.mesh)
		else
			body.mesh:Destroy()
		end
	end
	bodies[body.model] = nil
end

-- THE v6 FIT PASS, owner's test C (27 Nov: "ansigtet matcher ikke kroppen"): a v6 body wears the ROUND head of the
-- approved renders, in the body's own light grey, instead of the old dark cylinder head; the game's living face
-- (the Face SurfaceGui that FaceLife drives) is shown on the round head (Adornee), the old head hidden on this screen.
local GLASS_V6 = V6 and (Config :: any).BODY_FIT == true and ReplicatedStorage:FindFirstChild("SmoothBodyV6") ~= nil
local HEAD_GREY = Color3.fromRGB(166, 166, 169)
local HEAD_SIZE = 1.7 -- (BodyShape.HEAD radius 0.84)
local HEAD_LIFT = 0.15 -- the round head's centre above the physics head's centre (it sits on the short v6 neck)
local function roundHead(body: Body)
	if not GLASS_V6 then
		return
	end
	local head = body.model:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
	local ball = Instance.new("Part")
	ball.Name = "RoundHead"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(HEAD_SIZE, HEAD_SIZE, HEAD_SIZE)
	ball.Color = HEAD_GREY
	ball.Material = Enum.Material.SmoothPlastic
	-- (27 Nov late, owner: "Hovedet bugger på kroppen": welded to the physics head, the ball moved with the physics
	-- while the mesh's neck is drawn from the bone chain every frame, so the head wobbled on the neck. Now it is
	-- anchored and placed in drive() from the mesh's own Head bone, in the same frame as the body.)
	ball.CanCollide, ball.CanQuery, ball.CanTouch, ball.Massless, ball.Anchored = false, false, false, true, true
	ball.CastShadow = true
	ball.CFrame = head.CFrame * CFrame.new(0, HEAD_LIFT, 0)
	ball.Parent = body.folder
	body.ball = ball
	if head.LocalTransparencyModifier ~= 1 then
		head.LocalTransparencyModifier = 1
	end
	body.hidden[head] = true
	local face = head:FindFirstChild("Face")
	if face and face:IsA("SurfaceGui") then
		face.Adornee = ball
		body.face = face
	end
	-- (THE FINISH LINE, round-head accessories: a hat, a cap, a sweatband or headphones welded on the old smaller head by
	-- the server would sink into the bigger round one: on this screen everything welded on above the head's middle is
	-- lifted to the round head's top, now and when it comes later.)
	local lift = (HEAD_LIFT + HEAD_SIZE / 2) - head.Size.Y / 2
	local lifted: { [Instance]: boolean } = {}
	local function raise(w: Instance)
		if lifted[w] or lift <= 0.02 then
			return
		end
		if w:IsA("WeldConstraint") then
			local other = if w.Part0 == head then w.Part1 elseif w.Part1 == head then w.Part0 else nil
			if other and other ~= ball and not other:IsDescendantOf(ball) and other.Parent ~= body.model and head.CFrame:PointToObjectSpace(other.Position).Y > 0.25 then
				lifted[w] = true
				w.Enabled = false
				other.CFrame = other.CFrame + head.CFrame.UpVector * lift
				w.Enabled = true
			end
		elseif (w:IsA("Weld") or w:IsA("Motor6D")) and w.Part0 == head and w.Part1 and w.Part1.Parent ~= body.model and w.C0.Position.Y > 0.25 then
			lifted[w] = true
			w.C0 = w.C0 + Vector3.new(0, lift, 0)
		elseif w:IsA("Weld") and w.Part1 == head and w.Part0 and w.Part0.Parent ~= body.model and w.C1.Position.Y > 0.25 then
			lifted[w] = true -- (an Accessory's weld: Handle to Head)
			w.C1 = w.C1 + Vector3.new(0, lift, 0)
		end
	end
	for _, d in body.model:GetDescendants() do
		raise(d)
	end
	body.model.DescendantAdded:Connect(function(d)
		if body.ball and body.ball.Parent then
			task.defer(raise, d)
		end
	end)
	-- (owner's v6 test B: the whole skeleton in X-ray, the head too: a skull, two dark eye holes and a jaw inside the
	-- round head, shown only while the body is glass)
	local skull = {}
	local function piece(shape: Enum.PartType, size: Vector3, at: CFrame, colour: Color3)
		local p = Instance.new("Part")
		p.Name = "XraySkull"
		p.Shape = shape
		p.Size = size
		p.Color = colour
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.Anchored, p.CastShadow = false, false, false, true, false, false
		p.Transparency = 1
		p.CFrame = ball.CFrame * at
		local pw = Instance.new("WeldConstraint")
		pw.Part0 = ball
		pw.Part1 = p
		pw.Parent = p
		p.Parent = ball
		table.insert(skull, p)
	end
	local BONE = Color3.fromRGB(236, 226, 200)
	piece(Enum.PartType.Ball, Vector3.one * 1.22, CFrame.new(0, 0.1, 0.02), BONE)
	piece(Enum.PartType.Ball, Vector3.one * 0.3, CFrame.new(-0.24, 0.12, -0.5), Color3.fromRGB(60, 52, 48))
	piece(Enum.PartType.Ball, Vector3.one * 0.3, CFrame.new(0.24, 0.12, -0.5), Color3.fromRGB(60, 52, 48))
	piece(Enum.PartType.Block, Vector3.new(0.7, 0.24, 0.5), CFrame.new(0, -0.48, -0.22), BONE)
	body.skull = skull
end

local function build(model: Model): Body?
	local mesh0 = restMesh
	if not mesh0 then
		return nil
	end
	local folder = model:FindFirstChild("Skins")
	local pelvis = model:FindFirstChild("LowerTorso")
	if not (folder and pelvis and pelvis:IsA("BasePart")) then
		return nil -- (DummySkins dresses it first)
	end
	-- The dummy's own rest: every joint from its rig attachments, measured in the pelvis frame.
	local parts: { [string]: BasePart } = {}
	local joints: { [string]: Vector3 } = {}
	for name, att in JOINT do
		local p = model:FindFirstChild(name)
		local a = p and p:IsA("BasePart") and attachment(p, att) or nil
		if not (p and p:IsA("BasePart") and a) then
			return nil
		end
		parts[name] = p
		joints[name] = a.Position
	end
	-- Proportions: hip to ankle, through the dummy's chain (hip->knee in the thigh, knee->ankle in the shin).
	local thigh, shin = parts.LeftUpperLeg, parts.LeftLowerLeg
	local knee = attachment(thigh, "LeftKneeRigAttachment")
	local ankle = attachment(shin, "LeftAnkleRigAttachment")
	if not (knee and ankle) then
		return nil
	end
	local leg = (knee.Position - joints.LeftUpperLeg).Magnitude + (ankle.Position - joints.LeftLowerLeg).Magnitude
	if math.abs(leg / restLeg - 1) > 0.15 then
		refused[model] = os.clock()
		return nil
	end
	local mesh = table.remove(meshPool) or mesh0:Clone()
	mesh.Name = "SmoothBody"
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.CanQuery = false
	mesh.CanTouch = false
	mesh.Massless = true
	mesh.CastShadow = true
	local torsoSkin = folder:FindFirstChild(if V2 then "LeftUpperLeg" else "UpperTorso")
	local look = if torsoSkin and torsoSkin:IsA("BasePart") then torsoSkin else pelvis
	mesh.Color = look.Color
	mesh.Material = look.Material
	mesh.Reflectance = look.Reflectance
	mesh.TextureID = ""
	local drives: { Drive } = {}
	local digits: { Digit } = {}
	local bonesByName: { [string]: Bone } = {}
	for _, b in mesh:GetDescendants() do
		if b:IsA("Bone") then
			bonesByName[b.Name] = b
		end
	end
	-- Each R15 bone: the virtual rest part that would hold it (the bone at the part's joint, turned like the body), then
	-- the bone's offset from that part. Driven parents first (GetDescendants order is depth first).
	local function restPartOf(name: string): CFrame
		local jointRot = CFrame.new(restWorld[name].Position) * restFrame
		return jointRot * CFrame.new(joints[name]):Inverse()
	end
	local driveIndex: { [Instance]: number } = {}
	local fk = (V2 and templateName() == "SmoothBodyV2") or templateName() == "SmoothBodyV3" or templateName() == "SmoothBodyV6"
	for _, b in mesh:GetDescendants() do
		if b:IsA("Bone") then
			local name = if b.Name == "HumanoidRootPart" then "LowerTorso" else b.Name
			local part = parts[name]
			local w = restWorld[b.Name]
			if part and w then
				local parentBone = b.Parent
				local pIdx = if fk and parentBone then driveIndex[parentBone] else nil
				table.insert(drives, {
					bone = b,
					part = part,
					off = restPartOf(name):Inverse() * w,
					parent = pIdx,
					localPos = if pIdx and parentBone then restWorld[parentBone.Name]:PointToObjectSpace(w.Position) else Vector3.zero,
					rot = restFrame:Inverse() * w.Rotation,
				})
				driveIndex[b] = #drives
			end
		end
	end
	-- Fingers: curl toward the palm (the palm faces the body), spread across the hand.
	local front = restFrame.LookVector
	for name, b in bonesByName do
		local side, finger, seg = string.match(name, "^(%u%l+)(%u%l+)(%d)$")
		if side and finger and seg and (LANE[finger] or finger == "Thumb") then
			local n = tonumber(seg) or 1
			local w = restWorld[name]
			local nextBone = bonesByName[side .. finger .. tostring(n + 1)]
			local tip = if nextBone then restWorld[nextBone.Name].Position else w.Position + (w.Position - restWorld[(if n > 1 then side .. finger .. tostring(n - 1) else side .. "Hand")].Position)
			local dir = (tip - w.Position)
			dir = if dir.Magnitude > 1e-4 then dir.Unit else -restFrame.UpVector
			local toPalm = if side == "Left" then restFrame.RightVector else -restFrame.RightVector
			local curlAxis = dir:Cross(toPalm)
			local spreadAxis = dir:Cross(front)
			table.insert(digits, {
				bone = b,
				rest = b.CFrame,
				curlAxis = if curlAxis.Magnitude > 1e-4 then w:VectorToObjectSpace(curlAxis.Unit) else Vector3.xAxis,
				spreadAxis = if spreadAxis.Magnitude > 1e-4 then w:VectorToObjectSpace(spreadAxis.Unit) else Vector3.zAxis,
				seg = n,
				lane = LANE[finger] or 0,
				thumb = finger == "Thumb",
				left = side == "Left",
			})
		end
	end
	local body: Body = {
		model = model,
		folder = folder,
		mesh = mesh,
		meshOff = restPartOf("LowerTorso"):Inverse() * mesh0.CFrame,
		pelvis = pelvis,
		drives = drives,
		digits = digits,
		curl = table.clone(POSES.Relaxed),
		hidden = {},
		acc = 0,
		posed = false,
	}
	mesh.CFrame = pelvis.CFrame * body.meshOff
	mesh.Parent = folder
	bodies[model] = body
	roundHead(body)
	return body
end

-- Is this body's X-ray look on (its skins see-through)?
local XRAY_GLASS = 0.78
local function xrayed(body: Body): boolean
	for _, s in body.folder:GetChildren() do
		if s:IsA("BasePart") and s ~= body.mesh and JOINT[s.Name] and s.Transparency > 0.01 then
			return true
		end
	end
	return false
end

local function hideBlocks(body: Body)
	for _, d in body.folder:GetChildren() do
		if d:IsA("BasePart") and d ~= body.mesh and HIDE_NAMES[d.Name] then
			if d.LocalTransparencyModifier ~= 1 then
				d.LocalTransparencyModifier = 1
			end
			body.hidden[d] = true
			if d.Name == "TestMark" then
				for _, dec in d:GetChildren() do
					if dec:IsA("Decal") and dec.Transparency ~= 1 then
						dec.Transparency = 1
						body.hidden[dec] = true
					end
				end
			end
		end
	end
end

local function d0Head(body: Body): CFrame
	local h = body.model:FindFirstChild("Head")
	return if h and h:IsA("BasePart") then h.CFrame else body.pelvis.CFrame
end

local function drive(body: Body)
	local headCf: CFrame? = nil
	local mesh = body.mesh
	mesh.CFrame = body.pelvis.CFrame * body.meshOff
	local cfs: { CFrame } = {}
	for i, d in body.drives do
		local cf
		local p = d.parent
		if p and cfs[p] then
			cf = CFrame.new(cfs[p]:PointToWorldSpace(d.localPos)) * (d.part.CFrame.Rotation * d.rot)
		else
			cf = d.part.CFrame * d.off
		end
		cfs[i] = cf
		d.bone.WorldCFrame = cf
		if d.part.Name == "Head" and d.bone.Name == "Head" then
			headCf = cf
		end
	end
	local ball = body.ball
	if ball and headCf then
		local B = body :: any
		if not B.ballOff then
			B.ballOff = headCf:Inverse() * (d0Head(body) * CFrame.new(0, HEAD_LIFT, 0))
		end
		ball.CFrame = headCf * B.ballOff
	end
end

local function poseFingers(body: Body, dt: number)
	local name = poseOf(body.model)
	local target = POSES[name] or POSES.Relaxed
	local k = 1 - math.exp(-10 * dt)
	local moved = false
	-- (the pointing index straightens and the gripping is the right hand's only: both eased like the rest)
	local B = body :: any
	local pointW, gripW = B.pointW or 0, B.gripW or 0
	B.pointW = pointW + ((if name == "Point" then 1 else 0) - pointW) * k
	B.gripW = gripW + ((if name == "Grip" then 1 else 0) - gripW) * k
	if math.abs(B.pointW - pointW) > 0.002 or math.abs(B.gripW - gripW) > 0.002 then
		moved = true
	end
	for i = 1, 6 do
		local c = body.curl[i] + (target[i] - body.curl[i]) * k
		if math.abs(c - body.curl[i]) > 0.05 then
			moved = true
		end
		body.curl[i] = c
	end
	if not moved and body.posed then
		return
	end
	body.posed = true
	for _, g in body.digits do
		local idx = if g.thumb then 3 + math.min(g.seg, 2) else math.min(g.seg, 3)
		local curl = body.curl[idx]
		if g.left and B.gripW > 0 then
			curl += (POSES.Relaxed[idx] - curl) * B.gripW -- (the left hand stays relaxed while the right one holds)
		end
		if g.lane == 1.5 and not g.thumb and B.pointW > 0 then
			curl *= 1 - B.pointW -- (the index points)
		end
		local cf = g.rest * CFrame.fromAxisAngle(g.curlAxis, rad(curl))
		if g.seg == 1 and not g.thumb then
			cf *= CFrame.fromAxisAngle(g.spreadAxis, rad(g.lane * 5 * (body.curl[6] - 1)))
		end
		g.bone.CFrame = cf
	end
end

local farAcc = 0
local function step(dt: number)
	local camera = Workspace.CurrentCamera
	local dummies = Workspace:FindFirstChild("Dummies")
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector
	farAcc += dt
	local farTick = farAcc >= SmoothBody.FAR_RATE
	if farTick then
		farAcc = 0
		-- Drop the gone and the far; build the nearest new ones (2 an update at most).
		local count = 0
		for model, body in bodies do
			local gone = not model.Parent or not body.folder.Parent or not body.pelvis.Parent or not body.mesh.Parent
			if gone or (body.pelvis.Position - eye).Magnitude > SmoothBody.DROP_REACH then
				drop(body)
			else
				count += 1
			end
		end
		if dummies and count < SmoothBody.MAX_BODIES then
			local list: { { m: Model, d: number } } = {}
			for _, m in dummies:GetChildren() do
				if m:IsA("Model") and not bodies[m] and m:GetAttribute("Mannequin") == true and not (refused[m] and os.clock() - refused[m] < 30) then
					local pelvis = m:FindFirstChild("LowerTorso")
					if pelvis and pelvis:IsA("BasePart") then
						local d = (pelvis.Position - eye).Magnitude
						if d <= SmoothBody.BUILD_REACH then
							table.insert(list, { m = m, d = d })
						end
					end
				end
			end
			table.sort(list, function(a, b)
				return a.d < b.d
			end)
			for i = 1, math.min(#list, SmoothBody.MAX_BODIES - count, 2) do
				build(list[i].m)
			end
		end
	end
	for _, body in bodies do
		local hidden = body.model:GetAttribute("MachineHidden") == true
		if GLASS_V6 and not hidden then
			-- (THE v6 FIT PASS item 3 + the owner's A2: only the X-RAY toggle turns the whole v6 body to glass; a limb shot 3
			-- times in a row shows its own bones through a solid body (DummySkins limbGlow), the mesh never changes for it)
			local want = if xrayed(body) and Players.LocalPlayer:GetAttribute("XRayOn") == true then XRAY_GLASS else 0
			if body.mesh.Transparency ~= want then
				body.mesh.Transparency = want
			end
			hideBlocks(body)
		elseif xrayed(body) or hidden then
			-- (the X-ray look shows the glass skins and the bones; a machine hides everything)
			if body.mesh.Transparency ~= 1 then
				body.mesh.Transparency = 1
				showBlocks(body)
			end
			if hidden then
				hideBlocks(body)
			end
		else
			if body.mesh.Transparency ~= 0 then
				body.mesh.Transparency = 0
			end
			if farTick then
				hideBlocks(body)
				local skin = body.folder:FindFirstChild(if V2 then "LeftUpperLeg" else "UpperTorso")
				if skin and skin:IsA("BasePart") and body.mesh.Color ~= skin.Color then
					body.mesh.Color = skin.Color
				end
			end
		end
		if body.ball then
			if body.ball.Transparency ~= body.mesh.Transparency then
				body.ball.Transparency = body.mesh.Transparency
			end
			if body.face then
				body.face.Enabled = body.mesh.Transparency < 1
			end
			if body.skull then
				local show = body.mesh.Transparency > 0.05 and body.mesh.Transparency < 1
				local want = if show then 0 else 1
				if body.skull[1].Transparency ~= want then
					for _, p in body.skull do
						p.Transparency = want
					end
				end
			end
		end
		local toBody = body.pelvis.Position - eye
		local near = toBody.Magnitude <= SmoothBody.ANIM_REACH
		-- (LAG-FREE 2 item 3, Config.LAGFREE_SKIN: a near body behind or beside the camera is driven at FAR_RATE only;
		-- a sleeping body (DummyControl's Asleep) is drawn once and then left still)
		if SKIN_CHEAP and near and toBody.Magnitude > 6 and toBody.Unit:Dot(camLook) < 0.25 then
			near = false
		end
		local B = body :: any
		if SKIN_CHEAP and body.model:GetAttribute("Asleep") == true then
			if B.sleptDrawn then
				continue
			end
			B.sleptDrawn = true
		elseif B.sleptDrawn then
			B.sleptDrawn = nil
		end
		body.acc += dt
		if near or farTick or B.sleptDrawn then
			drive(body)
			if near then
				poseFingers(body, body.acc)
			end
			body.acc = 0
		end
	end
end

function SmoothBody.start()
	if not Config.SMOOTH_BODY then
		return
	end
	if not readTemplate() then
		local t = ReplicatedStorage:WaitForChild(templateName(), 20)
		if not (t and readTemplate()) then
			return -- (no smooth body in the place: the block skins and the part hands stay)
		end
	end
	pcall(function()
		local hands = require(script.Parent:WaitForChild("RealHands")) :: any
		hands.skip = SmoothBody.has
	end)
	RunService.RenderStepped:Connect(step)
end

return SmoothBody
