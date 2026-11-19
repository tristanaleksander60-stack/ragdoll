--!strict
-- Contacts between props and the dummies this client simulates: anvils, bowling balls and
-- trampolines hit our dummies here, instantly and on the same machine that moves them.
-- The server judges contacts only for dummies it simulates itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local HitMath = require(Shared:WaitForChild("HitMath"))
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll"))
local Dummies = require(Shared:WaitForChild("Dummies"))

local DummySim = require(script.Parent:WaitForChild("DummySim"))

local PropContacts = {}

-- Local effect for a contact: (toyId, position, speed). Set by the effects controller.
PropContacts.onHit = nil :: ((toyId: string, position: Vector3, speed: number) -> ())?

local relay: RemoteEvent
local mayHit = Dummies.gate()

-- Whose thing a part is: a prop's player, a build's player, nobody for the shared playground.
local function ownerIdOf(part: Instance): number
	local holder = part:FindFirstAncestorWhichIsA("Folder")
	local props = Workspace:FindFirstChild("Props")
	if props and part:IsDescendantOf(props) then
		local prop = part
		while prop.Parent and prop.Parent ~= props do
			prop = prop.Parent :: Instance
		end
		return (prop:GetAttribute("Owner") :: number?) or 0
	end
	while holder do
		local owner = holder:GetAttribute("Owner")
		if type(owner) == "number" then
			return owner
		end
		holder = holder:FindFirstAncestorWhichIsA("Folder")
	end
	return 0
end

-- Applies a contact to a dummy this client simulates, blamed on whoever owns what touched it (only
-- they can be knocked over by the dummy while it flies).
local blameRemote: RemoteEvent? = nil

local function apply(model: Model, cause: Instance, other: BasePart, impulse: Vector3, maxSpeed: number?)
	Dummies.blameLocal(model, ownerIdOf(cause))
	-- The server and every other client learn it too (only this client saw the contact).
	if blameRemote and cause:IsA("BasePart") then
		blameRemote:FireServer(model, cause)
	end
	ActiveRagdoll.hit(model, other, impulse, other.Position, maxSpeed)
end

local function report(toyId: string, position: Vector3, speed: number)
	local listener = PropContacts.onHit
	if listener then
		listener(toyId, position, speed)
	end
	relay:FireServer("Hit", position, speed, toyId)
end

local function onPropTouched(prop: BasePart, source: BasePart, other: BasePart)
	local model = DummySim.simulatedDummyOf(other)
	if not model then
		return
	end
	local profile = HitMath.PROPS[prop.Name]
	if not profile then
		return
	end
	local impulse = HitMath.propImpulse(source, other, profile.minSpeed, profile.scale)
	if not impulse or not HitMath.firstHit(source, model, profile.pass) or not mayHit(model, HitMath.TOUCH_COOLDOWN) then
		return
	end
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	impulse = HitMath.capImpulse(impulse, profile, mass)
	apply(model, source, other, impulse, profile.maxSpeed)
	HitMath.absorb(source, profile)
	report(profile.toyId, other.Position, impulse.Magnitude / mass)
end

local Players = game:GetService("Players")
local localUserId = Players.LocalPlayer.UserId
local propsFolder: Instance? = nil
local lastPropBounce: { [BasePart]: number } = {}

-- The top-level prop a part belongs to, if this player owns it (so this client simulates it).
local function ownedPropOf(part: Instance): Instance?
	local folder = propsFolder
	if not folder or not part:IsDescendantOf(folder) then
		return nil
	end
	local prop = part
	while prop.Parent and prop.Parent ~= folder do
		prop = prop.Parent :: Instance
	end
	return if prop:GetAttribute("Owner") == localUserId then prop else nil
end

