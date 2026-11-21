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

type Spec = { scale: number, density: number, elasticity: number, color: Color3, plate: string }
DummySpawn.TYPES = table.freeze({
	MINI = { scale = 0.6, density = 0.7, elasticity = 0.3, color = Color3.fromRGB(120, 210, 255), plate = "MINI" },
	HEAVY = { scale = 1.3, density = 3, elasticity = 0.1, color = Color3.fromRGB(150, 150, 160), plate = "HEAVY" },
	BOUNCY = { scale = 1, density = 0.9, elasticity = 1, color = Color3.fromRGB(255, 140, 220), plate = "BOUNCY" },
	FLOPPY = { scale = 1, density = 0.25, elasticity = 0.2, color = Color3.fromRGB(255, 220, 120), plate = "FLOPPY" },
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
		DummySpawn.grantBeta(player)
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
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CustomPhysicalProperties = PhysicalProperties.new(spec.density, 0.4, spec.elasticity, 1, if spec.elasticity >= 0.9 then 100 else 1)
			-- (V9-0l: the whole body in its kind's colour, as the GOD MODE window shows it; the skins wear
			-- the parts' colour (DummySkins) and the dead green gives it back (VitalsService.paintDead).)
			if d.Parent == model and d.Name ~= "HumanoidRootPart" then
				d.Color = d.Color:Lerp(spec.color, 0.8)
			end
		end
	end
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
		t.TextColor3 = Color3.fromRGB(20, 20, 30)
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
	if Lab.ownerAt(point) ~= player then
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
-- V9-0l (owner, 21 Nov 2026: "make GOD MODE much better so it is easy to spawn e.g. 10 quickly where you
-- want"): a whole pattern at once where you aim (Shared/GodPattern). The server checks it all: a known
-- kind and pattern, an amount 1-25 cut to the cap, the aim point in your own lab within REACH, each
-- body's spot in your own lab too (others are left out), and a pace. The oldest of yours make room when
-- the cap is hit; they come down one after another over about 0.3 s, one beam over the middle.

DummySpawn.MANY_GAP = 1 -- s between two patterns
DummySpawn.PAINT_GAP = 0.3 -- s between two single ones (held and dragged)
DummySpawn.STAGGER = 0.3 -- s the bodies of one pattern come down over

local lastMany: { [Player]: number } = {}

function DummySpawn.spawnMany(player: Player, kind: unknown, at: unknown, pattern: unknown, count: unknown, spacing: unknown, yaw: unknown): (number, string?)
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
	if point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z then
		return 0, "bad request"
	end
	local Lab = require(script.Parent:WaitForChild("Lab")) :: any
	if Lab.ownerAt(point) ~= player then
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
	local n = math.clamp(math.floor(count), 1, math.min(25, cap))
	local now = os.clock()
	local gap = if n == 1 and pattern == "Point" then DummySpawn.PAINT_GAP else DummySpawn.MANY_GAP
	if now - (lastMany[player] or -math.huge) < gap then
		return 0, "slow down"
	end
	lastMany[player] = now
	-- Each spot: inside your own lab, standing on its floor (a tower or the rain from above it).
	local spots: { Vector3 } = {}
	for _, off in GodPattern.offsets(pattern, n, spacing, yaw) do
		local flat = point + Vector3.new(off.X, 0, off.Z)
		if Lab.ownerAt(flat) == player then
			table.insert(spots, flat + Vector3.new(0, off.Y, 0))
		end
	end
	if #spots == 0 then
		return 0, "only in your own lab"
	end
	local list = mine[player] or {}
	mine[player] = list
	while #list + #spots > cap and #list > 0 do
		local oldest = table.remove(list, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	local DummyFactory = require(script.Parent:WaitForChild("DummyFactory")) :: any
	local facingTo = root.Position
	if DummySpawn.godGated() or Config.GOD_FREE_BETA then
		beam(point, player:GetAttribute("God") == true)
	end
	for i, spot in spots do
		task.delay((i - 1) * DummySpawn.STAGGER / math.max(1, #spots), function()
			if not player.Parent then
				return
			end
			local model = DummyFactory.spawn(spot + Vector3.new(0, 4, 0), facingTo, player)
			model.Name = "SpawnedDummy"
			dress(model, spec)
			table.insert(list, model)
			-- (Never past the cap, even when two patterns overlap in time.)
			while #list > cap do
				local oldest = table.remove(list, 1)
				if oldest then
					oldest:Destroy()
				end
			end
		end)
	end
	return #spots, nil
end

------------------------------------------------------------------------------------------------
-- V9-0l (owner, 21 Nov 2026: "give everyone GOD MODE after a few seconds where it fits, and show it as
-- free because we just opened and are still in beta"; Config.GOD_FREE_BETA): everyone gets GOD MODE free,
-- server-side (attribute GodBeta: the same caps and beam as the pass), at a moment that fits:
--   * a newcomer after their first wow (BETA_KOS takedowns or a cannon launch), at most BETA_LATEST s
--     in, once nothing has happened for BETA_CALM s;
--   * a returning player BETA_RETURNING s after joining.
-- The first time it is a golden reveal on the screen (remote Spawn "Granted" first=true; remembered in the
-- profile, eco.codes GODBETA); later visits a small chip at most once a UTC day (eco.daily GodChip).
-- Who bought the pass is a FOUNDER (MoneyService: attribute and tag, the gold beam) and keeps it for good.

DummySpawn.BETA_KOS = 3
DummySpawn.BETA_LATEST = 90 -- s
DummySpawn.BETA_CALM = 2 -- s without a takedown before the reveal
DummySpawn.BETA_RETURNING = 10 -- s

local granted: { [Player]: boolean } = {}

-- Whether a newcomer's moment has come: a first wow (BETA_KOS takedowns since joining, or a cannon
-- launch) or BETA_LATEST s in, and BETA_CALM s with nothing happening. Pure (T167).
function DummySpawn.betaDue(kosSinceJoin: number, launched: boolean, elapsed: number, calmFor: number): boolean
	local wow = kosSinceJoin >= DummySpawn.BETA_KOS or launched
	return (wow or elapsed >= DummySpawn.BETA_LATEST) and calmFor >= DummySpawn.BETA_CALM
end

-- Tests: forget a player's beta gift this visit.
function DummySpawn.resetBetaForTest(player: Player)
	granted[player] = nil
	player:SetAttribute("GodBeta", nil)
end

-- Gives `player` the beta GOD MODE now (once a visit). True if it was given now.
function DummySpawn.grantBeta(player: Player): boolean
	if not Config.GOD_FREE_BETA or granted[player] or not player.Parent then
		return false
	end
	granted[player] = true
	player:SetAttribute("GodBeta", true)
	local first, chip = true, false
	pcall(function()
		local ProgressService = require(script.Parent:WaitForChild("ProgressService")) :: any
		local e = ProgressService.ecoOf(player)
		if e then
			(require(Shared:WaitForChild("Economy")) :: any).rollDay(e, os.time() // 86400) -- (the chip is once a UTC day)
			first = not e.codes.GODBETA
			chip = not first and not e.daily.GodChip
			e.codes.GODBETA = true
			if not first then
				e.daily.GodChip = true
			end
			ProgressService.ecoChanged(player)
		end
	end)
	if first or chip then
		Net.event(Net.Names.Spawn):FireClient(player, "Granted", if first then "first" else "chip")
	end
	return true
end

-- When a joining player gets it (the moment that fits).
local function scheduleBeta(player: Player)
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
		if e and e.codes.GODBETA then
			task.wait(DummySpawn.BETA_RETURNING)
			DummySpawn.grantBeta(player)
			return
		end
		local function kos(): number
			return ProgressService.takedownsOf(player) or 0
		end
		local startKos = kos()
		local lastKos, calmSince = startKos, os.clock()
		while player.Parent and not granted[player] do
			task.wait(0.5)
			local k = kos()
			if k ~= lastKos then
				lastKos = k
				calmSince = os.clock()
			end
			local launched = (tonumber(player:GetAttribute("CannonShots")) or 0) > 0
			if DummySpawn.betaDue(k - startKos, launched, os.clock() - started, os.clock() - calmSince) then
				DummySpawn.grantBeta(player)
			end
		end
	end)
end
DummySpawn.scheduleBetaForTest = scheduleBeta

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
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, what: unknown, kind: unknown, at: unknown, pattern: unknown, count: unknown, spacing: unknown, yaw: unknown)
		if what == "Try" then
			DummySpawn.tryFor(player) -- (V9-0f: the SHOP card's TRY; once a visit, nothing to validate)
			return
		end
		if what == "Claim" then
			DummySpawn.grantBeta(player) -- (V9-0l: the SHOP's FREE · BETA card asks for it now; beta only, once)
			return
		end
		if what == "Clear" then
			DummySpawn.clear(player) -- (V9-0l: CLEAR MINE; only the player's own)
			return
		end
		if what == "SpawnMany" then
			-- (V9-0l: kind, at, pattern, count, spacing, yaw: every one checked in spawnMany.)
			local n, why = DummySpawn.spawnMany(player, kind, at, pattern, count, spacing, yaw)
			if n == 0 and why and why ~= "slow down" then
				remote:FireClient(player, "Refused", why)
			end
			return
		end
		if what ~= "Spawn" then
			return
		end
		local model, why = DummySpawn.spawnFor(player, kind, at)
		if not model and why and why ~= "slow down" then
			remote:FireClient(player, "Refused", why)
		end
	end)
	-- (V9-0l: the free beta GOD MODE, at a moment that fits.)
	Players.PlayerAdded:Connect(scheduleBeta)
	for _, p in Players:GetPlayers() do
		scheduleBeta(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		DummySpawn.clear(player)
		last[player] = nil
		trialUsed[player] = nil
		lastMany[player] = nil
		granted[player] = nil
	end)
end

-- Tests: forget a player's trial (used and running).
function DummySpawn.resetTrialForTest(player: Player)
	trialUsed[player] = nil
	player:SetAttribute("GodTrialUntil", nil)
end

return DummySpawn
