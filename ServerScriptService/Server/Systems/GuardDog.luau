--!strict
-- GUARD_DOG (owner, 26 Nov 2026; docs/GUARD_DOG.md, Config.GUARD_DOG): a doghouse in every lab. "Whistle" (E / tap) and
-- the dog (a German Shepherd, V3Assets GermanShepherd; F10) comes out and follows you, a few studs behind and to the side.
-- Tap or click a ragdoll right on a limb (Client/GuardDogClient): the dog runs there and bites exactly that limb, shakes
-- it for a moment (a real hit on that part: DummyControl.hit + VitalsService.wound, so it reacts, gets hurt and can be
-- knocked out, a KO for you), then trots back: "GOOD BOY!". Never the head or neck (the client picks the nearest arm).
-- One bite at a time, BITE_GAP s apart; the dog goes home by itself after IDLE_HOME s without a bite. Cartoon only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any

local GuardDog = {}

GuardDog.FOLLOW_SPEED = 26
GuardDog.RUN_SPEED = 44
GuardDog.BITE_TIME = 2.2
GuardDog.BITE_GAP = 1.5
GuardDog.IDLE_HOME = 180
GuardDog.REACH = 40
GuardDog.HOUSE_AT = if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).LAB_OWNERMAP then (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).at("DogYard", Vector2.new(30, 200), 0, 0) else Vector2.new(40, 22) -- lab space: by the cannon, off the plaza (map round 3: OwnerMapPlan DogYard)
GuardDog.BITABLE = {
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	LowerTorso = true,
}

type Dog = { model: Model, lift: number, state: string, target: Model?, limb: BasePart?, biteAt: number, lastBite: number, lastOrder: number, house: Vector3 }
local dogs: { [Player]: Dog } = {}
local remote: RemoteEvent? = nil

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name))
end

local function floorUnder(at: Vector3, skip: { Instance }): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	local hit = Workspace:Raycast(at + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), params)
	return if hit then hit.Position.Y else at.Y - 3
end

local function sendHome(player: Player)
	local d = dogs[player]
	if d then
		d.model:Destroy()
		dogs[player] = nil
	end
	player:SetAttribute("DogOut", nil)
end

-- Row 13 part 2 (Config.DOG_PET): the dog barks (when it comes out and when it bites), and its owner can PET it (a
-- "Pet" prompt on the dog): a happy bark, a burst of pink hearts, and its idle clock starts again.
GuardDog.BARK_ID = "rbxassetid://99723552215501" -- (Creator Store "Dog bark")
local function dogPart(m: Model): BasePart?
	if m.PrimaryPart then
		return m.PrimaryPart
	end
	return m:FindFirstChildWhichIsA("BasePart", true)
end
local function bark(m: Model, pitch: number?)
	if not (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).DOG_PET then
		return
	end
	local p = dogPart(m)
	if not p then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = GuardDog.BARK_ID
	s.Volume = 0.7
	s.PlaybackSpeed = pitch or (0.95 + math.random() * 0.15)
	s.RollOffMaxDistance = 90
	s.Parent = p
	s:Play()
	game:GetService("Debris"):AddItem(s, 3)
end
local function hearts(m: Model)
	local p = dogPart(m)
	if not p then
		return
	end
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 120, 170))
	e.Size = NumberSequence.new(0.7, 0.2)
	e.Speed = NumberRange.new(4, 7)
	e.SpreadAngle = Vector2.new(40, 40)
	e.Lifetime = NumberRange.new(0.8, 1.2)
	e.EmissionDirection = Enum.NormalId.Top
	e.Enabled = false
	e.Parent = p
	e:Emit(16)
	game:GetService("Debris"):AddItem(e, 2)
end

