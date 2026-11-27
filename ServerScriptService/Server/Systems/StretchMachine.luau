--!strict
-- StretchMachine (24 Nov 2026, owner): the ragdoll stretching machine, where the ramp behind the cannon stood. A ragdoll
-- put on the platform is locked (the server simulates it from then on), four steel claws take its hands and feet on real
-- springs, and each arm's own winch pulls its limb outward, slowly. The pull is the spring's own: how far it is stretched
-- times its stiffness. Held over BREAK for BREAK_TIME s the joint goes (VitalsService.sever) and the limb falls free.
-- Every force has a ceiling (in the body's own weights), nothing runs while it is empty and nobody is near, and every way
-- out (all off, RELEASE, the body gone, healed or grabbed, everybody left, MAX_TIME) goes through the one release.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared:WaitForChild("Zones"))
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll")) :: any
local Stretch = require(Shared:WaitForChild("Ragdoll"):WaitForChild("Stretch")) :: any -- (F74: limbs grow long, never tear)
local LONG = (require(Shared:WaitForChild("Config")) :: any).STRETCH_LONG == true

local StretchMachine = {}

StretchMachine.STIFF = 40 -- spring stiffness, in the body's mass, per stud
StretchMachine.DAMP = 3 -- in the body's mass
StretchMachine.FORCE_MAX = 200 -- the most one arm pulls, in the body's mass (its weight is 196)
StretchMachine.BREAK = 100 -- the pull a joint gives way at, in the body's mass
StretchMachine.BREAK_TIME = 0.35 -- s over it
StretchMachine.SPEED = 0.8 -- studs/s a winch draws in
StretchMachine.TRAVEL = 6.5 -- studs a claw goes out at most
StretchMachine.HOLD_LONG = 30 -- (F74) s a stretched limb stays at full length after the release
StretchMachine.SHRINK = 10 -- (F74) s it takes to shrink back, eased out
if LONG then
	StretchMachine.TRAVEL = 9.5 -- (F74: a leg can be pulled to about 3x)
end
StretchMachine.HOLD = 1200 -- what holds the trunk, in the body's mass
StretchMachine.LIFT = 4.2 -- studs over the floor the trunk is held at
StretchMachine.REACH = 16 -- studs: the levers answer someone this near
StretchMachine.NEAR = 60 -- studs: it looks for a body only while someone is this near
StretchMachine.MAX_TIME = 90 -- s a body stays in it
StretchMachine.IDLE = 30 -- s with nobody near before it lets go
StretchMachine.PRESS_GAP = 0.25

local DARK = Color3.fromRGB(44, 46, 52)
local STEEL = Color3.fromRGB(150, 154, 162)
local ORANGE = Color3.fromRGB(235, 120, 30)
local RED = Color3.fromRGB(200, 50, 44)
local GREEN = Color3.fromRGB(60, 190, 90)

-- (x, z from the middle: the body lies on its back, its head to -Z; its own left is towards -X... whichever hand is there.)
type ArmSpec = { limb: string, tip: string, x: number, z: number, word: string }
local ARMS: { ArmSpec } = {
	{ limb = "LeftArm", tip = "LeftHand", x = 1, z = -1, word = "Left arm" },
	{ limb = "RightArm", tip = "RightHand", x = -1, z = -1, word = "Right arm" },
	{ limb = "LeftLeg", tip = "LeftFoot", x = 1, z = 1, word = "Left leg" },
	{ limb = "RightLeg", tip = "RightFoot", x = -1, z = 1, word = "Right leg" },
}

type Arm = {
	spec: ArmSpec, palm: BasePart, claw: Attachment, boom: BasePart, cable: BasePart, lamp: BasePart, prompt: ProximityPrompt,
	pulley: Vector3, rest: CFrame, spring: SpringConstraint?, tip: Attachment?, out: Vector3, start: Vector3, gone: number,
	pulling: boolean, over: number, done: boolean,
}
type Machine = {
	model: Model, middle: CFrame, platform: BasePart, post: Attachment, arms: { Arm }, all: ProximityPrompt, free: ProximityPrompt, sound: Sound,
	body: Model?, owner: Player?, bits: { Instance }, since: number, seen: number, severed: number, by: Player?, phase: string, skip: Model?, token: number,
}

