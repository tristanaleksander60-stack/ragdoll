--!strict
-- The Christmas theme (round 3, M7): on from now until 6 January, then 1 December - 6 January every
-- year (Christmas.luau), and the owner can switch it on, off or back to the dates (AdminService:
-- "Theme"); his choice is kept (a DataStore; every server hears of a change at once).
-- While it is on:
--   the plaza: snow on the ground, a big tree with lights and a star, presents under it, a garland
--     on every lamp and snow on the boards' tops (all in one folder: off removes it, nothing else
--     is touched)
--   every lab dummy and plaza person wears a Santa hat and a scarf (new ones too)
--   presents drop into the plaza every GIFT_EVERY s: touching one opens it (an egg, once per
--     player per drop; it is a game event, never a TikTok gift)
--   the Workspace attribute "Christmas": screens add falling snow and the radio's Christmas songs
-- Everything is anchored or welded and massless, no part collides with bodies but the tree, and no
-- script runs per frame (no lag: T37 runs with the theme on).

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Christmas = require(Shared:WaitForChild("Christmas"))
local Log = require(Shared:WaitForChild("Log"))
local ProgressService = require(script.Parent.ProgressService)
local FxService = require(script.Parent.FxService)
local Metrics = require(script.Parent.Metrics)
local DummyFactory = require(script.Parent.DummyFactory)
local DummyControl = require(script.Parent.DummyControl)

local log = Log.new("Christmas")

local ChristmasService = {}

