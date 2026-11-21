--!strict
-- V9-NOW 23 (owner, 21 Nov 2026: "a bow on the start bar"): the Bow on this screen.
--   * Hold to draw (the mouse button, SHOOT on a phone, RT on a pad: whatever pressed the Bow), let go to shoot.
--     The string goes back while you hold (a creak), a small meter under the crosshair fills to full draw
--     (BowMath.FULL_DRAW s); held at full draw past WOBBLE_AFTER s the aim starts to wobble.
--   * The arrow is a real arc with gravity (BowMath): a short draw lobs it soft and high, a full draw sends it
--     hard, fast and flat. It flies on this screen; where it lands decides the shot: a body part -> HitRequest
--     (with the draw; the server caps it by the time it was held), anything else -> Shot. Your own dummy reacts
--     at once (as every gun's round does here: PokeController).
--   * A tap too short drops the arrow at your feet. Arrows stick where they land (welded to the limb), and
--     fade: a few seconds in the world, a little longer in a body; at most MAX_ARROWS of yours at once.
--   * Sounds: the creak, the twang, the arrow's whoosh-and-thunk where it lands (Pro Sound Effects).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BowMath = require(Shared:WaitForChild("BowMath"))
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local HitMath = require(Shared:WaitForChild("HitMath"))
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll"))

local Client = script.Parent

local BowClient = {}

BowClient.MAX_ARROWS = 12
BowClient.WORLD_STAY = 6 -- s an arrow stays in a wall or the floor
BowClient.BODY_STAY = 10 -- s in a body
BowClient.SOUNDS = table.freeze({
	creak = "rbxassetid://9120431111", -- (PSE "Violin Rasp Muted Strings 5", slowed: a string pulled back)
	twang = "rbxassetid://9114000974", -- (PSE "Crossbow Fire 5", a little higher: the string let go)
	hit = "rbxassetid://9113160396", -- (PSE "Arrow In And Hit 4": the whoosh and the thunk)
})

local player = Players.LocalPlayer
type Draw = { start: number, at: Vector2, creak: Sound? }
local drawing: Draw? = nil
local arrows: { BasePart } = {}
local meter: Frame? = nil
local fill: Frame? = nil

local function sound(id: string, parent: Instance, volume: number, pitch: number, looped: boolean?): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.Looped = looped == true
	s.RollOffMaxDistance = 90
	s.Parent = parent
	s:Play()
	if not looped then
		s.Ended:Once(function()
			s:Destroy()
		end)
		task.delay(6, function()
			if s.Parent then
				s:Destroy()
			end
		end)
	end
	return s
end

local function root(): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

-- The held bow's string and its tip (HeldService puts the model on the hand), if any.
local function heldBow(): (BasePart?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local str = character:FindFirstChild("BowString", true)
	local tip = nil
	for _, d in character:GetDescendants() do
		if d.Name == "Tip" and d:IsA("BasePart") and d.Parent and d.Parent:FindFirstChild("Body") and d.Parent.Body:FindFirstChild("BowString") then
			tip = d
			break
		end
	end
	return if str and str:IsA("BasePart") then str else nil, tip
end

local stringRest: { [BasePart]: CFrame } = {}
local function pullString(draw: number)
	local str = heldBow()
	if not str then
		return
	end
	-- (The string hangs on its Weld to the grip, like every piece of a held weapon: its C0 moves back on this screen.)
	local w = str:FindFirstChildWhichIsA("Weld")
	if not w then
		return
	end
	local rest = stringRest[str]
	if not rest then
		rest = w.C0
		stringRest[str] = rest
	end
	w.C0 = rest * CFrame.new(0, 0, 0.9 * draw) -- (back towards the archer: the bow's +Z)
end

local function buildMeter()
	if meter then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "BowMeter"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 9
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Size = UDim2.fromOffset(90, 8)
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	frame.BackgroundTransparency = 0.25
	frame.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = frame
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(0, 1)
	f.BackgroundColor3 = Color3.fromRGB(255, 205, 80)
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, 4)
	c2.Parent = f
	f.Parent = frame
	frame.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	meter, fill = frame, f
end

-- The arrow, built on this screen: a shaft, a head and three vanes.
local function makeArrow(): BasePart
	local shaft = Instance.new("Part")
	shaft.Name = "Arrow"
	shaft.Size = Vector3.new(0.08, 0.08, 2.4)
	shaft.Color = Color3.fromRGB(150, 110, 70)
	shaft.Material = Enum.Material.Wood
	shaft.Anchored = true
	shaft.CanCollide, shaft.CanQuery, shaft.CanTouch, shaft.CastShadow = false, false, false, false
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, false, true
		p.CFrame = shaft.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = shaft
		w.Part1 = p
		w.Parent = p
		p.Parent = shaft
	end
	piece("ArrowHead", Vector3.new(0.14, 0.14, 0.3), CFrame.new(0, 0, -1.3), Color3.fromRGB(80, 84, 92), Enum.Material.Metal)
	for i = 0, 2 do
		piece("Vane", Vector3.new(0.02, 0.22, 0.4), CFrame.new(0, 0, 1.0) * CFrame.Angles(0, 0, math.rad(120 * i)) * CFrame.new(0, 0.11, 0), Color3.fromRGB(230, 70, 60), Enum.Material.SmoothPlastic)
	end
	return shaft
end

local function keep(arrow: BasePart, stay: number)
	table.insert(arrows, arrow)
	while #arrows > BowClient.MAX_ARROWS do
		local old = table.remove(arrows, 1) :: BasePart
		old:Destroy()
	end
	task.delay(stay, function()
		if arrow.Parent then
			for _, p in arrow:GetDescendants() do
				if p:IsA("BasePart") then
					TweenService:Create(p, TweenInfo.new(0.6), { Transparency = 1 }):Play()
				end
			end
			local t = TweenService:Create(arrow, TweenInfo.new(0.6), { Transparency = 1 })
			t.Completed:Once(function()
				arrow:Destroy()
			end)
			t:Play()
		end
		local i = table.find(arrows, arrow)
		if i then
			table.remove(arrows, i)
		end
	end)
end

local function bodyOf(part: Instance): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	local node: Instance? = part
	while node and node.Parent ~= dummies do
		node = node.Parent
	end
	return if node and dummies and node:IsA("Model") then node else nil
end

-- Flies one arrow from `from` with velocity `v`; on landing, the shot (or the hit) and the arrow stuck there.
local function fly(from: Vector3, v: Vector3, draw: number)
	local arrow = makeArrow()
	arrow.CFrame = CFrame.lookAt(from, from + v)
	arrow.Parent = Workspace
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance, arrow, Workspace.CurrentCamera :: Instance }
	local t, last = 0, from
	local conn: RBXScriptConnection? = nil
	conn = RunService.Heartbeat:Connect(function(dt)
		t += dt
		local now = BowMath.at(from, v, t)
		local hit = Workspace:Raycast(last, now - last, params)
		local vel = v + Vector3.new(0, -BowMath.GRAVITY * t, 0)
		if hit or t >= BowMath.FLY_MAX then
			if conn then
				conn:Disconnect()
			end
			local at = if hit then hit.Position else now
			arrow.CFrame = CFrame.lookAt(at - vel.Unit * 0.9, at)
			if not hit then
				arrow:Destroy()
				return
			end
			sound(BowClient.SOUNDS.hit, arrow, 0.7, 1.05)
			local part = hit.Instance
			local body = bodyOf(part)
			if body and part:IsA("BasePart") then
				-- Stuck in the limb, moving with it.
				arrow.Anchored = false
				arrow.Massless = true
				local w = Instance.new("WeldConstraint")
				w.Part0 = part
				w.Part1 = arrow
				w.Parent = arrow
				keep(arrow, BowClient.BODY_STAY)
				-- Your own dummy reacts now (the server checks and wounds it: HitService).
				local DummySim = require(Client:WaitForChild("DummySim")) :: any
				local simulated = DummySim.simulatedDummyOf(part)
				local toy = Toys.byId.Bow
				if simulated and toy then
					local mass = (simulated:GetAttribute("Mass") :: number?) or 10
					ActiveRagdoll.ownHit = true
					pcall(ActiveRagdoll.hit, simulated, part, HitMath.toyImpulse(toy, vel.Unit, mass) * BowMath.pushScale(draw), at, nil, HitMath.gunOf(toy))
					ActiveRagdoll.ownHit = false
				end
				pcall(function()
					(require(Client:WaitForChild("HospitalCharts")) :: any).ownHit(body)
				end)
				Net.event(Net.Names.HitRequest):FireServer(part, at, vel.Unit, "Bow", false, draw)
			else
				keep(arrow, BowClient.WORLD_STAY)
				Net.event(Net.Names.Shot):FireServer(at, "Bow", draw)
			end
			return
		end
		arrow.CFrame = CFrame.lookAt(now, now + vel)
		last = now
	end)
end

-- Whether the Bow is drawn now.
function BowClient.isDrawing(): boolean
	return drawing ~= nil
end

-- The string goes back (called by PokeController when the Bow is pressed, from any input).
function BowClient.begin(at: Vector2): boolean
	if drawing then
		return true
	end
	local r = root()
	if not r then
		return false
	end
	buildMeter()
	drawing = { start = os.clock(), at = at, creak = sound(BowClient.SOUNDS.creak, r, 0.25, 0.55, true) }
	Net.event(Net.Names.Ammo):FireServer("Draw", "Bow")
	return true
end

-- Let go: the arrow flies (or drops at your feet after a tap too short).
function BowClient.release()
	local d = drawing
	if not d then
		return
	end
	drawing = nil
	if d.creak then
		d.creak:Destroy()
	end
	pullString(0)
	local m = meter
	if m then
		m.Visible = false
	end
	local r = root()
	if not r then
		return
	end
	local held = os.clock() - d.start
	local draw = BowMath.drawOf(held)
	local _, tip = heldBow()
	local from = if tip then tip.Position else r.Position + r.CFrame.LookVector * 1.5 + Vector3.new(0, 1.2, 0)
	if draw < BowMath.MIN_DRAW then
		-- (Too short: the arrow slips off the string and drops at your feet.)
		fly(from, r.CFrame.LookVector * 6 + Vector3.new(0, 2, 0), 0)
		return
	end
	-- Aim: where the camera's line through the pointer (a mouse) or the screen's middle meets the world.
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local mouse = UserInputService.MouseEnabled and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch
		and not string.find(UserInputService:GetLastInputType().Name, "Gamepad", 1, true)
	local screen = if mouse then UserInputService:GetMouseLocation() else camera.ViewportSize / 2
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	local target = if hit then hit.Position else ray.Origin + ray.Direction * 400
	local aim = target - from
	-- (Held at full draw too long: the arms tire and the aim wobbles a little.)
	if held > BowMath.FULL_DRAW + BowMath.WOBBLE_AFTER then
		local k = math.rad(BowMath.WOBBLE_DEG)
		aim = CFrame.Angles((math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k, 0):VectorToWorldSpace(aim)
	end
	local v = BowMath.launch(aim, draw)
	sound(BowClient.SOUNDS.twang, r, 0.8, 1.15 + 0.1 * draw)
	pcall(function() -- (the soft kick on let-go: Config.RECOIL.Bow)
		(require(Client:WaitForChild("FeelV2")) :: any).kick("Bow")
	end)
	fly(from, v, draw)
end

function BowClient.start()
	RunService.RenderStepped:Connect(function()
		local d = drawing
		if not d then
			return
		end
		local held = os.clock() - d.start
		local draw = BowMath.drawOf(held)
		pullString(draw)
		local m, f = meter, fill
		local camera = Workspace.CurrentCamera
		if m and f and camera then
			m.Visible = true
			m.Position = UDim2.fromOffset(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2 + 34)
			f.Size = UDim2.fromScale(draw, 1)
			f.BackgroundColor3 = if draw >= 1 then Color3.fromRGB(255, 120, 60) else Color3.fromRGB(255, 205, 80)
		end
	end)
	-- Whatever pressed the Bow, letting go of it shoots: a mouse button, a finger, RT.
	UserInputService.InputEnded:Connect(function(input)
		if not drawing then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonR2 then
			BowClient.release()
		end
	end)
	-- (Put away, dead or switched off the Bow mid-draw: no arrow.)
	player.CharacterRemoving:Connect(function()
		local d = drawing
		drawing = nil
		if d and d.creak then
			d.creak:Destroy()
		end
	end)
end

return BowClient
