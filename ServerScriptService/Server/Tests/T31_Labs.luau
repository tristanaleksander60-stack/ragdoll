--!strict
-- Every player's own lab (round 2, N1), through the server's own code:
--   the player owns a lab (plot 1, east of the plaza) and their avatar starts in it, facing its row
--     of dummies; the lab's six dummies are theirs (LabOwner, simulated by their client)
--   the plaza in the middle has no dummies of its own; the sign says whose lab it is
--   the Workshop builds in the player's own lab; Stop rewinds only its dummies
--   walking from the lab into the plaza (and back) changes where the player is without a trip;
--     the Maps trips "Plaza", "Lab" and "Lab:<n>" land in the right place, a free lab is refused
--   an event the player sets off happens in their lab while they are in it, in the plaza otherwise
--   respawning puts the avatar back in its own lab

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local Lab = require(Systems:WaitForChild("Lab"))
local BuildService = require(Systems:WaitForChild("BuildService"))
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))
local EventService = require(Systems:WaitForChild("EventService"))
local Places = require(ReplicatedStorage.Shared.Places)

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.1)
	end
	return check()
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function trip(player: Player, id: string): (boolean, string?)
	task.wait(Places.TRAVEL_GAP + 0.1)
	return WorldMaps.travel(player, id)
end

