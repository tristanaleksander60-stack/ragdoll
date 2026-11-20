--!strict
--[[
	LihFolkUIController
	Owns the LihFolk UI screen layers and every registered window:
	  - two ScreenGuis: a full-screen backdrop (ScreenInsets.None) and a safe-area
	    layer (ScreenInsets.CoreUISafeInsets) for everything a finger can touch
	  - responsive scaling: device base x player preference, clamped to fit the safe
	    area, with a touch floor so tap targets never draw under 44 px
	  - open / close: centre-anchored scale pop driven by state, interrupt-safe
	    (proportional retargeting, Completed checked before hiding)
	  - one menu at a time, dimmer behind it, tap-outside to close
	  - gamepad: focus moves into the window on open and back on close; ButtonB closes
	  - HUD launcher column with badges
	Run from ONE LocalScript (or any number; start() is idempotent).

	License: LihFolk. Free to use and modify in your games.
]]

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.LihFolkUITheme)
local Components = require(script.Parent.LihFolkUIComponents)

type Window = Components.Window
type HudButton = Components.HudButton
type ThemeName = Theme.ThemeName

export type DeviceKind = "phone" | "tablet" | "desktop" | "console"

export type StartOptions = {
	displayOrder: number?, -- main layer order; the backdrop sits one below (default 41)
	closeOnBackdrop: boolean?, -- tap outside a window closes it (default true)
	closeKeys: { Enum.KeyCode }?, -- default { ButtonB }. Escape is reserved by Roblox.
}

export type HudButtonOptions = {
	window: string?, -- registered window name to toggle (or onActivated)
	label: string,
	icon: string,
	theme: ThemeName,
	layoutOrder: number?,
	onActivated: (() -> ())?, -- instead of toggling a window (a mode, a window someone else opens)
	picture: GuiObject?, -- drawn instead of the icon
}

type Entry = {
	window: Window,
	open: boolean,
	tween: Tween?,
}

local Controller = {}
-- The game's hook for a tap on the dimmer: the screen point and the window that was open; it may
-- act on a HUD button under that point (nil: the tap only closes).
Controller.passThrough = nil :: ((Vector2, string?) -> ())?

local M = Theme.Motion
local S = Theme.Size

local CLOSE_ACTION = "LihFolkUI_Close"
local PHONE_SHORT_SIDE = 520 -- safe-area short side (px) below which a touch device is a phone
local PLAYER_SCALE_MIN, PLAYER_SCALE_MAX = 0.8, 1.3

