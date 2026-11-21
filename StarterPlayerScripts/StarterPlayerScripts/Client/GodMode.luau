--!strict
-- GOD MODE: create life (Config.GOD_PASS, Server/Systems/DummySpawn).
-- V9-0l (owner, 21 Nov 2026: "give everyone GOD MODE free in the beta, fully 3D, interactive and
-- beautiful, and much easier to spawn e.g. 10 quickly where you want, not just random places"):
--   * The window: a gold header (FREE · BETA, or FOUNDER for who bought it), each kind of ragdoll as a
--     live turning 3D dummy in its colour (pick one), the amount 1 · 5 · 10 · 25 (within your device's
--     cap), the pattern Point · Line · Circle · Grid · Tower · Rain (Shared/GodPattern), the spacing, PLACE
--     and CLEAR MINE. Without GOD MODE (only once the beta ends): what it gives and GET GOD MODE.
--   * PLACE: a ghost of the whole pattern follows your aim on the floor, green where it may go (your
--     own lab, in reach), red where not. Click / tap / RT creates it all; hold and drag paints single
--     ones. I opens the window or leaves placing (G is Grab), the wheel changes the amount, Q/E turn the pattern,
--     R/F change the spacing (only while placing), Esc or B leaves. A phone gets a small bar out of the
--     thumbs' way: the pattern, the amount, SPAWN (again at the last spot) and DONE.
--   * The beta gift: a golden "GOD MODE unlocked: FREE during beta!" (a small pill on a phone), the
--     picture flying to the GOD button, the first time; a small chip on later days.
-- The server decides and checks everything (DummySpawn).

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any
local Shop = require(Shared:WaitForChild("Shop")) :: any
local GodRules = require(Shared:WaitForChild("GodRules")) :: any
local GodPattern = require(Shared:WaitForChild("GodPattern")) :: any
local Zones = require(Shared:WaitForChild("Zones")) :: any
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any
local Icons = require(UI:WaitForChild("LihFolkUIIcons")) :: any

local GodMode = {}

GodMode.TYPES = {
	{ id = "MINI", word = "TINY", color = Color3.fromRGB(120, 210, 255), hex = "#78D2FF" },
	{ id = "HEAVY", word = "HEAVY", color = Color3.fromRGB(150, 150, 160), hex = "#9696A0" },
	{ id = "BOUNCY", word = "BOUNCY", color = Color3.fromRGB(255, 140, 220), hex = "#FF8CDC" },
	{ id = "FLOPPY", word = "FLOPPY", color = Color3.fromRGB(255, 220, 120), hex = "#FFDC78" },
}
GodMode.REACH = 80 -- studs (DummySpawn.REACH)
GodMode.PAINT_STEP = 3.5 -- studs the aim moves before a drag paints the next one
GodMode.PAINT_EVERY = 0.32 -- s between two painted ones (DummySpawn.PAINT_GAP)
GodMode.TURN_STEP = math.rad(15)

local player = Players.LocalPlayer
local window: any = nil
local offer: GuiObject? = nil
local controls: GuiObject? = nil
local statusLine: TextLabel? = nil
local headerPill: Frame? = nil

-- The choices.
local kind = "MINI"
local amount = 5
local pattern = "Line"
local spacing = GodPattern.SPACING
local turn = 0

local kindCards: { [string]: any } = {}
local amountButtons: { [number]: any } = {}
local patternButtons: { [string]: any } = {}
local spacingLabel: TextLabel? = nil

-- Placing.
local placing = false
local ghosts: Folder? = nil
local ghostParts: { BasePart } = {}
local aimAt: Vector3? = nil
local lastSpot: Vector3? = nil
local tapped = false -- (a phone: the first tap on the floor this placing)
local placeBar: ScreenGui? = nil
local barPattern: any = nil
local barAmount: any = nil
local barHint: TextLabel? = nil

------------------------------------------------------------------------------------------------
-- Who may create

-- A phone or tablet without a mouse (ViewMode: the Studio simulator with DevTouch counts too).
local function isTouch(): boolean
	local ok, touch = pcall(function()
		return (require(script.Parent:WaitForChild("ViewMode")) :: any).isTouch()
	end)
	return if ok then touch == true else UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function hasGod(): boolean
	return player:GetAttribute("God") == true or player:GetAttribute("GodBeta") == true
end

-- Whether creating life needs GOD MODE here (the same rule as DummySpawn.godGated).
function GodMode.gated(): boolean
	local pass = Shop.byKey.God
	return pass ~= nil and GodRules.gated(Config.GOD_PASS == true, pass.id, RunService:IsStudio())
end

-- V9-0f: whether this player sees the GOD launcher: with GOD MODE (the pass or the beta gift) or during
-- the free trial (or everyone while creating is free).
function GodMode.launcherShown(): boolean
	return GodRules.launcherShown(GodMode.gated(), hasGod(), player:GetAttribute("GodTrialUntil"), Workspace:GetServerTimeNow())
end

-- V9-0f: the SHOP card's TRY 60 s. (V9-0l: in the beta the SHOP's FREE · BETA card claims it instead.)
function GodMode.tryIt()
	Net.event(Net.Names.Spawn):FireServer(if Config.GOD_FREE_BETA then "Claim" else "Try")
	Controller.open("God")
