--!strict
-- The MENU launcher (phase F; round 3, M6 on every device): the left edge shows SHOP, WEAPONS,
-- SANDBOX and MENU only (the kit decides, LihFolkUIController.COLUMN_KEEP: a column on a computer
-- or tablet, two to a row on a phone), and MENU's window holds a button for each of the others:
-- Places, Rank & Eggs, Friends, Clips & Live, Radio, Settings (and Keys on a keyboard). A badge in
-- one's corner (an egg waiting) shows on MENU too.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local HudMenu = {}

local ENTRIES: { any } = {
	-- (One colour for going somewhere; green where something waits to be claimed; red is the kit's
	-- close and delete, never a place to go.)
	{ window = "Maps", text = "MAPS", role = "info", phoneOnly = true }, -- (off a phone MAPS is a square on the right; UI audit 21 Nov: one name, MAPS, everywhere)
	-- (21 Nov 2026: GOD MODE, create life. Off a phone it is a square of its own: HudV3.)
	{ window = "God", text = "GOD MODE", role = "premium", phoneOnly = true, godOnly = true }, -- (V9-0f: only for an owner of the pass or during the trial: GodRules)
	-- (Phase 0: SANDBOX had slipped onto the line above, behind its comment, so a phone had no way
	-- to build; it is back, and a phone's BUILD button now lives here.)
	{ window = "Sandbox", text = "LAB", role = "go", phoneOnly = true }, -- (V9-2c: the LAB window (TIME, first person, REVIVE, RESET, BUILD); HudMenu.onSandbox without it)
	{ window = "Rewards", text = "REWARDS", role = "go", phoneOnly = true }, -- (round 5; off a phone: its own launcher)
	{ window = "Eggs", text = "RANK & EGGS", role = "go" },
	-- (23 Nov 2026, owner: no missions anywhere.) { window = "Experiments", text = "MISSIONS", role = "go" }, -- (phase 1: a pad reaches the card's window here; owner 21 Nov 2026: everyone, to show hidden missions again)
	{ window = "Friends", text = "FRIENDS", role = "info" },
	{ window = "Creator", text = "CLIPS & LIVE", role = "info", notPhone = true }, -- (21 Nov 2026: streaming tools are a computer's; a phone clips from the replay's CLIP IT. Its row went to GOD MODE.)
	-- (V8-0.9: also wherever the launcher column is hidden, i.e. under HudV3 on PC, tablet and console:
	-- there SETTINGS had no way in at all.)
	{ window = "Settings", text = "SETTINGS", role = "neutral", phoneOnly = true, columnToo = true },
	{ window = "Like", text = "\u{2B50} FAVORITE", role = "go" }, -- (round 4: LikePrompt)
	{ window = "Codes", text = "CODES", role = "go", notPhone = true }, -- (V9-0t: codes from the game page: CodesWindow. A phone's MENU is full, LayoutCheck: there it is SHOP's "HAVE A CODE?")
	{ window = "Controls", text = "KEYS", role = "neutral", keyboardOnly = true },
}
-- UI v2: the drawn icon for each MENU entry (DrawnIcons names; the same pictures as the launchers).
local MENU_ICONS: { [string]: string } = {
	Maps = "map",
	God = "god",
	Time = "hud_slowmo",
	Sandbox = "sandbox",
	Rewards = "present",
	Eggs = "crown",
	Experiments = "star",
	Friends = "friends",
	Creator = "camera",
	Settings = "settings",
	Like = "star",
	Codes = "gift",
	Controls = "keys",
}
HudMenu.ICONS = MENU_ICONS

-- What stays on the left edge beside MENU, on a phone and a computer alike (round 3, M6): the
-- three things a player reaches for while playing. Everything else is one tap away in MENU.
-- Round 5 (like the big ragdoll games): WEAPONS is its own big button above the column (HudPlus);
-- the column is SHOP, REWARDS, PLACES, SANDBOX and SETTINGS, with key hints and number badges.
HudMenu.KEEP = { Shop = true, Rewards = true, Places = true, Sandbox = true, Settings = true }
-- A phone: SHOP beside MENU (one row: the short screen's left edge has the big WEAPONS button
-- too); REWARDS, PLACES, SANDBOX and SETTINGS in MENU (its badge shows what waits in REWARDS).
HudMenu.PHONE_KEEP = { Shop = true } -- (GOD MODE sits in MENU on a phone: no room in the column, LayoutCheck)
-- The column starts under the big WEAPONS button (HudSlots "Weapons": 68 px down, 58 tall; 46 on a phone).
Controller.COLUMN_TOP = 144
C.HUD_CAPTION_MIN = 11 -- (smaller tiles: "Settings" still fits)
Controller.HUD_SCALE = 0.85 -- (the owner, 10 Nov: a quieter HUD, focus on the game; a touch tap stays 44 px)
Controller.PHONE_COLUMN_TOP = 64 -- (24 Nov 2026 layout: SHOP and MENU up in the corner, clear of the move thumb)
HudMenu.onSandbox = nil :: (() -> ())? -- what MENU's SANDBOX does (BuildController.toggle: Main)

local function isPhone(): boolean
	local camera = workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
	return math.min(v.X, v.Y) <= 500 -- (the same test as HudSlots)
end

-- How many buttons a phone shows (LayoutCheck fits them; KEYS is for keyboards only).
function HudMenu.phoneCount(): number
	local n = 0
	for _, entry in ENTRIES do
		if not (entry :: any).keyboardOnly and not (entry :: any).notPhone and not (entry :: any).padOnly then
			n += 1
		end
	end
	return n
end

local hud: any = nil
local badges: { [string]: boolean } = {}
local buttons: { [string]: any } = {}

local function refresh()
	local any = false
	for window, on in badges do
		if on then
			any = true
		end
		local b = buttons[window]
		if b then
			b.badge.Visible = on
		end
	end
	if hud then
		hud.setBadge(any)
	end
end

-- A small pill on MENU (free ULTRA's clock): MENU keeps its name; nil hides the pill.
function HudMenu.setTag(text: string?)
	if hud then
		hud.setTag(text)
	end
end

-- The window as LayoutCheck measures it: CELL design units a button, two to a row.
HudMenu.WINDOW = Vector2.new(420, 400) -- (four rows of two and its header: eight buttons, KEYS on a keyboard)
-- (Two to a row in the window's 366 design units of grid. 46 tall, round 4: the seven a phone shows
-- with LIKE US are four rows, 4 x 46 + 3 x 8 = 208, inside the 210 the shortest phone has; still
-- over the 44 px a tap needs.)
HudMenu.CELL = Vector2.new(172, 46)
HudMenu.GAP = 8
HudMenu.HEAD = 130 -- design units over and under the rows (header, padding)

-- Another launcher's badge (shown on MENU too).
function HudMenu.setBadge(window: string, on: boolean)
	badges[window] = on
	refresh()
end

function HudMenu.start()
	local window = C.Window({ name = "Menu", title = if Config.V8_FIRST_HIT then "More" else "Menu", theme = "neutral", icon = "settings", size = HudMenu.WINDOW })
	-- Two to a row: the seven a phone shows are four rows (HudMenu.CELL), inside the body a phone's
	-- window has at its smallest, so none is below the fold (LayoutCheck measures it).
	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.Parent = window.body
	local layout = C.Grid(grid, HudMenu.CELL, HudMenu.GAP)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	for index, entry in ENTRIES do
		local name = entry.window
		-- (UI v2: every entry carries its drawn picture beside the word: MENU_ICONS.)
		local icon = if Theme.V2 then MENU_ICONS[name] else nil
		local button = C.Button({
			text = if icon and name == "Like" then "FAVORITE" else entry.text,
			icon = icon,
			role = entry.role :: any,
			size = UDim2.fromOffset(HudMenu.CELL.X, HudMenu.CELL.Y),
			layoutOrder = index,
			parent = grid,
			onActivated = function()
				if name == "Sandbox" and Controller.isRegistered and Controller.isRegistered("Lab") then
					-- (V9-2c: a phone's SANDBOX opens the LAB window: TIME, first person, REVIVE ALL, RESET,
					-- BUILD and the lab view, as off a phone; MENU stays at 8.)
					Controller.open("Lab")
					return
				end
				if name == "Sandbox" then
					Controller.closeAll()
					local go = HudMenu.onSandbox
					if go then
						go()
					end
					return
				end
				Controller.open(name)
			end,
		})
		local e = entry :: any
		if e.notPhone or e.phoneOnly then
			local function show()
				-- (Phase 0: a gamepad has no left column to reach, so MENU holds everything for it too.)
				local pad = string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
				local columnGone = e.columnToo == true and (require(script.Parent:WaitForChild("HudGate")) :: any).active()
				local godOk = not e.godOnly or (require(script.Parent:WaitForChild("GodMode")) :: any).launcherShown()
				if e.timeOnly and not Config.TIME_DIAL then
					godOk = false -- (V9-2c: the time dial only when it is on)
				end
				button.root.Visible = godOk and (if e.phoneOnly then (isPhone() or pad or columnGone) else not isPhone())
			end
			UserInputService.LastInputTypeChanged:Connect(show)
			show()
			if e.godOnly then
				-- (The pass or the trial can start or end at any time: look again once a second.)
				task.spawn(function()
					while button.root.Parent do
						task.wait(1)
						show()
					end
				end)
			end
			local camera = workspace.CurrentCamera
			if camera then
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(show)
			end
		end
		-- A badge in the corner (an egg waiting): the name stays as it is.
		local badge = C.Pill("!", { role = "danger", anchor = Vector2.new(0.5, 0.5), position = UDim2.new(1, -8, 0, 6), zIndex = 20, parent = button.root })
		badge.Visible = false
		buttons[name] = { badge = badge }
		if (entry :: any).padOnly then
			local function showPad()
				button.root.Visible = string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
			end
			showPad()
			UserInputService.LastInputTypeChanged:Connect(showPad)
		end
		if (entry :: any).keyboardOnly then
			local function show()
				button.root.Visible = UserInputService.KeyboardEnabled
			end
			show()
			UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(show)
		end
		if index == 1 then
			window.defaultSelection = button.hit
		end
	end
	Controller.register(window)
	-- (UI audit 21 Nov 2026: off a phone the window is as tall as its rows; three rows in a window
	-- made for four left a dark empty half. A phone keeps the full height LayoutCheck measures.)
	local function fitHeight()
		local shown = 0
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") and child.Visible then
				shown += 1
			end
		end
		local rows = math.max(1, math.ceil(shown / 2))
		local tall = if isPhone() then HudMenu.WINDOW.Y else math.min(HudMenu.WINDOW.Y, HudMenu.HEAD + rows * (HudMenu.CELL.Y + HudMenu.GAP))
		if window.designSize.Y ~= tall then
			window.designSize = Vector2.new(HudMenu.WINDOW.X, tall)
			Controller.refresh()
		end
	end
	for _, child in grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("Visible"):Connect(fitHeight)
		end
	end
	fitHeight()
	Controller.COLUMN_KEEP = HudMenu.KEEP
	Controller.PHONE_KEEP = HudMenu.PHONE_KEEP
	hud = Controller.addHudButton({ window = "Menu", label = Controller.MENU_LAUNCHER, icon = "settings", theme = "neutral", layoutOrder = 9 })
	refresh()
end

return HudMenu
