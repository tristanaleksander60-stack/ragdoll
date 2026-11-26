--!strict
-- Grab and throw other players in the plaza (phase D, 10 Nov 2026; Fling Things and People's core
-- verb, now between players too). The owner's rule stands: players can hit each other in the
-- plaza, never in a lab, and nobody is hurt.
--
--   grabber's client  Grab <player>  -> checked here (both in the plaza, close, nobody already
--                                       holding or held, the target not just knocked)
--   server            Held <grabber> -> the held player's client goes limp and hangs in front of
--                                       the grabber (its own client simulates its body, as always)
--                     Holding <held> -> the grabber's screen shows the hold
--   grabber           Throw <look>   -> Free <velocity> to the held one: it flies (capped)
--                     Drop           -> Free with no push
--   held              Wriggle        -> free after WRIGGLE_AFTER s (jump three times)
--
-- Release 0.20 (Config.PARTY_THROWS): the members of a running Prank Party may also grab and throw
-- each other inside that party's lab (Zones.mayGrab), and a friend thrown into the cannon, a station,
-- the bullseye or a trap is a TOSS COMBO (ExperimentService.thrown). Hitting stays plaza only.
--
-- A hold always ends: HOLD_MAX, either one leaving the plaza, dying or going, or drifting apart.
-- Every end of a hold counts as the plaza knock (PlayerRagdoll.markPlazaKnock), and nobody may grab
-- that player again for VICTIM_GAP (the same grabber: PAIR_GAP).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Zones = require(Shared.Zones)
local HitMath = require(Shared.HitMath)
local Config = require(Shared.Config)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local ExperimentService = require(script.Parent.ExperimentService)

local PlayerGrab = {}

PlayerGrab.REACH = 14 -- studs between the two roots to start a grab
PlayerGrab.HOLD_MAX = 6 -- s a hold may last
PlayerGrab.WRIGGLE_AFTER = 1.2 -- s held before wriggling free works
PlayerGrab.APART = 30 -- studs apart that ends a hold (the held body lags or got stuck)
PlayerGrab.THROW_SPEED = 85 -- studs/s
PlayerGrab.THROW_LIFT = 0.3
PlayerGrab.TRY_GAP = 0.4 -- s between grab tries per player
PlayerGrab.PAIR_GAP = 10 -- s before the same grabber may grab the same player again
PlayerGrab.VICTIM_GAP = 8 -- s after any hold ends before anyone may grab that player (no tag-team)

type Hold = { grabber: Player, held: Player, since: number, grabberBody: Model?, heldBody: Model?, wantsFree: boolean }

local holds: { [Player]: Hold } = {} -- by grabber
local heldBy: { [Player]: Hold } = {} -- by the one held
local lastTry: { [Player]: number } = {}
local lastPair: { [Player]: { [Player]: number } } = {} -- grabber -> held -> when the hold ended
local lastHeld: { [Player]: number } = {} -- held -> when their last hold ended (by anyone)
local remote: RemoteEvent

-- Release 0.20: the plaza, or inside a running Prank Party's lab between two of its members
-- (Config.PARTY_THROWS, Zones.mayGrab).
local function placeAllows(grabber: Player, target: Player, a: Vector3, b: Vector3): boolean
	return Zones.mayGrab(grabber, target, a, b, Config.PARTY_THROWS == true and Config.PRANK_PARTY == true)
end
PlayerGrab.placeAllows = placeAllows

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- Every end of a hold (thrown, dropped, wriggled, timed out) gives the held player the plaza
-- knock's safe time, and the same grabber waits PAIR_GAP for them: nobody is kept on the floor.
local function finish(hold: Hold, velocity: Vector3?)
	if holds[hold.grabber] ~= hold then
		return
	end
	holds[hold.grabber] = nil
	heldBy[hold.held] = nil
	local pairs_ = lastPair[hold.grabber] or {}
	lastPair[hold.grabber] = pairs_
	pairs_[hold.held] = os.clock()
	lastHeld[hold.held] = os.clock()
	if hold.held.Parent then
		PlayerRagdoll.markPlazaKnock(hold.held)
		remote:FireClient(hold.held, "Free", velocity)
	end
	if hold.grabber.Parent then
		remote:FireClient(hold.grabber, "Free", nil)
	end
end

-- Why `grabber` may not grab `target` now (nil: they may).
function PlayerGrab.refusal(grabber: Player, target: Player): string?
	if target == grabber or not target.Parent then
		return "nobody"
	end
	local a, b = rootOf(grabber), rootOf(target)
	if not a or not b then
		return "nobody"
	end
	if not placeAllows(grabber, target, a.Position, b.Position) then
		return if Config.PARTY_THROWS then "Only in the plaza, or with friends in a Prank Party!" else "Only in the plaza!"
	end
	if (a.Position - b.Position).Magnitude > PlayerGrab.REACH then
		return "Too far away. Walk closer to grab them"
	end
	if holds[grabber] or heldBy[grabber] or PlayerRagdoll.isDown(grabber) then
		return "busy"
	end
	if holds[target] or heldBy[target] then
		return "Someone already has them!"
	end
	local pairs_ = lastPair[grabber]
	local ended = lastHeld[target]
	if (pairs_ and pairs_[target] and os.clock() - pairs_[target] < PlayerGrab.PAIR_GAP)
		or (ended and os.clock() - ended < PlayerGrab.VICTIM_GAP) then
		return "Give them a break! Grab someone else"
	end
	if not PlayerRagdoll.mayPlazaKnock(target) then
		return "They are getting up. Wait a moment!"
	end
	return nil
end

