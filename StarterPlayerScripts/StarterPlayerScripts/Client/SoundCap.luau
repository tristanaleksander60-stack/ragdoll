--!strict
-- SoundCap (LAG-FREE 2 item 6, Config.LAGFREE_SOUNDS; PERF_MOBILE §6): sounds are played from about 60 places, so
-- rather than change each one this watches the sounds in the world (Workspace, not the UI's own clicks):
--   * a sound that starts farther away than it can be heard (its RollOffMaxDistance) is stopped at once;
--   * on a phone at most 12 world sounds play together (tablet 16, PC 32): a new one past the cap stops the
--     farthest one that is playing (the new one wins only when it is nearer).
-- Looping sounds (ambience) are never touched. Nothing runs while it is quiet: it only acts on a sound's Played signal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local SoundCap = {}

local playing: { [Sound]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local watched: { [Sound]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function capNow(): number
	local dev = tostring(Players.LocalPlayer:GetAttribute("Device"))
	if dev == "phone" then
		return 12
	elseif dev == "tablet" then
		return 16
	elseif dev == "pc" or dev == "console" then
		return 32
	end
	return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then 12 else 32
end

local function where(s: Sound): Vector3?
	local p = s.Parent
	if p and p:IsA("BasePart") then
		return p.Position
	elseif p and p:IsA("Attachment") then
		return p.WorldPosition
	end
	return nil -- (a sound with no place is heard everywhere: never stopped for distance)
end

local function distance(s: Sound): number
	local cam = Workspace.CurrentCamera
	local at = where(s)
	if not (cam and at) then
		return 0
	end
	return (at - cam.CFrame.Position).Magnitude
end

local function onPlayed(s: Sound)
	if s.Looped then
		return -- (a looping ambience is never stopped: it would not come back when you walk nearer)
	end
	local d = distance(s)
	if d > 0 and d > s.RollOffMaxDistance + 5 then
		s:Stop() -- (too far to be heard: never started)
		return
	end
	local count, far, farD = 0, nil :: Sound?, -1
	for other in playing do
		if other.Parent == nil or not other.IsPlaying or other.Looped then
			playing[other] = nil
		else
			count += 1
			local od = distance(other)
			if od > farD then
				far, farD = other, od
			end
		end
	end
	if count >= capNow() then
		if far and farD > d then
			playing[far] = nil
			far:Stop()
		else
			s:Stop()
			return
		end
	end
	playing[s] = true
end

local function watch(d: Instance)
	if d:IsA("Sound") and not watched[d] then
		watched[d] = true
		d.Played:Connect(function()
			pcall(onPlayed, d)
		end)
		d.Ended:Connect(function()
			playing[d] = nil
		end)
		d.Stopped:Connect(function()
			playing[d] = nil
		end)
	end
end

function SoundCap.start()
	if not Config.LAGFREE_SOUNDS then
		return
	end
	for _, d in Workspace:GetDescendants() do
		watch(d)
	end
	Workspace.DescendantAdded:Connect(watch)
end

return SoundCap
