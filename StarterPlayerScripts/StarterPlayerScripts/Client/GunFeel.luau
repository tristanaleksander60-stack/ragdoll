--!strict
-- Round 5, phase 2b: how each gun feels in the hand, on this screen (the server does the rounds:
-- WeaponMechanics; every shot here still goes through PokeController and its checks).
--   AK          climbing recoil: quick rounds in a row land higher and wider
--   LMG         wide while you move, tight standing still; SMG and Tommy a light spray
--   Revolver    fanning the hammer: quick clicks throw the rounds wide
--   M4          full auto (Dec 2026: was 3-round burst, now hold-to-fire like the other auto rifles)
--   Minigun     spins up before it fires (a whine), spins down after
--   Railgun     charges first (a ring fills at the crosshair, a rising hum), then fires
--   Sniper, DMR zoom: hold the right mouse button (a ZOOM button on touch: TouchShoot)
--   LaserRifle  a red beam from the muzzle to where it lands, while firing
--   DoubleBarrel both barrels kick you back
--   GoldenDeagle gold sparks on a head shot (the server's Fx "GoldSpark": FxController)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys"))

local Client = script.Parent
local FxController = require(Client:WaitForChild("FxController"))
local AmmoClient = require(Client:WaitForChild("AmmoClient"))

local GunFeel = {}

-- M4 was a 3-round burst in round 5; Dec 2026 made it fully automatic to match the other rifles
-- (the owner: "m4 and tommy are automatic weapons"). BURST and BURST_GAP are kept at zero only so a
-- test or external caller cannot blow up on a missing field.
GunFeel.BURST = 1
GunFeel.BURST_GAP = 0
GunFeel.SPIN_UP = 0.45
GunFeel.SPIN_KEEP = 0.6 -- s without a round before the barrels spin down
GunFeel.CHARGE = 0.75
GunFeel.ZOOM = { Sniper = -48, DMR = -32 } :: { [string]: number }

-- Set by PokeController: fires the picked gun at a screen point (its whole path and checks).
GunFeel.refire = nil :: ((at: Vector2) -> ())?
GunFeel.getSelected = nil :: (() -> string)?

local player = Players.LocalPlayer
local rng = Random.new()
local lastShot: { [string]: number } = {}
local streak: { [string]: number } = {}
local spinReadyAt: number? = nil
local lastMinigun = -math.huge
local charging = false
local chargeReadyUntil = 0
local zoomed = false
local zoomToggle = false
local ringGui: ScreenGui? = nil
local ring: Frame? = nil
local ringGrad: UIGradient? = nil

local function moving(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
end

-- Where a gun's round goes from where you aimed (screen px).
function GunFeel.aim(toy: Toys.Toy, at: Vector2): Vector2
	if not toy.gun then
		return at
	end
	local now = os.clock()
	local id = toy.id
	local quick = now - (lastShot[id] or -math.huge) < 0.35
	local s = if quick then streak[id] or 0 else 0
	local function jitter(px: number): Vector2
		return Vector2.new(rng:NextNumber(-px, px), rng:NextNumber(-px, px))
	end
	if id == "AK" then
		return at + Vector2.new(rng:NextNumber(-s, s) * 1.5, -math.min(s, 10) * 6)
	elseif id == "LMG" then
		return at + jitter(if moving() then 30 else 6)
	elseif id == "SMG" or id == "TommyGun" then
		return at + jitter(12)
	elseif id == "Minigun" then
		return at + jitter(10)
	elseif id == "Revolver" and quick then
		return at + jitter(24) -- (fanning the hammer)
	end
	return at
end

-- Whether a gun may fire now (spin-up for the minigun, charge for the railgun). May start what it
-- waits for. Dec 2026: the M4 is fully automatic (no burst, no pause).
function GunFeel.ready(toy: Toys.Toy, at: Vector2): boolean
	local now = os.clock()
	if toy.id == "Minigun" then
		if spinReadyAt == nil or now - lastMinigun > GunFeel.SPIN_KEEP then
			spinReadyAt = now + GunFeel.SPIN_UP
			lastMinigun = now
			FxController.reload("Minigun", GunFeel.SPIN_UP) -- (the barrels winding up)
			return false
		end
		lastMinigun = now
		return now >= (spinReadyAt :: number)
	elseif toy.id == "Railgun" then
		if now < chargeReadyUntil then
			chargeReadyUntil = 0
			return true
		end
		if not charging then
			GunFeel.charge(at)
		end
		return false
	end
	return true
end

-- The railgun's charge: a ring fills at the crosshair, then the shot goes where you aim then.
function GunFeel.charge(at: Vector2)
	charging = true
	local started = os.clock()
	FxController.reload("Railgun", GunFeel.CHARGE)
	task.spawn(function()
		while os.clock() - started < GunFeel.CHARGE do
			local r, g = ring, ringGrad
			if r and g then
				r.Visible = true
				r.Position = UDim2.fromOffset(at.X, at.Y)
				local p = math.clamp((os.clock() - started) / GunFeel.CHARGE, 0.001, 0.999)
				g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(p, 0), NumberSequenceKeypoint.new(math.min(p + 0.001, 1), 1), NumberSequenceKeypoint.new(1, 1) })
			end
			RunService.RenderStepped:Wait()
		end
		if ring then
			ring.Visible = false
		end
		charging = false
		chargeReadyUntil = os.clock() + 0.3
		local fire = GunFeel.refire
		local id = GunFeel.getSelected and GunFeel.getSelected()
		if fire and id == "Railgun" then
			-- (A moved mouse: the shot goes where it points now.)
			local camera = Workspace.CurrentCamera
			local now = if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and camera then camera.ViewportSize / 2
				elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then at
				else UserInputService:GetMouseLocation()
			fire(now)
		end
	end)
