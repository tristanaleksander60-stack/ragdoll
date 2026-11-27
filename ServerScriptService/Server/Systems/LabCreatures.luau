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
local LabLayout10 = require(Shared:WaitForChild("LabLayout10")) :: any
-- BODY_V2 0 (owner, 26 Nov 2026: gore off, Config.GORE): no bones, meat or red anywhere in the creatures; what was red is
-- the purple cartoon juice, bones become a burst of gold stars, the water never turns red.
local GORE = Config.GORE ~= false
local PURPLE = Color3.fromRGB(150, 70, 200)
local function mild(c: Color3): Color3
	if GORE then
		return c
	end
	return if c.R > 0.45 and c.G < 0.3 and c.B < 0.3 then PURPLE else c
end
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
		-- (V10 phase 2, owner: "takedowns when ragdolls are pressed, fed to the shark and so on": one each.)
		pcall(function()
			lazy("ProgressService").addTakedowns(p, 1)
		end)
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
	-- (23 Nov 2026, owner: "no hit card for ragdolls I did not give it myself": held or sent in by a player just now.)
	model:SetAttribute("Fed", os.clock() - ((model:GetAttribute("GivenAt") :: number?) or -100) < 12)
	task.spawn(function()
		local ok, err = pcall(function()
			local out = inside(model)
			-- (V10 phase 3, owner: "every animal at least as violent as the shark"): what comes out of any creature
			-- but the spider and the shark (they have their own) is a piece or two short and bleeding.
			if m.id ~= "Spider" and m.id ~= "Whale" then
				local V = lazy("VitalsService")
				local pieces = { "LeftArm", "RightArm", "LeftLeg", "RightLeg", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }
				for _ = 1, math.random(1, 2) do
					pcall(V.sever, model, pieces[math.random(#pieces)], nil)
				end
				local head = model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					pcall(V.wound, model, head, head.Position, m.owner(), 2, { zone = Anatomy.zones.Neck })
				end
			end
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
-- Phase D helpers (23 Nov 2026): a one-off burst of particles, bones that fly, and a little block ragdoll (a stand-in
-- seen spinning in the washer or hatching from the egg while the real body is hidden).

local function spray(f: Instance, at: Vector3, colors: { Color3 }, n: number, speed: number, size: number, dir: Vector3?)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one * 0.2
	p.CFrame = if dir and dir.Magnitude > 0.01 then CFrame.lookAt(at, at + dir) else CFrame.new(at)
	p.Parent = f
	local e = Instance.new("ParticleEmitter")
	local keys = {}
	for i, c in colors do
		table.insert(keys, ColorSequenceKeypoint.new(if #colors == 1 then 0 else (i - 1) / (#colors - 1), c))
	end
	if #keys == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, colors[1]))
	end
	for k, key in keys do
		keys[k] = ColorSequenceKeypoint.new(key.Time, mild(key.Value))
	end
	e.Color = ColorSequence.new(keys)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.3) })
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = if dir then Vector2.new(35, 35) else Vector2.new(180, 180)
	e.EmissionDirection = Enum.NormalId.Front
	e.Acceleration = Vector3.new(0, -40, 0)
	e.Lifetime = NumberRange.new(0.5, 1)
	e.Rate = 0
	e.Parent = p
	e:Emit(n)
	game:GetService("Debris"):AddItem(p, 2)
end

local function bones(f: Instance, at: Vector3, dir: Vector3, n: number)
	if not GORE then
		spray(f, at, { Color3.fromRGB(255, 215, 60), Color3.fromRGB(255, 255, 255) }, n * 4, 18, 0.6, dir)
		return
	end
	for i = 1, n do
		local bone = Instance.new("Part")
		bone.Name = "Bone"
		bone.Size = if i % 3 == 0 then Vector3.one * 0.55 else Vector3.new(0.25, 0.25, 1.1)
		bone.Shape = if i % 3 == 0 then Enum.PartType.Ball else Enum.PartType.Block
		bone.Color = Color3.fromRGB(236, 228, 208)
		bone.Material = Enum.Material.SmoothPlastic
		bone.CFrame = CFrame.new(at) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		bone.CanQuery, bone.CanTouch = false, false
		bone.Parent = f
		bone.AssemblyLinearVelocity = dir * math.random(14, 26) + Vector3.new(math.random(-8, 8), math.random(10, 20), math.random(-8, 8))
		game:GetService("Debris"):AddItem(bone, 6)
	end
end

type Puppet = { parts: { [string]: Part }, set: (CFrame, number) -> (), remove: () -> () }
local function puppet(f: Instance, scale: number): Puppet
	local parts: { [string]: Part } = {}
	local white = Color3.fromRGB(226, 226, 222)
	local function piece(name: string, size: Vector3, shape: Enum.PartType?)
		local p = Instance.new("Part")
		p.Name = "Puppet" .. name
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Size = size * scale
		p.Color = white
		p.Material = Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.Parent = f
		parts[name] = p
	end
	piece("Torso", Vector3.new(2, 2, 1))
	piece("Head", Vector3.one * 1.2, Enum.PartType.Ball)
	piece("LA", Vector3.new(0.8, 2, 0.8))
	piece("RA", Vector3.new(0.8, 2, 0.8))
	piece("LL", Vector3.new(0.9, 2, 0.9))
	piece("RL", Vector3.new(0.9, 2, 0.9))
	local function set(root: CFrame, t: number)
		local s = scale
		local flail = math.sin(t * 12)
		parts.Torso.CFrame = root
		parts.Head.CFrame = root * CFrame.new(0, 1.65 * s, 0)
		parts.LA.CFrame = root * CFrame.new(-1.4 * s, 0.9 * s, 0) * CFrame.Angles(flail, 0, 0) * CFrame.new(0, -0.9 * s, 0)
		parts.RA.CFrame = root * CFrame.new(1.4 * s, 0.9 * s, 0) * CFrame.Angles(-flail, 0, 0) * CFrame.new(0, -0.9 * s, 0)
		parts.LL.CFrame = root * CFrame.new(-0.5 * s, -1 * s, 0) * CFrame.Angles(-flail * 0.7, 0, 0) * CFrame.new(0, -1 * s, 0)
		parts.RL.CFrame = root * CFrame.new(0.5 * s, -1 * s, 0) * CFrame.Angles(flail * 0.7, 0, 0) * CFrame.new(0, -1 * s, 0)
	end
	local function remove()
		for _, p in parts do
			p:Destroy()
		end
	end
	return { parts = parts, set = set, remove = remove }
end

------------------------------------------------------------------------------------------------
-- The creatures

local BUILD: { [string]: (Folder, CFrame, Machine) -> ((() -> ())?) } = {}

-- SPIDER: a web in the yard's east corner; hunger meter on a small sign.
-- 3.13 SPIDER (docs/MACHINES_10.md; Config.SPIDER_10): the cocoon that drops stays 10 s and can be SHOT open: it bursts
-- in white silk, the body inside comes out with web strands on it for 8 s and "FREED!" pops.
local cocoons: { [BasePart]: { model: Model } } = {}
local cocoonListener = false
local function freeCocoon(c: BasePart)
	local entry = cocoons[c]
	cocoons[c] = nil
	if not entry or not c.Parent then
		return
	end
	local at = c.Position
	spray(c.Parent :: Instance, at, { Color3.fromRGB(250, 250, 255), Color3.fromRGB(230, 230, 240) }, 40, 16, 0.8, Vector3.new(0, 1, 0))
	c:Destroy()
	local model = entry.model
	if model.Parent then
		for _, name in { "LeftUpperArm", "RightUpperArm", "UpperTorso", "LeftUpperLeg", "RightLowerLeg" } do
			local limb = model:FindFirstChild(name)
			if limb and limb:IsA("BasePart") then
				local strand = Instance.new("Part")
				strand.Name = "WebStrand"
				strand.Size = Vector3.new(0.08, limb.Size.Y * 1.1, 0.08)
				strand.Color = Color3.fromRGB(245, 245, 250)
				strand.Material = Enum.Material.Neon
				strand.Transparency = 0.3
				strand.Massless, strand.CanCollide, strand.CanQuery, strand.CanTouch = true, false, false, false
				strand.CFrame = limb.CFrame * CFrame.new(limb.Size.X * 0.45, 0, 0) * CFrame.Angles(0, 0, math.rad(math.random(-30, 30)))
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = limb, strand
				w.Parent = strand
				strand.Parent = limb
				game:GetService("Debris"):AddItem(strand, 8)
			end
		end
		pcall(lazy("DummyControl").push, model, Vector3.new(0, 30, 0))
	end
	pcall(function()
		lazy("Playground").pop(at + Vector3.new(0, 4, 0), "FREED!", Color3.fromRGB(240, 240, 255))
	end)
end

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
	sign.Enabled = false -- (24 Nov 2026, owner: no signs over the creatures)
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
			local keep = if (Config :: any).SPIDER_10 then 10 else 2.5
			if (Config :: any).SPIDER_10 then
				cocoon.CanQuery = true
				cocoons[cocoon] = { model = model }
				if not cocoonListener then
					cocoonListener = true
					table.insert(lazy("Knockables").listeners, {
						shot = function(point: Vector3, _from: Vector3)
							for c in cocoons do
								if c.Parent and (c.Position - point).Magnitude < math.max(c.Size.X, c.Size.Y) * 0.6 + 0.5 then
									freeCocoon(c)
								end
							end
						end,
						blast = function(center: Vector3, radius: number)
							for c in cocoons do
								if c.Parent and (c.Position - center).Magnitude < radius + 2 then
									freeCocoon(c)
								end
							end
						end,
						reset = function() end,
					})
				end
			end
			task.delay(keep, function()
				cocoons[cocoon] = nil
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
	-- (Phase D, 23 Nov 2026): the plant lunges down over the body and two big jaws (green, red inside, white
	-- teeth) snap shut on it; it chews, juice and blood drip from the jaws, then it rears back and spits the bones
	-- out before the body is flung up and away.
	local head = base * CFrame.new(0, 14, 0)
	local green = Color3.fromRGB(70, 140, 60)
	local function jaw(name: string): (Part, { Part })
		local j = part(f, name, Vector3.new(6, 0.8, 5), head, green, Enum.Material.SmoothPlastic)
		local inner = part(f, name .. "Mouth", Vector3.new(5.4, 0.2, 4.4), head, Color3.fromRGB(170, 30, 40), Enum.Material.SmoothPlastic)
		local teeth = { inner }
		for i = -2, 2 do
			local tooth = part(f, name .. "Tooth", Vector3.new(0.35, 0.8, 0.35), head, Color3.fromRGB(245, 242, 230), Enum.Material.SmoothPlastic)
			tooth:SetAttribute("X", i * 1.1)
			table.insert(teeth, tooth)
		end
		return j, teeth
	end
	local upper, upperBits = jaw("JawTop")
	local lower, lowerBits = jaw("JawBottom")
	local function setJaws(at0: CFrame, open: number)
		-- open: 0 shut, 1 wide (75 degrees each way, hinged at the back edge)
		local a = math.rad(75 * open)
		local hingeTop = at0 * CFrame.new(0, 0.5, 2.5) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, -2.5)
		local hingeBot = at0 * CFrame.new(0, -0.5, 2.5) * CFrame.Angles(-a, 0, 0) * CFrame.new(0, 0, -2.5)
		upper.CFrame = hingeTop
		lower.CFrame = hingeBot
		for i, b in upperBits do
			b.CFrame = if i == 1 then hingeTop * CFrame.new(0, -0.45, 0) else hingeTop * CFrame.new(b:GetAttribute("X") :: number, -0.75, -2.1) * CFrame.Angles(math.rad(180), 0, 0)
		end
		for i, b in lowerBits do
			b.CFrame = if i == 1 then hingeBot * CFrame.new(0, 0.45, 0) else hingeBot * CFrame.new(b:GetAttribute("X") :: number, 0.75, -2.1)
		end
	end
	setJaws(head, 0.35)
	return function()
		if m.busy then
			return
		end
		local body = look(f, at * CFrame.new(0, 4, 0), Vector3.new(10, 8, 10))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			local r = rootOf(model)
			local down = CFrame.new((r and r.Position or at.Position) + Vector3.new(0, 2.5, 0)) * head.Rotation
			-- Lunge down, jaws wide; snap.
			play(0.25, function(t)
				setJaws(head:Lerp(down, t), 0.35 + 0.65 * t)
				if plant then
					plant:PivotTo(base * CFrame.new(0, -1.5 * t, 0) * CFrame.Angles(math.rad(15) * t, 0, 0))
				end
			end)
			play(0.08, function(t)
				setJaws(down, 1 - t)
			end)
			lazy("FxService").hit(down.Position, 90, "Punch")
			spray(f, down.Position, { Color3.fromRGB(150, 18, 24) }, 25, 14, 0.5)
			hideBody(model, true)
			task.spawn(hold, model, function()
				return head * CFrame.new(0, -1, 0)
			end, 3)
			if (Config :: any).PLANT_10 then
				-- 3.15 PLANT (Config.PLANT_10): a cartoon munch: yellow stars spin out of its jaws while it chews, "MUNCH!"
				local starAt = Instance.new("Part")
				starAt.Anchored, starAt.CanCollide, starAt.CanQuery, starAt.CanTouch, starAt.Transparency = true, false, false, false, 1
				starAt.Size = Vector3.one * 0.2
				starAt.CFrame = head
				starAt.Parent = f
				local st = Instance.new("ParticleEmitter")
				st.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				st.Color = ColorSequence.new(Color3.fromRGB(255, 225, 70))
				st.LightEmission = 0.6
				st.Size = NumberSequence.new(0.8, 0.3)
				st.Speed = NumberRange.new(5, 9)
				st.SpreadAngle = Vector2.new(70, 70)
				st.RotSpeed = NumberRange.new(-200, 200)
				st.Lifetime = NumberRange.new(0.6, 1)
				st.Rate = 14
				st.Parent = starAt
				game:GetService("Debris"):AddItem(starAt, 2.2)
				task.delay(1.9, function()
					st.Enabled = false
				end)
				pcall(function()
					lazy("Playground").pop(head.Position + Vector3.new(0, 4, 0), "MUNCH!", Color3.fromRGB(170, 230, 90))
				end)
			end
			-- Back up and chew, juice and blood dripping.
			play(0.3, function(t)
				setJaws(down:Lerp(head, t), 0)
				if plant then
					plant:PivotTo(base * CFrame.new(0, -1.5 * (1 - t), 0) * CFrame.Angles(math.rad(15) * (1 - t), 0, 0))
				end
			end)
			play(1.6, function(t)
				local chew = math.abs(math.sin(t * math.pi * 6))
				setJaws(head * CFrame.new(0, math.sin(t * 20) * 0.2, 0), chew * 0.25)
				if math.floor(t * 12) ~= math.floor((t - 0.02) * 12) then
					spray(f, (head * CFrame.new(0, -1, -2)).Position, { Color3.fromRGB(140, 200, 60), Color3.fromRGB(150, 18, 24) }, 6, 4, 0.35, Vector3.new(0, -1, 0))
				end
				if plant then
					plant:PivotTo(base * CFrame.Angles(math.sin(t * math.pi * 6) * 0.06, 0, math.sin(t * 7) * 0.05))
				end
			end)
			-- Rear back and spit the bones, then the body.
			play(0.2, function(t)
				setJaws(head * CFrame.Angles(math.rad(-25) * t, 0, 0), t)
				if plant then
					plant:PivotTo(base * CFrame.Angles(math.rad(-10) * t, 0, 0))
				end
			end)
			bones(f, (head * CFrame.new(0, 0, -3)).Position, head.LookVector, 7)
			spray(f, (head * CFrame.new(0, 0, -3)).Position, { Color3.fromRGB(140, 200, 60) }, 25, 18, 0.5, head.LookVector)
			play(0.4, function(t)
				setJaws(head, 1 - 0.65 * t)
				if plant then
					plant:PivotTo(base * CFrame.Angles(math.rad(-10) * (1 - t), 0, 0))
				end
			end)
			if plant then
				plant:PivotTo(base)
			end
			hideBody(model, false)
			return Vector3.new(0, 110, 0) + m.toLab * 30
		end)
	end
end

-- FROG: a pond; the tongue grabs one dummy within reach and pulls it in.
BUILD.Frog = function(f, at, m)
	part(f, "FrogPond", Vector3.new(14, 0.3, 14), at * CFrame.new(0, 0.15, 0), Color3.fromRGB(70, 120, 150), Enum.Material.Glass, Enum.PartType.Cylinder).CFrame = at * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
	local frog = place(f, "MFrog", (at * CFrame.new(0, 0.3, 0)).Position, 180, 9)
	local home = if frog then frog:GetPivot() else at
	-- (Phase D, 23 Nov 2026, owner: "make the frog, the chicken, the shark, the washer... more realistic and fun"):
	-- the frog turns to its catch, puffs its throat, shoots a thick sticky tongue with a ball on the end, reels the
	-- body in and gulps it; a lump slides down its throat into the belly, which bulges and kicks while it digests;
	-- then it rears up and burps: green slime, a spray of bones, and the body comes flying out a piece short.
	local skin = Color3.fromRGB(90, 160, 70)
	if frog then
		local biggest = 0
		for _, d in frog:GetDescendants() do
			if d:IsA("BasePart") and d.Size.Magnitude > biggest then
				biggest = d.Size.Magnitude
				skin = d.Color
			end
		end
	end
	local nextAt = 0
	local function setFrog(cf: CFrame)
		if frog then
			frog:PivotTo(cf)
		end
	end
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
			local target = if r then r.Position else (home * CFrame.new(0, 3, -6)).Position
			-- Turn to it, and crouch.
			local flat = Vector3.new(target.X, home.Position.Y, target.Z)
			local facing = if (flat - home.Position).Magnitude > 0.5 then CFrame.lookAt(home.Position, flat) else home
			play(0.22, function(t)
				setFrog(home:Lerp(facing, t) * CFrame.new(0, -0.4 * t, 0))
			end)
			local mouth = facing * CFrame.new(0, 3, -3)
			-- The throat puffs.
			local throat = part(f, "FrogThroat", Vector3.new(1.6, 1.6, 1.6), mouth * CFrame.new(0, -1, 0.6), skin:Lerp(Color3.new(1, 1, 0.85), 0.35), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			table.insert(m.temp, throat)
			play(0.18, function(t)
				throat.Size = Vector3.one * (1.6 + math.sin(t * math.pi) * 1.4)
			end)
			-- The tongue: thick, pink, a sticky ball on the end; out fast, a little wobble.
			local tongue = part(f, "Tongue", Vector3.new(0.9, 0.55, 1), mouth, Color3.fromRGB(225, 85, 115), Enum.Material.SmoothPlastic)
			local tip = part(f, "TongueTip", Vector3.one * 1.3, mouth, Color3.fromRGB(240, 110, 140), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			table.insert(m.temp, tongue)
			table.insert(m.temp, tip)
			local function stretch(to: Vector3, wob: number)
				local from = mouth.Position
				local len = math.max(1, (to - from).Magnitude)
				tongue.Size = Vector3.new(0.9, 0.55, len)
				tongue.CFrame = CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(0, 0, wob)
				tip.CFrame = CFrame.new(to)
			end
			play(0.16, function(t)
				stretch(mouth.Position:Lerp(target, t), math.sin(t * 20) * 0.15)
			end)
			lazy("FxService").hit(target, 40, "Punch")
			if (Config :: any).FROG_10 then
				-- 3.14 FROG (Config.FROG_10): the tongue length is the score, with a NEW BEST for the lab's owner (FrogBest)
				local reach = math.floor((target - mouth.Position).Magnitude + 0.5)
				local text = "TONGUE " .. tostring(reach) .. " studs!"
				local okO, owner = pcall(function()
					return lazy("Lab").ownerAt(mouth.Position)
				end)
				if okO and owner then
					local best = (owner:GetAttribute("FrogBest") :: number?) or 0
					if reach > best then
						owner:SetAttribute("FrogBest", reach)
						text ..= " NEW BEST!"
					end
				end
				pcall(function()
					lazy("Playground").pop(target + Vector3.new(0, 3, 0), text, Color3.fromRGB(160, 230, 90))
				end)
			end
			-- Reel it in: the body stuck to the tip.
			task.spawn(hold, model, function()
				return CFrame.new(tip.Position)
			end, 0.45)
			play(0.45, function(t)
				stretch(target:Lerp(mouth.Position, t * t), math.sin(t * 14) * 0.1)
			end)
			tongue:Destroy()
			tip:Destroy()
			-- Gulp: the body is inside; the frog snaps shut and the throat swells.
			hideBody(model, true)
			task.spawn(hold, model, function()
				return facing * CFrame.new(0, 1.5, 0)
			end, 3)
			play(0.2, function(t)
				setFrog(facing * CFrame.new(0, -0.4 + math.sin(t * math.pi) * 0.6, 0))
				throat.Size = Vector3.one * (1.6 + math.sin(t * math.pi) * 2)
			end)
			throat:Destroy()
			-- A lump down the throat, into a belly that bulges and kicks.
			local lump = part(f, "FrogLump", Vector3.one * 1.8, mouth * CFrame.new(0, -0.6, 0.4), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			table.insert(m.temp, lump)
			local belly = facing * CFrame.new(0, 1.4, 0.6)
			play(0.6, function(t)
				lump.CFrame = (mouth * CFrame.new(0, -0.6, 0.4)):Lerp(belly, t)
				lump.Size = Vector3.one * (1.8 + t * 1.6)
			end)
			play(1.5, function(t)
				local kick = math.abs(math.sin(t * 22)) * 0.5
				lump.CFrame = belly * CFrame.new(math.sin(t * 17) * 0.3, kick * 0.4, math.cos(t * 13) * 0.3)
				lump.Size = Vector3.one * (3.4 + kick)
				setFrog(facing * CFrame.new(0, -0.4 + kick * 0.15, 0) * CFrame.Angles(0, 0, math.sin(t * 9) * 0.04))
			end)
			-- The burp: it rears, green slime and bones fly out, then the body.
			play(0.25, function(t)
				setFrog(facing * CFrame.new(0, -0.4 + t * 0.9, 0) * CFrame.Angles(math.rad(-18 * t), 0, 0))
				lump.Size = Vector3.one * (3.4 - t * 3)
			end)
			lump:Destroy()
			local spit = (facing * CFrame.new(0, 3.2, -3.2)).Position
			local slime = Instance.new("Part")
			slime.Anchored, slime.CanCollide, slime.CanQuery, slime.CanTouch, slime.Transparency = true, false, false, false, 1
			slime.Position = spit
			slime.Parent = f
			local e = Instance.new("ParticleEmitter")
			e.Color = ColorSequence.new(Color3.fromRGB(150, 220, 70), Color3.fromRGB(90, 160, 40))
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2) })
			e.Speed = NumberRange.new(12, 22)
			e.SpreadAngle = Vector2.new(35, 35)
			e.EmissionDirection = Enum.NormalId.Front
			e.Acceleration = Vector3.new(0, -40, 0)
			e.Lifetime = NumberRange.new(0.6, 1)
			e.Rate = 0
			e.Parent = slime
			slime.CFrame = CFrame.lookAt(spit, spit + facing.LookVector + Vector3.new(0, 0.4, 0))
			e:Emit(45)
			game:GetService("Debris"):AddItem(slime, 2)
			for i = 1, 6 do
				local bone = Instance.new("Part")
				bone.Name = "Bone"
				bone.Size = if i % 3 == 0 then Vector3.one * 0.55 else Vector3.new(0.25, 0.25, 1.1)
				bone.Shape = if i % 3 == 0 then Enum.PartType.Ball else Enum.PartType.Block
				bone.Color = Color3.fromRGB(236, 228, 208)
				bone.Material = Enum.Material.SmoothPlastic
				bone.CFrame = CFrame.new(spit) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				bone.CanQuery, bone.CanTouch = false, false
				bone.Parent = f
				bone.AssemblyLinearVelocity = facing.LookVector * math.random(14, 26) + Vector3.new(math.random(-8, 8), math.random(10, 20), math.random(-8, 8))
				game:GetService("Debris"):AddItem(bone, 6)
			end
			lazy("FxService").hit(spit, 120, "CannonPad")
			play(0.3, function(t)
				setFrog(facing:Lerp(home, t))
			end)
			setFrog(home)
			if model.Parent then
				lazy("DummyControl").move(model, CFrame.new(spit))
				if (Config :: any).FROG_10 then
					-- covered in green slime: drips off it for 5 s
					local torso = model:FindFirstChild("UpperTorso")
					if torso and torso:IsA("BasePart") then
						local drip = Instance.new("ParticleEmitter")
						drip.Name = "FrogSlime"
						drip.Color = ColorSequence.new(Color3.fromRGB(150, 220, 70), Color3.fromRGB(90, 160, 40))
						drip.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.15) })
						drip.Speed = NumberRange.new(0.5, 1.5)
						drip.Acceleration = Vector3.new(0, -30, 0)
						drip.Lifetime = NumberRange.new(0.5, 0.8)
						drip.SpreadAngle = Vector2.new(180, 180)
						drip.Rate = 14
						drip.Parent = torso
						task.delay(5, function()
							drip:Destroy()
						end)
					end
				end
			end
			return facing.LookVector * 60 + Vector3.new(0, 40, 0)
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
	-- (23 Nov 2026, owner: "the shark under the water, only the fin sticking up".) The whole shark lies under the floor
	-- of the shallow pool; a fin (wedge: the slope to the front) and its dark shadow swim for it (Client/CreatureLife).
	local finParts: { BasePart } = {}
	if shark then
		local cfS, sizeS = shark:GetBoundingBox()
		local surface = (at * CFrame.new(0, 1, 0)).Position.Y
		shark:PivotTo(shark:GetPivot() + Vector3.new(0, surface - 0.7 - (cfS.Position.Y + sizeS.Y / 2), 0))
		local pivot = shark:GetPivot()
		local up = surface - pivot.Position.Y
		local fin = Instance.new("WedgePart")
		fin.Name = "SharkFin"
		fin.Size = Vector3.new(0.45, 3, 3.2)
		fin.Color = Color3.fromRGB(84, 92, 102)
		fin.CFrame = pivot * CFrame.new(0, up + 1, 0)
		local tip = Instance.new("WedgePart")
		tip.Name = "SharkFinBack"
		tip.Size = Vector3.new(0.4, 2.4, 0.9)
		tip.Color = fin.Color
		tip.CFrame = pivot * CFrame.new(0, up + 0.7, 2.05) * CFrame.Angles(0, math.pi, 0)
		local shade = Instance.new("Part")
		shade.Name = "SharkShade"
		shade.Size = Vector3.new(3.6, 0.3, 15)
		shade.Color = Color3.fromRGB(16, 30, 44)
		shade.Transparency = 0.35
		shade.CFrame = pivot * CFrame.new(0, up - 0.6, 0)
		local oval = Instance.new("SpecialMesh")
		oval.MeshType = Enum.MeshType.Sphere
		oval.Parent = shade
		for _, p in { fin, tip, shade } :: { BasePart } do
			p.Material = Enum.Material.SmoothPlastic
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p:SetAttribute("Shown", p.Transparency)
			p.Parent = shark
			table.insert(finParts, p)
		end
	end
	local function showFin(on: boolean)
		for _, p in finParts do
			p.Transparency = if on then (p:GetAttribute("Shown") :: number) else 1
		end
	end
	-- F78 part 2 (Config.REAL_WATER, owner: "Hajen er nede i concrete i akvariet"): on the compact map the shark lives in
	-- the aquarium's real terrain water. Its own shallow pool, sand floor and rim go; it hangs at MID-DEPTH (the tank's base is
	-- 3 high, the water stands to 2 under the 14-high glass), sized to the tank, and the surface fin is not needed.
	local REAL = (Config :: any).REAL_WATER == true and (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).compact
	if REAL and shark then
		for _, n in { "SharkTankFloor", "SharkTankWater", "TankRim" } do
			local x = f:FindFirstChild(n)
			if x and x ~= pool then
				x:Destroy()
			end
		end
		pool.Transparency = 1
		pool.CanCollide = false
		local tank = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).size("Aquarium", Vector2.new(44, 30))
		local _, s0 = shark:GetBoundingBox()
		local long = math.max(s0.X, s0.Z)
		if long > 0 then
			shark:ScaleTo(shark:GetScale() * math.clamp((tank.X - 4) * 0.42 / long, 0.3, 1.5))
		end
		local cfS, sizeS = shark:GetBoundingBox()
		local mid = (at * CFrame.new(0, 3 + 6, 0)).Position.Y -- (the middle of the water: base 3 + half of 12)
		shark:PivotTo(shark:GetPivot() + Vector3.new(0, mid - cfS.Position.Y, 0))
		local _ = sizeS
		for _, p in finParts do
			p:SetAttribute("Shown", 1)
			p.Transparency = 1
		end
	end
	local basePivot = shark and shark:GetPivot()
	-- (Phase D, 23 Nov 2026: on a catch the water foams and splashes. The patrol from the server jittered back and
	-- forth over the water (owner): taken out; it lies still until it eats.)
	-- A red mist burst when the tank eats (replaces the whale's clean white spout).
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxasset://textures/particles/smoke_main.dds"
	burst.Color = ColorSequence.new(mild(Color3.fromRGB(200, 40, 40)))
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
			spray(f, (at * CFrame.new(0, 1.2, 0)).Position, { Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 230, 240) }, 60, 20, 0.9, Vector3.new(0, 1, 0))
			lazy("FxService").hit((at * CFrame.new(0, 1, 0)).Position, 120, "CannonPad")
			local blue = pool.Color
			local red = if GORE then Color3.fromRGB(150, 18, 24) else Color3.fromRGB(120, 190, 230) -- (gore off: foam, never red)
			TweenService:Create(pool, TweenInfo.new(0.9), { Color = red, Transparency = 0.15 }):Play()
			-- 3.12 SHARK (docs/MACHINES_10.md; Config.SHARK_10): a cartoon death roll (two full turns), a random time in the
			-- jaws that is the score ("CHOMP! 2.1 s in the jaws" + NEW BEST: SharkBest), and the body comes up soaked with bubbles.
			local shark10 = (Config :: any).SHARK_10 == true
			local thrash = if shark10 then 1.4 + math.random() * 1.2 else 1.8
			if shark and basePivot then
				-- (It bursts up out of the water, jaws first, thrashes, and goes under again.)
				showFin(false)
				play(thrash, function(t)
					local out = math.sin(math.min(1, t * 1.15) * math.pi)
					local roll = if shark10 then t * math.pi * 4 else math.sin(t * math.pi * 6) * 0.4 * out
					shark:PivotTo(basePivot * CFrame.new(math.sin(t * 9) * 1.5, out * 7.5, 0) * CFrame.Angles(out * 0.35, math.sin(t * 7) * 0.4, roll))
				end)
				shark:PivotTo(basePivot)
				showFin(true)
			else
				task.wait(thrash)
			end
			if shark10 then
				local held = math.floor(thrash * 10 + 0.5) / 10
				local text = "CHOMP! " .. string.format("%.1f", held) .. " s in the jaws"
				local okO, owner = pcall(function()
					return lazy("Lab").ownerAt(at.Position)
				end)
				if okO and owner then
					local best = (owner:GetAttribute("SharkBest") :: number?) or 0
					if held > best then
						owner:SetAttribute("SharkBest", held)
						text ..= " NEW BEST!"
					end
				end
				pcall(function()
					lazy("Playground").pop((at * CFrame.new(0, 8, 0)).Position, text, Color3.fromRGB(140, 210, 255))
				end)
				task.delay(0.3, function()
					local torso = model:FindFirstChild("UpperTorso")
					if torso and torso:IsA("BasePart") then
						local bubbles = Instance.new("ParticleEmitter")
						bubbles.Name = "SoakedBubbles"
						bubbles.Rate = 14
						bubbles.Lifetime = NumberRange.new(1, 1.6)
						bubbles.Speed = NumberRange.new(2, 5)
						bubbles.Acceleration = Vector3.new(0, 4, 0)
						bubbles.SpreadAngle = Vector2.new(70, 70)
						bubbles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.4) })
						bubbles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
						bubbles.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
						bubbles.Parent = torso
						task.delay(5, function()
							bubbles:Destroy()
						end)
					end
				end)
			end
			burst:Emit(30)
			-- The spit: bones with meat on, out of the tank and onto the floor round it.
			local mouth = (at * CFrame.new(0, 2, 0)).Position
			if not GORE then
				spray(f, mouth, { Color3.fromRGB(255, 215, 60), Color3.fromRGB(255, 255, 255) }, 28, 20, 0.6)
			end
			for i = 1, if GORE then 7 else 0 do
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
-- 3.16 CHICKEN (docs/MACHINES_10.md; Config.CHICKEN_10): when the egg hatches, a little yellow chick pops out too and
-- follows the lab's owner for CHICK_TIME s (hopping, 3 studs behind, at most one chick each), then waddles off and is gone.
local CHICK_TIME = 60
local chickOf: { [Player]: BasePart } = {}
local function chickFollow(owner: Player, from: Vector3, into: Instance)
	local old = chickOf[owner]
	if old and old.Parent then
		old:Destroy()
	end
	local chick = Instance.new("Part")
	chick.Name = "Chick"
	chick.Shape = Enum.PartType.Ball
	chick.Size = Vector3.one * 1.1
	chick.Color = Color3.fromRGB(255, 220, 70)
	chick.Material = Enum.Material.SmoothPlastic
	chick.Anchored, chick.CanCollide, chick.CanQuery, chick.CanTouch = true, false, false, false
	chick.CFrame = CFrame.new(from)
	local beak = Instance.new("Part")
	beak.Name = "Beak"
	beak.Size = Vector3.new(0.25, 0.2, 0.35)
	beak.Color = Color3.fromRGB(255, 140, 40)
	beak.Material = Enum.Material.SmoothPlastic
	beak.Anchored, beak.CanCollide, beak.CanQuery, beak.CanTouch = true, false, false, false
	beak.Parent = chick
	for _, x in { -0.2, 0.2 } do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.one * 0.16
		eye.Color = Color3.fromRGB(20, 20, 24)
		eye.Anchored, eye.CanCollide, eye.CanQuery, eye.CanTouch = true, false, false, false
		eye:SetAttribute("X", x)
		eye.Parent = chick
	end
	chick.Parent = into
	chickOf[owner] = chick
	pcall(function()
		lazy("Playground").pop(from + Vector3.new(0, 3, 0), "A CHICK! It follows you", Color3.fromRGB(255, 230, 90))
	end)
	task.spawn(function()
		local t0 = os.clock()
		local pos = from
		while chick.Parent and owner.Parent and os.clock() - t0 < CHICK_TIME do
			local root = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local goal = root.Position - root.CFrame.LookVector * 3 + root.CFrame.RightVector * -1.5 - Vector3.new(0, 2.4, 0)
				local step = goal - pos
				if step.Magnitude > 60 then
					pos = goal -- (it was left far behind: it catches up)
				elseif step.Magnitude > 0.3 then
					pos += step.Unit * math.min(step.Magnitude, 1.6)
				end
				local hop = math.abs(math.sin(os.clock() * 12)) * (if step.Magnitude > 0.3 then 0.5 else 0.08)
				local face = if step.Magnitude > 0.3 then CFrame.lookAt(pos, pos + Vector3.new(step.X, 0, step.Z)) else CFrame.lookAt(pos, Vector3.new(root.Position.X, pos.Y, root.Position.Z))
				local cf = face + Vector3.new(0, hop, 0)
				chick.CFrame = cf
				beak.CFrame = cf * CFrame.new(0, 0, -0.6)
				for _, e in chick:GetChildren() do
					if e.Name == "Eye" and e:IsA("BasePart") then
						e.CFrame = cf * CFrame.new(e:GetAttribute("X") :: number, 0.2, -0.45)
					end
				end
			end
			task.wait(0.1)
		end
		if chick.Parent then
			chick:Destroy()
		end
		if chickOf[owner] == chick then
			chickOf[owner] = nil
		end
	end)
