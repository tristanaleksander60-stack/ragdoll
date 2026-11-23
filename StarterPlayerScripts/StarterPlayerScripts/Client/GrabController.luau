--!strict
-- Grab and throw, the genre's core verb (Fling Things and People style).
--
-- Player view (default):
--   Computer: hold the left button on a dummy within reach of your character to pick it up by the
--     limb you clicked; move the mouse to carry it, let go to drop it with the swing you gave it.
--     Right button throws it hard where you are looking; the wheel moves it nearer or further.
--   Phone: aim the dot in the middle of the screen at a dummy and tap GRAB; turn the camera to
--     carry it; tap DROP to let go (it keeps the swing), or THROW to fling it where you look.
-- Lab view: press on any of your dummies and drag it under your finger; let go to throw.
--
-- The grab is a spring (AlignPosition) on an attachment at the exact point grabbed, pulled to a
-- point along your aim. A green tether runs from your hand. Runs on the client that simulates the
-- dummy, so it answers in the same frame.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll"))
local Dummies = require(Shared:WaitForChild("Dummies"))
local NORMAL_GRAVITY = require(Shared:WaitForChild("Ragdoll"):WaitForChild("Config")).NORMAL_GRAVITY

local Client = script.Parent
local PokeController = require(Client:WaitForChild("PokeController"))
local DummySim = require(Client:WaitForChild("DummySim"))
local FxController = require(Client:WaitForChild("FxController"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local Toast = require(Client:WaitForChild("Toast"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))
local ToolCatalog = require(Client:WaitForChild("ToolCatalog"))
local HudSlots = require(Client:WaitForChild("HudSlots"))
local PlayerGrabClient = require(Client:WaitForChild("PlayerGrabClient"))

local player = Players.LocalPlayer

local MIN_DISTANCE, MAX_DISTANCE = 6, 110
local MAX_REACH = 200 -- lab view: studs from the camera to start a grab
local GRAB_REACH = 40 -- player view: studs from your character to start a grab
local HOLD_REACH = 34 -- player view: a held body stays within this of your character
local THROW_SHARE = 0.55 -- share of the drag speed added on release
local MAX_THROW = 140 -- studs/s
local THROW_SPEED = 95 -- studs/s for a deliberate throw (right button / THROW)
local THROW_LIFT = 0.22
local GROUND_CLEARANCE = 1.2
local GREEN = Color3.fromRGB(120, 230, 140)
local SHOULDER_OFFSET = Vector3.new(2, 0.6, 0)

local GrabController = {}

type Grab = {
	model: Model,
	part: BasePart,
	attachment: Attachment,
	align: AlignPosition,
	highlight: Highlight,
	marker: Part,
	beam: Beam?,
	handAttachment: Attachment?,
	distance: number,
	input: InputObject?, -- the touch that holds it (nil for the mouse or the centre dot)
	center: boolean, -- aimed with the dot in the middle of the screen
	history: { { t: number, p: Vector3 } },
}

local current: Grab? = nil
local tooFarAt = -math.huge -- the last aim was at a dummy out of reach
local tooFarToldAt = -math.huge
local notOursAt = -math.huge -- the last aim was at a dummy another player's client moves
local pinchStart: number? = nil
local pinchDistance: number? = nil

-- Phone pad (player view): centre dot, GRAB/DROP and THROW.
local buttonsGui: ScreenGui? = nil
local pad: ScreenGui? = nil
local mouseHelp: ScreenGui? = nil -- the mouse help (round 2, N5): a computer, the player view, Grab
local dot: Frame? = nil
local BLAME_REFRESH = 2 -- s between "still mine" reports while holding (blame lasts 5 s)
local grabButton: TextButton? = nil
local throwButton: TextButton? = nil

local function rootPart(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function screenCenter(): Vector2
	local camera = Workspace.CurrentCamera
	return camera.ViewportSize / 2
end

-- Viewport coordinates (touch positions are reported below the top bar inset).
local function pointerPosition(grab: Grab): Vector2
	if grab.center then
		return screenCenter()
	end
	if grab.input then
		local p = grab.input.Position
		return Vector2.new(p.X, p.Y) + GuiService:GetGuiInset()
	end
	return UserInputService:GetMouseLocation()
end

local function targetFor(grab: Grab): Vector3
	local camera = Workspace.CurrentCamera
	local screen = pointerPosition(grab)
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local target = ray.Origin + ray.Direction.Unit * grab.distance
	-- In the player view the body stays within reach of your character.
	local root = rootPart()
	if root and not ViewMode.isLab() then
		local offset = target - root.Position
		if offset.Magnitude > HOLD_REACH then
			target = root.Position + offset.Unit * HOLD_REACH
		end
	end
	-- Never pull a body through the floor.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { grab.model, grab.marker, player.Character :: Instance }
	local hit = Workspace:Raycast(target + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), params)
	if hit and target.Y < hit.Position.Y + GROUND_CLEARANCE then
		target = Vector3.new(target.X, hit.Position.Y + GROUND_CLEARANCE, target.Z)
	end
	return target
end

local function unbindHeldControls()
	ContextActionService:UnbindAction("RagdollLabGrabDistance")
	ContextActionService:UnbindAction("RagdollLabGrabThrow")
end

local function refreshPad()
	local holdingAny = current ~= nil or PlayerGrabClient.isHolding()
	if grabButton then
		grabButton.Text = "DROP"
		grabButton.Visible = holdingAny -- (a tap on the ragdoll grabs; the buttons are for what you hold)
	end
	if throwButton then
		throwButton.Visible = holdingAny
	end
end

-- throwDirection: a deliberate throw that way; otherwise the body keeps the swing you gave it.
local function release(throw: boolean, throwDirection: Vector3?)
	local grab = current
	if not grab then
		return
	end
	current = nil
	pinchStart = nil
	pinchDistance = nil
	unbindHeldControls()

	-- Swing speed from the last 0.12 s of carrying.
	local velocity = Vector3.zero
	local h = grab.history
	if throw and #h >= 2 then
		local newest = h[#h]
		local oldest = h[1]
		for i = #h, 1, -1 do
			if newest.t - h[i].t > 0.12 then
				oldest = h[i]
				break
			end
		end
		local dt = newest.t - oldest.t
		if dt > 1e-3 then
			velocity = (newest.p - oldest.p) / dt
		end
	end

	grab.align:Destroy()
	grab.attachment:Destroy()
	grab.highlight:Destroy()
	grab.marker:Destroy()
	if grab.handAttachment then
		grab.handAttachment:Destroy() -- takes the tether beam with it
	end
	if grab.model.Parent then
		ActiveRagdoll.setHeld(grab.model, false)
		Dummies.blameLocal(grab.model, player.UserId) -- you threw it: it can land on you, nobody else
		local root = rootPart()
		if root then
			Net.event(Net.Names.DummyBlame):FireServer(grab.model, root) -- and everyone else agrees
		end
		if throwDirection then
			local dir = (throwDirection.Unit + Vector3.new(0, THROW_LIFT, 0)).Unit
			ActiveRagdoll.push(grab.model, dir * THROW_SPEED)
			FxController.localEvent("Hit", grab.part.Position, THROW_SPEED, "Throw")
		elseif velocity.Magnitude > 1 then
			local boost = velocity * THROW_SHARE
			if boost.Magnitude > MAX_THROW then
				boost = boost.Unit * MAX_THROW
			end
			ActiveRagdoll.push(grab.model, boost)
			if velocity.Magnitude > 40 then
				FxController.localEvent("Hit", grab.part.Position, math.min(velocity.Magnitude, 110), "Throw")
			end
		end
	end
	refreshPad()
end

local function throwForward()
	if PlayerGrabClient.busy() then
		PlayerGrabClient.throw()
		return
	end
	if current then
		release(false, Workspace.CurrentCamera.CFrame.LookVector)
	end
end

-- What a press at this viewport point would grab: (dummy, part, point, ray) or nil.
local function aimAt(screen: Vector2): (Model?, BasePart?, Vector3?, Ray?)
	local camera = Workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local fx = Workspace:FindFirstChild("LocalFx")
	if fx then
		table.insert(ignore, fx)
	end
	params.FilterDescendantsInstances = ignore
	local result = Workspace:Raycast(ray.Origin, ray.Direction * MAX_REACH, params)
	if not result or not result.Instance:IsA("BasePart") then
		return nil, nil, nil, nil
	end
	local part = result.Instance :: BasePart
	local model = DummySim.simulatedDummyOf(part)
	if not model then
		if Dummies.of(part) then
			notOursAt = os.clock()
		end
		return nil, nil, nil, nil
	end
	if not ViewMode.isLab() then
		local root = rootPart()
		if root and (result.Position - root.Position).Magnitude > GRAB_REACH then
			tooFarAt = os.clock()
			return nil, nil, nil, nil -- too far from you: walk closer
		end
	end
	return model, part, result.Position, ray
end

local function begin(screen: Vector2, input: InputObject?, center: boolean): boolean
	local before, beforeOurs = tooFarAt, notOursAt
	local model, part, point, ray = aimAt(screen)
	-- (V6-5: a body inside a lab creature cannot be pulled out of it.)
	if not model or not part or not point or not ray or model:GetAttribute("InMachine") ~= nil then
		-- No dummy there: another player, in the plaza (phase D)?
		if not ViewMode.isLab() and PlayerGrabClient.tryAt(screen) then
			return true
		end
		-- A grab that does nothing always says why (at most every few seconds).
		if os.clock() - tooFarToldAt > 4 then
			if tooFarAt ~= before then
				tooFarToldAt = os.clock()
				Toast.show("Too far away. Walk closer to grab it")
			elseif notOursAt ~= beforeOurs then
				tooFarToldAt = os.clock()
				Toast.show("Another player is moving this one. Hit it instead!")
			end
		end
		return false
	end

	-- Parent first: WorldPosition on an unparented attachment is taken as an offset from the part.
	local attachment = Instance.new("Attachment")
	attachment.Name = "GrabPoint"
	attachment.Parent = part
	attachment.WorldPosition = point

	local mass = (model:GetAttribute("Mass") :: number?) or 10
	local align = Instance.new("AlignPosition")
	align.Name = "Grab"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.Position = point
	align.MaxForce = mass * NORMAL_GRAVITY * 9
	align.Responsiveness = 45
	align.MaxVelocity = 160
	align.ApplyAtCenterOfMass = false
	align.Parent = part

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.85
	highlight.FillColor = GREEN
	highlight.OutlineColor = GREEN
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model

	local marker = Instance.new("Part")
	marker.Name = "GrabMarker"
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.one * 0.6
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	marker.Material = Enum.Material.Neon
	marker.Color = GREEN
	marker.Position = point
	marker.Parent = Workspace:FindFirstChild("LocalFx") or Workspace

	-- A tether from your hand to the grab point, so it is always clear what you are holding.
	local beam: Beam? = nil
	local handAttachment: Attachment? = nil
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("HumanoidRootPart"))
	if hand and hand:IsA("BasePart") then
		local a = Instance.new("Attachment")
		a.Name = "GrabTether"
		a.Parent = hand
		handAttachment = a
		local b = Instance.new("Beam")
		b.Name = "GrabTether"
		b.Attachment0 = a
		b.Attachment1 = attachment
		b.Width0 = 0.18
		b.Width1 = 0.1
		b.FaceCamera = true
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Segments = 12
		b.CurveSize0 = 2
		b.Transparency = NumberSequence.new(0.15, 0.45)
		b.Color = ColorSequence.new(GREEN)
		b.Parent = a
		beam = b
	end

	current = {
		model = model,
		part = part,
		attachment = attachment,
		align = align,
		highlight = highlight,
		marker = marker,
		beam = beam,
		handAttachment = handAttachment,
		distance = math.clamp((point - ray.Origin).Magnitude, MIN_DISTANCE, MAX_DISTANCE),
		input = input,
		center = center,
		history = {},
	}
	ActiveRagdoll.setHeld(model, true)
	FxController.localEvent("Hit", point, 8, "Grab")
	Net.event(Net.Names.HitRequest):FireServer(part, point, ray.Direction, "Grab")
	-- While it is held the blame stays yours (it would run out after a few seconds), so everyone
	-- else's client keeps it a ghost: a held dummy never shoves another player.
	local held = current
	task.spawn(function()
		while true do
			task.wait(BLAME_REFRESH)
			if current ~= held or not model.Parent then
				return
			end
			local root = rootPart()
			if root then
				Net.event(Net.Names.DummyBlame):FireServer(model, root)
			end
		end
	end)
	local listener = PokeController.onUsed
	if listener then
		task.spawn(listener, "Grab", point)
	end

	-- While holding: the wheel moves the body (not the camera) and the right button throws.
	ContextActionService:BindActionAtPriority("RagdollLabGrabDistance", function(_, state, inputObject)
		local grab = current
		if grab and state == Enum.UserInputState.Change then
			grab.distance = math.clamp(grab.distance - inputObject.Position.Z * 3, MIN_DISTANCE, MAX_DISTANCE)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.UserInputType.MouseWheel)
	-- (22 Nov 2026, owner: right click while holding no longer launches the ragdoll; it turns the camera.)
	refreshPad()
	return true
end

------------------------------------------------------------------------------------------------
-- Phone pad

local function padWanted(): boolean
	return ViewMode.isTouch() and not ViewMode.isLab() and PokeController.active() and not PokeController.handIsEmpty() and PokeController.getSelected() == "Grab"
end

-- The mouse help: shown on a computer in the player view while Grab is picked (not while the
-- weapon catalog covers the bar: the help line steps aside then too).
local function mouseHelpWanted(): boolean
	return not ViewMode.isTouch() and not ViewMode.isLab() and PokeController.active() and PokeController.getSelected() == "Grab" and not ToolCatalog.isOpen()
end

-- A small mouse with the part you use lit: "left", "right" or "wheel".
local function mouseGlyph(lit: "left" | "right" | "wheel"): Frame
	local body = Instance.new("Frame")
	body.Name = "Mouse"
	body.Size = UDim2.fromOffset(18, 26)
	body.BackgroundColor3 = Theme.Palette.slab
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = body
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Palette.helpText
	stroke.Thickness = 1.5
	stroke.Parent = body
	if lit ~= "wheel" then
		-- The lit button: its outer top corner rounded as the mouse's own (a clip would not follow
		-- the rounding), the rest square, drawn from three pieces.
		local left = lit == "left"
		local lit_ = Theme.Palette.go
		local half = Instance.new("Frame")
		half.Name = "Lit"
		half.BorderSizePixel = 0
		half.BackgroundColor3 = lit_
		half.Size = UDim2.fromOffset(8, 11)
		half.Position = UDim2.fromOffset(if left then 0 else 10, 0)
		local halfCorner = Instance.new("UICorner")
		halfCorner.CornerRadius = UDim.new(0, 6)
		halfCorner.Parent = half
		half.Parent = body
		local inner = Instance.new("Frame") -- the square inner side, by the middle line
		inner.Name = "LitInner"
		inner.BorderSizePixel = 0
		inner.BackgroundColor3 = lit_
		inner.Size = UDim2.fromOffset(4, 11)
		inner.Position = UDim2.fromOffset(if left then 4 else 10, 0)
		inner.Parent = body
		local foot = Instance.new("Frame") -- the square bottom, by the split
		foot.Name = "LitFoot"
		foot.BorderSizePixel = 0
		foot.BackgroundColor3 = lit_
		foot.Size = UDim2.fromOffset(8, 5)
		foot.Position = UDim2.fromOffset(if left then 0 else 10, 6)
		foot.Parent = body
	end
	local split = Instance.new("Frame")
	split.Name = "Split"
	split.BorderSizePixel = 0
	split.BackgroundColor3 = Theme.Palette.helpText
	split.Size = UDim2.fromOffset(18, 1)
	split.Position = UDim2.fromOffset(0, 11)
	split.Parent = body
	local wheel = Instance.new("Frame")
	wheel.Name = "Wheel"
	wheel.BorderSizePixel = 0
	wheel.AnchorPoint = Vector2.new(0.5, 0)
	wheel.Position = UDim2.new(0.5, 0, 0, 3)
	wheel.Size = UDim2.fromOffset(4, 7)
	wheel.BackgroundColor3 = if lit == "wheel" then Theme.Palette.go else Theme.Palette.helpText
	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(1, 0)
	wc.Parent = wheel
	wheel.Parent = body
	return body
end

local function buildMouseHelp()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MouseHelp"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)
	gui.Enabled = false
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = Theme.Palette.dusk
	panel.BackgroundTransparency = Theme.Glass.panel
	HudSlots.apply(panel, "MouseHelp", HudSlots.context(false, false))
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Palette.ink
	stroke.Thickness = Theme.Stroke.panel
	stroke.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel
	local rows: { { lit: "left" | "right" | "wheel", word: string, how: string } } = {
		{ lit = "left", word = "Grab", how = "hold on a dummy/player" },
		{ lit = "right", word = "Throw", how = "where you look" },
		{ lit = "wheel", word = "Distance", how = "nearer / further" },
	}
	for i, r in rows do
		local row = Instance.new("Frame")
		row.Name = r.word
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 28)
		row.LayoutOrder = i
		row.Parent = panel
		local glyph = mouseGlyph(r.lit)
		glyph.AnchorPoint = Vector2.new(0, 0.5)
		glyph.Position = UDim2.new(0, 1, 0.5, 0)
		glyph.Parent = row
		local word = Instance.new("TextLabel")
		word.Name = "Word"
		word.BackgroundTransparency = 1
		word.Position = UDim2.fromOffset(30, 0)
		word.Size = UDim2.new(1, -30, 0, 15)
		word.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
		word.TextSize = 15
		word.TextColor3 = Theme.Palette.textHi
		word.TextXAlignment = Enum.TextXAlignment.Left
		word.Text = r.word
		word.Parent = row
		local how = Instance.new("TextLabel")
		how.Name = "How"
		how.BackgroundTransparency = 1
		how.Position = UDim2.fromOffset(30, 15)
		how.Size = UDim2.new(1, -30, 0, 13)
		how.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
		how.TextSize = 13
		how.TextColor3 = Theme.Palette.helpLow
		how.TextXAlignment = Enum.TextXAlignment.Left
		how.Text = r.how
		how.Parent = row
	end
	panel.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	mouseHelp = gui
