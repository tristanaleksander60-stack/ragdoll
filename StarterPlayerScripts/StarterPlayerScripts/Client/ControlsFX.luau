--!strict
-- C10 (docs/CONTROLS_10.md; Config.CONTROLS_V2): the screen side of the control kit (Shared/Controls).
--   * ONE custom prompt for every control: a big round button (76 px, a tap target on phones) with the control's icon
--     and the action word under it, a ring that fills while a hold prompt is held; no key letters on touch screens.
--   * Instant feedback: the moment you press, YOUR screen moves it (a button sinks 0.15 studs with a squash, a lever
--     throws with a spring overshoot, a crank turns, a dial clicks round) with a chunky click; if the server refuses
--     (attribute Refused changes), it pops back with a short buzz.
--   * The state, in shape and light, for controls within 80 studs: READY a slow pulse of the cap's glow; COOLING the
--     collar ring fills up as it recharges (CoolFrom..CoolUntil); BUSY red; LOCKED grey.
-- Every movement is a local tween; the server moves no parts.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local ControlsFX = {}

ControlsFX.NEAR = 80
local CLICK = "rbxasset://sounds/switch.wav"
local BUZZ = "rbxasset://sounds/electronicpingshort.wav"

local player = Players.LocalPlayer
local rest: { [BasePart]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
local tracked: { [Model]: boolean } = {}

local function sound(at: BasePart, id: string, speed: number)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0.6
	s.PlaybackSpeed = speed
	s.RollOffMaxDistance = 60
	s.Parent = at
	s:Play()
	game:GetService("Debris"):AddItem(s, 2)
end

local function partsOf(model: Model, names: { [string]: boolean }): { BasePart }
	local out = {}
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and names[d.Name] then
			table.insert(out, d)
		end
	end
	return out
end

local function childPart(model: Model, name: string): BasePart?
	local c = model:FindFirstChild(name)
	return if c and c:IsA("BasePart") then c else nil
end

local function remember(p: BasePart): CFrame
	local r = rest[p]
	if not r then
		r = p.CFrame
		rest[p] = r
	end
	return r :: CFrame
end

-- the press, on this screen at once
local function press(model: Model)
	local kind = model:GetAttribute("Kind")
	local base = model.PrimaryPart
	if base then
		sound(base, CLICK, if kind == "Lever" then 0.7 else 1)
	end
	if kind == "Button" then
		for _, p in partsOf(model, { Cap = true, Collar = true, Ring = true }) do
			local r = remember(p)
			p.CFrame = r * CFrame.new(0, -0.15, 0)
			TweenService:Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = r }):Play()
		end
	elseif kind == "Lever" then
		local pivot = childPart(model, "Pivot")
		if pivot then
			for _, p in partsOf(model, { Handle = true, Cap = true }) do
				local r = remember(p)
				local rel = pivot.CFrame:ToObjectSpace(r)
				local thrown = pivot.CFrame * CFrame.Angles(0, 0, math.rad(50)) * rel
				TweenService:Create(p, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = thrown }):Play()
				task.delay(0.9, function()
					TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CFrame = r }):Play()
				end)
			end
		end
	elseif kind == "Crank" then
		local hub = childPart(model, "Hub")
		if hub then
			for _, p in partsOf(model, { Cap = true, Spoke = true, Grip = true }) do
				local r = remember(p)
				local rel = hub.CFrame:ToObjectSpace(r)
				local v = Instance.new("NumberValue")
				v.Changed:Connect(function(a: number)
					p.CFrame = hub.CFrame * CFrame.Angles(math.rad(a), 0, 0) * rel
				end)
				local tw = TweenService:Create(v, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { Value = 360 })
				tw.Completed:Connect(function()
					p.CFrame = r
					v:Destroy()
				end)
				tw:Play()
			end
		end
	elseif kind == "Dial" then
		local face = childPart(model, "Face")
		local pointer = childPart(model, "Pointer")
		if face and pointer then
			local r = remember(pointer)
			local step = ((model:GetAttribute("DialStep") :: number?) or 0) % 3
			local a = math.rad(-60 + step * 60)
			local rel = face.CFrame:ToObjectSpace(r)
			TweenService:Create(pointer, TweenInfo.new(0.2, Enum.EasingStyle.Back), { CFrame = face.CFrame * CFrame.Angles(a, 0, 0) * rel }):Play()
		end
	end
end

local function popBack(model: Model)
	local base = model.PrimaryPart
	if base then
		sound(base, BUZZ, 0.6)
	end
	for p, r in rest do
		if p:IsDescendantOf(model) then
			TweenService:Create(p, TweenInfo.new(0.15), { CFrame = r }):Play()
		end
	end
