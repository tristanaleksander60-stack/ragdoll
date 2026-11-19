--!strict
-- Makes the instances for one build piece. Everything comes out anchored ("frozen", as in build
-- mode); BuildService brings it to life on Play. The same models serve as placement ghosts.
--
-- Every model:
--   attribute Item, PrimaryPart = the part that attaches to whatever the piece was placed on
--   parts carry attribute BuildIndex (1, 2, ...) in a fixed order, so a save can say which part of
--   a piece another piece is attached to
--   joints (HingeConstraint, PrismaticConstraint, ...) are created here and configured from the
--   piece's setting; BuildService only switches them on and off
-- Local frame: the piece's bounding box centred on the origin; for facesOut items +Y points away
-- from the surface the piece stands on.

local Catalog = require(script.Parent.Catalog)
local Orientation = require(script.Parent.Orientation)
local Codec = require(script.Parent.Codec)

type Piece = Codec.Piece

local Factory = {}

local STEEL = Color3.fromRGB(150, 155, 170)
local DARK = Color3.fromRGB(45, 45, 52)
local GAP = 0.05 -- between the moving halves of a joint, so they never rub

type Builder = {
	model: Model,
	frame: CFrame,
	count: number,
	color: Color3,
}

local function part(b: Builder, name: string, size: Vector3, localCf: CFrame, color: Color3?, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = b.frame * localCf
	p.Color = color or b.color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	b.count += 1
	p:SetAttribute("BuildIndex", b.count)
	p.Parent = b.model
	return p
end

local function wedge(b: Builder, name: string, size: Vector3, localCf: CFrame, color: Color3?): WedgePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = b.frame * localCf
	p.Color = color or b.color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	b.count += 1
	p:SetAttribute("BuildIndex", b.count)
	p.Parent = b.model
	return p
end

-- An attachment whose primary axis (the joint axis) is `axis` in the part's own frame.
local function axisAttachment(parent: BasePart, name: string, worldPoint: Vector3, worldAxis: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = parent
	local other = if math.abs(worldAxis.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
	a.WorldCFrame = CFrame.fromMatrix(worldPoint, worldAxis, other:Cross(worldAxis).Unit)
	return a
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Name = "Fix"
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function noCollide(a: BasePart, b: BasePart)
	local n = Instance.new("NoCollisionConstraint")
	n.Part0 = a
	n.Part1 = b
	n.Parent = a
end

-- Two halves of a joint along local Y, meeting at local y = `at`.
local function halves(b: Builder, baseSize: Vector3, topSize: Vector3, at: number, baseColor: Color3, topColor: Color3): (Part, Part)
	local base = part(b, "Base", baseSize - Vector3.new(0, GAP, 0), CFrame.new(0, at - baseSize.Y / 2 - GAP / 2, 0), baseColor)
	local top = part(b, "Top", topSize - Vector3.new(0, GAP, 0), CFrame.new(0, at + topSize.Y / 2 + GAP / 2, 0), topColor)
	noCollide(base, top)
	return base, top
end

local function hinge(b: Builder, a: BasePart, c: BasePart, localPoint: Vector3, localAxis: Vector3): HingeConstraint
	local point = b.frame:PointToWorldSpace(localPoint)
	local axis = b.frame:VectorToWorldSpace(localAxis)
	local h = Instance.new("HingeConstraint")
	h.Name = "Joint"
	h.Attachment0 = axisAttachment(a, "JointA", point, axis)
	h.Attachment1 = axisAttachment(c, "JointB", point, axis)
	h.Parent = a
	return h
end

local function slider(b: Builder, a: BasePart, c: BasePart, localPoint: Vector3): PrismaticConstraint
	local point = b.frame:PointToWorldSpace(localPoint)
	local axis = b.frame:VectorToWorldSpace(Vector3.yAxis)
	local s = Instance.new("PrismaticConstraint")
	s.Name = "Joint"
	s.Attachment0 = axisAttachment(a, "JointA", point, axis)
	s.Attachment1 = axisAttachment(c, "JointB", point, axis)
	s.Parent = a
	return s
end

local MOTOR_SPEED = { 2.5, 7, -4 } -- rad/s for Slow, Fast, Reverse
local WHEEL_SPEED = { 14, -14, 0 }
local PISTON_REACH = { 2.5, 5 }
local SPRING_STIFFNESS = { 900, 2600 }

local builders: { [string]: (Builder, Piece, Catalog.Item) -> () } = {}

-- Blocks ------------------------------------------------------------------------------------
builders.Block = function(b, _, item)
	part(b, "Body", item.size, CFrame.new())
end
builders.Plate = builders.Block
builders.Beam = builders.Block
builders.Plank = function(b, _, item)
	part(b, "Body", item.size, CFrame.new(), nil, Enum.Material.WoodPlanks)
end
builders.Wall = builders.Block
builders.Wedge = function(b, _, item)
	wedge(b, "Body", item.size, CFrame.new())
end
builders.Ramp = builders.Wedge
builders.Ball = function(b, _, item)
	part(b, "Body", item.size, CFrame.new(), nil, nil, Enum.PartType.Ball)
end
builders.BigBlock = builders.Block
builders.Pillar = builders.Block
builders.Glass = function(b, _, item)
	local p = part(b, "Body", item.size, CFrame.new(), nil, Enum.Material.Glass)
	p.Transparency = 0.5
end
builders.Corner = function(b, _, item)
	local p = Instance.new("CornerWedgePart")
	p.Name = "Body"
	p.Size = item.size
	p.CFrame = b.frame
	p.Color = b.color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	b.count += 1
	p:SetAttribute("BuildIndex", b.count)
	p.Parent = b.model
end
builders.Cylinder = function(b, _, item)
	-- Upright: the cylinder's axis (its X) along local Y.
	part(b, "Body", item.size, CFrame.Angles(0, 0, math.pi / 2), nil, nil, Enum.PartType.Cylinder)
end

-- Machines ----------------------------------------------------------------------------------
builders.Hinge = function(b)
	local base, top = halves(b, Vector3.new(2, 1, 2), Vector3.new(2, 1, 2), 0, STEEL, Color3.fromRGB(190, 195, 205))
	hinge(b, base, top, Vector3.zero, Vector3.yAxis)
end

builders.Motor = function(b, piece)
	local base, top = halves(b, Vector3.new(2, 1, 2), Vector3.new(2, 1, 2), 0, DARK, Color3.fromRGB(80, 170, 255))
	local mark = part(b, "Mark", Vector3.new(0.3, 0.12, 0.9), CFrame.new(0, 1.03, 0.45), Color3.new(1, 1, 1), Enum.Material.Neon)
	mark.CanCollide = false
	weld(top, mark)
	local h = hinge(b, base, top, Vector3.zero, Vector3.yAxis)
	h.ActuatorType = Enum.ActuatorType.Motor
	h.MotorMaxTorque = 1e7
	h.MotorMaxAcceleration = 40
	h.AngularVelocity = 0
	h:SetAttribute("RunSpeed", MOTOR_SPEED[piece.setting] or MOTOR_SPEED[1])
end

builders.Piston = function(b, piece)
	local base = part(b, "Base", Vector3.new(2, 1 - GAP, 2), CFrame.new(0, -0.5 - GAP / 2, 0), DARK)
	local head = part(b, "Top", Vector3.new(1.8, 1 - GAP, 1.8), CFrame.new(0, 0.5 + GAP / 2, 0), Color3.fromRGB(255, 160, 50))
	local rod = part(b, "Rod", Vector3.new(0.7, 1, 0.7), CFrame.new(0, 0, 0), STEEL, Enum.Material.Metal)
	rod.CanCollide = false
	weld(head, rod)
	noCollide(base, head)
	noCollide(base, rod)
	local s = slider(b, base, head, Vector3.zero)
	s.ActuatorType = Enum.ActuatorType.Servo
	s.LimitsEnabled = true
	s.LowerLimit = 0
	s.UpperLimit = PISTON_REACH[piece.setting] or PISTON_REACH[1]
	s.ServoMaxForce = 1e7
	s.Speed = 22
	s.TargetPosition = 0
	s:SetAttribute("Reach", s.UpperLimit)
end

builders.Spring = function(b, piece)
	local base = part(b, "Base", Vector3.new(2, 1 - GAP, 2), CFrame.new(0, -0.5 - GAP / 2, 0), DARK)
	local head = part(b, "Top", Vector3.new(2, 1 - GAP, 2), CFrame.new(0, 0.5 + GAP / 2, 0), Color3.fromRGB(120, 230, 140))
	noCollide(base, head)
	local s = slider(b, base, head, Vector3.zero)
	s.LimitsEnabled = true
	s.LowerLimit = 0
	s.UpperLimit = 3
	local spring = Instance.new("SpringConstraint")
	spring.Name = "Spring"
	spring.Attachment0 = base:FindFirstChild("JointA") :: Attachment
	spring.Attachment1 = head:FindFirstChild("JointB") :: Attachment
	spring.Stiffness = SPRING_STIFFNESS[piece.setting] or SPRING_STIFFNESS[1]
	spring.Damping = 20
	spring.FreeLength = 3.5 -- preloaded: it pops up on Play
	spring.Visible = true
	spring.Coils = 5
	spring.Radius = 0.7
	spring.Thickness = 0.12
	spring.Color = BrickColor.new("Medium stone grey")
	spring.Parent = base
end

builders.Wheel = function(b, piece)
	local hub = part(b, "Base", Vector3.new(1, 1 - GAP, 1), CFrame.new(0, -0.5 - GAP / 2, 0), STEEL, Enum.Material.Metal)
	-- Cylinder axis (its X) along local Y.
	local wheel = part(b, "Top", Vector3.new(1 - GAP, 3, 3), CFrame.new(0, 0.5 + GAP / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), DARK, nil, Enum.PartType.Cylinder)
	wheel.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1.6, 0.2, 50, 1)
	noCollide(hub, wheel)
	local h = hinge(b, hub, wheel, Vector3.zero, Vector3.yAxis)
	local speed = WHEEL_SPEED[piece.setting] or WHEEL_SPEED[1]
	if speed ~= 0 then
		h.ActuatorType = Enum.ActuatorType.Motor
		h.MotorMaxTorque = 3e5
		h.MotorMaxAcceleration = 25
	end
	h.AngularVelocity = 0
	h:SetAttribute("RunSpeed", speed)
end

builders.Thruster = function(b, piece)
	local mount = part(b, "Base", Vector3.new(2, 1, 2), CFrame.new(0, -0.5, 0), DARK)
	local nozzle = part(b, "Nozzle", Vector3.new(1, 1.6, 1.6), CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(240, 110, 40), nil, Enum.PartType.Cylinder)
	weld(mount, nozzle)
	local at = Instance.new("Attachment")
	at.Name = "Thrust"
	at.Parent = mount
	at.WorldCFrame = b.frame * CFrame.new(0, 1, 0)
	local force = Instance.new("VectorForce")
	force.Name = "Push"
	force.Attachment0 = at
	force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	force.ApplyAtCenterOfMass = false
	force.Enabled = false
	force:SetAttribute("Strength", if piece.setting == 2 then 9000 else 4000)
	force.Parent = mount
	local flame = Instance.new("ParticleEmitter")
	flame.Name = "Flame"
	flame.Enabled = false
	flame.Rate = 60
	flame.Lifetime = NumberRange.new(0.15, 0.3)
	flame.Speed = NumberRange.new(14, 20)
	flame.EmissionDirection = Enum.NormalId.Top
	flame.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	flame.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 90, 40))
	flame.LightEmission = 1
	flame.Parent = at
