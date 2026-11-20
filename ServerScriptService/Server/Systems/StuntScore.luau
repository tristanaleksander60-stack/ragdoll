--!strict
-- V8-1.1 (the CRASH score, Config.STUNT_SCORE): a player's own flight from a launch (the cannon, a
-- station, a trap) is measured here, from the replicated body: air time, distance, flips, bounces,
-- machines hit on the way, the bullseye. StuntMath scores it. The client gets "Begin", a few "Live"
-- counts and "Land" (score, tricks, best, new best). The best per machine is kept in DataStore
-- StuntBest_v1 (UpdateAsync, only ever up; Studio and play-as-newcomer visits keep it in memory).
-- AGAIN (client) puts the player back on the machine's pad, paced.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any
local StuntMath = require(Shared:WaitForChild("StuntMath")) :: any

local StuntScore = {}

StuntScore.SAMPLE = 0.1 -- s between looks at the body
StuntScore.MAX_FLIGHT = 12 -- s: a flight that never lands ends here
StuntScore.LANDED_FOR = 0.5 -- s on the ground, slow, that ends a flight
StuntScore.AGAIN_GAP = 4 -- s between two AGAINs

type Flight = {
	machine: string,
	pad: BasePart?,
	startedAt: number,
	from: Vector3,
	air: number,
	turned: number, -- radians the body turned
	bounces: number,
	machines: number,
	bullseye: boolean,
	wasUp: boolean,
	groundedAt: number?,
	lastUp: Vector3?,
	lastLive: number,
}

local flights: { [Player]: Flight } = {}
local lastLanding: { [Player]: number } = {}
local chains: { [Player]: number } = {}
local bests: { [Player]: { [string]: number } } = {}
local lastPad: { [Player]: BasePart } = {}
local lastAgain: { [Player]: number } = {}
local remote: RemoteEvent? = nil
local store: DataStore? = nil

local function send(player: Player, kind: string, data: any)
	local r = remote
	if r and player.Parent then
		r:FireClient(player, kind, data)
	end
end

local function testVisit(player: Player): boolean
	return (require(script.Parent:WaitForChild("TestAccount")) :: any).is(player)
end

-- Is there ground right under this body (within 4.5 studs, not the body itself)?
local function grounded(character: Model, root: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { character }
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ignore, dummies)
	end
	params.FilterDescendantsInstances = ignore
	return Workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), params) ~= nil
end

local function saveBest(player: Player, machine: string, score: number)
	local ds = store
	if not ds or testVisit(player) then
		return
	end
	task.spawn(function()
		pcall(function()
			ds:UpdateAsync(tostring(player.UserId), function(old: unknown)
				local t = if type(old) == "table" then old :: any else {}
				local was = if type(t[machine]) == "number" then t[machine] else 0
				if score <= was then
					return nil -- (only ever up)
				end
				t[machine] = score
				return t, { player.UserId }
			end)
		end)
	end)
end

local function finish(player: Player, f: Flight)
	flights[player] = nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local distance = 0
	if root and root:IsA("BasePart") then
		local d = root.Position - f.from
		distance = Vector3.new(d.X, 0, d.Z).Magnitude
	end
	local now = os.clock()
	local chain = if lastLanding[player] and f.startedAt - lastLanding[player] <= StuntMath.CHAIN_GAP then (chains[player] or 0) + 1 else 0
	chains[player] = chain
	lastLanding[player] = now
	local flight = {
		air = math.floor(f.air * 10 + 0.5) / 10,
		distance = math.floor(distance + 0.5),
		flips = math.floor(f.turned / (2 * math.pi)),
		bounces = f.bounces,
		machines = f.machines,
		bullseye = f.bullseye,
	}
	local r = StuntMath.score(flight, chain)
	local mine = bests[player] or {}
	bests[player] = mine
	local best = mine[f.machine] or 0
	local newBest = r.score > best
	if newBest then
		mine[f.machine] = r.score
		saveBest(player, f.machine, r.score)
	end
	send(player, "Land", {
		score = r.score,
		tricks = r.tricks,
		best = math.max(best, r.score),
		newBest = newBest and best > 0,
		machine = f.machine,
		again = f.pad ~= nil,
		air = flight.air,
	})
	StuntScore.lastForTest = { player = player, flight = flight, result = r }
	-- (V8-1.3: CRASH points count into a mission: "Score 2,000 CRASH".)
	pcall(function()
		(require(script.Parent:WaitForChild("ExperimentService")) :: any).event(player, "Crash", r.score)
	end)
end

