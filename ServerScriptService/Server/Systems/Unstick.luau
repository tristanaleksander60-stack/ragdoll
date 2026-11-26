--!strict
-- F32 (owner, 26 Nov 2026: ragdolls stuck inside the tree belts and walls; Config.UNSTICK):
--   * BELT WALLS: every walled room of the master plan (Shared/OwnerMapPlan) gets an invisible solid wall along the
--     middle of its tree belt (3 thick, 12 high, a gap at every entrance), so no ragdoll walks or is thrown deep into
--     the trees. CanQuery off (shots and clicks pass), a PathfindingModifier "NoGo" on it.
--   * UNSTICK: a ragdoll whose pelvis is inside something solid (a trunk, a wall, a rock, a building) or inside a belt
--     wall for more than STUCK s is moved to the nearest free walkable point within 20 studs, standing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Unstick = {}

Unstick.STUCK = 1
Unstick.WALL_IN = 9 -- studs in from the room edge: the middle of the belt (trees at 5, 9, 13)

local built: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local insideSince: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function wall(into: Instance, a: Vector3, b: Vector3)
	local len = (b - a).Magnitude
	if len < 2 then
		return
	end
	local p = Instance.new("Part")
	p.Name = "BeltWall"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(3, 12, len)
	p.CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 6, 0), b + Vector3.new(0, 6, 0))
	local mod = Instance.new("PathfindingModifier")
	mod.Label = "NoGo"
	mod.Parent = p
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).FOLIAGE_PASS then
		p.CollisionGroup = "RagdollBlock" -- (F54: the belt walls stop ragdolls only; players run through)
	end
	p.Parent = into
end

local function beltWalls(om: Instance, o: Vector3)
	local Plan = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
	local f = Instance.new("Folder")
	f.Name = "BeltWalls"
	f.Parent = om
	local gapHalf = Plan.GAP / 2 + 6
	for _, room in Plan.ROOMS do
		if room.walled then
			local d = Unstick.WALL_IN
			local mn, mx = room.min + Vector2.new(d, d), room.max - Vector2.new(d, d)
			local corners = { Vector2.new(mn.X, mn.Y), Vector2.new(mx.X, mn.Y), Vector2.new(mx.X, mx.Y), Vector2.new(mn.X, mx.Y) }
			for i = 1, 4 do
				local a, b = corners[i], corners[i % 4 + 1]
				-- cut the edge at every entrance near it
				local cuts = {}
				local dir = (b - a).Unit
				local len = (b - a).Magnitude
				for _, e in room.entrances do
					local t = (e - a):Dot(dir)
					local off = ((a + dir * t) - e).Magnitude
					if t > -gapHalf and t < len + gapHalf and off < d + 6 then
						table.insert(cuts, { t - gapHalf, t + gapHalf })
					end
				end
				table.sort(cuts, function(x, y)
					return x[1] < y[1]
				end)
				local s = 0
				for _, c in cuts do
					if c[1] > s then
						local p1, p2 = a + dir * s, a + dir * math.min(c[1], len)
						wall(f, Vector3.new(o.X + p1.X, o.Y, o.Z + p1.Y), Vector3.new(o.X + p2.X, o.Y, o.Z + p2.Y))
					end
					s = math.max(s, c[2])
				end
				if s < len then
					local p1 = a + dir * s
					wall(f, Vector3.new(o.X + p1.X, o.Y, o.Z + p1.Y), Vector3.new(o.X + b.X, o.Y, o.Z + b.Y))
				end
			end
		end
	end
end

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude

local function solidAt(pos: Vector3, size: Vector3): boolean
	for _, h in Workspace:GetPartBoundsInBox(CFrame.new(pos), size, overlap) do
		if h.CanCollide and h.Anchored and not (h.Size.Y < 1.3 and math.abs(h.CFrame.UpVector.Y) > 0.95) then
			return true
		end
	end
	return false
end

