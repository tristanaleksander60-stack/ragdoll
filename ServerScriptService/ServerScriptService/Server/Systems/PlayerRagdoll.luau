--!strict
-- Players' own bodies as ragdolls, split the same way as the dummies (vault: "Snippets - Ragdoll",
-- "AnimationConstraint and Physically Simulated Characters"):
--
--   the player's client   simulates its own body: goes limp, flies, lies still and gets up
--                          (PlayerBody), and reports every state change
--   this server           mirrors which joints are loose and the limbs' collisions, so every
--                          machine agrees and physics replication stays exact; tells the client
--                          about knocks only the server sees (explosions, the human cannon); and
--                          checks where the body ends up when it gets up
--
-- The server never touches the Humanoid's state or the body's network owner: the player keeps
-- simulating their own avatar the whole time, so it looks smooth to them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Log)
local HitMath = require(Shared.HitMath)
local Places = require(Shared.Places)
local ActiveRagdoll = require(Shared.Ragdoll.ActiveRagdoll)
local Topology = require(Shared.Ragdoll.Topology)

local log = Log.new("Body")

local PlayerRagdoll = {}

local MAX_KNOCK = HitMath.PLAYER_MAX_KNOCK
local LAUNCH_MAX = HitMath.PLAYER_LAUNCH_MAX
-- Reports are paced by a token bucket. One over budget is not lost: the latest state waits and is
-- applied as soon as there is a token, so the server always ends up agreeing with the client.
local REPORT_BURST = 8
local REPORTS_PER_SECOND = 6
local MAX_DISTANCE = 1500 -- studs from the lab a body may get up at before it is respawned
local VOID_MARGIN = HitMath.PLAYER_VOID_MARGIN
local RESPAWN_COOLDOWN = 5 -- s between respawns this system may cause for one player
local WATCH_INTERVAL = 0.25 -- s between checks of the limp bodies (void, death)

type JointSaved = { kinematic: boolean, force: number }
type Saved = {
	joints: { [AnimationConstraint]: JointSaved },
	parts: { [BasePart]: { canCollide: boolean, massless: boolean, physical: PhysicalProperties? } },
	requiresNeck: boolean,
	breakJoints: boolean,
}

type Body = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	saved: Saved,
	joints: { [string]: AnimationConstraint },
	names: { string },
	since: number,
	connections: { RBXScriptConnection },
}

local bodies: { [Player]: Body } = {}
local buckets: { [Player]: { tokens: number, at: number } } = {}
local waiting: { [Player]: { state: string, character: Model? } } = {} -- latest report without a token yet
local lastRespawn: { [Player]: number } = {}
local remote: RemoteEvent

local function takeToken(player: Player): boolean
	local now = os.clock()
	local b = buckets[player]
	if not b then
		b = { tokens = REPORT_BURST, at = now }
		buckets[player] = b
	end
	b.tokens = math.min(REPORT_BURST, b.tokens + (now - b.at) * REPORTS_PER_SECOND)
	b.at = now
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

-- force: respawn even inside the cooldown (a body under the world cannot wait for it).
local function respawn(player: Player, why: string, force: boolean?)
	local now = os.clock()
	if not force and lastRespawn[player] and now - lastRespawn[player] < RESPAWN_COOLDOWN then
		log.warn(player.Name .. " " .. why .. " again within the respawn cooldown; left where it is")
		return
	end
	lastRespawn[player] = now
	log.warn(player.Name .. " " .. why .. "; respawning")
	-- LoadCharacter yields; never inside the loops that call this.
	task.spawn(player.LoadCharacter, player)
end

local function forget(player: Player)
	local body = bodies[player]
	if body then
		bodies[player] = nil
		for _, c in body.connections do
			c:Disconnect()
		end
	end
end

