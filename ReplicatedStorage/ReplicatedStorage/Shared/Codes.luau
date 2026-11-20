--!strict
-- V9-0t (owner, 21 Nov 2026: "add codes we can advertise in the description"): the game's codes. Pure:
-- the server's EconomyService redeems them, the CODES window (Client/CodesWindow) sends them, T169
-- checks them. A code is case-insensitive and spaces are ignored; each player may use each code once
-- (the profile's eco.codes); outside its dates it answers that it has expired. Never tied to likes
-- or favourites (Roblox rules: the old Config.LIKE_CODES stay off).
--   reward: bolts, a free try of a weapon (TrialService, minutes), a map-shop cosmetic for some hours
--   (MapShopService's Try_<key>, kept in eco.perks across visits). Nothing is sold here.

local Codes = {}

export type Entry = {
	code: string,
	bolts: number?,
	trialWeapon: string?,
	trialMinutes: number?,
	cosmetic: string?,
	cosmeticHours: number?,
	from: number?, -- unix time (UTC) it starts; nil: from now
	to: number?, -- unix time (UTC) it ends; nil: no end
	beta: boolean?, -- only while the game is in beta (Config.BETA)
	live: boolean,
}

local function utc(y: number, m: number, d: number, h: number?, mi: number?, s: number?): number
	return DateTime.fromUniversalTime(y, m, d, h or 0, mi or 0, s or 0).UnixTimestamp
end

Codes.LIST = table.freeze({
	table.freeze({ code = "RELEASE", bolts = 500, live = true }),
	table.freeze({ code = "BETA", bolts = 300, trialWeapon = "Railgun", trialMinutes = 30, beta = true, live = true }),
	table.freeze({ code = "RAGDOLL", bolts = 250, live = true }),
	table.freeze({ code = "CHRISTMAS", bolts = 750, cosmetic = "FireTrail", cosmeticHours = 24, from = utc(2026, 12, 1), to = utc(2026, 12, 31, 23, 59, 59), live = true }),
} :: { Entry })

Codes.RATE = 5 -- tries a minute per player (server)
Codes.MESSAGES = table.freeze({
	invalid = "That code does not work",
	used = "You already used this code",
	expired = "This code has expired",
	slow = "Too many tries. Wait a minute",
})

-- The typed text as a code: upper case, no spaces.
function Codes.normalize(text: string): string
	return string.upper((string.gsub(text, "%s", "")))
end

export type Why = "invalid" | "used" | "expired"

-- The code's entry if `text` may be redeemed now by someone who used `used`, else why not. A code not
-- started yet, or a beta code after the beta, answers like an unknown one: no hint that it exists.
function Codes.check(text: string, used: { [string]: boolean }, now: number, beta: boolean): (Entry?, Why?)
	local code = Codes.normalize(text)
	if #code < 3 or #code > 24 then
		return nil, "invalid"
	end
	for _, entry in Codes.LIST do
		if entry.live and entry.code == code then
			if (entry.from and now < entry.from) or (entry.beta and not beta) then
				return nil, "invalid"
			end
			if entry.to and now > entry.to then
				return nil, "expired"
			end
			if used[code] then
				return nil, "used"
			end
			return entry, nil
		end
	end
	return nil, "invalid"
end

-- What a reward gives, in words (the result line).
function Codes.describe(entry: Entry, weaponName: string?, cosmeticName: string?): string
	local parts = {}
	if entry.bolts then
		table.insert(parts, string.format("+%d BOLTS", entry.bolts))
	end
	if entry.trialWeapon then
		table.insert(parts, string.format("%s free for %d min", weaponName or entry.trialWeapon, entry.trialMinutes or 30))
	end
	if entry.cosmetic then
		table.insert(parts, string.format("%s for %d h", cosmeticName or entry.cosmetic, entry.cosmeticHours or 24))
	end
	return table.concat(parts, " + ")
end

return Codes
