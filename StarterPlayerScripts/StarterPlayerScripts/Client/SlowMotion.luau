--!strict
-- v4 C5 (owner: "slow-mo, much better"). Roblox has no time scale for physics, so slow motion is
-- built on this screen from what works:
--   * Bodies: every frame, each part of a body inside a slow-mo bubble keeps only SCALE of the
--     speed change the physics step gave it (gravity, hits, bumps), and its speed is cut to SCALE
--     on the way in and given back on the way out. So bodies fall and tumble slowly instead of
--     stopping dead (the old way, on the server, cut speed 10 times a second: it stuttered).
--     The lab's bodies are simulated by the lab's player, so writing their speed here is what
--     everyone then sees; a body this client does not simulate just ignores it.
--   * Feel, while the camera is near a bubble: a cool colour grade, a light blur (not on phones), a
--     vignette, the field of view easing in, game sounds dropping in pitch (a PitchShift on the
--     Effects group), a low heartbeat, and speed trails on the slowed bodies (not on phones).
--     Everything eases in and out.
--   * A big hit near you (FeelBus "BigHit") gets a short automatic slow moment round it, at most
--     once per Config.SLOWMO_AUTO_GAP seconds.
-- The bubbles: ToyService's Slowmo (the spell, the Z key and the Lab window's SLOW-MO) tags its
-- bubble "SlowmoBubble" with attributes Radius and Ends. Config.SLOWMO_V2 (off = the old way).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Client = script.Parent
local Settings = require(Client:WaitForChild("Settings"))
local FeelBus = require(Client:WaitForChild("FeelBus"))
local FeelV2 = require(Client:WaitForChild("FeelV2"))

local SlowMotion = {}

local C = Config :: any
SlowMotion.SCALE = C.SLOWMO_SCALE or 0.25 -- how fast time runs in a bubble
SlowMotion.FEEL_REACH = 30 -- studs past a bubble's edge where the camera still feels it
SlowMotion.EASE = 0.35 -- s to ease the feel in or out
SlowMotion.RESTORE_MAX = 90 -- studs/s: a body leaving a bubble gets its speed back up to this
SlowMotion.SPIN_MAX = 30 -- rad/s: and its spin up to this
SlowMotion.AUTO_RADIUS = 12
SlowMotion.AUTO_TIME = 0.9
SlowMotion.AUTO_GAP = C.SLOWMO_AUTO_GAP or 8
SlowMotion.AUTO_STRENGTH = 0.95 -- a BigHit at least this strong
SlowMotion.TRAILS_MAX = 6

type Bubble = { centre: Vector3, radius: number, ends: number, part: BasePart? }
type Slowed = { last: Vector3, lastSpin: Vector3 }

local player = Players.LocalPlayer
local bubbles: { Bubble } = {}
local slowed: { [BasePart]: Slowed } = {}
local trails: { [Model]: Trail } = {}
local amount = 0 -- 0..1 the feel, eased
local lastAuto = -math.huge
local heartAt = 0

local grade: ColorCorrectionEffect? = nil
local blur: BlurEffect? = nil
local pitch: PitchShiftSoundEffect? = nil
local vignette: ScreenGui? = nil

local lowEnd = FeelV2.tier == "low"

local function inside(position: Vector3): boolean
	for _, b in bubbles do
		if (position - b.centre).Magnitude <= b.radius then
			return true
		end
	end
	return false
end

local function feelTarget(camPos: Vector3): number
	local best = 0
	for _, b in bubbles do
		local d = (camPos - b.centre).Magnitude - b.radius
		local k = if d <= 0 then 1 else math.clamp(1 - d / SlowMotion.FEEL_REACH, 0, 1)
		best = math.max(best, k)
	end
	return best
end

local function buildFeel()
	local g = Instance.new("ColorCorrectionEffect")
	g.Name = "SlowMotionGrade"
	g.Enabled = false
	g.Parent = Lighting
	grade = g
	if not lowEnd then
		local b = Instance.new("BlurEffect")
		b.Name = "SlowMotionBlur"
		b.Size = 0
		b.Enabled = false
		b.Parent = Lighting
		blur = b
	end
	local p = Instance.new("PitchShiftSoundEffect")
	p.Name = "SlowMotionPitch"
	p.Octave = 1
	p.Enabled = false
	p.Priority = 5
	p.Parent = Settings.effects()
	pitch = p
	-- The vignette: four soft dark edges.
	local gui = Instance.new("ScreenGui")
	gui.Name = "SlowMotionVignette"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -5
	gui.Enabled = false
	for _, side in { { 0, Vector2.new(0, 0), UDim2.fromScale(1, 0.22) }, { 180, Vector2.new(0, 1), UDim2.fromScale(1, 0.22) }, { 90, Vector2.new(1, 0), UDim2.fromScale(0.16, 1) }, { 270, Vector2.new(0, 0), UDim2.fromScale(0.16, 1) } } do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.fromRGB(8, 10, 24)
		f.AnchorPoint = side[2] :: Vector2
		f.Position = UDim2.fromScale((side[2] :: Vector2).X, (side[2] :: Vector2).Y)
		f.Size = side[3] :: UDim2
		local gr = Instance.new("UIGradient")
		gr.Rotation = (side[1] :: number) + 90
		gr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
		gr.Parent = f
		f.Parent = gui
	end
	gui.Parent = player:WaitForChild("PlayerGui")
	vignette = gui
