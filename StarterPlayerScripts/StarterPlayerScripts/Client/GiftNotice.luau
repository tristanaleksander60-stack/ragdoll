--!strict
-- GiftNotice (24 Nov 2026, owner: "a nice notification that does not disturb" when the owner gives someone VIP or
-- ULTRA). A small card slides down under the top bar, its edge shimmers once, and it goes up again after a few seconds.
-- It takes no taps, stops nothing and shows one at a time.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net")) :: any
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Icons = require(UI:WaitForChild("LihFolkUIIcons")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local GiftNotice = {}

GiftNotice.HOLD = 5 -- s
local LOOK = {
	VIP = { title = "You are VIP now!", sub = "A gift from the owner. Enjoy!", icon = "shop_VIP", a = Color3.fromRGB(255, 214, 92), b = Color3.fromRGB(255, 168, 46) },
	Ultra = { title = "You got ULTRA!", sub = "A gift from the owner. No waiting!", icon = "tool_Nuke", a = Color3.fromRGB(190, 120, 255), b = Color3.fromRGB(110, 150, 255) },
} :: { [string]: { title: string, sub: string, icon: string, a: Color3, b: Color3 } }

local queue: { string } = {}
local busy = false

local function label(parent: Instance, text: string, y: number, h: number, size: number, color: Color3, bold: boolean): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(66, y)
	t.Size = UDim2.new(1, -78, 0, h)
	t.FontFace = if bold then Font.new("rbxasset://fonts/families/FredokaOne.json") else Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
	t.TextSize = size
	t.TextColor3 = color
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextTruncate = Enum.TextTruncate.AtEnd
	t.Text = text
	t.Parent = parent
	return t
end

local function showOne(key: string)
	local look = LOOK[key]
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "GiftNotice"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 25
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local camera = Workspace.CurrentCamera
	local small = camera ~= nil and math.min(camera.ViewportSize.X, camera.ViewportSize.Y) <= 500
	local card = Instance.new("CanvasGroup")
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Size = UDim2.fromOffset(310, 62)
	card.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	card.BackgroundTransparency = 0.08
	card.GroupTransparency = 1
	card.Active = false
	local scale = Instance.new("UIScale")
	scale.Scale = if small then 0.82 else 1
	scale.Parent = card
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	local edge = Instance.new("UIStroke")
	edge.Thickness = 2
	edge.Color = Color3.new(1, 1, 1)
	local shine = Instance.new("UIGradient")
	shine.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, look.a), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, look.b) })
	shine.Offset = Vector2.new(-1, 0)
	shine.Rotation = 15
	shine.Parent = edge
	edge.Parent = card
	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(46, 46)
	badge.Position = UDim2.fromOffset(9, 8)
	badge.BackgroundColor3 = Color3.new(1, 1, 1)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = badge
	local fill = Instance.new("UIGradient")
	fill.Color = ColorSequence.new(look.a, look.b)
	fill.Rotation = 60
	fill.Parent = badge
	local pic = Icons.make(look.icon, UDim2.fromOffset(36, 36))
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	pic.Position = UDim2.fromScale(0.5, 0.5)
	pic.Parent = badge
	badge.Parent = card
	label(card, look.title, 9, 24, 21, look.a, true)
	label(card, look.sub, 34, 18, 15, Color3.fromRGB(214, 216, 226), false)
	local rest = UDim2.new(0.5, 0, 0, if small then 62 else 100)
	local up = UDim2.new(0.5, 0, 0, if small then 40 else 74)
	card.Position = up
	card.Parent = gui
	gui.Parent = playerGui
	local calm = Theme.isReducedMotion()
	-- (No sound: it must not disturb.)
	TweenService:Create(card, TweenInfo.new(if calm then 0.15 else 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = rest, GroupTransparency = 0 }):Play()
	if not calm then
		task.delay(0.35, function()
			TweenService:Create(shine, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1, 0) }):Play()
		end)
	end
	task.wait(GiftNotice.HOLD)
	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = up, GroupTransparency = 1 }):Play()
	task.wait(0.4)
	gui:Destroy()
end

function GiftNotice.show(key: string)
	if not LOOK[key] or table.find(queue, key) then
		return
	end
	table.insert(queue, key)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		while #queue > 0 do
			local ok, err = pcall(showOne, queue[1])
			if not ok and RunService:IsStudio() then
				warn("[GiftNotice] " .. tostring(err))
			end
			table.remove(queue, 1)
		end
		busy = false
	end)
end

function GiftNotice.start()
	Net.event(Net.Names.Money).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "Gift" and type(data) == "table" and type((data :: any).key) == "string" then
			GiftNotice.show((data :: any).key)
		end
	end)
end

return GiftNotice
