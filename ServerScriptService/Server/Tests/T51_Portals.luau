--!strict
-- Round 5, phase 4: portals and the server list (the parts that run in Studio: teleports cannot).
--   a server's fun name: from the word list, the same for the same id, different ids differ
--   PLAY NOW: the fullest server with room, never this one, none when all are full
--   this server's entry; both portals stand in the lab; requests in Studio are answered, never teleport

local Players = game:GetService("Players")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local PortalService = require(Systems:WaitForChild("PortalService"))
local Lab = require(Systems:WaitForChild("Lab"))

return {
	name = "portals-server-list",
	timeout = 20,
	run = function(): string?
		local a = PortalService.nameOf("job-aaa")
		assert(a == PortalService.nameOf("job-aaa"), "a name changed for the same server")
		assert(string.match(a, "^%u+ %u+$"), "a name is not two words: " .. a)
		local names = {}
		for i = 1, 20 do
			names[PortalService.nameOf("job-" .. i)] = true
		end
		local distinct = 0
		for _ in names do
			distinct += 1
		end
		assert(distinct >= 12, "only " .. distinct .. " names for 20 servers")
		local list = {
			{ id = "me", name = "", region = "DK", players = 9, max = 10, t = 0 },
			{ id = "a", name = "", region = "DK", players = 4, max = 10, t = 0 },
			{ id = "b", name = "", region = "US", players = 8, max = 10, t = 0 },
			{ id = "c", name = "", region = "US", players = 10, max = 10, t = 0 },
		}
		local best = PortalService.fullest(list, "me")
		assert(best and best.id == "b", "PLAY NOW did not pick the fullest with room")
		assert(PortalService.fullest({ list[1], list[4] }, "me") == nil, "PLAY NOW picked a full server or this one")
		local e = PortalService.entry()
		assert(type(e.name) == "string" and e.max == Players.MaxPlayers, "this server's entry is wrong")
		local player = Players:GetPlayers()[1]
		local portals = 0
		if player and Lab.plotIndex(player) then
			local lab = workspace.Playground:FindFirstChild("Lab" .. Lab.plotIndex(player))
			for _, n in { "PortalSolo", "PortalMulti" } do
				if lab and lab:FindFirstChild(n) then
					portals += 1
				end
			end
			assert(portals == 2, portals .. " portals in the lab")
			PortalService.onRequestForTest(player, "List")
			PortalService.onRequestForTest(player, 42)
		end
		return string.format("names \"%s\" (%d distinct of 20); PLAY NOW picks the fullest with room; %d portals in the lab", a, distinct, portals)
	end,
}
