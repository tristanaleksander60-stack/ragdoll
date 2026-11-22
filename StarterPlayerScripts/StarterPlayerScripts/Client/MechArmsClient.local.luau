--!strict
-- MechArmsClient (23 Nov 2026, owner: "mechanical arms on your back that pull ragdolls apart"; then "the arms do not
-- move; you must tear the piece off yourself, not just press on it: the best mechanics of the top games").
-- Moves every MechArms set this screen sees (Server/MechArms builds them on Motor6D joints; the joints' C0 is set
-- here on every screen, from the C0 they were built with, since a character's Animator resets Transform): a slow
-- idle sway, and a pair of arms reaching out when a set tears ("Reach" from the server).
-- Tearing, your own: HOLD Q with the mouse on a ragdoll's arm, leg, head or body: a claw grabs that piece. Then
-- PULL: drag the mouse away (or walk back); the piece is dragged towards the claw (in your own lab the bodies are
-- yours to move), a red bar fills with the strain, the screen shakes a little, and when it is full the piece rips
-- off (the server checks and cuts it). Let go of Q and the claw lets go. Touch: hold TEAR to grab the nearest body's
-- next piece and keep holding to rip it. Pad: hold L1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("MechArms") or ReplicatedStorage:FindFirstChild("MechArms") or remotes:WaitForChild("MechArms", 60)
if not (remote and remote:IsA("RemoteEvent")) then
	return
end

local REACH = 16
local REACH_TIME = 0.55
local BEND = { math.rad(70), math.rad(70), math.rad(40), math.rad(40) }
local STRAIN_NEED = 1 -- the bar
local STRAIN_START = 1.2 -- studs of stretch before it counts
local STRAIN_RATE = 0.55 -- bar per second per stud of stretch past STRAIN_START
local TOUCH_RATE = 0.8 -- bar per second while TEAR is held on touch

type Reach = { point: Vector3, t0: number, pair: number, hold: boolean? }
local reaches: { [Player]: Reach } = {}
local turn: { [Player]: number } = {}
local baseC0: { [Motor6D]: CFrame } = setmetatable({}, { __mode = "k" }) :: any

remote.OnClientEvent:Connect(function(kind: unknown, who: unknown, point: unknown)
	if kind == "Reach" and typeof(who) == "Instance" and (who :: Instance):IsA("Player") and typeof(point) == "Vector3" then
		local p = who :: Player
		if p == player then
			return -- (your own arms already reach while you hold)
		end
		turn[p] = ((turn[p] or 0) % 2) + 1
		reaches[p] = { point = point :: Vector3, t0 = os.clock(), pair = turn[p] }
	end
end)

local function setJoint(m: Motor6D, offset: CFrame)
	local base = baseC0[m]
	if not base then
		base = m.C0
		baseC0[m] = base
	end
	m.C0 = (base :: CFrame) * offset
end

-- The grab (your own).
type Grab = { model: Model, part: BasePart, piece: string, depth: number, strain: number, align: AlignPosition?, at: Attachment?, touch: boolean, t0: number }
local grab: Grab? = nil

local function clawPoint(): Vector3?
	local g = grab
	local camera = Workspace.CurrentCamera
	if not (g and camera) then
		return nil
	end
	if g.touch then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 3, 0)
		end
		return nil
	end
	local m = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(m.X, m.Y)
	return ray.Origin + ray.Direction * g.depth
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local set = character and character:FindFirstChild("MechArms")
		local pack = set and set:FindFirstChild("Pack")
		if not (set and pack and pack:IsA("BasePart")) then
			continue
		end
		local r = reaches[p]
		local k = 0
		if p == player and grab then
			local point = clawPoint()
			r = if point then { point = point, t0 = t, pair = 1, hold = true } else nil
			k = 1
		elseif r then
			local a = (t - r.t0) / REACH_TIME
			if a >= 1 then
				reaches[p] = nil
				r = nil
			else
				k = math.sin(a * math.pi)
			end
		end
		for i = 1, 4 do
			local sh = pack:FindFirstChild("Shoulder" .. i)
			local upper = set:FindFirstChild("Upper" .. i)
			local el = upper and upper:FindFirstChild("Elbow" .. i)
			if not (sh and sh:IsA("Motor6D") and el and el:IsA("Motor6D")) then
				continue
			end
			local idle = CFrame.Angles(math.sin(t * 1.3 + i) * 0.14, 0, math.cos(t * 1.1 + i * 1.7) * 0.12)
			local idleEl = CFrame.Angles(math.sin(t * 1.7 + i * 2) * 0.18, 0, 0)
			local reachThis = r ~= nil and ((r.pair == 1 and i <= 2) or (r.pair == 2 and i > 2))
			if reachThis and r then
				local base = baseC0[sh] or sh.C0
				baseC0[sh] = base
				local frame = pack.CFrame * base
				local d = frame:VectorToObjectSpace(r.point - frame.Position)
				if d.Magnitude > 0.1 then
					local aim = CFrame.fromRotationBetweenVectors(Vector3.new(0, -1, 0), d.Unit)
					setJoint(sh, idle:Lerp(aim, k))
					setJoint(el, idleEl:Lerp(CFrame.Angles(-BEND[i], 0, 0), k))
				end
			else
				setJoint(sh, idle)
				setJoint(el, idleEl)
			end
		end
	end
end)