local started = false
local mainGui: ScreenGui? = nil
local dim: TextButton? = nil
local dimTween: Tween? = nil
local hud: Frame? = nil
-- The launcher a phone shows instead of the whole column (its label; see applyLayout).
Controller.MENU_LAUNCHER = "Menu"
-- Where a whole column of launchers starts, from the top of the safe area (nil: centred).
-- Ragdoll Lab: under its chaos meter.
Controller.COLUMN_TOP = 76 :: number?
-- Room kept free under a whole column (nil: none). Ragdoll Lab: PLAY and BUILD in the bottom left
-- corner of a computer or tablet (PLAY's top is 136 px up, and 10 px clear of it).
Controller.COLUMN_BOTTOM_ROOM = 150 :: number?
-- The launchers (labels) that stay on the HUD beside MENU on every device (nil: a phone shows MENU
-- alone and everything else shows the whole column). Ragdoll Lab (M6): SHOP, WEAPONS, SANDBOX and
-- MENU, the same on a phone and a computer; MENU's window holds the rest.
Controller.COLUMN_KEEP = nil :: { [string]: boolean }?
-- On a phone (its left edge is too short for a column of four, LayoutCheck) these and MENU stand two
-- to a row from PHONE_COLUMN_TOP px down the safe area to PHONE_COLUMN_END px under its middle,
-- drawn smaller to fit (never under a 44 px tap). Ragdoll Lab: the same three as everywhere.
Controller.PHONE_KEEP = nil :: { [string]: boolean }?
Controller.PHONE_COLUMN_TOP = 71 :: number -- (under the chaos meter, its badges clear of it)
Controller.PHONE_COLUMN_END = 40 :: number
local TAP_PX = 44
local hudScale: UIScale? = nil
local hudHidden: { [string]: boolean } = {} -- launchers kept off the column for now (their labels)
local entries: { [string]: Entry } = {}
local current: string? = nil
local returnFocus: GuiObject? = nil
local playerScale = 1
local closeOnBackdrop = true
local closeKeys: { Enum.KeyCode } = { Enum.KeyCode.ButtonB }
local closeBound = false
local listeners: { (name: string, isOpen: boolean) -> () } = {}

-- Forward declaration: closing is needed by the backdrop and the ButtonB action,
-- which are set up before the public close function below.
local closeWindow: (name: string?) -> ()

---------------------------------------------------------------------------
-- Device and input
---------------------------------------------------------------------------
-- "Touch", "Gamepad", "KeyboardAndMouse" (uses PreferredInput when the engine has it).
function Controller.preferredInput(): string
	local ok, value = pcall(function(): any
		return (UserInputService :: any).PreferredInput
	end)
	if ok and typeof(value) == "EnumItem" then
		return (value :: any).Name
	end
	local last = UserInputService:GetLastInputType()
	if last == Enum.UserInputType.Touch then
		return "Touch"
	elseif string.sub(last.Name, 1, 7) == "Gamepad" then
		return "Gamepad"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Touch"
	end
	return "KeyboardAndMouse"
end

function Controller.deviceKind(): DeviceKind
	local gui = mainGui
	local area = if gui then gui.AbsoluteSize else Vector2.new(1920, 1080)
	local short = math.min(area.X, area.Y)
	local ok, display = pcall(function(): any
		return (GuiService :: any).ViewportDisplaySize
	end)
	if ok and typeof(display) == "EnumItem" and (display :: any).Name == "Large" then
		return "console"
	end
	local tenFoot = false
	pcall(function()
		tenFoot = GuiService:IsTenFootInterface()
	end)
	if tenFoot then
		return "console"
	end
	if UserInputService.TouchEnabled then
		return if short < PHONE_SHORT_SIDE then "phone" else "tablet"
	end
	return "desktop"
end

-- Base scale before the fit clamp and touch floor.
local function baseScale(kind: DeviceKind, area: Vector2): number
	if kind == "console" then
		return 1.35 -- read from a sofa
	elseif kind == "phone" then
		return 1 -- the fit clamp and the touch floor decide on phones
	end
	return math.clamp(area.Y / 1000, 0.85, 1.4)
end

---------------------------------------------------------------------------
-- Layout: fit every window into the safe area
---------------------------------------------------------------------------
-- The left column's scale on a screen (its safe area): the HUD's own scale, made smaller when a
-- whole column of `count` launchers would not end above Controller.COLUMN_BOTTOM_ROOM (never
-- under half size). count 0: the MENU launcher alone (nothing to fit). LayoutCheck uses it too.
-- The launchers' own size against the windows' (a game can keep its HUD quieter: windows stay
-- full size, the column smaller).
Controller.HUD_SCALE = 1
function Controller.columnScale(area: Vector2, kind: DeviceKind, touch: boolean, count: number): number
	if kind == "phone" and Controller.PHONE_KEEP and count > 0 then
		-- The phone's short column: fitted between PHONE_COLUMN_TOP and PHONE_COLUMN_END (its badges
		-- 5 px over the top), a launcher never under a 44 px tap.
		local rows = math.ceil(count / 2)
		local natural = rows * S.hudButton + (rows - 1) * Theme.Space.sm
		local room = area.Y / 2 + Controller.PHONE_COLUMN_END - Controller.PHONE_COLUMN_TOP - 5
		-- (At most the kit's touch size: a bigger phone keeps the same column, so what sits beside
		-- it, the part counter, has a fixed place.)
		return math.clamp(room / natural, TAP_PX / S.hudButton, S.touchDrawnMin / S.touchMin)
	end
	local floor = if touch then S.touchDrawnMin / S.touchMin else 0
	local scale = math.max(math.min(baseScale(kind, area) * playerScale * Controller.HUD_SCALE, 1.3), floor)
	local top, room = Controller.COLUMN_TOP, Controller.COLUMN_BOTTOM_ROOM
	if count > 0 and top and room then
		local natural = count * S.hudButton + (count - 1) * Theme.Space.sm
		local fit = (area.Y - top - room) / natural
		-- (Never under the touch floor on a touch screen: a tap target stays a tap target.)
		scale = math.max(math.min(scale, math.max(fit, 0.5)), floor)
	end
	return scale
