--!strict
-- OVERVIEW 0.1566 THE 2 NEARBY (owner: "Sørg for at der hele tiden er 2 ragdolls i nærheden så hvis en af de 3 dør så
-- kommer en af de andre 2 gående naturligt fra nærheden"; docs/ALWAYS3.md; Config.NEARBY_TWO): besides the 3 near each
-- player (Lab alwaysThree, within 35 studs) there are always 2 more living ragdolls CLOSE BY, 35-60 studs away, going
-- about their own life: every 6-10 s each walks at a normal pace to a new spot in that ring, a little ahead of the way
-- the player is going, spread to either side. They carry Watch "Close" (so the roaming, the road walkers, the watchers
-- and the nearby cap leave them alone) and CloseFor = the player's UserId.
--   * When one of the 3 dies, Lab alwaysThree takes a close-by one FIRST and it WALKS over (Pace 1.3, a jog 1.8 past 45
--     studs) and says a line; then this refills the ring quietly: the nearest free one 60-150 studs away walks in, else one
--     is set down out of view behind the player at 55-70 studs (an 8 s cooldown).
--   * A close-by one that comes within 30 studs on its own, is grabbed, knocked, given a role or wanders off past 150 studs
--     is let go and replaced.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NearbyTwo = {}

NearbyTwo.COUNT = 2
NearbyTwo.RING = Vector2.new(35, 60)
NearbyTwo.FROM = 150
NearbyTwo.MOVE_EVERY = Vector2.new(6, 10)

type Member = { m: Model, nextMove: number, side: number }
local rings: { [Player]: { Member } } = setmetatable({}, { __mode = "k" }) :: any
local setDownAt: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function alive(m: Model): boolean
	local st = m:GetAttribute("RagdollState")
	local vital = m:GetAttribute("Vital")
	return m.Parent ~= nil and vital ~= "Dead" and vital ~= "Unconscious" and m:GetAttribute("Held") ~= true
		and m:GetAttribute("InMachine") == nil and m:GetAttribute("MachineHidden") == nil and (st == nil or st == "Standing" or st == "Walking")
end

local function free(m: Model, plot: number?): boolean
	-- (a Pace means it is on its way somewhere: a recruit of the 3, a runner)
	return alive(m) and m:GetAttribute("Watch") == nil and m:GetAttribute("Role3") == nil and m:GetAttribute("TryFor") == nil
		and m:GetAttribute("Pace") == nil
		and (plot == nil or m:GetAttribute("Plot") == plot)
end

local function letGo(m: Model)
	if m.Parent and m:GetAttribute("Watch") == "Close" then
		m:SetAttribute("Watch", nil)
		m:SetAttribute("CloseFor", nil)
		m:SetAttribute("Pace", nil)
	end
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

-- A walkable spot in the 35-60 ring, ahead of the way the player is going, to one side.
local function spotFor(root: BasePart, side: number): Vector3?
	local ahead = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	if ahead.Magnitude < 2 then
		ahead = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	local base = math.atan2(ahead.Z, ahead.X)
	for _ = 1, 6 do
		local a = base + side * math.rad(math.random(35, 110))
		local r = math.random(NearbyTwo.RING.X + 3, NearbyTwo.RING.Y - 3)
		local at = root.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local hit = Workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -100, 0), params)
		if hit and hit.Normal.Y > 0.8 and hit.Material ~= Enum.Material.Water then
			local n = hit.Instance.Name
			if not (string.find(n, "Water") or string.find(n, "Pool") or string.find(n, "Lava") or string.find(n, "Pond")) then
				return hit.Position + Vector3.new(0, 3, 0)
			end
		end
	end
	return nil
end

