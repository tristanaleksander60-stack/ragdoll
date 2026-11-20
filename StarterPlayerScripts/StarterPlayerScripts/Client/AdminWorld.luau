--!strict
-- V6-2: what the owner's admin menu sets for everyone, drawn on every screen.
--   Workspace "AdminClock"   a time of day that wins over the place's own light (ZoneLighting)
--   Workspace "AdminWeather" "Rain" | "Snow" | "Fog" (nil = clear)
-- Cheap: one emitter on one part above the camera, rates by device tier.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")


local AdminWorld = {}

AdminWorld.RATE = { Rain = 260, Snow = 90 } -- per second on a PC; a phone gets a third
AdminWorld.FOG_ADD = 0.35 -- Atmosphere density added for Fog

local sky: Part? = nil
local emitter: ParticleEmitter? = nil
local fogBase: number? = nil

local function phoneScale(): number
	local cam = Workspace.CurrentCamera
	local small = cam ~= nil and math.min(cam.ViewportSize.X, cam.ViewportSize.Y) < 600
	return if game:GetService("UserInputService").TouchEnabled and small then 1 / 3 else 1
end

local function ensureSky(): (Part, ParticleEmitter)
	if sky and emitter then
		return sky, emitter
	end
	local p = Instance.new("Part")
	p.Name = "AdminWeatherSky"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(120, 1, 120)
	local e = Instance.new("ParticleEmitter")
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Enabled = false
	e.Parent = p
	p.Parent = Workspace -- (particles under the Camera do not draw)
	sky, emitter = p, e
	return p, e
end

local function setWeather(kind: string?)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		if fogBase == nil then
			fogBase = atmo.Density
		end
		TweenService:Create(atmo, TweenInfo.new(2), { Density = (fogBase :: number) + (if kind == "Fog" then AdminWorld.FOG_ADD else 0) }):Play()
	end
	local _, e = ensureSky()
	if kind == "Rain" then
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(200, 215, 235))
		e.Size = NumberSequence.new(0.35)
		e.Squash = NumberSequence.new(4) -- (thin streaks, not dots)
		e.LightEmission = 0.3
		e.Brightness = 1.5
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Transparency = NumberSequence.new(0.15)
		e.Speed = NumberRange.new(55, 65)
		e.Lifetime = NumberRange.new(0.8, 1)
		e.Rate = AdminWorld.RATE.Rain * phoneScale()
		e.Enabled = true
	elseif kind == "Snow" then
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.new(1, 1, 1))
		e.Size = NumberSequence.new(0.35)
		e.Squash = NumberSequence.new(0)
		e.Orientation = Enum.ParticleOrientation.FacingCamera
		e.Transparency = NumberSequence.new(0.1)
		e.Speed = NumberRange.new(6, 9)
		e.Lifetime = NumberRange.new(7, 9)
		e.SpreadAngle = Vector2.new(15, 15)
		e.Rate = AdminWorld.RATE.Snow * phoneScale()
		e.Enabled = true
	else
		e.Enabled = false
	end
end

function AdminWorld.start()
	local function weather()
		local w = Workspace:GetAttribute("AdminWeather")
		setWeather(if type(w) == "string" then w else nil)
	end
	Workspace:GetAttributeChangedSignal("AdminWeather"):Connect(weather)
	weather()
	-- The sky part follows the camera; the owner's time of day wins over the place's light (which
	-- may set its own on every place change).
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		local s = sky
		local cam = Workspace.CurrentCamera
		if s and cam and emitter and emitter.Enabled then
			s.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 40, 0))
		end
		acc += dt
		if acc >= 0.5 then
			acc = 0
			local clock = Workspace:GetAttribute("AdminClock")
			if type(clock) == "number" and math.abs(Lighting.ClockTime - clock) > 0.01 then
				Lighting.ClockTime = clock
			end
		end
	end)
	-- Back to the place's own time when the owner picks AUTO.
	Workspace:GetAttributeChangedSignal("AdminClock"):Connect(function()
		if Workspace:GetAttribute("AdminClock") == nil then
			require(script.Parent:WaitForChild("ZoneLighting")).reapply()
		end
	end)
end

return AdminWorld
