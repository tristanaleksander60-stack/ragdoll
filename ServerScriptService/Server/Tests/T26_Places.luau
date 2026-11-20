--!strict
-- The places (phase E), through the server's own code:
--   every room is built: a floor the crowd may stand on, walls, an arrival pad, within a part budget
--   travel is checked: unknown or malformed places, too soon after the last trip and a body lying on
--     the floor are refused; a good trip lands the avatar on the pad and sets its Place
--   a room's people come in when a player arrives, dressed for the place, with a mix of
--     personalities, standing on its floor inside its walls; they go quiet when nobody is there and
--     go home when the room is emptied
--   personalities change what happens: a coward runs longer than a brave one from the same punch; the
--     brave one comes back to look; a grumpy one shouts at it; a clown laughs at a body flying past
--     instead of running; a sleepy one nods off while it stands about

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local CrowdService = require(Systems:WaitForChild("CrowdService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local FxService = require(Systems:WaitForChild("FxService"))
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))
local Places = require(ReplicatedStorage.Shared.Places)

local PART_BUDGET = 400 -- per room
local OUTDOOR_BUDGET = 3000 -- per open-air map (real models; streamed, far from the labs)

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.05)
	end
	return check()
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function pelvis(model: Model): BasePart
	return model:FindFirstChild("LowerTorso") :: BasePart
end

local function panicLeft(model: Model): number
	local untilTime = model:GetAttribute("PanicUntil")
	return if type(untilTime) == "number" then untilTime - Workspace:GetServerTimeNow() else 0
end

local STAND = 2.85 -- a standing person's pelvis above the floor

