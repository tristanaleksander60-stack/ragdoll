--!strict
-- What every catalog tool that is not a plain hit or the grab does (Shared/Toys lists them):
--   props    anvil, trampoline, spring pad, banana, fan, bowling ball, cannon
--   blasts   TNT, firecracker, shockwave, big boom, sticky bomb (the explosions: Blasts)
--   gadgets  rocket, balloon, freeze, zap, black hole, heal
-- Bookkeeping (owners, caps, fading out, pushes, collision groups) is in Props.
--
-- Contacts between a prop and a dummy are judged where the dummy is simulated: the owner's client
-- (PropContacts) or, for dummies nobody simulates, here. Blasts, wind and rockets go through
-- DummyControl, which reaches either. Whatever a tool does to a dummy is blamed on its player
-- (DummyControl's `by`): only that player can be knocked over by the dummy as it flies.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local HitMath = require(Shared.HitMath)
local Dummies = require(Shared.Dummies)
local Net = require(Shared.Net)
local NORMAL_GRAVITY = require(Shared.Ragdoll.Config).NORMAL_GRAVITY
local GameConfig = require(Shared:WaitForChild("Config")) :: any
local DummyControl = require(script.Parent.DummyControl)
local FxService = require(script.Parent.FxService)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local Props = require(script.Parent.Props)
local Blasts = require(script.Parent.Blasts)
local VitalsService = require(script.Parent.VitalsService)
local BadgeAwards = require(script.Parent.BadgeAwards)

local makePart = Props.makePart
local own = Props.own
local BLASTS = Blasts.KINDS

-- Nothing solid is put down on top of another player (they would be shoved out of it).
local PLACE_CLEARANCE = 7 -- studs, flat
local PLACE_CLEARANCE_UP = 10
-- A sticky bomb rides on a flying dummy: it goes off where the dummy is, within reason.
local STICKY_DRIFT = 150
local STICKY_HOME = 30 -- carried further than this from where it was stuck, it spares its player
local BOMB_DRIFT = 30 -- a bomb on the floor: its owner's client may nudge it, not carry it off

local ToyService = {}
local TweenService = game:GetService("TweenService")
local N7Models = require(Shared.N7Models)
-- Round 5: each player's C4 charges waiting for the second press (ToyService.detonate).
local armedC4: { [Player]: { () -> () } } = {}
Players.PlayerRemoving:Connect(function(player)
	armedC4[player] = nil
end)

-- Kept on ToyService for the systems and tests that use them.
ToyService.BLASTS = BLASTS
ToyService.blast = Blasts.blast
ToyService.explode = Blasts.explode
ToyService.blastListeners = Blasts.listeners
ToyService.dummiesNear = Blasts.dummiesNear
ToyService.pushProp = Props.push
ToyService.propsFolder = Props.folder
ToyService.cleanUp = Props.cleanUp

local mayHit = Dummies.gate()

local function massOf(dummy: Model): number
	return (dummy:GetAttribute("Mass") :: number?) or 10
end

local function flat(facing: Vector3): Vector3
	local f = Vector3.new(facing.X, 0, facing.Z)
	return if f.Magnitude > 0.01 then f.Unit else Vector3.zAxis
end

-- A moving prop touched a dummy part. Only judged here for dummies the server simulates.
local function impact(prop: BasePart, other: BasePart)
	local model = Dummies.of(other)
	if not model or DummyControl.ownerOf(model) ~= nil then
		return
	end
	local profile = HitMath.PROPS[prop.Name]
	if not profile then
		return
	end
	-- Diagnostics for the self-tests: how many prop contacts this dummy had and what came of them.
	model:SetAttribute("PropTouches", ((model:GetAttribute("PropTouches") :: number?) or 0) + 1)
	local impulse = HitMath.propImpulse(prop, other, profile.minSpeed, profile.scale)
	if not impulse then
		model:SetAttribute("PropSlow", ((model:GetAttribute("PropSlow") :: number?) or 0) + 1)
		return
	end
	if not HitMath.firstHit(prop, model, profile.pass) or not mayHit(model, HitMath.TOUCH_COOLDOWN) then
		return
	end
	model:SetAttribute("PropHits", ((model:GetAttribute("PropHits") :: number?) or 0) + 1)
	impulse = HitMath.capImpulse(impulse, profile, massOf(model))
	local state = DummyControl.hit(model, other, impulse, other.Position, profile.maxSpeed, Props.ownerOf(prop))
	model:SetAttribute("PropHit", tostring(state))
	HitMath.absorb(prop, profile)
	if state then
		FxService.hit(other.Position, impulse.Magnitude / massOf(model), profile.toyId)
	end
end

local function watchImpacts(part: BasePart, source: BasePart)
	HitMath.track(source)
	part.Touched:Connect(function(other)
		impact(source, other)
	end)
end

------------------------------------------------------------------------------------------------
-- Props

local function anvil(player: Player?, at: Vector3)
	local body = makePart("Anvil", Vector3.new(3, 1.6, 2), Color3.fromRGB(70, 72, 82), Enum.Material.Metal)
	body.CustomPhysicalProperties = PhysicalProperties.new(8, 0.6, 0.1) -- heavy, but not a bulldozer once it has landed
	body.CFrame = CFrame.new(at + Vector3.new(0, 32, 0))
	local top = makePart("AnvilTop", Vector3.new(4.2, 0.8, 2.2), Color3.fromRGB(80, 82, 92), Enum.Material.Metal)
	top.CFrame = body.CFrame * CFrame.new(0, 1.2, 0)
	top.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = top
	weld.Parent = body
	top.Parent = body
	watchImpacts(body, body)
	watchImpacts(top, body)
	own(player, body, 6)
end

local function trampoline(player: Player?, at: Vector3)
	local model = Instance.new("Model")
	model.Name = "Trampoline"
	local base = makePart("Base", Vector3.new(1, 7, 7), Color3.fromRGB(40, 40, 50), Enum.Material.SmoothPlastic)
	base.Shape = Enum.PartType.Cylinder
	base.Anchored = true
	base.CFrame = CFrame.new(at + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	base.Parent = model
	-- The pad covers the whole frame: a body landing on the rim bounces too (it used to land on the
	-- frame's edge and just stop).
	local pad = makePart("TrampolinePad", Vector3.new(0.3, 6.9, 6.9), Color3.fromRGB(80, 170, 255), Enum.Material.Fabric)
	pad.Shape = Enum.PartType.Cylinder
	pad.Anchored = true
	pad.CFrame = CFrame.new(at + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pad.Parent = model
	model.PrimaryPart = base

	local function bounce(other: BasePart, force: boolean)
		local dummy = Dummies.of(other)
		if not dummy then
			-- A loose prop nobody simulates landing on the pad (props a player owns bounce on that
			-- player's client).
			local prop = Props.propOf(other)
			if prop and prop ~= model and not other.Anchored and (prop:GetAttribute("Owner") :: number?) == 0 then
				local v = other.AssemblyLinearVelocity
				other.AssemblyLinearVelocity = Vector3.new(v.X * 0.6, HitMath.TRAMPOLINE_SPEED * 0.8, v.Z * 0.6)
			end
			return
		end
		if (not force and DummyControl.ownerOf(dummy) ~= nil) or not mayHit(dummy, 0.5) then
			return
		end
		local v = other.AssemblyLinearVelocity
		-- The hit adds to the body's speed: a body still falling first has its fall cancelled, so it
		-- always goes up at least TRAMPOLINE_SPEED (a lower first touch by a hand used to eat the bounce).
		local pelvis = dummy:FindFirstChild("LowerTorso")
		local fall = if pelvis and pelvis:IsA("BasePart") then math.min(pelvis.AssemblyLinearVelocity.Y, 0) else math.min(v.Y, 0)
		local push = Vector3.new(v.X * 0.3, HitMath.TRAMPOLINE_SPEED - fall, v.Z * 0.3)
		DummyControl.hit(dummy, other, push * massOf(dummy), other.Position, nil, player)
		FxService.hit(pad.Position, 40, "Trampoline")
	end
	pad.Touched:Connect(function(other)
		bounce(other, false)
	end)
	own(player, model, 30)
	-- Placed right under a dummy: Touched will not fire for parts already in contact, so check once.
	task.defer(function()
		local dummies = Workspace:FindFirstChild("Dummies")
		if not dummies then
			return
		end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { dummies }
		for _, part in Workspace:GetPartBoundsInBox(pad.CFrame, Vector3.new(4, 6, 6), params) do
			bounce(part, true)
		end
	end)
end

local function fan(player: Player?, at: Vector3, facing: Vector3)
	local dir = flat(facing)
	local model = Instance.new("Model")
	model.Name = "Fan"
	local origin = at + Vector3.new(0, 3.5, 0)
	local frame = CFrame.lookAt(origin, origin + dir)
	local stand = makePart("Stand", Vector3.new(1, 3.5, 1), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	stand.Anchored = true
	stand.CFrame = CFrame.new(at + Vector3.new(0, 1.75, 0))
	stand.Parent = model
	local ring = makePart("Ring", Vector3.new(0.6, 6, 6), Color3.fromRGB(170, 220, 255), Enum.Material.SmoothPlastic)
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.Transparency = 0.4
	ring.CFrame = frame * CFrame.Angles(0, math.rad(90), 0)
	ring.Parent = model
	local blade = makePart("Blade", Vector3.new(0.2, 5, 1), Color3.fromRGB(240, 240, 250), Enum.Material.SmoothPlastic)
	blade.Anchored = true
	blade.CanCollide = false
	blade.CFrame = frame * CFrame.new(0, 0, -0.4)
	blade.Parent = model
	CollectionService:AddTag(blade, "Spinner")
	model.PrimaryPart = stand
	own(player, model, 10)

	local LENGTH, COS_HALF = 45, math.cos(math.rad(28))
	task.spawn(function()
		local started = os.clock()
		while model.Parent and model:GetAttribute("Retiring") ~= true and os.clock() - started < 10 do
			for _, dummy in Blasts.dummiesNear(origin, LENGTH) do
				local chest = dummy:FindFirstChild("UpperTorso") :: BasePart?
				if chest then
					local offset = chest.Position - origin
					local along = offset:Dot(dir)
					if along > 0 and offset.Unit:Dot(dir) > COS_HALF then
						local strength = 1 - along / LENGTH
						DummyControl.push(dummy, (dir + Vector3.new(0, 0.25, 0)) * (5 + 10 * strength), player)
					end
				end
			end
			for _, near in Props.near(origin, LENGTH, model) do
				local along = near.offset:Dot(dir)
				if Blasts.belongsTo(near.prop, player) and along > 0 and near.offset.Unit:Dot(dir) > COS_HALF then
					Props.push(near.prop, dir * (3 + 6 * (1 - along / LENGTH)))
				end
			end
			task.wait(0.2)
		end
	end)
end

local function bowling(player: Player?, at: Vector3, facing: Vector3)
	local dir = flat(facing)
	local ball = makePart("BowlingBall", Vector3.one * 4, Color3.fromRGB(110, 60, 200), Enum.Material.SmoothPlastic)
	ball.Shape = Enum.PartType.Ball
	-- Light enough to bowl a dummy over and roll on, not bulldoze it across the lab.
	ball.CustomPhysicalProperties = PhysicalProperties.new(2, 0.3, 0.2)
	ball.CFrame = CFrame.new(at - dir * 18 + Vector3.new(0, 2.2, 0))
	ball.AssemblyLinearVelocity = dir * 75
	watchImpacts(ball, ball)
	own(player, ball, 7)
end

-- A ball fired from a cannon in a build: a bowling ball or a lighter cannonball.
function ToyService.fireBall(player: Player?, muzzle: CFrame, kind: string)
	local bowlingBall = kind == "Bowling"
	local size = if bowlingBall then 3 else 2
	local ball = makePart("BowlingBall", Vector3.one * size, if bowlingBall then Color3.fromRGB(110, 60, 200) else Color3.fromRGB(40, 40, 46), Enum.Material.SmoothPlastic)
	ball.Shape = Enum.PartType.Ball
	ball.CustomPhysicalProperties = PhysicalProperties.new(if bowlingBall then 2 else 1.2, 0.3, 0.2)
	ball.CFrame = muzzle + muzzle.LookVector * (size / 2)
	ball.AssemblyLinearVelocity = muzzle.LookVector * (if bowlingBall then 70 else 95)
	watchImpacts(ball, ball)
	own(player, ball, 6)
end

-- Fires a cannonball from the player towards the tapped spot, on an arc that lands there.
local function cannon(player: Player?, at: Vector3)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local origin: Vector3
	if root and root:IsA("BasePart") and (root.Position - at).Magnitude < 250 then
		-- From in front of the player, never inside their own head.
		local aim = Vector3.new(at.X - root.Position.X, 0, at.Z - root.Position.Z)
		local ahead = if aim.Magnitude > 0.1 then aim.Unit * 4 else Vector3.zero
		origin = root.Position + Vector3.new(0, 2.5, 0) + ahead
	else
		origin = at + Vector3.new(-24, 14, 0)
	end
	local target = at + Vector3.new(0, 1.5, 0)
	local toTarget = target - origin
	local away = Vector3.new(toTarget.X, 0, toTarget.Z)
	-- Too close: nudge the muzzle back so the ball still has room to fly.
	if away.Magnitude < 8 then
		local back = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
		origin = target - back * 8 + Vector3.new(0, 4, 0)
		toTarget = target - origin
	end
	local flight = math.clamp(toTarget.Magnitude / 95, 0.3, 1.1)
	local velocity = toTarget / flight + Vector3.new(0, 0.5 * Workspace.Gravity * flight, 0)
	local ball = makePart("Cannonball", Vector3.one * 2.2, Color3.fromRGB(38, 38, 46), Enum.Material.SmoothPlastic)
	ball.Shape = Enum.PartType.Ball
	ball.CustomPhysicalProperties = PhysicalProperties.new(6, 0.4, 0.2)
	ball.CFrame = CFrame.lookAt(origin, target)
	ball.AssemblyLinearVelocity = velocity
	watchImpacts(ball, ball)
	own(player, ball, 6)
	FxService.hit(origin, 60, "CannonFire")
end

-- Pads you put down: a spring pad flings whatever steps on it, a banana peel makes it slip.
-- Server-simulated dummies and the pad's own player are judged here; the dummies a client
-- simulates are judged on that client (PropContacts), with the same HitMath.padLaunch.
local lastPadHit: { [Player]: number } = {}
local function watchPad(pad: BasePart, holder: Instance)
	pad.Touched:Connect(function(other)
		if holder:GetAttribute("Retiring") == true then
			return
		end
		local placedBy = Props.ownerOf(holder)
		local dummy = Dummies.of(other)
		if dummy then
			if DummyControl.ownerOf(dummy) ~= nil or not mayHit(dummy, 0.6) then
				return
			end
			local launch = HitMath.padLaunch(pad, other.AssemblyLinearVelocity)
			if launch then
				DummyControl.hit(dummy, other, launch * massOf(dummy), other.Position, nil, placedBy)
				FxService.hit(pad.Position, launch.Magnitude, pad.Name)
			end
			return
		end
		-- Only whoever put the pad down is flung by it: pads are not traps for other players.
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or player ~= placedBy then
			return
		end
		local now = os.clock()
		if lastPadHit[player] and now - lastPadHit[player] < 1 then
			return
		end
		lastPadHit[player] = now
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local velocity = if root and root:IsA("BasePart") then root.AssemblyLinearVelocity else Vector3.zero
		local launch = HitMath.padLaunch(pad, velocity)
		if not launch then
			return
		end
		if pad.Name == "SpringPad" then
			PlayerRagdoll.launch(player, launch)
		else
			PlayerRagdoll.knock(player, launch)
		end
		FxService.hit(pad.Position, launch.Magnitude, pad.Name)
	end)
end

local function springPad(player: Player?, at: Vector3)
	local model = Instance.new("Model")
	model.Name = "SpringPadProp"
	local base = makePart("Base", Vector3.new(5, 0.6, 5), Color3.fromRGB(60, 60, 72), Enum.Material.Metal)
	base.Anchored = true
	base.CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0))
	base.Parent = model
	local coil = makePart("Coil", Vector3.new(1.4, 3.2, 3.2), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
	coil.Shape = Enum.PartType.Cylinder
	coil.Anchored = true
	coil.CanCollide = false
	coil.CFrame = CFrame.new(at + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	coil.Parent = model
	local pad = makePart("SpringPad", Vector3.new(4.4, 0.5, 4.4), Color3.fromRGB(255, 160, 220), Enum.Material.SmoothPlastic)
	pad.Anchored = true
	pad.CFrame = CFrame.new(at + Vector3.new(0, 1.95, 0))
	pad.Parent = model
	model.PrimaryPart = base
	watchPad(pad, model)
	own(player, model, 30)
end

local function banana(player: Player?, at: Vector3, facing: Vector3)
	local spot = at + Vector3.new(0, 0.18, 0)
	local peel = makePart("BananaPeel", Vector3.new(1.6, 0.35, 2.4), Color3.fromRGB(255, 225, 60), Enum.Material.SmoothPlastic)
	peel.Anchored = true
	peel.CFrame = CFrame.lookAt(spot, spot + flat(facing))
	-- Slippery under anything resting on it, too.
	peel.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.3, 100, 1)
	watchPad(peel, peel)
	own(player, peel, 30)
end

------------------------------------------------------------------------------------------------
-- Blasts

-- A bomb that blinks (faster and faster when `waits` speeds up) and then goes off where it is.
local function fuse(bomb: BasePart, waits: { number }, colors: { Color3 }, goOff: () -> ())
	task.spawn(function()
		for i, t in waits do
			task.wait(t)
			if not bomb.Parent or bomb:GetAttribute("Retiring") == true then
				return
			end
			if bomb:GetAttribute("Chain") == true then
				break -- set off by a blast next to it
			end
			bomb.Color = colors[i % 2 + 1]
		end
		if bomb.Parent and bomb:GetAttribute("Retiring") ~= true then
			goOff()
		end
	end)
end

local function tnt(player: Player?, at: Vector3)
	local crate = makePart("TNT", Vector3.new(2.4, 2.4, 2.4), Color3.fromRGB(205, 45, 45), Enum.Material.WoodPlanks)
	local placedAt = at + Vector3.new(0, 1.3, 0)
	crate.CFrame = CFrame.new(placedAt)
	own(player, crate, 10)
	fuse(crate, table.create(6, 0.25), { Color3.fromRGB(205, 45, 45), Color3.fromRGB(255, 240, 200) }, function()
		local center = Blasts.clampTo(crate.Position, placedAt, BOMB_DRIFT)
		crate:Destroy()
		Blasts.explode(center, crate, player)
	end)
end

local function firecracker(player: Player?, at: Vector3)
	Blasts.blast(at + Vector3.new(0, 0.5, 0), BLASTS.Firecracker, nil, player)
end

local function shockwave(player: Player?, at: Vector3)
	Blasts.blast(at + Vector3.new(0, 1, 0), BLASTS.Shockwave, nil, player)
end

-- A big round bomb with a fizzing fuse; it blinks faster and faster, then the biggest blast.
local function bigBoom(player: Player?, at: Vector3)
	local bomb = makePart("BigBoom", Vector3.one * 4, Color3.fromRGB(30, 30, 38), Enum.Material.SmoothPlastic)
	bomb.Shape = Enum.PartType.Ball
	local placedAt = at + Vector3.new(0, 2.1, 0)
	bomb.CFrame = CFrame.new(placedAt)
	local spark = Instance.new("Sparkles")
	spark.SparkleColor = Color3.fromRGB(255, 200, 80)
	spark.Parent = bomb
	own(player, bomb, 10)
	fuse(bomb, { 0.3, 0.25, 0.2, 0.15, 0.12, 0.1, 0.08, 0.06 }, { Color3.fromRGB(30, 30, 38), Color3.fromRGB(255, 80, 40) }, function()
		local center = Blasts.clampTo(bomb.Position, placedAt, BOMB_DRIFT)
		bomb:Destroy()
		Blasts.blast(center, BLASTS.BigBoom, bomb, player)
	end)
end

-- Sticks to the tapped limb, beeps for a moment, then goes off right there.
local function stickyBomb(player: Player?, dummy: Model, part: BasePart, position: Vector3)
	local bomb = makePart("StickyBomb", Vector3.new(1.1, 1.1, 1.1), Color3.fromRGB(90, 220, 90), Enum.Material.Neon)
	bomb.Shape = Enum.PartType.Ball
	bomb.CFrame = CFrame.new(position)
	Props.stickOn(player, part, bomb)
	FxService.hit(position, 6, "StickyBomb")
	fuse(bomb, table.create(6, 0.25), { Color3.fromRGB(90, 220, 90), Color3.fromRGB(255, 60, 60) }, function()
		local center = Blasts.clampTo(bomb.Position, position, STICKY_DRIFT)
		bomb:Destroy()
		if dummy.Parent then
			-- Whoever simulates the dummy could carry it anywhere: far from where the bomb was stuck,
			-- it blows up dummies and props but never knocks its player over.
			Blasts.blast(center, BLASTS.StickyBomb, nil, player, (center - position).Magnitude > STICKY_HOME)
		end
	end)
end

-- The big ones (10 Nov 2026). A grenade: thrown, a short fuse, a TNT-sized blast.
-- Round 5: thrown from the hand in an arc, it bounces and rolls, a countdown over it (3, 2, 1),
-- then the blast where it came to rest (never further than GRENADE_DRIFT from where it was aimed).
ToyService.GRENADE_FUSE = 2.4
local GRENADE_DRIFT = 14
local function grenade(player: Player?, at: Vector3)
	local nade = makePart("Grenade", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(70, 96, 58), Enum.Material.Metal)
	nade.Shape = Enum.PartType.Ball
	nade.CustomPhysicalProperties = PhysicalProperties.new(2, 0.4, 0.55, 1, 1)
	local character = player and player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("HumanoidRootPart"))
	local target = at + Vector3.new(0, 0.6, 0)
	local from = if hand and hand:IsA("BasePart") then hand.Position + Vector3.new(0, 1, 0) else target + Vector3.new(0, 4, 0)
	nade.CFrame = CFrame.new(from)
	-- The real grenade's look on the ball (the held model's body), when the place has it.
	local held = N7Models.source("Weapons", "Grenade")
	local look = held and held:FindFirstChild("Body")
	if look then
		nade.Transparency = 1
		local copy = look:Clone()
		for _, d in copy:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.Massless = true
				d.Anchored = false
				local w = Instance.new("WeldConstraint")
				w.Part0 = nade
				w.Part1 = d
				w.Parent = d
			end
		end
		copy:PivotTo(nade.CFrame)
		copy.Parent = nade
	end
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(40, 40)
	tag.StudsOffset = Vector3.new(0, 1.6, 0)
	tag.AlwaysOnTop = true
	local count = Instance.new("TextLabel")
	count.Size = UDim2.fromScale(1, 1)
	count.BackgroundTransparency = 1
	count.TextScaled = true
	count.Font = Enum.Font.GothamBlack
	count.TextColor3 = Color3.fromRGB(255, 80, 60)
	count.TextStrokeTransparency = 0
	count.Text = "3"
	count.Parent = tag
	tag.Parent = nade
	own(player, nade, 10)
	-- An arc that lands at the aim (the flight time from the distance).
	local d = target - from
	local t = math.clamp(d.Magnitude / 45, 0.45, 1.1)
	nade.AssemblyLinearVelocity = d / t + Vector3.new(0, Workspace.Gravity * t / 2, 0)
	nade.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
	FxService.hit(from, 8, "Grenade")
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < ToyService.GRENADE_FUSE do
			if not nade.Parent or nade:GetAttribute("Retiring") == true then
				return
			end
			if nade:GetAttribute("Chain") == true then
				break
			end
			local left = ToyService.GRENADE_FUSE - (os.clock() - started)
			count.Text = tostring(math.max(1, math.ceil(left / (ToyService.GRENADE_FUSE / 3))))
			task.wait(0.1)
		end
		if nade.Parent and nade:GetAttribute("Retiring") ~= true then
			local center = Blasts.clampTo(nade.Position, target, GRENADE_DRIFT)
			nade:Destroy()
			Blasts.explode(center, nade, player)
		end
	end)
end

-- C4 stuck on a dummy: beeps, then the big blast right there.
local function c4(player: Player?, dummy: Model, part: BasePart, position: Vector3)
	local brick = makePart("C4", Vector3.new(1.4, 0.6, 1), Color3.fromRGB(200, 190, 150), Enum.Material.Plastic)
	brick.CFrame = CFrame.new(position)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 40, 40)
	light.Range = 6
	light.Parent = brick
	Props.stickOn(player, part, brick)
	FxService.hit(position, 6, "StickyBomb")
	-- Round 5: a remote charge. It blinks and waits; the player's next C4 press (anywhere: the
	-- client's DETONATE, ToyService.detonate) sets off every charge they have out. Unused, it goes
	-- off by itself after C4_WAIT s.
	local goOff: () -> ()
	function goOff()
		-- (Off its player's armed list however it goes: the DETONATE state never goes stale: review fix.)
		local list = player and armedC4[player]
		if player and list then
			local i = table.find(list, goOff)
			if i then
				table.remove(list, i)
			end
			if #list == 0 then
				armedC4[player] = nil
			end
			player:SetAttribute("C4Armed", if #list > 0 then #list else nil)
		end
		if not brick.Parent or brick:GetAttribute("Retiring") == true then
			return
		end
		local center = Blasts.clampTo(brick.Position, position, STICKY_DRIFT)
		brick:Destroy()
		if dummy.Parent then
			Blasts.blast(center, BLASTS.BigBoom, nil, player, (center - position).Magnitude > STICKY_HOME)
		end
	end
	if player then
		local list = armedC4[player] or {}
		armedC4[player] = list
		table.insert(list, goOff)
		player:SetAttribute("C4Armed", #list)
	end
	task.spawn(function()
		local started = os.clock()
		local on = false
		-- (Nobody's C4, from an event or a test, has no detonator: it goes off by itself soon.)
		local waitFor = if player then ToyService.C4_WAIT else 2
		while brick.Parent and os.clock() - started < waitFor do
			on = not on
			brick.Color = if on then Color3.fromRGB(255, 60, 60) else Color3.fromRGB(200, 190, 150)
			light.Enabled = on
			task.wait(0.5)
		end
		goOff()
	end)
end

-- Round 5: sets off every C4 a player has out (their second press). Returns how many went off.
ToyService.C4_WAIT = 20
function ToyService.detonate(player: Player): number
	local list = armedC4[player]
	armedC4[player] = nil
	player:SetAttribute("C4Armed", nil)
	if not list then
		return 0
	end
	local copy = table.clone(list)
	for i, goOff in copy do
		task.delay((i - 1) * 0.12, goOff)
	end
	return #copy
end

-- The rocket launcher: a rocket streaks from the shooter to where they aimed, then a big blast.
local function rpg(player: Player?, at: Vector3)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local from = if root and root:IsA("BasePart") then root.Position + Vector3.new(0, 1.5, 0) else at + Vector3.new(0, 30, 0)
	local target = at + Vector3.new(0, 1, 0)
	local rocketPart = makePart("RPGRocket", Vector3.new(0.6, 0.6, 2.4), Color3.fromRGB(110, 120, 80), Enum.Material.Metal)
	rocketPart.Anchored = true
	rocketPart.CanCollide = false
	rocketPart.CFrame = CFrame.lookAt(from, target)
	local flame = Instance.new("Fire")
	flame.Size = 3
	flame.Heat = 4
	flame.Parent = rocketPart
	-- Round 5: a white smoke trail behind it (a Trail between two attachments, left hanging a moment).
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.3, 1.2)
	a0.Parent = rocketPart
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.3, 1.2)
	a1.Parent = rocketPart
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 1.6
	trail.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235), Color3.fromRGB(150, 150, 150))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.WidthScale = NumberSequence.new(0.6, 2.2)
	trail.FaceCamera = true
	trail.Parent = rocketPart
	local smoke = Instance.new("Smoke")
	smoke.Size = 1.5
	smoke.RiseVelocity = 1
	smoke.Opacity = 0.4
	smoke.Parent = rocketPart
	rocketPart.Parent = Workspace
	FxService.hit(from, 60, "CannonFire", if player then player.UserId else nil)
	local distance = (target - from).Magnitude
	local flight = math.clamp(distance / 160, 0.15, 0.9)
	local started = os.clock()
	task.spawn(function()
		while os.clock() - started < flight and rocketPart.Parent do
			local t = (os.clock() - started) / flight
			rocketPart.CFrame = CFrame.lookAt(from:Lerp(target, t), target)
			task.wait()
		end
		rocketPart:Destroy()
		Blasts.blast(target, BLASTS.BigBoom, nil, player)
	end)
end

-- The nuke: a bomb falls from the sky, three blasts and a shockwave: the end of the lab.
local function nuke(player: Player?, at: Vector3)
	if player then
		BadgeAwards.award(player, "Nuke")
	end
	local bomb = makePart("Nuke", Vector3.new(3.2, 6.5, 3.2), Color3.fromRGB(240, 220, 60), Enum.Material.Metal)
	bomb.Anchored = true
	bomb.CanCollide = false
	local sky = at + Vector3.new(0, 60, 0)
	bomb.CFrame = CFrame.new(sky)
	bomb.Parent = Workspace
	FxService.bombFall(at, 1.4)
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < 1.4 and bomb.Parent do
			local t = (os.clock() - started) / 1.4
			bomb.CFrame = CFrame.new(sky:Lerp(at + Vector3.new(0, 3, 0), t * t))
			task.wait()
		end
		bomb:Destroy()
		local center = at + Vector3.new(0, 2, 0)
		Blasts.blast(center, BLASTS.BigBoom, nil, player)
		task.wait(0.25)
		for _, off in { Vector3.new(9, 0, 4), Vector3.new(-8, 0, -6) } do
			Blasts.blast(center + off, BLASTS.BigBoom, nil, player)
			task.wait(0.2)
		end
		Blasts.blast(center, BLASTS.Shockwave, nil, player)
		ToyService.mushroom(center)
	end)
