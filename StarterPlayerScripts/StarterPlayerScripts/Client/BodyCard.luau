--!strict
-- BodyCard (0.36.6, owner 22 Nov 2026: "like the biggest ragdoll game: only Blood and Awake"). The small
-- card the hospital monitor shows by itself (after your hit, or a body under the mouse): the ragdoll's
-- name, a see-through body with its bones in segments (upper arm, forearm, hand ...), the hurt segments lit
-- orange, a dark dot for every shot where it landed, cut-off pieces gone, one state word, the heart rate, a
-- Blood bar and an Awake bar. 0.36.8: name, shot dots, segments, missing pieces.
-- HospitalCharts decides when and where; this only draws. Client only, reads the body's attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Anatomy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anatomy"))

local BodyCard = {}

BodyCard.W = 230
BodyCard.H = 356
BodyCard.REFRESH = 0.25
BodyCard.MAX_DOTS = 80

local CARD = Color3.fromRGB(38, 38, 42)
local SHELL = Color3.fromRGB(120, 126, 138)
local BONE = Color3.fromRGB(232, 222, 196)
local HURT = Color3.fromRGB(235, 110, 35)
local DOT = Color3.fromRGB(70, 10, 20)
local DOT_RING = Color3.fromRGB(150, 30, 45)
local WHITE = Color3.fromRGB(240, 240, 240)
local GREEN = Color3.fromRGB(110, 225, 130)
local YELLOW = Color3.fromRGB(245, 190, 70)
local RED = Color3.fromRGB(255, 85, 85)
local CYAN = Color3.fromRGB(110, 200, 255)
local BLOOD = Color3.fromRGB(150, 110, 245)
local TRACK = Color3.fromRGB(70, 70, 76)

