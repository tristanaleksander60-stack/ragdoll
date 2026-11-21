--!strict
-- V9-P0 (owner, 21 Nov 2026: "make the BEST physics on all of Roblox"): the physics test bench. A fixed
-- set of repeatable scenes on a bench floor of its own, high over the map (nothing else near), with
-- server-simulated dummies (no owner: the same ActiveRagdoll code as everywhere), each measured:
--   * peak speed and spikes over the scene's cap (an "explosion");
--   * interpenetration: frames with a body part's middle under the floor's top;
--   * time to settle: from the hardest moment (the impact, the launch) until every part stays under
--     SETTLE_SPEED for SETTLE_HOLD s;
--   * jitter at rest: mean linear / angular speed over JITTER_TIME s once settled;
--   * the server's physics step time (Stats) during the scene.
-- T183_PhysicsBench runs it with targets; an owner can run it in Studio (ServerStorage attribute
-- PhysicsBench = true) and read the numbers in the output. docs/PHYSICS.md keeps the baseline.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PhysicsBench = {}

PhysicsBench.ORIGIN = Vector3.new(0, 900, -900) -- the bench floor's top middle (far from every map)
PhysicsBench.SETTLE_SPEED = 1.5 -- studs/s
PhysicsBench.SETTLE_HOLD = 0.5 -- s
PhysicsBench.JITTER_TIME = 2 -- s
PhysicsBench.TIMEOUT = 12 -- s a scene may take to settle
PhysicsBench.MIN_WATCH = 1.2 -- s: a scene is never "settled" before its body has moved or this long has passed

export type Result = {
	name: string,
	peak: number, -- studs/s
	spikes: number, -- frames over the scene's cap
	cap: number,
	sunk: number, -- frames with a part's middle under the floor
	settle: number?, -- s from the moment of the action to rest (nil: never settled)
	jitter: number, -- mean studs/s at rest
	spin: number, -- mean rad/s at rest
	physicsMs: number, -- the server's mean physics step during the scene (0 when Stats has none)
	bodies: number,
	state: string, -- the first body's RagdollState and Vital at the end
	trace: string, -- the fastest part every 0.25 s until settled (what keeps it moving)
}

local folder: Folder? = nil

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

