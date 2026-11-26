--!strict
-- The things tools put into the lab, and their bookkeeping: who owns each prop, the cap per player,
-- fading out, the clean-up button, pushes that reach a prop wherever it is simulated, gadgets stuck
-- on dummies, and the collision rule that keeps props away from players' bodies.
--
-- Physics props are simulated by the player who used them (their client also simulates their
-- dummies, so contacts resolve on one machine and feel instant). The tools themselves live in
-- ToyService; blasts in Blasts.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)

local Props = {}

Props.MAX_PER_PLAYER = 10
local RETIRE_TIME = 0.35 -- s a prop takes to fade out when it is cleaned up
local CLEANUP_COOLDOWN = 1 -- s between clean-up requests from one player
local PUSH_INTERVAL = 0.1 -- s: pushes on one prop add up and go out together (see DummyControl)

-- Props that keep working on everything around them (wind, pull) are few per player: the oldest
-- one makes way, like at the overall cap.
local KIND_LIMIT: { [string]: number } = { Fan = 2, BlackHole = 1 }

-- Loose props never collide with players' bodies (dummies, floors and each other, yes): a client
-- simulates its own props, and nothing it does with them may shove another player around.
-- Anchored pads stay solid (you stand on them on purpose); ToyService never puts one down on top of
-- another player.
Props.GROUP = "LabProps"
Props.BODIES_GROUP = "PlayerBodies"
-- Each client puts other players' flying dummies and moving machines in this group (Ghosts): they
-- collide with everything except player bodies.
Props.GHOST_GROUP = "Ghost"

local owned: { [Player]: { Instance } } = {}
local lastCleanup: { [Player]: number } = {}
local propCmd: RemoteEvent? = nil

function Props.folder(): Folder
	local f = Workspace:FindFirstChild("Props")
	if f and f:IsA("Folder") then
		return f
	end
	local new = Instance.new("Folder")
	new.Name = "Props"
	new.Parent = Workspace
	return new
end

