--!strict
-- RocketPilot (RUN 1.18 the PILOT, Config.ROCKET_PILOT). While the server flies YOUR rocket (the player attribute
-- "PilotRocket" = the full name of the rocket's RocketPromptPart, which moves with it):
--   * a CHASE camera behind and above the ragdoll on the rocket, looking along the nose (never first person);
--   * steering: WASD / the arrow keys, or the phone's move stick (the character's MoveDirection), camera-relative; the wanted nose
--     direction goes to the server through Net RocketSteer about 10 times a second (the server turns it at most
--     90 degrees a second and never into the ground);
--   * a small HUD: height, speed and a BOOM button (Net RocketBoom: blow it up now).
-- Your own character stands still meanwhile; everything is put back when the flight ends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any

local RocketPilot = {}

local player = Players.LocalPlayer

local function find(path: string): BasePart?
	local node: Instance? = game
	for name in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(name)
	end
	return if node and node:IsA("BasePart") then node else nil
end

-- The steer as (x right, z back), like a move vector. This game has no PlayerModule (its own controls), so: WASD and the
-- arrow keys straight from the keyboard; else the character's MoveDirection (the phone stick moves it even while the
-- walk speed is 0), turned into the camera's frame.
local UserInputService = game:GetService("UserInputService")
local function moveVector(): Vector3
	local x, z = 0, 0
	local K = Enum.KeyCode
	if UserInputService:IsKeyDown(K.D) or UserInputService:IsKeyDown(K.Right) then
		x += 1
	end
	if UserInputService:IsKeyDown(K.A) or UserInputService:IsKeyDown(K.Left) then
		x -= 1
	end
	if UserInputService:IsKeyDown(K.W) or UserInputService:IsKeyDown(K.Up) then
		z -= 1
	end
	if UserInputService:IsKeyDown(K.S) or UserInputService:IsKeyDown(K.Down) then
		z += 1
	end
	if x == 0 and z == 0 then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local md = if hum then hum.MoveDirection else Vector3.zero
		if md.Magnitude > 0.1 then
			local cf = Workspace.CurrentCamera.CFrame
			local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
			fwd = if fwd.Magnitude > 0.1 then fwd.Unit else Vector3.zAxis
			x = md:Dot(cf.RightVector)
			z = -md:Dot(fwd)
		end
	end
	return Vector3.new(x, 0, z)
end

local function hud(): (ScreenGui, TextLabel, TextButton)
	local gui = Instance.new("ScreenGui")
	gui.Name = "RocketPilotHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	local info = Instance.new("TextLabel")
	info.AnchorPoint = Vector2.new(0.5, 0)
	info.Position = UDim2.new(0.5, 0, 0, 70)
	info.Size = UDim2.fromOffset(260, 40)
	info.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	info.BackgroundTransparency = 0.25
	info.TextColor3 = Color3.new(1, 1, 1)
	info.Font = Enum.Font.FredokaOne
	info.TextScaled = true
	info.Text = ""
	local c1 = Instance.new("UICorner")
	c1.CornerRadius = UDim.new(0, 10)
	c1.Parent = info
	info.Parent = gui
	local boom = Instance.new("TextButton")
	boom.Name = "Boom"
	boom.AnchorPoint = Vector2.new(0, 1)
	boom.Position = UDim2.new(0.5, 150, 1, -16) -- (beside the hotbar: the right edge holds X-RAY and the phone's buttons)
	boom.Size = UDim2.fromOffset(84, 84)
	boom.BackgroundColor3 = Color3.fromRGB(230, 60, 40)
	boom.TextColor3 = Color3.new(1, 1, 1)
	boom.Font = Enum.Font.FredokaOne
	boom.TextScaled = true
	boom.Text = "BOOM"
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(1, 0)
	c2.Parent = boom
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 30), UDim.new(0, 30)
	pad.Parent = boom
	boom.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui, info, boom
end

local active = false

local function fly(path: string)
	if active then
		return
	end
	local part = find(path)
	if not part then
		return
	end
	active = true
	local cam = Workspace.CurrentCamera
	local oldType = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local oldSpeed = hum and hum.WalkSpeed or 16
	local oldJump = hum and hum.JumpPower or 50
	if hum then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
	end
	local gui, info, boom = hud()
	local steer = Net.unreliable(Net.Names.RocketSteer)
	boom.Activated:Connect(function()
		Net.event(Net.Names.RocketBoom):FireServer()
	end)
	local startY = part.Position.Y
	local lastPos = part.Position
	local lastAt = os.clock()
	local shownSpeed = 0
	local sendAt = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt: number)
		if not part.Parent or player:GetAttribute("PilotRocket") ~= path then
			conn:Disconnect()
			gui:Destroy()
			local function finish()
				active = false
				cam.CameraType = oldType
				if hum and hum.Parent then
					hum.WalkSpeed = oldSpeed
					hum.JumpPower = oldJump
				end
			end
			-- the camera stays on the blast for 2 s (the server's PilotBlast), then lets go
			local blast = player:GetAttribute("PilotBlast")
			if typeof(blast) == "Vector3" then
				local from = cam.CFrame.Position
				local hold = RunService.RenderStepped:Connect(function()
					cam.CFrame = CFrame.lookAt(from, blast)
				end)
				task.delay(2, function()
					hold:Disconnect()
					finish()
				end)
			else
				finish()
			end
			return
		end
		local nose = part.CFrame.UpVector
		local at = part.Position
		-- the chase camera: behind the rocket along its nose, a little above
		local up = Vector3.yAxis - nose * nose:Dot(Vector3.yAxis)
		up = if up.Magnitude > 0.2 then up.Unit else Vector3.zAxis
		local want = CFrame.lookAt(at - nose * 18 + up * 7, at + nose * 30, up)
		cam.CFrame = cam.CFrame:Lerp(want, math.clamp(dt * 8, 0, 1))
		-- the HUD
		-- (the speed over a quarter second: the server moves the rocket less often than the screen draws)
		if os.clock() - lastAt >= 0.25 then
			shownSpeed = (at - lastPos).Magnitude / (os.clock() - lastAt)
			lastPos, lastAt = at, os.clock()
		end
		info.Text = string.format("%d studs up  |  %d studs/s", math.floor(at.Y - startY + 0.5), math.floor(shownSpeed + 0.5))
		-- steering, camera-relative, about 10 a second
		local now = os.clock()
		if now >= sendAt then
			sendAt = now + 0.1
			local mv = moveVector()
			local d = nose + (cam.CFrame.RightVector * mv.X + cam.CFrame.UpVector * -mv.Z) * 0.9
			if d.Magnitude > 0.05 then
				steer:FireServer(d.Unit)
			end
		end
	end)
end

function RocketPilot.start()
	if not Config.ROCKET_PILOT then
		return
	end
	local function check()
		local path = player:GetAttribute("PilotRocket")
		if type(path) == "string" and path ~= "" then
			task.spawn(fly, path)
		end
	end
	player:GetAttributeChangedSignal("PilotRocket"):Connect(check)
	check()
end

return RocketPilot
