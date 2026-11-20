--!strict
-- V8-0.3 (Config.V8_HAND_RULES): where a new tool goes on a full bar (pure; PokeController uses it,
-- T110 checks it). A new tool takes the weakest slot (by Toy.rank, the ladder before V8 moved the
-- start bar to 0) that may go, and only when it is
-- stronger; a gun, an explosive, Grab, the G17 (Blaster) and the Bat never give way to a plain tool
-- (a stronger gun or bang may take the weakest gun or bang, never the G17). A prize (an egg, a
-- crate, a gift day) always lands: with nothing weaker it takes the weakest that may go anyway, and
-- with every slot guarded the last slot that is not the G17 or Grab.

local Toys = require(script.Parent:WaitForChild("Toys"))

local HandRules = {}

HandRules.KEEP = table.freeze({ Blaster = true, Grab = true, Bat = true }) :: { [string]: boolean }

-- Whether a slot's tool may give way to a new one.
function HandRules.mayGo(id: string): boolean
	local t = Toys.byId[id]
	return t ~= nil and not t.gun and t.category ~= "Explosives" and not HandRules.KEEP[id]
end

-- The slot (1..SLOTS) the tool goes in, or nil when it does not go on the bar.
function HandRules.slotFor(bar: { string }, id: string, prize: boolean?): number?
	local new = Toys.byId[id]
	if not new then
		return nil
	end
	local at = table.find(bar, id)
	if at then
		return at
	end
	if #bar < Toys.SLOTS then
		return #bar + 1
	end
	local weakest, weakestAt = nil :: number?, math.huge
	for i, have in bar do
		local t = Toys.byId[have]
		if t and HandRules.mayGo(have) and t.rank < weakestAt then
			weakest, weakestAt = i, t.rank
		end
	end
	if weakest and (prize or new.rank > weakestAt) then
		return weakest
	end
	-- A stronger gun or bang always lands: with no plain tool left to give way it takes the weakest
	-- gun or bang below it (never the G17).
	if new.gun or new.category == "Explosives" then
		local bang, bangAt = nil :: number?, new.rank
		for i, have in bar do
			local t = Toys.byId[have]
			if t and have ~= "Blaster" and (t.gun or t.category == "Explosives") and t.rank < bangAt then
				bang, bangAt = i, t.rank
			end
		end
		if bang then
			return bang
		end
	end
	if prize and not weakest then
		for i = #bar, 1, -1 do
			if bar[i] ~= "Blaster" and bar[i] ~= "Grab" then
				return i
			end
		end
	end
	return nil
end

return HandRules
