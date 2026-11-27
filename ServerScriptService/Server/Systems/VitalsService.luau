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
local HitMath = require(Shared.HitMath) :: any
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
local MAX_WOUNDS = 80 -- (23 Nov 2026, owner: every shot stays visible; it was 8) kept on the model (the monitor's list)
local INFO_GAP = 0.08 -- s: at most this often a line to one player (a shotgun's pellets: one line)

-- Every round, bolt or blade that lands weakens the heart a little for good (round 3, M2: the
-- owner's rule, the pulse falls with every hit and more for the head), until the body is patched
-- up: DROP_PER_LOSS bpm for each % of blood the zone costs at once, HEAD_MORE times that for the
-- head and neck (which also bleed HEAD_MORE_BLOOD times as much at once), never under DROP_MIN.
-- Enough of them stop it (Anatomy.DEAD_PULSE): bodies die from being shot often enough.
-- (24 Nov 2026, owner: "a weapon does not kill by the number of bullets, but by how much blood is left in the body"): a
-- wound takes blood by where it is (Anatomy: loss) and how strong the weapon is, then bleeds on; only the blood
-- (Anatomy.DEAD_AT) kills. No hit points, no pulse worn down by rounds. A round to the head still kills at once.
local BLOOD_KILLS = (Config :: any).BLOOD_KILLS == true
local BLOOD_PER_WOUND = 4.5 -- times the place's loss, for a round, a blade or a blast
local BLOOD_PER_BLOW = 3.5 -- for a blow
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
	damageAt: number?, -- os.clock() of the last damage (it wears off by Config.DAMAGE_DECAY a second)
}

local vitals: { [Model]: Vitals } = {}
local cutHits: { [Model]: { [string]: number } } = setmetatable({}, { __mode = "k" }) :: any -- (0.36.8: rounds per piece that can come off)
-- (24 Nov 2026, owner: the head falls off at the second round, and the third bursts it, whatever gun.) Rounds in the head
-- since the body was last whole, and whether it has burst.
local headRounds: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local headBurst: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local HEAD_BURST_AT = 3
local infoRemote: RemoteEvent? = nil
local lastInfo: { [Player]: number } = {}
local weaponsToday: { [Player]: any } = setmetatable({}, { __mode = "k" }) :: any -- (AUDIT 14: weapons used today)
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
	-- (V9-P fix round 2: the Damage a body shows wears off as it heals (DAMAGE_DECAY), so a hurt body's
	-- sway fades too (ActiveRagdoll.hurtOf); it was written only when a wound landed.)
	if v.damage and v.damage > 0 and v.damageAt then
		local worn = math.max(0, v.damage - (os.clock() - v.damageAt) * Config.DAMAGE_DECAY)
		local shown = math.floor(worn)
		if model:GetAttribute("Damage") ~= shown then
			model:SetAttribute("Damage", shown)
		end
	end
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
	if (w :: any).closed then
		return false
	end
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
-- (AUDIT 36, WOUNDS_COALESCE: the first change goes out at once; more within WOUNDS_GAP s (an
-- automatic gun) are sent together once at the end of the gap, so a burst is one replication, not 10.)
local WOUNDS_GAP = 0.2
local function shareWounds(model: Model, v: Vitals, now: number)
	if (Config :: any).WOUNDS_COALESCE then
		local vv = v :: any
		local t = os.clock()
		if vv.sharedAt and t - vv.sharedAt < WOUNDS_GAP then
			if not vv.sharePending then
				vv.sharePending = true
				task.delay(WOUNDS_GAP - (t - vv.sharedAt), function()
					vv.sharePending = false
					if model.Parent and vitals[model] == v then
						shareWounds(model, v, os.clock())
					end
				end)
			end
			return
		end
		vv.sharedAt = t
	end
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
-- keep: the wounds close but stay to be seen (23 Nov 2026, owner: shots stay until it has been dead and is alive again).
local function patchUp(model: Model, v: Vitals, quiet: boolean?, keep: boolean?)
	if (Config :: any).BONES_V2 then
		pcall(function()
			(require(script.Parent:WaitForChild("Bones")) :: any).reset(model) -- (D12: patched up, every bone whole again)
		end)
	end
	v.blood = 100
	v.pulse = v.rest
	if keep then
		for _, w in v.wounds do
			local shut: any = w
			shut.closed = true
		end
	else
		table.clear(v.wounds)
	end
	v.weak = 0
	v.ceiling = nil
	v.damage = 0
	v.lethalAt = nil
	v.knockUntil = 0
	v.shared = encodeWounds(v, os.clock())
	model:SetAttribute("Wounds", v.shared)
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
		local spec = Anatomy.cutOf(limb) :: any
		local first = model:FindFirstChild(spec.parts[1])
		local body = model:FindFirstChild(spec.parent or (if string.find(limb, "Leg") then "LowerTorso" else "UpperTorso"))
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
	cutHits[model] = nil
	headRounds[model], headBurst[model] = nil, nil
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
	local spec = Anatomy.cutOf(limb)
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
		local body = model:FindFirstChild((spec :: any).parent or (if string.find(limb, "Leg") then "LowerTorso" else "UpperTorso"))
		-- 0.36.9 (owner: "not just a circle"): a real-looking stump on both sides, sized to the limb: a dark
		-- wound face a little inside the cut, a lighter flesh ring, a bone end sticking out and a few drops round
		-- the edge. Every piece is named Stump (a heal or revive takes them all off again).
		local fp = first :: BasePart
		local thick = math.clamp(math.min(fp.Size.X, fp.Size.Z) * (if game:GetService("ReplicatedStorage"):FindFirstChild("DummySkin2") and limb ~= "Head" and limb ~= "Waist" then 0.7 else 1), 0.25, 1.2)
		for _, holder in { first, body } do
			if holder and holder:IsA("BasePart") then
				-- X points into the holder (along the limb), so -X is out of the cut.
				local base = CFrame.lookAt(socket.WorldPosition, socket.WorldPosition + (holder.Position - socket.WorldPosition)) * CFrame.Angles(0, math.rad(90), 0)
				-- (23 Nov 2026, owner: the bone sat in the air beside the body: the joint is the block's, the body you see is
				-- the skin's (DummySkins FIT): the cut goes on the middle of the skin's own end.)
				if game:GetService("ReplicatedStorage"):FindFirstChild("DummySkin2") and limb ~= "Head" and limb ~= "Waist" then
					local onLeft = string.find(first.Name, "Left", 1, true) ~= nil
					local side = if onLeft then -1 else 1 -- (the body's own left is -X)
					local size = holder.Size
					if holder.Name == "UpperTorso" then
						base = holder.CFrame * CFrame.new(side * (size.X / 2 - 0.1), size.Y * 0.26, 0) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0)
					elseif holder.Name == "LowerTorso" then
						base = holder.CFrame * CFrame.new(side * size.X * 0.25, -size.Y * 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
					else
						local arm = string.find(holder.Name, "Arm", 1, true) ~= nil or string.find(holder.Name, "Hand", 1, true) ~= nil
						local inward = if arm then -side * (size.X * 0.15 + 0.1) else 0
						local up = if holder == first then 1 else -1
						base = holder.CFrame * CFrame.new(inward, up * size.Y * 0.5, 0) * CFrame.Angles(0, 0, math.rad(if up > 0 then -90 else 90))
					end
				end
				local function piece(shape: Enum.PartType, size: Vector3, colour: Color3, at: CFrame)
					local p = Instance.new("Part")
					p.Name = "Stump"
					p:SetAttribute("Limb", limb)
					p.Shape = shape
					p.Size = size
					p.Color = colour
					p.Material = Enum.Material.SmoothPlastic
					p.CanCollide = false
					p.CanQuery = false
					p.CanTouch = false
					p.Massless = true
					p.CastShadow = false
					p.CFrame = at
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = holder
					weld.Part1 = p
					weld.Parent = p
					p.Parent = holder
				end
				local flesh = Color3.fromRGB(150, 45, 60)
				local inner = Color3.fromRGB(95, 15, 30)
				-- The flesh ring, then the darker wound face just out of it.
				piece(Enum.PartType.Cylinder, Vector3.new(0.12, thick * 0.92, thick * 0.92), flesh, base * CFrame.new(0.04, 0, 0))
				piece(Enum.PartType.Cylinder, Vector3.new(0.06, thick * 0.66, thick * 0.66), inner, base * CFrame.new(-0.03, 0, 0))
				-- The bone end: off-white, sticking out of the middle.
				piece(Enum.PartType.Cylinder, Vector3.new(0.34, thick * 0.26, thick * 0.26), Color3.fromRGB(236, 228, 208), base * CFrame.new(-0.12, thick * 0.04, 0))
				piece(Enum.PartType.Ball, Vector3.one * thick * 0.3, Color3.fromRGB(236, 228, 208), base * CFrame.new(-0.29, thick * 0.04, 0))
				if limb == "Head" then
					-- (23 Nov 2026, owner: "the bone sticking up"): the spine out of the neck, longer.
					piece(Enum.PartType.Cylinder, Vector3.new(0.7, thick * 0.22, thick * 0.22), Color3.fromRGB(236, 228, 208), base * CFrame.new(-0.45, 0, 0))
					piece(Enum.PartType.Ball, Vector3.one * thick * 0.28, Color3.fromRGB(236, 228, 208), base * CFrame.new(-0.8, 0, 0))
				end
				-- Ragged drops round the edge.
				for i = 1, 4 do
					local a = i * math.pi / 2 + rng:NextNumber(-0.5, 0.5)
					local r = thick * 0.42
					piece(Enum.PartType.Ball, Vector3.one * thick * rng:NextNumber(0.16, 0.24), if i % 2 == 0 then Anatomy.BLOOD else flesh,
						base * CFrame.new(-0.02, math.cos(a) * r, math.sin(a) * r))
				end
				-- (22 Nov 2026, owner: "blood from both ends"): a spurt out of the cut for a few seconds, both sides.
				if Config.BLOOD ~= "off" then
					local sp = Instance.new("Attachment")
					sp.Name = "StumpSpurt"
					sp.WorldCFrame = base * CFrame.Angles(0, math.rad(90), 0) -- (its front: out of the cut, -X)
					sp.Parent = holder
					local e = Instance.new("ParticleEmitter")
					e.Color = ColorSequence.new(Anatomy.BLOOD)
					e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.12) })
					e.Speed = if limb == "Head" then NumberRange.new(9, 17) else NumberRange.new(5, 11)
					e.SpreadAngle = Vector2.new(25, 25)
					e.Lifetime = NumberRange.new(0.4, 0.8)
					e.Acceleration = Vector3.new(0, -50, 0)
					e.EmissionDirection = Enum.NormalId.Front
					e.Rate = if limb == "Waist" or limb == "Head" then 70 else 35
					e.Parent = sp
					task.delay(if limb == "Waist" or limb == "Head" then 6 else 3.5, function()
						e.Enabled = false
						game:GetService("Debris"):AddItem(sp, 1.5)
					end)
				end
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
	local piece = string.sub(limb, #side + 1)
	local zone = if limb == "Waist" or limb == "Head" then (Anatomy.zones.Neck or Anatomy.zones.Aorta) -- (cut in half or the head off: the big arteries)
		elseif piece == "Arm" or piece == "Leg" then Anatomy.zones[side .. (if piece == "Leg" then "Femoral" else "ArmStump")]
		else Anatomy.zones[side .. piece] or Anatomy.zones[side .. "Forearm"]
	table.insert(v.wounds, { zone = zone, at = Workspace:GetServerTimeNow(), opened = os.clock(), power = 1 })
	v.blood -= 8
	shareWounds(model, v, os.clock())
	-- A leg off: it cannot stand. An arm off (round 3, M3 rule from the owner: an arm never puts a
	-- body down on its own): it stays up, bleeding hard, until the blood decides.
	-- (Cut in half: no one lives through that.)
	if limb == "Waist" or limb == "Head" then
		v.lethalAt = os.clock()
	end
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
local MAX_KEPT = 80 -- wounds kept per body

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
export type WoundOptions = { sever: number?, zone: Anatomy.Zone?, blunt: boolean?, guarded: boolean?, round: boolean?, boost: number?, strike: boolean?, burst: boolean?, toyId: string?, charge: number? }
-- The head gone in pieces: hidden (it comes back when the body is put together again), bits of it fly.
function VitalsService.burstHead(model: Model)
	local head = model:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
	local at = head.Position
	local shown = head.Transparency
	local faces: { SurfaceGui } = {}
	local caps: { BasePart } = {}
	head.Transparency = 1
	head.CanCollide = false
	for _, d in head:GetDescendants() do
		if d:IsA("SurfaceGui") and d.Enabled then
			d.Enabled = false
			table.insert(faces, d)
		elseif d:IsA("BasePart") then
			if d.Name ~= "Stump" and d.Transparency < 1 then
				table.insert(caps, d)
			end
			d.Transparency = 1
		elseif d:IsA("ParticleEmitter") then
			d.Enabled = false
		end
	end
	local conn: RBXScriptConnection? = nil
	conn = model:GetAttributeChangedSignal("Severed"):Connect(function()
		local raw = model:GetAttribute("Severed")
		if type(raw) == "string" and string.find("," .. raw .. ",", ",Head,", 1, true) then
			return
		end
		if conn then
			conn:Disconnect()
		end
		if head.Parent then
			head.Transparency = shown
			head.CanCollide = true
			for _, f in faces do
				f.Enabled = true
			end
			for _, c in caps do
				c.Transparency = 0
			end
		end
	end)
	-- (24 Nov 2026, owner: no blob of blood: pieces of the head fly about as they would, each drips a little on the ground,
	-- and there is a short spray just as it bursts.) Flat shards of the head with the bone on their inside.
	local size = head.Size
	local PIECES = 13
	for i = 1, PIECES do
		-- (Spread evenly over the head's own round: each piece starts where it sat and flies straight out from there.)
		local y = 1 - (i - 0.5) / PIECES * 2
		local r = math.sqrt(math.max(0, 1 - y * y))
		local turn = i * 2.39996
		local out = Vector3.new(math.cos(turn) * r, y, math.sin(turn) * r)
		local w, h = rng:NextNumber(0.24, 0.5), rng:NextNumber(0.22, 0.46)
		local from = head.CFrame:PointToWorldSpace(out * size * 0.4)
		local way = head.CFrame:VectorToWorldSpace(out)
		local shard: BasePart
		if i % 3 == 0 then
			shard = Instance.new("WedgePart")
		else
			shard = Instance.new("Part")
		end
		shard.Name = "HeadBit"
		shard.Size = Vector3.new(w, h, 0.09)
		shard.Color = head.Color
		shard.Material = Enum.Material.SmoothPlastic
		shard.CanQuery, shard.CanTouch, shard.CastShadow = false, false, false
		shard.CustomPhysicalProperties = PhysicalProperties.new(1.4, 0.7, 0.18)
		shard.CFrame = CFrame.lookAt(from, from + way) * CFrame.Angles(0, 0, rng:NextNumber(0, 6))
		local bone = Instance.new(shard.ClassName) :: BasePart
		bone.Name = "HeadBit"
		bone.Size = Vector3.new(w * 0.88, h * 0.88, 0.07)
		bone.Color = Color3.fromRGB(214, 203, 178)
		bone.Material = Enum.Material.SmoothPlastic
		bone.CanCollide, bone.CanQuery, bone.CanTouch, bone.CastShadow, bone.Massless = false, false, false, false, true
		bone.CFrame = shard.CFrame * CFrame.new(0, 0, 0.075)
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = shard, bone
		weld.Parent = bone
		bone.Parent = shard
		if Config.BLOOD ~= "off" then
			local drip = Instance.new("ParticleEmitter")
			drip.Color = ColorSequence.new(Anatomy.BLOOD_DARK)
			drip.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.09), NumberSequenceKeypoint.new(1, 0.05) })
			drip.Speed = NumberRange.new(0, 0.6)
			drip.SpreadAngle = Vector2.new(25, 25)
			drip.Lifetime = NumberRange.new(0.35, 0.6)
			drip.Acceleration = Vector3.new(0, -32, 0)
			drip.LightInfluence = 1
			drip.Rate = 7
			drip.Parent = shard
			task.delay(rng:NextNumber(2.2, 3.6), function()
				drip.Enabled = false
			end)
		end
		shard.Parent = workspace
		shard.AssemblyLinearVelocity = way * rng:NextNumber(9, 20) + Vector3.new(0, rng:NextNumber(5, 12), 0)
		shard.AssemblyAngularVelocity = rng:NextUnitVector() * rng:NextNumber(6, 18)
		game:GetService("Debris"):AddItem(shard, 8 + rng:NextNumber(0, 2))
	end
	if Config.BLOOD ~= "off" then
		local a = Instance.new("Attachment")
		a.WorldPosition = at
		a.Parent = workspace.Terrain
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(Anatomy.BLOOD)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.13), NumberSequenceKeypoint.new(1, 0.04) })
		e.Speed = NumberRange.new(7, 18)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Lifetime = NumberRange.new(0.25, 0.5)
		e.Acceleration = Vector3.new(0, -45, 0)
		e.LightInfluence = 1
		e.Rate = 320
		e.Parent = a
		task.delay(0.1, function()
			e.Enabled = false
		end)
		game:GetService("Debris"):AddItem(a, 2)
	end
	pcall(function()
		FxService.hit(at, 30, "Punch")
	end)
