--!strict
-- F88 RAGDOLL BOWLING, part 1 (owner: "vores bedste aspekt ... vores HOOK"; docs/BOWLING_12.md; Config.BOWLING): on the
-- plan's RagdollBowling spot by the spawn (Shared/OwnerMapPlan, lab-space), built from parts:
--   a glossy maple lane with dark wood edges, 7 aiming arrows and a red foul line, chrome gutters, a lighter approach;
--   10 GIANT pins (about 5 high: a white body and head with 2 red neck stripes) with real physics, a dark padded pit
--   and kickback walls; a low roof on slim posts with 2 warm lights; a retro scoreboard (bulbs round the edge) above
--   the pins; the big RED LEVER on the approach.
-- The game: pull the lever (a ProximityPrompt "Bowl!"): the nearest free ragdoll is put on the approach, curled, and
-- rolled down the lane (a real push; the server's physics). 4.5 s later the pins are counted: STRIKE / SPARE / SPLIT /
-- GUTTER / n pins on the board, a frame is 2 rolls (a strike ends it), then the pin-setter puts the 10 pins back.
-- The board shows your frame, YOUR BEST and TODAY'S BEST (the top 3 players' names this server, no free text).
-- 1 setup in 8 has a GOLDEN pin.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Bowling = {}

Bowling.ROLL_SPEED = 58 -- studs/s down the lane
Bowling.COUNT_AFTER = 4.5
Bowling.COOLDOWN = 7 -- s between two rolls on one lane

local MAPLE = Color3.fromRGB(214, 168, 112)
local DARK_WOOD = Color3.fromRGB(92, 58, 36)
local CHROME = Color3.fromRGB(196, 202, 212)
local PIN_WHITE = Color3.fromRGB(246, 244, 238)
local PIN_RED = Color3.fromRGB(205, 30, 40)
local GOLD = Color3.fromRGB(255, 196, 40)

type Lane = {
	pins: { Model },
	homes: { CFrame },
	board: TextLabel,
	word: TextLabel,
	at: Vector3, -- the approach (where the ball starts)
	dir: Vector3, -- down the lane
	deckAt: Vector3,
	busy: boolean,
	lastRoll: number,
	roll: number, -- 1 or 2 in the frame
	first: number, -- pins down in the frame's first roll
	golden: Model?,
}

local today: { [number]: { name: string, best: number } } = {}
local strikesInRow: { [number]: number } = {} -- (BOWL_TURKEY: strikes in a row per player this visit)
local boltsGot: { [number]: number } = {} -- (BOWL_BOLTS: bolts from bowling per player this visit)

-- (F88 part 2, Config.BOWLING_FX: a pin crash on a strike with confetti, a sad trombone on a gutter)
Bowling.STRIKE_SOUND = "rbxassetid://4692687595" -- (Creator Store "Bowling Strike Sound Effect")
Bowling.GUTTER_SOUND = "rbxassetid://190705984" -- (Creator Store "Sad-Trombone")
local function sound(id: string, at: Vector3, volume: number)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.Position = at
	p.Parent = Workspace
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.RollOffMaxDistance = 160
	s.Parent = p
	s:Play()
	game:GetService("Debris"):AddItem(p, 6)
end
local function confetti(at: Vector3)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.Position = at
	p.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 200, 255)) })
	e.Size = NumberSequence.new(0.5, 0.3)
	e.Speed = NumberRange.new(18, 30)
	e.SpreadAngle = Vector2.new(50, 50)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Lifetime = NumberRange.new(1.2, 2)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.EmissionDirection = Enum.NormalId.Top
	e.Enabled = false
	e.Parent = p
	e:Emit(80)
	game:GetService("Debris"):AddItem(p, 3)
end

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?, anchored: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

local function deco(p: BasePart)
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
end

-- (BOWLING_12, Config.BOWL_BUMPERS, "kid mode": after 2 gutters in a row the lane's bumpers rise for the next roll
-- (padded rails on both edges, tweened up out of the gutter edge), then sink again after it is counted)
local guttersInRow: { [number]: number } = {}

