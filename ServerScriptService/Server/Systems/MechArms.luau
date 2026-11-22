--!strict
-- MechArms (23 Nov 2026, owner: "the wild mechanical arms standing at the spawn, press E to equip, they hang on your
-- back and you can pull ragdolls apart with them"). Our own design (a graphite backpack with four jointed steel
-- arms, orange bands and three-finger claws), not any film's. Each lab has a stand by the spawn with a display set
-- and a prompt: E puts a set on your back (E again takes it off). The arms are parts on Motor6D joints in your
-- character (massless, no collision); Client/MechArmsClient moves them on every screen (idle sway, and a reach
-- when they tear). Q (or the TEAR button on touch) asks to tear: the server checks you wear them, the body is a
-- lab dummy within REACH in a lab you may use, and the pace; then the next piece comes off (arms, legs, the head,
-- then in half: VitalsService.sever), every screen sees the arms reach, and a kill is a takedown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared:WaitForChild("Zones"))

local MechArms = {}

MechArms.REACH = 16 -- studs from your middle to the body's
MechArms.GAP = 0.7 -- s between two tears
MechArms.ORDER = { "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Head", "Waist" }
MechArms.STAND_ANGLE = -35 -- degrees from the spawn's facing (left)
MechArms.STAND_DISTANCE = 12
MechArms.STAND_SIDE = 8 -- studs beside the LIKE GOAL post

local GRAPHITE = Color3.fromRGB(46, 48, 54)
local STEEL = Color3.fromRGB(168, 172, 180)
local ORANGE = Color3.fromRGB(235, 120, 30)

local remote: RemoteEvent? = nil
local lastTear: { [Player]: number } = {}

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function event(): RemoteEvent
	local r = remote
	if r and r.Parent then
		return r
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10) -- (23 Nov 2026: it was made before the Remotes folder, so the client never found it)
	local made = (remotes and remotes:FindFirstChild("MechArms")) :: RemoteEvent?
	if not made then
		local e = Instance.new("RemoteEvent")
		e.Name = "MechArms"
		e.Parent = remotes or ReplicatedStorage
		made = e
	end
	remote = made
	return made :: RemoteEvent
end

