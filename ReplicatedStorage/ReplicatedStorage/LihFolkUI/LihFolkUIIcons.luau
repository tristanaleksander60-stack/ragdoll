--!strict
--[[
	LihFolkUIIcons
	Icon registry for LihFolk UI. It ships EMPTY on purpose: LihFolk does not
	distribute icon art. Every icon has a drawn fallback (a coloured shape with a
	glyph), so every menu works and reads correctly before you add any art.

	HOW TO ADD YOUR OWN ICONS
	1. Make or license your icons (square PNG, 256 x 256 or 512 x 512, transparent
	   background, a 6 to 8 percent padding so outlines are not clipped).
	2. Upload them: Creator Hub > Development Items, or Studio's Asset Manager
	   (bulk import), or the 3D Importer for decals. Wait for moderation.
	3. Copy each image's asset id and paste it below as "rbxassetid://<id>",
	   replacing the empty string for that name. Use the IMAGE id, not the decal id
	   (in Studio, an ImageLabel set to the decal converts it and shows the image id).
	4. Or register at runtime: Icons.register("coin", "rbxassetid://<id>").

	Empty string = use the fallback. Do not paste ids you have not uploaded or checked.

	License: LihFolk. Free to use and modify in your games.
]]

local Theme = require(script.Parent.LihFolkUITheme)

local Icons = {}

export type Shape = "circle" | "square" | "diamond" | "none"
export type Fallback = {
	glyph: string, -- short text drawn on the shape; keep to 1 or 2 characters
	shape: Shape,
	color: Color3,
}

---------------------------------------------------------------------------
-- REGISTRY: name -> image asset. All placeholders. Fill with YOUR ids.
---------------------------------------------------------------------------
local ASSETS: { [string]: string } = {
	-- interface
	close = "", -- PLACEHOLDER: "rbxassetid://<your close X icon>"
	back = "", -- PLACEHOLDER
	info = "", -- PLACEHOLDER
	check = "", -- PLACEHOLDER
	lock = "", -- PLACEHOLDER
	timer = "", -- PLACEHOLDER
	arrow_right = "", -- PLACEHOLDER
	plus = "", -- PLACEHOLDER
	-- menus (HUD launcher buttons)
	shop = "", -- PLACEHOLDER
	codes = "", -- PLACEHOLDER
	rebirth = "", -- PLACEHOLDER
	settings = "", -- PLACEHOLDER
	daily = "", -- PLACEHOLDER
	-- currencies and rewards
	coin = "", -- PLACEHOLDER
	gem = "", -- PLACEHOLDER
	robux = "rbxasset://textures/ui/common/robux@2x.png", -- Roblox's own Robux icon, shipped with every client
	cash = "", -- PLACEHOLDER
	gift = "", -- PLACEHOLDER
	star = "", -- PLACEHOLDER
	crown = "", -- PLACEHOLDER
	boost = "", -- PLACEHOLDER
	pet = "", -- PLACEHOLDER
	-- settings rows
	music = "", -- PLACEHOLDER
	sound = "", -- PLACEHOLDER
	motion = "", -- PLACEHOLDER
	eye = "", -- PLACEHOLDER
	scale = "", -- PLACEHOLDER
	-- decoration (optional art; procedural versions are drawn when empty)
	pattern = "", -- PLACEHOLDER: a seamless tile for the panel background (white on transparent)
	sunburst = "", -- PLACEHOLDER: a white ray burst (white on transparent), spun behind featured items
}
Icons.Assets = ASSETS

---------------------------------------------------------------------------
-- FALLBACKS: what is drawn while an icon has no asset: a colour emoji on a
-- darkened shape (so a picture never melts into a shape of its own colour), or
-- for the few controls (close, back, info, arrows, plus) a plain symbol.
---------------------------------------------------------------------------
local P = Theme.Palette
local R = Theme.Roles

