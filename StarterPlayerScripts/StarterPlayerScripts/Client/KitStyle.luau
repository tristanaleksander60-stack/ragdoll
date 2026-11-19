--!strict
-- The LihFolk UI kit's look for the few HUD pieces that are plain Roblox buttons and labels (BUILD,
-- PLAY, LAB VIEW, RAGDOLL, recenter, the onboarding hint): the kit's display type (Builder Sans
-- Heavy in the dark-glass look), white text with an ink stroke (or ink text on light faces), the
-- kit's thin ink outline and corner radius. Everything else is
-- built from the kit's components directly.
--
-- UI v2 (Config.UI_V2, read through Theme.V2): the same calls also
--   * fit the text to its box (TextScaled under a UITextSizeConstraint: never cut, never under the
--     14 px floor drawn on a phone; a TextSize set afterwards becomes the cap),
--   * give the face a light-from-above gradient (it reads as pressable, not a flat slab),
--   * squish on press (Theme.Motion.pressScale 0.92) and click (the kit's "click" sound slot):
--     KitStyle.press, wired by KitStyle.button and callable on any hand-built button,
-- and the module adds the shared helpers every screen uses: icon (a drawn icon beside or over a
-- button's word), pop (a scale pop on the object's one UIScale), countUp (a number that counts to
-- its new value) and fit (TextScaled with a size cap and the floor).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local Icons = require(UI:WaitForChild("LihFolkUIIcons"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))

local INK = Theme.Palette.ink
local M = Theme.Motion

local KitStyle = {}

KitStyle.V2 = Theme.V2 == true

-- The HUD's few colours (dark glass, round 2, N5): a plain button is the dark slab, the one thing
-- to press (or a mode that is on) is green, a stop is red, a pick is blue. White text on all.
-- (UI v2: the same names, the v2 palette's values.)
KitStyle.SLAB = Theme.Palette.slab
KitStyle.GO = Theme.Palette.go
KitStyle.STOP = Theme.Roles.danger.bottom
KitStyle.PICK = Theme.Roles.info.bottom

-- The text floor in design px (UI v2: drawn 14 px at the kit's smallest touch scale).
KitStyle.MIN_TEXT = if KitStyle.V2 then 14 else 12

local function outline(object: GuiObject, thickness: number)
	local stroke = object:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = object
	end
	local s = stroke :: UIStroke
	s.Color = INK
	s.Thickness = thickness
	s.Transparency = 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

-- Relative luminance (WCAG 2.1): ink text on light faces, white on the rest.
local function lightFace(c: Color3): boolean
	local function lin(v: number): number
		return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B) > 0.4
end
KitStyle.lightFace = lightFace

-- TextScaled under a cap (the size it was designed at) and the floor. A TextSize set later (the
-- callers do: "RAGDOLL" at 16) moves the cap, so nothing a caller tuned is lost.
function KitStyle.fit(object: TextButton | TextLabel, cap: number, floor: number?)
	local o = object :: any
	local found = object:FindFirstChild("KitFit")
	local l: UITextSizeConstraint
	if found and found:IsA("UITextSizeConstraint") then
		l = found
	else
		local made = Instance.new("UITextSizeConstraint")
		made.Name = "KitFit"
		made.Parent = object
		l = made
		object:GetPropertyChangedSignal("TextSize"):Connect(function()
			made.MaxTextSize = math.max(made.MinTextSize, o.TextSize)
		end)
	end
	local low = math.min(cap, floor or KitStyle.MIN_TEXT)
	l.MinTextSize = 1 -- (set the pair in an order that never crosses)
	l.MaxTextSize = math.max(low, cap)
	l.MinTextSize = low
	o.TextScaled = true
	o.TextWrapped = true
end

-- As fit, but a word that cannot fit at the floor is hidden rather than drawn too small or cut
-- (a short card where the picture and the bar still say it). Shown again when it fits.
function KitStyle.fitOrHide(label: TextLabel, cap: number, floor: number?)
	KitStyle.fit(label, cap, floor)
	label:SetAttribute("KitFitOrHide", true)
	local pending = false
	local function check()
		if pending then
			return
		end
		pending = true
		task.defer(function()
			pending = false
			if label.Parent then
				label.TextTransparency = if label.TextFits then 0 else 1
				local stroke = label:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Enabled = label.TextFits
				end
			end
		end)
	end
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(check)
	label:GetPropertyChangedSignal("Text"):Connect(check)
	check()
end

local function text(object: TextButton | TextLabel, size: number)
	local o = object :: any
	o.FontFace = Theme.Fonts.display
	o.TextSize = size
	if lightFace(object.BackgroundColor3) then
		o.TextColor3 = INK
		o.TextStrokeTransparency = 1
	else
		o.TextColor3 = Color3.new(1, 1, 1)
		o.TextStrokeColor3 = INK
		o.TextStrokeTransparency = 0.2
	end
	if KitStyle.V2 then
		KitStyle.fit(object, size)
		if not object:FindFirstChildOfClass("UIPadding") then
			local pad = Instance.new("UIPadding")
			pad.Name = "KitPad"
			pad.PaddingLeft = UDim.new(0, 8)
			pad.PaddingRight = UDim.new(0, 8)
			pad.PaddingTop = UDim.new(0, 5)
			pad.PaddingBottom = UDim.new(0, 5)
			pad.Parent = object
		end
	end
end

local function corner(object: GuiObject, round: boolean?)
	local c = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = if round then UDim.new(1, 0) else UDim.new(0, Theme.Radius.button)
	c.Parent = object
end

-- UI v2: light from above (white at the top to a soft grey at the foot, over the face colour).
local function shade(object: GuiObject)
	if not KitStyle.V2 then
		return
	end
	if object:FindFirstChild("KitShade") then
		return
	end
	local g = Instance.new("UIGradient")
	g.Name = "KitShade"
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(196, 200, 214))
	g.Parent = object
end

---------------------------------------------------------------------------------------------------
-- Motion on the object's ONE UIScale (never two on one object). HudSlots.apply keeps its slot
-- scale in "HudScale" and writes the resting value to the KitBase attribute; this module uses the
-- same UIScale and returns it to that value.

local function scaleOf(object: GuiObject): UIScale
	local found = object:FindFirstChild("HudScale")
	if found and found:IsA("UIScale") then
		return found
	end
	local any = object:FindFirstChildOfClass("UIScale")
	if any then
		return any
	end
	local made = Instance.new("UIScale")
	made.Name = "HudScale" -- (the name HudSlots.apply looks for: it adopts this one)
	made.Parent = object
	return made
end

local function restOf(object: GuiObject): number
	local base = object:GetAttribute("KitBase")
	return if type(base) == "number" then base else 1
end

-- A pop: from a smaller (or bigger) scale back to rest with a little overshoot.
function KitStyle.pop(object: GuiObject, from: number?)
	if Theme.isReducedMotion() then
		return
	end
	local s = scaleOf(object)
	local rest = restOf(object)
	s.Scale = rest * (from or M.popFrom)
	TweenService:Create(s, TweenInfo.new(M.popTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = rest }):Play()
end

-- Press feedback on any GuiButton: squish while held (0.92), spring back on release, the kit's
-- click on Activated. Once per button (safe to call again).
function KitStyle.press(button: GuiButton, sound: string?)
	if not KitStyle.V2 or button:GetAttribute("KitPress") then
		return
	end
	button:SetAttribute("KitPress", true)
	local held = false
	local function settle(down: boolean)
		if Theme.isReducedMotion() then
			return
		end
		local s = scaleOf(button)
		local rest = restOf(button)
		local goal = if down then rest * M.pressScale else rest
		local info = if down
			then TweenInfo.new(M.pressTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			else TweenInfo.new(M.releaseTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(s, info, { Scale = goal }):Play()
	end
	local function pointer(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	button.InputBegan:Connect(function(input: InputObject)
		if pointer(input) then
			held = true
			settle(true)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if held and pointer(input) then
			held = false
			settle(false)
		end
	end)
	button.MouseLeave:Connect(function()
		if held then
			held = false
			settle(false)
		end
	end)
	button.Activated:Connect(function()
		C.playSound(sound or "click")
	end)
end

---------------------------------------------------------------------------------------------------
-- Icons: a drawn icon (DrawnIcons via the kit's registry) with the button's word. "left" for a
-- wide button (the word moves right of it), "top" for a round or square one (the word under it).

KitStyle.HUD_ICONS = {
	View = "eye",
	Ragdoll = "tool_Shove",
	Mode = "sandbox", -- BUILD
	Play = "tool_Launch",
	Grab = "tool_Grab",
	Throw = "tool_Launch",
	Sprint = "tool_Kick", -- RUN
	Shoot = "tool_Blaster",
	Zoom = "eye",
	Replay = "camera",
	FirstPerson = "camera",
	SlowMo = "tool_Slowmo",
	Revive = "heart",
	Reset = "tool_Shockwave",
	Experiment = "star",
}

function KitStyle.icon(object: GuiObject, name: string?, placement: ("left" | "top")?)
	local old = object:FindFirstChild("KitIcon")
	if old then
		old:Destroy()
	end
	if not KitStyle.V2 or not name then
		return
	end
	local where = placement or "left"
	local size = object.Size
	local h = if size.Y.Scale == 0 then size.Y.Offset else 44
	local w = if size.X.Scale == 0 then size.X.Offset else 120
	local px = if where == "top" then math.floor(math.min(w, h) * 0.38) else math.floor(math.min(h - 14, Theme.IconSize.sm - 2))
	local icon = Icons.make(name, UDim2.fromOffset(px, px))
	icon.Name = "KitIcon"
	if icon:IsA("ImageLabel") then
		icon.ImageTransparency = 0
	end
	icon.ZIndex = object.ZIndex + 1
	for _, d in icon:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = object.ZIndex + 2
		end
	end
	-- (The padding moves the word clear of the icon; the icon itself sits outside the padding by
	-- a matching negative offset, so it stays where it is drawn.)
	local pad = object:FindFirstChildOfClass("UIPadding")
	if not pad then
		local made = Instance.new("UIPadding")
		made.Name = "KitPad"
		made.Parent = object
		pad = made
	end
	local p = pad :: UIPadding
	if where == "top" then
		p.PaddingLeft = UDim.new(0, 3) -- (the word may use the full width under its icon)
		p.PaddingRight = UDim.new(0, 3)
		p.PaddingTop = UDim.new(0, px + 2)
		p.PaddingBottom = UDim.new(0, 4)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, -(px - 2))
	else
		p.PaddingLeft = UDim.new(0, px + 10)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, -(px + 4), 0.5, 0)
	end
	icon.Parent = object
end

---------------------------------------------------------------------------------------------------
-- Numbers that count up (bolts, kills, the level): from what the label shows now to the new value,
-- quicker for small steps. Reduced Motion (or v1): the new value at once.

type Count = { value: NumberValue, shown: number, target: number }
local counting: { [Instance]: Count } = setmetatable({}, { __mode = "k" }) :: any

function KitStyle.countUp(label: TextLabel | TextButton, to: number, format: ((n: number) -> string)?)
	local show = format or function(n: number): string
		return tostring(n)
	end
	local entry = counting[label]
	local from = if entry then entry.shown else to
	if not entry then
		local v = Instance.new("NumberValue")
		entry = { value = v, shown = to, target = to }
		counting[label] = entry
		v.Changed:Connect(function(n: number)
			local e = counting[label]
			if e then
				local whole = math.floor(n + 0.5)
				if whole ~= e.shown then
					e.shown = whole
					local target: any = label
					target.Text = show(whole)
				end
			end
		end)
	end
	local e = entry :: Count
	if e.target == to and e.shown ~= to then
		return -- (already counting to it)
	end
	e.target = to
	if not KitStyle.V2 or Theme.isReducedMotion() or to <= from or from == to then
		e.value.Value = to
		e.shown = to
		;(label :: any).Text = show(to)
		return
	end
	e.value.Value = from
	local time = math.clamp(M.countTime + (to - from) * 0.004, M.countTime, M.countTimeMax)
	TweenService:Create(e.value, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = to }):Play()
	KitStyle.pop(label :: GuiObject, 1.18)
end

---------------------------------------------------------------------------------------------------

-- A HUD button (call again after changing its colour, so the text stays readable).
function KitStyle.button(object: GuiButton, round: boolean?)
	if object:IsA("TextButton") then
		text(object, 18)
	end
	object.BackgroundTransparency = 0
	outline(object, Theme.Stroke.button)
	corner(object, round)
	shade(object)
	KitStyle.press(object)
	local pad = object:FindFirstChild("KitPad")
	if round and pad and pad:IsA("UIPadding") then
		-- (A circle: the word may use nearly its whole width.)
		pad.PaddingLeft = UDim.new(0, 3)
		pad.PaddingRight = UDim.new(0, 3)
	end
end

-- A hint or tag: a coloured panel with kit text.
function KitStyle.label(object: TextLabel)
	text(object, 22)
	outline(object, Theme.Stroke.card)
	corner(object)
	shade(object)
end

return KitStyle