end

-- A beam from the muzzle to where a laser round landed.
local function beam(to: Vector3)
	local character = player.Character
	local held = character and character:FindFirstChild("HeldTool")
	local tip = held and held:FindFirstChild("Tip", true)
	local from = if tip and tip:IsA("BasePart") then tip.Position else nil
	if not from then
		local head = character and character:FindFirstChild("Head")
		from = if head and head:IsA("BasePart") then head.Position else nil
	end
	if not from then
		return
	end
	local length = (to - from).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 50, 60)
	p.Size = Vector3.new(0.12, 0.12, length)
	p.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	p.Parent = Workspace:FindFirstChild("LocalFx") or Workspace
	task.delay(0.13, function()
		p:Destroy()
	end)
end

-- A round of `toy` went out towards screen point `at` (PokeController, after the remote).
function GunFeel.fired(toy: Toys.Toy, at: Vector2)
	local now = os.clock()
	local id = toy.id
	streak[id] = if now - (lastShot[id] or -math.huge) < 0.35 then (streak[id] or 0) + 1 else 1
	lastShot[id] = now
	if id == "DoubleBarrel" then
		-- Both barrels: the shooter is thrown back a step.
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local camera = Workspace.CurrentCamera
			local back = if camera then -camera.CFrame.LookVector else -root.CFrame.LookVector
			root.AssemblyLinearVelocity += Vector3.new(back.X, 0, back.Z).Unit * 38 + Vector3.new(0, 10, 0)
		end
	elseif id == "LaserRifle" then
		local camera = Workspace.CurrentCamera
		if camera then
			local ray = camera:ViewportPointToRay(at.X, at.Y)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = if player.Character then { player.Character } else {}
			local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
			beam(if hit then hit.Position else ray.Origin + ray.Direction * 200)
		end
	end
end

-- Zoom: Sniper and DMR, the right mouse button held (or the touch ZOOM toggle).
function GunFeel.setZoomToggle(on: boolean)
	zoomToggle = on
end
function GunFeel.zoomed(): boolean
	return zoomed
end

function GunFeel.start()
	local g = Instance.new("ScreenGui")
	g.Name = "GunFeel"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 8
	local r = Instance.new("Frame")
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Size = UDim2.fromOffset(38, 38)
	r.BackgroundTransparency = 1
	r.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = r
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Color = Color3.fromRGB(80, 210, 255)
	s.Parent = r
	local grad = Instance.new("UIGradient")
	grad.Rotation = -90
	grad.Parent = s
	r.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	ringGui, ring, ringGrad = g, r, grad
	RunService.RenderStepped:Connect(function()
		local id = GunFeel.getSelected and GunFeel.getSelected() or ""
		local want = GunFeel.ZOOM[id]
		local held = want ~= nil and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or zoomToggle)
		zoomed = held
		local target = if held and want then want else 0
		FxController.fovZoom += (target - FxController.fovZoom) * 0.25
		if math.abs(FxController.fovZoom) < 0.05 then
			FxController.fovZoom = 0
		end
		if not want then
			zoomToggle = false
		end
		-- The minigun's barrels winding down a moment after the last round.
		if spinReadyAt and os.clock() - lastMinigun > GunFeel.SPIN_KEEP then
			spinReadyAt = nil
		end
	end)
end

return GunFeel
