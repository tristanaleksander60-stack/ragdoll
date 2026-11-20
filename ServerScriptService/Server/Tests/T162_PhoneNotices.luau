--!strict
-- V9-0g (owner, 21 Nov 2026: "make all notifications on the phone much smaller: you could hardly see
-- anything"): NoticeRules. On a phone (AUTO = small) a notice is at most about 45 % of the width and
-- 40 px tall (48 upright) with 15 px text; in a fight (a shot in the last 1.5 s) only critical
-- notices show; 20 takedowns in 5 s are one "KO x20" counter; an unlock's reveal waits for 2 s
-- without a shot; MINIMAL shows only critical; a PC stays normal. (Toast, Banner, Notify and
-- ProgressUI use these rules on the screen.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NoticeRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NoticeRules")) :: any

return {
	name = "T162_PhoneNotices",
	timeout = 10,
	run = function(): string?
		-- Modes.
		assert(NoticeRules.mode(1, true) == "small" and NoticeRules.mode(1, false) == "normal", "AUTO is not small on a phone / normal on a PC")
		assert(NoticeRules.mode(2, true) == "normal" and NoticeRules.mode(4, false) == "minimal", "the Notices choices are wrong")
		-- Sizes on phone screens.
		for _, screen in { { Vector2.new(667, 375), false }, { Vector2.new(844, 390), false }, { Vector2.new(390, 844), true }, { Vector2.new(360, 780), true } } do
			local w, h, text = NoticeRules.smallBox(screen[1], screen[2])
			local limitW = screen[1].X * (if screen[2] then 0.9 else 0.46)
			assert(w <= limitW and h <= (if screen[2] then 48 else 40) and text >= 14 and text <= 16, string.format("a notice is too big on %dx%d: %dx%d at %d px", screen[1].X, screen[1].Y, w, h, text))
		end
		-- In a fight only critical shows; minimal only critical; normal shows all.
		local now = 100
		local busy = NoticeRules.busy(now, now - 0.5)
		assert(busy and not NoticeRules.busy(now, now - 2), "the busy window is wrong")
		assert(NoticeRules.allow("critical", "small", true), "a critical notice was held back in a fight")
		assert(not NoticeRules.allow("reward", "small", true) and not NoticeRules.allow("info", "small", true), "a reward/info notice showed in a fight on a phone")
		assert(NoticeRules.allow("reward", "small", false), "a reward notice was held back when calm")
		assert(not NoticeRules.allow("reward", "minimal", false) and NoticeRules.allow("critical", "minimal", false), "MINIMAL is wrong")
		assert(NoticeRules.allow("info", "normal", true), "a PC lost its notices in a fight")
		-- 20 takedowns in 5 s: one counter (each comes within the merge window of the last).
		local count, last = 0, -math.huge
		local counters = 0
		for i = 1, 20 do
			local t = i * 0.25
			if t - last >= NoticeRules.KO_MERGE then
				counters += 1
				count = 0
			end
			count += 1
			last = t
		end
		assert(counters == 1 and NoticeRules.koText(count) == "KO \u{00D7}20", "20 takedowns in 5 s did not merge into one KO x20")
		assert(NoticeRules.koText(1) == "+1 KO", "a single takedown reads wrong")
		-- An unlock while firing: the reveal waits; after 2 s quiet it plays.
		assert(not NoticeRules.revealNow(now, now - 0.5) and NoticeRules.revealNow(now, now - 2.1), "the unlock reveal does not wait for a quiet moment")
		return "phone: small notices (45 % x 40 px, 15 px text), critical only in a fight, KO x20 merged, reveal waits for 2 s quiet; MINIMAL and PC normal"
	end,
}
