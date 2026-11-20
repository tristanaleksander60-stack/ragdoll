--!strict
-- Progress on screen (phase F): the EGGS launcher (a badge when an egg waits), the window with
-- your rank, takedowns and the way to the next rank and the next egg, your eggs (OPEN) and your
-- hats (tap one to wear it), and the egg opening itself: the egg drops in, wobbles, wobbles harder,
-- cracks open in a burst of light, and what it held: a weapon you did not have (round 2, N4: in
-- the weapon's colour, with its picture), or, once you own them all, a hat (its rarity's colour). Takedowns,
-- rank-ups and found eggs are told with a toast. Everything here only draws what the server says.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Progress = require(Shared:WaitForChild("Progress"))
local Toys = require(Shared:WaitForChild("Toys"))
local UiRarity = require(Shared:WaitForChild("UiRarity"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))
local Notify = require(Client:WaitForChild("Notify")) :: any -- V6-1: what pops up by itself goes through the notification centre
local KitStyle = require(Client:WaitForChild("KitStyle"))
local ToolPicture = require(script.Parent:WaitForChild("ToolPicture"))
local HudMenu = require(Client:WaitForChild("HudMenu"))
local PokeController = require(Client:WaitForChild("PokeController"))
local ReplayController = require(Client:WaitForChild("ReplayController"))
local OnboardingController = require(Client:WaitForChild("OnboardingController"))
local SessionClient = require(Client:WaitForChild("SessionClient"))

local player = Players.LocalPlayer
local P = Theme.Palette
local SP = Theme.Space
local HAT_CELL = Vector2.new(150, 112)
local OPEN_WAIT = 3 -- s: no answer to an Open by then (no egg after all): the button is free again
local waitingOpen = false

local ProgressUI = {}

-- The egg offer (10 Nov 2026, from the launch numbers: not one new player had opened an egg, even
-- after 14 minutes, while the egg sat in Rank & Eggs inside MENU). Whenever an egg comes and the
-- moment is calm, a small card asks to open it now; a weapon from it goes straight onto the bar.
ProgressUI.OFFER = Vector2.new(400, 270) -- the card's window
ProgressUI.OFFER_GAP = 45 -- s between two offers that nobody asked for
ProgressUI.OFFER_FIRST = 3.5 -- s after the first minute's unlock (an egg is waiting already)
local offerText: TextLabel? = nil
local lastOffer = -math.huge
local offerWaiting = false
local freeNow = false
ProgressUI.OFFER_QUIET = 2.5 -- s without a tap or a click in the world before it may come
local lastAction = -math.huge
type GoalView = { text: string, need: number, got: number, claimed: boolean }
type State = { takedowns: number, playSeconds: number?, eggs: number, eggEvery: number?, hats: { string }, hat: string, best: { [string]: number }, streak: number?, dailyToday: boolean?, goals: { list: { GoalView }, bonus: boolean }?, streakEggs: { number }?, loading: boolean? }

local remote: RemoteEvent
local state: State = { takedowns = 0, eggs = 0, hats = {}, hat = "", best = {} }
local hud: any = nil
local rankLabel: TextLabel? = nil
local takedownLabel: TextLabel? = nil
local rankBar: any = nil
local eggBar: any = nil
local eggLabel: TextLabel? = nil
local openButton: any = nil
local bestLabel: TextLabel? = nil
local dailyLabel: TextLabel? = nil
local pips: { { frame: Frame, label: TextLabel, day: TextLabel } } = {}
local goalRows: { { text: TextLabel, bar: any, claim: any } } = {}
local bonusButton: any = nil
local hatButtons: { [string]: any } = {}
local opening = false
local overlay: Frame? = nil

local function owns(id: string): boolean
	return table.find(state.hats, id) ~= nil
end

