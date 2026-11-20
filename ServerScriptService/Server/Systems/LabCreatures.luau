--!strict
-- V6-5: the creature yard in front of each lab (Config.LAB_CREATURES). Real Creator Store models
-- (ServerStorage.V3Assets, malware pass done on insert) that play with dummies, cartoon style and
-- kid-safe: nothing is eaten for real, everything is swallowed and spat out whole.
--   SPIDER     a web in the corner: a dummy that touches it is wrapped in silk (a wiggling cocoon),
--              munched and spat out as a "burrito" across the lab; a hunger meter (full = a nap)
--   PLANT      a giant plant chomps a dummy at its feet and spits it high
--   FROG       its tongue grabs a dummy within reach and spits it back
--   WHALE      a dummy in its pool goes up a geyser
--   CHICKEN    a dummy in the coop is laid as an egg that wobbles, cracks and hatches it
--   WASHER     a washing machine spins a dummy and throws it out
--   SLINGSHOT  a tree with a band: a dummy on its pad is pulled back and fired at the lab
--   MOLE       pops up under dummies in its dirt patch and throws them up
--   VACUUM     a robot vacuum drives the yard, sucks up dummies and shoots them out behind
-- Each one counts an ExperimentService event for the lab's owner (experiment cards and journal
-- pages of the same kind). Bodies are only moved and pushed through DummyControl (the lab's player
-- simulates them), one at a time per machine, never one that someone holds.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Systems = script.Parent

local LabCreatures = {}

LabCreatures.YARD_Z = 92 -- the yard's middle line, in front of the lab (z from the lab's origin)
LabCreatures.CHECK = 0.3 -- s between looks for dummies in the triggers
LabCreatures.SPIDER_FULL = 100
LabCreatures.SPIDER_MEAL = 34 -- hunger filled per dummy (3 meals = full)
LabCreatures.SPIDER_NAP = 20 -- s it sleeps when full
LabCreatures.SPIDER_DIGEST = 1.5 -- hunger lost per second

local function lazy(name: string): any
	return require(Systems:WaitForChild(name)) :: any
end

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

-- A copy of a V3Assets model, scaled, turned, its lowest point on the ground at `at`.
local function place(into: Instance, name: string, at: Vector3, yaw: number, size: number): Model?
	local assets = ServerStorage:FindFirstChild("V3Assets")
	local src = assets and assets:FindFirstChild(name)
	if not src or not src:IsA("Model") then
		return nil
	end
	local m = src:Clone()
	local _, s0 = m:GetBoundingBox()
	local longest = math.max(s0.X, s0.Y, s0.Z)
	if longest > 0 then
		m:ScaleTo(m:GetScale() * size / longest)
	end
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0))
	local cf, s = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, at.Y - (cf.Position.Y - s.Y / 2), 0))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = false
			d.CanCollide = false -- (a body walking in must reach the trigger, not bump the model)
		end
	end
	m.Parent = into
	return m
end

-- Plays fn(t) for t 0..1 over `seconds` (server-side model motion, a few at a time).
local function play(seconds: number, fn: (number) -> ())
	local t0 = os.clock()
	while true do
		local t = math.clamp((os.clock() - t0) / seconds, 0, 1)
		fn(t)
		if t >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

local function rootOf(m: Model): BasePart?
	local r = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")
	return if r and r:IsA("BasePart") then r else nil
end

-- Dummies with a part inside a box (once each).
local function dummiesIn(cf: CFrame, size: Vector3): { Model }
	local folder = Workspace:FindFirstChild("Dummies")
	if not folder then
		return {}
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local seen: { [Model]: boolean } = {}
	local out = {}
	for _, p in Workspace:GetPartBoundsInBox(cf, size, params) do
		local m = p:FindFirstAncestorOfClass("Model")
		while m and m.Parent ~= folder do
			m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") or nil
		end
		if m and not seen[m] and m:GetAttribute("Held") ~= true and m:GetAttribute("InMachine") == nil and os.clock() >= ((m:GetAttribute("MachineCool") :: number?) or 0) then -- (MachineCool: just thrown, not taken again at once)
			seen[m] = true
			table.insert(out, m)
		end
	end
	return out
