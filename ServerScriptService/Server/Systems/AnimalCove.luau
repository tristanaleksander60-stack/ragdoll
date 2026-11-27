--!strict
-- 3.27-3.29 THE ANIMAL COVE COMES ALIVE (docs/MACHINES_10.md "BEAR", "CROCODILES", "T-REX"; Config.ANIMALS_10). Until now
-- the bear, the crocodiles and the T-rex were statues (LabOwnerMap places them). Server-side, cartoon only, no gore:
--   * THE BEAR (at the cave mouth) sleeps and breathes. Poke it (a prompt) or let a ragdoll come within WAKE studs: it
--     wakes with a ROAR (a big shake), rears up and SWATS the nearest ragdoll out like a ball. 1 in 4 it gives it a BEAR
--     HUG instead (holds it a few seconds) and goes back to sleep. "Zzz".
--   * THE CROCODILES: a ragdoll at the pond's edge or in the water: the nearest croc swims in, SNAPS, does a cartoon
--     death-roll splash and tosses it onto the bank.
--   * THE T-REX: a lever by the pen's gate opens it (the gate slides up). For RAMPAGE s the T-rex stomps (footstep booms)
--     after the ragdolls in the pen, picks one up in its jaws, shakes it and tosses it high; every ROAR_EVERY s a ROAR
--     with a shock ring knocks every ragdoll in the pen flat. A player inside who gets close is nudged out, unhurt.
--     Then it walks home and the gate closes.
-- Every model is anchored and moved with PivotTo; the bodies are moved and pushed through DummyControl.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AnimalCove = {}

AnimalCove.WAKE = 9
AnimalCove.SWAT_REACH = 16
AnimalCove.RAMPAGE = 30
AnimalCove.ROAR_EVERY = 8
AnimalCove.REX_SPEED = 11

local busy: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local wired: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pelvisOf(m: Instance): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function pop(at: Vector3, text: string, color: Color3)
	pcall(function()
		lazy("Playground").pop(at, text, color)
	end)
end

local function shake(at: Vector3, power: number)
	pcall(function()
		lazy("FxService").hit(at, power, "CannonPad")
	end)
end

local function free(m: Instance): boolean
	return m:IsA("Model") and not busy[m] and m:GetAttribute("Held") ~= true and m:GetAttribute("Vital") ~= "Dead"
		and m:GetAttribute("InMachine") == nil and m:GetAttribute("MachineHidden") == nil and m:GetAttribute("TryFor") == nil
end

-- The free ragdolls whose pelvis passes `test`, nearest to `at` first.
local function bodies(at: Vector3, test: (Vector3) -> boolean): { Model }
	local dummies = Workspace:FindFirstChild("Dummies")
	local list: { { m: Model, d: number } } = {}
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = pelvisOf(m)
		if pe and free(m) and test(pe.Position) then
			table.insert(list, { m = m :: Model, d = (pe.Position - at).Magnitude })
		end
	end
	table.sort(list, function(a, b)
		return a.d < b.d
	end)
	local out = {}
	for _, e in list do
		table.insert(out, e.m)
	end
	return out
end

