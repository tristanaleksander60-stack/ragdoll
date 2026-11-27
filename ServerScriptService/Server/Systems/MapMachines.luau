--!strict
-- MAP ROUND 3, the last two machines that only stood there (Config.MAP_MACHINES_LIVE; docs/NOW.md map DoD "every machine
-- works on its spot"):
--   * THE GYRO CAGE (OwnerMap GyroPad + GyroButton): a ragdoll thrown or dropped into the rings (within HUB_REACH of the
--     hub) is caught at the hub, tumbled for SPIN_TIME s, then flung out. The red button (a ProximityPrompt "Spin!") loads
--     the nearest free ragdoll within LOAD_REACH and spins it.
--   * THE SHREDDER (OwnerMap ShredderPit + ShredderButton): a ragdoll that falls into the pit disappears between the
--     rollers (MachineHidden: its skin hides) with a burst of purple cartoon confetti, then is spat out high over the
--     railing, whole (kid-friendly: no gore, nothing breaks). The button drops the nearest free ragdoll in.
-- Server-side; the machines are found in every built lab (scanned every few seconds, wired once).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MapMachines = {}

MapMachines.HUB_REACH = 13
MapMachines.SPIN_TIME = 4
MapMachines.LOAD_REACH = 60
MapMachines.SHRED_TIME = 1.5

local busy: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local wired: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function control(): any
	return require(script.Parent:WaitForChild("DummyControl"))
end

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

-- F92 (Config.MACHINE_SAFE): never the one you hold, one hit in the last 5 s, one within 8 studs of a player (the one
-- you walk to), one in a mood or another machine.
local SAFE = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).MACHINE_SAFE == true
local function safeToCall(m: Model, pe: BasePart): boolean
	local hitAt = m:GetAttribute("ServerHitAt")
	if m:GetAttribute("Mood") ~= nil or (type(hitAt) == "number" and Workspace:GetServerTimeNow() - hitAt < 5) then
		return false
	end
	for _, pl in Players:GetPlayers() do
		local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") and (r.Position - pe.Position).Magnitude < 8 then
			return false
		end
	end
	return true
end

local function nearestFree(at: Vector3, reach: number): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	local best, bestD = nil :: Model?, reach
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = m:IsA("Model") and pelvisOf(m)
		local st = m:GetAttribute("RagdollState")
		if pe and not busy[m] and m:GetAttribute("Held") ~= true and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("TryFor") == nil
			and m:GetAttribute("MachineHidden") == nil and m:GetAttribute("InMachine") == nil and (st == nil or st == "Standing" or st == "Walking") then
			local d = (pe.Position - at).Magnitude
			if d < bestD and (not SAFE or safeToCall(m, pe)) then
				best, bestD = m, d
			end
		end
	end
	return best
end

-- F92 (Config.MACHINE_SAFE): a machine CALLS its ragdoll: it RUNS to `spot` (Pace 2.4) and only gets in once there
-- (within 6 studs, at most 8 s); else nothing happens ("No ragdoll near!"). Never a teleport from somewhere else.
local function callIn(m: Model, spot: Vector3, name: string): boolean
	if not SAFE then
		return true
	end
	busy[m] = true
	m:SetAttribute("Home", spot)
	m:SetAttribute("Pace", 2.4)
	local t0 = os.clock()
	local there = false
	while os.clock() - t0 < 8 do
		local pe = pelvisOf(m)
		if not (pe and m.Parent) or m:GetAttribute("Held") == true then
			break
		end
		if (Vector3.new(pe.Position.X, 0, pe.Position.Z) - Vector3.new(spot.X, 0, spot.Z)).Magnitude < 6 then
			there = true
			break
		end
		task.wait(0.2)
	end
	m:SetAttribute("Pace", nil)
	busy[m] = nil
	if there then
		pcall(function()
			(require(script.Parent:WaitForChild("RagdollDirector")) :: any).logRemoval(m, name, "called; ran there and hopped in")
		end)
	else
		pcall(function()
			require(script.Parent:WaitForChild("Playground")).pop(spot + Vector3.new(0, 5, 0), "No ragdoll near!", Color3.fromRGB(255, 200, 120))
		end)
	end
	return there
end

local function prompt(button: BasePart, text: string, onUse: (Player) -> ())
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = text
	pp.ObjectText = ""
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = button
	local last = 0
	pp.Triggered:Connect(function(player)
		if os.clock() - last < 3 then
			return -- (one at a time)
		end
		last = os.clock()
		onUse(player)
	end)
end