end

-- A machine's look into its trigger box; the box's middle is kept on the machine's folder (Trigger)
-- so a self-test (T108) can drop a body right into it.
local function look(f: Instance, cf: CFrame, size: Vector3): { Model }
	if f:GetAttribute("Trigger") ~= cf.Position then
		f:SetAttribute("Trigger", cf.Position)
	end
	return dummiesIn(cf, size)
end

-- Holds a body at a spot for a while (moved there again and again: the owner simulates it).
local function hold(model: Model, at: () -> CFrame, seconds: number)
	local DummyControl = lazy("DummyControl")
	local t0 = os.clock()
	while os.clock() - t0 < seconds and model.Parent and model:GetAttribute("InMachine") ~= nil do -- (stops the moment it is let go)
		DummyControl.move(model, at())
		task.wait(0.12)
	end
end

-- (Review fix: the server blocks are already invisible on screens (DummySkins draws skins over
-- them), so hiding is an attribute every client honours on the skins.)
local function hideBody(model: Model, hidden: boolean)
	model:SetAttribute("MachineHidden", if hidden then true else nil)
end

type Machine = {
	id: string,
	label: string,
	lab: Model?,
	folder: Folder,
	owner: () -> Player?,
	busy: boolean,
	toLab: Vector3, -- (level, from the creature toward the lab's middle: every throw lands back in play)
	temp: { Instance }, -- (parts made for one swallow: removed if it fails half way)
}

local function credit(m: Machine)
	local p = m.owner()
	if p then
		pcall(function()
			lazy("ExperimentService").event(p, m.id, 1, m.label)
		end)
	end
end

-- The common shape: take one body from the trigger, do `inside` with it, then let it go flying.
local function swallow(m: Machine, model: Model, inside: (Model) -> Vector3)
	m.busy = true
	m.folder:SetAttribute("Busy", true) -- (CreatureLife on the screens rests while it works)
	model:SetAttribute("InMachine", m.id)
	task.spawn(function()
		local ok, err = pcall(function()
			local out = inside(model)
			-- (Let go first, so no hold step pulls it back after the push.)
			model:SetAttribute("InMachine", nil)
			hideBody(model, false)
			task.wait(0.15)
			if model.Parent then
				lazy("DummyControl").push(model, out, nil)
				model:SetAttribute("MachineCool", os.clock() + 6)
			end
			credit(m)
		end)
		if not ok then
			warn("[LabCreatures] " .. m.id .. ": " .. tostring(err))
			for _, t in m.temp do
				if t.Parent then
					t:Destroy() -- (no cocoon, tongue or egg left behind)
				end
			end
		end
		if model.Parent then
			hideBody(model, false)
			model:SetAttribute("InMachine", nil)
		end
		table.clear(m.temp)
		task.wait(1)
		m.busy = false
		m.folder:SetAttribute("Busy", nil)
	end)
end

------------------------------------------------------------------------------------------------
-- The creatures

local BUILD: { [string]: (Folder, CFrame, Machine) -> ((() -> ())?) } = {}

-- SPIDER: a web in the yard's east corner; hunger meter on a small sign.
BUILD.Spider = function(f, at, m)
	local web = part(f, "SpiderWeb", Vector3.new(26, 26, 0.4), at * CFrame.new(0, 14, 0), Color3.fromRGB(235, 235, 240), Enum.Material.SmoothPlastic)
	web.Transparency = 1 -- (only the threads show)
	web.CanQuery = true
	for i = 0, 7 do
		local a = i * math.pi / 8
		local thread = part(f, "WebThread", Vector3.new(0.12, 26, 0.12), web.CFrame * CFrame.Angles(0, 0, a), Color3.fromRGB(250, 250, 255), Enum.Material.Neon)
		thread.Transparency = 0.35
	end
	for r = 2.5, 12.5, 2.5 do
		for i = 0, 7 do
			local a1, a2 = i * math.pi / 4, (i + 1) * math.pi / 4
			local p1 = Vector3.new(math.cos(a1) * r, math.sin(a1) * r, 0)
			local p2 = Vector3.new(math.cos(a2) * r, math.sin(a2) * r, 0)
			local mid = (p1 + p2) / 2
			local ring = part(f, "WebRing", Vector3.new((p2 - p1).Magnitude, 0.1, 0.1), web.CFrame * CFrame.new(mid) * CFrame.Angles(0, 0, math.atan2(p2.Y - p1.Y, p2.X - p1.X)), Color3.fromRGB(250, 250, 255), Enum.Material.Neon)
			ring.Transparency = 0.4
		end
	end
	local spider = place(f, "MSpider", (at * CFrame.new(0, 0, -7)).Position, 180, 13)
	-- (20 Nov 2026, the owner: the spider lives ON its giant web: head down, legs spread on the
	-- threads, on the side that faces the lab. Its own up is the web's normal; its local +Z is up.)
	if spider then
		local n = web.CFrame.LookVector
		if n:Dot(m.toLab) < 0 then
			n = -n
		end
		local onWeb = web.Position + Vector3.new(0, 4.5, 0) + n * 1.2
		spider:PivotTo(CFrame.fromMatrix(onWeb, n:Cross(Vector3.yAxis).Unit, n))
	end
	local home = if spider then spider:GetPivot() else at
	-- (V6-7: the golden SPIDER DELUXE when the lab owner has it.)
	local labF = f.Parent and f.Parent.Parent
	if spider and labF then
		local looks: { [BasePart]: { Color3 | Enum.Material } } = {}
		for _, d in spider:GetDescendants() do
			if d:IsA("BasePart") then
				looks[d] = { d.Color, d.Material }
			end
		end
		labF:GetAttributeChangedSignal("SpiderDeluxe"):Connect(function()
			local gold = labF:GetAttribute("SpiderDeluxe") == true
			for d, was in looks do
				d.Color = if gold then Color3.fromRGB(230, 186, 60) else was[1] :: Color3
				d.Material = if gold then Enum.Material.Foil else was[2] :: Enum.Material
			end
		end)
	end
	local hunger = 0
	local napUntil = 0
	local sign = Instance.new("BillboardGui")
	sign.Name = "SpiderHunger"
	sign.Size = UDim2.fromOffset(120, 26)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 16, 0)
	sign.MaxDistance = 90
	sign.Adornee = web
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
	bar.BackgroundTransparency = 0.2
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(140, 220, 120)
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = bar
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "HUNGRY"
	label.Parent = bar
	for _, c in { bar, fill } do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = c
	end
	bar.Parent = sign
	sign.Parent = web
	local function draw()
		fill.Size = UDim2.fromScale(math.clamp(hunger / LabCreatures.SPIDER_FULL, 0, 1), 1)
		label.Text = if os.clock() < napUntil then "FULL: NAPPING" elseif hunger > 60 then "ALMOST FULL" else "HUNGRY"
	end
	draw()
	return function()
		-- (Asleep it does not digest; it wakes up hungry again.)
		if napUntil > 0 and os.clock() >= napUntil then
			napUntil = 0
			hunger = 0
		elseif os.clock() >= napUntil then
			hunger = math.max(0, hunger - LabCreatures.SPIDER_DIGEST * LabCreatures.CHECK)
		end
		draw()
		if m.busy or os.clock() < napUntil then
			return
		end
		local body = look(f, web.CFrame, Vector3.new(24, 24, 7))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			-- Wrapped in silk where it hit, a wiggle, the spider comes down for it.
			local r = rootOf(model)
			local stuck = web.CFrame * CFrame.new(0, -1, -1.5)
			local cocoon = part(f, "Cocoon", Vector3.new(4, 7, 4), stuck, Color3.fromRGB(245, 245, 240), Enum.Material.Fabric, Enum.PartType.Ball)
			table.insert(m.temp, cocoon)
			task.spawn(hold, model, function()
				return stuck
			end, 2.4)
			play(1.2, function(t)
				cocoon.Size = Vector3.new(4, 7, 4) * (0.3 + 0.7 * t)
				cocoon.CFrame = stuck * CFrame.Angles(0, 0, math.sin(t * 30) * 0.15)
				if spider then
					spider:PivotTo(home:Lerp(home * CFrame.new(0, 0, -5.5), t)) -- (down the web to its catch)
				end
			end)
			-- Munch munch (the spider bobs), then the burrito flies.
			play(1.0, function(t)
				cocoon.CFrame = stuck * CFrame.Angles(0, 0, math.sin(t * 40) * 0.25)
				if spider then
					spider:PivotTo(home * CFrame.new(0, 0, -5.5) * CFrame.new(0, math.abs(math.sin(t * 18)) * 1.2, 0))
				end
			end)
			hideBody(model, false)
			local carry = cocoon
			task.spawn(function()
				-- (The cocoon rides along for a moment, then pops.)
				local t0 = os.clock()
				while os.clock() - t0 < 1.6 and r and r.Parent do
					carry.CFrame = r.CFrame
					RunService.Heartbeat:Wait()
				end
				carry:Destroy()
			end)
			if spider then
				task.spawn(play, 0.8, function(t)
					spider:PivotTo((home * CFrame.new(0, 0, -5.5)):Lerp(home, t))
				end)
			end
			hunger += LabCreatures.SPIDER_MEAL
			if hunger >= LabCreatures.SPIDER_FULL then
				napUntil = os.clock() + LabCreatures.SPIDER_NAP
				hunger = LabCreatures.SPIDER_FULL
			end
			draw()
			-- (V6-7 SPIDER DELUXE, bought for this lab: it spits half as far again.)
			local labF = f.Parent and f.Parent.Parent
			local deluxe = labF ~= nil and labF:GetAttribute("SpiderDeluxe") == true
			local away = (web.CFrame.LookVector * -1)
			return (Vector3.new(away.X, 0, away.Z).Unit * 70 + Vector3.new(0, 75, 0)) * (if deluxe then 1.5 else 1)
		end)
	end
