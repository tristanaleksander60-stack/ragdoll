--!strict
-- Round 5, phase 1: REWARDS (J, a launcher in the left column), one window with every free thing,
-- like the big ragdoll games. It only shows what already exists:
--   DAILY GIFT   the 7-day calendar (the daily egg; days 2 and 7 also name a weapon:
--                DailyGoals.STREAK_WEAPONS), today marked
--   PLAY GIFT    the clock to the next free egg for time played (PlaytimeGifts: GiftAt)
--   TODAY'S DARES the day's three goals with CLAIM (the same as Rank & Eggs)
--   TROPHIES     badges you have / all of them
--   GROUP GIFT   join the game's group for a free egg (SOON until the owner sends the group id)
-- The launcher's red number: what can be claimed now (dares done, the group gift, an egg waiting).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local DailyGoals = require(Shared:WaitForChild("DailyGoals"))
local Toys = require(Shared:WaitForChild("Toys"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local ProgressUI = require(Client:WaitForChild("ProgressUI"))
local ToolPicture = require(Client:WaitForChild("ToolPicture"))

local RewardsUI = {}

RewardsUI.WINDOW = Vector2.new(560, 520)
local P = Theme.Palette
local SP = Theme.Space

local player = Players.LocalPlayer
local remote: RemoteEvent
local hud: any = nil
local rewards: { [string]: any } = { groupId = 0, inGroup = false, claimed = false, trophies = 0, trophiesTotal = 0 }
local progress: any = nil

local days: { { frame: Frame, label: TextLabel } } = {}
local playLabel: TextLabel? = nil
local playBar: any = nil
local dareRows: { { text: TextLabel, bar: any, claim: any } } = {}
local trophyLabel: TextLabel? = nil
local trophyBar: any = nil
local groupText: TextLabel? = nil
local groupButton: any = nil

-- What can be claimed now (the launcher's number).
function RewardsUI.claimable(): number
	local n = 0
	local s = progress
	if s and s.goals and type(s.goals.list) == "table" then
		for _, g in s.goals.list do
			if g.got >= g.need and not g.claimed then
				n += 1
			end
		end
	end
	if rewards.groupId ~= 0 and rewards.inGroup and not rewards.claimed then
		n += 1
	end
	if s and (s.eggs or 0) > 0 then
		n += 1
	end
	return n
end

local function redraw()
	local s = progress
	if s then
		local streak = math.max(0, s.streak or 0)
		local todayIndex = if s.dailyToday then ((math.max(1, streak) - 1) % 7) + 1 else (streak % 7) + 1
		for i, pip in days do
			local done = s.dailyToday and i <= todayIndex or (not s.dailyToday and i < todayIndex)
			pip.frame.BackgroundColor3 = if i == todayIndex then Color3.fromRGB(255, 154, 205) elseif done then Color3.fromRGB(70, 140, 90) else Color3.fromRGB(46, 40, 70)
		end
		local list = if s.goals and type(s.goals.list) == "table" then s.goals.list else {}
		for i, row in dareRows do
			local g = list[i]
			row.text.Text = if g then g.text else ""
			row.bar.setValue(if g then math.clamp(g.got / math.max(1, g.need), 0, 1) else 0)
			row.bar.setText(if g then string.format("%d / %d", math.min(g.got, g.need), g.need) else "")
			if g and g.claimed then
				row.claim.setText("DONE")
				row.claim.setRole("done")
			elseif g and g.got >= g.need then
				row.claim.setText("CLAIM")
				row.claim.setRole("go")
			else
				row.claim.setText("CLAIM")
				row.claim.setRole("locked")
			end
		end
	end
	if trophyLabel then
		trophyLabel.Text = string.format("TROPHIES  %d / %d", rewards.trophies or 0, rewards.trophiesTotal or 0)
	end
	if trophyBar then
		trophyBar.setValue(math.clamp((rewards.trophies or 0) / math.max(1, rewards.trophiesTotal or 1), 0, 1))
	end
	if groupText and groupButton then
		if rewards.groupId == 0 then
			groupText.Text = "Join our Roblox group for a FREE weapon egg"
			groupButton.setText("SOON")
			groupButton.setRole("locked")
		elseif rewards.claimed then
			groupText.Text = "Thanks for joining the group!"
			groupButton.setText("CLAIMED")
			groupButton.setRole("done")
		elseif rewards.inGroup then
			groupText.Text = "You're in the group! Claim your free weapon egg"
			groupButton.setText("CLAIM")
			groupButton.setRole("go")
		else
			groupText.Text = "Join the group (on the game's page), then claim a FREE weapon egg"
			groupButton.setText("CHECK")
			groupButton.setRole("info")
		end
	end
	if hud then
		hud.setCount(RewardsUI.claimable())
	end
end

local function build()
	local window = C.Window({ name = "Rewards", title = "Rewards", theme = "daily", icon = "gift", size = RewardsUI.WINDOW })
	-- Daily gift: the calendar.
	C.SectionHeader("DAILY GIFT", "daily", 1, window.body)
	local row = C.Row({ height = 66, gap = SP.xs, layoutOrder = 2, parent = window.body })
	for i = 1, 7 do
		local f = Instance.new("Frame")
		f.Name = "Day" .. i
		f.Size = UDim2.new(1 / 7, -SP.xs, 1, 0)
		f.BackgroundColor3 = Color3.fromRGB(46, 40, 70)
		f.LayoutOrder = i
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = f
		local day = C.Text("caption", "DAY " .. i, { size = UDim2.new(1, 0, 0, 16), parent = f })
		day.TextXAlignment = Enum.TextXAlignment.Center
		local weaponId = DailyGoals.STREAK_WEAPONS[i]
		local label: TextLabel
		if weaponId and Toys.byId[weaponId] then
			local pic = ToolPicture.make(weaponId, UDim2.fromOffset(30, 30))
			pic.AnchorPoint = Vector2.new(0.5, 0)
			pic.Position = UDim2.new(0.5, 0, 0, 17)
			pic.Parent = f
			label = C.Text("caption", string.upper(Toys.byId[weaponId].short), { size = UDim2.new(1, -4, 0, 16), parent = f })
			label.Position = UDim2.new(0, 2, 1, -18)
			label.TextColor3 = Color3.fromRGB(255, 210, 74)
		else
			local eggs = DailyGoals.STREAK_EGGS[i]
			label = C.Text("body", string.format("\u{1F95A}x%d", eggs), { size = UDim2.new(1, 0, 0, 30), parent = f })
			label.Position = UDim2.fromOffset(0, 24)
		end
		label.TextXAlignment = Enum.TextXAlignment.Center
		f.Parent = row
		days[i] = { frame = f, label = label }
	end
	-- Play gift.
	C.SectionHeader("PLAY GIFT", "daily", 3, window.body)
	local playCard = C.Card({ name = "PlayGift", gap = SP.xs, layoutOrder = 4, parent = window.body, size = UDim2.new(1, 0, 0, 84) })
	playLabel = C.Text("body", "", { wrap = true, size = UDim2.new(1, 0, 0, 26), layoutOrder = 1, parent = playCard.content })
	playBar = C.ProgressBar({ layoutOrder = 2, parent = playCard.content })
	-- Today's dares.
	C.SectionHeader("TODAY'S DARES", "daily", 5, window.body)
	for i = 1, 3 do
		local card = C.Card({ name = "Dare" .. i, gap = SP.xs, layoutOrder = 5 + i, parent = window.body, size = UDim2.new(1, 0, 0, 96) })
		local line = C.Row({ height = 44, gap = SP.sm, layoutOrder = 1, parent = card.content })
		local text = C.Text("body", "", { wrap = true, size = UDim2.new(1, -132, 1, 0), layoutOrder = 1, parent = line })
		local index = i
		local claim = C.Button({ text = "CLAIM", role = "locked", size = UDim2.fromOffset(120, 44), layoutOrder = 2, parent = line, onActivated = function()
			ProgressUI.claimGoal(index)
		end })
		local bar = C.ProgressBar({ layoutOrder = 2, parent = card.content })
		dareRows[i] = { text = text, bar = bar, claim = claim }
	end
	-- Trophies.
	C.SectionHeader("TROPHIES", "daily", 10, window.body)
	local trophyCard = C.Card({ name = "Trophies", gap = SP.xs, layoutOrder = 11, parent = window.body, size = UDim2.new(1, 0, 0, 80) })
	trophyLabel = C.Text("title", "TROPHIES", { scaled = true, size = UDim2.new(1, 0, 0, 26), layoutOrder = 1, parent = trophyCard.content })
	trophyBar = C.ProgressBar({ layoutOrder = 2, parent = trophyCard.content })
	-- Group gift.
	C.SectionHeader("GROUP GIFT", "daily", 12, window.body)
	local groupCard = C.Card({ name = "Group", gap = SP.xs, layoutOrder = 13, parent = window.body, size = UDim2.new(1, 0, 0, 70) })
	local groupLine = C.Row({ height = 48, gap = SP.sm, layoutOrder = 1, parent = groupCard.content })
	groupText = C.Text("body", "", { wrap = true, size = UDim2.new(1, -132, 1, 0), layoutOrder = 1, parent = groupLine })
	groupButton = C.Button({ text = "SOON", role = "locked", size = UDim2.fromOffset(120, 44), layoutOrder = 2, parent = groupLine, onActivated = function()
		if rewards.groupId ~= 0 and not rewards.claimed then
			remote:FireServer("ClaimGroup")
		end
	end })
	window.defaultSelection = dareRows[1].claim.hit
	Controller.register(window)
	hud = Controller.addHudButton({ window = "Rewards", label = "Rewards", icon = "gift", theme = "daily", layoutOrder = 2 })
end

-- The play gift's line, every half second.
local function tickPlay()
	local label, bar = playLabel, playBar
	if not label or not bar then
		return
	end
	local at = player:GetAttribute("GiftAt")
	local left = if typeof(at) == "number" then (at :: number) - workspace:GetServerTimeNow() else nil
	if left == nil then
		label.Text = "All of today's play gifts are yours. More tomorrow!"
		bar.setValue(1)
		bar.setText("DONE")
	elseif left <= 0 then
		label.Text = "\u{1F381} Your play gift is ready: an egg is on its way!"
		bar.setValue(1)
		bar.setText("READY")
	else
		local s = math.ceil(left)
		label.Text = string.format("\u{1F381} Next free weapon egg in %d:%02d of play", s // 60, s % 60)
		local span = 300
		bar.setValue(math.clamp(1 - left / span, 0, 1))
		bar.setText(string.format("%d:%02d", s // 60, s % 60))
	end
end

function RewardsUI.start()
	remote = Net.event(Net.Names.Rewards)
	build()
	remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "State" and type(data) == "table" then
			rewards = data :: any
			redraw()
		end
	end)
	ProgressUI.onState(function(s: any)
		progress = s
		redraw()
	end)
	remote:FireServer("Hello")
	-- (Asked again when the window opens: a group joined on the website shows at once.)
	Controller.onChanged(function(name: string, isOpen: boolean)
		if name == "Rewards" and isOpen then
			remote:FireServer("Hello")
		end
	end)
	local function keyLabel()
		if hud then
			hud.setKey(if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then Keybinds.labelOf("Rewards") else nil)
		end
	end
	keyLabel()
	Keybinds.onChanged(keyLabel)
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("Rewards", input.KeyCode) then
			Controller.toggle("Rewards")
		end
	end)
	task.spawn(function()
		while true do
			tickPlay()
			task.wait(0.5)
		end
	end)
end

return RewardsUI