local function begin(grabber: Player, target: Player): Hold
	local hold: Hold = {
		grabber = grabber,
		held = target,
		since = os.clock(),
		grabberBody = grabber.Character,
		heldBody = target.Character,
		wantsFree = false,
	}
	holds[grabber] = hold
	heldBy[target] = hold
	return hold
end

function PlayerGrab.grab(grabber: Player, target: Player): boolean
	local why = PlayerGrab.refusal(grabber, target)
	if why then
		if why ~= "nobody" and why ~= "busy" then
			remote:FireClient(grabber, "Refused", why)
		end
		return false
	end
	begin(grabber, target)
	remote:FireClient(target, "Held", grabber)
	remote:FireClient(grabber, "Holding", target)
	return true
end

-- Throws the held player along `look` (the grabber's camera; checked and capped here).
function PlayerGrab.throw(grabber: Player, look: Vector3)
	local hold = holds[grabber]
	if not hold then
		return
	end
	local m = look.Magnitude
	if m ~= m or m < 0.5 or m > 2 then
		finish(hold, nil)
		return
	end
	-- (Both still in the plaza, or both still in their Prank Party's lab: never thrown from the
	-- plaza into a lab. Otherwise just let go.)
	local a, b = rootOf(grabber), rootOf(hold.held)
	if not a or not b or not placeAllows(grabber, hold.held, a.Position, b.Position) then
		finish(hold, nil)
		return
	end
	local dir = (look.Unit + Vector3.new(0, PlayerGrab.THROW_LIFT, 0)).Unit
	local v = dir * math.min(PlayerGrab.THROW_SPEED, HitMath.PLAYER_MAX_KNOCK)
	finish(hold, v)
	-- (Release 0.20: where they land in the next few seconds may be a TOSS COMBO: ExperimentService.)
	ExperimentService.thrown(hold.held, grabber)
end

function PlayerGrab.drop(grabber: Player)
	local hold = holds[grabber]
	if hold then
		finish(hold, nil)
	end
end

-- A wriggle before WRIGGLE_AFTER is kept: the hold ends the moment it may (watch).
function PlayerGrab.wriggle(held: Player)
	local hold = heldBy[held]
	if not hold then
		return
	end
	if os.clock() - hold.since >= PlayerGrab.WRIGGLE_AFTER then
		finish(hold, nil)
	else
		hold.wantsFree = true
	end
end

-- Why a running hold must end now (nil: it goes on).
local function endReason(hold: Hold, now: number): string?
	local a, b = rootOf(hold.grabber), rootOf(hold.held)
	if now - hold.since > PlayerGrab.HOLD_MAX then
		return "time"
	elseif hold.wantsFree and now - hold.since >= PlayerGrab.WRIGGLE_AFTER then
		return "wriggled"
	elseif not a or not b or hold.grabber.Character ~= hold.grabberBody or hold.held.Character ~= hold.heldBody then
		return "gone" -- (died, reset or respawned: a new body is never held)
	elseif PlayerRagdoll.isDown(hold.grabber) then
		return "grabber down"
	elseif not placeAllows(hold.grabber, hold.held, a.Position, b.Position) then
		return "left the plaza" -- (or the Prank Party's lab, or the party ended)
	elseif (a.Position - b.Position).Magnitude > PlayerGrab.APART then
		return "apart"
	end
	return nil
end
PlayerGrab.endReasonForTest = endReason

-- Tests: a hold between two players without the checks of a grab (the suite has one player, who
-- holds itself; its client is not told, so the body stays up and only the server's rules run).
function PlayerGrab.holdForTest(grabber: Player, held: Player): () -> ()
	local hold = begin(grabber, held)
	return function()
		finish(hold, nil)
	end
end
function PlayerGrab.clearPairsForTest(grabber: Player)
	lastPair[grabber] = nil
	lastHeld[grabber] = nil
end
function PlayerGrab.holdOfForTest(held: Player): Hold?
	return heldBy[held]
end

function PlayerGrab.holdingOf(grabber: Player): Player?
	local hold = holds[grabber]
	return hold and hold.held
end

function PlayerGrab.heldByOf(held: Player): Player?
	local hold = heldBy[held]
	return hold and hold.grabber
end

local function onEvent(player: Player, kind: unknown, arg: unknown)
	if type(kind) ~= "string" then
		return
	end
	if kind == "Grab" then
		local now = os.clock()
		if now - (lastTry[player] or -math.huge) < PlayerGrab.TRY_GAP then
			return
		end
		lastTry[player] = now
		if typeof(arg) == "Instance" and (arg :: Instance):IsA("Player") then
			PlayerGrab.grab(player, arg :: Player)
		end
	elseif kind == "Throw" and typeof(arg) == "Vector3" then
		PlayerGrab.throw(player, arg :: Vector3)
	elseif kind == "Drop" then
		PlayerGrab.drop(player)
	elseif kind == "Wriggle" then
		PlayerGrab.wriggle(player)
	end
end

local clock = 0
local function watch(dt: number)
	clock += dt
	if clock < 0.25 then
		return
	end
	clock = 0
	local now = os.clock()
	for _, hold in holds do
		if endReason(hold, now) then
			finish(hold, nil)
		end
	end
end

function PlayerGrab.start()
	remote = Net.event(Net.Names.PlayerGrab)
	remote.OnServerEvent:Connect(onEvent)
	RunService.Heartbeat:Connect(watch)
	Players.PlayerRemoving:Connect(function(player: Player)
		local a, b = holds[player], heldBy[player]
		if a then
			finish(a, nil)
		end
		if b then
			finish(b, nil)
		end
		lastTry[player] = nil
		lastPair[player] = nil
		lastHeld[player] = nil
		for _, pairs_ in lastPair do
			pairs_[player] = nil
		end
	end)
end

return PlayerGrab