end

-- Round 5: the nuke's mushroom cloud: a stem rising, a cap swelling on top, glowing at first, then
-- grey smoke that fades out (anchored, nothing touches it).
function ToyService.mushroom(at: Vector3)
	local folder = Instance.new("Model")
	folder.Name = "Mushroom"
	local function piece(shape: Enum.PartType, color: Color3): Part
		local p = Instance.new("Part")
		p.Shape = shape
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Size = Vector3.new(2, 2, 2)
		p.CFrame = CFrame.new(at)
		p.Parent = folder
		return p
	end
	local stem = piece(Enum.PartType.Cylinder, Color3.fromRGB(255, 150, 60))
	stem.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	local cap = piece(Enum.PartType.Ball, Color3.fromRGB(255, 190, 90))
	local ring = piece(Enum.PartType.Cylinder, Color3.fromRGB(255, 120, 50))
	ring.CFrame = CFrame.new(at + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	folder.Parent = Workspace
	local rise = TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(stem, rise, { Size = Vector3.new(26, 7, 7), CFrame = CFrame.new(at + Vector3.new(0, 13, 0)) * CFrame.Angles(0, 0, math.rad(90)) }):Play()
	TweenService:Create(cap, rise, { Size = Vector3.new(26, 16, 26), CFrame = CFrame.new(at + Vector3.new(0, 28, 0)) }):Play()
	TweenService:Create(ring, rise, { Size = Vector3.new(2, 40, 40) }):Play()
	task.delay(1.6, function()
		local cool = TweenInfo.new(4, Enum.EasingStyle.Linear)
		for _, p in folder:GetChildren() do
			if p:IsA("BasePart") then
				TweenService:Create(p, TweenInfo.new(1.2), { Color = Color3.fromRGB(110, 105, 100) }):Play()
				task.delay(1.2, function()
					if p.Parent then
						p.Material = Enum.Material.SmoothPlastic
						TweenService:Create(p, cool, { Transparency = 1 }):Play()
					end
				end)
			end
		end
		task.delay(6, function()
			folder:Destroy()
		end)
	end)
end

------------------------------------------------------------------------------------------------
-- Gadgets

local function rocket(player: Player?, dummy: Model, part: BasePart, position: Vector3)
	local mass = massOf(dummy)
	Props.unstick(dummy, "Rocket") -- one at a time: a second rocket replaces the first
	-- Knock it over first so it flies limp and flailing.
	DummyControl.hit(dummy, part, Vector3.new(0, 35, 0) * mass, position, nil, player)
	FxService.hit(position, 40, "Rocket", if player then player.UserId else nil)
	local body = makePart("Rocket", Vector3.new(0.8, 2.4, 0.8), Color3.fromRGB(240, 110, 40), Enum.Material.SmoothPlastic)
	body.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(-15), 0, 0)
	local attachment = Instance.new("Attachment")
	attachment.Parent = body
	local thrust = Instance.new("VectorForce")
	thrust.Attachment0 = attachment
	thrust.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	-- A real push (not a limit), against the gravity of the moment: it always climbs at about
	-- nine tenths of whatever gravity is (gently in Zero-G, like everything else then).
	local function aim()
		thrust.Force = Vector3.new(0, mass * Workspace.Gravity * 1.9, 0)
	end
	aim()
	thrust.Parent = body
	local gravityChanged = Workspace:GetPropertyChangedSignal("Gravity"):Connect(aim)
	body.Destroying:Once(function()
		gravityChanged:Disconnect()
	end)
	local flame = Instance.new("Fire")
	flame.Size = 3
	flame.Heat = 6
	flame.Color = Color3.fromRGB(255, 170, 60)
	flame.SecondaryColor = Color3.fromRGB(255, 240, 120)
	flame.Parent = body
	Props.stickOn(player, part, body)
	task.delay(2.6, function()
		if body.Parent then
			local p = body.Position
			body:Destroy()
			FxService.hit(p, 90, "TNT", if player then player.UserId else nil)
		end
	end)
