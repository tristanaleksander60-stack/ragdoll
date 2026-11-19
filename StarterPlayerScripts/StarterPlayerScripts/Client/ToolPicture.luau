--!strict
-- A tool's picture (round 2, N7): its real 3D model in a ViewportFrame when the place has one
-- (ReplicatedStorage.N7Assets.Weapons.<id> through N7Models: Creator Store and Studio-generated
-- models, a Grip at the origin and -Z forward), else its drawn icon (LihFolkUIIcons "tool_<id>",
-- the emoji on a shape). The catalog, the tool bar and the egg card all draw it from here.
--
-- Readable at bar size (fix round 1): the model sits on a disc in the tool's own colour, darkened,
-- with a white halo round the model itself (a white glove and a black pistol both stand out); a
-- weapon is turned so its length runs corner to corner; the camera is fitted to the outline of the
-- parts you can see (never the invisible grip, tip or hit boxes, which made models small). A
-- ViewportFrame redraws only when something in it changes: nothing per frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local N7Models = require(Shared:WaitForChild("N7Models"))

local ToolPicture = {}

-- (The models arrive with the place's first load: pictures made before it would be emoji for the
-- whole visit, so the first one waits for it.)
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local FOV = 20
local MARGIN = 1.14 -- room round the outline (the halo and the disc's edge stay clear)
local HALO = 0.07 -- the halo's width, as a share of the model's size
local HALO_BACK = 1 -- how far behind the model the halo sits (share of its size)
local SEEN = 0.95 -- parts more transparent than this are not part of the picture

-- Held weapons whose shape spreads sideways are seen from higher up (degrees; 20 otherwise).
local FROM_ABOVE: { [string]: number } = { Crossbow = 65 }

-- The model kept for a tool, or nil (then the drawn icon stands in).
function ToolPicture.model(id: string): Model?
	return N7Models.source("Weapons", id)
end

-- The parts you can see.
local function visible(model: Model): { BasePart }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < SEEN then
			table.insert(list, d)
		end
	end
	return list
end

-- The middle and the corners of what you can see (every visible part's own box).
local function outline(parts: { BasePart }): (Vector3, { Vector3 }, number)
	local corners = {}
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in parts do
		local half = p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = p.CFrame:PointToWorldSpace(Vector3.new(sx * half.X, sy * half.Y, sz * half.Z))
					table.insert(corners, w)
					lo = lo:Min(w)
					hi = hi:Max(w)
				end
			end
		end
	end
	if #corners == 0 then
		return Vector3.zero, { Vector3.zero }, 1
	end
	local size = hi - lo
	return (lo + hi) / 2, corners, math.max(size.X, size.Y, size.Z, 0.01)
end

-- How the model is seen: a held weapon from its side, its muzzle or blade up to the right; any
-- other thing from the front, three-quarters and a little above.
local function viewOf(id: string, wide: boolean): CFrame
	local toy = Toys.byId[id]
	if toy and toy.held then
		-- Side on (looking along -X): -Z (forward) points right; in a square, rolled 35 degrees so
		-- it runs corner to corner (up to the right). A little from above (20 degrees), so what
		-- spreads sideways (a crossbow's bow, a glove's thumb) is not seen edge-on.
		return CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, -1), Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, if wide then math.rad(8) else math.rad(35)) * CFrame.Angles(math.rad(-(FROM_ABOVE[id] or 20)), 0, 0)
	end
	return CFrame.lookAt(Vector3.new(1, 0.55, 1.4).Unit, Vector3.zero)
end

-- The camera for a picture: looking the way `view` looks at `middle`, far enough that every
-- corner is inside it. Returns the camera and its distance from the middle.
local function fit(middle: Vector3, corners: { Vector3 }, view: CFrame, aspect: number): (CFrame, number)
	local tanHalf = math.tan(math.rad(FOV / 2))
	local rot = view - view.Position
	local need = 0
	for _, corner in corners do
		local local_ = rot:PointToObjectSpace(corner - middle) -- camera space (looking down -Z)
		-- distance at which this corner is just inside: |x| <= (d - z) * tan
		local d = math.max(math.abs(local_.X) / aspect, math.abs(local_.Y)) * MARGIN / tanHalf + local_.Z
		need = math.max(need, d)
	end
	return rot + (middle + rot.LookVector * -need), need
