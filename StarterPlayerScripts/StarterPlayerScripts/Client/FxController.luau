--!strict
-- Client-side juice for hits and landings: sound, a burst of cartoon sparks, camera shake and an FOV punch.
-- Sounds are Creator Store assets listed with their source in Shared.SoundManifest. Every event has a
-- bank of variants; a variant never plays twice in a row, pitch wanders a little, and a burst of the
-- same event (TNT knocking six dummies over) is thinned out so it reads as one big moment, not a wall.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local Anatomy = require(Shared:WaitForChild("Anatomy"))
local N7Models = require(Shared:WaitForChild("N7Models"))
local HitFeel = require(Shared:WaitForChild("HitFeel"))
local SoundManifest = require(Shared:WaitForChild("SoundManifest"))
local AvatarMoves = require(script.Parent:WaitForChild("AvatarMoves"))
local BloodFx = require(script.Parent:WaitForChild("BloodFx"))
local PlotPrivacy = require(script.Parent:WaitForChild("PlotPrivacy"))
local BulletHoles = require(script.Parent:WaitForChild("BulletHoles"))
local DummyLife = require(script.Parent:WaitForChild("DummyLife"))
local Settings = require(script.Parent:WaitForChild("Settings"))
local SoundMix = require(script.Parent:WaitForChild("SoundMix"))
-- World/Feel v2 (Config.FEEL_V2): the trauma shake, particle bursts, flops, trails, muzzle flash and
-- casings, the combo beat. Every v2 layer is behind FeelV2.ON; off, this file plays as in 0.20.
local FeelV2 = require(script.Parent:WaitForChild("FeelV2"))

-- Round 4, M10: every bank comes from the manifest (ids, titles and sources live there). A bank
-- loses an id whose asset fails to load (start), so a blocked upload never plays silence.
local BANK: { [string]: { string } } = {}
for bank in SoundManifest.SOUNDS do
	BANK[bank] = SoundManifest.assetIds(bank)
end
local BURST_WINDOW = 0.12 -- s
local BURST_MAX = 3 -- plays of one bank inside the window
local MAX_VOICES = 28
-- 10 Nov 2026 (mobile sound fix): a phone made 230 Sounds at once and dropped every play that took
-- over 0.1 s to load, so phones were nearly silent for their first minutes and in rapid fire.
-- Now a phone starts with one voice per asset (the pool grows on demand), the player's own shots
-- and hits may wait longer, and a busy asset restarts its oldest loaded voice instead of making a
-- fresh, unloaded one.
local UserInputService = game:GetService("UserInputService")
local PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local POOL = if PHONE then 1 else 2 -- loaded Sounds made per asset id at start, reused play after play
local LOAD_WAIT = if PHONE then 0.2 else 0.1 -- s a sound not yet loaded may wait; later it is dropped, never late
local LOAD_WAIT_OWN = 0.35 -- s the player's own shot or hit may wait (heard a little late beats silence)
local POOL_MAX = 6 -- voices an asset may grow to before a busy one is restarted
local CUT_FADE = 0.05 -- s a sound takes to fade out before its voice is freed (no click)
local SOUND_REACH = 160 -- studs a sound is heard, unless the caller says otherwise

local SHAKE_RANGE = 70 -- studs
local SPARK_COLORS = { Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 140, 40) }

local FxController = {}

local fxFolder: Folder
local shakeAmount = 0
local fovKick = 0
local baseFov: number? = nil
local rng = Random.new()

local soundAnchor: Part? = nil
local lastVariant: { [string]: number } = {}
local burst: { [string]: { start: number, count: number } } = {}

-- Round 4, M10: a voice is one Sound in its own attachment. Pooled voices are made and loaded at
-- start and moved to each new spot; `play` counts plays, so a timer only frees the play it began.
type Voice = { id: string, at: Attachment, sound: Sound, pooled: boolean, priority: boolean, play: number, fade: Tween? }
local free: { [string]: { Voice } } = {} -- pooled voices waiting, by asset id
local live: { Voice } = {} -- voices in use, oldest first
local plays = 0

-- Whether a point is on (or right by) a player's avatar: players are never hurt, so no blood there.
local function onPlayerBody(position: Vector3): boolean
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - position).Magnitude < 4 then
			return true
		end
	end
	return false
end

local function anchor(): Part
	local existing = soundAnchor
	if existing and existing.Parent then
		return existing
	end
	local p = Instance.new("Part")
	p.Name = "SoundAnchor"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.CFrame = CFrame.new()
	p.Parent = fxFolder
	soundAnchor = p
	return p
end

local function newVoice(id: string, pooled: boolean): Voice
	local at = Instance.new("Attachment")
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.RollOffMinDistance = 10
	sound.Parent = at
	at.Parent = anchor()
	return { id = id, at = at, sound = sound, pooled = pooled, priority = false, play = 0 }
end

-- Frees a voice for the play it was started for (a later play of a reused voice is left alone).
local function release(voice: Voice, play: number)
	if voice.play ~= play then
		return
	end
	voice.play = 0
	local fade = voice.fade
	if fade then
		fade:Cancel()
		voice.fade = nil
	end
	local i = table.find(live, voice)
	if i then
		table.remove(live, i)
	end
	voice.sound:Stop()
	local pool = free[voice.id]
	if voice.pooled and pool and voice.at.Parent then
		table.insert(pool, voice)
	else
		voice.at:Destroy()
	end
end

-- Fades a voice over its last moments instead of stopping it dead (no click; a gun's room tail
-- dies away over `length`).
local function fadeOut(voice: Voice, play: number, length: number)
	if voice.play == play then
		local tween = TweenService:Create(voice.sound, TweenInfo.new(length, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Volume = 0 })
		voice.fade = tween
		tween:Play()
	end
end

-- Starts a loaded voice; its cut and fade are timed from here, the moment it is really heard.
local function begin(voice: Voice, play: number, cut: number?, from: number?, fade: number?)
	if voice.play ~= play then
		return
	end
	local sound = voice.sound
	sound.TimePosition = from or 0
	sound:Play()
	local length = math.max(sound.TimeLength - (from or 0), 0.3) / math.max(sound.PlaybackSpeed, 0.3)
	local hold = if cut then cut else math.min(length + 0.1, 6)
	local fading = math.min(fade or CUT_FADE, hold)
	task.delay(math.max(hold - fading, 0), fadeOut, voice, play, fading)
	task.delay(hold, release, voice, play)
end

-- Starts a voice once it has loaded, if that takes no longer than LOAD_WAIT; otherwise drops it.
local function beginWhenLoaded(voice: Voice, play: number, cut: number?, from: number?, fade: number?)
	if voice.sound.IsLoaded then
		begin(voice, play, cut, from, fade)
		return
	end
	local waiting = true
	local loaded = voice.sound.Loaded:Once(function()
		if waiting then
			waiting = false
			begin(voice, play, cut, from, fade)
		end
	end)
	task.delay(if voice.priority then LOAD_WAIT_OWN else LOAD_WAIT, function()
		if waiting then
			waiting = false
			loaded:Disconnect()
			release(voice, play)
		end
	end)
end

-- Whether a bank has thinned out its burst (more than BURST_MAX plays inside BURST_WINDOW).
local function throttled(bank: string): boolean
	local now = os.clock()
	local b = burst[bank]
	if not b or now - b.start > BURST_WINDOW then
		b = { start = now, count = 0 }
		burst[bank] = b
	end
	b.count += 1
	return b.count > BURST_MAX
end

-- Frees the oldest voice that is not the player's own (for an own hit when every voice is busy).
local function steal(): boolean
	for _, voice in live do
		if not voice.priority then
			release(voice, voice.play)
			return true
		end
	end
	return false
end