-- The bench: a thick floor (no fall-through), a low wall at one side, and a flight of stairs.
function PhysicsBench.build()
	PhysicsBench.clear()
	local f = Instance.new("Folder")
	f.Name = "PhysicsBench"
	f.Parent = Workspace
	folder = f
	local o = PhysicsBench.ORIGIN
	part("BenchFloor", Vector3.new(200, 8, 200), CFrame.new(o - Vector3.new(0, 4, 0)), Color3.fromRGB(205, 198, 186), Enum.Material.Grass) -- (the lab's real collision floor: the Baseplate, Grass)
	-- Stairs: 10 steps of 1.2 up and 2 deep, going down towards -Z from a landing at z -40.
	for i = 0, 9 do
		local h = (10 - i) * 1.2
		part("Step" .. i, Vector3.new(10, h, 2), CFrame.new(o + Vector3.new(-40, h / 2, -40 + i * 2)), Color3.fromRGB(170, 170, 176))
	end
	part("Landing", Vector3.new(10, 12, 8), CFrame.new(o + Vector3.new(-40, 6, -45)), Color3.fromRGB(170, 170, 176))
	return f
end

function PhysicsBench.clear()
	if folder then
		folder:Destroy()
	end
	folder = nil
	for _, d in Workspace:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("BenchBody") == true then
			d:Destroy()
		end
	end
end

local function physicsMs(): number
	local ok, v = pcall(function()
		return (game:GetService("Stats") :: any).PhysicsStepTimeMs
	end)
	return if ok and type(v) == "number" then v else 0
end

-- A server-simulated dummy (no owner) at `at`, facing -Z, marked as a bench body.
function PhysicsBench.body(at: Vector3, lift: number?): Model
	local DummyFactory = require(script.Parent.Parent.Parent:WaitForChild("Systems"):WaitForChild("DummyFactory")) :: any
	local m = DummyFactory.spawn(at, at - Vector3.zAxis, nil, lift) -- (lift: studs over the ground under it)
	m:SetAttribute("BenchBody", true)
	return m
end

-- Watches `bodies` from now: the action has just happened. Returns the numbers.
function PhysicsBench.watch(name: string, bodies: { Model }, cap: number): Result
	local floorTop = PhysicsBench.ORIGIN.Y
	local r: Result = { name = name, peak = 0, spikes = 0, cap = cap, sunk = 0, settle = nil, jitter = 0, spin = 0, physicsMs = 0, bodies = #bodies, state = "", trace = "" }
	local parts: { BasePart } = {}
	for _, m in bodies do
		for _, d in m:GetChildren() do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				table.insert(parts, d)
			end
		end
	end
	local t0 = os.clock()
	local stillSince: number? = nil
	local lastTrace = 0
	local peakAt = t0 -- (the hardest moment: the impact or the launch; settling counts from there)
	local msSum, msN = 0, 0
	while os.clock() - t0 < PhysicsBench.TIMEOUT do
		RunService.Heartbeat:Wait()
		-- (Kept out cold the whole scene: VitalsService may wake a body a blast hurt.)
		for _, m in bodies do
			if m.Parent and m:GetAttribute("Vital") ~= "Unconscious" then
				m:SetAttribute("Vital", "Unconscious")
			end
		end
		local fast = 0
		local under = false
		local fastName = ""
		for _, p in parts do
			if p.Parent then
				local v = p.AssemblyLinearVelocity.Magnitude
				if v > fast then
					fastName = p.Name
				end
				fast = math.max(fast, v)
				if p.Position.Y < floorTop - 0.3 and math.abs(p.Position.X - PhysicsBench.ORIGIN.X) < 100 and math.abs(p.Position.Z - PhysicsBench.ORIGIN.Z) < 100 then
					under = true
				end
			end
		end
		if fast > r.peak then
			r.peak = fast
			peakAt = os.clock()
		end
		if os.clock() - lastTrace >= 0.25 then
			lastTrace = os.clock()
			r.trace ..= string.format(" %.0f%s", fast, string.sub(fastName, 1, 6))
		end
		if fast > cap then
			r.spikes += 1
		end
		if under then
			r.sunk += 1
		end
		msSum += physicsMs()
		msN += 1
		local moved = r.peak > PhysicsBench.SETTLE_SPEED * 3 or os.clock() - t0 > PhysicsBench.MIN_WATCH
		if fast < PhysicsBench.SETTLE_SPEED and moved then
			stillSince = stillSince or os.clock()
			if os.clock() - (stillSince :: number) >= PhysicsBench.SETTLE_HOLD then
				r.settle = math.max(0, (stillSince :: number) - peakAt)
				break
			end
		else
			stillSince = nil
		end
	end
	r.physicsMs = if msN > 0 then msSum / msN else 0
	-- Jitter at rest.
	if r.settle then
		local t1 = os.clock()
		local lin, ang, n = 0, 0, 0
		while os.clock() - t1 < PhysicsBench.JITTER_TIME do
			RunService.Heartbeat:Wait()
			for _, m in bodies do
				if m.Parent and m:GetAttribute("Vital") ~= "Unconscious" then
					m:SetAttribute("Vital", "Unconscious")
				end
			end
			-- (Only a body lying limp: one that got up anyway (VitalsService woke it) is standing, not
			-- jittering.)
			for _, p in parts do
				local body = p.Parent
				local s = body and body:GetAttribute("RagdollState")
				if body and (s == "Ragdoll" or s == "Out") then
					lin += p.AssemblyLinearVelocity.Magnitude
					ang += p.AssemblyAngularVelocity.Magnitude
					n += 1
				end
			end
		end
		r.jitter = if n > 0 then lin / n else 0
		r.spin = if n > 0 then ang / n else 0
	end
	local first = bodies[1]
	if first then
		r.state = tostring(first:GetAttribute("RagdollState")) .. "/" .. tostring(first:GetAttribute("Vital"))
	end
	return r
end

local function knock(m: Model, dv: Vector3)
	-- (Straight onto the body: the same limp as any big hit, then the push.)
	local DummyControl = require(script.Parent.Parent.Parent:WaitForChild("Systems"):WaitForChild("DummyControl")) :: any
	local chest = m:FindFirstChild("UpperTorso")
	if chest and chest:IsA("BasePart") then
		DummyControl.hit(m, chest, dv * ((m:GetAttribute("Mass") :: number?) or 10), chest.Position, nil, nil)
	end
	-- (Then out cold: it stays down, so the numbers are the fall and the rest, never the getting up.)
	m:SetAttribute("Vital", "Unconscious")
end

-- The scenes. Each returns its Result. (Water, the compressor, creatures, cars and moving platforms
-- join when those steps are built: V9-1, V9-0m, V9-2, V9-0y.)
PhysicsBench.SCENES = {
	{
		name = "drop40",
		run = function(): Result
			local o = PhysicsBench.ORIGIN
			local m = PhysicsBench.body(o, 40)
			task.wait(0.1)
			knock(m, Vector3.new(0, 0.1, 0)) -- (limp at the top: a drop, not a stand)
			return PhysicsBench.watch("drop40", { m }, 1.5 * math.sqrt(2 * Workspace.Gravity * 42))
		end,
	},
	{
		name = "stairs",
		run = function(): Result
			local o = PhysicsBench.ORIGIN
			local m = PhysicsBench.body(o + Vector3.new(-40, 15, -45))
			task.wait(0.4)
			knock(m, Vector3.new(0, 4, 14))
			return PhysicsBench.watch("stairs", { m }, 90)
		end,
	},
	{
		name = "launch",
		run = function(): Result
			local o = PhysicsBench.ORIGIN
			local m = PhysicsBench.body(o + Vector3.new(30, 4, 30))
			task.wait(0.4)
			knock(m, Vector3.new(0, 70, -60)) -- (a cannon-sized launch)
			return PhysicsBench.watch("launch", { m }, 1.5 * 110)
		end,
	},
	{
		name = "blast6",
		run = function(): Result
			local o = PhysicsBench.ORIGIN
			local m = PhysicsBench.body(o + Vector3.new(30, 4, -30))
			task.wait(0.4)
			local Blasts = require(script.Parent.Parent.Parent:WaitForChild("Systems"):WaitForChild("Blasts")) :: any
			Blasts.explode((m:GetPivot().Position) + Vector3.new(6, -2, 0), nil, nil)
			m:SetAttribute("Vital", "Unconscious") -- (stays down: the fall and the rest, not the getting up)
			return PhysicsBench.watch("blast6", { m }, 250)
		end,
	},
	{
		name = "pile20",
		run = function(): Result
			local o = PhysicsBench.ORIGIN
			local bodies = {}
			for i = 1, 20 do
				local m = PhysicsBench.body(o + Vector3.new(-30 + (i % 4) * 1.5, 0, 30 + (i % 3) * 1.5), 6 + i * 4)
				table.insert(bodies, m)
			end
			task.wait(0.2)
			for _, m in bodies do
				knock(m, Vector3.new(0, 0.1, 0))
			end
			return PhysicsBench.watch("pile20", bodies, 200)
		end,
	},
	{
		name = "rest10",
		run = function(): Result
			local o = PhysicsBench.ORIGIN
			local m = PhysicsBench.body(o + Vector3.new(0, 4, 40))
			task.wait(0.2)
			knock(m, Vector3.new(0, 0.1, 0))
			task.wait(3)
			local r = PhysicsBench.watch("rest10", { m }, 20)
			return r
		end,
	},
}

function PhysicsBench.format(r: Result): string
	return string.format("%-7s peak %5.0f (cap %3.0f, %d spikes)  sunk %3d  settle %s  jitter %.2f / %.2f rad/s  physics %.2f ms  bodies %d  %s  trace:%s", r.name, r.peak, r.cap, r.spikes, r.sunk, if r.settle then string.format("%.2fs", r.settle) else "NEVER", r.jitter, r.spin, r.physicsMs, r.bodies, r.state, r.trace)
end

-- Runs every scene (or the named ones), clearing between them. Returns the results.
function PhysicsBench.run(only: { string }?): { Result }
	PhysicsBench.build()
	local results: { Result } = {}
	for _, scene in PhysicsBench.SCENES do
		if not only or table.find(only, scene.name) then
			local ok, r = pcall(scene.run)
			if ok then
				table.insert(results, r)
				print("[PhysicsBench] " .. PhysicsBench.format(r))
			else
				warn("[PhysicsBench] " .. scene.name .. " failed: " .. tostring(r))
			end
			for _, d in Workspace:GetDescendants() do
				if d:IsA("Model") and d:GetAttribute("BenchBody") == true then
					d:Destroy()
				end
			end
			task.wait(0.3)
		end
	end
	PhysicsBench.clear()
	return results
end

local _ = Players
return PhysicsBench
