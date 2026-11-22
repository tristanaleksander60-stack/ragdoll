--!strict
-- Badges (phase D, 10 Nov 2026). Ids are 0 until the owner creates each badge on the Creator
-- Dashboard (Ragdoll Havoc > Engagement > Badges) and sends the id: a 0 id is never awarded.
-- Names and descriptions below are the text to type on the dashboard, word for word.

export type Badge = { key: string, id: number, name: string, description: string }

local Badges = {}

Badges.LIST = table.freeze({
	{ key = "Welcome", id = 2511026255505077, name = "Welcome", description = "You joined Untitled Ragdoll. Let the havoc begin!" },
	{ key = "FirstTakedown", id = 3373445548782736, name = "First Takedown", description = "Knock out your first dummy." },
	{ key = "FirstEgg", id = 3474625754262331, name = "First Egg", description = "Open your first weapon egg." },
	{ key = "FiveMinutes", id = 260717568329975, name = "Five Minutes", description = "Play for 5 minutes in one visit." },
	{ key = "Bullseye", id = 3887603893235173, name = "Bullseye", description = "Land on the bullseye with the human cannon." },
	{ key = "Takedowns100", id = 1844051455503525, name = "Havoc Maker", description = "Reach 100 takedowns." },
	{ key = "Nuke", id = 4449427007770327, name = "Nuked It", description = "Drop a nuke on your lab." },
	{ key = "Takedowns1000", id = 287835808177315, name = "Havoc Legend", description = "Reach 1,000 takedowns." },
} :: { Badge })

Badges.byKey = {} :: { [string]: Badge }
for _, b in Badges.LIST do
	Badges.byKey[b.key] = b
end

Badges.FIVE_MINUTES = 300 -- s of play in one visit

return table.freeze(Badges)
