--!strict
-- Round 5, phase 2: the weapon in front of the camera in first person (FirstPerson). A copy of the
-- weapon your avatar holds (its HeldTool, HeldService) and a forearm in your skin colour, drawn on
-- this screen only (in the camera, never replicated). It sways a little as you turn, kicks back with
-- every round (AmmoClient.onSpent), flashes at the muzzle (the model's Tip), and dips while it
-- reloads. Melee weapons and tools show too, without the kick.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ammo = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ammo"))
local Toys = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Toys"))

local HitMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HitMath")) :: any
local Client = script.Parent
local FirstPerson = require(Client:WaitForChild("FirstPerson"))
local AmmoClient = require(Client:WaitForChild("AmmoClient"))

local Viewmodel = {}

Viewmodel.OFFSET = CFrame.new(0.85, -0.75, -2.1) -- where the grip sits from the camera
Viewmodel.SCALE = 0.55 -- the copy's size against the one in the hand
Viewmodel.KICK = 0.14 -- studs back a round throws it
Viewmodel.SWAY = 0.06
Viewmodel.TILT = 0.9 -- radians of lift per stud of kick
Viewmodel.SETTLE = 1.4 -- studs of kick taken back a second
Viewmodel.ARM = Vector3.new(0.26, 0.26, 1.1)
Viewmodel.HAND = nil :: Color3? -- nil: the avatar's own hand colour
-- LOOK_V3 (19 Nov 2026, like the big ragdoll games): the gun big in the lower right, held by one
-- plain white hand and forearm from the corner, a small sway, and a short sharp recoil (about 4
-- degrees, settled in about a tenth of a second).
do
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
	if Config.LOOK_V3 then
		Viewmodel.OFFSET = CFrame.new(1.05, -0.95, -2.0)
		Viewmodel.SCALE = 0.8
		Viewmodel.SWAY = 0.03
		Viewmodel.TILT = 0.5
		Viewmodel.SETTLE = 2.6
		Viewmodel.ARM = Vector3.new(0.5, 0.5, 1.9)
		Viewmodel.HAND = Config.LOOK_V3_DUMMY
	end
end

local player = Players.LocalPlayer
local holder: Model? = nil
local shownTool: Model? = nil
local copy: Model? = nil
local arm: BasePart? = nil
local support: BasePart? = nil
local tip: BasePart? = nil
local kick = 0
local swingAt = -math.huge -- (V10 phase 3: when the last melee swing started)
Viewmodel.SWING_TIME = 0.32
local sway = Vector2.zero
local lastLook: Vector3? = nil
local flash: PointLight? = nil
local flashPart: BasePart? = nil
local flashUntil = 0
local toolId = ""
local topY = 0.2 -- studs from the grip to the top of the copy (its sights)
local aimed = 0 -- 0 at the side .. 1 up in the middle
Viewmodel.AIM_AT = -1.45 -- studs ahead of the eye the grip sits while aiming

local function clear()
	if holder then
		holder:Destroy()
	end
	holder, copy, arm, tip, flash, flashPart, shownTool = nil, nil, nil, nil, nil, nil, nil
	support = nil
end

local function build(held: Model)
	clear()
	local h = Instance.new("Model")
	h.Name = "Viewmodel"
	local c = held:Clone()
	for _, d in c:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
			d.LocalTransparencyModifier = 0
		end
	end
	-- (Drawn smaller than in the hand: this close to the camera a real size fills the screen.)
	pcall(function()
		c:ScaleTo(c:GetScale() * Viewmodel.SCALE)
	end)
	c.Parent = h
	-- (How high its sights are over the grip: aiming puts them just under the middle of the screen.)
	local pivot = c:GetPivot()
	topY = 0.05
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			local o = pivot:ToObjectSpace(d.CFrame)
			local half = math.abs(o.RightVector.Y) * d.Size.X / 2 + math.abs(o.UpVector.Y) * d.Size.Y / 2 + math.abs(o.LookVector.Y) * d.Size.Z / 2
			topY = math.max(topY, o.Position.Y + half)
		end
	end
	-- The tip (the muzzle): a part or an attachment named Tip; else the far end of the model.
	local t = c:FindFirstChild("Tip", true)
	if t and t:IsA("BasePart") then
		tip = t
	end
	-- A forearm in the avatar's skin colour, from the grip back towards the bottom right.
	local skin = Color3.fromRGB(230, 190, 150)
	local hand = player.Character and player.Character:FindFirstChild("RightHand")
	if hand and hand:IsA("BasePart") then
		skin = hand.Color
	end
	skin = Viewmodel.HAND or skin
	local a = Instance.new("Part")
	a.Name = "Forearm"
	a.Size = Viewmodel.ARM
	a.Color = skin
	a.Material = Enum.Material.SmoothPlastic
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.CanTouch = false
	a.CastShadow = false
	a.Parent = h
	arm = a
	-- (23 Nov 2026, owner: "both hands on the weapon, always"): the other forearm from the bottom left up to under the
	-- barrel, same colour.
	local s2 = a:Clone()
	s2.Name = "SupportArm"
	s2.Parent = h
	support = s2
	local fp = Instance.new("Part")
	fp.Name = "Flash"
	fp.Shape = Enum.PartType.Ball
	fp.Size = Vector3.new(0.5, 0.5, 0.5)
	fp.Material = Enum.Material.Neon
	fp.Color = Color3.fromRGB(255, 200, 90)
	fp.Transparency = 1
	fp.Anchored = true
	fp.CanCollide = false
	fp.CanQuery = false
	fp.CanTouch = false
	fp.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 90)
	light.Range = 10
	light.Brightness = 0
	light.Parent = fp
	fp.Parent = h
	flash = light
	flashPart = fp
	copy = c
	holder = h
	shownTool = held
	h.Parent = workspace.CurrentCamera
