--!strict
-- Round 5, phase 1: what the REWARDS window needs that the client cannot know by itself.
--   The group gift: join the game's Roblox group (Shop.GROUP_ID; 0 until the owner sends it, the
--     card then says "soon") and CLAIM a free weapon egg, once per player for good (a claim in its
--     own DataStore, taken in one UpdateAsync before the egg is given, handed back if it could not
--     go in). Joining a group is allowed as a reward; liking or favouriting is NOT (Roblox rules):
--     nothing here asks for those.
--   Trophies: how many of the game's badges the player has (BadgeService, the made ones only).
-- Remote Rewards: client "Hello" / "ClaimGroup"; server "State" { groupId, inGroup, claimed,
-- trophies, trophiesTotal }.

local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Shop = require(Shared:WaitForChild("Shop"))
local Badges = require(Shared:WaitForChild("Badges"))
local ProgressService = require(script.Parent.ProgressService)
local Purchases = require(script.Parent.Purchases)
local MarketplaceService = game:GetService("MarketplaceService")

local RewardsService = {}

local STORE = "GroupGift_v1"
RewardsService.GAP = 2 -- s between two requests from one player
local store: DataStore? = nil
local memory: { [number]: boolean } = {}
local claimed: { [Player]: boolean } = {}
local lastAsk: { [Player]: number } = {}
local remote: RemoteEvent

local function inGroup(player: Player): boolean
	if Shop.GROUP_ID == 0 then
		return false
	end
	local ok, yes = pcall(player.IsInGroup, player, Shop.GROUP_ID)
	return ok and yes == true
end

local function wasClaimed(userId: number): boolean
	local ds = store
	if not ds then
		return memory[userId] == true
	end
	local ok, value = pcall(ds.GetAsync, ds, tostring(userId))
	return ok and value ~= nil
end

-- "ok": taken now; "taken": already claimed before; "error": the store did not answer (try again).
local function claim(userId: number): string
	local ds = store
	if not ds then
		if memory[userId] then
			return "taken"
		end
		memory[userId] = true
		return "ok"
	end
	local took = false
	local ok = pcall(function()
		ds:UpdateAsync(tostring(userId), function(old: any)
			if old ~= nil then
				took = false
				return nil
			end
			took = true
			return os.time()
		end)
	end)
	return if not ok then "error" elseif took then "ok" else "taken"
end

local function unclaim(userId: number)
	local ds = store
	if not ds then
		memory[userId] = nil
		return
	end
	pcall(ds.RemoveAsync, ds, tostring(userId))
end

local function trophies(player: Player): (number, number)
	local ids = {}
	for _, b in Badges.LIST do
		if b.id ~= 0 then
			table.insert(ids, b.id)
		end
	end
	local have = 0
	if #ids > 0 then
		local ok, owned = pcall(BadgeService.CheckUserBadgesAsync, BadgeService, player.UserId, ids)
		if ok and type(owned) == "table" then
			have = #owned
		end
	end
	return have, #Badges.LIST
end

function RewardsService.stateFor(player: Player): { [string]: any }
	if claimed[player] == nil then
		claimed[player] = wasClaimed(player.UserId)
	end
	local have, total = trophies(player)
	return {
		groupId = Shop.GROUP_ID,
		inGroup = inGroup(player),
		claimed = claimed[player] == true,
		trophies = have,
		trophiesTotal = total,
	}
end

-- The group gift. Returns why not ("soon", "join", "claimed", "room", "failed") or nil when given.
function RewardsService.claimGroup(player: Player): string?
	if Shop.GROUP_ID == 0 then
		return "soon"
	end
	if not inGroup(player) then
		return "join"
	end
	if ProgressService.eggRoom(player) ~= nil then
		return "room"
	end
	local result = claim(player.UserId)
	if result == "error" then
		-- (The store did not answer: nothing cached, the player may try again: review fix.)
		ProgressService.notice(player, "Roblox did not answer. Try CLAIM again in a moment")
		return "failed"
	elseif result == "taken" then
		claimed[player] = true
		return "claimed"
	end
	if not ProgressService.giveEgg(player, "Thanks for joining the group! A free weapon egg for you.") then
		unclaim(player.UserId)
		return "failed"
	end
	claimed[player] = true
	return nil
end

-- Today's deal: the Starter Pack (Shop.STARTER_PACK; 0 = not on sale, the card says SOON). An
-- order gives the Revolver and STARTER_BOLTS (+STARTER_EXTRA if the Revolver is yours already).
-- (AUDIT 27 Nov 5: it gave 3 weapon eggs, a paid random item; now its contents are fixed, never eggs.)
RewardsService.STARTER_BOLTS = 300
RewardsService.STARTER_EXTRA = 100
function RewardsService.deliverStarter(player: Player, purchaseId: string)
	if not ProgressService.isLoaded(player) then
		error("profile not ready") -- (Purchases releases the claim: claimed again once it is)
	end
	local newWeapon = ProgressService.grantWeapon(player, "Revolver", "StarterPack")
	local bolts = RewardsService.STARTER_BOLTS + (if newWeapon then 0 else RewardsService.STARTER_EXTRA)
	local Economy = require(script.Parent:WaitForChild("EconomyService")) :: any
	if not Economy.give(player, bolts, nil, true) then
		error("bolts not given") -- (Purchases releases the claim: claimed again once the profile is safe)
	end
	ProgressService.notice(player, string.format("STARTER PACK! +%d BOLTS", bolts) .. (if newWeapon then " and the Revolver is yours" else "") .. ". Thank you!")
	task.spawn(Purchases.complete, player.UserId, purchaseId)
end

local function buyDeal(player: Player)
	if Shop.STARTER_PACK == 0 then
		ProgressService.notice(player, "The Starter Pack is coming soon!")
		return
	end
	if Purchases.isClosing() then
		ProgressService.notice(player, "The server is restarting. Try again in the next one!")
		return
	end
	MarketplaceService:PromptProductPurchase(player, Shop.STARTER_PACK)
end

function RewardsService.start()
	Purchases.register("StarterPack", Shop.STARTER_PACK, function(player: Player, order: Purchases.Order)
		RewardsService.deliverStarter(player, order.p)
	end)
	if ProgressService.usesDataStores() then
		local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, STORE)
		store = if ok then ds else nil
	end
	remote = Net.event(Net.Names.Rewards)
	remote.OnServerEvent:Connect(function(player: Player, kind: unknown)
		if type(kind) ~= "string" then
			return
		end
		local now = os.clock()
		if now - (lastAsk[player] or -math.huge) < RewardsService.GAP then
			return
		end
		lastAsk[player] = now
		if kind == "BuyDeal" then
			buyDeal(player)
			return
		end
		if kind == "ClaimGroup" then
			local why = RewardsService.claimGroup(player)
			if why == "join" then
				ProgressService.notice(player, "Join the group first, then claim your egg")
			elseif why == "room" then
				ProgressService.notice(player, "Your egg slots are full: open an egg first")
			end
		end
		if kind == "Hello" or kind == "ClaimGroup" then
			remote:FireClient(player, "State", RewardsService.stateFor(player))
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		claimed[player] = nil
		lastAsk[player] = nil
	end)
end

-- Tests: forget the claims kept in memory.
function RewardsService.resetForTest()
	table.clear(memory)
	table.clear(claimed)
	table.clear(lastAsk)
end

return RewardsService