local function glide(model: Model, to: CFrame, seconds: number)
	local from = model:GetPivot()
	local t0 = os.clock()
	while os.clock() - t0 < seconds and model.Parent do
		local k = (os.clock() - t0) / seconds
		k = k * k * (3 - 2 * k)
		model:PivotTo(from:Lerp(to, k))
		task.wait(0.03)
	end
	model:PivotTo(to)
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- THE BEAR -------------------------------------------------------------------------------------------------------
local function wireBear(bear: Model)
	local home = bear:GetPivot()
	local cf, size = bear:GetBoundingBox()
	local anchor = Instance.new("Part")
	anchor.Name = "BearPoke"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch, anchor.Transparency = true, false, false, false, 1
	anchor.Size = Vector3.one
	anchor.CFrame = cf
	anchor.Parent = bear
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Poke"
	pp.ObjectText = "Sleeping bear"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = anchor
	local awake = false
	local nextWake = 0
	local function wake(by: Player?)
		if awake or os.clock() < nextWake then
			return
		end
		awake = true
		pp.Enabled = false
		task.spawn(function()
			pop(cf.Position + Vector3.new(0, size.Y / 2 + 2, 0), "ROAR!", Color3.fromRGB(255, 150, 80))
			shake(cf.Position, 160)
			glide(bear, home * CFrame.Angles(math.rad(-18), 0, 0) + Vector3.new(0, 0.6, 0), 0.35)
			local target = bodies(cf.Position, function(p)
				return (p - cf.Position).Magnitude < AnimalCove.SWAT_REACH
			end)[1]
			if target then
				busy[target] = true
				local pe = pelvisOf(target)
				local dir = if pe then flat(pe.Position - cf.Position) else home.LookVector
				dir = if dir.Magnitude > 0.1 then dir.Unit else home.LookVector
				if math.random(4) == 1 then
					-- the BEAR HUG: held close a few seconds, then it dozes off again
					pop(cf.Position + Vector3.new(0, size.Y / 2 + 3, 0), "BEAR HUG!", Color3.fromRGB(255, 170, 200))
					target:SetAttribute("MoodSay", "Let me goooo!")
					local hugAt = cf.Position + dir * (size.Z / 2 + 0.5) + Vector3.new(0, 1, 0)
					local t0 = os.clock()
					while os.clock() - t0 < 3.5 and target.Parent do
						pcall(lazy("DummyControl").move, target, CFrame.lookAt(hugAt, cf.Position) * CFrame.new(0, math.sin((os.clock() - t0) * 8) * 0.15, 0))
						task.wait(0.1)
					end
					target:SetAttribute("MoodSay", nil)
					pcall(lazy("DummyControl").push, target, dir * 25 + Vector3.new(0, 20, 0), by)
				else
					-- the SWAT: a lunge and a big arc
					glide(bear, (home + dir * 2) * CFrame.Angles(math.rad(10), 0, 0), 0.15)
					pcall(lazy("DummyControl").push, target, dir * 110 + Vector3.new(0, 85, 0), by)
					shake(cf.Position + dir * 3, 90)
					pop(cf.Position + dir * 3 + Vector3.new(0, 5, 0), "SWAT!", Color3.fromRGB(255, 200, 90))
				end
				task.delay(1.5, function()
					busy[target] = nil
				end)
			end
			task.wait(0.6)
			glide(bear, home, 0.6)
			pop(cf.Position + Vector3.new(0, size.Y / 2 + 2, 0), "Zzz...", Color3.fromRGB(200, 210, 255))
			nextWake = os.clock() + 8
			awake = false
			pp.Enabled = true
		end)
	end
	pp.Triggered:Connect(function(player)
		wake(player)
	end)
	task.spawn(function()
		local t = 0
		while bear.Parent do
			task.wait(0.15)
			t += 0.15
			if not awake then
				-- asleep: a slow breath
				bear:PivotTo(home + Vector3.new(0, math.sin(t * 1.6) * 0.08, 0))
				if #bodies(cf.Position, function(p)
					return (p - cf.Position).Magnitude < AnimalCove.WAKE
				end) > 0 then
					wake(nil)
				end
			end
		end
	end)
end

-- THE CROCODILES -------------------------------------------------------------------------------------------------
local function splash(at: Vector3)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.Position = at
	p.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255), Color3.fromRGB(120, 180, 210))
	e.Size = NumberSequence.new(0.8, 0.2)
	e.Speed = NumberRange.new(10, 22)
	e.SpreadAngle = Vector2.new(50, 50)
	e.Acceleration = Vector3.new(0, -50, 0)
	e.Lifetime = NumberRange.new(0.6, 1)
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = p
	e:Emit(40)
	task.delay(2, function()
		p:Destroy()
	end)
end