local function part(name: string, size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Metal
	if shape then
		p.Shape = shape
	end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	return p
end

-- One set: a backpack (the root, "Pack") and four arms. Each arm: Upper on a Motor6D "Shoulder<i>" from the pack,
-- Lower on a Motor6D "Elbow<i>" from Upper, a claw welded to Lower. The arm points along its parts' -Y at rest.
-- `anchored`: a display set on the stand.
function MechArms.build(anchored: boolean): Model
	local m = Instance.new("Model")
	m.Name = "MechArms"
	local pack = part("Pack", Vector3.new(1.6, 1.9, 0.7), GRAPHITE)
	pack.Anchored = anchored
	pack.Parent = m
	m.PrimaryPart = pack
	local band = part("Band", Vector3.new(1.65, 0.22, 0.75), ORANGE, Enum.Material.SmoothPlastic)
	band.CFrame = pack.CFrame * CFrame.new(0, 0.45, 0)
	band.Parent = m
	local w0 = Instance.new("WeldConstraint")
	w0.Part0, w0.Part1 = pack, band
	w0.Parent = band
	-- Shoulders: upper pair out and up over the shoulders, lower pair out to the sides.
	local SHOULDERS = {
		{ at = Vector3.new(-0.6, 0.6, 0.4), aim = CFrame.Angles(0, 0, math.rad(-140)) * CFrame.Angles(math.rad(-25), 0, 0) },
		{ at = Vector3.new(0.6, 0.6, 0.4), aim = CFrame.Angles(0, 0, math.rad(140)) * CFrame.Angles(math.rad(-25), 0, 0) },
		{ at = Vector3.new(-0.6, -0.5, 0.4), aim = CFrame.Angles(0, 0, math.rad(-65)) * CFrame.Angles(math.rad(-20), 0, 0) },
		{ at = Vector3.new(0.6, -0.5, 0.4), aim = CFrame.Angles(0, 0, math.rad(65)) * CFrame.Angles(math.rad(-20), 0, 0) },
	}
	for i, s in SHOULDERS do
		local joint = part("Joint" .. i, Vector3.one * 0.55, GRAPHITE, Enum.Material.Metal, Enum.PartType.Ball)
		joint.Parent = m
		local jw = Instance.new("Weld")
		jw.Part0, jw.Part1 = pack, joint
		jw.C0 = CFrame.new(s.at)
		jw.Parent = joint
		local upper = part("Upper" .. i, Vector3.new(0.32, 3.2, 0.32), STEEL)
		upper.Parent = m
		local sm = Instance.new("Motor6D")
		sm.Name = "Shoulder" .. i
		sm.Part0, sm.Part1 = pack, upper
		sm.C0 = CFrame.new(s.at) * s.aim
		sm.C1 = CFrame.new(0, 1.6, 0)
		sm.Parent = pack
		local stripe = part("Stripe" .. i, Vector3.new(0.36, 0.5, 0.36), ORANGE, Enum.Material.SmoothPlastic)
		stripe.Parent = m
		local sw = Instance.new("Weld")
		sw.Part0, sw.Part1 = upper, stripe
		sw.C0 = CFrame.new(0, 0.6, 0)
		sw.Parent = stripe
		local knee = part("Knee" .. i, Vector3.one * 0.45, GRAPHITE, Enum.Material.Metal, Enum.PartType.Ball)
		knee.Parent = m
		local kw = Instance.new("Weld")
		kw.Part0, kw.Part1 = upper, knee
		kw.C0 = CFrame.new(0, -1.6, 0)
		kw.Parent = knee
		local lower = part("Lower" .. i, Vector3.new(0.26, 3.6, 0.26), STEEL)
		lower.Parent = m
		local em = Instance.new("Motor6D")
		em.Name = "Elbow" .. i
		em.Part0, em.Part1 = upper, lower
		em.C0 = CFrame.new(0, -1.6, 0) * CFrame.Angles(math.rad(if i <= 2 then 70 else 40), 0, 0)
		em.C1 = CFrame.new(0, 1.8, 0)
		em.Parent = upper
		-- The claw: three steel fingers round a graphite palm at the tip.
		local palm = part("Palm" .. i, Vector3.new(0.4, 0.35, 0.4), GRAPHITE)
		palm.Parent = m
		local pw = Instance.new("Weld")
		pw.Part0, pw.Part1 = lower, palm
		pw.C0 = CFrame.new(0, -1.9, 0)
		pw.Parent = palm
		for f = 0, 2 do
			local finger = part("Finger" .. i .. "_" .. f, Vector3.new(0.1, 0.75, 0.12), STEEL)
			finger.Parent = m
			local fw = Instance.new("Weld")
			fw.Part0, fw.Part1 = palm, finger
			fw.C0 = CFrame.Angles(0, math.rad(f * 120), 0) * CFrame.new(0, -0.4, 0.17) * CFrame.Angles(math.rad(-22), 0, 0)
			fw.Parent = finger
		end
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = anchored and d == pack
		end
	end
	return m
end

local function attach(player: Player)
	local character = player.Character
	local torso = character and character:FindFirstChild("UpperTorso")
	if not (character and torso and torso:IsA("BasePart")) then
		return
	end
	local old = character:FindFirstChild("MechArms")
	if old then
		old:Destroy()
	end
	local m = MechArms.build(false)
	local pack = m.PrimaryPart :: BasePart
	pack.CFrame = torso.CFrame * CFrame.new(0, 0.1, torso.Size.Z / 2 + 0.35)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = torso, pack
	w.C0 = CFrame.new(0, 0.1, torso.Size.Z / 2 + 0.35)
	w.Parent = pack
	m.Parent = character
end

local function detach(player: Player)
	local character = player.Character
	local m = character and character:FindFirstChild("MechArms")
	if m then
		m:Destroy()
	end
end

function MechArms.toggle(player: Player)
	if player:GetAttribute("MechArms") == true then
		player:SetAttribute("MechArms", nil)
		detach(player)
	else
		player:SetAttribute("MechArms", true)
		attach(player)
	end
end

local function floorAt(at: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), params)
	return if hit then hit.Position else at
end

