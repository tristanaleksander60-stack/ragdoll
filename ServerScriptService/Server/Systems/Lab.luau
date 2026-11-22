--!strict
-- Every player's own lab (round 2, N1). The ground is a row of lab plots either side of the plaza:
--
--     ... plot 4 | plot 2 | PLAZA | plot 1 | plot 3 ...      (x = -340, -170, 0, +170, +340, ...)
--
-- The plaza in the middle (at the old spawn) keeps the people, the public playground, the horde
-- and the server events nobody's lab is the place for. Each plot is a lab of its own: a row of
-- dummies in front of its spawn point, its own playground, a sign with its owner's name and the
-- owner's Workshop area. A player who joins gets the free plot nearest the plaza and spawns in it;
-- with every plot taken, they start in the plaza (and build there, as everyone did before).
--
-- A plot's dummies are its owner's: their client simulates them. Lost dummies are replaced.
-- Knocked away, a dummy walks (or limps, or crawls) back to its slot by itself (ActiveRagdoll knows
-- its Home); only one that fell out of the world, went very far or is stuck pops back. A hurt dummy
-- that has rested at home a while gets patched up.
--
-- Each lab's six have their own ways (round 2): two cowards run away from whoever makes a bang near
-- them (a shot, a blast, a hard hit), a brave one stands its ground, a friendly one now and then
-- walks up to a player in the lab to wave and say hi, and two chatty ones walk over to each other
-- for a chat. Everyone turns to look at a bang (DummyLife, on every screen). They go about it by
-- moving their Home for a while (the ordinary dummy brain walks them there), and always come back.
--
-- Every plot is on the same axes as the plaza (no turning), so the Workshop's half-stud grid lines
-- up in all of them. Players and clients learn their lab from Player attributes: LabPlot (index),
-- LabOrigin and LabFocus; the Workspace's LabOrigin and LabFocus stay the plaza's.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared") -- (V9-0h: PathPlan)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DummyFactory = require(script.Parent.DummyFactory)
local DummyControl = require(script.Parent.DummyControl)
local FxService = require(script.Parent.FxService)
local Finish = require(script.Parent.Finish)
local Log = require(ReplicatedStorage.Shared.Log)
local Net = require(ReplicatedStorage.Shared.Net)
local Toys = require(ReplicatedStorage.Shared.Toys)
local N7Models = require(ReplicatedStorage.Shared.N7Models)
local Zones = require(ReplicatedStorage.Shared.Zones)
local GunThreat = require(ReplicatedStorage.Shared.GunThreat)

local log = Log.new("Lab")

-- (session v850, owner: "tilføj 4 mere"): ten dummies on the test row (was six). They wander the
-- whole lab on their own after they first stand (ROAM_* below).
local DUMMY_COUNT = 18 -- (22 Nov 2026, owner: 18 dummies walking round the lab; nothing else spawns: Config.ONLY_LAB_DUMMIES)
local RADIUS = 22
local RESPAWN_DELAY = 3
local AWAY_DISTANCE = 6 -- studs from the slot: on its way home
local STUCK_AFTER = 12 -- s on its way home without getting closer: pop it back
local HEAL_AFTER = 12 -- s resting at home with a broken limb before it is patched up
-- (session v850: they roam all over the lab now; a far-away body is no longer "lost". Doubled
-- from 300 so a wanderer on the far side of the garden walks is kept alive.)
local LOST_DISTANCE = 600 -- this far from the slot in any state: bring it home now
local FELL_BELOW = -25 -- fell off the world
-- Their ways, by slot (see the top). Ten entries now (session v850).
local NAMES = { "Wobbly Steve", "Sir Flops", "Noodle", "Big Greg", "Captain Crash", "Tiny Tim", "Floppy Joe", "Professor Pancake", "Mr. Bonk", "Lil Dave", "Sergeant Squish", "Gary", "Biscuit", "Uncle Ragnar", "Jelly Jen", "Bouncy Bob", "Dizzy Dora", "Karl the Klutz" } -- (22 Nov 2026: one name per slot, the talk menu)
local PERSONALITY = { "Coward", "Friendly", "Brave", "Chatty", "Coward", "Friendly", "Coward", "Chatty", "Friendly", "Coward", "Brave", "Chatty", "Coward", "Friendly", "Coward", "Chatty", "Friendly", "Coward" } -- (22 Nov 2026, owner: they must fear guns: 18 ways, only 2 Brave; slots past the list were all Brave)
local CHAT_PAIR = { 4, 5 }
-- (session v850, owner: "dem der står på den sorte plade står stille, så begår at gå rundt i hele ens map"):
-- every slot picks a new wandering Home every ROAM_EVERY s (or when it reaches the last one). The
-- first roam waits ROAM_FIRST s after the slot first stands — so a new visitor sees the row standing
-- still before they drift off.
local ROAM_FIRST = 0 -- (22 Nov 2026, owner: no row standing still) s before a slot first starts wandering
local ROAM_EVERY_MIN, ROAM_EVERY_MAX = 10, 22 -- s before it picks the next spot (random in range)
local ROAM_REACH = 8 -- studs from its current roam Home where it counts as arrived
local ROAM_RANGE = 55 * ((Config :: any).LAB_SPREAD or 1) -- studs from the plot's spawn: the farthest a roam Home may be (22 Nov: inside the lab core)
local ROAM_YARD_Z = 40 * ((Config :: any).LAB_SPREAD or 1) -- (22 Nov 2026: never past this z, the creature yard, where a walker was swallowed and vanished)
local ROAM_NEAR_MIN = 18 -- studs: closest a roam Home may be (never right on top of the player)
local GREET_RANGE = 40 -- studs from its home: a player this close may get a hello
local GREET_STOP = 4.5 -- studs in front of the player where it stops
local GREET_TIME = 3.2 -- s of waving
local GREET_TRIP = 12 -- s at most for the whole hello (there, wave, back)
local GREET_GAP_MIN, GREET_GAP_MAX = 22, 40 -- s between two hellos
local CHAT_GAP = 3.2 -- studs between two chatting
local CHAT_OUT = 9 -- studs out in front of the row where the two meet (a real walk: a dummy sets off
-- for a Home over 5 studs away)
local CHAT_TIME_MIN, CHAT_TIME_MAX = 8, 13 -- s of chatting
local CHAT_EVERY_MIN, CHAT_EVERY_MAX = 25, 45 -- s between two chats
local SCARE_TIME = 2.6 -- s a coward runs from a bang
local SCARE_REST = 5 -- s before the same coward runs again
local SCARE_SHOT = 30 -- studs: a coward runs from a shot this close
local SCARE_BLAST = 55 -- ... a blast
local SCARE_HIT = 14 -- ... a hard hit
local SOURCE_RANGE = 120 -- studs: a bang's maker this close is who it runs from (else the bang)

