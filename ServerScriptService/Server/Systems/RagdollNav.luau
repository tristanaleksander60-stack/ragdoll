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

type Nav = { goal: Vector3, look: any, points: { Vector3 }, idx: number, lastPos: Vector3, lastAt: number, fails: number }

local navs: { [Model]: Nav } = setmetatable({}, { __mode = "k" }) :: any
local mine: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- (we are setting Home ourselves)
local budget = RagdollNav.RATE
local agent = { AgentRadius = 2, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 5, Costs = { NoGo = math.huge } }

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function setHome(m: Model, at: Vector3)
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
		navs[m] = nil
		return
	end
	local pts = compute(m, pe.Position, goal)
	if not pts or #pts < 2 then
		navs[m] = nil
		return -- (no path or no budget: it walks straight as before)
	end
	local look = m:GetAttribute("HomeLook")
	navs[m] = { goal = goal, look = look, points = pts, idx = 2, lastPos = pe.Position, lastAt = os.clock(), fails = 0 }
	if look ~= nil then
		m:SetAttribute("HomeLook", nil)
	end
	setHome(m, pts[2])
end

local function finish(m: Model, n: Nav)
	navs[m] = nil
	setHome(m, n.goal)
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
		local here = Vector3.new(pe.Position.X, 0, pe.Position.Z)
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
					navs[m] = nil
					setHome(m, pe.Position) -- (give up: it stays where it is)
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
			if n and (h - n.goal).Magnitude < 1.5 then
				setHome(m, n.points[n.idx]) -- (the same goal again, e.g. FirstAid each tick: keep to the path)
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
				budget = RagdollNav.RATE
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
