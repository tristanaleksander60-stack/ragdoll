--!strict
-- Round 5, phase 00: what only this screen knows, for the server's visit record (SessionStats,
-- DataStore Session_v1): touch, keyboard, gamepad, the screen size, how long the game took to get
-- this far (time() at the client's start = the first picture), and when the first shot went.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local SessionClient = {}

local shot = false
local remote: RemoteEvent? = nil

local function send(kind: string, data: any?)
	local r = remote
	if r then
		r:FireServer(kind, data)
	end
end

-- The first shot this visit (PokeController calls it for every gun shot; only the first is sent).
function SessionClient.shot()
	if shot then
		return
	end
	shot = true
	send("FirstShot", time())
end

function SessionClient.hasShot(): boolean
	return shot
end

function SessionClient.eggCard()
	send("EggCard")
end

-- Seconds from the client starting the game to its first shot (nil: none yet).
SessionClient.bootSeconds = 0

-- Phase 0: each input family once, the first time it is really used ("pad", "keys", "mouse",
-- "touch"), so the record tells a pad on a PC from a keyboard.
local usedSent: { [string]: boolean } = {}
local function familyOf(kind: Enum.UserInputType): string?
	if kind == Enum.UserInputType.Touch then
		return "touch"
	elseif kind == Enum.UserInputType.Keyboard then
		return "keys"
	elseif kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 or kind == Enum.UserInputType.MouseWheel then
		return "mouse"
	elseif string.sub(kind.Name, 1, 7) == "Gamepad" then
		return "pad"
	end
	return nil
end
local function noteInput(input: InputObject)
	local family = familyOf(input.UserInputType)
	if family and not usedSent[family] then
		usedSent[family] = true
		send("Used", family)
	end
end

-- V8-0.8 (see why they leave): the orientation after loading (the boot read can be the loading
-- screen), the screen's health, and what is on screen. All paced: a few dozen messages a visit.
local function portraitNow(): boolean?
	local camera = workspace.CurrentCamera
	if not camera or camera.ViewportSize.X < 100 then
		return nil
	end
	return camera.ViewportSize.Y > camera.ViewportSize.X
end

local function watchOrientation()
	local start = time()
	for _, t in { 10, 30, 60 } do
		task.delay(math.max(0, t - (time() - start)), function()
			send("Orient", { t = t, p = portraitNow() })
		end)
	end
	local last = portraitNow()
	local lastSent = 0
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local now = portraitNow()
			if now ~= nil and now ~= last and time() - lastSent > 2 then
				last = now
				lastSent = time()
				send("Orient", { t = "rot", p = now })
			end
		end)
	end
end

local function watchHealth()
	local RunService = game:GetService("RunService")
	local ScriptContext = game:GetService("ScriptContext")
	local Stats = game:GetService("Stats")
	local errs = 0
	local sigs: { string } = {}
	ScriptContext.Error:Connect(function(message: string)
		errs += 1
		if #sigs < 3 then
			table.insert(sigs, string.sub(message, 1, 90))
		end
	end)
	-- Frames per second, one sample each second; p50 and p5 over the last 60 samples.
	local samples: { number } = {}
	local frames, since = 0, os.clock()
	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = os.clock()
		if now - since >= 1 then
			table.insert(samples, frames / (now - since))
			if #samples > 60 then
				table.remove(samples, 1)
			end
			frames, since = 0, now
		end
	end)
	local function report()
		if #samples < 5 then
			return
		end
		local sorted = table.clone(samples)
		table.sort(sorted)
		local volume = 1
		pcall(function()
			volume = UserSettings():GetService("UserGameSettings").MasterVolume
		end)
		send("Perf", {
			p50 = sorted[math.ceil(#sorted * 0.5)],
			p5 = sorted[math.max(1, math.ceil(#sorted * 0.05))],
			mem = Stats:GetTotalMemoryUsageMb(),
			errs = errs,
			sig = table.concat(sigs, " | "),
			vol = if volume <= 0.01 then 0 elseif volume < 0.35 then 1 elseif volume < 0.75 then 2 else 3,
		})
	end
	task.spawn(function()
		task.wait(30)
		report()
		while true do
			task.wait(60)
			report()
		end
	end)
end

local function watchScreen()
	local Players = game:GetService("Players")
	local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local last = ""
	task.spawn(function()
		while true do
			task.wait(5)
			local state = "play"
			local chase = gui:FindFirstChild("ChaseHud")
			local goal = gui:FindFirstChild("FirstVisitGoal")
			if Controller.getCurrent() ~= nil then
				state = "window"
			elseif chase and chase:IsA("ScreenGui") and chase.Enabled and Players.LocalPlayer:GetAttribute("ChaseLeft") ~= nil then
				state = "chase"
			elseif goal and goal:IsA("ScreenGui") and goal.Enabled then
				state = "objective"
			end
			if state ~= last then
				last = state
				send("Screen", state)
			end
		end
	end)
end

function SessionClient.start()
	SessionClient.bootSeconds = time()
	remote = Net.event(Net.Names.Session)
	send("Frame0") -- (V8-0.8: every first-* time in a report counts from this frame)
	task.spawn(watchOrientation)
	task.spawn(watchHealth)
	task.spawn(watchScreen)
	UserInputService.InputBegan:Connect(noteInput)
	task.spawn(function()
		-- (The first frames report a tiny viewport: wait for a real one.)
		local camera = workspace.CurrentCamera
		for _ = 1, 20 do
			if camera and camera.ViewportSize.X > 100 then
				break
			end
			task.wait(0.1)
			camera = workspace.CurrentCamera
		end
		local size = if camera then camera.ViewportSize else Vector2.zero
		send("Hello", {
			touch = UserInputService.TouchEnabled,
			keys = UserInputService.KeyboardEnabled,
			pad = UserInputService.GamepadEnabled,
			w = size.X,
			h = size.Y,
			boot = SessionClient.bootSeconds,
		})
	end)
end

return SessionClient
