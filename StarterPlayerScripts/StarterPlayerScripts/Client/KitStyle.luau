--!strict
-- The LihFolk UI kit's look for the few HUD pieces that are plain Roblox buttons and labels (BUILD,
-- PLAY, LAB VIEW, RAGDOLL, recenter, the onboarding hint): the kit's display type (Builder Sans
-- Heavy in the dark-glass look), white text with an ink stroke (or ink text on light faces), the
-- kit's thin ink outline and corner radius. Everything else is
-- built from the kit's components directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))

local INK = Theme.Palette.ink

local KitStyle = {}

-- The HUD's few colours (dark glass, round 2, N5): a plain button is the dark slab, the one thing
-- to press (or a mode that is on) is green, a stop is red, a pick is blue. White text on all.
KitStyle.SLAB = Theme.Palette.slab
KitStyle.GO = Theme.Palette.go
KitStyle.STOP = Theme.Roles.danger.bottom
KitStyle.PICK = Theme.Roles.info.bottom

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

local function text(object: TextButton | TextLabel, size: number)
	object.FontFace = Theme.Fonts.display
	object.TextSize = size
	if lightFace(object.BackgroundColor3) then
		object.TextColor3 = INK
		object.TextStrokeTransparency = 1
	else
		object.TextColor3 = Color3.new(1, 1, 1)
		object.TextStrokeColor3 = INK
		object.TextStrokeTransparency = 0.2
	end
end

local function corner(object: GuiObject, round: boolean?)
	local c = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = if round then UDim.new(1, 0) else UDim.new(0, Theme.Radius.button)
	c.Parent = object
end

-- A HUD button (call again after changing its colour, so the text stays readable).
function KitStyle.button(object: GuiButton, round: boolean?)
	if object:IsA("TextButton") then
		text(object, 18)
	end
	object.BackgroundTransparency = 0
	outline(object, Theme.Stroke.button)
	corner(object, round)
end

-- A hint or tag: a coloured panel with kit text.
function KitStyle.label(object: TextLabel)
	text(object, 22)
	outline(object, Theme.Stroke.card)
	corner(object)
end

return KitStyle
