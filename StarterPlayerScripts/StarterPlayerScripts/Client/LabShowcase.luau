--!strict
-- LAB10 round 2 (owner, 26 Nov 2026: "tilføje animation som gør folk ikke kan vente med at prøve den
-- næste"; docs/LAB10.md R2.4). Two things, both on this client only:
--
-- ATTRACT MODE (Config.ATTRACT_MODE): every machine shows off by itself. A small yellow crash-test demo
-- dummy (6 parts, made here, never on the server) is fired from the cannon, smacked off by the wrecking
-- ball, slammed into the crash wall, lifted by the rocket, wrapped by the spider, thrown by the shark, squashed
-- by the press, spun in the washer... One demo starts every DEMO_GAP s, in turn, among the machines within
-- REACH studs of the camera; never one where a player stands close (they are using it); at most MAX_LIVE at
-- once (fewer on a phone). Something happens on screen every 2-3 s from anywhere in the lab.
--
-- TRY ME (Config.TRY_ME): the nearest machine you have not tried this visit (the server sets Tried_<kind>,
-- ExperimentService.event) gets a pulsing ring on the floor and a bobbing "TRY!" sign; the goal pill says
-- "Next: try the CANNON!". Try it, and the next one starts to pulse.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local LabShowcase = {}

LabShowcase.DEMO_GAP = 2.6 -- s between two demos starting
LabShowcase.REACH = 120 -- studs from the camera a machine may show off
LabShowcase.BUSY = 12 -- studs: a player this close is using the machine, no demo
LabShowcase.MAX_LIVE = 4
LabShowcase.MAX_LIVE_PHONE = 3
LabShowcase.GRAVITY = 70

local player = Players.LocalPlayer

local YELLOW = Color3.fromRGB(240, 196, 60)
local BLACK = Color3.fromRGB(30, 30, 34)

-- The lab this player stands in: the Playground folder whose cannon is nearest.
local function myLab(): Instance?
	local root = Workspace:FindFirstChild("Playground")
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not hrp or not hrp:IsA("BasePart") then
		return nil
	end
	local best: Instance? = nil
	local bestD = 400
	for _, lab in root:GetChildren() do
		if string.sub(lab.Name, 1, 3) == "Lab" then
			local pad = lab:FindFirstChild("CannonPad")
			if pad and pad:IsA("BasePart") then
				local d = (pad.Position - hrp.Position).Magnitude
				if d < bestD then
					best, bestD = lab, d
				end
			end
		end
	end
	return best
end

local function find(lab: Instance, path: { string }): Instance?
	local at: Instance? = lab
	for _, name in path do
		at = at and at:FindFirstChild(name)
	end
	return at
end

local function where(inst: Instance?): Vector3?
	if not inst then
		return nil
	end
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

-- The machines: where each one is (from the lab), its demo, and its "try" name.
type Machine = {
	kind: string?, -- the ExperimentService kind for TRY ME (nil: attract only)
	label: string,
	path: { string },
	demo: string, -- "arc" | "rise" | "slide" | "drop" | "spin"
	velocity: Vector3?, -- for "arc"
	lift: number?, -- studs over the thing where the dummy starts
}
LabShowcase.MACHINES = {
	{ kind = "Cannon", label = "the CANNON", path = { "CannonBarrel" }, demo = "arc", velocity = Vector3.new(-0.45, 0.8, -0.4).Unit * 62, lift = 2 },
	{ kind = "Wrecking", label = "the WRECKING BALL", path = { "SwingBall" }, demo = "arc", velocity = Vector3.new(0, 34, -46), lift = 0 },
	{ label = "the CRASH WALL", path = { "StationWall" }, demo = "slide" },
	{ label = "the ROCKET", path = { "Dress", "Rocket" }, demo = "rise", lift = 3 },
	{ kind = "Spider", label = "the SPIDER", path = { "CreatureYard", "Spider" }, demo = "spin", lift = 9 },
	{ kind = "Whale", label = "the SHARK TANK", path = { "CreatureYard", "Whale" }, demo = "arc", velocity = Vector3.new(6, 58, 10), lift = 2 },
	{ kind = "Vacuum", label = "the PRESS", path = { "CreatureYard", "Compressor" }, demo = "drop", lift = 16 },
	{ kind = "Washer", label = "the WASHER", path = { "CreatureYard", "Washer" }, demo = "spin", lift = 4 },
	{ kind = "Slingshot", label = "the SLINGSHOT", path = { "CreatureYard", "Slingshot" }, demo = "arc", velocity = Vector3.new(30, 56, -34), lift = 6 },
	{ kind = "Plant", label = "the GIANT PLANT", path = { "CreatureYard", "Plant" }, demo = "drop", lift = 22 },
	{ kind = "Frog", label = "the FROG", path = { "CreatureYard", "Frog" }, demo = "arc", velocity = Vector3.new(0, 40, 22), lift = 1 },
	{ kind = "Chicken", label = "the CHICKEN", path = { "CreatureYard", "Chicken" }, demo = "arc", velocity = Vector3.new(-18, 44, 0), lift = 1 },
	{ kind = "Mole", label = "the MOLE", path = { "CreatureYard", "Mole" }, demo = "arc", velocity = Vector3.new(0, 52, 0), lift = 0 },
	{ label = "the BOXING RING", path = { "BoxingPit" }, demo = "arc", velocity = Vector3.new(0, 48, 0), lift = 2 },
} :: { Machine }

---------------------------------------------------------------------------------------------------
-- The demo dummy: a little yellow crash-test dummy in 6 parts, posed from one CFrame.
local PIECES = {
	{ "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), YELLOW },
	{ "Head", Vector3.new(1.3, 1.3, 1.3), CFrame.new(0, 1.7, 0), YELLOW },
	{ "ArmL", Vector3.new(0.8, 2, 0.8), CFrame.new(-1.45, 0, 0) * CFrame.Angles(0, 0, math.rad(-25)), BLACK },
	{ "ArmR", Vector3.new(0.8, 2, 0.8), CFrame.new(1.45, 0, 0) * CFrame.Angles(0, 0, math.rad(25)), BLACK },
	{ "LegL", Vector3.new(0.9, 2, 0.9), CFrame.new(-0.5, -2, 0), YELLOW },
	{ "LegR", Vector3.new(0.9, 2, 0.9), CFrame.new(0.5, -2, 0), YELLOW },
}
type Dummy = { parts: { BasePart }, offsets: { CFrame } }
local pool: { Dummy } = {}

local function newDummy(): Dummy
	local d: Dummy = { parts = {}, offsets = {} }
	for _, p in PIECES do
		local part = Instance.new("Part")
		part.Name = "ShowDummy" .. (p[1] :: string)
		part.Size = p[2] :: Vector3
		part.Color = p[4] :: Color3
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = true
		if p[1] == "Head" then
			part.Shape = Enum.PartType.Ball
		end
		table.insert(d.parts, part)
		table.insert(d.offsets, p[3] :: CFrame)
	end
	return d
end

local holder: Folder? = nil
local function show(d: Dummy, cf: CFrame)
	local h = holder
	if not h then
		local made = Instance.new("Folder")
		made.Name = "LabShowcase"
		made.Parent = Workspace
		holder = made
		h = made
	end
	for i, part in d.parts do
		part.CFrame = cf * d.offsets[i]
		if part.Parent ~= h then
			part.Parent = h
		end
	end
end

local function put(d: Dummy)
	for _, part in d.parts do
		part.Parent = nil
	end
	table.insert(pool, d)
end

local function take(): Dummy
	return table.remove(pool) or newDummy()
end

local function poof(at: Vector3, color: Color3?)
	local ball = Instance.new("Part")
	ball.Name = "ShowPoof"
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = color or Color3.new(1, 1, 1)
	ball.Size = Vector3.one * 2
	ball.Position = at
	ball.Parent = holder or Workspace
	local t = TweenService:Create(ball, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * 8, Transparency = 1 })
	t:Play()
	t.Completed:Once(function()
		ball:Destroy()
	end)
end

-- Runs one demo; returns when it is over.
local function play(m: Machine, at: Vector3, lab: Instance)
	local d = take()
	local start = at + Vector3.new(0, (m.lift or 0) + 3, 0)
	local spin = Vector3.new(math.random() * 8 - 4, math.random() * 8 - 4, math.random() * 8 - 4)
	local floorY = at.Y - 1
	local t0 = os.clock()
	local function step(fn: (t: number) -> boolean)
		while true do
			local t = os.clock() - t0
			if not fn(t) then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end
	if m.demo == "arc" then
		local v = m.velocity or Vector3.new(0, 50, 0)
		local last = start
		step(function(t)
			local p = start + v * t + Vector3.new(0, -0.5 * LabShowcase.GRAVITY * t * t, 0)
			last = p
			show(d, CFrame.new(p) * CFrame.Angles(spin.X * t, spin.Y * t, spin.Z * t))
			return t < 3.2 and not (t > 0.3 and p.Y < floorY + 2)
		end)
		poof(last)
	elseif m.demo == "rise" then
		local last = start
		step(function(t)
			local p = start + Vector3.new(0, 4 * t * t * 6, 0)
			last = p
			show(d, CFrame.new(p) * CFrame.Angles(0, t * 3, 0))
			return t < 2.4
		end)
		poof(last, Color3.fromRGB(255, 170, 60))
	elseif m.demo == "slide" then
		-- From the first launch pad into the crash wall, then it bounces back off the padding.
		local pads = {}
		for _, c in lab:GetChildren() do
			if c.Name == "StationPad" and c:IsA("BasePart") then
				table.insert(pads, c)
			end
		end
		table.sort(pads, function(a, b)
			return a.Position.X < b.Position.X
		end)
		local from = if pads[1] then pads[1].Position + Vector3.new(0, 3, 0) else at + Vector3.new(-40, 3, 0)
		local to = Vector3.new(at.X - 2, from.Y + 1, from.Z)
		step(function(t)
			local k = math.min(1, t / 0.7)
			show(d, CFrame.lookAt(from:Lerp(to, k * k), to) * CFrame.Angles(math.rad(-80), 0, 0))
			return k < 1
		end)
		poof(to, Color3.fromRGB(255, 120, 40))
		local back = Vector3.new(-14, 22, (math.random() - 0.5) * 10)
		t0 = os.clock()
		local last = to
		step(function(t)
			local p = to + back * t + Vector3.new(0, -0.5 * LabShowcase.GRAVITY * t * t, 0)
			last = p
			show(d, CFrame.new(p) * CFrame.Angles(spin.X * t, spin.Y * t, spin.Z * t))
			return t < 2 and not (t > 0.2 and p.Y < floorY + 2)
		end)
		poof(last)
	elseif m.demo == "drop" then
		-- Falls in from over it, squashes flat, pops.
		local top = start + Vector3.new(0, 10, 0)
		local bottom = at + Vector3.new(0, 2, 0)
		step(function(t)
			local k = math.min(1, t / 0.6)
			show(d, CFrame.new(top:Lerp(bottom, k * k)) * CFrame.Angles(0, t * 4, 0))
			return k < 1
		end)
		for i, part in d.parts do
			part.CFrame = CFrame.new(bottom) * d.offsets[i] * CFrame.new(0, -1, 0)
		end
		poof(bottom, YELLOW)
		task.wait(0.15)
	elseif m.demo == "spin" then
		step(function(t)
			show(d, CFrame.new(start + Vector3.new(0, math.sin(t * 3) * 0.6, 0)) * CFrame.Angles(t * 5, t * 7, 0))
			return t < 2.6
		end)
		poof(start, Color3.fromRGB(200, 230, 255))
	end
	put(d)
end

local function isPhone(): boolean
	local camera = Workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
	return math.min(v.X, v.Y) <= 500
end

local function playerNear(at: Vector3): boolean
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") and (r.Position - at).Magnitude < LabShowcase.BUSY then
			return true
		end
	end
	return false
end

local function attract()
	local live = 0
	local turn = 0
	while true do
		task.wait(LabShowcase.DEMO_GAP)
		local lab = myLab()
		local camera = Workspace.CurrentCamera
		if lab and camera and live < (if isPhone() then LabShowcase.MAX_LIVE_PHONE else LabShowcase.MAX_LIVE) then
			-- The next machine in turn that is near enough and free.
			for _ = 1, #LabShowcase.MACHINES do
				turn = turn % #LabShowcase.MACHINES + 1
				local m = LabShowcase.MACHINES[turn]
				local at = where(find(lab, m.path))
				if at and (at - camera.CFrame.Position).Magnitude < LabShowcase.REACH and not playerNear(at) then
					live += 1
					task.spawn(function()
						pcall(play, m, at, lab)
						live -= 1
					end)
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- TRY ME: a pulsing ring and a bobbing "TRY!" sign on the nearest untried machine.
local function tried(kind: string): boolean
	return player:GetAttribute("Tried_" .. kind) == true
end

local function makeMarker(): (BasePart, BillboardGui)
	local ring = Instance.new("Part")
	ring.Name = "TryMeRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 200, 40)
	ring.Size = Vector3.new(0.2, 12, 12)
	ring.Transparency = 0.4
	local sign = Instance.new("BillboardGui")
	sign.Name = "TryMeSign"
	sign.Size = UDim2.fromOffset(120, 54)
	sign.AlwaysOnTop = true
	sign.LightInfluence = 0
	sign.MaxDistance = 220
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(255, 120, 40)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = "TRY!"
	label.Parent = sign
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.4, 0)
	corner.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(1, 1, 1)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = label
	return ring, sign
