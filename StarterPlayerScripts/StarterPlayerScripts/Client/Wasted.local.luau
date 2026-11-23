--!strict
-- Wasted (V10 phase 3, owner: "an animal eats you and WASTED comes up on the screen, then you respawn in your
-- lab"). Server LabCreatures fires Remotes.Wasted (seconds, what ate you): the world drains to grey and slows
-- into a dark band with WASTED in big red letters and a small line under it, for those seconds; the server then
-- gives you a new body in your lab. Our own look (no other game's font or art).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("Wasted") or game:GetService("ReplicatedStorage"):FindFirstChild("Wasted") or remotes:WaitForChild("Wasted", 60)
if not (remote and remote:IsA("RemoteEvent")) then
	return
end

remote.OnClientEvent:Connect(function(seconds: number, by: string?, how: string?)
	local hold = if type(seconds) == "number" then math.clamp(seconds, 1, 6) else 2.6
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "WastedGrade"
	grade.Parent = Lighting
	TweenService:Create(grade, TweenInfo.new(0.6), { Saturation = -1, Contrast = 0.15, Brightness = -0.08 }):Play()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Wasted"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 90
	local band = Instance.new("Frame")
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(0.5, 0.5)
	band.Size = UDim2.new(1, 0, 0, 120)
	band.BackgroundColor3 = Color3.new(0, 0, 0)
	band.BackgroundTransparency = 1
	band.BorderSizePixel = 0
	band.Parent = gui
	local word = Instance.new("TextLabel")
	word.BackgroundTransparency = 1
	word.AnchorPoint = Vector2.new(0.5, 0.5)
	word.Position = UDim2.fromScale(0.5, 0.42)
	word.Size = UDim2.new(0.8, 0, 0, 80)
	word.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	word.TextScaled = true
	word.TextColor3 = Color3.fromRGB(200, 30, 36)
	word.TextStrokeColor3 = Color3.new(0, 0, 0)
	word.TextStrokeTransparency = 0.2
	word.Text = "WASTED"
	word.TextTransparency = 1
	word.Parent = band
	local line = Instance.new("TextLabel")
	line.BackgroundTransparency = 1
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.Position = UDim2.fromScale(0.5, 0.8)
	line.Size = UDim2.new(0.6, 0, 0, 22)
	line.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	line.TextScaled = true
	line.TextColor3 = Color3.fromRGB(230, 230, 230)
	line.Text = if type(by) == "string" then (if type(how) == "string" then how else "Eaten by ") .. by else ""
	line.TextTransparency = 1
	line.Parent = band
	local scale = Instance.new("UIScale")
	scale.Scale = 1.4
	scale.Parent = word
	gui.Parent = player:WaitForChild("PlayerGui")
	local inInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(band, inInfo, { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(word, inInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(line, inInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(scale, inInfo, { Scale = 1 }):Play()
	task.delay(hold + 0.4, function()
		local out = TweenInfo.new(0.4)
		TweenService:Create(grade, out, { Saturation = 0, Contrast = 0, Brightness = 0 }):Play()
		TweenService:Create(band, out, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(word, out, { TextTransparency = 1 }):Play()
		TweenService:Create(line, out, { TextTransparency = 1 }):Play()
		task.wait(0.45)
		gui:Destroy()
		grade:Destroy()
	end)
end)
