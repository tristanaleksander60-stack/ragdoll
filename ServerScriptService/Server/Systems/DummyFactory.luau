--!strict
-- Spawns crash-test dummies as engine-built R15 rigs, so they get the same
-- Avatar Joint Upgrade joints as player characters. Round 2 (N7): they wear the real crash-test
-- marks (the yellow and black quartered circles on both sides of the head and on the chest),
-- drawn on SurfaceGuis so they sit flat whatever the mesh. The crowd takes them off
-- (CrowdService dresses people in their own clothes).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActiveRagdoll = require(ReplicatedStorage.Shared.Ragdoll.ActiveRagdoll)
local Assets = require(ReplicatedStorage.Shared.Assets)
local DummyControl = require(script.Parent.DummyControl)
local Config = require(ReplicatedStorage.Shared.Config)

local DummyFactory = {}

local YELLOW = Color3.fromRGB(245, 200, 40)

-- The look (10 Nov 2026, the owner: far more realistic, thinner, more joints, the grey of the big
-- Steam ragdoll games). A slim test mannequin: a neutral grey shell, the forearms and shins a shade
-- darker, dark hands and feet, and a dark ball at each elbow and knee so every joint reads; the
-- crash-test marks stay (the game's own sign). The crowd paints its people over all of it.
DummyFactory.SHELL = Color3.fromRGB(104, 105, 109)
DummyFactory.SHELL_LOW = Color3.fromRGB(88, 89, 94)
DummyFactory.JOINT = Color3.fromRGB(42, 44, 50)
-- LOOK_V3 (19 Nov 2026): the plain white mannequin of the big ragdoll games, no dark joints.
if Config.LOOK_V3 then
	DummyFactory.SHELL = Config.LOOK_V3_DUMMY
	DummyFactory.SHELL_LOW = Config.LOOK_V3_DUMMY_LOW
	DummyFactory.JOINT = Config.LOOK_V3_DUMMY_ENDS
end
-- V9-0o: the grey, matte tone (Config.DUMMY_TONE) over the white.
local TONE = Config.DUMMY_TONE
if TONE then
	DummyFactory.SHELL = TONE.shell
	DummyFactory.SHELL_LOW = TONE.low
	DummyFactory.JOINT = TONE.ends
end
DummyFactory.MATERIAL = if TONE then TONE.material else Enum.Material.SmoothPlastic
DummyFactory.REFLECTANCE = if TONE then (TONE.reflectance or 0) else 0.04 -- (V10: glossy, head and body alike)
DummyFactory.HEAD = if game:GetService("ReplicatedStorage"):FindFirstChild("DummySkin2") then 1 else 0.86 -- the head's size after the build (a real body's head is smaller than Roblox's)
-- (Slender human proportions: Roblox's own scales at their thin end, the body type towards Rthro's
-- longer limbs and smaller head.)
local SCALE = if game:GetService("ReplicatedStorage"):FindFirstChild("DummySkin2") then { width = 0.95, depth = 0.95, height = 1, head = 1, bodyType = 0, proportion = 0 } else { width = 0.7, depth = 0.75, height = 1, head = 0.95, bodyType = 0.7, proportion = 1 }

local function description(): HumanoidDescription
	local d = Instance.new("HumanoidDescription")
	d.HeadColor = DummyFactory.SHELL
	d.TorsoColor = DummyFactory.SHELL
	d.LeftArmColor = DummyFactory.SHELL
	d.RightArmColor = DummyFactory.SHELL
	d.LeftLegColor = DummyFactory.SHELL
	d.RightLegColor = DummyFactory.SHELL
	d.WidthScale = SCALE.width
	d.DepthScale = SCALE.depth
	d.HeightScale = SCALE.height
	d.HeadScale = SCALE.head
	d.BodyTypeScale = SCALE.bodyType
	d.ProportionScale = SCALE.proportion
	return d
end

-- The segments' shades (the client's sculpted skins take each limb's colour: DummySkins).
local LOW = { LeftLowerArm = true, RightLowerArm = true, LeftLowerLeg = true, RightLowerLeg = true }
local ENDS = { LeftHand = true, RightHand = true, LeftFoot = true, RightFoot = true }

-- RAGDOLL_10 THE v6 FIT PASS, item 2 (Config.BODY_FIT + SMOOTH_BODY_V6): the physics parts sit just inside the
-- approved v6 body (Shared/BodyShape): a deep torso (1.6 deep), round thinner arms, slimmer shins, long round boots.
-- Only the cross-sections change: every part keeps its length and its joints (the rig attachments stay where they are),
-- and its mass (ActiveRagdoll.prepareParts sets each part's density from Config.PHYSICS.MASS, not from its size).
local V6_SIZE: { [string]: { x: number?, z: number? } } = {
	UpperTorso = { z = 1.5 }, -- v6: 1.94 wide, 1.6 deep at the chest
	LowerTorso = { x = 1.75, z = 1.4 }, -- the hips: 1.76 wide, 1.48 deep
	LeftUpperArm = { x = 0.72, z = 0.72 }, RightUpperArm = { x = 0.72, z = 0.72 }, -- the upper arm 0.75 round
	LeftLowerArm = { x = 0.66, z = 0.66 }, RightLowerArm = { x = 0.66, z = 0.66 }, -- the forearm 0.7
	LeftHand = { x = 0.4, z = 0.7 }, RightHand = { x = 0.4, z = 0.7 }, -- the thick palm facing the body
	LeftUpperLeg = { x = 0.92, z = 0.92 }, RightUpperLeg = { x = 0.92, z = 0.92 }, -- the thigh 0.94
	LeftLowerLeg = { x = 0.78, z = 0.78 }, RightLowerLeg = { x = 0.78, z = 0.78 }, -- the shin 0.8
	LeftFoot = { x = 0.72, z = 1.25 }, RightFoot = { x = 0.72, z = 1.25 }, -- the round boot, 1.32 long
}
local function fitV6(model: Model)
	if not ((Config :: any).BODY_FIT and (Config :: any).SMOOTH_BODY_V6 and ReplicatedStorage:FindFirstChild("SmoothBodyV6")) then
		return
	end
	for name, want in V6_SIZE do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Size = Vector3.new(want.x or p.Size.X, p.Size.Y, want.z or p.Size.Z)
		end
	end
	model:SetAttribute("BodyV6", true)
end

local function segment(model: Model)
	-- A smaller head, still sitting on the neck (it shrinks towards its neck joint).
	local head = model:FindFirstChild("Head")
	local neck = head and head:FindFirstChild("NeckRigAttachment")
	if head and head:IsA("BasePart") and neck and neck:IsA("Attachment") then
		local k = DummyFactory.HEAD
		local pivot = neck.WorldPosition
		local cf = head.CFrame
		head.Size *= k
		head.CFrame = (cf - cf.Position) + pivot + (cf.Position - pivot) * k
		for _, a in head:GetChildren() do
			if a:IsA("Attachment") then
				a.Position *= k
			end
		end
	end
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Material = DummyFactory.MATERIAL
			d.Reflectance = DummyFactory.REFLECTANCE
			if LOW[d.Name] then
				d.Color = DummyFactory.SHELL_LOW
			elseif ENDS[d.Name] then
				d.Color = DummyFactory.JOINT
			end
		end
	end
	-- Every screen dresses it in the sculpted mannequin (client DummySkins: nothing extra is sent).
	model:SetAttribute("Mannequin", true)
	model:SetAttribute("Seed", math.random() * 10) -- (its own zigzag when it panics: ActiveRagdoll)
end
-- The engine gives a dynamic head with the face baked into its texture. Dummies need a face that
-- can change with their mood, so: plain head, no face animation rig, and a face drawn on a
-- SurfaceGui. (A Decal would follow the dynamic head's UV layout and land in the wrong place;
-- a SurfaceGui sits flat on the front of the head whatever the mesh.)
local function giveExpressiveFace(model: Model)
	local head = model:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
	if head:IsA("MeshPart") then
		head.TextureID = ""
	end
	for _, d in head:GetChildren() do
		if d:IsA("FaceControls") or d:IsA("Decal") then
			d:Destroy()
		end
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(256, 256)
	gui.LightInfluence = 1
	gui.MaxDistance = 220
	gui.ResetOnSpawn = false
	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = Assets.Faces.Neutral
	image.Parent = gui
	gui.Parent = head
end

-- A crash-test mark: a circle in four quarters, yellow and black by turns, with a black ring. A
-- yellow disc (its UIStroke is the ring) with two black quarters on it, each a square window (it
-- clips) onto a whole black circle, so the round edge stays round without an uploaded image:
-- 11 GUI objects a mark, 3 marks a dummy (both sides of the head and the chest).
local MARK_FACES = {
	{ part = "Head", face = Enum.NormalId.Left, size = 0.62 },
	{ part = "Head", face = Enum.NormalId.Right, size = 0.62 },
	{ part = "UpperTorso", face = Enum.NormalId.Front, size = 0.42, y = -0.1 },
}
local MARK_DISTANCE = 120 -- studs: further away the marks are not drawn
local INK = Color3.fromRGB(20, 20, 22)

local function round(frame: Frame)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
end

local function mark(parent: Instance, size: number, y: number)
	local disc = Instance.new("Frame")
	disc.Name = "Mark"
	disc.AnchorPoint = Vector2.new(0.5, 0.5)
	disc.Position = UDim2.fromScale(0.5, 0.5 + y)
	disc.Size = UDim2.fromScale(size, size)
	disc.BackgroundColor3 = YELLOW
	disc.BorderSizePixel = 0
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = disc
	round(disc)
	local ring = Instance.new("UIStroke")
	ring.Color = INK
	ring.Thickness = 5
	ring.Parent = disc
	for _, q in { 0, 1 } do -- (top left and bottom right)
		local window = Instance.new("Frame")
		window.Name = "Quarter"
		window.Size = UDim2.fromScale(0.5, 0.5)
		window.Position = UDim2.fromScale(q * 0.5, q * 0.5)
		window.BackgroundTransparency = 1
		window.ClipsDescendants = true
		local black = Instance.new("Frame")
		black.Size = UDim2.fromScale(2, 2)
		black.Position = UDim2.fromScale(-q, -q)
		black.BackgroundColor3 = INK
		black.BorderSizePixel = 0
		round(black)
		black.Parent = window
		window.Parent = disc
	end
	disc.Parent = parent
end

local function giveMarks(model: Model)
	for _, spec in MARK_FACES do
		local part = model:FindFirstChild(spec.part)
		if part and part:IsA("BasePart") then
			local gui = Instance.new("SurfaceGui")
			gui.Name = "CrashMark"
			gui.Face = spec.face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			gui.CanvasSize = Vector2.new(128, 128)
			gui.LightInfluence = 1
			gui.MaxDistance = MARK_DISTANCE
			gui.ResetOnSpawn = false
			mark(gui, spec.size, spec.y or 0)
			gui.Parent = part
		end
	end
end

-- Takes the crash-test marks off, and the mannequin's joint balls and shiny shell (a person in the
-- crowd wears clothes and skin instead).
function DummyFactory.removeMarks(model: Model)
	model:SetAttribute("Mannequin", false) -- (no mannequin skin: a person, under clothes)
	for _, d in model:GetDescendants() do
		if d:IsA("SurfaceGui") and d.Name == "CrashMark" then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Reflectance = 0
		end
	end
end

-- World/Feel v2 (Config.WORLD_V2): every dummy a test suit (the torso in one of the lab's colours,
-- by turns, never green: green is dead) and a big test number on its back, so a row reads as six
-- different test subjects. Named CrashMark: the crowd takes it off with the other marks. The
-- colour is the parts' own, so the sculpted skins wear it (DummySkins) and the dead green gives it
-- back (VitalsService.paintDead).
DummyFactory.SUITS = table.freeze({
	Color3.fromRGB(236, 128, 44), -- safety orange
	Color3.fromRGB(62, 132, 222), -- lab blue
	Color3.fromRGB(234, 190, 46), -- crash yellow
	Color3.fromRGB(222, 225, 232), -- test white
	DummyFactory.SHELL, -- plain grey
})
local suitTurn = 0
local function suit(model: Model)
	suitTurn += 1
	local color = DummyFactory.SUITS[(suitTurn - 1) % #DummyFactory.SUITS + 1]
	for _, name in { "UpperTorso", "LowerTorso" } do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Color = color
		end
	end
	local back = model:FindFirstChild("UpperTorso")
	if back and back:IsA("BasePart") then
		local gui = Instance.new("SurfaceGui")
		gui.Name = "CrashMark"
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = Vector2.new(128, 128)
		gui.LightInfluence = 1
		gui.MaxDistance = MARK_DISTANCE
		gui.ResetOnSpawn = false
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(0.8, 0.6)
		label.Position = UDim2.fromScale(0.1, 0.15)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = INK
		label.Text = string.format("%02d", (suitTurn - 1) % 99 + 1)
		label.Parent = gui
		gui.Parent = back
	end
end

local function container(): Folder
	local f = Workspace:FindFirstChild("Dummies")
	if f and f:IsA("Folder") then
		return f
	end
	local new = Instance.new("Folder")
	new.Name = "Dummies"
	new.Parent = Workspace
	return new
end

-- Places a dummy so its feet stand on the ground below `at`, facing `lookAt` if given.
-- owner: the player whose client simulates it (nil = the server simulates it).
-- lift: studs above the ground (a dummy that drops in from the sky), placed before it is handed over.
DummyFactory.onSpawn = nil :: ((Model) -> ())?

function DummyFactory.spawn(at: Vector3, lookAt: Vector3?, owner: Player?, lift: number?): Model
	local model = Players:CreateHumanoidModelFromDescription(description(), Enum.HumanoidRigType.R15)
	model.Name = "Dummy"
	model:SetAttribute("IsDummy", true)
	-- Lighter (round 3, M1, no lag): what a ragdoll dummy never uses goes before it is sent to every
	-- client: the walking avatar's Animate script and its animation values, the rig's scaling
	-- leftovers (a dummy is never rescaled) and layered-clothing wrap targets (it wears none).
	-- About 130 of a dummy's 320 instances.
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutomaticScalingEnabled = false
	end
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	for _, d in model:GetDescendants() do
		if (d:IsA("Vector3Value") and (d.Name == "OriginalSize" or d.Name == "OriginalPosition")) or d:IsA("WrapTarget") then
			d:Destroy()
		end
	end
	giveExpressiveFace(model)
	if not Config.LOOK_V3 then
		giveMarks(model) -- (LOOK_V3: a plain mannequin, no crash-test marks)
	end
	segment(model)
	fitV6(model)
	if Config.WORLD_V2 then
		suit(model)
	end

	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	-- The root is an invisible box inside the torso that the ragdoll leaves behind. Clicks, grabs and
	-- props must land on the body you can see, never on it.
	root.CanQuery = false
	root.CanTouch = false
	local lowest = math.huge
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "LeftFoot" or d.Name == "RightFoot") then
			lowest = math.min(lowest, d.Position.Y - d.Size.Y / 2)
		end
	end
	local rootAboveFeet = root.Position.Y - lowest

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { container() }
	local hit = Workspace:Raycast(at + Vector3.new(0, 20, 0), Vector3.new(0, -200, 0), params)
	local groundY = if hit then hit.Position.Y else at.Y

	local position = Vector3.new(at.X, groundY + rootAboveFeet + 0.05 + (lift or 0), at.Z)
	local facing = if lookAt then Vector3.new(lookAt.X, position.Y, lookAt.Z) else position + Vector3.zAxis
	model:PivotTo(CFrame.lookAt(position, facing))
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = container()
	-- Dressed for the season (ChristmasService) before it is set up and handed to whoever
	-- simulates it: what is welded on now is part of the body from the start.
	local hook = DummyFactory.onSpawn
	if hook then
		pcall(hook, model)
	end

	-- Static setup must happen after parenting: the Humanoid resets limb collisions on parent.
	local ok, err = ActiveRagdoll.prepare(model)
	if not ok then
		warn("[DummyFactory] prepare failed:", err)
	end
	DummyControl.register(model, owner)
	return model
end

return DummyFactory
