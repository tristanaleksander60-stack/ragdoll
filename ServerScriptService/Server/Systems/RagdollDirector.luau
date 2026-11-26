--!strict
-- OVERVIEW 0.1 part B, step 1 (owner: "de skal bare spawne hvor man er, så det ikke lagger"; docs/RAGDOLL_DIRECTOR.md;
-- Config.RAGDOLL_DIRECTOR): the far ragdolls cost nothing. Every 0.5 s the server marks each lab ragdoll that is more
-- than PARK studs from every player and not in use as Parked (attribute); within WAKE studs it is woken again
-- (hysteresis, so it never flickers). The simulating screen (Shared/Ragdoll/ActiveRagdoll) skips a parked body's whole
-- brain and pose update: a standing one keeps standing on its held joints, a lying one lies, at no cost.
-- In use = held, in a machine, hidden by a machine, a demo or NEVER ZERO runner, moving fast, or hit in the last 10 s.
-- At most MAX_CHANGES park/wake changes a tick (no spikes).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RagdollDirector = {}

RagdollDirector.PARK = 140
RagdollDirector.WAKE = 120
RagdollDirector.MAX_CHANGES = 8

local function inUse(m: Model, pe: BasePart): boolean
	local watch = m:GetAttribute("Watch")
	local hitAt = m:GetAttribute("ServerHitAt")
	return m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil or m:GetAttribute("MachineHidden") ~= nil
		or watch == "Demo" or watch == "NeverZero" or m:GetAttribute("TryFor") ~= nil
		or (type(m:GetAttribute("Pace")) == "number" and (m:GetAttribute("Pace") :: number) >= 1.4) -- (a recruit or runner on its way)
		or pe.AssemblyLinearVelocity.Magnitude > 6
		or (type(hitAt) == "number" and workspace:GetServerTimeNow() - hitAt < 10)
end

local function step()
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	local eyes = {}
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			table.insert(eyes, r.Position)
		end
	end
	local changes = 0
	for _, m in dummies:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		if m:IsA("Model") and pe and pe:IsA("BasePart") then
			local near = math.huge
			for _, e in eyes do
				near = math.min(near, (e - pe.Position).Magnitude)
			end
			local parked = m:GetAttribute("Parked") == true
			if parked and (near < RagdollDirector.WAKE or inUse(m, pe)) then
				m:SetAttribute("Parked", nil)
				changes += 1
			elseif not parked and near > RagdollDirector.PARK and not inUse(m, pe) then
				m:SetAttribute("Parked", true)
				changes += 1
			end
			if changes >= RagdollDirector.MAX_CHANGES then
				return
			end
		end
	end
end

-- OVERVIEW 0.158 "in view" (Config.VIEW_REPORT): every screen reports its camera (position + look) twice a second over an
-- unreliable remote; the server keeps the latest per player. RagdollDirector.inView(point) = some player's camera, fresh
-- (under 3 s old), sees the point: within 260 studs and inside a 60-degree cone round the look, or within 14 studs at
-- all. Systems that send ragdolls away or set them down ask this, so nothing appears or vanishes in view.
RagdollDirector.VIEW_RANGE = 260
RagdollDirector.VIEW_COS = math.cos(math.rad(60))
local views: { [Player]: { pos: Vector3, look: Vector3, at: number } } = setmetatable({}, { __mode = "k" }) :: any
local lastView: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
local function finite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end
function RagdollDirector.onView(player: Player, pos: unknown, look: unknown)
	if typeof(pos) ~= "Vector3" or typeof(look) ~= "Vector3" then
		return
	end
	local p, l = pos :: Vector3, look :: Vector3
	if not finite(p) or not finite(l) or l.Magnitude < 0.5 or l.Magnitude > 1.5 then
		return
	end
	local now = os.clock()
	if now - (lastView[player] or -math.huge) < 0.25 then
		return -- (at most 4 a second)
	end
	lastView[player] = now
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (r and r:IsA("BasePart")) or (r.Position - p).Magnitude > 400 then
		return
	end
	views[player] = { pos = p, look = l.Unit, at = now }
end
function RagdollDirector.inView(point: Vector3): boolean
	local now = os.clock()
	for _, v in views do
		if now - v.at < 3 then
			local d = point - v.pos
			local m = d.Magnitude
			if m < 14 or (m < RagdollDirector.VIEW_RANGE and d.Unit:Dot(v.look) > RagdollDirector.VIEW_COS) then
				return true
			end
		end
	end
	return false
end

-- OVERVIEW 0.158 / docs/RAGDOLL_DIRECTOR.md Part C (owner: "Hvis der er mere end 6-7 i nærheden af en telefonspiller, så skal alle
-- over 6-7 gå væk, medmindre de er blevet ramt af et skud"; Config.NEARBY_CAP): living ragdolls within 45 studs of a
-- player, capped by the player's device (phone 7, tablet 9, PC 12). Over it, the extras WALK AWAY (never removed in
-- view): the farthest free ones first; never one that was shot in the last 60 s, is held, in a machine, one of the 3
-- near (Role3), a watcher, a demo or a runner. They walk 90 studs straight away from the player and roam on from there.
RagdollDirector.CAP = { phone = 7, tablet = 9 }
RagdollDirector.CAP_PC = 12
local sentAway: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local function capStep()
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	local now = os.clock()
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not (r and r:IsA("BasePart")) then
			continue
		end
		local cap = RagdollDirector.CAP[tostring(p:GetAttribute("Device"))] or RagdollDirector.CAP_PC
		local living, extras = 0, {}
		for _, m in dummies:GetChildren() do
			local pe = m:FindFirstChild("LowerTorso")
			local vital = m:GetAttribute("Vital")
			if m:IsA("Model") and pe and pe:IsA("BasePart") and vital ~= "Dead" and vital ~= "Unconscious" then
				local d = (pe.Position - r.Position).Magnitude
				if d < 45 then
					living += 1
					local hitAt = m:GetAttribute("ServerHitAt")
					local shot = type(hitAt) == "number" and workspace:GetServerTimeNow() - hitAt < 60
					if not shot and not inUse(m, pe) and m:GetAttribute("Role3") == nil and m:GetAttribute("Watch") == nil
						and now - (sentAway[m] or -math.huge) > 15 then
						table.insert(extras, { m = m, d = d, at = pe.Position, seen = false })
					end
				end
			end
		end
		local over = living - cap
		if over > 0 then
			-- (0.158: the ones out of every camera first, then the farthest)
			for _, e in extras do
				e.seen = RagdollDirector.inView(e.at)
			end
			table.sort(extras, function(a, b)
				if a.seen ~= b.seen then
					return not a.seen
				end
				return a.d > b.d
			end)
			for i = 1, math.min(over, #extras) do
				local e = extras[i]
				local away = Vector3.new(e.at.X - r.Position.X, 0, e.at.Z - r.Position.Z)
				local dir = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
				sentAway[e.m] = now
				e.m:SetAttribute("Home", e.at + dir * 90)
				e.m:SetAttribute("HomeLook", nil)
			end
		end
	end
end

function RagdollDirector.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if Config.VIEW_REPORT then
		local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any
		Net.unreliable(Net.Names.CameraView).OnServerEvent:Connect(RagdollDirector.onView)
	end
	if not Config.RAGDOLL_DIRECTOR then
		return
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(step)
			if Config.NEARBY_CAP then
				pcall(capStep)
			end
		end
	end)
end

return RagdollDirector
