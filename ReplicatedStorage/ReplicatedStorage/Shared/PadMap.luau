--!strict
-- Phase 0 (19 Nov 2026): the gamepad, in one place. 28 % of visits had a pad and 84 % of them never
-- fired (the only binding was L3 sprint). Client\GamepadControls binds these with
-- ContextActionService; this module is pure (no client state), so the server's self-test drives
-- the handler with fake actions (T53_Gamepad).
--
--   R2 fire (held: automatic guns keep firing)   L2 zoom / aim (held)
--   LB / RB or D-pad left / right: the previous / next bar slot (LB / RB switch tabs in WEAPONS)
--   Y WEAPONS   X grab / throw   B ragdoll   Select (View / Share) the next view
--   D-pad up SHOP   D-pad down MENU
-- Start (Menu / Options) is Roblox's own menu and cannot be taken (reserved): MENU is on D-pad down.
-- While one of our windows is open the pad belongs to it (A selects, B closes: the kit's ButtonB at
-- High priority, D-pad moves): every world action passes, except Y (closes WEAPONS) and LB / RB.
-- Aim is the centre of the screen (the same path as the touch SHOOT button).

local PadMap = {}

export type Actions = {
	busy: () -> boolean, -- one of our windows is open
	fire: (down: boolean) -> (),
	aim: (down: boolean) -> (),
	slot: (step: number) -> (),
	tab: (step: number) -> boolean, -- a window with tabs took the step
	weapons: () -> (),
	grab: () -> (),
	ragdoll: () -> (),
	view: () -> (),
	menu: () -> (),
	shop: () -> (),
}

export type Binding = { action: string, keys: { Enum.KeyCode }, hold: boolean? }

-- Below the kit's ButtonB close (High, 3000) and Sprint's L3 (High); above Roblox's defaults
-- (Medium = Default, 2000), which use none of these buttons in the world.
PadMap.PRIORITY = Enum.ContextActionPriority.Medium.Value + 100

PadMap.BINDINGS = {
	{ action = "PadFire", keys = { Enum.KeyCode.ButtonR2 }, hold = true },
	{ action = "PadAim", keys = { Enum.KeyCode.ButtonL2 }, hold = true },
	{ action = "PadSlotPrev", keys = { Enum.KeyCode.ButtonL1, Enum.KeyCode.DPadLeft } },
	{ action = "PadSlotNext", keys = { Enum.KeyCode.ButtonR1, Enum.KeyCode.DPadRight } },
	{ action = "PadWeapons", keys = { Enum.KeyCode.ButtonY } },
	{ action = "PadGrab", keys = { Enum.KeyCode.ButtonX } },
	{ action = "PadRagdoll", keys = { Enum.KeyCode.ButtonB } },
	{ action = "PadView", keys = { Enum.KeyCode.ButtonSelect } },
	{ action = "PadShop", keys = { Enum.KeyCode.DPadUp } },
	{ action = "PadMenu", keys = { Enum.KeyCode.DPadDown } },
} :: { Binding }

-- The button names shown on hints (Xbox names, PlayStation names).
local GLYPHS: { [string]: { string } } = {
	Fire = { "RT", "R2" },
	Aim = { "LT", "L2" },
	Slot = { "LB/RB", "L1/R1" },
	Weapons = { "Y", "\u{25B3}" },
	Grab = { "X", "\u{25A1}" },
	Ragdoll = { "B", "\u{25CB}" },
	View = { "View", "Share" },
	Menu = { "D-pad \u{2193}", "D-pad \u{2193}" },
	Shop = { "D-pad \u{2191}", "D-pad \u{2191}" },
}
function PadMap.glyph(name: string, playstation: boolean?): string
	local pair = GLYPHS[name]
	if not pair then
		return name
	end
	return if playstation then pair[2] else pair[1]
end

local SINK = Enum.ContextActionResult.Sink
local PASS = Enum.ContextActionResult.Pass

-- What one binding does with one input state. Returns Sink when it acted (or swallowed the
-- release of a press it acted on), Pass otherwise.
function PadMap.handle(actions: Actions, action: string, state: Enum.UserInputState, key: Enum.KeyCode?): Enum.ContextActionResult
	local begin = state == Enum.UserInputState.Begin
	local stop = state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel
	-- Held buttons: always let go (a window may have opened while R2 was down).
	if action == "PadFire" or action == "PadAim" then
		local fn = if action == "PadFire" then actions.fire else actions.aim
		if stop then
			fn(false)
			return PASS
		end
		if begin and not actions.busy() then
			fn(true)
			return SINK
		end
		return PASS
	end
	if not begin then
		return PASS
	end
	local busy = actions.busy()
	if action == "PadSlotPrev" or action == "PadSlotNext" then
		local step = if action == "PadSlotPrev" then -1 else 1
		local shoulder = key == Enum.KeyCode.ButtonL1 or key == Enum.KeyCode.ButtonR1
		if busy then
			-- (Shoulders switch tabs; the D-pad moves the selection.)
			if shoulder and actions.tab(step) then
				return SINK
			end
			return PASS
		end
		actions.slot(step)
		return SINK
	end
	if action == "PadWeapons" then
		actions.weapons() -- (opens WEAPONS, or closes it when it is the open window)
		return SINK
	end
	if busy then
		return PASS
	end
	if action == "PadGrab" then
		actions.grab()
	elseif action == "PadRagdoll" then
		actions.ragdoll()
	elseif action == "PadView" then
		actions.view()
	elseif action == "PadMenu" then
		actions.menu()
	elseif action == "PadShop" then
		actions.shop()
	else
		return PASS
	end
	return SINK
end

-- Whether this input type is a gamepad (the hints switch to pad glyphs).
function PadMap.isPad(kind: Enum.UserInputType): boolean
	return string.sub(kind.Name, 1, 7) == "Gamepad"
end

return PadMap
