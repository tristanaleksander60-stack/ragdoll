--!strict
-- BODY_V2 1 (owner, 26 Nov 2026: "X-RAY 10/10"; Config.XRAY_V2): an X-RAY button on the HUD (every device; touch: a
-- round button on the right, 64 px) and the B key (V is first person, X takes the mech arms off). On: the nearest
-- bodies within 80 studs show their X-ray look with the whole skeleton (DummySkins.setXray); off: normal. The short
-- automatic X-ray flash after 3 hits on one limb stays as it was.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local XRayToggle = {}

local player = Players.LocalPlayer
local OFF = Color3.fromRGB(30, 34, 44)
local ON = Color3.fromRGB(60, 160, 255)

function XRayToggle.start()
	if not Config.XRAY_V2 then
		return
	end
	local DummySkins = require(script.Parent:WaitForChild("DummySkins")) :: any
	local gui = Instance.new("ScreenGui")
	gui.Name = "XRayToggle"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4
	local b = Instance.new("TextButton")
	b.Name = "XRay"
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -12, 0.42, 0)
	b.Size = UDim2.fromOffset(64, 64)
	b.BackgroundColor3 = OFF
	b.BackgroundTransparency = 0.15
	b.Font = Enum.Font.FredokaOne
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextScaled = true
	b.Text = "X-RAY"
	b.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.12, 0), UDim.new(0.12, 0)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.3, 0), UDim.new(0.3, 0)
	pad.Parent = b
	local edge = Instance.new("UIStroke")
	edge.Thickness = 2
	edge.Color = ON
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = b
	gui.Parent = player:WaitForChild("PlayerGui")
	local function toggle()
		local on = not DummySkins.xrayIsOn()
		DummySkins.setXray(on)
		b.BackgroundColor3 = if on then ON else OFF
	end
	b.Activated:Connect(toggle)
	ContextActionService:BindAction("XRayToggle", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggle()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.B)
end

return XRayToggle
