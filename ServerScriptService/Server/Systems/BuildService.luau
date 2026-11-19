--!strict
-- The Workshop on the server: every player's blueprint, the operations that change it, and
-- bringing a build to life on Play.
--
-- The blueprint is the truth. Clients ask for operations (place, delete, paint, tune, pin, wire,
-- undo, clear, play, stop); each one is validated against the catalog and the build rules before
-- the blueprint changes, and the frozen models are rebuilt from it. On Play the models are welded
-- together along the "placed on" links, joints come alive, pieces placed on the floor stay pinned,
-- and the whole machine is handed to the player's client to simulate (like their dummies), so it
-- feels instant. Signals (buttons, timers, sensors) run here and switch machines through their
-- constraints, which replicate. Stop rebuilds everything frozen from the blueprint.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Log)
local HitMath = require(Shared.HitMath)
local Dummies = require(Shared.Dummies)
local Build = Shared.Build
local Catalog = require(Build.Catalog)
local Codec = require(Build.Codec)
local Factory = require(Build.Factory)
local Orientation = require(Build.Orientation)

local DummyControl = require(script.Parent.DummyControl)
local ToyService = require(script.Parent.ToyService)
local FxService = require(script.Parent.FxService)
local Lab = require(script.Parent.Lab)

local log = Log.new("Build")

local MAX_UNDO = 40
local MAX_OPS_PER_SECOND = 25
local OVERLAP_SLACK = 0.05
local PISTON_CYCLE = 1.2 -- s, unwired pistons
local CANNON_CYCLE = 3 -- s, unwired cannons
local SENSOR_COOLDOWN = 0.6
local CRATE_IMPACT_SPEED = 35
-- Loose parts that leave the lab (a car driving off, a block flung by a crate) poof away instead
-- of travelling forever; Stop brings everything back.
-- (Within the player's own lab: never into a neighbour's, which starts 85 studs from the middle.)
local LEASH_RADIUS = Catalog.BUILD_RADIUS + 8
local LEASH_LOW, LEASH_HIGH = -25, 180
local LEASH_CHECK = 0.25

type Live = {
	token: number,
	wired: { [number]: boolean }, -- pieces that have incoming wires
	on: { [number]: boolean }, -- current on/off of inputs
	spent: { [number]: boolean }, -- crates that went off
	lastSensor: { [number]: number },
	wheelSign: { [number]: number }, -- wheels on opposite sides of a body spin the same way forward
	connections: { RBXScriptConnection },
}

type Plot = {
	player: Player,
	bp: Codec.Blueprint,
	models: { Model },
	folder: Folder,
	undo: { Codec.Blueprint },
	live: Live?,
	window: { start: number, count: number },
}

local BuildService = {}

local plots: { [Player]: Plot } = {}
local stateEvent: RemoteEvent
local tokens = 0

local function buildsFolder(): Folder
	local f = Workspace:FindFirstChild("Builds")
	if f and f:IsA("Folder") then
		return f
	end
	local new = Instance.new("Folder")
	new.Name = "Builds"
	new.Parent = Workspace
	return new
end

-- Where a player's build sits: in their own lab (the plaza, shared, when every lab was taken).
-- On the floor (y = 0) and on whole studs, so the half-stud build grid lines up with the world.
function BuildService.originFor(player: Player): Vector3
	local origin = Lab.originFor(player)
	return Vector3.new(math.round(origin.X), 0, math.round(origin.Z))
end

local function publish(plot: Plot, message: string?)
	local wires = {}
	for _, w in plot.bp.wires do
		table.insert(wires, { w.from, w.to })
	end
	stateEvent:FireClient(plot.player, {
		pieces = #plot.bp.pieces,
		wires = wires,
		playing = plot.live ~= nil,
		canUndo = #plot.undo > 0,
		message = message,
	})
end

local function destroyModels(plot: Plot)
	for _, model in plot.models do
		model:Destroy()
	end
	table.clear(plot.models)
end

local function buildModel(plot: Plot, index: number): Model
	local piece = plot.bp.pieces[index]
	local model = Factory.build(piece, BuildService.originFor(plot.player))
	model:SetAttribute("Piece", index)
	model:SetAttribute("Owner", plot.player.UserId)
	model.Parent = plot.folder
	return model