end

-- A balloon on a string: the dummy goes limp and floats gently up, then the balloon pops.
local FLOAT_SPEED = 7 -- studs/s up
local FLOAT_TIME = 4
local function balloon(player: Player?, dummy: Model, part: BasePart, position: Vector3)
	local mass = massOf(dummy)
	Props.unstick(dummy, "Balloon")
	Props.unstick(dummy, "BalloonString")
	DummyControl.hit(dummy, part, Vector3.new(0, 12, 0) * mass, position, nil, player)
	local top = part.Position + Vector3.new(0, 4.5, 0)
	local body = makePart("Balloon", Vector3.new(2.6, 3, 2.6), Color3.fromRGB(255, 90, 170), Enum.Material.SmoothPlastic)
	body.Shape = Enum.PartType.Ball
	body.CFrame = CFrame.new(top)
	local cord = makePart("BalloonString", Vector3.new(0.1, 3.2, 0.1), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
	cord.CFrame = CFrame.new((top + part.Position) / 2)
	local attachment = Instance.new("Attachment")
	attachment.Parent = body
	local float = Instance.new("LinearVelocity")
	float.Attachment0 = attachment
	float.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	float.LineDirection = Vector3.yAxis
	float.LineVelocity = FLOAT_SPEED
	float.RelativeTo = Enum.ActuatorRelativeTo.World
	float.MaxForce = mass * NORMAL_GRAVITY * 1.6
	float.Parent = body
	Props.stickOn(player, part, body)
	Props.stickOn(player, part, cord, false) -- the string belongs to the balloon: one prop
	FxService.hit(position, 8, "Balloon")
	task.delay(FLOAT_TIME, function()
		if body.Parent then
			local p = body.Position
			body:Destroy()
			FxService.hit(p, 30, "BalloonPop")
		end
		if cord.Parent then
			cord:Destroy()
		end
	end)
end

-- Bzzt: a jolt to the head knocks the dummy out cold for a moment.
local ZAP_SPEED = 36 -- above ActiveRagdoll's KO speed for a head hit
local function zap(player: Player?, dummy: Model, part: BasePart)
	local head = dummy:FindFirstChild("Head")
	local target = if head and head:IsA("BasePart") then head else part
	local side = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	local dir = (if side.Magnitude > 0.01 then side.Unit * 0.5 else Vector3.zero) + Vector3.new(0, 0.3, 0)
	DummyControl.hit(dummy, target, dir.Unit * ZAP_SPEED * massOf(dummy), target.Position, nil, player)
	FxService.hit(target.Position, 30, "Zap")
end

-- A black hole: pulls dummies and loose props in for a few seconds, then spits them out.
local HOLE_RADIUS = 30
local HOLE_TIME = 3.2
local HOLE_PULL = 9 -- studs/s added per tick towards the middle (more when close)
local HOLE_TICK = 0.15 -- s
local function blackHole(player: Player?, at: Vector3)
	local center = at + Vector3.new(0, 6, 0)
	local core = makePart("BlackHole", Vector3.one * 3, Color3.fromRGB(10, 6, 20), Enum.Material.Neon)
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = false
	core.CFrame = CFrame.new(center)
	local ring = makePart("BlackHoleRing", Vector3.new(0.4, 9, 9), Color3.fromRGB(150, 90, 255), Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Transparency = 0.35
	ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = core
	CollectionService:AddTag(ring, "Spinner")
	own(player, core, HOLE_TIME + 1)
	FxService.hit(center, 20, "BlackHole")
	task.spawn(function()
		local started = os.clock()
		local knocked: { [Model]: boolean } = {}
		while core.Parent and core:GetAttribute("Retiring") ~= true and os.clock() - started < HOLE_TIME do
			for _, dummy in Blasts.dummiesNear(center, HOLE_RADIUS) do
				local pelvis = dummy:FindFirstChild("LowerTorso") :: BasePart?
				local offset = if pelvis then center - pelvis.Position else Vector3.zero
				local distance = offset.Magnitude
				if pelvis and distance > 2.5 then
					if not knocked[dummy] then
						knocked[dummy] = true
						DummyControl.hit(dummy, pelvis, offset.Unit * 18 * massOf(dummy), pelvis.Position, nil, player)
					end
					local pull = HOLE_PULL * (1.3 - distance / HOLE_RADIUS)
					-- Mostly cancels gravity too, so bodies are sucked up off the floor into the
					-- middle instead of being dragged along the ground.
					local float = Vector3.new(0, Workspace.Gravity * HOLE_TICK * 0.85, 0)
					DummyControl.push(dummy, offset.Unit * pull + float, player)
				end
			end
			for _, near in Props.near(center, HOLE_RADIUS, core) do
				if near.offset.Magnitude > 2.5 and Blasts.belongsTo(near.prop, player) then
					Props.push(near.prop, -near.offset.Unit * HOLE_PULL)
				end
			end
			task.wait(HOLE_TICK)
		end
		if core.Parent then
			core:Destroy()
			-- Everything that fell in comes back out.
			Blasts.blast(center, BLASTS.Shockwave, nil, player)
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Dispatch: what each catalog tool does, by kind (Shared/Toys says which kind each one is). A tool
-- in the catalog without an entry here is refused (and T21 fails).

type PlaceFn = (player: Player?, at: Vector3, facing: Vector3) -> ()
type DummyFn = (player: Player?, dummy: Model, part: BasePart, position: Vector3) -> ()

------------------------------------------------------------------------------------------------
-- Phase H: the unlockables

-- Slime: a big slippery puddle (it slips like a banana peel: same name, so the pads' rules and
-- every client's contact code treat it the same way), green and see-through.
-- The slime cannon: a glob of slime flies from the player's hands to where they aimed and splats
-- there into a slippery puddle (the glob is a look; the puddle is what knocks them over).
local SLIME_FLIGHT = 0.35 -- s in the air
local function slimePuddle(player: Player?, at: Vector3)
	local puddle = makePart("BananaPeel", Vector3.new(7, 0.2, 7), Color3.fromRGB(110, 230, 80), Enum.Material.SmoothPlastic)
	puddle.Anchored = true
	puddle.Transparency = 0.15
	puddle.CFrame = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	puddle.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0, 100, 1)
	puddle:SetAttribute("Look", "Slime")
	watchPad(puddle, puddle)
	own(player, puddle, 30)
	FxService.hit(at, 20, "BalloonPop")
end

local function slime(player: Player?, at: Vector3, _facing: Vector3)
	local character = player and player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("HumanoidRootPart"))
	if not hand or not hand:IsA("BasePart") then
		slimePuddle(player, at)
		return
	end
	local glob = makePart("SlimeGlob", Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(110, 230, 80), Enum.Material.Neon)
	glob.Shape = Enum.PartType.Ball
	glob.Anchored = true
	glob.CanCollide = false
	glob.CanQuery = false
	glob.CanTouch = false
	glob.Transparency = 0.1
	local from = hand.Position
	local to = at + Vector3.new(0, 0.6, 0)
	glob.CFrame = CFrame.new(from)
	glob.Parent = Workspace
	-- An arc: up and over, then down onto the spot (a few steps, so it reads as a lob).
	task.spawn(function()
		local steps = 7
		local peak = math.clamp((to - from).Magnitude * 0.18, 1.5, 8)
		for i = 1, steps do
			local t = i / steps
			local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * peak, 0)
			glob.CFrame = CFrame.new(p)
			task.wait(SLIME_FLIGHT / steps)
		end
		glob:Destroy()
		slimePuddle(player, at)
	end)
end

-- Float: no gravity in a bubble for a few seconds: the dummies in it drift up and tumble.
local FLOAT_RADIUS = 18
local FLOAT_BUBBLE_TIME = 5
local FLOAT_TICK = 0.2
local floatedAt: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any -- (overlapping bubbles lift a body once a tick)
local function floatBubble(player: Player?, at: Vector3, _facing: Vector3)
	local centre = at + Vector3.new(0, 4, 0)
	local bubble = makePart("FloatBubble", Vector3.one * FLOAT_RADIUS * 2, Color3.fromRGB(140, 200, 255), Enum.Material.ForceField)
	bubble.Shape = Enum.PartType.Ball
	bubble.Anchored = true
	bubble.CanCollide = false
	bubble.CanQuery = false
	bubble.CanTouch = false
	bubble.Transparency = 0.2
	bubble.CFrame = CFrame.new(centre)
	own(player, bubble, FLOAT_BUBBLE_TIME + 0.5)
	FxService.hit(centre, 40, "BlackHole")
	local g = Workspace.Gravity
	task.spawn(function()
		local ends = os.clock() + FLOAT_BUBBLE_TIME
		while os.clock() < ends and bubble.Parent do
			local now = os.clock()
			for _, dummy in Blasts.dummiesNear(centre, FLOAT_RADIUS) do
				-- Gravity cancelled and a little more: up they go, slowly, turning over (once a
				-- tick however many bubbles overlap: two never fling a body).
				if now - (floatedAt[dummy] or -math.huge) >= FLOAT_TICK * 0.9 then
					floatedAt[dummy] = now
					local spin = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 2
					DummyControl.nudge(dummy, Vector3.new(0, g * FLOAT_TICK * 1.06, 0) + spin)
				end
			end
			task.wait(FLOAT_TICK)
		end
		if bubble.Parent then
			bubble:Destroy()
		end
	end)
end

-- Slow-mo: a bubble where everything moves in slow motion for a while (physics cannot be slowed
-- for one spot on Roblox, so bodies in it lose most of their speed and fall at a crawl: everyone
-- in the server sees the same slow tumble).
local SLOWMO_RADIUS = 16
local SLOWMO_TIME = 6
local SLOWMO_TICK = 0.1
local SLOWMO_KEEP = 0.55 -- of a body's speed kept each tick (the rest is slowed away)
local SLOWMO_FALL = 0.85 -- of gravity cancelled
local slowedAt: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any -- (overlapping bubbles slow a body once a tick)
local function slowmo(player: Player?, at: Vector3, _facing: Vector3)
	local centre = at + Vector3.new(0, 4, 0)
	local bubble = makePart("SlowmoBubble", Vector3.one * SLOWMO_RADIUS * 2, Color3.fromRGB(200, 140, 255), Enum.Material.ForceField)
	bubble.Shape = Enum.PartType.Ball
	bubble.Anchored = true
	bubble.CanCollide = false
	bubble.CanQuery = false
	bubble.CanTouch = false
	bubble.Transparency = 0.25
	bubble.CFrame = CFrame.new(centre)
	-- v4 C5: the clients draw the slow motion (Client/SlowMotion) and slow the bodies they simulate.
	bubble:SetAttribute("Radius", SLOWMO_RADIUS)
	bubble:SetAttribute("Ends", Workspace:GetServerTimeNow() + SLOWMO_TIME)
	CollectionService:AddTag(bubble, "SlowmoBubble")
	local clientSide = GameConfig.SLOWMO_V2 == true
	own(player, bubble, SLOWMO_TIME + 0.5)
	FxService.hit(centre, 30, "BlackHole")
	local g = Workspace.Gravity
	task.spawn(function()
		local ends = os.clock() + SLOWMO_TIME
		while os.clock() < ends and bubble.Parent do
			local now = os.clock()
			for _, dummy in Blasts.dummiesNear(centre, SLOWMO_RADIUS) do
				local pelvis = dummy:FindFirstChild("LowerTorso") :: BasePart?
				if pelvis and not (clientSide and ((dummy:GetAttribute("SimulatedBy") :: number?) or 0) ~= 0) and now - (slowedAt[dummy] or -math.huge) >= SLOWMO_TICK * 0.9 then
					slowedAt[dummy] = now
					local v = pelvis.AssemblyLinearVelocity
					local slowed = -v * (1 - SLOWMO_KEEP) + Vector3.new(0, g * SLOWMO_TICK * SLOWMO_FALL, 0)
					DummyControl.nudge(dummy, slowed) -- (names nobody: no takedown changes hands)
				end
			end
			task.wait(SLOWMO_TICK)
		end
		if bubble.Parent then
			bubble:Destroy()
		end
	end)
end

-- Portals (our own look: pink and cyan rings on a dark purple gun): a player's first shot opens the
-- pink one, the next the cyan one (then pink again,
-- moving it). Whatever dummy comes within reach of one comes out of the other, flying the way that
-- one faces at the speed it went in (at least a good push).
local PORTAL_REACH = 3.6
local PORTAL_TIME = 45
local PORTAL_MIN_SPEED = 28
local portals: { [Player | string]: { a: BasePart?, b: BasePart?, nextIsB: boolean } } = {}
local portalCooldown: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local function portal(player: Player?, at: Vector3, facing: Vector3)
	local key: Player | string = player or "lab"
	local pair = portals[key] or { a = nil, b = nil, nextIsB = false }
	portals[key] = pair
	local isB = pair.nextIsB
	pair.nextIsB = not isB
	local old = if isB then pair.b else pair.a
	if old and old.Parent then
		old:Destroy()
	end
	local look = -flat(facing)
	if look.Magnitude < 0.1 then
		look = Vector3.zAxis
	end
	local centre = at + Vector3.new(0, 4, 0)
	-- (V11 B6, owner: "much nicer portals", inspired by the green swirl look, our own art): a green field with
	-- a pale swirling core and a darker rim, swirl and spark particles, a green light, and it opens from a
	-- point with a whoosh. A is a little more lime than B, so you can tell them apart. No neon.
	local green = if isB then Color3.fromRGB(70, 205, 70) else Color3.fromRGB(120, 225, 50)
	local cf = CFrame.lookAt(centre, centre + look) * CFrame.Angles(0, math.rad(90), 0) -- (a cylinder faces along X)
	local ring = makePart(if isB then "PortalB" else "PortalA", Vector3.new(0.3, 7.4, 7.4), green, Enum.Material.SmoothPlastic)
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.CFrame = cf
	local layers: { { part: BasePart, size: Vector3 } } = { { part = ring, size = ring.Size } }
	for _, spec in { { "Rim", 0.22, 8.2, Color3.fromRGB(35, 120, 40) }, { "Core", 0.38, 5.2, Color3.fromRGB(200, 255, 140) }, { "Eye", 0.44, 2.6, Color3.fromRGB(235, 255, 200) } } do
		local p = makePart("Portal" .. spec[1], Vector3.new(spec[2], spec[3], spec[3]), spec[4], Enum.Material.SmoothPlastic)
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = cf
		p.Parent = ring
		table.insert(layers, { part = p, size = p.Size })
	end
	local swirl = Instance.new("ParticleEmitter")
	swirl.Name = "Swirl"
	swirl.Color = ColorSequence.new(Color3.fromRGB(170, 255, 110), Color3.fromRGB(40, 150, 40))
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 0.4) })
	swirl.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	swirl.Rotation = NumberRange.new(0, 360)
	swirl.RotSpeed = NumberRange.new(160, 260)
	swirl.Speed = NumberRange.new(0.2, 0.8)
	swirl.Lifetime = NumberRange.new(0.5, 0.9)
	swirl.Rate = 45
	swirl.LightEmission = 0.4
	swirl.Shape = Enum.ParticleEmitterShape.Disc
	swirl.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	swirl.Parent = ring
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Color = ColorSequence.new(Color3.fromRGB(220, 255, 150))
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
	sparks.Speed = NumberRange.new(6, 13)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 3
	sparks.Acceleration = Vector3.new(0, -12, 0)
	sparks.Lifetime = NumberRange.new(0.35, 0.8)
	sparks.Rate = 22
	sparks.LightEmission = 1
	sparks.Parent = ring
	local light = Instance.new("PointLight")
	light.Color = green
	light.Range = 14
	light.Brightness = 1.6
	light.Parent = ring
	-- Opens from a point.
	for _, l in layers do
		local full = l.size
		l.part.Size = Vector3.new(full.X, 0.2, 0.2)
		TweenService:Create(l.part, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = full }):Play()
	end
	sparks:Emit(40)
	own(player, ring, PORTAL_TIME)
	if isB then
		pair.b = ring
	else
		pair.a = ring
	end
	FxService.hit(centre, 20, "Zap")