end

-- Toys --------------------------------------------------------------------------------------
builders.Trampoline = function(b)
	local base = part(b, "Base", Vector3.new(6, 0.6, 6), CFrame.new(0, -0.2, 0), DARK)
	local pad = part(b, "TrampolinePad", Vector3.new(5.4, 0.3, 5.4), CFrame.new(0, 0.25, 0), Color3.fromRGB(80, 170, 255), Enum.Material.Fabric)
	weld(base, pad)
end

builders.Conveyor = function(b, piece)
	local belt = part(b, "Belt", Vector3.new(6, 1, 2), CFrame.new(), Color3.fromRGB(60, 60, 70), Enum.Material.DiamondPlate)
	belt:SetAttribute("BeltSpeed", ({ 10, 22, -12 })[piece.setting] or 10)
	for i = -1, 1 do
		local arrow = part(b, "Arrow", Vector3.new(0.6, 0.06, 1.2), CFrame.new(i * 2, 0.53, 0), Color3.fromRGB(255, 205, 60), Enum.Material.Neon)
		arrow.CanCollide = false
		weld(belt, arrow)
	end
end

builders.Bumper = function(b)
	part(b, "Base", Vector3.new(2, 0.6, 2), CFrame.new(0, -1.2, 0), DARK)
	local ball = part(b, "BumperBall", Vector3.new(3, 3, 3) - Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 0.3, 0), Color3.fromRGB(255, 90, 160), Enum.Material.Neon, Enum.PartType.Ball)
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.2, 1, 1, 100)
	weld(b.model:FindFirstChild("Base") :: BasePart, ball)
