--!strict
-- The mood of each place (phase E). The one owner of these Lighting properties (vault: Lighting
-- Mood, one owner per property): when your avatar moves to another place (the server's Place
-- attribute), the light blends to that place's profile over a second. The lab keeps the look it
-- was built with (read once at start).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Places = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Places"))

local ZoneLighting = {}

type Profile = {
	ClockTime: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	ExposureCompensation: number,
	EnvironmentDiffuseScale: number,
	EnvironmentSpecularScale: number,
}

local PROPS = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale" }

-- Rooms are closed boxes: the sun barely reaches in, so the ambient light carries the room and the
-- lamps add pools of colour.
-- (10 Nov 2026, the owner: "like a Steam game, not matte AI quality". Less flat fill light, more sun
-- and sky reflections: shapes get real light and shadow sides, surfaces catch the sky.)
local PROFILES: { [string]: Profile } = {
	Night = { ClockTime = 0.5, Brightness = 1, Ambient = Color3.fromRGB(62, 68, 104), OutdoorAmbient = Color3.fromRGB(40, 46, 80), ExposureCompensation = 0.2, EnvironmentDiffuseScale = 0.5, EnvironmentSpecularScale = 0.8 },
	Warm = { ClockTime = 14, Brightness = 2, Ambient = Color3.fromRGB(112, 94, 78), OutdoorAmbient = Color3.fromRGB(118, 100, 84), ExposureCompensation = 0.1, EnvironmentDiffuseScale = 0.8, EnvironmentSpecularScale = 0.8 },
	Cool = { ClockTime = 14, Brightness = 2, Ambient = Color3.fromRGB(98, 106, 120), OutdoorAmbient = Color3.fromRGB(104, 112, 128), ExposureCompensation = 0.1, EnvironmentDiffuseScale = 0.8, EnvironmentSpecularScale = 0.8 },
	White = { ClockTime = 14, Brightness = 2.4, Ambient = Color3.fromRGB(160, 160, 170), OutdoorAmbient = Color3.fromRGB(165, 165, 175), ExposureCompensation = 0.15, EnvironmentDiffuseScale = 0.9, EnvironmentSpecularScale = 0.6 },
	-- The labs and the plaza: a clear afternoon, sun from the side, a bright sky to reflect.
	Day = { ClockTime = 14.6, Brightness = 3, Ambient = Color3.fromRGB(78, 82, 96), OutdoorAmbient = Color3.fromRGB(128, 134, 150), ExposureCompensation = 0, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1 },
}

-- Each mood's air and colour (the finish follows the place: a night hangar is not a sunny lab).
type Air = { density: number, color: Color3, decay: Color3, saturation: number, tint: Color3 }
local AIR: { [string]: Air } = {
	Lab = { density = 0.24, color = Color3.fromRGB(199, 214, 238), decay = Color3.fromRGB(110, 124, 160), saturation = 0.16, tint = Color3.new(1, 1, 1) },
	Night = { density = 0.32, color = Color3.fromRGB(60, 70, 120), decay = Color3.fromRGB(20, 24, 50), saturation = 0.1, tint = Color3.fromRGB(215, 222, 255) },
	Warm = { density = 0.18, color = Color3.fromRGB(255, 228, 196), decay = Color3.fromRGB(170, 130, 100), saturation = 0.2, tint = Color3.fromRGB(255, 246, 232) },
	Cool = { density = 0.16, color = Color3.fromRGB(214, 226, 240), decay = Color3.fromRGB(130, 145, 170), saturation = 0.12, tint = Color3.fromRGB(240, 246, 255) },
	White = { density = 0.08, color = Color3.fromRGB(245, 245, 250), decay = Color3.fromRGB(220, 220, 230), saturation = 0.06, tint = Color3.new(1, 1, 1) },
}
local airTween: { Tween } = {}

local function applyAir(key: string, instant: boolean?)
	local air = AIR[key] or AIR.Lab
	local atmosphere = Lighting:FindFirstChild("LabAir") :: Atmosphere?
	local cc = Lighting:FindFirstChild("LabFinish") :: ColorCorrectionEffect?
	for _, t in airTween do
		t:Cancel()
	end
	table.clear(airTween)
	local info = TweenInfo.new(if instant then 0 else 0.9, Enum.EasingStyle.Sine)
	if atmosphere then
		local t = TweenService:Create(atmosphere, info, { Density = air.density, Color = air.color, Decay = air.decay })
		t:Play()
		table.insert(airTween, t)
	end
	if cc then
		local t = TweenService:Create(cc, info, { Saturation = air.saturation, TintColor = air.tint })
		t:Play()
		table.insert(airTween, t)
	end
