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

local player = Players.LocalPlayer
local bubbles: { Bubble } = {}
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

-- One physics step. Only bodies this client simulates (attribute SimulatedBy = our UserId): writing
-- anyone else's would only fight the network. The state is kept per BODY, not per assembly: a body
-- that goes limp or gets up splits or merges its assemblies, and that must never scale it twice.
-- Its speed is scaled once on the way in and once on the way out (each assembly once, then).
local seenBody: { [Model]: boolean } = {}
local function capped(v: Vector3, most: number): Vector3
	return if v.Magnitude > most then v.Unit * most else v
end

-- V9-2c: in a time bubble, gravity itself runs at s^2: a VectorForce on every part of the body (made
-- on this screen, which simulates it), so a split or a merge never changes the sum. Every controller
-- and joint acts as anywhere (ActiveRagdoll walks and lifts at the bubble's time: the model's local
-- TimeScale); a hard knock in one step (> IMPULSE studs/s) is slowed to s of itself, or in a fast
-- bubble sped up s times (but never a landing: it would bounce the body off the floor).
SlowMotion.IMPULSE = 6 -- studs/s in one step that reads as a knock, not as gravity or a joint
SlowMotion.BODIES_MAX = { low = 8, mid = 14, high = 22 } -- bodies one bubble times on this device

type BodyState = { scale: number, timeBubble: boolean, last: { [BasePart]: Vector3 }, lastSpin: { [BasePart]: Vector3 } }
local bodyStates: { [Model]: BodyState } = {}

local function rootsOf(body: Model): { BasePart }
	local out: { BasePart } = {}
	local seenRoot: { [BasePart]: boolean } = {}
	for _, part in body:GetChildren() do
		local root = if part:IsA("BasePart") then part.AssemblyRootPart else nil
		if root and not seenRoot[root] and not root.Anchored then
			seenRoot[root] = true
			table.insert(out, root)
		end
	end
	return out
end

local function setForces(body: Model, s: number?)
	for _, part in body:GetChildren() do
		if part:IsA("BasePart") then
			local f = part:FindFirstChild("TimeForce")
			if s == nil then
				if f then
					f:Destroy()
				end
				local a = part:FindFirstChild("TimeAttach")
				if a then
					a:Destroy()
				end
			elseif not part.Massless then
				if not (f and f:IsA("VectorForce")) then
					local a = Instance.new("Attachment")
					a.Name = "TimeAttach"
					a.Parent = part
					local nf = Instance.new("VectorForce")
					nf.Name = "TimeForce"
					nf.Attachment0 = a
					nf.RelativeTo = Enum.ActuatorRelativeTo.World
					nf.ApplyAtCenterOfMass = true
					nf.Parent = part
					f = nf
				end
				(f :: VectorForce).Force = Vector3.new(0, part:GetMass() * Workspace.Gravity * (1 - (s :: number) ^ 2), 0)
			end
		end
	end
	body:SetAttribute("TimeScale", s) -- (local: ActiveRagdoll here walks and lifts at it)
end

-- Its speed from one time to another (into a bubble, out of it, or a speed change), once per assembly.
local function rescale(body: Model, k: number)
	for _, root in rootsOf(body) do
		root.AssemblyLinearVelocity = capped(root.AssemblyLinearVelocity * k, SlowMotion.RESTORE_MAX)
		root.AssemblyAngularVelocity = capped(root.AssemblyAngularVelocity * k, SlowMotion.SPIN_MAX)
	end
end

local function leave(body: Model, st: BodyState)
	bodyStates[body] = nil
	if body.Parent then
		if st.timeBubble then
			setForces(body, nil)
		end
		rescale(body, 1 / st.scale)
	end
end

