--!strict
-- Keybinds (phase L): one table for every keyboard shortcut in the game, so the controls, the
-- hints and the Controls window (K) all read the same keys, and a player can change any of them.
--
-- Each action has a stable id, a default key (in code: a new action always arrives with its
-- default) and a context. Keys only clash inside contexts that can be on at the same time:
--   Global: anywhere (windows, ragdoll, view, build on/off)
--   Play:   with the tool bar (tools, grab, catalog)
--   Build:  while building (turn, tilt, undo, parts)
-- so T can open TOOLS while playing and tilt a part while building. Setting a key that another
-- action in a clashing context has swaps the two (never blocks). Reserved keys (Roblox's own:
-- Esc, Tab, chat, camera zoom, shift lock, jump, walking) cannot be taken.
--
-- Only the keys a player changed are saved (ProgressService "Keys"); the server runs sanitize()
-- on them, so a saved table can never hold an unknown action, an unknown or reserved key, or
-- more entries than there are actions.

local UserInputService = game:GetService("UserInputService")

export type Context = "Global" | "Play" | "Build" | "Lab"
export type Action = { id: string, label: string, context: Context, default: string, group: string }

local Keybinds = {}

-- Client: true while the Controls window waits for a new key (no shortcut fires meanwhile).
Keybinds.capturing = false

-- Client: whether a key press should run shortcuts at all (not typing, not choosing a key).
function Keybinds.live(processed: boolean): boolean
	return not processed and not Keybinds.capturing
end

