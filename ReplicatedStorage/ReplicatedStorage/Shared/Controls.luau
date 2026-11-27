--!strict
-- C10 (docs/CONTROLS_10.md; Config.CONTROLS_V2): ONE kit for every machine control, the way the big games do it.
-- Controls.build(kind, cframe, opts) makes a BIG RED BUTTON, a LEVER, a CRANK wheel or a DIAL (the same shape
-- everywhere, built once in code; a Blender version can replace the parts later without touching any machine), tags it
-- "Control" with attributes Kind / Machine / Action / Icon, and gives it ONE prompt (Style Custom: Client/ControlsFX
-- draws a big round icon with the action word, a large tap target on phones, no key letters).
-- Server: Controls.bind(model, onUse) runs onUse(player) when it is pressed and the control is READY; the state is
-- shown by attributes only (the server moves no parts): Ready, CoolUntil (server time), Busy, Locked.
-- Client (ControlsFX): the press moves the button at once on your screen (sink + squash, a lever throws, a crank turns),
-- a click, and the state in shape and light: READY a slow pulse, COOLING a ring filling up, BUSY red, LOCKED grey.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Controls = {}

Controls.TAG = "Control"
Controls.REACH = 12

export type Kind = "Button" | "Lever" | "Crank" | "Dial"
export type Opts = { machine: string?, action: string?, icon: string?, hold: number?, parent: Instance?, scale: number? }

local HAZARD_Y = Color3.fromRGB(245, 200, 30)
local BLACK = Color3.fromRGB(24, 24, 28)
local CHROME = Color3.fromRGB(200, 204, 210)
local RED = Color3.fromRGB(215, 30, 35)
local STEEL = Color3.fromRGB(90, 96, 106)

local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- A ring of N thin blocks round a centre (a hazard stripe band or a light ring).
local function band(model: Model, name: string, cf: CFrame, radius: number, height: number, n: number, colorOf: (number) -> Color3, material: Enum.Material?)
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local w = 2 * math.pi * radius / n * 1.05
		part(model, name, Vector3.new(w, height, 0.12), cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -radius), colorOf(i), material)
	end
end

