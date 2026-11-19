--!strict
-- The horde (phase G, co-op): every HORDE_EVERY seconds while someone is in the lab, a crowd of
-- runners in red charges from the plaza at the lab. Everyone in the lab knocks them down together;
-- every knock-down is a takedown for whoever did it, and when the last one is down (or the time
-- runs out) everyone who knocked at least one gets a bonus. Warned 10 s ahead to the whole server.
-- Bigger with more players (up to MAX_RUNNERS), never more than the server can carry: it sizes
-- itself to the room left under EventService's body cap, and waits while a server event or an
-- arena game is on (never two crowds of bodies at once on a phone).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local Dummies = require(Shared:WaitForChild("Dummies"))

local DummyFactory = require(script.Parent.DummyFactory)
local ProgressService = require(script.Parent.ProgressService)
local Metrics = require(script.Parent.Metrics)
local EventService = require(script.Parent.EventService)
local MinigameService = require(script.Parent.MinigameService)

local log = Log.new("Horde")

local HordeService = {}

HordeService.HORDE_EVERY = 600 -- s between hordes
HordeService.WARNING = 10 -- s of warning
HordeService.DURATION = 60 -- s a horde lasts at most
HordeService.BASE_RUNNERS = 8
HordeService.PER_PLAYER = 3
HordeService.MAX_RUNNERS = 18
HordeService.BONUS = 5 -- takedowns for everyone who helped
HordeService.MIN_RUNNERS = 4 -- fewer room than this under the cap: the horde waits
local START_OFFSET = Vector3.new(0, 0, 110) -- from the lab's origin: beyond the plaza
local GROUND_TOP = 600 -- studs above the floor: higher up you are in the rooms, not on the ground

type Runner = { model: Model, down: boolean }
type Horde = { runners: { Runner }, helpers: { [number]: number }, endsAt: number, done: boolean, total: number }

local origin = Vector3.zero
local remote: RemoteEvent
local current: Horde? = nil
local nextAt = 0

