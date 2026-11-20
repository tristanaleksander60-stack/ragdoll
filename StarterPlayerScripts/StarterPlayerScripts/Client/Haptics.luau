--!strict
-- V8-1.5 (sounds that reward, Config.AUDIO_V8): a short buzz on the moments that already have a sound
-- (a KO, a landing, the cannon), on a pad and on a phone where Roblox supports it. Off with Settings'
-- Motion LESS. Every call is safe on a device with no motor.

local HapticService = game:GetService("HapticService")
local UserInputService = game:GetService("UserInputService")

local Haptics = {}

local function reducedMotion(): boolean
	local ok, Settings = pcall(function()
		return require(script.Parent:WaitForChild("Settings")) :: any
	end)
	return ok and type(Settings.get) == "function" and Settings.get().motion == 2
end

local function target(): Enum.UserInputType?
	local last = UserInputService:GetLastInputType()
	if string.sub(last.Name, 1, 7) == "Gamepad" then
		return last
	end
	if UserInputService.TouchEnabled then
		return Enum.UserInputType.Touch
	end
	return nil
end

-- A buzz of `strength` (0-1) for `seconds`.
function Haptics.pulse(strength: number, seconds: number)
	local kind = target()
	if not kind or reducedMotion() then
		return
	end
	pcall(function()
		if not HapticService:IsVibrationSupported(kind) then
			return
		end
		local motor = Enum.VibrationMotor.Small
		if not HapticService:IsMotorSupported(kind, motor) then
			motor = Enum.VibrationMotor.Large
		end
		HapticService:SetMotor(kind, motor, math.clamp(strength, 0, 1))
		task.delay(seconds, function()
			pcall(function()
				HapticService:SetMotor(kind, motor, 0)
			end)
		end)
	end)
end

return Haptics
