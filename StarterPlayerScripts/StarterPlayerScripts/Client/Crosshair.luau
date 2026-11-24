--!strict
-- The crosshair (round 3, M2). With a gun picked, the mouse pointer becomes a thin crosshair: four
-- short white lines with a dark edge and a dot in the middle, the lines opening up a little with
-- every shot (the gun kicks) and closing again. A shot that hits a body shows a hit mark over it
-- (an X): white, red for the head, and for the round that killed a bigger, bolder red X held longer. On a touch screen there is no pointer: the crosshair
-- shows for a moment where the finger tapped, with the same marks.
--
-- Client only, purely visual: the shot itself is PokeController's (it fires where you tap or
-- click, a body or not). Drawn every frame only while a gun is picked.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local Config = require(Shared:WaitForChild("Config"))
local V2 = Config.UI_V2 == true
local PREMIUM = (Config :: any).UI_PREMIUM == true -- (24 Nov 2026: rounded lines, a softer edge, a fuller dot)

local Crosshair = {}

Crosshair.LINE = 8 -- px: each line's length
Crosshair.THICK = 2
Crosshair.GAP = 5 -- px from the middle to a line, at rest
Crosshair.KICK = 5 -- px a shot opens it
Crosshair.MAX_GAP = 18
Crosshair.CLOSE = 40 -- px a second it closes again
Crosshair.TOUCH_HOLD = 0.45 -- s it shows where a finger tapped
Crosshair.MARK_HOLD = 0.28 -- s a hit mark shows
-- Round 4, M10: the round that killed gets its own mark, bigger, bolder and held longer.
Crosshair.KILL_HOLD = 0.7
local MARK = { length = 7, out = 9, thick = Crosshair.THICK }
local KILL_MARK = { length = 13, out = 13, thick = Crosshair.THICK + 2 }
-- UI v2: marks you cannot miss on a phone: thicker, a punch of the whole crosshair on every hit
-- (bigger for a kill), and a "KO!" stamp beside it for the round that killed.
if V2 then
	MARK = { length = 9, out = 10, thick = 3 }
	KILL_MARK = { length = 16, out = 15, thick = 5 }
end
Crosshair.PUNCH = 1.3 -- UI v2: scale the crosshair jumps to on a hit (KILL_PUNCH on a kill)
Crosshair.KILL_PUNCH = 1.6

local HEAD = require(Shared:WaitForChild("Anatomy")).HEAD_ZONES
local MARK_RED = Color3.fromRGB(255, 70, 70)
local MARK_ANGLES = { 45, 135, 225, 315 }

local player = Players.LocalPlayer
local root: Frame? = nil
local lines: { Frame } = {}
local marks: { Frame } = {}
local gap = Crosshair.GAP
local touchUntil = 0
local touchAt = Vector2.zero
local hidingPointer = false
local markTweens: { Tween } = {}

