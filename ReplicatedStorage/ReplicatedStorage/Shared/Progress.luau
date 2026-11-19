--!strict
-- Progress (phase F): what takedowns are worth. A takedown is a dummy or a person knocked down by
-- you (the server's blame on the body). Takedowns raise your rank, every EGG_EVERY of them finds
-- you an egg, and an egg opens into a hat for your avatar (rarer ones less often). Shared so the
-- server's rolls, the client's windows and the tests read the same tables.

export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"
export type Hat = { id: string, name: string, rarity: Rarity }
export type Rank = { name: string, at: number }

local Progress = {}

Progress.EGG_EVERY = 75 -- takedowns per egg (round 2, N4: an egg holds a weapon now, so they are rarer)
Progress.MAX_EGGS = 99 -- unopened eggs kept
Progress.TAKEDOWN_COOLDOWN = 3 -- s: the same body knocked again this soon counts once

Progress.RANKS = table.freeze({
	{ name = "Rookie", at = 0 },
	{ name = "Troublemaker", at = 10 },
	{ name = "Menace", at = 25 },
	{ name = "Wrecker", at = 60 },
	{ name = "Chaos Agent", at = 150 },
	{ name = "Chaos Lord", at = 400 },
	{ name = "Legend", at = 1000 },
} :: { Rank })

Progress.RARITY = table.freeze({
	Common = { weight = 60, color = Color3.fromRGB(200, 205, 220) },
	Rare = { weight = 28, color = Color3.fromRGB(80, 170, 255) },
	Epic = { weight = 10, color = Color3.fromRGB(190, 110, 255) },
	Legendary = { weight = 2, color = Color3.fromRGB(255, 200, 60) },
})

Progress.HATS = table.freeze({
	{ id = "PartyHat", name = "Party Hat", rarity = "Common" },
	{ id = "Cone", name = "Traffic Cone", rarity = "Common" },
	{ id = "Beanie", name = "Beanie", rarity = "Common" },
	{ id = "Bucket", name = "Bucket", rarity = "Common" },
	{ id = "Cowboy", name = "Cowboy Hat", rarity = "Rare" },
	{ id = "Propeller", name = "Propeller Cap", rarity = "Rare" },
	{ id = "Chef", name = "Chef Hat", rarity = "Rare" },
	{ id = "Viking", name = "Viking Helmet", rarity = "Epic" },
	{ id = "Halo", name = "Halo", rarity = "Epic" },
	{ id = "Crown", name = "Crown", rarity = "Epic" },
	{ id = "Duck", name = "Rubber Duck", rarity = "Legendary" },
	{ id = "GoldCrown", name = "Golden Crown", rarity = "Legendary" },
} :: { Hat })

Progress.hatById = {} :: { [string]: Hat }
for _, hat in Progress.HATS do
	Progress.hatById[hat.id] = hat
end

-- Your rank for a number of takedowns, and the next one (nil at the top).
function Progress.rankOf(takedowns: number): (Rank, Rank?)
	local current = Progress.RANKS[1]
	local nextRank: Rank? = nil
	for i, rank in Progress.RANKS do
		if takedowns >= rank.at then
			current = rank
			nextRank = Progress.RANKS[i + 1]
		end
	end
	return current, nextRank
end

-- A hat from an egg: a rarity by weight, then a hat of it. `roll` is a number in [0, 1).
function Progress.roll(rollRarity: number, rollHat: number): Hat
	local total = 0
	for _, r in { "Common", "Rare", "Epic", "Legendary" } do
		total += (Progress.RARITY :: any)[r].weight
	end
	local pickAt = rollRarity * total
	local rarity = "Legendary"
	for _, r in { "Common", "Rare", "Epic", "Legendary" } do
		local w = (Progress.RARITY :: any)[r].weight
		if pickAt < w then
			rarity = r
			break
		end
		pickAt -= w
	end
	local pool = {}
	for _, hat in Progress.HATS do
		if hat.rarity == rarity then
			table.insert(pool, hat)
		end
	end
	return pool[math.clamp(math.floor(rollHat * #pool) + 1, 1, #pool)]
end

return Progress
