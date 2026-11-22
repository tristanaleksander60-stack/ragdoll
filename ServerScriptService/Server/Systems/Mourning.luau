--!strict
-- Mourning (V11 item 13, owner 22 Nov 2026: "ragdolls get scared when they see a body, mourn their mates, kneel now
-- and then and say oh noo, and try to give each other CPR"). Every STEP s, in each lab: a living ragdoll that sees a
-- dead one (Vital "Dead") within SEE studs may become its mourner (at most PER_BODY a body, LAB_MAX a lab, once per
-- death). It jumps (Mood "Shock": hands to the head, "Oh no!"), walks over (a player-command Home, CommandedBy -2,
-- so the lab's roaming leaves it alone), and kneels by it: Mood "Mourn" (head bowed, "Oh noo...") or "CPR"
-- (pumping the chest, "Come on! Breathe!"). CPR now and then works (SAVE_CHANCE): the body wakes early
-- (VitalsService.reviveNow), "It worked!". Otherwise it gets up after a while ("I tried..."). ActiveRagdoll holds
-- the pose (Poses.MOODS), DummyLife says the line (DummyLines.MOURN). It stops at once on a hit, a fall, a bang,
-- a hand that grabs it, or when the body is gone or up. Never zombies, the greeter, or ones in a machine.

local Players = game:GetService("Players")

local Mourning = {}

Mourning.STEP = 0.5
Mourning.SEE = 25 -- studs
Mourning.PER_BODY = 2
Mourning.LAB_MAX = 3
Mourning.JOIN_CHANCE = 0.7
Mourning.CPR_CHANCE = 0.5
Mourning.SAVE_CHANCE = 0.3
Mourning.SHOCK_TIME = 1.3
Mourning.WALK_MAX = 12
Mourning.KNEEL_TIME = 8
Mourning.CPR_TRY = 6
Mourning.SIDE = 2.4 -- studs from the body's middle where it kneels

type Job = {
	corpse: Model,
	phase: string, -- "Shock" | "Walk" | "Act"
	since: number,
	kind: string, -- "Mourn" | "CPR"
	homeWas: any,
	lookWas: any,
	owner: Player,
	tried: boolean,
}

local jobs: { [Model]: Job } = {}
local mourned: { [Model]: boolean } = {} -- bodies that had their mourners this death
local running = false

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function free(m: Model): boolean
	local state = m:GetAttribute("RagdollState")
	return m.Parent ~= nil
		and m:GetAttribute("Vital") ~= "Dead"
		and (state == "Standing" or state == "Walking")
		and m:GetAttribute("Zombie") ~= true
		and m:GetAttribute("Greeter") == nil
		and m:GetAttribute("InMachine") == nil
		and m:GetAttribute("MachineHidden") ~= true
		and m:GetAttribute("Held") ~= true
		and m:GetAttribute("CommandedBy") == nil
end

local function stop(m: Model, say: string?)
	local job = jobs[m]
	jobs[m] = nil
	if not job then
		return
	end
	m:SetAttribute("Mood", nil)
	if m:GetAttribute("CommandedBy") == -2 then
		m:SetAttribute("CommandedBy", nil)
	end
	if m.Parent then
		m:SetAttribute("Home", job.homeWas)
		m:SetAttribute("HomeLook", job.lookWas)
	end
	if say then
		m:SetAttribute("MoodSay", say)
		task.delay(3, function()
			if m.Parent and m:GetAttribute("MoodSay") == say then
				m:SetAttribute("MoodSay", nil)
			end
		end)
	end
end

local function step()
	local now = os.clock()
	local serverNow = workspace:GetServerTimeNow()
	local Lab = lazy("Lab")
	-- Bodies that are up again may be mourned at their next death.
	for body in mourned do
		if not body.Parent or body:GetAttribute("Vital") ~= "Dead" then
			mourned[body] = nil
		end
	end
	-- The running jobs.
	for m, job in jobs do
		local corpse = job.corpse
		local pelvis = pelvisOf(m)
		local cp = corpse.Parent and pelvisOf(corpse)
		local panic = m:GetAttribute("PanicUntil")
		local state = m:GetAttribute("RagdollState")
		local hurt = m:GetAttribute("Vital") == "Dead" or m:GetAttribute("Held") == true or m:GetAttribute("Zombie") == true
			or (state ~= "Standing" and state ~= "Walking") or (type(panic) == "number" and panic > serverNow)
		if not m.Parent or not pelvis or hurt then
			stop(m, nil)
		elseif not cp or corpse:GetAttribute("Vital") ~= "Dead" then
			stop(m, if job.phase == "Act" and job.kind == "CPR" then "Saved" else nil)
		elseif job.phase == "Shock" then
			if now - job.since >= Mourning.SHOCK_TIME then
				local side = flat(pelvis.Position - cp.Position)
				local dir = if side.Magnitude > 0.1 then side.Unit else Vector3.xAxis
				local spot = Vector3.new(cp.Position.X, pelvis.Position.Y, cp.Position.Z) + dir * Mourning.SIDE
				job.phase, job.since = "Walk", now
				m:SetAttribute("Mood", nil)
				m:SetAttribute("Home", spot)
				m:SetAttribute("HomeLook", cp.Position)
			end
		elseif job.phase == "Walk" then
			local home = m:GetAttribute("Home")
			local gap = if typeof(home) == "Vector3" then flat(home - pelvis.Position).Magnitude else 0
			if gap < 3.2 and state == "Standing" then
				job.phase, job.since = "Act", now
				m:SetAttribute("Home", pelvis.Position)
				m:SetAttribute("Mood", job.kind)
			elseif now - job.since > Mourning.WALK_MAX then
				stop(m, nil)
			end
		elseif job.phase == "Act" then
			local held = now - job.since
			if job.kind == "CPR" and not job.tried and held >= Mourning.CPR_TRY then
				job.tried = true
				if math.random() < Mourning.SAVE_CHANCE then
					local ok = pcall(function()
						lazy("VitalsService").reviveNow(corpse)
					end)
					stop(m, if ok then "Saved" else "Gone")
					continue
				end
			end
			if held >= Mourning.KNEEL_TIME + (if job.kind == "CPR" then 2 else 0) then
				stop(m, "Gone")
			end
		end
	end
	-- New mourners.
	for _, owner in Players:GetPlayers() do
		if not Lab.plotIndex(owner) then
			continue
		end
		local dummies = Lab.dummiesOf(owner)
		local busy = 0
		for _, j in jobs do
			if j.owner == owner then
				busy += 1
			end
		end
		for _, body in dummies do
			if busy >= Mourning.LAB_MAX then
				break
			end
			if body:GetAttribute("Vital") ~= "Dead" or mourned[body] or body:GetAttribute("MachineHidden") == true or body:GetAttribute("InMachine") ~= nil then
				continue
			end
			local bp = pelvisOf(body)
			if not bp then
				continue
			end
			mourned[body] = true
			local near: { { m: Model, d: number } } = {}
			for _, m in dummies do
				local p = pelvisOf(m)
				if m ~= body and not jobs[m] and p and free(m) then
					local d = (p.Position - bp.Position).Magnitude
					if d <= Mourning.SEE then
						table.insert(near, { m = m, d = d })
					end
				end
			end
			table.sort(near, function(a, b)
				return a.d < b.d
			end)
			local taken = 0
			for _, n in near do
				if taken >= Mourning.PER_BODY or busy >= Mourning.LAB_MAX then
					break
				end
				if math.random() < Mourning.JOIN_CHANCE then
					local m = n.m
					local p = pelvisOf(m) :: BasePart
					jobs[m] = {
						corpse = body,
						phase = "Shock",
						since = now,
						kind = if taken == 0 and math.random() < Mourning.CPR_CHANCE then "CPR" else "Mourn",
						homeWas = m:GetAttribute("Home"),
						lookWas = m:GetAttribute("HomeLook"),
						owner = owner,
						tried = false,
					}
					m:SetAttribute("CommandedBy", -2)
					m:SetAttribute("Home", p.Position)
					m:SetAttribute("HomeLook", bp.Position)
					m:SetAttribute("Mood", "Shock")
					taken += 1
					busy += 1
				end
			end
		end
	end
end

function Mourning.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while true do
			task.wait(Mourning.STEP)
			local ok, err = pcall(step)
			if not ok then
				warn("[Mourning] " .. tostring(err))
			end
		end
	end)
end

return Mourning
