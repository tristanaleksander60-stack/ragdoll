--!strict
-- V8-1.1 (the CRASH score, Config.STUNT_SCORE): what the server measures of your own flight
-- (StuntScore, remote Stunt), on this screen:
--   Begin  a live count over your head; a cannon shot also gets a slow-mo beat at the top of its arc
--          that slows your own body (time dilation: speed x K, gravity x K^2, then back: the same
--          path, more slowly), with FeelBus "SlowMo" for the look;
--   Live   the count climbs;
--   Land   a card in the toast lane: CRASH score, the named tricks, your best (NEW BEST!), and
--          AGAIN (back on the pad that threw you). A bullseye rings.
-- The card holds the toast lane while it shows (Toast.hold), so nothing talks over it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any
local StuntMath = require(Shared:WaitForChild("StuntMath")) :: any
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any

local Client = script.Parent

local StuntHud = {}

StuntHud.SLOW_K = 0.35 -- the slow-mo beat's time scale
StuntHud.SLOW_FOR = 0.7 -- s of real time the beat lasts
StuntHud.CARD_FOR = 6 -- s the landing card stays

local player = Players.LocalPlayer
local remote: RemoteEvent? = nil
local live: BillboardGui? = nil
local liveText: TextLabel? = nil
local shown = 0
local card: ScreenGui? = nil
local cardToken = 0

local function clearLive()
	local l = live
	if l then
		l:Destroy()
	end
	live, liveText = nil, nil
end

local function showLive()
	clearLive()
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	local b = Instance.new("BillboardGui")
	b.Name = "StuntLive"
	b.Size = UDim2.fromOffset(220, 60)
	b.StudsOffset = Vector3.new(0, 4, 0)
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	b.Adornee = head
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 214, 64)
	t.Text = "0"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(40, 24, 0)
	stroke.Parent = t
	t.Parent = b
	b.Parent = player:WaitForChild("PlayerGui")
	live, liveText = b, t
	shown = 0
end

local function setLive(score: number)
	local t = liveText
	if not t then
		return
	end
	local from = shown
	shown = score
	local v = Instance.new("NumberValue")
	v.Value = from
	v.Changed:Connect(function(x)
		t.Text = StuntMath.format(x)
	end)
	local tw = TweenService:Create(v, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { Value = score })
	tw.Completed:Connect(function()
		v:Destroy()
	end)
	tw:Play()
end

-- The slow-mo beat on your own body at the top of the cannon's arc.
local function slowBeat()
	local character = player.Character
	if not character then
		return
	end
	local k = StuntHud.SLOW_K
	-- (One per assembly: setting an assembly's velocity through each of its parts would apply it
	-- many times over. A play test shot the body into space that way.)
	local parts = {}
	local seen: { [BasePart]: boolean } = {}
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") and not d.Anchored then
			local rootPart = d.AssemblyRootPart or d
			if not seen[rootPart] then
				seen[rootPart] = true
				table.insert(parts, rootPart)
			end
		end
	end
	pcall(function()
		(require(Client:WaitForChild("FeelBus")) :: any).fire("SlowMo", { seconds = StuntHud.SLOW_FOR })
	end)
	for _, p in parts do
		p.AssemblyLinearVelocity *= k
		p.AssemblyAngularVelocity *= k
	end
	local lift = Workspace.Gravity * (1 - k * k)
	local t0 = os.clock()
	local conn: RBXScriptConnection? = nil
	conn = RunService.Heartbeat:Connect(function(dt)
		if os.clock() - t0 >= StuntHud.SLOW_FOR or not character.Parent then
			if conn then
				conn:Disconnect()
			end
			for _, p in parts do
				if p.Parent then
					p.AssemblyLinearVelocity /= k
					p.AssemblyAngularVelocity /= k
				end
			end
			return
		end
		-- (Gravity as K^2 of itself: the missing part pushed back up each frame.)
		for _, p in parts do
			if p.Parent then
				p.AssemblyLinearVelocity += Vector3.new(0, lift * dt, 0)
			end
		end
	end)
end

-- Waits for the top of the arc (going up, then not), then the beat.
local function watchApex()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local t0 = os.clock()
	local rising = false
	while os.clock() - t0 < 4 and root.Parent do
		local vy = root.AssemblyLinearVelocity.Y
		if vy > 20 then
			rising = true
		elseif rising and vy <= 0 then
			slowBeat()
			return
		end
		RunService.Heartbeat:Wait()
	end
