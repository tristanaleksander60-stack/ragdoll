--!strict
-- V9-0i (owner, 21 Nov 2026: "fix all the icons in the shop so they match the right things and make the
-- whole shop 3D, interactive and beautiful, because people should spend money there"; Config.SHOP_V9).
-- The SHOP window ("Events", built by EventShop) laid out as a store:
--   * tabs FEATURED · PASSES · ITEMS · EVENTS · BOLTS; FEATURED opens first with a hero (EVERYTHING,
--     BEST VALUE) and a hand-picked row (Shared/ShopArt);
--   * cards in a grid (2 a row on a phone): the thing turning in 3D (ShopShowcase, within Ui3D's
--     budget; the picture on a low-end device and for events, which drift gently), a rarity frame by
--     price, its name, one line and a price button always showing Roblox's own price ("R$ 149"),
--     OWNED / OPEN when yours, TRYING m:ss during a try;
--   * hover or pad focus lifts and tilts a card and speeds its turn; a tap on a phone focuses, a second
--     opens it; the detail view has a big model you drag round, what you get, TRY where it exists and
--     a big gold BUY; B/BACK closes it;
--   * a purchase that lands (a pass's attribute, an offer's "Got", an event's "bought") bursts the card
--     with confetti and a Robux shower, flies the picture to the SHOP button and says YOURS!
-- Buying goes through EventShop's paths (the api), never anything new: Roblox's own prompt.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopArt = require(Shared:WaitForChild("ShopArt")) :: any
local Shop = require(Shared:WaitForChild("Shop")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local ShopShowcase = require(Client:WaitForChild("ShopShowcase")) :: any
local RobuxPrice = require(Client:WaitForChild("RobuxPrice")) :: any
local Ui3D = require(Client:WaitForChild("Ui3D")) :: any
local KitStyle = require(Client:WaitForChild("KitStyle")) :: any

local player = Players.LocalPlayer

local ShopV9 = {}

ShopV9.SIZE = Vector2.new(900, 620)
ShopV9.CARD = Vector2.new(206, 306)
ShopV9.CARD_PHONE_H = 256 -- (a phone's short window: a whole card in view)
ShopV9.GAP = 14
ShopV9.TAB_H = 52
ShopV9.HERO_H = 230
ShopV9.HERO_PHONE = 150
ShopV9.BUY_MEMORY = 180 -- s a BUY tap stays "asked" (a pass's attribute then means it was just bought)

export type Api = {
	buyPass: (key: string) -> (),
	buyOffer: (key: string) -> (),
	buyEvent: (eventId: string) -> (),
	eventEntry: (eventId: string, setText: (string) -> (), setEnabled: (boolean) -> ()) -> (),
	eventsExtras: (page: Frame) -> (),
	tryGod: () -> (),
	tryItem: (key: string) -> (),
}

type Card = {
	item: any,
	root: Frame,
	media: Frame,
	scale: UIScale,
	stroke: UIStroke,
	price: any, -- kit Button
	hit: TextButton,
	ribbon: TextLabel?,
	robux: number?,
	live3D: boolean,
	name: TextLabel?,
}

local api: Api
local window: any = nil
local pages: { [string]: Frame } = {}
local tabs: { [string]: any } = {}
local current = "FEATURED"
local cards: { Card } = {}
local byKey: { [string]: { Card } } = {}
local asked: { [string]: number } = {} -- key -> os.clock of its last BUY tap
local focused: Card? = nil
local detail: Frame? = nil
local detailItem: any = nil
local detailBuy: any = nil
local detailTry: any = nil
local blur: BlurEffect? = nil
local scroller: ScrollingFrame? = nil
local drifts: { Tween } = {} -- the event pictures' slow zooms (played only while the shop is open)

-- A controller is in use (the focus ring is for pads only).
function ShopV9.pad(): boolean
	local t = UserInputService:GetLastInputType()
	return t.Name:sub(1, 7) == "Gamepad"
end

local function lowEnd(): boolean
	local ok, low = pcall(function()
		return Ui3D.lowEnd()
	end)
	return ok and low == true
end

local function phone(): boolean
	local camera = Workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
	return math.min(v.X, v.Y) <= 500
end

------------------------------------------------------------------------------------------------
-- What a card shows

local function owned(item: any): boolean
	if item.kind == "weapon" then
		local ok, state = pcall(function()
			return (require(Client:WaitForChild("ToolCatalog")) :: any).stateOf(item.toy)
		end)
		return ok and state == "open"
	end
	if item.product then
		return false
	end
	if item.kind == "pass" then
		return player:GetAttribute(item.key) == true
	end
	return player:GetAttribute("Offer_" .. item.key) == true
end

-- A running try: (ends at server time) or nil.
local function tryingUntil(item: any): number?
	local untilT: any = nil
	if item.key == "God" then
		untilT = player:GetAttribute("GodTrialUntil")
	elseif item.kind == "offer" then
		untilT = player:GetAttribute("Try_" .. item.key)
	end
	if type(untilT) == "number" and untilT > Workspace:GetServerTimeNow() then
		return untilT
	end
	return nil
end

local function priceText(robux: number?): string
	return if robux then "R$ " .. RobuxPrice.text(robux) else "R$ ..."
end

local function refreshCard(card: Card)
	local item = card.item
	local button = card.price
	if item.kind == "event" then
		return -- (an event's button is EventShop's: its price and the queue rule)
	end
	local mine = owned(item)
	local untilT = tryingUntil(item)
	if item.key == "God" and Config.GOD_FREE_BETA and not mine then
		-- (V9-0l: free for everyone in the beta: never sold now, it opens.)
		button.setRole("go")
		button.setText("FREE \u{00B7} BETA")
		button.setEnabled(true)
		button.setIcon("god") -- (no Robux mark: nothing to pay)
	elseif mine and item.key == "God" then
		button.setRole("go")
		button.setText("OPEN")
		button.setEnabled(true)
	elseif mine then
		button.setRole("done")
		button.setText("OWNED")
		button.setEnabled(false)
	elseif item.kind == "weapon" and not Toys.canBuy(Toys.byId[item.toy], (player:GetAttribute("Takedowns") :: number?) or 0) then
		-- (One nearly earned is never sold: the server refuses it too.)
		button.setRole("locked")
		button.setText("NEARLY YOURS")
		button.setEnabled(false)
	elseif untilT then
		local left = math.max(0, math.floor(untilT - Workspace:GetServerTimeNow()))
		button.setRole("info")
		button.setText(string.format("TRYING %d:%02d", left // 60, left % 60))
		button.setEnabled(true)
	else
		button.setRole("premium")
		button.setText(if item.id == 0 then (if RunService:IsStudio() then "TEST" else "SOON") else priceText(card.robux))
		button.setEnabled(item.id ~= 0 or RunService:IsStudio())
	end
	local ribbon = card.ribbon
	if ribbon then
		ribbon.Text = if mine then "OWNED" elseif item.key == ShopArt.HERO then "BEST VALUE" else ribbon.Text
	end
end

local function refreshAll()
	for _, card in cards do
		refreshCard(card)
	end
	if detail and detail.Visible and detailItem and detailBuy then
		local mine = owned(detailItem)
		if detailItem.key == "God" and Config.GOD_FREE_BETA and not mine then
			detailBuy.setRole("go")
			detailBuy.setText("FREE \u{00B7} BETA")
			detailBuy.setEnabled(true)
			detailBuy.setIcon("god")
			return
		end
		detailBuy.setRole(if mine and detailItem.key == "God" then "go" elseif mine then "done" else "premium")
		detailBuy.setText(if mine and detailItem.key == "God" then "OPEN" elseif mine then "OWNED" else (byKey[detailItem.key] and byKey[detailItem.key][1] and priceText(byKey[detailItem.key][1].robux) or "BUY"))
		detailBuy.setEnabled(not mine or detailItem.key == "God")
	end
end

------------------------------------------------------------------------------------------------
-- Buying and the celebration

local function buy(item: any)
	if item.key == "God" and Config.GOD_FREE_BETA and not owned(item) then
		api.tryGod() -- (V9-0l: free in the beta: claimed and opened, never sold)
		return
	end
	if item.key == "God" and owned(item) then
		Controller.open("God")
		return
	end
	if owned(item) then
		return
	end
	if item.kind == "weapon" then
		if os.clock() >= (asked[item.key] or -math.huge) + 2 then
			asked[item.key] = os.clock()
			Net.event(Net.Names.Weapons):FireServer("Buy", item.toy)
		end
		return
	end
	asked[item.key] = os.clock()
	if item.kind == "pass" then
		api.buyPass(item.key)
	elseif item.kind == "offer" then
		api.buyOffer(item.key)
	else
		api.buyEvent(item.key)
	end
end

local function confetti(into: GuiObject, from: Vector2)
	local colours = { Color3.fromRGB(255, 201, 60), Color3.fromRGB(255, 120, 60), Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 230, 120), Color3.fromRGB(240, 110, 200) }
	for i = 1, 34 do
		local b = Instance.new("Frame")
		b.Name = "Confetti"
		b.BorderSizePixel = 0
		b.BackgroundColor3 = colours[(i % #colours) + 1]
		b.Size = UDim2.fromOffset(8, 12)
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.fromScale(from.X, from.Y)
		-- lihfolk-ignore: paid-random-no-policy (confetti angles only; nothing random is sold here)
		b.Rotation = math.random(0, 360)
		b.ZIndex = 80
		b.Parent = into
		local dx = (math.random() - 0.5) * 0.7
		local up = 0.15 + math.random() * 0.3
		local t1 = TweenService:Create(b, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(from.X + dx * 0.5, from.Y - up), Rotation = b.Rotation + math.random(-180, 180) })
		t1:Play()
		t1.Completed:Connect(function()
			local t2 = TweenService:Create(b, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(from.X + dx, 1.05), BackgroundTransparency = 1 })
			t2:Play()
			t2.Completed:Connect(function()
				b:Destroy()
			end)
		end)
	end
	-- A shower of Robux marks from the top.
	for i = 1, 12 do
		local coin = Icons.make("robux", UDim2.fromOffset(26, 26))
		coin.AnchorPoint = Vector2.new(0.5, 0.5)
		coin.Position = UDim2.fromScale(0.1 + 0.8 * (i / 12), -0.05)
		coin.ZIndex = 79
		coin.Parent = into
		local t = TweenService:Create(coin, TweenInfo.new(0.9 + math.random() * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.1 + 0.8 * (i / 12) + (math.random() - 0.5) * 0.1, 1.08), Rotation = math.random(-200, 200) })
		t:Play()
		t.Completed:Connect(function()
			coin:Destroy()
		end)
	end
end

-- The bought thing's picture flies from the card to the SHOP button and fades.
local function fly(item: any, fromObject: GuiObject?)
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then
		return
	end
	local layer = Instance.new("ScreenGui")
	layer.Name = "ShopFly"
	layer.IgnoreGuiInset = true
	layer.DisplayOrder = 60
	layer.Parent = gui
	local pic = Icons.make(item.picture, UDim2.fromOffset(120, 120))
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	local start = if fromObject then fromObject.AbsolutePosition + fromObject.AbsoluteSize / 2 else Workspace.CurrentCamera.ViewportSize / 2
	pic.Position = UDim2.fromOffset(start.X, start.Y + GuiService:GetGuiInset().Y)
	pic.Parent = layer
	local target = Vector2.new(60, 160)
	local shop = gui:FindFirstChild("Hud_Shop", true)
	if shop and shop:IsA("GuiObject") then
		target = shop.AbsolutePosition + shop.AbsoluteSize / 2 + Vector2.new(0, GuiService:GetGuiInset().Y)
	end
	local goals: { [string]: any } = { Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(28, 28) }
	if pic:IsA("ImageLabel") then
		goals.ImageTransparency = 0.3
	end
	local t = TweenService:Create(pic, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), goals)
	t:Play()
	t.Completed:Connect(function()
		layer:Destroy()
	end)
end

-- A purchase of `key` landed: only when this screen asked for it (a pass set on joining is quiet).
-- True when it celebrated (the caller then says nothing more).
local celebrated: { [string]: number } = {} -- key -> os.clock it was just celebrated
function ShopV9.celebrate(key: string): boolean
	-- (A pass lands twice, its attribute and MoneyService's "Owned": one celebration, and the second
	-- caller stays quiet too.)
	local last = celebrated[key]
	if last and os.clock() - last < 10 then
		return true
	end
	local at = asked[key]
	if not at or os.clock() - at > ShopV9.BUY_MEMORY then
		return false
	end
	asked[key] = nil
	local item = ShopArt.byKey(key)
	if not item then
		return false
	end
	celebrated[key] = os.clock()
	local list = byKey[key]
	local card = list and list[1]
	if window and Controller.isOpen("Events") then
		local from = Vector2.new(0.5, 0.45)
		if card and card.root.AbsoluteSize.X > 0 and window.body.AbsoluteSize.X > 0 then
			local p = (card.root.AbsolutePosition + card.root.AbsoluteSize / 2 - window.body.AbsolutePosition) / window.body.AbsoluteSize
			from = Vector2.new(math.clamp(p.X, 0, 1), math.clamp(p.Y, 0, 1))
		end
		confetti(window.body, from)
	end
	fly(item, if detail and detail.Visible then detail else (card and card.media))
	pcall(function()
		local rarity = ShopArt.rarity(item.robux, item.kind)
		-- (V9-0g on a phone: a small pill, never the full banner.)
		local compact = (require(Client:WaitForChild("NoticeState")) :: any).compact()
		if compact then
			(require(Client:WaitForChild("Toast")) :: any).show("YOURS! " .. item.name, rarity.color)
		else
			local Banner = require(Client:WaitForChild("Banner")) :: any
			Banner.show({ title = "YOURS!", sub = item.name, color = rarity.color, icon = item.picture, emoji = "\u{1F389}", priority = 4 })
		end
	end)
	refreshAll()
	return true
end

------------------------------------------------------------------------------------------------
-- The detail view

local function closeDetail()
	if detail then
		detail.Visible = false
	end
	detailItem = nil
	ContextActionService:UnbindAction("ShopV9Back")
	local list = focused
	if list then
		if ShopV9.pad() then
			GuiService.SelectedObject = list.hit
		end
	end
end

-- A map-shop item (it has a 60 s TRY at its booth).
local function isMapItem(key: string): boolean
	for _, o in Shop.OFFERS do
		if o.key == key then
			return o.map == true and o.kind == "pass"
		end
	end
	return false
end

-- The thing itself: its 3D showcase (when `allow3D` and the device can), else its picture.
local function media(item: any, size: UDim2, big: boolean, allow3D: boolean?): GuiObject
	local holder = Instance.new("Frame")
	holder.Name = "Media"
	holder.BackgroundTransparency = 1
	holder.Size = size
	holder.ClipsDescendants = true
	local spec = ShopArt.SHOW[item.key]
	local vp: GuiObject? = nil
	if ShopArt.LIVE_3D and spec and allow3D ~= false and not lowEnd() then
		vp = ShopShowcase.viewport(spec, UDim2.fromScale(1, 1), if big then "big" else nil)
	end
	if vp then
		vp.Parent = holder
	else
		-- (The picture: an event's drifts in a slow zoom so it never sits still.)
		local pic = Icons.make(item.picture, UDim2.fromScale(1, 1))
		pic.AnchorPoint = Vector2.new(0.5, 0.5)
		pic.Position = UDim2.fromScale(0.5, 0.5)
		if pic:IsA("ImageLabel") then
			pic.ScaleType = if item.kind == "weapon" then Enum.ScaleType.Fit else Enum.ScaleType.Crop
		end
		pic.Parent = holder
		if item.kind == "event" then
			-- (Drifts only while the shop is open: ShopV9.drift starts and stops them all.)
			local t = TweenService:Create(pic, TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromScale(1.14, 1.14), Position = UDim2.fromScale(0.47, 0.53) })
			table.insert(drifts, t)
			if Controller.isOpen("Events") then
				t:Play()
			end
			pic.Destroying:Connect(function()
				t:Cancel()
				local i = table.find(drifts, t)
				if i then
					table.remove(drifts, i)
				end
			end)
		end
	end
	return holder
end

local function openDetail(item: any)
	local d = detail
	if not d then
		return
	end
	for _, c in d:GetChildren() do
		if c.Name ~= "Back" then
			c:Destroy()
		end
	end
	detailItem = item
	local rarity = ShopArt.rarity(item.robux, item.kind)
	local narrow = window and window.body.AbsoluteSize.X > 0 and window.body.AbsoluteSize.X / math.max(0.01, window.fitScale.Scale) < 640
	-- Left (top when narrow): the big model, dragged round.
	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.BackgroundColor3 = rarity.color
	stage.BackgroundTransparency = 0.72
	stage.Size = if narrow then UDim2.new(1, -24, 0.46, 0) else UDim2.new(0.48, -18, 1, -24)
	stage.Position = UDim2.fromOffset(12, 12)
	C.corner(stage, UDim.new(0, 16))
	stage.Parent = d
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Transparency = NumberSequence.new(0.2, 0.85)
	g.Parent = stage
	media(item, UDim2.fromScale(1, 1), true).Parent = stage
	-- Right (bottom when narrow): what it is and what you get.
	local info = Instance.new("Frame")
	info.Name = "Info"
	info.BackgroundTransparency = 1
	info.Size = if narrow then UDim2.new(1, -24, 0.54, -24) else UDim2.new(0.52, -18, 1, -24)
	info.Position = if narrow then UDim2.new(0, 12, 0.46, 18) else UDim2.new(0.48, 6, 0, 12)
	info.Parent = d
	C.list(info, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left)
	C.Pill(rarity.name, { role = "premium", layoutOrder = 1, parent = info })
	local name = C.Text("title", item.name, { scaled = true, size = UDim2.new(1, 0, 0, 40), layoutOrder = 2, parent = info })
	name.TextXAlignment = Enum.TextXAlignment.Left
	for i, line in item.bullets do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 30)
		row.LayoutOrder = 2 + i
		row.Parent = info
		local tick = Icons.make("check", UDim2.fromOffset(22, 22))
		tick.AnchorPoint = Vector2.new(0, 0.5)
		tick.Position = UDim2.new(0, 0, 0.5, 0)
		tick.Parent = row
		local t = C.Text("body", line, { wrap = true, size = UDim2.new(1, -30, 1, 0), position = UDim2.fromOffset(30, 0), parent = row })
		t.TextXAlignment = Enum.TextXAlignment.Left
	end
	-- TRY where it exists: GOD MODE's 60 s, a map item's 60 s.
	detailTry = nil
	local canTry = ((item.key == "God" and not Config.GOD_FREE_BETA) or isMapItem(item.key)) and not owned(item) -- (V9-0l: no GOD MODE trial while it is free)
	if canTry then
		detailTry = C.Button({
			name = "Try",
			text = "TRY 60 s",
			role = "info",
			size = UDim2.new(1, 0, 0, 52),
			layoutOrder = 10,
			parent = info,
			onActivated = function()
				if item.key == "God" then
					api.tryGod()
				else
					api.tryItem(item.key)
				end
			end,
		})
	end
	local list = byKey[item.key]
	local card = list and list[1]
	detailBuy = C.Button({
		name = "Buy",
		text = if card then card.price.label.Text else "BUY",
		role = "premium",
		size = UDim2.new(1, 0, 0, 60),
		layoutOrder = 11,
		parent = info,
		onActivated = function()
			buy(item)
		end,
	})
	detailBuy.setIcon("robux")
	d.Visible = true
	refreshAll() -- (after Visible: it only touches a shown detail)
	pcall(KitStyle.pop, d)
	if ShopV9.pad() then
		GuiService.SelectedObject = detailBuy.hit -- (a pad's focus; a mouse or a finger never sees the ring)
	end
	ContextActionService:BindActionAtPriority("ShopV9Back", function(_, state)
		if state == Enum.UserInputState.Begin then
			closeDetail()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 60, Enum.KeyCode.ButtonB)
end

------------------------------------------------------------------------------------------------
-- Cards

local function makeCard(item: any, parent: Instance, order: number): Card
	local rarity = ShopArt.rarity(item.robux, item.kind)
	local root = Instance.new("Frame")
	root.Name = "Card_" .. item.key
	root.BackgroundColor3 = Theme.Palette.dusk
	root.BackgroundTransparency = 0.05
	root.LayoutOrder = order
	C.corner(root, UDim.new(0, 16))
	local stroke = C.outline(root, 2, rarity.color)
	local scale = Instance.new("UIScale")
	scale.Parent = root
	root.Parent = parent
	-- The stage: the rarity's colour behind the turning model or the picture.
	local stageBack = Instance.new("Frame")
	stageBack.Name = "Stage"
	stageBack.BackgroundColor3 = rarity.color
	local mediaH = if phone() then 112 else 156
	stageBack.Size = UDim2.new(1, -16, 0, mediaH)
	stageBack.Position = UDim2.fromOffset(8, 8)
	C.corner(stageBack, UDim.new(0, 12))
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Transparency = NumberSequence.new(0.35, 0.9)
	g.Parent = stageBack
	stageBack.Parent = root
	-- (The picture first; the 3D comes when its page is first shown: upgrade, so the shop builds fast.)
	local m = media(item, UDim2.fromScale(1, 1), false, false)
	m.Parent = stageBack
	C.corner(m :: any, UDim.new(0, 12))
	-- The rarity tag and a ribbon.
	local tag = C.Pill(rarity.name, { role = "neutral", anchor = Vector2.new(0, 0), position = UDim2.fromOffset(6, 6), zIndex = 6, parent = stageBack })
	tag.BackgroundColor3 = rarity.color
	local ribbon: TextLabel? = nil
	if item.key == ShopArt.HERO or item.key == "God" then
		local r = Instance.new("TextLabel")
		r.Name = "Ribbon"
		r.Text = if item.key == ShopArt.HERO then "BEST VALUE" else "NEW"
		r.FontFace = Theme.Fonts.display
		r.TextSize = 14
		r.TextColor3 = Theme.Palette.ink
		r.BackgroundColor3 = Color3.fromRGB(255, 205, 64)
		r.Size = UDim2.fromOffset(96, 24)
		r.AnchorPoint = Vector2.new(1, 0)
		r.Position = UDim2.new(1, -6, 0, 6)
		r.ZIndex = 6
		C.corner(r, UDim.new(0, 8))
		r.Parent = stageBack
		ribbon = r
	end
	local nameLabel = C.Text("title", item.name, { scaled = true, size = UDim2.new(1, -16, 0, 28), position = UDim2.fromOffset(8, mediaH + 14), parent = root })
	KitStyle.fit(nameLabel, 24, 14)
	local line = C.Text("caption", item.line, { color = Theme.Palette.textMid, wrap = true, size = UDim2.new(1, -16, 0, if mediaH < 150 then 26 else 38), position = UDim2.fromOffset(8, mediaH + 44), parent = root })
	line.TextYAlignment = Enum.TextYAlignment.Top
	-- The whole card opens the detail (a tap on a phone focuses it first).
	local hit = Instance.new("TextButton")
	hit.Name = "Open"
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.new(1, 0, 1, -64)
	hit.ZIndex = 5
	hit.Selectable = true
	hit.SelectionImageObject = C.selectionRing(UDim.new(0, 16))
	hit.Parent = root
	local price = C.Button({
		name = "Price",
		text = "R$ ...",
		role = "premium",
		size = UDim2.new(1, -16, 0, 52), -- (52 x 0.85 on a phone = 44 px: the touch floor)
		parent = root,
		onActivated = function()
			buy(item)
		end,
	})
	price.root.AnchorPoint = Vector2.new(0.5, 1)
	price.root.Position = UDim2.new(0.5, 0, 1, -8)
	price.setIcon("robux")
	local card: Card = { item = item, root = root, media = stageBack, scale = scale, stroke = stroke, price = price, hit = hit, ribbon = ribbon, robux = nil, live3D = false, name = nameLabel }
	-- Feel: lift and tilt toward the pointer, glow; the kit's hover tick.
	local function lift(on: boolean)
		TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { Scale = if on then 1.045 else 1 }):Play()
		stroke.Thickness = if on then 3.5 else 2
		if not on then
			TweenService:Create(root, TweenInfo.new(0.14), { Rotation = 0 }):Play()
		end
	end
	hit.MouseEnter:Connect(function()
		lift(true)
		C.playSound("hover")
	end)
	hit.MouseLeave:Connect(function()
		lift(false)
	end)
	hit.MouseMoved:Connect(function(x: number)
		local w = root.AbsoluteSize.X
		if w > 0 then
			root.Rotation = math.clamp((x - root.AbsolutePosition.X - w / 2) / w * 5, -2.5, 2.5)
		end
	end)
	hit.SelectionGained:Connect(function()
		lift(true)
		focused = card
	end)
	hit.SelectionLost:Connect(function()
		lift(false)
	end)
	hit.Activated:Connect(function(input: InputObject?)
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		if touch and focused ~= card then
			-- (A phone: the first tap focuses, the second opens.)
			local was = focused
			if was then
				lift(false)
			end
			focused = card
			lift(true)
			return
		end
		focused = card
		C.playSound("click")
		openDetail(item)
	end)
	KitStyle.press(price.hit)
	-- Its price, Roblox's own.
	if item.kind == "event" then
		api.eventEntry(item.key, function(text: string)
			price.setText(if text == "..." then "R$ ..." elseif tonumber(text) then "R$ " .. text else text)
		end, function(on: boolean)
			price.setEnabled(on)
		end)
	elseif item.id ~= 0 then
		local function got(robux: number?)
			card.robux = robux
			refreshCard(card)
		end
		if item.kind == "pass" or not item.product then
			RobuxPrice.getPass(item.id, got)
		else
			RobuxPrice.get(item.id, got)
		end
	end
	table.insert(cards, card)
	byKey[item.key] = byKey[item.key] or {}
	table.insert(byKey[item.key], card)
	refreshCard(card)
	return card
end

-- A page's grid, its cell width following the window (2 a row on a phone).
local function grid(page: Frame, order: number): Frame
	local holder = Instance.new("Frame")
	holder.Name = "Grid"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.LayoutOrder = order
	holder.Parent = page
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(ShopV9.GAP, ShopV9.GAP)
	layout.CellSize = UDim2.fromOffset(ShopV9.CARD.X, ShopV9.CARD.Y)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = holder
	local function fit()
		local scaleNow = if window then math.max(0.01, window.fitScale.Scale) else 1
		local w = holder.AbsoluteSize.X / scaleNow
		if w <= 0 then
			return
		end
		local cols = if phone() then 2 else math.clamp(math.floor((w + ShopV9.GAP) / (ShopV9.CARD.X + ShopV9.GAP)), 2, 5)
		local cellW = math.floor((w - ShopV9.GAP * (cols - 1)) / cols)
		layout.CellSize = UDim2.fromOffset(cellW, if phone() then ShopV9.CARD_PHONE_H else ShopV9.CARD.Y)
	end
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	task.defer(fit)
	return holder
end

local function heading(page: Frame, text: string, order: number)
	local h = C.Text("title", text, { size = UDim2.new(1, 0, 0, 32), layoutOrder = order, parent = page })
	h.TextXAlignment = Enum.TextXAlignment.Left
end

-- FEATURED's hero: EVERYTHING, big, with its model turning and BEST VALUE.
local function hero(page: Frame, item: any)
	local rarity = ShopArt.rarity(item.robux, item.kind)
	local banner = Instance.new("Frame")
	banner.Name = "Hero"
	banner.BackgroundColor3 = Color3.fromRGB(255, 160, 40)
	banner.Size = UDim2.new(1, 0, 0, if phone() then ShopV9.HERO_PHONE else ShopV9.HERO_H) -- (a phone's short window: the cards show sooner)
	banner.LayoutOrder = 1
	C.corner(banner, UDim.new(0, 18))
	C.outline(banner, 3, rarity.color)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 186, 60), Color3.fromRGB(214, 70, 40))
	g.Rotation = 20
	g.Parent = banner
	banner.Parent = page
	local stage = media(item, UDim2.new(0.42, 0, 1, -16), true)
	stage.Position = UDim2.fromOffset(8, 8)
	stage.Parent = banner
	local text = Instance.new("Frame")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(0.58, -24, 1, -24)
	text.Position = UDim2.new(0.42, 12, 0, 12)
	text.Parent = banner
	C.list(text, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Left)
	C.Pill("BEST VALUE", { role = "premium", layoutOrder = 1, parent = text })
	local t = C.Text("title", item.name, { scaled = true, size = UDim2.new(1, 0, 0, 44), layoutOrder = 2, parent = text })
	t.TextXAlignment = Enum.TextXAlignment.Left
	local b = C.Text("body", item.line, { wrap = true, size = UDim2.new(1, 0, 0, 52), layoutOrder = 3, parent = text })
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Visible = not phone() -- (the short phone hero: name, BEST VALUE and the buttons)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 56)
	row.LayoutOrder = 4
	row.Parent = text
	C.list(row, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left)
	local see = C.Button({ name = "See", text = "SEE INSIDE", role = "info", size = UDim2.new(0.45, -5, 1, 0), layoutOrder = 1, parent = row, onActivated = function()
		openDetail(item)
	end })
	local _ = see
	-- (The hero's BUY is the same card's button, so it follows the price and OWNED.)
	local list = byKey[item.key]
	local card = list and list[1]
	local heroBuy = C.Button({ name = "Buy", text = if card then card.price.label.Text else "BUY", role = "premium", size = UDim2.new(0.55, -5, 1, 0), layoutOrder = 2, parent = row, onActivated = function()
		buy(item)
	end })
	heroBuy.setIcon("robux")
	task.spawn(function()
		while banner.Parent do
			local c = card
			if c then
				local mine = owned(item)
				heroBuy.setRole(if mine then "done" else "premium")
				heroBuy.setText(c.price.label.Text)
				heroBuy.setEnabled(c.price.isEnabled())
			end
			task.wait(1)
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Tabs and pages

-- A card's picture becomes its turning model, once (the page is on screen now).
local function upgrade(card: Card)
	if not ShopArt.LIVE_3D or card.live3D or not ShopArt.SHOW[card.item.key] or lowEnd() then
		return
	end
	card.live3D = true
	local old = card.media:FindFirstChild("Media")
	local m = media(card.item, UDim2.fromScale(1, 1), false, true)
	if m:FindFirstChild("Showcase3D") then
		m.Parent = card.media
		C.corner(m :: any, UDim.new(0, 12))
		if old then
			old:Destroy()
		end
	else
		m:Destroy()
	end
end

local function show(tab: string)
	current = tab
	for name, page in pages do
		page.Visible = name == tab
	end
	-- (V9-0i review: the page's 3D comes one card a frame, in order, so opening never stalls.)
	local page = pages[tab]
	local todo: { Card } = {}
	for _, card in cards do
		if page and card.root:IsDescendantOf(page) and not card.live3D then
			table.insert(todo, card)
		end
	end
	table.sort(todo, function(a, b)
		return a.root.LayoutOrder < b.root.LayoutOrder
	end)
	task.spawn(function()
		for _, card in todo do
			if current ~= tab then
				return
			end
			upgrade(card)
			RunService.Heartbeat:Wait()
		end
	end)
	for name, button in tabs do
		button.setRole(if name == tab then "premium" else "neutral")
	end
	local s = scroller
	if s then
		s.CanvasPosition = Vector2.zero
	end
	closeDetail()
	-- (The prices count up as a page opens.)
	for _, card in cards do
		if card.item.tab == tab and card.robux and string.sub(card.price.label.Text, 1, 2) == "R$" then -- (a price only: never over OWNED or a try)
			pcall(KitStyle.countUp, card.price.label, card.robux, function(n: number): string
				return "R$ " .. tostring(math.floor(n))
			end)
		end
	end
end

function ShopV9.build(win: any, given: Api)
	window = win
	api = given
	local body = win.body :: GuiObject
	-- The tab row, and a "Have a code?" button at its end.
	local row = Instance.new("Frame")
	row.Name = "Tabs"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, ShopV9.TAB_H)
	row.Parent = body
	C.list(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center)
	for i, tab in ShopArt.TABS do
		tabs[tab] = C.Button({ name = "Tab_" .. tab, text = tab, role = if tab == current then "premium" else "neutral", size = UDim2.new(0.17, -6, 1, 0), layoutOrder = i, parent = row, onActivated = function()
			show(tab)
		end })
	end
	-- (V9-0i review: labelled: on a phone this is the only way to CODES.)
	local code = C.Button({ name = "HaveCode", text = "CODES", role = "info", size = UDim2.new(0.13, -6, 1, 0), layoutOrder = 10, parent = row, onActivated = function()
		Controller.open("Codes")
	end })
	code.setIcon("present")
	-- The pages, one scrolling list under the tabs.
	local s = Instance.new("ScrollingFrame")
	s.Name = "Pages"
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.Position = UDim2.fromOffset(0, ShopV9.TAB_H + 8)
	s.Size = UDim2.new(1, 0, 1, -(ShopV9.TAB_H + 8))
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.CanvasSize = UDim2.new()
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = Theme.Palette.textLow
	s.Parent = body
	C.pad(s, 6)
	scroller = s
	for i, tab in ShopArt.TABS do
		local page = Instance.new("Frame")
		page.Name = "Page_" .. tab
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 0)
		page.AutomaticSize = Enum.AutomaticSize.Y
		page.Visible = tab == current
		page.LayoutOrder = i
		C.list(page, Enum.FillDirection.Vertical, 12, Enum.HorizontalAlignment.Center)
		page.Parent = s
		pages[tab] = page
	end
	-- Cards, each in its own tab.
	local grids: { [string]: Frame } = {}
	for _, tab in ShopArt.TABS do
		if tab ~= "FEATURED" then
			if tab == "EVENTS" then
				api.eventsExtras(pages[tab])
			end
			grids[tab] = grid(pages[tab], 20)
		end
	end
	-- (Owner, 26 Nov 2026: the weapons, sold here now, under their own heading in ITEMS.)
	if Config.WEAPONS_NO_BUY and pages.ITEMS then
		heading(pages.ITEMS, "WEAPONS", 30)
		grids.WEAPONS = grid(pages.ITEMS, 31)
	end
	local items = ShopArt.items()
	local studio = RunService:IsStudio()
	for i, item in items do
		if item.id ~= 0 or studio then
			makeCard(item, if item.kind == "weapon" then (grids.WEAPONS or grids[item.tab]) else grids[item.tab], i)
		end
	end
	-- FEATURED: the hero and a row of picks (their own cards, the same buying).
	local heroItem = ShopArt.byKey(ShopArt.HERO)
	if heroItem and (heroItem.id ~= 0 or studio) then
		hero(pages.FEATURED, heroItem)
	end
	heading(pages.FEATURED, "POPULAR", 2)
	local picks = grid(pages.FEATURED, 3)
	for i, key in ShopArt.FEATURED do
		local item = ShopArt.byKey(key)
		if item and (item.id ~= 0 or studio) then
			makeCard(item, picks, i)
		end
	end
	-- The detail view, over the pages.
	local d = Instance.new("Frame")
	d.Name = "Detail"
	d.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
	d.BackgroundTransparency = 0
	d.Size = UDim2.fromScale(1, 1)
	d.ZIndex = 40
	d.Visible = false
	C.corner(d, UDim.new(0, 16))
	d.Parent = body
	local back = C.Button({ name = "Back", text = "BACK", role = "neutral", size = UDim2.fromOffset(130, 52), parent = d, onActivated = closeDetail })
	back.root.AnchorPoint = Vector2.new(1, 0)
	back.root.Position = UDim2.new(1, -12, 0, 12)
	back.root.ZIndex = 50
	detail = d
	-- Tries count down on their cards.
	task.spawn(function()
		while true do
			task.wait(1)
			if Controller.isOpen("Events") then
				for _, card in cards do
					if tryingUntil(card.item) then
						refreshCard(card)
					end
				end
			end
		end
	end)
	-- Owning something changes its card; a purchase this screen asked for is celebrated.
	for _, item in items do
		local attr = if item.kind == "pass" then item.key elseif item.kind == "offer" and not item.product then "Offer_" .. item.key else nil
		if attr then
			player:GetAttributeChangedSignal(attr):Connect(function()
				refreshAll()
				if player:GetAttribute(attr) == true then
					ShopV9.celebrate(item.key)
				end
			end)
		end
		if item.kind == "offer" and not item.product then
			player:GetAttributeChangedSignal("Try_" .. item.key):Connect(refreshAll)
		end
	end
	player:GetAttributeChangedSignal("GodTrialUntil"):Connect(refreshAll)
	if Config.WEAPONS_NO_BUY then
		player:GetAttributeChangedSignal("Takedowns"):Connect(function()
			if Controller.isOpen("Events") then
				refreshAll()
			end
		end)
		player:GetAttributeChangedSignal("Owned"):Connect(refreshAll)
		player:GetAttributeChangedSignal("PassToys"):Connect(refreshAll)
	end
	-- (A prompt closed without buying: no YOURS! later for it, even if a slow ownership check lands.)
	local MarketplaceService = game:GetService("MarketplaceService")
	local function cancelled(id: number)
		for _, item in items do
			if item.id == id then
				asked[item.key] = nil
			end
		end
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, passId: number, bought: boolean)
		if not bought then
			cancelled(passId)
		end
	end)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, productId: number, bought: boolean)
		if not bought then
			cancelled(productId)
		end
	end)
	-- Opening: the world behind softly blurred; X buys the focused card on a pad.
	blur = Instance.new("BlurEffect")
	local b = blur :: BlurEffect
	b.Name = "ShopBlur"
	b.Size = 0
	b.Parent = Lighting
	Controller.onChanged(function(name: string, open: boolean)
		if name ~= "Events" then
			return
		end
		TweenService:Create(b, TweenInfo.new(0.25), { Size = if open then 10 else 0 }):Play()
		for _, t in drifts do
			if open then
				t:Play()
			else
				t:Pause()
			end
		end
		if open then
			show(current)
			ContextActionService:BindActionAtPriority("ShopV9Buy", function(_, state)
				if state ~= Enum.UserInputState.Begin then
					return Enum.ContextActionResult.Pass
				end
				local sel = GuiService.SelectedObject
				for _, card in cards do
					if sel and (sel == card.hit or sel:IsDescendantOf(card.root)) then
						buy(card.item)
						return Enum.ContextActionResult.Sink
					end
				end
				return Enum.ContextActionResult.Pass
			end, false, Enum.ContextActionPriority.High.Value + 50, Enum.KeyCode.ButtonX)
		else
			ContextActionService:UnbindAction("ShopV9Buy")
			closeDetail()
		end
	end)
	if pages.FEATURED then
		local first = byKey[ShopArt.FEATURED[1]]
		if first and first[1] then
			win.defaultSelection = first[1].hit
		end
	end
