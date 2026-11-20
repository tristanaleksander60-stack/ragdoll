--!strict
-- V6-7: things to buy on the maps (Config.MAP_SHOP). Showcase booths on the plaza and the open-air
-- maps: a stone pedestal under a soft spotlight, the item turning slowly on it (the client spins
-- what is tagged BoothSpin), its name, a one-line pitch and the price, and two prompts:
--   TRY  60 s free (once per item per visit; attribute Try_<key> = server time it ends)
--   BUY  Roblox's own purchase prompt (Shop.OFFERS id; OfferService delivers it and keeps
--        Offer_<key> right on join and after a purchase). Id 0 = no booth live, TEST in Studio.
-- The effects, for an owner or a TRY:
--   RainbowTrail / FireTrail  a trail behind the player (fire: flames at the feet too)
--   CrashSuit                 the yellow and black crash-test look
--   GoldDummies               the player's lab dummies in gold
--   RobotDog                  a robot dog that follows the player
--   Parrot                    a macaw on the player's shoulder
--   MegaTrampoline            a giant trampoline in the player's lab (bodies and players bounce)
--   GiantFan                  a giant fan at the back of the lab blowing dummies forward
--   SpiderDeluxe              the lab's spider in gold, spitting farther (LabCreatures reads it)
--   BoltCrate                 a product: 500 BOLTS (OfferService's grant)
-- Everything is cosmetic or lab fun: nothing here hurts other players (no pay-to-win).

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Shop = require(Shared:WaitForChild("Shop")) :: any
local Places = require(Shared:WaitForChild("Places")) :: any
local Systems = script.Parent

local MapShopService = {}

MapShopService.TRY_SECONDS = 60
MapShopService.TICK = 0.25

local function lazy(name: string): any
	return require(Systems:WaitForChild(name)) :: any
end

local ITEMS: { any } = {}
local BY_KEY: { [string]: any } = {}
for _, o in Shop.OFFERS do
	if o.map then
		table.insert(ITEMS, o)
		BY_KEY[o.key] = o
	end
end
MapShopService.ITEMS = ITEMS

local tried: { [Player]: { [string]: boolean } } = {}

-- Whether the player has the item now (owned, or in a TRY).
function MapShopService.has(player: Player, key: string): boolean
	if player:GetAttribute("Offer_" .. key) == true then
		return true
	end
	local untilT = player:GetAttribute("Try_" .. key)
	return type(untilT) == "number" and untilT > Workspace:GetServerTimeNow()
end

local function sellable(o: any): boolean
	return (tonumber(o.id) or 0) > 0 or RunService:IsStudio()
end

------------------------------------------------------------------------------------------------
-- Booths

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

-- The model on the pedestal (about `size` studs at its longest).
local function showpiece(o: any, at: CFrame, size: number, into: Instance): Model?
	local m: Model
	local assets = ServerStorage:FindFirstChild("V3Assets")
	local src = assets and assets:FindFirstChild(o.show)
	if src and src:IsA("Model") then
		m = src:Clone()
	elseif o.show == "Suit" or o.show == "GoldDummy" or o.show == "Trail" or o.show == "Fire" then
		-- (A display mannequin: a copy of the dummies' own sculpted skin rig, never a live body.)
		local skin = game:GetService("ReplicatedStorage"):FindFirstChild("DummySkin")
		if not skin or not skin:IsA("Model") then
			return nil
		end
		m = skin:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") then
				d:Destroy()
			end
		end
		local colour = if o.show == "GoldDummy" then Color3.fromRGB(240, 196, 60) elseif o.show == "Suit" then Color3.fromRGB(250, 205, 40) else nil
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and colour then
				d.Color = if o.show == "Suit" and (string.find(d.Name, "Leg") or string.find(d.Name, "Foot") or string.find(d.Name, "Arm") or string.find(d.Name, "Hand")) then Color3.fromRGB(30, 30, 34) else colour
				if o.show == "GoldDummy" then
					d.Material = Enum.Material.Foil
				end
			end
		end
	else
		return nil
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local _, s = m:GetBoundingBox()
	local longest = math.max(s.X, s.Y, s.Z)
	if longest > 0 then
		m:ScaleTo(m:GetScale() * size / longest)
	end
	m:PivotTo(at)
	local cf, s2 = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, at.Position.Y - (cf.Position.Y - s2.Y / 2), 0))
	if o.show == "MSpider" then
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = Color3.fromRGB(230, 186, 60)
				d.Material = Enum.Material.Foil
			end
		end
	end
	if o.show == "Trail" or o.show == "Fire" then
		local torso = m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")
		if torso and torso:IsA("BasePart") then
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(0, 1, 0)
			a0.Parent = torso
			local fx = Instance.new("ParticleEmitter")
			fx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			fx.Color = if o.show == "Fire" then ColorSequence.new(Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 60, 30)) else ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 220, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 120, 255)) })
			fx.Rate = 30
			fx.Lifetime = NumberRange.new(1, 1.5)
			fx.Speed = NumberRange.new(2, 4)
			fx.Size = NumberSequence.new(0.6, 0)
			fx.Parent = a0
		end
	end
	CollectionService:AddTag(m, "BoothSpin")
	m.Parent = into
	return m
