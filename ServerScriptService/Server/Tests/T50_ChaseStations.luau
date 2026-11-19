--!strict
-- Round 5 extras: the NPC Chase (a pack in your own lab, a health bar, knocked out at 0 and back
-- after a second) and the PUT RAGDOLL HERE stations (pads with a launch, a sign each).

local Players = game:GetService("Players")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local ChaseService = require(Systems:WaitForChild("ChaseService"))
local Lab = require(Systems:WaitForChild("Lab"))
local EventService = require(Systems:WaitForChild("EventService"))
local Playground = require(Systems:WaitForChild("Playground"))

local function body(player: Player): string
	local results = {}
	-- Stations in the player's lab.
	local index = Lab.plotIndex(player)
	assert(index, "no lab")
	local lab = workspace:FindFirstChild("Playground") and workspace.Playground:FindFirstChild("Lab" .. index)
	assert(lab, "no lab playground")
	local pads = 0
	for _, p in lab:GetChildren() do
		if p.Name == "StationPad" then
			pads += 1
			assert(typeof(p:GetAttribute("LaunchVelocity")) == "Vector3", "a station pad has no launch")
			assert(p:FindFirstChild("Sign"), "a station pad has no sign")
		end
	end
	assert(pads == #Playground.STATIONS, string.format("%d station pads (want %d)", pads, #Playground.STATIONS))
	table.insert(results, pads .. " PUT RAGDOLL HERE stations")
	-- The chase.
	Lab.sendHome(player)
	task.wait(1)
	local c = ChaseService.start(player, 4)
	assert(c, "the chase did not start in the own lab")
	assert(player:GetAttribute("ChaseHP") == ChaseService.MAX_HP and player:GetAttribute("ChaseMax") == ChaseService.MAX_HP, "no health bar")
	assert(#(c :: any).chasers == 4, "not 4 chasers")
	assert(ChaseService.start(player, 4) == nil, "a second chase at once")
	task.wait(1)
	local chaser = (c :: any).chasers[1].model
	assert(typeof(chaser:GetAttribute("Home")) == "Vector3", "the chasers do not come for the player")
	ChaseService.stopForTest(player)
	assert(player:GetAttribute("ChaseHP") == nil, "the health bar stayed after the chase")
	table.insert(results, "chase: 4 chasers come for you, a health bar, one at a time, gone after")
	-- Visitors (phase 3): in your lab they come, each heading for a thing to try; gone when you go.
	local VisitorService = require(Systems:WaitForChild("VisitorService"))
	VisitorService.tickForTest(player)
	local list = VisitorService.of(player)
	assert(#list == VisitorService.VISITORS, #list .. " visitors (want " .. VisitorService.VISITORS .. ")")
	local spots = VisitorService.spotsOf(player)
	assert(#spots >= 4, "only " .. #spots .. " things to try in the lab")
	for _, v in list do
		local home = v:GetAttribute("Home")
		local near = false
		for _, s in spots do
			if typeof(home) == "Vector3" and (Vector3.new(home.X, 0, home.Z) - Vector3.new(s.Position.X, 0, s.Position.Z)).Magnitude < 1 then
				near = true
			end
		end
		assert(near, "a visitor is not heading for a thing to try")
	end
	VisitorService.clearForTest(player)
	assert(#VisitorService.of(player) == 0, "visitors stayed")
	-- Pedestals and the real cannon (when the place has it).
	local rims = 0
	for _, p in lab:GetChildren() do
		if p.Name == "Pedestal" then
			rims += 1
		end
	end
	assert(rims >= 4, rims .. " pedestals")
	table.insert(results, string.format("%d visitors each going for one of %d things; %d pedestals%s", #list, #spots, rims, if lab:FindFirstChild("CannonModel") then ", real cannon" else ""))
	return table.concat(results, "; ")
end

return {
	name = "chase-stations",
	timeout = 30,
	run = function(): string?
		local started = os.clock()
		while os.clock() - started < 20 and not (Players:GetPlayers()[1] and Players:GetPlayers()[1].Character) do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		if not player then
			return "skipped (no player)"
		end
		EventService.holdForTest(true)
		local ok, result = pcall(body, player)
		EventService.holdForTest(false)
		ChaseService.stopForTest(player)
		if not ok then
			error(result, 0)
		end
		return result
	end,
}
