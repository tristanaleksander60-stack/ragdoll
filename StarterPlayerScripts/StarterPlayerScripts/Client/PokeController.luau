--!strict
-- The tool bar and tapping. Phone first: big slabs at the bottom with the six tools of your
-- loadout, and a TOOLS slab pinned on the left that opens the catalog (ToolCatalog).
--
-- The bar is built from the LihFolk UI kit's slabs (Button), so it looks and presses like every
-- window: the selected tool is lit in its own colour with a gold ring; the others rest dimmed in
-- theirs. It always fits between the corner controls (thumbstick and jump button on a phone, BUILD
-- and the camera buttons otherwise): one row when the buttons can stay wide enough, otherwise two
-- rows (TOOLS tall on the left, the six tools three by two), still centred at the bottom. Nothing
-- scrolls, clips or rises into the side controls.
--
-- EQUIP in the catalog closes it and asks for a slot: a chip above the bar names the tool that is
-- waiting (with a cancel), the slots' gold rings breathe, and the one you tap gets the new tool
-- (nothing is replaced behind your back). Every tap that does nothing says why (a short hint), and
-- so does every use the server refuses (ToyRefused).
--
-- "hit" and "dummy" tools need a tapped dummy; "place" tools go on any surface.
-- Keyboard: 1-3 pick a slot (or place a tool being equipped), G the grab, T the catalog, Esc cancels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local BarRules = require(Shared:WaitForChild("BarRules"))
local Config = require(Shared:WaitForChild("Config"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Shop = require(Shared:WaitForChild("Shop"))
local HitFeel = require(Shared:WaitForChild("HitFeel"))
local HitMath = require(Shared:WaitForChild("HitMath"))
local Zones = require(Shared:WaitForChild("Zones"))
local WoundSpot = require(Shared:WaitForChild("WoundSpot"))
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local FxController = require(Client:WaitForChild("FxController"))
-- V9-NOW crosshair-sync: FeelV2 owns the live camera recoil angles; the mouse gun path adds the
-- same pixel offset the Crosshair module paints with, so the icon the player sees and the
-- raycast through camera:ViewportPointToRay always agree - including through burst recoil and
-- recovery. Touch and gamepad already come in through TouchShoot.fire with the offset applied.
local FeelV2 = require(Client:WaitForChild("FeelV2"))
local DummySim = require(Client:WaitForChild("DummySim"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local ToolCatalog = require(Client:WaitForChild("ToolCatalog"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local HudSlots = require(Client:WaitForChild("HudSlots")) -- (audit area 1: the newcomer window)
local HudGate = require(Client:WaitForChild("HudGate"))
local Toast = require(Client:WaitForChild("Toast"))
local ToolPicture = require(script.Parent:WaitForChild("ToolPicture"))
local NextUnlocks = require(script.Parent:WaitForChild("NextUnlocks"))
local AvatarMoves = require(Client:WaitForChild("AvatarMoves"))
local SessionClient = require(Client:WaitForChild("SessionClient"))
local AmmoClient = require(Client:WaitForChild("AmmoClient"))
local GunFeel = require(Client:WaitForChild("GunFeel"))
local lastAim = Vector2.zero -- (where the last shot was aimed: GunFeel's burst and beam)

local player = Players.LocalPlayer

local PokeController = {}
PokeController.weaponsHud = nil :: any -- the left column's WEAPONS tile (its tag: GiftClock)

-- Called after a toy request is sent: (toyId, worldPosition).
PokeController.onUsed = nil :: ((toyId: string, position: Vector3) -> ())?
-- (V9-0a review: more listeners, each told the same; NpcTalk hides the Talk prompts on every use, so
-- a hit from R2 or the touch SHOOT button, which the UI already took, still counts as an attack.)
PokeController.onUsedAlso = {} :: { (toyId: string, position: Vector3) -> () }

local P = Theme.Palette
local INK = P.ink
local GOLD = P.gold
local WHITE = Color3.new(1, 1, 1)

local GAP = 8
local EDGE = 10 -- room inside the bar's edges for the rings and the press pop
local MAX_W = 96
local MIN_W_ONE_ROW = 72 -- narrower than this and the bar goes to two rows (labels stay readable)
local MIN_W = 56 -- two rows: never under this (the kit's 44 px touch floor, with room for a word)
local PICK_TIME = 10 -- s a tool from the catalog waits for its slot
local HINT_GAP = 2.5 -- s between two "that did nothing" hints
local CHIP_H = 40 -- the close button is drawn 36 high; the kit grows its tap pad to the touch floor
local CHIP_GAP = 10
local CHIP_SIDE = 146 -- the chip keeps clear of the side columns (counter, Replay)

-- How much room the corner controls take on each side, in pixels from the screen edge (HudSlots
-- places them; LayoutCheck proves the bar misses them). A phone in the player view: the thumbstick
-- (left) and, on the right, the jump button with GRAB beside it (GRAB reaches 184 px in).
-- Otherwise: BUILD and PLAY (left), the recenter button and RAGDOLL (right).
local SIDE_TOUCH = 196
local SIDE_OTHER = 120

type Slab = {
	id: string,
	button: C.Button,
	ring: UIStroke,
	shade: Frame,
	pop: UIScale,
	picture: GuiObject?, -- the tool's picture (phase K: Icons.make, as in TOOLS)
	picScale: UIScale?,
	padding: UIPadding?,
	padTop: UDim?,
	number: TextLabel, -- the slot's number (its key on a keyboard), over its top corner
}

PokeController.NUMBER = 18 -- px, the slot number's badge
PokeController.TOOLS_MIN_TEXT = if KitStyle.V2 then 14 else 10 -- px: the WEAPONS slab's floor (UI v2: or its icon alone)

-- The help line under the bar on a computer (round 2, N5): what the picked weapon does and the
-- keys that matter, one line. The bar sits higher to make room for it.
PokeController.HELP_H = 22
PokeController.HELP_BOTTOM = 8
function PokeController.helpWidth(screen: Vector2): number
	-- (Clear of BUILD / PLAY on the left and the mouse help on the right.)
	return math.max(0, math.min(640, screen.X - 2 * 196))
end
local helpLabel: TextLabel? = nil
local barBottom = 12 -- px under the bar now (plan.bottom: more on a computer, for the help line)

-- Slabs narrower than this put the picture above the word instead of beside it (a phone in the
-- player view: about 57 px, too narrow for both in a row). LayoutCheck measures both ways.
PokeController.STACK_BELOW = 80
PokeController.PICTURE = 24 -- px, beside the word, at the least (it grows with the slab)
PokeController.PICTURE_STACKED = 22 -- px, above it (N7: a 3D model needs the room; 16 was a speck)
PokeController.STACK_TOP = 25 -- px of the face the picture takes above the word
-- The picture beside the word: half the slab's height (24 px on a 48 px phone slab, 30 px on a
-- 60 px PC slab), and the room it takes from the word (3 px each side of it).
function PokeController.pictureFor(height: number): (number, number)
	local size = math.max(PokeController.PICTURE, math.floor(height * 0.5))
	return size, size + 6
end
PokeController.PICTURE_PAD = select(2, PokeController.pictureFor(60))

-- UI v2: a slab's word never draws under 14 px. Where the word does not fit at that size (six
-- slots on an upright phone), the slab shows its drawn picture alone, bigger and centred (the
-- slot number and the ring still say which is which; the hit line names the tool when picked).
PokeController.SLAB_MIN_TEXT = if KitStyle.V2 then 14 else 12
local wordWidths: { [string]: number } = {}
function PokeController.wordWidth(text: string): number
	local known = wordWidths[text]
	if known then
		return known
	end
	-- (The legacy measure runs about a tenth narrower than the Fredoka One FontFace: LayoutCheck.)
	local ok, size = pcall(function(): Vector2
		return TextService:GetTextSize(text, PokeController.SLAB_MIN_TEXT, Enum.Font.FredokaOne, Vector2.new(10000, 100))
	end)
	local w = if ok then size.X * 1.15 else #text * PokeController.SLAB_MIN_TEXT * 0.62
	wordWidths[text] = w
	return w
end
function PokeController.iconOnly(width: number, height: number, text: string): boolean
	if not KitStyle.V2 then
		return false
	end
	local stacked = width < PokeController.STACK_BELOW
	local _, pad = PokeController.pictureFor(height)
	local roomW = width - 3 - (if stacked then 3 else pad)
	local roomH = height - Theme.Size.depthSmall - (if stacked then PokeController.STACK_TOP else 0) - 4
	return PokeController.wordWidth(text) > roomW or roomH < PokeController.SLAB_MIN_TEXT
end

local selected: string = Toys.default
local loadout: { string } = table.clone(Toys.defaultLoadout)
local slabs: { [string]: Slab } = {}
local toolsSlab: Slab? = nil
local lastFire: { [string]: number } = {}
local enabled = true
local doctorHold = false -- doctor mode (round 2, N3): the monitor takes the bar's place, tools rest
local catalogOpen = false
local allowed: { string }? = nil -- the first minute: exactly these tools, in this order
local barGui: ScreenGui? = nil
local barFrame: Frame? = nil
local slotsFrame: Frame? = nil
local pickChip: Frame? = nil
local nextFrame: Frame? = nil
local nextStacked = false -- (the next cards hold the first column: WEAPONS comes back as CANCEL while picking)
local pickLabel: TextLabel? = nil
local pulses: { Tween } = {}
local pendingEquip: string? = nil -- a tool from the catalog waiting for the slot to go in
local pendingToken = 0
local lastHint = 0
local cell = Vector2.new(MAX_W, 60)
local chipFits = true


-- Why the server refused a use, in words (Net ToyRefused).
local REFUSALS: { [string]: string } = {
	Busy = "Big tools need a breather. Try again in a second",
	Reload = "Reloading...", -- (round 5: the server counts the rounds too)
	Locked = "Try your starter tools first!",
	Occupied = "Someone is standing there. Pick another spot",
	Frozen = "It's frozen! Hit it to shatter it",
	TooFar = "Too far from you. Walk closer",
	Missed = "It moved! Tap it again",
	Loading = "Loading your progress. Try again in a moment",
	Spell = "One spell at a time. Wait for it to wear off",
	Already = "It's already under that spell!",
	Private = "That's someone else's lab. Ask them for an invite",
	GettingUp = "They just got up. Give them a moment!",
	Down = "They're down. Wait till they're back on their feet!",
	TooLate = "Too late, they're gone. A new one comes soon", -- (round 4, M10: the dead stay dead)
}
local REACH = Toys.REACH -- checked here first, so a tap out of reach never shows a hit that the
-- server then refuses

-- The tools on the bar right now, in order.
local function shown(): { string }
	return allowed or loadout
end

-- Relative luminance (WCAG 2.1) and the readable text colour on a face: ink or white, whichever
-- contrasts more.
local function luminance(c: Color3): number
	local function lin(v: number): number
		return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
end
local INK_L = luminance(INK)
local function textOn(face: Color3): Color3
	local l = luminance(face)
	local withWhite = 1.05 / (l + 0.05)
	local withInk = (l + 0.05) / (INK_L + 0.05)
	return if withInk > withWhite then INK else WHITE
end

-- A tool's slab colours: lit (selected) in its own colour, resting dimmed towards the panel dusk.
-- Resting slabs are dimmed towards the dusk panel until white text reads at 6:1 or better on the
-- lightest part of the face (the top of its gradient), so a pale tool (Zap, Freeze) is dimmed
-- further than a dark one; LayoutCheck reports the lowest ratio over the whole catalog. A lit slab
-- that would be too dark to stand out from the panel (a near-black cannon) is lightened.
local REST_CONTRAST = 6
local function contrastWithWhite(face: Color3): number
	return 1.05 / (luminance(face) + 0.05)
end
local function restingTop(color: Color3): number
	-- (Dark glass, N5: a resting slab is mostly the panel's near-black with a tint of its tool's
	-- colour; the picked one is lit in its full colour.)
	local t = 0.74
	while t < 0.9 and contrastWithWhite(color:Lerp(P.dusk, t)) < REST_CONTRAST do
		t += 0.02
	end
	return t
end
local function swatchFor(color: Color3, lit: boolean): Theme.Swatch
	local base = if lit and luminance(color) < 0.12 then color:Lerp(WHITE, 0.35) else color
	local t = if lit then 0 else restingTop(color)
	local bottom = if lit then base else color:Lerp(P.dusk, math.min(t + 0.15, 0.95))
	local top = if lit then base:Lerp(WHITE, 0.3) else color:Lerp(P.dusk, t)
	local text = if lit then textOn(bottom:Lerp(top, 0.5)) else WHITE
	return {
		top = top,
		bottom = bottom,
		shade = bottom:Lerp(INK, 0.5),
		text = text,
		textStroke = if text == WHITE then INK else nil,
	}
end

-- Checks: the lowest white-on-face contrast over every resting slab in the catalog, and which tool.
function PokeController.restingContrast(): (number, string)
	local worst, which = math.huge, ""
	for _, toy in Toys.list do
		local ratio = contrastWithWhite(swatchFor(toy.color, false).top)
		if ratio < worst then
			worst, which = ratio, toy.id
		end
	end
	return worst, which
end

-- The selected tool's ring: gold on a dark face, ink on a light one (gold vanishes on yellow).
local function ringFor(color: Color3): Color3
	return if luminance(color:Lerp(WHITE, 0.15)) > 0.45 then INK else GOLD
end

local function reducedMotion(): boolean
	return Theme.isReducedMotion()
end

local function hint(text: string)
	local now = os.clock()
	if now - lastHint < HINT_GAP then
		return
	end
	lastHint = now
	Toast.show(text, P.gold)
end

-- The slab's picture hops (selected, or just put in the bar).
local function hopPicture(slab: Slab)
	local scale = slab.picScale
	if not scale or reducedMotion() then
		return
	end
	scale.Scale = 1.45
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- A slab pops (a tool just put in the bar, so the eye finds where it went).
local function pop(slab: Slab)
	if reducedMotion() then
		return
	end
	slab.pop.Scale = 1.15
	TweenService:Create(slab.pop, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	hopPicture(slab)
end

-- Beside the word on a wide slab, above it on a narrow one.
local function placePicture(slab: Slab, width: number, height: number)
	local icon, padding = slab.picture, slab.padding
	if not icon or not padding then
		return
	end
	local label = slab.button.label
	if PokeController.iconOnly(width, height, label.Text) then
		-- (UI v2: the picture alone, centred and as big as the face allows.)
		label.Visible = false
		local size = math.max(PokeController.PICTURE_STACKED, math.min(width - 10, height - Theme.Size.depthSmall - 8))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Size = UDim2.fromOffset(size, size)
		return
	end
	label.Visible = label.Text ~= ""
	if width < PokeController.STACK_BELOW then
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 3)
		icon.Size = UDim2.fromOffset(PokeController.PICTURE_STACKED, PokeController.PICTURE_STACKED)
		padding.PaddingLeft = UDim.new(0, 3)
		padding.PaddingTop = UDim.new(0, PokeController.STACK_TOP)
	else
		local size, pad = PokeController.pictureFor(height)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 3, 0.5, 0)
		icon.Size = UDim2.fromOffset(size, size)
		padding.PaddingLeft = UDim.new(0, pad)
		padding.PaddingTop = slab.padTop or padding.PaddingTop
	end
end

local function stopPulses()
	for _, t in pulses do
		t:Cancel()
	end
	table.clear(pulses)
end

local heldSent: string? = nil -- the tool the server shows in your avatar's hand (HeldService)

-- The help line's words for the picked weapon.
function PokeController.helpText(id: string, lab: boolean): string
	local toy = Toys.byId[id]
	-- V8-0.2 (the pad pass): while a pad is the last input, its own buttons, never "Click", "1-6"
	-- or a keyboard key (B is RAGDOLL on a pad, not the sandbox).
	if (Config :: any).V8_FIRST_HIT and string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad" then
		local PadMap = require(Shared:WaitForChild("PadMap")) :: any
		local okA, a = pcall(function()
			return UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA)
		end)
		local ps = okA and type(a) == "string" and string.find(string.lower(a), "cross", 1, true) ~= nil
		local fire, slot, weapons = PadMap.glyph("Fire", ps), PadMap.glyph("Slot", ps), PadMap.glyph("Weapons", ps)
		local what = if not toy then "pick a weapon"
			elseif toy.kind == "grab" then "grab a dummy, " .. PadMap.glyph("Grab", ps) .. " throws"
			elseif toy.kind == "dummy" or toy.kind == "place" then "put down the " .. toy.label
			else "use the " .. toy.label
		return string.format("%s %s  \u{00B7}  %s switch  \u{00B7}  %s all weapons", fire, what, slot, weapons)
	end
	local first: string
	if not toy then
		first = "Pick a weapon in the bar"
	elseif toy.kind == "grab" then
		first = if lab then "Press on a dummy and drag it, let go to throw" else "Pick a dummy up, swing it, throw it"
	elseif toy.kind == "dummy" or toy.kind == "place" then
		first = "Click the ground to put down the " .. toy.label
	else
		first = "Click a dummy to use the " .. toy.label
	end
	-- (Audit area 1: a newcomer's first visit shows only what to do now, until the HUD comes in.)
	if time() < HudSlots.newcomerUntil then
		return first
	end
	-- (UI audit 21 Nov 2026: with the big HUD the keys are its chips and the slot numbers; the line
	-- says only what the tool in your hand does.)
	if HudGate.active() then
		return first
	end
	-- The keys as they are bound now (a part whose key is unbound is left out).
	local parts = { first }
	-- (1-6 only while the slots are on 1 to 6; rebound, each slot shows its own key instead.)
	local inOrder = true
	for i = 1, Toys.SLOTS do
		if Keybinds.labelOf("Slot" .. i) ~= tostring(i) then
			inOrder = false
		end
	end
	table.insert(parts, if inOrder then "1-" .. Toys.SLOTS .. " switch" else "slot keys switch")
	local catalog = Keybinds.labelOf("Catalog")
	if catalog ~= "" then
		table.insert(parts, catalog .. " all weapons")
	end
	local build = Keybinds.labelOf("Build")
	if build ~= "" then
		table.insert(parts, build .. " sandbox")
	end
	return table.concat(parts, "  \u{00B7}  ")
end

-- 21 Nov 2026 (Config.ICON_SIGNS, the owner: "no distracting text, icons a child understands"): the
-- help line as pictures: the mouse's click, the tool in your hand, an arrow, what it is used on (a
-- dummy, or the floor for a thing you put down). A pad keeps its words (its buttons have names).
local HELP_ICON = 28
local function iconHelp(label: TextLabel, id: string): boolean
	local okPad = string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
	if not (Config :: any).ICON_SIGNS or okPad then
		local strip = label:FindFirstChild("IconStrip")
		if strip then
			strip:Destroy()
		end
		return false
	end
	local Icons = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIIcons")) :: any
	local toy = Toys.byId[id]
	local target = if toy and (toy.kind == "place") then "sign_target" else "guide_feed"
	local key = id .. "|" .. target
	local strip = label:FindFirstChild("IconStrip")
	if strip and strip:GetAttribute("Key") == key then
		return true
	end
	if strip then
		strip:Destroy()
	end
	local row = Instance.new("Frame")
	row.Name = "IconStrip"
	row:SetAttribute("Key", key)
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	local function add(name: string, order: number)
		if Icons.has(name) then
			local pic = Icons.make(name, UDim2.fromOffset(HELP_ICON, HELP_ICON))
			pic.LayoutOrder = order
			pic.Parent = row
		end
	end
	add("hud_click", 1)
	add("tool_" .. id, 2)
	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromOffset(22, HELP_ICON)
	arrow.LayoutOrder = 3
	arrow.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	arrow.TextSize = 22
	arrow.TextColor3 = Color3.fromRGB(255, 214, 90)
	arrow.Text = "\u{279C}"
	arrow.Parent = row
	add(target, 4)
	row.Parent = label
	return true
end

local function refreshHelp()
	local label = helpLabel
	if label then
		if iconHelp(label, selected) then
			label.Text = ""
			label.Size = UDim2.fromOffset(4 * HELP_ICON + 4 * 6 + 22 + 24, PokeController.HELP_H + 8)
			return
		end
		label.Text = PokeController.helpText(selected, ViewMode.isLab())
		local parent = label.Parent
		if parent and parent:IsA("LayerCollector") then
			local room = PokeController.helpWidth(parent.AbsoluteSize)
			local words = TextService:GetTextSize(label.Text, 15, Enum.Font.GothamBold, Vector2.new(10000, PokeController.HELP_H)).X
			label.Size = UDim2.fromOffset(math.min(room, words + 28), PokeController.HELP_H)
		end
	end
end
PokeController.refreshHelp = refreshHelp -- (FirstVisit: the full help line comes back with the HUD)

-- Fired when what the hand can do changes (the tool picked, the bar on or off, doctor mode,
-- picking a slot): the crosshair listens instead of looking all the time.
local changedEvent = Instance.new("BindableEvent")
PokeController.changed = changedEvent.Event

-- UI audit 21 Nov 2026 (the owner: "everything 3D and interactive"): the weapon in your hand shows
-- as its real 3D model on its slab, turning slowly (faster under the pointer, a drag turns it:
-- Ui3D); the others keep their drawn pictures. One live model at a time, none on a low-end device
-- (ToolPicture falls back to the drawing by itself).
local function live3D(slab: any, id: string, on: boolean)
	local pic = slab.picture
	if not pic then
		return
	end
	local live = pic:FindFirstChild("Live3D")
	if on and not live then
		local turning = ToolPicture.make(id, UDim2.fromScale(1, 1), nil, true)
		if not turning:FindFirstChild("View") then
			turning:Destroy() -- (no model, or a low-end device: the drawing stays)
			return
		end
		turning.Name = "Live3D"
		turning.AnchorPoint = Vector2.zero
		turning.Position = UDim2.fromScale(0, 0)
		turning.ZIndex = 5
		for _, d in turning:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 5
			end
		end
		for _, child in pic:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = false
			end
		end
		turning.Parent = pic
	elseif not on and live then
		live:Destroy()
		for _, child in pic:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = true
			end
		end
	end
end

local function refresh()
	changedEvent:Fire()
	refreshHelp()
	-- (Doctor mode rests the tools: the hand is empty, "", so no patient sees a gun.)
	local want = if doctorHold then "" else selected
	if want ~= heldSent then
		heldSent = want
		Net.event(Net.Names.Hold):FireServer(want)
	end
	local picking = pendingEquip ~= nil
	for id, slab in slabs do
		local toy = Toys.byId[id]
		local lit = id == selected and not picking
		live3D(slab, id, lit and Config.UI_3D == true)
		slab.button.setSwatch(swatchFor(toy.color, lit))
		-- Colour plus one more cue: the selected tool (or, while picking, every slot) has a ring.
		slab.ring.Enabled = lit or picking
		slab.ring.Color = if picking then GOLD else ringFor(toy.color)
		if not picking then
			slab.ring.Transparency = 0
		end
	end
	ToolCatalog.refresh()
end

export type Plan = {
	rows: number,
	perRow: number,
	cell: Vector2, -- one slot
	size: Vector2, -- the whole bar, outline room included
	bottom: number, -- gap under the bar
	chip: boolean, -- room for the pick chip above the bar (clear of the top HUD rows)
	chipWidth: number, -- as wide as the bar, but clear of the side columns
	next: number, -- round 5: the locked "next unlock" cards after the slots (NextUnlocks)...
	nextColumns: number, -- ...in this many columns: one slot each in one row, or one column of small cards
	nextStacked: boolean, -- (no longer used: the cards never stack; kept false)
	nextRow: boolean, -- the next cards on a row of their own under the slots (a phone, a tablet)
	lead: number, -- columns before the slots (WEAPONS)
	shown: number, -- slots drawn (a small landscape phone shows the first ones that fit; the rest stay in WEAPONS)
}

-- The chip stays below this line: under the top HUD rows and any toast (LayoutCheck checks it on
-- every screen).
local CHIP_CLEAR_TOP = 96

-- Where the bar goes on a screen of this size: one row, or two rows when one would make the
-- buttons too narrow; always between the side margins, always at the bottom. Pure (layout tests
-- run it for other screen sizes).
-- On a phone the bar keeps clear of the left edge's launchers (round 3, M6: SHOP, WEAPONS, SANDBOX
-- and MENU two to a row, 136 px wide at most, and 10 px between).
PokeController.PHONE_SIDE_MIN = 146
-- A landscape phone's GRAB/SHOOT box (HudSlots: 108 from the right, 76 wide) plus LayoutCheck's clearance
-- (3 px outlines on both and a 4 px gap).
PokeController.PHONE_THUMB_RIGHT = 196
PokeController.NEXT_SHOWN = NextUnlocks.SHOWN
PokeController.NEXT_SIDE = 226 -- px each side on a computer with the next cards: the longer bar clears the
-- part counter beside PLAY (left) and the mouse help (right)
PokeController.CHIP_SIDE_WIDE = 222 -- the pick chip clears the counter too off a phone
PokeController.CHIP_MAX = 700 -- ...and is never wider than it was before the next cards (clear of the gift guide: 720 left 1 px at 1280 wide, PC LayoutCheck 19 Nov)
-- Phase 0: a phone held upright in the walk view: the bar sits over the thumb row (the move stick,
-- SHOOT / GRAB and the jump button, with RUN and THROW over them: HudSlots, portrait).
PokeController.PORTRAIT_BOTTOM = 180
function PokeController.plan(screen: Vector2, touch: boolean, lab: boolean, withTools: boolean, count: number, upcoming: number?): Plan
	local up = upcoming or PokeController.NEXT_SHOWN
	local side = PokeController.sideMargin(touch, lab)
	local phone = math.min(screen.X, screen.Y) <= 500
	if phone then
		side = math.max(side, PokeController.PHONE_SIDE_MIN)
	end
	if phone and touch then
		-- (PC play test 19 Nov: with 6 slots, the next cards made the bar two rows on a landscape
		-- phone, over JUMP/SHOOT/GRAB. The WEAPONS button already names the next weapon there.)
		-- (V10 phase 1, owner: "the next 3 weapons from the first join": the data shows every phone held upright,
		-- where there is room for their own row under the slots; only a landscape phone still goes without.)
		-- (V10, owner: phones play in landscape now and must still see the next 3 weapons: they go on their own row.)
	end
	if not touch and up > 0 then
		side = math.max(side, PokeController.NEXT_SIDE)
	end
	local lead = if withTools then 1 else 0
	local function widthFor(columns: number, margin: number): number
		return math.floor((screen.X - 2 * margin - (columns - 1) * GAP - 2 * EDGE) / columns)
	end
	-- One row: WEAPONS, your slots, then the next cards, each a slot wide. Too narrow for that (a
	-- phone, a tablet in the walk view): the next cards go on a row of their own under the slots.
	local rows, perRow, tail, nextRow = 1, count, up, false
	local shownCount = count
	local w = widthFor(lead + count + up, side)
	local landscapePhone = phone and touch and screen.X > screen.Y
	if landscapePhone and not lab then
		-- A landscape phone keeps one short row between the move stick and GRAB/SHOOT (their box
		-- ends PHONE_THUMB_RIGHT from the right edge), never the full width over them (PC play
		-- test 19 Nov, 6 slots): as many slots as fit at the 44 px touch floor, at least 3.
		local clear = PokeController.PHONE_THUMB_RIGHT
		local fit = math.floor((screen.X - 2 * clear - 2 * EDGE + GAP) / (44 + GAP)) - lead
		shownCount = math.clamp(fit, math.min(3, count), count)
		perRow = shownCount
		w = math.clamp(widthFor(lead + shownCount, clear), 44, MAX_W)
	elseif landscapePhone and w < MIN_W_ONE_ROW then
		w = math.max(w, 44) -- (the lab view: no thumb buttons, one row at the touch floor)
	elseif w < MIN_W_ONE_ROW then
		perRow = math.max(count, up)
		tail = 0
		nextRow = up > 0
		rows = math.ceil(count / math.max(perRow, 1)) + (if nextRow then 1 else 0)
		w = widthFor(perRow + lead, side)
		if w < MIN_W then
			w = widthFor(perRow + lead, 12) -- a phone held upright: the whole width
		end
	end
	w = math.clamp(w, 44, MAX_W)
	if phone and touch and screen.Y > screen.X then
		-- An upright phone: the slots that fit across at the 44 px floor (a 360 px Android fits 5
		-- of 6 with WEAPONS; PC LayoutCheck 19 Nov found the bar off screen).
		local fit = math.floor((screen.X - 24 - 2 * EDGE + GAP) / (44 + GAP)) - lead
		if fit < shownCount then
			shownCount = math.max(fit, 1)
			perRow = shownCount
			rows = 1 + (if nextRow then 1 else 0)
			w = math.clamp(widthFor(lead + shownCount, 12), 44, MAX_W)
		end
	end
	-- Phones are short: slabs 48 high (the touch floor is 44) keep the two-row bar low on screen.
	local h = if touch and math.min(screen.X, screen.Y) <= 500 then 48 elseif touch then 58 else 60
	local columns = perRow + lead + tail
	local size = Vector2.new(2 * EDGE + columns * w + (columns - 1) * GAP, 2 * EDGE + rows * h + (rows - 1) * GAP)
	return {
		rows = rows,
		perRow = perRow,
		cell = Vector2.new(w, h),
		size = size,
		bottom = if touch and phone and screen.Y > screen.X and not lab then PokeController.PORTRAIT_BOTTOM
			elseif touch then 12
			else PokeController.HELP_BOTTOM + PokeController.HELP_H + 12,
		chip = screen.Y - 12 - size.Y - CHIP_H - CHIP_GAP >= CHIP_CLEAR_TOP,
		chipWidth = math.min(size.X - 2 * EDGE, screen.X - 2 * (if phone then CHIP_SIDE else PokeController.CHIP_SIDE_WIDE), PokeController.CHIP_MAX),
		next = up,
		nextColumns = if nextRow then up else tail,
		nextStacked = false,
		nextRow = nextRow,
		lead = lead,
		shown = shownCount,
	}
end
-- Places every slab per the plan, shows the bar's tools in order (and TOOLS after the first
-- minute) and keeps the chip above the bar.
-- (A tool's slab is made the first time the bar needs it: ensureSlab, below makeSlab.)
local slotsParent: Instance? = nil
local ensureSlab: (id: string) -> Slab?
local drawTools: (picking: boolean) -> () -- (below, with the pick chip)
local toolsIconOnly = false -- UI v2: the WEAPONS slab shows its icon alone (drawTools)
local toolsPicking = false

local function layout()
	local frame, gui, slotsBox = barFrame, barGui, slotsFrame
	if not frame or not gui or not slotsBox then
		return
	end
	local list = shown()
	for _, id in list do
		ensureSlab(id)
	end
	local withTools = allowed == nil
	local touch = ViewMode.isTouch()
	local plan = PokeController.plan(gui.AbsoluteSize, touch, ViewMode.isLab(), withTools, #list, NextUnlocks.count())
	chipFits = plan.chip
	local w, h, perRow = plan.cell.X, plan.cell.Y, plan.perRow
	cell = plan.cell
	local tall = plan.rows * h + (plan.rows - 1) * GAP
	local lead = plan.lead

	local tools = toolsSlab
	if tools then
		tools.button.root.Visible = withTools and (not plan.nextStacked or pendingEquip ~= nil)
		tools.button.root.Size = UDim2.fromOffset(w, tall)
		tools.button.root.Position = UDim2.fromOffset(EDGE, EDGE)
		local iconOnly = KitStyle.V2 and (PokeController.wordWidth("WEAPONS") > w - 8 or PokeController.wordWidth("CANCEL") > w - 8)
		if iconOnly ~= toolsIconOnly then
			toolsIconOnly = iconOnly
			drawTools(toolsPicking)
		end
	end
	for id, slab in slabs do
		local index = table.find(list, id)
		if index and index > plan.shown then
			index = nil -- (a small landscape phone: past the slots that fit)
		end
		local root = slab.button.root
		root.Visible = index ~= nil
		if index then
			local r = (index - 1) // perRow
			local c = (index - 1) % perRow
			root.Size = UDim2.fromOffset(w, h)
			root.Position = UDim2.fromOffset((lead + c) * (w + GAP), r * (h + GAP))
			placePicture(slab, w, h)
			-- On a keyboard, the key it is on (1 to 6 by default; a long key name in three letters at
			-- most, Keybinds.badgeOf: "N1" for the number pad; the badge widens for it; a slot with
			-- no key shows none). Elsewhere, its number.
			if UserInputService.KeyboardEnabled then
				local key = if index <= Toys.SLOTS then Keybinds.badgeOf("Slot" .. index) else ""
				slab.number.Text = key
				slab.number.Visible = key ~= ""
			else
				slab.number.Text = tostring(index)
				slab.number.Visible = index <= 9
			end
		end
	end
	-- Round 5: the next unlocks after the last column of slots.
	local nextBox = nextFrame
	if nextBox then
		nextStacked = plan.nextStacked
		nextBox.Visible = plan.nextColumns > 0 and not (plan.nextStacked and pendingEquip ~= nil)
		local slotRows = math.ceil(#list / math.max(perRow, 1))
		nextBox.Position = if plan.nextRow
			then UDim2.fromOffset(EDGE + lead * (w + GAP), EDGE + slotRows * (h + GAP))
			else UDim2.fromOffset(EDGE + (lead + perRow) * (w + GAP), EDGE)
		nextBox.Size = UDim2.fromOffset(plan.nextColumns * w + math.max(0, plan.nextColumns - 1) * GAP, h)
		NextUnlocks.shape(plan.nextStacked, plan.cell, GAP)
	end
	frame.Size = UDim2.fromOffset(plan.size.X, plan.size.Y)
	slotsBox.Position = UDim2.fromOffset(EDGE, EDGE)
	slotsBox.Size = UDim2.new(1, -2 * EDGE, 1, -2 * EDGE)
	barBottom = plan.bottom
	frame.Position = UDim2.new(0.5, 0, 1, -plan.bottom)
	-- What it was laid out for (LayoutCheck.live re-plans from these and compares).
	frame:SetAttribute("Touch", touch)
	frame:SetAttribute("Lab", ViewMode.isLab())
	frame:SetAttribute("WithTools", withTools)
	frame:SetAttribute("Count", #list)
	frame:SetAttribute("Upcoming", plan.next)
	local chipTop = gui.AbsoluteSize.Y - plan.bottom - plan.size.Y - CHIP_H - CHIP_GAP
	Toast.setFloor(function()
		return chipTop - 10 -- toasts end above the pick chip (and so above the bar)
	end)
	if pickChip then
		pickChip.Size = UDim2.fromOffset(plan.chipWidth, CHIP_H)
	end
	frame.Visible = not catalogOpen
	local help = helpLabel
	if help then
		-- (UI audit 21 Nov 2026: as wide as its words, never a long empty strip under other things.)
		local room = PokeController.helpWidth(gui.AbsoluteSize)
		local words = TextService:GetTextSize(help.Text, 15, Enum.Font.GothamBold, Vector2.new(10000, PokeController.HELP_H)).X
		help.Size = UDim2.fromOffset(math.min(room, words + 28), PokeController.HELP_H)
		help.Visible = not touch and not catalogOpen and withTools
	end

	if not table.find(list, selected) and #list > 0 then
		selected = list[1]
	end
	-- A turned phone or a resized window: the chip shows (or hides) for the new screen.
	if pickChip then
		pickChip.Visible = pendingEquip ~= nil and chipFits
	end
	refresh()
end

local function select(id: string)
	if Toys.byId[id] and table.find(shown(), id) then
		local changed = selected ~= id
		selected = id
		refresh()
		local slab = slabs[id]
		if changed and slab then
			hopPicture(slab)
		end
	end
end

-- The bar's first slab: WEAPONS, or CANCEL while a slot is picked. UI v2: where the word does not
-- fit at the 14 px floor (an upright phone), the drawn toolbox (or a close mark) alone.
-- (session v850, owner: "tilføj så man kan se en keybind til våben menuen ved siden af ens våben i
-- hotbaren hvor der står WEAPONS"): on a keyboard, the catalog's keybind shows next to the word
-- (e.g. "WEAPONS [T]"). Touch/pad get the plain word; CANCEL also has no keybind (the picker is
-- driven by the slot keys, and a long key would push CANCEL off narrow screens).
drawTools = function(picking: boolean)
	toolsPicking = picking
	local tools = toolsSlab
	if not tools then
		return
	end
	-- (V10, owner: "make the weapons keybind visible"): a key chip in the WEAPONS button's corner, like the
	-- other squares, on a keyboard, whatever the button shows.
	do
		local root = tools.button.root
		local kb = UserInputService.KeyboardEnabled and not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
		local key = if kb then Keybinds.badgeOf("Catalog") else ""
		local chip = root:FindFirstChild("KeyChip") :: TextLabel?
		if not chip then
			local made = Instance.new("TextLabel")
			made.Name = "KeyChip"
			made.Size = UDim2.fromOffset(22, 20)
			made.Position = UDim2.fromOffset(3, 3)
			made.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
			made.BackgroundTransparency = 0.1
			made.TextColor3 = Color3.new(1, 1, 1)
			made.Font = Enum.Font.GothamBlack
			made.TextSize = 12
			made.ZIndex = 20
			local r = Instance.new("UICorner")
			r.CornerRadius = UDim.new(0, 5)
			r.Parent = made
			made.Parent = root
			chip = made
		end
		local c = chip :: TextLabel
		c.Text = key
		c.Visible = key ~= "" and not picking
	end
	if toolsIconOnly then
		-- (V10, owner: "WEAPONS must always show its key": the key beside the picture on a keyboard.)
		local key = if not picking and UserInputService.KeyboardEnabled and not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then Keybinds.labelOf("Catalog") else ""
		tools.button.setText(if key ~= "" then "[" .. key .. "]" else "")
		tools.button.setIcon(if picking then "close" else "toolbox")
	else
		tools.button.setIcon(nil)
		local label = if picking then "CANCEL" else "WEAPONS"
		if not picking and UserInputService.KeyboardEnabled and not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then
			local key = Keybinds.labelOf("Catalog")
			if key and key ~= "" then
				label = "WEAPONS [" .. key .. "]"
			end
		end
		tools.button.setText(label)
	end
end

-- While a tool waits for its slot: the chip above the bar says which (or, on a screen too short
-- for it, a toast), and TOOLS turns into the way out.
local function showPickChip(id: string?)
	local chip = pickChip
	if not chip then
		return
	end
	chip.Visible = id ~= nil and chipFits
	if id then
		local text = "Pick a slot for " .. Toys.byId[id].label
		if pickLabel then
			pickLabel.Text = text
		end
		if not chipFits then
			Toast.show(text, GOLD)
		end
	end
	local tools = toolsSlab
	if tools and nextStacked then
		-- (A phone: CANCEL takes the next cards' column while a slot is picked.)
		tools.button.root.Visible = id ~= nil and allowed == nil
		local box = nextFrame
		if box then
			box.Visible = id == nil
		end
	end
	if tools then
		drawTools(id ~= nil)
		tools.button.setSwatch(if id then Theme.role("danger") else Theme.role("neutral"))
	end
end

local function stopPicking()
	pendingEquip = nil
	pendingToken += 1
	stopPulses()
	showPickChip(nil)
	refresh()
end

-- Puts the tool waiting from the catalog into this slot.
local function placeIn(slotId: string)
	local id = pendingEquip
	local slot = table.find(loadout, slotId)
	if not id or not slot then
		return
	end
	loadout[slot] = id
	selected = id
	stopPicking()
	layout()
	Net.event(Net.Names.Loadout):FireServer("Set", loadout) -- kept for next time
	C.playSound("success")
	local slab = slabs[id]
	if slab then
		pop(slab)
	end
end

-- From the catalog: a tool already in the bar is just picked; with a slot free (UNEQUIP) it goes
-- straight in at the end; otherwise it waits for a slot to be tapped.
local function beginEquip(id: string)
	if not Toys.byId[id] or allowed then
		return
	end
	if table.find(loadout, id) then
		select(id)
		local slab = slabs[id]
		if slab then
			pop(slab)
		end
		return
	end
	if #loadout < Toys.SLOTS then
		stopPicking()
		table.insert(loadout, id)
		selected = id
		layout()
		refresh()
		Net.event(Net.Names.Loadout):FireServer("Set", loadout)
		C.playSound("success")
		local slab = slabs[id]
		if slab then
			pop(slab)
		end
		return
	end
	stopPulses()
	pendingEquip = id
	pendingToken += 1
	local token = pendingToken
	refresh()
	showPickChip(id)
	-- The gold rings breathe until a slot is tapped (still, under Reduced Motion).
	if not reducedMotion() then
		local info = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		for _, slab in slabs do
			if slab.button.root.Visible then
				slab.ring.Transparency = 0
				local t = TweenService:Create(slab.ring, info, { Transparency = 0.65 })
				t:Play()
				table.insert(pulses, t)
			end
		end
	end
	task.delay(PICK_TIME, function()
		if pendingToken == token then
			stopPicking()
			Toast.show("No slot picked: " .. Toys.byId[id].label .. " stays in WEAPONS")
		end
	end)
end

-- From the catalog: takes a tool off the bar (its slot is free for the next EQUIP). The bar keeps
-- at least one tool.
local function unequip(id: string): boolean
	local slot = table.find(loadout, id)
	if allowed or not slot or #loadout <= 1 then
		return false
	end
	stopPicking()
	table.remove(loadout, slot)
	if selected == id then
		select(loadout[math.min(slot, #loadout)])
	end
	layout()
	refresh()
	Net.event(Net.Names.Loadout):FireServer("Set", loadout)
	C.playSound("click")
	return true
end

-- A tool on the bar you may no longer use (round 3, M9: the free weekend's weapon after Sunday)
-- leaves it, and the bar is kept without it (BarRules: only once the progress is really known, the
-- server's ProgressLoaded; never the last tool).
local function pruneLocked()
	if allowed then
		return
	end
	local keep, gone = BarRules.prune(loadout, player:GetAttribute("ProgressLoaded") == true, function(id: string): boolean
		return ToolCatalog.stateOf(id) == "locked"
	end)
	if #gone == 0 then
		return
	end
	loadout = keep
	if selected and not table.find(loadout, selected) then
		select(loadout[1])
	end
	layout()
	refresh()
	Net.event(Net.Names.Loadout):FireServer("Set", loadout)
	local toy = Toys.byId[gone[1]]
	if toy then
		hint(string.format("The %s left your bar: unlock it to keep it", toy.label))
	end
end

local function pressed(id: string)
	if pendingEquip then
		placeIn(id)
	else
		select(id)
	end
end

local function openCatalog()
	if pendingEquip then
		stopPicking() -- TOOLS reads CANCEL while a tool waits for its slot
		return
	end
	ToolCatalog.showTool(selected)
	ToolCatalog.toggle()
end
PokeController.openCatalog = openCatalog -- (LOOK_V3: HudV3's WEAPONS square)

-- One slab on the bar: a kit Button, with a ring for "selected"/"pick me", a cooldown shade and
-- its own pop scale.
local function makeSlab(id: string, text: string, swatch: Theme.Swatch, parent: Instance, onActivated: () -> ()): Slab
	local button = C.Button({
		name = id,
		text = text,
		swatch = swatch,
		size = UDim2.fromOffset(MAX_W, 60),
		depth = Theme.Size.depthSmall,
		textStyle = "small",
		parent = parent,
		onActivated = onActivated,
	})
	local root = button.root
	-- A one-word label may draw down to the kit's 12 px floor, so the longest names fit a phone slot.
	local fit = button.label:FindFirstChildOfClass("UITextSizeConstraint")
	if fit then
		fit.MinTextSize = PokeController.SLAB_MIN_TEXT -- (UI v2: 14; a word that cannot fit hides: iconOnly)
	end
	-- A one-word label gets the whole face (the kit pads text buttons for long captions).
	local content = button.face:FindFirstChild("Content")
	local padding = content and content:FindFirstChildOfClass("UIPadding")
	-- Phase K: the tool's picture at the slab's left (for players who go by pictures, not words);
	-- the word keeps the rest of the face.
	local toy = Toys.byId[id]
	local picture = toy and (toy :: any).glyph
	local padTop = padding and padding.PaddingTop
	if padding then
		padding.PaddingLeft = UDim.new(0, if picture then PokeController.PICTURE_PAD else 3)
		padding.PaddingRight = UDim.new(0, 3)
	end
	local icon: GuiObject? = nil
	local picScale: UIScale? = nil
	if picture and content then
		-- The same picture as in TOOLS (LihFolkUIIcons: the emoji on a darkened disc with a thin
		-- white edge), so it shows on the near-black resting slab and on the lit selected one alike.
		ToolCatalog.registerIcons()
		local pic = ToolPicture.make(id, UDim2.fromOffset(PokeController.PICTURE, PokeController.PICTURE))
		pic.Name = "Picture"
		pic.AnchorPoint = Vector2.new(0, 0.5)
		pic.Position = UDim2.new(0, 3, 0.5, 0)
		for _, d in pic:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 4 -- (under the cooldown shade, as the word is; the emoji draws over its disc)
			end
		end
		pic.ZIndex = 4
		local scale = Instance.new("UIScale")
		scale.Parent = pic
		pic.Parent = button.face
		icon = pic
		picScale = scale
	end
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Parent = root
	local ringHolder = Instance.new("Frame")
	ringHolder.Name = "Ring"
	ringHolder.BackgroundTransparency = 1
	ringHolder.Size = UDim2.fromScale(1, 1)
	ringHolder.ZIndex = 6
	ringHolder.Parent = root
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(0, Theme.Radius.button + 2)
	ringCorner.Parent = ringHolder
	local ring = Instance.new("UIStroke")
	ring.Thickness = 3
	ring.Color = GOLD
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Enabled = false
	ring.Parent = ringHolder
	-- The cooldown: a shade that drains away while the tool recharges.
	local shade = Instance.new("Frame")
	shade.Name = "Cooldown"
	shade.AnchorPoint = Vector2.new(0, 1)
	shade.Position = UDim2.fromScale(0, 1)
	shade.Size = UDim2.fromScale(1, 0)
	shade.BackgroundColor3 = INK
	shade.BackgroundTransparency = 0.45
	shade.BorderSizePixel = 0
	shade.ZIndex = 5
	shade.Parent = root
	local shadeCorner = Instance.new("UICorner")
	shadeCorner.CornerRadius = UDim.new(0, Theme.Radius.button)
	shadeCorner.Parent = shade
	-- The slot's number (round 2, N5), a small black square over the slab's top right corner (in
	-- the bar's own edge room, clear of the word and the picture).
	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.AnchorPoint = Vector2.new(1, 0)
	number.Position = UDim2.new(1, 3, 0, -6)
	number.Size = UDim2.fromOffset(PokeController.NUMBER, PokeController.NUMBER)
	number.AutomaticSize = Enum.AutomaticSize.X -- (a key name of three letters widens it)
	number.BackgroundColor3 = INK
	number.BackgroundTransparency = 0.1
	number.TextColor3 = WHITE
	number.FontFace = Theme.Fonts.display
	number.TextSize = if KitStyle.V2 then 14 else 13
	number.Text = ""
	number.ZIndex = 7
	number.Visible = false
	local numberCorner = Instance.new("UICorner")
	numberCorner.CornerRadius = UDim.new(0, 4)
	numberCorner.Parent = number
	local numberStroke = Instance.new("UIStroke")
	numberStroke.Color = Color3.fromRGB(110, 116, 128)
	numberStroke.Thickness = 1
	numberStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	numberStroke.Parent = number
	local numberPad = Instance.new("UIPadding")
	numberPad.PaddingLeft = UDim.new(0, 4)
	numberPad.PaddingRight = UDim.new(0, 4)
	numberPad.Parent = number
	number.Parent = root
	return { id = id, button = button, ring = ring, shade = shade, pop = pop, picture = icon, picScale = picScale, padding = padding, padTop = padTop, number = number }
end

-- A tool's slab, made the first time the bar needs it (and kept: the next equip is instant).
ensureSlab = function(id: string): Slab?
	local slab = slabs[id]
	local toy = Toys.byId[id]
	if slab or not toy or not slotsParent then
		return slab
	end
	local made = makeSlab(id, toy.short, swatchFor(toy.color, false), slotsParent :: Instance, function()
		pressed(id)
	end)
	made.button.root.Visible = false
	slabs[id] = made
	return made
end

local function showCooldown(id: string, seconds: number)
	local slab = slabs[id]
	if not slab or seconds < 0.3 then
		return
	end
	slab.shade.Size = UDim2.fromScale(1, 1)
	TweenService:Create(slab.shade, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 0) }):Play()
end

local function clearCooldown(id: string)
	lastFire[id] = nil
	local slab = slabs[id]
	if slab then
		TweenService:Create(slab.shade, TweenInfo.new(0.1), { Size = UDim2.fromScale(1, 0) }):Play()
	end
end

local function buildUi()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ToyBar"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- the kit's slabs layer their parts by sibling order
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)

	-- The holder: TOOLS pinned on the left, the loadout next to it. Sized to its content exactly
	-- (layout), so nothing ever scrolls or clips.
	local holder = Instance.new("Frame")
	holder.Name = "Bar"
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	-- Quiet lilac: the lit tool is the bar's focal point; TOOLS draws the eye only when it matters
	-- (its ring breathes when the catalog first opens, it turns red as CANCEL while picking).
	toolsSlab = makeSlab("Tools", "WEAPONS", Theme.role("neutral"), holder, openCatalog)
	local toolsFit = toolsSlab.button.label:FindFirstChildOfClass("UITextSizeConstraint")
	if toolsFit then
		toolsFit.MinTextSize = PokeController.TOOLS_MIN_TEXT -- (WEAPONS is the longest word on the bar)
	end

	-- Round 5: the next three weapons to unlock (NextUnlocks draws them; layout places the box).
	local nextBox = Instance.new("Frame")
	nextBox.Name = "Next"
	nextBox.BackgroundTransparency = 1
	nextBox.Parent = holder
	nextFrame = nextBox
	NextUnlocks.mount(nextBox)
	NextUnlocks.onTap = function()
		openCatalog()
	end
	NextUnlocks.onCount = function()
		layout()
	end

	local slots = Instance.new("Frame")
	slots.Name = "Slots"
	slots.BackgroundTransparency = 1
	slots.Parent = holder
	slotsFrame = slots

	-- The chip above the bar while a tool from the catalog waits for its slot.
	local chip = Instance.new("Frame")
	chip.Name = "PickChip"
	chip.AnchorPoint = Vector2.new(0.5, 1)
	chip.Position = UDim2.new(0.5, 0, 0, -CHIP_GAP)
	chip.Size = UDim2.fromOffset(300, CHIP_H) -- layout sizes it to the bar and the screen
	chip.BackgroundColor3 = P.dusk
	chip.Visible = false
	chip.ZIndex = 8
	chip.Parent = holder
	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0.5, 0)
	chipCorner.Parent = chip
	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = GOLD
	chipStroke.Thickness = Theme.Stroke.card
	chipStroke.Parent = chip
	local chipPad = Instance.new("UIPadding")
	chipPad.PaddingLeft = UDim.new(0, 18)
	chipPad.PaddingRight = UDim.new(0, 2)
	chipPad.Parent = chip
	local chipList = Instance.new("UIListLayout")
	chipList.FillDirection = Enum.FillDirection.Horizontal
	chipList.VerticalAlignment = Enum.VerticalAlignment.Center
	chipList.Padding = UDim.new(0, 10)
	chipList.SortOrder = Enum.SortOrder.LayoutOrder
	chipList.Parent = chip
	local label = C.Text("small", "", {
		name = "Text",
		color = GOLD,
		scaled = true,
		size = UDim2.new(1, -(CHIP_H + 30), 1, -12), -- beside the close button, inside the padding
		layoutOrder = 1,
		parent = chip,
	})
	local fit = label:FindFirstChildOfClass("UITextSizeConstraint")
	if fit then
		fit.MinTextSize = if KitStyle.V2 then 14 else 12 -- a long tool name on a phone still fits the chip
	end
	label.ZIndex = 8
	pickLabel = label
	C.Button({
		name = "Cancel",
		icon = "close",
		role = "danger",
		round = true,
		depth = Theme.Size.depthSmall,
		size = UDim2.fromOffset(CHIP_H - 4, CHIP_H - 4), -- drawn 36; its tap pad is the kit's 52
		layoutOrder = 2,
		zIndex = 8,
		parent = chip,
		onActivated = stopPicking,
	})
	pickChip = chip

	-- (Slabs are made when a tool first goes in the bar: ensureSlab, round 3 M1. 49 slabs with a
	-- 3D picture each were 2,000 interface objects and 49 model copies nobody saw.)
	slotsParent = slots

	-- The help line under the bar (a computer: layout shows it).
	local help = Instance.new("TextLabel")
	help.Name = "HelpLine"
	help.AnchorPoint = Vector2.new(0.5, 1)
	help.Position = UDim2.new(0.5, 0, 1, -PokeController.HELP_BOTTOM)
	help.Size = UDim2.fromOffset(640, PokeController.HELP_H)
	help.BackgroundColor3 = INK
	help.BackgroundTransparency = 0.35
	help.TextColor3 = P.helpText
	help.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	help.TextScaled = true
	help.Visible = false
	local helpFit = Instance.new("UITextSizeConstraint")
	helpFit.MaxTextSize = 15
	helpFit.MinTextSize = 12
	helpFit.Parent = help
	local helpPad = Instance.new("UIPadding")
	helpPad.PaddingTop = UDim.new(0, 3)
	helpPad.PaddingBottom = UDim.new(0, 3)
	helpPad.PaddingLeft = UDim.new(0, 10)
	helpPad.PaddingRight = UDim.new(0, 10)
	helpPad.Parent = help
	local helpCorner = Instance.new("UICorner")
	helpCorner.CornerRadius = UDim.new(0, 4)
	helpCorner.Parent = help
	help.Parent = gui
	helpLabel = help

	barGui = gui
	barFrame = holder
	gui.Parent = player:WaitForChild("PlayerGui")
end

-- A gun fired at no dummy (round 2, N2): the dart flies to where you aimed (the ground, a wall) or
-- off into the air, with its bang; the server shares it with everyone (HitService's Shot). Fired on a
-- tap (a short press that did not drag), so turning the camera never fires.
local AIR_SHOT = 150 -- studs along the aim for a shot into the open sky
local WHOOSH_LEAD = 0.1 -- s before a blow by hand lands that its whoosh starts (it peaks at the hit)
local function fireMiss(toy: Toys.Toy, ray: Ray, result: RaycastResult?): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	local now = os.clock()
	local cooldown = if player:GetAttribute("ZeroDelay") == true then math.min(toy.cooldown, Shop.ZERO_DELAY) else toy.cooldown
	if lastFire[toy.id] and now - lastFire[toy.id] < cooldown then
		local slab = slabs[toy.id]
		if slab then
			pop(slab)
		end
		FxController.dryFire(toy.id) -- (the Deagle and the shotgun click)
		return true
	end
	if not AmmoClient.canFire(toy.id) then
		FxController.dryFire(toy.id) -- (round 5: reloading, the magazine fills)
		return true
	end
	local point = if result then result.Position else ray.Origin + ray.Direction.Unit * AIR_SHOT
	-- (Never past the reach the server allows: a far shot ends there, in the air.)
	local offset = point - root.Position
	if offset.Magnitude > REACH - 2 then
		point = root.Position + offset.Unit * (REACH - 2)
	end
	if not Zones.mayReach(player, point) then
		hint(REFUSALS.Private)
		return true
	end
	lastFire[toy.id] = now
	showCooldown(toy.id, cooldown)
	if character and AvatarMoves.upright(character) then
		AvatarMoves.play(character, toy.id, point, {})
	end
	Net.event(Net.Names.Shot):FireServer(point, toy.id)
	AmmoClient.spent(toy.id)
	GunFeel.fired(toy, lastAim)
	SessionClient.shot()
	FxController.localEvent("Shot", point, 0, toy.id)
	local listener = PokeController.onUsed
	if listener then
		task.spawn(listener, toy.id, point)
	end
	for _, also in PokeController.onUsedAlso do
		task.spawn(also, toy.id, point)
	end
	return true
end

-- phase "press": the finger/button just went down. Toys aimed at a dummy fire at once when it is
--   on a dummy (instant), and the press is used up (it will not turn the camera).
-- phase "tap": a short press that did not drag. Toys placed on any surface fire here, so dragging
--   across the ground to turn the camera never drops an anvil by accident.
-- Positions are viewport coordinates. Returns true when the toy was used.
-- Round 5, phase 00: touch aim help. A finger is wide and the dummies run from a gun: a tap that
-- would miss every body, but lands within ASSIST of one on the screen (a share of the screen's
-- short side), goes to the nearest body's middle instead. Touch only, tools aimed at a dummy only,
-- and never into a lab this player may not reach.
PokeController.ASSIST = 0.12
local ASSIST_PARTS = { "UpperTorso", "Head", "LowerTorso" }
-- (V8-0.2: the torso only, never the head: a help that lands headshots reads as a cheat.)
local ASSIST_TORSO = { "UpperTorso", "LowerTorso" }
local function assisted(camera: Camera, at: Vector2): Vector2
	local ray = camera:ViewportPointToRay(at.X, at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	local direct = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	local hitModel = direct and direct.Instance:FindFirstAncestorOfClass("Model")
	if hitModel and hitModel:GetAttribute("IsDummy") == true then
		return at
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return at
	end
	local view = camera.ViewportSize
	local best, bestDistance = at, math.max(56, math.min(view.X, view.Y) * PokeController.ASSIST)
	for _, model in dummies:GetChildren() do
		if model:GetAttribute("IsDummy") ~= true then
			continue
		end
		for _, name in (if (Config :: any).V8_FIRST_HIT then ASSIST_TORSO else ASSIST_PARTS) do
			local part = model:FindFirstChild(name)
			if part and part:IsA("BasePart") and Zones.mayReach(player, part.Position) then
				local point, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen and point.Z > 0 then
					local d = (Vector2.new(point.X, point.Y) - at).Magnitude
					if d < bestDistance then
						best, bestDistance = Vector2.new(point.X, point.Y), d
					end
				end
			end
		end
	end
	return best
end
PokeController.assistedForTest = assisted

local function tryUse(screenPosition: Vector2, phase: "press" | "tap"): boolean
	local camera = Workspace.CurrentCamera
	if not camera or not enabled or doctorHold then
		return false
	end
	do
		local picked = Toys.byId[selected]
		-- Round 5: C4 out already: this press (anywhere) is the detonator.
		if picked and picked.id == "C4" and ((player:GetAttribute("C4Armed") :: number?) or 0) > 0 and phase == "press" and not pendingEquip then
			Net.event(Net.Names.Ammo):FireServer("Detonate")
			hint("BOOM!")
			return true
		end
		-- (V8-0.2: a pad aims at the screen centre with a stick: it gets the same help as a finger.)
		local padAim = (Config :: any).V8_FIRST_HIT and string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
		-- V9-NOW crosshair-sync: on PC (mouse, not touch, not pad) a gun's shot pixel shifts by the
		-- current camera recoil in viewport pixels, matching the Crosshair icon's own offset. Touch
		-- and pad already come in with the offset baked into screenPosition (TouchShoot.aimPixel).
		if picked and picked.gun and not ViewMode.isTouch() and not padAim then
			screenPosition = screenPosition + FeelV2.recoilPixelOffset(camera)
		end
		if picked and (picked.kind == "hit" or picked.kind == "dummy") and (ViewMode.isTouch() or padAim) then
			screenPosition = GunFeel.aim(picked, assisted(camera, screenPosition))
		elseif picked and picked.gun then
			screenPosition = GunFeel.aim(picked, screenPosition)
		end
		-- (Round 5: the minigun spins up and the railgun charges before firing; Dec 2026: the M4 is
		-- fully automatic, no burst pause.)
		if picked and picked.gun and not pendingEquip and enabled and not GunFeel.ready(picked, screenPosition) then
			return true
		end
		lastAim = screenPosition
	end
	if pendingEquip then
		if phase == "tap" then
			hint("Tap a slot in your bar first (or the X to cancel)")
		end
		return false -- picking a slot: taps in the world do nothing until a slot is tapped
	end
	local toy = Toys.byId[selected]
	if toy.kind == "grab" then
		return false -- GrabController handles press, drag and release
	end
	local aimed = toy.kind == "hit" or toy.kind == "dummy"

	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local localFx = Workspace:FindFirstChild("LocalFx")
	if localFx then
		table.insert(ignore, localFx)
	end
	params.FilterDescendantsInstances = ignore
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	local model = result and result.Instance:FindFirstAncestorOfClass("Model")
	local isDummy = model ~= nil and model:GetAttribute("IsDummy") == true
	local onPlayer = model ~= nil and Players:GetPlayerFromCharacter(model) ~= nil
	-- Players hit players only in the plaza, both standing in it (round 3, M1): a knock, no wound.
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local plazaFight = onPlayer and toy.kind == "hit" and result ~= nil and myRoot ~= nil and myRoot:IsA("BasePart")
		and Zones.isPlaza(myRoot.Position) and Zones.isPlaza(result.Position)
	-- Someone else's lab (round 3, M1): nothing in it can be touched from here (the server refuses
	-- it too); a press there still turns the camera.
	if result and not Zones.mayReach(player, result.Position) then
		if phase == "tap" then
			hint(REFUSALS.Private)
		end
		return phase == "tap"
	end

	-- Round 5 (the owner: spam the pistol into the air, hold an automatic down): with a mouse in the
	-- player view the left button never turns the camera, so a gun fires on the press itself, at a
	-- dummy or not, and the press is claimed (LabCamera keeps firing while it is held). A touch
	-- screen's drag turns the camera: there SHOOT does it (TouchShoot), and a tap still fires.
	if phase == "press" and toy.gun and not isDummy and not onPlayer and not ViewMode.isTouch() and not ViewMode.isLab() then
		return fireMiss(toy, ray, result)
	end
	if (phase == "press") ~= aimed then
		-- A gun fires wherever it is aimed, a dummy or not.
		if phase == "tap" and toy.gun and not isDummy and not onPlayer then
			return fireMiss(toy, ray, result)
		end
		-- A plain tap that missed what this tool needs: say so (a drag to turn the camera never
		-- gets here).
		if phase == "tap" and aimed and not isDummy and not plazaFight then
			hint(if onPlayer then "You can only hit other players in the plaza" else "Tap a dummy to use " .. toy.label)
		end
		return false
	end
	if not result then
		if not aimed then
			hint("Too far away. Tap closer to put down " .. toy.label)
		end
		return false
	end
	if aimed and not isDummy and not plazaFight then
		return false
	end
	if onPlayer and not plazaFight then
		hint("You can only hit other players in the plaza")
		return false
	end
	-- A player just knocked over is safe for a moment (the server's KnockSafeUntil): told, no hit.
	if plazaFight and model then
		local target = Players:GetPlayerFromCharacter(model)
		local safe = target and target:GetAttribute("KnockSafeUntil")
		-- (Or lying down already, knocked or on purpose: the server's BodyLoose on the character; it
		-- never knocks a body that is down.)
		local down = model:GetAttribute("BodyLoose") == true
		if down or (type(safe) == "number" and Workspace:GetServerTimeNow() < safe) then
			if phase == "press" then
				hint(if down then REFUSALS.Down else REFUSALS.GettingUp)
			end
			return phase == "press"
		end
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and (root.Position - result.Position).Magnitude > REACH then
		hint(REFUSALS.TooFar)
		return true
	end
	local now = os.clock()
	-- ULTRA (MoneyService sets ZeroDelay on the player): next to no wait, as on the server.
	local cooldown = if player:GetAttribute("ZeroDelay") == true then math.min(toy.cooldown, Shop.ZERO_DELAY) else toy.cooldown
	if lastFire[toy.id] and now - lastFire[toy.id] < cooldown then
		local slab = slabs[toy.id]
		if slab then
			pop(slab) -- the recharging slab answers the tap
		end
		if toy.gun then
			FxController.dryFire(toy.id)
		end
		return aimed -- a dummy press during cooldown is still not a camera drag
	end
	if toy.gun and not AmmoClient.canFire(toy.id) then
		FxController.dryFire(toy.id) -- (round 5: reloading)
		return aimed
	end
	if toy.kind == "dummy" and model and model:GetAttribute("Frozen") == true then
		hint(if toy.id == "Freeze" then "Already frozen! Hit it to shatter it" else REFUSALS.Frozen)
		return true
	end
	-- Hands, feet and smackers are done by your avatar: in the walk view you must be close; in the
	-- lab view, close by your avatar does it, further away the tool works from afar.
	local avatar = character and character:FindFirstChild("HumanoidRootPart")
	local distance = if avatar and avatar:IsA("BasePart") then (avatar.Position - result.Position).Magnitude else math.huge
	local walking = not ViewMode.isLab()
	if toy.byHand and walking and distance > HitFeel.MELEE_REACH then
		hint("Get closer to hit with " .. toy.label .. "!")
		return true
	end
	local standing = character ~= nil and AvatarMoves.upright(character)
	if toy.byHand and walking and not standing then
		-- Limp or down: your avatar cannot swing (and a blow from nowhere would make no sense).
		hint("Get up first to hit with " .. toy.label .. "!")
		return true
	end
	local byHand = toy.byHand and distance <= HitFeel.MELEE_REACH and standing
	-- The avatar's move. A blow by hand steps in and lands at the move's contact moment, holding
	-- there for the hit-stop (taken from the budget now, so the pose and the camera agree); a shot
	-- lands at once; a throw has already happened when the thing appears (the arm follows through);
	-- a tool from afar (the glove on a spring, the giant hand) makes no move: its own visual does it.
	local stop = if byHand then FxController.takeHitStop(HitFeel.stopFor(toy)) else 0
	local contact = 0
	if character and (byHand or not toy.byHand) then
		contact = AvatarMoves.play(character, toy.id, result.Position, {
			hitStop = stop,
			lunge = byHand,
			targetModel = model,
			fromContact = toy.kind == "place" or toy.kind == "dummy",
		})
	end
	if not byHand then
		contact = 0
	end
	-- Round 4, M10: the swing whooshes just before it lands (a blow from afar whooshes in FxController).
	if byHand and contact > 0 and toy.kind == "hit" then
		task.delay(math.max(contact - WHOOSH_LEAD, 0), FxController.swingWhoosh, toy.id, result.Position)
	end
	-- The cooldown runs from when the blow lands (the server spaces uses the same way), so a flurry
	-- is paced by the slab and every blow that lands is one the server takes.
	lastFire[toy.id] = now + contact
	showCooldown(toy.id, cooldown + contact)
	local part = result.Instance
	local direction = ray.Direction
	-- Where on the part it was tapped, in the part's own space: a blow that lands a moment later
	-- lands on the same spot of a dummy that has moved since.
	local spot = if part:IsA("BasePart") then part.CFrame:PointToObjectSpace(result.Position) else nil
	local function land()
		if byHand then
			-- Gone limp, died or picked another tool during the wind-up: the blow never lands.
			if not part.Parent or selected ~= toy.id or not (character and AvatarMoves.upright(character)) then
				return
			end
		end
		local position = if spot and part:IsA("BasePart") then part.CFrame:PointToWorldSpace(spot) else result.Position
		-- (byHand travels with it, only for the looks: others draw the avatar's blow or the tool.)
		Net.event(Net.Names.HitRequest):FireServer(part, position, direction, toy.id, byHand)
		if toy.gun then
			AmmoClient.spent(toy.id)
			GunFeel.fired(toy, lastAim)
			SessionClient.shot()
		elseif toy.sever > 0 and toy.byHand and character then
			-- Round 5: a blade's cut shows in the air (katana, axe, cleaver, chainsaw, plasma).
			local r = character:FindFirstChild("HumanoidRootPart")
			if r and r:IsA("BasePart") then
				FxController.slash(r.CFrame, if toy.id == "PlasmaBlade" then toy.color else Color3.fromRGB(235, 240, 255))
			end
		end
		if toy.kind == "hit" then
			-- Our own dummy: react this frame instead of waiting for the server.
			local simulated = DummySim.simulatedDummyOf(part)
			if simulated and part:IsA("BasePart") and part.Parent and simulated:GetAttribute("Frozen") ~= true then
				local mass = (simulated:GetAttribute("Mass") :: number?) or 10
				-- (On the part the server will wound: the line from our head, WoundSpot.)
				local onPart, at = WoundSpot.find(character, simulated, part, position)
				local before = simulated:GetAttribute("RagdollState")
				ActiveRagdoll.ownHit = true
				local okHit, after = pcall(ActiveRagdoll.hit, simulated, onPart, HitMath.toyImpulse(toy, direction, mass), at, nil, HitMath.gunOf(toy))
				ActiveRagdoll.ownHit = false
				-- (V9-NOW 10: a round on your own dummy shows it on the monitor this frame, before the server's echo.)
				if toy.gun then
					pcall(function()
						(require(script.Parent:WaitForChild("HospitalCharts")) :: any).ownHit(simulated)
					end)
				end
				if not okHit then
					warn("[Poke] local hit failed: " .. tostring(after))
					after = nil
				end
				-- V8-0.2: the hit tick and, when it went down, the KO stamp and a dry "thock" now, from
				-- this screen; the server stays the count's source of truth.
				-- V8-1.2: a word, dizzy stars and a hit-stop on the body for what the hit did.
				if (Config :: any).REACTIONS_V8 and okHit then
					pcall(function()
						local Poses = require(Shared:WaitForChild("Ragdoll"):WaitForChild("Poses")) :: any
						local HitWords = require(script.Parent:WaitForChild("HitWords")) :: any
						HitWords.onHit(simulated, Poses.regionOf(onPart.Name), after, toy.speed, toy.gun == true)
					end)
				end
				if (Config :: any).V8_FIRST_HIT then
					local knocked = after == "Ragdoll" and before ~= "Ragdoll" and before ~= "Out"
					pcall(function()
						(require(script.Parent:WaitForChild("Crosshair")) :: any).localHit(knocked)
					end)
					if knocked then
						C.playSound("tick", 0.62)
						-- (V8-1.5: a chime that climbs with the combo, and a buzz on phones and pads.)
						if (Config :: any).AUDIO_V8 then
							pcall(function()
								local n = (require(script.Parent:WaitForChild("Crosshair")) :: any).combo()
								C.playSound("reward", math.min(1.6, 0.9 + 0.12 * math.max(0, n - 1)))
								;(require(script.Parent:WaitForChild("Haptics")) :: any).pulse(if n >= 3 then 0.8 else 0.5, 0.08)
							end)
						end
					end
				end
				-- (V9-0ac fix round 3: under SHOT_FLINCH a round never knocks a body over by itself; it drops
				-- when the server says it is out (Vital). A drop within KO_WATCH s of your round gets the
				-- same KO stamp, tick, combo chime and buzz a knock-down had.)
				if (Config :: any).SHOT_FLINCH and toy.gun and after ~= "Ragdoll" then
					local body = onPart:FindFirstAncestorOfClass("Model")
					if body and body:GetAttribute("Vital") == "Alive" and body:GetAttribute("KOWatch") == nil then
						body:SetAttribute("KOWatch", true) -- (this screen only)
						local conn: RBXScriptConnection? = nil
						local finished = false
						local function finish(dropped: boolean)
							if finished then
								return
							end
							finished = true
							if conn then
								conn:Disconnect()
							end
							body:SetAttribute("KOWatch", nil)
							if dropped then
								pcall(function()
									(require(script.Parent:WaitForChild("Crosshair")) :: any).localHit(true)
								end)
								C.playSound("tick", 0.62)
								if (Config :: any).AUDIO_V8 then
									pcall(function()
										local n = (require(script.Parent:WaitForChild("Crosshair")) :: any).combo()
										C.playSound("reward", math.min(1.6, 0.9 + 0.12 * math.max(0, n - 1)))
										;(require(script.Parent:WaitForChild("Haptics")) :: any).pulse(if n >= 3 then 0.8 else 0.5, 0.08)
									end)
								end
							end
						end
						conn = body:GetAttributeChangedSignal("Vital"):Connect(function()
							local v = body:GetAttribute("Vital")
							if v == "Unconscious" or v == "Dead" then
								finish(true)
							end
						end)
						task.delay(1.5, function()
							finish(false)
						end)
					end
				end
			end
			-- Round 4, M10: the shooter hears the impact this frame (<50 ms), whether or not they
			-- own the target's simulation. The server echo for our own UserId is suppressed by the
			-- predicted queue in FxController.onFx, so we never play twice (a plaza knock too; no
			-- blood there: FxController never bleeds a player).
			FxController.predictHit(position, toy.speed, toy.id, direction, stop, byHand)
		elseif toy.kind == "place" then
			FxController.localEvent("Place", position, 0, toy.id)
		end
	end
	if byHand and contact > 0 then
		task.delay(contact, land)
	else
		land()
	end
	local listener = PokeController.onUsed
	if listener then
		task.spawn(listener, toy.id, result.Position)
	end
	for _, also in PokeController.onUsedAlso do
		task.spawn(also, toy.id, result.Position)
	end
	return true
end

-- Opens WEAPONS (the big WEAPONS button, round 5).
function PokeController.openCatalog()
	if allowed == nil and enabled then
		openCatalog()
	end
end

-- Pointer routing lives in LabCamera, which calls these.
-- V9-NOW 23: the Bow is drawn while held and shot on let-go (Client/BowClient), from any input that presses it.
local function bowPress(viewportPosition: Vector2): boolean?
	if (Config :: any).BOW and selected == "Bow" and enabled and not doctorHold then
		return (require(script.Parent:WaitForChild("BowClient")) :: any).begin(viewportPosition)
	end
	return nil
end

-- (22 Nov 2026, owner: "Talk is a magic wand you start with"): with the Wand picked, a click on a
-- ragdoll asks the server to open its talk card (NpcCommand "Talk"); a click on nothing does nothing.
-- Returns nil when the Wand is not picked.
local wandParams = RaycastParams.new()
wandParams.FilterType = Enum.RaycastFilterType.Exclude
local function wandPress(viewportPosition: Vector2): boolean?
	if PokeController.getSelected() ~= "Wand" then
		return nil
	end
	local camera = Workspace.CurrentCamera
	local dummies = Workspace:FindFirstChild("Dummies")
	if not camera or not dummies then
		return true
	end
	wandParams.FilterDescendantsInstances = { player.Character :: Instance }
	local ray = camera:ViewportPointToRay(viewportPosition.X, viewportPosition.Y)
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, wandParams)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	while model and model.Parent ~= dummies do
		model = model:FindFirstAncestorOfClass("Model")
	end
	if model then
		Net.event(Net.Names.NpcCommand):FireServer("Talk", model)
	end
	return true
end

function PokeController.pressAt(viewportPosition: Vector2): boolean
	local wand = wandPress(viewportPosition)
	if wand ~= nil then
		return wand
	end
	local bow = bowPress(viewportPosition)
	if bow ~= nil then
		return bow
	end
	return tryUse(viewportPosition, "press")
end

function PokeController.tapAt(viewportPosition: Vector2): boolean
	local wand = wandPress(viewportPosition)
	if wand ~= nil then
		return wand
	end
	local bow = bowPress(viewportPosition)
	if bow ~= nil then
		return bow
	end
	return tryUse(viewportPosition, "tap")
end

-- Shows or hides the toy bar and turns tapping on or off.
function PokeController.setEnabled(on: boolean)
	enabled = on
	changedEvent:Fire()
	if barGui then
		barGui.Enabled = on and not doctorHold
	end
	if not on and pendingEquip then
		stopPicking()
	end
end

-- Doctor mode (N3): the bar steps aside for the monitor and tools rest, on top of whatever else
-- (a replay, the first minute) has the bar on or off; leaving puts that back as it was.
function PokeController.setDoctor(on: boolean)
	doctorHold = on
	refresh() -- (also the hand: empty in doctor mode, the tool back after)
	if barGui then
		barGui.Enabled = enabled and not on
	end
	if on and pendingEquip then
		stopPicking()
	end
end

-- Whether tools can be used right now: the bar on, and not resting for doctor mode. (isEnabled
-- says only whether the bar is on, which build mode keeps to put back.)
function PokeController.active(): boolean
	return enabled and not doctorHold
end

function PokeController.isDoctor(): boolean
	return doctorHold
end

-- The first minute (the bar shows only the tools it teaches).
function PokeController.firstMinute(): boolean
	return allowed ~= nil
end

-- How far from each side the bar keeps (the doctor's monitor docks in the same room).
function PokeController.sideMargin(touch: boolean, lab: boolean): number
	return if touch and not lab then SIDE_TOUCH else SIDE_OTHER
end

-- The first minute: the bar shows exactly these tools, in this order (nil = your loadout, and the
-- TOOLS button).
function PokeController.setAllowed(ids: { string }?)
	if ids then
		local list = {}
		for _, id in ids do
			if Toys.byId[id] then
				table.insert(list, id)
			end
		end
		allowed = list
	else
		allowed = nil
	end
	-- (The left column's WEAPONS opens the catalog, which the first minute keeps closed.)
	Controller.setHudShown("Weapons", allowed == nil)
	layout()
end

function PokeController.isEnabled(): boolean
	return enabled
end

function PokeController.select(id: string)
	select(id)
end

-- Phase 0 (gamepad LB / RB, D-pad left / right): the previous or next slot on the bar, wrapping;
-- the same as pressing its key.
function PokeController.cycle(step: number)
	if not enabled or doctorHold then
		return
	end
	local list = shown()
	if #list == 0 then
		return
	end
	local i = table.find(list, selected) or 0
	pressed(list[((i - 1 + step) % #list) + 1])
end

-- The way to the next weapon (10 Nov 2026, the audit: progress could only be seen inside the
-- catalog): a thin gold bar along the foot of the bar's WEAPONS slab, filling towards the next unlock;
-- it hops when it moves on. frac nil: hidden (everything earned).
local nextFill: Frame? = nil
local lastFrac = -1
-- (Round 5: the big WEAPONS button shows the way to the next weapon: HudPlus. Off here.)
PokeController.NEXT_ON_BAR = false
function PokeController.setNext(frac: number?)
	local slab = toolsSlab
	if not slab or not PokeController.NEXT_ON_BAR then
		return
	end
	local fill = nextFill
	-- (The slab is rebuilt when the bar is: a bar on the old slab is gone with it. Build anew.)
	if fill and (not fill.Parent or fill.Parent.Parent ~= slab.root) then
		if fill.Parent then
			fill.Parent:Destroy()
		end
		fill = nil
		nextFill = nil
		lastFrac = -1
	end
	if not fill then
		local track = Instance.new("Frame")
		track.Name = "NextTrack"
		track.AnchorPoint = Vector2.new(0.5, 1)
		track.Position = UDim2.new(0.5, 0, 1, -7)
		track.Size = UDim2.new(0.78, 0, 0, 5)
		track.BackgroundColor3 = Color3.fromRGB(20, 18, 34)
		track.BackgroundTransparency = 0.2
		track.ZIndex = 6
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = track
		local f = Instance.new("Frame")
		f.Name = "Fill"
		f.Size = UDim2.fromScale(0, 1)
		f.BackgroundColor3 = GOLD
		f.ZIndex = 7
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(1, 0)
		fc.Parent = f
		f.Parent = track
		track.Parent = slab.root
		nextFill = f
		fill = f
	end
	local bar = fill :: Frame
	local track = bar.Parent :: Frame
	track.Visible = frac ~= nil
	if frac == nil then
		return
	end
	local k = math.clamp(frac, 0, 1)
	TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(k, 1) }):Play()
	if lastFrac >= 0 and k ~= lastFrac then
		pop(slab)
	end
	lastFrac = k
end

function PokeController.getSelected(): string
	return selected
end

-- Draws the eye to the TOOLS slab for a few seconds (the first time it appears): its ring breathes
-- (or simply shows, under Reduced Motion).
function PokeController.highlightTools()
	local slab = toolsSlab
	if not slab then
		return
	end
	slab.ring.Enabled = true
	slab.ring.Transparency = 0
	local done: () -> ()
	if reducedMotion() then
		done = function() end
	else
		local tween = TweenService:Create(slab.ring, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 7, true), {
			Transparency = 0.7,
		})
		tween:Play()
		local grow = TweenService:Create(slab.pop, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 7, true), { Scale = 1.08 })
		grow:Play()
		done = function()
			tween:Cancel()
			grow:Cancel()
			slab.pop.Scale = 1
		end
	end
	task.delay(6.5, function()
		done()
		slab.ring.Enabled = false
	end)
end

-- The bar's loadout (tests, and the profile later).
function PokeController.getLoadout(): { string }
	return table.clone(loadout)
end

-- From the catalog (or tests): start putting a tool in the bar.
function PokeController.equip(id: string)
	-- (V10 phase 3, owner: "equipping a weapon in first person swaps it for the one in your hand, no number key"):
	-- in first person the new one takes the picked slot at once and is picked.
	local fp = Players.LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson
	local at = if fp and selected then table.find(loadout, selected) else nil
	if at and not table.find(loadout, id) then
		loadout[at] = id
		Net.event(Net.Names.Loadout):FireServer("Set", loadout)
		layout()
		select(id)
		return
	elseif fp and table.find(loadout, id) then
		select(id)
		return
	end
	beginEquip(id)
end

-- A weapon just earned goes straight onto the bar, picked, ready to try (10 Nov 2026, the launch
-- funnel: two in three new players never tried a third tool; "find it in WEAPONS" was not enough).
-- A full bar gives up its plainest starter for it (Shove, then Punch, Crowbar, Bat), never the G17
-- or Grab and never something the player chose; with none of those left it asks as an equip does.
-- Returns whether it is on the bar now.
local GIVE_UP = { "Shove", "Punch", "Crowbar", "Bat" }

-- V8-0.3 (Config.V8_HAND_RULES): the bar stays yours. A new tool takes the weakest slot (by ladder
-- rung) that may go, and only when it is stronger; a gun, an explosive, Grab, the G17 and the Bat
-- never go. A prize (an egg, a crate, a gift day) always lands: with nothing weaker it takes the
-- weakest that may go anyway, and with all of them guarded the last slot that is not the G17 or
-- Grab. It is never picked while a tool is in use or fire is held: it waits for a calm moment.
local function busyFiring(): boolean
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		return true
	end
	local okPad, down = pcall(function()
		return UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2)
	end)
	if okPad and down then
		return true
	end
	local last = lastFire[selected]
	return last ~= nil and os.clock() - last < 0.6
end
PokeController.slotFor = (require(Shared:WaitForChild("HandRules")) :: any).slotFor
PokeController.busyFiringForTest = busyFiring

local function autoEquipV8(id: string, prize: boolean?): boolean
	local slot = PokeController.slotFor(loadout, id, prize)
	if not slot then
		return false
	end
	if loadout[slot] ~= id then
		loadout[slot] = id
		Net.event(Net.Names.Loadout):FireServer("Set", loadout)
	end
	layout()
	local function pick()
		selected = id
		refresh()
		local slab = slabs[id]
		if slab then
			pop(slab)
		end
	end
	if busyFiring() then
		refresh()
		task.spawn(function()
			local t0 = os.clock()
			while busyFiring() and os.clock() - t0 < 8 do
				task.wait(0.2)
			end
			if table.find(loadout, id) then
				pick()
			end
		end)
	else
		pick()
	end
	C.playSound("unlock")
	return true
end

function PokeController.autoEquip(id: string, prize: boolean?): boolean
	if not Toys.byId[id] or allowed or pendingEquip then
		return false
	end
	if (Config :: any).V8_HAND_RULES then
		return autoEquipV8(id, prize)
	end
	if table.find(loadout, id) or #loadout < Toys.SLOTS then
		beginEquip(id)
		return table.find(loadout, id) ~= nil
	end
	for _, plain in GIVE_UP do
		local at = table.find(loadout, plain)
		if at then
			loadout[at] = id
			selected = id
			layout()
			refresh()
			Net.event(Net.Names.Loadout):FireServer("Set", loadout)
			C.playSound("success")
			local slab = slabs[id]
			if slab then
				pop(slab)
			end
			return true
		end
	end
	return false
end

function PokeController.unequip(id: string): boolean
	return unequip(id)
end

function PokeController.isPicking(): boolean
	return pendingEquip ~= nil
end

-- How far the bar reaches up from the bottom of the screen (hints sit above it).
function PokeController.height(): number
	local frame = barFrame
	return if frame then frame.AbsoluteSize.Y + barBottom else 92
end

-- For layout checks: the size of one slot right now.
function PokeController.cellSize(): Vector2
	return cell
end

function PokeController.start()
	-- (Round 5: the magazine counter reads the picked tool and draws on its slab.)
	AmmoClient.getSelected = function(): string
		return selected
	end
	AmmoClient.slabOf = function(id: string): GuiObject?
		local slab = slabs[id]
		return if slab then slab.button.root else nil
	end
	AmmoClient.start()
	GunFeel.getSelected = AmmoClient.getSelected
	GunFeel.refire = function(at: Vector2)
		if not tryUse(at, "press") then
			tryUse(at, "tap")
		end
	end
	GunFeel.start()
	ToolCatalog.start({
		has = function(id: string): boolean
			return table.find(shown(), id) ~= nil
		end,
		equip = PokeController.equip, -- (V10 phase 3: first person swaps the held weapon at once)
		unequip = unequip,
		canUnequip = function(): boolean
			return allowed == nil and #loadout > 1
		end,
	})
	buildUi()
	-- The left column's WEAPONS (round 2, N5): the catalog, with a real weapon as its picture.
	Controller.setHudShown("Weapons", allowed == nil)
	PokeController.weaponsHud = Controller.addHudButton({
		label = "Weapons",
		icon = "toolbox",
		theme = "settings",
		layoutOrder = 2,
		picture = ToolPicture.make("Blaster", UDim2.fromScale(1, 1)), -- (the tile frames it: HudButton)
		onActivated = openCatalog,
	})
	layout()
	ViewMode.onChanged(layout)
	Keybinds.onChanged(function()
		layout() -- (a slot's number is its key)
		refreshHelp()
	end)
	ViewMode.onChanged(refreshHelp)
	local gui = barGui
	if gui then
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	end
	-- The open catalog covers the bottom of the screen: the bar steps aside until it closes.
	ToolCatalog.onOpenChanged(function(open: boolean)
		catalogOpen = open
		layout() -- (the bar and the help line under it step aside together)
	end)
	-- Your bar from last time, once the server has it.
	Net.event(Net.Names.Loadout).OnClientEvent:Connect(function(kind: unknown, list: unknown)
		if kind ~= "Load" or type(list) ~= "table" then
			return
		end
		local ids = list :: { any }
		local clean = {}
		if #ids < 1 then
			return
		end
		for i = 1, math.min(#ids, Toys.SLOTS) do
			local id = ids[i]
			if type(id) ~= "string" or not Toys.byId[id] or table.find(clean, id) then
				return
			end
			table.insert(clean, id)
		end
		loadout = clean
		layout()
		pruneLocked()
	end)
	Workspace:GetAttributeChangedSignal("FreeWeapon"):Connect(pruneLocked)
	Workspace:GetAttributeChangedSignal("OwnerParty"):Connect(pruneLocked) -- (the owner's free weapons ending)
	player:GetAttributeChangedSignal("ProgressLoaded"):Connect(pruneLocked)
	player:GetAttributeChangedSignal("TrialWeapon"):Connect(pruneLocked) -- (a free try over: round 5)
	player:GetAttributeChangedSignal("PassToys"):Connect(pruneLocked) -- (release 0.20.0: Shop.OFFERS passes)
	Net.event(Net.Names.ToyRefused).OnClientEvent:Connect(function(toyId: unknown, reason: unknown)
		if type(toyId) ~= "string" or type(reason) ~= "string" then
			return
		end
		clearCooldown(toyId) -- nothing happened, so it is ready again
		lastHint = 0 -- the server's word always shows
		local toy = Toys.byId[toyId]
		if reason == "Unlock" and toy then
			local have = (player:GetAttribute("Takedowns") :: number?) or 0
			hint(string.format("Take down %d more for the %s, or get it in WEAPONS", math.max(1, toy.unlockAt - have), toy.label))
		else
			hint(REFUSALS[reason] or "That did not work. Try again")
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape and pendingEquip then
			stopPicking()
			return
		end
		if not Keybinds.live(false) or not enabled or doctorHold then
			return -- (choosing a key, or building with the bar put away: the build keys have them;
			-- while a machine plays the bar is back, and so are its keys)
		end
		if Keybinds.is("Grab", input.KeyCode) then
			if table.find(shown(), "Grab") then
				select("Grab")
			else
				hint("Grab isn't in your bar. Add it from WEAPONS")
			end
			return
		end
		if Keybinds.is("Catalog", input.KeyCode) then
			if allowed == nil and enabled then
				openCatalog()
			end
			return
		end
		local index: number? = nil
		for i = 1, 6 do
			if Keybinds.is("Slot" .. i, input.KeyCode) then
				index = i
			end
		end
		local id = index and shown()[index]
		if id then
			pressed(id)
		end
	end)
end

return PokeController
