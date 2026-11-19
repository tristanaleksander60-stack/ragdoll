--!strict
-- Round 5: the health bar during an NPC Chase (ChaseService on the server sets ChaseHP, ChaseMax
-- and ChaseLeft on the player). Top middle, under the toasts: a red bar that shakes when you are
-- hit, and how many chasers are still standing. Gone when the chase ends. The hit line rests
-- during a chase (HitInfo.show) and the bar steps aside while a slot is picked.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))
local HudSlots = require(script.Parent:WaitForChild("HudSlots"))

local ChaseHud = {}

ChaseHud.TOP = 108 -- px down the safe area: under the toast box (a phone's ends at 96), 12 clear
ChaseHud.SIZE = Vector2.new(280, 46)

-- (A phone held upright: under its toast box, HudSlots.eventTop.)
function ChaseHud.top(screen: Vector2): number
	return HudSlots.eventTop(screen, ChaseHud.TOP, HudSlots.PORTRAIT_CHASE_BELOW)
end
local function top(): number
	return ChaseHud.top(workspace.CurrentCamera.ViewportSize)
end

local player = Players.LocalPlayer

function ChaseHud.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChaseHud"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 9
	gui.Enabled = false
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, top())
	frame.Size = UDim2.fromOffset(280, 46)
	frame.BackgroundColor3 = Color3.fromRGB(20, 16, 24)
	frame.BackgroundTransparency = 0.15
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(10, 3)
	title.Size = UDim2.new(1, -20, 0, 16)
	title.FontFace = Theme.Fonts.display
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(10, 23)
	track.Size = UDim2.new(1, -20, 0, 16)
	track.BackgroundColor3 = Color3.fromRGB(60, 20, 24)
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(1, 0)
	tc.Parent = track
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(235, 50, 60)
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill
	fill.Parent = track
	track.Parent = frame
	frame.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	local lastHp = -1
	local function redraw()
		local hp = player:GetAttribute("ChaseHP")
		local max = player:GetAttribute("ChaseMax")
		if type(hp) ~= "number" or type(max) ~= "number" or max <= 0 then
			gui.Enabled = false
			lastHp = -1
			return
		end
		-- (Steps aside while a slot is picked: the pick chip has the middle of a phone. LayoutCheck.)
		local chip = player.PlayerGui:FindFirstChild("PickChip", true)
		-- (And on a phone held upright while building: BUILD/PLAY have its row. The chase runs on.)
		local vp = workspace.CurrentCamera.ViewportSize
		local upright = math.min(vp.X, vp.Y) <= 500 and vp.Y > vp.X
		gui.Enabled = not (chip and chip:IsA("GuiObject") and chip.Visible) and not (upright and player:GetAttribute("Building") == true)
		frame.Position = UDim2.new(0.5, 0, 0, top())
		local left = player:GetAttribute("ChaseLeft")
		title.Text = string.format("NPC CHASE  ·  HP %d  ·  %s LEFT", hp, tostring(left or "?"))
		TweenService:Create(fill, TweenInfo.new(0.15), { Size = UDim2.fromScale(math.clamp(hp / max, 0, 1), 1) }):Play()
		if lastHp >= 0 and hp < lastHp then
			-- (A punch: the bar shakes.)
			frame.Position = UDim2.new(0.5, 6, 0, top())
			TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Elastic), { Position = UDim2.new(0.5, 0, 0, top()) }):Play()
		end
		lastHp = hp
	end
	for _, a in { "ChaseHP", "ChaseMax", "ChaseLeft", "Building" } do
		player:GetAttributeChangedSignal(a):Connect(redraw)
	end
	task.spawn(function()
		local chip = player.PlayerGui:WaitForChild("ToyBar", 30) and player.PlayerGui:FindFirstChild("PickChip", true)
		if chip and chip:IsA("GuiObject") then
			chip:GetPropertyChangedSignal("Visible"):Connect(redraw)
		end
	end)
	redraw()
end

return ChaseHud
