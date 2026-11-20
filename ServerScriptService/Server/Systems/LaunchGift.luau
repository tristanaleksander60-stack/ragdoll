--!strict
-- The launch gift (round 4, the owner: "we just launched"): every player gets ONE free weapon egg
-- (an egg always holds a weapon they do not have yet: ProgressService), once, while the launch
-- runs (until UNTIL). It is given to everyone, for nothing: never tied to liking, favouriting or
-- anything else (Roblox does not allow rewards for social actions; the like reminder is separate,
-- LikePrompt on the client).
--
-- Once per player for good: a claim in its own DataStore, taken in one UpdateAsync before the egg
-- is given (two servers at once cannot both give it), and handed back if the egg could not go in.
-- In Studio self-tests and without DataStore access the claims live in memory.

local DataStoreService = game:GetService("DataStoreService")

local Log = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Log"))
local ProgressService = require(script.Parent.ProgressService)

local log = Log.new("LaunchGift")

local LaunchGift = {}

LaunchGift.UNTIL = os.time({ year = 2026, month = 12, day = 10, hour = 23, min = 59, sec = 0 }) -- (server UTC)
-- (V8-0.4: no button named that may be hidden; the egg card offers it by itself.)
LaunchGift.TEXT = "LAUNCH GIFT! A free weapon egg for everyone who plays now!"
local STORE = "LaunchGift_v1"

local store: DataStore? = nil
local memory: { [number]: boolean } = {}

-- Takes the player's claim. True: it was free and is now theirs (give the egg).
local function claim(userId: number): boolean
	local ds = store
	if not ds then
		if memory[userId] then
			return false
		end
		memory[userId] = true
		return true
	end
	local took = false
	local ok, err = pcall(function()
		ds:UpdateAsync(tostring(userId), function(old: any)
			if old ~= nil then
				took = false
				return nil -- (already given: nothing written)
			end
			took = true
			return os.time()
		end)
	end)
	if not ok then
		log.warn("claim failed for", userId, tostring(err))
		return false -- (tried again on the next visit)
	end
	return took
end

local function unclaim(userId: number)
	local ds = store
	if not ds then
		memory[userId] = nil
		return
	end
	pcall(function()
		ds:RemoveAsync(tostring(userId))
	end)
end

function LaunchGift.running(now: number?): boolean
	return (now or os.time()) <= LaunchGift.UNTIL
end

local function onLoaded(player: Player)
	if not LaunchGift.running() or ProgressService.isTesting() or not player.Parent then
		return
	end
	-- (No room for an egg now: nothing taken, it comes on a visit with room.)
	if ProgressService.eggRoom(player) ~= nil then
		return
	end
	if not claim(player.UserId) then
		return
	end
	if not ProgressService.giveEgg(player, LaunchGift.TEXT) then
		unclaim(player.UserId)
	end
end

function LaunchGift.start()
	if ProgressService.usesDataStores() then
		local ok, ds = pcall(function()
			return DataStoreService:GetDataStore(STORE)
		end)
		store = if ok then ds else nil
	end
	ProgressService.onLoaded(function(player: Player, _first: boolean)
		-- (A beat after the first seconds: the gift's line is not lost among the welcome messages.)
		task.delay(6, onLoaded, player)
	end)
	-- (Anyone whose progress was read before this started: the first player of a server.)
	for _, player in game:GetService("Players"):GetPlayers() do
		if ProgressService.isLoaded(player) then
			task.delay(6, onLoaded, player)
		end
	end
	log.info("ready" .. (if LaunchGift.running() then "" else " (the launch is over)"))
end

-- Tests: forget every claim kept in memory.
function LaunchGift.resetForTest()
	table.clear(memory)
end

return LaunchGift