end

-- Studio: plays the purchase celebration of `key` as if this screen had just bought it ("celebrate:<key>").
function ShopV9.celebrateForTest(key: string)
	asked[key] = os.clock()
	ShopV9.celebrate(key)
end

-- Studio: shows a tab (the DevShopCheck hook "tab:<NAME>", for captures).
function ShopV9.showTab(tab: string)
	if pages[tab] then
		Controller.open("Events")
		show(tab)
	end
end

-- Studio: opens the detail view of `key` (the DevShopCheck hook "open:<key>", for captures).
function ShopV9.openFor(key: string)
	local item = ShopArt.byKey(key)
	if item then
		Controller.open("Events")
		openDetail(item)
	end
end

-- Studio self-check (the "DevShopCheck" hook): every card has a price or a state, the pictures are
-- registered, the detail view opens and closes, and the 3D within budget.
function ShopV9.selfCheck(): string
	local problems = {}
	local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any
	for _, card in cards do
		local text = card.price.label.Text
		if not (string.find(text, "R$", 1, true) or text == "OWNED" or text == "OPEN" or text == "TEST" or string.find(text, "TRYING", 1, true) or tonumber(text) or text == "N/A") then
			table.insert(problems, card.item.key .. " shows \"" .. text .. "\"")
		end
		if not DrawnIcons.ASSETS[card.item.picture] then
			table.insert(problems, card.item.key .. " has no picture " .. card.item.picture)
		end
		-- (Measured on this screen: the name and the price fit their boxes.)
		local nameLabel = card.name
		if nameLabel and nameLabel.AbsoluteSize.X > 0 and not nameLabel.TextFits then
			table.insert(problems, card.item.key .. "'s name does not fit")
		end
		if card.price.label.AbsoluteSize.X > 0 and not card.price.label.TextFits then
			table.insert(problems, card.item.key .. "'s price does not fit")
		end
	end
	for name, tab in tabs do
		if tab.label.AbsoluteSize.X > 0 and not tab.label.TextFits then
			table.insert(problems, "the tab " .. name .. " does not fit")
		end
		if UserInputService.TouchEnabled and tab.hit.AbsoluteSize.Y > 0 and tab.hit.AbsoluteSize.Y < 43.5 then
			table.insert(problems, "the tab " .. name .. " is under 44 px")
		end
	end
	local first = cards[1]
	if first then
		openDetail(first.item)
		if not (detail and detail.Visible) then
			table.insert(problems, "the detail view did not open")
		end
		closeDetail()
		if detail and detail.Visible then
			table.insert(problems, "the detail view did not close")
		end
	end
	return string.format("%d cards, %d problem(s)%s", #cards, #problems, if #problems > 0 then ": " .. table.concat(problems, "; ") else "")
end

return ShopV9
