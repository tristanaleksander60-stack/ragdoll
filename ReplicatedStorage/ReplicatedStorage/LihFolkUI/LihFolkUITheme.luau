--!strict
--[[
	LihFolkUITheme
	Design tokens for LihFolk UI: palette, button roles, per-menu header themes,
	type scale, spacing, radii, strokes, sizes, motion and sound slots.

	Look (Ragdoll Lab, round 2 N5): "Dark glass", after the big ragdoll games. Near-black
	panels you can just see through, thin black outlines, square corners, white bold
	Builder Sans; colour only where it means something (green = do it, gold = Robux,
	red = close). Built on the LihFolk "Ink and Candy" kit: the same components and
	rules, its tokens retuned here.

	Every other LihFolk UI module reads from here. Change a value here, never inline.
	All sizes are DESIGN UNITS: pixels at a UIScale of 1. The controller scales them.

	License: LihFolk. Free to use and modify in your games. Docs are CC BY 4.0.
]]

local GuiService = game:GetService("GuiService")

local Theme = {}

export type RoleName = "go" | "neutral" | "premium" | "danger" | "info" | "done" | "locked" | "accent"
export type ThemeName = "shop" | "codes" | "rebirth" | "settings" | "daily" | "neutral"
export type TextStyleName = "display" | "title" | "button" | "number" | "small" | "body" | "caption"

-- A tactile surface: gradient face (top -> bottom), the darker "lip" under it,
-- and the text colour / outline that reads on it.
export type Swatch = {
	top: Color3,
	bottom: Color3,
	shade: Color3,
	text: Color3,
	textStroke: Color3?, -- nil = no outline on this surface
}

export type TextStyle = {
	font: Font,
	size: number,
	stroke: number, -- outline thickness in design px, 0 = none
}

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

---------------------------------------------------------------------------
-- Palette (raw colours). Names describe the colour, not the use.
---------------------------------------------------------------------------
Theme.Palette = {
	ink = hex("#050608"), -- outlines, text strokes, the darkest value in the kit
	dusk = hex("#16181D"), -- panel canvas (drawn a little see-through: Theme.Glass)
	duskRaised = hex("#20232A"), -- cards on the canvas
	duskRaisedHi = hex("#2A2E37"), -- top of a card's gradient
	duskSunken = hex("#0D0F12"), -- recessed tracks and text fields
	line = hex("#3A3F4A"), -- dividers on the canvas
	textHi = hex("#FFFFFF"), -- titles and primary text (17.6:1 on dusk)
	textMid = hex("#DADDE3"), -- body text (13.5:1 on dusk)
	textLow = hex("#A9AFBA"), -- captions, placeholders (8.2:1 on dusk)
	positive = hex("#7BF5A6"), -- success messages on dark surfaces
	negative = hex("#FF8FA8"), -- error messages on dark surfaces
	backdrop = hex("#000000"), -- modal dimmer
	white = hex("#FFFFFF"),
	gold = hex("#FFD24A"), -- featured outlines, sunburst
	-- HUD pieces (round 2, N5)
	slab = hex("#2B2F38"), -- a plain HUD button's face (LAB VIEW, RAGDOLL, the build rail)
	go = hex("#23B262"), -- a HUD button that is on, or the one thing to press (PLAY, a picked tool)
	stageTop = hex("#3A3F4B"), -- the lit well a weapon's 3D model stands on (catalog cards)
	stageBottom = hex("#1E2128"),
	helpText = hex("#E2E5EB"), -- the help line and the mouse help's words
	helpLow = hex("#BEC4CE"), -- the mouse help's second line
}

-- How see-through the dark surfaces are (0 = solid). Text on them keeps its contrast: the
-- world behind is darkened by the panel's own colour first.
Theme.Glass = {
	panel = 0.12,
	card = 0.15,
}
Theme.Bands = false -- the kit's diagonal candy bands: off in the dark-glass look

