--!strict
-- V6-1: the rules of the notification centre (pure, so T100 can check them without a client).
-- Client/Notify keeps a State and asks `decide` for every waiting message and every big pop-up.
--
-- Kinds (most urgent first):
--   critical  shown at once, never held (a refusal, "your lab is gone", a server shutdown)
--   reward    something the player got (an egg, an unlock, a gift)
--   info      news nobody asked for (free weekend, events, What's New)
--   tip       help text; its x mutes it for the rest of the visit (Toast draws the x on tips only)
-- Rules:
--   * nothing but critical before `quietUntil` (the newcomer's first 90 s, a window just closed);
--   * a gap since the last unsolicited message, by kind (GAP);
--   * the same key again within DEDUPE seconds is dropped;
--   * a waiting message expires after MAX_WAIT[kind];
--   * big pop-ups (windows/cards that open by themselves): one at a time, BIG_GAP after the last
--     one closed, and never while the player has a window of their own open.

local NotifyRules = {}

export type Kind = "critical" | "reward" | "info" | "tip"
export type State = {
	lastAt: number, -- when the last unsolicited message showed
	lastKind: string?,
	seen: { [string]: number }, -- key -> when it last showed
	muted: { [string]: boolean }, -- tip keys the player switched off
	quietUntil: number, -- nothing but critical before this
	newcomerUntil: number, -- a newcomer's first visit: only rewards (one at a time) and critical before this
	bigOpen: string?, -- the big pop-up up now
	bigClosedAt: number, -- when the last big pop-up closed
	playerWindow: boolean, -- a window the player opened is up
}

NotifyRules.PRIORITY = table.freeze({ critical = 4, reward = 3, info = 2, tip = 1 })
-- Seconds since the last unsolicited message before one of this kind may show.
NotifyRules.GAP = table.freeze({ critical = 0, reward = 4, info = 20, tip = 45 })
-- Seconds a message may wait before it is no longer worth showing.
NotifyRules.MAX_WAIT = table.freeze({ critical = 10, reward = 120, info = 45, tip = 90 })
NotifyRules.DEDUPE = 120 -- s
NotifyRules.BIG_GAP = 40 -- s between two big pop-ups
NotifyRules.AFTER_WINDOW = 3 -- s of quiet after a window closes
-- V8-0.4 (one voice): in the first EARLY s of a visit, at most one toast per EARLY_GAP s (0: off;
-- Notify sets it from Config.V8_ONE_VOICE).
NotifyRules.EARLY = 180
NotifyRules.EARLY_GAP = 0

function NotifyRules.new(): State
	return {
		lastAt = -math.huge,
		lastKind = nil,
		seen = {},
		muted = {},
		quietUntil = 0,
		newcomerUntil = 0,
		bigOpen = nil,
		bigClosedAt = -math.huge,
		playerWindow = false,
	}
end

local function kindOf(kind: string?): string
	return if kind and NotifyRules.PRIORITY[kind] then kind else "info"
end

-- "show" | "wait" | "drop" for a small message (a toast) of `kind`, keyed `key`, queued at `queuedAt`.
function NotifyRules.decide(s: State, kind: string?, key: string, queuedAt: number, now: number): string
	local k = kindOf(kind)
	if k == "critical" then
		return "show"
	end
	if k == "tip" and s.muted[key] then
		return "drop"
	end
	-- (Only news and tips are deduped: two eggs in a row are two eggs.)
	local seenAt = s.seen[key]
	if k ~= "reward" and seenAt and now - seenAt < NotifyRules.DEDUPE then
		return "drop"
	end
	-- (A newcomer's first visit: nothing but critical, the objective line has the screen.)
	if now < s.newcomerUntil then
		return "wait"
	end
	-- (The expiry clock starts when the quiet ended: join-time news still shows after the reveal.)
	local from = math.max(queuedAt, s.newcomerUntil)
	if now - from > NotifyRules.MAX_WAIT[k] then
		return "drop"
	end
	if now < s.quietUntil then
		return "wait"
	end
	-- (Tips and news never talk over a big pop-up; a reward may, it is what the card is about.)
	if s.bigOpen and k ~= "reward" then
		return "wait"
	end
	if NotifyRules.EARLY_GAP > 0 and now < NotifyRules.EARLY and now - s.lastAt < NotifyRules.EARLY_GAP then
		return "wait"
	end
	if now - s.lastAt < NotifyRules.GAP[k] then
		return "wait"
	end
	return "show"
end

-- Marks a small message as shown.
function NotifyRules.shown(s: State, kind: string?, key: string, now: number)
	local k = kindOf(kind)
	s.seen[key] = now
	if k ~= "critical" then
		s.lastAt = now
		s.lastKind = k
	end
end

-- Whether a big pop-up may open now.
function NotifyRules.bigAllowed(s: State, now: number): boolean
	return s.bigOpen == nil
		and not s.playerWindow
		and now >= s.quietUntil
		and now >= s.newcomerUntil
		and now - s.bigClosedAt >= NotifyRules.BIG_GAP
end

function NotifyRules.bigOpened(s: State, name: string)
	s.bigOpen = name
end

function NotifyRules.bigClosed(s: State, name: string, now: number)
	if s.bigOpen == name then
		s.bigOpen = nil
		s.bigClosedAt = now
	end
	s.quietUntil = math.max(s.quietUntil, now + NotifyRules.AFTER_WINDOW)
end

-- Of the waiting items, the index of the one to try first: the most urgent, then the oldest.
function NotifyRules.pick(items: { { kind: string?, at: number } }): number?
	local best, bestP, bestAt = nil, -1, math.huge
	for i, it in items do
		local p = NotifyRules.PRIORITY[kindOf(it.kind)]
		if p > bestP or (p == bestP and it.at < bestAt) then
			best, bestP, bestAt = i, p, it.at
		end
	end
	return best
end

return NotifyRules
