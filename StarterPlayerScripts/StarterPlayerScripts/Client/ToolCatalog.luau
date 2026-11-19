--!strict
-- The Tools window: every weapon on four shelves (Melee, Guns, Explosives, Specials: round 2, N4),
-- each a card with a drawn icon, a one-line blurb and two bars (POWER, CHAOS), lowest on the
-- takedown ladder first. A weapon still locked shows how far there is to go ("(43/100) Kills") and
-- a BUY button with its Robux price (WeaponShop); an unlocked one EQUIP (into a free slot, or the
-- bar asks which slot) or UNEQUIP when it is in the bar (the bar keeps one tool at least).
-- Two rows of four are in view at once; the shelf scrolls for the rest.
-- Built with the LihFolk UI kit (vault: "LihFolk UI Design System"), the same family as the Events
-- shop. Opened from the TOOLS button pinned at the left of the bar, or T on a keyboard.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys"))
local Net = require(Shared:WaitForChild("Net"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Toast = require(script.Parent:WaitForChild("Toast"))
local ToolPicture = require(script.Parent:WaitForChild("ToolPicture"))
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local SP = Theme.Space
local CARD = Vector2.new(182, 316) -- (the weapon's 3D model on a stage on top: the picture is what young players read first)

-- Phones (shorter side 500 px or less) see the window at the touch floor's scale, about 335 design
-- units tall: there the instruction line is left out and EQUIP sits right under the tool's name, so
-- the first row of cards shows its EQUIP buttons without scrolling (LayoutCheck.catalogLive checks
-- it). Blurb and bars follow below.
local WINDOW_SIZE = Vector2.new(820, 780) -- design units: a whole shelf (two rows of four) in view
local WINDOW = "Tools"

local ToolCatalog = {}
ToolCatalog.CARD = CARD
ToolCatalog.ICON = 84 -- px, the card's picture: a stage the model lies along (N7; bigger in N5)
ToolCatalog.ICON_PHONE = 40 -- px on a phone (EQUIP stays above the fold)

-- Set by the bar: is this tool in it, and put it there.
type Bar = {
	has: (id: string) -> boolean,
	equip: (id: string) -> (),
	unequip: ((id: string) -> boolean)?,
	canUnequip: (() -> boolean)?,
}

local bar: Bar? = nil
local shelf: Frame? = nil
local tabs: { [string]: any } = {}
local equipButtons: { [string]: any } = {}
local current: string = Toys.categories[1]
local intro: TextLabel? = nil
local cardParts: { { title: GuiObject, blurb: GuiObject, stats: GuiObject, equip: GuiObject, icon: Frame, progress: GuiObject } } = {}
local progressBars: { [string]: any } = {}
local locks: { [string]: GuiObject } = {}
local shownAs: { [string]: string } = {} -- each button's last look (redrawn only when it changes)
local Shop = require(Shared:WaitForChild("Shop"))
local RobuxPrice = require(script.Parent:WaitForChild("RobuxPrice"))
local INK = Color3.fromRGB(5, 6, 8)

-- What a weapon is to this player now: "loading" (the profile is not read yet), "locked", or "open".
local function ownedSet(): { [string]: boolean }
	local set = {}
	local raw = Players.LocalPlayer:GetAttribute("Owned")
	if type(raw) == "string" then
		for id in string.gmatch(raw, "[^,]+") do
			set[id] = true
		end
	end
	return set
end
local function stateOf(toy: Toys.Toy, owned: { [string]: boolean }): (string, number)
	local known = Players.LocalPlayer:GetAttribute("Takedowns") :: number?
	local have = known or 0
	local all = RunService:IsStudio() and Players.LocalPlayer:GetAttribute("UnlockAll") == true
	if toy.unlockAt <= 0 or all or owned[toy.id] or (known ~= nil and have >= toy.unlockAt) then
		return "open", have
	end
	-- (Round 5: TRY FREE, a few minutes with it: TrialService sets these on the player.)
	if Players.LocalPlayer:GetAttribute("TrialWeapon") == toy.id then
		local untilAt = Players.LocalPlayer:GetAttribute("TrialUntil")
		if type(untilAt) == "number" and untilAt > game:GetService("Workspace"):GetServerTimeNow() then
			return "open", have
		end
	end
	-- (The free weekend's weapon, round 3, M9: anyone may use it until Sunday ends.)
	if game:GetService("Workspace"):GetAttribute("FreeWeapon") == toy.id then
		return "open", have
	end
	-- (The owner is in this server and gave everyone every weapon: AdminService.)
	if game:GetService("Workspace"):GetAttribute("OwnerParty") == true then
		return "open", have
	end
	return if known == nil then "loading" else "locked", have
end
ToolCatalog.stateOf = function(id: string): string
	local toy = Toys.byId[id]
	return if toy then (stateOf(toy, ownedSet())) else "unknown"
end

-- The kills line on a locked card: "(43/100) Kills".
function ToolCatalog.killsText(have: number, need: number): string
	return string.format("(%d/%d) Kills", math.min(have, need), need)
end

local function iconName(id: string): string
	return "tool_" .. id
end
ToolCatalog.iconName = iconName

-- Every tool's picture (its emoji on its shape, LihFolkUIIcons), named "tool_<id>": the catalog
-- and the tool bar draw the same one. Safe to call more than once.
local function registerIcons()
	for _, toy in Toys.list do
		local name = iconName(toy.id)
		if not Icons.Fallbacks[name] then
			Icons.Fallbacks[name] = { glyph = toy.glyph, shape = "square", color = toy.color } -- (rounded squares, as the HUD's)
		end
	end
end
ToolCatalog.registerIcons = registerIcons

-- The doctor mode switch at the bottom of the window (HospitalCharts binds it; V on a keyboard).
type Switch = { get: () -> boolean, set: (on: boolean) -> () }
local hospital: Switch? = nil
local hospitalButton: any = nil

local function refreshHospital()
	local h = hospital
	local button = hospitalButton
	if h and button then
		local on = h.get()
		button.setText(if on then "DOCTOR MODE: ON" else "DOCTOR MODE: OFF")
		button.setRole(if on then "info" else "neutral")
	end
end

-- Weapon prices: always Roblox's own (RobuxPrice: GetProductInfoAsync), never a number typed in
-- here. Until the answer comes a BUY button reads "BUY ..."; when Roblox never answers it reads
-- "BUY N/A" and is off (as the shop's buttons are). Studio, with no product made yet, says TEST.
local pricePending: { [string]: boolean } = {} -- tiers asked and not answered yet (one callback each)
local function priceText(tierKey: string): (string, boolean)
	local productId = Shop.WEAPON_PRODUCTS[tierKey] or 0
	if productId == 0 then
		return "TEST", true -- (only Studio offers BUY without a product)
	end
	local price, answered = RobuxPrice.peek(productId)
	if answered then
		return RobuxPrice.text(price), price ~= nil
	end
	if not pricePending[tierKey] then
		pricePending[tierKey] = true
		RobuxPrice.get(productId, function()
			pricePending[tierKey] = nil
			table.clear(shownAs) -- (every BUY button drawn again with the price)
			ToolCatalog.refresh()
		end)
	end
	return "...", false
end

local tryButtons: { [string]: TextButton } = {}
-- The weapon on a free try now (nil: none).
local function trialRunning(): string?
	local id = Players.LocalPlayer:GetAttribute("TrialWeapon")
	local untilAt = Players.LocalPlayer:GetAttribute("TrialUntil")
	if type(id) == "string" and type(untilAt) == "number" and untilAt > game:GetService("Workspace"):GetServerTimeNow() then
		return id
	end
	return nil
end
ToolCatalog.trialRunning = trialRunning

local function refreshEquip()
	local b = bar
	local owned = ownedSet()
	local ownedCount = 0
	local canUnequip = b ~= nil and b.canUnequip ~= nil and (b.canUnequip :: () -> boolean)()
	for id, button in equipButtons do
		local toy = Toys.byId[id]
		local state, have = stateOf(toy, owned)
		local tier = Toys.priceTier(toy)
		-- A weapon still to earn: its takedowns so far on a bar, and BUY at its price (Robux, the
		-- kit's premium colour). Until the profile is read nobody knows yet, and it says so.
		local left = math.max(1, toy.unlockAt - have)
		-- (A live server sells only what the owner has put on sale: a tier without its product
		-- shows how far there is to go instead. Studio's BUY gives it, for testing.)
		local onSale = tier ~= nil and (RunService:IsStudio() or (Shop.WEAPON_PRODUCTS[tier.key] or 0) ~= 0)
		local inBar = b ~= nil and b.has(id)
		local buyable = state == "locked" and tier ~= nil and onSale and Toys.canBuy(toy, have)
		local price, priced = "", true
		if buyable and tier then
			price, priced = priceText(tier.key)
		end
		local look = string.format("%s|%s|%d|%s|%s|%s", state, tostring(buyable), if state == "locked" and not buyable then left else 0, tostring(inBar), tostring(canUnequip), price)
		if shownAs[id] == look then
			-- unchanged button: nothing redrawn (the kills bar below still moves)
		elseif buyable and tier then
			-- BUY and the price, the Robux mark in ink on the premium yellow (the kit's image is
			-- pale: tinted dark so it reads).
			button.setIcon("robux")
			local mark = button.root:FindFirstChild("Icon_robux", true)
			if mark and mark:IsA("ImageLabel") then
				mark.ImageColor3 = INK
			end
			button.setText("BUY " .. price)
			button.setRole("premium")
			button.setEnabled(priced)
		elseif state == "locked" then
			-- Nearly earned (never sold), or not on sale yet: the button says how close it is.
			button.setIcon(nil)
			button.setEnabled(true)
			button.setText("LOCKED")
			button.setRole("locked")
		elseif state == "loading" then
			button.setIcon(nil)
			button.setEnabled(true)
			button.setText("LOADING...")
			button.setRole("locked")
		else
			button.setIcon(nil)
			button.setEnabled(true)
			-- (Round 5, like the big ragdoll games: EQUIP, or EQUIPPED in green once it is on the bar;
			-- tapping EQUIPPED takes it off again, unless it is the bar's last tool.)
			button.setText(if inBar then "EQUIPPED" else "EQUIP")
			button.setRole(if inBar then "done" else "go")
		end
		-- (A lock on a locked weapon's picture: the card reads "not yours yet" at a glance.)
		local lock = locks[id]
		if lock then
			lock.Visible = state == "locked"
		end
		-- TRY FREE on a locked one, while no other try runs (round 5).
		local tryButton = tryButtons[id]
		if tryButton then
			tryButton.Visible = state == "locked" and trialRunning() == nil
		end
		if state == "open" and trialRunning() ~= id then
			ownedCount += 1
		end
		shownAs[id] = look
		local progress = progressBars[id]
		if progress then
			local need = math.max(1, toy.unlockAt)
			progress.bar.setValue(math.clamp(have / need, 0, 1), false)
			progress.bar.setText(ToolCatalog.killsText(have, need))
			progress.row.Visible = state == "locked"
		end
	end
	-- The header line (round 5): how many are yours, and the ways to the rest.
	local line = intro
	if line then
		line.Text = string.format("%d/%d OWNED  ·  Locked: earn kills, BUY, or TRY FREE for 2 min", ownedCount, #Toys.list)
	end
end

local pictureMakers: { [string]: () -> () } = {} -- cards whose 3D picture is not drawn yet
local function showShelf(category: string)
	current = category
	for name, tab in tabs do
		tab.setRole(if name == category then "info" else "neutral")
	end
	local frame = shelf
	if not frame then
		return
	end
	local open = Controller.isOpen(WINDOW)
	for _, card in frame:GetChildren() do
		if card:IsA("GuiObject") then
			local toy = Toys.byId[card.Name]
			card.Visible = toy ~= nil and toy.category == category
			local make = toy and pictureMakers[toy.id]
			if card.Visible and open and make then
				pictureMakers[toy.id] = nil
				make()
			end
		end
	end
end

local function statBar(label: string, value: number, order: number, parent: Instance)
	local row = Instance.new("Frame")
	row.Name = label
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 24)
	row.LayoutOrder = order
	row.Parent = parent
	-- Kit "small": the style for bar labels (never drawn under the 12 px floor).
	C.Text("small", label, {
		color = Theme.Palette.textMid,
		align = Enum.TextXAlignment.Left,
		size = UDim2.new(0, 70, 1, 0),
		parent = row,
	})
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.new(0, 72, 0, 4)
	holder.Size = UDim2.new(1, -72, 1, -8)
	holder.Parent = row
	C.ProgressBar({
		value = math.clamp(value, 0, 1),
		role = if label == "CHAOS" then "danger" else "premium",
		size = UDim2.fromScale(1, 1),
		parent = holder,
	})
end

local function build()
	registerIcons()
	-- The header's picture is the left column's WEAPONS tile's: the G17's 3D model on the same
	-- blue rounded square (the same menu colour as the tile).
	local window = C.Window({
		name = WINDOW,
		title = "Weapons",
		theme = "settings",
		icon = "toolbox",
		picture = ToolPicture.make("Blaster", UDim2.fromScale(1, 1)),
		size = WINDOW_SIZE,
	})

	intro = C.Text("body", "EQUIP puts a weapon in your bar. Locked ones: take people down, or BUY.", {
		color = Theme.Palette.textHi,
		wrap = true,
		size = UDim2.new(1, 0, 0, 28),
		layoutOrder = 0,
		parent = window.body,
	})

	-- Shelf tabs.
	local tabRow = Instance.new("Frame")
	tabRow.Name = "Tabs"
	tabRow.BackgroundTransparency = 1
	tabRow.Size = UDim2.new(1, 0, 0, 58)
	tabRow.LayoutOrder = 1
	tabRow.Parent = window.body
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, SP.sm)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabRow
	for index, category in Toys.categories do
		local tab = C.Button({
			name = "Tab_" .. category,
			text = string.upper(category),
			role = "neutral",
			size = UDim2.new(0.25, -SP.sm, 0, 56), -- four across, whatever the width
			layoutOrder = index,
			parent = tabRow,
			onActivated = function()
				showShelf(category)
			end,
		})
		tabs[category] = tab
	end

	-- The cards (all of them; the shelf shows one category at a time).
	local grid = Instance.new("Frame")
	grid.Name = "Shelf"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = 2
	C.Grid(grid, CARD, SP.md)
	grid.Parent = window.body
	shelf = grid

	-- Under the shelf: the doctor mode switch (the hospital monitor; the touch screens' way in).
	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1, 0, 0, 64)
	footer.LayoutOrder = 3
	footer.Parent = window.body
	hospitalButton = C.Button({
		name = "HospitalSwitch",
		text = "DOCTOR MODE: OFF",
		role = "info",
		size = UDim2.new(0, 320, 0, 56),
		layoutOrder = 1,
		parent = footer,
		onActivated = function()
			local h = hospital
			if h then
				local on = not h.get()
				h.set(on)
				refreshHospital()
				if on and h.get() then
					Controller.close(WINDOW) -- (the monitor is at the bottom, behind this window)
				end
			end
		end,
	})
	local footerLayout = Instance.new("UIListLayout")
	footerLayout.FillDirection = Enum.FillDirection.Horizontal
	footerLayout.Padding = UDim.new(0, SP.md)
	footerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	footerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	footerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	footerLayout.Parent = footer

	-- Lowest on the ladder first: what you have, then what comes next.
	local order = table.clone(Toys.list)
	table.sort(order, function(x, y)
		if x.unlockAt ~= y.unlockAt then
			return x.unlockAt < y.unlockAt
		end
		return (table.find(Toys.list, x) or 0) < (table.find(Toys.list, y) or 0)
	end)
	for index, toy in order do
		local card = C.Card({ name = toy.id, gap = SP.xs, layoutOrder = index, parent = grid })
		local iconSlot = Instance.new("Frame")
		iconSlot.Name = "IconSlot"
		-- The stage: a lighter well at the top of the card, lit from above, the model on it.
		iconSlot.BackgroundTransparency = 0
		iconSlot.BackgroundColor3 = Color3.new(1, 1, 1)
		iconSlot.Size = UDim2.new(1, 0, 0, ToolCatalog.ICON)
		iconSlot.LayoutOrder = 1
		iconSlot.Parent = card.content
		local stageCorner = Instance.new("UICorner")
		stageCorner.CornerRadius = UDim.new(0, Theme.Radius.card - 2)
		stageCorner.Parent = iconSlot
		local stageLight = Instance.new("UIGradient")
		stageLight.Rotation = 90
		stageLight.Color = ColorSequence.new(Theme.Palette.stageTop, Theme.Palette.stageBottom)
		stageLight.Parent = iconSlot
		local stageEdge = Instance.new("UIStroke")
		stageEdge.Color = Theme.Palette.line
		stageEdge.Thickness = 1
		stageEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stageEdge.Parent = iconSlot
		-- The real model, lying along the strip (N7), drawn the first time its shelf is shown with
		-- the window open (round 3 M1: 49 model copies at the start were memory nobody used).
		local icon = Instance.new("Frame")
		icon.Name = "Picture"
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromScale(1, 1)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Parent = iconSlot
		local toyId = toy.id
		pictureMakers[toyId] = function()
			local picture = ToolPicture.make(toyId, UDim2.fromScale(1, 1), true)
			picture.Parent = icon
		end
		local lock = Instance.new("TextLabel")
		lock.Name = "Lock"
		lock.BackgroundTransparency = 1
		lock.AnchorPoint = Vector2.new(0, 1)
		lock.Position = UDim2.new(1, -24, 1, 2) -- (in the strip's corner)
		lock.Size = UDim2.fromOffset(24, 24)
		lock.Text = "\u{1F512}"
		lock.TextScaled = true
		lock.ZIndex = icon.ZIndex + 2
		lock.Visible = false
		lock.Parent = iconSlot
		locks[toy.id] = lock
		-- TRY FREE (round 5): a locked weapon for two minutes, once a day each (TrialService).
		local try = Instance.new("TextButton")
		try.Name = "TryFree"
		try.AnchorPoint = Vector2.new(0, 0)
		try.Position = UDim2.fromOffset(4, 4)
		try.Size = UDim2.fromOffset(88, 26)
		try.BackgroundColor3 = Color3.fromRGB(40, 170, 80)
		try.Text = "TRY FREE"
		try.TextScaled = true
		try.FontFace = Theme.Fonts.display
		try.TextColor3 = Color3.new(1, 1, 1)
		try.ZIndex = icon.ZIndex + 3
		try.Visible = false
		local tryCorner = Instance.new("UICorner")
		tryCorner.CornerRadius = UDim.new(0, 8)
		tryCorner.Parent = try
		local tryStroke = Instance.new("UIStroke")
		tryStroke.Thickness = 2
		tryStroke.Color = INK
		tryStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		tryStroke.Parent = try
		local tryPad = Instance.new("UIPadding")
		tryPad.PaddingTop = UDim.new(0, 3)
		tryPad.PaddingBottom = UDim.new(0, 3)
		tryPad.Parent = try
		local tryId = toy.id
		try.Activated:Connect(function()
			Net.event(Net.Names.Trial):FireServer("Try", tryId)
		end)
		try.Parent = iconSlot
		tryButtons[toy.id] = try
		-- Phase K: the picture comes alive under the pointer or a tap (a little hop and wiggle).
		local hop = Instance.new("UIScale")
		hop.Parent = icon
		local function wiggle()
			if Theme.isReducedMotion() then
				return
			end
			hop.Scale = 1.3
			TweenService:Create(hop, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			icon.Rotation = -14
			TweenService:Create(icon, TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
		end
		card.root.MouseEnter:Connect(wiggle)
		card.root.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				wiggle()
			end
		end)
		local title = C.Text("title", toy.label, { scaled = true, size = UDim2.new(1, 0, 0, 26), layoutOrder = 2, parent = card.content })

		-- The blurb: two full lines at the kit's caption size (never cut to one line).
		local blurb = C.Text("caption", toy.blurb, {
			color = Theme.Palette.textMid,
			wrap = true,
			size = UDim2.new(1, 0, 0, 38),
			layoutOrder = 3,
			parent = card.content,
		})
		local stats = Instance.new("Frame")
		stats.Name = "Stats"
		stats.BackgroundTransparency = 1
		stats.Size = UDim2.new(1, 0, 0, 50)
		stats.LayoutOrder = 4
		stats.Parent = card.content
		local statLayout = Instance.new("UIListLayout")
		statLayout.Padding = UDim.new(0, 4)
		statLayout.SortOrder = Enum.SortOrder.LayoutOrder
		statLayout.Parent = stats
		if toy.power <= 0 and toy.chaos <= 0 then
			-- A helper (Heal): no bars to fill, a tag instead, centred where the bars would be.
			statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			C.Pill("HELPER", { role = "go", parent = stats })
		else
			statBar("POWER", toy.power, 1, stats)
			statBar("CHAOS", toy.chaos, 2, stats)
		end
		-- A locked weapon's way there: its takedowns so far, on a bar.
		local progressRow = Instance.new("Frame")
		progressRow.Name = "Kills"
		progressRow.BackgroundTransparency = 1
		progressRow.Size = UDim2.new(1, 0, 0, 24)
		progressRow.LayoutOrder = 5
		progressRow.Visible = false
		progressRow.Parent = card.content
		local killsBar = C.ProgressBar({ value = 0, role = "danger", text = "", size = UDim2.fromScale(1, 1), parent = progressRow }) -- (red, as in the big ragdoll games: round 5)
		-- (Its words stay inside the 24 px bar, outline and all.)
		local killsText = progressRow:FindFirstChild("Label", true)
		local killsFit = killsText and killsText:FindFirstChildOfClass("UITextSizeConstraint")
		if killsFit then
			killsFit.MaxTextSize = 13
		end
		progressBars[toy.id] = { row = progressRow, bar = killsBar }
		local id = toy.id
		local equip = C.Button({
			name = "Equip",
			text = "EQUIP",
			role = "neutral",
			size = UDim2.new(1, 0, 0, 48), -- the kit grows its tap pad to the touch floor
			layoutOrder = 6,
			parent = card.content,
			onActivated = function()
				local b = bar
				if not b then
					return
				end
				local state = stateOf(toy, ownedSet())
				if state == "loading" then
					Toast.show("Loading your progress. Try again in a moment")
					return
				elseif state == "locked" then
					local have = (Players.LocalPlayer:GetAttribute("Takedowns") :: number?) or 0
					local tier = Toys.priceTier(toy)
					local onSale = tier ~= nil and (RunService:IsStudio() or (Shop.WEAPON_PRODUCTS[tier.key] or 0) ~= 0)
					if onSale and Toys.canBuy(toy, have) then
						-- BUY: Roblox's own prompt opens (the server checks it again and picks the product).
						Net.event(Net.Names.Weapons):FireServer("Buy", id)
					else
						Toast.show(string.format("Take down %d more for the %s!", math.max(1, toy.unlockAt - have), toy.label))
					end
					return
				end
				if b.has(id) and b.unequip and b.canUnequip and (b.canUnequip :: () -> boolean)() then
					if (b.unequip :: (string) -> boolean)(id) then
						Toast.show(toy.label .. " is off your bar. EQUIP another one!")
					end
					refreshEquip()
					return
				end
				b.equip(id)
				refreshEquip()
				-- The window steps aside: the bar asks for a new tool's slot, or shows the one picked.
				if Controller.isOpen(WINDOW) then
					Controller.toggle(WINDOW)
				end
			end,
		})
		equipButtons[id] = equip
		table.insert(cardParts, { title = title, blurb = blurb, stats = stats, equip = equip.root, icon = iconSlot, progress = progressRow })
	end
	-- The phone layout follows the window's Compact attribute (set here from the screen; LayoutCheck
	-- sets it on a PC to measure the phone layout).
	-- (Again whenever the screen changes size: the first frames report a tiny viewport, which
	-- left a computer in the phone layout.)
	local function fromScreen()
		local viewport = workspace.CurrentCamera.ViewportSize
		window.root:SetAttribute("Compact", math.min(viewport.X, viewport.Y) <= 500)
	end
	fromScreen()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fromScreen)
	window.root:GetAttributeChangedSignal("Compact"):Connect(function()
		ToolCatalog.setCompact(window.root:GetAttribute("Compact") == true)
	end)
	ToolCatalog.setCompact(window.root:GetAttribute("Compact") == true)

	Controller.register(window)
	-- Opening the catalog asks Roblox again for a price that failed a while ago (RobuxPrice).
	ToolCatalog.onOpenChanged(function(open: boolean)
		if open then
			table.clear(shownAs)
			refreshEquip()
			showShelf(current) -- (its pictures, the first time)
		end
	end)
	showShelf(current)
	refreshEquip()
end

-- The phone layout (see the top): no instruction line, EQUIP under the name. LayoutCheck switches
-- it on a PC to measure where EQUIP lands.
function ToolCatalog.setCompact(on: boolean)
	if intro then
		intro.Visible = not on
	end
	-- (The cards are as much shorter as their picture is: no empty foot on a phone.)
	local grid = shelf and shelf:FindFirstChildOfClass("UIGridLayout")
	if grid then
		grid.CellSize = UDim2.fromOffset(CARD.X, CARD.Y - (if on then ToolCatalog.ICON - ToolCatalog.ICON_PHONE else 0))
	end
	for _, parts in cardParts do
		-- (A phone keeps the picture a little smaller so EQUIP stays above the fold.)
		parts.icon.Size = UDim2.new(1, 0, 0, if on then ToolCatalog.ICON_PHONE else ToolCatalog.ICON)
		parts.title.LayoutOrder = 2
		parts.equip.LayoutOrder = if on then 3 else 6
		parts.progress.LayoutOrder = if on then 4 else 5
		parts.blurb.LayoutOrder = if on then 5 else 3
		parts.stats.LayoutOrder = if on then 6 else 4
	end
end

-- Opens or closes the window.
function ToolCatalog.toggle()
	Controller.toggle(WINDOW)
end

function ToolCatalog.isOpen(): boolean
	return Controller.isOpen(WINDOW)
end

-- Told when the window opens or closes (the bar steps aside while it is open).
function ToolCatalog.onOpenChanged(callback: (open: boolean) -> ())
	Controller.onChanged(function(name: string, open: boolean)
		if name == WINDOW then
			callback(open)
		end
	end)
end

-- The doctor mode switch: how to read it and flip it (HospitalCharts), and a redraw when it
-- changes elsewhere (V).
function ToolCatalog.bindHospital(get: () -> boolean, set: (on: boolean) -> ())
	hospital = { get = get, set = set }
	refreshHospital()
end

function ToolCatalog.refreshHospital()
	refreshHospital()
end

-- The bar changed (a tool equipped from the bar side, onboarding): the buttons follow.
function ToolCatalog.refresh()
	refreshEquip()
end

-- Opens on the shelf a tool is on (tests, and later the "new tool" toast).
function ToolCatalog.showTool(id: string)
	local toy = Toys.byId[id]
	if toy then
		showShelf(toy.category)
	end
end

function ToolCatalog.start(barApi: Bar)
	bar = barApi
	Controller.start()
	build()
	-- Tools unlock as takedowns come in (ProgressService keeps the attribute).
	Players.LocalPlayer:GetAttributeChangedSignal("Takedowns"):Connect(refreshEquip)
	Players.LocalPlayer:GetAttributeChangedSignal("Owned"):Connect(refreshEquip)
	Players.LocalPlayer:GetAttributeChangedSignal("TrialWeapon"):Connect(function()
		table.clear(shownAs)
		refreshEquip()
	end)
	-- TRY FREE's answer (round 5): on the bar now, or why not.
	Net.event(Net.Names.Trial).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if type(data) ~= "table" then
			return
		end
		local d = data :: any
		if kind == "Started" and type(d.id) == "string" and Toys.byId[d.id] then
			local toy = Toys.byId[d.id]
			local b = bar
			if b and not b.has(toy.id) then
				b.equip(toy.id)
			end
			if Controller.isOpen(WINDOW) then
				Controller.toggle(WINDOW)
			end
			Toast.show(string.format("FREE TRY: the %s is yours for 2 minutes!", string.upper(toy.label)), Color3.fromRGB(120, 230, 140))
			local id = toy.id
			task.delay(120, function()
				if Players.LocalPlayer:GetAttribute("TrialWeapon") ~= id or ToolCatalog.stateOf(id) == "locked" then
					Toast.show(string.format("The free try is over. Earn the %s with kills, or BUY it in WEAPONS!", toy.label))
				end
			end)
		elseif kind == "Refused" and type(d.text) == "string" then
			Toast.show(d.text)
		end
	end)
	game:GetService("Workspace"):GetAttributeChangedSignal("OwnerParty"):Connect(refreshEquip)
	-- A weapon bought: it is yours (the Owned attribute redraws the cards), and it says so.
	Net.event(Net.Names.Weapons).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if type(data) ~= "table" then
			return
		end
		local d = data :: { [string]: any }
		if kind == "Bought" then
			C.playSound("reward")
			if type(d.id) == "string" and Toys.byId[d.id] then
				Toast.show(string.format(if d.earlier then "Your %s from last time is here. EQUIP it!" else "The %s is yours. EQUIP it!", Toys.byId[d.id].label))
			elseif type(d.eggs) == "number" then
				Toast.show(string.format("You own every weapon! %d eggs instead", d.eggs))
			end
			refreshEquip()
		elseif kind == "Refused" and type(d.text) == "string" then
			Toast.show(d.text)
		end
	end)
end

return ToolCatalog
