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

local function nearestFree(at: Vector3, reach: number): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	local best, bestD = nil :: Model?, reach
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = m:IsA("Model") and pelvisOf(m)
		local st = m:GetAttribute("RagdollState")
		if pe and not busy[m] and m:GetAttribute("Held") ~= true and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("TryFor") == nil
			and m:GetAttribute("MachineHidden") == nil and m:GetAttribute("InMachine") == nil and (st == nil or st == "Standing" or st == "Walking") then
			local d = (pe.Position - at).Magnitude
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
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
		s.SoundId = "rbxassetid://9113480917"
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
			local m = nearestFree(button.Position, MapMachines.LOAD_REACH)
			if m then
				local DC = control()
				pcall(DC.move, m, CFrame.new(hub))
				task.spawn(spin, m, hub, player, power)
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
	end
	task.delay(2, function()
		busy[m] = nil
	end)
end

local function wireShredder(pit: BasePart)
	local button = pit.Parent and pit.Parent:FindFirstChild("ShredderButton")
	if button and button:IsA("BasePart") and (button.Position - pit.Position).Magnitude < 60 then
		prompt(button, "Shred!", function(player)
			local m = nearestFree(button.Position, MapMachines.LOAD_REACH)
			if m then
				task.spawn(shred, m, pit, player)
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
				end
			end
			task.wait(5)
		end
	end)
	local _ = Players
end

return MapMachines
