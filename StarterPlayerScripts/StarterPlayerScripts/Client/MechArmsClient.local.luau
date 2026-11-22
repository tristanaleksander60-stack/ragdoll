--!strict
-- MechArmsClient (23 Nov 2026, owner: "mechanical arms on your back that pull ragdolls apart"). Moves every MechArms
-- set this screen sees (Server/MechArms builds them on Motor6D joints): a slow idle sway, and when the server says a
-- set tore ("Reach", player, point) one pair of arms shoots out at the point and back. Your own: Q (or the TEAR
-- button on touch) asks to tear the ragdoll under the mouse, or the nearest one in reach. A small hint shows the key.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:WaitForChild("MechArms", 60)
if not (remote and remote:IsA("RemoteEvent")) then
	return
end

local REACH = 15
local REACH_TIME = 0.55
local BEND = { math.rad(70), math.rad(70), math.rad(40), math.rad(40) }

type Reach = { point: Vector3, t0: number, pair: number }
local reaches: { [Player]: Reach } = {}
local turn: { [Player]: number } = {}

remote.OnClientEvent:Connect(function(kind: unknown, who: unknown, point: unknown)
	if kind == "Reach" and typeof(who) == "Instance" and (who :: Instance):IsA("Player") and typeof(point) == "Vector3" then
		local p = who :: Player
		turn[p] = ((turn[p] or 0) % 2) + 1
		reaches[p] = { point = point :: Vector3, t0 = os.clock(), pair = turn[p] }
	end
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local set = character and character:FindFirstChild("MechArms")
		local pack = set and set:FindFirstChild("Pack")
		if not (set and pack and pack:IsA("BasePart")) then
			continue
		end
		local r = reaches[p]
		local k = 0
		if r then
			local a = (t - r.t0) / REACH_TIME
			if a >= 1 then
				reaches[p] = nil
				r = nil
			else
				k = math.sin(a * math.pi)
			end
		end
		for i = 1, 4 do
			local sh = pack:FindFirstChild("Shoulder" .. i)
			local upper = set:FindFirstChild("Upper" .. i)
			local el = upper and upper:FindFirstChild("Elbow" .. i)
			if not (sh and sh:IsA("Motor6D") and el and el:IsA("Motor6D")) then
				continue
			end
			local idle = CFrame.Angles(math.sin(t * 1.3 + i) * 0.12, 0, math.cos(t * 1.1 + i * 1.7) * 0.1)
			local idleEl = CFrame.Angles(math.sin(t * 1.7 + i * 2) * 0.15, 0, 0)
			local reachThis = r ~= nil and ((r.pair == 1 and i <= 2) or (r.pair == 2 and i > 2))
			if reachThis and r then
				local frame = pack.CFrame * sh.C0
				local d = frame:VectorToObjectSpace(r.point - frame.Position)
				if d.Magnitude > 0.1 then
					local aim = CFrame.fromRotationBetweenVectors(Vector3.new(0, -1, 0), d.Unit)
					sh.Transform = idle:Lerp(aim, k)
					el.Transform = idleEl:Lerp(CFrame.Angles(-BEND[i], 0, 0), k)
				end
			else
				sh.Transform = idle
				el.Transform = idleEl
			end
		end
	end
end)

-- Your own tears.
local function wearing(): boolean
	return player:GetAttribute("MechArms") == true
end

local function dummyOf(inst: Instance?): Model?
	local node = inst
	while node and node ~= Workspace do
		if node:IsA("Model") and node:GetAttribute("IsDummy") == true then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function target(): Model?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	local mouse = player:GetMouse()
	local under = dummyOf(mouse.Target)
	local up = under and under:FindFirstChild("LowerTorso")
	if under and up and up:IsA("BasePart") and (up.Position - root.Position).Magnitude <= REACH then
		return under
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Instance }
	local best, bestD = nil :: Model?, math.huge
	for _, part in Workspace:GetPartBoundsInRadius(root.Position, REACH, params) do
		local m = dummyOf(part)
		local mp = m and m:FindFirstChild("LowerTorso")
		if m and mp and mp:IsA("BasePart") then
			local d = (mp.Position - root.Position).Magnitude
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

local function tear()
	if not wearing() then
		return
	end
	local m = target()
	if m then
		remote:FireServer("Tear", m)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1 and wearing() then
		tear()
	end
end)

-- The hint (keyboard) or the TEAR button (touch), only while you wear them.
local gui = Instance.new("ScreenGui")
gui.Name = "MechArmsHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.Enabled = false
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 1)
button.Position = if touch then UDim2.new(1, -200, 1, -150) else UDim2.new(0.5, 110, 1, -118)
button.Size = if touch then UDim2.fromOffset(84, 84) else UDim2.fromOffset(150, 34)
button.BackgroundColor3 = Color3.fromRGB(46, 48, 54)
button.BackgroundTransparency = 0.15
button.TextColor3 = Color3.new(1, 1, 1)
button.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
button.TextScaled = true
button.Text = if touch then "TEAR" else "[Q]  Tear apart"
button.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, if touch then 42 else 10)
corner.Parent = button
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(235, 120, 30)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = button
button.Activated:Connect(tear)
gui.Parent = player:WaitForChild("PlayerGui")
local function refresh()
	gui.Enabled = wearing()
end
player:GetAttributeChangedSignal("MechArms"):Connect(refresh)
refresh()