end

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
	local drop = if BLOOD_KILLS or blunt or zone.pulse < 0 then nil else math.clamp(zone.loss * power * DROP_PER_LOSS * (if head then HEAD_MORE else 1), DROP_MIN, DROP_MAX)
	table.insert(v.wounds, { zone = zone, at = Workspace:GetServerTimeNow(), opened = now, power = power, blunt = blunt, drop = drop })
	trimWounds(v, now)
	if v.state ~= "Dead" then
		if BLOOD_KILLS then
			local share = if blunt then BLOOD_PER_BLOW * (if o.strike then HitMath.STRIKE_DAMAGE else 1) else BLOOD_PER_WOUND * (if head then HEAD_MORE_BLOOD else 1)
			if o.round and not blunt and power >= ((Config :: any).SHOT_ONE_KILL_POWER or math.huge) then
				share *= power -- (a Sniper or Railgun round tears a great hole: most of the blood at once)
			end
			v.blood = math.max(0, v.blood - zone.loss * power * share * (o.boost or 1))
		elseif blunt then
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
		if not BLOOD_KILLS and v.state ~= "Dead" then
			local region = if head then Config.DAMAGE_HEAD elseif zone.limb then Config.DAMAGE_LIMB else 1
			-- (Damage wears off by Config.DAMAGE_DECAY a second, so a punch an hour ago does not count.)
			local nowT = os.clock()
			local worn = math.max(0, (v.damage or 0) - (nowT - (v.damageAt or nowT)) * Config.DAMAGE_DECAY)
			v.damageAt = nowT
			v.damage = worn + power * Config.DAMAGE_PER_POWER * region * (if blunt then Config.DAMAGE_BLUNT else 1) * (o.boost or 1) * (if o.strike then HitMath.STRIKE_DAMAGE else 1)
			-- (V9-0ac: a round heavy enough (Sniper, Railgun) kills with one body shot; a limb only hurts.)
			if (Config :: any).SHOT_FLINCH and o.round and not blunt and not zone.limb and power >= (Config :: any).SHOT_ONE_KILL_POWER then
				v.damage = math.max(v.damage :: number, Config.BODY_HP)
			end
			model:SetAttribute("Damage", math.floor(v.damage :: number))
			-- (A hit that already took all the blood dies of that: the heart gives out, in step.)
			if not quiet() and (v.damage :: number) >= Config.BODY_HP and v.blood > Anatomy.DEAD_AT then
				v.pulse = 0
				v.lethalAt = now
				setState(model, v, "Dead", "Wounds")
			end
		end
		-- (V9-0ac fix round 2: under SHOT_FLINCH a round never knocks a living body out by its zone (a
		-- round in the spine from behind floored it): only a blow does, or a round strong enough to kill
		-- at once. A round drops it by its damage.)
		-- (Fix round 3: the rule is for rounds only: a blade still knocks out by its zone.)
		local roundKO = not blunt and not ((Config :: any).SHOT_FLINCH and o.round and power < ((Config :: any).SHOT_ONE_KILL_POWER or math.huge))
		if zone.knockout and not o.strike and power >= (if blunt then BLUNT_KNOCKOUT else 0.6) and (blunt or roundKO) then
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
	-- 0.36.8 (owner): enough rounds on one spot take that piece off (Anatomy.cutForZone: the shoulder the arm,
	-- the wrist the hand, and so on). Counted per body until it is healed or revived.
	if not severed and not blunt and Config.SEVERING then
		local cut, need = Anatomy.cutForZone(zone.id)
		if cut and need > 0 then
			local counts = cutHits[model] or {}
			cutHits[model] = counts
			counts[cut] = (counts[cut] or 0) + 1
			if counts[cut] >= need and VitalsService.sever(model, cut, position) then
				counts[cut] = nil
				severed = cut
			end
		end
	end
	-- (23 Nov 2026, owner: "a Deagle or a shotgun to the head: the head bursts".)
	if o.burst and o.round and not o.guarded and HEADSHOT[zone.id] and v.state == "Dead" and not v.severed.Head and VitalsService.sever(model, "Head", position) then
		headBurst[model] = true
		VitalsService.burstHead(model)
	end
	if o.round and not o.guarded and HEADSHOT[zone.id] and part.Name == "Head" and not headBurst[model] and not quiet() then
		headRounds[model] = if o.burst then HEAD_BURST_AT else (headRounds[model] or 0) + 1 -- (a big gun: at once, also a head that is off already)
		if headRounds[model] >= HEAD_BURST_AT and (v.severed.Head or VitalsService.sever(model, "Head", position)) then
			headBurst[model] = true
			VitalsService.burstHead(model)
		end
	end
	VitalsService.step(model, v, 0)
	local label = if severed then (((Anatomy.cutOf(severed :: string) :: any).label) .. " severed")
		elseif Config.MILD_TEXT then Anatomy.mildLabel(zone.id) -- (phase 0: a body region, no organs)
		else zone.label
	-- (row 4 / F59 LEFT, Config.HIT_BONE_NAME: a round to the trunk names the bone it reaches, as the X-ray shows it:
	-- the chest front = Sternum (middle) or Rib, the back = Spine (middle) or Shoulder blade, the sides = Rib; the belly
	-- front = Pelvis, its back = Lower spine)
	if (Config :: any).HIT_BONE_NAME and o.round and not severed and (part.Name == "UpperTorso" or part.Name == "LowerTorso") then
		local l = part.CFrame:PointToObjectSpace(position)
		local sx, sz = l.X / (part.Size.X / 2), l.Z / (part.Size.Z / 2)
		local bone = if part.Name == "UpperTorso"
			then (if math.abs(sx) > 0.75 then "Rib" elseif sz < 0 then (if math.abs(sx) < 0.25 then "Sternum" else "Rib") else (if math.abs(sx) < 0.3 then "Spine" else "Shoulder blade"))
			else (if sz < 0 then "Pelvis" else "Lower spine")
		label = label .. " (" .. bone .. ")"
	end
	-- (AUDIT 14: the "Use N different weapons" daily goal: the different weapons that hit today, a "max" goal)
	if by and by:IsA("Player") and type(o.toyId) == "string" then
		local day = math.floor(os.time() / 86400)
		local w = weaponsToday[by]
		if not w or w.day ~= day then
			w = { day = day, set = {}, n = 0 }
			weaponsToday[by] = w
		end
		if not w.set[o.toyId] then
			w.set[o.toyId] = true
			w.n += 1
			local n = w.n
			pcall(function()
				(require(script.Parent:WaitForChild("ProgressService")) :: any).goal(by, "Weapons", n)
			end)
		end
	end
	-- (D12 part 1, Config.BONES_V2: the bone it hit loses integrity; a stage change is named on the card: ": CRACKED")
	if (Config :: any).BONES_V2 and not severed then
		local kind = if o.zone == Anatomy.zones.Blast then "blast" elseif o.round then "round" else "blow"
		local okB, word = pcall(function()
			local range: number? = nil
			local ch = by and by.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				range = (hrp.Position - position).Magnitude
			end
			return (require(script.Parent:WaitForChild("Bones")) :: any).hit(model, part, power, kind, o.toyId, o.charge, range)
		end)
		if okB and type(word) == "string" then
			label = label .. ": " .. word
			if (word == "BROKEN" or word == "SHATTERED") and by and by:IsA("Player") then
				pcall(function() -- (AUDIT 14: the "Break N bones" daily goal)
					(require(script.Parent:WaitForChild("ProgressService")) :: any).goal(by, "Breaks", 1)
				end)
			end
		end
	end
	local line = string.format("%s \u{00B7} %d%% blood \u{00B7} %s", label, math.floor(v.blood + 0.5), if v.state == "Dead" then (if Config.GORE == false then "knocked out" else "no pulse") else "pulse " .. math.floor(v.pulse + 0.5))
	local killedNow = not wasDead and v.state == "Dead"
	-- (24 Nov 2026: it may get mad at who hit it, the more the nearer it is to dying: Mourning.provoke.)
	if by and v.state == "Alive" and not severed and not quiet() then
		local hp = (Config :: any).BODY_HP
		local near = math.max((100 - v.blood) / (100 - Anatomy.DEAD_AT), if type(hp) == "number" and hp > 0 then (v.damage or 0) / hp else 0)
		pcall(function()
			(require(script.Parent:WaitForChild("Mourning")) :: any).provoke(model, by, near)
		end)
	end
	-- (Round 4, M10: the line for the hit that killed is never held back by INFO_GAP.)
	-- (A creature's bite on a body no player gave it: no card, LabCreatures "Fed".)
	local unseen = o.zone == Anatomy.zones.Neck and model:GetAttribute("InMachine") ~= nil and model:GetAttribute("Fed") ~= true
	if by and infoRemote and not unseen and (killedNow or now - (lastInfo[by] or -math.huge) >= INFO_GAP) then
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
		if (w :: any).closed then
			continue
		end
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
	if bruise > 0 and (v.blood <= BRUISE_FLOOR or BLOOD_KILLS) then
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
	target = math.clamp(target, if BLOOD_KILLS and not v.lethalAt then 28 else 0, 210)
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
	-- (FIXES 10.2, Config.BLEED_STAGES: a slow, readable bleed-out. It already sways and walks slower as Blood falls
	-- (ActiveRagdoll hurtOf); in the last 12 % before out cold it sinks to its knees, a hand on the ground ("Breath",
	-- a kneeling mood), then at UNCONSCIOUS_AT it tips over and lies still, breathing.)
	if (Config :: any).BLEED_STAGES and model:GetAttribute("IsDummy") == true then
		local mood = model:GetAttribute("Mood")
		local sinking = v.state == "Alive" and bleeding and v.blood < Anatomy.UNCONSCIOUS_AT + 12 and v.blood >= Anatomy.UNCONSCIOUS_AT
		if sinking and mood == nil and model:GetAttribute("InMachine") == nil then
			model:SetAttribute("Mood", "Breath")
			model:SetAttribute("FaintMood", true)
		elseif not sinking and model:GetAttribute("FaintMood") == true then
			model:SetAttribute("FaintMood", nil)
			if mood == "Breath" then
				model:SetAttribute("Mood", nil)
			end
		end
	end
	-- Out cold, dead, or back.
	local dead = v.blood <= Anatomy.DEAD_AT or (v.lethalAt ~= nil and now >= (v.lethalAt :: number)) or (not BLOOD_KILLS and v.pulse < Anatomy.DEAD_PULSE and target < Anatomy.DEAD_PULSE)
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
local LAB_REVIVE_AFTER = 8 -- (22 Nov 2026: 4 s rotting in, a little while green, then the rot fades: ROT_IN, ROT_OUT)
local LAB_REVIVE_MIN, LAB_REVIVE_MAX = 20, 30
local WAKE_SLOW = 3 -- s it lies out cold after that, eyes dizzy, before it gets up
VitalsService.REVIVE_AFTER = REVIVE_AFTER
local DEAD_GREEN = Color3.fromRGB(96, 196, 84)
local trueColors: { [Model]: { [BasePart]: Color3 } } = setmetatable({}, { __mode = "k" }) :: any

-- (22 Nov 2026, owner: "they rot slowly, then the rot fades and they come alive"): the green creeps
-- in over ROT_IN s after death and fades back to the body's own colours over ROT_OUT s before it wakes.
local TweenService = game:GetService("TweenService")
local ROT_IN = 4
local ROT_OUT = 1.5
VitalsService.ROT_OUT = ROT_OUT

-- Dead: every limb slowly green (its own colours kept to give back); alive again: the colours back.
local function paintDead(model: Model, dead: boolean)
	if dead and not Config.DEAD_GREEN then
		return -- (23 Nov 2026, owner: they do not turn green)
	end
	local kept = trueColors[model]
	if dead then
		if kept then
			return -- (already rotting)
		end
		kept = {}
		trueColors[model] = kept
		local info = TweenInfo.new(ROT_IN, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				(kept :: any)[d] = d.Color
				TweenService:Create(d, info, { Color = DEAD_GREEN }):Play()
			end
		end
	elseif kept then
		trueColors[model] = nil
		local info = TweenInfo.new(ROT_OUT, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		for part, color in kept do
			if part.Parent then
				TweenService:Create(part, info, { Color = color }):Play()
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
	local labDummy = type(model:GetAttribute("LabOwner")) == "number" and type(model:GetAttribute("Slot")) == "number"
	-- (23 Nov 2026, owner: "20 to 30 seconds from green to normal again"): a lab body lies dead a random 20-30 s.
	local vr: any = v
	if v.state == "Dead" and vr.reviveFor ~= v.since then
		vr.reviveFor = v.since
		vr.reviveIn = LAB_REVIVE_MIN + math.random() * (LAB_REVIVE_MAX - LAB_REVIVE_MIN)
	end
	if v.state == "Dead" and model:GetAttribute("BeingHelped") ~= true and now - v.since >= (if labDummy then (vr.reviveIn or LAB_REVIVE_AFTER) else REVIVE_AFTER) and (next(v.severed) == nil or labDummy) and model:GetAttribute("IsDummy") == true then
		if labDummy and next(v.severed) ~= nil then reattach(model, v) end
		paintDead(model, false)
		if (Config :: any).DEATH_HEAL then
			-- (F47, owner 26 Nov late: waking from DEATH heals every injury (bones, bruises, limp, the hurt face, drips,
			-- plasters) EXCEPT the shots: the bullet holes stay (closed, no longer bleeding) so the pick-out scene
			-- (Systems/PickOut) can take them out one by one)
			patchUp(model, v, true, true)
			for i = #v.wounds, 1, -1 do
				if v.wounds[i].blunt then
					table.remove(v.wounds, i)
				end
			end
			v.shared = encodeWounds(v, os.clock())
			model:SetAttribute("Wounds", v.shared)
		else
			patchUp(model, v, true)
		end
		v.knockUntil = now + WAKE_SLOW
		model:SetAttribute("Waking", true) -- (out cold only WAKE_SLOW, not OUT_HOLD)
		setState(model, v, "Unconscious")
		publish(model, v, false)
		return
	end
	if v.state == "Dead" and not labDummy and now - v.since >= DEAD_HOLD then
		-- Gone in a puff; whoever looks after it (the lab, the crowd) brings a new one.
		local pelvis = model:FindFirstChild("LowerTorso")
		if pelvis and pelvis:IsA("BasePart") then
			FxService.hit(pelvis.Position, 0, "Heal")
		end
		vitals[model] = nil
		model:Destroy()
	elseif v.state == "Unconscious" and next(v.severed) == nil and (now - v.since >= OUT_HOLD or model:GetAttribute("Waking") == true) and now >= v.knockUntil then
		model:SetAttribute("Waking", nil)
		patchUp(model, v, false, true)
	elseif v.state == "Unconscious" and not labDummy and (v.severed.LeftLeg or v.severed.RightLeg) and now - v.since >= DEAD_HOLD * 2 then
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
	for model, v in vitals do
		if v.state == "Dead" and not (type(model:GetAttribute("LabOwner")) == "number" and type(model:GetAttribute("Slot")) == "number") then
			count += 1
		end
	end
	if count <= MAX_CORPSES then
		return -- (the usual case: nothing built)
	end
	local dead: { { model: Model, since: number } } = {}
	for model, v in vitals do
		if v.state == "Dead" and model.Parent and not (type(model:GetAttribute("LabOwner")) == "number" and type(model:GetAttribute("Slot")) == "number") then
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
		-- (LAG-FREE 2 item 8: a dead body that sleeps is tended once a second, not 4 times, with the time it missed;
		-- its timed revive (20-30 s) still comes, a second late at most)
		local step = dt
		if v.state == "Dead" and model:GetAttribute("Asleep") == true then
			local vr: any = v
			vr.slept = (vr.slept or 0) + dt
			if vr.slept < 1 then
				continue
			end
			step = vr.slept
			vr.slept = 0
		end
		-- (One body's error never stops the others: it is logged once and the loop goes on.)
		local ok, err = pcall(tend, model, v, step, now)
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
-- First aid (24 Nov 2026, FirstAid): the place hurt worst (LeftArm, RightArm, LeftLeg, RightLeg, Body, Head) and how long
-- ago the last wound came; nil with none.
local function aidGroup(id: string): string
	local side, rest = string.match(id, "^(%u%l+)(%u.*)$")
	if side == "Left" or side == "Right" then
		if rest == "UpperArm" or rest == "ArmStump" or rest == "Forearm" or rest == "Hand" then
			return side .. "Arm"
		elseif rest == "Thigh" or rest == "Femoral" or rest == "Shin" or rest == "Foot" or rest == "LegStump" then
			return side .. "Leg"
		end
	end
	return if HEAD_ZONES[id] then "Head" else "Body"
end
function VitalsService.aidNeed(model: Model): (string?, number)
	local v = vitals[model]
	if not v or #v.wounds == 0 or v.state == "Dead" then
		return nil, 0
	end
	local worst: { [string]: number } = {}
	local newest = 0
	local best: string? = nil
	for _, w in v.wounds do
		local g = aidGroup(w.zone.id)
		worst[g] = (worst[g] or 0) + 0.1 + w.zone.bleed
		newest = math.max(newest, w.opened)
		if best == nil or worst[g] > (worst[best :: string] or 0) then
			best = g
		end
	end
	return best, os.clock() - newest
end
-- That place is well again: its wounds go (its colour on every screen too); with none left the body is whole.
function VitalsService.dress(model: Model, group: string)
	local v = vitals[model]
	if not v or v.state == "Dead" then
		return
	end
	for i = #v.wounds, 1, -1 do
		if aidGroup(v.wounds[i].zone.id) == group then
			table.remove(v.wounds, i)
		end
	end
	if group == "LeftLeg" or group == "RightLeg" then
		model:SetAttribute(if group == "LeftLeg" then "LegShotLeft" else "LegShotRight", nil)
	end
	cutHits[model] = nil
	headRounds[model], headBurst[model] = nil, nil
	if #v.wounds == 0 then
		patchUp(model, v, true)
	else
		v.damage = (v.damage or 0) * 0.5
		shareWounds(model, v, os.clock())
	end
end

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
		if next(v.severed) ~= nil and type(model:GetAttribute("Slot")) ~= "number" then
			return false
		end
		-- (A lab body waits 20-30 s by itself: past that, so it really wakes now.)
		model:SetAttribute("BeingHelped", nil)
		v.since = math.min(v.since, os.clock() - math.max(REVIVE_AFTER, LAB_REVIVE_MAX + 1))
		return true
	end
	return VitalsService.heal(model)
end

-- Tests: patch a body up now.
-- F47 (Systems/PickOut): one bullet picked out: the oldest wound (a hole and its lodged slug) goes from the list, the
-- shared list is sent again (the hole closes on every screen). Returns how many are left.
function VitalsService.pickOneOut(model: Model): number
	local v = vitals[model]
	if not v then
		local raw = model:GetAttribute("Wounds")
		if type(raw) ~= "string" or raw == "" then
			return 0
		end
		local parts = string.split(raw, ";")
		table.remove(parts, 1)
		model:SetAttribute("Wounds", table.concat(parts, ";"))
		return #parts
	end
	if #v.wounds == 0 then
		return 0
	end
	table.remove(v.wounds, 1)
	v.shared = encodeWounds(v, os.clock())
	model:SetAttribute("Wounds", v.shared)
	return #v.wounds
end

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