function Props.makePart(name: string, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

function Props.rootOf(prop: Instance): BasePart?
	if prop:IsA("BasePart") then
		return prop
	elseif prop:IsA("Model") then
		return prop.PrimaryPart
	end
	return nil
end

-- The prop a part belongs to (the direct child of the Props folder), if any.
function Props.propOf(part: Instance): Instance?
	local folder = Props.folder()
	if not part:IsDescendantOf(folder) then
		return nil
	end
	local prop = part
	while prop.Parent and prop.Parent ~= folder do
		prop = prop.Parent :: Instance
	end
	return prop
end

function Props.ownerOf(prop: Instance): Player?
	return Players:GetPlayerByUserId((prop:GetAttribute("Owner") :: number?) or 0)
end

local function active(prop: Instance): boolean
	return prop.Parent ~= nil and prop:GetAttribute("Retiring") ~= true
end

local function updateCount(player: Player)
	local n = 0
	for _, prop in owned[player] or {} do
		if active(prop) then
			n += 1
		end
	end
	player:SetAttribute("PropCount", n)
end

-- Fades a prop out and removes it (lifetime over, cap reached, or cleaned up). Props never just
-- blink out of existence; the player sees where they went.
function Props.retire(prop: Instance)
	if not active(prop) then
		return
	end
	prop:SetAttribute("Retiring", true)
	local info = TweenInfo.new(RETIRE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local all = prop:GetDescendants()
	table.insert(all, prop)
	for _, d in all do
		if d:IsA("BasePart") then
			d.CanTouch = false
			d.CanQuery = false
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		elseif d:IsA("Decal") or d:IsA("Texture") then
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
			d.Enabled = false
		end
	end
	local owner = Props.ownerOf(prop)
	if owner then
		updateCount(owner)
	end
	task.delay(RETIRE_TIME, function()
		prop:Destroy()
	end)
end

-- Counts a prop (or a gadget stuck on a dummy) against its player's cap; over the cap, their
-- oldest one makes way.
local function track(player: Player, prop: Instance)
	local list = owned[player] or {}
	owned[player] = list
	table.insert(list, prop)
	prop.Destroying:Once(function()
		local current = owned[player]
		local i = current and table.find(current, prop)
		if current and i then
			table.remove(current, i)
		end
		updateCount(player)
	end)
	local n = 0
	for _, p in list do
		if active(p) then
			n += 1
		end
	end
	-- ULTRA doubles the cap (MoneyService sets ZeroDelay; the overall server cap still holds).
	local cap = if player:GetAttribute("ZeroDelay") == true then Props.MAX_PER_PLAYER * 2 else Props.MAX_PER_PLAYER
	for _, p in list do
		if n <= cap then
			break
		end
		if p ~= prop and active(p) then
			Props.retire(p)
			n -= 1
		end
	end
	updateCount(player)
end

local function setGroup(root: Instance, group: string, looseOnly: boolean?)
	local all = root:GetDescendants()
	table.insert(all, root)
	for _, d in all do
		if d:IsA("BasePart") and (not looseOnly or not d.Anchored) then
			d.CollisionGroup = group
		end
	end
end

-- Parents a prop, tags its owner, gives its physics to that player and caps their count.
function Props.own(player: Player?, prop: Instance, lifetime: number)
	setGroup(prop, Props.GROUP, true)
	prop:SetAttribute("Owner", if player then player.UserId else 0)
	prop.Parent = Props.folder()
	task.delay(lifetime, Props.retire, prop)
	local root = Props.rootOf(prop)
	if root and not root.Anchored then
		pcall(root.SetNetworkOwner, root, player)
	end
	if player then
		track(player, prop)
	end
end

-- Something stuck on a dummy (rocket, balloon, sticky bomb): part of its limb's assembly, so it is
-- simulated wherever the dummy is, and counted with the player's props (counted = false for the
-- pieces of one gadget after the first: a balloon's string).
function Props.stickOn(player: Player?, part: BasePart, gadget: BasePart, counted: boolean?)
	gadget:SetAttribute("Gadget", true) -- taken off when the dummy is reset
	gadget:SetAttribute("Owner", if player then player.UserId else 0)
	gadget.Massless = true
	gadget.CanCollide = false
	gadget.CanQuery = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = gadget
	weld.Parent = gadget
	gadget.Parent = part
	if player and counted ~= false then
		track(player, gadget)
	end
end

-- One of a kind per dummy (a second rocket replaces the first instead of stacking the thrust).
function Props.unstick(dummy: Model, name: string)
	for _, d in dummy:GetDescendants() do
		if d.Name == name and d:GetAttribute("Gadget") == true then
			d:Destroy()
		end
	end
end

-- Before a player puts down another fan or black hole: their oldest makes way past the kind limit.
function Props.makeRoomFor(player: Player?, name: string)
	local limit = KIND_LIMIT[name]
	local list = player and owned[player]
	if not limit or not list then
		return
	end
	local same = {}
	for _, prop in list do
		if prop.Name == name and active(prop) then
			table.insert(same, prop)
		end
	end
	for i = 1, #same - limit + 1 do
		Props.retire(same[i])
	end
end

-- Removes every prop a player has out (the clean-up button).
function Props.cleanUp(player: Player)
	for _, prop in table.clone(owned[player] or {}) do
		Props.retire(prop)
	end
end

-- Changes a prop's velocity wherever it is simulated (its owner's client, or here). Pushes from
-- every source (wind, pull, blasts) add up and go out together.
local pushes: { [BasePart]: Vector3 } = {}
local flushQueued = false

local function flush()
	flushQueued = false
	for root, delta in pushes do
		if root.Parent and not root.Anchored then
			local prop = Props.propOf(root) or root
			local owner = Props.ownerOf(prop)
			if owner and propCmd then
				propCmd:FireClient(owner, "Push", root, delta)
			else
				root:ApplyImpulse(delta * root.AssemblyMass)
			end
		end
	end
	table.clear(pushes)
end

function Props.push(prop: Instance, deltaVelocity: Vector3)
	local root = Props.rootOf(prop)
	if not root or root.Anchored or not active(prop) then
		return
	end
	pushes[root] = (pushes[root] or Vector3.zero) + deltaVelocity
	if not flushQueued then
		flushQueued = true
		task.delay(PUSH_INTERVAL, flush)
	end
end

-- Every loose prop in reach of a point (for blasts, wind and pull), except one.
function Props.near(center: Vector3, radius: number, except: Instance?): { { prop: Instance, root: BasePart, offset: Vector3 } }
	local found = {}
	for _, prop in Props.folder():GetChildren() do
		local root = Props.rootOf(prop)
		if root and prop ~= except and active(prop) then
			local offset = root.Position - center
			if offset.Magnitude < radius then
				table.insert(found, { prop = prop, root = root, offset = offset })
			end
		end
	end
	return found
end

function Props.start()
	Props.folder() -- exists from the start so clients can watch it
	pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, Props.GROUP)
	pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, Props.BODIES_GROUP)
	PhysicsService:CollisionGroupSetCollidable(Props.GROUP, Props.BODIES_GROUP, false)
	pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, Props.GHOST_GROUP)
	PhysicsService:CollisionGroupSetCollidable(Props.GHOST_GROUP, Props.BODIES_GROUP, false)
	propCmd = Net.event(Net.Names.PropCmd)
	local function onJoin(player: Player)
		player:SetAttribute("PropCount", 0)
		player:SetAttribute("PropMax", Props.MAX_PER_PLAYER)
		local function body(character: Model)
			setGroup(character, Props.BODIES_GROUP)
			character.DescendantAdded:Connect(function(d)
				if d:IsA("BasePart") then
					d.CollisionGroup = Props.BODIES_GROUP
				end
			end)
		end
		player.CharacterAdded:Connect(body)
		if player.Character then
			body(player.Character)
		end
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		onJoin(player)
	end
	Net.event(Net.Names.CleanUp).OnServerEvent:Connect(function(player)
		local now = os.clock()
		if lastCleanup[player] and now - lastCleanup[player] < CLEANUP_COOLDOWN then
			return
		end
		lastCleanup[player] = now
		Props.cleanUp(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastCleanup[player] = nil
		local list = owned[player]
		owned[player] = nil
		for _, prop in list or {} do
			prop:Destroy()
		end
	end)
end

return Props
