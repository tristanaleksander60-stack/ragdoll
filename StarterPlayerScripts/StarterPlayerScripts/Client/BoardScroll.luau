--!strict
-- BoardScroll (owner 27 Nov late: "man kan ikke scrolle på leaderboards"; Config.BOARD_SCROLL). The cause: a SurfaceGui
-- that lives in the Workspace never gets mouse, wheel or touch input, so the boards' ScrollingFrame ("List") could not be
-- scrolled. Roblox's rule: a SurfaceGui takes input only from the PlayerGui with its Adornee set to the part. On this
-- screen every leaderboard ("Board" SurfaceGui with a ScrollingFrame) is moved into the PlayerGui, adorned to its own
-- panel; the server's updates still reach it (the same instance; PlotPrivacy moves things the same way). If its panel
-- goes, the gui goes with it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local BoardScroll = {}

local moved: { [SurfaceGui]: BasePart } = {}

local function take(gui: Instance)
	if not gui:IsA("SurfaceGui") or moved[gui] then
		return
	end
	local panel = gui.Parent
	if not (panel and panel:IsA("BasePart")) or not gui:FindFirstChildWhichIsA("ScrollingFrame", true) then
		return
	end
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then
		return
	end
	moved[gui] = panel
	gui.Adornee = panel
	gui.ResetOnSpawn = false
	gui.Parent = pg
	panel.AncestryChanged:Connect(function()
		if not panel:IsDescendantOf(game) and moved[gui] then
			moved[gui] = nil
			gui:Destroy()
		end
	end)
end

function BoardScroll.start()
	if not Config.BOARD_SCROLL then
		return
	end
	for _, d in Workspace:GetDescendants() do
		if d.Name == "Board" then
			take(d)
		end
	end
	Workspace.DescendantAdded:Connect(function(d)
		if d.Name == "Board" then
			task.defer(take, d) -- (its ScrollingFrame may arrive a moment after it)
			task.delay(1, take, d)
		end
	end)
end

return BoardScroll