local function liveCharacter(player: Player): (Model?, Humanoid?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character and humanoid and humanoid.Health > 0 and character:FindFirstChild("LowerTorso") then
		return character, humanoid
	end
	return nil, nil
end

local function capped(velocity: Vector3, cap: number): Vector3?
	local m = velocity.Magnitude
	if m ~= m or m == math.huge then
		return nil -- NaN or infinite
	end
	if velocity.Magnitude > cap then
		return velocity.Unit * cap
	end
	return velocity
end

-- The first report that the body went limp: remember how it was and loosen it here too.
local function loosen(player: Player, character: Model, humanoid: Humanoid): Body
	local joints: { [string]: AnimationConstraint } = {}
	local names: { string } = {}
	local saved: Saved = { joints = {}, parts = {}, requiresNeck = humanoid.RequiresNeck, breakJoints = humanoid.BreakJointsOnDeath }
	for _, d in character:GetDescendants() do
		if d:IsA("AnimationConstraint") then
			joints[d.Name] = d
			table.insert(names, d.Name)
			saved.joints[d] = { kinematic = d.IsKinematic, force = d.MaxForce }
		elseif d:IsA("BasePart") then
			saved.parts[d] = { canCollide = d.CanCollide, massless = d.Massless, physical = d.CustomPhysicalProperties }
		end
	end
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	ActiveRagdoll.prepareParts(character)
	-- The root joint holds the invisible root part to the pelvis by force once it is loose; an
	-- avatar comes with no force there (the part would drop through the floor and be destroyed).
	local rootJoint = joints.Root
	if rootJoint then
		rootJoint.MaxForce = math.max(rootJoint.MaxForce, 1e6)
	end
	local body: Body = {
		player = player,
		character = character,
		humanoid = humanoid,
		saved = saved,
		joints = joints,
		names = names,
		since = os.clock(),
		connections = {},
	}
	bodies[player] = body
	-- The client sees this as the server's acknowledgement: until it is gone again, the server's
	-- restore is still on its way and going limp would be undone by it.
	character:SetAttribute("BodyLoose", true)
	table.insert(body.connections, humanoid.Died:Connect(function()
		forget(player)
	end))
	table.insert(body.connections, character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(Workspace) then
			forget(player)
		end
	end))
	return body
end

-- Back on its feet: joints, collisions and the Humanoid exactly as they were.
local function restore(body: Body)
	forget(body.player)
	local s = body.saved
	for joint, j in s.joints do
		if joint.Parent then
			joint.IsKinematic = j.kinematic
			joint.MaxForce = j.force
		end
	end
	for part, p in s.parts do
		if part.Parent then
			part.CanCollide = p.canCollide
			part.Massless = p.massless
			part.CustomPhysicalProperties = p.physical
		end
	end
	if body.humanoid.Parent then
		body.humanoid.RequiresNeck = s.requiresNeck
		body.humanoid.BreakJointsOnDeath = s.breakJoints
	end
	body.character:SetAttribute("RagdollState", nil)
	body.character:SetAttribute("BodyLoose", nil)
end

-- Where the body got up must be somewhere in the world (not under it, not miles away).
local function validSpot(character: Model): boolean
	local pelvis = character:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") then
		return false
	end
	local p = pelvis.Position
	if p ~= p or p.Y < Workspace.FallenPartsDestroyHeight + VOID_MARGIN then
		return false
	end
	local labOrigin = Workspace:GetAttribute("LabOrigin")
	local center = if typeof(labOrigin) == "Vector3" then labOrigin else Vector3.zero
	if Vector3.new(p.X - center.X, 0, p.Z - center.Z).Magnitude < MAX_DISTANCE then
		return true
	end
	-- (v3 phase B: the open-air maps lie far out; a spot inside any place, with room for a throw, is
	-- fine too. Blind review 19 Nov: getting up on one sent the player home.)
	for _, place in Places.list do
		local mid = Places.floorCenter(center, place.id)
		if mid then
			local d = p - mid
			if math.abs(d.X) < place.size.X / 2 + 60 and math.abs(d.Z) < place.size.Z / 2 + 60 and d.Y > -80 and d.Y < place.size.Y + 300 then
				return true
			end
		end
	end
	return false
end

-- The player's client reports a state change of its own body.
local function onReport(player: Player, state: string)
	local character, humanoid = liveCharacter(player)
	if not character or not humanoid then
		return
	end
	local body = bodies[player]
	if body and body.character ~= character then
		forget(player)
		body = nil
	end
	if state == "Standing" then
		if body then
			restore(body)
			if not validSpot(character) then
				respawn(player, "got up somewhere odd")
			end
		end
		return
	end
	if state == "Frozen" then
		return -- players are never frozen
	end
	if not body then
		body = loosen(player, character, humanoid)
	end
	local flags = Topology.flags(state, {}, body.names)
	if flags then
		for name, kinematic in flags do
			local joint = body.joints[name]
			if joint and joint.IsKinematic ~= kinematic then
				joint.IsKinematic = kinematic
			end
		end
	end
	character:SetAttribute("RagdollState", state)
end

local function send(player: Player, kind: string, ...: any)
	if liveCharacter(player) then
		remote:FireClient(player, kind, ...)
	end
end