end

function ToyService.resetPortalsForTest()
	for _, pair in portals do
		for _, p in { pair.a, pair.b } do
			if p and p.Parent then
				p:Destroy()
			end
		end
	end
	table.clear(portals)
end

-- The portals at work, ten times a second.
local function portalTick()
	for key, pair in portals do
		local a, b = pair.a, pair.b
		if (not a or not a.Parent) and (not b or not b.Parent) then
			portals[key] = nil
		elseif a and b and a.Parent and b.Parent then
			for _, from in { a, b } do
				local to = if from == a then b else a
				for _, dummy in Blasts.dummiesNear(from.Position, PORTAL_REACH) do
					local now = os.clock()
					if not portalCooldown[dummy] or now - portalCooldown[dummy] > 1.2 then
						portalCooldown[dummy] = now
						local pelvis = dummy:FindFirstChild("LowerTorso") :: BasePart?
						if pelvis then
							local speed = math.max(pelvis.AssemblyLinearVelocity.Magnitude, PORTAL_MIN_SPEED)
							-- (The exit's face looks along its CFrame's right vector: the X axis.)
							local out = to.CFrame.RightVector
							local exit = to.Position + out * 3
							DummyControl.move(dummy, CFrame.lookAt(exit, exit + out)) -- (as it is: nothing mended)
							local by = if typeof(key) == "Instance" then key :: Player else nil
							task.defer(function()
								local p = dummy:FindFirstChild("LowerTorso") :: BasePart?
								if p and dummy.Parent then
									DummyControl.hit(dummy, p, (out + Vector3.new(0, 0.25, 0)).Unit * speed * massOf(dummy), p.Position, nil, by)
								end
							end)
							FxService.hit(to.Position, 20, "Zap")
						end
					end
				end
				-- (V11 B6: players walk through too, keeping their speed out of the other one.)
				for _, pl in Players:GetPlayers() do
					local ch = pl.Character
					local root = ch and ch:FindFirstChild("HumanoidRootPart")
					if root and root:IsA("BasePart") and (root.Position - from.Position).Magnitude <= PORTAL_REACH + 0.8 then
						local now = os.clock()
						if not portalCooldown[ch :: Model] or now - portalCooldown[ch :: Model] > 1.2 then
							portalCooldown[ch :: Model] = now
							local out = to.CFrame.RightVector
							local exit = to.Position + out * 3.5
							local speed = math.max(root.AssemblyLinearVelocity.Magnitude, 16)
							;(ch :: Model):PivotTo(CFrame.lookAt(exit, exit + Vector3.new(out.X, 0, out.Z)))
							root.AssemblyLinearVelocity = out * speed
							FxService.hit(to.Position, 20, "Zap")
						end
					end
				end
			end
		end
	end