local FALLBACKS: { [string]: Fallback } = {
	close = { glyph = "X", shape = "none", color = P.white },
	back = { glyph = "<", shape = "circle", color = R.neutral.bottom },
	info = { glyph = "?", shape = "circle", color = R.info.bottom },
	check = { glyph = "\u{2713}", shape = "circle", color = R.go.bottom },
	lock = { glyph = "🔒", shape = "square", color = R.locked.shade },
	timer = { glyph = "⏱️", shape = "circle", color = R.neutral.bottom },
	arrow_right = { glyph = ">", shape = "circle", color = P.ink },
	plus = { glyph = "+", shape = "circle", color = R.go.bottom },
	shop = { glyph = "🛒", shape = "square", color = Theme.Accents.shop },
	codes = { glyph = "🎟", shape = "square", color = Theme.Accents.codes },
	rebirth = { glyph = "🔁", shape = "square", color = Theme.Accents.rebirth },
	settings = { glyph = "⚙️", shape = "square", color = Theme.Accents.settings },
	daily = { glyph = "📅", shape = "square", color = Theme.Accents.daily },
	coin = { glyph = "🪙", shape = "circle", color = Color3.fromHex("#FFC21F") },
	gem = { glyph = "💎", shape = "diamond", color = Color3.fromHex("#4FD8FF") },
	robux = { glyph = "R$", shape = "circle", color = Color3.fromHex("#1E9E5A") }, -- (drawn only if the built-in image above is ever cleared)
	cash = { glyph = "💵", shape = "square", color = Color3.fromHex("#38C46A") },
	gift = { glyph = "🥚", shape = "square", color = Theme.Accents.daily },
	star = { glyph = "⭐", shape = "none", color = P.gold },
	crown = { glyph = "👑", shape = "diamond", color = P.gold },
	boost = { glyph = "🛒", shape = "circle", color = R.info.bottom },
	pet = { glyph = "🐾", shape = "circle", color = Theme.Accents.rebirth },
	music = { glyph = "🎵", shape = "circle", color = Theme.Accents.settings },
	sound = { glyph = "🔊", shape = "circle", color = Theme.Accents.settings },
	motion = { glyph = "🎞️", shape = "circle", color = Theme.Accents.settings },
	eye = { glyph = "👁️", shape = "circle", color = Theme.Accents.settings },
	scale = { glyph = "🔍", shape = "circle", color = Theme.Accents.settings },
	-- Ragdoll Lab (phase K): drawn as colour emoji on the shape until painted art replaces them.
	map = { glyph = "🗺️", shape = "square", color = Theme.Accents.codes },
	friends = { glyph = "👫", shape = "square", color = Theme.Accents.rebirth },
	toolbox = { glyph = "🧰", shape = "square", color = Theme.Accents.codes },
	camera = { glyph = "🎬", shape = "square", color = Theme.Accents.codes },
	shake = { glyph = "📳", shape = "square", color = Theme.Accents.codes },
	keys = { glyph = "⌨️", shape = "square", color = Theme.Accents.settings },
	heart = { glyph = "🫀", shape = "circle", color = Theme.Accents.settings }, -- (round 4, M11: the dead monitor)
}
Icons.Fallbacks = FALLBACKS

-- The shape behind a picture: its colour taken this far toward a deep ink (the hue stays, the
-- light picture stands out on it; the captures show ice, banana and cloud on their shapes).
Icons.PICTURE_DARK = Color3.fromRGB(11, 12, 15)
Icons.PICTURE_SHADE = 0.55

