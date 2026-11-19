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

local Client = script.Parent
local FirstPerson = require(Client:WaitForChild("FirstPerson"))
local AmmoClient = require(Client:WaitForChild("AmmoClient"))

local Viewmodel = {}

Viewmodel.OFFSET = CFrame.new(0.85, -0.75, -2.1) -- where the grip sits from the camera
Viewmodel.SCALE = 0.55 -- the copy's size against the one in the hand
Viewmodel.KICK = 0.14 -- studs back a round throws it
Viewmodel.SWAY = 0.06

local player = Players.LocalPlayer
local holder: Model? = nil
local shownTool: Model? = nil
local copy: Model? = nil
local arm: BasePart? = nil
local tip: BasePart? = nil
local kick = 0
local sway = Vector2.zero
local lastLook: Vector3? = nil
local flash: PointLight? = nil
local flashPart: BasePart? = nil
local flashUntil = 0
local toolId = ""

local function clear()
	if holder then
		holder:Destroy()
	end
	holder, copy, arm, tip, flash, flashPart, shownTool = nil, nil, nil, nil, nil, nil, nil
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
	local a = Instance.new("Part")
	a.Name = "Forearm"
	a.Size = Vector3.new(0.26, 0.26, 1.1)
	a.Color = skin
	a.Material = Enum.Material.SmoothPlastic
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.CanTouch = false
	a.CastShadow = false
	a.Parent = h
	arm = a
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
	kick = math.max(0, kick - dt * 1.4)
	-- Reloading: the weapon dips and tilts.
	local reload = Ammo.reloading(AmmoClient.bookForTest(), toolId, os.clock())
	local dip = if reload then math.sin(reload * math.pi) else 0
	local bob = math.sin(os.clock() * 2) * 0.015
	local at = camera.CFrame
		* Viewmodel.OFFSET
		* CFrame.new(sway.X * Viewmodel.SWAY, sway.Y * Viewmodel.SWAY - dip * 0.45 + bob, kick)
		* CFrame.Angles(kick * 0.9 + dip * -0.5, 0, dip * 0.6)
	c:PivotTo(at)
	local a = arm
	if a then
		a.CFrame = at * CFrame.new(0.05, -0.2, 0.6) * CFrame.Angles(math.rad(12), 0, 0)
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
end

return Viewmodel