end

-- A ray that sees only the world (no bodies, props or builds): where the floor is under a body.
local function floorParams(dummy: Model): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = { dummy }
	for _, name in { "Dummies", "Props", "Builds" } do
		local f = Workspace:FindFirstChild(name)
		if f then
			table.insert(skip, f)
		end
	end
	params.FilterDescendantsInstances = skip
	return params
end

-- Shrink: half size for a while (and half the heft: a shrunk dummy flies further).
local SHRINK_TIME = 12
local function shrink(player: Player?, dummy: Model, _part: BasePart, position: Vector3): string?
	if dummy:GetAttribute("Shrunk") == true then
		return "Already"
	end
	if dummy:GetAttribute("Chicken") == true then
		return "Spell"
	end
	Dummies.setBlame(dummy, if player then player.UserId else 0)
	local mass = (dummy:GetAttribute("Mass") :: number?) or 10
	local ok = pcall(function()
		dummy:ScaleTo(0.5)
	end)
	if not ok then
		return
	end
	dummy:SetAttribute("Shrunk", true)
	dummy:SetAttribute("Mass", mass * 0.125)
	FxService.hit(position, 10, "Zap")
	task.delay(SHRINK_TIME, function()
		if dummy.Parent and dummy:GetAttribute("Shrunk") == true then
			-- Back to full size standing where it is, lifted so its feet are not under the floor.
			local before = dummy:GetPivot()
			pcall(function()
				dummy:ScaleTo(1)
			end)
			local _, size = dummy:GetBoundingBox()
			local pelvisNow = dummy:FindFirstChild("LowerTorso") :: BasePart?
			if pelvisNow then
				local floor = Workspace:Raycast(pelvisNow.Position + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), floorParams(dummy))
				if floor then
					local lowest = pelvisNow.Position.Y - size.Y / 2
					if lowest < floor.Position.Y then
						DummyControl.move(dummy, before + Vector3.new(0, floor.Position.Y - lowest + 0.2, 0))
					end
				end
			end
			dummy:SetAttribute("Mass", mass)
			dummy:SetAttribute("Shrunk", nil)
			local pelvis = dummy:FindFirstChild("LowerTorso") :: BasePart?
			if pelvis then
				FxService.hit(pelvis.Position, 10, "Heal")
			end
		end
	end)
