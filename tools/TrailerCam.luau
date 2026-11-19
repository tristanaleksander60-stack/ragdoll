--!strict
-- Store video (trailer), the CLIENT half: the camera. Studio only, in Play (solo).
-- Run it with the Studio MCP's run_code on the CLIENT first, then TrailerServer.luau on the server.
-- It hides every UI, and for each shot the server announces (Workspace "TrailerShot" and
-- "TrailerFocus") flies a smooth cinematic camera: orbit, low dolly, tracking, crane. When the
-- server sets the shot to 0 the normal camera and UI come back.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera :: Camera
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Every UI off (ours and Roblox's), and back on at the end.
local hidden: { ScreenGui } = {}
for _, g in gui:GetChildren() do
	if g:IsA("ScreenGui") and g.Enabled then
		g.Enabled = false
		table.insert(hidden, g)
	end
end
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

-- (offset from the focus at the shot's start, offset at its end, field of view)
local SHOTS: { [number]: { a: Vector3, b: Vector3, fov: number, orbit: boolean? } } = {
	[1] = { a = Vector3.new(0, 70, 110), b = Vector3.new(0, 70, 110), fov = 55, orbit = true },
	[2] = { a = Vector3.new(14, 6, 22), b = Vector3.new(-30, 30, 10), fov = 60 },
	[3] = { a = Vector3.new(-22, 3, 10), b = Vector3.new(-14, 3, 4), fov = 50 },
	[4] = { a = Vector3.new(0, 5, -30), b = Vector3.new(10, 8, -18), fov = 55 },
	[5] = { a = Vector3.new(26, 4, 26), b = Vector3.new(18, 3, 18), fov = 42 },
	[6] = { a = Vector3.new(0, 25, 70), b = Vector3.new(0, 40, 90), fov = 60 },
	[7] = { a = Vector3.new(-60, 60, 0), b = Vector3.new(60, 60, 0), fov = 60 },
	[8] = { a = Vector3.new(0, 45, -80), b = Vector3.new(0, 25, -40), fov = 60 },
}
local SHOT_TIME = 4

local current, since = 0, 0
local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
local connection = RunService.RenderStepped:Connect(function()
	local n = Workspace:GetAttribute("TrailerShot")
	local focus = Workspace:GetAttribute("TrailerFocus")
	if type(n) ~= "number" or typeof(focus) ~= "Vector3" then
		return
	end
	if n ~= current then
		current, since = n, os.clock()
	end
	local s = SHOTS[n]
	if not s then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local t = smooth((os.clock() - since) / SHOT_TIME)
	local offset = s.a:Lerp(s.b, t)
	if s.orbit then
		offset = CFrame.Angles(0, t * math.rad(80), 0) * offset
	end
	-- Shot 4 follows the gorilla when it is there.
	local look = focus :: Vector3
	if n == 4 then
		local creatures = Workspace:FindFirstChild("Creatures")
		local g = creatures and creatures:FindFirstChildWhichIsA("Model")
		if g then
			look = g:GetPivot().Position + Vector3.new(0, 5, 0)
		end
	end
	camera.FieldOfView = s.fov
	camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(look + offset, look), 0.15)
end)

-- The end: back to normal.
Workspace:GetAttributeChangedSignal("TrailerShot"):Connect(function()
	if Workspace:GetAttribute("TrailerShot") == 0 then
		connection:Disconnect()
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		for _, g in hidden do
			g.Enabled = true
		end
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
	end
end)
print("[TrailerCam] ready: start recording, then run TrailerServer.luau on the server")
