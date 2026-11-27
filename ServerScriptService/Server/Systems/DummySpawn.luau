--!strict
-- V8-2.5 (dummy types and a SPAWN key, Config.DUMMY_TYPES): a player drops an extra dummy of a type
-- where they aim, in their own lab: MINI (small, flies far), HEAVY (big, hard to move), BOUNCY
-- (bounces off everything) and FLOPPY (light as a pillow). Each wears its type on a chest plate.
-- The server checks every request: a known type, a point in your own lab within REACH of you, one
-- per GAP s, and at most CAP[device] of yours at once (the oldest goes). Reset (SandboxService) and
-- leaving remove them. Remote Net "Spawn": client -> server ("Spawn", type, at).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any

local DummySpawn = {}

DummySpawn.REACH = 80 -- studs from you to the spot
DummySpawn.GAP = 1.5 -- s between two spawns
DummySpawn.CAP = table.freeze({ phone = 3, tablet = 5, pc = 6, console = 6 }) :: { [string]: number }

type Spec = { scale: number, density: number, elasticity: number, color: Color3, plate: string, pace: number? }
DummySpawn.TYPES = table.freeze({
	MINI = { scale = 0.6, density = 0.7, elasticity = 0.3, color = Color3.fromRGB(120, 210, 255), plate = "MINI", pace = 1.4 },
	HEAVY = { scale = 1.3, density = 3, elasticity = 0.1, color = Color3.fromRGB(58, 66, 84), plate = "HEAVY", pace = 0.7 }, -- (V9-0o: dark steel, never the grey of a plain dummy)
	BOUNCY = { scale = 1, density = 0.9, elasticity = 1, color = Color3.fromRGB(255, 140, 220), plate = "BOUNCY", pace = 1.15 },
	FLOPPY = { scale = 1, density = 0.25, elasticity = 0.2, color = Color3.fromRGB(255, 220, 120), plate = "FLOPPY", pace = 0.85 },
}) :: { [string]: Spec }

local mine: { [Player]: { Model } } = {}
local last: { [Player]: number } = {}
local trialUsed: { [Player]: boolean } = {}

-- 21 Nov 2026 (the owner: "a pass called God: it gives access to creating life", Config.GOD_PASS): spawning
-- is GOD MODE's. A player without it gets one free TRIAL s a visit (the first press starts it), then
-- the offer. While the pass is not on sale yet (id 0, live) spawning stays free for everyone, as before.
DummySpawn.TRIAL = 60
DummySpawn.BEAM_SOUND = "rbxassetid://9116394545" -- (Pro Sound Effects "Magic Glows Soft Clusters Of Chiming Hits 1")

function DummySpawn.godGated(): boolean
	if not Config.GOD_PASS then
		return false
	end
	local Shop = require(Shared:WaitForChild("Shop")) :: any
	local pass = Shop.byKey.God
	return pass ~= nil and (pass.id ~= 0 or game:GetService("RunService"):IsStudio())
end

-- Whether a player has GOD MODE: the pass, or (V9-0l) the free beta gift.
function DummySpawn.hasGod(player: Player): boolean
	return player:GetAttribute("God") == true or player:GetAttribute("GodBeta") == true
end

-- Whether a player may create life now: GOD MODE, or the trial running.
function DummySpawn.mayCreate(player: Player): boolean
	if not DummySpawn.godGated() or DummySpawn.hasGod(player) then
		return true
	end
	local untilAt = player:GetAttribute("GodTrialUntil")
	return type(untilAt) == "number" and workspace:GetServerTimeNow() < untilAt
end

-- Someone without GOD MODE creates: in the beta (V9-0l) they get it now (they asked: the moment fits);
-- else the first try starts the free trial. False = refused ("god").
function DummySpawn.letIn(player: Player): boolean
	if Config.GOD_FREE_BETA then
		DummySpawn.grantBeta(player, true)
		return DummySpawn.hasGod(player)
	end
	return DummySpawn.startTrial(player)
end

-- V9-0f: the SHOP card's TRY 60 s: starts the trial for a player without the pass (once a visit).
function DummySpawn.tryFor(player: Player): boolean
	-- (V9-0l: while it is free in the beta there is no trial: everyone gets it.)
	if not DummySpawn.godGated() or DummySpawn.hasGod(player) or Config.GOD_FREE_BETA then
		return false
	end
	return DummySpawn.startTrial(player)
end