end

-- Chicken: white feathers, a red comb, a beak and wings for a while (DummyLife: BAWK!).
local CHICKEN_TIME = 15
local CHICKEN_BODY = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg" }
local unchicken: { [Model]: () -> () } = {}
local function chicken(player: Player?, dummy: Model, _part: BasePart, position: Vector3): string?
	if dummy:GetAttribute("Chicken") == true then
		return "Already"
	end
	if dummy:GetAttribute("Shrunk") == true then
		return "Spell"
	end
	Dummies.setBlame(dummy, if player then player.UserId else 0)
	local before: { [BasePart]: Color3 } = {}
	for _, name in CHICKEN_BODY do
		local p = dummy:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			before[p] = p.Color
			p.Color = Color3.fromRGB(250, 250, 245)
		end
	end
	for _, name in { "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot" } do
		local p = dummy:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			before[p] = p.Color
			p.Color = Color3.fromRGB(255, 170, 40)
		end
	end
	local bits = Instance.new("Model")
	bits.Name = "ChickenBits"
	bits:SetAttribute("Worn", true)
	local function bit(on: string, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?)
		local to = dummy:FindFirstChild(on)
		if not to or not to:IsA("BasePart") then
			return
		end
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Shape = shape or Enum.PartType.Block
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.CFrame = to.CFrame * offset
		local w = Instance.new("Weld")
		w.Part0 = to
		w.Part1 = p
		w.C0 = offset
		w.Parent = p
		p.Parent = bits
	end
	bit("Head", "Comb", Vector3.new(0.25, 0.6, 0.9), CFrame.new(0, 0.75, 0), Color3.fromRGB(230, 40, 40))
	bit("Head", "Beak", Vector3.new(0.5, 0.3, 0.55), CFrame.new(0, -0.05, -0.75), Color3.fromRGB(255, 170, 40))
	bit("Head", "Wattle", Vector3.new(0.25, 0.4, 0.2), CFrame.new(0, -0.45, -0.6), Color3.fromRGB(230, 40, 40))
	bit("LeftUpperArm", "WingL", Vector3.new(0.3, 1.4, 1.3), CFrame.new(-0.4, -0.2, 0.1), Color3.fromRGB(245, 245, 240))
	bit("RightUpperArm", "WingR", Vector3.new(0.3, 1.4, 1.3), CFrame.new(0.4, -0.2, 0.1), Color3.fromRGB(245, 245, 240))
	bit("LowerTorso", "Tail", Vector3.new(1.2, 1.0, 0.4), CFrame.new(0, 0.5, 0.75) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(245, 245, 240))
	bits.Parent = dummy
	dummy:SetAttribute("Chicken", true)
	FxService.hit(position, 10, "Balloon")
	local function restore()
		if unchicken[dummy] ~= restore then
			return
		end
		unchicken[dummy] = nil
		if dummy.Parent then
			for p, color in before do
				if p.Parent then
					p.Color = color
				end
			end
			bits:Destroy()
			dummy:SetAttribute("Chicken", nil)
		end
	end
	unchicken[dummy] = restore
	dummy.Destroying:Once(function()
		unchicken[dummy] = nil
	end)
	task.delay(CHICKEN_TIME, restore)