local function step(dummies: Instance)
	local now = os.clock()
	local Lab = require(script.Parent:WaitForChild("Lab")) :: any
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			continue
		end
		params.FilterDescendantsInstances = { player.Character :: Instance, dummies }
		local list = rings[player] or {}
		rings[player] = list
		-- drop the ones that are gone, busy, too near (they belong to the 3 now) or too far
		for i = #list, 1, -1 do
			local mem = list[i]
			local pe = pelvisOf(mem.m)
			local d = if pe then (pe.Position - root.Position).Magnitude else math.huge
			if not alive(mem.m) or mem.m:GetAttribute("Watch") ~= "Close" or mem.m:GetAttribute("Role3") ~= nil or d < 30 or d > NearbyTwo.FROM then
				letGo(mem.m)
				table.remove(list, i)
			end
		end
		-- refill: the nearest free one 35-150 studs away walks in
		local ok, plot = pcall(function()
			return Lab.plotIndex(player)
		end)
		plot = if ok then plot else nil
		-- (SPAWN_V2 step 1, SPAWN_ROOM: no refill beyond the player's near cap)
		local roomOk = not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SPAWN_ROOM
			or (require(script.Parent:WaitForChild("RagdollDirector")) :: any).room(player) > 0
		if #list < NearbyTwo.COUNT and roomOk then
			local best, bestD = nil, math.huge
			for _, m in dummies:GetChildren() do
				if m:IsA("Model") and free(m, plot) then
					local pe = pelvisOf(m)
					local d = if pe then (pe.Position - root.Position).Magnitude else math.huge
					if d >= NearbyTwo.RING.X and d <= NearbyTwo.FROM and d < bestD then
						best, bestD = m, d
					end
				end
			end
			if best then
				best:SetAttribute("Watch", "Close")
				best:SetAttribute("CloseFor", player.UserId)
				table.insert(list, { m = best, nextMove = 0, side = if #list == 0 then 1 else -1 })
			elseif now >= (setDownAt[player] or 0) then
				-- none free near enough: one from further away is set down out of view behind the player
				local far, farD = nil, -1
				for _, m in dummies:GetChildren() do
					if m:IsA("Model") and free(m, plot) then
						local pe = pelvisOf(m)
						local d = if pe then (pe.Position - root.Position).Magnitude else 0
						if d > farD then
							far, farD = m, d
						end
					end
				end
				if far and farD > NearbyTwo.FROM then
					local back = -root.CFrame.LookVector * Vector3.new(1, 0, 1)
					back = if back.Magnitude > 0.1 then back.Unit else Vector3.zAxis
					local at = root.Position + back * math.random(55, 70)
					local hit = Workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), params)
					local Dir = require(script.Parent:WaitForChild("RagdollDirector")) :: any
					local setAt: CFrame? = nil
					if hit then
						setAt = CFrame.lookAt(hit.Position + Vector3.new(0, 3.2, 0), Vector3.new(root.Position.X, hit.Position.Y + 3.2, root.Position.Z))
					end
					if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SETDOWN_FREE then
						local sk: { Instance } = { dummies }
						if player.Character then
							table.insert(sk, player.Character)
						end
						setAt = Dir.setDownSpot(root, math.random(55, 70), sk) -- (RUN 0.1: free level floor only)
						hit = if setAt then hit else nil
					end
					if hit and setAt and hit.Normal.Y > 0.8 and (Dir.mayRemove == nil or Dir.mayRemove(far)) then -- F90: never pulled away from where someone sees it
						if Dir.logRemoval then
							Dir.logRemoval(far, "NearbyTwo", "set down behind a player")
						end
						setDownAt[player] = now + 8
						far:SetAttribute("Parked", nil)
						local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
						pcall(DC.move, far, setAt)
						far:SetAttribute("Watch", "Close")
						far:SetAttribute("CloseFor", player.UserId)
						table.insert(list, { m = far, nextMove = 0, side = if #list == 0 then 1 else -1 })
					end
				end
			end
		end
		-- their own life in the ring: a new spot every 6-10 s (sooner when the player has walked off)
		for _, mem in list do
			local pe = pelvisOf(mem.m)
			if not pe then
				continue
			end
			local d = (pe.Position - root.Position).Magnitude
			if now >= mem.nextMove or (d > NearbyTwo.RING.Y + 10 and now >= mem.nextMove - 4) then
				local spot = spotFor(root, mem.side)
				if spot then
					mem.m:SetAttribute("Home", spot)
					mem.m:SetAttribute("HomeLook", nil)
					mem.m:SetAttribute("Pace", if d > NearbyTwo.RING.Y + 15 then 1.3 else nil)
				end
				mem.nextMove = now + math.random(NearbyTwo.MOVE_EVERY.X, NearbyTwo.MOVE_EVERY.Y)
			end
		end
	end
end

function NearbyTwo.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.NEARBY_TWO then
		return
	end
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		while true do
			task.wait(1)
			pcall(step, dummies)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		for _, mem in rings[p] or {} do
			letGo(mem.m)
		end
		rings[p] = nil
	end)
end

return NearbyTwo