-- Puts a person on the floor at `at` (its height is the floor's), standing, facing a point.
local function place(model: Model, at: Vector3, facing: Vector3)
	assert(model.Parent and model:FindFirstChild("LowerTorso"), string.format("%s (%s) is gone", tostring(model:GetAttribute("PersonName")), tostring(model:GetAttribute("Personality"))))
	-- (Stand on what is there: the open-air city's street is a stud over its floor line.)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, Workspace:FindFirstChild("Dummies") :: Instance }
	local ground = Workspace:Raycast(at + Vector3.new(0, 6, 0), Vector3.new(0, -12, 0), params)
	local y = (if ground then ground.Position.Y else at.Y) + STAND
	local spot = Vector3.new(at.X, y, at.Z)
	DummyControl.reset(model, CFrame.lookAt(spot, Vector3.new(facing.X, y, facing.Z)))
	model:SetAttribute("Home", spot)
	model:SetAttribute("HomeLook", Vector3.new(facing.X, y, facing.Z))
	model:SetAttribute("PanicFrom", nil)
	model:SetAttribute("PanicUntil", nil)
	model:SetAttribute("AngryUntil", nil)
	model:SetAttribute("LaughUntil", nil)
end

local function trip(player: Player, id: string): boolean
	task.wait(Places.TRAVEL_GAP + 0.1)
	local ok = WorldMaps.travel(player, id)
	return ok
end

local function body(results: { string }, player: Player)
	local origin = (Workspace:GetAttribute("LabOrigin") :: Vector3?) or Vector3.zero

	-- 1. The rooms.
	local folder = WorldMaps.folder()
	assert(folder, "no places were built")
	local total = 0
	for _, p in Places.list do
		if p.slot > 0 then
			local model = folder:FindFirstChild(p.id)
			assert(model, p.id .. " was not built")
			local floor = model:FindFirstChild("Floor")
			assert(floor and floor:GetAttribute("Floor") == true, p.id .. " has no floor for the crowd")
			assert(model:FindFirstChild("Arrival"), p.id .. " has no arrival pad")
			-- (v3 phase B: an open-air map has invisible edge walls and the sky for a ceiling.)
			for _, wall in if p.outdoor then { "WallN", "WallS", "WallE", "WallW" } else { "WallN", "WallS", "WallE", "WallW", "Ceiling" } do
				assert(model:FindFirstChild(wall), p.id .. " is missing its " .. wall)
			end
			local count = 0
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					count += 1
					assert(d.Anchored, p.id .. ": a loose part (" .. d.Name .. ")")
				end
			end
			local budget = if p.outdoor then OUTDOOR_BUDGET else PART_BUDGET
			assert(count <= budget, string.format("%s has %d parts (budget %d)", p.id, count, budget))
			total += count
		end
	end
	table.insert(results, string.format("%d rooms built, %d parts", #folder:GetChildren(), total))

	-- 2. Travel is checked.
	local character = player.Character :: Model
	assert(WorldMaps.refusal(player, "Nowhere") ~= nil, "an unknown place was allowed")
	assert(WorldMaps.refusal(player, 42) ~= nil, "a number for a place was allowed")
	assert(WorldMaps.refusal(player, { "City" }) ~= nil, "a table for a place was allowed")
	-- (Set and cleared in the same frame: the avatar never really lies down.)
	character:SetAttribute("RagdollState", "Ragdoll")
	local lying = WorldMaps.refusal(player, "City")
	character:SetAttribute("RagdollState", nil)
	assert(lying == "Get up first to travel!", "travel while lying on the floor was allowed: " .. tostring(lying))
	assert(trip(player, "City"), "a trip to the coffee bar was refused")
	local arrival = WorldMaps.arrival("City") :: CFrame
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	assert(flat(root.Position - arrival.Position).Magnitude < 8, "the avatar did not land on the coffee bar's pad")
	assert(player:GetAttribute("Place") == "City", "the player's Place was not set")
	local again = WorldMaps.refusal(player, "Site")
	assert(again ~= nil, "a second trip straight after the first was allowed")
	table.insert(results, "unknown, malformed, lying down and too-soon trips refused; a trip lands on the pad")

	-- 3. The coffee bar comes to life.
	local cafe = Places.byId.City
	local centre = Places.floorCenter(origin, "City") :: Vector3
	assert(waitFor(function()
		local z = CrowdService.zones().City
		return z.populated and z.active and z.people >= cafe.crowd
	end, 3), "the coffee bar's people did not come in")
	local people = CrowdService.people("City")
	local personalities: { [string]: boolean } = {}
	local kinds = 0
	for _, model in people do
		local role = model:GetAttribute("Role")
		assert(table.find(cafe.roles, role :: string), "someone in the coffee bar is a " .. tostring(role))
		local persona = model:GetAttribute("Personality")
		assert(type(persona) == "string", "someone without a personality")
		if not personalities[persona] then
			personalities[persona] = true
			kinds += 1
		end
	end
	assert(kinds >= 5, string.format("only %d kinds of personality among %d people", kinds, #people))
	task.wait(2.5)
	for _, model in people do
		local p = pelvis(model).Position - centre
		assert(math.abs(p.X) < cafe.size.X / 2 and math.abs(p.Z) < cafe.size.Z / 2, "someone stands outside the coffee bar's walls")
		if not (p.Y > 0 and p.Y < 6) then
			local under = Workspace:Raycast(pelvis(model).Position, Vector3.new(0, -60, 0))
			local what = if under then under.Instance:GetFullName() else "nothing"
			error(string.format("someone is %.1f studs above the floor at (%.0f, %.0f), on %s", p.Y, p.X, p.Z, what))
		end
	end
	assert(not CrowdService.zones().Site.populated, "the building site came to life with nobody in it")
	table.insert(results, string.format("coffee bar: %d people (%s), %d personalities, all on the floor inside", #people, table.concat(cafe.roles, "/"), kinds))

	-- 4. Personalities.
	CrowdService.holdForTest(true)
	local coward, brave, grumpy, clown, sleepy = people[1], people[2], people[3], people[4], people[5]
	-- The rest out of the way, at the west end, facing the wall (they see nothing of the tests).
	for i = 6, #people do
		local at = centre + Vector3.new(-40 + (i % 2) * 5, 0, -6 + math.floor(i / 2) * 6)
		place(people[i], at, at + Vector3.new(-5, 0, 0))
	end
	CrowdService.setPersonalityForTest(coward, "Coward")
	CrowdService.setPersonalityForTest(brave, "Brave")
	CrowdService.setPersonalityForTest(grumpy, "Grumpy")
	CrowdService.setPersonalityForTest(clown, "Clown")
	CrowdService.setPersonalityForTest(sleepy, "Sleepy")
	-- In the open by the door (no tables there), well away from the arrival pad.
	local spot = centre + Vector3.new(-20, 0, -24)
	place(coward, spot + Vector3.new(-10, 0, 0), spot)
	place(brave, spot + Vector3.new(10, 0, 0), spot)
	place(grumpy, spot + Vector3.new(0, 0, -8), spot)
	place(clown, centre + Vector3.new(26, 0, 14), centre + Vector3.new(26, 0, -14))
	place(sleepy, centre + Vector3.new(30, 0, -20), centre)
	task.wait(1.2)
	CrowdService.holdForTest(true, true)
	CrowdService.plainForTest(false)
	FxService.hit(spot, 30, "Punch")
	local runCoward, runBrave = 0, 0
	assert(waitFor(function()
		runCoward = math.max(runCoward, panicLeft(coward))
		runBrave = math.max(runBrave, panicLeft(brave))
		return runCoward > 0 and runBrave > 0
	end, 4), "the coward and the brave one did not both run from a punch 10 studs off")
	assert(runCoward > runBrave + 2, string.format("the coward runs %.1f s, the brave one %.1f s", runCoward, runBrave))
	-- Let them think again: the brave one comes back to look, the grumpy one shouts.
	CrowdService.holdForTest(false)
	local cameBack = waitFor(function()
		local home = brave:GetAttribute("Home")
		return CrowdService.modeOf(brave) == "Walk" and typeof(home) == "Vector3" and flat(home - spot).Magnitude < 9
	end, 9)
	assert(cameBack, "the brave one did not come back to look")
	assert(waitFor(function()
		local angry = grumpy:GetAttribute("AngryUntil")
		return type(angry) == "number" and angry > Workspace:GetServerTimeNow()
	end, 9), "the grumpy one did not shout at it")
	table.insert(results, string.format("punch: coward ran %.1f s, brave %.1f s and came back to look; grumpy shouted HEY!", runCoward, runBrave))

	-- The clown, at a body flying past in front of it (everyone else back at the west end, facing
	-- the wall, so nobody's scream reaches it).
	CrowdService.holdForTest(true)
	for i, model in people do
		if model ~= clown and model.Parent and model:FindFirstChild("LowerTorso") then
			local at = centre + Vector3.new(-40 + (i % 2) * 5, 0, -18 + math.floor(i / 2) * 6)
			place(model, at, at + Vector3.new(-5, 0, 0))
		end
	end
	place(clown, centre + Vector3.new(26, 0, 14), centre + Vector3.new(26, 0, -14))
	task.wait(0.5)
	CrowdService.holdForTest(true, true)
	CrowdService.plainForTest(false)
	task.wait(1)
	local chance = CrowdService.LAUGH_CHANCE
	CrowdService.LAUGH_CHANCE = 1
	local show = centre + Vector3.new(26, 0, 0)
	local flyer = DummyFactory.spawn(show, show + Vector3.xAxis)
	task.wait(0.4)
	local chest = flyer:FindFirstChild("UpperTorso") :: BasePart
	local mass = (flyer:GetAttribute("Mass") :: number?) or 10
	DummyControl.hit(flyer, chest, Vector3.new(0, 70, 0) * mass, chest.Position)
	local laughed = waitFor(function()
		local laugh = clown:GetAttribute("LaughUntil")
		return type(laugh) == "number" and laugh > Workspace:GetServerTimeNow()
	end, 3)
	CrowdService.LAUGH_CHANCE = chance
	local clownRan = panicLeft(clown) > 0
	flyer:Destroy()
	assert(laughed, "the clown did not laugh at a body flying past")
	assert(not clownRan, "the clown laughed and ran")
	table.insert(results, "a clown laughs at a body flying past instead of running")

	-- The sleepy one, left to stand about.
	-- (Whatever it was doing when the crowd was held, it now has a while to stand about.)
	CrowdService.holdForTest(false)
	-- (Kept to itself: a chat started by someone walking past is chance, not what is checked here.)
	CrowdService.aloneForTest(sleepy, true)
	local dozed = false
	for _ = 1, 2 do
		CrowdService.idleForTest(sleepy, 12)
		dozed = waitFor(function()
			return sleepy:GetAttribute("Dozing") == true
		end, 6)
		if dozed then
			break
		end
	end
	CrowdService.aloneForTest(sleepy, false)
	assert(dozed, "the sleepy one never nodded off")
	table.insert(results, "a sleepy one nods off while it stands about")

	-- 5. Leaving: the room goes quiet, and its people go home.
	assert(trip(player, "Lab"), "the trip back to the lab was refused")
	assert(player:GetAttribute("Place") == "Lab", "back at the lab, Place still says " .. tostring(player:GetAttribute("Place")))
	assert(waitFor(function()
		return not CrowdService.zones().City.active
	end, 2), "the coffee bar kept thinking with nobody in it")
	CrowdService.emptyForTest("City")
	assert(#CrowdService.people("City") == 0, "the coffee bar's people did not go home")
	table.insert(results, "back at the lab: the coffee bar stops thinking; emptied, its people go home")
end

return {
	name = "places-travel-rooms-crowds-personalities",
	timeout = 120,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and first.Character:FindFirstChild("HumanoidRootPart") ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player to travel")
		local results = {}
		local ok, err = pcall(body, results, player)
		CrowdService.holdForTest(false)
		if player.Character then
			pcall(WorldMaps.travel, player, "Lab")
			if player:GetAttribute("Place") ~= "Lab" then
				task.wait(Places.TRAVEL_GAP + 0.1)
				pcall(WorldMaps.travel, player, "Lab")
			end
		end
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
