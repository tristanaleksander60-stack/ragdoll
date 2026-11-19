--!strict
-- The dummies and people live a little (round 2, N1), through the server's own code:
--   nobody stays sunk in the floor: a person pushed down to the hips is standing on the floor again
--     within a couple of seconds (it happened in the rooms' thick floors)
--   a lab's six have their ways: Brave, Coward, Friendly, Chatty, Chatty, Coward
--   a shot near a coward: it runs away from whoever fired (PanicFrom is the shooter); the brave one
--     does not run
--   the friendly one walks up to the player, waves and says hi (GreetUntil), then goes home
--   the chatty two: one walks over to the other and they chat (Chatting 1 and 2), then go home
--   a person in the plaza walks up to a player near it and says hi
-- (Turning to look at a bang, the start it gives and the idle gestures are drawn by every client:
-- DummyLife; checked by hand.)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local Lab = require(Systems:WaitForChild("Lab"))
local CrowdService = require(Systems:WaitForChild("CrowdService"))
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))
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

local function pelvis(model: Model): BasePart
	return model:FindFirstChild("LowerTorso") :: BasePart
end

local function standingAtHome(model: Model?): boolean
	if not model or model:GetAttribute("RagdollState") ~= "Standing" then
		return false
	end
	local home = model:GetAttribute("Home")
	return typeof(home) == "Vector3" and flat(home - pelvis(model).Position).Magnitude < 3
end

