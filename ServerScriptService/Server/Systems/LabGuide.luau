--!strict
-- 21 Nov 2026 (the owner: "even a 9-year-old must understand how to use everything in the lab, like
-- feeding the spider a ragdoll, or the other monsters"). Vault: show, don't tell; one accent colour
-- means "you can use this"; a prompt is a verb and an object; labels of one or two words.
-- Every creature in the yard and every PUT RAGDOLL HERE station gets:
--   * a sign in the world (studs): the drawn "dummy -> " picture and two words, FEED ME!;
--   * a glowing cyan ring on the ground where a dummy goes (Client/LabGuideClient pulses it, and the
--     nearest one lights up with DROP HERE! while you carry a dummy);
--   * a button (ProximityPrompt "Feed / Spider"): press it and the nearest free dummy of the lab
--     flies in an arc right into it. So a child who only presses the button still sees it work,
--     and one who carries a dummy over learns the real way.
-- A leaf for the rest: it reads the yard (LabCreatures' Trigger attribute) and the stations, and
-- moves bodies only through DummyControl (the lab's player simulates them).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any

local LabGuide = {}

LabGuide.ACCENT = Color3.fromRGB(40, 220, 255) -- (the one "use me" colour: nothing else in the lab is this cyan)
LabGuide.RING = 10 -- studs across a drop ring
LabGuide.PROMPT_REACH = 18 -- studs from the button's point
LabGuide.SPOT_GAP = 2 -- s between two tosses into one creature
LabGuide.PLAYER_GAP = 0.8 -- s between two presses of one player
LabGuide.FLIGHT_SPEED = 55 -- studs/s along the ground a tossed dummy covers (its flight time follows)
LabGuide.TAG = "GuideRing"

-- What each creature's button and sign say (verb, object, the sign's words).
LabGuide.WORDS = table.freeze({
	Spider = { "Feed", "Spider", "FEED ME!" },
	Frog = { "Feed", "Frog", "FEED ME!" },
	Plant = { "Feed", "Giant Plant", "FEED ME!" },
	Chicken = { "Feed", "Chicken", "FEED ME!" },
	Whale = { "Feed", "Whale", "FEED ME!" },
	Washer = { "Wash", "a Dummy", "WASH ME!" },
	Vacuum = { "Feed", "Robot Vacuum", "FEED ME!" },
	Mole = { "Feed", "Mole", "FEED ME!" },
	Slingshot = { "Load", "Slingshot", "LOAD ME!" },
}) :: { [string]: { string } }

-- The lab's machines that get a toss button too (part name -> verb, object, no sign: they have theirs).
LabGuide.MACHINES = table.freeze({
	CannonPad = { "Fire", "Cannon", "" },
	LavaPool = { "Toss", "Lava", "" },
	TrampolinePad = { "Bounce", "Trampoline", "" },
}) :: { [string]: { string } }

local spotLast: { [Instance]: number } = {}
local playerLast: { [Player]: number } = {}
local tossedCount = 0

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function anchoredPart(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- The ground under a point (the lab floor, the yard, a pool's bottom), ignoring dummies and players.
local function groundUnder(at: Vector3, fallbackY: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ignore, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), params)
	return if hit then hit.Position.Y else fallbackY
end

-- The sign over a spot: a white card with a cyan edge, the drawn picture and two words.
local function sign(point: BasePart, words: string, height: number)
	local g = Instance.new("BillboardGui")
	g.Name = "GuideSign"
	g.Size = UDim2.fromScale(10, 3.4) -- (studs: a sign in the world, smaller far off)
	g.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	g.MaxDistance = 80
	g.LightInfluence = 0
	g.Adornee = point
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.3, 0)
	c.Parent = card
	local edge = Instance.new("UIStroke")
	edge.Color = LabGuide.ACCENT
	edge.Thickness = 4
	edge.Parent = card
	local pic = Instance.new("ImageLabel")
	pic.BackgroundTransparency = 1
	pic.Size = UDim2.fromScale(0.36, 1.1)
	pic.AnchorPoint = Vector2.new(0, 0.5)
	pic.Position = UDim2.fromScale(0.02, 0.5)
	pic.ScaleType = Enum.ScaleType.Fit
	pic.Image = DrawnIcons.ASSETS.guide_feed or ""
	pic.Parent = card
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.AnchorPoint = Vector2.new(1, 0.5)
	text.Position = UDim2.fromScale(0.96, 0.5)
	text.Size = UDim2.fromScale(0.6, 0.78)
	text.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(24, 26, 40)
	text.Text = words
	text.Parent = card
	card.Parent = g
	g.Parent = point
end

-- A dummy of this lab to toss: free (not held, in no machine, not cooling down), the nearest to
-- where the player stands.
local function pickDummy(owner: Player, near: Vector3): Model?
	local Lab = lazy("Lab")
	local best: Model? = nil
	local bestD = math.huge
	for _, model in Lab.dummiesOf(owner) do
		local pelvis = model:FindFirstChild("LowerTorso")
		if model.Parent and pelvis and pelvis:IsA("BasePart") and model:GetAttribute("Held") ~= true
			and model:GetAttribute("InMachine") == nil and model:GetAttribute("Frozen") ~= true
			and os.clock() >= ((model:GetAttribute("MachineCool") :: number?) or 0) then
			local d = (pelvis.Position - near).Magnitude
			if d < bestD then
				best, bestD = model, d
			end
		end
	end
	return best
end

-- The velocity that lands a body from `from` at `to` after a flight that follows the distance.
function LabGuide.arc(from: Vector3, to: Vector3): Vector3
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
	local t = math.clamp(flat / LabGuide.FLIGHT_SPEED, 0.8, 1.5)
	local g = Workspace.Gravity
	return (to - from) / t + Vector3.new(0, 0.5 * g * t, 0)
end

-- Tosses one free dummy of the lab into `target`; true if one flew.
function LabGuide.toss(player: Player, owner: Player, target: Vector3): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local near = if root and root:IsA("BasePart") then root.Position else target
	local model = pickDummy(owner, near)
	if not model then
		return false
	end
	local pelvis = model:FindFirstChild("LowerTorso")
	if not (pelvis and pelvis:IsA("BasePart")) then
		return false
	end
	local v = LabGuide.arc(pelvis.Position, target)
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	lazy("DummyControl").hit(model, pelvis, v * mass, pelvis.Position, v.Magnitude + 20, nil)
	tossedCount += 1
	return true
end

-- One guided spot: its point (sign and button), its ring, and what the button does.
local function addSpot(into: Instance, origin: Vector3, id: string, target: () -> Vector3, words: { string }, signHeight: number, signTop: (() -> number?)?)
	local at = target()
	local point = anchoredPart("GuidePoint", Vector3.new(1, 1, 1), CFrame.new(at), into)
	point.Transparency = 1
	point:SetAttribute("GuideId", id)
	local floorY = groundUnder(at, origin.Y)
	-- (A dashed ring of glowing pieces, a drop zone: it marks the spot without covering what is there,
	-- the lava or the cannon's pad. The ring part itself is invisible and carries the pieces.)
	local ring = anchoredPart(LabGuide.TAG, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at.X, floorY + 0.12, at.Z), into)
	ring.Transparency = 1
	local pieces = 14
	for k = 1, pieces do
		local a = k / pieces * math.pi * 2
		local seg = anchoredPart("GuideRingSeg", Vector3.new(LabGuide.RING * math.pi / pieces * 0.62, 0.12, 0.5), CFrame.new(at.X + math.cos(a) * LabGuide.RING / 2, floorY + 0.3, at.Z + math.sin(a) * LabGuide.RING / 2) * CFrame.Angles(0, -a + math.pi / 2, 0), ring)
		seg.Material = Enum.Material.Neon
		seg.Color = LabGuide.ACCENT
		seg.Transparency = 0.25
	end
	ring:SetAttribute("GuideId", id)
	CollectionService:AddTag(ring, LabGuide.TAG)
	sign(point, words[3], signHeight)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Guide"
	prompt.ActionText = words[1]
	prompt.ObjectText = words[2]
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = LabGuide.PROMPT_REACH
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = point
	-- (A creature that moves, the vacuum, or a trigger set on its first look: the point follows.)
	task.spawn(function()
		while point.Parent do
			task.wait(1)
			local now = target()
			if (now - point.Position).Magnitude > 0.5 then
				point.CFrame = CFrame.new(now)
				local moveBy = CFrame.new(now.X, groundUnder(now, origin.Y) + 0.12, now.Z) * ring.CFrame:Inverse()
				for _, seg in ring:GetChildren() do
					if seg:IsA("BasePart") then
						seg.CFrame = moveBy * seg.CFrame
					end
				end
				ring.CFrame = moveBy * ring.CFrame
			end
			-- (The sign stands clear over the creature's head: its top, measured, plus a little.)
			local top = if signTop then signTop() else nil
			local board = point:FindFirstChild("GuideSign")
			if top and board and board:IsA("BillboardGui") then
				board.StudsOffsetWorldSpace = Vector3.new(0, math.max(signHeight, top + 3 - now.Y), 0)
			end
		end
	end)
	prompt.Triggered:Connect(function(player: Player)
		local now = os.clock()
		if now - (spotLast[point] or 0) < LabGuide.SPOT_GAP or now - (playerLast[player] or 0) < LabGuide.PLAYER_GAP then
			return
		end
		local Lab = lazy("Lab")
		local owner = Lab.ownerAt(origin + Vector3.new(0, 1, 0))
		if not owner then
			return
		end
		-- (The lab's player, or someone the lab lets in: the same rule as a blast's reach.)
		if player ~= owner then
			local okReach, mayReach = pcall(function()
				return (require(Shared:WaitForChild("Zones")) :: any).mayReach(player, target())
			end)
			if not (okReach and mayReach) then
				return
			end
		end
		spotLast[point] = now
		playerLast[player] = now
		if not LabGuide.toss(player, owner, target() + Vector3.new(0, 1.5, 0)) then
			pcall(function()
				lazy("ProgressService").notice(player, "No free dummy right now. Try again in a moment!")
			end)
		end
	end)
end

-- Builds the guide into a lab's Playground folder (after LabCreatures.build and the stations).
function LabGuide.build(folder: Instance, origin: Vector3)
	local into = Instance.new("Folder")
	into.Name = "Guide"
	into.Parent = folder
	-- The creatures.
	local yard = folder:FindFirstChild("CreatureYard")
	local layout = lazy("LabCreatures").LAYOUT
	for _, spot in layout do
		local words = LabGuide.WORDS[spot.id]
		local sub = yard and yard:FindFirstChild(spot.id)
		if words and sub then
			local fallback = origin + Vector3.new(spot.x, 3, spot.z)
			local function target(): Vector3
				local t = sub:GetAttribute("Trigger")
				return if typeof(t) == "Vector3" then t else fallback
			end
			-- (The creature's own model: LabCreatures marks it with "Creature".)
			local function signTop(): number?
				for _, c in sub:GetChildren() do
					if c:IsA("Model") and c:GetAttribute("Creature") == spot.id then
						local cf, size = c:GetBoundingBox()
						return cf.Position.Y + size.Y / 2
					end
				end
				return nil
			end
			addSpot(into, origin, spot.id, target, words, 6, signTop)
		end
	end
	-- The PUT RAGDOLL HERE stations (their own signs say it; the button and the ring are added).
	for _, d in folder:GetChildren() do
		if d:IsA("BasePart") and d.Name == "StationPad" then
			local station = tostring(d:GetAttribute("Station") or "PAD")
			local pad = d
			local function target(): Vector3
				return pad.Position + Vector3.new(0, 1.5, 0)
			end
			local name = string.upper(string.sub(station, 1, 1)) .. string.lower(string.sub(station, 2))
			addSpot(into, origin, "Station:" .. station, target, { "Launch", name, "" }, 0)
		end
	end
	-- (21 Nov 2026, research: the biggest games' machines teach themselves: 44 % of one game's players
	-- launched a dummy with its fan. The cannon, the lava and the trampoline get the same button.)
	for name, words in LabGuide.MACHINES do
		local partOf = folder:FindFirstChild(name, true)
		if partOf and partOf:IsA("BasePart") then
			local p = partOf
			local function target(): Vector3
				return p.Position + Vector3.new(0, 1.5, 0)
			end
			addSpot(into, origin, "Station:" .. name, target, words, 0)
		end
	end
	-- (A station already has its own sign: its guide sign is left out.)
	for _, g in into:GetDescendants() do
		if g:IsA("BillboardGui") and g.Name == "GuideSign" then
			local point = g.Parent
			local id = point and point:GetAttribute("GuideId")
			if type(id) == "string" and string.sub(id, 1, 8) == "Station:" then
				g:Destroy()
			end
		end
	end
	return into
end

-- Tests: how many dummies were tossed so far.
function LabGuide.tossedForTest(): number
	return tossedCount
end

Players.PlayerRemoving:Connect(function(player)
	playerLast[player] = nil
end)

return LabGuide
