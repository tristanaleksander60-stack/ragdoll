--!strict
-- Round 5, phase 00: one record per visit, kept in the DataStore Session_v1 (key "<userId>_<join
-- time>"), so the first minutes can be read per device and per build. Only the userId; nothing
-- else about the player. The client sends what only it knows (touch, keyboard, gamepad, the
-- screen, when its scripts were running, whether the egg card showed); the server counts the
-- rest itself (shots, the hits it approved, knock-downs, takedowns credited, an egg opened, a lab).
-- Written once on leave (and on shutdown). Never in Studio unless ServerStorage SessionStudio =
-- true. A record is small (about 300 bytes).
--
-- Leaf module: no other system is required here, so anything may count into it.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local SessionStats = {}

SessionStats.STORE = "Session_v1"

export type Record = {
	v: string, -- Config.Version
	pv: number, -- phase 0: game.PlaceVersion (the published build; 0 in Studio)
	joined: number, -- os.time()
	plat: string, -- "phone" | "tablet" | "pc" | "console" | "?"
	touch: boolean?,
	keys: boolean?,
	pad: boolean?,
	w: number?,
	h: number?,
	boot: number?, -- s from the client starting the game to its scripts running (first picture)
	firstShot: number?, -- s from join to the first shot the server took
	clientShot: number?, -- s from the client starting to its first shot (the client's clock)
	shots: number,
	hits: number, -- hits on a body the server approved
	knocks: number, -- bodies this player sent down (blamed), credited or not
	takedowns: number, -- takedowns credited
	eggCard: boolean, -- the "Free egg!" card was shown
	eggOpened: number, -- eggs opened
	autoEgg: boolean, -- the first egg opened by itself
	lab: boolean, -- had a lab of their own
	left: number?, -- s from join to leave
	-- Phase 0: what was really used this visit (not only what the device has), and the onboarding
	-- funnel's furthest step (1 Joined ... 5 ThreeToys, 6 SixToys, 7 TenToys; new players only).
	usedPad: boolean,
	usedKeys: boolean,
	usedMouse: boolean,
	usedTouch: boolean,
	input: string?, -- "pad" | "kbm" | "touch" | "mixed" | "none", set on leave
	portrait: boolean?,
	step: number,
	unlocks: number?,
	streak: number?,
	robux: number?,
	build: string?,
	shopOpen: number?,
	promptShown: number?,
	promptDone: number?,
	dailyClaimed: boolean?,
	firstUnlockAt: number?,
	-- V8-0.8 (see why they leave): times are seconds from the server's join, like firstShot;
	-- frame0 is when the client drew its first frame, so a report subtracts it.
	owner: boolean?, -- the game's creator (reports leave these out)
	test: boolean?, -- a play-as-newcomer visit (TestAccount; reports leave these out)
	newPlayer: boolean?, -- Newcomer was set (a first visit by play time)
	frame0: number?,
	orient10: string?, -- "p" upright or "l" sideways, read again 10, 30 and 60 s after the first frame
	orient30: string?,
	orient60: string?,
	rot: number?, -- orientation changes this visit
	errs: number?, -- client script errors this visit
	errSig: string?, -- the first 3 error heads
	fpsP50: number?,
	fpsP5: number?,
	memMb: number?,
	vol: number?, -- master volume bucket 0-3 (0 muted)
	firstKnockAt: number?,
	firstLaunchAt: number?,
	firstMissionDoneAt: number?,
	used: { [string]: number }?, -- first-use second per machine, creature, map and event
	friendsMax: number?, -- most Roblox friends in the server at once
	screen: string?, -- what was on screen last: "play", "window", "chase", "objective"
	stage: number?, -- V8 funnel: 1 Joined, 2 FirstHit, 3 FirstKO, 4 FirstLaunch, 5 FirstMission, 6 Min3, 7 Min5, 8 Min10
}

local records: { [Player]: Record } = {}
local joinedAt: { [Player]: number } = {}
local messages: { [Player]: number } = {}
local pending = 0 -- writes in flight
local store: DataStore? = nil
SessionStats.hasLab = nil :: ((Player) -> boolean)? -- set by Main (Lab.plotIndex)

local function recordOf(player: Player): Record?
	return records[player]
end

local function begin(player: Player)
	if records[player] then
		return
	end
	joinedAt[player] = os.clock()
	records[player] = {
		v = Config.Version,
		pv = game.PlaceVersion,
		joined = os.time(),
		plat = "?",
		shots = 0,
		hits = 0,
		knocks = 0,
		takedowns = 0,
		unlocks = 0, -- (V8-1.4: weapons unlocked this visit; firstUnlockAt is the first)
		robux = 0, -- (V8-5.5: the money funnel this visit)
		build = (workspace:GetAttribute("Build") :: string?), -- (V8-6.2: the build stamp's commit)
		shopOpen = 0,
		promptShown = 0,
		promptDone = 0,
		eggCard = false,
		eggOpened = 0,
		autoEgg = false,
		lab = false,
		usedPad = false,
		usedKeys = false,
		usedMouse = false,
		usedTouch = false,
		step = 0,
	}
end

-- Phase 0: the input mix in one word, from what was used.
function SessionStats.inputOf(r: Record): string
	local n = (if r.usedPad then 1 else 0) + (if r.usedKeys or r.usedMouse then 1 else 0) + (if r.usedTouch then 1 else 0)
	if n == 0 then
		return "none"
	elseif n > 1 then
		return "mixed"
	end
	return if r.usedPad then "pad" elseif r.usedTouch then "touch" else "kbm"
end

-- Phase 0: the onboarding funnel's step reached (OnboardingService); the record keeps the furthest.
function SessionStats.step(player: Player, n: number)
	local r = records[player]
	if r and n > r.step then
		r.step = n
	end
end

local function since(player: Player): number
	return math.floor((os.clock() - (joinedAt[player] or os.clock())) * 10 + 0.5) / 10
end

-- A shot (a gun fired, at a body or at nothing) the server took.
function SessionStats.shot(player: Player)
	local r = recordOf(player)
	if r then
		r.shots += 1
		if r.firstShot == nil then
			r.firstShot = since(player)
		end
	end
end

-- Counters: "hits", "knocks", "takedowns", "eggOpened".
function SessionStats.count(player: Player, key: string, n: number?)
	local r = recordOf(player) :: any
	if r and type(r[key]) == "number" then
		r[key] += n or 1
		if key == "knocks" and r.firstKnockAt == nil then
			r.firstKnockAt = since(player)
		end
	end
end

-- V8-0.8: the first time something happened this visit ("firstLaunchAt", "firstMissionDoneAt").
function SessionStats.mark(player: Player, key: string)
	local r = recordOf(player) :: any
	if r and r[key] == nil then
		r[key] = since(player)
	end
end

-- V8-0.8: the first use of a machine, creature, map or event this visit (at most 40 names).
SessionStats.USED_MAX = 40
function SessionStats.used(player: Player, name: string)
	local r = recordOf(player)
	if not r or type(name) ~= "string" or #name > 40 then
		return
	end
	pcall(function()
		(require(script.Parent:WaitForChild("Funnels")) :: any).used(player, name)
	end)
	local u = r.used or {}
	r.used = u
	if u[name] == nil then
		local n = 0
		for _ in u do
			n += 1
		end
		if n < SessionStats.USED_MAX then
			u[name] = since(player)
		end
	end
end

function SessionStats.countUserId(userId: number, key: string, n: number?)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		SessionStats.count(player, key, n)
	end
end

function SessionStats.flag(player: Player, key: string)
	local r = recordOf(player) :: any
	if r and type(r[key]) == "boolean" then
		r[key] = true
	end
end

-- Tests: the live record.
function SessionStats.recordFor(player: Player): Record?
	return records[player]
end

local function clean(n: unknown, lo: number, hi: number): number?
	if type(n) ~= "number" or n ~= n then
		return nil
	end
	return math.clamp(math.floor(n * 10 + 0.5) / 10, lo, hi)
end

-- What the client says about itself (once; later messages only add the egg card or its first shot).
-- FIRST_2_MIN: the machines TRY may be pressed at (ExperimentService kinds), and when each player last pressed it.
local TRY_KINDS = { Cannon = true, Wrecking = true, Spider = true, Plant = true, Frog = true, Whale = true, Chicken = true, Washer = true, Slingshot = true, Mole = true, Vacuum = true, Tower = true }
local lastTry: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
function SessionStats.onClient(player: Player, kind: unknown, data: unknown)
	local r = recordOf(player)
	if not r or type(kind) ~= "string" then
		return
	end
	-- (A handful of messages a visit at most: a client that floods is ignored from then on.)
	local n = (messages[player] or 0) + 1
	messages[player] = n
	if n > 120 then -- (V8-0.8: the client paces Orient, Perf and Screen itself; this is the flood guard)
		return
	end
	if kind == "Hello" and type(data) == "table" and r.plat == "?" then
		local d = data :: any
		r.touch = d.touch == true
		r.keys = d.keys == true
		r.pad = d.pad == true
		r.w = clean(d.w, 0, 10000)
		r.h = clean(d.h, 0, 10000)
		r.boot = clean(d.boot, 0, 600)
		r.portrait = (r.h or 0) > (r.w or 0)
		local short = math.min(r.w or 0, r.h or 0)
		r.plat = if r.touch and not r.keys then (if short > 0 and short <= 500 then "phone" else "tablet")
			elseif r.pad and not r.keys then "console"
			else "pc"
		player:SetAttribute("Device", r.plat) -- (NOW 1/4: Funnels splits new players by device)
	elseif kind == "Tutorial" and type(data) == "string" then
		-- (NOW 7: a tutorial step done: Funnels "Tutorial".)
		pcall(function()
			(require(script.Parent:WaitForChild("Funnels")) :: any).tutorial(player, data)
		end)
	elseif kind == "Moment" and (data == "Cannon" or data == "Creature" or data == "Maps") then
		-- (NOW 4: which minute moments a newcomer was shown, for the dashboard.)
		pcall(function()
			(require(script.Parent:WaitForChild("Funnels")) :: any).used(player, "Moment" .. tostring(data))
		end)
	elseif kind == "Try" and type(data) == "string" and TRY_KINDS[data] then
		-- (FIRST_2_MIN: TRY pressed at a machine: the nearest free ragdoll runs to the player. At most one every 3 s.)
		if os.clock() - (lastTry[player] or -math.huge) >= 3 then
			lastTry[player] = os.clock()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local at = root.Position + root.CFrame.LookVector * 4
				pcall(function()
					(require(script.Parent:WaitForChild("Lab")) :: any).callTo(player, at, root.Position)
				end)
			end
			pcall(function()
				(require(script.Parent:WaitForChild("Funnels")) :: any).used(player, "TryPressed")
			end)
		end
	elseif kind == "TryStep" and (data == "Grabbed" or data == "Put") then
		pcall(function()
			(require(script.Parent:WaitForChild("Funnels")) :: any).used(player, "Try" .. tostring(data))
		end)
	elseif kind == "MapBoard" then
		SessionStats.used(player, "mapBoard") -- (V9-0e: a trip chosen on the Map Board)
	elseif kind == "Used" and type(data) == "string" then
		-- (Phase 0: the first time this visit an input family is really used.)
		if data == "pad" then
			r.usedPad = true
		elseif data == "keys" then
			r.usedKeys = true
		elseif data == "mouse" then
			r.usedMouse = true
		elseif data == "touch" then
			r.usedTouch = true
		end
	elseif kind == "EggCard" then
		r.eggCard = true
	elseif kind == "Loaded" and (r :: any).loadedAt == nil then
		-- (V10 phase 1: the load cover lifted: the funnel's "loaded" step, and whether it gave up waiting.)
		local rr = r :: any
		rr.loadedAt = since(player)
		pcall(function()
			(require(script.Parent:WaitForChild("Funnels")) :: any).loaded(player)
		end)
		rr.loadTimedOut = if type(data) == "table" and (data :: any).timedOut == true then true else nil
	elseif kind == "FirstShot" and r.clientShot == nil then
		r.clientShot = clean(data, 0, 36000)
	-- V8-0.8: the first frame, the orientation after load, the client's health and what is on screen.
	elseif kind == "Frame0" and r.frame0 == nil then
		r.frame0 = since(player)
	elseif kind == "Orient" and type(data) == "table" then
		local d = data :: any
		local o = if d.p == true then "p" elseif d.p == false then "l" else nil
		if o and d.t == 10 then
			r.orient10 = o
		elseif o and d.t == 30 then
			r.orient30 = o
		elseif o and d.t == 60 then
			r.orient60 = o
		elseif d.t == "rot" then
			r.rot = math.min((r.rot or 0) + 1, 50)
		end
	elseif kind == "Perf" and type(data) == "table" then
		local d = data :: any
		r.fpsP50 = clean(d.p50, 0, 240)
		r.fpsP5 = clean(d.p5, 0, 240)
		r.memMb = clean(d.mem, 0, 20000)
		r.errs = clean(d.errs, 0, 100000)
		r.vol = clean(d.vol, 0, 3)
		-- (Blind review: a cut or a forged non-UTF-8 string would make the record's SetAsync fail.)
		if type(d.sig) == "string" and utf8.len(d.sig) ~= nil then
			r.errSig = (function()
				local cut = string.sub(d.sig, 1, 300)
				-- (A cut may split a character: then every non-ASCII byte becomes "?".)
				return if utf8.len(cut) ~= nil then cut else (string.gsub(cut, "[\128-\255]", "?"))
			end)()
		end
	elseif kind == "Shop" and type(data) == "string" then
		-- (V8-5.5: the money funnel: the shop opened, a purchase prompt closed, bought or not.)
		local rr = r :: any
		if data == "open" or data == "prompt" or data == "bought" then
			pcall(function()
				(require(script.Parent:WaitForChild("Funnels")) :: any).shop(player, data)
			end)
		end
		if data == "open" then
			rr.shopOpen = math.min((rr.shopOpen or 0) + 1, 500)
		elseif data == "prompt" or data == "bought" then
			rr.promptShown = math.min((rr.promptShown or 0) + 1, 500)
			if data == "bought" then
				rr.promptDone = math.min((rr.promptDone or 0) + 1, 500)
			end
		end
	-- V9-0w: the first shot's glide into first person (s since the first frame), and the seconds a
	-- player then stayed in first person.
	elseif kind == "FpAuto" and (r :: any).fpAuto == nil then
		(r :: any).fpAuto = since(player)
	elseif kind == "FpStay" and (r :: any).fpAuto ~= nil then
		-- (sent every 15 s while it lasts, and at the switch back: the most is kept)
		(r :: any).fpStay = math.max((r :: any).fpStay or 0, clean(data, 0, 36000) or 0)
	elseif kind == "Screen" and type(data) == "string" then
		if data == "play" or data == "window" or data == "chase" or data == "objective" then
			r.screen = data
		end
	end
end

-- V8-0.8: the furthest V8 funnel stage a record reached (1 Joined, 2 FirstHit, 3 FirstKO,
-- 4 FirstLaunch, 5 FirstMission, 6 Min3, 7 Min5, 8 Min10; played time from the first frame).
function SessionStats.stageOf(r: Record): number
	local played = (r.left or 0) - (r.frame0 or 0)
	if played >= 600 then
		return 8
	elseif played >= 300 then
		return 7
	elseif played >= 180 then
		return 6
	elseif r.firstMissionDoneAt then
		return 5
	elseif r.firstLaunchAt then
		return 4
	elseif r.knocks > 0 or r.firstKnockAt then
		return 3
	elseif r.hits > 0 then
		return 2
	end
	return 1
end

-- V8-0.8: how many of a player's Roblox friends are in this server now (asked once per pair).
local friendCache: { [string]: boolean } = {}
local function friendsHere(player: Player): number
	local n = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local a, b = math.min(player.UserId, other.UserId), math.max(player.UserId, other.UserId)
			local key = a .. "_" .. b
			local yes = friendCache[key]
			if yes == nil then
				local ok, result = pcall(function()
					return player:IsFriendsWith(other.UserId)
				end)
				yes = ok and result == true
				friendCache[key] = yes
			end
			if yes then
				n += 1
			end
		end
	end
	return n
end

local function write(player: Player)
	local r = records[player]
	records[player] = nil
	if not r then
		return
	end
	r.left = since(player)
	r.input = SessionStats.inputOf(r)
	-- V8-0.8: who it was (the owner and test visits are left out of reports) and the funnel stage.
	r.owner = player.UserId == game.CreatorId
	r.test = (require(script.Parent:WaitForChild("TestAccount")) :: any).is(player) or nil
	r.newPlayer = player:GetAttribute("Newcomer") == true
	-- (V8-3.4: the daily streak and whether today's was claimed this visit.)
	local streakNow = player:GetAttribute("Streak")
	r.streak = if type(streakNow) == "number" then streakNow else nil
	r.dailyClaimed = player:GetAttribute("DailyClaimed") == true or nil
	r.stage = SessionStats.stageOf(r)
	joinedAt[player] = nil
	messages[player] = nil
	local hasLab = SessionStats.hasLab
	if hasLab then
		local ok, yes = pcall(hasLab, player)
		r.lab = r.lab or (ok and yes == true)
	end
	local s = store
	if not s then
		return
	end
	local key = string.format("%d_%d", player.UserId, r.joined)
	pending += 1
	pcall(function()
		-- lihfolk-ignore: datastore-setasync-player (a write-once log row under a new key per visit, never player progress)
		(s :: DataStore):SetAsync(key, r)
	end)
	pending -= 1
end

function SessionStats.start()
	local studio = RunService:IsStudio()
	if not studio or ServerStorage:GetAttribute("SessionStudio") == true then
		local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, SessionStats.STORE)
		if ok then
			store = ds
		end
	end
	Net.event(Net.Names.Session).OnServerEvent:Connect(SessionStats.onClient)
	Players.PlayerAdded:Connect(begin)
	for _, player in Players:GetPlayers() do
		begin(player)
	end
	-- The lab is checked a while after joining too (it is given on join; the leave check can miss
	-- it if the lab was handed back first).
	Players.PlayerAdded:Connect(function(player)
		task.delay(20, function()
			local hasLab = SessionStats.hasLab
			local r = records[player]
			if r and hasLab then
				local ok, yes = pcall(hasLab, player)
				r.lab = r.lab or (ok and yes == true)
			end
		end)
	end)
	-- V8-0.8: maps visited (the Place attribute) and friends in the server (every 30 s, and when
	-- someone joins).
	local function watchPlace(player: Player)
		player:GetAttributeChangedSignal("Place"):Connect(function()
			local place = player:GetAttribute("Place")
			if type(place) == "string" then
				SessionStats.used(player, "Map:" .. place)
			end
		end)
	end
	Players.PlayerAdded:Connect(watchPlace)
	for _, player in Players:GetPlayers() do
		watchPlace(player)
	end
	local function countFriends()
		for player, r in records do
			if player.Parent then
				local n = friendsHere(player)
				if n > (r.friendsMax or 0) then
					r.friendsMax = n
				end
			end
		end
	end
	Players.PlayerAdded:Connect(function()
		task.delay(5, countFriends)
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			pcall(countFriends)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		task.spawn(write, player)
	end)
	game:BindToClose(function()
		for player in records do
			task.spawn(write, player)
		end
		-- (Every record written before the server goes, within the close's time: review fix.)
		local started = os.clock()
		task.wait(0.1)
		while pending > 0 and os.clock() - started < 20 do
			task.wait(0.1)
		end
	end)
end

return SessionStats
