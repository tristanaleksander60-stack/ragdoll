--!strict
-- V8-0.3 (a full bar that stays yours):
--   the start bar is Popper (Blaster), Grab, Bat, Grenade, Launch, all open from the start, and the
--   Rocket is the first unlock (3);
--   unlocks 0..30 in order on the hand rules: the bar's power never falls, every gun and explosive
--   lands, a gun, a bang, Grab, the G17 and the Bat never leave;
--   a prize always lands;
--   a saved bar of Popper, Grab, Poke, Slap, Heal moves once to Popper, Grab, Bat, Grenade, Launch,
--   and a Poke put back after that stays (the migration never runs twice).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local HandRules = require(Shared:WaitForChild("HandRules")) :: any
local LoadoutStore = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("LoadoutStore")) :: any

local function power(bar: { string }): number
	local sum = 0
	for _, id in bar do
		sum += Toys.byId[id].rank -- (V8-0.3: strength is the rank, the ladder before V8 moved the start bar)
	end
	return sum
end

return {
	name = "T110_HandRules",
	timeout = 20,
	run = function(): string?
		if not (Config.V8_START_BAR and Config.V8_HAND_RULES) then
			return "skipped (V8_START_BAR / V8_HAND_RULES off)"
		end
		local start = Toys.defaultLoadout
		assert(table.concat(start, ",") == "Blaster,Grab,Bat,Grenade,Launch", "the start bar is " .. table.concat(start, ","))
		for _, id in start do
			assert(Toys.byId[id].unlockAt == 0, id .. " is not open from the start")
		end
		assert(Toys.byId.Rocket.unlockAt == 3, "the Rocket is not the first unlock at 3")
		for _, id in { "Poke", "Slap", "Shove" } do
			assert(Toys.byId[id].unlockAt > 10, id .. " is still on an early rung")
		end
		-- Unlocks 0..30 in order.
		local ladder = {}
		for _, toy in Toys.list do
			if toy.unlockAt > 0 and toy.unlockAt <= 30 then
				table.insert(ladder, toy)
			end
		end
		table.sort(ladder, function(a, b)
			return a.unlockAt < b.unlockAt
		end)
		local bar = table.clone(start)
		local before = power(bar)
		for _, toy in ladder do
			local slot = HandRules.slotFor(bar, toy.id, false)
			if slot then
				bar[slot] = toy.id
			end
			if (toy.gun or toy.category == "Explosives") and not table.find(bar, toy.id) then
				-- (A gun or a bang stays off only when nothing weaker may give way to it.)
				for _, have in bar do
					local t = Toys.byId[have]
					local replaceable = HandRules.mayGo(have) or (have ~= "Blaster" and (t.gun or t.category == "Explosives"))
					assert(not (replaceable and t.rank < toy.rank), toy.id .. " (a gun or a bang) did not land over the weaker " .. have)
				end
			end
			for _, keep in { "Blaster", "Grab", "Bat" } do
				assert(table.find(bar, keep), keep .. " left the bar for " .. toy.id)
			end
			local now = power(bar)
			assert(now >= before, "the bar got weaker with " .. toy.id)
			before = now
		end
		-- A prize lands even when it is weaker than everything that may go.
		local full = { "Blaster", "Grab", "Bat", "Grenade", "Launch", "Rocket" }
		local weak = HandRules.slotFor(full, "Punch", true)
		assert(weak and full[weak] ~= "Blaster" and full[weak] ~= "Grab", "a prize did not land")
		assert(HandRules.slotFor(full, "Punch", false) == nil, "a weaker unlock pushed something off")
		-- The one-time move of an old saved bar (memory only: a test never writes a real store).
		if not LoadoutStore.inMemory() then
			return "hand rules hold; the old-bar move not run (bars are in a real DataStore here)"
		end
		local userId = -110
		local moved = LoadoutStore.migrateOnce(userId, { "Blaster", "Grab", "Poke", "Slap", "Heal" })
		assert(table.concat(moved, ",") == "Blaster,Grab,Bat,Grenade,Launch", "the old bar moved to " .. table.concat(moved, ","))
		local again = LoadoutStore.migrateOnce(userId, { "Blaster", "Grab", "Bat", "Grenade", "Launch", "Poke" })
		assert(table.find(again, "Poke"), "the move ran a second time")
		return string.format("start bar %s; %d unlocks 0..30: power never fell, guns/bangs landed over anything weaker, keepers kept; a prize lands; the old bar moved once", table.concat(start, ","), #ladder)
	end,
}