end
-- Freezing a chicken: it turns back first (else its own colours would be frozen in for good).
table.insert(DummyControl.beforeFreeze, function(model: Model)
	local restore = unchicken[model]
	if restore then
		restore()
	end
end)

local PLACE: { [string]: PlaceFn } = {
	Anvil = anvil,
	TNT = tnt,
	Trampoline = trampoline,
	Fan = fan,
	Bowling = bowling,
	Firecracker = firecracker,
	Shockwave = shockwave,
	BigBoom = bigBoom,
	Cannon = cannon,
	BlackHole = blackHole,
	SpringPad = springPad,
	Banana = banana,
	Slime = slime,
	Float = floatBubble,
	Slowmo = slowmo,
	Portal = portal,
	Grenade = grenade,
	RPG = rpg,
	Nuke = nuke,
}

local ON_DUMMY: { [string]: DummyFn } = {
	Shrink = shrink,
	Chicken = chicken,
	Rocket = rocket,
	StickyBomb = stickyBomb,
	C4 = c4,
	Balloon = balloon,
	Zap = function(player, dummy, part)
		zap(player, dummy, part)
	end,
	Freeze = function(player: Player?, dummy: Model): string?
		-- (Round 4, M10: never a dead body; it lies still its DEAD_HOLD.)
		if dummy:GetAttribute("Vital") == "Dead" then
			return "TooLate"
		end
		Dummies.setBlame(dummy, if player then player.UserId else 0)
		DummyControl.freeze(dummy)
		local chest = dummy:FindFirstChild("UpperTorso") :: BasePart?
		if chest then
			FxService.hit(chest.Position, 20, "Freeze")
		end
	end,
	Heal = function(_player: Player?, dummy: Model, _part: BasePart, position: Vector3): string?
		-- Good as new: the body (DummyControl) and its blood, wounds and limbs (VitalsService; its
		-- sparkle is this one). Round 4, M10: a dead body is too late (no sparkle; the player is told).
		if not VitalsService.heal(dummy) then
			return "TooLate"
		end
		FxService.hit(position, 10, "Heal")
	end,
}

