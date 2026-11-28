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
	b.Font = Enum.Font.BuilderSansBold -- (AUDIT 29: the HUD font)
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
	local grow = Instance.new("UIScale") -- (AUDIT 29: the pulse grows from the centre, not from the corner)
	grow.Parent = b
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
	-- (XRAY_BUTTON_TOUCH_ONLY: on a computer X-RAY is already in the bottom-left list (the I key), so the round button
	-- shows on touch screens only; the I key still works everywhere.)
	if Config.XRAY_BUTTON_TOUCH_ONLY then
		local UIS = game:GetService("UserInputService")
		local function show()
			gui.Enabled = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("TouchFirst")) :: any).get() -- (TOUCH_FIRST_DEVICE: the Device attribute, not "no keyboard")
		end
		show()
		UIS:GetPropertyChangedSignal("KeyboardEnabled"):Connect(show)
		UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(show)
		;(require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("TouchFirst")) :: any).onChange(show)
	end
	gui.Parent = player:WaitForChild("PlayerGui")
	local function toggle()
		local on = not DummySkins.xrayIsOn()
		DummySkins.setXray(on)
		b.BackgroundColor3 = if on then ON else OFF
		b.Text = if on then "X-RAY ON" else "X-RAY" -- (AUDIT 29: said in words, not by colour only)
		player:SetAttribute("XRayOn", on) -- (F21: the chip lights up)
		if on then
			pcall(function() -- (FIXES_27NOV_LATE 4: the funnel step and event, told to the server)
			local r = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
			local e = r and r:FindFirstChild("Session")
			if e and e:IsA("RemoteEvent") then
				e:FireServer("Xray", "toggle")
			end
		end)
		end
	end
	XRayToggle.toggle = toggle
	-- (XRAY_TEST_HOOK, RUN 2.3: the MCP's key, click and its own require copy cannot reach the X-ray in the phone
	-- emulator, so no X-ray proof could be taken. A local player attribute "XRayWant" (true/false) now turns it on/off
	-- exactly as the button does. Client-only: it changes only this player's own view.)
	if Config.XRAY_TEST_HOOK then
		player:GetAttributeChangedSignal("XRayWant"):Connect(function()
			if (player:GetAttribute("XRayWant") == true) ~= DummySkins.xrayIsOn() then
				toggle()
			end
		end)
	end
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
	-- T1 part 2 (FTUE_10 "the X-RAY moment"): after the first bone you see break (or at 3:00), the X-RAY button pulses
	-- once and the goal line says "See the bones!". Once a session, and never while X-ray is already on.
	if Config.FTUE_10 then
		local pulsed = false
		local function pulse()
			if pulsed or DummySkins.xrayIsOn() then
				return
			end
			pulsed = true
			pcall(function()
				(require(script.Parent:WaitForChild("HudV3")) :: any).moment("See the bones! Tap X-RAY", 6)
			end)
			local TweenService = game:GetService("TweenService")
			for _ = 1, 3 do
				TweenService:Create(grow, TweenInfo.new(0.25), { Scale = 1.3 }):Play()
				TweenService:Create(b, TweenInfo.new(0.25), { BackgroundColor3 = ON }):Play()
				task.wait(0.3)
				TweenService:Create(grow, TweenInfo.new(0.25), { Scale = 1 }):Play()
				TweenService:Create(b, TweenInfo.new(0.25), { BackgroundColor3 = if DummySkins.xrayIsOn() then ON else OFF }):Play()
				task.wait(0.3)
			end
		end
		task.delay(180, pulse)
		task.spawn(function()
			local dummies = workspace:WaitForChild("Dummies", 60)
			if not dummies then
				return
			end
			local function watch(m: Instance)
				m:GetAttributeChangedSignal("BoneStages"):Connect(function()
					local v = m:GetAttribute("BoneStages")
					if not pulsed and type(v) == "string" and string.find(v, ":[34]") then
						task.delay(1, pulse)
					end
				end)
			end
			for _, m in dummies:GetChildren() do
				watch(m)
			end
			dummies.ChildAdded:Connect(watch)
		end)
	end
end

return XRayToggle