end

local function prompt(on: BasePart, action: string, object: string, key: Enum.KeyCode, order: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = key
	p.HoldDuration = 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.UIOffset = Vector2.new(0, order * 72)
	p.Parent = on
	return p
end

function MapShopService.buildBooth(o: any, at: CFrame, into: Instance): Model
	local booth = Instance.new("Model")
	booth.Name = "Booth_" .. o.key
	booth:SetAttribute("Offer", o.key)
	-- Pedestal: a round stone base, a dark top with a soft rim light, a spotlight from above.
	local base = part(booth, "Pedestal", Vector3.new(2.6, 7, 7), at * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(214, 210, 200), Enum.Material.Marble, Enum.PartType.Cylinder)
	local top = part(booth, "PedestalTop", Vector3.new(0.4, 7.6, 7.6), at * CFrame.new(0, 2.8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 42, 48), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local rim = part(booth, "PedestalRim", Vector3.new(0.15, 7.9, 7.9), at * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 196, 90), Enum.Material.Neon, Enum.PartType.Cylinder)
	rim.CanCollide = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 50
	light.Brightness = 2.2
	light.Range = 18
	light.Color = Color3.fromRGB(255, 236, 210)
	local lamp = part(booth, "BoothLamp", Vector3.new(1, 0.4, 1), at * CFrame.new(0, 14, 0), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
	lamp.CanCollide = false
	light.Parent = lamp
	showpiece(o, at * CFrame.new(0, 3, 0), if o.show == "MSpider" then 7 elseif o.show == "Trampoline" or o.show == "BigFan" or o.show == "Suit" or o.show == "GoldDummy" or o.show == "Trail" or o.show == "Fire" then 7 else 5, booth)
	-- The sign: name, pitch, price (fixed text from Shop.OFFERS; nobody types here).
	local sign = Instance.new("BillboardGui")
	sign.Name = "BoothSign"
	sign.Size = UDim2.fromScale(11, 4.3) -- (in studs: it shrinks with distance, so neighbours never overlap)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 11, 0)
	sign.MaxDistance = 70
	sign.Adornee = top
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
	card.BackgroundTransparency = 0.08
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 196, 90)
	stroke.Thickness = 1.5
	stroke.Parent = card
	local function line(text: string, y: number, h: number, size: number, color: Color3, weight: Enum.FontWeight)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.new(0.05, 0, y / 86, 0)
		t.Size = UDim2.new(0.9, 0, h / 86, 0)
		t.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", weight)
		t.TextScaled = true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = size
		cap.Parent = t
		t.TextColor3 = color
		t.TextWrapped = true
		t.Text = text
		t.Parent = card
	end
	line(string.upper(o.name), 6, 24, 20, Color3.fromRGB(255, 255, 255), Enum.FontWeight.Heavy)
	line(o.pitch or o.gives, 30, 30, 13, Color3.fromRGB(196, 202, 214), Enum.FontWeight.Medium)
	line(if (tonumber(o.id) or 0) > 0 then "\u{E002} " .. tostring(o.robux) else "TEST (no id yet) \u{E002} " .. tostring(o.robux), 60, 20, 16, Color3.fromRGB(120, 230, 140), Enum.FontWeight.Bold)
	card.Parent = sign
	sign.Parent = top
	local tryPrompt = if o.kind == "pass" then prompt(base, "Try 60 s free", o.name, Enum.KeyCode.T, 1) else nil
	local buyPrompt = prompt(base, "Buy", o.name, Enum.KeyCode.E, 0)
	buyPrompt.Triggered:Connect(function(player: Player)
		MapShopService.buy(player, o.key)
	end)
	if tryPrompt then
		tryPrompt.Triggered:Connect(function(player: Player)
			MapShopService.try(player, o.key)
		end)
	end
	booth.Parent = into
	return booth
