--!strict
-- NOW 1.5 (owner, 26 Nov 2026: "fjern Free Gift notifikationer osv fra tlf"): on a phone or tablet the
-- screen shows only the target, SHOOT, the hotbar and one goal line. Config.PHONE_QUIET.
--   PhoneQuiet.on()  true on a touch screen with no keyboard (phones and tablets; PC and consoles keep
--                    today's notices)
-- Used by Notify (no pop-ups), IconCount (no red badges), HudV3 (no GIFT button, REVIVE only when
-- down) and WhatsNew (never opens by itself).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local PhoneQuiet = {}

function PhoneQuiet.on(): boolean
	if not Config.PHONE_QUIET then
		return false
	end
	-- (Studio's device emulator: the workspace attribute DevTouch counts as a phone, like ViewMode.)
	local dev = game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevTouch") == true
	return dev or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
end

return PhoneQuiet
