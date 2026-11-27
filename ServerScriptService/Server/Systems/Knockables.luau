--!strict
-- UI audit 21 Nov 2026 (the owner: "everything 3D and interactive"): the lab's barrels, crates and
-- cones were scenery a flying dummy passed through. Now each one is a thing: a flying dummy, a car,
-- a running player, a shot or a blast knocks it over and away (barrels roll), and it goes back to
-- its spot by itself once it has lain still a while (and at once on RESET).
--   At rest a knockable is anchored (it costs nothing); a hit unanchors it (the server simulates it)
--   and pushes it. Visible pieces are
--   welded to one invisible body (a cylinder for a barrel, a box otherwise) that does the physics.
-- A leaf: Blasts, HitService, LabDress and SandboxService call in; it requires nothing of the game.

local RunService = game:GetService("RunService")
local CRATE_BURST = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).CRATE_BURST == true

local Knockables = {}

-- role -> density of its body (a barrel heavier than a cone)
Knockables.ROLES = table.freeze({ Barrel = 0.55, Crate = 0.7, Cone = 0.3, Block = 0.3 }) :: { [string]: number }
-- V9-NOW 11 (owner, 21 Nov 2026: "the big target blocks topple when shot"): a Block is tall and heavy: a shot gives it
-- only BLOCK_SHOT studs/s and a tip (no hop), so a few hits rock it over; it lands with a heavy thud and dust,
-- and can knock its neighbour. A shot must land on it (its box, BLOCK_MARGIN), not just near it.
Knockables.BLOCK_SHOT = 3.2 -- (a shot's push: only its direction counts for a block, see BLOCK_WOBBLE)
Knockables.BLOCK_WOBBLE = 8 -- studs/s of the block's mass pushed at its top by one shot: it rocks (about 6 degrees)
Knockables.BLOCK_TOPPLE = 16 -- the same for the push that tips it over (measured: 13 tips a 9 x 12.8 x 7 block)
Knockables.BLOCK_HITS = 4 -- shots within BLOCK_MEMORY s that topple it
Knockables.BLOCK_MEMORY = 2.5
Knockables.BLOCK_HARD = 20 -- studs/s: a push this hard (a car, a thrown body, a blast) topples it at once
Knockables.BLOCK_MARGIN = 0.8 -- studs round its box that still count as on it
Knockables.FALLEN_TILT = 55 -- degrees off upright: it fell (the thud)
Knockables.KNOCK_SPEED = 14 -- studs/s: a touch at least this fast (relative) knocks it
Knockables.CARRY = 0.6 -- share of the toucher's speed it takes
Knockables.LIFT = 10 -- studs/s up on every knock (it hops, it does not slide)
Knockables.SHOT_REACH = 2.5 -- studs from a shot's point to the body's surface
Knockables.SHOT_SPEED = 26 -- studs/s a shot gives
Knockables.BLAST_SPEED = 70 -- studs/s right at a blast's middle (less at its edge)
Knockables.REST_SPEED = 1.5 -- studs/s: slower than this counts as lying still
Knockables.RETURN_AFTER = 10 -- s lying still before it goes back
Knockables.RETURN_MAX = 30 -- s loose before it goes back whatever it does
Knockables.FALL_LIMIT = 40 -- studs under its spot: fell off the world, goes back now
Knockables.TOUCH_GAP = 0.25 -- s between two knocks from touches

type Entry = {
	model: Model,
	body: BasePart,
	home: CFrame,
	looseAt: number?,
	stillSince: number?,
	lastKnock: number,
	role: string,
	fell: boolean?,
	hits: number?,
	hitAt: number?,
}

-- (24 Nov 2026: others that want to hear of shots, blasts and resets: Scaffolds.)
Knockables.listeners = {} :: { { shot: (Vector3, Vector3) -> (), blast: (Vector3, number) -> (), reset: (Vector3, number) -> () } }
local entries: { [BasePart]: Entry } = {}
local started = false

-- Row 7 (Config.CRATE_BURST; IMPACT_FX "props react"): a body flung through a crate fast (CRATE_BURST_SPEED studs/s)
-- smashes it: the crate's pieces vanish, 6-8 planks fly out with a crack and wood dust, and the body flies on through
-- (the crate's body stops blocking). It comes back whole on its spot with the others (goHome).
Knockables.CRATE_BURST_SPEED = 40
local burstLooks: { [Entry]: { [BasePart]: number } } = setmetatable({}, { __mode = "k" }) :: any
local CRACK_ID = "rbxassetid://9116785204"
local function burst(e: Entry, other: BasePart)
	if burstLooks[e] then
		return
	end
	local looks: { [BasePart]: number } = {}
	local color = Color3.fromRGB(170, 120, 70)
	for _, d in e.model:GetDescendants() do
		if d:IsA("BasePart") and d ~= e.body then
			looks[d] = d.Transparency
			color = d.Color
			d.Transparency = 1
		end
	end
	burstLooks[e] = looks
	local body = e.body
	body.CanCollide = false
	body.Anchored = true
	e.looseAt = e.looseAt or os.clock()
	e.model:SetAttribute("Loose", true)
	local at = body.Position
	local push = other.AssemblyLinearVelocity
	for i = 1, math.random(6, 8) do
		local plank = Instance.new("Part")
		plank.Name = "CratePlank"
		plank.Size = Vector3.new(math.random(18, 30) / 10, 0.25, math.random(5, 8) / 10)
		plank.Color = color
		plank.Material = Enum.Material.WoodPlanks
		plank.CanQuery, plank.CanTouch, plank.CastShadow = false, false, false
		plank.CFrame = CFrame.new(at + Vector3.new(math.random(-10, 10) / 10, math.random(-5, 10) / 10, math.random(-10, 10) / 10))
			* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		plank.AssemblyLinearVelocity = push * 0.35 + Vector3.new(math.random(-12, 12), math.random(8, 18), math.random(-12, 12))
		plank.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
		plank.Parent = workspace
		game:GetService("Debris"):AddItem(plank, 5 + i * 0.2)
	end
	local s = Instance.new("Sound")
	s.SoundId = CRACK_ID
	s.Volume = 1.1
	s.PlaybackSpeed = 0.8
	s.RollOffMaxDistance = 110
	s.Parent = body
	s:Play()
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(196, 170, 130))
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	dust.Lifetime = NumberRange.new(0.6, 1.1)
	dust.Speed = NumberRange.new(5, 12)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Rate = 0
	dust.Parent = body
	dust:Emit(22)
	task.delay(3, function()
		s:Destroy()
		dust:Destroy()
	end)
end

local function goHome(e: Entry)
	local looks = burstLooks[e]
	if looks then
		burstLooks[e] = nil
		for d, t in looks do
			if d.Parent then
				d.Transparency = t
			end
		end
		e.body.CanCollide = true
	end
	e.looseAt = nil
	e.stillSince = nil
	e.body.Anchored = true
	e.body.AssemblyLinearVelocity = Vector3.zero
	e.body.AssemblyAngularVelocity = Vector3.zero
	e.model:PivotTo(e.home) -- (its pivot is the body: the welded pieces come along)
	e.model:SetAttribute("Loose", nil)
	e.fell = nil
	e.hits = 0
end

-- V9-NOW 11: a fallen block lands with a heavy thud and a puff of dust (on every screen: a server sound and emitter).
local THUD_IDS = { "rbxassetid://9113480917", "rbxassetid://9113525391" } -- (SoundManifest land: PSE body falls)
local function thud(body: BasePart)
	local s = Instance.new("Sound")
	s.SoundId = THUD_IDS[math.random(1, #THUD_IDS)]
	s.Volume = 1.2
	s.PlaybackSpeed = 0.62 -- (lower: a heavy block, not a body)
	s.RollOffMaxDistance = 120
	s.Parent = body
	s:Play()
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(205, 196, 178))
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
	dust.Lifetime = NumberRange.new(0.8, 1.4)
	dust.Speed = NumberRange.new(4, 9)
	dust.SpreadAngle = Vector2.new(80, 20)
	dust.Rate = 0
	dust.Parent = body
	dust:Emit(18)
	task.delay(3, function()
		s:Destroy()
		dust:Destroy()
	end)
end

-- Knocks a knockable with this velocity change (studs/s).
local function knock(e: Entry, velocity: Vector3)
	local now = os.clock()
	e.lastKnock = now
	e.stillSince = nil
	local body = e.body
	if not e.looseAt then
		e.looseAt = now
		body.Anchored = false
		e.model:SetAttribute("Loose", true)
		-- (The server keeps it: a few light things, and the push a touch gave is never lost in a hand-over.)
		pcall(function()
			body:SetNetworkOwner(nil)
		end)
	end
	if e.role == "Block" then
		-- (A block rocks, it never hops: a push at its top (the ground holds its foot, a turn about its centre
		-- alone is cancelled by the floor). Shots rock it; the BLOCK_HITS-th within BLOCK_MEMORY s, or one hard
		-- push, tips it over.)
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		if flat.Magnitude > 0.01 then
			if now - (e.hitAt or -math.huge) > Knockables.BLOCK_MEMORY then
				e.hits = 0
			end
			e.hits = (e.hits or 0) + 1
			e.hitAt = now
			local hard = flat.Magnitude >= Knockables.BLOCK_HARD or (e.hits :: number) >= Knockables.BLOCK_HITS
			local k = if hard then Knockables.BLOCK_TOPPLE else Knockables.BLOCK_WOBBLE
			local top = body.Position + body.CFrame.UpVector * body.Size.Y * 0.45
			body:ApplyImpulseAtPosition(flat.Unit * body.AssemblyMass * k, top)
		end
		return
	end
	local spin = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 10
	body.AssemblyLinearVelocity += velocity + Vector3.new(0, Knockables.LIFT, 0)
	body.AssemblyAngularVelocity += spin
end

local function onTouched(e: Entry, other: BasePart)
	if other.Anchored or other:IsDescendantOf(e.model) then
		return
	end
	local now = os.clock()
	if now - e.lastKnock < Knockables.TOUCH_GAP then
		return
	end
	local relative = other.AssemblyLinearVelocity - e.body.AssemblyLinearVelocity
	local speed = relative.Magnitude
	if speed < Knockables.KNOCK_SPEED then
		return
	end
	if e.role == "Crate" and speed >= Knockables.CRATE_BURST_SPEED and CRATE_BURST then
		local m = other:FindFirstAncestorOfClass("Model")
		if m and m.Parent and m.Parent.Name == "Dummies" then
			e.lastKnock = now
			burst(e, other)
			return
		end
	end
	if burstLooks[e] then
		return -- (smashed: nothing left to knock)
	end
	knock(e, relative * Knockables.CARRY)
end

-- Turns a placed model (V3Assets.place) into a knockable; `role` picks its weight. Nothing happens
-- for a role that is not knockable.
function Knockables.make(model: Model, role: string)
	local density = Knockables.ROLES[role]
	if not density then
		return
	end
	local cf, size = model:GetBoundingBox()
	local body = Instance.new("Part")
	body.Name = "KnockBody"
	body.Transparency = 1
	body.Anchored = true
	body.CanCollide = true
	body.CanTouch = true
	body.CanQuery = true
	body.CastShadow = false
	body.CustomPhysicalProperties = PhysicalProperties.new(density, 0.6, 0.35)
	if role == "Barrel" then
		-- (A cylinder lies along X: turned upright, so a knocked barrel rolls.)
		local across = math.min(size.X, size.Z)
		body.Shape = Enum.PartType.Cylinder
		body.Size = Vector3.new(size.Y, across, across)
		body.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	else
		body.Size = size * Vector3.new(0.92, 1, 0.92)
		body.CFrame = cf
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = d
			weld.Parent = body
		end
	end
	body.Parent = model
	model.PrimaryPart = body
	model:SetAttribute("Knockable", role)
	local e: Entry = { model = model, body = body, home = body.CFrame, looseAt = nil, stillSince = nil, lastKnock = 0, role = role }
	entries[body] = e
	body.Touched:Connect(function(other: BasePart)
		onTouched(e, other)
	end)
	model.Destroying:Connect(function()
		entries[body] = nil
	end)
	Knockables.start()
end

-- A blast: everything in reach flies away from its middle (Blasts.blast).
function Knockables.blast(center: Vector3, radius: number)
	for _, l in Knockables.listeners do
		l.blast(center, radius)
	end
	for body, e in entries do
		local offset = body.Position - center
		local d = offset.Magnitude
		if d < radius then
			local falloff = 1 - d / radius
			local dir = if d > 0.01 then offset.Unit else Vector3.yAxis
			knock(e, (dir + Vector3.new(0, 0.6, 0)).Unit * Knockables.BLAST_SPEED * falloff)
		end
	end
end

-- A shot that landed at `point`, fired from `from` (HitService's Shot): the knockable it hit jumps.
function Knockables.shot(point: Vector3, from: Vector3): boolean
	for _, l in Knockables.listeners do
		l.shot(point, from)
	end
	for body, e in entries do
		local half = body.Size.Magnitude / 2
		if e.role == "Block" then
			local l = body.CFrame:PointToObjectSpace(point)
			local s = body.Size / 2 + Vector3.one * Knockables.BLOCK_MARGIN
			if math.abs(l.X) <= s.X and math.abs(l.Y) <= s.Y and math.abs(l.Z) <= s.Z then
				local dir = point - from
				knock(e, (if dir.Magnitude > 0.01 then dir.Unit else Vector3.zAxis) * Knockables.BLOCK_SHOT)
				return true
			end
		elseif (body.Position - point).Magnitude <= half + Knockables.SHOT_REACH then
			local dir = point - from
			knock(e, (if dir.Magnitude > 0.01 then dir.Unit else Vector3.zAxis) * Knockables.SHOT_SPEED)
			return true
		end
	end
	return false
end

-- Everything loose within `radius` of `center` back on its spot (RESET in a lab).
function Knockables.resetNear(center: Vector3, radius: number): number
	for _, l in Knockables.listeners do
		l.reset(center, radius)
	end
	local n = 0
	for _, e in entries do
		if e.looseAt and (e.home.Position - center).Magnitude <= radius then
			goHome(e)
			n += 1
		end
	end
	return n
end

-- Tests: every knockable (body -> its model) and a knock by hand.
function Knockables.all(): { [BasePart]: Model }
	local out = {}
	for body, e in entries do
		out[body] = e.model
	end
	return out
end
function Knockables.knockForTest(body: BasePart, velocity: Vector3)
	local e = entries[body]
	if e then
		knock(e, velocity)
	end
end
function Knockables.isLoose(body: BasePart): boolean
	local e = entries[body]
	return e ~= nil and e.looseAt ~= nil
end
function Knockables.sendHomeForTest(body: BasePart)
	local e = entries[body]
	if e then
		goHome(e)
	end
end

-- The watch: loose ones that lie still go home after RETURN_AFTER s (RETURN_MAX at most, at once
-- when they fell off the world). Twice a second; nothing to do while all are home.
function Knockables.start()
	if started then
		return
	end
	started = true
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 then
			return
		end
		acc = 0
		local now = os.clock()
		for _, e in entries do
			local loose = e.looseAt
			if loose then
				local body = e.body
				if e.role == "Block" and not e.fell and body.CFrame.UpVector.Y < math.cos(math.rad(Knockables.FALLEN_TILT)) then
					e.fell = true
					thud(body)
				end
				if body.Position.Y < e.home.Position.Y - Knockables.FALL_LIMIT or now - loose > Knockables.RETURN_MAX then
					goHome(e)
				elseif body.AssemblyLinearVelocity.Magnitude < Knockables.REST_SPEED then
					e.stillSince = e.stillSince or now
					if now - (e.stillSince :: number) > Knockables.RETURN_AFTER then
						goHome(e)
					end
				else
					e.stillSince = nil
				end
			end
		end
	end)
end

return Knockables
