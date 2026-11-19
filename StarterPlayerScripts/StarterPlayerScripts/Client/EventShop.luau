--!strict
-- The Events shop and the event banner, built with the LihFolk UI kit (Ink and Candy; vault:
-- "LihFolk UI Design System"). The shop lists every server event with its real Robux price from
-- Roblox; buying asks the server, which opens the purchase prompt (or, in Studio, while an event
-- is not on sale yet, runs it as a test). The banner shows the running event to everyone: who set
-- it off and how long is left.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Events = require(Shared:WaitForChild("Events"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local FxController = require(Client:WaitForChild("FxController"))
local Toast = require(Client:WaitForChild("Toast"))
local ScheduleUI = require(Client:WaitForChild("ScheduleUI"))
local RobuxPrice = require(Client:WaitForChild("RobuxPrice"))
local HudSlots = require(Client:WaitForChild("HudSlots"))

local player = Players.LocalPlayer
local SP = Theme.Space
local CARD = Vector2.new(220, 236)
local PRESS_LOCK = 1.2 -- s a shop button waits after a tap (no double prompts)
local WARN = Color3.fromRGB(255, 120, 100)

local EventShop = {}

type State = { id: string?, by: string?, source: string?, endsAt: number, queued: number }

local buyRemote: RemoteEvent
local state: State = { id = nil, by = nil, source = nil, endsAt = 0, queued = 0 }
-- ready: the button can be pressed at all (a price is known, or a Studio test); locked: just tapped.
-- why: what a tap that cannot buy says ("soon": no product yet; "asking": the price is on its
-- way; "failed": Roblox did not answer, asked again on the tap and when the shop opens).
type Entry = { button: any, ready: boolean, locked: boolean, why: string?, ask: (() -> ())? }
local buttons: { [string]: Entry } = {}
local queueLabel: TextLabel? = nil

------------------------------------------------------------------------------------------------
-- The shop window


-- The Robux packs on the right of the HUD (round 2, N5): the first events, each a card with its
-- picture, its name and its real price, tapped to buy it (the same path as the shop's button).
local packs: { [string]: { card: TextButton, price: TextLabel } } = {}
local packsGui: ScreenGui? = nil
local packsAfterFirstMinute = false -- (a new player's first minute is for the first shot only)

local function refreshButtons()
	local full = state.queued >= Events.MAX_QUEUE
	for _, event in Events.list do
		local entry = buttons[event.id]
		if entry then
			local can = not full and entry.ready and not entry.locked
			entry.button.setEnabled(can)
			local pack = packs[event.id]
			if pack then
				pack.card.AutoButtonColor = can
				pack.card.BackgroundTransparency = if can then 0.12 else 0.35
				pack.price.TextTransparency = if can then 0 else 0.4
			end
		end
	end
	local label = queueLabel
	if label then
		label.Text = if full
			then "The event queue is full. Try again in a moment."
			elseif state.queued > 0 then string.format("%d event%s waiting to go off.", state.queued, if state.queued == 1 then "" else "s")
			else "Everyone in the server sees your event, with your name on it."
	end
end

-- Phase I: the passes, at the top of the same shop (MoneyService decides; this only asks).
local Shop = require(Shared:WaitForChild("Shop"))
local moneyRemote: RemoteEvent? = nil
local passButtons: { [string]: any } = {}
local isOwner = false
local adminButton: any = nil
local shopHud: any = nil
local freeEnds = 0 -- server time free ULTRA runs to (0: not running)
local passBlurbs: { [string]: TextLabel } = {}
local buyLockedUntil = 0
local BUY_LOCK = 3 -- s a BUY waits after a tap (Roblox's purchase window is on its way)

local function refreshPasses()
	for key, button in passButtons do
		local pass = Shop.byKey[key]
		local mine = player:GetAttribute(key) == true
		button.setRole(if mine then "done" else "premium")
		button.setText(if mine then "OWNED" elseif pass.id ~= 0 then "BUY" elseif RunService:IsStudio() then "TEST" else "SOON")
		button.setEnabled(not mine and (pass.id ~= 0 or RunService:IsStudio()) and os.clock() >= buyLockedUntil)
	end
end

local function buildPasses(window: any)
	C.SectionHeader("PASSES", "shop", -4, window.body)
	local grid = Instance.new("Frame")
	grid.Name = "Passes"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = -3
	C.Grid(grid, Vector2.new(CARD.X, 268), SP.md)
	grid.Parent = window.body
	for index, pass in Shop.PASSES do
		local card = C.Card({ name = pass.key, featured = index == 1, gap = SP.xs, layoutOrder = index, parent = grid })
		card.root.Visible = pass.id ~= 0 or RunService:IsStudio() -- (phase 0: no "SOON" card)
		local title = C.Text("title", pass.name, { scaled = true, size = UDim2.new(1, 0, 0, 34), layoutOrder = 1, parent = card.content })
		title.TextColor3 = Color3.fromHex(pass.color)
		passBlurbs[pass.key] = C.Text("body", pass.blurb, { wrap = true, size = UDim2.new(1, 0, 0, 40), layoutOrder = 2, parent = card.content })
		local perks = C.Text("caption", "\u{2022} " .. table.concat(pass.perks, "\n\u{2022} "), {
			color = Theme.Palette.textMid,
			wrap = true,
			size = UDim2.new(1, 0, 0, 92),
			layoutOrder = 3,
			parent = card.content,
		})
		perks.TextXAlignment = Enum.TextXAlignment.Left
		local key = pass.key
		passButtons[key] = C.Button({
			text = "BUY",
			role = "premium",
			size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
			layoutOrder = 4,
			parent = card.content,
			onActivated = function()
				local r = moneyRemote
				if r and os.clock() >= buyLockedUntil then
					-- (One tap is one ask: the button rests while Roblox's purchase window opens.)
					buyLockedUntil = os.clock() + BUY_LOCK
					refreshPasses()
					task.delay(BUY_LOCK, refreshPasses)
					r:FireServer("Buy", key)
				end
			end,
		})
	end
	C.SectionHeader("SERVER EVENTS", "shop", -2, window.body)
	-- The owner's own button: start any event free for everyone (MoneyService checks it is them).
	adminButton = C.Button({
		text = "ADMIN EVENTS (OWNER)",
		role = "danger",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = -1, -- (under its SERVER EVENTS header, above the queue line and the events)
		parent = window.body,
		onActivated = function()
			Controller.open("Admin")
		end,
	})
	adminButton.root.Visible = false
	refreshPasses()
	for _, pass in Shop.PASSES do
		player:GetAttributeChangedSignal(pass.key):Connect(refreshPasses)
	end
end

-- One tap on a pack: what the shop's button does (the server opens Roblox's own purchase prompt).
local function buy(eventId: string)
	local entry = buttons[eventId]
	if not entry or entry.locked then
		return
	end
	if not entry.ready then
		if entry.why == "asking" then
			Toast.show("Getting the price from Roblox. One moment!")
		elseif entry.why == "failed" then
			Toast.show("Roblox didn't send the price. Trying again...")
			local event = Events.byId[eventId]
			if event then
				RobuxPrice.forget(event.productId) -- (a tap really asks again)
			end
			local again = entry.ask
			if again then
				again()
			end
		else
			Toast.show("Not on sale yet. Soon!")
		end
		return
	end
	if state.queued >= Events.MAX_QUEUE then
		Toast.show("The event queue is full. Try again in a moment.")
		return
	end
	entry.locked = true
	refreshButtons()
	buyRemote:FireServer(eventId)
	task.delay(PRESS_LOCK, function()
		entry.locked = false
		refreshButtons()
	end)
end

-- When the packs show (LayoutCheck reads this rule too).
function EventShop.packsShown(phone: boolean, afterFirstMinute: boolean, building: boolean, streamer: boolean): boolean
	return not phone and afterFirstMinute and not building and not streamer
end

local function placePacks()
	local gui = packsGui
	if not gui then
		return
	end
	local column = gui:FindFirstChild("Packs") :: Frame?
	if column then
		HudSlots.apply(column, "Packs", HudSlots.context(false, false))
	end
	-- Off a phone (a phone has them in MENU's shop), not in a new player's first minute (as
	-- WEAPONS and SANDBOX), not while building (its tools have that edge) and not while Streamer
	-- Mode's gift guide is there.
	gui.Enabled = EventShop.packsShown(HudSlots.context(false, false).phone, packsAfterFirstMinute, player:GetAttribute("Building") == true, player:GetAttribute("Streamer") == true)
end

local function buildPacks()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Packs"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)
	local column = Instance.new("Frame")
	column.Name = "Packs"
	column.BackgroundTransparency = 1
	column.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, HudSlots.PACK_GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = column
	local studio = RunService:IsStudio()
	for _, event in Events.list do
		-- Each event's picture (its emoji on its shape, LihFolkUIIcons), as in the shop.
		if not Icons.Fallbacks[event.icon] then
			Icons.Fallbacks[event.icon] = { glyph = event.glyph, shape = "square", color = Color3.fromHex(event.color) } -- (rounded squares, as the HUD's)
		end
	end
	for index = 1, math.min(HudSlots.PACKS, #Events.list) do
		local event = Events.list[index]
		local eventId = event.id
		local card = Instance.new("TextButton")
		card.Name = eventId
		card.Text = ""
		card.Size = UDim2.fromOffset(HudSlots.PACK.X, HudSlots.PACK.Y)
		card.BackgroundColor3 = Theme.Palette.dusk
		card.BackgroundTransparency = 0.12
		card.LayoutOrder = index
		card.Parent = column
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Radius.card)
		corner.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Palette.ink
		stroke.Thickness = Theme.Stroke.panel
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = card
		-- Its own colour down the left edge.
		local edge = Instance.new("Frame")
		edge.Name = "Edge"
		edge.BorderSizePixel = 0
		edge.BackgroundColor3 = Color3.fromHex(event.color)
		edge.Position = UDim2.fromOffset(0, 8)
		edge.Size = UDim2.new(0, 3, 1, -16)
		edge.Parent = card
		local icon = Icons.make(event.icon, UDim2.fromOffset(36, 36))
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 10, 0.5, 0)
		icon.Parent = card
		local name = C.Text("small", event.name, {
			name = "Name",
			scaled = true,
			align = Enum.TextXAlignment.Left,
			size = UDim2.new(1, -(50 + 64), 0, 20),
			position = UDim2.new(0, 50, 0.5, 0),
			anchor = Vector2.new(0, 0.5),
			parent = card,
		})
		local nameFit = name:FindFirstChildOfClass("UITextSizeConstraint")
		if nameFit then
			nameFit.MaxTextSize = 15
			nameFit.MinTextSize = 11
		end
		-- The price: Roblox's Robux mark and the real price (from Roblox, never typed in here).
		local pill = Instance.new("Frame")
		pill.Name = "Price"
		pill.AnchorPoint = Vector2.new(1, 0.5)
		pill.Position = UDim2.new(1, -8, 0.5, 0)
		pill.Size = UDim2.fromOffset(56, 28)
		pill.BackgroundColor3 = Theme.Roles.premium.bottom -- (Robux is gold everywhere: the shop, the catalog's BUY)
		pill.Parent = card
		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 6)
		pillCorner.Parent = pill
		local pillStroke = Instance.new("UIStroke")
		pillStroke.Color = Theme.Palette.ink
		pillStroke.Thickness = 1.5
		pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pillStroke.Parent = pill
		local robux = Icons.make("robux", UDim2.fromOffset(16, 16))
		if robux:IsA("ImageLabel") then
			robux.ImageColor3 = Theme.Palette.ink -- (the kit's mark is pale: tinted dark so it reads, as on BUY)
		end
		robux.AnchorPoint = Vector2.new(0, 0.5)
		robux.Position = UDim2.new(0, 5, 0.5, 0)
		robux.Parent = pill
		local forSale = event.productId ~= 0
		card.Visible = forSale or studio -- (phase 0: no "SOON" card for a product not made yet)
		local price = C.Text("small", if forSale then "..." elseif studio then "TEST" else "SOON", {
			name = "Amount",
			scaled = true,
			size = UDim2.new(1, -25, 1, -6),
			position = UDim2.new(0, 22, 0.5, 0),
			anchor = Vector2.new(0, 0.5),
			parent = pill,
		})
		price.TextColor3 = Theme.Palette.ink
		local priceStroke = price:FindFirstChildOfClass("UIStroke")
		if priceStroke then
			priceStroke.Enabled = false
		end
		local priceFit = price:FindFirstChildOfClass("UITextSizeConstraint")
		if priceFit then
			priceFit.MaxTextSize = 15
			priceFit.MinTextSize = 10
		end
		card.Activated:Connect(function()
			buy(eventId)
		end)
		packs[eventId] = { card = card, price = price }
	end
	gui.Parent = player:WaitForChild("PlayerGui")
	packsGui = gui
	HudSlots.watch(placePacks)
	player:GetAttributeChangedSignal("Building"):Connect(placePacks)
	player:GetAttributeChangedSignal("Streamer"):Connect(placePacks)
	task.spawn(function()
		local Onboarding = require(Client:WaitForChild("OnboardingController")) :: any
		Onboarding.whenFree(function()
			packsAfterFirstMinute = true
			placePacks()
		end)
	end)
end

local function buildShop()
	local window = C.Window({ name = "Events", title = "Shop", theme = "shop", icon = "shop" })
	buildPasses(window)
	queueLabel = C.Text("caption", "", {
		color = Theme.Palette.textMid,
		wrap = true,
		size = UDim2.new(1, 0, 0, 24),
		layoutOrder = 0,
		parent = window.body,
	})
	-- The weekly ADMIN SHOW, counted down (round 3, M9: ScheduleUI), in gold.
	local showLabel = C.Text("caption", "", { color = Theme.Palette.gold, wrap = true, size = UDim2.new(1, 0, 0, 24), layoutOrder = 1, parent = window.body })
	task.spawn(function()
		while true do
			if showLabel.Parent and window.root.Visible then
				showLabel.Text = ScheduleUI.line()
			end
			task.wait(1)
		end
	end)
	showLabel.Text = ScheduleUI.line()
	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = 2
	C.Grid(grid, CARD, SP.md)
	grid.Parent = window.body

	local studio = RunService:IsStudio()
	for _, event in Events.list do
		-- Each event's picture (its emoji on its shape, LihFolkUIIcons) until painted art exists.
		if not Icons.Fallbacks[event.icon] then
			Icons.Fallbacks[event.icon] = { glyph = event.glyph, shape = "square", color = Color3.fromHex(event.color) } -- (rounded squares, as the HUD's)
		end
	end
	for index, event in Events.list do
		local card = C.Card({ name = event.id, featured = index == 1, gap = SP.xs, layoutOrder = index, parent = grid })
		local iconSlot = Instance.new("Frame")
		iconSlot.Name = "IconSlot"
		iconSlot.BackgroundTransparency = 1
		iconSlot.Size = UDim2.new(1, 0, 0, 68)
		iconSlot.LayoutOrder = 1
		iconSlot.Parent = card.content
		if index == 1 then
			C.Pill("FAN FAVOURITE", {
				role = "premium",
				anchor = Vector2.new(0.5, 0.5),
				position = UDim2.new(0.5, 0, 0, 2),
				zIndex = 6,
				parent = card.root,
			})
		end
		local icon = Icons.make(event.icon, UDim2.fromScale(1, 1))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.ZIndex = 2
		icon.Parent = iconSlot
		C.Text("title", event.name, { scaled = true, size = UDim2.new(1, 0, 0, 30), layoutOrder = 2, parent = card.content })
		C.Text("caption", event.blurb, {
			color = Theme.Palette.textMid,
			wrap = true,
			size = UDim2.new(1, 0, 0, 38),
			layoutOrder = 3,
			parent = card.content,
		})
		local forSale = event.productId ~= 0
		card.root.Visible = forSale or studio -- (phase 0: no "SOON" card for a product not made yet)
		local eventId = event.id
		local price = C.CurrencyButton({
			price = if forSale then "..." elseif studio then "TEST" else "SOON",
			currency = "robux",
			size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
			layoutOrder = 4,
			parent = card.content,
			onActivated = function()
				local entry = buttons[eventId]
				if not entry or entry.locked then
					return
				end
				entry.locked = true
				refreshButtons()
				buyRemote:FireServer(eventId)
				task.delay(PRESS_LOCK, function()
					entry.locked = false
					refreshButtons()
				end)
			end,
		})
		local entry: Entry = { button = price.button, ready = studio and not forSale, locked = false, why = if forSale then "asking" elseif studio then nil else "soon" }
		buttons[eventId] = entry
		if forSale then
			-- Never a number typed in here; no price, no button. (Asked again after a failure: on a
			-- tap, and whenever the shop opens.)
			local function ask()
				if entry.why == "asking" and entry.ask then
					return -- (already on its way)
				end
				entry.why = "asking"
				price.setPrice("...")
				local pack = packs[eventId]
				if pack then
					pack.price.Text = "..."
				end
				RobuxPrice.get(event.productId, function(robux: number?)
					price.setPrice(if robux then robux else RobuxPrice.text(nil))
					local p = packs[eventId]
					if p then
						p.price.Text = RobuxPrice.text(robux)
					end
					entry.ready = robux ~= nil
					entry.why = if robux then nil else "failed"
					refreshButtons()
				end)
			end
			ask()
			entry.ask = ask
		end
		if index == 1 then
			window.defaultSelection = price.button.hit
		end
	end
	Controller.register(window)
	-- Opening the shop asks Roblox again for any price it failed to send.
	Controller.onChanged(function(name: string, open: boolean)
		if name == "Events" and open then
			for _, entry in buttons do
				local again = entry.ask
				if entry.why == "failed" and again then
					again()
				end
			end
		end
	end)
	shopHud = Controller.addHudButton({ window = "Events", label = "Shop", icon = "shop", theme = "shop", layoutOrder = 1 })
	refreshButtons()
end

------------------------------------------------------------------------------------------------
-- The banner

local banner: Frame? = nil
local bannerTitle: TextLabel? = nil
local bannerBy: TextLabel? = nil
local bar: any = nil
local shownId: string? = nil
local shownSeconds = -1
local bannerGui: ScreenGui? = nil
local bannerScale: UIScale? = nil

local function buildBanner()
	local gui = Instance.new("ScreenGui")
	gui.Name = "EventBanner"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 30
	gui.Parent = player:WaitForChild("PlayerGui")
	bannerGui = gui

	local holder = Instance.new("Frame")
	holder.Name = "Banner"
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 8)
	holder.Size = UDim2.fromOffset(420, 104)
	holder.BackgroundColor3 = Theme.Palette.dusk
	holder.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = holder
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Palette.ink
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = holder
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, SP.sm)
	pad.PaddingBottom = UDim.new(0, SP.sm)
	pad.PaddingLeft = UDim.new(0, SP.md)
	pad.PaddingRight = UDim.new(0, SP.md)
	pad.Parent = holder
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, SP.xs)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	bannerScale = scale
	-- Phones: never wider than the screen allows.
	local function fit()
		local width = gui.AbsoluteSize.X
		scale.Scale = math.clamp((width - 24) / 420, 0.6, 1)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	bannerBy = C.Text("small", "", { color = Theme.Palette.gold, size = UDim2.new(1, 0, 0, 22), scaled = true, layoutOrder = 1, parent = holder })
	bannerTitle = C.Text("display", "", { size = UDim2.new(1, 0, 0, 36), scaled = true, layoutOrder = 2, parent = holder })
	bar = C.ProgressBar({ value = 1, role = "premium", size = UDim2.new(1, 0, 0, 18), layoutOrder = 3, parent = holder })
	holder.Parent = gui
	banner = holder
end

local function showBanner()
	local holder = banner
	if not holder then
		return
	end
	local id = state.id
	local event = if id then Events.byId[id] else nil
	if not event then
		if shownId then
			-- The event is over: the banner slides back up.
			shownId = nil
			local out = TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -120),
			})
			out:Play()
			out.Completed:Once(function()
				if not shownId then
					holder.Visible = false
				end
			end)
		end
		return
	end
	if shownId ~= id then
		shownId = id
		shownSeconds = -1
		;(bannerTitle :: TextLabel).Text = string.upper(event.name) .. "!"
		local by = state.by or "Someone"
		;(bannerBy :: TextLabel).Text = if state.source == "TikTok"
			then string.upper(by) .. " SENT A GIFT"
			else string.upper(by) .. " SENT"
		holder.Visible = true
		-- Pop in from the top.
		holder.Position = UDim2.new(0.5, 0, 0, -120)
		TweenService:Create(holder, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 8),
		}):Play()
		local camera = Workspace.CurrentCamera
		if camera then
			FxController.localEvent("Event", camera.CFrame.Position, 0, "")
		end
	end