-- The horde runs into the plaza in the middle of the labs; whoever is on the ground (in a lab or the
-- plaza, not up in the rooms) is near enough to come and help.
local function playersInLab(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and root.Position.Y - origin.Y <= GROUND_TOP then
			table.insert(list, player)
		end
	end
	return list
end

local function tellAll(kind: string, data: { [string]: any })
	remote:FireAllClients(kind, data)
end

local function finish(h: Horde, why: string)
	if h.done then
		return
	end
	h.done = true
	current = nil
	Workspace:SetAttribute("HordeOn", nil)
	local helped = 0
	for userId, count in h.helpers do
		local player = Players:GetPlayerByUserId(userId)
		if player and count > 0 then
			helped += 1
			ProgressService.addTakedowns(player, HordeService.BONUS)
			Metrics.event(player, "Horde_" .. why)
		end
	end
	local downed = 0
	for _, r in h.runners do
		if r.down then
			downed += 1
		end
	end
	tellAll("HordeEnd", { downed = downed, total = #h.runners, bonus = HordeService.BONUS, helpers = helped, cleared = why == "Cleared" })
	-- (Round 4, M10: the dead stay for their DEAD_HOLD, VitalsService takes them; they still count
	-- in EventService.dummyRoom.)
	task.delay(3, function()
		for _, r in h.runners do
			if r.model.Parent and r.model:GetAttribute("Vital") ~= "Dead" then
				r.model:Destroy()
			end
		end
	end)
	log.info(string.format("horde over (%s): %d/%d down, %d helped", why, downed, #h.runners, helped))
end

-- Starts a horde now (after its warning). Returns it.
function HordeService.start(warning: number?): Horde?
	if current then
		return nil
	end
	local count = math.min(HordeService.MAX_RUNNERS, HordeService.BASE_RUNNERS + HordeService.PER_PLAYER * #Players:GetPlayers(), EventService.dummyRoom())
	if count < HordeService.MIN_RUNNERS then
		return nil
	end
	local h: Horde = { runners = {}, helpers = {}, endsAt = math.huge, done = false, total = count }
	current = h
	Workspace:SetAttribute("HordeOn", true) -- (events and arena rounds wait for it: EventService, MinigameService)
	local wait = warning or HordeService.WARNING
	tellAll("HordeWarning", { seconds = wait, count = count })
	task.delay(wait, function()
		if h.done then
			return
		end
		local start = origin + START_OFFSET
		count = math.min(count, EventService.dummyRoom()) -- (something may have arrived meanwhile)
		h.total = count
		if count < HordeService.MIN_RUNNERS then
			-- No room after all: called off, and everyone told (never a bar of 0 runners).
			h.done = true
			current = nil
			Workspace:SetAttribute("HordeOn", nil)
			tellAll("HordeCancelled", {})
			nextAt = os.clock() + 60
			return
		end
		for i = 1, count do
			local x = (i - (count + 1) / 2) * 4.5
			local at = start + Vector3.new(x, 0, (i % 3) * 4)
			local model = DummyFactory.spawn(at, at - Vector3.zAxis)
			model.Name = "HordeRunner"
			model:SetAttribute("Horde", true)
			model:SetAttribute("PersonName", "Horde")
			model:SetAttribute("Role", "Charging")
			model:SetAttribute("Pace", 1.25)
			for _, d in model:GetChildren() do
				if d:IsA("BasePart") and (string.find(d.Name, "Torso") or string.find(d.Name, "Arm") or string.find(d.Name, "Leg")) then
					d.Color = Color3.fromRGB(210, 40, 50)
				end
			end
			-- At the lab, spread out across it.
			local goal = origin + Vector3.new(x * 1.5, 0, -10)
			model:SetAttribute("Home", Vector3.new(goal.X, at.Y, goal.Z))
			model:SetAttribute("HomeLook", Vector3.new(goal.X, at.Y, goal.Z - 10))
			local runner: Runner = { model = model, down = false }
			table.insert(h.runners, runner)
			model:GetAttributeChangedSignal("RagdollState"):Connect(function()
				local state = model:GetAttribute("RagdollState")
				if not runner.down and (state == "Ragdoll" or state == "Out") then
					runner.down = true
					local who = Dummies.blame(model)
					if who ~= 0 then
						h.helpers[who] = (h.helpers[who] or 0) + 1
					end
					local left = 0
					for _, r in h.runners do
						if not r.down then
							left += 1
						end
					end
					tellAll("HordeLeft", { left = left, total = #h.runners })
					if left == 0 then
						finish(h, "Cleared")
					end
				end
			end)
		end
		h.endsAt = os.clock() + HordeService.DURATION
		tellAll("HordeStart", { total = #h.runners, seconds = HordeService.DURATION })
		task.delay(HordeService.DURATION, function()
			finish(h, "Time")
		end)
	end)
	return h
end

-- What a player who joins now sees (MinigameHud asks once it listens).
function HordeService.stateFor(player: Player)
	local h = current
	if h and h.endsAt < math.huge then
		local left = 0
		for _, r in h.runners do
			if not r.down then
				left += 1
			end
		end
		remote:FireClient(player, "HordeStart", { total = #h.runners, seconds = math.max(1, h.endsAt - os.clock()) })
		remote:FireClient(player, "HordeLeft", { left = left, total = #h.runners })
	end
end

-- Tests.
function HordeService.current(): Horde?
	return current
end
function HordeService.stopForTest()
	local h = current
	if h then
		finish(h, "Stopped")
	end
end
HordeService.finishForTest = finish

function HordeService.boot(labOrigin: Vector3)
	origin = labOrigin
	remote = Net.event(Net.Names.Horde)
	local asked: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
	remote.OnServerEvent:Connect(function(player: Player, kind: unknown)
		if kind == "Hello" and os.clock() - (asked[player] or -math.huge) > 2 then
			asked[player] = os.clock()
			HordeService.stateFor(player) -- (a player who joined mid-horde gets the bar too)
		end
	end)
	nextAt = os.clock() + HordeService.HORDE_EVERY
	task.spawn(function()
		while true do
			task.wait(5)
			-- (Studio only: a place saved with RunSelfTest on never stops hordes on a live server.)
			local testing = game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true
			local busy = EventService.current() ~= nil or MinigameService.current() ~= nil
			if not testing and not current and not busy and os.clock() >= nextAt and #playersInLab() > 0 then
				if HordeService.start() then
					nextAt = os.clock() + HordeService.HORDE_EVERY
				else
					nextAt = os.clock() + 30 -- (no room for it yet: tried again soon)
				end
			end
		end
	end)
end

return HordeService
