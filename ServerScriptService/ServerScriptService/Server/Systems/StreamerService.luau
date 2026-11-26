--!strict
-- Streamer Mode (phase M): for going live on TikTok. A tool like TikFinity presses a key on the
-- streamer's PC when a viewer sends a gift; with Streamer Mode on, those keys (STREAMER keys in
-- Controls, F1-F8 by default) set off something fun in the game: dummies dropping in, a boom, a
-- slow-mo bubble, a dummy rain, the streamer flung into the air.
--
-- Rules, all checked here:
--   * Only the game's owner, or the owner of the private server the stream runs in (in Studio:
--     anyone), can switch Streamer Mode on: a public server is never flooded by someone's stream.
--   * Gifts never give lasting value: nothing a stream sets off counts for takedowns, eggs, ranks
--     or anything saved (its bodies are marked NoCredit; its blasts have nobody behind them).
--   * Paced: one action every ACTION_GAP s from a queue of at most QUEUE_MAX (a burst of gifts plays
--     out instead of crashing a phone), bodies capped by the server's body cap.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))

local DummyFactory = require(script.Parent.DummyFactory)
local DummyControl = require(script.Parent.DummyControl)
local Blasts = require(script.Parent.Blasts)
local FxService = require(script.Parent.FxService)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local EventService = require(script.Parent.EventService)
local ToyService = require(script.Parent.ToyService)
local Lab = require(script.Parent.Lab)
local Metrics = require(script.Parent.Metrics)

local log = Log.new("Streamer")

local StreamerService = {}

StreamerService.ACTIONS = table.freeze({ "Drop", "Boom", "Slowmo", "Rain", "Fling", "Party", "Giant", "Tool" })
local KNOWN: { [string]: boolean } = {}
for _, id in StreamerService.ACTIONS do
	KNOWN[id] = true
end

StreamerService.ACTION_GAP = 1.2 -- s between two actions
StreamerService.QUEUE_MAX = 10
local DROP_COUNT = 3
local RAIN_COUNT = 8
local BODY_LIFE = 25 -- s a streamer's body stays
local REQUESTS_PER_10S = 30

local remote: RemoteEvent
local onFor: { [Player]: boolean } = {}
local queues: { [Player]: { string } } = {}
local window: { [Player]: { start: number, count: number } } = {}
local lastResult: { [Player]: string } = {} -- (tests: what the last action did)

