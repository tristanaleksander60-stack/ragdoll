--!strict
-- Phase 0 (19 Nov 2026): the gamepad. Client\GamepadControls binds Shared\PadMap's buttons with
-- ContextActionService; a server test cannot press a pad, so this drives PadMap.handle (the very
-- function every binding runs) with fake actions and checks:
--   every button the plan names is bound, once, at a priority under the kit's B-close (High)
--   R2 fires on press and lets go on release (also when a window opened meanwhile)
--   LB / RB and the D-pad step the bar; in a window LB / RB switch tabs and the D-pad moves the
--   selection (passes); Y opens WEAPONS and closes it from inside
--   X, B, Select, D-pad up / down act in the world and pass while a window is open
--   the pad glyphs read right on Xbox and PlayStation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PadMap = require(ReplicatedStorage.Shared.PadMap)

local B = Enum.UserInputState.Begin
local E = Enum.UserInputState.End
local SINK = Enum.ContextActionResult.Sink
local PASS = Enum.ContextActionResult.Pass

return {
	name = "T53_Gamepad",
	timeout = 3,
	run = function(): string?
		-- 1. The bindings.
		local need = {
			ButtonR2 = "PadFire",
			ButtonL2 = "PadAim",
			ButtonL1 = "PadSlotPrev",
			ButtonR1 = "PadSlotNext",
			DPadLeft = "PadSlotPrev",
			DPadRight = "PadSlotNext",
			ButtonY = "PadWeapons",
			ButtonX = "PadGrab",
			ButtonB = "PadRagdoll",
			ButtonSelect = "PadView",
			DPadDown = "PadMenu",
			DPadUp = "PadShop",
		}
		local seen: { [string]: string } = {}
		for _, b in PadMap.BINDINGS do
			for _, key in b.keys do
				assert(seen[key.Name] == nil, key.Name .. " is bound twice")
				assert(key ~= Enum.KeyCode.ButtonStart, "ButtonStart is Roblox's menu (reserved)")
				seen[key.Name] = b.action
			end
		end
		for key, action in need do
			assert(seen[key] == action, string.format("%s should be %s, is %s", key, action, tostring(seen[key])))
		end
		assert(PadMap.PRIORITY < Enum.ContextActionPriority.High.Value, "the pad must stay under the kit's ButtonB close (High)")
		assert(PadMap.PRIORITY > Enum.ContextActionPriority.Medium.Value, "the pad must sit over Roblox's defaults")

		-- 2. Fake actions that write down what happened.
		local log: { string } = {}
		local busy = false
		local tabs = true
		local actions: PadMap.Actions = {
			busy = function()
				return busy
			end,
			fire = function(down)
				table.insert(log, "fire " .. tostring(down))
			end,
			aim = function(down)
				table.insert(log, "aim " .. tostring(down))
			end,
			slot = function(step)
				table.insert(log, "slot " .. step)
			end,
			tab = function(step)
				table.insert(log, "tab " .. step)
				return tabs
			end,
			weapons = function()
				table.insert(log, "weapons")
			end,
			grab = function()
				table.insert(log, "grab")
			end,
			ragdoll = function()
				table.insert(log, "ragdoll")
			end,
			view = function()
				table.insert(log, "view")
			end,
			menu = function()
				table.insert(log, "menu")
			end,
			shop = function()
				table.insert(log, "shop")
			end,
		}
		local function press(action: string, key: Enum.KeyCode, state: Enum.UserInputState?): (Enum.ContextActionResult, string?)
			local before = #log
			local result = PadMap.handle(actions, action, state or B, key)
			return result, if #log > before then log[#log] else nil
		end

		-- In the world.
		local r, did = press("PadFire", Enum.KeyCode.ButtonR2)
		assert(r == SINK and did == "fire true", "R2 did not fire: " .. tostring(did))
		r, did = press("PadFire", Enum.KeyCode.ButtonR2, E)
		assert(did == "fire false", "letting go of R2 did not stop firing")
		r, did = press("PadAim", Enum.KeyCode.ButtonL2)
		assert(r == SINK and did == "aim true", "L2 did not aim")
		r, did = press("PadSlotPrev", Enum.KeyCode.ButtonL1)
		assert(r == SINK and did == "slot -1", "LB did not step back")
		r, did = press("PadSlotNext", Enum.KeyCode.DPadRight)
		assert(r == SINK and did == "slot 1", "D-pad right did not step on")
		for action, want in { PadWeapons = "weapons", PadGrab = "grab", PadRagdoll = "ragdoll", PadView = "view", PadMenu = "menu", PadShop = "shop" } do
			r, did = press(action, Enum.KeyCode.ButtonA)
			assert(r == SINK and did == want, action .. " did not " .. want)
		end
		-- A release of a one-shot button does nothing.
		r, did = press("PadGrab", Enum.KeyCode.ButtonX, E)
		assert(r == PASS and did == nil, "releasing X acted again")

		-- 3. A window is open: the pad belongs to it.
		busy = true
		r, did = press("PadFire", Enum.KeyCode.ButtonR2)
		assert(r == PASS and did == nil, "R2 fired through an open window")
		r, did = press("PadFire", Enum.KeyCode.ButtonR2, E)
		assert(did == "fire false", "R2 let go in a window did not stop the firing")
		r, did = press("PadSlotNext", Enum.KeyCode.ButtonR1)
		assert(r == SINK and did == "tab 1", "RB did not switch the tab")
		tabs = false
		r, did = press("PadSlotNext", Enum.KeyCode.ButtonR1)
		assert(r == PASS, "RB in a window without tabs must pass")
		r, did = press("PadSlotPrev", Enum.KeyCode.DPadLeft)
		assert(r == PASS and did == nil, "the D-pad must move the selection in a window")
		r, did = press("PadWeapons", Enum.KeyCode.ButtonY)
		assert(r == SINK and did == "weapons", "Y did not close WEAPONS from inside")
		for _, action in { "PadGrab", "PadRagdoll", "PadView", "PadMenu", "PadShop" } do
			r, did = press(action, Enum.KeyCode.ButtonA)
			assert(r == PASS and did == nil, action .. " acted through an open window (B must close it)")
		end
		busy = false

		-- 4. Glyphs.
		assert(PadMap.glyph("Fire", false) == "RT" and PadMap.glyph("Fire", true) == "R2", "fire glyphs")
		assert(PadMap.glyph("Weapons", false) == "Y", "Y glyph")
		assert(PadMap.isPad(Enum.UserInputType.Gamepad1) and not PadMap.isPad(Enum.UserInputType.Touch), "isPad")

		-- 5. The client module ships.
		local client = StarterPlayer:FindFirstChild("StarterPlayerScripts") and (StarterPlayer :: any).StarterPlayerScripts:FindFirstChild("Client")
		local module = client and client:FindFirstChild("GamepadControls")
		assert(module and module:IsA("ModuleScript"), "Client.GamepadControls is missing")
		return string.format("%d buttons bound, %d actions logged, windows take the pad", #PadMap.BINDINGS, #log)
	end,
}
