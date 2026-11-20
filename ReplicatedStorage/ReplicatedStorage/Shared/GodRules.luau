--!strict
-- V9-0f (owner, 21 Nov 2026: "make the god menu not visible to everyone, just in the shop like the
-- other passes"): who sees the GOD launcher (the HUD square off phones, the MENU entry on phones).
-- Pure: Client/HudV3, Client/HudMenu, Client/GodMode and T148 read it. Everyone else finds GOD MODE
-- as a pass card in the SHOP, with TRY 60 s and BUY.

local GodRules = {}

-- Whether creating life needs the pass here (the server's DummySpawn.godGated says the same): the
-- switch is on and the pass is on sale (or this is Studio).
function GodRules.gated(enabled: boolean, passId: number, studio: boolean): boolean
	return enabled and (passId ~= 0 or studio)
end

-- Whether the GOD launcher shows: always when creating is free; else only for an owner of the pass
-- or while their free trial runs.
function GodRules.launcherShown(gated: boolean, owns: boolean, trialUntil: unknown, now: number): boolean
	if not gated or owns then
		return true
	end
	return type(trialUntil) == "number" and now < trialUntil
end

-- The trial's state for the SHOP card's TRY button: "try" (never used this visit), "running" (and
-- the seconds left), or "used".
function GodRules.trialState(trialUntil: unknown, now: number): (string, number)
	if type(trialUntil) ~= "number" then
		return "try", 0
	end
	local left = trialUntil - now
	if left > 0 then
		return "running", math.ceil(left)
	end
	return "used", 0
end

return GodRules