-- (BOWLING_12, Config.BOWL_CHEERS: on a strike or a spare the standing ragdolls round the lane (35 studs of the
-- pins) cheer 2.5 s, three of them with a line; never the bowled one, one held, in a machine or with a mood)
local CHEER_LINES = { "STRIIIKE!", "WOOO!", "What a roll!", "Bowled over!", "Again! Again!" }
local function cheer(lane: any, ball: Model?)
	local folder = Workspace:FindFirstChild("Dummies")
	if not folder then
		return
	end
	local said = 0
	for _, m in folder:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		if m ~= ball and pe and pe:IsA("BasePart") and (pe.Position - lane.deckAt).Magnitude < 35 and m:GetAttribute("Mood") == nil
			and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("Held") ~= true and m:GetAttribute("InMachine") == nil
			and (m:GetAttribute("RagdollState") == nil or m:GetAttribute("RagdollState") == "Standing" or m:GetAttribute("RagdollState") == "Walking") then
			m:SetAttribute("Mood", "Cheer")
			local line: string? = nil
			if said < 3 then
				said += 1
				line = CHEER_LINES[math.random(1, #CHEER_LINES)]
				m:SetAttribute("MoodSay", line)
			end
			task.delay(2.5, function()
				if m.Parent then
					if m:GetAttribute("Mood") == "Cheer" then
						m:SetAttribute("Mood", nil)
					end
					if line and m:GetAttribute("MoodSay") == line then
						m:SetAttribute("MoodSay", nil)
					end
				end
			end)
		end
	end
end
local function setBumpers(lane: any, up: boolean)
	local rails = lane.bumpers
	if not rails or lane.bumpersUp == up then
		return
	end
	lane.bumpersUp = up
	local TweenService = game:GetService("TweenService")
	for _, r in rails do
		local home = r:GetAttribute("Home") :: CFrame
		r.CanCollide = up
		r.Transparency = 0
		local tw = TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Back, if up then Enum.EasingDirection.Out else Enum.EasingDirection.In),
			{ CFrame = if up then home else home * CFrame.new(0, -2.3, 0) })
		tw:Play()
		if not up then
			tw.Completed:Once(function()
				if not lane.bumpersUp then
					r.Transparency = 1
				end
			end)
		end
	end
end

