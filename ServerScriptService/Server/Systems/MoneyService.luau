--!strict
-- Passes, free minutes, What's New and the owner's admin events (phase I).
--
-- ULTRA (a game pass): next to no wait between uses of any tool, twice the props out, twice the
-- budget for the big bangs. Everyone gets FREE_ULTRA_SECONDS of it free each day (the free minutes
-- start on the first visit of the day, saved in the profile), so every player has felt it before
-- they are asked to buy it. The server's own limits still hold (taps a second, the overall cap).
-- VIP (a game pass): a VIP tag over the head for everyone to see, an egg every 50 takedowns (not 75), VIP on
-- the boards.
--
-- Ownership comes from Roblox (UserOwnsGamePassAsync, retried, kept for the session) and the
-- purchase-finished signal; the client only asks to buy. A pass id of 0 is never sold: in Studio
-- the TEST button turns it on for the session to try it.
--
-- What's New: shown once per version (ProgressService keeps the last version seen).
-- Admin events: the game's owner (and only them, checked on the server) can start any server
-- event for free for everyone: "admin abuse".

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local Shop = require(Shared:WaitForChild("Shop"))
local Events = require(Shared:WaitForChild("Events"))
local Config = require(Shared:WaitForChild("Config"))

local ProgressService = require(script.Parent.ProgressService)
local EventService = require(script.Parent.EventService)
local Metrics = require(script.Parent.Metrics)
local OwnerSetting = require(script.Parent.OwnerSetting)

local log = Log.new("Money")

local MoneyService = {}

local REQUESTS_PER_10S = 8
local ADMIN_GAP = 5 -- s between two admin events
local ADMIN_QUEUE_MAX = 2 -- an admin event is refused while this many events (any kind) wait already
local OWNERSHIP_RETRY = 30 -- s between ownership checks after Roblox did not answer
local OWNERSHIP_TRIES = 10
local WHATS_NEW_AFTER = 12 -- s after the profile is read

local remote: RemoteEvent
local owned: { [Player]: { [string]: boolean } } = {}
local freeUntil: { [Player]: number } = {}
local window: { [Player]: { start: number, count: number } } = {}
local firstCheckDone: { [Player]: boolean } = {} -- Roblox's first answer about the passes is in
local lastAdmin = -math.huge

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

-- Whether a player owns a pass (as Roblox said at join or on purchase).
function MoneyService.owns(player: Player, key: string): boolean
	local o = owned[player]
	return o ~= nil and o[key] == true
end

-- Whether the free ULTRA minutes are running for a player.
function MoneyService.freeLeft(player: Player): number
	return math.max(0, (freeUntil[player] or 0) - Workspace:GetServerTimeNow())
end

-- The launch (round 3, M9): the owner can make the passes' fun free for everyone until a date
-- (AdminService: OFF / 3 / 7 / 14 days, kept for every server: OwnerSetting). ULTRA's no-wait and
-- VIP's faster eggs for all; the VIP tag and the VIP boards stay for those who bought it.
-- The Workspace attribute "PassesFreeUntil" (server time) tells every screen.
MoneyService.LAUNCH_DAYS = table.freeze({ 0, 3, 7, 14 })
local launch: OwnerSetting.Setting? = nil
function MoneyService.launchFree(): boolean
	local until_ = Workspace:GetAttribute("PassesFreeUntil")
	return type(until_) == "number" and Workspace:GetServerTimeNow() < until_
end

-- The attributes everything else reads (HitService, Props, ProgressService, the clients).
local function apply(player: Player)
	local ultra = MoneyService.owns(player, "Ultra") or MoneyService.freeLeft(player) > 0 or MoneyService.launchFree()
	player:SetAttribute("ZeroDelay", ultra)
	player:SetAttribute("Ultra", MoneyService.owns(player, "Ultra"))
	player:SetAttribute("FreeUltraUntil", if freeUntil[player] then freeUntil[player] else nil)
	local vip = MoneyService.owns(player, "VIP")
	player:SetAttribute("VIP", vip)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local tag = head and head:FindFirstChild("VipTag")
	if vip and head and not tag then
		local gui = Instance.new("BillboardGui")
		gui.Name = "VipTag"
		gui.Size = UDim2.fromOffset(64, 26)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
		gui.MaxDistance = 80
		gui.LightInfluence = 0
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(255, 210, 74)
		label.TextColor3 = Color3.fromRGB(22, 15, 43)
		label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json") -- (the kit's display face)
		label.TextScaled = true
		label.Text = "VIP"
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = label
		label.Parent = gui
		gui.Parent = head
	elseif not vip and tag then
		tag:Destroy()
	end
end

local function grant(player: Player, key: string)
	owned[player] = owned[player] or {}
	;(owned[player] :: { [string]: boolean })[key] = true
	apply(player)
	remote:FireClient(player, "Owned", { key = key })
end