end

-- One short word per machine for the goal pill (it cuts anything long).
local SHORT: { [string]: string } = {
	["the CANNON"] = "CANNON", ["the WRECKING BALL"] = "WRECKER", ["the SPIDER"] = "SPIDER", ["the SHARK TANK"] = "SHARK",
	["the PRESS"] = "PRESS", ["the WASHER"] = "WASHER", ["the SLINGSHOT"] = "SLINGSHOT", ["the GIANT PLANT"] = "PLANT",
	["the FROG"] = "FROG", ["the CHICKEN"] = "CHICKEN", ["the MOLE"] = "MOLE",
}

-- (STAY_LONGER 2: machines tried this visit, " 2/6", until the reward is given: ExperimentService.)
local function countText(): string
	local reward = Config.TRY_REWARD
	if not reward or player:GetAttribute("TryRewardDone") == true then
		return ""
	end
	local n = player:GetAttribute("TriedCount")
	return string.format(" %d/%d", if type(n) == "number" then n else 0, reward.count)
end

local function tryMe()
	local ring, sign = makeMarker()
	local current: Machine? = nil
	local lastSaid = 0
	local base: Vector3? = nil
	local top: Vector3? = nil
	RunService.RenderStepped:Connect(function()
		local b, tp = base, top
		if b and tp and ring.Parent then
			local t = os.clock()
			local s = 11 + math.sin(t * 4) * 1.5
			ring.Size = Vector3.new(0.2, s, s)
			ring.Transparency = 0.35 + (math.sin(t * 4) + 1) * 0.2
			ring.CFrame = CFrame.new(b + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
			sign.StudsOffsetWorldSpace = tp + Vector3.new(0, 2 + math.sin(t * 3) * 0.8, 0) - b
		end
	end)
	while true do
		task.wait(1)
		local lab = myLab()
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local best: Machine? = nil
		local bestAt: Vector3? = nil
		local bestTop: Vector3? = nil
		if lab and hrp and hrp:IsA("BasePart") then
			local bestD = math.huge
			for _, m in LabShowcase.MACHINES do
				local kind = m.kind
				if kind and not tried(kind) then
					local inst = find(lab, m.path)
					local at = where(inst)
					if inst and at then
						local d = (at - hrp.Position).Magnitude
						if d < bestD then
							local floorY = hrp.Position.Y - 3
							local height = 8
							if inst:IsA("Model") then
								local _, size = inst:GetBoundingBox()
								height = math.min(size.Y, 30)
							end
							best, bestD = m, d
							bestAt = Vector3.new(at.X, floorY, at.Z)
							bestTop = Vector3.new(at.X, floorY + height, at.Z)
						end
					end
				end
			end
		end
		if best and bestAt then
			base, top = bestAt, bestTop
			sign.Adornee = nil
			sign.StudsOffsetWorldSpace = Vector3.zero
			-- (A BillboardGui needs an anchor: the ring itself.)
			sign.Adornee = ring
			ring.Parent = holder or Workspace
			sign.Parent = player:WaitForChild("PlayerGui")
			if best ~= current then
				current = best
				if os.clock() - lastSaid > 20 then
					lastSaid = os.clock()
					pcall(function()
						(require(script.Parent:WaitForChild("HudV3")) :: any).moment("Try " .. (SHORT[best.label] or "IT") .. countText(), 6) -- (short: the goal pill cuts long lines)
					end)
				end
			end
		else
			current = nil
			base, top = nil, nil
			ring.Parent = nil
			sign.Parent = nil
		end
	end
end

-- (FIRST_2_MIN: Client/FirstTwo uses the same list, the lab finder and the short names.)
LabShowcase.myLab = myLab
LabShowcase.find = find
LabShowcase.where = where
LabShowcase.SHORT = SHORT

-- (STAY_LONGER 3: 10 s before a lab surprise the goal line says so: EventService sets SurpriseAt.)
local function surpriseWarning()
	local warnedFor = 0
	while true do
		task.wait(0.5)
		local at = player:GetAttribute("SurpriseAt")
		if type(at) == "number" and at ~= warnedFor then
			local left = at - Workspace:GetServerTimeNow()
			if left <= 10 and left > 3 then
				warnedFor = at
				pcall(function()
					(require(script.Parent:WaitForChild("HudV3")) :: any).moment("Surprise in " .. math.floor(left + 0.5) .. " s!", 4)
				end)
			end
		end
	end
end

function LabShowcase.start()
	if Config.LAB_SURPRISES then
		task.spawn(surpriseWarning)
	end
	if Config.ATTRACT_MODE then
		task.spawn(attract)
	end
	if Config.TRY_ME then
		task.spawn(tryMe)
	end
end

return LabShowcase
