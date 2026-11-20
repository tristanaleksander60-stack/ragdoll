--!strict
-- V9-0c (owner, 21 Nov 2026: "... and make a speedometer"): a round gauge while you drive a lab car
-- (VehicleClient.reading): a needle that sweeps over 240 degrees, the speed in km/h big in the
-- middle, a small gear chip (D / R / N) and a red zone at the top speed. UI v2 tokens; it pops in
-- when you sit down and leaves when you get out. On touch it is a little smaller (UIScale) and sits
-- in the same spot, clear of the thumb buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local CarDrive = require(Shared:WaitForChild("CarDrive")) :: any
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local Speedometer = {}

Speedometer.SIZE = 132 -- px, the gauge's width and height (design units; touch scales it 0.85)
Speedometer.SWEEP = 240 -- degrees from 0 to the top of the dial
Speedometer.TICKS = 12
Speedometer.RED_FROM = 0.85 -- of the dial: the red zone

local gui: ScreenGui? = nil
local needle: Frame? = nil
local number: TextLabel? = nil
local gear: TextLabel? = nil
local scale: UIScale? = nil
local shown = false
local shownAngle = 0
local dialFrame: Frame? = nil

-- (The gauge sits just above the tool bar wherever the bar is on this screen: PC, tablet, phone.)
local function place()
	local dial = dialFrame
	if not dial or not gui then
		return
	end
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local toyBar = pg and pg:FindFirstChild("ToyBar")
	local bar = toyBar and toyBar:FindFirstChild("Bar")
	if bar and bar:IsA("GuiObject") and bar.Visible and bar.AbsoluteSize.Y > 0 then
		local top = bar.AbsolutePosition.Y - (gui :: ScreenGui).AbsolutePosition.Y
		dial.AnchorPoint = Vector2.new(0.5, 1)
		dial.Position = UDim2.new(0, bar.AbsolutePosition.X + bar.AbsoluteSize.X / 2, 0, top - 10)
	else
		dial.Position = UDim2.new(0.5, 0, 1, -132)
	end
end

local function rgb(c: any, fallback: Color3): Color3
	return if typeof(c) == "Color3" then c else fallback
end