end

local function creating(): boolean
	if not GodMode.gated() or hasGod() then
		return true
	end
	local untilAt = player:GetAttribute("GodTrialUntil")
	return type(untilAt) == "number" and Workspace:GetServerTimeNow() < untilAt
end

-- The most of your own at once (DummySpawn.capFor: what the device's ragdoll budget leaves beside the
-- row with GOD MODE, else the plain cap).
function GodMode.cap(): number
	local FeelTuning = require(Shared:WaitForChild("FeelTuning")) :: any
	local DeviceTier = require(Shared:WaitForChild("DeviceTier")) :: any
	local camera = Workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
	local plat = FeelTuning.platOf(UserInputService.TouchEnabled, UserInputService.KeyboardEnabled, UserInputService.GamepadEnabled, math.min(view.X, view.Y))
	local base = ({ phone = 3, tablet = 5, pc = 6, console = 6 } :: any)[plat] or 6
	if not hasGod() then
		return base
	end
	local fx = (Config.FX_CAPS :: any)[DeviceTier.of(plat)]
	return math.max(base * 2, (if fx then fx.ragdolls else 22) - 6)
end

------------------------------------------------------------------------------------------------
-- Aim and the ghost

local function yaw(): number
	local camera = Workspace.CurrentCamera
	local look = if camera then camera.CFrame.LookVector else Vector3.new(0, 0, -1)
	return math.atan2(-look.X, -look.Z) + turn
end

