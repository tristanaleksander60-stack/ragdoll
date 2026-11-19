--!strict
-- v3 Phase C (19 Nov 2026; research: animals and "escalating chaos" are top requests and video
-- formats): the animals of two lab events, built by code (blocky, cartoon, no blood).
--   Gorilla Rampage: a big gorilla stomps after the nearest dummy and swats it across the lab
--     (players who get in its way fly too, unhurt).
--   Bull Run: three bulls thunder across the lab one after another, throwing whatever is in the lane.
-- The server moves them (anchored, PivotTo) and knocks bodies through DummyControl.hit and
-- PlayerRagdoll.knock, as a blast does. Each returns a stop function for the event's clean-up.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent
local DummyControl = require(Systems.DummyControl)
local FxService = require(Systems.FxService)
local PlayerRagdoll = require(Systems.PlayerRagdoll)

local Creatures = {}

Creatures.GORILLA_SPEED = 16 -- studs/s
Creatures.GORILLA_REACH = 8 -- studs from its middle to swat
Creatures.GORILLA_SWAT = 85 -- body speed a swat gives
Creatures.GORILLA_GAP = 0.7 -- s between swats
Creatures.BULL_SPEED = 48
Creatures.BULL_REACH = 5.5
Creatures.BULL_THROW = 95
Creatures.HALF = 70 -- studs from the lab's middle the animals keep inside

local function block(model: Model, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = offset
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function folder(): Folder
	local f = Workspace:FindFirstChild("Creatures")
	if f and f:IsA("Folder") then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "Creatures"
	made.Parent = Workspace
	return made
end

-- A gorilla standing at the origin facing -Z (feet on y = 0).
local function gorillaModel(): (Model, { [string]: BasePart })
	local fur = Color3.fromRGB(46, 44, 48)
	local skin = Color3.fromRGB(96, 84, 80)
	local m = Instance.new("Model")
	m.Name = "Gorilla"
	local parts: { [string]: BasePart } = {}
	parts.body = block(m, "Body", Vector3.new(6, 6, 4.5), CFrame.new(0, 7.5, 0), fur)
	m.PrimaryPart = parts.body
	block(m, "Chest", Vector3.new(4, 3.4, 0.4), CFrame.new(0, 7.8, -2.3), skin)
	parts.head = block(m, "Head", Vector3.new(3.4, 3, 3), CFrame.new(0, 11.6, -0.8), fur)
	block(m, "Face", Vector3.new(2.6, 2, 0.4), CFrame.new(0, 11.3, -2.4), skin)
	for _, side in { -1, 1 } do
		block(m, "Eye", Vector3.new(0.5, 0.5, 0.2), CFrame.new(side * 0.6, 11.8, -2.62), Color3.fromRGB(250, 250, 250))
		parts["arm" .. side] = block(m, "Arm", Vector3.new(1.8, 7, 1.8), CFrame.new(side * 4, 6.2, -0.6), fur)
		block(m, "Fist", Vector3.new(2.2, 1.6, 2.2), CFrame.new(side * 4, 2.4, -0.6), skin)
		parts["leg" .. side] = block(m, "Leg", Vector3.new(2, 4.5, 2), CFrame.new(side * 1.7, 2.25, 0.4), fur)
	end
	return m, parts
end

-- A bull standing at the origin facing -Z.
local function bullModel(): Model
	local hide = Color3.fromRGB(70, 44, 32)
	local m = Instance.new("Model")
	m.Name = "Bull"
	local body = block(m, "Body", Vector3.new(4, 4, 8), CFrame.new(0, 4.5, 0), hide)
	m.PrimaryPart = body
	block(m, "Head", Vector3.new(3, 3, 3), CFrame.new(0, 5.2, -5), hide)
	block(m, "Snout", Vector3.new(2.2, 1.4, 0.8), CFrame.new(0, 4.4, -6.7), Color3.fromRGB(190, 140, 130))
	for _, side in { -1, 1 } do
		block(m, "Horn", Vector3.new(2.2, 0.6, 0.6), CFrame.new(side * 2.4, 6.6, -5.2) * CFrame.Angles(0, 0, side * math.rad(-25)), Color3.fromRGB(240, 232, 210))
		for _, z in { -2.8, 2.8 } do
			block(m, "Leg", Vector3.new(1.1, 2.6, 1.1), CFrame.new(side * 1.4, 1.3, z), hide)
		end
	end
	return m
end

local function knock(model: Model, from: Vector3, speed: number, lift: number)
	local pelvis = model:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") then
		return
	end
	local offset = pelvis.Position - from
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) + Vector3.new(0, lift, 0)).Unit
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	DummyControl.hit(model, pelvis, dir * speed * mass, pelvis.Position)
end

local function knockPlayers(from: Vector3, reach: number, speed: number, lift: number, center: Vector3)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local offset = root.Position - from
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude < reach and math.abs(root.Position.X - center.X) < Creatures.HALF + 10 then
				local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) + Vector3.new(0, lift, 0)).Unit
				PlayerRagdoll.knock(player, dir * speed * 0.7)
			end
		end
	end
end

type Body = { model: Model, pelvis: BasePart }
local function dummiesIn(center: Vector3): { Body }
	local out: { Body } = {}
	local f = Workspace:FindFirstChild("Dummies")
	for _, model in if f then f:GetChildren() else {} do
		local pelvis = model:FindFirstChild("LowerTorso")
		if model:IsA("Model") and pelvis and pelvis:IsA("BasePart") then
			local o = pelvis.Position - center
			if math.abs(o.X) < Creatures.HALF and o.Z > -95 and o.Z < 72 then
				table.insert(out, { model = model, pelvis = pelvis })
			end
		end
	end
	return out