local function onPadTouched(pad: BasePart, other: BasePart)
	local model = DummySim.simulatedDummyOf(other)
	if not model then
		-- Our own loose props bounce too (anvils on trampolines are the point).
		local prop = ownedPropOf(other)
		if prop and not other.Anchored and not pad:IsDescendantOf(prop) then
			local now = os.clock()
			if not lastPropBounce[other] or now - lastPropBounce[other] > 0.3 then
				lastPropBounce[other] = now
				for part in lastPropBounce do
					if not part.Parent then
						lastPropBounce[part] = nil
					end
				end
				local v = other.AssemblyLinearVelocity
				other.AssemblyLinearVelocity = Vector3.new(v.X * 0.6, HitMath.TRAMPOLINE_SPEED * 0.8, v.Z * 0.6)
				report("Trampoline", pad.Position, 30)
			end
		end
		return
	end
	if not mayHit(model, 0.5) then
		return
	end
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	local v = other.AssemblyLinearVelocity
	local push = Vector3.new(v.X * 0.3, HitMath.TRAMPOLINE_SPEED, v.Z * 0.3)
	apply(model, pad, other, push * mass)
	report("Trampoline", pad.Position, 40)
end

-- Tool pads (spring pad, banana peel) under the dummies this client simulates.
local function onToolPadTouched(pad: BasePart, other: BasePart)
	local model = DummySim.simulatedDummyOf(other)
	if not model or not mayHit(model, 0.6) then
		return
	end
	local launch = HitMath.padLaunch(pad, other.AssemblyLinearVelocity)
	if not launch then
		return
	end
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	apply(model, pad, other, launch * mass)
	report(pad.Name, pad.Position, launch.Magnitude)
end

local function watchProp(prop: Instance)
	-- Every part of the prop that can touch something; the prop's root carries mass and velocity.
	local root: BasePart? = if prop:IsA("BasePart") then prop else nil
	local function hook(part: BasePart)
		if part.Name == "TrampolinePad" then
			part.Touched:Connect(function(other)
				onPadTouched(part, other)
			end)
		elseif part.Name == "SpringPad" or part.Name == "BananaPeel" then
			part.Touched:Connect(function(other)
				onToolPadTouched(part, other)
			end)
		elseif HitMath.PROPS[part.Name] then
			local source = root or part
			HitMath.track(source)
			part.Touched:Connect(function(other)
				onPropTouched(part, source, other)
			end)
		end
	end
	if prop:IsA("BasePart") then
		hook(prop)
	end
	for _, d in prop:GetDescendants() do
		if d:IsA("BasePart") then
			hook(d)
		end
	end
end

-- Workshop pieces: trampolines and bumpers act on the dummies this client simulates, and a sensor
-- in your own build tells the server when one of them steps on it.
local lastBump: { [Model]: number } = {}

local function onBumper(ball: BasePart, other: BasePart)
	local model = DummySim.simulatedDummyOf(other)
	if not model then
		return
	end
	local now = os.clock()
	if lastBump[model] and now - lastBump[model] < 0.5 then
		return
	end
	lastBump[model] = now
	for m in lastBump do
		if not m.Parent then
			lastBump[m] = nil
		end
	end
	local away = other.Position - ball.Position
	local flat = Vector3.new(away.X, 0, away.Z)
	local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) * 0.85 + Vector3.new(0, 0.5, 0)).Unit
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	apply(model, ball, other, dir * HitMath.BUMPER_SPEED * mass)
	report("Trampoline", other.Position, 35)
end

local signal: RemoteEvent

-- The body part whose recent velocity stands for the whole dummy.
local function bodyOf(model: Model): BasePart?
	local body = model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
	return if body and body:IsA("BasePart") then body else nil
end

local function onMachineTouched(part: BasePart, other: BasePart)
	-- Only free-moving machines hit: a frozen build, or anything fixed to a pinned part (a conveyor
	-- belt moves things by its surface speed, it does not swing into them), does not.
	local root = part.AssemblyRootPart
	if part.Anchored or not root or root.Anchored then
		return
	end
	local model = DummySim.simulatedDummyOf(other)
	if not model then
		return
	end
	local body = bodyOf(model)
	if body and not HitMath.isTracked(body) then
		HitMath.track(body)
	end
	if not HitMath.isTracked(root) then
		HitMath.track(root)
	end
	local launch = HitMath.machineLaunch(part, other, body)
	if not launch or not HitMath.firstHit(root, model) or not mayHit(model, HitMath.TOUCH_COOLDOWN) then
		return
	end
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	apply(model, part, other, launch * mass, HitMath.MACHINE_MAX_SPEED)
	report("Machine", other.Position, launch.Magnitude)
end