end

-- PLANT: chomps a dummy at its feet (a squeeze of the whole plant) and spits it up high.
BUILD.Plant = function(f, at, m)
	local plant = place(f, "MPlant", at.Position, 180, 22)
	local base = if plant then plant:GetPivot() else at
	return function()
		if m.busy then
			return
		end
		local body = look(f, at * CFrame.new(0, 4, 0), Vector3.new(10, 8, 10))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			task.spawn(hold, model, function()
				return base * CFrame.new(0, 14, 0)
			end, 1.6)
			hideBody(model, true)
			play(1.4, function(t)
				if plant then
					-- (A chomping bob and sway: never a rescale each frame.)
					plant:PivotTo(base * CFrame.new(0, math.abs(math.sin(t * math.pi * 4)) * 1.2, 0) * CFrame.Angles(math.sin(t * math.pi * 4) * 0.12, 0, 0))
				end
			end)
			hideBody(model, false)
			return Vector3.new(0, 110, 0) + m.toLab * 30
		end)
	end
end

-- FROG: a pond; the tongue grabs one dummy within reach and pulls it in.
BUILD.Frog = function(f, at, m)
	part(f, "FrogPond", Vector3.new(14, 0.3, 14), at * CFrame.new(0, 0.15, 0), Color3.fromRGB(70, 120, 150), Enum.Material.Glass, Enum.PartType.Cylinder).CFrame = at * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
	local frog = place(f, "MFrog", (at * CFrame.new(0, 0.3, 0)).Position, 180, 9)
	local mouth = (if frog then frog:GetPivot() else at) * CFrame.new(0, 3, -3)
	local nextAt = 0
	return function()
		if m.busy or os.clock() < nextAt then
			return
		end
		local body = look(f, at, Vector3.new(44, 12, 44))[1]
		if not body then
			return
		end
		nextAt = os.clock() + 4
		swallow(m, body, function(model)
			local r = rootOf(model)
			local tongue = part(f, "Tongue", Vector3.new(0.7, 0.7, 1), mouth, Color3.fromRGB(230, 90, 120), Enum.Material.SmoothPlastic)
			table.insert(m.temp, tongue)
			local target = if r then r.Position else mouth.Position
			play(0.25, function(t)
				local tip = mouth.Position:Lerp(target, t)
				tongue.Size = Vector3.new(0.7, 0.7, math.max(1, (tip - mouth.Position).Magnitude))
				tongue.CFrame = CFrame.lookAt((mouth.Position + tip) / 2, tip)
			end)
			task.spawn(hold, model, function()
				local rr = rootOf(model)
				return CFrame.new(if rr then rr.Position:Lerp(mouth.Position, 0.35) else mouth.Position)
			end, 0.6)
			play(0.6, function(t)
				local tip = target:Lerp(mouth.Position, t)
				tongue.Size = Vector3.new(0.7, 0.7, math.max(1, (tip - mouth.Position).Magnitude))
				tongue.CFrame = CFrame.lookAt((mouth.Position + tip) / 2 + Vector3.new(0, 0, 0.01), tip)
			end)
			tongue:Destroy()
			task.wait(0.5)
			return m.toLab * 80 + Vector3.new(0, 55, 0)
		end)
	end
