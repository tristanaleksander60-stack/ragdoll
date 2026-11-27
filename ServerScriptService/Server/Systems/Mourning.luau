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

-- (23 Nov 2026, owner: CPR works SAVE_CHANCE of the time; of the rest ANGRY_CHANCE turn angry: a sour face, "You killed my ...!", and it runs
-- up and boxes the player until they die, it dies, or ATTACK_MAX s: phase "Attack", Moods "Angry" and "Box".)

local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Mourning = {}

Mourning.STEP = 0.25
Mourning.SEE = 25 -- studs
Mourning.PER_BODY = 1 -- (23 Nov 2026, owner: "only 1 ragdoll goes to give CPR")
Mourning.LAB_MAX = 3
Mourning.JOIN_CHANCE = 0.85
Mourning.CPR_CHANCE = 0.5
Mourning.SAVE_CHANCE = 0.33
Mourning.ANGRY_CHANCE = 0.77 -- of the ones that fail
Mourning.REACT_TIME = 3
Mourning.SHOCK_TIME = 0.9
Mourning.WALK_MAX = 12
Mourning.REACH = 3.9 -- studs
Mourning.HIT_GAP = 0.8
Mourning.HIT_LANDS = 0.2 -- s from the start of a punch until the fist is there
Mourning.HIT_DAMAGE = 12
Mourning.SHOVE = 10
Mourning.ATTACK_MAX = 90
Mourning.SIDE = 1.6 -- studs from the body's middle where it kneels

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
	m:SetAttribute("MournedName", nil)
	m:SetAttribute("Provoked", nil)
	job.corpse:SetAttribute("BeingHelped", nil)
	local angry: any = job
	if angry.target then
		m:SetAttribute("Personality", angry.personWas)
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

local SHOCK_MOODS = { "Shock", "Gasp", "Point" }
local CPR_MOODS = { "CPR", "CPRFast", "CPRSlam", "CPROne" }
local SAVED_MOODS = { "Cheer", "Relief", "Hug" }
local GONE_MOODS = { "Mourn", "Despair", "Sky" }

