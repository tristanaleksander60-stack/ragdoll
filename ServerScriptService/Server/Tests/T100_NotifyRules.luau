--!strict
-- V6-1: the notification centre's rules (Shared/NotifyRules, pure): priorities, gaps by kind,
-- dedupe, expiry, the newcomer's quiet, quiet after a window, one big pop-up at a time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local R = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NotifyRules"))

return {
	name = "T100_NotifyRules",
	timeout = 5,
	run = function(): string?
		local s = R.new()
		-- Critical always; the first info shows, a second one waits for its gap.
		assert(R.decide(s, "critical", "c", 0, 0) == "show", "critical was held")
		assert(R.decide(s, "info", "a", 0, 0) == "show", "first info held")
		R.shown(s, "info", "a", 0)
		assert(R.decide(s, "info", "b", 1, 5) == "wait", "info 5 s after info did not wait")
		assert(R.decide(s, "reward", "r", 1, 5) == "show", "a reward waited past its 4 s gap")
		assert(R.decide(s, "tip", "t", 1, 30) == "wait", "a tip came within 45 s")
		assert(R.decide(s, "info", "b", 1, 21) == "show", "info still waits after its gap")
		-- Dedupe and expiry.
		assert(R.decide(s, "info", "a", 50, 50) == "drop", "the same key twice in two minutes")
		assert(R.decide(s, "info", "late", 0, 100) == "drop", "a 100 s old info was not dropped")
		assert(R.decide(s, "reward", "late2", 0, 100) ~= "drop", "a 100 s old reward was dropped")
		-- Muted tips.
		s.muted["hint"] = true
		assert(R.decide(s, "tip", "hint", 200, 200) == "drop", "a muted tip came back")
		-- The newcomer's first visit: rewards only.
		local n = R.new()
		n.newcomerUntil = 90
		assert(R.decide(n, "info", "x", 10, 10) == "wait", "news in a newcomer's first 90 s")
		assert(R.decide(n, "tip", "y", 10, 10) == "wait", "a tip in a newcomer's first 90 s")
		assert(R.decide(n, "reward", "z", 10, 10) == "wait", "a reward over a newcomer's objective line")
		assert(R.decide(n, "info", "x", 10, 100) == "show", "join-time news expired during the newcomer's quiet")
		-- Rewards are never deduped (two eggs are two eggs).
		local d = R.new()
		R.shown(d, "reward", "egg", 0)
		assert(R.decide(d, "reward", "egg", 10, 10) == "show", "a second identical reward was dropped")
		assert(not R.bigAllowed(n, 50), "a big pop-up before the reveal")
		assert(R.bigAllowed(n, 95), "no big pop-up after the reveal")
		-- Big pop-ups: one at a time, a gap after, never over the player's window.
		local b = R.new()
		assert(R.bigAllowed(b, 0), "the first big pop-up was refused")
		R.bigOpened(b, "EggReady")
		assert(not R.bigAllowed(b, 1), "two big pop-ups at once")
		assert(R.decide(b, "info", "q", 1, 1) == "wait", "news over a big pop-up")
		R.bigClosed(b, "EggReady", 10)
		assert(not R.bigAllowed(b, 30), "a big pop-up within BIG_GAP of the last")
		assert(R.decide(b, "info", "q", 10, 11) == "wait", "news right after a window closed")
		assert(R.bigAllowed(b, 10 + R.BIG_GAP), "big pop-ups never came back")
		b.playerWindow = true
		assert(not R.bigAllowed(b, 1000), "a big pop-up over the player's own window")
		-- Pick: most urgent first, then the oldest.
		local i = R.pick({ { kind = "tip", at = 0 }, { kind = "reward", at = 5 }, { kind = "reward", at = 2 } })
		assert(i == 3, "pick did not take the oldest reward")
		return string.format("gaps %d/%d/%d s, dedupe %d s, big gap %d s", R.GAP.reward, R.GAP.info, R.GAP.tip, R.DEDUPE, R.BIG_GAP)
	end,
}