local function body(results: { string }, player: Player)
	local character = player.Character :: Model
	local origin = Lab.originFor(player)

	-- 1. Sunk in the floor: lifted out.
	local people = CrowdService.people()
	assert(#people >= 4, "the plaza has too few people")
	-- (Everyone keeps still, and the one picked has stood a second: not just stopping a walk.)
	CrowdService.holdForTest(true)
	local sinker: Model? = nil
	local since: { [Model]: number } = {}
	waitFor(function()
		for _, p in people do
			if p:GetAttribute("RagdollState") == "Standing" then
				since[p] = since[p] or os.clock()
				if os.clock() - since[p] > 1.2 then
					sinker = p
					return true
				end
			else
				since[p] = nil
			end
		end
		return false
	end, 15)
	assert(sinker, "nobody in the plaza is standing")
	local model = sinker :: Model
	local floorY = Lab.plazaOrigin().Y - 0.5
	local feetBefore = pelvis(model).Position.Y - (model:GetAttribute("StandOffset") :: number)
	-- (The baseplate pushes a body out by itself; the rooms' floors did not. Held still (anchored),
	-- so only the lift-out can bring it up.)
	local anchored: { BasePart } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			part.Anchored = true
			table.insert(anchored, part)
		end
	end
	model:PivotTo(model:GetPivot() - Vector3.new(0, 2.2, 0))
	local sunkBy = floorY - (pelvis(model).Position.Y - (model:GetAttribute("StandOffset") :: number))
	local lifted = waitFor(function()
		local feet = pelvis(model).Position.Y - (model:GetAttribute("StandOffset") :: number)
		return feet > floorY - 0.4
	end, 3)
	for _, part in anchored do
		part.Anchored = false
	end
	CrowdService.holdForTest(false)
	assert(sunkBy > 1.5, string.format("the push down did not sink it (%.2f)", sunkBy))
	assert(lifted, "a person sunk to the hips stayed in the floor")
	table.insert(results, string.format("a person pushed %.1f studs into the floor stands on it again (feet %.2f before, back within 0.4)", sunkBy, feetBefore - floorY))

	-- 2. The lab's ways (earlier tests may have knocked them about: home first).
	Lab.liveForTest(true)
	Lab.rewind(player)
	assert(waitFor(function()
		for i = 1, 6 do
			if not standingAtHome(Lab.slotDummy(player, i)) then
				return false
			end
		end
		return true
	end, 15), "the lab's dummies are not all standing at home")
	for i, kind in Lab.PERSONALITY do
		local d = Lab.slotDummy(player, i) :: Model
		assert(d:GetAttribute("Personality") == kind, string.format("slot %d is %s, should be %s", i, tostring(d:GetAttribute("Personality")), kind))
	end
	table.insert(results, "the lab's six: " .. table.concat(Lab.PERSONALITY, ", "))

	-- 3. A shot near a coward: it runs from the shooter; the brave one stands.
	local coward = Lab.slotDummy(player, 2) :: Model
	local brave = Lab.slotDummy(player, 1) :: Model
	character:PivotTo(CFrame.lookAt(origin + Vector3.new(0, 3.5, 6), origin + Vector3.new(0, 3.5, -20)))
	task.wait(0.4)
	local shooter = (character:FindFirstChild("HumanoidRootPart") :: BasePart).Position
	local startDistance = flat(pelvis(coward).Position - shooter).Magnitude
	Lab.heardForTest("Hit", pelvis(coward).Position + Vector3.new(4, 0, 0), 120, "Blaster", player.UserId)
	local from = coward:GetAttribute("PanicFrom")
	assert(typeof(from) == "Vector3" and flat(from - shooter).Magnitude < 3, "the coward did not run from the shooter")
	assert(brave:GetAttribute("PanicFrom") == nil, "the brave one ran from a shot too")
	assert(waitFor(function()
		return coward:GetAttribute("RagdollState") == "Fleeing"
	end, 2), "the coward did not run")
	local ran = 0
	waitFor(function()
		ran = flat(pelvis(coward).Position - shooter).Magnitude - startDistance
		return ran > 6
	end, 3)
	assert(ran > 6, string.format("the coward got only %.1f studs further from the shooter", ran))
	assert(waitFor(function()
		return standingAtHome(coward)
	end, 15), "the coward did not come home after running")
	table.insert(results, string.format("a shot near a coward: it ran %.0f studs from the shooter and came home; the brave one stood", ran))

	-- 3b. A gun pointed at a coward (round 3, M3; fix 1: a gun only carried is not a gun used).
	do
		local Systems = script.Parent.Parent:WaitForChild("Systems")
		local HeldService = require(Systems:WaitForChild("HeldService"))
		local GunThreat = require(ReplicatedStorage.Shared.GunThreat)
		HeldService.onHold(player, "Shove") -- (nothing in the hand while walking up)
		task.wait(0.3)
		local chome = pelvis(coward).Position
		local function stand(at: Vector3, facing: Vector3)
			character:PivotTo(CFrame.lookAt(at, facing))
		end
		stand(chome + Vector3.new(0, 1, 7), chome)
		task.wait(1.2)
		assert(coward:GetAttribute("RagdollState") ~= "Fleeing", "the coward ran from an empty hand")
		-- The gun pointed away: nothing. Pointed at it but never fired (every player starts with the
		-- G17): it stays (DummyLife puts its hands up a while).
		HeldService.onHold(player, "Blaster")
		stand(chome + Vector3.new(0, 1, 7), chome + Vector3.new(0, 1, 20))
		task.wait(1.2)
		assert(coward:GetAttribute("RagdollState") ~= "Fleeing", "the coward ran from a gun pointed away")
		stand(chome + Vector3.new(0, 1, 7), chome)
		task.wait(1.5)
		assert(coward:GetAttribute("RagdollState") ~= "Fleeing", "the coward ran from a gun only carried, 7 studs off")
		-- The gun fires (raised): it runs.
		character:SetAttribute("GunFiredAt", nil)
		GunThreat.markFired(character)
		assert(waitFor(function()
			return coward:GetAttribute("RagdollState") == "Fleeing"
		end, 3), "the coward did not run from a gun that fired, 7 studs away")
		assert(brave:GetAttribute("RagdollState") ~= "Fleeing", "the brave one ran from the gun too")
		-- While that gun stays pointed at its place, it keeps its distance (no back and forth).
		task.wait(GunThreat.RAISED_FOR + 1) -- (the gun only held again)
		local kept = flat(pelvis(coward).Position - chome).Magnitude
		assert(kept > 4, string.format("the coward walked back to a gun pointed at its place (%.1f studs off)", kept))
		local runs = 0
		local wasFleeing = false
		for _ = 1, 30 do
			local f = coward:GetAttribute("RagdollState") == "Fleeing"
			if f and not wasFleeing then
				runs += 1
			end
			wasFleeing = f
			task.wait(0.1)
		end
		assert(runs == 0, string.format("the coward kept running back and forth (%d runs in 3 s)", runs))
		-- Pushed right up to it (under CLOSE_RUN), even unfired: it runs.
		stand(pelvis(coward).Position + Vector3.new(0, 1, 3.5), pelvis(coward).Position)
		character:SetAttribute("GunFiredAt", nil)
		task.wait(2.5)
		assert(waitFor(function()
			return coward:GetAttribute("RagdollState") == "Fleeing"
		end, 3), "the coward did not run from a gun pushed up to it")
		-- A coward walking home looks out too: the gun gone far, it sets off home; a gun fired and
		-- pointed at it on the way: it runs again.
		stand(origin + Vector3.new(0, 3.5, 30), origin)
		assert(waitFor(function()
			return coward:GetAttribute("RagdollState") == "Walking"
		end, 20), "the coward never set off home once the gun was far")
		task.wait(2.6) -- (FLEE_REST: not straight after a run)
		local walkingAt = pelvis(coward).Position
		local stillWalking = coward:GetAttribute("RagdollState") == "Walking"
		if stillWalking then
			stand(walkingAt + Vector3.new(0, 1, 6.5), walkingAt)
			GunThreat.markFired(character)
			assert(waitFor(function()
				return coward:GetAttribute("RagdollState") == "Fleeing"
			end, 2), "a coward walking home did not run from a gun fired at it")
			character:SetAttribute("GunFiredAt", nil)
		end
		-- The gun gone: home again.
		stand(origin + Vector3.new(0, 3.5, 30), origin)
		HeldService.onHold(player, "") -- (doctor mode's empty hand)
		assert(HeldService.holdingOf(player) == nil, "an empty hand still holds a tool")
		assert(waitFor(function()
			return standingAtHome(coward)
		end, 25), "the coward did not come home once the gun was gone")
		table.insert(results, string.format("a gun at a coward 7 studs off: an empty hand, a gun pointed away or only carried did nothing; fired, it ran and kept %.0f studs off while the gun stayed pointed (no back and forth); pushed up to it unfired it ran; walking home, a gun fired at it made it run again (" .. (if stillWalking then "checked" else "it was home before the check") .. "); the brave one stood; the empty hand (doctor mode) holds nothing; home once the gun was gone", kept))
	end

	-- 4. The friendly one says hi.
	local friendly = Lab.slotDummy(player, 3) :: Model
	local fhome = pelvis(friendly).Position
	character:PivotTo(CFrame.new(Vector3.new(fhome.X, origin.Y + 3.5, fhome.Z + 18)))
	task.wait(0.3)
	Lab.socialNowForTest(player, 3)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	assert(waitFor(function()
		local greet = friendly:GetAttribute("GreetUntil")
		return type(greet) == "number" and greet > Workspace:GetServerTimeNow()
	end, 10), "the friendly one did not come and say hi")
	local near = flat(pelvis(friendly).Position - root.Position).Magnitude
	assert(near < 7.5, string.format("it said hi from %.1f studs away", near))
	assert(waitFor(function()
		return friendly:GetAttribute("GreetUntil") == nil and standingAtHome(friendly)
			and flat((friendly:GetAttribute("Home") :: Vector3) - fhome).Magnitude < 1.5
	end, 16), "after saying hi it did not go home")
	table.insert(results, string.format("the friendly one walked up, said hi %.1f studs from the player, went home", near))

	-- 5. The chatty two.
	character:PivotTo(CFrame.new(origin + Vector3.new(0, 3.5, 30)))
	local a, b = Lab.slotDummy(player, 4) :: Model, Lab.slotDummy(player, 5) :: Model
	assert(waitFor(function()
		return standingAtHome(a) and standingAtHome(b)
	end, 10), "the chatty two are not at home")
	Lab.socialNowForTest(player, 4)
	assert(waitFor(function()
		return type(a:GetAttribute("Chatting")) == "number" and type(b:GetAttribute("Chatting")) == "number"
	end, 3), "the chatty two did not start a chat")
	assert(a:GetAttribute("Chatting") ~= b:GetAttribute("Chatting"), "both chatty ones talk at once")
	-- They really walk: out of the row (each more than 5 studs from its own place) and meet there.
	local homeA, homeB = pelvis(a).Position, pelvis(b).Position
	local gap, walkedA, walkedB = math.huge, 0, 0
	assert(waitFor(function()
		gap = flat(pelvis(a).Position - pelvis(b).Position).Magnitude
		walkedA = flat(pelvis(a).Position - homeA).Magnitude
		walkedB = flat(pelvis(b).Position - homeB).Magnitude
		return gap < 5 and walkedA > 5 and walkedB > 5
			and a:GetAttribute("RagdollState") == "Standing" and b:GetAttribute("RagdollState") == "Standing"
	end, 14), string.format("the chatty two never met out of the row (%.1f apart, walked %.1f and %.1f)", gap, walkedA, walkedB))
	table.insert(results, string.format("the chatty two walked %.0f and %.0f studs out of the row and stand %.1f studs apart, taking turns", walkedA, walkedB, gap))
	Lab.liveForTest(false)
	assert(waitFor(function()
		return a:GetAttribute("Chatting") == nil and standingAtHome(a) and standingAtHome(b)
	end, 15), "after the chat they did not go home")

	-- 6. Someone in the plaza says hi.
	task.wait(Places.TRAVEL_GAP + 0.1)
	WorldMaps.travel(player, "Plaza")
	-- (Into the square itself, among its people.)
	local square = CrowdService.center()
	;(player.Character :: Model):PivotTo(CFrame.new(square + Vector3.new(0, 3.5, -12)))
	task.wait(0.5)
	local greeter: Model? = nil
	local best = math.huge
	root = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	for _, p in CrowdService.people() do
		local d = flat(pelvis(p).Position - root.Position).Magnitude
		-- (Far enough that it must walk: under GREET_STOP + 5.5 it waves from where it stands.)
		-- (And nothing in the way: the square's benches and stalls make a walker steer round them,
		-- which can take longer than the test waits; the hello itself is what is tested.)
		local clearParams = RaycastParams.new()
		clearParams.FilterType = Enum.RaycastFilterType.Exclude
		clearParams.FilterDescendantsInstances = { Workspace:FindFirstChild("Dummies") :: Instance, player.Character :: Instance }
		local from = pelvis(p).Position - Vector3.new(0, 1.2, 0) -- (knee high: low benches too)
		local clear = Workspace:Raycast(from, (root.Position - from) * Vector3.new(1, 0, 1), clearParams) == nil
		-- (Nor another person on the line: the walker goes round people slowly on purpose, and the
		-- ray above skips them. Round 3: a crowd member in the way made this a slow, flaky walk.)
		local a, b = flat(pelvis(p).Position), flat(root.Position)
		for _, q in CrowdService.people() do
			if q ~= p then
				local c = flat(pelvis(q).Position)
				local ab = b - a
				local t = math.clamp((c - a):Dot(ab) / math.max(ab:Dot(ab), 1e-3), 0, 1)
				if (c - (a + ab * t)).Magnitude < 3 then
					clear = false
				end
			end
		end
		-- (Unhurt: a person an earlier test broke a leg of, or bled, limps or crawls up at a fraction
		-- of a walk, as it should; the hello is what is tested here.)
		local broken = p:GetAttribute("BrokenJoints")
		local blood = p:GetAttribute("Blood")
		local unhurt = (broken == nil or broken == "") and (blood == nil or (blood :: number) >= 99)
		if clear and unhurt and p:GetAttribute("RagdollState") == "Standing" and d > 12 and d < 30 and d < best then
			greeter, best = p, d
		end
	end
	-- (Nobody where the test needs one, the square's things in the way of all of them (the Christmas
	-- tree and its presents stand there in the season): one unhurt person is set down on a clear
	-- line 18 studs off. The hello is what is tested, not where the crowd happened to be.)
	local setDown = greeter == nil
	if not greeter then
		local clearParams = RaycastParams.new()
		clearParams.FilterType = Enum.RaycastFilterType.Exclude
		clearParams.FilterDescendantsInstances = { Workspace:FindFirstChild("Dummies") :: Instance, player.Character :: Instance }
		clearParams.RespectCanCollide = true
		for _, p in CrowdService.people() do
			local broken = p:GetAttribute("BrokenJoints")
			local blood = p:GetAttribute("Blood")
			if (broken == nil or broken == "") and (blood == nil or (blood :: number) >= 99) and p:GetAttribute("RagdollState") == "Standing" then
				for k = 0, 7 do
					local a = k / 8 * math.pi * 2
					local dir = Vector3.new(math.cos(a), 0, math.sin(a))
					local knee = root.Position - Vector3.new(0, 1.6, 0)
					if Workspace:Raycast(knee, dir * 20, clearParams) == nil then
						local spot = root.Position + dir * 18
						p:PivotTo(CFrame.lookAt(Vector3.new(spot.X, pelvis(p).Position.Y, spot.Z), Vector3.new(root.Position.X, pelvis(p).Position.Y, root.Position.Z)))
						greeter = p
						break
					end
				end
			end
			if greeter then
				break
			end
		end
		task.wait(1.5)
	end
	assert(greeter, "nobody in the plaza near enough to say hi")
	-- (With the starting gun in hand, never fired: a greeter still walks up and says hi.)
	local Held = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("HeldService"))
	Held.onHold(player, "Blaster")
	;(player.Character :: Model):SetAttribute("GunFiredAt", nil)
	local startAt = pelvis(greeter :: Model).Position
	assert(CrowdService.greetForTest(greeter :: Model), "the plaza person found nobody to greet")
	local trail = {}
	assert(waitFor(function()
		local g = (greeter :: Model):GetAttribute("GreetUntil")
		local step = string.format("%s/%s/%.1f", tostring(CrowdService.modeOf(greeter :: Model)), tostring((greeter :: Model):GetAttribute("RagdollState")), flat(pelvis(greeter :: Model).Position - root.Position).Magnitude)
		if trail[#trail] ~= step then
			table.insert(trail, step)
		end
		return type(g) == "number" and g > Workspace:GetServerTimeNow()
	end, 12), string.format("the plaza person (%s, broken %s, blood %s) did not come and say hi: %s", tostring((greeter :: Model):GetAttribute("Personality")),
		tostring((greeter :: Model):GetAttribute("BrokenJoints")), tostring((greeter :: Model):GetAttribute("Blood")), table.concat(trail, " > ")))
	local said = flat(pelvis(greeter :: Model).Position - root.Position).Magnitude
	local walked = flat(pelvis(greeter :: Model).Position - startAt).Magnitude
	assert(walked > 4, string.format("the plaza person said hi without walking up (%.1f studs moved)", walked))
	assert(said < 7.5, string.format("the plaza person said hi from %.1f studs", said))
	Held.onHold(player, "Shove")
	table.insert(results, string.format("a person in the plaza %s walked %.0f studs up to the player holding the G17 and said hi (%.1f away)", if setDown then "(set down 18 studs off: the square's things blocked every line)" else string.format("%.0f studs off", best), walked, said))

	-- 7. A greeter that cannot get closer (a wall in its way) gives up after a few seconds instead of
	-- walking into it for ever.
	local blocked: Model? = nil
	for _, p in CrowdService.people() do
		local d = flat(pelvis(p).Position - root.Position).Magnitude
		if p ~= greeter and p:GetAttribute("RagdollState") == "Standing" and d > 12 and d < 30 and CrowdService.modeOf(p) ~= "Greet" then
			blocked = p
			break
		end
	end
	if blocked then
		local from = pelvis(blocked :: Model).Position
		local toward = flat(root.Position - from).Unit
		local wall = Instance.new("Part")
		wall.Name = "T32Wall"
		wall.Anchored = true
		wall.Size = Vector3.new(16, 8, 1)
		wall.CFrame = CFrame.lookAt(from + toward * 2.5, from + toward * 3.5)
		wall.Parent = Workspace
		local ok, err = pcall(function()
			assert(CrowdService.greetForTest(blocked :: Model), "the blocked person found nobody to greet")
			local started = os.clock()
			assert(waitFor(function()
				return CrowdService.modeOf(blocked :: Model) ~= "Greet"
			end, 9), "a greeter behind a wall never gave up")
			table.insert(results, string.format("a greeter with a wall in its way gave up after %.1f s", os.clock() - started))
		end)
		wall:Destroy()
		if not ok then
			error(err, 0)
		end
	end
end

return {
	name = "npc-life-unsink-cowards-friendly-chatty-greet",
	timeout = 120,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and first.Character:FindFirstChild("HumanoidRootPart") ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		Lab.sendHome(player)
		task.wait(0.5)
		local results = {}
		local ok, err = pcall(body, results, player)
		Lab.liveForTest(false)
		CrowdService.holdForTest(false)
		task.wait(Places.TRAVEL_GAP + 0.1)
		pcall(WorldMaps.travel, player, "Lab")
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