end

BUILD.Chicken = function(f, at, m)
	part(f, "Coop", Vector3.new(14, 0.4, 12), at * CFrame.new(0, 0.2, 0), Color3.fromRGB(196, 160, 96), Enum.Material.WoodPlanks)
	local hen = place(f, "MChicken", (at * CFrame.new(0, 0.4, 2)).Position, 180, 9)
	local nest = at * CFrame.new(0, 0, -6)
	part(f, "Nest", Vector3.new(6, 1, 6), nest * CFrame.new(0, 0.5, 0), Color3.fromRGB(205, 180, 110), Enum.Material.Grass, Enum.PartType.Cylinder).CFrame = nest * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	local henHome = if hen then hen:GetPivot() else at
	-- (Phase D, 23 Nov 2026): the hen struts to the body and pecks it three times (feathers fly), gobbles it, waddles
	-- onto the nest and sits; an egg grows under her; she hops off, the egg wobbles harder and harder, cracks (shell
	-- bits fly) and a little ragdoll flails out of it before the real one is flung from the nest.
	local function setHen(cf: CFrame)
		if hen then
			hen:PivotTo(cf)
		end
	end
	return function()
		if m.busy then
			return
		end
		local body = look(f, at * CFrame.new(0, 4, 2), Vector3.new(14, 8, 10))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			local r = rootOf(model)
			local target = if r then Vector3.new(r.Position.X, henHome.Position.Y, r.Position.Z) else henHome.Position
			local face = if (target - henHome.Position).Magnitude > 0.5 then CFrame.lookAt(henHome.Position, target) else henHome
			local near = face + (target - henHome.Position) * 0.6
			play(0.4, function(t)
				setHen(henHome:Lerp(near, t) * CFrame.new(0, math.abs(math.sin(t * math.pi * 4)) * 0.4, 0))
			end)
			for _ = 1, 3 do
				play(0.14, function(t)
					setHen(near * CFrame.Angles(math.rad(-35) * math.sin(t * math.pi), 0, 0))
				end)
				local beak = (near * CFrame.new(0, 1.5, -2)).Position
				spray(f, beak, { Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 220, 190) }, 10, 10, 0.4)
				lazy("FxService").hit(beak, 30, "Punch")
			end
			hideBody(model, true)
			task.spawn(hold, model, function()
				return nest * CFrame.new(0, 3, 0)
			end, 5)
			local onNest = CFrame.lookAt(nest.Position, nest.Position + henHome.LookVector) * CFrame.new(0, 1.2, 0)
			play(0.5, function(t)
				setHen(near:Lerp(onNest, t) * CFrame.new(0, math.abs(math.sin(t * math.pi * 3)) * 0.5, 0))
			end)
			local egg = part(f, "DummyEgg", Vector3.new(1, 1.3, 1), nest * CFrame.new(0, 1.2, 0), Color3.fromRGB(250, 246, 236), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			table.insert(m.temp, egg)
			play(0.9, function(t)
				setHen(onNest * CFrame.new(0, -0.4 * t, 0) * CFrame.Angles(0, 0, math.sin(t * 30) * 0.05))
				egg.Size = Vector3.new(1 + 3.5 * t, 1.3 + 4.7 * t, 1 + 3.5 * t)
				egg.CFrame = nest * CFrame.new(0, 1 + 2.5 * t, 0)
			end)
			play(0.4, function(t)
				setHen(onNest:Lerp(henHome, t) * CFrame.new(0, math.sin(t * math.pi) * 2, 0))
			end)
			setHen(henHome)
			play(1.4, function(t)
				egg.CFrame = nest * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.sin(t * (15 + t * 25)) * 0.35 * t)
			end)
			-- Crack: shell bits, then a little ragdoll flails out.
			local eggAt = egg.Position
			egg:Destroy()
			spray(f, eggAt, { Color3.fromRGB(250, 246, 236), Color3.fromRGB(230, 225, 210) }, 30, 16, 0.6)
			lazy("FxService").hit(eggAt, 80, "Punch")
			local chick = puppet(f, 0.45)
			play(0.6, function(t)
				chick.set(CFrame.new(eggAt + Vector3.new(0, t * 3, 0)) * CFrame.Angles(0, t * 6, 0), t * 3)
			end)
			chick.remove()
			hideBody(model, false)
			if (Config :: any).CHICKEN_10 then
				local okO, owner = pcall(function()
					return lazy("Lab").ownerAt(eggAt)
				end)
				if okO and owner then
					chickFollow(owner, eggAt, f)
				end
			end
			return Vector3.new(0, 70, 0) + m.toLab * 25
		end)
	end