---------------------------------------------------------------------------
-- Button roles. Every interactive slab uses exactly one role.
-- Roles differ in LIGHTNESS and carry a glyph or word, never colour alone.
---------------------------------------------------------------------------
local ROLES: { [RoleName]: Swatch } = {
	go = { -- claim, buy, confirm, the one primary action on a screen
		top = hex("#5FE08F"),
		bottom = hex("#23B262"),
		shade = hex("#0F6B3A"),
		text = hex("#FFFFFF"),
		textStroke = hex("#050608"),
	},
	neutral = { -- secondary actions, tabs, back: dark glass
		top = hex("#3D424D"),
		bottom = hex("#2B2F38"),
		shade = hex("#121419"),
		text = hex("#FFFFFF"),
		textStroke = hex("#050608"),
	},
	premium = { -- Robux, skip, paid boosts
		top = hex("#FFD95A"),
		bottom = hex("#F5A623"),
		shade = hex("#9A5A00"),
		text = hex("#FFFFFF"),
		textStroke = hex("#050608"),
	},
	danger = { -- close, destructive, reset
		top = hex("#F2556F"),
		bottom = hex("#C92A48"),
		shade = hex("#7A1229"),
		text = hex("#FFFFFF"),
		textStroke = hex("#050608"),
	},
	info = { -- help, header actions, links
		top = hex("#5AB4FF"),
		bottom = hex("#2F7FE0"),
		shade = hex("#184C94"),
		text = hex("#FFFFFF"),
		textStroke = hex("#050608"),
	},
	done = { -- claimed, owned, equipped: pale, quiet, not interactive
		top = hex("#E6E8EC"),
		bottom = hex("#BFC4CC"),
		shade = hex("#7C828C"),
		text = hex("#16181D"),
		textStroke = nil,
	},
	accent = { -- UI v2: the game's own colour (havoc orange), for the one hero action
		top = hex("#FF9A4D"),
		bottom = hex("#F2621F"),
		shade = hex("#8F2C05"),
		text = hex("#FFFFFF"),
		textStroke = hex("#050608"),
	},
	locked = { -- not yet available: the darkest slab (white, stroked text: still readable)
		top = hex("#2E323B"),
		bottom = hex("#22252C"),
		shade = hex("#0F1114"),
		text = hex("#E2E5EA"),
		textStroke = hex("#050608"),
	},
}
Theme.Roles = ROLES

---------------------------------------------------------------------------
-- Menu header themes. Each menu owns one colour identity; the body stays dusk
-- so every menu still reads as the same family.
---------------------------------------------------------------------------
-- Dark glass: every header is the dark slab with a faint tint of its menu's own colour (so each
-- menu still has an identity); the full colour is kept for accents (Theme.Accents).
local DARK_TOP, DARK_BOTTOM, DARK_SHADE = hex("#2A2E37"), hex("#1C1F25"), hex("#0B0C0F")
local function header(color: string): Swatch
	local c = hex(color)
	return { top = DARK_TOP:Lerp(c, 0.18), bottom = DARK_BOTTOM:Lerp(c, 0.1), shade = DARK_SHADE, text = hex("#FFFFFF"), textStroke = hex("#050608") }
end
local MENUS: { [ThemeName]: Swatch } = {
	shop = header("#FF7B22"), -- Tangerine
	codes = header("#18B5C6"), -- Lagoon
	rebirth = header("#9257F2"), -- Orchid
	settings = header("#4F7BEA"), -- Denim
	daily = header("#F25AA2"), -- Bubblegum
	neutral = header("#6E66B3"), -- Lilac
}
Theme.Accents = {
	shop = hex("#FF9A3D"),
	codes = hex("#2FD0D8"),
	rebirth = hex("#B07BFF"),
	settings = hex("#6F98FF"),
	daily = hex("#FF79BC"),
	neutral = hex("#9C94DB"),
}
Theme.Menus = MENUS

