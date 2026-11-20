--!strict
-- V6-6: birds round the lab and the open-air maps (Config.BIRDS). Client-side only (nothing on the
-- network), pooled real models from ReplicatedStorage.BirdModels (Creator Store, malware pass done):
--   Lab        small birds (pigeons) circling the garden, a hawk gliding high over it
--   Plaza/City pigeons that walk and peck on the ground, and fly when something bangs
--   Island     seagulls over the beach
--   Farm       crows
--   Military   a hawk or two, high
-- Behaviour: a flock steers like boids (keep together, keep apart, follow), wanders round a point
-- that drifts after the player, banks into turns; grounded pigeons peck and hop. A shot or a blast
-- near them (FeelBus Shot / BigHit) scatters them up and away for a few seconds. The hawk's wings
-- beat on its bones; the others bob and bank. Budget per device tier (Config.BIRDS_MAX); birds far
-- from the camera are hidden and not stepped. A quiet birdsong loop plays outdoors (SoundMix Ambient).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local Client = script.Parent

local Birds = {}

Birds.SONG = "rbxassetid://9119383684" -- Sonoma Morning Birds (Pro Sound Effects, Roblox licensed)
Birds.SONG_VOLUME = 0.22
Birds.VIEW = 320 -- studs: past this a bird is hidden and not stepped
Birds.SCATTER_REACH = 70 -- studs from a bang that scatters a flock
Birds.SCATTER_TIME = 4
Birds.HIGH_ROOMS = 500 -- above this the rooms have roofs: no birds, no song

-- Per place: { model, count, height, radius, speed, ground (walking pigeons), size }.
Birds.FLOCKS = table.freeze({
	Lab = { { model = "Pigeon", count = 5, ground = true, radius = 30, speed = 4, size = 2.6 }, { model = "Crow", count = 6, height = 48, radius = 70, speed = 20, size = 1.1 }, { model = "Hawk", count = 1, height = 85, radius = 110, speed = 16, size = 1 } },
	Plaza = { { model = "Pigeon", count = 10, ground = true, radius = 40, speed = 4, size = 2.6 } },
	City = { { model = "Pigeon", count = 12, ground = true, radius = 50, speed = 4, size = 2.6 }, { model = "Crow", count = 5, height = 45, radius = 80, speed = 22, size = 1.1 } },
	Island = { { model = "Gull", count = 7, height = 40, radius = 90, speed = 18, size = 0.22 } },
	Farm = { { model = "Crow", count = 7, height = 50, radius = 90, speed = 20, size = 1.1 } },
	Military = { { model = "Hawk", count = 2, height = 90, radius = 120, speed = 16, size = 1 } },
	Site = { { model = "Crow", count = 5, height = 52, radius = 70, speed = 20, size = 1.1 } },
})

type Bird = {
	model: Model,
	pos: Vector3,
	vel: Vector3,
	phase: number,
	ground: boolean,
	bones: { Bone },
	baseC0: { CFrame },
	feet: number, -- (V7-3: from the pivot down to the lowest point of the model: its feet)
}
type Flock = { def: any, birds: { Bird }, centre: Vector3, scatterUntil: number, scatterFrom: Vector3 }

local player = Players.LocalPlayer
local flocks: { Flock } = {}
local placeNow = ""
local song: Sound? = nil
local rng = Random.new()

local function maxBirds(): number
	local caps = Config.BIRDS_MAX or { pc = 24, tablet = 14, phone = 8 }
	local cam = Workspace.CurrentCamera
	local short = if cam then math.min(cam.ViewportSize.X, cam.ViewportSize.Y) else 720
	if UserInputService.TouchEnabled then
		return if short < 600 then caps.phone else caps.tablet
	end
	return caps.pc
end

local function folder(): Folder
	local f = Workspace:FindFirstChild("ClientBirds")
	if f and f:IsA("Folder") then
		return f
	end
	local new = Instance.new("Folder")
	new.Name = "ClientBirds"
	new.Parent = Workspace
	return new
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local function refreshFilter()
	-- (V7-3: never the birds, a dummy or any player: the real floor or the terrain only.)
	local skip: { Instance } = { folder() }
	for _, pl in Players:GetPlayers() do
		if pl.Character then
			table.insert(skip, pl.Character)
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	params.FilterDescendantsInstances = skip
end

local function makeBird(def: any, at: Vector3): Bird?
	local src = ReplicatedStorage:FindFirstChild("BirdModels")
	local tpl = src and src:FindFirstChild(def.model)
	if not tpl or not tpl:IsA("Model") then
		return nil
	end
	local m = tpl:Clone()
	if def.size and def.size ~= 1 then
		m:ScaleTo(m:GetScale() * def.size)
	end
	-- (Review fix: a bird never collides, is never hit by an aim ray, never simulates.)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
	m.Parent = folder()
	local bones: { Bone } = {}
	local base: { CFrame } = {}
	for _, d in m:GetDescendants() do
		if d:IsA("Bone") and (string.find(d.Name, "UpperArm") or string.find(d.Name, "Clavical")) then
			table.insert(bones, d)
			table.insert(base, d.Transform)
		end
	end
	local dir = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
	return {
		model = m,
		pos = at,
		vel = (if dir.Magnitude > 0.01 then dir.Unit else Vector3.xAxis) * (def.speed or 10),
		phase = rng:NextNumber(0, 6),
		ground = def.ground == true,
		bones = bones,
		baseC0 = base,
		feet = Birds.feetOffset(m),
	}
