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

local Knockables = {}

-- role -> density of its body (a barrel heavier than a cone)
Knockables.ROLES = table.freeze({ Barrel = 0.55, Crate = 0.7, Cone = 0.3, Block = 0.3 }) :: { [string]: number }
-- V9-NOW 11 (owner, 21 Nov 2026: "the big target blocks topple when shot"): a Block is tall and heavy: a shot gives it
-- only BLOCK_SHOT studs/s and a tip (no hop), so a few hits rock it over; it lands with a heavy thud and dust,
-- and can knock its neighbour. A shot must land on it (its box, BLOCK_MARGIN), not just near it.
Knockables.BLOCK_SHOT = 3.2 -- studs/s a shot pushes a block
Knockables.BLOCK_TIP = 0.42 -- rad/s of tip per stud/s of push (the top goes first)
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
}

local entries: { [BasePart]: Entry } = {}
local started = false

local function goHome(e: Entry)
	e.looseAt = nil
	e.stillSince = nil
	e.body.Anchored = true
	e.body.AssemblyLinearVelocity = Vector3.zero
	e.body.AssemblyAngularVelocity = Vector3.zero
	e.model:PivotTo(e.home) -- (its pivot is the body: the welded pieces come along)
	e.model:SetAttribute("Loose", nil)
	e.fell = nil
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
		-- (A block rocks over, it does not hop: the push tips its top the way it was pushed.)
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		if flat.Magnitude > 0.01 then
			body.AssemblyAngularVelocity += Vector3.yAxis:Cross(flat.Unit) * flat.Magnitude * Knockables.BLOCK_TIP
		end
		body.AssemblyLinearVelocity += velocity
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
