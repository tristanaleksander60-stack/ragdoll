--!strict
-- Phase 0 (19 Nov 2026): a phone held upright (95 % of phone visits). HudSlots is pure, so the
-- server can lay it out for any screen. On four portrait phones and four landscape ones this checks:
--   the thumb row (SHOOT / GRAB, RUN, THROW, ZOOM, Roblox's jump button) never overlaps itself,
--   and in portrait all of it stays under the tool bar (PokeController.PORTRAIT_BOTTOM = 180)
--   the top cluster (chaos meter, WEAPONS, LAB VIEW, RAGDOLL) keeps clear of the toast box, which
--   is the full width under it in portrait (no more "Play 2 more min for a")
--   RUN no longer touches RAGDOLL on a short landscape phone (it shares THROW's box there)
--   LAB VIEW and RUN wait out the quiet start on a phone, not on a computer
-- The full picture (bar, launchers, windows) is LayoutCheck's, run in a play test on the client.

local StarterPlayer = game:GetService("StarterPlayer")

local client = (StarterPlayer :: any).StarterPlayerScripts.Client
local HudSlots = require(client.HudSlots) :: any

type Rect = { x: number, y: number, w: number, h: number, name: string }

local PORTRAIT_BOTTOM = 180 -- PokeController.PORTRAIT_BOTTOM (the bar's gap at the foot of the screen)
local GAP = 10 -- LayoutCheck: 3 px outlines and 4 px between them

local function rect(name: string, ctx: any, screen: Vector2): Rect
	local at, size = HudSlots.rect(name, ctx, screen)
	return { x = at.X, y = at.Y, w = size.X, h = size.Y, name = name }
end

local function overlap(a: Rect, b: Rect): boolean
	local m = GAP / 2
	return a.x - m < b.x + b.w + m and b.x - m < a.x + a.w + m and a.y - m < b.y + b.h + m and b.y - m < a.y + a.h + m
end

local function jump(screen: Vector2): Rect
	return { x = screen.X - 95, y = screen.Y - 90, w = 70, h = 70, name = "Jump" }
end

local PORTRAIT = { Vector2.new(390, 752), Vector2.new(414, 804), Vector2.new(360, 690), Vector2.new(430, 840) }
local LANDSCAPE = { Vector2.new(667, 317), Vector2.new(800, 302), Vector2.new(750, 311), Vector2.new(832, 351) }

-- Pairs that never show together (SHOOT only with a gun, GRAB / THROW only with Grab, ZOOM only
-- with a scoped gun, RUN steps aside on a landscape phone).
local APART: { [string]: { [string]: boolean } } = {
	Shoot = { Grab = true, Throw = true },
	Grab = { Shoot = true, Zoom = true },
	Throw = { Shoot = true, Zoom = true, Sprint = true },
	Zoom = { Grab = true, Throw = true, Sprint = true },
	Sprint = { Throw = true, Zoom = true },
	Experiment = { Weapons = true }, -- (phase 1: on a phone the card has the big WEAPONS button's box)
	Weapons = { Experiment = true },
}

local function check(screen: Vector2, portrait: boolean, problems: { string })
	local ctx = { touch = true, lab = false, phone = true, portrait = portrait }
	local list: { Rect } = { jump(screen) }
	for _, name in { "Shoot", "Grab", "Throw", "Sprint", "Zoom", "View", "Ragdoll", "Chaos", "Weapons", "Experiment" } do
		table.insert(list, rect(name, ctx, screen))
	end
	local cx, tw, ty = HudSlots.toastBox(screen, ctx)
	local toast: Rect = { x = cx - tw / 2, y = ty or 10, w = tw, h = if portrait then 110 else 86, name = "Toast" }
	table.insert(list, toast)
	local label = string.format("%dx%d", screen.X, screen.Y)
	for i, a in list do
		if a.x < 0 or a.y < 0 or a.x + a.w > screen.X or a.y + a.h > screen.Y then
			table.insert(problems, label .. " off screen: " .. a.name)
		end
		for j = i + 1, #list do
			local b = list[j]
			local apart = APART[a.name] and APART[a.name][b.name]
			if not apart and overlap(a, b) then
				table.insert(problems, string.format("%s %s/%s", label, a.name, b.name))
			end
		end
	end
	if portrait then
		local barBottom = screen.Y - PORTRAIT_BOTTOM
		for _, r in list do
			if (r.name == "Shoot" or r.name == "Grab" or r.name == "Throw" or r.name == "Sprint" or r.name == "Zoom" or r.name == "Jump") and r.y < barBottom + GAP then
				table.insert(problems, label .. " " .. r.name .. " reaches the bar")
			end
		end
		if tw < screen.X - 40 then
			table.insert(problems, label .. " toast box only " .. tw .. " px wide")
		end
	end
end

return {
	name = "T54_PortraitHud",
	timeout = 3,
	run = function(): string?
		local problems: { string } = {}
		for _, size in PORTRAIT do
			check(size, true, problems)
		end
		for _, size in LANDSCAPE do
			check(size, false, problems)
		end
		assert(#problems == 0, table.concat(problems, "; "))
		-- The quiet start: on a phone LAB VIEW and RUN wait, nothing waits on a computer.
		local phone = { touch = true, lab = false, phone = true, portrait = true }
		local pc = { touch = false, lab = false, phone = false }
		assert(not HudSlots.shownNow("View", phone, 30, 90) and HudSlots.shownNow("View", phone, 91, 90), "LAB VIEW should wait 90 s on a phone")
		assert(not HudSlots.shownNow("Sprint", phone, 30, 90), "RUN should wait on a phone")
		assert(HudSlots.shownNow("View", pc, 1, 90) and HudSlots.shownNow("Ragdoll", phone, 1, 90), "nothing else waits")
		assert(not HudSlots.sprintFree({ touch = true, lab = false, phone = true, portrait = false }, "Grab"), "RUN must give THROW its box on a landscape phone")
		assert(HudSlots.sprintFree(phone, "Grab"), "RUN has its own place upright")
		return string.format("%d portrait + %d landscape phones: thumb row, top cluster and toast box clear", #PORTRAIT, #LANDSCAPE)
	end,
}
