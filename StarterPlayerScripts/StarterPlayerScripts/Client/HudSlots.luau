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
}

local function slot(ax: number, ay: number, position: UDim2, w: number, h: number): Slot
	return { anchor = Vector2.new(ax, ay), position = position, size = Vector2.new(w, h) }
end

local SLOTS: { [string]: (ctx: Context) -> Slot } = {
	View = function(ctx)
		-- Wider off a phone: room for the V key badge beside "LAB VIEW".
		return slot(1, 0, UDim2.new(1, -12, 0, 10), if ctx.phone then 112 else 140, 44)
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
	Recenter = function()
		return slot(1, 1, UDim2.new(1, -14, 1, -96), 56, 56)
	end,
	Grab = function(ctx)
		if ctx.phone then
			return slot(1, 1, UDim2.new(1, -108, 1, -24), 76, 76) -- left of the 70 px jump button
		end
		return slot(1, 1, UDim2.new(1, -32, 1, -254), 76, 76) -- above the 120 px jump button
	end,
	Throw = function(ctx)
		if ctx.phone then
			return slot(1, 1, UDim2.new(1, -116, 1, -112), 60, 60) -- above GRAB
		end
		return slot(1, 1, UDim2.new(1, -120, 1, -262), 60, 60) -- left of GRAB
	end,
	Mode = function(ctx)
		if ctx.phone then
			return slot(0, 0, UDim2.new(0, 12, 0.5, 50), 92, 44) -- under the Events launcher
		end
		return slot(0, 1, UDim2.new(0, 14, 1, -14), 92, 56)
	end,
	Play = function(ctx)
		if ctx.phone then
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
	if ctx.phone then
		return slot(1, 1, UDim2.new(1, -25, 1, -102), 64, 64)
	end
	return slot(1, 1, UDim2.new(1, -200, 1, -60), 70, 70)
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

-- Round 5, phase 1 (like the big ragdoll games):
--   Weapons      the big WEAPONS button under the chaos meter: the next weapon, "Next: X 3/5" and
--                a bar (the left column of launchers starts under it: HudMenu sets COLUMN_TOP)
--   Deal         "Today's deal" off a phone, at the top of the right-hand cards (the Robux packs
--                below it), left of the sandbox column
--   FirstPerson, SlowMo, Revive, Reset   the sandbox column under RAGDOLL, off a phone
SLOTS.Weapons = function(ctx)
	return slot(0, 0, UDim2.new(0, 12, 0, 68), if ctx.phone then 158 else 214, if ctx.phone then 46 else 58)
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
	if ctx.phone then
		return slot(1, 1, UDim2.new(1, -116, 1, -114), 64, 48)
	end
	return slot(1, 1, UDim2.new(1, -140, 1, -250), 92, 52)
end

HudSlots.NAMES = { "View", "Replay", "Ragdoll", "Chaos", "Recenter", "Grab", "Throw", "Mode", "Play", "Counter", "Packs", "MouseHelp", "Sprint", "Weapons", "Deal", "FirstPerson", "SlowMo", "Revive", "Reset" }

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
function HudSlots.toastBox(screen: Vector2, ctx: Context): (number, number)
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
	return { touch = touch, lab = lab, phone = math.min(viewport.X, viewport.Y) <= 500 }
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