-- A random variant of a bank, never the one it played last.
local function variant(bank: string, list: { string }): string
	local index = rng:NextInteger(1, #list)
	if #list > 1 and index == lastVariant[bank] then
		index = index % #list + 1
	end
	lastVariant[bank] = index
	return list[index]
end

-- A pooled voice of an asset if one is free, else a new one (it joins the pool when freed).
local count: { [string]: number } = {} -- voices made per asset id (pooled ones)
local function takeVoice(id: string): Voice
	local pool = free[id]
	while pool and #pool > 0 do
		local voice = table.remove(pool) :: Voice
		if voice.at.Parent then
			return voice
		end
	end
	-- None free: grow the pool up to POOL_MAX, then restart this asset's oldest loaded voice
	-- (always heard at once; a fresh Sound would still be loading).
	if pool and (count[id] or 0) >= POOL_MAX then
		for _, busy in live do
			if busy.id == id and busy.sound.IsLoaded and not busy.priority then
				release(busy, busy.play)
				local again = table.remove(pool)
				if again and again.at.Parent then
					return again
				end
				break
			end
		end
	end
	if pool then
		count[id] = (count[id] or 0) + 1
	end
	return newVoice(id, pool ~= nil)
end

local function hasBank(bank: string): boolean
	local list = BANK[bank]
	return list ~= nil and #list > 0
end

-- Plays a random variant of a bank at a world position. Options:
--   cut      s after which the sound fades and its voice is free again (a rapid-fire gun's long
--            sample would otherwise hold a voice each, crowding out the rest).
--   from     s into the sample it starts (a chainsaw's grind, past its pull cord).
--   reach    studs it is heard (a gunshot carries further than a punch).
--   priority the player's own hit or shot: never thinned out, and takes a busy voice if it must.
--   vary     how far volume and pitch wander (default 0.08 pitch, 0.1 volume; a real gun: 0.03).
--   fade     s the end of a cut fades over (default CUT_FADE; a gun's tail: longer).
type Options = { cut: number?, from: number?, reach: number?, priority: boolean?, vary: number?, fade: number? }
local function play(bank: string, position: Vector3, volume: number, speed: number, options: Options?)
	local o: Options = options or {}
	if not hasBank(bank) or (throttled(bank) and not o.priority) then
		return
	end
	if #live >= MAX_VOICES and not (o.priority and steal()) then
		return
	end
	local id = variant(bank, BANK[bank])
	local voice = takeVoice(id)
	plays += 1
	voice.play = plays
	voice.priority = o.priority == true
	table.insert(live, voice)
	voice.at.WorldPosition = position
	local sound = voice.sound
	local vary = o.vary
	sound.Volume = volume * rng:NextNumber(if vary then 1 - vary else 0.9, 1)
	sound.PlaybackSpeed = speed * (if vary then rng:NextNumber(1 - vary, 1 + vary) else rng:NextNumber(0.92, 1.08))
	sound.RollOffMaxDistance = o.reach or SOUND_REACH
	sound.SoundGroup = SoundMix.groupFor(bank) -- (v4 A3: its group in the mix, under SETTINGS' effects)
	beginWhenLoaded(voice, plays, o.cut, o.from, o.fade)
end

-- An explosion from its own bank (boomPop, boomMid, boomBig, cannonShot, slam: SoundManifest),
-- the old small "boom" in its place if that bank's sounds all failed to load.
local function blast(bank: string, position: Vector3, volume: number, speed: number, cut: number?)
	if hasBank(bank) then
		play(bank, position, volume, speed, { cut = cut, fade = if cut then 0.8 else nil, reach = 260, vary = 0.06 })
		if bank == "boomBig" or bank == "boomMid" or bank == "cannonShot" then
			SoundMix.duck(if bank == "boomBig" then 1.2 else 0.6) -- (the rest dips so the blast reads)
		end
	else
		play("boom", position, volume, speed)
	end
end

local ICE_COLORS = { Color3.fromRGB(190, 235, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 210, 255) }
local DUST_COLORS = { Color3.fromRGB(205, 200, 190), Color3.fromRGB(170, 165, 158), Color3.fromRGB(235, 232, 225) } -- a shot into the ground

local MAX_SPARKS = 140 -- live spark parts at once (phones): a burst over budget is thinned out
local liveSparks = 0

local function sparks(position: Vector3, count: number, power: number, palette: { Color3 }?)
	if FeelV2.ON then
		FeelV2.sparks(position, count, power, palette) -- (pooled particles, not a part per spark)
		return
	end
	count = math.min(count, MAX_SPARKS - liveSparks)
	for _ = 1, count do
		liveSparks += 1
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		local colors = palette or SPARK_COLORS
		p.Color = colors[rng:NextInteger(1, #colors)]
		p.Size = Vector3.one * rng:NextNumber(0.25, 0.5)
		p.CFrame = CFrame.new(position) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0)
		p.Parent = fxFolder
		local dir = rng:NextUnitVector()
		local goal = position + dir * rng:NextNumber(1.5, 3) * power
		local tween = TweenService:Create(p, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = goal,
			Size = Vector3.one * 0.05,
			Transparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			liveSparks -= 1
			p:Destroy()
		end)
	end
end

local function nearness(position: Vector3): number
	local camera = Workspace.CurrentCamera
	if not camera then
		return 0
	end
	local d = (camera.CFrame.Position - position).Magnitude
	return math.clamp(1 - d / SHAKE_RANGE, 0, 1)
end

-- Moments worth an Instant Replay: the catalog marks its big tools; machines are big too.
local function isBig(toyId: string): boolean
	local toy = Toys.byId[toyId]
	-- (Contact ids that are not tools: machines, the spring pad, the human cannon, a hard throw.)
	return toyId == "Machine" or toyId == "SpringPad" or toyId == "CannonPad" or toyId == "Throw" or (toy ~= nil and toy.big)
end

-- A flat ring racing out from a blast (shockwave, black hole spitting things out).
local liveRings = 0
local function ring(position: Vector3, radius: number, color: Color3, time: number)
	if liveRings >= 4 then
		return
	end
	liveRings += 1
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.3, 2, 2)
	p.Transparency = 0.2
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = fxFolder
	local tween = TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.3, radius * 2, radius * 2),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		liveRings -= 1
		p:Destroy()
	end)
end

local STAR_COLORS = { Color3.fromRGB(255, 230, 80), Color3.fromRGB(255, 255, 200) }
local ZAP_COLORS = { Color3.fromRGB(255, 250, 140), Color3.fromRGB(255, 255, 255), Color3.fromRGB(130, 220, 255) }
local POP_COLORS = { Color3.fromRGB(255, 90, 170), Color3.fromRGB(255, 200, 230), Color3.fromRGB(255, 255, 255) }
local HOLE_COLORS = { Color3.fromRGB(150, 90, 255), Color3.fromRGB(60, 30, 120), Color3.fromRGB(220, 200, 255) }
local localUserId = game:GetService("Players").LocalPlayer.UserId
-- Our own taps already played locally: one entry per tap, so a fast double tap skips both echoes.
local predicted: { [string]: { number } } = {}
local PREDICT_EXPIRY = 2 -- s an own tap waits for its echo (round 4, M10: up from 1, for high ping)

-- Called for big moments (a replay is worth offering): (toyId, os.clock() of the moment).
FxController.onBigEvent = nil :: ((toyId: string, at: number, position: Vector3) -> ())?

------------------------------------------------------------------------------------------------
-- Cartoon swings: every hand and smack tool shows the thing that hit (a fist, a boot, a pan, a
-- bat, a glove on a spring, a golf club, a big mallet, a giant hand), swung through the spot in a
-- blink and gone. Seen by everyone; nothing here touches anything.

type PieceSpec = { size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType? }
type SwingSpec = { reach: number, pieces: { PieceSpec } }

local SKIN = Color3.fromRGB(255, 205, 160)
local function along(distance: number): CFrame
	return CFrame.new(0, 0, -distance) -- along the tool, from its pivot outwards
end
local SWINGS: { [string]: SwingSpec } = {
	Poke = { reach = 2.2, pieces = {
		{ size = Vector3.new(0.35, 0.35, 1.4), offset = along(2.2), color = SKIN },
	} },
	Shove = { reach = 2.6, pieces = {
		{ size = Vector3.new(1.5, 1.4, 0.35), offset = along(2.6) * CFrame.new(-0.9, 0, 0), color = SKIN },
		{ size = Vector3.new(1.5, 1.4, 0.35), offset = along(2.6) * CFrame.new(0.9, 0, 0), color = SKIN },
	} },
	Launch = { reach = 4.4, pieces = {
		{ size = Vector3.new(3, 0.45, 0.45), offset = along(2) * CFrame.Angles(0, math.rad(90), 0), color = Color3.fromRGB(200, 200, 210), shape = Enum.PartType.Cylinder },
		{ size = Vector3.new(2.6, 2.6, 2.6), offset = along(4.4), color = Color3.fromRGB(255, 90, 70), shape = Enum.PartType.Ball },
	} },
	Slap = { reach = 2.6, pieces = {
		{ size = Vector3.new(1.3, 0.3, 1.2), offset = along(2.6), color = SKIN },
		{ size = Vector3.new(0.3, 0.3, 0.7), offset = along(2.4) * CFrame.new(0.75, 0, 0.2), color = SKIN },
	} },
	Punch = { reach = 2.4, pieces = {
		{ size = Vector3.new(1.3, 1.3, 1.3), offset = along(2.4), color = Color3.fromRGB(250, 250, 255), shape = Enum.PartType.Ball },
	} },
	Kick = { reach = 2.8, pieces = {
		{ size = Vector3.new(1.1, 1, 1.9), offset = along(2.8), color = Color3.fromRGB(140, 85, 50) },
	} },
	Uppercut = { reach = 2.4, pieces = {
		{ size = Vector3.new(1.4, 1.4, 1.4), offset = along(2.4), color = Color3.fromRGB(250, 250, 255), shape = Enum.PartType.Ball },
	} },
	Pan = { reach = 3.4, pieces = {
		{ size = Vector3.new(0.25, 0.25, 2), offset = along(1.4), color = Color3.fromRGB(60, 40, 30) },
		{ size = Vector3.new(0.25, 2.3, 2.3), offset = along(3.4) * CFrame.Angles(0, 0, math.rad(90)), color = Color3.fromRGB(70, 72, 82), shape = Enum.PartType.Cylinder },
	} },
	Glove = { reach = 3.6, pieces = {
		{ size = Vector3.new(2.4, 0.35, 0.35), offset = along(1.6) * CFrame.Angles(0, math.rad(90), 0), color = Color3.fromRGB(200, 200, 210), shape = Enum.PartType.Cylinder },
		{ size = Vector3.new(1.8, 1.8, 1.8), offset = along(3.6), color = Color3.fromRGB(230, 50, 60), shape = Enum.PartType.Ball },
	} },
	Bat = { reach = 4.6, pieces = {
		{ size = Vector3.new(4.6, 0.55, 0.55), offset = along(2.6) * CFrame.Angles(0, math.rad(90), 0), color = Color3.fromRGB(200, 150, 90), shape = Enum.PartType.Cylinder },
	} },
	Golf = { reach = 4.6, pieces = {
		{ size = Vector3.new(4.4, 0.18, 0.18), offset = along(2.4) * CFrame.Angles(0, math.rad(90), 0), color = Color3.fromRGB(190, 190, 200), shape = Enum.PartType.Cylinder },
		{ size = Vector3.new(0.5, 0.45, 1), offset = along(4.6) * CFrame.new(0, 0, 0), color = Color3.fromRGB(110, 200, 120) },
	} },
	Hammer = { reach = 5, pieces = {
		{ size = Vector3.new(0.4, 0.4, 4), offset = along(2.6), color = Color3.fromRGB(150, 100, 60) },
		{ size = Vector3.new(2.8, 1.9, 1.9), offset = along(5), color = Color3.fromRGB(170, 110, 70) },
	} },
	MegaSlap = { reach = 7, pieces = {
		{ size = Vector3.new(4.2, 0.8, 4.2), offset = along(7), color = Color3.fromRGB(255, 120, 200) },
		{ size = Vector3.new(0.8, 0.8, 2.6), offset = along(9.4) * CFrame.new(-1.5, 0, 0), color = Color3.fromRGB(255, 120, 200) },
		{ size = Vector3.new(0.8, 0.8, 2.9), offset = along(9.6) * CFrame.new(-0.5, 0, 0), color = Color3.fromRGB(255, 120, 200) },
		{ size = Vector3.new(0.8, 0.8, 2.9), offset = along(9.6) * CFrame.new(0.5, 0, 0), color = Color3.fromRGB(255, 120, 200) },
		{ size = Vector3.new(0.8, 0.8, 2.6), offset = along(9.4) * CFrame.new(1.5, 0, 0), color = Color3.fromRGB(255, 120, 200) },
		{ size = Vector3.new(0.8, 0.8, 2.2), offset = along(7.4) * CFrame.new(2.4, 0, 0.6) * CFrame.Angles(0, math.rad(-50), 0), color = Color3.fromRGB(255, 120, 200) },
	} },
}
local SWING_TIME = 0.12
local SWING_CONTACT = 0.56 -- share of SWING_TIME at which a drawn swing passes the spot
local FADE_TIME = 0.2

-- Round 4, M10: the air a blow cuts through, heard just before it lands. Heavy weapons whoosh low
-- and loud, light hands and blades high and soft. (The chainsaw grinds instead.)
local HEAVY_SWINGS: { [string]: boolean } = {
	Hammer = true, Axe = true, Bat = true, Crowbar = true, Pan = true, Golf = true, Cleaver = true, MegaSlap = true,
}
-- priority: this player's own swing (others' whooshes never take a busy voice).
local function swingWhoosh(toyId: string, position: Vector3, priority: boolean?)
	if toyId == "Chainsaw" then
		return
	end
	local heavy = HEAVY_SWINGS[toyId] == true
	play("whoosh", position, if heavy then 0.4 else 0.26, if heavy then 0.8 else 1.25, { cut = 0.35, priority = priority == true })
end
-- Our own blow by hand, just before it lands (PokeController).
function FxController.swingWhoosh(toyId: string, position: Vector3)
	swingWhoosh(toyId, position, true)
end
local MAX_SWINGS = 6
local liveSwings = 0

-- direction: the way the hit goes (from the hitter towards the body).
local function swing(toyId: string, position: Vector3, direction: Vector3)
	local spec = SWINGS[toyId]
	if not spec or liveSwings >= MAX_SWINGS then
		return
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	local dir = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local up = Vector3.yAxis
	local reach = spec.reach
	-- An overhead arc: the pivot sits up and behind the spot; the tool sweeps down through it.
	local uppercut = toyId == "Uppercut"
	local pivot = if uppercut
		then position - dir * reach * 0.5 - up * reach * 0.8
		else position - dir * reach * 0.7 + up * reach * 0.7
	local atHit = (position - pivot).Unit
	local axis = dir:Cross(up)
	if axis.Magnitude < 0.01 then
		axis = Vector3.xAxis
	end
	axis = axis.Unit
	local fromAngle, toAngle = math.rad(-75), math.rad(18)
	if uppercut then
		fromAngle, toAngle = math.rad(70), math.rad(-15)
	end
	local parts: { { part: BasePart, offset: CFrame } } = {}
	for _, piece in spec.pieces do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = piece.color
		p.Size = piece.size
		if piece.shape then
			p.Shape = piece.shape
		end
		p.Parent = fxFolder
		table.insert(parts, { part = p, offset = piece.offset })
	end
	liveSwings += 1
	local function place(angle: number)
		local toolDir = CFrame.fromAxisAngle(axis, angle):VectorToWorldSpace(atHit)
		local frame = CFrame.lookAt(pivot, pivot + toolDir, up)
		for _, entry in parts do
			entry.part.CFrame = frame * entry.offset
		end
	end
	place(fromAngle)
	task.spawn(function()
		local started = os.clock()
		while true do
			local t = (os.clock() - started) / SWING_TIME
			if t >= 1 then
				break
			end
			local eased = 1 - (1 - t) * (1 - t)
			place(fromAngle + (toAngle - fromAngle) * eased)
			RunService.RenderStepped:Wait()
		end
		place(toAngle)
		for _, entry in parts do
			TweenService:Create(entry.part, TweenInfo.new(FADE_TIME), { Transparency = 1 }):Play()
		end
		task.wait(FADE_TIME)
		for _, entry in parts do
			entry.part:Destroy()
		end
		liveSwings -= 1
	end)
end

-- The way a hit came from: the hitter's body towards the spot (or the camera's view).
local stickDart: (Vector3, Vector3, string?) -> ()

