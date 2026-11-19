--!strict
-- Your own body as a ragdoll (Ragdoll Engine's F, Ragdoll Reality's Ragdoll button). This client
-- simulates it, like every player's avatar, the whole time: it goes limp, flies, lies still and gets
-- up right here with the same ActiveRagdoll as the dummies, so it reacts the instant something hits
-- you. The server mirrors which joints are loose (see PlayerRagdoll) and tells us about knocks only
-- it sees (explosions, the human cannon).
--
--   F, or the RAGDOLL button      go limp where you stand; you stay down until you press it again
--                                  (or jump), then you get up the same way the dummies do
--   explosions, props, machines,  knock you over and send you flying; you get up by yourself
--   flying dummies, bumpers        once you lie still
--   trampolines                    bounce you high, limp or not
--   a long fall                    ends in a flop instead of a clean landing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Net = require(Shared:WaitForChild("Net"))
local HitMath = require(Shared:WaitForChild("HitMath"))
local Dummies = require(Shared:WaitForChild("Dummies"))
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll"))

local Client = script.Parent
local FxController = require(Client:WaitForChild("FxController"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local HudSlots = require(Client:WaitForChild("HudSlots"))

local player = Players.LocalPlayer

local PlayerBody = {}

local KNOCK_SPEED = 24 -- studs/s a thing must hit you with to knock you over
local DUMMY_KNOCK_SPEED = 32 -- a flying dummy has to be really flying
local MAX_KNOCK = HitMath.PLAYER_MAX_KNOCK
local KNOCK_LIFT = 0.35
local FLOP_FALL_SPEED = 72 -- studs/s downwards on landing that ends in a flop
local TRAMPOLINE_SHARE = 0.85

local LAUNCH_MAX = HitMath.PLAYER_LAUNCH_MAX -- the most any knock may send you (the human cannon)
local MIN_DOWN_TIME = HitMath.PLAYER_MIN_DOWN_TIME -- s before getting up starts (a press before waits)
local ACK_WAIT = 1 -- s to wait for the server to finish restoring before going limp again anyway
local VOID_MARGIN = HitMath.PLAYER_VOID_MARGIN

type Saved = {
	joints: { [AnimationConstraint]: { kinematic: boolean, strength: number, damping: number, torque: number, force: number, linearStrength: number, linearDamping: number } },
	parts: { [BasePart]: { canCollide: boolean, massless: boolean, physical: PhysicalProperties? } },
	evaluate: boolean,
	requiresNeck: boolean,
	breakJoints: boolean,
	nameDistance: Enum.HumanoidDisplayDistanceType,
}

local remote: RemoteEvent
local down = false -- the body is limp (ActiveRagdoll runs it)
local stayDown = false
local downSince = 0
local limpModel: Model? = nil
local saved: Saved? = nil
local button: TextButton? = nil
local lastKnock = 0
local upWanted = false -- get up was asked for before MIN_DOWN_TIME; it happens when that is over
local waitingForAck = false
local everLimp = false -- for the onboarding tip
local ackStay = false -- what was asked for while waiting: the strongest wins
local ackVelocity: Vector3? = nil
local lastBounce = 0
local characterConnections: { RBXScriptConnection } = {}

local function character(): (Model?, Humanoid?, BasePart?)
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if c and h and r and r:IsA("BasePart") and h.Health > 0 then
		return c, h, r
	end
	return nil, nil, nil
end

local function refreshButton()
	local b = button
	if not b then
		return
	end
	local stayingDown = down and stayDown
	b.Text = if stayingDown then "GET UP" else "RAGDOLL"
	b.BackgroundColor3 = if stayingDown then KitStyle.GO else KitStyle.SLAB
	KitStyle.button(b)
	b.TextSize = 16 -- "RAGDOLL" fits the 86 px slot
end

function PlayerBody.isDown(): boolean
	return down
end

local function snapshot(model: Model, humanoid: Humanoid): Saved
	local joints = {}
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") then
			joints[d] = {
				kinematic = d.IsKinematic,
				strength = d.AngularStrength,
				damping = d.AngularDamping,
				torque = d.MaxTorque,
				force = d.MaxForce,
				linearStrength = d.LinearStrength,
				linearDamping = d.LinearDamping,
			}
		elseif d:IsA("BasePart") then
			parts[d] = { canCollide = d.CanCollide, massless = d.Massless, physical = d.CustomPhysicalProperties }
		end
	end
	return {
		joints = joints,
		parts = parts,
		evaluate = humanoid.EvaluateStateMachine,
		requiresNeck = humanoid.RequiresNeck,
		breakJoints = humanoid.BreakJointsOnDeath,
		nameDistance = humanoid.DisplayDistanceType,
	}
end

local function setAnimate(model: Model, on: boolean)
	local animate = model:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Enabled = on
	end
end

-- Back on your feet: everything exactly as it was, upright where the body stands, walking again.
-- how: "GetUp" (the ragdoll got up by itself), "Report" (cut short here: tell the server),
-- "Silent" (the avatar is gone anyway)
local function stand(how: "GetUp" | "Report" | "Silent")
	local report = how == "Report"
	local model, s = limpModel, saved
	down = false
	stayDown = false
	upWanted = false
	limpModel = nil
	saved = nil
	if model then
		ActiveRagdoll.teardown(model)
	end
	if model and s and model.Parent then
		for joint, j in s.joints do
			if joint.Parent then
				joint.IsKinematic = j.kinematic
				joint.AngularStrength = j.strength
				joint.AngularDamping = j.damping
				joint.MaxTorque = j.torque
				joint.MaxForce = j.force
				joint.LinearStrength = j.linearStrength
				joint.LinearDamping = j.linearDamping
			end
		end
		for part, p in s.parts do
			if part.Parent then
				part.CanCollide = p.canCollide
				part.Massless = p.massless
				part.CustomPhysicalProperties = p.physical
			end
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		local pelvis = model:FindFirstChild("LowerTorso")
		if root and root:IsA("BasePart") and pelvis and pelvis:IsA("BasePart") then
			-- The get-up already brought the pelvis upright; only the heading is kept.
			local look = pelvis.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude < 0.1 then
				flat = Vector3.zAxis
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
			if how == "GetUp" then
				FxController.localEvent("GetUp", root.Position, 0, "")
			end
		end
		if humanoid then
			humanoid.RequiresNeck = s.requiresNeck
			humanoid.BreakJointsOnDeath = s.breakJoints
			humanoid.DisplayDistanceType = s.nameDistance
			humanoid.EvaluateStateMachine = s.evaluate
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		setAnimate(model, true)
		if report then
			-- Got up without the ragdoll's own get-up (switched view, respawned): tell the server.
			remote:FireServer("State", "Standing")
		end
	end
	refreshButton()
end

local function capped(velocity: Vector3): Vector3
	if velocity.Magnitude > LAUNCH_MAX then
		return velocity.Unit * LAUNCH_MAX
	end
	return velocity
end

-- A limp body standing perfectly still can stay balanced on its feet: tip the top half so it
-- crumples (backwards and a little to one side, like a faint).
local function tip(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local push = -root.CFrame.LookVector * 9 + root.CFrame.RightVector * (if math.random() < 0.5 then -3 else 3) + Vector3.new(0, -2, 0)
	for _, name in { "UpperTorso", "Head" } do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part:ApplyImpulse(push * part.Mass)
		end
	end
end

-- The body died or fell apart while limp: nothing to restore, the avatar respawns.
local function dropLimp()
	local model = limpModel
	down = false
	stayDown = false
	upWanted = false
	limpModel = nil
	saved = nil
	if model then
		ActiveRagdoll.teardown(model)
	end
	refreshButton()
end

-- Go limp (or, already limp, take the shove). stay: lie there until told to get up.
local function goLimp(stay: boolean, velocity: Vector3?, force: boolean?)
	if ViewMode.isLab() then
		return -- the avatar is parked in the lab view
	end
	local model, humanoid = character()
	if not model or not humanoid then
		return
	end
	if not down and not force and model:GetAttribute("BodyLoose") == true then
		-- Just got up and the server is still putting the joints back: its restore would undo
		-- going limp now. Go as soon as it is done (one round trip), or after ACK_WAIT anyway.
		-- Whatever else arrives meanwhile is kept: staying down wins, the biggest shove wins.
		ackStay = ackStay or stay
		if velocity and (not ackVelocity or velocity.Magnitude > (ackVelocity :: Vector3).Magnitude) then
			ackVelocity = velocity
		end
		if waitingForAck then
			return
		end
		waitingForAck = true
		local started = os.clock()
		task.spawn(function()
			while model:GetAttribute("BodyLoose") == true and os.clock() - started < ACK_WAIT do
				task.wait()
			end
			waitingForAck = false
			local s, v = ackStay, ackVelocity
			ackStay, ackVelocity = false, nil
			if model == player.Character and not down then
				goLimp(s, v, true)
			end
		end)
		return
	end
	if down and limpModel == model then
		if stay then
			stayDown = true
			upWanted = false
			-- Pressed while getting up: drop back down.
			if ActiveRagdoll.getState(model) ~= "Ragdoll" then
				ActiveRagdoll.setState(model, "Ragdoll")
			end
			ActiveRagdoll.setStayDown(model, true)
		end
		if velocity and velocity.Magnitude > 0.5 then
			-- A shove while getting up knocks you back down.
			if ActiveRagdoll.getState(model) ~= "Ragdoll" then
				ActiveRagdoll.setState(model, "Ragdoll")
				ActiveRagdoll.setStayDown(model, stayDown)
			end
			ActiveRagdoll.push(model, capped(velocity))
		end
		refreshButton()
		return
	end
	saved = snapshot(model, humanoid)
	setAnimate(model, false)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	ActiveRagdoll.prepare(model)
	local ok, err = ActiveRagdoll.setup(model)
	if not ok then
		warn("[Body] cannot ragdoll: " .. tostring(err))
		limpModel = model
		stand("Silent")
		return
	end
	down = true
	everLimp = true
	stayDown = stay
	downSince = os.clock()
	limpModel = model
	ActiveRagdoll.setState(model, "Ragdoll")
	ActiveRagdoll.setStayDown(model, stay)
	if velocity and velocity.Magnitude > 0.5 then
		ActiveRagdoll.push(model, capped(velocity))
	else
		tip(model)
		local chest = model:FindFirstChild("UpperTorso")
		if chest and chest:IsA("BasePart") then
			FxController.localEvent("Limp", chest.Position, 0, "")
		end
	end
	refreshButton()
end

local function getUp()
	local model = limpModel
	if not down or not model then
		return
	end
	local early = MIN_DOWN_TIME - (os.clock() - downSince)
	if early > 0 then
		-- Pressed straight after going down: remember it rather than ignore it.
		if not upWanted then
			upWanted = true
			task.delay(early, function()
				if upWanted and down and limpModel == model then
					upWanted = false
					getUp()
				end
			end)
		end
		stayDown = false
		ActiveRagdoll.setStayDown(model, false)
		refreshButton()
		return
	end
	upWanted = false
	stayDown = false
	ActiveRagdoll.setStayDown(model, false)
	ActiveRagdoll.getUp(model)
	refreshButton()
end

-- A shove from something this client noticed.
function PlayerBody.knock(velocity: Vector3)
	local now = os.clock()
	if now - lastKnock < 0.3 then
		return
	end
	lastKnock = now
	if velocity.Magnitude > MAX_KNOCK then
		velocity = velocity.Unit * MAX_KNOCK
	end
	goLimp(stayDown, velocity)
end

-- Whether this player has gone limp at all this session (the onboarding tip waits for it).
function PlayerBody.hasGoneLimp(): boolean
	return everLimp
end

-- Points at the RAGDOLL button for a few seconds (a gentle bounce).
function PlayerBody.highlight()
	local b = button
	if not b then
		return
	end
	-- (On the slot's own UIScale, back to its resting scale after: never a second UIScale.)
	local found = b:FindFirstChild("HudScale")
	local scale: UIScale
	if found and found:IsA("UIScale") then
		scale = found
	else
		scale = Instance.new("UIScale")
		scale.Name = "HudScale"
		scale.Parent = b
	end
	local base = b:GetAttribute("KitBase")
	local rest = if type(base) == "number" then base else 1
	local tween = TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 8, true), { Scale = rest * 1.15 })
	tween:Play()
	tween.Completed:Once(function()
		scale.Scale = rest
	end)
end

------------------------------------------------------------------------------------------------
-- Held by another player in the plaza (phase D, PlayerGrab on the server): limp, hanging in front
-- of them on a spring this client runs (it simulates its own body, as always). Jump (or F) three
-- times to wriggle free; the server lets go anyway after a few seconds.

local HELD_OFFSET = CFrame.new(0, 1.6, -4.5) -- in front of the grabber, at chest height
local WRIGGLES = 3
local lastWriggle = 0
local held: { grabber: Player, attachment: Attachment, align: AlignPosition, step: RBXScriptConnection, wriggles: number }? = nil
PlayerBody.onWriggle = nil :: (() -> ())?

local function endHeld()
	local h = held
	if not h then
		return
	end
	held = nil
	h.step:Disconnect()
	h.align:Destroy()
	h.attachment:Destroy()
end

local function wriggle()
	local h = held
	if not h then
		return
	end
	h.wriggles += 1
	local _, _, root = character()
	if root then
		FxController.localEvent("Hit", root.Position, 6, "Grab")
	end
	if h.wriggles >= WRIGGLES then
		h.wriggles = 0
		local f = PlayerBody.onWriggle
		if f then
			f()
		end
	end
end

function PlayerBody.isHeld(): boolean
	return held ~= nil
end

-- Returns false when this body cannot be held now (the lab view, no avatar).
function PlayerBody.setHeld(grabber: Player): boolean
	endHeld()
	goLimp(true, nil, true)
	local model = limpModel
	local chest = model and model:FindFirstChild("UpperTorso")
	if not down or not model or not chest or not chest:IsA("BasePart") then
		return false
	end
	local mass = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not d.Massless then
			mass += d:GetMass()
		end
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "HeldPoint"
	attachment.Parent = chest
	local align = Instance.new("AlignPosition")
	align.Name = "Held"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxForce = math.max(mass, 5) * Workspace.Gravity * 4
	align.Responsiveness = 30
	align.MaxVelocity = 120
	align.Position = chest.Position
	align.Parent = chest
	local step = RunService.Heartbeat:Connect(function()
		if not down or limpModel ~= model or not attachment.Parent then
			endHeld() -- (died, respawned or got up some other way)
			return
		end
		local c = grabber.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			align.Position = (r.CFrame * HELD_OFFSET).Position
		end
	end)
	held = { grabber = grabber, attachment = attachment, align = align, step = step, wriggles = 0 }
	return true
end

-- Let go: thrown (velocity) or dropped. You get up by yourself once you lie still.
function PlayerBody.freeHeld(velocity: Vector3?)
	endHeld()
	local model = limpModel
	if not down or not model then
		return
	end
	stayDown = false
	ActiveRagdoll.setStayDown(model, false)
	if velocity and velocity.Magnitude > 0.5 then
		ActiveRagdoll.push(model, capped(velocity))
	end
	refreshButton()
end

function PlayerBody.toggle()
	if held then
		wriggle()
		return
	end
	if not down then
		goLimp(true, nil)
	elseif stayDown then
		getUp()
	else
		goLimp(true, nil)
	end
end

------------------------------------------------------------------------------------------------
-- What can hit you

local function knockFrom(other: BasePart, limb: BasePart, minSpeed: number)
	local _, _, root = character()
	if not root then
		return
	end
	-- Only what comes AT you knocks you over (M1): the thing's own speed toward you, not yours.
	-- Running or walking into a standing dummy, person or prop never floors you.
	local theirs = other:GetVelocityAtPosition(limb.Position)
	local toMe = root.Position - other.Position
	local closing = if toMe.Magnitude > 0.01 then theirs:Dot(toMe.Unit) else 0
	if closing < minSpeed then
		return
	end
	local relative = theirs - root.AssemblyLinearVelocity
	local dir = (relative.Unit + Vector3.new(0, KNOCK_LIFT, 0)).Unit
	PlayerBody.knock(dir * math.min(relative.Magnitude * 0.9, MAX_KNOCK))
	FxController.localEvent("Hit", limb.Position, relative.Magnitude, "Machine")
end

local function bounce(pad: BasePart)
	local now = os.clock()
	if now - lastBounce < 0.35 then
		return
	end
	lastBounce = now
	local _, humanoid, root = character()
	if not humanoid or not root then
		return
	end
	local v = root.AssemblyLinearVelocity
	local up = Vector3.new(v.X * 0.6, HitMath.TRAMPOLINE_SPEED * TRAMPOLINE_SHARE, v.Z * 0.6)
	local model = limpModel
	if down and model then
		-- Limp: the whole body gets the bounce (minus how fast it was falling into the pad).
		local pelvis = model:FindFirstChild("LowerTorso")
		local was = if pelvis and pelvis:IsA("BasePart") then pelvis.AssemblyLinearVelocity else v
		ActiveRagdoll.push(model, up - was)
	else
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		root.AssemblyLinearVelocity = up
	end
	FxController.localEvent("Hit", pad.Position, 40, "Trampoline")
end

-- Whether something is yours (or the shared playground's): only your own things knock you over,
-- bounce you or bump you. Another player's props, pads and machines never keep you on the floor.
local function isMine(other: BasePart): boolean
	local props = Workspace:FindFirstChild("Props")
	local builds = Workspace:FindFirstChild("Builds")
	local playground = Workspace:FindFirstChild("Playground")
	if props and other:IsDescendantOf(props) then
		local prop: Instance = other
		while prop.Parent and prop.Parent ~= props do
			prop = prop.Parent :: Instance
		end
		local owner = prop:GetAttribute("Owner")
		return owner == player.UserId or owner == 0
	elseif builds and other:IsDescendantOf(builds) then
		local myBuild = builds:FindFirstChild(tostring(player.UserId))
		return myBuild ~= nil and other:IsDescendantOf(myBuild)
	end
	return playground ~= nil and other:IsDescendantOf(playground)
end

local function onTouched(other: BasePart, limb: BasePart)
	if not other.Parent or (player.Character and other:IsDescendantOf(player.Character)) then
		return
	end
	if other.Name == "TrampolinePad" then
		if isMine(other) then
			bounce(other)
		end
		return
	end
	if down then
		return -- the limp body just collides; what hits it moves it
	end
	if other.Name == "BumperBall" then
		local _, _, root = character()
		if root and isMine(other) then
			local away = root.Position - other.Position
			local flat = Vector3.new(away.X, 0, away.Z)
			local dir = ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) * 0.85 + Vector3.new(0, 0.5, 0)).Unit
			PlayerBody.knock(dir * HitMath.BUMPER_SPEED)
			FxController.localEvent("Hit", root.Position, 35, "Trampoline")
		end
		return
	end
	if other.Anchored then
		return
	end
	if isMine(other) then
		local root = other.AssemblyRootPart
		if root and not root.Anchored then
			knockFrom(other, limb, KNOCK_SPEED)
		end
		return
	end
	-- A flying dummy only knocks you over if you sent it flying (hit, threw, blew up): nobody can
	-- throw dummies at someone else to floor them. The one you are carrying never counts.
	local dummy = Dummies.of(other)
	if dummy and dummy:GetAttribute("Held") ~= true and Dummies.sentBy(dummy, player.UserId) then
		knockFrom(other, limb, DUMMY_KNOCK_SPEED)
	end
end

local function watchCharacter(model: Model)
	if down then
		stand("Silent") -- a new avatar: the old one is gone
	end
	for _, c in characterConnections do
		c:Disconnect()
	end
	characterConnections = {}
	local humanoid = model:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	local function keep(c: RBXScriptConnection)
		table.insert(characterConnections, c)
	end
	-- Dying while limp: the state machine is off then, so put it back for the death to play out.
	keep(humanoid.HealthChanged:Connect(function(health)
		if health <= 0 and down and limpModel == model then
			humanoid.EvaluateStateMachine = true
			humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			dropLimp()
		end
	end))
	local pelvis = model:FindFirstChild("LowerTorso")
	if pelvis then
		keep(pelvis.AncestryChanged:Connect(function()
			if not pelvis:IsDescendantOf(model) and down and limpModel == model then
				dropLimp() -- destroyed by the void; the server respawns the avatar
			end
		end))
	end
	-- Roblox's own trip states never fire: falling over is this module's (a bump into a person or
	-- a dummy's foot made the avatar flop in round 2).
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	keep(humanoid.Touched:Connect(function(other, limb)
		if other:IsA("BasePart") and limb:IsA("BasePart") then
			onTouched(other, limb)
		end
	end))
	-- A long fall ends in a flop.
	local fallSpeed = 0
	keep(humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed and fallSpeed > FLOP_FALL_SPEED and not down then
			local root = model:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				FxController.localEvent("Land", root.Position, fallSpeed, "")
			end
			PlayerBody.knock(Vector3.new(0, -1, 0))
		end
	end))
	keep(RunService.Heartbeat:Connect(function()
		local root = model:FindFirstChild("HumanoidRootPart")
		local pelvisNow = model:FindFirstChild("LowerTorso")
		if down and limpModel == model and pelvisNow and pelvisNow:IsA("BasePart")
			and pelvisNow.Position.Y < Workspace.FallenPartsDestroyHeight + VOID_MARGIN then
			dropLimp() -- fell out of the world limp; the server respawns the avatar
			return
		end
		if root and root:IsA("BasePart") and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			fallSpeed = math.max(0, -root.AssemblyLinearVelocity.Y)
		elseif humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
			fallSpeed = 0
		end
	end))
	refreshButton()
end

local function buildButton()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BodyPad"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)
	local b = Instance.new("TextButton")
	b.Name = "Ragdoll"
	HudSlots.apply(b, "Ragdoll", HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()))
	b.TextSize = 16
	b.AutoButtonColor = true
	KitStyle.button(b)
	KitStyle.icon(b, KitStyle.HUD_ICONS.Ragdoll) -- (UI v2: a drawn icon beside the word)
	b.Activated:Connect(function()
		KitStyle.pop(b, 0.88) -- (on the slot's own UIScale: never a second one)
		PlayerBody.toggle()
	end)
	b.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	button = b
	-- Only in the player view: in the lab view your avatar is parked. Not while building either:
	-- the build tools have that edge of the screen.
	local function show()
		gui.Enabled = not ViewMode.isLab() and player:GetAttribute("Building") ~= true
	end
	ViewMode.onChanged(show)
	player:GetAttributeChangedSignal("Building"):Connect(show)
	show()
	refreshButton()
end

function PlayerBody.start()
	remote = Net.event(Net.Names.Body)
	remote.OnClientEvent:Connect(function(kind: unknown, arg: unknown)
		if kind == "Knock" and typeof(arg) == "Vector3" then
			goLimp(stayDown, arg :: Vector3)
		elseif kind == "Limp" then
			goLimp(arg == true, nil)
		elseif kind == "GetUp" then
			getUp()
		end
	end)
	-- Every state change of the limp body goes to the server, which mirrors the loose joints.
	ActiveRagdoll.addTransitionListener(function(model: Model, state: ActiveRagdoll.State)
		if model == limpModel and model == player.Character then
			remote:FireServer("State", state)
			if state == "Standing" and down then
				task.defer(stand, "GetUp")
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not Keybinds.live(processed) or not Keybinds.is("Ragdoll", input.KeyCode) or ViewMode.isLab() then
			return
		end
		PlayerBody.toggle()
	end)
	-- Jump gets you up.
	UserInputService.JumpRequest:Connect(function()
		if held then
			-- (JumpRequest fires every frame the key is held: one wriggle per press.)
			local now = os.clock()
			if now - lastWriggle > 0.2 then
				wriggle()
			end
			lastWriggle = now
			return
		end
		if down then
			getUp()
		end
	end)
	-- The lab view parks your avatar: stand up at once.
	ViewMode.onChanged(function()
		if down and ViewMode.isLab() then
			stand("Report")
		end
	end)
	buildButton()
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
end

return PlayerBody