local function whistle(player: Player, house: Vector3)
	if dogs[player] then
		sendHome(player)
		return
	end
	local src = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
	-- (F10, owner 26 Nov 2026: "ikke en robothund men en schæferhund": V3Assets GermanShepherd, a Creator Store K9 mesh
	-- (scripts and rig removed), the robot dog only if it is missing.)
	local template = src and (src:FindFirstChild("GermanShepherd") or src:FindFirstChild("PetRobotDog"))
	if not template then
		return
	end
	local m = template:Clone() :: Model
	m.Name = "GuardDog"
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		elseif p:IsA("Script") or p:IsA("LocalScript") then
			p:Destroy()
		end
	end
	local cf, size = m:GetBoundingBox()
	local lift = size.Y / 2 + (m:GetPivot().Position.Y - cf.Position.Y)
	m:PivotTo(CFrame.new(house + Vector3.new(0, lift, 3)))
	m.Parent = Workspace
	dogs[player] = { model = m, lift = lift, state = "Follow", target = nil, limb = nil, biteAt = 0, lastBite = 0, lastOrder = os.clock(), house = house }
	;(dogs[player] :: any).yaw = (template:GetAttribute("ForwardYaw") :: number?) or 0 -- (F22: the head is not on the LookVector)
	player:SetAttribute("DogOut", true)
	bark(m)
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).DOG_PET then
		local at = dogPart(m)
		if at then
			local pet = Instance.new("ProximityPrompt")
			pet.ActionText = "Pet"
			pet.ObjectText = "Good boy"
			pet.HoldDuration = 0
			pet.MaxActivationDistance = 9
			pet.RequiresLineOfSight = false
			pet.KeyboardKeyCode = Enum.KeyCode.F
			pet.Parent = at
			pet.Triggered:Connect(function(who: Player)
				local d = dogs[player]
				if who ~= player or not d or d.model ~= m then
					return
				end
				d.lastOrder = os.clock()
				bark(m, 1.15)
				hearts(m)
				if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).DOG_10 then
					-- 3.11: it rolls over on its back, and a GOOD BOY! pop with a heart
					d.rollUntil = os.clock() + 1.2
					local at = dogPart(m)
					if at then
						pcall(function()
							lazy("Playground").pop(at.Position + Vector3.new(0, 3, 0), "GOOD BOY! \u{2764}", Color3.fromRGB(255, 140, 180))
						end)
					end
				end
			end)
		end
	end
	pcall(function()
		lazy("Funnels").used(player, "DogWhistled")
	end)
end