end

-- Where the booths stand: a row by the plaza's front, a row by each open-air map's arrival.
local function spots(place: string, labOrigin: Vector3): Vector3?
	if place == "Plaza" then
		return labOrigin + Vector3.new(0, 0, 130) -- (in front of the plaza's boards and benches)
	end
	local ok, centre = pcall(function()
		return Places.floorCenter(labOrigin, place)
	end)
	local def = Places.byId and Places.byId[place]
	if ok and centre and def then
		return centre + Vector3.new(0, 0, (def.arrive or 100) - 34)
	end
	return nil
end

function MapShopService.build(labOrigin: Vector3)
	local root = Instance.new("Folder")
	root.Name = "MapBooths"
	local rows: { [string]: { any } } = {}
	for _, o in ITEMS do
		if sellable(o) then
			for _, place in o.places do
				rows[place] = rows[place] or {}
				table.insert(rows[place], o)
			end
		end
	end
	for place, list in rows do
		local at = spots(place, labOrigin)
		if at then
			local folder = Instance.new("Folder")
			folder.Name = place
			folder.Parent = root
			local gap = 16
			for i, o in list do
				local x = (i - (#list + 1) / 2) * gap
				local ground = Workspace:Raycast(at + Vector3.new(x, 120, 0), Vector3.new(0, -400, 0))
				local y = if ground then ground.Position.Y else at.Y
				-- (Facing the way players arrive: the sign reads from the front.)
				MapShopService.buildBooth(o, CFrame.new(at.X + x, y, at.Z), folder)
			end
		end
	end
	root.Parent = Workspace
	return root
end

------------------------------------------------------------------------------------------------
-- Try and buy

function MapShopService.try(player: Player, key: string): string?
	local o = BY_KEY[key]
	if not o or o.kind ~= "pass" then
		return "junk"
	end
	if player:GetAttribute("Offer_" .. key) == true then
		lazy("ProgressService").notice(player, "You own the " .. o.name .. " already!")
		return "owned"
	end
	local mine = tried[player] or {}
	tried[player] = mine
	if mine[key] then
		lazy("ProgressService").notice(player, "You tried the " .. o.name .. " this visit. Buy it to keep it!")
		return "tried"
	end
	mine[key] = true
	player:SetAttribute("Try_" .. key, Workspace:GetServerTimeNow() + MapShopService.TRY_SECONDS)
	lazy("ProgressService").notice(player, "60 seconds of the " .. o.name .. ": enjoy!")
	return nil
end

function MapShopService.buy(player: Player, key: string): string?
	local o = BY_KEY[key]
	if not o then
		return "junk"
	end
	if o.kind == "pass" and player:GetAttribute("Offer_" .. key) == true then
		lazy("ProgressService").notice(player, "You own the " .. o.name .. "!")
		return "owned"
	end
	local id = tonumber(o.id) or 0
	if id <= 0 then
		if RunService:IsStudio() then
			-- (Studio: a TEST purchase through the same delivery as the real one.)
			local OfferService = lazy("OfferService")
			if o.kind == "pass" then
				OfferService.grantPass(player, key)
			else
				OfferService.deliver(player, key, "studio-" .. tostring(os.clock()), true)
			end
			return "test"
		end
		return "noid"
	end
	if o.kind == "pass" then
		MarketplaceService:PromptGamePassPurchase(player, id)
	else
		MarketplaceService:PromptProductPurchase(player, id)
	end
	return nil
end

------------------------------------------------------------------------------------------------
-- Effects

type Fx = { trail: Instance?, fire: Instance?, suit: boolean, dog: Model?, parrot: Model?, tramp: Model?, fan: Model? }
local active: { [Player]: Fx } = {}

local function rootOf(p: Player): BasePart?
	local c = p.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

local function clone(name: string): Model?
	local assets = ServerStorage:FindFirstChild("V3Assets")
	local src = assets and assets:FindFirstChild(name)
	return if src and src:IsA("Model") then src:Clone() else nil
end

local function setTrail(p: Player, fx: Fx, on: boolean, fire: boolean)
	local slot = if fire then "fire" else "trail"
	local have = (fx :: any)[slot]
	if on and (not have or not have.Parent) then
		local r = rootOf(p)
		if not r then
			return
		end
		local holder = Instance.new("Folder")
		holder.Name = if fire then "FireTrail" else "RainbowTrail"
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1, 0)
		a0.Parent = r
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1, 0)
		a1.Parent = r
		local t = Instance.new("Trail")
		t.Attachment0 = a0
		t.Attachment1 = a1
		t.Lifetime = 0.6
		t.LightEmission = 0.4
		t.Color = if fire then ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 60, 20)) else ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 70)), ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 220, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255)) })
		t.Transparency = NumberSequence.new(0.2, 1)
		t.Parent = r
		if fire then
			local feet = Instance.new("Attachment")
			feet.Position = Vector3.new(0, -2.8, 0)
			feet.Parent = r
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/fire_main.dds"
			e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 70, 20))
			e.Size = NumberSequence.new(1.2, 0)
			e.Lifetime = NumberRange.new(0.4, 0.7)
			e.Speed = NumberRange.new(2, 4)
			e.Rate = 24
			e.LightEmission = 0.6
			e.Parent = feet
			holder:SetAttribute("Feet", true)
			local ref = Instance.new("ObjectValue")
			ref.Value = feet
			ref.Parent = holder
		end
		for _, x in { a0, a1, t } do
			local ref = Instance.new("ObjectValue")
			ref.Value = x
			ref.Parent = holder
		end
		holder.Parent = r
		;(fx :: any)[slot] = holder
	elseif not on and have then
		for _, ref in have:GetChildren() do
			if ref:IsA("ObjectValue") and ref.Value then
				ref.Value:Destroy()
			end
		end
		have:Destroy()
		;(fx :: any)[slot] = nil
	end