-- THE GYRO CAGE
-- 3.3 (docs/MACHINES_10.md "GYRO CAGE"; Config.GYRO_10): leather straps snap round the wrists and ankles at the hub; the
-- spin ramps up to `power` (HOLD the red button: the longer, the faster, the prompt's ring is the dial; a ragdoll that
-- falls in spins at half power); a motor whir rises with the speed; the straps pop at the top and the body is flung out
-- along the spin; the top RPM and the G-force pop ("128 RPM  9.4 G!") with a NEW BEST for whoever started it (GyroBest);
-- 1 in 20 is GOLDEN: a rainbow trail and +5 KOs.
local function strap(m: Model): { Instance }
	local made = {}
	for _, name in { "LeftHand", "RightHand", "LeftFoot", "RightFoot" } do
		local limb = m:FindFirstChild(name)
		if limb and limb:IsA("BasePart") then
			local band = Instance.new("Part")
			band.Name = "GyroStrap"
			band.Shape = Enum.PartType.Cylinder
			band.Size = Vector3.new(0.35, 1.05, 1.05)
			band.Color = Color3.fromRGB(110, 70, 40)
			band.Material = Enum.Material.Leather
			band.Massless, band.CanCollide, band.CanQuery, band.CanTouch = true, false, false, false
			band.CFrame = limb.CFrame * CFrame.new(0, if string.find(name, "Foot") then 0.1 else 0.25, 0) * CFrame.Angles(0, 0, math.rad(90))
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = limb, band
			w.Parent = band
			band.Parent = m
			table.insert(made, band)
		end
	end
	return made
end

local function spin(m: Model, hub: Vector3, by: Player?, power: number?)
	if busy[m] then
		return
	end
	busy[m] = true
	local live = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).GYRO_10 == true
	local pow = math.clamp(power or 0.5, 0.25, 1)
	m:SetAttribute("InMachine", "Gyro")
	local DC = control()
	local straps = if live then strap(m) else {}
	local whir: Sound? = nil
	if live then
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://9118773057" -- (PSE "San Francisco Bart Train 2": a motor whine and hum)
		s.Looped = true
		s.Volume = 0.5
		s.PlaybackSpeed = 0.5
		s.RollOffMaxDistance = 90
		local pe = pelvisOf(m)
		s.Parent = pe or Workspace
		s:Play()
		whir = s
		m:SetAttribute("MoodSay", if pow > 0.8 then "TOO FAST!" else "Whoaaa!")
	end
	local wMax = 6 + 10 * pow -- rad/s at the top
	local t0 = os.clock()
	local ax, ay, az = 0, 0, 0
	local top = 0
	local last = t0
	while m.Parent and os.clock() - t0 < MapMachines.SPIN_TIME and m:GetAttribute("Held") ~= true do
		local now = os.clock()
		local dt = now - last
		last = now
		local w = if live then wMax * math.min(1, (now - t0) / (MapMachines.SPIN_TIME * 0.75)) else 7
		top = math.max(top, w)
		ax += w * dt
		ay += w * 0.72 * dt
		az += w * 0.43 * dt
		pcall(DC.move, m, CFrame.new(hub) * CFrame.Angles(ax, ay, az))
		if whir then
			whir.PlaybackSpeed = 0.5 + w / 16 * 1.3
		end
		task.wait(if live then 0.05 else 0.1)
	end
	task.wait(0.05)
	m:SetAttribute("InMachine", nil)
	m:SetAttribute("MoodSay", nil)
	for _, b in straps do
		b:Destroy()
	end
	if whir then
		whir:Stop()
		whir:Destroy()
	end
	if m.Parent and m:GetAttribute("Held") ~= true then
		-- flung out along the spin: the tangent of the turn about Y at the release
		local dir = if live then Vector3.new(math.cos(ay), 0, -math.sin(ay)) else (function()
			local a = math.random() * math.pi * 2
			return Vector3.new(math.cos(a), 0, math.sin(a))
		end)()
		local out = if live then 90 + 90 * pow else 130
		pcall(DC.push, m, dir * out + Vector3.new(0, if live then 60 + 50 * pow else 90, 0), by)
		pcall(function()
			require(script.Parent:WaitForChild("FxService")).hit(hub, 50, "CannonPad")
		end)
		if live then
			local rpm = math.floor(top * 60 / (2 * math.pi) + 0.5)
			local g = math.floor(top * top * 0.7 / 9.81 * 10 + 0.5) / 10 -- (limbs about 0.7 m from the hub)
			local golden = math.random(20) == 1
			local text = tostring(rpm) .. " RPM  " .. string.format("%.1f", g) .. " G!"
			if by then
				local best = (by:GetAttribute("GyroBest") :: number?) or 0
				if g > best then
					by:SetAttribute("GyroBest", g)
					text ..= " NEW BEST!"
				end
			end
			if golden then
				text = "GOLDEN SPIN! " .. text
				local pe = pelvisOf(m)
				if pe then
					local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
					a0.Position, a1.Position = Vector3.new(0, 0.6, 0), Vector3.new(0, -0.6, 0)
					a0.Parent, a1.Parent = pe, pe
					local tr = Instance.new("Trail")
					tr.Attachment0, tr.Attachment1 = a0, a1
					tr.Lifetime = 0.8
					tr.LightEmission = 0.6
					tr.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
						ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 40)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 230, 90)),
						ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 140, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255)),
					})
					tr.Parent = pe
					task.delay(3, function()
						tr:Destroy()
						a0:Destroy()
						a1:Destroy()
					end)
				end
				if by then
					pcall(function()
						require(script.Parent:WaitForChild("ProgressService")).addTakedowns(by, 5)
					end)
				end
			end
			pcall(function()
				require(script.Parent:WaitForChild("Playground")).pop(hub + Vector3.new(0, 6, 0), text, if golden then Color3.fromRGB(255, 220, 80) else Color3.fromRGB(150, 220, 255))
			end)
		end
	end
	task.delay(1, function()
		busy[m] = nil
	end)
