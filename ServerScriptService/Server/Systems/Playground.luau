--!strict
-- The ready-made playground around the lab: something to try in the first ten seconds, before any
-- building. What players of every big ragdoll game go for first:
--
--   the fall tower    20 stairs up to a platform 30 studs high (throw yourself down the stairs),
--                     a diving plank off the side and a trampoline below it
--   the human cannon  step on the pad and you are fired over the lab (dummies thrown on it fly too)
--   the wrecking ball swings back and forth across a walkway; walk through if you dare (big and
--                     red; it throws whoever it meets)
--   the ramp          run, jump, flop
--   labs only (10 Nov 2026, like the game's picture): the lava pit, the bullseye where the cannon
--   lands, red spike blocks and the spinning spiked mace (buildLava ... buildMace below)
--
-- Built from code (cartoon colours, smooth plastic) into Workspace.Playground: one in the plaza at
-- startup ("Plaza") and one in every lab the first time someone owns it ("Lab1", "Lab2", ...). The
-- parts clients react to are named like the Workshop's (TrampolinePad) or CannonPad.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Log)
local Config = require(Shared.Config)

local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local FxService = require(script.Parent.FxService)
local ProgressService = require(script.Parent.ProgressService)
local ExperimentService = require(script.Parent.ExperimentService)
local BadgeAwards = require(script.Parent.BadgeAwards)
local Finish = require(script.Parent.Finish)
local WorldDress = require(script.Parent.WorldDress)

local log = Log.new("Playground")

local Playground = {}

local watchBullseye: (Player, BasePart) -> ()

local YELLOW = Color3.fromRGB(255, 205, 60)
local WHITE = Color3.fromRGB(240, 240, 245)
local BLUE = Color3.fromRGB(80, 170, 255)
local ORANGE = Color3.fromRGB(255, 140, 50)
local DARK = Color3.fromRGB(45, 47, 58)
local STEEL = Color3.fromRGB(150, 155, 170)
local RED = Color3.fromRGB(232, 38, 38)
local SILVER = Color3.fromRGB(176, 182, 194) -- (chrome: Finish "Brushed" adds the shine)
local BLACK = Color3.fromRGB(24, 24, 28)
local LAVA = Color3.fromRGB(255, 120, 24)
local SPIKE_MESH = "rbxassetid://1033714" -- (Roblox's classic cone mesh)

-- The human cannon: launch velocity and how long before the same player can be fired again.
local CANNON_SPEED = 120
local CANNON_DIRECTION = Vector3.new(-0.45, 0.8, -0.4).Unit
local CANNON_COOLDOWN = 2
local SWING_ANGLE = 55 -- degrees each way
local SWING_PERIOD = 1.9 -- s per side

local root: Folder? = nil -- Workspace.Playground
local folder: Folder -- the one being built
local origin = Vector3.zero

local function part(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	Finish.forMaterial(p, material) -- (plain plastic and metal: painted steel)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.Parent = folder
	return p
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(origin + Vector3.new(x, y, z))
end

local function buildTower()
	-- 20 stairs climbing towards -Z on the west side, then the platform.
	local x, z0 = -52, -8
	local steps, rise, run, width = 20, 1.5, 2.5, 8
	-- (Concrete steps with a yellow safety edge on each, a panelled tower: a test rig, not a toy.)
	for i = 0, steps - 1 do
		local h = (i + 1) * rise
		local stair = part("Stair", Vector3.new(width, h, run), at(x, h / 2, z0 - i * run - run / 2), Color3.fromRGB(172, 175, 182))
		Finish.apply(stair, "Floor")
		local edge = part("StairEdge", Vector3.new(width + 0.02, 0.12, 0.35), at(x, h + 0.05, z0 - i * run - 0.18), YELLOW)
		edge.CanCollide = false
		edge.CanQuery = false
		edge.CanTouch = false
	end
	local top = steps * rise
	local platformZ = z0 - steps * run - 6
	local tower = part("Tower", Vector3.new(14, top, 12), at(x, top / 2, platformZ), Color3.fromRGB(206, 208, 212))
	Finish.apply(tower, "Wall")
	-- A yellow and black band round the top, and a blue stripe down its face (the lab's colours).
	for k = 0, 6 do
		local band = part("TowerBand", Vector3.new(2, 1.2, 12.1), at(x - 6 + k * 2, top - 0.6, platformZ), if k % 2 == 0 then YELLOW else BLACK)
		band.CanCollide = false
		band.CanQuery = false
	end
	local stripe = part("TowerStripe", Vector3.new(2.4, top - 2, 12.06), at(x, top / 2 - 1, platformZ), BLUE)
	stripe.CanCollide = false
	stripe.CanQuery = false
	-- The diving plank out of the east side, and the trampoline under its end.
	part("Plank", Vector3.new(14, 1, 4), at(x + 14, top + 0.5, platformZ), Color3.fromRGB(205, 160, 105), Enum.Material.WoodPlanks)
	local base = part("TrampolineBase", Vector3.new(12, 1, 12), at(x + 18, 0.5, platformZ), DARK)
	local pad = part("TrampolinePad", Vector3.new(11, 0.4, 11), at(x + 18, 1.2, platformZ), BLUE, Enum.Material.Fabric)
	pad:SetAttribute("Playground", true)
	base:SetAttribute("Playground", true)
end

local lastFired: { [Player]: number } = {}

Playground.BULLSEYE_RADIUS = 8
-- Where the human cannon's shot comes down (no air drag on a body in Roblox: a plain throw), from
-- the pad at (x, z) with the root 3 studs over the pad, down to lying height.
-- V8-1.1 (Config.STUNT_SCORE): the player's own cannon shot, a longer and higher arc of
-- Config.CANNON_AIR s to the very same landing point (the old shot was a 1 s hop, 23 studs up).
-- The dummies keep the old shot (the pad's LaunchVelocity): the same landing.
function Playground.cannonVelocity(): Vector3
	local v = CANNON_DIRECTION * CANNON_SPEED
	if not Config.STUNT_SCORE then
		return v
	end
	local g = Workspace.Gravity
	local rise = 2 -- (as cannonLanding: from 3 over the pad down to about 1 over the ground)
	local old = (v.Y + math.sqrt(v.Y * v.Y + 2 * g * rise)) / g
	local t = (Config :: any).CANNON_AIR
	return Vector3.new(v.X * old / t, (0.5 * g * t * t - rise) / t, v.Z * old / t)
end

function Playground.cannonLanding(padTop: Vector3): Vector3
	local v = CANNON_DIRECTION * CANNON_SPEED
	local g = Workspace.Gravity
	local rise = 2 -- (from 3 over the pad down to about 1 over the ground)
	local t = (v.Y + math.sqrt(v.Y * v.Y + 2 * g * rise)) / g
	return Vector3.new(padTop.X + v.X * t, padTop.Y - 0.5, padTop.Z + v.Z * t)
end

-- After a shot: if the player comes down on the bullseye within a few seconds, everyone near sees it
-- and the player is told.
function watchBullseye(player: Player, target: BasePart)
	local started = os.clock()
	task.wait(0.4) -- (off the pad first)
	while os.clock() - started < 6 and player.Parent do -- (V8-1.1: the long arc lands later)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local d = root.Position - target.Position
			if Vector3.new(d.X, 0, d.Z).Magnitude <= Playground.BULLSEYE_RADIUS + 1 and d.Y < 5 then
				FxService.hit(target.Position + Vector3.new(0, 2, 0), 130, "CannonPad")
				ProgressService.notice(player, "\u{1F3AF} BULLSEYE!")
				pcall(function()
					(require(script.Parent:WaitForChild("StuntScore")) :: any).bonus(player, "Bullseye") -- (V8-1.1)
				end)
				ExperimentService.event(player, "Bullseye", 1, "the BULLSEYE")
				BadgeAwards.award(player, "Bullseye")
				return
			end
		end
		task.wait(0.1)
	end
end

local function buildCannon()
	local mine = folder
	local x, z = 48, 6
	local padPart = part("CannonPad", Vector3.new(8, 1, 8), at(x, 0.5, z), ORANGE, Enum.Material.Neon)
	-- Clients launch the dummies they simulate with the same velocity.
	padPart:SetAttribute("LaunchVelocity", CANNON_DIRECTION * CANNON_SPEED)
	-- An arrow on the pad and a barrel behind it, both pointing where you will fly.
	local flat = Vector3.new(CANNON_DIRECTION.X, 0, CANNON_DIRECTION.Z).Unit
	local arrow = part("CannonArrow", Vector3.new(1.2, 0.1, 5), CFrame.lookAt((at(x, 1.05, z)).Position, (at(x, 1.05, z)).Position + flat), WHITE, Enum.Material.Neon)
	arrow.CanCollide = false
	arrow.CanQuery = false
	local barrelBase = (at(x, 0, z)).Position - flat * 6
	local barrelCf = CFrame.lookAt(barrelBase + Vector3.new(0, 4, 0), barrelBase + Vector3.new(0, 4, 0) + CANNON_DIRECTION)
	local barrel = part("CannonBarrel", Vector3.new(3.2, 3.2, 9), barrelCf, DARK, Enum.Material.Metal)
	barrel.CanCollide = false
	local stand = part("CannonStand", Vector3.new(3, 4, 3), CFrame.new(barrelBase + Vector3.new(0, 2, 0)), STEEL, Enum.Material.Metal)
	-- Round 5, phase 3: a real cannon on wooden wheels when the place has it (ServerStorage
	-- N7Assets.Props.LabCannon, a Creator Store model, scripts stripped; its pivot on the ground, -Z
	-- at the muzzle). The built barrel and stand stay as invisible stand-ins (their names are read).
	-- (v3: the hand-picked Creator Store cannon first, V3Assets "Cannon".)
	local v3 = require(script.Parent.V3Assets).place("Cannon", folder, CFrame.lookAt(barrelBase, barrelBase + flat), { size = 14, collide = false, name = "CannonModel" })
	local n7 = game:GetService("ServerStorage"):FindFirstChild("N7Assets")
	local props = n7 and n7:FindFirstChild("Props")
	local real = props and props:FindFirstChild("LabCannon")
	if v3 then
		barrel.Transparency = 1
		stand.Transparency = 1
		stand.CanCollide = false
	elseif real and real:IsA("Model") then
		local copy = real:Clone()
		for _, d in copy:GetDescendants() do
			if d:IsA("LuaSourceContainer") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		copy:ScaleTo(1.25)
		copy:PivotTo(CFrame.lookAt(barrelBase, barrelBase + flat))
		copy.Name = "CannonModel"
		copy.Parent = folder
		barrel.Transparency = 1
		stand.Transparency = 1
		stand.CanCollide = false
	end

	padPart.Touched:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local now = os.clock()
		if lastFired[player] and now - lastFired[player] < CANNON_COOLDOWN then
			return
		end
		lastFired[player] = now
		PlayerRagdoll.launch(player, Playground.cannonVelocity())
		-- (V8-1.1: the flight is scored: StuntScore; AGAIN puts the player back on this pad.)
		pcall(function()
			(require(script.Parent:WaitForChild("StuntScore")) :: any).begin(player, "Cannon", padPart)
		end)
		ExperimentService.event(player, "Cannon", 1, "the CANNON")
		-- (Audit area 1: the first-visit objective line waits on this, not on a height guess.)
		player:SetAttribute("CannonShots", ((player:GetAttribute("CannonShots") :: number?) or 0) + 1)
		FxService.hit(padPart.Position + Vector3.new(0, 3, 0), 120, "CannonPad")
		-- A lab's bullseye (where the shot comes down): landing on it is told (watchBullseye).
		local target = mine:FindFirstChild("Bullseye")
		if target and target:IsA("BasePart") then
			task.spawn(watchBullseye, player, target)
		end
	end)
end

-- Players touching `p` are thrown (ragdolled) with velocityFor's answer, once per `cooldown` s each,
-- with a bang where they are (the hazards of the labs, 10 Nov 2026).
-- (Release 0.20: what a TOSS COMBO pop calls each trap: "Sam into the LAVA!". ExperimentService.)
local TRAP_NAMES: { [string]: string } = {
	LavaPool = "the LAVA",
	SpikeBlock = "the SPIKES",
	SwingBall = "the WRECKING BALL",
	MaceBall = "the SPIKE MACE",
	ChimneyPad = "the CHIMNEY",
	PresentTrap = "the PRESENT",
}
local function throwOnTouch(p: BasePart, cooldown: number, fxSpeed: number, fxId: string, velocityFor: (root: BasePart) -> Vector3, after: ((Player, BasePart) -> ())?)
	local last: { [Player]: number } = {}
	local station = p:GetAttribute("Station")
	local what = if type(station) == "string" then "the " .. station else TRAP_NAMES[p.Name]
	p.Touched:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not character then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end
		local now = os.clock()
		if last[player] and now - last[player] < cooldown then
			return
		end
		last[player] = now
		PlayerRagdoll.launch(player, velocityFor(root))
		-- (V8-1.1: a machine on the way is a bonus in the flight that is on; else a new flight.)
		pcall(function()
			local StuntScore = require(script.Parent:WaitForChild("StuntScore")) :: any
			if StuntScore.isFlying(player) then
				StuntScore.bonus(player, "Machine")
			else
				StuntScore.begin(player, if type(station) == "string" then station else p.Name, p)
			end
		end)
		FxService.hit(root.Position, fxSpeed, fxId)
		ExperimentService.event(player, "Hazard", 1, what)
		if p.Name == "SwingBall" or string.find(p.Name, "Wreck", 1, true) then
			ExperimentService.event(player, "Wrecking", 1) -- (V8-1.3: "ride the WRECKING BALL")
		end
		-- (Audit area 1: which machine threw this player, for the first-visit objective line.)
		player:SetAttribute("ThrownBy_" .. p.Name, ((player:GetAttribute("ThrownBy_" .. p.Name) :: number?) or 0) + 1)
		if after then
			task.spawn(after, player, root)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
end

local function buildWreckingBall()
	local x, z = 40, -38
	local height = 24
	local postA = part("Post", Vector3.new(2, height, 2), at(x - 8, height / 2, z), DARK, Enum.Material.Metal)
	local postB = part("Post", Vector3.new(2, height, 2), at(x + 8, height / 2, z), DARK, Enum.Material.Metal)
	local beam = part("Beam", Vector3.new(18, 2, 2), at(x, height + 1, z), DARK, Enum.Material.Metal)
	-- Walkway under it, in the direction it swings.
	part("Walkway", Vector3.new(6, 0.4, 30), at(x, 0.2, z), YELLOW)

	local pivot = (at(x, height, z)).Position
	local armLength = 15
	local arm = part("SwingArm", Vector3.new(0.7, armLength, 0.7), CFrame.new(pivot - Vector3.new(0, armLength / 2, 0)), DARK, Enum.Material.DiamondPlate)
	-- (The big red ball of the game's picture, 10 Nov 2026: it was a small pink one.)
	local ball = part("SwingBall", Vector3.new(8, 8, 8), CFrame.new(pivot - Vector3.new(0, armLength + 3, 0)), RED, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	-- A player it meets flies the way it swings.
	throwOnTouch(ball, 1.2, 110, "CannonPad", function(root)
		local v = ball.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		local push = if flat.Magnitude > 2 then flat.Unit else (Vector3.new(root.Position.X - ball.Position.X, 0, root.Position.Z - ball.Position.Z)).Unit
		return push * 95 + Vector3.new(0, 55, 0)
	end)
	ball.CustomPhysicalProperties = PhysicalProperties.new(3, 0.3, 0.3)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = ball
	weld.Parent = arm
	if (Config :: any).WRECKING_V2 then
		-- Owner, 20 Nov 2026: "make the swinging ball much nicer". The physics stay the same parts
		-- (arm, ball, hinge); only the look changes: a dark worn steel ball with a lifting lug on a
		-- real chain, hung from a yellow A-frame gantry with braces, an I-beam and concrete feet,
		-- over a hazard-striped run. Pictures are weightless and never collide.
		local STEEL = Color3.fromRGB(46, 48, 53)
		local PAINT = Color3.fromRGB(232, 176, 38)
		local function deco(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, onto: BasePart?, shape: Enum.PartType?): Part
			local p = part(name, size, cf, color, material, shape)
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = true
			if onto then
				p.Anchored = false
				p.Massless = true
				local w = Instance.new("WeldConstraint")
				w.Part0 = onto
				w.Part1 = p
				w.Parent = p
			end
			return p
		end
		-- The ball: worn dark steel, a ring band and a lug on top.
		ball.Color = STEEL
		ball.Material = Enum.Material.Metal
		ball.Reflectance = 0.06
		local top = pivot - Vector3.new(0, armLength - 1, 0)
		deco("BallBand", Vector3.new(1.1, 8.3, 8.3), CFrame.new(pivot - Vector3.new(0, armLength + 3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(34, 35, 39), Enum.Material.Metal, ball, Enum.PartType.Cylinder)
		deco("Lug", Vector3.new(1.6, 1.4, 0.7), CFrame.new(top - Vector3.new(0, 0.3, 0)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal, ball)
		deco("LugPin", Vector3.new(0.5, 2.2, 2.2), CFrame.new(top + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 92, 98), Enum.Material.Metal, ball, Enum.PartType.Cylinder)
		-- The chain: links turned in turn, along the (now hidden) arm.
		arm.Transparency = 1
		local n = 0
		for y = 0.6, armLength - 1, 1.05 do
			n += 1
			local turn = if n % 2 == 0 then math.rad(90) else 0
			local c = CFrame.new(pivot - Vector3.new(0, y, 0)) * CFrame.Angles(0, turn, 0)
			deco("LinkA", Vector3.new(0.22, 1.25, 0.22), c * CFrame.new(-0.28, 0, 0), Color3.fromRGB(64, 66, 72), Enum.Material.Metal, arm)
			deco("LinkB", Vector3.new(0.22, 1.25, 0.22), c * CFrame.new(0.28, 0, 0), Color3.fromRGB(64, 66, 72), Enum.Material.Metal, arm)
		end
		-- The gantry: an A-frame each side (two legs leaning in, a brace), feet, an I-beam, a pulley.
		for _, sx in { -8, 8 } do
			local foot = at(x + sx, 0.5, z).Position
			for _, sz in { -4.5, 4.5 } do
				local base = foot + Vector3.new(0, 0, sz)
				local head = (at(x + sx, height, z)).Position
				local mid = (base + head) / 2
				deco("Leg", Vector3.new(1.4, (head - base).Magnitude, 1.4), CFrame.lookAt(mid, head) * CFrame.Angles(math.rad(90), 0, 0), PAINT, Enum.Material.Metal)
				deco("Footing", Vector3.new(3, 1, 3), CFrame.new(base), Color3.fromRGB(150, 150, 146), Enum.Material.Concrete)
			end
			deco("Brace", Vector3.new(0.8, 0.8, 7), CFrame.new(foot + Vector3.new(0, height * 0.42, 0)), PAINT, Enum.Material.Metal)
		end
		beam.Transparency = 1
		postA.Transparency = 1 -- (they still stop a body; the A-frames are the picture)
		postB.Transparency = 1
		local beamAt = at(x, height + 1, z)
		deco("BeamWeb", Vector3.new(19, 1.6, 0.5), beamAt, Color3.fromRGB(58, 60, 66), Enum.Material.Metal)
		deco("BeamFlange", Vector3.new(19, 0.3, 1.8), beamAt * CFrame.new(0, 0.95, 0), Color3.fromRGB(58, 60, 66), Enum.Material.Metal)
		deco("BeamFlange", Vector3.new(19, 0.3, 1.8), beamAt * CFrame.new(0, -0.95, 0), Color3.fromRGB(58, 60, 66), Enum.Material.Metal)
		deco("Pulley", Vector3.new(1, 2.4, 2.4), CFrame.new(pivot + Vector3.new(0, 0.2, 0)), PAINT, Enum.Material.Metal, nil, Enum.PartType.Cylinder)
		-- The run under it: black and yellow hazard stripes, not a yellow plank.
		local walk = folder:FindFirstChild("Walkway")
		if walk and walk:IsA("BasePart") then
			walk.Transparency = 1
		end
		for k = 0, 9 do
			deco("RunStripe", Vector3.new(6, 0.42, 3), at(x, 0.21, z - 13.5 + k * 3), if k % 2 == 0 then PAINT else Color3.fromRGB(28, 28, 30), Enum.Material.SmoothPlastic)
		end
	end
	-- A servo hinge along X: it swings along Z, across the walkway.
	local a0 = Instance.new("Attachment")
	a0.Parent = beam
	a0.WorldCFrame = CFrame.fromMatrix(pivot, Vector3.xAxis, Vector3.yAxis)
	local a1 = Instance.new("Attachment")
	a1.Parent = arm
	a1.WorldCFrame = CFrame.fromMatrix(pivot, Vector3.xAxis, Vector3.yAxis)
	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0 = a0
	hinge.Attachment1 = a1
	hinge.ActuatorType = Enum.ActuatorType.Servo
	hinge.ServoMaxTorque = 5e6
	hinge.AngularSpeed = math.rad(2 * SWING_ANGLE) / SWING_PERIOD * 1.6
	hinge.AngularResponsiveness = 30
	hinge.TargetAngle = SWING_ANGLE
	hinge.Parent = arm
	local noCollide = Instance.new("NoCollisionConstraint")
	noCollide.Part0 = arm
	noCollide.Part1 = beam
	noCollide.Parent = arm
	arm.Anchored = false
	ball.Anchored = false
	pcall(arm.SetNetworkOwner, arm, nil)
	local mine = folder
	task.spawn(function()
		local side = 1
		local resting = false
		while mine.Parent do
			task.wait(SWING_PERIOD)
			-- A lab nobody owns now: the ball hangs still (anchored: no physics for it) until
			-- someone has the lab again.
			local paused = mine:GetAttribute("Paused") == true
			if paused ~= resting then
				resting = paused
				arm.Anchored = paused
				ball.Anchored = paused
				if paused then
					arm.CFrame = CFrame.new(pivot - Vector3.new(0, armLength / 2, 0))
					ball.CFrame = CFrame.new(pivot - Vector3.new(0, armLength + 3, 0))
				else
					pcall(arm.SetNetworkOwner, arm, nil)
				end
			end
			if not paused then
				side = -side
				hinge.TargetAngle = SWING_ANGLE * side
			end
		end
	end)
end

local function buildRamp()
	local RAMP = (require(Shared:WaitForChild("PathPlan")) :: any).RAMP_AT -- (V9-0h: on the rim under LAYOUT_V3)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "Ramp"
	ramp.Size = Vector3.new(10, 7, 18)
	-- The wedge rises towards its -Z face: run at it from +Z.
	ramp.CFrame = at(RAMP.X, 3.5, RAMP.Y) * CFrame.Angles(0, math.pi, 0)
	ramp.Anchored = true
	if (Config :: any).UI_CLEAN then
		-- V5-1: a steel ramp (diamond plate) with hazard-striped side rails and a painted lip, not a
		-- flat yellow wedge.
		ramp.Color = Color3.fromRGB(118, 122, 130)
		ramp.Material = Enum.Material.DiamondPlate
		ramp.Parent = folder
		for _, sx in { -5.2, 5.2 } do
			local rail = Instance.new("WedgePart")
			rail.Name = "RampRail"
			rail.Size = Vector3.new(0.5, 7.4, 18.2)
			rail.CFrame = at(RAMP.X + sx, 3.7, RAMP.Y) * CFrame.Angles(0, math.pi, 0)
			rail.Color = YELLOW
			rail.Material = Enum.Material.Metal
			rail.Anchored = true
			rail.CanCollide = false
			rail.Parent = folder
		end
		part("RampStripe", Vector3.new(10.2, 0.2, 1), at(RAMP.X, 7.1, RAMP.Y - 8.5), WHITE, Enum.Material.SmoothPlastic).CanCollide = false
		return
	end
	ramp.Color = YELLOW
	Finish.apply(ramp, "Painted")
	ramp.Parent = folder
	part("RampStripe", Vector3.new(10.2, 0.2, 1), at(RAMP.X, 7.1, RAMP.Y - 8.5), WHITE, Enum.Material.Neon).CanCollide = false
end

------------------------------------------------------------------------------------------------
-- The lab's hazards (10 Nov 2026, the owner: the first minutes must feel like the game's picture,
-- the one players click on in the ads): a lava pit, a bullseye where the human cannon lands, red
-- spike blocks, a spinning spiked mace, hazard stripes round them. None of it hurts anyone (players
-- are never hurt in this game): each throws the player, ragdolled, high or far. Labs only (the
-- plaza has its own things around its spawn).
------------------------------------------------------------------------------------------------

-- A spike: a silver cone (a picture only: the block under it does the throwing).
local function spike(position: Vector3, height: number)
	local p = part("Spike", Vector3.new(height * 0.55, height, height * 0.55), CFrame.new(position + Vector3.new(0, height / 2, 0)), SILVER, Enum.Material.Metal)
	Finish.apply(p, "Brushed")
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = SPIKE_MESH
	mesh.Scale = Vector3.new(height * 0.28, height * 0.5, height * 0.28)
	mesh.Parent = p
end

-- Yellow and black blocks round a rectangle (centre x, z; size w, d), low enough to walk over.
local function hazardRim(x: number, z: number, w: number, d: number, height: number)
	local step = 2
	local i = 0
	local function block(px: number, pz: number, sx: number, sz: number)
		local b = part("HazardRim", Vector3.new(sx, height, sz), at(px, height / 2, pz), if i % 2 == 0 then YELLOW else BLACK)
		b.CanQuery = false
		i += 1
	end
	for s = -w / 2 + step / 2, w / 2 - step / 2 + 0.01, step do
		block(x + s, z - d / 2 - 0.5, step, 1)
		block(x + s, z + d / 2 + 0.5, step, 1)
	end
	for s = -d / 2 + step / 2, d / 2 - step / 2 + 0.01, step do
		block(x - w / 2 - 0.5, z + s, 1, step)
		block(x + w / 2 + 0.5, z + s, 1, step)
	end
end

-- A short word over an attraction (the game's own words; nobody types anything here).
-- LOOK_V3 (19 Nov 2026, like the big ragdoll games: almost no text in the world): the shouting
-- words go, the stations keep a small plain name seen only up close.
-- 21 Nov 2026 (Config.ICON_SIGNS, the owner: "no big text in the world, nice signs and icons a child
-- understands"): an attraction's word becomes its picture, a round white badge floating over it (in
-- studs: smaller far off), the drawn pictograms of DrawnIcons; a word with no picture is left out.
Playground.SIGN_ICONS = {
	["SKY LAUNCH"] = "sign_up",
	["FLING PAD"] = "sign_fling",
	["ROCKET WALL"] = "sign_crash",
	["CRASH WALL"] = "sign_crash",
	["BIG RED BUTTON"] = "sign_button",
	["BULLSEYE"] = "sign_target",
	["LAVA!"] = "sign_lava",
} :: { [string]: string }
local function iconBadge(icon: string, onto: BasePart, height: number, color: Color3)
	local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any
	local id = DrawnIcons.ASSETS[icon]
	if not id then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "IconSign"
	gui.Size = UDim2.fromScale(4.2, 4.2)
	gui.StudsOffsetWorldSpace = Vector3.new(0, math.min(height, 7), 0)
	gui.MaxDistance = 110
	gui.LightInfluence = 0
	local disc = Instance.new("Frame")
	disc.Size = UDim2.fromScale(1, 1)
	disc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = disc
	local ring = Instance.new("UIStroke")
	ring.Thickness = 4
	ring.Color = color
	ring.Parent = disc
	local pic = Instance.new("ImageLabel")
	pic.BackgroundTransparency = 1
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	pic.Position = UDim2.fromScale(0.5, 0.5)
	pic.Size = UDim2.fromScale(0.78, 0.78)
	pic.ScaleType = Enum.ScaleType.Fit
	pic.Image = id
	pic.Parent = disc
	disc.Parent = gui
	gui.Parent = onto
end
Playground.iconBadge = iconBadge

local V3_DROP = { ["PUT RAGDOLL HERE"] = true, ["LAVA!"] = true, ["BULLSEYE"] = true, ["SPIKE MACE"] = true }
local function sign(text: string, onto: BasePart, height: number, color: Color3)
	if (Config :: any).ICON_SIGNS then
		local icon = Playground.SIGN_ICONS[text]
		if icon then
			iconBadge(icon, onto, height, color)
		end
		return
	end
	if Config.LOOK_V3 then
		if V3_DROP[text] then
			return
		end
		local gui = Instance.new("BillboardGui")
		gui.Name = "Sign"
		gui.Size = UDim2.new(6, 0, 1.1, 0)
		gui.StudsOffsetWorldSpace = Vector3.new(0, math.min(height, 6), 0)
		gui.MaxDistance = 38
		gui.LightInfluence = 0
		if (Config :: any).UI_CLEAN then
			-- V5-1: a small dark tag of a fixed size on screen (it never fills the view up close).
			gui.Size = UDim2.fromOffset(math.max(90, #text * 11 + 28), 30)
			local tag = Instance.new("TextLabel")
			tag.Size = UDim2.fromScale(1, 1)
			tag.BackgroundColor3 = Color3.fromRGB(24, 26, 31)
			tag.BackgroundTransparency = 0.2
			tag.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
			tag.TextSize = 17
			tag.TextColor3 = Color3.fromRGB(240, 240, 236)
			tag.Text = text
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 8)
			c.Parent = tag
			tag.Parent = gui
			gui.Parent = onto
			return
		end
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.BuilderSansBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(245, 245, 245)
		label.TextTransparency = 0.1
		label.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Transparency = 0.4
		stroke.Color = BLACK
		stroke.Parent = label
		label.Parent = gui
		gui.Parent = onto
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.new(10, 0, 2.4, 0) -- (studs: it shrinks with distance like the world)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = BLACK
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = onto
end

local function buildLava()
	-- Front left, between the fall tower and the dummies' row. (21 Nov 2026: it stays here, at the edge of the
	-- spawn's view beside the bullseye: a destination, not a danger by the spawn; the west side has no room
	-- for it and a path.)
	local x, z, w, d = -27.5, -41, 21, 18
	local pool = part("LavaPool", Vector3.new(w, 0.4, d), at(x, 0.2, z), LAVA, Enum.Material.CrackedLava)
	pool:SetAttribute("LaunchVelocity", Vector3.new(0, 105, 0)) -- (dummies too: PropContacts)
	CollectionService:AddTag(pool, "DummyAvoid") -- (a fleeing dummy turns aside: ActiveRagdoll)
	-- (21 Nov 2026, Config.LAVA_V2: a real pit, LavaPit: a rounded glowing pool, rocks, embers, a sound
	-- and a warning picture; the pool part stays the trigger.)
	local v2 = (Config :: any).LAVA_V2 == true
	if v2 then
		require(script.Parent.LavaPit).dress(pool, origin.Y + 0.02)
	else
		hazardRim(x, z, w, d, 0.6)
	end
	local flames: { Vector3 } = if v2 then {} else { Vector3.new(-6, 0, -4), Vector3.new(5, 0, 3), Vector3.new(-2, 0, 6) }
	for _, spot in flames do
		local flame = Instance.new("Fire")
		flame.Size = 6
		flame.Heat = 12
		flame.Color = Color3.fromRGB(255, 150, 40)
		flame.SecondaryColor = Color3.fromRGB(255, 60, 20)
		local holder = part("LavaFlame", Vector3.new(1, 0.2, 1), at(x + spot.X, 0.3, z + spot.Z), LAVA, Enum.Material.Neon)
		holder.CanCollide = false
		holder.CanQuery = false
		holder.CanTouch = false
		holder.Transparency = 1
		flame.Parent = holder
	end
	if not v2 then
		local glow = Instance.new("PointLight")
		glow.Color = LAVA
		glow.Range = 22
		glow.Brightness = 2
		glow.Parent = pool
		sign("LAVA!", pool, 7, LAVA)
	end
	-- Step in: up you go, a little to one side.
	throwOnTouch(pool, 1.5, 120, "CannonPad", function(root)
		local side = Vector3.new(root.Position.X - pool.Position.X, 0, root.Position.Z - pool.Position.Z)
		local away = if side.Magnitude > 0.5 then side.Unit else Vector3.xAxis
		return away * 18 + Vector3.new(0, 125, 0)
	end)
end

local function buildBullseye()
	-- Where the human cannon's shot comes down (the pad: buildCannon, at 48, 6).
	local land = Playground.cannonLanding(origin + Vector3.new(48, 1, 6)) - origin
	local r = Playground.BULLSEYE_RADIUS
	local base = part("Bullseye", Vector3.new(0.8, r * 2, r * 2), CFrame.new(origin + Vector3.new(land.X, 0.4, land.Z)) * CFrame.Angles(0, 0, math.rad(90)), WHITE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	base.CanTouch = false
	-- The rings, each a hair over the one under it.
	for i, ring in { { r * 0.8, RED }, { r * 0.6, WHITE }, { r * 0.4, RED }, { r * 0.2, WHITE }, { r * 0.08, RED } } do
		local disc = part("BullseyeRing", Vector3.new(0.82 + i * 0.14, ring[1] * 2, ring[1] * 2), CFrame.new(origin + Vector3.new(land.X, 0.4, land.Z)) * CFrame.Angles(0, 0, math.rad(90)), ring[2] :: Color3, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		disc.CanCollide = false
		disc.CanQuery = false
		disc.CanTouch = false
	end
	-- (The sign hangs on a hidden point over the middle: the disc itself is turned on its side.)
	local over = part("BullseyeSign", Vector3.new(0.2, 0.2, 0.2), CFrame.new(origin + Vector3.new(land.X, 1, land.Z)), WHITE)
	over.Transparency = 1
	over.CanCollide = false
	over.CanQuery = false
	over.CanTouch = false
	sign("BULLSEYE", over, 5, RED)
end

local function buildSpikes()
	-- Front right, short of the wrecking ball's walkway.
	for _, spot in { Vector3.new(22, 0, -46), Vector3.new(25, 0, -62) } do
		local block = part("SpikeBlock", Vector3.new(10, 3, 10), at(spot.X, 1.5, spot.Z), RED)
		block:SetAttribute("LaunchVelocity", Vector3.new(0, 85, 0)) -- (dummies too: PropContacts)
		-- A yellow-black band round its foot.
		local band = part("SpikeBand", Vector3.new(10.3, 0.8, 10.3), at(spot.X, 0.4, spot.Z), YELLOW)
		band.CanQuery = false
		band.CanTouch = false
		for ix = -1, 1 do
			for iz = -1, 1 do
				spike(origin + Vector3.new(spot.X + ix * 3, 3, spot.Z + iz * 3), 3.2)
			end
		end
		throwOnTouch(block, 1, 90, "Trampoline", function(root)
			local side = Vector3.new(root.Position.X - block.Position.X, 0, root.Position.Z - block.Position.Z)
			local away = if side.Magnitude > 0.5 then side.Unit else -Vector3.zAxis
			return away * 45 + Vector3.new(0, 95, 0)
		end)
	end
end

local function buildMace()
	-- Behind the spawn, on the left: a post with an arm going round, a spiked ball at its end.
	local x, z = -30, 32
	if (Config :: any).LAYOUT_V2 then
		x, z = Playground.MACE_V2_AT.X, Playground.MACE_V2_AT.Y -- (21 Nov 2026: back a little, clear of the moved lava and the new paths)
	end
	local post = part("MacePost", Vector3.new(3, 5, 3), at(x, 2.5, z), DARK, Enum.Material.Metal)
	-- (V7-1: the big painted box round the mace goes with the other floor boxes: ZONE_FLOOR.)
	if (Config :: any).ZONE_FLOOR then
		hazardRim(x, z, 30, 30, 0.4)
	end
	local hub = (at(x, 4, z)).Position
	local length = 12
	local arm = part("MaceArm", Vector3.new(length, 0.8, 0.8), CFrame.new(hub + Vector3.new(length / 2, 0, 0)), DARK, Enum.Material.DiamondPlate)
	local ball = part("MaceBall", Vector3.new(5, 5, 5), CFrame.new(hub + Vector3.new(length + 1.5, 0, 0)), Color3.fromRGB(60, 62, 72), Enum.Material.Metal, Enum.PartType.Ball)
	Finish.apply(ball, "Brushed")
	-- Spikes all round the ball, welded on (pictures: the ball does the throwing).
	for _, dir in { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis } do
		-- (The cone's tip is its +Y: straight up or down as it is, sideways turned to face out.)
		local where = ball.Position + dir * 3
		local cf = if dir.Y > 0.5 then CFrame.new(where)
			elseif dir.Y < -0.5 then CFrame.new(where) * CFrame.Angles(math.pi, 0, 0)
			else CFrame.lookAt(where, where + dir) * CFrame.Angles(-math.rad(90), 0, 0)
		local s = part("MaceSpike", Vector3.new(1.4, 2.4, 1.4), cf, SILVER, Enum.Material.Metal)
		Finish.apply(s, "Brushed")
		s.CanCollide = false
		s.CanQuery = false
		s.CanTouch = false
		s.Massless = true
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = SPIKE_MESH
		mesh.Scale = Vector3.new(0.7, 1.2, 0.7)
		mesh.Parent = s
		local w = Instance.new("WeldConstraint")
		w.Part0 = ball
		w.Part1 = s
		w.Parent = s
		s.Anchored = false
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = ball
	weld.Parent = arm
	-- A motor round the post (a hinge along Y).
	local a0 = Instance.new("Attachment")
	a0.Parent = post
	a0.WorldCFrame = CFrame.fromMatrix(hub, Vector3.yAxis, Vector3.zAxis)
	local a1 = Instance.new("Attachment")
	a1.Parent = arm
	a1.WorldCFrame = CFrame.fromMatrix(hub, Vector3.yAxis, Vector3.zAxis)
	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0 = a0
	hinge.Attachment1 = a1
	hinge.ActuatorType = Enum.ActuatorType.Motor
	hinge.MotorMaxTorque = 5e7
	hinge.AngularVelocity = 1.4
	hinge.Parent = arm
	local noCollide = Instance.new("NoCollisionConstraint")
	noCollide.Part0 = arm
	noCollide.Part1 = post
	noCollide.Parent = arm
	arm.Anchored = false
	ball.Anchored = false
	pcall(arm.SetNetworkOwner, arm, nil)
	sign("SPIKE MACE", post, 9, SILVER)
	-- Hit by it: thrown the way it goes round.
	throwOnTouch(ball, 1.2, 100, "CannonPad", function(root)
		local v = ball.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		local push = if flat.Magnitude > 1 then flat.Unit else Vector3.new(root.Position.X - hub.X, 0, root.Position.Z - hub.Z).Unit
		return push * 90 + Vector3.new(0, 50, 0)
	end)
	-- A lab nobody owns: the mace rests (no physics), like the wrecking ball.
	local mine = folder
	task.spawn(function()
		local resting = false
		while mine.Parent do
			task.wait(1)
			local paused = mine:GetAttribute("Paused") == true
			if paused ~= resting then
				resting = paused
				hinge.AngularVelocity = if paused then 0 else 1.4
				arm.Anchored = paused
				ball.Anchored = paused
				if not paused then
					pcall(arm.SetNetworkOwner, arm, nil)
				end
			end
		end
	end)
end

-- Round 5 (the owner: "put ragdoll here" stations that keep players in, violent): pads in a row
-- behind the spawn. Step on one yourself, or throw a dummy on it (its LaunchVelocity: the client that
-- simulates the dummy launches it, PropContacts), and it goes:
--   SKY LAUNCH   straight up, very high: the fall is the show
--   FLING PAD    thrown far to the side, spinning
--   ROCKET WALL  shot flat along a rail into a concrete wall
-- Each with a bang, a yellow-black rim and the "PUT RAGDOLL HERE" sign.
local STATIONS = {
	{ name = "SKY LAUNCH", x = -8, z = 52, velocity = Vector3.new(0, 210, 0), color = Color3.fromRGB(80, 170, 255) },
	{ name = "FLING PAD", x = 10, z = 52, velocity = Vector3.new(-62, 95, -30), color = Color3.fromRGB(190, 90, 255) },
	{ name = "ROCKET WALL", x = 28, z = 52, velocity = Vector3.new(150, 18, 0), color = Color3.fromRGB(255, 70, 50) },
}
Playground.STATIONS = STATIONS

-- Round 5, phase 3 (the big game's look): a round pedestal with a yellow-black rim under a thing,
-- low enough never to trip anyone (0.25 studs), a little wider than what stands on it.
local function pedestal(x: number, z: number, radius: number)
	local base = part("Pedestal", Vector3.new(0.25, radius * 2, radius * 2), at(x, 0.12, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(55, 58, 68), Enum.Material.Metal, Enum.PartType.Cylinder)
	base.CanQuery = false
	base.CanTouch = false
	local n = 16
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local seg = part("PedestalRim", Vector3.new(radius * 2 * math.pi / n + 0.05, 0.3, 0.9), at(x + math.cos(a) * (radius - 0.45), 0.15, z + math.sin(a) * (radius - 0.45)) * CFrame.Angles(0, -a + math.pi / 2, 0), if i % 2 == 0 then YELLOW else BLACK)
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
	end
end
Playground.pedestal = pedestal

local function buildStations()
	for _, s in STATIONS do
		local pad = part("StationPad", Vector3.new(7, 1, 7), at(s.x, 0.5, s.z), s.color, Enum.Material.Neon)
		pad:SetAttribute("LaunchVelocity", s.velocity)
		pad:SetAttribute("Station", s.name)
		hazardRim(s.x, s.z, 7, 7, 0.6)
		sign(s.name, pad, 8, s.color)
		sign("PUT RAGDOLL HERE", pad, 5, WHITE)
		throwOnTouch(pad, 1.5, 130, "CannonPad", function(_root)
			return s.velocity
		end)
	end
	-- The rocket wall's rail and its wall, 26 studs on.
	local rocket = STATIONS[3]
	local rail = part("StationRail", Vector3.new(26, 0.3, 2), at(rocket.x + 16.5, 0.15, rocket.z), YELLOW)
	rail.CanCollide = false
	rail.CanQuery = false
	local wall = part("StationWall", Vector3.new(2, 14, 14), at(rocket.x + 30, 7, rocket.z), Color3.fromRGB(150, 150, 155), Enum.Material.Concrete)
	Finish.apply(wall, "Wall")
	sign("CRASH WALL", wall, 9, YELLOW)
end

-- Phase 3 (Config.CHRISTMAS_LAB): the Christmas lab, in every lab while the season is on
-- (Workspace "Christmas"): a CHIMNEY that launches you up out of it, a PRESENT that bursts and throws
-- you, and a SLEIGH RAMP. Built once with the lab into "ChristmasLab", which leaves the world out of
-- season. The spots are clear of the rest of the lab (T66 checks it in a play test).
-- (V8-0.9: moved off the paths and out of the car park: PathPlan.OBSTACLES keeps them clear, T106.)
Playground.CHRISTMAS_SPOTS = { Chimney = Vector2.new(45, 66), Present = Vector2.new(-40, 58), Sleigh = Vector2.new(-10, -60) }
-- 21 Nov 2026 (Config.LAYOUT_V2): the lab re-laid out (vault and the biggest ragdoll games: the spawn faces
-- the test range and the cannon, the hazards gather on the west side, every path joins another).
Playground.MACE_V2_AT = Vector2.new(-41, 50)
if (Config :: any).LAYOUT_V2 then
	Playground.CHRISTMAS_SPOTS = { Chimney = Vector2.new(45, 66), Present = Vector2.new(-58, 64), Sleigh = Vector2.new(-10, -60) }
end
if (Config :: any).LAYOUT_V3 then
	-- (V9-0h review: the dummies' test row moved behind the bullseye, onto the sleigh's old spot.)
	Playground.CHRISTMAS_SPOTS = { Chimney = Vector2.new(45, 66), Present = Vector2.new(-58, 64), Sleigh = Vector2.new(62, -62) }
end
local BRICK = Color3.fromRGB(150, 50, 40)
local XMAS_GREEN = Color3.fromRGB(40, 150, 70)
local GOLD = Color3.fromRGB(255, 200, 60)
local christmasFolders: { Folder } = {}

local function buildChristmas(): Folder
	local saved = folder
	local x = Instance.new("Folder")
	x.Name = "ChristmasLab"
	folder = x
	local spots = Playground.CHRISTMAS_SPOTS
	-- The chimney: walk into the hearth at its foot, come out of the top.
	local c = spots.Chimney
	local stack = part("Chimney", Vector3.new(7, 14, 7), at(c.X, 7, c.Y), BRICK, Enum.Material.Brick)
	sign("CHIMNEY", stack, 10, WHITE)
	local hearth = part("ChimneyPad", Vector3.new(7, 0.6, 5), at(c.X, 0.3, c.Y - 6), RED, Enum.Material.Neon)
	throwOnTouch(hearth, 1.5, 120, "CannonPad", function()
		return Vector3.new(0, 200, 0)
	end, function(player: Player)
		ExperimentService.event(player, "Chimney", 1)
	end)
	-- The present: a big box with a gold ribbon that throws whoever opens it.
	local p = spots.Present
	local box = part("PresentTrap", Vector3.new(6, 6, 6), at(p.X, 3, p.Y), XMAS_GREEN)
	part("Ribbon", Vector3.new(6.2, 6.2, 1.2), at(p.X, 3, p.Y), GOLD)
	part("Ribbon", Vector3.new(1.2, 6.2, 6.2), at(p.X, 3, p.Y), GOLD)
	sign("PRESENT", box, 6, GOLD)
	throwOnTouch(box, 2, 110, "CannonPad", function(root: BasePart)
		local away = root.Position - box.Position
		local flat = Vector3.new(away.X, 0, away.Z)
		local dir = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(1, 0, 0)
		return dir * 90 + Vector3.new(0, 110, 0)
	end, function(player: Player)
		ExperimentService.event(player, "Present", 1)
	end)
	-- The sleigh ramp: a wedge up to a red sleigh at the top edge.
	local s = spots.Sleigh
	local ramp = part("SleighRamp", Vector3.new(8, 6, 16), at(s.X, 3, s.Y), WHITE, Enum.Material.Ice)
	ramp.Shape = Enum.PartType.Wedge
	part("Sleigh", Vector3.new(6, 2, 4), at(s.X, 7, s.Y - 6), RED)
	sign("SLEIGH RAMP", ramp, 8, WHITE)
	folder = saved
	-- World/Feel v2: a cap and snow on the chimney, a bow, the sleigh's runners (in this folder:
	-- they come and go with it; pictures only).
	if Config.WORLD_V2 then
		local ok, err = pcall(function()
			WorldDress.dressChristmas(x, origin, spots :: any)
		end)
		if not ok then
			log.warn("WORLD_V2 Christmas dressing failed: " .. tostring(err))
		end
	end
	x.Parent = if Workspace:GetAttribute("Christmas") == true then saved else nil
	table.insert(christmasFolders, x)
	return x
end

-- In season the Christmas lab is in the world; out of season it waits (the Touched links stay).
function Playground.showChristmas(on: boolean)
	for _, x in christmasFolders do
		local labFolder = x:GetAttribute("Lab")
		local home = if type(labFolder) == "string" and root then root:FindFirstChild(labFolder) else nil
		x.Parent = if on and home then home else nil
	end
end

-- Builds a playground round a lab's (or the plaza's) spawn point.
-- v3 Phase C (19 Nov 2026, like the leader's big red button): press it and a random event happens
-- in this lab, free, once every Config.BIG_BUTTON_GAP s per lab. Anyone in the lab may press it.
-- (V8-0.7: the events sold as products, Mega Bomb and Dummy Rain, left the free pool: the button gave
-- them away every 75 s.)
local BUTTON_EVENTS = { "GorillaRampage", "BullRun", "Tornado", "MeteorShower", "TrainRun", "UfoBeam", "BowlingAvalanche", "RocketRain", "MagnetStorm", "LightningStorm", "Sinkhole", "Earthquake", "FanBlast", "MoonGravity", "BalloonDrop", "GiantDummy" } -- (v4 C4: + the surprises)
-- (V9-0u: no UFO while it is hidden.)
if not (Config :: any).UFO_ENABLED then
	local i = table.find(BUTTON_EVENTS, "UfoBeam")
	if i then
		table.remove(BUTTON_EVENTS, i)
	end
end
Playground.BUTTON_EVENTS = BUTTON_EVENTS -- (tests: what the button can start)
local function buildBigButton()
	local spot = (require(Shared:WaitForChild("PathPlan")) :: any).BUTTON_AT -- (V9-0h: on the rim under LAYOUT_V3)
	local x, z = spot.X, spot.Y
	local base = part("BigButtonBase", Vector3.new(1.6, 6, 6), at(x, 0.8, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 200, 205), Enum.Material.Metal, Enum.PartType.Cylinder)
	local button = part("BigButton", Vector3.new(1, 4.4, 4.4), at(x, 2, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(220, 30, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local lit = Color3.fromRGB(220, 30, 30)
	local dim = Color3.fromRGB(90, 40, 40)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Press"
	prompt.ActionText = "Press"
	prompt.ObjectText = "Big Red Button"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = button
	local labOrigin = origin
	local readyAt = 0
	prompt.Triggered:Connect(function(player: Player)
		local now = os.clock()
		if now < readyAt then
			return
		end
		local Lab = require(script.Parent.Lab)
		local owner = Lab.ownerAt(labOrigin)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not owner or not root or not root:IsA("BasePart") or Lab.ownerAt(root.Position) ~= owner then
			return
		end
		local EventService = require(script.Parent.EventService)
		-- (Only events that stay in this lab, and only while nothing waits: the server's one queue
		-- stays free for bought events.)
		-- (No train without its engine model: Creatures.train would run empty.)
		local pool = {}
		for _, id in BUTTON_EVENTS do
			if id ~= "TrainRun" or require(script.Parent.V3Assets).has("Train") then
				table.insert(pool, id)
			end
		end
		local pick = pool[math.random(1, #pool)]
		-- (Only when nothing runs or waits: a free lab event never holds the server's one queue, and it
		-- starts now, while the presser is in this lab. Blind review 19 Nov.)
		local started = EventService.current() == nil and EventService.queued() == 0 and not EventService.miniRunning() and EventService.trigger(pick, player.DisplayName, "Free", false, nil, owner.UserId)
		if not started then
			prompt.ActionText = "Busy, try again soon"
			task.delay(2.5, function()
				prompt.ActionText = "Press"
			end)
		end
		if started then
			-- (The Lab Controls pass: its owner, in their own lab, waits LAB_CONTROLS_GAP instead.)
			local gap = if player == owner and player:GetAttribute("LabControls") == true then Config.LAB_CONTROLS_GAP else Config.BIG_BUTTON_GAP
			readyAt = now + gap
			button.Color = dim
			prompt.Enabled = false
			button.CFrame = button.CFrame * CFrame.new(-0.3, 0, 0)
			task.delay(gap, function()
				button.Color = lit
				prompt.Enabled = true
				button.CFrame = button.CFrame * CFrame.new(0.3, 0, 0)
			end)
		end
	end)
	sign("BIG RED BUTTON", base, 4.5, WHITE)
	-- v3: the Creator Store button when the place has it (the code-built one stays, see-through,
	-- holding the prompt).
	local look = require(script.Parent.V3Assets).place("BigButton", folder, at(x, 0, z), { size = 6.5, collide = true, name = "BigButtonLook" })
	if look then
		base.Transparency = 1
		base.CanCollide = false
		button.Transparency = 1
		lit = Color3.fromRGB(220, 30, 30)
	end
end

function Playground.build(labOrigin: Vector3, name: string?)
	if not root then
		local new = Instance.new("Folder")
		new.Name = "Playground"
		new.Parent = Workspace
		root = new
		Players.PlayerRemoving:Connect(function(player)
			lastFired[player] = nil
		end)
	end
	origin = Vector3.new(labOrigin.X, labOrigin.Y - 0.5, labOrigin.Z)
	folder = Instance.new("Folder")
	folder.Name = name or "Plaza"
	buildTower()
	buildCannon()
	buildRamp()
	local lab = folder.Name ~= "Plaza"
	if lab then
		buildLava()
		buildBullseye()
		if (Config :: any).SPIKE_BLOCKS ~= false then
			buildSpikes() -- (owner, 20 Nov 2026: the red spike plates are gone: Config.SPIKE_BLOCKS)
		end
		buildStations() -- (round 5: PUT RAGDOLL HERE)
		buildBigButton() -- (v3 Phase C)
		-- Round 5, phase 3: round pedestals under the things to try.
		pedestal(48, 6, 7.5) -- the human cannon
		-- Round 5, phase 4: SINGLEPLAYER and MULTIPLAYER behind the spawn.
		require(script.Parent.PortalService).buildPortals(folder, origin)
		for _, s in STATIONS do
			pedestal(s.x, s.z, 6.5)
		end
		local cannonPad = folder:FindFirstChild("CannonPad")
		if cannonPad and cannonPad:IsA("BasePart") then
			sign("PUT RAGDOLL HERE", cannonPad, 5, WHITE)
		end
	end
	folder.Parent = root
	if lab and Config.CHRISTMAS_LAB then
		local x = buildChristmas()
		x:SetAttribute("Lab", folder.Name)
		x.Parent = if Workspace:GetAttribute("Christmas") == true then folder else nil
		if #christmasFolders == 1 then
			Workspace:GetAttributeChangedSignal("Christmas"):Connect(function()
				Playground.showChristmas(Workspace:GetAttribute("Christmas") == true)
			end)
		end
	end
	buildWreckingBall() -- after parenting: the swinging parts need to be in the world to be owned
	if lab then
		buildMace() -- (moving too: after parenting)
		-- v3: the lab's dressing from the Creator Store models the place has (LabDress).
		pcall(function()
			require(script.Parent.LabDress).dress(folder, origin)
		end)
		-- v3 Phase C: a car and a monster truck on the east side (after parenting: they move).
		local ok, err = pcall(function()
			require(script.Parent.VehicleService).build(folder, origin)
		end)
		if not ok then
			log.warn("Vehicles failed in " .. folder.Name .. ": " .. tostring(err))
		end
	end
	-- v4 C1: zones, today's machine and NEW tags (pictures only: LabZones).
	if lab then
		local ok, err = pcall(function()
			require(script.Parent.LabZones).build(folder, origin)
		end)
		if not ok then
			log.warn("LabZones failed in " .. folder.Name .. ": " .. tostring(err))
		end
	end
	-- V6-4: the garden in the wider plot's side strips (LabGarden). A failure never costs the lab.
	if (Config :: any).LAB_V6 and lab then
		local ok, err = pcall(function()
			require(script.Parent.LabGarden).build(folder, origin)
			if (Config :: any).PATHS then
				-- (V9-0 review: a failure in the paths never costs the creatures and the guide; the
				-- garden's kerbs, which the paths would have laid with theirs, are laid on their own.)
				local okPaths, errPaths = pcall(function()
					require(script.Parent.PathBuilder).lab(folder, origin, origin.Y + 0.04) -- V7-2: paths to everything
				end)
				if not okPaths then
					log.warn("Paths failed in " .. folder.Name .. ": " .. tostring(errPaths))
					local garden = folder:FindFirstChild("Garden")
					if garden then
						require(script.Parent.PathBuilder).finishKerbs(garden)
					end
				end
			end
			if (Config :: any).LAB_CREATURES then
				require(script.Parent.LabCreatures).build(folder, origin)
				-- (21 Nov 2026: signs, rings and a FEED button at every creature and station: LabGuide.)
				if (Config :: any).LAB_GUIDE then
					require(script.Parent.LabGuide).build(folder, origin)
				end
			end
		end)
		if not ok then
			log.warn("LabGarden failed in " .. folder.Name .. ": " .. tostring(err))
		end
	end
	-- (V9-0d review: once everything stands, no path piece lies level with another or with the ground it
	-- crosses; PathFlicker = the pairs left, 0.)
	if lab and (Config :: any).PATHS then
		local okU, errU = pcall(function()
			local roots: { Instance } = { folder }
			-- (V9-0d review: only this lab's own plot, not every lab built so far.)
			local labs = Workspace:FindFirstChild("Labs")
			for _, plot in if labs then labs:GetChildren() else {} do
				local floorPart = plot:FindFirstChild("LabFloor", true)
				if floorPart and floorPart:IsA("BasePart") and math.abs(floorPart.Position.X - origin.X) < 60 then
					table.insert(roots, plot)
				end
			end
			folder:SetAttribute("PathFlicker", require(script.Parent.PathBuilder).unflickerArea({ folder }, roots))
		end)
		if not okU then
			log.warn("unflicker failed in " .. folder.Name .. ": " .. tostring(errU))
		end
	end
	-- World/Feel v2: the dressing over it all (pictures only: WorldDress). A failure there never
	-- costs the playground itself.
	if Config.WORLD_V2 then
		local into = folder
		local ok, err = pcall(function()
			local plan = if lab
				then {
					cannonPad = Vector3.new(48, 1, 6),
					landing = Playground.cannonLanding(origin + Vector3.new(48, 1, 6)) - origin,
					velocity = CANNON_DIRECTION * CANNON_SPEED,
					gravity = Workspace.Gravity,
					stations = STATIONS,
					maxLights = Config.WORLD_V2_LAB_LIGHTS,
				}
				else nil
			WorldDress.dress(into, origin, plan :: any)
		end)
		if not ok then
			log.warn("WORLD_V2 dressing failed in " .. into.Name .. ": " .. tostring(err))
		end
	end
	log.info("built " .. folder.Name)
end

return Playground