end

local function roundButton(name: string, text: string, size: number, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(1, 1)
	b.Size = UDim2.fromOffset(size, size)
	b.BackgroundColor3 = color
	b.Text = text
	b.AutoButtonColor = true
	KitStyle.button(b, true)
	b.TextSize = if size > 70 then 18 else 15
	return b
end

local function pop(object: GuiObject)
	KitStyle.pop(object, 0.86) -- (on the slot's own UIScale: never a second one)
end

local placePad: () -> () -- below, with the numbers

local function buildPad()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GrabPad"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- the dot sits exactly on the camera's centre ray
	gui.Enabled = false

	local d = Instance.new("Frame")
	d.Name = "Dot"
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Position = UDim2.fromScale(0.5, 0.5)
	d.Size = UDim2.fromOffset(14, 14)
	d.BackgroundColor3 = Color3.new(1, 1, 1)
	d.BackgroundTransparency = 0.2
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = d
	local ds = Instance.new("UIStroke")
	ds.Thickness = 2
	ds.Color = Color3.new(0, 0, 0)
	ds.Transparency = 0.4
	ds.Parent = d
	d.Visible = false -- (no aiming with the middle any more: GrabController.tapAt)
	d.Parent = gui
	dot = d

	-- GRAB and THROW live in their own safe-area layer (the dot's layer ignores the insets, so it
	-- sits exactly on the camera's centre ray); HudSlots places them by the jump button.
	local buttons = Instance.new("ScreenGui")
	buttons.Name = "GrabButtons"
	buttons.ResetOnSpawn = false
	buttons.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)
	buttons.Enabled = false
	local holder = Instance.new("Frame")
	holder.Name = "Buttons"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = buttons
	buttonsGui = buttons

	local g = roundButton("Grab", "GRAB", 76, KitStyle.GO)
	KitStyle.icon(g, KitStyle.HUD_ICONS.Grab, "top") -- (UI v2: the drawn glove over the word)
	g.Parent = holder
	g.Activated:Connect(function()
		pop(g)
		if PlayerGrabClient.isHolding() then
			PlayerGrabClient.drop()
			refreshPad()
		elseif current then
			release(true)
		elseif not begin(screenCenter(), nil, true) then
			-- Nothing grabbable under the dot: show it.
			if dot then
				dot.BackgroundColor3 = Color3.fromRGB(255, 90, 70)
				task.delay(0.25, function()
					if dot then
						dot.BackgroundColor3 = Color3.new(1, 1, 1)
					end
				end)
			end
		end
	end)
	grabButton = g

	local t = roundButton("Throw", "THROW", 60, KitStyle.SLAB)
	KitStyle.icon(t, KitStyle.HUD_ICONS.Throw, "top")
	t.Parent = holder
	t.Activated:Connect(function()
		pop(t)
		throwForward()
	end)
	throwButton = t

	gui.Parent = player:WaitForChild("PlayerGui")
	buttons.Parent = player:WaitForChild("PlayerGui")
	pad = gui
	HudSlots.watch(placePad)
	refreshPad()
end

-- By the jump button: Roblox draws it 70 px near the corner on a phone (GRAB and THROW go just
-- left of it) and 120 px higher up on a tablet (they go above it). HudSlots has the numbers.
function placePad()
	local g, t = grabButton, throwButton
	if not g or not t then
		return
	end
	local ctx = HudSlots.context(true, false)
	HudSlots.apply(g, "Grab", ctx)
	HudSlots.apply(t, "Throw", ctx)
end

local function updatePad()
	local help = mouseHelp
	if help then
		local show = mouseHelpWanted()
		if help.Enabled ~= show then
			help.Enabled = show
		end
	end
	local gui = pad
	if not gui then
		return
	end
	local wanted = padWanted()
	if current and ViewMode.isTouch() and PokeController.handIsEmpty() then
		release(false) -- (the Grab slot pressed again while carrying: it is put down)
	end
	if gui.Enabled ~= wanted then
		gui.Enabled = wanted
		if buttonsGui then
			buttonsGui.Enabled = wanted
		end
		if wanted then
			placePad()
		end
	end
	-- Aiming with the dot: the camera looks over your right shoulder (like shift lock), so the dot
	-- is beside your avatar instead of on the back of its head.
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and player:GetAttribute("ViewBobbing") ~= true then -- (ViewBob owns the offset while it bobs)
		-- (V8-0.2: a pad fires at the screen centre, which sat on the back of your own head: over the
		-- shoulder for a pad too, in the player view.)
		local padShoulder = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).V8_FIRST_HIT
			and not ViewMode.isLab() and string.sub(game:GetService("UserInputService"):GetLastInputType().Name, 1, 7) == "Gamepad"
		local offset = if wanted or padShoulder then SHOULDER_OFFSET else Vector3.zero
		if humanoid.CameraOffset ~= offset then
			humanoid.CameraOffset = offset
		end
	end
	if wanted and dot and dot.Visible and not current then
		-- The dot turns green over something you can grab.
		local model = aimAt(screenCenter())
		local want = if model then GREEN else Color3.new(1, 1, 1)
		if dot.BackgroundColor3 ~= want and dot.BackgroundColor3 ~= Color3.fromRGB(255, 90, 70) then
			dot.BackgroundColor3 = want
		end
	elseif wanted and dot then
		dot.BackgroundColor3 = GREEN
	end
end

------------------------------------------------------------------------------------------------

local function onRender()
	updatePad()
	local grab = current
	if not grab then
		return
	end
	if not grab.model.Parent or not grab.part.Parent or ActiveRagdoll.getState(grab.model) == nil then
		release(false)
		return
	end
	local target = targetFor(grab)
	grab.align.Position = target
	grab.marker.Position = target
	local now = os.clock()
	table.insert(grab.history, { t = now, p = target })
	while #grab.history > 12 do
		table.remove(grab.history, 1)
	end
end

function GrabController.isGrabbing(): boolean
	return current ~= nil
end

-- (23 Nov 2026, owner: "on a phone just tap a ragdoll".) A short tap in the player view picks up the ragdoll under the
-- finger, or the nearest one within a fingertip of it; it then hangs in front of you until DROP or THROW. A drag still
-- turns the camera.
local TAP_RINGS = { 14, 28, 42 } -- px
function GrabController.tapAt(at: Vector2): boolean
	if not padWanted() or current or PlayerGrabClient.busy() or PlayerGrabClient.isHolding() then
		return false
	end
	local spot = at
	if not aimAt(at) then
		local found = false
		for _, r in TAP_RINGS do
			for i = 0, 7 do
				local a = i * math.pi / 4
				local try = at + Vector2.new(math.cos(a), math.sin(a)) * r
				if aimAt(try) then
					spot, found = try, true
					break
				end
			end
			if found then
				break
			end
		end
	end
	return begin(spot, nil, true)
end

-- Called by LabCamera's pointer routing on a press (viewport position; the touch, or nil for the
-- mouse). Returns true when a dummy was grabbed and the press now belongs to the grab. On a phone in
-- the player view the press belongs to the camera: grabbing is done with the dot and GRAB.
function GrabController.tryBegin(viewportPosition: Vector2, input: InputObject?): boolean
	if current or PokeController.getSelected() ~= "Grab" or not PokeController.active() then
		return false
	end
	if input and not ViewMode.isLab() then
		return false
	end
	return begin(viewportPosition, input, false)