end

-- WASHER: the door swings open, the body goes in, you see a ragdoll spin round behind the glass while the water
-- fills and turns red and the machine shakes on its feet; the door bangs open, red water splashes out and the
-- body flops out limp, a piece short. (Phase D, 23 Nov 2026.)
BUILD.Washer = function(f, at, m)
	local washer = place(f, "MWasher", at.Position, 0, 12)
	local base = if washer then washer:GetPivot() else at
	local door = base * CFrame.new(0, 6, -6)
	local drum = door * CFrame.new(0, 0, 1.6)
	local glass = part(f, "WasherGlass", Vector3.new(0.2, 5.4, 5.4), door * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(190, 220, 235), Enum.Material.Glass, Enum.PartType.Cylinder)
	glass.Transparency = 0.55
	local hinge = door * CFrame.new(-2.8, 0, 0)
	local function setDoor(open: number)
		glass.CFrame = hinge * CFrame.Angles(0, math.rad(-100 * open), 0) * CFrame.new(2.8, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
	end
	setDoor(0)
	-- 3.8 WASHER (docs/MACHINES_10.md; Config.WASHER_10): a program dial (a prompt on the door: DELICATE > NORMAL >
	-- TURBO), a light purple suds wash, the machine walking across its pad on TURBO, the spin count ("142 SPINS!") with a
	-- NEW BEST for the lab's owner (WashBest), and the body comes out dizzy with bubbles rising off it.
	local wash10 = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).WASHER_10 == true
	local PROGRAMS = { { name = "DELICATE", k = 0.5 }, { name = "NORMAL", k = 1 }, { name = "TURBO", k = 2 } }
	local program = 2
	if wash10 then
		local pp = Instance.new("ProximityPrompt")
		pp.ObjectText = "Washer: NORMAL"
		pp.ActionText = "Program"
		pp.HoldDuration = 0
		pp.MaxActivationDistance = 12
		pp.RequiresLineOfSight = false
		pp.Parent = glass
		pp.Triggered:Connect(function()
			program = program % #PROGRAMS + 1
			pp.ObjectText = "Washer: " .. PROGRAMS[program].name
		end)
	end
	return function()
		if m.busy then
			return
		end
		local body = look(f, door * CFrame.new(0, -2, -2), Vector3.new(10, 8, 8))[1]
		if not body then
			return
		end
		swallow(m, body, function(model)
			play(0.25, function(t)
				setDoor(t)
			end)
			hideBody(model, true)
			task.spawn(hold, model, function()
				return base * CFrame.new(0, 6, 0)
			end, 3.6)
			play(0.25, function(t)
				setDoor(1 - t)
			end)
			local water = part(f, "WasherWater", Vector3.new(0.3, 0.2, 5), drum * CFrame.new(0, -2.2, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(80, 150, 220), Enum.Material.Glass, Enum.PartType.Cylinder)
			water.Transparency = 0.35
			table.insert(m.temp, water)
			local doll = puppet(f, 0.6)
			local blue, red = Color3.fromRGB(80, 150, 220), if GORE then Color3.fromRGB(150, 20, 28) elseif wash10 then Color3.fromRGB(200, 170, 240) else Color3.fromRGB(120, 200, 240)
			local k = if wash10 then PROGRAMS[program].k else 1
			local turbo = wash10 and k >= 2
			local walk = if turbo then Vector3.new(math.random(-10, 10) / 10, 0, math.random(-10, 10) / 10) * 2.5 else Vector3.zero
			play(3.0, function(t)
				local spin = t * t * 40 * k
				doll.set(drum * CFrame.Angles(0, 0, spin) * CFrame.new(0, 1, 0) * CFrame.Angles(spin * 0.7, 0, 0), t * 6)
				local level = math.min(1, t * 2)
				water.Size = Vector3.new(0.3, 0.2 + level * 4.6, 5)
				water.CFrame = drum * CFrame.new(0, -2.2 + level * 2.3, 0) * CFrame.Angles(0, math.rad(90), 0)
				water.Color = blue:Lerp(red, math.clamp(t * 1.4 - 0.2, 0, 1))
				if washer then
					local shake = (0.15 + t * 0.35) * (if turbo then 1.8 else 1)
					washer:PivotTo(base * CFrame.new(math.sin(t * 90) * shake, math.abs(math.sin(t * 60)) * shake * 0.5, math.cos(t * 70) * shake) + walk * t)
				end
			end)
			if washer then
				if turbo then
					play(0.6, function(t)
						washer:PivotTo(base + walk * (1 - t)) -- (it walks back onto its pad)
					end)
				end
				washer:PivotTo(base)
			end
			if wash10 then
				local spins = math.floor(40 * k * 3.5 + math.random(0, 9))
				local text = tostring(spins) .. " SPINS!"
				local okO, owner = pcall(function()
					return lazy("Lab").ownerAt(door.Position)
				end)
				if okO and owner then
					local best = (owner:GetAttribute("WashBest") :: number?) or 0
					if spins > best then
						owner:SetAttribute("WashBest", spins)
						text ..= " NEW BEST!"
					end
				end
				pcall(function()
					lazy("Playground").pop(door.Position + Vector3.new(0, 4, 0), text, Color3.fromRGB(200, 170, 255))
				end)
				-- out dizzy, with bubbles rising off it for 4 s
				local torso = model:FindFirstChild("UpperTorso")
				if torso and torso:IsA("BasePart") then
					local bubbles = Instance.new("ParticleEmitter")
					bubbles.Name = "WasherBubbles"
					bubbles.Rate = 12
					bubbles.Lifetime = NumberRange.new(1, 1.8)
					bubbles.Speed = NumberRange.new(2, 4)
					bubbles.Acceleration = Vector3.new(0, 3, 0)
					bubbles.SpreadAngle = Vector2.new(60, 60)
					bubbles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.45) })
					bubbles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
					bubbles.Color = ColorSequence.new(Color3.fromRGB(230, 220, 255))
					bubbles.LightEmission = 0.3
					bubbles.Parent = torso
					task.delay(4, function()
						bubbles:Destroy()
					end)
				end
			end
			doll.remove()
			play(0.15, function(t)
				setDoor(t)
			end)
			spray(f, door.Position, { red, if GORE then Color3.fromRGB(110, 10, 20) else Color3.fromRGB(235, 235, 255) }, 50, 18, 0.6, door.LookVector + Vector3.new(0, 0.2, 0))
			water:Destroy()
			task.delay(1.2, function()
				play(0.4, function(t)
					setDoor(1 - t)
				end)
			end)
			hideBody(model, false)
			if model.Parent then
				lazy("DummyControl").move(model, door * CFrame.new(0, -1, -3))
			end
			return m.toLab * 45 + Vector3.new(0, 20, 0)
		end)
	end
