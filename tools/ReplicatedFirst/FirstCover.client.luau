--!strict
-- FirstCover (23 Nov 2026, owner: "the first 3 seconds you stand on Roblox's plate and can run about, then you fly into
-- the map from the ground"). Lives in ReplicatedFirst (place file only: Script Sync does not reach ReplicatedFirst;
-- this file is its copy, put in by the Studio MCP). It runs before anything else loads: it takes Roblox's own
-- loading screen away and puts a dark cover with the game's name over everything from the first frame, until the
-- start menu (Client/StartMenu) or the LoadCover (an arrival by teleport) is up under it, at most 30 s.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "FirstCover"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 200
local back = Instance.new("Frame")
back.Size = UDim2.fromScale(1, 1)
back.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
back.BorderSizePixel = 0
back.Parent = gui
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.45)
title.Size = UDim2.new(0.8, 0, 0, 60)
title.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Text = "Hyper Ragdoll Physics"
title.Parent = back
local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.AnchorPoint = Vector2.new(0.5, 0)
sub.Position = UDim2.fromScale(0.5, 0.53)
sub.Size = UDim2.new(0.6, 0, 0, 26)
sub.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
sub.TextScaled = true
sub.TextColor3 = Color3.fromRGB(190, 190, 200)
sub.Text = "Loading..."
sub.Parent = back
gui.Parent = playerGui
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)
-- (23 Nov 2026, owner: "it is like joining twice"): the way on to your own server wears this cover too. Set here, on
-- the first frame: the teleport may start before PortalUI runs.
pcall(function()
	game:GetService("TeleportService"):SetTeleportGui(gui:Clone())
end)

local t0 = os.clock()
while os.clock() - t0 < 30 do
	local menu = playerGui:FindFirstChild("StartMenu")
	local cover = playerGui:FindFirstChild("LoadCover")
	if menu or (cover and os.clock() - t0 > 0.3) then
		break
	end
	task.wait(0.05)
end
task.wait(0.1)
gui:Destroy()