end

local SUIT_YELLOW = Color3.fromRGB(250, 205, 40)
local SUIT_BLACK = Color3.fromRGB(30, 30, 34)
local function setSuit(p: Player, fx: Fx, on: boolean)
	local c = p.Character
	if not c or fx.suit == on then
		return
	end
	fx.suit = on
	for _, d in c:GetChildren() do
		if d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			if on then
				-- (Kept in a folder on the body, put back when the suit comes off.)
				local keep = c:FindFirstChild("SuitClothes") or Instance.new("Folder")
				keep.Name = "SuitClothes"
				keep.Parent = c
				d.Parent = keep
			end
		end
	end
	local keep = c:FindFirstChild("SuitClothes")
	if not on and keep then
		for _, cl in keep:GetChildren() do
			cl.Parent = c
		end
		keep:Destroy()
	end
	for _, d in c:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			if on then
				d:SetAttribute("SuitColor", d.Color)
				d.Color = if string.find(d.Name, "Leg") or string.find(d.Name, "Foot") or string.find(d.Name, "Hand") then SUIT_BLACK elseif d.Name == "Head" then d.Color else SUIT_YELLOW
			else
				local was = d:GetAttribute("SuitColor")
				if typeof(was) == "Color3" then
					d.Color = was
				end
			end
		end
	end
end

local function labFolderOf(p: Player): Instance?
	local pg = Workspace:FindFirstChild("Playground")
	local Lab = lazy("Lab")
	for _, f in if pg then pg:GetChildren() else {} do
		local pad = f:FindFirstChild("CannonPad")
		if pad and pad:IsA("BasePart") and Lab.ownerAt(pad.Position) == p then
			return f
		end
	end
	return nil
end

