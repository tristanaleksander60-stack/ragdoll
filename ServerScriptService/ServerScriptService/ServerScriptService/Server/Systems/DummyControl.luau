--!strict
-- Who simulates each dummy, and how commands reach the simulator.
--
-- A dummy is owned by a player (their client simulates it: instant reactions, smooth grabbing)
-- or by nobody (the server simulates it: tests, empty servers). The owner's client reports every
-- state change; the server mirrors which joints are kinematic so all machines see the same
-- assemblies and physics replication stays exact. Plasters, ice and shattering are shared visuals
-- and are always done here.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local ActiveRagdoll = require(Shared.Ragdoll.ActiveRagdoll)
local Topology = require(Shared.Ragdoll.Topology)
local Dummies = require(Shared.Dummies)

local RagdollConfig = require(Shared.Ragdoll.Config)
local FROZEN_TIME = RagdollConfig.FROZEN_TIME
local ICE_COLOR = RagdollConfig.ICE_COLOR
local SHATTER_SPEED = 5 -- studs/s a hit must give a frozen dummy to shatter it
local MAX_REPORTS_PER_SECOND = 40

type Ice = { welds: { WeldConstraint }, looks: { [BasePart]: { color: Color3, material: Enum.Material } }, token: number }

local DummyControl = {}

-- Called when a dummy shatters: (position). Set by the effects system.
DummyControl.onShatter = nil :: ((position: Vector3) -> ())?
-- Called when a body goes down (knocked flat or out cold): ProgressService counts takedowns.
DummyControl.onDown = nil :: ((model: Model, state: string) -> ())?

local owners: { [Model]: Player? } = {}
local known: { [Model]: boolean } = {}
local jointNames: { [Model]: { string } } = {}
local brokenSeen: { [Model]: { [string]: boolean } } = {}
local ice: { [Model]: Ice } = {}
-- Commands for an owner whose client has not reported yet (just spawned or just handed over).
local ready: { [Model]: boolean } = {}
local pending: { [Model]: { { any } } } = {}
local MAX_PENDING = 6
local reportWindow: { [Player]: { start: number, count: number } } = {}
-- The latest report over the rate limit, per dummy: applied as soon as there is room again, so the
-- server always ends up agreeing with the simulator (an older report may be skipped, never the last).
type Report = { player: Player, state: string, broken: { string }, held: boolean }
local waitingReports: { [Model]: Report } = {}
local cmd: RemoteEvent

local function partsOf(model: Model): { BasePart }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Plaster" then
			table.insert(list, d)
		end
	end
	return list
end

local function jointsOf(model: Model): { [string]: AnimationConstraint }
	local map = {}
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") then
			map[d.Name] = d
		end
	end
	return map
end

local function send(model: Model, owner: Player, ...: any)
	if ready[model] then
		cmd:FireClient(owner, ...)
		return
	end
	local queue = pending[model] or {}
	pending[model] = queue
	if #queue >= MAX_PENDING then
		table.remove(queue, 1) -- the latest commands (a reset, a heal) matter most
	end
	table.insert(queue, table.pack(...))
end

local function giveParts(model: Model, owner: Player?)
	for _, part in partsOf(model) do
		if not part.Anchored then
			pcall(part.SetNetworkOwner, part, owner)
		end
	end
end

function DummyControl.ownerOf(model: Model): Player?
	return owners[model]
end

-- Hands simulation of a dummy to a player's client, or back to the server (owner = nil).
function DummyControl.setOwner(model: Model, owner: Player?)
	if known[model] and owners[model] == owner then
		return
	end
	local wasServer = known[model] and owners[model] == nil
	known[model] = true
	owners[model] = owner
	ready[model] = nil
	pending[model] = nil
	model:SetAttribute("SimulatedBy", 0)
	model:SetAttribute("Owner", if owner then owner.UserId else 0)
	if owner then
		if wasServer then
			ActiveRagdoll.teardown(model)
		end
		model.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
		pcall(function()
			model:AddPersistentPlayer(owner)
		end)
		giveParts(model, owner)
	else
		ActiveRagdoll.setup(model)
		giveParts(model, nil)
	end
end

