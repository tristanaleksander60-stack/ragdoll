--!strict
-- Blood, pulse and wounds (round 2, N2). Every dummy and person has its body's blood (100%) and a
-- resting pulse; a hit opens a wound where it landed (Anatomy: the organ or zone under the point),
-- which costs some blood at once and keeps bleeding (organs until the body is patched up, limbs
-- until they clot). The heart answers: it races as blood runs out, slows when it is hit itself, and
-- stops at the end. Below 45% the body is out cold, at 15% (or with the heart stopped) it is dead.
--
-- The server keeps the truth and shares it as attributes on the model, so every screen shows the
-- same: Blood (whole %), Pulse (bpm), Vital ("Alive" | "Unconscious" | "Dead") and Wounds (the last
-- few: "Zone@servertime;..."), which the doctor's monitor (N3) reads. Whoever made the hit gets a
-- short line back: "Left lung · 97% blood · pulse 118" (HitInfo).
--
-- Blunt blows (a slap, a punch, a bat) bruise: the wound bleeds a little for BLUNT_CLOT seconds,
-- however hard the blow, and blows alone never take a body under BRUISE_FLOOR (so never out cold
-- or dead from blood); they move the pulse only a little and never stop the heart; a blow to the
-- head can knock a body out (it wakes) but never reaches the brain. Only rounds, bolts, blades and
-- blasts open wounds that keep bleeding or kill.
--
-- A body with no open wound slowly makes up its blood. One out cold for a while is patched up where
-- it lies; a dead one (or one missing a limb, Config.SEVERING) goes in a puff after a moment and
-- its place (lab, crowd) brings a new one, as for any body lost.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Anatomy = require(Shared.Anatomy)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Log = require(Shared.Log)

local DummyControl = require(script.Parent.DummyControl)
local FxService = require(script.Parent.FxService)

local log = Log.new("Vitals")

local VitalsService = {}

local TICK = 0.25
local PULSE_EASE = 30 -- bpm a second the pulse moves towards where it is heading
local SHOCK_FADE = 25 -- s a wound's push on the pulse lasts
local REGEN = 0.6 -- % blood a second with no open wound
local OUT_HOLD = 18 -- s out cold (from blood loss) before the body is patched up where it lies
local KNOCK_HOLD = 5 -- s out cold from a head or spine hit
local BLUNT_CLOT = 2.5 -- s a bruise bleeds, however hard the blow (it never grows with the power)
local BRUISE_FLOOR = 50 -- % blood: blows alone never take a body under this (out cold is 45)
local BLUNT_BLEED = 0.5 -- a bruise bleeds this much of what an open wound would
local BLUNT_KNOCKOUT = 1 -- power a blunt blow needs to knock a body out (a sharp one: 0.6)
local BLUNT_SHOCK = 0.25 -- a blow moves the pulse this much of what a wound there would
local BLUNT_FLOOR = 0.35 -- blows together slow the pulse by at most this share of its rest (never stop it)