local function body(results: { string }, player: Player)
	-- 1. The player's lab.
	local plot = Lab.plotIndex(player)
	assert(plot == 1, "the first player should have lab 1, has " .. tostring(plot))
	local origin = Lab.originFor(player)
	assert(origin == Lab.plotCenter(1), "the lab is not where plot 1 is")
	local plazaOrigin = Lab.plazaOrigin()
	assert(math.abs(origin.X - plazaOrigin.X - Lab.PLOT_SPACING) < 0.5 and math.abs(origin.Z - plazaOrigin.Z) < 0.5, "lab 1 is not one plot east of the plaza")
	assert(player:GetAttribute("LabPlot") == 1, "the player was not told their lab")
	assert(player:GetAttribute("LabOrigin") == origin, "the player's LabOrigin is not their lab's")
	local focus = player:GetAttribute("LabFocus")
	assert(typeof(focus) == "Vector3" and flat(focus - origin).Magnitude < 25, "LabFocus is not in front of the lab's spawn")
	assert(Lab.plotCenter(2).X < plazaOrigin.X, "lab 2 should be west of the plaza")
	table.insert(results, string.format("lab 1 for the first player, %d studs east of the plaza (lab 2 west)", Lab.PLOT_SPACING))

	-- Its dummies (earlier tests may have knocked them about: home first).
	Lab.rewind(player)
	assert(waitFor(function()
		local list = Lab.dummiesOf(player)
		if #list < 6 then
			return false
		end
		for _, d in list do
			if d:GetAttribute("SimulatedBy") ~= player.UserId then
				return false
			end
		end
		return true
	end, 10), "the lab's six dummies are not there or not simulated by the player")
	local far = 0
	assert(waitFor(function()
		far = 0
		for _, d in Lab.dummiesOf(player) do
			local pelvis = d:FindFirstChild("LowerTorso") :: BasePart
			local away = flat(pelvis.Position - origin).Magnitude
			if away >= 40 then
				far = math.max(far, away)
				Lab.rewind(player) -- (one still on its way back from an earlier test)
			end
		end
		return far == 0
	end, 12), string.format("a lab dummy stands outside its lab (%.0f studs out)", far))
	for _, d in Lab.dummiesOf(player) do
		assert(d:GetAttribute("LabOwner") == player.UserId and d:GetAttribute("Plot") == 1, "a lab dummy is not marked as the player's")
	end
	local plazaDummies = 0
	local folder = Workspace:FindFirstChild("Dummies")
	for _, d in if folder then folder:GetChildren() else {} do
		local pelvis = d:FindFirstChild("LowerTorso")
		if d:GetAttribute("Slot") ~= nil and pelvis and pelvis:IsA("BasePart") and flat(pelvis.Position - plazaOrigin).Magnitude < 60 then
			plazaDummies += 1
		end
	end
	assert(plazaDummies == 0, plazaDummies .. " lab dummies stand in the plaza")
	local labs = Workspace:FindFirstChild("Labs")
	local sign = labs and labs:FindFirstChild("Lab1") and (labs :: any).Lab1:FindFirstChild("LabSign")
	local label = sign and sign:FindFirstChildWhichIsA("SurfaceGui") and (sign :: any):FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
	assert(label and label.Text == string.upper(player.DisplayName) .. "'S LAB", "the sign does not name the owner: " .. tostring(label and label.Text))
	local free = labs and (labs :: any):FindFirstChild("Lab2")
	local freeLabel = free and free:FindFirstChild("LabSign") and free.LabSign:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
	assert(freeLabel and freeLabel.Text == "FREE LAB", "an empty lab's sign does not say FREE LAB")
	local playground = Workspace:FindFirstChild("Playground")
	assert(playground and playground:FindFirstChild("Plaza") and playground:FindFirstChild("Lab1"), "the plaza's and lab 1's playgrounds are not both built")
	assert(not playground:FindFirstChild("Lab2"), "a playground was built in a lab nobody owns")
	table.insert(results, string.format("6 dummies in it, the player's (LabOwner, simulated by them); none in the plaza; the sign reads %q, an empty lab's FREE LAB; playgrounds in the plaza and lab 1 only", label.Text))

	-- 2. The Workshop builds there.
	local buildOrigin = BuildService.originFor(player)
	assert(flat(buildOrigin - origin).Magnitude < 1 and buildOrigin.Y == 0, "the Workshop does not build in the player's lab")
	table.insert(results, "the Workshop builds in the player's lab")

	-- 3. Where the player is: walking and trips.
	assert(trip(player, "Plaza"), "the trip to the plaza was refused")
	assert(player:GetAttribute("Place") == "Plaza", "after the trip to the plaza, Place says " .. tostring(player:GetAttribute("Place")))
	local root = assert(rootOf(player), "no avatar")
	assert(flat(root.Position - plazaOrigin).Magnitude < 60, "the plaza trip did not land in the plaza")
	-- Walk (well, step) into the own lab: no trip, yet Place follows.
	player.Character:PivotTo(CFrame.new(origin + Vector3.new(0, 3.5, 30)))
	assert(waitFor(function()
		return player:GetAttribute("Place") == "Lab"
	end, 2), "stepping into the own lab did not make Place 'Lab' (" .. tostring(player:GetAttribute("Place")) .. ")")
	-- Labs are private (round 3, M1): stepping into one that is not yours (here nobody's) puts you
	-- back in the plaza, and the client is told.
	local toldBefore = player:GetAttribute("PrivateLabAt")
	player.Character:PivotTo(CFrame.new(Lab.plotCenter(2) + Vector3.new(0, 3.5, 30)))
	assert(waitFor(function()
		local r = rootOf(player)
		return r ~= nil and flat(r.Position - plazaOrigin).Magnitude < 60 and player:GetAttribute("PrivateLabAt") ~= toldBefore
	end, 2), "stepping into lab 2 (not yours) did not put you back in the plaza")
	assert(waitFor(function()
		return player:GetAttribute("Place") == "Plaza"
	end, 2), "after being put back, Place is not 'Plaza' (" .. tostring(player:GetAttribute("Place")) .. ")")
	assert(Lab.mayEnter(player, 1) and not Lab.mayEnter(player, 2), "mayEnter: own lab yes, a free one no")
	-- The ground past the last lab on each side is that lab's (never a second plaza).
	local Zones = require(ReplicatedStorage.Shared.Zones)
	local farEast = Vector3.new(Zones.plotCenterX(Zones.PLOT_COUNT - 1) + Zones.PLOT_SPACING * 2, plazaOrigin.Y, plazaOrigin.Z)
	local farWest = Vector3.new(Zones.plotCenterX(Zones.PLOT_COUNT) - Zones.PLOT_SPACING * 2, plazaOrigin.Y, plazaOrigin.Z)
	assert(Zones.plotAt(farEast) == Zones.PLOT_COUNT - 1 and Zones.plotAt(farWest) == Zones.PLOT_COUNT, string.format("past the last labs: %s and %s", tostring(Zones.plotAt(farEast)), tostring(Zones.plotAt(farWest))))
	player.Character:PivotTo(CFrame.new(plazaOrigin + Vector3.new(0, 3.5, 40)))
	assert(waitFor(function()
		return player:GetAttribute("Place") == "Plaza"
	end, 2), "stepping into the plaza did not make Place 'Plaza'")
	table.insert(results, "walking: own lab -> Place Lab, lab 2 (private, not yours) -> put back in the plaza and told, the plaza -> Plaza (no trip)")
	-- Nothing in a lab you may not enter can be touched from the plaza: a tap on its ground is
	-- refused ("Private"), a blast by the edge reaches a dummy on the plaza side and not the one
	-- just inside the lab; your own lab can be reached.
	do
		local HitService = require(Systems:WaitForChild("HitService"))
		local Blasts = require(Systems:WaitForChild("Blasts"))
		local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
		local floor = Workspace:FindFirstChild("Baseplate") :: BasePart
		local westEdge = plazaOrigin.X - Lab.PLOT_HALF
		local z = plazaOrigin.Z + 40
		player.Character:PivotTo(CFrame.new(Vector3.new(westEdge + 40, plazaOrigin.Y + 3.5, z)))
		task.wait(0.3)
		HitService.lastRefusal[player] = nil
		HitService.onRequest(player, floor, Vector3.new(westEdge - 10, plazaOrigin.Y - 0.5, z), Vector3.new(-1, 0, 0), "Punch")
		local refusal = HitService.lastRefusal[player]
		assert(refusal and refusal.reason == "Private", "a tap into lab 2 was not refused as private: " .. tostring(refusal and refusal.reason))
		HitService.lastRefusal[player] = nil
		HitService.onRequest(player, floor, Vector3.new(Lab.plotCenter(1).X - 60, plazaOrigin.Y - 0.5, z), Vector3.new(1, 0, 0), "Punch")
		local own = HitService.lastRefusal[player]
		assert(not own or own.reason ~= "Private", "a tap into the own lab was refused as private")
		local inside = DummyFactory.spawn(Vector3.new(westEdge - 3, plazaOrigin.Y, z + 8), nil)
		local outside = DummyFactory.spawn(Vector3.new(westEdge + 9, plazaOrigin.Y, z + 8), nil)
		task.wait(0.5)
		local insidePelvis = inside:FindFirstChild("LowerTorso") :: BasePart?
		local Zones = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Zones"))
		local where = if insidePelvis then string.format(" (before the blast its pelvis was %.1f studs inside the line, plot %s, %.1f studs from the blast; LabPlot of the player %s)", westEdge - insidePelvis.Position.X, tostring(Zones.plotAt(insidePelvis.Position)), (insidePelvis.Position - Vector3.new(westEdge + 3, plazaOrigin.Y, z + 8)).Magnitude, tostring(player:GetAttribute("LabPlot"))) else " (no pelvis)"
		Blasts.explode(Vector3.new(westEdge + 3, plazaOrigin.Y, z + 8), nil, player)
		task.wait(0.3)
		local insideHit = inside:GetAttribute("Wounds")
		local outsideHit = outside:GetAttribute("Wounds")
		inside:Destroy()
		outside:Destroy()
		assert(type(outsideHit) == "string" and outsideHit ~= "", "the blast did not reach the dummy on the plaza side")
		assert(insideHit == nil or insideHit == "", "a blast from the plaza reached into lab 2: " .. tostring(insideHit) .. where)
		table.insert(results, "a lab you may not enter: a tap on its ground refused (Private), a blast by the edge hurts the plaza dummy and not the lab's; the own lab is reached")
	end
	local ok, why = trip(player, "Lab:2")
	assert(not ok and why == "Nobody has that lab now", "a trip to a free lab was not refused: " .. tostring(why))
	ok, why = trip(player, "Lab:x")
	assert(not ok and why == "Unknown place", "a malformed lab id was not refused: " .. tostring(why))
	assert(trip(player, "Lab:1"), "a trip to the player's own lab by number was refused")
	assert(player:GetAttribute("Place") == "Lab", "the own lab by number should count as 'Lab'")
	root = assert(rootOf(player), "no avatar")
	assert(flat(root.Position - origin).Magnitude < 8, "the trip home did not land by the lab's spawn")
	local look = root.CFrame.LookVector
	assert(look.Z < -0.9, "back home the avatar does not face the dummies")
	ok, why = WorldMaps.travel(player, "Lab:1")
	assert(not ok and why == "Wait a moment", "a second trip home by number at once was not refused: " .. tostring(why))
	table.insert(results, "trips: Plaza lands in the plaza; Lab:2 (free) refused; Lab:x refused; Lab:1 = own lab, by its spawn facing the dummies, and like any trip not again at once")

	-- 3b. A lab coming free goes to someone living in the plaza; their build moves with them.
	assert(BuildService.request(player, "clear", nil))
	assert(BuildService.request(player, "place", { item = "Block", pos = Vector3.new(10, 1, 30), rot = 0, parent = 0 }))
	Lab.releaseForTest(player)
	assert(Lab.plotIndex(player) == nil and player:GetAttribute("LabPlot") == nil, "the player still has a lab after giving it back")
	assert(flat(BuildService.originFor(player) - Lab.plazaOrigin()).Magnitude < 1, "without a lab the Workshop does not build in the plaza")
	-- Without a lab the rooms are still there to go to (no number is "yours").
	assert(trip(player, "Island"), "a player without a lab could not go to the island")
	assert(player:GetAttribute("Place") == "Island", "a player without a lab went to the island but Place says " .. tostring(player:GetAttribute("Place")))
	local hangarRoot = assert(rootOf(player), "no avatar")
	assert(hangarRoot.Position.Y > Lab.plazaOrigin().Y + 1000, "a player without a lab did not land up in the island")
	assert(trip(player, "Lab"), "a player without a lab could not go to 'My Lab'")
	assert(player:GetAttribute("Place") == "Plaza", "'My Lab' without a lab should land in the plaza, Place says " .. tostring(player:GetAttribute("Place")))
	assert(#Lab.dummiesOf(player) == 0, "a given-back lab kept its dummies")
	local freed = (Workspace:FindFirstChild("Labs") :: any).Lab1.LabSign:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
	assert(freed.Text == "FREE LAB", "a given-back lab's sign still names its owner")
	Lab.handOnForTest()
	assert(Lab.plotIndex(player) == 1 and player:GetAttribute("LabPlot") == 1, "the freed lab was not handed to the player in the plaza")
	assert(waitFor(function()
		return #Lab.dummiesOf(player) == 6
	end, 6), "the handed-on lab has no dummies")
	local block = BuildService.modelsOf(player)[1]
	assert(block and flat(block:GetPivot().Position - (origin + Vector3.new(10, 0, 30))).Magnitude < 2, "the build did not move into the handed-on lab")
	assert(BuildService.request(player, "clear", nil))
	task.wait(Places.TRAVEL_GAP + 0.1)
	assert(WorldMaps.travel(player, "Lab"), "the trip home to the handed-on lab was refused")
	table.insert(results, "a lab given back is FREE LAB with no dummies, its player builds in the plaza, still goes to the island (and 'My Lab' lands in the plaza); handed on to a player in the plaza: their lab, its dummies, their build moved in")

	-- 4. Events happen where the player is: their lab, or the plaza.
	local here = EventService.whereFor(player.UserId)
	assert(flat(here - Lab.focusFor(player)).Magnitude < 1, "an event the player set off at home did not happen in their lab")
	assert(trip(player, "Plaza"), "the trip to the plaza was refused")
	local there = EventService.whereFor(player.UserId)
	assert(flat(there - Lab.plazaFocus()).Magnitude < 1, "an event the player set off from the plaza did not happen in the plaza")
	local nobody = EventService.whereFor(nil)
	assert(flat(nobody - Lab.plazaFocus()).Magnitude < 1, "an event for nobody did not happen in the plaza")
	table.insert(results, "events: at home in the player's lab; from the plaza (or for nobody here) in the plaza")

	-- 5. Respawn: back in the own lab.
	player:LoadCharacter()
	assert(waitFor(function()
		local r = rootOf(player)
		return r ~= nil and flat(r.Position - origin).Magnitude < 8
	end, 8), "after a respawn the avatar is not in its own lab")
	assert(waitFor(function()
		return player:GetAttribute("Place") == "Lab"
	end, 2), "after a respawn Place is not 'Lab'")
	table.insert(results, "a respawn starts in the own lab")
end

return {
	name = "own-labs-spawn-walk-travel-events",
	timeout = 90,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and first.Character:FindFirstChild("HumanoidRootPart") ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		local results = {}
		local ok, err = pcall(body, results, player)
		if player.Character and player:GetAttribute("Place") ~= "Lab" then
			task.wait(Places.TRAVEL_GAP + 0.1)
			pcall(WorldMaps.travel, player, "Lab")
		end
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
