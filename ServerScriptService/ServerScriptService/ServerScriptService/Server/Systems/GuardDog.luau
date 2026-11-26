--!strict
-- GUARD_DOG (owner, 26 Nov 2026; docs/GUARD_DOG.md, Config.GUARD_DOG): a doghouse in every lab. "Whistle" (E / tap) and
-- the dog (the robot dog model, V3Assets PetRobotDog) comes out and follows you, a few studs behind and to the side.
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
GuardDog.HOUSE_AT = Vector2.new(40, 22) -- lab space: by the cannon, off the plaza
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

local function whistle(player: Player, house: Vector3)
	if dogs[player] then
		sendHome(player)
		return
	end
	local src = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
	local template = src and src:FindFirstChild("PetRobotDog")
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
	player:SetAttribute("DogOut", true)
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
end

local function step(dt: number)
	local now = os.clock()
	for player, d in dogs do
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
		local here = d.model:GetPivot().Position
		local goal: Vector3
		local speed = GuardDog.FOLLOW_SPEED
		if d.state == "Run" or d.state == "Bite" then
			local limb = d.limb
			if not limb or not limb.Parent or not d.target or d.target:GetAttribute("Vital") == "Dead" and d.state == "Run" then
				d.state = "Follow"
				continue
			end
			goal = limb.Position
			speed = GuardDog.RUN_SPEED
			local flatGap = Vector3.new(goal.X - here.X, 0, goal.Z - here.Z).Magnitude
			if d.state == "Run" and flatGap < 2.5 then
				d.state, d.biteAt = "Bite", now
				bite(player, d)
			end
			if d.state == "Bite" then
				-- The shake: the head goes side to side on the limb, then it lets go.
				local wag = math.sin((now - d.biteAt) * 22) * 0.5
				local look = Vector3.new(goal.X - here.X, 0, goal.Z - here.Z)
				local face = if look.Magnitude > 0.05 then look.Unit else Vector3.zAxis
				d.model:PivotTo(CFrame.lookAt(here, here + face) * CFrame.Angles(0, wag, 0))
				if now - d.biteAt > GuardDog.BITE_TIME then
					d.state, d.lastBite = "Follow", now
					local r = remote
					if r then
						r:FireClient(player, "GoodBoy")
					end
				end
				continue
			end
		else
			goal = root.Position + root.CFrame.RightVector * 3 - root.CFrame.LookVector * 3
		end
		local move = Vector3.new(goal.X - here.X, 0, goal.Z - here.Z)
		local dist = move.Magnitude
		if dist > 0.4 then
			local stepLen = math.min(dist, speed * dt)
			local next = here + move.Unit * stepLen
			local y = floorUnder(next, { d.model, character :: Instance }) + d.lift
			local pos = Vector3.new(next.X, y, next.Z)
			d.model:PivotTo(CFrame.lookAt(pos, pos + move.Unit))
		end
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
