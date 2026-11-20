--!strict
-- V9-0i: the 3D showcases the SHOP turns (Shared/ShopArt.SHOW). Each is built from what this screen
-- has: the real weapon models (N7Assets.Weapons), the mannequin dummy (ReplicatedStorage.DummySkin),
-- the props the server copies over (ReplicatedStorage.ShopModels), and a few code-built touches (a
-- crown, a rainbow, flames, a beam of light). `viewport` puts one in a ViewportFrame with its camera
-- fitted and hands it to Ui3D, which turns it (a few at once per device, faster under the pointer,
-- and by drag in the detail view). nil when nothing can be built: the card keeps its picture.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui3D = require(script.Parent:WaitForChild("Ui3D")) :: any
local ToolPicture = require(script.Parent:WaitForChild("ToolPicture")) :: any

local ShopShowcase = {}

ShopShowcase.FOV = 32

local function anchorAll(m: Instance)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CastShadow = false
		elseif d:IsA("LuaSourceContainer") or d:IsA("JointInstance") or d:IsA("Sound") or d:IsA("Light") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
end

local function scaleTo(m: Model, biggest: number)
	local _, size = m:GetBoundingBox()
	local big = math.max(size.X, size.Y, size.Z)
	if big > 0.01 then
		pcall(function()
			m:ScaleTo(m:GetScale() * biggest / big)
		end)
	end
end

local function centre(m: Model): (Vector3, Vector3)
	local cf, size = m:GetBoundingBox()
	return cf.Position, size
end