end

-- WHALE: a pool with a whale in it; a dummy in the water goes up the geyser.
BUILD.Whale = function(f, at, m)
	local pool = part(f, "WhalePool", Vector3.new(30, 1, 20), at * CFrame.new(0, 0.3, 0), Color3.fromRGB(50, 120, 170), Enum.Material.Glass)
	pool.Transparency = 0.25
	part(f, "PoolRim", Vector3.new(32, 1.2, 22), at * CFrame.new(0, 0.1, 0), Color3.fromRGB(150, 146, 138), Enum.Material.Cobblestone)
	local whale = place(f, "MWhale", (at * CFrame.new(-4, 0.4, 0)).Position, 90, 26)
	local spout = at * CFrame.new(6, 1, 0)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	emitter.Size = NumberSequence.new(2, 4)
	emitter.Speed = NumberRange.new(60, 80)
	emitter.SpreadAngle = Vector2.new(8, 8)
	emitter.Lifetime = NumberRange.new(0.8, 1.1)
	emitter.Acceleration = Vector3.new(0, -60, 0)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rate = 0
	emitter.Parent = pool
	return function()
		if m.busy then
			return
		end
		local body = look(f, at * CFrame.new(0, 3, 0), Vector3.new(30, 6, 20))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			task.spawn(hold, model, function()
				return spout * CFrame.new(0, 2, 0)
			end, 0.8)
			if whale then
				local base = whale:GetPivot()
				play(0.6, function(t)
					whale:PivotTo(base * CFrame.Angles(0, 0, math.sin(t * math.pi) * 0.12))
				end)
			end
			emitter:Emit(60)
			return Vector3.new(0, 150, 0) + m.toLab * 25 -- (lands beside the pool, not back in it)
		end)
	end