-- Whether a spot is right where another player stands (nothing solid lands on top of them).
local function onAnotherPlayer(player: Player?, at: Vector3): boolean
	for _, other in Players:GetPlayers() do
		local character = other ~= player and other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local offset = root.Position - at
			if Vector3.new(offset.X, 0, offset.Z).Magnitude < PLACE_CLEARANCE and math.abs(offset.Y) < PLACE_CLEARANCE_UP then
				return true
			end
		end
	end
	return false
end

-- Uses a "place" toy at a surface point. Returns whether it was used and, if not, why ("busy":
-- someone stands there; nil: not a place toy).
function ToyService.place(player: Player?, toyId: string, at: Vector3, facing: Vector3): (boolean, string?)
	local use = PLACE[toyId]
	if not use then
		return false, nil
	end
	if player and onAnotherPlayer(player, at) then
		return false, "Occupied"
	end
	Props.makeRoomFor(player, toyId)
	use(player, at, facing)
	return true, nil
end

-- Uses a "dummy" toy on a dummy part. Returns whether it was used and, if not, why ("Frozen": an
-- ice statue is hit to shatter it instead).
function ToyService.onDummy(player: Player?, toyId: string, part: BasePart, position: Vector3): (boolean, string?)
	local dummy = Dummies.of(part)
	local use = ON_DUMMY[toyId]
	if not dummy or not use then
		return false, nil
	end
	if dummy:GetAttribute("Frozen") == true then
		return false, "Frozen"
	end
	local why = (use :: any)(player, dummy, part, position)
	if type(why) == "string" then
		return false, why
	end
	return true, nil
end

-- Contacts on a dummy a client simulates (someone's ball, pad or machine) are judged on that
-- client; it tells the server whose thing it was, so everyone agrees who sent the dummy flying.
-- Believed only from the client that simulates the dummy, a few a second, and only as far as the
-- server can see it is true: the reporter may always blame itself (its own body: a throw) or the
-- lab; it may blame another player only for a loose thing of theirs that is moving, right next to
-- the dummy. An anchored wall someone built never "sends" a dummy anywhere, so nobody can be framed
-- by parking a dummy next to their build and then flinging it at them.
local BLAME_REACH = 8 -- studs from the dummy's pelvis to the cause's box (a dummy is ~5 tall)
local BLAME_MIN_SPEED = 6 -- studs/s: another player's thing must be moving
-- ...or be one of the pads that launch whatever lands on them (anchored, but they do the throwing).
local LAUNCH_PADS = { TrampolinePad = true, SpringPad = true, BananaPeel = true }
local BLAME_PER_SECOND = 20
local blameWindow: { [Player]: { start: number, count: number } } = {}

local function ownerIdOf(cause: BasePart): number?
	local prop = Props.propOf(cause)
	if prop then
		return (prop:GetAttribute("Owner") :: number?) or 0
	end
	local builds = Workspace:FindFirstChild("Builds")
	if builds and cause:IsDescendantOf(builds) then
		local holder = cause:FindFirstAncestorWhichIsA("Folder")
		while holder and holder.Parent ~= builds do
			holder = holder:FindFirstAncestorWhichIsA("Folder")
		end
		return if holder then (holder:GetAttribute("Owner") :: number?) else nil
	end
	local playground = Workspace:FindFirstChild("Playground")
	if playground and cause:IsDescendantOf(playground) then
		return 0
	end
	return nil
end

local function onBlame(player: Player, model: unknown, cause: unknown)
	if typeof(model) ~= "Instance" or typeof(cause) ~= "Instance" then
		return
	end
	local m, c = model :: Instance, cause :: Instance
	if not m:IsA("Model") or not c:IsA("BasePart") or DummyControl.ownerOf(m) ~= player then
		return
	end
	local now = os.clock()
	local w = blameWindow[player]
	if not w or now - w.start > 1 then
		w = { start = now, count = 0 }
		blameWindow[player] = w
	end
	w.count += 1
	if w.count > BLAME_PER_SECOND then
		return
	end
	local character = player.Character
	if character and c:IsDescendantOf(character) then
		Dummies.setBlame(m, player.UserId) -- holding or throwing it: only ever blames yourself
		return
	end
	local pelvis = m:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") then
		return
	end
	local l = c.CFrame:PointToObjectSpace(pelvis.Position)
	local half = c.Size / 2
	local nearest = Vector3.new(math.clamp(l.X, -half.X, half.X), math.clamp(l.Y, -half.Y, half.Y), math.clamp(l.Z, -half.Z, half.Z))
	if (l - nearest).Magnitude > BLAME_REACH then
		return
	end
	local owner = ownerIdOf(c)
	if owner == nil then
		return
	end
	if owner ~= 0 and owner ~= player.UserId then
		local pad = LAUNCH_PADS[c.Name] == true
		if not pad and (c.Anchored or c.AssemblyLinearVelocity.Magnitude < BLAME_MIN_SPEED) then
			return
		end
	end
	Dummies.setBlame(m, owner)
end

-- Tests: the DummyBlame handler itself.
ToyService.onBlame = function(player: Player, model: unknown, cause: unknown)
	onBlame(player, model, cause)
end

function ToyService.start()
	Props.start()
	Net.event(Net.Names.DummyBlame).OnServerEvent:Connect(onBlame)
	Players.PlayerRemoving:Connect(function(player)
		lastPadHit[player] = nil
		blameWindow[player] = nil
		-- (Their portal rings go with them, not left standing about doing nothing.)
		local pair = portals[player]
		if pair then
			for _, ring in { pair.a, pair.b } do
				if ring and ring.Parent then
					ring:Destroy()
				end
			end
		end
		portals[player] = nil
	end)
	local portalAcc = 0
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		portalAcc += dt
		if portalAcc >= 0.1 then
			portalAcc = 0
			if next(portals) ~= nil then
				portalTick()
			end
		end
	end)
end

return ToyService
