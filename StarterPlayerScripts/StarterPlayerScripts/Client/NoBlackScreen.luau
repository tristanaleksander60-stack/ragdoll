--!strict
-- F3 (owner, 26 Nov 2026: "Fjern den sorte skærm"; Config.NO_BLACK_SCREEN): the screen went black when you were pushed,
-- knocked or ragdolled. The cause: in first person (or zoomed right in) the camera sits in your head, and a loose body
-- tumbles so the camera ends inside your own torso or a wall. While your own body is loose (the character's
-- BodyLoose / RagdollState, set by Systems/PlayerRagdoll) the camera is held out at LOOSE_ZOOM studs (third person) on
-- the head, and goes back to how it was when you stand up. Occlusion stays "Zoom" so walls pull the camera in front.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local NoBlackScreen = {}

NoBlackScreen.LOOSE_ZOOM = 9

local player = Players.LocalPlayer

function NoBlackScreen.start()
	if not Config.NO_BLACK_SCREEN then
		return
	end
	local kept: { min: number, mode: Enum.CameraMode }? = nil
	local function loose(c: Model?): boolean
		local s = c and c:GetAttribute("RagdollState")
		return c ~= nil and (c:GetAttribute("BodyLoose") == true or s == "Ragdoll" or s == "Out")
	end
	task.spawn(function()
		while true do
			task.wait(0.1)
			local c = player.Character
			if loose(c) then
				if not kept then
					kept = { min = player.CameraMinZoomDistance, mode = player.CameraMode }
				end
				if player.CameraMode ~= Enum.CameraMode.Classic then
					player.CameraMode = Enum.CameraMode.Classic
				end
				if player.CameraMinZoomDistance < NoBlackScreen.LOOSE_ZOOM then
					player.CameraMinZoomDistance = math.min(NoBlackScreen.LOOSE_ZOOM, player.CameraMaxZoomDistance)
				end
				local head = (c :: Model):FindFirstChild("Head")
				local camera = Workspace.CurrentCamera
				if camera and head and head:IsA("BasePart") and camera.CameraSubject ~= head then
					camera.CameraSubject = head
				end
			elseif kept then
				local k = kept :: { min: number, mode: Enum.CameraMode }
				kept = nil
				player.CameraMinZoomDistance = k.min
				player.CameraMode = k.mode
				local h = c and c:FindFirstChildOfClass("Humanoid")
				local camera = Workspace.CurrentCamera
				if camera and h then
					camera.CameraSubject = h
				end
			end
		end
	end)
end

return NoBlackScreen
