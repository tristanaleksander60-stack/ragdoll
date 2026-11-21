--!strict
-- V9-2b / Phase T (Config.FEED_TERMINAL): this screen's side of the feed terminals (Server/Systems/LabGuide).
-- Each terminal's screen (tag FeedTerminalScreen) gets a SurfaceGui in PlayerGui (only there can it be
-- tapped or clicked): the drawn "dummy ->" picture, FEED SPIDER (the verb and the thing), a big glowing
-- FEED! button (remote Terminal "Press"; the server checks every press), the combo ("x5!") and the queue
-- as six lights. Any press, by anyone, flashes the terminal's 3D button and beeps on screens nearby.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any
local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any

local TerminalClient = {}

TerminalClient.PIXELS = 100 -- per stud on the screen
TerminalClient.BEEP_RANGE = 40 -- studs: a press beeps on screens this near
TerminalClient.ACCENT = Color3.fromRGB(40, 220, 255)

local player = Players.LocalPlayer
local built: { [BasePart]: SurfaceGui } = {}

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function build(screen: BasePart)
	if built[screen] then
		return
	end
	local verb = tostring(screen:GetAttribute("Verb") or "Feed")
	local object = tostring(screen:GetAttribute("Object") or "")
	local gui = Instance.new("SurfaceGui")
	gui.Name = "FeedTerminal"
	gui.Adornee = screen
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = TerminalClient.PIXELS
	gui.LightInfluence = 0
	gui.Brightness = 1.3
	gui.MaxDistance = 90
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local canvas = Instance.new("Frame")
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
	canvas.Parent = gui
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.fromRGB(22, 34, 60), Color3.fromRGB(8, 10, 18))
	g.Parent = canvas
	-- The picture and the words.
	local pic = Instance.new("ImageLabel")
	pic.BackgroundTransparency = 1
	pic.Image = DrawnIcons.guide_feed or ""
	pic.Size = UDim2.fromScale(0.2, 0.32)
	pic.Position = UDim2.fromScale(0.03, 0.04)
	pic.ScaleType = Enum.ScaleType.Fit
	pic.Parent = canvas
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.72, 0.28)
	title.Position = UDim2.fromScale(0.25, 0.06)
	title.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = string.upper(verb .. " " .. object)
	title.Parent = canvas
	-- The big button.
	local button = Instance.new("TextButton")
	button.Name = "Press"
	button.AutoButtonColor = false
	button.Size = UDim2.fromScale(0.62, 0.42)
	button.Position = UDim2.fromScale(0.05, 0.44)
	button.BackgroundColor3 = TerminalClient.ACCENT
	button.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	button.TextScaled = true
	button.TextColor3 = Color3.fromRGB(4, 30, 40)
	button.Text = string.upper(verb) .. "!"
	corner(button, UDim.new(0.3, 0))
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 6
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.4
	stroke.Parent = button
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.Parent = canvas
	button.Activated:Connect(function()
		Net.event(Net.Names.Terminal):FireServer("Press", screen)
		scale.Scale = 0.9
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	-- The combo and the queue.
	local combo = Instance.new("TextLabel")
	combo.BackgroundTransparency = 1
	combo.Size = UDim2.fromScale(0.28, 0.3)
	combo.Position = UDim2.fromScale(0.69, 0.42)
	combo.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	combo.TextScaled = true
	combo.TextColor3 = Color3.fromRGB(255, 210, 80)
	combo.Text = ""
	local comboScale = Instance.new("UIScale")
	comboScale.Parent = combo
	combo.Parent = canvas
	local pips = Instance.new("Frame")
	pips.BackgroundTransparency = 1
	pips.Size = UDim2.fromScale(0.28, 0.12)
	pips.Position = UDim2.fromScale(0.69, 0.76)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0.02, 0)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = pips
	local dots: { Frame } = {}
	for i = 1, 6 do
		local d = Instance.new("Frame")
		d.Size = UDim2.fromScale(0.14, 0.9)
		d.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
		d.LayoutOrder = i
		corner(d, UDim.new(1, 0))
		d.Parent = pips
		table.insert(dots, d)
	end
	pips.Parent = canvas
	local function queue()
		local q = screen:GetAttribute("Queue")
		local n = if type(q) == "number" then q else 0
		for i, d in dots do
			d.BackgroundColor3 = if i <= n then TerminalClient.ACCENT else Color3.fromRGB(50, 60, 80)
		end
	end
	queue()
	screen:GetAttributeChangedSignal("Queue"):Connect(queue)
	screen:GetAttributeChangedSignal("Combo"):Connect(function()
		local n = screen:GetAttribute("Combo")
		if type(n) == "number" and n > 1 then
			combo.Text = "x" .. n .. "!"
			comboScale.Scale = 1.35
			TweenService:Create(comboScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		else
			combo.Text = ""
		end
	end)
	-- Any press: the 3D button flashes; screens nearby hear a beep.
	screen:GetAttributeChangedSignal("PressedAt"):Connect(function()
		local model = screen.Parent
		local b = model and model:FindFirstChild("Button")
		if b and b:IsA("BasePart") then
			b.Color = Color3.new(1, 1, 1)
			TweenService:Create(b, TweenInfo.new(0.18), { Color = TerminalClient.ACCENT }):Play()
		end
		local camera = Workspace.CurrentCamera
		if camera and (camera.CFrame.Position - screen.Position).Magnitude < TerminalClient.BEEP_RANGE then
			pcall(function()
				C.playSound("click")
			end)
		end
	end)
	screen.Destroying:Connect(function()
		gui:Destroy()
		built[screen] = nil
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
	built[screen] = gui
end

function TerminalClient.start()
	if not Config.FEED_TERMINAL then
		return
	end
	for _, s in CollectionService:GetTagged("FeedTerminalScreen") do
		if s:IsA("BasePart") then
			task.spawn(build, s)
		end
	end
	CollectionService:GetInstanceAddedSignal("FeedTerminalScreen"):Connect(function(s)
		if s:IsA("BasePart") then
			task.spawn(build, s)
		end
	end)
end

return TerminalClient