local function freePointNear(pos: Vector3): Vector3?
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = overlap.FilterDescendantsInstances
	for r = 3, 21, 3 do
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2 + r
			local p = pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local hit = Workspace:Raycast(p + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), ray)
			if hit and hit.Normal.Y > 0.8 then
				local stand = hit.Position + Vector3.new(0, 3.2, 0)
				if not solidAt(stand, Vector3.new(2.5, 4.5, 2.5)) then
					return stand
				end
			end
		end
	end
	return nil
end

local airStill: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
-- F46 (owner: "Fiks så ragdollen ikke fryser når den dør"; Config.NO_DEATH_FREEZE): a dead or knocked-out body may never
-- hang still in the air. Still (under 0.5 studs/s) with no ground within 3 studs for 0.6 s: every part is unanchored
-- and it gets a small push down, so it falls and lies loose.
local function deathGuard(m: Model, pe: BasePart, now: number, ray: RaycastParams)
	local vital = m:GetAttribute("Vital")
	if vital ~= "Dead" and vital ~= "Unconscious" then
		airStill[m] = nil
		return
	end
	if pe.AssemblyLinearVelocity.Magnitude > 0.5 or m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil then
		airStill[m] = nil
		return
	end
	if Workspace:Raycast(pe.Position, Vector3.new(0, -3, 0), ray) then
		airStill[m] = nil
		return -- (lying on something: fine)
	end
	airStill[m] = airStill[m] or now
	if now - (airStill[m] :: number) > 0.6 then
		airStill[m] = nil
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.Anchored and d.Name ~= "HumanoidRootPart" then
				d.Anchored = false
			end
		end
		local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
		pcall(DC.push, m, Vector3.new(0, -6, 0))
	end
end

local function step()
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	local ex = { dummies }
	for _, pl in game:GetService("Players"):GetPlayers() do
		if pl.Character then
			table.insert(ex, pl.Character)
		end
	end
	overlap.FilterDescendantsInstances = ex
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = ex
	local guard = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).NO_DEATH_FREEZE == true
	local now = os.clock()
	for _, m in dummies:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		if guard and m:IsA("Model") and pe and pe:IsA("BasePart") then
			deathGuard(m, pe, now, ray)
		end
		if m:IsA("Model") and pe and pe:IsA("BasePart") and m:GetAttribute("Held") ~= true and m:GetAttribute("InMachine") == nil
			and m:GetAttribute("MachineHidden") == nil and pe.AssemblyLinearVelocity.Magnitude < 10 then
			if solidAt(pe.Position, Vector3.new(1, 1, 1)) then
				insideSince[m] = insideSince[m] or now
				if now - (insideSince[m] :: number) > Unstick.STUCK then
					insideSince[m] = nil
					local to = freePointNear(pe.Position)
					if to then
						local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
						pcall(DC.move, m, CFrame.new(to))
						m:SetAttribute("Home", to)
					end
				end
			else
				insideSince[m] = nil
			end
		end
	end
end

function Unstick.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.UNSTICK or not Config.LAB_OWNERMAP then
		return
	end
	if Config.FOLIAGE_PASS then
		local PhysicsService = game:GetService("PhysicsService")
		pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, "RagdollBlock")
		pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, "PlayerBodies")
		PhysicsService:CollisionGroupSetCollidable("RagdollBlock", "PlayerBodies", false)
	end
	task.spawn(function()
		local t = 0
		while true do
			task.wait(0.5)
			t += 0.5
			pcall(step)
			if t >= 5 then
				t = 0
				local root = Workspace:FindFirstChild("Playground")
				for _, lab in if root then root:GetChildren() else {} do
					local om = lab:FindFirstChild("OwnerMap")
					local grass = om and om:FindFirstChild("OwnerGrass")
					if om and grass and grass:IsA("BasePart") and not built[om] then
						built[om] = true
						local c = (require(script.Parent:WaitForChild("LabOwnerMap")) :: any).CENTER :: Vector2
						pcall(beltWalls, om, Vector3.new(grass.Position.X - c.X, grass.Position.Y + 1.05, grass.Position.Z - c.Y))
					end
				end
			end
		end
	end)
end

return Unstick