-- The stand by a lab's spawn: a round plinth, a short post with the display set on it, and the prompt.
function MechArms.buildStand(folder: Instance, origin: Vector3)
	-- (23 Nov 2026, owner: "move the stand out to the side, next to the like goal"): beside Playground's LIKE GOAL
	-- post (at -24, 18 times the lab spread), on the same line, facing the spawn the same way.
	local S = (require(Shared:WaitForChild("Config")) :: any).LAB_SPREAD or 1
	local post0 = origin + Vector3.new(-24 * S, 0, 18 * S)
	local toMid = Vector3.new(origin.X - post0.X, 0, origin.Z - post0.Z)
	local side = if toMid.Magnitude > 0.1 then toMid.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
	local ground = floorAt(post0 + side * MechArms.STAND_SIDE)
	local dir = if toMid.Magnitude > 0.1 then -toMid.Unit else Vector3.zAxis
	local m = Instance.new("Model")
	m.Name = "MechArmsStand"
	local base = part("Plinth", Vector3.new(1, 5, 5), GRAPHITE, Enum.Material.Metal, Enum.PartType.Cylinder)
	base.Anchored, base.CanCollide, base.CanQuery = true, true, true
	base.CFrame = CFrame.new(ground + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	base.Parent = m
	local ring = part("Ring", Vector3.new(0.3, 5.3, 5.3), ORANGE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	ring.Anchored = true
	ring.CFrame = CFrame.new(ground + Vector3.new(0, 0.85, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = m
	local post = part("Post", Vector3.new(0.7, 3.6, 0.7), STEEL)
	post.Anchored, post.CanCollide = true, true
	post.CFrame = CFrame.new(ground + Vector3.new(0, 2.8, 0))
	post.Parent = m
	local set = MechArms.build(true)
	local look = -Vector3.new(dir.X, 0, dir.Z) -- (its back to the spawn's side, arms spread towards the player)
	set:PivotTo(CFrame.lookAt(ground + Vector3.new(0, 5.4, 0), ground + Vector3.new(0, 5.4, 0) + look))
	set.Name = "Display"
	set.Parent = m
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EquipMechArms"
	prompt.ActionText = "Equip / take off"
	prompt.ObjectText = "Mech Arms"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = post
	prompt.Triggered:Connect(MechArms.toggle)
	m.Parent = folder
end

-- lihfolk-ignore: remote-unvalidated-args (kind is checked on the first line: only "Tear" passes)
local function onTear(player: Player, kind: unknown, target: unknown)
	if kind ~= "Tear" or typeof(target) ~= "Instance" or not (target :: Instance):IsA("Model") then
		return
	end
	local model = target :: Model
	if player:GetAttribute("MechArms") ~= true or model:GetAttribute("IsDummy") ~= true or not model.Parent then
		return
	end
	local now = os.clock()
	if now - (lastTear[player] or -math.huge) < MechArms.GAP then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local pelvis = model:FindFirstChild("LowerTorso")
	if not (root and root:IsA("BasePart") and pelvis and pelvis:IsA("BasePart")) then
		return
	end
	if (pelvis.Position - root.Position).Magnitude > MechArms.REACH then
		return
	end
	if not Zones.mayEnter(player, Zones.plotAt(pelvis.Position)) or model:GetAttribute("InMachine") ~= nil then
		return
	end
	lastTear[player] = now
	local raw = model:GetAttribute("Severed")
	local gone = if type(raw) == "string" then raw else ""
	local piece: string? = nil
	for _, name in MechArms.ORDER do
		if not string.find("," .. gone .. ",", "," .. name .. ",", 1, true) then
			piece = name
			break
		end
	end
	if not piece then
		return
	end
	local wasDead = model:GetAttribute("Vital") == "Dead"
	local partName = if piece == "Head" then "Head" elseif piece == "Waist" then "UpperTorso" elseif piece == "LeftArm" then "LeftUpperArm"
		elseif piece == "RightArm" then "RightUpperArm" elseif piece == "LeftLeg" then "LeftUpperLeg" else "RightUpperLeg"
	local at = model:FindFirstChild(partName)
	local point = if at and at:IsA("BasePart") then at.Position else pelvis.Position
	event():FireAllClients("Reach", player, point)
	task.delay(0.22, function()
		if not model.Parent then
			return
		end
		pcall(function()
			lazy("VitalsService").sever(model, piece :: string, point)
		end)
		pcall(function()
			lazy("FxService").hit(point, 70, "Punch")
		end)
		task.delay(0.3, function()
			if not wasDead and model.Parent and model:GetAttribute("Vital") == "Dead" then
				pcall(function()
					lazy("ProgressService").addTakedowns(player, 1)
				end)
			end
		end)
	end)
end

function MechArms.start()
	event().OnServerEvent:Connect(onTear)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			if player:GetAttribute("MechArms") == true then
				task.wait(0.5)
				attach(player)
			end
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			if player:GetAttribute("MechArms") == true then
				task.wait(0.5)
				attach(player)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastTear[player] = nil
	end)
end

return MechArms
