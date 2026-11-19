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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Log)

local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local FxService = require(script.Parent.FxService)
local ProgressService = require(script.Parent.ProgressService)
local ExperimentService = require(script.Parent.ExperimentService)
local BadgeAwards = require(script.Parent.BadgeAwards)
local Finish = require(script.Parent.Finish)

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
	while os.clock() - started < 4 and player.Parent do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local d = root.Position - target.Position
			if Vector3.new(d.X, 0, d.Z).Magnitude <= Playground.BULLSEYE_RADIUS + 1 and d.Y < 5 then
				FxService.hit(target.Position + Vector3.new(0, 2, 0), 130, "CannonPad")
				ProgressService.notice(player, "\u{1F3AF} BULLSEYE!")
				ExperimentService.event(player, "Bullseye", 1)
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
	local n7 = game:GetService("ServerStorage"):FindFirstChild("N7Assets")
	local props = n7 and n7:FindFirstChild("Props")
	local real = props and props:FindFirstChild("LabCannon")
	if real and real:IsA("Model") then
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
		PlayerRagdoll.launch(player, CANNON_DIRECTION * CANNON_SPEED)
		ExperimentService.event(player, "Cannon", 1)
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
local function throwOnTouch(p: BasePart, cooldown: number, fxSpeed: number, fxId: string, velocityFor: (root: BasePart) -> Vector3, after: ((Player, BasePart) -> ())?)
	local last: { [Player]: number } = {}
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
		FxService.hit(root.Position, fxSpeed, fxId)
		ExperimentService.event(player, "Hazard", 1)
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
	part("Post", Vector3.new(2, height, 2), at(x - 8, height / 2, z), DARK, Enum.Material.Metal)
	part("Post", Vector3.new(2, height, 2), at(x + 8, height / 2, z), DARK, Enum.Material.Metal)
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
	local ramp = Instance.new("WedgePart")
	ramp.Name = "Ramp"
	ramp.Size = Vector3.new(10, 7, 18)
	-- The wedge rises towards its -Z face: run at it from +Z.
	ramp.CFrame = at(26, 3.5, 30) * CFrame.Angles(0, math.pi, 0)
	ramp.Color = YELLOW
	Finish.apply(ramp, "Painted")
	ramp.Anchored = true
	ramp.Parent = folder
	part("RampStripe", Vector3.new(10.2, 0.2, 1), at(26, 7.1, 21.5), WHITE, Enum.Material.Neon).CanCollide = false
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
local function sign(text: string, onto: BasePart, height: number, color: Color3)
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
	-- Front left, between the fall tower and the dummies' row.
	local x, z, w, d = -27.5, -41, 21, 18
	local pool = part("LavaPool", Vector3.new(w, 0.4, d), at(x, 0.2, z), LAVA, Enum.Material.CrackedLava)
	pool:SetAttribute("LaunchVelocity", Vector3.new(0, 105, 0)) -- (dummies too: PropContacts)
	hazardRim(x, z, w, d, 0.6)
	for _, spot in { Vector3.new(-6, 0, -4), Vector3.new(5, 0, 3), Vector3.new(-2, 0, 6) } do
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
	local glow = Instance.new("PointLight")
	glow.Color = LAVA
	glow.Range = 22
	glow.Brightness = 2
	glow.Parent = pool
	sign("LAVA!", pool, 7, LAVA)
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
		local disc = part("BullseyeRing", Vector3.new(0.82 + i * 0.02, ring[1] * 2, ring[1] * 2), CFrame.new(origin + Vector3.new(land.X, 0.4, land.Z)) * CFrame.Angles(0, 0, math.rad(90)), ring[2] :: Color3, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
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
	local post = part("MacePost", Vector3.new(3, 5, 3), at(x, 2.5, z), DARK, Enum.Material.Metal)
	hazardRim(x, z, 30, 30, 0.4)
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

-- Builds a playground round a lab's (or the plaza's) spawn point.
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
		buildSpikes()
		buildStations() -- (round 5: PUT RAGDOLL HERE)
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
	buildWreckingBall() -- after parenting: the swinging parts need to be in the world to be owned
	if lab then
		buildMace() -- (moving too: after parenting)
	end
	log.info("built " .. folder.Name)
end

return Playground
