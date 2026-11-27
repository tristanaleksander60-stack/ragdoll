--!strict
-- Round 5, phase 3: a living lab. While you are in your own lab, VISITORS ragdolls wander about it
-- trying the things there on their own: the human cannon, the PUT RAGDOLL HERE stations, the
-- trampoline, the lava. They walk to one (their Home), step on, get thrown (the pads' LaunchVelocity
-- does it: your client simulates them, PropContacts), and once up again pick the next. They are
-- ordinary dummies otherwise (hit them, grab them: takedowns as usual). Gone when you leave your
-- lab or the game. Only with room under the server's body cap (EventService.dummyRoom), so a full
-- server never carries more than it can (T37).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DummyFactory = require(script.Parent.DummyFactory)
local Lab = require(script.Parent.Lab)
local EventService = require(script.Parent.EventService)
local SessionStats = require(script.Parent.SessionStats)
local DeviceTier = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("DeviceTier"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local VisitorService = {}

-- (session v850, owner: "der skal ikke spawne random ragdolls rundt om en"): the base visitor
-- fill is off — the player's lab is its ten row dummies (Lab.DUMMY_COUNT) wandering about on their
-- own; no more pop-in ragdolls round the player. VIP LAB still gets Config.VIP_LAB_VISITORS extras.
VisitorService.VISITORS = 0
VisitorService.ROOM_KEEP = 8 -- bodies always left free under the cap for events and the horde
VisitorService.TRY_EVERY = 14 -- s a visitor stays with one thing before it picks another
VisitorService.SPOTS = { "CannonPad", "StationPad", "TrampolinePad", "LavaPool" }
-- (V9-0o: no green shirt: green is how a knocked-out body reads.)
local SHIRTS = { Color3.fromRGB(60, 160, 255), Color3.fromRGB(255, 170, 40), Color3.fromRGB(176, 110, 232) }

type Visitor = { model: Model, pickedAt: number }
local visitors: { [Player]: { Visitor } } = {}

local function inOwnLab(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local index = Lab.plotIndex(player)
	if not (root and root:IsA("BasePart")) or not index then
		return false
	end
	local zone, at = Lab.zoneAt(root.Position)
	return zone == "Lab" and at == index
end

-- The things in a player's lab a visitor can go and try.
function VisitorService.spotsOf(player: Player): { BasePart }
	local index = Lab.plotIndex(player)
	local root = Workspace:FindFirstChild("Playground")
	local lab = index and root and root:FindFirstChild("Lab" .. index)
	local list = {}
	if lab then
		for _, p in lab:GetChildren() do
			if p:IsA("BasePart") and table.find(VisitorService.SPOTS, p.Name) then
				table.insert(list, p)
			end
		end
	end
	return list
end

local function pick(player: Player, v: Visitor)
	local spots = VisitorService.spotsOf(player)
	if #spots == 0 then
		return
	end
	local spot = spots[math.random(1, #spots)]
	local pelvis = v.model:FindFirstChild("LowerTorso")
	local y = if pelvis and pelvis:IsA("BasePart") then pelvis.Position.Y else spot.Position.Y + 3
	v.model:SetAttribute("Home", Vector3.new(spot.Position.X, y, spot.Position.Z))
	v.model:SetAttribute("HomeLook", Vector3.new(spot.Position.X, y, spot.Position.Z - 5))
	v.pickedAt = os.clock()
end

local downSince: { [Model]: number } = {} -- (V9-0j: since when a visitor has been down or away)

local function clear(player: Player)
	for _, v in visitors[player] or {} do
		downSince[v.model] = nil
		if v.model.Parent and v.model:GetAttribute("Vital") ~= "Dead" then
			v.model:Destroy()
		end
	end
	visitors[player] = nil
end

local function fill(player: Player)
	if Lab.plotIndex(player) then
		clear(player)
		return -- the lab's 18 roaming dummies replace visitor spawns
	end
	local list = visitors[player] or {}
	visitors[player] = list
	for i = #list, 1, -1 do
		if not list[i].model.Parent then
			table.remove(list, i)
		end
	end
	-- (Phase 1: the player's device simulates its lab's bodies: a phone gets fewer. DeviceTier.)
	local record = SessionStats.recordFor(player)
	local cap = math.min(VisitorService.VISITORS, DeviceTier.caps(DeviceTier.of(record and record.plat)).visitors)
	-- (Release 0.20.0: the VIP LAB pass, Shop.OFFERS: a few more of them. OfferService sets VipLab.)
	if player:GetAttribute("VipLab") == true then
		cap += Config.VIP_LAB_VISITORS
	end
	local want = cap - #list
	if want <= 0 then
		return
	end
	want = math.min(want, math.max(0, EventService.dummyRoom() - VisitorService.ROOM_KEEP))
	-- (V9-0l: and within the lab's one body budget, which GOD MODE bodies share.)
	want = math.min(want, VisitorService.capFor(player) - #VisitorService.bodiesOf(player) - (require(script.Parent:WaitForChild("DummySpawn")) :: any).pendingFor(player))
	if want <= 0 then
		return
	end
	local center = Lab.focusFor(player)
	for i = 1, want do
		local at = center + Vector3.new(math.random(-20, 20), 3, math.random(15, 40))
		local model = DummyFactory.spawn(at, center, player)
		model.Name = "Visitor"
		model:SetAttribute("Visitor", player.UserId)
		model:SetAttribute("Personality", "Brave")
		local shirt = SHIRTS[(#list + i - 1) % #SHIRTS + 1]
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") and string.find(d.Name, "Torso") then
				d.Color = shirt
			end
		end
		local v: Visitor = { model = model, pickedAt = 0 }
		table.insert(list, v)
		-- Thrown, then up again: on to the next thing (a moment after getting up).
		local wasDown = false
		model:GetAttributeChangedSignal("RagdollState"):Connect(function()
			local s = model:GetAttribute("RagdollState")
			local down = s == "Ragdoll" or s == "Out"
			if wasDown and s == "Standing" then
				task.delay(1.5, function()
					if model.Parent then
						pick(player, v)
					end
				end)
			end
			wasDown = down
		end)
		pick(player, v)
	end
end

------------------------------------------------------------------------------------------------
-- V9-0j (owner, 21 Nov 2026: "make sure ragdolls walk round your lab so there is always one to
-- shoot"): while you are in your own lab, at least Config.LAB_MIN_TARGETS bodies (by device tier)
-- stand in it, the row, the visitors and your GOD MODE ones together, and at least NEAR_WANT of them
-- within NEAR studs in front of you. When fewer stand (knocked out, in a creature, thrown away), all
-- that are missing walk in at once from the hub's rim with a puff, each on a free spot of floor (never
-- the lava, a machine or inside anything), heading for a spot in front of you, then go about the lab
-- like any visitor. One pool with the visitors; all bodies of the lab stay under the device's ragdoll
-- cap (Config.FX_CAPS) and the server's room. Walkers past what is needed, once everyone is up again,
-- puff away out of the player's sight; a visitor that lies or is gone from the lab for STILL_RECYCLE s
-- is recycled (never one in a machine or in someone's hands).

VisitorService.KEEP_EVERY = 1 -- s between checks
VisitorService.WALK_IN_RIM = 60 -- studs from the lab's spawn: where a walker comes in
VisitorService.STILL_RECYCLE = 30 -- s a visitor may lie still or be out of the lab before it goes
VisitorService.NEAR = 45 -- studs: "near the player"
VisitorService.NEAR_WANT = 2 -- standing ones near and in front of the player, at least
VisitorService.SPARE = 2 -- walkers kept past the minimum before the extras puff away

local loopInTests = false

-- Tests: lets the real loop run while the self-tests run (T166 waits on it).
function VisitorService.loopInTests(on: boolean)
	loopInTests = on
end

-- A body that counts as a target: up (standing, walking or running off), alive, not in a machine
-- or in someone's hands.
function VisitorService.standing(model: Model): boolean
	if not model.Parent or model:GetAttribute("Vital") == "Dead" then
		return false
	end
	if model:GetAttribute("InMachine") or model:GetAttribute("MachineHidden") or model:GetAttribute("Held") then
		return false
	end
	local s = model:GetAttribute("RagdollState")
	return s == nil or s == "Standing" or s == "Fleeing" or s == "Walking"
end

local function tierOf(player: Player): DeviceTier.Tier
	local record = SessionStats.recordFor(player)
	return DeviceTier.of(record and record.plat)
end

-- The bodies of a player's lab: the row, the visitors, the GOD MODE ones.
function VisitorService.bodiesOf(player: Player): { Model }
	local out: { Model } = {}
	for _, m in Lab.dummiesOf(player) do
		table.insert(out, m)
	end
	for _, v in visitors[player] or {} do
		if v.model.Parent then
			table.insert(out, v.model)
		end
	end
	pcall(function()
		for _, m in (require(script.Parent:WaitForChild("DummySpawn")) :: any).inLab(player) do -- (V9-0l: party guests' too)
			table.insert(out, m)
		end
	end)
	return out
end

local function puff(at: Vector3)
	local ball = Instance.new("Part")
	ball.Name = "WalkInPuff"
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = Color3.new(1, 1, 1)
	ball.Transparency = 0.2
	ball.Size = Vector3.one * 2
	ball.Position = at
	ball.Parent = Workspace
	game:GetService("TweenService"):Create(ball, TweenInfo.new(0.45), { Size = Vector3.one * 7, Transparency = 1 }):Play()
	game:GetService("Debris"):AddItem(ball, 0.6)
end

-- The most bodies a player's lab may hold at once: their device's ragdoll budget (FX_CAPS), which
-- the row, the visitors and walkers and the GOD MODE ones share.
function VisitorService.capFor(player: Player): number
	return ((Config :: any).FX_CAPS :: any)[tierOf(player)].ragdolls
end

-- V9-0l: makes room for `n` bodies the player asked for (GOD MODE wins over the automatic
-- visitors): their visitors and walkers puff away, the farthest from them first, never one held or
-- in a machine. Returns how many went.
function VisitorService.makeRoom(player: Player, n: number): number
	local list = visitors[player]
	if not list or n <= 0 then
		return 0
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local from = if root and root:IsA("BasePart") then root.Position else Lab.originFor(player)
	local order: { { model: Model, d: number } } = {}
	for _, v in list do
		local m = v.model
		if m.Parent and not m:GetAttribute("Held") and not m:GetAttribute("InMachine") and not m:GetAttribute("MachineHidden") then
			table.insert(order, { model = m, d = (m:GetPivot().Position - from).Magnitude })
		end
	end
	table.sort(order, function(a, b)
		return a.d > b.d
	end)
	local freed = 0
	for k = 1, math.min(n, #order) do
		local m = order[k].model
		local pelvis = m:FindFirstChild("LowerTorso")
		if pelvis and pelvis:IsA("BasePart") then
			puff(pelvis.Position)
		end
		downSince[m] = nil
		m:Destroy()
		freed += 1
	end
	for i = #list, 1, -1 do
		if not list[i].model.Parent then
			table.remove(list, i)
		end
	end
	return freed
end

-- Whether a lab spot (x, z from the lab's spawn) is in a machine's footprint (PathPlan.OBSTACLES).
local function inMachine(p: Vector2): boolean
	local PathPlan = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PathPlan")) :: any
	if (Config :: any).LAB_CREATURES and PathPlan.inYard(p) then
		return true -- (V9-0l: the creature yard)
	end
	for _, o in PathPlan.OBSTACLES do
		if o.at and o.radius and (p - o.at).Magnitude < o.radius + 3 then
			return true
		elseif o.min and o.max and p.X > o.min.X - 3 and p.X < o.max.X + 3 and p.Y > o.min.Y - 3 and p.Y < o.max.Y + 3 then
			return true
		end
	end
	return false
end

-- Whether one spot (world) is open floor of `owner`'s lab: no machine footprint, a level floor
-- under it near the lab's height (no lava), nothing solid standing there at body height. Returns
-- the floor's top, or nil. (V9-0l: GOD MODE checks every body's spot with it too.)
function VisitorService.floorAt(owner: Player, at: Vector3, tolerance: number?): Vector3?
	local origin = Lab.originFor(owner)
	if inMachine(Vector2.new(at.X - origin.X, at.Z - origin.Z)) then
		return nil
	end
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(Vector3.new(at.X, origin.Y + 30, at.Z), Vector3.new(0, -60, 0), params)
	if not hit or hit.Normal.Y < 0.9 or math.abs(hit.Position.Y - origin.Y) > (tolerance or 2.5) or string.find(hit.Instance.Name, "Lava") or Lab.ownerAt(hit.Position) ~= owner then
		return nil
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = skip
	for _, part in Workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 3, 0)), Vector3.new(3, 4.5, 3), overlap) do
		if part.CanCollide then
			return nil
		end
	end
	return hit.Position
end

-- A free spot on the floor of `owner`'s lab near `want` (world). nil when none of the tries is free.
local function freeSpot(owner: Player, want: Vector3): Vector3?
	for _, at in { want, want + Vector3.new(4, 0, 0), want + Vector3.new(-4, 0, 0), want + Vector3.new(0, 0, 4), want + Vector3.new(0, 0, -4) } do
		local top = VisitorService.floorAt(owner, at)
		if top then
			return top + Vector3.new(0, 3, 0)
		end
	end
	return nil
end

local function facingOf(player: Player): (Vector3, Vector3?)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local facing = Lab.SPAWN_FACING
	if root and root:IsA("BasePart") then
		local look = root.CFrame.LookVector
		if Vector3.new(look.X, 0, look.Z).Magnitude > 0.1 then
			facing = Vector3.new(look.X, 0, look.Z).Unit
		end
		return facing, root.Position
	end
	return facing, nil
end

-- One walker in from the rim on a free spot, heading for a spot in front of the player. False when
-- no free spot was found this time.
local function walkIn(player: Player, list: { Visitor }): boolean
	local origin = Lab.originFor(player)
	local facing, rootAt = facingOf(player)
	local here = rootAt or origin
	local at: Vector3? = nil
	for _ = 1, 8 do
		-- (In from the rim ahead of the player, a little to one side, so it walks into view.)
		local a = math.rad(math.random(-40, 40))
		local dir = Vector3.new(facing.X * math.cos(a) - facing.Z * math.sin(a), 0, facing.X * math.sin(a) + facing.Z * math.cos(a))
		at = freeSpot(player, origin + dir * math.random(VisitorService.WALK_IN_RIM - 14, VisitorService.WALK_IN_RIM))
		if at then
			break
		end
	end
	if not at then
		at = freeSpot(player, here + facing * 20) -- (the rim is busy: closer in, still on free floor)
	end
	if not at then
		return false
	end
	local spawnAt = at :: Vector3
	local goal = here + facing * math.random(18, 30) + Vector3.new(facing.Z, 0, -facing.X) * math.random(-10, 10)
	puff(spawnAt)
	local model = DummyFactory.spawn(spawnAt, goal, player)
	model.Name = "Visitor"
	model:SetAttribute("Visitor", player.UserId)
	model:SetAttribute("WalkIn", true)
	model:SetAttribute("WalkInAt", spawnAt) -- (where it came in: T166 checks it was free floor)
	model:SetAttribute("Personality", "Brave")
	model:SetAttribute("Home", Vector3.new(goal.X, spawnAt.Y, goal.Z))
	model:SetAttribute("HomeLook", here)
	local shirt = SHIRTS[(#list) % #SHIRTS + 1]
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and string.find(d.Name, "Torso") then
			d.Color = shirt
		end
	end
	local v: Visitor = { model = model, pickedAt = os.clock() }
	table.insert(list, v)
	local wasDown = false
	model:GetAttributeChangedSignal("RagdollState"):Connect(function()
		local s = model:GetAttribute("RagdollState")
		local down = s == "Ragdoll" or s == "Out"
		if wasDown and s == "Standing" then
			task.delay(1.5, function()
				if model.Parent then
					pick(player, v)
				end
			end)
		end
		wasDown = down
	end)
	return true
end

-- Keeps at least the minimum standing in the player's own lab (nothing while they are elsewhere).
-- Returns how many walked in.
function VisitorService.keepTargets(player: Player): number
	if Lab.plotIndex(player) then
		clear(player)
		return 0
	end
	if not inOwnLab(player) or not (Config :: any).LAB_MIN_TARGETS then
		return 0
	end
	-- (A newcomer's first minute stays as V8 made it: the row and the greeter, calm.)
	local spawnedAt = player:GetAttribute("SpawnedAt")
	if player:GetAttribute("Newcomer") == true and type(spawnedAt) == "number" and Workspace:GetServerTimeNow() - spawnedAt < (Config.QUIET_START or 60) then
		return 0
	end
	local list = visitors[player] or {}
	visitors[player] = list
	local now = os.clock()
	-- Recycle a visitor that lies or left the lab for too long (never one in a machine or held).
	for i = #list, 1, -1 do
		local m = list[i].model
		if not m.Parent then
			table.remove(list, i)
			downSince[m] = nil
			continue
		end
		local pelvis = m:FindFirstChild("LowerTorso")
		local away = pelvis and pelvis:IsA("BasePart") and Lab.ownerAt(pelvis.Position) ~= player
		if (VisitorService.standing(m) and not away) or m:GetAttribute("InMachine") or m:GetAttribute("Held") then
			downSince[m] = nil
		else
			downSince[m] = downSince[m] or now
			if now - downSince[m] > VisitorService.STILL_RECYCLE then
				downSince[m] = nil
				m:Destroy()
				table.remove(list, i)
			end
		end
	end
	local tier = tierOf(player)
	local want = ((Config :: any).LAB_MIN_TARGETS :: any)[tier] or 5
	-- (LAG-FREE 2 item 1: a phone that has stepped down to quality 1 or 0 gets one visitor fewer, never under 3)
	local perf = player:GetAttribute("PerfLevel")
	if (Config :: any).LAGFREE_SERVER_KNOWS and type(perf) == "number" and perf <= 1 then
		want = math.max(3, want - 1)
	end
	local cap = ((Config :: any).FX_CAPS :: any)[tier].ragdolls
	local bodies = VisitorService.bodiesOf(player)
	local facing, rootAt = facingOf(player)
	local up, near = 0, 0
	-- (A walker that just came in counts as up, and near, while it lands from its puff.)
	local fresh: { [Model]: boolean } = {}
	for _, v in list do
		if v.model:GetAttribute("WalkIn") and now - v.pickedAt < 3 then
			fresh[v.model] = true
		end
	end
	for _, m in bodies do
		if fresh[m] or VisitorService.standing(m) then
			up += 1
			local pelvis = m:FindFirstChild("LowerTorso")
			if rootAt and pelvis and pelvis:IsA("BasePart") then
				local d = Vector3.new(pelvis.Position.X - rootAt.X, 0, pelvis.Position.Z - rootAt.Z)
				if fresh[m] or (d.Magnitude < VisitorService.NEAR and (d.Magnitude < 6 or d.Unit:Dot(facing) > 0.2)) then
					near += 1
				end
			end
		end
	end
	-- All that are missing at once (the 3-second rule), within the caps.
	local room = math.min(cap - #bodies - (require(script.Parent:WaitForChild("DummySpawn")) :: any).pendingFor(player), EventService.dummyRoom() - VisitorService.ROOM_KEEP) -- (V9-0l: GOD MODE bodies on their way down count)
	local need = math.max(want - up, VisitorService.NEAR_WANT - near, 0)
	local n = math.min(need, room)
	local came = 0
	for _ = 1, n do
		if walkIn(player, list) then
			came += 1
		end
	end
	-- Extras once everyone is up again: walkers past the minimum and a spare puff away, out of sight.
	if need <= 0 and up > want + VisitorService.SPARE and rootAt then
		for i = #list, 1, -1 do
			local m = list[i].model
			local pelvis = m:FindFirstChild("LowerTorso")
			if m:GetAttribute("WalkIn") and VisitorService.standing(m) and pelvis and pelvis:IsA("BasePart") then
				local d = Vector3.new(pelvis.Position.X - rootAt.X, 0, pelvis.Position.Z - rootAt.Z)
				-- (Out of view: behind the player, or far off: then the puff is small and the crowd thins.)
				if d.Magnitude > 45 or (d.Magnitude > 20 and d.Unit:Dot(facing) < -0.2) then
					puff(pelvis.Position)
					downSince[m] = nil
					m:Destroy()
					table.remove(list, i)
					break -- (one a check: never a whole crowd vanishing at once)
				end
			end
		end
	end
	return came
end

-- Tests: a player's visitors now.
function VisitorService.of(player: Player): { Model }
	local out = {}
	for _, v in visitors[player] or {} do
		if v.model.Parent then
			table.insert(out, v.model)
		end
	end
	return out
end
function VisitorService.tickForTest(player: Player)
	if inOwnLab(player) then
		fill(player)
	else
		clear(player)
	end
end
VisitorService.clearForTest = clear

function VisitorService.start()
	Players.PlayerRemoving:Connect(clear)
	-- (V9-0j: always a target, checked often and cheaply; idle for anyone not in their own lab.)
	task.spawn(function()
		while true do
			task.wait(VisitorService.KEEP_EVERY)
			if game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true and not loopInTests then
				continue -- (the tests set their own scenes; T166 lets this real loop run: loopInTests)
			end
			for _, player in Players:GetPlayers() do
				pcall(VisitorService.keepTargets, player)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(4)
			local testing = game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true
			for _, player in Players:GetPlayers() do
				if testing then
					continue -- (the tests set their own scenes: VisitorService.tickForTest)
				end
				if inOwnLab(player) then
					fill(player)
					for _, v in visitors[player] or {} do
						if os.clock() - v.pickedAt > VisitorService.TRY_EVERY then
							pick(player, v)
						end
					end
				elseif visitors[player] then
					clear(player)
				end
			end
		end
	end)
end

return VisitorService
