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

-- F90 (owner, 27 Nov: "Ragdolls der går rundt forsvinder bare ud af det blå nogle gange imens man står og slår dem";
-- Config.NEVER_VANISH): ONE guard every system asks before it moves a ragdoll far, hides it, pools it or removes it.
-- No when it is in some player's view, within NEAR studs of a player, hit in the last HIT_AGO s, held, in a machine or
-- hidden by one. Every removal it is told about is logged (REMOVAL_LOG), so a system that still does it in view is named.
RagdollDirector.GUARD_NEAR = 60
RagdollDirector.GUARD_HIT_AGO = 30
function RagdollDirector.nearestPlayer(point: Vector3): number
	local best = math.huge
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			best = math.min(best, (r.Position - point).Magnitude)
		end
	end
	return best
end
function RagdollDirector.mayRemove(m: Model): boolean
	local pe = m:FindFirstChild("LowerTorso")
	if not (pe and pe:IsA("BasePart")) then
		return true
	end
	local hitAt = m:GetAttribute("ServerHitAt")
	if m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil or m:GetAttribute("MachineHidden") ~= nil then
		return false
	end
	if type(hitAt) == "number" and workspace:GetServerTimeNow() - hitAt < RagdollDirector.GUARD_HIT_AGO then
		return false
	end
	if RagdollDirector.nearestPlayer(pe.Position) < RagdollDirector.GUARD_NEAR then
		return false
	end
	return not RagdollDirector.inView(pe.Position)
end
function RagdollDirector.logRemoval(m: Model, system: string, reason: string)
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if Config.REMOVAL_LOG == false then
		return
	end
	local pe = m:FindFirstChild("LowerTorso")
	local at = if pe and pe:IsA("BasePart") then pe.Position else Vector3.zero
	local seen = RagdollDirector.inView(at)
	local line = string.format("[REMOVAL_LOG] %s %s: %s (nearest player %.0f studs, in view: %s)", system, m.Name, reason,
		RagdollDirector.nearestPlayer(at), if seen then "YES (bug)" else "no")
	if seen then
		warn(line)
	else
		print(line)
	end
end

-- OVERVIEW 0.158 / docs/RAGDOLL_DIRECTOR.md Part C (owner: "Hvis der er mere end 6-7 i nærheden af en telefonspiller, så skal alle
-- over 6-7 gå væk, medmindre de er blevet ramt af et skud"; Config.NEARBY_CAP): living ragdolls within 45 studs of a
-- player, capped by the player's device (phone 7, tablet 9, PC 12). Over it, the extras WALK AWAY (never removed in
-- view): the farthest free ones first; never one that was shot in the last 60 s, is held, in a machine, one of the 3
-- near (Role3), a watcher, a demo or a runner. They walk 90 studs straight away from the player and roam on from there.
local MORE_ROOM = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).MORE_ROOM == true
RagdollDirector.CAP = if MORE_ROOM then { phone = 5, tablet = 6 } else { phone = 7, tablet = 9 }
RagdollDirector.CAP_PC = if MORE_ROOM then 8 else 12 -- (MORE_ROOM, owner 27 Nov late: fewer close by)
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
		-- (LAG-FREE 2 item 1, Config.LAGFREE_SERVER_KNOWS: the device's real frame rate (PerfLevel, sent by its
		-- QualityGovernor) lowers the near cap: level 1 one less, level 0 two less; never under ALWAYS3's 3.)
		local lvl = p:GetAttribute("PerfLevel")
		if type(lvl) == "number" and lvl <= 1 then
			cap = math.max(3, cap - (if lvl <= 0 then 2 else 1))
		end
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