-- How Roblox is asked (tests swap it for a stub that fails first).
MoneyService.askOwns = function(userId: number, passId: number): boolean
	-- (V8-0.8: a play-as-newcomer visit owns no pass, so it sees what a new player sees.)
	local who = game:GetService("Players"):GetPlayerByUserId(userId)
	if who and (require(script.Parent:WaitForChild("TestAccount")) :: any).is(who) then
		return false
	end
	return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
end

-- Asks Roblox which passes a player owns. A pass Roblox could not answer for is asked again every
-- OWNERSHIP_RETRY s in the background (a paying player is never left without their pass for the
-- session), and the player is told when it turns up.
local function checkOwnership(player: Player, passes: { Shop.Pass }?, gap: number?)
	owned[player] = owned[player] or {}
	local unknown: { Shop.Pass } = {}
	for _, pass in passes or Shop.PASSES do
		if pass.id ~= 0 then
			table.insert(unknown, pass)
		end
	end
	local retryGap = gap or OWNERSHIP_RETRY
	for round = 1, OWNERSHIP_TRIES do
		local still: { Shop.Pass } = {}
		for _, pass in unknown do
			local ok, has = pcall(MoneyService.askOwns, player.UserId, pass.id)
			if not player.Parent then
				return
			end
			if ok then
				if has and not MoneyService.owns(player, pass.key) then
					(owned[player] :: { [string]: boolean })[pass.key] = true
					if round > 1 then
						remote:FireClient(player, "Owned", { key = pass.key })
					end
				end
			else
				table.insert(still, pass)
			end
		end
		apply(player)
		firstCheckDone[player] = true
		unknown = still
		if #unknown == 0 then
			return
		end
		if round == 1 then
			remote:FireClient(player, "Notice", { text = "Checking your passes with Roblox..." })
		end
		task.wait(retryGap)
	end
	-- (Roblox never answered: said so, and asked again now and then for as long as they stay.)
	remote:FireClient(player, "Notice", { text = "Roblox can't check your passes right now. Rejoin if one is missing" })
	while player.Parent and #unknown > 0 do
		task.wait(OWNERSHIP_RETRY * 4)
		local still: { Shop.Pass } = {}
		for _, pass in unknown do
			local ok, has = pcall(MoneyService.askOwns, player.UserId, pass.id)
			if ok then
				if has and player.Parent and not MoneyService.owns(player, pass.key) then
					(owned[player] :: { [string]: boolean })[pass.key] = true
					apply(player)
					remote:FireClient(player, "Owned", { key = pass.key })
				end
			else
				table.insert(still, pass)
			end
		end
		unknown = still
	end
end

-- The free minutes: from the first visit of each UTC day (the profile keeps the day).
function MoneyService.startFree(player: Player, today: number?): boolean
	if MoneyService.owns(player, "Ultra") then
		return false
	end
	local day = today or math.floor(os.time() / 86400)
	if not ProgressService.claimFreeDay(player, day) then
		return false
	end
	local ends = Workspace:GetServerTimeNow() + Shop.FREE_ULTRA_SECONDS
	Metrics.event(player, "FreeUltra")
	ProgressService.setFreeUntil(player, ends) -- (kept: a rejoin keeps what is left)
	MoneyService.runFree(player, ends, true)
	return true
end

MoneyService.checkOwnershipForTest = checkOwnership

-- Runs free ULTRA until `ends` (server time): on, told, and off again at the end.
function MoneyService.runFree(player: Player, ends: number, fresh: boolean)
	local left = ends - Workspace:GetServerTimeNow()
	if left <= 0 then
		return
	end
	freeUntil[player] = ends
	apply(player)
	remote:FireClient(player, "Free", { seconds = math.floor(left), fresh = fresh, ends = ends })
	task.delay(left + 0.5, function()
		if player.Parent and freeUntil[player] == ends then
			-- A new day may have begun meanwhile (minutes carried over from yesterday, or a run
			-- that crossed midnight while playing): today's own start now, if not had yet
			-- (startFree claims each day only once).
			if MoneyService.startFree(player) then
				return
			end
			apply(player)
			if not MoneyService.owns(player, "Ultra") then
				remote:FireClient(player, "FreeOver", {})
			end
		end
	end)
end

local Owner = require(script.Parent.Owner)
local isOwner = Owner.isOwner

local function onRequest(player: Player, kind: unknown, arg: unknown)
	if not allowed(player) then
		return
	end
	if kind == "Buy" and type(arg) == "string" then
		local pass = Shop.byKey[arg]
		if not pass then
			return
		end
		if pass.id ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, pass.id)
		elseif RunService:IsStudio() then
			grant(player, pass.key) -- (Studio only: try a pass that is not on sale yet)
		else
			remote:FireClient(player, "Refused", { text = pass.name .. " is coming soon!" })
		end
	elseif kind == "Admin" and type(arg) == "string" then
		if not require(script.Parent.Admins).isAdmin(player) then -- (21 Nov: admins too)
			return
		end
		if os.clock() - lastAdmin < ADMIN_GAP or not Events.byId[arg] then
			return
		end
		-- (Refused while ADMIN_QUEUE_MAX events of any kind wait: an owner's spree never makes the
		-- queue long for paying players.)
		if EventService.queued() >= ADMIN_QUEUE_MAX then
			remote:FireClient(player, "Refused", { text = "Events are waiting already. Try after this one!" })
			return
		end
		lastAdmin = os.clock()
		local running = EventService.current() ~= nil
		local place = EventService.trigger(arg, player.DisplayName, "Free", true, nil, player.UserId)
		-- (Queued when something is on now or waiting ahead of it: then it is not "started".)
		local queued = running or (place ~= nil and place > 1)
		MoneyService.lastAdminQueued = queued -- (tests)
		remote:FireAllClients("Admin", { by = player.DisplayName, event = Events.byId[arg].name, queued = queued })
	elseif kind == "SeenNew" then
		ProgressService.setSeenVersion(player, Config.Version)
	elseif kind == "Hello" then
		remote:FireClient(player, "Hello", { owner = isOwner(player), admin = require(script.Parent.Admins).isAdmin(player) })
	end
