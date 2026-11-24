--!strict
-- MechArmsClient (23 Nov 2026, owner: "mechanical arms on your back that pull ragdolls apart"; then "you must tear it
-- off yourself"; then "the body must not move while you hold a limb, the arms rest behind you, you see the claw take
-- hold of the limb, then a few clicks tear it more and more and you see strands of flesh between the pieces; in
-- first person too").
-- Every screen: moves every MechArms set it sees (Server/MechArms builds them on Motor6D joints; the joints' C0 is
-- set here from the C0 they were built with, since a character's Animator resets Transform): resting behind the
-- back with a slow sway; a pair reaches out when a set tears ("Reach"); and when a piece comes off ("Torn") strands
-- of flesh stretch from the stump to the falling piece, thin out and snap.
-- Your own: Q (pad L1, touch TEAR) on a ragdoll's arm, leg, head or body: two arms shoot out and the claws take hold
-- of it (the server holds the body still). Keep holding and PULL the mouse away: the strain bar fills, blood spurts
-- and the wound opens wider, and when it is full the piece rips off. Your gun rests while you hold (player attribute MechGrab).
-- Your own arms stay drawn in first person.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
local HOLD_MAX = 10
local BLOOD = Color3.fromRGB(140, 14, 24)
local FLESH = Color3.fromRGB(160, 40, 52)

-- The pieces: the part the claws hold, the first part that comes off, the part it hangs on, and the joint.
local PIECES = {
	LeftArm = { grip = "LeftLowerArm", first = "LeftUpperArm", body = "UpperTorso", joint = "LeftShoulder" },
	RightArm = { grip = "RightLowerArm", first = "RightUpperArm", body = "UpperTorso", joint = "RightShoulder" },
	LeftLeg = { grip = "LeftLowerLeg", first = "LeftUpperLeg", body = "LowerTorso", joint = "LeftHip" },
	RightLeg = { grip = "RightLowerLeg", first = "RightUpperLeg", body = "LowerTorso", joint = "RightHip" },
	Head = { grip = "Head", first = "Head", body = "UpperTorso", joint = "Neck" },
	Waist = { grip = "UpperTorso", first = "UpperTorso", body = "LowerTorso", joint = "Waist" },
} :: { [string]: { grip: string, first: string, body: string, joint: string } }
local PIECE_OF = {
	Head = "Head", UpperTorso = "Waist", LowerTorso = "Waist",
	LeftUpperArm = "LeftArm", LeftLowerArm = "LeftArm", LeftHand = "LeftArm",
	RightUpperArm = "RightArm", RightLowerArm = "RightArm", RightHand = "RightArm",
	LeftUpperLeg = "LeftLeg", LeftLowerLeg = "LeftLeg", LeftFoot = "LeftLeg",
	RightUpperLeg = "RightLeg", RightLowerLeg = "RightLeg", RightFoot = "RightLeg",
} :: { [string]: string }

type Reach = { point: Vector3, t0: number, pair: number }
local reaches: { [Player]: Reach } = {}
local turn: { [Player]: number } = {}
-- (23 Nov 2026, owner: "the hands still stick out after Q"): each joint's built C0 is kept as an attribute on the
-- joint itself (BaseC0, set on this screen only). A weak-keyed table lost it now and then, and the next frame took
-- the bent C0 of a reach as the new rest, so the arms stayed out.
local function baseOf(m: Motor6D): CFrame
	local base = m:GetAttribute("BaseC0")
	if typeof(base) == "CFrame" then
		return base
	end
	m:SetAttribute("BaseC0", m.C0)
	return m.C0
end
local function setJoint(m: Motor6D, offset: CFrame)
	m.C0 = baseOf(m) * offset
end
local function straight(m: Motor6D): CFrame
	return baseOf(m).Rotation:Inverse()
end

-- Your grab.
type Grab = { model: Model, part: BasePart, piece: string, clicks: number, t0: number, kick: number, gash: Part? }
local grab: Grab? = nil

local function severed(model: Model, piece: string): boolean
	local raw = model:GetAttribute("Severed")
	return type(raw) == "string" and string.find("," .. raw .. ",", "," .. piece .. ",", 1, true) ~= nil
end

local function jointPoint(model: Model, piece: string): Vector3?
	local spec = PIECES[piece]
	local first = spec and model:FindFirstChild(spec.first)
	local socket = first and first:FindFirstChild(spec.joint .. "RigAttachment")
	return if socket and socket:IsA("Attachment") then socket.WorldPosition else nil
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
			local g = grab :: Grab
			-- (Holding: the claws on the piece; a wrench throws them back a little after each click.)
			local kick = math.max(0, g.kick - t)
			local pull = (g.part.Position - pack.Position)
			local point = g.part.Position - (if pull.Magnitude > 0.1 then pull.Unit else Vector3.zero) * kick * 3
			r = { point = point, t0 = t, pair = 1 }
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
			local idle = CFrame.Angles(math.sin(t * 1.3 + i) * 0.1, 0, math.cos(t * 1.1 + i * 1.7) * 0.08)
			local idleEl = CFrame.Angles(math.sin(t * 1.7 + i * 2) * 0.12, 0, 0)
			local reachThis = r ~= nil and ((r.pair == 1 and i <= 2) or (r.pair == 2 and i > 2))
			if reachThis and r then
				local base = baseOf(sh)
				local frame = pack.CFrame * base
				local d = frame:VectorToObjectSpace(r.point - frame.Position)
				if d.Magnitude > 0.1 then
					-- (`d` is already in the shoulder's rest frame: turn its -Y onto it.)
					local aim = CFrame.fromRotationBetweenVectors(Vector3.new(0, -1, 0), d.Unit)
					setJoint(sh, idle:Lerp(aim, k))
					setJoint(el, idleEl:Lerp(straight(el), k))
				end
			else
				setJoint(sh, idle)
				setJoint(el, idleEl)
			end
		end
		-- (First person hides your character; your own arms stay drawn.)
		if p == player then
			for _, d in set:GetDescendants() do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = 0
				end
			end
		end
	end
	-- The gash at the joint follows it.
	local g = grab
	if g and g.gash then
		local at = jointPoint(g.model, g.piece)
		if at then
			(g.gash :: Part).Position = at
		end
	end
end)

remote.OnClientEvent:Connect(function(kind: unknown, a: unknown, b: unknown)
	if kind == "Reach" and typeof(a) == "Instance" and (a :: Instance):IsA("Player") and typeof(b) == "Vector3" then
		local p = a :: Player
		if p == player then
			return
		end
		turn[p] = ((turn[p] or 0) % 2) + 1
		reaches[p] = { point = b :: Vector3, t0 = os.clock(), pair = turn[p] }
	elseif kind == "Torn" and typeof(a) == "Instance" and (a :: Instance):IsA("Model") and type(b) == "string" then
		-- Strands of flesh from the stump to the piece: they stretch as it falls, thin out and snap.
		local model = a :: Model
		local spec = PIECES[b :: string]
		local first = spec and model:FindFirstChild(spec.first)
		local body = spec and model:FindFirstChild(spec.body)
		local socket = first and first:FindFirstChild(spec.joint .. "RigAttachment")
		local bodySocket = body and body:FindFirstChild(spec.joint .. "RigAttachment")
		if not (first and body and socket and bodySocket and socket:IsA("Attachment") and bodySocket:IsA("Attachment")) then
			return
		end
		local rng = Random.new()
		local made: { Instance } = {}
		local beams: { Beam } = {}
		for _ = 1, 6 do
			local off = Vector3.new(rng:NextNumber(-0.25, 0.25), rng:NextNumber(-0.25, 0.25), rng:NextNumber(-0.25, 0.25))
			local a0 = Instance.new("Attachment")
			a0.Position = socket.Position + off
			a0.Parent = first
			local a1 = Instance.new("Attachment")
			a1.Position = bodySocket.Position + off * 0.8
			a1.Parent = body
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Color = ColorSequence.new(FLESH, BLOOD)
			beam.Width0 = rng:NextNumber(0.06, 0.14)
			beam.Width1 = rng:NextNumber(0.05, 0.12)
			beam.FaceCamera = true
			beam.Segments = 8
			beam.CurveSize0 = rng:NextNumber(-0.6, 0.6)
			beam.CurveSize1 = rng:NextNumber(-0.6, 0.6)
			beam.LightInfluence = 1
			beam.Transparency = NumberSequence.new(0)
			beam.Parent = a0
			table.insert(made, a0)
			table.insert(made, a1)
			table.insert(beams, beam)
		end
		task.spawn(function()
			local t0 = os.clock()
			local life = 1.8
			while os.clock() - t0 < life do
				local f = (os.clock() - t0) / life
				for i, beam in beams do
					if beam.Parent then
						-- (One by one they snap; the rest thin out.)
						if f > 0.25 + i * 0.1 then
							beam.Enabled = false
						else
							beam.Width0 *= 0.985
							beam.Width1 *= 0.985
						end
					end
				end
				task.wait()
			end
			for _, inst in made do
				inst:Destroy()
			end
		end)
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

local function pieceAt(model: Model, point: Vector3): string?
	local bestD, bestPiece = math.huge, nil :: string?
	for name, piece in PIECE_OF do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") and not severed(model, piece) then
			local d = (part.Position - point).Magnitude
			if d < bestD then
				bestD, bestPiece = d, piece
			end
		end
	end
	return bestPiece
end

local function rootPos(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- The HUD: a hint, and the strain bar while you pull.
local gui = Instance.new("ScreenGui")
gui.Name = "MechArmsHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.Enabled = false
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local hint = Instance.new("TextButton")
-- (23 Nov 2026, owner: "move Hold Q up under the next weapon"): on a keyboard a pill under the top bar's Next pill.
hint.AnchorPoint = if touch then Vector2.new(1, 1) else Vector2.new(0.5, 0)
hint.Position = if touch then UDim2.new(1, -200, 1, -150) else UDim2.new(0.5, 0, 0, 62)
hint.Size = if touch then UDim2.fromOffset(84, 84) else UDim2.fromOffset(0, 30)
if not touch then
	hint.AutomaticSize = Enum.AutomaticSize.X
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = hint
end
hint.BackgroundColor3 = Color3.fromRGB(46, 48, 54)
hint.BackgroundTransparency = 0.15
hint.TextColor3 = Color3.new(1, 1, 1)
hint.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
hint.TextScaled = touch
hint.TextSize = 17
hint.AutoButtonColor = touch
hint.Active = touch
hint.Parent = gui
local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, if touch then 42 else 10)
hintCorner.Parent = hint
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(235, 120, 30)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = hint
if touch then
	local off = hint:Clone()
	off.Name = "TakeOff"
	off.Position = UDim2.new(1, -290, 1, -190)
	off.Size = UDim2.fromOffset(46, 46)
	off.Text = "OFF"
	off.Parent = gui
	off.Activated:Connect(function()
		remote:FireServer("TakeOff")
	end)
end
gui.Parent = player:WaitForChild("PlayerGui")

local function drawHint()
	local g = grab
	if g then
		hint.Text = if touch then "PULL!" else "PULL the mouse away!"
		stroke.Color = Color3.fromRGB(220, 40, 40)
	else
		hint.Text = if touch then "HOLD: RIP" else "Hold [Q] on a limb  \u{00B7}  [X] take off"
		stroke.Color = Color3.fromRGB(235, 120, 30)
	end
end

local function release(tell: boolean)
	local g = grab
	grab = nil
	player:SetAttribute("MechGrab", nil)
	if g then
		if g.gash then
			local gash = g.gash :: Part
			TweenService:Create(gash, TweenInfo.new(1.2), { Transparency = 1 }):Play()
			game:GetService("Debris"):AddItem(gash, 1.3)
		end
		if tell then
			remote:FireServer("Let", g.model)
		end
	end
	drawHint()
end

local function burst(at: Vector3, n: number)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one * 0.2
	p.Position = at
	p.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(BLOOD)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0.1) })
	e.Speed = NumberRange.new(6, 14)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Acceleration = Vector3.new(0, -45, 0)
	e.Rate = 0
	e.Parent = p
	e:Emit(n)
	game:GetService("Debris"):AddItem(p, 1.5)
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
	local piece = pieceAt(body, hitPoint :: Vector3)
	if useTouch then
		for _, name in { "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Head", "Waist" } do
			if not severed(body, name) then
				piece = name
				break
			end
		end
	end
	local spec = piece and PIECES[piece]
	local grip = spec and body:FindFirstChild(spec.grip)
	if not (piece and grip and grip:IsA("BasePart")) then
		return
	end
	remote:FireServer("Grab", body)
	player:SetAttribute("MechGrab", true)
	grab = { model = body, part = grip, piece = piece, clicks = 0, t0 = os.clock(), kick = 0, gash = nil }
	drawHint()
