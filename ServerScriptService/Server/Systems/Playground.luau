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
local LabLayout10 = require(Shared:WaitForChild("LabLayout10")) :: any
local S = (Config :: any).LAB_SPREAD or 1 -- (0.37.0: the bigger lab: machine spots this many times further out)

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
local CANNON_DIRECTION = if (Config :: any).LAB_OWNERMAP then Vector3.new(-0.86, 0.5, 0).Unit else Vector3.new(-0.45, 0.8, -0.4).Unit -- (map round 3: west, over the Launch Field's landing field)
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

-- V9-NOW 7 (owner, 21 Nov 2026: "the neon launch pads become real pads"): one style for every launch pad
-- (Config.REAL_PADS): the pad itself turns into a dark diamond-plate steel plate, with a black rubber mat on
-- top, four bolts and the pad's colour as a painted ring and its pictogram painted on the mat (a Decal, no
-- floating badge). Nothing glows. The pad keeps its name, size and attributes, so every launch rule is the same.
local PAD_STEEL = Color3.fromRGB(78, 82, 90)
local PAD_RUBBER = Color3.fromRGB(34, 35, 38)
local PAD_BOLT = Color3.fromRGB(150, 154, 160)
local function realPad(pad: BasePart, color: Color3, icon: string?)
	pad.Material = Enum.Material.DiamondPlate
	pad.Color = PAD_STEEL
	pad.Reflectance = 0
	local top = pad.CFrame * CFrame.new(0, pad.Size.Y / 2, 0)
	local w, d = pad.Size.X, pad.Size.Z
	local function deco(name: string, size: Vector3, cf: CFrame, c: Color3, material: Enum.Material, shape: Enum.PartType?): Part
		local p = part(name, size, cf, c, material, shape)
		p.Material = material
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		return p
	end
	local mat = deco("PadMat", Vector3.new(w - 1.2, 0.08, d - 1.2), top * CFrame.new(0, 0.04, 0), PAD_RUBBER, Enum.Material.Rubber)
	-- (The colour as paint: a flat ring on the mat, never neon.)
	local r = math.min(w, d) / 2 - 1
	deco("PadPaint", Vector3.new(0.02, r * 2, r * 2), top * CFrame.new(0, 0.09, 0) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	deco("PadPaintInner", Vector3.new(0.022, r * 2 - 0.9, r * 2 - 0.9), top * CFrame.new(0, 0.092, 0) * CFrame.Angles(0, 0, math.rad(90)), PAD_RUBBER, Enum.Material.Rubber, Enum.PartType.Cylinder)
	for _, c in { Vector2.new(1, 1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(-1, -1) } do
		deco("PadBolt", Vector3.new(0.12, 0.38, 0.38), top * CFrame.new(c.X * (w / 2 - 0.35), 0.05, c.Y * (d / 2 - 0.35)) * CFrame.Angles(0, 0, math.rad(90)), PAD_BOLT, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any
	local id = nil :: string? -- (V10 phase 2, owner: no pictograms; was icon and DrawnIcons.ASSETS[icon])
	local _ = icon
	if id then
		local mark = deco("PadMark", Vector3.new(r * 1.25, 0.02, r * 1.25), top * CFrame.new(0, 0.1, 0), PAD_RUBBER, Enum.Material.SmoothPlastic)
		mark.Transparency = 1
		local decal = Instance.new("Decal")
		decal.Texture = id
		decal.Face = Enum.NormalId.Top
		decal.Color3 = Color3.new(1, 1, 1)
		decal.Parent = mark
	end
	pad:SetAttribute("RealPad", true)
	return mat
end
Playground.realPad = realPad

local function buildTower()
	-- 20 stairs climbing towards -Z on the west side, then the platform.
	local x, z0 = -52 * S, -8 * S
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
		-- (0.37.10: the band's top just under the roof, so the two never flicker)
		local band = part("TowerBand", Vector3.new(2, 1.2, 12.1), at(x - 6 + k * 2, top - 0.66, platformZ), if k % 2 == 0 then YELLOW else BLACK)
		band.CanCollide = false
		band.CanQuery = false
	end
	local stripe = part("TowerStripe", Vector3.new(2.4, top - 2, 12.06), at(x, top / 2 - 1, platformZ), BLUE)
	stripe.CanCollide = false
	stripe.CanQuery = false
	-- The diving plank out of the east side, and the trampoline under its end.
	part("Plank", Vector3.new(14, 1, 4), at(x + 14, top + 0.5, platformZ), Color3.fromRGB(205, 160, 105), Enum.Material.WoodPlanks)
	-- (0.37.10, owner: "a giant trampoline under the tower": twice as wide, and it throws higher: Bounce.)
	local base = part("TrampolineBase", Vector3.new(24, 1, 24), at(x + 20, 0.5, platformZ), DARK)
	local pad = part("TrampolinePad", Vector3.new(23, 0.4, 23), at(x + 20, 1.2, platformZ), BLUE, Enum.Material.Fabric)
	pad:SetAttribute("Bounce", 1.7)
	pad:SetAttribute("Playground", true)
	base:SetAttribute("Playground", true)
end

local lastFired: { [Player]: number } = {}

Playground.BULLSEYE_RADIUS = 8
Playground.CANNON_LOAD = 0.8 -- s a ragdoll sits in the barrel before it is fired (22 Nov 2026)
Playground.CANNON_DUMMY_BOOST = 1.5 -- its shot out of the muzzle, times the pad's old throw (0.37.7: was 1.15, owner: "much more violent")
-- 0.37.7 (owner: "the cannon and the swinging ball much more violent, so body parts sometimes fall off"):
-- a shot or a hit can tear one or two pieces off (VitalsService.sever: whole limbs, forearms, hands, shins, feet).
Playground.TEAR_CANNON = 0.45 -- the chance a cannon shot tears something off
Playground.TEAR_BALL = 0.4 -- the chance a hit by the wrecking ball does
local TEAR_PIECES = { "LeftArm", "RightArm", "LeftForearm", "RightForearm", "LeftHand", "RightHand", "LeftLeg", "RightLeg", "LeftShin", "RightShin", "LeftFoot", "RightFoot" }
local function tearOff(m: Model, chance: number, at: Vector3?)
	if not (Config :: any).SEVERING or math.random() > chance then
		return
	end
	local ok, Vitals = pcall(require, script.Parent:WaitForChild("VitalsService"))
	if not ok then
		return
	end
	for _ = 1, math.random(1, 2) do
		pcall((Vitals :: any).sever, m, TEAR_PIECES[math.random(#TEAR_PIECES)], at)
	end
end
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
	local x, z = 48 * S, 6 * S
	if (Config :: any).LAB_OWNERMAP then
		local cn = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).at("Cannon", Vector2.new(-235, 335))
		x, z = cn.X, cn.Y -- (OwnerMapPlan Cannon, by the Launch Field; M4: from the plan)
	end
	local padPart = part("CannonPad", Vector3.new(8, 1, 8), at(x, 0.5, z), ORANGE, Enum.Material.Neon)
	-- Clients launch the dummies they simulate with the same velocity.
	padPart:SetAttribute("LaunchVelocity", CANNON_DIRECTION * CANNON_SPEED)
	-- An arrow on the pad and a barrel behind it, both pointing where you will fly.
	local flat = Vector3.new(CANNON_DIRECTION.X, 0, CANNON_DIRECTION.Z).Unit
	local arrow = part("CannonArrow", Vector3.new(1.2, 0.1, 5), CFrame.lookAt((at(x, 1.05, z)).Position, (at(x, 1.05, z)).Position + flat), WHITE, Enum.Material.Neon)
	-- (F7, owner 26 Nov 2026: "pladen ved kanonen skal ikke launche en": no plate; the pad stays as an invisible
	-- stand-in, its name is read elsewhere. A ragdoll let go at the glowing muzzle spot slides in, then it fires.)
	local muzzleLoad = (Config :: any).CANNON_MUZZLE_LOAD == true
	if muzzleLoad then
		padPart.Transparency = 1
		padPart.CanCollide = false
		padPart.CanTouch = false
		padPart.CanQuery = false
		arrow.Transparency = 1
	elseif (Config :: any).REAL_PADS then
		realPad(padPart, ORANGE, nil)
		arrow.Material = Enum.Material.SmoothPlastic -- (painted on, over the mat)
		arrow.CFrame += Vector3.new(0, 0.12, 0)
	end
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

	-- (22 Nov 2026, owner: "the ragdoll goes down INTO the cannon and is shot out of it, not off the pad"):
	-- a ragdoll let go on the pad vanishes into the barrel, a beat later it flies out of the muzzle.
	-- The pad no longer throws dummies itself (no LaunchVelocity: PropContacts leaves them alone).
	padPart:SetAttribute("LaunchVelocity", nil)
	local muzzle = barrelCf * CFrame.new(0, 0, -6)
	local loading: { [Model]: number } = {}
	local lastHeld: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
	-- (F7: the glowing load spot right under the muzzle: let a carried ragdoll go here.)
	local loadAt = Vector3.new(muzzle.Position.X, (at(x, 0, z)).Position.Y, muzzle.Position.Z) + Vector3.new(CANNON_DIRECTION.X, 0, CANNON_DIRECTION.Z).Unit * 1.5
	-- C10 (docs/CONTROLS_10.md 1; Config.CANNON_HOPPER): a real LOADING HOPPER on the back of the cannon instead of the
	-- glowing disc: a big round metal funnel (6 wide) with a yellow-black hazard rim, a painted down-arrow and a ragdoll
	-- pictogram, on a chute into the breech. Drop, throw or let go of a ragdoll anywhere in it: it slides down the chute,
	-- the barrel clunks shut, 3-2-1, BOOM. The rim glows soft yellow while a ragdoll is carried within 20 studs, red
	-- while one is inside. Players are never loaded (only lab ragdolls are looked at).
	local hopper = (Config :: any).CANNON_HOPPER == true
	local hopperTop: Vector3? = nil
	local hopperRim: { BasePart } = {}
	if hopper then
		local ground = (at(x, 0, z)).Position.Y
		local back = barrelBase - flat * 7.5
		local top = Vector3.new(back.X, ground + 5.6, back.Z)
		hopperTop = top
		-- the funnel: a cone of 16 tilted steel staves, wide at the top, narrow at the chute
		for i = 1, 16 do
			local a = (i - 0.5) / 16 * math.pi * 2
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local mid = top + dir * 2.2 + Vector3.new(0, -1.1, 0)
			local stave = part("HopperStave", Vector3.new(1.0, 2.6, 0.18), CFrame.lookAt(mid, mid + dir) * CFrame.Angles(math.rad(-38), 0, 0), Color3.fromRGB(120, 124, 132), Enum.Material.DiamondPlate)
			stave.CanCollide = true
			stave.CanQuery = false
			local rim = part("HopperRim", Vector3.new(1.25, 0.45, 0.3), CFrame.lookAt(top + dir * 3.05, top + dir * 4), if i % 2 == 0 then Color3.fromRGB(245, 200, 30) else Color3.fromRGB(24, 24, 28), Enum.Material.SmoothPlastic)
			rim.CanCollide, rim.CanQuery = false, false
			table.insert(hopperRim, rim)
		end
		-- the chute from the funnel's throat into the breech, and the legs
		local throat = top + Vector3.new(0, -2.4, 0)
		local breech = barrelBase + Vector3.new(0, 4, 0) - CANNON_DIRECTION * 3.5
		local chute = part("HopperChute", Vector3.new(1.6, 1.6, (breech - throat).Magnitude + 0.6), CFrame.lookAt((throat + breech) / 2, breech), Color3.fromRGB(70, 74, 82), Enum.Material.Metal)
		chute.CanCollide, chute.CanQuery = false, false
		for _, sx in { -1, 1 } do
			local side = flat:Cross(Vector3.yAxis) * sx
			local leg = part("HopperLeg", Vector3.new(0.45, ground + 3.4 - ground, 0.45), CFrame.new(throat + side * 1.6 + Vector3.new(0, -1.6, 0)), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
			leg.CanQuery = false
		end
		-- the painted down-arrow on the far inside wall, and the ragdoll pictogram plate on its side
		local far = top - flat * 2.0 + Vector3.new(0, -0.9, 0)
		local arrowPlate = part("HopperArrow", Vector3.new(1.6, 1.8, 0.06), CFrame.lookAt(far, far + flat) * CFrame.Angles(math.rad(-38), 0, 0), Color3.fromRGB(245, 200, 30), Enum.Material.SmoothPlastic)
		arrowPlate.CanCollide, arrowPlate.CanQuery = false, false
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local g = Instance.new("SurfaceGui")
			g.Face = face
			g.CanvasSize = Vector2.new(100, 110)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(1, 1)
			t.Font = Enum.Font.GothamBlack
			t.TextScaled = true
			t.TextColor3 = Color3.fromRGB(24, 24, 28)
			t.Text = "\u{2B07}"
			t.Parent = g
			g.Parent = arrowPlate
		end
		local sideDir = flat:Cross(Vector3.yAxis)
		local picAt = top + sideDir * 3.3 + Vector3.new(0, -1.4, 0)
		local pic = part("HopperPictogram", Vector3.new(1.4, 1.4, 0.08), CFrame.lookAt(picAt, picAt + sideDir), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic)
		pic.CanCollide, pic.CanQuery = false, false
		local pg = Instance.new("SurfaceGui")
		pg.Face = Enum.NormalId.Front
		pg.CanvasSize = Vector2.new(100, 100)
		local pt = Instance.new("TextLabel")
		pt.BackgroundTransparency = 1
		pt.Size = UDim2.fromScale(1, 1)
		pt.TextScaled = true
		pt.Text = "\u{1F938}"
		pt.Parent = pg
		pg.Parent = pic
		loadAt = top
		-- the rim's light: yellow while a ragdoll is carried near, red while one is inside, plain otherwise
		task.spawn(function()
			local was = ""
			while padPart.Parent do
				task.wait(0.25)
				local want = "off"
				local dummies = Workspace:FindFirstChild("Dummies")
				for _, m in if dummies then dummies:GetChildren() else {} do
					local pe = m:FindFirstChild("LowerTorso")
					if pe and pe:IsA("BasePart") then
						if m:GetAttribute("MachineHidden") == true and (pe.Position - barrelCf.Position).Magnitude < 8 then
							want = "busy"
							break
						elseif m:GetAttribute("Held") == true and (pe.Position - top).Magnitude < 20 then
							want = "carry"
						end
					end
				end
				if want ~= was then
					was = want
					for i, r in hopperRim do
						if want == "carry" then
							r.Material = Enum.Material.Neon
							r.Color = if i % 2 == 0 then Color3.fromRGB(255, 230, 90) else Color3.fromRGB(60, 50, 20)
						elseif want == "busy" then
							r.Material = Enum.Material.Neon
							r.Color = if i % 2 == 0 then Color3.fromRGB(255, 60, 50) else Color3.fromRGB(60, 20, 20)
						else
							r.Material = Enum.Material.SmoothPlastic
							r.Color = if i % 2 == 0 then Color3.fromRGB(245, 200, 30) else Color3.fromRGB(24, 24, 28)
						end
					end
				end
			end
		end)
	end
	if muzzleLoad and not hopper then
		local spot = part("CannonLoad", Vector3.new(0.2, 5, 5), CFrame.new(loadAt + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)), ORANGE, Enum.Material.Neon, Enum.PartType.Cylinder)
		spot.CanCollide, spot.CanQuery, spot.CanTouch, spot.CastShadow = false, false, false, false
		spot.Transparency = 0.35
		local label = Instance.new("BillboardGui")
		label.Size = UDim2.fromOffset(160, 36)
		label.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		label.AlwaysOnTop = false
		label.MaxDistance = 40
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.3
		t.Text = "DROP A RAGDOLL HERE"
		t.Parent = label
		label.Parent = spot
	end
	task.spawn(function()
		local DummyControl = require(script.Parent.DummyControl) :: any
		while padPart.Parent do
			task.wait(0.2)
			local dummies = Workspace:FindFirstChild("Dummies")
			local now = os.clock()
			for _, m in if dummies then dummies:GetChildren() else {} do
				local pelvis = m:FindFirstChild("LowerTorso")
				if m:IsA("Model") and m:GetAttribute("Held") == true then
					lastHeld[m] = now
				end
				if m:IsA("Model") and pelvis and pelvis:IsA("BasePart") and not loading[m] and m:GetAttribute("Held") ~= true
					and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("MachineHidden") ~= true then
					local inZone: boolean
					if hopper and hopperTop then
						-- (C10: anywhere in the funnel: a generous volume over its mouth, carried ones only once let go)
						local ht = hopperTop :: Vector3
						local flatD = Vector3.new(pelvis.Position.X - ht.X, 0, pelvis.Position.Z - ht.Z).Magnitude
						local dy = pelvis.Position.Y - ht.Y
						-- (F92: only one a player let go of or threw in the last 2.5 s: never one that walks or falls past)
						inZone = flatD < 3.4 and dy > -3 and dy < 6 and now - (lastHeld[m] or -99) < 2.5
					elseif muzzleLoad then
						-- Only a ragdoll a player just let go (never one that walks by), close under the muzzle.
						local flat = Vector3.new(pelvis.Position.X - loadAt.X, 0, pelvis.Position.Z - loadAt.Z).Magnitude
						local dy = pelvis.Position.Y - loadAt.Y
						inZone = flat < 3.6 and dy > -1 and dy < 9 and now - (lastHeld[m] or -99) < 4
					else
						local rel = padPart.CFrame:PointToObjectSpace(pelvis.Position)
						inZone = math.abs(rel.X) < 4.5 and math.abs(rel.Z) < 4.5 and rel.Y > -1 and rel.Y < 6
					end
					if inZone then
						loading[m] = os.clock()
						task.spawn(function()
							FxService.hit(padPart.Position + Vector3.new(0, 2, 0), 40, "CannonPad")
							if hopper and hopperTop then
								-- (C10: it slides down the funnel and the chute with a whoosh, then the barrel clunks shut)
								local from = pelvis.CFrame
								local throat = CFrame.new((hopperTop :: Vector3) + Vector3.new(0, -2.2, 0))
								for i = 1, 5 do
									DummyControl.move(m, from:Lerp(throat, i / 5))
									task.wait(0.05)
								end
								local whoosh = Instance.new("Sound")
								whoosh.SoundId = "rbxassetid://9113480917"
								whoosh.PlaybackSpeed = 1.6
								whoosh.Volume = 0.6
								whoosh.Parent = padPart
								whoosh:Play()
								game:GetService("Debris"):AddItem(whoosh, 2)
							elseif muzzleLoad then
								-- It slides into the barrel: a few steps from where it is to the muzzle, then inside.
								local from = pelvis.CFrame
								local into = CFrame.lookAt(muzzle.Position, muzzle.Position + CANNON_DIRECTION)
								for i = 1, 6 do
									DummyControl.move(m, from:Lerp(into, i / 6))
									task.wait(0.05)
								end
							end
							m:SetAttribute("MachineHidden", true) -- (gone into the barrel, on every screen)
							DummyControl.move(m, barrelCf)
							-- (The player who dropped it, the nearest within 30 studs, tried the cannon: TRY, goal line, record.)
							pcall(function()
								local owner: Player? = nil
								local bestD = 30
								for _, pl in Players:GetPlayers() do
									local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
									if r and r:IsA("BasePart") and (r.Position - loadAt).Magnitude < bestD then
										owner, bestD = pl, (r.Position - loadAt).Magnitude
									end
								end
								if owner then
									ExperimentService.event(owner, "Cannon", 1, "the CANNON")
								end
								m:SetAttribute("CannonBy", if owner then owner.UserId else nil) -- (M10_CANNON: whose NEW BEST it is)
							end)
							if Config.M10_CANNON then
								Playground.cannonWindUp(barrelCf, loadAt, Playground.CANNON_LOAD + 0.2)
							end
							task.wait(Playground.CANNON_LOAD)
							if m.Parent then
								DummyControl.move(m, CFrame.lookAt(muzzle.Position, muzzle.Position + CANNON_DIRECTION))
								task.wait(0.1)
								m:SetAttribute("MachineHidden", nil)
								DummyControl.push(m, CANNON_DIRECTION * CANNON_SPEED * Playground.CANNON_DUMMY_BOOST)
								FxService.hit(muzzle.Position, 140, "CannonPad")
								tearOff(m, Playground.TEAR_CANNON, muzzle.Position)
								if Config.M10_CANNON then
									local by = m:GetAttribute("CannonBy")
									task.spawn(Playground.cannonScore, m, muzzle.Position, if type(by) == "number" then Players:GetPlayerByUserId(by) else nil)
								end
								-- (Phase D, 23 Nov 2026: "cannon smoke and recoil"): a flash and a cloud of smoke out of
								-- the muzzle, and the cannon kicks back on its wheels and rolls home.
								task.spawn(function()
									local puff = Instance.new("Part")
									puff.Anchored, puff.CanCollide, puff.CanQuery, puff.CanTouch, puff.Transparency = true, false, false, false, 1
									puff.Size = Vector3.one * 0.2
									puff.CFrame = CFrame.lookAt(muzzle.Position, muzzle.Position + CANNON_DIRECTION)
									puff.Parent = folder
									local smoke = Instance.new("ParticleEmitter")
									smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
									smoke.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235), Color3.fromRGB(120, 120, 120))
									smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) })
									smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
									smoke.Speed = NumberRange.new(8, 18)
									smoke.SpreadAngle = Vector2.new(25, 25)
									smoke.Drag = 2
									smoke.Lifetime = NumberRange.new(1.2, 2.2)
									smoke.EmissionDirection = Enum.NormalId.Front
									smoke.Rate = 0
									smoke.Parent = puff
									local fire = smoke:Clone()
									fire.Texture = ""
									fire.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 110, 30))
									fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
									fire.Lifetime = NumberRange.new(0.12, 0.25)
									fire.LightEmission = 1
									fire.Parent = puff
									smoke:Emit(30)
									fire:Emit(25)
									game:GetService("Debris"):AddItem(puff, 3)
									local model = folder:FindFirstChild("CannonModel")
									if model and model:IsA("Model") then
										local home = model:GetPivot()
										local kick = -CANNON_DIRECTION.Unit * 1.4
										for i = 1, 6 do
											model:PivotTo(home + kick * (1 - (i - 1) / 6) * (if i == 1 then 1 else 0.9))
											task.wait(0.03)
										end
										for i = 1, 12 do
											model:PivotTo(home + kick * (1 - i / 12) * 0.9)
											task.wait(0.03)
										end
										model:PivotTo(home)
									end
								end)
							end
							task.wait(2.5)
							loading[m] = nil
						end)
					end
				end
			end
		end
	end)

	padPart.Touched:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or muzzleLoad then
			return -- (F7: standing near the cannon never launches anyone)
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
	local x, z = 40 * S, -38 * S
	if (Config :: any).LAB_OWNERMAP then
		local wb = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).at("WreckingBall", Vector2.new(-215, -25))
		x, z = wb.X, wb.Y -- (OwnerMapPlan WreckingBall; M4: from the plan)
	end
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
	-- 0.37.7: a ragdoll it meets is smashed away hard the way it swings, and may lose a piece (tearOff).
	local smashed: { [Model]: number } = {}
	local wreckBy: { player: Player? } = { player = nil } -- (3.6: who pulled the lever last)
	ball.Touched:Connect(function(other)
		local m = other:FindFirstAncestorOfClass("Model")
		if not m or m:GetAttribute("IsDummy") ~= true or m:GetAttribute("Held") == true or m:GetAttribute("MachineHidden") == true then
			return
		end
		local now = os.clock()
		if smashed[m] and now - smashed[m] < 1.5 then
			return
		end
		smashed[m] = now
		local v = ball.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		local away = if flat.Magnitude > 2 then flat.Unit else Vector3.new(other.Position.X - ball.Position.X, 0, other.Position.Z - ball.Position.Z).Unit
		if (Config :: any).WRECK_10 then
			-- 3.6: the force follows the ball's speed; "SMASH! FORCE 87%" at the hit, the distance where it lands
			local speed = v.Magnitude
			if speed < 6 then
				return -- (a resting ball only bumps)
			end
			local k = math.clamp(speed / 60, 0.2, 1)
			local by = wreckBy.player
			pcall((require(script.Parent.DummyControl) :: any).push, m, away * (60 + 110 * k) + Vector3.new(0, 35 + 45 * k, 0), by)
			pcall(function()
				Playground.pop(other.Position + Vector3.new(0, 4, 0), "SMASH! FORCE " .. tostring(math.floor(k * 100)) .. "%", Color3.fromRGB(255, 170, 90))
			end)
			local pe = m:FindFirstChild("LowerTorso")
			if pe and pe:IsA("BasePart") then
				local from = pe.Position
				task.delay(2.6, function()
					if pe.Parent then
						local d = math.floor(Vector3.new(pe.Position.X - from.X, 0, pe.Position.Z - from.Z).Magnitude + 0.5)
						if d >= 8 then
							local text = tostring(d) .. " studs!"
							if by and by.Parent then
								local best = (by:GetAttribute("WreckBest") :: number?) or 0
								if d > best then
									by:SetAttribute("WreckBest", d)
									text ..= " NEW BEST!"
								end
							end
							Playground.pop(pe.Position + Vector3.new(0, 4, 0), text, Color3.fromRGB(255, 220, 120))
						end
					end
				end)
			end
			FxService.hit(other.Position, 60 + 100 * k, "CannonPad")
			m.Destroying:Once(function()
				smashed[m] = nil
			end)
			return
		end
		pcall((require(script.Parent.DummyControl) :: any).push, m, away * 120 + Vector3.new(0, 65, 0))
		FxService.hit(other.Position, 120, "CannonPad")
		tearOff(m, Playground.TEAR_BALL, other.Position)
		m.Destroying:Once(function()
			smashed[m] = nil
		end)
	end)
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
	hinge.TargetAngle = if (Config :: any).WRECK_10 then 0 else SWING_ANGLE
	hinge.Parent = arm
	if (Config :: any).WRECK_10 then
		-- 3.6 WRECKING BALL (docs/MACHINES_10.md; Config.WRECK_10): it hangs still; a lever pulls it back with ratchet
		-- clicks while you HOLD (longer = farther = more force; the prompt ring is the gauge), and letting go swings it
		-- with a heavy whoosh. The hit scales with the ball's speed ("SMASH! FORCE 87%", then the distance and a NEW BEST:
		-- WreckBest). A stack of 5 crates stands in its path (a body on top is a multi-hit); they stack again after 12 s.
		local normalSpeed = hinge.AngularSpeed
		local leverBase = part("LeverBase", Vector3.new(2, 1, 2), at(x + 11, 0.5, z + 5), DARK, Enum.Material.Metal)
		local handle = part("LeverHandle", Vector3.new(0.5, 4, 0.5), leverBase.CFrame * CFrame.new(0, 2.5, 0), Color3.fromRGB(210, 40, 40), Enum.Material.SmoothPlastic)
		handle.CanCollide = false
		local handleRest = handle.CFrame
		local ratchet = Instance.new("Sound")
		ratchet.SoundId = "rbxassetid://9116785204" -- (PSE "Metal Ratchet Small Ratchet Clicks 13")
		ratchet.Volume = 0.7
		ratchet.Parent = leverBase
		local whoosh = Instance.new("Sound")
		whoosh.SoundId = "rbxassetid://9120728815" -- (PSE "Whoosh Heavy Punches 1")
		whoosh.Volume = 1
		whoosh.RollOffMaxDistance = 120
		whoosh.Parent = ball
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "HOLD to pull back"
		pp.ObjectText = "Wrecking Ball"
		pp.HoldDuration = 2
		pp.MaxActivationDistance = 12
		pp.RequiresLineOfSight = false
		pp.Parent = handle
		local pulling: { [Player]: number } = {}
		local busyUntil = 0
		local function release(player: Player, power: number)
			if os.clock() < busyUntil then
				return
			end
			busyUntil = os.clock() + 3.5
			wreckBy.player = player
			handle.CFrame = handleRest
			hinge.AngularSpeed = math.rad(140 + 160 * power)
			hinge.TargetAngle = SWING_ANGLE * (0.55 + 0.45 * power)
			whoosh.PlaybackSpeed = 0.8 + 0.3 * power
			whoosh:Play()
			task.delay(1.8, function()
				hinge.AngularSpeed = normalSpeed * 0.6
				hinge.TargetAngle = 0
			end)
		end
		pp.PromptButtonHoldBegan:Connect(function(player)
			if os.clock() < busyUntil then
				return
			end
			local t0 = os.clock()
			pulling[player] = t0
			hinge.AngularSpeed = math.rad(35)
			task.spawn(function()
				while pulling[player] == t0 do
					local k = math.min(1, (os.clock() - t0) / pp.HoldDuration)
					hinge.TargetAngle = -SWING_ANGLE * 1.1 * k
					handle.CFrame = handleRest * CFrame.new(0, -2, 0) * CFrame.Angles(math.rad(-50 * k), 0, 0) * CFrame.new(0, 2, 0)
					ratchet:Play()
					task.wait(0.35)
				end
			end)
		end)
		pp.PromptButtonHoldEnded:Connect(function(player)
			local t0 = pulling[player]
			pulling[player] = nil
			if t0 and os.clock() - t0 > 0.2 then
				release(player, math.min(1, (os.clock() - t0) / pp.HoldDuration))
			end
		end)
		pp.Triggered:Connect(function(player)
			pulling[player] = nil
			release(player, 1)
		end)
		-- the crate stack where it swings through (the release swings toward -Z)
		local homes: { [BasePart]: CFrame } = {}
		local spots = { { -3.2, 1.5 }, { 0, 1.5 }, { 3.2, 1.5 }, { -1.6, 4.5 }, { 1.6, 4.5 } }
		for _, sp in spots do
			local c = part("WreckCrate", Vector3.new(3, 3, 3), at(x + sp[1], sp[2], z - 9), Color3.fromRGB(150, 105, 60), Enum.Material.WoodPlanks)
			c.Anchored = false
			c.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.5, 0.2)
			homes[c] = c.CFrame
		end
		task.defer(function()
			for c in homes do
				pcall(c.SetNetworkOwner, c, nil)
			end
		end)
		task.spawn(function()
			local movedAt = 0
			while folder.Parent do
				task.wait(2)
				local moved = false
				for c, home in homes do
					if c.Parent and (c.Position - home.Position).Magnitude > 1.5 then
						moved = true
					end
				end
				if moved and movedAt == 0 then
					movedAt = os.clock()
				elseif not moved then
					movedAt = 0
				end
				if moved and os.clock() - movedAt > 12 then
					for c, home in homes do
						if c.Parent then
							c.AssemblyLinearVelocity = Vector3.zero
							c.AssemblyAngularVelocity = Vector3.zero
							c.CFrame = home
						end
					end
					movedAt = 0
				end
			end
		end)
	end
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
			if not paused and not (Config :: any).WRECK_10 then
				side = -side
				hinge.TargetAngle = SWING_ANGLE * side
			end
		end
	end)
