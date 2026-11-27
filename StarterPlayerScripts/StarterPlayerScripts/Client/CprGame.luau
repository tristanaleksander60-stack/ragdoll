--!strict
-- 3.34 CPR rhythm game (Config.PLAYER_CPR; Systems/PlayerCPR): when the server says "Start", a small panel: a heart
-- line on a little monitor and a big PUSH button (phone) / Space or a click (PC). After a 1.2 s count-in, 5 beats come
-- 0.6 s apart (the ring pulses); a push within 0.15 s of a beat is good (1), within 0.3 s half (0.5). The beats go to
-- the server, which rolls the chance. The panel closes itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local CprGame = {}

local BEAT = 0.6
local LEAD = 1.2
local BEATS = 5

local running = false

local function play(remote: RemoteEvent, model: Instance)
	if running then
		return
	end
	running = true
	local gui = Instance.new("ScreenGui")
	gui.Name = "CprGame"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 0.82, 0)
	panel.Size = UDim2.fromOffset(300, 190)
	panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
	panel.BackgroundTransparency = 0.1
	panel.Parent = gui
	Instance.new("UICorner").Parent = panel
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = "CPR: push on the beat!"
	title.Parent = panel
	-- the monitor: a dark strip with a green trace dot that spikes on each beat
	local screen = Instance.new("Frame")
	screen.Position = UDim2.fromOffset(12, 36)
	screen.Size = UDim2.new(1, -24, 0, 50)
	screen.BackgroundColor3 = Color3.fromRGB(8, 20, 12)
	screen.ClipsDescendants = true
	screen.Parent = panel
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(6, 6)
	dot.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
	dot.BorderSizePixel = 0
	dot.Parent = screen
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.new(0.5, 0, 0, 130)
	ring.Size = UDim2.fromOffset(70, 70)
	ring.BackgroundTransparency = 1
	ring.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 90, 110)
	stroke.Thickness = 4
	stroke.Parent = ring
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(1, 0)
	rc.Parent = ring
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = ring.Position
	button.Size = UDim2.fromOffset(58, 58)
	button.BackgroundColor3 = Color3.fromRGB(220, 60, 80)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "PUSH"
	button.Parent = panel
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = button
	gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")

	local t0 = os.clock()
	local score = 0
	local used: { [number]: boolean } = {}
	local function push()
		local t = os.clock() - t0 - LEAD
		local k = math.floor(t / BEAT + 0.5)
		if k < 0 or k >= BEATS or used[k] then
			return
		end
		local off = math.abs(t - k * BEAT)
		if off <= 0.3 then
			used[k] = true
			local good = off <= 0.15
			score += if good then 1 else 0.5
			title.Text = if good then "GOOD!" else "ok"
		end
	end
	local c1 = button.Activated:Connect(push)
	local c2 = UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Space then
			push()
		end
	end)
	local c3 = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local x = (t % 2) / 2
		local tb = t - LEAD
		local phase = if tb >= 0 then (tb % BEAT) / BEAT else 0.5
		local spike = if tb >= 0 and (phase < 0.12 or phase > 0.94) then 1 else 0
		dot.Position = UDim2.new(x, -3, 0.5, -3 - spike * 18)
		local near = math.min(phase, 1 - phase)
		local s = 70 - 16 * math.max(0, 1 - near * 6)
		ring.Size = UDim2.fromOffset(s, s)
		if tb < 0 then
			title.Text = "Get ready..."
		end
	end)
	task.wait(LEAD + BEAT * BEATS + 0.3)
	c1:Disconnect()
	c2:Disconnect()
	c3:Disconnect()
	remote:FireServer("Result", model, score)
	title.Text = "Beats: " .. score .. " / " .. BEATS
	task.wait(1.2)
	gui:Destroy()
	running = false
end

function CprGame.start()
	if not Config.PLAYER_CPR then
		return
	end
	local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any
	local remote = Net.event(Net.Names.Cpr)
	remote.OnClientEvent:Connect(function(kind: string, model: Instance)
		if kind == "Start" then
			task.spawn(play, remote, model)
		end
	end)
end

return CprGame