end

local function applyLayout()
	local gui = mainGui
	if not gui then
		return
	end
	local area = gui.AbsoluteSize
	if area.X <= 0 or area.Y <= 0 then
		return
	end
	local kind = Controller.deviceKind()
	local touch = kind == "phone" or kind == "tablet" or Controller.preferredInput() == "Touch"
	local floor = if touch then S.touchDrawnMin / S.touchMin else 0
	local margin = S.screenMargin * 2
	local wanted = baseScale(kind, area) * playerScale

	for _, entry in entries do
		local design = entry.window.designSize
		local fit = math.min((area.X - margin) / design.X, (area.Y - margin) / design.Y)
		local scale = math.max(math.min(wanted, fit), floor)
		-- When the touch floor beats the fit, shrink the slot instead; the body scrolls.
		local w = math.min(design.X, (area.X - margin) / scale)
		local h = math.min(design.Y, (area.Y - margin) / scale)
		entry.window.root.Size = UDim2.fromOffset(math.floor(w), math.floor(h))
		entry.window.fitScale.Scale = scale
	end

	local hs = hudScale
	if hs then
		-- (A whole column on a short computer window is drawn smaller so it ends above the room
		-- kept under it: Controller.columnScale.)
		local count = 0
		local column = hud
		local keep = Controller.COLUMN_KEEP
		local hasMenu = column ~= nil and column:FindFirstChild("Hud_" .. Controller.MENU_LAUNCHER) ~= nil
		if column and keep and hasMenu then
			-- (The kept launchers and MENU; on a phone only PHONE_KEEP's and MENU.)
			local shown = if kind == "phone" then (Controller.PHONE_KEEP or {}) else keep
			for _, child in column:GetChildren() do
				local label = string.sub(child.Name, 5)
				if child:IsA("GuiObject") and (shown[label] or label == Controller.MENU_LAUNCHER) and not hudHidden[label] then
					count += 1
				end
			end
		elseif column and not (kind == "phone" and hasMenu) then
			for _, child in column:GetChildren() do
				if child:IsA("GuiObject") and child.Name ~= "Hud_" .. Controller.MENU_LAUNCHER and not hudHidden[string.sub(child.Name, 5)] then
					count += 1
				end
			end
		end
		hs.Scale = Controller.columnScale(area, kind, touch, count)
	end
	-- On a phone (a short screen) a column of launchers would run into what sits above and below
	-- it on the left edge: when the game has added a MENU launcher (Controller.MENU_LAUNCHER), a
	-- phone shows only that one (its window lists the others); elsewhere every launcher but it.
	local column = hud
	local keep = Controller.COLUMN_KEEP
	if column and keep and column:FindFirstChild("Hud_" .. Controller.MENU_LAUNCHER) then
		-- The kept launchers and MENU on every device (MENU's window holds the rest): a column hung
		-- from COLUMN_TOP off a phone; on a phone PHONE_KEEP's and MENU, from PHONE_COLUMN_TOP.
		local phone = kind == "phone"
		local shown = if phone then (Controller.PHONE_KEEP or {}) else keep
		for _, child in column:GetChildren() do
			if child:IsA("GuiObject") then
				local label = string.sub(child.Name, 5) -- ("Hud_<label>")
				child.Visible = (shown[label] == true or label == Controller.MENU_LAUNCHER) and not hudHidden[label]
			end
		end
		-- (Two to a row on a phone: a list that wraps inside a column two launchers wide.)
		local list = column:FindFirstChildOfClass("UIListLayout")
		if list then
			list.FillDirection = if phone then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
			list.Wraps = phone
		end
		column.Size = UDim2.fromOffset(if phone then 2 * S.hudButton + Theme.Space.sm + 6 else S.hudButton + 6, 0)
		column.AnchorPoint = Vector2.new(0, 0)
		column.Position = UDim2.new(0, S.screenMargin, 0, if phone then Controller.PHONE_COLUMN_TOP else (Controller.COLUMN_TOP or 76))
		return
	end
	if column then
		local menu = column:FindFirstChild("Hud_" .. Controller.MENU_LAUNCHER)
		local phone = kind == "phone" and menu ~= nil
		for _, child in column:GetChildren() do
			if child:IsA("GuiObject") then
				local label = string.sub(child.Name, 5) -- ("Hud_<label>")
				child.Visible = (if child == menu then phone else not phone) and not hudHidden[label]
			end
		end
		-- The one MENU launcher sits at mid-height; a whole column hangs from near the top (a tall
		-- one centred would reach the corner controls at the bottom).
		if phone or Controller.COLUMN_TOP == nil then
			column.AnchorPoint = Vector2.new(0, 0.5)
			column.Position = UDim2.new(0, S.screenMargin, 0.5, 0)
		else
			column.AnchorPoint = Vector2.new(0, 0)
			column.Position = UDim2.new(0, S.screenMargin, 0, Controller.COLUMN_TOP)
		end
	end
end

---------------------------------------------------------------------------
-- Motion
---------------------------------------------------------------------------
-- Fraction of the way from `from` to `to` still left, given the current value.
local function remainingFraction(value: number, from: number, to: number): number
	if from == to then
		return 0
	end
	return math.clamp((to - value) / (to - from), 0, 1)
end

local function setDim(visible: boolean)
	local d = dim
	if not d then
		return
	end
	local previous = dimTween
	if previous then
		previous:Cancel()
	end
	dimTween = nil
	if visible then
		d.Visible = true
		if Theme.isReducedMotion() then
			d.BackgroundTransparency = M.dimTransparency
			return
		end
		local t = TweenService:Create(d, TweenInfo.new(M.dimTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = M.dimTransparency,
		})
		dimTween = t
		t:Play()
	else
		if Theme.isReducedMotion() then
			d.BackgroundTransparency = 1
			d.Visible = false
			return
		end
		local t = TweenService:Create(d, TweenInfo.new(M.closeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		t.Completed:Connect(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and current == nil then
				d.Visible = false
			end
		end)
		dimTween = t
		t:Play()
	end
end

local function animate(entry: Entry, wantOpen: boolean)
	local window = entry.window
	local motion = window.motionScale
	local previous = entry.tween
	if previous then
		previous:Cancel() -- leaves Scale where it is; we retarget from there
	end
	entry.tween = nil
	local reduced = Theme.isReducedMotion()

	if wantOpen then
		if not window.root.Visible then
			motion.Scale = if reduced then 1 else M.openFrom
			window.root.Visible = true
		end
		for _, loop in window.loops do
			loop:Play()
		end
		if reduced then
			motion.Scale = 1
			return
		end
		local remaining = remainingFraction(motion.Scale, M.openFrom, 1)
		local t = TweenService:Create(
			motion,
			TweenInfo.new(math.max(M.openTime * remaining, 0.05), M.openStyle, M.openDirection),
			{ Scale = 1 }
		)
		entry.tween = t
		t:Play()
	else
		local function finish()
			window.root.Visible = false
			for _, loop in window.loops do
				loop:Pause()
			end
		end
		if reduced or not window.root.Visible then
			finish()
			return
		end
		local remaining = remainingFraction(motion.Scale, 1, M.closeTo)
		local t = TweenService:Create(
			motion,
			TweenInfo.new(math.max(M.closeTime * remaining, 0.03), M.closeStyle, M.closeDirection),
			{ Scale = M.closeTo }
		)
		-- Rule: never hide on a cancelled tween (a reopen interrupted this close).
		t.Completed:Connect(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and not entry.open then
				finish()
			end
		end)
		entry.tween = t
		t:Play()
	end
end

---------------------------------------------------------------------------
-- Gamepad close action (bound only while a window is open)
---------------------------------------------------------------------------
local function onCloseAction(_action: string, inputState: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin and current ~= nil then
		closeWindow(nil)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function bindClose()
	if closeBound or #closeKeys == 0 then
		return
	end
	closeBound = true
	ContextActionService:BindActionAtPriority(
		CLOSE_ACTION,
		onCloseAction,
		false,
		Enum.ContextActionPriority.High.Value,
		table.unpack(closeKeys)
	)
end

local function unbindClose()
	if closeBound then
		closeBound = false
		ContextActionService:UnbindAction(CLOSE_ACTION)
	end
end

local function notify(name: string, isOpen: boolean)
	for _, fn in listeners do
		task.spawn(fn, name, isOpen)
	end
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
local function makeLayer(parent: Instance, name: string, insets: Enum.ScreenInsets, order: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = insets
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None -- no automatic stretching
	gui.DisplayOrder = order
	gui.Parent = parent
	return gui
end

function Controller.start(options: StartOptions?)
	if started then
		return
	end
	started = true
	local o: StartOptions = options or {}
	closeOnBackdrop = o.closeOnBackdrop ~= false
	if o.closeKeys then
		closeKeys = o.closeKeys
	end
	local order = o.displayOrder or 41

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Backdrop: edge to edge, never scaled, holds only the dimmer.
	local back = makeLayer(playerGui, "LihFolkUI_Backdrop", Enum.ScreenInsets.None, order - 1)
	local d = Instance.new("TextButton")
	d.Name = "Dimmer"
	d.Text = ""
	d.AutoButtonColor = false
	d.Selectable = false
	d.Size = UDim2.fromScale(1, 1)
	d.BackgroundColor3 = Theme.Palette.backdrop
	d.BackgroundTransparency = 1
	d.BorderSizePixel = 0
	d.Visible = false
	d.Parent = back
	d.Activated:Connect(function(input: InputObject?)
		if closeOnBackdrop and current ~= nil then
			local was = current
			closeWindow(nil)
			-- (A tap on a HUD button under the dimmer: the game may act on it too, so one tap switches
			-- windows instead of only closing this one. Controller.passThrough, set by the game.)
			local pass = Controller.passThrough
			if pass and input then
				pass(Vector2.new(input.Position.X, input.Position.Y), was)
			end
		end
	end)
	dim = d

	-- Main layer: everything interactive, inside the core UI safe area.
	local gui = makeLayer(playerGui, "LihFolkUI", Enum.ScreenInsets.CoreUISafeInsets, order)
	mainGui = gui

	-- HUD launcher column: left edge, vertically centred (clear of the top bar,
	-- the thumbstick and the jump button).
	local column = Instance.new("Frame")
	column.Name = "Launcher"
	column.BackgroundTransparency = 1
	column.AnchorPoint = Vector2.new(0, 0.5)
	column.Position = UDim2.new(0, S.screenMargin, 0.5, 0)
	column.Size = UDim2.fromOffset(S.hudButton + 6, 0) -- (a badge pokes out on the right)
	column.AutomaticSize = Enum.AutomaticSize.Y
	local columnList = Instance.new("UIListLayout")
	columnList.FillDirection = Enum.FillDirection.Vertical
	columnList.Padding = UDim.new(0, Theme.Space.sm)
	columnList.SortOrder = Enum.SortOrder.LayoutOrder
	columnList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	columnList.Parent = column
	local cs = Instance.new("UIScale")
	cs.Parent = column
	column.Parent = gui
	hud = column
	hudScale = cs

	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)
	pcall(function()
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(applyLayout)
	end)
	pcall(function()
		GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(applyLayout)
	end)
	UserInputService.LastInputTypeChanged:Connect(function()
		applyLayout()
	end)
	applyLayout()
end

---------------------------------------------------------------------------
-- Windows
---------------------------------------------------------------------------
function Controller.register(window: Window)
	Controller.start()
	assert(entries[window.name] == nil, `[LihFolkUI] a window named "{window.name}" is already registered`)
	local entry: Entry = { window = window, open = false, tween = nil }
	entries[window.name] = entry
	window.requestClose = function()
		closeWindow(window.name)
	end
	window.root.Visible = false
	window.root.Parent = mainGui
	applyLayout()
end

function Controller.isOpen(name: string): boolean
	local entry = entries[name]
	return entry ~= nil and entry.open
end

function Controller.getCurrent(): string?
	return current
end

function Controller.open(name: string)
	local entry = entries[name]
	if not entry then
		warn(`[LihFolkUI] open("{name}"): no window registered with that name`)
		return
	end
	if entry.open then
		return
	end
	local previousName = current
	if previousName and previousName ~= name then
		local other = entries[previousName]
		if other and other.open then
			other.open = false
			animate(other, false)
			notify(previousName, false)
		end
	else
		returnFocus = GuiService.SelectedObject -- opened from the HUD / world
	end

	entry.open = true
	current = name
	setDim(true)
	bindClose()
	animate(entry, true)
	Components.playSound("open")

	if Controller.preferredInput() == "Gamepad" then
		GuiService.SelectedObject = entry.window.defaultSelection or entry.window.closeButton.hit
	end
	notify(name, true)
end

closeWindow = function(name: string?)
	local target = name or current
	if target == nil then
		return
	end
	local entry = entries[target]
	if not entry or not entry.open then
		return
	end
	entry.open = false
	animate(entry, false)
	Components.playSound("close")

	if current == target then
		current = nil
		setDim(false)
		unbindClose()
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(entry.window.root) then
			local back = returnFocus
			if back and back:IsDescendantOf(game) and back.Visible then
				GuiService.SelectedObject = back
			else
				GuiService.SelectedObject = nil
			end
		end
		returnFocus = nil
	end
	notify(target, false)
end
Controller.close = closeWindow

function Controller.toggle(name: string)
	if Controller.isOpen(name) then
		Controller.close(name)
	else
		Controller.open(name)
	end
end

function Controller.closeAll()
	if current then
		Controller.close(current)
	end
end

-- Toggle a registered window from any GuiButton you made yourself.
function Controller.bindOpener(button: GuiButton, name: string): RBXScriptConnection
	return button.Activated:Connect(function()
		Controller.toggle(name)
	end)
end

-- Adds a themed launcher to the HUD column. Returns it so you can setBadge(true).
function Controller.addHudButton(options: HudButtonOptions): HudButton
	Controller.start()
	local made = Components.HudButton({
		label = options.label,
		icon = options.icon,
		theme = options.theme,
		layoutOrder = options.layoutOrder,
		picture = options.picture,
		parent = hud,
		onActivated = function()
			local go = options.onActivated
			if go then
				go()
			elseif options.window then
				Controller.toggle(options.window)
			end
		end,
	})
	applyLayout() -- (a phone shows the menu launcher or the others)
	return made
end

-- Keeps a launcher (by its label) off the column for now, or puts it back (the first minute hides
-- the ones that would open what it has not shown yet).
function Controller.setHudShown(label: string, shown: boolean)
	if (hudHidden[label] == true) == not shown then
		return
	end
	hudHidden[label] = if shown then nil else true
	applyLayout()
end

---------------------------------------------------------------------------
-- Preferences and events
---------------------------------------------------------------------------
-- Player UI size (0.8 to 1.3). The fit clamp still wins so a window never leaves the screen.
function Controller.setPlayerScale(value: number)
	playerScale = math.clamp(value, PLAYER_SCALE_MIN, PLAYER_SCALE_MAX)
	applyLayout()
end

function Controller.getPlayerScale(): number
	return playerScale
end

-- true / false forces Reduced Motion; nil follows the platform setting.
function Controller.setReducedMotion(value: boolean?)
	Theme.setReducedMotion(value)
end

-- Listen for open / close. Returns a function that removes the listener.
function Controller.onChanged(callback: (name: string, isOpen: boolean) -> ()): () -> ()
	table.insert(listeners, callback)
	return function()
		local index = table.find(listeners, callback)
		if index then
			table.remove(listeners, index)
		end
	end
end

-- The safe-area ScreenGui, for your own HUD pieces that should share the scaling rules.
function Controller.getGui(): ScreenGui?
	return mainGui
end

function Controller.refresh()
	applyLayout()
end

return Controller