end

local function wireGyro(pad: BasePart)
	local hub = pad.Position + Vector3.new(0, 19.7, 0)
	local button = pad.Parent and pad.Parent:FindFirstChild("GyroButton")
	local live = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).GYRO_10 == true
	if button and button:IsA("BasePart") and (button.Position - pad.Position).Magnitude < 40 then
		local function go(player: Player, power: number)
			local m = nearestFree(button.Position, if SAFE then 40 else MapMachines.LOAD_REACH)
			if m then
				task.spawn(function()
					if callIn(m, Vector3.new(pad.Position.X, pad.Position.Y, pad.Position.Z), "Gyro") then
						local DC = control()
						pcall(DC.move, m, CFrame.new(hub))
						spin(m, hub, player, power)
					end
				end)
			end
		end
		if live then
			-- HOLD to spin faster: the prompt's fill ring is the dial; let go early for a slower spin
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = "HOLD to spin!"
			pp.ObjectText = "Gyro Cage"
			pp.HoldDuration = 2.5
			pp.MaxActivationDistance = 12
			pp.RequiresLineOfSight = false
			pp.Parent = button
			local holding: { [Player]: number } = {}
			local last = 0
			local function fire(player: Player, power: number)
				if os.clock() - last < 3 then
					return
				end
				last = os.clock()
				go(player, power)
			end
			pp.PromptButtonHoldBegan:Connect(function(player)
				holding[player] = os.clock()
			end)
			pp.PromptButtonHoldEnded:Connect(function(player)
				local t = holding[player]
				holding[player] = nil
				if t and os.clock() - t > 0.25 then
					fire(player, (os.clock() - t) / pp.HoldDuration)
				end
			end)
			pp.Triggered:Connect(function(player)
				holding[player] = nil
				fire(player, 1)
			end)
		else
			prompt(button, "Spin!", function(player)
				go(player, 0.5)
			end)
		end
	end
	task.spawn(function()
		while pad.Parent do
			task.wait(0.3)
			local dummies = Workspace:FindFirstChild("Dummies")
			for _, m in if dummies then dummies:GetChildren() else {} do
				local pe = m:IsA("Model") and pelvisOf(m)
				if pe and not busy[m] and m:GetAttribute("Held") ~= true and m:GetAttribute("Vital") ~= "Dead" and (pe.Position - hub).Magnitude < MapMachines.HUB_REACH then
					task.spawn(spin, m, hub, nil)
				end
			end
		end
	end)
end

-- THE SHREDDER
local function confetti(at: Vector3)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = at
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Speed = NumberRange.new(18, 30)
	e.Lifetime = NumberRange.new(1.2, 2)
	e.SpreadAngle = Vector2.new(50, 50)
	e.Acceleration = Vector3.new(0, -25, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.Size = NumberSequence.new(0.5, 0.3)
	e.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 60, 230)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 220)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 80, 255)),
	})
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
	p.Parent = Workspace
	e:Emit(80)
	task.delay(3, function()
		p:Destroy()
	end)
end

