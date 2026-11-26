--!strict
-- Pointer routing for both views, and the optional lab camera.
--
-- Player view (the default, like every big ragdoll game on Roblox): you walk your avatar with the
-- standard controls and Roblox's own third-person camera. Here this module only routes presses and
-- taps: a press on a dummy uses the selected toy at once, a short tap on a surface places a toy or
-- uses a build tool. Dragging is left to the standard camera.
--
-- Lab view (switched on with the VIEW button): an orbit camera over the lab. The avatar stands
-- still; phone first:
--   one finger on a dummy      -> the selected toy acts on it at once (or Grab picks it up)
--   one finger tap on a surface -> place toys (anvil, TNT, ...) land there
--   one finger drag elsewhere  -> orbit around the lab (with a little glide when you let go)
--   two fingers                -> pinch to zoom, move together to pan
-- Desktop: left click works like a finger, right drag orbits, wheel zooms, middle drag or
-- WASD pans, Q/E turn. While nobody touches it, it keeps fast-moving dummies in view and drifts
-- back to the lab once things calm down; a recenter button appears whenever the view is away.

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Toys = require(Shared:WaitForChild("Toys"))
local Assets = require(Shared:WaitForChild("Assets"))
local Config = require(Shared:WaitForChild("Config"))

local Client = script.Parent
local PokeController = require(Client:WaitForChild("PokeController"))
local GrabController = require(Client:WaitForChild("GrabController"))
local ReplayController = require(Client:WaitForChild("ReplayController"))
local Toast = require(Client:WaitForChild("Toast"))
local BuildController = require(Client:WaitForChild("BuildController"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local MoveStick = require(Client:WaitForChild("MoveStick"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local HudSlots = require(Client:WaitForChild("HudSlots"))
local HudGate = require(Client:WaitForChild("HudGate"))
local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))

local player = Players.LocalPlayer

-- View limits
local MIN_DISTANCE, MAX_DISTANCE = 10, 150 -- (0.37.0: the bigger lab: room to see all of it)
local MIN_PITCH, MAX_PITCH = -78, -6 -- degrees; never under the floor, never straight down
local HOME_YAW, HOME_PITCH, HOME_DISTANCE = 0, -24, 28
local BOUND_RADIUS = 260 -- (0.37.0: the bigger lab) how far the focus may wander from the lab

-- Feel
local TAP_SLOP = 12 -- px a finger may move and still count as a tap
local TAP_TIME = 0.45 -- s
local ORBIT_DEG_PER_PX = 0.32
local ORBIT_GLIDE_DECAY = 5 -- 1/s
local FOLLOW_RATE = 2.2 -- 1/s
local FOLLOW_SPEED = 28 -- studs/s a dummy must move to be worth following
local CALM_BEFORE_HOME = 3 -- s of no fast dummies before an automatic follow returns home
local KEY_PAN_SPEED = 1.1 -- times the view distance, per second
local KEY_TURN_SPEED = 110 -- deg/s

type Pointer = {
	input: InputObject?, -- the touch (nil = mouse)
	start: Vector2,
	position: Vector2,
	began: number,
	movedAt: number,
	role: "pending" | "orbit" | "claimed" | "multi",
}

local LabCamera = {}
-- Switches the player view and the lab view (set once the button is built: start).
LabCamera.toggleView = function() end

local home: Vector3 = Vector3.new(0, 3, -18)
local origin: Vector3 = Vector3.zero
-- Target view (what input asks for) and shown view (smoothed towards it).
local focus, yaw, pitch, distance = home, HOME_YAW, HOME_PITCH, HOME_DISTANCE
local shownFocus, shownYaw, shownPitch, shownDistance = focus, yaw, pitch, distance
local glideYaw, glidePitch = 0, 0

local pointers: { [any]: Pointer } = {}
local rightDrag: Vector2? = nil
local middleDrag: Vector2? = nil
local pinchSpan: number? = nil
local pinchDistance = distance
local pinchMid: Vector2? = nil

local lastUserInput = -math.huge
local autoAway = false
local lastFast = 0
local orbitedOnce = false
local startedAt = os.clock()
local hintShown = false
local recenterButton: GuiButton? = nil
local viewButton: TextButton? = nil

local function viewportOf(input: InputObject): Vector2
	-- Input positions are below the top bar inset; rays want viewport coordinates.
	return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
end

local function userTouched()
	lastUserInput = os.clock()
	autoAway = false
end

local function clampFocus(p: Vector3): Vector3
	local flat = Vector3.new(p.X - origin.X, 0, p.Z - origin.Z)
	if flat.Magnitude > BOUND_RADIUS then
		flat = flat.Unit * BOUND_RADIUS
	end
	return Vector3.new(origin.X + flat.X, math.clamp(p.Y, origin.Y + 1, origin.Y + 40), origin.Z + flat.Z)
end

local function orbitBy(dx: number, dy: number)
	yaw -= dx * ORBIT_DEG_PER_PX
	pitch = math.clamp(pitch - dy * ORBIT_DEG_PER_PX, MIN_PITCH, MAX_PITCH)
end

-- Moves the focus along the ground, in screen directions, by a screen delta in pixels.
local function panBy(dx: number, dy: number)
	local camera = Workspace.CurrentCamera
	local scale = distance * 2 * math.tan(math.rad(camera.FieldOfView / 2)) / math.max(camera.ViewportSize.Y, 1)
	local right = Vector3.new(math.cos(math.rad(yaw)), 0, -math.sin(math.rad(yaw)))
	local forward = Vector3.new(-math.sin(math.rad(yaw)), 0, -math.cos(math.rad(yaw)))
	focus = clampFocus(focus - right * dx * scale + forward * dy * scale * 1.4)
end

local function zoomTo(d: number)
	distance = math.clamp(d, MIN_DISTANCE, MAX_DISTANCE)
end

local function recenter()
	userTouched()
	focus = home
	yaw, pitch, distance = HOME_YAW, HOME_PITCH, HOME_DISTANCE
	glideYaw, glidePitch = 0, 0
end

local function activeFree(): { Pointer }
	local list = {}
	for _, p in pointers do
		if p.role ~= "claimed" then
			table.insert(list, p)
		end
	end
	return list
end

local function startPinch()
	local free = activeFree()
	if #free ~= 2 then
		pinchSpan = nil
		return
	end
	for _, p in free do
		p.role = "multi"
	end
	pinchSpan = (free[1].position - free[2].position).Magnitude
	pinchDistance = distance
	pinchMid = (free[1].position + free[2].position) / 2
end

-- (24 Nov 2026, owner: turning the view with a finger fired the weapon): a finger on the world never uses a tool that
-- has its own button (TouchShoot: SHOOT, HIT, PLACE ...). Grabbing, the wand and the lab view tap as before.
local function buttonOnly(input: InputObject?): boolean
	if not input then
		return false
	end
	local ok, on = pcall(function()
		return (require(script.Parent:WaitForChild("TouchShoot")) :: any).wanted()
	end)
	return ok and on == true
end

local function onPress(key: any, input: InputObject?, at: Vector2)
	if ReplayController.isPlaying() then
		return
	end
	-- (11 Nov 2026: the finger on the move stick only walks, never shoots: MoveStick.)
	if input and MoveStick.has(input, ViewMode.isLab()) then
		-- (Claimed: never a tap, an orbit or a pinch; it is the walking finger.)
		pointers[key] = { input = input, start = at, position = at, began = os.clock(), movedAt = os.clock(), role = "claimed" }
		return
	end
	local p: Pointer = { input = input, start = at, position = at, began = os.clock(), movedAt = os.clock(), role = "pending" }
	if not input and not BuildController.isActive() and PokeController.beginCharge() then
		(p :: any).charge = true
		p.role = "claimed"
		pointers[key] = p
		return
	end
	if BuildController.pressAt(at) or GrabController.tryBegin(at, input) or (not buttonOnly(input) and PokeController.pressAt(at)) then
		p.role = "claimed"
	end
	pointers[key] = p
	-- Hold to fire (10 Nov 2026 the audit: the minigun and the nail gun needed a tap a round; Dec
	-- 2026 the owner: pistols are one tap at a time, fully automatic rifles and SMGs keep firing):
	-- a gun with the auto flag held down keeps firing at its own pace wherever the pointer is, until
	-- it is let go. The G17, Deagle, Shotgun, Sniper, DMR, Revolver, Crossbow, Double Barrel, Flare
	-- Gun, Railgun, RPG, Golden Deagle and the dummy-tag specials (Sticky, Freeze, Zap, Heal, Rocket,
	-- Balloon, Shrink, Chicken, C4) all stay tap per round. Chainsaw is held by its own hand.
	local selectedToy = Toys.byId[PokeController.getSelected()]
	local holdToFire = selectedToy and not buttonOnly(input) and (selectedToy.auto == true or selectedToy.id == "Chainsaw")
	if holdToFire then
		-- First shot: if the press did not claim (no NPC under it), fire a miss-shot now so the air
		-- spam starts on the same press, not one cooldown later. A claimed press already fired its
		-- round through the normal hit path; do nothing extra for it here.
		if p.role ~= "claimed" then
			if PokeController.tapAt(p.position) then
				p.role = "claimed"
			end
		end
		task.spawn(function()
			local pace = math.max(selectedToy.cooldown, 0.045) + 0.005
			while pointers[key] == p and PokeController.getSelected() == selectedToy.id do
				task.wait(pace)
				if pointers[key] ~= p then
					break
				end
				-- A round into a dummy under the pointer. pressAt returns true if it hit a dummy or
				-- fired through the normal path; false if the pointer is on empty air.
				if not PokeController.pressAt(p.position) then
					PokeController.tapAt(p.position)
				end
			end
		end)
	end
	glideYaw, glidePitch = 0, 0
	if p.role ~= "claimed" and input and ViewMode.isLab() then
		startPinch()
	end
end

local function onMove(key: any, at: Vector2)
	local p = pointers[key]
	if not p then
		return
	end
	local delta = at - p.position
	p.position = at
	if p.role == "claimed" then
		return
	end
	if p.input and GrabController.isGrabbing() then
		return -- a second finger while holding a dummy pinches its distance, not the camera
	end
	if p.role == "multi" then
		local free = activeFree()
		if #free == 2 and pinchSpan and pinchMid and not GrabController.isGrabbing() then
			local span = (free[1].position - free[2].position).Magnitude
			zoomTo(pinchDistance * (pinchSpan :: number) / math.max(span, 1))
			local mid = (free[1].position + free[2].position) / 2
			panBy(mid.X - pinchMid.X, mid.Y - pinchMid.Y)
			pinchMid = mid
			userTouched()
		end
		return
	end
	if not ViewMode.isLab() then
		if p.role == "pending" and (at - p.start).Magnitude > TAP_SLOP then
			p.role = "orbit" -- the standard camera turns; this is no longer a tap
		end
		return
	end
	if p.role == "pending" and (at - p.start).Magnitude > TAP_SLOP then
		p.role = "orbit"
		orbitBy((at - p.start).X, (at - p.start).Y)
		userTouched()
		orbitedOnce = true
		return
	end
	if p.role == "orbit" then
		orbitBy(delta.X, delta.Y)
		-- Track the finger's angular speed for the glide after release (smoothed, capped).
		local now = os.clock()
		local dt = math.clamp(now - p.movedAt, 1 / 240, 0.1)
		p.movedAt = now
		local vy = math.clamp(-delta.X * ORBIT_DEG_PER_PX / dt, -540, 540)
		local vp = math.clamp(-delta.Y * ORBIT_DEG_PER_PX / dt, -360, 360)
		glideYaw += (vy - glideYaw) * 0.5
		glidePitch += (vp - glidePitch) * 0.5
		userTouched()
	end
end

local function onRelease(key: any, at: Vector2)
	local p = pointers[key]
	if not p then
		return
	end
	pointers[key] = nil
	if (p :: any).charge then
		PokeController.endCharge(at)
		return
	end
	if p.role == "pending" and os.clock() - p.began <= TAP_TIME then
		if not BuildController.tapAt(at) and not (p.input and GrabController.tapAt(at)) and not buttonOnly(p.input) then
			PokeController.tapAt(at)
		end
	end
	if p.role ~= "orbit" or os.clock() - p.movedAt > 0.08 then
		glideYaw, glidePitch = 0, 0 -- no flick: the finger had stopped before lifting
	end
	if p.role == "multi" then
		pinchSpan = nil
		-- The finger left behind keeps orbiting from where it is, not from where it started.
		for _, other in pointers do
			if other.role == "multi" then
				other.role = "orbit"
				other.start = other.position
			end
		end
	end
end

local function keyboardMove(dt: number)
	if not ViewMode.isLab() or UserInputService:GetFocusedTextBox() then
		return
	end
	local function down(k: Enum.KeyCode): number
		return if UserInputService:IsKeyDown(k) then 1 else 0
	end
	local fwd = down(Enum.KeyCode.W) + down(Enum.KeyCode.Up) - down(Enum.KeyCode.S) - down(Enum.KeyCode.Down)
	local side = down(Enum.KeyCode.D) + down(Enum.KeyCode.Right) - down(Enum.KeyCode.A) - down(Enum.KeyCode.Left)
	-- (Q / E by default; while building those keys pick parts instead, but not while the machine
	-- plays: then they turn the camera again.)
	local building = BuildController.editing() or Keybinds.capturing
	local turn = if building then 0 else down(Keybinds.key("CamRight")) - down(Keybinds.key("CamLeft"))
	if fwd == 0 and side == 0 and turn == 0 then
		return
	end
	userTouched()
	local fast = if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then 2.2 else 1
	local step = distance * KEY_PAN_SPEED * fast * dt
	local right = Vector3.new(math.cos(math.rad(yaw)), 0, -math.sin(math.rad(yaw)))
	local forward = Vector3.new(-math.sin(math.rad(yaw)), 0, -math.cos(math.rad(yaw)))
	focus = clampFocus(focus + (forward * fwd + right * side) * step)
	yaw -= turn * KEY_TURN_SPEED * dt
end

-- Keeps the action in frame while the player is not steering the camera.
local function autoFollow(dt: number, camera: Camera)
	local now = os.clock()
	if now - lastUserInput < 2 or GrabController.isGrabbing() then
		return
	end
	local best: BasePart? = nil
	local bestSpeed = FOLLOW_SPEED
	local folder = Workspace:FindFirstChild("Dummies")
	if folder then
		for _, d in folder:GetChildren() do
			local pelvis = d:FindFirstChild("LowerTorso")
			if pelvis and pelvis:IsA("BasePart") and d:GetAttribute("Owner") == player.UserId then
				local speed = pelvis.AssemblyLinearVelocity.Magnitude
				if speed > bestSpeed then
					best, bestSpeed = pelvis, speed
				end
			end
		end
	end
	if best then
		lastFast = now
		local p, onScreen = camera:WorldToViewportPoint(best.Position)
		local size = camera.ViewportSize
		local inside = onScreen
			and p.X > size.X * 0.15 and p.X < size.X * 0.85
			and p.Y > size.Y * 0.12 and p.Y < size.Y * 0.8
		if not inside then
			local target = clampFocus(Vector3.new(best.Position.X, math.max(best.Position.Y, origin.Y + 3), best.Position.Z))
			focus = focus:Lerp(target, 1 - math.exp(-FOLLOW_RATE * dt))
			autoAway = true
		end
	elseif autoAway and now - lastFast > CALM_BEFORE_HOME then
		focus = focus:Lerp(home, 1 - math.exp(-1.5 * dt))
		if (focus - home).Magnitude < 0.5 then
			focus = home
			autoAway = false
		end
	end
end

local function updateRecenterButton()
	local button = recenterButton
	if not button then
		return
	end
	local away = (focus - home).Magnitude > 12 or math.abs(distance - HOME_DISTANCE) > 25
		or math.abs(((yaw - HOME_YAW + 180) % 360) - 180) > 70
	-- (Rests in doctor mode: the monitor has the bottom, and the camera is not the point then.)
	button.Visible = away and ViewMode.isLab() and not ReplayController.isPlaying() and not PokeController.isDoctor()
end

-- Phase 0: a gamepad in the lab view: the right stick orbits, the left one pans.
local padOrbit, padPan = Vector2.zero, Vector2.zero
local PAD_DEAD = 0.15

local function onRender(dt: number)
	if ViewMode.isLab() and (padOrbit.Magnitude > PAD_DEAD or padPan.Magnitude > PAD_DEAD) then
		if padOrbit.Magnitude > PAD_DEAD then
			orbitBy(padOrbit.X * dt * 500, -padOrbit.Y * dt * 350)
		end
		if padPan.Magnitude > PAD_DEAD then
			panBy(-padPan.X * dt * 600, padPan.Y * dt * 600)
		end
		userTouched()
	end
	local camera = Workspace.CurrentCamera
	if not camera or ReplayController.isPlaying() then
		return
	end
	if not ViewMode.isLab() then
		updateRecenterButton()
		return
	end
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	keyboardMove(dt)
	-- Glide after a flick, unless a finger is still orbiting.
	local orbiting = false
	for _, p in pointers do
		if p.role == "orbit" then
			orbiting = true
		end
	end
	if rightDrag then
		orbiting = true
	end
	if not orbiting and (math.abs(glideYaw) > 0.5 or math.abs(glidePitch) > 0.5) then
		yaw += glideYaw * dt
		pitch = math.clamp(pitch + glidePitch * dt, MIN_PITCH, MAX_PITCH)
		local decay = math.exp(-ORBIT_GLIDE_DECAY * dt)
		glideYaw *= decay
		glidePitch *= decay
	end
	autoFollow(dt, camera)

	local k = 1 - math.exp(-16 * dt)
	shownYaw += (yaw - shownYaw) * k
	shownPitch += (pitch - shownPitch) * k
	shownDistance += (distance - shownDistance) * (1 - math.exp(-11 * dt))
	shownFocus = shownFocus:Lerp(focus, 1 - math.exp(-9 * dt))

	local rotation = CFrame.fromOrientation(math.rad(shownPitch), math.rad(shownYaw), 0)
	local eye = shownFocus - rotation.LookVector * shownDistance
	camera.CFrame = CFrame.new(eye) * rotation
	camera.Focus = CFrame.new(shownFocus)

	updateRecenterButton()

	-- Teach the lab camera once, after the player has had a moment with it.
	if not hintShown and not orbitedOnce and os.clock() - startedAt > 25 then
		hintShown = true
		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
			Toast.show("Drag to look around · pinch to zoom")
		else
			Toast.show("Right-drag to look around · scroll to zoom · WASD to move")
		end
	end
end

local function buildRecenterButton()
	local gui = Instance.new("ScreenGui")
	gui.Name = "LabCamera"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)
	local button = Instance.new("ImageButton")
	button.Name = "Recenter"
	HudSlots.apply(button, "Recenter", HudSlots.context(ViewMode.isTouch(), true))
	button.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	button.BackgroundTransparency = 0.1
	button.Image = Assets.Recenter
	button.ScaleType = Enum.ScaleType.Fit
	button.Visible = false
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = button
	KitStyle.button(button, true)
	UserInputService.InputBegan:Connect(function(input, processed)
		if button.Visible and not BuildController.editing() and Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("Recenter", input.KeyCode) then
			recenter()
		end
	end)
	button.Activated:Connect(function()
		recenter()
		KitStyle.pop(button, 0.85) -- (on the slot's own UIScale: never a second one)
	end)
	button.Parent = gui

	-- The view switch, top right.
	local view = Instance.new("TextButton")
	view.Name = "View"
	HudSlots.apply(view, "View", HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()))
	view.BackgroundColor3 = Theme.Palette.dusk
	view.Text = "LAB VIEW"
	view.AutoButtonColor = true
	KitStyle.button(view)
	KitStyle.icon(view, KitStyle.HUD_ICONS.View) -- (UI v2: the drawn eye beside the word)
	-- The key for it, in the corner of the button (keyboards only; V unless changed in Controls).
	if ViewMode.showKeys() then -- (F70)
		local key = Instance.new("TextLabel")
		key.Name = "Key"
		key.AnchorPoint = Vector2.new(1, 0.5)
		key.Position = UDim2.new(1, -6, 0.5, 0)
		key.Size = UDim2.fromOffset(20, 20)
		key.BackgroundColor3 = Theme.Palette.gold
		key.TextColor3 = Theme.Palette.ink
		key.FontFace = Theme.Fonts.display
		key.TextSize = 14
		key.Text = Keybinds.labelOf("View")
		key.AutomaticSize = Enum.AutomaticSize.X
		Keybinds.onChanged(function()
			key.Text = Keybinds.labelOf("View")
		end)
		key.ZIndex = 5
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, 6)
		round.Parent = key
		local edge = Instance.new("UIStroke")
		edge.Color = Theme.Palette.ink
		edge.Thickness = 2
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Parent = key
		key.Parent = view
	end
	local function toggleView()
		if ReplayController.isPlaying() then
			return -- the replay owns the camera until it ends
		end
		local told = hintShown
		hintShown = true -- switching says how the lab view works
		local toLab = not ViewMode.isLab()
		ViewMode.set(if toLab then "Lab" else "Player")
		-- (21 Nov 2026, research: constant pop-ups drive players away: the how-to once a visit, and no
		-- "Walking again": the view itself says it.)
		if toLab and not told then
			Toast.show(if ViewMode.isTouch()
				then "Lab view: drag to look around, pinch to zoom"
				else "Lab view: right-drag to look around, scroll to zoom, WASD to move")
		end
	end
	view.Activated:Connect(toggleView)
	LabCamera.toggleView = toggleView -- (the gamepad's Select: GamepadControls)
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("View", input.KeyCode) then
			toggleView()
		end
	end)
	view.Parent = gui
	viewButton = view
	-- Placed again when the screen settles or changes (the first frames report a tiny viewport, which
	-- would leave the phone-sized button on a PC).
	local function placeView()
		local ctx = HudSlots.context(ViewMode.isTouch(), ViewMode.isLab())
		HudSlots.apply(view, "View", ctx)
		-- (Phase 0: a phone shows LAB VIEW after the quiet start, HudSlots.PHONE_LATER; the lab view
		-- itself always keeps its way back.)
		-- (UI audit 21 Nov 2026: on a computer with the big HUD the lab view is a key, C, in the chips and
		-- the LAB window; the button only shows as WALK, the way back.)
		local pcBig = not ViewMode.isTouch() and HudGate.active()
		view.Visible = ViewMode.isLab() or (not ViewMode.isTouch() and -- (23 Nov 2026, owner: no LAB VIEW button on phones)
			HudSlots.shownNow("View", ctx, time(), Config.QUIET_START) and not pcBig)
		-- The V badge only fits the wide button (off phones).
		local key = view:FindFirstChild("Key")
		if key and key:IsA("GuiObject") then
			key.Visible = not ctx.phone
		end
	end
	HudSlots.watch(placeView)
	ViewMode.onChanged(function()
		placeView() -- (WALK shows in the lab view and goes again when you walk)
	end)
	-- (Audit area 1: placed again when the newcomer answer comes or the reveal moves, and once the
	-- player's own quiet start is over: QUIET_START, or a newcomer's later reveal.)
	HudSlots.newcomerChanged.Event:Connect(placeView)
	task.spawn(function()
		while time() < HudSlots.quietUntil(Config.QUIET_START) + 0.1 do
			task.wait(0.5)
		end
		placeView()
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
	recenterButton = button
end

-- In the lab view the avatar stands still (WASD and the touch area belong to the camera) and the
-- thumbstick is hidden. In the player view it walks and jumps like in any Roblox game.
local function applyToCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") or character ~= player.Character then
		return
	end
	if ViewMode.isLab() then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		humanoid.JumpPower = 0
	else
		humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
		humanoid.JumpPower = StarterPlayer.CharacterJumpPower
	end
end

local function applyMode()
	local lab = ViewMode.isLab()
	GuiService.TouchControlsEnabled = not lab
	if player.Character then
		task.spawn(applyToCharacter, player.Character)
	end
	local camera = Workspace.CurrentCamera
	if lab then
		-- Start the lab view over the lab, looking the way you were looking.
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.1 then
			yaw = math.deg(math.atan2(-flat.X, -flat.Z))
		end
		focus, pitch, distance = home, HOME_PITCH, HOME_DISTANCE
		shownFocus, shownYaw, shownPitch, shownDistance = focus, yaw, pitch, distance
		glideYaw, glidePitch = 0, 0
		camera.CameraType = Enum.CameraType.Scriptable
	else
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
	local button = viewButton
	if button then
		button.Text = if lab then "WALK" else "LAB VIEW"
	end
	updateRecenterButton()
end

local function watchAvatar()
	player.CharacterAdded:Connect(applyToCharacter)
	if player.Character then
		task.spawn(applyToCharacter, player.Character)
	end
	ViewMode.onChanged(applyMode)
	applyMode()
end

function LabCamera.start()
	-- The lab view looks over your own lab (the server tells each player where theirs is; the
	-- plaza's, on the Workspace, until it has).
	local me = Players.LocalPlayer
	local function labAttribute(name: string): any
		local own = me:GetAttribute(name)
		return if own ~= nil then own else Workspace:GetAttribute(name)
	end
	local labOrigin = labAttribute("LabOrigin")
	local labFocus = labAttribute("LabFocus")
	if typeof(labOrigin) == "Vector3" then
		origin = labOrigin
	end
	if typeof(labFocus) == "Vector3" then
		home = labFocus
	end
	focus, shownFocus = home, home
	-- The server may publish the lab layout after this client started.
	local function relaid()
		local f = labAttribute("LabFocus")
		local o = labAttribute("LabOrigin")
		if typeof(o) == "Vector3" then
			origin = o
		end
		if typeof(f) == "Vector3" then
			local wasHome = (focus - home).Magnitude < 1
			home = f
			if wasHome then
				focus = home
			end
		end
	end
	Workspace:GetAttributeChangedSignal("LabFocus"):Connect(relaid)
	me:GetAttributeChangedSignal("LabFocus"):Connect(relaid)

	buildRecenterButton()
	watchAvatar()

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			local at = UserInputService:GetMouseLocation()
			local inset = GuiService:GetGuiInset() -- (0.37.11: GetGuiObjectsAtPosition lives on PlayerGui, in its own space under the top bar)
			for _, object in (player:WaitForChild("PlayerGui") :: PlayerGui):GetGuiObjectsAtPosition(at.X, at.Y - inset.Y) do
				if object:IsA("GuiButton") or object:IsA("TextBox") then return end
			end
		end
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch then
			onPress(input, input, viewportOf(input))
		elseif kind == Enum.UserInputType.MouseButton1 then
			onPress("mouse", nil, UserInputService:GetMouseLocation())
		elseif kind == Enum.UserInputType.MouseButton2 and ViewMode.isLab() then
			rightDrag = UserInputService:GetMouseLocation()
			glideYaw, glidePitch = 0, 0
		elseif kind == Enum.UserInputType.MouseButton3 and ViewMode.isLab() then
			middleDrag = UserInputService:GetMouseLocation()
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		local kind = input.UserInputType
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			padOrbit = Vector2.new(input.Position.X, input.Position.Y)
		elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
			padPan = Vector2.new(input.Position.X, input.Position.Y)
		end
		if kind == Enum.UserInputType.Touch then
			onMove(input, viewportOf(input))
		elseif kind == Enum.UserInputType.MouseMovement then
			local at = UserInputService:GetMouseLocation()
			onMove("mouse", at)
			if rightDrag then
				local d = at - (rightDrag :: Vector2)
				rightDrag = at
				orbitBy(d.X, d.Y)
				userTouched()
				orbitedOnce = true
			end
			if middleDrag then
				local d = at - (middleDrag :: Vector2)
				middleDrag = at
				panBy(d.X, d.Y)
				userTouched()
			end
		elseif kind == Enum.UserInputType.MouseWheel and not processed and not GrabController.isGrabbing() and ViewMode.isLab() then
			zoomTo(distance * (1 - input.Position.Z * 0.12))
			userTouched()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch then
			onRelease(input, viewportOf(input))
		elseif kind == Enum.UserInputType.MouseButton1 then
			onRelease("mouse", UserInputService:GetMouseLocation())
		elseif kind == Enum.UserInputType.MouseButton2 then
			rightDrag = nil
		elseif kind == Enum.UserInputType.MouseButton3 then
			middleDrag = nil
		end
	end)

	RunService:BindToRenderStep("RagdollLabCamera", Enum.RenderPriority.Camera.Value, onRender)
end

function LabCamera.recenter()
	recenter()
end

return LabCamera