end

-- Rebuilds every frozen model from the blueprint.
local function rebuild(plot: Plot)
	destroyModels(plot)
	for i in plot.bp.pieces do
		plot.models[i] = buildModel(plot, i)
	end
end

local function snapshot(plot: Plot)
	table.insert(plot.undo, Codec.clone(plot.bp))
	if #plot.undo > MAX_UNDO then
		table.remove(plot.undo, 1)
	end
end

-- World-space box of a piece (axis aligned).
local function boxOf(plot: Plot, piece: Codec.Piece): (Vector3, Vector3)
	local item = Catalog.byId[piece.item]
	return BuildService.originFor(plot.player) + piece.pos, Orientation.extents(piece.rot, item.size) / 2
end

local function overlapsAny(plot: Plot, piece: Codec.Piece): boolean
	local c, h = boxOf(plot, piece)
	for _, other in plot.bp.pieces do
		local oc, oh = boxOf(plot, other)
		local d = (c - oc):Abs()
		local limit = h + oh - Vector3.one * OVERLAP_SLACK
		if d.X < limit.X and d.Y < limit.Y and d.Z < limit.Z then
			return true
		end
	end
	return false
end

local function allowed(plot: Plot): boolean
	local now = os.clock()
	local w = plot.window
	if now - w.start > 1 then
		w.start = now
		w.count = 0
	end
	w.count += 1
	return w.count <= MAX_OPS_PER_SECOND
end

local function isInt(v: unknown, lo: number, hi: number): boolean
	return type(v) == "number" and v % 1 == 0 and v >= lo and v <= hi
end

------------------------------------------------------------------------------------------------
-- Live machines