-- Parts welded onto a live body (a Christmas hat put on while it walks about) join its assembly as
-- the server's: this hands the whole body back to whoever simulates it.
function DummyControl.reassertOwner(model: Model)
	if known[model] then
		giveParts(model, owners[model])
	end
end

-- Registers a freshly prepared dummy with its first owner.
function DummyControl.register(model: Model, owner: Player?)
	local names = {}
	for name in jointsOf(model) do
		table.insert(names, name)
	end
	jointNames[model] = names
	brokenSeen[model] = {}
	-- The hospital chart (HospitalCharts on every screen): knock-outs and bones broken so far, kept
	-- here whoever simulates the dummy (the state and the broken count reach this server either way).
	model:SetAttribute("Hits", 0)
	model:SetAttribute("KOs", 0)
	model:SetAttribute("Bones", 0)
	local lastState = model:GetAttribute("RagdollState")
	local lastBroken = 0
	model:GetAttributeChangedSignal("RagdollState"):Connect(function()
		local state = model:GetAttribute("RagdollState")
		if state == "Out" and lastState ~= "Out" then
			model:SetAttribute("KOs", ((model:GetAttribute("KOs") :: number?) or 0) + 1)
		end
		local down = state == "Ragdoll" or state == "Out"
		local wasDown = lastState == "Ragdoll" or lastState == "Out"
		lastState = state
		local listener = DummyControl.onDown
		if down and not wasDown and listener then
			task.spawn(listener, model, state :: string)
		end
	end)
	model:GetAttributeChangedSignal("Broken"):Connect(function()
		local broken = (model:GetAttribute("Broken") :: number?) or 0
		if broken > lastBroken then
			model:SetAttribute("Bones", ((model:GetAttribute("Bones") :: number?) or 0) + broken - lastBroken)
		end
		lastBroken = broken
	end)
	model.Destroying:Once(function()
		owners[model] = nil
		known[model] = nil
		jointNames[model] = nil
		brokenSeen[model] = nil
		ice[model] = nil
		ready[model] = nil
		pending[model] = nil
	end)
	DummyControl.setOwner(model, owner)
end

local function shatter(model: Model)
	local chest = model:FindFirstChild("UpperTorso") :: BasePart?
	local listener = DummyControl.onShatter
	if chest and listener then
		task.spawn(listener, chest.Position)
	end
	model:Destroy()
end

