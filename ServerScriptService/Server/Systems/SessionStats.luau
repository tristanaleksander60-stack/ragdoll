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
function SessionStats.onClient(player: Player, kind: unknown, data: unknown)
	local r = recordOf(player)
	if not r or type(kind) ~= "string" then
		return
	end
	-- (A handful of messages a visit at most: a client that floods is ignored from then on.)
	local n = (messages[player] or 0) + 1
	messages[player] = n
	if n > 20 then -- (phase 0: up to four "Used" messages more)
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
	elseif kind == "FirstShot" and r.clientShot == nil then
		r.clientShot = clean(data, 0, 36000)
	end
end

local function write(player: Player)
	local r = records[player]
	records[player] = nil
	if not r then
		return
	end
	r.left = since(player)
	r.input = SessionStats.inputOf(r)
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
