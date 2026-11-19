--!strict
-- Phase 2 (19 Nov 2026): the soft currency BOLTS, the BONE JOURNAL, today's Daily Experiments and
-- the like-milestone codes, kept in the profile's `eco` field (ProgressService). Pure: the server's
-- EconomyService acts on it, T63 checks it. Numbers live in Config (BOLTS_*, JOURNAL, LIKE_CODES).
--   Bolts: from experiments (stars x BOLTS_PER_STAR), daily experiments (DAILY_BONUS), journal
--   pages (JOURNAL_BOLTS), playtime gifts (PLAYTIME_BOLTS, instead of eggs: EGG_RATION) and codes.
--   Spent on the next locked weapon (EconomyService "BuyNext": Economy.priceOf).
--   Journal: counts of what the server sees (Shared\Experiments kinds) reach a page's need.

local Config = require(script.Parent:WaitForChild("Config"))

local Economy = {}

export type Eco = {
	bolts: number,
	counts: { [string]: number },
	journal: { [string]: boolean },
	day: number, -- the UTC day `daily` belongs to
	daily: { [string]: boolean }, -- today's daily experiments done
	codes: { [string]: boolean }, -- like-milestone codes redeemed
}

export type Page = { id: string, text: string, kind: string, need: number }

-- The BONE JOURNAL: one page per thing found (kinds as in Shared\Experiments, plus Experiment and
-- Daily, counted by EconomyService).
Economy.JOURNAL = table.freeze({
	{ id = "FirstDown", text = "First takedown", kind = "Takedown", need = 1 },
	{ id = "Ten", text = "10 takedowns", kind = "Takedown", need = 10 },
	{ id = "Hundred", text = "100 takedowns", kind = "Takedown", need = 100 },
	{ id = "Thousand", text = "1,000 takedowns", kind = "Takedown", need = 1000 },
	{ id = "Cannonball", text = "Cannonball!", kind = "Cannon", need = 1 },
	{ id = "Frequent", text = "Frequent flyer: 25 cannon shots", kind = "Cannon", need = 25 },
	{ id = "Bullseye", text = "Bullseye", kind = "Bullseye", need = 1 },
	{ id = "Sharp", text = "Sharpshooter: 10 bullseyes", kind = "Bullseye", need = 10 },
	{ id = "Hot", text = "Too hot: thrown by a trap", kind = "Hazard", need = 1 },
	{ id = "Crash", text = "Crash dummy: 50 traps", kind = "Hazard", need = 50 },
	{ id = "Egg", text = "First egg", kind = "Egg", need = 1 },
	{ id = "Scientist", text = "Scientist: 5 experiments", kind = "Experiment", need = 5 },
	{ id = "Professor", text = "Professor: 50 experiments", kind = "Experiment", need = 50 },
	{ id = "Daily", text = "A daily experiment", kind = "Daily", need = 1 },
	{ id = "Regular", text = "Regular: 15 daily experiments", kind = "Daily", need = 15 },
	{ id = "Toss", text = "Friend flinger: a TOSS COMBO", kind = "Toss", need = 1 }, -- (release 0.20)
} :: { Page })

local function num(v: unknown, lo: number, hi: number): number?
	return if type(v) == "number" and v == v then math.clamp(math.floor(v), lo, hi) else nil
end

-- A stored eco table (or nothing) checked into a clean one.
function Economy.clean(raw: unknown): Eco
	local e: Eco = { bolts = 0, counts = {}, journal = {}, day = 0, daily = {}, codes = {} }
	if type(raw) ~= "table" then
		return e
	end
	local t = raw :: any
	e.bolts = num(t.bolts, 0, 1e9) or 0
	e.day = num(t.day, 0, 1e7) or 0
	if type(t.counts) == "table" then
		for k, v in t.counts do
			local n = num(v, 0, 1e9)
			if type(k) == "string" and #k <= 16 and n then
				e.counts[k] = n
			end
		end
	end
	local pages: { [string]: boolean } = {}
	for _, page in Economy.JOURNAL do
		pages[page.id] = true
	end
	for _, field in { "journal", "daily", "codes" } do
		local list = t[field]
		if type(list) == "table" then
			for k, v in list do
				if type(k) == "string" and #k <= 24 and v == true and (field ~= "journal" or pages[k]) then
					(e :: any)[field][k] = true
				end
			end
		end
	end
	return e
end

-- Counts `n` of a kind; returns the journal pages this just filled (and marks them).
function Economy.count(e: Eco, kind: string, n: number): { Page }
	e.counts[kind] = (e.counts[kind] or 0) + math.max(0, n)
	local new = {}
	for _, page in Economy.JOURNAL do
		if page.kind == kind and not e.journal[page.id] and e.counts[kind] >= page.need then
			e.journal[page.id] = true
			table.insert(new, page)
		end
	end
	return new
end

-- A new UTC day: yesterday's daily ticks go.
function Economy.rollDay(e: Eco, day: number)
	if e.day ~= day then
		e.day = day
		e.daily = {}
	end
end

-- What the next weapon costs in bolts (by its takedowns on the ladder).
function Economy.priceOf(unlockAt: number): number
	return math.max(Config.BOLTS_MIN_PRICE, math.floor(unlockAt * Config.BOLTS_PER_TAKEDOWN + 0.5))
end

-- The cheapest weapon not yet yours (by the ladder), given what is yours: (id, price) or nil.
function Economy.nextBuy(list: { any }, isMine: (string) -> boolean): (string?, number?)
	local best: any = nil
	for _, toy in list do
		if toy.unlockAt > 0 and not isMine(toy.id) and (best == nil or toy.unlockAt < best.unlockAt) then
			best = toy
		end
	end
	if not best then
		return nil, nil
	end
	return best.id, Economy.priceOf(best.unlockAt)
end

-- A like-milestone code: its bolts if it is live and not used yet by this profile.
function Economy.redeem(e: Eco, text: string): number?
	local code = string.upper((string.gsub(text, "%s", "")))
	if #code < 3 or #code > 24 or e.codes[code] then
		return nil
	end
	for _, entry in Config.LIKE_CODES do
		if entry.live and entry.code ~= "" and string.upper(entry.code) == code then
			e.codes[code] = true
			return entry.bolts
		end
	end
	return nil
end

return Economy