function Controls.build(kind: Kind, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local s = o.scale or 1
	local model = Instance.new("Model")
	model.Name = "Control" .. kind
	local base: BasePart
	if kind == "Button" then
		-- a short post at hand height, a black-and-yellow hazard base, a chrome collar, a glossy red mushroom cap
		local post = part(model, "Post", Vector3.new(1.1, 2.6, 1.1) * s, cf * CFrame.new(0, 1.3 * s, 0), STEEL, Enum.Material.Metal)
		post.CanCollide = true
		base = part(model, "Base", Vector3.new(0.5, 2.6, 2.6) * s, cf * CFrame.new(0, 2.85 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		band(model, "Hazard", cf * CFrame.new(0, 2.85 * s, 0), 1.3 * s, 0.5 * s, 12, function(i)
			return if i % 2 == 0 then HAZARD_Y else BLACK
		end)
		part(model, "Collar", Vector3.new(0.3, 1.9, 1.9) * s, cf * CFrame.new(0, 3.25 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), CHROME, Enum.Material.Metal, Enum.PartType.Cylinder)
		local ring = part(model, "Ring", Vector3.new(0.08, 2.0, 2.0) * s, cf * CFrame.new(0, 3.42 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, Enum.PartType.Cylinder)
		ring.Transparency = 0.6
		local cap = part(model, "Cap", Vector3.new(1.7, 0.8, 1.7) * s, cf * CFrame.new(0, 3.6 * s, 0), RED, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		cap.Reflectance = 0.15
		local glow = Instance.new("PointLight")
		glow.Name = "Glow"
		glow.Color = Color3.fromRGB(255, 70, 60)
		glow.Range = 6 * s
		glow.Brightness = 0.8
		glow.Parent = cap
		-- the pictogram plate under it, facing out
		local plate = part(model, "Plate", Vector3.new(1.3, 0.9, 0.08) * s, cf * CFrame.new(0, 2.2 * s, -0.6 * s), Color3.fromRGB(240, 240, 236))
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.CanvasSize = Vector2.new(140, 96)
		g.LightInfluence = 0.3
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.TextScaled = true
		t.Font = Enum.Font.FredokaOne
		t.TextColor3 = BLACK
		t.Text = o.icon or "!"
		t.Parent = g
		g.Parent = plate
	elseif kind == "Lever" then
		-- a metal box, an ON/OFF arc plate (green and red), a chunky handle with a red ball knob (pivots at the box top)
		base = part(model, "Box", Vector3.new(1.6, 1.4, 1.2) * s, cf * CFrame.new(0, 0.7 * s, 0), STEEL, Enum.Material.Metal)
		base.CanCollide = true
		part(model, "ArcOn", Vector3.new(0.7, 0.5, 0.06) * s, cf * CFrame.new(-0.4 * s, 1.15 * s, -0.62 * s), Color3.fromRGB(60, 200, 90), Enum.Material.Neon)
		part(model, "ArcOff", Vector3.new(0.7, 0.5, 0.06) * s, cf * CFrame.new(0.4 * s, 1.15 * s, -0.62 * s), Color3.fromRGB(220, 60, 50), Enum.Material.Neon)
		local pivot = part(model, "Pivot", Vector3.new(0.5, 0.5, 0.5) * s, cf * CFrame.new(0, 1.45 * s, 0), CHROME, Enum.Material.Metal, Enum.PartType.Ball)
		local handle = part(model, "Handle", Vector3.new(0.25, 2.0, 0.25) * s, pivot.CFrame * CFrame.Angles(0, 0, math.rad(-25)) * CFrame.new(0, 1.0 * s, 0), CHROME, Enum.Material.Metal)
		local knob = part(model, "Cap", Vector3.new(0.7, 0.7, 0.7) * s, handle.CFrame * CFrame.new(0, 1.05 * s, 0), RED, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		knob.Reflectance = 0.15
		local glow = Instance.new("PointLight")
		glow.Name = "Glow"
		glow.Color = Color3.fromRGB(255, 70, 60)
		glow.Range = 5 * s
		glow.Brightness = 0.6
		glow.Parent = knob
	elseif kind == "Crank" then
		-- a gearbox with a spoked wheel on its front (it turns while held)
		base = part(model, "Gearbox", Vector3.new(1.8, 1.8, 1.4) * s, cf * CFrame.new(0, 1.6 * s, 0), STEEL, Enum.Material.Metal)
		base.CanCollide = true
		part(model, "Leg", Vector3.new(0.6, 0.8, 0.6) * s, cf * CFrame.new(0, 0.4 * s, 0), BLACK)
		local hub = part(model, "Hub", Vector3.new(0.4, 0.6, 0.6) * s, cf * CFrame.new(0, 1.6 * s, -0.9 * s) * CFrame.Angles(0, math.rad(90), 0), CHROME, Enum.Material.Metal, Enum.PartType.Cylinder)
		local rim = part(model, "Rim", Vector3.new(0.2, 2.4, 2.4) * s, hub.CFrame * CFrame.new(-0.15 * s, 0, 0), RED, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		rim.Name = "Cap"
		for k = 0, 2 do
			part(model, "Spoke", Vector3.new(0.12, 2.2, 0.18) * s, hub.CFrame * CFrame.new(-0.1 * s, 0, 0) * CFrame.Angles(math.rad(k * 60), 0, 0), CHROME, Enum.Material.Metal)
		end
		part(model, "Grip", Vector3.new(0.7, 0.3, 0.3) * s, hub.CFrame * CFrame.new(-0.45 * s, 1.0 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	else -- Dial
		-- a round dial face (slow / normal / fast) on a post, a pointer that turns to the setting
		base = part(model, "Post", Vector3.new(0.9, 2.6, 0.9) * s, cf * CFrame.new(0, 1.3 * s, 0), STEEL, Enum.Material.Metal)
		base.CanCollide = true
		local face = part(model, "Face", Vector3.new(0.2, 2.2, 2.2) * s, cf * CFrame.new(0, 3.0 * s, -0.5 * s) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		for k, col in { Color3.fromRGB(60, 200, 90), HAZARD_Y, Color3.fromRGB(220, 60, 50) } do
			local a = math.rad(-60 + (k - 1) * 60)
			part(model, "Tick", Vector3.new(0.12, 0.45, 0.06) * s, face.CFrame * CFrame.new(-0.12 * s, 0, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0.75 * s, 0), col, Enum.Material.Neon)
		end
		local pointer = part(model, "Pointer", Vector3.new(0.1, 0.9, 0.16) * s, face.CFrame * CFrame.new(-0.16 * s, 0, 0) * CFrame.new(0, 0.4 * s, 0), BLACK)
		pointer.Name = "Pointer"
		local knob = part(model, "Cap", Vector3.new(0.3, 0.7, 0.7) * s, face.CFrame * CFrame.new(-0.2 * s, 0, 0), RED, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		knob.Reflectance = 0.15
	end
	model.PrimaryPart = base
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Machine", o.machine or "")
	model:SetAttribute("Action", o.action or "USE")
	model:SetAttribute("Icon", o.icon or "!")
	model:SetAttribute("Ready", true)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ControlPrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = o.action or "USE"
	prompt.ObjectText = o.machine or ""
	prompt.MaxActivationDistance = Controls.REACH
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = o.hold or 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = base
	CollectionService:AddTag(model, Controls.TAG)
	if o.parent then
		model.Parent = o.parent
	end
	return model
end

-- Server: run onUse(player) when the control is pressed while READY (not Busy, not Locked, cooled down). onUse returns
-- true when it ran (then the control cools for `cool` s), false when the machine refused (the client's press pops back).
function Controls.bind(model: Model, onUse: (Player) -> boolean, cool: number?)
	local prompt = model:FindFirstChild("ControlPrompt", true)
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		return
	end
	prompt.Triggered:Connect(function(player: Player)
		local now = Workspace:GetServerTimeNow()
		local coolUntil = model:GetAttribute("CoolUntil")
		if model:GetAttribute("Busy") == true or model:GetAttribute("Locked") == true or (type(coolUntil) == "number" and now < coolUntil) then
			model:SetAttribute("Refused", (model:GetAttribute("Refused") or 0) + 1)
			return
		end
		local ok, ran = pcall(onUse, player)
		if ok and ran then
			model:SetAttribute("Used", (model:GetAttribute("Used") or 0) + 1)
			if cool and cool > 0 then
				model:SetAttribute("CoolFrom", now)
				model:SetAttribute("CoolUntil", now + cool)
			end
		else
			model:SetAttribute("Refused", (model:GetAttribute("Refused") or 0) + 1)
		end
	end)
end

function Controls.setState(model: Model, busy: boolean?, locked: boolean?)
	if busy ~= nil then
		model:SetAttribute("Busy", busy)
	end
	if locked ~= nil then
		model:SetAttribute("Locked", locked)
	end
end

return Controls