local function redraw()
	local rank, nextRank = Progress.rankOf(state.takedowns)
	if rankLabel then
		rankLabel.Text = string.upper(rank.name)
	end
	if takedownLabel then
		takedownLabel.Text = string.format("%d takedowns", state.takedowns)
			.. (if nextRank then string.format("  \u{00B7}  %d to %s", nextRank.at - state.takedowns, nextRank.name) else "  \u{00B7}  top rank")
	end
	if rankBar then
		local span = if nextRank then nextRank.at - rank.at else 1
		rankBar.setValue(if nextRank then (state.takedowns - rank.at) / span else 1)
	end
	-- (The server says how often an egg comes for this player: VIP finds them sooner.)
	local every = state.eggEvery or Progress.EGG_EVERY
	local toEgg = state.takedowns % every
	if eggBar then
		eggBar.setValue(toEgg / every)
	end
	if eggLabel then
		eggLabel.Text = if state.eggs > 0
			then string.format("%d egg%s to open!", state.eggs, if state.eggs == 1 then "" else "s")
			else string.format("Next egg in %d takedowns", every - toEgg)
	end
	if openButton then
		openButton.setEnabled(state.eggs > 0 and not opening)
		openButton.setRole(if state.eggs > 0 then "go" else "locked")
	end
	-- The 7-day calendar: today's day of the streak lit, the eggs each day gives.
	local cal = state.streakEggs or { 1, 1, 2, 1, 1, 2, 3 }
	local streakNow = math.max(1, state.streak or 1)
	local todayPip = ((streakNow - 1) % #cal) + 1
	for i, pip in pips do
		local done = i < todayPip or (i == todayPip and state.dailyToday == true)
		pip.frame.BackgroundColor3 = if i == todayPip then Color3.fromRGB(255, 154, 205) elseif done then Color3.fromRGB(110, 70, 120) else Color3.fromRGB(46, 40, 70)
		pip.label.Text = string.format("%d\u{1F95A}", cal[i] or 1)
		pip.label.TextColor3 = if i == todayPip then Color3.fromRGB(30, 16, 40) else Color3.new(1, 1, 1)
		pip.day.TextColor3 = pip.label.TextColor3
	end
	-- Today's goals.
	local goals = state.goals
	for i, row in goalRows do
		local g = goals and goals.list[i]
		row.text.Text = if g then g.text else "..."
		row.bar.setValue(if g then math.clamp(g.got / g.need, 0, 1) else 0)
		row.bar.setText(if g then string.format("%d / %d", math.min(g.got, g.need), g.need) else "")
		local ready = g ~= nil and not g.claimed and g.got >= g.need
		row.claim.setText(if g and g.claimed then "DONE" elseif ready then "CLAIM" else "1 \u{1F95A}")
		row.claim.setRole(if g and g.claimed then "done" elseif ready then "go" else "locked")
		row.claim.setEnabled(ready)
	end
	if bonusButton then
		local all = goals ~= nil and goals.list[1] ~= nil and goals.list[1].claimed and goals.list[2].claimed and goals.list[3].claimed
		local got = goals ~= nil and goals.bonus
		bonusButton.setText(if got then "BONUS EGG CLAIMED" elseif all then "CLAIM THE BONUS EGG" else "ALL 3 DONE: A BONUS EGG")
		bonusButton.setRole(if got then "done" elseif all then "go" else "locked")
		bonusButton.setEnabled(all and not got)
	end
	if dailyLabel then
		-- The reason to come back tomorrow, in the window itself.
		local streak = state.streak or 0
		local nextDay = streak + 1
		local nextEggs = cal[((nextDay - 1) % #cal) + 1] or 1
		dailyLabel.Text = if state.dailyToday
			then string.format("Daily egg: day %d in a row. Tomorrow: %d egg%s!", math.max(1, streak), nextEggs, if nextEggs > 1 then "s" else "")
			elseif state.loading then "Your daily egg comes once your progress has loaded"
			else "Your daily egg is on its way!"
	end
	if bestLabel then
		bestLabel.Text = string.format("Best: Red Light %d  \u{00B7}  Shoot 'em %d", state.best.RLGL or 0, state.best.Shoot or 0)
	end
	-- (The badge: an egg to open, or a goal or the bonus to claim.)
	local claimable = false
	if goals then
		for _, g in goals.list do
			if not g.claimed and g.got >= g.need then
				claimable = true
			end
		end
		local l = goals.list
		if l[1] and l[1].claimed and l[2].claimed and l[3].claimed and not goals.bonus then
			claimable = true
		end
	end
	if hud then
		hud.setBadge(state.eggs > 0 or claimable)
	end
	HudMenu.setBadge("Eggs", state.eggs > 0 or claimable)
	for id, button in hatButtons do
		local mine = owns(id)
		local worn = state.hat == id
		button.setEnabled(mine)
		button.setRole(if worn then "done" elseif mine then "neutral" else "locked")
		button.setText(if worn then "WEARING" elseif mine then "WEAR" else "???")
	end
end

local offerEgg: (force: boolean) -> ()

-- The egg: drops in, wobbles, cracks, a burst of light, then the card of what it held.
local function playOpening(result: { kind: string?, id: string, name: string, rarity: string?, new: boolean })
	local root = overlay
	if not root then
		return
	end
	local weapon = if result.kind == "Weapon" then Toys.byId[result.id] else nil
	local rarity = if weapon
		then { color = if KitStyle.V2 then UiRarity.of(weapon).color else weapon.color } -- (UI v2: the card's rarity colour)
		else (Progress.RARITY :: any)[result.rarity or ""] or Progress.RARITY.Common
	root.Visible = true
	root.BackgroundTransparency = 1
	for _, child in root:GetChildren() do
		child:Destroy()
	end
	TweenService:Create(root, TweenInfo.new(0.25), { BackgroundTransparency = 0.35 }):Play()
	local egg = Instance.new("Frame")
	egg.AnchorPoint = Vector2.new(0.5, 0.5)
	egg.Position = UDim2.fromScale(0.5, -0.2)
	egg.Size = UDim2.fromOffset(120, 150)
	egg.BackgroundColor3 = Color3.fromRGB(255, 244, 220)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = egg
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = Color3.fromRGB(5, 6, 8)
	stroke.Parent = egg
	-- Spots, so it reads as an egg.
	for i, spot in { { 0.3, 0.3, 26 }, { 0.68, 0.48, 20 }, { 0.38, 0.72, 16 } } do
		local dot = Instance.new("Frame")
		dot.Name = "Spot" .. i
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(spot[1], spot[2])
		dot.Size = UDim2.fromOffset(spot[3], spot[3])
		dot.BackgroundColor3 = Color3.fromRGB(255, 178, 90)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = dot
		dot.Parent = egg
	end
	egg.Parent = root
	local drop = TweenService:Create(egg, TweenInfo.new(0.45, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.45) })
	drop:Play()
	drop.Completed:Wait()
	-- Three wobbles, each harder.
	for i = 1, 3 do
		local angle = 8 * i
		for _, a in { angle, -angle, 0 } do
			local t = TweenService:Create(egg, TweenInfo.new(0.07, Enum.EasingStyle.Sine), { Rotation = a })
			t:Play()
			t.Completed:Wait()
		end
		C.playSound("tick", 0.9 + 0.15 * i) -- (V8-0.9: each wobble ticks, higher each time)
		task.wait(0.18)
	end
	-- Crack: a burst of light in the rarity's colour, the egg pops away.
	C.Sunburst({ size = UDim2.fromOffset(520, 520), position = UDim2.fromScale(0.5, 0.45), anchor = Vector2.new(0.5, 0.5), color = rarity.color, parent = root })
	C.playSound("click")
	TweenService:Create(egg, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = UDim2.fromOffset(0, 0) }):Play()
	-- The card.
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.45)
	card.Size = UDim2.fromOffset(0, 0)
	card.BackgroundColor3 = P.duskRaised
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 18)
	cc.Parent = card
	local cs = Instance.new("UIStroke")
	cs.Thickness = 5
	cs.Color = rarity.color
	cs.Parent = card
	card.ZIndex = 5
	local function text(t: string, y: number, h: number, color: Color3, font: Font)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.new(0, 12, 0, y)
		l.Size = UDim2.new(1, -24, 0, h)
		l.FontFace = font
		l.TextScaled = true
		l.TextColor3 = color
		l.Text = t
		l.ZIndex = 6
		local st = Instance.new("UIStroke")
		st.Thickness = 2
		st.Color = Color3.fromRGB(5, 6, 8)
		st.Parent = l
		l.Parent = card
	end
	local height = 140
	if weapon then
		-- A weapon: its picture at the top of the card (inside it: nothing reaches past the card
		-- on a short phone), its name, and where it is now.
		height = 200
		local icon = ToolPicture.make(weapon.id, UDim2.fromOffset(60, 60), nil, true)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 10)
		icon.ZIndex = 6
		for _, d in icon:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 7 -- (over the card's face: the overlay layers by ZIndex across the screen)
			end
		end
		icon.Parent = card
		if KitStyle.V2 then
			-- (UI v2: the word for its rarity, in its colour, as on its catalog card.)
			local r = UiRarity.of(weapon)
			text("NEW " .. r.label .. " WEAPON", 74, 26, r.color, Theme.Fonts.display)
		else
			text("NEW WEAPON", 74, 26, Color3.fromRGB(255, 210, 74), Theme.Fonts.display)
		end
		text(weapon.label, 106, 44, Color3.new(1, 1, 1), Theme.Fonts.display)
		text("Yours to keep. Going on your bar now!", 158, 24, P.textMid, Theme.Fonts.body)
	else
		text(string.upper(result.rarity or "Common"), 14, 26, rarity.color, Theme.Fonts.display)
		text(result.name, 46, 44, Color3.new(1, 1, 1), Theme.Fonts.display)
		text(if result.new then "NEW HAT! Now on your head." else "You have this one already.", 98, 24, P.textMid, Theme.Fonts.body)
	end
	card.Parent = root
	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(300, height) }):Play()
	task.wait(2.2)
	TweenService:Create(root, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = UDim2.fromOffset(0, 0) }):Play()
	task.wait(0.32)
	root.Visible = false
	for _, child in root:GetChildren() do
		child:Destroy()
	end
	-- One egg at a time: the next can be opened once this one has played out.
	opening = false
	redraw()
	-- A weapon goes straight onto the bar, in hand (or, with a full bar, the pick of its slot).
	if weapon and not PokeController.firstMinute() then
		-- (V8-0.3: a prize lands in the hand: no pick-a-slot step.)
		if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).V8_HAND_RULES then
			PokeController.autoEquip(weapon.id, true)
		else
			PokeController.equip(weapon.id)
		end
	end
	-- More eggs: offered again at once (one tap each).
	if state.eggs > 0 then
		offerEgg(true)
	end
