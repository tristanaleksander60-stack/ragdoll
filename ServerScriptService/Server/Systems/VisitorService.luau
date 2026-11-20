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

VisitorService.VISITORS = 3
VisitorService.ROOM_KEEP = 8 -- bodies always left free under the cap for events and the horde
VisitorService.TRY_EVERY = 14 -- s a visitor stays with one thing before it picks another
VisitorService.SPOTS = { "CannonPad", "StationPad", "TrampolinePad", "LavaPool" }
local SHIRTS = { Color3.fromRGB(60, 160, 255), Color3.fromRGB(255, 170, 40), Color3.fromRGB(120, 220, 110) }

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

local function clear(player: Player)
	for _, v in visitors[player] or {} do
		if v.model.Parent and v.model:GetAttribute("Vital") ~= "Dead" then
			v.model:Destroy()
		end
	end
	visitors[player] = nil
end

local function fill(player: Player)
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
-- stand in it: the row, the visitors and your GOD MODE ones together. When fewer stand (knocked out,
-- in a creature, thrown away), a new one walks in from the hub's rim with a puff, heading for a spot
-- in front of you, then goes about the lab like any visitor. One pool with the visitors; all bodies of
-- the lab stay under the device's ragdoll cap (Config.FX_CAPS) and the server's room. A visitor that
-- lies or is gone from the lab for STILL_RECYCLE s is recycled.

VisitorService.KEEP_EVERY = 1.5 -- s between checks
VisitorService.WALK_IN_RIM = 60 -- studs from the lab's spawn: where a walker comes in
VisitorService.WALK_IN_AT_ONCE = 2 -- walkers a check may bring
VisitorService.STILL_RECYCLE = 30 -- s a visitor may lie still or be out of the lab before it goes

local downSince: { [Model]: number } = {}

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
		for _, m in (require(script.Parent:WaitForChild("DummySpawn")) :: any).of(player) do
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

-- One walker in from the rim, heading for a spot in front of the player.
local function walkIn(player: Player, list: { Visitor })
	local origin = Lab.originFor(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local facing = Lab.SPAWN_FACING
	if root and root:IsA("BasePart") then
		local look = root.CFrame.LookVector
		facing = if Vector3.new(look.X, 0, look.Z).Magnitude > 0.1 then Vector3.new(look.X, 0, look.Z).Unit else facing
	end
	-- (In from the rim ahead of the player, a little to one side, so it walks into view.)
	local a = math.rad(math.random(-35, 35))
	local dir = Vector3.new(facing.X * math.cos(a) - facing.Z * math.sin(a), 0, facing.X * math.sin(a) + facing.Z * math.cos(a))
	local at = Vector3.new(origin.X, origin.Y + 3, origin.Z) + dir * VisitorService.WALK_IN_RIM
	local here = if root and root:IsA("BasePart") then root.Position else origin
	local goal = here + facing * math.random(18, 30) + Vector3.new(facing.Z, 0, -facing.X) * math.random(-10, 10)
	puff(at)
	local model = DummyFactory.spawn(at, goal, player)
	model.Name = "Visitor"
	model:SetAttribute("Visitor", player.UserId)
	model:SetAttribute("WalkIn", true)
	model:SetAttribute("Personality", "Brave")
	model:SetAttribute("Home", Vector3.new(goal.X, at.Y, goal.Z))
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
end

-- Keeps at least the minimum standing in the player's own lab (nothing while they are elsewhere).
-- Returns how many walked in.
function VisitorService.keepTargets(player: Player): number
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
	-- Recycle a visitor that lies, is held in a machine or left the lab for too long.
	for i = #list, 1, -1 do
		local m = list[i].model
		if not m.Parent then
			table.remove(list, i)
			downSince[m] = nil
			continue
		end
		local pelvis = m:FindFirstChild("LowerTorso")
		local away = pelvis and pelvis:IsA("BasePart") and Lab.ownerAt(pelvis.Position) ~= player
		if VisitorService.standing(m) and not away then
			downSince[m] = nil
		else
			downSince[m] = downSince[m] or now
			if now - downSince[m] > VisitorService.STILL_RECYCLE and not m:GetAttribute("InMachine") then
				downSince[m] = nil
				m:Destroy()
				table.remove(list, i)
			end
		end
	end
	local tier = tierOf(player)
	local want = ((Config :: any).LAB_MIN_TARGETS :: any)[tier] or 5
	local cap = ((Config :: any).FX_CAPS :: any)[tier].ragdolls
	local bodies = VisitorService.bodiesOf(player)
	local up = 0
	-- (A walker that just came in counts as up while it lands from its puff: no second one for it.)
	local fresh: { [Model]: boolean } = {}
	for _, v in list do
		if v.model:GetAttribute("WalkIn") and now - v.pickedAt < 3 then
			fresh[v.model] = true
		end
	end
	for _, m in bodies do
		if fresh[m] or VisitorService.standing(m) then
			up += 1
		end
	end
	local room = math.min(cap - #bodies, EventService.dummyRoom() - VisitorService.ROOM_KEEP)
	local n = math.min(want - up, room, VisitorService.WALK_IN_AT_ONCE)
	for _ = 1, n do
		walkIn(player, list)
	end
	return math.max(0, n)
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
			if game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true then
				continue -- (the tests set their own scenes: keepTargets)
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