local function partNamed(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

local function jointOf(model: Model): Constraint?
	for _, d in model:GetDescendants() do
		if d.Name == "Joint" and d:IsA("Constraint") then
			return d
		end
	end
	return nil
end

local function flash(model: Model)
	for _, part in Factory.parts(model) do
		if part.Material == Enum.Material.Neon or part.Name == "Cap" or part.Name == "Face" or part.Name == "SensorPad" then
			local original = part.Color
			part.Color = Color3.new(1, 1, 1)
			task.delay(0.15, function()
				if part.Parent then
					part.Color = original
				end
			end)
		end
	end
end

local function fireCannon(plot: Plot, index: number)
	local model = plot.models[index]
	local barrel = model and partNamed(model, "Barrel")
	local base = model and partNamed(model, "Base")
	if not barrel or not base then
		return
	end
	local muzzle = barrel:FindFirstChild("Muzzle") :: Attachment?
	local dir = barrel.CFrame.XVector -- the barrel cylinder's axis
	local at = if muzzle then muzzle.WorldPosition else barrel.Position + dir * 1.5
	ToyService.fireBall(plot.player, CFrame.lookAt(at, at + dir), (base:GetAttribute("Ammo") :: string?) or "Ball")
	FxService.hit(at, 60, "Launch")
end

local function explodeCrate(plot: Plot, index: number)
	local live = plot.live
	if not live or live.spent[index] then
		return
	end
	live.spent[index] = true
	local model = plot.models[index]
	local crate = model and partNamed(model, "TNT")
	if not crate then
		return
	end
	local center = crate.Position
	crate.Transparency = 1
	crate.CanCollide = false
	crate.CanTouch = false
	crate.CanQuery = false
	-- Whatever was built on the crate comes loose.
	for _, d in crate:GetChildren() do
		if d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	for _, other in plot.models do
		for _, d in other:GetDescendants() do
			if d:IsA("WeldConstraint") and (d.Part0 == crate or d.Part1 == crate) then
				d:Destroy()
			end
		end
	end
	ToyService.explode(center, model, plot.player)
end

-- Switches an input piece on or off.
local function setOn(plot: Plot, index: number, on: boolean)
	local live = plot.live
	if not live then
		return
	end
	live.on[index] = on
	local piece = plot.bp.pieces[index]
	local model = plot.models[index]
	if not piece or not model then
		return
	end
	local item = piece.item
	if item == "Motor" or item == "Wheel" then
		local joint = jointOf(model) :: HingeConstraint?
		if joint then
			local sign = if item == "Wheel" then (live.wheelSign[index] or 1) else 1
			joint.AngularVelocity = if on then sign * ((joint:GetAttribute("RunSpeed") :: number?) or 0) else 0
		end
	elseif item == "Piston" then
		local joint = jointOf(model) :: PrismaticConstraint?
		if joint then
			joint.TargetPosition = if on then ((joint:GetAttribute("Reach") :: number?) or 2.5) else 0
		end
	elseif item == "Thruster" then
		local base = partNamed(model, "Base")
		local push = base and base:FindFirstChild("Push") :: VectorForce?
		if push then
			push.Force = Vector3.new(0, -((push:GetAttribute("Strength") :: number?) or 4000), 0)
			push.Enabled = on
			local flame = base and base:FindFirstChild("Flame", true) :: ParticleEmitter?
			if flame then
				flame.Enabled = on
			end
		end
	elseif item == "Conveyor" then
		local belt = partNamed(model, "Belt")
		if belt then
			belt.AssemblyLinearVelocity = if on then belt.CFrame.XVector * ((belt:GetAttribute("BeltSpeed") :: number?) or 10) else Vector3.zero
		end
	end
end

-- A signal arrives at an input piece.
local function deliver(plot: Plot, index: number)
	local live = plot.live
	local piece = plot.bp.pieces[index]
	if not live or not piece then
		return
	end
	if piece.item == "Cannon" then
		fireCannon(plot, index)
	elseif piece.item == "Crate" then
		explodeCrate(plot, index)
	else
		setOn(plot, index, not live.on[index])
	end
end

-- An output piece fires: every wire from it delivers.
local function pulse(plot: Plot, index: number)
	if not plot.live then
		return
	end
	local model = plot.models[index]
	if model then
		flash(model)
	end
	for _, wire in plot.bp.wires do
		if wire.from == index then
			deliver(plot, wire.to)
		end
	end
end

local dummyOf = Dummies.of

-- Whether something running into a build's TNT crate may set it off: only the build's own player
-- and their things (their props, their dummies in flight, the build itself). Anyone else's ball or
-- thrown dummy bounces off: a crate is never a way to blow someone else up.
local function mayTrigger(plot: Plot, other: BasePart): boolean
	local me = plot.player
	local folder = buildsFolder()
	if other:IsDescendantOf(folder) then
		return other:IsDescendantOf(plot.folder)
	end
	local character = me.Character
	if character and other:IsDescendantOf(character) then
		return true
	end
	local props = Workspace:FindFirstChild("Props")
	if props and other:IsDescendantOf(props) then
		local prop: Instance = other
		while prop.Parent and prop.Parent ~= props do
			prop = prop.Parent :: Instance
		end
		return prop:GetAttribute("Owner") == me.UserId
	end
	local dummy = dummyOf(other)
	if dummy then
		return Dummies.sentBy(dummy, me.UserId)
	end
	return false
end

local function bounceDummy(plot: Plot, dummy: Model, other: BasePart, push: Vector3, maxBodySpeed: number?)
	local mass = (dummy:GetAttribute("Mass") :: number?) or 10
	DummyControl.hit(dummy, other, push * mass, other.Position, maxBodySpeed, plot.player)
end

-- Contacts judged here for dummies the server simulates (the owner's client does its own).
local function watchContacts(plot: Plot, live: Live, index: number, model: Model)
	local lastBounce: { [Model]: number } = {}
	local function serverDummy(other: BasePart): Model?
		local dummy = dummyOf(other)
		if dummy and DummyControl.ownerOf(dummy) == nil then
			local now = os.clock()
			if lastBounce[dummy] and now - lastBounce[dummy] < 0.5 then
				return nil
			end
			lastBounce[dummy] = now
			return dummy
		end
		return nil
	end
	for _, part in Factory.parts(model) do
		if part.Name == "TrampolinePad" then
			table.insert(live.connections, part.Touched:Connect(function(other)
				local dummy = serverDummy(other)
				if dummy then
					local v = other.AssemblyLinearVelocity
					bounceDummy(plot, dummy, other, Vector3.new(v.X * 0.3, HitMath.TRAMPOLINE_SPEED, v.Z * 0.3))
					FxService.hit(part.Position, 40, "Trampoline")
				end
			end))
		elseif part.Name == "BumperBall" then
			table.insert(live.connections, part.Touched:Connect(function(other)
				local dummy = serverDummy(other)
				if dummy then
					local away = other.Position - part.Position
					local flat = Vector3.new(away.X, 0, away.Z)
					local dir = (if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis) * 0.85 + Vector3.new(0, 0.5, 0)
					bounceDummy(plot, dummy, other, dir.Unit * HitMath.BUMPER_SPEED)
					FxService.hit(other.Position, 35, "Trampoline")
				end
			end))
		elseif part.Name == "SensorPad" then
			table.insert(live.connections, part.Touched:Connect(function(other)
				local dummy = dummyOf(other)
				if dummy and DummyControl.ownerOf(dummy) == nil then
					BuildService.sensor(plot.player, index)
				end
			end))
		elseif part.Name ~= "Belt" then
			-- Moving machine parts knock over dummies the server simulates.
			table.insert(live.connections, part.Touched:Connect(function(other)
				local root = part.AssemblyRootPart
				if part.Anchored or not root or root.Anchored then
					return
				end
				local dummy = dummyOf(other)
				if not dummy or DummyControl.ownerOf(dummy) ~= nil then
					return
				end
				local body = dummy:FindFirstChild("UpperTorso") :: BasePart?
				if body and not HitMath.isTracked(body) then
					HitMath.track(body)
				end
				if not HitMath.isTracked(root) then
					HitMath.track(root)
				end
				local launch = HitMath.machineLaunch(part, other, body)
				if launch and HitMath.firstHit(root, dummy) and serverDummy(other) then
					bounceDummy(plot, dummy, other, launch, HitMath.MACHINE_MAX_SPEED)
					FxService.hit(other.Position, launch.Magnitude, "Machine")
				end
			end))
		end
		if part.Name == "TNT" then
			table.insert(live.connections, part.Touched:Connect(function(other)
				if other:IsDescendantOf(model) then
					return
				end
				local rel = (other.AssemblyLinearVelocity - part.AssemblyLinearVelocity).Magnitude
				if rel >= CRATE_IMPACT_SPEED and mayTrigger(plot, other) then
					explodeCrate(plot, index)
				end
			end))
		end
	end
end

local function startLive(plot: Plot)
	rebuild(plot)
	tokens += 1
	local live: Live = { token = tokens, wired = {}, on = {}, spent = {}, lastSensor = {}, wheelSign = {}, connections = {} }
	plot.live = live
	for _, wire in plot.bp.wires do
		live.wired[wire.to] = true
	end

	-- 1. Weld every piece to what it was placed on; pin floor pieces.
	for i, piece in plot.bp.pieces do
		local model = plot.models[i]
		local parts = Factory.parts(model)
		if piece.parent > 0 then
			local parentParts = Factory.parts(plot.models[piece.parent])
			local target = parentParts[piece.parentPart] or parentParts[1]
			local w = Instance.new("WeldConstraint")
			w.Name = "Placed"
			w.Part0 = parts[1]
			w.Part1 = target
			w.Parent = parts[1]
		end
	end
	-- 2. Unfreeze. Pinned floor pieces keep their attach part anchored; belts always stay put.
	for i, piece in plot.bp.pieces do
		local model = plot.models[i]
		local parts = Factory.parts(model)
		local pinned = piece.parent == 0 and piece.pinned
		for k, part in parts do
			local keep = (k == 1 and pinned) or part.Name == "Belt"
			if part.Name == "Blade" then
				-- Fan blades spin as a visual; only when the fan cannot move.
				keep = pinned
				if pinned then
					local fix = part:FindFirstChildOfClass("WeldConstraint")
					if fix then
						fix:Destroy()
					end
					for _, other in parts do
						for _, d in other:GetChildren() do
							if d:IsA("WeldConstraint") and (d.Part0 == part or d.Part1 == part) then
								d:Destroy()
							end
						end
					end
					CollectionService:AddTag(part, "Spinner")
				end
			end
			part.Anchored = keep
		end
	end
	-- 3. Hand every moving assembly to the player's client.
	for _, model in plot.models do
		for _, part in Factory.parts(model) do
			if not part.Anchored then
				pcall(part.SetNetworkOwner, part, plot.player)
			end
		end
	end
	-- Wheels drive "forward" relative to what they are mounted on: a wheel on the left side of a
	-- body has its axle pointing the other way, so it must spin the other way for the car to go.
	local origin = BuildService.originFor(plot.player)
	for i, piece in plot.bp.pieces do
		if piece.item == "Wheel" then
			local axle = Factory.cframeOf(piece, origin).UpVector
			local reference = if piece.parent > 0
				then Factory.cframeOf(plot.bp.pieces[piece.parent], origin).RightVector
				else Vector3.xAxis
			local d = axle:Dot(reference)
			if math.abs(d) < 0.5 then
				local look = if piece.parent > 0 then Factory.cframeOf(plot.bp.pieces[piece.parent], origin).LookVector else Vector3.zAxis
				d = axle:Dot(look)
			end
			-- Positive spin about the axle rolls the body backwards (towards +Z for an unturned
			-- body), so flip it: Forward is the way the body faces, away from the default camera.
			live.wheelSign[i] = if d < 0 then 1 else -1
		end
	end
	-- 4. Machines start: unwired ones run, wired ones wait for a signal.
	for i, piece in plot.bp.pieces do
		local item = Catalog.byId[piece.item]
		if item.input and piece.item ~= "Cannon" and piece.item ~= "Crate" then
			setOn(plot, i, not live.wired[i])
		end
		watchContacts(plot, live, i, plot.models[i])
	end
	-- 5. Loops: timers, unwired pistons and cannons, fans, the leash.
	local token = live.token
	local function alive(): boolean
		return plot.live ~= nil and (plot.live :: Live).token == token
	end
	task.spawn(function()
		local gone: { [BasePart]: boolean } = {}
		while true do
			task.wait(LEASH_CHECK)
			if not alive() then
				return
			end
			for _, model in plot.models do
				for _, part in Factory.parts(model) do
					if not part.Anchored and not gone[part] and part.Parent then
						local offset = part.Position - origin
						local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
						if flat > LEASH_RADIUS or offset.Y < LEASH_LOW or offset.Y > LEASH_HIGH then
							local group = part:GetConnectedParts(true)
							FxService.shatter(part.Position)
							for _, p in group do
								if p:IsA("BasePart") and p:IsDescendantOf(plot.folder) then
									gone[p] = true
									p.Anchored = true
									p.CanCollide = false
									p.CanTouch = false
									p.CanQuery = false
									p.Transparency = 1
									for _, d in p:GetDescendants() do
										if d:IsA("Decal") or d:IsA("Texture") then
											d.Transparency = 1
										elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") then
											d.Enabled = false
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end)
	for i, piece in plot.bp.pieces do
		if piece.item == "Timer" then
			local base = partNamed(plot.models[i], "Base")
			local period = (base and base:GetAttribute("Period") :: number?) or 1
			task.spawn(function()
				while true do
					task.wait(period)
					if not alive() then
						return
					end
					pulse(plot, i)
				end
			end)
		elseif piece.item == "Piston" and not live.wired[i] then
			task.spawn(function()
				while true do
					task.wait(PISTON_CYCLE)
					if not alive() then
						return
					end
					setOn(plot, i, not live.on[i])
				end
			end)
		elseif piece.item == "Cannon" and not live.wired[i] then
			task.spawn(function()
				task.wait(0.6)
				while alive() do
					fireCannon(plot, i)
					task.wait(CANNON_CYCLE)
				end
			end)
		elseif piece.item == "Fan" then
			task.spawn(function()
				while alive() do
					if live.on[i] then
						local model = plot.models[i]
						local ring = model and partNamed(model, "Base")
						if ring then
							local dir = ring.CFrame.XVector
							local origin = ring.Position
							local strength = (ring:GetAttribute("Wind") :: number?) or 11
							for _, dummy in ToyService.dummiesNear(origin, 40) do
								local chest = dummy:FindFirstChild("UpperTorso") :: BasePart?
								if chest then
									local offset = chest.Position - origin
									local along = offset:Dot(dir)
									if along > 0 and offset.Unit:Dot(dir) > 0.85 then
										DummyControl.push(dummy, dir * strength * (1 - along / 40) + Vector3.new(0, 2, 0), plot.player)
									end
								end
							end
						end
					end
					task.wait(0.2)
				end
			end)
		end
	end
end

local function stopLive(plot: Plot)
	local live = plot.live
	if not live then
		return
	end
	plot.live = nil
	for _, c in live.connections do
		c:Disconnect()
	end
	rebuild(plot)
end

------------------------------------------------------------------------------------------------
-- Operations

local ops: { [string]: (Plot, { [string]: any }) -> (boolean, string?) } = {}

ops.place = function(plot, a)
	local item = type(a.item) == "string" and Catalog.byId[a.item]
	if not item then
		return false, "Unknown part"
	end
	if #plot.bp.pieces >= Catalog.MAX_PARTS then
		return false, "Your build is full (" .. Catalog.MAX_PARTS .. " parts)"
	end
	if typeof(a.pos) ~= "Vector3" or not isInt(a.rot, 0, 23) or not isInt(a.parent, 0, #plot.bp.pieces) then
		return false, "Bad placement"
	end
	local parentPart = if isInt(a.parentPart, 1, 8) then a.parentPart else 1
	if a.parent > 0 and parentPart > #Factory.parts(plot.models[a.parent]) then
		return false, "Bad placement"
	end
	local color = if isInt(a.color, 0, #Catalog.palette) and item.paintable then a.color else 0
	local piece: Codec.Piece = {
		item = item.id,
		pos = a.pos,
		rot = a.rot,
		color = color,
		setting = 1,
		pinned = a.parent == 0,
		parent = a.parent,
		parentPart = parentPart,
	}
	local test = Codec.clone(plot.bp)
	table.insert(test.pieces, piece)
	local ok, err = Codec.validate(test)
	if not ok then
		return false, if err and string.find(err, "outside") then "Too far from the lab" else "That does not fit there"
	end
	if overlapsAny(plot, piece) then
		return false, "Something is already there"
	end
	snapshot(plot)
	table.insert(plot.bp.pieces, piece)
	plot.models[#plot.bp.pieces] = buildModel(plot, #plot.bp.pieces)
	return true, nil
end

ops.delete = function(plot, a)
	if not isInt(a.index, 1, #plot.bp.pieces) then
		return false, "Nothing to delete"
	end
	snapshot(plot)
	-- The piece and everything built on it.
	local removed: { [number]: boolean } = {}
	for i, piece in plot.bp.pieces do
		removed[i] = i == a.index or (piece.parent > 0 and removed[piece.parent] == true)
	end
	local remap: { [number]: number } = {}
	local kept: { Codec.Piece } = {}
	for i, piece in plot.bp.pieces do
		if not removed[i] then
			table.insert(kept, piece)
			remap[i] = #kept
		end
	end
	for _, piece in kept do
		if piece.parent > 0 then
			piece.parent = remap[piece.parent]
		end
	end
	local wires: { Codec.Wire } = {}
	for _, w in plot.bp.wires do
		if remap[w.from] and remap[w.to] then
			table.insert(wires, { from = remap[w.from], to = remap[w.to] })
		end
	end
	plot.bp = { pieces = kept, wires = wires }
	rebuild(plot)
	return true, nil
end

ops.paint = function(plot, a)
	if not isInt(a.index, 1, #plot.bp.pieces) or not isInt(a.color, 1, #Catalog.palette) then
		return false, "Bad paint"
	end
	local piece = plot.bp.pieces[a.index]
	if not Catalog.byId[piece.item].paintable then
		return false, "That part has its own colors"
	end
	if piece.color == a.color then
		return true, nil
	end
	snapshot(plot)
	piece.color = a.color
	plot.models[a.index]:Destroy()
	plot.models[a.index] = buildModel(plot, a.index)
	return true, nil
end

ops.tune = function(plot, a)
	if not isInt(a.index, 1, #plot.bp.pieces) then
		return false, "Nothing to tune"
	end
	local piece = plot.bp.pieces[a.index]
	local settings = Catalog.byId[piece.item].settings
	if not settings then
		return false, "That part has no settings"
	end
	snapshot(plot)
	piece.setting = piece.setting % #settings + 1
	plot.models[a.index]:Destroy()
	plot.models[a.index] = buildModel(plot, a.index)
	return true, settings[piece.setting]
end

ops.pin = function(plot, a)
	if not isInt(a.index, 1, #plot.bp.pieces) then
		return false, "Nothing to pin"
	end
	local piece = plot.bp.pieces[a.index]
	if piece.parent ~= 0 then
		return false, "Only parts on the floor can be pinned"
	end
	snapshot(plot)
	piece.pinned = not piece.pinned
	return true, if piece.pinned then "Pinned to the floor" else "Free to move"
end

ops.wire = function(plot, a)
	local n = #plot.bp.pieces
	if not isInt(a.from, 1, n) or not isInt(a.to, 1, n) or a.from == a.to then
		return false, "Bad wire"
	end
	local from, to = Catalog.byId[plot.bp.pieces[a.from].item], Catalog.byId[plot.bp.pieces[a.to].item]
	if not from.output then
		return false, "Start a wire at a button, timer or sensor"
	end
	if not to.input then
		return false, to.label .. " cannot take a signal"
	end
	for i, w in plot.bp.wires do
		if w.from == a.from and w.to == a.to then
			snapshot(plot)
			table.remove(plot.bp.wires, i)
			return true, "Wire removed"
		end
	end
	if #plot.bp.wires >= Catalog.MAX_WIRES then
		return false, "Too many wires"
	end
	snapshot(plot)
	table.insert(plot.bp.wires, { from = a.from, to = a.to })
	return true, "Wired"
end

ops.undo = function(plot)
	local previous = table.remove(plot.undo)
	if not previous then
		return false, "Nothing to undo"
	end
	plot.bp = previous
	rebuild(plot)
	return true, nil
end

ops.clear = function(plot)
	if #plot.bp.pieces == 0 then
		return true, nil
	end
	snapshot(plot)
	plot.bp = Codec.empty()
	rebuild(plot)
	return true, nil
end

ops.play = function(plot)
	if #plot.bp.pieces == 0 then
		return false, "Build something first"
	end
	startLive(plot)
	return true, nil
end

ops.stop = function(plot)
	local wasLive = plot.live ~= nil
	stopLive(plot)
	-- Stop rewinds the scene: the dummies of the player's own lab go back to their places too.
	if wasLive then
		Lab.rewind(plot.player)
	end
	return true, nil
end

local function plotOf(player: Player): Plot
	local plot = plots[player]
	if plot then
		return plot
	end
	local folder = Instance.new("Folder")
	folder.Name = tostring(player.UserId)
	folder:SetAttribute("Owner", player.UserId)
	folder.Parent = buildsFolder()
	plot = {
		player = player,
		bp = Codec.empty(),
		models = {},
		folder = folder,
		undo = {},
		live = nil,
		window = { start = 0, count = 0 },
	}
	plots[player] = plot
	return plot
end

-- Runs an operation for a player. Returns (ok, message).
function BuildService.request(player: Player, op: unknown, args: unknown): (boolean, string?)
	if type(op) ~= "string" or not ops[op] then
		return false, "Unknown action"
	end
	local a = if type(args) == "table" then args :: { [string]: any } else {}
	local plot = plotOf(player)
	if not allowed(plot) then
		return false, "Slow down"
	end
	if plot.live and op ~= "stop" and op ~= "play" then
		return false, "Press Stop to keep building"
	end
	if op == "play" and plot.live then
		stopLive(plot)
	end
	local ok, message = ops[op](plot, a)
	publish(plot, message)
	return ok, message
end

-- A button was pressed or a sensor saw a dummy (from the owner's client or the server itself).
function BuildService.press(player: Player, index: number)
	local plot = plots[player]
	if not plot or not plot.live or not plot.bp.pieces[index] or plot.bp.pieces[index].item ~= "Button" then
		return
	end
	pulse(plot, index)
end

function BuildService.sensor(player: Player, index: number)
	local plot = plots[player]
	local live = plot and plot.live
	if not plot or not live or not plot.bp.pieces[index] or plot.bp.pieces[index].item ~= "Sensor" then
		return
	end
	local now = os.clock()
	if live.lastSensor[index] and now - live.lastSensor[index] < SENSOR_COOLDOWN then
		return
	end
	live.lastSensor[index] = now
	pulse(plot, index)
end

-- For saves and tests.
function BuildService.blueprintOf(player: Player): Codec.Blueprint
	return Codec.clone(plotOf(player).bp)
end

function BuildService.load(player: Player, bp: Codec.Blueprint): (boolean, string?)
	local ok, err = Codec.validate(bp)
	if not ok then
		return false, err
	end
	local plot = plotOf(player)
	stopLive(plot)
	snapshot(plot)
	plot.bp = Codec.clone(bp)
	rebuild(plot)
	publish(plot, nil)
	return true, nil
end

function BuildService.isPlaying(player: Player): boolean
	local plot = plots[player]
	return plot ~= nil and plot.live ~= nil
end

function BuildService.modelsOf(player: Player): { Model }
	local plot = plots[player]
	return if plot then table.clone(plot.models) else {}
end

function BuildService.start()
	buildsFolder()
	stateEvent = Net.event(Net.Names.BuildState)
	-- A player who gets a lab later (one came free): their build moves into it, stopped.
	table.insert(Lab.onMoved, function(player: Player)
		local plot = plots[player]
		if plot then
			if plot.live then
				stopLive(plot)
			end
			rebuild(plot)
			publish(plot, "Your build moved into your new lab")
		end
	end)
	Net.func(Net.Names.BuildRequest).OnServerInvoke = function(player, op, args)
		local ok, result, message = pcall(BuildService.request, player, op, args)
		if not ok then
			log.warn("request failed: " .. tostring(result))
			return false, "Something went wrong"
		end
		return result, message
	end
	local signalWindow: { [Player]: { start: number, count: number } } = {}
	Net.event(Net.Names.BuildSignal).OnServerEvent:Connect(function(player, kind, index)
		if not isInt(index, 1, Catalog.MAX_PARTS) then
			return
		end
		local now = os.clock()
		local w = signalWindow[player]
		if not w or now - w.start > 1 then
			w = { start = now, count = 0 }
			signalWindow[player] = w
		end
		w.count += 1
		if w.count > 20 then
			return
		end
		if kind == "Press" then
			BuildService.press(player, index :: number)
		elseif kind == "Sensor" then
			BuildService.sensor(player, index :: number)
		end
	end)
	-- Blasts set off build crates nearby: only in the build of whoever set the blast off (nobody
	-- can detonate someone else's machine at them).
	table.insert(ToyService.blastListeners, function(center: Vector3, radius: number, source: Player?)
		for owner, plot in plots do
			if plot.live and owner == source then
				for i, piece in plot.bp.pieces do
					if piece.item == "Crate" and not plot.live.spent[i] then
						local crate = plot.models[i] and partNamed(plot.models[i], "TNT")
						if crate and (crate.Position - center).Magnitude < radius * 0.7 then
							task.delay(0.12, explodeCrate, plot, i)
						end
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local plot = plots[player]
		plots[player] = nil
		signalWindow[player] = nil
		if plot then
			if plot.live then
				for _, c in plot.live.connections do
					c:Disconnect()
				end
			end
			plot.live = nil
			plot.folder:Destroy()
		end
	end)
	-- Studio only: drive the first player's workshop from the command bar and tests.
	if game:GetService("RunService"):IsStudio() then
		local debug = Instance.new("BindableFunction")
		debug.Name = "DebugBuild"
		debug.OnInvoke = function(op: string, args: any)
			local player = Players:GetPlayers()[1]
			if not player then
				return false, "no player"
			end
			if op == "blueprint" then
				return Codec.clone(plotOf(player).bp)
			elseif op == "press" then
				BuildService.press(player, args)
				return true
			end
			return BuildService.request(player, op, args)
		end
		debug.Parent = game:GetService("ServerStorage")
	end
	log.info("ready")
end

return BuildService