end

-- (23 Nov 2026, owner: "a bat is not held like a gun: upright, and many others too".) How a tool is held: rise = degrees
-- its far end points up, lean = degrees it leans in over the view, both = two hands on the handle. nil = like a gun.
-- The models have the handle at the origin and the far end along -Z (N7Assets.Weapons).
type Hold = { rise: number, lean: number, both: boolean, at: Vector3 }
local UPRIGHT: Hold = { rise = 72, lean = 16, both = false, at = Vector3.new(0, -0.15, 0.1) }
local UPRIGHT2: Hold = { rise = 70, lean = 24, both = true, at = Vector3.new(-0.2, -0.15, 0.1) }
local WAND: Hold = { rise = 48, lean = 14, both = false, at = Vector3.new(0, -0.1, 0) }
local CARRIED: Hold = { rise = 12, lean = 0, both = false, at = Vector3.new(-0.1, -0.05, -0.1) }
local HOLDS: { [string]: Hold } = {
	Bat = UPRIGHT2, Golf = UPRIGHT2, Hammer = UPRIGHT2, Axe = UPRIGHT2, Katana = UPRIGHT2, PlasmaBlade = UPRIGHT2,
	Pan = UPRIGHT, Crowbar = UPRIGHT, Cleaver = UPRIGHT,
}
local LIKE_A_GUN = { Chainsaw = true, RPG = true, GravityGun = true, Portal = true, Bow = true, Slime = true }
local function holdOf(id: string): Hold?
	local toy = Toys.byId[id]
	if not toy or toy.gun or LIKE_A_GUN[id] then
		return nil
	end
	if HOLDS[id] then
		return HOLDS[id]
	end
	if toy.category == "Melee" then
		return UPRIGHT
	end
	if toy.move == "Cast" then
		return WAND
	elseif toy.move == "Throw" or toy.kind == "place" and toy.move ~= "Aim" then
		return CARRIED
	end
	return nil
end

local function heldTool(): Model?
	local character = player.Character
	local held = character and character:FindFirstChild("HeldTool")
	return if held and held:IsA("Model") then held else nil
end

