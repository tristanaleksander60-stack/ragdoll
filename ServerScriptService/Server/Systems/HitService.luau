--!strict
-- Validates hit requests from clients and applies them to dummies.
-- The client only says what it tapped and which toy; the server decides the force.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Toys = require(Shared.Toys)
local Shop = require(Shared.Shop)
local Log = require(Shared.Log)
local HitMath = require(Shared.HitMath)
local Dummies = require(Shared.Dummies)
local DummyControl = require(script.Parent.DummyControl)
local FxService = require(script.Parent.FxService)
local Knockables = require(script.Parent.Knockables)
local ToyService = require(script.Parent.ToyService)
local OnboardingService = require(script.Parent.OnboardingService)
local ProgressService = require(script.Parent.ProgressService)
local VitalsService = require(script.Parent.VitalsService)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local Zones = require(Shared.Zones)
local WoundSpot = require(Shared.WoundSpot)
local GunThreat = require(Shared.GunThreat)
local Anatomy = require(Shared.Anatomy)
local SessionStats = require(script.Parent.SessionStats)
local Ammo = require(Shared.Ammo)
local Config = require(Shared.Config)
local WeaponMechanics = require(script.Parent.WeaponMechanics)
-- (An extra round of a gun's own mechanics never starts more: per player, so one player's rounds
-- never switch off another's: review fix.)
local inMechanicsOf: { [Player]: boolean } = {}

local log = Log.new("Hit")

local MAX_DISTANCE = Toys.REACH -- from the player's character to the hit point
local MAX_POINT_OFFSET = 3 -- studs: a hit point is on the part, give or take this
-- A moving part is where the client saw it a moment ago: the slack grows with its speed.
local LAG_SLACK = 0.3 -- s of movement
local MAX_MOVING_SLACK = 30 -- studs
local MAX_HITS_PER_SECOND = 12
-- The big ones (Toys: heavy = true) share a budget per player, whatever tool they cycle.
local HEAVY_PER_WINDOW = 5
local HEAVY_WINDOW = 3 -- s
-- With ULTRA the big ones refill steadily instead (TNT spam that keeps going: a burst of
-- HEAVY_BURST, then HEAVY_REFILL a second for as long as you like).
local HEAVY_BURST = 10
local HEAVY_REFILL = 4 -- a second

local HitService = {}

HitService.ZERO_DELAY = Shop.ZERO_DELAY -- s between uses of one tool with ULTRA

local lastHit: { [Player]: { [string]: number } } = {}
local window: { [Player]: { start: number, count: number } } = {}
local heavyUses: { [Player]: { number } } = {}
local heavyBucket: { [Player]: { tokens: number, at: number } } = {}

-- Tests: how many heavy uses are kept for a player (never more than one window's worth).
function HitService.heavyCountForTest(player: Player): number
	return #(heavyUses[player] or {})
end

local function bucketOf(player: Player, now: number): { tokens: number, at: number }
	local b = heavyBucket[player]
	if not b then
		-- (Starts with what the normal budget has not just spent: switching ULTRA on is no refill.)
		local recent = 0
		for _, t in heavyUses[player] or {} do
			if now - t <= HEAVY_WINDOW then
				recent += 1
			end
		end
		b = { tokens = math.max(0, HEAVY_BURST - recent * 2), at = now }
		heavyBucket[player] = b
	end
	b.tokens = math.min(HEAVY_BURST, b.tokens + (now - b.at) * HEAVY_REFILL)
	b.at = now
	return b
end

local finite = Dummies.finite
local dummyOf = Dummies.of
local refused: RemoteEvent

-- Tells the player why a tap did nothing (their client shows a short hint). Reasons: "Busy" (the
-- big-tool budget), "Locked" (not unlocked yet), "Occupied" (someone stands there), "Frozen",
-- "TooFar" (out of reach of their avatar), "Missed" (the point was not on the part any more).
-- The last refusal per player (tests read it; the client only gets the remote).
HitService.lastRefusal = {} :: { [Player]: { toy: string, reason: string } }

local function refuse(player: Player, toy: Toys.Toy, reason: string)
	HitService.lastRefusal[player] = { toy = toy.id, reason = reason }
	refused:FireClient(player, toy.id, reason)
end

-- Whether a use fits the limits: 12 taps a second overall, each tool's own cooldown (with slack for
-- lag), and the budget the big tools share. Checking costs nothing: a use is only counted against
-- the cooldown and the budget once it has really happened (commit), so a refused or missed tap
-- never eats into them.
-- Every request counts against 12 a second before anything else (refusals included), so no
-- request, good or bad, can make the server answer more often than that.
-- (An automatic gun, cooldown under AUTO_COOLDOWN, has a bigger budget of its own: the minigun's
-- 22 rounds a second were silently dropped past 12. Audit fix, 10 Nov 2026.)
local AUTO_COOLDOWN = 0.1
local AUTO_PER_SECOND = 26
local function burstOk(player: Player, toy: Toys.Toy?): boolean
	local now = os.clock()
	local w = window[player]
	if not w or now - w.start > 1 then
		w = { start = now, count = 0 }
		window[player] = w
	end
	w.count += 1
	local limit = if toy and toy.cooldown < AUTO_COOLDOWN then AUTO_PER_SECOND else MAX_HITS_PER_SECOND
	return w.count <= limit
end

local function rateOk(player: Player, toy: Toys.Toy): (boolean, string?)
	local now = os.clock()
	local perToy = lastHit[player]
	local last = perToy and perToy[toy.id]
	-- ULTRA (and its free minutes, MoneyService): next to no wait between uses of a tool.
	local zero = player:GetAttribute("ZeroDelay") == true
	local cooldown = if zero then math.min(toy.cooldown, HitService.ZERO_DELAY) else toy.cooldown
	if last and now - last < cooldown * 0.8 then
		return false, nil -- the client shows the cooldown already
	end
	if toy.heavy then
		if zero then
			if bucketOf(player, now).tokens < 1 then
				return false, "Busy"
			end
		else
			heavyBucket[player] = nil -- (ULTRA off: switching it on again starts from recent use)
			local uses = heavyUses[player] or {}
			heavyUses[player] = uses
			while uses[1] and now - uses[1] > HEAVY_WINDOW do
				table.remove(uses, 1)
			end
			if #uses >= HEAVY_PER_WINDOW then
				return false, "Busy"
			end
		end
	end
	return true, nil
end

local function commit(player: Player, toy: Toys.Toy)
	local now = os.clock()
	if toy.gun then
		GunThreat.markFired(player.Character) -- (the gun is raised a moment: GunThreat)
	end
	local perToy = lastHit[player] or {}
	lastHit[player] = perToy
	perToy[toy.id] = now
	if toy.heavy then
		local uses = heavyUses[player] or {}
		heavyUses[player] = uses
		table.insert(uses, now)
		-- (Only the last window is ever read: older uses go now, so ULTRA's rapid fire never piles
		-- up a long list.)
		local keep = 1
		while uses[keep] and now - uses[keep] > HEAVY_WINDOW do
			keep += 1
		end
		if keep > 1 then
			table.move(uses, keep, #uses, 1)
			for i = #uses - keep + 2, #uses do
				uses[i] = nil
			end
		end
		if player:GetAttribute("ZeroDelay") == true then
			local b = bucketOf(player, now)
			b.tokens -= 1
		end
	end
end

-- Whether a point lies on (or right by) a part: inside its box, give or take a little. A point far
-- off a big part (the whole baseplate) is not "on" it just because the part is big.
local function onPart(p: BasePart, pos: Vector3): boolean
	if p:IsA("Terrain") then
		-- Terrain is one huge part: there must be terrain right at the point (the 4-stud voxels
		-- around it, any side: floor, cliff or ceiling).
		local terrain = p :: Terrain
		local region = Region3.new(pos - Vector3.one * MAX_POINT_OFFSET, pos + Vector3.one * MAX_POINT_OFFSET):ExpandToGrid(4)
		local ok, _, occupancy = pcall(terrain.ReadVoxels, terrain, region, 4)
		if not ok then
			return false
		end
		for _, plane in occupancy do
			for _, row in plane do
				for _, value in row do
					if value > 0 then
						return true
					end
				end
			end
		end
		return false
	end
	local l = p.CFrame:PointToObjectSpace(pos)
	local slack = MAX_POINT_OFFSET + math.min(p.AssemblyLinearVelocity.Magnitude * LAG_SLACK, MAX_MOVING_SLACK)
	local half = p.Size / 2 + Vector3.one * slack
	return math.abs(l.X) <= half.X and math.abs(l.Y) <= half.Y and math.abs(l.Z) <= half.Z
end

-- Applies a toy hit to a dummy part. Shared by remote requests and tests.
-- requester: the player who tapped. When they simulate the dummy themselves, their client has
-- already applied the hit (instantly); the server only checks it, shatters ice and shares effects.
-- Where a wound lands, as the server sees it (WoundSpot: the line from the hitter's head; the
-- owner's own screen reacts on the same part).
local function woundSpot(requester: Player?, model: Model, part: BasePart, position: Vector3): (BasePart, Vector3, boolean)
	return WoundSpot.find(if requester then requester.Character else nil, model, part, position)
end
HitService.woundSpotForTest = woundSpot

-- The chance this hit cuts a limb off: the weapon's own; a shotgun (severRange) only up close to
-- the shooter (from afar, or with nobody behind it, a shot only wounds).
function HitService.severFor(toy: Toys.Toy, requester: Player?, position: Vector3): number
	local sever = toy.sever
	local range = toy.severRange
	if range and sever > 0 then
		local character = requester and requester.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root or (root.Position - position).Magnitude > range then
			return 0
		end
	end
	return sever
end

function HitService.applyToy(toy: Toys.Toy, part: BasePart, position: Vector3, direction: Vector3, requester: Player?, byHand: boolean?): string?
	local model = dummyOf(part)
	if not model then
		return nil
	end
	local mass = model:GetAttribute("Mass") :: number?
	if not mass then
		return nil
	end
	local impulse = HitMath.toyImpulse(toy, direction, mass)
	-- Where it really lands decides both what the body does and the wound (never two parts).
	local frozen = model:GetAttribute("Frozen") == true
	local woundPart, woundAt, guarded = part, position, false
	if not frozen then
		woundPart, woundAt, guarded = woundSpot(requester, model, part, position)
	end
	if toy.gun and not frozen then
		-- A round in a leg, remembered on the body itself (server time): whichever machine
		-- simulates it next (ownership may move between two shots) knows the other leg was hit.
		local limb = Anatomy.limbOfPart(woundPart.Name)
		if limb == "LeftLeg" or limb == "RightLeg" then
			model:SetAttribute("LegShot" .. (if limb == "LeftLeg" then "Left" else "Right"), workspace:GetServerTimeNow())
		end
	end
	local state: string?
	-- (A gun's extra rounds, round 5: the client never saw them, so they go to it like any server hit.)
	if requester and DummyControl.ownerOf(model) == requester and model:GetAttribute("Frozen") ~= true and not inMechanicsOf[requester] then
		-- The owner's client already applied it; the server still records who sent it flying.
		state = "Predicted"
		Dummies.setBlame(model, requester.UserId)
		DummyControl.countHit(model)
		-- (The request passed the rate, reach and tool checks: the server saw this hit.)
		DummyControl.stampServerHit(model, requester.UserId)
	else
		state = DummyControl.hit(model, woundPart, impulse, woundAt, nil, requester, HitMath.gunOf(toy))
	end
	if state then
		if requester then
			SessionStats.count(requester, "hits")
			-- Round 5, phase 00: the first hit on your greeter is always a takedown (31% of new players
			-- left with none: a round in an arm only flinches, and the greeter runs from a gun).
			if model:GetAttribute("Greeter") == requester.UserId then
				ProgressService.greeterHit(requester, model)
			end
		end
		FxService.hit(position, toy.speed, toy.id, if requester then requester.UserId else nil, byHand)
		-- A wound where it landed (not on ice): blood, pulse, and a line back to the hitter.
		if not frozen then
			-- Rounds, bolts and blades open wounds; everything else is a blow (it bruises).
			local blunt = not toy.gun and toy.sever <= 0
			local sever = HitService.severFor(toy, requester, position)
			-- (Round 4, M10: a gun's round, the NailGun's too, kills at once in the head: VitalsService.)
			-- (V9-0ac: a newcomer's first takedowns come in 2-3 shots: their hits do NEWCOMER_DAMAGE times the damage
			-- until FIRST_HITS takedowns, instead of the old knock-flat rule.)
			local boost: number? = nil
			if (Config :: any).SHOT_FLINCH and requester and requester:GetAttribute("Newcomer") == true and (ProgressService.takedownsOf(requester) or 0) < ((Config :: any).FIRST_HITS or 3) then
				boost = (Config :: any).NEWCOMER_DAMAGE
			end
			VitalsService.wound(model, woundPart, woundAt, requester, toy.wound, { sever = sever, blunt = blunt, guarded = guarded, round = toy.gun == true, boost = boost })
		end
		-- Round 5: each gun's own (pellets, a round through bodies, a flare, gold sparks). Never
		-- from inside one of its own extra rounds.
		if requester and toy.gun and not inMechanicsOf[requester] then
			inMechanicsOf[requester] = true
			pcall(WeaponMechanics.afterHit, requester, toy, model, woundPart, woundAt, direction)
			inMechanicsOf[requester] = nil
		end
	end
	return state
end

-- A player hit in the plaza: knocked over (the tool's push, capped as every knock is), the hit's
-- look and sound for everyone, no wound and no blood. One knock per target each PLAZA_GAP, which
-- covers lying down, getting up and a moment standing after (a crowd or a gun from afar cannot keep
-- anyone down), only from within PLAYER_REACH, and the tool's own pace for the hitter.
HitService.PLAZA_GAP = PlayerRagdoll.PLAZA_GAP -- s (kept by PlayerRagdoll: blasts share it)
HitService.PLAYER_REACH = 60 -- studs from the hitter to the player hit
function HitService.plazaHit(player: Player, target: Player, toy: Toys.Toy, position: Vector3, direction: Vector3, byHand: boolean?): boolean
	if not PlayerRagdoll.mayPlazaKnock(target) then
		refuse(player, toy, "GettingUp")
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) or (root.Position - position).Magnitude > HitService.PLAYER_REACH then
		return false
	end
	if not OnboardingService.isAllowed(player, toy.id) or not ProgressService.isUnlocked(player, toy) then
		return false
	end
	local ok = rateOk(player, toy)
	if not ok then
		return false
	end
	commit(player, toy)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	local push = (if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis) + Vector3.new(0, 0.45, 0)
	PlayerRagdoll.plazaKnock(target, push.Unit * math.clamp(toy.speed * 0.6, 12, 70))
	FxService.hit(position, toy.speed, toy.id, player.UserId, byHand)
	return true
end

-- byHand (optional): the client's word that its avatar did it by hand. Only the looks follow it (the
-- others draw the avatar's blow instead of the tool), so it is just type-checked.
-- lihfolk-ignore: remote-unvalidated-args (byHand is only ever read as `byHand == true`)
local function onRequest(player: Player, part: unknown, position: unknown, direction: unknown, toyId: unknown, byHand: unknown)
	if typeof(part) ~= "Instance" or not (part :: Instance):IsA("BasePart") then
		return
	end
	if typeof(position) ~= "Vector3" or typeof(direction) ~= "Vector3" or type(toyId) ~= "string" then
		return
	end
	local p = part :: BasePart
	local pos = position :: Vector3
	local dir = direction :: Vector3
	local toy = Toys.byId[toyId :: string]
	if not toy or not finite(pos) or not finite(dir) or dir.Magnitude < 0.01 then
		return
	end
	if not p:IsDescendantOf(workspace) or not burstOk(player, toy) then
		return
	end
	-- A dummy the requester simulates is where their client says (its physics is theirs, and their
	-- client has already applied the hit or grab): no "Missed" contradicting what they saw.
	local tappedDummy = dummyOf(p)
	local ownDummy = tappedDummy ~= nil and DummyControl.ownerOf(tappedDummy) == player
	if not ownDummy and not onPart(p, pos) then
		refuse(player, toy, "Missed") -- the client already showed the tap: say why nothing came of it
		return
	end
	-- Whatever is put on the part goes on its surface, not in the slack around it (a sticky bomb
	-- welded 30 studs off a limb).
	if not p:IsA("Terrain") then
		local l = p.CFrame:PointToObjectSpace(pos)
		local half = p.Size / 2
		pos = p.CFrame:PointToWorldSpace(Vector3.new(
			math.clamp(l.X, -half.X, half.X),
			math.clamp(l.Y, -half.Y, half.Y),
			math.clamp(l.Z, -half.Z, half.Z)
		))
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	if (root.Position - pos).Magnitude > MAX_DISTANCE then
		refuse(player, toy, "TooFar") -- the lab camera can look further than tools reach
		return
	end
	-- Someone else's lab is theirs (round 3, M1): nothing is hit, shot, placed or grabbed in a lab
	-- this player may not enter (nor on a body that is in one).
	if not Zones.mayReach(player, pos) or not Zones.mayReach(player, p.Position) then
		refuse(player, toy, "Private")
		return
	end
	-- A player's body: only a blow or a shot, only in the plaza with both there, and it knocks them
	-- over without a wound (round 3, M1). Nothing is ever placed on a player.
	local hitModel = p:FindFirstAncestorOfClass("Model")
	while hitModel do
		local target = Players:GetPlayerFromCharacter(hitModel)
		if target then
			if toy.kind == "hit" and target ~= player and Zones.isPlaza(root.Position) and Zones.isPlaza(pos) then
				-- (A gun at a player uses its magazine too: review fix, round 5.)
				-- (Only a shot that can land costs a round: not one the plaza gap would refuse.)
				if toy.gun and PlayerRagdoll.mayPlazaKnock(target) and not HitService.takeRound(player, toy.id) then
					refuse(player, toy, "Reload")
					return
				end
				HitService.plazaHit(player, target, toy, pos, dir, byHand == true and toy.byHand)
			end
			return
		end
		hitModel = hitModel:FindFirstAncestorOfClass("Model")
	end
	if not OnboardingService.isAllowed(player, toy.id) then
		refuse(player, toy, "Locked")
		return
	end
	if not ProgressService.isUnlocked(player, toy) then
		-- Earned with takedowns (phase H); until the profile is read nobody knows yet.
		refuse(player, toy, if ProgressService.isLoaded(player) then "Unlock" else "Loading")
		return
	end
	local ok, why = rateOk(player, toy)
	if not ok then
		if why then
			refuse(player, toy, why)
		end
		return
	end
	-- Round 5: the magazine (Shared/Ammo). A round the gun does not have is not fired.
	if toy.gun and not HitService.takeRound(player, toy.id) then
		refuse(player, toy, "Reload")
		return
	end
	local used, reason = false, nil :: string?
	if toy.kind == "hit" then
		used = HitService.applyToy(toy, p, pos, dir, player, byHand == true and toy.byHand) ~= nil
	elseif toy.kind == "dummy" then
		used, reason = ToyService.onDummy(player, toy.id, p, pos)
	elseif toy.kind == "place" then
		used, reason = ToyService.place(player, toy.id, pos, dir)
	elseif toy.kind == "grab" then
		-- The grab itself runs on the owner's client; the server counts it and records who has it.
		local grabbed = dummyOf(p)
		if grabbed then
			Dummies.setBlame(grabbed, player.UserId)
			DummyControl.stampServerHit(grabbed, player.UserId) -- a grab the server accepted: its throw counts
		end
		used = true
	end
	if used then
		commit(player, toy)
		if toy.gun then
			SessionStats.shot(player)
		end
		OnboardingService.onToyUsed(player, toy.id)
		if toy.kind == "place" or toy.kind == "dummy" then
			FxService.used(player, pos, toy.id) -- everyone else sees the throw (hits carry their own)
		end
	elseif reason then
		refuse(player, toy, reason)
	end
end

-- Round 5: every player's magazines, counted here (Shared/Ammo). The self-tests fire hundreds of
-- rounds to test other things: there the count is off unless a test turns it on (AMMO_IN_TESTS).
local books: { [Player]: Ammo.Book } = {}
local bookChar: { [Player]: Model? } = {}
HitService.AMMO_IN_TESTS = false
local function ammoOn(): boolean
	return not (RunService:IsStudio() and ServerStorage:GetAttribute("RunSelfTest") == true) or HitService.AMMO_IN_TESTS
end
function HitService.takeRound(player: Player, toyId: string): boolean
	if not ammoOn() then
		return true
	end
	-- (A new life: every magazine full again, as on the client: AmmoClient.)
	if bookChar[player] ~= player.Character then
		bookChar[player] = player.Character
		books[player] = nil
	end
	local book = books[player] or {}
	books[player] = book
	return Ammo.take(book, toyId, os.clock(), Ammo.SERVER_SLACK)
end
function HitService.reloadRound(player: Player, toyId: unknown): boolean
	if type(toyId) ~= "string" or not Ammo.spec(toyId) then
		return false
	end
	local book = books[player] or {}
	books[player] = book
	return Ammo.reload(book, toyId, os.clock(), Ammo.SERVER_SLACK)
end
function HitService.roundsLeft(player: Player, toyId: string): number?
	return Ammo.left(books[player] or {}, toyId, os.clock())
end
function HitService.resetAmmoForTest(player: Player)
	books[player] = nil
end

-- A gun fired at nothing (round 2, N2): the ground, a wall, the air. Checked like a hit (the gun, its
-- lock, its pace, the reach), then everyone else sees the shot and the bodies near it hear it. The
-- point is where the client's aim met the world (or a point along the aim in the air).
local function onShot(player: Player, position: unknown, toyId: unknown)
	if typeof(position) ~= "Vector3" or type(toyId) ~= "string" then
		return
	end
	local toy = Toys.byId[toyId :: string]
	local pos = position :: Vector3
	if not toy or not toy.gun or not finite(pos) or not burstOk(player, toy) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	if (root.Position - pos).Magnitude > MAX_DISTANCE then
		return -- (the client stops an air shot at the reach: further is not a shot it could fire)
	end
	if not Zones.mayReach(player, pos) then
		return -- (into a lab this player may not enter: nobody there hears it)
	end
	if not OnboardingService.isAllowed(player, toy.id) or not ProgressService.isUnlocked(player, toy) then
		return
	end
	local ok = rateOk(player, toy)
	if not ok or not HitService.takeRound(player, toy.id) then
		return
	end
	commit(player, toy)
	SessionStats.shot(player)
	OnboardingService.onToyUsed(player, toy.id)
	FxService.shot(player, pos, toy.id)
	Knockables.shot(pos, root.Position) -- (UI audit 21 Nov 2026: a shot knocks a barrel, crate or cone it hit)
	if not inMechanicsOf[player] then
		inMechanicsOf[player] = true
		pcall(WeaponMechanics.afterShot, player, toy, pos)
		inMechanicsOf[player] = nil
	end
end
HitService.onShot = onShot

-- For the self-tests: when a player's last use of a tool went through (nil: never).
function HitService.lastUseOf(player: Player, toyId: string): number?
	local perToy = lastHit[player]
	return perToy and perToy[toyId]
end

-- For the self-tests: the remote handler itself (T22 feeds it bad input).
HitService.onRequest = function(player: Player, ...: unknown)
	onRequest(player, ...)
end

-- Studio only: lets automated checks hit a lab dummy by slot through the real code path.
local function installDebugHook()
	if not RunService:IsStudio() then
		return
	end
	local hook = Instance.new("BindableFunction")
	hook.Name = "DebugHit"
	hook.OnInvoke = function(slot: number, toyId: string, direction: Vector3, partName: string?): string?
		local toy = Toys.byId[toyId]
		local dummies = workspace:FindFirstChild("Dummies")
		if not toy or not dummies then
			return nil
		end
		for _, model in dummies:GetChildren() do
			if model:GetAttribute("Slot") == slot then
				local part = model:FindFirstChild(partName or "UpperTorso")
				if part and part:IsA("BasePart") then
					if toy.kind == "hit" then
						return HitService.applyToy(toy, part, part.Position, direction)
					elseif toy.kind == "dummy" then
						return if ToyService.onDummy(nil, toy.id, part, part.Position) then "ok" else nil
					else
						local ground = Vector3.new(part.Position.X, 0, part.Position.Z)
						return if ToyService.place(nil, toy.id, ground, direction) then "ok" else nil
					end
				end
			end
		end
		return nil
	end
	hook.Parent = ServerStorage
end

function HitService.start()
	WeaponMechanics.apply = function(toy: any, part: BasePart, position: Vector3, direction: Vector3, requester: Player?): string?
		return HitService.applyToy(toy, part, position, direction, requester)
	end
	refused = Net.event(Net.Names.ToyRefused)
	Net.event(Net.Names.HitRequest).OnServerEvent:Connect(onRequest)
	Net.event(Net.Names.Shot).OnServerEvent:Connect(onShot)
	-- R: reload early (round 5). Only a known gun's id; the reload itself paces it.
	Net.event(Net.Names.Ammo).OnServerEvent:Connect(function(player: Player, kind: unknown, toyId: unknown)
		if type(kind) == "string" and kind == "Reload" and type(toyId) == "string" and #toyId <= 40 then
			HitService.reloadRound(player, toyId)
		elseif kind == "Detonate" then
			-- Round 5: the C4's second press sets off the player's own charges (nothing else).
			ToyService.detonate(player)
		end
	end)
	installDebugHook()
	Players.PlayerRemoving:Connect(function(player)
		lastHit[player] = nil
		window[player] = nil
		heavyUses[player] = nil
		heavyBucket[player] = nil
		HitService.lastRefusal[player] = nil
		books[player] = nil
		bookChar[player] = nil
	end)
	log.info("ready")
end

return HitService
