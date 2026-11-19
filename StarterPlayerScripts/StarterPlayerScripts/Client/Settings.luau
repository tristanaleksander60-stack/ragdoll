--!strict
-- Settings (round 3, M6): the MENU's SETTINGS window and what it changes, kept in the profile
-- (ProgressService: "Settings", checked there) so a choice follows the player to any device.
--   SOUND EFFECTS  NORMAL / QUIET / OFF: every hit, shot, beep and click (the Effects sound group;
--                  the radio keeps its own volume)
--   BLOOD          ON / OFF: off is stars, sparks and dust only (HitFxStyle "Stylised", the vault's
--                  gore policy: the game sets the most it shows, a player may always choose less)
--   CAMERA SHAKE   ON / OFF
--   MOTION         AUTO (the device's setting) / LESS / FULL: windows and toasts pop or just appear
--   UI SIZE        NORMAL / LARGE / SMALL (the kit's player scale; a window still fits the screen)
-- No free text anywhere: every row is a fixed set of choices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))

local Settings = {}

--   DEAD MONITOR   ON / OFF (round 4, M11): the small monitor over a dead body under the mouse (OFF unless chosen)
export type Values = { sfx: number, blood: boolean, shake: boolean, motion: number, ui: number, deadMon: boolean }

-- The choices of each multi-way row, in the order a tap cycles them (index 1 is the default).
Settings.SFX = { { name = "NORMAL", volume = 1 }, { name = "QUIET", volume = 0.4 }, { name = "OFF", volume = 0 } }
Settings.MOTION = { { name = "AUTO", reduced = nil :: boolean? }, { name = "LESS", reduced = true :: boolean? }, { name = "FULL", reduced = false :: boolean? } }
Settings.UI = { { name = "NORMAL", scale = 1 }, { name = "LARGE", scale = 1.15 }, { name = "SMALL", scale = 0.9 } }
local SAVE_AFTER = 0.75 -- s after the last change (one write for a flurry of taps)

