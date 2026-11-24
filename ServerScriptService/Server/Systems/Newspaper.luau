--!strict
-- Newspaper (24 Nov 2026, owner: "one of the ragdolls walks with a newspaper, holds on to it until you shoot it, then
-- another picks it up; happy and whistling, as if just back from the mailbox"). One paper a lab. Its carrier (attribute
-- Paper) roams as always, the paper welded in the right hand (Client/DummyLife holds the arm), whistling a short tune
-- now and then. A new wound, a fall, a hand or a death drops it; when it lies still the nearest free ragdoll comes over
-- (Home, CommandedBy -7), kneels and takes it.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Newspaper = {}

Newspaper.STEP = 0.3
Newspaper.FIRST = 6 -- s after the lab has ragdolls
Newspaper.LIE = 1.5 -- s it lies before anyone goes for it
Newspaper.WALK_MAX = 14
Newspaper.KNEEL = 1.1
Newspaper.LOST = 45 -- s on the ground with nobody getting it, then a new carrier has it
local MINE = -7

-- (Pro Sound Effects' short human whistles.)
local TUNES = { 9120686423, 9120687117, 9120687308, 9120686650, 9120686928, 9120681639, 9120688331, 9120679584 }

type Lab_ = { paper: BasePart?, carrier: Model?, wounds: string, fetcher: Model?, phase: string, since: number, droppedAt: number, readyAt: number, homeWas: any, lookWas: any, tuneAt: number, tune: number }
local labs: { [Player]: Lab_ } = {}
local running = false

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

local function upright(m: Model): boolean
	local s = m:GetAttribute("RagdollState")
	return s == "Standing" or s == "Walking"
end

local function woundsOf(m: Model): string
	local w = m:GetAttribute("Wounds")
	return if type(w) == "string" then w else ""
end

local function free(m: Model): boolean
	local panic = m:GetAttribute("PanicUntil")
	return m.Parent ~= nil and upright(m) and m:GetAttribute("Vital") == "Alive" and woundsOf(m) == "" and m:GetAttribute("Greeter") == nil
		and m:GetAttribute("InMachine") == nil and m:GetAttribute("MachineHidden") ~= true and m:GetAttribute("Held") ~= true
		and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("Mood") == nil and m:GetAttribute("Frozen") ~= true
		and m:GetAttribute("Severed") == nil and partOf(m, "RightHand") ~= nil
		and not (type(panic) == "number" and panic > Workspace:GetServerTimeNow())
end

local function say(m: Model, what: string)
	m:SetAttribute("MoodSay", what)
	task.delay(3, function()
		if m.Parent and m:GetAttribute("MoodSay") == what then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

local function folder(): Instance
	local f = Workspace:FindFirstChild("Newspapers")
	if not f then
		local made = Instance.new("Folder")
		made.Name = "Newspapers"
		made.Parent = Workspace
		f = made
	end
	return f :: Instance
end

-- A folded newspaper: off-white, its head line and columns on both sides.
local function make(): BasePart
	local p = Instance.new("Part")
	p.Name = "Newspaper"
	p.Size = Vector3.new(0.12, 1.05, 1.35)
	p.Color = Color3.fromRGB(226, 220, 204)
	p.Material = Enum.Material.SmoothPlastic
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		g.CanvasSize = Vector2.new(270, 210)
		g.LightInfluence = 1
		g.MaxDistance = 60
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromOffset(250, 44)
		title.Position = UDim2.fromOffset(10, 8)
		title.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(34, 32, 30)
		title.Text = "THE DAILY RAGDOLL"
		title.Parent = g
		local function ink(x: number, y: number, w: number, h: number, shade: number)
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.BackgroundColor3 = Color3.fromRGB(shade, shade, shade - 4)
			f.Position = UDim2.fromOffset(x, y)
			f.Size = UDim2.fromOffset(w, h)
			f.Parent = g
		end
		ink(10, 56, 250, 3, 40)
		ink(10, 68, 120, 80, 120) -- (the picture)
		for k = 0, 8 do
			ink(140, 68 + k * 15, if k % 4 == 3 then 80 else 118, 6, 96)
		end
		for k = 0, 2 do
			ink(10, 158 + k * 15, 118, 6, 96)
		end
		g.Parent = p
	end
	p.Parent = folder()
	return p
end

local function unweld(paper: BasePart)
	for _, w in paper:GetChildren() do
		if w:IsA("Weld") then
			w:Destroy()
		end
	end
end

local function drop(lab: Lab_, now: number)
	local m = lab.carrier
	lab.carrier = nil
	lab.phase, lab.droppedAt = "Ground", now
	if m then
		m:SetAttribute("Paper", nil)
		local head = partOf(m, "Head")
		local s = head and head:FindFirstChild("Whistle")
		if s then
			s:Destroy()
		end
	end
	local paper = lab.paper
	if paper and paper.Parent then
		unweld(paper)
		paper.CanCollide = true
		paper.Massless = false
		pcall(function()
			paper:SetNetworkOwner(nil)
		end)
		paper.AssemblyLinearVelocity = Vector3.new(math.random(-6, 6), 8, math.random(-6, 6))
		paper.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
	end
end

local function give(lab: Lab_, m: Model, now: number)
	local hand = partOf(m, "RightHand")
	if not hand then
		return
	end
	local paper = lab.paper
	if not paper or not paper.Parent then
		paper = make()
		lab.paper = paper
	end
	local p = paper :: BasePart
	unweld(p)
	p.CanCollide = false
	p.Massless = true
	p.CFrame = hand.CFrame * CFrame.new(0, -0.4, 0)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = hand, p
	w.C0 = CFrame.new(0, -0.4, 0)
	w.Parent = p
	lab.carrier, lab.wounds, lab.phase, lab.since = m, woundsOf(m), "Carry", now
	lab.tuneAt = now + 1
	m:SetAttribute("Paper", true)
end

local function endFetch(lab: Lab_)
	local m = lab.fetcher
	lab.fetcher = nil
	if m and m.Parent then
		m:SetAttribute("Pace", nil)
		m:SetAttribute("Mood", nil)
		if m:GetAttribute("CommandedBy") == MINE then
			m:SetAttribute("CommandedBy", nil)
		end
		m:SetAttribute("Home", lab.homeWas)
		m:SetAttribute("HomeLook", lab.lookWas)
	end
end

local function whistle(lab: Lab_, m: Model, now: number)
	if now < lab.tuneAt then
		return
	end
	lab.tuneAt = now + 2.2 + math.random() * 3.5
	local head = partOf(m, "Head")
	if not head then
		return
	end
	local s = head:FindFirstChild("Whistle") :: Sound? -- lihfolk-ignore: findfirstchild-chain (a type cast, nil is checked below)
	if not s then
		local made = Instance.new("Sound")
		made.Name = "Whistle"
		made.Volume = 0.4
		made.RollOffMode = Enum.RollOffMode.InverseTapered
		made.RollOffMinDistance = 6
		made.RollOffMaxDistance = 45
		made.Parent = head
		s = made
	end
	lab.tune = lab.tune % #TUNES + 1
	local sound = s :: Sound
	sound.SoundId = "rbxassetid://" .. TUNES[lab.tune]
	sound.PlaybackSpeed = 0.95 + math.random() * 0.12
	sound:Play()
end

local function stepLab(owner: Player, lab: Lab_, dummies: { Model }, now: number)
	local m = lab.carrier
	if m then
		local held = lab.paper ~= nil and (lab.paper :: BasePart).Parent ~= nil
		local state = m:GetAttribute("RagdollState")
		if not m.Parent or not held then
			drop(lab, now)
		elseif #woundsOf(m) > #lab.wounds or m:GetAttribute("Vital") ~= "Alive" or m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil
			or state == "Ragdoll" or state == "Out" or state == "Crawling" or state == "Flinch" or state == "Stumble" then
			drop(lab, now)
		else
			lab.wounds = woundsOf(m)
			if upright(m) and m:GetAttribute("Mood") == nil then
				whistle(lab, m, now)
			end
		end
		return
	end
	local paper = lab.paper
	if lab.phase == "Wait" then
		if now >= lab.readyAt then
			local list = {}
			for _, d in dummies do
				if free(d) then
					table.insert(list, d)
				end
			end
			if #list > 0 then
				give(lab, list[math.random(#list)], now)
			end
		end
		return
	end
	if not paper or not paper.Parent or paper.Position.Y < -50 or now - lab.droppedAt > Newspaper.LOST then
		endFetch(lab)
		if paper then
			paper:Destroy()
		end
		lab.paper = nil
		lab.phase, lab.readyAt = "Wait", now + 4
		return
	end
	local f = lab.fetcher
	if not f then
		if now - lab.droppedAt < Newspaper.LIE or paper.AssemblyLinearVelocity.Magnitude > 3 then
			return
		end
		local best: Model? = nil
		local bestD = 90
		for _, d in dummies do
			local pelvis = partOf(d, "LowerTorso")
			if pelvis and free(d) then
				local dist = (pelvis.Position - paper.Position).Magnitude
				if dist < bestD then
					best, bestD = d, dist
				end
			end
		end
		if best then
			lab.fetcher, lab.phase, lab.since = best, "Fetch", now
			lab.homeWas, lab.lookWas = best:GetAttribute("Home"), best:GetAttribute("HomeLook")
			best:SetAttribute("CommandedBy", MINE)
			best:SetAttribute("Pace", 1.4)
			local pelvis = partOf(best, "LowerTorso") :: BasePart
			best:SetAttribute("Home", Vector3.new(paper.Position.X, pelvis.Position.Y, paper.Position.Z))
			best:SetAttribute("HomeLook", paper.Position)
			say(best, "PaperSeen")
		end
		return
	end
	local pelvis = partOf(f, "LowerTorso")
	local panic = f:GetAttribute("PanicUntil")
	if not pelvis or not upright(f) or f:GetAttribute("Vital") ~= "Alive" or f:GetAttribute("Held") == true or f:GetAttribute("CommandedBy") ~= MINE
		or (type(panic) == "number" and panic > Workspace:GetServerTimeNow()) or now - lab.since > Newspaper.WALK_MAX then
		endFetch(lab)
		lab.phase = "Ground"
		return
	end
	local gap = flat(paper.Position - pelvis.Position)
	if lab.phase == "Fetch" then
		if gap.Magnitude < 3.4 and f:GetAttribute("RagdollState") == "Standing" then
			lab.phase, lab.since = "Kneel", now
			f:SetAttribute("Pace", nil)
			f:SetAttribute("Home", pelvis.Position)
			f:SetAttribute("HomeLook", paper.Position)
			f:SetAttribute("Mood", "WrapLow")
		elseif gap.Magnitude > 3.4 then
			f:SetAttribute("Home", Vector3.new(paper.Position.X, pelvis.Position.Y, paper.Position.Z))
		end
	elseif now - lab.since >= Newspaper.KNEEL then
		endFetch(lab)
		give(lab, f, now)
		say(f, "PaperFound")
	end
end

local function step()
	local now = os.clock()
	local Lab = lazy("Lab")
	for owner, lab in labs do
		if not owner.Parent then
			if lab.paper then
				lab.paper:Destroy()
			end
			labs[owner] = nil
		end
	end
	for _, owner in Players:GetPlayers() do
		if Lab.plotIndex(owner) then
			local dummies = Lab.dummiesOf(owner)
			local lab = labs[owner]
			if not lab and #dummies >= 2 then
				lab = { paper = nil, carrier = nil, wounds = "", fetcher = nil, phase = "Wait", since = now, droppedAt = 0, readyAt = now + Newspaper.FIRST,
					homeWas = nil, lookWas = nil, tuneAt = 0, tune = math.random(#TUNES) }
				labs[owner] = lab
			end
			if lab then
				stepLab(owner, lab, dummies, now)
			end
		end
	end
end

function Newspaper.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while true do
			task.wait(Newspaper.STEP)
			local ok, err = pcall(step)
			if not ok then
				warn("[Newspaper] " .. tostring(err))
			end
		end
	end)
end

return Newspaper
