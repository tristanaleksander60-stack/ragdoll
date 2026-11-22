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
local Anatomy = require(Shared:WaitForChild("Anatomy")) -- (0.37.11: the spider's bite)
local Config = require(Shared:WaitForChild("Config")) :: any
local Systems = script.Parent

local LabCreatures = {}

local S = Config.LAB_SPREAD or 1 -- (0.37.0: the bigger lab)
LabCreatures.YARD_Z = 92 * S -- the yard's middle line, in front of the lab (z from the lab's origin)
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
	sign.Size = UDim2.fromScale(6, 1.3) -- (studs: a label on the web in the world, not a pixel card at the screen's edge)
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
			-- 0.37.11 / 0.37.12 (owner: "a more realistic kill", then "the ragdoll must not fly up and down, buggy, in
			-- the web; you must see the spider wind round the ragdoll"): the real body is hidden at once and laid on
			-- the ground under the web, and a still copy of it (its pose as it was caught, its face) hangs in the web,
			-- so nothing fights the physics. The spider comes down, bites the neck (blood sprays; the bite bleeds the
			-- real body to death: VitalsService neck wounds), then circles the catch twice, a silk thread from it to
			-- the body, laying band after band of silk from the feet to the head; the bands close into a cocoon, it
			-- is sucked dry (shrinks, goes brown), the spider climbs back, and the cocoon drops where the body lies.
			local stuck = web.CFrame * CFrame.new(0, -1, -1.5)
			local groundY = at.Position.Y + 1.2
			local floorCf = CFrame.new(stuck.Position.X, groundY, stuck.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
			hideBody(model, true)
			pcall(lazy("DummyControl").move, model, floorCf)
			-- The still copy in the web.
			local catch = Instance.new("Model")
			catch.Name = "SpiderCatch"
			local pelvis = model:FindFirstChild("LowerTorso")
			for _, p in model:GetChildren() do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 1 and pelvis and pelvis:IsA("BasePart") then
					local c = Instance.new("Part")
					c.Name = p.Name
					c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch = true, false, false, false
					c.Size = p.Size
					c.Color = p.Color
					c.Material = Enum.Material.SmoothPlastic
					c.CFrame = stuck * pelvis.CFrame:ToObjectSpace(p.CFrame)
					c.Parent = catch
					local face = p:FindFirstChild("Face")
					if face and face:IsA("SurfaceGui") then
						local f2 = face:Clone()
						f2.Enabled = true
						f2.Parent = c
					end
				end
			end
			catch.Parent = f
			table.insert(m.temp, catch)
			local low = home * CFrame.new(0, 0, -5.5)
			if spider then
				play(1.0, function(t)
					spider:PivotTo(home:Lerp(low, t))
				end)
			end
			-- The bite.
			local spray = Instance.new("ParticleEmitter")
			spray.Color = ColorSequence.new(Anatomy.BLOOD)
			spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.15) })
			spray.Speed = NumberRange.new(6, 14)
			spray.SpreadAngle = Vector2.new(50, 50)
			spray.Lifetime = NumberRange.new(0.4, 0.8)
			spray.Acceleration = Vector3.new(0, -40, 0)
			spray.Rate = 0
			local sprayAt = Instance.new("Attachment")
			sprayAt.WorldPosition = (stuck * CFrame.new(0, 2.2, 0)).Position
			sprayAt.Parent = web
			spray.Parent = sprayAt
			table.insert(m.temp, sprayAt)
			local head = model:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				for _ = 1, 2 do
					pcall(lazy("VitalsService").wound, model, head, head.Position, m.owner(), 2.5, { zone = Anatomy.zones.Neck })
				end
			end
			play(0.8, function(t)
				if spider then
					spider:PivotTo(low * CFrame.new(0, math.abs(math.sin(t * 22)) * 0.9, -math.abs(math.sin(t * 22)) * 0.6))
				end
				if math.floor(t * 10) % 3 == 0 then
					spray:Emit(6)
				end
			end)
			-- The wrap: twice round the catch, a band of silk laid each step, feet to head.
			local silk = Color3.fromRGB(245, 245, 240)
			local thread = part(f, "SilkThread", Vector3.new(0.12, 0.12, 1), stuck, silk, Enum.Material.SmoothPlastic)
			table.insert(m.temp, thread)
			local bands: { BasePart } = {}
			local BANDS = 9
			local center = stuck.Position
			play(2.4, function(t)
				local a = t * math.pi * 4
				local y = -3 + 6 * t
				local pos = center + Vector3.new(math.cos(a) * 6.5, y * 0.6, math.sin(a) * 6.5)
				if spider then
					spider:PivotTo(CFrame.lookAt(pos, center + Vector3.new(0, y * 0.6, 0)))
				end
				local tip = center + Vector3.new(0, y * 0.5, 0)
				thread.Size = Vector3.new(0.12, 0.12, (pos - tip).Magnitude)
				thread.CFrame = CFrame.lookAt((pos + tip) / 2, tip)
				while #bands < math.floor(t * BANDS) do
					local k = #bands
					local band = part(f, "SilkBand", Vector3.new(0.6, 3.6, 3.6), stuck * CFrame.new(0, -2.8 + k * 0.7, 0) * CFrame.Angles(0, k * 0.7, math.rad(90)), silk, Enum.Material.Fabric, Enum.PartType.Cylinder)
					band.Transparency = 0.05
					table.insert(bands, band)
					table.insert(m.temp, band)
				end
			end)
			thread:Destroy()
			-- The bands close into a cocoon.
			local cocoon = part(f, "Cocoon", Vector3.new(3.8, 6.6, 3.8), stuck, silk, Enum.Material.Fabric, Enum.PartType.Ball)
			table.insert(m.temp, cocoon)
			play(0.5, function(t)
				cocoon.Size = Vector3.new(3.8, 6.6, 3.8) * (0.85 + 0.15 * t) + Vector3.new(0.4, 0.8, 0.4) * t
			end)
			for _, b in bands do
				b:Destroy()
			end
			catch:Destroy()
			-- Sucked dry: the spider on top, bobbing; the cocoon shrinks and goes brown.
			local brown = Color3.fromRGB(150, 128, 96)
			local full = cocoon.Size
			if spider then
				spider:PivotTo(low)
			end
			play(1.4, function(t)
				cocoon.Size = full * (1 - 0.2 * t)
				cocoon.Color = silk:Lerp(brown, t)
				if spider then
					spider:PivotTo(low * CFrame.new(0, math.abs(math.sin(t * 9)) * 0.5, 0))
				end
			end)
			if spider then
				task.spawn(play, 0.9, function(t)
					spider:PivotTo(low:Lerp(home, t))
				end)
			end
			-- The cocoon drops onto the body on the ground.
			local dropTo = CFrame.new(stuck.Position.X, groundY, stuck.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
			play(0.45, function(t)
				cocoon.CFrame = stuck:Lerp(dropTo, t * t)
			end)
			pcall(lazy("DummyControl").move, model, floorCf)
			hideBody(model, false)
			task.delay(2.5, function()
				if cocoon.Parent then
					cocoon:Destroy()
				end
			end)
			sprayAt:Destroy()
			hunger += LabCreatures.SPIDER_MEAL
			if hunger >= LabCreatures.SPIDER_FULL then
				napUntil = os.clock() + LabCreatures.SPIDER_NAP
				hunger = LabCreatures.SPIDER_FULL
			end
			draw()
			-- (V6-7 SPIDER DELUXE, bought for this lab: it spits half as far again.)
			local labF = f.Parent and f.Parent.Parent
			local deluxe = labF ~= nil and labF:GetAttribute("SpiderDeluxe") == true
			-- (21 Nov: towards the middle of the lab. Away from the web's face it spat into the west
			-- garden's hedge after the move; the body stuck 12 studs off, slid back and was caught again.)
			local away = m.toLab
			local _ = deluxe and away -- (0.37.11: no throw any more; the dead body stays where the cocoon dropped)
			return Vector3.new(0, 4, 0)
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

-- SHARK TANK (session v847, owner: "udskift experimenter i ens lab"): the old whale pool was a quiet blue
-- rectangle with a smoke geyser; the ragdoll gameplay is ragdoll CHAOS, so the station is now a shark tank.
-- The id "Whale" is kept so saved progress on the Whale card is not lost — a player who had it part-done gets
-- credit when a dummy goes in the tank. The text on the card and the label in the lab guide read "SHARK TANK".
BUILD.Whale = function(f, at, m)
	-- The tank: a deeper, darker glass pool with a pale sand floor so the dark shark reads against it.
	part(f, "SharkTankFloor", Vector3.new(30, 0.4, 20), at * CFrame.new(0, 0.05, 0), Color3.fromRGB(220, 200, 150), Enum.Material.Sand)
	local pool = part(f, "SharkTankWater", Vector3.new(30, 1, 20), at * CFrame.new(0, 0.5, 0), Color3.fromRGB(30, 90, 140), Enum.Material.Glass)
	pool.Transparency = 0.3
	part(f, "TankRim", Vector3.new(32, 1.2, 22), at * CFrame.new(0, 0.1, 0), Color3.fromRGB(140, 134, 125), Enum.Material.Cobblestone)
	-- The shark itself: big, placed in the middle of the tank, facing along X so its length sweeps the pool.
	local shark = place(f, "MShark", (at * CFrame.new(0, 0.6, 0)).Position, 90, 24)
	local basePivot = shark and shark:GetPivot()
	-- A red mist burst when the tank eats (replaces the whale's clean white spout).
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxasset://textures/particles/smoke_main.dds"
	burst.Color = ColorSequence.new(Color3.fromRGB(200, 40, 40))
	burst.Size = NumberSequence.new(1.5, 3)
	burst.Speed = NumberRange.new(12, 20)
	burst.SpreadAngle = Vector2.new(60, 60)
	burst.Lifetime = NumberRange.new(0.5, 0.9)
	burst.EmissionDirection = Enum.NormalId.Top
	burst.Rate = 0
	burst.Parent = pool
	return function()
		if m.busy then
			return
		end
		local body = look(f, at * CFrame.new(0, 3, 0), Vector3.new(30, 6, 20))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			-- 0.37.11 (owner: "the shark takes the ragdoll under the water, the water goes red, then it spits out
			-- bones with meat on"): a beat over the water, the lunge, the body pulled under (hidden), the shark
			-- thrashes while the water turns red, then it spits bones with meat on them out of the tank, and the
			-- body comes up last, missing a piece or two. The water clears again after a while.
			task.spawn(hold, model, function()
				return at * CFrame.new(0, 2.5, 0)
			end, 0.5)
			task.wait(0.5)
			task.spawn(hold, model, function()
				return at * CFrame.new(0, 0.3, 0)
			end, 2.6)
			hideBody(model, true)
			burst:Emit(30)
			local TweenService = game:GetService("TweenService")
			local blue = pool.Color
			local red = Color3.fromRGB(150, 18, 24)
			TweenService:Create(pool, TweenInfo.new(0.9), { Color = red, Transparency = 0.15 }):Play()
			if shark and basePivot then
				play(1.8, function(t)
					local roll = math.sin(t * math.pi * 6) * 0.45
					local lift = math.abs(math.sin(t * math.pi * 3)) * 0.9
					shark:PivotTo(basePivot * CFrame.new(math.sin(t * 9) * 1.5, lift, 0) * CFrame.Angles(0, math.sin(t * 7) * 0.4, roll))
				end)
				shark:PivotTo(basePivot)
			else
				task.wait(1.8)
			end
			burst:Emit(30)
			-- The spit: bones with meat on, out of the tank and onto the floor round it.
			local mouth = (at * CFrame.new(0, 2, 0)).Position
			for i = 1, 7 do
				local chunk = Instance.new("Model")
				chunk.Name = "SharkScraps"
				local len = 1.6 + math.random() * 1.4
				local bone = Instance.new("Part")
				bone.Name = "Bone"
				bone.Shape = Enum.PartType.Cylinder
				bone.Size = Vector3.new(len, 0.35, 0.35)
				bone.Color = Color3.fromRGB(236, 228, 208)
				bone.Material = Enum.Material.SmoothPlastic
				bone.CFrame = CFrame.new(mouth) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				bone.CanTouch = false
				bone.Parent = chunk
				for _, endX in { -len / 2, len / 2 } do
					local knob = Instance.new("Part")
					knob.Shape = Enum.PartType.Ball
					knob.Size = Vector3.one * 0.6
					knob.Color = bone.Color
					knob.Material = Enum.Material.SmoothPlastic
					knob.CanCollide = false
					knob.CanTouch = false
					knob.Massless = true
					knob.CFrame = bone.CFrame * CFrame.new(endX, 0, 0)
					local w = Instance.new("WeldConstraint")
					w.Part0, w.Part1 = bone, knob
					w.Parent = knob
					knob.Parent = chunk
				end
				local meat = Instance.new("Part")
				meat.Name = "Meat"
				meat.Shape = Enum.PartType.Ball
				meat.Size = Vector3.new(1.1, 1.1, 1.1) * (0.8 + math.random() * 0.5)
				meat.Color = Color3.fromRGB(150 + math.random(0, 30), 30, 40)
				meat.Material = Enum.Material.SmoothPlastic
				meat.CanCollide = false
				meat.CanTouch = false
				meat.Massless = true
				meat.CFrame = bone.CFrame * CFrame.new((math.random() - 0.5) * len * 0.6, 0.15, 0)
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = bone, meat
				w.Parent = meat
				meat.Parent = chunk
				chunk.PrimaryPart = bone
				chunk.Parent = f
				local a = math.random() * math.pi * 2
				bone.AssemblyLinearVelocity = Vector3.new(math.cos(a) * (18 + math.random() * 14), 45 + math.random() * 20, math.sin(a) * (18 + math.random() * 14))
				bone.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
				game:GetService("Debris"):AddItem(chunk, 12)
				task.wait(0.08)
			end
			-- The body comes up last, a piece or two short.
			for _ = 1, math.random(1, 2) do
				local pieces = { "LeftArm", "RightArm", "LeftLeg", "RightLeg", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }
				pcall(lazy("VitalsService").sever, model, pieces[math.random(#pieces)], mouth)
			end
			task.delay(4, function()
				TweenService:Create(pool, TweenInfo.new(3), { Color = blue, Transparency = 0.3 }):Play()
			end)
			return Vector3.new(0, 120, 0) + m.toLab * 30 -- (spat out beside the tank, not back in it)
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
	{ id = "Spider", label = "the SPIDER", x = 0, z = -60 * S, yaw = 180 }, -- (0.37.3, owner: "the spider where the black mat was, right in front of the spawn: the first thing you see")
	{ id = "Frog", label = "the FROG", x = (if (Config :: any).LAYOUT_V3 then -81 else -89) * S, z = -5 * S, yaw = -90 }, -- (V9-0d: its pond off the west garden walk)
	{ id = "Plant", label = "the GIANT PLANT", x = 90 * S, z = -70 * S, yaw = 90 },
	{ id = "Chicken", label = "the CHICKEN", x = 90 * S, z = -8 * S, yaw = 90 },
	-- (session v849, owner: "ryk rundt på tingene så de står psykologisk bedst"): the shark tank is new,
	-- premium content; it moved from the far west yard corner (-95, 92) up and in to (-55, 70) so a
	-- player standing at the west side of the lab core SEES it, a clear wow hook on the way back.
	{ id = "Whale", label = "the SHARK TANK", x = -41 * S, z = 50 * S, yaw = 0 }, -- (0.37.8, owner: on the spinning mace's old spot) -- (session v847: shark swap, id kept for saved progress; session v849: moved forward)
	{ id = "Washer", label = "the WASHING MACHINE", x = -47 * S, z = 94 * S, yaw = 180 },
	{ id = "Vacuum", label = "the ROBOT VACUUM", x = 0 * S, z = 88 * S, yaw = 0 },
	{ id = "Mole", label = "the MOLE", x = 47 * S, z = 94 * S, yaw = 0 },
	{ id = "Slingshot", label = "the SLINGSHOT TREE", x = 95 * S, z = 98 * S, yaw = 0 },
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
	local ground = part(folder, "YardGrass", Vector3.new(250 * S, 0.2, 38), CFrame.new(origin + Vector3.new(0, 0.1, LabCreatures.YARD_Z)), Color3.fromRGB(86, 124, 64), Enum.Material.Grass)
	ground.CanCollide = false
	local ticks: { () -> () } = {}
	for _, spot in LabCreatures.LAYOUT do
		-- (Owner, 21 Nov 2026: "a COMPRESSOR instead of the robot vacuum": the press stands on the vacuum's spot.)
		if spot.id == "Vacuum" and (Config :: any).COMPRESSOR then
			local okC, errC = pcall(function()
				lazy("Compressor").build(folder, origin, origin + Vector3.new(spot.x, 0, spot.z))
			end)
			if not okC then
				warn("[LabCreatures] Compressor failed: " .. tostring(errC))
			end
			continue
		end
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
