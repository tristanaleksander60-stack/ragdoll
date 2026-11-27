--!strict
-- F90 (owner, 27 Nov 2026: "Ragdolls der går rundt forsvinder bare ud af det blå nogle gange imens man står og slår
-- dem"; Config.NEVER_VANISH): a client-only PATH WALKER (Client/PathWalkers) that comes near you in view asks for a REAL
-- ragdoll to stand in its place, so what you walk up to and hit is real and never fades away. The server checks it
-- (Net "PathSwap": a Vector3 position and look, finite; on solid ground; within REACH studs of the asking player; at
-- most one per GAP s a player), takes a free lab ragdoll of that player's lab that is out of every view and far from
-- every player (RagdollDirector.mayRemove; a parked one first), sets it down standing there facing the walker's way,
-- sends it walking on, and tells the client, which hides its walker at once. None free: nothing happens (the walker
-- turns round and walks away on the client).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local PathSwap = {}

PathSwap.REACH = 70 -- studs from the asking player
PathSwap.GAP = 1.5 -- s between two asks of one player
PathSwap.FAR = 120 -- studs: a ragdoll this far from every player (and out of view) may be moved in

local last: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function finite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

local function free(m: Model): boolean
	local state = m:GetAttribute("RagdollState")
	local vital = m:GetAttribute("Vital")
	return m.Parent ~= nil and (state == nil or state == "Standing" or state == "Walking") and vital ~= "Dead" and vital ~= "Unconscious"
		and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("Mood") == nil and m:GetAttribute("InMachine") == nil
		and m:GetAttribute("MachineHidden") == nil and m:GetAttribute("Held") ~= true and m:GetAttribute("TryFor") == nil
		and m:GetAttribute("Watch") == nil and m:GetAttribute("Seat") == nil
end

local function onSwap(player: Player, pos: unknown, look: unknown)
	if typeof(pos) ~= "Vector3" or typeof(look) ~= "Vector3" then
		return
	end
	local p, l = pos :: Vector3, look :: Vector3
	if not finite(p) or not finite(l) or l.Magnitude < 0.5 or l.Magnitude > 1.5 then
		return
	end
	local now = os.clock()
	if now - (last[player] or -math.huge) < PathSwap.GAP then
		return
	end
	last[player] = now
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) or (root.Position - p).Magnitude > PathSwap.REACH or math.abs(root.Position.Y - p.Y) > 30 then
		return
	end
	-- solid ground under the spot (the walkway), not inside anything
	local dummies = Workspace:FindFirstChild("Dummies")
	local ex: { Instance } = {}
	if dummies then
		table.insert(ex, dummies)
	end
	for _, pl in Players:GetPlayers() do
		if pl.Character then
			table.insert(ex, pl.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ex
	local hit = Workspace:Raycast(p + Vector3.new(0, 8, 0), Vector3.new(0, -16, 0), params)
	if not hit or hit.Normal.Y < 0.8 then
		return
	end
	local stand = hit.Position + Vector3.new(0, 3.2, 0)
	local Lab = lazy("Lab")
	local Dir = lazy("RagdollDirector")
	local owner = Lab.ownerAt(p) or player
	local best: Model? = nil
	local bestScore = -math.huge
	for _, m in Lab.dummiesOf(owner) do
		local pe = m:FindFirstChild("LowerTorso")
		if pe and pe:IsA("BasePart") and free(m) and Dir.nearestPlayer(pe.Position) > PathSwap.FAR and Dir.mayRemove(m) then
			local score = (if m:GetAttribute("Parked") == true then 1000 else 0) + Dir.nearestPlayer(pe.Position)
			if score > bestScore then
				best, bestScore = m, score
			end
		end
	end
	if not best then
		return
	end
	local flat = Vector3.new(l.X, 0, l.Z)
	local dir = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
	Dir.logRemoval(best, "PathSwap", "moved in to stand where a path walker was")
	best:SetAttribute("Parked", nil)
	local DC = lazy("DummyControl")
	local ok = pcall(DC.move, best, CFrame.lookAt(stand, stand + dir))
	if not ok then
		return
	end
	best:SetAttribute("Home", stand + dir * 24)
	Net.event(Net.Names.PathSwap):FireClient(player, p, best)
end

function PathSwap.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.NEVER_VANISH or not Config.PATH_WALKERS then
		return
	end
	Net.event(Net.Names.PathSwap).OnServerEvent:Connect(onSwap)
end

return PathSwap
