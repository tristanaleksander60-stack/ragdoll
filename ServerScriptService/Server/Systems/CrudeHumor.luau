--!strict
-- CrudeHumor (MILD_EXTRAS A, Config.CRUDE_HUMOR; owner: "ja til A og C3"). Cartoony and silly, never gross:
--   A1 the whoopee cushion: a ragdoll that sits on a bench sometimes goes PFFRRT, jumps up and says it was not it;
--   A3 burps: a ragdoll at the picnic grill burps now and then (a sound and a little ring of air);
--   A4 the spin sick: after the washer or the gyro, a dizzy ragdoll says "blegh" and leaves a green cartoon puddle;
--   A5 the fart boost: the go-kart's BOOST goes PFFRRT with a green puff (VehicleService calls fartPuff);
--   A6 the poop emoji: a smiling cartoon poop by each picnic corner; a walking ragdoll that steps on it slips.
--   A2 the fart gun: a toy (Toys "FartGun", a place toy) that leaves a green cloud; ragdolls in it cough and run.
-- The questionnaire says crude humour: Mild.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CrudeHumor = {}

CrudeHumor.FART = "rbxassetid://137644960996530" -- (DailySoundsFX "Whoopee Cushion Big", 0.8 s)
CrudeHumor.BURP = "rbxassetid://9113414717" -- (ProSoundEffects "Belch Obnoxious 1", 0.9 s)
CrudeHumor.CUSHION_CHANCE = 0.2
local GREEN = Color3.fromRGB(150, 220, 90)

local on = false

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function holder(): Folder
	local f = Workspace:FindFirstChild("CrudeHumor")
	if not f then
		f = Instance.new("Folder")
		f.Name = "CrudeHumor"
		f.Parent = Workspace
	end
	return f :: Folder
end

local function anchorAt(at: Vector3, life: number): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one * 0.2
	p.Position = at
	p.Parent = holder()
	game:GetService("Debris"):AddItem(p, life)
	return p
end

local function sound(at: Vector3, id: string, pitch: number?, volume: number?)
	local p = anchorAt(at, 3)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.PlaybackSpeed = pitch or 1
	s.Volume = volume or 0.8
	s.RollOffMaxDistance = 90
	s.Parent = p
	s:Play()
end

local function puff(at: Vector3, color: Color3?, amount: number?)
	local p = anchorAt(at, 3)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(color or GREEN)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Lifetime = NumberRange.new(1, 1.8)
	e.Rate = 0
	e.Parent = p
	e:Emit(amount or 14)
end