-- Starts a player's free trial if it is still unused this visit; true if it started.
function DummySpawn.startTrial(player: Player): boolean
	if trialUsed[player] then
		return false
	end
	trialUsed[player] = true
	player:SetAttribute("GodTrialUntil", workspace:GetServerTimeNow() + DummySpawn.TRIAL)
	pcall(function()
		(require(script.Parent:WaitForChild("ProgressService")) :: any).notice(player, "GOD MODE! " .. DummySpawn.TRIAL .. " seconds to create life")
	end)
	return true
end

-- How many of a player's own may stand at once. (V9-0l: with GOD MODE, what the device's ragdoll
-- budget leaves beside the lab's row, FX_CAPS.ragdolls - 6: room for a 10-line; at least twice the cap.)
local function capFor(player: Player): number
	local SessionStats = require(script.Parent:WaitForChild("SessionStats")) :: any
	local record = SessionStats.recordFor(player)
	local cap = DummySpawn.CAP[record and record.plat or "pc"] or 6
	if not DummySpawn.hasGod(player) then
		return cap
	end
	local DeviceTier = require(Shared:WaitForChild("DeviceTier")) :: any
	local fx = (Config.FX_CAPS :: any)[DeviceTier.of(record and record.plat)]
	return math.max(cap * 2, (if fx then fx.ragdolls else 22) - 6)
end
DummySpawn.capFor = capFor

-- Life comes down from the sky: a beam of light at the spot that fades, sparkles, a chime. (V9-0l: gold
-- for a Founder, who bought GOD MODE; a cool white for the free beta.)
local function beam(at: Vector3, founder: boolean?)
	local p = Instance.new("Part")
	p.Name = "CreationBeam"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(70, 3.2, 3.2)
	p.CFrame = CFrame.new(at + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Material = Enum.Material.Neon
	p.Color = if founder == false then Color3.fromRGB(190, 228, 255) else Color3.fromRGB(255, 226, 120)
	p.Transparency = 0.4
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 240, 170))
	sparkle.LightEmission = 1
	sparkle.LightInfluence = 0
	sparkle.Size = NumberSequence.new(0.5, 0)
	sparkle.Lifetime = NumberRange.new(0.6, 1.2)
	sparkle.Speed = NumberRange.new(4, 9)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Rate = 0
	sparkle.Parent = p
	local chime = Instance.new("Sound")
	chime.SoundId = DummySpawn.BEAM_SOUND
	chime.Volume = 0.6
	chime.RollOffMaxDistance = 120
	chime.Parent = p
	p.Parent = workspace
	sparkle:Emit(30)
	chime:Play()
	game:GetService("TweenService"):Create(p, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1, Size = Vector3.new(70, 0.5, 0.5) }):Play()
	game:GetService("Debris"):AddItem(p, 1.6)
end

