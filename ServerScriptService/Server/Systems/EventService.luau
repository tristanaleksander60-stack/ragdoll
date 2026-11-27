--!strict
-- Server events (see Shared/Events): one at a time, in the order they came, a short gap between
-- them; every player sees a banner with who set it off. Sources: a Robux purchase (granted by
-- Purchases.processReceipt), a free event (free weekend, later), a TikTok gift (Streamer Mode,
-- later) or a Studio test. Everything an event changes is put back when it ends.
--
--   Dummy Rain    a dozen extra dummies drop flailing from the sky over the lab, then poof away
--   Mega Bomb     a huge bomb falls on the middle of the lab: one cartoon blast, dummies and players fly
--   Zero-G        gravity almost off for everyone
--   Bouncy Floor  the floor turns to rubber: everything that lands bounces back up
--   Flash Freeze  every dummy turns to ice at once
--
-- Paid events are never lost: a purchase is a saved order (Purchases) until its event has
-- started. A server that closes, or a buyer who leaves before their event's turn, gives the order
-- back; it is queued again in the next server the buyer joins. A paid event that fails to start
-- gets one more go, then goes back to the buyer the same way.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Log)
local Events = require(Shared.Events)
local Config = require(Shared.Config)
local N7Models = require(Shared.N7Models)

local Systems = script.Parent
local DummyFactory = require(Systems.DummyFactory)
local DummyControl = require(Systems.DummyControl)
local FxService = require(Systems.FxService)
local PlayerRagdoll = require(Systems.PlayerRagdoll)
local Purchases = require(Systems.Purchases)
local Lab = require(Systems.Lab)
local Creatures = require(Systems.Creatures)
local Surprises = require(Systems.Surprises)

local log = Log.new("Events")

local EventService = {}

export type Source = "Robux" | "Free" | "TikTok" | "Test"
-- A paid job carries its order, so it can be completed when it runs or given back.
export type Paid = { purchaseId: string, userId: number }
-- hostId: the player it is for (their UserId), when there is one: it happens in their lab.
type Job = { id: string, by: string, source: Source, paid: Paid?, retried: boolean?, hostId: number?, allLabs: boolean? }

local RAIN_COUNT = 12
local RAIN_HEIGHT = 45
local RAIN_RADIUS = 26
local RAIN_OWNER_RANGE = 200 -- the lab owner's client simulates the rain when it is this close
local OWNER_BODIES = 12 -- most bodies one client simulates (phones); the server takes the rest
local MAX_DUMMIES = 24 -- extra bodies (rain, horde, gifts) in the world at once; labs and crowds not counted
local BOMB_RADIUS = 42
local LOW_GRAVITY = 32 -- studs/s² (normal is 196.2)
local FLOOR_SIZE = 40 -- studs: a part at least this wide both ways counts as floor
local PROMPT_COOLDOWN = 1 -- s per player
local MAX_PER_BUYER = 2 -- paid events one player can have waiting (others get a turn too)
-- World folders that are never floor: bodies, props and player builds come and go.
local NOT_FLOOR = { Dummies = true, Props = true, Builds = true }

local queue: { Job } = {}
local current: Job? = nil
local currentEndsAt = 0
local nextAt = 0
local stateRemote: RemoteEvent? = nil -- set by start
local noticeRemote: RemoteEvent? = nil
local lastPrompt: { [Player]: number } = {}
local lastPassEvent: { [Player]: number } = {} -- (release 0.20.0: the EVENTS PASS's free events)
local heldForTest = false
local failStarts = 0 -- tests: how many starts to fail on purpose

-- Who an event is for: its buyer, or the player who set it off (an admin, a test), by UserId
-- (display names are not unique).
local function hostOf(job: Job): Player?
	local userId = if job.paid then job.paid.userId else job.hostId
	return if userId then Players:GetPlayerByUserId(userId) else nil
end

-- 1.0 EVENTS ON THE NEW MAP, rule 1 (docs/EVENTS_NEWMAP.md; Config.EVENTS_V2): an event happens AROUND THE PLAYER it is
-- for, in view at once, not in the lab's middle hundreds of studs away. When that player stands somewhere covered or
-- cramped (a roof over the head within 40 studs, in a seat, high up on the tower), it centres on the nearest OPEN spot
-- of the plan within 90 studs (the Tower Square, the spawn plaza, a walkway crossing). nil = not in their own lab.
local OPEN_SPOTS: { Vector2 }? = nil
local function openSpots(): { Vector2 }
	if OPEN_SPOTS then
		return OPEN_SPOTS
	end
	local list: { Vector2 } = {}
	pcall(function()
		local Plan = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
		for _, pz in Plan.PLAZAS or {} do
			table.insert(list, pz.at)
		end
		for _, r in Plan.ROADS or {} do
			for _, p in r.points do
				table.insert(list, p)
			end
		end
	end)
	OPEN_SPOTS = list
	return list
end
local eventParams = RaycastParams.new()
eventParams.FilterType = Enum.RaycastFilterType.Exclude
local function eventSpot(job: Job?): Vector3?
	if not (Config :: any).EVENTS_V2 then
		return nil
	end
	local host = job and hostOf(job)
	local character = host and host.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (host and root and root:IsA("BasePart") and Lab.plotIndex(host) and Lab.ownerAt(root.Position) == host) then
		return nil
	end
	local dummies = workspace:FindFirstChild("Dummies")
	eventParams.FilterDescendantsInstances = if dummies then { character :: Instance, dummies } else { character :: Instance }
	local groundY = Lab.plazaOrigin().Y
	local here = Vector3.new(root.Position.X, groundY, root.Position.Z)
	local hum = (character :: Model):FindFirstChildOfClass("Humanoid")
	local covered = workspace:Raycast(root.Position + Vector3.new(0, 3, 0), Vector3.new(0, 40, 0), eventParams) ~= nil
	local cramped = covered or (hum ~= nil and hum.SeatPart ~= nil) or root.Position.Y - groundY > 14
	if not cramped then
		return here
	end
	local o = Lab.originFor(host)
	local best, bestD = here, 90
	for _, s in openSpots() do
		local p = Vector3.new(o.X + s.X, groundY, o.Z + s.Y)
		local d = (p - here).Magnitude
		if d < bestD and not workspace:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, 40, 0), eventParams) then
			best, bestD = p, d
		end
	end
	return best
