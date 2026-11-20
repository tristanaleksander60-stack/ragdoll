--!strict
-- Studio layout check: does anything on the HUD land on anything else, on the screens players
-- really have? For each screen (phones and tablets in landscape, inside their safe area, and PCs),
-- each view and both bar states (the first minute, the full bar), it places the tool bar and its
-- pick chip with PokeController.plan, every fixed control where HudSlots puts it, the kit's Events
-- launcher (read from the live PlayerGui) and Roblox's jump button, and lists every overlapping
-- pair. Run from the MCP (Client): require(LayoutCheck).run()
--
-- Also: the toast box (HudSlots.toastBox) against every control, whether the longest messages fit
-- it, the catalog window as the kit fits it on each touch screen, the resting slabs' contrast, and
-- LayoutCheck.live(): the boxes the controls really have right now against their slots (a control
-- that ignores its slot, or is scaled, shows up there).
--
-- Not covered: the dynamic thumbstick (it appears under the finger, anywhere in the lower left).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))
local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController"))

local PokeController = require(script.Parent:WaitForChild("PokeController"))
local HudSlots = require(script.Parent:WaitForChild("HudSlots"))
local MinigameHud = require(script.Parent:WaitForChild("MinigameHud"))
local HitInfo = require(script.Parent:WaitForChild("HitInfo"))
local HospitalCharts = require(script.Parent:WaitForChild("HospitalCharts"))
local Toys = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Toys"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ToolCatalog = require(script.Parent:WaitForChild("ToolCatalog")) :: any
local FriendsUI = require(script.Parent:WaitForChild("FriendsUI")) :: any
local CreatorUI = require(script.Parent:WaitForChild("CreatorUI")) :: any
local KitStyle = require(script.Parent:WaitForChild("KitStyle"))
local UiRarity = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UiRarity"))

local LayoutCheck = {}

type Rect = { x: number, y: number, w: number, h: number, name: string }

type Screen = { name: string, size: Vector2, touch: boolean, pad: boolean? }