local function dress(model: Model, spec: Spec)
	if spec.scale ~= 1 then
		pcall(function()
			model:ScaleTo(spec.scale)
		end)
	end
	-- (V9-P fix round 1: the kind's weight is a factor on the body's own real spread (Config.PHYSICS.MASS,
	-- set by ActiveRagdoll.prepare), not one density on every part; then the body's Mass and StandOffset
	-- are written again, so the forces that hold it up and the hits are sized for what it really weighs.)
	local factor = spec.density / 0.7
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local cur = d.CurrentPhysicalProperties
			d.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(cur.Density * factor, 0.01, 100), cur.Friction, spec.elasticity, cur.FrictionWeight, if spec.elasticity >= 0.9 then 100 else 1)
			-- (V9-0l: the whole body in its kind's colour, as the GOD MODE window shows it; the skins wear
			-- the parts' colour (DummySkins) and the dead green gives it back (VitalsService.paintDead).)
			if d.Parent == model and d.Name ~= "HumanoidRootPart" then
				d.Color = d.Color:Lerp(spec.color, 0.8)
			end
		end
	end
	local mass = 0
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and not d.Massless then
			mass += d.Mass
		end
	end
	if mass > 0 then
		model:SetAttribute("Mass", mass)
	end
	local offset = model:GetAttribute("StandOffset")
	if type(offset) == "number" and spec.scale ~= 1 then
		model:SetAttribute("StandOffset", offset * spec.scale)
	end
	-- (Fix round 2: a rig the server already set up (a body it simulates itself) takes the new weight too.)
	pcall(function()
		(require(game:GetService("ReplicatedStorage").Shared.Ragdoll.ActiveRagdoll) :: any).refreshMass(model)
	end)
	model:SetAttribute("DummyType", spec.plate)
	-- The chest plate: the type in big letters on the chest (a SurfaceGui, so the crowd-style
	-- strip of marks leaves it).
	local chest = model:FindFirstChild("UpperTorso")
	if chest and chest:IsA("BasePart") then
		local gui = Instance.new("SurfaceGui")
		gui.Name = "TypePlate"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(200, 120)
		gui.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(0.9, 0, 0.5, 0)
		t.Position = UDim2.fromScale(0.05, 0.25)
		t.BackgroundColor3 = spec.color
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		local lum = 0.299 * spec.color.R + 0.587 * spec.color.G + 0.114 * spec.color.B
		t.TextColor3 = if lum < 0.45 then Color3.new(1, 1, 1) else Color3.fromRGB(20, 20, 30) -- (V9-0o: readable on dark steel)
		t.Text = spec.plate
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = t
		t.Parent = gui
		gui.Parent = chest
	end
end

-- A player's spawned dummies now (tests).
function DummySpawn.of(player: Player): { Model }
	return mine[player] or {}
end

-- Drops one dummy of `kind` at `at` for `player`. Returns it, or nil and why not.
function DummySpawn.spawnFor(player: Player, kind: unknown, at: unknown): (Model?, string?)
	if not Config.DUMMY_TYPES then
		return nil, "off"
	end
	local spec = if type(kind) == "string" then DummySpawn.TYPES[kind] else nil
	if not spec or typeof(at) ~= "Vector3" then
		return nil, "bad request"
	end
	local point = at :: Vector3
	if point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z then
		return nil, "bad request"
	end
	local Lab = require(script.Parent:WaitForChild("Lab")) :: any
	if Lab.ownerAt(point) ~= player and DummySpawn.labOwnerFor(player, point) == nil then -- (a shared lab's guest too)
		return nil, "only in your own lab"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or (root.Position - point).Magnitude > DummySpawn.REACH then
		return nil, "too far"
	end
	-- (GOD MODE: the first try starts the free trial, after it the offer: "god".)
	if not DummySpawn.mayCreate(player) and not DummySpawn.letIn(player) then
		return nil, "god"
	end
	local now = os.clock()
	if now - (last[player] or -math.huge) < DummySpawn.GAP then
		return nil, "slow down"
	end
	last[player] = now
	local list = mine[player] or {}
	mine[player] = list
	while #list >= capFor(player) do
		local oldest = table.remove(list, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	local DummyFactory = require(script.Parent:WaitForChild("DummyFactory")) :: any
	local model = DummyFactory.spawn(point + Vector3.new(0, 4, 0), root.Position, player)
	model.Name = "SpawnedDummy"
	dress(model, spec)
	table.insert(list, model)
	if DummySpawn.godGated() then
		beam(point, player:GetAttribute("God") == true)
	end
	return model, nil
end

------------------------------------------------------------------------------------------------
-- V9-0z (owner, 21 Nov 2026: "the ragdolls you spawn in GOD MODE should not just stand there"; and "they
-- should disappear after they are knocked out once"): a GOD MODE body lives like the lab's own:
--   * it holds its pattern HOLD_SHAPE s (the shape reads and can be filmed), then wanders: every
--     WANDER_EVERY s a new Home on open floor WANDER_NEAR..WANDER_FAR studs off, which ActiveRagdoll's
--     brain walks it to (at its kind's Pace: TINY quick, HEAVY slow); it flinches, runs and falls like
--     the others;
--   * "Stay in place" (the God window) keeps it standing where it came down (set-ups, bowling pins);
--   * one KO and it goes: once it is down (any knock, a death), it lies ONE_USE_REST s (the fall is
--     enjoyed and counted), then a puff and it is gone, freeing its slot. Never while held, in a
--     machine, or still in the air (waits up to AIR_WAIT s).

DummySpawn.HOLD_SHAPE = 2.5
DummySpawn.WANDER_EVERY = { 6, 10 } -- s
DummySpawn.WANDER_NEAR = 8
DummySpawn.WANDER_FAR = 18
DummySpawn.ONE_USE_REST = 3 -- s down before it goes
DummySpawn.AIR_WAIT = 5

local function poof(model: Model)
	local pelvis = model:FindFirstChild("LowerTorso")
	if pelvis and pelvis:IsA("BasePart") then
		pcall(function()
			(require(script.Parent:WaitForChild("FxService")) :: any).hit(pelvis.Position, 18, "Shove")
		end)
	end
	-- (Its slot is free at once: out of its maker's list too.)
	for _, list in mine do
		local i = table.find(list, model)
		if i then
			table.remove(list, i)
		end
	end
	model:Destroy()
end

local function bringToLife(model: Model, owner: Player, stay: boolean)
	task.spawn(function()
		local VisitorService = require(script.Parent:WaitForChild("VisitorService")) :: any
		local born = os.clock()
		local nextWander = born + DummySpawn.HOLD_SHAPE
		local downAt: number? = nil
		while model.Parent do
			local state = model:GetAttribute("RagdollState")
			local vital = model:GetAttribute("Vital")
			local spent = model:GetAttribute("Spent") == true
			local down = spent or state == "Ragdoll" or state == "Out" or (vital ~= nil and vital ~= "Alive")
			if down and os.clock() - born > 0.5 then
				if not spent then
					model:SetAttribute("Spent", true) -- (one KO: it stays down until it goes; never revived)
				end
				downAt = downAt or os.clock()
				local busy = model:GetAttribute("Held") == true or model:GetAttribute("InMachine") ~= nil or model:GetAttribute("MachineHidden") == true
				local flying = model:GetAttribute("Airborne") == true and os.clock() - (downAt :: number) < DummySpawn.AIR_WAIT
				if busy then
					downAt = os.clock() -- (its rest starts once it is let go)
				elseif not flying and os.clock() - (downAt :: number) >= DummySpawn.ONE_USE_REST then
					poof(model)
					return
				end
			elseif not stay and os.clock() >= nextWander and owner.Parent then
				local pelvis = model:FindFirstChild("LowerTorso")
				if pelvis and pelvis:IsA("BasePart") then
					for _ = 1, 6 do
						local a = math.random() * math.pi * 2
						local r = DummySpawn.WANDER_NEAR + math.random() * (DummySpawn.WANDER_FAR - DummySpawn.WANDER_NEAR)
						local spot = VisitorService.floorAt(owner, pelvis.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
						if spot then
							local home = Vector3.new(spot.X, pelvis.Position.Y, spot.Z)
							model:SetAttribute("Home", home)
							model:SetAttribute("HomeLook", home + Vector3.new(math.cos(a), 0, math.sin(a)) * 5)
							break
						end
					end
				end
				nextWander = os.clock() + DummySpawn.WANDER_EVERY[1] + math.random() * (DummySpawn.WANDER_EVERY[2] - DummySpawn.WANDER_EVERY[1])
			end
			task.wait(0.25)
		end
	end)
end
DummySpawn.bringToLifeForTest = bringToLife

------------------------------------------------------------------------------------------------
-- V9-0l (owner, 21 Nov 2026: "make GOD MODE much better so it is easy to spawn e.g. 10 quickly where you
-- want"): a whole pattern at once where you aim (Shared/GodPattern). The server checks it all:
--   * a known kind and pattern, an amount 1-25 cut to the cap, numbers that are numbers;
--   * the aim in your own lab (or the lab of the Prank Party you are in), within REACH;
--   * each body's spot: open floor of that lab (VisitorService.floorAt: no machine, no lava, nothing
--     solid there, near the lab's height); others are left out;
--   * room: the lab's one body budget (the device's FX_CAPS ragdolls, shared with the row and the
--     visitors: GOD MODE wins, visitors puff away to make room), the server's (EventService), and
--     your own cap; your oldest make room first;
--   * a pace: MANY_GAP between patterns, PAINT_GAP between painted singles, PER_MINUTE bodies a minute.
-- They come down over STAGGER s, one beam over the middle; the lab's player simulates them.

DummySpawn.MANY_GAP = 1 -- s between two patterns
DummySpawn.PAINT_GAP = 0.3 -- s between two single ones (held and dragged)
DummySpawn.STAGGER = 0.3 -- s the bodies of one pattern come down over
DummySpawn.PER_MINUTE = 60 -- bodies a player may create in any minute (painting never churns nonstop)
DummySpawn.FLOOR_TOLERANCE = 6 -- studs a spot's floor may lie off the lab's height

local lastMany: { [Player]: number } = {}
local made: { [Player]: { number } } = {} -- when each body of the last minute was made
local pending: { [number]: number } = {} -- lab owner's UserId -> bodies on their way down

-- The lab a player may create in at `point`: their own, or the lab of the Prank Party they are in.
function DummySpawn.labOwnerFor(player: Player, point: Vector3): Player?
	local Lab = require(script.Parent:WaitForChild("Lab")) :: any
	local owner = Lab.ownerAt(point)
	if owner == player then
		return owner
	end
	if owner and player:GetAttribute("SharedGuest") == owner.UserId then
		return owner -- (bug hunt, 23 Nov 2026: a guest of a shared lab creates in it too)
	end
	if owner and (Config :: any).PRANK_PARTY and player:GetAttribute("PartyLab") == owner.UserId then
		return owner
	end
	return nil
end

-- Every GOD MODE body in `owner`'s lab (theirs and their party guests'). VisitorService counts them.
function DummySpawn.inLab(owner: Player): { Model }
	local out: { Model } = {}
	for _, list in mine do
		for _, m in list do
			if m.Parent and m:GetAttribute("GodLab") == owner.UserId then
				table.insert(out, m)
			end
		end
	end
	return out
end

-- Bodies on their way down into `owner`'s lab (VisitorService leaves room for them).
function DummySpawn.pendingFor(owner: Player): number
	return pending[owner.UserId] or 0
end

-- The cap the client previews with (attribute GodCap): the server's own number.
local function refreshCap(player: Player)
	if player.Parent then
		player:SetAttribute("GodCap", capFor(player))
	end
end
DummySpawn.refreshCap = refreshCap

function DummySpawn.spawnMany(player: Player, kind: unknown, at: unknown, pattern: unknown, count: unknown, spacing: unknown, yaw: unknown, stay: unknown?): (number, string?)
	if not Config.DUMMY_TYPES then
		return 0, "off"
	end
	local GodPattern = require(Shared:WaitForChild("GodPattern")) :: any
	local spec = if type(kind) == "string" then DummySpawn.TYPES[kind] else nil
	if not spec or typeof(at) ~= "Vector3" or type(pattern) ~= "string" or not table.find(GodPattern.PATTERNS, pattern) then
		return 0, "bad request"
	end
	if type(count) ~= "number" or count ~= count or type(spacing) ~= "number" or spacing ~= spacing or type(yaw) ~= "number" or yaw ~= yaw or math.abs(yaw) > 100 then
		return 0, "bad request"
	end
	local point = at :: Vector3
	if point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z or point.Magnitude > 1e6 then
		return 0, "bad request"
	end
	local owner = DummySpawn.labOwnerFor(player, point)
	if not owner then
		return 0, "only in your own lab"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or (root.Position - point).Magnitude > DummySpawn.REACH then
		return 0, "too far"
	end
	if not DummySpawn.mayCreate(player) and not DummySpawn.letIn(player) then
		return 0, "god"
	end
	local cap = capFor(player)
	local n = math.clamp(math.floor(math.clamp(count, 1, 25)), 1, math.min(25, cap))
	local now = os.clock()
	local gap = if n == 1 and pattern == "Point" then DummySpawn.PAINT_GAP else DummySpawn.MANY_GAP
	if now - (lastMany[player] or -math.huge) < gap then
		return 0, "slow down"
	end
	local times = made[player] or {}
	made[player] = times
	while #times > 0 and now - times[1] > 60 do
		table.remove(times, 1)
	end
	n = math.min(n, DummySpawn.PER_MINUTE - #times)
	if n <= 0 then
		return 0, "busy" -- (the minute's budget: told, unlike the short gaps)
	end
	lastMany[player] = now
	-- Each spot: open floor of that lab (a tower stacks up from it, the rain falls onto it).
	local VisitorService = require(script.Parent:WaitForChild("VisitorService")) :: any
	local spots: { Vector3 } = {}
	for _, off in GodPattern.offsets(pattern, n, math.clamp(spacing, GodPattern.SPACING_MIN, GodPattern.SPACING_MAX), yaw) do
		local floor = VisitorService.floorAt(owner, point + Vector3.new(off.X, 0, off.Z), DummySpawn.FLOOR_TOLERANCE)
		if floor then
			table.insert(spots, floor + Vector3.new(0, off.Y, 0))
		end
	end
	if #spots == 0 then
		return 0, "no free floor there"
	end
	-- Room. GOD MODE wins over the automatic visitors; then the player's own oldest make room, but
	-- never one held or in a machine, and for this lab's budget only one in this lab (a party guest's
	-- bodies at home free nothing in the host's lab).
	local EventService = require(script.Parent:WaitForChild("EventService")) :: any
	local list = mine[player] or {}
	mine[player] = list
	for i = #list, 1, -1 do
		if not list[i].Parent then
			table.remove(list, i)
		end
	end
	local labCap = VisitorService.capFor(owner)
	local function labUsed(): number
		return #VisitorService.bodiesOf(owner) + DummySpawn.pendingFor(owner)
	end
	local function serverFree(): number
		return EventService.dummyRoom() - VisitorService.ROOM_KEEP
	end
	local function spare(m: Model): boolean
		return m.Parent ~= nil and not m:GetAttribute("Held") and not m:GetAttribute("InMachine") and not m:GetAttribute("MachineHidden")
	end
	local hereSpare, anySpare = 0, 0
	for _, m in list do
		if spare(m) then
			anySpare += 1
			if m:GetAttribute("GodLab") == owner.UserId then
				hereSpare += 1
			end
		end
	end
	if labUsed() + #spots > labCap then
		VisitorService.makeRoom(owner, labUsed() + #spots - labCap)
	end
	local fits = math.min(#spots, cap - (#list - anySpare), math.max(0, labCap - labUsed()) + hereSpare, math.max(0, serverFree()) + anySpare)
	if fits <= 0 then
		return 0, "full"
	end
	while #spots > fits do
		table.remove(spots)
	end
	local function recycle(onlyHere: boolean): boolean
		-- F90: first one nobody sees; only then the oldest (logged)
		local Dir = require(script.Parent:WaitForChild("RagdollDirector")) :: any
		for pass = 1, 2 do
			for i, m in list do
				if spare(m) and (not onlyHere or m:GetAttribute("GodLab") == owner.UserId) and (pass == 2 or Dir.mayRemove == nil or Dir.mayRemove(m)) then
					table.remove(list, i)
					if Dir.logRemoval then
						Dir.logRemoval(m, "DummySpawn", "recycled for a new GOD MODE spawn")
					end
					m:Destroy()
					return true
				end
			end
		end
		return false
	end
	while labUsed() + #spots > labCap and recycle(true) do
		-- (the oldest of yours in this lab first)
	end
	while (#list + #spots > cap or serverFree() < #spots) and recycle(false) do
		-- (then the oldest of yours anywhere)
	end
	for _ = 1, #spots do
		table.insert(times, now)
	end
	local DummyFactory = require(script.Parent:WaitForChild("DummyFactory")) :: any
	local facingTo = root.Position
	beam(point, player:GetAttribute("God") == true)
	local key = owner.UserId
	pending[key] = (pending[key] or 0) + #spots
	for i, spot in spots do
		task.delay((i - 1) * DummySpawn.STAGGER / math.max(1, #spots), function()
			pending[key] = math.max(0, (pending[key] or 1) - 1)
			if pending[key] == 0 then
				pending[key] = nil
			end
			if not player.Parent or not owner.Parent then
				return
			end
			-- (The lab's player simulates it, as every body in that lab.)
			local model = DummyFactory.spawn(spot + Vector3.new(0, 4, 0), facingTo, owner)
			model.Name = "SpawnedDummy"
			model:SetAttribute("GodLab", owner.UserId)
			dress(model, spec)
			-- (V9-0z: it lives: its kind's pace and gait, a wander after the pattern has been seen, gone after one KO.)
			model:SetAttribute("Pace", spec.pace)
			model:SetAttribute("Gait", if kind == "BOUNCY" then "Hop" elseif kind == "FLOPPY" then "Wobble" else nil)
			model:SetAttribute("StayPut", stay == true or nil)
			bringToLife(model, owner, stay == true)
			table.insert(list, model)
			-- (Never past the cap, even when two patterns overlap in time: the oldest spare one goes.)
			while #list > cap and recycle(false) do
				-- (recycled)
			end
		end)
	end
	return #spots, nil
end

------------------------------------------------------------------------------------------------
-- V9-0l (owner, 21 Nov 2026: "give everyone GOD MODE after a few seconds where it fits, and show it as
-- free because we just opened and are still in beta"; Config.GOD_FREE_BETA): everyone gets GOD MODE free,
-- server-side (attribute GodBeta: the same caps and beam as the pass), at a moment that fits:
--   * a newcomer never inside the busy first minute (BETA_EARLIEST s), then after a first wow
--     (BETA_KOS takedowns or a cannon launch) or at BETA_LATEST s, once BETA_CALM s have passed
--     without a shot or a takedown;
--   * a returning player BETA_RETURNING s after joining;
--   * anyone at once who opens it themselves (the SHOP's FREE · BETA card, or a creation).
-- The first time it is a golden reveal on the screen (remote Spawn "Granted" "first"; remembered in the
-- profile as eco.codes GODBETA, a name no code has); later visits a small chip at most once a UTC day
-- (eco.daily GodChip). The reveal waits for the profile, so a returning player never sees it twice.
-- Who bought the pass is a FOUNDER (MoneyService: attribute and tag, the gold beam) and keeps it for good.

DummySpawn.BETA_KOS = 3
DummySpawn.BETA_EARLIEST = 60 -- s: never inside the busy first minute
DummySpawn.BETA_LATEST = 120 -- s
DummySpawn.BETA_CALM = 3 -- s without a shot or a takedown before the reveal
DummySpawn.BETA_RETURNING = 10 -- s
DummySpawn.BETA_VETERAN = 10 -- takedowns: a player from before the beta is no newcomer

local granted: { [Player]: boolean } = {}
local revealOwed: { [Player]: boolean } = {} -- (the first reveal sent, not yet seen)

-- The screen showed the first reveal: remembered in the profile now.
function DummySpawn.revealSeen(player: Player)
	if not revealOwed[player] then
		return
	end
	revealOwed[player] = nil
	local ProgressService = require(script.Parent:WaitForChild("ProgressService")) :: any
	local e = ProgressService.ecoOf(player)
	if e then
		e.codes.GODBETA = true
		ProgressService.ecoChanged(player)
	end
end
local lastShot: { [Player]: number } = {}

-- Whether a newcomer's moment has come. Pure (T167).
function DummySpawn.betaDue(kosSinceJoin: number, launched: boolean, elapsed: number, calmFor: number): boolean
	local wow = kosSinceJoin >= DummySpawn.BETA_KOS or launched
	return elapsed >= DummySpawn.BETA_EARLIEST and (wow or elapsed >= DummySpawn.BETA_LATEST) and calmFor >= DummySpawn.BETA_CALM
end

-- Tests: forget a player's beta gift this visit.
function DummySpawn.resetBetaForTest(player: Player)
	granted[player] = nil
	player:SetAttribute("GodBeta", nil)
	refreshCap(player)
end

-- Gives `player` the beta GOD MODE now (once a visit). True if it was given now. `asked`: they opened
-- it themselves (the SHOP card, a creation): their screen shows it at once.
function DummySpawn.grantBeta(player: Player, asked: boolean?): boolean
	if not Config.GOD_FREE_BETA or granted[player] or not player.Parent then
		return false
	end
	granted[player] = true
	player:SetAttribute("GodBeta", true)
	refreshCap(player)
	-- The reveal: once the profile is read (the first time ever, a day's chip, or nothing).
	task.spawn(function()
		local ProgressService = require(script.Parent:WaitForChild("ProgressService")) :: any
		local waited = 0
		while player.Parent and not ProgressService.ecoOf(player) and waited < 20 do
			task.wait(0.5)
			waited += 0.5
		end
		local e = ProgressService.ecoOf(player)
		if not e or not player.Parent then
			return -- (no profile: no reveal rather than a wrong one)
		end
		local Economy = require(Shared:WaitForChild("Economy")) :: any
		Economy.rollDay(e, os.time() // 86400) -- (the chip is once a UTC day)
		local first = not e.codes.GODBETA
		local chip = not first and not e.daily.GodChip
		-- (The first reveal is remembered only once the screen says it showed it: "Seen". Lost in a busy
		-- moment, it comes again next visit. A day's chip is remembered at once.)
		if first then
			revealOwed[player] = true
		else
			e.daily.GodChip = true
			ProgressService.ecoChanged(player)
		end
		if first and asked then
			Net.event(Net.Names.Spawn):FireClient(player, "Granted", "asked")
		elseif first or chip then
			Net.event(Net.Names.Spawn):FireClient(player, "Granted", if first then "first" else "chip")
		end
	end)
	return true
end

-- When a joining player gets it (the moment that fits).
local function scheduleBeta(player: Player)
	-- (The device, once its first word (Hello) is in: SessionStats; a slow phone can take a while.)
	task.spawn(function()
		local SessionStats = require(script.Parent:WaitForChild("SessionStats")) :: any
		local t0 = os.clock()
		while player.Parent and os.clock() - t0 < 60 do
			local r = SessionStats.recordFor(player)
			if r and r.plat and r.plat ~= "?" then
				break
			end
			task.wait(1)
		end
		refreshCap(player)
	end)
	if not Config.GOD_FREE_BETA then
		return
	end
	if game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true then
		return -- (the self-tests judge GOD MODE themselves: T167 grants it on purpose)
	end
	task.spawn(function()
		local ProgressService = require(script.Parent:WaitForChild("ProgressService")) :: any
		local started = os.clock()
		-- (A profile read first: returning or new.)
		while player.Parent and not ProgressService.ecoOf(player) and os.clock() - started < 30 do
			task.wait(1)
		end
		local e = ProgressService.ecoOf(player)
		-- (Returning: GOD MODE seen before, or a player from before the beta (BETA_VETERAN takedowns).)
		if e and (e.codes.GODBETA or (ProgressService.takedownsOf(player) or 0) >= DummySpawn.BETA_VETERAN) then
			task.wait(DummySpawn.BETA_RETURNING)
			DummySpawn.grantBeta(player)
			return
		end
		local function kos(): number
			return ProgressService.takedownsOf(player) or 0
		end
		local startKos = kos()
		local lastKos, lastKoAt = startKos, os.clock()
		while player.Parent and not granted[player] do
			task.wait(0.5)
			local k = kos()
			if k ~= lastKos then
				lastKos = k
				lastKoAt = os.clock()
			end
			local launched = (tonumber(player:GetAttribute("CannonShots")) or 0) > 0
			local calmFor = os.clock() - math.max(lastKoAt, lastShot[player] or 0)
			if DummySpawn.betaDue(k - startKos, launched, os.clock() - started, calmFor) then
				DummySpawn.grantBeta(player)
			end
		end
	end)
end
DummySpawn.scheduleBetaForTest = scheduleBeta

-- V9-0l: removes every GOD MODE body in `owner`'s lab, a party guest's too (the host's RESET, the host
-- leaving). `except`: one player whose own are kept.
function DummySpawn.clearLab(owner: Player, except: Player?)
	for who, list in mine do
		if who ~= except then
			for i = #list, 1, -1 do
				local m = list[i]
				if m:GetAttribute("GodLab") == owner.UserId then
					table.remove(list, i)
					m:Destroy()
				end
			end
		end
	end
end

-- A guest's bodies in someone else's lab (their party ended): gone.
local function clearAway(player: Player)
	local list = mine[player]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		local m = list[i]
		local lab = m:GetAttribute("GodLab")
		if lab ~= nil and lab ~= player.UserId then
			table.remove(list, i)
			m:Destroy()
		end
	end
end

-- Removes a player's spawned dummies (Reset, leaving).
function DummySpawn.clear(player: Player)
	for _, m in mine[player] or {} do
		if m.Parent then
			m:Destroy()
		end
	end
	mine[player] = nil
end

function DummySpawn.start()
	local remote = Net.event(Net.Names.Spawn)
	if not Config.DUMMY_TYPES then
		return
	end
	-- lihfolk-ignore: remote-unvalidated-args (what is only compared with fixed words; kind, at, pattern, count, spacing and yaw are checked in spawnFor and spawnMany)
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, what: unknown, kind: unknown, at: unknown, pattern: unknown, count: unknown, spacing: unknown, yaw: unknown, stay: unknown)
		if what == "Try" then
			DummySpawn.tryFor(player) -- (V9-0f: the SHOP card's TRY; once a visit, nothing to validate)
			return
		end
		if what == "Claim" then
			DummySpawn.grantBeta(player, true) -- (V9-0l: the SHOP's FREE · BETA card asks for it now; beta only, once)
			return
		end
		if what == "Seen" then
			DummySpawn.revealSeen(player) -- (V9-0l: the first reveal showed; only when one was sent)
			return
		end
		if what == "Clear" then
			DummySpawn.clear(player) -- (V9-0l: CLEAR MINE; only the player's own)
			return
		end
		if what == "SpawnMany" then
			-- (V9-0l: kind, at, pattern, count, spacing, yaw: every one checked in spawnMany; V9-0z: stay = true keeps them standing.)
			local n, why = DummySpawn.spawnMany(player, kind, at, pattern, count, spacing, yaw, stay)
			if n == 0 and why and why ~= "slow down" then
				remote:FireClient(player, "Refused", why)
			end
			return
		end
		if what ~= "Spawn" then
			return
		end
		-- (The old single creation: one body, through the same checks as a pattern.)
		local n, why = DummySpawn.spawnMany(player, kind, at, "Point", 1, 4, 0)
		if n == 0 and why and why ~= "slow down" then
			remote:FireClient(player, "Refused", why)
		end
	end)
	-- (V9-0l: the free beta GOD MODE, at a moment that fits; its "calm" counts shots too.)
	Net.event(Net.Names.Shot).OnServerEvent:Connect(function(player: Player)
		lastShot[player] = os.clock()
	end)
	local function joined(player: Player)
		scheduleBeta(player)
		player:GetAttributeChangedSignal("PartyLab"):Connect(function()
			clearAway(player) -- (the party ended or moved: what they made in the host's lab goes)
		end)
		player:GetAttributeChangedSignal("God"):Connect(function()
			refreshCap(player)
		end)
	end
	Players.PlayerAdded:Connect(joined)
	for _, p in Players:GetPlayers() do
		joined(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		DummySpawn.clear(player)
		DummySpawn.clearLab(player) -- (the guests' bodies in the leaving host's lab too)
		revealOwed[player] = nil
		last[player] = nil
		trialUsed[player] = nil
		lastMany[player] = nil
		made[player] = nil
		granted[player] = nil
		lastShot[player] = nil
		pending[player.UserId] = nil
	end)
end

-- Tests: forget a player's trial (used and running).
function DummySpawn.resetTrialForTest(player: Player)
	trialUsed[player] = nil
	player:SetAttribute("GodTrialUntil", nil)
end

return DummySpawn
