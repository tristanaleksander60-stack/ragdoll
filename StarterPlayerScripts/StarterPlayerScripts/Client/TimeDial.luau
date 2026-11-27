--!strict
-- V9-2c (owner, 21 Nov 2026: "Z should not just stop time in a small spot in the lab, but open a small
-- menu where you turn time faster or slower in a bubble round yourself"; Config.TIME_DIAL).
-- Z (or the Lab window's SLOW-MO row, on a phone too) opens the TIME window:
--   * the speed big, and six steps 0.1x · 0.25x · 0.5x · 1x · 2x · 3x (blue slow, orange fast);
--   * the bubble's size: SMALL · MEDIUM · BIG (12 / 20 / 30 studs round you);
--   * START / STOP.
-- It opens on 0.25x, MEDIUM, so Z then Enter is the old slow-mo. While it is open: Enter starts or
-- stops, LB/RB (pad) step the speed, Z or the X closes it. A change while the bubble is on is sent at
-- once (the server paces and checks it: SandboxService.setTime). The bubble itself: Client/SlowMotion.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any

local TimeDial = {}

TimeDial.SPEEDS = { 0.1, 0.25, 0.5, 1, 2, 3 }
TimeDial.SIZES = { { word = "SMALL", radius = 12 }, { word = "MEDIUM", radius = 20 }, { word = "BIG", radius = 30 } }
TimeDial.SLOW = Color3.fromRGB(110, 190, 255)
TimeDial.FAST = Color3.fromRGB(255, 160, 60)

local player = Players.LocalPlayer
local speed = 0.25
local size = 20
local window: any = nil
local big: TextLabel? = nil
local speedButtons: { [number]: any } = {}
local sizeButtons: { [number]: any } = {}
local startButton: any = nil
local sendToken = 0

local function isOn(): boolean
	return type(player:GetAttribute("TimeScale")) == "number"
end

local function label(s: number): string
	return (if s < 1 then tostring(s) else string.format("%d", s)) .. "x"
end

local function send(on: boolean)
	Net.event(Net.Names.Sandbox):FireServer("Time", speed, size, on)
end

local function refresh()
	local on = isOn()
	local shown = if on then (player:GetAttribute("TimeScale") :: number) else speed
	if big then
		big.Text = label(shown)
		big.TextColor3 = if shown < 1 then TimeDial.SLOW elseif shown > 1 then TimeDial.FAST else Color3.new(1, 1, 1)
	end
	for s, b in speedButtons do
		b.setRole(if s == speed then (if s > 1 then "accent" else "info") else "neutral")
	end
	for r, b in sizeButtons do
		b.setRole(if r == size then "info" else "neutral")
	end
	if startButton then
		startButton.setRole(if on then "danger" else "go")
		startButton.setText(if on then "STOP" else "START")
	end
end

local function pick(s: number?, r: number?)
	if s then
		speed = s
	end
	if r then
		size = r
	end
	C.playSound("tick", if speed < 1 then 0.8 + speed * 0.3 else 1 + speed * 0.1)
	-- (Quick taps: only the last choice goes, 0.3 s after it (the server takes one change per 0.25 s),
	-- so the lit button and the bubble always agree.)
	if isOn() then
		sendToken += 1
		local token = sendToken
		task.delay(0.3, function()
			if token == sendToken and isOn() then
				send(true)
			end
		end)
	end
	refresh()
end

local function toggleOn()
	local starting = not isOn()
	send(starting)
	if starting then
		if Controller.isOpen("Time") then
			Controller.toggle("Time") -- (the bubble is on: the view clear again, so Z then Enter is one quick slow-mo)
		end
	end
end

local function step(by: number)
	local i = table.find(TimeDial.SPEEDS, speed) or 2
	pick(TimeDial.SPEEDS[math.clamp(i + by, 1, #TimeDial.SPEEDS)], nil)
end

local function row(parent: Instance, order: number, height: number): Frame
	local r = Instance.new("Frame")
	r.Name = "Row" .. order
	r.BackgroundTransparency = 1
	r.Size = UDim2.new(1, 0, 0, height)
	r.AutomaticSize = Enum.AutomaticSize.Y
	r.LayoutOrder = order
	r.Parent = parent
	local l = C.list(r, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	l.Wraps = true
	return r
end

local function build()
	window = C.Window({ name = "Time", title = "TIME", theme = "settings", icon = "hud_slowmo", size = Vector2.new(620, 400) })
	local body = window.body
	local b = C.Text("display", label(speed), { size = UDim2.new(1, 0, 0, 64), layoutOrder = 1, parent = body })
	b.Name = "Speed"
	b.TextScaled = false
	b.TextSize = 56 -- (the speed, big: it is what the window is about)
	big = b
	local speeds = row(body, 3, 56)
	for i, s in TimeDial.SPEEDS do
		speedButtons[s] = C.Button({ name = "Speed" .. i, text = label(s), role = "neutral", size = UDim2.fromOffset(86, 54), layoutOrder = i, parent = speeds, onActivated = function()
			pick(s, nil)
		end })
	end
	local sizes = row(body, 4, 56)
	for i, z in TimeDial.SIZES do
		sizeButtons[z.radius] = C.Button({ name = "Size" .. i, text = z.word, role = "neutral", size = UDim2.fromOffset(150, 54), layoutOrder = i, parent = sizes, onActivated = function()
			pick(nil, z.radius)
		end })
	end
	local go = row(body, 5, 64)
	startButton = C.Button({ name = "Start", text = "START", icon = "hud_slowmo", role = "go", size = UDim2.fromOffset(300, 62), layoutOrder = 1, parent = go, onActivated = toggleOn })
	window.defaultSelection = startButton.hit
	-- (An upright phone: START right under the speed, in view without scrolling.)
	local function order()
		local camera = workspace.CurrentCamera
		go.LayoutOrder = if camera and camera.ViewportSize.Y > camera.ViewportSize.X then 2 else 5
	end
	order()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(order)
	end
	Controller.register(window)
end

-- (AUDIT 28: the speed chips and START/STOP right in the LAB row, no window in between.) quick(s) starts time at speed
-- s round you; quick(nil) switches it on or off at the speed it has.
function TimeDial.quick(s: number?)
	if s then
		speed = s
		send(true)
	else
		send(not isOn())
	end
	task.defer(refresh)
end
function TimeDial.isOn(): boolean
	return isOn()
end

-- Opens or closes the TIME window (Z, the Lab window's SLOW-MO row).
function TimeDial.toggle()
	Controller.toggle("Time")
end

function TimeDial.start()
	if not Config.TIME_DIAL then
		return
	end
	build()
	refresh()
	player:GetAttributeChangedSignal("TimeScale"):Connect(refresh)
	-- While it is open: Enter starts or stops (Z then Enter = the old slow-mo), LB/RB step the speed.
	Controller.onChanged(function(name: string, open: boolean)
		if name ~= "Time" then
			return
		end
		if open then
			ContextActionService:BindActionAtPriority("TimeDialKeys", function(_, state, input)
				if state ~= Enum.UserInputState.Begin then
					return Enum.ContextActionResult.Pass
				end
				if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
					toggleOn()
				elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
					step(-1)
				elseif input.KeyCode == Enum.KeyCode.ButtonR1 then
					step(1)
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value + 30, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
		else
			ContextActionService:UnbindAction("TimeDialKeys")
		end
	end)
end

return TimeDial
