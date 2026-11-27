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
-- (LAG-FREE 2 item 4, Config.LAGFREE_BUDGET: smarter steps: down after 5 s under 40, or 3 frames over 50 ms within 5 s;
-- up only after 45 s over 58. Every number by level is in Config.PERF_LEVELS; get(key) reads it, Changed fires.)
local BUDGET = Config.LAGFREE_BUDGET == true
if BUDGET then
	QualityGovernor.LOW_FPS, QualityGovernor.LOW_FOR = 40, 5
	QualityGovernor.HIGH_FOR = 45
end
local changed = Instance.new("BindableEvent")
QualityGovernor.Changed = changed.Event

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

-- (LAG-FREE 2 items 0-1: the level goes to the server (PerfReport) when it changes, at most once per 5 s; the server's
-- caps follow it. A client attribute never replicates, so the server never knew a phone was struggling.)
local sentLevel: number? = nil
local levelSendAt = 0
local function report(kind: string, data: any)
	pcall(function()
		local r = ReplicatedStorage:FindFirstChild("Remotes")
		local e = r and r:FindFirstChild("PerfReport")
		if e and e:IsA("RemoteEvent") then
			e:FireServer(kind, data)
		end
	end)
end
local function sendLevel()
	if not Config.LAGFREE_SERVER_KNOWS or sentLevel == level then
		return
	end
	local wait = levelSendAt + 5 - os.clock()
	if wait > 0 then
		task.delay(wait + 0.05, sendLevel)
		return
	end
	levelSendAt = os.clock()
	sentLevel = level
	report("Level", level)
end

local function apply(l: number)
	level = l
	Players.LocalPlayer:SetAttribute("Quality", l)
	sendLevel()
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
	-- (LAG-FREE 2 items 3-4: the smooth skin's reach and far rate by level)
	if BUDGET and Config.PERF_LEVELS and Config.PERF_LEVELS[l] then
		local row = Config.PERF_LEVELS[l]
		local sb = client("SmoothBody")
		if sb and row.skinReach then
			sb.ANIM_REACH = row.skinReach
			sb.FAR_RATE = 1 / row.skinRate
		end
	end
	changed:Fire(l)
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

-- A number for this level from Config.PERF_LEVELS (nil when there is none).
function QualityGovernor.get(key: string): any
	local levels = Config.PERF_LEVELS
	local row = levels and levels[level]
	return row and row[key]
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
		-- (LAG-FREE 2 item 4: a phone already over 1200 MB at join starts one level lower; never in Studio)
		local startAt = top
		if BUDGET and dev == "phone" and not RunService:IsStudio() and game:GetService("Stats"):GetTotalMemoryUsageMb() > 1200 then
			startAt = math.min(top, 1)
		end
		apply(startAt)
		local frames = 0
		local hitches = 0
		RunService.RenderStepped:Connect(function(dt)
			frames += 1
			if dt > 0.05 then
				hitches += 1
			end
		end)
		-- (LAG-FREE 2 item 0, Config.LAGFREE_TELEMETRY: the minute's numbers to the server once a minute)
		local samples: { number } = {}
		if Config.LAGFREE_TELEMETRY then
			task.spawn(function()
				while true do
					task.wait(60)
					if #samples >= 10 then
						local sorted = table.clone(samples)
						table.sort(sorted)
						local bodies = 0
						local dummies = Workspace:FindFirstChild("Dummies")
						for _, m in if dummies then dummies:GetChildren() else {} do
							local pe = m:FindFirstChild("LowerTorso")
							if pe and pe:IsA("BasePart") and not pe.Anchored and pe.ReceiveAge == 0 then
								bodies += 1 -- (this device simulates it)
							end
						end
						report("Stats", {
							p50 = sorted[math.ceil(#sorted * 0.5)],
							p10 = sorted[math.max(1, math.ceil(#sorted * 0.1))],
							hitches = hitches,
							mem = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()),
							bodies = bodies,
							level = level,
						})
					end
					table.clear(samples)
					hitches = 0
				end
			end)
		end
		local lowFor, highFor = 0, 0
		local hitchWindow: { number } = {}
		local hitchSeen = 0
		local bornAt, hitchStepAt = os.clock(), 0
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
			if #samples < 120 then
				table.insert(samples, fps)
			end
			if fps < QualityGovernor.LOW_FPS then
				lowFor += 1
				highFor = 0
			elseif fps > QualityGovernor.HIGH_FPS then
				highFor += 1
				lowFor = 0
			else
				lowFor, highFor = 0, 0
			end
			-- (LAG-FREE 2 item 4: 3 hitches (frames over 50 ms) within 5 s also step down, not only a low average)
			if hitches < hitchSeen then
				hitchSeen = 0 -- (the 60 s report reset the count)
			end
			table.insert(hitchWindow, hitches - hitchSeen)
			hitchSeen = hitches
			if #hitchWindow > 5 then
				table.remove(hitchWindow, 1)
			end
			local recent = 0
			for _, n in hitchWindow do
				recent += n
			end
			-- (not in the first 30 s: loading the world hitches on every device; and at most one hitch step per 10 s)
			if BUDGET and recent >= 3 and level > 0 and os.clock() - bornAt > 30 and os.clock() - hitchStepAt > 10 then
				hitchStepAt = os.clock()
				apply(level - 1)
				table.clear(hitchWindow)
				lowFor, highFor = 0, 0
				continue
			end
			if lowFor >= QualityGovernor.LOW_FOR and level > 0 and (not BUDGET or os.clock() - bornAt > 30) then
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