local function wireCrocs(water: BasePart, crocs: { Model })
	local centre = water.Position
	local radius = math.max(water.Size.Y, water.Size.Z) / 2
	local homes: { [Model]: CFrame } = {}
	for _, c in crocs do
		homes[c] = c:GetPivot()
	end
	local busyCroc = false
	task.spawn(function()
		while water.Parent do
			task.wait(0.3)
			if busyCroc then
				continue
			end
			local target = bodies(centre, function(p)
				return flat(p - centre).Magnitude < radius + 3 and math.abs(p.Y - centre.Y) < 8
			end)[1]
			if not target then
				continue
			end
			local pe = pelvisOf(target)
			if not pe then
				continue
			end
			busyCroc = true
			busy[target] = true
			task.spawn(function()
				-- the nearest croc swims in
				local best, bestD = nil :: Model?, math.huge
				for _, c in crocs do
					local d = (c:GetPivot().Position - pe.Position).Magnitude
					if d < bestD then
						best, bestD = c, d
					end
				end
				local croc = best
				if croc and croc.Parent then
					local home = homes[croc]
					local goal = Vector3.new(pe.Position.X, home.Position.Y, pe.Position.Z)
					local dist = flat(goal - home.Position).Magnitude
					glide(croc, CFrame.lookAt(home.Position:Lerp(goal, 0.85), goal), math.clamp(dist / 14, 0.4, 2.5))
					-- SNAP and the death roll
					pop(goal + Vector3.new(0, 4, 0), "SNAP!", Color3.fromRGB(140, 220, 120))
					splash(goal)
					local base = croc:GetPivot()
					local t0 = os.clock()
					while os.clock() - t0 < 0.9 and target.Parent do
						local k = (os.clock() - t0) / 0.9
						croc:PivotTo(base * CFrame.Angles(0, 0, k * math.pi * 4))
						pcall(lazy("DummyControl").move, target, base * CFrame.new(0, 1, -2) * CFrame.Angles(0, 0, k * math.pi * 4))
						task.wait(0.05)
					end
					croc:PivotTo(base)
					splash(goal)
					-- tossed onto the bank, dizzy
					local out = flat(goal - centre)
					out = if out.Magnitude > 0.1 then out.Unit else Vector3.xAxis
					pcall(lazy("DummyControl").push, target, out * 70 + Vector3.new(0, 60, 0))
					task.wait(0.6)
					glide(croc, home, 1.2)
				end
				task.delay(2, function()
					busy[target] = nil
				end)
				task.wait(4)
				busyCroc = false
			end)
		end
	end)
end

-- THE T-REX ------------------------------------------------------------------------------------------------------
local function wireRex(rex: Model, ground: BasePart, gate: BasePart)
	local home = rex:GetPivot()
	local _, rsize = rex:GetBoundingBox()
	local gateHome = gate.CFrame
	local outward = flat(gate.Position - ground.Position)
	outward = if outward.Magnitude > 0.1 then outward.Unit else Vector3.xAxis
	local lever = Instance.new("Part")
	lever.Name = "TRexLever"
	lever.Size = Vector3.new(0.6, 4, 0.6)
	lever.Color = Color3.fromRGB(210, 40, 40)
	lever.Material = Enum.Material.SmoothPlastic
	lever.Anchored, lever.CanCollide = true, false
	local leverAt = gate.Position + outward * 4 + gate.CFrame.LookVector * (gate.Size.Z / 2 + 2)
	lever.CFrame = CFrame.new(Vector3.new(leverAt.X, ground.Position.Y + 2, leverAt.Z))
	lever.Parent = rex.Parent
	local box = Instance.new("Part")
	box.Name = "TRexLeverBox"
	box.Size = Vector3.new(2.4, 2.4, 2.4)
	box.Color = Color3.fromRGB(240, 200, 40)
	box.Material = Enum.Material.Metal
	box.Anchored = true
	box.CFrame = lever.CFrame * CFrame.new(0, -0.8, 0)
	box.Parent = rex.Parent
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Open the gate"
	pp.ObjectText = "T-REX"
	pp.HoldDuration = 0.4
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = lever
	local halfX, halfZ = ground.Size.X / 2, ground.Size.Z / 2
	local function inPen(p: Vector3): boolean
		local rel = ground.CFrame:PointToObjectSpace(p)
		return math.abs(rel.X) < halfX and math.abs(rel.Z) < halfZ and rel.Y < 25 and rel.Y > -3
	end
	local running = false
	pp.Triggered:Connect(function(player)
		if running then
			return
		end
		running = true
		pp.Enabled = false
		task.spawn(function()
			-- the gate slides up
			local up = gateHome + Vector3.new(0, gate.Size.Y + 1, 0)
			local t0 = os.clock()
			while os.clock() - t0 < 1 do
				gate.CFrame = gateHome:Lerp(up, (os.clock() - t0))
				task.wait(0.03)
			end
			gate.CFrame = up
			pop(rex:GetPivot().Position + Vector3.new(0, rsize.Y / 2 + 4, 0), "ROAR!", Color3.fromRGB(255, 120, 60))
			shake(rex:GetPivot().Position, 200)
			local startT = os.clock()
			local lastRoar, lastStep = os.clock(), 0
			while os.clock() - startT < AnimalCove.RAMPAGE and rex.Parent do
				local here = rex:GetPivot()
				local target = bodies(here.Position, inPen)[1]
				if target then
					local pe = pelvisOf(target)
					if pe then
						local to = flat(pe.Position - here.Position)
						local dist = to.Magnitude
						local look = if dist > 0.1 then to.Unit else here.LookVector
						if dist > rsize.Z * 0.45 + 3 then
							local nextPos = here.Position + look * math.min(dist, AnimalCove.REX_SPEED * 0.1)
							rex:PivotTo(CFrame.lookAt(nextPos, nextPos + look))
							if os.clock() - lastStep > 0.7 then
								lastStep = os.clock()
								shake(nextPos, 35) -- (a footstep boom)
							end
						else
							-- the bite: up in its jaws, shaken, tossed high
							busy[target] = true
							pop(pe.Position + Vector3.new(0, 6, 0), "CHOMP!", Color3.fromRGB(255, 200, 90))
							local jaw = here * CFrame.new(0, rsize.Y * 0.7, -rsize.Z * 0.45)
							local b0 = os.clock()
							while os.clock() - b0 < 1.2 and target.Parent do
								local k = os.clock() - b0
								rex:PivotTo(here * CFrame.Angles(0, math.sin(k * 20) * 0.15, 0))
								pcall(lazy("DummyControl").move, target, jaw * CFrame.new(math.sin(k * 20) * 1.5, 0, 0))
								task.wait(0.05)
							end
							rex:PivotTo(here)
							pcall(lazy("DummyControl").push, target, look * 40 + Vector3.new(0, 120, 0), player)
							task.delay(2, function()
								busy[target] = nil
							end)
						end
					end
				end
				if os.clock() - lastRoar > AnimalCove.ROAR_EVERY then
					lastRoar = os.clock()
					local at = rex:GetPivot().Position
					pop(at + Vector3.new(0, rsize.Y / 2 + 4, 0), "ROAR!", Color3.fromRGB(255, 120, 60))
					shake(at, 220)
					for _, m in bodies(at, inPen) do
						local pe = pelvisOf(m)
						if pe then
							local away = flat(pe.Position - at)
							away = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
							pcall(lazy("DummyControl").push, m, away * 50 + Vector3.new(0, 30, 0), player)
						end
					end
				end
				-- a player inside who gets close is nudged out, unhurt
				for _, pl in Players:GetPlayers() do
					local root = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
					if root and root:IsA("BasePart") and inPen(root.Position) and (root.Position - rex:GetPivot().Position).Magnitude < rsize.Z * 0.5 + 4 then
						pcall(function()
							lazy("PlayerRagdoll").launch(pl, outward * 60 + Vector3.new(0, 35, 0))
						end)
					end
				end
				task.wait(0.1)
			end
			-- home and the gate closes
			glide(rex, home, 2)
			t0 = os.clock()
			while os.clock() - t0 < 1 do
				gate.CFrame = up:Lerp(gateHome, (os.clock() - t0))
				task.wait(0.03)
			end
			gate.CFrame = gateHome
			running = false
			pp.Enabled = true
		end)
	end)