local heldAt: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local lastPress: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function between(p: BasePart, a: Vector3, b: Vector3)
	local d = b - a
	local n = math.max(d.Magnitude, 0.05)
	p.Size = Vector3.new(p.Size.X, p.Size.Y, n)
	p.CFrame = CFrame.lookAt(a, if d.Magnitude > 0.01 then b else a + Vector3.zAxis) * CFrame.new(0, 0, -n / 2)
end

local function drawArm(arm: Arm)
	between(arm.boom, arm.pulley, arm.palm.Position)
	between(arm.cable, arm.pulley + Vector3.new(0, 0.6, 0), arm.palm.Position + Vector3.new(0, 0.3, 0))
end

local function setPalm(arm: Arm, at: Vector3)
	arm.palm.CFrame = CFrame.lookAt(at, at + (at - arm.pulley).Unit)
	drawArm(arm)
end

local function words(mc: Machine)
	for _, a in mc.arms do
		local ready = mc.body ~= nil and mc.phase == "Ready" and not a.done
		a.prompt.Enabled = ready
		a.prompt.ActionText = if a.pulling then "Stop" else "Pull"
		a.lamp.Color = if a.done then RED elseif a.pulling then ORANGE elseif ready then GREEN else DARK
	end
	local any = false
	for _, a in mc.arms do
		any = any or a.pulling
	end
	mc.all.Enabled = mc.phase == "Ready"
	mc.all.ActionText = if any then "Stop all" else "Pull all four"
	mc.free.Enabled = mc.body ~= nil
	if any ~= mc.sound.IsPlaying then
		if any then
			mc.sound:Play()
		else
			mc.sound:Stop()
		end
	end
end

local function severedCount(m: Model): number
	local raw = m:GetAttribute("Severed")
	return if type(raw) == "string" and raw ~= "" then #string.split(raw, ",") else 0
end

-- The one way out.
local function release(mc: Machine)
	local m = mc.body
	mc.token += 1
	mc.body = nil
	mc.phase = "Empty"
	for _, b in mc.bits do
		b:Destroy()
	end
	table.clear(mc.bits)
	for _, a in mc.arms do
		a.spring, a.tip, a.pulling, a.done, a.gone, a.over = nil, nil, false, false, 0, 0
		a.palm.CFrame = a.rest
		drawArm(a)
	end
	if m and m.Parent then
		mc.skip = m -- (not again until it has left the platform)
		if LONG and m:GetAttribute("Stretched") == true then
			local token = ((m:GetAttribute("StretchToken") :: number?) or 0) + 1
			m:SetAttribute("StretchToken", token)
			task.spawn(function()
				task.wait(StretchMachine.HOLD_LONG)
				local from: { [string]: number } = {}
				for limb in Stretch.PARTS do
					from[limb] = Stretch.factorOf(m, limb)
				end
				local t0 = os.clock()
				while m.Parent and m:GetAttribute("StretchToken") == token do
					local u = math.clamp((os.clock() - t0) / StretchMachine.SHRINK, 0, 1)
					local e = 1 - (1 - u) * (1 - u) -- (eased out)
					for limb, f0 in from do
						Stretch.setLimb(m, limb, f0 + (1 - f0) * e)
					end
					if u >= 1 then
						Stretch.reset(m)
						break
					end
					task.wait(0.1)
				end
			end)
		end
		ActiveRagdoll.setStayDown(m, false)
		m:SetAttribute("InMachine", nil)
		local back = mc.owner
		if not (back and back.Parent) then
			back = lazy("Lab").ownerAt(mc.middle.Position)
		end
		pcall(function()
			lazy("DummyControl").setOwner(m, back)
		end)
	end
	mc.owner, mc.by = nil, nil
	words(mc)
end