local function wearing(): boolean
	return player:GetAttribute("MechArms") == true
end

local function dummyOf(inst: Instance?): Model?
	local node = inst
	while node and node ~= Workspace do
		if node:IsA("Model") and node:GetAttribute("IsDummy") == true then
			return node
		end
		node = node.Parent
	end
	return nil
end

local PIECE_OF = {
	Head = "Head", UpperTorso = "Waist", LowerTorso = "Waist",
	LeftUpperArm = "LeftArm", LeftLowerArm = "LeftArm", LeftHand = "LeftArm",
	RightUpperArm = "RightArm", RightLowerArm = "RightArm", RightHand = "RightArm",
	LeftUpperLeg = "LeftLeg", LeftLowerLeg = "LeftLeg", LeftFoot = "LeftLeg",
	RightUpperLeg = "RightLeg", RightLowerLeg = "RightLeg", RightFoot = "RightLeg",
} :: { [string]: string }
local GRIP_PART = { Head = "Head", Waist = "UpperTorso", LeftArm = "LeftLowerArm", RightArm = "RightLowerArm", LeftLeg = "LeftLowerLeg", RightLeg = "RightLowerLeg" } :: { [string]: string }

local function severed(model: Model, piece: string): boolean
	local raw = model:GetAttribute("Severed")
	return type(raw) == "string" and string.find("," .. raw .. ",", "," .. piece .. ",", 1, true) ~= nil
end

-- The body part of `model` nearest `point` that can still come off, and its piece.
local function pieceAt(model: Model, point: Vector3): (BasePart?, string?)
	local best, bestD, bestPiece = nil :: BasePart?, math.huge, nil :: string?
	for name, piece in PIECE_OF do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") and not severed(model, piece) then
			local d = (part.Position - point).Magnitude
			if d < bestD then
				best, bestD, bestPiece = part, d, piece
			end
		end
	end
	return best, bestPiece
end

local function rootPos(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- The bar by the cursor.
local gui = Instance.new("ScreenGui")
gui.Name = "MechArmsHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.Enabled = false
gui.IgnoreGuiInset = true
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local bar = Instance.new("Frame")
bar.Name = "Strain"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Size = UDim2.fromOffset(120, 14)
bar.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
bar.BackgroundTransparency = 0.2
bar.Visible = false
bar.Parent = gui
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = bar
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
fill.Parent = bar
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill
local barWord = Instance.new("TextLabel")
barWord.BackgroundTransparency = 1
barWord.Size = UDim2.new(1, 0, 0, 18)
barWord.Position = UDim2.fromOffset(0, -20)
barWord.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
barWord.TextScaled = true
barWord.TextColor3 = Color3.new(1, 1, 1)
barWord.TextStrokeTransparency = 0.4
barWord.Text = "PULL!"
barWord.Parent = bar
local hint = Instance.new("TextButton")
hint.AnchorPoint = Vector2.new(1, 1)
hint.Position = if touch then UDim2.new(1, -200, 1, -150) else UDim2.new(0.5, 130, 1, -118)
hint.Size = if touch then UDim2.fromOffset(84, 84) else UDim2.fromOffset(190, 34)
hint.BackgroundColor3 = Color3.fromRGB(46, 48, 54)
hint.BackgroundTransparency = 0.15
hint.TextColor3 = Color3.new(1, 1, 1)
hint.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
hint.TextScaled = true
hint.AutoButtonColor = touch
hint.Active = touch
hint.Text = if touch then "TEAR" else "Hold [Q] on a limb, pull"
hint.Parent = gui
local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, if touch then 42 else 10)
hintCorner.Parent = hint
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(235, 120, 30)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = hint
gui.Parent = player:WaitForChild("PlayerGui")

local function release()
	local g = grab
	grab = nil
	bar.Visible = false
	if g then
		if g.align then
			g.align:Destroy()
		end
		if g.at then
			g.at:Destroy()
		end
	end
end

