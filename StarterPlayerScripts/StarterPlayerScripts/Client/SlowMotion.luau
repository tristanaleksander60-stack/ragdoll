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
SlowMotion.RESTORE_MAX = if (Config :: any).REACTIONS_V8 then 230 else 90 -- studs/s: a body leaving a bubble gets its speed back up to this (V8-1.2: no 90 cap; 230 = the launch cap)
SlowMotion.SPIN_MAX = 30 -- rad/s: and its spin up to this
SlowMotion.AUTO_RADIUS = 12
SlowMotion.AUTO_TIME = 0.9
SlowMotion.AUTO_GAP = C.SLOWMO_AUTO_GAP or 8
SlowMotion.AUTO_STRENGTH = 0.95 -- a BigHit at least this strong
SlowMotion.TRAILS_MAX = 6

-- (V9-2c: a bubble has its own speed `scale` (0.1x-3x); a time bubble (`timeBubble`) follows its
-- owner, and inside it time runs truly at `scale`: speeds x scale, gravity x scale^2.)
type Bubble = { centre: Vector3, radius: number, ends: number, part: BasePart?, scale: number, timeBubble: boolean, owner: number? }
type Slowed = { last: Vector3, lastSpin: Vector3, scale: number, timeBubble: boolean }

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

-- The bubble a point is in (nil: none). A time bubble at 1x does nothing.
local function bubbleAt(position: Vector3): Bubble?
	for _, b in bubbles do
		if b.scale ~= 1 and (position - b.centre).Magnitude <= b.radius then
			return b
		end
	end
	return nil
end

local function feelTarget(camPos: Vector3): number
	local best = 0
	for _, b in bubbles do
		if b.scale >= 1 then
			continue -- (the slow-mo look is for slow time only: a fast bubble has its own colour)
		end
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
local function capped(v: Vector3, most: number): Vector3
	return if v.Magnitude > most then v.Unit * most else v
end

-- V9-2c: in a time bubble, gravity itself runs at s^2 (a VectorForce on each of the body's assemblies,
-- made on this screen, which simulates it): every controller and joint of the body then acts as it
-- does anywhere, and only a hard knock in one step (a hit, a landing: more than IMPULSE studs/s) is
-- slowed to s of itself. Fast bubbles never amplify a knock (it would bounce bodies off the floor).
SlowMotion.IMPULSE = 6 -- studs/s in one step that reads as a knock, not as gravity or a joint

local function timeForce(root: BasePart, s: number): VectorForce
	local force = root:FindFirstChild("TimeForce")
	if not (force and force:IsA("VectorForce")) then
		local a = Instance.new("Attachment")
		a.Name = "TimeAttach"
		a.Parent = root
		local f = Instance.new("VectorForce")
		f.Name = "TimeForce"
		f.Attachment0 = a
		f.RelativeTo = Enum.ActuatorRelativeTo.World
		f.ApplyAtCenterOfMass = true
		f.Parent = root
		force = f
	end
	local vf = force :: VectorForce
	vf.Force = Vector3.new(0, root.AssemblyMass * Workspace.Gravity * (1 - s * s), 0)
	return vf
end

local function dropForce(root: BasePart)
	local f = root:FindFirstChild("TimeForce")
	if f then
		f:Destroy()
	end
	local a = root:FindFirstChild("TimeAttach")
	if a then
		a:Destroy()
	end
end