end

-- SLINGSHOT: a tree with two bands and a pad; a dummy on the pad is pulled back and fired.
BUILD.Slingshot = function(f, at, m)
	local treeL = place(f, "TreeRound", (at * CFrame.new(-5, 0, 4)).Position, 0, 20)
	local treeR = place(f, "TreeRound", (at * CFrame.new(5, 0, 4)).Position, 60, 20)
	local homeL = treeL and treeL:GetPivot()
	local homeR = treeR and treeR:GetPivot()
	local pad = part(f, "SlingPad", Vector3.new(6, 0.4, 6), at * CFrame.new(0, 0.2, 0), Color3.fromRGB(150, 60, 50), Enum.Material.Fabric)
	local left = part(f, "Band", Vector3.new(0.4, 0.4, 1), at, Color3.fromRGB(120, 40, 30), Enum.Material.Fabric)
	local right = part(f, "Band", Vector3.new(0.4, 0.4, 1), at, Color3.fromRGB(120, 40, 30), Enum.Material.Fabric)
	local postL0, postR0 = (at * CFrame.new(-5, 7, 4)).Position, (at * CFrame.new(5, 7, 4)).Position
	local postL, postR = postL0, postR0
	local function bands(to: Vector3)
		for _, pair in { { left, postL }, { right, postR } } do
			local b, post = pair[1], pair[2]
			b.Size = Vector3.new(0.4, 0.4, math.max(0.5, (to - post).Magnitude))
			b.CFrame = CFrame.lookAt((to + post) / 2, to)
		end
	end
	-- (Phase D, 23 Nov 2026): as the band is drawn back the two trees bend in towards it; let go, they whip forward
	-- past straight and wobble back, and the body flies far.
	local function bend(k: number)
		local tilt = math.rad(14) * k
		if treeL and homeL then
			treeL:PivotTo(homeL * CFrame.Angles(tilt, 0, -tilt * 0.6))
		end
		if treeR and homeR then
			treeR:PivotTo(homeR * CFrame.Angles(tilt, 0, tilt * 0.6))
		end
		local back = at:VectorToWorldSpace(Vector3.new(0, -0.4 * k, 1.6 * k))
		postL = postL0 + at:VectorToWorldSpace(Vector3.new(1.2 * k, 0, 0)) + back
		postR = postR0 + at:VectorToWorldSpace(Vector3.new(-1.2 * k, 0, 0)) + back
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
			local back = at * CFrame.new(0, 4, 11)
			task.spawn(hold, model, function()
				return back
			end, 1.3)
			play(1.1, function(t)
				local k = t * t
				bend(k)
				bands(from.Position:Lerp(back.Position, k))
			end)
			lazy("FxService").hit(back.Position, 40, "Punch")
			task.delay(0.12, function()
				play(0.12, function(t)
					bend(1 - 1.6 * t)
					bands(back.Position:Lerp(from.Position, t))
				end)
				play(0.7, function(t)
					bend(-0.6 * (1 - t) * math.cos(t * math.pi * 3))
				end)
				bend(0)
				bands(pad.Position + Vector3.new(0, 3, 0))
			end)
			spray(f, back.Position, { Color3.fromRGB(150, 120, 80) }, 18, 10, 0.5)
			return at.LookVector * 150 + Vector3.new(0, 75, 0) -- (a long flight toward the lab)
		end)
	end
