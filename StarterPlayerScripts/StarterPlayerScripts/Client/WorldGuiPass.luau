--!strict
-- WorldGuiPass (FIXES_27NOV_LATE 6, Config.WORLD_GUI_PASS; owner, PC: "Man kan ikke bevæge musen i nærheden af mange
-- af tingene"). The cause, found in one Play: 181 world GUIs (166 sign and label SurfaceGuis, the ragdoll faces,
-- the boards) had Active = true and not one button. An Active world GUI catches the mouse over its whole area, so
-- near a sign or a machine the camera would not turn and a click (a shot, a grab) was lost. Every SurfaceGui and
-- BillboardGui with no button or text box in it is made inactive, and so are the plain frames inside it; new ones
-- are fixed as they appear. GUIs with a button keep working.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local WorldGuiPass = {}

local function hasInput(g: Instance): boolean
	return g:FindFirstChildWhichIsA("GuiButton", true) ~= nil or g:FindFirstChildWhichIsA("TextBox", true) ~= nil
end

local function pass(g: Instance)
	if not (g:IsA("SurfaceGui") or g:IsA("BillboardGui")) then
		return
	end
	if hasInput(g) then
		return
	end
	(g :: any).Active = false
	for _, o in g:GetDescendants() do
		if o:IsA("GuiObject") and o.Active then
			o.Active = false
		end
	end
end

function WorldGuiPass.start()
	if not Config.WORLD_GUI_PASS then
		return
	end
	task.spawn(function()
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
		for _, root in { Workspace, pg } :: { Instance } do
			for _, g in root:GetDescendants() do
				pass(g)
			end
			root.DescendantAdded:Connect(function(g)
				if g:IsA("SurfaceGui") or g:IsA("BillboardGui") then
					task.defer(pass, g) -- (its children are added right after it)
				end
			end)
		end
	end)
end

return WorldGuiPass
