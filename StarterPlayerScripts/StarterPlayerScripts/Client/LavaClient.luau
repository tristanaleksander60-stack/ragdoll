--!strict
-- 21 Nov 2026 (Config.LAVA_V2, Server/Systems/LavaPit): the lava lives on each screen. Its glowing
-- skin breathes, its light flickers like fire, the crust islands drift a little round their spot.
-- Only pits near the camera move (NEAR studs), 20 times a second: a still pit costs nothing.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LavaClient = {}

LavaClient.NEAR = 160

function LavaClient.start()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.05 then
			return
		end
		acc = 0
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local eye = camera.CFrame.Position
		local t = os.clock()
		for _, glow in CollectionService:GetTagged("LavaGlow") do
			if glow:IsA("BasePart") and (glow.Position - eye).Magnitude < LavaClient.NEAR then
				local phase = glow.Position.X * 0.37 + glow.Position.Z * 0.21
				local k = 0.5 + 0.5 * math.sin(t * 1.4 + phase) * 0.8 + 0.1 * math.sin(t * 4.7 + phase * 2)
				if glow.Material == Enum.Material.CrackedLava then
					-- (The cracks warm and cool: deep red-orange to bright orange.)
					glow.Color = Color3.fromRGB(255, 70, 16):Lerp(Color3.fromRGB(255, 150, 50), math.clamp(k, 0, 1))
				else
					glow.LocalTransparencyModifier = 0
					glow.Transparency = 0.42 + 0.14 * math.sin(t * 1.7 + phase)
				end
			end
		end
		for _, plate in CollectionService:GetTagged("LavaLight") do
			if plate:IsA("BasePart") and (plate.Position - eye).Magnitude < LavaClient.NEAR then
				local light = plate:FindFirstChildOfClass("PointLight")
				if light then
					light.Brightness = 1.9 + 0.35 * math.sin(t * 7.1) + 0.2 * math.sin(t * 13.7)
				end
			end
		end
		for _, crust in CollectionService:GetTagged("LavaCrust") do
			if crust:IsA("BasePart") and (crust.Position - eye).Magnitude < LavaClient.NEAR then
				local home = crust:GetAttribute("Home")
				if typeof(home) == "CFrame" then
					local k = crust.Position.X * 0.5
					crust.LocalTransparencyModifier = 0
					-- (A local offset only: the server's parts stay put; it drifts on this screen.)
					crust.CFrame = home * CFrame.new(0.5 * math.sin(t * 0.3 + k), 0.03 * math.sin(t * 1.1 + k), 0.4 * math.cos(t * 0.25 + k)) * CFrame.Angles(0, 0.15 * math.sin(t * 0.2 + k), 0)
				end
			end
		end
	end)
end

return LavaClient
