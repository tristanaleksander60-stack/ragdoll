--!strict
-- The first five seconds: when you first appear this visit, a dummy appears a little way in front of
-- you and walks up to you (its Home is just in front of you, so the ordinary dummy brain brings it
-- over and turns it to face you). Your client simulates it, so the first shot lands at once. One
-- per player per visit; after it has been hit it stays a while to be played with, then goes in a
-- puff (and anyway after GREETER_LIFETIME s, or when you leave). A dead one lies its DEAD_HOLD.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DummyFactory = require(script.Parent.DummyFactory)
local Lab = require(script.Parent.Lab)

local START_DISTANCE = 16 -- studs from you where it appears (in view, a few steps away)
local STOP_DISTANCE = 8 -- where it stops: straight in front of you, still in front of the camera
-- It comes in from the side if it can (in clear view, not from behind the lab's row of dummies):
-- the first of these headings (degrees off straight ahead) with a clear walk wins.
local HEADINGS = { 40, -40, 25, -25, 0 }
local CLEAR = 4 -- studs: no other dummy this close to its walk
local SIDE_STEP = 3.5 -- studs off the middle where it stops
local SHIRT_COLOR = Color3.fromRGB(255, 140, 40)
local SHIRT = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
local STAY_AFTER_HIT = 12 -- s it stays once hit
local GREETER_LIFETIME = 45 -- s at most
local FELL_BELOW = -60

local GreeterService = {}

local greeted: { [Player]: boolean } = {}
local greeters: { [Player]: Model } = {}
local stayAfterHit = STAY_AFTER_HIT

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function goAway(player: Player, model: Model)
	if greeters[player] == model then
		greeters[player] = nil
	end
	if model.Parent then
		local pelvis = model:FindFirstChild("LowerTorso")
		if pelvis and pelvis:IsA("BasePart") then
			Lab.poof(pelvis.Position)
		end
		model:Destroy()
	end
end

-- How close the walk from a to b passes to any other dummy.
local function nearestDummy(a: Vector3, b: Vector3): number
	local dummies = Workspace:FindFirstChild("Dummies")
	local best = math.huge
	if not dummies then
		return best
	end
	local ab = flat(b - a)
	local length = ab.Magnitude
	for _, model in dummies:GetChildren() do
		local pelvis = model:FindFirstChild("LowerTorso")
		if pelvis and pelvis:IsA("BasePart") then
			local ap = flat(pelvis.Position - a)
			local t = if length > 0 then math.clamp(ap:Dot(ab) / (length * length), 0, 1) else 0
			best = math.min(best, (ap - ab * t).Magnitude)
		end
	end
	return best
end

-- Where it starts and stops for a player standing at `root`: it stops straight in front of you
-- and comes in from the first heading with open floor, no wall and no other dummy in the way.
function GreeterService.route(root: BasePart): (Vector3?, Vector3?)
	local ahead = flat(root.CFrame.LookVector)
	ahead = if ahead.Magnitude > 0.01 then ahead.Unit else Vector3.zAxis
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ignore, dummies)
	end
	if root.Parent then
		table.insert(ignore, root.Parent)
	end
	params.FilterDescendantsInstances = ignore
	-- It stops a little to the side it came from: straight ahead it would stand behind your own
	-- avatar's head in the camera's view.
	local side = ahead:Cross(Vector3.yAxis)
	local stop = root.Position + ahead * STOP_DISTANCE
	for _, degrees in HEADINGS do
		local heading = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(degrees)):VectorToWorldSpace(ahead)
		local offset = side * (if degrees < 0 then SIDE_STEP else -SIDE_STEP)
		stop = root.Position + ahead * STOP_DISTANCE + offset
		local start = root.Position + heading * START_DISTANCE
		local wall = Workspace:Raycast(start, stop - start, params) or Workspace:Raycast(root.Position, start - root.Position, params)
		local floor = Workspace:Raycast(start + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), params)
		if not wall and floor and nearestDummy(start, stop) > CLEAR then
			return start, stop
		end
	end
	-- Nothing clear from the sides: straight ahead, closer if a wall is in the way; no room at all
	-- (facing a wall, at an edge) and there is no greeter (the lab's own dummies are still there).
	local wall = Workspace:Raycast(root.Position, ahead * START_DISTANCE, params)
	local distance = if wall then (wall.Position - root.Position).Magnitude - 3 else START_DISTANCE
	if distance < STOP_DISTANCE + 3 then
		return nil, nil
	end
	local start = root.Position + ahead * distance
	stop = root.Position + ahead * STOP_DISTANCE - side * SIDE_STEP
	if
		not Workspace:Raycast(start + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), params)
		or Workspace:Raycast(start, stop - start, params)
		or nearestDummy(start, stop) <= CLEAR
	then
		return nil, nil
	end
	return start, stop