end

local function tickBanner()
	if not shownId or not bar then
		return
	end
	local event = Events.byId[shownId]
	local left = state.endsAt - Workspace:GetServerTimeNow()
	local seconds = math.max(0, math.ceil(left))
	if seconds ~= shownSeconds then
		-- Once a second: the bar steps with the count (no work on the other frames).
		shownSeconds = seconds
		bar.setValue(math.clamp(seconds / event.duration, 0, 1))
		bar.setText(seconds .. "s")
	end
end

-- Where a toast must sit to clear the banner (screen Y), while one is showing.
local function belowBanner(): number
	local gui = bannerGui
	local holder = banner
	if not (gui and holder and shownId and holder.Visible) then
		return 0
	end
	local scale = if bannerScale then bannerScale.Scale else 1
	return gui.AbsolutePosition.Y + 8 + 104 * scale + 8
end

-- What's New: the newest entry, once per version (MoneyService asks; GOT IT tells it seen).
local function buildWhatsNew()
	local entry = Shop.WHATS_NEW[1]
	if not entry then
		return
	end
	local window = C.Window({ name = "WhatsNew", title = "What's New", theme = "rebirth", icon = "star", size = Vector2.new(520, 460) })
	C.Text("title", "Version " .. entry.version, { scaled = true, size = UDim2.new(1, 0, 0, 30), layoutOrder = 0, parent = window.body })
	for i, line in entry.lines do
		C.Text("body", "\u{2022} " .. line, { autoY = true, align = Enum.TextXAlignment.Left, layoutOrder = i, parent = window.body })
	end
	local ok = C.Button({
		text = "GOT IT",
		role = "go",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 100,
		parent = window.body,
		onActivated = function()
			Controller.toggle("WhatsNew")
		end,
	})
	window.defaultSelection = ok.hit
	Controller.register(window)
	Controller.onChanged(function(name, open)
		if name == "WhatsNew" and not open and moneyRemote then
			(moneyRemote :: RemoteEvent):FireServer("SeenNew")
		end
	end)
