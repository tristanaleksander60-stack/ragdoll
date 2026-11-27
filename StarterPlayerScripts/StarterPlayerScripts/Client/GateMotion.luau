--!strict
-- OVERVIEW 0.97 (docs/SPAWN_11.md; Config.SPAWN_11): the moving parts of the spawn and the room gates, on this screen only
-- and only within RANGE studs of the camera (the server builds them still; Systems/LabOwnerMap tags them):
--   Chase      a marquee bulb (attribute Idx): the bulbs light in a running pattern;
--   Spin       turns round attribute Axis (a Vector3, through its pivot) or round the vertical line through Around;
--   Bob        floats up and down (Amp, Speed);
--   Swing      sways round a hinge (Pivot: the hinge in its own space; Axis "Y" or the default X; Snap: a jaw);
--   Barrier    a barrier arm that lifts while you are within 14 studs of it;
--   Countdown  a display counting From..0 every Every s; at 0 a smoke puff (LaunchPuff's emitter nearby);
--   Burst      emits its ParticleEmitter (Count) every Every s.
-- Also the first-join camera glide (SPAWN_11 section 1): once, for a newcomer, a 2.5 s glide from high above the welcome
-- arch down to behind the player; any key or tap skips it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local GateMotion = {}

GateMotion.RANGE = 120

local base: { [Instance]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
local lastBurst: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local barrierK: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any

local function pivotOf(x: Instance): CFrame?
	if x:IsA("BasePart") then
		return x.CFrame
	elseif x:IsA("Model") then
		return x:GetPivot()
	end
	return nil
end
local function setPivot(x: Instance, cf: CFrame)
	if x:IsA("BasePart") then
		x.CFrame = cf
	elseif x:IsA("Model") then
		x:PivotTo(cf)
	end
end

local function near(x: Instance, cam: Vector3): boolean
	local cf = base[x] or pivotOf(x)
	return cf ~= nil and (cf.Position - cam).Magnitude < GateMotion.RANGE
end

local function step(t: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local cam = camera.CFrame.Position
	-- (F87: the aquarium's water surface: its textures scroll slowly, Scroll studs a second, near the camera only)
	for _, tex in CollectionService:GetTagged("ScrollTexture") do
		local p = tex.Parent
		if tex:IsA("Texture") and p and p:IsA("BasePart") and (p.Position - cam).Magnitude < 160 then
			local sp = (tex:GetAttribute("Scroll") :: number?) or 1
			tex.OffsetStudsU = (t * sp) % tex.StudsPerTileU
			tex.OffsetStudsV = (t * sp * 0.6) % tex.StudsPerTileV
		end
	end
	for _, b in CollectionService:GetTagged("Chase") do
		if b:IsA("BasePart") and near(b, cam) then
			local idx = (b:GetAttribute("Idx") :: number?) or 0
			local on = (idx + math.floor(t * 6)) % 4 == 0
			b.Transparency = if on then 0 else 0.55
		end
	end
	for _, s in CollectionService:GetTagged("Spin") do
		if near(s, cam) then
			local b0 = base[s] or pivotOf(s)
			if b0 then
				base[s] = b0
				local speed = (s:GetAttribute("Speed") :: number?) or 1
				local around = s:GetAttribute("Around")
				local axis = s:GetAttribute("Axis")
				if typeof(around) == "Vector3" then
					local rel = CFrame.new(around):ToObjectSpace(b0)
					setPivot(s, CFrame.new(around) * CFrame.Angles(0, t * speed, 0) * rel)
				elseif typeof(axis) == "Vector3" then
					setPivot(s, CFrame.new(b0.Position) * CFrame.fromAxisAngle(axis.Unit, t * speed) * (b0 - b0.Position))
				else
					setPivot(s, b0 * CFrame.Angles(0, t * speed, 0))
				end
			end
		end
	end
	for _, s in CollectionService:GetTagged("Bob") do
		if near(s, cam) then
			local b0 = base[s] or pivotOf(s)
			if b0 then
				base[s] = b0
				local amp = (s:GetAttribute("Amp") :: number?) or 0.5
				local speed = (s:GetAttribute("Speed") :: number?) or 1
				setPivot(s, b0 + Vector3.new(0, math.sin(t * speed + b0.X) * amp, 0))
			end
		end
	end
	for _, s in CollectionService:GetTagged("Swing") do
		if near(s, cam) then
			local b0 = base[s] or pivotOf(s)
			if b0 then
				base[s] = b0
				local amp = (s:GetAttribute("Amp") :: number?) or 0.2
				local speed = (s:GetAttribute("Speed") :: number?) or 1
				local pivot = s:GetAttribute("Pivot")
				local p = if typeof(pivot) == "Vector3" then pivot else Vector3.zero
				local wave = math.sin(t * speed + b0.Z)
				if s:GetAttribute("Snap") then
					wave = math.max(0, wave) ^ 0.5 -- (a jaw: open, then snaps shut)
				end
				local a = wave * amp
				local rot = if s:GetAttribute("Axis") == "Y" then CFrame.Angles(0, a, 0) else CFrame.Angles(a, 0, 0)
				setPivot(s, b0 * CFrame.new(p) * rot * CFrame.new(-p))
			end
		end
	end
	local me = Players.LocalPlayer.Character
	local hrp = me and me:FindFirstChild("HumanoidRootPart")
	for _, s in CollectionService:GetTagged("Barrier") do
		if s:IsA("BasePart") and near(s, cam) then
			local b0 = base[s] or s.CFrame
			base[s] = b0
			local pivot = s:GetAttribute("Pivot")
			local p = if typeof(pivot) == "Vector3" then pivot else Vector3.zero
			local hinge = (b0 * CFrame.new(p)).Position
			local want = if hrp and hrp:IsA("BasePart") and (hrp.Position - hinge).Magnitude < 16 then 1 else 0
			local k = barrierK[s] or 0
			k += (want - k) * 0.12
			barrierK[s] = k
			s.CFrame = b0 * CFrame.new(p) * CFrame.Angles(0, 0, k * math.rad(80) * (if p.X < 0 then -1 else 1)) * CFrame.new(-p)
		end
	end
	for _, s in CollectionService:GetTagged("Countdown") do
		if s:IsA("BasePart") and near(s, cam) then
			local every = (s:GetAttribute("Every") :: number?) or 30
			local from = (s:GetAttribute("From") :: number?) or 10
			local left = every - (t % every)
			local label = s:FindFirstChild("Digits", true)
			if label and label:IsA("TextLabel") then
				label.Text = if left <= from then tostring(math.floor(left)) else "--"
			end
			local cycle = math.floor(t / every)
			if lastBurst[s] ~= cycle then
				lastBurst[s] = cycle
				local gate = s.Parent
				local puff = gate and gate:FindFirstChild("LaunchPuff")
				local e = puff and puff:FindFirstChildOfClass("ParticleEmitter")
				if e then
					e:Emit(30)
				end
			end
		end
	end
	for _, s in CollectionService:GetTagged("Burst") do
		if s:IsA("BasePart") and near(s, cam) then
			local every = (s:GetAttribute("Every") :: number?) or 10
			local cycle = math.floor(t / every)
			if lastBurst[s] ~= cycle then
				lastBurst[s] = cycle
				local e = s:FindFirstChildOfClass("ParticleEmitter")
				if e then
					e:Emit((s:GetAttribute("Count") :: number?) or 20)
				end
			end
		end
	end
end

-- The first-join glide: once, for a newcomer.
local function glide()
	local player = Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	task.wait(1.5)
	local until_ = player:GetAttribute("NewcomerUntil")
	if not (hrp and hrp:IsA("BasePart")) or type(until_) ~= "number" or time() >= until_ then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local fromAt = hrp.Position + hrp.CFrame.LookVector * 60 + Vector3.new(0, 70, 0)
	local endCF = CFrame.lookAt(hrp.Position - hrp.CFrame.LookVector * 14 + Vector3.new(0, 7, 0), hrp.Position + hrp.CFrame.LookVector * 30)
	local startCF = CFrame.lookAt(fromAt, hrp.Position + hrp.CFrame.LookVector * 20)
	local skip = false
	local conn = UserInputService.InputBegan:Connect(function()
		skip = true
	end)
	camera.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	while not skip and os.clock() - t0 < 2.5 do
		local a = (os.clock() - t0) / 2.5
		a = a * a * (3 - 2 * a)
		camera.CFrame = startCF:Lerp(endCF, a)
		RunService.RenderStepped:Wait()
	end
	conn:Disconnect()
	camera.CameraType = Enum.CameraType.Custom
end

function GateMotion.start()
	if not Config.SPAWN_11 then
		return
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / 30 then
			return
		end
		acc = 0
		step(os.clock())
	end)
	if Config.SPAWN_GLIDE then
		task.spawn(glide)
	end
end

return GateMotion
