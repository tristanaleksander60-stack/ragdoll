--!strict
-- The people (phase D), through the crowd's own code on this server:
--   a crowd of dressed, named people with a role each, on the plaza behind the spawn
--   they go about: a person told to stroll walks off; two told to meet walk up, face each other and
--     take turns talking
--   panic comes only from what reaches them: a punch heard close by sets off the one who heard it,
--     not someone across the plaza; the scream spreads to a neighbour a beat later; a body flying in
--     front of someone sets them off, the same behind their back does not
--   the hospital chart's record: hits, knock-outs, bones broken and which, on the server for every
--     screen; a broken bone is patched up after a while
--   20 people at once: the server's frame time with the full crowd

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local CrowdService = require(Systems:WaitForChild("CrowdService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local FxService = require(Systems:WaitForChild("FxService"))
local HitService = require(Systems:WaitForChild("HitService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

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

local function panicking(model: Model): boolean
	local untilTime = model:GetAttribute("PanicUntil")
	return type(untilTime) == "number" and untilTime > Workspace:GetServerTimeNow()
end

-- Puts a person somewhere, standing, facing a point, and makes that their spot.
local function place(model: Model, at: Vector3, facing: Vector3)
	local y = pelvis(model).Position.Y
	local spot = Vector3.new(at.X, y, at.Z)
	DummyControl.reset(model, CFrame.lookAt(spot, Vector3.new(facing.X, y, facing.Z)))
	model:SetAttribute("Home", spot)
	model:SetAttribute("HomeLook", Vector3.new(facing.X, y, facing.Z))
	model:SetAttribute("PanicFrom", nil)
	model:SetAttribute("PanicUntil", nil)
end

local function body(results: { string }): ()
	local people = CrowdService.people()
	assert(#people >= CrowdService.SIZE, string.format("only %d people on the plaza", #people))
	local center = CrowdService.center()

	-- 1. Who they are.
	local roles: { [string]: boolean } = {}
	for _, model in people do
		local role = model:GetAttribute("Role")
		assert(type(role) == "string" and type(model:GetAttribute("PersonName")) == "string", "a person without a name or role")
		roles[role :: string] = true
		local outfit = model:FindFirstChild("Outfit")
		assert(outfit and outfit:GetAttribute("Worn") == true, "a person without their outfit")
		for _, d in outfit:GetDescendants() do
			if d:IsA("BasePart") then
				assert(not d.CanCollide and not d.CanQuery and d.Massless, "a piece of an outfit collides, can be tapped or weighs something")
			end
		end
		local chest = model:FindFirstChild("UpperTorso") :: BasePart
		assert(chest.Color ~= Color3.fromRGB(245, 200, 40), "a person still looks like a test dummy")
	end
	local roleCount = 0
	for _ in roles do
		roleCount += 1
	end
	-- Round 4, M11: real clothes on the plaza's roles, and real hair on those without a hat of their
	-- own once it has loaded (it loads in the background at start).
	local haired, hairless = 0, 0
	local hairBy = os.clock() + 10
	repeat
		haired, hairless = 0, 0
		for _, model in people do
			local role = model:GetAttribute("Role")
			assert(model:FindFirstChildOfClass("Shirt") and model:FindFirstChildOfClass("Pants"), tostring(role) .. " without real clothes")
			if not CrowdService.HAT_ROLES[role :: string] then
				local outfit = model:FindFirstChild("Outfit")
				if outfit and outfit:FindFirstChildOfClass("Accessory") then
					haired += 1
				else
					hairless += 1
				end
			end
		end
		if hairless > 0 then
			task.wait(0.5)
		end
	until hairless == 0 or os.clock() > hairBy
	assert(hairless == 0, string.format("%d people without hair", hairless))
	table.insert(results, string.format("%d people, %d roles, all dressed (real shirts and trousers, %d with real hair)", #people, roleCount, haired))

	CrowdService.holdForTest(true)
	local a, b, c = people[1], people[2], people[3]
	-- Everyone else well out of the way of these tests (each to a corner of the plaza).
	for i = 4, #people do
		local angle = (i / #people) * math.pi * 2
		place(people[i], center + Vector3.new(math.cos(angle) * 34, 0, math.sin(angle) * 34), center)
	end

	-- 2. Strolling: a person told to go walks off to the spot.
	place(a, center + Vector3.new(-6, 0, 0), center)
	task.wait(1.5)
	local before = pelvis(a).Position
	a:SetAttribute("Home", before + Vector3.new(0, 0, 14))
	assert(waitFor(function()
		return flat(pelvis(a).Position - before).Magnitude >= 10
	end, 8), "a person sent off did not walk")
	table.insert(results, "strolls to a new spot")

	-- 3. Chatting: two told to meet walk up, face each other, take turns.
	place(a, center + Vector3.new(-8, 0, -6), center)
	place(b, center + Vector3.new(8, 0, -6), center)
	task.wait(1.2)
	CrowdService.holdForTest(false)
	CrowdService.meetForTest(a, b)
	assert(waitFor(function()
		-- (With each other: once the crowd thinks again, either may start a chat with someone else.)
		if CrowdService.partnerOfForTest(a) ~= b then
			CrowdService.meetForTest(a, b)
			return false
		end
		return type(a:GetAttribute("Chatting")) == "number" and type(b:GetAttribute("Chatting")) == "number"
	end, 15), string.format("two people told to meet never started talking (%s/%s, %s/%s, %.1f studs apart, %.1f/%.1f from their spots)",
		tostring(a:GetAttribute("RagdollState")), tostring(b:GetAttribute("RagdollState")),
		tostring(CrowdService.modeOf(a)), tostring(CrowdService.modeOf(b)),
		(pelvis(a).Position - pelvis(b).Position).Magnitude,
		flat((a:GetAttribute("Home") :: Vector3) - pelvis(a).Position).Magnitude,
		flat((b:GetAttribute("Home") :: Vector3) - pelvis(b).Position).Magnitude))
	local pa, pb = pelvis(a), pelvis(b)
	local gap = flat(pb.Position - pa.Position)
	assert(gap.Magnitude <= 6, string.format("they talk %.1f studs apart", gap.Magnitude))
	local faceA = flat(pa.CFrame.LookVector).Unit:Dot(gap.Unit)
	local faceB = flat(pb.CFrame.LookVector).Unit:Dot(-gap.Unit)
	assert(faceA > 0.6 and faceB > 0.6, string.format("they do not face each other (%.2f, %.2f)", faceA, faceB))
	assert(a:GetAttribute("Chatting") ~= b:GetAttribute("Chatting"), "both talk at once (no turns)")
	table.insert(results, string.format("two meet and talk, %.1f studs apart, facing (%.2f/%.2f), taking turns", gap.Magnitude, faceA, faceB))
	CrowdService.holdForTest(true)
	a:SetAttribute("Chatting", nil)
	b:SetAttribute("Chatting", nil)

	-- 4. Hearing: a punch heard 15 studs away sets off the one who heard it; someone 22 studs from
	-- the hearer (beyond the punch's reach, inside a scream's) catches it a beat later; someone across
	-- the plaza stays calm.
	local spot = center + Vector3.new(0, 0, -36)
	place(a, spot + Vector3.new(0, 0, 15), spot) -- hears it
	place(b, spot + Vector3.new(0, 0, 27), spot) -- 27 from the punch, 12 from a: the scream
	place(c, center + Vector3.new(0, 0, 40), center) -- 76 away
	task.wait(1.2)
	CrowdService.holdForTest(true, true) -- noticing on, plans off
	FxService.hit(spot, 30, "Punch")
	assert(waitFor(function()
		return panicking(a)
	end, 2), "a person 15 studs from a punch did not panic")
	assert(waitFor(function()
		return a:GetAttribute("RagdollState") == "Fleeing"
	end, 2), "the panicked person did not run")
	assert(waitFor(function()
		return panicking(b)
	end, 3), "the scream did not spread to someone 12 studs away")
	local delay = (CrowdService.panickedAt(b) or 0) - (CrowdService.panickedAt(a) or 0)
	assert(delay >= 0.3, string.format("the scream spread in %.2f s (all at once)", delay))
	task.wait(1)
	assert(not panicking(c), "someone 76 studs from a punch panicked (the whole plaza at once)")
	local runA = flat(pelvis(a).Position - spot).Magnitude
	-- The lab's own noise does not reach the plaza: TNT among the lab's dummies and the human cannon.
	local labOrigin = (Workspace:GetAttribute("LabOrigin") :: Vector3?) or Vector3.zero
	local tntReach = CrowdService.loudness("Hit", 140, "TNT")
	local tntGap = flat(center - (labOrigin + Vector3.new(0, 0, -22))).Magnitude - 38
	assert(tntReach < tntGap, string.format("TNT at the lab is heard %.0f studs off, the plaza is %.0f away", tntReach, tntGap))
	local playground = Workspace:FindFirstChild("Playground")
	local pad = playground and playground:FindFirstChild("CannonPad", true)
	if pad and pad:IsA("BasePart") then
		local padReach = CrowdService.loudness("Hit", 120, "CannonPad")
		local padGap = flat(center - pad.Position).Magnitude - 38
		assert(padReach < padGap, string.format("the human cannon is heard %.0f studs off, the plaza is %.0f away", padReach, padGap))
	end
	table.insert(results, string.format("punch heard at 15 studs: panic and run (now %.0f studs off); scream spread %.2f s later; 76 studs away stayed calm; lab TNT (%.0f) and the human cannon do not reach the plaza", runA, delay, tntReach))

	-- 5. Sight: a body sent flying in front of someone sets them off; behind their back, not.
	CrowdService.holdForTest(true)
	local seer, blind = people[4], people[5]
	local show = center + Vector3.new(-20, 0, 20)
	place(seer, show + Vector3.new(0, 0, -16), show) -- faces it, 16 away
	place(blind, show + Vector3.new(0, 0, 30), show + Vector3.new(0, 0, 60)) -- back turned, 30 away
	task.wait(1.2)
	CrowdService.holdForTest(true, true)
	local flyer = DummyFactory.spawn(show, show + Vector3.xAxis)
	task.wait(0.4)
	local chest = flyer:FindFirstChild("UpperTorso") :: BasePart
	local mass = (flyer:GetAttribute("Mass") :: number?) or 10
	DummyControl.hit(flyer, chest, Vector3.new(30, 60, 0) * mass, chest.Position)
	assert(waitFor(function()
		return panicking(seer)
	end, 2.5), "a body flying in front of someone did not scare them")
	task.wait(0.8)
	assert(not panicking(blind), "a body flying behind someone's back scared them")
	flyer:Destroy()
	table.insert(results, "a flying body seen in front scares, behind the back does not")
	CrowdService.holdForTest(true)

	-- 6. The hospital record, and patching up.
	local patient = people[6]
	place(patient, center + Vector3.new(10, 0, 10), center)
	task.wait(1.2)
	local hitsBefore = (patient:GetAttribute("Hits") :: number?) or 0
	local leg = patient:FindFirstChild("LeftLowerLeg") :: BasePart
	HitService.applyToy(Toys.byId.Launch, leg, leg.Position, Vector3.new(0, 0, 1))
	assert(((patient:GetAttribute("Hits") :: number?) or 0) == hitsBefore + 1, "the hit was not counted")
	assert(waitFor(function()
		return ((patient:GetAttribute("Bones") :: number?) or 0) >= 1 and ((patient:GetAttribute("KOs") :: number?) or 0) >= 1
	end, 6), string.format("the landing was not on the chart (KOs %s, Bones %s)", tostring(patient:GetAttribute("KOs")), tostring(patient:GetAttribute("Bones"))))
	local joints = patient:GetAttribute("BrokenJoints")
	assert(type(joints) == "string" and string.find(joints, "LeftKnee") ~= nil, "the chart does not say which bone: " .. tostring(joints))
	CrowdService.HEAL_AFTER = 1
	CrowdService.holdForTest(false)
	assert(waitFor(function()
		return ((patient:GetAttribute("Broken") :: number?) or 0) == 0
	end, 25), "a person with a broken bone was never patched up")
	assert(patient:GetAttribute("BrokenJoints") == "", "the chart still lists a bone after patching up")
	table.insert(results, string.format("chart: hits %d, KOs %d, bones %d (%s); patched up after", patient:GetAttribute("Hits"), patient:GetAttribute("KOs"), patient:GetAttribute("Bones"), joints))
end

return {
	name = "crowd-lives-panics-on-cue-hospital-chart",
	timeout = 150,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil
		end, 20)
		local results = {}
		local heal = CrowdService.HEAL_AFTER
		local ok, err = pcall(body, results)
		CrowdService.HEAL_AFTER = heal -- whatever happened in there
		CrowdService.holdForTest(false)
		if not ok then
			error(err, 0)
		end

		-- 8. Twenty people at once: the server's frame time with the full crowd.
		local extra = CrowdService.addForTest(20 - #CrowdService.people())
		task.wait(3)
		local Stats = game:GetService("Stats")
		local heartbeat, physics, samples = 0, 0, 0
		for _ = 1, 30 do
			heartbeat += Stats.HeartbeatTimeMs
			physics += Stats.PhysicsStepTimeMs
			samples += 1
			task.wait(0.1)
		end
		CrowdService.removeForTest(extra)
		heartbeat /= samples
		physics /= samples
		assert(heartbeat < 25, string.format("the server spends %.1f ms a frame with 20 people", heartbeat))
		table.insert(results, string.format("20 people: server frame %.1f ms, physics %.1f ms", heartbeat, physics))
		return table.concat(results, "; ")
	end,
}