local Lab = {}
Lab.DUMMY_COUNT = DUMMY_COUNT -- (World/Feel v2: T80 adds it to a device's ragdoll budget)

Lab.PLOT_COUNT = 10 -- labs on one server (the place's server size should be 10)
Lab.PLOT_SPACING = Zones.PLOT_SPACING -- studs between the middles of two neighbouring labs (and the plaza; V6-4 wider)
Lab.PLOT_HALF = Zones.PLOT_HALF -- half a plot's width: closer than this to its middle line, you are in it
local S = (Config :: any).LAB_SPREAD or 1 -- (0.37.0: the bigger lab)
Lab.CORE_HALF = 85 * S -- the concrete lab inside it (markings and floor; the rest is the V6-4 garden)
Lab.GROUND_TOP = 600 -- studs above the floor: higher than this you are in the rooms, not on the ground

type Slot = {
	index: number,
	position: Vector3,
	lastPosition: Vector3,
	model: Model?,
	awayTime: number, -- s on its way home without getting closer
	bestDistance: number,
	restTime: number, -- s standing at home hurt
	fleeTime: number, -- s fleeing in a row
	downTime: number, -- s down (lying, out cold, getting up) in a row
	excusedTime: number, -- s of excused pauses on this trip home
	homeY: number,
	homeAttr: Vector3?, -- its own Home and HomeLook (a hello or a chat moves them for a while)
	homeLook: Vector3?,
	target: Vector3?, -- where it is walking for a hello or a chat (nil: home)
	socialUntil: number, -- os.clock when that trip is over
	socialKind: string?,
	nextSocialAt: number,
	scaredAt: number,
	-- (session v850: wandering the lab on its own)
	roamHome: Vector3?, -- the current wander spot, or nil (on the row)
	nextRoamAt: number, -- os.clock to pick the next roam spot
}

type Plot = {
	index: number,
	origin: Vector3,
	owner: Player?,
	slots: { Slot },
	folder: Folder, -- its sign and edge lines
	sign: TextLabel?,
	built: boolean, -- its playground stands (it stays when the owner leaves)
	generation: number, -- bumped when the plot changes hands: old refills are dropped
}

local FLEE_GRACE = 6 -- s of fleeing that do not count as "no progress" (it is meant to go away)
local DOWN = { Ragdoll = true, Out = true, GettingUp = true, Flinch = true, Stumble = true, Recovering = true }
local EXCUSE_LIMIT = 40 -- s of excused pauses one trip home may have in all (no endless fall-and-get-up)
local MAX_SPEED = require(ReplicatedStorage.Shared.Ragdoll.Config).MAX_LINEAR_SPEED + 40 -- studs/s: no toy gets near it

local plots: { Plot } = {}
local plotOf: { [Player]: Plot } = {}
local worldOrigin = Vector3.zero -- the plaza's middle (where the place's spawn stands)
local labsFolder: Folder
local playgroundBuilder: ((origin: Vector3, name: string) -> ())? = nil

local function spawnOrigin(): Vector3
	local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
	return if spawnLocation then spawnLocation.Position else Vector3.zero
end

-- The middle of plot i: odd ones to the east of the plaza, even ones to the west, nearest first.
function Lab.plotCenter(index: number): Vector3
	local side = if index % 2 == 1 then 1 else -1
	local step = math.ceil(index / 2)
	local o = worldOrigin
	return Vector3.new(math.round(o.X) + side * step * Lab.PLOT_SPACING, o.Y, math.round(o.Z))
end

local function focusOf(origin: Vector3): Vector3
	-- (V9-0h review: under LAYOUT_V3 the lab view looks at the test row behind the bullseye.)
	if (Config :: any).LAYOUT_V3 then
		return origin + Vector3.new(0, 2.5, (require(Shared:WaitForChild("PathPlan")) :: any).ROW_Z * 0.85)
	end
	return origin + Vector3.new(0, 2.5, -RADIUS * 0.85)
end

local function slotPosition(origin: Vector3, index: number): Vector3
	-- An arc in front of the plot's spawn point (towards -Z), facing it.
	-- (V9-0h, Config.LAYOUT_V3: on the rim, a test row behind the bullseye: a narrower arc further out.)
	local v3 = (Config :: any).LAYOUT_V3 == true
	local radius = if v3 then -(require(Shared:WaitForChild("PathPlan")) :: any).ROW_Z - 2 else RADIUS
	local spread = math.rad(if v3 then 40 else 70)
	local t = if DUMMY_COUNT > 1 then (index - 1) / (DUMMY_COUNT - 1) else 0.5
	local angle = -spread / 2 + spread * t
	return origin + Vector3.new(math.sin(angle) * radius, 0, -math.cos(angle) * radius)
end
Lab.slotPosition = slotPosition -- (tests: where each slot of the row stands)
Lab.slotCount = function(): number
	return DUMMY_COUNT
end

local function poof(at: Vector3)
	local ball = Instance.new("Part")
	ball.Name = "Poof"
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = Color3.new(1, 1, 1)
	ball.Size = Vector3.one * 2
	ball.Position = at
	ball.Parent = Workspace
	local tween = TweenService:Create(ball, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * 7,
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		ball:Destroy()
	end)
end

local pickRoamSpot: (plot: Plot, slot: Slot) -> Vector3

local function fill(plot: Plot, slot: Slot, generation: number)
	local owner = plot.owner
	if plot.generation ~= generation or not owner or owner.Parent == nil then
		return
	end
	-- (22 Nov 2026, owner: "not in one place"): each one appears at its own spot round the lab.
	local model = DummyFactory.spawn(pickRoamSpot(plot, slot), plot.origin, owner)
	model:SetAttribute("Slot", slot.index)
	model:SetAttribute("Plot", plot.index)
	model:SetAttribute("LabOwner", owner.UserId)
	model:SetAttribute("Personality", PERSONALITY[slot.index] or "Brave")
	-- (22 Nov 2026, owner: funny names in the talk menu, so "Wobbly Steve, attack Sir Flops" reads well.)
	model:SetAttribute("PersonName", NAMES[slot.index] or ("Dummy " .. slot.index))
	slot.target = nil
	slot.socialKind = nil
	slot.socialUntil = 0
	slot.nextSocialAt = os.clock() + math.random(8, 20)
	slot.model = model
	slot.awayTime = 0
	slot.homeY = model:GetPivot().Position.Y
	slot.bestDistance = 0
	slot.restTime = 0
	-- Where it walks back to (pelvis position) and which way it then faces.
	local pelvisHome = model:FindFirstChild("LowerTorso")
	slot.homeAttr = if pelvisHome and pelvisHome:IsA("BasePart") then pelvisHome.Position else slot.position
	slot.homeLook = Vector3.new(plot.origin.X, slot.position.Y, plot.origin.Z)
	model:SetAttribute("Home", slot.homeAttr)
	model:SetAttribute("HomeLook", slot.homeLook)
	-- (session v850: pick the first roam spot after the welcome time, so a visitor first sees the row
	-- standing still before any of them drifts off.)
	slot.roamHome = nil
	slot.nextRoamAt = os.clock() + ROAM_FIRST + math.random() * 2
	model.Destroying:Once(function()
		if slot.model == model then
			local last = slot.lastPosition
			if last then
				slot.position = last + Vector3.new(0, 3, 0)
			end
			slot.model = nil
			task.delay(RESPAWN_DELAY, fill, plot, slot, generation)
		end
	end)
	-- Parts fall below FallenPartsDestroyHeight one by one; treat a lost pelvis as a lost dummy.
	local pelvis = model:FindFirstChild("LowerTorso")
	if pelvis then
		pelvis.AncestryChanged:Connect(function(_, parent)
			if parent == nil and model.Parent then
				model:Destroy()
			end
		end)
	end
end

-- A white puff where something appears or disappears (events use it too).
Lab.poof = poof

-- Ends a hello or a chat: its own Home again (it walks back there).
local function endSocial(slot: Slot)
	local model = slot.model
	slot.target = nil
	slot.socialKind = nil
	slot.socialUntil = 0
	slot.nextSocialAt = os.clock() + math.random(CHAT_EVERY_MIN, CHAT_EVERY_MAX)
	if model and model.Parent and model:GetAttribute("CommandedBy") == nil then -- (v4 B4: a player's command walks it now)
		model:SetAttribute("Home", slot.homeAttr)
		model:SetAttribute("HomeLook", slot.homeLook)
		model:SetAttribute("Chatting", nil)
		model:SetAttribute("GreetUntil", nil)
	end
end

local function returnHome(plot: Plot, slot: Slot, model: Model)
	-- Do not reset, destroy, or teleport a lab dummy because it moved away or was flung.
	return
end

local function watchSlot(plot: Plot, slot: Slot, dt: number)
	local model = slot.model
	if not model or not model.Parent then
		return
	end
	local pelvis = model:FindFirstChild("LowerTorso") :: BasePart?
	if not pelvis then
		return
	end
	if pelvis.Position.Y >= plot.origin.Y - 5 and pelvis.Position.Y < plot.origin.Y + Lab.GROUND_TOP then
		slot.lastPosition = pelvis.Position
	end
	-- v4 B4: a body a player commands (NpcCommand) is not "lost": it is not walked or sent home.
	-- (V6-5: nor one inside a lab creature: the creature lets it go in a moment.)
	if model:GetAttribute("CommandedBy") ~= nil or model:GetAttribute("InMachine") ~= nil then
		slot.awayTime = 0
		return
	end
	local state = model:GetAttribute("RagdollState")
	-- (On a hello or a chat it is headed somewhere else for a while: measured from there.)
	local goal = slot.target or slot.position
	local distance = Vector3.new(pelvis.Position.X - goal.X, 0, pelvis.Position.Z - goal.Z).Magnitude
	if pelvis.Position.Y < FELL_BELOW or distance > LOST_DISTANCE then
		slot.awayTime = 0
		returnHome(plot, slot, model)
		return
	end
	-- Its simulating client keeps dummies under 180 studs/s; much faster is not physics. (Checked
	-- for the dead too: a client never flings a corpse about; returnHome takes a dead one away.)
	if pelvis.AssemblyLinearVelocity.Magnitude > MAX_SPEED then
		log.warn("dummy " .. plot.index .. "/" .. slot.index .. " moving impossibly fast; sent home")
		returnHome(plot, slot, model)
		return
	end
	-- Round 4, M10: a dead one lies where it fell for the whole DEAD_HOLD (never sent home);
	-- VitalsService takes it then and the slot refills (Destroying, fill).
	if model:GetAttribute("Vital") == "Dead" then
		slot.awayTime = 0
		slot.restTime = 0
		slot.downTime = 0
		return
	end
	-- Away from home it should keep getting closer, whatever its client says it is doing. A
	-- short flee pauses the clock for a limited time. A ragdoll/out-cold body pauses it until it
	-- actually gets up: a deliberately limp body must never be reset just for lying still.
	slot.fleeTime = if state == "Fleeing" then slot.fleeTime + dt else 0
	slot.downTime = if DOWN[state] then slot.downTime + dt else 0
	-- Frozen or carried in a grab it cannot move at all. Lying down is also excused without a
	-- timer: a player may leave a dummy ragdolled indefinitely. Fleeing remains capped per trip.
	local stopped = model:GetAttribute("Frozen") == true or model:GetAttribute("Held") == true
	local paused = state == "Fleeing" and slot.fleeTime < FLEE_GRACE
	if distance <= AWAY_DISTANCE then
		-- Home: the next trip starts measuring from wherever it is knocked to.
		slot.awayTime = 0
		slot.excusedTime = 0
		slot.bestDistance = math.huge
	elseif stopped or DOWN[state] or (paused and slot.excusedTime < EXCUSE_LIMIT) then
		if paused and not stopped then
			slot.excusedTime += dt
		end
		-- Knocked further off or running away: the trip home is measured from there.
		slot.bestDistance = if slot.bestDistance == math.huge then distance else math.max(slot.bestDistance, distance)
		slot.awayTime = 0
	elseif distance < slot.bestDistance - 1 then
		slot.bestDistance = distance
		slot.awayTime = 0
	else
		slot.awayTime += dt
		if slot.awayTime > STUCK_AFTER then
			slot.awayTime = 0
			slot.excusedTime = 0
			slot.bestDistance = math.huge
			returnHome(plot, slot, model)
		end
	end
	-- Resting at home with a broken limb: patched up after a while.
	local broken = model:GetAttribute("Broken")
	if type(broken) == "number" and broken > 0 and not slot.target and distance <= AWAY_DISTANCE and (state == "Standing" or state == "Crawling") then
		slot.restTime += dt
		if slot.restTime > HEAL_AFTER then
			slot.restTime = 0
			DummyControl.heal(model)
			FxService.hit(pelvis.Position + Vector3.new(0, 1, 0), 0, "Heal")
		end
	else
		slot.restTime = 0
	end
end

-- During the self-tests the dummies keep still (the tests want them at home), unless a test asks
-- (or ServerStorage's LabLive is on: looking at them by hand after a run).
local quietInTests = true
local function testing(): boolean
	local storage = game:GetService("ServerStorage")
	-- (Studio only: a place saved with RunSelfTest on never quiets a live server.)
	return game:GetService("RunService"):IsStudio()
		and storage:GetAttribute("RunSelfTest") == true
		and storage:GetAttribute("LabLive") ~= true
end
-- (A test that turns them on starts each hello or chat itself: socialNowForTest.)
function Lab.liveForTest(on: boolean)
	quietInTests = not on
	for _, plot in plots do
		for _, slot in plot.slots do
			if slot.socialKind then
				endSocial(slot)
			end
			-- (Off again: back to the usual waits.)
			slot.nextSocialAt = if on then math.huge else os.clock() + math.random(8, 20)
		end
	end
end

local function upright(model: Model?): boolean
	local state = model and model.Parent and model:GetAttribute("RagdollState")
	return (state == "Standing" or state == "Walking") and model ~= nil and model:GetAttribute("Frozen") ~= true
		and model:GetAttribute("Held") ~= true and (model:GetAttribute("Broken") or 0) == 0
end

local function atHome(slot: Slot): boolean
	local model = slot.model
	local pelvis = model and model:FindFirstChild("LowerTorso")
	return not slot.target and model ~= nil and model:GetAttribute("CommandedBy") == nil and model:GetAttribute("RagdollState") == "Standing" and upright(model)
		and pelvis ~= nil and pelvis:IsA("BasePart")
		and Vector3.new(pelvis.Position.X - slot.position.X, 0, pelvis.Position.Z - slot.position.Z).Magnitude <= AWAY_DISTANCE
end

local function pelvisY(slot: Slot): number
	return if slot.homeAttr then slot.homeAttr.Y else slot.position.Y + 2
end

-- The friendly one: walks up to a player in its lab and says hi.
local function startGreeting(plot: Plot, slot: Slot, now: number): boolean
	local best: BasePart? = nil
	local bestDistance = GREET_RANGE
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- (Not to someone who just fired a gun: GunThreat.)
		if root and root:IsA("BasePart") and character:GetAttribute("RagdollState") ~= "Ragdoll" and not GunThreat.raised(character) then
			local d = Vector3.new(root.Position.X - slot.position.X, 0, root.Position.Z - slot.position.Z).Magnitude
			-- (Far enough that it really walks over: a dummy sets off for a Home over 5 studs away.)
			if d < bestDistance and d > GREET_STOP + 6.5 and math.abs(root.Position.Y - slot.position.Y) < 8 then
				best, bestDistance = root, d
			end
		end
	end
	local model = slot.model
	if not best or not model then
		return false
	end
	local from = Vector3.new(slot.position.X, 0, slot.position.Z)
	local to = Vector3.new(best.Position.X, 0, best.Position.Z)
	local spot = to - (to - from).Unit * GREET_STOP
	slot.target = spot
	slot.socialKind = "Greet"
	slot.socialUntil = now + GREET_TRIP
	model:SetAttribute("Home", Vector3.new(spot.X, pelvisY(slot), spot.Z))
	model:SetAttribute("HomeLook", Vector3.new(to.X, pelvisY(slot), to.Z))
	model:SetAttribute("GreetUntil", nil)
	return true
end

-- The chatty two: they step out of the row towards the middle of the lab, meet face to face and
-- talk a while (then each walks back to its own place).
local function startChat(plot: Plot, a: Slot, b: Slot, now: number)
	local am, bm = a.model, b.model
	if not am or not bm then
		return
	end
	local pa = Vector3.new(a.position.X, 0, a.position.Z)
	local pb = Vector3.new(b.position.X, 0, b.position.Z)
	local mid = (pa + pb) / 2
	local out = Vector3.new(plot.origin.X, 0, plot.origin.Z) - mid
	out = if out.Magnitude > 0.1 then out.Unit else Vector3.zAxis
	local meet = mid + out * CHAT_OUT
	local across = pb - pa
	across = if across.Magnitude > 0.1 then across.Unit else Vector3.xAxis
	local spots = { meet - across * CHAT_GAP / 2, meet + across * CHAT_GAP / 2 }
	local length = now + math.random(CHAT_TIME_MIN * 10, CHAT_TIME_MAX * 10) / 10 + 5
	for i, slot in { a, b } do
		local model = (if i == 1 then am else bm) :: Model
		local spot = spots[i]
		local other = spots[3 - i]
		slot.target = spot
		slot.socialKind = "Chat"
		slot.socialUntil = length
		model:SetAttribute("Home", Vector3.new(spot.X, pelvisY(slot), spot.Z))
		model:SetAttribute("HomeLook", Vector3.new(other.X, pelvisY(slot), other.Z))
		-- 1 and 2: they take turns talking (DummyLife; the bubbles show once they stand).
		model:SetAttribute("Chatting", i)
	end
end

local function social(plot: Plot, now: number)
	if not plot.owner or (quietInTests and testing()) then
		return
	end
	for _, slot in plot.slots do
		local model = slot.model
		if slot.socialKind and model then
			local pelvis = model:FindFirstChild("LowerTorso")
			local there = slot.target and pelvis and pelvis:IsA("BasePart")
				and Vector3.new(pelvis.Position.X - slot.target.X, 0, pelvis.Position.Z - slot.target.Z).Magnitude <= 2.5
			if not upright(model) or now >= slot.socialUntil then
				-- Knocked over, frozen, grabbed, hurt or simply done: back to its own home.
				endSocial(slot)
			elseif slot.socialKind == "Greet" and there and model:GetAttribute("RagdollState") == "Standing" and model:GetAttribute("GreetUntil") == nil then
				model:SetAttribute("GreetUntil", Workspace:GetServerTimeNow() + GREET_TIME)
				slot.socialUntil = math.min(slot.socialUntil, now + GREET_TIME + 0.6)
			end
		end
	end
	-- (A chat ends for both when either ends.)
	local a, b = plot.slots[CHAT_PAIR[1]], plot.slots[CHAT_PAIR[2]]
	if a and b and (a.socialKind == "Chat") ~= (b.socialKind == "Chat") then
		if a.socialKind == "Chat" then
			endSocial(a)
		else
			endSocial(b)
		end
	end
	for _, slot in plot.slots do
		if not slot.socialKind and now >= slot.nextSocialAt and atHome(slot) then
			local kind = PERSONALITY[slot.index]
			if kind == "Friendly" then
				if not startGreeting(plot, slot, now) then
					slot.nextSocialAt = now + 4
				end
			elseif kind == "Chatty" and slot.index == CHAT_PAIR[1] and b and not b.socialKind and atHome(b) then
				startChat(plot, slot, b, now)
			else
				slot.nextSocialAt = now + 6
			end
		end
	end
end

-- A bang: the cowards near it run away from whoever made it.
local function heard(kind: string, position: Vector3, speed: number, toyId: string, sourceUserId: number?)
	if (kind ~= "Hit" and kind ~= "Shot") or toyId == "Heal" or toyId == "Balloon" or (quietInTests and testing()) then
		return
	end
	local gun = Toys.byId[toyId]
	local reach = if kind == "Shot" or (gun and gun.gun) then SCARE_SHOT elseif speed >= 100 then SCARE_BLAST elseif speed >= 55 then SCARE_HIT else 0
	if reach <= 0 then
		return
	end
	local source = position
	local maker = if sourceUserId and sourceUserId > 0 then Players:GetPlayerByUserId(sourceUserId) else nil
	local makerRoot = maker and maker.Character and maker.Character:FindFirstChild("HumanoidRootPart")
	if makerRoot and makerRoot:IsA("BasePart") and (makerRoot.Position - position).Magnitude < SOURCE_RANGE then
		source = makerRoot.Position
	end
	local now = os.clock()
	-- V8-0.2 (Config.V8_FIRST_HIT): calmer cowards. 5 of 6 ran from every shot, so a newcomer could
	-- hardly hit anything. Now nobody runs in a newcomer's first CALM_FIRST s; after that only the
	-- coward nearest the bang runs, for FLEE_SHORT s, and at most FLEE_MAX run at once in a lab.
	local calm = (Config :: any).V8_FIRST_HIT == true
	for _, plot in plots do
		if calm and plot.owner and math.abs(position.X - plot.origin.X) < Lab.PLOT_HALF + SCARE_BLAST then
			local owner = plot.owner :: Player
			local joined = (owner:GetAttribute("V8JoinedAt") :: number?) or 0
			if owner:GetAttribute("Newcomer") == true and Workspace:GetServerTimeNow() - joined < (Config :: any).CALM_FIRST then
				continue
			end
			local running, nearest, nearestD = 0, nil :: any, math.huge
			local serverNow = Workspace:GetServerTimeNow()
			for _, slot in plot.slots do
				local model = slot.model
				local until_ = model and model:GetAttribute("PanicUntil")
				if type(until_) == "number" and until_ > serverNow then
					running += 1
				end
				local pelvis = model and model:FindFirstChild("LowerTorso")
				if model and PERSONALITY[slot.index] ~= "Brave" and model:GetAttribute("Greeter") == nil and pelvis and pelvis:IsA("BasePart") and upright(model)
					and now - slot.scaredAt >= SCARE_REST then
					local d = (pelvis.Position - position).Magnitude
					if d <= reach and d > 2 and d < nearestD then
						nearest, nearestD = slot, d
					end
				end
			end
			if nearest and running < (Config :: any).FLEE_MAX then
				nearest.scaredAt = now
				if nearest.socialKind then
					endSocial(nearest)
				end
				nearest.model:SetAttribute("PanicFrom", source)
				nearest.model:SetAttribute("PanicUntil", serverNow + (Config :: any).FLEE_SHORT)
			end
			continue
		end
		if plot.owner and math.abs(position.X - plot.origin.X) < Lab.PLOT_HALF + SCARE_BLAST then
			for _, slot in plot.slots do
				local model = slot.model
				local pelvis = model and model:FindFirstChild("LowerTorso")
				-- (10 Nov 2026, the owner: properly scared: every one but the brave runs from a bang.)
				if model and PERSONALITY[slot.index] ~= "Brave" and model:GetAttribute("Greeter") == nil and pelvis and pelvis:IsA("BasePart") and upright(model)
					and now - slot.scaredAt >= SCARE_REST then
					local d = (pelvis.Position - position).Magnitude
					if d <= reach and d > 2 then
						slot.scaredAt = now
						if slot.socialKind then
							endSocial(slot)
						end
						model:SetAttribute("PanicFrom", source)
						model:SetAttribute("PanicUntil", Workspace:GetServerTimeNow() + SCARE_TIME + math.random() * 0.8)
					end
				end
			end
		end
	end
end
Lab.heardForTest = heard

-- Private labs (round 3, M1): only the owner and the friends they invited may be in a lab. Each
-- client walls off the labs it may not enter (PlotPrivacy); this is the server's word on it: anyone
-- else found in one is put back in the plaza, and told whose lab it was.
function Lab.mayEnter(player: Player, index: number): boolean
	return Zones.mayEnter(player, index)
end

local function keepOut()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local index = Zones.plotAt(root.Position)
			if index and index > 0 and not Lab.mayEnter(player, index) then
				local at = worldOrigin + Vector3.new(0, 3.5, 40)
				character:PivotTo(CFrame.lookAt(at, at + Vector3.zAxis))
				local plot = plots[index]
				player:SetAttribute("PrivateLab", if plot and plot.owner then plot.owner.DisplayName else "")
				player:SetAttribute("PrivateLabAt", os.clock()) -- (the client says it each time)
			end
		end
	end
end

-- (session v850: picks a new wander spot for a slot — a point on free floor somewhere in the lab
-- core, never on top of a machine or inside the lava. We keep it simple: random polar offset from
-- the plot's spawn, between ROAM_NEAR_MIN and ROAM_RANGE. If the roll lands on a machine (PathPlan
-- obstacle) we try again a few times, else we fall back to the row spot.)
pickRoamSpot = function(plot: Plot, slot: Slot): Vector3
	local PathPlan = require(ReplicatedStorage.Shared:WaitForChild("PathPlan")) :: any
	local origin = plot.origin
	for _ = 1, 12 do
		local r = ROAM_NEAR_MIN + math.random() * (ROAM_RANGE - ROAM_NEAR_MIN)
		local a = math.random() * math.pi * 2
		local x, z = math.cos(a) * r, math.sin(a) * r
		local local2 = Vector2.new(x, z)
		local blocked = false
		for _, o in PathPlan.OBSTACLES do
			if o.at and o.radius and (local2 - o.at).Magnitude < o.radius + 2 then
				blocked = true
				break
			elseif o.min and o.max and local2.X > o.min.X - 2 and local2.X < o.max.X + 2 and local2.Y > o.min.Y - 2 and local2.Y < o.max.Y + 2 then
				blocked = true
				break
			end
		end
		if z > ROAM_YARD_Z then
			blocked = true
		end
		if not blocked then
			return Vector3.new(origin.X + x, if slot.homeY ~= 0 then slot.homeY else slot.position.Y, origin.Z + z)
		end
	end
	return slot.homeAttr or slot.position
end

-- (session v850: a slot that has no social trip, is not commanded, is not in a machine and is up
-- picks a new wander Home every ROAM_EVERY s. We only overwrite Home, not homeAttr — endSocial
-- and returnHome still reset to the row's slot.)
local function roam(plot: Plot, slot: Slot, now: number)
	local model = slot.model
	if not model or not model.Parent then
		return
	end
	if slot.target or slot.socialKind then
		return -- (a hello or a chat is running)
	end
	if model:GetAttribute("CommandedBy") ~= nil or model:GetAttribute("InMachine") ~= nil then
		return
	end
	if model:GetAttribute("Vital") == "Dead" then
		return
	end
	local state = model:GetAttribute("RagdollState")
	if state and state ~= "Standing" and state ~= "Walking" and state ~= "Fleeing" then
		return -- (down, getting up, in the air: no wandering)
	end
	if now < slot.nextRoamAt then
		-- Mid-walk: if it reached its current roam Home, pick another sooner.
		if slot.roamHome then
			local pelvis = model:FindFirstChild("LowerTorso")
			if pelvis and pelvis:IsA("BasePart") and (pelvis.Position - slot.roamHome).Magnitude < ROAM_REACH then
				slot.nextRoamAt = now + math.random(2, 5) -- (a short pause here, then on)
			end
		end
		return
	end
	local spot = pickRoamSpot(plot, slot)
	slot.roamHome = spot
	slot.nextRoamAt = now + math.random(ROAM_EVERY_MIN, ROAM_EVERY_MAX)
	model:SetAttribute("Home", spot)
	model:SetAttribute("HomeLook", spot + Vector3.new(math.random(-1, 1) * 5, 0, math.random(-1, 1) * 5))
end

local function watch(dt: number)
	keepOut()
	local now = os.clock()
	for _, plot in plots do
		for _, slot in plot.slots do
			watchSlot(plot, slot, dt)
			roam(plot, slot, now) -- (session v850: wanders the whole lab on its own)
		end
		social(plot, now)
	end
end

-- Tests: a slot's dummy, its personality, and starting a hello or a chat now.
function Lab.slotDummy(player: Player, index: number): Model?
	local plot = plotOf[player]
	local slot = plot and plot.slots[index]
	return if slot then slot.model else nil
end
function Lab.socialNowForTest(player: Player, index: number)
	local plot = plotOf[player]
	local slot = plot and plot.slots[index]
	if slot then
		if slot.socialKind then
			endSocial(slot)
		end
		slot.nextSocialAt = 0
	end
end
Lab.PERSONALITY = PERSONALITY

------------------------------------------------------------------------------------------------
-- The plots

local function edge(parent: Instance, size: Vector3, at: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Name = "Edge"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	p.Position = at
	p.Parent = parent
end

-- A plot's markings: thin lines on the floor round it and a big sign at its far end that says
-- whose lab it is (Roblox display names only; nobody types anything here).
local function markPlot(plot: Plot)
	local o = plot.origin
	local w = Lab.CORE_HALF * 2 - 10
	-- The lab runs from 72 behind the spawn (the Workshop's reach, 70, inside it) to 95 in front.
	local depth = 167 * S
	local zMid = o.Z - 11.5 * S
	local color = Color3.fromRGB(124, 200, 255)
	edge(plot.folder, Vector3.new(w, 0.06, 0.6), Vector3.new(o.X, 0.03, zMid - depth / 2), color)
	edge(plot.folder, Vector3.new(w, 0.06, 0.6), Vector3.new(o.X, 0.03, zMid + depth / 2), color)
	edge(plot.folder, Vector3.new(0.6, 0.06, depth), Vector3.new(o.X - w / 2, 0.03, zMid), color)
	edge(plot.folder, Vector3.new(0.6, 0.06, depth), Vector3.new(o.X + w / 2, 0.03, zMid), color)
	local board = Instance.new("Part")
	board.Name = "LabSign"
	board.Anchored = true
	board.CanCollide = false
	board.CanQuery = false
	board.CanTouch = false
	board.Material = Enum.Material.SmoothPlastic
	board.Color = Color3.fromRGB(22, 24, 34)
	board.Size = Vector3.new(40, 8, 1)
	board.CFrame = CFrame.lookAt(Vector3.new(o.X, 16, zMid - depth / 2 - 2), Vector3.new(o.X, 16, o.Z))
	for _, x in { -18, 18 } do
		local post = Instance.new("Part")
		post.Name = "LabSignPost"
		post.Anchored = true
		post.CanQuery = false
		post.Material = Enum.Material.Metal
		post.Color = Color3.fromRGB(45, 47, 58)
		post.Size = Vector3.new(1, 12, 1)
		post.Position = Vector3.new(o.X + x, 6, zMid - depth / 2 - 2.6)
		post.Parent = plot.folder
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(800, 160)
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "FREE LAB"
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 24)
	pad.PaddingRight = UDim.new(0, 24)
	pad.PaddingTop = UDim.new(0, 18)
	pad.PaddingBottom = UDim.new(0, 18)
	pad.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(80, 170, 255)
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = board
	board.Parent = plot.folder
	plot.sign = label
end

-- A lab looks like a crash-test lab (N7, fix round 2): a concrete floor over the whole plot, the
-- test zone painted under the dummies' row (a dark pad, a yellow border, hazard stripes at its
-- front), a padded crash wall well behind the row (a dummy knocked far hits it; nearer, it would
-- block shots and trap dummies behind it), a workbench either side of it, and striped barriers with cones down each side edge. All of it clear of the
-- playground (stairs and tower on the left, the swing on the right, the cannon and the ramp in
-- front) and outside the Workshop's reach at the sides. The painted floor is only a look: nothing
-- collides with it or is hit by a tap or a build ray.
local function prop(parent: Instance, name: string, at: Vector3, facing: Vector3, size: number)
	local model = N7Models.clone("Props", name)
	if not model then
		return
	end
	local _, box = model:GetBoundingBox()
	local big = math.max(box.X, box.Y, box.Z)
	model:ScaleTo(model:GetScale() * size / big)
	model:PivotTo(CFrame.lookAt(at, at - facing))
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false -- (scenery: nothing listens for touches on it)
			d.CastShadow = size >= 8
		end
	end
	model.Parent = parent
end

-- V9-NOW 11 (owner, 21 Nov 2026: "the big target blocks topple when shot"): the crash wall behind the row is three
-- big cream blocks (a red target on the first, a black ring and chevron on the others) instead of one mesh, each a
-- Knockables "Block": shots rock them over, blasts throw them, cars and bodies knock them, a falling one can knock
-- its neighbour; they stand back up at their spot after 10 s still (30 s at most) and on RESET.
Lab.TARGET_BLOCK = Vector3.new(9, 12.8, 7)
local function targetBlocks(parent: Instance, center: Vector3, ground: number)
	local Knockables = require(script.Parent:WaitForChild("Knockables")) :: any
	local cream = Color3.fromRGB(236, 230, 205)
	local size = Lab.TARGET_BLOCK
	for i = -1, 1 do
		local m = Instance.new("Model")
		m.Name = "TargetBlock"
		local block = Instance.new("Part")
		block.Name = "Block"
		block.Size = size
		block.Color = cream
		block.Material = Enum.Material.SmoothPlastic
		block.CFrame = CFrame.new(center.X + i * (size.X + 0.4), ground + size.Y / 2, center.Z)
		block.Anchored = true
		block.Parent = m
		for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 20
			gui.LightInfluence = 1
			gui.Parent = block
			local function circle(scale: number, color: Color3, ring: number?): Frame
				local f = Instance.new("Frame")
				f.AnchorPoint = Vector2.new(0.5, 0.5)
				f.Position = UDim2.fromScale(0.5, 0.36)
				f.Size = UDim2.fromScale(scale, scale * size.X / size.Y)
				f.BackgroundColor3 = color
				f.BackgroundTransparency = if ring then 1 else 0
				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(0.5, 0)
				c.Parent = f
				if ring then
					local s = Instance.new("UIStroke")
					s.Color = color
					s.Thickness = ring
					s.Parent = f
				end
				f.Parent = gui
				return f
			end
			if i == -1 then
				circle(0.7, Color3.fromRGB(210, 40, 40))
				circle(0.52, Color3.fromRGB(250, 250, 250))
				circle(0.34, Color3.fromRGB(210, 40, 40))
				circle(0.16, Color3.fromRGB(250, 250, 250))
			else
				circle(0.6, Color3.fromRGB(30, 30, 32), 22)
			end
			-- (The chevron at the foot: two dark bars meeting in a point.)
			for _, side in { -1, 1 } do
				local bar = Instance.new("Frame")
				bar.AnchorPoint = Vector2.new(0.5, 0.5)
				bar.Position = UDim2.fromScale(0.5 + side * 0.2, 0.8)
				bar.Size = UDim2.fromScale(0.5, 0.06)
				bar.Rotation = side * -22
				bar.BackgroundColor3 = Color3.fromRGB(30, 30, 32)
				bar.BorderSizePixel = 0
				bar.Parent = gui
			end
		end
		m.Parent = parent
		Knockables.make(m, "Block")
	end
end

local function paint(parent: Instance, name: string, size: Vector3, at: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = size
	p.Position = at
	p.Parent = parent
	return p
end

local function dressPlot(plot: Plot)
	local o = plot.origin
	local ground = o.Y - 0.5
	local folder = plot.folder
	-- The floor (the whole plot, within its markings): tiled lab concrete (Finish).
	local floor = paint(folder, "LabFloor", Vector3.new(Lab.CORE_HALF * 2 - 12, 0.04, 165 * S), Vector3.new(o.X, ground + 0.02, o.Z - 11.5 * S), Color3.fromRGB(176, 180, 188), Enum.Material.Concrete)
	-- (V9-P fix round 2: the floor you see answers a landing (FeelV2.surfaceAt), not the hidden ground under it.)
	game:GetService("CollectionService"):AddTag(floor, "VisibleFloor")
	local look3 = (Config :: any).LAYOUT_V3 and (Config :: any).LAYOUT_V3_FLOOR
	if look3 then
		-- (V9-0h: the leader's hub floor: big light tiles with thin joints, drawn by a texture on the
		-- floor itself, so nothing lies on it to flicker.)
		floor.Color = look3.color
		local tiles = Instance.new("Texture")
		tiles.Name = "Tiles"
		tiles.Face = Enum.NormalId.Top
		tiles.Texture = look3.texture
		tiles.StudsPerTileU = look3.tile
		tiles.StudsPerTileV = look3.tile
		tiles.Color3 = Color3.fromRGB(206, 206, 202) -- (a light grey in the bright sun, never glaring white)
		tiles.Parent = floor
		-- (V9-0k, Config.HUB_FLOOR_PADS: soft padded cushions instead of flat white tiles: a PBR
		-- MaterialVariant with a pillow normal map on the same one flat floor (MaterialService,
		-- place file). The bevels catch the light; the floor stays one flat part for the physics.)
		local pads = (Config :: any).HUB_FLOOR_PADS
		if pads and game:GetService("MaterialService"):FindFirstChild(pads.variant, true) then
			tiles:Destroy()
			floor.Material = pads.material
			floor.MaterialVariant = pads.variant
			floor.Color = pads.color
		end
	else
		Finish.apply(floor, "Floor")
	end
	-- 0.37.0 (owner, 22 Nov 2026: the biggest game's map: grass with paved walks and a round plaza at the
	-- spawn): the floor turns to lawn, a stone plaza lies round the spawn and a straight paved walk runs
	-- from its rim out to every machine, so each one has a clear line to walk along. Pictures only (thin,
	-- not colliding, not queried): the floor under them stays the one floor the physics and rays use.
	if (Config :: any).LAB_GRASS then
		for _, t in floor:GetChildren() do
			if t:IsA("Texture") then
				t:Destroy()
			end
		end
		floor.MaterialVariant = ""
		floor.Material = Enum.Material.Grass
		floor.Color = Color3.fromRGB(92, 148, 66)
		local stoneColor = Color3.fromRGB(196, 190, 176)
		local PLAZA_R = 30
		local plaza = paint(folder, "Plaza", Vector3.new(0.06, PLAZA_R * 2, PLAZA_R * 2), Vector3.new(o.X, ground + 0.08, o.Z), stoneColor, Enum.Material.Slate)
		plaza.Shape = Enum.PartType.Cylinder
		plaza.CFrame = CFrame.new(plaza.Position) * CFrame.Angles(0, 0, math.rad(90))
		local rim = paint(folder, "PlazaRim", Vector3.new(0.05, PLAZA_R * 2 + 2.4, PLAZA_R * 2 + 2.4), Vector3.new(o.X, ground + 0.06, o.Z), Color3.fromRGB(120, 116, 108), Enum.Material.Slate)
		rim.Shape = Enum.PartType.Cylinder
		rim.CFrame = CFrame.new(rim.Position) * CFrame.Angles(0, 0, math.rad(90))
		local PathPlanM = require(Shared:WaitForChild("PathPlan")) :: any
		local Sp = (Config :: any).LAB_SPREAD or 1
		local areaRects: { { at: Vector2, min: Vector2, max: Vector2 } } = {}
		-- 0.37.1 (owner, the reviewer: "build real areas with their own theme"): each quarter round the plaza
		-- gets its own ground, so you see four places, not one lawn with machines on it. Launch (east, in
		-- front: cannon, ramp, stations) on red rubber; cars and crashes (east, behind) on asphalt; danger
		-- (west, in front: mace, press) on sand; height (west, behind: tower, fan, throw tower) on concrete.
		for _, a in {
			{ name = "LaunchArea", at = Vector2.new(42, 30), size = Vector2.new(68, 62), color = Color3.fromRGB(150, 70, 60), material = Enum.Material.Concrete },
			{ name = "CarArea", at = Vector2.new(58, -42), size = Vector2.new(46, 72), color = Color3.fromRGB(70, 72, 78), material = Enum.Material.Asphalt },
			{ name = "DangerArea", at = Vector2.new(-40, 42), size = Vector2.new(58, 56), color = Color3.fromRGB(214, 190, 140), material = Enum.Material.Sand },
			{ name = "HeightArea", at = Vector2.new(-58, -40), size = Vector2.new(48, 80), color = Color3.fromRGB(168, 170, 174), material = Enum.Material.Concrete },
		} do
			local mid = a.at * Sp
			table.insert(areaRects, { at = mid, min = mid - a.size * Sp / 2, max = mid + a.size * Sp / 2 })
			local area = paint(folder, a.name, Vector3.new(a.size.X * Sp, 0.04, a.size.Y * Sp), Vector3.new(o.X + mid.X, ground + 0.05, o.Z + mid.Y), a.color, a.material)
			-- (a darker edge round it, a hair lower: the area reads as a place with a border)
			paint(folder, a.name .. "Edge", Vector3.new(a.size.X * Sp + 2, 0.03, a.size.Y * Sp + 2), Vector3.new(o.X + mid.X, ground + 0.045, o.Z + mid.Y), a.color:Lerp(Color3.new(0, 0, 0), 0.35), a.material)
			area:SetAttribute("Area", a.name)
		end
		-- (0.37.1, owner: "the portals stand half in the grass"): one stone platform under the travel corner
		-- (MapBoard.TRAVEL_SPOTS: the MAPS board between SINGLEPLAYER and MULTIPLAYER), along its line.
		do
			local solo, multi = Vector2.new(-2, 64), Vector2.new(-2, 36) -- (0.37.13: MapBoard.TRAVEL_SPOTS, between the launch and the danger areas)
			local mid, along = (solo + multi) / 2, (solo - multi)
			local pad = paint(folder, "TravelPad", Vector3.new(16, 0.05, along.Magnitude + 16), Vector3.new(o.X + mid.X, ground + 0.075, o.Z + mid.Y), stoneColor, Enum.Material.Slate)
			pad.CFrame = CFrame.lookAt(pad.Position, pad.Position + Vector3.new(along.X, 0, along.Y))
			local edge = paint(folder, "TravelPadEdge", Vector3.new(17.2, 0.04, along.Magnitude + 17.2), Vector3.zero, Color3.fromRGB(120, 116, 108), Enum.Material.Slate)
			edge.CFrame = pad.CFrame * CFrame.new(0, -0.006, 0)
		end
		-- (0.37.3, owner: "the boxing ring overlaps the grass"): a stone floor under the ring (Playground: the pit at
		-- -6, 54, 21 x 18), with room to walk round it.
		paint(folder, "RingFloor", Vector3.new(29, 0.05, 26), Vector3.new(o.X - 111, ground + 0.075, o.Z - 28), stoneColor, Enum.Material.Slate)
		paint(folder, "RingFloorEdge", Vector3.new(30.2, 0.04, 27.2), Vector3.new(o.X - 111, ground + 0.069, o.Z - 28), Color3.fromRGB(120, 116, 108), Enum.Material.Slate)
		-- 0.37.5 (owner: "the walks to every thing are ugly: one walk from the spawn to each area's platform, not
		-- three or four per area"): one straight walk from the plaza's rim to where each area's ground starts
		-- (an area the plaza already touches needs none), and one out to the creature yard. No caps: a walk runs
		-- on into its area's ground.
		local goals: { { at: Vector2, min: Vector2?, max: Vector2? } } = {}
		for _, r in areaRects do
			table.insert(goals, r)
		end
		-- (0.37.7, owner: the walk out across the launch area is gone; the garden roads lead to the yard.)
		if (Config :: any).LAB_NO_PATHS then
			table.clear(goals) -- (0.37.8, owner: just the platforms)
		end
		for i, g in goals do
			local dir = if g.at.Magnitude > 1 then g.at.Unit else Vector2.new(0, 1)
			local from = dir * (PLAZA_R - 1)
			local reach = g.at.Magnitude
			if g.min and g.max then
				-- (where the ray from the spawn enters the area's box)
				local enter = 0
				for _, axis in { "X", "Y" } do
					local d = (dir :: any)[axis] :: number
					if math.abs(d) > 1e-3 then
						local t1, t2 = ((g.min :: any)[axis] :: number) / d, ((g.max :: any)[axis] :: number) / d
						enter = math.max(enter, math.min(t1, t2))
					end
				end
				reach = enter + 1.5
			end
			local to = dir * reach
			local len = (to - from).Magnitude
			if reach > PLAZA_R + 2 then
				local mid = (from + to) / 2
				local y = ground + 0.07 + i * 0.002 -- (each walk a hair apart: no flicker)
				local walk = paint(folder, "Walk", Vector3.new(8, 0.05, len), Vector3.new(o.X + mid.X, y, o.Z + mid.Y), stoneColor, Enum.Material.Slate)
				walk.CFrame = CFrame.lookAt(walk.Position, walk.Position + Vector3.new(dir.X, 0, dir.Y))
			end
		end
	end
	-- The test zone under the row: a black rubber safety mat. (0.37.3: not on the lawn layout; the spider
	-- stands there now, LabCreatures.)
	local rowZ = o.Z + (require(Shared:WaitForChild("PathPlan")) :: any).ROW_Z -- (V9-0h: behind the bullseye under LAYOUT_V3)
	if not (Config :: any).LAB_GRASS then
	local mat = paint(folder, "TestZone", Vector3.new(42, 0.05, 16), Vector3.new(o.X, ground + 0.12, rowZ) -- (V9-0d: 0.1 over the floor, no flicker)
		, Color3.fromRGB(52, 54, 60), Enum.Material.Concrete)
	Finish.apply(mat, "Rubber")
	local yellow = Color3.fromRGB(206, 172, 58) -- (V9-NOW 18: a painted mustard line, not a glowing yellow)
	-- (Each layer a clear step above the one under it, so none of them flickers.)
	paint(folder, "ZoneEdge", Vector3.new(42, 0.06, 0.6), Vector3.new(o.X, ground + 0.22, rowZ - 8), yellow)
	paint(folder, "ZoneEdge", Vector3.new(0.6, 0.06, 16), Vector3.new(o.X - 21, ground + 0.22, rowZ), yellow)
	paint(folder, "ZoneEdge", Vector3.new(0.6, 0.06, 16), Vector3.new(o.X + 21, ground + 0.22, rowZ), yellow)
	for i = 0, 13 do -- hazard stripes along its front edge
		paint(folder, "Hazard", Vector3.new(1.5, 0.06, 1.6), Vector3.new(o.X - 19.5 + i * 3, ground + 0.22, rowZ + 8), if i % 2 == 0 then yellow else Color3.fromRGB(24, 24, 28))
	end
	end
	-- The crash wall behind the row, a workbench either side of it.
	if (Config :: any).TARGET_BLOCKS then
		targetBlocks(folder, Vector3.new(o.X, ground, o.Z - 74 * S), ground)
	else
		prop(folder, "CrashWall", Vector3.new(o.X, ground, o.Z - 74 * S), Vector3.new(0, 0, 1), 28)
	end
	for _, x in { -22, 22 } do
		prop(folder, "LabBench", Vector3.new(o.X + x, ground, o.Z - 76 * S), Vector3.new(0, 0, 1), 9)
	end
	-- Barriers and cones down each side edge.
	for _, side in { -1, 1 } do
		local x = o.X + side * 76 * S
		for i = 0, 3 do
			local z = o.Z + (-60 + i * 34) * S
			prop(folder, "Barrier", Vector3.new(x, ground, z), Vector3.new(-side, 0, 0), 7)
			prop(folder, "Cone", Vector3.new(x - side * 2, ground, z + 9), Vector3.new(-side, 0, 0), 2.6)
		end
	end
end

local function signText(owner: Player?): string
	if not owner then
		return "FREE LAB"
	end
	return (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MachineNames")) :: any).labOf(owner.DisplayName) -- (V8-2.8: "JONAS' LAB")
end

-- Which way an avatar faces at the lab's spawn (V8-0.4: 50 degrees right of -Z, towards the cannon; T112 measured the cannon at 42 degrees and the middle dummies at -37..-19 in the follow camera, inside 1920x1080 (49) and a landscape phone (55)).
-- (0.37.3: 45 degrees: the spider ahead-left, the wrecking ball ahead, the cannon to the right.)
Lab.SPAWN_FACING = if Config.V8_ONE_VOICE then Vector3.new(math.sin(math.rad(45)), 0, -math.cos(math.rad(45))) else -Vector3.zAxis

local function placeOnPlot(player: Player, plot: Plot)
	local character = player.Character
	if not character then
		return
	end
	local at = plot.origin + Vector3.new(math.random() * 4 - 2, 3.5, math.random() * 2 - 1)
	-- (V8-0.4: turned 50 degrees towards the cannon, which sat 82-97 degrees right of the spawn camera:
	-- the dummies in the middle and the cannon both in view on PC, tablet and a landscape phone; T112.)
	character:PivotTo(CFrame.lookAt(at, at + Lab.SPAWN_FACING))
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function claim(player: Player)
	if plotOf[player] then
		return
	end
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.roamStarted = true -- all 18 begin walking as soon as the player enters
			if player:GetAttribute("V8JoinedAt") == nil then
				player:SetAttribute("V8JoinedAt", Workspace:GetServerTimeNow()) -- (V8-0.2: the calm first minute counts from here)
			end
			plot.generation += 1
			plotOf[player] = plot
			if not plot.built and playgroundBuilder then
				plot.built = true
				;(playgroundBuilder :: (Vector3, string) -> ())(plot.origin, "Lab" .. plot.index)
			end
			local playground = Workspace:FindFirstChild("Playground")
			local own = playground and playground:FindFirstChild("Lab" .. plot.index)
			if own then
				own:SetAttribute("Paused", nil)
			end
			if plot.sign then
				plot.sign.Text = signText(player)
			end
			plot.folder:SetAttribute("Owner", player.UserId)
			player:SetAttribute("LabPlot", plot.index)
			player:SetAttribute("LabOrigin", plot.origin)
			player:SetAttribute("LabFocus", focusOf(plot.origin))
			local generation = plot.generation
			for _, slot in plot.slots do
				fill(plot, slot, generation)
			end
			log.info(string.format("%s has lab %d", player.Name, plot.index))
			return
		end
	end
	-- Every lab taken: this player lives in the plaza.
	player:SetAttribute("LabPlot", nil)
	player:SetAttribute("LabOrigin", worldOrigin)
	player:SetAttribute("LabFocus", focusOf(worldOrigin))
	log.info(player.Name .. " has no lab (all " .. Lab.PLOT_COUNT .. " taken)")
end

-- A lab came free: the first player still living in the plaza gets it (told by a toast; their
-- build moves into it).
local function handOn(leaving: Player?)
	for _, other in Players:GetPlayers() do
		if other ~= leaving and other.Parent and not plotOf[other] then
			claim(other)
			local plot = plotOf[other]
			if plot then
				for _, moved in Lab.onMoved do
					task.spawn(moved, other)
				end
				Net.event(Net.Names.Travel):FireClient(other, "LabReady", plot.index)
			end
			return
		end
	end
end

-- Empties a lab: its dummies go, its sign says FREE LAB.
local function freePlot(plot: Plot)
	plot.owner = nil
	plot.generation += 1
	for _, slot in plot.slots do
		local model = slot.model
		slot.model = nil
		if model and model.Parent then
			model:Destroy()
		end
	end
	if plot.sign then
		plot.sign.Text = signText(nil)
	end
	plot.folder:SetAttribute("Owner", nil)
	local playground = Workspace:FindFirstChild("Playground")
	local own = playground and playground:FindFirstChild("Lab" .. plot.index)
	if own then
		own:SetAttribute("Paused", true) -- (its wrecking ball rests)
	end
end

local function release(player: Player)
	local plot = plotOf[player]
	plotOf[player] = nil
	if plot then
		freePlot(plot)
		task.defer(handOn, player)
	end
end

------------------------------------------------------------------------------------------------
-- Asking about labs

-- The plot a player owns (nil: none, they live in the plaza).
function Lab.plotIndex(player: Player): number?
	local plot = plotOf[player]
	return if plot then plot.index else nil
end

-- Where a player's lab is (the plaza's middle when they have none).
function Lab.originFor(player: Player): Vector3
	local plot = plotOf[player]
	return if plot then plot.origin else worldOrigin
end

-- The middle of a player's dummy row (where the lab camera looks and events land).
function Lab.focusFor(player: Player): Vector3
	return focusOf(Lab.originFor(player))
end

-- The plaza's middle and the middle of its open floor.
function Lab.plazaOrigin(): Vector3
	return worldOrigin
end
function Lab.plazaFocus(): Vector3
	return focusOf(worldOrigin)
end

-- Who owns plot i (nil: free or no such plot).
function Lab.ownerOf(index: number): Player?
	local plot = plots[index]
	return if plot then plot.owner else nil
end

-- Which part of the ground a point is in: "Lab" with the plot (and its owner, if any), or "Plaza".
-- Nil when the point is not on the ground (up in the rooms).
function Lab.zoneAt(position: Vector3): (string?, number?, Player?)
	if position.Y > worldOrigin.Y + Lab.GROUND_TOP then
		return nil, nil, nil
	end
	local index = Zones.plotAt(position) -- (the same answer on every screen)
	local plot = if index and index > 0 then plots[index] else nil
	if not plot then
		return "Plaza", nil, nil
	end
	return "Lab", index :: number, plot.owner
end

-- The owner of the lab a point is in (nil in the plaza, a free lab or up in the rooms).
function Lab.ownerAt(position: Vector3): Player?
	local _, _, owner = Lab.zoneAt(position)
	return owner
end

-- Puts every dummy of a player's lab that was knocked about back on its slot (a Workshop Stop
-- rewinds the whole scene, so the next run starts the same way). Dummies still standing where they
-- belong stay put.
function Lab.rewind(player: Player): number
	local plot = plotOf[player]
	if not plot then
		return 0
	end
	local count = 0
	for _, slot in plot.slots do
		local model = slot.model
		local pelvis = model and model.Parent and model:FindFirstChild("LowerTorso") :: BasePart?
		-- (Round 4, M10: a dead one stays where it died, uncounted; VitalsService takes it at DEAD_HOLD.)
		if model and pelvis and model:GetAttribute("Vital") ~= "Dead" then
			local flat = Vector3.new(pelvis.Position.X - slot.position.X, 0, pelvis.Position.Z - slot.position.Z)
			if flat.Magnitude > 1.5 or model:GetAttribute("RagdollState") ~= "Standing" then
				slot.awayTime = 0
				returnHome(plot, slot, model)
				count += 1
			end
		end
	end
	return count
end

-- A player's own lab dummies (tests, and whoever needs them).
function Lab.dummiesOf(player: Player): { Model }
	local list = {}
	local plot = plotOf[player]
	for _, slot in if plot then plot.slots else {} do
		if slot.model and slot.model.Parent then
			table.insert(list, slot.model)
		end
	end
	return list
end

-- Sends a player's avatar to their own lab (the Maps window's "My Lab", and every spawn).
function Lab.sendHome(player: Player): boolean
	local plot = plotOf[player]
	if not plot then
		return false
	end
	placeOnPlot(player, plot)
	return true
end

-- Told when a player gets a lab later than when they joined (one came free): BuildService moves
-- their build there.
Lab.onMoved = {} :: { (player: Player) -> () }

-- Tests: a player giving their lab back (as leaving does, but staying: they live in the plaza).
function Lab.releaseForTest(player: Player)
	local plot = plotOf[player]
	plotOf[player] = nil
	if plot then
		freePlot(plot)
		player:SetAttribute("LabPlot", nil)
		player:SetAttribute("LabOrigin", worldOrigin)
		player:SetAttribute("LabFocus", focusOf(worldOrigin))
	end
end
function Lab.handOnForTest()
	handOn(nil)
end

-- The plaza's playground and every lab's are built by Playground (it sits on PlayerRagdoll, which
-- sits on this): Main hands its builder over.
function Lab.setPlaygroundBuilder(builder: (origin: Vector3, name: string) -> ())
	playgroundBuilder = builder
	for _, plot in plots do
		if plot.owner and not plot.built then
			plot.built = true
			builder(plot.origin, "Lab" .. plot.index)
		end
	end
end

function Lab.build()
	worldOrigin = spawnOrigin()
	-- The spawn only says where the plaza is. Its pad would sit in the middle of the open floor (and
	-- catch build and grab rays), so it disappears; players are moved onto their own lab's floor.
	local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnLocation then
		for _, d in spawnLocation:GetChildren() do
			if d:IsA("Decal") or d:IsA("Texture") then
				d:Destroy()
			end
		end
		spawnLocation.Transparency = 1
		spawnLocation.CanCollide = false
		spawnLocation.CanQuery = false
		spawnLocation.CastShadow = false
	end
	-- The plaza's middle (places, crowd, horde and the shared playground are laid out from it).
	Workspace:SetAttribute("LabOrigin", worldOrigin)
	Workspace:SetAttribute("LabFocus", focusOf(worldOrigin))
	Workspace:SetAttribute("LabSpacing", Lab.PLOT_SPACING)
	labsFolder = Instance.new("Folder")
	labsFolder.Name = "Labs"
	for i = 1, Lab.PLOT_COUNT do
		local folder = Instance.new("Folder")
		folder.Name = "Lab" .. i
		folder:SetAttribute("Plot", i)
		local plot: Plot = { index = i, origin = Lab.plotCenter(i), owner = nil, slots = {}, folder = folder, sign = nil, built = false, generation = 0 }
		folder:SetAttribute("Origin", plot.origin)
		for s = 1, DUMMY_COUNT do
			table.insert(plot.slots, { index = s, position = slotPosition(plot.origin, s), lastPosition = slotPosition(plot.origin, s), model = nil, awayTime = 0, bestDistance = 0, restTime = 0, fleeTime = 0, downTime = 0, excusedTime = 0, homeY = 0, homeAttr = nil, homeLook = nil, target = nil, socialUntil = 0, socialKind = nil, nextSocialAt = 0, scaredAt = -math.huge, roamHome = nil, nextRoamAt = 0 })
		end
		markPlot(plot)
		dressPlot(plot)
		folder.Parent = labsFolder
		table.insert(plots, plot)
	end
	labsFolder.Parent = Workspace
	FxService.onMoment(heard)
	task.spawn(function()
		while true do
			watch(task.wait(0.25))
		end
	end)
	log.info(string.format("%d labs of %d dummies laid out", Lab.PLOT_COUNT, DUMMY_COUNT))

	local function onJoin(player: Player)
		claim(player)
		-- Every avatar starts in its own lab (the plaza when there is none).
		player.CharacterAdded:Connect(function(character)
			local plot = plotOf[player]
			if plot then
				task.defer(function()
					if player.Character == character and plotOf[player] == plot then
						placeOnPlot(player, plot)
					end
				end)
			end
		end)
		if player.Character and plotOf[player] then
			placeOnPlot(player, plotOf[player])
		end
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		onJoin(player)
	end
	Players.PlayerRemoving:Connect(release)
end

return Lab
