--!strict
-- Mourning (V11 item 13, owner 22 Nov 2026: "ragdolls get scared when they see a body, mourn their mates, kneel now
-- and then and say oh noo, and try to give each other CPR"). Every STEP s, in each lab: a living ragdoll that sees a
-- dead one (Vital "Dead") within SEE studs may become its mourner (at most PER_BODY a body, LAB_MAX a lab, once per
-- death). It jumps (Mood "Shock": hands to the head, "Oh no!"), walks over (a player-command Home, CommandedBy -2,
-- so the lab's roaming leaves it alone), and kneels by it: Mood "Mourn" (head bowed, "Oh noo...") or "CPR"
-- (pumping the chest, "Come on! Breathe!"). CPR now and then works (SAVE_CHANCE): the body wakes early
-- (VitalsService.reviveNow), "It worked!". Otherwise it gets up after a while ("I tried..."). ActiveRagdoll holds
-- the pose (Poses.MOODS), DummyLife says the line (DummyLines.MOURN). It stops at once on a hit, a fall, a bang,
-- a hand that grabs it, or when the body is gone or up. Never the greeter, or ones in a machine.

-- (23 Nov 2026, owner: every 3rd helper whose CPR fails turns angry: a sour face, "You killed my ...!", and it runs
-- up and boxes the player until they die, it dies, or ATTACK_MAX s: phase "Attack", Moods "Angry" and "Box".)

local Players = game:GetService("Players")

local Mourning = {}

Mourning.STEP = 0.25
Mourning.SEE = 25 -- studs
Mourning.PER_BODY = 1 -- (23 Nov 2026, owner: "only 1 ragdoll goes to give CPR")
Mourning.LAB_MAX = 3
Mourning.JOIN_CHANCE = 0.85
Mourning.CPR_CHANCE = 0.5
Mourning.SAVE_CHANCE = 0.3
Mourning.SHOCK_TIME = 0.9
Mourning.WALK_MAX = 12
Mourning.KNEEL_TIME = 12.5 -- s of CPR at most (a try every CPR_TRY s; before the body wakes by itself)
Mourning.ANGRY_EVERY = 3 -- every 3rd failed CPR in a lab attacks
Mourning.REACH = 4.6 -- studs
Mourning.HIT_GAP = 0.75
Mourning.HIT_DAMAGE = 12
Mourning.SHOVE = 10
Mourning.ATTACK_MAX = 90
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
local fails: { [number]: number } = {} -- (failed CPRs per lab player)
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
	m:SetAttribute("Pace", nil)
	local angry: any = job
	if angry.target then
		m:SetAttribute("Personality", angry.personWas)
		m:SetAttribute("MournedName", nil)
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

-- The nearest living player in the lab `owner` has.
local function targetFor(m: Model, owner: Player): Player?
	local Lab = lazy("Lab")
	local pelvis = pelvisOf(m)
	local best: Player? = nil
	local bestD = math.huge
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if pelvis and root and root:IsA("BasePart") and hum and hum.Health > 0 and Lab.ownerAt(root.Position) == owner then
			local d = (root.Position - pelvis.Position).Magnitude
			if d < bestD then
				best, bestD = p, d
			end
		end
	end
	return best
end

-- The CPR failed: every ANGRY_EVERY-th one in a lab goes for the player; the others give up.
local function failed(m: Model, job: Job)
	local id = job.owner.UserId
	fails[id] = (fails[id] or 0) + 1
	local target = if fails[id] % Mourning.ANGRY_EVERY == 0 then targetFor(m, job.owner) else nil
	if not target then
		stop(m, "Gone")
		return
	end
	local a: any = job
	a.phase, a.since = "Attack", os.clock()
	a.target, a.personWas, a.nextHit = target, m:GetAttribute("Personality"), os.clock() + 1.5
	m:SetAttribute("Personality", "Brave")
	local name = job.corpse:GetAttribute("PersonName")
	m:SetAttribute("MournedName", if type(name) == "string" and name ~= "" then name else "buddy")
	m:SetAttribute("Mood", "Angry")
	m:SetAttribute("Pace", 1.8)
end

-- One angry body's turn: after its player, and punches in reach.
local function attack(m: Model, job: Job, now: number)
	local a: any = job
	local target: Player = a.target
	local pelvis = pelvisOf(m)
	local c = target.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not m.Parent or not pelvis or m:GetAttribute("Vital") == "Dead" or m:GetAttribute("InMachine") ~= nil or m:GetAttribute("MachineHidden") == true
		or not target.Parent or not (root and root:IsA("BasePart") and hum) or hum.Health <= 0
		or now - job.since > Mourning.ATTACK_MAX or lazy("Lab").ownerAt(root.Position) ~= job.owner then
		stop(m, nil)
		return
	end
	local gap = flat(root.Position - pelvis.Position)
	local dist = gap.Magnitude
	local dir = if dist > 0.1 then gap.Unit else Vector3.zAxis
	local look = flat(pelvis.CFrame.LookVector)
	local facing = look.Magnitude > 0.1 and look.Unit:Dot(dir) > 0.3
	local state = m:GetAttribute("RagdollState")
	local inReach = dist <= Mourning.REACH and math.abs(root.Position.Y - pelvis.Position.Y) < 5
	m:SetAttribute("HomeLook", root.Position)
	if state == "Standing" and now - job.since > 1.2 and not (inReach and facing) then
		m:SetAttribute("Home", pelvis.Position + dir * (dist + 6)) -- (far enough off that it sets out again)
	else
		m:SetAttribute("Home", root.Position - dir * math.min(2.4, dist))
	end
	local mood = if inReach and state == "Standing" then "Box" else "Angry"
	if m:GetAttribute("Mood") ~= mood then
		m:SetAttribute("Mood", mood)
	end
	if inReach and facing and state == "Standing" and m:GetAttribute("Held") ~= true and now >= a.nextHit then
		a.nextHit = now + Mourning.HIT_GAP
		hum:TakeDamage(Mourning.HIT_DAMAGE)
		root.AssemblyLinearVelocity += dir * Mourning.SHOVE
		pcall(function()
			lazy("FxService").hit(root.Position, 50, "Punch")
		end)
		if hum.Health <= 0 then
			local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
			local wasted = remotes and remotes:FindFirstChild("Wasted")
			if wasted and wasted:IsA("RemoteEvent") then
				wasted:FireClient(target, 2.6, tostring(m:GetAttribute("PersonName") or "an angry dummy"), "Beaten up by ")
			end
			stop(m, nil)
		end
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
		if job.phase == "Attack" then
			attack(m, job, now)
			continue
		end
		local corpse = job.corpse
		local pelvis = pelvisOf(m)
		local cp = corpse.Parent and pelvisOf(corpse)
		local panic = m:GetAttribute("PanicUntil")
		local state = m:GetAttribute("RagdollState")
		local hurt = m:GetAttribute("Vital") == "Dead" or m:GetAttribute("Held") == true
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
				m:SetAttribute("Pace", 2) -- (it runs to it)
				m:SetAttribute("Home", spot)
				m:SetAttribute("HomeLook", cp.Position)
			end
		elseif job.phase == "Walk" then
			local home = m:GetAttribute("Home")
			local gap = if typeof(home) == "Vector3" then flat(home - pelvis.Position).Magnitude else 0
			if gap < 3.2 and state == "Standing" then
				job.phase, job.since = "Act", now
				m:SetAttribute("Pace", nil)
				m:SetAttribute("Home", pelvis.Position)
				m:SetAttribute("Mood", job.kind)
			elseif now - job.since > Mourning.WALK_MAX then
				stop(m, nil)
			end
		elseif job.phase == "Act" then
			local held = now - job.since
			local tries = math.floor(held / Mourning.CPR_TRY)
			if job.kind == "CPR" and tries > ((job :: any).tries or 0) then
				(job :: any).tries = tries
				if math.random() < Mourning.SAVE_CHANCE then
					local ok = pcall(function()
						lazy("VitalsService").reviveNow(corpse)
					end)
					stop(m, if ok then "Saved" else "Gone")
					continue
				end
			end
			if held >= Mourning.KNEEL_TIME then
				failed(m, job)
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
						kind = "CPR", -- (23 Nov 2026, owner: "it comes running in shock and helps the dead one")
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
	Players.PlayerRemoving:Connect(function(p)
		fails[p.UserId] = nil
	end)
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
