--!strict
-- v4 C1 (owner: "the lab is messy; always something new"). On top of each lab (pictures only, no
-- collisions, nothing moves the machines that the tests and systems rely on):
--   * Zones: painted floor areas with a name on the floor, so the lab reads as places, not a pile
--     of things: TEST ZONE (the dummies' row), LAUNCH ZONE (cannon and ramp), VEHICLE BAY (the cars,
--     with parking lines), EVENT PAD (round the BIG RED BUTTON), HAZARDS (lava and spikes).
--   * Today's machine: one machine is featured each UTC day (the same on every server): a gold
--     light column over it and a "TODAY'S MACHINE" sign. Players see it change every day.
--   * NEW: a small "NEW" tag over what came in the latest update, for Config.NEW_DAYS days after
--     Config.NEW_SINCE (UTC date), so returning players spot it.
-- Config.LAB_ZONES switches it all off.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LabZones = {}

type Zone = { name: string, x: number, z: number, w: number, d: number, color: Color3, label: Vector2? }

-- Lab space (x across, z along; see LabDress for the layout).
LabZones.ZONES = table.freeze({
	{ name = "TEST ZONE", x = 0, z = -32, w = 44, d = 34, color = Color3.fromRGB(70, 140, 220), label = Vector2.new(0, -12) },
	{ name = "LAUNCH ZONE", x = 40, z = 14, w = 26, d = 34, color = Color3.fromRGB(240, 150, 40), label = Vector2.new(40, -1) },
	{ name = "VEHICLE BAY", x = 70, z = -6, w = 18, d = 70, color = Color3.fromRGB(150, 150, 160), label = Vector2.new(70, -36) },
	{ name = "EVENT PAD", x = 14, z = 14, w = 14, d = 14, color = Color3.fromRGB(220, 50, 50), label = Vector2.new(14, 5) },
	{ name = "HAZARDS", x = -6, z = -54, w = 70, d = 18, color = Color3.fromRGB(230, 200, 40), label = Vector2.new(-40, -54) },
} :: { Zone })