local function watchBuildPart(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	-- Any piece can be part of a moving machine; the handler ignores it while it is frozen.
	if part.Name ~= "TrampolinePad" and part.Name ~= "BumperBall" and part.Name ~= "SensorPad" then
		part.Touched:Connect(function(other)
			onMachineTouched(part, other)
		end)
	end
	if part.Name == "TrampolinePad" then
		part.Touched:Connect(function(other)
			onPadTouched(part, other)
		end)
	elseif part.Name == "CannonPad" or typeof(part:GetAttribute("LaunchVelocity")) == "Vector3" then
		-- The playground's human cannon fires dummies too, and the labs' lava and spike blocks
		-- throw them up as they throw players (10 Nov 2026).
		local cannon = part.Name == "CannonPad"
		part.Touched:Connect(function(other)
			local model = DummySim.simulatedDummyOf(other)
			local launch = part:GetAttribute("LaunchVelocity")
			if model and typeof(launch) == "Vector3" and mayHit(model, 1.5) then
				local mass = (model:GetAttribute("Mass") :: number?) or 10
				apply(model, part, other, (launch :: Vector3) * mass)
				report(if cannon then "CannonPad" else "Trampoline", part.Position, (launch :: Vector3).Magnitude)
			end
		end)
	elseif part.Name == "BumperBall" then
		part.Touched:Connect(function(other)
			onBumper(part, other)
		end)
	elseif part.Name == "SensorPad" then
		local folder = part:FindFirstAncestorOfClass("Folder")
		if folder and folder:GetAttribute("Owner") == localUserId then
			part.Touched:Connect(function(other)
				if DummySim.simulatedDummyOf(other) then
					local model = part:FindFirstAncestorOfClass("Model")
					local index = model and model:GetAttribute("Piece")
					if index then
						signal:FireServer("Sensor", index)
					end
				end
			end)
		end
	end
end

function PropContacts.start()
	signal = Net.event(Net.Names.BuildSignal)
	task.spawn(function()
		local builds = Workspace:WaitForChild("Builds")
		builds.DescendantAdded:Connect(watchBuildPart)
		for _, d in builds:GetDescendants() do
			watchBuildPart(d)
		end
	end)
	-- The ready-made playground: trampolines, the human cannon, the wrecking ball.
	task.spawn(function()
		local playground = Workspace:WaitForChild("Playground")
		playground.DescendantAdded:Connect(watchBuildPart)
		for _, d in playground:GetDescendants() do
			watchBuildPart(d)
		end
	end)
	relay = Net.event(Net.Names.FxRelay)
	blameRemote = Net.event(Net.Names.DummyBlame)
	-- Track the dummies' bodies from the start, so a machine's first contact knows how fast the
	-- body was already going.
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies")
		local function add(model: Instance)
			if model:IsA("Model") then
				local body = model:WaitForChild("UpperTorso", 10)
				if body and body:IsA("BasePart") and not HitMath.isTracked(body) then
					HitMath.track(body)
				end
			end
		end
		dummies.ChildAdded:Connect(add)
		for _, model in dummies:GetChildren() do
			task.spawn(add, model)
		end
	end)
	local folder = Workspace:WaitForChild("Props")
	propsFolder = folder
	-- Blasts and wind from the server reach the props this client simulates.
	Net.event(Net.Names.PropCmd).OnClientEvent:Connect(function(kind: unknown, part: unknown, delta: unknown)
		if kind ~= "Push" or typeof(part) ~= "Instance" or typeof(delta) ~= "Vector3" then
			return
		end
		local p = part :: Instance
		local builds = Workspace:FindFirstChild("Builds")
		local myBuild = builds and builds:FindFirstChild(tostring(localUserId))
		local mine = ownedPropOf(p) ~= nil or (myBuild ~= nil and p:IsDescendantOf(myBuild))
		if not p:IsA("BasePart") or not mine or p.Anchored then
			return
		end
		local d = delta :: Vector3
		if d.Magnitude > 200 then
			d = d.Unit * 200
		end
		p:ApplyImpulse(d * p.AssemblyMass)
	end)
	folder.ChildAdded:Connect(watchProp)
	for _, child in folder:GetChildren() do
		watchProp(child)
	end
end

return PropContacts