end

-- A picture of the tool, size as given. wide: no disc, the model fills a wide frame (the catalog's
-- picture strip, where a weapon lies along it); otherwise a disc (the bar, the egg card).
function ToolPicture.make(id: string, size: UDim2, wide: boolean?): GuiObject
	-- The hand-drawn picture first (10 Nov 2026, the owner: drawn, not rendered; Shared.DrawnIcons),
	-- on the same darkened disc in the tool's colour.
	if Icons.has("tool_" .. id) then
		local toy = Toys.byId[id]
		local holder = Instance.new("Frame")
		holder.Name = "Drawn_" .. id
		holder.Size = size
		holder.BackgroundColor3 = (if toy then toy.color else Color3.fromRGB(150, 150, 170)):Lerp(Color3.fromRGB(20, 20, 28), 0.45)
		holder.BackgroundTransparency = if wide then 1 else 0
		-- (Square on its disc; in a wide strip the holder fills the strip and the picture, square by
		-- itself, sits in its middle.)
		if not wide then
			local aspect = Instance.new("UIAspectRatioConstraint")
			aspect.AspectRatio = 1
			aspect.Parent = holder
		end
		if not wide then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.28, 0)
			corner.Parent = holder
		end
		local image = Icons.make("tool_" .. id, UDim2.fromScale(if wide then 1 else 0.96, if wide then 1 else 0.96))
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.Parent = holder
		return holder
	end
	local source = ToolPicture.model(id)
	if not source then
		return Icons.make("tool_" .. id, size)
	end
	local toy = Toys.byId[id]
	-- The disc (the tool's colour, darkened: the same family as the drawn icons).
	local disc = Instance.new("Frame")
	disc.Name = "Model_" .. id
	disc.Size = size
	-- (Darkened: the model's white halo stands out on it, whatever the model's own colour.)
	disc.BackgroundColor3 = (if toy then toy.color else Color3.fromRGB(150, 150, 170)):Lerp(Color3.fromRGB(20, 20, 28), 0.45)
	if wide then
		disc.BackgroundTransparency = 1
	else
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = disc
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.28, 0) -- (a rounded square, as every picture in the HUD)
		corner.Parent = disc
		local edge = Instance.new("UIStroke")
		edge.Color = Color3.new(1, 1, 1)
		edge.Thickness = 1.5
		edge.Transparency = 0.25
		edge.Parent = disc
	end
	local frame = Instance.new("ViewportFrame")
	frame.Name = "View"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Ambient = Color3.fromRGB(205, 205, 215)
	frame.LightColor = Color3.fromRGB(255, 252, 245)
	frame.LightDirection = Vector3.new(-0.5, -1, -0.7)
	frame.Parent = disc
	local model = source:Clone()
	N7Models.clean(model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		elseif d:IsA("Light") or d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			d:Destroy() -- (lights do nothing here; joints would drag pieces as they are reshaped)
		end
	end
	model:PivotTo(CFrame.new())
	-- Only what you can see is drawn and measured (the grip, the tip and hit boxes are invisible).
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency >= SEEN then
			d:Destroy()
		end
	end
	local parts = visible(model)
	-- A long thin weapon (a bat, a crowbar, a katana) is a hairline at bar size: it is drawn thicker
	-- across its length (the whole weapon, every piece and the gaps between them alike, so it keeps
	-- its shape), until its girth is about three quarters of its length under 40 px (the phone bar,
	-- at most 4.5 times) or two fifths of it in a bigger picture (at most 2 times), as drawn icons are.
	-- A mesh in a SpecialMesh is scaled with its part. (The model in the hand is untouched.)
	if toy and toy.held and not wide then
		local small = size.X.Offset > 0 and size.X.Offset < 40
		local middle0, corners0 = outline(parts)
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, c in corners0 do
			lo = lo:Min(c - middle0)
			hi = hi:Max(c - middle0)
		end
		local box = hi - lo
		local girth = math.max(box.X, box.Y, 0.01)
		local k = if small then math.clamp(box.Z / girth / 1.33, 1, 4.5) else math.clamp(box.Z / girth / 2.5, 1, 2)
		if k > 1.05 then
			for _, d in parts do
				local cf = d.CFrame
				local p = cf.Position - middle0
				-- Each of the piece's own axes grows by how far it lies across the weapon.
				local function across(v: Vector3): number
					return 1 + (k - 1) * (1 - math.abs(v.Z))
				end
				local factor = Vector3.new(across(cf.RightVector), across(cf.UpVector), across(cf.LookVector))
				d.Size = d.Size * factor
				local mesh = d:FindFirstChildWhichIsA("SpecialMesh")
				if mesh then
					mesh.Scale = mesh.Scale * factor
				end
				d.CFrame = (cf - cf.Position) + middle0 + Vector3.new(p.X * k, p.Y * k, p.Z)
			end
		end
	end
	model.Parent = frame
	local middle, corners, extent = outline(parts)
	-- The halo: a flat white copy of every visible piece, a little thicker, set behind the model and
	-- grown to make up for being further away. Placed again whenever the camera is fitted.
	local halo = Instance.new("Model")
	halo.Name = "Halo"
	local haloParts: { { part: BasePart, cf: CFrame, size: Vector3, mesh: SpecialMesh?, meshScale: Vector3? } } = {}
	for _, p in parts do
		local h = p:Clone()
		for _, c in h:GetChildren() do
			if c:IsA("SurfaceAppearance") or c:IsA("Decal") or c:IsA("Texture") then
				c:Destroy()
			end
		end
		if h:IsA("MeshPart") then
			h.TextureID = ""
		end
		local mesh = h:FindFirstChildWhichIsA("SpecialMesh")
		if mesh then
			mesh.TextureId = ""
			mesh.VertexColor = Vector3.one
		end
		h.Color = Color3.new(1, 1, 1)
		h.Material = Enum.Material.SmoothPlastic
		h.Transparency = 0
		h.Parent = halo
		local haloMesh = h:FindFirstChildWhichIsA("SpecialMesh")
		table.insert(haloParts, { part = h, cf = p.CFrame, size = p.Size, mesh = haloMesh, meshScale = if haloMesh then haloMesh.Scale else nil })
	end
	halo.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	local view = viewOf(id, wide == true)
	local function place(aspect: number)
		local cf, distance = fit(middle, corners, view, aspect)
		camera.CFrame = cf
		local back = extent * HALO_BACK
		local k = (distance + back) / math.max(distance, 0.01)
		local pad = extent * HALO
		local away = cf.LookVector * back
		for _, h in haloParts do
			-- (A MeshPart's size scales its mesh: the pad thickens every piece, thin ones most.)
			local grown = (h.size + Vector3.one * pad) * k
			h.part.Size = grown
			-- (A mesh in a SpecialMesh ignores its part's size: its own scale grows the same way.)
			local mesh, meshScale = h.mesh, h.meshScale
			if mesh and meshScale then
				mesh.Scale = meshScale * (grown / Vector3.new(math.max(h.size.X, 0.001), math.max(h.size.Y, 0.001), math.max(h.size.Z, 0.001)))
			end
			h.part.CFrame = (h.cf - h.cf.Position) + middle + (h.cf.Position - middle) * k + away
		end
	end
	place(1)
	camera.Parent = frame
	frame.CurrentCamera = camera
	if wide then
		-- (Fitted again to the frame's real shape once it has one, and when it changes.)
		local function refit()
			local px = frame.AbsoluteSize
			if px.X > 0 and px.Y > 0 then
				place(px.X / px.Y)
			end
		end
		frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
		task.defer(refit)
	end
	return disc
end

return ToolPicture
