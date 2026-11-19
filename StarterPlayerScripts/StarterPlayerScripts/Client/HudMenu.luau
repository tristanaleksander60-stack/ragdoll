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

local HudMenu = {}

local ENTRIES = {
	-- (One colour for going somewhere; green where something waits to be claimed; red is the kit's
	-- close and delete, never a place to go.)
	{ window = "Maps", text = "PLACES", role = "info", phoneOnly = true }, -- (off a phone PLACES is on the left edge)	{ window = "Sandbox", text = "SANDBOX", role = "go", phoneOnly = true }, -- (and SANDBOX here: HudMenu.onSandbox)
	{ window = "Rewards", text = "REWARDS", role = "go", phoneOnly = true }, -- (round 5; off a phone: its own launcher)
	{ window = "Eggs", text = "RANK & EGGS", role = "go" },
	{ window = "Friends", text = "FRIENDS", role = "info" },
	{ window = "Creator", text = "CLIPS & LIVE", role = "info" },
	{ window = "Settings", text = "SETTINGS", role = "neutral", phoneOnly = true }, -- (off a phone: its own launcher)
	{ window = "Like", text = "\u{2B50} FAVORITE", role = "go" }, -- (round 4: LikePrompt)
	{ window = "Controls", text = "KEYS", role = "neutral", keyboardOnly = true },
}
-- What stays on the left edge beside MENU, on a phone and a computer alike (round 3, M6): the
-- three things a player reaches for while playing. Everything else is one tap away in MENU.
-- Round 5 (like the big ragdoll games): WEAPONS is its own big button above the column (HudPlus);
-- the column is SHOP, REWARDS, PLACES, SANDBOX and SETTINGS, with key hints and number badges.
HudMenu.KEEP = { Shop = true, Rewards = true, Places = true, Sandbox = true, Settings = true }
-- A phone: SHOP beside MENU (one row: the short screen's left edge has the big WEAPONS button
-- too); REWARDS, PLACES, SANDBOX and SETTINGS in MENU (its badge shows what waits in REWARDS).
HudMenu.PHONE_KEEP = { Shop = true }
-- The column starts under the big WEAPONS button (HudSlots "Weapons": 68 px down, 58 tall; 46 on a phone).
Controller.COLUMN_TOP = 144
C.HUD_CAPTION_MIN = 11 -- (smaller tiles: "Settings" still fits)
Controller.HUD_SCALE = 0.85 -- (the owner, 10 Nov: a quieter HUD, focus on the game; a touch tap stays 44 px)
Controller.PHONE_COLUMN_TOP = 130
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
		if not (entry :: any).keyboardOnly and not (entry :: any).notPhone then
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

-- Another launcher's badge (shown on MENU too).
function HudMenu.setBadge(window: string, on: boolean)
	badges[window] = on
	refresh()
end

function HudMenu.start()
	local window = C.Window({ name = "Menu", title = "Menu", theme = "neutral", icon = "settings", size = HudMenu.WINDOW })
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
		local button = C.Button({
			text = entry.text,
			role = entry.role :: any,
			size = UDim2.fromOffset(HudMenu.CELL.X, HudMenu.CELL.Y),
			layoutOrder = index,
			parent = grid,
			onActivated = function()
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
				button.root.Visible = if e.phoneOnly then isPhone() else not isPhone()
			end
			show()
			local camera = workspace.CurrentCamera
			if camera then
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(show)
			end
		end
		-- A badge in the corner (an egg waiting): the name stays as it is.
		local badge = C.Pill("!", { role = "danger", anchor = Vector2.new(0.5, 0.5), position = UDim2.new(1, -8, 0, 6), zIndex = 20, parent = button.root })
		badge.Visible = false
		buttons[name] = { badge = badge }
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
	Controller.COLUMN_KEEP = HudMenu.KEEP
	Controller.PHONE_KEEP = HudMenu.PHONE_KEEP
	hud = Controller.addHudButton({ window = "Menu", label = Controller.MENU_LAUNCHER, icon = "settings", theme = "neutral", layoutOrder = 9 })
	refresh()
end

return HudMenu
