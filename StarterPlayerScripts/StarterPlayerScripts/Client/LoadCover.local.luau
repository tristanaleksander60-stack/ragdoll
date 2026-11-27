--!strict
-- LoadCover (V10 phase 1, owner 22 Nov 2026: "nobody may see a half-loaded map or half-loaded ragdolls"). A plain
-- cover over the screen from the first frame until the player's own lab is really there on this screen: its
-- floor streamed in round the spawn, and its ragdolls dressed in their skins (DummySkins puts a "Skins" folder in
-- each). At most MAX_WAIT s, then it lifts anyway. It asks the server to stream the lab first, then fades out.
-- It also tells SessionStats when it lifted ("Loaded", the funnel's load step).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local TOUCH = game:GetService("UserInputService").TouchEnabled
local MAX_WAIT = if TOUCH then 8 else 12 -- s
local MIN_DUMMIES = if TOUCH then 2 else 4 -- dressed ragdolls of this lab before it lifts (fewer if the lab has fewer)

local player = Players.LocalPlayer
-- (V10, owner 22 Nov 2026: phones play in landscape, like the big ragdoll games; every phone in the data was held
-- upright, with a narrow view. StarterGui.ScreenOrientation is LandscapeSensor too; this covers a cached place.)
pcall(function()
	(player:WaitForChild("PlayerGui") :: PlayerGui).ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
end)
local gui = Instance.new("ScreenGui")
gui.Name = "LoadCover"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
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
sub.Text = "Loading..." -- (23 Nov 2026: the same words as FirstCover, so a join looks like one load)
sub.Parent = back
-- (AUDIT 31: a progress bar from the real ready() steps, and one rotating kid tip)
local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0)
barBack.Position = UDim2.fromScale(0.5, 0.62)
barBack.Size = UDim2.new(0.4, 0, 0, 10)
barBack.BackgroundColor3 = Color3.fromRGB(44, 48, 60)
barBack.BorderSizePixel = 0
barBack.Parent = back
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = barBack
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0.04, 1)
bar.BackgroundColor3 = Color3.fromRGB(150, 110, 255)
bar.BorderSizePixel = 0
bar.Parent = barBack
corner:Clone().Parent = bar
local TIPS = {
	"Tip: GRAB a ragdoll and THROW it!",
	"Tip: REVIVE ALL wakes every ragdoll up",
	"Tip: X-RAY shows the bones you hit",
	"Tip: try the machines in your lab",
	"Tip: roll a ragdoll down the bowling lane",
}
local tip = Instance.new("TextLabel")
tip.BackgroundTransparency = 1
tip.AnchorPoint = Vector2.new(0.5, 0)
tip.Position = UDim2.fromScale(0.5, 0.68)
tip.Size = UDim2.new(0.8, 0, 0, 22)
tip.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
tip.TextSize = 18
tip.TextColor3 = Color3.fromRGB(170, 175, 190)
tip.Text = TIPS[math.random(1, #TIPS)]
tip.Parent = back
gui.Parent = player:WaitForChild("PlayerGui")

local t0 = os.clock()
local function ready(): boolean
	if player:GetAttribute("SpectateTarget") ~= nil then
		return true -- (the owner, here only to watch)
	end
	local origin = player:GetAttribute("LabOrigin")
	if typeof(origin) ~= "Vector3" then
		return false
	end
	-- (Bug hunt, 23 Nov 2026: a guest in a shared lab has no LabPlot, so the cover waited its whole 12 s. A guest is
	-- ready once standing in the host's lab with the host's ragdolls dressed.)
	local host = player:GetAttribute("SharedGuest")
	if player:GetAttribute("LabPlot") == nil and type(host) == "number" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) or Vector2.new(root.Position.X - origin.X, root.Position.Z - origin.Z).Magnitude > 90 then
			return false
		end
		local dummies = Workspace:FindFirstChild("Dummies")
		local theirs, dressed = 0, 0
		for _, m in if dummies then dummies:GetChildren() else {} do
			if m:GetAttribute("LabOwner") == host then
				theirs += 1
				if m:FindFirstChild("Skins") then
					dressed += 1
				end
			end
		end
		return theirs > 0 and dressed >= math.min(MIN_DUMMIES, theirs)
	end
	local labs = Workspace:FindFirstChild("Labs")
	local plot = player:GetAttribute("LabPlot")
	local plotFolder = labs and labs:FindFirstChild("Lab" .. tostring(plot))
	if not (plotFolder and plotFolder:FindFirstChild("LabFloor", true)) then
		return false
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	local mine, dressed = 0, 0
	for _, m in if dummies then dummies:GetChildren() else {} do
		if m:GetAttribute("LabOwner") == player.UserId then
			mine += 1
			if m:FindFirstChild("Skins") then
				dressed += 1
			end
		end
	end
	return mine > 0 and dressed >= math.min(MIN_DUMMIES, mine)
end

-- Stream the lab in round its spawn as soon as we know where it is.
task.spawn(function()
	while typeof(player:GetAttribute("LabOrigin")) ~= "Vector3" and os.clock() - t0 < MAX_WAIT do
		task.wait(0.2)
	end
	local origin = player:GetAttribute("LabOrigin")
	if typeof(origin) == "Vector3" then
		pcall(function()
			player:RequestStreamAroundAsync(origin, 4)
		end)
	end
end)

-- How far the real steps are (0..1): the lab is known, its floor is here, its ragdolls are dressed.
local function progress(): number
	if typeof(player:GetAttribute("LabOrigin")) ~= "Vector3" then
		return 0.1
	end
	local labs = Workspace:FindFirstChild("Labs")
	local plotFolder = labs and labs:FindFirstChild("Lab" .. tostring(player:GetAttribute("LabPlot")))
	local p = if plotFolder and plotFolder:FindFirstChild("LabFloor", true) then 0.55 else 0.3
	local dummies = Workspace:FindFirstChild("Dummies")
	local dressed = 0
	for _, m in if dummies then dummies:GetChildren() else {} do
		if m:FindFirstChild("Skins") and m:GetAttribute("LabOwner") == player.UserId then
			dressed += 1
		end
	end
	return p + 0.4 * math.min(1, dressed / MIN_DUMMIES)
end
local shown = 0.04
local tipAt = os.clock()
while os.clock() - t0 < MAX_WAIT and not ready() do
	-- (never backwards; time also creeps it on, so a slow phone still sees it move)
	local want = math.max(progress(), math.min(0.9, (os.clock() - t0) / MAX_WAIT))
	shown = math.max(shown, shown + (want - shown) * 0.3)
	bar.Size = UDim2.fromScale(shown, 1)
	if os.clock() - tipAt > 3 then
		tipAt = os.clock()
		tip.Text = TIPS[math.random(1, #TIPS)]
	end
	task.wait(0.1)
end
bar.Size = UDim2.fromScale(1, 1)
task.wait(0.1) -- (a beat for the last skins)
pcall(function()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local r = remotes and remotes:FindFirstChild("Session")
	if r and r:IsA("RemoteEvent") then
		r:FireServer("Loaded", { at = os.clock() - t0, timedOut = os.clock() - t0 >= MAX_WAIT })
	end
end)
local fade = TweenInfo.new(0.5)
TweenService:Create(back, fade, { BackgroundTransparency = 1 }):Play()
TweenService:Create(title, fade, { TextTransparency = 1 }):Play()
TweenService:Create(sub, fade, { TextTransparency = 1 }):Play()
TweenService:Create(tip, fade, { TextTransparency = 1 }):Play()
TweenService:Create(barBack, fade, { BackgroundTransparency = 1 }):Play()
TweenService:Create(bar, fade, { BackgroundTransparency = 1 }):Play()
task.wait(0.55)
gui:Destroy()