end

builders.Fan = function(b, piece)
	local ring = part(b, "Base", Vector3.new(1, 4, 4), CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(170, 220, 255), nil, Enum.PartType.Cylinder)
	ring.Transparency = 0.35
	-- Lying across the ring; its local Z is the fan's axis so the spinner turns it the right way.
	local blade = part(b, "Blade", Vector3.new(3.4, 0.8, 0.2), CFrame.new(0, 0.3, 0) * CFrame.Angles(math.pi / 2, 0, 0), Color3.new(1, 1, 1))
	blade.CanCollide = false
	weld(ring, blade)
	blade:SetAttribute("Spin", true)
	ring:SetAttribute("Wind", if piece.setting == 2 then 22 else 11)
end

builders.Cannon = function(b, piece)
	local base = part(b, "Base", Vector3.new(2, 1, 2), CFrame.new(0, -1.5, 0), DARK)
	local barrel = part(b, "Barrel", Vector3.new(3, 1.6, 1.6), CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 72, 82), Enum.Material.Metal, Enum.PartType.Cylinder)
	weld(base, barrel)
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Parent = barrel
	muzzle.WorldCFrame = b.frame * CFrame.new(0, 2.2, 0)
	base:SetAttribute("Ammo", if piece.setting == 2 then "Bowling" else "Ball")