end

-- The owner's admin events: every server event, free, for everyone (checked on the server).
local function buildAdmin()
	local window = C.Window({ name = "Admin", title = "Admin", theme = "settings", icon = "crown", size = Vector2.new(560, 620) })
	-- Round 3, M7: the Christmas theme's switch (AdminService checks it is the owner; kept for every
	-- server): AUTO follows the dates (on until 6 January, then 1 December - 6 January), ON, OFF.
	C.SectionHeader("CHRISTMAS THEME", "settings", -5, window.body)
	-- Three choices side by side, the one in force lit (green); a line says whether it is on now.
	local admin = Net.event(Net.Names.Admin)
	local themeMode = "auto"
	local themeOn = false
	local row = C.Row({ height = Theme.Size.buttonH, gap = Theme.Space.sm, layoutOrder = -4, parent = window.body })
	local layout = row:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	end
	local choices: { [string]: any } = {}
	for i, m in { "auto", "on", "off" } do
		choices[m] = C.Button({
			text = string.upper(m),
			role = "neutral",
			size = UDim2.new(1 / 3, -Theme.Space.sm, 0, Theme.Size.buttonH),
			layoutOrder = i,
			parent = row,
			onActivated = function()
				admin:FireServer("Theme", m) -- (the lit one again: kept for every server again)
			end,
		})
	end
	-- Round 4: ALL WEAPONS FOR EVERYONE HERE, while the owner is in this server (AdminService; nothing
	-- is kept: it ends when the owner leaves or taps OFF). Everyone here is told why.
	local PARTY_ORDER = -60 -- (first in the window)
	C.SectionHeader("ALL WEAPONS FOR EVERYONE HERE", "settings", PARTY_ORDER, window.body)
	local partyRow = C.Row({ height = Theme.Size.buttonH, gap = Theme.Space.sm, layoutOrder = PARTY_ORDER + 1, parent = window.body })
	local partyButtons: { [boolean]: any } = {}
	for i, on in { true, false } do
		partyButtons[on] = C.Button({
			text = if on then "ON" else "OFF",
			role = "neutral",
			size = UDim2.new(1 / 2, -Theme.Space.sm, 0, Theme.Size.buttonH),
			layoutOrder = i,
			parent = partyRow,
			onActivated = function()
				admin:FireServer("AllWeapons", on)
			end,
		})
	end
	local partyLabel = C.Text("caption", "", { color = Theme.Palette.textMid, wrap = true, size = UDim2.new(1, 0, 0, 30), layoutOrder = PARTY_ORDER + 2, parent = window.body })
	local function drawParty()
		local on = Workspace:GetAttribute("OwnerParty") == true
		partyButtons[true].setRole(if on then "go" else "neutral")
		partyButtons[false].setRole(if on then "neutral" else "go")
		partyLabel.Text = if on
			then "ON: everyone in this server has every weapon while you are here. Nothing is kept."
			else "Off. ON gives everyone here every weapon while you are in the server, and tells them why."
	end
	Workspace:GetAttributeChangedSignal("OwnerParty"):Connect(drawParty)
	drawParty()
	local nowLabel = C.Text("body", "", { size = UDim2.new(1, 0, 0, 22), layoutOrder = -3, parent = window.body })
	local function drawTheme()
		for m, button in choices do
			button.setRole(if m == themeMode then "go" else "neutral")
		end
		nowLabel.Text = if themeOn then "Christmas is ON here now" else "Christmas is OFF here now"
	end
	-- (What every screen is told, so it is right whatever changed it: these buttons, another server,
	-- or the date.)
	local function readTheme()
		local m = Workspace:GetAttribute("ChristmasMode")
		if m == "auto" or m == "on" or m == "off" then
			themeMode = m
		end
		themeOn = Workspace:GetAttribute("Christmas") == true
		drawTheme()
	end
	Workspace:GetAttributeChangedSignal("ChristmasMode"):Connect(readTheme)
	Workspace:GetAttributeChangedSignal("Christmas"):Connect(readTheme)
	C.Text("caption", "AUTO: on until 6 January, then every year 1 December - 6 January. ON and OFF: always, until you change it.", { color = Theme.Palette.textMid, wrap = true, size = UDim2.new(1, 0, 0, 30), layoutOrder = -2, parent = window.body })
	-- Round 3, M9: the launch. The passes' fun (ULTRA's no-wait, VIP's faster eggs) free for
	-- everyone for a while; MoneyService keeps it for every server.
	C.SectionHeader("LAUNCH: FREE PASSES", "settings", -20, window.body)
	local launchRow = C.Row({ height = Theme.Size.buttonH, gap = Theme.Space.sm, layoutOrder = -19, parent = window.body })
	-- (Like the theme row: OFF is lit while the passes are not free; while they are, the line under
	-- the row says until when, in gold, and a day button sets a new end from now.)
	local launchOff
	for i, days in { 0, 3, 7, 14 } do
		local button = C.Button({
			text = if days == 0 then "OFF" else days .. " DAYS",
			role = "neutral",
			size = UDim2.new(1 / 4, -Theme.Space.sm, 0, Theme.Size.buttonH),
			layoutOrder = i,
			parent = launchRow,
			onActivated = function()
				admin:FireServer("FreePasses", days)
			end,
		})
		if days == 0 then
			launchOff = button
		end
	end
	local launchLabel = C.Text("body", "", { size = UDim2.new(1, 0, 0, 22), layoutOrder = -18, parent = window.body })
	local function drawLaunch()
		local untilAt = Workspace:GetAttribute("PassesFreeUntil")
		local on = type(untilAt) == "number" and untilAt > Workspace:GetServerTimeNow()
		launchLabel.Text = if on
			then "ON: free for everyone until " .. tostring(os.date("%a %d %b %H:%M", untilAt))
			else "Off: the passes are for those who buy them"
		launchLabel.TextColor3 = if on then Color3.fromRGB(255, 205, 70) else Theme.Palette.textHi
		if launchOff then
			launchOff.setRole(if on then "neutral" else "go")
		end
	end
	Workspace:GetAttributeChangedSignal("PassesFreeUntil"):Connect(drawLaunch)
	drawLaunch()
	-- (A launch that runs out on its own changes no attribute: the row looks again every few seconds
	-- while the window is open.)
	task.spawn(function()
		while window.root.Parent do
			task.wait(5)
			if window.root.Visible then
				drawLaunch()
			end
		end
	end)
	-- Round 3, M8: TROLL A PLAYER. Pick someone here, then what happens to them (AdminService checks
	-- it is the owner and runs it; everything wears off and never touches their things).
	local TROLL_ORDER = -40 -- (first in the window: above the theme and the free events)
	C.SectionHeader("TROLL A PLAYER", "settings", TROLL_ORDER, window.body)
	C.Text("caption", "Pick a player, then what happens. All of it wears off by itself and never touches their stuff.", { color = Theme.Palette.textMid, wrap = true, size = UDim2.new(1, 0, 0, 24), layoutOrder = TROLL_ORDER + 1, parent = window.body })
	local function gridFrame(name: string, order: number, cellH: number): Frame
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.LayoutOrder = order
		frame.Parent = window.body
		local layout = C.Grid(frame, Vector2.new(100, cellH), Theme.Space.sm)
		layout.CellSize = UDim2.new(0.5, -Theme.Space.sm, 0, cellH) -- (two a row at any window width)
		return frame
	end
	-- The players: two a row, at most PLAYER_ROWS rows tall (more scroll inside), so the actions
	-- stay in view under them however full the server is.
	local PLAYER_ROWS, PLAYER_H = 2, 48
	local playersFrame = Instance.new("ScrollingFrame")
	playersFrame.Name = "TrollPlayers"
	playersFrame.BackgroundTransparency = 1
	playersFrame.BorderSizePixel = 0
	playersFrame.Size = UDim2.new(1, 0, 0, PLAYER_H)
	playersFrame.CanvasSize = UDim2.new()
	playersFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playersFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	playersFrame.ScrollBarThickness = 6
	playersFrame.LayoutOrder = TROLL_ORDER + 2
	playersFrame.Parent = window.body
	local playerLayout = C.Grid(playersFrame, Vector2.new(100, PLAYER_H), Theme.Space.sm)
	playerLayout.CellSize = UDim2.new(0.5, -Theme.Space.sm - 4, 0, PLAYER_H)
	local actionsFrame = gridFrame("TrollActions", TROLL_ORDER + 3, Theme.Size.buttonH)
	local logLabel = C.Text("caption", "", { color = Theme.Palette.textMid, wrap = true, size = UDim2.new(1, 0, 0, 0), layoutOrder = TROLL_ORDER + 4, parent = window.body })
	logLabel.AutomaticSize = Enum.AutomaticSize.Y
	local target: number? = nil
	local playerButtons: { [number]: any } = {}
	local actionButtons: { any } = {}
	local function drawTargets()
		for id, button in playerButtons do
			button.setRole(if id == target then "go" else "neutral")
		end
		for _, button in actionButtons do
			button.setRole(if target then "danger" else "neutral")
		end
	end
	local TROLLS = {
		{ id = "Ragdoll", name = "RAGDOLL" }, { id = "Fling", name = "FLING" },
		{ id = "Freeze", name = "FREEZE 5S" }, { id = "Spin", name = "SPIN" },
		{ id = "Small", name = "TINY" }, { id = "Giant", name = "GIANT" },
		{ id = "Launch", name = "SKY LAUNCH" }, { id = "Rain", name = "DUMMY RAIN" },
		{ id = "Chase", name = "NPC CHASE" }, { id = "Present", name = "PRESENT" },
	}
	for i, t in TROLLS do
		actionButtons[i] = C.Button({
			text = t.name,
			role = "neutral",
			size = UDim2.fromOffset(100, Theme.Size.buttonH),
			layoutOrder = i,
			parent = actionsFrame,
			onActivated = function()
				if target then
					admin:FireServer("Troll", { target = target, action = t.id })
				else
					Toast.show("Pick a player first")
				end
			end,
		})
	end
	-- SPECTATE (10 Nov 2026): the camera follows the picked player (Spectate; NEXT and STOP on its
	-- bar). The window closes so the view is clear.
	C.Button({
		text = "\u{1F441} SPECTATE",
		role = "go",
		size = UDim2.fromOffset(100, Theme.Size.buttonH),
		layoutOrder = #TROLLS + 1,
		parent = actionsFrame,
		onActivated = function()
			local who = if target then Players:GetPlayerByUserId(target) else nil
			if who then
				Controller.closeAll()
				require(script.Parent:WaitForChild("Spectate")).watch(who)
			else
				Toast.show("Pick a player first")
			end
		end,
	})
	local function drawPlayers(list: { any })
		local seen: { [number]: boolean } = {}
		for i, entry in list do
			local id = tonumber(entry.id)
			if id and type(entry.name) == "string" then
				seen[id] = true
				local button = playerButtons[id]
				if not button then
					local userId = id
					-- (The name the game shows, and the user name when it differs: two players with
					-- the same display name are never one button.)
					local user = if type(entry.user) == "string" and entry.user ~= entry.name then " (@" .. entry.user .. ")" else ""
					button = C.Button({
						text = entry.name .. user,
						role = "neutral",
						size = UDim2.fromOffset(100, 48),
						parent = playersFrame,
						onActivated = function()
							target = if target == userId then nil else userId
							drawTargets()
						end,
					})
					playerButtons[id] = button
				end
				button.root.LayoutOrder = i
			end
		end
		for id, button in playerButtons do
			if not seen[id] then
				button.root:Destroy()
				playerButtons[id] = nil
				if target == id then
					target = nil
				end
			end
		end
		local count = 0
		for _ in playerButtons do
			count += 1
		end
		local rows = math.clamp(math.ceil(count / 2), 1, PLAYER_ROWS)
		playersFrame.Size = UDim2.new(1, 0, 0, rows * PLAYER_H + (rows - 1) * Theme.Space.sm)
		drawTargets()
	end
	admin.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "Notice" and type(data) == "string" then
			Toast.show(data, Color3.fromRGB(255, 110, 110))
		elseif kind == "State" and type(data) == "table" then
			local d = data :: any
			if type(d.players) == "table" then
				drawPlayers(d.players)
			end
			if type(d.log) == "table" then
				local shown = {}
				for i, line in d.log do
					if type(line) == "string" then
						table.insert(shown, line)
					end
				end
				logLabel.Text = if #shown > 0 then "RECENT: " .. table.concat(shown, "  ·  ") else ""
			end
		end
	end)
	admin:FireServer("Hello")
	readTheme()
	C.SectionHeader("FREE EVENTS", "settings", -1, window.body)
	C.Text("caption", "Starts the event for everyone in this server, free. Owner only.", { color = Theme.Palette.textMid, wrap = true, size = UDim2.new(1, 0, 0, 24), layoutOrder = 0, parent = window.body })
	for index, event in Events.list do
		local id = event.id
		C.Button({
			text = string.upper(event.name),
			role = "danger",
			size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
			layoutOrder = index,
			parent = window.body,
			onActivated = function()
				if moneyRemote then
					(moneyRemote :: RemoteEvent):FireServer("Admin", id)
				end
			end,
		})
	end
	Controller.register(window)