Keybinds.ACTIONS = table.freeze({
	-- Playing
	{ id = "Ragdoll", label = "Ragdoll yourself", context = "Global", default = "F", group = "PLAY" },
	{ id = "View", label = "Lab view / player view", context = "Global", default = "C", group = "PLAY" },
	-- (Round 2: lab view moved to C, the camera. Round 5: V is first person, the doctor's monitor is L
	-- like INJURIES L in the big ragdoll games.)
	{ id = "Doctor", label = "Doctor mode (hospital monitor)", context = "Global", default = "L", group = "PLAY" },
	{ id = "FirstPerson", label = "First person", context = "Global", default = "V", group = "PLAY" },
	{ id = "SlowMo", label = "Slow-mo over your lab", context = "Play", default = "Z", group = "PLAY" },
	{ id = "ReviveAll", label = "Revive all (your lab)", context = "Play", default = "X", group = "PLAY" },
	{ id = "Reload", label = "Reload", context = "Play", default = "R", group = "PLAY" },
	{ id = "Grab", label = "Grab", context = "Play", default = "G", group = "PLAY" },
	{ id = "SpawnDummy", label = "Spawn a dummy (press again: next type)", context = "Play", default = "H", group = "PLAY" }, -- (V8-2.5)
	-- (Owner, 21 Nov 2026: "keybinds on everything, so you never leave first person". The lab view's turn keys have
	-- their own context (Lab, never on with the player view's keys), so E is also USE in the player view.)
	{ id = "CamLeft", label = "Lab view: turn left", context = "Lab", default = "Q", group = "PLAY" },
	{ id = "CamRight", label = "Lab view: turn right", context = "Lab", default = "E", group = "PLAY" },
	{ id = "Use", label = "Use what you stand at (terminal, board, button)", context = "Play", default = "E", group = "PLAY" },
	{ id = "MissionSkip", label = "Skip the mission", context = "Play", default = "Minus", group = "PLAY" },
	{ id = "MissionHide", label = "Hide or show the mission card", context = "Play", default = "Equals", group = "PLAY" },
	{ id = "Recenter", label = "Lab view: back to the middle", context = "Play", default = "Home", group = "PLAY" },
	{ id = "CleanUp", label = "Sweep the lab clean", context = "Global", default = "Delete", group = "PLAY" },
	{ id = "BodyCard", label = "Hide or show the body card", context = "Global", default = "Period", group = "PLAY" },
	{ id = "Catalog", label = "All weapons", context = "Play", default = "T", group = "PLAY" },
	{ id = "Slot1", label = "Weapon slot 1", context = "Play", default = "One", group = "PLAY" },
	{ id = "Slot2", label = "Weapon slot 2", context = "Play", default = "Two", group = "PLAY" },
	{ id = "Slot3", label = "Weapon slot 3", context = "Play", default = "Three", group = "PLAY" },
	{ id = "Slot4", label = "Weapon slot 4", context = "Play", default = "Four", group = "PLAY" },
	{ id = "Slot5", label = "Weapon slot 5", context = "Play", default = "Five", group = "PLAY" },
	{ id = "Slot6", label = "Weapon slot 6", context = "Play", default = "Six", group = "PLAY" },
	-- Windows
	{ id = "Places", label = "Places", context = "Global", default = "M", group = "WINDOWS" },
	{ id = "Eggs", label = "Rank & eggs", context = "Global", default = "N", group = "WINDOWS" },
	{ id = "Shop", label = "Shop", context = "Global", default = "Y", group = "WINDOWS" },
	{ id = "Friends", label = "Friends", context = "Global", default = "P", group = "WINDOWS" },
	{ id = "Clip", label = "Record a clip / stop", context = "Global", default = "Semicolon", group = "WINDOWS" },
	{ id = "Rewards", label = "Gift (rewards)", context = "Global", default = "J", group = "WINDOWS" },
	{ id = "Settings", label = "Settings", context = "Global", default = "O", group = "WINDOWS" }, -- (V8-0.9)
	{ id = "Creator", label = "Creator mode (hide the screen buttons)", context = "Global", default = "U", group = "WINDOWS" },
	{ id = "CreatorWindow", label = "Clips & live window", context = "Global", default = "Comma", group = "WINDOWS" },
	{ id = "Controls", label = "This list (controls)", context = "Global", default = "K", group = "WINDOWS" },
	{ id = "GodWindow", label = "GOD MODE", context = "Global", default = "Seven", group = "WINDOWS" },
	{ id = "LabWindow", label = "Lab window", context = "Global", default = "Eight", group = "WINDOWS" },
	{ id = "MenuWindow", label = "More (menu)", context = "Global", default = "Nine", group = "WINDOWS" },
	-- Building
	{ id = "Build", label = "Build mode on/off", context = "Global", default = "B", group = "BUILD" },
	{ id = "Turn", label = "Turn the part", context = "Build", default = "R", group = "BUILD" },
	{ id = "Tilt", label = "Tilt the part", context = "Build", default = "T", group = "BUILD" },
	{ id = "PrevPart", label = "Previous part", context = "Build", default = "Q", group = "BUILD" },
	{ id = "NextPart", label = "Next part", context = "Build", default = "E", group = "BUILD" },
	{ id = "NextTab", label = "Next part group", context = "Build", default = "G", group = "BUILD" },
	{ id = "Undo", label = "Undo", context = "Build", default = "Z", group = "BUILD" },
	{ id = "PlayStop", label = "Play / stop the machine", context = "Build", default = "Return", group = "BUILD" },
	{ id = "Saves", label = "Saves", context = "Build", default = "X", group = "BUILD" },
	{ id = "ColourPrev", label = "Paint: previous colour", context = "Build", default = "LeftBracket", group = "BUILD" },
	{ id = "ColourNext", label = "Paint: next colour", context = "Build", default = "RightBracket", group = "BUILD" },
	{ id = "ToolPlace", label = "Place", context = "Build", default = "One", group = "BUILD" },
	{ id = "ToolDelete", label = "Delete", context = "Build", default = "Two", group = "BUILD" },
	{ id = "ToolPaint", label = "Paint", context = "Build", default = "Three", group = "BUILD" },
	{ id = "ToolTune", label = "Tune", context = "Build", default = "Four", group = "BUILD" },
	{ id = "ToolWire", label = "Wire", context = "Build", default = "Five", group = "BUILD" },
	{ id = "ToolPin", label = "Pin", context = "Build", default = "Six", group = "BUILD" },
	-- Streamer Mode (phase M): the keys a gift tool (TikFinity) presses. Only while it is on.
	{ id = "GiftDrop", label = "Gift: dummies drop in", context = "Global", default = "F1", group = "STREAMER" },
	{ id = "GiftBoom", label = "Gift: a big boom", context = "Global", default = "F2", group = "STREAMER" },
	{ id = "GiftSlowmo", label = "Gift: slow-mo bubble", context = "Global", default = "F3", group = "STREAMER" },
	{ id = "GiftRain", label = "Gift: dummy rain", context = "Global", default = "F4", group = "STREAMER" },
	{ id = "GiftFling", label = "Gift: fling me", context = "Global", default = "F5", group = "STREAMER" },
	{ id = "GiftParty", label = "Gift: party pops", context = "Global", default = "F6", group = "STREAMER" },
	{ id = "GiftGiant", label = "Gift: a giant dummy", context = "Global", default = "F7", group = "STREAMER" },
	{ id = "GiftTool", label = "Gift: next tool", context = "Global", default = "F8", group = "STREAMER" },
	-- (Round 3, M9: viewers' wishes. A gift tool presses one when a viewer types its command, and
	-- the streamer's hands switch to that tool in the bar. Only while Streamer Mode is on.)
	{ id = "Wish1", label = "Wish: tool 1 of your bar", context = "Global", default = "Insert", group = "STREAMER" },
	{ id = "Wish2", label = "Wish: tool 2 of your bar", context = "Global", default = "End", group = "STREAMER" },
	{ id = "Wish3", label = "Wish: tool 3 of your bar", context = "Global", default = "PageUp", group = "STREAMER" },
	{ id = "Wish4", label = "Wish: tool 4 of your bar", context = "Global", default = "PageDown", group = "STREAMER" },
} :: { Action })

Keybinds.byId = {} :: { [string]: Action }
for _, action in Keybinds.ACTIONS do
	Keybinds.byId[action.id] = action
end

-- Roblox's own keys (and walking, jumping, chat, camera): never ours to take.
local RESERVED = {
	Escape = true, Tab = true, Slash = true, Backquote = true, Space = true,
	W = true, A = true, S = true, D = true, I = true, O = true,
	Up = true, Down = true, Left = true, Right = true,
	LeftShift = true, RightShift = true, LeftControl = true, RightControl = true,
	LeftAlt = true, RightAlt = true, LeftMeta = true, RightMeta = true, LeftSuper = true, RightSuper = true,
	F9 = true, F10 = true, F11 = true, F12 = true, Print = true, Menu = true, CapsLock = true,
	Unknown = true, None = true,
}

-- The keys that can be bound: letters, digits, keypad digits, F1-F8 and a few named keys.
local ALLOWED: { [string]: boolean } = {}
for c = string.byte("A"), string.byte("Z") do
	ALLOWED[string.char(c)] = true
end
for _, name in { "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" } do
	ALLOWED[name] = true
	ALLOWED["Keypad" .. name] = true
end
for i = 1, 8 do
	ALLOWED["F" .. i] = true
end
for _, name in { "Return", "Backspace", "Delete", "Insert", "Home", "End", "PageUp", "PageDown", "Comma", "Period", "Semicolon", "Quote", "LeftBracket", "RightBracket", "Minus", "Equals", "BackSlash" } do
	ALLOWED[name] = true
end
for name in RESERVED do
	ALLOWED[name] = nil
end

local NAMES: { [string]: string } = {
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
	Return = "ENTER", Backspace = "BKSP", Delete = "DEL", Insert = "INS", PageUp = "PGUP", PageDown = "PGDN",
	Comma = ",", Period = ".", Semicolon = ";", Quote = "'", LeftBracket = "[", RightBracket = "]", Minus = "-", Equals = "=", BackSlash = "\\",
}

local current: { [string]: string } = {} -- id -> KeyCode name
for _, action in Keybinds.ACTIONS do
	current[action.id] = action.default
end
local listeners: { () -> () } = {}

local function clashes(a: Context, b: Context): boolean
	return a == b or a == "Global" or b == "Global"
end

function Keybinds.isAllowed(keyName: string): boolean
	return ALLOWED[keyName] == true
end

function Keybinds.isReserved(keyName: string): boolean
	return RESERVED[keyName] == true
end

-- The key an action is on now.
function Keybinds.key(id: string): Enum.KeyCode
	local name = current[id]
	return (Enum.KeyCode :: any)[name] or Enum.KeyCode.Unknown
end

-- Whether a pressed key is this action's (a keypad digit counts as the digit, and clashList treats
-- them as one key).
function Keybinds.is(id: string, keyCode: Enum.KeyCode): boolean
	local name = current[id]
	if not name then
		return false
	end
	local pressed = keyCode.Name
	if pressed == name then
		return true
	end
	return string.sub(pressed, 1, 6) == "Keypad" and string.sub(pressed, 7) == name
end

-- A key's label on this keyboard (a French player sees their own letters).
function Keybinds.label(keyCode: Enum.KeyCode | string): string
	local name = if typeof(keyCode) == "EnumItem" then (keyCode :: Enum.KeyCode).Name else keyCode :: string
	if NAMES[name] then
		return NAMES[name]
	end
	if string.sub(name, 1, 6) == "Keypad" and NAMES[string.sub(name, 7)] then
		return "NUM " .. NAMES[string.sub(name, 7)]
	end
	local code = (Enum.KeyCode :: any)[name]
	if code and #name == 1 then
		local ok, text = pcall(function()
			return UserInputService:GetStringForKeyCode(code)
		end)
		if ok and type(text) == "string" and text ~= "" then
			return string.upper(text)
		end
	end
	return string.upper(name)
end

-- A key's label for a small badge (a tool slot's corner): at most three characters, readable
-- ("NUM 1" -> "N1", "ENTER" -> "ENT", "PAGEUP" -> "PGU"). "" when the action has no key.
local BADGE: { [string]: string } = { ENTER = "ENT", RETURN = "ENT", SPACE = "SPC", TAB = "TAB", HOME = "HM", END = "END", PAGEUP = "PGU", PAGEDOWN = "PGD", INSERT = "INS", DELETE = "DEL", BACKSPACE = "BKS", LEFTSHIFT = "SHF", RIGHTSHIFT = "SHF", LEFTCONTROL = "CTL", RIGHTCONTROL = "CTL", LEFTALT = "ALT", RIGHTALT = "ALT" }
function Keybinds.badgeOf(id: string): string
	local label = Keybinds.labelOf(id)
	if label == "" then
		return ""
	end
	local numpad = string.match(label, "^NUM (.+)$")
	if numpad then
		return "N" .. string.sub(numpad, 1, 2)
	end
	local short = BADGE[string.gsub(string.upper(label), " ", "")]
	if short then
		return short
	end
	return string.sub(label, 1, 3)
end

-- An action's name without its note in brackets ("Creator mode", not "Creator mode (hide ...)").
function Keybinds.shortLabel(id: string): string
	local action = Keybinds.byId[id]
	if not action then
		return id
	end
	return (string.gsub(action.label, " %b()", ""))
end

-- The label of the key an action is on now ("" if none).
function Keybinds.labelOf(id: string): string
	local name = current[id]
	return if name then Keybinds.label(name) else ""
end

local function changed()
	for _, fn in listeners do
		task.spawn(fn)
	end
end

function Keybinds.onChanged(fn: () -> ())
	table.insert(listeners, fn)
end

-- Puts an action on a key. An action in a clashing context on that key swaps onto this one's old
-- key. Returns whether it was set, the id it swapped with, and why not.
function Keybinds.set(id: string, keyName: string): (boolean, string?, string?)
	local action = Keybinds.byId[id]
	if not action then
		return false, nil, "unknown"
	end
	if RESERVED[keyName] then
		return false, nil, "reserved"
	end
	if not ALLOWED[keyName] then
		return false, nil, "not allowed"
	end
	local old = current[id]
	if old == keyName then
		return true, nil, nil
	end
	local before = table.clone(current)
	local swapped: string? = nil
	for _, other in Keybinds.ACTIONS do
		if other.id ~= id and current[other.id] == keyName and clashes(other.context, action.context) then
			current[other.id] = old
			swapped = other.id
		end
	end
	current[id] = keyName
	-- The swapped action must be free on its new key in every context it is used in (a Global
	-- action swapped onto a key a Play or Build action has would fire two things): else no change.
	if #Keybinds.clashList() > 0 then
		table.clear(current)
		for k, v in before do
			current[k] = v
		end
		return false, swapped, "clash"
	end
	changed()
	return true, swapped, nil
end

function Keybinds.reset(id: string?)
	for _, action in Keybinds.ACTIONS do
		if id == nil or action.id == id then
			current[action.id] = action.default
		end
	end
	if id ~= nil then
		-- (Resetting one can land on a key another changed action now has: that one goes home too.)
		local action = Keybinds.byId[id]
		for _, other in Keybinds.ACTIONS do
			if action and other.id ~= id and current[other.id] == current[id] and clashes(other.context, action.context) then
				current[other.id] = other.default
			end
		end
	end
	changed()
end

-- Only what differs from the defaults (what gets saved).
function Keybinds.diff(): { [string]: string }
	local out = {}
	for _, action in Keybinds.ACTIONS do
		if current[action.id] ~= action.default then
			out[action.id] = current[action.id]
		end
	end
	return out
end

-- Server and client: a stored or sent table, cleaned (unknown actions, keys and junk dropped).
function Keybinds.sanitize(raw: unknown): { [string]: string }
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	local count = 0
	for id, keyName in raw :: { [any]: any } do
		count += 1
		if count > #Keybinds.ACTIONS then
			break
		end
		if type(id) == "string" and type(keyName) == "string" and Keybinds.byId[id] and ALLOWED[keyName] then
			out[id] = keyName
		end
	end
	return out
end

-- Loads saved changes on top of the defaults (through set, so no two clashing actions share a key).
function Keybinds.apply(saved: unknown)
	for _, action in Keybinds.ACTIONS do
		current[action.id] = action.default
	end
	-- (In the table's order, so the outcome never depends on how the saved table was stored.)
	local clean = Keybinds.sanitize(saved)
	for _, a in Keybinds.ACTIONS do
		local id, keyName = a.id, clean[a.id]
		if keyName == nil then
			continue
		end
		local action = Keybinds.byId[id]
		local taken = false
		for _, other in Keybinds.ACTIONS do
			if other.id ~= id and current[other.id] == keyName and clashes(other.context, action.context) then
				taken = true
			end
		end
		if taken then
			Keybinds.set(id, keyName) -- (swaps)
		else
			current[id] = keyName
		end
	end
	changed()
end

-- Tests: every pair of actions that would fire on one key in one context (should be none).
function Keybinds.clashList(): { string }
	local out = {}
	for i, a in Keybinds.ACTIONS do
		for j = i + 1, #Keybinds.ACTIONS do
			local b = Keybinds.ACTIONS[j]
			local ka = string.gsub(current[a.id], "^Keypad", "")
			local kb = string.gsub(current[b.id], "^Keypad", "")
			if ka == kb and clashes(a.context, b.context) then
				table.insert(out, a.id .. "/" .. b.id)
			end
		end
	end
	return out
end

return Keybinds
