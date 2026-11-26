--!strict
-- OVERVIEW 0.158 "in view" (Config.VIEW_REPORT): this screen tells the server where its camera is and where it looks,
-- twice a second, over an unreliable remote (losing one is fine). The server (RagdollDirector.inView) uses it so ragdolls
-- are only sent away, set down or put away where no camera sees it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any

local ViewReport = {}

ViewReport.EVERY = 0.5

function ViewReport.start()
	if not Config.VIEW_REPORT then
		return
	end
	local remote = Net.unreliable(Net.Names.CameraView)
	task.spawn(function()
		while true do
			task.wait(ViewReport.EVERY)
			local cam = Workspace.CurrentCamera
			if cam then
				local cf = cam.CFrame
				remote:FireServer(cf.Position, cf.LookVector)
			end
		end
	end)
end

return ViewReport