-- One more hit on the hospital chart (a hit the owner's client already played counts too: HitService).
function DummyControl.countHit(model: Model)
	model:SetAttribute("Hits", ((model:GetAttribute("Hits") :: number?) or 0) + 1)
end

-- Applies a hit wherever the dummy is simulated. Returns the new state ("Sent" when forwarded).
-- by: the player behind it (their tool, prop, blast or build); nobody for events and tests. Only
-- that player can be knocked over by the dummy while it flies (PlayerBody, Dummies.blame).
-- A hit or push the server itself carried out: stamped so a knock-down after it can count as a
-- takedown (ProgressService); a client's own report of a contact never stamps it. (At most twice a
-- second: pushes come many times a second.) ServerHitBy names whose hit it was (0: nobody's); a
-- takedown needs the blamed player to be that one.
function DummyControl.stampServerHit(model: Model, by: number?)
	local now = Workspace:GetServerTimeNow()
	local who = by or 0
	local last = model:GetAttribute("ServerHitAt")
	if type(last) ~= "number" or now - last >= 0.5 or model:GetAttribute("ServerHitBy") ~= who then
		model:SetAttribute("ServerHitAt", now)
		model:SetAttribute("ServerHitBy", who)
	end
end

-- gun: a gun's round (HitMath.gunOf): where it lands decides what the body does (round 3, M2).
DummyControl.HANDOFF_GAP = 1.5
local lastHandoff: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

function DummyControl.hit(model: Model, part: BasePart, impulse: Vector3, position: Vector3, maxBodySpeed: number?, by: Player?, gun: number?): string?
	if not known[model] then
		return nil
	end
	DummyControl.countHit(model)
	Dummies.setBlame(model, if by then by.UserId else 0)
	DummyControl.stampServerHit(model, if by then by.UserId else 0)
	if model:GetAttribute("Frozen") == true then
		local mass = (model:GetAttribute("Mass") :: number?) or 10
		if impulse.Magnitude / mass >= SHATTER_SPEED then
			shatter(model)
			return "Shatter"
		end
	end
	-- (23 Nov 2026, owner: "it lags like mad in a lab with others"): the body's simulation goes to whoever hits it
	-- (as the top ragdoll games do), so the hitter sees it react at once instead of a round trip through the lab
	-- owner's machine, and no one machine runs every body. Only between players sharing a lab, at most every
	-- HANDOFF_GAP s a body.
	local current = owners[model]
	if by and current and by ~= current and by.Parent and (by:GetAttribute("SharedGuest") ~= nil or by:GetAttribute("SharedHost") == true)
		and os.clock() - (lastHandoff[model] or -math.huge) >= DummyControl.HANDOFF_GAP then
		lastHandoff[model] = os.clock()
		DummyControl.setOwner(model, by)
	end
	local owner = owners[model]
	if owner then
		send(model, owner, "Hit", model, part.Name, impulse, position, maxBodySpeed or false, gun)
		return "Sent"
	end
	local state = ActiveRagdoll.hit(model, part, impulse, position, maxBodySpeed, gun)
	if state == "Shatter" then
		shatter(model)
	end
	return state
end

-- Pushes from fans and black holes arrive many times a second, from many sources at once. They
-- add up per dummy and go out together every PUSH_INTERVAL: one remote per dummy ten times a
-- second at most, however many fans and black holes are out.
local PUSH_INTERVAL = 0.1
local pushes: { [Model]: Vector3 } = {}
local pushFlushQueued = false

local function flushPushes()
	pushFlushQueued = false
	for model, delta in pushes do
		local owner = owners[model]
		if owner then
			send(model, owner, "Push", model, delta)
		elseif known[model] then
			ActiveRagdoll.push(model, delta)
		end
	end
	table.clear(pushes)
end

function DummyControl.push(model: Model, deltaVelocity: Vector3, by: Player?)
	if not known[model] then
		return
	end
	Dummies.setBlame(model, if by then by.UserId else 0)
	DummyControl.stampServerHit(model, if by then by.UserId else 0)
	pushes[model] = (pushes[model] or Vector3.zero) + deltaVelocity
	if not pushFlushQueued then
		pushFlushQueued = true
		task.delay(PUSH_INTERVAL, flushPushes)
	end
end

local thaw: (model: Model, token: number) -> ()

-- Teleports a dummy and puts it back to a clean standing state (an ice statue thaws first, so
-- the server's ice and the simulator agree).
function DummyControl.reset(model: Model, cframe: CFrame)
	local frozen = ice[model]
	if frozen then
		thaw(model, frozen.token)
	end
	for _, d in model:GetDescendants() do
		-- Plasters, and anything stuck on it by a tool (a rocket must not fire it off again).
		if d.Name == "Plaster" or d:GetAttribute("Gadget") == true then
			d:Destroy()
		end
	end
	brokenSeen[model] = {}
	model:SetAttribute("Broken", 0)
	local owner = owners[model]
	if owner then
		send(model, owner, "Reset", model, cframe)
	else
		model:PivotTo(cframe)
		ActiveRagdoll.reset(model)
	end
end

-- A push that names nobody: the blame and the server's hit stamp stay as they are (a bubble that
-- floats or slows everything in it must not take someone else's takedown).
function DummyControl.nudge(model: Model, deltaVelocity: Vector3)
	if not known[model] then
		return
	end
	pushes[model] = (pushes[model] or Vector3.zero) + deltaVelocity
	if not pushFlushQueued then
		pushFlushQueued = true
		task.delay(PUSH_INTERVAL, flushPushes)
	end
end

-- Moves a dummy somewhere else as it is (a portal): nothing mended, nothing taken off.
function DummyControl.move(model: Model, cframe: CFrame)
	if not known[model] then
		return
	end
	local owner = owners[model]
	if owner then
		send(model, owner, "Move", model, cframe)
	else
		model:PivotTo(cframe)
	end
end

-- Spells that must end before a body is frozen (their colours would be frozen in): ToyService.
DummyControl.beforeFreeze = {} :: { (Model) -> () }

-- Mends broken limbs wherever the dummy is simulated (plasters come off here).
function DummyControl.heal(model: Model)
	if not known[model] then
		return
	end
	for _, d in model:GetDescendants() do
		if d.Name == "Plaster" then
			d:Destroy()
		end
	end
	brokenSeen[model] = {}
	model:SetAttribute("BrokenJoints", "")
	model:SetAttribute("Broken", 0)
	local owner = owners[model]
	if owner then
		send(model, owner, "Heal", model)
	else
		ActiveRagdoll.heal(model)
	end
end

function thaw(model: Model, token: number)
	local state = ice[model]
	if not state or state.token ~= token then
		return
	end
	ice[model] = nil
	for _, weld in state.welds do
		weld:Destroy()
	end
	for part, look in state.looks do
		part.Color = look.color
		part.Material = look.material
	end
	for _, joint in jointsOf(model) do
		joint.Enabled = true
	end
	model:SetAttribute("Frozen", false)
	local owner = owners[model]
	if owner then
		giveParts(model, owner)
	else
		ActiveRagdoll.setExternalFrozen(model, false)
	end
end

-- Freeze ray: turns the dummy into a rigid ice statue for a while.
function DummyControl.freeze(model: Model)
	-- (A body missing a limb is not frozen: the statue would weld the loose limb to it, and the thaw
	-- would put the cut joint back.) Round 4, M10: nor a dead one (no shatter, no thaw that puts it
	-- down again and counts another takedown).
	if not known[model] or ice[model] or (model:GetAttribute("Severed") or "") ~= "" or model:GetAttribute("Vital") == "Dead" then
		return
	end
	local pelvis = model:FindFirstChild("LowerTorso") :: BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if not pelvis then
		return
	end
	for _, fn in DummyControl.beforeFreeze do
		fn(model)
	end
	local welds: { WeldConstraint } = {}
	local looks: { [BasePart]: { color: Color3, material: Enum.Material } } = {}
	for _, part in partsOf(model) do
		if part ~= pelvis and part.Name ~= "Rocket" then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "FreezeWeld"
			weld.Part0 = pelvis
			weld.Part1 = part
			weld.Parent = pelvis
			table.insert(welds, weld)
		end
		if part ~= root then
			looks[part] = { color = part.Color, material = part.Material }
			part.Color = ICE_COLOR
			part.Material = Enum.Material.Ice
		end
	end
	for _, joint in jointsOf(model) do
		joint.Enabled = false
	end
	local token = os.clock()
	ice[model] = { welds = welds, looks = looks, token = token }
	model:SetAttribute("Frozen", true)
	model:SetAttribute("RagdollState", "Frozen")
	local owner = owners[model]
	if owner then
		giveParts(model, owner)
	else
		ActiveRagdoll.setExternalFrozen(model, true)
		giveParts(model, nil)
	end
	task.delay(FROZEN_TIME, thaw, model, token)
end

local function reportAllowed(player: Player): boolean
	local now = os.clock()
	local w = reportWindow[player]
	if not w or now - w.start > 1 then
		w = { start = now, count = 0 }
		reportWindow[player] = w
	end
	w.count += 1
	return w.count <= MAX_REPORTS_PER_SECOND
end

-- The owner's client reports a state change: mirror kinematic flags, plasters and state.
local applyReport: (player: Player, m: Model, state: string, broken: { string }, held: boolean) -> ()

local function onTopology(player: Player, model: unknown, state: unknown, broken: unknown, held: unknown)
	if typeof(model) ~= "Instance" or not (model :: Instance):IsA("Model") then
		return
	end
	local m = model :: Model
	if owners[m] ~= player or type(state) ~= "string" or type(broken) ~= "table" then
		return
	end
	if not table.find(Topology.STATES, state :: string) then
		return
	end
	-- At most 4 entries, read by index only (a table with string keys reads as empty), and only
	-- joints that can actually break.
	local list: { string } = {}
	local raw = broken :: { any }
	for i = 1, 4 do
		local name = raw[i]
		if type(name) == "string" and RagdollConfig.BREAKABLE_JOINTS[name] then
			table.insert(list, name)
		end
	end
	if not reportAllowed(player) then
		waitingReports[m] = { player = player, state = state :: string, broken = list, held = held == true }
		return
	end
	waitingReports[m] = nil
	applyReport(player, m, state :: string, list, held == true)
end

function applyReport(player: Player, m: Model, state: string, broken: { string }, held: boolean)
	if owners[m] ~= player or not m.Parent then
		return
	end
	local names = jointNames[m]
	if not names then
		return
	end
	local brokenSet: { [string]: boolean } = {}
	local count = 0
	for _, name in broken do
		if table.find(names, name) then
			brokenSet[name] = true
			count += 1
			if count >= 2 then
				break
			end
		end
	end
	-- Only the server freezes dummies.
	if state == "Frozen" and not ice[m] then
		return
	end
	-- Getting about is only for lab dummies, and crawling only on two broken legs.
	if (state == "Walking" or state == "Fleeing" or state == "Crawling") and typeof(m:GetAttribute("Home")) ~= "Vector3" then
		return
	end
	if state == "Crawling" then
		local left = brokenSet.LeftHip or brokenSet.LeftKnee
		local right = brokenSet.RightHip or brokenSet.RightKnee
		if not (left and right) then
			return
		end
	end

	if not ice[m] then
		local flags = Topology.flags(state, brokenSet, names)
		if flags then
			local joints = jointsOf(m)
			for name, kinematic in flags do
				local joint = joints[name]
				if joint and joint.IsKinematic ~= kinematic then
					joint.IsKinematic = kinematic
				end
			end
		end
		m:SetAttribute("RagdollState", state)
	end
	-- Held only drives looks on other screens (scared face); a lie here harms nothing.
	m:SetAttribute("Held", held and (state == "Ragdoll" or state == "Out"))
	if held and os.clock() - ((m:GetAttribute("GivenAt") :: number?) or -10) > 1 then
		m:SetAttribute("GivenAt", os.clock()) -- (a player has it: what a machine does to it next is theirs, LabCreatures)
	end

	-- First report from this owner: the client simulates the dummy now; deliver what waited.
	if not ready[m] then
		ready[m] = true
		m:SetAttribute("SimulatedBy", player.UserId)
		local queue = pending[m]
		pending[m] = nil
		if queue then
			for _, args in queue do
				cmd:FireClient(player, table.unpack(args, 1, args.n))
			end
		end
	end

	-- Plasters follow the broken set.
	local seen = brokenSeen[m] or {}
	for name in brokenSet do
		if not seen[name] then
			local limb = ActiveRagdoll.limbOf(m, name)
			if limb then
				ActiveRagdoll.addPlaster(limb)
			end
		end
	end
	if count == 0 and next(seen) ~= nil then
		for _, d in m:GetDescendants() do
			if d.Name == "Plaster" then
				d:Destroy()
			end
		end
	end
	brokenSeen[m] = brokenSet
	local names: { string } = {}
	for name in brokenSet do
		table.insert(names, name)
	end
	table.sort(names)
	m:SetAttribute("BrokenJoints", table.concat(names, ","))
	m:SetAttribute("Broken", count)

	-- New assemblies after a topology change: make sure the owner simulates all of them.
	giveParts(m, player)
end

function DummyControl.start()
	cmd = Net.event(Net.Names.DummyCmd)
	Net.event(Net.Names.Topology).OnServerEvent:Connect(onTopology)
	RunService.Heartbeat:Connect(function()
		for m, report in waitingReports do
			if not m.Parent or owners[m] ~= report.player then
				waitingReports[m] = nil
			elseif reportAllowed(report.player) then
				waitingReports[m] = nil
				applyReport(report.player, m, report.state, report.broken, report.held)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		reportWindow[player] = nil
		for model, owner in owners do
			if owner == player then
				-- (Back to the lab's own player when one is still here, else the server.)
				local labOwner = Players:GetPlayerByUserId((model:GetAttribute("LabOwner") :: number?) or 0)
				DummyControl.setOwner(model, if labOwner and labOwner ~= player then labOwner else nil)
			end
		end
	end)
end

return DummyControl