end

-- MOLE: a dirt patch; it digs up under a dummy (dirt flies, a hole opens), drags it under, and a moment later the
-- earth bursts somewhere else on the patch and it throws the body sky-high. (Phase D, 23 Nov 2026.)
BUILD.Mole = function(f, at, m)
	part(f, "MoleDirt", Vector3.new(20, 0.3, 20), at * CFrame.new(0, 0.15, 0), Color3.fromRGB(110, 82, 58), Enum.Material.Ground)
	for i = 1, 5 do
		local a = i * 1.3
		part(f, "MoleHill", Vector3.new(3, 1.6, 3), at * CFrame.new(math.cos(a) * 6, 0.5, math.sin(a) * 6), Color3.fromRGB(92, 68, 48), Enum.Material.Ground, Enum.PartType.Ball)
	end
	local mole = place(f, "MMole", (at * CFrame.new(0, -6, 0)).Position, 0, 6)
	local nextAt = 0
	local DIRT = { Color3.fromRGB(110, 82, 58), Color3.fromRGB(80, 60, 42) }
	local function setMole(cf: CFrame)
		if mole then
			mole:PivotTo(cf)
		end
	end
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
			local hole = part(f, "MoleHole", Vector3.new(0.2, 0.5, 0.5), under * CFrame.new(0, 0.32, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 22, 16), Enum.Material.Ground, Enum.PartType.Cylinder)
			table.insert(m.temp, hole)
			play(0.25, function(t)
				hole.Size = Vector3.new(0.2, 0.5 + 4 * t, 0.5 + 4 * t)
				setMole(under * CFrame.new(0, -5 + 5.5 * t, 0))
			end)
			spray(f, under.Position + Vector3.new(0, 0.5, 0), DIRT, 40, 18, 0.7, Vector3.new(0, 1, 0))
			lazy("FxService").hit(under.Position, 60, "Punch")
			-- Dragged under.
			hideBody(model, true)
			task.spawn(hold, model, function()
				return under * CFrame.new(0, -3, 0)
			end, 1.6)
			play(0.3, function(t)
				setMole(under * CFrame.new(0, 0.5 - 6 * t, 0))
			end)
			task.wait(0.8)
			-- Up somewhere else: the earth bursts, the body flies.
			local a = math.random() * math.pi * 2
			local out = at * CFrame.new(math.cos(a) * 6, 0, math.sin(a) * 6)
			spray(f, out.Position + Vector3.new(0, 0.5, 0), DIRT, 50, 22, 0.8, Vector3.new(0, 1, 0))
			play(0.2, function(t)
				setMole(out * CFrame.new(0, -5 + 6 * t, 0))
				hole.Size = Vector3.new(0.2, 4.5 * (1 - t) + 0.1, 4.5 * (1 - t) + 0.1)
			end)
			hole:Destroy()
			task.delay(0.8, function()
				play(0.3, function(t)
					setMole(out * CFrame.new(0, 1 - 7 * t, 0))
				end)
			end)
			hideBody(model, false)
			if model.Parent then
				lazy("DummyControl").move(model, out * CFrame.new(0, 3, 0))
			end
			lazy("FxService").hit(out.Position, 100, "CannonPad")
			return Vector3.new(0, 105, 0) + m.toLab * 30
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
	{ id = "Spider", label = "the SPIDER", x = 0, z = -42 * S, yaw = 180 }, -- (0.37.14: further forward, clear of the portals behind it) -- (0.37.3, owner: "the spider where the black mat was, right in front of the spawn: the first thing you see")
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
-- V10 phase 3 (owner: "shoot or hit an animal and it comes for you and eats you, WASTED on the screen, and you
-- respawn in your lab"): HitService tells shotAt where a round landed. If that is on a creature, it drops what
-- it does, lunges at the shooter, swallows them (the body hidden, a burst of blood), the shooter's screen shows
-- WASTED (Client/Wasted), the creature goes home, and the player comes back in their lab.
LabCreatures.REVENGE_GAP = 6 -- s before the same creature comes for someone again
LabCreatures.REVENGE_REACH = 22 -- studs from the creature's edge: nearer than that, a shot makes it come for you
LabCreatures.WASTED_HOLD = 2.6 -- s on the WASTED screen before the respawn
local creatures: { { machine: Machine, model: Model } } = {}
local lastRevenge: { [Model]: number } = {}
local wastedRemote: RemoteEvent? = nil
local function wasted(): RemoteEvent
	local r = wastedRemote
	if r and r.Parent then
		return r
	end
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") or game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 10)
	local made = (remotes and remotes:FindFirstChild("Wasted")) :: RemoteEvent?
	if not made then
		made = Instance.new("RemoteEvent")
		;(made :: RemoteEvent).Name = "Wasted"
		;(made :: RemoteEvent).Parent = remotes or game:GetService("ReplicatedStorage")
	end
	wastedRemote = made
	return made :: RemoteEvent
end

local function revenge(entry: { machine: Machine, model: Model }, player: Player)
	local m, model = entry.machine, entry.model
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) or humanoid.Health <= 0 then
		return
	end
	m.busy = true
	m.folder:SetAttribute("Busy", true)
	local home = model:GetPivot()
	local ok, err = pcall(function()
		-- The lunge: straight at them, fast, turned to face them.
		local from = home.Position
		play(0.7, function(t)
			local to = root.Position
			local pos = from:Lerp(Vector3.new(to.X, from.Y + math.sin(t * math.pi) * 6, to.Z), t * t)
			model:PivotTo(CFrame.lookAt(pos, Vector3.new(to.X, pos.Y, to.Z)))
		end)
		-- Swallowed: the body gone, a burst of blood, the screen goes WASTED.
		local at = root.Position
		local saved: { [Instance]: number } = {}
		for _, d in (character :: Model):GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				saved[d] = d.Transparency
				d.Transparency = 1
			end
		end
		root.Anchored = true
		local burst = Instance.new("Part")
		burst.Anchored, burst.CanCollide, burst.CanQuery, burst.CanTouch, burst.Transparency = true, false, false, false, 1
		burst.Position = at
		burst.Parent = m.folder
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(Anatomy.BLOOD)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2) })
		e.Speed = NumberRange.new(10, 22)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Lifetime = NumberRange.new(0.5, 1)
		e.Acceleration = Vector3.new(0, -40, 0)
		e.Rate = 0
		e.Parent = burst
		e:Emit(60)
		game:GetService("Debris"):AddItem(burst, 3)
		wasted():FireClient(player, LabCreatures.WASTED_HOLD, m.label)
		-- Chewing, then home.
		local here = model:GetPivot()
		play(0.6, function(t)
			model:PivotTo(here * CFrame.new(0, math.abs(math.sin(t * 20)) * 0.8, 0))
		end)
		play(0.8, function(t)
			model:PivotTo(here:Lerp(home, t))
		end)
		model:PivotTo(home)
		task.wait(math.max(0, LabCreatures.WASTED_HOLD - 1.4))
		for d, tr in saved do
			if d.Parent then
				(d :: any).Transparency = tr
			end
		end
		if player.Parent then
			player:LoadCharacter() -- (back in their lab: Lab places a new character on its plot)
		end
	end)
	if not ok then
		warn("[LabCreatures] revenge " .. tostring(err))
		model:PivotTo(home)
	end
	m.busy = false
	m.folder:SetAttribute("Busy", nil)
