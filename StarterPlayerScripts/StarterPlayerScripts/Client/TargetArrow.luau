--!strict
-- NOW 1.3 (owner, 26 Nov 2026: "can you see what to do and hit a dummy within 10 seconds?"): a small
-- bobbing arrow over the nearest living dummy for a new player. Only in the first ARROW_SECONDS of a
-- visit and only while the player has fewer than ARROW_KOS takedowns; gone for good after that.
-- One BillboardGui on this screen, moved from dummy to dummy; nothing is sent to the server.
-- Config.TARGET_ARROW.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local TargetArrow = {}

TargetArrow.ARROW_SECONDS = 120
TargetArrow.ARROW_KOS = 3
TargetArrow.RANGE = 70 -- studs from your character
TargetArrow.PICK_EVERY = 0.5 -- s between picks of the nearest dummy

local player = Players.LocalPlayer

local function alive(model: Model): boolean
	if model:GetAttribute("IsDummy") ~= true or model:GetAttribute("Vital") == "Dead" then
		return false
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum == nil or hum.Health > 0
end

local function nearest(from: Vector3): BasePart?
	local folder = Workspace:FindFirstChild("Dummies")
	if not folder then
		return nil
	end
	local best, bestD = nil, TargetArrow.RANGE
	for _, model in folder:GetChildren() do
		if model:IsA("Model") and alive(model) then
			local head = model:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local d = (head.Position - from).Magnitude
				if d < bestD then
					best, bestD = head, d
				end
			end
		end
	end
	return best
end

function TargetArrow.start()
	if not Config.TARGET_ARROW then
		return
	end
	-- (An older player never sees it: only someone who joins with no takedowns to speak of. Never
	-- holds the client boot: the rest runs on its own thread.)
	task.spawn(TargetArrow.run)
end

function TargetArrow.run()
	local function takedowns(): number
		local n = player:GetAttribute("Takedowns")
		return if type(n) == "number" then n else 0
	end
	task.wait(3)
	if takedowns() >= TargetArrow.ARROW_KOS then
		return
	end
	local startKos = takedowns()
	local gui = Instance.new("BillboardGui")
	gui.Name = "TargetArrow"
	gui.Size = UDim2.fromOffset(34, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = TargetArrow.RANGE + 10
	gui.ResetOnSpawn = false
	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.Text = "\u{25BC}"
	arrow.TextScaled = true
	arrow.TextColor3 = Color3.fromRGB(255, 214, 64)
	arrow.TextStrokeTransparency = 0.2
	arrow.TextStrokeColor3 = Color3.fromRGB(40, 25, 0)
	arrow.Font = Enum.Font.GothamBlack
	arrow.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	local began = os.clock()
	local nextPick = 0
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - began > TargetArrow.ARROW_SECONDS or takedowns() - startKos >= TargetArrow.ARROW_KOS or takedowns() >= TargetArrow.ARROW_KOS + 2 then
			if conn then
				conn:Disconnect()
			end
			gui:Destroy()
			return
		end
		if now >= nextPick then
			nextPick = now + TargetArrow.PICK_EVERY
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			gui.Adornee = if root and root:IsA("BasePart") then nearest(root.Position) else nil
		end
		-- the bob
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6 + math.abs(math.sin(now * 4)) * 0.8, 0)
	end)
end

return TargetArrow