end

-- Gorilla Rampage in the lab around `center` (the lab's middle at floor height).
function Creatures.gorilla(center: Vector3): () -> ()
	local model, parts = gorillaModel()
	local base: { [BasePart]: CFrame } = {}
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			base[p] = p.CFrame
		end
	end
	local at = center + Vector3.new(0, 0, 60)
	local facing = 0
	local function place(t: number)
		local bob = math.abs(math.sin(t * 6)) * 0.6
		local root = CFrame.new(at) * CFrame.Angles(0, facing, 0) * CFrame.new(0, bob, 0)
		for p, cf in base do
			local extra = CFrame.identity
			if p == parts["arm-1"] or p == parts["arm1"] then
				extra = CFrame.new(0, 3, 0) * CFrame.Angles(math.sin(t * 6 + (if p == parts["arm1"] then math.pi else 0)) * 0.5, 0, 0) * CFrame.new(0, -3, 0)
			end
			p.CFrame = root * cf * extra
		end
	end
	place(0)
	model.Parent = folder()
	FxService.hit(at + Vector3.new(0, 4, 0), 120, "BigBoom")
	local lastSwat = 0
	local t = 0
	local connection = RunService.Heartbeat:Connect(function(dt)
		t += dt
		-- The nearest dummy standing in the lab.
		local target: Vector3? = nil
		local best = math.huge
		for _, d in dummiesIn(center) do
			local dist = (d.pelvis.Position - at).Magnitude
			if dist < best then
				best, target = dist, d.pelvis.Position
			end
		end
		local goal = target or center
		local flat = Vector3.new(goal.X - at.X, 0, goal.Z - at.Z)
		if flat.Magnitude > 2 then
			local step = flat.Unit * math.min(flat.Magnitude, Creatures.GORILLA_SPEED * dt)
			at += step
			facing = math.atan2(-flat.X, -flat.Z)
		end
		local o = at - center
		at = center + Vector3.new(math.clamp(o.X, -Creatures.HALF, Creatures.HALF), 0, math.clamp(o.Z, -90, 68))
		place(t)
		if os.clock() - lastSwat > Creatures.GORILLA_GAP then
			local swatted = false
			for _, d in dummiesIn(center) do
				if (d.pelvis.Position - at).Magnitude < Creatures.GORILLA_REACH then
					knock(d.model, at, Creatures.GORILLA_SWAT, 0.9)
					swatted = true
				end
			end
			if swatted then
				lastSwat = os.clock()
				FxService.hit(at + Vector3.new(0, 3, 0), 90, "BigBoom")
				knockPlayers(at, Creatures.GORILLA_REACH, Creatures.GORILLA_SWAT, 0.9, center)
			end
		end
	end)
	return function()
		connection:Disconnect()
		model:Destroy()
	end
end

-- Bull Run in the lab around `center`: three bulls across the lab, one after another.
function Creatures.bulls(center: Vector3): () -> ()
	local running = true
	local made: { Model } = {}
	local connections: { RBXScriptConnection } = {}
	task.spawn(function()
		for i = 1, 3 do
			if not running then
				return
			end
			local z = -40 + (i - 1) * 30 -- three lanes across the lab
			local fromLeft = i % 2 == 1
			local x0 = if fromLeft then -Creatures.HALF else Creatures.HALF
			local dirX = if fromLeft then 1 else -1
			local bull = bullModel()
			local base: { [BasePart]: CFrame } = {}
			for _, p in bull:GetChildren() do
				if p:IsA("BasePart") then
					base[p] = p.CFrame
				end
			end
			local facing = if fromLeft then -math.pi / 2 else math.pi / 2
			local at = center + Vector3.new(x0, 0, z)
			local hit: { [Model]: boolean } = {}
			bull.Parent = folder()
			table.insert(made, bull)
			FxService.hit(at, 70, "BigBoom")
			local t = 0
			local c: RBXScriptConnection
			c = RunService.Heartbeat:Connect(function(dt)
				t += dt
				at += Vector3.new(dirX * Creatures.BULL_SPEED * dt, 0, 0)
				local root = CFrame.new(at) * CFrame.Angles(0, facing, 0) * CFrame.new(0, math.abs(math.sin(t * 14)) * 0.5, 0)
				for p, cf in base do
					p.CFrame = root * cf
				end
				for _, d in dummiesIn(center) do
					local o = d.pelvis.Position - at
					if not hit[d.model] and math.abs(o.Z) < Creatures.BULL_REACH and math.abs(o.X) < Creatures.BULL_REACH + 1 then
						hit[d.model] = true
						knock(d.model, at - Vector3.new(dirX * 4, 0, 0), Creatures.BULL_THROW, 1.1)
					end
				end
				knockPlayers(at, Creatures.BULL_REACH, Creatures.BULL_THROW, 1.1, center)
				if math.abs(at.X - center.X) > Creatures.HALF + 2 then
					c:Disconnect()
					bull:Destroy()
				end
			end)
			table.insert(connections, c)
			task.wait(4)
		end
	end)
	return function()
		running = false
		for _, c in connections do
			c:Disconnect()
		end
		for _, m in made do
			m:Destroy()
		end
	end
end

return Creatures