-- Landscape, in the core UI safe area every HUD layer uses (notches, the home indicator and
-- Roblox's 58 px top bar taken off).
LayoutCheck.SCREENS = {
	{ name = "iPhone SE", size = Vector2.new(667, 317), touch = true },
	{ name = "Galaxy S21", size = Vector2.new(800, 302), touch = true },
	{ name = "iPhone 14", size = Vector2.new(750, 311), touch = true },
	{ name = "iPhone 14 Pro Max", size = Vector2.new(832, 351), touch = true },
	{ name = "iPad", size = Vector2.new(1180, 742), touch = true },
	{ name = "PC 1366x768", size = Vector2.new(1366, 654), touch = false },
	{ name = "PC 1280x720", size = Vector2.new(1280, 606), touch = false }, -- (a short window: the column is drawn smaller)
	{ name = "PC 1920x1080", size = Vector2.new(1920, 964), touch = false },
	-- V7-6: big PC screens and the TV (a console draws its UI at 1080p logical size; 4K is the same
	-- layout, scaled up), with the TV's 5% overscan edge taken off.
	{ name = "PC 2560x1440", size = Vector2.new(2560, 1324), touch = false },
	{ name = "PC ultrawide 3440x1440", size = Vector2.new(3440, 1324), touch = false },
	{ name = "Console TV 1080p", size = Vector2.new(1824, 1026), touch = false, pad = true },
	{ name = "Console TV 720p", size = Vector2.new(1216, 684), touch = false, pad = true },
	-- Phase 0 (19 Nov 2026): 95 % of phone visits hold the phone upright. Portrait phones, in the
	-- safe area (Roblox's 58 px top bar and the home indicator / navigation bar taken off).
	{ name = "iPhone 14 portrait 390x844", size = Vector2.new(390, 752), touch = true },
	{ name = "iPhone 11 portrait 414x896", size = Vector2.new(414, 804), touch = true },
	{ name = "Android portrait 360x780", size = Vector2.new(360, 690), touch = true },
	{ name = "iPhone Pro Max portrait 430x932", size = Vector2.new(430, 840), touch = true },
} :: { Screen }

-- The HudSlots context for a screen of this size (portrait: a phone held upright).
local function ctxOf(size: Vector2, touch: boolean, lab: boolean): HudSlots.Context
	local phone = math.min(size.X, size.Y) <= 500
	return { touch = touch, lab = lab, phone = phone, portrait = phone and size.Y > size.X }
end
-- A toast at its biggest on this screen (Toast: PORTRAIT_HEIGHT_MAX, PHONE_HEIGHT_MAX, HEIGHT_MAX).
local function toastH(size: Vector2): number
	local phone = math.min(size.X, size.Y) <= 500
	return if phone and size.Y > size.X then 110 elseif phone then 86 else 76
end

-- Every control here has a 3 px ink outline drawn outside its box; two outlines may not touch, and
-- there is a 4 px gap between them (so boxes are at least 10 px apart).
local OUTLINE = 3
local MIN_GAP = 4
local TOUCH_MIN = 44 -- px, the smallest tap target on a phone
-- Boxes that are never on screen at the same time (the view card replaces the hint and holds toasts).
local NEVER_TOGETHER: { [string]: { [string]: boolean } } = {
	Choice = { Experiment = true, Chase = true, Hint = true, Toast = true, Chip = true, GameBar = true, Light = true, HordeToast = true, Nuke = true, NukeHorde = true, HitInfo = true }, -- the card steps aside while a slot is picked; no nuke warning while it is up
	-- (The hit line is not drawn while the view card asks its question; the first minute's hint steps
	-- aside while it shows; nothing is fired while a slot is picked: HitInfo.show.)
	HitInfo = { Choice = true, Hint = true, Chip = true, Chase = true },
	Hint = { Experiment = true, Choice = true, HordeToast = true, NukeHorde = true, HitInfo = true, Weapons = true, Chase = true },
	Chip = { Experiment = true, Choice = true, HitInfo = true, Weapons = true, Chase = true },
	-- (Round 5: the big WEAPONS button waits out the first minute, and steps aside while a slot is picked.)
	Weapons = { Experiment = true, Hint = true, Chip = true },
	-- (Phase 1: the Experiment card waits out the first minute, steps aside while a slot is picked,
	-- for a chase, the arena and a horde; on a phone it has the big WEAPONS button's box, hidden there.)
	Experiment = { Hint = true, Chip = true, Chase = true, GameBar = true, HordeToast = true, NukeHorde = true, Weapons = true, Choice = true },
	-- (Round 5: SHOOT shows only with a gun picked, GRAB and THROW only with Grab.)
	Shoot = { Grab = true, Throw = true },
	Grab = { Shoot = true, Zoom = true },
	Throw = { Shoot = true, Zoom = true, Sprint = true },
	Zoom = { Grab = true, Throw = true, Sprint = true },
	-- (Phase 0: on a landscape phone RUN shares THROW's / ZOOM's box and steps aside for them:
	-- HudSlots.sprintFree.)
	Sprint = { Throw = true, Zoom = true },
	-- (The chase waits for the horde and the arena: ChaseService; never in the first minute.)
	-- (The hit line rests during a chase: HitInfo.show; the bar steps aside for the pick chip: ChaseHud.)
	Chase = { Experiment = true, GameBar = true, HordeToast = true, NukeHorde = true, Light = true, Hint = true, Choice = true, HitInfo = true, Chip = true, Mode = true, Play = true },
	-- (BUILD/PLAY show only while building on a phone; on an upright one the chase bar steps aside
	-- then, ChaseHud, and toasts go under them, BuildController -> Toast.setMinTop.)
	Mode = { Chase = true, Toast = true, GameBar = true, Nuke = true }, -- (the bar and the nuke banner go under them too: MinigameHud barTop, Toast.topY)
	Play = { Chase = true, Toast = true, GameBar = true, Nuke = true },
	-- (Toasts wait while the arena game's bar is up: MinigameHud pauses them; the view card is
	-- only ever shown in the lab, never in the arena.)
	Toast = { Choice = true, GameBar = true, Light = true, HordeToast = true, Nuke = true, NukeHorde = true },
	-- (Below the bar only while a horde runs in the lab: never with the first minute's hint or
	-- card, and it replaces the usual toast place.)
	HordeToast = { Experiment = true, Toast = true, Choice = true, Hint = true, Light = true, Nuke = true, NukeHorde = true },
	GameBar = { Experiment = true, Toast = true, Choice = true, Nuke = true },
	-- (The nuke warning has the toast's place, toasts wait; with the horde's bar up it goes under it.)
	Nuke = { Toast = true, HordeToast = true, NukeHorde = true, GameBar = true, Choice = true },
	NukeHorde = { Experiment = true, Toast = true, HordeToast = true, Nuke = true, Choice = true, Hint = true, Light = true },
	Light = { Toast = true, Choice = true, HordeToast = true },
	-- (V7-5: the event card and chip share the toast lane and give way: they hide while a toast, the
	-- nuke warning, a game bar, the view card, the first-visit line or BUILD/PLAY on an upright
	-- phone has the lane top (Toast.topY; EventShop tickBannerV7).)
	EventCard = { EventChip = true, Toast = true, HordeToast = true, Nuke = true, NukeHorde = true, GameBar = true, Choice = true, Light = true, Mode = true, Play = true },
	-- (V8-1.1: the CRASH card holds the toast lane: Toast.hold("Stunt").)
	StuntCard = { EventCard = true, EventChip = true, Toast = true, HordeToast = true, Nuke = true, NukeHorde = true, GameBar = true, Choice = true, Light = true, Mode = true, Play = true, Chase = true, Experiment = true }, -- (a toast in a chase; the experiment card steps aside)
	EventChip = { EventCard = true, Toast = true, HordeToast = true, Nuke = true, NukeHorde = true, GameBar = true, Choice = true, Light = true, Mode = true, Play = true },
	-- (Round 2, N5: the Robux packs step aside while Streamer Mode's gift guide is up.)
	Packs = { Guide = true },
	-- (Round 3, M6: on a phone the part counter takes the chaos meter's place while building.)
	Counter = { Chaos = true },
	Chaos = { Counter = true },
	Guide = { Packs = true, Deal = true, FirstPerson = true, SlowMo = true, Revive = true, Reset = true },
	-- (Round 5: today's deal and the sandbox column step aside in Streamer Mode, as the packs do.)
	Deal = { Guide = true },
	FirstPerson = { Guide = true },
	SlowMo = { Guide = true },
	Revive = { Guide = true },
	Reset = { Guide = true },
}
local TAPPABLE = { Experiment = true, Sprint = true, View = true, Replay = true, Ragdoll = true, Recenter = true, Grab = true, Throw = true, Shoot = true, Mode = true, Play = true,
	Weapons = true, Deal = true, FirstPerson = true, SlowMo = true, Revive = true, Reset = true }

local function overlap(a: Rect, b: Rect): boolean
	local m = OUTLINE + MIN_GAP / 2
	return a.x - m < b.x + b.w + m and b.x - m < a.x + a.w + m and a.y - m < b.y + b.h + m and b.y - m < a.y + a.h + m
end

-- A GuiObject's rect on a screen of this size (positions and sizes from its UDim2s, inside its
-- parent's rect and padding).
local function rectOf(object: GuiObject, screen: Vector2): Rect
	local parentRect: Rect = { x = 0, y = 0, w = screen.X, h = screen.Y, name = "" }
	local parent = object.Parent
	if parent and parent:IsA("GuiObject") then
		parentRect = rectOf(parent, screen)
		local pad = parent:FindFirstChildOfClass("UIPadding")
		if pad then
			local l = pad.PaddingLeft.Scale * parentRect.w + pad.PaddingLeft.Offset
			local r = pad.PaddingRight.Scale * parentRect.w + pad.PaddingRight.Offset
			local t = pad.PaddingTop.Scale * parentRect.h + pad.PaddingTop.Offset
			local b = pad.PaddingBottom.Scale * parentRect.h + pad.PaddingBottom.Offset
			parentRect = { x = parentRect.x + l, y = parentRect.y + t, w = parentRect.w - l - r, h = parentRect.h - t - b, name = "" }
		end
	end
	local size = object.Size
	local w = size.X.Scale * parentRect.w + size.X.Offset
	local h = size.Y.Scale * parentRect.h + size.Y.Offset
	if object.AutomaticSize ~= Enum.AutomaticSize.None then
		w, h = math.max(w, object.AbsoluteSize.X), math.max(h, object.AbsoluteSize.Y)
	end
	local pos = object.Position
	local x = parentRect.x + pos.X.Scale * parentRect.w + pos.X.Offset - object.AnchorPoint.X * w
	local y = parentRect.y + pos.Y.Scale * parentRect.h + pos.Y.Offset - object.AnchorPoint.Y * h
	return { x = x, y = y, w = w, h = h, name = object.Name }
end

-- Roblox's jump button: 70 px near the corner on a phone, 120 px higher up on a tablet.
local function jumpButton(screen: Vector2): Rect
	if math.min(screen.X, screen.Y) <= 500 then
		return { x = screen.X - 95, y = screen.Y - 90, w = 70, h = 70, name = "Jump" }
	end
	return { x = screen.X - 170, y = screen.Y - 210, w = 120, h = 120, name = "Jump" }
end

local function slotRect(name: string, ctx: HudSlots.Context, screen: Vector2): Rect
	-- (As drawn: a quiet control shrunk towards its anchor, HudSlots.scaleOf.)
	local at, size = HudSlots.rect(name, ctx, screen)
	return { x = at.X, y = at.Y, w = size.X, h = size.Y, name = name }
end

-- Every fixed control showing on this screen in this view (each at its largest moment: build mode
-- open, a replay on offer, the grab pad up).
local guideWidest = 300 -- (set from CreatorUI.guideWidthMax when run starts)

local function controls(screen: Vector2, touch: boolean, lab: boolean, pad: boolean?): { Rect }
	local ctx: HudSlots.Context = ctxOf(screen, touch, lab)
	local list: { Rect } = {}
	local names = { "View", "Replay", "Chaos", "Mode", "Play", "Counter" }
	if lab then
		table.insert(names, "Recenter")
	else
		table.insert(names, "Ragdoll")
	end
	if touch and not lab then
		table.insert(names, "Grab")
		table.insert(names, "Throw")
		table.insert(names, "Shoot")
		table.insert(names, "Sprint") -- (phase 0: RUN was never checked)
		table.insert(list, jumpButton(screen))
	end
	-- Round 2, N5: the Robux packs (off a phone) and, on a computer in the player view, the mouse
	-- help (Grab picked).
	if not ctx.phone then
		table.insert(names, "Packs")
		-- (Round 5: today's deal off a phone; the sandbox column on a computer.)
		table.insert(names, "Deal")
		if not touch then
			for _, n in HudSlots.SANDBOX do
				table.insert(names, n)
			end
		end
	end
	table.insert(names, "Weapons") -- (round 5: the big WEAPONS button, under the chaos meter)
	table.insert(names, "Experiment") -- (phase 1: the experiment card)
	if not touch and not lab then
		table.insert(names, "MouseHelp")
	end
	for _, name in names do
		table.insert(list, slotRect(name, ctx, screen))
	end
	-- Streamer Mode's gift guide (PC only: CreatorUI.streamDevice), at the widest any pairing makes it.
	if not touch and not pad then -- (V7-6: a console has no keyboard: never there)
		local w = guideWidest
		table.insert(list, { x = screen.X - 10 - w, y = CreatorUI.GUIDE_TOP, w = w, h = CreatorUI.GUIDE_HEIGHT, name = "Guide" })
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	-- The kit's Events launcher: placed by its own UDim2, as big as everything drawn in it (its
	-- labels hang below the buttons).
	local layer = playerGui:FindFirstChild("LihFolkUI")
	local column = layer and layer:FindFirstChild("Launcher")
	if column and column:IsA("GuiObject") then
		local box = rectOf(column, screen)
		local top, bottom = column.AbsolutePosition.Y, column.AbsolutePosition.Y + column.AbsoluteSize.Y
		local right = column.AbsolutePosition.X + column.AbsoluteSize.X
		for _, d in column:GetDescendants() do
			if d:IsA("GuiObject") and d.Visible then
				top = math.min(top, d.AbsolutePosition.Y)
				bottom = math.max(bottom, d.AbsolutePosition.Y + d.AbsoluteSize.Y)
				right = math.max(right, d.AbsolutePosition.X + d.AbsoluteSize.X)
			end
		end
		local h = bottom - top
		local w = right - column.AbsolutePosition.X
		-- One launcher's box (a phone shows just the MENU one): the column split evenly.
		local items = 0
		for _, child in column:GetChildren() do
			if child:IsA("GuiObject") and child.Visible then
				items += 1
			end
		end
		local layout = column:FindFirstChildOfClass("UIListLayout")
		local gap = if layout then layout.Padding.Offset else 12
		local itemW = w
		local itemH = (h - gap * (items - 1)) / math.max(items, 1)
		-- (The shipped lists, not the kit's live settings: a capture tool's own copy of the kit has not
		-- had HudMenu.start set them.)
		local HudMenu = require(script.Parent:WaitForChild("HudMenu")) :: any
		local keep = HudMenu.KEEP :: { [string]: boolean }
		if keep and column:FindFirstChild("Hud_" .. Controller.MENU_LAUNCHER) then
			-- Round 3, M6: the kept launchers and MENU on every device, at their largest moment (all
			-- shown): a column from COLUMN_TOP, or on a phone PHONE_KEEP's and MENU from
			-- PHONE_COLUMN_TOP, at the scale the kit gives them on THIS screen.
			local count = 1
			for _ in (if ctx.phone then HudMenu.PHONE_KEEP else keep) do
				count += 1
			end
			local kind = if ctx.phone and touch then "phone" elseif touch then "tablet" else "desktop"
			local S = Theme.Size
			local rows = if ctx.phone then math.ceil(count / 2) else count
			local natural = rows * S.hudButton + (rows - 1) * Theme.Space.sm
			local savedKeep = Controller.PHONE_KEEP
			Controller.PHONE_KEEP = HudMenu.PHONE_KEEP -- (columnScale reads it)
			local scale = Controller.columnScale(screen, kind :: any, touch, count)
			Controller.PHONE_KEEP = savedKeep
			local top = if ctx.phone then Controller.PHONE_COLUMN_TOP else Controller.COLUMN_TOP :: number
			table.insert(list, {
				x = S.screenMargin,
				y = top - 5 * scale,
				w = (if ctx.phone then 2 * S.hudButton + Theme.Space.sm + 6 else S.hudButton + 6) * scale,
				h = (natural + 5) * scale,
				name = "Launcher",
			})
		elseif ctx.phone and column:FindFirstChild("Hud_" .. Controller.MENU_LAUNCHER) then
			-- A phone shows the one MENU launcher (LihFolkUIController.applyLayout), centred on the
			-- left edge whatever the column does on this screen.
			table.insert(list, { x = box.x, y = screen.Y / 2 - itemH / 2, w = itemW, h = itemH, name = "Launcher" })
		elseif Controller.COLUMN_TOP then
			-- The whole column, hung from COLUMN_TOP at the scale the kit gives it on THIS screen
			-- (Controller.columnScale: smaller on a short window), its badges (5 px over the top
			-- and the right edge) included.
			local kind = if ctx.phone and touch then "phone" elseif touch then "tablet" else "desktop"
			local S = Theme.Size
			local scale = Controller.columnScale(screen, kind :: any, touch, items)
			local natural = items * S.hudButton + (items - 1) * Theme.Space.sm
			table.insert(list, {
				x = S.screenMargin,
				y = (Controller.COLUMN_TOP :: number) - 5 * scale,
				w = (S.hudButton + 6) * scale,
				h = (natural + 5) * scale,
				name = "Launcher",
			})
		else
			local center = box.y + box.h / 2 + (top + bottom) / 2 - (column.AbsolutePosition.Y + column.AbsoluteSize.Y / 2)
			table.insert(list, { x = box.x, y = center - h / 2, w = w, h = h, name = "Launcher" })
		end
	end
	return list
end

-- Everything on one screen in one view and bar state: the fixed controls, the bar and (with the
-- full bar) the pick chip.
function LayoutCheck.scene(s: Screen, lab: boolean, withTools: boolean): ({ Rect }, PokeController.Plan)
	local plan = PokeController.plan(s.size, s.touch, lab, withTools, Toys.SLOTS)
	local bar: Rect = {
		x = (s.size.X - plan.size.X) / 2,
		y = s.size.Y - plan.bottom - plan.size.Y,
		w = plan.size.X,
		h = plan.size.Y,
		name = "Bar",
	}
	local all = controls(s.size, s.touch, lab, s.pad)
	table.insert(all, bar)
	-- The help line under the bar (a computer, the full bar).
	if not s.touch and withTools then
		local hw = PokeController.helpWidth(s.size)
		table.insert(all, { x = (s.size.X - hw) / 2, y = s.size.Y - PokeController.HELP_BOTTOM - PokeController.HELP_H, w = hw, h = PokeController.HELP_H, name = "HelpLine" })
	end
	if withTools and plan.chip then
		-- The chip above the bar while picking a slot (where it fits): 40 px tall, 10 above the
		-- bar, as wide as PokeController.plan says.
		table.insert(all, { x = (s.size.X - plan.chipWidth) / 2, y = bar.y - 50, w = plan.chipWidth, h = 40, name = "Chip" })
	end
	-- The one-line hint above the bar (first minute), and the card that asks which view you want
	-- (once, never with the hint; it can still be up after the catalog opens, with the full bar).
	if not withTools then
		table.insert(all, { x = (s.size.X - 260) / 2, y = bar.y - 14 - 44, w = 260, h = 44, name = "Hint" })
	end
	if Config.VIEW_CARD then -- (phase 0: the card is off, Config.VIEW_CARD)
		table.insert(all, { x = (s.size.X - 270) / 2, y = bar.y - 10 - 104, w = 270, h = 104, name = "Choice" })
	end
	-- The hit line (round 2, N2), just above the bar: two lines at most.
	local phone = math.min(s.size.X, s.size.Y) <= 500
	local hw = HitInfo.widthOn(s.size)
	table.insert(all, { x = (s.size.X - hw) / 2, y = bar.y - HitInfo.ABOVE_BAR - HitInfo.HEIGHT, w = hw, h = HitInfo.HEIGHT, name = "HitInfo" })
	-- The arena game's bar (MinigameHud), top middle (the light is drawn on it).
	local gb = MinigameHud.BAR_SIZE
	table.insert(all, { x = (s.size.X - gb.X) / 2, y = HudSlots.eventTop(s.size, MinigameHud.BAR_TOP), w = gb.X, h = gb.Y, name = "GameBar" })
	-- Round 5: the NPC Chase's health bar (top middle, under the toasts; never with the horde's or
	-- the arena's bar: ChaseService waits for them) and, on a touch screen in the player view, ZOOM
	-- in its slot (only with a scoped gun: never with GRAB or THROW).
	local ChaseHud = require(script.Parent:WaitForChild("ChaseHud")) :: any
	table.insert(all, { x = (s.size.X - ChaseHud.SIZE.X) / 2, y = ChaseHud.top(s.size), w = ChaseHud.SIZE.X, h = ChaseHud.SIZE.Y, name = "Chase" })
	if s.touch and not lab then
		local ctx = ctxOf(s.size, true, false)
		local at, size = HudSlots.rect("Zoom", ctx, s.size)
		table.insert(all, { x = at.X, y = at.Y, w = size.X, h = size.Y, name = "Zoom" })
	end
	return all, plan
end

-- One line per screen, view and bar state: the bar's shape and every overlap (none, ideally).
function LayoutCheck.run(): string
	local lines = {}
	local problems = 0
	guideWidest = CreatorUI.guideWidthMax()
	table.insert(lines, string.format("gift guide at its widest pairing: %d px wide (checked as the \"Guide\" box on PC screens)", guideWidest))
	-- Creator mode: only its eye (top-right), the REC pill (top middle), the guide and Roblox's own
	-- jump button stay; the eye may touch none of them.
	local eyeProblems = problems
	for _, s in LayoutCheck.SCREENS do
		local eye: Rect = { x = s.size.X - CreatorUI.EYE_INSET - CreatorUI.EYE_SIZE, y = CreatorUI.EYE_INSET, w = CreatorUI.EYE_SIZE, h = CreatorUI.EYE_SIZE, name = "Eye" }
		local others: { Rect } = { { x = (s.size.X - 150) / 2, y = 8, w = 150, h = 44, name = "Rec" } }
		if s.touch then
			table.insert(others, jumpButton(s.size))
		else
			table.insert(others, { x = s.size.X - 10 - guideWidest, y = CreatorUI.GUIDE_TOP, w = guideWidest, h = CreatorUI.GUIDE_HEIGHT, name = "Guide" })
		end
		for _, o in others do
			if overlap(eye, o) then
				problems += 1
				table.insert(lines, string.format("%-18s creator mode: Eye/%s", s.name, o.name))
			end
		end
	end
	if problems == eyeProblems then
		table.insert(lines, "creator mode: the eye (top-right) clear of the REC pill, the jump button and the gift guide on every screen")
	end
	-- V8-0.9 (the day-2 tablet): HudV3's five squares on touch (HudV3Layout) stay out of the move
	-- thumb's zone and clear of RAGDOLL, the jump button and every other control and toast.
	if (Config :: any).LOOK_V3 then
		local Layout = require(script.Parent:WaitForChild("HudV3Layout")) :: any
		local v3Problems = problems
		local TABLETS = {
			{ name = "iPad", size = Vector2.new(1180, 742) },
			{ name = "iPad mini 1024x704", size = Vector2.new(1024, 704) },
			{ name = "Android tablet 1280x736", size = Vector2.new(1280, 736) },
		}
		-- (Hidden under HudV3: the chaos meter and its build-mode counter (ChaosMeter), the big WEAPONS
		-- button and today's deal (HudPlus), the event packs (EventShop).)
		local SKIP = { Chaos = true, Counter = true, Weapons = true, Deal = true, Packs = true }
		for _, t in TABLETS do
			for _, lab in { false, true } do
				local ctx = ctxOf(t.size, true, lab)
				local ragdoll = slotRect("Ragdoll", ctx, t.size)
				local centre, tw, ty = HudSlots.toastBox(t.size, ctx)
				local squares = Layout.touchRects(t.size, ragdoll.y + ragdoll.h, centre - tw / 2)
				local others: { Rect } = { jumpButton(t.size), Layout.thumbZone(t.size) }
				for _, r in controls(t.size, true, lab) do
					if not SKIP[r.name] then
						table.insert(others, r)
					end
				end
				table.insert(others, { x = centre - tw / 2, y = ty or 10, w = tw, h = toastH(t.size), name = "Toast" })
				for _, sq in squares do
					for _, o in others do
						if overlap(sq, o) then
							problems += 1
							table.insert(lines, string.format("%-18s HudV3 touch%s: %s/%s", t.name, if lab then " lab" else "", sq.name, o.name))
						end
					end
				end
			end
		end
		if problems == v3Problems then
			table.insert(lines, "HudV3 on tablets: the five squares clear of the move thumb's zone, RAGDOLL, the jump button, the toasts and every control")
		end
	end
	for _, s in LayoutCheck.SCREENS do
		for _, lab in { false, true } do
			for _, withTools in { false, true } do
				local all, plan = LayoutCheck.scene(s, lab, withTools)
				local bar: Rect = all[1]
				for _, r in all do
					if r.name == "Bar" then
						bar = r
					end
				end
				local hits = {}
				-- A toast at its biggest, where Toast puts it: it may not touch anything.
				local phone = math.min(s.size.X, s.size.Y) <= 500
				local centre, tw, ty = HudSlots.toastBox(s.size, ctxOf(s.size, s.touch, lab))
				local toast: Rect = { x = centre - tw / 2, y = ty or 10, w = tw, h = toastH(s.size), name = "Toast" }
				table.insert(all, toast)
				-- V7-5: the event card and its chip share the toast lane (EventShop BANNER_V7: toasts wait
				-- for the card, the chip gives way to a toast or the nuke warning), as wide as it allows.
				if (Config :: any).BANNER_V7 then
					local cs = math.min(1, tw / 392)
					table.insert(all, { x = centre - 392 * cs / 2, y = ty or 10, w = 392 * cs, h = 80 * cs, name = "EventCard" })
					table.insert(all, { x = centre - 214 * cs / 2, y = ty or 10, w = 214 * cs, h = 44 * cs, name = "EventChip" })
				end
				-- V8-1.1: the CRASH card (StuntHud) holds the toast lane while it shows.
				if (Config :: any).STUNT_SCORE then
					local sw = math.min(tw, 380)
					table.insert(all, { x = centre - sw / 2, y = ty or 10, w = sw, h = 84, name = "StuntCard" })
				end
				-- During a horde toasts go on below the game bar (Toast.setMinTop); a phone shows them
				-- in the bar's points line instead (MinigameHud setBar), so it has no such box.
				local underBar = HudSlots.eventTop(s.size, MinigameHud.BAR_TOP) + MinigameHud.BAR_SIZE.Y + MinigameHud.TOAST_UNDER_GAP
				if not phone then
					table.insert(all, { x = centre - tw / 2, y = underBar, w = tw, h = 76, name = "HordeToast" })
				end
				-- The nuke warning (FriendsUI): in the toast's place, as wide as the toast box allows
				-- (toasts wait while it shows); under the horde's bar while one runs.
				local nw = math.min(FriendsUI.BANNER.X, tw)
				table.insert(all, { x = centre - nw / 2, y = ty or 10, w = nw, h = FriendsUI.BANNER.Y, name = "Nuke" }) -- (FriendsUI: at Toast.topY)
				if not phone then -- (a phone shows it in the horde bar's points line instead)
					table.insert(all, { x = centre - nw / 2, y = underBar, w = nw, h = FriendsUI.BANNER.Y, name = "NukeHorde" })
				end
				for i = 1, #all do
					local a = all[i]
					if a.x < 0 or a.y < 0 or a.x + a.w > s.size.X or a.y + a.h > s.size.Y then
						table.insert(hits, a.name .. " off screen")
					end
					-- (A touch screen: a 44 px tap. A mouse: 32 px; the owner wants a quieter HUD, 10 Nov.)
					local floor = if s.touch then TOUCH_MIN else 32
					if TAPPABLE[a.name] and (a.w < floor or a.h < floor) then
						table.insert(hits, string.format("%s %dx%d under %d px", a.name, a.w, a.h, floor))
					end
					for k = i + 1, #all do
						local apart = NEVER_TOGETHER[a.name]
						local apartToo = NEVER_TOGETHER[all[k].name] -- (either way round)
						if not (apart and apart[all[k].name]) and not (apartToo and apartToo[a.name]) and overlap(a, all[k]) then
							table.insert(hits, a.name .. "/" .. all[k].name)
						end
					end
				end
				if plan.cell.X < TOUCH_MIN or plan.cell.Y < TOUCH_MIN then
					table.insert(hits, "slots under 44 px")
				end
				problems += #hits
				table.insert(lines, string.format("%-18s %-6s %-9s %d row(s), slot %dx%d, bar %dx%d at y %d: %s",
					s.name, if lab then "lab" else "player", if withTools then "full" else "first min",
					plan.rows, plan.cell.X, plan.cell.Y, plan.size.X, plan.size.Y, bar.y,
					if #hits == 0 then "clear" else table.concat(hits, ", ")))
			end
		end
	end
	-- The longest messages players see, in the toast's font, at each screen's toast width.
	local longest = {
		"Tools are for the dummies and the lab, not other players",
		"Tap a button, timer or sensor, then what it should switch",
		"Big tools need a breather. Try again in a second",
		"Grab isn't in your bar. Add it from WEAPONS",
		"Charts off. Turn on again in WEAPONS (or H)",
		"Get up first to hit with Uppercut!",
		-- Friends and the horde (phase G)
		"HORDE of 18 at the Plaza in 10 s! Open Places to go",
		"Horde cleared! +5 takedowns for each helper",
		"The horde is over: 18 of 18 down",
		"SuperLongDisplayName was just hit. Give them a minute!",
		"SuperLongDisplayName is in a game. Try after it!",
		"NUKE FROM SUPERLONGDISPL in 3!",
		"Gift skipped: the lab is full of dummies right now",
		"Streamer Mode works in your own private server",
		"SuperLongDisplayName turned pranks off",
		"PvP turns off in 5 seconds",
		"Your next nuke in 9:59",
		-- Phases H-L
		"UNLOCKED: CHICKEN SPELL! Find it in WEAPONS.",
		"Take down 150 more for the Slow-Mo Spell, or get it in WEAPONS",
		-- Round 2, N4 (weapons)
		"Your Plasma Blade from last time is here. EQUIP it!",
		"The Chicken Spell is yours. EQUIP it!",
		"You own every weapon! 2 eggs instead",
		"Only 14 more takedowns for the Chicken Spell!",
		"Take down 14 more for the Chicken Spell!",
		"Your progress is still loading. Try again in a moment",
		"The server is restarting. Try again in the next one!",
		"Chicken Spell is off your bar. EQUIP another one!",
		"Chicken Spell is yours already!",
		"Buying weapons is coming soon!",
		"Loading your progress. Try again in a moment",
		"Your free ULTRA is over. Get it to keep the speed!",
		"Plug in a keyboard to change keys",
		"Swapped: HOME Lab view: back to the middle, ENTER Play / stop the machine",
		"BKSP would clash with another key. Pick another one",
		"Finger Heart \u{2192} Fling the streamer!",
		"Roblox can't check your passes right now. Rejoin if one is missing",
		"No horde this time: the plaza is too full",
		"A lab came free: it's yours! Open Places > My Lab",
		"Nobody has that lab now",
		-- (Phase 0: cut on a phone in the owner's captures.)
		"Play 2 more min for a FREE weapon egg! The clock is on WEAPONS.",
		"Daily egg! Come back tomorrow for the next one, the streak grows",
	}
	for _, s in LayoutCheck.SCREENS do
		local phone = math.min(s.size.X, s.size.Y) <= 500
		local _, tw = HudSlots.toastBox(s.size, ctxOf(s.size, s.touch, false))
		local textSize = if phone then 18 else 20
		local maxLines = if phone and s.size.Y > s.size.X then 4 elseif phone then 3 else 2
		for _, text in longest do
			local params = Instance.new("GetTextBoundsParams")
			params.Text = text
			params.Font = Theme.Fonts.display
			params.Size = textSize
			params.Width = tw - 32
			local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
			if ok and bounds.Y > maxLines * textSize * 1.25 then
				problems += 1
				table.insert(lines, string.format("%s: toast text over %d lines: %s", s.name, maxLines, text))
			end
		end
		if phone then
			table.insert(lines, string.format("%-18s toast box %d wide, %d lines of %d px: longest messages fit", s.name, tw, maxLines, textSize))
		end
	end
	-- The arena's points line (MinigameHud): the longest messages, wrapped, within its lines. On a
	-- phone during a horde every toast shows there too (MinigameHud setBar): those are measured as
	-- well.
	local popTexts = table.clone(MinigameHud.POP_LONGEST)
	for _, text in longest do
		table.insert(popTexts, text)
	end
	for _, s in LayoutCheck.SCREENS do
		local w = MinigameHud.popWidth(s.size.X)
		local worst = 0
		for _, text in if math.min(s.size.X, s.size.Y) <= 500 then popTexts else MinigameHud.POP_LONGEST do
			local params = Instance.new("GetTextBoundsParams")
			params.Text = text
			params.Font = Theme.Fonts.display
			params.Size = MinigameHud.POP_TEXT
			params.Width = w
			local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
			if ok then
				worst = math.max(worst, bounds.Y)
				if bounds.Y > MinigameHud.popLines(s.size) * MinigameHud.POP_TEXT * 1.25 then
					problems += 1
					table.insert(lines, string.format("%s: arena line over %d lines: %s", s.name, MinigameHud.popLines(s.size), text))
				end
			end
		end
		if math.min(s.size.X, s.size.Y) <= 500 then
			table.insert(lines, string.format("%-18s arena line %d wide, %d lines of %d px: longest fit (%d px tall)", s.name, w, MinigameHud.popLines(s.size), MinigameHud.POP_TEXT, worst))
		end
	end
	-- A line's width as the text engine draws it (the legacy GetTextSize measures about a tenth
	-- narrower than the FredokaOne FontFace).
	local function widthOf(text: string, size: number): number
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = Theme.Fonts.display
		params.Size = size
		params.Width = 100000
		local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
		return if ok then bounds.X else TextService:GetTextSize(text, size, Enum.Font.FredokaOne, Vector2.new(100000, 100)).X * 1.2
	end
	-- The same in Builder Sans Bold (the tiles' names, the help line).
	local function boldWidthOf(text: string, size: number): number
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = Theme.Fonts.body
		params.Size = size
		params.Width = 100000
		local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
		return if ok then bounds.X else TextService:GetTextSize(text, size, Enum.Font.SourceSansBold, Vector2.new(100000, 100)).X * 1.1
	end
	-- The game bar's titles (16 px padding inside the bar): a title too wide shrinks to fit, never
	-- below MinigameHud.TITLE_MIN.
	do
		local room = MinigameHud.BAR_SIZE.X - 16
		local smallest, smallestText = math.huge, ""
		for _, t in MinigameHud.TITLES_LONGEST do
			local w = widthOf(t.text, t.size)
			local drawn = if w > room then math.floor(t.size * room / w) else t.size
			if drawn < smallest then
				smallest, smallestText = drawn, t.text
			end
			if drawn < MinigameHud.TITLE_MIN then
				problems += 1
				table.insert(lines, string.format("game bar title would shrink to %d px (under %d): %s", drawn, MinigameHud.TITLE_MIN, t.text))
			end
		end
		table.insert(lines, string.format("game bar titles: all fit %d px; the widest shrinks to %d px (%s)", room, smallest, smallestText))
	end
	-- Doctor mode (N3): the monitor in the bar's place (the bar is away), clear of every control
	-- and of a toast at its biggest (toasts go on while it shows), on every screen and view; and its
	-- tiles never shrink under a readable size.
	do
		local before = problems
		local smallest = math.huge
		local smallestWord = 12
		for _, s in LayoutCheck.SCREENS do
			for _, lab in { false, true } do
				local phone = math.min(s.size.X, s.size.Y) <= 500
				local p = HospitalCharts.plan(s.size, s.touch, lab)
				local monitor: Rect = { x = (s.size.X - p.size.X) / 2, y = s.size.Y - p.bottom - p.size.Y, w = p.size.X, h = p.size.Y, name = "Monitor" }
				local all = controls(s.size, s.touch, lab, s.pad)
				local centre, tw, ty = HudSlots.toastBox(s.size, ctxOf(s.size, s.touch, lab))
				table.insert(all, { x = centre - tw / 2, y = ty or 10, w = tw, h = toastH(s.size), name = "Toast" })
				local hits = {}
				if monitor.x < 0 or monitor.y < 0 or monitor.x + monitor.w > s.size.X then
					table.insert(hits, "Monitor off screen")
				end
				for _, r in all do
					-- (SHOOT is not drawn in doctor mode: tools rest, PokeController.active.)
					if r.name ~= "Shoot" and r.name ~= "Weapons" and r.name ~= "Experiment" and r.name ~= "Recenter" and overlap(monitor, r) then -- (round 5: the big WEAPONS button rests in doctor mode too; so does the experiment card, ExperimentCard.shown)
						table.insert(hits, "Monitor/" .. r.name)
					end
				end
				local tileW = HospitalCharts.tileWidth(p)
				smallest = math.min(smallest, tileW)
				-- (Round 3, M5) The tiles' labels at their longest, in a tile: the cuff's time, the GCS
				-- in parts, the blood with its share; and the blood's class in its part of the tile.
				for _, label in { "NIBP 00:00:00", "GCS E4 V5 M6", "BLOOD 100%", "TEMP \u{00B0}C", "RESP /min" } do
					local size = 12
					while size > HospitalCharts.LABEL_MIN and widthOf(label, size) > tileW - 12 do
						size -= 1
					end
					if widthOf(label, size) > tileW - 12 then
						table.insert(hits, string.format("tile label %q over %d px", label, math.floor(tileW - 12)))
					end
					smallestWord = math.min(smallestWord, size)
				end
				local classRoom = (1 - HospitalCharts.BLOOD_SPLIT) * tileW - 6
				local classSize = 12
				while classSize > 9 and widthOf("CL III", classSize) > classRoom do
					classSize -= 1
				end
				if widthOf("CL III", classSize) > classRoom then
					table.insert(hits, string.format("blood class over %d px", math.floor(classRoom)))
				end
				-- The body map is tall enough to read the wounds on it.
				local mapH = p.ecg + 6 + (if p.wide then p.tile else 2 * p.tile + 4)
				if mapH < 70 or p.body < 34 then
					table.insert(hits, string.format("body map %dx%d", p.body, mapH))
				end
				-- The GCS tile's word (scaled 12 down to 9 px in its share of the tile).
				local room = (1 - HospitalCharts.GCS_SPLIT) * tileW - 6
				for _, word in { "Alert", "Confused", "Drowsy", "Stupor", "Out cold", "None" } do
					local size = 12
					while size > 9 and widthOf(word, size) > room do
						size -= 1
					end
					if widthOf(word, size) > room then
						table.insert(hits, string.format("GCS word %q over %d px", word, math.floor(room)))
					end
					smallestWord = math.min(smallestWord, size)
				end
				-- The patient's name beside LEAVE (a touch target) gets 140 px at least.
				if p.size.X - 20 - HospitalCharts.LEAVE.X < 140 then
					table.insert(hits, string.format("name %d px", p.size.X - 20 - HospitalCharts.LEAVE.X))
				end
				if HospitalCharts.LEAVE.Y < TOUCH_MIN or HospitalCharts.LEAVE.X < TOUCH_MIN then
					table.insert(hits, "LEAVE under 44 px")
				end
				if #hits > 0 then
					problems += #hits
					table.insert(lines, string.format("%-18s %-6s doctor: %s", s.name, if lab then "lab" else "player", table.concat(hits, ", ")))
				end
			end
		end
		-- A tile holds "120/80" at 17 px and its label ("NIBP mmHg") at 11 px: 70 px at least.
		if smallest < 70 then
			problems += 1
		end
		if problems == before then
			table.insert(lines, string.format("doctor mode: the monitor clear of every control and toast on every screen and view; tiles %d px wide at the least (70 needed); the GCS words fit at %d px or more", math.floor(smallest), smallestWord))
		else
			table.insert(lines, string.format("doctor mode: narrowest tile %d px (70 needed)", math.floor(smallest)))
		end
	end
	-- The hit lines (round 3, M2): the top line's longest single entry and the bottom line's longest
	-- text each fit on one line on every screen (the top line drops older hits to fit by itself).
	do
		local worst, worstText = 0, ""
		for _, s in LayoutCheck.SCREENS do
			local phone = math.min(s.size.X, s.size.Y) <= 500
			local room = HitInfo.widthOn(s.size)
			local size = if phone then HitInfo.TEXT_PHONE else HitInfo.TEXT
			for _, pair in { { HitInfo.LONGEST_TOP, size + HitInfo.LEAD_UP }, { HitInfo.LONGEST_STATUS, size } } do
				for _, text in pair[1] do
					local count = math.ceil(widthOf(text, pair[2]) / room)
					if count > worst then
						worst, worstText = count, text
					end
					if count > 1 then
						problems += 1
					end
				end
			end
		end
		table.insert(lines, string.format("hit lines: the longest takes %d line(s) (%s): %s", worst, worstText, if worst <= 1 then "fits" else "TOO LONG"))
	end
	-- Other players' lab cards in the Places window: the title is their display name (up to 20
	-- characters), scaled to fit the card at 26 px; on a phone the window is drawn at its smallest
	-- scale. A long mixed-case name must stay at 11 px or more; the all-W extreme is reported too.
	do
		local phoneScale = Theme.Size.touchDrawnMin / Theme.Size.touchMin
		local room = 220 - 2 * Theme.Space.md
		local function drawn(text: string): number
			local w = widthOf(text, 26)
			return (if w > room then 26 * room / w else 26) * phoneScale
		end
		-- (Names are cut to PlaceMenu.cardName's length with an ellipsis.)
		local PlaceMenu = require(script.Parent:WaitForChild("PlaceMenu")) :: any
		local long = drawn(PlaceMenu.cardName("Bartholomewsmithson2"))
		local widest = drawn(PlaceMenu.cardName("WWWWWWWWWWWWWWWWWWWW"))
		if long < 11 or widest < 11 then
			problems += 1
		end
		table.insert(lines, string.format("lab card names (cut at 14 letters): a long name %.1f px on a phone, the all-W extreme %.1f px (floor 11): %s", long, widest, if math.min(long, widest) >= 11 then "readable" else "TOO SMALL"))
	end
	-- The Friends window's lab button (round 3, M1): its two words fit the 112 px button (less its
	-- padding) at the button text's floor or bigger.
	do
		local room = FriendsUI.BUTTON_W - 2 * Theme.Space.md
		local worst = math.huge
		for _, text in { "LAB INVITE", "INVITED" } do
			local size = 22
			while size > Theme.MinTextSize and widthOf(text, size) > room do
				size -= 1
			end
			worst = math.min(worst, size)
			if widthOf(text, size) > room then
				problems += 1
			end
		end
		table.insert(lines, string.format("friends lab button: LAB INVITE / INVITED fit %d px of room at %d px text or more (floor %d)", room, worst, Theme.MinTextSize))
	end
	-- The tool bar's slab labels with their pictures: beside the word on a wide slab, above it on a
	-- narrow one (PokeController.STACK_BELOW); the longest word at the 12 px floor must fit the room
	-- left in every screen and bar state.
	-- (UI v2: the floor is PokeController.SLAB_MIN_TEXT, 14; a slab whose word cannot fit shows its
	-- picture alone (PokeController.iconOnly): counted, not a problem. Below, the v2 section.)
	if KitStyle.V2 then
		local iconOnly, states = 0, 0
		for _, s in LayoutCheck.SCREENS do
			for _, lab in { false, true } do
				for _, withTools in { false, true } do
					local plan = PokeController.plan(s.size, s.touch, lab, withTools, Toys.SLOTS)
					states += 1
					for _, toy in Toys.list do
						if PokeController.iconOnly(plan.cell.X, plan.cell.Y, toy.short) then
							iconOnly += 1
							break
						end
					end
				end
			end
		end
		table.insert(lines, string.format("UI v2 tool bar: words at %d px or the picture alone; %d of %d screen states show some slab as a picture only", PokeController.SLAB_MIN_TEXT, iconOnly, states))
	else
		local longestWord, longestW = "", 0
		for _, toy in Toys.list do
			local w = widthOf(toy.short, 12)
			if w > longestW then
				longestWord, longestW = toy.short, w
			end
		end
		local depth = Theme.Size.depthSmall
		local tight = 0
		for _, s in LayoutCheck.SCREENS do
			for _, lab in { false, true } do
				for _, withTools in { false, true } do
					local plan = PokeController.plan(s.size, s.touch, lab, withTools, Toys.SLOTS)
					local stacked = plan.cell.X < PokeController.STACK_BELOW
					local _, pad = PokeController.pictureFor(plan.cell.Y)
					local roomW = plan.cell.X - 3 - (if stacked then 3 else pad)
					local roomH = plan.cell.Y - depth - (if stacked then PokeController.STACK_TOP else 0) - 4
					if longestW > roomW or roomH < 14 then
						problems += 1
						tight += 1
						table.insert(lines, string.format("%-18s %s %s: slab %dx%d leaves %dx%d for \"%s\" (%d px)", s.name, if lab then "lab" else "player", if withTools then "full" else "first min", plan.cell.X, plan.cell.Y, roomW, roomH, longestWord, longestW))
					end
				end
			end
		end
		table.insert(lines, string.format("tool bar slabs: the longest word \"%s\" (%d px at 12): %s", longestWord, longestW, if tight == 0 then "fits beside or under its picture on every screen" else (tight .. " screen states too tight")))
		-- (end of the v1 slab check)
	end
	-- The bar's first slab (round 2, N5): WEAPONS (CANCEL while picking) at its 10 px floor, on the
	-- narrowest full bar.
	do
		local narrowest = math.huge
		for _, s in LayoutCheck.SCREENS do
			for _, lab in { false, true } do
				narrowest = math.min(narrowest, PokeController.plan(s.size, s.touch, lab, true, Toys.SLOTS).cell.X)
			end
		end
		local need = math.max(widthOf("WEAPONS", PokeController.TOOLS_MIN_TEXT), widthOf("CANCEL", PokeController.TOOLS_MIN_TEXT))
		local room = narrowest - 6
		if need > room and not KitStyle.V2 then
			problems += 1 -- (UI v2: too narrow means the drawn toolbox alone, not a cut word)
		end
		table.insert(lines, string.format("WEAPONS slab: %d px of %d at %d px on the narrowest bar: %s", need, room, PokeController.TOOLS_MIN_TEXT, if need <= room then "fits" else "TOO WIDE"))
	end
	-- Round 2, N5 (fix round 2): the left column's names at their 13 px floor inside a tile (64
	-- wide, 3 px each side); the longest help line at its 12 px floor in the narrowest one (a
	-- computer: 20 px of padding); when the Robux packs show.
	do
		local room = Theme.Size.hudButton - 6
		local widest, which = 0, ""
		for _, name in { "Shop", "Weapons", "Sandbox", "Places", "Eggs", "Friends", "Creator", "Done", "Menu" } do
			local w = boldWidthOf(name, 13)
			if w > widest then
				widest, which = w, name
			end
		end
		if widest > room then
			problems += 1
		end
		table.insert(lines, string.format("left tiles: the widest name \"%s\" is %d px at 13 px of %d: %s", which, widest, room, if widest <= room then "fits" else "TOO WIDE"))
		local narrowest = math.huge
		for _, sc in LayoutCheck.SCREENS do
			if not sc.touch then
				narrowest = math.min(narrowest, PokeController.helpWidth(sc.size) - 20)
			end
		end
		local longest, longestText = 0, ""
		for _, toy in Toys.list do
			for _, lab in { false, true } do
				local text = PokeController.helpText(toy.id, lab)
				local w = boldWidthOf(text, 12)
				if w > longest then
					longest, longestText = w, text
				end
			end
		end
		if longest > narrowest then
			problems += 1
		end
		table.insert(lines, string.format("help line: the longest (%s) is %d px at 12 px of %d: %s", longestText, longest, narrowest, if longest <= narrowest then "fits" else "TOO LONG"))
		local EventShop = require(script.Parent:WaitForChild("EventShop")) :: any
		local rule = EventShop.packsShown(false, true, false, false) and not EventShop.packsShown(true, true, false, false) and not EventShop.packsShown(false, false, false, false) and not EventShop.packsShown(false, true, true, false) and not EventShop.packsShown(false, true, false, true)
		if not rule then
			problems += 1
		end
		table.insert(lines, "Robux packs: shown off a phone after the first minute; hidden on a phone, in the first minute, while building, in Streamer Mode: " .. (if rule then "holds" else "WRONG"))
	end
	-- Inside one control (fix round 1 of N5): the build rail's words beside their key chips (a cell
	-- 72 px wide, 4 px padding on the left, the chip's 20 + 2 on the right), at the 11 px floor.
	do
		local room = 72 - 4 - 22
		local widest, which = 0, ""
		for _, word in { "Place", "Delete", "Paint", "Tune", "Wire", "Pin", "Turn", "Tilt", "Undo", "Saves" } do
			local w = widthOf(word, 11)
			if w > widest then
				widest, which = w, word
			end
		end
		if widest > room then
			problems += 1
		end
		table.insert(lines, string.format("build rail: the widest word \"%s\" is %d px at 11 px of %d beside its key chip: %s", which, widest, room, if widest <= room then "clear of the chip" else "UNDER THE CHIP"))
	end
	-- The phone MENU (HudMenu): every button a phone shows in view without scrolling (the window's
	-- header and padding take HEADER design units of its height).
	do
		local HudMenu = require(script.Parent:WaitForChild("HudMenu")) :: any
		local HEADER = 109
		local shownOnPhone = HudMenu.phoneCount() -- (counted from its entries: KEYS is for keyboards only)
		local rows = math.ceil(shownOnPhone / 2)
		local need = rows * HudMenu.CELL.Y + (rows - 1) * HudMenu.GAP
		-- (Two to a row only if two fit the grid: the 420-unit window's grid is 366 wide, measured in
		-- play: its padding and scroll bar take the rest. Round 3, M6: at 180 a row held one.)
		local GRID_W = HudMenu.WINDOW.X - 54
		local pair = 2 * HudMenu.CELL.X + HudMenu.GAP
		if pair > GRID_W then
			problems += 1
		end
		table.insert(lines, string.format("MENU grid: two buttons need %d of %d design units: %s", pair, GRID_W, if pair <= GRID_W then "two to a row" else "ONE TO A ROW"))
		local size = Theme.Size
		for _, s in LayoutCheck.SCREENS do
			if s.touch and math.min(s.size.X, s.size.Y) <= 500 then
				local margin = (size.screenMargin or 16) * 2
				local floorScale = size.touchDrawnMin / size.touchMin
				local tall = HudMenu.WINDOW.Y
				local scale = math.max(math.min(1, (s.size.Y - margin) / tall), floorScale)
				local body = math.min(tall, (s.size.Y - margin) / scale) - HEADER
				if body < need then
					problems += 1
				end
				table.insert(lines, string.format("%-18s MENU: %d buttons in %d rows need %d of %d design units: %s", s.name, shownOnPhone, rows, need, body, if body >= need then "all in view" else "SCROLLS"))
			end
		end
	end
	-- The catalog window as the kit fits it (LihFolkUIController.applyLayout) on each touch screen.
	local size = Theme.Size
	for _, s in LayoutCheck.SCREENS do
		if s.touch then
			local margin = (size.screenMargin or 16) * 2
			local design = Vector2.new(820, 780)
			local fit = math.min((s.size.X - margin) / design.X, (s.size.Y - margin) / design.Y)
			local floor = size.touchDrawnMin / size.touchMin
			local scale = math.max(math.min(1, fit), floor)
			local w = math.min(design.X, (s.size.X - margin) / scale) * scale
			local h = math.min(design.Y, (s.size.Y - margin) / scale) * scale
			if w > s.size.X - margin + 1 or h > s.size.Y - margin + 1 then
				problems += 1
			end
			table.insert(lines, string.format("%-18s catalog window %dx%d at scale %.2f (cards %dx%d, taps >= %d px): %s",
				s.name, w, h, scale, ToolCatalog.CARD.X * scale, ToolCatalog.CARD.Y * scale, size.touchMin * scale,
				if w <= s.size.X - margin + 1 and h <= s.size.Y - margin + 1 then "fits, body scrolls" else "TOO BIG"))
		end
	end
	local ratio, tool = PokeController.restingContrast()
	if ratio < 6 then
		problems += 1
	end
	table.insert(lines, string.format("resting slabs: white text at least %.1f:1 on the lightest part of every face (lowest: %s)", ratio, tool))
	-- Round 3, M5 fix 1: the monitor's body map has a place for every wound zone (a severed arm's
	-- stump at its shoulder, not its neck), and the alarm sounds only while the monitor is up, a
	-- stopped heart a few times, never for ever.
	do
		local HospitalCharts = require(script.Parent:WaitForChild("HospitalCharts")) :: any
		local Anatomy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anatomy")) :: any
		local missing = {}
		for id in Anatomy.zones do
			if not HospitalCharts.MAP_POINT[id] then
				table.insert(missing, id)
			end
		end
		local neck = HospitalCharts.MAP_POINT.Neck
		local stumpOk = neck ~= nil
		for _, id in { "LeftArmStump", "RightArmStump" } do
			local stump = HospitalCharts.MAP_POINT[id]
			stumpOk = stumpOk and stump ~= nil and (stump - neck).Magnitude > 6
		end
		-- The rhythm line on the narrowest monitor (a phone): every short form fits its label (60% of
		-- the strip, 12 px; a clinical note goes on the findings line there).
		local longest, longestW = "", 0
		local narrowest = math.huge
		for _, s in LayoutCheck.SCREENS do
			if s.touch and math.min(s.size.X, s.size.Y) <= 500 then
				for _, lab in { false, true } do
					local p = HospitalCharts.plan(s.size, s.touch, lab)
					local strip = p.size.X - 16 - (if p.wide then 96 else 74) - 6 - p.body
					narrowest = math.min(narrowest, strip * 0.6 - 6)
				end
			end
		end
		local short = HospitalCharts.SHORT_RHYTHM
		for _, line in { "Sinus rhythm", short["Sinus tachycardia"], short["Sinus bradycardia"], short["Ventricular fibrillation"], "Asystole" } do
			local params = Instance.new("GetTextBoundsParams")
			params.Text = line
			params.Font = Theme.Fonts.bodySemi
			params.Size = 12
			params.Width = 100000
			local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
			local wpx = if ok then bounds.X else #line * 7
			if wpx > longestW then
				longest, longestW = line, wpx
			end
		end
		local rhythmFits = longestW <= narrowest
		if not rhythmFits then
			problems += 1
		end
		table.insert(lines, string.format("monitor rhythm line on the narrowest phone: \"%s\" %d px of %d: %s", longest, longestW, narrowest, if rhythmFits then "fits" else "CUT"))
		local quiet = HospitalCharts.alarmGap("Critical", false, 0) == nil
		local deadStops = HospitalCharts.alarmGap("Dead", true, HospitalCharts.DEAD_ALARMS) == nil and HospitalCharts.alarmGap("Dead", true, 0) ~= nil
		local stableQuiet = HospitalCharts.alarmGap("Stable", true, 0) == nil
		if #missing > 0 or not stumpOk or not quiet or not deadStops or not stableQuiet then
			problems += 1
		end
		table.sort(missing)
		table.insert(lines, string.format("monitor: body map %s; arm stump %s; alarm %s under a replay, a stopped heart %d times then quiet: %s",
			if #missing == 0 then "has every zone" else "MISSING " .. table.concat(missing, ", "),
			if stumpOk then "at the shoulder" else "NOT AT THE SHOULDER",
			if quiet then "silent" else "SOUNDS", HospitalCharts.DEAD_ALARMS, if deadStops and stableQuiet then "ok" else "WRONG"))
	end
	-- Round 3, M6: SETTINGS' UI SIZE (the kit's player scale) at its largest and smallest: the left
	-- edge's launchers against everything else on every screen, view and bar state.
	do
		local Settings = require(script.Parent:WaitForChild("Settings")) :: any
		local saved = Controller.getPlayerScale()
		local hits = {}
		for _, choice in Settings.UI do
			Controller.setPlayerScale(choice.scale)
			for _, s in LayoutCheck.SCREENS do
				for _, lab in { false, true } do
					for _, withTools in { false, true } do
						local all = LayoutCheck.scene(s, lab, withTools)
						for _, a in all do
							if a.name == "Launcher" then
								for _, b in all do
									if b ~= a and not (NEVER_TOGETHER[a.name] and NEVER_TOGETHER[a.name][b.name]) and overlap(a, b) then
										table.insert(hits, string.format("%s %s %s: Launcher/%s", choice.name, s.name, if lab then "lab" else "player", b.name))
									end
								end
							end
						end
					end
				end
			end
		end
		Controller.setPlayerScale(saved)
		problems += #hits
		table.insert(lines, if #hits == 0 then "UI size SMALL / NORMAL / LARGE: the launchers clear of everything on every screen" else "UI size: " .. table.concat(hits, "; "))
	end
	if KitStyle.V2 then
		problems += LayoutCheck.uiV2(lines, widthOf, boldWidthOf)
	end
	table.insert(lines, string.format("%d problems (overlaps with outlines and a 4 px gap, taps under 44 px, off screen, toast text, catalog fit, contrast)", problems))
	return table.concat(lines, "\n")
end

---------------------------------------------------------------------------------------------------
-- UI v2 (Config.UI_V2): the look's own rules, measured.
--   * every kit text style draws 14 px or more at the touch scale floor (Theme.MinDrawnText)
--   * every role's text on its face: 4.5:1, or 3:1 with its ink outline
--   * every rarity colour against the navy card: 3:1 (and the tag's word on it: 4.5:1)
--   * every HUD and MENU icon the v2 look names is a drawn icon (not the emoji fallback)
--   * the weapon card's stat names, value and rarity tags fit their boxes at their floor
--   * a portrait phone's first minute shows at most 7 of our things (Roblox's stick and jump aside)
--   * the level badge's number and the HUD's icon buttons keep 14 px words
LayoutCheck.FIRST_MINUTE_MAX = 7

local function luminance(c: Color3): number
	local function lin(v: number): number
		return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
end
function LayoutCheck.contrast(a: Color3, b: Color3): number
	local x, y = luminance(a), luminance(b)
	return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end

-- A portrait phone, the player view, the first QUIET_START s: what shows (bar = one group).
function LayoutCheck.firstMinuteNames(screen: Vector2): { string }
	local ctx = ctxOf(screen, true, false)
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	local HudMenu = require(script.Parent:WaitForChild("HudMenu")) :: any
	local shown = {}
	-- (The G17 is picked: SHOOT shows, GRAB / THROW / ZOOM do not; BUILD lives in MENU on a phone;
	-- the chaos meter waits for a prop; the replay button for a replay; the WEAPONS button gives
	-- its place to the experiment card, which waits out the first minute.)
	for _, name in { "Ragdoll", "Shoot", "View", "Sprint" } do
		if HudSlots.shownNow(name, ctx, 0, Config.QUIET_START) then
			table.insert(shown, name)
		end
	end
	if not (ctx.phone and Config.PHONE_HUD_MAX7) then
		table.insert(shown, "Weapons")
	end
	table.insert(shown, "Bar")
	table.insert(shown, "Hint")
	for launcher in (if ctx.phone then HudMenu.PHONE_KEEP else HudMenu.KEEP) do
		table.insert(shown, "Launcher:" .. launcher)
	end
	table.insert(shown, "Launcher:Menu")
	if not (KitStyle.V2 and ctx.phone) then
		table.insert(shown, "Level") -- (UI v2: a phone's level badge waits out the quiet start)
	end
	return shown
end

function LayoutCheck.uiV2(lines: { string }, widthOf: (string, number) -> number, boldWidthOf: (string, number) -> number): number
	local problems = 0
	local S = Theme.Size
	local floorScale = S.touchDrawnMin / S.touchMin
	-- Text styles at the touch floor.
	local small = {}
	for name, spec in Theme.Text do
		local drawn = spec.size * floorScale
		if drawn < Theme.MinDrawnText then
			problems += 1
			table.insert(small, string.format("%s %.1f", name, drawn))
		end
	end
	local floorDrawn = Theme.MinTextSize * floorScale
	if floorDrawn < Theme.MinDrawnText then
		problems += 1
	end
	table.insert(lines, string.format("UI v2 text: every kit style and the fitted floor (%d units = %.1f px) at the touch scale %.2f: %s",
		Theme.MinTextSize, floorDrawn, floorScale, if #small == 0 and floorDrawn >= Theme.MinDrawnText then "14 px or more" else "UNDER: " .. table.concat(small, ", ")))
	-- Role contrast (text on the face's bottom colour; a stroked text needs 3:1).
	local weak = {}
	for name, role in Theme.Roles do
		local need = if role.textStroke then 3 else 4.5
		local ratio = LayoutCheck.contrast(role.text, role.bottom)
		if ratio < need then
			problems += 1
			table.insert(weak, string.format("%s %.1f", name, ratio))
		end
	end
	table.insert(lines, "UI v2 roles: text on every button face " .. (if #weak == 0 then "reads (4.5:1, or 3:1 outlined)" else "TOO WEAK: " .. table.concat(weak, ", ")))
	-- Rarity colours.
	local card = Theme.Palette.duskRaised
	local rare = {}
	for _, r in UiRarity.LIST do
		local onCard = LayoutCheck.contrast(r.color, card)
		local word = if KitStyle.tagInk(r.color) then Theme.Palette.ink else Color3.new(1, 1, 1)
		local tag = LayoutCheck.contrast(word, r.color)
		if onCard < 3 or tag < 4.5 then
			problems += 1
			table.insert(rare, string.format("%s %.1f/%.1f", r.label, onCard, tag))
		end
		local w = widthOf(r.label, 17) + 16
		if w > ToolCatalog.CARD.X - 24 - 8 then
			problems += 1
			table.insert(rare, r.label .. " tag too wide")
		end
	end
	table.insert(lines, "UI v2 rarity: colours on the card (3:1) and their tags' words (4.5:1) " .. (if #rare == 0 then "read" else "FAIL: " .. table.concat(rare, ", ")))
	-- Drawn icons for the v2 look's names.
	local Icons = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIIcons")) :: any
	local HudMenu = require(script.Parent:WaitForChild("HudMenu")) :: any
	local missing = {}
	for _, name in KitStyle.HUD_ICONS do
		if not Icons.has(name) then
			table.insert(missing, name)
		end
	end
	for _, name in HudMenu.ICONS do
		if not Icons.has(name) then
			table.insert(missing, name)
		end
	end
	problems += #missing
	table.insert(lines, "UI v2 icons: HUD buttons and MENU entries " .. (if #missing == 0 then "all drawn (DrawnIcons)" else "EMOJI FALLBACK: " .. table.concat(missing, ", ")))
	-- The weapon card's stat row: names at their floor in 70 units (with 15 % room: the rendered bold
	-- face runs wider than the measure; V5 found POWER cut at 62), the value in 22.
	local statOk = widthOf("POWER", Theme.MinTextSize) * 1.15 <= 70 and widthOf("SPEED", Theme.MinTextSize) * 1.15 <= 70 and widthOf("CHAOS", Theme.MinTextSize) * 1.15 <= 70 and widthOf("10", Theme.MinTextSize) <= 22
	if not statOk then
		problems += 1
	end
	table.insert(lines, string.format("UI v2 weapon cards: POWER %d / CHAOS %d units (+15%%) of 70, \"10\" %d of 22 at %d: %s", widthOf("POWER", Theme.MinTextSize), widthOf("CHAOS", Theme.MinTextSize), widthOf("10", Theme.MinTextSize), Theme.MinTextSize, if statOk then "fit" else "TOO WIDE"))
	-- HUD icon buttons: the word beside (LAB VIEW, RAGDOLL) or under (BUILD, GRAB, THROW, RUN, SHOOT)
	-- its icon keeps 14 px.
	local tight = {}
	local function room(name: string, word: string, placement: string, w: number, h: number)
		local px = if placement == "top" then math.floor(math.min(w, h) * 0.38) else math.floor(math.min(h - 14, Theme.IconSize.sm - 2))
		local roomW = if placement == "top" then w - 6 else w - (px + 10) - 8
		local roomH = if placement == "top" then h - (px + 2) - 4 else h - 10
		local needW = widthOf(word, 14)
		if needW > roomW * 2 or roomH < 14 or (needW > roomW and roomH < 2 * 14 * 1.15) then
			table.insert(tight, string.format("%s %dx%d", name, roomW, roomH))
		end
	end
	for _, sc in LayoutCheck.SCREENS do
		local ctx = ctxOf(sc.size, sc.touch, false)
		local function slotSize(n: string): Vector2
			local _, size = HudSlots.rect(n, ctx, sc.size)
			return size
		end
		local v, r = slotSize("View"), slotSize("Ragdoll")
		room("LAB VIEW", "LAB VIEW", "left", v.X, v.Y)
		room("RAGDOLL", "RAGDOLL", "top", r.X, r.Y)
		if sc.touch then
			local g, t, run, sh = slotSize("Grab"), slotSize("Throw"), slotSize("Sprint"), slotSize("Shoot")
			room("GRAB", "GRAB", "top", g.X, g.Y)
			room("THROW", "THROW", "top", t.X, t.Y)
			room("RUN", "RUN", "top", run.X, run.Y)
			room("SHOOT", "SHOOT", "top", sh.X, sh.Y)
		end
	end
	problems += #tight
	table.insert(lines, "UI v2 HUD icon buttons: words at 14 px beside or under their icons " .. (if #tight == 0 then "fit on every screen" else "TIGHT: " .. table.concat(tight, "; ")))
	-- The level badge.
	local HudPlus = require(script.Parent:WaitForChild("HudPlus")) :: any
	local levelText = HudPlus.LEVEL_BADGE * 0.76
	if levelText < 14 then
		problems += 1
	end
	table.insert(lines, string.format("UI v2 level badge: %d px, its number up to %.0f px: %s", HudPlus.LEVEL_BADGE, levelText, if levelText >= 14 then "readable" else "TOO SMALL"))
	-- The first minute on an upright phone.
	for _, sc in LayoutCheck.SCREENS do
		if sc.touch and sc.size.Y > sc.size.X then
			local names = LayoutCheck.firstMinuteNames(sc.size)
			if #names > LayoutCheck.FIRST_MINUTE_MAX then
				problems += 1
			end
			table.insert(lines, string.format("%-18s first minute: %d things (%s): %s", sc.name, #names, table.concat(names, ", "),
				if #names <= LayoutCheck.FIRST_MINUTE_MAX then "at most " .. LayoutCheck.FIRST_MINUTE_MAX else "TOO MANY"))
		end
	end
	local _ = boldWidthOf
	return problems
end

-- The live screen's words (UI v2): every visible text on our layers, drawn size against the
-- 14 px floor (a fitted text: its drawn bounds), and any that does not fit its box. Run with the
-- screens open that should be checked (the catalog, SHOP, MENU...). Roblox's own guis are skipped.
function LayoutCheck.textLive(): string
	local lines = {}
	local problems = 0
	local seen = 0
	for _, object in Players.LocalPlayer.PlayerGui:GetDescendants() do
		if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) and object.Text ~= "" then
			local gui = object:FindFirstAncestorWhichIsA("LayerCollector")
			local visible = gui ~= nil and (not gui:IsA("ScreenGui") or gui.Enabled)
			local a: Instance? = object
			while visible and a and a ~= gui do
				if a:IsA("GuiObject") and not a.Visible then
					visible = false
				end
				a = a.Parent
			end
			local hidden = object:GetAttribute("KitFitOrHide") == true and object.TextTransparency >= 1
			if visible and not hidden and object.TextTransparency < 1 and object.AbsoluteSize.Y > 0 then
				seen += 1
				local lineCount = math.max(1, math.floor(object.TextBounds.Y / math.max(1, object.TextSize * 1.1) + 0.5))
				local drawn = if object.TextScaled then object.TextBounds.Y / lineCount else object.TextSize * (object.AbsoluteSize.Y / math.max(1, object.Size.Y.Offset))
				if object.Size.Y.Offset == 0 and not object.TextScaled then
					drawn = object.TextSize
				end
				local cut = not object.TextFits
				if drawn < 13.5 or cut then
					problems += 1
					table.insert(lines, string.format("%s: %s%s \"%s\"", object:GetFullName(), if drawn < 13.5 then string.format("%.1f px ", drawn) else "", if cut then "DOES NOT FIT" else "", string.sub(object.Text, 1, 32)))
				end
			end
		end
	end
	table.insert(lines, string.format("%d texts on screen, %d under 14 px or not fitting", seen, problems))
	return table.concat(lines, "\n")
end

-- The catalog on phones, measured: with the Tools window open (on any screen), switches the cards
-- to the phone layout, reads how far down the first row's EQUIP ends (in design units, from the
-- window's top), and compares that with how much of the window each phone shows.
function LayoutCheck.catalogLive(): string
	local layer = Players.LocalPlayer.PlayerGui:FindFirstChild("LihFolkUI")
	local root = layer and layer:FindFirstChild("Tools", true)
	if not root or not root:IsA("GuiObject") then
		return "no Tools window"
	end
	local was = root:GetAttribute("Compact")
	root:SetAttribute("Compact", true) -- ToolCatalog switches the cards to the phone layout
	task.wait(0.3)
	local pxPerUnit = root.AbsoluteSize.Y / root.Size.Y.Offset
	local deepest = 0
	local found = 0
	for _, d in root:GetDescendants() do
		if d.Name == "Equip" and d:IsA("GuiObject") and d.AbsoluteSize.X > 0 then
			local visible = true
			local a: Instance? = d
			while a and a ~= root do
				if a:IsA("GuiObject") and not a.Visible then
					visible = false
				end
				a = a.Parent
			end
			local top = (d.AbsolutePosition.Y - root.AbsolutePosition.Y) / pxPerUnit
			if visible and top < 400 then -- the first row
				found += 1
				deepest = math.max(deepest, top + d.AbsoluteSize.Y / pxPerUnit)
			end
		end
	end
	root:SetAttribute("Compact", was)
	if found == 0 then
		return "open the Tools window first"
	end
	local lines = { string.format("phone layout: first row's EQUIP ends %d design units below the window top (%d buttons)", deepest, found) }
	local problems = if found == 0 then 1 else 0
	local size = Theme.Size
	for _, s in LayoutCheck.SCREENS do
		if s.touch and math.min(s.size.X, s.size.Y) <= 500 then
			local margin = (size.screenMargin or 16) * 2
			local scale = math.max(math.min(1, (s.size.Y - margin) / 780), size.touchDrawnMin / size.touchMin)
			local shown = math.min(780, (s.size.Y - margin) / scale)
			local ok = deepest + 12 <= shown
			if not ok then
				problems += 1
			end
			table.insert(lines, string.format("%-18s window shows %d units: EQUIP %s", s.name, shown, if ok then "visible without scrolling" else "BELOW THE FOLD"))
		end
	end
	table.insert(lines, string.format("%d catalog problems", problems))
	return table.concat(lines, "\n")
end

-- The live screen: every control HudSlots placed, and the tool bar, where they really are now
-- (AbsolutePosition and AbsoluteSize, inside their ScreenGui) against where their slot or the bar
-- plan says, and every visible pair checked for overlap.
function LayoutCheck.live(): string
	local lines = {}
	local rects: { Rect } = {}
	local problems = 0
	local viewport = workspace.CurrentCamera.ViewportSize
	local phone = math.min(viewport.X, viewport.Y) <= 500
	for _, object in Players.LocalPlayer.PlayerGui:GetDescendants() do
		local name = object:GetAttribute("HudSlot")
		local gui = object:FindFirstAncestorWhichIsA("LayerCollector")
		if type(name) == "string" and object:IsA("GuiObject") and gui and gui:IsA("ScreenGui") and gui.Enabled and object.Visible then
			local at = object.AbsolutePosition - gui.AbsolutePosition
			local size = object.AbsoluteSize
			local wantAt, wantSize = HudSlots.rect(name, { touch = false, lab = false, phone = phone }, gui.AbsoluteSize)
			local off = math.max((at - wantAt).Magnitude, (size - wantSize).Magnitude)
			if off > 2 then
				problems += 1
			end
			table.insert(rects, { x = at.X, y = at.Y, w = size.X, h = size.Y, name = name })
			table.insert(lines, string.format("%-9s live %d,%d %dx%d  slot %d,%d %dx%d  %s", name, at.X, at.Y, size.X, size.Y,
				wantAt.X, wantAt.Y, wantSize.X, wantSize.Y, if off > 2 then "MOVED" else "ok"))
		end
	end
	local barGui = Players.LocalPlayer.PlayerGui:FindFirstChild("ToyBar")
	local bar = barGui and barGui:FindFirstChild("Bar")
	if bar and bar:IsA("GuiObject") and barGui:IsA("ScreenGui") and barGui.Enabled and bar.Visible then
		local at = bar.AbsolutePosition - barGui.AbsolutePosition
		table.insert(rects, { x = at.X, y = at.Y, w = bar.AbsoluteSize.X, h = bar.AbsoluteSize.Y, name = "Bar" })
		local plan = PokeController.plan(barGui.AbsoluteSize, bar:GetAttribute("Touch") == true, bar:GetAttribute("Lab") == true,
			bar:GetAttribute("WithTools") == true, (bar:GetAttribute("Count") :: number?) or Toys.SLOTS, bar:GetAttribute("Upcoming") :: number?)
		local want = Vector2.new((barGui.AbsoluteSize.X - plan.size.X) / 2, barGui.AbsoluteSize.Y - plan.bottom - plan.size.Y)
		local off = math.max((at - want).Magnitude, (bar.AbsoluteSize - plan.size).Magnitude)
		if off > 2 then
			problems += 1
		end
		table.insert(lines, string.format("Bar       live %d,%d %dx%d  plan %d,%d %dx%d  %s", at.X, at.Y, bar.AbsoluteSize.X, bar.AbsoluteSize.Y,
			want.X, want.Y, plan.size.X, plan.size.Y, if off > 2 then "MOVED" else "ok"))
	end
	for i = 1, #rects do
		for k = i + 1, #rects do
			if overlap(rects[i], rects[k]) then
				problems += 1
				table.insert(lines, "overlap " .. rects[i].name .. "/" .. rects[k].name)
			end
		end
	end
	table.insert(lines, string.format("%d live problems", problems))
	return table.concat(lines, "\n")
end

return LayoutCheck