end

-- CHICKEN: a coop; a dummy that walks in is laid as an egg that wobbles, cracks and hatches it.
BUILD.Chicken = function(f, at, m)
	part(f, "Coop", Vector3.new(14, 0.4, 12), at * CFrame.new(0, 0.2, 0), Color3.fromRGB(196, 160, 96), Enum.Material.WoodPlanks)
	local hen = place(f, "MChicken", (at * CFrame.new(0, 0.4, 2)).Position, 180, 9)
	local nest = at * CFrame.new(0, 0, -6)
	part(f, "Nest", Vector3.new(6, 1, 6), nest * CFrame.new(0, 0.5, 0), Color3.fromRGB(205, 180, 110), Enum.Material.Grass, Enum.PartType.Cylinder).CFrame = nest * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	return function()
		if m.busy then
			return
		end
		local body = look(f, at * CFrame.new(0, 4, 2), Vector3.new(14, 8, 10))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			hideBody(model, true)
			task.spawn(hold, model, function()
				return nest * CFrame.new(0, 3, 0)
			end, 2.2)
			if hen then
				local base = hen:GetPivot()
				play(0.6, function(t)
					hen:PivotTo(base * CFrame.new(0, math.abs(math.sin(t * math.pi * 3)) * 1.5, 0))
				end)
			end
			local egg = part(f, "DummyEgg", Vector3.new(4.5, 6, 4.5), nest * CFrame.new(0, 3.5, 0), Color3.fromRGB(250, 246, 236), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			table.insert(m.temp, egg)
			play(1.6, function(t)
				egg.CFrame = nest * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.sin(t * 25) * 0.2 * t)
			end)
			egg:Destroy()
			hideBody(model, false)
			return Vector3.new(0, 70, 0) + m.toLab * 25
		end)
	end