local function stepBodies(_dt: number)
	local folder = Workspace:FindFirstChild("Dummies")
	table.clear(seen)
	table.clear(seenBody)
	if folder and #bubbles > 0 then
		local me = player.UserId
		-- (V8-1.2: your own body too, as much as the dummies: it is simulated here as well.)
		local bodies = folder:GetChildren()
		local own = player.Character
		if (Config :: any).REACTIONS_V8 and own then
			table.insert(bodies, own)
		end
		for _, body in bodies do
			local pelvis = body:FindFirstChild("LowerTorso")
			local b = if body:IsA("Model") and pelvis and pelvis:IsA("BasePart") and (body:GetAttribute("SimulatedBy") == me or body == own) then bubbleAt(pelvis.Position) else nil
			-- (V9-2c: a time bubble leaves the players' own walking speed alone.)
			if b and not (b.timeBubble and body:FindFirstChildOfClass("Humanoid") and Players:GetPlayerFromCharacter(body)) then
				local s = b.scale
				seenBody[body] = true
				if s < 1 then
					addTrail(body)
				end
				for _, part in body:GetChildren() do
					local root = if part:IsA("BasePart") then part.AssemblyRootPart else nil
					if root and not seen[root] and not root.Anchored then
						seen[root] = true
						local v, w = root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
						local st = slowed[root]
						if not st or st.scale ~= s or st.timeBubble ~= b.timeBubble then
							-- On the way in (or the speed changed): its speed to the bubble's time.
							local from = if st then st.scale else 1
							local nv = capped(v * (s / from), SlowMotion.RESTORE_MAX)
							local nw = capped(w * (s / from), SlowMotion.SPIN_MAX)
							root.AssemblyLinearVelocity = nv
							root.AssemblyAngularVelocity = nw
							slowed[root] = { last = nv, lastSpin = nw, scale = s, timeBubble = b.timeBubble }
							if b.timeBubble then
								timeForce(root, s)
							end
						elseif b.timeBubble then
							timeForce(root, s) -- (its mass can change: a limb lost or a gadget stuck on)
							local dv = v - st.last
							local nv = v
							if s < 1 and dv.Magnitude > SlowMotion.IMPULSE then
								nv = st.last + dv * s
							end
							nv = capped(nv, SlowMotion.RESTORE_MAX)
							if nv ~= v then
								root.AssemblyLinearVelocity = nv
							end
							st.last = nv
							st.lastSpin = w
						else
							-- The old spell's bubble: each step keeps s of what the physics changed.
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
	for root, st in slowed do
		if not seen[root] then
			slowed[root] = nil
			local s = st.scale
			dropForce(root)
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
	local timeBubble = part:GetAttribute("TimeBubble") == true
	local b: Bubble = {
		centre = part.Position,
		radius = radius,
		ends = ends,
		part = part,
		scale = (part:GetAttribute("Scale") :: number?) or SlowMotion.SCALE,
		timeBubble = timeBubble,
		owner = part:GetAttribute("Owner") :: number?,
	}
	table.insert(bubbles, b)
	-- (V9-2c: a time bubble's speed and size change while it lasts, and every screen draws it.)
	if timeBubble then
		part.AttributeChanged:Connect(function()
			b.scale = (part:GetAttribute("Scale") :: number?) or b.scale
			b.radius = (part:GetAttribute("Radius") :: number?) or b.radius
		end)
		SlowMotion.drawTimeBubble(b)
	end
	-- The way in: a low whoosh.
	local cam = Workspace.CurrentCamera
	if FeelV2.play and cam and (cam.CFrame.Position - b.centre).Magnitude < radius + SlowMotion.FEEL_REACH then
		(FeelV2.play :: any)("whoosh", b.centre, 0.6, 0.4)
	end
end

-- V9-2c: a time bubble on every screen: a clear shimmering sphere round its owner (ForceField), blue
-- when slow, orange when fast, with a soft rim; it follows the owner every frame and eases to a new
-- size. A simpler, fainter one on low-end devices.
SlowMotion.SLOW_COLOR = Color3.fromRGB(110, 190, 255)
SlowMotion.FAST_COLOR = Color3.fromRGB(255, 160, 60)
local timeVisuals: { [Bubble]: { shell: BasePart, rim: BasePart?, size: number } } = {}

function SlowMotion.drawTimeBubble(b: Bubble)
	local folder = Workspace:FindFirstChild("TimeBubbles") or Instance.new("Folder")
	folder.Name = "TimeBubbles"
	folder.Parent = Workspace
	local function ball(name: string, material: Enum.Material, transparency: number): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = material
		p.Transparency = transparency
		p.Size = Vector3.one * b.radius * 2
		p.CFrame = CFrame.new(b.centre)
		p.Parent = folder
		return p
	end
	local shell = ball("TimeShell", Enum.Material.ForceField, if lowEnd then 0.5 else 0.15)
	local rim: BasePart? = nil -- (a glass rim drew as a faceted white shape: the shimmering shell alone reads best)
	timeVisuals[b] = { shell = shell, rim = rim, size = b.radius * 2 }
end

local function owners(b: Bubble): Vector3?
	local owner = if b.owner then Players:GetPlayerByUserId(b.owner) else nil
	local root = owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function drawTimeBubbles(dt: number)
	for b, v in timeVisuals do
		if not table.find(bubbles, b) then
			v.shell:Destroy()
			if v.rim then
				v.rim:Destroy()
			end
			timeVisuals[b] = nil
			continue
		end
		local at = owners(b) or b.centre
		b.centre = at
		v.size += (b.radius * 2 - v.size) * math.min(1, dt * 6)
		local colour = if b.scale < 1 then SlowMotion.SLOW_COLOR elseif b.scale > 1 then SlowMotion.FAST_COLOR else Color3.fromRGB(220, 230, 240)
		v.shell.Size = Vector3.one * v.size
		v.shell.CFrame = CFrame.new(at)
		v.shell.Color = colour
		if v.rim then
			v.rim.Size = Vector3.one * (v.size + 0.4)
			v.rim.CFrame = CFrame.new(at)
			v.rim.Color = colour
		end
	end
end

-- A short slow moment round a point on this screen only (a big hit).
function SlowMotion.moment(at: Vector3, radius: number?, seconds: number?)
	table.insert(bubbles, { centre = at, radius = radius or SlowMotion.AUTO_RADIUS, ends = Workspace:GetServerTimeNow() + (seconds or SlowMotion.AUTO_TIME), part = nil, scale = SlowMotion.SCALE, timeBubble = false, owner = nil })
end

-- V6-3 (director): one lasting bubble that follows a point (the camera's focus) until released;
-- no 3 s renewals, so no jolt, and nothing else (an auto moment) blocks it.
local directorBubble: Bubble? = nil
function SlowMotion.director(at: Vector3?, radius: number?)
	if at == nil then
		if directorBubble then
			directorBubble.ends = 0 -- (gone at the next physics step)
			directorBubble = nil
		end
		return
	end
	local b = directorBubble
	if b then
		b.centre = at
		b.radius = radius or b.radius
	else
		local new: Bubble = { centre = at, radius = radius or 90, ends = math.huge, part = nil, scale = SlowMotion.SCALE, timeBubble = false, owner = nil }
		table.insert(bubbles, new)
		directorBubble = new
	end
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
	RunService.PreSimulation:Connect(function(dt: number)
		local now = Workspace:GetServerTimeNow()
		for i = #bubbles, 1, -1 do
			local b = bubbles[i]
			if now >= b.ends or (b.part ~= nil and b.part.Parent == nil) then
				table.remove(bubbles, i)
			elseif b.timeBubble then
				b.centre = owners(b) or b.centre -- (V9-2c: round its owner, this very step)
			end
		end
		if #bubbles > 0 or next(slowed) or next(trails) then
			stepBodies(dt)
		end
	end)
	RunService.RenderStepped:Connect(function(dt: number)
		if next(timeVisuals) then
			drawTimeBubbles(dt)
		end
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