-- NEARBY_CAP_V2 (owner 27 Nov late: "Der er stadig ALT for mange ragdolls lige i nærheden af en"). Why the first cap did
-- nothing: (1) almost everyone near was exempt: a body running TO you (Pace >= 1.4 or faster than 6 studs/s), anyone shot
-- in the last 60 s (you shoot everything round you), every Role3 and every watcher; (2) a body sent away was called back
-- by one of ~35 systems that write "Home" (and was free again after 15 s). Now:
--   * counted: every living body within NEAR studs, PLUS every one on its way to you (its Home within NEAR of you);
--   * kept: held, in a machine or the ring, a machine demo/TRY, shot in the last 8 s, and the 2 nearest Role3 (the 1-2
--     that come to talk to you, owner's rule); every other one is movable, watchers too;
--   * over the cap: the unseen first, then the incoming, then the farthest walk 90 studs away at a walk (Pace 1), lose
--     their Role3/Watch job, and for SHOO_FOR s any Home a system sets near a player is put back to the away point.
RagdollDirector.NEAR = 45
RagdollDirector.SHOO_FOR = 30
local shooTo: { [Model]: { at: Vector3, untilAt: number } } = setmetatable({}, { __mode = "k" }) :: any
local watching: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function nearAnyPlayer(at: Vector3): boolean
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") and (Vector3.new(r.Position.X - at.X, 0, r.Position.Z - at.Z)).Magnitude < RagdollDirector.NEAR then
			return true
		end
	end
	return false
end
local function shoo(m: Model, to: Vector3)
	shooTo[m] = { at = to, untilAt = os.clock() + RagdollDirector.SHOO_FOR }
	m:SetAttribute("Role3", nil)
	m:SetAttribute("Watch", nil)
	m:SetAttribute("Pace", 1)
	m:SetAttribute("HomeLook", nil)
	m:SetAttribute("Home", to)
	if not watching[m] then
		watching[m] = true
		m:GetAttributeChangedSignal("Home"):Connect(function()
			local s = shooTo[m]
			if not s or os.clock() > s.untilAt or m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil then
				return
			end
			local h = m:GetAttribute("Home")
			if typeof(h) == "Vector3" and (h - s.at).Magnitude > 1 and nearAnyPlayer(h) then
				m:SetAttribute("Home", s.at) -- (a system called it back to a player: it keeps walking away)
			end
		end)
	end
end
local CAP_NEVER_YOURS = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).CAP_NEVER_YOURS == true
RagdollDirector.KEEP_NEAR = 25 -- studs: a body this close to you is yours, never sent off
RagdollDirector.KEEP_HIT = 60 -- s after any hit or touch (its Hits count went up) it is never sent off
local lastHits: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local hitKeep: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local function keptV2(m: Model): boolean
	local watch = m:GetAttribute("Watch")
	local hitAt = m:GetAttribute("ServerHitAt")
	return m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil or m:GetAttribute("MachineHidden") ~= nil
		or watch == "Demo" or watch == "NeverZero" or m:GetAttribute("TryFor") ~= nil or m:GetAttribute("BoxSide") ~= nil
		-- (an angry, mourning, CPR or other mood body is busy with you on purpose: the revenge attacker was sent away and
		-- punched the air far off)
		or m:GetAttribute("Mood") ~= nil or m:GetAttribute("CommandedBy") ~= nil
		or (type(hitAt) == "number" and workspace:GetServerTimeNow() - hitAt < 8)
