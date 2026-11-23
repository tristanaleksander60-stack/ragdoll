--!strict
-- ViewBob (23 Nov 2026, owner: "the camera goes up and down when you walk and run in first person"). In first person,
-- on the ground and moving, the view bobs: a step's dip and a little sway from side to side, faster and bigger on the
-- run; it eases out when you stop or jump. Through Humanoid.CameraOffset, so it never builds up.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local phase = 0
local amount = 0

RunService:BindToRenderStep("ViewBob", Enum.RenderPriority.Camera.Value - 1, function(dt)
	local camera = Workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if not (camera and humanoid and head and head:IsA("BasePart")) then
		return
	end
	local firstPerson = (camera.CFrame.Position - head.Position).Magnitude < 1.5
	local speed = Vector3.new(humanoid.RootPart and humanoid.RootPart.AssemblyLinearVelocity.X or 0, 0, humanoid.RootPart and humanoid.RootPart.AssemblyLinearVelocity.Z or 0).Magnitude
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local want = if firstPerson and grounded and speed > 1 then math.clamp(speed / 16, 0.4, 1.6) else 0
	amount += (want - amount) * math.min(1, dt * 8)
	player:SetAttribute("ViewBobbing", if amount >= 0.01 then true else nil)
	if amount < 0.01 then
		if humanoid.CameraOffset ~= Vector3.zero then
			humanoid.CameraOffset = Vector3.zero
		end
		return
	end
	phase += dt * (6 + speed * 0.35)
	local dip = -math.abs(math.sin(phase)) * 0.16 * amount
	local sway = math.sin(phase * 0.5) * 0.06 * amount
	humanoid.CameraOffset = Vector3.new(sway, dip, 0)
end)