-- Darts stay stuck in what they hit (a dummy's limb: they fly with it), a while, then fade. Only on
-- this client (every client sticks its own from the same hit), at most MAX_DARTS at once.
local MAX_DARTS = 40
local DART_STAY = 8
local stuck: { BasePart } = {}
local dartParams = OverlapParams.new()
dartParams.FilterType = Enum.RaycastFilterType.Include

-- What sticks in, by tool: the Blaster's foam dart, the crossbow's bolt, the nail gun's nail.
local DART_LOOKS: { [string]: { size: Vector3, color: Color3, tip: Color3, tipSize: number, material: Enum.Material } } = {
	Blaster = { size = Vector3.new(0.9, 0.28, 0.28), color = Color3.fromRGB(255, 150, 40), tip = Color3.fromRGB(70, 200, 255), tipSize = 0.36, material = Enum.Material.SmoothPlastic },
	Crossbow = { size = Vector3.new(1.9, 0.16, 0.16), color = Color3.fromRGB(120, 80, 40), tip = Color3.fromRGB(230, 60, 60), tipSize = 0.3, material = Enum.Material.Wood },
	NailGun = { size = Vector3.new(0.7, 0.1, 0.1), color = Color3.fromRGB(170, 175, 185), tip = Color3.fromRGB(120, 125, 135), tipSize = 0.22, material = Enum.Material.Metal },
}

function stickDart(position: Vector3, direction: Vector3, toyId: string?)
	local look = DART_LOOKS[toyId or "Blaster"] or DART_LOOKS.Blaster
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	dartParams.FilterDescendantsInstances = { dummies }
	local best: BasePart? = nil
	local bestDistance = 1.6
	for _, p in Workspace:GetPartBoundsInRadius(position, 1.6, dartParams) do
		local d = (p.Position - position).Magnitude
		if p.Transparency < 1 and d < bestDistance then
			best, bestDistance = p, d
		end
	end
	if not best then
		return
	end
	local dart = Instance.new("Part")
	dart.Name = "StuckDart"
	dart.Shape = Enum.PartType.Cylinder
	dart.Size = look.size
	dart.Color = look.color
	dart.Material = look.material
	dart.CanCollide = false
	dart.CanQuery = false
	dart.CanTouch = false
	dart.Massless = true
	dart.CastShadow = false
	-- Half in, half out, along the shot (a cylinder's length is its X axis).
	dart.CFrame = CFrame.lookAt(position - direction * (look.size.X / 2 - 0.15), position + direction) * CFrame.Angles(0, math.rad(90), 0)
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Shape = Enum.PartType.Ball
	tip.Size = Vector3.one * look.tipSize
	tip.Color = look.tip
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CanTouch = false
	tip.Massless = true
	tip.CFrame = CFrame.new(position - direction * (look.size.X - 0.15))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = best
	weld.Part1 = dart
	weld.Parent = dart
	local tipWeld = Instance.new("WeldConstraint")
	tipWeld.Part0 = dart
	tipWeld.Part1 = tip
	tipWeld.Parent = tip
	tip.Parent = dart
	dart.Parent = fxFolder
	table.insert(stuck, dart)
	while #stuck > MAX_DARTS do
		local oldest = table.remove(stuck, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	task.delay(DART_STAY, function()
		if dart.Parent then
			for _, piece in { dart, tip } do
				TweenService:Create(piece, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			end
			task.delay(0.5, function()
				local i = table.find(stuck, dart)
				if i then
					table.remove(stuck, i)
				end
				dart:Destroy()
			end)
		end
	end)
end

-- A dart, bolt or nail streaks from the shooter's muzzle (or hand) to where it hit, and sticks in.
-- The real guns (round 2, N4: the G17, the Deagle, the shotgun) fire a bullet instead: a thin pale
-- tracer and a gunshot, and nothing sticks. Every gun is heard at its muzzle (SoundManifest.GUNS).
local DART_TIME = 0.09
-- What a weapon's blow sounds like on a body, on top of the thud (bank, volume, pitch).
-- (Every one cut short: a voice is held only as long as the blow is heard, so a flurry or a
-- chainsaw never crowds the rest out; the chainsaw's sample starts past its pull cord, in the grind.)
local WEAPON_HITS: { [string]: { bank: string, volume: number, pitch: number, cut: number, from: number? } } = {
	Bat = { bank = "bat", volume = 0.5, pitch = 1, cut = 0.7 },
	Golf = { bank = "golf", volume = 0.55, pitch = 1, cut = 0.7 },
	Axe = { bank = "chop", volume = 0.6, pitch = 0.95, cut = 0.6 },
	Cleaver = { bank = "chop", volume = 0.5, pitch = 1.2, cut = 0.5 },
	Katana = { bank = "chop", volume = 0.4, pitch = 1.45, cut = 0.45 },
	PlasmaBlade = { bank = "chop", volume = 0.35, pitch = 1.6, cut = 0.45 },
	Chainsaw = { bank = "saw", volume = 0.55, pitch = 1, cut = 0.25, from = 1.2 },
	Crowbar = { bank = "clang", volume = 0.45, pitch = 1.35, cut = 0.6 },
	Crossbow = { bank = "arrow", volume = 0.6, pitch = 1, cut = 0.6 },
}
FxController.WEAPON_HITS = WEAPON_HITS
-- Metal surfaces ring (a round striking them ricochets).
local METALS: { [Enum.Material]: boolean } = {
	[Enum.Material.Metal] = true,
	[Enum.Material.DiamondPlate] = true,
	[Enum.Material.CorrodedMetal] = true,
	[Enum.Material.Foil] = true,
}

-- The real guns fire a bullet: the width of its tracer (their sounds are SoundManifest.GUNS).
local REAL_GUNS: { [string]: { width: number, color: Color3? } } = {
	Blaster = { width = 0.07 },
	Deagle = { width = 0.09 },
	Shotgun = { width = 0.14 },
	Minigun = { width = 0.08 },
	Sniper = { width = 0.11 },
	Revolver = { width = 0.09 },
	SMG = { width = 0.06 },
	AK = { width = 0.08 },
	FlareGun = { width = 0.2, color = Color3.fromRGB(255, 120, 40) },
	M4 = { width = 0.08 },
	DoubleBarrel = { width = 0.16 },
	TommyGun = { width = 0.07 },
	AutoShotgun = { width = 0.14 },
	LMG = { width = 0.08 },
	DMR = { width = 0.1 },
	LaserRifle = { width = 0.12, color = Color3.fromRGB(255, 50, 60) },
	Railgun = { width = 0.22, color = Color3.fromRGB(90, 210, 255) },
	GoldenDeagle = { width = 0.1, color = Color3.fromRGB(255, 210, 90) },
}
FxController.REAL_GUNS = REAL_GUNS
-- (A gunshot is heard at the muzzle.)
local function start0(from: BasePart?, position: Vector3): Vector3
	return if from and (from.Position - position).Magnitude < 400 then from.Position else position
end

-- A gun's shot at its muzzle (the fallback if every asset of its own bank failed to load), then
-- the shotgun's pump. (Round 4, M10 fix: no casing "ding" on every shot; the owner heard it as
-- wrong, and a real casing is too quiet to hear over the shot.)
local function fireGun(toyId: string, muzzle: Vector3, _feet: Vector3?, priority: boolean?)
	local g = SoundManifest.GUNS[toyId]
	if not g then
		return
	end
	local options = { cut = g.cut, reach = g.maxDistance, priority = priority, vary = g.vary, fade = g.fade }
	if hasBank(g.fire) then
		play(g.fire, muzzle, g.volume, g.pitch, options)
	else
		play(g.fallback.bank, muzzle, g.fallback.volume, g.fallback.pitch, options)
	end
	local after = g.after
	if after then
		task.delay(g.afterDelay or 0, play, after, muzzle, 0.5, 1, { vary = g.vary })
	end
end

-- The muzzle of a player's held gun (or their hand), and their feet.
local function gunOf(character: Model?): (BasePart?, Vector3?)
	local held = character and character:FindFirstChild("HeldTool")
	local from: BasePart? = nil
	if held then
		local tip = held:FindFirstChild("Tip")
		from = if tip and tip:IsA("BasePart") then tip else nil
	end
	if not from and character then
		local hand = character:FindFirstChild("RightHand")
		from = if hand and hand:IsA("BasePart") then hand else nil
	end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local feet = if root and root:IsA("BasePart") then root.Position - Vector3.new(0, 2.8, 0) else nil
	return from, feet
end

-- priority: this player's own shot (play never drops it).
local function dart(position: Vector3, sourceUserId: number?, toyId: string?, noStick: boolean?, priority: boolean?)
	local shooter = Players:GetPlayerByUserId(sourceUserId or localUserId)
	local from, feet = gunOf(shooter and shooter.Character)
	local real = REAL_GUNS[toyId or ""]
	fireGun(toyId or "", start0(from, position), feet, priority)
	if FeelV2.ON and from and toyId and (from.Position - position).Magnitude < 400 then
		FeelV2.muzzle(toyId, from, position, shooter == nil or shooter.UserId == localUserId)
	end
	local start = if from then from.Position else nil
	if not start or (start - position).Magnitude > 400 then
		return
	end
	local length = (position - start).Magnitude
	local streak = Instance.new("Part")
	streak.Name = "Dart"
	streak.Anchored = true
	streak.CanCollide = false
	streak.CanQuery = false
	streak.CanTouch = false
	streak.CastShadow = false
	streak.Material = Enum.Material.Neon
	streak.Color = if real then (real.color or Color3.fromRGB(255, 240, 190)) else Color3.fromRGB(255, 170, 60)
	local width = if real then real.width else 0.18
	streak.Size = Vector3.new(width, width, length)
	streak.CFrame = CFrame.lookAt(start:Lerp(position, 0.5), position)
	streak.Parent = fxFolder
	local fade = TweenService:Create(streak, TweenInfo.new(DART_TIME * 2), { Transparency = 1, Size = Vector3.new(0.05, 0.05, length) })
	fade:Play()
	fade.Completed:Once(function()
		streak:Destroy()
	end)
	if not noStick and not real then
		stickDart(position, (position - start).Unit, toyId)
	end
end

-- The dummy with a part right at a point (a round's hit), or nil.
local bodyParams = OverlapParams.new()
bodyParams.FilterType = Enum.RaycastFilterType.Include
local function bodyAt(position: Vector3): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return nil
	end
	bodyParams.FilterDescendantsInstances = { dummies }
	local best: Model? = nil
	local bestDistance = math.huge
	for _, part in Workspace:GetPartBoundsInRadius(position, 1.6, bodyParams) do
		local model = part.Parent
		if model and model:IsA("Model") and model.Parent == dummies then
			local d = (part.Position - position).Magnitude
			if d < bestDistance then
				best, bestDistance = model, d
			end
		end
	end
	return best
end

local function hitDirection(position: Vector3, sourceUserId: number?): Vector3
	local hitter = sourceUserId and sourceUserId ~= 0 and game:GetService("Players"):GetPlayerByUserId(sourceUserId)
	local root = hitter and hitter.Character and hitter.Character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return position - root.Position
	end
	local camera = Workspace.CurrentCamera
	return if camera then position - camera.CFrame.Position else Vector3.zAxis
end

-- The Mega Bomb event's bomb (N7): a real aerial bomb drawn here, falling faster and faster onto
-- `at` for `seconds`, then gone (the server's blast is the landing). One per event; only a look.
local BOMB_SIZE = 12 -- studs tall
local BOMB_HEIGHT = 70 -- studs it falls from
local function bombFall(at: Vector3, seconds: number)
	local bomb = N7Models.clone("Fx", "MegaBomb")
	if not bomb or seconds <= 0 or seconds > 5 then
		return
	end
	for _, d in bomb:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local _, size = bomb:GetBoundingBox()
	bomb:ScaleTo(bomb:GetScale() * BOMB_SIZE / math.max(size.Y, 0.01))
	local function place(t: number)
		bomb:PivotTo(CFrame.new(at + Vector3.new(0, BOMB_SIZE / 2 + BOMB_HEIGHT * (1 - t * t), 0)) * CFrame.Angles(0, t * 2, 0))
	end
	place(0)
	bomb.Parent = Workspace
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = math.min((os.clock() - started) / seconds, 1)
		place(t)
		if t >= 1 then
			connection:Disconnect()
			bomb:Destroy()
		end
	end)
end

-- The surface a shot at nothing struck (found along the line from the shooter), or nil: nothing
-- there (the open sky) or a body.
local function surfaceStruck(position: Vector3, sourceUserId: number?): RaycastResult?
	local along = hitDirection(position, sourceUserId or localUserId)
	if along.Magnitude <= 0.01 then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	params.FilterDescendantsInstances = skip
	local struck = Workspace:Raycast(position - along.Unit * 1.5, along.Unit * 3, params)
	local owner = struck and struck.Instance:FindFirstAncestorOfClass("Model")
	if struck and not (owner and (owner:GetAttribute("IsDummy") == true or owner:FindFirstChildOfClass("Humanoid"))) then
		return struck
	end
	return nil
end

-- A gun fired at nothing (round 2, N2): the streak to where it went and its bang (ours is played at
-- once; everyone else's comes from the server). Where it struck a surface: a hole (round 3, M2), a
-- puff of dust and the round striking it (round 3, M4: metal rings, anything else cracks and echoes;
-- a bolt or a nail goes in with a thunk). Round 4, M10: a shot into the open sky strikes nothing.
-- (Cut short: a nail gun at a wall must not hold every voice.)
local RICOCHET_CHANCE = 0.25 -- of a round into stone, wood or the ground
local function shotAt(position: Vector3, sourceUserId: number?, toyId: string, priority: boolean)
	dart(position, sourceUserId, toyId, true, priority)
	local struck = surfaceStruck(position, sourceUserId)
	if not struck then
		return
	end
	BulletHoles.surface(struck.Position, struck.Normal, struck.Instance)
	sparks(position, 5, 0.5, DUST_COLORS)
	if not REAL_GUNS[toyId] then
		play("hit", position, 0.22, 1.5, { cut = 0.35 })
		play("arrow", struck.Position, 0.3, if toyId == "NailGun" then 1.5 else 1.1, { cut = 0.35 })
		return
	end
	-- A round striking a surface (the owner: the pistols sounded wrong): a short, dull impact, never
	-- a punch; metal rings, and now and then (not every shot) a ricochet whines off.
	play("land", struck.Position, 0.14, 2, { cut = 0.25, vary = 0.05 })
	if METALS[struck.Material] then
		play("ricMetal", struck.Position, 0.25, rng:NextNumber(0.95, 1.1), { cut = 0.7 })
	elseif rng:NextNumber() < RICOCHET_CHANCE then
		play("ricHard", struck.Position, 0.16, rng:NextNumber(1.05, 1.25), { cut = 0.7 })
	end
end

-- A round in a body (round 3, M2): the round going in (round 4, M10: a bullet into flesh, the punch
-- if those failed to load), a hole on that spot of the limb, and a few drops out of it along the
-- shot (no splash, no puddle: the body bleeds from the hole after, BloodFx). No shake: a round is small.
local function roundInBody(position: Vector3, sourceUserId: number?, toyId: string, tool: Toys.Toy, priority: boolean)
	local along = hitDirection(position, sourceUserId or localUserId)
	local body = bodyAt(position)
	local part = if body then BulletHoles.body(body, position) else nil
	-- (A player in the plaza takes no wound: a knock, not a round in flesh.)
	if hasBank("flesh") and not onPlayerBody(position) then
		play("flesh", position, 0.5, 1, { cut = 0.5, priority = priority })
	else
		play("hit", position, 0.28, 1.45, { priority = priority })
	end
	local own = WEAPON_HITS[toyId] -- (the crossbow's bolt going in)
	if own then
		play(own.bank, position, own.volume, own.pitch, { cut = own.cut, from = own.from, priority = priority })
	end
	if not onPlayerBody(position) then
		-- (The head list, as the wound has it: the neck bleeds like the head.)
		local zone = if part then Anatomy.zoneAt(part.Name, part.CFrame:PointToObjectSpace(position), part.Size) else nil
		BloodFx.wound(position, tool.wound, along, zone ~= nil and Anatomy.HEAD_ZONES[zone.id] == true)
	end
	dart(position, sourceUserId, toyId, nil, priority)
	if sourceUserId and sourceUserId ~= 0 and sourceUserId ~= localUserId then
		local hitter = Players:GetPlayerByUserId(sourceUserId)
		if hitter then
			AvatarMoves.playRemote(hitter.Character, toyId)
		end
	end
end

-- What a kind of tool adds on top of the impact. weaponSound: the tool has its own impact sound
-- (WEAPON_HITS), so it never gets the cartoon BONK on top (round 4, M10: one clang, not two).
local function styleLayer(position: Vector3, toyId: string, power: number, near: number, weaponSound: boolean)
	local style = if toyId == "Throw" or toyId == "CannonPad" then "Big" else Toys.byId[toyId] and Toys.byId[toyId].fx
	if style == "Big" and toyId ~= "Rocket" then
		-- Launch, Uppercut, Golf, Mega Slap: a whoosh and a slide whistle as they fly.
		play("whoosh", position, 0.6, 1)
		play("whistle", position, 0.45, if toyId == "Uppercut" then 1.25 else 1)
		fovKick = math.max(fovKick, 7 * near * math.min(power, 1.5))
	elseif style == "Clang" and not weaponSound then
		-- BONK: a metal ring over the hit, and cartoon stars (the pan and the hammer).
		play("clang", position, 0.55, if toyId == "Hammer" then 0.75 else 1.15)
		sparks(position, 10, 1.1, STAR_COLORS)
	elseif toyId == "Firecracker" then
		blast("boomPop", position, 0.7, 1, 1.4)
		sparks(position, 12, 1.4, { Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 220, 80), Color3.fromRGB(120, 200, 255) })
	elseif toyId == "Shockwave" then
		blast("slam", position, 0.8, 1, 2.5)
		play("whoosh", position, 0.6, 0.7)
		ring(position, 26, Color3.fromRGB(120, 200, 255), 0.45)
		shakeAmount = math.max(shakeAmount, near * 0.8)
	elseif toyId == "TNT" or toyId == "StickyBomb" or toyId == "BigBoom" then
		local big = toyId == "BigBoom"
		if big then
			-- The biggest bang: a huge blast, then rubble raining down.
			blast("boomBig", position, 1, 1, 4)
			blast("debris", position, 0.55, 1, 3)
		else
			blast("boomMid", position, 0.9, if toyId == "StickyBomb" then 1.1 else 1, 2.2)
		end
		play("land", position, 0.7, 0.6)
		sparks(position, if big then 30 else 18, if big then 4.5 else 3)
		fovKick = math.max(fovKick, (if big then 14 else 9) * near)
		shakeAmount = math.max(shakeAmount, near * (if big then 2 else 1.2))
		if big then
			ring(position, 36, Color3.fromRGB(255, 160, 60), 0.6)
		end
	elseif toyId == "Cannon" then
		-- The cannonball comes down: a heavy blast, lower than TNT's.
		blast("boomMid", position, 0.85, 0.85, 2.2)
		shakeAmount = math.max(shakeAmount, near * 0.9)
	elseif toyId == "Rocket" then
		play("whoosh", position, 0.5, 0.8)
	elseif toyId == "Anvil" then
		play("land", position, 0.9, 0.7)
	elseif toyId == "Machine" then
		-- A heavy "thunk" under the hit: being run over by something you built.
		play("land", position, 0.45 + 0.2 * math.min(power, 1.5), 0.85)
	end
end

-- (v2: a hit-stop for a big moment that is not a blow by hand; set once hitStop exists, below.)
local bigStop: (length: number) -> () = function(_length: number) end
-- (v2: the hits that send a body flying from a launcher: it streaks at once, FeelV2.noteLaunch.)
local LAUNCHERS: { [string]: string } = { CannonPad = "Launch", Throw = "Throw", SpringPad = "Launch", Trampoline = "Launch", Launch = "Launch", Uppercut = "Launch" }

-- The moment a blow lands: the thud, the weapon's own sound, sparks, shake and blood.
local function impact(position: Vector3, speed: number, toyId: string, priority: boolean)
	local power = math.clamp(speed / 40, 0.2, 2.5)
	local near = nearness(position)
	-- Small hits are lighter and higher, big hits deeper and louder.
	play("hit", position, 0.3 + 0.28 * power, 1.25 - 0.18 * math.min(power, 2), { priority = priority })
	-- The weapon's own sound on top (a bat's crack, an axe's chop, a chainsaw's grind).
	local own = WEAPON_HITS[toyId]
	if own then
		play(own.bank, position, own.volume, own.pitch, { cut = own.cut, from = own.from, priority = priority })
	end
	sparks(position, math.floor(4 + 4 * power), 0.8 + 0.6 * power)
	shakeAmount = math.max(shakeAmount, near * 0.35 * power)
	if FeelV2.ON then
		local tool = Toys.byId[toyId]
		local kind = if toyId == "TNT" or toyId == "BigBoom" or toyId == "StickyBomb" or toyId == "Cannon" then "Blast"
			elseif tool and tool.fx == "Clang" then "Clang"
			else "Hit"
		local stop = FeelV2.impact(position, speed, near, kind)
		if stop > 0 and not (tool and tool.byHand) then
			bigStop(stop) -- (a blow by hand already had its own stop: PokeController)
		end
		if power >= 1.2 and not LAUNCHERS[toyId] then
			FeelV2.noteLaunch(position, "Hit") -- knocked flying: the body streaks where it goes
		end
	end
	-- Cartoon blood from anything that really hurts (a wind gust or a gentle nudge does not).
	-- (Not at the middle of a pop or a ring of air, where nobody need be standing.)
	-- (Never on a player: in the plaza players knock each other over, nobody bleeds.)
	if speed >= 14 and toyId ~= "Fan" and toyId ~= "Firecracker" and toyId ~= "Shockwave" and not onPlayerBody(position) then
		local blast = toyId == "TNT" or toyId == "BigBoom" or toyId == "StickyBomb"
		BloodFx.burst(position, if blast then power * 1.4 else power)
	end
	styleLayer(position, toyId, power, near, own ~= nil)
end

-- byHandFlag: whether the hitter's avatar did it by hand (the hitter decided; sent with the hit). Nil
-- for hits that come without one (then the same rule is applied here).
-- own: this player's own hit or shot, played the moment it happens (its sounds are never dropped).
local function onFx(kind: string, position: Vector3, speed: number, toyId: string, sourceUserId: number?, swingDirection: Vector3?, byHandFlag: boolean?, own: boolean?)
	if typeof(position) ~= "Vector3" or type(speed) ~= "number" then
		return
	end
	local priority = own == true
	-- Round 5: the Golden Deagle's head shot: a burst of gold sparks (WeaponMechanics).
	if toyId == "GoldSpark" then
		if PlotPrivacy.visibleAt(position) then
			FxController.goldBurst(position)
		end
		return
	end
	-- (Nothing from a lab this screen does not show: round 3, private labs.)
	if not PlotPrivacy.visibleAt(position) then
		return
	end
	if kind == "BombFall" then
		bombFall(position, speed)
		return
	end
	-- Everyone in earshot looks round (our own predicted ones too, and again when they come back).
	local heardToy = if type(toyId) == "string" then Toys.byId[toyId] else nil
	DummyLife.heard(kind, position, speed, if heardToy then heardToy.fx else nil, REAL_GUNS[toyId] ~= nil)
	if kind == "Shot" then
		shotAt(position, sourceUserId, toyId, priority)
		return
	end
	-- Our own tap was already played locally the moment we tapped.
	if kind == "Hit" and sourceUserId == localUserId then
		local queue = predicted[toyId]
		local now = os.clock()
		while queue and queue[1] and now - queue[1] > PREDICT_EXPIRY do
			table.remove(queue, 1)
		end
		if queue and queue[1] then
			table.remove(queue, 1)
			return
		end
	end
	-- Only moments the player can actually see are worth a replay.
	if kind == "Hit" and isBig(toyId) and ((toyId ~= "Bowling" and toyId ~= "Machine") or speed > 30) and nearness(position) > 0 then
		local listener = FxController.onBigEvent
		if listener then
			task.spawn(listener, toyId, os.clock(), position)
		end
	end
	local near = nearness(position)
	if kind == "Hit" and FeelV2.ON and LAUNCHERS[toyId] then
		FeelV2.noteLaunch(position, LAUNCHERS[toyId])
	end
	if kind == "Hit" then
		if toyId == "Grab" then
			play("whoosh", position, 0.25, 1.6) -- a light "fwip" as the grip takes hold
			return
		elseif toyId == "Trampoline" then
			play("boing", position, 0.75, 1)
			play("whistle", position, 0.3, 1.25)
			sparks(position, 6, 1)
			return
		elseif toyId == "Sever" then
			-- A limb off: a wet crack and the biggest purple splash.
			play("noodle", position, 0.9, 0.8)
			play("land", position, 0.5, 1.3)
			BloodFx.burst(position, 3)
			shakeAmount = math.max(shakeAmount, near * 0.4)
			return
		elseif toyId == "Heal" then
			-- Patched up: a bright little "ding" and a few sparkles.
			play("whoosh", position, 0.25, 1.9)
			sparks(position, 8, 0.7)
			return
		elseif toyId == "Freeze" then
			play("freeze", position, 0.6, 1.35)
			sparks(position, 14, 1.6, ICE_COLORS)
			return
		elseif toyId == "Zap" then
			play("zap", position, 0.6, 1.1)
			sparks(position, 16, 1.4, ZAP_COLORS)
			shakeAmount = math.max(shakeAmount, near * 0.3)
			return
		elseif toyId == "Balloon" or (toyId == "StickyBomb" and speed < 14) then
			-- Stuck on: a light squeak, the real moment comes later.
			play("boing", position, 0.35, 1.6)
			sparks(position, 5, 0.5, if toyId == "Balloon" then POP_COLORS else nil)
			return
		elseif toyId == "BalloonPop" then
			play("pop", position, 0.8, 1)
			sparks(position, 14, 1.4, POP_COLORS)
			return
		elseif toyId == "CannonFire" then
			blast("cannonShot", position, 0.8, 1, 2)
			sparks(position, 8, 1.2)
			shakeAmount = math.max(shakeAmount, near * 0.25)
			return
		elseif toyId == "BlackHole" then
			play("suck", position, 0.7, 1)
			sparks(position, 18, 2.2, HOLE_COLORS)
			return
		elseif toyId == "SpringPad" then
			play("boing", position, 0.85, 0.85)
			play("whistle", position, 0.45, 1.4)
			sparks(position, 8, 1.2)
			fovKick = math.max(fovKick, 5 * near)
			return
		elseif toyId == "BananaPeel" then
			play("zip", position, 0.6, 1.1)
			play("whistle", position, 0.3, 0.8)
			play("land", position, 0.5, 1)
			sparks(position, 6, 0.8, STAR_COLORS)
			return
		end
		local tool = Toys.byId[toyId]
		if tool and tool.gun then
			roundInBody(position, sourceUserId, toyId, tool, priority)
			return
		end
		-- The hitter's avatar swings it by hand when it is close; from afar (the lab view) the tool
		-- swings on its own at the hit, with a whoosh.
		local byHand = if type(byHandFlag) == "boolean" then byHandFlag else AvatarMoves.byHand(sourceUserId, toyId, position)
		local drawn = tool ~= nil and tool.kind == "hit" and not byHand
		if drawn then
			swing(toyId, position, swingDirection or hitDirection(position, sourceUserId))
			swingWhoosh(toyId, position, priority)
		end
		-- Someone else's hit: their avatar does the move here too (from its contact: it has landed).
		if sourceUserId and sourceUserId ~= 0 and sourceUserId ~= localUserId and (byHand or (tool ~= nil and not tool.byHand)) then
			local hitter = Players:GetPlayerByUserId(sourceUserId)
			if hitter then
				AvatarMoves.playRemote(hitter.Character, toyId)
			end
		end
		-- Round 4, M10: a drawn swing reaches the spot part way through its arc; the impact waits for it.
		if drawn then
			task.delay(SWING_TIME * SWING_CONTACT, impact, position, speed, toyId, priority)
		else
			impact(position, speed, toyId, priority)
		end
	elseif kind == "Shatter" then
		play("shatter", position, 0.9, 1.1)
		sparks(position, 26, 2.4, ICE_COLORS)
		shakeAmount = math.max(shakeAmount, near * 0.5)
	elseif kind == "Break" then
		play("noodle", position, 0.75, 1.1)
		sparks(position, 6, 0.8)
		BloodFx.burst(position, 2.2) -- a limb snapping is the biggest splash
	elseif kind == "Land" and speed >= 40 then
		local power = math.clamp(speed / 50, 0.2, 1.5)
		play("land", position, 0.3 + 0.4 * power, 1.1 - 0.15 * power)
		sparks(position, math.floor(3 + 3 * power), 0.6 + 0.4 * power)
		shakeAmount = math.max(shakeAmount, near * 0.25 * power)
		BloodFx.landing(position, speed)
		if FeelV2.ON then
			FeelV2.flop(position, speed, near)
		end
	elseif kind == "Used" then
		-- Someone else threw or put something down: their avatar throws it.
		local thrower = sourceUserId and sourceUserId ~= localUserId and Players:GetPlayerByUserId(sourceUserId)
		if thrower then
			AvatarMoves.playRemote(thrower.Character, toyId)
		end
	elseif kind == "Place" then
		-- Your own prop or bomb lands where you tapped: a soft thunk and a puff, at once.
		play("land", position, 0.3, 1.5)
		sparks(position + Vector3.new(0, 0.5, 0), 5, 0.6, { Color3.fromRGB(240, 240, 250), Color3.fromRGB(200, 205, 220) })
	elseif kind == "Gift" then
		-- A present (round 3, M7): Christmas-coloured sparkles and a cheerful boing.
		sparks(position + Vector3.new(0, 0.8, 0), 16, 0.9, { Color3.fromRGB(230, 50, 60), Color3.fromRGB(255, 205, 70), Color3.fromRGB(70, 190, 100), Color3.fromRGB(250, 250, 255) })
		play("boing", position, 0.5, 1.2)
	elseif kind == "Event" then
		-- A server event starts: a fanfare-ish slide whistle and boing, no visuals (the banner is it).
		play("whistle", position, 0.55, 1.1)
		play("boing", position, 0.45, 0.9)
	elseif kind == "Limp" then
		-- Going limp on purpose: a soft cartoon flop.
		play("land", position, 0.35, 1.35)
		play("whoosh", position, 0.15, 0.7)
	elseif kind == "GetUp" then
		play("whoosh", position, 0.22, 1.7)
		sparks(position - Vector3.new(0, 2.5, 0), 4, 0.5)
	elseif kind == "Land" then
		local power = math.clamp(speed / 50, 0.2, 1.5)
		play("land", position, 0.3 + 0.4 * power, 1.1 - 0.15 * power)
		sparks(position, math.floor(3 + 3 * power), 0.6 + 0.4 * power)
		shakeAmount = math.max(shakeAmount, near * 0.25 * power)
		if FeelV2.ON then
			FeelV2.flop(position, speed, near)
		end
	end
end

-- Spinning parts (fan blades, the black hole's ring), kept in a set as they come and go.
local spinners: { [BasePart]: boolean } = {}
local function addSpinner(instance: Instance)
	if instance:IsA("BasePart") then
		spinners[instance] = true
	end
end
CollectionService:GetInstanceAddedSignal("Spinner"):Connect(addSpinner)
CollectionService:GetInstanceRemovedSignal("Spinner"):Connect(function(instance)
	spinners[instance :: BasePart] = nil
end)
for _, instance in CollectionService:GetTagged("Spinner") do
	addSpinner(instance)
end

local function spinBlades(dt: number)
	for blade in spinners do
		if blade:IsDescendantOf(Workspace) then
			blade.CFrame = blade.CFrame * CFrame.Angles(0, 0, dt * 25)
		end
	end
end

local function onRender(dt: number)
	spinBlades(dt)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if FeelV2.ON then
		-- v2: what was asked for this frame becomes trauma; the shake drawn is its square, smooth
		-- noise, with gun recoil (FeelV2.cameraStep reads the SETTINGS switch itself).
		if shakeAmount > 0.001 then
			FeelV2.addTrauma(shakeAmount * 0.45)
			shakeAmount = 0
		end
		local offset = FeelV2.cameraStep(dt)
		if offset ~= CFrame.identity then
			camera.CFrame = camera.CFrame * offset
		end
	end
	if shakeAmount > 0.001 and not Settings.shake() then
		shakeAmount = 0 -- (SETTINGS: camera shake off)
	end
	if shakeAmount > 0.001 then
		local a = shakeAmount
		camera.CFrame = camera.CFrame
			* CFrame.Angles(rng:NextNumber(-a, a) * 0.05, rng:NextNumber(-a, a) * 0.05, rng:NextNumber(-a, a) * 0.03)
		shakeAmount = math.max(0, shakeAmount - dt * 1.6)
	end
	-- (The only writer of FieldOfView: a hit's kick and the sprint's widening add up here.)
	baseFov = baseFov or camera.FieldOfView
	fovKick = math.max(0, fovKick - dt * 30)
	local target = (baseFov :: number) + FxController.fovExtra + FxController.fovZoom + (if fovKick > 0.01 then fovKick else 0) + (if FeelV2.ON then FeelV2.fovBeat else 0)
	if math.abs(camera.FieldOfView - target) > 0.01 then
		camera.FieldOfView = target
	end
end

-- Degrees the view is widened by others (round 4, M10: Sprint sets it while sprinting).
FxController.fovExtra = 0
FxController.fovZoom = 0 -- (round 5: a scope's zoom, GunFeel; apart from the sprint's fovExtra)

-- Plays an effect for a moment of this client's own simulation (landings, breaks, prop contacts).
function FxController.localEvent(kind: string, position: Vector3, speed: number, toyId: string)
	onFx(kind, position, speed, toyId, nil, nil, nil, true)
end

-- Round 4, M10: the trigger pulled before a gun is ready again (only guns with a dry click).
local lastDry = 0
function FxController.dryFire(toyId: string)
	local g = SoundManifest.GUNS[toyId]
	local now = os.clock()
	if not (g and g.dry) or now - lastDry < 0.15 then
		return
	end
	lastDry = now
	local from = gunOf(Players.LocalPlayer.Character)
	if from then
		play(g.dry, from.Position, 0.35, 1, { cut = 0.3, priority = true })
	end
end

-- Round 5: gold sparks (the Golden Deagle's head shot), and a blade's cut in the air.
function FxController.goldBurst(at: Vector3)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.CFrame = CFrame.new(at)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 170, 30))
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.35, 0)
	e.Speed = NumberRange.new(14, 26)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.Drag = 3
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Enabled = false
	e.Parent = holder
	holder.Parent = workspace:FindFirstChild("LocalFx") or workspace
	e:Emit(40)
	task.delay(1, function()
		holder:Destroy()
	end)
end

function FxController.slash(from: CFrame, color: Color3)
	local arc = Instance.new("Part")
	arc.Anchored = true
	arc.CanCollide = false
	arc.CanQuery = false
	arc.CanTouch = false
	arc.CastShadow = false
	arc.Material = Enum.Material.Neon
	arc.Color = color
	arc.Transparency = 0.25
	arc.Size = Vector3.new(4.5, 0.08, 1.2)
	arc.CFrame = from * CFrame.new(0, 0.6, -2.4) * CFrame.Angles(0, 0, math.rad(-30))
	arc.Parent = workspace:FindFirstChild("LocalFx") or workspace
	game:GetService("TweenService"):Create(arc, TweenInfo.new(0.18), { Transparency = 1, Size = Vector3.new(5.5, 0.04, 0.4), CFrame = arc.CFrame * CFrame.Angles(0, 0, math.rad(60)) }):Play()
	task.delay(0.2, function()
		arc:Destroy()
	end)
end

-- Round 5: a gun reloading (Ammo): its own reload recording at your gun, cut to the reload's time.
function FxController.reload(toyId: string, seconds: number)
	local g = SoundManifest.GUNS[toyId]
	if not (g and g.reload) then
		return
	end
	local from = gunOf(Players.LocalPlayer.Character)
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local at = if from then from.Position elseif root and root:IsA("BasePart") then root.Position else nil
	if at then
		play(g.reload, at, 0.55, 1, { cut = math.max(0.3, seconds), priority = true })
	end
end

-- Hit-stop for your own blows by hand (HitFeel has the numbers): the camera holds with the contact
-- pose. Stops share a budget, so a flurry never feels like lag.
local stops: { { at: number, length: number } } = {}
local frozenCamera: CFrame? = nil
local frozenUntil = 0

-- Takes a hit-stop of `length` from the budget; returns what was granted (0: none, over budget).
-- The caller holds the avatar's contact pose for exactly that long.
function FxController.takeHitStop(length: number): number
	if length <= 0 then
		return 0
	end
	local now = os.clock()
	local used = 0
	for i = #stops, 1, -1 do
		if now - stops[i].at > HitFeel.STOP_WINDOW then
			table.remove(stops, i)
		else
			used += stops[i].length
		end
	end
	if used + length > HitFeel.STOP_BUDGET then
		return 0
	end
	table.insert(stops, { at = now, length = length })
	return length
end

-- Holds the camera for a granted stop, at the contact. Not while you are walking: a camera that
-- stands still while the avatar walks on would judder (the pose hold is the stop then).
local function hitStop(length: number)
	if length <= 0 then
		return
	end
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
		return
	end
	local camera = Workspace.CurrentCamera
	if camera then
		frozenCamera = camera.CFrame
		frozenUntil = os.clock() + length
	end
end

bigStop = function(length: number)
	hitStop(FxController.takeHitStop(length))
end

-- Plays a hit effect immediately for the local player's own tap (server echo is then skipped).
-- stop: the hit-stop (s) granted for this hit (FxController.takeHitStop).
function FxController.predictHit(position: Vector3, speed: number, toyId: string, direction: Vector3?, stop: number?, byHand: boolean?)
	hitStop(stop or 0)
	local queue = predicted[toyId] or {}
	predicted[toyId] = queue
	table.insert(queue, os.clock())
	if #queue > 8 then
		table.remove(queue, 1)
	end
	onFx("Hit", position, speed, toyId, nil, direction, byHand == true, true)
end

function FxController.start()
	local folder = Instance.new("Folder")
	folder.Name = "LocalFx"
	folder.Parent = Workspace
	fxFolder = folder

	-- Round 4, M10: POOL loaded voices per asset, made now, so the first hit is never late or silent.
	-- An asset that fails to load (a community upload blocked live) leaves its bank, so the bank
	-- plays its other variants, or the gun's fallback once none is left.
	-- (The start bar's guns and the hit sounds first, so a phone hears its first shots soonest.)
	local preload: { Instance } = {}
	local function loadList(list: { string }?)
		for _, id in list or {} do
			if not free[id] then
				free[id] = {}
				count[id] = POOL
				for _ = 1, POOL do
					local voice = newVoice(id, true)
					table.insert(free[id], voice)
					table.insert(preload, voice.sound)
				end
			end
		end
	end
	for _, gun in { "G17", "Deagle", "Shotgun", "Revolver" } do
		local g = SoundManifest.GUNS[gun]
		if g then
			loadList(BANK[g.fire])
		end
	end
	for name, list in BANK do
		if string.find(string.lower(name), "hit") or string.find(string.lower(name), "punch") then
			loadList(list)
		end
	end
	for _, list in BANK do
		loadList(list)
	end
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync(preload, function(id: string, status: Enum.AssetFetchStatus)
			-- (Only a real failure: a slow phone's timeout keeps the id, a late play is dropped anyway.)
			if status == Enum.AssetFetchStatus.Failure then
				for _, list in BANK do
					local i = table.find(list, id)
					if i then
						table.remove(list, i)
					end
				end
			end
		end)
	end)

	FeelV2.play = function(bank: string, position: Vector3, volume: number, pitch: number)
		play(bank, position, volume, pitch)
	end
	Net.event(Net.Names.Fx).OnClientEvent:Connect(onFx)
	RunService:BindToRenderStep("RagdollLabFx", Enum.RenderPriority.Camera.Value + 1, onRender)
	-- The hit-stop holds the camera still for its few frames (after every other camera update).
	RunService:BindToRenderStep("RagdollLabHitStop", Enum.RenderPriority.Camera.Value + 5, function()
		local held = frozenCamera
		if held then
			if os.clock() < frozenUntil then
				local camera = Workspace.CurrentCamera
				if camera then
					camera.CFrame = held
				end
			else
				frozenCamera = nil
			end
		end
	end)
end

return FxController