-- Where the pointer (or the screen's middle on a pad) meets the floor.
local function aimPoint(screen: Vector2?): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local at = screen
	if not at then
		local last = UserInputService:GetLastInputType()
		if last.Name:sub(1, 7) == "Gamepad" then
			at = camera.ViewportSize / 2
		else
			at = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		end
	end
	local ray = camera:ViewportPointToRay((at :: Vector2).X, (at :: Vector2).Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	if player.Character then
		table.insert(skip, player.Character)
	end
	if ghosts then
		table.insert(skip, ghosts :: Folder)
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if hit and hit.Normal.Y > 0.6 then
		return hit.Position
	end
	return nil
end

-- Whether a spot may take a body: your own lab, within reach.
local function allowed(spot: Vector3): boolean
	local plot = player:GetAttribute("LabPlot")
	if type(plot) ~= "number" or Zones.plotAt(spot) ~= plot then
		return false
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and (root.Position - spot).Magnitude <= GodMode.REACH
end

local function clearGhosts()
	if ghosts then
		ghosts:Destroy()
	end
	ghosts = nil
	ghostParts = {}
end

-- Each body to come: a glowing ring on the floor where it lands and a faint post (a tower's rings
-- stack up), green where it may go, red where not.
local function ghostPart(folder: Folder, shape: Enum.PartType, size: Vector3, transparency: number): BasePart
	local p = Instance.new("Part")
	p.Name = "Ghost"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Shape = shape
	p.Size = size
	p.Transparency = transparency
	p:SetAttribute("Shown", transparency)
	p.Parent = folder
	return p
end

local function drawGhosts()
	local folder = ghosts
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GodGhosts"
		folder.Parent = Workspace
		ghosts = folder
	end
	local n = math.min(amount, GodMode.cap())
	local offsets = GodPattern.offsets(pattern, n, spacing, yaw())
	local at = aimAt
	for i = 1, math.max(#offsets, #ghostParts // 2) do
		local ring, post = ghostParts[i * 2 - 1], ghostParts[i * 2]
		if not ring then
			ring = ghostPart(folder :: Folder, Enum.PartType.Cylinder, Vector3.new(0.12, 2.8, 2.8), 0.3)
			post = ghostPart(folder :: Folder, Enum.PartType.Block, Vector3.new(0.35, 4.5, 0.35), 0.7)
			ghostParts[i * 2 - 1] = ring
			ghostParts[i * 2] = post
		end
		local shown = at ~= nil and i <= #offsets
		for _, part in { ring, post } do
			part.Transparency = if shown then part:GetAttribute("Shown") :: number else 1
		end
		if not shown then
			continue
		end
		local off = offsets[i]
		local spot = (at :: Vector3) + Vector3.new(off.X, 0, off.Z)
		local lift = if pattern == "Tower" then off.Y else 0
		local colour = if allowed(spot) then Color3.fromRGB(90, 230, 120) else Color3.fromRGB(255, 80, 80)
		ring.CFrame = CFrame.new(spot + Vector3.new(0, 0.08 + lift, 0)) * CFrame.Angles(0, 0, math.rad(90))
		post.CFrame = CFrame.new(spot + Vector3.new(0, 2.3 + lift, 0))
		ring.Color = colour
		post.Color = colour
	end
end

local function create(at: Vector3, count: number, pat: string)
	lastSpot = at
	Net.event(Net.Names.Spawn):FireServer("SpawnMany", kind, at, pat, count, spacing, yaw())
end

-- Kept for the old path (a phone's single tap from the window before V9-0l): one where you look.
function GodMode.create(k: string)
	kind = k
	local at = aimPoint(Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize / 2)
	if at then
		create(at, 1, "Point")
	end
end

------------------------------------------------------------------------------------------------
-- Placing mode

local painting = false
local lastPaint = 0
local lastPaintAt: Vector3? = nil

local function stopPlacing()
	if not placing then
		return
	end
	placing = false
	painting = false
	clearGhosts()
	for _, name in { "GodPlaceClick", "GodPlaceBack", "GodPlaceTurn", "GodPlaceSpace", "GodPlaceWheel", "GodPlacePad" } do
		ContextActionService:UnbindAction(name)
	end
	RunService:UnbindFromRenderStep("GodPlace")
	if placeBar then
		placeBar.Enabled = false
	end
end

local function refreshBar()
	if barPattern then
		barPattern.setText(string.upper(pattern))
	end
	if barAmount then
		barAmount.setText("x" .. math.min(amount, GodMode.cap()))
	end
end

local refresh: () -> () = function() end

local function setAmount(n: number)
	amount = n
	refresh()
	refreshBar()
end

local function setPattern(p: string)
	pattern = p
	refresh()
	refreshBar()
end

local function startPlacing()
	if not creating() and not Config.GOD_FREE_BETA then
		Controller.open("God")
		return
	end
	Controller.closeAll()
	placing = true
	local touch = isTouch()
	tapped = false
	if placeBar then
		placeBar.Enabled = true
		refreshBar()
	end
	if barHint then
		local pad = UserInputService:GetLastInputType().Name:sub(1, 7) == "Gamepad"
		barHint.Text = if touch then "Tap the floor to place them"
			elseif pad then "RT place  \u{00B7}  D-pad amount / pattern  \u{00B7}  B done"
			else "Click: place  \u{00B7}  Drag: paint  \u{00B7}  Q/E: turn  \u{00B7}  Wheel: amount  \u{00B7}  R/F: spacing  \u{00B7}  I: done"
		-- (As wide as its words, never wider than the screen less the gutters; the words shrink to fit.)
		local view = if Workspace.CurrentCamera then Workspace.CurrentCamera.ViewportSize.X else 800
		barHint.Size = UDim2.fromOffset(math.min(if touch then 300 else 560, view - 32), 26)
		-- (A phone shows no line: the rings at the screen's middle and the bar say it, and an upright
		-- phone's launchers sit right under the bar.)
		barHint.Visible = not touch
	end
	RunService:BindToRenderStep("GodPlace", Enum.RenderPriority.Camera.Value + 2, function()
		if not touch then
			aimAt = aimPoint()
		elseif not tapped then
			-- (A phone: the rings follow the screen's middle until the first tap puts them down.)
			local camera = Workspace.CurrentCamera
			aimAt = if camera then aimPoint(camera.ViewportSize / 2) else nil
		end
		drawGhosts()
		-- (Held and dragged: paint single ones along the way.)
		local here = aimAt
		if painting and here and os.clock() - lastPaint >= GodMode.PAINT_EVERY and (not lastPaintAt or ((here :: Vector3) - (lastPaintAt :: Vector3)).Magnitude >= GodMode.PAINT_STEP) then
			lastPaint = os.clock()
			lastPaintAt = here
			if allowed(here :: Vector3) then
				create(here :: Vector3, 1, "Point")
			end
		end
	end)
	local priority = Enum.ContextActionPriority.High.Value + 40
	ContextActionService:BindActionAtPriority("GodPlaceClick", function(_, state: Enum.UserInputState, input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			-- (A phone: the tap is the spot.)
			if state == Enum.UserInputState.Begin then
				local at = aimPoint(Vector2.new(input.Position.X, input.Position.Y))
				if at then
					tapped = true
					aimAt = at
					if allowed(at) then
						create(at, math.min(amount, GodMode.cap()), pattern)
					end
				end
			end
			return Enum.ContextActionResult.Sink
		end
		if state == Enum.UserInputState.Begin then
			local at = aimAt
			if at and allowed(at) then
				create(at, math.min(amount, GodMode.cap()), pattern)
			end
			painting = true
			lastPaint = os.clock() + 0.25 -- (a click is a click: painting starts once held and moved)
			lastPaintAt = at
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			painting = false
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonR2)
	ContextActionService:BindActionAtPriority("GodPlaceBack", function(_, state)
		if state == Enum.UserInputState.Begin then
			stopPlacing()
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB, Enum.KeyCode.I)
	ContextActionService:BindActionAtPriority("GodPlaceTurn", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			turn += if input.KeyCode == Enum.KeyCode.Q then -GodMode.TURN_STEP else GodMode.TURN_STEP
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.Q, Enum.KeyCode.E)
	ContextActionService:BindActionAtPriority("GodPlaceSpace", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			spacing = math.clamp(spacing + (if input.KeyCode == Enum.KeyCode.R then 0.5 else -0.5), GodPattern.SPACING_MIN, GodPattern.SPACING_MAX)
			refresh()
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.R, Enum.KeyCode.F)
	ContextActionService:BindActionAtPriority("GodPlaceWheel", function(_, state, input)
		if state == Enum.UserInputState.Change then
			setAmount(GodPattern.step(GodPattern.AMOUNTS, amount, if input.Position.Z > 0 then 1 else -1))
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.UserInputType.MouseWheel)
	-- (A pad: the D-pad changes the amount and the pattern.)
	ContextActionService:BindActionAtPriority("GodPlacePad", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			if input.KeyCode == Enum.KeyCode.DPadUp or input.KeyCode == Enum.KeyCode.DPadDown then
				setAmount(GodPattern.step(GodPattern.AMOUNTS, amount, if input.KeyCode == Enum.KeyCode.DPadUp then 1 else -1))
			else
				setPattern(GodPattern.step(GodPattern.PATTERNS, pattern, if input.KeyCode == Enum.KeyCode.DPadRight then 1 else -1))
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight)
end
GodMode.startPlacing = startPlacing
GodMode.stopPlacing = stopPlacing
function GodMode.placing(): boolean
	return placing
end

------------------------------------------------------------------------------------------------
-- The window

refresh = function()
	local can = creating()
	if offer then
		offer.Visible = not can
	end
	if controls then
		controls.Visible = true
	end
	local cap = GodMode.cap()
	for id, card in kindCards do
		card.stroke.Color = if id == kind then Color3.fromRGB(255, 205, 64) else Theme.Palette.ink
		card.stroke.Thickness = if id == kind then 4 else 2
	end
	for n, b in amountButtons do
		b.setRole(if n == amount then "premium" else "neutral")
		b.setEnabled(n <= math.max(cap, 1) or n == 1)
	end
	if amount > cap then
		amount = GodPattern.AMOUNTS[1]
		for _, n in GodPattern.AMOUNTS do
			if n <= cap then
				amount = n
			end
		end
	end
	for p, b in patternButtons do
		b.setRole(if p == pattern then "premium" else "neutral")
	end
	if spacingLabel then
		spacingLabel.Text = string.format("%.1f studs", spacing)
	end
	local line = statusLine
	if line then
		local untilAt = player:GetAttribute("GodTrialUntil")
		local left = if type(untilAt) == "number" then math.ceil(untilAt - Workspace:GetServerTimeNow()) else 0
		line.Text = if player:GetAttribute("Founder") == true then "Yours for good, with the gold beam"
			elseif player:GetAttribute("GodBeta") == true then "Create life anywhere in your lab"
			elseif hasGod() then string.format("Up to %d of yours at once", cap)
			elseif Config.GOD_FREE_BETA then "Free during beta: it unlocks in a moment"
			elseif left > 0 then string.format("FREE TRY: %d s", left)
			elseif type(untilAt) == "number" then "Your free try is over"
			else "Tap a kind to try it FREE for 60 s"
	end
	if headerPill then
		local text = headerPill:FindFirstChildWhichIsA("TextLabel", true)
		headerPill.Visible = Config.GOD_FREE_BETA == true or player:GetAttribute("Founder") == true
		if text then
			text.Text = if player:GetAttribute("Founder") == true then "\u{2728} FOUNDER" else "FREE \u{00B7} BETA"
		end
	end
end

-- A row of controls with a caption in front.
local function row(parent: Instance, order: number): Frame
	local r = Instance.new("Frame")
	r.Name = "Row" .. order
	r.BackgroundTransparency = 1
	r.Size = UDim2.new(1, 0, 0, 52)
	r.AutomaticSize = Enum.AutomaticSize.Y -- (a narrow window, an upright phone: the row wraps onto a second line)
	r.LayoutOrder = order
	r.Parent = parent
	local l = C.list(r, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	l.Wraps = true
	return r
end

local function caption(parent: Instance, text: string, order: number)
	local c = C.Text("small", text, { size = UDim2.fromOffset(86, 50), layoutOrder = order, parent = parent })
	c.TextXAlignment = Enum.TextXAlignment.Right
end

local function build()
	window = C.Window({ name = "God", title = "GOD MODE", theme = "shop", icon = "god", size = Vector2.new(780, 500) })
	local body = window.body
	-- The gold header line: FREE · BETA (or FOUNDER) and what you can do now.
	local head = Instance.new("Frame")
	head.Name = "GodHeader"
	head.BackgroundColor3 = Color3.fromRGB(255, 186, 60)
	head.Size = UDim2.new(1, 0, 0, 54)
	head.LayoutOrder = 1
	C.corner(head, UDim.new(0, 14))
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 214, 90), Color3.fromRGB(240, 140, 40))
	g.Parent = head
	head.Parent = body
	local godIcon = Icons.make("god", UDim2.fromOffset(42, 42))
	godIcon.AnchorPoint = Vector2.new(0, 0.5)
	godIcon.Position = UDim2.new(0, 8, 0.5, 0)
	godIcon.Parent = head
	statusLine = C.Text("body", "", { wrap = true, size = UDim2.new(1, -200, 1, 0), position = UDim2.fromOffset(58, 0), color = Color3.fromRGB(40, 22, 0), parent = head })
	local pill = C.Pill("FREE \u{00B7} BETA", { role = "go", anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -10, 0.5, 0), parent = head })
	headerPill = pill
	-- The controls.
	local box = Instance.new("Frame")
	box.Name = "Controls"
	box.BackgroundTransparency = 1
	box.Size = UDim2.fromScale(1, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.LayoutOrder = 2
	C.list(box, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center)
	box.Parent = body
	controls = box
	-- Kinds: a live turning 3D dummy each (pick one).
	local kinds = Instance.new("Frame")
	kinds.Name = "Kinds"
	kinds.BackgroundTransparency = 1
	kinds.Size = UDim2.new(1, 0, 0, 132)
	kinds.LayoutOrder = 2
	kinds.Parent = box
	C.list(kinds, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center)
	local ShopShowcase = require(script.Parent:WaitForChild("ShopShowcase")) :: any
	for i, t in GodMode.TYPES do
		local card = Instance.new("TextButton")
		card.Name = t.id
		card.Text = ""
		card.AutoButtonColor = false
		card.BackgroundColor3 = t.color:Lerp(Color3.new(0, 0, 0), 0.55)
		card.Size = UDim2.new(0.24, -8, 1, 0)
		card.LayoutOrder = i
		card.Selectable = true
		card.SelectionImageObject = C.selectionRing(UDim.new(0, 14))
		C.corner(card, UDim.new(0, 14))
		local stroke = C.outline(card, 2, Theme.Palette.ink)
		local glow = Instance.new("UIGradient")
		glow.Rotation = 90
		glow.Color = ColorSequence.new(t.color:Lerp(Color3.new(1, 1, 1), 0.2), t.color:Lerp(Color3.new(0, 0, 0), 0.6))
		glow.Parent = card
		card.Parent = kinds
		local vp = ShopShowcase.viewport({ dummy = t.hex, gold = false }, UDim2.new(1, 0, 1, -28))
		if vp then
			vp.Parent = card
		end
		local name = C.Text("title", t.word, { size = UDim2.new(1, 0, 0, 26), position = UDim2.new(0, 0, 1, -28), parent = card })
		name.TextColor3 = Color3.new(1, 1, 1)
		local scale = Instance.new("UIScale")
		scale.Parent = card
		card.MouseEnter:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.05 }):Play()
			card.Rotation = 1.5
		end)
		card.MouseLeave:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
			card.Rotation = 0
		end)
		card.Activated:Connect(function()
			kind = t.id
			C.playSound("click")
			refresh()
		end)
		kindCards[t.id] = { root = card, stroke = stroke }
	end
	-- Amount and spacing on one row, the pattern on the next: everything and PLACE in view at once.
	local tune = row(box, 4)
	caption(tune, "AMOUNT", 0)
	for i, n in GodPattern.AMOUNTS do
		amountButtons[n] = C.Button({ text = tostring(n), role = "neutral", size = UDim2.fromOffset(62, 50), layoutOrder = i, parent = tune, onActivated = function()
			setAmount(n)
		end })
	end
	local gap = Instance.new("Frame")
	gap.BackgroundTransparency = 1
	gap.Size = UDim2.fromOffset(14, 50)
	gap.LayoutOrder = 10
	gap.Parent = tune
	caption(tune, "SPACING", 11)
	C.Button({ text = "-", role = "neutral", size = UDim2.fromOffset(50, 50), layoutOrder = 12, parent = tune, onActivated = function()
		spacing = math.clamp(spacing - 0.5, GodPattern.SPACING_MIN, GodPattern.SPACING_MAX)
		refresh()
	end })
	spacingLabel = C.Text("body", "", { size = UDim2.fromOffset(92, 50), layoutOrder = 13, parent = tune })
	C.Button({ text = "+", role = "neutral", size = UDim2.fromOffset(50, 50), layoutOrder = 14, parent = tune, onActivated = function()
		spacing = math.clamp(spacing + 0.5, GodPattern.SPACING_MIN, GodPattern.SPACING_MAX)
		refresh()
	end })
	local patternRow = row(box, 5)
	caption(patternRow, "PATTERN", 0)
	for i, p in GodPattern.PATTERNS do
		patternButtons[p] = C.Button({ text = string.upper(p), role = "neutral", size = UDim2.fromOffset(98, 50), layoutOrder = i, parent = patternRow, onActivated = function()
			setPattern(p)
		end })
	end
	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.BackgroundTransparency = 1
	actions.Size = UDim2.new(1, 0, 0, 60)
	actions.LayoutOrder = 9
	actions.Parent = box
	C.list(actions, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center)
	local place = C.Button({ name = "Place", text = if UserInputService.KeyboardEnabled and not isTouch() then "PLACE (I)" else "PLACE", icon = "god", role = "go", size = UDim2.new(0.58, 0, 1, 0), layoutOrder = 1, parent = actions, onActivated = startPlacing })
	C.Button({ name = "ClearMine", text = "CLEAR MINE", role = "danger", size = UDim2.new(0.36, 0, 1, 0), layoutOrder = 2, parent = actions, onActivated = function()
		Net.event(Net.Names.Spawn):FireServer("Clear")
	end })
	window.defaultSelection = place.hit
	-- (An upright screen: PLACE right under the kinds, in view without scrolling; the amount and the
	-- pattern under it.)
	local function order()
		local camera = Workspace.CurrentCamera
		local upright = camera ~= nil and camera.ViewportSize.Y > camera.ViewportSize.X
		actions.LayoutOrder = if upright then 3 else 9
	end
	order()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(order)
	end
	-- The offer (only once the beta ends, for who has no GOD MODE).
	local o = Instance.new("Frame")
	o.Name = "Offer"
	o.BackgroundTransparency = 1
	o.Size = UDim2.fromScale(1, 0)
	o.AutomaticSize = Enum.AutomaticSize.Y
	o.LayoutOrder = 3
	C.list(o, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center)
	C.Text("body", "\u{2728} Always on   \u{2728} Up to 16 at once   \u{2728} Beam of light", { wrap = true, size = UDim2.new(1, 0, 0, 26), layoutOrder = 1, parent = o })
	local get = C.Button({ text = "GET GOD MODE", icon = "god", role = "premium", size = UDim2.fromOffset(300, 60), layoutOrder = 10, parent = o, onActivated = function()
		Net.event(Net.Names.Money):FireServer("Buy", "God")
	end })
	get.root.Name = "Get"
	o.Parent = body
	offer = o
	Controller.register(window)
	Controller.addHudButton({ window = "God", label = "God", icon = "god", theme = "shop", layoutOrder = 2 })
end

-- A phone's bar while placing: the pattern, the amount, SPAWN again at the last spot, DONE. At the
-- top middle, under the notices, out of the thumbs' way; every target 48 px.
local function buildBar()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GodPlaceBar"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- (the kit's buttons layer by siblings)
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.DisplayOrder = 20
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, 46)
	row.Size = UDim2.fromOffset(420, 52)
	row.Parent = gui
	C.list(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center)
	barPattern = C.Button({ text = "LINE", role = "info", size = UDim2.fromOffset(100, 50), layoutOrder = 1, parent = row, onActivated = function()
		setPattern(GodPattern.step(GodPattern.PATTERNS, pattern, 1))
	end })
	barAmount = C.Button({ text = "x5", role = "info", size = UDim2.fromOffset(70, 50), layoutOrder = 2, parent = row, onActivated = function()
		setAmount(GodPattern.step(GodPattern.AMOUNTS, amount, 1))
	end })
	local spawnButton = C.Button({ text = "SPAWN", icon = "god", role = "go", size = UDim2.fromOffset(130, 50), layoutOrder = 3, parent = row, onActivated = function()
		local at = lastSpot or aimAt
		if at and allowed(at) then
			create(at, math.min(amount, GodMode.cap()), pattern)
		end
	end })
	local done = C.Button({ text = "DONE", role = "neutral", size = UDim2.fromOffset(90, 50), layoutOrder = 4, parent = row, onActivated = stopPlacing })
	-- (Never wider than the screen less 16 px gutters (an upright phone is 360-393 wide): the buttons
	-- narrow, their height stays 50 so a thumb always has 44 px or more.)
	local widths = { { barPattern.root, 100 }, { barAmount.root, 70 }, { spawnButton.root, 130 }, { done.root, 90 } }
	local function refit()
		local camera = Workspace.CurrentCamera
		local room = if camera then camera.ViewportSize.X - 32 - 18 else 402
		local k = math.min(1, room / 390)
		for _, w in widths do
			w[1].Size = UDim2.fromOffset(math.floor(w[2] * k), 50)
		end
		row.Size = UDim2.fromOffset(math.floor(390 * k) + 18, 52)
	end
	refit()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	-- (What the keys do, in one quiet line under it.)
	local hint = C.Text("small", "", { size = UDim2.fromOffset(600, 26), position = UDim2.new(0.5, 0, 0, 102), anchor = Vector2.new(0.5, 0), scaled = true, parent = gui })
	hint.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	hint.BackgroundTransparency = 0.3
	hint.TextColor3 = Color3.new(1, 1, 1)
	C.corner(hint, UDim.new(0.5, 0))
	barHint = hint
	gui.Parent = player:WaitForChild("PlayerGui")
	placeBar = gui
end

-- The GOD launcher on screen now (the HUD square off phones, else the MENU button), or nil.
local function launcherOnScreen(gui: Instance): GuiObject?
	local best: GuiObject? = nil
	for _, name in { "God", "Menu" } do
		for _, d in gui:GetDescendants() do
			if d.Name ~= name or not d:IsA("GuiObject") or d.AbsoluteSize.X < 20 or d.AbsoluteSize.X > 220 then
				continue
			end
			local shown = true
			local a: Instance? = d
			while a and a ~= gui do
				if (a:IsA("GuiObject") and not a.Visible) or (a:IsA("ScreenGui") and not a.Enabled) then
					shown = false
					break
				end
				a = a.Parent
			end
			if shown then
				best = d
				break
			end
		end
		if best then
			return best
		end
	end
	return nil
end

-- The beta gift on this screen: the first time a golden reveal, the picture popping in under it and
-- flying to the GOD button; later days a small chip.
local function reveal(first: boolean)
	local compact = false
	pcall(function()
		compact = (require(script.Parent:WaitForChild("NoticeState")) :: any).compact()
	end)
	local keys = UserInputService.KeyboardEnabled and not isTouch()
	local Toast = require(script.Parent:WaitForChild("Toast")) :: any
	if not first then
		Toast.show(if keys then "God Mode is still free in beta: press I" else "God Mode is still free in beta", Color3.fromRGB(255, 205, 64))
		return
	end
	C.playSound("purchase")
	if compact then
		Toast.show("GOD MODE unlocked: FREE during beta!", Color3.fromRGB(255, 205, 64))
	else
		pcall(function()
			(require(script.Parent:WaitForChild("Banner")) :: any).show({ title = "GOD MODE UNLOCKED", sub = if keys then "FREE during beta! Press I" else "FREE during beta!", color = Color3.fromRGB(255, 196, 46), icon = "god", emoji = "\u{2728}", priority = 4 })
		end)
	end
	-- The picture pops in under the banner, then flies to its button.
	local gui = player:WaitForChild("PlayerGui")
	local layer = Instance.new("ScreenGui")
	layer.Name = "GodFly"
	layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	layer.IgnoreGuiInset = true
	layer.DisplayOrder = 60
	layer.Parent = gui
	local view = Workspace.CurrentCamera.ViewportSize
	local big = math.clamp(view.Y * 0.16, 64, 120)
	local pic = Icons.make("god", UDim2.fromOffset(0, 0))
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	pic.Position = UDim2.fromOffset(view.X / 2, view.Y * 0.62)
	pic.Parent = layer
	TweenService:Create(pic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(big, big) }):Play()
	task.wait(1.3)
	local target = Vector2.new(60, view.Y * 0.5)
	local button = launcherOnScreen(gui)
	if button then
		target = button.AbsolutePosition + button.AbsoluteSize / 2 + Vector2.new(0, GuiService:GetGuiInset().Y)
	end
	local t = TweenService:Create(pic, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(28, 28) })
	t:Play()
	t.Completed:Connect(function()
		layer:Destroy()
		if button then
			pcall(function()
				(require(script.Parent:WaitForChild("KitStyle")) :: any).pop(button)
			end)
		end
	end)
