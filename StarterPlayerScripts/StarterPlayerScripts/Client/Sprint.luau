--!strict
-- Sprinting (round 4, M10). In the walk view: hold Shift on a keyboard; on a phone hold the SPRINT
-- button by the jump button; on a controller hold the left stick's click (L3). Across every input
-- it is HOLD-to-run: the moment you release it, you slow back to a walk.
-- Sprinting is faster (SPEED x the walk speed) with a small widening of the view while you run.
-- Never in the lab view (the avatar stands there and Shift pans the camera faster), never while
-- your body is limp or down; it stops by itself when you stop moving.
-- (Shift is Roblox's mouse-lock key when that option is on: the server turns mouse lock off,
-- Main.server, and Shift is sunk here at high priority, so Shift is ours. The lab camera's fast
-- pan reads the key directly, so sinking it costs nothing there.)

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local ViewMode = require(script.Parent:WaitForChild("ViewMode"))
local HudSlots = require(script.Parent:WaitForChild("HudSlots"))
local AvatarMoves = require(script.Parent:WaitForChild("AvatarMoves"))
local FxController = require(script.Parent:WaitForChild("FxController"))

local Sprint = {}

Sprint.SPEED = 1.65 -- x the walk speed (16 -> 26.4)
Sprint.FOV_ADD = 7 -- degrees wider at full sprint
local EASE = 8 -- per second: how fast the speed and the view follow
local ACTION = "RagdollLabSprint"

local player = Players.LocalPlayer
local shiftHeld = false -- Shift on a keyboard
local touchHeld = false -- RUN button held on a touch screen
local touchCount = 0 -- fingers on the RUN button
local padHeld = false -- L3 held on a controller
local amount = 0 -- 0..1, eased
local touchButton: TextButton? = nil

-- Whether sprinting is wanted and allowed right now.
function Sprint.active(): boolean
	if ViewMode.isLab() then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 or humanoid.MoveDirection.Magnitude < 0.1 then
		return false
	end
	if not AvatarMoves.upright(character) then
		return false
	end
	return shiftHeld or touchHeld or padHeld
end

local function showHold()
	local button = touchButton
	local on = touchHeld or padHeld
	if button then
		button.BackgroundColor3 = if on then Color3.fromRGB(60, 170, 90) else Color3.fromRGB(20, 22, 28)
	end
end

-- Our own RUN button (round 4, M10), placed by HudSlots so LayoutCheck sees it: held to run.
local function makeTouchButton(): TextButton
	local gui = Instance.new("ScreenGui")
	gui.Name = "SprintButton"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = player:WaitForChild("PlayerGui")
	local button = Instance.new("TextButton")
	button.Name = "Run"
	button.Text = "RUN"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	button.BackgroundTransparency = 0.3
	button.AutoButtonColor = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = button
	-- The finger that pressed it is followed to its end, wherever it slides or is cancelled.
	button.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		-- (Every finger on it counts: lifting one while another still holds it keeps running.)
		touchCount += 1
		touchHeld = true
		showHold()
		local watch: RBXScriptConnection
		watch = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
				watch:Disconnect()
				touchCount = math.max(touchCount - 1, 0)
				touchHeld = touchCount > 0
				showHold()
			end
		end)
	end)
	button.Parent = gui
	return button
end

-- Round 4, M10: HOLD semantics for every input. Begin → set that source true; End/Cancel → false.
-- The three sources are tracked separately so one releasing never cancels another still held.
local function onAction(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	local pressed = state == Enum.UserInputState.Begin
	local released = state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel
	local keyCode = input.KeyCode
	if keyCode == Enum.KeyCode.LeftShift or keyCode == Enum.KeyCode.RightShift then
		-- (A release always counts, even while typing: Shift never stays held behind a chat box.)
		if released then
			shiftHeld = false
			return Enum.ContextActionResult.Sink
		end
		if UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		if pressed then
			shiftHeld = true
		end
		return Enum.ContextActionResult.Sink
	end
	-- (The only other key bound: L3 on a controller. The RUN button has its own handler.)
	if pressed then
		padHeld = true
	elseif released then
		padHeld = false
	end
	showHold()
	return Enum.ContextActionResult.Sink
end

function Sprint.start()
	ContextActionService:BindActionAtPriority(ACTION, onAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)
	if UserInputService.TouchEnabled then
		touchButton = makeTouchButton()
	end
	showHold()
	-- The touch button only in the walk view (the lab view has no thumbstick to run with), in its
	-- slot for this screen.
	local function place()
		local button = touchButton
		if button then
			HudSlots.apply(button, "Sprint", HudSlots.context(true, ViewMode.isLab()))
			button.Visible = not ViewMode.isLab()
		end
	end
	HudSlots.watch(place)
	-- Drops every input: entering the lab view, leaving the window (its key-up never arrives here)
	-- or a new avatar; no one's hand is still on a button then.
	local function dropAll()
		shiftHeld = false
		touchHeld = false
		touchCount = 0
		padHeld = false
		showHold()
	end
	local function viewChanged()
		place()
		if ViewMode.isLab() then
			dropAll()
		end
	end
	ViewMode.onChanged(viewChanged)
	viewChanged()
	UserInputService.WindowFocusReleased:Connect(dropAll)
	player.CharacterAdded:Connect(dropAll)
	local written: number? = nil -- the speed this module last set (anything else's is left alone)
	RunService.RenderStepped:Connect(function(dt: number)
		-- (A key let go while something else had the input is caught here.)
		shiftHeld = shiftHeld and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
		local want = if Sprint.active() then 1 else 0
		amount += (want - amount) * math.min(1, EASE * dt)
		if want == 0 and amount < 0.01 then
			amount = 0
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and not ViewMode.isLab() then
			local state = humanoid:GetState()
			local plain = state ~= Enum.HumanoidStateType.Climbing and state ~= Enum.HumanoidStateType.Swimming and not humanoid.Sit
			local speed = StarterPlayer.CharacterWalkSpeed * (1 + (Sprint.SPEED - 1) * (if plain then amount else 0))
			-- (Only while the walk speed is ours to set: the plain walk speed or the one we wrote last.
			-- Anything else set it (a stop, a slow, a boost): left alone.)
			local now = humanoid.WalkSpeed
			local ours = math.abs(now - StarterPlayer.CharacterWalkSpeed) < 0.05 or (written ~= nil and math.abs(now - written) < 0.05)
			if ours and math.abs(now - speed) > 0.05 then
				humanoid.WalkSpeed = speed
				written = speed
			end
		end
		FxController.fovExtra = Sprint.FOV_ADD * amount
	end)
end

-- For tests: the eased amount (0 walk .. 1 full sprint).
function Sprint.amount(): number
	return amount
end

-- For tests: force one of the three input sources to a state (for a client self-test, so it does not
-- need a real keyboard, controller or touchscreen to drive the hold semantics).
function Sprint.setInputForTest(source: string, pressed: boolean)
	if source == "shift" then
		shiftHeld = pressed
	elseif source == "touch" then
		touchHeld = pressed
	elseif source == "pad" then
		padHeld = pressed
	end
end

return Sprint
