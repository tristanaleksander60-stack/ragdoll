--!strict
-- V8-1.4 (one goal): the one "next weapon" every surface names (HudPlus' WEAPONS button, HudV3's
-- Next pill, the phone pill): the nearest exciting weapon (a gun, an explosive or a big special) not
-- yet yours, and the rung the count runs from (the last exciting rung you passed). Pure.

local Toys = require(script.Parent:WaitForChild("Toys"))

local NextGoal = {}

function NextGoal.exciting(toy: any): boolean
	return toy.category == "Guns" or toy.category == "Explosives" or toy.big == true
end

-- (toy or nil when every one is yours, the rung the count runs from)
function NextGoal.of(takedowns: number, owned: { [string]: boolean }): (any?, number)
	local best: any = nil
	local from = 0
	for _, toy in Toys.list do
		if toy.unlockAt > 0 and NextGoal.exciting(toy) then
			if toy.unlockAt <= takedowns or owned[toy.id] then
				if toy.unlockAt <= takedowns then
					from = math.max(from, toy.unlockAt)
				end
			elseif not best or toy.unlockAt < best.unlockAt then
				best = toy
			end
		end
	end
	return best, from
end

return NextGoal