end

-- Where an event happens: in the lab of the player it is for, while they are in it; anywhere else
-- (they went out, or it is nobody's) in the plaza, the place for everyone.
local function labCenter(job: Job?): Vector3
	local spot = eventSpot(job)
	if spot then
		return spot -- (1.0 rule 1: round the buyer)
	end
	local host = job and hostOf(job)
	local character = host and host.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local focus = Lab.plazaFocus()
	if host and Lab.plotIndex(host) and root and root:IsA("BasePart") and Lab.ownerAt(root.Position) == host then
		focus = Lab.focusFor(host)
	end
	return Vector3.new(focus.X, Lab.plazaOrigin().Y, focus.Z)
end
-- Tests: where an event set off by this player (UserId) would happen now.
function EventService.whereFor(hostId: number?): Vector3
	return labCenter({ id = "", by = "", source = "Test", hostId = hostId })
end

local function snapshot(): { [string]: any }
	local job = current
	return {
		id = if job then job.id else nil,
		by = if job then job.by else nil,
		source = if job then job.source else nil,
		endsAt = currentEndsAt,
		queued = #queue,
	}
end

local function broadcast()
	if stateRemote then
		stateRemote:FireAllClients(snapshot())
	end
end

-- A short personal line for one player ("Your Zero-G is next!"). kind: "ok" or "warn". afterBanner:
-- the event is about to start; the line waits for the banner, so it lands below it, not under it.
local function notify(player: Player?, text: string, kind: string?, afterBanner: boolean?)
	local remote = noticeRemote
	if not (player and remote) then
		return
	end
	task.delay(if afterBanner then 0.8 else 0, function()
		if player.Parent then
			remote:FireClient(player, text, kind or "ok")
		end
	end)
end

-- Where a job just queued stands: 0 = it starts right away.
local function placeOf(position: number): string
	if position <= 1 and not current then
		return "is starting!"
	elseif position <= 1 then
		return "is next!"
	end
	return string.format("is queued (#%d).", position)
end

------------------------------------------------------------------------------------------------
-- The events. A handler registers how to undo each change (onEnd) before making it, so whatever
-- happened, even a failure halfway, is put back when the event ends.

type Handler = (job: Job, onEnd: (() -> ()) -> ()) -> ()

-- (The plaza's crowd keeps its own number: CrowdService.)
local function dummyCount(): number
	local folder = Workspace:FindFirstChild("Dummies")
	local count = 0
	for _, model in if folder then folder:GetChildren() else {} do
		-- (Every lab's own row keeps its own number too: Lab.)
		if model:GetAttribute("Crowd") ~= true and model:GetAttribute("Plot") == nil then
			count += 1
		end
	end
	return count
end

-- The owner of the lab it rains in simulates the rain dummies while near, up to OWNER_BODIES bodies
-- in all (their lab dummies count); the server simulates the rest (and all of the plaza's).
local function rainOwner(center: Vector3): Player?
	local owner = Lab.ownerAt(center)
	local character = owner and owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if owner and root and root:IsA("BasePart") and (root.Position - center).Magnitude < RAIN_OWNER_RANGE then
		return owner
	end
	return nil
end

local handlers: { [string]: Handler } = {}

handlers.DummyRain = function(job, onEnd)
	local center = labCenter(job)
	local rained: { Model } = {}
	local stopped = false
	onEnd(function()
		stopped = true
		-- (Round 4, M10: the dead stay for their DEAD_HOLD, VitalsService takes them; they still count
		-- in dummyCount, so MAX_DUMMIES holds.)
		for _, model in rained do
			if model.Parent and model:GetAttribute("Vital") ~= "Dead" then
				local pelvis = model:FindFirstChild("LowerTorso")
				if pelvis and pelvis:IsA("BasePart") then
					Lab.poof(pelvis.Position)
				end
				model:Destroy()
			end
		end
	end)
	local owner = rainOwner(center)
	task.spawn(function()
		for _ = 1, RAIN_COUNT do
			if stopped or dummyCount() >= MAX_DUMMIES then
				break
			end
			-- lihfolk-ignore: paid-random-no-policy (where the rain's dummies land; a bought event's effect is fixed, nothing is rolled as a reward)
			local angle = math.random() * math.pi * 2
			local d = math.sqrt(math.random()) * RAIN_RADIUS
			local spot = center + Vector3.new(math.cos(angle) * d, 0, math.sin(angle) * d)
			if owner and not owner.Parent then
				owner = nil
			end
			local simulatedBy = owner
			if simulatedBy then
				local bodies = 0
				local folder = Workspace:FindFirstChild("Dummies")
				for _, other in if folder then folder:GetChildren() else {} do
					if other:IsA("Model") and DummyControl.ownerOf(other) == simulatedBy then
						bodies += 1
					end
				end
				if bodies >= OWNER_BODIES then
					simulatedBy = nil
				end
			end
			local model = DummyFactory.spawn(spot, center, simulatedBy, RAIN_HEIGHT + math.random() * 15)
			if stopped then
				-- The event ended while this one was being made (spawning yields).
				model:Destroy()
				break
			end
			model:SetAttribute("Guest", true)
			table.insert(rained, model)
			-- Flailing all the way down.
			local chest = model:FindFirstChild("UpperTorso")
			local mass = (model:GetAttribute("Mass") :: number?) or 10
			if chest and chest:IsA("BasePart") then
				local spin = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
				DummyControl.hit(model, chest, (spin * 40 + Vector3.new(0, -35, 0)) * mass, chest.Position + Vector3.new(0, 0.5, 0))
			end
			task.wait(0.25)
		end
	end)
end

-- Round 2 (N7): a huge bomb (a real aerial bomb model, ReplicatedStorage.N7Assets.Fx.MegaBomb)
-- falls out of the sky first, so everyone sees it coming; the blast is where it lands. Every
-- client animates its own copy (FxService.bombFall): smooth on every screen, nothing per frame
-- on the server.
local BOMB_FALL = 1.1 -- s

local function fallingBomb(center: Vector3): boolean
	if not N7Models.source("Fx", "MegaBomb") then
		return false
	end
	FxService.bombFall(center, BOMB_FALL)
	return true
end

local function megaBlast(center: Vector3)
	local blast = Instance.new("Explosion")
	blast.Position = center
	blast.BlastPressure = 0
	blast.BlastRadius = 0
	blast.DestroyJointRadiusPercent = 0
	blast.ExplosionType = Enum.ExplosionType.NoCraters
	blast.Parent = Workspace
	FxService.hit(center, 160, "BigBoom") -- (the biggest sound and flash: 10 Nov 2026, explosions by size)
	local folder = Workspace:FindFirstChild("Dummies")
	for _, model in if folder then folder:GetChildren() else {} do
		local pelvis = model:FindFirstChild("LowerTorso")
		if model:IsA("Model") and pelvis and pelvis:IsA("BasePart") then
			local offset = pelvis.Position - center
			if offset.Magnitude < BOMB_RADIUS then
				local falloff = 1 - offset.Magnitude / BOMB_RADIUS
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) * 0.65 + Vector3.new(0, 0.8, 0)).Unit
				local mass = (model:GetAttribute("Mass") :: number?) or 10
				DummyControl.hit(model, pelvis, dir * (45 + 75 * falloff) * mass, pelvis.Position)
			end
		end
	end
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local offset = root.Position - center
			if offset.Magnitude < BOMB_RADIUS then
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) * 0.6 + Vector3.new(0, 0.8, 0)).Unit
				PlayerRagdoll.knock(player, dir * 65)
			end
		end
	end
