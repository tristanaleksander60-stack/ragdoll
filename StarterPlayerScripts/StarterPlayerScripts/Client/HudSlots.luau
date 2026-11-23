--!strict
-- Where every fixed HUD control sits, in one place, so they never land on each other or on the
-- (outlines included: boxes stay at least 10 px apart)
-- tool bar (PokeController keeps the bottom middle; LayoutCheck checks all of it on phone, tablet
-- and PC screens). Positions are in a CoreUISafeInsets ScreenGui, the same frame as the LihFolk
-- kit's HUD (below Roblox's top bar, inside notches and the home indicator).
--
--   right edge   a column from the top: LAB VIEW, Replay, RAGDOLL; on a phone in the player view
--                GRAB and THROW sit just left of Roblox's jump button, on a tablet above it; the
--                recenter button low in the lab view
--   left edge    the chaos meter (top), the Events launcher (kit, mid-height); BUILD / PLAY / the
--                part counter (right of PLAY) in the bottom corner, or on a phone (the thumbstick owns that corner
--                and the screen is short): BUILD and PLAY under the launcher, the counter under
--                the chaos meter
--                under them (round 2, N5) the Robux packs, off a phone (a phone has them in
--                MENU's shop); on a computer in the player view, the mouse help in the bottom
--                corner while Grab is picked
--   bottom       the tool bar, between the side margins (PokeController.plan), and on a computer
--                the help line under it

local HudSlots = {}

export type Slot = {
	anchor: Vector2,
	position: UDim2,
	size: Vector2,
}

-- What the screen looks like: a phone (its shorter side 500 px or less) or not, touch or not, and
-- which view.
export type Context = {
	touch: boolean,
	lab: boolean,
	phone: boolean,
	portrait: boolean?, -- phase 0: a phone held upright (95 % of phone visits)
}

-- Phase 0 (19 Nov 2026), a phone held upright: the thumb row at the bottom is the move stick
-- (left), SHOOT / GRAB beside Roblox's jump button and, one row up, RUN and THROW (or ZOOM) over
-- them; the tool bar sits above that row (PokeController.PORTRAIT_BOTTOM), toasts go full width
-- under the top cluster (toastBox's third value). LayoutCheck checks four portrait phones.
HudSlots.PORTRAIT_TOAST_TOP = 200 -- px: under LAB VIEW / RAGDOLL (right) and SHOP / MENU (left)
HudSlots.PORTRAIT_BUILD_ROW = 56 -- px: BUILD/PLAY (44) + 12 at the top of an upright phone's toast box while building

local function slot(ax: number, ay: number, position: UDim2, w: number, h: number): Slot
	return { anchor = Vector2.new(ax, ay), position = position, size = Vector2.new(w, h) }
end

local SLOTS: { [string]: (ctx: Context) -> Slot } = {
	View = function(ctx)
		-- Wider off a phone: room for the V key badge beside "LAB VIEW".
		return slot(1, 0, UDim2.new(1, -12, 0, 10), if ctx.phone then 112 else 172, 44) -- 172: the UI_V2 eye icon + "LAB VIEW" + the key chip (140 cut it, PC play test 19 Nov)
	end,
	Replay = function()
		return slot(1, 0, UDim2.new(1, -12, 0, 66), 120, 52)
	end,
	Ragdoll = function()
		return slot(1, 0, UDim2.new(1, -14, 0, 130), 86, 52) -- 86 wide: clear of THROW on a phone
	end,
	Chaos = function()
		return slot(0, 0, UDim2.new(0, 12, 0, 10), 214, 46)
	end,
	Recenter = function(ctx)
		if ctx.portrait then
			return slot(1, 1, UDim2.new(1, -14, 1, -168), 56, 56) -- (upright: clear of the hit line over the bar)
		end
		return slot(1, 1, UDim2.new(1, -14, 1, -96), 56, 56)
	end,
	Grab = function(ctx)
		if ctx.phone then
			return slot(1, 1, UDim2.new(1, -108, 1, -24), 76, 76) -- left of the 70 px jump button
		end
		return slot(1, 1, UDim2.new(1, -32, 1, -254), 76, 76) -- above the 120 px jump button
	end,
	Throw = function(ctx)
		if ctx.portrait then
			return slot(1, 1, UDim2.new(1, -30, 1, -104), 60, 60) -- over the jump button
		end
		if ctx.phone then
			return slot(1, 1, UDim2.new(1, -116, 1, -112), 60, 60) -- above GRAB
		end
		return slot(1, 1, UDim2.new(1, -120, 1, -262), 60, 60) -- left of GRAB
	end,
	Mode = function(ctx)
		if ctx.phone then
			if ctx.portrait then
				-- (Upright, PC LayoutCheck 19 Nov: side by side with PLAY in the toasts' top row; while
				-- building there toasts go under them, BuildController -> Toast.setMinTop, and the chase
				-- bar steps aside, ChaseHud.)
				return slot(0, 0, UDim2.new(0, 12, 0, HudSlots.PORTRAIT_TOAST_TOP), 92, 44)
			end
			return slot(0, 0, UDim2.new(0, 12, 0.5, 50), 92, 44) -- under the Events launcher
		end
		return slot(0, 1, UDim2.new(0, 14, 1, -14), 92, 56)
	end,
	Play = function(ctx)
		if ctx.phone then
			if ctx.portrait then
				return slot(0, 0, UDim2.new(0, 114, 0, HudSlots.PORTRAIT_TOAST_TOP), 92, 44) -- right of BUILD
			end
			return slot(0, 0, UDim2.new(0, 12, 0.5, 104), 92, 44) -- under BUILD
		end
		return slot(0, 1, UDim2.new(0, 14, 1, -80), 92, 56) -- above BUILD
	end,
	Counter = function(ctx)
		if ctx.phone then
			-- In the chaos meter's place: it steps aside while building on a phone (round 3, M6: the
			-- four launchers stand under it).
			return slot(0, 0, UDim2.new(0, 16, 0, 24), 120, 18)
		end
		-- Beside PLAY (to its right), clear of the launcher column above, the tool bar's top and its
		-- pick chip (90 wide: "150/150 parts" is 74 px).
		return slot(0, 1, UDim2.new(0, 118, 1, -104), 90, 18)
	end,
}

-- Round 2, N5: the Robux packs (three event cards under RAGDOLL, off a phone) and the mouse help.
HudSlots.PACK = Vector2.new(200, 52)
HudSlots.PACK_GAP = 8
HudSlots.PACKS = 3
SLOTS.Packs = function()
	local h = HudSlots.PACKS * HudSlots.PACK.Y + (HudSlots.PACKS - 1) * HudSlots.PACK_GAP
	return slot(1, 0, UDim2.new(1, -12, 0, 194), HudSlots.PACK.X, h) -- (RAGDOLL ends at 182)
end
SLOTS.MouseHelp = function()
	return slot(1, 1, UDim2.new(1, -14, 1, -14), 172, 108)
end

-- Round 4, M10: the RUN button (touch only, the walk view): on a phone just above Roblox's jump
-- button, clear of THROW to its left; on a tablet left of the jump button, under GRAB and THROW.
SLOTS.Sprint = function(ctx)
	if ctx.portrait then
		return slot(1, 1, UDim2.new(1, -104, 1, -112), 56, 56) -- over SHOOT / GRAB, left of THROW
	end
	if ctx.phone then
		-- (Phase 0: over the jump button it touched RAGDOLL on short phones (LayoutCheck now checks
		-- it): THROW's box, and RUN steps aside while THROW or ZOOM need it: HudSlots.sprintFree.)
		return slot(1, 1, UDim2.new(1, -116, 1, -112), 60, 60)
	end
	-- (A tablet: under the 120 px jump button in the corner, clear of the 6-slot bar that ends 196 px
	-- from the right; left of the jump button it sat on the bar: PC LayoutCheck 19 Nov, iPad.)
	return slot(1, 1, UDim2.new(1, -100, 1, -8), 70, 70)
end

-- Round 5, phase 00: SHOOT (touch, the walk view, a gun picked) takes GRAB's place by the jump
-- button, a little bigger: GRAB shows only with Grab picked, so the two never show together (not in
-- NAMES for that reason; LayoutCheck checks it against the rest itself).
SLOTS.Shoot = function(ctx)
	if ctx.phone then
		return slot(1, 1, UDim2.new(1, -108, 1, -24), 76, 76) -- (GRAB's box: the bar's side margin is made for it)
	end
	return slot(1, 1, UDim2.new(1, -28, 1, -250), 92, 92)
end

-- 23 Nov 2026: RELOAD (touch, a gun with a magazine): over the jump button, beside the action button.
SLOTS.Reload = function(ctx)
	if ctx.phone then
		return slot(1, 1, UDim2.new(1, -30, 1, -104), 60, 52)
	end
	return slot(1, 1, UDim2.new(1, -44, 1, -352), 64, 56)
end

-- Round 5, phase 1 (like the big ragdoll games):
--   Weapons      the big WEAPONS button under the chaos meter: the next weapon, "Next: X 3/5" and
--                a bar (the left column of launchers starts under it: HudMenu sets COLUMN_TOP)
--   Deal         "Today's deal" off a phone, at the top of the right-hand cards (the Robux packs
--                below it), left of the sandbox column
--   FirstPerson, SlowMo, Revive, Reset   the sandbox column under RAGDOLL, off a phone
SLOTS.Weapons = function(ctx)
	return slot(0, 0, UDim2.new(0, 12, 0, 68), if ctx.phone then 158 else 214, if ctx.phone then 46 else 58)
end
-- Phase 1: the Experiment card. On a phone it takes the big WEAPONS button's box (HudPlus hides
-- that button there: Config.PHONE_HUD_MAX7; the bar keeps its WEAPONS slab); elsewhere top middle,
-- under the toasts, where the NPC Chase's bar goes (it steps aside for a chase and the arena).
SLOTS.Experiment = function(ctx)
	if ctx.phone then
		return slot(0, 0, UDim2.new(0, 12, 0, 68), 158, 46)
	end
	return slot(0.5, 0, UDim2.new(0.5, 0, 0, 108), 280, 46)
end
HudSlots.SIDE_X = -112 -- the right-hand cards' right edge (clear of the 86 px sandbox column)
SLOTS.Deal = function()
	return slot(1, 0, UDim2.new(1, HudSlots.SIDE_X, 0, 130), HudSlots.PACK.X, 56)
end
HudSlots.SANDBOX = { "FirstPerson", "SlowMo", "Revive", "Reset" }
for i, name in HudSlots.SANDBOX do
	SLOTS[name] = function()
		return slot(1, 0, UDim2.new(1, -14, 0, 192 + (i - 1) * 56), 86, 46)
	end
end
-- (The packs move down under the deal, left of the sandbox column.)
SLOTS.Packs = function()
	local h = HudSlots.PACKS * HudSlots.PACK.Y + (HudSlots.PACKS - 1) * HudSlots.PACK_GAP
	return slot(1, 0, UDim2.new(1, HudSlots.SIDE_X, 0, 196), HudSlots.PACK.X, h)
end

-- Round 5 (review fix): ZOOM for a scoped gun on touch: on a phone just over SHOOT (in THROW's
-- place: THROW shows only with Grab picked), clear of RAGDOLL and the bar; on a tablet left of SHOOT.
SLOTS.Zoom = function(ctx)
	if ctx.portrait then
		return slot(1, 1, UDim2.new(1, -30, 1, -104), 60, 48) -- (THROW's box: never together)
	end
	if ctx.phone then
		return slot(1, 1, UDim2.new(1, -116, 1, -114), 64, 48)
	end
	return slot(1, 1, UDim2.new(1, -140, 1, -250), 92, 52)
end

HudSlots.NAMES = { "View", "Replay", "Ragdoll", "Chaos", "Recenter", "Grab", "Throw", "Mode", "Play", "Counter", "Packs", "MouseHelp", "Sprint", "Weapons", "Deal", "FirstPerson", "SlowMo", "Revive", "Reset", "Shoot", "Zoom", "Experiment" }

-- Whether RUN may show with this tool picked (a landscape phone shares THROW's / ZOOM's box).
function HudSlots.sprintFree(ctx: Context, selected: string): boolean
	if ctx.phone and not ctx.portrait then
		return selected ~= "Grab" and selected ~= "Sniper" and selected ~= "DMR"
	end
	return true
end

-- Phase 0: on a phone the first QUIET_START s of a visit show only what the first minute needs
-- (fire, the move stick, the bar, WEAPONS, SHOP, MENU, RAGDOLL); these wait (LAB VIEW and RUN), and
-- BUILD lives in MENU (SANDBOX) on a phone. Config.QUIET_START.
HudSlots.PHONE_LATER = { View = true, Sprint = true }
-- Audit area 1: a newcomer's first visit (Client/FirstVisit sets newcomerUntil, a time()) keeps these back
-- on every screen until the HUD comes in.
HudSlots.NEWCOMER_LATER = { View = true, MouseHelp = true, Replay = true }
HudSlots.newcomerUntil = 0
-- (Fired when newcomerUntil changes: buttons placed while it was held place themselves again.)
HudSlots.newcomerChanged = Instance.new("BindableEvent")
function HudSlots.setNewcomerUntil(t: number)
	HudSlots.newcomerUntil = t
	HudSlots.newcomerChanged:Fire()
end
-- When this player's quiet start ends (a newcomer's reveal may be later than QUIET_START).
function HudSlots.quietUntil(quietStart: number): number
	local n = HudSlots.newcomerUntil
	return if n == math.huge then quietStart else math.max(quietStart, n)
end
function HudSlots.shownNow(name: string, ctx: Context, now: number, quietStart: number): boolean
	if HudSlots.NEWCOMER_LATER[name] and now < HudSlots.newcomerUntil then
		return false
	end
	if ctx.phone and HudSlots.PHONE_LATER[name] then
		return now >= quietStart
	end
	return true
end

function HudSlots.get(name: string, ctx: Context): Slot
	return SLOTS[name](ctx)
end

-- The owner (10 Nov): a quieter HUD, the game in front. These controls are drawn at HUD_SCALE of
-- their slot, shrunk towards their anchor (a UIScale, so their insides shrink with them); on a touch
-- screen never under a 44 px tap. The NEXT weapon button (Weapons) and the touch fire buttons keep
-- their size.
HudSlots.HUD_SCALE = 0.8
HudSlots.QUIET = { View = true, Replay = true, Ragdoll = true, Deal = true, Packs = true, FirstPerson = true, SlowMo = true, Revive = true, Reset = true, MouseHelp = true, Recenter = true, Chaos = true }
function HudSlots.scaleOf(name: string, ctx: Context): number
	if not HudSlots.QUIET[name] then
		return 1
	end
	local s = SLOTS[name](ctx)
	local k = HudSlots.HUD_SCALE
	if ctx.touch then
		k = math.max(k, 44 / math.max(1, math.min(s.size.X, s.size.Y)))
	end
	return math.min(k, 1)
end

-- A slot's box on a screen of this size (the safe-area frame).
function HudSlots.rect(name: string, ctx: Context, screen: Vector2): (Vector2, Vector2)
	local s = SLOTS[name](ctx)
	local size = s.size * HudSlots.scaleOf(name, ctx)
	local p = s.position
	local x = p.X.Scale * screen.X + p.X.Offset - s.anchor.X * size.X
	local y = p.Y.Scale * screen.Y + p.Y.Offset - s.anchor.Y * size.Y
	return Vector2.new(x, y), size
end

-- Where toasts go: the top of the screen between the left column (chaos meter) and the right one
-- (LAB VIEW, Replay), 12 px clear of both; centred when a toast of full width fits there, otherwise
-- in the middle of the gap (a phone). Returns the centre x and the widest a toast may be; on a
-- phone toasts may use three lines (TOAST_LINES) at a smaller size.
HudSlots.TOAST_MAX = 520

-- The top-middle bars (the arena's bar, the chase's health bar) on `screen`: `normal` px down,
-- or on a phone held upright under the top corners, where its toasts go (PC LayoutCheck run,
-- 19 Nov: at the top they sat on LAB VIEW, Replay, the chaos meter and WEAPONS). `below` = px
-- under the toast's top line (the chase bar keeps clear of a toast).
function HudSlots.eventTop(screen: Vector2, normal: number, below: number?): number
	if math.min(screen.X, screen.Y) <= 500 and screen.Y > screen.X then
		return HudSlots.PORTRAIT_TOAST_TOP + (below or 0)
	end
	return normal
end
HudSlots.PORTRAIT_CHASE_BELOW = 124 -- the chase bar under a portrait phone's toast (110 high, outlines + gap)

function HudSlots.toastBox(screen: Vector2, ctx: Context): (number, number, number?)
	if ctx.portrait then
		-- (Upright: the gap between the top corners is a few dozen px; the whole width under them.)
		return screen.X / 2, math.min(HudSlots.TOAST_MAX, screen.X - 24), HudSlots.PORTRAIT_TOAST_TOP
	end
	local chaosAt, chaosSize = HudSlots.rect("Chaos", ctx, screen)
	local viewAt = HudSlots.rect("View", ctx, screen)
	local replayAt = HudSlots.rect("Replay", ctx, screen)
	local left = chaosAt.X + chaosSize.X + 12
	local right = math.min(viewAt.X, replayAt.X) - 12
	local width = math.min(HudSlots.TOAST_MAX, right - left)
	local centred = screen.X / 2
	if centred - width / 2 < left or centred + width / 2 > right then
		centred = (left + right) / 2
	end
	return centred, width
end

-- Each placed control carries its slot's name (attribute HudSlot), so LayoutCheck.live can find it
-- from any context and compare its live box with the slot.

-- Puts a control in its slot.
function HudSlots.apply(object: GuiObject, name: string, ctx: Context)
	local s = HudSlots.get(name, ctx)
	object.AnchorPoint = s.anchor
	object.Position = s.position
	object.Size = UDim2.fromOffset(s.size.X, s.size.Y)
	object:SetAttribute("HudSlot", name)
	local k = HudSlots.scaleOf(name, ctx)
	object:SetAttribute("KitBase", k) -- (UI v2: KitStyle's press and pop return to this scale)
	local scale = object:FindFirstChild("HudScale")
	if k < 1 and not scale then
		local made = Instance.new("UIScale")
		made.Name = "HudScale"
		made.Parent = object
		scale = made
	end
	if scale and scale:IsA("UIScale") then
		scale.Scale = k
	end
end

-- The context right now, from the camera's viewport and the view mode.
function HudSlots.context(touch: boolean, lab: boolean): Context
	local viewport = workspace.CurrentCamera.ViewportSize
	local phone = math.min(viewport.X, viewport.Y) <= 500
	return { touch = touch, lab = lab, phone = phone, portrait = phone and viewport.Y > viewport.X }
end

-- Calls back whenever the screen changes size (the first frames report a tiny viewport, a phone
-- turns, a window is resized): slots that depend on the screen are placed again.
function HudSlots.watch(callback: () -> ())
	local connection: RBXScriptConnection? = nil
	local function follow()
		if connection then
			connection:Disconnect()
		end
		local camera = workspace.CurrentCamera
		if camera then
			connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(callback)
		end
		callback()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(follow)
	follow()
end

return HudSlots
