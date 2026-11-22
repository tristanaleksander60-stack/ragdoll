--!strict
-- BodyCard (0.36.6, owner 22 Nov 2026: "like the biggest ragdoll game: only Blood and Awake"). The small
-- card the hospital monitor shows by itself (after your hit, or a body under the mouse): a see-through body
-- with its bones, the hurt parts lit orange, one state word, the heart rate, a Blood bar and an Awake bar.
-- HospitalCharts decides when and where; this only draws. Client only, reads the body's attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Anatomy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anatomy"))

local BodyCard = {}

BodyCard.W = 230
BodyCard.H = 318
BodyCard.REFRESH = 0.25

local CARD = Color3.fromRGB(38, 38, 42)
local SHELL = Color3.fromRGB(120, 126, 138)
local BONE = Color3.fromRGB(232, 222, 196)
local HURT = Color3.fromRGB(235, 110, 35)
local WHITE = Color3.fromRGB(240, 240, 240)
local GREEN = Color3.fromRGB(110, 225, 130)
local YELLOW = Color3.fromRGB(245, 190, 70)
local RED = Color3.fromRGB(255, 85, 85)
local CYAN = Color3.fromRGB(110, 200, 255)
local BLOOD = Color3.fromRGB(150, 110, 245)
local TRACK = Color3.fromRGB(70, 70, 76)

local HEAD_ZONES = { Brain = true, Skull = true, Jaw = true, Neck = true }

type Ui = {
	gui: ScreenGui,
	card: Frame,
	scale: UIScale,
	pieces: { [string]: Frame },
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
	t.Text = ""
	t.Parent = parent
	return t
end

-- One body piece: a see-through shell with a bone down its middle.
local function limb(fig: Frame, name: string, x: number, y: number, w: number, h: number): Frame
	local shell = box(fig, name, x, y, w, h, SHELL, 0.45, math.floor(w / 2))
	box(shell, "Bone", math.floor(w / 2) - 2, 6, 4, h - 12, BONE, 0, 2)
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

	local fig = Instance.new("Frame")
	fig.Name = "Figure"
	fig.BackgroundTransparency = 1
	fig.Size = UDim2.fromOffset(BodyCard.W, 196)
	fig.Position = UDim2.fromOffset(0, 8)
	fig.Parent = card
	local cx = BodyCard.W / 2
	local pieces: { [string]: Frame } = {}
	-- Head: a skull with two eye holes.
	local head = box(fig, "Head", cx - 18, 2, 36, 38, SHELL, 0.45, 18)
	local skull = box(head, "Skull", 6, 5, 24, 26, BONE, 0, 12)
	box(skull, "EyeL", 4, 9, 6, 6, Color3.fromRGB(60, 60, 64), 0, 3)
	box(skull, "EyeR", 14, 9, 6, 6, Color3.fromRGB(60, 60, 64), 0, 3)
	pieces.Head = head
	-- Torso: spine and ribs.
	local torso = box(fig, "Torso", cx - 30, 44, 60, 72, SHELL, 0.45, 12)
	box(torso, "Spine", 28, 4, 4, 64, BONE, 0, 2)
	for i = 0, 3 do
		box(torso, "Rib", 10, 10 + i * 11, 40, 4, BONE, 0, 2)
	end
	box(torso, "Hips", 12, 58, 36, 8, BONE, 0, 4)
	pieces.Torso = torso
	pieces.LeftArm = limb(fig, "LeftArm", cx - 30 - 20, 46, 17, 78)
	pieces.RightArm = limb(fig, "RightArm", cx + 30 + 3, 46, 17, 78)
	pieces.LeftLeg = limb(fig, "LeftLeg", cx - 27, 120, 24, 74)
	pieces.RightLeg = limb(fig, "RightLeg", cx + 3, 120, 24, 74)

	local state = label(card, "State", 0, 206, BodyCard.W, 30, 26, YELLOW, Enum.TextXAlignment.Center)
	state.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	local heart = label(card, "Heart", 16, 240, 90, 24, 18, RED, Enum.TextXAlignment.Left)
	heart.Text = "\u{2665}"
	local bpm = label(card, "Bpm", 60, 238, BodyCard.W - 76, 26, 22, WHITE, Enum.TextXAlignment.Right)

	local function bar(y: number, name: string, colour: Color3): (TextLabel, Frame, TextLabel, Frame)
		local l = label(card, name .. "Label", 16, y, 70, 24, 21, WHITE, Enum.TextXAlignment.Left)
		l.Text = name
		local track = box(card, name .. "Track", 92, y + 7, BodyCard.W - 92 - 16, 11, TRACK, 0, 6)
		local fill = box(track, "Fill", 0, 0, 0, 11, colour, 0, 6)
		fill.Size = UDim2.new(1, 0, 1, 0)
		local value = label(card, name .. "Value", 92, y, BodyCard.W - 92 - 16, 24, 20, WHITE, Enum.TextXAlignment.Right)
		return l, fill, value, track
	end
	local _, bloodBar, bloodText, bt = bar(270, "Blood", BLOOD)
	local awakeLabel, awakeBar, awakeValue = bar(292, "Awake", GREEN)
	awakeValue:Destroy()
	-- (Blood's percent sits after its bar, like the reference: the bar is shortened for it.)
	bt.Size = UDim2.fromOffset(BodyCard.W - 92 - 16 - 50, 11)
	awakeLabel.TextColor3 = GREEN

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return {
		gui = gui,
		card = card,
		scale = scale,
		pieces = pieces,
		state = state,
		bpm = bpm,
		bloodBar = bloodBar,
		bloodText = bloodText,
		awakeLabel = awakeLabel,
		awakeBar = awakeBar,
	}
end

local function region(z: Anatomy.Zone): string
	if HEAD_ZONES[z.id] then
		return "Head"
	end
	return z.limb or "Torso"
end

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function redraw()
	local u, m = ui, body
	if not u or not m or not m.Parent then
		return
	end
	local blood = m:GetAttribute("Blood")
	local pulse = m:GetAttribute("Pulse")
	local vital = m:GetAttribute("Vital")
	local b = if type(blood) == "number" then blood else 100
	local hr = if type(pulse) == "number" then pulse else 72
	local v = if type(vital) == "string" then vital else "Alive"
	local wounds = Anatomy.parseWounds(m:GetAttribute("Wounds"))
	local r = Anatomy.monitor(b, hr, v, wounds, Anatomy.stoppedFor(m:GetAttribute("DiedAt"), m:GetAttribute("DeathCause"), serverNow()))
	-- The hurt pieces.
	local hurt: { [string]: boolean } = {}
	for _, w in wounds do
		hurt[region(w.zone)] = true
	end
	for name, f in u.pieces do
		f.BackgroundColor3 = if hurt[name] then HURT else SHELL
		f.BackgroundTransparency = if hurt[name] then 0.15 else 0.45
	end
	-- One word for the state.
	local dead = v == "Dead"
	local word, colour
	if dead then
		word, colour = "Dead", RED
	elseif v == "Unconscious" then
		word, colour = "Knocked out", CYAN
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
