--!strict
-- Server events: one big moment the whole server sees at once, with the name of whoever set it off
-- ("Tristan sent DUMMY RAIN!"). Bought with Robux (developer products), given away on free
-- weekends, and later set off by TikTok gifts in Streamer Mode: the same engine for all of them
-- (EventService). Every event is temporary; nothing it does stays in the game.
--
-- productId: the developer product on the Creator Dashboard (0 = not on sale yet). Prices shown in
-- the game always come from Roblox (GetProductInfoAsync), never from here.

export type Event = {
	id: string,
	name: string, -- shown in caps on the banner
	blurb: string, -- one short line on the shop card
	duration: number, -- s the banner runs
	productId: number,
	icon: string, -- LihFolk UI icon name (drawn from glyph/color until art exists)
	glyph: string, -- its picture (a colour emoji, unique among events; T21 checks)
	color: string, -- its hex colour
}

local list: { Event } = {
	{ id = "DummyRain", name = "Dummy Rain", blurb = "A dozen dummies drop from the sky", duration = 20, productId = 3730106983, icon = "event_DummyRain", glyph = "🌧️", color = "#3FA9F5" },
	{ id = "MegaBomb", name = "Mega Bomb", blurb = "One huge cartoon blast across the lab", duration = 5, productId = 3730107002, icon = "event_MegaBomb", glyph = "🎇", color = "#FF5A3C" },
	{ id = "ZeroG", name = "Zero-G", blurb = "Gravity almost off for everyone", duration = 20, productId = 3730107024, icon = "event_ZeroG", glyph = "🪐", color = "#9B6BFF" },
	{ id = "BouncyFloor", name = "Bouncy Floor", blurb = "Everything that lands bounces back up", duration = 20, productId = 3730107042, icon = "event_BouncyFloor", glyph = "🏀", color = "#38C46A" },
	{ id = "FlashFreeze", name = "Flash Freeze", blurb = "Every dummy turns to ice at once", duration = 8, productId = 3730107067, icon = "event_FlashFreeze", glyph = "🧊", color = "#7FE3FF" },
	-- v3 Phase C (19 Nov 2026): animals. Not on sale until the owner makes their products (0): the
	-- lab's BIG RED BUTTON and the free events reach them meanwhile.
	{ id = "GorillaRampage", name = "Gorilla Rampage", blurb = "A giant gorilla swats dummies around your lab", duration = 20, productId = 0, icon = "event_GorillaRampage", glyph = "🦍", color = "#6B5B4B" },
	{ id = "BullRun", name = "Bull Run", blurb = "Three bulls charge straight through the lab", duration = 14, productId = 0, icon = "event_BullRun", glyph = "🐂", color = "#B5562E" },
}

local byId: { [string]: Event } = {}
for _, event in list do
	byId[event.id] = table.freeze(event)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	MAX_QUEUE = 4, -- events waiting; a purchase prompt is refused while the queue is full
	GAP = 3, -- s between two events
})