local lastMood: { [any]: string } = {}
-- One of the list, never the one picked last time.
local function pickMood(list: { string }): string
	local pick = list[math.random(#list)]
	if pick == lastMood[list] then
		pick = list[(table.find(list, pick) :: number) % #list + 1]
	end
	lastMood[list] = pick
	return pick
end

-- Shows how it feels for REACT_TIME s, then goes back to its own.
local function react(m: Model, job: Job, moods: { string })
	job.phase, job.since = "React", os.clock()
	job.corpse:SetAttribute("BeingHelped", nil)
	m:SetAttribute("Mood", pickMood(moods))
end

-- What this one does: feels for a pulse, presses, (mostly) breathes, presses another way.
local function cprPlan(): { { mood: string, time: number } }
	local plan = {}
	local function add(mood: string, time: number)
		table.insert(plan, { mood = mood, time = time })
	end
	if math.random() < 0.75 then
		add("Check", 1.6 + math.random() * 0.8)
	end
	add(pickMood(CPR_MOODS), 3 + math.random() * 1.5)
	if math.random() < 0.75 then
		add("Breath", 2.6)
	end
	add(pickMood(CPR_MOODS), 3 + math.random() * 1.5)
	if math.random() < 0.5 then
		add("Check", 1.4)
	end
	return plan
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

-- BODY_V2 4 (owner, 26 Nov 2026; Config.BURIAL): when the CPR fails, the helper may bury its friend first: a shovel,
-- 3 s of digging with dirt puffs, the body goes under (hidden on every screen through MachineHidden until it wakes),
-- a dirt mound and a grey "R.I.P." stone (gone after GRAVE_HOLD s, at most GRAVE_MAX a lab), a sad beat, then one
-- cringe line and it comes for the player who knocked its friend out (the ordinary attack, REVENGE_MAX s at most).
-- One burial at a time a lab; never in a newcomer's first BURY_CALM s.
Mourning.BURY_DIG = 3
Mourning.GRAVE_HOLD = 60
Mourning.GRAVE_MAX = 3
Mourning.REVENGE_MAX = 10
Mourning.BURY_CALM = 120
Mourning.REVENGE_LINES = { "It's your time.", "This one's for Gary.", "You messed with the wrong dummy.", "Prepare to get... ragdolled.", "I'm doing this for him.", "Say goodnight, buddy.", "Your time has come. Probably.", "He was two days from retirement." }
local burying: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local graves: { [Player]: { Model } } = setmetatable({}, { __mode = "k" }) :: any

local function grave(owner: Player, at: Vector3)
	local list = graves[owner] or {}
	graves[owner] = list
	while #list >= Mourning.GRAVE_MAX do
		local old = table.remove(list, 1)
		if old then
			old:Destroy()
		end
	end
	local g = Instance.new("Model")
	g.Name = "Grave"
	local function piece(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		if shape then
			p.Shape = shape
		end
		p.Parent = g
		return p
	end
	-- The ground under it.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local dummies = workspace:FindFirstChild("Dummies")
	params.FilterDescendantsInstances = if dummies then { dummies } else {}
	local hit = workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
	local floor = if hit then hit.Position else at - Vector3.new(0, 2.5, 0)
	local mound = piece("Mound", Vector3.new(6, 2.2, 3.2), CFrame.new(floor), Color3.fromRGB(112, 82, 56), Enum.Material.Ground, Enum.PartType.Ball)
	mound.CFrame = CFrame.new(floor)
	local stone = piece("Headstone", Vector3.new(2.4, 3, 0.6), CFrame.new(floor + Vector3.new(3.4, 1.5, 0)), Color3.fromRGB(140, 142, 146), Enum.Material.Slate)
	local top = piece("HeadstoneTop", Vector3.new(0.6, 2.4, 2.4), CFrame.new(floor + Vector3.new(3.4, 3, 0)) * CFrame.Angles(0, math.rad(90), math.rad(90)), Color3.fromRGB(140, 142, 146), Enum.Material.Slate, Enum.PartType.Cylinder)
	top.Size = Vector3.new(0.6, 2.4, 2.4)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(120, 150)
	gui.LightInfluence = 0.6
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = "R.I.P."
	label.TextScaled = true
	label.Font = Enum.Font.Fantasy
	label.TextColor3 = Color3.fromRGB(60, 60, 64)
	label.Parent = gui
	gui.Parent = stone
	local back = gui:Clone()
	back.Face = Enum.NormalId.Back
	back.Parent = stone
	g.Parent = workspace
	table.insert(list, g)
	task.delay(Mourning.GRAVE_HOLD, function()
		local i = table.find(list, g)
		if i then
			table.remove(list, i)
		end
		g:Destroy()
	end)
end

-- The burial, run in its own thread; ends by starting the revenge attack (or letting the helper go).
local function bury(m: Model, job: Job, target: Player)
	local a: any = job
	a.phase, a.since = "Bury", os.clock()
	burying[job.owner] = true
	pcall(function() -- (row 17: the burial funnel, step 1 of 2)
		lazy("Funnels").used(job.owner, "BurialStarted")
	end)
	local corpse = job.corpse
	local cp = pelvisOf(corpse)
	local spot = if cp then cp.Position else (pelvisOf(m) or { Position = Vector3.zero } :: any).Position
	m:SetAttribute("Mood", "Sad")
	m:SetAttribute("HomeLook", spot)
	-- The shovel in its right hand.
	local hand = m:FindFirstChild("RightHand") or m:FindFirstChild("Right Arm")
	local shovel: Model? = nil
	if hand and hand:IsA("BasePart") then
		local s = Instance.new("Model")
		s.Name = "Shovel"
		local shaft = Instance.new("Part")
		shaft.Name = "Shaft"
		shaft.Size = Vector3.new(0.25, 3.6, 0.25)
		shaft.Color = Color3.fromRGB(120, 86, 58)
		shaft.Material = Enum.Material.Wood
		shaft.CanCollide, shaft.CanQuery, shaft.CanTouch, shaft.Massless = false, false, false, true
		shaft.CFrame = hand.CFrame * CFrame.new(0, -1.2, 0)
		shaft.Parent = s
		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(1, 1.2, 0.12)
		blade.Color = Color3.fromRGB(150, 152, 158)
		blade.Material = Enum.Material.Metal
		blade.CanCollide, blade.CanQuery, blade.CanTouch, blade.Massless = false, false, false, true
		blade.CFrame = shaft.CFrame * CFrame.new(0, -2.3, 0)
		blade.Parent = s
		for _, p in { shaft, blade } do
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = hand, p
			w.Parent = p
		end
		s.Parent = m
		shovel = s
	end
	-- Dirt puffs while it digs.
	local puff = Instance.new("Attachment")
	puff.WorldPosition = spot
	puff.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(120, 92, 64))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 2.6) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(3, 7)
	e.SpreadAngle = Vector2.new(50, 50)
	e.Rate = 10
	e.Parent = puff
	task.wait(Mourning.BURY_DIG)
	e.Enabled = false
	game:GetService("Debris"):AddItem(puff, 2)
	-- Under the ground: hidden on every screen until it wakes up again.
	if corpse.Parent and corpse:GetAttribute("Vital") == "Dead" then
		corpse:SetAttribute("MachineHidden", true)
		local c
		c = corpse:GetAttributeChangedSignal("Vital"):Connect(function()
			if corpse:GetAttribute("Vital") ~= "Dead" then
				corpse:SetAttribute("MachineHidden", nil)
				c:Disconnect()
			end
		end)
		grave(job.owner, spot)
	end
	if shovel then
		shovel:Destroy()
	end
	task.wait(1.5) -- (the sad beat)
	burying[job.owner] = nil
	if not m.Parent or m:GetAttribute("Vital") == "Dead" or not target.Parent then
		stop(m, nil)
		return
	end
	-- Revenge: one cringe line, then it comes for the player.
	pcall(function() -- (row 17: the burial funnel, step 2 of 2)
		lazy("Funnels").used(job.owner, "BurialRevenge")
	end)
	m:SetAttribute("MoodSay", Mourning.REVENGE_LINES[math.random(1, #Mourning.REVENGE_LINES)])
	task.delay(3, function()
		if m.Parent then
			m:SetAttribute("MoodSay", nil)
		end
	end)
	a.phase, a.since = "Attack", os.clock()
	a.target, a.personWas, a.nextHit, a.max = target, m:GetAttribute("Personality"), os.clock() + 1.5, Mourning.REVENGE_MAX
	m:SetAttribute("Personality", "Brave")
	m:SetAttribute("Mood", "Angry")
	m:SetAttribute("Pace", 1.8)
end

-- The CPR failed: most go for the player (ANGRY_CHANCE); the others mourn and give up.
local function failed(m: Model, job: Job)
	job.corpse:SetAttribute("BeingHelped", nil)
	local target = if math.random() < Mourning.ANGRY_CHANCE then targetFor(m, job.owner) else nil
	if not target then
		react(m, job, GONE_MOODS)
		return
	end
	-- (BODY_V2 4: the burial first, then the revenge.)
	local owner = job.owner
	local joined = (owner:GetAttribute("V8JoinedAt") :: number?) or 0
	local calm = owner:GetAttribute("Newcomer") == true and workspace:GetServerTimeNow() - joined < Mourning.BURY_CALM
	if (Config :: any).BURIAL and not burying[owner] and not calm and job.corpse.Parent then
		task.spawn(bury, m, job, target)
		return
	end
	local a: any = job
	a.phase, a.since = "Attack", os.clock()
	a.target, a.personWas, a.nextHit = target, m:GetAttribute("Personality"), os.clock() + 1.5
	m:SetAttribute("Personality", "Brave")
	m:SetAttribute("Mood", if math.random() < 0.6 then "Rage" else "Angry")
	m:SetAttribute("Pace", 1.8)
end

-- (24 Nov 2026, owner: "a small chance that the ragdoll you shoot gets mad, bigger the nearer it is to dying".) near:
-- 0 whole .. 1 about to die. It comes for the one who hit it, boxing, PROVOKED_MAX s at most (phase "Attack").
Mourning.PROVOKE_LOW = 0.03
Mourning.PROVOKE_HIGH = 0.35
Mourning.PROVOKE_GAP = 0.7 -- s between two rolls for one body (an automatic gun is not twenty chances)
Mourning.PROVOKED_MAX = 25
Mourning.PROVOKED_LAB = 2 -- mad at once in a lab
local rolled: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
-- NOW 6 (owner, 26 Nov 2026): the first dummy a newcomer hits twice gets angry (unless the first shot killed it:
-- then the next one hit twice). A red face and a short tantrum, it runs at you, one harmless funny shove
-- (Config.ANGRY_SHOVE; false = it only scolds), then it runs off. Once a visit; after that only the rare
-- chance above. Player attribute FirstAngryDone.
Mourning.FIRST_ANGRY_MAX = 14 -- s it has to reach you
Mourning.FIRST_ANGRY_UNDER = 60 -- only a player with fewer takedowns than this gets the planned one
Mourning.FUNNY_SHOVE = 34 -- studs/s away from it
Mourning.FUNNY_LIFT = 18 -- studs/s up
local firstHits: { [Player]: { [Model]: number } } = setmetatable({}, { __mode = "k" }) :: any
function Mourning.chanceOf(near: number): number
	local n = math.clamp(near, 0, 1)
	return Mourning.PROVOKE_LOW + (Mourning.PROVOKE_HIGH - Mourning.PROVOKE_LOW) * n * n
end
function Mourning.provoke(m: Model, by: Player, near: number): boolean
	local now = os.clock()
	-- (NOW 6: the planned first anger, counted before the roll gap so two quick shots count.)
	local planned = false
	if (Config :: any).ANGRY_FIRST and by:GetAttribute("FirstAngryDone") ~= true then
		local td = by:GetAttribute("Takedowns")
		if type(td) ~= "number" or td < Mourning.FIRST_ANGRY_UNDER then
			local hits = firstHits[by] or {}
			firstHits[by] = hits
			hits[m] = (hits[m] or 0) + 1
			planned = hits[m] >= 2
		end
	end
	if not planned and now - (rolled[m] or -math.huge) < Mourning.PROVOKE_GAP then
		return false
	end
	rolled[m] = now
	if not running or jobs[m] or (not planned and math.random() >= Mourning.chanceOf(near)) then
		return false
	end
	local pelvis = pelvisOf(m)
	local character = by.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not pelvis or not (root and root:IsA("BasePart")) or (root.Position - pelvis.Position).Magnitude > 70 then
		return false
	end
	if m:GetAttribute("IsDummy") ~= true or m:GetAttribute("Greeter") ~= nil or m:GetAttribute("InMachine") ~= nil or m:GetAttribute("Held") == true
		or m:GetAttribute("CommandedBy") ~= nil or m:GetAttribute("Mood") ~= nil or m:GetAttribute("Frozen") == true or m:GetAttribute("Severed") ~= nil
		or m:GetAttribute("Chaser") ~= nil or m:GetAttribute("Horde") ~= nil or m:GetAttribute("Minigame") ~= nil then
		return false
	end
	local owner = lazy("Lab").ownerAt(pelvis.Position)
	if not owner or lazy("Lab").ownerAt(root.Position) ~= owner then
		return false
	end
	local mad = 0
	for _, j in jobs do
		if j.owner == owner and j.phase == "Attack" then
			mad += 1
		end
	end
	if mad >= Mourning.PROVOKED_LAB then
		return false
	end
	local job: any = { corpse = m, phase = "Attack", since = now, kind = "Provoked", homeWas = m:GetAttribute("Home"), lookWas = m:GetAttribute("HomeLook"), owner = owner, tried = false }
	job.target, job.personWas, job.nextHit, job.max = by, m:GetAttribute("Personality"), now + 1.5, Mourning.PROVOKED_MAX
	if planned then
		job.harmless, job.max = true, Mourning.FIRST_ANGRY_MAX
		by:SetAttribute("FirstAngryDone", true)
		firstHits[by] = nil
	end
	jobs[m] = job
	m:SetAttribute("Provoked", true)
	m:SetAttribute("CommandedBy", -2)
	m:SetAttribute("PanicUntil", nil)
	m:SetAttribute("Personality", "Brave")
	m:SetAttribute("Mood", if planned then "Rage" else "Angry") -- (Rage: the red face and the tantrum)
	m:SetAttribute("Pace", 1.8)
	return true
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
		or now - job.since > (a.max or Mourning.ATTACK_MAX) or lazy("Lab").ownerAt(root.Position) ~= job.owner then
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
	if now - job.since < 1.3 then
		return -- (the anger shows first)
	end
	if state == "Standing" and now - job.since > 1.2 and not (inReach and facing) then
		m:SetAttribute("Home", pelvis.Position + dir * (dist + 6)) -- (far enough off that it sets out again)
	else
		m:SetAttribute("Home", root.Position - dir * math.min(1.6, dist))
	end
	local mood = if inReach then "Box" else "Angry"
	if m:GetAttribute("Mood") ~= mood then
		m:SetAttribute("Mood", mood)
	end
	-- (NOW 6: the planned first anger: one funny shove, or only a scolding, then it runs off.)
	if a.harmless and inReach and facing and (state == "Standing" or state == "Walking") and m:GetAttribute("Held") ~= true and now >= a.nextHit then
		-- F26 (Config.SHOVE_SERIES): a random 1-3 shoves, each with its own line and a short wind-up; it follows if the
		-- player backs off (Home stays on the player); a hit that knocks it over ends the series. Then it flees.
		local series = (Config :: any).SHOVE_SERIES == true
		if series and not a.shoves then
			a.shoves = math.random(1, 3)
			a.shoved = 0
		end
		a.shoved = (a.shoved or 0) + 1
		local last = not series or a.shoved >= a.shoves
		a.nextHit = if last then math.huge else now + Mourning.HIT_LANDS + 1.1
		local shove = (Config :: any).ANGRY_SHOVE ~= false
		if series then
			local lines = { "Hey!", "Stop that!", "How do YOU like it?" }
			m:SetAttribute("MoodSay", lines[math.min(a.shoved, #lines)])
		end
		if shove then
			m:SetAttribute("Punch", ((m:GetAttribute("Punch") :: number?) or 0) + 1)
		end
		task.delay(if shove then Mourning.HIT_LANDS else 1.6, function()
			if jobs[m] ~= job then
				return
			end
			local st = m:GetAttribute("RagdollState")
			local knocked = series and st ~= "Standing" and st ~= "Walking"
			if knocked then
				last = true -- (knocked over mid-series: no more shoves)
				a.nextHit = math.huge
			end
			if shove and not knocked and root.Parent and flat(root.Position - pelvis.Position).Magnitude <= Mourning.REACH + 1 then
				root.AssemblyLinearVelocity += dir * Mourning.FUNNY_SHOVE + Vector3.new(0, Mourning.FUNNY_LIFT, 0)
				pcall(function()
					lazy("FxService").hit(root.Position, 30, "Punch")
				end)
			end
			if not last then
				return
			end
			m:SetAttribute("MoodSay", nil)
			stop(m, nil)
			m:SetAttribute("PanicFrom", root.Position)
			m:SetAttribute("PanicUntil", workspace:GetServerTimeNow() + 4)
		end)
		return
	end
	if a.harmless then
		return
	end
	if inReach and facing and (state == "Standing" or state == "Walking") and m:GetAttribute("Held") ~= true and now >= a.nextHit then
		a.nextHit = now + Mourning.HIT_GAP
		m:SetAttribute("Punch", ((m:GetAttribute("Punch") :: number?) or 0) + 1) -- (every screen draws the punch: DummyLife)
		task.delay(Mourning.HIT_LANDS, function()
		local standing = m:GetAttribute("RagdollState")
		if jobs[m] ~= job or hum.Health <= 0 or not root.Parent or not pelvis.Parent or (standing ~= "Standing" and standing ~= "Walking")
			or flat(root.Position - pelvis.Position).Magnitude > Mourning.REACH + 1 then
			return -- (stepped back, or knocked down before it landed: a miss)
		end
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
		if job.phase == "Attack" then
			attack(m, job, now)
			continue
		end
		if job.phase == "Bury" then
			continue -- (BODY_V2 4: the burial runs in its own thread)
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
		elseif job.phase == "React" then
			if now - job.since >= Mourning.REACT_TIME then
				stop(m, nil)
			end
		elseif not cp or corpse:GetAttribute("Vital") ~= "Dead" then
			stop(m, nil)
		elseif job.phase == "Shock" then
			if now - job.since >= Mourning.SHOCK_TIME then
				-- (By its chest, on the near side of it, so the hands reach.)
				local chest = corpse:FindFirstChild("UpperTorso")
				local aim = if chest and chest:IsA("BasePart") then chest.Position else cp.Position
				local side = flat(pelvis.Position - aim)
				local along = flat(aim - cp.Position)
				if along.Magnitude > 0.3 then
					local across = Vector3.new(-along.Z, 0, along.X).Unit
					side = if side:Dot(across) < 0 then -across else across
				end
				local dir = if side.Magnitude > 0.1 then side.Unit else Vector3.xAxis
				local spot = Vector3.new(aim.X, pelvis.Position.Y, aim.Z) + dir * Mourning.SIDE
				job.phase, job.since = "Walk", now
				m:SetAttribute("Mood", nil)
				m:SetAttribute("Pace", 2) -- (it runs to it)
				m:SetAttribute("Home", spot)
				m:SetAttribute("HomeLook", aim)
			end
		elseif job.phase == "Walk" then
			local home = m:GetAttribute("Home")
			local gap = if typeof(home) == "Vector3" then flat(home - pelvis.Position).Magnitude else 0
			if gap < 3.2 and state == "Standing" then
				job.phase, job.since = "Act", now
				m:SetAttribute("Pace", nil)
				-- (F15, owner 26 Nov 2026: CPR faces the patient: it kneels level with the chest, turned to it.)
				if (Config :: any).CPR_FACE then
					local chest = corpse:FindFirstChild("UpperTorso")
					local aim = if chest and chest:IsA("BasePart") then chest.Position else cp.Position
					local off = flat(pelvis.Position - aim)
					local dir = if off.Magnitude > 0.1 then off.Unit else Vector3.xAxis
					m:SetAttribute("Home", Vector3.new(aim.X, pelvis.Position.Y, aim.Z) + dir * Mourning.SIDE)
					m:SetAttribute("HomeLook", aim)
				else
					m:SetAttribute("Home", pelvis.Position)
				end
				local a: any = job
				a.plan, a.turn, a.nextAt = cprPlan(), 0, now
				a.works = math.random() < Mourning.SAVE_CHANCE
			elseif now - job.since > Mourning.WALK_MAX then
				stop(m, nil)
			end
		elseif job.phase == "Act" then
			-- (23 Nov 2026, owner: better CPR, different every time.) The job's own plan of moods, one after the other;
			-- whether it works was drawn when it knelt (SAVE_CHANCE).
			local a: any = job
			if now >= a.nextAt then
				a.turn += 1
				local stage = a.plan[a.turn]
				if stage then
					a.nextAt = now + stage.time
					m:SetAttribute("Mood", stage.mood)
					-- (F15: before each round of compressions it aims again at the chest, wherever the body has slid.)
					local chest = corpse:FindFirstChild("UpperTorso")
					if (Config :: any).CPR_FACE and chest and chest:IsA("BasePart") then
						m:SetAttribute("HomeLook", chest.Position)
					end
				elseif a.works then
					local ok, woke = pcall(function()
						return lazy("VitalsService").reviveNow(corpse)
					end)
					if ok and woke then
						react(m, job, SAVED_MOODS)
						task.delay(7, function()
							if corpse.Parent and corpse:GetAttribute("Vital") == "Alive" and corpse:GetAttribute("Mood") == nil then
								corpse:SetAttribute("MoodSay", "Thanks")
								task.delay(3, function()
									if corpse.Parent and corpse:GetAttribute("MoodSay") == "Thanks" then
										corpse:SetAttribute("MoodSay", nil)
									end
								end)
							end
						end)
					else
						failed(m, job)
					end
				else
					failed(m, job)
				end
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
					m:SetAttribute("Mood", pickMood(SHOCK_MOODS))
					local name = body:GetAttribute("PersonName")
					m:SetAttribute("MournedName", if type(name) == "string" and name ~= "" then name else "buddy")
					body:SetAttribute("BeingHelped", true) -- (it does not wake by itself meanwhile)
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
