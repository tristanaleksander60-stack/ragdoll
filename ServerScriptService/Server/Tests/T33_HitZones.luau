--!strict
-- Hit zones, organs, blood and pulse (round 2, N2), through the server's own code:
--   Anatomy finds the organ under a point: heart, lungs, liver, spine, brain, neck, the femoral
--     artery high on the inside of the thigh, the limbs; the pulse races as blood runs out, then fails
--   a Blaster shot on a dummy opens a wound there: blood drops, the pulse answers, the wound is
--     listed (Wounds), the body bleeds over time (Bleeding) and the hitter's line reads
--     "<organ> · <n>% blood · pulse <n>"
--   out cold below 45%: it stays down (does not get up) until patched up, then gets up
--   a brain shot: dead on the spot ("no pulse", the blood not clamped), green and lying until
--     REVIVE_AFTER, then its colour back and coming round (10 Nov 2026)
--   every gun round to the head (face, side, back, top) kills on the spot; a blade kills only in the
--     brain; blows to the head only stun (round 4, M10)
--   a limb cut off (Config.SEVERING): its joint lets go, purple caps, the body stays down; the line
--     says "<limb> severed"; with SEVERING off nothing is cut
--   a blast wounds every body in reach (Blast)
--   freezing leaves a body missing a limb alone; the Heal tool puts the limb back and closes
--     every wound (good as new)
--   blunt blows bruise: a punch on the top of the head is the skull (never the brain, never dead),
--     a slap on the heart clots within seconds and the blood comes back; eight Mega Slaps (the
--     heaviest blow) on the heart never put the body down (blows stop at 50% blood; the pulse dips,
--     never stops); thirty pokes after a heart shot never push the heart wound out of the list
--     (it keeps bleeding)
--   a gun fired at nothing: checked (a gun, its pace, the reach) and heard: a coward runs from it
--   a wound behind a wall: the server's line from the hitter's head meets the wall, so the spot is
--     guarded (no brain, heart or big artery: the heart shot becomes a lung); another body in the
--     way is looked past, and so is an invisible part; a G17 round from the player to the face kills

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local Lab = require(Systems:WaitForChild("Lab"))
local HitService = require(Systems:WaitForChild("HitService"))
local VitalsService = require(Systems:WaitForChild("VitalsService"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local Blasts = require(Systems:WaitForChild("Blasts"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local Shared = ReplicatedStorage.Shared
local Anatomy = require(Shared.Anatomy)
local Toys = require(Shared.Toys)
local Config = require(Shared.Config)
-- (Release fix: with Config.MILD_TEXT the hit line names the body region, "Chest" for the heart.)
local function shownAs(zoneId: string): string
	return if Config.MILD_TEXT then Anatomy.mildLabel(zoneId) else zoneId
end

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

local function part(model: Model, name: string): BasePart
	return model:FindFirstChild(name) :: BasePart
end

-- A point on a part from its -1..1 box coordinates.
local function at(p: BasePart, x: number, y: number, z: number): Vector3
	return p.CFrame:PointToWorldSpace(Vector3.new(x * p.Size.X / 2, y * p.Size.Y / 2, z * p.Size.Z / 2))
end

local function zoneOf(p: BasePart, x: number, y: number, z: number): string
	local zone = Anatomy.zoneAt(p.Name, p.CFrame:PointToObjectSpace(at(p, x, y, z)), p.Size)
	return if zone then zone.id else "none"
end

local spawned: { Model } = {}
local function body(spot: Vector3): Model
	local m = DummyFactory.spawn(spot, spot - Vector3.zAxis) -- (the server simulates it)
	table.insert(spawned, m)
	task.wait(0.6)
	return m
end

local function run(results: { string }, player: Player)
	-- 1. The map of the body.
	local probe = body(Lab.plazaOrigin() + Vector3.new(-20, 0, -28))
	local chest, head, thigh = part(probe, "UpperTorso"), part(probe, "Head"), part(probe, "LeftUpperLeg")
	local checks = {
		{ zoneOf(chest, -0.2, 0.2, -0.8), "Heart" },
		{ zoneOf(chest, -0.75, 0.4, -0.8), "LeftLung" },
		{ zoneOf(chest, 0.75, 0.4, -0.8), "RightLung" },
		{ zoneOf(chest, 0.6, -0.6, -0.8), "Liver" },
		{ zoneOf(chest, -0.5, -0.6, -0.8), "Stomach" },
		{ zoneOf(chest, 0, 0, 0.9), "Spine" },
		{ zoneOf(chest, 0, 0.8, -0.8), "Aorta" },
		{ zoneOf(head, 0, 0.7, -0.9), "Brain" },
		{ zoneOf(head, 0, -0.8, 0), "Neck" },
		{ zoneOf(thigh, 0.7, 0.5, -0.8), "LeftFemoral" },
		{ zoneOf(thigh, -0.7, -0.3, -0.8), "LeftThigh" },
		{ zoneOf(part(probe, "RightHand"), 0, 0, 0), "RightHand" },
	}
	for _, c in checks do
		assert(c[1] == c[2], string.format("expected %s, found %s", c[2], c[1]))
	end
	local rest = 75
	local p90, p60, p30, p15 = Anatomy.pulseFor(rest, 95), Anatomy.pulseFor(rest, 60), Anatomy.pulseFor(rest, 30), Anatomy.pulseFor(rest, 15)
	assert(Anatomy.pulseFor(rest, 100) == rest and p90 < 100 and p60 > 140 and p30 < p60 and p15 == 0, string.format("the pulse does not race then fail (%.0f, %.0f, %.0f, %.0f)", p90, p60, p30, p15))
	table.insert(results, string.format("%d zones found where they are (heart left of the middle, lungs, liver, spine at the back, brain, neck, femoral artery inside the thigh); pulse at 95/60/30/15%% blood: %.0f/%.0f/%.0f/%.0f", #checks, p90, p60, p30, p15))

	-- 2. A shot on the heart.
	VitalsService.liveForTest(true)
	local blaster = Toys.byId.Blaster
	local dummy = body(Lab.plazaOrigin() + Vector3.new(-12, 0, -28))
	chest = part(dummy, "UpperTorso")
	local state = HitService.applyToy(blaster, chest, at(chest, -0.2, 0.2, -0.95), Vector3.new(0, 0, 1))
	assert(state, "the shot did not land")
	local line, zone = VitalsService.wound(dummy, chest, at(chest, -0.2, 0.2, -0.95), nil, 1)
	assert(zone and zone.id == "Heart", "the second shot was not on the heart")
	assert(line and string.match(line, "^" .. shownAs("Heart") .. " \u{00B7} %d+%% blood \u{00B7} pulse %d+$"), "the line reads: " .. tostring(line))
	local blood0 = dummy:GetAttribute("Blood") :: number
	assert(blood0 < 100 and blood0 > 60, "blood after two heart shots: " .. tostring(blood0))
	assert(string.find(dummy:GetAttribute("Wounds") :: string, "Heart@", 1, true), "the wound is not listed")
	assert(waitFor(function()
		return dummy:GetAttribute("Bleeding") == true
	end, 1), "a heart wound does not bleed")
	task.wait(2)
	local blood1 = dummy:GetAttribute("Blood") :: number
	assert(blood1 <= blood0 - 10, string.format("a heart wound bled only %d%% in 2 s", blood0 - blood1))
	table.insert(results, string.format("two Blaster rounds on the heart: %q; %d%% blood, bleeding to %d%% 2 s later", line, blood0, blood1))

	-- 3. Out cold below 45%: down until patched up.
	assert(waitFor(function()
		return dummy:GetAttribute("Vital") == "Unconscious" or dummy:GetAttribute("Vital") == "Dead"
	end, 8), "the bleeding body never went out cold")
	-- (It goes limp on the body's next think, a moment after the vitals say so.)
	local downState = dummy:GetAttribute("RagdollState")
	waitFor(function()
		downState = dummy:GetAttribute("RagdollState")
		return downState == "Ragdoll" or downState == "Out"
	end, 2)
	assert(downState == "Ragdoll" or downState == "Out", "out cold but " .. tostring(downState))
	VitalsService.patchUpForTest(dummy)
	assert(dummy:GetAttribute("Blood") == 100 and dummy:GetAttribute("Vital") == "Alive", "patching up did not restore it")
	assert(waitFor(function()
		return dummy:GetAttribute("RagdollState") == "Standing"
	end, 8), "the patched-up body did not get up")
	table.insert(results, "out cold under 45% (lay " .. tostring(downState) .. "), patched up: 100%, up again")

	-- 4. A brain shot: dead, and gone.
	-- Round 4, M10: the lethal brain hit must land in the SAME update that writes Vital=Dead.
	-- No waitFor loop here — the attributes must already read Dead by the time wound() returns.
	local head2 = part(dummy, "Head")
	local brainLine = VitalsService.wound(dummy, head2, at(head2, 0, 0.7, -0.9), nil, 1)
	assert(brainLine and string.find(brainLine, shownAs("Brain"), 1, true), "not the brain: " .. tostring(brainLine))
	assert(dummy:GetAttribute("Vital") == "Dead", "a brain shot did not kill this update (Vital=" .. tostring(dummy:GetAttribute("Vital")) .. ")")
	assert(dummy:GetAttribute("Pulse") == 0, "a brain shot left the pulse at " .. tostring(dummy:GetAttribute("Pulse")) .. ", not 0")
	assert(dummy:GetAttribute("DiedAt") ~= nil, "a brain shot did not stamp DiedAt (the monitor flatlines from this)")
	assert(brainLine and string.find(brainLine, "no pulse", 1, true), "a brain shot's line still shows a pulse: " .. tostring(brainLine))
	-- (Round 4, M10: the blood the wound left, not clamped to 15%; the monitor flat at once.)
	local deadBlood = dummy:GetAttribute("Blood") :: number
	assert(deadBlood > Anatomy.DEAD_AT, "a brain shot clamped the blood to " .. tostring(deadBlood) .. "%")
	assert(dummy:GetAttribute("DeathCause") == "Brain", "a brain kill has DeathCause " .. tostring(dummy:GetAttribute("DeathCause")))
	local deadLine = VitalsService.wound(dummy, part(dummy, "UpperTorso"), part(dummy, "UpperTorso").Position, nil, 1)
	assert(deadLine and string.find(deadLine, "no pulse", 1, true), "a dead body's line: " .. tostring(deadLine))
	-- It drops on the body's next think (as out cold above), then stays down: still there and dead
	-- at DEAD_HOLD - 2 s (VitalsService.ageForTest: no real 60 s wait), never stood up, then gone by
	-- DEAD_HOLD + 2.
	assert(waitFor(function()
		local s = dummy:GetAttribute("RagdollState")
		return s == "Ragdoll" or s == "Out"
	end, 2), "the dead body never went down (" .. tostring(dummy:GetAttribute("RagdollState")) .. ")")
	-- (10 Nov 2026, the owner: a dead body turns green, and after REVIVE_AFTER s gets its colour back
	-- and comes round slowly, never standing while dead.)
	local chest = part(dummy, "UpperTorso")
	assert(waitFor(function()
		local c = chest.Color
		return c.G > c.R + 0.15 and c.G > c.B + 0.15
	end, 2), "the dead body did not turn green: " .. tostring(chest.Color))
	local green = chest.Color
	VitalsService.ageForTest(dummy, VitalsService.REVIVE_AFTER - 2)
	local holdUntil = os.clock() + 1
	while os.clock() < holdUntil do
		assert(dummy.Parent ~= nil and dummy:GetAttribute("Vital") == "Dead", "the dead body came round before REVIVE_AFTER")
		assert(dummy:GetAttribute("RagdollState") ~= "Standing", "the dead body stood up while dead")
		task.wait(0.1)
	end
	VitalsService.ageForTest(dummy, 2)
	assert(waitFor(function()
		return dummy:GetAttribute("Vital") ~= "Dead"
	end, 2), "the dead body did not come round by REVIVE_AFTER + 2 s")
	assert(dummy.Parent ~= nil and chest.Color ~= green, "it came round still green, or was gone")
	table.insert(results, string.format("a brain shot: dead this update (%q, %d%% blood, DeathCause Brain), green and lying until %d s, then its colour back and coming round (%s)", tostring(deadLine), deadBlood, VitalsService.REVIVE_AFTER, tostring(dummy:GetAttribute("Vital"))))

	-- 4b. Round 4, M10: every gun round to the head kills on the spot (face, side, back, top: Jaw,
	-- Skull, Brain), the NailGun too; blades kill only in the brain; blows only stun.
	local headTests = 0
	local function headHit(toy: Toys.Toy, x: number, y: number, z: number): (Model, string)
		local victim = body(Lab.plazaOrigin() + Vector3.new(-20 + headTests % 5 * 4, 0, -36))
		headTests += 1
		local h = part(victim, "Head")
		HitService.applyToy(toy, h, at(h, x, y, z), Vector3.new(0, 0, 1))
		return victim, zoneOf(h, x, y, z)
	end
	local points = { { 0, 0, -0.95 }, { 0.95, 0, 0 }, { 0, -0.3, 0.95 }, { 0, 0.9, 0 } }
	local guns = 0
	for _, toy in Toys.list do
		if toy.gun then
			guns += 1
			for _, p in points do
				local victim, zoneId = headHit(toy, p[1], p[2], p[3])
				assert(Anatomy.HEADSHOT[zoneId], "a head point read as " .. zoneId)
				assert(victim:GetAttribute("Vital") == "Dead" and victim:GetAttribute("Pulse") == 0, string.format("a %s round in the %s left it %s", toy.id, zoneId, tostring(victim:GetAttribute("Vital"))))
				victim:Destroy()
			end
		end
	end
	assert(not Anatomy.HEADSHOT.Neck, "the neck counts as a headshot")
	local katanaBrain = headHit(Toys.byId.Katana, 0, 0.7, -0.9)
	assert(katanaBrain:GetAttribute("Vital") == "Dead", "a Katana to the brain did not kill")
	local katanaJaw = headHit(Toys.byId.Katana, 0, 0, -0.95)
	assert(katanaJaw:GetAttribute("Vital") ~= "Dead", "a Katana to the jaw killed")
	katanaBrain:Destroy()
	katanaJaw:Destroy()
	local stunned: { Model } = {}
	-- (A body launched out of the world by a big blow is no death: only a dead one would fail.)
	for _, id in { "Punch", "Bat", "Hammer", "Pan", "MegaSlap", "Golf" } do
		local victim = headHit(Toys.byId[id], 0, 0.7, -0.9)
		local wounds = (victim:GetAttribute("Wounds") :: string?) or ""
		assert(victim:GetAttribute("Vital") ~= "Dead" and string.find(wounds, "Skull@", 1, true), string.format("a %s on the top of the head: %s, %s", id, tostring(victim:GetAttribute("Vital")), wounds))
		table.insert(stunned, victim)
	end
	assert(waitFor(function()
		for _, victim in stunned do
			if victim.Parent and victim:GetAttribute("Vital") ~= "Alive" then
				return false
			end
		end
		return true
	end, 5 + 1 + 1), "a blow to the head kept a body out longer than its knock-out")
	for _, victim in stunned do
		victim:Destroy()
	end
	table.insert(results, string.format("%d guns x 4 head points (face, side, back, top): dead on the spot; a Katana kills in the brain, not the jaw; 6 blows to the head stun, never kill, all awake within the knock-out", guns))

	-- 5. A limb off.
	local victim = body(Lab.plazaOrigin() + Vector3.new(-4, 0, -28))
	local forearm = part(victim, "LeftLowerArm")
	local cutLine = VitalsService.wound(victim, forearm, forearm.Position, nil, 1, { sever = 1 })
	if Config.SEVERING then
		assert(cutLine and string.find(cutLine, "Left arm severed", 1, true), "the cut line reads: " .. tostring(cutLine))
		local shoulder = part(victim, "LeftUpperArm"):FindFirstChild("LeftShoulder") :: Constraint
		local socket = part(victim, "LeftUpperArm"):FindFirstChild("LeftShoulderBallSocket") :: Constraint
		assert(shoulder and not shoulder.Enabled and socket and not socket.Enabled, "the shoulder still holds the arm")
		assert(victim:GetAttribute("Severed") == "LeftArm", "Severed: " .. tostring(victim:GetAttribute("Severed")))
		local caps = 0
		for _, d in victim:GetDescendants() do
			if d.Name == "Stump" then
				caps += 1
			end
		end
		assert(caps == 2, caps .. " stump caps")
		-- (An arm off never puts the body down on its own (round 3, M2): it stays up, bleeding hard.)
		task.wait(1)
		assert(victim:GetAttribute("Vital") == "Alive", "a body missing an arm went down at once: " .. tostring(victim:GetAttribute("Vital")))
		table.insert(results, string.format("a hit with sever 1 on the forearm: %q, shoulder joint off, 2 purple caps, still up (an arm alone never fells)", cutLine))
		-- Freezing leaves it alone; healing puts the arm back.
		DummyControl.freeze(victim)
		assert(victim:GetAttribute("Frozen") ~= true, "a body missing an arm was frozen")
		assert(not shoulder.Enabled and not socket.Enabled, "freezing put the arm back")
		VitalsService.heal(victim)
		assert(shoulder.Enabled and socket.Enabled, "healing did not put the arm back")
		local left = 0
		for _, d in victim:GetDescendants() do
			if d.Name == "Stump" then
				left += 1
			end
		end
		assert(left == 0, left .. " stump caps after healing")
		assert(victim:GetAttribute("Severed") == nil and victim:GetAttribute("Vital") == "Alive" and victim:GetAttribute("Blood") == 100, "healed but " .. tostring(victim:GetAttribute("Vital")) .. ", " .. tostring(victim:GetAttribute("Blood")) .. "% blood")
		local gap = (part(victim, "LeftUpperArm").Position - part(victim, "UpperTorso").Position).Magnitude
		assert(gap < 3, string.format("the arm came back %.1f studs from the body", gap))
		assert(waitFor(function()
			return victim:GetAttribute("RagdollState") == "Standing"
		end, 10), "the healed body did not get up")
		table.insert(results, string.format("freezing it: refused (the cut joint stays off); the Heal tool: arm back on (%.1f studs from the chest), no caps, 100%%, up again", gap))
	else
		table.insert(results, "Config.SEVERING is off: nothing cut")
	end

	-- 5b. Blunt blows bruise.
	local bruised = body(Lab.plazaOrigin() + Vector3.new(-28, 0, -28))
	local top = part(bruised, "Head")
	HitService.applyToy(Toys.byId.Punch, top, at(top, 0, 0.8, -0.5), Vector3.new(0, 0, 1))
	local punchWounds = (bruised:GetAttribute("Wounds") :: string?) or ""
	assert(string.find(punchWounds, "Skull@", 1, true) and not string.find(punchWounds, "Brain@", 1, true), "a punch on the top of the head: " .. punchWounds)
	local slapLine, slapZone = VitalsService.wound(bruised, part(bruised, "UpperTorso"), at(part(bruised, "UpperTorso"), -0.2, 0.2, -0.95), nil, Toys.byId.Slap.wound, { blunt = true })
	assert(slapZone and slapZone.id == "Heart", "the slap was not on the heart")
	assert(waitFor(function()
		return bruised:GetAttribute("Bleeding") ~= true
	end, 6), "a slap on the heart still bleeds after 6 s")
	local bruisedBlood = bruised:GetAttribute("Blood") :: number
	task.wait(3)
	assert(bruised:GetAttribute("Vital") == "Alive", "a punch and a slap left it " .. tostring(bruised:GetAttribute("Vital")))
	local healedBlood = bruised:GetAttribute("Blood") :: number
	assert(bruisedBlood >= 85 and healedBlood > bruisedBlood, string.format("blood after the blows %d%%, 3 s later %d%%", bruisedBlood, healedBlood))
	table.insert(results, string.format("blunt blows: a Punch on the top of the head is the skull (alive), a Slap on the heart (%q) clots in seconds: %d%% blood, back to %d%% 3 s later", slapLine, bruisedBlood, healedBlood))
	-- Blows never bleed a body out: three Mega Slaps on the heart (the heaviest blow; v4 A5: five
	-- would kill by damage, T95), then
	-- watched until every bruise has long stopped bleeding.
	local boxer = body(Lab.plazaOrigin() + Vector3.new(-36, 0, -28))
	local lowest, lowestBlood = math.huge, math.huge
	local function watch()
		lowestBlood = math.min(lowestBlood, boxer:GetAttribute("Blood") :: number)
		lowest = math.min(lowest, boxer:GetAttribute("Pulse") :: number)
		assert(boxer:GetAttribute("Vital") == "Alive", string.format("Mega Slaps on the heart left it %s at %d%% blood", tostring(boxer:GetAttribute("Vital")), boxer:GetAttribute("Blood") :: number))
	end
	for _ = 1, 3 do
		local boxChest = part(boxer, "UpperTorso")
		HitService.applyToy(Toys.byId.MegaSlap, boxChest, at(boxChest, -0.2, 0.2, -0.95), Vector3.new(0, 0, 1))
		for _ = 1, 4 do
			watch()
			task.wait(0.1)
		end
	end
	local watchUntil = os.clock() + 15
	while os.clock() < watchUntil do
		watch()
		task.wait(0.2)
	end
	assert(string.find((boxer:GetAttribute("Wounds") :: string?) or "", "Heart@", 1, true), "the slaps were not on the heart")
	assert(lowestBlood >= 50, "blows took it to " .. lowestBlood .. "% blood")
	assert(lowest >= Anatomy.DEAD_PULSE * 2, "the pulse fell to " .. lowest)
	assert(boxer:GetAttribute("Bleeding") ~= true and (boxer:GetAttribute("Blood") :: number) > lowestBlood, "15 s after the last swing it still bleeds, or the blood is not coming back")
	table.insert(results, string.format("three Mega Slaps on the heart, watched 15 s: alive throughout, blood at its lowest %d%% (blows stop at 50), pulse at its lowest %d, the bleeding stopped and the blood coming back (%d%%)", lowestBlood, lowest, boxer:GetAttribute("Blood") :: number))

	-- A flurry of pokes after a heart shot: the open heart wound stays (the list keeps the wounds
	-- that bleed), so the body goes on bleeding.
	local shot = body(Lab.plazaOrigin() + Vector3.new(-44, 0, -28))
	local shotChest = part(shot, "UpperTorso")
	VitalsService.wound(shot, shotChest, at(shotChest, -0.2, 0.2, -0.95), nil, 0.5)
	for _ = 1, 30 do
		VitalsService.wound(shot, shotChest, shotChest.Position, nil, 0.15, { blunt = true })
	end
	task.wait(3) -- every poke's bruise has stopped
	assert(shot:GetAttribute("Bleeding") == true, "thirty pokes after a heart shot stopped its bleeding")
	table.insert(results, string.format("a heart shot then thirty pokes: still bleeding 3 s later (%d%% blood)", shot:GetAttribute("Blood") :: number))

	-- 6. A blast wounds every body in reach.
	local a, b = body(Lab.plazaOrigin() + Vector3.new(6, 0, -28)), body(Lab.plazaOrigin() + Vector3.new(12, 0, -28))
	Blasts.blast(Lab.plazaOrigin() + Vector3.new(9, 1, -24), Blasts.KINDS.TNT, nil, nil)
	task.wait(0.3)
	for _, m in { a, b } do
		assert(string.find((m:GetAttribute("Wounds") :: string?) or "", "Blast@", 1, true), "a body in the blast has no wound")
	end
	table.insert(results, "a TNT blast wounded both bodies in reach")

	-- 7. A gun fired at nothing.
	Lab.liveForTest(true)
	Lab.rewind(player)
	assert(waitFor(function()
		local c = Lab.slotDummy(player, 2)
		return c ~= nil and c:GetAttribute("RagdollState") == "Standing"
	end, 10), "the lab's coward is not standing")
	local coward = Lab.slotDummy(player, 2) :: Model
	-- (V9-P fix round 1: a knocked dummy lies PHYSICS.MIN_DOWN s; the coward nearest the bang must be up
	-- to run, so the lab's six get the time to stand.)
	waitFor(function()
		for i = 1, 6 do
			local d = Lab.slotDummy(player, i)
			if d and d:GetAttribute("RagdollState") ~= "Standing" and d:GetAttribute("RagdollState") ~= "Walking" then
				return false
			end
		end
		return true
	end, 8)
	for i = 1, 6 do
		local d = Lab.slotDummy(player, i)
		if d then
			d:SetAttribute("PanicFrom", nil)
			d:SetAttribute("PanicUntil", nil)
		end
	end
	-- lihfolk-ignore: findfirstchild-chain (test setup: the character was moved about above, so its root exists)
	local root = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local ground = Vector3.new(part(coward, "LowerTorso").Position.X + 5, 0.5, part(coward, "LowerTorso").Position.Z)
	-- (V8-0.2: past a newcomer's calm first minute, where nobody runs.)
	player:SetAttribute("V8JoinedAt", workspace:GetServerTimeNow() - 600)
	local before = HitService.lastUseOf(player, "Blaster")
	task.wait(0.2)
	HitService.onShot(player, ground, "Blaster")
	local after = HitService.lastUseOf(player, "Blaster")
	assert(after and after ~= before, "a shot into the ground was not taken")
	-- (V8-0.2: only the coward nearest the bang runs, which may be a neighbour of slot 2.)
	assert(waitFor(function()
		if not (Config :: any).V8_FIRST_HIT then
			return typeof(coward:GetAttribute("PanicFrom")) == "Vector3"
		end
		for i = 1, 6 do
			local d = Lab.slotDummy(player, i)
			if d and typeof(d:GetAttribute("PanicFrom")) == "Vector3" then
				return true
			end
		end
		return false
	end, 1), (function()
		local seen = {}
		for i = 1, 6 do
			local d = Lab.slotDummy(player, i)
			local pel = d and d:FindFirstChild("LowerTorso")
			table.insert(seen, string.format("%d:%s %.0f", i, if d then tostring(d:GetAttribute("RagdollState")) else "none", if pel and pel:IsA("BasePart") then (pel.Position - ground).Magnitude else -1))
		end
		return "no coward heard the shot (" .. table.concat(seen, ", ") .. "; newcomer " .. tostring(player:GetAttribute("Newcomer")) .. ")"
	end)())
	HitService.onShot(player, ground, "Blaster")
	assert(HitService.lastUseOf(player, "Blaster") == after, "a second shot at once was taken (the gun's pace)")
	task.wait(0.2)
	HitService.onShot(player, root.Position + Vector3.new(0, 0, Toys.REACH + 20), "Blaster")
	assert(HitService.lastUseOf(player, "Blaster") == after, "a shot past the reach was taken")
	local batBefore = HitService.lastUseOf(player, "Bat")
	task.wait(0.05)
	HitService.onShot(player, ground, "Bat")
	assert(HitService.lastUseOf(player, "Bat") == batBefore, "a bat was fired as a gun")
	table.insert(results, "a Blaster shot into the ground: taken and heard (the coward ran); one at once, one past the reach and a bat 'shot' refused")

	-- 8. Behind a wall.
	local head = (player.Character :: Model):FindFirstChild("Head") :: BasePart
	-- (A clear direction, so nothing of the lab's stands in the way by chance.)
	local clear = RaycastParams.new()
	clear.FilterType = Enum.RaycastFilterType.Exclude
	clear.FilterDescendantsInstances = { player.Character :: Model }
	local way = Vector3.zAxis
	for _, d in { Vector3.zAxis, -Vector3.zAxis, Vector3.xAxis, -Vector3.xAxis } do
		if not Workspace:Raycast(head.Position, d * 16, clear) and not Workspace:Raycast(head.Position - Vector3.new(0, 2, 0), d * 16, clear) then
			way = d
			break
		end
	end
	local spot = Vector3.new(root.Position.X, Lab.plazaOrigin().Y, root.Position.Z) + way * 10
	local target = DummyFactory.spawn(spot, Vector3.new(root.Position.X, spot.Y, root.Position.Z))
	table.insert(spawned, target)
	task.wait(0.6)
	local torso = part(target, "UpperTorso")
	local named = at(torso, -0.2, 0.2, -0.95)
	local wall = Instance.new("Part")
	wall.Anchored = true
	wall.Size = Vector3.new(14, 14, 1)
	wall.CFrame = CFrame.lookAt(head.Position:Lerp(named, 0.5), named)
	wall.Parent = Workspace
	local blockedPart, blockedAt, guarded = HitService.woundSpotForTest(player, target, torso, named)
	assert(blockedPart == torso and (blockedAt - named).Magnitude < 0.01 and guarded, "a wound behind a wall was not guarded")
	local _, guardedZone = VitalsService.wound(target, blockedPart, blockedAt, nil, 1, { guarded = guarded })
	assert(guardedZone and guardedZone.id == "LeftLung", "a guarded heart shot landed on " .. tostring(guardedZone and guardedZone.id))
	wall:Destroy()
	-- Another body in the way is looked past (in lab view the camera aims over it).
	local between = DummyFactory.spawn(Vector3.new(head.Position.X, spot.Y, head.Position.Z):Lerp(Vector3.new(named.X, spot.Y, named.Z), 0.5), head.Position)
	table.insert(spawned, between)
	task.wait(0.3)
	local clearPart, clearAt, clearGuarded = HitService.woundSpotForTest(player, target, torso, named)
	assert(clearPart.Parent == target and not clearGuarded and (clearAt - torso.Position).Magnitude > 0.01, "with a body in the way the aimed spot was not kept")
	table.insert(results, string.format("a wound behind a wall: guarded (the heart shot became %s); with a body in the way instead: %s, where it was aimed", guardedZone.label, clearPart.Name))
	-- Round 4, M10: a see-through part or a placed toy in the way never guards; then a round from the
	-- player (the WoundSpot path, a clear line) to the face kills on the spot.
	between:Destroy()
	local glass = Instance.new("Part")
	glass.Anchored = true
	glass.Transparency = 1
	glass.Size = Vector3.new(14, 14, 1)
	glass.CFrame = CFrame.lookAt(head.Position:Lerp(named, 0.5), named)
	glass.Parent = Workspace
	local _, _, glassGuarded = HitService.woundSpotForTest(player, target, torso, named)
	glass:Destroy()
	assert(not glassGuarded, "an invisible part guarded the wound")
	local face = part(target, "Head")
	local _, _, faceGuarded = HitService.woundSpotForTest(player, target, face, at(face, 0, 0, -0.95))
	assert(not faceGuarded, "a clear line to the face was guarded")
	HitService.applyToy(Toys.byId.Blaster, face, at(face, 0, 0, -0.95), (face.Position - head.Position).Unit, player)
	assert(target:GetAttribute("Vital") == "Dead", "a G17 round from the player to the face left it " .. tostring(target:GetAttribute("Vital")))
	table.insert(results, "an invisible part in the way: not guarded; a G17 round from the player to the face: dead on the spot")
end

return {
	name = "hit-zones-blood-pulse-sever-shots",
	timeout = 150,
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
		local ok, err = pcall(run, results, player)
		VitalsService.liveForTest(false)
		Lab.liveForTest(false)
		for _, m in spawned do
			if m.Parent then
				m:Destroy()
			end
		end
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