end

-- A round from `player` landed at `point`: a creature there comes for them.
function LabCreatures.shotAt(player: Player, point: Vector3)
	for _, entry in creatures do
		local model = entry.model
		if model.Parent and not entry.machine.busy then
			local cf, size = model:GetBoundingBox()
			local rel = cf:PointToObjectSpace(point)
			local half = size / 2 + Vector3.new(1, 1, 1)
			if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z then
				-- (23 Nov 2026, owner: "only when you are fairly close, not when you stand shooting from the spawn")
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local reach = LabCreatures.REVENGE_REACH + math.max(size.X, size.Z) / 2
				if not (root and root:IsA("BasePart")) or (Vector3.new(root.Position.X - cf.Position.X, 0, root.Position.Z - cf.Position.Z)).Magnitude > reach then
					return
				end
				local now = os.clock()
				if now - (lastRevenge[model] or -math.huge) >= LabCreatures.REVENGE_GAP then
					lastRevenge[model] = now
					task.spawn(revenge, entry, player)
				end
				return
			end
		end
	end
end

function LabCreatures.build(into: Instance, origin: Vector3)
	pcall(wasted) -- (V10 phase 3: the WASTED remote exists before anyone gets eaten; Client/Wasted listens)
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
	if (Config :: any).GREEN_TILES or LabLayout10.on then
		ground.Transparency = 1 -- (the green tiles under it show)
	end
	local ticks: { () -> () } = {}
	for _, spot in LabCreatures.LAYOUT do
		-- (LAB10: each one in its zone of the crash-test lab: Shared/LabLayout10.)
		local moved = LabLayout10.creature(spot.id)
		if moved then
			local copy = table.clone(spot :: any)
			copy.x, copy.z = moved.X, moved.Y
			spot = copy
		end
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
				table.insert(creatures, { machine = machine, model = c }) -- (V10 phase 3: it fights back, shotAt)
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
