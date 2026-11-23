--!strict
-- Round 5: FIRST PERSON (V, or 1ST PERSON on the right edge). The camera goes into your head (the
-- player view only: the lab view keeps its own camera), your body is hidden from you, and the weapon
-- you hold shows in front of the camera (Viewmodel: arms, sway, kick, muzzle flash). V again, or the
-- lab view, puts the camera back as it was.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Keybinds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Keybinds"))

local Client = script.Parent
local ViewMode = require(Client:WaitForChild("ViewMode"))

local FirstPerson = {}

local player = Players.LocalPlayer
local on = false
local leftAt = -10
local kept: { mode: Enum.CameraMode, minZoom: number, maxZoom: number }? = nil
local listeners: { (boolean) -> () } = {}

function FirstPerson.isOn(): boolean
	return on
end

function FirstPerson.onChanged(fn: (boolean) -> ())
	table.insert(listeners, fn)
end

function FirstPerson.set(want: boolean)
	if want and ViewMode.isLab() then
		return -- (first person is the player's own eyes: from the player view)
	end
	if want == on then
		return
	end
	on = want
	if want then
		kept = { mode = player.CameraMode, minZoom = player.CameraMinZoomDistance, maxZoom = player.CameraMaxZoomDistance }
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		leftAt = os.clock()
		local k = kept
		player.CameraMode = if k then k.mode else Enum.CameraMode.Classic
		if k then
			player.CameraMinZoomDistance = k.minZoom
			player.CameraMaxZoomDistance = k.maxZoom
		end
		-- (Out of first person Roblox leaves the camera at the head: back to a normal distance.)
		player.CameraMinZoomDistance = math.max(player.CameraMinZoomDistance, 0.5)
		task.defer(function()
			if not on and player.CameraMaxZoomDistance >= 10 then
				local camera = workspace.CurrentCamera
				local head = player.Character and player.Character:FindFirstChild("Head")
				if camera and head and head:IsA("BasePart") and (camera.CFrame.Position - head.Position).Magnitude < 2 then
					player.CameraMinZoomDistance = 10
					task.wait()
					player.CameraMinZoomDistance = if k then k.minZoom else 0.5
				end
			end
		end)
	end
	for _, fn in listeners do
		task.spawn(fn, on)
	end
end

function FirstPerson.toggle()
	FirstPerson.set(not on)
end

-- (22 Nov 2026, owner: "notices you have to close yourself vanish by themselves after a few seconds in
-- first person, so you never have to leave it"): the mouse is locked in first person, so a window
-- there cannot be clicked shut. One that stays open AUTO_CLOSE s closes itself.
FirstPerson.AUTO_CLOSE = 4
FirstPerson.KEEP_OPEN = { Tools = true, Shop = true, Menu = true } :: { [string]: boolean } -- (0.37.20: never closed by themselves)
local function autoClose()
	local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
	local openSince: number? = nil
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).COUNTERS_ONLY then
		return -- (23 Nov 2026: nothing opens by itself any more, so Maps, Multiplayer and the rest stay until you close them)
	end
	while true do
		task.wait(0.5)
		local current = if on then Controller.getCurrent() else nil
		-- (0.37.20, owner: "the weapons menu must work in first person": the menus you open yourself stay open.)
		if current and FirstPerson.KEEP_OPEN[current] then
			current = nil
		end
		if current then
			openSince = openSince or os.clock()
			if os.clock() - (openSince :: number) >= FirstPerson.AUTO_CLOSE then
				Controller.closeAll()
				openSince = nil
			end
		else
			openSince = nil
		end
	end
end

function FirstPerson.start()
	task.spawn(autoClose)
	-- (0.37.20: while any window is open in first person, the mouse is free to click it: a Modal button, the
	-- engine's own way to unlock a locked mouse; it locks again when the window closes.)
	task.spawn(function()
		local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
		local gui = Instance.new("ScreenGui")
		gui.Name = "FirstPersonFreeMouse"
		gui.ResetOnSpawn = false
		gui.Enabled = false
		local free = Instance.new("TextButton")
		free.Name = "FreeMouse"
		free.Modal = true
		free.Text = ""
		free.BackgroundTransparency = 1
		free.Size = UDim2.fromOffset(1, 1)
		free.Parent = gui
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		-- (23 Nov 2026, owner: "weapons, maps and multiplayer in first person: let me use my mouse"): after Roblox's
		-- camera each frame, with any window open and the camera in your head (however it got there), the mouse
		-- is unlocked and its pointer shown; the camera takes it back when the window closes.
		game:GetService("RunService"):BindToRenderStep("FirstPersonFreeMouse", Enum.RenderPriority.Last.Value, function()
			local window = Controller.getCurrent() ~= nil
			local camera = workspace.CurrentCamera
			local head = player.Character and player.Character:FindFirstChild("Head")
			local inHead = on or player.CameraMode == Enum.CameraMode.LockFirstPerson
				or (camera ~= nil and head ~= nil and head:IsA("BasePart") and (camera.CFrame.Position - head.Position).Magnitude < 1.5)
			local want = window and inHead
			if gui.Enabled ~= want then
				gui.Enabled = want
			end
			if want then
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true
			end
		end)
	end)
	ViewMode.onChanged(function()
		if ViewMode.isLab() and on then
			FirstPerson.set(false)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("FirstPerson", input.KeyCode) then
			FirstPerson.toggle()
		end
	end)
	player.CharacterAdded:Connect(function()
		if on then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		end
	end)
	-- v4 A4 (owner): scrolling all the way in enters first person (the gun in your hands), scrolling
	-- out leaves it; V still toggles. Roblox's own zoom is read, never fought: under ENTER_AT studs
	-- from the head counts as in. Not in the lab view, not while seated (a car), not on touch.
	game:GetService("RunService").RenderStepped:Connect(function()
		if on or ViewMode.isLab() or os.clock() - leftAt < 0.6 or not (UserInputService.MouseEnabled or UserInputService.TouchEnabled) then
			return
		end
		local camera = workspace.CurrentCamera
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not camera or not head or not head:IsA("BasePart") or (humanoid and humanoid.SeatPart) then
			return
		end
		if (camera.CFrame.Position - head.Position).Magnitude < FirstPerson.ENTER_AT then
			FirstPerson.set(true)
		end
	end)
	-- (23 Nov 2026, owner: "zoomed in on a phone I must see my weapon": pinching all the way in is first person too;
	-- pinching out leaves it.)
	UserInputService.TouchPinch:Connect(function(_, scale: number, _, _, processed: boolean)
		if on and not processed and scale < 0.85 then
			FirstPerson.set(false)
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if processed or not on or input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end
		if input.Position.Z < 0 then
			-- (Out, however it was entered: set(false) puts the camera back behind the head.)
			FirstPerson.set(false)
		end
	end)
end

FirstPerson.ENTER_AT = 1.0 -- studs from the head: scrolled all the way in

return FirstPerson
