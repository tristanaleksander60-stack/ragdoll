--!strict
-- Round 5 (the owner): the next three weapons you unlock, always on the tool bar, after your own
-- slots: each one dark with a clear padlock on its picture, "12/27" kills and a gold progress bar.
-- A tap opens WEAPONS. PokeController leaves room for them (plan: three slots in one row, or one
-- column of three small cards beside a two-row bar on a phone) and places the frame; this module
-- draws the cards in it. HudPlus feeds it the takedowns and what you own (ProgressUI's state).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys"))
local BarRules = require(Shared:WaitForChild("BarRules"))
local Config = require(Shared:WaitForChild("Config"))
local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))

local ToolPicture = require(script.Parent:WaitForChild("ToolPicture"))
local KitStyle = require(script.Parent:WaitForChild("KitStyle"))

local NextUnlocks = {}

NextUnlocks.SHOWN = 1 -- (23 Nov 2026, owner: only the next one; was 3)
NextUnlocks.STACK_GAP = 4 -- px between the small cards in a column (a phone)

local GOLD = Theme.Palette.gold
local FACE = if (Theme :: any).Premium then Theme.Hud.face else Color3.fromRGB(28, 30, 38)
local EDGE = Color3.fromRGB(96, 100, 116)
local TRACK = Color3.fromRGB(60, 58, 50)

type Card = { id: string, root: TextButton, picture: GuiObject, lock: Frame, count: TextLabel, name: TextLabel, track: Frame, fill: Frame }

local frame: Frame? = nil
local cards: { Card } = {}
local upcoming: { { id: string, have: number, need: number } } = {}
local shape = { stacked = false, cell = Vector2.new(96, 60), gap = 8 }

NextUnlocks.onTap = nil :: ((id: string) -> ())?
NextUnlocks.onCount = nil :: ((n: number) -> ())? -- the number of cards changed (the bar lays out again)

