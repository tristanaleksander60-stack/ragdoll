--!strict
-- Slide (0.37.11, owner 22 Nov 2026: "the slide so slippery you cannot climb up it, and you slide down"). A
-- part with the attribute Slide (Server/Systems/Heights) takes the player's own character down it: while
-- the feet are on it, the body sits and is carried down its slope (the part's LookVector points downhill)
-- at SPEED, whatever the keys say, so nobody walks up it. Off it, the player stands up again. Ragdolls need
-- none of this: the slide has no friction, so they slide by themselves.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SPEED = 55 -- studs/s along the slope
local LEAVE_AFTER = 0.25 -- s off the slide before standing up

local player = Players.LocalPlayer
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local sliding = false
local offSince = 0

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) or humanoid.Health <= 0 then
		sliding = false
		return
	end
	params.FilterDescendantsInstances = { character :: Model }
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -5, 0), params)
	local slide = hit and hit.Instance
	if slide and slide:GetAttribute("Slide") == true then
		local down = slide.CFrame.LookVector
		if down.Y > 0 then
			down = -down
		end
		root.AssemblyLinearVelocity = down * SPEED
		if not sliding then
			sliding = true
			humanoid.Sit = true
		end
		offSince = os.clock()
	elseif sliding and os.clock() - offSince > LEAVE_AFTER then
		sliding = false
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end)