-- The doghouse of one lab: a small wooden house with a slate roof, a food bowl, and the Whistle prompt.
function GuardDog.buildLab(folder: Instance, origin: Vector3)
	local into = Instance.new("Model")
	into.Name = "Doghouse"
	local at = Vector3.new(origin.X + GuardDog.HOUSE_AT.X, 0, origin.Z + GuardDog.HOUSE_AT.Y)
	local floorY = floorUnder(Vector3.new(at.X, origin.Y + 2, at.Z), {})
	at = Vector3.new(at.X, floorY, at.Z)
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		if shape then
			p.Shape = shape
		end
		p.Parent = into
		return p
	end
	local wood = Color3.fromRGB(150, 104, 64)
	local base = part("House", Vector3.new(5, 4, 5), CFrame.new(at + Vector3.new(0, 2, 0)), wood, Enum.Material.WoodPlanks)
	game:GetService("CollectionService"):AddTag(base, "Doghouse") -- (F9: the dog button shows only near one)
	part("Door", Vector3.new(2, 2.6, 0.2), CFrame.new(at + Vector3.new(0, 1.3, 2.55)), Color3.fromRGB(30, 24, 20), Enum.Material.SmoothPlastic)
	local slate = Color3.fromRGB(60, 64, 72)
	for _, side in { -1, 1 } do
		local roof = Instance.new("WedgePart")
		roof.Name = "Roof"
		roof.Anchored = true
		roof.Size = Vector3.new(5.6, 2, 3)
		roof.CFrame = CFrame.new(at + Vector3.new(side * 1.5, 5, 0)) * CFrame.Angles(0, math.rad(side * 90), 0)
		roof.Color = slate
		roof.Material = Enum.Material.Slate
		roof.Parent = into
	end
	part("Bowl", Vector3.new(0.5, 1.4, 1.4), CFrame.new(at + Vector3.new(2.2, 0.25, 3.4)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Whistle"
	prompt.ObjectText = "Guard Dog"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	prompt.Triggered:Connect(function(player: Player)
		whistle(player, at)
	end)
	into.Parent = folder
end

local function onRemote(player: Player, kind: unknown, target: unknown, limbName: unknown)
	if type(kind) ~= "string" or (kind ~= "Home" and kind ~= "Bite") then
		return
	end
	local d = dogs[player]
	if kind == "Home" then
		sendHome(player)
		return
	end
	if kind ~= "Bite" or not d then
		return
	end
	local now = os.clock()
	if now - d.lastOrder < GuardDog.BITE_GAP or d.state ~= "Follow" then
		return
	end
	if typeof(target) ~= "Instance" or not (target :: Instance):IsA("Model") or type(limbName) ~= "string" or not GuardDog.BITABLE[limbName] then
		return
	end
	local model = target :: Model
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies or not model:IsDescendantOf(dummies) or model:GetAttribute("Vital") == "Dead" then
		return
	end
	local limb = model:FindFirstChild(limbName)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not limb or not limb:IsA("BasePart") or not root or not root:IsA("BasePart") or (limb.Position - root.Position).Magnitude > GuardDog.REACH then
		return
	end
	d.lastOrder = now
	d.state, d.target, d.limb = "Run", model, limb
	pcall(function()
		lazy("Funnels").used(player, "DogBite")
	end)
end

local function bite(player: Player, d: Dog)
	local model, limb = d.target, d.limb
	if not model or not limb or not limb.Parent then
		return
	end
	local dir = limb.Position - d.model:GetPivot().Position
	dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.zAxis
	pcall(function()
		lazy("DummyControl").hit(model, limb, (dir * 0.6 + Vector3.new(0, 0.3, 0)) * limb.AssemblyMass * 28, limb.Position, nil, player)
	end)
	pcall(function()
		lazy("VitalsService").wound(model, limb, limb.Position, player, 0.7, { blunt = true })
	end)
	pcall(function()
		lazy("FxService").hit(limb.Position, 30, "Bat", player.UserId, true)
	end)
	bark(d.model, 0.85)
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).DOG_10 then
		-- 3.11 tooth marks: two little arcs of grey dents on the side of the limb the dog bit (cartoon, 10 s)
		local face = -dir
		local up = limb.CFrame.UpVector
		local right = face:Cross(up)
		right = if right.Magnitude > 1e-3 then right.Unit else limb.CFrame.RightVector
		local half = limb.Size.Magnitude * 0.28
		for _, row in { 0.18, -0.18 } do
			for k = -2, 2 do
				local dot = Instance.new("Part")
				dot.Name = "ToothMark"
				dot.Shape = Enum.PartType.Ball
				dot.Size = Vector3.one * 0.13
				dot.Color = Color3.fromRGB(110, 100, 120)
				dot.Material = Enum.Material.SmoothPlastic
				dot.Massless, dot.CanCollide, dot.CanQuery, dot.CanTouch = true, false, false, false
				dot.CFrame = CFrame.new(limb.Position + face * half + right * k * 0.12 + up * (row + math.abs(k) * 0.03 * (if row > 0 then -1 else 1)))
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = limb, dot
				w.Parent = dot
				dot.Parent = limb
				game:GetService("Debris"):AddItem(dot, 10)
			end
		end
	end
end

-- F22 (owner, 26 Nov 2026: "hunden skal bevæge sig meget mere realistisk ... vender den forkerte vej når den bider"):
--   * Facing: the model's head is not on its LookVector; every placement goes through place() with the template's
--     ForwardYaw attribute (the German Shepherd: pi), the one place the forward offset lives.
--   * It moves along its heading, which turns toward where it wants to go at TURN rad/s (arcs, never a spin on the
--     spot); its speed eases up and down (ACCEL, BRAKE); the gait follows the speed (walk: a small head bob; trot;
--     gallop: a big bound and the back stretching), its beat driven by the distance covered, so nothing slides.
--   * The body tilts with the slope under it (front and back feet).
--   * Following: on your right, about 5 studs back; slows to a walk near you; standing by you it turns to look at you,
--     sits after SIT_AFTER s and lies down after LIE_AFTER s.
--   * The bite: eyes on the target, a short crouch, a sprint, slowing in the last few studs, then it stops with its
--     head (HEAD_REACH studs ahead of the body) on the limb, facing it, leaning back as it tugs and shakes; then a
--     wet-dog shake of the whole body and it trots back.
GuardDog.TURN = 5
GuardDog.ACCEL = 34
GuardDog.BRAKE = 50
GuardDog.HEAD_REACH = 3
GuardDog.CROUCH = 0.35
GuardDog.SHAKE = 0.8
GuardDog.SIT_AFTER = 6
GuardDog.LIE_AFTER = 20

local function flatOf(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function turnToward(heading: Vector3, want: Vector3, rate: number, dt: number): Vector3
	if want.Magnitude < 1e-3 then
		return heading
	end
	local t = want.Unit
	local dot = math.clamp(heading:Dot(t), -1, 1)
	local a = math.acos(dot)
	if a < 1e-3 then
		return t
	end
	local turn = math.min(a, rate * dt)
	local side = if heading:Cross(t).Y >= 0 then 1 else -1
	return (CFrame.Angles(0, turn * side, 0) * heading).Unit
end

local function place(d: any, pos: Vector3, heading: Vector3, extra: CFrame?)
	local h = if heading.Magnitude > 1e-3 then heading.Unit else Vector3.zAxis
	d.model:PivotTo(CFrame.lookAt(pos, pos + h) * (extra or CFrame.identity) * CFrame.Angles(0, d.yaw or 0, 0)) -- (the pose in the heading's own frame: +X tips the nose up)
end

local function step(dt: number)
	local now = os.clock()
	for player, d0 in dogs do
		local d: any = d0
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not player.Parent or not d.model.Parent or not root or not root:IsA("BasePart") then
			sendHome(player)
			continue
		end
		if now - d.lastBite > GuardDog.IDLE_HOME and now - d.lastOrder > GuardDog.IDLE_HOME then
			sendHome(player)
			continue
		end
		local skip = { d.model, character :: Instance }
		local here = d.model:GetPivot().Position
		d.heading = d.heading or flatOf(root.Position - here)
		if d.heading.Magnitude < 1e-3 then
			d.heading = Vector3.zAxis
		end
		d.v = d.v or 0
		d.phase = d.phase or 0
		local function ground(at: Vector3): number
			return floorUnder(at, skip) + d.lift
		end
		local function tilt(at: Vector3, heading: Vector3): number
			local f = floorUnder(at + heading * 2, skip)
			local b = floorUnder(at - heading * 2, skip)
			return math.clamp(math.atan2(f - b, 4), -0.5, 0.5)
		end
		if d.rollUntil and now < d.rollUntil and d.state ~= "Run" and d.state ~= "Bite" then
			-- 3.11: petted: a roll over on its back, lifting a little in the middle
			local t = 1 - (d.rollUntil - now) / 1.2
			place(d, Vector3.new(here.X, ground(here) + math.sin(t * math.pi) * 0.6, here.Z), d.heading, CFrame.Angles(0, 0, t * math.pi * 2))
			continue
		end
		if d.state == "Run" or d.state == "Bite" then
			local limb = d.limb
			if not limb or not limb.Parent or not d.target or (d.target:GetAttribute("Vital") == "Dead" and d.state == "Run") then
				d.state, d.crouchUntil = "Follow", nil
				continue
			end
			local toLimb = flatOf(limb.Position - here)
			local gap = toLimb.Magnitude
			if d.state == "Run" then
				-- Eyes on it, a short crouch, then the sprint.
				if not d.crouchUntil then
					d.crouchUntil = now + GuardDog.CROUCH
					d.v = 0
					if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).DOG_10 then
						bark(d.model, 0.55) -- (3.11: a deep growl-woof as it crouches)
					end
				end
				if now < d.crouchUntil then
					d.heading = turnToward(d.heading, toLimb, GuardDog.TURN * 1.5, dt)
					place(d, Vector3.new(here.X, ground(here) - 0.3, here.Z), d.heading, CFrame.Angles(-0.06, 0, 0))
					continue
				end
				if gap < GuardDog.HEAD_REACH + 0.4 then
					d.state, d.biteAt, d.crouchUntil, d.biteSpot = "Bite", now, nil, here
					d.v = 0
					bite(player, d)
				else
					local want = if gap < GuardDog.HEAD_REACH + 3 then GuardDog.RUN_SPEED * 0.3 else GuardDog.RUN_SPEED
					d.v += math.clamp(want - d.v, -GuardDog.BRAKE * dt, GuardDog.ACCEL * 1.5 * dt)
					d.heading = turnToward(d.heading, toLimb, GuardDog.TURN * 1.4, dt)
				end
			end
			if d.state == "Bite" then
				-- Facing the limb, leaning back and tugging, the head shaking it.
				d.heading = turnToward(d.heading, toLimb, GuardDog.TURN * 2, dt)
				local t = now - d.biteAt
				local tug = math.sin(t * 9) * 0.25
				local spot = d.biteSpot or here
				local pos = Vector3.new(spot.X, ground(spot), spot.Z) - d.heading * (0.15 + tug * 0.2)
				place(d, pos, d.heading, CFrame.Angles(-0.12, math.sin(t * 22) * 0.18, math.sin(t * 22) * 0.06))
				if t > GuardDog.BITE_TIME then
					d.state, d.lastBite, d.shakeUntil = "Shake", now, now + GuardDog.SHAKE
					local r = remote
					if r then
						r:FireClient(player, "GoodBoy")
					end
				end
				continue
			end
		elseif d.state == "Shake" then
			-- The wet-dog shake: the whole body twists fast side to side.
			local pos = Vector3.new(here.X, ground(here), here.Z)
			place(d, pos, d.heading, CFrame.Angles(0, 0, math.sin(now * 42) * 0.28))
			if now >= (d.shakeUntil or 0) then
				d.state = "Follow"
			end
			continue
		else
			-- Following: on your right, about 5 studs back; slower close to you.
			local goal = root.Position + root.CFrame.RightVector * 3 - root.CFrame.LookVector * 4
			local move = flatOf(goal - here)
			local dist = move.Magnitude
			local want = if dist < 1.2 then 0 else GuardDog.FOLLOW_SPEED * math.clamp((dist - 1) / 8, 0.25, 1)
			if dist > 24 then
				want = GuardDog.RUN_SPEED -- (left far behind: it gallops to catch up)
			end
			d.v += math.clamp(want - d.v, -GuardDog.BRAKE * dt, GuardDog.ACCEL * dt)
			if d.v > 0.3 then
				d.heading = turnToward(d.heading, move, GuardDog.TURN, dt)
				d.idleSince = nil
			else
				-- Standing by you: it turns to look at you, sits, and lies down after a while.
				d.v = 0
				d.idleSince = d.idleSince or now
				d.heading = turnToward(d.heading, flatOf(root.Position - here), GuardDog.TURN * 0.6, dt)
				local idle = now - d.idleSince
				local pos = Vector3.new(here.X, ground(here), here.Z)
				local pose: CFrame
				if idle > GuardDog.LIE_AFTER then
					pos -= Vector3.new(0, 0.55, 0)
					pose = CFrame.Angles(0, math.sin(now * 0.7) * 0.03, 0)
				elseif idle > GuardDog.SIT_AFTER then
					pos -= Vector3.new(0, 0.25, 0)
					pose = CFrame.Angles(0.22, 0, 0) -- (the front up, sitting)
				else
					pose = CFrame.Angles(math.sin(now * 3) * 0.015, math.sin(now * 9) * 0.05, 0) -- (breathing, a happy wiggle)
				end
				place(d, pos + Vector3.new(0, math.sin(now * 3) * 0.03, 0), d.heading, pose)
				continue
			end
		end
		-- Moving: along its heading (so it turns in arcs), the gait by speed, its beat by the distance covered.
		local pos = here + d.heading * d.v * dt
		d.phase += d.v * dt * 0.55
		local gallop = d.v > 30
		local trot = d.v > 12
		local beat = d.phase * math.pi
		local bob = if gallop then math.abs(math.sin(beat)) * 0.4 elseif trot then math.abs(math.sin(beat * 2)) * 0.16 else math.abs(math.sin(beat * 2)) * 0.06
		local pitch = tilt(pos, d.heading) + (if gallop then math.sin(beat) * 0.12 elseif trot then math.sin(beat * 2) * 0.03 else math.sin(beat * 2) * 0.02)
		local roll = if trot and not gallop then math.sin(beat) * 0.05 else 0
		place(d, Vector3.new(pos.X, ground(pos) + bob, pos.Z), d.heading, CFrame.Angles(pitch, 0, roll))
	end
end

function GuardDog.start()
	remote = Net.event(Net.Names.GuardDog)
	local r = remote :: RemoteEvent
	r.OnServerEvent:Connect(onRemote)
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		sendHome(player)
	end)
end

return GuardDog
