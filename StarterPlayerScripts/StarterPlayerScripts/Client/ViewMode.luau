--!strict
-- Which view the player is in.
--   "Player" (default): you are your avatar, like in every big ragdoll game on Roblox. Standard
--            movement (WASD / thumbstick + jump) and the standard third-person camera; you grab
--            and throw from your character.
--   "Lab":   the optional orbit camera over the lab. The avatar stands still; one finger orbits,
--            pinch zooms, and taps act wherever you point.

local UserInputService = game:GetService("UserInputService")
local isStudio = game:GetService("RunService"):IsStudio()

export type Mode = "Player" | "Lab"

local ViewMode = {}

local mode: Mode = "Player"
local listeners: { (Mode) -> () } = {}

function ViewMode.get(): Mode
	return mode
end

function ViewMode.isLab(): boolean
	return mode == "Lab"
end

function ViewMode.set(new: Mode)
	if new == mode then
		return
	end
	mode = new
	for _, listener in listeners do
		task.spawn(listener, new)
	end
end

function ViewMode.onChanged(listener: (Mode) -> ())
	table.insert(listeners, listener)
end

-- A phone or tablet without a mouse: thumbstick, jump button and screen-centre aiming.
function ViewMode.isTouch(): boolean
	-- (Studio only: the device simulator keeps the PC mouse, so a phone there reads as a touch laptop;
	-- the workspace attribute DevTouch makes it a real phone for screenshots.)
	if isStudio and workspace:GetAttribute("DevTouch") == true then
		return UserInputService.TouchEnabled
	end
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- F70 (owner: "Fjern keybind (J) fra gaven på tlf"; Config.PHONE_NO_KEYS): ONE rule for every key letter on the HUD: a
-- keyboard and no touch screen. Any touch screen (a phone, an iPad with a keyboard, the Studio emulator) shows none.
function ViewMode.showKeys(): boolean
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
	if Config.PHONE_NO_KEYS then
		return UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled and not ViewMode.isTouch()
	end
	return UserInputService.KeyboardEnabled and not ViewMode.isTouch()
end

return ViewMode
