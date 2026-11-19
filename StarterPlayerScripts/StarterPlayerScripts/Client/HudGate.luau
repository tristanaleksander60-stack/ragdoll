--!strict
-- LOOK_V3: whether the big ragdoll games' HUD (HudV3) is on for this screen now. Its own module so
-- the pieces that step aside for it (HudPlus, ChaosMeter, EventShop) can ask without a require
-- loop through HudV3.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local HudSlots = require(script.Parent:WaitForChild("HudSlots"))
local ViewMode = require(script.Parent:WaitForChild("ViewMode"))

local HudGate = {}

-- On: LOOK_V3 and not a phone (a phone keeps the round 5 HUD, measured by LayoutCheck).
function HudGate.active(): boolean
	if not Config.LOOK_V3 then
		return false
	end
	return not HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()).phone
end

return HudGate
