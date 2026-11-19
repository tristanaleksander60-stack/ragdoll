--!strict
-- World/Feel v2 (Config.WORLD_V2): the dressing that makes a lab read as a designed place, built
-- from code over what Playground and Lab already build (19 Nov 2026, the owner: "the models and
-- everything look low quality"). Art direction: a bright toy crash-test lab. White wall panels and
-- painted steel, yellow-black hazard stripes, black rubber, safety orange and lab blue as accents;
-- chamfered edges (WedgeParts) and trims instead of plain blocks; props near where you look.
--
-- Everything here is a picture: anchored, CanCollide/CanQuery/CanTouch off, so no shot, grab, build
-- ray, camera ray or Touched sees it and play is the same with WORLD_V2 off. It goes in a "WorldV2"
-- folder inside the playground being dressed (Workspace.Playground.LabN, built when someone first
-- owns the lab), so Workspace.Labs keeps its own part budget (T36) and other labs' dressing leaves
-- this screen with them (PlotPrivacy). Lamps are tagged WorldLight and built switched off: each
-- screen lights only the nearest few its device can afford (Client\WorldLights, Config.FX_CAPS).
--
-- The lab's plan, seen from its spawn (0, 0) looking down -Z (where the dummies stand):
--   far end (z -101)  the backdrop wall: panels, pilasters, a chamfered cornice, a striped skirting
--   z -9              the CRASH TEST ZONE gantry over the dummies' row, two spot lamps on it
--   spawn to cannon   orange arrows on the floor and a HUMAN CANNON board by the pad
--   over the lab      a dotted arc from the cannon to the bullseye (where the shot comes down)
--   sides and back    crates, barrels, tyres, carts, light towers with cables, warning boards
--   the attractions   tower rails and board, cannon beacon, wrecking-ball braces, ramp rails,
--                     station boards; in season the chimney cap, the present's bow, the sleigh's runners

local CollectionService = game:GetService("CollectionService")

local Finish = require(script.Parent.Finish)

local WorldDress = {}

WorldDress.FOLDER = "WorldV2"
WorldDress.LIGHT_TAG = "WorldLight"

-- The palette (one place: the whole lab is painted from it).
local C = {
	panel = Color3.fromRGB(232, 235, 240),
	steel = Color3.fromRGB(118, 126, 140),
	frame = Color3.fromRGB(44, 48, 58),
	yellow = Color3.fromRGB(255, 200, 40),
	black = Color3.fromRGB(26, 26, 30),
	orange = Color3.fromRGB(255, 122, 40),
	blue = Color3.fromRGB(60, 150, 255),
	red = Color3.fromRGB(225, 50, 50),
	rubber = Color3.fromRGB(40, 42, 48),
	lamp = Color3.fromRGB(255, 244, 214),
	white = Color3.fromRGB(245, 246, 250),
	brass = Color3.fromRGB(196, 160, 80),
}
WorldDress.PALETTE = table.freeze(C)

type Look = string | Enum.Material

local parent: Instance
local origin = Vector3.zero
local parts = 0
local lights = 0
local maxLights = 12

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(origin + Vector3.new(x, y, z))
end

local function finish(p: BasePart, look: Look?)
	if look == nil then
		p.Material = Enum.Material.SmoothPlastic
	elseif type(look) == "string" then
		Finish.apply(p, look :: any)
	else
		p.Material = look :: Enum.Material
	end
end

local function picture(p: BasePart, name: string, size: Vector3, cf: CFrame, color: Color3, look: Look?)
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = math.max(size.X, size.Y, size.Z) >= 8
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	finish(p, look)
	p.Parent = parent
	parts += 1
end

local function box(name: string, size: Vector3, cf: CFrame, color: Color3, look: Look?): Part
	local p = Instance.new("Part")
	picture(p, name, size, cf, color, look)
	return p
end

local function wedge(name: string, size: Vector3, cf: CFrame, color: Color3, look: Look?): WedgePart
	local p = Instance.new("WedgePart")
	picture(p, name, size, cf, color, look)
	return p
end

-- A cylinder from a to b.
local function rod(name: string, a: Vector3, b: Vector3, diameter: number, color: Color3, look: Look?): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	local length = math.max((b - a).Magnitude, 0.05)
	-- (A cylinder's axis is its X: turn -Z onto the line, then X onto -Z.)
	-- (A line straight up or down needs another "up" for lookAt.)
	local dir = (b - a).Unit
	local up = if math.abs(dir.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	local cf = CFrame.lookAt(a:Lerp(b, 0.5), b, up) * CFrame.Angles(0, math.rad(90), 0)
	picture(p, name, Vector3.new(length, diameter, diameter), cf, color, look)
	return p
end

-- A flat disc lying on the floor (centre x, z; height over the ground).
local function disc(name: string, x: number, z: number, y: number, radius: number, color: Color3, look: Look?): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	picture(p, name, Vector3.new(0.05, radius * 2, radius * 2), at(x, y, z) * CFrame.Angles(0, 0, math.rad(90)), color, look)
	p.CastShadow = false
	return p
end

-- A box whose top edges are chamfered (bevel b): a body, an inset top and four sloped strips. `cf`
-- is the box's middle; its local +Y is the bevelled face (a sign turned to face you: see panel).
local function bevelBox(name: string, size: Vector3, cf: CFrame, b: number, color: Color3, look: Look?, trim: Color3?)
	local body = box(name, Vector3.new(size.X, size.Y - b, size.Z), cf * CFrame.new(0, -b / 2, 0), color, look)
	local top = trim or color
	box(name .. "Top", Vector3.new(size.X - 2 * b, b, size.Z - 2 * b), cf * CFrame.new(0, size.Y / 2 - b / 2, 0), top, look)
	local y = size.Y / 2 - b / 2
	-- (A wedge's slope faces its -Z and rises to its +Z: each one looks outward from the box.)
	wedge(name .. "Bevel", Vector3.new(size.X - 2 * b, b, b), cf * CFrame.new(0, y, -size.Z / 2 + b / 2), top, look)
	wedge(name .. "Bevel", Vector3.new(size.X - 2 * b, b, b), cf * CFrame.new(0, y, size.Z / 2 - b / 2) * CFrame.Angles(0, math.pi, 0), top, look)
	wedge(name .. "Bevel", Vector3.new(size.Z - 2 * b, b, b), cf * CFrame.new(-size.X / 2 + b / 2, y, 0) * CFrame.Angles(0, math.rad(90), 0), top, look)
	wedge(name .. "Bevel", Vector3.new(size.Z - 2 * b, b, b), cf * CFrame.new(size.X / 2 - b / 2, y, 0) * CFrame.Angles(0, -math.rad(90), 0), top, look)
	return body
end

-- A box with only its front top edge chamfered (the edge you see; 3 parts, not bevelBox's 6). Its
-- local -Z is the front.
local function chamferFront(name: string, size: Vector3, cf: CFrame, b: number, color: Color3, look: Look?, trim: Color3?)
	local top = trim or color
	local body = box(name, Vector3.new(size.X, size.Y - b, size.Z), cf * CFrame.new(0, -b / 2, 0), color, look)
	box(name .. "Top", Vector3.new(size.X, b, size.Z - b), cf * CFrame.new(0, size.Y / 2 - b / 2, b / 2), top, look)
	wedge(name .. "Bevel", Vector3.new(size.X, b, b), cf * CFrame.new(0, size.Y / 2 - b / 2, -size.Z / 2 + b / 2), top, look)
	return body
end

-- A box with a thin cap of another colour on top (a trim; 2 parts).
local function lipBox(name: string, size: Vector3, cf: CFrame, lip: number, color: Color3, look: Look?, trim: Color3)
	local body = box(name, Vector3.new(size.X, size.Y - lip, size.Z), cf * CFrame.new(0, -lip / 2, 0), color, look)
	box(name .. "Lip", Vector3.new(size.X + 0.08, lip, size.Z + 0.08), cf * CFrame.new(0, size.Y / 2 - lip / 2, 0), trim, look)
	return body
end

-- Diagonal yellow-black hazard stripes drawn on one face of a part (GUI frames, not parts).
local function stripes(p: BasePart, face: Enum.NormalId, count: number)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Stripes"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(64 * count, 64)
	gui.LightInfluence = 1
	gui.MaxDistance = 160
	local clip = Instance.new("Frame")
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundColor3 = C.yellow
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	for i = 0, count do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Size = UDim2.fromOffset(32, 160)
		bar.Position = UDim2.fromOffset(i * 64 + 16, 32)
		bar.Rotation = 45
		bar.BackgroundColor3 = C.black
		bar.BorderSizePixel = 0
		bar.Parent = clip
	end
	clip.Parent = gui
	gui.Parent = p
end

-- Words on a part's front (the game's own words; nobody types anything here).
local function words(p: BasePart, text: string, color: Color3, background: Color3?, canvas: Vector2?, face: Enum.NormalId?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Words"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = canvas or Vector2.new(600, 150)
	gui.LightInfluence = 0.3
	gui.MaxDistance = 220
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if background then 0 else 1
	label.BackgroundColor3 = background or C.black
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = label
	label.Parent = gui
	gui.Parent = p
end

-- A lamp, switched off: the screen lights the nearest few (Client\WorldLights). Over the lab's
-- light budget it is left out (the glowing lamp face still reads).
local function lamp(onto: BasePart, kind: "Point" | "Spot" | "Surface", color: Color3, range: number, brightness: number, face: Enum.NormalId?, angle: number?)
	if lights >= maxLights then
		return
	end
	lights += 1
	local light: Light
	if kind == "Spot" then
		local s = Instance.new("SpotLight")
		s.Face = face or Enum.NormalId.Front
		s.Angle = angle or 60
		s.Range = range
		light = s
	elseif kind == "Surface" then
		local s = Instance.new("SurfaceLight")
		s.Face = face or Enum.NormalId.Front
		s.Angle = angle or 90
		s.Range = range
		light = s
	else
		local s = Instance.new("PointLight")
		s.Range = range
		light = s
	end
	light.Color = color
	light.Brightness = brightness
	light.Shadows = false
	light.Enabled = false
	light.Parent = onto
	CollectionService:AddTag(light, WorldDress.LIGHT_TAG)
end

-- A framed board facing `facing` (flat): a dark backing with words, a painted steel frame standing
-- proud of it with a chamfered top, on two posts when `postHeight` is given.
local function board(name: string, text: string, center: Vector3, facing: Vector3, w: number, h: number, fg: Color3, bg: Color3, postHeight: number?)
	local look = CFrame.lookAt(center, center + facing)
	local back = box(name, Vector3.new(w, h, 0.3), look, bg)
	words(back, text, fg, bg, Vector2.new(math.floor(120 * w / h), 120))
	local t = 0.45
	box(name .. "Frame", Vector3.new(w + 2 * t, t, 0.6), look * CFrame.new(0, -h / 2 - t / 2, 0), C.frame, "Painted")
	box(name .. "Frame", Vector3.new(t, h, 0.6), look * CFrame.new(-w / 2 - t / 2, 0, 0), C.frame, "Painted")
	box(name .. "Frame", Vector3.new(t, h, 0.6), look * CFrame.new(w / 2 + t / 2, 0, 0), C.frame, "Painted")
	chamferFront(name .. "Cap", Vector3.new(w + 2 * t, t * 1.4, 0.8), look * CFrame.new(0, h / 2 + t * 0.7, 0), 0.3, C.frame, "Painted", C.yellow)
	if postHeight then
		local ground = center.Y - postHeight
		for _, side in { -1, 1 } do
			local x = look * CFrame.new(side * (w / 2 - 0.4), 0, 0.5)
			rod(name .. "Post", Vector3.new(x.X, ground, x.Z), Vector3.new(x.X, center.Y - h / 2, x.Z), 0.45, C.steel, "Painted")
		end
	end
	return back
end

-- A cable lying on the floor from a to b (a few straight lengths with a gentle wander).
local function cable(a: Vector3, b: Vector3)
	local n = 3
	local side = Vector3.new(-(b - a).Z, 0, (b - a).X).Unit
	local last = a
	for i = 1, n do
		local t = i / n
		local wander = if i < n then side * math.sin(t * math.pi * 2) * 0.8 else Vector3.zero
		local here = a:Lerp(b, t) + wander
		rod("V2Cable", last + Vector3.new(0, 0.12, 0), here + Vector3.new(0, 0.12, 0), 0.22, C.rubber, "Rubber")
		last = here
	end
end

------------------------------------------------------------------------------------------------
-- Props

local function crate(x: number, z: number, size: number, turn: number, color: Color3, y: number?)
	local cf = at(x, (y or 0) + size / 2, z) * CFrame.Angles(0, math.rad(turn), 0)
	box("V2Crate", Vector3.new(size, size * 0.92, size), cf * CFrame.new(0, -size * 0.04, 0), color, "Painted")
	box("V2CrateLid", Vector3.new(size * 1.04, size * 0.1, size * 1.04), cf * CFrame.new(0, size * 0.45, 0), C.frame, "Painted")
	box("V2CrateBand", Vector3.new(size * 1.02, size * 0.9, size * 0.1), cf * CFrame.new(0, -size * 0.04, 0), C.frame, "Painted")
end

local function barrel(x: number, z: number, color: Color3)
	local h, r = 3.6, 1.25
	local base = origin + Vector3.new(x, 0, z)
	rod("V2Barrel", base, base + Vector3.new(0, h, 0), r * 2, color, "Painted")
	local mid = base + Vector3.new(0, h * 0.5, 0)
	rod("V2BarrelRim", mid - Vector3.new(0, 0.15, 0), mid + Vector3.new(0, 0.15, 0), r * 2 + 0.12, C.frame, "Painted")
	rod("V2BarrelLid", base + Vector3.new(0, h, 0), base + Vector3.new(0, h + 0.08, 0), r * 1.6, C.black, "Rubber")
end

local function tyres(x: number, z: number, count: number)
	for i = 0, count - 1 do
		local y = origin + Vector3.new(x + (i % 2) * 0.25, i * 1.05, z)
		rod("V2Tyre", y, y + Vector3.new(0, 1, 0), 3.4, C.rubber, "Rubber")
		rod("V2TyreHub", y - Vector3.new(0, 0.02, 0), y + Vector3.new(0, 1.02, 0), 1.6, C.black, Enum.Material.SmoothPlastic)
	end
end

local function cart(x: number, z: number, turn: number)
	local cf = at(x, 0, z) * CFrame.Angles(0, math.rad(turn), 0)
	lipBox("V2Cart", Vector3.new(4, 0.5, 2.4), cf * CFrame.new(0, 3, 0), 0.12, C.blue, "Painted", C.frame)
	box("V2CartShelf", Vector3.new(3.8, 0.3, 2.2), cf * CFrame.new(0, 1.1, 0), C.blue, "Painted")
	for _, s in { Vector3.new(-1.8, 0, -1), Vector3.new(1.8, 0, -1), Vector3.new(-1.8, 0, 1), Vector3.new(1.8, 0, 1) } do
		local foot = (cf * CFrame.new(s)).Position
		rod("V2CartLeg", foot + Vector3.new(0, 0.4, 0), foot + Vector3.new(0, 3, 0), 0.25, C.steel, "Brushed")
	end
	box("V2Toolbox", Vector3.new(1.8, 0.9, 1), cf * CFrame.new(-0.6, 3.7, 0), C.red, "Painted")
end

-- A light tower: a tripod, a mast, a lamp head aimed at `aim`, a generator at its foot.
local function lightTower(x: number, z: number, aim: Vector3)
	local foot = origin + Vector3.new(x, 0, z)
	local top = foot + Vector3.new(0, 14, 0)
	for i = 0, 2 do
		local a = i * math.pi * 2 / 3
		rod("V2TowerLeg", foot + Vector3.new(math.cos(a) * 2.4, 0, math.sin(a) * 2.4), foot + Vector3.new(0, 5, 0), 0.3, C.steel, "Brushed")
	end
	rod("V2TowerMast", foot + Vector3.new(0, 4.5, 0), top, 0.4, C.steel, "Brushed")
	local head = box("V2LampHead", Vector3.new(3, 2, 1), CFrame.lookAt(top + Vector3.new(0, 0.6, 0), origin + aim), C.frame, "Painted")
	local face = box("V2LampFace", Vector3.new(2.6, 1.6, 0.1), head.CFrame * CFrame.new(0, 0, -0.52), C.lamp, Enum.Material.Neon)
	lamp(face, "Spot", C.lamp, 40, 2.2, Enum.NormalId.Front, 55)
	local gen = foot + Vector3.new(3.5, 0, 3)
	lipBox("V2Generator", Vector3.new(3, 2, 2), CFrame.new(gen + Vector3.new(0, 1, 0)), 0.25, C.yellow, "Painted", C.frame)
	cable(gen + Vector3.new(-1.5, 0, 0), foot)
end

-- A warning board on a post, facing the spawn (danger: lava, spikes, the mace).
local function warning(text: string, x: number, z: number, color: Color3)
	local center = origin + Vector3.new(x, 3.6, z)
	local facing = Vector3.new(-x, 0, -z)
	facing = if facing.Magnitude > 0.1 then facing.Unit else Vector3.zAxis
	board("V2Warning", text, center, facing, 5, 1.8, color, C.black, 3.6 - 0.9)
	local stripe = box("V2WarningStripe", Vector3.new(5.9, 0.6, 0.35), CFrame.lookAt(center, center + facing) * CFrame.new(0, -1.55, 0.05), C.yellow, "Painted")
	stripes(stripe, Enum.NormalId.Front, 6)
end

------------------------------------------------------------------------------------------------
-- The lab

local function backdrop()
	local z = -101
	local width, height = 144, 20
	local panels = 6
	local pw = width / panels
	for i = 0, panels - 1 do
		local x = -width / 2 + pw * (i + 0.5)
		-- (Turned round so its Front, where the words go, faces the lab.)
		local panel = box("V2WallPanel", Vector3.new(pw - 2, height, 1.2), at(x, height / 2, z) * CFrame.Angles(0, math.pi, 0), C.panel, "Wall")
		if i == 1 or i == 4 then
			words(panel, if i == 1 then "TEST BAY" else "CRASH LAB", C.frame, nil, Vector2.new(800, 240))
		end
	end
	for i = 0, panels do
		local x = -width / 2 + pw * i
		-- (Turned round: the chamfer faces the lab.)
		chamferFront("V2Pilaster", Vector3.new(2.2, height + 1, 2), at(x, (height + 1) / 2, z + 0.4) * CFrame.Angles(0, math.pi, 0), 0.5, C.frame, "Painted", C.steel)
	end
	-- The cornice: a beam along the top with a chamfer towards the lab.
	box("V2Cornice", Vector3.new(width + 2, 1.4, 2.4), at(0, height + 0.7, z + 0.4), C.steel, "Painted")
	-- (Turned round: its slope faces the lab, +Z.)
	wedge("V2CorniceBevel", Vector3.new(width + 2, 0.8, 0.8), at(0, height + 1.8, z + 1.2) * CFrame.Angles(0, math.pi, 0), C.yellow, "Painted")
	-- The skirting: hazard stripes along the floor.
	local skirt = box("V2Skirting", Vector3.new(width, 1.4, 0.4), at(0, 0.7, z + 0.85), C.yellow, "Painted")
	stripes(skirt, Enum.NormalId.Back, 72)
	-- Wall lamps over the panels, shining down the wall.
	for _, x in { -48, 0, 48 } do
		local head = box("V2WallLamp", Vector3.new(4, 0.8, 1.6), at(x, height - 2, z + 1.4), C.frame, "Painted")
		local glow = box("V2WallLampFace", Vector3.new(3.6, 0.1, 1.3), head.CFrame * CFrame.new(0, -0.42, 0), C.lamp, Enum.Material.Neon)
		lamp(glow, "Surface", C.lamp, 18, 1.4, Enum.NormalId.Bottom, 100)
	end
end

local function gantry()
	local z, span, beamY = -9, 27, 15
	for _, side in { -1, 1 } do
		local x = side * span
		lipBox("V2GantryFoot", Vector3.new(3, 0.6, 3), at(x, 0.3, z), 0.15, C.frame, "Painted", C.yellow)
		box("V2GantryPost", Vector3.new(1.4, beamY + 1, 1.4), at(x, (beamY + 1) / 2, z), C.steel, "Painted")
		local sleeve = box("V2GantrySleeve", Vector3.new(1.5, 2.4, 1.5), at(x, 1.8, z), C.yellow, "Painted")
		stripes(sleeve, Enum.NormalId.Back, 2)
		stripes(sleeve, Enum.NormalId.Front, 2)
	end
	-- Two chords and the braces between them: a truss, not a plank.
	box("V2GantryChord", Vector3.new(span * 2 + 1.4, 0.6, 0.8), at(0, beamY + 0.9, z), C.steel, "Painted")
	box("V2GantryChord", Vector3.new(span * 2 + 1.4, 0.6, 0.8), at(0, beamY - 1.3, z), C.steel, "Painted")
	local bays = 6
	for i = 0, bays - 1 do
		local x0 = -span + (span * 2 / bays) * i
		local x1 = x0 + span * 2 / bays
		local up = i % 2 == 0
		rod("V2GantryBrace", origin + Vector3.new(x0, if up then beamY - 1.3 else beamY + 0.9, z), origin + Vector3.new(x1, if up then beamY + 0.9 else beamY - 1.3, z), 0.3, C.steel, "Brushed")
	end
	board("V2GantrySign", "CRASH TEST ZONE", origin + Vector3.new(0, beamY - 0.2, z + 0.6), Vector3.zAxis, 11, 1.9, C.yellow, C.black)
	-- Spot lamps hanging off it over the row.
	for _, x in { -12, 12 } do
		local head = box("V2GantryLamp", Vector3.new(1.6, 1.2, 1.6), CFrame.lookAt((at(x, beamY - 2.4, z)).Position, origin + Vector3.new(x * 0.4, 0, -20)), C.frame, "Painted")
		local face = box("V2GantryLampFace", Vector3.new(1.3, 1, 0.1), head.CFrame * CFrame.new(0, 0, -0.82), C.lamp, Enum.Material.Neon)
		lamp(face, "Spot", C.lamp, 30, 2, Enum.NormalId.Front, 50)
		rod("V2GantryLampArm", (at(x, beamY - 1.6, z)).Position, (at(x, beamY - 2, z)).Position, 0.25, C.frame, "Painted")
	end
end

-- An arrow painted flat on the floor at `from` (lab-local x, z) pointing along `dir`: a shaft and a
-- head of two flat wedges (a wedge's triangle lies in its local YZ; its X is turned to the vertical).
local function floorArrow(x: number, z: number, dir: Vector3, color: Color3)
	local f = Vector3.new(dir.X, 0, dir.Z).Unit
	local up = Vector3.yAxis
	local side = f:Cross(up) -- (to the right of the arrow)
	local y = origin.Y + 0.07
	local base = Vector3.new(origin.X + x, y, origin.Z + z)
	local shaft = 2.6
	box("V2FloorArrow", Vector3.new(0.9, 0.05, shaft), CFrame.lookAt(base, base + f), color).CastShadow = false
	local p0 = base + f * (shaft / 2)
	local a, b, t = 1.1, 1.6, 0.05
	-- (Right half: local Y out to the right, local Z back along the arrow, X down; left half mirrored.)
	wedge("V2FloorArrowHead", Vector3.new(t, a, b), CFrame.fromMatrix(p0 + side * (a / 2) + f * (b / 2), -up, side, -f), color).CastShadow = false
	wedge("V2FloorArrowHead", Vector3.new(t, a, b), CFrame.fromMatrix(p0 - side * (a / 2) + f * (b / 2), up, -side, -f), color).CastShadow = false
end

local function signposts(cannonPad: Vector3)
	-- Arrows on the floor from the spawn to the human cannon (a sign in the air would stand between
	-- the camera and the dummies), and a small board by the pad itself.
	local from = Vector3.new(5, 0, 0.5)
	local to = Vector3.new(cannonPad.X - 6, 0, cannonPad.Z - 0.5)
	local dir = (to - from).Unit
	for i = 0, 3 do
		local p = from + dir * (3 + i * 7.5)
		floorArrow(p.X, p.Z, dir, if i % 2 == 0 then C.orange else C.yellow)
	end
	local signAt = origin + Vector3.new(cannonPad.X - 7.5, 3.4, cannonPad.Z - 6)
	board("V2Signpost", "HUMAN CANNON", signAt, Vector3.new(-0.7, 0, -0.7).Unit, 4.6, 1.3, C.orange, C.black, 3.4 - 0.65)
	-- The spawn mark: a dark disc with a yellow ring.
	disc("V2SpawnRing", 0, 0, 0.06, 4.2, C.yellow, Enum.Material.SmoothPlastic)
	disc("V2SpawnMark", 0, 0, 0.075, 3.5, C.rubber, "Rubber")
end

-- The dotted flight of the human cannon from its pad to the bullseye (where the shot lands).
local function flightArc(pad: Vector3, land: Vector3, velocity: Vector3, gravity: number)
	local t1 = math.max(0.2, (land.X - pad.X) / velocity.X)
	local dots = 11
	for i = 1, dots do
		local t = t1 * (0.08 + 0.84 * (i - 1) / (dots - 1))
		local p = pad + Vector3.new(0, 3, 0) + velocity * t - Vector3.new(0, gravity * t * t / 2, 0)
		local dot = Instance.new("Part")
		dot.Shape = Enum.PartType.Ball
		picture(dot, "V2FlightDot", Vector3.one * (if i % 3 == 0 then 1.8 else 1.2), CFrame.new(origin + p), if i % 3 == 0 then C.orange else C.white, Enum.Material.Neon)
		dot.CastShadow = false
	end
end

local function cannonBeacon(x: number, z: number)
	local foot = origin + Vector3.new(x, 0, z)
	lipBox("V2BeaconFoot", Vector3.new(2.4, 0.6, 2.4), CFrame.new(foot + Vector3.new(0, 0.3, 0)), 0.15, C.frame, "Painted", C.yellow)
	rod("V2BeaconMast", foot + Vector3.new(0, 0.6, 0), foot + Vector3.new(0, 20, 0), 0.5, C.steel, "Brushed")
	local flag = box("V2BeaconFlag", Vector3.new(6, 2.4, 0.15), CFrame.lookAt(foot + Vector3.new(-3.2, 17.6, 0), foot + Vector3.new(-3.2, 17.6, 0) + Vector3.zAxis), C.orange, Enum.Material.Fabric)
	words(flag, "CANNON", C.white, nil, Vector2.new(500, 200))
	words(flag, "CANNON", C.white, nil, Vector2.new(500, 200), Enum.NormalId.Back)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	picture(ball, "V2Beacon", Vector3.one * 1.4, CFrame.new(foot + Vector3.new(0, 20.6, 0)), C.orange, Enum.Material.Neon)
	lamp(ball, "Point", C.orange, 16, 1.5)
end

local function towerDressing()
	local x, top, pz = -52, 30, -64
	-- Rails round the back and the west side of the platform (the stairs and the plank stay open).
	local y0, y1 = top, top + 3.2
	local function rail(a: Vector3, b: Vector3)
		rod("V2TowerRail", origin + a + Vector3.new(0, y1, 0), origin + b + Vector3.new(0, y1, 0), 0.35, C.yellow, "Painted")
		rod("V2TowerRail", origin + a + Vector3.new(0, y0 + 1.6, 0), origin + b + Vector3.new(0, y0 + 1.6, 0), 0.25, C.yellow, "Painted")
		local n = math.max(1, math.floor((b - a).Magnitude / 3.5))
		for i = 0, n do
			local p = a:Lerp(b, i / n)
			rod("V2TowerPost", origin + p + Vector3.new(0, y0, 0), origin + p + Vector3.new(0, y1, 0), 0.25, C.frame, "Painted")
		end
	end
	rail(Vector3.new(x - 6.6, 0, pz - 5.6), Vector3.new(x + 6.6, 0, pz - 5.6))
	rail(Vector3.new(x - 6.6, 0, pz - 5.6), Vector3.new(x - 6.6, 0, pz + 5.6))
	board("V2TowerSign", "FALL TOWER", origin + Vector3.new(x + 7.25, 21, pz), Vector3.xAxis, 8, 2.2, C.yellow, C.black)
end

local function wreckingDressing()
	local x, z, height = 40, -38, 24
	for _, px in { x - 8, x + 8 } do
		lipBox("V2BallFoot", Vector3.new(4, 0.6, 4), at(px, 0.3, z), 0.15, C.frame, "Painted", C.yellow)
		local sleeve = box("V2BallSleeve", Vector3.new(2.2, 3, 2.2), at(px, 2.1, z), C.yellow, "Painted")
		stripes(sleeve, Enum.NormalId.Front, 2)
		stripes(sleeve, Enum.NormalId.Back, 2)
		-- Braces from the post down to the floor (along Z: the ball swings along Z, between them).
		for _, dz in { -1, 1 } do
			rod("V2BallBrace", origin + Vector3.new(px, 9, z), origin + Vector3.new(px, 0.3, z + dz * 6), 0.45, C.steel, "Painted")
		end
	end
	box("V2BallBeamCap", Vector3.new(19, 0.5, 2.4), at(x, height + 2.25, z), C.yellow, "Painted")
end

local function rampDressing()
	-- Dark side rails along the yellow ramp (Playground.buildRamp: at 26, 30; 10 x 7 x 18, rising to -Z).
	for _, side in { -1, 1 } do
		wedge("V2RampRail", Vector3.new(0.4, 7.5, 18.2), at(26 + side * 5.2, 3.75, 30) * CFrame.Angles(0, math.pi, 0), C.frame, "Painted")
	end
end

local function stationBoards(stations: { { name: string, x: number, z: number, color: Color3 } })
	for _, s in stations do
		local b = board("V2StationBoard", s.name, origin + Vector3.new(s.x, 8.2, s.z + 6.5), -Vector3.zAxis, 8, 2.4, Color3.new(1, 1, 1), s.color, 8.2 - 1.2)
		local strip = box("V2StationLight", Vector3.new(8, 0.25, 0.25), b.CFrame * CFrame.new(0, -1.6, -0.3), s.color, Enum.Material.Neon)
		lamp(strip, "Surface", s.color, 12, 1.2, Enum.NormalId.Bottom, 90)
	end
end

local function clutter()
	-- Left of the spawn's view (clear of the tower, x -59 and in).
	crate(-64, -28, 4, 8, C.blue)
	crate(-64.4, -28.2, 2.8, -14, C.orange, 4)
	crate(-68, -33, 3.2, 30, C.panel)
	barrel(-61, -35, C.yellow)
	barrel(-63.4, -37.8, C.blue)
	tyres(-68, -40, 3)
	-- Right (clear of the wrecking ball, x 48, and the sleigh ramp, z -20 and up).
	crate(64, -44, 4, -6, C.orange)
	crate(66.5, -49, 3, 20, C.blue)
	barrel(61, -52, C.red)
	tyres(67, -55, 2)
	cart(60, -60, 90)
	-- At the back, by the crash wall: light towers on the row and the bullseye, barrels, crates.
	lightTower(-36, -80, Vector3.new(-6, 0, -42))
	lightTower(36, -80, Vector3.new(14, 0, -30))
	barrel(-47, -84, C.yellow)
	barrel(-44.2, -85.5, C.yellow)
	crate(48, -86, 4, 12, C.panel)
	crate(52.5, -85, 3, -20, C.orange)
	-- By the spawn, out of the walking lines (the portals behind, the ramp right, the mace left).
	cart(-18, 9, 0)
	crate(16, 11, 2.6, 25, C.orange)
	crate(15.6, 13.4, 2, -10, C.blue)
	-- Cables from the gantry's feet to a junction box beside each.
	for _, side in { -1, 1 } do
		local box0 = origin + Vector3.new(side * 33, 0, -9)
		lipBox("V2Junction", Vector3.new(1.8, 2.4, 1.2), CFrame.new(box0 + Vector3.new(0, 1.2, 0)), 0.2, C.frame, "Painted", C.yellow)
		cable(box0, origin + Vector3.new(side * 27.8, 0, -9))
	end
end

------------------------------------------------------------------------------------------------
-- Entry points (Playground calls these; each builds into a WorldV2 folder of the one given)

local function begin(ground: Vector3, lightBudget: number): Folder
	local f = Instance.new("Folder")
	f.Name = WorldDress.FOLDER
	parent = f
	origin = ground
	parts = 0
	lights = 0
	maxLights = lightBudget
	return f
end

export type LabPlan = {
	cannonPad: Vector3, -- (relative to the ground origin)
	landing: Vector3,
	velocity: Vector3,
	gravity: number,
	stations: { { name: string, x: number, z: number, color: Color3 } },
	maxLights: number,
}

-- A playground's dressing: the attractions every playground has (tower, cannon, wrecking ball,
-- ramp), and in a lab (`plan` given) the rest of the lab. Returns the folder, its parts and lights.
function WorldDress.dress(into: Instance, ground: Vector3, plan: LabPlan?): (Folder, number, number)
	local f = begin(ground, if plan then plan.maxLights else 2)
	towerDressing()
	wreckingDressing()
	rampDressing()
	cannonBeacon(56, 14)
	if plan then
		backdrop()
		gantry()
		signposts(plan.cannonPad)
		flightArc(plan.cannonPad, plan.landing, plan.velocity, plan.gravity)
		stationBoards(plan.stations)
		-- (Out to the sides of the dummies' row as the spawn camera sees it, and low: never over a dummy.)
		warning("DANGER: LAVA", -21, -28, C.orange)
		warning("SPIKES!", 30, -34, C.red)
		warning("SPINNING MACE", -13.5, 16, C.yellow)
		clutter()
	end
	f:SetAttribute("Parts", parts)
	f:SetAttribute("Lights", lights)
	f.Parent = into
	return f, parts, lights
end

-- The Christmas lab's finishing touches (into its own ChristmasLab folder, so they come and go with
-- it): a cap and snow on the chimney and a glowing hearth, a bow on the present, the sleigh's
-- runners, curled front and gold trim. `spots` is Playground.CHRISTMAS_SPOTS.
function WorldDress.dressChristmas(into: Instance, ground: Vector3, spots: { [string]: Vector2 }): (Folder, number)
	local f = begin(ground, 1)
	local brick = Color3.fromRGB(120, 40, 34)
	local gold = Color3.fromRGB(255, 200, 60)
	local c = spots.Chimney
	if c then
		bevelBox("V2ChimneyCap", Vector3.new(8.4, 1.2, 8.4), at(c.X, 14.6, c.Y), 0.3, brick, Enum.Material.Brick)
		box("V2ChimneySnow", Vector3.new(8.2, 0.5, 8.2), at(c.X, 15.45, c.Y), C.white, Enum.Material.Snow)
		for _, side in { -1, 1 } do
			box("V2HearthPost", Vector3.new(1.2, 5, 1.2), at(c.X + side * 3.4, 2.5, c.Y - 3.9), brick, Enum.Material.Brick)
		end
		box("V2HearthLintel", Vector3.new(8, 1.2, 1.4), at(c.X, 5.6, c.Y - 3.9), brick, Enum.Material.Brick)
		local glow = box("V2HearthGlow", Vector3.new(5, 3, 0.2), at(c.X, 1.8, c.Y - 3.55), C.orange, Enum.Material.Neon)
		lamp(glow, "Point", C.orange, 12, 1.2)
	end
	local p = spots.Present
	if p then
		local top = at(p.X, 6.4, p.Y)
		box("V2Bow", Vector3.new(2.6, 1.6, 0.6), top * CFrame.Angles(0, math.rad(45), math.rad(25)) * CFrame.new(-1.1, 0, 0), gold)
		box("V2Bow", Vector3.new(2.6, 1.6, 0.6), top * CFrame.Angles(0, math.rad(45), -math.rad(25)) * CFrame.new(1.1, 0, 0), gold)
		box("V2BowKnot", Vector3.new(1, 1, 1), top, gold)
	end
	local s = spots.Sleigh
	if s then
		local sz = s.Y - 6
		for _, side in { -1, 1 } do
			box("V2SleighRunner", Vector3.new(0.35, 0.35, 6.4), at(s.X + side * 2.4, 5.85, sz), gold, "Brushed")
			for _, dz in { -1.8, 1.8 } do
				box("V2SleighStrut", Vector3.new(0.3, 0.8, 0.3), at(s.X + side * 2.4, 6.3, sz + dz), gold, "Brushed")
			end
		end
		wedge("V2SleighNose", Vector3.new(6, 1.8, 1.6), at(s.X, 7.9, sz - 2.8), C.red)
		box("V2SleighBack", Vector3.new(6, 2.4, 0.6), at(s.X, 9.2, sz + 1.7), C.red)
		box("V2SleighTrim", Vector3.new(6.2, 0.3, 4.2), at(s.X, 8.05, sz), gold)
	end
	f.Parent = into
	return f, parts
end

return WorldDress
