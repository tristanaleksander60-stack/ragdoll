--!strict
-- F65 UN-PARKED (owner: "Benene hakker stadig helt randomly i 1-2 sekunder"; Config.LEG_JITTER_LOG): an always-on, cheap
-- jitter detector on this screen. For every ragdoll within RANGE studs of the camera it counts the knee-angle direction
-- reversals; more than LIMIT a second over WINDOW s is a JITTER event. Then it logs the context (state, role, watch job,
-- pace, parked, how often its Home changed in the last 2 s, who simulates it, its speed, what its feet stand on, the fps)
-- to the output and to the player attribute LegJitterLast, so the cause can be found. One event per ragdoll per 5 s.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local LegJitter = {}

LegJitter.RANGE = 60
LegJitter.LIMIT = 10 -- reversals a second (a fast run makes about 7; real jitter flips nearly every frame)
LegJitter.WINDOW = 0.3

type Track = { last: number?, lastD: number, flips: { number }, homeChanges: { number }, lastLog: number }
local tracks: { [Model]: Track } = setmetatable({}, { __mode = "k" }) :: any
local frameTimes: { number } = {}

local function kneeAngle(m: Model): number?
	local up, low = m:FindFirstChild("LeftUpperLeg"), m:FindFirstChild("LeftLowerLeg")
	if not (up and low and up:IsA("BasePart") and low:IsA("BasePart")) then
		return nil
	end
	local rel = up.CFrame:ToObjectSpace(low.CFrame)
	return math.atan2(rel.LookVector.Y, -rel.LookVector.Z)
end

local function footSurface(m: Model): string
	local foot = m:FindFirstChild("LeftFoot")
	if not (foot and foot:IsA("BasePart")) then
		return "?"
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { m }
	local hit = Workspace:Raycast(foot.Position, Vector3.new(0, -3, 0), params)
	if not hit then
		return "air"
	end
	local inst = hit.Instance
	local model = inst:FindFirstAncestorOfClass("Model")
	return inst.Name .. (if model and model.Parent and model.Parent.Name == "Dummies" then "(another ragdoll)" else "")
end

local function report(m: Model, t: Track, rate: number)
	local now = os.clock()
	local homes = 0
	for _, at in t.homeChanges do
		if now - at < 2 then
			homes += 1
		end
	end
	local fps = 0
	for _, ft in frameTimes do
		fps += ft
	end
	fps = if #frameTimes > 0 then #frameTimes / fps else 0
	local pe = m:FindFirstChild("LowerTorso")
	local speed = if pe and pe:IsA("BasePart") then pe.AssemblyLinearVelocity.Magnitude else 0
	local line = string.format(
		"[LegJitter] %s %.0f rev/s | state=%s role=%s watch=%s pace=%s parked=%s | Home changes in 2 s=%d | sim=%s | speed=%.1f | feet on %s | fps=%.0f",
		m.Name, rate, tostring(m:GetAttribute("RagdollState")), tostring(m:GetAttribute("Role3")), tostring(m:GetAttribute("Watch")),
		tostring(m:GetAttribute("Pace")), tostring(m:GetAttribute("Parked")), homes, tostring(m:GetAttribute("SimulatedBy")), speed, footSurface(m), fps)
	print(line)
	Players.LocalPlayer:SetAttribute("LegJitterLast", line)
	Players.LocalPlayer:SetAttribute("LegJitterCount", ((Players.LocalPlayer:GetAttribute("LegJitterCount") :: number?) or 0) + 1)
end

local function watchModel(m: Instance)
	if not m:IsA("Model") or tracks[m] then
		return
	end
	local t: Track = { last = nil, lastD = 0, flips = {}, homeChanges = {}, lastLog = -math.huge }
	tracks[m] = t
	m:GetAttributeChangedSignal("Home"):Connect(function()
		table.insert(t.homeChanges, os.clock())
		if #t.homeChanges > 40 then
			table.remove(t.homeChanges, 1)
		end
	end)
end

function LegJitter.start()
	if not Config.LEG_JITTER_LOG then
		return
	end
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		for _, m in dummies:GetChildren() do
			watchModel(m)
		end
		dummies.ChildAdded:Connect(watchModel)
		RunService.RenderStepped:Connect(function(dt)
			table.insert(frameTimes, dt)
			if #frameTimes > 30 then
				table.remove(frameTimes, 1)
			end
			local camera = Workspace.CurrentCamera
			if not camera then
				return
			end
			local eye = camera.CFrame.Position
			local now = os.clock()
			for m, t in tracks do
				if not m.Parent then
					tracks[m] = nil
					continue
				end
				local st = m:GetAttribute("RagdollState")
				local pe = m:FindFirstChild("LowerTorso")
				if not (pe and pe:IsA("BasePart")) or (pe.Position - eye).Magnitude > LegJitter.RANGE or not (st == "Standing" or st == "Walking") then
					t.last = nil
					continue
				end
				local ang = kneeAngle(m)
				if ang and t.last then
					local delta = ang - t.last
					if math.abs(delta) > 0.03 then
						if t.lastD ~= 0 and (delta > 0) ~= (t.lastD > 0) then
							table.insert(t.flips, now)
						end
						t.lastD = delta
					end
				end
				t.last = ang
				-- count reversals in the window
				while #t.flips > 0 and now - t.flips[1] > LegJitter.WINDOW do
					table.remove(t.flips, 1)
				end
				local rate = #t.flips / LegJitter.WINDOW
				local fpsNow = 1 / math.max(dt, 1 / 240)
				if rate > LegJitter.LIMIT and rate > fpsNow * 0.7 and now - t.lastLog > 5 then
					t.lastLog = now
					report(m, t, rate)
				end
			end
		end)
	end)
end

return LegJitter
