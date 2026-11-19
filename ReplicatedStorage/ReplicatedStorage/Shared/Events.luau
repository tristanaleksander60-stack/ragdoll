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
	{ id = "Tornado", name = "Tornado", blurb = "A twister wanders your lab and spins everything into the sky", duration = 18, productId = 0, icon = "event_Tornado", glyph = "\u{1F32A}\u{FE0F}", color = "#7A7F87" },
	{ id = "MeteorShower", name = "Meteor Shower", blurb = "Burning rocks rain down and blast the dummies", duration = 12, productId = 0, icon = "event_MeteorShower", glyph = "\u{2604}\u{FE0F}", color = "#D9622B" },
	{ id = "TrainRun", name = "Train Run", blurb = "Rails appear and a steam train thunders through your lab", duration = 12, productId = 0, icon = "event_TrainRun", glyph = "\u{1F682}", color = "#3E5C76" },
	-- v4 C4: eleven lab surprises (Server/Systems/Surprises), free (productId 0): the BIG RED BUTTON,
	-- the free-event rotation and the lab's own short surprises use them.
	{ id = "UfoBeam", name = "UFO Beam", blurb = "A flying saucer beams dummies up and drops them", duration = 16, productId = 0, icon = "event_UfoBeam", glyph = "\u{1F6F8}", color = "#46D17B" },
	{ id = "BowlingAvalanche", name = "Bowling Avalanche", blurb = "Giant bowling balls roll through the lab", duration = 10, productId = 0, icon = "event_BowlingAvalanche", glyph = "\u{1F3B3}", color = "#2E3A55" },
	{ id = "RocketRain", name = "Rocket Rain", blurb = "Little fireworks rockets rain down and pop dummies about", duration = 12, productId = 0, icon = "event_RocketRain", glyph = "\u{1F680}", color = "#E8503A" },
	{ id = "MagnetStorm", name = "Magnet Storm", blurb = "A huge magnet pulls every dummy in, then lets go", duration = 14, productId = 0, icon = "event_MagnetStorm", glyph = "\u{1F9F2}", color = "#C83A3A" },
	{ id = "LightningStorm", name = "Lightning Storm", blurb = "A storm cloud throws bolts that fling dummies", duration = 14, productId = 0, icon = "event_LightningStorm", glyph = "\u{26A1}", color = "#5A6178" },
	{ id = "Sinkhole", name = "Sinkhole", blurb = "A hole sucks dummies in and spits them sky-high", duration = 16, productId = 0, icon = "event_Sinkhole", glyph = "\u{1F573}\u{FE0F}", color = "#5B4636" },
	{ id = "Earthquake", name = "Earthquake", blurb = "The whole lab shakes and everything hops about", duration = 12, productId = 0, icon = "event_Earthquake", glyph = "\u{1F30B}", color = "#8A6B4A" },
	{ id = "FanBlast", name = "Giant Fan", blurb = "A giant fan blows the lab across the floor", duration = 12, productId = 0, icon = "event_FanBlast", glyph = "\u{1F32C}\u{FE0F}", color = "#6FA8D8" },
	{ id = "MoonGravity", name = "Moon Gravity", blurb = "A moon rises and dummies float like astronauts", duration = 16, productId = 0, icon = "event_MoonGravity", glyph = "\u{1F315}", color = "#8C8FA6" },
	{ id = "BalloonDrop", name = "Balloon Drop", blurb = "A hot-air balloon drifts over and drops guests", duration = 16, productId = 0, icon = "event_BalloonDrop", glyph = "\u{1F388}", color = "#E8B83A" },
	{ id = "GiantDummy", name = "Giant Dummy", blurb = "A giant dummy walks in to be knocked down", duration = 25, productId = 0, icon = "event_GiantDummy", glyph = "\u{1F9CD}", color = "#9AA0A8" },
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