end

local function buildRamp()
	local RAMP = (require(Shared:WaitForChild("PathPlan")) :: any).RAMP_AT -- (V9-0h: on the rim under LAYOUT_V3)
	if (Config :: any).STRETCH_MACHINE then
		-- (24 Nov 2026, owner: the stretching machine in the ramp's place.)
		-- (F74: under the owner map it stands on the plan's STRETCHER spot, LabLayout10.STRETCH, not the old ramp spot)
		local spot = RAMP
		local L10 = require(Shared:WaitForChild("LabLayout10")) :: any
		if (Config :: any).LAB_OWNERMAP and L10.on and L10.STRETCH then
			spot = L10.STRETCH
		end
		local okM, errM = pcall(function()
			return (require(script.Parent:WaitForChild("StretchMachine")) :: any).build(folder, at(spot.X, 0, spot.Y))
		end)
		if not okM then
			warn("[Playground] stretch machine: " .. tostring(errM))
		end
		return
	end
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
	if true then
		return -- (V10 phase 2, owner: "remove all pictograms")
	end
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
	-- (session v849, owner: "ryk rundt på tingene så de står psykologisk bedst"): the hazard pit is now
	-- the BOXING RING (Config.BOXING_RING; see Server/Systems/BoxingPit), the NEW feature. Moved from the
	-- old lava spot (-27.5, -41) to (0, -32): centred in front of the spawn, so it is the FIRST thing a
	-- new player sees. The bullseye (at (-6, -42) in PathPlan) still lives just behind it; path obstacles
	-- were updated to match (Shared/PathPlan: "Lava" obstacle now (-11, -41) to (11, -23)).
	-- (0.37.1, owner: "the ring is the first thing you see but not our best, it must not be the hook"): behind the
	-- spawn now, between the plaza and the launch stations; the cannon is what the spawn faces.
	-- (0.37.13, owner: "the ring to the garden by the frog": west garden, south of the frog's pond.)
	local x, z, w, d = -111, -28, 21, 18
	local pool = part("LavaPool", Vector3.new(w, 0.4, d), at(x, 0.2, z), LAVA, Enum.Material.CrackedLava)
	-- (session v850, owner: "lavaen skal ikke være under bokseringen, det skal være en helt normal bokse-
	-- ring, man skal bare kunne hoppe en anelse højere"): the hazard launch is off under the ring —
	-- when Config.BOXING_RING is on, no LaunchVelocity on the pool and no DummyAvoid tag. Stepping on
	-- the ring canvas is harmless; the jump boost lives in BoxingPit.dress (a little spring to each jump
	-- while standing on it). The old lava still launches when BOXING_RING is off.
	if not (Config :: any).BOXING_RING then
		pool:SetAttribute("LaunchVelocity", Vector3.new(0, 105, 0)) -- (dummies too: PropContacts)
		CollectionService:AddTag(pool, "DummyAvoid") -- (a fleeing dummy turns aside: ActiveRagdoll)
	end
	-- (21 Nov 2026, Config.LAVA_V2: a real pit, LavaPit: a rounded glowing pool, rocks, embers, a sound
	-- and a warning picture; the pool part stays the trigger.)
	-- (session v848, owner: "udskift lavaen med boxing ring"): if Config.BOXING_RING is on, the pool
	-- is dressed as a BOXING RING instead (Server/Systems/BoxingPit, V3Assets.BoxingRing). The pool
	-- part, LaunchVelocity, DummyAvoid tag and throwOnTouch below stay the same — only the picture
	-- changed. The slot name "LavaPool" is kept so experiments/missions/paths keep resolving.
	local ring = (Config :: any).BOXING_RING == true
	local v2 = (Config :: any).LAVA_V2 == true
	if ring then
		require(script.Parent.BoxingPit).dress(pool, origin.Y + 0.02)
	elseif v2 then
		require(script.Parent.LavaPit).dress(pool, origin.Y + 0.02)
	else
		hazardRim(x, z, w, d, 0.6)
	end
	local flames: { Vector3 } = if ring or v2 then {} else { Vector3.new(-6, 0, -4), Vector3.new(5, 0, 3), Vector3.new(-2, 0, 6) }
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
	if not ring and not v2 then
		local glow = Instance.new("PointLight")
		glow.Color = LAVA
		glow.Range = 22
		glow.Brightness = 2
		glow.Parent = pool
		sign("LAVA!", pool, 7, LAVA)
	end
	-- Step in: up you go, a little to one side.
	-- (session v850: with BOXING_RING on the throwOnTouch is off; the ring is walk-on, the small jump
	-- boost in BoxingPit does the rest.)
	if not (Config :: any).BOXING_RING then
		throwOnTouch(pool, 1.5, 120, "CannonPad", function(root)
			local side = Vector3.new(root.Position.X - pool.Position.X, 0, root.Position.Z - pool.Position.Z)
			local away = if side.Magnitude > 0.5 then side.Unit else Vector3.xAxis
			return away * 18 + Vector3.new(0, 125, 0)
		end)
	end
end

local function buildBullseye()
	-- Where the human cannon's shot comes down (the pad: buildCannon, at 48, 6).
	local land = Playground.cannonLanding(origin + Vector3.new(48 * S, 1, 6 * S)) - origin
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
	local x, z = -30 * S, 32 * S
	if (Config :: any).LAYOUT_V2 then
		x, z = Playground.MACE_V2_AT.X * S, Playground.MACE_V2_AT.Y * S -- (21 Nov 2026: back a little, clear of the moved lava and the new paths)
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
	{ name = "SKY LAUNCH", x = 14 * S, z = 52 * S, velocity = Vector3.new(0, 210, 0), color = Color3.fromRGB(80, 170, 255) },
	{ name = "FLING PAD", x = 32 * S, z = 52 * S, velocity = Vector3.new(-62, 95, -30), color = Color3.fromRGB(190, 90, 255) },
	{ name = "ROCKET WALL", x = 50 * S, z = 52 * S, velocity = Vector3.new(150, 18, 0), color = Color3.fromRGB(255, 70, 50) },
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
		if (Config :: any).REAL_PADS then
			realPad(pad, s.color, Playground.SIGN_ICONS[s.name])
		else
			sign(s.name, pad, 8, s.color)
			sign("PUT RAGDOLL HERE", pad, 5, WHITE)
		end
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
	-- (V9-NOW 19, owner 21 Nov 2026: the badge sat half inside the wall (7 over its middle = its top edge). It hangs
	-- on its own point now, on the side the dummy comes from and over the wall's top, fully in view.)
	local badgeAt = part("CrashWallBadge", Vector3.new(0.2, 0.2, 0.2), at(rocket.x + 30 - 1 - 3.5, 14 + 3, rocket.z), YELLOW)
	badgeAt.Transparency = 1
	badgeAt.CanCollide = false
	badgeAt.CanQuery = false
	badgeAt.CanTouch = false
	sign("CRASH WALL", badgeAt, 0, YELLOW)
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
for k, v in Playground.CHRISTMAS_SPOTS do
	Playground.CHRISTMAS_SPOTS[k] = v * S -- (0.37.0: the bigger lab)
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
	if (Config :: any).REAL_PADS then
		realPad(hearth, RED, nil) -- (V9-NOW 7: the same real pad, no glow)
	end
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
	-- (22 Nov 2026, owner: "a small stand with a button on it, and a real sign: a random free event every
	-- 5 minutes if you press"): a waist-high pedestal with a small red button on top, and a sign board
	-- beside it whose second line counts down to the next free event.
	local face = CFrame.lookAt(origin + Vector3.new(x, 0, z), Vector3.new(origin.X, origin.Y, origin.Z)) -- (its front to the spawn)
	local function local_(dx: number, dy: number, dz: number): CFrame
		return face * CFrame.new(dx, dy, dz)
	end
	local steel = Color3.fromRGB(60, 64, 74)
	local base = part("BigButtonBase", Vector3.new(2.6, 0.4, 2.6), local_(0, 0.2, 0), steel, Enum.Material.Metal)
	part("BigButtonStand", Vector3.new(1.8, 3, 1.8), local_(0, 1.9, 0), Color3.fromRGB(235, 235, 232), Enum.Material.SmoothPlastic)
	part("BigButtonTop", Vector3.new(2.3, 0.3, 2.3), local_(0, 3.55, 0), steel, Enum.Material.Metal)
	part("BigButtonRing", Vector3.new(0.25, 1.7, 1.7), local_(0, 3.8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 196, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local button = part("BigButton", Vector3.new(0.5, 1.3, 1.3), local_(0, 4.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(220, 30, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local lit = Color3.fromRGB(220, 30, 30)
	local dim = Color3.fromRGB(90, 40, 40)
	-- The sign: a board on two posts, beside the stand, readable from both sides.
	part("ButtonSignPost", Vector3.new(0.3, 3.2, 0.3), local_(3.4, 1.6, 0.6), steel, Enum.Material.Metal) -- (22 Nov 2026: up to the board, not through its words)
	part("ButtonSignPost", Vector3.new(0.3, 3.2, 0.3), local_(6.2, 1.6, 0.6), steel, Enum.Material.Metal)
	local board = part("ButtonSign", Vector3.new(3.6, 2.4, 0.2), local_(4.8, 4.4, 0.6), Color3.fromRGB(28, 30, 38), Enum.Material.SmoothPlastic)
	local countdowns: { TextLabel } = {}
	for _, faceId in { Enum.NormalId.Back, Enum.NormalId.Front } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = faceId
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 60
		gui.LightInfluence = 0
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromScale(1, 0.62)
		title.Position = UDim2.fromScale(0, 0.04)
		title.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 220, 70)
		title.Text = "PRESS FOR A FREE\nRANDOM EVENT!"
		title.Parent = gui
		local clock = Instance.new("TextLabel")
		clock.BackgroundTransparency = 1
		clock.Size = UDim2.fromScale(1, 0.3)
		clock.Position = UDim2.fromScale(0, 0.66)
		clock.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
		clock.TextScaled = true
		clock.TextColor3 = Color3.fromRGB(120, 230, 120)
		clock.Text = "READY!"
		clock.Parent = gui
		table.insert(countdowns, clock)
		gui.Parent = board
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Press"
	prompt.ActionText = "Press"
	prompt.ObjectText = "Free event"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = button
	local labOrigin = origin
	local readyAt = 0
	local function showClock()
		local left = math.ceil(readyAt - os.clock())
		for _, c in countdowns do
			if left > 0 then
				c.Text = string.format("NEXT IN %d:%02d", left // 60, left % 60)
				c.TextColor3 = Color3.fromRGB(240, 240, 236)
			else
				c.Text = "READY!"
				c.TextColor3 = Color3.fromRGB(120, 230, 120)
			end
		end
	end
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
		if not Config.BIG_BUTTON and not (player == owner and player:GetAttribute("LabControls") == true) then
			return -- (AUDIT 27 Nov 1: with the free button off, only the Lab Controls owner, in their own lab)
		end
		local EventService = require(script.Parent.EventService)
		-- (Only events that stay in this lab, and only while nothing waits: the server's one queue
		-- stays free for bought events. No train without its engine model.)
		local pool = {}
		for _, id in BUTTON_EVENTS do
			if id ~= "TrainRun" or require(script.Parent.V3Assets).has("Train") then
				table.insert(pool, id)
			end
		end
		local pick = pool[math.random(1, #pool)]
		local started = EventService.current() == nil and EventService.queued() == 0 and not EventService.miniRunning() and EventService.trigger(pick, player.DisplayName, "Free", false, nil, owner.UserId, true) -- (V10 phase 4: every lab on the server)
		if not started then
			prompt.ActionText = "Busy, try again soon"
			task.delay(2.5, function()
				prompt.ActionText = "Press"
			end)
			return
		end
		-- (The Lab Controls pass: its owner, in their own lab, waits LAB_CONTROLS_GAP instead.)
		local gap = if player == owner and player:GetAttribute("LabControls") == true then Config.LAB_CONTROLS_GAP else Config.BIG_BUTTON_GAP
		readyAt = now + gap
		button.Color = dim
		prompt.Enabled = false
		button.CFrame = button.CFrame * CFrame.new(-0.2, 0, 0)
		task.spawn(function()
			while os.clock() < readyAt and board.Parent do
				showClock()
				task.wait(1)
			end
			showClock()
			if button.Parent then
				button.Color = lit
				prompt.Enabled = true
				button.CFrame = button.CFrame * CFrame.new(0.2, 0, 0)
			end
		end)
	end)
	local _ = base
	-- AUDIT 27 Nov 1 (Config.LAB_CONTROLS_BUTTON): the free button is off (owner, 24 Nov), so the stand shows only in the
	-- lab of a player who owns the Lab Controls pass (they bought it: a free random event every LAB_CONTROLS_GAP s).
	if not Config.BIG_BUTTON then
		local names = { BigButtonBase = true, BigButtonStand = true, BigButtonTop = true, BigButtonRing = true, BigButton = true, ButtonSignPost = true, ButtonSign = true }
		local mine: { BasePart } = {}
		local collide: { [BasePart]: boolean } = {}
		for _, c in (button.Parent :: Instance):GetChildren() do
			if names[c.Name] and c:IsA("BasePart") and (c.Position - base.Position).Magnitude < 12 then
				table.insert(mine, c)
				collide[c] = c.CanCollide
			end
		end
		for _, c in countdowns do
			local g = c.Parent
			if g and g:IsA("SurfaceGui") then
				local t = g:FindFirstChildWhichIsA("TextLabel")
				if t and t ~= c then
					t.Text = "LAB CONTROLS:\nA RANDOM EVENT!"
					t.TextScaled = true -- (THE FINISH LINE: the words fit the sign, never cut off)
					t.TextWrapped = true
				end
			end
		end
		prompt.ObjectText = "Lab Controls"
		local shown: boolean? = nil
		task.spawn(function()
			while button.Parent do
				local owner = (require(script.Parent.Lab) :: any).ownerAt(labOrigin)
				local on = owner ~= nil and owner:GetAttribute("LabControls") == true
				if on ~= shown then
					shown = on
					for _, p in mine do
						p.Transparency = if on then 0 else 1
						p.CanCollide = on and collide[p] == true
						p.CanQuery = on
						for _, g in p:GetChildren() do
							if g:IsA("SurfaceGui") then
								g.Enabled = on
							end
						end
					end
					prompt.Parent = if on then button else nil
				end
				task.wait(2)
			end
		end)
	end
end

-- V10 phase 4 (owner: "a wooden info post: 50 likes = Area 51"): a post and a plank sign at the edge of the spawn
-- plaza, readable from both sides. A shared update goal only: nothing is given to anyone who likes (Roblox rules).
local function buildLikePost()
	local wood = Color3.fromRGB(150, 104, 64)
	local dark = Color3.fromRGB(96, 64, 38)
	local x, z = -24 * S, 18 * S
	local face = CFrame.lookAt((at(x, 0, z)).Position, (at(0, 0, 0)).Position)
	for _, sx in { -3.65, 3.65 } do -- (V10: beside the board, not through its text)
		part("LikePost", Vector3.new(0.6, 7, 0.6), face * CFrame.new(sx, 3.5, 0), dark, Enum.Material.Wood)
	end
	local board = part("LikeSign", Vector3.new(6.6, 3.2, 0.4), face * CFrame.new(0, 5.4, 0), wood, Enum.Material.WoodPlanks)
	part("LikeSignTop", Vector3.new(8, 0.4, 0.7), face * CFrame.new(0, 7.1, 0), dark, Enum.Material.Wood)
	for _, side in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = side
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 1
		local list = Instance.new("UIListLayout")
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Parent = gui
		for i, line in { { "LIKE GOAL", 0.26, Color3.fromRGB(255, 236, 200) }, { "50 LIKES = AREA 51", 0.42, Color3.fromRGB(255, 255, 255) }, { "next update", 0.22, Color3.fromRGB(230, 210, 170) } } do
			local t = Instance.new("TextLabel")
			t.LayoutOrder = i
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(0.86, line[2] :: number)
			t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
			t.TextScaled = true
			t.TextColor3 = line[3] :: Color3
			t.TextStrokeColor3 = Color3.fromRGB(60, 36, 20)
			t.TextStrokeTransparency = 0.3
			t.Text = line[1] :: string
			t.Parent = gui
		end
		gui.Parent = board
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
		-- (LAB10: built from a moved origin, so every spot it keeps moves with it: Shared/LabLayout10.)
		do
			local home = origin
			origin = home + LabLayout10.move("Lava")
			local okLava, errLava = pcall(buildLava)
			origin = home
			if not okLava then
				log.warn("lava failed in " .. folder.Name .. ": " .. tostring(errLava))
			end
		end
		if (Config :: any).BULLSEYE ~= false then
			buildBullseye() -- (V9-NOW 17 / V9-0ae: Config.BULLSEYE false = no bullseye; the cannon lands on the open floor)
		end
		if (Config :: any).SPIKE_BLOCKS ~= false then
			buildSpikes() -- (owner, 20 Nov 2026: the red spike plates are gone: Config.SPIKE_BLOCKS)
		end
		buildStations() -- (round 5: PUT RAGDOLL HERE)
		if Config.BIG_BUTTON or (Config :: any).LAB_CONTROLS_BUTTON then
			buildBigButton() -- (v3 Phase C; AUDIT 27 Nov 1: for Lab Controls owners only when the free one is off)
		end
		pcall(buildLikePost) -- (V10 phase 4)
		-- Round 5, phase 3: round pedestals under the things to try.
		pedestal(48 * S, 6 * S, 7.5) -- the human cannon
		-- Round 5, phase 4: SINGLEPLAYER and MULTIPLAYER behind the spawn.
		require(script.Parent.PortalService).buildPortals(folder, origin)
		-- V9-0e: the Map Board and the gold PLACES portal in the spawn's view (a failure never costs the lab).
		if (Config :: any).MAP_BOARD then
			local okBoard, errBoard = pcall(function()
				require(script.Parent.MapBoard).buildLab(folder, origin)
			end)
			if not okBoard then
				log.warn("MapBoard failed in " .. folder.Name .. ": " .. tostring(errBoard))
			end
		end
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
		if (Config :: any).MACE ~= false then
			buildMace() -- (moving too: after parenting)
		end
		-- v3: the lab's dressing from the Creator Store models the place has (LabDress).
		pcall(function()
			require(script.Parent.LabDress).dress(folder, origin)
		end)
		-- 0.37.9: bridges, a slide, a sky deck and jump steps in the height area (after LabDress: it joins the throw tower).
		local okH, errH = pcall(function()
			require(script.Parent.Heights).build(folder, origin)
		end)
		if not okH then
			log.warn("Heights failed in " .. folder.Name .. ": " .. tostring(errH))
		end
		-- v3 Phase C: a car and a monster truck on the east side (after parenting: they move).
		local ok, err = pcall(function()
			require(script.Parent.VehicleService).build(folder, origin)
		end)
		if not ok then
			log.warn("Vehicles failed in " .. folder.Name .. ": " .. tostring(err))
		end
		if (Config :: any).CANNON_TARGETS then
			pcall(Playground.buildCannonTargets, folder, origin)
		end
		-- F88: the ragdoll bowling lane by the spawn (Systems/Bowling, Config.BOWLING).
		local okB, errB = pcall(function()
			require(script.Parent.Bowling).build(folder, origin)
		end)
		if not okB then
			log.warn("Bowling failed in " .. folder.Name .. ": " .. tostring(errB))
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
			if not LabLayout10.on then
				require(script.Parent.LabGarden).build(folder, origin) -- (LAB10: no garden strips inside the compound)
			end
			if (Config :: any).PATHS and not (Config :: any).LAB_NO_PATHS and not LabLayout10.on then
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
	-- LAB10: the crash-test compound over it all: floor, test floor, spawn pad, wall, walkways, skyline, signs,
	-- and the old scattered dressing hidden (Server/Systems/LabV10).
	if lab and LabLayout10.on then
		local okV, errV = pcall(function()
			require(script.Parent:WaitForChild("LabV10")).build(folder, origin)
		end)
		if not okV then
			log.warn("LabV10 failed in " .. folder.Name .. ": " .. tostring(errV))
		end
	end
	-- (GO NOW: THE MAP, Config.LAB_OWNERMAP: the owner's map, 10x the area, phase by phase: Systems/LabOwnerMap.)
	if lab and (Config :: any).LAB_OWNERMAP then
		local okM, errM = pcall(function()
			require(script.Parent:WaitForChild("LabOwnerMap")).build(folder, origin)
		end)
		if not okM then
			log.warn("LabOwnerMap failed in " .. folder.Name .. ": " .. tostring(errM))
		end
	end
	-- GUARD_DOG: the doghouse with its Whistle prompt (Systems/GuardDog).
	if lab and (Config :: any).GUARD_DOG then
		local okD, errD = pcall(function()
			require(script.Parent:WaitForChild("GuardDog")).buildLab(folder, origin)
		end)
		if not okD then
			log.warn("GuardDog failed in " .. folder.Name .. ": " .. tostring(errD))
		end
	end
	-- DESTRUCTION 2 (Config.BREAKABLES): crate stacks you can shoot to planks (Systems/Breakables).
	if lab and (Config :: any).BREAKABLES then
		local okB, errB = pcall(function()
			require(script.Parent:WaitForChild("Breakables")).buildLab(folder, origin)
		end)
		if not okB then
			log.warn("Breakables failed in " .. folder.Name .. ": " .. tostring(errB))
		end
	end
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
					cannonPad = Vector3.new(48 * S, 1, 6 * S),
					landing = Playground.cannonLanding(origin + Vector3.new(48 * S, 1, 6 * S)) - origin,
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

-- MACHINES_10 3.1 (Config.M10_CANNON): the cannon's wind-up and score. Before the shot: a fuse spark at the barrel's back
-- and the watchers near say "Cover your ears!". After it: the ragdoll is followed until it lands; where it lands a big
-- "123 studs!" pops (3 s), with NEW BEST for the player who loaded it (attribute CannonBest), and 1 shot in 20 is
-- GOLDEN (a gold confetti burst, "GOLDEN SHOT!").
local function pop(at: Vector3, text: string, color: Color3)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).WORLD_POPS == false then
		return -- (owner 27 Nov late: "Fjern ALLE de her tekster", also from the machines)
	end
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one * 0.2
	p.Position = at + Vector3.new(0, 4, 0)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 70)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 400
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.1
	l.Text = text
	l.Parent = bb
	bb.Parent = p
	p.Parent = Workspace
	game:GetService("Debris"):AddItem(p, 3)
end
Playground.pop = pop -- (3.2: DropScore pops its heights the same way)
function Playground.cannonWindUp(barrel: CFrame, loadAt: Vector3, seconds: number)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one * 0.2
	p.CFrame = barrel * CFrame.new(0, 1.5, 4)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 120, 30))
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.35, 0)
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Lifetime = NumberRange.new(0.2, 0.4)
	e.Rate = 60
	e.Parent = p
	p.Parent = Workspace
	game:GetService("Debris"):AddItem(p, seconds)
	local dummies = Workspace:FindFirstChild("Dummies")
	for _, w in if dummies then dummies:GetChildren() else {} do
		local wp = w:FindFirstChild("LowerTorso")
		if w:GetAttribute("Watch") ~= nil and wp and wp:IsA("BasePart") and (wp.Position - loadAt).Magnitude < 45 then
			w:SetAttribute("MoodSay", "Cover your ears!")
			task.delay(2.5, function()
				if w.Parent and w:GetAttribute("MoodSay") == "Cover your ears!" then
					w:SetAttribute("MoodSay", nil)
				end
			end)
			break
		end
	end
end
-- 3.1 CANNON part 2 (Config.CANNON_TARGETS; docs/MACHINES_10.md 3.1 "Score"): 3 targets on the landing field: a HAY RING
-- (8 bales in a circle), a PAINT circle (white and red rings) and a little SPLASH pool; a body that lands inside one
-- gets its name and a bonus on top of the distance.
function Playground.buildCannonTargets(into: Instance, labOrigin: Vector3)
	local okP, PlanSpot = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any
	end)
	if not okP then
		return
	end
	local field = PlanSpot.at("LandingField", Vector2.new(-175, 170))
	local f = Instance.new("Model")
	f.Name = "CannonTargets"
	f.Parent = into
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function ground(x: number, z: number): Vector3
		local at = Vector3.new(labOrigin.X + x, labOrigin.Y + 60, labOrigin.Z + z)
		local hit = Workspace:Raycast(at, Vector3.new(0, -140, 0), params)
		return if hit then hit.Position else Vector3.new(at.X, labOrigin.Y, at.Z)
	end
	local function flat(name: string, at: Vector3, r: number, colour: Color3, lift: number)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.1, r * 2, r * 2)
		p.CFrame = CFrame.new(at + Vector3.new(0, lift, 0)) * CFrame.Angles(0, 0, math.rad(90))
		p.Color = colour
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Parent = f
		return p
	end
	local function mark(name: string, at: Vector3, r: number, bonus: number)
		local tag = Instance.new("Part")
		tag.Name = "Target_" .. name
		tag.Anchored, tag.CanCollide, tag.CanQuery, tag.CanTouch, tag.Transparency = true, false, false, false, 1
		tag.Size = Vector3.one
		tag.Position = at
		tag:SetAttribute("Label", name)
		tag:SetAttribute("Radius", r)
		tag:SetAttribute("Bonus", bonus)
		game:GetService("CollectionService"):AddTag(tag, "CannonTarget")
		tag.Parent = f
	end
	-- the hay ring
	local hay = ground(field.X - 12, field.Y - 8)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local b = Instance.new("Part")
		b.Name = "HayBale"
		b.Size = Vector3.new(2.4, 1.6, 1.6)
		b.CFrame = CFrame.new(hay + Vector3.new(math.cos(a) * 6, 0.8, math.sin(a) * 6)) * CFrame.Angles(0, -a, 0)
		b.Color = Color3.fromRGB(214, 180, 92)
		b.Material = Enum.Material.Grass
		b.Anchored = true
		b.Parent = f
	end
	mark("HAY RING", hay, 6, 25)
	-- the paint circle
	local paint = ground(field.X + 10, field.Y + 6)
	flat("PaintOuter", paint, 6, Color3.fromRGB(240, 240, 240), 0.05)
	flat("PaintMid", paint, 4, Color3.fromRGB(220, 50, 60), 0.07)
	flat("PaintIn", paint, 2, Color3.fromRGB(240, 240, 240), 0.09)
	mark("PAINT CIRCLE", paint, 6, 40)
	-- the splash pool
	local pool = ground(field.X + 18, field.Y - 12)
	flat("PoolRim", pool, 5, Color3.fromRGB(200, 200, 205), 0.05)
	local water = flat("PoolWater", pool, 4.3, Color3.fromRGB(70, 160, 220), 0.08)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.2
	mark("SPLASH POOL", pool, 5, 50)
end

function Playground.cannonScore(m: Model, muzzle: Vector3, shooter: Player?)
	local pelvis = m:FindFirstChild("LowerTorso")
	if not (pelvis and pelvis:IsA("BasePart")) then
		return
	end
	task.wait(0.8)
	local t0 = os.clock()
	local still = 0
	while m.Parent and os.clock() - t0 < 9 do
		task.wait(0.2)
		if pelvis.AssemblyLinearVelocity.Magnitude < 8 then
			still += 0.2
			if still >= 0.6 then
				break
			end
		else
			still = 0
		end
	end
	if not m.Parent then
		return
	end
	local d = math.floor(Vector3.new(pelvis.Position.X - muzzle.X, 0, pelvis.Position.Z - muzzle.Z).Magnitude + 0.5)
	local golden = math.random(1, 20) == 1
	local best = if shooter then (shooter:GetAttribute("CannonBest") :: number?) or 0 else 0
	local newBest = shooter ~= nil and d > best
	if shooter and newBest then
		shooter:SetAttribute("CannonBest", d)
	end
	-- (3.1 part 2: a target hit adds its bonus)
	if (Config :: any).CANNON_TARGETS then
		for _, t in game:GetService("CollectionService"):GetTagged("CannonTarget") do
			if t:IsA("BasePart") then
				local flatD = Vector3.new(pelvis.Position.X - t.Position.X, 0, pelvis.Position.Z - t.Position.Z).Magnitude
				if flatD <= ((t:GetAttribute("Radius") :: number?) or 5) + 1 then
					local bonus = (t:GetAttribute("Bonus") :: number?) or 25
					d += bonus
					pop(pelvis.Position + Vector3.new(0, 7, 0), tostring(t:GetAttribute("Label")) .. "! +" .. bonus, Color3.fromRGB(120, 230, 255))
					if shooter then
						-- (AUDIT 15: the painted bullseye is gone; a ragdoll fired onto a target is the PERFECT landing)
						pcall(BadgeAwards.award, shooter, "Bullseye")
					end
					break
				end
			end
		end
	end
	pop(pelvis.Position, tostring(d) .. " studs!" .. (if newBest then "\nNEW BEST!" else ""), if golden then Color3.fromRGB(255, 210, 60) else Color3.new(1, 1, 1))
	if golden then
		pop(pelvis.Position + Vector3.new(0, 4, 0), "GOLDEN SHOT!", Color3.fromRGB(255, 200, 40))
		local c = Instance.new("Part")
		c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.Transparency = true, false, false, false, 1
		c.Size = Vector3.one * 0.2
		c.Position = pelvis.Position + Vector3.new(0, 2, 0)
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 170, 30))
		e.LightEmission = 0.6
		e.Size = NumberSequence.new(0.5, 0.3)
		e.Speed = NumberRange.new(16, 28)
		e.SpreadAngle = Vector2.new(60, 60)
		e.Acceleration = Vector3.new(0, -25, 0)
		e.Lifetime = NumberRange.new(1.2, 2)
		e.Rate = 0
		e.Parent = c
		c.Parent = Workspace
		e:Emit(90)
		game:GetService("Debris"):AddItem(c, 3)
	end
end


return Playground
