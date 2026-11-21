--!strict
-- V9-NOW 12 (owner, 21 Nov 2026: "a 2x event for 48 hours"): pure rules for the 2X KO + BOLTS window in
-- Config.DOUBLE_EVENT { from, to } (UTC seconds). The servers decide by os.time(), so every server starts and
-- ends together; the client only draws the chip from the same numbers.

local DoubleEvent = {}

DoubleEvent.MULT = 2

export type Window = { from: number, to: number }

local function windowOf(cfg: unknown): Window?
	if type(cfg) ~= "table" then
		return nil
	end
	local w = cfg :: any
	if type(w.from) ~= "number" or type(w.to) ~= "number" or w.to <= w.from then
		return nil
	end
	return { from = w.from, to = w.to }
end

-- Whether the event runs at `now` (UTC seconds).
function DoubleEvent.active(cfg: unknown, now: number): boolean
	local w = windowOf(cfg)
	return w ~= nil and now >= w.from and now < w.to
end

-- What a KO or a bolt payout is multiplied by at `now` (1 outside the window).
function DoubleEvent.mult(cfg: unknown, now: number): number
	return if DoubleEvent.active(cfg, now) then DoubleEvent.MULT else 1
end

-- Seconds left (0 outside the window).
function DoubleEvent.left(cfg: unknown, now: number): number
	local w = windowOf(cfg)
	if not w or now < w.from or now >= w.to then
		return 0
	end
	return w.to - now
end

-- "2X · 47:12:05" for a number of seconds left.
function DoubleEvent.label(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	return string.format("2X \u{00B7} %d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
end

return DoubleEvent