-- The machines that can be "today's": the part that marks each (by name, in the lab's folder).
LabZones.MACHINES = (function()
	local list = {
		{ part = "CannonPad", label = "HUMAN CANNON" },
		{ part = "Bullseye", label = "BULLSEYE" },
		{ part = "LavaPool", label = "LAVA PIT" },
		{ part = "MaceBall", label = "SPINNING MACE" },
		{ part = "SwingBall", label = "WRECKING BALL" },
		{ part = "TrampolinePad", label = "TRAMPOLINE" },
		{ part = "StationPad", label = "LAUNCH STATIONS" },
		{ part = "BigButton", label = "BIG RED BUTTON" },
	}
	-- (V9-NOW 17 / V9-0ae: with Config.BULLSEYE false the bullseye is never today's machine.)
	if (Config :: any).BULLSEYE == false then
		table.remove(list, 2)
	end
	return table.freeze(list)
end)()

-- Today's machine (UTC day; the same on every server). Pure, for the tests.
function LabZones.todayIndex(unixTime: number): number
	local day = math.floor(unixTime / 86400)
	return (day % #LabZones.MACHINES) + 1
end

-- Whether the NEW tags still show at `unixTime`.
function LabZones.newShowing(unixTime: number): boolean
	local since = (Config :: any).NEW_SINCE
	local days = (Config :: any).NEW_DAYS or 7
	if type(since) ~= "string" then
		return false
	end
	local y, m, d = string.match(since, "^(%d+)-(%d+)-(%d+)$")
	if not y then
		return false
	end
	local start = DateTime.fromUniversalTime(tonumber(y) :: number, tonumber(m) :: number, tonumber(d) :: number).UnixTimestamp -- (UTC, never the machine's local time)
	return unixTime >= start and unixTime < start + days * 86400
end

local function flat(name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = transparency
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function floorText(parent: Instance, text: string, at: Vector3, width: number, color: Color3)
	local p = flat("ZoneLabel", Vector3.new(width, 0.05, width * 0.18), CFrame.new(at), color, 1, parent)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Top
	g.CanvasSize = Vector2.new(width * 30, width * 30 * 0.18)
	g.LightInfluence = 0.6
	g.MaxDistance = 220
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = text
	t.TextScaled = true
	t.TextColor3 = color
	t.TextTransparency = 0.15
	t.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
	t.Rotation = 180
	t.Parent = g
end

LabZones.PX_PER_STUD = 19 -- a sign designed in px: its size in studs (260 px = 13.7 studs)

-- A gold star over today's machine (Config.ICON_SIGNS): the drawn star on a dark round badge.
LabZones.PICTOGRAMS = false -- (24 Nov 2026, owner: "remove all pictograms": no star, no NEW tags)
local function starBadge(parent: Instance, adornee: BasePart, offset: number)
	if not LabZones.PICTOGRAMS then
		return
	end
	local DrawnIcons = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("DrawnIcons")) :: any
	local g = Instance.new("BillboardGui")
	g.Name = "ZoneSign"
	g.Adornee = adornee
	g.Size = UDim2.fromScale(4.5, 4.5)
	g.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	g.MaxDistance = 140
	g.LightInfluence = 0
	local disc = Instance.new("Frame")
	disc.Size = UDim2.fromScale(1, 1)
	disc.BackgroundColor3 = Color3.fromRGB(34, 28, 52)
	disc.BackgroundTransparency = 0.1
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = disc
	local ring = Instance.new("UIStroke")
	ring.Thickness = 4
	ring.Color = Color3.fromRGB(255, 205, 60)
	ring.Parent = disc
	local pic = Instance.new("ImageLabel")
	pic.BackgroundTransparency = 1
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	pic.Position = UDim2.fromScale(0.5, 0.5)
	pic.Size = UDim2.fromScale(0.8, 0.8)
	pic.ScaleType = Enum.ScaleType.Fit
	pic.Image = DrawnIcons.ASSETS.star or ""
	pic.Parent = disc
	disc.Parent = g
	g.Parent = parent
end

local function sign(parent: Instance, adornee: BasePart, text: string, color: Color3, offset: number, size: Vector2)
	local g = Instance.new("BillboardGui")
	g.Name = "ZoneSign"
	g.Adornee = adornee
	-- (UI audit 21 Nov 2026: in studs, a sign in the world that gets smaller with distance, not a
	-- pixel card that sat on top of the HUD's mission card from across the lab.)
	g.Size = UDim2.fromScale(size.X / LabZones.PX_PER_STUD, size.Y / LabZones.PX_PER_STUD)
	g.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	g.MaxDistance = 140
	g.LightInfluence = 0
	g.Parent = parent
	local box = Instance.new("TextLabel")
	box.Size = UDim2.fromScale(1, 1)
	box.BackgroundColor3 = color
	box.BackgroundTransparency = 0.05
	box.Text = text
	box.TextScaled = true
	box.TextColor3 = Color3.fromRGB(20, 18, 14)
	box.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = box
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 3)
	pad.PaddingBottom = UDim.new(0, 3)
	pad.Parent = box
	box.Parent = g
end

-- Builds the zones, today's machine and the NEW tags into `folder` (the lab's Playground folder).
function LabZones.build(folder: Instance, origin: Vector3)
	if not (Config :: any).LAB_ZONES then
		return
	end
	local into = Instance.new("Folder")
	into.Name = "Zones"
	into:SetAttribute("Origin", origin)
	into:SetAttribute("NewShowing", LabZones.newShowing(os.time()))
	into.Parent = folder
	local y = origin.Y + 0.06
	-- (V7-1, the owner: no painted boxes on the floor. Config.ZONE_FLOOR brings the tints, edge lines,
	-- floor names and parking lines back; the paths of V7-2 show the way instead.)
	for _, z in if (Config :: any).ZONE_FLOOR then LabZones.ZONES else {} do
		local c = CFrame.new(origin + Vector3.new(z.x, 0, z.z))
		-- A soft tint and a crisp edge line (four thin strips).
		flat("ZoneTint", Vector3.new(z.w, 0.04, z.d), c + Vector3.new(0, y - origin.Y, 0), z.color, 0.86, into)
		local edge = 0.35
		for _, s in { { 0, z.d / 2, z.w, edge }, { 0, -z.d / 2, z.w, edge }, { z.w / 2, 0, edge, z.d }, { -z.w / 2, 0, edge, z.d } } do
			flat("ZoneEdge", Vector3.new(s[3], 0.05, s[4]), c + Vector3.new(s[1], y - origin.Y + 0.01, s[2]), z.color, 0.25, into)
		end
		if z.label then
			floorText(into, z.name, origin + Vector3.new(z.label.X, y - origin.Y + 0.02, z.label.Y), math.min(z.w - 2, 22), z.color)
		end
	end
	-- Parking lines in the vehicle bay.
	for i = 0, if (Config :: any).ZONE_FLOOR then 3 else -1 do
		flat("BayLine", Vector3.new(14, 0.05, 0.3), CFrame.new(origin + Vector3.new(70, y - origin.Y + 0.02, -24 + i * 22)), Color3.fromRGB(240, 240, 240), 0.2, into)
	end
	-- (A sign floats over the top of the thing it names, and over anything standing round it: an
	-- invisible anchor at the highest point within a few studs, so a frame or glass never hides it.)
	local function topOf(thing: Instance, at: Vector3): Vector3
		local high = at.Y
		local list = if thing:IsA("Model") then thing:GetDescendants() else { thing }
		for _, d in list do
			if d:IsA("BasePart") then
				high = math.max(high, d.Position.Y + d.Size.Y / 2)
			end
		end
		-- Anything else of the lab right round it (a swing's frame, a portal's arch).
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 0.9 and not d:IsDescendantOf(into) then
				local flatGap = Vector2.new(d.Position.X - at.X, d.Position.Z - at.Z).Magnitude
				if flatGap < 5 + math.max(d.Size.X, d.Size.Z) / 2 and d.Size.Y < 40 then
					high = math.max(high, d.Position.Y + d.Size.Y / 2)
				end
			end
		end
		return Vector3.new(at.X, high, at.Z)
	end
	local function anchorAt(p: Vector3): Part
		local a = flat("SignAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(p), Color3.new(1, 1, 1), 1, into)
		return a
	end
	-- Today's machine.
	local pick = LabZones.MACHINES[LabZones.todayIndex(os.time())]
	local target = folder:FindFirstChild(pick.part, true)
	into:SetAttribute("Today", pick.part)
	if target and target:IsA("BasePart") then
		-- (V7-1, the owner: no yellow light column over it; Config.TODAY_LIGHT brings it back.)
		if (Config :: any).TODAY_LIGHT then
			local column = flat("TodayLight", Vector3.new(60, 9, 9), CFrame.new(target.Position + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 205, 60), 0.82, into)
			column.Shape = Enum.PartType.Cylinder
			column.Material = Enum.Material.Neon
		end
		local machine = if target.Parent and target.Parent:IsA("Model") then target.Parent else target
		-- (21 Nov 2026, Config.ICON_SIGNS: a big gold star over it says "today's one", no words.)
		if (Config :: any).ICON_SIGNS then
			starBadge(into, anchorAt(topOf(machine, target.Position)), 5)
		else
			sign(into, anchorAt(topOf(machine, target.Position)), "\u{2B50} TODAY'S MACHINE: " .. pick.label, Color3.fromRGB(255, 205, 60), 4, Vector2.new(260, 40))
		end
	end
	-- NEW tags.
	if LabZones.PICTOGRAMS and LabZones.newShowing(os.time()) then
		for _, name in ((Config :: any).NEW_IN_LAB or {}) :: { string } do
			local thing = folder:FindFirstChild(name, true)
			local part = if thing and thing:IsA("Model") then thing.PrimaryPart or thing:FindFirstChildWhichIsA("BasePart", true) elseif thing and thing:IsA("BasePart") then thing else nil
			if part and part ~= target then
				sign(into, anchorAt(topOf(thing :: Instance, part.Position)), "NEW", Color3.fromRGB(80, 230, 120), 3, Vector2.new(64, 28))
			end
		end
	end
end


-- A server that stays up past UTC midnight (or past the end of the NEW window) redraws each lab's
-- zones once a minute when today's machine or the NEW state has changed.
function LabZones.start()
	if not (Config :: any).LAB_ZONES then
		return
	end
	task.spawn(function()
		while true do
			task.wait(60)
			local now = os.time()
			local today = LabZones.MACHINES[LabZones.todayIndex(now)].part
			local showing = LabZones.newShowing(now)
			local pg = workspace:FindFirstChild("Playground")
			for _, folder in if pg then pg:GetChildren() else {} do
				local zones = folder:FindFirstChild("Zones")
				local origin = zones and zones:GetAttribute("Origin")
				if zones and typeof(origin) == "Vector3" and (zones:GetAttribute("Today") ~= today or zones:GetAttribute("NewShowing") ~= showing) then
					zones:Destroy()
					pcall(LabZones.build, folder, origin)
				end
			end
		end
	end)
end
return LabZones
