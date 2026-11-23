--!strict
-- UI_3D (19 Nov 2026, the owner: "make all UI 3D interactive"): pictures that hold a real 3D model
-- (ToolPicture's weapon viewports) turn. Each one turns slowly while it is on screen, faster under
-- the pointer, and follows a drag (mouse or finger) when you grab it. A device only turns a few at
-- once (Config.UI_3D_LIVE per tier, the pointed-at one first); the rest stand still, and a still
-- ViewportFrame costs nothing per frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Ui3D = {}

Ui3D.IDLE_SPEED = 0.35 -- rad/s on screen (gentle: the one hovered card, the egg card)
Ui3D.HOVER_SPEED = 1.8 -- rad/s under the pointer
Ui3D.DRAG = 0.012 -- rad per pixel dragged
Ui3D.START = math.rad(-25) -- the first angle (a three-quarter view)

type Entry = { holder: GuiObject, turn: (number) -> (), yaw: number, hovered: boolean, dragging: boolean }

local entries: { Entry } = {}
local started = false

local liveCount: number? = nil
local function budget(): number
	if liveCount then
		return liveCount
	end
	local DeviceTier = require(Shared:WaitForChild("DeviceTier"))
	local FeelTuning = require(Shared:WaitForChild("FeelTuning"))
	local camera = workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
	local plat = FeelTuning.platOf(UserInputService.TouchEnabled, UserInputService.KeyboardEnabled, UserInputService.GamepadEnabled, math.min(view.X, view.Y))
	local n = (Config.UI_3D_LIVE :: any)[DeviceTier.of(plat)] or 4
	liveCount = n
	return n
end

local function onScreen(g: GuiObject): boolean
	if not g.Parent or not g.Visible then
		return false
	end
	local size = g.AbsoluteSize
	if size.X < 8 or size.Y < 8 then
		return false
	end
	-- (Its ScreenGui must be on, every frame above it shown, and it must lie inside any scrolling
	-- list it is in and on the screen: a card scrolled away does not take a turning slot.)
	local at = g.AbsolutePosition
	local camera = workspace.CurrentCamera
	if camera then
		local view = camera.ViewportSize
		if at.X + size.X < 0 or at.Y + size.Y < 0 or at.X > view.X or at.Y > view.Y then
			return false
		end
	end
	local node: Instance? = g.Parent
	while node do
		if node:IsA("ScreenGui") then
			return node.Enabled
		elseif node:IsA("GuiObject") then
			if not node.Visible then
				return false
			end
			if node:IsA("ScrollingFrame") then
				local p, s = node.AbsolutePosition, node.AbsoluteSize
				if at.X + size.X < p.X or at.Y + size.Y < p.Y or at.X > p.X + s.X or at.Y > p.Y + s.Y then
					return false
				end
			end
		end
		node = node.Parent
	end
	return false
end

local PACE = if game:GetService("UserInputService").TouchEnabled then 1 / 24 else 0 -- (a turning picture needs no more on a phone)
local waited = 0
local function frame(step: number)
	waited += step
	if waited < PACE then
		return
	end
	local dt = waited
	waited = 0
	local live = budget()
	-- The ones under the pointer or held first, then the rest in the order they were made.
	local count = 0
	for pass = 1, 2 do
		for i = #entries, 1, -1 do
			local e = entries[i]
			if not e.holder.Parent then
				table.remove(entries, i)
			elseif (pass == 1) == (e.hovered or e.dragging) and count < live and onScreen(e.holder) then
				count += 1
				if not e.dragging then
					e.yaw += dt * (if e.hovered then Ui3D.HOVER_SPEED else Ui3D.IDLE_SPEED)
				end
				e.turn(e.yaw)
			end
		end
	end
end

local function start()
	if started then
		return
	end
	started = true
	RunService.RenderStepped:Connect(frame)
end

-- A low-end device (UI_3D_LIVE.low or less): pictures stay drawn, no models (ToolPicture asks).
function Ui3D.lowEnd(): boolean
	return budget() <= (Config.UI_3D_LIVE :: any).low
end

-- A picture that can turn: `turn(yaw)` redraws it at that angle (radians about the up axis).
function Ui3D.track(holder: GuiObject, turn: (number) -> ())
	if not Config.UI_3D then
		return
	end
	start()
	local e: Entry = { holder = holder, turn = turn, yaw = Ui3D.START, hovered = false, dragging = false }
	table.insert(entries, e)
	turn(e.yaw)
	holder.MouseEnter:Connect(function()
		e.hovered = true
	end)
	holder.MouseLeave:Connect(function()
		e.hovered = false
	end)
	holder.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			e.dragging = true
			local last = input.Position
			local moved: RBXScriptConnection? = nil
			local ended: RBXScriptConnection? = nil
			moved = UserInputService.InputChanged:Connect(function(change: InputObject)
				if change.UserInputType == Enum.UserInputType.MouseMovement or change == input then
					local now = change.Position
					e.yaw += (now.X - last.X) * Ui3D.DRAG
					last = now
					e.turn(e.yaw)
				end
			end)
			ended = UserInputService.InputEnded:Connect(function(done: InputObject)
				if done == input or done.UserInputType == Enum.UserInputType.MouseButton1 then
					e.dragging = false
					if moved then
						moved:Disconnect()
					end
					if ended then
						ended:Disconnect()
					end
				end
			end)
		end
	end)
end

-- Tests: how many pictures can turn.
function Ui3D.countForTest(): number
	return #entries
end

return Ui3D
