--!strict
-- v4 C4 (owner: "many more unpredictable things"): eleven new lab events, all cartoon and kid-safe,
-- built by code and cheap enough for a phone (a few parts each, the server moves anchored parts and
-- knocks bodies through DummyControl, as Creatures does):
--   UfoBeam          a saucer drifts over the lab and beams dummies up, then drops them
--   BowlingAvalanche giant bowling balls roll through the lab in lanes
--   RocketRain       little fireworks rockets rain down and pop dummies about
--   MagnetStorm      a huge magnet pulls every dummy in, then lets go with a bang
--   LightningStorm   a storm cloud throws bolts that fling dummies
--   Sinkhole         a hole opens, sucks dummies in and spits them sky-high
--   Earthquake       the lab shakes and everything hops about
--   FanBlast         a giant fan blows the whole lab across the floor
--   MoonGravity      a moon rises and dummies float as if on the moon
--   BalloonDrop      a hot-air balloon drifts over and drops guest dummies
--   GiantDummy       a giant dummy walks in to be knocked down
-- Each `Surprises.<id>(center, owner)` returns the event's stop function. `center` is the lab's
-- middle at floor height (EventService.labMiddle). Surprises.mini runs a short one by itself now and
-- then in a player's lab (Config.LAB_SURPRISES), so no two minutes are the same.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent
local Creatures = require(Systems.Creatures)
local DummyControl = require(Systems.DummyControl)
local DummyFactory = require(Systems.DummyFactory)
local FxService = require(Systems.FxService)

local U = Creatures.util
local block, folder, knock, knockPlayers, dummiesIn = U.block, U.folder, U.knock, U.knockPlayers, U.dummiesIn

local Surprises = {}

Surprises.HALF = Creatures.HALF -- studs either side of the lab's middle
Surprises.Z_MIN, Surprises.Z_MAX = -85, 65

type Stop = () -> ()
local rng = Random.new()

local function spot(center: Vector3, margin: number?): Vector3
	local m = margin or 8
	return center + Vector3.new(rng:NextNumber(-Surprises.HALF + m, Surprises.HALF - m), 0, rng:NextNumber(Surprises.Z_MIN + m, Surprises.Z_MAX - m))
end

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = folder()
	return m
end

local function neon(p: BasePart): BasePart
	p.Material = Enum.Material.Neon
	return p
end

-- A run loop: calls `tick(dt, t)` every heartbeat until stopped; returns the stop function.
local function run(made: { Instance }, tick: (number, number) -> ()): Stop
	local running = true
	local t0 = os.clock()
	task.spawn(function()
		local last = os.clock()
		while running do
			local now = os.clock()
			local ok, err = pcall(tick, now - last, now - t0)
			if not ok then
				warn("[Surprises] " .. tostring(err))
				break
			end
			last = now
			RunService.Heartbeat:Wait()
		end
	end)
	return function()
		running = false
		for _, x in made do
			if x.Parent then
				x:Destroy()
			end
		end
	end
end

-- Every `gap` seconds inside a tick (returns true when it is time).
local function every(gap: number): (number) -> boolean
	local nextAt = 0
	return function(t: number): boolean
		if t >= nextAt then
			nextAt = t + gap
			return true
		end
		return false
	end
end

local function lift(m: Model, dv: Vector3)
	DummyControl.nudge(m, dv)
end

------------------------------------------------------------------------------------------------
-- UFO beam

