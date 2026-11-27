--!strict
-- OVERVIEW 0.95 (owner, 26 Nov 2026: "Fiks så at ragdolls ikke går ind i ting"; docs/ALWAYS3.md "Ragdolls never walk INTO
-- things"; Config.RAGDOLL_NAV): real paths for every walking ragdoll, without touching the systems that send them.
--   * Every system sends a ragdoll by setting its attribute Home (the active ragdoll walks straight at it). When Home
--     moves more than FAR studs from where the ragdoll stands, this module takes the goal, asks PathfindingService for
--     a path (agent radius 2, height 5.5, no jumping) and feeds Home one waypoint ahead at a time, so it walks round
--     trees, benches, lamps, machines and walls. HomeLook is held back until the last waypoint.
--   * NO-GO: lava, water, pools, flower beds, the shredder and gyro pads, the rails and the trench get a
--     PathfindingModifier "NoGo" (never crossed).
--   * STUCK GUARD: under 1 stud of progress in 1.5 s: a step back and a new path; after 3 tries it gives up and stays.
--   * At most RATE paths a second in total; over that, the walk stays straight as before.

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RagdollNav = {}

RagdollNav.FAR = 8
RagdollNav.RATE = 6
RagdollNav.AHEAD = 3.5 -- studs: the next waypoint is given before it arrives, so it never stops between them
RagdollNav.NOGO = { "Lava", "Water", "Pool", "FlowerBed", "Shredder", "GyroPad", "Rail", "Sleeper", "Trench", "Pond", "Aquarium" }

type Nav = { goal: Vector3, look: any, points: { Vector3 }, idx: number, lastPos: Vector3, lastAt: number, fails: number, plannedAt: number?, dirty: boolean? }

local navs: { [Model]: Nav } = setmetatable({}, { __mode = "k" }) :: any
local mine: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- (we are setting Home ourselves)
local lastOutside: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any -- (F65: when a system last set Home itself)
local budget = RagdollNav.RATE
local pending: { [Model]: Vector3 } = setmetatable({}, { __mode = "k" }) :: any -- (PHYSICS_DEEP NAV_QUEUE: walks that missed the budget)
-- (F72, Config.NAV_ALWAYS: the waypoint goes in its OWN attribute NavHome, which the active ragdoll follows before Home; Home is
-- never overwritten, so a system that sets Home every tick (a moving goal: the newspaper route, a chase, FirstAid, a
-- runner) no longer fights the path, and every walk gets one: re-planned only when the goal moved 4 studs, at most 1/s)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local ALWAYS = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).NAV_ALWAYS == true
local function drop(m: Model)
	navs[m] = nil
	if ALWAYS and m.Parent then
		m:SetAttribute("NavHome", nil)
	end
end
local agent = { AgentRadius = 2, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 5, Costs = { NoGo = math.huge } }

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function setHome(m: Model, at: Vector3)
	if ALWAYS then
		m:SetAttribute("NavHome", at)
		return
	end
	mine[m] = true
	m:SetAttribute("Home", at)
	mine[m] = nil
end