type Ui = {
	gui: ScreenGui,
	card: Frame,
	scale: UIScale,
	name: TextLabel,
	pieces: { [string]: Frame },
	dots: { Frame },
	state: TextLabel,
	bpm: TextLabel,
	bloodBar: Frame,
	bloodText: TextLabel,
	awakeLabel: TextLabel,
	awakeBar: Frame,
}
local ui: Ui? = nil
local body: Model? = nil
local token = 0

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function box(parent: Instance, name: string, x: number, y: number, w: number, h: number, colour: Color3, alpha: number, r: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.BackgroundColor3 = colour
	f.BackgroundTransparency = alpha
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	corner(f, r)
	f.Parent = parent
	return f
end

local function label(parent: Instance, name: string, x: number, y: number, w: number, h: number, size: number, colour: Color3, align: Enum.TextXAlignment): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(x, y)
	t.Size = UDim2.fromOffset(w, h)
	t.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	t.TextSize = size
	t.TextColor3 = colour
	t.TextXAlignment = align
	t.TextTruncate = Enum.TextTruncate.AtEnd
	t.Text = ""
	t.Parent = parent
	return t
end

-- One segment: a see-through shell with a bone down its middle and a knob at each end (the joints).
local function segment(fig: Frame, name: string, x: number, y: number, w: number, h: number): Frame
	local shell = box(fig, name, x, y, w, h, SHELL, 0.45, math.floor(math.min(w, h) / 2))
	local bw = math.max(3, math.floor(w * 0.22))
	box(shell, "Bone", math.floor((w - bw) / 2), 3, bw, h - 6, BONE, 0, 2)
	if h > 20 then
		box(shell, "KnobTop", math.floor(w / 2) - bw, 1, bw * 2, bw + 1, BONE, 0, bw)
		box(shell, "KnobBottom", math.floor(w / 2) - bw, h - bw - 2, bw * 2, bw + 1, BONE, 0, bw)
	end
	return shell
end

local function build(): Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "BodyCard"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 6
	gui.Enabled = false
	local card = box(gui, "Card", 0, 0, BodyCard.W, BodyCard.H, CARD, 0.08, 16)
	card.AnchorPoint = Vector2.new(1, 1)
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.6
	stroke.Thickness = 1.5
	stroke.Parent = card

	local name = label(card, "Name", 12, 6, BodyCard.W - 24, 24, 19, WHITE, Enum.TextXAlignment.Center)

	local fig = Instance.new("Frame")
	fig.Name = "Figure"
	fig.BackgroundTransparency = 1
	fig.Size = UDim2.fromOffset(BodyCard.W, 216)
	fig.Position = UDim2.fromOffset(0, 32)
	fig.Parent = card
	local cx = math.floor(BodyCard.W / 2)
	local pieces: { [string]: Frame } = {}
	-- Head: a skull with eye holes, a nose and a jaw; the neck under it.
	local head = box(fig, "Head", cx - 17, 0, 34, 38, SHELL, 0.45, 16)
	local skull = box(head, "Skull", 6, 4, 22, 22, BONE, 0, 11)
	box(skull, "EyeL", 3, 8, 6, 6, Color3.fromRGB(55, 55, 60), 0, 3)
	box(skull, "EyeR", 13, 8, 6, 6, Color3.fromRGB(55, 55, 60), 0, 3)
	box(skull, "Nose", 9, 15, 4, 4, Color3.fromRGB(55, 55, 60), 0, 2)
	box(head, "Jaw", 10, 25, 14, 7, BONE, 0, 3)
	box(fig, "Neck", cx - 3, 38, 6, 7, BONE, 0, 2)
	pieces.Head = head
	-- Chest: spine, collarbones and a ribcage.
	local chest = box(fig, "Chest", cx - 29, 44, 58, 52, SHELL, 0.45, 12)
	box(chest, "Spine", 27, 2, 4, 48, BONE, 0, 2)
	box(chest, "Collar", 6, 3, 46, 4, BONE, 0, 2)
	for i = 0, 3 do
		box(chest, "Rib", 9 + i, 11 + i * 9, 40 - i * 2, 4, BONE, 0, 2)
	end
	pieces.Chest = chest
	-- Belly: the spine on and the pelvis.
	local belly = box(fig, "Belly", cx - 25, 97, 50, 26, SHELL, 0.45, 10)
	box(belly, "Spine", 23, 0, 4, 12, BONE, 0, 2)
	box(belly, "Pelvis", 7, 12, 36, 10, BONE, 0, 5)
	pieces.Belly = belly
	for _, side in { "Left", "Right" } do
		local s = if side == "Left" then 1 else -1 -- (the figure faces you: its left is on your right)
		local ax = if s < 0 then cx - 29 - 16 else cx + 29 + 1
		pieces[side .. "UpperArm"] = segment(fig, side .. "UpperArm", ax, 46, 15, 40)
		pieces[side .. "Forearm"] = segment(fig, side .. "Forearm", ax, 88, 15, 36)
		pieces[side .. "Hand"] = box(fig, side .. "Hand", ax, 126, 15, 17, SHELL, 0.45, 6)
		box(pieces[side .. "Hand"], "Bones", 3, 3, 9, 11, BONE, 0, 3)
		local lx = if s < 0 then cx - 24 else cx + 2
		pieces[side .. "Thigh"] = segment(fig, side .. "Thigh", lx, 125, 22, 42)
		pieces[side .. "Shin"] = segment(fig, side .. "Shin", lx, 169, 22, 34)
		pieces[side .. "Foot"] = box(fig, side .. "Foot", lx + (if s < 0 then -3 else 3), 205, 22, 10, SHELL, 0.45, 4)
		box(pieces[side .. "Foot"], "Bones", 3, 2, 16, 6, BONE, 0, 3)
	end
	-- The shot dots (made once, placed on the segment they belong to).
	local dots: { Frame } = {}
	for i = 1, BodyCard.MAX_DOTS do
		local d = box(fig, "Shot", 0, 0, 7, 7, DOT, 0, 4)
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.ZIndex = 3
		local ring = Instance.new("UIStroke")
		ring.Color = DOT_RING
		ring.Thickness = 1.5
		ring.Parent = d
		d.Visible = false
		dots[i] = d
	end

	local state = label(card, "State", 0, 250, BodyCard.W, 30, 26, YELLOW, Enum.TextXAlignment.Center)
	state.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	local heart = label(card, "Heart", 16, 282, 90, 24, 18, RED, Enum.TextXAlignment.Left)
	heart.Text = "\u{2665}"
	local bpm = label(card, "Bpm", 60, 280, BodyCard.W - 76, 26, 22, WHITE, Enum.TextXAlignment.Right)

	local function bar(y: number, title: string, colour: Color3): (TextLabel, Frame, TextLabel, Frame)
		local l = label(card, title .. "Label", 16, y, 70, 24, 21, WHITE, Enum.TextXAlignment.Left)
		l.Text = title
		local track = box(card, title .. "Track", 92, y + 7, BodyCard.W - 92 - 16, 11, TRACK, 0, 6)
		local fill = box(track, "Fill", 0, 0, 0, 11, colour, 0, 6)
		fill.Size = UDim2.new(1, 0, 1, 0)
		local value = label(card, title .. "Value", 92, y, BodyCard.W - 92 - 16, 24, 20, WHITE, Enum.TextXAlignment.Right)
		return l, fill, value, track
	end
	local _, bloodBar, bloodText, bt = bar(308, "Blood", BLOOD)
	local awakeLabel, awakeBar, awakeValue = bar(330, "Awake", GREEN)
	awakeValue:Destroy()
	-- (Blood's percent sits after its bar, like the reference: the bar is shortened for it.)
	bt.Size = UDim2.fromOffset(BodyCard.W - 92 - 16 - 50, 11)
	awakeLabel.TextColor3 = GREEN

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return {
		gui = gui,
		card = card,
		scale = scale,
		name = name,
		pieces = pieces,
		dots = dots,
		state = state,
		bpm = bpm,
		bloodBar = bloodBar,
		bloodText = bloodText,
		awakeLabel = awakeLabel,
		awakeBar = awakeBar,
	}
end

-- The segment a wound zone is drawn on.
local function segmentOf(zoneId: string): string
	if zoneId == "Brain" or zoneId == "Skull" or zoneId == "Jaw" or zoneId == "Neck" then
		return "Head"
	elseif zoneId == "Liver" or zoneId == "Stomach" or zoneId == "Intestines" or zoneId == "Pelvis" or string.find(zoneId, "Kidney", 1, true) then
		return "Belly"
	end
	local side = string.match(zoneId, "^(Left)") or string.match(zoneId, "^(Right)")
	if side then
		local rest = string.sub(zoneId, #side + 1)
		if rest == "UpperArm" or rest == "ArmStump" then
			return side .. "UpperArm"
		elseif rest == "Forearm" or rest == "Hand" or rest == "Shin" or rest == "Foot" then
			return side .. rest
		elseif rest == "Thigh" or rest == "Femoral" then
			return side .. "Thigh"
		elseif rest == "Lung" or rest == "Kidney" then
			return if rest == "Lung" then "Chest" else "Belly"
		end
	end
	return "Chest"
end

-- The segments a cut-off piece takes with it (Anatomy LIMBS and CUTS names).
local GONE: { [string]: { string } } = {}
for _, side in { "Left", "Right" } do
	GONE[side .. "Arm"] = { side .. "UpperArm", side .. "Forearm", side .. "Hand" }
	GONE[side .. "Forearm"] = { side .. "Forearm", side .. "Hand" }
	GONE[side .. "Hand"] = { side .. "Hand" }
	GONE[side .. "Leg"] = { side .. "Thigh", side .. "Shin", side .. "Foot" }
	GONE[side .. "Shin"] = { side .. "Shin", side .. "Foot" }
	GONE[side .. "Foot"] = { side .. "Foot" }
end

-- A steady spot in 0..1 for a wound (the same wound stays where it was drawn).
local function spot(at: number, salt: number): number
	local x = math.sin(at * 12.9898 + salt * 78.233) * 43758.5453
	return x - math.floor(x)
end

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function redraw()
	local u, m = ui, body
	if not u or not m or not m.Parent then
		return
	end
	local personName = m:GetAttribute("PersonName")
	u.name.Text = if type(personName) == "string" and personName ~= "" then personName else "Lab dummy"
	local blood = m:GetAttribute("Blood")
	local pulse = m:GetAttribute("Pulse")
	local vital = m:GetAttribute("Vital")
	local b = if type(blood) == "number" then blood else 100
	local hr = if type(pulse) == "number" then pulse else 72
	local v = if type(vital) == "string" then vital else "Alive"
	local wounds = Anatomy.parseWounds(m:GetAttribute("Wounds"))
	local r = Anatomy.monitor(b, hr, v, wounds, Anatomy.stoppedFor(m:GetAttribute("DiedAt"), m:GetAttribute("DeathCause"), serverNow()))
	-- Cut-off pieces are gone from the figure.
	local gone: { [string]: boolean } = {}
	local severed = m:GetAttribute("Severed")
	if type(severed) == "string" and severed ~= "" then
		for _, piece in string.split(severed, ",") do
			for _, seg in GONE[piece] or {} do
				gone[seg] = true
			end
		end
	end
	-- The hurt segments, and a dot for every shot (blows bruise: no dot).
	local hurt: { [string]: boolean } = {}
	local used = 0
	local same: { [string]: number } = {} -- (shots in one second on one spot: each its own place)
	local first = math.max(1, #wounds - BodyCard.MAX_DOTS + 1)
	for i, w in wounds do
		local seg = segmentOf(w.zone.id)
		hurt[seg] = true
		local piece = u.pieces[seg]
		if i >= first and not w.blunt and piece and not gone[seg] then
			used += 1
			local d = u.dots[used]
			local pos, size = piece.Position, piece.Size
			local key = seg .. w.at
			local nth = same[key] or 0
			same[key] = nth + 1
			local fx = 0.2 + 0.6 * spot(w.at, 1 + nth * 2)
			local fy = 0.12 + 0.76 * spot(w.at, 2 + nth * 2)
			d.Position = UDim2.fromOffset(pos.X.Offset + size.X.Offset * fx, pos.Y.Offset + size.Y.Offset * fy)
			d.Visible = true
		end
	end
	for i = used + 1, #u.dots do
		u.dots[i].Visible = false
	end
	for seg, f in u.pieces do
		f.Visible = not gone[seg]
		f.BackgroundColor3 = if hurt[seg] then HURT else SHELL
		f.BackgroundTransparency = if hurt[seg] then 0.15 else 0.45
	end
	-- One word for the state.
	local dead = v == "Dead"
	local word, colour
	if dead then
		word, colour = "Dead", RED
	elseif v == "Unconscious" then
		word, colour = "Knocked out", CYAN
	elseif next(gone) ~= nil then
		word, colour = "Missing a limb", YELLOW
	elseif m:GetAttribute("Bleeding") then
		word, colour = "Bleeding", YELLOW
	elseif #wounds > 0 or b < 100 then
		word, colour = "Hurt", YELLOW
	else
		word, colour = "Fine", GREEN
	end
	u.state.Text = word
	u.state.TextColor3 = colour
	local beats = if dead then 0 else math.max(0, math.floor((r :: any).hr or hr))
	u.bpm.Text = string.format("%d bpm", beats)
	local bp = math.clamp(b, 0, 100)
	u.bloodBar.Size = UDim2.fromScale(bp / 100, 1)
	u.bloodText.Text = string.format("%d%%", math.floor(bp + 0.5))
	local gcs = (r :: any).gcs
	local awake = if dead then 0 elseif type(gcs) == "number" then math.clamp((gcs - 3) / 12, 0, 1) else 1
	u.awakeBar.Size = UDim2.fromScale(awake, 1)
	local ac = if awake > 0.66 then GREEN elseif awake > 0.25 then YELLOW else RED
	u.awakeBar.BackgroundColor3 = ac
	u.awakeLabel.TextColor3 = ac
end

-- Show the card for `model` (nil: hide it).
function BodyCard.show(model: Model?)
	if model == body then
		return
	end
	body = model
	token += 1
	local mine = token
	if not model then
		local u = ui
		if u and u.gui.Enabled then
			local t = TweenService:Create(u.scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = ((u.scale:GetAttribute("Base") :: number?) or 1) * 0.7 })
			t.Completed:Once(function()
				if token == mine then
					u.gui.Enabled = false
				end
			end)
			t:Play()
		end
		return
	end
	local u = ui or build()
	ui = u
	redraw()
	local base = (u.scale:GetAttribute("Base") :: number?) or 1
	u.scale.Scale = base * 0.85
	u.gui.Enabled = true
	TweenService:Create(u.scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = base }):Play()
	task.spawn(function()
		while token == mine and body == model do
			task.wait(BodyCard.REFRESH)
			if token == mine then
				redraw()
			end
		end
	end)
end

-- Where it sits (the monitor's own corner) and how big (the monitor's fit for this screen).
function BodyCard.place(anchor: Vector2, position: UDim2, fit: number)
	local u = ui
	if not u then
		return
	end
	u.card.AnchorPoint = anchor
	u.card.Position = position
	if u.scale:GetAttribute("Base") ~= fit then
		u.scale:SetAttribute("Base", fit)
		u.scale.Scale = fit
	end
end

function BodyCard.shown(): Model?
	return if ui and (ui :: Ui).gui.Enabled then body else nil
end

return BodyCard