local function build()
	local P = Theme.Palette or {}
	local g = Instance.new("ScreenGui")
	g.Name = "Speedometer"
	g.ResetOnSpawn = false
	g.DisplayOrder = 8
	g.IgnoreGuiInset = false
	g.Enabled = false
	local dial = Instance.new("Frame")
	dial.Name = "Dial"
	dial.AnchorPoint = Vector2.new(0.5, 1)
	dial.Position = UDim2.new(0.5, 0, 1, -118)
	dial.Size = UDim2.fromOffset(Speedometer.SIZE, Speedometer.SIZE)
	dial.BackgroundColor3 = rgb(P.dusk, Color3.fromRGB(24, 28, 44))
	dial.BackgroundTransparency = 0.08
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = dial
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = rgb(P.accent, Color3.fromRGB(255, 122, 34))
	stroke.Transparency = 0.15
	stroke.Parent = dial
	local s = Instance.new("UIScale")
	s.Scale = 0
	s.Parent = dial
	scale = s
	-- The ticks round the dial, the last ones red.
	local r = Speedometer.SIZE / 2
	for i = 0, Speedometer.TICKS do
		local f = i / Speedometer.TICKS
		local angle = math.rad(-Speedometer.SWEEP / 2 + f * Speedometer.SWEEP)
		local tick = Instance.new("Frame")
		tick.Name = "Tick"
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		local len = if i % 3 == 0 then 12 else 7
		tick.Size = UDim2.fromOffset(3, len)
		local dist = r - 8 - len / 2
		tick.Position = UDim2.fromOffset(r + math.sin(angle) * dist, r - math.cos(angle) * dist)
		tick.Rotation = math.deg(angle)
		tick.BorderSizePixel = 0
		tick.BackgroundColor3 = if f >= Speedometer.RED_FROM then Color3.fromRGB(235, 64, 64) else Color3.fromRGB(230, 234, 245)
		tick.Parent = dial
	end
	-- The needle: a bar from the middle, turned about the middle.
	local pivot = Instance.new("Frame")
	pivot.Name = "Needle"
	pivot.AnchorPoint = Vector2.new(0.5, 0.5)
	pivot.Position = UDim2.fromScale(0.5, 0.5)
	pivot.Size = UDim2.fromOffset(4, (r - 16) * 2)
	pivot.BackgroundTransparency = 1
	pivot.Parent = dial
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.fromScale(0.5, 0)
	bar.Size = UDim2.new(1, 0, 0.5, 0)
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = rgb(P.accent, Color3.fromRGB(255, 122, 34))
	local barRound = Instance.new("UICorner")
	barRound.CornerRadius = UDim.new(0.5, 0)
	barRound.Parent = bar
	bar.Parent = pivot
	needle = pivot
	local hub = Instance.new("Frame")
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.Size = UDim2.fromOffset(12, 12)
	hub.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
	local hubRound = Instance.new("UICorner")
	hubRound.CornerRadius = UDim.new(0.5, 0)
	hubRound.Parent = hub
	hub.Parent = dial
	-- The speed, big, under the hub; "km/h" small; the gear chip.
	local num = Instance.new("TextLabel")
	num.Name = "Speed"
	num.AnchorPoint = Vector2.new(0.5, 0)
	num.Position = UDim2.new(0.5, 0, 0.58, 0)
	num.Size = UDim2.fromOffset(80, 30)
	num.BackgroundTransparency = 1
	num.FontFace = Theme.Fonts and Theme.Fonts.display or Font.fromEnum(Enum.Font.FredokaOne)
	num.TextSize = 28
	num.TextColor3 = Color3.new(1, 1, 1)
	num.Text = "0"
	num.Parent = dial
	number = num
	local unit = Instance.new("TextLabel")
	unit.AnchorPoint = Vector2.new(0.5, 0)
	unit.Position = UDim2.new(0.5, 0, 0.8, 0)
	unit.Size = UDim2.fromOffset(60, 14)
	unit.BackgroundTransparency = 1
	unit.Font = Enum.Font.BuilderSansBold
	unit.TextSize = 13
	unit.TextColor3 = Color3.fromRGB(190, 196, 214)
	unit.Text = "km/h"
	unit.Parent = dial
	local chip = Instance.new("TextLabel")
	chip.Name = "Gear"
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.Position = UDim2.new(0.5, 0, 0.3, 0)
	chip.Size = UDim2.fromOffset(24, 20)
	chip.BackgroundColor3 = Color3.fromRGB(40, 46, 66)
	chip.Font = Enum.Font.BuilderSansBold
	chip.TextSize = 14
	chip.TextColor3 = Color3.fromRGB(120, 230, 150)
	chip.Text = "N"
	local chipRound = Instance.new("UICorner")
	chipRound.CornerRadius = UDim.new(0, 6)
	chipRound.Parent = chip
	chip.Parent = dial
	gear = chip
	dialFrame = dial
	dial.Parent = g
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = g
end

local function show(on: boolean)
	if on == shown or not gui or not scale then
		return
	end
	shown = on
	local touch = (require(script.Parent:WaitForChild("ViewMode")) :: any).isTouch()
	local goal = if on then (if touch then 0.85 else 1) else 0
	if on then
		gui.Enabled = true
	end
	local t = TweenService:Create(scale, TweenInfo.new(if on then 0.28 else 0.16, if on then Enum.EasingStyle.Back else Enum.EasingStyle.Quad, if on then Enum.EasingDirection.Out else Enum.EasingDirection.In), { Scale = goal })
	t:Play()
	if not on then
		t.Completed:Connect(function()
			if not shown and gui then
				gui.Enabled = false
			end
		end)
	end
end

function Speedometer.start()
	if not (Config.VEHICLES and Config.VEHICLES.enabled) then
		return
	end
	build()
	local VehicleClient = require(script.Parent:WaitForChild("VehicleClient")) :: any
	RunService.RenderStepped:Connect(function(dt)
		local reading = VehicleClient.reading
		show(reading.seated == true)
		if not shown then
			return
		end
		place()
		local kmh, g = CarDrive.reading(reading.along)
		local top = math.max(1, (reading.top or 1) * CarDrive.KMH_PER_STUD * 1.1)
		local f = math.clamp(kmh / top, 0, 1)
		local angle = -Speedometer.SWEEP / 2 + f * Speedometer.SWEEP
		shownAngle += (angle - shownAngle) * math.min(1, dt * 12)
		if needle then
			needle.Rotation = shownAngle
		end
		if number then
			number.Text = tostring(kmh)
		end
		if gear then
			gear.Text = g
			gear.TextColor3 = if g == "R" then Color3.fromRGB(255, 150, 90) elseif g == "D" then Color3.fromRGB(120, 230, 150) else Color3.fromRGB(200, 204, 220)
		end
	end)
end

return Speedometer