local function lock(mc: Machine, m: Model)
	local control = lazy("DummyControl")
	mc.token += 1
	local mine = mc.token
	mc.body, mc.phase, mc.since, mc.seen = m, "Grab", os.clock(), os.clock()
	mc.severed = severedCount(m)
	m:SetAttribute("InMachine", "Stretch")
	mc.owner = control.ownerOf(m)
	words(mc)
	local ok = pcall(function()
		control.setOwner(m, nil)
	end)
	task.wait(0.25)
	local torso = m:FindFirstChild("UpperTorso")
	if mc.token ~= mine then
		return
	end
	if not ok or not m.Parent or not (torso and torso:IsA("BasePart")) or not ActiveRagdoll.isSimulating(m) then
		release(mc)
		return
	end
	ActiveRagdoll.setState(m, "Ragdoll")
	ActiveRagdoll.setStayDown(m, true)
	local mass = math.clamp((m:GetAttribute("Mass") :: number?) or 10, 1, 200)
	-- The trunk: held over the platform, on its back (real constraints with a ceiling, no teleport).
	local grip = Instance.new("Attachment")
	grip.Name = "StretchGrip"
	grip.Parent = torso
	local pos = Instance.new("AlignPosition")
	pos.Attachment0, pos.Attachment1 = grip, mc.post
	pos.MaxForce = mass * StretchMachine.HOLD
	pos.MaxVelocity = 10
	pos.Responsiveness = 25
	pos.Parent = torso
	local turn = Instance.new("AlignOrientation")
	turn.Attachment0, turn.Attachment1 = grip, mc.post
	turn.MaxTorque = mass * StretchMachine.HOLD
	turn.MaxAngularVelocity = 6
	turn.Responsiveness = 20
	turn.Parent = torso
	mc.bits = { pos, turn, grip }
	task.wait(1.2)
	if mc.token ~= mine or not m.Parent then
		return
	end
	-- The claws go to the limbs, take them, and the springs go on slack.
	for _, a in mc.arms do
		local tip = m:FindFirstChild(a.spec.tip)
		local raw = m:GetAttribute("Severed")
		local off = type(raw) == "string" and string.find("," .. raw .. ",", "," .. a.spec.limb .. ",", 1, true) ~= nil
		a.done = off or not (tip and tip:IsA("BasePart"))
		if not a.done and tip and tip:IsA("BasePart") then
			task.spawn(function()
				local from = a.palm.Position
				for i = 1, 12 do
					if mc.token ~= mine or not tip.Parent then
						return
					end
					setPalm(a, from:Lerp(tip.Position, i / 12))
					task.wait(0.05)
				end
				local at = Instance.new("Attachment")
				at.Name = "StretchTip"
				at.Parent = tip
				local spring = Instance.new("SpringConstraint")
				spring.Name = "StretchSpring"
				spring.Attachment0, spring.Attachment1 = a.claw, at
				spring.Stiffness = mass * StretchMachine.STIFF
				spring.Damping = mass * StretchMachine.DAMP
				spring.MaxForce = mass * StretchMachine.FORCE_MAX
				spring.FreeLength = 0.1
				spring.Visible = true
				spring.Coils, spring.Radius, spring.Thickness = 5, 0.25, 0.08
				spring.Color = BrickColor.new("Dark stone grey")
				spring.Parent = a.palm
				table.insert(mc.bits, spring)
				table.insert(mc.bits, at)
				a.spring, a.tip = spring, at
				a.start = a.palm.Position
				local flat = Vector3.new(a.pulley.X - mc.post.WorldPosition.X, 0, a.pulley.Z - mc.post.WorldPosition.Z)
				a.out = flat.Unit
				a.gone, a.over = 0, 0
			end)
		end
	end
	task.wait(0.8)
	if mc.token == mine and m.Parent then
		mc.phase = "Ready"
		words(mc)
	end
end

local function tear(mc: Machine, a: Arm)
	local m = mc.body
	if not m then
		return
	end
	local wasDead = m:GetAttribute("Vital") == "Dead"
	local tip = m:FindFirstChild(a.spec.tip)
	local at = if tip and tip:IsA("BasePart") then tip.Position else mc.middle.Position
	local ok, cut = pcall(function()
		return lazy("VitalsService").sever(m, a.spec.limb, nil)
	end)
	a.pulling = false
	a.done = true
	if ok and cut then
		mc.severed = severedCount(m)
		pcall(function()
			lazy("FxService").hit(at, 70, "Punch")
		end)
	end
	-- (The claw swings the limb a moment, then opens: it falls by itself.)
	local spring, tipAt = a.spring, a.tip
	a.spring, a.tip = nil, nil
	task.delay(0.6, function()
		if spring then
			spring:Destroy()
		end
		if tipAt then
			tipAt:Destroy()
		end
	end)
	local by = mc.by
	task.delay(0.5, function()
		if not wasDead and m.Parent and m:GetAttribute("Vital") == "Dead" and by and by.Parent then
			pcall(function()
				lazy("ProgressService").addTakedowns(by, 1)
			end)
		end
	end)
	words(mc)
	local left = false
	for _, o in mc.arms do
		left = left or not o.done
	end
	if not left then
		local mine = mc.token
		mc.phase = "Done"
		words(mc)
		task.delay(1.5, function()
			if mc.token == mine then
				release(mc)
			end
		end)
	end