local function shred(m: Model, pit: BasePart, by: Player?)
	if busy[m] then
		return
	end
	busy[m] = true
	m:SetAttribute("InMachine", "Shredder")
	m:SetAttribute("MachineHidden", true)
	local DC = control()
	pcall(DC.move, m, CFrame.new(pit.Position - Vector3.new(0, 6, 0)))
	confetti(pit.Position + Vector3.new(0, 1, 0))
	pcall(function()
		require(script.Parent:WaitForChild("FxService")).hit(pit.Position, 40, "CannonPad")
	end)
	task.wait(MapMachines.SHRED_TIME)
	if m.Parent then
		m:SetAttribute("MachineHidden", nil)
		m:SetAttribute("InMachine", nil)
		-- spat out over the long side's railing, whole
		local side = if math.random() < 0.5 then -1 else 1
		pcall(DC.move, m, CFrame.new(pit.Position + Vector3.new(0, 4, 0)))
		task.wait(0.1) -- (the move lands first, then the throw: as MachineDemos)
		pcall(DC.push, m, Vector3.new(math.random(-20, 20), 150, side * 60), by)
		confetti(pit.Position + Vector3.new(0, 3, 0))
		if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SHRED_10 then
			-- 3.21 (docs/MACHINES_10.md "SHREDDER PIT"; Config.SHRED_10): the folds it came out with, a NEW BEST for whoever
			-- pressed (ShredBest)
			local folds = math.random(1, 6)
			local text = "FOLDED x" .. tostring(folds) .. "!"
			if by then
				local best = (by:GetAttribute("ShredBest") :: number?) or 0
				if folds > best then
					by:SetAttribute("ShredBest", folds)
					text ..= " NEW BEST!"
				end
			end
			pcall(function()
				require(script.Parent:WaitForChild("Playground")).pop(pit.Position + Vector3.new(0, 6, 0), text, Color3.fromRGB(240, 240, 255))
			end)
		end
	end
	task.delay(2, function()
		busy[m] = nil
	end)
end

local function wireShredder(pit: BasePart)
	local button = pit.Parent and pit.Parent:FindFirstChild("ShredderButton")
	if button and button:IsA("BasePart") and (button.Position - pit.Position).Magnitude < 60 then
		prompt(button, "Shred!", function(player)
			local m = nearestFree(button.Position, if SAFE then 40 else MapMachines.LOAD_REACH)
			if m then
				task.spawn(function()
					if callIn(m, pit.Position, "Shredder") then
						shred(m, pit, player)
					end
				end)
			end
		end)
	end
	task.spawn(function()
		while pit.Parent do
			task.wait(0.3)
			local dummies = Workspace:FindFirstChild("Dummies")
			local half = pit.Size / 2
			for _, m in if dummies then dummies:GetChildren() else {} do
				local pe = m:IsA("Model") and pelvisOf(m)
				if pe and not busy[m] and m:GetAttribute("Held") ~= true then
					local l = pit.CFrame:PointToObjectSpace(pe.Position)
					if math.abs(l.X) < half.X and math.abs(l.Z) < half.Z and l.Y < -1 and l.Y > -10 then
						task.spawn(shred, m, pit, nil)
					end
				end
			end
		end
	end)
end

-- 3.20 TESLA COIL (docs/MACHINES_10.md; Config.TESLA_10): a ZAP button on its base. A 1 s charge (a rising electric
-- growl, the sparks crawl faster), then a jagged lightning arc to the nearest free ragdoll within ZAP_REACH: it flashes
-- blue-white (the cartoon X-ray moment), goes soot-black for 3 s with a smoke puff and jumps; the arc chains on to up to
-- 2 more ragdolls within CHAIN_REACH of the last one. "ZAP! x3 CHAIN".
MapMachines.ZAP_REACH = 28
MapMachines.CHAIN_REACH = 16

local function arc(a: Vector3, b: Vector3)
	local pts = { a }
	local n = 7
	for i = 1, n - 1 do
		local p = a:Lerp(b, i / n)
		table.insert(pts, p + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2.4)
	end
	table.insert(pts, b)
	local made = {}
	for i = 1, #pts - 1 do
		local p0, p1 = pts[i], pts[i + 1]
		local seg = Instance.new("Part")
		seg.Name = "ZapArc"
		seg.Material = Enum.Material.Neon
		seg.Color = Color3.fromRGB(170, 220, 255)
		seg.Anchored, seg.CanCollide, seg.CanQuery, seg.CanTouch, seg.CastShadow = true, false, false, false, false
		seg.Size = Vector3.new(0.25, 0.25, (p1 - p0).Magnitude)
		seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		seg.Parent = Workspace
		table.insert(made, seg)
	end
	task.delay(0.3, function()
		for _, seg in made do
			seg:Destroy()
		end
	end)
end

