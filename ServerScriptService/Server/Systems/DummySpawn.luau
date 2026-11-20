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

-- Whether a player may create life now: GOD MODE, or the trial running.
function DummySpawn.mayCreate(player: Player): boolean
	if not DummySpawn.godGated() or player:GetAttribute("God") == true then
		return true
	end
	local untilAt = player:GetAttribute("GodTrialUntil")
	return type(untilAt) == "number" and workspace:GetServerTimeNow() < untilAt
end

-- V9-0f: the SHOP card's TRY 60 s: starts the trial for a player without the pass (once a visit).
function DummySpawn.tryFor(player: Player): boolean
	if not DummySpawn.godGated() or player:GetAttribute("God") == true then
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

local function capFor(player: Player): number
	local SessionStats = require(script.Parent:WaitForChild("SessionStats")) :: any
	local record = SessionStats.recordFor(player)
	local cap = DummySpawn.CAP[record and record.plat or "pc"] or 6
	return if player:GetAttribute("God") == true then cap * 2 else cap
end

-- Life comes down from the sky: a beam of gold light at the spot that fades, sparkles, a chime.
local function beam(at: Vector3)
	local p = Instance.new("Part")
	p.Name = "CreationBeam"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(70, 3.2, 3.2)
	p.CFrame = CFrame.new(at + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 226, 120)
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
	if not DummySpawn.mayCreate(player) and not DummySpawn.startTrial(player) then
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
		beam(point)
	end
	return model, nil
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
	-- lihfolk-ignore: remote-unvalidated-args (what is only compared with "Spawn"; kind and at are checked in spawnFor)
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, what: unknown, kind: unknown, at: unknown)
		if what == "Try" then
			DummySpawn.tryFor(player) -- (V9-0f: the SHOP card's TRY; once a visit, nothing to validate)
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
	Players.PlayerRemoving:Connect(function(player)
		DummySpawn.clear(player)
		last[player] = nil
		trialUsed[player] = nil
	end)
end

-- Tests: forget a player's trial (used and running).
function DummySpawn.resetTrialForTest(player: Player)
	trialUsed[player] = nil
	player:SetAttribute("GodTrialUntil", nil)
end

return DummySpawn