end

handlers.MegaBomb = function(job)
	local center = labCenter(job) + Vector3.new(0, 1, 0)
	if fallingBomb(center) then
		-- (The banner shows while it falls.)
		task.delay(BOMB_FALL, megaBlast, center)
	else
		megaBlast(center)
	end
end

handlers.ZeroG = function(_job, onEnd)
	local before = Workspace.Gravity
	onEnd(function()
		local admin = Workspace:GetAttribute("AdminGravity") -- (V6-2: the owner's choice wins over the old value)
		Workspace.Gravity = if type(admin) == "number" then admin else before
	end)
	Workspace.Gravity = LOW_GRAVITY
end

handlers.BouncyFloor = function(_job, onEnd)
	-- Every big anchored floor in the world (the baseplate, the playground and lab floors, in
	-- folders and models too). Bodies, props and player builds are skipped whole, so the scan only
	-- walks the fixed world, once.
	-- A list, not a map: a floor without custom properties has nil to go back to.
	local floors: { { part: BasePart, was: PhysicalProperties? } } = {}
	onEnd(function()
		for _, floor in floors do
			if floor.part.Parent then
				floor.part.CustomPhysicalProperties = floor.was
			end
		end
	end)
	-- Rubber that wins against anything landing on it.
	local rubber = PhysicalProperties.new(0.7, 0.4, 1, 1, 100)
	local function consider(part: Instance)
		if part:IsA("BasePart") and not part:IsA("Terrain") and part.Anchored and part.CanCollide and part.Size.X >= FLOOR_SIZE and part.Size.Z >= FLOOR_SIZE then -- (a painted floor that nothing lands on is skipped)
			table.insert(floors, { part = part, was = part.CustomPhysicalProperties })
			part.CustomPhysicalProperties = rubber
		end
	end
	for _, child in Workspace:GetChildren() do
		local isCharacter = child:IsA("Model") and Players:GetPlayerFromCharacter(child) ~= nil
		if not NOT_FLOOR[child.Name] and not isCharacter then
			consider(child)
			for _, part in child:GetDescendants() do
				consider(part)
			end
		end
	end
end

handlers.FlashFreeze = function()
	local folder = Workspace:FindFirstChild("Dummies")
	for _, model in if folder then folder:GetChildren() else {} do
		if model:IsA("Model") then
			DummyControl.freeze(model)
		end
	end
	-- the ice thaws by itself
end

-- v3 Phase C: the animals walk the host's lab (its middle; the plaza when they are not in it).
local function labMiddle(job: Job): Vector3
	local spot = eventSpot(job)
	if spot then
		return Vector3.new(spot.X, spot.Y - 0.5, spot.Z) -- (1.0 rule 1: round the buyer)
	end
	local host = hostOf(job)
	local character = host and host.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if host and Lab.plotIndex(host) and root and root:IsA("BasePart") and Lab.ownerAt(root.Position) == host then
		local o = Lab.originFor(host)
		return Vector3.new(o.X, Lab.plazaOrigin().Y - 0.5, o.Z)
	end
	local p = Lab.plazaOrigin()
	return Vector3.new(p.X, p.Y - 0.5, p.Z)
end

handlers.GorillaRampage = function(job, onEnd)
	onEnd(Creatures.gorilla(labMiddle(job)))
end

handlers.TrainRun = function(job, onEnd)
	onEnd(Creatures.train(labMiddle(job)))
end

handlers.Tornado = function(job, onEnd)
	onEnd(Creatures.tornado(labMiddle(job)))
end

handlers.MeteorShower = function(job, onEnd)
	onEnd(Creatures.meteors(labMiddle(job)))
end

handlers.BullRun = function(job, onEnd)
	onEnd(Creatures.bulls(labMiddle(job)))
end

-- v4 C4: the lab surprises (Surprises), each in the host's lab.
for _, id in { "UfoBeam", "BowlingAvalanche", "RocketRain", "MagnetStorm", "LightningStorm", "Sinkhole", "Earthquake", "FanBlast", "MoonGravity", "BalloonDrop", "GiantDummy" } do
	handlers[id] = function(job, onEnd)
		local fn = (Surprises :: any)[id] :: (Vector3, Player?) -> () -> ()
		onEnd(fn(labMiddle(job), hostOf(job)))
	end
end

for _, event in Events.list do
	assert(handlers[event.id], "no handler for the event " .. event.id)
end

------------------------------------------------------------------------------------------------

local function isClosing(): boolean
	return Purchases.isClosing()
end

-- Gives paid jobs back to their buyers (they are queued again in the next server they join).
local function giveBack(jobs: { Job }, failedStart: boolean?)
	local byUser: { [number]: { string } } = {}
	for _, job in jobs do
		local paid = job.paid
		if paid then
			byUser[paid.userId] = byUser[paid.userId] or {}
			table.insert(byUser[paid.userId], paid.purchaseId)
		end
	end
	for userId, ids in byUser do
		task.spawn(Purchases.release, userId, ids, failedStart)
	end
end

-- 1.0 rule 3 (Config.EVENT_CROWD): before the peak up to CROWD free ragdolls within 160 studs run into a ring 10-24 studs
-- round the event's middle and look at it ("What's that?!"); they are let go 25 s later.
local CROWD = 12
local function crowdIn(center: Vector3)
	local dummies = workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	local lines = { "What's that?!", "Look up!", "Uh oh...", "Whoa!" }
	local n = 0
	for _, m in dummies:GetChildren() do
		if n >= CROWD then
			break
		end
		local pe = m:FindFirstChild("LowerTorso")
		local st = m:GetAttribute("RagdollState")
		if m:IsA("Model") and pe and pe:IsA("BasePart") and (st == "Standing" or st == "Walking") and m:GetAttribute("Vital") ~= "Dead"
			and m:GetAttribute("Watch") == nil and m:GetAttribute("Role3") == nil and m:GetAttribute("TryFor") == nil
			and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("InMachine") == nil and m:GetAttribute("Held") ~= true
			and (pe.Position - center).Magnitude < 160 then
			n += 1
			local a = math.random() * math.pi * 2
			local r = math.random(10, 24)
			m:SetAttribute("Watch", "Event")
			m:SetAttribute("Home", center + Vector3.new(math.cos(a) * r, 3, math.sin(a) * r))
			m:SetAttribute("HomeLook", center)
			m:SetAttribute("Pace", 1.8)
			if n <= 4 then
				m:SetAttribute("MoodSay", lines[n])
			end
			task.delay(25, function()
				if m.Parent and m:GetAttribute("Watch") == "Event" then
					m:SetAttribute("Watch", nil)
					m:SetAttribute("Home", nil)
					m:SetAttribute("HomeLook", nil)
					m:SetAttribute("Pace", nil)
					m:SetAttribute("MoodSay", nil)
				end
			end)
		end
	end
end

local function run(job: Job)
	local event = Events.byId[job.id]
	current = job
	log.info(string.format("%s: %s (%s)", event.name, job.by, job.source))
	-- (Phase D, 23 Nov 2026, owner: "events more realistic: a short warning before"): the lab's player (every player
	-- for an all-labs event) sees "INCOMING!" 1.5 s before it starts. Not for self-tests.
	if job.source ~= "Test" and (Config :: any).EVENT_CROWD and not job.allLabs then
		pcall(crowdIn, labCenter(job))
	end
	if job.source ~= "Test" then
		for _, p in Players:GetPlayers() do
			if job.allLabs or p.UserId == job.hostId then
				pcall(function()
					(require(script.Parent:WaitForChild("ProgressService")) :: any).notice(p, "\u{26A0}\u{FE0F} " .. string.upper(event.name) .. " INCOMING!")
				end)
			end
		end
		task.wait(1.5)
	end
	local undo: { () -> () } = {}
	local ok, err = pcall(function()
		if failStarts > 0 then
			failStarts -= 1
			error("failed on purpose (test)")
		end
		handlers[job.id](job, function(fn: () -> ())
			table.insert(undo, fn)
		end)
		-- (V10 phase 4, owner: "the red button: the event happens in every lab on the server"): the same event,
		-- at the same time, in every other player's lab too.
		if job.allLabs then
			for _, p in Players:GetPlayers() do
				if p.UserId ~= job.hostId and Lab.plotIndex(p) then
					pcall(handlers[job.id], { id = job.id, by = job.by, source = job.source, hostId = p.UserId }, function(fn: () -> ())
						table.insert(undo, fn)
					end)
				end
			end
		end
	end)
	local paid = job.paid
	if ok then
		-- The banner only once the event has really started.
		currentEndsAt = Workspace:GetServerTimeNow() + event.duration
		broadcast()
		-- (V9-NOW 21: the falls in the starter's lab are their KOs while it runs.)
		local starter = hostOf(job)
		if starter and Lab.plotIndex(starter) then
			pcall(function()
				(require(script.Parent:WaitForChild("ProgressService")) :: any).startEventCredit(starter, event.name, event.duration)
			end)
		end
		if paid then
			task.spawn(Purchases.complete, paid.userId, paid.purchaseId) -- delivered
		end
		if (Config :: any).EVENT_STATS and job.source ~= "Test" then
			-- 3.30 (docs/MACHINES_10.md "RED-BUTTON EVENTS"; Config.EVENT_STATS): an end line with its stats: how many
			-- ragdolls it knocked over in the starter's lab (every lab for an all-labs event), "TORNADO over: 37 ragdolls flung!"
			local flung: { [Instance]: boolean } = {}
			local count = 0
			local t0 = os.clock()
			while os.clock() - t0 < event.duration do
				for _, p in Players:GetPlayers() do
					if job.allLabs or p.UserId == job.hostId then
						local okL, list = pcall(function()
							return Lab.dummiesOf(p)
						end)
						for _, m in if okL then list else {} do
							local st = m:GetAttribute("RagdollState")
							if not flung[m] and (st == "Ragdoll" or st == "Out") then
								flung[m] = true
								count += 1
							end
						end
					end
				end
				task.wait(0.5)
			end
			if count > 0 then
				for _, p in Players:GetPlayers() do
					if job.allLabs or p.UserId == job.hostId then
						pcall(function()
							(require(script.Parent:WaitForChild("ProgressService")) :: any).notice(p, string.upper(event.name) .. " over: " .. tostring(count) .. " ragdoll" .. (if count == 1 then "" else "s") .. " flung!")
						end)
					end
				end
			end
		else
			task.wait(event.duration)
		end
	else
		-- Ends at once: no banner counting down an event that is not happening.
		log.warn(event.name .. " failed to start: " .. tostring(err))
	end
	for i = #undo, 1, -1 do
		local cleaned, cleanupErr = pcall(undo[i])
		if not cleaned then
			log.warn(event.name .. " failed to clean up: " .. tostring(cleanupErr))
		end
	end
	if not ok and paid then
		local buyer = Players:GetPlayerByUserId(paid.userId)
		if buyer and not job.retried and not isClosing() then
			-- One more go, at the back of the queue.
			table.insert(queue, { id = job.id, by = job.by, source = job.source, paid = paid, retried = true, hostId = job.hostId })
			notify(buyer, string.format("Your %s hit a snag. It goes again in a moment.", event.name), "warn")
		else
			-- Back to the buyer (who may have left meanwhile): this server, or their next one, tries
			-- again a few minutes from now.
			giveBack({ job }, true)
			notify(buyer, string.format("Your %s could not start. It is saved for you and comes back soon.", event.name), "warn")
		end
	end
	current = nil
	currentEndsAt = 0
	nextAt = os.clock() + Events.GAP
	broadcast()
end

-- How many more bodies the world can take before the cap (the horde sizes itself by it).
function EventService.dummyRoom(): number
	return math.max(0, MAX_DUMMIES - dummyCount())
end

-- Whether a new event can join the queue now (purchase prompts are refused when not).
function EventService.hasRoom(): boolean
	return #queue < Events.MAX_QUEUE and not isClosing()
end

local function waitingFor(userId: number): number
	local n = 0
	for _, job in queue do
		if job.paid and job.paid.userId == userId then
			n += 1
		end
	end
	return n
end

-- Queues an event. `force` (a paid order) always queues: refusing after payment is not allowed.
-- Returns its place in the queue (1 = next), or nil when refused.
function EventService.trigger(id: string, by: string, source: Source, force: boolean?, paid: Paid?, hostId: number?, allLabs: boolean?): number?
	if not Events.byId[id] then
		return nil
	end
	-- (V8-0.8: an event a player set off counts as used in their visit record.)
	local host = if hostId then Players:GetPlayerByUserId(hostId) else nil
	if host then
		pcall(function()
			(require(script.Parent:WaitForChild("SessionStats")) :: any).used(host, "Event:" .. id)
		end)
	end
	if paid and isClosing() then
		-- Too late for this server: the buyer gets it in the next one.
		giveBack({ { id = id, by = by, source = source, paid = paid } })
		return nil
	end
	if not force and not EventService.hasRoom() then
		return nil
	end
	if paid then
		-- One order, one event: never queued twice.
		local running = current
		if running and running.paid and running.paid.purchaseId == paid.purchaseId then
			return nil
		end
		for _, job in queue do
			if job.paid and job.paid.purchaseId == paid.purchaseId then
				return nil
			end
		end
	end
	table.insert(queue, { id = id, by = by, source = source, paid = paid, hostId = hostId, allLabs = allLabs })
	broadcast()
	return #queue
end

function EventService.current(): string?
	return if current then current.id else nil
end

-- Whether start has run (tests wait for it: Purchases.start yields on its DataStore probe).
function EventService.isReady(): boolean
	return stateRemote ~= nil
end

function EventService.queued(): number
	return #queue
end

-- Tests: drop whatever is waiting (paid jobs go back to their buyers).
function EventService.clearQueue()
	giveBack(queue)
	table.clear(queue)
	broadcast()
end

-- Tests: what a buyer leaving does to their waiting events.
local function buyerLeft(userId: number)
	local mine: { Job } = {}
	for i = #queue, 1, -1 do
		local job = queue[i]
		if job.paid and job.paid.userId == userId then
			table.insert(mine, 1, table.remove(queue, i) :: Job)
		end
	end
	if #mine > 0 then
		giveBack(mine)
		broadcast()
	end
end
EventService.buyerLeftForTest = buyerLeft

-- Tests: while held, queued events wait (a test that needs a quiet lab).
function EventService.holdForTest(on: boolean)
	assert(RunService:IsStudio(), "for Studio tests only")
	heldForTest = on
end

-- Tests: the next `count` events fail to start.
function EventService.failStartsForTest(count: number)
	assert(RunService:IsStudio(), "for Studio tests only")
	failStarts = count
end

local function onBuy(player: Player, id: unknown)
	if type(id) ~= "string" then
		return
	end
	local event = Events.byId[id]
	if not event then
		return
	end
	local now = os.clock()
	if lastPrompt[player] and now - lastPrompt[player] < PROMPT_COOLDOWN then
		return -- a double tap (the shop button also waits a moment)
	end
	lastPrompt[player] = now
	-- Refused before any prompt: never take Robux for something that cannot run soon.
	if isClosing() then
		notify(player, "The server is restarting. Try again in the next one!", "warn")
		return
	elseif not EventService.hasRoom() then
		notify(player, "The event queue is full. Try again in a moment.", "warn")
		return
	elseif waitingFor(player.UserId) >= MAX_PER_BUYER then
		notify(player, "You already have events waiting. Let them go off first!", "warn")
		return
	end
	-- (Release 0.20.0: the EVENTS PASS, Shop.OFFERS: free, at most one per Config.EVENTS_PASS_GAP s.
	-- OfferService sets the EventsPass attribute from Roblox's answer.)
	if player:GetAttribute("EventsPass") == true then
		local gap = Config.EVENTS_PASS_GAP - (now - (lastPassEvent[player] or -math.huge))
		if gap <= 0 then
			lastPassEvent[player] = now
			local place = EventService.trigger(id, player.DisplayName, "Free", nil, nil, player.UserId)
			if place then
				notify(player, string.format("EVENTS PASS: your %s %s", event.name, placeOf(place)), nil, place <= 1 and not current)
			end
			return
		elseif event.productId == 0 then
			notify(player, string.format("EVENTS PASS: your next free event in %d s", math.ceil(gap)), "warn")
			return
		end
	end
	if event.productId ~= 0 then
		MarketplaceService:PromptProductPurchase(player, event.productId)
	elseif RunService:IsStudio() then
		-- Not on sale yet: in Studio the shop runs it straight away for testing.
		local place = EventService.trigger(id, player.DisplayName, "Test", nil, nil, player.UserId)
		if place then
			-- (V7-5: "is starting!" is what the banner itself says: no second line under it.)
			if not (Config.BANNER_V7 and place <= 1 and not current) then
				notify(player, string.format("Your %s %s", event.name, placeOf(place)), nil, place <= 1 and not current)
			end
		end
	end
end


-- v4 C4: now and then a short surprise by itself in a player's own lab (Config.LAB_SURPRISES), so no
-- two minutes are the same: only in their own lab, never while an event runs or waits, never in a
-- new visit's quiet start, at most one per LAB_SURPRISE_GAP (random in the range) per player.
local nextSurprise: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
local firstWow: { [Player]: number | false } = setmetatable({}, { __mode = "k" }) :: any
local miniUntil = 0 -- (while a short surprise runs, no event starts on top of it)
function EventService.miniRunning(): boolean
	return os.clock() < miniUntil
end
function EventService.surpriseNow(player: Player, id: string?, quiet: boolean?): string?
	if not Lab.plotIndex(player) then
		return nil
	end
	miniUntil = os.clock() + Surprises.MINI_TIME + 1
	local name = Surprises.mini(labMiddle({ id = "Surprise", by = player.DisplayName, source = "Free" :: any, hostId = player.UserId }), player, id)
	local event = Events.byId[name]
	if not quiet then
		notify(player, string.format("SURPRISE! %s", if event then event.name else name), "ok")
	end
	pcall(function() -- (V9-NOW 21: a surprise's falls are the player's KOs too)
		(require(script.Parent:WaitForChild("ProgressService")) :: any).startEventCredit(player, if event then event.name else name, Surprises.MINI_TIME)
	end)
	return name
end
local function surpriseLoop()
	local gap = Config.LAB_SURPRISE_GAP :: Vector2
	while true do
		task.wait(10)
		if game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true then
			continue -- (never while the self-tests run: they count on still bodies)
		end
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			-- v4 E1 (research: the first wow by 60 s): once a visit, at Config.FIRST_WOW_AT s, FIRST_WOW_EVENT
			-- (V9-0u: a balloon dropping new dummies in; it was a UFO)
			-- comes over the player's own lab (no pop-up, the quiet start holds; nothing if busy).
			local joined = firstWow[player]
			if joined == nil then
				firstWow[player] = now
			elseif joined ~= false and now - joined >= (Config :: any).FIRST_WOW_AT then
				local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local free = current == nil and #queue == 0 and os.clock() >= miniUntil and player:GetAttribute("PartyLab") == nil
				if r and r:IsA("BasePart") and free and Lab.ownerAt(r.Position) == player then
					firstWow[player] = false
					pcall(EventService.surpriseNow, player, (Config :: any).FIRST_WOW_EVENT or "BalloonDrop", true)
				elseif now - joined > 180 then
					firstWow[player] = false -- (never found them free in their lab: let it go)
				end
			end
			local due = nextSurprise[player]
			if not due then
				-- (Each player's first one falls at a random time, so a fresh server never fires them all at once.)
				local first = ((Config :: any).LAB_SURPRISE_FIRST or gap) :: Vector2
				nextSurprise[player] = now + math.max(Config.QUIET_START, math.random(math.floor(first.X), math.floor(first.Y)))
				player:SetAttribute("SurpriseAt", workspace:GetServerTimeNow() + ((nextSurprise[player] :: number) - now))
				continue
			end
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local busy = player:GetAttribute("PartyLab") ~= nil or ((player:GetAttribute("ChaseLeft") :: number?) or 0) > 0 or os.clock() < miniUntil
			if now >= due and not busy and current == nil and #queue == 0 and root and root:IsA("BasePart") and Lab.ownerAt(root.Position) == player then
				nextSurprise[player] = now + math.random(math.floor(gap.X), math.floor(gap.Y))
				pcall(EventService.surpriseNow, player)
				player:SetAttribute("SurpriseAt", workspace:GetServerTimeNow() + ((nextSurprise[player] :: number) - now)) -- (STAY_LONGER 3: the goal line warns 10 s before)
			end
		end
	end
end
function EventService.start()
	stateRemote = Net.event(Net.Names.EventState)
	noticeRemote = Net.event(Net.Names.EventNotice)
	Net.event(Net.Names.EventBuy).OnServerEvent:Connect(onBuy)
	Surprises.room = EventService.dummyRoom -- (guest dummies of the surprises respect MAX_DUMMIES)
	if Config.LAB_SURPRISES then
		task.spawn(surpriseLoop)
	end
	for _, event in Events.list do
		local eventId = event.id
		-- Orders arrive from a new purchase, or owed from a server that closed or that the buyer left.
		Purchases.register("Event:" .. eventId, event.productId, function(player: Player, order)
			local place = EventService.trigger(eventId, player.DisplayName, "Robux", true, {
				purchaseId = order.p,
				userId = player.UserId,
			})
			if not place then
				return
			end
			local earlier = os.time() - order.t > 60
			notify(player, string.format(if earlier then "Your %s from last time %s" else "Thanks! Your %s %s", event.name, placeOf(place)), if earlier then nil else "bought:" .. eventId, place <= 1 and not current) -- (V9-0i: the SHOP card bursts)
		end)
	end
	-- (V9-0u: a hidden event's product, still owed to someone who paid before: its stand-in instead.)
	for _, gone in (Events :: any).hidden or {} do
		local instead = Events.byId[gone.instead]
		if instead and gone.productId ~= 0 then
			Purchases.register("Event:" .. gone.id, gone.productId, function(player: Player, order)
				local place = EventService.trigger(instead.id, player.DisplayName, "Robux", true, {
					purchaseId = order.p,
					userId = player.UserId,
				})
				if place then
					notify(player, string.format("The UFO is away for now: your %s %s", instead.name, placeOf(place)), nil, place <= 1 and not current)
				end
			end)
		end
	end
	-- Every player gets the state as they join (the banner of an event already running), then
	-- anything they are still owed.
	local state = stateRemote :: RemoteEvent
	local function joined(player: Player)
		state:FireClient(player, snapshot())
		task.spawn(Purchases.claimOwed, player)
		-- Once more shortly after: the server they came from may still be giving their orders back.
		task.delay(20, function()
			if player.Parent then
				Purchases.claimOwed(player)
			end
		end)
	end
	Purchases.setOnWaiting(function(player: Player)
		notify(player, "Your purchase is on its way. It shows up in a moment!")
	end)
	Players.PlayerAdded:Connect(joined)
	for _, player in Players:GetPlayers() do
		joined(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastPrompt[player] = nil
		lastPassEvent[player] = nil
		buyerLeft(player.UserId)
	end)
	game:BindToClose(function()
		-- Closing first: no event starts, and orders arriving now are given straight back. Then
		-- every waiting paid event goes back to its buyer, and the server waits for those writes
		-- (and any other order write still in flight).
		Purchases.close()
		local waiting = table.clone(queue)
		table.clear(queue)
		giveBack(waiting)
		Purchases.flush(25)
	end)
	task.spawn(function()
		while true do
			-- (A co-op horde in the lab goes first: its runners and an event's bodies never at once.)
			local hordeOn = Workspace:GetAttribute("HordeOn") == true
			if not current and not hordeOn and not isClosing() and not heldForTest and #queue > 0 and os.clock() >= nextAt then
				local job = table.remove(queue, 1) :: Job
				task.spawn(run, job)
			end
			task.wait(0.2)
		end
	end)
	log.info("ready")
end

return EventService
