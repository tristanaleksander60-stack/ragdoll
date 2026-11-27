--!strict
-- OVERVIEW 8 PHONES: the AUTOMATIC QUALITY GOVERNOR (docs/PERF_MOBILE.md 3; Config.AUTO_QUALITY): on this screen only.
--   * The start level comes from the device: PC 3, tablet 2, phone 2 (console 3). It never goes above that.
--   * Every second it counts the frames; under 45 FPS for 10 s it steps DOWN one level, over 58 for 30 s it steps UP.
--   * Each step lowers, in this order: (2) the path walkers' far animation and the particles (rates halved), (1) the
--     shadows and the far lights, (0) fewer path walkers shown and fewer real hands (fingers only up close).
--   * Never touched: your own hit's splatter, the ragdolls you hit, the machine you use, the goal line, the dog
--     (nothing here hides or stops those; particle RATES are lowered, never turned off).
-- The level is on the player as attribute "Quality" (0-3) for any module that wants it.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local QualityGovernor = {}

QualityGovernor.LOW_FPS, QualityGovernor.LOW_FOR = 45, 10
QualityGovernor.HIGH_FPS, QualityGovernor.HIGH_FOR = 58, 30

local level = 3
local top = 3
local rates: { [ParticleEmitter]: number } = setmetatable({}, { __mode = "k" }) :: any
local shadows0: boolean? = nil

local function client(name: string): any
	local folder = script.Parent
	local m = folder and folder:FindFirstChild(name)
	if m and m:IsA("ModuleScript") then
		local ok, mod = pcall(require, m)
		if ok then
			return mod
		end
	end
	return nil
end

local function particles(scale: number)
	for _, d in Workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			if rates[d] == nil then
				rates[d] = d.Rate
			end
			d.Rate = (rates[d] :: number) * scale
		end
	end
end

local function apply(l: number)
	level = l
	Players.LocalPlayer:SetAttribute("Quality", l)
	-- (2) particles and far walker animation
	particles(if l <= 2 then 0.5 else 1)
	local walkers = client("PathWalkers")
	if walkers then
		walkers.MID = if l <= 2 then 110 else 160
		walkers.NEAR = if l <= 2 then 60 else 80
		walkers.LIMIT = if l <= 0 then 8 else 999
	end
	-- (1) shadows and far lights
	if shadows0 == nil then
		shadows0 = Lighting.GlobalShadows
	end
	Lighting.GlobalShadows = if l <= 1 then false else shadows0 :: boolean
	local guard = client("LagGuard")
	if guard then
		guard.LIGHT_RANGE = if l <= 1 then 80 else 140
	end
	-- (0) fewer real hands
	local hands = client("RealHands")
	if hands then
		hands.MAX_BODIES = if l <= 0 then 6 elseif l <= 1 then 10 else 14
		hands.ANIM_REACH = if l <= 0 then 22 else 40
	end
end

function QualityGovernor.level(): number
	return level
end

function QualityGovernor.start()
	if not Config.AUTO_QUALITY then
		return
	end
	local player = Players.LocalPlayer
	task.spawn(function()
		-- the device's start level (the server sets Device a moment after join)
		for _ = 1, 20 do
			if player:GetAttribute("Device") ~= nil then
				break
			end
			task.wait(0.5)
		end
		local dev = tostring(player:GetAttribute("Device"))
		top = if dev == "phone" or dev == "tablet" then 2 else 3
		apply(top)
		local frames = 0
		RunService.RenderStepped:Connect(function()
			frames += 1
		end)
		local lowFor, highFor = 0, 0
		while true do
			frames = 0
			task.wait(1)
			-- (row 8: the Settings choice: LOW holds level 0, HIGH holds the device's top; AUTO steps by the frame rate)
			local choice = player:GetAttribute("QualityChoice")
			if choice == "Low" or choice == "High" then
				local want = if choice == "Low" then 0 else top
				if level ~= want then
					apply(want)
				end
				continue
			end
			local fps = frames
			if fps < QualityGovernor.LOW_FPS then
				lowFor += 1
				highFor = 0
			elseif fps > QualityGovernor.HIGH_FPS then
				highFor += 1
				lowFor = 0
			else
				lowFor, highFor = 0, 0
			end
			if lowFor >= QualityGovernor.LOW_FOR and level > 0 then
				apply(level - 1)
				lowFor = 0
			elseif highFor >= QualityGovernor.HIGH_FOR and level < top then
				apply(level + 1)
				highFor = 0
			end
		end
	end)
end

return QualityGovernor