end
GodMode.revealForTest = reveal

function GodMode.start()
	if not (Config.GOD_PASS and Config.DUMMY_TYPES) then
		return
	end
	build()
	buildBar()
	refresh()
	for _, name in { "God", "GodBeta", "Founder", "GodTrialUntil" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	-- (The trial's clock, while the window is open.)
	task.spawn(function()
		while true do
			task.wait(1)
			if Controller.isOpen("God") then
				refresh()
			end
		end
	end)
	-- I opens the window (or leaves placing: bound while placing). (G is Grab.)
	ContextActionService:BindAction("GodOpen", function(_, state)
		if state == Enum.UserInputState.Begin and not placing and GodMode.launcherShown() then
			Controller.toggle("God")
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.I) -- (G is Grab: I opens GOD MODE)
	-- (Studio: the player attribute DevGodPlace starts and stops placing, for checks and captures.)
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevGodPlace"):Connect(function()
			if player:GetAttribute("DevGodPlace") then
				startPlacing()
			else
				stopPlacing()
			end
		end)
	end
	-- Opening any window leaves placing.
	Controller.onChanged(function(_, open: boolean)
		if open and placing then
			stopPlacing()
		end
	end)
	Net.event(Net.Names.Spawn).OnClientEvent:Connect(function(what: unknown, why: unknown)
		if what == "Refused" and why == "god" then
			stopPlacing()
			Controller.open("God")
		elseif what == "Refused" and type(why) == "string" and placing then
			(require(script.Parent:WaitForChild("Toast")) :: any).show(if why == "only in your own lab" then "Only in your own lab" elseif why == "too far" then "Too far away" else tostring(why))
		elseif what == "Granted" then
			task.spawn(reveal, why == "first")
		end
	end)
end

return GodMode