end

-- One step of the winches (20 a second, only with a body in it).
local function pull(mc: Machine, dt: number)
	local m = mc.body :: Model
	local mass = math.clamp((m:GetAttribute("Mass") :: number?) or 10, 1, 200)
	for _, a in mc.arms do
		local spring = a.spring
		if spring and not a.done then
			if a.pulling and a.gone < StretchMachine.TRAVEL then
				a.gone = math.min(StretchMachine.TRAVEL, a.gone + StretchMachine.SPEED * dt)
				setPalm(a, a.start + a.out * a.gone)
			end
			if LONG then
				-- (F74: the limb follows the claw: its length = from the shoulder or hip joint to the claw, over its rest length)
				local leg = string.find(a.spec.limb, "Leg") ~= nil
				local side = if string.sub(a.spec.limb, 1, 4) == "Left" then "Left" else "Right"
				local trunk = m:FindFirstChild(if leg then "LowerTorso" else "UpperTorso")
				local ja = trunk and trunk:FindFirstChild(side .. (if leg then "HipRigAttachment" else "ShoulderRigAttachment"))
				local aa: any = a
				if ja and ja:IsA("Attachment") and os.clock() - (aa.grownAt or 0) > 0.1 then
					aa.grownAt = os.clock()
					local dist = (a.palm.Position - ja.WorldPosition).Magnitude
					if aa.restFor ~= m then
						aa.restFor, aa.rest0 = m, math.max(1, dist / Stretch.factorOf(m, a.spec.limb)) -- (its normal length: stretching again starts from the length it has now)
					end
					local k = dist / aa.rest0
					local got = Stretch.setLimb(m, a.spec.limb, k)
					if got >= Stretch.MAX - 0.01 and a.pulling then
						a.pulling = false -- (MAX: the winch stops)
						words(mc)
					end
				end
				continue
			end
			-- (The spring's own pull, capped as the spring is.)
			local tension = math.min((spring.CurrentLength - spring.FreeLength) * spring.Stiffness, spring.MaxForce)
			a.over = if a.pulling and tension >= mass * StretchMachine.BREAK then a.over + dt else 0
			if a.over >= StretchMachine.BREAK_TIME then
				tear(mc, a)
			end
		end
	end
end

local function someone(mc: Machine, within: number): boolean
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") and (r.Position - mc.middle.Position).Magnitude < within then
			return true
		end
	end
	return false
end

local function onPlatform(mc: Machine, m: Model): boolean
	local p = m:FindFirstChild("LowerTorso")
	if not (p and p:IsA("BasePart")) then
		return false
	end
	local l = mc.middle:PointToObjectSpace(p.Position)
	return math.abs(l.X) < 3.6 and math.abs(l.Z) < 4.6 and l.Y > -1 and l.Y < 7
end

-- A body put there: let go of on the platform, or lying on it (one that only walks across is left alone).
local function look(mc: Machine)
	local now = os.clock()
	local skip = mc.skip
	if skip and (not skip.Parent or not onPlatform(mc, skip)) then
		mc.skip = nil
	end
	local folder = Workspace:FindFirstChild("Dummies")
	for _, m in if folder then folder:GetChildren() else {} do
		if not m:IsA("Model") or m == mc.skip or not onPlatform(mc, m) then
			continue
		end
		if m:GetAttribute("Held") == true then
			heldAt[m] = now
			continue
		end
		local state = m:GetAttribute("RagdollState")
		local put = now - (heldAt[m] or -math.huge) < 4 or state == "Ragdoll" or state == "Out"
		if put and m:GetAttribute("IsDummy") == true and m:GetAttribute("InMachine") == nil and m:GetAttribute("Frozen") ~= true
			and m:GetAttribute("CommandedBy") == nil and lazy("DummyControl").ownerOf(m) ~= nil then
			task.spawn(lock, mc, m)
			return
		end
	end
end

local function run(mc: Machine)
	local acc, scan = 0, 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt)
		if not mc.model.Parent then
			conn:Disconnect()
			if mc.body then
				release(mc)
			end
			return
		end
		acc += dt
		if acc < 0.05 then
			return
		end
		local step = math.min(acc, 0.2)
		acc = 0
		scan += step
		local m = mc.body
		if m then
			if not m.Parent or m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= "Stretch" or severedCount(m) < mc.severed
				or os.clock() - mc.since > StretchMachine.MAX_TIME then
				release(mc) -- (gone, grabbed, healed whole, or too long)
				return
			end
			if mc.phase == "Ready" then
				pull(mc, step)
			end
		end
		if scan >= 0.5 then
			scan = 0
			if mc.body then
				if someone(mc, StretchMachine.NEAR) then
					mc.seen = os.clock()
				elseif os.clock() - mc.seen > StretchMachine.IDLE then
					release(mc)
				end
			elseif someone(mc, StretchMachine.NEAR) then
				look(mc)
			end
		end
	end)