end

-- WASHER: spins a dummy (the machine shakes) and throws it out of the door.
BUILD.Washer = function(f, at, m)
	local washer = place(f, "MWasher", at.Position, 0, 12)
	local base = if washer then washer:GetPivot() else at
	local door = base * CFrame.new(0, 6, -6)
	return function()
		if m.busy then
			return
		end
		local body = look(f, door * CFrame.new(0, -2, -2), Vector3.new(10, 8, 8))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			hideBody(model, true)
			task.spawn(hold, model, function()
				return base * CFrame.new(0, 6, 0)
			end, 2.2)
			play(2.0, function(t)
				if washer then
					washer:PivotTo(base * CFrame.new(math.sin(t * 90) * 0.3, 0, math.cos(t * 70) * 0.3))
				end
			end)
			if washer then
				washer:PivotTo(base)
			end
			hideBody(model, false)
			return m.toLab * 85 + Vector3.new(0, 45, 0)
		end)
	end
end

-- SLINGSHOT: a tree with two bands and a pad; a dummy on the pad is pulled back and fired.
BUILD.Slingshot = function(f, at, m)
	place(f, "TreeRound", (at * CFrame.new(-5, 0, 4)).Position, 0, 20)
	place(f, "TreeRound", (at * CFrame.new(5, 0, 4)).Position, 60, 20)
	local pad = part(f, "SlingPad", Vector3.new(6, 0.4, 6), at * CFrame.new(0, 0.2, 0), Color3.fromRGB(150, 60, 50), Enum.Material.Fabric)
	local left = part(f, "Band", Vector3.new(0.4, 0.4, 1), at, Color3.fromRGB(120, 40, 30), Enum.Material.Fabric)
	local right = part(f, "Band", Vector3.new(0.4, 0.4, 1), at, Color3.fromRGB(120, 40, 30), Enum.Material.Fabric)
	local postL, postR = (at * CFrame.new(-5, 7, 4)).Position, (at * CFrame.new(5, 7, 4)).Position
	local function bands(to: Vector3)
		for _, pair in { { left, postL }, { right, postR } } do
			local b, post = pair[1], pair[2]
			b.Size = Vector3.new(0.4, 0.4, math.max(0.5, (to - post).Magnitude))
			b.CFrame = CFrame.lookAt((to + post) / 2, to)
		end
	end
	bands(pad.Position + Vector3.new(0, 3, 0))
	return function()
		if m.busy then
			return
		end
		local body = look(f, at * CFrame.new(0, 3, 0), Vector3.new(7, 6, 7))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			local from = at * CFrame.new(0, 3, 0)
			local back = at * CFrame.new(0, 4, 9)
			task.spawn(hold, model, function()
				return back
			end, 0.9)
			play(0.8, function(t)
				bands(from.Position:Lerp(back.Position, t))
			end)
			task.delay(0.1, function()
				play(0.15, function(t)
					bands(back.Position:Lerp(from.Position, t))
				end)
			end)
			return at.LookVector * 110 + Vector3.new(0, 60, 0) -- (toward the lab)
		end)
	end