end

-- Tests.
MoneyService.onRequest = onRequest
function MoneyService.adminGapForTest()
	lastAdmin = -math.huge
end
MoneyService.grantForTest = grant
function MoneyService.resetForTest(player: Player)
	owned[player] = {}
	freeUntil[player] = nil
	window[player] = nil
	apply(player)
end

-- The owner's launch switch (AdminService checks it is him): free for `days` days from now, or 0:
-- off. False for anything but the fixed choices.
function MoneyService.setLaunchFree(days: unknown): boolean
	local s = launch
	if not s or not table.find(MoneyService.LAUNCH_DAYS, days :: any) then
		return false
	end
	return OwnerSetting.set(s, if days == 0 then 0 else Workspace:GetServerTimeNow() + (days :: number) * 86400)
end
function MoneyService.onLaunchSaveFailed(fn: (any) -> ())
	local s = launch
	if s then
		s.onSaveFailed = fn
	end
end

function MoneyService.start()
	remote = Net.event(Net.Names.Money)
	remote.OnServerEvent:Connect(onRequest)
	-- The egg rate (VIP) and the board's VIP mark read from here.
	ProgressService.eggEvery = function(player: Player): number
		return if MoneyService.owns(player, "VIP") or MoneyService.launchFree() then Shop.VIP_EGG_EVERY else nil :: any
	end
	-- The launch's free passes: kept for every server; everyone's attributes follow it, and again
	-- the moment it ends (checked every 15 s).
	local wasFree = false
	local function reapply()
		wasFree = MoneyService.launchFree()
		for _, p in Players:GetPlayers() do
			apply(p)
		end
	end
	launch = OwnerSetting.new("PassesFreeUntil", 0, function(v: unknown): boolean
		return type(v) == "number" and v == v and v >= 0 and v < 4e9
	end, function(v: any)
		Workspace:SetAttribute("PassesFreeUntil", if v > 0 then v else nil)
		reapply()
	end, ProgressService.usesDataStores())
	task.spawn(function()
		while true do
			task.wait(15)
			if MoneyService.launchFree() ~= wasFree then
				reapply()
			end
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in Shop.PASSES do
			if pass.id ~= 0 and pass.id == passId then
				grant(player, pass.key)
				log.info(string.format("%s bought %s", player.Name, pass.key))
				Metrics.event(player, "Pass_" .. pass.key)
			end
		end
	end)
	local function join(player: Player)
		task.spawn(checkOwnership, player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			apply(player)
		end)
		-- (The free minutes and What's New wait for the stored profile: ProgressService.onLoaded.)
	end
	ProgressService.onLoaded(function(player: Player, isNew: boolean)
		if not player.Parent or ProgressService.isTesting() then
			return
		end
		-- Roblox's first word on the passes first (an ULTRA owner never gets the free minutes).
		local waited = 0
		while not firstCheckDone[player] and waited < 15 and player.Parent do
			task.wait(0.25)
			waited += 0.25
		end
		if not player.Parent then
			return
		end
		-- Free minutes still running from before a rejoin carry on; else today's start now.
		local kept = ProgressService.freeUntil(player)
		if kept > Workspace:GetServerTimeNow() + 1 then
			MoneyService.runFree(player, kept, false)
		else
			-- Today's free minutes are the 5-minute gift (a reason to stay past the first minutes,
			-- where most new players left), not a join perk that runs out while they look around.
			task.delay(Shop.FREE_ULTRA_AFTER, function()
				if player.Parent then
					MoneyService.startFree(player)
				end
			end)
		end
		-- What's New: only for players who were here before this version (a first visit has
		-- nothing "new"; ProgressService marks it seen), a while after the hello toasts (the free
		-- minutes, the daily egg) so it never lands on top of them.
		if not isNew and ProgressService.seenVersion(player) ~= Config.Version then
			task.delay(WHATS_NEW_AFTER, function()
				if player.Parent then
					remote:FireClient(player, "WhatsNew", { version = Config.Version })
				end
			end)
		end
	end)
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		join(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		firstCheckDone[player] = nil
		owned[player] = nil
		freeUntil[player] = nil
		window[player] = nil
	end)
end

return MoneyService
