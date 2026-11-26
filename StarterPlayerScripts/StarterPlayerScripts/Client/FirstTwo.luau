--!strict
-- FIRST_2_MIN (owner, 26 Nov 2026: "Man skal bare kunne trykke TRY når man er derhenne og så kommer der en ragdoll
-- første gang, og så skal man grab den og putte den i maskinen"; docs/FIRST_2_MIN.md, Config.FIRST_TWO).
--   - The next machine you have not tried is picked once and kept until you try it (no flipping): the goal line
--     says "Try CANNON 0/6" and a faint guide line (a Beam on the floor side) leads there.
--   - Within NEAR studs of an untried machine: a big round TRY button (touch: right side above SHOOT; keyboard E;
--     gamepad X) and a soft orange outline on the machine.
--   - TRY: the server sends the nearest free ragdoll running to you (Lab.callTo, TryFor = you).
--   - The first time (a newcomer): a hand and "Hold to GRAB" over that ragdoll, then, once you hold it, the
--     machine glows with "Put it in!". The machine counts as tried when it runs (ExperimentService Tried_<kind>),
--     with a "+25 BOLTS 1/6" pop. Later machines: no hints.
--   - While a TRY runs the player attribute TryBusy is set (local), so the minute moments wait.
-- Replaces the floating TRY! ring and sign (Config.TRY_ME off).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any

local FirstTwo = {}

FirstTwo.NEAR = 12 -- studs from the machine's box: the TRY button shows
FirstTwo.GUIDE_FROM = 20 -- studs: the guide line shows only when further than this
FirstTwo.LESSON_WAIT = 45 -- s a lesson waits for the grab and the put before it lets go

local player = Players.LocalPlayer
local ORANGE = Color3.fromRGB(255, 140, 40)

local function showcase(): any
	return require(script.Parent:WaitForChild("LabShowcase")) :: any
end

local function tried(kind: string): boolean
	return player:GetAttribute("Tried_" .. kind) == true
end

local function count(): string
	local reward = Config.TRY_REWARD
	if not reward or player:GetAttribute("TryRewardDone") == true then
		return ""
	end
	local n = player:GetAttribute("TriedCount")
	return string.format(" %d/%d", if type(n) == "number" then n else 0, reward.count)
end

local function root(): BasePart?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

local function seated(): boolean
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.SeatPart ~= nil
end

-- Distance from a point to an instance's box (0 inside it).
local function boxDistance(inst: Instance, p: Vector3): number
	local cf: CFrame, size: Vector3
	if inst:IsA("Model") then
		cf, size = inst:GetBoundingBox()
	elseif inst:IsA("BasePart") then
		cf, size = inst.CFrame, inst.Size
	else
		return math.huge
	end
	local l = cf:PointToObjectSpace(p)
	local h = size / 2
	local q = Vector3.new(math.clamp(l.X, -h.X, h.X), math.clamp(l.Y, -h.Y, h.Y), math.clamp(l.Z, -h.Z, h.Z))
	return (l - q).Magnitude
end

local function say(text: string)
	pcall(function()
		(require(script.Parent:WaitForChild("HudV3")) :: any).moment(text, 6)
	end)
end

local function session(kind: string, data: string)
	pcall(function()
		Net.event(Net.Names.Session):FireServer(kind, data)
	end)
end

-- A label over a part, with a pointing hand: the lesson's hints.
local function hint(adornee: Instance, text: string): BillboardGui
	local g = Instance.new("BillboardGui")
	g.Name = "FirstTwoHint"
	g.Size = UDim2.fromOffset(200, 70)
	g.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	g.AlwaysOnTop = true
	g.MaxDistance = 80
	g.LightInfluence = 0
	g.Adornee = adornee
	local hand = Instance.new("TextLabel")
	hand.BackgroundTransparency = 1
	hand.Size = UDim2.new(1, 0, 0.5, 0)
	hand.Text = "\u{1F447}"
	hand.TextScaled = true
	hand.Parent = g
	local word = Instance.new("TextLabel")
	word.BackgroundColor3 = ORANGE
	word.Position = UDim2.fromScale(0, 0.5)
	word.Size = UDim2.fromScale(1, 0.5)
	word.Font = Enum.Font.FredokaOne
	word.TextColor3 = Color3.new(1, 1, 1)
	word.TextScaled = true
	word.Text = text
	word.Parent = g
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = word
	g.Parent = player:WaitForChild("PlayerGui")
	return g
end

local function holding(): boolean
	local ok, yes = pcall(function()
		return (require(script.Parent:WaitForChild("GrabController")) :: any).isGrabbing()
	end)
	return ok and yes == true
end

-- The first-time lesson for one machine (runs in its own thread).
local lessonDone = false
local function lesson(kind: string, machine: Instance)
	local started = os.clock()
	-- The ragdoll the server sent (TryFor = me).
	local body: Model? = nil
	while os.clock() - started < 8 and not body do
		for _, d in (Workspace:FindFirstChild("Dummies") or Workspace):GetChildren() do
			if d:IsA("Model") and d:GetAttribute("TryFor") == player.UserId then
				body = d
				break
			end
		end
		task.wait(0.2)
	end
	local b = body
	if not b then
		return
	end
	local head = b:FindFirstChild("Head") or b.PrimaryPart
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local grabHint = if head then hint(head, if touch then "Hold to GRAB" else "Hold click to GRAB") else nil
	while os.clock() - started < FirstTwo.LESSON_WAIT and not holding() and not tried(kind) do
		task.wait(0.1)
	end
	if grabHint then
		grabHint:Destroy()
	end
	if tried(kind) or not holding() then
		return
	end
	session("TryStep", "Grabbed")
	local glow = Instance.new("Highlight")
	glow.Name = "FirstTwoLoad"
	glow.FillColor = ORANGE
	glow.FillTransparency = 0.55
	glow.OutlineColor = ORANGE
	glow.Adornee = machine
	glow.Parent = player:WaitForChild("PlayerGui")
	local anchor = if machine:IsA("Model") then machine.PrimaryPart or machine:FindFirstChildWhichIsA("BasePart", true) else machine
	local putHint = if anchor then hint(anchor, "Put it in!") else nil
	while os.clock() - started < FirstTwo.LESSON_WAIT and not tried(kind) do
		task.wait(0.2)
	end
	glow:Destroy()
	if putHint then
		putHint:Destroy()
	end
	if tried(kind) then
		lessonDone = true
		session("TryStep", "Put")
	end
end

function FirstTwo.start()
	if not Config.FIRST_TWO then
		return
	end
	-- The TRY button (touch: right side above SHOOT, big and round).
	local gui = Instance.new("ScreenGui")
	gui.Name = "FirstTwo"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Enabled = false
	local button = Instance.new("TextButton")
	button.Name = "Try"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -120, 1, -230)
	button.Size = UDim2.fromOffset(84, 84)
	button.BackgroundColor3 = ORANGE
	button.Font = Enum.Font.FredokaOne
	button.Text = "TRY"
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = button
	local edge = Instance.new("UIStroke")
	edge.Thickness = 4
	edge.Color = Color3.new(1, 1, 1)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = button
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.22, 0), UDim.new(0.22, 0)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.14, 0), UDim.new(0.14, 0)
	pad.Parent = button
	gui.Parent = player:WaitForChild("PlayerGui")

	local outline = Instance.new("Highlight")
	outline.Name = "FirstTwoOutline"
	outline.FillTransparency = 1
	outline.OutlineColor = ORANGE
	outline.DepthMode = Enum.HighlightDepthMode.Occluded

	-- The faint guide line from the player to the target machine.
	local anchorPart = Instance.new("Part")
	anchorPart.Name = "FirstTwoGuide"
	anchorPart.Anchored, anchorPart.CanCollide, anchorPart.CanQuery, anchorPart.CanTouch = true, false, false, false
	anchorPart.Transparency = 1
	anchorPart.Size = Vector3.one * 0.2
	local a1 = Instance.new("Attachment")
	a1.Parent = anchorPart
	local beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 210, 90))
	beam.Transparency = NumberSequence.new(0.55)
	beam.Width0, beam.Width1 = 0.5, 0.5
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Attachment1 = a1
	beam.Parent = anchorPart
	local a0: Attachment? = nil

	local target: any = nil -- the machine row being pointed at
	local targetInst: Instance? = nil
	local near: any = nil -- the untried machine within NEAR, if any
	local nearInst: Instance? = nil
	local busyUntil = 0

	local function press()
		local m, inst = near, nearInst
		if not m or not inst or os.clock() < busyUntil then
			return
		end
		busyUntil = os.clock() + 3
		session("Try", m.kind)
		player:SetAttribute("TryBusy", true)
		task.spawn(function()
			if not lessonDone and player:GetAttribute("Newcomer") == true then
				lesson(m.kind, inst)
			else
				task.wait(6)
			end
			player:SetAttribute("TryBusy", nil)
		end)
	end
	button.Activated:Connect(press)
	ContextActionService:BindAction("FirstTwoTry", function(_, state)
		if state == Enum.UserInputState.Begin and near then
			press()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

	local function pick(lab: Instance, r: BasePart): (any, Instance?)
		local S = showcase()
		local best, bestInst, bestD = nil, nil, math.huge
		for _, m in S.MACHINES do
			if m.kind and not tried(m.kind) then
				local inst = S.find(lab, m.path)
				if inst then
					local d = boxDistance(inst, r.Position)
					if d < bestD then
						best, bestInst, bestD = m, inst, d
					end
				end
			end
		end
		return best, bestInst
	end

	task.spawn(function()
		while true do
			task.wait(0.25)
			local r = root()
			local lab = showcase().myLab()
			if not r or not lab then
				gui.Enabled = false
				continue
			end
			-- The target: kept until it is tried (no flipping between two machines).
			if not target or tried(target.kind) or not targetInst or not targetInst.Parent then
				target, targetInst = pick(lab, r)
				if target then
					say("Try " .. (showcase().SHORT[target.label] or "IT") .. count())
					local pos = showcase().where(targetInst)
					if pos then
						-- (The machine's own floor, found once: the line never jumps with the player.)
						local params = RaycastParams.new()
						params.FilterType = Enum.RaycastFilterType.Exclude
						params.FilterDescendantsInstances = { player.Character :: Instance }
						local hit = Workspace:Raycast(pos + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), params)
						anchorPart.Position = (if hit then hit.Position else pos) + Vector3.new(0, 0.5, 0)
					end
				end
			end
			-- The guide line from the player's feet.
			if not a0 or a0.Parent ~= r then
				local made = Instance.new("Attachment")
				made.Name = "FirstTwoFrom"
				made.Position = Vector3.new(0, -2.5, 0)
				made.Parent = r
				a0 = made
				beam.Attachment0 = made
			end
			local far = target and targetInst and boxDistance(targetInst, r.Position) > FirstTwo.GUIDE_FROM
			anchorPart.Parent = if far and not seated() then Workspace else nil
			-- The TRY button at an untried machine.
			local m, inst = pick(lab, r)
			if m and inst and boxDistance(inst, r.Position) <= FirstTwo.NEAR and not seated() then
				near, nearInst = m, inst
				outline.Adornee = inst
				outline.Parent = player:WaitForChild("PlayerGui")
				gui.Enabled = true
			else
				near, nearInst = nil, nil
				outline.Parent = nil
				gui.Enabled = false
			end
		end
	end)
end

return FirstTwo