local function stepBodies(_dt: number)
	local folder = Workspace:FindFirstChild("Dummies")
	table.clear(seenBody)
	if folder and #bubbles > 0 then
		local me = player.UserId
		-- (V8-1.2: your own body too, as much as the dummies: it is simulated here as well.)
		local bodies = folder:GetChildren()
		local own = player.Character
		if (Config :: any).REACTIONS_V8 and own then
			table.insert(bodies, own)
		end
		local most = SlowMotion.BODIES_MAX[FeelV2.tier] or 14
		local counts: { [Bubble]: number } = {}
		for _, body in bodies do
			local pelvis = body:FindFirstChild("LowerTorso")
			local b = if body:IsA("Model") and pelvis and pelvis:IsA("BasePart") and (body:GetAttribute("SimulatedBy") == me or body == own) then bubbleAt(pelvis.Position) else nil
			-- (V9-2c: a time bubble leaves the players' own walking speed alone, and times at most
			-- BODIES_MAX bodies on this device; the old spell's bubble times all.)
			if b and b.timeBubble and body:FindFirstChildOfClass("Humanoid") and Players:GetPlayerFromCharacter(body) then
				b = nil
			end
			if b and b.timeBubble then
				local n = (counts[b] or 0) + 1
				if n > most and not bodyStates[body :: Model] then
					b = nil
				else
					counts[b] = n
				end
			end
			if b then
				local model = body :: Model
				local s = b.scale
				seenBody[model] = true
				if s < 1 then
					addTrail(model)
				end
				local st = bodyStates[model]
				if not st or st.scale ~= s or st.timeBubble ~= b.timeBubble then
					-- On the way in (or the speed or the kind of bubble changed): its speed to the
					-- bubble's time, once; the forces for this bubble (none for the old spell's).
					local from = if st then st.scale else 1
					rescale(model, s / from)
					if b.timeBubble then
						setForces(model, s)
					elseif st and st.timeBubble then
						setForces(model, nil)
					end
					st = { scale = s, timeBubble = b.timeBubble, last = {}, lastSpin = {} }
					bodyStates[model] = st
				end
				local state = st :: BodyState
				local last, lastSpin = {}, {}
				for _, root in rootsOf(model) do
					local v, w = root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
					-- (A new assembly (a split, a merge) starts from where it is: never scaled again.)
					local lv, lw = state.last[root] or v, state.lastSpin[root] or w
					local nv, nw = v, w
					if state.timeBubble then
						local dv = v - lv
						if dv.Magnitude > SlowMotion.IMPULSE then
							local landing = lv.Y < -5 and dv.Y > 0
							if s < 1 then
								nv = lv + dv * s
							elseif not landing then
								nv = capped(lv + dv * s, SlowMotion.RESTORE_MAX)
							end
						end
					else
						-- The old spell's bubble: each step keeps s of what the physics changed.
						nv = lv + (v - lv) * s
						nw = lw + (w - lw) * s
					end
					if nv ~= v then
						root.AssemblyLinearVelocity = nv
					end
					if nw ~= w then
						root.AssemblyAngularVelocity = nw
					end
					last[root], lastSpin[root] = nv, nw
				end
				state.last, state.lastSpin = last, lastSpin
			end
		end
	end
	-- Out of every bubble: its speed back (capped both ways), its forces and trail gone.
	for body, st in bodyStates do
		if not seenBody[body] then
			leave(body, st)
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
		-- (Only where this screen is: a bubble in a lab hidden from it (PlotPrivacy) never floats there.)
		local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local Zones = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Zones")) :: any
		local here = mine ~= nil and mine:IsA("BasePart") and Zones.plotAt((mine :: BasePart).Position) == Zones.plotAt(at)
		v.shell.Transparency = if here and b.scale ~= 1 then (if lowEnd then 0.5 else 0.15) else 1
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
	if (Config :: any).BOWL_SLOWMO then
		-- (BOWLING_12 rest, Config.BOWL_SLOWMO: the bowled ragdoll bursts out of its ball into the pins (the server clears
		-- its Curl right there): a short slow moment round the pins, so the strike reads)
		task.spawn(function()
			local curled: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
			while true do
				task.wait(0.15)
				local folder = Workspace:FindFirstChild("Dummies")
				if folder then
					for _, m in folder:GetChildren() do
						if m:IsA("Model") then
							local on = m:GetAttribute("Curl") == true
							if on then
								curled[m] = true
							elseif curled[m] then
								curled[m] = nil
								local pe = m:FindFirstChild("LowerTorso")
								if pe and pe:IsA("BasePart") and pe.AssemblyLinearVelocity.Magnitude > 12 and not calmMotion() then
									SlowMotion.moment(pe.Position, 14, 1.2)
								end
							end
						end
					end
				end
			end
		end)
	end
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
		if #bubbles > 0 or next(bodyStates) or next(trails) then
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
