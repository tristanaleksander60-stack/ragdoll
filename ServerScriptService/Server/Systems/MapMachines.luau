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
local function spin(m: Model, hub: Vector3, by: Player?)
	if busy[m] then
		return
	end
	busy[m] = true
	m:SetAttribute("InMachine", "Gyro")
	local DC = control()
	local t0 = os.clock()
	while m.Parent and os.clock() - t0 < MapMachines.SPIN_TIME and m:GetAttribute("Held") ~= true do
		local t = os.clock() - t0
		pcall(DC.move, m, CFrame.new(hub) * CFrame.Angles(t * 7, t * 5, t * 3))
		task.wait(0.1)
	end
	task.wait(0.1)
	m:SetAttribute("InMachine", nil)
	if m.Parent and m:GetAttribute("Held") ~= true then
		local a = math.random() * math.pi * 2
		pcall(DC.push, m, Vector3.new(math.cos(a) * 130, 90, math.sin(a) * 130), by)
		pcall(function()
			require(script.Parent:WaitForChild("FxService")).hit(hub, 50, "CannonPad")
		end)
	end
	task.delay(1, function()
		busy[m] = nil
	end)
end

local function wireGyro(pad: BasePart)
	local hub = pad.Position + Vector3.new(0, 19.7, 0)
	local button = pad.Parent and pad.Parent:FindFirstChild("GyroButton")
	if button and button:IsA("BasePart") and (button.Position - pad.Position).Magnitude < 40 then
		prompt(button, "Spin!", function(player)
			local m = nearestFree(button.Position, MapMachines.LOAD_REACH)
			if m then
				local DC = control()
				pcall(DC.move, m, CFrame.new(hub))
				task.spawn(spin, m, hub, player)
			end
		end)
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
