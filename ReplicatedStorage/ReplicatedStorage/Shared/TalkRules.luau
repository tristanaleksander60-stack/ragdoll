--!strict
-- V9-0a (owner, 21 Nov 2026: "when you try to hit a ragdoll you open the talk menu all the time"):
-- when this screen shows the Talk prompts (NpcCommand's TalkPrompt) and when the Talk panel may
-- open. Pure: Client/NpcTalk and T158 read it.
--   * A click never opens Talk (the server makes the prompt not clickable); keyboard E / pad L3 do.
--   * After any attack (a click, a tap, R2, a shot of your own, or while Grab holds a body) the
--     prompts hide for QUIET_AFTER s (QUIET_AFTER_TOUCH on touch).
--   * On touch the prompt shows only while you stand still, and needs a TOUCH_HOLD s hold.
--   * The panel never opens within OPEN_GAP s of an attack, even if a prompt fired.

local TalkRules = {}

TalkRules.QUIET_AFTER = 2
TalkRules.QUIET_AFTER_TOUCH = 3
TalkRules.OPEN_GAP = 0.5
TalkRules.TOUCH_HOLD = 0.4
TalkRules.STILL_SPEED = 2 -- studs/s of walking that still counts as standing still

export type State = {
	now: number,
	lastAttack: number,
	touch: boolean,
	speed: number, -- your avatar's speed over the ground, studs/s
	grabbing: boolean,
	viewOk: boolean, -- not in the lab view or Build
}

-- Whether the Talk prompts show on this screen now.
function TalkRules.show(s: State): boolean
	if not s.viewOk or s.grabbing then
		return false
	end
	local quiet = if s.touch then TalkRules.QUIET_AFTER_TOUCH else TalkRules.QUIET_AFTER
	if s.now - s.lastAttack < quiet then
		return false
	end
	if s.touch and s.speed > TalkRules.STILL_SPEED then
		return false
	end
	return true
end

-- Whether the Talk panel may open now.
function TalkRules.mayOpen(now: number, lastAttack: number): boolean
	return now - lastAttack >= TalkRules.OPEN_GAP
end

-- Whether an input (not taken by the UI) is an attack: a click, a tap or R2.
function TalkRules.isAttack(inputType: Enum.UserInputType, keyCode: Enum.KeyCode): boolean
	return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch or keyCode == Enum.KeyCode.ButtonR2
end

-- How the prompt behaves on this screen: clickable/tappable only on touch, and then with a hold.
function TalkRules.promptStyle(touch: boolean): (boolean, number)
	if touch then
		return true, TalkRules.TOUCH_HOLD
	end
	return false, 0
end

return TalkRules
