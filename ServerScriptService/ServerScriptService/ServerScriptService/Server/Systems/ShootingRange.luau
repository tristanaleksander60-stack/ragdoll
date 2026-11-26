--!strict
-- ShootingRange (24 Nov 2026, owner): WEAPON TESTING, an indoor range behind the creature yard of every lab (behind the
-- compressor, the washer and the mole). Four lanes; at the end of each a real ragdoll stands on a steel stand, a longer
-- way off from lane to lane. The ragdolls are only there while someone is at the range (they cost a phone physics), and a
-- dead, torn or fallen one is swapped for a fresh one. They are ordinary dummies: every weapon hurts them as it does any.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Systems = script.Parent

local ShootingRange = {}

ShootingRange.Z = 134 -- lab z of the front (the yard ends at 129)
ShootingRange.WIDE = 52
ShootingRange.DEEP = 44
ShootingRange.HIGH = 15
ShootingRange.DOOR = 28 -- the opening's width
ShootingRange.DOOR_HIGH = 10
ShootingRange.LINE = 12 -- studs in to the firing line
ShootingRange.TARGETS = { 21, 34, 26, 39 } -- studs in, lane by lane
ShootingRange.NEAR = 42 -- studs from its middle: someone this near brings the targets out
ShootingRange.AWAY = 10 -- s with nobody near before they go
ShootingRange.SWAP = 4 -- s down, dead or torn before a fresh one stands there
ShootingRange.STRAY = 6 -- studs off its stand counts as gone

local WALL = Color3.fromRGB(112, 84, 62)
local WALL_LOW = Color3.fromRGB(84, 63, 48)
local DARK = Color3.fromRGB(46, 42, 40)
local STEEL = Color3.fromRGB(92, 92, 96)
local FLOOR = Color3.fromRGB(122, 119, 114)
local ORANGE = Color3.fromRGB(240, 122, 32)
local WARM = Color3.fromRGB(255, 196, 128)

-- Words painted on a face, in studs (never a screen-sized label).
local function words(on: BasePart, face: Enum.NormalId, text: string, color: Color3)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 24
	g.LightInfluence = 0.2
	g.MaxDistance = 220
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(0.94, 0.8)
	t.Position = UDim2.fromScale(0.03, 0.1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.BuilderSansExtraBold
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = text
	t.Parent = g
	g.Parent = on
end

type Stand = { at: Vector3, look: Vector3, model: Model?, badSince: number? }

local function nearSomeone(middle: Vector3): boolean
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - middle).Magnitude < ShootingRange.NEAR then
			return true
		end
	end
	return false
end

local function bad(s: Stand, m: Model): boolean
	local pelvis = m:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") then
		return true
	end
	local off = pelvis.Position - s.at
	local state = m:GetAttribute("RagdollState")
	local severed = m:GetAttribute("Severed")
	return m:GetAttribute("Vital") == "Dead" or state == "Ragdoll" or state == "Out" or (type(severed) == "string" and severed ~= "")
		or Vector3.new(off.X, 0, off.Z).Magnitude > ShootingRange.STRAY or math.abs(off.Y) > 8
end