end

-- (23 Nov 2026, owner: "remove the clicking, you must rip it off again"): HOLD Q on a limb, then PULL: drag the mouse
-- away from it (on touch: keep holding TEAR). The body stands still; the strain builds with how far you pull, the
-- wound at the joint opens, blood spurts harder, and when the bar is full the piece rips off. Let go of Q to stop.
local STRAIN_START = 0.7 -- studs of pull before it counts
local STRAIN_RATE = 1.3 -- bar a second per stud past that
local TOUCH_RATE = 1.2
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
local depth = 0
local nextSpurt = 0
local touchGrab = false

local function clawPoint(g: Grab): Vector3
	local camera = Workspace.CurrentCamera
	if touchGrab or not camera then
		return g.part.Position + Vector3.new(0, 3, 0)
	end
	local m = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(m.X, m.Y)
	return ray.Origin + ray.Direction * depth
end

RunService.Heartbeat:Connect(function(dt)
	local g = grab
	if not g then
		bar.Visible = false
		return
	end
	local here = rootPos()
	if not g.model.Parent or not g.part.Parent or severed(g.model, g.piece) or not here or not wearing()
		or (g.part.Position - here).Magnitude > REACH + 6 or os.clock() - g.t0 > HOLD_MAX then
		release(true)
		return
	end
	local claw = clawPoint(g)
	local stretch = (claw - g.part.Position).Magnitude
	local rate = if touchGrab then TOUCH_RATE else math.max(0, stretch - STRAIN_START) * STRAIN_RATE
	g.clicks = math.min(1, g.clicks + rate * dt) -- (the strain, 0..1)
	local strain = g.clicks
	bar.Visible = true
	fill.Size = UDim2.fromScale(strain, 1)
	local mouse = UserInputService:GetMouseLocation()
	bar.Position = if touchGrab then UDim2.new(0.5, 0, 0.6, 0) else UDim2.fromOffset(mouse.X, mouse.Y + 22)
	if rate > 0 then
		g.kick = os.clock() + 0.05 -- (the claws tug)
		local at = jointPoint(g.model, g.piece) or g.part.Position
		if os.clock() >= nextSpurt then
			nextSpurt = os.clock() + 0.3 - strain * 0.18
			burst(at, 4 + math.floor(strain * 14))
		end
		local gash = g.gash
		if not gash then
			local made = Instance.new("Part")
			made.Name = "MechGash"
			made.Shape = Enum.PartType.Ball
			made.Anchored, made.CanCollide, made.CanQuery, made.CanTouch, made.CastShadow = true, false, false, false, false
			made.Color = FLESH
			made.Material = Enum.Material.SmoothPlastic
			made.Position = at
			made.Size = Vector3.one * 0.2
			made.Parent = Workspace
			g.gash = made
			gash = made
		end
		local gp = gash :: Part
		gp.Size = Vector3.one * (0.2 + strain * 0.65)
		gp.Color = FLESH:Lerp(BLOOD, strain)
		local camera = Workspace.CurrentCamera
		if camera then
			camera.CFrame *= CFrame.Angles(0, 0, math.rad((math.random() - 0.5) * 0.5 * strain))
		end
	end
	if strain >= 1 and os.clock() - g.t0 > 0.4 then
		remote:FireServer("Tear", g.model, g.piece)
		release(false)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	-- (23 Nov 2026, owner: "press X to take the arms off again"): the server takes them off (HudPlus skips revive-all).
	if input.KeyCode == Enum.KeyCode.X and wearing() then
		if grab then
			release(true)
		end
		remote:FireServer("TakeOff")
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1 then
		touchGrab = false
		startGrab(false)
		local g = grab
		local camera = Workspace.CurrentCamera
		if g and camera then
			depth = (g.part.Position - camera.CFrame.Position).Magnitude
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1) and grab and not touchGrab then
		release(true)
	end
end)
if touch then
	hint.MouseButton1Down:Connect(function()
		touchGrab = true
		startGrab(true)
	end)
	hint.MouseButton1Up:Connect(function()
		if grab and touchGrab then
			release(true)
		end
	end)
end

local function refresh()
	gui.Enabled = wearing()
	if not wearing() and grab then
		release(true)
	end
	drawHint()
end
player:GetAttributeChangedSignal("MechArms"):Connect(refresh)
refresh()
