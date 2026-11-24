--!strict
-- 20 Nov 2026 (the owner: "make the monsters alive"): the lab creatures move on this screen while
-- they wait for a dummy. The server tags each creature model CreatureLife with its kind (Creature)
-- and its rest pose (LifeHome); here each one breathes and does its own thing, and the ones that
-- can look at you turn to the nearest player:
--   Spider   breathes on its web, now and then creeps a little to the side and back
--   Plant    sways, turns its head to you, snaps at the air every few seconds
--   Frog     breathes (a throat bob), turns to you, hops on the spot now and then
--   Chicken  pecks at the straw, turns its head this way and that
--   Whale    the shark: circles its pool under the water, only the fin up
--   Washer   rumbles through a short spin now and then
--   Mole     peeks out of its hole, looks round and ducks back down
-- While its machine works (the folder's Busy, LabCreatures.swallow) the server moves it and this
-- rests. Only creatures within LIFE_RANGE of the camera are moved, at most 30 times a second.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CreatureLife = {}

local LITE = not game:GetService("UserInputService").KeyboardEnabled -- (0.50.3, fps)
CreatureLife.LIFE_RANGE = if LITE then 100 else 160
CreatureLife.STEP = if LITE then 1 / 20 else 1 / 30
CreatureLife.TURN_REACH = 45 -- studs: a player this close is looked at
CreatureLife.TURN_MAX = math.rad(70)

type Life = { model: Model, kind: string, home: CFrame, seed: number, yaw: number }

local lives: { [Model]: Life } = {}

local function add(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local home = model:GetAttribute("LifeHome")
	local kind = model:GetAttribute("Creature")
	if typeof(home) ~= "CFrame" or type(kind) ~= "string" then
		return
	end
	lives[model] = { model = model, kind = kind, home = home, seed = (#model.Name * 7.3 + home.Position.X) % 10, yaw = 0 }
end

local function remove(model: Instance)
	lives[model :: Model] = nil
end

-- How far round (radians, about the creature's own up) the nearest player stands, or nil.
local function towardPlayer(home: CFrame): number?
	local best: Vector3? = nil
	local bestD = CreatureLife.TURN_REACH
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			local d = (r.Position - home.Position).Magnitude
			if d < bestD then
				best, bestD = r.Position, d
			end
		end
	end
	if not best then
		return nil
	end
	local rel = home:PointToObjectSpace(best)
	return math.atan2(-rel.X, -rel.Z)
end

-- The creature's pose this moment, as an offset from its rest pose.
local function pose(l: Life, t: number): CFrame
	local s = l.seed
	local k = l.kind
	if k == "Spider" then
		local creep = math.max(0, math.sin(t * 0.25 + s)) ^ 3 * 2.5
		return CFrame.new(creep, math.sin(t * 2.2) * 0.12, 0)
	elseif k == "Plant" then
		local snap = math.max(0, math.sin(t * 0.9 + s)) ^ 16
		return CFrame.Angles(math.sin(t * 1.3) * 0.05 - snap * 0.25, l.yaw, math.sin(t * 0.9) * 0.05) * CFrame.new(0, -snap * 0.6, 0)
	elseif k == "Frog" then
		local hopPhase = (t * 0.22 + s) % 1
		local hop = if hopPhase < 0.12 then math.sin(hopPhase / 0.12 * math.pi) * 2.2 else 0
		return CFrame.new(0, hop + math.abs(math.sin(t * 3.1)) * 0.05, 0) * CFrame.Angles(0, l.yaw, 0)
	elseif k == "Chicken" then
		local peck = math.max(0, math.sin(t * 2.6 + s)) ^ 8
		local look = math.sin(t * 0.7 + s) * 0.6
		return CFrame.Angles(0, l.yaw * 0.5 + look, 0) * CFrame.Angles(-peck * 0.45, 0, 0)
	elseif k == "Whale" then
		local a = t * 0.55 + s
		local dx, dz = 5 * math.cos(a), -5.5 * math.sin(a)
		return CFrame.new(5 * math.sin(a), math.sin(t * 0.8) * 0.2, 5.5 * math.cos(a)) * CFrame.Angles(0, math.atan2(-dx, -dz) + math.sin(t * 3) * 0.08, 0)
	elseif k == "Washer" then
		local spin = math.max(0, math.sin(t * 0.35 + s)) ^ 20
		return CFrame.new(math.sin(t * 60) * 0.12 * spin, 0, math.cos(t * 47) * 0.12 * spin)
	elseif k == "Mole" then
		local cycle = (t * 0.12 + s) % 1
		local up = if cycle < 0.3 then math.sin(cycle / 0.3 * math.pi) else 0
		return CFrame.new(0, up * 6.4, 0) * CFrame.Angles(0, math.sin(t * 2) * 0.6 * up, 0)
	end
	return CFrame.new()
end

local LOOKS = { Plant = true, Frog = true, Chicken = true }

function CreatureLife.start()
	for _, m in CollectionService:GetTagged("CreatureLife") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("CreatureLife"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("CreatureLife"):Connect(remove)
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < CreatureLife.STEP then
			return
		end
		local step = acc
		acc = 0
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local camPos = cam.CFrame.Position
		local t = os.clock()
		for model, l in lives do
			if not model.Parent then
				lives[model] = nil
				continue
			end
			local busy = model.Parent:GetAttribute("Busy") == true
			-- (0.50.3, fps: one out of view is not moved.)
			local off = l.home.Position - camPos
			local far = off.Magnitude
			if busy or far > CreatureLife.LIFE_RANGE or (far > 30 and off:Dot(cam.CFrame.LookVector) < far * 0.3) then
				continue
			end
			if LOOKS[l.kind] then
				local want = towardPlayer(l.home)
				local goal = if want then math.clamp(want, -CreatureLife.TURN_MAX, CreatureLife.TURN_MAX) else 0
				l.yaw += (goal - l.yaw) * math.clamp(step * 3, 0, 1)
			end
			model:PivotTo(l.home * pose(l, t))
		end
	end)
end

return CreatureLife
