--!strict
-- Doctor mode and the hospital monitor (round 2, N3). V (Controls can change it) or the switch in
-- the TOOLS window turns doctor mode on: the tool bar steps aside, tools rest, and a bedside
-- monitor docks in the bar's place. Point at someone (a computer) or tap them (a touch screen) and
-- the monitor shows them, live:
--   the heart: its rate and an ECG trace sweeping across (a flat line when it stops), the rhythm
--   the pressure (NIBP), oxygen (SpO2), breathing (RESP), the blood left (mL and %), how awake they
--     are (GCS and a word), whether they bleed
--   their injuries: each organ or limb hit, newest first, with how long ago
-- The numbers come from what the server shares about every body (Blood, Pulse, Vital, Wounds,
-- Severed, Bleeding: VitalsService) through Anatomy.monitor, so every screen and the tests read the
-- same; the patient keeps an outline while it is on the monitor. V again (or the switch) leaves.
-- Not in the first minute (the tool bar is teaching then).
--
-- Round 3, M5 (a real bedside monitor): under the ECG the SpO2 pleth wave sweeps too (its height
-- follows the pressure: a weak pulse is a flat wave); a heart that just stopped fibrillates (VF)
-- before the line goes flat; the pressure is a cuff reading (NIBP) taken every NIBP_CYCLE s with
-- the time it was taken; temperature; the blood lost as an ATLS class (I-IV); the GCS in its parts
-- (E V M); a body map with each wound where it is (red: still bleeding); a beep with every beat whose
-- pitch falls with the oxygen (as a real monitor's does) and the alarm's triple beep when the patient
-- is critical or the heart has stopped. Numbers and classes from Anatomy.monitor (sources there).
--
-- Drawn in a ScreenGui in the CoreUISafeInsets frame, between the bar's side margins
-- (PokeController.sideMargin), at the bottom; HospitalCharts.plan sizes it for any screen (LayoutCheck
-- checks it on every phone, tablet and computer). The ECG is drawn as columns that a cursor
-- overwrites as it sweeps, like a real monitor: only the few columns it passes change each frame.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Anatomy = require(Shared:WaitForChild("Anatomy"))
local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))
local Settings = require(Client:WaitForChild("Settings"))
local PokeController = require(Client:WaitForChild("PokeController"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local ReplayController = require(Client:WaitForChild("ReplayController"))

local HospitalCharts = {}

HospitalCharts.MAX_W = 640
HospitalCharts.MIN_W = 260
HospitalCharts.WIDE_AT = 520 -- px: one row of tiles from this width
HospitalCharts.BOTTOM = 12
HospitalCharts.UPRIGHT_BOTTOM = 178 -- px: an upright phone's thumb row under it (JUMP, GRAB, THROW, RUN; RECENTER rests then, LabCamera)
HospitalCharts.SWEEP = 3 -- s for the trace to cross the strip
HospitalCharts.SLIDE = 40 -- px the monitor slides in from below
HospitalCharts.LEAVE = Vector2.new(84, 44) -- the LEAVE button (a touch screen's way out: the bar is away)
local COLUMN = 2 -- px per ECG column
local ERASE = 8 -- columns cleared ahead of the cursor
local LABEL_ROW = 16 -- px at the strip's top for its two labels (the trace stays under them)
local HOVER_RATE = 0.1 -- s between looks under the mouse
local MAX_DISTANCE = 160
local FIELDS = { "Blood", "Pulse", "Vital", "Wounds", "Severed", "Bleeding", "PersonName", "Role", "BrokenJoints", "Hits", "KOs", "Bones", "DiedAt", "DeathCause" }

-- Monitor colours (the convention at a bedside: the heart green, oxygen cyan, breath yellow), on a
-- near-black glass panel; alarms in red.
local INK = Color3.fromRGB(10, 12, 18)
local GREEN = Color3.fromRGB(90, 255, 140)
local CYAN = Color3.fromRGB(80, 220, 255)
local YELLOW = Color3.fromRGB(255, 220, 90)
local PURPLE = Color3.fromRGB(190, 130, 255) -- the game's blood
local WHITE = Color3.fromRGB(235, 238, 245)
local DIM = Color3.fromRGB(165, 171, 186)
local RED = Color3.fromRGB(255, 90, 90)
local ORANGE = Color3.fromRGB(255, 180, 80)
local SEVERITY_COLOUR = { Stable = GREEN, Serious = ORANGE, Critical = RED, Dead = DIM }

export type Plan = {
	size: Vector2,
	wide: boolean, -- one row of six tiles (else two rows of three)
	ecg: number, -- the strip's height
	header: number,
	tile: number, -- a tile's height
	injuries: number, -- the injury line's height
	body: number, -- the body map's column width (round 3, M5)
	bottom: number, -- px under it (an upright phone: over the thumb row)
}

-- The monitor's size on a screen of this size (pure: LayoutCheck runs it for every screen).
HospitalCharts.PHONE_SIDE = 150 -- px: on a phone, clear of the right-hand column (LAB VIEW, Replay)
function HospitalCharts.plan(screen: Vector2, touch: boolean, lab: boolean): Plan
	local phone = math.min(screen.X, screen.Y) <= 500
	local side = PokeController.sideMargin(touch, lab)
	if phone then
		side = math.max(side, HospitalCharts.PHONE_SIDE)
	end
	local upright = phone and screen.Y > screen.X
	if upright then
		side = 12 -- (an upright phone: the whole width, over the thumb row; PC LayoutCheck 19 Nov)
	end
	local w = math.clamp(screen.X - 2 * side, HospitalCharts.MIN_W, HospitalCharts.MAX_W)
	local wide = w >= HospitalCharts.WIDE_AT
	-- A phone is short: everything a little lower, so the monitor stays under the toasts.
	local header = if phone then 18 else 20
	-- (Taller than before: the ECG and the SpO2 wave share the strip.)
	local ecg = if wide then 84 elseif upright then 40 elseif phone then 50 else 62 -- (upright: under the toasts on a 360x780 Android)
	local tile = if wide then 40 elseif phone then 29 else 36
	local injuries = if phone then 16 else 18
	local rows = if wide then 1 else 2
	local h = 8 + header + 4 + ecg + 6 + rows * tile + (rows - 1) * 4 + 4 + injuries + 8
	local body = if wide then 54 elseif phone then 35 else 44
	return { size = Vector2.new(w, h), wide = wide, ecg = ecg, header = header, tile = tile, injuries = injuries, body = body,
		bottom = if upright then HospitalCharts.UPRIGHT_BOTTOM else HospitalCharts.BOTTOM }
end

-- The waves (round 3, M5 fix 1: shared, Anatomy, so the self-tests check them too).
HospitalCharts.ecgAt = Anatomy.ecgAt
HospitalCharts.vfAt = Anatomy.vfAt
HospitalCharts.plethAt = Anatomy.plethAt

-- How long ago, short: "12s", "2m".
local function ago(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds < 60 then
		return seconds .. "s"
	end
	return math.floor(seconds / 60) .. "m"
end

-- The joints that break (ActiveRagdoll: BrokenJoints) and the limb each one is in.
local BROKEN_LIMB = {
	LeftShoulder = "Left arm", LeftElbow = "Left arm", RightShoulder = "Right arm", RightElbow = "Right arm",
	LeftHip = "Left leg", LeftKnee = "Left leg", RightHip = "Right leg", RightKnee = "Right leg",
}

-- The injury line: limbs off, then wounds newest first (each organ or limb once, with how long ago
-- it was hit), then broken limbs.
function HospitalCharts.injuryText(wounds: { Anatomy.SharedWound }, severed: unknown, now: number, broken: unknown): string
	local parts: { string } = {}
	if type(severed) == "string" and severed ~= "" then
		for _, limb in string.split(severed, ",") do
			local spec = Anatomy.LIMBS[limb]
			if spec then
				table.insert(parts, spec.label .. " severed")
			end
		end
	end
	-- (A blow is a bruise there, not an organ wound: "Heart bruise 3s".)
	local seen: { [string]: boolean } = {}
	for i = #wounds, 1, -1 do
		local w = wounds[i]
		local key = w.zone.id .. (if w.blunt then "b" else "")
		if not seen[key] then
			seen[key] = true
			table.insert(parts, w.zone.label .. (if w.blunt then " bruise " else " ") .. ago(now - w.at))
		end
	end
	if type(broken) == "string" and broken ~= "" then
		local limbs: { [string]: boolean } = {}
		for _, joint in string.split(broken, ",") do
			local limb = BROKEN_LIMB[joint]
			if limb and not limbs[limb] then
				limbs[limb] = true
				table.insert(parts, limb .. " broken")
			end
		end
	end
	if #parts == 0 then
		return "No injuries"
	end
	return table.concat(parts, "  \u{00B7}  ")
end

local player = Players.LocalPlayer
local doctor = false
local patient: Model? = nil
local connections: { RBXScriptConnection } = {}
local hovered: Model? = nil
local lastLook = 0
local lostAt = -math.huge -- when the last patient went (dead and gone, or sent away)
local pointed = false -- the way to doctor mode was pointed out (or it was found): once a visit
local started = false -- this copy runs the player's monitor (start was called)
-- Round 4, M11 (the owner): outside doctor mode a computer sees the phone's small monitor by itself,
-- beside the mouse, while the mouse is on a dead body (Settings: DEAD MONITOR, on by default). Quiet
-- (no beeps), no LEAVE (it goes when the mouse leaves the body), the tool bar stays.
HospitalCharts.AUTO_SCREEN = Vector2.new(667, 375) -- the phone whose monitor it is (an iPhone SE)
HospitalCharts.AUTO_GRACE = 0.35 -- s off the body before it goes (no flicker between two limbs)
local auto = false
local autoSeenAt = 0
local endAuto: () -> () -- (the small monitor off: set below, where it is made)
local slideOut: Tween? = nil -- (doctor mode sliding away: cancelled if the small monitor takes the screen)

type Tile = { frame: Frame, label: TextLabel, value: TextLabel, sub: TextLabel }
type Ui = {
	gui: ScreenGui,
	panel: Frame,
	name: TextLabel,
	status: TextLabel,
	strip: Frame,
	rhythm: TextLabel,
	hr: TextLabel,
	heart: TextLabel,
	tiles: { [string]: Tile },
	injuries: TextLabel,
	record: TextLabel,
	empty: TextLabel,
	leave: TextButton,
	outline: Highlight,
	columns: { Frame },
	pleth: { Frame }, -- the SpO2 wave's columns (round 3, M5)
	map: Frame, -- the body map
	mapParts: { [string]: Frame },
	dots: { Frame },
	beep: Sound,
	alarm: Sound,
}
local ui: Ui? = nil
local plan: Plan? = nil

-- The trace's state: where the cursor is, the last height drawn, when the current beat began.
local cursor = 0
local lastY = 0
local beatAt = 0
local lastBeatAt = 0 -- (the beat before: a column from before this frame's new beat belongs to it)
local sweptAt = 0 -- os.clock() the strip was last drawn up to
local deadAlarms = 0 -- triple beeps sounded for this stopped heart (DEAD_ALARMS, then quiet)
local shownTemp: number? = nil -- the temperature on the screen, easing towards the reading
local shownTempAt = 0
HospitalCharts.TEMP_RATE = 0.02 -- degrees C a second the shown temperature moves (1.2 a minute)
local reading: Anatomy.Reading? = nil
local plethY = 0
local nibp: { systolic: number, diastolic: number, at: number, class: string }? = nil -- the last cuff reading
local alarmAt = 0

local function text(name: string, parent: Instance, font: Font, size: number, colour: Color3, xAlign: Enum.TextXAlignment?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.FontFace = font
	l.TextSize = size
	l.TextColor3 = colour
	l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

local TILES = { "NIBP", "SpO2", "RESP", "TEMP", "BLOOD", "GCS" }
-- (NIBP white, as a bedside monitor draws a cuff reading: a pink one read too close to an alarm.)
local TILE_COLOUR = { NIBP = WHITE, SpO2 = CYAN, RESP = YELLOW, TEMP = WHITE, BLOOD = PURPLE, GCS = WHITE }
local TILE_UNIT = { NIBP = "mmHg", SpO2 = "%", RESP = "/min", TEMP = "\u{00B0}C", BLOOD = "", GCS = "" }
HospitalCharts.TILES = TILES
HospitalCharts.GCS_SPLIT = 0.32
HospitalCharts.BLOOD_SPLIT = 0.62
HospitalCharts.LABEL_MIN = 9 -- px: a tile's label shrinks to this, no smaller
local SPLIT: { [string]: number } = { BLOOD = HospitalCharts.BLOOD_SPLIT, GCS = HospitalCharts.GCS_SPLIT } -- the value's share of a tile with a word
HospitalCharts.NIBP_CYCLE = 15 -- s between cuff readings (a real monitor: every few minutes; a game: quicker)
HospitalCharts.ALARM_GAP = { Critical = 4, Dead = 2 } -- s between the alarm's triple beeps
-- A stopped heart sounds its alarm this many times, then the monitor goes quiet (the flat line and
-- the red stay): a game is not a ward, and a body left dead must not beep for ever.
HospitalCharts.DEAD_ALARMS = 3
HospitalCharts.SHORT_RHYTHM = {
	["Sinus tachycardia"] = "Sinus tachy",
	["Sinus bradycardia"] = "Sinus brady",
	["Ventricular fibrillation"] = "V-fib",
} :: { [string]: string }

-- The s until the next triple beep may sound (nil: none): only while the monitor is up, a stopped
-- heart DEAD_ALARMS times at most (pure: LayoutCheck checks it).
function HospitalCharts.alarmGap(severity: string?, audible: boolean, deadAlarms: number): number?
	if not audible or severity == nil then
		return nil
	end
	if severity == "Dead" and deadAlarms >= HospitalCharts.DEAD_ALARMS then
		return nil
	end
	return HospitalCharts.ALARM_GAP[severity]
end
-- The beep: Pro Sound Effects "Nasa Transmission Beep 1 (SFX)", cut short; its pitch follows SpO2.
local BEEP_ID = "rbxassetid://9117060347"
local BEEP_LENGTH = 0.11 -- s

-- The body map (round 3, M5): where on a front-view figure each wound zone is, in a 40 x 100 box
-- (the patient faces you: their left is on your right).
HospitalCharts.MAP_POINT = {
	Brain = Vector2.new(20, 5), Skull = Vector2.new(20, 3), Jaw = Vector2.new(20, 13), Neck = Vector2.new(20, 17),
	Heart = Vector2.new(23, 26), Aorta = Vector2.new(20, 30), LeftLung = Vector2.new(25, 25), RightLung = Vector2.new(15, 25),
	Liver = Vector2.new(15, 36), Stomach = Vector2.new(24, 35), Spine = Vector2.new(20, 40), LeftKidney = Vector2.new(25, 42),
	RightKidney = Vector2.new(15, 42), Intestines = Vector2.new(20, 45), Pelvis = Vector2.new(20, 50), Blast = Vector2.new(20, 32),
	LeftUpperArm = Vector2.new(32.5, 25), LeftForearm = Vector2.new(32.5, 37), LeftHand = Vector2.new(32.5, 48),
	RightUpperArm = Vector2.new(7.5, 25), RightForearm = Vector2.new(7.5, 37), RightHand = Vector2.new(7.5, 48),
	LeftArmStump = Vector2.new(30, 20), RightArmStump = Vector2.new(10, 20), -- (the shoulder: the arm is gone)
	LeftThigh = Vector2.new(24.5, 60), LeftFemoral = Vector2.new(23, 63), LeftShin = Vector2.new(24.5, 80), LeftFoot = Vector2.new(24.5, 95),
	RightThigh = Vector2.new(15.5, 60), RightFemoral = Vector2.new(17, 63), RightShin = Vector2.new(15.5, 80), RightFoot = Vector2.new(15.5, 95),
}
-- The figure's parts in the same box: { x, y, w, h } (the head round).
local MAP_PARTS: { [string]: { number } } = {
	Head = { 13, 0, 14, 15 }, Torso = { 11, 18, 18, 35 },
	LeftArm = { 30, 19, 5, 32 }, RightArm = { 5, 19, 5, 32 },
	LeftLeg = { 21, 54, 7, 45 }, RightLeg = { 12, 54, 7, 45 },
}
local MAX_DOTS = 8

local function build(): Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "DoctorMonitor"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 7
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Enabled = false
	local panel = Instance.new("Frame")
	panel.Name = "Monitor"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -(if plan then plan.bottom else HospitalCharts.BOTTOM))
	panel.BackgroundColor3 = INK
	panel.BackgroundTransparency = 0.12
	panel.Active = true -- (taps on it never reach the world behind)
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.Palette.ink
	stroke.Parent = panel

	local name = text("Patient", panel, Theme.Fonts.bodySemi, 15, WHITE)

	local strip = Instance.new("Frame")
	strip.Name = "Ecg"
	strip.BackgroundColor3 = Color3.fromRGB(4, 8, 6)
	strip.BackgroundTransparency = 0.2
	strip.ClipsDescendants = true
	strip.Parent = panel
	local stripCorner = Instance.new("UICorner")
	stripCorner.CornerRadius = UDim.new(0, 6)
	stripCorner.Parent = strip
	local rhythm = text("Rhythm", strip, Theme.Fonts.bodySemi, 12, DIM)
	rhythm.Position = UDim2.fromOffset(6, 2)
	rhythm.Size = UDim2.new(0.6, -6, 0, 14)
	rhythm.ZIndex = 3
	-- How the patient is, in a word, in the strip's other top corner.
	local status = text("Status", strip, Theme.Fonts.display, 13, GREEN, Enum.TextXAlignment.Right)
	status.Position = UDim2.new(0.6, 0, 0, 2)
	status.Size = UDim2.new(0.4, -6, 0, 14)
	status.ZIndex = 3

	local hr = text("HeartRate", panel, Theme.Fonts.display, 30, GREEN, Enum.TextXAlignment.Right)
	local heart = text("Beat", panel, Theme.Fonts.display, 14, GREEN, Enum.TextXAlignment.Right)

	local tiles: { [string]: Tile } = {}
	for _, key in TILES do
		local f = Instance.new("Frame")
		f.Name = key
		f.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
		f.BackgroundTransparency = 0.15
		f.Parent = panel
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = f
		local label = text("Label", f, Theme.Fonts.bodySemi, 12, DIM)
		label.Text = key .. (if TILE_UNIT[key] ~= "" then " " .. TILE_UNIT[key] else "")
		label.Position = UDim2.fromOffset(6, 1)
		label.Size = UDim2.new(1, -12, 0, 13)
		-- (A narrow tile shrinks its label to 9 px rather than cut the cuff's time or the GCS parts.)
		label.TextScaled = true
		local labelFit = Instance.new("UITextSizeConstraint")
		labelFit.MinTextSize = HospitalCharts.LABEL_MIN
		labelFit.MaxTextSize = 12
		labelFit.Parent = label
		local value = text("Value", f, Theme.Fonts.display, 18, TILE_COLOUR[key])
		value.Position = UDim2.new(0, 6, 0, 13)
		value.Size = UDim2.new(1, -12, 1, -14)
		-- The value and its word each have their own part of the tile (they never run into each
		-- other on a narrow tile): the blood's litres take most of it, the GCS's word most of it.
		local sub = text("Sub", f, Theme.Fonts.bodySemi, 12, DIM, Enum.TextXAlignment.Right)
		local split = SPLIT[key]
		if split then
			value.Size = UDim2.new(split, -6, 1, -14)
			sub.Position = UDim2.new(split, 0, 0, 13)
			sub.Size = UDim2.new(1 - split, -6, 1, -14)
			local fit = Instance.new("UITextSizeConstraint")
			fit.MinTextSize = 9
			fit.MaxTextSize = 12
			fit.Parent = sub
			sub.TextScaled = true
		else
			sub.Visible = false
		end
		tiles[key] = { frame = f, label = label, value = value, sub = sub }
	end
	local injuries = text("Injuries", panel, Theme.Fonts.bodySemi, 13, WHITE)
	injuries.RichText = true -- (BLEEDING in red at its start)
	-- The body map: a plain figure, the wounds on it as dots.
	local map = Instance.new("Frame")
	map.Name = "BodyMap"
	map.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	map.BackgroundTransparency = 0.15
	map.Parent = panel
	local mapCorner = Instance.new("UICorner")
	mapCorner.CornerRadius = UDim.new(0, 6)
	mapCorner.Parent = map
	local mapParts: { [string]: Frame } = {}
	for partName in MAP_PARTS do
		local f = Instance.new("Frame")
		f.Name = partName
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.fromRGB(70, 78, 98)
		f.Parent = map
		local c = Instance.new("UICorner")
		c.CornerRadius = if partName == "Head" then UDim.new(1, 0) else UDim.new(0, 3)
		c.Parent = f
		mapParts[partName] = f
	end
	local dots: { Frame } = {}
	for i = 1, MAX_DOTS do
		local d = Instance.new("Frame")
		d.Name = "Wound" .. i
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.BorderSizePixel = 0
		d.Visible = false
		d.ZIndex = 3
		d.Parent = map
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = d
		local edge = Instance.new("UIStroke")
		edge.Color = INK
		edge.Thickness = 1
		edge.Parent = d
		table.insert(dots, d)
	end
	local function sound(name: string): Sound
		local snd = Instance.new("Sound")
		snd.Name = name
		snd.SoundId = BEEP_ID
		snd.Volume = 0.2
		snd.SoundGroup = Settings.effects() -- (SETTINGS: sound effects normal, quiet or off)
		snd.Parent = gui
		return snd
	end
	local beep, alarm = sound("Beep"), sound("Alarm")
	-- The patient's record so far (hits, knock-outs, bones broken), quiet at the line's end.
	local record = text("Record", panel, Theme.Fonts.bodySemi, 12, DIM, Enum.TextXAlignment.Right)
	local empty = text("Empty", panel, Theme.Fonts.display, 16, WHITE, Enum.TextXAlignment.Center)
	empty.ZIndex = 4
	-- LEAVE: a pill in the panel's top-right corner (a touch screen's way out: the bar, and its
	-- TOOLS, is away). The tap target is 44 px tall (the touch floor) and reaches down over the
	-- heart's corner, which nothing else uses.
	local leave = Instance.new("TextButton")
	leave.Name = "Leave"
	leave.AnchorPoint = Vector2.new(1, 0)
	leave.Position = UDim2.new(1, -4, 0, 0)
	leave.Size = UDim2.fromOffset(HospitalCharts.LEAVE.X, HospitalCharts.LEAVE.Y)
	leave.BackgroundTransparency = 1
	leave.Text = ""
	leave.ZIndex = 5
	leave.Parent = panel
	local pill = Instance.new("TextLabel")
	pill.Name = "Pill"
	pill.AnchorPoint = Vector2.new(1, 0)
	pill.Position = UDim2.new(1, -4, 0, 4)
	pill.Size = UDim2.fromOffset(HospitalCharts.LEAVE.X - 10, 26)
	pill.BackgroundColor3 = Theme.Palette.dusk
	pill.TextColor3 = WHITE
	pill.FontFace = Theme.Fonts.display
	pill.TextSize = 15
	pill.Text = "LEAVE"
	pill.ZIndex = 5
	-- (The kit's look, like LAB VIEW and RAGDOLL: an ink outline and the kit's corner.)
	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(0, 8)
	pillCorner.Parent = pill
	local pillEdge = Instance.new("UIStroke")
	pillEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillEdge.Color = Theme.Palette.ink
	pillEdge.Thickness = 2
	pillEdge.Parent = pill
	local pillText = Instance.new("UIStroke")
	pillText.Color = Theme.Palette.ink
	pillText.Thickness = 1.5
	pillText.Parent = pill
	pill.Parent = leave
	leave.Activated:Connect(function()
		HospitalCharts.setDoctor(false)
	end)

	local outline = Instance.new("Highlight")
	outline.Name = "PatientOutline"
	outline.FillTransparency = 1
	outline.OutlineColor = GREEN
	outline.OutlineTransparency = 0.15
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = player:WaitForChild("PlayerGui")
	gui.Parent = player:WaitForChild("PlayerGui")
	return {
		gui = gui, panel = panel, name = name, status = status, strip = strip, rhythm = rhythm,
		hr = hr, heart = heart, tiles = tiles, injuries = injuries, record = record, empty = empty, leave = leave, outline = outline,
		columns = {}, pleth = {}, map = map, mapParts = mapParts, dots = dots, beep = beep, alarm = alarm,
	}
end

-- A tile's width in a plan (LayoutCheck measures the labels against it).
function HospitalCharts.tileWidth(p: Plan): number
	local perRow = if p.wide then 6 else 3
	return (p.size.X - 16 - (p.body + 6) - (perRow - 1) * 4) / perRow
end

-- Where the body map's figure is drawn (set by layout).
local mapScale = 1
local mapOrigin = Vector2.zero

-- Lays the monitor out for this screen (and rebuilds the trace's columns for the strip's width).
local previewScreen: Vector2? = nil -- (captures: a phone-sized frame instead of this screen)
local previewTouch: boolean? = nil
local function layout()
	local u = ui
	if not u then
		return
	end
	-- (The ScreenGui's own size: the safe-area frame it draws in, which LayoutCheck checks.)
	local screen = previewScreen or (if auto then HospitalCharts.AUTO_SCREEN else u.gui.AbsoluteSize)
	if screen.X < 1 or screen.Y < 1 then
		return -- (not measured yet: its size signal lays it out)
	end
	local touch = if previewTouch ~= nil then previewTouch elseif auto then true else ViewMode.isTouch()
	u.leave.Visible = not auto
	local p = HospitalCharts.plan(screen, touch, ViewMode.isLab())
	plan = p
	local w = p.size.X
	u.panel.Size = UDim2.fromOffset(w, p.size.Y)
	if not auto then
		u.panel.Position = UDim2.new(0.5, 0, 1, -p.bottom) -- (turned upright or back: over the thumb row or not)
	end
	local y = 8
	u.name.Position = UDim2.fromOffset(10, y)
	u.name.Size = UDim2.new(1, -(20 + (if auto then 0 else HospitalCharts.LEAVE.X)), 0, p.header)
	u.name.TextSize = if p.header < 20 then 14 else 15
	y += p.header + 4
	local hrW = if p.wide then 96 else 74
	local bodyCol = p.body + 6 -- (the body map's column on the right, beside the strip and the tiles)
	local mapTop = y
	u.strip.Position = UDim2.fromOffset(8, y)
	u.strip.Size = UDim2.fromOffset(w - 16 - hrW - 6 - bodyCol, p.ecg)
	u.hr.Position = UDim2.new(1, -8 - hrW - bodyCol, 0, y + 10)
	u.hr.Size = UDim2.fromOffset(hrW, p.ecg - 14)
	u.hr.TextSize = if p.wide then 40 else 30
	u.heart.Position = UDim2.new(1, -8 - hrW - bodyCol, 0, y - 1)
	u.heart.Size = UDim2.fromOffset(hrW, 14)
	y += p.ecg + 6
	local perRow = if p.wide then 6 else 3
	local tileW = HospitalCharts.tileWidth(p)
	for i, key in TILES do
		local col = (i - 1) % perRow
		local row = (i - 1) // perRow
		local t = u.tiles[key]
		t.frame.Position = UDim2.fromOffset(8 + col * (tileW + 4), y + row * (p.tile + 4))
		t.frame.Size = UDim2.fromOffset(tileW, p.tile)
		t.value.TextSize = if p.wide then 20 else 17
	end
	local rows = if p.wide then 1 else 2
	y += rows * p.tile + (rows - 1) * 4 + 4
	-- The body map: beside the strip and the tiles, as tall as both; the figure scaled into it.
	local mapH = y - 4 - mapTop
	u.map.Position = UDim2.new(1, -8 - p.body, 0, mapTop)
	u.map.Size = UDim2.fromOffset(p.body, mapH)
	local scale = math.min((p.body - 6) / 40, (mapH - 6) / 100)
	local ox, oy = (p.body - 40 * scale) / 2, (mapH - 100 * scale) / 2
	for partName, box in MAP_PARTS do
		local f = u.mapParts[partName]
		f.Position = UDim2.fromOffset(ox + box[1] * scale, oy + box[2] * scale)
		f.Size = UDim2.fromOffset(math.max(2, box[3] * scale), math.max(2, box[4] * scale))
	end
	mapScale, mapOrigin = scale, Vector2.new(ox, oy)
	local dotSize = math.max(5, math.floor(6 * scale + 0.5))
	for _, d in u.dots do
		d.Size = UDim2.fromOffset(dotSize, dotSize)
	end
	-- The record shares the line on a wide monitor; a narrow one gives the injuries the whole line
	-- (they matter more, and broken limbs are in them).
	local recordW = if p.wide then 170 else 0
	u.injuries.Position = UDim2.fromOffset(10, y)
	u.injuries.Size = UDim2.new(1, -(20 + (if p.wide then recordW + 4 else 0)), 0, p.injuries)
	u.record.Visible = p.wide
	u.record.Position = UDim2.new(1, -(10 + recordW), 0, y)
	u.record.Size = UDim2.fromOffset(recordW, p.injuries)
	-- The prompt with nobody on the monitor: across the top of the strip, over a flat line.
	u.empty.Position = UDim2.fromOffset(8, 8 + p.header + 4)
	u.empty.Size = UDim2.new(1, -16, 0, math.floor(p.ecg * 0.5))
	-- The trace's columns: thin bars, one per COLUMN px. (Round 4, M11: made again only when the
	-- strip's width changes, never on every show of the small monitor.)
	local count = math.max(1, math.floor(u.strip.Size.X.Offset / COLUMN))
	if #u.columns == count and #u.pleth == count then
		return
	end
	for _, list in { u.columns, u.pleth } do
		for _, c in list do
			c:Destroy()
		end
		table.clear(list)
	end
	for _, pair in { { u.columns, GREEN, "C" }, { u.pleth, CYAN, "P" } } do
		for i = 1, count do
			local c = Instance.new("Frame")
			c.Name = pair[3]
			c.BorderSizePixel = 0
			c.BackgroundColor3 = pair[2]
			c.Visible = false
			c.Position = UDim2.fromOffset((i - 1) * COLUMN, 0)
			c.Size = UDim2.fromOffset(COLUMN, 2)
			c.ZIndex = 2
			c.Parent = u.strip
			table.insert(pair[1], c)
		end
	end
	cursor = 0
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Every number on the monitor from the patient's attributes.
local function redraw()
	local u = ui
	if not u then
		return
	end
	local m = patient
	if not m or not m.Parent then
		reading = nil
		u.empty.Visible = true
		local prompt = if ViewMode.isTouch() then "Tap someone to check them" else "Point at someone to check them"
		u.empty.Text = if os.clock() - lostAt < 6 then "Patient gone. " .. prompt else prompt
		u.name.Text = "DOCTOR MODE"
		u.status.Text = ""
		u.rhythm.Text = ""
		u.hr.Text = "--"
		u.hr.TextColor3 = DIM
		u.injuries.Text = ""
		u.record.Text = ""
		for _, t in u.tiles do
			t.value.Text = "--"
			t.value.TextColor3 = DIM
			t.sub.Text = ""
		end
		for _, d in u.dots do
			d.Visible = false
		end
		nibp = nil
		return
	end
	u.empty.Visible = false
	local blood = m:GetAttribute("Blood")
	local pulse = m:GetAttribute("Pulse")
	local vital = m:GetAttribute("Vital")
	-- A body never hit has its whole blood and a steady heart (the server starts its record at the
	-- first hit).
	local b = if type(blood) == "number" then blood else 100
	local hrNow = if type(pulse) == "number" then pulse else 72
	local v = if type(vital) == "string" then vital else "Alive"
	local wounds = Anatomy.parseWounds(m:GetAttribute("Wounds"))
	-- (Round 4, M10: a brain kill is flat at once, Anatomy.stoppedFor.)
	local r = Anatomy.monitor(b, hrNow, v, wounds, Anatomy.stoppedFor(m:GetAttribute("DiedAt"), m:GetAttribute("DeathCause"), now()))
	reading = r
	-- The cuff: a reading now and then (and at once for a new patient), shown with when it was taken.
	local clock = now()
	-- (And at once when the blood-loss class changes: a normal reading never stands beside class IV.)
	if not nibp or clock - (nibp :: any).at >= HospitalCharts.NIBP_CYCLE or (r.systolic == 0) ~= ((nibp :: any).systolic == 0) or (nibp :: any).class ~= r.hemorrhage then
		nibp = { systolic = r.systolic, diastolic = r.diastolic, at = clock, class = r.hemorrhage }
	end
	local cuff = nibp :: { systolic: number, diastolic: number, at: number, class: string }
	local personName = m:GetAttribute("PersonName")
	local role = m:GetAttribute("Role")
	local persona = m:GetAttribute("Personality")
	u.name.Text = (if type(personName) == "string" then personName else "Lab dummy")
		.. (if type(role) == "string" then "  \u{00B7}  " .. string.upper(role) else "")
		.. (if type(persona) == "string" then "  \u{00B7}  " .. string.upper(persona) else "")
	u.status.Text = string.upper(r.severity)
	u.status.TextColor3 = SEVERITY_COLOUR[r.severity] or WHITE
	-- (A narrow monitor shares the line with the state: the short forms monitors print.)
	local narrow = plan ~= nil and not plan.wide
	local rhythmText = if narrow then (HospitalCharts.SHORT_RHYTHM[r.rhythm] or r.rhythm) else r.rhythm
	-- (The clinical note follows the rhythm on a wide monitor; a narrow one has no room there and
	-- puts it first on the findings line.)
	local note = r.note
	if note and not narrow then
		rhythmText ..= "  \u{00B7}  " .. string.lower(note)
	end
	u.rhythm.Text = rhythmText
	-- The core temperature moves slowly (a body cools over minutes, not seconds): the shown value
	-- eases towards the reading.
	if r.temp then
		local target = r.temp :: number
		local nowT = os.clock()
		local shown = shownTemp or target
		local step = HospitalCharts.TEMP_RATE * math.max(0, nowT - shownTempAt)
		shownTemp = shown + math.clamp(target - shown, -step, step)
		shownTempAt = nowT
	end
	u.hr.Text = if r.hr > 0 then tostring(r.hr) else "0"
	-- (The number takes the patient's colour: it never reads green while the monitor says CRITICAL.)
	u.hr.TextColor3 = if r.hr <= 0 then RED else (SEVERITY_COLOUR[r.severity] or GREEN)
	local t = u.tiles
	t.NIBP.value.Text = if cuff.systolic > 0 then string.format("%d/%d", cuff.systolic, cuff.diastolic) else "--/--"
	t.NIBP.value.TextColor3 = if cuff.systolic < 90 then RED else WHITE
	t.NIBP.label.Text = "NIBP " .. os.date("%H:%M:%S", math.floor(cuff.at))
	t.SpO2.value.Text = if r.spo2 then tostring(r.spo2) else "--"
	t.SpO2.value.TextColor3 = if r.spo2 == nil or (r.spo2 :: number) < 90 then RED else CYAN
	t.RESP.value.Text = tostring(r.resp)
	t.RESP.value.TextColor3 = if r.resp < 8 or r.resp > 30 then RED else YELLOW
	local temp = if r.temp then shownTemp else nil
	t.TEMP.value.Text = if temp then string.format("%.1f", temp :: number) else "--"
	t.TEMP.value.TextColor3 = if temp == nil then DIM elseif (temp :: number) < 35 then RED elseif (temp :: number) < 36 then ORANGE else WHITE
	t.BLOOD.value.Text = string.format("%.1f L", r.bloodMl / 1000)
	t.BLOOD.label.Text = "BLOOD " .. r.bloodPct .. "%"
	t.BLOOD.sub.Text = if r.hemorrhage ~= "" then "CL " .. r.hemorrhage else ""
	t.BLOOD.sub.TextColor3 = if r.hemorrhage == "IV" or r.hemorrhage == "III" then RED elseif r.hemorrhage == "II" then ORANGE else DIM
	t.BLOOD.value.TextColor3 = if r.bloodPct < 60 then RED else PURPLE
	t.GCS.value.Text = tostring(r.gcs)
	t.GCS.label.Text = string.format("GCS E%d V%d M%d", r.eyes, r.verbal, r.motor)
	t.GCS.sub.Text = r.consciousness
	t.GCS.value.TextColor3 = if r.gcs <= 8 then RED elseif r.gcs < 15 then ORANGE else WHITE
	local bleeding = m:GetAttribute("Bleeding") == true and r.severity ~= "Dead"
	local injuries = HospitalCharts.injuryText(wounds, m:GetAttribute("Severed"), now(), m:GetAttribute("BrokenJoints"))
	-- (Escaped for the rich text the line is drawn with.)
	injuries = string.gsub(string.gsub(string.gsub(injuries, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")
	if bleeding then
		injuries = '<font color="#FF5A5A">BLEEDING</font>  \u{00B7}  ' .. injuries
	end
	if r.note and plan and not plan.wide then
		injuries = string.lower(r.note) .. "  \u{00B7}  " .. injuries
	end
	-- The body map: each wound where it is (newest last), red while it bleeds, a bruise orange,
	-- a closed wound purple; a limb torn off fades.
	local shown = 0
	for i = #wounds, 1, -1 do
		local w = wounds[i]
		local at = HospitalCharts.MAP_POINT[w.zone.id]
		if at and shown < MAX_DOTS then
			shown += 1
			local d = u.dots[shown]
			d.Visible = true
			d.Position = UDim2.fromOffset(mapOrigin.X + at.X * mapScale, mapOrigin.Y + at.Y * mapScale)
			d.BackgroundColor3 = if w.blunt then ORANGE elseif w.open then RED else PURPLE
		end
	end
	for i = shown + 1, MAX_DOTS do
		u.dots[i].Visible = false
	end
	local severed = m:GetAttribute("Severed")
	for partName, f in u.mapParts do
		f.BackgroundTransparency = if type(severed) == "string" and string.find(severed, partName, 1, true) then 0.8 else 0
	end
	local function count(key: string): number
		local n = m:GetAttribute(key)
		return if type(n) == "number" then n else 0
	end
	local hits, kos, bones = count("Hits"), count("KOs"), count("Bones")
	u.record.Text = string.format("%d hit%s \u{00B7} %d KO \u{00B7} %d bone%s", hits, if hits == 1 then "" else "s", kos, bones, if bones == 1 then "" else "s")
	-- A narrow monitor has no room beside the injuries: the hits come last on their line.
	u.injuries.Text = if plan and not plan.wide then injuries .. "  \u{00B7}  " .. hits .. (if hits == 1 then " hit" else " hits") else injuries
	u.outline.OutlineColor = SEVERITY_COLOUR[r.severity] or GREEN
end

local function watch(model: Model?)
	if model == patient then
		return
	end
	for _, c in connections do
		c:Disconnect()
	end
	table.clear(connections)
	patient = model
	nibp = nil -- (a new patient's cuff reading at once, never the last one's)
	shownTemp = nil -- (and its own temperature at once)
	deadAlarms = 0
	alarmAt = 0
	local u = ui
	if u then
		u.outline.Adornee = model
	end
	if model then
		for _, key in FIELDS do
			table.insert(connections, model:GetAttributeChangedSignal(key):Connect(redraw))
		end
		table.insert(connections, model.Destroying:Connect(function()
			lostAt = os.clock()
			-- (The small monitor goes with its body: it never shows an empty "Patient gone".)
			if auto then
				endAuto()
			else
				watch(nil)
			end
		end))
	end
	redraw()
end

-- The body (a dummy or a person) a screen point is on, if any.
local bodyParams = RaycastParams.new()
bodyParams.FilterType = Enum.RaycastFilterType.Exclude
local function bodyAt(screen: Vector2, inset: boolean): Model?
	local camera = Workspace.CurrentCamera
	local dummies = Workspace:FindFirstChild("Dummies")
	if not camera or not dummies then
		return nil
	end
	local ray = if inset then camera:ScreenPointToRay(screen.X, screen.Y) else camera:ViewportPointToRay(screen.X, screen.Y)
	local params = bodyParams
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, params)
	if not hit then
		return nil
	end
	local node: Instance? = hit.Instance
	while node and node.Parent ~= dummies do
		node = node.Parent
	end
	return if node and node:IsA("Model") then node else nil
end

-- Whether the mouse is on something of the HUD a click would land on (a button, a window, the
-- monitor): not just any GuiObject, since an invisible full-screen frame (a flash waiting to play)
-- covers everything.
local function overUi(at: Vector2): boolean
	for _, o in player:WaitForChild("PlayerGui"):GetGuiObjectsAtPosition(at.X, at.Y - GuiService:GetGuiInset().Y) do
		local gui = o:FindFirstAncestorWhichIsA("LayerCollector")
		-- (The crosshair rides on the mouse itself, and so does the small monitor: never something
		-- the mouse is "on".)
		if gui and gui:IsA("ScreenGui") and (not gui.Enabled or gui.Name == "Crosshair" or (auto and gui.Name == "DoctorMonitor")) then
			continue
		end
		if o:IsA("GuiButton") or o.Active or o.BackgroundTransparency < 0.95 then
			return true
		end
	end
	return false
end

-- One frame of the trace: the cursor moves on, each column it passes gets the heart's height then,
-- and a few columns ahead are cleared.
local function sweep(dt: number)
	local u, p = ui, plan
	if not u or not p or #u.columns == 0 then
		return
	end
	local count = #u.columns
	-- The ECG over the top 60% of the strip (under its labels), the SpO2 wave under it.
	local area = (p.ecg - LABEL_ROW - 2) * 0.6
	local plethTop = LABEL_ROW + area + 2
	local plethArea = p.ecg - plethTop - 3
	local r = reading
	local rate = if r then r.hr else 0
	local period = if rate > 0 then 60 / rate else math.huge
	local tNow = os.clock()
	-- Sounds only while the monitor is up (not under a replay, which has the screen).
	local audible = doctor and patient ~= nil and u.gui.Enabled
	if rate > 0 and tNow - beatAt >= period then
		-- (On the beat's own time, not this frame's, so the trace keeps its rhythm; a long gap, a
		-- new patient, starts afresh.)
		lastBeatAt = beatAt
		beatAt = if tNow - beatAt < 2 * period then beatAt + period else tNow
		u.heart.Text = "\u{2665}"
		u.heart.TextTransparency = 0
		-- The beep with the beat; lower as the oxygen falls (a real monitor's way of telling it).
		if audible then
			local spo2 = if r and r.spo2 then r.spo2 :: number else 98
			u.beep.PlaybackSpeed = math.clamp(1 - (98 - spo2) * 0.015, 0.6, 1.05)
			u.beep.TimePosition = 0
			u.beep:Play()
			task.delay(BEEP_LENGTH, function()
				u.beep:Stop()
			end)
		end
	else
		u.heart.TextTransparency = math.min(1, (tNow - beatAt) * 3)
	end
	-- The alarm: three quick high beeps every few seconds while critical, faster when the heart has
	-- stopped (DEAD_ALARMS times, then quiet).
	local severity = if r then r.severity else nil
	if severity ~= "Dead" then
		deadAlarms = 0
	end
	local gap = HospitalCharts.alarmGap(severity, audible, deadAlarms)
	if gap and tNow - alarmAt >= gap then
		alarmAt = tNow
		if severity == "Dead" then
			deadAlarms += 1
		end
		task.spawn(function()
			for _ = 1, 3 do
				u.alarm.PlaybackSpeed = 1.45
				u.alarm.TimePosition = 0
				u.alarm:Play()
				task.wait(BEEP_LENGTH)
				u.alarm:Stop()
				task.wait(0.06)
			end
		end)
	end
	-- (Ventricular fibrillation: since the heart stopped, the server's DiedAt.)
	local vfAge = 0
	if r and r.vf and patient then
		local diedAt = patient:GetAttribute("DiedAt")
		vfAge = if type(diedAt) == "number" then now() - diedAt else 0
	end
	-- The pleth's height follows the pressure (a weak pulse is a small wave; none, a flat line).
	local perfusion = if r then math.clamp((r.systolic - 40) / 80, 0, 1) else 0
	local step = count / HospitalCharts.SWEEP * dt
	local from = cursor
	cursor += step
	local colour = if r == nil then DIM elseif rate <= 0 then RED else GREEN
	-- Each column covers its own stretch of time (this frame spread over the columns it crosses),
	-- and is drawn from the lowest to the highest point of the trace in it (Anatomy.ecgSpan), so a
	-- QRS shorter than a column still shows as its spike.
	local perColumn = HospitalCharts.SWEEP / count
	local frameStart = if sweptAt > 0 and tNow - sweptAt < 0.5 then sweptAt else tNow - dt
	sweptAt = tNow
	for i = math.floor(from) + 1, math.floor(cursor) do
		local index = (i % count) + 1
		local tEnd = math.clamp(frameStart + (i - from) / math.max(step, 1e-6) * (tNow - frameStart), frameStart, tNow)
		local tStart = tEnd - perColumn
		local function sinceBeat(t: number): number
			return if t >= beatAt then t - beatAt else t - lastBeatAt
		end
		local lo, hi, value = 0, 0, 0
		if r == nil then
			lo, hi, value = 0, 0, 0
		elseif r.vf then
			value = HospitalCharts.vfAt(tEnd, vfAge)
			local before = HospitalCharts.vfAt(tStart, vfAge)
			lo, hi = math.min(value, before), math.max(value, before)
		elseif rate > 0 then
			local a = sinceBeat(tStart)
			lo, hi, value = Anatomy.ecgSpan(a, a + perColumn, period)
		end
		-- A little noise on the line, as a lead picks up.
		local noise = (math.random() - 0.5) * 0.03
		lo += noise
		hi += noise
		value += noise
		-- (Under the rhythm and the patient's state, which sit in the strip's top 16 px.)
		local function yOf(v: number): number
			return math.floor(LABEL_ROW + area * 0.62 - v * area * 0.55)
		end
		local y = yOf(value)
		local top, bottom = math.min(yOf(hi), lastY, y), math.max(yOf(lo), lastY, y)
		local c = u.columns[index]
		c.Visible = true
		c.BackgroundColor3 = colour
		c.Position = UDim2.fromOffset((index - 1) * COLUMN, top - 1)
		c.Size = UDim2.fromOffset(COLUMN, bottom - top + 2)
		lastY = y
		-- The SpO2 wave, the same column.
		local pv = if r and rate > 0 then HospitalCharts.plethAt(sinceBeat(tEnd), period) * perfusion else 0
		local py = math.floor(plethTop + plethArea * (1 - pv * 0.9))
		local ptop, pbottom = math.min(py, plethY), math.max(py, plethY)
		local pc = u.pleth[index]
		pc.Visible = true
		pc.BackgroundColor3 = if r == nil or (r.spo2 == nil) then DIM else CYAN
		pc.Position = UDim2.fromOffset((index - 1) * COLUMN, ptop - 1)
		pc.Size = UDim2.fromOffset(COLUMN, pbottom - ptop + 2)
		plethY = py
		for e = 1, ERASE do
			local ahead = ((index + e - 1) % count) + 1
			u.columns[ahead].Visible = false
			u.pleth[ahead].Visible = false
		end
	end
	if cursor >= count then
		cursor -= count
	end
end

function HospitalCharts.isDoctor(): boolean
	return doctor
end

-- Whether the small monitor is up by itself over a dead body (round 4, M11).
function HospitalCharts.isAuto(): boolean
	return auto
end

-- The small monitor's pop-in scale (made the first time it is needed).
local function popScale(): UIScale
	local u = ui :: Ui
	local s = u.panel:FindFirstChild("AutoPop")
	if s and s:IsA("UIScale") then
		return s
	end
	local made = Instance.new("UIScale")
	made.Name = "AutoPop"
	made.Parent = u.panel
	return made
end

-- The small monitor on (over `body`) or off.
local function setAuto(body: Model?)
	local u = ui
	if not u then
		return
	end
	if body then
		-- (Doctor mode still sliding away: stopped here, so its end never hides this one.)
		local sliding = slideOut
		if sliding then
			sliding:Cancel()
			slideOut = nil
		end
		if not auto then
			auto = true
			u.panel.Active = false -- (a click goes through to the world: it is beside the aim, not in it)
			layout()
			-- A fresh trace for this body (never the last patient's line), and a quick pop in.
			for _, list in { u.columns, u.pleth } do
				for _, c in list do
					c.Visible = false
				end
			end
			cursor = 0
			popScale().Scale = if GuiService.ReducedMotionEnabled then 1 else 0.9
			if not GuiService.ReducedMotionEnabled then
				TweenService:Create(popScale(), TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end
		u.gui.Enabled = true
		watch(body)
	elseif auto then
		auto = false
		u.gui.Enabled = false
		u.panel.Active = true
		u.panel.AnchorPoint = Vector2.new(0.5, 1)
		u.panel.Position = UDim2.new(0.5, 0, 1, -(if plan then plan.bottom else HospitalCharts.BOTTOM))
		popScale().Scale = 1
		watch(nil)
	end
end
endAuto = function()
	setAuto(nil)
end

-- Beside the mouse, never over the aim: on the side it was on until the mouse is well past the
-- middle (no jumping to and fro across it) or that side has no room; always whole on the screen
-- and above the tool bar.
HospitalCharts.AUTO_GAP = 36 -- px between the mouse and the monitor
HospitalCharts.AUTO_SWAP = 60 -- px past the middle before it changes side
local autoRight = true
function HospitalCharts.autoRect(screen: Vector2, mouse: Vector2, size: Vector2, right: boolean, barTop: number): (Vector2, boolean)
	local gap = HospitalCharts.AUTO_GAP
	-- (Only to a side that is better: never back and forth on a narrow window.)
	local roomR = screen.X - 8 - (mouse.X + gap)
	local roomL = mouse.X - gap - 8
	local mid, swap = screen.X / 2, HospitalCharts.AUTO_SWAP
	if right and ((mouse.X > mid + swap and roomL >= size.X) or (roomR < size.X and roomL > roomR)) then
		right = false
	elseif not right and ((mouse.X < mid - swap and roomR >= size.X) or (roomL < size.X and roomR > roomL)) then
		right = true
	end
	local left = if right then mouse.X + gap else mouse.X - gap - size.X
	left = math.clamp(left, 8, math.max(8, screen.X - 8 - size.X))
	local top = math.clamp(mouse.Y - size.Y / 2, 8, math.max(8, barTop - 8 - size.Y))
	return Vector2.new(left, top), right
end
local function followMouse(at: Vector2)
	local u, p = ui, plan
	if not u or not p then
		return
	end
	local screen = u.gui.AbsoluteSize
	local corner, right = HospitalCharts.autoRect(screen, Vector2.new(at.X, at.Y - GuiService:GetGuiInset().Y), p.size, autoRight, screen.Y - PokeController.height())
	autoRight = right
	-- (Anchored on the edge that faces the mouse: its pop-in grows out of the cursor's side.)
	u.panel.AnchorPoint = Vector2.new(if right then 0 else 1, 0.5)
	u.panel.Position = UDim2.fromOffset(if right then corner.X else corner.X + p.size.X, corner.Y + p.size.Y / 2)
end

function HospitalCharts.current(): Model?
	return if doctor then patient else nil
end

HospitalCharts.onChanged = nil :: ((on: boolean) -> ())?

-- On or off. Not during the first minute (the bar is teaching the tools then).
function HospitalCharts.setDoctor(on: boolean, quiet: boolean?)
	if on == doctor then
		return
	end
	if on and player:GetAttribute("OnboardingReady") ~= true then
		Toast.show("One moment, still getting ready")
		return
	end
	if on and PokeController.firstMinute() then
		Toast.show("Try the tools first! Doctor mode comes after.")
		return
	end
	if on and player:GetAttribute("Building") == true then
		Toast.show("Finish building first")
		return
	end
	if on and auto then
		setAuto(nil) -- (the big one takes over from the small one)
	end
	doctor = on
	if on then
		pointed = true -- (found it: no need to point the way any more)
		PokeController.setDoctor(true)
	end
	local u = ui
	if u then
		-- It slides up into the bar's place, and down out of it (at once under Reduced Motion).
		local base = UDim2.new(0.5, 0, 1, -(if plan then plan.bottom else HospitalCharts.BOTTOM))
		local below = UDim2.new(0.5, 0, 1, -(if plan then plan.bottom else HospitalCharts.BOTTOM) + HospitalCharts.SLIDE)
		local still = GuiService.ReducedMotionEnabled
		if on then
			u.gui.Enabled = true
			layout()
			u.panel.Position = if still then base else below
			if not still then
				TweenService:Create(u.panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = base }):Play()
			end
		elseif still then
			u.gui.Enabled = false
			watch(nil)
			PokeController.setDoctor(false)
		else
			-- The bar comes back once the monitor has gone (never the two at once).
			local t = TweenService:Create(u.panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = below })
			slideOut = t
			t.Completed:Once(function()
				if slideOut == t then
					slideOut = nil
				end
				if not doctor then
					-- (The small monitor may have taken the screen meanwhile: then it stays.)
					if not auto then
						u.gui.Enabled = false
						u.panel.Position = base
						watch(nil)
					end
					PokeController.setDoctor(false)
				end
			end)
			t:Play()
		end
	elseif not on then
		watch(nil)
		PokeController.setDoctor(false)
	end
	if on then
		watch(nil)
		if not quiet then
			Toast.show(if ViewMode.isTouch()
				then "Doctor mode: tap someone to check them"
				else "Doctor mode: point at someone. " .. Keybinds.labelOf("Doctor") .. " to leave")
		end
	else
		-- (The patient stays on the monitor while it slides away; it is let go once it has gone.)
		hovered = nil
	end
	local listener = HospitalCharts.onChanged
	if listener then
		task.spawn(listener, on)
	end
end

-- Captures: the real monitor drawn into `frame` as if the screen were `screen` (a phone's safe
-- area) with `model` on it, live, so a computer can show what a phone shows. For a separate copy
-- of this module (a capture tool's own require), never the player's.
function HospitalCharts.previewForTest(frame: GuiObject, screen: Vector2, touch: boolean, model: Model?)
	-- (Studio only, and never on the copy the game started: it would take the player's monitor.)
	if not RunService:IsStudio() or started then
		return
	end
	if not ui then
		ui = build()
	end
	local u = ui :: Ui
	previewScreen = screen
	previewTouch = touch
	u.panel.Parent = frame
	layout()
	doctor = true
	watch(model)
	RunService.RenderStepped:Connect(function(dt)
		redraw()
		sweep(dt)
	end)
end

-- Tests and checks: a patient on the monitor now.
function HospitalCharts.showForTest(model: Model?)
	watch(model)
end

-- The monitor's box right now (LayoutCheck.live), nil while it is off.
function HospitalCharts.box(): GuiObject?
	local u = ui
	return if u and u.gui.Enabled then u.panel else nil
end

-- The line under a hit (HitInfo) points the way the first time: once a visit.
function HospitalCharts.pointTheWay()
	if pointed or doctor or ReplayController.isPlaying() then
		return -- (during a replay it waits for the next line)
	end
	pointed = true
	Toast.show(if ViewMode.isTouch()
		then "See their pulse and bumps: DOCTOR MODE in WEAPONS"
		else "See their pulse and bumps: Doctor mode (" .. Keybinds.labelOf("Doctor") .. ")")
end

function HospitalCharts.start()
	started = true
	ui = build()
	-- Build mode has the bottom of the screen (its parts drawer): doctor mode steps out for it.
	player:GetAttributeChangedSignal("Building"):Connect(function()
		if player:GetAttribute("Building") == true and doctor then
			HospitalCharts.setDoctor(false, true)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if Keybinds.live(processed) and Keybinds.is("Doctor", input.KeyCode) then
				HospitalCharts.setDoctor(not doctor)
			end
			return
		end
		if processed or not doctor then
			return
		end
		-- A tap or a click on a body: it goes on the monitor (and stays until another is picked).
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			local p = input.Position
			local body = bodyAt(Vector2.new(p.X, p.Y), true)
			if body then
				watch(body)
			end
		end
	end)
	local refreshAt = 0
	-- Round 4, M11: outside doctor mode, the small monitor over a dead body under the mouse.
	local function autoStep(dt: number)
		local t = os.clock()
		-- (A mouse in use: not a touch, not a gamepad that leaves the mouse where it last was.)
		local last = UserInputService:GetLastInputType()
		local mouse = UserInputService.MouseEnabled and last ~= Enum.UserInputType.Touch and not string.find(last.Name, "Gamepad", 1, true)
		local allowed = mouse and Settings.deadMonitor() and not ReplayController.isPlaying() and player:GetAttribute("Building") ~= true
			and player:GetAttribute("OnboardingReady") == true
		if not allowed then
			setAuto(nil)
			return
		end
		local at = UserInputService:GetMouseLocation()
		if t >= lastLook then
			lastLook = t + HOVER_RATE
			-- (The cheap look first: the HUD under the mouse is asked only over a dead body.)
			local hit = bodyAt(at, false)
			local body = if hit and hit:GetAttribute("Vital") == "Dead" and not overUi(at) then hit else nil
			if body then
				autoSeenAt = t
				setAuto(body)
			elseif auto and t - autoSeenAt > HospitalCharts.AUTO_GRACE then
				setAuto(nil)
			end
		end
		if auto then
			followMouse(at)
			if t >= refreshAt then
				refreshAt = t + 1
				redraw()
			end
			sweep(dt)
		end
	end
	RunService.RenderStepped:Connect(function(dt)
		if not doctor then
			autoStep(dt)
			return
		end
		local t = os.clock()
		-- A computer: whatever the mouse points at goes on the monitor (the last one stays).
		local mouse = UserInputService.MouseEnabled and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch
		if mouse and t >= lastLook then
			lastLook = t + HOVER_RATE
			local at = UserInputService:GetMouseLocation()
			local body = if overUi(at) then nil else bodyAt(at, false)
			if body and body ~= hovered then
				hovered = body
				watch(body)
			end
		end
		-- Not over a replay (it has the screen while it plays).
		local u = ui
		if u then
			u.gui.Enabled = not ReplayController.isPlaying()
		end
		-- The injury times tick on.
		if t >= refreshAt then
			refreshAt = t + 1
			redraw()
		end
		sweep(dt)
	end)
	-- A new size of the safe-area frame (a phone turned, a window resized): laid out again.
	local gui = (ui :: Ui).gui
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if doctor or auto then
			layout()
		end
	end)
	ViewMode.onChanged(function()
		if doctor then
			layout()
		end
	end)
end

return HospitalCharts
