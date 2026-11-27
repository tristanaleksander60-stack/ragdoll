--!strict
-- AUDIT 27 Nov 1: every game pass or product ON SALE (Shop.OFFERS with an id) must reach a live feature. Run once at
-- startup; a pass that gives nothing is printed as an error (in Studio and in the live server's log), so a switched-off
-- feature can never keep selling silently (the Lab Controls pass sold while its BIG RED BUTTON was off, 24-27 Nov).
-- Checks: the offer has a grant in Offers.GRANTS, and the feature
-- switches behind the grants are on (RULES).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PassLint = {}

-- grant field -> is its feature live? (Config)
local RULES: { [string]: (any) -> boolean } = {
	labControls = function(C)
		return C.BIG_BUTTON == true or C.LAB_CONTROLS_BUTTON == true
	end,
	eventsPass = function(C)
		return C.EVENTS ~= false
	end,
}

function PassLint.run(): { string }
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Config = require(Shared:WaitForChild("Config")) :: any
	local Shop = require(Shared:WaitForChild("Shop")) :: any
	local Offers = require(Shared:WaitForChild("Offers")) :: any
	local bad: { string } = {}
	for _, o in Shop.OFFERS do
		if (tonumber(o.id) or 0) > 0 then
			local grant = Offers.GRANTS[o.key]
			if grant == nil then
				table.insert(bad, o.key .. ": no grant in Offers.GRANTS")
			else
				for field, rule in RULES do
					if grant[field] and not rule(Config) then
						table.insert(bad, o.key .. ": its " .. field .. " feature is switched off in Config")
					end
				end
			end
		end
	end
	for _, line in bad do
		warn("[PassLint] ERROR a pass on sale gives nothing: " .. line)
	end
	if #bad == 0 then
		print("[PassLint] every pass on sale reaches a live feature")
	end
	return bad
end

return PassLint