---------------------------------------------------------------------------
-- Typography. Two families only.
--   Display: Builder Sans Heavy (Roblox's own face, bold and plain: the dark-glass look; built
--   in, so no download). Fredoka One was the "Ink and Candy" display face.
--   Body:    Builder Sans (Roblox's own UI face; wide language coverage).
-- Outline ratio: about 9 to 10 percent of the text size, round joins.
---------------------------------------------------------------------------
Theme.Fonts = {
	display = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
	body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	bodySemi = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
}

local TEXT: { [TextStyleName]: TextStyle } = {
	display = { font = Theme.Fonts.display, size = 34, stroke = 2 }, -- window titles
	title = { font = Theme.Fonts.display, size = 24, stroke = 1.5 }, -- section headers, card titles
	button = { font = Theme.Fonts.display, size = 22, stroke = 1.5 }, -- button captions
	number = { font = Theme.Fonts.display, size = 28, stroke = 1.5 }, -- amounts, prices, multipliers
	small = { font = Theme.Fonts.display, size = 17, stroke = 1.2 }, -- pills, bar labels, day tags
	body = { font = Theme.Fonts.body, size = 18, stroke = 0 }, -- descriptions
	caption = { font = Theme.Fonts.bodySemi, size = 15, stroke = 0 }, -- hints, timers (never under 12 px drawn)
}
Theme.Text = TEXT

Theme.MinDrawnText = 12 -- hard floor in real pixels after scaling
Theme.MinTextSize = 15 -- design units; 15 x the 0.85 touch scale floor still draws about 12.7 px

---------------------------------------------------------------------------
-- Spacing (4-point steps), radii, stroke widths, component sizes
---------------------------------------------------------------------------
Theme.Space = { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 }

-- Nested radius rule: inner radius = outer radius - gap between them.
Theme.Radius = {
	panel = 10,
	header = 6, -- panel 10 minus the 4 px of its inset that shows
	card = 8,
	button = 6, -- square-ish buttons (dark glass)
	input = 6,
	pill = UDim.new(0.5, 0), -- fully round ends
}

Theme.Stroke = {
	panel = 2,
	card = 1.5,
	button = 2,
	input = 1.5,
	focus = 3,
	divider = 1.5,
}

Theme.Size = {
	touchMin = 52, -- smallest tappable box in design units; drawn >= 44 px on phones
	touchDrawnMin = 44, -- real pixels; the controller never scales touch UI below this
	buttonH = 56,
	depth = 4, -- tactile lip under a slab (flatter in dark glass)
	depthSmall = 3,
	headerH = 72, -- header slab including its lip
	headerInset = 8,
	close = 52,
	iconSm = 28,
	iconMd = 48,
	iconLg = 72,
	toggleW = 84,
	toggleH = 40,
	progressH = 30,
	inputH = 56,
	window = Vector2.new(760, 520), -- default window, design units
	screenMargin = 16, -- gap kept between a window and the safe-area edge
	hudButton = 64,
}

---------------------------------------------------------------------------
-- Motion. All UI tweens take their numbers from here.
---------------------------------------------------------------------------
Theme.Motion = {
	openTime = 0.22,
	openFrom = 0.86, -- window scale when it starts to open
	openStyle = Enum.EasingStyle.Back,
	openDirection = Enum.EasingDirection.Out,
	closeTime = 0.12,
	closeTo = 0.9,
	closeStyle = Enum.EasingStyle.Quad,
	closeDirection = Enum.EasingDirection.In,
	dimTime = 0.18,
	dimTransparency = 0.45, -- backdrop at rest when a menu is open
	hoverScale = 1.04,
	hoverTime = 0.1,
	pressScale = 0.96,
	pressTime = 0.05,
	releaseTime = 0.16,
	fillTime = 0.35, -- progress bars
	toggleTime = 0.16,
	glowTime = 0.8, -- claimable glow breathing half-period
	nudgeTime = 0.6, -- tier arrow nudge half-period
	sunburstPeriod = 16, -- seconds per full turn
	staggerStep = 0.04,
	shakeStep = 0.04,
	-- Shared by every hand-built piece (KitStyle.pop / press / countUp read these).
	popFrom = 0.6, -- scale a pop starts at
	popTime = 0.28,
	countTime = 0.55, -- a number counting up to its new value
	countTimeMax = 1.1,
}

-- Optional sound slots. Empty = silent. Fill with YOUR uploaded audio ids,
-- as "rbxassetid://<your id>". Never ship ids you have not checked.
-- Ragdoll Lab: Roblox-licensed Pro Sound Effects from the Creator Store.
local SOUNDS: { [string]: string } = {
	click = "rbxassetid://9119717523", -- Switch Click On Or Off Toggle Button 2
	hover = "", -- left silent
	open = "rbxassetid://9126045906", -- Synth Air Whoosh Cheesy Karate Style Swishes 3
	close = "rbxassetid://9126045906", -- the same swish as open
	success = "rbxassetid://9116421550", -- Magic Transformation 6 (a bouncy boink)
	error = "", -- left silent
}
Theme.Sounds = SOUNDS

-- Icon sizes (design units) and the drop shadow under raised surfaces (UI v2 turns it on).
Theme.IconSize = { xs = 20, sm = 28, md = 40, lg = 56, xl = 72 }
Theme.Shadow = { enabled = false, offset = 5, transparency = 0.55, color = Theme.Palette.ink }
-- The gamepad / keyboard focus ring.
Theme.Focus = { color = Theme.Palette.white, thickness = 3, grow = 10 }

---------------------------------------------------------------------------
-- UI v2 (Config.UI_V2, 19 Nov 2026): "Havoc". The same components and rules, retuned: a deep navy
-- canvas instead of grey glass, the game's own havoc orange as the accent, livelier role colours,
-- Fredoka One for titles and buttons with Builder Sans for the rest, rounder corners, solid
-- surfaces with a drop shadow, a 0.92 press squish, and a text floor that draws 14 px on a phone
-- (17 design units x the 0.85 touch floor). Everything is a token change: switch UI_V2 off and the
-- dark-glass look above comes back untouched.
---------------------------------------------------------------------------
local function uiV2(): boolean
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	-- (Replicated before any script runs; the short waits only guard a slow join.)
	local shared = ReplicatedStorage:WaitForChild("Shared", 5)
	local config = shared and shared:WaitForChild("Config", 5)
	if not config or not config:IsA("ModuleScript") then
		return false
	end
	local ok, value = pcall(function(): any
		return (require(config) :: any).UI_V2
	end)
	return ok and value == true
end
Theme.V2 = uiV2()

if Theme.V2 then
	local Pa = Theme.Palette :: any
	Pa.ink = hex("#090A14")
	Pa.dusk = hex("#141A2C") -- navy canvas (15.9:1 under white text)
	Pa.duskRaised = hex("#1C2440")
	Pa.duskRaisedHi = hex("#283357")
	Pa.duskSunken = hex("#0A0E1B")
	Pa.line = hex("#35426C")
	Pa.textMid = hex("#DDE4F5") -- 13.1:1 on the canvas
	Pa.textLow = hex("#AEB8D3") -- 8.0:1
	Pa.gold = hex("#FFC83D")
	Pa.slab = hex("#1E2742")
	Pa.go = hex("#1DB857")
	Pa.stageTop = hex("#2D3A68")
	Pa.stageBottom = hex("#141A30")
	Pa.accent = hex("#FF6A26") -- havoc orange: the game's own colour
	Pa.accentHi = hex("#FFA25A")
	Pa.focus = hex("#FFE15C") -- the gamepad ring (bright on every surface)

	local function set(name: RoleName, top: string, bottom: string, shade: string, text: string?, stroke: string?)
		ROLES[name] = {
			top = hex(top),
			bottom = hex(bottom),
			shade = hex(shade),
			text = hex(text or "#FFFFFF"),
			textStroke = if stroke == "none" then nil else hex(stroke or "#090A14"),
		}
	end
	set("go", "#62F29F", "#13A04C", "#0A6630") -- (bottom #17B054 gave white 2.8:1; 3:1 needed with the stroke: PC LayoutCheck 19 Nov)
	set("neutral", "#35416C", "#232C4B", "#0C1022")
	set("premium", "#FFE27A", "#FFB120", "#9E5A00", "#141A2C", "none") -- (ink on gold: white was 1.8:1)
	set("danger", "#FF6E84", "#E0284F", "#7C0E27")
	set("info", "#55D6FF", "#1F8EEA", "#0D4A8A")
	set("done", "#E9EEF8", "#C4CCDD", "#7D8699", "#141A2C", "none")
	set("locked", "#2B3352", "#1D243C", "#0A0E1C", "#DDE4F5")
	set("accent", "#FFA25A", "#F2621F", "#8F2C05")

	-- Headers: the navy slab with a clear tint of the menu's own colour (identity at a glance).
	local top, bottom, shade = hex("#2A3459"), hex("#1A2140"), hex("#090C18")
	for name, color in Theme.Accents :: any do
		MENUS[name :: ThemeName] = {
			top = top:Lerp(color, 0.32),
			bottom = bottom:Lerp(color, 0.2),
			shade = shade,
			text = hex("#FFFFFF"),
			textStroke = hex("#090A14"),
		}
	end

	Theme.Glass.panel = 0.04 -- (solid surfaces read as finished; the backdrop dims the world)
	Theme.Glass.card = 0.05

	local Fo = Theme.Fonts :: any
	Fo.display = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	Fo.body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	Fo.bodySemi = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	-- (Fredoka One is round and heavy: outlines at about 6 percent, so 0, a and e keep their holes.)
	local TX = TEXT :: any
	TX.display = { font = Fo.display, size = 36, stroke = 2 }
	TX.title = { font = Fo.display, size = 25, stroke = 1.5 }
	TX.button = { font = Fo.display, size = 23, stroke = 1.5 }
	TX.number = { font = Fo.display, size = 28, stroke = 1.5 }
	TX.small = { font = Fo.display, size = 18, stroke = 1 }
	TX.body = { font = Fo.body, size = 19, stroke = 0 }
	TX.caption = { font = Fo.bodySemi, size = 17, stroke = 0 }
	Theme.MinDrawnText = 14
	Theme.MinTextSize = 17 -- x the 0.85 touch floor = 14.5 px drawn

	Theme.Radius.panel = 18
	Theme.Radius.header = 12
	Theme.Radius.card = 14
	Theme.Radius.button = 12
	Theme.Radius.input = 10

	Theme.Stroke.panel = 3
	Theme.Stroke.card = 2
	Theme.Stroke.button = 2.5
	Theme.Stroke.input = 2

	Theme.Size.depth = 5
	Theme.Size.depthSmall = 4

	local Mo = Theme.Motion :: any
	Mo.openTime = 0.26
	Mo.openFrom = 0.8
	Mo.hoverScale = 1.05
	Mo.pressScale = 0.92 -- the press squish
	Mo.pressTime = 0.06
	Mo.releaseTime = 0.2

	Theme.Shadow = { enabled = true, offset = 6, transparency = 0.5, color = Pa.ink }
	Theme.Focus = { color = Pa.focus, thickness = 3, grow = 12 }
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local reducedMotionOverride: boolean? = nil

-- Player setting wins; otherwise follow the platform's Reduced Motion setting.
function Theme.isReducedMotion(): boolean
	if reducedMotionOverride ~= nil then
		return reducedMotionOverride
	end
	local ok, value = pcall(function(): any
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
end

-- nil = follow the platform setting again.
function Theme.setReducedMotion(value: boolean?)
	reducedMotionOverride = value
end

function Theme.role(name: RoleName): Swatch
	return Theme.Roles[name] or Theme.Roles.neutral
end

function Theme.menu(name: ThemeName): Swatch
	return Theme.Menus[name] or Theme.Menus.neutral
end

-- Vertical face gradient (UIGradient.Rotation = 90 runs top to bottom).
-- Dark glass (round 2, N5): faces are nearly flat, a faint light from above (40% of the swatch's
-- top colour), as the HUD's plain slabs are.
function Theme.faceSequence(swatch: Swatch): ColorSequence
	local top = swatch.bottom:Lerp(swatch.top, 0.4)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(1, swatch.bottom),
	})
end

-- 1234567 -> "1,234,567"
function Theme.formatComma(n: number): string
	local negative = n < 0
	local digits = tostring(math.floor(math.abs(n)))
	local out = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return if negative then "-" .. out else out
end

-- 1234567 -> "1.2M". Keeps trailing zeros of the integer part intact ("160M", not "16M").
local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }
function Theme.formatShort(n: number): string
	local value = math.abs(n)
	if value < 1000 then
		return tostring(math.floor(n))
	end
	local index = 0
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local text: string
	if value >= 100 then
		text = string.format("%d", math.floor(value))
	else
		text = string.format("%.1f", math.floor(value * 10) / 10)
		if text:sub(-2) == ".0" then
			text = text:sub(1, -3)
		end
	end
	return (if n < 0 then "-" else "") .. text .. SUFFIXES[index]
end

return Theme