end

local function closeCard()
	local c = card
	if c then
		c:Destroy()
	end
	card = nil
	pcall(function()
		(require(Client:WaitForChild("Toast")) :: any).hold("Stunt", false)
	end)
end

local function showCard(d: any)
	closeCard()
	cardToken += 1
	local token = cardToken
	local HudSlots = require(Client:WaitForChild("HudSlots")) :: any
	local ViewMode = require(Client:WaitForChild("ViewMode")) :: any
	local screen = (Workspace.CurrentCamera :: Camera).ViewportSize
	local centre, width, top = HudSlots.toastBox(screen, HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()))
	local w = math.min(width, 380)
	local g = Instance.new("ScreenGui")
	g.Name = "StuntCard"
	g.ResetOnSpawn = false
	g.DisplayOrder = 30
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.fromOffset(centre, top or 10)
	f.Size = UDim2.fromOffset(w, if d.again then 128 else 92)
	f.BackgroundColor3 = Color3.fromRGB(22, 26, 44)
	f.BackgroundTransparency = 0.08
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = if d.newBest then Color3.fromRGB(255, 214, 64) else Color3.fromRGB(255, 140, 40)
	stroke.Thickness = 2
	stroke.Parent = f
	local function label(text: string, y: number, h: number, size: number, color: Color3, font: Enum.Font): TextLabel
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromOffset(12, y)
		t.Size = UDim2.new(1, -24, 0, h)
		t.Font = font
		t.TextSize = size
		t.TextColor3 = color
		t.TextScaled = false
		t.TextWrapped = true
		t.Text = text
		t.Parent = f
		return t
	end
	local scoreLine = label("CRASH 0", 6, 36, 30, Color3.fromRGB(255, 214, 64), Enum.Font.FredokaOne)
	local tricks = if type(d.tricks) == "table" then table.concat(d.tricks, "  \u{00B7}  ") else ""
	label(if tricks ~= "" then tricks else string.format("%.1f s in the air", tonumber(d.air) or 0), 42, 20, 16, Color3.new(1, 1, 1), Enum.Font.GothamBold)
	label(if d.newBest then "NEW BEST!" else "Best " .. StuntMath.format(tonumber(d.best) or 0), 62, 22, 16, if d.newBest then Color3.fromRGB(120, 230, 140) else Color3.fromRGB(190, 196, 214), Enum.Font.GothamBold)
	if d.again then
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = UDim2.new(0.5, 0, 1, -8)
		b.Size = UDim2.fromOffset(160, 36)
		b.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
		b.Font = Enum.Font.FredokaOne
		b.TextSize = 22
		b.TextColor3 = Color3.fromRGB(40, 20, 0)
		b.Text = "AGAIN!"
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 12)
		bc.Parent = b
		b.Activated:Connect(function()
			C.playSound("click")
			local r = remote
			if r then
				r:FireServer("Again")
			end
			closeCard()
		end)
		b.Parent = f
	end
	f.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	card = g
	pcall(function()
		(require(Client:WaitForChild("Toast")) :: any).hold("Stunt", true)
	end)
	-- The score counts up, with a tick for each step.
	local target = tonumber(d.score) or 0
	task.spawn(function()
		local steps = 12
		for i = 1, steps do
			if cardToken ~= token then
				return
			end
			scoreLine.Text = "CRASH " .. StuntMath.format(target * i / steps)
			if i % 3 == 0 then
				C.playSound("tick", 0.9 + i * 0.05)
			end
			task.wait(0.04)
		end
		C.playSound(if d.newBest then "unlock" else "reward")
	end)
	task.delay(StuntHud.CARD_FOR, function()
		if cardToken == token then
			closeCard()
		end
	end)
end

function StuntHud.start()
	if not Config.STUNT_SCORE then
		return
	end
	remote = Net.event(Net.Names.Stunt)
	;(remote :: RemoteEvent).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		local d = if type(data) == "table" then data :: any else {}
		if kind == "Begin" then
			showLive()
			if d.machine == "Cannon" then
				task.spawn(watchApex)
			end
		elseif kind == "Live" then
			setLive(tonumber(d.score) or 0)
		elseif kind == "Land" then
			clearLive()
			if type(d.tricks) == "table" and table.find(d.tricks, "BULLSEYE!") then
				C.playSound("unlock", 1.2) -- (the bullseye's ding)
			end
			showCard(d)
		end
	end)
end

return StuntHud
