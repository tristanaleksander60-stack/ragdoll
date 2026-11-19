--!strict
-- What may stay on the tool bar (round 3, M9 fix 2). Pure: the client acts on it, T42 checks it.
-- A tool known to be locked leaves the bar (the free weekend's weapon after Sunday), but only once
-- the player's progress is really known (never while it loads or after a failed read: everything
-- would look locked then), and never the last tool.

local BarRules = {}

-- `locked(id)`: the tool is known to be locked now. Returns the bar to keep and the ids taken off.
function BarRules.prune(bar: { string }, progressKnown: boolean, locked: (string) -> boolean): ({ string }, { string })
	local keep = table.clone(bar)
	local gone: { string } = {}
	if not progressKnown then
		return keep, gone
	end
	for i = #keep, 1, -1 do
		if #keep > 1 and locked(keep[i]) then
			table.insert(gone, table.remove(keep, i) :: string)
		end
	end
	return keep, gone
end

return BarRules