end

-- MOLE: a dirt patch; every few seconds it pops up under one dummy on it and throws it up.
BUILD.Mole = function(f, at, m)
	part(f, "MoleDirt", Vector3.new(20, 0.3, 20), at * CFrame.new(0, 0.15, 0), Color3.fromRGB(110, 82, 58), Enum.Material.Ground)
	for i = 1, 5 do
		local a = i * 1.3
		part(f, "MoleHill", Vector3.new(3, 1.6, 3), at * CFrame.new(math.cos(a) * 6, 0.5, math.sin(a) * 6), Color3.fromRGB(92, 68, 48), Enum.Material.Ground, Enum.PartType.Ball)
	end
	local mole = place(f, "MMole", (at * CFrame.new(0, -6, 0)).Position, 0, 6)
	local nextAt = 0
	return function()
		if m.busy or os.clock() < nextAt then
			return
		end
		local body = look(f, at * CFrame.new(0, 4, 0), Vector3.new(20, 8, 20))[1]
		if not body then
			return
		end
		nextAt = os.clock() + math.random(4, 7)
		swallow(m, body, function(model)
			local r = rootOf(model)
			local under = if r then CFrame.new(r.Position.X, at.Position.Y, r.Position.Z) else at
			if mole then
				play(0.25, function(t)
					mole:PivotTo(under * CFrame.new(0, -5 + 6 * t, 0))
				end)
				task.delay(0.8, function()
					play(0.3, function(t)
						mole:PivotTo(under * CFrame.new(0, 1 - 7 * t, 0))
					end)
				end)
			end
			return Vector3.new(0, 95, 0) + m.toLab * 30 -- (off the patch)
		end)
	end
end

-- VACUUM: drives a loop in the yard's middle, sucks up a dummy it meets, shoots it out behind.
BUILD.Vacuum = function(f, at, m)
	local bot = place(f, "MVacuum", at.Position, 0, 6)
	if not bot then
		return nil
	end
	local angle = 0
	local pos = at.Position
	task.spawn(function()
		while f.Parent do
			if not m.busy and m.owner() then -- (V6-5 review: only in a lab someone owns)
				angle += 0.08
				pos = (at * CFrame.new(math.cos(angle) * 22, 0, math.sin(angle) * 8)).Position
				local ahead = (at * CFrame.new(math.cos(angle + 0.08) * 22, 0, math.sin(angle + 0.08) * 8)).Position
				bot:PivotTo(CFrame.lookAt(pos, Vector3.new(ahead.X, pos.Y, ahead.Z)) + Vector3.new(0, 0.1, 0))
			end
			task.wait(1 / 15) -- (15 steps a second is smooth enough for a slow robot)
		end
	end)
	return function()
		if m.busy then
			return
		end
		local body = look(f, CFrame.new(pos + Vector3.new(0, 3, 0)), Vector3.new(9, 6, 9))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			local here = bot:GetPivot()
			task.spawn(hold, model, function()
				return here * CFrame.new(0, 1.5, 0)
			end, 1.0)
			hideBody(model, true)
			play(0.9, function(t)
				bot:PivotTo(here * CFrame.Angles(0, t * math.pi * 4, 0))
			end)
			hideBody(model, false)
			return m.toLab * 90 + Vector3.new(0, 50, 0)
		end)
	end