-- The colour of the shape behind a picture drawn in this colour (other pictures framed the same
-- way use it: the HUD tiles' 3D pictures).
function Icons.shapeColor(color: Color3): Color3
	return color:Lerp(Icons.PICTURE_DARK, Icons.PICTURE_SHADE)
end

local DEFAULT_FALLBACK: Fallback = { glyph = "?", shape = "circle", color = R.neutral.bottom }

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
local warned: { [string]: boolean } = {}

local function normalise(asset: string | number): string?
	if typeof(asset) == "number" then
		return "rbxassetid://" .. tostring(math.floor(asset))
	end
	local text = asset :: string
	if text == "" then
		return nil
	end
	if text:match("^rbxassetid://%d+$") or text:match("^rbxasset://") or text:match("^rbxthumb://") then
		return text
	end
	if text:match("^%d+$") then
		return "rbxassetid://" .. text
	end
	return nil
end

-- Returns the asset string for a name, or nil when the fallback should be used.
function Icons.get(name: string): string?
	local raw = Icons.Assets[name]
	if raw == nil or raw == "" then
		return nil
	end
	local asset = normalise(raw)
	if asset == nil and not warned[name] then
		warned[name] = true
		warn(`[LihFolkUI] Icon "{name}" has an invalid asset string "{raw}". Use "rbxassetid://<id>". Drawing fallback.`)
	end
	return asset
end

function Icons.has(name: string): boolean
	return Icons.get(name) ~= nil
end

function Icons.register(name: string, asset: string | number)
	local value = normalise(asset)
	if value == nil then
		warn(`[LihFolkUI] Icons.register("{name}") ignored: not an asset id.`)
		return
	end
	Icons.Assets[name] = value
end

function Icons.registerMany(map: { [string]: string | number })
	for name, asset in map do
		Icons.register(name, asset)
	end
end

function Icons.fallback(name: string): Fallback
	return Icons.Fallbacks[name] or DEFAULT_FALLBACK
end

-- Builds the icon: an ImageLabel when an asset is registered, otherwise a drawn
-- fallback. Always square (UIAspectRatioConstraint), always non-interactive.
-- `tint` recolours a registered image (leave nil for full-colour icons).
function Icons.make(name: string, size: UDim2, tint: Color3?): GuiObject
	local asset = Icons.get(name)
	if asset then
		local image = Instance.new("ImageLabel")
		image.Name = "Icon_" .. name
		image.Size = size
		image.BackgroundTransparency = 1
		image.Image = asset
		image.ScaleType = Enum.ScaleType.Fit
		image.ImageColor3 = tint or Color3.new(1, 1, 1)
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.AspectRatio = 1
		ratio.Parent = image
		return image
	end

	local spec = Icons.fallback(name)
	-- (A colour emoji is a picture, not a letter: it fills more of the shape, and the shape
	-- behind it is darkened so a picture in the shape's own colour, ice on light blue or a
	-- banana on yellow, still stands out.)
	local picture = (string.byte(spec.glyph, 1) or 0) > 127
	local fill = if picture then spec.color:Lerp(Icons.PICTURE_DARK, Icons.PICTURE_SHADE) else spec.color
	local holder = Instance.new("Frame")
	holder.Name = "Icon_" .. name
	holder.Size = size
	holder.BackgroundTransparency = 1
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = holder

	if spec.shape ~= "none" then
		local shape = Instance.new("Frame")
		shape.Name = "Shape"
		shape.AnchorPoint = Vector2.new(0.5, 0.5)
		shape.Position = UDim2.fromScale(0.5, 0.5)
		shape.BackgroundColor3 = fill
		shape.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		if spec.shape == "circle" then
			shape.Size = UDim2.fromScale(1, 1)
			corner.CornerRadius = UDim.new(0.5, 0)
		elseif spec.shape == "square" then
			shape.Size = UDim2.fromScale(0.9, 0.9)
			corner.CornerRadius = UDim.new(0.28, 0)
		else -- diamond: a rounded square turned 45 degrees, sized to stay inside the box
			shape.Size = UDim2.fromScale(0.68, 0.68)
			shape.Rotation = 45
			corner.CornerRadius = UDim.new(0.2, 0)
		end
		corner.Parent = shape
		local outline = Instance.new("UIStroke")
		outline.Color = P.ink
		outline.Thickness = 1.5 -- (dark glass: thin outlines)
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.LineJoinMode = Enum.LineJoinMode.Round
		outline.Parent = shape
		local shine = Instance.new("UIGradient")
		shine.Rotation = 90
		shine.Color = ColorSequence.new(fill:Lerp(Color3.new(1, 1, 1), if picture then 0.2 else 0.35), fill)
		shine.Parent = shape
		shape.Parent = holder
	end

	if spec.glyph ~= "" then
		local glyph = Instance.new("TextLabel")
		glyph.Name = "Glyph"
		glyph.AnchorPoint = Vector2.new(0.5, 0.5)
		glyph.Position = UDim2.fromScale(0.5, 0.5)
		glyph.Size = if picture then UDim2.fromScale(0.94, 0.94) else UDim2.fromScale(0.78, 0.78)
		glyph.BackgroundTransparency = 1
		glyph.FontFace = Theme.Fonts.display
		glyph.Text = spec.glyph
		glyph.TextColor3 = if spec.shape == "none" then spec.color else P.white
		glyph.TextScaled = true
		glyph.ZIndex = 2
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = 8
		limit.MaxTextSize = 64
		limit.Parent = glyph
		local glyphStroke = Instance.new("UIStroke")
		-- (A picture gets a thin white sticker edge: a dark one, a black hole or an ant, still
		-- stands out on its darkened shape.)
		glyphStroke.Color = if picture then P.white else P.ink
		glyphStroke.Transparency = if picture then 0.15 else 0
		glyphStroke.Thickness = if picture then 1.5 else 2
		glyphStroke.LineJoinMode = Enum.LineJoinMode.Round
		glyphStroke.Parent = glyph
		glyph.Parent = holder
	end

	return holder
end

return Icons