end
local function capStepV2()
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
		local me = r.Position
		local cap = RagdollDirector.CAP[tostring(p:GetAttribute("Device"))] or RagdollDirector.CAP_PC
		local lvl = p:GetAttribute("PerfLevel")
		if type(lvl) == "number" and lvl <= 1 then
			cap = math.max(3, cap - (if lvl <= 0 then 2 else 1))
		end
		local count = 0
		local talkers: { { m: Model, d: number } } = {}
		local movable: { { m: Model, d: number, at: Vector3, seen: boolean, coming: boolean } } = {}
		for _, m in dummies:GetChildren() do
			local pe = m:FindFirstChild("LowerTorso")
			local vital = m:GetAttribute("Vital")
			if not (m:IsA("Model") and pe and pe:IsA("BasePart")) or vital == "Dead" or vital == "Unconscious" or m:GetAttribute("Parked") == true then
				continue
			end
			local flat = Vector3.new(pe.Position.X - me.X, 0, pe.Position.Z - me.Z)
			local d = flat.Magnitude
			local h = m:GetAttribute("Home")
			local coming = d >= RagdollDirector.NEAR and d < 160 and typeof(h) == "Vector3"
				and Vector3.new(h.X - me.X, 0, h.Z - me.Z).Magnitude < RagdollDirector.NEAR
			if d < RagdollDirector.NEAR or coming then
				count += 1
				local s = shooTo[m]
				-- (CAP_NEVER_YOURS, owner 28 Nov: "I hit a ragdoll, it went 20 m away, and every time I walked to it, it went
				-- further, as if tied to me but keeping its distance". The cause: this cap sent it 90 studs away from the
				-- player; a body you just punched was only kept if the SERVER stamped the hit (ServerHitAt, 8 s), and a
				-- punch on your own lab's body is reported by your screen, so it was never kept and was sent off again each
				-- time you came near. Now a body is never moved off when it is close to you (KEEP_NEAR), in your view, or
				-- touched in the last KEEP_HIT s (its Hits count went up); and a body walking away stops when you go to it.)
				if CAP_NEVER_YOURS then
					local hits = (m:GetAttribute("Hits") :: number?) or 0
					if hits ~= (lastHits[m] or hits) then
						hitKeep[m] = now + RagdollDirector.KEEP_HIT
					end
					lastHits[m] = hits
					local mine = d < RagdollDirector.KEEP_NEAR or now < (hitKeep[m] or 0)
					if mine then
						if s and now <= s.untilAt then
							shooTo[m] = nil
							m:SetAttribute("Home", pe.Position) -- (you came to it: it stays)
							m:SetAttribute("Pace", nil)
						end
						continue
					end
				end
				if s and now <= s.untilAt then
					continue -- (already walking away)
				end
				if keptV2(m) then
					continue
				end
				if m:GetAttribute("Role3") ~= nil and not coming then
					table.insert(talkers, { m = m, d = d })
					continue
				end
				table.insert(movable, { m = m, d = d, at = pe.Position, seen = false, coming = coming })
			end
		end
		-- (the 2 nearest talkers stay; any more are movable like the rest)
		table.sort(talkers, function(a, b)
			return a.d < b.d
		end)
		for i = 3, #talkers do
			local t = talkers[i]
			local pe = t.m:FindFirstChild("LowerTorso") :: BasePart
			table.insert(movable, { m = t.m, d = t.d, at = pe.Position, seen = false, coming = false })
		end
		local over = count - cap
		if over <= 0 then
			continue
		end
		for _, e in movable do
			e.seen = RagdollDirector.inView(e.at)
		end
		if CAP_NEVER_YOURS then
			-- (the owner's rule: nobody walks off in your view; only the ones you cannot see leave)
			local unseen = {}
			for _, e in movable do
				if not e.seen then
					table.insert(unseen, e)
				end
			end
			movable = unseen
		end
		table.sort(movable, function(a, b)
			if a.seen ~= b.seen then
				return not a.seen
			end
			if a.coming ~= b.coming then
				return a.coming
			end
			return a.d > b.d
		end)
		for i = 1, math.min(over, #movable) do
			local e = movable[i]
			local away = Vector3.new(e.at.X - me.X, 0, e.at.Z - me.Z)
			local dir = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
			shoo(e.m, e.at + dir * 90)
		end
	end
end

-- SPAWN_V2 step 1 (docs/SPAWN_V2.md): how many more living bodies may come within NEAR of this player right now (the
-- cap minus the ones there or on their way). Every system that spawns a body near a player or calls one to a player asks
-- this first and sends at most that many; 0 = none.
function RagdollDirector.room(player: Player): number
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local dummies = Workspace:FindFirstChild("Dummies")
	if not (r and r:IsA("BasePart") and dummies) then
		return 0
	end
	local me = r.Position
	local cap = RagdollDirector.CAP[tostring(player:GetAttribute("Device"))] or RagdollDirector.CAP_PC
	local lvl = player:GetAttribute("PerfLevel")
	if type(lvl) == "number" and lvl <= 1 then
		cap = math.max(3, cap - (if lvl <= 0 then 2 else 1))
	end
	local count = 0
	for _, m in dummies:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		local vital = m:GetAttribute("Vital")
		if m:IsA("Model") and pe and pe:IsA("BasePart") and vital ~= "Dead" and vital ~= "Unconscious" and m:GetAttribute("Parked") ~= true then
			local d = Vector3.new(pe.Position.X - me.X, 0, pe.Position.Z - me.Z).Magnitude
			local h = m:GetAttribute("Home")
			local s = shooTo[m]
			local leaving = s ~= nil and os.clock() <= s.untilAt
			if not leaving and (d < RagdollDirector.NEAR or (typeof(h) == "Vector3" and Vector3.new(h.X - me.X, 0, h.Z - me.Z).Magnitude < RagdollDirector.NEAR)) then
				count += 1
			end
		end
	end
	return math.max(0, cap - count)
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
			if Config.NEARBY_CAP_V2 then
				pcall(capStepV2)
			elseif Config.NEARBY_CAP then
				pcall(capStep)
			end
		end
	end)
end

return RagdollDirector
