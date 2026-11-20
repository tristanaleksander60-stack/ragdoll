--!strict
-- V9-0g (owner, 21 Nov 2026: "make all notifications on the phone much smaller: you could hardly see
-- anything when shooting several ragdolls and unlocking things"): how big notices may be, when they
-- may show, and how repeats merge. Pure: Client/NoticeState, Toast, Banner, Notify, ProgressUI and
-- T162 read it.
--   * Size on a phone (mode "small"): one lane at the top centre, at most PHONE_W of the width, about
--     PHONE_H tall (portrait PHONE_H_PORTRAIT), text PHONE_TEXT px; banners are a compact pill there.
--   * Amount: one at a time; while you fired in the last BUSY s only critical notices show, the rest
--     are dropped; "+1 TAKEDOWN" repeats merge into one "KO xN" counter; an unlock's big reveal
--     waits for REVEAL_QUIET s without a shot.
--   * Settings "Notices": AUTO (small on a phone, normal elsewhere), NORMAL, SMALL, MINIMAL (only
--     critical, and the KO counter).

local NoticeRules = {}

NoticeRules.PHONE_H = 40
NoticeRules.PHONE_H_PORTRAIT = 48
NoticeRules.PHONE_W = 0.45
NoticeRules.PHONE_TEXT = 15
NoticeRules.BUSY = 1.5 -- s after a shot or swing
NoticeRules.BANNER_HOLD = 1.2 -- s a compact banner stays
NoticeRules.KO_MERGE = 2.5 -- s a KO counter keeps counting
NoticeRules.REVEAL_QUIET = 2 -- s without a shot before an unlock's big reveal plays
NoticeRules.CHOICES = { "AUTO", "NORMAL", "SMALL", "MINIMAL" } -- (Settings "Notices", index 1 = AUTO)

export type Mode = "normal" | "small" | "minimal"

-- The mode from the setting's index (1..4) and the device.
function NoticeRules.mode(choice: number?, phone: boolean): Mode
	local name = NoticeRules.CHOICES[choice or 1] or "AUTO"
	if name == "NORMAL" then
		return "normal"
	elseif name == "SMALL" then
		return "small"
	elseif name == "MINIMAL" then
		return "minimal"
	end
	return if phone then "small" else "normal"
end

-- Whether the player is in the middle of a fight (a shot or swing in the last BUSY s).
function NoticeRules.busy(now: number, lastUse: number): boolean
	return now - lastUse < NoticeRules.BUSY
end

-- Whether an unsolicited notice of `kind` ("critical" | "reward" | "info" | "tip") may show.
function NoticeRules.allow(kind: string, mode: Mode, busy: boolean): boolean
	if kind == "critical" then
		return true
	end
	if mode == "minimal" then
		return false
	end
	if busy and mode == "small" then
		return false
	end
	return true
end

-- The merged KO counter's words.
function NoticeRules.koText(n: number): string
	return if n <= 1 then "+1 KO" else string.format("KO \u{00D7}%d", n)
end

-- The largest notice box on a screen of `size` in mode "small" (width, height, text px).
function NoticeRules.smallBox(size: Vector2, portrait: boolean): (number, number, number)
	local h = if portrait then NoticeRules.PHONE_H_PORTRAIT else NoticeRules.PHONE_H
	local w = math.floor(size.X * (if portrait then 0.9 else NoticeRules.PHONE_W))
	return w, h, NoticeRules.PHONE_TEXT
end

-- Whether an unlock's big reveal may play now (or should wait as a small chip).
function NoticeRules.revealNow(now: number, lastUse: number): boolean
	return now - lastUse >= NoticeRules.REVEAL_QUIET
end

return NoticeRules
