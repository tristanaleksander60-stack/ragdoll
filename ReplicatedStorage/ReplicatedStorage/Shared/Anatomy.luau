--!strict
-- Where a body was hit (round 2, N2): the zone or organ under the point on the part, and what it
-- does. Shared so the server's vitals, the hit text and the tests read the same table.
--
-- A point on an R15 part is read in the part's own space, scaled to -1..1 on each axis (x: the
-- body's right is +X, so its left side is -X; y: up; z: the back is +Z, the front -Z). The torso
-- holds the organs (heart, lungs, liver, stomach, kidneys, intestines, the aorta and the spine); the
-- head the brain; the limbs their bones and, high on the inside of the thigh, the femoral artery.
--
-- bleed: blood lost per second while the wound is open (% of the body's blood); loss: lost at once;
-- pulse: how the heart answers (bpm added; the heart itself and the brain slow it); lethal: the body
-- dies at once whatever its blood (brain). A wound stops bleeding after `stops` seconds (the
-- limbs clot; organs keep bleeding until the body is patched up).

export type Zone = {
	id: string,
	label: string, -- what the hit text says ("Left lung")
	bleed: number,
	loss: number,
	pulse: number,
	stops: number?, -- s until it stops bleeding (nil: keeps bleeding)
	lethal: boolean?,
	knockout: boolean?, -- out cold on the spot (a head hit)
	limb: string?, -- the limb this zone is on (severing: Config.SEVERING)
}

local Anatomy = {}

local Z: { [string]: Zone } = {}
local function zone(id: string, label: string, bleed: number, loss: number, pulse: number, extra: { [string]: any }?)
	local z: any = { id = id, label = label, bleed = bleed, loss = loss, pulse = pulse }
	for k, v in extra or {} do
		z[k] = v
	end
	Z[id] = z :: Zone
end

zone("Brain", "Brain", 0, 8, -60, { lethal = true, knockout = true })
zone("Skull", "Skull", 0.4, 2, 10, { knockout = true, stops = 20 })
zone("Jaw", "Jaw", 0.5, 2, 12, { stops = 20 })
zone("Neck", "Neck (carotid)", 4.5, 6, 30)
zone("Heart", "Heart", 6, 10, -45)
zone("Aorta", "Aorta", 8, 12, 35)
zone("LeftLung", "Left lung", 1.4, 3, 28)
zone("RightLung", "Right lung", 1.4, 3, 28)
zone("Liver", "Liver", 2.4, 4, 22)
zone("Stomach", "Stomach", 0.9, 2, 14)
zone("Spine", "Spine", 0.6, 2, 8, { knockout = true })
zone("LeftKidney", "Left kidney", 1.6, 3, 18)
zone("RightKidney", "Right kidney", 1.6, 3, 18)
zone("Intestines", "Intestines", 0.8, 2, 12)
zone("Pelvis", "Pelvis", 0.6, 2, 10, { stops = 40 })
for _, side in { "Left", "Right" } do
	zone(side .. "UpperArm", side .. " upper arm", 0.35, 1, 8, { stops = 25, limb = side .. "Arm" })
	zone(side .. "Forearm", side .. " forearm", 0.3, 1, 6, { stops = 20, limb = side .. "Arm" })
	zone(side .. "Hand", side .. " hand", 0.2, 0.5, 5, { stops = 15, limb = side .. "Arm" })
	zone(side .. "Thigh", side .. " thigh", 0.45, 1, 8, { stops = 25, limb = side .. "Leg" })
	zone(side .. "Femoral", side .. " femoral artery", 4, 5, 30, { limb = side .. "Leg" })
	-- An arm torn off (round 3, M5 fix 1): the stump at the shoulder bleeds from the arm's big artery
	-- (axillary), as a leg's from the femoral. Never under a point: only a severed arm makes it.
	zone(side .. "ArmStump", side .. " arm stump", 4, 5, 30, { limb = side .. "Arm" })
	zone(side .. "Shin", side .. " shin", 0.3, 1, 6, { stops = 20, limb = side .. "Leg" })
	zone(side .. "Foot", side .. " foot", 0.15, 0.5, 4, { stops = 15, limb = side .. "Leg" })
end
zone("Blast", "Blast", 1.2, 6, 25, { stops = 30 })

Anatomy.zones = table.freeze(Z)

-- Phase 0 (mild content, Config.MILD_TEXT): the body region a zone is in, for the hit line every
-- player sees (no organ names). Doctor mode keeps the zone's own label.
local REGION: { [string]: string } = {
	Brain = "Head", Skull = "Head", Jaw = "Head", Neck = "Neck",
	Heart = "Chest", Aorta = "Chest", LeftLung = "Chest", RightLung = "Chest", Spine = "Back",
	Liver = "Belly", Stomach = "Belly", LeftKidney = "Belly", RightKidney = "Belly", Intestines = "Belly",
	Pelvis = "Hips", Blast = "Blast",
}
function Anatomy.mildLabel(id: string): string
	local region = REGION[id]
	if region then
		return region
	end
	local side, rest = string.match(id, "^(%u%l+)(%u.*)$")
	if side and rest then
		local part = if rest == "Femoral" or rest == "Thigh" or rest == "Shin" then "leg"
			elseif rest == "ArmStump" or rest == "UpperArm" or rest == "Forearm" then "arm"
			else string.lower(rest)
		return side .. " " .. part
	end
	return "Body"
end

-- The parts each limb is made of, from the body outwards, and the joint that holds it on.
Anatomy.LIMBS = table.freeze({
	LeftArm = { joint = "LeftShoulder", parts = { "LeftUpperArm", "LeftLowerArm", "LeftHand" }, label = "Left arm" },
	RightArm = { joint = "RightShoulder", parts = { "RightUpperArm", "RightLowerArm", "RightHand" }, label = "Right arm" },
	LeftLeg = { joint = "LeftHip", parts = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" }, label = "Left leg" },
	RightLeg = { joint = "RightHip", parts = { "RightUpperLeg", "RightLowerLeg", "RightFoot" }, label = "Right leg" },
})

-- 0.36.8 (owner, 22 Nov 2026: "shoot the shoulder enough and the arm falls off, the wrist and the hand
-- falls off"): smaller pieces that can come off at their own joint (Config.SEVERING). `parent` is the part
-- the piece hangs on (the stump caps go on it, a heal puts the piece back on it). Not in LIMBS, so
-- limbOfPart still names the whole arm or leg.
Anatomy.CUTS = table.freeze({
	LeftForearm = { joint = "LeftElbow", parts = { "LeftLowerArm", "LeftHand" }, label = "Left forearm", parent = "LeftUpperArm" },
	RightForearm = { joint = "RightElbow", parts = { "RightLowerArm", "RightHand" }, label = "Right forearm", parent = "RightUpperArm" },
	LeftHand = { joint = "LeftWrist", parts = { "LeftHand" }, label = "Left hand", parent = "LeftLowerArm" },
	RightHand = { joint = "RightWrist", parts = { "RightHand" }, label = "Right hand", parent = "RightLowerArm" },
	LeftShin = { joint = "LeftKnee", parts = { "LeftLowerLeg", "LeftFoot" }, label = "Left shin", parent = "LeftUpperLeg" },
	RightShin = { joint = "RightKnee", parts = { "RightLowerLeg", "RightFoot" }, label = "Right shin", parent = "RightUpperLeg" },
	LeftFoot = { joint = "LeftAnkle", parts = { "LeftFoot" }, label = "Left foot", parent = "LeftLowerLeg" },
	RightFoot = { joint = "RightAnkle", parts = { "RightFoot" }, label = "Right foot", parent = "RightLowerLeg" },
	-- (22 Nov 2026, owner: "shoot them at the hips 2-3 times and the ragdoll comes apart, blood from both ends, bones
	-- showing"): the upper body comes off the pelvis at the waist.
	Waist = { joint = "Waist", parts = { "UpperTorso", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }, label = "Cut in half", parent = "LowerTorso" },
})

-- A whole limb (LIMBS) or a smaller piece (CUTS) by name.
function Anatomy.cutOf(name: string): { joint: string, parts: { string }, label: string, parent: string? }?
	return (Anatomy.LIMBS :: any)[name] or (Anatomy.CUTS :: any)[name]
end

-- What a round in a zone cuts off once enough rounds land there, and how many it takes.
Anatomy.SHOTS_TO_CUT = table.freeze({ Arm = 4, Forearm = 3, Hand = 2, Leg = 5, Shin = 3, Foot = 2, Waist = 3 })
function Anatomy.cutForZone(zoneId: string): (string?, number)
	if zoneId == "Pelvis" or zoneId == "Intestines" then
		return "Waist", Anatomy.SHOTS_TO_CUT.Waist -- (the hips: the waist gives way)
	end
	local side = string.match(zoneId, "^(Left)") or string.match(zoneId, "^(Right)")
	if not side then
		return nil, 0
	end
	local rest = string.sub(zoneId, #side + 1)
	local piece = if rest == "UpperArm" then "Arm" elseif rest == "Forearm" then "Forearm" elseif rest == "Hand" then "Hand"
		elseif rest == "Thigh" or rest == "Femoral" then "Leg" elseif rest == "Shin" then "Shin" elseif rest == "Foot" then "Foot" else nil
	if not piece then
		return nil, 0
	end
	return side .. piece, Anatomy.SHOTS_TO_CUT[piece]
end

-- Which limb a part belongs to (nil: head or torso).
function Anatomy.limbOfPart(partName: string): string?
	for name, limb in Anatomy.LIMBS do
		if table.find(limb.parts, partName) then
			return name
		end
	end
	return nil
end

-- The zone under a point on a body part. `localPoint` is the point in the part's own space and
-- `size` the part's size.
function Anatomy.zoneAt(partName: string, localPoint: Vector3, size: Vector3): Zone?
	local half = size / 2
	local x = math.clamp(localPoint.X / math.max(half.X, 0.01), -1, 1)
	local y = math.clamp(localPoint.Y / math.max(half.Y, 0.01), -1, 1)
	local z = math.clamp(localPoint.Z / math.max(half.Z, 0.01), -1, 1)
	if partName == "Head" then
		if y > 0.15 then
			return if z < 0.35 or y > 0.5 then Z.Brain else Z.Skull
		elseif y < -0.55 then
			return Z.Neck
		end
		return if z < -0.2 then Z.Jaw else Z.Skull
	elseif partName == "UpperTorso" then
		if z > 0.55 and math.abs(x) < 0.22 then
			return Z.Spine
		end
		if math.abs(x) < 0.14 and y > 0.35 then
			return Z.Aorta
		end
		if y > -0.25 then
			-- The heart sits left of the middle, behind the breastbone.
			if x > -0.5 and x < 0.08 and y < 0.55 then
				return Z.Heart
			end
			return if x < 0 then Z.LeftLung else Z.RightLung
		end
		return if x > 0.05 then Z.Liver else Z.Stomach
	elseif partName == "LowerTorso" then
		if z > 0.35 and math.abs(x) > 0.15 then
			return if x < 0 then Z.LeftKidney else Z.RightKidney
		end
		if z > 0.55 then
			return Z.Spine
		end
		return if y > -0.2 then Z.Intestines else Z.Pelvis
	elseif partName == "LeftUpperArm" or partName == "RightUpperArm" then
		return Z[(if partName == "LeftUpperArm" then "Left" else "Right") .. "UpperArm"]
	elseif partName == "LeftLowerArm" or partName == "RightLowerArm" then
		return Z[(if partName == "LeftLowerArm" then "Left" else "Right") .. "Forearm"]
	elseif partName == "LeftHand" or partName == "RightHand" then
		return Z[(if partName == "LeftHand" then "Left" else "Right") .. "Hand"]
	elseif partName == "LeftUpperLeg" or partName == "RightUpperLeg" then
		local legSide = if partName == "LeftUpperLeg" then "Left" else "Right"
		-- The femoral artery runs high on the inside of the thigh (towards the other leg).
		local inside = if legSide == "Left" then x > 0.2 else x < -0.2
		if inside and y > 0.1 then
			return Z[legSide .. "Femoral"]
		end
		return Z[legSide .. "Thigh"]
	elseif partName == "LeftLowerLeg" or partName == "RightLowerLeg" then
		return Z[(if partName == "LeftLowerLeg" then "Left" else "Right") .. "Shin"]
	elseif partName == "LeftFoot" or partName == "RightFoot" then
		return Z[(if partName == "LeftFoot" then "Left" else "Right") .. "Foot"]
	end
	return nil
end

-- The pulse a body has with this much blood left and nothing else wrong: the heart makes up for
-- the blood lost as the ATLS classes say (class I under 100, II 100-120, III 120-140, IV over 140;
-- round 3, M5 fix 1), then fails below 40% and stops at 15%. (Hits pull it down on their own:
-- VitalsService, the owner's rule that every round slows the heart.)
function Anatomy.pulseFor(rest: number, blood: number): number
	local function lerp(a: number, b: number, t: number): number
		return a + (b - a) * math.clamp(t, 0, 1)
	end
	local top = math.max(rest, 75) -- (the classes are counted from a normal adult's rest)
	if blood > 85 then
		return lerp(rest, top + 20, (100 - blood) / 15) -- class I: to 95
	elseif blood >= 70 then
		return lerp(top + 25, top + 45, (85 - blood) / 15) -- class II: 100 -> 120
	elseif blood > 60 then
		return lerp(top + 45, top + 65, (70 - blood) / 10) -- class III: 120 -> 140
	elseif blood >= 40 then
		return lerp(top + 67, top + 80, (60 - blood) / 20) -- class IV: 142 -> 155
	end
	-- 40% -> 155, 15% -> 0: the heart gives out.
	return math.max(0, (top + 80) * (blood - 15) / 25)
end

-- What the doctor's monitor shows (round 2, N3), worked out from what the server shares about a
-- body (Blood, Pulse, Vital, Wounds), so every screen and the tests read the same numbers. It follows
-- the classes of blood loss doctors use (ATLS): up to 15% lost little changes; 15-30% the heart
-- races and breathing quickens, the pressure still holds; 30-40% the pressure falls and the body is
-- confused; past 40% the pressure is low and breathing fast and shallow; a hit lung costs oxygen
-- and quickens breathing until the body is patched up. A failing heart (a shot to it, the end of a
-- bleed) pumps less: the pressure falls with the rate, the oxygen reading weakens, and a body with
-- too little pressure to its brain grows drowsy, then stuporous (barely rousable).
export type Reading = {
	hr: number, -- bpm (the server's Pulse)
	rhythm: string, -- "Sinus rhythm", "Sinus tachycardia", "Sinus bradycardia", "Asystole"
	note: string?, -- a clinical reading shown after the rhythm ("Relative bradycardia")
	systolic: number, -- mmHg (0: none)
	diastolic: number,
	spo2: number?, -- % (nil: no reading, "--")
	resp: number, -- breaths a minute
	bloodPct: number, -- % of the body's blood
	bloodMl: number, -- of BLOOD_ML
	gcs: number, -- Glasgow coma scale, 3..15
	consciousness: string, -- "Alert", "Confused", "Drowsy", "Stupor", "Out cold", "None" (short: a tile holds it)
	severity: string, -- "Stable", "Serious", "Critical", "Dead": how the monitor colours the patient
	-- Round 3, M5:
	eyes: number, -- the GCS in its three parts (E 1-4, V 1-5, M 1-6; they add up to gcs)
	verbal: number,
	motor: number,
	hemorrhage: string, -- ATLS class of the blood lost: "I" (<15%), "II" (15-30), "III" (30-40), "IV" (40+), "" dead
	temp: number?, -- core temperature, degrees C (still read after death)
	vf: boolean, -- the heart in ventricular fibrillation (just stopped): a chaotic trace, no beat
}

Anatomy.BLOOD_ML = 5000 -- a grown body's blood
Anatomy.LOW_OUTPUT_HR = 55 -- bpm: under this the heart pumps too little to hold the pressure

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- One wound as the server shares it: where, when (server time), whether it was a blow (a bruise),
-- whether it still bleeds.
export type SharedWound = { zone: Zone, at: number, blunt: boolean?, open: boolean? }

-- The wounds the server lists ("Zone@servertime" with flags b: a blow, o: still bleeding; ";"
-- between): in order, unknown zones and broken pieces left out.
function Anatomy.parseWounds(raw: unknown): { SharedWound }
	local list = {}
	if type(raw) ~= "string" or raw == "" then
		return list
	end
	for _, piece in string.split(raw, ";") do
		local id, at, flags = string.match(piece, "^(%w+)@(%d+)([bo]*)$")
		local zone = id and Z[id]
		if zone and at then
			table.insert(list, {
				zone = zone,
				at = tonumber(at) :: number,
				blunt = string.find(flags :: string, "b", 1, true) ~= nil,
				open = string.find(flags :: string, "o", 1, true) ~= nil,
			})
		end
	end
	return list
end

-- The monitor's numbers for a body. blood: %, pulse: bpm, vital: "Alive" | "Unconscious" | "Dead",
-- wounds: Anatomy.parseWounds (each with its own blow and still-bleeding flags).
-- The head and the neck (round 3, M2): a round there costs more blood and pulse, and the
-- crosshair's hit mark turns red.
Anatomy.HEAD_ZONES = { Brain = true, Skull = true, Jaw = true, Neck = true } :: { [string]: boolean }
-- Round 4, M10: where a gun round kills at once (the owner's rule: any round to the head). The neck
-- is not one: its carotid bleeds out fast instead.
Anatomy.HEADSHOT = { Brain = true, Skull = true, Jaw = true } :: { [string]: boolean }
Anatomy.MAJOR_BLEED = 4 -- %/s: a zone that bleeds this fast is a big vessel (heart, aorta, neck, femoral)
-- The GCS's parts for each total the monitor shows (Teasdale & Jennett; E eyes, V words, M movement):
-- alert 4/5/6, confused (talks, muddled) 4/4/6, drowsy (eyes to voice, localises pain) 3/4/5,
-- stupor (eyes to pain, sounds, localises pain) 2/2/5... out cold 1/1/4 (withdraws from pain),
-- none 1/1/1.
Anatomy.GCS_PARTS = table.freeze({
	[15] = { 4, 5, 6 },
	[14] = { 4, 4, 6 },
	[12] = { 3, 4, 5 },
	[9] = { 2, 2, 5 },
	[6] = { 1, 1, 4 },
	[3] = { 1, 1, 1 },
})
Anatomy.VF_TIME = 8 -- s after the heart stops that it fibrillates before the line goes flat

-- The heart's trace at `t` s into a beat of `period` s, in -1..1 (P, QRS, T; the waves keep their
-- length at a normal rate and squeeze when the heart races).
function Anatomy.ecgAt(t: number, period: number): number
	local k = math.min(1, period / 0.8)
	local function bump(at: number, width: number, height: number): number
		local x = (t - at * k) / (width * k)
		return height * math.exp(-x * x)
	end
	return bump(0.12, 0.035, 0.12) -- P
		+ bump(0.205, 0.008, -0.12) -- Q
		+ bump(0.225, 0.010, 1) -- R
		+ bump(0.245, 0.009, -0.28) -- S
		+ bump(0.46, 0.06, 0.26) -- T
end

-- Ventricular fibrillation at `t` s: a chaotic, fast, irregular wave (coarse at first, finer as it
-- goes on: `age` s since the heart stopped), in -1..1.
function Anatomy.vfAt(t: number, age: number): number
	local coarse = math.clamp(1 - age / Anatomy.VF_TIME, 0.25, 1)
	return coarse * (0.42 * math.sin(t * 2 * math.pi * 4.7) + 0.3 * math.sin(t * 2 * math.pi * 6.9 + 1.3) + 0.22 * math.sin(t * 2 * math.pi * 3.1 + 2.1))
end

-- The pulse oximeter's wave at `t` s into a beat of `period` s, 0..1: a quick upstroke, a rounded
-- top, the dicrotic notch on the way down.
function Anatomy.plethAt(t: number, period: number): number
	local u = (t % period) / period
	local function bump(at: number, width: number, height: number): number
		local x = (u - at) / width
		return height * math.exp(-x * x)
	end
	return math.clamp(bump(0.28, 0.11, 1) + bump(0.52, 0.07, 0.32), 0, 1.1)
end

-- The heart's trace over a stretch of time a column of the strip covers (`t0`..`t1` s into a beat of
-- `period` s, either may run past the beat into the next): its lowest and highest points and where
-- it ends. A column is tens of ms on a narrow (phone) strip and the R wave 20, so a column drawn from
-- one sample would miss it: this samples every ECG_STEP s and keeps the extremes (round 3, M5 fix 1).
Anatomy.ECG_STEP = 0.002
function Anatomy.ecgSpan(t0: number, t1: number, period: number): (number, number, number)
	local n = math.clamp(math.ceil((t1 - t0) / Anatomy.ECG_STEP), 1, 64)
	local lo, hi, last = math.huge, -math.huge, 0
	for i = 0, n do
		local t = (t0 + (t1 - t0) * i / n) % period
		last = Anatomy.ecgAt(t, period)
		lo, hi = math.min(lo, last), math.max(hi, last)
	end
	return lo, hi, last
end
Anatomy.TEMP_REST = 36.8 -- degrees C

-- The ATLS class of haemorrhage for a share of the blood lost (%).
function Anatomy.hemorrhageClass(lossPct: number): string
	return if lossPct < 15 then "I" elseif lossPct < 30 then "II" elseif lossPct < 40 then "III" else "IV"
end

-- The `deadFor` the monitor reads off a body's DiedAt and DeathCause (VitalsService) at server time
-- `now`. Round 4, M10: a brain kill gives nil (no fibrillation: the line is flat at once).
function Anatomy.stoppedFor(diedAt: unknown, cause: unknown, now: number): number?
	if type(diedAt) ~= "number" or cause == "Brain" then
		return nil
	end
	return now - diedAt
end

-- `deadFor` (optional): seconds since the heart stopped (the server's DiedAt): a fresh stop
-- fibrillates first, then the line goes flat.
function Anatomy.monitor(blood: number, pulse: number, vital: string, wounds: { SharedWound }, deadFor: number?): Reading
	local loss = math.clamp(100 - blood, 0, 100)
	-- A shot lung (not a blow on the chest) stays shot until the body is patched up (the server's
	-- list is cleared then); each lung counts once, however often it was hit.
	local shotLungs: { [string]: boolean } = {}
	local lungs = 0
	for _, w in wounds do
		if (w.zone.id == "LeftLung" or w.zone.id == "RightLung") and not w.blunt and not shotLungs[w.zone.id] then
			shotLungs[w.zone.id] = true
			lungs += 1
		end
	end
	-- Cooling with the blood lost (haemorrhagic shock: class III and IV run cold, the "lethal triad").
	-- A probe still reads a body whose heart has stopped (it cools about 1 C an hour: unseen here).
	local temp = math.floor(math.max(34, Anatomy.TEMP_REST - math.max(0, loss - 15) * 0.05) * 10 + 0.5) / 10
	if vital == "Dead" then
		local vf = deadFor ~= nil and deadFor < Anatomy.VF_TIME
		return {
			hr = 0, rhythm = if vf then "Ventricular fibrillation" else "Asystole", systolic = 0, diastolic = 0, spo2 = nil, resp = 0,
			bloodPct = math.floor(blood + 0.5), bloodMl = math.floor(Anatomy.BLOOD_ML * blood / 100 / 10 + 0.5) * 10,
			gcs = 3, consciousness = "None", severity = "Dead",
			eyes = 1, verbal = 1, motor = 1, hemorrhage = "", temp = temp, vf = vf,
		}
	end
	-- Pressure: held to 30% lost (it narrows: the lower number rises a little), then falling.
	local systolic, diastolic
	if loss <= 15 then
		systolic, diastolic = 120, 80
	elseif loss <= 30 then
		systolic, diastolic = lerp(120, 114, (loss - 15) / 15), lerp(80, 84, (loss - 15) / 15)
	elseif loss <= 40 then
		systolic, diastolic = lerp(114, 92, (loss - 30) / 10), lerp(84, 66, (loss - 30) / 10)
	else
		systolic, diastolic = lerp(92, 45, (loss - 40) / 45), lerp(66, 25, (loss - 40) / 45)
	end
	-- Breathing: quicker with every class, then shallow and failing near the end.
	-- (ATLS: I 14-20, II 20-30, III 30-40, IV over 35.)
	local resp
	if loss < 15 then
		resp = lerp(15, 19, loss / 15)
	elseif loss < 30 then
		resp = lerp(21, 29, (loss - 15) / 15)
	elseif loss < 40 then
		resp = lerp(31, 39, (loss - 30) / 10)
	elseif loss <= 70 then
		resp = lerp(39, 42, (loss - 40) / 30)
	else
		resp = lerp(42, 8, (loss - 70) / 15) -- agonal
	end
	resp += lungs * 4
	local hr = math.floor(pulse + 0.5)
	-- A heart beating too slowly pumps too little: the pressure falls with the rate.
	local output = math.clamp(hr / Anatomy.LOW_OUTPUT_HR, 0, 1)
	if output < 1 then
		local keep = 0.3 + 0.7 * output
		systolic *= keep
		diastolic *= keep
	end
	-- Oxygen: a hit lung costs it, and so does a body short of blood or a weak pulse.
	local spo2 = 98 - lungs * 5 - math.max(0, loss - 40) * 0.5 - (1 - output) * 20
	-- Awake? Blood lost clouds the mind, and so does too little pressure to the brain.
	local gcs, consciousness
	if vital == "Unconscious" then
		gcs, consciousness = 6, "Out cold"
	elseif loss < 30 then
		gcs, consciousness = 15, "Alert"
	elseif loss < 40 then
		gcs, consciousness = 14, "Confused"
	else
		gcs, consciousness = 12, "Drowsy"
	end
	if vital ~= "Unconscious" then
		if systolic < 55 then
			gcs, consciousness = math.min(gcs, 9), "Stupor"
		elseif systolic < 70 then
			gcs, consciousness = math.min(gcs, 12), "Drowsy"
		end
	end
	-- A big vessel still bleeding (that wound itself, not a bruise) is never stable, however full
	-- the body still is.
	local major = false
	for _, w in wounds do
		if w.open and not w.blunt and w.zone.bleed >= Anatomy.MAJOR_BLEED then
			major = true
		end
	end
	local severity = if vital == "Unconscious" or loss >= 40 or spo2 < 90 or systolic < 80 or hr < 40 or hr > 150 then "Critical"
		elseif loss >= 15 or lungs > 0 or major or hr > 110 or hr < 50 then "Serious"
		else "Stable"
	local parts = Anatomy.GCS_PARTS[gcs] or Anatomy.GCS_PARTS[15]
	return {
		eyes = parts[1],
		verbal = parts[2],
		motor = parts[3],
		hemorrhage = Anatomy.hemorrhageClass(loss),
		temp = temp,
		vf = false,
		hr = hr,
		rhythm = if hr <= 0 then "Asystole" elseif hr > 100 then "Sinus tachycardia" elseif hr < 60 then "Sinus bradycardia" else "Sinus rhythm",
		-- (A clinical reading beside the rhythm, not a rhythm: a heart its rounds slowed while the
		-- body is in shock, systolic 90 or less with a pulse of 90 or less (Demetriades et al. 1998,
		-- "Relative bradycardia in patients with traumatic hypotension"). The owner's rule that every
		-- round slows the heart lands here.)
		note = if hr > 0 and hr <= 90 and systolic > 0 and systolic <= 90 and loss >= 15 then "Relative bradycardia" else nil,
		systolic = math.floor(systolic + 0.5),
		diastolic = math.floor(diastolic + 0.5),
		spo2 = math.floor(math.clamp(spo2, 60, 100) + 0.5),
		resp = math.floor(resp + 0.5),
		bloodPct = math.floor(blood + 0.5),
		bloodMl = math.floor(Anatomy.BLOOD_ML * blood / 100 / 10 + 0.5) * 10,
		gcs = gcs,
		consciousness = consciousness,
		severity = severity,
	}
end

-- The game's blood (purple: unrealistic, never red) and its darker edge.
Anatomy.BLOOD = Color3.fromRGB(150, 62, 225)
Anatomy.BLOOD_DARK = Color3.fromRGB(78, 22, 128)

Anatomy.UNCONSCIOUS_AT = 45 -- % blood: out cold below this
Anatomy.DEAD_AT = 15 -- % blood: dead
Anatomy.DEAD_PULSE = 20 -- bpm: under this the heart has stopped

return table.freeze(Anatomy)