end

-- Sends the greeter to a player who has just appeared (once per visit).
function GreeterService.send(player: Player): Model?
	if greeted[player] then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	-- (SPAWN_V2 step 1, SPAWN_ROOM: no greeter when the player already has the near cap round them; asked again later)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SPAWN_ROOM and (require(script.Parent:WaitForChild("RagdollDirector")) :: any).room(player) <= 0 then
		return nil
	end
	greeted[player] = true
	-- V8-0.2 (audit A): the avatar appears where Roblox spawns it, and Lab moves it into its own lab
	-- a frame later (task.defer). Wait for that move (at most 3 s), so the route is worked out in the
	-- lab, not at the spawn it just left.
	local waited = os.clock()
	-- (Also while the lab is not even claimed yet: a Studio play test caught the greeter on the plaza.)
	while (Lab.plotIndex(player) == nil or Lab.ownerAt(root.Position) ~= player) and os.clock() - waited < 3 do
		task.wait(0.1)
		if not root.Parent or player.Character ~= character then
			return nil
		end
	end
	local start, stop = GreeterService.route(root)
	if not start or not stop then
		return nil
	end
	local model = DummyFactory.spawn(start, root.Position, player)
	model:SetAttribute("Greeter", player.UserId)
	-- An orange shirt: it is the one walking up to you, not one of the lab's row.
	for _, name in SHIRT do
		local piece = model:FindFirstChild(name)
		if piece and piece:IsA("BasePart") then
			piece.Color = SHIRT_COLOR
		end
	end
	local pelvis = model:FindFirstChild("LowerTorso")
	local y = if pelvis and pelvis:IsA("BasePart") then pelvis.Position.Y else start.Y
	model:SetAttribute("Home", Vector3.new(stop.X, y, stop.Z))
	model:SetAttribute("HomeLook", Vector3.new(root.Position.X, y, root.Position.Z))
	greeters[player] = model

	local born = os.clock()
	task.spawn(function()
		local hitAt: number? = nil
		while model.Parent and player.Parent do
			local p = model:FindFirstChild("LowerTorso")
			if not p or not p:IsA("BasePart") or p.Position.Y < FELL_BELOW then
				break
			end
			if not hitAt and model:GetAttribute("HitBy") ~= nil then
				hitAt = os.clock()
			end
			-- (Round 4, M10: a dead one stays for its DEAD_HOLD; VitalsService takes it and the loop ends.)
			if model:GetAttribute("Vital") == "Dead" then
				task.wait(0.5)
				continue
			end
			local now = os.clock()
			if now - born > GREETER_LIFETIME or (hitAt and now - hitAt > stayAfterHit) then
				break
			end
			task.wait(0.5)
		end
		goAway(player, model)
	end)
	return model
end

-- Tests: the greeter a player has now, a fresh one, and a shorter stay.
function GreeterService.of(player: Player): Model?
	return greeters[player]
end

function GreeterService.resetForTest(player: Player, stay: number?)
	greeted[player] = nil
	local old = greeters[player]
	if old then
		goAway(player, old)
	end
	stayAfterHit = stay or STAY_AFTER_HIT
end

function GreeterService.start()
	Players.PlayerRemoving:Connect(function(player)
		local model = greeters[player]
		if model then
			goAway(player, model)
		end
		greeted[player] = nil
	end)
end

return GreeterService
