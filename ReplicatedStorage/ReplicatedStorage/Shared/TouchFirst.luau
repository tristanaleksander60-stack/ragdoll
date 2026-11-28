--!strict
-- TouchFirst (Config.TOUCH_FIRST_DEVICE): is this screen a phone or tablet (touch first)? The phone-only rules
-- (X-RAY_BUTTON_TOUCH_ONLY, MORE_GEAR_PC_ONLY, MP_SHORT_LABEL, HOTBAR_ICON_CENTER) asked "TouchEnabled and not
-- KeyboardEnabled". That is false on a tablet with a keyboard and in Studio's phone emulator (it reports a keyboard),
-- so those rules never switched on there. The game already knows the device: the player's "Device" attribute ("phone",
-- "tablet", "pc", "console"), from the client's own visit report (SessionStats). This reads that first, and falls back
-- to touch-without-keyboard until it arrives. onChange(cb) calls cb again whenever the answer may have changed.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local TouchFirst = {}

function TouchFirst.get(): boolean
	if Config.TOUCH_FIRST_DEVICE then
		local p = Players.LocalPlayer
		local d = p and p:GetAttribute("Device")
		if d == "phone" or d == "tablet" then
			return true
		elseif d == "pc" or d == "console" then
			return false
		end
	end
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function TouchFirst.onChange(cb: () -> ())
	UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(cb)
	UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(cb)
	local p = Players.LocalPlayer
	if p then
		p:GetAttributeChangedSignal("Device"):Connect(cb)
	end
end

return TouchFirst