end

-- Phase 0 (gamepad X): grab what is under the middle of the screen (Grab is picked for it when it
-- is on the bar), or throw what you hold where you look, a dummy or a player in the plaza.
function GrabController.padGrab()
	if PlayerGrabClient.isHolding() then
		PlayerGrabClient.throw()
		refreshPad()
		return
	end
	if current then
		throwForward()
		refreshPad()
		return
	end
	if not PokeController.active() then
		return
	end
	if PokeController.getSelected() ~= "Grab" then
		PokeController.select("Grab")
	end
	begin(screenCenter(), nil, true)
	refreshPad()
end

function GrabController.start()
	buildPad()
	buildMouseHelp()
	ViewMode.onChanged(function()
		release(false)
		PlayerGrabClient.drop()
	end)
	PlayerGrabClient.onChanged = refreshPad
	UserInputService.InputEnded:Connect(function(input)
		-- A player held with the mouse: letting go throws them where you look.
		if not current and input.UserInputType == Enum.UserInputType.MouseButton1 and PlayerGrabClient.busy() then
			PlayerGrabClient.throw()
			refreshPad()
			return
		end
		local grab = current
		if not grab or grab.center then
			return
		end
		if grab.input then
			if input == grab.input then
				release(true)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			release(true)
		end
	end)
	-- Lab view: a second finger pinching moves the held body nearer or further.
	UserInputService.TouchPinch:Connect(function(_positions, scale, _velocity, state)
		local grab = current
		if not grab or not ViewMode.isLab() then
			return
		end
		if state == Enum.UserInputState.Begin then
			pinchStart = scale
			pinchDistance = grab.distance
		elseif state == Enum.UserInputState.Change and pinchStart and pinchDistance then
			grab.distance = math.clamp(pinchDistance * (pinchStart / math.max(scale, 0.05)), MIN_DISTANCE, MAX_DISTANCE)
		end
	end)
	RunService:BindToRenderStep("RagdollLabGrab", Enum.RenderPriority.Input.Value + 1, onRender)
end

return GrabController
