--!strict
-- Broadcasts hit, landing, break and shatter moments to clients, which play sound, sparks and
-- camera shake. Nothing here changes gameplay; clients may drop these freely.
--
-- Sources: toy use (server), server-simulated dummies (ActiveRagdoll.onEvent), shattering
-- (DummyControl), and owning clients relaying moments of their own simulation (FxRelay), which
-- are passed on to everyone else.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local ActiveRagdoll = require(Shared.Ragdoll.ActiveRagdoll)
local DummyControl = require(script.Parent.DummyControl)
local Workspace = game:GetService("Workspace")

local MIN_LAND_SPEED = 14
local RELAY_PER_SECOND = 20
local RELAY_KINDS = { Land = true, Break = true, Hit = true }
-- Contact effects a client reports for the dummies it simulates (PropContacts, HitMath.PROPS).
local RELAY_IDS = {
	Anvil = true,
	Bowling = true,
	Cannon = true,
	Trampoline = true,
	SpringPad = true,
	BananaPeel = true,
	Machine = true,
	CannonPad = true, -- the playground's human cannon
}
local RELAY_REACH = 20 -- studs: a relayed moment happens next to a dummy the sender simulates
local RELAY_MAX_SPEED = 160 -- studs/s: the fastest any contact really goes (a human cannon shot)
-- Effects only go to players near enough to see them (the lab is 2 km across; a phone far away has
-- no use for a bang it cannot see).
local FX_REACH = 350

-- Whether a client's reported moment is next to one of the dummies it simulates (the only
-- moments a client can see first).
local function nearOwnDummy(player: Player, position: Vector3): boolean
	local folder = Workspace:FindFirstChild("Dummies")
	for _, model in if folder then folder:GetChildren() else {} do
		if model:IsA("Model") and DummyControl.ownerOf(model) == player then
			local pelvis = model:FindFirstChild("LowerTorso")
			if pelvis and pelvis:IsA("BasePart") and (pelvis.Position - position).Magnitude <= RELAY_REACH then
				return true
			end
		end
	end
	return false
end

-- Whether a point is by one of the playground's cannon pads.
local function nearCannonPad(position: Vector3): boolean
	local playground = Workspace:FindFirstChild("Playground")
	for _, d in if playground then playground:GetDescendants() else {} do
		if d.Name == "CannonPad" and d:IsA("BasePart") and (d.Position - position).Magnitude <= 30 then
			return true
		end
	end
	return false
end

local FxService = {}

local event: RemoteEvent? = nil
-- Who wants to hear every moment (the crowd's ears, the labs' cowards): (kind, position, speed,
-- toyId, who made it: a UserId or 0).
local hearers: { (string, Vector3, number, string, number) -> () } = {}
local relayWindow: { [Player]: { start: number, count: number } } = {}

local finite = require(Shared.Dummies).finite

-- Sends a moment to every player near it (except one: whoever reported it, they played it already).
-- byHand: for a player's hit, whether their avatar did it by hand (their client's word: only looks).
local function broadcast(kind: string, position: Vector3, speed: number, toyId: string, sourceUserId: number, except: Player?, byHand: boolean?)
	for _, hear in hearers do
		task.spawn(hear, kind, position, speed, toyId, sourceUserId)
	end
	local e = event
	if not e then
		return
	end
	for _, player in Players:GetPlayers() do
		local character = player ~= except and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- No body yet (just joined, respawning): send it anyway, it may be watching.
		if player ~= except and (not root or not root:IsA("BasePart") or (root.Position - position).Magnitude <= FX_REACH) then
			e:FireClient(player, kind, position, speed, toyId, sourceUserId, nil, byHand)
		end
	end
end

function FxService.hit(position: Vector3, speed: number, toyId: string, sourceUserId: number?, byHand: boolean?)
	broadcast("Hit", position, speed, toyId, sourceUserId or 0, nil, byHand)
end

-- A player threw or put down a tool (a bomb, a prop, a gadget on a dummy): the others see their
-- avatar throw it. Not sent back to the thrower (their own client played it).
-- Calls `hear` with every moment the server shares (hits, blasts, landings, breaks), wherever it
-- came from: (kind, position, speed, toyId, who made it: a UserId or 0).
function FxService.onMoment(hear: (string, Vector3, number, string, number) -> ())
	table.insert(hearers, hear)
end

-- A gun fired at nothing: the others see the shot (their own client played it already).
function FxService.shot(player: Player, position: Vector3, toyId: string)
	broadcast("Shot", position, 0, toyId, player.UserId, player)
end

function FxService.used(player: Player, position: Vector3, toyId: string)
	broadcast("Used", position, 0, toyId, player.UserId, player)
end

-- The Mega Bomb's fall (N7): every client draws the bomb falling onto `position` for `seconds`
-- (FxController). Only a look: the server's blast follows on its own clock.
function FxService.bombFall(position: Vector3, seconds: number)
	local e = event
	if e then
		e:FireAllClients("BombFall", position, seconds, "", 0)
	end
end

-- A festive pop (round 3, M7: a present opened, presents dropping): sparkles and a cheer.
function FxService.gift(position: Vector3)
	broadcast("Gift", position, 20, "", 0)
end

function FxService.shatter(position: Vector3)
	broadcast("Shatter", position, 30, "", 0)
end

local function onRelay(player: Player, kind: unknown, position: unknown, speed: unknown, toyId: unknown)
	local e = event
	if not e or type(kind) ~= "string" or not RELAY_KINDS[kind :: string] then
		return
	end
	if typeof(position) ~= "Vector3" or not finite(position :: Vector3) or type(speed) ~= "number" then
		return
	end
	local now = os.clock()
	local w = relayWindow[player]
	if not w or now - w.start > 1 then
		w = { start = now, count = 0 }
		relayWindow[player] = w
	end
	w.count += 1
	if w.count > RELAY_PER_SECOND then
		return
	end
	-- Only what a client's own contacts can produce (never a blast or an event that shakes screens),
	-- and only next to a dummy that client simulates.
	-- A "Hit" always names its contact; landings and breaks name none.
	if type(toyId) ~= "string" or (if kind == "Hit" then not RELAY_IDS[toyId :: string] else toyId ~= "") then
		return
	end
	if not nearOwnDummy(player, position :: Vector3) then
		return
	end
	-- The human cannon's big moment only happens at the cannon.
	if toyId == "CannonPad" and not nearCannonPad(position :: Vector3) then
		return
	end
	local v = speed :: number
	broadcast(kind :: string, position :: Vector3, if v == v then math.clamp(v, 0, RELAY_MAX_SPEED) else 0, toyId :: string, player.UserId, player)
end

function FxService.start()
	local e = Net.event(Net.Names.Fx)
	event = e
	Net.event(Net.Names.FxRelay).OnServerEvent:Connect(onRelay)
	Players.PlayerRemoving:Connect(function(player)
		relayWindow[player] = nil
	end)
	-- Moments from dummies the server simulates itself.
	ActiveRagdoll.onEvent = function(kind: string, _model: Model, position: Vector3, speed: number)
		if kind == "Land" and speed >= MIN_LAND_SPEED then
			broadcast("Land", position, speed, "", 0)
		elseif kind == "Break" then
			broadcast("Break", position, speed, "", 0)
		end
	end
end

return FxService
