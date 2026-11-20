--!strict
-- 21 Nov 2026 (the owner: "make the messages that pop up, like SURPRISE, much nicer"): the centre
-- banner for big moments (Shared/BannerRules says which): a coloured ribbon that unrolls, a picture
-- in a round badge, a big gold title that pops in, a short line under it, a sting. One at a time,
-- a short queue (a chase jumps it); toasts wait while it shows, so it never lands on top of one.
-- Toast.show sends the lines BannerRules knows here, so every sender gets the banner for free.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BannerRules = require(Shared:WaitForChild("BannerRules"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any
local Icons = require(UI:WaitForChild("LihFolkUIIcons")) :: any

local Banner = {}

type Item = { spec: BannerRules.Spec, at: number }

local queue: { Item } = {}
local busy = false
local gui: ScreenGui? = nil
local shownCount = 0

local function ensureGui(): ScreenGui
	if gui and gui.Parent then
		return gui
	end
	local g = Instance.new("ScreenGui")
	g.Name = "Banner"
	g.ResetOnSpawn = false
	g.DisplayOrder = 26
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = g
	return g
end

local function toastHold(on: boolean)
	pcall(function()
		(require(script.Parent:WaitForChild("Toast")) :: any).hold("banner", on)
	end)
end

local function sting(priority: number)
	if priority < 3 then
		return
	end
	pcall(function()
		(require(UI:WaitForChild("LihFolkUIComponents")) :: any).playSound("reward")
	end)
end

local function corner(parent: Instance, r: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = r
	c.Parent = parent
end

-- Draws one banner and plays it through; returns when it is gone.
local function play(spec: BannerRules.Spec, hold: number)
	local g = ensureGui()
	local camera = Workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local reduced = Theme.isReducedMotion()
	-- (Design px at a 1080 px tall screen; a phone draws it smaller, never under 0.62.)
	local k = math.clamp(view.Y / 900, 0.62, 1.1)
	local width = math.min(760, (view.X - 32) / k)

	local root = Instance.new("Frame")
	root.Name = "Moment"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, BannerRules.Y)
	root.Size = UDim2.fromOffset(width, 150)
	local scale = Instance.new("UIScale")
	scale.Scale = if reduced then k else k * 0.45
	scale.Parent = root

	-- The ribbon: the moment's colour, fading out at both ends, with thin bright edges.
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.AnchorPoint = Vector2.new(0.5, 0.5)
	ribbon.Position = UDim2.new(0.5, 0, 0.5, -6)
	ribbon.Size = UDim2.new(if reduced then 1 else 0.2, 0, 0, 84)
	ribbon.BackgroundColor3 = spec.color
	ribbon.BorderSizePixel = 0
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.16, 0.08),
		NumberSequenceKeypoint.new(0.84, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, spec.color),
		ColorSequenceKeypoint.new(0.5, spec.color:Lerp(Color3.new(1, 1, 1), 0.18)),
		ColorSequenceKeypoint.new(1, spec.color),
	})
	fade.Parent = ribbon
	for _, y in { 0, 1 } do
		local edge = Instance.new("Frame")
		edge.Name = "Edge"
		edge.AnchorPoint = Vector2.new(0.5, y)
		edge.Position = UDim2.fromScale(0.5, y)
		edge.Size = UDim2.new(1, 0, 0, 3)
		edge.BackgroundColor3 = Color3.new(1, 1, 1)
		edge.BorderSizePixel = 0
		local ef = Instance.new("UIGradient")
		ef.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0.35),
			NumberSequenceKeypoint.new(0.75, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		ef.Parent = edge
		edge.Parent = ribbon
	end
	ribbon.Parent = root

	-- The head: the badge with its picture, then the title.
	local head = Instance.new("Frame")
	head.Name = "Head"
	head.BackgroundTransparency = 1
	head.AnchorPoint = Vector2.new(0.5, 0.5)
	head.Position = UDim2.new(0.5, 0, 0.5, -8)
	head.Size = UDim2.fromOffset(0, 96)
	head.AutomaticSize = Enum.AutomaticSize.X
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.Padding = UDim.new(0, 14)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = head
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.LayoutOrder = 1
	badge.Size = UDim2.fromOffset(78, 78)
	badge.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
	corner(badge, UDim.new(0.5, 0))
	local ring = Instance.new("UIStroke")
	ring.Color = spec.color:Lerp(Color3.new(0, 0, 0), 0.35)
	ring.Thickness = 4
	ring.Parent = badge
	local okIcon, hasIcon = pcall(function()
		return spec.icon ~= "" and Icons.has(spec.icon)
	end)
	if okIcon and hasIcon then
		local pic = Icons.make(spec.icon, UDim2.fromOffset(54, 54))
		pic.AnchorPoint = Vector2.new(0.5, 0.5)
		pic.Position = UDim2.fromScale(0.5, 0.5)
		pic.Parent = badge
	else
		local pic = Instance.new("TextLabel")
		pic.BackgroundTransparency = 1
		pic.Size = UDim2.fromScale(1, 1)
		pic.Text = spec.emoji
		pic.TextSize = 44
		pic.Font = Enum.Font.SourceSans
		pic.Parent = badge
	end
	badge.Parent = head
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 2
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromOffset(0, 80)
	title.AutomaticSize = Enum.AutomaticSize.X
	title.FontFace = Theme.Fonts.display
	title.TextSize = 64
	title.Text = spec.title
	title.TextColor3 = Color3.new(1, 1, 1)
	local gold = Instance.new("UIGradient")
	gold.Rotation = 90
	gold.Color = ColorSequence.new(Color3.fromRGB(255, 246, 170), Color3.fromRGB(255, 186, 40))
	gold.Parent = title
	local ink = Instance.new("UIStroke")
	ink.Color = Color3.fromRGB(28, 16, 40)
	ink.Thickness = 5
	ink.Parent = title
	title.Parent = head
	head.Parent = root

	-- The line under it, in a dark pill.
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.AnchorPoint = Vector2.new(0.5, 0)
	sub.Position = UDim2.new(0.5, 0, 0.5, 40)
	sub.Size = UDim2.fromOffset(0, 34)
	sub.AutomaticSize = Enum.AutomaticSize.X
	sub.BackgroundColor3 = Color3.fromRGB(20, 14, 32)
	sub.BackgroundTransparency = 0.15
	sub.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	sub.TextSize = 24
	sub.TextColor3 = Color3.new(1, 1, 1)
	sub.Text = spec.sub
	sub.Visible = spec.sub ~= ""
	corner(sub, UDim.new(0.5, 0))
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 18)
	pad.PaddingRight = UDim.new(0, 18)
	pad.Parent = sub
	sub.Parent = root
	root.Parent = g

	sting(spec.priority)
	if not reduced then
		-- In: the ribbon unrolls, the whole thing pops (a slight overshoot), the badge spins in.
		TweenService:Create(ribbon, TweenInfo.new(BannerRules.ENTER, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 84) }):Play()
		TweenService:Create(scale, TweenInfo.new(BannerRules.ENTER + 0.06, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = k }):Play()
		badge.Rotation = -40
		TweenService:Create(badge, TweenInfo.new(BannerRules.ENTER + 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
		-- A quick shine down the title once it has landed.
		task.delay(BannerRules.ENTER, function()
			if gold.Parent then
				gold.Offset = Vector2.new(0, -0.6)
				TweenService:Create(gold, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { Offset = Vector2.zero }):Play()
			end
		end)
	end
	task.wait(BannerRules.ENTER + hold)
	-- Out: quicker than in (vault: about 0.6 of it), a fade and a small shrink.
	local info = TweenInfo.new(BannerRules.EXIT, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if not reduced then
		TweenService:Create(scale, info, { Scale = k * 0.9 }):Play()
	end
	for _, d in root:GetDescendants() do
		if d:IsA("TextLabel") then
			TweenService:Create(d, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		elseif d:IsA("ImageLabel") then
			TweenService:Create(d, info, { ImageTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
			TweenService:Create(d, info, { BackgroundTransparency = 1 }):Play()
		end
	end
	task.wait(BannerRules.EXIT + 0.02)
	root:Destroy()
end

local function pump()
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		toastHold(true)
		while #queue > 0 do
			local item = table.remove(queue, 1) :: Item
			if os.clock() - item.at <= BannerRules.STALE then
				local hold = if #queue >= 2 then BannerRules.HOLD_BUSY else BannerRules.HOLD
				local ok, err = pcall(play, item.spec, hold)
				if not ok then
					warn("[Banner] " .. tostring(err))
				end
				shownCount += 1
			end
		end
		toastHold(false)
		busy = false
	end)
end

-- Shows a banner (queued behind any on screen; priority 4 goes first). Same title and line already
-- waiting: not added twice.
function Banner.show(spec: BannerRules.Spec)
	for _, item in queue do
		if item.spec.title == spec.title and item.spec.sub == spec.sub then
			return
		end
	end
	local item: Item = { spec = spec, at = os.clock() }
	if spec.priority >= 4 then
		table.insert(queue, 1, item)
	else
		table.insert(queue, item)
	end
	while #queue > BannerRules.QUEUE_MAX do
		table.remove(queue)
	end
	pump()
end

-- A line from any sender: true if it was a big moment the banner took.
function Banner.tryLine(text: string): boolean
	local spec = BannerRules.of(text)
	if not spec then
		return false
	end
	-- (V9-0g, owner 21 Nov 2026: "on the phone you could hardly see anything": in compact notices
	-- the big moment is a small toast pill in the top lane; in a fight only the most important one
	-- (priority 4) shows, the rest are dropped, not queued.)
	local NoticeState = require(script.Parent:WaitForChild("NoticeState")) :: any
	if NoticeState.compact() then
		return NoticeState.busy() and spec.priority < 4
	end
	Banner.show(spec)
	return true
end

-- Tests and LayoutCheck: how many have played, and whether one shows now.
function Banner.count(): number
	return shownCount
end
function Banner.isShowing(): boolean
	return busy
end

return Banner
