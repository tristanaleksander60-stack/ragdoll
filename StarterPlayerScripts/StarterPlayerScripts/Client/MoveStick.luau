--!strict
-- 11 Nov 2026 (owner: "you shoot when you walk on mobile"): Roblox's move stick does not sink its
-- touch, so the finger that walks also reached the gun. MoveStick.has(input) says whether a touch
-- started on the move stick (its frame in TouchGui, or the screen's lower left if that is not
-- found); such a touch only walks (LabCamera, Crosshair).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MoveStick = {}

local MARGIN = 8 -- px around the stick's frame

-- `pos` in GUI coordinates (InputObject.Position, below the top bar inset).
function MoveStick.at(pos: Vector2, inLab: boolean?): boolean
	local gui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local touchGui = gui and gui:FindFirstChild("TouchGui")
	local controls = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	if touchGui and touchGui:IsA("ScreenGui") and controls then
		if not touchGui.Enabled then
			return false
		end
		for _, name in { "DynamicThumbstickFrame", "ThumbstickFrame" } do
			local frame = controls:FindFirstChild(name)
			if frame and frame:IsA("GuiObject") and frame.Visible then
				local a, s = frame.AbsolutePosition, frame.AbsoluteSize
				if pos.X >= a.X - MARGIN and pos.X <= a.X + s.X + MARGIN and pos.Y >= a.Y - MARGIN and pos.Y <= a.Y + s.Y + MARGIN then
					return true
				end
			end
		end
		return false
	end
	local size = Workspace.CurrentCamera.ViewportSize
	return not inLab and pos.X < size.X * 0.4 and pos.Y > size.Y * 0.45
end

function MoveStick.has(input: InputObject, inLab: boolean?): boolean
	return input.UserInputType == Enum.UserInputType.Touch and MoveStick.at(Vector2.new(input.Position.X, input.Position.Y), inLab)
end

return MoveStick