local function zapBody(m: Model, by: Player?)
	local glow = Instance.new("Highlight")
	glow.Name = "ZapGlow"
	glow.FillColor = Color3.fromRGB(170, 225, 255)
	glow.OutlineColor = Color3.fromRGB(255, 255, 255)
	glow.FillTransparency = 0.05
	glow.Parent = m
	task.delay(0.3, function()
		glow.FillColor = Color3.fromRGB(30, 30, 34) -- (soot-black)
		glow.OutlineColor = Color3.fromRGB(60, 60, 64)
		glow.FillTransparency = 0.25
	end)
	task.delay(3, function()
		glow:Destroy()
	end)
	local pe = pelvisOf(m)
	if pe then
		local puff = Instance.new("ParticleEmitter")
		puff.Texture = "rbxasset://textures/particles/smoke_main.dds"
		puff.Color = ColorSequence.new(Color3.fromRGB(60, 60, 64))
		puff.Size = NumberSequence.new(1, 3)
		puff.Transparency = NumberSequence.new(0.3, 1)
		puff.Speed = NumberRange.new(3, 6)
		puff.Lifetime = NumberRange.new(0.8, 1.4)
		puff.Rate = 0
		puff.Parent = pe
		puff:Emit(16)
		game:GetService("Debris"):AddItem(puff, 2)
	end
	pcall(control().push, m, Vector3.new(math.random(-10, 10), 70, math.random(-10, 10)), by)
end

local function wireTesla(base: BasePart, top: BasePart)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "ZAP!"
	pp.ObjectText = "Tesla Coil"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Parent = base
	local hum = Instance.new("Sound")
	hum.SoundId = "rbxassetid://9114524003" -- (PSE "Force Field Constant Sci Fi 2": a growling electric charge)
	hum.Volume = 0.5
	hum.RollOffMaxDistance = 90
	hum.Parent = top
	local zap = Instance.new("Sound")
	zap.SoundId = "rbxassetid://9114277757" -- (PSE "Electric Zaps 12")
	zap.Volume = 1
	zap.RollOffMaxDistance = 120
	zap.Parent = top
	local sparks = top:FindFirstChildWhichIsA("ParticleEmitter")
	local charging = false
	pp.Triggered:Connect(function(player)
		if charging then
			return
		end
		charging = true
		pp.Enabled = false
		task.spawn(function()
			hum.PlaybackSpeed = 0.6
			hum:Play()
			local t0 = os.clock()
			while os.clock() - t0 < 1 do
				local k = os.clock() - t0
				hum.PlaybackSpeed = 0.6 + k * 1.2
				if sparks then
					sparks.Rate = 12 + 90 * k
				end
				task.wait(0.05)
			end
			hum:Stop()
			if sparks then
				sparks.Rate = 12
			end
			zap:Play()
			local from = top.Position
			local hits = 0
			for _ = 1, 3 do
				local m = nearestFree(if hits == 0 then base.Position else from, if hits == 0 then MapMachines.ZAP_REACH else MapMachines.CHAIN_REACH)
				if not m then
					break
				end
				busy[m] = true
				local pe = pelvisOf(m)
				local to = if pe then pe.Position else from
				arc(from, to)
				zapBody(m, player)
				hits += 1
				from = to
				task.delay(1, function()
					busy[m] = nil
				end)
				task.wait(0.12)
			end
			if hits > 0 then
				pcall(function()
					require(script.Parent:WaitForChild("Playground")).pop(top.Position + Vector3.new(0, 4, 0), if hits > 1 then "ZAP! x" .. hits .. " CHAIN" else "ZAP!", Color3.fromRGB(170, 225, 255))
				end)
			end
			task.wait(3)
			charging = false
			pp.Enabled = true
		end)
	end)
end

