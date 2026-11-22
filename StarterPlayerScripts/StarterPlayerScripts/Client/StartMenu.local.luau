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

-- (23 Nov 2026, owner: "the start menu looks like trash: just our thumbnail in the background, a little darker"):
-- the game's first thumbnail, cropped to fill, under a dark veil.
local view = Instance.new("ImageLabel")
view.Size = UDim2.fromScale(1, 1)
view.BackgroundTransparency = 1
view.Image = "rbxassetid://130041076140252"
view.ScaleType = Enum.ScaleType.Crop
view.ImageColor3 = Color3.fromRGB(150, 150, 150)
view.Parent = back
local veil = Instance.new("Frame")
veil.Size = UDim2.fromScale(1, 1)
veil.BackgroundColor3 = Color3.new(0, 0, 0)
veil.BackgroundTransparency = 0.55
veil.BorderSizePixel = 0
veil.Parent = back

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

local live = RunService.RenderStepped:Connect(function() end) -- (no scene to move any more)

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
		elseif d:IsA("Frame") then
			TweenService:Create(d, out, { BackgroundTransparency = 1 }):Play()
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