end

local current: string? = nil
local tween: Tween? = nil

local function apply(placeId: string, instant: boolean?)
	local place = Places.byId[placeId] or Places.byId.Lab
	local key = place.light
	if key == current then
		return
	end
	current = key
	applyAir(key, instant)
	local profile = PROFILES[key]
	if not profile then
		return
	end
	if tween then
		tween:Cancel()
	end
	if instant then
		for _, prop in PROPS do
			(Lighting :: any)[prop] = (profile :: any)[prop]
		end
		return
	end
	-- The time of day jumps (the arrival flash covers it; a tween would race the sun across the
	-- sky); the rest blends.
	Lighting.ClockTime = profile.ClockTime
	local goal = table.clone(profile) :: any
	goal.ClockTime = nil
	tween = TweenService:Create(Lighting, TweenInfo.new(0.9, Enum.EasingStyle.Sine), goal)
	;(tween :: Tween):Play()
end

function ZoneLighting.profileFor(placeId: string): string
	local place = Places.byId[placeId] or Places.byId.Lab
	return place.light
end

-- Phase K: the finish on the picture (made here once, on this screen only; if the game already has
-- its own effect of a kind, that one is left alone and not tuned per place): colours a little
-- richer, bright things glowing a touch, a soft haze far away so the sky meets the floor instead
-- of a hard grey edge. Each place's mood then sets the haze's colour and the tint (AIR).
local function finish()
	-- The finished look (10 Nov 2026, a "Steam game", not matte): soft real shadows, a filmic grade
	-- (more contrast, a touch warm), bloom only on what is truly bright, sun rays, and the far
	-- distance a little soft so the eye goes to what is near.
	Lighting.ShadowSoftness = 0.25
	Lighting.GlobalShadows = true
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.Contrast = 0.14
		cc.Brightness = 0.02
	end
	local glow = Lighting:FindFirstChildOfClass("BloomEffect")
	if glow then
		glow.Intensity = 0.55
		glow.Size = 26
		glow.Threshold = 1.05
	end
	if not Lighting:FindFirstChildOfClass("SunRaysEffect") then
		local rays = Instance.new("SunRaysEffect")
		rays.Name = "LabRays"
		rays.Intensity = 0.06
		rays.Spread = 0.6
		rays.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("DepthOfFieldEffect") then
		local dof = Instance.new("DepthOfFieldEffect")
		dof.Name = "LabFocus"
		dof.FarIntensity = 0.12
		dof.FocusDistance = 70
		dof.InFocusRadius = 90
		dof.NearIntensity = 0
		dof.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "LabFinish"
		cc.Saturation = 0.16
		cc.Contrast = 0.14
		cc.Brightness = 0.02
		cc.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "LabGlow"
		bloom.Intensity = 0.55
		bloom.Size = 26
		bloom.Threshold = 1.05
		bloom.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local air = Instance.new("Atmosphere")
		air.Name = "LabAir"
		air.Density = 0.24
		air.Offset = 0.1
		air.Color = Color3.fromRGB(199, 214, 238)
		air.Decay = Color3.fromRGB(110, 124, 160)
		air.Glare = 0.2
		air.Haze = 1.1
		air.Parent = Lighting
	end
end

function ZoneLighting.start()
	finish()
	-- The labs and the plaza: the clear afternoon (Day), not the flatter light the place was built
	-- with; the Christmas theme still tints it through the air and the grade.
	PROFILES.Lab = PROFILES.Day
	for _, prop in PROPS do
		(Lighting :: any)[prop] = (PROFILES.Day :: any)[prop]
	end
	local player = Players.LocalPlayer
	local function update()
		local place = player:GetAttribute("Place")
		apply(if type(place) == "string" then place else "Lab")
	end
	player:GetAttributeChangedSignal("Place"):Connect(update)
	update()
end

return ZoneLighting
