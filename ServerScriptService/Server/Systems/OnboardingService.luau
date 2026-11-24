--!strict
-- First-session funnel. The client drives the UI; the server owns the facts: when you came in, the
-- first minute's tool rules, whether you have done the intro before (kept between visits, with the
-- view you chose), and the funnel steps and first-shot time it logs to Roblox analytics.
--
-- There is no SPAWN button: your avatar's first appearance is the start. A dummy walks up to you
-- (GreeterService) with the Blaster already in your hand; the first shot should land within 5 s.
--
-- Steps (AnalyticsService onboarding funnel, new players only):
--   1 Joined  2 Spawned  3 FirstOwnToy  4 ReplayEnded  5 ThreeToys  6 SixToys  7 TenToys
-- (the catalog grew past what anyone tries in one sitting, so the last step is ten different tools)
-- Returning players skip it: the whole catalog from the first second, their view as they left it.

local AnalyticsService = game:GetService("AnalyticsService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Log)
local Toys = require(Shared.Toys)
local GreeterService = require(script.Parent.GreeterService)
local SessionStats = require(script.Parent.SessionStats)

local Funnels = require(script.Parent:WaitForChild("Funnels")) :: any

local log = Log.new("Onboarding")

local STEP_NAMES = { "Joined", "Spawned", "FirstOwnToy", "ReplayEnded", "ThreeToys", "SixToys", "TenToys" }
local TOOLS_GOAL = 10
-- The replay of your first big moment comes after it; a "replay ended" sooner than this is not one.
local MIN_REPLAY_GAP = 1.5 -- s after the first own toy
-- The catalog opens this long after you appear even without a first big moment. The server keeps its
-- own clock for it (the client's matching timer only changes the screen), so nobody can stay locked
-- to the starters because a message was lost or came too early.
local UNLOCK_FALLBACK = Toys.UNLOCK_FALLBACK
local fallbackTime = UNLOCK_FALLBACK -- tests shorten it

local STORE = "Onboarding_v1"
local MODES = { Player = true, Lab = true }
local RETRIES = 3
local SAVE_DELAY = 6 -- s: view changes are saved once they settle (a DataStore key takes ~1 write / 6 s)
-- The replicated view attribute changes at most once per MODE_GAP s (30 a minute); a view picked in
-- between is kept and shown when the gap is over, so the attribute always ends on the last view.
local MODE_GAP = 2

type Progress = {
	joinedAt: number,
	spawnedAt: number?,
	step: number,
	tried: { [string]: boolean },
	triedCount: number,
	firstToyAt: number,
	replayPending: boolean?,
	returning: boolean,
	mode: string?,
	readKnown: boolean, -- the saved record has been read (or the read failed): new or returning is known
	minuteStarted: boolean?,
	firstToolSeconds: number?,
	firstToolLogged: boolean?,
	earlyReplay: string?, -- a replay message that came before the saved record was read
	modeShownAt: number?, -- when the replicated view attribute last changed
	modeCatchUp: boolean?, -- a later change of the attribute is waiting for the gap
	modePicked: boolean?, -- the player picked a view this visit (it wins over the saved one)
	settling: boolean?, -- one timer waits for the view to settle
	readOk: boolean,
	saveToken: number, -- the latest wanted save (an older one never lands after a newer one)
	saving: boolean, -- a write is running for this player
	savedToken: number, -- the save that last went through
}

local OnboardingService = {}

local progress: { [Player]: Progress } = {}
local inFlight = 0 -- writes running (BindToClose waits for them)
local store: DataStore? = nil
local memory: { [number]: { done: boolean, mode: string? } } = {}

local function retry(fn: () -> any): (boolean, any)
	local lastError: any = nil
	for attempt = 1, RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < RETRIES then
			task.wait(attempt)
		end
	end
	log.warn(tostring(lastError))
	return false, lastError
end

local function readRecord(userId: number): (boolean, { done: boolean, mode: string? }?)
	local ds = store
	if not ds then
		return true, memory[userId]
	end
	local ok, value = retry(function()
		return ds:GetAsync(tostring(userId))
	end)
	if not ok then
		return false, nil
	end
	if type(value) ~= "table" then
		return true, nil
	end
	local v = value :: { [string]: any }
	local mode = if type(v.mode) == "string" and MODES[v.mode] then v.mode else nil
	-- (An older record's "hospital" key, the charts switch before round 2's doctor mode, is left
	-- out: nothing reads it, and the next write drops it.)
	return true, { done = v.done == true, mode = mode }
end

local function recordOf(p: Progress): { done: boolean, mode: string? }
	return { done = p.returning or p.step >= 4, mode = p.mode }
end

local flush: (Player, Progress) -> ()

-- One timer per player, however many changes: it writes once nothing changed for SAVE_DELAY s
-- (so a player can never make the server write their key more often than that).
local function settleLater(player: Player, p: Progress)
	if p.settling then
		return
	end
	p.settling = true
	local function check(token: number)
		task.delay(SAVE_DELAY, function()
			if progress[player] ~= p then
				p.settling = false
				return
			end
			if p.saveToken ~= token then
				check(p.saveToken)
				return
			end
			p.settling = false
			flush(player, p)
		end)
	end
	check(p.saveToken)
end

-- Writes the player's record now: one write at a time per player, and when it finishes it writes
-- again if something changed meanwhile, so the newest state always lands last. Never over a record
-- it could not read.
function flush(player: Player, p: Progress)
	if not p.readOk or p.saving then
		return
	end
	local ds = store
	if not ds then
		memory[player.UserId] = recordOf(p)
		p.savedToken = p.saveToken
		return
	end
	p.saving = true
	inFlight += 1
	local token = p.saveToken
	local userId = player.UserId
	task.spawn(function()
		local ok = retry(function()
			-- Merged with what is stored: "done" never goes back (another server may have written it
			-- since this one read the record); the view is the newest.
			ds:UpdateAsync(tostring(userId), function(old: any)
				local mine = recordOf(p)
				local before = if type(old) == "table" then old else {}
				return { done = mine.done or before.done == true, mode = mine.mode or before.mode }, { userId }
			end)
		end)
		inFlight -= 1
		p.saving = false
		if ok then
			p.savedToken = math.max(p.savedToken, token)
		end
		if p.saveToken ~= token then
			-- Changed while writing: through the settle timer while the player is here, at once
			-- if they have left (nothing else would write it).
			if progress[player] == p then
				settleLater(player, p)
			else
				flush(player, p)
			end
		end
	end)
end

-- Shows the kept view on the replicated attribute: at once, or (in a flood) when MODE_GAP has
-- passed since the last change, so the attribute changes at most 30 times a minute and still ends
-- on the last view.
local function showMode(player: Player, p: Progress)
	if p.modeCatchUp or not player.Parent or player:GetAttribute("PreferredView") == p.mode then
		return
	end
	local now = os.clock()
	local wait = if p.modeShownAt then p.modeShownAt + MODE_GAP - now else 0
	if wait <= 0 then
		p.modeShownAt = now
		player:SetAttribute("PreferredView", p.mode)
		return
	end
	p.modeCatchUp = true
	task.delay(wait, function()
		p.modeCatchUp = false
		if progress[player] == p then
			showMode(player, p)
		end
	end)
end

-- Saved when the intro is done (now) and when the view changes (once it settles).
local function writeRecord(player: Player, soon: boolean?)
	local p = progress[player]
	if not p or not p.readOk then
		return
	end
	p.saveToken += 1
	if not soon then
		flush(player, p)
		return
	end
	settleLater(player, p)
end

local function reach(player: Player, step: number)
	local p = progress[player]
	if not p or step <= p.step then
		return
	end
	if not p.returning then
		-- Log every step in order so the funnel has no holes.
		for s = p.step + 1, step do
			local name = STEP_NAMES[s]
			-- (24 Nov 2026: the dashboard's funnels are Funnels' now; these steps are the game's own.)
			local seconds = os.clock() - p.joinedAt
			player:SetAttribute("Onboarding_" .. name, math.floor(seconds * 10) / 10)
			log.info(string.format("%s step %d %s at %.1fs", player.Name, s, name, seconds))
		end
	end
	local was = p.step
	p.step = step
	if not p.returning then
		SessionStats.step(player, step) -- (phase 0: the visit record keeps the furthest step)
	end
	if step == 3 then
		p.firstToyAt = os.clock()
	end
	player:SetAttribute("OnboardingStep", step)
	if was < 4 and step >= 4 and not p.returning then
		writeRecord(player) -- the intro is done: next visit starts with everything
	end
end

local function unlock(player: Player, skipped: boolean)
	player:SetAttribute("ReplaySkipped", skipped)
	reach(player, 4)
	OnboardingService.checkCounts(player)
end

local function logFirstTool(player: Player, p: Progress)
	local seconds = p.firstToolSeconds
	if not seconds or p.firstToolLogged or not p.readKnown or p.returning then
		return
	end
	p.firstToolLogged = true
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "FirstToolSeconds", seconds)
	end)
	log.info(string.format("%s first tool after %.1fs", player.Name, seconds))
end

-- The funnel and the catalog clock of a new player, once both are known: that they are new (the
-- read) and when they appeared. The clock runs from the appearance, whenever the read came back.
local function startFirstMinute(player: Player, p: Progress)
	local spawnedAt = p.spawnedAt
	if p.returning or not p.readKnown or not spawnedAt or p.minuteStarted then
		return
	end
	p.minuteStarted = true
	reach(player, 2)
	-- What happened before the record was read still counts: a tool already used, a replay done.
	if p.firstToolSeconds then
		reach(player, 3)
	end
	local early = p.earlyReplay
	if early then
		p.earlyReplay = nil
		task.defer(OnboardingService.onClient, player, early)
	end
	task.delay(math.max(0, fallbackTime - (os.clock() - spawnedAt)), function()
		if progress[player] == p and p.step < 4 then
			unlock(player, true)
		end
	end)
end

-- Your avatar's first appearance this visit: the start of the first five seconds. The greeter
-- comes at once (for everyone: something to shoot straight away), not after the saved record.
local function onSpawned(player: Player)
	local p = progress[player]
	if not p or p.spawnedAt then
		return
	end
	p.spawnedAt = os.clock()
	player:SetAttribute("SpawnedAt", workspace:GetServerTimeNow())
	if not (require(Shared:WaitForChild("Config")) :: any).ONLY_LAB_DUMMIES then task.spawn(GreeterService.send, player) end -- (V8-0.2: it may wait for the move into the lab)
	startFirstMinute(player, p)
end

local function onClient(player: Player, kind: unknown, value: unknown)
	local p = progress[player]
	if not p or type(kind) ~= "string" then
		return
	end
	if (kind == "ReplayDone" or kind == "ReplaySkipped") and not p.readKnown and not p.earlyReplay then
		p.earlyReplay = kind -- handled once the saved record is read (startFirstMinute)
	elseif (kind == "ReplayDone" or kind == "ReplaySkipped") and p.step == 3 and not p.replayPending then
		p.replayPending = true -- one at a time, however often the client says it
		-- Too soon after the first toy to be a real replay (a client skipping the first minute):
		-- it still counts, a moment later.
		task.delay(math.max(0, MIN_REPLAY_GAP - (os.clock() - p.firstToyAt)), function()
			if progress[player] == p and p.step == 3 then
				unlock(player, kind == "ReplaySkipped")
			end
		end)
	elseif kind == "Mode" and type(value) == "string" and MODES[value] then
		-- Cheap however often it comes: a field and an attribute; the DataStore write waits until
		-- the view has not changed for SAVE_DELAY s (one write, whatever the rate).
		if p.mode == value then
			return
		end
		-- However fast it is switched, the last view wins (kept, and written once it settles); only
		-- the replicated attribute is limited, so a flood never reaches the other clients.
		p.mode = value
		p.modePicked = true
		showMode(player, p)
		writeRecord(player, true)
	end
end

-- Tests: where a player is in the funnel, and skipping them past the first minute.
function OnboardingService.stepOf(player: Player): number?
	local p = progress[player]
	return p and p.step
end

-- Tests: the remote handler, back to the start of the funnel (a new player who has just appeared),
-- and a shorter fallback.
OnboardingService.onClient = onClient
OnboardingService.onSpawned = onSpawned

function OnboardingService.restartForTest(player: Player, fallbackSeconds: number?)
	assert(RunService:IsStudio(), "for Studio tests only")
	local p = progress[player]
	if p then
		p.step = 1
		p.firstToyAt = math.huge
		p.replayPending = nil
		p.spawnedAt = nil
		p.returning = false
		p.readKnown = true
		p.minuteStarted = nil
		p.firstToolSeconds = nil
		p.firstToolLogged = nil
		player:SetAttribute("FirstToolSeconds", nil)
	end
	fallbackTime = fallbackSeconds or UNLOCK_FALLBACK
end

function OnboardingService.finishForTest(player: Player)
	assert(RunService:IsStudio(), "for Studio tests only")
	fallbackTime = UNLOCK_FALLBACK
	local p = progress[player]
	if p and p.step < 4 then
		p.firstToyAt = math.min(p.firstToyAt, os.clock())
		reach(player, 4)
	end
end

-- Tests: what is kept for a player between visits.
function OnboardingService.recordForTest(player: Player): { done: boolean, mode: string? }?
	local _, record = readRecord(player.UserId)
	return record
end

-- The first minute: the starters only, until the first replay (or its fallback) opens the
-- catalog. Players who are not tracked (tests) and returning players may use anything.
function OnboardingService.isAllowed(player: Player, toyId: string): boolean
	local p = progress[player]
	if not p or p.step >= 4 or p.returning then
		return true
	end
	return table.find(Toys.defaultLoadout, toyId) ~= nil
end

-- Called by HitService after a toy request passed validation.
function OnboardingService.onToyUsed(player: Player, toyId: string)
	-- (V8-1.3: the mission chain's "swing the BAT" and "throw the GRENADE".)
	if toyId == "Bat" or toyId == "Grenade" then
		pcall(function()
			(require(script.Parent:WaitForChild("ExperimentService")) :: any).event(player, "Tool:" .. toyId, 1)
		end)
	end
	local p = progress[player]
	if not p or not Toys.byId[toyId] then
		return
	end
	if p.spawnedAt and player:GetAttribute("FirstToolSeconds") == nil then
		-- The number the first five seconds are judged by: appearing to the first tool that worked
		-- (sent to analytics for new players only, once it is known the player is new).
		local seconds = math.floor((os.clock() - p.spawnedAt) * 10) / 10
		player:SetAttribute("FirstToolSeconds", seconds)
		p.firstToolSeconds = seconds
		logFirstTool(player, p)
	end
	if p.step >= 2 then
		reach(player, 3)
	end
	Funnels.tool(player, toyId)
	if not p.tried[toyId] then
		p.tried[toyId] = true
		p.triedCount += 1
		if p.triedCount <= TOOLS_GOAL then
			player:SetAttribute("Tried_" .. toyId, true) -- (24 Nov 2026: the bar's slots show which is not tried yet)
		end
	end
	OnboardingService.checkCounts(player)
end

-- Toy-count steps only follow the replay step, so the funnel stays in order.
function OnboardingService.checkCounts(player: Player)
	local p = progress[player]
	if not p or p.step < 4 or p.returning then
		return
	end
	if p.triedCount >= 3 and p.step == 4 then
		reach(player, 5)
	end
	if p.triedCount >= 6 and p.step == 5 then
		reach(player, 6)
	end
	if p.triedCount >= TOOLS_GOAL and p.step == 6 then
		reach(player, 7)
	end
end

local function onJoin(player: Player)
	local p: Progress = {
		joinedAt = os.clock(),
		step = 0,
		tried = {},
		triedCount = 0,
		firstToyAt = math.huge,
		returning = false,
		readOk = false,
		readKnown = false,
		saveToken = 0,
		saving = false,
		savedToken = 0,
	}
	progress[player] = p
	-- The appearance is caught straight away (the first five seconds do not wait for the DataStore).
	local function spawned(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		if character.Parent then
			onSpawned(player)
		end
	end
	player.CharacterAdded:Connect(spawned)
	if player.Character then
		task.spawn(spawned, player.Character)
	end
	-- Whether this player has been here before decides the rest of the first minute; the client
	-- follows OnboardingReady / Returning (a failed read counts as new: the intro again, nothing
	-- saved over). The funnel counts new players only, so Joined is logged once that is known.
	task.spawn(function()
		local ok, record = readRecord(player.UserId)
		if progress[player] ~= p then
			return
		end
		p.readOk = ok
		p.readKnown = true
		if record and record.done then
			p.returning = true
			p.step = math.max(p.step, 4)
			player:SetAttribute("OnboardingStep", p.step)
			player:SetAttribute("Returning", true)
		else
			reach(player, 1)
			Funnels.newPlayer(player)
		end
		if p.modePicked then
			-- A choice made before the record came in wins over the saved one, and is saved.
			writeRecord(player, true)
		end
		if not p.modePicked and record and record.mode then
			p.mode = record.mode
			showMode(player, p)
		end
		player:SetAttribute("OnboardingReady", true)
		startFirstMinute(player, p)
		logFirstTool(player, p)
	end)
end

function OnboardingService.start()
	if not RunService:IsStudio() then
		store = DataStoreService:GetDataStore(STORE) -- live servers: never wait on a probe at boot
	else
		-- Studio: memory during self-tests or without API access (probed once).
		local testing = ServerStorage:GetAttribute("RunSelfTest") == true
		local usable = not testing and pcall(function()
			DataStoreService:GetDataStore(STORE):GetAsync("probe")
		end)
		if usable then
			store = DataStoreService:GetDataStore(STORE)
		end
	end
	GreeterService.start()
	Net.event(Net.Names.Onboarding).OnServerEvent:Connect(onClient)
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		if not progress[player] then
			onJoin(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		local p = progress[player]
		if p and p.saveToken ~= p.savedToken and not p.saving then
			flush(player, p) -- a view change still waiting to settle
		end
		progress[player] = nil
	end)
	game:BindToClose(function()
		for player, p in progress do
			if p.saveToken ~= p.savedToken then
				flush(player, p)
			end
		end
		local started = os.clock()
		while inFlight > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

return OnboardingService
