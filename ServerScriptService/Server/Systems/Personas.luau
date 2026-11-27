--!strict
-- P1 SPREAD OUT + PERSONALITIES, part 1 (owner: "nogle bliver tiltrukket af skud, andre bliver bange og løber, nogle
-- prøver at være the hero"; docs/ALWAYS3.md; Config.PERSONAS): every ragdoll gets a Persona when it appears:
--   CURIOUS 35%  a shot or hit nearby (60 studs; a break or big landing 90): it stops, walks to 12-18 studs from it,
--                looks, says "Whoa!" / "Do it again!", and goes back to its day after 10-15 s;
--   SCARED  30%  a short scream ("Aaah!", "Not again!") and it RUNS (the lab's panic run: PanicFrom / PanicUntil);
--   HERO    15%  runs to the hurt body nearest the event ("Leave him alone!", "Stop!") and stands by it 8 s;
--   CHILL   20%  a shrug line now and then ("Every day...") and goes on.
-- A reacting body is held with Watch = "React" (the lab's roam leaves it alone) and released after. Only free bodies
-- react (no role, machine, TRY, grab, mood, greeter), each at most once every REST s, and at most MAX_PER moment.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Personas = {}
local FILM_PHONE = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).FILM_PHONE == true

Personas.SHARES = { { "Curious", 35 }, { "Scared", 30 }, { "Hero", 15 }, { "Chill", 20 } }
Personas.REST = 18
Personas.MAX_PER = 4
Personas.LINES = {
	Curious = { "Whoa!", "Do it again!", "What was that?", "Cool!", "I gotta see this!", "Again! Again!" },
	Scared = { "Aaah!", "Not again!", "Run!", "Mommy!", "Nope nope nope!", "Help!" },
	Hero = { "Leave him alone!", "Stop!", "I've got you!", "Hang in there!", "Back off!", "I'm here!" },
	Chill = { "Every day...", "Meh.", "Whatever.", "Not my problem.", "Cool cool cool.", "Yawn." },
}

local lastAt: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local lastLine: { [Model]: string } = setmetatable({}, { __mode = "k" }) :: any

local function pick(): string
	local r = math.random(1, 100)
	for _, s in Personas.SHARES do
		r -= s[2]
		if r <= 0 then
			return s[1]
		end
	end
	return "Chill"
end

local function say(m: Model, kind: string)
	local list = Personas.LINES[kind]
	if not list then
		return
	end
	local line = list[math.random(1, #list)]
	if line == lastLine[m] then
		line = list[(table.find(list, line) or 0) % #list + 1]
	end
	lastLine[m] = line
	m:SetAttribute("MoodSay", line)
	task.delay(2.5, function()
		if m.Parent and m:GetAttribute("MoodSay") == line then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

local function free(m: Model): boolean
	local st = m:GetAttribute("RagdollState")
	local vital = m:GetAttribute("Vital")
	return (st == nil or st == "Standing" or st == "Walking") and vital ~= "Dead" and vital ~= "Unconscious"
		and m:GetAttribute("Watch") == nil and m:GetAttribute("Role3") == nil and m:GetAttribute("TryFor") == nil
		and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("InMachine") == nil and m:GetAttribute("Held") ~= true
		and m:GetAttribute("Mood") == nil and m:GetAttribute("Greeter") == nil and m:GetAttribute("Bowling") == nil
end

local function release(m: Model, after: number)
	task.delay(after, function()
		if m.Parent then
			m:SetAttribute("Filming", nil)
		end
		if m.Parent and m:GetAttribute("Watch") == "React" then
			m:SetAttribute("Watch", nil)
			m:SetAttribute("Home", nil)
			m:SetAttribute("HomeLook", nil)
			m:SetAttribute("Pace", nil)
		end
	end)
end

local function hurtNear(at: Vector3, dummies: Instance): Model?
	local best, bestD = nil :: Model?, 30
	for _, v in dummies:GetChildren() do
		local pe = v:FindFirstChild("LowerTorso")
		if v:IsA("Model") and pe and pe:IsA("BasePart") then
			local st = v:GetAttribute("RagdollState")
			if st == "Ragdoll" or st == "Out" or v:GetAttribute("Vital") == "Unconscious" then
				local d = (pe.Position - at).Magnitude
				if d < bestD then
					best, bestD = v, d
				end
			end
		end
	end
	return best
end

local busyUntil = 0
local function heard(kind: string, at: Vector3, dummies: Instance)
	local now = os.clock()
	if now < busyUntil then
		return
	end
	busyUntil = now + 0.5
	local reach = if kind == "Break" or kind == "Land" then 90 else 60
	local n = 0
	for _, m in dummies:GetChildren() do
		if n >= Personas.MAX_PER then
			break
		end
		local pe = m:FindFirstChild("LowerTorso")
		if not (m:IsA("Model") and pe and pe:IsA("BasePart")) then
			continue
		end
		local d = (pe.Position - at).Magnitude
		if d > reach or d < 3 or now - (lastAt[m] or -math.huge) < Personas.REST or not free(m) then
			continue
		end
		local persona = m:GetAttribute("Persona")
		if persona == "Curious" then
			lastAt[m] = now
			n += 1
			local away = Vector3.new(pe.Position.X - at.X, 0, pe.Position.Z - at.Z)
			local dir = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
			local stand = at + dir * math.random(12, 18)
			m:SetAttribute("Watch", "React")
			m:SetAttribute("Home", Vector3.new(stand.X, pe.Position.Y, stand.Z))
			m:SetAttribute("HomeLook", at)
			m:SetAttribute("Pace", 1.3)
			if FILM_PHONE and math.random() < 0.5 then
				-- (P1 rest: half the curious ones get their phone out and film it, Client/DummyLife filmLayer)
				m:SetAttribute("Filming", true)
			end
			say(m, "Curious")
			release(m, math.random(10, 15))
		elseif persona == "Scared" then
			lastAt[m] = now
			n += 1
			say(m, "Scared")
			m:SetAttribute("PanicFrom", at)
			m:SetAttribute("PanicUntil", Workspace:GetServerTimeNow() + 4 + math.random() * 2)
		elseif persona == "Hero" then
			local victim = hurtNear(at, dummies)
			local vp = victim and victim:FindFirstChild("LowerTorso")
			if victim and victim ~= m and vp and vp:IsA("BasePart") then
				lastAt[m] = now
				n += 1
				local side = Vector3.new(pe.Position.X - vp.Position.X, 0, pe.Position.Z - vp.Position.Z)
				local stand = vp.Position + (if side.Magnitude > 0.1 then side.Unit else Vector3.xAxis) * 2.5
				m:SetAttribute("Watch", "React")
				m:SetAttribute("Home", stand)
				m:SetAttribute("HomeLook", vp.Position)
				m:SetAttribute("Pace", 1.8)
				say(m, "Hero")
				release(m, 8)
			end
		elseif persona == "Chill" and math.random() < 0.3 then
			lastAt[m] = now
			say(m, "Chill")
		end
	end
end

function Personas.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.PERSONAS then
		return
	end
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		local function give(m: Instance)
			if m:IsA("Model") and m:GetAttribute("Persona") == nil then
				m:SetAttribute("Persona", pick())
			end
		end
		for _, m in dummies:GetChildren() do
			give(m)
		end
		dummies.ChildAdded:Connect(give)
		local okFx, Fx = pcall(function()
			return require(script.Parent:WaitForChild("FxService")) :: any
		end)
		if okFx and Fx then
			Fx.onMoment(function(kind: string, at: Vector3, speed: number, _toy: string, _who: number)
				if kind == "Shot" or kind == "Hit" or kind == "Break" or (kind == "Land" and speed >= 60) then
					heard(kind, at, dummies)
				end
			end)
		end
	end)
end

return Personas