end

function EventShop.start()
	buyRemote = Net.event(Net.Names.EventBuy)
	Controller.start()
	buildPacks()
	buildShop()
	buildBanner()
	buildWhatsNew()
	moneyRemote = Net.event(Net.Names.Money)
	local money = moneyRemote :: RemoteEvent
	money.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		local d = if type(data) == "table" then data :: any else {}
		if kind == "Hello" then
			isOwner = d.owner == true
			if isOwner and adminButton then
				buildAdmin()
				adminButton.root.Visible = true
			end
		elseif kind == "Owned" then
			local pass = Shop.byKey[tostring(d.key)]
			Toast.show(string.format("%s is yours! Thank you!", if pass then pass.name else "It"), Color3.fromRGB(255, 210, 74))
			refreshPasses()
		elseif kind == "Free" then
			freeEnds = tonumber(d.ends) or (Workspace:GetServerTimeNow() + (tonumber(d.seconds) or 180))
			local seconds = tonumber(d.seconds) or 180
			Toast.show(if d.fresh == false
				then string.format("Free ULTRA carries on: %d:%02d left!", seconds // 60, seconds % 60)
				else string.format("5 MINUTES GIFT: FREE ULTRA for %d minutes! No waiting: spam away!", math.floor(seconds / 60)), Color3.fromRGB(255, 160, 60))
		elseif kind == "FreeOver" then
			freeEnds = 0
			Toast.show("Your free ULTRA is over. Get it to keep the speed!", Color3.fromRGB(255, 160, 60))
		elseif kind == "Notice" and type(d.text) == "string" then
			Toast.show(d.text)
		elseif kind == "WhatsNew" then
			if not Controller.isOpen("WhatsNew") then
				Controller.open("WhatsNew")
			end
		elseif kind == "Admin" then
			Toast.show(string.format(if d.queued then "ADMIN ABUSE! %s queued %s for everyone!" else "ADMIN ABUSE! %s started %s for everyone!", tostring(d.by), tostring(d.event)), Color3.fromRGB(255, 110, 110), belowBanner)
		elseif kind == "Refused" and type(d.text) == "string" then
			Toast.show(d.text)
		end
	end)
	money:FireServer("Hello")
	-- Free ULTRA's clock: on the Shop launcher (MENU on a phone) and on the ULTRA card, once a
	-- second while it runs, so everyone sees how much is left of what the pass would keep.
	local shown = -1
	RunService.Heartbeat:Connect(function()
		local left = if freeEnds > 0 and player:GetAttribute("Ultra") ~= true then math.max(0, math.ceil(freeEnds - Workspace:GetServerTimeNow())) else 0
		if left == shown then
			return
		end
		shown = left
		local clock = string.format("%d:%02d", left // 60, left % 60)
		-- (A gold pill on the launcher: the launcher keeps its name, the clock reads at 15 px.)
		if shopHud then
			shopHud.setTag(if left > 0 then clock else nil)
		end
		local blurb = passBlurbs.Ultra
		local launchUntil = Workspace:GetAttribute("PassesFreeUntil")
		local launch = type(launchUntil) == "number" and launchUntil > Workspace:GetServerTimeNow()
		if blurb then
			blurb.Text = if launch then "FREE for everyone until " .. tostring(os.date("%a %d %b", launchUntil)) .. "! Keep it:"
				elseif left > 0 then "FREE for " .. clock .. " more! Keep it:"
				else Shop.byKey.Ultra.blurb
		end
	end)
	Net.event(Net.Names.EventState).OnClientEvent:Connect(function(incoming: unknown)
		if type(incoming) ~= "table" then
			return
		end
		local s = incoming :: { [string]: any }
		state = {
			id = if type(s.id) == "string" then s.id else nil,
			by = if type(s.by) == "string" then s.by else nil,
			source = if type(s.source) == "string" then s.source else nil,
			endsAt = if type(s.endsAt) == "number" then s.endsAt else 0,
			queued = if type(s.queued) == "number" then s.queued else 0,
		}
		refreshButtons()
		showBanner()
	end)
	-- What happened to your own event: queued, next, or the queue was full.
	Net.event(Net.Names.EventNotice).OnClientEvent:Connect(function(text: unknown, kind: unknown)
		if type(text) == "string" then
			Toast.show(text, if kind == "warn" then WARN else nil, belowBanner)
		end
	end)
	RunService.Heartbeat:Connect(tickBanner)
end

return EventShop