end

local function openEgg()
	if opening or state.eggs <= 0 then
		return
	end
	opening = true
	waitingOpen = true
	redraw()
	remote:FireServer("Open")
	task.delay(OPEN_WAIT, function()
		if waitingOpen then
			waitingOpen = false
			opening = false
			redraw()
		end
	end)
end

-- A calm moment for the offer: past the first minute, no replay, not building, not opening, not
-- picking a slot, and neither it nor Rank & Eggs open already.
local function calm(): boolean
	return freeNow
		and time() >= Config.QUIET_START -- (phase 0: never in a visit's first 90 s)
		and not opening
		and not PokeController.firstMinute()
		and not PokeController.isPicking() -- (a won weapon waits for its slot on a full bar)
		and not ReplayController.isPlaying()
		and player:GetAttribute("Building") ~= true
		and Controller.getCurrent() == nil -- (never over another window: the shop mid-purchase, settings...)
		and os.clock() - lastAction >= ProgressUI.OFFER_QUIET -- (nor in the middle of a fight)
end

function offerEgg(force: boolean)
	if offerWaiting or state.eggs <= 0 or Controller.isOpen("EggReady") then
		return
	end
	if not force and os.clock() - lastOffer < ProgressUI.OFFER_GAP then
		return
	end
	offerWaiting = true
	task.spawn(function()
		-- (Never given up: it waits for the first calm moment, however long the player keeps busy;
		-- an egg opened meanwhile, or the card already up, ends the wait. Audit fix: a busy player
		-- never saw it.)
		while not calm() and state.eggs > 0 do
			task.wait(1)
		end
		-- (offerWaiting stays set until the card is up or not needed: one waiter at a time.)
		if state.eggs <= 0 or Controller.isOpen("EggReady") then
			offerWaiting = false
			return
		end
		lastOffer = os.clock()
		SessionClient.eggCard()
		if offerText then
			offerText.Text = if state.eggs == 1
				then "You have a FREE egg!"
				else string.format("You have %d FREE eggs!", state.eggs)
		end
		-- (V6-1: one big pop-up at a time, a gap between them, never over a window the player opened.)
		-- (Never given up: it waits for its turn, then for calm again, as often as it takes.)
		while true do
			Notify.waitBig("EggReady")
			if state.eggs <= 0 or Controller.isOpen("EggReady") then
				offerWaiting = false
				Notify.releaseBig("EggReady")
				return
			end
			if calm() and Controller.getCurrent() == nil then
				break
			end
			Notify.releaseBig("EggReady")
			task.wait(2)
		end
		offerWaiting = false
		Controller.open("EggReady")
	end)
end

local function buildOffer()
	local window = C.Window({ name = "EggReady", title = "Free egg!", theme = "daily", icon = "gift", size = ProgressUI.OFFER })
	offerText = C.Text("title", "You have a FREE egg!", { scaled = true, size = UDim2.new(1, 0, 0, 34), layoutOrder = 1, parent = window.body })
	C.Text("body", "A new weapon is inside. Open it now and it goes straight onto your bar.", { autoY = true, wrap = true, layoutOrder = 2, parent = window.body })
	local open = C.Button({
		text = "\u{1F95A} OPEN IT!",
		role = "go",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 3,
		parent = window.body,
		onActivated = function()
			Controller.toggle("EggReady")
			openEgg()
		end,
	})
	-- (No LATER button: the window's own X closes it, and a short phone keeps OPEN IT! in view.)
	window.defaultSelection = open.hit
	Controller.register(window)
end

local function build()
	buildOffer()
	local window = C.Window({ name = "Eggs", title = "Rank & Eggs", theme = "daily", icon = "gift" })
	-- Rank.
	C.SectionHeader("YOUR RANK", "daily", 0, window.body)
	local rankCard = C.Card({ name = "Rank", gap = SP.xs, layoutOrder = 1, parent = window.body, size = UDim2.new(1, 0, 0, 120) })
	rankLabel = C.Text("title", "ROOKIE", { scaled = true, size = UDim2.new(1, 0, 0, 32), layoutOrder = 1, parent = rankCard.content })
	takedownLabel = C.Text("body", "", { color = P.textMid, size = UDim2.new(1, 0, 0, 22), layoutOrder = 2, parent = rankCard.content })
	rankBar = C.ProgressBar({ layoutOrder = 3, parent = rankCard.content })
	-- Eggs.
	local eggCard = C.Card({ name = "EggCard", featured = true, gap = SP.xs, layoutOrder = 2, parent = window.body, size = UDim2.new(1, 0, 0, 150) })
	eggLabel = C.Text("title", "", { scaled = true, size = UDim2.new(1, 0, 0, 30), layoutOrder = 1, parent = eggCard.content })
	eggBar = C.ProgressBar({ layoutOrder = 2, parent = eggCard.content })
	openButton = C.Button({ text = "OPEN EGG", role = "go", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 3, parent = eggCard.content, onActivated = openEgg })
	bestLabel = C.Text("body", "", { color = P.textMid, size = UDim2.new(1, 0, 0, 24), layoutOrder = 3, parent = window.body })
	dailyLabel = C.Text("body", "", { color = Color3.fromRGB(255, 154, 205), wrap = true, size = UDim2.new(1, 0, 0, 40), layoutOrder = -10, parent = window.body }) -- (under the calendar it speaks of)
	-- Today (round 3, M9): the 7-day calendar and the day's three goals.
	C.SectionHeader("TODAY", "daily", -12, window.body) -- (first: what to do today, the reason to come back)
	local calRow = C.Row({ height = 52, gap = SP.xs, layoutOrder = -11, parent = window.body })
	for i = 1, 7 do
		local f = Instance.new("Frame")
		f.Name = "Day" .. i
		f.Size = UDim2.new(1 / 7, -SP.xs, 1, 0)
		f.BackgroundColor3 = Color3.fromRGB(46, 40, 70)
		f.LayoutOrder = i
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = f
		local day = C.Text("caption", "DAY " .. i, { size = UDim2.new(1, 0, 0.45, 0), parent = f })
		day.TextXAlignment = Enum.TextXAlignment.Center
		local label = C.Text("body", "", { size = UDim2.new(1, 0, 0.55, 0), parent = f })
		label.Position = UDim2.fromScale(0, 0.45)
		label.TextXAlignment = Enum.TextXAlignment.Center
		f.Parent = calRow
		pips[i] = { frame = f, label = label, day = day }
	end
	for i = 1, 3 do
		local card = C.Card({ name = "Goal" .. i, gap = SP.xs, layoutOrder = -10 + i, parent = window.body, size = UDim2.new(1, 0, 0, 96) })
		local line = C.Row({ height = 44, gap = SP.sm, layoutOrder = 1, parent = card.content })
		local text = C.Text("body", "", { wrap = true, size = UDim2.new(1, -132, 1, 0), layoutOrder = 1, parent = line })
		local index = i
		local claim = C.Button({ text = "CLAIM", role = "locked", size = UDim2.fromOffset(120, 44), layoutOrder = 2, parent = line, onActivated = function()
			remote:FireServer("ClaimGoal", index)
		end })
		local bar = C.ProgressBar({ layoutOrder = 2, parent = card.content })
		goalRows[i] = { text = text, bar = bar, claim = claim }
	end
	bonusButton = C.Button({ text = "", role = "locked", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = -5, parent = window.body, onActivated = function()
		remote:FireServer("ClaimGoal", 4)
	end })
	-- Hats.
	C.SectionHeader("HATS", "daily", 11, window.body)
	local grid = Instance.new("Frame")
	grid.Name = "Hats"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = 12
	C.Grid(grid, HAT_CELL, SP.sm)
	grid.Parent = window.body
	for index, hat in Progress.HATS do
		local rarity = (Progress.RARITY :: any)[hat.rarity]
		local card = C.Card({ name = hat.id, gap = SP.xs, layoutOrder = index, parent = grid })
		local title = C.Text("body", hat.name, { scaled = true, size = UDim2.new(1, 0, 0, 22), layoutOrder = 1, parent = card.content })
		title.TextColor3 = rarity.color
		local id = hat.id
		hatButtons[id] = C.Button({
			text = "???",
			role = "locked",
			size = UDim2.new(1, 0, 0, 48),
			layoutOrder = 2,
			parent = card.content,
			onActivated = function()
				if owns(id) then
					remote:FireServer("Wear", if state.hat == id then "" else id)
				end
			end,
		})
	end
	window.defaultSelection = openButton.hit
	Controller.register(window)
	hud = Controller.addHudButton({ window = "Eggs", label = "Eggs", icon = "gift", theme = "daily", layoutOrder = 5 })

	-- The opening plays over everything.
	local gui = Instance.new("ScreenGui")
	gui.Name = "EggOpening"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 45
	local o = Instance.new("Frame")
	o.Size = UDim2.fromScale(1, 1)
	o.BackgroundColor3 = Color3.fromRGB(12, 8, 30)
	o.BackgroundTransparency = 1
	o.Visible = false
	o.Active = true -- taps do not fall through while it plays
	o.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	overlay = o
end

-- V8-1.4 (unlocks that feel like presents): a 1.5 s reveal in the middle of the screen, never in the
-- way (nothing in it takes a tap): the new weapon turning, its name, a rising chord.
function ProgressUI.reveal(id: string, label: string)
	local g = Instance.new("ScreenGui")
	g.Name = "UnlockReveal"
	g.ResetOnSpawn = false
	g.DisplayOrder = 40
	g.IgnoreGuiInset = true
	local box = Instance.new("Frame")
	box.Active = false
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.42)
	box.Size = UDim2.fromOffset(220, 200)
	box.BackgroundTransparency = 1
	box.Parent = g
	local pic = ToolPicture.make(id, UDim2.fromOffset(140, 140), nil, true)
	pic.AnchorPoint = Vector2.new(0.5, 0)
	pic.Position = UDim2.new(0.5, 0, 0, 0)
	pic.Active = false
	pic.Parent = box
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, 146)
	name.Size = UDim2.fromOffset(220, 44)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.fromRGB(255, 214, 64)
	name.Text = "NEW: " .. string.upper(label)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(40, 24, 0)
	stroke.Parent = name
	name.Parent = box
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = box
	g.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.spawn(function()
		for i, pitch in { 1, 1.26, 1.5 } do -- (a rising chord: root, third, fifth)
			C.playSound("tick", pitch)
			task.wait(0.09)
			if i == 3 then
				C.playSound("unlock")
			end
		end
	end)
	task.delay(1.5, function()
		local out = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		out:Play()
		out.Completed:Wait()
		g:Destroy()
	end)