local function compute(m: Model, from: Vector3, goal: Vector3): { Vector3 }?
	if budget <= 0 then
		return nil
	end
	budget -= 1
	local path = PathfindingService:CreatePath(agent)
	local ok = pcall(function()
		path:ComputeAsync(from, goal)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		return nil
	end
	local pts = {}
	for _, w in path:GetWaypoints() do
		table.insert(pts, w.Position)
	end
	return pts
end

local function start(m: Model, goal: Vector3)
	local pe = pelvisOf(m)
	if not pe then
		return
	end
	local from = Vector3.new(pe.Position.X, goal.Y, pe.Position.Z)
	if (from - goal).Magnitude < RagdollNav.FAR then
		drop(m)
		return
	end
	local broke = budget <= 0
	local pts = compute(m, pe.Position, goal)
	if not pts or #pts < 2 then
		drop(m)
		if broke and Config.NAV_QUEUE then
			-- (PHYSICS_DEEP: the probe found walkers with no path walking into bike racks, fences and lamp posts: the path
			-- budget (shared by every lab) was spent, so they walked straight and never got one. Now they wait in a queue
			-- for the next refill and get their path then.)
			pending[m] = goal
		end
		return -- (no path or no budget: it walks straight as before)
	end
	pending[m] = nil
	local look = m:GetAttribute("HomeLook")
	navs[m] = { goal = goal, look = look, points = pts, idx = 2, lastPos = pe.Position, lastAt = os.clock(), fails = 0, plannedAt = os.clock() }
	if look ~= nil then
		m:SetAttribute("HomeLook", nil)
	end
	setHome(m, pts[2])
end

local function finish(m: Model, n: Nav)
	navs[m] = nil
	if ALWAYS then
		m:SetAttribute("NavHome", nil) -- (the last stretch straight to Home itself)
	else
		setHome(m, n.goal)
	end
	if n.look ~= nil then
		m:SetAttribute("HomeLook", n.look)
	end
end

local function step()
	local now = os.clock()
	for m, n in navs do
		local pe = pelvisOf(m)
		local st = m:GetAttribute("RagdollState")
		if not m.Parent or not pe then
			navs[m] = nil
			continue
		end
		if not (st == nil or st == "Standing" or st == "Walking") then
			n.lastAt = now -- (down or held: wait)
			continue
		end
		if ALWAYS and n.dirty and now - (n.plannedAt or 0) >= 1 then
			-- (the goal moved 4+ studs: a new path, at most once a second)
			n.dirty = false
			n.plannedAt = now
			local pts = compute(m, pe.Position, n.goal)
			if pts and #pts >= 2 then
				n.points, n.idx = pts, 2
				setHome(m, pts[2])
			end
		end
		local here = Vector3.new(pe.Position.X, 0, pe.Position.Z)
		-- (PHYSICS_DEEP 2b, Config.NAV_NO_BACKTRACK: the probe saw walkers reverse 6-11 times in 12 s while their
		-- NavHome changed: a waypoint passed off to the side (outside AHEAD) or a new path's first point just behind it
		-- turned it round. A waypoint it has already passed along the path is skipped: never a step back.)
		if Config.NAV_NO_BACKTRACK then
			while n.idx < #n.points do
				local a0, a1 = n.points[n.idx], n.points[n.idx + 1]
				local seg = Vector3.new(a1.X - a0.X, 0, a1.Z - a0.Z)
				local toWp = Vector3.new(a0.X, 0, a0.Z) - here
				if seg.Magnitude > 0.1 and toWp:Dot(seg) < 0 then
					n.idx += 1 -- (it is behind us along the path)
				else
					break
				end
			end
			if n.points[n.idx] ~= nil and m:GetAttribute("NavHome") ~= n.points[n.idx] and n.idx < #n.points then
				setHome(m, n.points[n.idx])
			end
		end
		local wp = n.points[n.idx]
		if (here - Vector3.new(wp.X, 0, wp.Z)).Magnitude < RagdollNav.AHEAD then
			-- skip ahead to the next waypoint that is not right here
			repeat
				n.idx += 1
			until n.idx >= #n.points or (here - Vector3.new(n.points[n.idx].X, 0, n.points[n.idx].Z)).Magnitude >= RagdollNav.AHEAD
			if n.idx >= #n.points then
				finish(m, n)
			else
				setHome(m, n.points[n.idx])
			end
			n.lastPos, n.lastAt = pe.Position, now
		elseif now - n.lastAt > 1.5 then
			if (pe.Position - n.lastPos).Magnitude < 1 then
				-- stuck: a step back and a new path
				n.fails += 1
				if n.fails >= 3 then
					if ALWAYS then
						drop(m) -- (give up: it walks straight at Home again)
					else
						navs[m] = nil
						setHome(m, pe.Position) -- (give up: it stays where it is)
					end
					if n.look ~= nil then
						m:SetAttribute("HomeLook", n.look)
					end
				else
					local pts = compute(m, pe.Position, n.goal)
					if pts and #pts >= 2 then
						n.points, n.idx = pts, 2
						setHome(m, pts[2])
					end
				end
			end
			n.lastPos, n.lastAt = pe.Position, now
		end
	end
end

local function watchModel(m: Instance)
	if not m:IsA("Model") then
		return
	end
	m:GetAttributeChangedSignal("Home"):Connect(function()
		if mine[m] then
			return
		end
		local h = m:GetAttribute("Home")
		if typeof(h) == "Vector3" then
			local n = navs[m]
			if n and (h - n.points[n.idx]).Magnitude < 0.05 then
				return -- (our own waypoint, seen late when signals are deferred)
			end
			if ALWAYS then
				if n and (h - n.goal).Magnitude < 4 then
					n.goal = h -- (a small move: same path, new end)
					return
				end
				if n and os.clock() - (n.plannedAt or 0) < 1 then
					n.goal = h
					n.dirty = true -- (re-planned in step, at most once a second)
					return
				end
				start(m, h)
				return
			end
			-- (F65: a system that moves Home more than once a second steers on its own (the newspaper route, a chase): pathing
			-- each of those would make Home flip between its target and a waypoint, and the legs jitter.)
			local now = os.clock()
			local recent = now - (lastOutside[m] or -math.huge) < 1
			lastOutside[m] = now
			if recent then
				navs[m] = nil
				return
			end
			if n and (h - n.goal).Magnitude < 1.5 then
				-- (F65: the same goal set again every tick (FirstAid): the path is dropped and it walks straight there. Setting
				-- the waypoint back each tick made Home flip between two points several times a second: legs jittering.)
				navs[m] = nil
				return
			end
			start(m, h)
		end
	end)
	m:GetAttributeChangedSignal("HomeLook"):Connect(function()
		local n = navs[m]
		local look = m:GetAttribute("HomeLook")
		if n and look ~= nil then
			n.look = look -- (keep it for the end of the walk)
			m:SetAttribute("HomeLook", nil)
		end
	end)
end

local function markNoGo()
	local root = Workspace:FindFirstChild("Playground")
	for _, lab in if root then root:GetChildren() else {} do
		local om = lab:FindFirstChild("OwnerMap")
		if om and not om:GetAttribute("NavMarked") then
			om:SetAttribute("NavMarked", true)
			for _, d in om:GetDescendants() do
				if d:IsA("BasePart") then
					for _, key in RagdollNav.NOGO do
						if string.find(d.Name, key) then
							local mod = Instance.new("PathfindingModifier")
							mod.Label = "NoGo"
							mod.Parent = d
							break
						end
					end
				end
			end
		end
	end
end

function RagdollNav.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.RAGDOLL_NAV then
		return
	end
	task.spawn(function()
		-- (started before Lab makes the Dummies folder: never hold up the boot)
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		for _, m in dummies:GetChildren() do
			watchModel(m)
		end
		dummies.ChildAdded:Connect(watchModel)
	end)
	task.spawn(function()
		local acc, scan = 0, 0
		while true do
			local dt = task.wait(0.2)
			acc += dt
			if acc >= 1 then
				acc = 0
				budget = if Config.NAV_QUEUE then RagdollNav.RATE * 2 else RagdollNav.RATE
				if Config.NAV_QUEUE then
					for m, goal in pending do
						if budget <= 0 then
							break
						end
						pending[m] = nil
						if m.Parent and m:GetAttribute("Home") == goal and not navs[m] then
							pcall(start, m, goal)
						end
					end
				end
			end
			scan += dt
			if scan > 5 then
				scan = 0
				pcall(markNoGo)
			end
			pcall(step)
		end
	end)
end

return RagdollNav
