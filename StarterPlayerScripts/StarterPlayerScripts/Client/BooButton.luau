--!strict
-- BooButton (MILD_EXTRAS C3, Config.BOO_MASK): while you stand close behind a standing ragdoll that faces away, a
-- BOO! button shows (a big touch button on phones; the B key on a computer). Pressing it asks the server
-- (Systems/BooMask), which checks it again and makes the ragdoll jump, scream and run.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local BooButton = {}

local REACH = 6 -- studs (the server allows 7)
local ACTION = "BooMask"

local function target(): Model?
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local dummies = Workspace:FindFirstChild("Dummies")
	if not (root and root:IsA("BasePart") and dummies) then
		return nil
	end
	local best, bestD = nil, REACH
	for _, m in dummies:GetChildren() do
		local st = m:GetAttribute("RagdollState")
		local chest = m:FindFirstChild("UpperTorso")
		if (st == "Standing" or st == "Walking") and chest and chest:IsA("BasePart") and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("InMachine") == nil then
			local away = Vector3.new(root.Position.X - chest.Position.X, 0, root.Position.Z - chest.Position.Z)
			local d = away.Magnitude
			local look = Vector3.new(chest.CFrame.LookVector.X, 0, chest.CFrame.LookVector.Z)
			if d < bestD and d > 0.1 and look.Magnitude > 0.1 and look.Unit:Dot(away.Unit) < -0.3 then
				best, bestD = m, d
			end
		end
	end
	return best
end

function BooButton.start()
	if not Config.BOO_MASK then
		return
	end
	local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any
	local remote = Net.event(Net.Names.Boo)
	local current: Model? = nil
	local bound = false
	local function act(_: string, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin and current then
			remote:FireServer(current)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end
	task.spawn(function()
		while true do
			task.wait(0.2)
			current = target()
			if current and not bound then
				bound = true
				ContextActionService:BindAction(ACTION, act, true, Enum.KeyCode.B)
				ContextActionService:SetTitle(ACTION, "BOO!")
				ContextActionService:SetPosition(ACTION, UDim2.new(1, -180, 1, -190))
			elseif not current and bound then
				bound = false
				ContextActionService:UnbindAction(ACTION)
			end
		end
	end)
end

return BooButton