end

local function track(inst: Instance)
	if not inst:IsA("Model") or tracked[inst] then
		return
	end
	local model = inst :: Model
	tracked[model] = true
	local prompt = model:FindFirstChild("ControlPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(who: Player)
			if who == player then
				press(model)
			end
		end)
	end
	model:GetAttributeChangedSignal("Refused"):Connect(function()
		popBack(model)
	end)
	model.Destroying:Connect(function()
		tracked[model] = nil
	end)
end

-- the custom prompt: a big round icon button with the action word
local shown: { [ProximityPrompt]: BillboardGui } = {}
local function showPrompt(prompt: ProximityPrompt, input: Enum.ProximityPromptInputType)
	if prompt.Name ~= "ControlPrompt" or prompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return
	end
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "ControlPromptGui"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(110, 120)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.Adornee = prompt.Parent :: Instance
	gui.Active = true
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(76, 76)
	btn.Position = UDim2.new(0.5, -38, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(215, 30, 35)
	btn.Text = tostring(model:GetAttribute("Icon") or "!")
	btn.TextScaled = true
	btn.Font = Enum.Font.FredokaOne
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.AutoButtonColor = true
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = btn
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(255, 220, 70)
	stroke.Parent = btn
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = btn
	btn.Parent = gui
	local word = Instance.new("TextLabel")
	word.BackgroundTransparency = 1
	word.Position = UDim2.fromOffset(0, 80)
	word.Size = UDim2.new(1, 0, 0, 30)
	word.Font = Enum.Font.FredokaOne
	word.TextScaled = true
	word.TextColor3 = Color3.new(1, 1, 1)
	word.TextStrokeTransparency = 0.3
	local key = if input == Enum.ProximityPromptInputType.Keyboard then " [" .. prompt.KeyboardKeyCode.Name .. "]" else ""
	word.Text = string.upper(prompt.ActionText) .. key
	word.Parent = gui
	-- a tap (touch) or a click works the prompt by hand (a Custom prompt has no built-in button)
	btn.InputBegan:Connect(function(io: InputObject)
		if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end)
	btn.InputEnded:Connect(function(io: InputObject)
		if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
	shown[prompt] = gui
end

local function hidePrompt(prompt: ProximityPrompt)
	local g = shown[prompt]
	if g then
		g:Destroy()
		shown[prompt] = nil
	end
end

function ControlsFX.start()
	if not Config.CONTROLS_V2 then
		return
	end
	for _, m in CollectionService:GetTagged("Control") do
		track(m)
	end
	CollectionService:GetInstanceAddedSignal("Control"):Connect(track)
	ProximityPromptService.PromptShown:Connect(showPrompt)
	ProximityPromptService.PromptHidden:Connect(hidePrompt)
	-- the state, a few times a second, only near
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < 0.08 then
			return
		end
		acc = 0
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local now = Workspace:GetServerTimeNow()
		local t = os.clock()
		for model in tracked do
			local base = model.PrimaryPart
			if not base or (base.Position - cam.CFrame.Position).Magnitude > ControlsFX.NEAR then
				continue
			end
			local cap = childPart(model, "Cap")
			local ring = childPart(model, "Ring")
			local g0 = cap and cap:FindFirstChild("Glow")
			local glow = if g0 and g0:IsA("PointLight") then g0 else nil
			local locked = model:GetAttribute("Locked") == true
			local busy = model:GetAttribute("Busy") == true
			local cu, cf = model:GetAttribute("CoolUntil"), model:GetAttribute("CoolFrom")
			local cooling = type(cu) == "number" and now < cu
			if cap then
				cap.Color = if locked then Color3.fromRGB(130, 130, 134) elseif busy then Color3.fromRGB(255, 40, 30) elseif cooling then Color3.fromRGB(120, 30, 32) else Color3.fromRGB(215, 30, 35)
			end
			if glow then
				glow.Enabled = not locked
				glow.Brightness = if busy then 2 elseif cooling then 0.2 else 0.6 + 0.5 * math.sin(t * 2.4)
			end
			if ring then
				if cooling and type(cf) == "number" and cu > cf then
					local k = math.clamp((now - cf) / (cu - cf), 0, 1)
					ring.Transparency = 0.85 - 0.6 * k
					ring.Color = Color3.fromRGB(255, 220, 90):Lerp(Color3.fromRGB(90, 255, 120), k)
				else
					ring.Transparency = if locked then 1 else 0.55 + 0.15 * math.sin(t * 2.4)
					ring.Color = Color3.fromRGB(255, 220, 90)
				end
			end
		end
	end)
end

return ControlsFX
