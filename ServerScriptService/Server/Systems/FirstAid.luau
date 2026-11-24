--!strict
-- FirstAid (24 Nov 2026, owner: "if a ragdoll is hurt, another comes and helps it: it looks like it winds a bandage round
-- the hurt place, and then the colour is normal again"). Every STEP s, in each lab: a body with fresh wounds that is
-- calm again gets a helper, the nearest free whole one within SEE studs. It runs over (Home, CommandedBy -6), stands
-- or kneels by the hurt place and winds (Moods WrapHigh / WrapMid / WrapLow, Poses), one hurt place after another;
-- each is then well (VitalsService.dress). The patient stands still meanwhile, the hurt arm held out (PatientLeft /
-- PatientRight). Both talk (DummyLines.MOURN). It stops on a fall, a bang, a hand, a death.

local Players = game:GetService("Players")

local FirstAid = {}

FirstAid.STEP = 0.25
FirstAid.SEE = 55 -- studs
FirstAid.LAB_MAX = 3
FirstAid.WAIT = 2.5 -- s after the last wound
FirstAid.WIND = 4 -- s at one hurt place
FirstAid.WALK_MAX = 14
FirstAid.SIDE = 2.2 -- studs from the hurt place
FirstAid.GAP = 5 -- s before the same body is tried again
local MINE = -6

type Job = { patient: Model, phase: string, since: number, owner: Player, group: string, homeWas: any, lookWas: any, pHome: any, pLook: any, held: boolean }
local jobs: { [Model]: Job } = {}
local tended: { [Model]: boolean } = {}
local later: { [Model]: number } = {}
local running = false

local PART = { LeftArm = "LeftLowerArm", RightArm = "RightLowerArm", LeftLeg = "LeftLowerLeg", RightLeg = "RightLowerLeg", Body = "UpperTorso", Head = "Head" } :: { [string]: string }

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function partOf(m: Model, name: string): BasePart?
	local p = m:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function panicking(m: Model): boolean
	local panic = m:GetAttribute("PanicUntil")
	return type(panic) == "number" and panic > workspace:GetServerTimeNow()
end

local function usable(m: Model): boolean
	return m.Parent ~= nil and m:GetAttribute("Greeter") == nil and m:GetAttribute("InMachine") == nil and m:GetAttribute("MachineHidden") ~= true
		and m:GetAttribute("Held") ~= true and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("Mood") == nil
		and m:GetAttribute("Frozen") ~= true and not panicking(m)
end

local function upright(m: Model): boolean
	local s = m:GetAttribute("RagdollState")
	return s == "Standing" or s == "Walking"
end

local function nameOf(m: Model): string
	local n = m:GetAttribute("PersonName")
	return if type(n) == "string" and n ~= "" then n else "buddy"
end

local function say(m: Model, what: string)
	m:SetAttribute("MoodSay", what)
	task.delay(3, function()
		if m.Parent and m:GetAttribute("MoodSay") == what then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

local function stop(m: Model, done: boolean)
	local job = jobs[m]
	jobs[m] = nil
	if not job then
		return
	end
	local p = job.patient
	tended[p] = nil
	later[p] = os.clock() + FirstAid.GAP
	m:SetAttribute("Pace", nil)
	m:SetAttribute("Mood", nil)
	if m:GetAttribute("CommandedBy") == MINE then
		m:SetAttribute("CommandedBy", nil)
	end
	if m.Parent then
		m:SetAttribute("Home", job.homeWas)
		m:SetAttribute("HomeLook", job.lookWas)
	end
	if p.Parent then
		local mood = p:GetAttribute("Mood")
		if type(mood) == "string" and string.sub(mood, 1, 7) == "Patient" then
			p:SetAttribute("Mood", nil)
		end
		if job.held then
			if p:GetAttribute("CommandedBy") == MINE then
				p:SetAttribute("CommandedBy", nil)
			end
			p:SetAttribute("Home", job.pHome)
			p:SetAttribute("HomeLook", job.pLook)
		end
	end
	if done and m.Parent then
		say(m, "AidDone")
		task.delay(1.6, function()
			if p.Parent and p:GetAttribute("Vital") == "Alive" and p:GetAttribute("Mood") == nil then
				say(p, "AidThanks")
			end
		end)
	end
end

-- Where the helper stands: by the hurt place, outside the body.
local function spotFor(helper: BasePart, patient: Model, group: string): (Vector3?, Vector3?)
	local part = partOf(patient, PART[group])
	local pelvis = partOf(patient, "LowerTorso")
	if not (part and pelvis) then
		return nil, nil
	end
	local out = flat(helper.Position - pelvis.Position)
	if upright(patient) then
		local front = flat(pelvis.CFrame.LookVector)
		local right = flat(pelvis.CFrame.RightVector)
		local side = if string.sub(group, 1, 4) == "Left" then -1 elseif string.sub(group, 1, 5) == "Right" then 1 else 0
		out = front + right * side * 0.9
	end
	local dir = if out.Magnitude > 0.1 then out.Unit else Vector3.zAxis
	local at = Vector3.new(part.Position.X, helper.Position.Y, part.Position.Z) + dir * FirstAid.SIDE
	return at, part.Position
end

local function moodFor(patient: Model, group: string): string
	if not upright(patient) or group == "LeftLeg" or group == "RightLeg" then
		return "WrapLow"
	end
	return if group == "Head" then "WrapHigh" else "WrapMid"
end

-- The patient keeps still.
local function hold(job: Job)
	local p = job.patient
	local pelvis = partOf(p, "LowerTorso")
	if job.held or not pelvis or not upright(p) or p:GetAttribute("CommandedBy") ~= nil then
		return
	end
	job.held = true
	job.pHome, job.pLook = p:GetAttribute("Home"), p:GetAttribute("HomeLook")
	p:SetAttribute("CommandedBy", MINE)
	p:SetAttribute("Home", pelvis.Position)
	p:SetAttribute("HomeLook", pelvis.Position + flat(pelvis.CFrame.LookVector) * 8)
end

local function tendJob(m: Model, job: Job, now: number, Vitals: any)
	local p = job.patient
	local mp = partOf(m, "LowerTorso")
	local pp = if p.Parent then partOf(p, "LowerTorso") else nil
	local vital = p:GetAttribute("Vital")
	if not m.Parent or not mp or not upright(m) or m:GetAttribute("Vital") ~= "Alive" or m:GetAttribute("Held") == true or panicking(m)
		or not pp or vital == "Dead" or p:GetAttribute("Held") == true or p:GetAttribute("InMachine") ~= nil or panicking(p)
		or (mp.Position - pp.Position).Magnitude > FirstAid.SEE + 20 then
		stop(m, false)
		return
	end
	if job.phase == "Walk" then
		hold(job)
		local spot, look = spotFor(mp, p, job.group)
		if not spot then
			stop(m, false)
			return
		end
		local gap = flat(spot - mp.Position).Magnitude
		local near = flat(pp.Position - mp.Position).Magnitude
		if (gap < 1.6 or (near < 4.6 and now - job.since > 2)) and m:GetAttribute("RagdollState") == "Standing" then
			job.phase, job.since = "Wind", now
			m:SetAttribute("Pace", nil)
			m:SetAttribute("MoodSay", nil)
			m:SetAttribute("Home", mp.Position)
			m:SetAttribute("HomeLook", look)
			m:SetAttribute("Mood", moodFor(p, job.group))
			if job.held then
				p:SetAttribute("Mood", if job.group == "LeftArm" then "PatientLeft" elseif job.group == "RightArm" then "PatientRight" else "PatientStill")
			end
		elseif now - job.since > FirstAid.WALK_MAX then
			stop(m, false)
		else
			local home = m:GetAttribute("Home")
			if typeof(home) ~= "Vector3" or flat(home - spot).Magnitude > 1.5 then
				m:SetAttribute("Home", spot)
			end
			m:SetAttribute("HomeLook", look)
		end
	elseif flat(pp.Position - mp.Position).Magnitude > 7 then
		stop(m, false) -- (it went off)
	elseif now - job.since >= FirstAid.WIND then
		Vitals.dress(p, job.group)
		local nextGroup = Vitals.aidNeed(p)
		if nextGroup then
			job.group, job.phase, job.since = nextGroup, "Walk", now
			m:SetAttribute("Mood", nil)
			p:SetAttribute("Mood", nil)
		else
			stop(m, true)
		end
	end
end

local function step()
	local now = os.clock()
	local Lab = lazy("Lab")
	local Vitals = lazy("VitalsService")
	for m, at in later do
		if not m.Parent or now > at + 60 then
			later[m] = nil
		end
	end
	for m, job in table.clone(jobs) do
		tendJob(m, job, now, Vitals)
	end
	for _, owner in Players:GetPlayers() do
		if not Lab.plotIndex(owner) then
			continue
		end
		local busy = 0
		for _, j in jobs do
			if j.owner == owner then
				busy += 1
			end
		end
		local dummies = Lab.dummiesOf(owner)
		for _, p in dummies do
			if busy >= FirstAid.LAB_MAX then
				break
			end
			local vital = p:GetAttribute("Vital")
			if tended[p] or jobs[p] or now < (later[p] or 0) or (vital ~= "Alive" and vital ~= "Unconscious") or not usable(p) or p:GetAttribute("RagdollState") == "Fleeing" then
				continue
			end
			local group, age = Vitals.aidNeed(p)
			local pp = partOf(p, "LowerTorso")
			if not group or age < FirstAid.WAIT or not pp or pp.AssemblyLinearVelocity.Magnitude > 12 then
				continue
			end
			local best: Model? = nil
			local bestD = FirstAid.SEE
			for _, m in dummies do
				local mp = partOf(m, "LowerTorso")
				if m ~= p and mp and not jobs[m] and not tended[m] and m:GetAttribute("Vital") == "Alive" and upright(m) and usable(m)
					and m:GetAttribute("Severed") == nil and not Vitals.aidNeed(m) then
					local d = (mp.Position - pp.Position).Magnitude
					if d < bestD then
						best, bestD = m, d
					end
				end
			end
			if not best then
				later[p] = now + 2
				continue
			end
			local m = best :: Model
			local spot, look = spotFor(partOf(m, "LowerTorso") :: BasePart, p, group)
			if spot then
				jobs[m] = { patient = p, phase = "Walk", since = now, owner = owner, group = group, homeWas = m:GetAttribute("Home"),
					lookWas = m:GetAttribute("HomeLook"), pHome = nil, pLook = nil, held = false }
				tended[p] = true
				busy += 1
				m:SetAttribute("CommandedBy", MINE)
				m:SetAttribute("Pace", 1.8)
				m:SetAttribute("Home", spot)
				m:SetAttribute("HomeLook", look)
				m:SetAttribute("MournedName", nameOf(p))
				p:SetAttribute("MournedName", nameOf(m))
				say(m, "AidComing")
			end
		end
	end
end

function FirstAid.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while true do
			task.wait(FirstAid.STEP)
			local ok, err = pcall(step)
			if not ok then
				warn("[FirstAid] " .. tostring(err))
			end
		end
	end)
end

return FirstAid
