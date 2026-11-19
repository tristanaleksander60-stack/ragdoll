--!strict
-- UI v2 (19 Nov 2026): what the weapon cards show, as plain data (no instances: T69 runs it).
--
--   rarity    by how far up the takedown ladder a weapon is, on the same bounds as its Robux price
--             tier (Toys.priceTiers): COMMON (a starter), RARE, EPIC, LEGENDARY, MYTHIC. A word and
--             a colour, so it never reads by colour alone.
--   stats     POWER, SPEED and CHAOS on a 1-10 scale against the strongest weapon ON THE SAME
--             SHELF. Toys.power is a hit speed over the hardest hit of all (135, a launch tool), so
--             every gun drew a sliver of a bar ("the weapons look weak in their own shop", AUDIT
--             §7). The shelf is what a player compares: the best gun there fills its bar.
--
-- Nothing here changes how a weapon plays: Toys stays as it is.

local Toys = require(script.Parent:WaitForChild("Toys"))

local UiRarity = {}

export type Rarity = {
	key: string,
	label: string,
	rank: number, -- 1 (common) to 5 (mythic)
	color: Color3,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Colours chosen to stay apart for the common colour-vision types (blue / purple / orange / red
-- differ in lightness too) and to keep 3:1 against the navy card.
UiRarity.LIST = table.freeze({
	table.freeze({ key = "Common", label = "COMMON", rank = 1, color = rgb(170, 182, 204) }),
	table.freeze({ key = "Rare", label = "RARE", rank = 2, color = rgb(64, 170, 255) }),
	table.freeze({ key = "Epic", label = "EPIC", rank = 3, color = rgb(186, 110, 255) }),
	table.freeze({ key = "Legendary", label = "LEGENDARY", rank = 4, color = rgb(255, 181, 46) }),
	table.freeze({ key = "Mythic", label = "MYTHIC", rank = 5, color = rgb(255, 77, 109) }),
}) :: { Rarity }

UiRarity.COMMON_UP_TO = 10 -- takedowns: the first rungs (and the starters) are common

-- The rarity of a weapon by its rung on the ladder.
function UiRarity.of(toy: Toys.Toy): Rarity
	local rung = toy.unlockAt
	if rung <= UiRarity.COMMON_UP_TO then
		return UiRarity.LIST[1]
	end
	for i, tier in Toys.priceTiers do
		if rung <= tier.upTo then
			return UiRarity.LIST[math.min(i + 1, #UiRarity.LIST)]
		end
	end
	return UiRarity.LIST[#UiRarity.LIST]
end

export type Stats = { power: number, speed: number, chaos: number }

UiRarity.SCALE = 10 -- the bars read "n/10"

-- The shelf's best of each stat (computed once).
local best: { [string]: { power: number, speed: number, chaos: number } }? = nil
local function bests(): { [string]: { power: number, speed: number, chaos: number } }
	local b = best
	if b then
		return b
	end
	local made: { [string]: { power: number, speed: number, chaos: number } } = {}
	for _, toy in Toys.list do
		local m = made[toy.category]
		if not m then
			m = { power = 0, speed = 0, chaos = 0 }
			made[toy.category] = m
		end
		local mm = m :: { power: number, speed: number, chaos: number }
		mm.power = math.max(mm.power, toy.power)
		mm.chaos = math.max(mm.chaos, toy.chaos or 0)
		mm.speed = math.max(mm.speed, 1 / math.max(0.05, toy.cooldown or 1))
	end
	best = made
	return made
end

-- A value against the shelf's best, on 1..SCALE (0 only when the weapon has none of it).
local function onScale(value: number, top: number): number
	if value <= 0 or top <= 0 then
		return 0
	end
	return math.clamp(math.floor(value / top * UiRarity.SCALE + 0.5), 1, UiRarity.SCALE)
end

function UiRarity.stats(toy: Toys.Toy): Stats
	local b = bests()[toy.category] or { power = 1, speed = 1, chaos = 1 }
	return {
		power = onScale(toy.power, b.power),
		speed = onScale(1 / math.max(0.05, toy.cooldown or 1), b.speed),
		chaos = onScale(toy.chaos or 0, b.chaos),
	}
end

return table.freeze(UiRarity)