-- Where a wound lands when the server's line from the hitter to the spot was blocked (a build or a
-- wall in the way: HitService): the spot stands, but never one that kills or bleeds out fast; the
-- tissue next to it takes the wound instead.
local GUARDED: { [string]: string } = {
	Brain = "Skull",
	Neck = "Jaw",
	Heart = "LeftLung",
	Aorta = "RightLung",
	LeftFemoral = "LeftThigh",
	RightFemoral = "RightThigh",
}
local DEAD_HOLD = 60 -- s a dead body lies still before it goes (round 4, M10: 60 s, up from 30)
VitalsService.DEAD_HOLD = DEAD_HOLD
local INSTANT_LETHAL_POWER = 0.6 -- a blade or better to the brain: dead this update (round 4, M10)
local HEADSHOT = Anatomy.HEADSHOT -- a gun round there: dead this update, whatever its power
local MAX_WOUNDS = 8 -- kept on the model (the monitor's list)
local INFO_GAP = 0.08 -- s: at most this often a line to one player (a shotgun's pellets: one line)

-- Every round, bolt or blade that lands weakens the heart a little for good (round 3, M2: the
-- owner's rule, the pulse falls with every hit and more for the head), until the body is patched
-- up: DROP_PER_LOSS bpm for each % of blood the zone costs at once, HEAD_MORE times that for the
-- head and neck (which also bleed HEAD_MORE_BLOOD times as much at once), never under DROP_MIN.
-- Enough of them stop it (Anatomy.DEAD_PULSE): bodies die from being shot often enough.
local DROP_PER_LOSS = 2.5
local DROP_MIN = 3
local DROP_MAX = 40
local HEAD_MORE = 2
local HEAD_MORE_BLOOD = 1.5
local HEAD_ZONES = Anatomy.HEAD_ZONES
VitalsService.HEAD_ZONES = HEAD_ZONES

type Wound = { zone: Anatomy.Zone, at: number, opened: number, power: number, blunt: boolean?, drop: number? }
type Vitals = {
	blood: number,
	pulse: number,
	rest: number,
	wounds: { Wound },
	state: string,
	since: number, -- os.clock the state began
	knockUntil: number,
	lethalAt: number?,
	severed: { [string]: boolean },
	shared: string?, -- the wound list as last shared (Wounds)
	weak: number, -- bpm every round so far took off the pulse for good (only patching up resets it)
	ceiling: number?, -- after a round: the pulse never climbs above where that round left it
	damage: number?, -- v4 A5: hits so far (Config.BODY_HP of it kills); patching up clears it
}

local vitals: { [Model]: Vitals } = {}
local infoRemote: RemoteEvent? = nil
local lastInfo: { [Player]: number } = {}
-- The last line each player was sent (tests read it; the client only gets the remote).
VitalsService.lastSent = {} :: { [Player]: { line: string, killed: boolean } }
local rng = Random.new()

-- During the self-tests bodies keep their blood and pulse but never go down from them (the older
-- tests hit the same dummies over and over and want them standing), and nothing is cut off,
-- unless a test asks.
local quietInTests = true
local function quiet(): boolean
	local storage = game:GetService("ServerStorage")
	-- (ServerStorage's LabLive: looking at it by hand after a run, as for the lab's dummies.)
	-- (Studio only: a place saved with RunSelfTest on never quiets a live server.)
	return quietInTests
		and RunService:IsStudio()
		and storage:GetAttribute("RunSelfTest") == true
		and storage:GetAttribute("LabLive") ~= true
end
function VitalsService.liveForTest(on: boolean)
	quietInTests = not on
end


local function publish(model: Model, v: Vitals, bleeding: boolean?)
	model:SetAttribute("Blood", math.clamp(math.floor(v.blood + 0.5), 0, 100))
	model:SetAttribute("Pulse", math.floor(v.pulse + 0.5))
	model:SetAttribute("Vital", v.state)
	if bleeding ~= nil then
		-- (Every screen drips purple from a body that is bleeding: BloodFx.)
		model:SetAttribute("Bleeding", bleeding or nil)
	end
end

-- Whether a wound still bleeds.
local function bleeds(w: Wound, now: number): boolean
	local age = now - w.opened
	if w.blunt then
		return age < BLUNT_CLOT
	end
	return not w.zone.stops or age < (w.zone.stops :: number) * math.max(w.power, 0.3)
end

-- The wounds every screen sees (the monitor's list, Anatomy.parseWounds): at most MAX_WOUNDS, in the
-- order they came, "Zone@servertime" with flags: b a blow (a bruise), o still bleeding. When there
-- are more, the ones that matter stay, newest first in each group: a big vessel still bleeding;
-- another wound (not a blow) still bleeding or a shot lung (it costs breath until the body is
-- patched up); then a bruise still bleeding; then the rest.
local function encodeWounds(v: Vitals, now: number): string
	local function group(w: Wound): number
		local lung = w.zone.id == "LeftLung" or w.zone.id == "RightLung"
		local open = bleeds(w, now)
		if not w.blunt and open and w.zone.bleed >= Anatomy.MAJOR_BLEED then
			return 1 -- a big vessel still bleeding: never pushed out by newer wounds
		elseif not w.blunt and (lung or open) then
			return 2
		elseif open then
			return 3
		end
		return 4
	end
	local keep: { [number]: boolean } = {}
	local count = 0
	for pass = 1, 4 do
		for i = #v.wounds, 1, -1 do
			if count >= MAX_WOUNDS then
				break
			end
			if not keep[i] and group(v.wounds[i]) <= pass then
				keep[i] = true
				count += 1
			end
		end
	end
	local parts = {}
	for i, w in v.wounds do
		if keep[i] then
			local flags = (if w.blunt then "b" else "") .. (if bleeds(w, now) then "o" else "")
			table.insert(parts, string.format("%s@%d%s", w.zone.id, math.floor(w.at), flags))
		end
	end
	return table.concat(parts, ";")
end

-- Shares the list when it changed (a new wound, or one that stopped bleeding).
local function shareWounds(model: Model, v: Vitals, now: number)
	local text = encodeWounds(v, now)
	if text ~= v.shared then
		v.shared = text
		model:SetAttribute("Wounds", text)
	end
end

local function vitalsOf(model: Model): Vitals
	local v = vitals[model]
	if v then
		return v
	end
	local rest = rng:NextInteger(66, 84)
	local new: Vitals = { blood = 100, pulse = rest, rest = rest, wounds = {}, state = "Alive", since = os.clock(), knockUntil = 0, lethalAt = nil, severed = {}, weak = 0, ceiling = nil }
	vitals[model] = new
	model.Destroying:Once(function()
		vitals[model] = nil
	end)
	publish(model, new)
	return new
end

-- cause (dead only): "Brain" for a kill on the spot (round 4, M10: the monitor is flat at once,
-- Anatomy.stoppedFor); nil for a heart that gave out (it fibrillates first).
local function setState(model: Model, v: Vitals, state: string, cause: string?)
	if v.state == state then
		return
	end
	v.state = state
	v.since = os.clock()
	-- (When the heart stopped, server time: the monitor shows it fibrillate a moment, then flat.)
	model:SetAttribute("DiedAt", if state == "Dead" then Workspace:GetServerTimeNow() else nil)
	model:SetAttribute("DeathCause", if state == "Dead" then cause else nil)
	-- (The machine that simulates the body sees Vital: not Alive, it goes limp and stays down.)
	publish(model, v)
end

-- Patched up where it lies: full blood, no wounds, awake (it gets up by itself).
-- quiet: no sparkle here (the Heal tool plays its own where it was used).
local function patchUp(model: Model, v: Vitals, quiet: boolean?)
	v.blood = 100
	v.pulse = v.rest
	table.clear(v.wounds)
	v.weak = 0
	v.ceiling = nil
	v.damage = 0
	v.lethalAt = nil
	v.knockUntil = 0
	v.shared = ""
	model:SetAttribute("Wounds", "")
	model:SetAttribute("LegShotLeft", nil) -- (patched up: no leg round counts any more)
	model:SetAttribute("LegShotRight", nil)
	model:SetAttribute("Damage", nil)
	setState(model, v, "Alive")
	publish(model, v, false)
	DummyControl.heal(model)
	local pelvis = model:FindFirstChild("LowerTorso")
	if not quiet and pelvis and pelvis:IsA("BasePart") then
		FxService.hit(pelvis.Position + Vector3.new(0, 1, 0), 0, "Heal")
	end
end

-- Puts cut-off limbs back where they belong (the Heal tool: good as new). Each limb is moved so its
-- joint meets the body again before the joint holds it.
-- A limb that is gone (fell out of the world) stays off.
local function reattach(model: Model, v: Vitals)
	local back: { string } = {}
	for limb in v.severed do
		local spec = Anatomy.LIMBS[limb]
		local first = model:FindFirstChild(spec.parts[1])
		local body = model:FindFirstChild(if string.find(limb, "Leg") then "LowerTorso" else "UpperTorso")
		if first and first:IsA("BasePart") and body and body:IsA("BasePart") then
			local mine = first:FindFirstChild(spec.joint .. "RigAttachment")
			local theirs = body:FindFirstChild(spec.joint .. "RigAttachment")
			if not (mine and mine:IsA("Attachment") and theirs and theirs:IsA("Attachment")) then
				continue
			end
			do
				local move = (theirs.WorldCFrame * mine.CFrame:Inverse()) * first.CFrame:Inverse()
				for _, name in spec.parts do
					local p = model:FindFirstChild(name)
					if p and p:IsA("BasePart") then
						p.CFrame = move * p.CFrame
						p.AssemblyLinearVelocity = Vector3.zero
						p.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
			for _, d in first:GetChildren() do
				if d:IsA("Constraint") and (d.Name == spec.joint or d.Name == spec.joint .. "BallSocket") then
					d.Enabled = true
				end
			end
			for _, holder in { first, body } do
				for _, cap in holder:GetChildren() do
					if cap.Name == "Stump" and cap:GetAttribute("Limb") == limb then
						cap:Destroy()
					end
				end
			end
			table.insert(back, limb)
		end
	end
	for _, limb in back do
		v.severed[limb] = nil
	end
	local left = {}
	for name in v.severed do
		table.insert(left, name)
	end
	table.sort(left)
	model:SetAttribute("Severed", if #left > 0 then table.concat(left, ",") else nil)
end

-- The Heal tool: every wound closed, the blood back, cut-off limbs put back, and awake. Returns
-- false for a dead body (round 4, M10: too late, nothing brings it back; it lies its DEAD_HOLD).
function VitalsService.heal(model: Model): boolean
	local v = vitals[model]
	if not v then
		DummyControl.heal(model)
		return true
	end
	if v.state == "Dead" then
		return false
	end
	if next(v.severed) ~= nil then
		reattach(model, v)
	end
	if next(v.severed) ~= nil then
		-- A limb could not come back (it is gone): the bleeding stops, but the body stays down.
		v.blood = 100
		table.clear(v.wounds)
		v.weak = 0
		v.ceiling = nil
		v.lethalAt = nil
		v.shared = ""
		model:SetAttribute("Wounds", "")
		publish(model, v, false)
		return true
	end
	patchUp(model, v, true)
	return true
end

-- Cuts a limb off at its joint (heavy weapons and close blasts, when Config.SEVERING is on). The
-- limb falls loose; the body is down for good (it goes after a moment, and a new one comes).
function VitalsService.sever(model: Model, limb: string, position: Vector3?): boolean
	-- (Not on an ice statue: its limbs are welded to it, and the thaw would put the cut one back.)
	if not Config.SEVERING or quiet() or model:GetAttribute("Frozen") == true then
		return false
	end
	local spec = Anatomy.LIMBS[limb]
	local v = vitalsOf(model)
	if not spec or v.severed[limb] then
		return false
	end
	local first = model:FindFirstChild(spec.parts[1])
	if not first then
		return false
	end
	local cut = false
	for _, d in first:GetChildren() do
		if d:IsA("Constraint") and (d.Name == spec.joint or d.Name == spec.joint .. "BallSocket") then
			d.Enabled = false
			cut = true
		end
	end
	if not cut then
		return false
	end
	-- Purple caps on both sides of the cut (welded on, weightless, never in the way).
	local socket = first:FindFirstChild(spec.joint .. "RigAttachment")
	if socket and socket:IsA("Attachment") then
		local body = model:FindFirstChild(if string.find(limb, "Leg") then "LowerTorso" else "UpperTorso")
		for _, holder in { first, body } do
			if holder and holder:IsA("BasePart") then
				local cap = Instance.new("Part")
				cap.Name = "Stump"
				cap:SetAttribute("Limb", limb)
				cap.Shape = Enum.PartType.Cylinder
				cap.Size = Vector3.new(0.18, 0.9, 0.9)
				cap.Color = Anatomy.BLOOD
				cap.Material = Enum.Material.SmoothPlastic
				cap.CanCollide = false
				cap.CanQuery = false
				cap.CanTouch = false
				cap.Massless = true
				cap.CastShadow = false
				cap.CFrame = CFrame.lookAt(socket.WorldPosition, socket.WorldPosition + (holder.Position - socket.WorldPosition)) * CFrame.Angles(0, math.rad(90), 0)
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = holder
				weld.Part1 = cap
				weld.Parent = cap
				cap.Parent = holder
			end
		end
	end
	v.severed[limb] = true
	local list = {}
	for name in v.severed do
		table.insert(list, name)
	end
	table.sort(list)
	model:SetAttribute("Severed", table.concat(list, ","))
	-- A stump: the big artery there (a leg's femoral; an arm's axillary, at the shoulder).
	local side = if string.find(limb, "Left") then "Left" else "Right"
	local zone = Anatomy.zones[side .. (if string.find(limb, "Leg") then "Femoral" else "ArmStump")]
	table.insert(v.wounds, { zone = zone, at = Workspace:GetServerTimeNow(), opened = os.clock(), power = 1 })
	v.blood -= 8
	shareWounds(model, v, os.clock())
	-- A leg off: it cannot stand. An arm off (round 3, M3 rule from the owner: an arm never puts a
	-- body down on its own): it stays up, bleeding hard, until the blood decides.
	if v.state == "Alive" and string.find(limb, "Leg") then
		setState(model, v, "Unconscious")
	end
	local at = position or ((first :: BasePart).Position)
	FxService.hit(at, 70, "Sever")
	return true
end

-- A hit on a body: opens a wound on what is under the point. Returns the line for the hitter (and
-- the zone), or nil when it was no body.
-- power: how hard the wound is (Toys: wound; 1 = a pistol round).
local MAX_KEPT = 24 -- wounds kept per body

-- At most MAX_KEPT wounds. What goes first: the oldest that no longer bleeds, then the oldest blow,
-- and only then the oldest wound; so a flurry of pokes never pushes out the open wound that is
-- killing the body.
local function trimWounds(v: Vitals, now: number)
	while #v.wounds > MAX_KEPT do
		local drop: number? = nil
		for i, w in v.wounds do
			if not bleeds(w, now) then
				drop = i
				break
			end
		end
		if not drop then
			for i, w in v.wounds do
				if w.blunt then
					drop = i
					break
				end
			end
		end
		table.remove(v.wounds, drop or 1)
	end
end

-- options:
--   sever    the chance a hit on a limb cuts it off (Toys: sever)
--   zone     the zone, whatever is under the point (a blast)
--   blunt    a blow, not a round or a blade: it bruises and clots, moves the pulse a little, and
--            never reaches the brain
--   guarded  the server could not see the spot from the hitter (HitService): no zone that kills
--            or bleeds out fast (GUARDED)
--   round    a gun's round (Toys: gun): any of it to the head kills at once (HEADSHOT)
export type WoundOptions = { sever: number?, zone: Anatomy.Zone?, blunt: boolean?, guarded: boolean?, round: boolean? }
function VitalsService.wound(model: Model, part: BasePart, position: Vector3, by: Player?, power: number, options: WoundOptions?): (string?, Anatomy.Zone?)
	local o: WoundOptions = options or {}
	local blunt = o.blunt == true
	local severChance = o.sever
	local zone = o.zone or Anatomy.zoneAt(part.Name, part.CFrame:PointToObjectSpace(position), part.Size)
	if not zone then
		return nil, nil
	end
	if o.guarded and GUARDED[zone.id] then
		zone = Anatomy.zones[GUARDED[zone.id]]
	end
	if blunt and zone.lethal then
		-- A blow to the top of the head: the skull takes it.
		zone = Anatomy.zones.Skull
	end
	local v = vitalsOf(model)
	local before = v.pulse
	local wasDead = v.state == "Dead"
	local now = os.clock()
	local head = HEAD_ZONES[zone.id] == true
	-- (Not for the heart and the brain: they slow the heart their own way, Anatomy's pulse push.)
	local drop = if blunt or zone.pulse < 0 then nil else math.clamp(zone.loss * power * DROP_PER_LOSS * (if head then HEAD_MORE else 1), DROP_MIN, DROP_MAX)
	table.insert(v.wounds, { zone = zone, at = Workspace:GetServerTimeNow(), opened = now, power = power, blunt = blunt, drop = drop })
	trimWounds(v, now)
	if v.state ~= "Dead" then
		if blunt then
			-- (A blow costs a little blood, never past BRUISE_FLOOR.)
			v.blood = math.max(math.min(v.blood, BRUISE_FLOOR), v.blood - zone.loss * power * BLUNT_BLEED)
		else
			v.blood = math.max(0, v.blood - zone.loss * power * (if head then HEAD_MORE_BLOOD else 1))
			-- The pulse falls at once (the line shows it), and stays down (step: weak).
			v.pulse = math.max(0, v.pulse - (drop or 0))
			v.weak += drop or 0
			-- (From here the pulse only falls until the body is patched up: every round leaves it lower.)
			v.ceiling = math.min(v.ceiling or math.huge, v.pulse)
		end
		-- Round 4, M10: dead in this same update (no Alive frame, the monitor flat at once: DeathCause)
		-- from any gun round to the head (HEADSHOT; not the neck, not through a wall: guarded) or a
		-- blade's worth to the brain (a graze is not). The blood stays what the wound left. A blow
		-- never gets here (the brain was swapped to Skull above). (Quiet self-tests never kill: the
		-- older tests hit the same dummies over and over.)
		local headshot = o.round == true and not o.guarded and HEADSHOT[zone.id] == true
		if not quiet() and not blunt and (headshot or (zone.lethal and power >= INSTANT_LETHAL_POWER)) then
			v.pulse = 0
			v.lethalAt = now -- (already past: the step loop treats it as pending-dead)
			setState(model, v, "Dead", "Brain")
		end
		-- v4 A5 (owner): enough hits kill, body shots and blows too (headshots stay instant, above).
		-- Region and weapon set the share; the body shows it as today (knocked out, dead green, revive).
		if v.state ~= "Dead" then
			local region = if head then Config.DAMAGE_HEAD elseif zone.limb then Config.DAMAGE_LIMB else 1
			v.damage = (v.damage or 0) + power * Config.DAMAGE_PER_POWER * region * (if blunt then Config.DAMAGE_BLUNT else 1)
			model:SetAttribute("Damage", math.floor(v.damage :: number))
			if not quiet() and (v.damage :: number) >= Config.BODY_HP then
				v.pulse = 0
				v.lethalAt = now
				setState(model, v, "Dead", "Wounds")
			end
		end
		if zone.knockout and power >= (if blunt then BLUNT_KNOCKOUT else 0.6) then
			v.knockUntil = math.max(v.knockUntil, now + KNOCK_HOLD)
		end
	end
	shareWounds(model, v, os.clock())
	-- A limb off (heavy weapons): the chance comes with the weapon (Toys: sever).
	local severed: string? = nil
	if severChance and severChance > 0 and zone.limb and rng:NextNumber() < severChance then
		if VitalsService.sever(model, zone.limb, position) then
			severed = zone.limb
		end
	end
	VitalsService.step(model, v, 0)
	local label = if severed then (Anatomy.LIMBS[severed :: string].label .. " severed")
		elseif Config.MILD_TEXT then Anatomy.mildLabel(zone.id) -- (phase 0: a body region, no organs)
		else zone.label
	local line = string.format("%s \u{00B7} %d%% blood \u{00B7} %s", label, math.floor(v.blood + 0.5), if v.state == "Dead" then "no pulse" else "pulse " .. math.floor(v.pulse + 0.5))
	local killedNow = not wasDead and v.state == "Dead"
	-- (Round 4, M10: the line for the hit that killed is never held back by INFO_GAP.)
	if by and infoRemote and (killedNow or now - (lastInfo[by] or -math.huge) >= INFO_GAP) then
		lastInfo[by] = now
		-- (The pulse before the hit too: the line shows which way it went.)
		-- (And whether this very wound killed: the hitter's crosshair shows its kill mark.)
		;(infoRemote :: RemoteEvent):FireClient(by, line, model, math.floor(before + 0.5), zone.id, killedNow)
		VitalsService.lastSent[by] = { line = line, killed = killedNow }
	end
	return line, zone
end

-- One step of a body's vitals (dt s).
function VitalsService.step(model: Model, v: Vitals, dt: number)
	local now = os.clock()
	local bleed = 0 -- open wounds (rounds, blades, blasts)
	local bruise = 0 -- blows: a short bleed that stops at BRUISE_FLOOR
	local shock = 0
	local bluntShock = 0
	local weak = v.weak -- bpm the rounds that landed took off for good (DROP_PER_LOSS; kept as a total, so trimming old wounds never gives it back)
	for _, w in v.wounds do
		local age = now - w.opened
		if w.blunt then
			if age < BLUNT_CLOT then
				bruise += w.zone.bleed * w.power * BLUNT_BLEED
			end
		elseif not w.zone.stops or age < (w.zone.stops :: number) * math.max(w.power, 0.3) then
			bleed += w.zone.bleed * w.power
		end
		if age < SHOCK_FADE then
			local push = w.zone.pulse * math.min(w.power, 1.2) * (1 - age / SHOCK_FADE)
			if w.blunt then
				bluntShock += push * BLUNT_SHOCK
			elseif push < 0 then
				shock += push -- (a round in the heart or the brain: it slows on top of the drop)
			end
		end
	end
	if v.state == "Dead" then
		v.pulse = math.max(0, v.pulse - PULSE_EASE * 2 * dt)
		publish(model, v, false)
		return
	end
	if bruise > 0 and v.blood <= BRUISE_FLOOR then
		bruise = 0 -- (blows alone go no further)
	end
	if bleed > 0 or bruise > 0 then
		v.blood = math.max(0, v.blood - bleed * dt)
		if bruise > 0 then
			v.blood = math.max(math.min(v.blood, BRUISE_FLOOR), v.blood - bruise * dt)
		end
	elseif v.state == "Alive" then
		v.blood = math.min(100, v.blood + REGEN * dt)
	end
	local bleeding = bleed > 0 or bruise > 0
	shareWounds(model, v, now)
	-- (Blows on their own never stop a heart: they slow it by at most BLUNT_FLOOR of its rest.)
	local target = Anatomy.pulseFor(v.rest, v.blood) + math.clamp(shock, -v.rest, 70) + math.clamp(bluntShock, -v.rest * BLUNT_FLOOR, 30) - weak
	if v.lethalAt then
		target = 0
	end
	if v.ceiling then
		target = math.min(target, v.ceiling)
	end
	target = math.clamp(target, 0, 210)
	local step = PULSE_EASE * (if v.lethalAt then 3 else 1) * dt
	if dt == 0 then
		-- A fresh hit shows at once in the line (a jump of a few beats).
		step = math.abs(target - v.pulse) * 0.35
	end
	v.pulse += math.clamp(target - v.pulse, -step, step)
	if quiet() then
		v.blood = math.max(v.blood, Anatomy.UNCONSCIOUS_AT + 1)
		v.lethalAt = nil
		v.knockUntil = 0
		if v.state ~= "Alive" and next(v.severed) == nil then
			setState(model, v, "Alive")
		end
		publish(model, v, bleeding)
		return
	end
	-- Out cold, dead, or back.
	local dead = v.blood <= Anatomy.DEAD_AT or (v.lethalAt ~= nil and now >= (v.lethalAt :: number)) or (v.pulse < Anatomy.DEAD_PULSE and target < Anatomy.DEAD_PULSE)
	if dead then
		v.pulse = if v.lethalAt then 0 else v.pulse
		setState(model, v, "Dead")
	elseif v.blood < Anatomy.UNCONSCIOUS_AT or now < v.knockUntil or v.severed.LeftLeg or v.severed.RightLeg then
		setState(model, v, "Unconscious")
	elseif v.state == "Unconscious" then
		setState(model, v, "Alive")
	end
	publish(model, v, bleeding)
end

local REVIVE_AFTER = 10 -- s a dead body lies green before it comes round
local WAKE_SLOW = 3 -- s it lies out cold after that, eyes dizzy, before it gets up
VitalsService.REVIVE_AFTER = REVIVE_AFTER
local DEAD_GREEN = Color3.fromRGB(96, 196, 84)
local trueColors: { [Model]: { [BasePart]: Color3 } } = setmetatable({}, { __mode = "k" }) :: any

-- Dead: every limb green (its own colours kept to give back); alive again: the colours back.
local function paintDead(model: Model, dead: boolean)
	local kept = trueColors[model]
	if dead then
		if kept then
			return -- (already green)
		end
		kept = {}
		trueColors[model] = kept
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				(kept :: any)[d] = d.Color
				d.Color = DEAD_GREEN
			end
		end
	elseif kept then
		trueColors[model] = nil
		for part, color in kept do
			if part.Parent then
				part.Color = color
			end
		end
	end
end

-- One body's turn: its step, then out (dead a while), patched up (out cold a while) or gone (a limb off).
local function tend(model: Model, v: Vitals, dt: number, now: number)
	VitalsService.step(model, v, dt)
	-- (10 Nov 2026, the owner: a dead body turns green, and after REVIVE_AFTER s gets its colour back
	-- and slowly comes round: out cold a few seconds, then up. One with a limb off still goes.)
	if v.state == "Dead" then
		paintDead(model, true)
	end
	if v.state == "Dead" and now - v.since >= REVIVE_AFTER and next(v.severed) == nil and model:GetAttribute("IsDummy") == true then
		paintDead(model, false)
		patchUp(model, v, true)
		v.knockUntil = now + WAKE_SLOW
		model:SetAttribute("Waking", true) -- (out cold only WAKE_SLOW, not OUT_HOLD)
		setState(model, v, "Unconscious")
		publish(model, v, false)
		return
	end
	if v.state == "Dead" and now - v.since >= DEAD_HOLD then
		-- Gone in a puff; whoever looks after it (the lab, the crowd) brings a new one.
		local pelvis = model:FindFirstChild("LowerTorso")
		if pelvis and pelvis:IsA("BasePart") then
			FxService.hit(pelvis.Position, 0, "Heal")
		end
		vitals[model] = nil
		model:Destroy()
	elseif v.state == "Unconscious" and next(v.severed) == nil and (now - v.since >= OUT_HOLD or model:GetAttribute("Waking") == true) and now >= v.knockUntil then
		model:SetAttribute("Waking", nil)
		patchUp(model, v)
	elseif v.state == "Unconscious" and (v.severed.LeftLeg or v.severed.RightLeg) and now - v.since >= DEAD_HOLD * 2 then
		vitals[model] = nil
		model:Destroy()
	end
end

-- Round 4, M10: at most this many bodies lie dead at once on a server (phones draw every one); past
-- it the oldest goes early, in the same puff as at DEAD_HOLD.
local MAX_CORPSES = 16
VitalsService.MAX_CORPSES = MAX_CORPSES

local function capCorpses()
	local count = 0
	for _, v in vitals do
		if v.state == "Dead" then
			count += 1
		end
	end
	if count <= MAX_CORPSES then
		return -- (the usual case: nothing built)
	end
	local dead: { { model: Model, since: number } } = {}
	for model, v in vitals do
		if v.state == "Dead" and model.Parent then
			table.insert(dead, { model = model, since = v.since })
		end
	end
	if #dead <= MAX_CORPSES then
		return
	end
	table.sort(dead, function(a, b)
		return a.since < b.since
	end)
	for i = 1, #dead - MAX_CORPSES do
		local model = dead[i].model
		local pelvis = model:FindFirstChild("LowerTorso")
		if pelvis and pelvis:IsA("BasePart") then
			FxService.hit(pelvis.Position, 0, "Heal")
		end
		vitals[model] = nil
		model:Destroy()
	end
end

local warned: { [string]: boolean } = {}
local function tick(dt: number)
	local now = os.clock()
	capCorpses()
	for model, v in vitals do
		if not model.Parent then
			vitals[model] = nil
			continue
		end
		-- (One body's error never stops the others: it is logged once and the loop goes on.)
		local ok, err = pcall(tend, model, v, dt, now)
		if not ok then
			local key = tostring(err)
			if not warned[key] then
				warned[key] = true
				log.warn("vitals failed for", model.Name, key)
			end
		end
	end
end

-- Tests and the monitor: a body's vitals (nil: never hit).
function VitalsService.of(model: Model): { blood: number, pulse: number, state: string, wounds: number }?
	local v = vitals[model]
	return if v then { blood = v.blood, pulse = v.pulse, state = v.state, wounds = #v.wounds } else nil
end

-- Tests: a body's pulse now (its vitals start here if it was never hit).
function VitalsService.pulseOf(model: Model): number
	return vitalsOf(model).pulse
end

-- Studio tests: as if a body had been in its state `seconds` longer (a dead one goes at DEAD_HOLD
-- without a real 60 s wait).
function VitalsService.ageForTest(model: Model, seconds: number)
	assert(RunService:IsStudio(), "for Studio tests only")
	local v = vitals[model]
	if v then
		v.since -= seconds
	end
end

-- Round 5: REVIVE ALL (SandboxService). A dead body comes round at once (as REVIVE_AFTER would
-- bring it, on the next beat); a living one is healed. False for one that cannot (a limb gone).
function VitalsService.reviveNow(model: Model): boolean
	local v = vitals[model]
	if not v then
		DummyControl.heal(model)
		return true
	end
	if v.state == "Dead" then
		if next(v.severed) ~= nil then
			return false
		end
		v.since = math.min(v.since, os.clock() - REVIVE_AFTER)
		return true
	end
	return VitalsService.heal(model)
end

-- Tests: patch a body up now.
function VitalsService.patchUpForTest(model: Model)
	local v = vitals[model]
	if v then
		patchUp(model, v)
	end
end

function VitalsService.start()
	infoRemote = Net.event(Net.Names.HitInfo)
	Players.PlayerRemoving:Connect(function(player)
		lastInfo[player] = nil
		VitalsService.lastSent[player] = nil
	end)
	task.spawn(function()
		while true do
			tick(task.wait(TICK))
		end
	end)
	log.info("started")
end

return VitalsService