end

local function clear()
	for _, fl in flocks do
		for _, b in fl.birds do
			b.model:Destroy()
		end
	end
	flocks = {}
end

local function anchorPoint(): Vector3?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r.Position else nil
end

local function build(place: string)
	refreshFilter()
	clear()
	if Config.BIRDS == false then
		return
	end
	local key = if string.sub(place, 1, 3) == "Lab" then "Lab" else place
	local defs = Birds.FLOCKS[key]
	local at = anchorPoint()
	if not defs or not at then
		return
	end
	local budget = maxBirds()
	for _, def in defs do
		local fl: Flock = { def = def, birds = {}, centre = at, scatterUntil = 0, scatterFrom = at }
		local n = math.min(def.count, budget)
		budget -= n
		for _ = 1, n do
			local h = if def.ground then 0.5 else def.height + rng:NextNumber(-6, 6)
			local p = at + Vector3.new(rng:NextNumber(-def.radius, def.radius) * 0.5, h, rng:NextNumber(-def.radius, def.radius) * 0.5)
			local b = makeBird(def, p)
			if b then
				table.insert(fl.birds, b)
			end
		end
		table.insert(flocks, fl)
	end
end

local function scatter(at: Vector3)
	for _, fl in flocks do
		if (fl.centre - at).Magnitude < Birds.SCATTER_REACH + fl.def.radius then
			fl.scatterUntil = os.clock() + Birds.SCATTER_TIME
			fl.scatterFrom = at
		end
	end
end