local function startGrab(useTouch: boolean)
	if grab or not wearing() then
		return
	end
	local here = rootPos()
	local camera = Workspace.CurrentCamera
	if not (here and camera) then
		return
	end
	local model: Model? = nil
	local hitPoint: Vector3? = nil
	if not useTouch then
		local m = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(m.X, m.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character :: Instance }
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
		model = if hit then dummyOf(hit.Instance) else nil
		hitPoint = if hit then hit.Position else nil
	end
	if not model then
		-- (Touch, or the mouse just off a body: the nearest one in reach.)
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character :: Instance }
		local bestD = math.huge
		for _, part in Workspace:GetPartBoundsInRadius(here, REACH, params) do
			local m = dummyOf(part)
			local mp = m and m:FindFirstChild("LowerTorso")
			if m and mp and mp:IsA("BasePart") then
				local d = (mp.Position - here).Magnitude
				if d < bestD then
					model, bestD, hitPoint = m, d, mp.Position
				end
			end
		end
	end
	if not (model and hitPoint) then
		return
	end
	local body = model :: Model
	local pelvis = body:FindFirstChild("LowerTorso")
	if not (pelvis and pelvis:IsA("BasePart")) or (pelvis.Position - here).Magnitude > REACH or body:GetAttribute("InMachine") ~= nil then
		return
	end
	local _, piece = pieceAt(body, hitPoint :: Vector3)
	if useTouch then
		for _, name in { "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Head", "Waist" } do
			if not severed(body, name) then
				piece = name
				break
			end
		end
	end
	if not piece then
		return
	end
	local grip = body:FindFirstChild(GRIP_PART[piece :: string])
	if not (grip and grip:IsA("BasePart")) then
		return
	end
	-- The tug: pulls the piece towards the claw (works on bodies this screen moves: your own lab's).
	local at = Instance.new("Attachment")
	at.Name = "MechGrip"
	at.Parent = grip
	local align = Instance.new("AlignPosition")
	align.Name = "MechTug"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = at
	align.MaxForce = 2500
	align.Responsiveness = 18
	align.Position = grip.Position
	align.Parent = grip
	grab = {
		model = body,
		part = grip,
		piece = piece :: string,
		depth = (grip.Position - camera.CFrame.Position).Magnitude,
		strain = 0,
		align = align,
		at = at,
		touch = useTouch,
		t0 = os.clock(),
	}
	bar.Visible = true
	fill.Size = UDim2.fromScale(0, 1)
end

RunService.Heartbeat:Connect(function(dt)
	local g = grab
	if not g then
		return
	end
	local here = rootPos()
	if not g.model.Parent or not g.part.Parent or severed(g.model, g.piece) or not here or not wearing()
		or (g.part.Position - here).Magnitude > REACH + 10 then
		release()
		return
	end
	local claw = clawPoint()
	if not claw then
		return
	end
	if g.align then
		(g.align :: AlignPosition).Position = claw
	end
	local stretch = (claw - g.part.Position).Magnitude
	local rate = if g.touch then TOUCH_RATE else math.max(0, stretch - STRAIN_START) * STRAIN_RATE
	g.strain = math.min(STRAIN_NEED, g.strain + rate * dt)
	fill.Size = UDim2.fromScale(g.strain / STRAIN_NEED, 1)
	local mouse = UserInputService:GetMouseLocation()
	bar.Position = if g.touch then UDim2.new(0.5, 0, 0.6, 0) else UDim2.fromOffset(mouse.X, mouse.Y + 22)
	barWord.Text = if g.strain > 0.75 then "RIP IT!" elseif rate > 0 then "PULL!" else "PULL AWAY!"
	-- A little shake on the claw while it strains.
	local camera = Workspace.CurrentCamera
	if camera and rate > 0 then
		camera.CFrame *= CFrame.Angles(0, 0, math.rad((math.random() - 0.5) * 0.6 * g.strain))
	end
	if g.strain >= STRAIN_NEED and os.clock() - g.t0 > 0.4 then
		remote:FireServer("Tear", g.model, g.piece)
		release()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1 then
		startGrab(false)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1 then
		if grab and not (grab :: Grab).touch then
			release()
		end
	end
end)
if touch then
	hint.MouseButton1Down:Connect(function()
		startGrab(true)
	end)
	hint.MouseButton1Up:Connect(release)
	hint.MouseLeave:Connect(function()
		if grab and (grab :: Grab).touch then
			release()
		end
	end)
end

local function refresh()
	gui.Enabled = wearing()
	if not wearing() then
		release()
	end
end
player:GetAttributeChangedSignal("MechArms"):Connect(refresh)
refresh()