end

function AnimalCove.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.ANIMALS_10 then
		return
	end
	task.spawn(function()
		while true do
			local root = Workspace:FindFirstChild("Playground")
			for _, lab in if root then root:GetChildren() else {} do
				local om = lab:FindFirstChild("OwnerMap")
				if om then
					local bear = om:FindFirstChild("Bear")
					if bear and bear:IsA("Model") and not wired[bear] then
						wired[bear] = true
						pcall(wireBear, bear)
					end
					local water = om:FindFirstChild("CrocWater")
					if water and water:IsA("BasePart") and not wired[water] then
						local crocs = {}
						for _, c in om:GetChildren() do
							if c.Name == "Crocodile" and c:IsA("Model") then
								table.insert(crocs, c)
							end
						end
						if #crocs > 0 then
							wired[water] = true
							pcall(wireCrocs, water, crocs)
						end
					end
					local rex = om:FindFirstChild("TRex")
					local ground = om:FindFirstChild("TRexGround")
					if rex and rex:IsA("Model") and ground and ground:IsA("BasePart") and not wired[rex] then
						local gate: BasePart? = nil
						local gd = math.huge
						for _, g in om:GetChildren() do
							if g.Name == "TRexGate" and g:IsA("BasePart") and (g.Position - ground.Position).Magnitude < gd then
								gate, gd = g, (g.Position - ground.Position).Magnitude
							end
						end
						if gate then
							wired[rex] = true
							pcall(wireRex, rex, ground, gate)
						end
					end
				end
			end
			task.wait(5)
		end
	end)
end

return AnimalCove