-- 3.22 SWEEPER (docs/MACHINES_10.md; Config.SWEEP_10): a button on its centre post steps the beam's speed SLOW > FAST >
-- CRAZY; a ragdoll standing on the pad that the beam passes is swept off over the edge; a player on the pad who is in the
-- air as the beam passes under them scores a jump ("JUMPED x5!", NEW BEST: SweepBest); one it catches on the ground is
-- knocked off and the streak starts again.
MapMachines.SWEEP_SPEEDS = { 0.5, 1.1, 1.9 }
local function wireSweeper(pad: BasePart, beam: BasePart, post: BasePart?)
	local level = 1
	beam:SetAttribute("SweepSpeed", MapMachines.SWEEP_SPEEDS[1])
	if post then
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Speed: FAST"
		pp.ObjectText = "Sweeper: SLOW"
		pp.HoldDuration = 0
		pp.MaxActivationDistance = 12
		pp.RequiresLineOfSight = false
		pp.Parent = post
		local names = { "SLOW", "FAST", "CRAZY" }
		pp.Triggered:Connect(function()
			level = level % 3 + 1
			beam:SetAttribute("SweepSpeed", MapMachines.SWEEP_SPEEDS[level])
			pp.ObjectText = "Sweeper: " .. names[level]
			pp.ActionText = "Speed: " .. names[level % 3 + 1]
		end)
	end
	local centre = pad.Position
	local radius = math.max(pad.Size.Y, pad.Size.Z) / 2
	local swept: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
	local streak: { [Player]: number } = {}
	local lastSide: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
	task.spawn(function()
		while pad.Parent and beam.Parent do
			task.wait(0.08)
			local ang = (beam:GetAttribute("SweepAngle") :: number?) or 0
			local speed = (beam:GetAttribute("SweepSpeed") :: number?) or 0.5
			local dir = beam.CFrame.RightVector -- (the beam's long axis)
			local function side(p: Vector3): (number, number)
				local rel = Vector3.new(p.X - centre.X, 0, p.Z - centre.Z)
				return dir:Cross(rel).Y, rel.Magnitude -- (which side of the beam line, distance from the post)
			end
			local _ = ang
			-- ragdolls
			local dummies = Workspace:FindFirstChild("Dummies")
			for _, m in if dummies then dummies:GetChildren() else {} do
				local pe = m:IsA("Model") and pelvisOf(m)
				if pe and math.abs(pe.Position.Y - centre.Y) < 6 then
					local s0, r = side(pe.Position)
					if r < radius and r > 3 then
						local before = lastSide[m]
						lastSide[m] = s0
						if before and (before > 0) ~= (s0 > 0) and os.clock() - (swept[m] or 0) > 1.5 and m:GetAttribute("Held") ~= true then
							swept[m] = os.clock()
							local out = Vector3.new(pe.Position.X - centre.X, 0, pe.Position.Z - centre.Z).Unit
							local tangent = Vector3.new(0, 1, 0):Cross(out) * (if speed > 0 then 1 else -1)
							pcall(control().push, m, tangent * (40 + 40 * speed) + out * 50 + Vector3.new(0, 35, 0))
						end
					else
						lastSide[m] = nil
					end
				end
			end
			-- players: a jump over it counts, a catch on the ground knocks them off
			for _, pl in Players:GetPlayers() do
				local root = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local s0, r = side(root.Position)
					local onPad = r < radius and r > 3 and root.Position.Y - centre.Y < 12
					local before = lastSide[pl]
					lastSide[pl] = if onPad then s0 else nil
					if onPad and before and (before > 0) ~= (s0 > 0) then
						local airborne = root.Position.Y - centre.Y > 5.2
						if airborne then
							streak[pl] = (streak[pl] or 0) + 1
							local n = streak[pl]
							local text = "JUMPED x" .. tostring(n) .. "!"
							local best = (pl:GetAttribute("SweepBest") :: number?) or 0
							if n > best then
								pl:SetAttribute("SweepBest", n)
								if n > 1 then
									text ..= " NEW BEST!"
								end
							end
							pcall(function()
								require(script.Parent:WaitForChild("Playground")).pop(root.Position + Vector3.new(0, 4, 0), text, Color3.fromRGB(255, 200, 80))
							end)
						else
							streak[pl] = 0
							local out = Vector3.new(root.Position.X - centre.X, 0, root.Position.Z - centre.Z).Unit
							pcall(function()
								require(script.Parent:WaitForChild("PlayerRagdoll")).launch(pl, out * 70 + Vector3.new(0, 40, 0))
							end)
						end
					end
				end
			end
		end
	end)
end

-- 3.23 LAVA STRIP (docs/MACHINES_10.md; Config.LAVA_10): the strip glows and bubbles; a ragdoll in it does a hot-foot
-- dance (quick hops), goes soot-black and smoking, and after HOT_TIME s jumps out over the nearer kerb: "HOT FOOT! 1.6 s"
-- (the time it danced) with a NEW BEST for the lab's owner (LavaBest). Cartoon only.
MapMachines.HOT_TIME = 1.6
local function wireLava(lava: BasePart)
	local bub = Instance.new("ParticleEmitter")
	bub.Name = "LavaBubbles"
	bub.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bub.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 80, 20))
	bub.LightEmission = 0.8
	bub.Size = NumberSequence.new(0.6, 0.1)
	bub.Speed = NumberRange.new(2, 6)
	bub.Lifetime = NumberRange.new(0.5, 1)
	bub.Rate = 18
	bub.EmissionDirection = Enum.NormalId.Top
	bub.Parent = lava
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 120, 40)
	glow.Range = 18
	glow.Brightness = 1.5
	glow.Parent = lava
	local inSince: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
	local hopAt: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
	task.spawn(function()
		while lava.Parent do
			task.wait(0.15)
			local dummies = Workspace:FindFirstChild("Dummies")
			local now = os.clock()
			for _, m in if dummies then dummies:GetChildren() else {} do
				local pe = m:IsA("Model") and pelvisOf(m)
				if pe and not busy[m] and m:GetAttribute("Held") ~= true then
					local rel = lava.CFrame:PointToObjectSpace(pe.Position)
					local inside = math.abs(rel.X) < lava.Size.X / 2 + 0.5 and math.abs(rel.Z) < lava.Size.Z / 2 + 0.5 and rel.Y < 5 and rel.Y > -2
					if inside then
						if not inSince[m] then
							inSince[m] = now
							local sootGlow = Instance.new("Highlight")
							sootGlow.Name = "LavaSoot"
							sootGlow.FillColor = Color3.fromRGB(35, 30, 30)
							sootGlow.OutlineColor = Color3.fromRGB(255, 120, 40)
							sootGlow.FillTransparency = 0.35
							sootGlow.Parent = m
							task.delay(5, function()
								sootGlow:Destroy()
							end)
							local smoke = Instance.new("ParticleEmitter")
							smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
							smoke.Color = ColorSequence.new(Color3.fromRGB(70, 70, 72))
							smoke.Size = NumberSequence.new(0.8, 2.4)
							smoke.Transparency = NumberSequence.new(0.3, 1)
							smoke.Speed = NumberRange.new(2, 4)
							smoke.Lifetime = NumberRange.new(0.8, 1.4)
							smoke.Rate = 10
							smoke.Parent = pe
							task.delay(5, function()
								smoke:Destroy()
							end)
							m:SetAttribute("MoodSay", "HOT HOT HOT!")
							task.delay(2.5, function()
								if m:GetAttribute("MoodSay") == "HOT HOT HOT!" then
									m:SetAttribute("MoodSay", nil)
								end
							end)
						end
						if now - (hopAt[m] or 0) > 0.35 then
							hopAt[m] = now
							pcall(control().nudge, m, Vector3.new(math.random(-6, 6), 34, math.random(-6, 6)))
						end
						if now - inSince[m] >= MapMachines.HOT_TIME then
							local danced = math.floor((now - inSince[m]) * 10 + 0.5) / 10
							inSince[m] = nil
							busy[m] = true
							task.delay(1.5, function()
								busy[m] = nil
							end)
							local out = lava.CFrame.RightVector * (if rel.X >= 0 then 1 else -1)
							pcall(control().push, m, out * 55 + Vector3.new(0, 60, 0))
							local text = "HOT FOOT! " .. string.format("%.1f", danced) .. " s"
							local okO, owner = pcall(function()
								return require(script.Parent:WaitForChild("Lab")).ownerAt(pe.Position)
							end)
							if okO and owner then
								local best = (owner:GetAttribute("LavaBest") :: number?) or 0
								if danced > best then
									owner:SetAttribute("LavaBest", danced)
									text ..= " NEW BEST!"
								end
							end
							pcall(function()
								require(script.Parent:WaitForChild("Playground")).pop(pe.Position + Vector3.new(0, 4, 0), text, Color3.fromRGB(255, 150, 60))
							end)
						end
					else
						inSince[m] = nil
					end
				end
			end
		end
	end)