end

-- Reduced motion: Settings LESS, or AUTO with the device's own reduced-motion setting on.
local function calmMotion(): boolean
	local pick = Settings.MOTION[Settings.get().motion]
	if pick and pick.reduced ~= nil then
		return pick.reduced == true
	end
	local ok, on = pcall(function()
		return game:GetService("GuiService").ReducedMotionEnabled
	end)
	return ok and on == true
end

local function applyFeel(k: number)
	local on = k > 0.01

	local calm = calmMotion() -- (reduced motion: no FOV move, no blur, a lighter vignette)
	if grade then
		grade.Enabled = on
		grade.Saturation = -0.45 * k
		grade.Contrast = 0.1 * k
		grade.Brightness = -0.03 * k
		grade.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(205, 222, 255), k)
	end
	if blur then
		blur.Enabled = on and not calm
		blur.Size = 3 * k
	end
	if pitch then
		pitch.Enabled = on
		pitch.Octave = 1 - 0.32 * k
	end
	if vignette then
		vignette.Enabled = on
		for _, f in vignette:GetChildren() do
			if f:IsA("Frame") then
				f.BackgroundTransparency = 1 - (if calm then 0.4 else 0.85) * k
			end
		end
	end
	FeelV2.fovBeat = if calm then 0 else -9 * k
end

local function addTrail(body: Model)
	if lowEnd or trails[body] then
		return
	end
	local n = 0
	for _ in trails do
		n += 1
	end
	if n >= SlowMotion.TRAILS_MAX then
		return
	end
	local chest = body:FindFirstChild("UpperTorso")
	if not (chest and chest:IsA("BasePart")) then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "SlowTrailA"
	a0.Position = Vector3.new(0, 0.6, 0)
	a0.Parent = chest
	local a1 = Instance.new("Attachment")
	a1.Name = "SlowTrailB"
	a1.Position = Vector3.new(0, -0.6, 0)
	a1.Parent = chest
	local t = Instance.new("Trail")
	t.Name = "SlowTrail"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = 0.45
	t.MinLength = 0.2
	t.FaceCamera = true
	t.LightEmission = 0.4
	t.Color = ColorSequence.new(Color3.fromRGB(190, 215, 255))
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	t.Parent = chest
	trails[body] = t
end

local function dropTrail(body: Model)
	local t = trails[body]
	trails[body] = nil
	if t then
		local a0, a1 = t.Attachment0, t.Attachment1
		t:Destroy()
		if a0 then
			a0:Destroy()
		end
		if a1 then
			a1:Destroy()
		end
	end
end

