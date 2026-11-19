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

function SessionClient.start()
	SessionClient.bootSeconds = time()
	remote = Net.event(Net.Names.Session)
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