-- The next weapons to unlock by kills: not yours yet, cheapest first.
function NextUnlocks.listFor(takedowns: number, owned: { [string]: boolean }, n: number?): { { id: string, have: number, need: number } }
	local pool = {}
	for _, toy in Toys.list do
		if toy.unlockAt > 0 and toy.unlockAt > takedowns and not owned[toy.id] then
			table.insert(pool, toy)
		end
	end
	table.sort(pool, function(a, b)
		if a.unlockAt ~= b.unlockAt then
			return a.unlockAt < b.unlockAt
		end
		return a.id < b.id
	end)
	local out = {}
	for i = 1, math.min(n or NextUnlocks.SHOWN, #pool) do
		table.insert(out, { id = pool[i].id, have = takedowns, need = pool[i].unlockAt })
	end
	return out
end

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function makeCard(id: string, parent: Instance): Card
	local root = Instance.new("TextButton")
	root.Name = "Next_" .. id
	root.Text = ""
	root.AutoButtonColor = false
	root.BackgroundColor3 = FACE
	root.BackgroundTransparency = 0.05
	root.ClipsDescendants = false
	corner(root, UDim.new(0, Theme.Radius.button))
	local stroke = Instance.new("UIStroke")
	stroke.Color = EDGE
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = root
	local pic = ToolPicture.make(id, UDim2.fromOffset(24, 24))
	pic.Name = "Picture"
	pic.Parent = root
	-- (Dimmed: it is not yours yet.)
	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 20
	corner(dim, UDim.new(0.5, 0))
	dim.Parent = pic
	-- The padlock: a dark round badge with a gold edge over the picture's corner.
	local lock = Instance.new("Frame")
	lock.Name = "Lock"
	lock.AnchorPoint = Vector2.new(0.5, 0.5)
	lock.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	lock.ZIndex = 22
	corner(lock, UDim.new(0.5, 0))
	local ls = Instance.new("UIStroke")
	ls.Color = GOLD
	ls.Thickness = 2
	ls.Parent = lock
	local glyph = Instance.new("TextLabel")
	glyph.BackgroundTransparency = 1
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.Text = "\u{1F512}"
	glyph.TextScaled = true
	glyph.ZIndex = 23
	glyph.Parent = lock
	lock.Parent = root
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.FontFace = Theme.Fonts.display
	name.TextColor3 = Color3.fromRGB(210, 212, 222)
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = string.upper(Toys.byId[id].short)
	name.ZIndex = 21
	local nf = Instance.new("UITextSizeConstraint")
	nf.MaxTextSize = 14
	nf.MinTextSize = 8
	nf.Parent = name
	if KitStyle.V2 then
		KitStyle.fitOrHide(name, 16) -- (UI v2: 14 px or hidden: the picture and padlock still say it)
	end
	name.Parent = root
	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.BackgroundTransparency = 1
	count.FontFace = Theme.Fonts.display
	count.TextColor3 = GOLD
	count.TextScaled = true
	count.TextXAlignment = Enum.TextXAlignment.Left
	count.ZIndex = 21
	local cf = Instance.new("UITextSizeConstraint")
	cf.MaxTextSize = 14
	cf.MinTextSize = 9
	cf.Parent = count
	if KitStyle.V2 then
		KitStyle.fitOrHide(count, 16) -- (the gold bar under it shows the same)
	end
	count.Parent = root
	local track = Instance.new("Frame")
	track.Name = "Progress"
	track.AnchorPoint = Vector2.new(0.5, 1)
	track.BackgroundColor3 = TRACK
	track.BorderSizePixel = 0
	track.ZIndex = 21
	corner(track, UDim.new(1, 0))
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = GOLD
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.ZIndex = 22
	corner(fill, UDim.new(1, 0))
	fill.Parent = track
	track.Parent = root
	root.Activated:Connect(function()
		local tap = NextUnlocks.onTap
		if tap then
			tap(id)
		end
	end)
	root.Parent = parent
	return { id = id, root = root, picture = pic, lock = lock, count = count, name = name, track = track, fill = fill }
end

-- Lays one card out for its box: a slot-sized card (picture and lock on the left, the name and the
-- count beside them, the bar along the foot; on a narrow slot the picture on top), or a small one in a
-- phone's column (picture and lock, the count, the bar).
local function arrange(card: Card, w: number, h: number, small: boolean)
	local barH = if small then 5 else 7
	card.track.Position = UDim2.new(0.5, 0, 1, -4)
	card.track.Size = UDim2.new(1, -10, 0, barH)
	if small then
		local p = math.max(16, h - barH - 10)
		card.picture.AnchorPoint = Vector2.new(0, 0)
		card.picture.Position = UDim2.fromOffset(4, 3)
		card.picture.Size = UDim2.fromOffset(p, p)
		local l = math.floor(p * 0.75)
		card.lock.Size = UDim2.fromOffset(l, l)
		card.lock.Position = UDim2.fromOffset(4 + p, 3 + p / 2)
		card.name.Visible = false
		card.count.Position = UDim2.fromOffset(4 + p + l / 2 + 3, 3)
		card.count.Size = UDim2.new(1, -(4 + p + l / 2 + 6), 0, p)
	elseif w < 80 then
		local p = 22
		card.picture.AnchorPoint = Vector2.new(0.5, 0)
		card.picture.Position = UDim2.new(0.5, -6, 0, 4)
		card.picture.Size = UDim2.fromOffset(p, p)
		card.lock.Size = UDim2.fromOffset(22, 22)
		card.lock.Position = UDim2.new(0.5, 12, 0, 4 + p / 2)
		card.name.Visible = false
		card.count.TextXAlignment = Enum.TextXAlignment.Center
		card.count.Position = UDim2.fromOffset(3, 4 + p + 1)
		card.count.Size = UDim2.new(1, -6, 0, math.max(10, h - p - barH - 12))
	else
		local p = math.max(22, math.floor(h * 0.5))
		card.picture.AnchorPoint = Vector2.new(0, 0)
		card.picture.Position = UDim2.fromOffset(5, 4)
		card.picture.Size = UDim2.fromOffset(p, p)
		local l = math.max(22, math.floor(p * 0.9))
		card.lock.Size = UDim2.fromOffset(l, l)
		card.lock.Position = UDim2.fromOffset(5 + p - 2, 4 + p - 4)
		local x = 5 + p + l / 2 + 2
		card.name.Visible = true
		card.name.Position = UDim2.fromOffset(x, 4)
		card.name.Size = UDim2.new(1, -(x + 4), 0, math.floor((h - barH - 12) / 2))
		card.count.TextXAlignment = Enum.TextXAlignment.Left
		card.count.Position = UDim2.fromOffset(x, 4 + math.floor((h - barH - 12) / 2))
		card.count.Size = UDim2.new(1, -(x + 4), 0, math.floor((h - barH - 12) / 2))
	end
end

local function redraw()
	local f = frame
	if not f then
		return
	end
	-- The same three: the cards stay (only their numbers move); a new weapon list: new cards.
	local same = #cards == #upcoming
	if same then
		for i, c in cards do
			if c.id ~= upcoming[i].id then
				same = false
				break
			end
		end
	end
	if not same then
		for _, c in cards do
			c.root:Destroy()
		end
		cards = {}
		for _, u in upcoming do
			table.insert(cards, makeCard(u.id, f))
		end
	end
	local w, h = shape.cell.X, shape.cell.Y
	for i, c in cards do
		local u = upcoming[i]
		if shape.stacked then
			-- (Three rows in the two-row bar's height, whatever the count: the cards keep their size.)
			local ch = math.floor((shape.cell.Y * 2 + shape.gap - (NextUnlocks.SHOWN - 1) * NextUnlocks.STACK_GAP) / NextUnlocks.SHOWN)
			c.root.Size = UDim2.fromOffset(w, ch)
			c.root.Position = UDim2.fromOffset(0, (i - 1) * (ch + NextUnlocks.STACK_GAP))
			arrange(c, w, ch, true)
		else
			c.root.Size = UDim2.fromOffset(w, h)
			c.root.Position = UDim2.fromOffset((i - 1) * (w + shape.gap), 0)
			arrange(c, w, h, false)
		end
		c.count.Text = string.format("%d/%d", math.min(u.have, u.need), u.need)
		local k = math.clamp(u.have / math.max(1, u.need), 0, 1)
		TweenService:Create(c.fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(math.max(k, 0.04), 1) }):Play()
	end
end

-- PokeController: where the cards go (a frame in the bar) and their shape for this layout.
function NextUnlocks.mount(parent: Frame)
	frame = parent
	redraw()
end

function NextUnlocks.shape(stacked: boolean, cell: Vector2, gap: number)
	shape = { stacked = stacked, cell = cell, gap = gap }
	redraw()
end

function NextUnlocks.count(): number
	return #upcoming
end

-- HudPlus: the takedowns and what is yours (whenever either changes).
local lastState: { takedowns: number, owned: { [string]: boolean } }? = nil
local recheck = false
function NextUnlocks.setState(takedowns: number, owned: { [string]: boolean })
	local before = #upcoming
	lastState = { takedowns = takedowns, owned = owned }
	-- (Phase 0: hidden for new players; looked at again once the visit is old enough.)
	if BarRules.nextUnlocksShown(takedowns, time()) then
		upcoming = NextUnlocks.listFor(takedowns, owned)
	else
		upcoming = {}
		if not recheck and time() < Config.NEXT_UNLOCKS_AFTER then
			recheck = true
			task.delay(Config.NEXT_UNLOCKS_AFTER - time() + 0.1, function()
				local s = lastState
				if s then
					NextUnlocks.setState(s.takedowns, s.owned)
				end
			end)
		end
	end
	redraw()
	if #upcoming ~= before then
		local cb = NextUnlocks.onCount
		if cb then
			cb(#upcoming)
		end
	end
end

-- Tests: the ids shown now.
function NextUnlocks.shown(): { string }
	local ids = {}
	for _, c in cards do
		table.insert(ids, c.id)
	end
	return ids
end

return NextUnlocks