-- One physics step: every slowed assembly keeps SCALE of what the step changed. Only bodies this
-- client simulates (attribute SimulatedBy = our UserId): writing anyone else's would only fight
-- the network. Each assembly is touched once (its root part), never once per part.
local seen: { [BasePart]: boolean } = {}
local seenBody: { [Model]: boolean } = {}
local function stepBodies()
	local s = SlowMotion.SCALE
	local folder = Workspace:FindFirstChild("Dummies")
	table.clear(seen)
	table.clear(seenBody)
	if folder and #bubbles > 0 then
		local me = player.UserId
		for _, body in folder:GetChildren() do
			local pelvis = body:FindFirstChild("LowerTorso")
			if body:IsA("Model") and pelvis and pelvis:IsA("BasePart") and body:GetAttribute("SimulatedBy") == me and inside(pelvis.Position) then
				seenBody[body] = true
				addTrail(body)
				for _, part in body:GetChildren() do
					local root = if part:IsA("BasePart") then part.AssemblyRootPart else nil
					if root and not seen[root] and not root.Anchored then
						seen[root] = true
						local v, w = root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
						local st = slowed[root]
						if not st then
							-- On the way in: its speed drops to the bubble's time.
							local nv, nw = v * s, w * s
							root.AssemblyLinearVelocity = nv
							root.AssemblyAngularVelocity = nw
							slowed[root] = { last = nv, lastSpin = nw }
						else
							local nv = st.last + (v - st.last) * s
							local nw = st.lastSpin + (w - st.lastSpin) * s
							root.AssemblyLinearVelocity = nv
							root.AssemblyAngularVelocity = nw
							st.last = nv
							st.lastSpin = nw
						end
					end
				end
			end
		end
	end
	-- Out of every bubble: its speed back (capped both ways), its trail gone.
	for root, _ in slowed do
		if not seen[root] then
			slowed[root] = nil
			if root.Parent and not root.Anchored then
				local back = root.AssemblyLinearVelocity / s
				if back.Magnitude > SlowMotion.RESTORE_MAX then
					back = back.Unit * SlowMotion.RESTORE_MAX
				end
				local spin = root.AssemblyAngularVelocity / s
				if spin.Magnitude > SlowMotion.SPIN_MAX then
					spin = spin.Unit * SlowMotion.SPIN_MAX
				end
				root.AssemblyLinearVelocity = back
				root.AssemblyAngularVelocity = spin
			end
		end
	end
	for body in trails do
		if not seenBody[body] then
			dropTrail(body)
		end
	end
end

local function addBubble(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local radius = (part:GetAttribute("Radius") :: number?) or part.Size.X / 2
	local ends = (part:GetAttribute("Ends") :: number?) or (Workspace:GetServerTimeNow() + 6)
	local b: Bubble = { centre = part.Position, radius = radius, ends = ends, part = part }
	table.insert(bubbles, b)
	-- The way in: a low whoosh.
	local cam = Workspace.CurrentCamera
	if FeelV2.play and cam and (cam.CFrame.Position - b.centre).Magnitude < radius + SlowMotion.FEEL_REACH then
		(FeelV2.play :: any)("whoosh", b.centre, 0.6, 0.4)
	end
end

-- A short slow moment round a point on this screen only (a big hit).
function SlowMotion.moment(at: Vector3, radius: number?, seconds: number?)
	table.insert(bubbles, { centre = at, radius = radius or SlowMotion.AUTO_RADIUS, ends = Workspace:GetServerTimeNow() + (seconds or SlowMotion.AUTO_TIME), part = nil })
end

function SlowMotion.activeForTest(): number
	return #bubbles
end

function SlowMotion.start()
	if not C.SLOWMO_V2 then
		return
	end
	buildFeel()
	for _, p in CollectionService:GetTagged("SlowmoBubble") do
		addBubble(p)
	end
	CollectionService:GetInstanceAddedSignal("SlowmoBubble"):Connect(addBubble)
	CollectionService:GetInstanceRemovedSignal("SlowmoBubble"):Connect(function(p)
		for i = #bubbles, 1, -1 do
			if bubbles[i].part == p then
				table.remove(bubbles, i)
			end
		end
	end)
	FeelBus.on("BigHit", function(data: any)
		if type(data) ~= "table" or typeof(data.position) ~= "Vector3" then
			return
		end
		local now = os.clock()
		if not calmMotion() and (tonumber(data.strength) or 0) >= SlowMotion.AUTO_STRENGTH and now - lastAuto >= SlowMotion.AUTO_GAP then
			lastAuto = now
			SlowMotion.moment(data.position)
		end
	end)
	RunService.PreSimulation:Connect(function()
		local now = Workspace:GetServerTimeNow()
		for i = #bubbles, 1, -1 do
			local b = bubbles[i]
			if now >= b.ends or (b.part ~= nil and b.part.Parent == nil) then
				table.remove(bubbles, i)
			end
		end
		if #bubbles > 0 or next(slowed) or next(trails) then
			stepBodies()
		end
	end)
	RunService.RenderStepped:Connect(function(dt: number)
		local cam = Workspace.CurrentCamera
		local target = if cam then feelTarget(cam.CFrame.Position) else 0
		local rate = dt / SlowMotion.EASE
		amount = if target > amount then math.min(target, amount + rate) else math.max(target, amount - rate)
		if amount > 0.001 or (grade and grade.Enabled) then
			applyFeel(amount)
		end
		-- A low heartbeat while it lasts.
		if amount > 0.6 and os.clock() >= heartAt and FeelV2.play and cam then
			heartAt = os.clock() + 0.85;
			(FeelV2.play :: any)("land", cam.CFrame.Position + cam.CFrame.LookVector * 4, 0.22, 0.45)
		end
	end)
end

return SlowMotion