local function frame(dt: number)
	local camera = workspace.CurrentCamera
	local held = heldTool()
	if not FirstPerson.isOn() or not camera or not held then
		if holder then
			clear()
		end
		lastLook = nil
		return
	end
	if held ~= shownTool or not holder or holder.Parent ~= camera then
		build(held)
		local id = held:GetAttribute("Tool") or held:GetAttribute("ToyId")
		toolId = if type(id) == "string" then id else ""
	end
	local c = copy
	if not c then
		return
	end
	-- Sway: the weapon lags a little behind a turn of the camera.
	local look = camera.CFrame.LookVector
	if lastLook then
		local d = camera.CFrame:VectorToObjectSpace(lastLook - look)
		sway = sway:Lerp(Vector2.new(math.clamp(d.X * 6, -1, 1), math.clamp(d.Y * 6, -1, 1)), math.min(1, dt * 10))
	end
	lastLook = look
	sway = sway:Lerp(Vector2.zero, math.min(1, dt * 4))
	kick = math.max(0, kick - dt * Viewmodel.SETTLE)
	-- Reloading: the weapon dips and tilts.
	local reload = Ammo.reloading(AmmoClient.bookForTest(), toolId, os.clock())
	local dip = if reload then math.sin(reload * math.pi) else 0
	local bob = math.sin(os.clock() * 2) * 0.015
	-- (V10 phase 3, owner: "melee in first person: you see the blow land, not a hammer pointing ahead"): a swing
	-- arcs the weapon down and across into the middle of the view and back.
	local st = (os.clock() - swingAt) / Viewmodel.SWING_TIME
	local swing = if st >= 0 and st < 1 then math.sin(st * math.pi) else 0
	-- (24 Nov 2026, owner: aim with every gun: it comes up to the middle, its sights under the crosshair.)
	local GunFeel = require(script.Parent:WaitForChild("GunFeel")) :: any
	local toyNow = Toys.byId[toolId]
	local wantAim = if toyNow and toyNow.gun and GunFeel.zoomed() and not reload then 1 else 0
	aimed += (wantAim - aimed) * math.min(1, dt * 14)
	local place = Viewmodel.OFFSET:Lerp(CFrame.new(0, -topY - 0.035, Viewmodel.AIM_AT), aimed)
	sway *= 1 - 0.6 * aimed
	bob *= 1 - 0.8 * aimed
	local at = camera.CFrame
		* place
		* CFrame.new(-swing * 0.7, -swing * 0.15, -swing * 0.9)
		* CFrame.Angles(-swing * 1.3, swing * 0.5, swing * 0.7)
		* CFrame.new(sway.X * Viewmodel.SWAY, sway.Y * Viewmodel.SWAY - dip * 0.45 + bob, kick)
		* CFrame.Angles(kick * Viewmodel.TILT * (1 - 0.6 * aimed) + dip * -0.5, 0, dip * 0.6)
	-- (Holding a blow: the weapon goes back, the longer the further, trembling when full.)
	local since = player:GetAttribute("Charging")
	if type(since) == "number" then
		local pull = HitMath.chargeOf(os.clock() - since)
		local shake = if pull >= 1 then math.sin(os.clock() * 45) * 0.012 else 0
		at = at * CFrame.new(0.2 * pull + shake, 0.18 * pull, 0.4 * pull) * CFrame.Angles(math.rad(26) * pull, 0, math.rad(-10) * pull)
	end
	local hold = holdOf(toolId)
	if hold then
		local base = at * CFrame.new(hold.at)
		local turn = base * CFrame.Angles(0, 0, math.rad(hold.lean)) * CFrame.Angles(math.rad(hold.rise), 0, 0)
		c:PivotTo(turn)
		local function reach(p: BasePart?, elbow: Vector3, hand: Vector3)
			if p then
				p.Size = Vector3.new(Viewmodel.ARM.X * 0.8, Viewmodel.ARM.Y * 0.8, (hand - elbow).Magnitude)
				p.CFrame = CFrame.lookAt((hand + elbow) / 2, hand)
			end
		end
		reach(arm, (base * CFrame.new(0.55, -1.25, 0.75)).Position, (turn * CFrame.new(0, 0, -0.12)).Position)
		if support then
			support.Transparency = if hold.both then 0 else 1
			if hold.both then
				reach(support, (base * CFrame.new(-1.15, -1.3, 0.75)).Position, (turn * CFrame.new(0, 0, 0.3)).Position)
			end
		end
		return
	end
	c:PivotTo(at)
	local a = arm
	if a then
		a.CFrame = at * CFrame.new(0.05, -0.2 - Viewmodel.ARM.Y * 0.4, Viewmodel.ARM.Z * 0.55) * CFrame.Angles(math.rad(12), 0, 0)
	end
	local s2 = support
	if s2 then
		local grip = (at * CFrame.new(-0.05, -0.28, -1.05)).Position
		local elbow = (at * CFrame.new(-1.0, -1.0, 0.55)).Position
		local len = (grip - elbow).Magnitude
		s2.Size = Vector3.new(Viewmodel.ARM.X, Viewmodel.ARM.Y, len)
		s2.CFrame = CFrame.lookAt((grip + elbow) / 2, grip)
	end
	local fp, light = flashPart, flash
	if fp and light then
		local muzzle = if tip then tip.Position else (at * CFrame.new(0, 0.1, -2.2)).Position
		fp.CFrame = CFrame.new(muzzle)
		local on = os.clock() < flashUntil
		fp.Transparency = if on then 0.15 else 1
		light.Brightness = if on then 4 else 0
	end
end

-- A touch or pad action button's blow (its press never reaches InputBegan as a click).
function Viewmodel.swing()
	local toy = Toys.byId[toolId or ""]
	if FirstPerson.isOn() and toy and not toy.gun and os.clock() - swingAt > Viewmodel.SWING_TIME then
		swingAt = os.clock()
	end
end

function Viewmodel.start()
	RunService.RenderStepped:Connect(frame)
	table.insert(AmmoClient.onSpent, function(id: string)
		if FirstPerson.isOn() then
			local toy = Toys.byId[id]
			kick = math.min(0.35, kick + (if toy and toy.speed > 60 then Viewmodel.KICK * 1.8 else Viewmodel.KICK))
			flashUntil = os.clock() + 0.05
		end
	end)
	FirstPerson.onChanged(function(on: boolean)
		if not on then
			clear()
		end
	end)
	-- (V10 phase 3: a click with a melee weapon in first person swings it.)
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if processed or not FirstPerson.isOn() then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.KeyCode ~= Enum.KeyCode.ButtonR2 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local toy = Toys.byId[toolId or ""]
		if toy and not toy.gun and not HitMath.charges(toy) and os.clock() - swingAt > Viewmodel.SWING_TIME then
			swingAt = os.clock()
		end
	end)
end

return Viewmodel
