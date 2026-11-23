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
row.AnchorPoint = Vector2.new(0.5, 0.5)
row.Position = UDim2.new(0.5, 0, 0.56, 0) -- (23 Nov 2026, owner: "in the middle of the screen")
row.Size = UDim2.new(0.9, 0, 0, 96)
row.Parent = back
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
note.AnchorPoint = Vector2.new(0.5, 0)
note.Position = UDim2.new(0.5, 0, 0.56, 70)
note.Size = UDim2.new(0.6, 0, 0, 26)
note.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
note.TextScaled = true
note.TextColor3 = Color3.fromRGB(230, 230, 230)
note.Text = ""
note.Parent = back

gui.Parent = player:WaitForChild("PlayerGui")
-- (23 Nov 2026, owner: "load in as fast as possible"): the world round the lab streams in while the menu is up.
task.spawn(function()
	local t0 = os.clock()
	while typeof(player:GetAttribute("LabOrigin")) ~= "Vector3" and os.clock() - t0 < 15 do
		task.wait(0.1)
	end
	local origin = player:GetAttribute("LabOrigin")
	if typeof(origin) == "Vector3" then
		pcall(function()
			player:RequestStreamAroundAsync(origin, 6)
		end)
	end
end)
pcall(function()
	GuiService.SelectedObject = single
end)

-- (23 Nov 2026, owner: "make them bounce up and down"): each button hops on its own beat; it grows a little
-- under the mouse.
local t0 = os.clock()
local hover: { [GuiObject]: boolean } = {}
for _, b in { single, multi } do
	b.MouseEnter:Connect(function()
		hover[b] = true
	end)
	b.MouseLeave:Connect(function()
		hover[b] = nil
	end)
	local s = Instance.new("UIScale")
	s.Parent = b
end
local live = RunService.RenderStepped:Connect(function()
	local t = os.clock() - t0
	for i, b in { single, multi } do
		local hop = math.abs(math.sin(t * 3 + i * 1.2)) * 14
		b.Position = UDim2.new(if i == 1 then 0 else 0.5, if i == 1 then 0 else 9, 0, -hop) -- (SINGLEPLAYER left, the default)
		local s = b:FindFirstChildOfClass("UIScale")
		if s then
			s.Scale += ((if hover[b] then 1.08 else 1) - s.Scale) * 0.2
		end
	end
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

-- (23 Nov 2026, owner: "nothing happens when you pick one"): a pick always shows: the button squishes and a line
-- says what happens; SINGLEPLAYER lifts the menu, MULTIPLAYER says it is going (or, in Studio, why it cannot, for
-- 2 s) and then lifts. Activated and a plain press both count (a press the camera or a pad ate still picks).
local picked = false
local function squish(b: GuiObject)
	local s = b:FindFirstChildOfClass("UIScale")
	if s then
		s.Scale = 0.88
	end
end
-- (23 Nov 2026, owner: "after picking one, 4-5 s of an empty world before it loads"): the menu stays up, saying
-- it loads, until the lab is really there (its floor, the character, 6 dressed ragdolls; the LoadCover test),
-- at most READY_MAX s.
local READY_MAX = 20
local function labReady(): boolean
	if not player.Character or typeof(player:GetAttribute("LabOrigin")) ~= "Vector3" then
		return false
	end
	-- (23 Nov 2026, owner: "5 s standing on Roblox's default plate"): the character must stand in its lab already.
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	local origin = player:GetAttribute("LabOrigin") :: Vector3
	if not (root and root:IsA("BasePart")) or Vector2.new(root.Position.X - origin.X, root.Position.Z - origin.Z).Magnitude > 90 then
		return false
	end
	local plot = player:GetAttribute("LabPlot")
	if plot == nil then
		return true -- (a guest on a shared server: the host's lab)
	end
	local labs = workspace:FindFirstChild("Labs")
	local plotFolder = labs and labs:FindFirstChild("Lab" .. tostring(plot))
	if not (plotFolder and plotFolder:FindFirstChild("LabFloor", true)) then
		return false
	end
	local dummies = workspace:FindFirstChild("Dummies")
	local mine, dressed = 0, 0
	for _, m in if dummies then dummies:GetChildren() else {} do
		if m:GetAttribute("LabOwner") == player.UserId then
			mine += 1
			if m:FindFirstChild("Skins") then
				dressed += 1
			end
		end
	end
	return mine > 0 and dressed >= math.min(3, mine) -- (23 Nov 2026, owner: "load in as fast as possible": 3, the rest dress in view)
end
local function liftWhenReady(after: (() -> ())?)
	task.spawn(function()
		local t0 = os.clock()
		if not labReady() then
			note.Text = "Loading your lab..."
		end
		while not labReady() and os.clock() - t0 < READY_MAX do
			task.wait(0.1)
		end
		-- (23 Nov 2026, owner: "everyone loads in as fast as possible"): the world round the lab was asked for when
		-- the menu came up (below); once the lab is in and the bar is drawn the menu lifts at once and takes the
		-- LoadCover under it along.
		local hud = player.PlayerGui:FindFirstChild("ToyBar")
		while not hud and os.clock() - t0 < READY_MAX do
			task.wait(0.1)
			hud = player.PlayerGui:FindFirstChild("ToyBar")
		end
		local cover = player.PlayerGui:FindFirstChild("LoadCover")
		if cover then
			cover:Destroy()
		end
		lift()
		if after then
			pcall(after)
		end
	end)
end
local function pickSingle()
	if picked or done then
		return
	end
	picked = true
	squish(single)
	note.Text = "Your own lab!"
	liftWhenReady(nil)
end
local function pickMulti()
	if picked or done then
		return
	end
	picked = true
	squish(multi)
	-- (23 Nov 2026, owner: "everyone who picks multiplayer spawns in the same lab"): this server's shared lab
	-- (PortalService "JoinShared", Lab.joinShared); the MULTIPLAYER portal in the lab opens the server hub.
	note.Text = "Joining the shared lab..."
	local Net = require(Shared:WaitForChild("Net")) :: any
	local portal = Net.event(Net.Names.Portal)
	-- (No shared lab on this server: the server sends everyone who picks MULTIPLAYER to the same shared-lab
	-- server; the menu stays up through the teleport. Refused (Studio, a failed teleport): play here.)
	local going = false
	local refused = false
	local conn = portal.OnClientEvent:Connect(function(kind: unknown)
		if kind == "Going" then
			going = true
			note.Text = "Taking you to the multiplayer lab..."
		elseif kind == "Refused" then
			refused = true
		end
	end)
	portal:FireServer("JoinShared")
	-- (Until the server has made this player the host or a guest here, or sends them on.)
	local t0 = os.clock()
	while player:GetAttribute("SharedGuest") == nil and player:GetAttribute("SharedHost") ~= true and not going and not refused and os.clock() - t0 < 4 do
		task.wait(0.05)
	end
	if going then
		task.delay(15, function()
			conn:Disconnect()
			liftWhenReady(nil) -- (the teleport never happened)
		end)
		return
	end
	conn:Disconnect()
	liftWhenReady(nil)
end
single.Activated:Connect(pickSingle)
multi.Activated:Connect(pickMulti)
single.MouseButton1Down:Connect(pickSingle)
multi.MouseButton1Down:Connect(pickMulti)
UserInputService.InputBegan:Connect(function(input)
	if not done and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter) then
		pickSingle()
	end
end)