-- A player was just launched by `machine` (its pad, for AGAIN).
function StuntScore.begin(player: Player, machine: string, pad: BasePart?)
	if not Config.STUNT_SCORE then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root or not root:IsA("BasePart") then
		return
	end
	local old = flights[player]
	if old then
		finish(player, old) -- (launched again in the air: the first flight ends here)
	end
	if pad then
		lastPad[player] = pad
	end
	flights[player] = {
		machine = machine,
		pad = pad,
		startedAt = os.clock(),
		from = root.Position,
		air = 0,
		turned = 0,
		bounces = 0,
		machines = 0,
		bullseye = false,
		wasUp = true,
		groundedAt = nil,
		lastUp = root.CFrame.UpVector,
		lastLive = 0,
	}
	send(player, "Begin", { machine = machine })
end

-- Something on the way (the bullseye, a machine hit) while a flight is on.
function StuntScore.bonus(player: Player, kind: string)
	local f = flights[player]
	if not f then
		return
	end
	if kind == "Bullseye" then
		f.bullseye = true
	else
		f.machines += 1
	end
end

function StuntScore.isFlying(player: Player): boolean
	return flights[player] ~= nil
end

local function step(player: Player, f: Flight, dt: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root or not root:IsA("BasePart") then
		flights[player] = nil
		return
	end
	local now = os.clock()
	local up = not grounded(character, root)
	if up then
		f.air += dt
		f.groundedAt = nil
	else
		if f.wasUp and now - f.startedAt > 0.4 then
			f.bounces += 1 -- (counted as a touch; the first touch is the landing, taken off below)
		end
		f.groundedAt = f.groundedAt or now
	end
	f.wasUp = up
	local u = root.CFrame.UpVector
	local last = f.lastUp
	if last then
		f.turned += math.acos(math.clamp(u:Dot(last), -1, 1))
	end
	f.lastUp = u
	if now - f.lastLive >= 0.25 then
		f.lastLive = now
		local live = StuntMath.score({ air = f.air, distance = 0, flips = math.floor(f.turned / (2 * math.pi)), bounces = math.max(0, f.bounces - 1), machines = f.machines, bullseye = f.bullseye }, 0)
		send(player, "Live", { score = live.score })
	end
	local slow = root.AssemblyLinearVelocity.Magnitude < 6
	if (f.groundedAt and now - f.groundedAt >= StuntScore.LANDED_FOR and slow and now - f.startedAt > 0.6) or now - f.startedAt > StuntScore.MAX_FLIGHT then
		f.bounces = math.max(0, f.bounces - 1) -- (the landing itself is no bounce)
		finish(player, f)
	end
end

local function loadBests(player: Player)
	local ds = store
	if not ds or testVisit(player) then
		bests[player] = bests[player] or {}
		return
	end
	local ok, value = pcall(function()
		return ds:GetAsync(tostring(player.UserId))
	end)
	local t: { [string]: number } = {}
	if ok and type(value) == "table" then
		for k, v in value :: any do
			if type(k) == "string" and type(v) == "number" then
				t[k] = v
			end
		end
	end
	bests[player] = t
end

-- Tests: a player's best for a machine.
function StuntScore.bestOf(player: Player, machine: string): number
	local mine = bests[player]
	return if mine and mine[machine] then mine[machine] else 0
end

function StuntScore.start()
	remote = Net.event(Net.Names.Stunt)
	if not Config.STUNT_SCORE then
		return
	end
	if not RunService:IsStudio() then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore("StuntBest_v1")
		end)
		if ok then
			store = result
		end
	end
	Players.PlayerAdded:Connect(function(p)
		task.spawn(loadBests, p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(loadBests, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		flights[p] = nil
		lastLanding[p] = nil
		chains[p] = nil
		bests[p] = nil
		lastPad[p] = nil
		lastAgain[p] = nil
	end)
	-- AGAIN: back on the pad of the machine that threw you, in your own lab only, paced.
	-- lihfolk-ignore: remote-unvalidated-args (kind is only compared with "Again"; nothing else is read)
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, kind: unknown)
		if kind ~= "Again" then
			return
		end
		local now = os.clock()
		if now - (lastAgain[player] or -math.huge) < StuntScore.AGAIN_GAP or flights[player] then
			return
		end
		local pad = lastPad[player]
		local character = player.Character
		if not pad or not pad.Parent or not character then
			return
		end
		local Lab = require(script.Parent:WaitForChild("Lab")) :: any
		local owner = Lab.ownerAt(pad.Position)
		if owner ~= nil and owner ~= player then
			return
		end
		lastAgain[player] = now
		local PlayerRagdoll = require(script.Parent:WaitForChild("PlayerRagdoll")) :: any
		pcall(PlayerRagdoll.getUp, player)
		task.delay(0.3, function()
			if player.Character == character and pad.Parent then
				character:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 3.5, 0)))
			end
		end)
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < StuntScore.SAMPLE then
			return
		end
		local d = acc
		acc = 0
		for player, f in flights do
			step(player, f, d)
		end
	end)
end

return StuntScore
