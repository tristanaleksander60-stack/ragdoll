--!strict
-- V8-2.5 (dummy types and a SPAWN key, Config.DUMMY_TYPES): H (Keybinds "SpawnDummy") drops a dummy
-- where you aim (the mouse, or the screen's centre on a pad or touch), in your own lab. Pressed again
-- within CYCLE s it moves on to the next type: MINI, HEAVY, BOUNCY, FLOPPY. The server checks it all
-- (DummySpawn); a refusal says why.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any
local Keybinds = require(Shared:WaitForChild("Keybinds")) :: any

local SpawnKey = {}

SpawnKey.ORDER = { "MINI", "HEAVY", "BOUNCY", "FLOPPY" }
SpawnKey.CYCLE = 3 -- s: a press within this of the last one picks the next type

local player = Players.LocalPlayer
local at = 0
local lastPress = -math.huge

local function aimPoint(): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local screen = if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then UserInputService:GetMouseLocation() else camera.ViewportSize / 2
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ignore, dummies)
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	return if hit then hit.Position else nil
end

function SpawnKey.press()
	local now = os.clock()
	if now - lastPress <= SpawnKey.CYCLE then
		at = at % #SpawnKey.ORDER + 1
	elseif at == 0 then
		at = 1
	end
	lastPress = now
	local point = aimPoint()
	local kind = SpawnKey.ORDER[at]
	if point then
		Net.event(Net.Names.Spawn):FireServer("Spawn", kind, point)
		pcall(function()
			(require(script.Parent:WaitForChild("Toast")) :: any).show(string.format("+%s DUMMY  (press again: next type)", kind))
		end)
	end
end

function SpawnKey.start()
	if not Config.DUMMY_TYPES then
		return
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("SpawnDummy", input.KeyCode) then
			SpawnKey.press()
		end
	end)
	Net.event(Net.Names.Spawn).OnClientEvent:Connect(function(kind: unknown, why: unknown)
		if kind == "Refused" and type(why) == "string" then
			pcall(function()
				(require(script.Parent:WaitForChild("Toast")) :: any).show("Can't drop a dummy: " .. why)
			end)
		end
	end)
end

return SpawnKey