local STORE = "Theme_v1"
local KEY = "Christmas"
local TOPIC = "ThemeChanged"
local CHECK_EVERY = 60 -- s between date checks (midnight on 6 January turns it off by itself)
ChristmasService.GIFT_EVERY = 600 -- s between present drops while it is on
ChristmasService.GIFTS = 6 -- presents a drop
ChristmasService.GIFT_STAY = 90 -- s an unopened present lies before it goes
local PLAZA_MIDDLE = Vector3.new(0, 0, 85)
local TREE_ANGLE, TREE_RADIUS = 180, 22 -- (the plaza's west side; the fountain is east: WorldMaps)
local TREE_KEEP = 14 -- studs round the tree's foot no dropped present lands in (its tier is 9.5, its presents to 12)
local SNOW_RADIUS = 56

local RED = Color3.fromRGB(205, 40, 50)
local WHITE = Color3.fromRGB(248, 250, 255)
local SNOW = Color3.fromRGB(228, 236, 246) -- (the ground: a cool white that does not glare)
local GREEN = Color3.fromRGB(34, 120, 62)
local GREEN_LIGHT = Color3.fromRGB(46, 158, 84)
local GOLD = Color3.fromRGB(255, 200, 60)
local LIGHTS = { Color3.fromRGB(255, 70, 70), GOLD, Color3.fromRGB(80, 170, 255), Color3.fromRGB(250, 250, 255), Color3.fromRGB(120, 230, 120) }
local WRAPS = { RED, Color3.fromRGB(40, 140, 80), Color3.fromRGB(60, 110, 230), Color3.fromRGB(150, 70, 210), GOLD }

local mode: Christmas.Mode = "auto"
local isOn = false
local store: DataStore? = nil
local labOrigin = Vector3.zero
local folder: Folder? = nil
local dropNo = 0
local opened: { [number]: { [number]: boolean } } = {} -- drop number -> user ids that opened one
local told: { [number]: { [number]: boolean } } = {} -- drop number -> user ids told why they get no egg

local function today(): { year: number, month: number, day: number }
	return os.date("!*t", math.floor(Workspace:GetServerTimeNow())) :: any
end

ChristmasService.dateForTest = nil :: { year: number, month: number, day: number }?

------------------------------------------------------------------------------------------------
-- Parts

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Shape = shape or Enum.PartType.Block
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = collide == true
	p.CanQuery = collide == true -- (lights and garlands are never in a shot's or a walker's way)
	p.CanTouch = false
	p.CastShadow = collide == true
	p.Parent = parent
	return p
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- (a cylinder's axis is X: this stands it up)

local function floorAt(x: number, z: number, fallback: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	for _, name in { "Dummies", "Christmas" } do
		local f = Workspace:FindFirstChild(name)
		if f then
			table.insert(skip, f)
		end
	end
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(Vector3.new(x, fallback + 40, z), Vector3.new(0, -80, 0), params)
	return if hit then hit.Position.Y else fallback
end

-- The tree: five cone tiers, each an eight-sided cone of wedges (no cone part in Roblox), lights
-- on their slopes, a gold star on top. About 24 studs tall: four people high.
local TIERS = { -- bottom radius, height, where its bottom stands
	{ r = 9.5, h = 7, y = 2.6 },
	{ r = 8, h = 6.5, y = 6.4 },
	{ r = 6.4, h = 6, y = 10 },
	{ r = 4.8, h = 5.5, y = 13.4 },
	{ r = 3.2, h = 5, y = 16.6 },
}
local SIDES = 8

local function tree(parent: Instance, base: Vector3)
	local model = Instance.new("Model")
	model.Name = "Tree"
	part(model, "Trunk", Vector3.new(3.2, 2.4, 2.4), CFrame.new(base + Vector3.new(0, 1.6, 0)) * UP, Color3.fromRGB(110, 70, 40), Enum.PartType.Cylinder, Enum.Material.Wood, true)
	local rng = Random.new(25) -- (the same lights in every server)
	local half = math.pi / SIDES
	for i, t in TIERS do
		local width = 2 * t.r * math.tan(half) + 0.05
		local color = if i % 2 == 1 then GREEN else GREEN_LIGHT
		for k = 0, SIDES - 1 do
			local a = k / SIDES * math.pi * 2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			local at = base + Vector3.new(0, t.y + t.h / 2, 0) + out * (t.r / 2)
			-- (A wedge's slope faces its front: the front looks outward, the tall back stands on the axis.)
			local w = Instance.new("WedgePart")
			w.Name = "Tier" .. i
			w.Anchored = true
			w.Size = Vector3.new(width, t.h, t.r)
			w.CFrame = CFrame.lookAt(at, at + out)
			w.Color = color
			w.Material = Enum.Material.Grass
			w.TopSurface = Enum.SurfaceType.Smooth
			w.BottomSurface = Enum.SurfaceType.Smooth
			w.CanCollide = i == 1
			w.CanTouch = false
			w.CastShadow = true
			w.Parent = model
		end
		-- Lights on the slope, a loose spiral round the tier.
		local n = math.floor(t.r * 1.9)
		for k = 1, n do
			local h = rng:NextNumber(0.12, 0.8) * t.h
			local side = math.floor(rng:NextNumber(0, SIDES))
			local off = rng:NextNumber(-0.85, 0.85) * half
			local a = side / SIDES * math.pi * 2 + off
			-- Where the tier's surface is that way at that height: the farthest any wedge reaches
			-- (a wedge is as wide at its top as at its foot, so its neighbours stick out past it).
			local depth = t.r * (1 - h / t.h)
			local r = 0
			for j = 0, SIDES - 1 do
				local dAng = a - j / SIDES * math.pi * 2
				local c, sn = math.cos(dAng), math.abs(math.sin(dAng))
				if c > 0.01 then
					r = math.max(r, math.min(depth / c, if sn > 0.001 then (width / 2) / sn else math.huge))
				end
			end
			r += 0.25
			local at = base + Vector3.new(math.cos(a) * r, t.y + h, math.sin(a) * r)
			part(model, "Light", Vector3.new(0.75, 0.75, 0.75), CFrame.new(at), LIGHTS[(k + i) % #LIGHTS + 1], Enum.PartType.Ball, Enum.Material.Neon)
		end
	end
	-- The star: a bright ball with four points, and a light.
	local last = TIERS[#TIERS]
	local top = base + Vector3.new(0, last.y + last.h + 0.6, 0)
	local star = part(model, "Star", Vector3.new(1.8, 1.8, 1.8), CFrame.new(top), GOLD, Enum.PartType.Ball, Enum.Material.Neon)
	for k = 0, 3 do
		part(model, "Point", Vector3.new(0.4, 3.8, 0.4), CFrame.new(top) * CFrame.Angles(0, 0, math.rad(k * 45)), GOLD, nil, Enum.Material.Neon)
	end
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 20
	light.Brightness = 2
	light.Parent = star
	model.Parent = parent
end

local function present(parent: Instance, cf: CFrame, size: number, color: Color3, anchored: boolean): Model
	local model = Instance.new("Model")
	model.Name = "Present"
	local box = part(model, "Box", Vector3.new(size, size * 0.85, size), cf, color, nil, Enum.Material.SmoothPlastic, true)
	box.Anchored = anchored
	local ribbon = if color == GOLD then RED else GOLD
	local function welded(name: string, s: Vector3, offset: CFrame, c: Color3, shape: Enum.PartType?)
		local p = part(model, name, s, cf * offset, c, shape)
		p.Anchored = false
		p.Massless = true
		p.CanQuery = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = box
		w.Part1 = p
		w.Parent = p
	end
	welded("RibbonX", Vector3.new(size + 0.05, size * 0.85 + 0.05, size * 0.18), CFrame.new(), ribbon)
	welded("RibbonZ", Vector3.new(size * 0.18, size * 0.85 + 0.05, size + 0.05), CFrame.new(), ribbon)
	welded("Bow", Vector3.new(size * 0.4, size * 0.4, size * 0.4), CFrame.new(0, size * 0.5, 0), ribbon, Enum.PartType.Ball)
	model.PrimaryPart = box
	model.Parent = parent
	return model
end

local function lampsOf(): { BasePart }
	local poles = {}
	local dressing = Workspace:FindFirstChild("PlazaDressing", true)
	if not dressing then
		return poles
	end
	for _, lamp in dressing:GetChildren() do
		if lamp:IsA("Model") and string.find(lamp.Name, "StreetLamp", 1, true) then
			local cf, size = lamp:GetBoundingBox()
			local p = Instance.new("Part") -- (a stand-in: where its pole stands and how tall)
			p.CFrame = cf
			p.Size = size
			table.insert(poles, p)
		end
	end
	return poles
end

local function garland(parent: Instance, pole: BasePart)
	local cf, size = pole.CFrame, pole.Size
	local baseY = cf.Position.Y - size.Y / 2
	-- (The lamp's pole stands at its model's footprint middle.)
	-- A garland wound round the pole: two and a half turns from low on it to under the lamp, a red
	-- light every third bead; a bow on top.
	local beads = 22
	for k = 0, beads - 1 do
		local f = k / (beads - 1)
		local a = f * math.pi * 5
		local spot = Vector3.new(cf.Position.X, baseY + size.Y * (0.12 + f * 0.6), cf.Position.Z) + Vector3.new(math.cos(a) * 0.6, 0, math.sin(a) * 0.6)
		part(parent, "Garland", Vector3.new(0.5, 0.5, 0.5), CFrame.new(spot), if k % 3 == 0 then RED else GREEN_LIGHT, Enum.PartType.Ball, if k % 3 == 0 then Enum.Material.Neon else Enum.Material.Grass)
	end
	part(parent, "Bow", Vector3.new(0.3, 0.7, 1.1), CFrame.new(Vector3.new(cf.Position.X, baseY + size.Y * 0.74, cf.Position.Z) + Vector3.new(0.65, 0, 0)), RED, nil, Enum.Material.Fabric)
end

local function dressPlaza()
	local existing = Workspace:FindFirstChild("Christmas")
	if existing then
		existing:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "Christmas"
	local middle = labOrigin + PLAZA_MIDDLE
	local floorY = floorAt(middle.X, middle.Z, middle.Y)
	-- Snow on the ground: one thin disc over the plaza (raycasts land on it: holes and pools show).
	local snow = part(f, "SnowGround", Vector3.new(0.1, SNOW_RADIUS * 2, SNOW_RADIUS * 2), CFrame.new(middle.X, floorY + 0.05, middle.Z) * UP, SNOW, Enum.PartType.Cylinder, Enum.Material.Snow)
	snow.CanQuery = true
	-- The tree, its presents.
	local a = math.rad(TREE_ANGLE)
	local base = Vector3.new(middle.X + math.cos(a) * TREE_RADIUS, floorY + 0.1, middle.Z + math.sin(a) * TREE_RADIUS)
	tree(f, base)
	local rng = Random.new(12)
	for k = 1, 8 do
		local ang = k / 8 * math.pi * 2 + 0.3
		local r = rng:NextNumber(10.6, 12) -- (round the foot of the lowest tier, 9.5 wide)
		local s = rng:NextNumber(1.4, 2.3)
		present(f, CFrame.new(base + Vector3.new(math.cos(ang) * r, s * 0.425, math.sin(ang) * r)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), s, WRAPS[k % #WRAPS + 1], true)
	end
	-- A garland on every lamp; snow on the boards' tops.
	for _, pole in lampsOf() do
		garland(f, pole)
	end
	local boards = Workspace:FindFirstChild("Boards")
	if boards then
		for _, board in boards:GetChildren() do
			local panel = board:FindFirstChild("Panel")
			if panel and panel:IsA("BasePart") then
				part(f, "SnowCap", Vector3.new(panel.Size.X + 0.3, 0.45, panel.Size.Z + 0.5), panel.CFrame * CFrame.new(0, panel.Size.Y / 2 + 0.2, 0), WHITE, nil, Enum.Material.Snow)
			end
		end
	end
	-- Snow on top of the plaza's sign and its posts (the plaza has no roofs: its tops get the snow).
	local dressing = Workspace:FindFirstChild("PlazaDressing", true)
	if dressing then
		local topSign: BasePart? = nil
		for _, p in dressing:GetChildren() do
			if p:IsA("BasePart") and p.Name == "Sign" and (not topSign or p.Position.Y > topSign.Position.Y) then
				topSign = p
			end
		end
		local sign = topSign
		if sign then
			part(f, "SignSnow", Vector3.new(sign.Size.X + 0.3, 0.45, sign.Size.Z + 0.5), sign.CFrame * CFrame.new(0, sign.Size.Y / 2 + 0.2, 0), WHITE, nil, Enum.Material.Snow)
		end
	end
	f.Parent = Workspace
	folder = f
end

------------------------------------------------------------------------------------------------
-- Hats and scarves

local function wearable(model: Model, head: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Shape = shape or Enum.PartType.Block
	p.Color = color
	p.Material = material or Enum.Material.Fabric
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = head.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = p
	weld.C0 = offset
	weld.Parent = p
	p.Parent = model
end

-- Whether a body wears a hat of its own (the crowd's chef, guard and tourist: CrowdService), or hair
-- too tall for a Santa hat (round 4, M11: an afro, dreads or a top knot, marked TallHair).
local OWN_HATS = { "ChefHat", "Cap", "GuardCap", "BucketHat", "HatTop", "HardHat", "StrawTop", "Helmet", "SunTop" } -- (v4 B3: the open-air maps' hats)
local function hasOwnHat(body: Model): boolean
	local outfit = body:FindFirstChild("Outfit")
	if outfit then
		for _, name in OWN_HATS do
			if outfit:FindFirstChild(name) then
				return true
			end
		end
		for _, item in outfit:GetChildren() do
			if item:IsA("Accessory") and item:GetAttribute("TallHair") == true then
				return true
			end
		end
	end
	return false
end

function ChristmasService.dress(body: Model)
	if body:FindFirstChild("XmasHat") or body:FindFirstChild("XmasScarf") then
		return
	end
	local head = body:FindFirstChild("Head")
	local torso = body:FindFirstChild("UpperTorso")
	if not head or not head:IsA("BasePart") then
		return
	end
	if not hasOwnHat(body) then
		local hat = Instance.new("Model")
		hat.Name = "XmasHat"
		hat:SetAttribute("Worn", true) -- (never part of the body when it goes limp)
		local w, top = head.Size.X, head.Size.Y / 2
		wearable(hat, head, "Brim", Vector3.new(0.35, w * 1.12, w * 1.12), CFrame.new(0, top + 0.05, 0) * UP, WHITE, Enum.PartType.Cylinder)
		for i = 0, 2 do
			local d = w * (0.95 - i * 0.28)
			-- (Each step leans a little more to the side: a Santa hat flops.)
			wearable(hat, head, "Cone" .. i, Vector3.new(0.42, d, d), CFrame.new(i * 0.12, top + 0.38 + i * 0.36, 0) * CFrame.Angles(0, 0, math.rad(-8 * i)) * UP, RED, Enum.PartType.Cylinder)
		end
		wearable(hat, head, "Pom", Vector3.new(0.42, 0.42, 0.42), CFrame.new(0.45, top + 1.3, 0), WHITE, Enum.PartType.Ball)
		hat.Parent = body
	end
	if torso and torso:IsA("BasePart") then
		local scarf = Instance.new("Model")
		scarf.Name = "XmasScarf"
		scarf:SetAttribute("Worn", true)
		local sw = torso.Size.X
		local neck = CFrame.new(0, torso.Size.Y / 2 + 0.05, 0)
		wearable(scarf, torso, "Wrap", Vector3.new(0.38, sw * 0.62, sw * 0.62), neck * UP, RED)
		wearable(scarf, torso, "Tail", Vector3.new(0.32, 1.0, 0.12), neck * CFrame.new(sw * 0.18, -0.55, -torso.Size.Z / 2 - 0.08), GREEN)
		scarf.Parent = body
	end
end

local function undress(body: Instance)
	for _, name in { "XmasHat", "XmasScarf" } do
		local m = body:FindFirstChild(name)
		if m then
			m:Destroy()
		end
	end
end

-- Every body here now (the theme switched while they are about): dressed or undressed, then handed
-- back to whoever simulates it (a part welded onto a live body joins it as the server's). New
-- bodies are dressed as they are made (DummyFactory.onSpawn), before anyone simulates them.
local function dressAll(on: boolean)
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	for _, body in dummies:GetChildren() do
		if body:IsA("Model") then
			local had = body:FindFirstChild("XmasScarf") ~= nil or body:FindFirstChild("XmasHat") ~= nil
			if on then
				ChristmasService.dress(body)
			else
				undress(body)
			end
			if had ~= (body:FindFirstChild("XmasScarf") ~= nil or body:FindFirstChild("XmasHat") ~= nil) then
				DummyControl.reassertOwner(body)
			end
		end
	end
end

------------------------------------------------------------------------------------------------
-- Presents dropping

-- Drops `count` presents round the plaza (open floor, away from the tree). Returns them (tests).
function ChristmasService.drop(count: number?): { Model }
	local f = folder
	if not isOn or not f then
		return {}
	end
	dropNo += 1
	local no = dropNo
	opened[no] = {}
	opened[no - 2] = nil -- (its presents are long gone: GIFT_STAY < two drops apart)
	told[no - 2] = nil
	local middle = labOrigin + PLAZA_MIDDLE
	local rng = Random.new()
	local made: { Model } = {}
	for k = 1, count or ChristmasService.GIFTS do
		-- (Open floor: never in the tree or among its presents.)
		local treeAt = Vector3.new(middle.X + math.cos(math.rad(TREE_ANGLE)) * TREE_RADIUS, 0, middle.Z + math.sin(math.rad(TREE_ANGLE)) * TREE_RADIUS)
		local plazaFloor = floorAt(middle.X, middle.Z, middle.Y)
		local ang, x, z = 0, middle.X, middle.Z
		for _ = 1, 12 do
			ang = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(8, 34)
			x, z = middle.X + math.cos(ang) * r, middle.Z + math.sin(ang) * r
			-- (And on the open floor: not on the fountain, a bench, a sign or a lamp.)
			if (Vector3.new(x, 0, z) - treeAt).Magnitude > TREE_KEEP and math.abs(floorAt(x, z, middle.Y) - plazaFloor) < 0.3 then
				break
			end
		end
		local y = floorAt(x, z, middle.Y)
		local gift = present(f, CFrame.new(x, y + 30 + k * 2, z) * CFrame.Angles(0, ang, 0), 2, WRAPS[k % #WRAPS + 1], false)
		gift:SetAttribute("Drop", no)
		local box = gift.PrimaryPart :: BasePart
		box.CanTouch = true
		local done = false
		box.Touched:Connect(function(other: BasePart)
			if done then
				return
			end
			local character = other:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			ChristmasService.open(player, gift)
			done = gift.Parent == nil
		end)
		task.delay(ChristmasService.GIFT_STAY, function()
			if gift.Parent then
				gift:Destroy()
			end
		end)
		table.insert(made, gift)
	end
	FxService.gift(middle + Vector3.new(0, 4, 0))
	Workspace:SetAttribute("GiftDrop", no) -- (every screen says so: ChristmasFx)
	return made
end

-- A player opens a present: an egg, once per player per drop (a second one in the same drop just
-- pops). Returns whether it gave the egg.
function ChristmasService.open(player: Player, gift: Model): boolean
	local no = gift:GetAttribute("Drop")
	local who = if type(no) == "number" then opened[no] else nil
	if gift.Parent == nil or not who then
		return false
	end
	-- Someone who can't get an egg from it leaves it for the others (told why, once a drop).
	local why: string? = nil
	if who[player.UserId] then
		why = "You found this drop's egg already! Leave the rest for the others"
	else
		local room = ProgressService.eggRoom(player)
		if room == "full" then
			why = "Your egg slots are full: open some to make room"
		elseif room == "loading" then
			return false -- (a moment after joining: their progress is still being read)
		end
	end
	if why then
		local list = told[no :: number] or {}
		told[no :: number] = list
		if not list[player.UserId] then
			list[player.UserId] = true
			ProgressService.notice(player, why)
		end
		return false
	end
	if not ProgressService.giveEgg(player, "A present! An egg inside!") then
		return false
	end
	who[player.UserId] = true
	Metrics.event(player, "Xmas_PresentEgg")
	local box = gift.PrimaryPart
	local at = if box then box.Position else gift:GetPivot().Position
	gift:Destroy()
	FxService.gift(at)
	return true
end

-- The owner's troll menu (AdminService): a present falls on someone's head and pops. It holds
-- nothing (no Drop number: never an egg). Works with the theme on or off.
ChristmasService.PRANK_POP = 1.6 -- s after it is dropped
function ChristmasService.prank(at: Vector3): boolean
	local gift = present(Workspace, CFrame.new(at + Vector3.new(0, 14, 0)) * CFrame.Angles(0, math.random() * math.pi, 0), 2.4, WRAPS[math.random(1, #WRAPS)], false)
	gift.Name = "PrankPresent"
	task.delay(ChristmasService.PRANK_POP, function()
		if gift.Parent then
			local box = gift.PrimaryPart
			local where = if box then box.Position else gift:GetPivot().Position
			gift:Destroy()
			FxService.gift(where)
			FxService.hit(where + Vector3.new(0, 1, 0), 20, "BalloonPop")
		end
	end)
	return true
end

------------------------------------------------------------------------------------------------
-- On and off

local function apply()
	local date = ChristmasService.dateForTest or today()
	local on = Christmas.isOn(mode, date)
	Workspace:SetAttribute("ChristmasMode", mode)
	if on == isOn and (not on or folder ~= nil) then
		return
	end
	isOn = on
	Workspace:SetAttribute("Christmas", on)
	if on then
		dressPlaza()
	else
		local f = Workspace:FindFirstChild("Christmas")
		if f then
			f:Destroy()
		end
		folder = nil
	end
	dressAll(on)
	log.info("theme " .. (if on then "on" else "off") .. " (" .. mode .. ")")
end

function ChristmasService.isOn(): boolean
	return isOn
end

function ChristmasService.mode(): Christmas.Mode
	return mode
end

-- The owner's choice travels as a record { mode, at = server time it was made, from = the server
-- that made it }: the newest wins everywhere, whatever order messages come in, and a server never
-- takes back its own message. Kept in the DataStore; told to every server at once (MessagingService,
-- best effort) and read back from the store every CHECK_EVERY s, so a server that missed the
-- message still follows within a minute.
local modeAt = -1 -- (below any record: a choice kept as a plain word before records is still taken)
local function adopt(record: unknown): boolean
	local m, at = nil :: unknown, 0
	if type(record) == "table" then
		m, at = (record :: any).mode, tonumber((record :: any).at) or 0
	elseif type(record) == "string" then
		m = record -- (a choice kept before records: older than any)
	end
	if not Christmas.validMode(m) or at <= modeAt then
		return false
	end
	mode, modeAt = m :: Christmas.Mode, at
	apply()
	return true
end
ChristmasService.adoptForTest = adopt

-- Told when the owner's choice could not be kept (AdminService tells the owner).
ChristmasService.onSaveFailed = nil :: ((Christmas.Mode) -> ())?

-- The owner's switch (AdminService checks it is him): applied here at once, kept, told to every
-- server. Saving is tried three times; a failure is told (onSaveFailed).
function ChristmasService.setMode(newMode: unknown): boolean
	if not Christmas.validMode(newMode) then
		return false
	end
	local record = { mode = newMode, at = Workspace:GetServerTimeNow(), from = game.JobId }
	mode, modeAt = newMode :: Christmas.Mode, record.at
	apply()
	local s = store
	if s then
		task.spawn(function()
			local saved = false
			for attempt = 1, 3 do
				saved = pcall(function()
					s:UpdateAsync(KEY, function(old: any)
						-- (Never over a newer choice made elsewhere meanwhile.)
						if type(old) == "table" and (tonumber(old.at) or 0) > record.at then
							return nil
						end
						return record
					end)
				end)
				if saved or attempt == 3 then
					break
				end
				task.wait(2 ^ attempt)
			end
			if not saved then
				log.warn("could not keep the Christmas theme " .. tostring(record.mode))
				local tellOwner = ChristmasService.onSaveFailed
				if tellOwner then
					tellOwner(record.mode :: Christmas.Mode)
				end
			end
			pcall(function()
				MessagingService:PublishAsync(TOPIC, record)
			end)
		end)
	end
	return true
end

-- Tests: a date instead of today (nil: today again), applied at once.
function ChristmasService.setDateForTest(date: { year: number, month: number, day: number }?)
	ChristmasService.dateForTest = date
	apply()
end

function ChristmasService.start(origin: Vector3)
	labOrigin = origin
	DummyFactory.onSpawn = function(body: Model)
		if isOn then
			ChristmasService.dress(body)
		end
	end
	if ProgressService.usesDataStores() then
		local ok, s = pcall(function()
			return DataStoreService:GetDataStore(STORE)
		end)
		if ok and s then
			store = s
			local okGet, stored = pcall(function()
				return s:GetAsync(KEY)
			end)
			if okGet then
				adopt(stored)
			else
				log.warn("could not read the Christmas theme (the default until the next check)")
			end
			pcall(function()
				MessagingService:SubscribeAsync(TOPIC, function(message)
					local data = message.Data
					if type(data) == "table" and data.from ~= game.JobId then
						adopt(data)
					end
				end)
			end)
		end
	end
	apply()
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			-- The kept choice read back (a missed message is caught up), then the date.
			local s = store
			if s then
				local okGet, stored = pcall(function()
					return s:GetAsync(KEY)
				end)
				if okGet then
					adopt(stored)
				end
			end
			apply()
		end
	end)
	-- (Studio only: a drop on demand, for a look at it: ServerStorage "ChristmasDropForTest".)
	if RunService:IsStudio() then
		ServerStorage:GetAttributeChangedSignal("ChristmasDropForTest"):Connect(function()
			ChristmasService.drop()
		end)
	end
	-- Presents now and then while it is on (never during the self-tests: a box falling on a test
	-- body would be noise; T40 drops its own).
	task.spawn(function()
		while true do
			task.wait(ChristmasService.GIFT_EVERY)
			local testing = RunService:IsStudio() and ServerStorage:GetAttribute("RunSelfTest") == true
			if isOn and not testing and #Players:GetPlayers() > 0 then
				ChristmasService.drop()
			end
		end
	end)
end

return ChristmasService
