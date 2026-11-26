--!strict
-- BODY_V2 1 (owner, 26 Nov 2026: "X-RAY 10/10"; Config.XRAY_V2): an X-RAY button on the HUD (every device; touch: a
-- round button on the right, 64 px) and the I key (V is first person, X revive all, B build mode). On: the nearest
-- bodies within 80 studs show their X-ray look with the whole skeleton (DummySkins.setXray); off: normal. The short
-- automatic X-ray flash after 3 hits on one limb stays as it was.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local XRayToggle = {}
XRayToggle.toggle = function() end -- (set in start)

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
	-- (Owner, 26 Nov 2026: "tænk mere ind i telefon"): on a phone the right column is the body card arrow (top), RAGDOLL,
	-- RELOAD, JUMP and SHOOT; X-RAY sits in the free gap under the arrow and over RAGDOLL, 60 px. Off a phone: right, middle.
	local function place()
		local camera = workspace.CurrentCamera
		local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
		if math.min(v.X, v.Y) <= 500 then
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -10, 0, 62)
			b.Size = UDim2.fromOffset(60, 60)
		else
			b.AnchorPoint = Vector2.new(1, 0.5)
			b.Position = UDim2.new(1, -12, 0.42, 0)
			b.Size = UDim2.fromOffset(64, 64)
		end
	end
	place()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
	end
	gui.Parent = player:WaitForChild("PlayerGui")
	local function toggle()
		local on = not DummySkins.xrayIsOn()
		DummySkins.setXray(on)
		b.BackgroundColor3 = if on then ON else OFF
		player:SetAttribute("XRayOn", on) -- (F21: the chip lights up)
	end
	XRayToggle.toggle = toggle
	-- (F21: the key comes from Keybinds "XRay" (I); a pad uses D-pad left.)
	local key = Enum.KeyCode.I
	pcall(function()
		local k = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Keybinds")) :: any).key("XRay")
		if typeof(k) == "EnumItem" then
			key = k
		end
	end)
	b.Activated:Connect(toggle)
	ContextActionService:BindAction("XRayToggle", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggle()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, key, Enum.KeyCode.DPadLeft) -- (B is Build mode: Keybinds "Build"; I is the one free letter)
end

return XRayToggle