function Surprises.UfoBeam(center: Vector3): Stop
	local ufo = model("Ufo")
	local h = 40
	local base = CFrame.new(center + Vector3.new(0, h, 0))
	block(ufo, "Disc", Vector3.new(2.2, 28, 28), base * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 158, 170), Enum.PartType.Cylinder).Material = Enum.Material.Metal
	block(ufo, "Rim", Vector3.new(1, 31, 31), base * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 96, 108), Enum.PartType.Cylinder).Material = Enum.Material.Metal
	local dome = block(ufo, "Dome", Vector3.new(12, 12, 12), base * CFrame.new(0, 2, 0), Color3.fromRGB(140, 230, 255), Enum.PartType.Ball)
	dome.Material = Enum.Material.Glass
	dome.Transparency = 0.35
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		neon(block(ufo, "Light", Vector3.new(1.4, 1.4, 1.4), base * CFrame.new(math.cos(a) * 14, -0.7, math.sin(a) * 14), if i % 2 == 0 then Color3.fromRGB(120, 255, 160) else Color3.fromRGB(255, 230, 90), Enum.PartType.Ball))
	end
	local beam = neon(block(ufo, "Beam", Vector3.new(h, 16, 16), CFrame.new(center + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(140, 255, 170), Enum.PartType.Cylinder))
	beam.Transparency = 0.75
	FxService.hit(center + Vector3.new(0, h, 0), 30, "BlackHole")
	local from, to = center, spot(center, 14)
	local legT, leg = 0, 4
	local pulse = every(0.15)
	local zap = every(1.4)
	local yank = every(1.6)
	local done: { [Player]: boolean } = {}
	return run({ ufo }, function(dt, t)
		legT += dt
		if legT >= leg then
			legT = 0
			from, to = to, spot(center, 14)
		end
		local k = legT / leg
		local at = from:Lerp(to, k * k * (3 - 2 * k))
		local wobble = math.sin(t * 2) * 1.2
		ufo:PivotTo(CFrame.new(at + Vector3.new(0, h + wobble, 0)) * CFrame.Angles(0, t * 1.5, 0))
		local on = (t % 5) < 3.8 -- (the beam blinks off now and then: everything drops)
		beam.Transparency = if on then 0.72 else 1
		beam.CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		if on and pulse(t) then
			for _, d in dummiesIn(center) do
				local o = d.pelvis.Position - at
				if Vector3.new(o.X, 0, o.Z).Magnitude < 8 and o.Y < h - 6 then
					lift(d.model, Vector3.new(-o.X * 0.4, 14, -o.Z * 0.4))
				end
			end
		end
		if on and yank(t) then
			table.clear(done)
			knockPlayers(at, 7, 30, 3, center, done)
		end
		if zap(t) then
			FxService.hit(at + Vector3.new(0, h - 2, 0), 20, "Zap")
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Bowling avalanche

function Surprises.BowlingAvalanche(center: Vector3): Stop
	local made: { Instance } = {}
	local balls: { { part: BasePart, x: number, z: number, speed: number, start: number } } = {}
	local colors = { Color3.fromRGB(30, 30, 36), Color3.fromRGB(170, 30, 40), Color3.fromRGB(30, 70, 170), Color3.fromRGB(40, 120, 60) }
	local m = model("Bowling")
	table.insert(made, m)
	for i = 1, 9 do
		local x = -Surprises.HALF + 8 + (i - 1) * ((Surprises.HALF * 2 - 16) / 8)
		local p = block(m, "BowlingBall", Vector3.new(9, 9, 9), CFrame.new(center + Vector3.new(x, -50, 0)), colors[(i % #colors) + 1], Enum.PartType.Ball)
		p.Material = Enum.Material.Glass
		p.Reflectance = 0.15
		table.insert(balls, { part = p, x = x, z = Surprises.Z_MIN - 15, speed = rng:NextNumber(32, 46), start = rng:NextNumber(0, 2.5) })
	end
	FxService.hit(center + Vector3.new(0, 4, Surprises.Z_MIN), 60, "Cannon")
	local hitOnce: { [Model]: number } = {}
	local done: { [Player]: boolean } = {}
	return run(made, function(_dt, t)
		for _, b in balls do
			local run = math.max(0, t - b.start)
			local z = b.z + run * b.speed
			if z > Surprises.Z_MAX + 20 then
				b.part.Transparency = 1
				continue
			end
			local at = center + Vector3.new(b.x, 4.5, z)
			b.part.CFrame = CFrame.new(at) * CFrame.Angles(z / 4.5, 0, 0)
			for _, d in dummiesIn(center) do
				local o = d.pelvis.Position - at
				if Vector3.new(o.X, 0, o.Z).Magnitude < 6.5 and (hitOnce[d.model] or 0) < t - 1 then
					hitOnce[d.model] = t
					knock(d.model, at - Vector3.new(0, 0, 3), 80, 0.9)
					FxService.hit(d.pelvis.Position, 60, "Anvil")
				end
			end
			knockPlayers(at, 6, 70, 0.8, center, done)
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Rocket rain (little fireworks rockets)

function Surprises.RocketRain(center: Vector3): Stop
	local made: { Instance } = {}
	local drop = every(0.28)
	local rockets: { { m: Model, from: Vector3, to: Vector3, t0: number } } = {}
	return run(made, function(_dt, t)
		if drop(t) then
			local to = spot(center, 6)
			local from = to + Vector3.new(rng:NextNumber(-20, 20), 120, rng:NextNumber(-20, 20))
			local m = model("Rocket")
			table.insert(made, m)
			local look = CFrame.lookAt(from, to)
			block(m, "Body", Vector3.new(0.9, 0.9, 3.4), look, Color3.fromHSV(rng:NextNumber(), 0.75, 1))
			neon(block(m, "Nose", Vector3.new(0.7, 0.7, 0.9), look * CFrame.new(0, 0, -2.1), Color3.fromRGB(255, 240, 200)))
			local flame = neon(block(m, "Flame", Vector3.new(0.6, 0.6, 1.6), look * CFrame.new(0, 0, 2.4), Color3.fromRGB(255, 160, 40)))
			local sparks = Instance.new("Sparkles")
			sparks.SparkleColor = Color3.fromRGB(255, 210, 120)
			sparks.Parent = flame
			table.insert(rockets, { m = m, from = from, to = to, t0 = t })
		end
		for i = #rockets, 1, -1 do
			local r = rockets[i]
			local a = math.min(1, (t - r.t0) / 1.1)
			r.m:PivotTo(CFrame.lookAt(r.from:Lerp(r.to + Vector3.new(0, 1, 0), a), r.to))
			if a >= 1 then
				table.remove(rockets, i)
				r.m:Destroy()
				FxService.hit(r.to + Vector3.new(0, 1, 0), 60, "Firecracker")
				for _, d in dummiesIn(center) do
					if (d.pelvis.Position - r.to).Magnitude < 9 then
						knock(d.model, r.to, 70, 1.5)
					end
				end
				knockPlayers(r.to, 7, 55, 1.4, center)
			end
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Magnet storm

function Surprises.MagnetStorm(center: Vector3): Stop
	local m = model("Magnet")
	local top = CFrame.new(center + Vector3.new(0, 30, -10))
	local red, steel = Color3.fromRGB(205, 40, 40), Color3.fromRGB(200, 204, 210)
	block(m, "Bridge", Vector3.new(16, 5, 5), top, red)
	block(m, "ArmL", Vector3.new(5, 12, 5), top * CFrame.new(-5.5, -8.5, 0), red)
	block(m, "ArmR", Vector3.new(5, 12, 5), top * CFrame.new(5.5, -8.5, 0), red)
	block(m, "TipL", Vector3.new(5.2, 3, 5.2), top * CFrame.new(-5.5, -16, 0), steel).Material = Enum.Material.Metal
	block(m, "TipR", Vector3.new(5.2, 3, 5.2), top * CFrame.new(5.5, -16, 0), steel).Material = Enum.Material.Metal
	local core = (top * CFrame.new(0, -16, 0)).Position
	FxService.hit(core, 30, "BlackHole")
	local pull = every(0.2)
	local phase = -1
	return run({ m }, function(_dt, t)
		m:PivotTo(top * CFrame.new(0, math.sin(t * 3) * 0.6, 0) * CFrame.Angles(0, 0, math.sin(t * 9) * 0.04))
		local cycle = math.floor(t / 4.5)
		local inPull = (t % 4.5) < 3.5
		if inPull and pull(t) then
			for _, d in dummiesIn(center) do
				local o = core - d.pelvis.Position
				if o.Magnitude > 4 and o.Magnitude < 80 then
					lift(d.model, o.Unit * 9 + Vector3.new(0, 4, 0))
				end
			end
		end
		if not inPull and cycle ~= phase then
			phase = cycle
			FxService.hit(core, 120, "Shockwave")
			for _, d in dummiesIn(center) do
				if (d.pelvis.Position - core).Magnitude < 30 then
					knock(d.model, core, 75, 0.6)
				end
			end
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Lightning storm (a cartoon storm cloud over the lab)

function Surprises.LightningStorm(center: Vector3): Stop
	local cloud = model("StormCloud")
	local h = 55
	for i = 1, 9 do
		local p = block(cloud, "Puff", Vector3.one * rng:NextNumber(16, 26), CFrame.new(center + Vector3.new(rng:NextNumber(-34, 34), h + rng:NextNumber(-2, 4), rng:NextNumber(-40, 30))), Color3.fromRGB(70, 74, 86), Enum.PartType.Ball)
		p.Material = Enum.Material.SmoothPlastic
		p.Transparency = 0.1
		p.CastShadow = false
	end
	local made: { Instance } = { cloud }
	local strike = every(0.7)
	return run(made, function(_dt, t)
		cloud:PivotTo(CFrame.new(center + Vector3.new(math.sin(t * 0.5) * 8, 0, 0)) * CFrame.new(-center))
		if not strike(t) then
			return
		end
		-- Aim at a dummy half the time (more fun), else a random spot.
		local target = spot(center, 6)
		local bodies = dummiesIn(center)
		if #bodies > 0 and rng:NextNumber() < 0.5 then
			target = bodies[rng:NextInteger(1, #bodies)].pelvis.Position
			target = Vector3.new(target.X, center.Y, target.Z)
		end
		local bolt = model("Bolt")
		local last = target + Vector3.new(0, h, 0)
		for s = 1, 6 do
			local nextP = if s == 6 then target else target + Vector3.new(rng:NextNumber(-4, 4), h * (1 - s / 6), rng:NextNumber(-4, 4))
			local len = (nextP - last).Magnitude
			neon(block(bolt, "Seg", Vector3.new(0.6, 0.6, len), CFrame.lookAt((last + nextP) / 2, nextP), Color3.fromRGB(230, 240, 255)))
			last = nextP
		end
		task.delay(0.22, function()
			bolt:Destroy()
		end)
		FxService.hit(target + Vector3.new(0, 1, 0), 90, "Zap")
		for _, d in bodies do
			if (d.pelvis.Position - target).Magnitude < 9 then
				knock(d.model, target, 75, 1.6)
			end
		end
		knockPlayers(target, 6, 50, 1.4, center)
	end)
end

------------------------------------------------------------------------------------------------
-- Sinkhole: a hole that pulls dummies in and spits them out sky-high

function Surprises.Sinkhole(center: Vector3): Stop
	local m = model("Sinkhole")
	local at = spot(center, 22)
	local hole = block(m, "Hole", Vector3.new(0.3, 1, 1), CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(14, 12, 16), Enum.PartType.Cylinder)
	local lip = block(m, "Lip", Vector3.new(0.2, 1, 1), CFrame.new(at + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(95, 75, 55), Enum.PartType.Cylinder)
	lip.Material = Enum.Material.Ground
	FxService.hit(at, 50, "Shockwave")
	local pull = every(0.2)
	local spat = false
	local hopAt = 0
	return run({ m }, function(_dt, t)
		local cycle = t % 8 -- grow 0-1.5, suck to 6, spit at 6, rest; a new hole after
		local size = math.clamp(cycle / 1.5, 0, 1) * 22
		if cycle > 6.5 then
			size = 22 * math.clamp(1 - (cycle - 6.5) / 1.2, 0, 1)
		end
		hole.Size = Vector3.new(0.3, math.max(1, size), math.max(1, size))
		lip.Size = Vector3.new(0.2, math.max(1, size + 3), math.max(1, size + 3))
		if cycle < 6 then
			spat = false
			if pull(t) then
				for _, d in dummiesIn(center) do
					local o = at - d.pelvis.Position
					local flat = Vector3.new(o.X, 0, o.Z)
					if flat.Magnitude < size / 2 + 14 and flat.Magnitude > 1.5 then
						lift(d.model, flat.Unit * 8)
					end
				end
			end
		elseif not spat then
			spat = true
			FxService.hit(at + Vector3.new(0, 2, 0), 150, "SpringPad")
			for _, d in dummiesIn(center) do
				local o = d.pelvis.Position - at
				if Vector3.new(o.X, 0, o.Z).Magnitude < size / 2 + 6 then
					knock(d.model, at, 60, 4)
				end
			end
			knockPlayers(at, size / 2 + 4, 60, 3, center)
		end
		if cycle > 7.8 and t > hopAt then
			hopAt = t + 1
			at = spot(center, 22)
			hole.CFrame = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
			lip.CFrame = CFrame.new(at + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Earthquake

function Surprises.Earthquake(center: Vector3): Stop
	local made: { Instance } = {}
	local hop = every(0.35)
	local rumble = every(1.6)
	local crack = every(0.9)
	local cracks = model("Cracks")
	table.insert(made, cracks)
	return run(made, function(_dt, t)
		local k = math.clamp(math.min(t / 2, 1), 0, 1) -- builds up
		if hop(t) then
			for _, d in dummiesIn(center) do
				lift(d.model, Vector3.new(rng:NextNumber(-10, 10) * k, rng:NextNumber(10, 22) * k, rng:NextNumber(-10, 10) * k))
			end
		end
		if rumble(t) then
			FxService.hit(spot(center, 10), 70, "Shockwave")
		end
		if crack(t) and #cracks:GetChildren() < 14 then
			local at = spot(center, 6)
			local c = block(cracks, "Crack", Vector3.new(rng:NextNumber(0.4, 0.7), 0.1, rng:NextNumber(8, 18)), CFrame.new(at + Vector3.new(0, 0.07, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Color3.fromRGB(28, 24, 22))
			c.Material = Enum.Material.Slate
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Giant fan

function Surprises.FanBlast(center: Vector3): Stop
	local m = model("GiantFan")
	local side = if rng:NextNumber() < 0.5 then -1 else 1
	local at = center + Vector3.new(side * (Surprises.HALF - 4), 13, -10)
	local face = CFrame.lookAt(at, at - Vector3.new(side, 0, 0))
	local frame = Color3.fromRGB(60, 64, 72)
	block(m, "Cage", Vector3.new(26, 26, 2), face * CFrame.new(0, 0, 1), frame).Transparency = 0.6
	block(m, "Ring", Vector3.new(2, 27, 27), face * CFrame.Angles(0, math.rad(90), 0), frame, Enum.PartType.Cylinder).Material = Enum.Material.Metal
	block(m, "Stand", Vector3.new(4, 13, 6), face * CFrame.new(0, -13, 2), frame)
	local hub = block(m, "Hub", Vector3.new(3, 3, 3), face, Color3.fromRGB(220, 60, 50), Enum.PartType.Ball)
	local blades: { BasePart } = {}
	for i = 1, 4 do
		local b = block(m, "Blade", Vector3.new(4, 11, 0.4), face, Color3.fromRGB(230, 232, 236))
		b.Material = Enum.Material.Metal
		table.insert(blades, b)
	end
	FxService.hit(at, 40, "Machine")
	local blow = every(0.2)
	local whoosh = every(2.2)
	local gust = every(3)
	local spin = 0
	return run({ m }, function(dt, t)
		local power = math.clamp(t / 2, 0, 1)
		spin += dt * 14 * power
		for i, b in blades do
			b.CFrame = face * CFrame.Angles(0, 0, spin + i * math.pi / 2) * CFrame.new(0, 6, -0.4) * CFrame.Angles(0.25, 0, 0)
		end
		hub.CFrame = face * CFrame.new(0, 0, -0.6)
		if blow(t) then
			for _, d in dummiesIn(center) do
				lift(d.model, Vector3.new(-side * 9 * power, 2.5 * power, 0))
			end
		end
		if whoosh(t) then
			FxService.hit(at, 40, "Throw")
		end
		if gust(t) and power >= 1 then
			knockPlayers(at - Vector3.new(side * 30, 0, 0), 30, 40, 0.5, center)
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Moon gravity

function Surprises.MoonGravity(center: Vector3): Stop
	local m = model("Moon")
	local moon = block(m, "Moon", Vector3.new(40, 40, 40), CFrame.new(center + Vector3.new(30, -30, -160)), Color3.fromRGB(225, 225, 215), Enum.PartType.Ball)
	moon.Material = Enum.Material.Slate
	moon.CastShadow = false
	for i = 1, 5 do
		local c = block(m, "Crater", Vector3.new(1, 1, 1) * rng:NextNumber(5, 10), moon.CFrame * CFrame.new(rng:NextNumber(-12, 12), rng:NextNumber(-12, 12), 17), Color3.fromRGB(190, 190, 182), Enum.PartType.Ball)
		c.Material = Enum.Material.Slate
		c.CastShadow = false
	end
	local float = every(0.1)
	local g = Workspace.Gravity
	local rise = moon.Position
	FxService.hit(center + Vector3.new(0, 4, 0), 30, "Balloon")
	return run({ m }, function(_dt, t)
		local k = math.clamp(t / 3, 0, 1)
		m:PivotTo(CFrame.new(rise:Lerp(rise + Vector3.new(0, 110, 0), k * k * (3 - 2 * k))) * CFrame.Angles(0, t * 0.05, 0))
		if float(t) then
			for _, d in dummiesIn(center) do
				-- (Five sixths of gravity cancelled, as on the moon.)
				lift(d.model, Vector3.new(0, g * 0.1 * 0.83 * k, 0))
			end
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Hot-air balloon drop

Surprises.BALLOON_DUMMIES = 5

function Surprises.BalloonDrop(center: Vector3, owner: Player?): Stop
	local m = model("HotAirBalloon")
	local stripes = { Color3.fromRGB(230, 70, 60), Color3.fromRGB(250, 205, 60), Color3.fromRGB(60, 140, 220) }
	local function build(at: CFrame)
		m:ClearAllChildren()
		block(m, "Envelope", Vector3.new(22, 22, 22), at * CFrame.new(0, 16, 0), stripes[1], Enum.PartType.Ball)
		block(m, "Band", Vector3.new(4, 22.6, 22.6), at * CFrame.new(0, 16, 0) * CFrame.Angles(0, 0, math.rad(90)), stripes[2], Enum.PartType.Cylinder)
		block(m, "Band2", Vector3.new(2.5, 18, 18), at * CFrame.new(0, 9, 0) * CFrame.Angles(0, 0, math.rad(90)), stripes[3], Enum.PartType.Cylinder)
		local basket = block(m, "Basket", Vector3.new(6, 4, 6), at * CFrame.new(0, -2, 0), Color3.fromRGB(150, 105, 60))
		basket.Material = Enum.Material.WoodPlanks
		for _, x in { -2.6, 2.6 } do
			for _, z in { -2.6, 2.6 } do
				block(m, "Rope", Vector3.new(0.2, 8, 0.2), at * CFrame.new(x, 3.5, z), Color3.fromRGB(90, 70, 50))
			end
		end
	end
	build(CFrame.new())
	local h = 42
	local from = center + Vector3.new(-Surprises.HALF - 20, h, rng:NextNumber(-40, 20))
	local to = center + Vector3.new(Surprises.HALF + 20, h, rng:NextNumber(-40, 20))
	local guests: { Instance } = { m }
	local dropped = 0
	local drop = every(2)
	local cross = 14
	return run(guests, function(_dt, t)
		local k = math.clamp(t / cross, 0, 1)
		local at = from:Lerp(to, k) + Vector3.new(0, math.sin(t * 1.3) * 1.5, 0)
		m:PivotTo(CFrame.new(at))
		local inside = math.abs(at.X - center.X) < Surprises.HALF - 10
		if inside and t > 1.5 and dropped < Surprises.BALLOON_DUMMIES and drop(t) then
			dropped += 1
			local ok, body = pcall(DummyFactory.spawn, at - Vector3.new(0, 5, 0), at + Vector3.new(0, -5, 4), owner)
			if ok and body then
				body:SetAttribute("NoCredit", true)
				table.insert(guests, body)
				FxService.hit(at - Vector3.new(0, 3, 0), 20, "BalloonPop")
			end
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Giant dummy

function Surprises.GiantDummy(center: Vector3, owner: Player?): Stop
	local at = center + Vector3.new(0, 4, Surprises.Z_MIN + 10)
	local ok, body = pcall(DummyFactory.spawn, at, center + Vector3.new(0, 4, 0), owner)
	local made: { Instance } = {}
	if ok and body then
		body:SetAttribute("NoCredit", true)
		pcall(function()
			body:ScaleTo(2.6)
		end)
		body:SetAttribute("Mass", ((body:GetAttribute("Mass") :: number?) or 10) * 14)
		body:SetAttribute("Home", center + Vector3.new(0, 4, 0))
		table.insert(made, body)
		FxService.hit(at, 120, "Anvil")
	end
	local stomp = every(0.9)
	return run(made, function(_dt, t)
		if body and body.Parent and stomp(t) then
			local pelvis = body:FindFirstChild("LowerTorso")
			if pelvis and pelvis:IsA("BasePart") and pelvis.AssemblyLinearVelocity.Magnitude > 2 then
				FxService.hit(pelvis.Position - Vector3.new(0, 4, 0), 25, "Land")
			end
		end
	end)
end

------------------------------------------------------------------------------------------------
-- The short surprises that happen by themselves (Config.LAB_SURPRISES).

Surprises.MINI = table.freeze({ "RocketRain", "LightningStorm", "UfoBeam", "Earthquake", "FanBlast", "MoonGravity", "Sinkhole" })
Surprises.MINI_TIME = 7 -- s

function Surprises.mini(center: Vector3, owner: Player?, id: string?): string
	local pick = id or Surprises.MINI[rng:NextInteger(1, #Surprises.MINI)]
	local fn = (Surprises :: any)[pick] :: (Vector3, Player?) -> Stop
	local stop = fn(center, owner)
	task.delay(Surprises.MINI_TIME, stop)
	return pick
end

-- (Players is used by the tests' helpers below.)
function Surprises.anyPlayer(): Player?
	return Players:GetPlayers()[1]
end

return Surprises