-- Whether this player may switch Streamer Mode on in this server.
function StreamerService.mayStream(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	-- Only in a private server (never a public one, not even for the game's owner), and only its
	-- owner (or the game's owner in it, e.g. a reserved test server).
	if game.PrivateServerId == "" then
		return false
	end
	if game.PrivateServerOwnerId == player.UserId then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local ok, rank = pcall(function()
		return player:GetRankInGroup(game.CreatorId)
	end)
	return ok and type(rank) == "number" and rank >= 255
end

local function allowed(player: Player): boolean
	local now = os.clock()
	local w = window[player]
	if not w or now - w.start > 10 then
		w = { start = now, count = 0 }
		window[player] = w
	end
	w.count += 1
	return w.count <= REQUESTS_PER_10S
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- A spot a little in front of the streamer (where the camera looks), on their floor.
local function spotNear(root: BasePart, ahead: number, spread: number): Vector3
	local angle = (math.random() - 0.5) * 1.6
	local dir = (root.CFrame * CFrame.Angles(0, angle, 0)).LookVector
	local d = ahead + (math.random() - 0.5) * spread
	return root.Position + Vector3.new(dir.X, 0, dir.Z).Unit * d - Vector3.new(0, 2.5, 0)
end

-- A body that never earns anything (NoCredit) and goes away by itself.
local function guestBody(at: Vector3, look: Vector3, lift: number): Model?
	if EventService.dummyRoom() <= 0 then
		return nil
	end
	local model = DummyFactory.spawn(at, look, nil, lift)
	model:SetAttribute("NoCredit", true)
	model:SetAttribute("Guest", true)
	-- (Round 4, M10: a dead one stays for its DEAD_HOLD; VitalsService takes it.)
	task.delay(BODY_LIFE, function()
		if model.Parent and model:GetAttribute("Vital") ~= "Dead" then
			local pelvis = model:FindFirstChild("LowerTorso")
			if pelvis and pelvis:IsA("BasePart") then
				Lab.poof(pelvis.Position)
			end
			model:Destroy()
		end
	end)
	return model
end

StreamerService.guestBody = guestBody -- (the troll menu's chasers: AdminService)

-- Each action returns whether it set anything off (false: no room for more bodies).
StreamerService.rootOf = rootOf -- (tests swap it: a streamer with no body yet)

local RUN: { [string]: (Player, BasePart) -> boolean } = {}

RUN.Drop = function(_player, root)
	local any = false
	for _ = 1, DROP_COUNT do
		if guestBody(spotNear(root, 14, 8), root.Position, 25 + math.random() * 10) then
			any = true
		end
	end
	return any
end

RUN.Rain = function(_player, root)
	local any = false
	for _ = 1, RAIN_COUNT do
		if not guestBody(spotNear(root, 16, 18), root.Position, 40 + math.random() * 20) then
			break
		end
		any = true
		task.wait(0.15)
	end
	return any
end

RUN.Boom = function(_player, root)
	-- (Nobody behind it: no takedowns, and players' bodies are spared as by any lab blast.)
	local at = spotNear(root, 16, 4)
	Blasts.explode(at, nil, nil)
	return true
end

RUN.Slowmo = function(_player, root)
	local placed = ToyService.place(nil, "Slowmo", spotNear(root, 12, 0), root.CFrame.LookVector)
	return placed == true
end

RUN.Fling = function(player, root)
	local side = (math.random() - 0.5) * 30
	PlayerRagdoll.launch(player, root.CFrame.RightVector * side + Vector3.new(0, 70, 0))
	return true
end

RUN.Party = function(_player, root)
	for i = 1, 5 do
		FxService.hit(spotNear(root, 10, 10) + Vector3.new(0, 4, 0), 20, "BalloonPop")
		task.wait(0.12 * i)
	end
	return true
end

RUN.Giant = function(_player, root)
	-- One big dummy (twice the size) walks in: a "boss" to knock over on stream.
	local model = guestBody(spotNear(root, 18, 2), root.Position, 2)
	if model then
		pcall(function()
			model:ScaleTo(2)
		end)
		model:SetAttribute("Mass", ((model:GetAttribute("Mass") :: number?) or 10) * 8)
	end
	return model ~= nil
end

RUN.Tool = function(player, _root)
	-- The client picks the next tool in the bar (told back, nothing changes on the server).
	remote:FireClient(player, "NextTool")
	return true
end

-- One of the streamer actions at a player, run once (the owner's troll menu, AdminService: a dummy
-- rain over someone). The same rules: guest bodies, NoCredit, gone after BODY_LIFE s.
function StreamerService.runAt(player: Player, id: string): boolean
	local run = RUN[id]
	local root = StreamerService.rootOf(player)
	if not run or not root then
		return false
	end
	return run(player, root)
end

-- AUTOPILOT (round 3, M9): a quiet stream keeps moving. When no gift has come for AUTOPILOT_IDLE
-- s, a gentle action (from AUTOPILOT_ACTIONS) runs every AUTOPILOT_EVERY s until one does. The
-- streamer switches it off in CREATOR (on by default); it never gives anything that lasts either.
StreamerService.AUTOPILOT_IDLE = 90
StreamerService.AUTOPILOT_EVERY = 45
StreamerService.AUTOPILOT_ACTIONS = table.freeze({ "Drop", "Party", "Slowmo" })
local autopilotOff: { [Player]: boolean } = {}
local lastGift: { [Player]: number } = {}
local lastAuto: { [Player]: number } = {}
StreamerService.clockForTest = nil :: (() -> number)?
local function clockNow(): number
	local c = StreamerService.clockForTest
	return if c then c() else os.clock()
end

-- The autopilot's turn for one streamer: returns the action it queued, or nil.
function StreamerService.autopilot(player: Player): string?
	if not onFor[player] or autopilotOff[player] then
		return nil
	end
	local now = clockNow()
	lastGift[player] = lastGift[player] or now
	local q = queues[player]
	if (q and #q > 0) or now - lastGift[player] < StreamerService.AUTOPILOT_IDLE or now - (lastAuto[player] or -math.huge) < StreamerService.AUTOPILOT_EVERY then
		return nil
	end
	lastAuto[player] = now
	local id = StreamerService.AUTOPILOT_ACTIONS[math.random(1, #StreamerService.AUTOPILOT_ACTIONS)]
	table.insert(queues[player], id)
	return id
end

function StreamerService.setAutopilot(player: Player, on: boolean)
	autopilotOff[player] = if on then nil else true
end

local function runNext(player: Player)
	local q = queues[player]
	if not q or #q == 0 or not onFor[player] then
		return
	end
	local root = StreamerService.rootOf(player)
	if not root then
		return -- (respawning: the gift waits in the queue for the next turn)
	end
	local id = table.remove(q, 1) :: string
	local ok, ran = pcall(RUN[id], player, root)
	if not ok then
		log.warn(string.format("%s failed: %s", id, tostring(ran)))
	end
	if ok and ran == true then
		remote:FireClient(player, "Ran", { id = id, waiting = #q })
	else
		-- Nothing happened (no room for more bodies, or it failed): the streamer is told, never
		-- shown a banner for something that didn't happen.
		remote:FireClient(player, "Skipped", {
			id = id,
			text = if ok then "Gift skipped: the lab is full of dummies right now" else "Gift skipped: that one didn't work. Try the next!",
		})
	end
	lastResult[player] = if ok and ran == true then "Ran" else "Skipped"
end

function StreamerService.setOn(player: Player, on: boolean): boolean
	if on and not StreamerService.mayStream(player) then
		remote:FireClient(player, "Refused", { text = "Streamer Mode works in your own private server" })
		return false
	end
	onFor[player] = on or nil
	if on then
		Metrics.event(player, "Streamer_On")
	end
	queues[player] = if on then (queues[player] or {}) else nil
	lastGift[player] = if on then clockNow() else nil -- (the autopilot waits its idle time first)
	player:SetAttribute("Streamer", on)
	remote:FireClient(player, "Mode", { on = on })
	return true
end

-- Queues an action (a gift). Returns its place, or nil when refused.
function StreamerService.queue(player: Player, id: string): number?
	if not onFor[player] or not KNOWN[id] then
		return nil
	end
	local q = queues[player] :: { string }
	if #q >= StreamerService.QUEUE_MAX then
		remote:FireClient(player, "Skipped", { id = id, text = string.format("Gift skipped: %d gifts are already waiting", StreamerService.QUEUE_MAX) })
		return nil
	end
	table.insert(q, id)
	lastGift[player] = clockNow() -- (a gift came: the autopilot rests)
	return #q
end

local function onRequest(player: Player, kind: unknown, arg: unknown)
	if not allowed(player) then
		if kind == "Action" and onFor[player] then
			-- (Told at most once a window: a flood of gifts is not a flood of messages.)
			local w = window[player]
			if w and w.count == REQUESTS_PER_10S + 1 then
				remote:FireClient(player, "Skipped", { text = "Gifts are coming too fast: some were skipped" })
			end
		end
		return
	end
	if kind == "Mode" and type(arg) == "boolean" then
		StreamerService.setOn(player, arg)
	elseif kind == "Action" and type(arg) == "string" then
		StreamerService.queue(player, arg)
	elseif kind == "Autopilot" and type(arg) == "boolean" then
		StreamerService.setAutopilot(player, arg)
	elseif kind == "Hello" then
		remote:FireClient(player, "Hello", { may = StreamerService.mayStream(player), on = onFor[player] == true })
	end
end

-- Tests.
StreamerService.onRequest = onRequest
StreamerService.runNextForTest = runNext
function StreamerService.queueOf(player: Player): { string }
	return queues[player] or {}
end
function StreamerService.lastResultOf(player: Player): string?
	return lastResult[player]
end
-- Tests: who may stream, swapped for a stub (nil restores the real check).
local realMayStream = StreamerService.mayStream
function StreamerService.setMayStreamForTest(fn: ((Player) -> boolean)?)
	StreamerService.mayStream = fn or realMayStream
end

function StreamerService.start()
	remote = Net.event(Net.Names.Streamer)
	remote.OnServerEvent:Connect(onRequest)
	task.spawn(function()
		while true do
			task.wait(StreamerService.ACTION_GAP)
			for player in onFor do
				if player.Parent then
					StreamerService.autopilot(player)
					task.spawn(runNext, player)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		onFor[player] = nil
		queues[player] = nil
		window[player] = nil
		lastResult[player] = nil
		autopilotOff[player] = nil
		lastGift[player] = nil
		lastAuto[player] = nil
	end)
end

return StreamerService