local function say(m: Model, what: string)
	m:SetAttribute("MoodSay", what)
	task.delay(2.5, function()
		if m.Parent and m:GetAttribute("MoodSay") == what then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

-- A5: the go-kart's BOOST (VehicleService).
function CrudeHumor.fartPuff(body: BasePart)
	if not on then
		return
	end
	local back = body.Position - body.CFrame.LookVector * (body.Size.Z / 2 + 0.5)
	sound(back, CrudeHumor.FART, 0.75 + math.random() * 0.2, 1)
	puff(back, GREEN, 20)
end

-- A2: the fart gun (ToyService place toy "FartGun"): a green cloud; the ragdolls in it cough, hold their noses and
-- run from it, and now and then one faints comically.
local COUGH = { "*cough cough*", "EWWW!", "WHO DID THAT?!", "MY NOSE!", "Gross!" }
function CrudeHumor.fartCloud(player: Player?, at: Vector3)
	if not on then
		return
	end
	sound(at, CrudeHumor.FART, 0.7, 1)
	puff(at + Vector3.new(0, 1.5, 0), GREEN, 45)
	local dummies = Workspace:FindFirstChild("Dummies")
	for _, m in if dummies then dummies:GetChildren() else {} do
		local chest = m:FindFirstChild("UpperTorso")
		if m:IsA("Model") and chest and chest:IsA("BasePart") and (chest.Position - at).Magnitude < 10 and m:GetAttribute("Vital") ~= "Dead"
			and m:GetAttribute("InMachine") == nil then
			task.delay(math.random() * 0.6, function()
				if not m.Parent then
					return
				end
				say(m, COUGH[math.random(#COUGH)])
				if math.random() < 0.2 then
					pcall(function() -- (a comic faint)
						lazy("DummyControl").push(m, Vector3.new(math.random() - 0.5, 0.3, math.random() - 0.5).Unit * 14, player)
					end)
				else
					m:SetAttribute("PanicFrom", at)
					m:SetAttribute("PanicUntil", Workspace:GetServerTimeNow() + 4)
				end
			end)
		end
	end
end

-- A1: a ragdoll just sat down on a bench (BenchService).
function CrudeHumor.sat(m: Model)
	if not on or math.random() > CrudeHumor.CUSHION_CHANCE then
		return
	end
	task.delay(1 + math.random() * 1.5, function()
		local pe = m:FindFirstChild("LowerTorso")
		if not (m.Parent and m:GetAttribute("Seat") ~= nil and pe and pe:IsA("BasePart")) then
			return
		end
		sound(pe.Position, CrudeHumor.FART, 0.95 + math.random() * 0.2, 1)
		puff(pe.Position, GREEN, 10)
		say(m, if math.random() < 0.5 then "...wasn't me!" else "WHO PUT THAT THERE?!")
		m:SetAttribute("Mood", "Shock")
		pcall(function()
			lazy("DummyControl").push(m, Vector3.new(0, 18, 0), nil)
		end)
		task.delay(1.2, function()
			if m.Parent and m:GetAttribute("Mood") == "Shock" then
				m:SetAttribute("Mood", nil)
			end
		end)
	end)
end

-- A3, A4, A6: what the ragdolls do round the map, checked twice a second.
local poops: { { part: BasePart, last: number } } = {}

local function makePoop(at: Vector3): BasePart
	local m = Instance.new("Model")
	m.Name = "PoopEmoji"
	local brown = Color3.fromRGB(120, 72, 40)
	local base: BasePart? = nil
	for i, r in { 1.3, 1.0, 0.65 } do
		local b = Instance.new("Part")
		b.Shape = Enum.PartType.Ball
		b.Size = Vector3.new(r, r * 0.75, r)
		b.Color = brown
		b.Material = Enum.Material.SmoothPlastic
		b.Anchored, b.CanCollide, b.CanQuery = true, false, false
		b.Position = at + Vector3.new(0, 0.3 + (i - 1) * 0.42, 0)
		b.Parent = m
		if i == 1 then
			base = b
		end
	end
	for side = -1, 1, 2 do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.one * 0.2
		eye.Color = Color3.new(1, 1, 1)
		eye.Anchored, eye.CanCollide, eye.CanQuery = true, false, false
		eye.Position = at + Vector3.new(side * 0.17, 0.85, -0.42)
		eye.Parent = m
	end
	m.Parent = holder()
	return base :: BasePart
end

local function placePoops()
	for _, d in Workspace:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "PicnicTable" and #poops < 10 then
			-- (on the ground near the table, never on the grill or a bench: the first spot whose ground is low)
			for _, off in { d.CFrame.RightVector * -6, d.CFrame.LookVector * 5, d.CFrame.LookVector * -5, d.CFrame.RightVector * 6 } do
				local at = d.Position + off
				local hit = Workspace:Raycast(Vector3.new(at.X, d.Position.Y + 5, at.Z), Vector3.new(0, -20, 0))
				if hit and hit.Position.Y < d.Position.Y - 1.8 then
					table.insert(poops, { part = makePoop(hit.Position), last = 0 })
					break
				end
			end
		end
	end
end

local function watch()
	local wasIn: { [Model]: string } = setmetatable({}, { __mode = "k" }) :: any
	local grills: { BasePart } = {}
	for _, d in Workspace:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Grill" or d.Name == "PicnicGrill") then
			table.insert(grills, d)
		end
	end
	local nextBurp = os.clock() + 8
	while true do
		task.wait(0.5)
		local dummies = Workspace:FindFirstChild("Dummies")
		local now = os.clock()
		for _, m in if dummies then dummies:GetChildren() else {} do
			if m:IsA("Model") then
				-- A4: off the washer or the gyro, a dizzy blegh
				local inM = m:GetAttribute("InMachine")
				local was = wasIn[m]
				if (was == "Washer" or was == "Gyro") and inM == nil and m:GetAttribute("Vital") ~= "Dead" then
					task.delay(1.5, function()
						local head = m:FindFirstChild("Head")
						if m.Parent and head and head:IsA("BasePart") then
							say(m, "Blegh...")
							local g = Workspace:Raycast(head.Position, Vector3.new(0, -12, 0))
							if g then
								local puddle = Instance.new("Part")
								puddle.Shape = Enum.PartType.Cylinder
								puddle.Size = Vector3.new(0.06, 1.8, 1.8)
								puddle.CFrame = CFrame.new(g.Position + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, 0, math.rad(90))
								puddle.Color = GREEN
								puddle.Material = Enum.Material.SmoothPlastic
								puddle.Anchored, puddle.CanCollide, puddle.CanQuery, puddle.CanTouch = true, false, false, false
								puddle.Parent = holder()
								game:GetService("Debris"):AddItem(puddle, 8)
							end
						end
					end)
				end
				wasIn[m] = if type(inM) == "string" then inM else nil
				-- A6: a walking ragdoll steps on a poop and slips
				local pe = m:FindFirstChild("LowerTorso")
				local st = m:GetAttribute("RagdollState")
				if pe and pe:IsA("BasePart") and (st == "Walking" or st == "Fleeing") then
					for _, p in poops do
						local d = Vector3.new(pe.Position.X - p.part.Position.X, 0, pe.Position.Z - p.part.Position.Z).Magnitude
						if d < 1.4 and now - p.last > 4 then
							p.last = now
							say(m, "EWW! WHOA!")
							local fwd = pe.CFrame.LookVector
							pcall(function()
								lazy("DummyControl").push(m, fwd * 22 + Vector3.new(0, 16, 0), nil)
							end)
							sound(p.part.Position, CrudeHumor.FART, 1.4, 0.5)
						end
					end
				end
			end
		end
		-- A3: someone at the grill burps now and then
		if now >= nextBurp and #grills > 0 then
			nextBurp = now + 10 + math.random() * 10
			for _, m in if dummies then dummies:GetChildren() else {} do
				local head = m:FindFirstChild("Head")
				if head and head:IsA("BasePart") and m:GetAttribute("RagdollState") == "Standing" then
					local near = false
					for _, g in grills do
						if (g.Position - head.Position).Magnitude < 10 then
							near = true
							break
						end
					end
					if near then
						sound(head.Position, CrudeHumor.BURP, 1.1 + math.random() * 0.2, 0.9)
						say(m, "BUUURP! ...'scuse me.")
						puff(head.Position + head.CFrame.LookVector * 0.6, Color3.fromRGB(235, 235, 235), 6)
						break
					end
				end
			end
		end
	end
end

function CrudeHumor.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.CRUDE_HUMOR then
		return
	end
	on = true
	task.spawn(function()
		task.wait(12) -- (the labs are built first)
		placePoops()
		watch()
	end)
end

return CrudeHumor
