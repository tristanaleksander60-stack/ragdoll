--!strict
-- The visible physics budget: how many of your props are out, against your cap. It fills green ->
-- yellow -> red; when it is full the next prop makes your oldest one fade away (the meter pulses
-- so that is never a surprise). The broom clears everything you placed in one tap.
-- Hidden while you have nothing out, so the first minute stays clean.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Net = require(Shared:WaitForChild("Net"))
local Assets = require(Shared:WaitForChild("Assets"))
local V2 = require(Shared:WaitForChild("Config")).UI_V2 == true -- (UI v2: the 14 px text floor)

local Client = script.Parent
local ReplayController = require(Client:WaitForChild("ReplayController"))
local HudV3 = require(script.Parent:WaitForChild("HudGate")) -- (LOOK_V3: is HudV3 on)
local HudSlots = require(Client:WaitForChild("HudSlots"))

local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(120, 230, 140)
local YELLOW = Color3.fromRGB(255, 205, 60)
local RED = Color3.fromRGB(255, 90, 70)
local LINGER = 2.5 -- s the meter stays after the last prop is gone

local ChaosMeter = {}

local group: CanvasGroup
local fill: Frame
local stroke: UIStroke
local countLabel: TextLabel
local shownCount = 0
local lastNonZero = -math.huge
local visible = false

local function colorFor(t: number): Color3
	if t < 0.5 then
		return GREEN:Lerp(YELLOW, t / 0.5)
	end
	return YELLOW:Lerp(RED, (t - 0.5) / 0.5)
end

local function bump(object: GuiObject, scale: number)
	local s = Instance.new("UIScale")
	s.Scale = scale
	s.Parent = object
	local tween = TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 })
	tween:Play()
	tween.Completed:Once(function()
		s:Destroy()
	end)
end

local function setVisible(on: boolean)
	if on == visible then
		return
	end
	visible = on
	group.Visible = true
	local tween = TweenService:Create(group, TweenInfo.new(0.25), { GroupTransparency = if on then 0 else 1 })
	tween:Play()
	if not on then
		tween.Completed:Once(function()
			if not visible then
				group.Visible = false
			end
		end)
	end
end

local function refresh()
	local count = (player:GetAttribute("PropCount") :: number?) or 0
	local max = math.max((player:GetAttribute("PropMax") :: number?) or 10, 1)
	local t = math.clamp(count / max, 0, 1)
	TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(t, 1),
		BackgroundColor3 = colorFor(t),
	}):Play()
	countLabel.Text = string.format("%d/%d", count, max)
	if count >= max and shownCount < max then
		-- Just hit the cap: from now on new props replace the oldest.
		bump(group, 1.12)
		stroke.Color = RED
		TweenService:Create(stroke, TweenInfo.new(0.6), { Color = Color3.fromRGB(255, 255, 255) }):Play()
	end
	if count > 0 then
		lastNonZero = os.clock()
	end
	shownCount = count
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Chaos"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	group = Instance.new("CanvasGroup")
	group.Name = "Meter"
	group.AnchorPoint = Vector2.new(0, 0)
	HudSlots.apply(group, "Chaos", HudSlots.context(false, false))
	group.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	group.BackgroundTransparency = 0.1
	group.GroupTransparency = 1
	group.Visible = false
	group.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = group
	stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.6
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = group

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 5)
	label.Size = UDim2.fromOffset(90, if V2 then 18 else 16)
	label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	label.TextSize = if V2 then 15 else 13 -- (UI v2: 14 px drawn at the touch HUD scale)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = "CHAOS"
	label.Parent = group

	countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.BackgroundTransparency = 1
	countLabel.Position = UDim2.fromOffset(102, 5)
	countLabel.Size = UDim2.fromOffset(60, if V2 then 18 else 16)
	countLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	countLabel.TextSize = if V2 then 15 else 13
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	countLabel.Text = "0/10"
	countLabel.Parent = group

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(12, 26)
	track.Size = UDim2.fromOffset(150, 10)
	track.BackgroundColor3 = Color3.fromRGB(70, 70, 82)
	track.BorderSizePixel = 0
	track.Parent = group
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = GREEN
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local broom = Instance.new("ImageButton")
	broom.Name = "CleanUp"
	broom.AnchorPoint = Vector2.new(1, 0.5)
	broom.Position = UDim2.new(1, -6, 0.5, 0)
	broom.Size = UDim2.fromOffset(38, 38)
	broom.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
	broom.Image = Assets.Broom
	broom.ScaleType = Enum.ScaleType.Fit
	broom.Parent = group
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = broom
	local broomCorner = Instance.new("UICorner")
	broomCorner.CornerRadius = UDim.new(0, 10)
	broomCorner.Parent = broom
	local function sweep()
		Net.event(Net.Names.CleanUp):FireServer()
		bump(broom, 0.8)
		local spin = TweenService:Create(broom, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Rotation = broom.Rotation - 25 })
		spin:Play()
		spin.Completed:Once(function()
			TweenService:Create(broom, TweenInfo.new(0.2), { Rotation = 0 }):Play()
		end)
	end
	broom.Activated:Connect(sweep)
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("CleanUp", input.KeyCode) then
			sweep()
		end
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

function ChaosMeter.start()
	build()
	player:GetAttributeChangedSignal("PropCount"):Connect(refresh)
	player:GetAttributeChangedSignal("PropMax"):Connect(refresh)
	refresh()
	RunService.Heartbeat:Connect(function()
		-- (On a phone the part counter has its place while building: BuildController's "Building".)
		local building = player:GetAttribute("Building") == true and HudSlots.context(false, false).phone
		local want = not ReplayController.isPlaying() and not building and not HudV3.active() and (shownCount > 0 or os.clock() - lastNonZero < LINGER)
		setVisible(want)
	end)
end

return ChaosMeter
