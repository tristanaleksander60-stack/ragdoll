--!strict
-- The doctor's monitor (round 2, N3): the numbers it shows, from what the server shares about a body
-- (Anatomy.monitor, the same code every screen runs):
--   a healthy body: its heart, 120/80, SpO2 98, breathing 15, the whole 5 L, GCS 15 alert, stable
--   the classes of blood loss doctors use (ATLS): to 30% lost the heart races and breathing quickens
--     while the pressure holds; 30-40% the pressure falls and the body is confused; past 40% the
--     pressure is low, the body drowsy and critical; every number moves one way as blood runs out
--   a shot lung costs oxygen and quickens breathing (until the body is patched up and its list
--     cleared); each lung once, however often hit; a blow on the chest (a bruise) costs nothing
--   a failing heart pumps too little: the pressure falls with the rate, the oxygen reading weakens,
--     and too little pressure to the brain makes the body drowsy, then stuporous; never "Alert"
--     with no pressure
--   out cold: GCS 6, critical; dead: asystole, no pressure, no oxygen reading, GCS 3
--   a big vessel still bleeding (heart, aorta, neck, femoral) is never stable; a bruise there, or a
--     bleeding forearm, is
--   on a real body: three slaps on the chest leave the oxygen and breathing alone; a heart shot
--     followed by twelve pokes, then eight newer bleeding rounds, keeps the heart on the shared list,
--     still bleeding; a stopped bruise on
--     the heart with a forearm still bleeding reads stable
--   a real body shot in the heart: its attributes (Blood, Pulse, Vital, Wounds) read back as a heart
--     wound just now, and the monitor calls it serious or worse
--   real deaths (round 4, M10): a brain kill reads asystole at once; a heart that gave out
--     fibrillates first

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local Lab = require(Systems:WaitForChild("Lab"))
local VitalsService = require(Systems:WaitForChild("VitalsService"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local Anatomy = require(ReplicatedStorage.Shared.Anatomy)

local function check(results: { string })
	local Z = Anatomy.zones
	local none = {}

	-- 1. Healthy.
	local fine = Anatomy.monitor(100, 75, "Alive", none)
	assert(fine.hr == 75 and fine.rhythm == "Sinus rhythm", "healthy heart: " .. fine.hr .. " " .. fine.rhythm)
	assert(fine.systolic == 120 and fine.diastolic == 80, string.format("healthy pressure %d/%d", fine.systolic, fine.diastolic))
	assert(fine.spo2 == 98 and fine.resp == 15 and fine.bloodMl == 5000 and fine.gcs == 15, "healthy: spo2/resp/blood/gcs")
	assert(fine.consciousness == "Alert" and fine.severity == "Stable", "healthy: " .. fine.consciousness .. ", " .. fine.severity)
	table.insert(results, string.format("healthy: HR 75 sinus, %d/%d, SpO2 %d, RESP %d, %d mL, GCS %d %s, %s", fine.systolic, fine.diastolic, fine.spo2 :: number, fine.resp, fine.bloodMl, fine.gcs, fine.consciousness, fine.severity))

	-- 1b. Round 3, M5: the ATLS classes (I <15%, II 15-30, III 30-40, IV 40+ lost), the GCS in its
	-- parts (they add up; alert 4/5/6), the temperature falling with the blood, a fresh stop
	-- fibrillating before the line goes flat.
	local function class(lost: number): string
		return Anatomy.monitor(100 - lost, Anatomy.pulseFor(75, 100 - lost), "Alive", none).hemorrhage
	end
	assert(class(10) == "I" and class(14) == "I" and class(15) == "II" and class(29) == "II" and class(30) == "III" and class(39) == "III" and class(40) == "IV" and class(60) == "IV", "the ATLS classes are off")
	assert(fine.eyes == 4 and fine.verbal == 5 and fine.motor == 6, "a healthy body is not E4 V5 M6")
	local lastTemp = math.huge
	for blood = 100, 20, -5 do
		local r = Anatomy.monitor(blood, Anatomy.pulseFor(75, blood), "Alive", none)
		assert(r.eyes + r.verbal + r.motor == r.gcs, string.format("GCS parts %d+%d+%d are not %d", r.eyes, r.verbal, r.motor, r.gcs))
		assert(r.temp and (r.temp :: number) <= lastTemp, "the temperature rose as blood ran out")
		lastTemp = r.temp :: number
	end
	local out = Anatomy.monitor(40, 60, "Unconscious", none)
	assert(out.eyes + out.verbal + out.motor == 6, "out cold is not GCS 6 in parts")
	local fresh = Anatomy.monitor(80, 0, "Dead", none, 2)
	local flat = Anatomy.monitor(80, 0, "Dead", none, Anatomy.VF_TIME + 1)
	assert(fresh.vf and fresh.rhythm == "Ventricular fibrillation", "a fresh stop does not fibrillate")
	assert(not flat.vf and flat.rhythm == "Asystole" and flat.temp ~= nil and flat.eyes + flat.verbal + flat.motor == 3, "a stop " .. Anatomy.VF_TIME .. " s old is not a flat line")
	table.insert(results, string.format("ATLS classes I-IV at 15/30/40%%; GCS parts add up at every blood level (alert E4 V5 M6, out cold 6); temperature %.1f at rest down to %.1f at 20%% blood; a fresh stop fibrillates, after %d s asystole", fine.temp :: number, lastTemp, Anatomy.VF_TIME))

	-- 2. The classes of blood loss.
	local c2 = Anatomy.monitor(78, Anatomy.pulseFor(75, 78), "Alive", none) -- 22% lost
	local c3 = Anatomy.monitor(65, Anatomy.pulseFor(75, 65), "Alive", none) -- 35% lost
	local c4 = Anatomy.monitor(50, Anatomy.pulseFor(75, 50), "Alive", none) -- 50% lost
	assert(c2.systolic >= 110 and c2.resp >= 18 and c2.hr > fine.hr and c2.severity == "Serious", string.format("class II: %d/%d, resp %d, hr %d, %s", c2.systolic, c2.diastolic, c2.resp, c2.hr, c2.severity))
	assert(c3.systolic < 110 and c3.systolic >= 90 and c3.consciousness == "Confused", string.format("class III: %d, %s", c3.systolic, c3.consciousness))
	assert(c4.systolic < 90 and c4.severity == "Critical" and c4.consciousness == "Drowsy" and c4.rhythm == "Sinus tachycardia", string.format("class IV: %d, %s, %s, %s", c4.systolic, c4.severity, c4.consciousness, c4.rhythm))
	-- Round 3, M5 fix 1: the heart and breathing in each class as ATLS has them (bleeding alone; a
	-- round slows the heart on its own, the owner's rule: VitalsService).
	for lost = 1, 60 do
		local r = Anatomy.monitor(100 - lost, Anatomy.pulseFor(75, 100 - lost), "Alive", none)
		local hrOk = if lost < 15 then r.hr < 100 elseif lost < 30 then r.hr >= 100 and r.hr <= 120 elseif lost < 40 then r.hr >= 120 and r.hr <= 140 else r.hr > 140
		local rrOk = if lost < 15 then r.resp >= 14 and r.resp <= 20 elseif lost < 30 then r.resp >= 20 and r.resp <= 30 elseif lost < 40 then r.resp >= 30 and r.resp <= 40 else r.resp > 35
		assert(hrOk and rrOk, string.format("%d%% lost (class %s): HR %d, RESP %d is not what ATLS has", lost, r.hemorrhage, r.hr, r.resp))
	end
	-- The ECG on a narrow strip: a column of 40 ms over the R wave still reaches its peak (one sample
	-- at the column's time would miss the 20 ms spike).
	local period = 60 / 72
	local hits = 0
	for start = 0, period, 0.04 do
		local lo, hi = Anatomy.ecgSpan(start, start + 0.04, period)
		local rAt = 0.225 * math.min(1, period / 0.8)
		if start <= rAt and start + 0.04 >= rAt then
			assert(hi > 0.9, string.format("the column over the R wave peaks at %.2f", hi))
			hits += 1
		end
		assert(lo <= hi, "a column's low is above its high")
	end
	assert(hits >= 1, "no column covered the R wave")
	-- A heart its rounds slowed in a body that lost a third of its blood: relative bradycardia.
	-- (Demetriades: systolic 90 or less with a pulse of 90 or less; the rhythm itself stays sinus.)
	local slowed = Anatomy.monitor(51, 74, "Alive", none)
	assert(slowed.rhythm == "Sinus rhythm" and slowed.note == "Relative bradycardia" and slowed.systolic <= 90, string.format("a slow heart in class IV reads %s / %s at %d", slowed.rhythm, tostring(slowed.note), slowed.systolic))
	local holding = Anatomy.monitor(68, 95, "Alive", none) -- (32% short, the pressure still above 90)
	assert(holding.note == nil, "relative bradycardia read with the pressure at " .. holding.systolic)
	assert(Anatomy.monitor(90, 74, "Alive", none).note == nil, "a calm body reads relative bradycardia")
	local last = fine
	for blood = 99, 16, -1 do
		local r = Anatomy.monitor(blood, Anatomy.pulseFor(75, blood), "Alive", none)
		assert(r.systolic <= last.systolic and (r.spo2 :: number) <= (last.spo2 :: number) and r.bloodMl <= last.bloodMl and r.gcs <= last.gcs,
			string.format("a number went up as blood ran out at %d%% (%d/%d, spo2 %s, gcs %d)", blood, r.systolic, r.diastolic, tostring(r.spo2), r.gcs))
		last = r
	end
	table.insert(results, string.format("blood loss: 22%% lost %d/%d RESP %d HR %d %s; 35%% %d/%d %s; 50%% %d/%d %s %s; pressure, oxygen, blood and GCS never rise as blood runs out (99..16%%)",
		c2.systolic, c2.diastolic, c2.resp, c2.hr, c2.severity, c3.systolic, c3.diastolic, c3.consciousness, c4.systolic, c4.diastolic, c4.consciousness, c4.severity))

	-- 3. A hit lung (and both).
	local lung = Anatomy.monitor(97, 80, "Alive", { { zone = Z.LeftLung, at = 990 } })
	local both = Anatomy.monitor(97, 80, "Alive", { { zone = Z.LeftLung, at = 900 }, { zone = Z.RightLung, at = 990 } })
	local sameTwice = Anatomy.monitor(97, 80, "Alive", { { zone = Z.LeftLung, at = 900 }, { zone = Z.LeftLung, at = 990 } })
	local slapped = Anatomy.monitor(97, 80, "Alive", { { zone = Z.LeftLung, at = 990, blunt = true }, { zone = Z.RightLung, at = 991, blunt = true } })
	assert(sameTwice.spo2 == lung.spo2 and sameTwice.resp == lung.resp, "one lung hit twice read as two")
	local unhurt97 = Anatomy.monitor(97, 80, "Alive", none) -- (the same blood, no blows: what they must not change)
	assert(slapped.spo2 == 98 and slapped.resp == unhurt97.resp and slapped.severity == "Stable", string.format("blows on the chest read SpO2 %s, RESP %d, %s", tostring(slapped.spo2), slapped.resp, slapped.severity))
	assert((lung.spo2 :: number) <= 93 and lung.resp >= 19 and lung.severity ~= "Stable", string.format("a lung hit: spo2 %s, resp %d, %s", tostring(lung.spo2), lung.resp, lung.severity))
	assert((both.spo2 :: number) < (lung.spo2 :: number) and both.resp > lung.resp, "both lungs read no worse than one")
	table.insert(results, string.format("one lung shot: SpO2 %d, RESP %d (%s); the same lung twice: the same; both: SpO2 %d, RESP %d; blows on both lungs: SpO2 98, RESP 15, Stable", lung.spo2 :: number, lung.resp, lung.severity, both.spo2 :: number, both.resp))

	-- 3b. A failing heart with the blood still in: the pressure follows the rate down.
	local weak = Anatomy.monitor(90, 45, "Alive", none)
	local failing = Anatomy.monitor(90, 20, "Alive", none)
	local stopping = Anatomy.monitor(90, 8, "Alive", none)
	assert(weak.systolic < 115 and weak.systolic > failing.systolic and failing.systolic > stopping.systolic, string.format("the pressure does not follow a failing heart (%d, %d, %d)", weak.systolic, failing.systolic, stopping.systolic))
	assert(failing.consciousness ~= "Alert" and stopping.consciousness == "Stupor" and stopping.severity == "Critical", string.format("a heart at 20 and 8 bpm reads %s and %s, %s", failing.consciousness, stopping.consciousness, stopping.severity))
	assert((stopping.spo2 :: number) < (weak.spo2 :: number), "the oxygen reading does not weaken with the pulse")
	table.insert(results, string.format("a failing heart at 90%% blood: 45 bpm %d/%d %s; 20 bpm %d/%d %s; 8 bpm %d/%d SpO2 %d %s %s", weak.systolic, weak.diastolic, weak.consciousness, failing.systolic, failing.diastolic, failing.consciousness, stopping.systolic, stopping.diastolic, stopping.spo2 :: number, stopping.consciousness, stopping.severity))

	-- 3c. Bleeding from a big vessel is never stable; a bruise there that has stopped is.
	local shotHeart = Anatomy.monitor(95, 72, "Alive", { { zone = Z.Heart, at = 990, open = true } })
	local bruisedHeart = Anatomy.monitor(95, 72, "Alive", { { zone = Z.Heart, at = 990, blunt = true, open = true } })
	local shotArm = Anatomy.monitor(95, 72, "Alive", { { zone = Z.LeftForearm, at = 990, open = true }, { zone = Z.Heart, at = 980, blunt = true } })
	assert(shotHeart.severity == "Serious" and bruisedHeart.severity == "Stable" and shotArm.severity == "Stable", string.format("heart bleeding %s, heart not bleeding %s, forearm bleeding %s", shotHeart.severity, bruisedHeart.severity, shotArm.severity))
	table.insert(results, "at 95% blood: a heart wound still bleeding reads Serious; a bruise on the heart (even while it bleeds) and a bleeding forearm beside an old heart bruise read Stable")

	-- 4. Out cold, and dead.
	local out = Anatomy.monitor(42, 140, "Unconscious", none)
	assert(out.gcs == 6 and out.consciousness == "Out cold" and out.severity == "Critical", "out cold: " .. out.gcs .. " " .. out.consciousness)
	local dead = Anatomy.monitor(12, 0, "Dead", none)
	assert(dead.hr == 0 and dead.rhythm == "Asystole" and dead.systolic == 0 and dead.spo2 == nil and dead.resp == 0 and dead.gcs == 3 and dead.severity == "Dead", "dead does not read dead")
	table.insert(results, "out cold: GCS 6 'Out cold', critical; dead: asystole, 0/0, no SpO2, RESP 0, GCS 3 'None'")

	-- 5. The wound list as the server writes it.
	local parsed = Anatomy.parseWounds("Heart@1000o;Nope@5;LeftLung@1010b;Liver@1020;junk;Neck@3x")
	assert(#parsed == 3 and parsed[1].zone.id == "Heart" and parsed[1].open and not parsed[1].blunt
		and parsed[2].at == 1010 and parsed[2].blunt and not parsed[2].open
		and parsed[3].zone.id == "Liver" and not parsed[3].open, "the wound list did not parse")
	assert(#Anatomy.parseWounds(nil) == 0 and #Anatomy.parseWounds(5) == 0, "a missing wound list did not read as none")
	table.insert(results, "the wound list: 'Heart@1000o;Nope@5;LeftLung@1010b;Liver@1020;junk;Neck@3x' reads as the heart (bleeding), the left lung (a blow) and the liver, unknown and broken pieces left out")
end

-- Round 4, M10: what the monitor reads off a real body (DiedAt, DeathCause: Anatomy.stoppedFor) at
-- once: a brain kill is flat at once (no fibrillation); a heart that gave out (all the blood gone)
-- still fibrillates first.
local function deaths(results: { string })
	local shot = DummyFactory.spawn(Lab.plazaOrigin() + Vector3.new(-78, 0, -28), Lab.plazaOrigin() + Vector3.new(-78, 0, -29))
	local bled = DummyFactory.spawn(Lab.plazaOrigin() + Vector3.new(-84, 0, -28), Lab.plazaOrigin() + Vector3.new(-84, 0, -29))
	task.wait(0.6)
	local ok, err = pcall(function()
		local function monitorOf(model: Model): Anatomy.Reading
			local deadFor = Anatomy.stoppedFor(model:GetAttribute("DiedAt"), model:GetAttribute("DeathCause"), Workspace:GetServerTimeNow())
			return Anatomy.monitor(model:GetAttribute("Blood") :: number, model:GetAttribute("Pulse") :: number, model:GetAttribute("Vital") :: string, Anatomy.parseWounds(model:GetAttribute("Wounds")), deadFor)
		end
		local head = shot:FindFirstChild("Head") :: BasePart
		VitalsService.wound(shot, head, head.CFrame:PointToWorldSpace(Vector3.new(0, 0.7 * head.Size.Y / 2, -0.9 * head.Size.Z / 2)), nil, 1)
		local brain = monitorOf(shot)
		assert(shot:GetAttribute("Vital") == "Dead" and not brain.vf and brain.rhythm == "Asystole", "a brain kill reads " .. brain.rhythm)
		local chest = bled:FindFirstChild("UpperTorso") :: BasePart
		VitalsService.wound(bled, chest, chest.CFrame:PointToWorldSpace(Vector3.new(-0.2 * chest.Size.X / 2, 0.2 * chest.Size.Y / 2, -0.95 * chest.Size.Z / 2)), nil, 9)
		local heart = monitorOf(bled)
		assert(bled:GetAttribute("Vital") == "Dead" and bled:GetAttribute("DeathCause") == nil, "all the blood gone: " .. tostring(bled:GetAttribute("Vital")))
		assert(heart.vf and heart.rhythm == "Ventricular fibrillation", "a heart that gave out reads " .. heart.rhythm)
		table.insert(results, string.format("real deaths: a brain kill reads asystole at once (%d%% blood); a heart that gave out (%d%% blood) fibrillates first", brain.bloodPct, heart.bloodPct))
	end)
	shot:Destroy()
	bled:Destroy()
	if not ok then
		error(err, 0)
	end
end

local function live(results: { string })
	VitalsService.liveForTest(true)
	local dummy = DummyFactory.spawn(Lab.plazaOrigin() + Vector3.new(-52, 0, -28), Lab.plazaOrigin() + Vector3.new(-52, 0, -29))
	task.wait(0.6)
	local ok, err = pcall(function()
		local chest = dummy:FindFirstChild("UpperTorso") :: BasePart
		local heart = chest.CFrame:PointToWorldSpace(Vector3.new(-0.2 * chest.Size.X / 2, 0.2 * chest.Size.Y / 2, -0.95 * chest.Size.Z / 2))
		VitalsService.wound(dummy, chest, heart, nil, 1)
		task.wait(0.5)
		local wounds = Anatomy.parseWounds(dummy:GetAttribute("Wounds"))
		assert(#wounds == 1 and wounds[1].zone.id == "Heart", "the body's wound list: " .. tostring(dummy:GetAttribute("Wounds")))
		local age = Workspace:GetServerTimeNow() - wounds[1].at
		assert(age >= -1 and age < 3, string.format("the wound's time is %.1f s off", age))
		local r = Anatomy.monitor(dummy:GetAttribute("Blood") :: number, dummy:GetAttribute("Pulse") :: number, dummy:GetAttribute("Vital") :: string, wounds)
		assert(r.severity == "Serious" or r.severity == "Critical", "a heart shot reads " .. r.severity)
		if r.hr < 50 then
			assert(r.systolic < 120, string.format("a heart shot at HR %d still reads %d/%d", r.hr, r.systolic, r.diastolic))
		end
		assert(dummy:GetAttribute("Bleeding") == true, "the heart shot is not bleeding")
		table.insert(results, string.format("a real heart shot: wound read back (%.0f s ago), %d%% blood, HR %d, %d/%d, %s", age, r.bloodPct, r.hr, r.systolic, r.diastolic, r.severity))
	end)
	dummy:Destroy()
	if ok then
		ok, err = pcall(deaths, results)
	end
	if not ok then
		error(err, 0)
	end
end

local function point(p: BasePart, x: number, y: number, z: number): Vector3
	return p.CFrame:PointToWorldSpace(Vector3.new(x * p.Size.X / 2, y * p.Size.Y / 2, z * p.Size.Z / 2))
end

local function read(model: Model): Anatomy.Reading
	return Anatomy.monitor(model:GetAttribute("Blood") :: number, model:GetAttribute("Pulse") :: number, model:GetAttribute("Vital") :: string, Anatomy.parseWounds(model:GetAttribute("Wounds")))
end

-- The shared list on real bodies: what the monitor reads from it.
local function shared(results: { string })
	local made: { Model } = {}
	local function body(dx: number): Model
		local at = Lab.plazaOrigin() + Vector3.new(dx, 0, -36)
		local m = DummyFactory.spawn(at, at - Vector3.zAxis)
		table.insert(made, m)
		return m
	end
	local ok, err = pcall(function()
		local slapped, poked, mixed = body(-60), body(-66), body(-72)
		task.wait(0.6)
		-- Three slaps on the chest (they land on a lung).
		local chest = slapped:FindFirstChild("UpperTorso") :: BasePart
		for _ = 1, 3 do
			VitalsService.wound(slapped, chest, point(chest, -0.75, 0.4, -0.9), nil, 0.33, { blunt = true })
		end
		-- A heart shot, then twelve pokes on an arm.
		local pchest = poked:FindFirstChild("UpperTorso") :: BasePart
		VitalsService.wound(poked, pchest, point(pchest, -0.2, 0.2, -0.95), nil, 0.5)
		local arm = poked:FindFirstChild("LeftLowerArm") :: BasePart
		for _ = 1, 12 do
			VitalsService.wound(poked, arm, arm.Position, nil, 0.15, { blunt = true })
		end
		-- A slap on the heart, and a round in the forearm.
		local mchest = mixed:FindFirstChild("UpperTorso") :: BasePart
		VitalsService.wound(mixed, mchest, point(mchest, -0.2, 0.2, -0.95), nil, 0.33, { blunt = true })
		local forearm = mixed:FindFirstChild("RightLowerArm") :: BasePart
		VitalsService.wound(mixed, forearm, forearm.Position, nil, 1)
		task.wait(3.2) -- every bruise has stopped bleeding; the forearm still bleeds
		local s = read(slapped)
		assert(s.spo2 == 98 and s.resp <= 16, string.format("three slaps on the chest read SpO2 %s, RESP %d (%s)", tostring(s.spo2), s.resp, tostring(slapped:GetAttribute("Wounds"))))
		local list = Anatomy.parseWounds(poked:GetAttribute("Wounds"))
		local heartOpen = false
		for _, w in list do
			if w.zone.id == "Heart" and w.open then
				heartOpen = true
			end
		end
		assert(#list <= 8 and heartOpen, "after twelve pokes the shared list lost the bleeding heart: " .. tostring(poked:GetAttribute("Wounds")))
		local p = read(poked)
		assert(p.severity ~= "Stable", "a bleeding heart after twelve pokes reads Stable")
		-- Eight newer rounds that bleed too (forearms): the heart, a big vessel, keeps its place.
		for i = 1, 8 do
			local limb = poked:FindFirstChild(if i % 2 == 0 then "LeftLowerArm" else "RightLowerArm") :: BasePart
			VitalsService.wound(poked, limb, limb.Position, nil, 0.3)
		end
		local after = Anatomy.parseWounds(poked:GetAttribute("Wounds"))
		local heartKept = false
		for _, w in after do
			if w.zone.id == "Heart" and w.open then
				heartKept = true
			end
		end
		assert(heartKept, "eight newer bleeding rounds pushed the bleeding heart off the shared list: " .. tostring(poked:GetAttribute("Wounds")))
		local m = read(mixed)
		assert(m.severity == "Stable", string.format("a stopped heart bruise with a bleeding forearm reads %s (%s)", m.severity, tostring(mixed:GetAttribute("Wounds"))))
		table.insert(results, string.format("real bodies: three slaps on the chest: SpO2 %d, RESP %d; a heart shot then twelve pokes: %d shared, the heart still listed as bleeding, %s, and still after eight newer bleeding rounds; a stopped heart bruise with a bleeding forearm: %s", s.spo2 :: number, s.resp, #list, p.severity, m.severity))
	end)
	for _, m in made do
		m:Destroy()
	end
	if not ok then
		error(err, 0)
	end
end

return {
	name = "doctor-monitor-numbers",
	timeout = 40,
	run = function(): string?
		local results = {}
		check(results)
		local ok, err = pcall(function()
			live(results)
			shared(results)
		end)
		VitalsService.liveForTest(false)
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
