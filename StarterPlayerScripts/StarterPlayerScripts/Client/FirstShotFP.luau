--!strict
-- V9-0w (owner, 21 Nov 2026: "when you shoot for the first time, send them into first person so they find
-- out they can"; Config.FIRST_SHOT_FP): on a player's first shot ever (the profile's settings flag
-- fpTaught, so once, not every visit) the camera glides into first person over about 0.4 s. The shot
-- itself still lands; the switch never eats the click. A small pill says how to go back (V on a keyboard,
-- Select on a pad). The player chooses: it never jumps back by itself.
--   * Never while: the first visit's guided step is up (FirstVisitGoal), seated or driving, the lab view,
--     Build, Director mode or an open window. Then the next normal shot does it.
--   * A phone has no first-person button to come back with, so it is keyboard and pad only.
--   * Settings: "First person on first shot" (fpShot) turns it off, "Start in first person" (fpStart)
--     starts every visit in it.
--   * Session_v1: FpAuto (when), FpStay (how long they stayed in first person).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Keybinds = require(Shared:WaitForChild("Keybinds")) :: any
local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any

local Client = script.Parent
local FirstPerson = require(Client:WaitForChild("FirstPerson")) :: any
local ViewMode = require(Client:WaitForChild("ViewMode")) :: any
local Settings = require(Client:WaitForChild("Settings")) :: any
local SessionClient = require(Client:WaitForChild("SessionClient")) :: any

local FirstShotFP = {}

FirstShotFP.GLIDE = 0.4 -- s the camera takes to glide in
FirstShotFP.HINT_TIME = 4 -- s

local player = Players.LocalPlayer
local busy = false
local switchBack = false -- (the glide just happened: a pad's Select goes back, not on to the lab view)

-- Whether this screen has a way back out of first person (V on a keyboard, Select on a pad).
function FirstShotFP.hasWayBack(): boolean
	return not ViewMode.isTouch() and (UserInputService.KeyboardEnabled or UserInputService.GamepadEnabled)
end

local FirstShotRules = require(Shared:WaitForChild("FirstShotRules")) :: any
FirstShotFP.blockedBy = FirstShotRules.blockedBy

local function state()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local gui = player:FindFirstChild("PlayerGui")
	local director = false
	pcall(function()
		director = (require(Client:WaitForChild("Director")) :: any).isOn()
	end)
	return {
		lab = ViewMode.isLab(),
		seated = humanoid ~= nil and humanoid.SeatPart ~= nil,
		building = player:GetAttribute("Building") == true,
		director = director,
		window = Controller.getCurrent() ~= nil,
		guided = gui ~= nil and gui:FindFirstChild("FirstVisitGoal") ~= nil,
		on = FirstPerson.isOn(),
	}
end

FirstShotFP.hintFor = FirstShotRules.hintFor

local function hint()
	local pad = UserInputService:GetLastInputType().Name:sub(1, 7) == "Gamepad"
	local key = "V"
	pcall(function()
		key = Keybinds.labelOf("FirstPerson")
	end)
	pcall(function()
		(require(Client:WaitForChild("Toast")) :: any).show(FirstShotFP.hintFor(pad, key), Color3.fromRGB(120, 200, 255), nil, "eye")
	end)
end

-- The glide: the camera eases in toward the head, then first person locks.
local function glide()
	local camera = Workspace.CurrentCamera
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not camera or not head or not head:IsA("BasePart") then
		FirstPerson.set(true)
		return
	end
	local from = (camera.CFrame.Position - head.Position).Magnitude
	local keptMax = player.CameraMaxZoomDistance
	local t0 = os.clock()
	while os.clock() - t0 < FirstShotFP.GLIDE do
		local k = (os.clock() - t0) / FirstShotFP.GLIDE
		k = 1 - (1 - k) ^ 3 -- (ease out)
		player.CameraMaxZoomDistance = math.max(0.6, from + (0.6 - from) * k)
		RunService.RenderStepped:Wait()
	end
	player.CameraMaxZoomDistance = keptMax
	FirstPerson.set(true)
end

-- After a shot: teach first person once, when the moment is free.
function FirstShotFP.onShot()
	if busy or not Config.FIRST_SHOT_FP or not FirstShotFP.hasWayBack() or not Settings.loaded() then
		return
	end
	local v = Settings.get()
	if not FirstShotRules.shouldTeach(Config.FIRST_SHOT_FP == true, v.fpShot, v.fpTaught, FirstShotFP.hasWayBack()) then
		return
	end
	if FirstShotFP.blockedBy(state()) then
		return -- (the next normal shot does it)
	end
	busy = true
	task.wait(0.05) -- (the shot first: the switch never eats the click)
	if FirstShotFP.blockedBy(state()) then
		busy = false
		return
	end
	Settings.set("fpTaught", true)
	pcall(function()
		Settings.saveNow() -- (kept at once: leaving right after the first shot never teaches it again)
	end)
	switchBack = true
	glide()
	hint()
	pcall(function()
		SessionClient.note("FpAuto")
	end)
	-- How long they stay (Session_v1): sent every 15 s while it lasts (the server keeps the most), and
	-- when they switch back, so one who stays to the end of the visit is counted too.
	local since = os.clock()
	local done = false
	local function note()
		pcall(function()
			SessionClient.note("FpStay", math.floor(os.clock() - since))
		end)
	end
	FirstPerson.onChanged(function(on: boolean)
		if not on and not done then
			done = true
			note()
			-- (Back in third person: a tip once, if they never come back to first person in 5 min.)
			task.delay(300, function()
				if not FirstPerson.isOn() then
					local key = "V"
					pcall(function()
						key = Keybinds.labelOf("FirstPerson")
					end)
					local pad = UserInputService:GetLastInputType().Name:sub(1, 7) == "Gamepad"
					pcall(function()
						(require(Client:WaitForChild("Toast")) :: any).show(if pad then "Tip: Select for first person" else "Tip: " .. key .. " for first person", Color3.fromRGB(120, 200, 255), nil, "eye")
					end)
				end
			end)
		end
	end)
	task.spawn(function()
		while not done and player.Parent do
			task.wait(15)
			if not done then
				note()
			end
		end
	end)
	busy = false
end

-- V9-0w: right after the glide, a pad's Select goes back to the player view (once): GamepadControls.
function FirstShotFP.takeSwitchBack(): boolean
	local was = switchBack
	switchBack = false
	return was
end

function FirstShotFP.start()
	if not Config.FIRST_SHOT_FP then
		return
	end
	SessionClient.onShot(FirstShotFP.onShot)
	-- "Start in first person": once the choices are in and the avatar stands, in the player view.
	task.spawn(function()
		local t0 = os.clock()
		while not Settings.loaded() and os.clock() - t0 < 30 do
			task.wait(0.5)
		end
		local function enter()
			if Settings.get().fpStart and FirstShotFP.hasWayBack() then
				task.wait(1)
				if not FirstShotFP.blockedBy(state()) then
					FirstPerson.set(true)
				end
			end
		end
		if player.Character then
			enter()
		end
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			enter()
		end)
	end)
end

return FirstShotFP