-- A shove only the server saw (explosions): the player's body goes limp and flies.
function PlayerRagdoll.knock(player: Player, velocity: Vector3)
	local v = capped(velocity, MAX_KNOCK)
	if v then
		send(player, "Knock", v)
	end
end

-- A knock from another player in the plaza (a hit or a blast; round 3, M1): one per player each
-- PLAZA_GAP, never while they are down, so nobody (a crowd, a gun from afar, firecrackers at their
-- feet) can keep a player on the floor. Their KnockSafeUntil attribute (server time) tells every
-- screen, so the hitter's own screen shows "getting up" instead of a hit that does nothing.
PlayerRagdoll.PLAZA_GAP = 3.5 -- s
local lastPlazaKnock: { [Player]: number } = {}
function PlayerRagdoll.mayPlazaKnock(player: Player): boolean
	return os.clock() - (lastPlazaKnock[player] or -math.huge) >= PlayerRagdoll.PLAZA_GAP and not PlayerRagdoll.isDown(player)
end
function PlayerRagdoll.plazaKnock(player: Player, velocity: Vector3): boolean
	if not PlayerRagdoll.mayPlazaKnock(player) then
		return false
	end
	lastPlazaKnock[player] = os.clock()
	player:SetAttribute("KnockSafeUntil", workspace:GetServerTimeNow() + PlayerRagdoll.PLAZA_GAP)
	PlayerRagdoll.knock(player, velocity)
	return true
end
-- A throw by another player (PlayerGrab, phase D) counts as their plaza knock: the same PLAZA_GAP
-- of safety follows, so nobody is grabbed again the moment they land.
function PlayerRagdoll.markPlazaKnock(player: Player)
	lastPlazaKnock[player] = os.clock()
	player:SetAttribute("KnockSafeUntil", workspace:GetServerTimeNow() + PlayerRagdoll.PLAZA_GAP)
end
Players.PlayerRemoving:Connect(function(p)
	lastPlazaKnock[p] = nil
end)

-- Fired on purpose (the human cannon): faster than any knock may be.
function PlayerRagdoll.launch(player: Player, velocity: Vector3)
	local v = capped(velocity, LAUNCH_MAX)
	if v then
		send(player, "Knock", v)
	end
end

-- Go limp where you stand (tests and debugging; players use F or the RAGDOLL button).
function PlayerRagdoll.goLimp(player: Player, stayDown: boolean)
	send(player, "Limp", stayDown)
end

function PlayerRagdoll.getUp(player: Player)
	send(player, "GetUp")
end

-- Whether the player's body is limp (by its client's last report).
function PlayerRagdoll.isDown(player: Player): boolean
	local body = bodies[player]
	return body ~= nil and body.character == player.Character
end

-- A report from the client, paced: without a token the latest state waits for one.
local function receive(player: Player, state: string)
	if takeToken(player) then
		waiting[player] = nil
		onReport(player, state)
	else
		waiting[player] = { state = state, character = player.Character }
	end
end

-- Tests: what the server does with a report from this player's client.
PlayerRagdoll.receive = receive

local watchClock = 0
local function watch(dt: number)
	for player, w in waiting do
		if w.character ~= player.Character then
			waiting[player] = nil -- reported by an avatar that is gone
		elseif takeToken(player) then
			waiting[player] = nil
			onReport(player, w.state)
		end
	end
	watchClock += dt
	if watchClock < WATCH_INTERVAL then
		return
	end
	watchClock = 0
	-- A limp body that fell out of the world (or lost its pelvis there) cannot get up: respawn it.
	for player, body in bodies do
		local pelvis = body.character:FindFirstChild("LowerTorso")
		local fallen = not pelvis or not pelvis:IsA("BasePart")
			or pelvis.Position.Y < Workspace.FallenPartsDestroyHeight + VOID_MARGIN
		if fallen and body.humanoid.Health > 0 then
			forget(player)
			respawn(player, "fell out of the world while limp", true)
		end
	end
end

function PlayerRagdoll.start()
	remote = Net.event(Net.Names.Body)
	remote.OnServerEvent:Connect(function(player: Player, kind: unknown, state: unknown)
		if kind ~= "State" or type(state) ~= "string" or not table.find(Topology.STATES, state) then
			return
		end
		receive(player, state :: string)
	end)
	RunService.Heartbeat:Connect(watch)
	Players.PlayerRemoving:Connect(function(player)
		forget(player)
		buckets[player] = nil
		waiting[player] = nil
		lastRespawn[player] = nil
	end)
	log.info("ready")
end

return PlayerRagdoll
