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
local fogOn = false
local kindNow: string? = nil

AdminWorld.SKY_ROOMS_Y = 500 -- above this the rooms have roofs: no rain or snow inside

-- The drops: a third on a phone or a small tablet, none with less motion asked for.
local function rateScale(): number
	local ok, Theme = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme")) :: any
	end)
	if ok and Theme.isReducedMotion and Theme.isReducedMotion() then
		return 0
	end
	local cam = Workspace.CurrentCamera
	local short = if cam then math.min(cam.ViewportSize.X, cam.ViewportSize.Y) else 720
	return if game:GetService("UserInputService").TouchEnabled and short < 900 then 1 / 3 else 1
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

-- Fog is added to whatever density the place's own air has now (ZoneLighting sets it per place).
local function fog(on: boolean)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		return
	end
	if on and not fogOn then
		TweenService:Create(atmo, TweenInfo.new(2), { Density = math.min(1, atmo.Density + AdminWorld.FOG_ADD) }):Play()
	elseif not on and fogOn then
		TweenService:Create(atmo, TweenInfo.new(2), { Density = math.max(0, atmo.Density - AdminWorld.FOG_ADD) }):Play()
	end
	fogOn = on
end

local function setWeather(kind: string?)
	kindNow = kind
	fog(kind == "Fog")
	local _, e = ensureSky()
	-- (Every property set for each kind: nothing carries over from the last one.)
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.SpreadAngle = Vector2.zero
	e.Acceleration = Vector3.zero
	if kind == "Rain" then
		e.Color = ColorSequence.new(Color3.fromRGB(200, 215, 235))
		e.Size = NumberSequence.new(0.35)
		e.Squash = NumberSequence.new(4) -- (thin streaks, not dots)
		e.LightEmission = 0.3
		e.Brightness = 1.5
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Transparency = NumberSequence.new(0.15)
		e.Speed = NumberRange.new(55, 65)
		e.Lifetime = NumberRange.new(0.8, 1)
		e.Rate = AdminWorld.RATE.Rain * rateScale()
		e.Enabled = e.Rate > 0
	elseif kind == "Snow" and Workspace:GetAttribute("Christmas") ~= true then
		-- (In the Christmas season ChristmasFx snows already: never two snows at once.)
		e.Color = ColorSequence.new(Color3.new(1, 1, 1))
		e.Size = NumberSequence.new(0.35)
		e.Squash = NumberSequence.new(0)
		e.LightEmission = 0.6
		e.Brightness = 2
		e.Orientation = Enum.ParticleOrientation.FacingCamera
		e.Transparency = NumberSequence.new(0.1)
		e.Speed = NumberRange.new(6, 9)
		e.Lifetime = NumberRange.new(5, 6)
		e.SpreadAngle = Vector2.new(15, 15)
		e.Acceleration = Vector3.new(1.2, 0, 0.6)
		e.Rate = AdminWorld.RATE.Snow * rateScale()
		e.Enabled = e.Rate > 0
	else
		e.Rate = 0 -- (so the sky check never turns it back on)
		e.Enabled = false
	end
end

function AdminWorld.start()
	local function weather()
		local w = Workspace:GetAttribute("AdminWeather")
		setWeather(if type(w) == "string" then w else nil)
	end
	Workspace:GetAttributeChangedSignal("AdminWeather"):Connect(weather)
	Workspace:GetAttributeChangedSignal("Christmas"):Connect(weather)
	weather()
	-- A new place sets its own air: the fog goes back on top of it a moment later.
	local player = game:GetService("Players").LocalPlayer
	player:GetAttributeChangedSignal("Place"):Connect(function()
		if fogOn then
			fogOn = false
			task.delay(1.2, function()
				if kindNow == "Fog" then
					fog(true)
				end
			end)
		end
	end)
	-- The sky part follows the camera (and stops in the roofed rooms high up); the owner's time of
	-- day wins over the place's light every frame (a place change sets its own at once).
	RunService.RenderStepped:Connect(function()
		local s = sky
		local cam = Workspace.CurrentCamera
		local e = emitter
		if s and cam and e and (kindNow == "Rain" or kindNow == "Snow") then
			local high = cam.CFrame.Position.Y > AdminWorld.SKY_ROOMS_Y
			s.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 40, 0))
			if high and e.Enabled then
				e.Enabled = false
			elseif not high and not e.Enabled and e.Rate > 0 then
				e.Enabled = true
			end
		end
		local clock = Workspace:GetAttribute("AdminClock")
		if type(clock) == "number" and Lighting.ClockTime ~= clock then
			Lighting.ClockTime = clock
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
