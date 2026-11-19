--!strict
-- Round 5, phase 1: the HUD like the big ragdoll games (the owner's screenshots).
--   WEAPONS      a big red button under the chaos meter (HudSlots "Weapons"): the next weapon's
--                picture, "Next: Revolver 3/5" and a bar; it opens WEAPONS (T). It carries the play
--                gift's clock (GiftClock: PokeController.weaponsHud) and replaces the bar's gold line.
--   LEVEL        a round level badge at the tool bar's top-left corner and a thin XP line along its
--                top edge (Shared/Level: takedowns and minutes played; no new economy)
--   TODAY'S DEAL the Starter Pack card with a clock to midnight UTC (off a phone; SOON until the
--                owner makes the product: Shop.STARTER_PACK)
--   SANDBOX      1ST PERSON (V), SLOW-MO (Z), REVIVE ALL (X), RESET (Delete) under RAGDOLL, off a
--                phone (SandboxService on the server; RESET also sweeps the props: CleanUp)
--   key hints    on the left column's launchers with a keyboard (SHOP Y, REWARDS J, PLACES M,
--                SANDBOX B), and a SETTINGS launcher

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Shop = require(Shared:WaitForChild("Shop"))
local Level = require(Shared:WaitForChild("Level"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local HudSlots = require(Client:WaitForChild("HudSlots"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local PokeController = require(Client:WaitForChild("PokeController"))
local ToolPicture = require(Client:WaitForChild("ToolPicture"))
local NextUnlocks = require(Client:WaitForChild("NextUnlocks"))
local ProgressUI = require(Client:WaitForChild("ProgressUI"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local FirstPerson = require(Client:WaitForChild("FirstPerson"))

local HudPlus = {}

local P = Theme.Palette
local LEVEL_BADGE = 30 -- px, UI v2 (22 before): its number draws 14 px or more
HudPlus.LEVEL_BADGE = if KitStyle.V2 then LEVEL_BADGE else 22
local RED = Color3.fromRGB(214, 40, 48)
local RED_DARK = Color3.fromRGB(120, 16, 22)
local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local weapons: Frame? = nil
local nextPicture: Frame? = nil
local nextPictureId: string? = nil
local nextText: TextLabel? = nil
local nextFill: Frame? = nil
local deal: Frame? = nil
local dealClock: TextLabel? = nil
local sandbox: { [string]: TextButton } = {}
local levelGui: ScreenGui? = nil
local levelText: TextLabel? = nil
local xpFill: Frame? = nil
local xpTrack: Frame? = nil
local lastState: any = nil
local stateAt = os.clock()

local function stroke(parent: Instance, thickness: number, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or Color3.fromRGB(8, 8, 12)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function round(parent: Instance, r: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = r
	c.Parent = parent
end

local function label(parent: Instance, text: string, position: UDim2, size: UDim2, font: Font?, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = position
	l.Size = size
	l.Text = text
	l.TextScaled = true
	l.FontFace = font or Theme.Fonts.display
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextXAlignment = Enum.TextXAlignment.Left
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Color3.fromRGB(8, 8, 12)
	s.Parent = l
	l.Parent = parent
	return l
end

local function keyChip(parent: GuiObject, text: string?, at: UDim2?)
	-- lihfolk-ignore: findfirstchild-chain (the result is nil-checked before use)
	local chip = parent:FindFirstChild("KeyChip") :: TextLabel?
	if not chip then
		local k = Instance.new("TextLabel")
		k.Name = "KeyChip"
		k.AnchorPoint = Vector2.new(0.5, 0.5)
		k.Position = at or UDim2.fromOffset(6, 5)
		k.Size = UDim2.fromOffset(20, 18)
		k.BackgroundColor3 = P.ink
		k.TextColor3 = P.textHi
		k.FontFace = Theme.Fonts.display
		k.TextSize = 12
		k.ZIndex = 21
		round(k, UDim.new(0, 5))
		stroke(k, 1.5, Color3.fromRGB(230, 230, 240))
		k.Parent = parent
		chip = k
	end
	local c = chip :: TextLabel
	c.Visible = text ~= nil
	c.Text = text or ""
end

local function keyboard(): boolean
	return UserInputService.KeyboardEnabled and not ViewMode.isTouch()
end

local function keyText(id: string): string?
	if not keyboard() then
		return nil
	end
	local ok, text = pcall(Keybinds.labelOf, id)
	return if ok and type(text) == "string" and #text <= 3 then text else nil
end

------------------------------------------------------------------------------------------------
-- WEAPONS

-- What the button says from the takedowns (the next weapon on the ladder and how far to it).
function HudPlus.nextOf(takedowns: number): (Toys.Toy?, number, number)
	local prev, nextToy = 0, nil :: Toys.Toy?
	for _, toy in Toys.list do
		local at = toy.unlockAt
		if at > 0 then
			if at <= takedowns then
				prev = math.max(prev, at)
			elseif not nextToy or at < nextToy.unlockAt then
				nextToy = toy
			end
		end
	end
	return nextToy, prev, if nextToy then nextToy.unlockAt else prev
end

-- Round 5 (the owner: a better "next weapon"): the next weapon worth chasing, not the next rung.
-- Guns, explosives and the big ones count; a small hand move (Poke, Slap) or something already
-- yours (an egg, a purchase) is skipped. The bar fills from your last such unlock to it, and the
-- line says plainly how many kills are left; the last few make the button pulse.
local function ownedNow(): { [string]: boolean }
	local set = {}
	local raw = player:GetAttribute("Owned")
	if type(raw) == "string" then
		for id in string.gmatch(raw, "[^,]+") do
			set[id] = true
		end
	end
	return set
end

local function exciting(toy: Toys.Toy): boolean
	return toy.category == "Guns" or toy.category == "Explosives" or toy.big
end

function HudPlus.goalOf(takedowns: number, owned: { [string]: boolean }): (Toys.Toy?, number)
	local best: Toys.Toy? = nil
	local from = 0
	for _, toy in Toys.list do
		if toy.unlockAt > 0 and exciting(toy) then
			if toy.unlockAt <= takedowns or owned[toy.id] then
				if toy.unlockAt <= takedowns then
					from = math.max(from, toy.unlockAt)
				end
			elseif not best or toy.unlockAt < best.unlockAt then
				best = toy
			end
		end
	end
	return best, from
end

local lastGoal: string? = nil
local function drawWeapons(takedowns: number)
	NextUnlocks.setState(takedowns, ownedNow()) -- (the bar's three locked cards: round 5)
	local toy, from = HudPlus.goalOf(takedowns, ownedNow())
	local t, fill = nextText, nextFill
	-- lihfolk-ignore: findfirstchild-chain (nil-checked below)
	local title = weapons and weapons:FindFirstChild("Title") :: TextLabel?
	local left = if toy then math.max(1, toy.unlockAt - takedowns) else 0
	if title then
		title.Text = if toy then "NEXT: " .. string.upper(toy.short) else "WEAPONS"
		title.TextColor3 = if toy then Color3.fromRGB(255, 226, 120) else Color3.new(1, 1, 1)
	end
	if t then
		t.Text = if toy then string.format("%d kill%s to go!", left, if left == 1 then "" else "s") else "Every weapon is yours!"
	end
	if fill then
		local k = if toy then math.clamp((takedowns - from) / math.max(1, toy.unlockAt - from), 0, 1) else 1
		TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(k, 1) }):Play()
	end
	-- Close: the button breathes. A new goal (the last one unlocked): a pop.
	local w = weapons
	if w then
		-- lihfolk-ignore: findfirstchild-chain (made when missing, just below)
		-- (The button's one UIScale, whoever made it: KitStyle's press shares it.)
		local scale = w:FindFirstChildOfClass("UIScale")
		if not scale then
			local s = Instance.new("UIScale")
			s.Name = "Pulse"
			s.Parent = w
			scale = s
		end
		local id = if toy then toy.id else nil
		if lastGoal ~= nil and id ~= lastGoal then
			(scale :: UIScale).Scale = 1.15
			TweenService:Create(scale :: UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			C.playSound("reward")
		end
		lastGoal = id
		w:SetAttribute("Close", toy ~= nil and left <= 3)
	end
	local holder = nextPicture
	local id = if toy then toy.id else "GoldenDeagle"
	if holder and id ~= nextPictureId then
		nextPictureId = id
		holder:ClearAllChildren()
		local pic = ToolPicture.make(id, UDim2.fromScale(1, 1))
		pic.Parent = holder
	end
end

local function buildWeapons(parent: ScreenGui)
	local b = Instance.new("TextButton")
	b.Name = "WeaponsBig"
	b.Text = ""
	b.AutoButtonColor = true
	b.BackgroundColor3 = RED
	round(b, UDim.new(0, 12))
	stroke(b, 3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190))
	g.Rotation = 90
	g.Parent = b
	local pic = Instance.new("Frame")
	pic.Name = "Next"
	pic.BackgroundColor3 = RED_DARK
	pic.AnchorPoint = Vector2.new(0, 0.5)
	pic.Position = UDim2.new(0, 5, 0.5, 0)
	pic.Size = UDim2.fromOffset(48, 48) -- (fit: the button's height less a margin)
	round(pic, UDim.new(0, 8))
	pic.Parent = b
	nextPicture = pic
	label(b, "WEAPONS", UDim2.new(0, 0, 0.06, 0), UDim2.new(1, 0, 0.4, 0)).Name = "Title"
	nextText = label(b, "", UDim2.new(0, 0, 0.46, 0), UDim2.new(1, 0, 0.27, 0), Theme.Fonts.display, Color3.new(1, 1, 1))
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = RED_DARK
	track.Position = UDim2.new(0, 0, 0.76, 0)
	track.Size = UDim2.new(1, 0, 0.14, 0)
	round(track, UDim.new(1, 0))
	stroke(track, 1)
	local f = Instance.new("Frame")
	f.Name = "Fill"
	f.BackgroundColor3 = Color3.fromRGB(255, 214, 74)
	f.Size = UDim2.fromScale(0, 1)
	round(f, UDim.new(1, 0))
	f.Parent = track
	track.Parent = b
	nextFill = f
	-- The text column sits right of the square picture (its width = the button's height).
	local function fit()
		local h = b.AbsoluteSize.Y
		pic.Size = UDim2.fromOffset(math.max(10, h - 10), math.max(10, h - 10))
		for _, name in { "Title", "Track" } do
			-- lihfolk-ignore: findfirstchild-chain (the result is nil-checked before use)
			local o = b:FindFirstChild(name) :: GuiObject?
			if o then
				o.Position = UDim2.new(0, h + 2, o.Position.Y.Scale, 0)
				o.Size = UDim2.new(1, -(h + 10), o.Size.Y.Scale, 0)
			end
		end
		local t = nextText
		if t then
			t.Position = UDim2.new(0, h + 2, t.Position.Y.Scale, 0)
			t.Size = UDim2.new(1, -(h + 10), t.Size.Y.Scale, 0)
		end
	end
	b:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	b.Activated:Connect(function()
		PokeController.openCatalog()
	end)
	KitStyle.press(b) -- (UI v2: squish and click)
	b.Parent = parent
	weapons = b :: any
	task.defer(fit)
	-- The gift clock's tag (GiftClock: the same calls as a kit launcher's).
	local api = {
		root = b,
		setTag = function(text: string?)
			-- lihfolk-ignore: findfirstchild-chain (the result is nil-checked before use)
			local tag = b:FindFirstChild("Tag") :: TextLabel?
			if not tag then
				local t = Instance.new("TextLabel")
				t.Name = "Tag"
				t.AnchorPoint = Vector2.new(1, 0.5)
				t.Position = UDim2.new(1, -8, 0, 0)
				t.Size = UDim2.fromOffset(if KitStyle.V2 then 82 else 72, if KitStyle.V2 then 18 else 15)
				t.BackgroundColor3 = P.gold
				t.TextColor3 = P.ink
				t.FontFace = Theme.Fonts.display
				t.TextSize = if KitStyle.V2 then 14 else 13
				t.ZIndex = 21
				round(t, UDim.new(1, 0))
				stroke(t, 1.5)
				t.Parent = b
				tag = t
			end
			local l = tag :: TextLabel
			l.Visible = text ~= nil
			l.Text = text or ""
		end,
		setBadge = function(_on: boolean) end,
		setCaption = function(_text: string?) end,
	}
	PokeController.weaponsHud = api
end

------------------------------------------------------------------------------------------------
-- TODAY'S DEAL

local function secondsToMidnight(): number
	local now = os.time()
	return 86400 - (now % 86400)
end

local function buildDeal(parent: ScreenGui)
	local f = Instance.new("TextButton")
	f.Name = "Deal"
	f.Text = ""
	f.AutoButtonColor = true
	f.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
	round(f, UDim.new(0, 10))
	stroke(f, 2.5, Color3.fromRGB(255, 210, 74))
	local pic = ToolPicture.make("Revolver", UDim2.fromOffset(44, 44))
	pic.AnchorPoint = Vector2.new(0, 0.5)
	pic.Position = UDim2.new(0, 5, 0.5, 0)
	pic.Parent = f
	label(f, "TODAY'S DEAL", UDim2.fromOffset(54, 4), UDim2.new(1, -60, 0, 16), Theme.Fonts.display, Color3.fromRGB(255, 210, 74))
	label(f, "Starter Pack", UDim2.fromOffset(54, 21), UDim2.fromOffset(86, 15), Theme.Fonts.body)
	dealClock = label(f, "", UDim2.fromOffset(54, 37), UDim2.fromOffset(86, 13), Theme.Fonts.body, P.textMid)
	local price = label(f, if Shop.STARTER_PACK ~= 0 then string.format("R$%d", Shop.STARTER_PACK_ROBUX) else "SOON", UDim2.new(1, -54, 0, 24), UDim2.fromOffset(48, 24))
	price.Name = "Price"
	price.TextXAlignment = Enum.TextXAlignment.Center
	price.BackgroundTransparency = 0
	price.BackgroundColor3 = if Shop.STARTER_PACK ~= 0 then Color3.fromRGB(40, 170, 80) else Color3.fromRGB(90, 90, 100)
	round(price, UDim.new(0, 8))
	f.Activated:Connect(function()
		Net.event(Net.Names.Rewards):FireServer("BuyDeal")
	end)
	f.Parent = parent
	deal = f :: any
end

------------------------------------------------------------------------------------------------
-- SANDBOX

local SANDBOX_TEXT = { FirstPerson = "1ST PERSON", SlowMo = "SLOW-MO", Revive = "REVIVE ALL", Reset = "RESET" }
local SANDBOX_KEY = { FirstPerson = "FirstPerson", SlowMo = "SlowMo", Revive = "ReviveAll", Reset = "CleanUp" }

function HudPlus.sandbox(name: string)
	if name == "FirstPerson" then
		FirstPerson.toggle()
	elseif name == "SlowMo" then
		Net.event(Net.Names.Sandbox):FireServer("SlowMo")
	elseif name == "Revive" then
		Net.event(Net.Names.Sandbox):FireServer("Revive")
	elseif name == "Reset" then
		Net.event(Net.Names.CleanUp):FireServer()
		Net.event(Net.Names.Sandbox):FireServer("Reset")
	end
end

local function buildSandbox(parent: ScreenGui)
	for _, name in HudSlots.SANDBOX do
		local b = Instance.new("TextButton")
		b.Name = name
		b.Text = SANDBOX_TEXT[name]
		b.TextScaled = true
		b.FontFace = Theme.Fonts.display
		b.TextColor3 = Color3.new(1, 1, 1)
		b.BackgroundColor3 = Color3.fromRGB(44, 48, 64)
		b.AutoButtonColor = true
		round(b, UDim.new(0, 10))
		stroke(b, 2)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 26) -- (room for the key chip at the left)
		pad.PaddingRight = UDim.new(0, 6)
		pad.PaddingTop = UDim.new(0, 10)
		pad.PaddingBottom = UDim.new(0, 10)
		pad.Parent = b
		local ts = Instance.new("UIStroke")
		ts.Thickness = 1.5
		ts.Color = Color3.fromRGB(8, 8, 12)
		ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		ts.Parent = b
		b.Activated:Connect(function()
			HudPlus.sandbox(name)
		end)
		if KitStyle.V2 then
			-- (UI v2: the HUD's slab colour lit from above, the press squish and a click.)
			b.BackgroundColor3 = KitStyle.SLAB
			round(b, UDim.new(0, Theme.Radius.button))
			KitStyle.fit(b, 18, 11) -- (PC-only column keeps the old floor, so "SLOW-MO" is not cut)
			KitStyle.press(b)
		end
		b.Parent = parent
		sandbox[name] = b
	end
	FirstPerson.onChanged(function(on: boolean)
		local b = sandbox.FirstPerson
		if b then
			b.BackgroundColor3 = if KitStyle.V2 then (if on then KitStyle.GO else KitStyle.SLAB)
				elseif on then Color3.fromRGB(40, 150, 80)
				else Color3.fromRGB(44, 48, 64)
		end
	end)
end

------------------------------------------------------------------------------------------------
-- LEVEL

local function buildLevel()
	local g = Instance.new("ScreenGui")
	g.Name = "Level"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 4
	local track = Instance.new("Frame")
	track.Name = "XP"
	track.BackgroundColor3 = Color3.fromRGB(20, 18, 34)
	track.BackgroundTransparency = 0.5
	track.Size = UDim2.fromOffset(100, 3)
	round(track, UDim.new(1, 0))
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(90, 200, 255)
	fill.Size = UDim2.fromScale(0, 1)
	round(fill, UDim.new(1, 0))
	fill.Parent = track
	track.Parent = g
	local circle = Instance.new("Frame")
	circle.Name = "Badge"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	-- (The owner, 10 Nov: the level quiet and small; focus on the game.)
	circle.Size = UDim2.fromOffset(22, 22)
	circle.BackgroundColor3 = Color3.fromRGB(40, 110, 220)
	circle.BackgroundTransparency = 0.25
	round(circle, UDim.new(1, 0))
	stroke(circle, 1.5, Color3.fromRGB(200, 215, 240))
	local text = label(circle, "1", UDim2.fromScale(0.1, 0.18), UDim2.fromScale(0.8, 0.64))
	text.TextXAlignment = Enum.TextXAlignment.Center
	if KitStyle.V2 then
		-- (UI v2: still small and quiet, but its number draws 14 px or more: a 30 px solid badge in
		-- the kit's info blue, an ink edge, and a thicker XP line.)
		circle.Size = UDim2.fromOffset(LEVEL_BADGE, LEVEL_BADGE)
		circle.BackgroundColor3 = Theme.role("info").bottom
		circle.BackgroundTransparency = 0
		local edge = circle:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Color = P.ink
			edge.Thickness = 2
		end
		text.Position = UDim2.fromScale(0.08, 0.12)
		text.Size = UDim2.fromScale(0.84, 0.76)
		KitStyle.fit(text, 20, 14)
		track.Size = UDim2.fromOffset(100, 5)
		track.BackgroundTransparency = 0.25
		fill.BackgroundColor3 = Theme.role("info").top
	end
	circle.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	levelGui = g
	levelText = text
	xpFill = fill
	xpTrack = track
end

local function drawLevel()
	local s = lastState
	if not s then
		return
	end
	local played = (s.playSeconds or 0) + (os.clock() - stateAt)
	local n, into, span = Level.of(Level.xp(s.takedowns or 0, played))
	local t, f = levelText, xpFill
	if t and t.Text ~= tostring(n) then
		if KitStyle.V2 then
			KitStyle.countUp(t, n) -- (UI v2: it counts and pops, still silent)
		else
			t.Text = tostring(n) -- (a level up is silent now: the owner wants the game in front)
		end
	end
	if f then
		f.Size = UDim2.fromScale(math.clamp(into / math.max(1, span), 0, 1), 1)
	end
end

-- Follows the tool bar (it moves with the view and the screen): the badge on its top-left corner,
-- the XP line along its top edge.
local function followBar()
	local lg = levelGui
	if not lg then
		return
	end
	local pg = player:FindFirstChild("PlayerGui")
	local barGui = pg and pg:FindFirstChild("ToyBar")
	local bar = barGui and barGui:FindFirstChild("Bar")
	local shown = bar ~= nil and bar:IsA("GuiObject") and barGui:IsA("ScreenGui") and barGui.Enabled and bar.Visible and bar.AbsoluteSize.X > 0
	-- (UI v2: a phone's first QUIET_START s show at most seven things: the level waits.)
	if KitStyle.V2 and shown and time() < Config.QUIET_START and HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()).phone then
		shown = false
	end
	lg.Enabled = shown
	if not shown or not bar or not bar:IsA("GuiObject") then
		return
	end
	local at, size = bar.AbsolutePosition, bar.AbsoluteSize
	-- lihfolk-ignore: findfirstchild-chain (the result is nil-checked before use)
	local circle = lg:FindFirstChild("Badge") :: Frame?
	if circle then
		circle.Position = UDim2.fromOffset(at.X + 4, at.Y - 2)
	end
	local track = xpTrack
	if track then
		local thick = if KitStyle.V2 then 5 else 3
		track.Position = UDim2.fromOffset(at.X + (if KitStyle.V2 then 22 else 18), at.Y - 2 - thick)
		track.Size = UDim2.fromOffset(math.clamp(size.X * 0.15, 40, 110), thick)
	end
end

------------------------------------------------------------------------------------------------

local function place()
	local touch = ViewMode.isTouch()
	local ctx = HudSlots.context(touch, ViewMode.isLab())
	local w = weapons
	if w then
		HudSlots.apply(w, "Weapons", ctx)
	end
	local d = deal
	if d then
		HudSlots.apply(d, "Deal", ctx)
	end
	for name, b in sandbox do
		HudSlots.apply(b, name, ctx)
	end
end

local function refresh()
	local first = PokeController.firstMinute()
	local touch = ViewMode.isTouch()
	local phone = HudSlots.context(touch, ViewMode.isLab()).phone
	-- (Like the packs: not while building, not in Streamer Mode; nothing in doctor mode.)
	local busy = player:GetAttribute("Building") == true or player:GetAttribute("Streamer") == true
	local w = weapons
	if w then
		w.Visible = not first and not PokeController.isDoctor() and not PokeController.isPicking()
			and not (phone and Config.PHONE_HUD_MAX7) -- (phase 1: the experiment card's place on a phone)
		keyChip(w, keyText("Catalog"), UDim2.fromOffset(8, 6))
	end
	local d = deal
	if d then
		-- (Phase 0: no "SOON" card for a product that does not exist yet: Shop.STARTER_PACK 0 hides it.)
		d.Visible = Shop.STARTER_PACK ~= 0 and not phone and not first and not busy
	end
	for name, b in sandbox do
		b.Visible = not touch and not first and not busy
		keyChip(b, keyText(SANDBOX_KEY[name]), UDim2.new(0, -13, 0.5, 0)) -- (inside the padding: 13 px from the edge)
	end
	-- The left column's launchers: their keys, with a keyboard.
	local layer = Controller.getGui()
	if layer then
		for labelName, keyId in { Shop = "Shop", Places = "Places", Sandbox = "Build", Rewards = "Rewards" } do
			local tile = layer:FindFirstChild("Hud_" .. labelName, true)
			if tile and tile:IsA("GuiObject") then
				keyChip(tile, keyText(keyId))
			end
		end
	end
end

function HudPlus.start()
	local g = Instance.new("ScreenGui")
	g.Name = "HudPlus"
	g.ResetOnSpawn = false
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- (HudSlots' frame)
	g.DisplayOrder = 5
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	buildWeapons(g)
	buildDeal(g)
	buildSandbox(g)
	buildLevel()
	Controller.addHudButton({ window = "Settings", label = "Settings", icon = "settings", theme = "settings", layoutOrder = 8 })
	HudSlots.watch(place)
	ViewMode.onChanged(function()
		place()
		refresh()
	end)
	Keybinds.onChanged(refresh)
	refresh()
	ProgressUI.onState(function(s: any)
		lastState = s
		stateAt = os.clock()
		drawWeapons(s.takedowns or 0)
		drawLevel()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not Keybinds.live(processed) or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if Keybinds.is("SlowMo", input.KeyCode) then
			HudPlus.sandbox("SlowMo")
		elseif Keybinds.is("ReviveAll", input.KeyCode) then
			HudPlus.sandbox("Revive")
		end
	end)
	local lastSecond = -1
	player:GetAttributeChangedSignal("Owned"):Connect(function()
		if lastState then
			drawWeapons(lastState.takedowns or 0)
		end
	end)
	RunService.RenderStepped:Connect(function()
		followBar()
		-- (A goal within 3 kills: the WEAPONS button breathes, gold.)
		local w = weapons
		if w and w:GetAttribute("Close") == true then
			local k = (math.sin(os.clock() * 6) + 1) / 2
			w.BackgroundColor3 = RED:Lerp(Color3.fromRGB(255, 150, 40), k * 0.6)
		elseif w then
			w.BackgroundColor3 = RED
		end
		local second = math.floor(os.clock())
		if second ~= lastSecond then
			lastSecond = second
			drawLevel()
			refresh()
			local clock = dealClock
			if clock then
				local s = secondsToMidnight()
				clock.Text = string.format("Ends in %d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
			end
		end
	end)
	-- The bar's gold line is the big button's job now.
	PokeController.setNext(nil)
end

-- Tests / LayoutCheck.
function HudPlus.guiForTest(): ScreenGui?
	return gui
end

return HudPlus