end

function StretchMachine.build(folder: Instance, floor: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "StretchMachine"
	local function part(name: string, size: Vector3, at: CFrame, color: Color3, material: Enum.Material, solid: boolean?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = floor * at
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if solid ~= true then
			p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		end
		p.Parent = model
		return p
	end
	local metal, plate, paint = Enum.Material.Metal, Enum.Material.DiamondPlate, Enum.Material.SmoothPlastic
	part("Base", Vector3.new(17, 0.4, 20), CFrame.new(0, 0.2, 0), DARK, plate, true)
	local platform = part("Platform", Vector3.new(6, 0.5, 8), CFrame.new(0, 0.65, 0), STEEL, plate, true)
	part("PlatformRim", Vector3.new(6.5, 0.3, 8.5), CFrame.new(0, 0.5, 0), ORANGE, paint)
	local post = Instance.new("Attachment")
	post.Name = "Hold"
	-- (The trunk's up (its head) to -Z, its front to the sky.)
	post.CFrame = CFrame.new(0, StretchMachine.LIFT - 0.65, -0.6) * CFrame.fromMatrix(Vector3.zero, Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1))
	post.Parent = platform
	local function prompt(on: BasePart, object: string, action: string, key: Enum.KeyCode): ProximityPrompt
		local p = Instance.new("ProximityPrompt")
		p.ObjectText, p.ActionText = object, action
		p.KeyboardKeyCode = key
		p.MaxActivationDistance = 7
		p.RequiresLineOfSight = false
		p.ClickablePrompt = false
		p.Enabled = false
		p.Parent = on
		return p
	end
	local arms: { Arm } = {}
	for _, spec in ARMS do
		local x, z = spec.x * 7.2, spec.z * 8.2
		part("Post", Vector3.new(1.1, 6.4, 1.1), CFrame.new(x, 3.4, z), DARK, metal, true)
		part("Band", Vector3.new(1.2, 0.4, 1.2), CFrame.new(x, 2.2, z), ORANGE, paint)
		part("Motor", Vector3.new(1.7, 1.3, 1.7), CFrame.new(x, 6.6, z), STEEL, metal)
		local drum = part("Drum", Vector3.new(2, 0.9, 0.9), CFrame.new(x, 5.4, z), ORANGE, metal)
		drum.Shape = Enum.PartType.Cylinder
		local lamp = part("Lamp", Vector3.new(0.5, 0.5, 0.5), CFrame.new(x, 7.5, z), DARK, Enum.Material.Neon)
		lamp.Shape = Enum.PartType.Ball
		local pulley = (floor * CFrame.new(x * 0.94, 5, z * 0.94)).Position
		local rest = floor * CFrame.new(x * 0.62, 4.6, z * 0.62)
		rest = CFrame.lookAt(rest.Position, rest.Position + (rest.Position - pulley).Unit)
		local boom = part("Boom", Vector3.new(0.4, 0.4, 1), CFrame.new(x, 5, z), STEEL, metal)
		local cable = part("Cable", Vector3.new(0.12, 0.12, 1), CFrame.new(x, 5, z), DARK, metal)
		local palm = part("Palm", Vector3.new(0.7, 0.7, 0.5), CFrame.new(x, 5, z), DARK, metal)
		palm.CFrame = rest
		local claw = Instance.new("Attachment")
		claw.Parent = palm
		for f = 0, 2 do
			local finger = part("Finger", Vector3.new(0.18, 0.24, 1), CFrame.new(), STEEL, metal)
			finger.CFrame = rest * CFrame.Angles(0, 0, math.rad(f * 120)) * CFrame.new(0, 0.45, -0.55) * CFrame.Angles(math.rad(-22), 0, 0)
			finger.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = palm, finger
			w.Parent = finger
			finger.Anchored = false
		end
		-- The lever: its own little box on the post, on the outside.
		local lever = part("Lever", Vector3.new(1.5, 1.5, 1.5), CFrame.new(x * 1.08, 3.6, z * 1.06), ORANGE, paint)
		local arm: Arm = {
			spec = spec, palm = palm, claw = claw, boom = boom, cable = cable, lamp = lamp, prompt = prompt(lever, spec.word, "Pull", Enum.KeyCode.E),
			pulley = pulley, rest = rest, spring = nil, tip = nil, out = Vector3.zAxis, start = rest.Position, gone = 0, pulling = false, over = 0, done = false,
		}
		drawArm(arm)
		table.insert(arms, arm)
	end
	-- The frame between the posts, and the control panel at the front (towards -Z... the spawn side).
	for _, s in { -1, 1 } do
		part("RailSide", Vector3.new(0.5, 0.5, 16.4), CFrame.new(s * 7.2, 6.2, 0), STEEL, metal)
		part("RailEnd", Vector3.new(14.4, 0.5, 0.5), CFrame.new(0, 6.2, s * 8.2), STEEL, metal)
	end
	part("PanelFoot", Vector3.new(1.2, 2.6, 0.8), CFrame.new(0, 1.7, -8.6), DARK, metal, true)
	part("Panel", Vector3.new(3.2, 1.8, 0.4), CFrame.new(0, 3.4, -8.7) * CFrame.Angles(math.rad(20), 0, 0), STEEL, metal, true)
	local green = part("PanelGreen", Vector3.new(1, 1, 0.5), CFrame.new(-0.7, 3.4, -8.95), GREEN, paint)
	local red = part("PanelRed", Vector3.new(1, 1, 0.5), CFrame.new(0.7, 3.4, -8.95), RED, paint)
	local all = prompt(green, "Stretch machine", "Pull all four", Enum.KeyCode.E)
	local free = prompt(red, "Stretch machine", "Release", Enum.KeyCode.E)
	free.GamepadKeyCode = Enum.KeyCode.ButtonY
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9118773057" -- (PSE motor whine and hum; was a body-fall thud on a loop)
	sound.Looped = true
	sound.Volume = 0.35
	sound.PlaybackSpeed = 0.4
	sound.RollOffMaxDistance = 80
	sound.Parent = platform
	local mc: Machine = {
		model = model, middle = floor, platform = platform, post = post, arms = arms, all = all, free = free, sound = sound, body = nil, owner = nil,
		bits = {}, since = 0, seen = 0, severed = 0, by = nil, phase = "Empty", skip = nil, token = 0,
	}
	local function may(player: Player): boolean
		local now = os.clock()
		if now - (lastPress[player] or -math.huge) < StretchMachine.PRESS_GAP then
			return false
		end
		lastPress[player] = now
		local c = player.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		return r ~= nil and r:IsA("BasePart") and (r.Position - floor.Position).Magnitude < StretchMachine.REACH
			and Zones.mayEnter(player, Zones.plotAt(floor.Position))
	end
	for _, a in arms do
		a.prompt.Triggered:Connect(function(player)
			if may(player) and mc.phase == "Ready" and not a.done then
				a.pulling = not a.pulling
				mc.by = player
				words(mc)
			end
		end)
	end
	all.Triggered:Connect(function(player)
		if not may(player) or mc.phase ~= "Ready" then
			return
		end
		local any = false
		for _, a in arms do
			any = any or a.pulling
		end
		for _, a in arms do
			a.pulling = not any and not a.done
		end
		mc.by = player
		words(mc)
	end)
	free.Triggered:Connect(function(player)
		if may(player) and mc.body then
			release(mc)
		end
	end)
	words(mc)
	model.Parent = folder
	run(mc)
	return model
end

return StretchMachine
