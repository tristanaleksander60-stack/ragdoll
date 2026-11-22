--!strict
-- Falling snow while the Christmas theme is on (round 3, M7; the server sets the Workspace
-- attribute "Christmas"). One emitter on a sheet that follows the camera, high above it: cheap on a
-- phone (fewer flakes there, and with SETTINGS' motion LESS), nothing per frame but moving the sheet
-- twice a second. Snow never falls indoors in the rooms high above the world (they have roofs).

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))

local ChristmasFx = {}

ChristmasFx.RATE = 120 -- flakes a second on a computer
ChristmasFx.RATE_PHONE = 60
ChristmasFx.RATE_LESS = 40 -- motion LESS (SETTINGS)
local SHEET = Vector3.new(110, 1, 110)
local HEIGHT = 30 -- studs above the camera

local sheet: Part? = nil
local emitter: ParticleEmitter? = nil

local function build(): (Part, ParticleEmitter)
	local p = Instance.new("Part")
	p.Name = "SnowSky"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = SHEET
	local e = Instance.new("ParticleEmitter")
	e.Name = "Snow"
	e.Texture = "rbxasset://textures/particles/smoke_main.dds" -- (a soft round flake when small)
	e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	e.LightEmission = 0.6
	e.Brightness = 2
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.42), NumberSequenceKeypoint.new(1, 0.32) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.85, 0.05), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(9, 11) -- (on past the camera to the ground, even from a raised view)
	e.Speed = NumberRange.new(5, 8)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(12, 12)
	e.Acceleration = Vector3.new(1.2, 0, 0.6) -- (a little wind)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-40, 40)
	e.Rate = 0
	e.Parent = p
	p.Parent = Workspace
	return p, e
end

local function phone(): boolean
	local size = (Workspace.CurrentCamera :: Camera).ViewportSize
	return math.min(size.X, size.Y) <= 500
end

-- A cool winter light while it is on: one colour correction (a touch bluer, a little less
-- saturated), gone when it is off.
local function winterLight(on: boolean)
	local Lighting = game:GetService("Lighting")
	-- (LOOK_V3: the snow alone says winter; no blue tint over the calm daylight.)
	if require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")).LOOK_V3 then
		on = false
	end
	local tint = Lighting:FindFirstChild("ChristmasWinter")
	if on and not tint then
		local c = Instance.new("ColorCorrectionEffect")
		c.Name = "ChristmasWinter"
		c.TintColor = Color3.fromRGB(236, 243, 255)
		c.Saturation = -0.06
		c.Brightness = -0.02
		c.Parent = Lighting
	elseif not on and tint then
		tint:Destroy()
	end
end

local function refresh()
	local on = Workspace:GetAttribute("Christmas") == true
	winterLight(on)
	if on and not sheet then
		sheet, emitter = build()
	end
	local e = emitter
	if e and not on then
		e:Clear() -- (switched off: the flakes in the air go at once)
	end
	if e then
		e.Rate = if not on then 0 elseif Theme.isReducedMotion() then ChristmasFx.RATE_LESS elseif phone() then ChristmasFx.RATE_PHONE else ChristmasFx.RATE
	end
end

function ChristmasFx.start()
	Workspace:GetAttributeChangedSignal("Christmas"):Connect(refresh)
	-- A present drop (every 10 minutes while it is on): said once, wherever you are.
	local Notify = require(script.Parent:WaitForChild("Notify")) :: any -- V6-1
	Workspace:GetAttributeChangedSignal("GiftDrop"):Connect(function()
		if Workspace:GetAttribute("Christmas") == true then
			Notify.say("critical", "Presents are falling in the plaza! Grab one for an egg", Color3.fromRGB(255, 205, 70))
		end
	end)
	refresh()
	local nextMove = 0
	RunService.Heartbeat:Connect(function()
		local p = sheet
		if not p then
			return
		end
		local t = os.clock()
		if t < nextMove then
			return
		end
		nextMove = t + 0.5
		refresh() -- (motion setting, a phone turned)
		local camera = Workspace.CurrentCamera
		if camera then
			local at = camera.CFrame.Position
			-- (Above the rooms in the sky: no snow indoors there.)
			p.Position = Vector3.new(at.X, if at.Y > 500 then -1000 else at.Y + HEIGHT, at.Z)
		end
	end)
end

return ChristmasFx