-- A plain part for the code-built touches.
local function bit(into: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

local function dummy(color: Color3, gold: boolean): Model?
	local skin = ReplicatedStorage:FindFirstChild("DummySkin")
	local src = skin and skin:FindFirstChildWhichIsA("Model")
	if not src then
		return nil
	end
	local m = src:Clone()
	anchorAll(m)
	for _, d in m:GetDescendants() do
		if d:IsA("MeshPart") then
			d.TextureID = ""
		end
		if d:IsA("BasePart") then
			d.Color = color
			d.Material = if gold then Enum.Material.Foil else Enum.Material.SmoothPlastic
			d.Reflectance = if gold then 0.25 else 0
		elseif d:IsA("SurfaceAppearance") or d:IsA("Decal") then
			d:Destroy()
		end
	end
	scaleTo(m, 6)
	return m
end

local function weapon(id: string, length: number?): Model?
	local src = ToolPicture.model(id)
	if not src then
		return nil
	end
	local m = src:Clone() :: Model
	anchorAll(m)
	scaleTo(m, length or 4.2)
	return m
end

local function prop(name: string, gold: boolean): Model?
	local folder = ReplicatedStorage:FindFirstChild("ShopModels")
	local src = folder and folder:FindFirstChild(name)
	if not src or not src:IsA("Model") then
		return nil
	end
	local m = src:Clone()
	anchorAll(m)
	if gold then
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = Color3.fromRGB(231, 181, 59)
				d.Material = Enum.Material.Foil
			end
		end
	end
	scaleTo(m, 6)
	return m
end

local function crown(into: Instance, at: Vector3)
	local gold = Color3.fromRGB(255, 205, 64)
	bit(into, Vector3.new(0.5, 1.5, 1.5), CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Foil, Enum.PartType.Cylinder)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		bit(into, Vector3.new(0.22, 0.55, 0.22), CFrame.new(at + Vector3.new(math.cos(a) * 0.62, 0.45, math.sin(a) * 0.62)), gold, Enum.Material.Foil)
	end
end

-- The showcase for a ShopArt.SHOW spec, its parts round the origin.
function ShopShowcase.build(spec: any): Model?
	local root = Instance.new("Model")
	root.Name = "Showcase"
	local pieces: { Model } = {}
	if spec.model then
		local m = prop(spec.model, spec.gold == true)
		if m then
			table.insert(pieces, m)
		end
	end
	if spec.dummy then
		for _ = 1, spec.count or 1 do
			local m = dummy(Color3.fromHex(spec.dummy), spec.gold == true)
			if m then
				table.insert(pieces, m)
			end
		end
	end
	if spec.weapons then
		for _, id in spec.weapons do
			local m = weapon(id, if #spec.weapons == 1 and not spec.dummy and not spec.model then 6 else nil) -- (one alone: big)
			if m then
				table.insert(pieces, m)
			end
		end
	end
	if #pieces == 0 then
		root:Destroy()
		return nil
	end
	-- The weapons lie across the view (their length along X, not pointing at the camera), stacked
	-- in a fan; dummies and props stand side by side on y = 0, a weapon leaning in front of them.
	local weaponsOnly = spec.weapons ~= nil and spec.dummy == nil and spec.model == nil
	local standing: { Model } = {}
	local lying: { Model } = {}
	for _, m in pieces do
		local mid, size = centre(m)
		m.WorldPivot = CFrame.new(mid) -- (its middle, world-aligned: the moves below keep how it is turned)
		if size.Z > size.X * 1.4 then
			m:PivotTo(CFrame.new(mid) * CFrame.Angles(0, math.rad(90), 0)) -- (long along Z: turned across)
		end
		local isWeapon = spec.weapons ~= nil and table.find(spec.weapons, m.Name) ~= nil
		table.insert(if isWeapon then lying else standing, m)
	end
	local n = #standing
	local width = 0
	for i, m in standing do
		local _, size = centre(m)
		local x = (i - (n + 1) / 2) * 3.4
		m:PivotTo(CFrame.new(x, size.Y / 2, 0) * (m:GetPivot() - m:GetPivot().Position))
		width = math.max(width, math.abs(x) + size.X / 2)
		m.Parent = root
	end
	local k = #lying
	local stackY = 0 -- (stacked by each one's own height: chunky ones never overlap)
	for i, m in lying do
		local _, size = centre(m)
		local roll = math.rad((i - (k + 1) / 2) * -14)
		stackY += size.Y / 2 + (if i > 1 then 0.45 else 0.3)
		local at = if weaponsOnly
			then Vector3.new(((i % 2) - 0.5) * 0.5, stackY, 0)
			else Vector3.new(width * 0.25, 1.1 + (i - 1) * 1.2, 3.4) -- (leaning in front of the crate or the dummy)
		m:PivotTo(CFrame.new(at) * CFrame.Angles(0, 0, if weaponsOnly then roll else math.rad(-28)) * (m:GetPivot() - m:GetPivot().Position))
		stackY += size.Y / 2
		local _ = size
		m.Parent = root
	end
	local mid, size = centre(root)
	local top = mid.Y + size.Y / 2
	if spec.extra == "crown" then
		crown(root, Vector3.new(mid.X, top + 0.5, mid.Z))
	elseif spec.extra == "beam" then
		-- (A soft column of light round the dummy and a glowing ring at its feet: no taller than it.)
		bit(root, Vector3.new(size.Y * 1.05, 3.2, 3.2), CFrame.new(mid.X, mid.Y + 0.1, mid.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 226, 120), Enum.Material.Neon, Enum.PartType.Cylinder).Transparency = 0.82
		bit(root, Vector3.new(0.15, 4.4, 4.4), CFrame.new(mid.X, mid.Y - size.Y / 2 + 0.08, mid.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 210, 90), Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif spec.extra == "rainbow" then
		-- (A full rainbow arching over the dummy: six bands of solid segments laid along the curve.)
		local colours = { "#FF4B4B", "#FF9A3C", "#FFE14D", "#5BD46B", "#4BA3FF", "#9B6BFF" }
		local base = mid.Y - size.Y / 2
		for k, hexc in colours do
			local r = 4.6 - k * 0.42
			for s = 0, 11 do
				local a = math.pi * (s + 0.5) / 12
				bit(root, Vector3.new(r * math.pi / 12 + 0.08, 0.42, 0.42), CFrame.new(mid.X + math.cos(a) * r, base + math.sin(a) * r, mid.Z - 0.9) * CFrame.Angles(0, 0, a + math.pi / 2), Color3.fromHex(hexc), Enum.Material.Neon)
			end
		end
	elseif spec.extra == "flames" then
		for k = -2, 2 do
			local h = 1.4 + (2 - math.abs(k)) * 0.5
			bit(root, Vector3.new(0.7, h, 0.7), CFrame.new(mid.X + k * 0.55, mid.Y - size.Y / 2 + h / 2, mid.Z + 0.9), if k % 2 == 0 then Color3.fromRGB(255, 120, 30) else Color3.fromRGB(255, 210, 60), Enum.Material.Neon, Enum.PartType.Ball)
		end
	elseif spec.extra == "suit" then
		bit(root, Vector3.new(size.X * 0.95, 0.35, size.Z * 1.05), CFrame.new(mid.X, mid.Y + 0.2, mid.Z), Color3.fromRGB(30, 30, 36))
		bit(root, Vector3.new(size.X * 0.95, 0.35, size.Z * 1.05), CFrame.new(mid.X, mid.Y + 1.3, mid.Z), Color3.fromRGB(30, 30, 36))
	elseif spec.extra == "glow" then
		bit(root, Vector3.new(0.2, 4.2, 4.2), CFrame.new(mid.X, mid.Y - size.Y / 2 - 0.4, mid.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 130, 40), Enum.Material.Neon, Enum.PartType.Cylinder)
	end
	local finalMid = select(1, root:GetBoundingBox()).Position
	root.WorldPivot = CFrame.new(finalMid)
	return root
end

-- A ViewportFrame holding the showcase, camera fitted, turning (Ui3D). nil: nothing to show.
function ShopShowcase.viewport(spec: any, size: UDim2, view: string?): ViewportFrame?
	local model = ShopShowcase.build(spec)
	if not model then
		return nil
	end
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Showcase3D"
	vp.Size = size
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(165, 165, 175)
	vp.LightColor = Color3.fromRGB(255, 250, 240)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.7)
	local cam = Instance.new("Camera")
	cam.FieldOfView = ShopShowcase.FOV
	cam.Parent = vp
	vp.CurrentCamera = cam
	model.Parent = vp
	local mid, box = centre(model)
	local radius = math.max(box.X, box.Y, box.Z) * 0.6
	local dist = radius / math.tan(math.rad(ShopShowcase.FOV / 2)) * (if view == "big" then 1.05 else 1.12)
	cam.CFrame = CFrame.lookAt(mid + Vector3.new(0, radius * 0.35, dist), mid)
	local pivot = CFrame.new(mid)
	Ui3D.track(vp, function(yaw: number)
		model:PivotTo(pivot * CFrame.Angles(0, yaw, 0))
	end)
	return vp
end

return ShopShowcase