end

-- 3.33 SEESAW (docs/MACHINES_10.md "Seesaw"; Config.SEESAW_10): "SIT A RAGDOLL" seats the nearest free one on the low
-- end. Anything heavy coming down on the HIGH end (you jumping on it, a falling ragdoll, a thrown crate) flips the plank:
-- the low end kicks up and the ragdoll sitting there is launched: "SEESAW! 38 studs" (the height) with a NEW BEST for
-- whoever jumped (SeesawBest). The plank stays tipped the other way, ready for the next one.
MapMachines.SEESAW_TILT = 9
local function wireSeesaw(plank: BasePart)
	local pivot = plank.CFrame * CFrame.Angles(0, 0, -math.rad(MapMachines.SEESAW_TILT)) -- (level)
	local half = plank.Size.X / 2
	local sign = 1 -- (+1: the +X end is high)
	local lastFlip = 0
	local function tipped(sg: number): CFrame
		return pivot * CFrame.Angles(0, 0, math.rad(MapMachines.SEESAW_TILT) * sg)
	end
	plank.CFrame = tipped(sign)
	local function lowEnd(): Vector3
		return (pivot * CFrame.new(-sign * (half - 1.2), 0, 0)).Position
	end
	local function flip(by: Player?)
		local now = os.clock()
		if now - lastFlip < 1 then
			return
		end
		lastFlip = now
		local low = lowEnd()
		sign = -sign
		game:GetService("TweenService"):Create(plank, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = tipped(sign) }):Play()
		local dummies = Workspace:FindFirstChild("Dummies")
		for _, m in if dummies then dummies:GetChildren() else {} do
			local pe = m:IsA("Model") and pelvisOf(m)
			if pe and (pe.Position - low).Magnitude < 4.5 then
				local out = (pivot.RightVector * -(-sign)) -- (away from the pivot, over the end that kicked up)
				local y0 = pe.Position.Y
				pcall(control().push, m, out * 18 + Vector3.new(0, 95, 0), by)
				task.spawn(function()
					local peak = y0
					local t0 = os.clock()
					while os.clock() - t0 < 2.5 and pe.Parent do
						peak = math.max(peak, pe.Position.Y)
						task.wait(0.05)
					end
					local h = math.floor(peak - y0 + 0.5)
					local text = "SEESAW! " .. h .. " studs"
					if by then
						local best = (by:GetAttribute("SeesawBest") :: number?) or 0
						if h > best then
							by:SetAttribute("SeesawBest", h)
							text ..= " NEW BEST!"
						end
					end
					pcall(function()
						require(script.Parent:WaitForChild("Playground")).pop(low + Vector3.new(0, 6, 0), text, Color3.fromRGB(255, 220, 80))
					end)
				end)
			end
		end
	end
	plank.Touched:Connect(function(other: BasePart)
		-- (only a hit on the HIGH end, coming down hard)
		local rel = pivot:PointToObjectSpace(other.Position)
		if rel.X * sign < half * 0.35 then
			return
		end
		local vy = other.AssemblyLinearVelocity.Y
		local char = other:FindFirstAncestorOfClass("Model")
		local player = char and Players:GetPlayerFromCharacter(char)
		if (player and vy < -6) or (not player and vy < -15) then
			flip(player)
		end
	end)
	prompt(plank, "Sit a ragdoll", function(player)
		local m = nearestFree(plank.Position, if SAFE then 40 else 70)
		if m and callIn(m, lowEnd(), "Seesaw") then
			local seat = lowEnd() + Vector3.new(0, 3, 0)
			pcall(control().move, m, CFrame.lookAt(seat, seat + pivot.RightVector * sign))
			pcall(function()
				require(script.Parent:WaitForChild("Playground")).pop(seat + Vector3.new(0, 4, 0), "JUMP ON THE OTHER END!", Color3.fromRGB(255, 255, 255))
			end)
		end
	end)
