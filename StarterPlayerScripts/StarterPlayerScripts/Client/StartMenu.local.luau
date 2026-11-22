--!strict
-- StartMenu (V11 C8, owner 22 Nov 2026: "choose single or multiplayer before you load in, a nice 3D interactive menu
-- that does not lag"). Over everything (LoadCover loads the world under it): a ViewportFrame with a small scene of
-- our own (a round floor, three block ragdolls: one tumbling through the air, one wobbling on its feet, one
-- flailing on the floor, the camera turning slowly round them; about 30 parts, nothing streamed), the game's name
-- and two buttons. SINGLEPLAYER (the default: Enter, or the pad's A on it) lifts the menu: your own lab, as the
-- game is. MULTIPLAYER asks PortalService for the shared lab server; if that is refused (Studio), the menu lifts
-- as singleplayer. Not shown to a player who arrived by teleport (they chose already).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
if Config.START_MENU == false then
	return
end
local okT, tp = pcall(function()
	return TeleportService:GetLocalPlayerTeleportData()
end)
if okT and tp ~= nil then
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "StartMenu"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 120

local back = Instance.new("Frame")
back.Size = UDim2.fromScale(1, 1)
back.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
back.BorderSizePixel = 0
back.Parent = gui
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new(Color3.fromRGB(60, 74, 96), Color3.fromRGB(14, 16, 22))
grad.Parent = back

local view = Instance.new("ViewportFrame")
view.Size = UDim2.fromScale(1, 1)
view.BackgroundTransparency = 1
view.Ambient = Color3.fromRGB(150, 150, 160)
view.LightColor = Color3.fromRGB(255, 250, 240)
view.LightDirection = Vector3.new(-0.4, -1, -0.3)
view.Parent = back
local world = Instance.new("WorldModel")
world.Parent = view
local camera = Instance.new("Camera")
camera.FieldOfView = 45
camera.Parent = view
view.CurrentCamera = camera

local function block(size: Vector3, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = world
	return p
end

local floor = block(Vector3.new(1, 26, 26), Color3.fromRGB(96, 150, 84), Enum.PartType.Cylinder)
floor.CFrame = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
local rim = block(Vector3.new(0.9, 27, 27), Color3.fromRGB(150, 140, 120), Enum.PartType.Cylinder)
rim.CFrame = CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(90))

-- A block ragdoll: parts placed each frame from a root frame and joint angles.
type Doll = { parts: { [string]: Part } }
local SKIN = Color3.fromRGB(226, 226, 222)
local function doll(tint: Color3): Doll
	local d: Doll = { parts = {} }
	d.parts.Torso = block(Vector3.new(2, 2, 1), tint)
	d.parts.Head = block(Vector3.new(1.2, 1.2, 1.2), SKIN, Enum.PartType.Ball)
	d.parts.LA = block(Vector3.new(0.8, 2, 0.8), SKIN)
	d.parts.RA = block(Vector3.new(0.8, 2, 0.8), SKIN)
	d.parts.LL = block(Vector3.new(0.9, 2, 0.9), Color3.fromRGB(70, 74, 86))
	d.parts.RL = block(Vector3.new(0.9, 2, 0.9), Color3.fromRGB(70, 74, 86))
	return d
end
-- root: the torso's frame; a: shoulder swing (left, right), l: hip swing (left, right), radians.
local function pose(d: Doll, root: CFrame, la: number, ra: number, ll: number, rl: number)
	local p = d.parts
	p.Torso.CFrame = root
	p.Head.CFrame = root * CFrame.new(0, 1.65, 0)
	p.LA.CFrame = root * CFrame.new(-1.4, 0.9, 0) * CFrame.Angles(la, 0, 0) * CFrame.new(0, -0.9, 0)
	p.RA.CFrame = root * CFrame.new(1.4, 0.9, 0) * CFrame.Angles(ra, 0, 0) * CFrame.new(0, -0.9, 0)
	p.LL.CFrame = root * CFrame.new(-0.5, -1, 0) * CFrame.Angles(ll, 0, 0) * CFrame.new(0, -1, 0)
	p.RL.CFrame = root * CFrame.new(0.5, -1, 0) * CFrame.Angles(rl, 0, 0) * CFrame.new(0, -1, 0)
end
local flyer = doll(Color3.fromRGB(230, 120, 60))
local wobbler = doll(Color3.fromRGB(80, 150, 230))
local flopper = doll(Color3.fromRGB(120, 200, 90))
local cannon = block(Vector3.new(4, 1.6, 1.6), Color3.fromRGB(60, 62, 70), Enum.PartType.Cylinder)
cannon.CFrame = CFrame.new(-9, 1, 4) * CFrame.Angles(0, 0, math.rad(35))

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.07)
title.Size = UDim2.fromScale(0.8, 0.13)
title.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.TextStrokeTransparency = 0.6
title.Text = if type(Config.GameName) == "string" then Config.GameName else "Hyper Ragdoll Physics"
title.Parent = back

local row = Instance.new("Frame")
row.BackgroundTransparency = 1
row.AnchorPoint = Vector2.new(0.5, 1)
row.Position = UDim2.new(0.5, 0, 1, -28)
row.Size = UDim2.new(0.9, 0, 0, 96)
row.Parent = back
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Padding = UDim.new(0, 18)
list.Parent = row
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(760, 96)
limit.Parent = row

local function button(word: string, sub: string, color: Color3, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = word
	b.LayoutOrder = order
	b.Size = UDim2.new(0.5, -9, 1, 0)
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.Text = ""
	b.Modal = true
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 18)
	c.Parent = b
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(1, 1, 1)
	s.Thickness = 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = b
	local w = Instance.new("TextLabel")
	w.BackgroundTransparency = 1
	w.Position = UDim2.fromScale(0.05, 0.1)
	w.Size = UDim2.fromScale(0.9, 0.52)
	w.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	w.TextScaled = true
	w.TextColor3 = Color3.new(1, 1, 1)
	w.Text = word
	w.Parent = b
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromScale(0.05, 0.62)
	t.Size = UDim2.fromScale(0.9, 0.28)
	t.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(235, 240, 245)
	t.Text = sub
	t.Parent = b
	b.Parent = row
	return b
end
local single = button("SINGLEPLAYER", "Your own lab", Color3.fromRGB(46, 160, 80), 1)
local multi = button("MULTIPLAYER", "One lab with everyone", Color3.fromRGB(50, 120, 210), 2)
local note = Instance.new("TextLabel")
note.BackgroundTransparency = 1
note.AnchorPoint = Vector2.new(0.5, 1)
note.Position = UDim2.new(0.5, 0, 1, -130)
note.Size = UDim2.new(0.6, 0, 0, 26)
note.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
note.TextScaled = true
note.TextColor3 = Color3.fromRGB(230, 230, 230)
note.Text = ""
note.Parent = back

gui.Parent = player:WaitForChild("PlayerGui")
pcall(function()
	GuiService.SelectedObject = single
end)

local t0 = os.clock()
local live = RunService.RenderStepped:Connect(function()
	local t = os.clock() - t0
	camera.CFrame = CFrame.lookAt(Vector3.new(math.sin(t * 0.15) * 22, 9, math.cos(t * 0.15) * 22), Vector3.new(0, 2, 0))
	-- The flyer: shot from the cannon every 2.6 s, tumbling along an arc, then again.
	local k = (t % 2.6) / 2.6
	local x = -9 + k * 18
	local y = 1.5 + math.sin(k * math.pi) * 9
	pose(flyer, CFrame.new(x, y, 4 - k * 6) * CFrame.Angles(k * 9, k * 4, k * 2), math.sin(t * 14), -math.sin(t * 14), math.cos(t * 12), -math.cos(t * 12))
	-- The wobbler: on its feet, swaying, arms out.
	local sway = math.sin(t * 2.4) * 0.25
	pose(wobbler, CFrame.new(3, 3, -3) * CFrame.Angles(0, t * 0.4, sway) * CFrame.new(0, 0, 0), -1.4 + sway, -1.4 - sway, sway * 0.6, -sway * 0.6)
	-- The flopper: on its back, kicking.
	pose(flopper, CFrame.new(-2, 0.6, -5) * CFrame.Angles(math.rad(-90), 0.6, 0), math.sin(t * 6) * 1.2, math.cos(t * 5) * 1.2, math.sin(t * 7) * 0.8, math.cos(t * 6) * 0.8)
end)

local done = false
local function lift()
	if done then
		return
	end
	done = true
	pcall(function()
		GuiService.SelectedObject = nil
	end)
	local out = TweenInfo.new(0.45)
	TweenService:Create(back, out, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(view, out, { ImageTransparency = 1 }):Play()
	for _, d in back:GetDescendants() do
		if d:IsA("TextLabel") then
			TweenService:Create(d, out, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		elseif d:IsA("TextButton") then
			TweenService:Create(d, out, { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, out, { Transparency = 1 }):Play()
		end
	end
	task.delay(0.5, function()
		live:Disconnect()
		gui:Destroy()
	end)
end

single.Activated:Connect(lift)
multi.Activated:Connect(function()
	if done then
		return
	end
	note.Text = "Finding a lab with other players..."
	local Net = require(Shared:WaitForChild("Net")) :: any
	local remote = Net.event(Net.Names.Portal)
	local conn: RBXScriptConnection? = nil
	conn = remote.OnClientEvent:Connect(function(kind: unknown)
		if kind == "Refused" then
			if conn then
				conn:Disconnect()
			end
			note.Text = ""
			lift() -- (no shared server: play here, your own lab)
		end
	end)
	remote:FireServer("Shared")
end)
UserInputService.InputBegan:Connect(function(input)
	if not done and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter) then
		lift()
	end
end)