local values: Values = { sfx = 1, blood = true, shake = true, motion = 1, ui = 1, deadMon = false }
local touched = false -- (changed here before the kept choice arrived: this session's choice wins)
local saveToken = 0
local remote: RemoteEvent? = nil
local redrawers: { () -> () } = {}

-- The sound group every game sound effect plays in (FxController, the monitor's beep, the kit's
-- clicks); the radio is music and has its own volume.
local group: SoundGroup
do
	local existing = SoundService:FindFirstChild("Effects")
	if existing and existing:IsA("SoundGroup") then
		group = existing
	else
		group = Instance.new("SoundGroup")
		group.Name = "Effects"
		group.Volume = 1
		group.Parent = SoundService
	end
end

function Settings.effects(): SoundGroup
	return group
end

function Settings.shake(): boolean
	return values.shake
end

function Settings.deadMonitor(): boolean
	return values.deadMon
end

function Settings.get(): Values
	return table.clone(values)
end

-- Checks a table from anywhere (the server's message, a test) into values; junk keeps the default.
function Settings.clean(raw: unknown): Values
	local v: Values = { sfx = 1, blood = true, shake = true, motion = 1, ui = 1, deadMon = false }
	if type(raw) ~= "table" then
		return v
	end
	local t = raw :: any
	local function pick(n: unknown, list: { any }): number?
		return if type(n) == "number" and n == math.floor(n) and n >= 1 and n <= #list then n else nil
	end
	v.sfx = pick(t.sfx, Settings.SFX) or 1
	v.motion = pick(t.motion, Settings.MOTION) or 1
	v.ui = pick(t.ui, Settings.UI) or 1
	v.blood = t.blood ~= false
	v.shake = t.shake ~= false
	v.deadMon = t.deadMon == true -- (10 Nov 2026, the owner: off unless chosen; a new key, so an old saved 'monitor' is not read)
	return v
end

local function apply()
	group.Volume = Settings.SFX[values.sfx].volume
	local player = Players.LocalPlayer
	-- (A local preference: only this screen draws this player's hit effects. Unset is the game's
	-- most, so ON clears it rather than naming a style.)
	player:SetAttribute("HitFxStyle", if values.blood then nil else "Stylised")
	Controller.setReducedMotion(Settings.MOTION[values.motion].reduced)
	Controller.setPlayerScale(Settings.UI[values.ui].scale)
	for _, redraw in redrawers do
		redraw()
	end
end

local function save()
	saveToken += 1
	local token = saveToken
	task.delay(SAVE_AFTER, function()
		local r = remote
		if token == saveToken and r then
			r:FireServer("Settings", table.clone(values))
		end
	end)
end

-- A change from the window (or a test): applied at once and kept.
function Settings.set(key: string, value: any)
	local next = table.clone(values) :: any
	next[key] = value
	values = Settings.clean(next)
	touched = true
	apply()
	save()
end

-- A row with a few fixed choices: the same card as an on/off row (label, a line under it, an icon),
-- with a button on the right that steps to the next choice.
local CHOICE_W = 128
local function choiceRow(label: string, description: string, icon: string, key: string, list: { { name: string } }, order: number, parent: Instance): any
	local card = C.Card({ name = "Setting_" .. label, size = UDim2.new(1, 0, 0, 78), layout = "none", padding = Theme.Space.md, layoutOrder = order })
	local content = card.content
	local picture = Icons.make(icon, UDim2.fromOffset(40, 40))
	picture.AnchorPoint = Vector2.new(0, 0.5)
	picture.Position = UDim2.fromScale(0, 0.5)
	picture.Parent = content
	local left = 40 + Theme.Space.md
	local textW = -(left + CHOICE_W + Theme.Space.lg)
	C.Text("small", label, { name = "Label", align = Enum.TextXAlignment.Left, size = UDim2.new(1, textW, 0, 26), position = UDim2.new(0, left, 0, 2), parent = content })
	C.Text("caption", description, { name = "Description", color = (Theme.Palette :: any).textLow, align = Enum.TextXAlignment.Left, size = UDim2.new(1, textW, 0, 20), position = UDim2.new(0, left, 1, -2), anchor = Vector2.new(0, 1), parent = content } :: any)
	local button = C.Button({
		text = "",
		role = "info",
		size = UDim2.fromOffset(CHOICE_W, 46),
		parent = content,
		onActivated = function()
			local now = (values :: any)[key] :: number
			Settings.set(key, now % #list + 1)
		end,
	})
	button.root.AnchorPoint = Vector2.new(1, 0.5)
	button.root.Position = UDim2.fromScale(1, 0.5)
	table.insert(redrawers, function()
		button.setText(list[(values :: any)[key]].name)
	end)
	card.root.Parent = parent
	return button
end

local function build()
	-- (Tall enough for its six rows on a computer; a short screen scrolls the body.)
	local window = C.Window({ name = "Settings", title = "Settings", theme = "settings", icon = "settings", size = Vector2.new(640, 650) })
	local body = window.body
	local first = choiceRow("Sound effects", "Hits, shots and beeps", "sound", "sfx", Settings.SFX, 1, body)
	local blood = C.SettingRow({
		label = "Blood",
		description = "Off: stars and sparks only",
		icon = "eye",
		value = values.blood,
		layoutOrder = 2,
		parent = body,
		onChanged = function(on: boolean)
			Settings.set("blood", on)
		end,
	})
	-- (Phase 0: with Config.BLOOD "off" there is no blood to choose: the row is hidden.)
	blood.root.Visible = Config.BLOOD ~= "off"
	local shake = C.SettingRow({
		label = "Camera shake",
		description = "The screen shakes when something big goes off",
		icon = "shake", -- (its own picture: a phone shaking, apart from Motion's film)
		value = values.shake,
		layoutOrder = 3,
		parent = body,
		onChanged = function(on: boolean)
			Settings.set("shake", on)
		end,
	})
	-- (Only where there is a mouse to point with: a phone has doctor mode instead.)
	local monitor = C.SettingRow({
		label = "Dead monitor",
		description = "Show a dead body's monitor when you point at it",
		icon = "heart",
		value = values.deadMon,
		layoutOrder = 6,
		parent = body,
		onChanged = function(on: boolean)
			Settings.set("deadMon", on)
		end,
	})
	local UserInputService = game:GetService("UserInputService")
	local function mouseRow()
		monitor.root.Visible = UserInputService.MouseEnabled
	end
	mouseRow()
	UserInputService:GetPropertyChangedSignal("MouseEnabled"):Connect(mouseRow)
	table.insert(redrawers, function()
		blood.toggle.set(values.blood, true)
		shake.toggle.set(values.shake, true)
		monitor.toggle.set(values.deadMon, true)
	end)
	choiceRow("Motion", "Auto follows your device. Less: menus just appear", "motion", "motion", Settings.MOTION, 4, body)
	choiceRow("UI size", "Buttons and windows bigger or smaller", "scale", "ui", Settings.UI, 5, body)
	window.defaultSelection = first.hit
	Controller.register(window)
	apply()
end

function Settings.start()
	-- (The kit's clicks are effects too, in the mix's quieter UI group: v4 A3.)
	C.soundGroup = require(script.Parent:WaitForChild("SoundMix")).group("UI")
	build()
	local r = Net.event(Net.Names.Progress)
	remote = r
	r.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		-- The kept choice (asked for with the radio's "Prefs"; the first answer counts unless the
		-- player already changed something here).
		if kind ~= "Settings" or touched then
			return
		end
		touched = true
		values = Settings.clean(data)
		apply()
	end)
	r:FireServer("Prefs")
end

return Settings