end

function MapMachines.start()
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.MAP_MACHINES_LIVE or not Config.LAB_OWNERMAP then
		return
	end
	task.spawn(function()
		while true do
			local root = Workspace:FindFirstChild("Playground")
			for _, lab in if root then root:GetChildren() else {} do
				local om = lab:FindFirstChild("OwnerMap")
				if om then
					local pad = om:FindFirstChild("GyroPad")
					if pad and pad:IsA("BasePart") and not wired[pad] then
						wired[pad] = true
						wireGyro(pad)
					end
					local pit = om:FindFirstChild("ShredderPit")
					if pit and pit:IsA("BasePart") and not wired[pit] then
						wired[pit] = true
						wireShredder(pit)
					end
					local lavaStrip = om:FindFirstChild("LavaStrip")
					if Config.LAVA_10 and lavaStrip and lavaStrip:IsA("BasePart") and not wired[lavaStrip] then
						wired[lavaStrip] = true
						wireLava(lavaStrip)
					end
					local sPad, sBeam = om:FindFirstChild("SweeperPad"), om:FindFirstChild("SweeperBeam")
					if Config.SWEEP_10 and sPad and sBeam and sPad:IsA("BasePart") and sBeam:IsA("BasePart") and not wired[sPad] then
						wired[sPad] = true
						local post = om:FindFirstChild("SweeperPost")
						wireSweeper(sPad, sBeam, if post and post:IsA("BasePart") then post else nil)
					end
					local plank = om:FindFirstChild("SeesawPlank")
					if Config.SEESAW_10 and plank and plank:IsA("BasePart") and not wired[plank] then
						wired[plank] = true
						wireSeesaw(plank)
					end
					local tBase, tTop = om:FindFirstChild("TeslaBase"), om:FindFirstChild("TeslaTop")
					if Config.TESLA_10 and tBase and tTop and tBase:IsA("BasePart") and tTop:IsA("BasePart") and not wired[tBase] then
						wired[tBase] = true
						wireTesla(tBase, tTop)
					end
				end
			end
			task.wait(5)
		end
	end)
	local _ = Players
end

return MapMachines