end

builders.Crate = function(b)
	part(b, "TNT", Vector3.new(2, 2, 2), CFrame.new(), Color3.fromRGB(205, 45, 45), Enum.Material.WoodPlanks)
end

builders.Seesaw = function(b)
	local fulcrum = wedge(b, "Base", Vector3.new(2, 2, 2), CFrame.new(0, -0.5, 0), DARK)
	local plank = part(b, "Plank", Vector3.new(10, 0.6, 2), CFrame.new(0, 1.2, 0), Color3.fromRGB(205, 160, 105), Enum.Material.WoodPlanks)
	noCollide(fulcrum, plank)
	hinge(b, fulcrum, plank, Vector3.new(0, 0.6, 0), Vector3.zAxis)
end

builders.Swing = function(b)
	-- A gallows: post on the left, an arm out to the right with the ball on its end. On Play the
	-- arm swings down; the ball clears the floor at the bottom of the swing.
	local post = part(b, "Base", Vector3.new(1.5, 9.5, 1.5), CFrame.new(-5.25, -1.25, 0), DARK, Enum.Material.Metal)
	local arm = part(b, "Arm", Vector3.new(6.5, 0.8, 0.8), CFrame.new(-2, 4, 0), STEEL, Enum.Material.Metal)
	local ball = part(b, "WreckingBall", Vector3.new(4, 4, 4), CFrame.new(2.5, 4, 0), Color3.fromRGB(70, 72, 82), Enum.Material.Metal, Enum.PartType.Ball)
	ball.CustomPhysicalProperties = PhysicalProperties.new(6, 0.4, 0.2)
	weld(arm, ball)
	noCollide(post, arm)
	noCollide(post, ball)
	hinge(b, post, arm, Vector3.new(-5.25, 4, 0), Vector3.zAxis)