local function setPet(p: Player, fx: Fx, which: string, on: boolean)
	local have: Model? = if which == "dog" then fx.dog else fx.parrot
	if on and (not have or not have.Parent) then
		local m = clone(if which == "dog" then "PetRobotDog" else "PetParrot")
		if not m then
			return
		end
		local _, s = m:GetBoundingBox()
		local want = if which == "dog" then 3.4 else 1.6
		m:ScaleTo(m:GetScale() * want / math.max(s.X, s.Y, s.Z))
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.Massless = true
			end
		end
		m.Name = if which == "dog" then "PetRobotDog" else "PetParrot"
		m.Parent = Workspace
		if which == "dog" then
			fx.dog = m
		else
			fx.parrot = m
		end
	elseif not on and have then
		have:Destroy()
		if which == "dog" then
			fx.dog = nil
		else
			fx.parrot = nil
		end
	end
end

local function setLabThing(p: Player, fx: Fx, which: string, on: boolean)
	local have: Model? = if which == "tramp" then fx.tramp else fx.fan
	if on and (not have or not have.Parent) then
		local lab = labFolderOf(p)
		local pad = lab and lab:FindFirstChild("CannonPad")
		if not lab or not pad or not pad:IsA("BasePart") then
			return
		end
		local origin = pad.Position - Vector3.new(48, 0.5, 6) -- (the lab's origin, from its cannon pad)
		local m = clone(if which == "tramp" then "Trampoline" else "BigFan")
		if not m then
			return
		end
		local at = if which == "tramp" then CFrame.new(origin + Vector3.new(0, 0, 108)) else CFrame.new(origin + Vector3.new(0, 0, -84))
		local _, s = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * (if which == "tramp" then 16 else 14) / math.max(s.X, s.Y, s.Z))
		m:PivotTo(at)
		local cf, s2 = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(0, at.Position.Y - (cf.Position.Y - s2.Y / 2), 0))
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanTouch = false
			elseif d:IsA("LuaSourceContainer") then
				d:Destroy()
			end
		end
		m.Name = if which == "tramp" then "MegaTrampoline" else "GiantFan"
		m:SetAttribute("Owner", p.UserId)
		m.Parent = lab
		if which == "tramp" then
			fx.tramp = m
		else
			fx.fan = m
		end
	elseif not on and have then
		have:Destroy()
		if which == "tramp" then
			fx.tramp = nil
		else
			fx.fan = nil
		end
	end
end

local GOLD = Color3.fromRGB(240, 196, 60)
local function goldDummies(p: Player, on: boolean)
	local ok, list = pcall(function()
		return lazy("Lab").dummiesOf(p)
	end)
	for _, m in if ok then list else {} do
		local is = m:GetAttribute("Gold") == true
		if on and not is then
			m:SetAttribute("Gold", true)
			for _, d in m:GetChildren() do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
					d:SetAttribute("GoldWas", d.Color)
					d.Color = GOLD
				end
			end
		elseif not on and is then
			m:SetAttribute("Gold", nil)
			for _, d in m:GetChildren() do
				local was = d:GetAttribute("GoldWas")
				if d:IsA("BasePart") and typeof(was) == "Color3" then
					d.Color = was
				end
			end
		end
	end
end

-- Bodies and players on the trampoline bounce; in front of the fan they are blown forward.
local function labMachines(p: Player, fx: Fx)
	local folder = Workspace:FindFirstChild("Dummies")
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local DummyControl = lazy("DummyControl")
	local function bodies(cf: CFrame, size: Vector3): { Model }
		params.FilterDescendantsInstances = if folder then { folder } else {}
		local seen, out = {}, {}
		for _, part in Workspace:GetPartBoundsInBox(cf, size, params) do
			local m = part:FindFirstAncestorOfClass("Model")
			while m and m.Parent ~= folder do
				m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") or nil
			end
			if m and not seen[m] and m:GetAttribute("InMachine") == nil then
				seen[m] = true
				table.insert(out, m)
			end
		end
		return out
	end
	local t = fx.tramp
	if t and t.Parent then
		local cf, s = t:GetBoundingBox()
		local top = cf * CFrame.new(0, s.Y / 2 + 2, 0)
		for _, m in bodies(top, Vector3.new(s.X, 5, s.Z)) do
			DummyControl.push(m, Vector3.new(0, 140, 0), p)
		end
		for _, pl in Players:GetPlayers() do
			local r = rootOf(pl)
			if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(cf.Position.X, 0, cf.Position.Z)).Magnitude < s.X / 2 and math.abs(r.Position.Y - top.Position.Y) < 4 then
				pcall(function()
					lazy("PlayerRagdoll").launch(pl, Vector3.new(0, 160, 0))
				end)
			end
		end
	end
	local f = fx.fan
	if f and f.Parent then
		local cf = f:GetPivot()
		local blowAt = CFrame.new(cf.Position + Vector3.new(0, 5, 30))
		for _, m in bodies(blowAt, Vector3.new(30, 10, 50)) do
			DummyControl.nudge(m, Vector3.new(0, 8, 26))
		end
	end