-- One giant pin (about 5 high): a cylinder body, a ball belly and a ball head, 2 red neck stripes, welded; unanchored.
local function makePin(into: Instance, at: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "BowlingPin"
	local up = CFrame.Angles(0, 0, math.rad(90)) -- (a cylinder's axis is X)
	local props = PhysicalProperties.new(0.35, 0.35, 0.35, 1, 1) -- (light, a little bouncy: they fly and spin)
	local base = part(m, "Base", Vector3.new(2.4, 1.3, 1.3), at * CFrame.new(0, 1.2, 0) * up, PIN_WHITE, Enum.Material.SmoothPlastic, false)
	local belly = part(m, "Belly", Vector3.new(1.9, 1.9, 1.9), at * CFrame.new(0, 2.1, 0), PIN_WHITE, Enum.Material.SmoothPlastic, false)
	belly.Shape = Enum.PartType.Ball
	local neck = part(m, "Neck", Vector3.new(1.4, 0.8, 0.8), at * CFrame.new(0, 3.6, 0) * up, PIN_WHITE, Enum.Material.SmoothPlastic, false)
	local head = part(m, "Head", Vector3.new(1.15, 1.15, 1.15), at * CFrame.new(0, 4.5, 0), PIN_WHITE, Enum.Material.SmoothPlastic, false)
	head.Shape = Enum.PartType.Ball
	for i, y in { 3.35, 3.75 } do
		local s = part(m, "Stripe" .. i, Vector3.new(0.18, 0.86, 0.86), at * CFrame.new(0, y, 0) * up, PIN_RED, Enum.Material.SmoothPlastic, false)
		s.Shape = Enum.PartType.Cylinder
		deco(s)
	end
	base.Shape = Enum.PartType.Cylinder
	neck.Shape = Enum.PartType.Cylinder
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") then
			p.CustomPhysicalProperties = props
			p.Reflectance = 0.06
			if p ~= base then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = base, p
				w.Parent = p
			end
		end
	end
	m.PrimaryPart = base
	m.Parent = into
	return m
end

local function standing(pin: Model, home: CFrame): boolean
	local base = pin.PrimaryPart
	if not base then
		return false
	end
	local upY = base.CFrame.RightVector.Y -- (the base cylinder's axis is its X: up when standing)
	return math.abs(upY) > 0.8 and (base.Position - (home * CFrame.new(0, 1.2, 0)).Position).Magnitude < 2.2
end

local function resetPins(lane: Lane)
	lane.golden = nil
	local goldIdx = if math.random(1, 8) == 1 then math.random(1, #lane.pins) else 0
	for i, pin in lane.pins do
		for _, p in pin:GetChildren() do
			if p:IsA("BasePart") then
				p.AssemblyLinearVelocity = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
				if not string.match(p.Name, "^Stripe") then
					p.Color = if i == goldIdx then GOLD else PIN_WHITE
				end
			end
		end
		pin:PivotTo(lane.homes[i] * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
		if i == goldIdx then
			lane.golden = pin
		end
	end
end

local function showBoard(lane: Lane, by: Player?, word: string?)
	local me = by and today[by.UserId]
	local rows = {}
	for _, t in today do
		table.insert(rows, t)
	end
	table.sort(rows, function(a, b)
		return a.best > b.best
	end)
	local top = {}
	for i = 1, math.min(3, #rows) do
		table.insert(top, string.format("%d. %s  %d", i, rows[i].name, rows[i].best))
	end
	lane.board.Text = string.format("FRAME  roll %d\nYOUR BEST  %s\n\nTODAY'S BEST\n%s", lane.roll, if me then tostring(me.best) else "-", if #top > 0 then table.concat(top, "\n") else "be the first!")
	if word then
		lane.word.Text = word
		lane.word.TextTransparency = 0
		task.delay(2.2, function()
			if lane.word.Text == word then
				lane.word.TextTransparency = 1
			end
		end)
	end
end

-- F92 (Config.MACHINE_SAFE): the machine only CALLS a ragdoll: a free, standing one within 40 studs that is not the one
-- you hold, not one hit in the last 5 s, not one within 8 studs of a player (the one you are walking to), not in another
-- machine. It then RUNS to the approach (never a teleport from somewhere else).
local function freeRagdoll(near: Vector3): Model?
	local safe = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).MACHINE_SAFE == true
	local dummies = Workspace:FindFirstChild("Dummies")
	local walk = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).TRY_WALK == true
	local best, bestD = nil :: Model?, if walk then 80 elseif safe then 40 else 90
	local now = Workspace:GetServerTimeNow()
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = m:FindFirstChild("LowerTorso")
		if m:IsA("Model") and pe and pe:IsA("BasePart") and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("Held") ~= true
			and m:GetAttribute("InMachine") == nil and m:GetAttribute("Bowling") == nil
			and (if walk then (m:GetAttribute("Watch") ~= "Demo" and m:GetAttribute("Watch") ~= "NeverZero" and m:GetAttribute("BoxSide") == nil) else m:GetAttribute("Watch") == nil)
			and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("TryFor") == nil then
			local ok = true
			if safe then
				local st = m:GetAttribute("RagdollState")
				local hitAt = m:GetAttribute("ServerHitAt")
				ok = (st == nil or st == "Standing" or st == "Walking") and m:GetAttribute("Mood") == nil
					and not (type(hitAt) == "number" and now - hitAt < 5)
				if ok and not walk then -- (TRY_WALK: one standing by you may come: you asked for it)
					for _, pl in Players:GetPlayers() do
						local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
						if r and r:IsA("BasePart") and (r.Position - pe.Position).Magnitude < 8 then
							ok = false
						end
					end
				end
			end
			local d = (pe.Position - near).Magnitude
			if ok and d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

local function bowl(lane: Lane, by: Player)
	local now = os.clock()
	if lane.busy or now - lane.lastRoll < Bowling.COOLDOWN then
		return
	end
	local ball = freeRagdoll(lane.at)
	if not ball then
		lane.word.Text = "No ragdoll near!"
		lane.word.TextTransparency = 0
		task.delay(1.5, function()
			lane.word.TextTransparency = 1
		end)
		return
	end
	lane.busy = true
	lane.lastRoll = now
	pcall(function() -- (FIXES_27NOV_LATE 4: the onboarding's BowlingTry)
		(require(script.Parent:WaitForChild("Funnels")) :: any).step(by, "BowlingTry")
	end)
	ball:SetAttribute("Bowling", true)
	local safe = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).MACHINE_SAFE == true
	local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
	if safe then
		-- F92: it RUNS to the approach (about 2 s), and only then gets in (a short hop onto the lane)
		ball:SetAttribute("Home", lane.at - lane.dir * 2)
		ball:SetAttribute("Pace", 2.4)
		local t0 = os.clock()
		local there = false
		while os.clock() - t0 < (if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).TRY_WALK then 16 else 8) do
			local pe = ball:FindFirstChild("LowerTorso")
			if not (pe and pe:IsA("BasePart") and ball.Parent) or ball:GetAttribute("Held") == true then
				break
			end
			if (Vector3.new(pe.Position.X, 0, pe.Position.Z) - Vector3.new(lane.at.X, 0, lane.at.Z)).Magnitude < 5 then
				there = true
				break
			end
			task.wait(0.2)
		end
		ball:SetAttribute("Pace", nil)
		if not there then
			ball:SetAttribute("Bowling", nil)
			lane.busy = false
			lane.word.Text = "No ragdoll near!"
			lane.word.TextTransparency = 0
			task.delay(1.5, function()
				lane.word.TextTransparency = 1
			end)
			return
		end
		pcall(function()
			(require(script.Parent:WaitForChild("RagdollDirector")) :: any).logRemoval(ball, "Bowling", "called; ran to the approach and hopped on")
		end)
		if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).TRY_WALK then
			-- (TRY_WALK: no teleport onto the lane: a real hop from the approach onto the lane's start)
			local pe = ball:FindFirstChild("LowerTorso")
			if pe and pe:IsA("BasePart") then
				local g = Workspace.Gravity
				local rise = math.max(0, lane.at.Y + 1 - pe.Position.Y) + 2
				local vy = math.sqrt(2 * g * rise)
				local t = vy / g + math.sqrt(4 / g)
				local flat = Vector3.new(lane.at.X - pe.Position.X, 0, lane.at.Z - pe.Position.Z)
				pcall(DC.push, ball, Vector3.new(0, vy, 0) + flat / math.max(t, 0.2))
				task.wait(t + 0.15)
			end
		else
			pcall(DC.move, ball, CFrame.lookAt(lane.at + Vector3.new(0, 3, 0), lane.at + Vector3.new(0, 3, 0) + lane.dir) * CFrame.Angles(math.rad(-80), 0, 0))
		end
	else
		-- The ball: put on the approach, curled (a ragdoll on its side), then a real push down the lane.
		ball:PivotTo(CFrame.lookAt(lane.at + Vector3.new(0, 3, 0), lane.at + Vector3.new(0, 3, 0) + lane.dir) * CFrame.Angles(math.rad(-80), 0, 0))
	end
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_BALL then
		ball:SetAttribute("Curl", true) -- (F91: it tucks into a ball for the roll: ActiveRagdoll holds Poses.curl)
		local pe0 = ball:FindFirstChild("LowerTorso")
		if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_SPHERE and pe0 and pe0:IsA("BasePart") then
			-- (F91 rest, Config.BOWL_SPHERE: an invisible ball round the curled body, welded to its pelvis, so it rolls true
			-- down the lane like a bowling ball instead of tumbling on its knees; gone when it bursts out at the pins)
			local sphere = Instance.new("Part")
			sphere.Name = "BowlSphere"
			sphere.Shape = Enum.PartType.Ball
			sphere.Size = Vector3.new(3.4, 3.4, 3.4)
			sphere.Transparency = 1
			sphere.CanQuery, sphere.CanTouch, sphere.CastShadow = false, false, false
			sphere.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.05, 0.1, 100, 1)
			sphere.CFrame = pe0.CFrame
			local w = Instance.new("WeldConstraint")
			w.Part0 = pe0
			w.Part1 = sphere
			w.Parent = sphere
			for _, part in ball:GetChildren() do
				if part:IsA("BasePart") then
					local nc = Instance.new("NoCollisionConstraint") -- (the body inside never pushes on its own ball)
					nc.Part0 = sphere
					nc.Part1 = part
					nc.Parent = sphere
				end
			end
			sphere.Parent = ball
			local conn: RBXScriptConnection? = nil
			conn = ball:GetAttributeChangedSignal("Curl"):Connect(function()
				if ball:GetAttribute("Curl") == nil then
					if conn then
						conn:Disconnect()
					end
					if sphere.Parent then
						sphere:Destroy()
					end
				end
			end)
			task.delay(9, function()
				if sphere.Parent then
					sphere:Destroy()
				end
			end)
		end
	end
	task.wait(0.15)
	local pelvis = ball:FindFirstChild("LowerTorso")
	if pelvis and pelvis:IsA("BasePart") then
		local mass = 0
		for _, p in ball:GetDescendants() do
			if p:IsA("BasePart") and not p.Massless then
				mass += p.Mass
			end
		end
		pcall(function()
			(require(script.Parent:WaitForChild("DummyControl")) :: any).hit(ball, pelvis, lane.dir * Bowling.ROLL_SPEED * math.max(mass, 1), pelvis.Position, Bowling.ROLL_SPEED + 10, by)
		end)
		for _, p in ball:GetDescendants() do
			if p:IsA("BasePart") then
				p.AssemblyAngularVelocity = lane.dir:Cross(Vector3.yAxis) * -9 -- (it rolls)
			end
		end
	end
	-- (F91 rest, Config.BOWL_OWNER: the bowler's own machine runs the pins during the roll, like the ball it already
	-- simulates, so ball and pins meet without a network lag; back to the server after the count)
	local owned: { BasePart } = {}
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_OWNER and by and by.Parent then
		for _, pin in lane.pins do
			for _, p in pin:GetDescendants() do
				if p:IsA("BasePart") and not p.Anchored then
					if pcall(function()
						p:SetNetworkOwner(by)
					end) then
						table.insert(owned, p)
					end
					break -- (one part sets the whole pin's assembly)
				end
			end
		end
		task.delay(Bowling.COUNT_AFTER + 0.5, function()
			for _, p in owned do
				pcall(function()
					if p.Parent and not p.Anchored then
						p:SetNetworkOwnershipAuto()
					end
				end)
			end
		end)
	end
	-- (T1 FTUE_10: a new player's FIRST roll is always a STRIKE: as the ball reaches the pins, every pin still up is
	-- knocked flying)
	local sure = by:GetAttribute("Tried_Bowling") ~= true and lane.roll == 1
		and (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).FTUE_10 == true
	by:SetAttribute("Tried_Bowling", true)
	-- F91 (Config.BOWL_BALL): it ALWAYS reaches the pins: a min-speed guard pushes it on while it is slower than 25 studs/s
	-- on the lane; the guaranteed first strike waits for the body to reach the pin deck (an impact, never a timer).
	local ballCfg = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_BALL == true
	local reached = Instance.new("BindableEvent")
	if ballCfg then
		task.spawn(function()
			local DC2 = require(script.Parent:WaitForChild("DummyControl")) :: any
			local t0 = os.clock()
			local deckAlong = (lane.deckAt - lane.at):Dot(lane.dir)
			while os.clock() - t0 < 7 do
				task.wait(0.1)
				local pe = ball:FindFirstChild("LowerTorso")
				if not (pe and pe:IsA("BasePart") and ball.Parent) then
					break
				end
				local along = (pe.Position - lane.at):Dot(lane.dir)
				if along >= deckAlong - 3 then
					-- (it bursts out of the curl into the pins, its speed kept and a little more)
					ball:SetAttribute("Curl", nil)
					pcall(DC2.push, ball, lane.dir * 10 + Vector3.new(0, 6, 0), nil)
					break
				end
				local speed = pe.AssemblyLinearVelocity:Dot(lane.dir)
				if speed < 25 then
					pcall(DC2.push, ball, lane.dir * (40 - math.max(speed, 0)), nil)
				end
			end
			ball:SetAttribute("Curl", nil)
			reached:Fire()
		end)
	else
		task.delay(1.5, function()
			reached:Fire()
		end)
	end
	if sure then
		reached.Event:Once(function()
			for i, pin in lane.pins do
				if standing(pin, lane.homes[i]) then
					local side = lane.dir:Cross(Vector3.yAxis) * (math.random() - 0.5) * 30
					for _, p in pin:GetChildren() do
						if p:IsA("BasePart") then
							p.AssemblyLinearVelocity = lane.dir * 26 + side + Vector3.new(0, 14, 0)
							p.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
						end
					end
				end
			end
		end)
	end
	task.wait(Bowling.COUNT_AFTER)
	ball:SetAttribute("Bowling", nil)
	local down = 0
	local goldDown = false
	for i, pin in lane.pins do
		if not standing(pin, lane.homes[i]) then
			down += 1
			if pin == lane.golden then
				goldDown = true
			end
		end
	end
	local word: string
	local frameDone = false
	local score = 0
	if lane.roll == 1 then
		if down >= 10 then
			word, frameDone, score = "STRIKE!", true, 30
		elseif down == 0 then
			word = "GUTTER..."
		else
			-- (a split: the front pin down, pins left standing on both sides)
			local left, right = false, false
			for i, pin in lane.pins do
				if standing(pin, lane.homes[i]) then
					local side = (lane.homes[i].Position - lane.deckAt):Dot(lane.dir:Cross(Vector3.yAxis))
					if side < -1 then
						left = true
					elseif side > 1 then
						right = true
					end
				end
			end
			word = if left and right and not standing(lane.pins[1], lane.homes[1]) then "SPLIT!" else string.format("%d PINS", down)
		end
		lane.first = down
		lane.roll = 2
	else
		local more = down - lane.first
		if down >= 10 then
			word, score = "SPARE!", 20
		elseif more <= 0 then
			word, score = "GUTTER...", down
		else
			word, score = string.format("+%d PINS", more), down
		end
		frameDone = true
	end
	-- (BOWLING_12 rest, Config.BOWL_TURKEY: strikes in a row: 2 is a DOUBLE, 3 (and on) a TURKEY with an extra
	-- confetti burst and a big shout; any frame that is not a strike starts the count again)
	local turkey = false
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_TURKEY and by then
		if string.sub(word, 1, 6) == "STRIKE" then
			strikesInRow[by.UserId] = (strikesInRow[by.UserId] or 0) + 1
			local n = strikesInRow[by.UserId]
			if n >= 3 then
				word ..= "  TURKEY!"
				turkey = true
			elseif n == 2 then
				word ..= "  DOUBLE!"
			end
		elseif frameDone then
			strikesInRow[by.UserId] = nil
		end
	end
	if goldDown then
		word ..= "  GOLDEN PIN!"
	end
	pcall(function()
		(require(script.Parent:WaitForChild("FxService")) :: any).hit(lane.deckAt + Vector3.new(0, 3, 0), if down >= 10 then 90 else 30, "Bowling")
	end)
	if frameDone then
		local mine = today[by.UserId]
		if not mine then
			mine = { name = by.DisplayName, best = 0 }
			today[by.UserId] = mine
		end
		if score > mine.best then
			mine.best = score
			if score > 0 then
				word ..= "  NEW BEST!"
			end
		end
		lane.roll = 1
	end
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWLING_FX then
		if string.sub(word, 1, 6) == "STRIKE" or string.sub(word, 1, 5) == "SPARE" then
			sound(Bowling.STRIKE_SOUND, lane.deckAt + Vector3.new(0, 3, 0), 1)
			confetti(lane.deckAt + Vector3.new(0, 4, 0))
			if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_CHEERS then
				cheer(lane, ball)
			end
		elseif string.sub(word, 1, 6) == "GUTTER" then
			sound(Bowling.GUTTER_SOUND, lane.at + Vector3.new(0, 3, 0), 0.8)
		end
	end
	if string.sub(word, 1, 6) == "STRIKE" and by and by.Parent then
		pcall(function() -- (AUDIT 14: the "Bowl a strike" daily goal)
			(require(script.Parent:WaitForChild("ProgressService")) :: any).goal(by, "Strike", 1)
		end)
		pcall(function() -- (FIXES_27NOV_LATE 4: the onboarding's FirstStrike)
			(require(script.Parent:WaitForChild("Funnels")) :: any).step(by, "FirstStrike")
		end)
	end
	if frameDone and by and by.Parent then
		pcall(function() -- (FIXES_27NOV_LATE 4: "BowlingScore", the frame's score in a bucket)
			(require(script.Parent:WaitForChild("Funnels")) :: any).event(by, "BowlingScore", if score >= 20 then "20-30" elseif score >= 10 then "10-19" else "0-9")
		end)
	end
	if turkey then
		confetti(lane.deckAt + Vector3.new(0, 7, 0))
		pcall(function()
			(require(script.Parent:WaitForChild("FxService")) :: any).hit(lane.deckAt + Vector3.new(0, 5, 0), 120, "Bowling")
		end)
		pcall(function()
			(require(script.Parent:WaitForChild("ProgressService")) :: any).notice(by, "\u{1F983} TURKEY! Three strikes in a row!")
		end)
	end
	-- (BOWLING_12 rewards, Config.BOWL_BOLTS: small BOLTS for a strike (5) or a spare (3), +15 for a turkey; at most
	-- 100 from bowling a visit, so the lane is a treat, not a farm)
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_BOLTS and by and by.Parent then
		local pay = if string.sub(word, 1, 6) == "STRIKE" then 5 elseif string.sub(word, 1, 5) == "SPARE" then 3 else 0
		if turkey then
			pay += 15
		end
		local got = boltsGot[by.UserId] or 0
		pay = math.min(pay, 100 - got)
		if pay > 0 then
			boltsGot[by.UserId] = got + pay
			pcall(function()
				(require(script.Parent:WaitForChild("EconomyService")) :: any).give(by, pay, nil)
			end)
			word ..= string.format("  +%d BOLTS", pay)
		end
	end
	showBoard(lane, by, word)
	if (lane :: any).bumpers and by then
		-- (the bumpers were up for this roll: they sink again; two gutters in a row raise them for the next one)
		setBumpers(lane, false)
		if string.sub(word, 1, 6) == "GUTTER" then
			guttersInRow[by.UserId] = (guttersInRow[by.UserId] or 0) + 1
		else
			guttersInRow[by.UserId] = nil
		end
		if (guttersInRow[by.UserId] or 0) >= 2 then
			guttersInRow[by.UserId] = nil
			task.delay(1.4, function()
				setBumpers(lane, true)
			end)
			pcall(function()
				(require(script.Parent:WaitForChild("ProgressService")) :: any).notice(by, "Bumpers up! Kid mode for your next roll.")
			end)
		end
	end
	if frameDone then
		task.wait(1.2) -- (the pin-setter)
		resetPins(lane)
	end
	lane.busy = false
end

-- Builds the lane in a lab (the Playground calls this after the lab stands; origin = the lab floor's middle).
function Bowling.build(into: Instance, origin: Vector3)
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.BOWLING then
		return
	end
	local okPlan, Plan = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
	end)
	local it = okPlan and Plan and Plan.ITEMS and Plan.ITEMS.RagdollBowling
	if not it then
		return
	end
	local L, W = it.size.X, it.size.Y
	local mid = origin + Vector3.new(it.at.X, 0, it.at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	-- lihfolk-ignore: findfirstchild-chain (only put in the filter list; a missing folder just filters nothing)
	params.FilterDescendantsInstances = { Workspace:FindFirstChild("Dummies") :: Instance }
	local hit = Workspace:Raycast(mid + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), params)
	local y = if hit then hit.Position.Y else origin.Y + 0.5
	local f = Instance.new("Model")
	f.Name = "RagdollBowling"
	f.Parent = into
	-- The lane runs along X: the pins at the west end (-X), the approach at the east end (+X), so it faces east.
	local dir = Vector3.new(-1, 0, 0)
	local laneW = math.min(8, W - 4)
	local bumperRails: { BasePart }? = nil
	local top = y + 0.6
	local function at(x: number, z: number, h: number): CFrame
		return CFrame.new(mid.X + x, top + h, mid.Z + z)
	end
	part(f, "Bed", Vector3.new(L, 0.6, W), at(0, 0, -0.3), DARK_WOOD, Enum.Material.Wood)
	local lane = part(f, "Lane", Vector3.new(L - 10, 0.2, laneW), at(-1, 0, 0.1), MAPLE, Enum.Material.SmoothPlastic)
	lane.Reflectance = 0.12
	for _, s in { -1, 1 } do
		part(f, "Edge", Vector3.new(L - 10, 0.3, 0.35), at(-1, s * (laneW / 2 + 0.17), 0.15), DARK_WOOD, Enum.Material.Wood)
		local g = part(f, "Gutter", Vector3.new(L - 10, 0.8, 1.3), at(-1, s * (laneW / 2 + 1), -0.15), CHROME, Enum.Material.Metal)
		g.Shape = Enum.PartType.Cylinder
		g.CFrame = at(-1, s * (laneW / 2 + 1), -0.35)
		g.Size = Vector3.new(L - 10, 1.3, 1.3)
		if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BOWL_BUMPERS then
			local home = at(-1, s * (laneW / 2 + 0.25), 1.2)
			local r = part(f, "Bumper", Vector3.new(L - 14, 2, 0.5), home * CFrame.new(0, -2.3, 0), Color3.fromRGB(255, 196, 64), Enum.Material.SmoothPlastic)
			r:SetAttribute("Home", home)
			r.CanCollide, r.CastShadow, r.Transparency = false, false, 1
			bumperRails = bumperRails or {}
			table.insert(bumperRails :: { BasePart }, r)
		end
	end
	for k = -3, 3 do -- the 7 aiming arrows
		local a = part(f, "Arrow", Vector3.new(1.2, 0.05, 0.35), at(L / 2 - 14 - math.abs(k) * 0.9, k * laneW / 8, 0.22), DARK_WOOD)
		a.CFrame = a.CFrame * CFrame.Angles(0, math.rad(45), 0)
		deco(a)
	end
	deco(part(f, "FoulLine", Vector3.new(0.25, 0.05, laneW), at(L / 2 - 6, 0, 0.22), PIN_RED, Enum.Material.Neon))
	part(f, "Approach", Vector3.new(6, 0.25, W - 2), at(L / 2 - 3, 0, 0.12), Color3.fromRGB(232, 196, 146), Enum.Material.Wood)
	-- The pit and kickbacks at the west end.
	part(f, "Pit", Vector3.new(3, 0.4, W), at(-L / 2 + 1.5, 0, -0.8), Color3.fromRGB(30, 30, 36), Enum.Material.Fabric)
	part(f, "Cushion", Vector3.new(1, 6, W), at(-L / 2 + 0.5, 0, 3), Color3.fromRGB(26, 26, 34), Enum.Material.Fabric)
	for _, s in { -1, 1 } do
		local kb = part(f, "Kickback", Vector3.new(12, 6, 0.6), at(-L / 2 + 7, s * (W / 2 - 0.3), 3), Color3.fromRGB(40, 44, 70), Enum.Material.SmoothPlastic)
		deco(part(f, "Stripe", Vector3.new(12, 0.6, 0.1), at(-L / 2 + 7, s * (W / 2 - 0.62), 4.4), Color3.fromRGB(255, 120, 40), Enum.Material.Neon))
		local _ = kb
	end
	-- The roof on slim posts, with 2 warm lights.
	for _, x in { -L / 2 + 2, L / 2 - 2 } do
		for _, s in { -1, 1 } do
			part(f, "Post", Vector3.new(0.6, 12, 0.6), at(x, s * (W / 2 - 0.3), 6), CHROME, Enum.Material.Metal)
		end
	end
	local roof = part(f, "Roof", Vector3.new(L + 1, 0.6, W + 1), at(0, 0, 12.3), Color3.fromRGB(150, 40, 50), Enum.Material.SmoothPlastic)
	for _, x in { -L / 4, L / 4 } do
		local a = Instance.new("Attachment")
		a.Position = Vector3.new(x, -1, 0)
		a.Parent = roof
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 214, 160)
		light.Range = 22
		light.Brightness = 1.6
		light.Shadows = false
		light.Parent = a
	end
	-- The scoreboard above the pins, facing the approach.
	local boardPart = part(f, "Scoreboard", Vector3.new(0.6, 6, 10), at(-L / 2 + 9, 0, 9), Color3.fromRGB(20, 20, 28), Enum.Material.SmoothPlastic)
	deco(boardPart)
	for k = 0, 15 do -- the bulbs round the edge
		local t = k / 16
		local zz = -5 + 10 * t
		for _, yy in { 3.1, -3.1 } do
			local b = part(f, "Bulb", Vector3.new(0.3, 0.3, 0.3), at(-L / 2 + 9.35, zz, 9 + yy), Color3.fromRGB(255, 220, 120), Enum.Material.Neon)
			b.Shape = Enum.PartType.Ball
			deco(b)
			b:SetAttribute("Idx", k)
			game:GetService("CollectionService"):AddTag(b, "Chase")
		end
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right -- (+X: toward the approach)
	gui.CanvasSize = Vector2.new(500, 300)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	gui.Parent = boardPart
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.2)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 196, 60)
	title.Text = "RAGDOLL BOWLING"
	title.Parent = gui
	local board = Instance.new("TextLabel")
	board.Size = UDim2.fromScale(0.94, 0.62)
	board.Position = UDim2.fromScale(0.03, 0.22)
	board.BackgroundTransparency = 1
	board.Font = Enum.Font.GothamBold
	board.TextScaled = true
	board.TextColor3 = Color3.fromRGB(235, 240, 255)
	board.TextXAlignment = Enum.TextXAlignment.Left
	board.Parent = gui
	local word = Instance.new("TextLabel")
	word.Size = UDim2.fromScale(1, 0.16)
	word.Position = UDim2.fromScale(0, 0.84)
	word.BackgroundTransparency = 1
	word.Font = Enum.Font.FredokaOne
	word.TextScaled = true
	word.TextColor3 = Color3.fromRGB(255, 90, 120)
	word.TextTransparency = 1
	word.Text = ""
	word.Parent = gui
	-- The 10 pins in their triangle at the west end (the head pin nearest the approach).
	local pinsFolder = Instance.new("Folder")
	pinsFolder.Name = "Pins"
	pinsFolder.Parent = f
	local deckX = -L / 2 + 9
	local homes: { CFrame } = {}
	local gap = 2.3
	for row = 0, 3 do
		for k = 0, row do
			local x = deckX - row * gap * 0.87
			local z = (k - row / 2) * gap
			table.insert(homes, at(x, z, 0.2))
		end
	end
	local pins: { Model } = {}
	for _, h in homes do
		table.insert(pins, makePin(pinsFolder, h))
	end
	-- The red lever on the approach.
	local leverBase = part(f, "LeverBase", Vector3.new(1.2, 1.2, 1.2), at(L / 2 - 2, W / 2 - 2, 0.6), Color3.fromRGB(40, 40, 46), Enum.Material.Metal)
	local stick = part(f, "Lever", Vector3.new(0.3, 3, 0.3), at(L / 2 - 2, W / 2 - 2, 2.4) * CFrame.Angles(0, 0, math.rad(-20)), PIN_RED, Enum.Material.SmoothPlastic)
	local knob = part(f, "Knob", Vector3.new(0.9, 0.9, 0.9), stick.CFrame * CFrame.new(0, 1.6, 0), PIN_RED, Enum.Material.SmoothPlastic)
	knob.Shape = Enum.PartType.Ball
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Bowl!"
	prompt.ObjectText = "Ragdoll Bowling"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = leverBase
	local laneState: Lane = {
		pins = pins,
		homes = homes,
		board = board,
		word = word,
		at = at(L / 2 - 4, 0, 0).Position,
		dir = dir,
		deckAt = at(deckX, 0, 0).Position,
		busy = false,
		lastRoll = -math.huge,
		roll = 1,
		first = 0,
		golden = nil,
	}
	;(laneState :: any).bumpers = bumperRails
	resetPins(laneState)
	showBoard(laneState, nil, nil)
	prompt.Triggered:Connect(function(player: Player)
		if not player:IsA("Player") then
			return
		end
		task.spawn(bowl, laneState, player)
	end)
	local _ = Players
end

return Bowling