end

-- Where each one lives (x, z from the lab's middle). 20 Nov 2026 (the owner: "move the monsters
-- round the lab so they are not all in one place"): the spider and the frog in the west garden, the
-- plant and the chicken in the east garden (between the lab floor and the garden walk, facing the
-- walk), the other five spread across the whole yard in front.
LabCreatures.LAYOUT = table.freeze({
	{ id = "Spider", label = "the SPIDER", x = -90, z = -70, yaw = -90 },
	{ id = "Frog", label = "the FROG", x = -89, z = -5, yaw = -90 },
	{ id = "Plant", label = "the GIANT PLANT", x = 90, z = -70, yaw = 90 },
	{ id = "Chicken", label = "the CHICKEN", x = 90, z = -8, yaw = 90 },
	{ id = "Whale", label = "the WHALE", x = -95, z = 92, yaw = 0 },
	{ id = "Washer", label = "the WASHING MACHINE", x = -47, z = 94, yaw = 180 },
	{ id = "Vacuum", label = "the ROBOT VACUUM", x = 0, z = 88, yaw = 0 },
	{ id = "Mole", label = "the MOLE", x = 47, z = 94, yaw = 0 },
	{ id = "Slingshot", label = "the SLINGSHOT TREE", x = 95, z = 98, yaw = 0 },
})

-- Builds the yard into a lab's Playground folder; a loop per lab checks every trigger.
function LabCreatures.build(into: Instance, origin: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "CreatureYard"
	folder.Parent = into
	local Lab = lazy("Lab")
	local function owner(): Player?
		return Lab.ownerAt(origin + Vector3.new(0, 1, 0))
	end
	-- The yard's ground: soft grass under it all.
	local ground = part(folder, "YardGrass", Vector3.new(250, 0.2, 38), CFrame.new(origin + Vector3.new(0, 0.1, LabCreatures.YARD_Z)), Color3.fromRGB(86, 124, 64), Enum.Material.Grass)
	ground.CanCollide = false
	local ticks: { () -> () } = {}
	for _, spot in LabCreatures.LAYOUT do
		local sub = Instance.new("Folder")
		sub.Name = spot.id
		sub.Parent = folder
		local toLab = Vector3.new(-spot.x, 0, -spot.z)
		local machine: Machine = { id = spot.id, label = spot.label, lab = nil, folder = sub, owner = owner, busy = false, toLab = toLab.Unit, temp = {} }
		local at = CFrame.new(origin + Vector3.new(spot.x, 0, spot.z)) * CFrame.Angles(0, math.rad(spot.yaw), 0)
		local ok, tick = pcall(BUILD[spot.id], sub, at, machine)
		-- (20 Nov: its own little home round it, and its model moves on the screens while it waits.)
		pcall(function()
			lazy("CreatureHabitats").dress(spot.id, sub, at)
		end)
		for _, c in sub:GetChildren() do
			if c:IsA("Model") and string.sub(c.Name, 1, 1) == "M" and c.Name ~= "MVacuum" then
				c:SetAttribute("Creature", spot.id)
				c:SetAttribute("LifeHome", c:GetPivot())
				CollectionService:AddTag(c, "CreatureLife")
			end
		end
		if ok and tick then
			table.insert(ticks, tick)
		elseif not ok then
			warn("[LabCreatures] " .. spot.id .. " failed: " .. tostring(tick))
		end
	end
	task.spawn(function()
		while folder.Parent do
			task.wait(LabCreatures.CHECK)
			-- (Only a lab someone owns plays: an empty lab's yard rests.)
			if owner() then
				for _, tick in ticks do
					local ok, err = pcall(tick)
					if not ok then
						warn("[LabCreatures] " .. tostring(err))
					end
				end
			end
		end
	end)
	return folder
end

return LabCreatures