-- The ground under a point (grounded pigeons stand on it).
local function groundY(p: Vector3, fallback: number): number
	-- (V7-3: a see-through or walk-through part (a sign, a light, a path stone's neighbour) is
	-- not ground: the ray goes on below it, up to 4 times.)
	local from = p + Vector3.new(0, 40, 0)
	for _ = 1, 4 do
		local hit = Workspace:Raycast(from, Vector3.new(0, -160, 0), params)
		if not hit then
			return fallback
		end
		local part = hit.Instance
		if part:IsA("Terrain") or (part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.9) or part.Name == "PathStone" then
			return hit.Position.Y
		end
		from = hit.Position - Vector3.new(0, 0.05, 0)
	end
	return fallback
end

-- How far a model's lowest point is below its pivot (its feet stand on the ground from there).
function Birds.feetOffset(m: Model): number
	local cf, size = m:GetBoundingBox()
	return m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
end

-- (Review fix: a bird's ground is looked up about 7 times a second, not every frame.)
local groundCache: { [any]: { y: number, at: number } } = setmetatable({}, { __mode = "k" }) :: any
local function cachedGround(b: any, p: Vector3, fallback: number): number
	local c = groundCache[b]
	local now = os.clock()
	if c and now - c.at < 0.15 then
		return c.y
	end
	local y = groundY(p, fallback)
	groundCache[b] = { y = y, at = now }
	return y
end

local function step(dt: number)
	local cam = Workspace.CurrentCamera
	if not cam or #flocks == 0 then
		return
	end
	local camPos = cam.CFrame.Position
	local anchor = anchorPoint()
	local now = os.clock()
	for _, fl in flocks do
		local def = fl.def
		if anchor then
			-- (The flock's point drifts after the player, slowly: they live round the place.)
			fl.centre = fl.centre:Lerp(anchor, math.clamp(dt * 0.08, 0, 1))
		end
		local scattering = now < fl.scatterUntil
		-- Flock centre and heading.
		local sum, head = Vector3.zero, Vector3.zero
		for _, b in fl.birds do
			sum += b.pos
			head += b.vel
		end
		local n = math.max(1, #fl.birds)
		local mid = sum / n
		for i, b in fl.birds do
			local far = (b.pos - camPos).Magnitude > Birds.VIEW
			local wantParent = if far then nil else folder()
			if b.model.Parent ~= wantParent then
				b.model.Parent = wantParent
			end
			if far then
				continue
			end
			b.phase += dt
			if b.ground and not scattering then
				-- Walk, peck, stop: a little random stroll near the centre, on the ground.
				local toCentre = Vector3.new(fl.centre.X - b.pos.X, 0, fl.centre.Z - b.pos.Z)
				if math.sin(b.phase * 0.7 + i) > 0.3 then
					local wander = Vector3.new(math.noise(b.phase * 0.2, i), 0, math.noise(i, b.phase * 0.2))
					local want = (wander * 2 + (if toCentre.Magnitude > def.radius then toCentre.Unit else Vector3.zero))
					b.vel = if want.Magnitude > 0.01 then want.Unit * def.speed else Vector3.zero
				else
					b.vel = Vector3.zero
				end
				local p = b.pos + b.vel * dt
				-- (Back from the air it glides down, never pops to the ground.)
				local gy = cachedGround(b, p, p.Y - b.feet) + b.feet + 0.02 -- (V7-3: feet on the ground, not the pivot)
				p = Vector3.new(p.X, math.max(gy, b.pos.Y - 12 * dt), p.Z)
				b.pos = p
				local look = if b.vel.Magnitude > 0.1 then b.vel.Unit else b.model:GetPivot().LookVector
				local peck = if b.vel.Magnitude < 0.1 then CFrame.Angles(math.max(0, math.sin(b.phase * 9)) * -0.5, 0, 0) else CFrame.new()
				b.model:PivotTo(CFrame.lookAt(p, p + Vector3.new(look.X, 0, look.Z)) * peck)
				continue
			end
			-- Flying: boids-lite round the flock's point, high; scattering = up and away.
			local target = fl.centre + Vector3.new(math.cos(b.phase * 0.25 + i) * def.radius, (def.height or 30), math.sin(b.phase * 0.25 + i) * def.radius)
			local steer = (target - b.pos) * 0.04 + (mid - b.pos) * 0.02 + (head / n - b.vel) * 0.05
			for j, o in fl.birds do
				if j ~= i then
					local d = b.pos - o.pos
					if d.Magnitude < 5 and d.Magnitude > 0.01 then
						steer += d.Unit * 2
					end
				end
			end
			if scattering then
				local away = b.pos - fl.scatterFrom
				steer += (if away.Magnitude > 0.01 then away.Unit else Vector3.yAxis) * 8 + Vector3.new(0, 6, 0)
				b.ground = false
			elseif def.ground and now > fl.scatterUntil + 6 then
				b.ground = true -- (pigeons come back down a while after the bang)
			end
			local speed = def.speed * (if scattering then 2 else 1)
			b.vel = (b.vel + steer * dt * 10)
			if b.vel.Magnitude > speed then
				b.vel = b.vel.Unit * speed
			end
			b.pos += b.vel * dt
			local floor = cachedGround(b, b.pos, -math.huge) + 8
			if b.pos.Y < floor then
				b.pos = Vector3.new(b.pos.X, floor, b.pos.Z)
			end
			local fwd = if b.vel.Magnitude > 0.1 then b.vel.Unit else Vector3.zAxis
			local bank = math.clamp(steer:Dot(fwd:Cross(Vector3.yAxis)) * -0.05, -0.6, 0.6)
			local bob = math.sin(b.phase * 6) * 0.25
			b.model:PivotTo(CFrame.lookAt(b.pos + Vector3.new(0, bob, 0), b.pos + fwd) * CFrame.Angles(0, 0, bank))
			-- Wing beats on the hawk's bones (gliding most of the time, beats now and then).
			if #b.bones > 0 then
				local beat = if math.sin(b.phase * 0.6) > 0.2 or scattering then math.sin(b.phase * 14) * 0.6 else 0.05
				for k, bone in b.bones do
					local side = if string.find(bone.Name, "Left") then 1 else -1
					bone.Transform = b.baseC0[k] * CFrame.Angles(0, 0, beat * side)
				end
			end
		end
	end
end

local function updateSong()
	local s = song
	if not s then
		return
	end
	local cam = Workspace.CurrentCamera
	local high = cam ~= nil and cam.CFrame.Position.Y > Birds.HIGH_ROOMS
	local want = not high and #flocks > 0
	if want and not s.IsPlaying then
		s:Play()
	elseif not want and s.IsPlaying then
		s:Stop()
	end
end

function Birds.start()
	if Config.BIRDS == false then
		return
	end
	local s = Instance.new("Sound")
	s.Name = "Birdsong"
	s.SoundId = Birds.SONG
	s.Looped = true
	s.Volume = Birds.SONG_VOLUME
	pcall(function()
		local SoundMix = require(Client:WaitForChild("SoundMix")) :: any
		s.SoundGroup = SoundMix.group("Ambient")
	end)
	s.Parent = SoundService
	song = s
	local function onPlace()
		local p = player:GetAttribute("Place")
		local place = if type(p) == "string" then p else "Lab"
		if place ~= placeNow then
			placeNow = place
			task.delay(1.5, function() -- (after the arrival: the body is there)
				if placeNow == place then
					build(place)
				end
			end)
		end
	end
	player:GetAttributeChangedSignal("Place"):Connect(onPlace)
	player.CharacterAdded:Connect(function()
		task.delay(2, function()
			build(placeNow)
		end)
	end)
	onPlace()
	pcall(function()
		local FeelBus = require(Client:WaitForChild("FeelBus")) :: any
		FeelBus.on("BigHit", function(d: any)
			if type(d) == "table" and typeof(d.position) == "Vector3" then
				scatter(d.position)
			end
		end)
		FeelBus.on("Shot", function()
			local a = anchorPoint()
			if a then
				scatter(a)
			end
		end)
	end)
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		step(math.min(dt, 0.1))
		acc += dt
		if acc > 1 then
			acc = 0
			updateSong()
		end
	end)
end

-- (For T104: how many birds are out now.)
function Birds.countForTest(): number
	local n = 0
	for _, fl in flocks do
		n += #fl.birds
	end
	return n
end

return Birds
