--!strict
-- F80 (owner: "Lav en back to spawn knap i more"; Config.BACK_TO_SPAWN): MORE's BACK TO SPAWN row fires Net "Teleport"
-- "Spawn" (no arguments). The server checks it (a 5 s cooldown a player, only the word "Spawn"), waits until the player
-- stands (not ragdolled, not carried: at most 4 s), gets them out of a seat first (the vehicle stays where it was), and
-- sets them on a free spot of the spawn plaza (a small random ring, never on another player), facing down the
-- boulevard (+Z). In a place without the owner map: the first SpawnLocation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local BackToSpawn = {}

BackToSpawn.COOLDOWN = 5
BackToSpawn.PLAZA = (function(): Vector2 -- (M4: the compact plan's Spawn item; round 3 was (-30, -300))
	local ok, P = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
	end)
	local it = ok and P and P.ITEMS and P.ITEMS.Spawn
	return if it then it.at else Vector2.new(-30, -300)
end)() -- (lab space: the spawn plaza's south half, by the stair to the boulevard)

local last: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function spawnCentre(player: Player): Vector3?
	local ok, idx = pcall(function()
		return (require(script.Parent:WaitForChild("Lab")) :: any).plotIndex(player)
	end)
	local root = Workspace:FindFirstChild("Playground")
	local lab = ok and idx and root and root:FindFirstChild("Lab" .. tostring(idx))
	local om = lab and lab:FindFirstChild("OwnerMap")
	local grass = om and om:FindFirstChild("OwnerGrass")
	if grass and grass:IsA("BasePart") then
		local c = (require(script.Parent:WaitForChild("LabOwnerMap")) :: any).CENTER :: Vector2
		local o = Vector3.new(grass.Position.X - c.X, grass.Position.Y, grass.Position.Z - c.Y)
		return Vector3.new(o.X + BackToSpawn.PLAZA.X, o.Y, o.Z + BackToSpawn.PLAZA.Y)
	end
	for _, d in Workspace:GetDescendants() do
		if d:IsA("SpawnLocation") then
			return d.Position
		end
	end
	return nil
end

local function go(player: Player)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and hum and root and root:IsA("BasePart")) or hum.Health <= 0 then
		return
	end
	-- wait until it stands (a ragdolled fall, being carried), at most 4 s
	local t0 = os.clock()
	while os.clock() - t0 < 4 do
		local st = hum:GetState()
		local carried = player:GetAttribute("HeldBy") ~= nil or character:GetAttribute("Held") == true
		if st ~= Enum.HumanoidStateType.Physics and st ~= Enum.HumanoidStateType.FallingDown and st ~= Enum.HumanoidStateType.Ragdoll and not carried then
			break
		end
		task.wait(0.2)
	end
	-- out of a vehicle first: it stays where it was
	if hum.SeatPart then
		local weld = hum.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		hum.Sit = false
		task.wait(0.1)
	end
	local centre = spawnCentre(player)
	if not centre then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { Workspace:FindFirstChild("Dummies") :: Instance }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local spot: Vector3? = nil
	for _ = 1, 10 do
		local a = math.random() * math.pi * 2
		local r = math.random() * 7
		local at = centre + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local hit = Workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), params)
		if hit and hit.Normal.Y > 0.8 then
			local free = true
			for _, p in Players:GetPlayers() do
				local r2 = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if r2 and r2:IsA("BasePart") and (r2.Position - hit.Position).Magnitude < 4 then
					free = false
				end
			end
			if free then
				spot = hit.Position + Vector3.new(0, 3, 0)
				break
			end
		end
	end
	local at = spot or (centre + Vector3.new(0, 8, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(CFrame.lookAt(at, at + Vector3.zAxis))
end

function BackToSpawn.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.BACK_TO_SPAWN then
		return
	end
	Net.event(Net.Names.Teleport).OnServerEvent:Connect(function(player: Player, kind: unknown)
		if kind ~= "Spawn" then
			return
		end
		local now = os.clock()
		if now - (last[player] or -math.huge) < BackToSpawn.COOLDOWN then
			return
		end
		last[player] = now
		task.spawn(go, player)
	end)
end

return BackToSpawn
