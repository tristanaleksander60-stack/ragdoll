--!strict
-- What your avatar holds: the picked tool, when it is one you hold (Toys: held = true, the
-- Blaster), sits in your right hand where everyone sees it. The client says which tool it picked
-- ("Hold", a tool id, a few a second); the server builds the model, welds it to the hand and keeps it
-- through respawns. Pure looks: it never collides, never blocks a tap and weighs nothing.
-- (Phase C gives each held tool its own arm pose and swing.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Toys = require(Shared.Toys)
local Log = require(Shared.Log)
local N7Models = require(Shared.N7Models)

local log = Log.new("Held")

local MODEL_NAME = "HeldTool"
local HOLDS_PER_SECOND = 10

local HeldService = {}
HeldService.SCALE_MIN = 0.7 -- (the weapon sized to the avatar: tiny bodies)
HeldService.SCALE_MAX = 1.5 -- (and giants)

local holding: { [Player]: string? } = {}
local window: { [Player]: { start: number, count: number } } = {}
local latest: { [Player]: string } = {} -- a pick over the limit: shown when the window ends

-- Fixes a piece to the body where it was built. A Weld with its offset written down (not a
-- WeldConstraint, whose offset is taken from wherever the pieces happen to be when it wakes up: the
-- hand weld moves the grip first, and a smacker's end came out a few studs off).
local function fix(body: BasePart, piece: BasePart)
	local weld = Instance.new("Weld")
	weld.Part0 = body
	weld.Part1 = piece
	weld.C0 = body.CFrame:ToObjectSpace(piece.CFrame)
	weld.Parent = piece
end

local function part(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	return p
end

-- Round 2 (N4): real handguns (the G17 you start with, the Deagle), built along -Z (the muzzle)
-- from the grip at the origin: a slide on a frame, an angled grip, a trigger guard. A little larger
-- than life on purpose: it has to read from the camera behind the avatar on a phone. The "Tip" is
-- the muzzle (shots leave from it), dark like the rest.
local function handgun(slide: Vector3, slideColor: Color3, frameColor: Color3, material: Enum.Material): Model
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	local body = part("Body", slide, slideColor, material)
	body.CFrame = CFrame.new(0, 0.62, -slide.Z / 2 + 0.55)
	body.Parent = model
	local frame = part("Frame", Vector3.new(slide.X * 0.92, slide.Y * 0.55, slide.Z * 0.82), frameColor)
	frame.CFrame = CFrame.new(0, 0.62 - slide.Y / 2 - slide.Y * 0.25, -slide.Z * 0.41 + 0.45)
	frame.Parent = model
	local grip = part("Grip", Vector3.new(slide.X * 0.95, 1.05, 0.5), frameColor)
	grip.CFrame = CFrame.new(0, 0.0, 0.18) * CFrame.Angles(math.rad(-18), 0, 0)
	grip.Parent = model
	local guard = part("Guard", Vector3.new(slide.X * 0.4, 0.08, 0.5), frameColor)
	guard.CFrame = CFrame.new(0, 0.12, -0.3)
	guard.Parent = model
	local trigger = part("Trigger", Vector3.new(0.08, 0.22, 0.08), Color3.fromRGB(25, 25, 28))
	trigger.CFrame = CFrame.new(0, 0.26, -0.2)
	trigger.Parent = model
	local sight = part("Sight", Vector3.new(0.1, 0.1, 0.12), Color3.fromRGB(230, 230, 230))
	sight.CFrame = CFrame.new(0, 0.62 + slide.Y / 2 + 0.05, -slide.Z + 0.65)
	sight.Parent = model
	local tip = part("Tip", Vector3.new(0.12, 0.2, 0.2), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
	tip.Shape = Enum.PartType.Cylinder
	tip.CFrame = CFrame.new(0, 0.66, -slide.Z + 0.5) * CFrame.Angles(0, math.rad(90), 0)
	tip.Parent = model
	for _, piece in { frame, grip, guard, trigger, sight, tip } do
		fix(body, piece)
	end
	model.PrimaryPart = grip
	return model
end

local function blaster(): Model -- (the G17: its id stays "Blaster")
	return handgun(Vector3.new(0.4, 0.42, 1.75), Color3.fromRGB(38, 40, 44), Color3.fromRGB(28, 29, 32), Enum.Material.Metal)
end
local function deagle(): Model
	return handgun(Vector3.new(0.48, 0.55, 2.3), Color3.fromRGB(175, 178, 185), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
end

-- A pump shotgun: a long barrel over the pump, a wooden stock back past the grip.
local function shotgun(): Model
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	local metal = Color3.fromRGB(45, 46, 50)
	local wood = Color3.fromRGB(120, 80, 45)
	local body = part("Body", Vector3.new(0.45, 0.55, 1.4), metal, Enum.Material.Metal)
	body.CFrame = CFrame.new(0, 0.6, -0.35)
	body.Parent = model
	local barrel = part("Barrel", Vector3.new(3.0, 0.24, 0.24), metal, Enum.Material.Metal)
	barrel.Shape = Enum.PartType.Cylinder
	barrel.CFrame = CFrame.new(0, 0.75, -2.5) * CFrame.Angles(0, math.rad(90), 0)
	barrel.Parent = model
	local pump = part("Pump", Vector3.new(0.36, 0.3, 1.0), wood, Enum.Material.Wood)
	pump.CFrame = CFrame.new(0, 0.5, -2.0)
	pump.Parent = model
	local stock = part("Stock", Vector3.new(0.38, 0.6, 1.5), wood, Enum.Material.Wood)
	stock.CFrame = CFrame.new(0, 0.45, 1.0) * CFrame.Angles(math.rad(8), 0, 0)
	stock.Parent = model
	local grip = part("Grip", Vector3.new(0.4, 0.9, 0.45), wood, Enum.Material.Wood)
	grip.CFrame = CFrame.new(0, 0.05, 0.25) * CFrame.Angles(math.rad(-20), 0, 0)
	grip.Parent = model
	local tip = part("Tip", Vector3.new(0.1, 0.26, 0.26), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
	tip.Shape = Enum.PartType.Cylinder
	tip.CFrame = CFrame.new(0, 0.75, -4.0) * CFrame.Angles(0, math.rad(90), 0)
	tip.Parent = model
	for _, piece in { barrel, pump, stock, grip, tip } do
		fix(body, piece)
	end
	model.PrimaryPart = grip
	return model
end

-- A smacker: a handle in the fist (the grip) and its business end further along -Z, all welded to
-- the handle's body. head: the striking end's size, colour and shape.
local function smacker(handleLength: number, handleColor: Color3, headSize: Vector3, headColor: Color3, headShape: Enum.PartType?, headMaterial: Enum.Material?): Model
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	local body = part("Body", Vector3.new(0.32, 0.32, handleLength), handleColor, Enum.Material.Wood)
	body.CFrame = CFrame.new(0, 0, -handleLength / 2 + 0.3)
	body.Parent = model
	local grip = part("Grip", Vector3.new(0.4, 0.4, 0.7), Color3.fromRGB(40, 34, 70))
	grip.CFrame = CFrame.new(0, 0, 0)
	grip.Parent = model
	-- (Not called "Head": that is a body part's name.) A cylinder's axis is its X: the pan's disc
	-- faces sideways, the way it swings.
	local striker = part("Striker", headSize, headColor, headMaterial)
	striker.Shape = headShape or Enum.PartType.Block
	striker.CFrame = CFrame.new(0, 0, -handleLength + 0.3 - headSize.Z / 2 + 0.1)
	striker.Parent = model
	for _, piece in { grip, striker } do
		fix(body, piece)
	end
	model.PrimaryPart = grip
	return model
end

local function bat(): Model
	-- A bat is one long tapering piece: a thick head on a thin handle.
	return smacker(2.2, Color3.fromRGB(200, 150, 90), Vector3.new(0.6, 0.6, 1.8), Color3.fromRGB(210, 160, 100), Enum.PartType.Block, Enum.Material.Wood)
end
local function pan(): Model
	return smacker(1.6, Color3.fromRGB(60, 60, 70), Vector3.new(0.25, 2.2, 2.2), Color3.fromRGB(150, 155, 170), Enum.PartType.Cylinder, Enum.Material.Metal)
end
local function hammer(): Model
	return smacker(2.6, Color3.fromRGB(170, 110, 70), Vector3.new(1.6, 1.0, 1.0), Color3.fromRGB(220, 60, 60), Enum.PartType.Block, Enum.Material.SmoothPlastic)
end
local function golf(): Model
	return smacker(3.6, Color3.fromRGB(200, 200, 210), Vector3.new(0.35, 0.3, 0.7), Color3.fromRGB(110, 200, 120), Enum.PartType.Block, Enum.Material.Metal)
end

-- Phase H: a crossbow, a nail gun, spell wands and the portal gun, built the same way (along -Z
-- from the grip, a "Tip" at the muzzle where shots leave from).
local function gunLike(bodySize: Vector3, bodyColor: Color3, tipColor: Color3, extra: ((Model, BasePart) -> ())?): Model
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	local body = part("Body", bodySize, bodyColor)
	body.CFrame = CFrame.new(0, 0.55, -bodySize.Z / 2 + 0.4)
	body.Parent = model
	local grip = part("Grip", Vector3.new(0.45, 1.0, 0.55), Color3.fromRGB(40, 34, 70))
	grip.CFrame = CFrame.new(0, -0.05, 0.15) * CFrame.Angles(math.rad(-15), 0, 0)
	grip.Parent = model
	local tip = part("Tip", Vector3.new(0.3, 0.4, 0.4), tipColor, Enum.Material.Neon)
	tip.Shape = Enum.PartType.Cylinder
	tip.CFrame = CFrame.new(0, 0.6, -bodySize.Z + 0.35) * CFrame.Angles(0, math.rad(90), 0)
	tip.Parent = model
	fix(body, grip)
	fix(body, tip)
	if extra then
		extra(model, body)
	end
	model.PrimaryPart = grip
	return model
end

local function crossbow(): Model
	return gunLike(Vector3.new(0.5, 0.5, 2.6), Color3.fromRGB(130, 85, 45), Color3.fromRGB(200, 200, 210), function(model, body)
		local limbs = part("Limbs", Vector3.new(3.2, 0.25, 0.3), Color3.fromRGB(90, 60, 35), Enum.Material.Wood)
		limbs.CFrame = CFrame.new(0, 0.6, -1.9)
		limbs.Parent = model
		local string_ = part("String", Vector3.new(3.0, 0.06, 0.06), Color3.fromRGB(240, 240, 230))
		string_.CFrame = CFrame.new(0, 0.6, -1.4)
		string_.Parent = model
		fix(body, limbs)
		fix(body, string_)
	end)
end
local function nailGun(): Model
	return gunLike(Vector3.new(0.7, 0.9, 1.8), Color3.fromRGB(255, 160, 30), Color3.fromRGB(150, 160, 175), function(model, body)
		local mag = part("Magazine", Vector3.new(0.35, 0.8, 1.2), Color3.fromRGB(60, 60, 66))
		mag.CFrame = CFrame.new(0, 0.0, -1.0)
		mag.Parent = model
		fix(body, mag)
	end)
end
local function wand(color: Color3): () -> Model
	return function(): Model
		return gunLike(Vector3.new(0.2, 0.2, 2.2), Color3.fromRGB(70, 45, 30), color, function(model, body)
			local star = part("Star", Vector3.new(0.6, 0.6, 0.6), color, Enum.Material.Neon)
			star.Shape = Enum.PartType.Ball
			star.CFrame = CFrame.new(0, 0.6, -2.0)
			star.Parent = model
			fix(body, star)
		end)
	end
end
local function portalGun(): Model
	return gunLike(Vector3.new(0.8, 0.8, 1.9), Color3.fromRGB(70, 40, 120), Color3.fromRGB(255, 70, 190), function(model, body)
		local ring = part("Ring", Vector3.new(0.3, 1.0, 1.0), Color3.fromRGB(50, 225, 235), Enum.Material.Neon)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(0, 0.6, -1.3) * CFrame.Angles(0, math.rad(90), 0)
		ring.Parent = model
		fix(body, ring)
	end)
end

local function slimeCannon(): Model
	return gunLike(Vector3.new(0.9, 0.9, 2.0), Color3.fromRGB(60, 140, 50), Color3.fromRGB(110, 230, 80), function(model, body)
		local tank = part("Tank", Vector3.new(1.0, 1.0, 1.0), Color3.fromRGB(110, 230, 80), Enum.Material.Glass)
		tank.Shape = Enum.PartType.Ball
		tank.Transparency = 0.25
		tank.CFrame = CFrame.new(0, 1.35, -0.6)
		tank.Parent = model
		fix(body, tank)
	end)
end


-- Round 2 (N4): the crowbar and the blades. A smacker, with the pieces that make it what it is
-- added on (in the handle's frame: along -Z from the fist, +Y the edge's side).
local function withPieces(model: Model, pieces: { { name: string, size: Vector3, color: Color3, material: Enum.Material?, at: CFrame, shape: Enum.PartType?, neon: boolean? } }): Model
	local body = model:FindFirstChild("Body") :: BasePart
	for _, spec in pieces do
		local piece = part(spec.name, spec.size, spec.color, if spec.neon then Enum.Material.Neon else spec.material)
		if spec.shape then
			piece.Shape = spec.shape
		end
		piece.CFrame = spec.at
		piece.Parent = model
		fix(body, piece)
	end
	return model
end
local STEEL = Color3.fromRGB(200, 205, 215)
local function crowbar(): Model
	-- A red iron bar with a hooked claw at the end.
	local model = smacker(2.8, Color3.fromRGB(200, 50, 45), Vector3.new(0.26, 0.6, 0.26), Color3.fromRGB(200, 50, 45), Enum.PartType.Block, Enum.Material.Metal)
	;(model:FindFirstChild("Body") :: BasePart).Material = Enum.Material.Metal
	return withPieces(model, {
		{ name = "Claw", size = Vector3.new(0.22, 0.22, 0.5), color = Color3.fromRGB(200, 50, 45), material = Enum.Material.Metal, at = CFrame.new(0, 0.55, -2.55) },
	})
end
local function axe(): Model
	local model = smacker(2.7, Color3.fromRGB(150, 100, 60), Vector3.new(0.3, 0.35, 0.4), Color3.fromRGB(70, 70, 76), Enum.PartType.Block, Enum.Material.Metal)
	return withPieces(model, {
		{ name = "Blade", size = Vector3.new(0.1, 1.1, 0.9), color = STEEL, material = Enum.Material.Metal, at = CFrame.new(0, 0.55, -2.3) },
	})
end
local function cleaver(): Model
	local model = smacker(1.1, Color3.fromRGB(40, 34, 30), Vector3.new(0.1, 0.1, 0.1), STEEL, Enum.PartType.Block, Enum.Material.Metal)
	return withPieces(model, {
		{ name = "Blade", size = Vector3.new(0.08, 0.95, 1.5), color = STEEL, material = Enum.Material.Metal, at = CFrame.new(0, 0.3, -1.45) },
	})
end
local function katana(): Model
	local model = smacker(1.1, Color3.fromRGB(30, 28, 34), Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(30, 28, 34), Enum.PartType.Block, Enum.Material.Fabric)
	return withPieces(model, {
		{ name = "Guard", size = Vector3.new(0.12, 0.6, 0.6), color = Color3.fromRGB(190, 160, 70), material = Enum.Material.Metal, at = CFrame.new(0, 0, -0.85) * CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder },
		{ name = "Blade", size = Vector3.new(0.06, 0.24, 3.6), color = Color3.fromRGB(225, 230, 240), material = Enum.Material.Metal, at = CFrame.new(0, 0.03, -2.75) },
	})
end
local function plasmaBlade(): Model
	local glow = Color3.fromRGB(90, 220, 255)
	local model = smacker(1.1, Color3.fromRGB(150, 155, 165), Vector3.new(0.1, 0.1, 0.1), glow, Enum.PartType.Block, Enum.Material.Metal)
	;(model:FindFirstChild("Body") :: BasePart).Material = Enum.Material.Metal
	withPieces(model, {
		{ name = "Emitter", size = Vector3.new(0.4, 0.4, 0.3), color = Color3.fromRGB(60, 62, 70), material = Enum.Material.Metal, at = CFrame.new(0, 0, -0.85) },
		{ name = "Blade", size = Vector3.new(0.22, 0.22, 3.4), color = glow, neon = true, at = CFrame.new(0, 0, -2.7) },
	})
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 8
	light.Brightness = 1.5
	light.Parent = model:FindFirstChild("Blade")
	return model
end
local function chainsaw(): Model
	return gunLike(Vector3.new(0.8, 0.9, 1.4), Color3.fromRGB(255, 140, 30), Color3.fromRGB(70, 72, 78), function(model, body)
		local bar = part("Bar", Vector3.new(0.14, 0.45, 2.4), Color3.fromRGB(150, 155, 165), Enum.Material.Metal)
		bar.CFrame = CFrame.new(0, 0.5, -2.1)
		bar.Parent = model
		local chain = part("Chain", Vector3.new(0.18, 0.55, 2.45), Color3.fromRGB(50, 50, 55), Enum.Material.DiamondPlate)
		chain.CFrame = CFrame.new(0, 0.5, -2.1)
		chain.Transparency = 0.2
		chain.Parent = model
		local handle = part("TopHandle", Vector3.new(0.18, 0.5, 0.9), Color3.fromRGB(40, 34, 30))
		handle.CFrame = CFrame.new(0, 1.2, -0.3)
		handle.Parent = model
		fix(body, bar)
		fix(body, chain)
		fix(body, handle)
	end)
end

-- Each held tool and how it sits in the fist (in the hand's own frame): the blaster level and turned
-- a little outwards, the smackers pointing up and forward, ready to swing.
local BUILDERS: { [string]: { build: () -> Model, tilt: CFrame } } = {
	Blaster = { build = blaster, tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Bat = { build = bat, tilt = CFrame.Angles(math.rad(55), math.rad(-10), 0) },
	-- (22 Nov 2026: the Magic Wand: a dark stick with a glowing purple star ball at its tip.)
	Wand = { build = function(): Model
		return smacker(1.5, Color3.fromRGB(60, 40, 30), Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(200, 120, 255), Enum.PartType.Ball, Enum.Material.SmoothPlastic) -- (no neon: owner, 21 Nov)
	end, tilt = CFrame.Angles(math.rad(40), 0, 0) },
	Pan = { build = pan, tilt = CFrame.Angles(math.rad(50), math.rad(-10), 0) },
	Hammer = { build = hammer, tilt = CFrame.Angles(math.rad(55), math.rad(-10), 0) },
	Golf = { build = golf, tilt = CFrame.Angles(math.rad(-60), 0, 0) },
	Crossbow = { build = crossbow, tilt = CFrame.Angles(0, math.rad(-14), 0) },
	NailGun = { build = nailGun, tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Shrink = { build = wand(Color3.fromRGB(190, 120, 255)), tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Chicken = { build = wand(Color3.fromRGB(255, 220, 90)), tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Float = { build = wand(Color3.fromRGB(140, 200, 255)), tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Slowmo = { build = wand(Color3.fromRGB(200, 140, 255)), tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Portal = { build = portalGun, tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Slime = { build = slimeCannon, tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Deagle = { build = deagle, tilt = CFrame.Angles(0, math.rad(-14), 0) },
	Shotgun = { build = shotgun, tilt = CFrame.Angles(0, math.rad(-10), 0) },
	Chainsaw = { build = chainsaw, tilt = CFrame.Angles(math.rad(-10), math.rad(-10), 0) },
	Crowbar = { build = crowbar, tilt = CFrame.Angles(math.rad(55), math.rad(-10), 0) },
	Axe = { build = axe, tilt = CFrame.Angles(math.rad(55), math.rad(-10), 0) },
	Cleaver = { build = cleaver, tilt = CFrame.Angles(math.rad(55), math.rad(-10), 0) },
	Katana = { build = katana, tilt = CFrame.Angles(math.rad(55), math.rad(-10), 0) },
	PlasmaBlade = { build = plasmaBlade, tilt = CFrame.Angles(math.rad(55), math.rad(-10), 0) },
}

local function remove(character: Model)
	local old = character:FindFirstChild(MODEL_NAME)
	if old then
		old:Destroy()
	end
end

-- Round 2 (N7): a real model when the place has one (ReplicatedStorage.N7Assets.Weapons.<id>,
-- Creator Store models with their scripts stripped, kept with a "Grip" part at the origin, -Z
-- forward, every piece welded to it, and a "Tip" at the muzzle or blade end). The built one above
-- stays as the stand-in when there is none. How it sits in the fist follows its kind.
local GUN_TILT = CFrame.Angles(0, math.rad(-14), 0)
local BLADE_TILT = CFrame.Angles(math.rad(55), math.rad(-10), 0)
local function assetFor(toyId: string): Model?
	local found = N7Models.source("Weapons", toyId)
	return if found and found.PrimaryPart then found else nil
end
HeldService.assetFor = assetFor

-- Puts the model in the right hand, pointing the way the avatar faces.
local function attach(character: Model, toyId: string)
	remove(character)
	local asset = assetFor(toyId)
	local toy = Toys.byId[toyId]
	local spec = BUILDERS[toyId]
	if asset and toy then
		local move = toy.move
		spec = {
			build = function(): Model
				local copy = (asset :: Model):Clone()
				N7Models.clean(copy) -- (only what draws it: never a script or a prompt)
				-- Never part of the body, whatever the stored model says: no collisions, no taps, no
				-- weight, not anchored (it rides on its welds).
				for _, d in copy:GetDescendants() do
					if d:IsA("BasePart") then
						d.CanCollide = false
						d.CanQuery = false
						d.CanTouch = false
						d.Massless = true
						d.Anchored = false
						d.CastShadow = false
					end
				end
				return copy
			end,
			tilt = if spec then spec.tilt elseif move == "Shoot" or move == "Aim" or move == "Cast" then GUN_TILT else BLADE_TILT,
		}
	end
	-- (Owner, 21 Nov 2026: "every weapon right in the hand, whatever Roblox skin you wear". An R6 body has no RightHand:
	-- its "Right Arm" holds it, the fist at the arm's lower end.)
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not spec or not hand or not hand:IsA("BasePart") or not root or not root:IsA("BasePart") then
		return
	end
	local model = spec.build()
	model.Name = MODEL_NAME
	local grip = model.PrimaryPart :: BasePart
	-- (Any skin: a tall or a tiny avatar holds a weapon sized to it. The root part grows with the body's height
	-- scale (2 studs tall at 1), so the weapon follows it, within sane bounds.)
	local k = math.clamp(root.Size.Y / 2, HeldService.SCALE_MIN, HeldService.SCALE_MAX)
	if math.abs(k - 1) > 0.04 then
		pcall(function()
			model:ScaleTo(model:GetScale() * k)
		end)
	end
	local bodyFound = model:FindFirstChild("Body")
	local body = if bodyFound and bodyFound:IsA("BasePart") then bodyFound else grip
	-- A fixed grip in the hand's own frame (the hand of a standing R15 avatar faces the way the
	-- avatar does), so the angle never depends on the pose the hand had when the tool was picked.
	local gripInBody = body.CFrame:ToObjectSpace(grip.CFrame)
	-- Round 4, M10: held in the palm, not at the middle of the hand. The palm is the avatar's own
	-- RightGripAttachment (its position only: the hand's -Z-forward frame stays the grip's frame), so
	-- it fits every body and scale; a model's 'Palm' attachment on its grip marks where the fist
	-- closes on the handle and is what lands there.
	local gripAt = hand:FindFirstChild("RightGripAttachment")
	local palmAt = if gripAt and gripAt:IsA("Attachment") then gripAt.Position else Vector3.new(0, -hand.Size.Y / 2, 0)
	-- (A package with an odd grip point: the fist stays inside the hand's own box, never off in the air.)
	local half = hand.Size / 2
	palmAt = Vector3.new(math.clamp(palmAt.X, -half.X, half.X), math.clamp(palmAt.Y, -half.Y, half.Y), math.clamp(palmAt.Z, -half.Z, half.Z))
	-- (A package whose hand mesh is turned in its part: the wrist joint's C1 says how; the grip follows the body's
	-- frame, not the mesh's, so every skin holds it the same way.)
	local wrist = hand:FindFirstChild("RightWrist")
	local turn = if wrist and wrist:IsA("Motor6D") then wrist.C1.Rotation else CFrame.identity
	local palm = CFrame.new(palmAt) * turn
	local palmOnGrip = grip:FindFirstChild("Palm")
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = grip
	weld.C0 = palm * spec.tilt * CFrame.new(-gripInBody.Position) * gripInBody
	if palmOnGrip and palmOnGrip:IsA("Attachment") then
		weld.C1 = CFrame.new(palmOnGrip.Position)
	end
	weld.Parent = grip
	model:SetAttribute("Tool", toyId)
	model:SetAttribute("Worn", true) -- not part of the body when it goes limp (ActiveRagdoll)
	model.Parent = character
end

-- (Any skin: when the avatar's look loads after the weapon (its package hands swap in, its scale lands), the old
-- hand is gone and the weapon would hang in the air: it is put in the new hand.)
local function watchBody(player: Player, character: Model)
	local pending = false
	local function again()
		if pending then
			return
		end
		pending = true
		task.delay(0.2, function()
			pending = false
			local id = holding[player]
			if id and character.Parent and player.Character == character then
				attach(character, id)
			end
		end)
	end
	character.ChildAdded:Connect(function(c)
		if c.Name == "RightHand" or c.Name == "Right Arm" or c.Name == "HumanoidRootPart" then
			again()
		end
	end)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if humanoid then
		for _, n in { "BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "BodyTypeScale", "BodyProportionScale" } do
			local v = humanoid:FindFirstChild(n)
			if v and v:IsA("NumberValue") then
				v.Changed:Connect(again)
			end
		end
	end
	local loaded = player.CharacterAppearanceLoaded:Connect(function(c)
		if c == character then
			again()
		end
	end)
	character.Destroying:Once(function()
		loaded:Disconnect()
	end)
end

local onHold: (Player, unknown) -> ()

function onHold(player: Player, toyId: unknown)
	if type(toyId) ~= "string" then
		return
	end
	-- "" (M3 fix 1): the hand empty, whatever tool is picked (doctor mode rests the tools).
	if toyId == "" then
		latest[player] = nil
		if holding[player] ~= nil then
			holding[player] = nil
			if player.Character then
				remove(player.Character)
			end
		end
		return
	end
	local toy = Toys.byId[toyId :: string]
	if not toy then
		return
	end
	-- A tool not unlocked yet is not shown in the hand either (the hand keeps what it held).
	local ProgressService = require(script.Parent.ProgressService) :: any
	if not ProgressService.isUnlocked(player, toy) then
		return
	end
	local now = os.clock()
	local w = window[player]
	if not w or now - w.start > 1 then
		w = { start = now, count = 0 }
		window[player] = w
	end
	w.count += 1
	if w.count > HOLDS_PER_SECOND then
		-- Too many picks at once: the last one still wins, a moment later (the hand never stays wrong).
		local waiting = latest[player] ~= nil
		latest[player] = toy.id
		if not waiting then
			task.delay(math.max(0, 1 - (now - w.start)) + 0.05, function()
				local id = latest[player]
				latest[player] = nil
				if id and player.Parent then
					onHold(player, id)
				end
			end)
		end
		return
	end
	latest[player] = nil
	local wanted = if toy.held then toy.id else nil
	if holding[player] == wanted then
		return
	end
	holding[player] = wanted
	local character = player.Character
	if character then
		if wanted then
			attach(character, wanted)
		else
			remove(character)
		end
	end
end

-- Tests: the remote handler, and what the server thinks a player holds.
HeldService.onHold = function(player: Player, toyId: unknown)
	onHold(player, toyId)
end
function HeldService.holdingOf(player: Player): string?
	return holding[player]
end

function HeldService.start()
	Net.event(Net.Names.Hold).OnServerEvent:Connect(onHold)
	local function onJoin(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(watchBody, player, character)
			local id = holding[player]
			if id then
				local _ = character:WaitForChild("RightHand", 5) or character:FindFirstChild("Right Arm")
				character:WaitForChild("HumanoidRootPart", 5)
				if character.Parent and holding[player] == id then
					attach(character, id)
				end
			end
		end)
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		onJoin(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		holding[player] = nil
		window[player] = nil
		latest[player] = nil
	end)
	log.info("ready")
end

return HeldService