end

local function step(p: Player)
	local fx = active[p]
	if not fx then
		fx = { trail = nil, fire = nil, suit = false, dog = nil, parrot = nil, tramp = nil, fan = nil }
		active[p] = fx
	end
	local f = fx :: Fx
	setTrail(p, f, MapShopService.has(p, "RainbowTrail"), false)
	setTrail(p, f, MapShopService.has(p, "FireTrail"), true)
	setSuit(p, f, MapShopService.has(p, "CrashSuit"))
	setPet(p, f, "dog", MapShopService.has(p, "RobotDog"))
	setPet(p, f, "parrot", MapShopService.has(p, "Parrot"))
	setLabThing(p, f, "tramp", MapShopService.has(p, "MegaTrampoline"))
	setLabThing(p, f, "fan", MapShopService.has(p, "GiantFan"))
	goldDummies(p, MapShopService.has(p, "GoldDummies"))
	local lab = labFolderOf(p)
	if lab then
		lab:SetAttribute("SpiderDeluxe", if MapShopService.has(p, "SpiderDeluxe") then true else nil)
	end
	labMachines(p, f)
	end

-- Pets follow (15 times a second: smooth): the dog trots behind, the parrot rides the shoulder.
local function petStep(p: Player)
	local f = active[p]
	local r = rootOf(p)
	if f and r then
		if f.dog and f.dog.Parent then
			local want = r.CFrame * CFrame.new(3, -1.4, 4)
			local now = f.dog:GetPivot()
			local pos = now.Position:Lerp(want.Position, 0.35)
			local ground = Workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0))
			local y = if ground then ground.Position.Y + 0.1 else pos.Y
			f.dog:PivotTo(CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(r.Position.X, y, r.Position.Z)))
		end
		if f.parrot and f.parrot.Parent then
			f.parrot:PivotTo(r.CFrame * CFrame.new(1.4, 1.9, 0))
		end
	end
end

function MapShopService.start(labOrigin: Vector3)
	if not Config.MAP_SHOP then
		return
	end
	task.spawn(function()
		while true do
			task.wait(1 / 15)
			for _, p in Players:GetPlayers() do
				pcall(petStep, p)
			end
		end
	end)
	task.delay(8, MapShopService.build, labOrigin) -- (after the open-air maps are built: booths stand on their ground)
	Players.PlayerRemoving:Connect(function(p)
		local fx = active[p]
		if fx then
			for _, m in { fx.dog, fx.parrot, fx.tramp, fx.fan } do
				if m then
					m:Destroy()
				end
			end
		end
		active[p] = nil
		tried[p] = nil
	end)
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			local fx = active[p]
			if fx then
				fx.trail, fx.fire, fx.suit = nil, nil, false -- (a new body gets them again)
			end
		end)
	end)
	for _, p in Players:GetPlayers() do
		p.CharacterAdded:Connect(function()
			local fx = active[p]
			if fx then
				fx.trail, fx.fire, fx.suit = nil, nil, false
			end
		end)
	end
	task.spawn(function()
		while true do
			task.wait(MapShopService.TICK)
			for _, p in Players:GetPlayers() do
				local ok, err = pcall(step, p)
				if not ok then
					warn("[MapShop] " .. tostring(err))
				end
			end
		end
	end)
end

function MapShopService.resetForTest(p: Player)
	tried[p] = nil
	for _, o in ITEMS do
		p:SetAttribute("Try_" .. o.key, nil)
	end
end

return MapShopService