-- Once a second: the targets out while someone is here, the spent ones swapped.
local function tend(model: Model, stands: { Stand }, middle: Vector3)
	local DummyFactory = require(Systems:WaitForChild("DummyFactory")) :: any
	local Lab = require(Systems:WaitForChild("Lab")) :: any
	local EventService = require(Systems:WaitForChild("EventService")) :: any
	local VisitorService = require(Systems:WaitForChild("VisitorService")) :: any
	local seenAt = -math.huge
	while model.Parent do
		task.wait(1)
		local now = os.clock()
		if nearSomeone(middle) then
			seenAt = now
		end
		local owner: Player? = if now - seenAt < ShootingRange.AWAY then Lab.ownerAt(middle) else nil
		local lanes = #stands
		if owner and VisitorService.capFor(owner) <= 14 then
			lanes = 3 -- (a phone or a tablet simulates them: one fewer)
		end
		for i, s in stands do
			local m = s.model
			if m and not m.Parent then
				m, s.model, s.badSince = nil, nil, nil
			end
			if m then
				local held = m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil
				if not owner or i > lanes then
					if not held then
						m:Destroy()
						s.model, s.badSince = nil, nil
					end
				elseif not held and bad(s, m) then
					s.badSince = s.badSince or now
					if now - (s.badSince :: number) >= ShootingRange.SWAP then
						m:Destroy()
						s.model, s.badSince = nil, nil
					end
				else
					s.badSince = nil
				end
			elseif owner and i <= lanes and EventService.dummyRoom() > 2 then
				-- (The factory looks for the ground from 20 studs over the point: from under the roof, not from over it.)
				local made = DummyFactory.spawn(s.at - Vector3.new(0, 8, 0), s.look, owner) :: Model
				made.Name = "RangeTarget"
				made:SetAttribute("RangeTarget", true)
				made:SetAttribute("Personality", "Brave")
				made:SetAttribute("Greeter", -1) -- (nobody's greeter: it stands where it is, neither flees nor wanders off to help)
				made:SetAttribute("Home", s.at)
				made:SetAttribute("HomeLook", s.look)
				s.model = made
			end
		end
	end
	for _, s in stands do
		if s.model then
			s.model:Destroy()
		end
	end
end

function ShootingRange.buildLab(folder: Instance, origin: Vector3): (Model, { Stand })
	local model = Instance.new("Model")
	model.Name = "ShootingRange"
	local W, D, H = ShootingRange.WIDE, ShootingRange.DEEP, ShootingRange.HIGH
	local at = CFrame.new(origin + Vector3.new(0, 0.2, ShootingRange.Z)) -- (floor level, the middle of the front; +Z goes in)
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material, solid: boolean?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = at * CFrame.new(offset)
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if solid == false then
			p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
		end
		p.Parent = model
		return p
	end
	local function upright(p: Part, height: number, across: number): Part
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(height, across, across)
		p.CFrame *= CFrame.Angles(0, 0, math.rad(90))
		return p
	end
	local concrete, metal, neon, paint = Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.Neon, Enum.Material.SmoothPlastic
	local door, doorH = ShootingRange.DOOR, ShootingRange.DOOR_HIGH
	local side = (W - door) / 2
	-- The shell: closed walls with a darker foot, a roof that reaches out over the front, steel beams under it.
	part("Floor", Vector3.new(W, 0.6, D), Vector3.new(0, -0.3, D / 2), FLOOR, concrete)
	part("Apron", Vector3.new(door + 6, 0.5, 5), Vector3.new(0, -0.27, -2.5), FLOOR, concrete)
	part("WallBack", Vector3.new(W, H, 1), Vector3.new(0, H / 2, D - 0.5), WALL, concrete)
	part("FootBack", Vector3.new(W - 2, 3, 0.2), Vector3.new(0, 1.5, D - 1.1), WALL_LOW, concrete, false)
	for _, s in { -1, 1 } do
		part("WallSide", Vector3.new(1, H, D - 2), Vector3.new(s * (W / 2 - 0.5), H / 2, D / 2), WALL, concrete)
		part("FootSide", Vector3.new(0.2, 3, D - 2), Vector3.new(s * (W / 2 - 1.1), 1.5, D / 2), WALL_LOW, concrete, false)
		part("WallFront", Vector3.new(side, H, 1), Vector3.new(s * (W / 2 - side / 2), H / 2, 0.5), WALL, concrete)
		part("Pier", Vector3.new(2, H, 1.1), Vector3.new(s * (door / 2 + 1), H / 2, -0.55), DARK, metal)
		part("PierLine", Vector3.new(0.3, doorH - 1, 0.1), Vector3.new(s * (door / 2 + 1), doorH / 2, -1.15), ORANGE, neon, false)
	end
	part("Lintel", Vector3.new(door, H - doorH, 1), Vector3.new(0, (H + doorH) / 2, 0.5), WALL, concrete)
	part("Roof", Vector3.new(W + 2, 0.9, D + 4), Vector3.new(0, H + 0.45, D / 2 - 1), DARK, metal)
	part("RoofEdge", Vector3.new(W + 2.2, 0.35, 0.2), Vector3.new(0, H + 0.45, -3.1), ORANGE, paint, false)
	for _, z in { 12, 23, 34 } do
		part("Beam", Vector3.new(W - 2, 0.9, 0.6), Vector3.new(0, H - 0.45, z), STEEL, metal, false)
	end
	local sign = part("Sign", Vector3.new(door - 4, 3.2, 0.3), Vector3.new(0, (H + doorH) / 2, -0.2), DARK, metal, false)
	words(sign, Enum.NormalId.Front, "WEAPON TESTING", Color3.fromRGB(255, 170, 84))
	part("Threshold", Vector3.new(door, 0.08, 0.8), Vector3.new(0, 0.03, 0.5), ORANGE, paint, false)
	-- The lanes.
	local lanes = #ShootingRange.TARGETS
	local lane = (W - 2) / lanes
	local line = ShootingRange.LINE
	part("FireLine", Vector3.new(W - 2, 0.06, 0.5), Vector3.new(0, 0.04, line + 1.4), ORANGE, paint, false)
	part("Backstop", Vector3.new(W - 2, 6, 0.6), Vector3.new(0, 3, D - 1.5), DARK, Enum.Material.DiamondPlate)
	for i = 1, lanes - 1 do
		local x = -W / 2 + 1 + lane * i
		part("Kerb", Vector3.new(0.7, 1.1, D - line - 4.5), Vector3.new(x, 0.55, (D + line) / 2 + 0.4), WALL_LOW, concrete)
		part("KerbLine", Vector3.new(0.75, 0.12, D - line - 4.5), Vector3.new(x, 1.13, (D + line) / 2 + 0.4), ORANGE, paint, false)
		part("Booth", Vector3.new(0.6, 7, 5), Vector3.new(x, 3.5, line - 2), DARK, metal)
	end
	-- (How far it is, painted across the floor.)
	for _, far in { 10, 20 } do
		local z = line + 1.4 + far
		part("Range" .. far, Vector3.new(W - 2, 0.05, 0.25), Vector3.new(0, 0.04, z), Color3.fromRGB(225, 222, 214), paint, false)
		local tag = part("RangeTag" .. far, Vector3.new(3, 0.05, 1.6), Vector3.new(-W / 2 + 3, 0.05, z - 1.2), FLOOR, concrete, false)
		words(tag, Enum.NormalId.Top, tostring(far), Color3.fromRGB(240, 236, 226))
	end
	local stands: { Stand } = {}
	for i, deep in ShootingRange.TARGETS do
		local x = -W / 2 + 1 + lane * (i - 0.5)
		part("Counter", Vector3.new(lane, 0.4, 1.8), Vector3.new(x, 3, line), STEEL, metal)
		part("CounterEdge", Vector3.new(lane - 0.6, 0.12, 0.1), Vector3.new(x, 3.1, line - 0.95), ORANGE, paint, false)
		local plate = part("Number", Vector3.new(3, 2, 0.2), Vector3.new(x, H - 2.4, line - 0.2), DARK, metal, false)
		words(plate, Enum.NormalId.Front, tostring(i), Color3.fromRGB(255, 170, 84))
		-- The stand: a steel disc with an orange rim, a post and a cross bar behind the ragdoll.
		upright(part("StandRim", Vector3.one, Vector3.new(x, 0.1, deep), ORANGE, paint, false), 0.2, 5.4)
		upright(part("StandDisc", Vector3.one, Vector3.new(x, 0.15, deep), STEEL, Enum.Material.DiamondPlate), 0.3, 5)
		part("StandPost", Vector3.new(0.4, 6.4, 0.4), Vector3.new(x, 3.2, deep + 2.2), DARK, metal, false)
		part("StandBar", Vector3.new(3, 0.3, 0.3), Vector3.new(x, 6.2, deep + 2.2), DARK, metal, false)
		local spot = (at * CFrame.new(x, 0.3, deep)).Position
		table.insert(stands, { at = spot, look = (at * CFrame.new(x, 0.3, 0)).Position, model = nil, badSince = nil })
		-- Hanging lamps: one over the shooter, one over the target.
		for n, z in { line - 2, deep - 1 } do
			part("LampRod", Vector3.new(0.15, 1.6, 0.15), Vector3.new(x, H - 0.8, z), DARK, metal, false)
			local shade = upright(part("LampShade", Vector3.one, Vector3.new(x, H - 1.8, z), DARK, metal, false), 0.7, 2.4)
			upright(part("LampGlow", Vector3.one, Vector3.new(x, H - 2.2, z), WARM, neon, false), 0.12, 1.9)
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Left -- (the cylinder's foot: straight down)
			light.Angle = 110
			light.Range = 24
			light.Color = WARM
			light.Brightness = if n == 1 then 1.6 else 2.4
			light.Shadows = n == 2
			light.Enabled = false -- (Client/WorldLights lights the nearest few)
			light.Parent = shade
			CollectionService:AddTag(light, "WorldLight")
		end
	end
	model.Parent = folder
	task.spawn(tend, model, stands, (at * CFrame.new(0, 3, D / 2 - 4)).Position)
	return model, stands
end

return ShootingRange