end

-- Logic -------------------------------------------------------------------------------------
builders.Button = function(b)
	local base = part(b, "Base", Vector3.new(2, 0.6, 2), CFrame.new(0, -0.2, 0), DARK)
	local cap = part(b, "Cap", Vector3.new(0.4, 1.4, 1.4), CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 70, 70), Enum.Material.Neon, Enum.PartType.Cylinder)
	weld(base, cap)
end

builders.Timer = function(b, piece)
	local base = part(b, "Base", Vector3.new(2, 0.6, 2), CFrame.new(0, -0.2, 0), DARK)
	local face = part(b, "Face", Vector3.new(0.3, 1.6, 1.6), CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 205, 60), nil, Enum.PartType.Cylinder)
	weld(base, face)
	base:SetAttribute("Period", ({ 1, 2, 4 })[piece.setting] or 1)
end

builders.Sensor = function(b)
	local plate = part(b, "SensorPad", Vector3.new(4, 0.4, 4), CFrame.new(0, -0.3, 0), Color3.fromRGB(255, 205, 60))
	for i = -1, 1, 2 do
		local stripe = part(b, "Stripe", Vector3.new(4, 0.05, 0.5), CFrame.new(0, -0.08, i * 1.2), Color3.fromRGB(40, 40, 46))
		stripe.CanCollide = false
		weld(plate, stripe)
	end
end

-- The cframe of a piece in the world.
function Factory.cframeOf(piece: Piece, origin: Vector3): CFrame
	return CFrame.new(origin + piece.pos) * Orientation.get(piece.rot)
end

-- The main color of a piece (paint or the item's own color).
function Factory.colorOf(piece: Piece): Color3
	local item = Catalog.byId[piece.item]
	if item.paintable and piece.color > 0 then
		return Catalog.palette[piece.color]
	end
	return item.color
end

-- Builds the frozen model for a piece.
function Factory.build(piece: Piece, origin: Vector3): Model
	local item = Catalog.byId[piece.item]
	assert(item, "unknown item " .. tostring(piece.item))
	local model = Instance.new("Model")
	model.Name = item.id
	model:SetAttribute("Item", item.id)
	local b: Builder = { model = model, frame = Factory.cframeOf(piece, origin), count = 0, color = Factory.colorOf(piece) }
	local builder = builders[item.id]
	assert(builder, "no builder for " .. item.id)
	builder(b, piece, item)
	model.PrimaryPart = Factory.parts(model)[1]
	return model
end

-- The parts of a piece in BuildIndex order (index 1 attaches to the parent).
function Factory.parts(model: Model): { BasePart }
	local list: { BasePart } = {}
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d:GetAttribute("BuildIndex") then
			table.insert(list, d)
		end
	end
	table.sort(list, function(a, c)
		return (a:GetAttribute("BuildIndex") :: number) < (c:GetAttribute("BuildIndex") :: number)
	end)
	return list
end

-- Turns a built model into a see-through placement ghost.
function Factory.ghost(model: Model, ok: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = math.max(d.Transparency, 0.45)
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
			d.Material = Enum.Material.ForceField
			d.Color = if ok then Color3.fromRGB(120, 230, 140) else Color3.fromRGB(255, 90, 70)
		elseif d:IsA("Constraint") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
end

for _, item in Catalog.list do
	assert(builders[item.id], "Factory has no builder for " .. item.id)
end

return Factory