end

function ProgressUI.start()
	remote = Net.event(Net.Names.Progress)
	build()
	remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "State" and type(data) == "table" then
			local d = data :: any
			local eggsBefore = state.eggs
			state = {
				takedowns = if type(d.takedowns) == "number" then d.takedowns else 0,
				playSeconds = if type(d.playSeconds) == "number" then d.playSeconds else 0,
				eggs = if type(d.eggs) == "number" then d.eggs else 0,
				eggEvery = if type(d.eggEvery) == "number" and d.eggEvery >= 1 then d.eggEvery else nil,
				hats = if type(d.hats) == "table" then d.hats else {},
				hat = if type(d.hat) == "string" then d.hat else "",
				best = if type(d.best) == "table" then d.best else {},
				streak = if type(d.streak) == "number" then d.streak else 0,
				dailyToday = d.dailyToday == true,
				goals = if type(d.goals) == "table" and type(d.goals.list) == "table" then d.goals else nil,
				streakEggs = if type(d.streakEggs) == "table" then d.streakEggs else nil,
				loading = d.loading == true,
			}
			redraw()
			for _, fn in ProgressUI.listeners do
				task.spawn(fn, state)
			end
			-- The way to the next weapon on the ladder, on the bar (PokeController.setNext).
			local prev, nextAt = 0, math.huge
			for _, toy in Toys.list do
				local at = toy.unlockAt
				if at > 0 then
					if at <= state.takedowns then
						prev = math.max(prev, at)
					else
						nextAt = math.min(nextAt, at)
					end
				end
			end
			PokeController.setNext(if nextAt < math.huge then (state.takedowns - prev) / math.max(1, nextAt - prev) else nil)
			if state.eggs > eggsBefore then
				offerEgg(false) -- (a new egg: offered when the moment is calm)
			end
		elseif kind == "Egg" then
			Notify.say("reward", "You found an egg!", Color3.fromRGB(255, 154, 205))
		elseif kind == "Daily" and type(data) == "table" then
			local d = data :: any
			local streak = tonumber(d.streak) or 1
			local weapon = if type(d.weapon) == "string" then Toys.byId[d.weapon] else nil
			if weapon then
				-- (Round 5: a named weapon day of the calendar.)
				local id = weapon.id
				OnboardingController.whenFree(function()
					PokeController.autoEquip(id, true) -- (V8-0.3: a gift day is a prize: it always lands)
				end)
				Notify.say("reward", string.format("DAY %d GIFT: the %s is yours! It's on your bar.", streak, string.upper(weapon.label)), Color3.fromRGB(120, 230, 140))
				C.playSound("reward")
			end
			-- (Audit area 1: a newcomer's first 90 s carry one objective only; the daily news waits.)
			local lp = game:GetService("Players").LocalPlayer
			local newcomerUntil = (lp:GetAttribute("NewcomerUntil") :: number?) or (if lp:GetAttribute("Newcomer") == true then Config.QUIET_START else 0)
			if time() < newcomerUntil then
				task.wait(newcomerUntil - time() + 3)
			end
			-- (V8-0.4: no "come back tomorrow" on a first visit: the egg itself says enough.)
			if (Config :: any).V8_ONE_VOICE and streak <= 1 and lp:GetAttribute("Newcomer") == true then
				return
			end
			Notify.say("reward", if streak <= 1
				then "Daily egg! Come back tomorrow for another."
				else string.format("Daily egg%s! Day %d in a row. Come back tomorrow!", if (tonumber(d.eggs) or 1) > 1 then "s" else "", streak), Color3.fromRGB(255, 154, 205))
		elseif kind == "Notice" and type(data) == "string" then
			-- (Server notices are mostly answers to the player's own press: shown at once, like a reply.)
			Toast.show(data)
		elseif kind == "GoalDone" and type(data) == "string" then
			-- (V5 first visit: never on top of an egg card or another reward: it waits a few seconds.)
			task.wait(6)
			-- (V8-0.4: no button named that may be hidden; the egg card offers the egg by itself.)
			Notify.say("reward", if (Config :: any).V8_ONE_VOICE then "Goal done: " .. data .. "! A free egg is yours." else "Goal done: " .. data .. "! Claim your egg in Rank & Eggs", Color3.fromRGB(255, 154, 205))
			C.playSound("reward")
		elseif kind == "Rank" and type(data) == "string" then
			Notify.say("reward", "Rank up: " .. string.upper(data) .. "!", Color3.fromRGB(255, 210, 74))
		elseif kind == "Combo" and type(data) == "table" then
			-- (Round 2: no COMBO on the screen, the owner's wish. Round 5, phase 00: in the first
			-- minutes of a visit every takedown pops a big "+1 TAKEDOWN", so a new player sees the
			-- shots count.)
			if time() < ProgressUI.POP_FOR then
				local d = data :: any
				ProgressUI.popTakedown(1 + (if type(d.bonus) == "number" then d.bonus else 0))
			end
		elseif kind == "AutoEgg" then
			-- The first egg opens by itself (round 5, phase 00), once the first minute's bar is free.
			OnboardingController.whenFree(function()
				task.wait(math.max(0.5, Config.QUIET_START - time())) -- (phase 0: after the quiet start)
				-- (V6-1 / audit area 1: the self-opening egg is a big pop-up too: it waits its turn, and a
				-- newcomer's comes NOTIFY_BIG_AFTER_REVEAL s after the HUD is in.)
				Notify.waitBig("AutoEgg", 240)
				if Controller.isOpen("EggReady") then
					Controller.close("EggReady")
				end
				local started = os.clock()
				while (opening or state.eggs <= 0) and os.clock() - started < 6 do
					task.wait(0.25) -- (the state with the egg may be a moment behind)
				end
				openEgg()
			end)
		elseif kind == "Opened" and type(data) == "table" then
			waitingOpen = false
			task.spawn(playOpening, data :: any)
		elseif kind == "Unlock" and type(data) == "table" then
			-- A tool unlocked: the moment, with where to find it.
			local d = data :: any
			-- A gun or a bang goes straight onto the bar, picked: the next tap tries it (the launch
			-- funnel: most never opened WEAPONS to find what they had earned).
			local toy = type(d.id) == "string" and Toys.byId[d.id] or nil
			-- (V8-1.4: a 1.5 s present, never in the way: the weapon turning, its name, a chord.)
			if toy and (Config :: any).LADDER_V3 then
				ProgressUI.reveal(toy.id, toy.label)
			end
			local onBar = false
			local deferred = false
			-- (Round 5: the first rungs too, whatever they are: Bat, Crowbar and Shove come at 2, 4 and 6.)
			-- (V8-0.3: under the hand rules every unlock asks for a slot; HandRules decides.)
			if toy and ((Config :: any).V8_HAND_RULES or toy.category == "Guns" or toy.category == "Explosives" or toy.unlockAt <= 10) then
				if PokeController.firstMinute() then
					deferred = true
					-- (The first minute's bar is fixed: it goes on the moment that is over.)
					local id = toy.id
					OnboardingController.whenFree(function()
						if PokeController.autoEquip(id) then
							Notify.say("reward", string.format("Your %s is on the bar. Try it!", string.upper(toy.label)), Color3.fromRGB(120, 230, 140))
						elseif (Config :: any).V8_ONE_VOICE then
							-- (Blind review: the bar kept its stronger tools; it is in WEAPONS.)
							Notify.say("reward", string.format("UNLOCKED: %s! Find it in WEAPONS.", string.upper(toy.label)), Color3.fromRGB(120, 230, 140))
						end
					end)
				else
					onBar = PokeController.autoEquip(toy.id)
				end
			end
			-- (V8-0.4: when it goes on after the first minute, that line says it once; no second toast
			-- saying the opposite now.)
			if not (deferred and (Config :: any).V8_ONE_VOICE) then
				Notify.say("reward", if onBar
					then string.format("NEW: %s! It's on your bar. Try it!", string.upper(tostring(d.name)))
					else string.format("UNLOCKED: %s! Find it in WEAPONS.", string.upper(tostring(d.name))), Color3.fromRGB(120, 230, 140))
			end
			C.playSound("reward")
		end
	end)
	remote:FireServer("Hello")
	-- A tap or a click in the world (a shot, a hit): the offer waits for a quiet moment after it.
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		local kind = input.UserInputType
		if not processed and (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.Gamepad1) then
			lastAction = os.clock()
		end
	end)
	-- The first minute is over: the egg waiting already (the daily egg) is offered a moment later.
	OnboardingController.whenFree(function()
		freeNow = true
		task.wait(ProgressUI.OFFER_FIRST)
		offerEgg(true)
	end)
end

-- Round 5: whoever draws from the profile's state too (REWARDS, the big WEAPONS button, LEVEL).
ProgressUI.listeners = {} :: { (any) -> () }
function ProgressUI.onState(fn: (any) -> ())
	table.insert(ProgressUI.listeners, fn)
	task.spawn(fn, state)
end
function ProgressUI.claimGoal(i: number)
	remote:FireServer("ClaimGoal", i)
end
function ProgressUI.openEggNow()
	openEgg()
end

-- Round 5, phase 00: "+1 TAKEDOWN", big, in the upper middle of the screen, for each takedown in
-- the first POP_FOR seconds of a visit. Pops in, floats up, fades (taps fall through).
ProgressUI.POP_FOR = 120 -- (the owner, 10 Nov: small and quiet, only at the very start)
local popGui: ScreenGui? = nil
local popCount = 0
function ProgressUI.popTakedown(n: number)
	local gui = popGui
	if not gui then
		local g = Instance.new("ScreenGui")
		g.Name = "TakedownPop"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = 30
		g.Parent = player:WaitForChild("PlayerGui")
		popGui = g
		gui = g
	end
	assert(gui)
	popCount += 1
	local label = Instance.new("TextLabel")
	label.Name = "Pop"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	-- (A quick second one sits a little to the side, so two read as two.)
	label.Position = UDim2.fromScale(0.5 + (if popCount % 2 == 0 then 0.04 else -0.02), 0.4)
	label.Size = UDim2.fromOffset(60, 20)
	label.BackgroundTransparency = 1
	label.FontFace = Theme.Fonts.display
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.Text = string.format("+%d TAKEDOWN%s", n, if n > 1 then "S" else "")
	label.Active = false
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(40, 12, 0)
	stroke.Parent = label
	label.Parent = gui
	local camera = workspace.CurrentCamera
	local short = if camera then math.min(camera.ViewportSize.X, camera.ViewportSize.Y) else 600
	local w = if KitStyle.V2 then math.clamp(short * 0.32, 120, 160) else math.clamp(short * 0.3, 100, 150) -- (UI v2: its words 14 px or more)
	TweenService:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(w, w * 0.2) }):Play()
	label.TextTransparency = 0.2
	task.delay(0.5, function()
		TweenService:Create(label, TweenInfo.new(0.6), { Position = label.Position - UDim2.fromScale(0, 0.08), TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		task.delay(0.65, function()
			label:Destroy()
		end)
	end)
end

-- Tests / LayoutCheck.
function ProgressUI.state(): State
	return state
end

return ProgressUI