local function bar(parent: Instance, name: string, size: Vector2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Size = UDim2.fromOffset(size.X, size.Y)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(10, 10, 14)
	stroke.Thickness = 1
	stroke.Transparency = if PREMIUM then 0.45 else 0.2
	stroke.Parent = f
	if PREMIUM then
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(1, 0)
		round.Parent = f
	end
	f.Parent = parent
	return f
end

-- The hit mark's four lines at one size (MARK or KILL_MARK).
local function shapeMarks(shape: { length: number, out: number, thick: number })
	for i, m in marks do
		local a = math.rad(MARK_ANGLES[i])
		m.Size = UDim2.fromOffset(shape.thick, shape.length)
		m.Position = UDim2.new(0.5, math.sin(a) * shape.out, 0.5, -math.cos(a) * shape.out)
	end
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Crosshair"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- (the mouse's own coordinates)
	gui.DisplayOrder = 7
	local f = Instance.new("Frame")
	f.Name = "Cross"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Size = UDim2.fromOffset(64, 64)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.Active = false
	local t = Crosshair.THICK
	local l = Crosshair.LINE
	lines = {
		bar(f, "Up", Vector2.new(t, l)),
		bar(f, "Down", Vector2.new(t, l)),
		bar(f, "Left", Vector2.new(l, t)),
		bar(f, "Right", Vector2.new(l, t)),
	}
	local dot = bar(f, "Dot", if PREMIUM then Vector2.new(3, 3) else Vector2.new(t, t))
	dot.Position = UDim2.fromScale(0.5, 0.5)
	-- The hit mark: four short diagonal lines round the middle.
	marks = {}
	for i, angle in MARK_ANGLES do
		local m = bar(f, "Mark" .. i, Vector2.new(t, MARK.length))
		m.Rotation = angle
		m.BackgroundTransparency = 1
		local stroke = m:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 1
		end
		table.insert(marks, m)
	end
	shapeMarks(MARK)
	if V2 then
		local punch = Instance.new("UIScale")
		punch.Name = "Punch"
		punch.Parent = f
		local ko = Instance.new("TextLabel")
		ko.Name = "KO"
		ko.AnchorPoint = Vector2.new(0, 1)
		ko.Position = UDim2.new(0.5, 14, 0.5, -10)
		ko.Size = UDim2.fromOffset(44, 24)
		ko.BackgroundTransparency = 1
		ko.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
		ko.TextSize = 22
		ko.Text = "KO!"
		ko.TextColor3 = MARK_RED
		ko.TextTransparency = 1
		ko.Rotation = -8
		local koStroke = Instance.new("UIStroke")
		koStroke.Color = Color3.fromRGB(10, 10, 14)
		koStroke.Thickness = 2
		koStroke.Transparency = 1
		koStroke.Parent = ko
		ko.Parent = f
	end
	f.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	root = f
end

local function placeLines()
	local half = Crosshair.LINE / 2
	lines[1].Position = UDim2.new(0.5, 0, 0.5, -(gap + half))
	lines[2].Position = UDim2.new(0.5, 0, 0.5, gap + half)
	lines[3].Position = UDim2.new(0.5, -(gap + half), 0.5, 0)
	lines[4].Position = UDim2.new(0.5, gap + half, 0.5, 0)
end

-- Whether a gun is picked right now (and tools are in use: not doctor mode, not building).
local PokeController: any = nil
local function gunPicked(): boolean
	if not PokeController or not PokeController.isEnabled() or PokeController.isDoctor() or PokeController.isPicking() then
		return false
	end
	local toy = Toys.byId[PokeController.getSelected()]
	return toy ~= nil and toy.gun == true
end

local function setPointerHidden(on: boolean)
	if hidingPointer ~= on then
		hidingPointer = on
		UserInputService.MouseIconEnabled = not on
	end
end

-- A shot was fired (a click or a tap with a gun picked): the lines open up; on a touch screen it
-- shows where the finger was.
function Crosshair.fired(screenAt: Vector2?, touch: boolean?)
	gap = math.min(gap + Crosshair.KICK, Crosshair.MAX_GAP)
	if touch and screenAt then
		touchAt = screenAt
		touchUntil = os.clock() + Crosshair.TOUCH_HOLD
	end
end

-- A shot landed on a body: the hit mark, red for the head; the round that killed gets the kill
-- mark instead (round 4, M10: a head hit that did not kill is only red).
-- V8-0.2: our own hit on a body this screen simulates, marked now (the server's mark for it follows
-- ~100 ms later and is skipped unless it says more: a head or a kill).
local localMarkAt = -math.huge
-- (V8-1.5: KOs close together are a combo: "KO! x2", "KO! x3"... and the chime climbs.)
Crosshair.COMBO_GAP = 4 -- s between two KOs that keeps a combo
local comboN, comboAt = 0, -math.huge
function Crosshair.combo(): number
	return comboN
end
function Crosshair.localHit(knocked: boolean)
	localMarkAt = os.clock()
	if knocked then
		comboN = if os.clock() - comboAt <= Crosshair.COMBO_GAP then comboN + 1 else 1
		comboAt = os.clock()
	end
	local f = root
	local ko = f and f:FindFirstChild("KO")
	if ko and ko:IsA("TextLabel") then
		ko.Text = if knocked and comboN > 1 then string.format("KO! x%d", comboN) else "KO!"
	end
	Crosshair.hit(false, knocked)
end
function Crosshair.recentLocal(): boolean
	return os.clock() - localMarkAt < 0.35
end

function Crosshair.hit(head: boolean, killed: boolean)
	for _, tw in markTweens do
		tw:Cancel()
	end
	table.clear(markTweens)
	shapeMarks(if killed then KILL_MARK else MARK)
	local hold = if killed then Crosshair.KILL_HOLD else Crosshair.MARK_HOLD
	for _, m in marks do
		m.BackgroundColor3 = if head or killed then MARK_RED else Color3.new(1, 1, 1)
		m.BackgroundTransparency = 0
		local stroke = m:FindFirstChildOfClass("UIStroke")
		local info = TweenInfo.new(hold, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		table.insert(markTweens, TweenService:Create(m, info, { BackgroundTransparency = 1 }))
		if stroke then
			stroke.Transparency = 0.2
			table.insert(markTweens, TweenService:Create(stroke, info, { Transparency = 1 }))
		end
	end
	local f = root
	if V2 and f then
		-- (UI v2: the punch, and "KO!" for the round that killed.)
		local punch = f:FindFirstChild("Punch")
		if punch and punch:IsA("UIScale") then
			punch.Scale = if killed then Crosshair.KILL_PUNCH else Crosshair.PUNCH
			table.insert(markTweens, TweenService:Create(punch, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }))
		end
		local ko = f:FindFirstChild("KO")
		if ko and ko:IsA("TextLabel") then
			local koStroke = ko:FindFirstChildOfClass("UIStroke")
			local show = if killed then 0 else 1
			ko.TextTransparency = show
			local fade = TweenInfo.new(Crosshair.KILL_HOLD, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			table.insert(markTweens, TweenService:Create(ko, fade, { TextTransparency = 1 }))
			if koStroke then
				koStroke.Transparency = show
				table.insert(markTweens, TweenService:Create(koStroke, fade, { Transparency = 1 }))
			end
		end
	end
	for _, tw in markTweens do
		tw:Play()
	end
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		touchUntil = math.max(touchUntil, os.clock() + hold)
	end
end

-- Tests: whether the crosshair shows now, and where.
function Crosshair.shown(): (boolean, Vector2)
	local f = root
	return f ~= nil and f.Visible, if f then f.AbsolutePosition + f.AbsoluteSize / 2 else Vector2.zero
end

-- Whether the mouse is over a button or a window right now (then the normal pointer shows: menus
-- are clicked with the pointer, not the crosshair). Looked at ten times a second, not every frame.
local overUi = false
local lookedAt = 0
local function pointerOverUi(at: Vector2): boolean
	local now = os.clock()
	if now - lookedAt < 0.1 then
		return overUi
	end
	lookedAt = now
	overUi = false
	local gui = player:FindFirstChild("PlayerGui")
	if gui then
		local inset = game:GetService("GuiService"):GetGuiInset()
		for _, g in (gui :: PlayerGui):GetGuiObjectsAtPosition(at.X - inset.X, at.Y - inset.Y) do
			if g.Active and g.Visible and g.BackgroundTransparency < 1 then
				overUi = true
				break
			end
		end
	end
	return overUi
end

local rebind: () -> ()
local unbind: () -> ()
local function step(dt: number)
	local f = root
	if not f then
		return
	end
	gap = math.max(Crosshair.GAP, gap - Crosshair.CLOSE * dt)
	local gun = gunPicked()
	local mouse = UserInputService.MouseEnabled and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch and UserInputService:GetLastInputType() ~= Enum.UserInputType.Gamepad1 -- (a pad aims at the middle: TouchShoot draws that one)
	local mouseFree = UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter
	local at = if mouseFree then UserInputService:GetMouseLocation() else workspace.CurrentCamera.ViewportSize / 2
	local Controller = require(game:GetService("ReplicatedStorage"):WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
	if Controller.getCurrent() ~= nil then
		-- (23 Nov 2026: a window is open: the pointer instead.)
		f.Visible = false
		setPointerHidden(false)
	elseif gun and mouse and mouseFree and pointerOverUi(at) then
		f.Visible = false
		setPointerHidden(false)
	elseif gun and mouse then
		-- (A locked mouse, as in shift lock, aims at the middle of the screen.)
		-- (22 Nov 2026, owner: the crosshair follows the recoil; the shot goes there too: PokeController.)
		local kicked = at + require(script.Parent:WaitForChild("FeelV2")).recoilPixelOffset(workspace.CurrentCamera)
		f.Position = UDim2.fromOffset(kicked.X, kicked.Y)
		f.Visible = true
		setPointerHidden(true)
	elseif gun and os.clock() < touchUntil and not (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
		-- (22 Nov 2026, owner: no extra crosshair in the middle on a phone; TouchShoot draws the one there.)
		local fp = (require(script.Parent:WaitForChild("FirstPerson")) :: any).isOn()
		f.Position = if fp then UDim2.fromScale(0.5, 0.5) else UDim2.fromOffset(touchAt.X, touchAt.Y)
		f.Visible = true
		setPointerHidden(false)
	elseif not gun then
		unbind() -- (nothing to draw until a gun is picked again)
		return
	else
		f.Visible = false
		setPointerHidden(false)
	end
	if f.Visible then
		placeLines()
	end
end

local bound = false
function unbind()
	if bound then
		bound = false
		RunService:UnbindFromRenderStep("Crosshair")
	end
	if root then
		root.Visible = false
	end
	setPointerHidden(false)
end

function rebind()
	if gunPicked() and not bound then
		bound = true
		RunService:BindToRenderStep("Crosshair", Enum.RenderPriority.Last.Value, step)
	end
end

function Crosshair.start()
	PokeController = require(script.Parent:WaitForChild("PokeController"))
	build()
	-- (Drawn every frame only while a gun is picked: bound when the hand changes to a gun, PokeController
	-- .changed, and unbound by the step itself once no gun is picked and nothing shows.)
	PokeController.changed:Connect(rebind)
	rebind()
	-- A click or a tap in the world with a gun picked (not on a button).
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not gunPicked() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Crosshair.fired(nil, false)
		elseif input.UserInputType == Enum.UserInputType.Touch and not require(script.Parent:WaitForChild("MoveStick")).has(input) then
			Crosshair.fired(Vector2.new(input.Position.X, input.Position.Y + game:GetService("GuiService"):GetGuiInset().Y), true)
		end
	end)
	-- The server's word that a shot landed (VitalsService's line to the shooter).
	Net.event(Net.Names.HitInfo).OnClientEvent:Connect(function(_line: unknown, _model: unknown, _before: unknown, zoneId: unknown, killed: unknown)
		if not gunPicked() then
			return
		end
		-- Red for the head; the kill mark for the round that killed (the server's word: never a
		-- round into a body already dead).
		local head = type(zoneId) == "string" and HEAD[zoneId] == true
		if Crosshair.recentLocal() and not head and killed ~= true then
			return -- (V8-0.2: already marked from this screen)
		end
		Crosshair.hit(head, killed == true)
	end)
end

return Crosshair
