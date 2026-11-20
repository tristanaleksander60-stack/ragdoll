--!strict
-- V8-0.9 (the day-2 tablet): where HudV3's squares go on a touch screen, as one pure rule that HudV3
-- draws and LayoutCheck checks. HudV3 is off phones, so "touch" here means a tablet. Off touch HudV3
-- keeps its PC layout (Shop/Weapons/Lab down the lower left, Maps/Menu at the right).
--   Touch: Shop, Weapons and Lab in a row at the top left, out of the move thumb's zone (Roblox's
--   dynamic thumbstick takes the lower left); Maps and Menu in a row at the right, under RAGDOLL
--   (which stays on a touch screen and was covered by MENU).
-- Rects are in screen pixels inside the safe area, like LayoutCheck's.

local HudV3Layout = {}

HudV3Layout.CARD = Vector2.new(132, 120) -- px at a 1080 px tall screen (HudV3.CARD)
HudV3Layout.GAP = 6
HudV3Layout.MARGIN = 12
HudV3Layout.UNDER_RAGDOLL = 10 -- px between RAGDOLL's bottom and the Maps/Menu row
HudV3Layout.TOAST_GAP = 12 -- px between the top-left row and the toast lane
HudV3Layout.ROW_MIN = 0.75 -- the top-left row shrinks to fit left of the toasts, never under this

export type Rect = { x: number, y: number, w: number, h: number, name: string }

-- HudV3's UIScale for a screen this tall.
function HudV3Layout.scale(screen: Vector2): number
	return math.clamp(screen.Y / 1080, 0.72, 1.1)
end

-- Roblox's move-thumb zone on a touch screen: the left 40 %, the lower two thirds.
function HudV3Layout.thumbZone(screen: Vector2): Rect
	return { x = 0, y = screen.Y / 3, w = screen.X * 0.4, h = screen.Y * 2 / 3, name = "ThumbZone" }
end

-- The top of the Maps/Menu row (screen px) for RAGDOLL's bottom edge (screen px; nil: no RAGDOLL).
function HudV3Layout.rightTop(screen: Vector2, ragdollBottom: number?): number
	local k = HudV3Layout.scale(screen)
	return math.max(150 * k, (ragdollBottom or 0) + HudV3Layout.UNDER_RAGDOLL)
end

-- How much the top-left row shrinks (1 = not at all) so it ends left of the toast lane (toastLeft:
-- the lane's left edge in screen px; nil: no lane to keep clear of).
function HudV3Layout.rowScale(screen: Vector2, toastLeft: number?): number
	if toastLeft == nil then
		return 1
	end
	local k = HudV3Layout.scale(screen)
	local m = HudV3Layout.MARGIN * k
	local row = (3 * HudV3Layout.CARD.X + 2 * HudV3Layout.GAP) * k
	return math.clamp((toastLeft - HudV3Layout.TOAST_GAP - m) / row, HudV3Layout.ROW_MIN, 1)
end

-- The five squares on a touch screen.
function HudV3Layout.touchRects(screen: Vector2, ragdollBottom: number?, toastLeft: number?): { Rect }
	local k = HudV3Layout.scale(screen)
	local cw, ch = HudV3Layout.CARD.X * k, HudV3Layout.CARD.Y * k
	local gap, m = HudV3Layout.GAP * k, HudV3Layout.MARGIN * k
	local f = HudV3Layout.rowScale(screen, toastLeft)
	local rects: { Rect } = {}
	for i, name in { "Shop", "Weapons", "Lab" } do
		table.insert(rects, { x = m + (i - 1) * (cw + gap) * f, y = m, w = cw * f, h = ch * f, name = "V3" .. name })
	end
	local top = HudV3Layout.rightTop(screen, ragdollBottom)
	local x0 = screen.X - m - (2 * cw + gap)
	for i, name in { "Maps", "Menu" } do
		table.insert(rects, { x = x0 + (i - 1) * (cw + gap), y = top, w = cw, h = ch, name = "V3" .. name })
	end
	return rects
end

return HudV3Layout
