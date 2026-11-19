--!strict
-- Playing with friends (phase G).
--
-- NUKE and PRANK: a button for each of your Roblox friends in this server. A nuke falls on them
-- (a warning ring at their feet for 3 s, a bomb from the sky, a big cartoon boom that sends them
-- flying; nobody is hurt and nothing is lost); a prank is a random silly one (a balloon ride, a
-- banana slip, a spin into the air). Only between Roblox friends (checked by the server with
-- Roblox), in the same server, at most one nuke per 10 minutes and one prank per 5 minutes from
-- each player, never more than one on the same friend per minute, and anyone can switch "Friends
-- can prank me" off.
--
-- Labs are private (round 3, M1): INVITE lets a Roblox friend in this server into your lab (the
-- LabGuests attribute, Shared/Zones), again to take it back. Players reach each other (hits and
-- blasts, no wounds) only in the plaza (Zones, HitService, Blasts): there is no PvP switch.
--
-- Friend boost: while a Roblox friend is in the same server, every second takedown counts one
-- extra (ProgressService.boost). Joining a friend in another server: asked by the client with the
-- friend's user id; the server checks the friendship and where the friend is (Roblox's own answer,
-- never the client's) before teleporting.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local Zones = require(Shared:WaitForChild("Zones"))

local FxService = require(script.Parent.FxService)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local ProgressService = require(script.Parent.ProgressService)

local log = Log.new("Friends")

local FriendsService = {}

FriendsService.NUKE_COOLDOWN = 600 -- s, per sender
FriendsService.PRANK_COOLDOWN = 300
FriendsService.TARGET_GAP = 60 -- s between two hits on the same player, from anyone
FriendsService.NUKE_WARNING = 3 -- s of the ring before it lands
FriendsService.INVITE_TOAST_GAP = 30 -- s: one "you're invited" toast per inviter and friend in this time
local FRIEND_CACHE = 300 -- s a friendship answer is kept
local REQUESTS_PER_10S = 10
local JOIN_GAP = 10 -- s between join attempts

local remote: RemoteEvent
local friendCache: { [string]: { at: number, yes: boolean } } = {}
-- Cooldowns by user id, kept while the server runs (leaving and coming back does not reset them).
local lastNuke: { [number]: number } = {}
local lastPrank: { [number]: number } = {}
local notFriendsForTest = false -- tests: the friendship check says no
local lastHitOn: { [number]: number } = {} -- by UserId: a rejoin does not reset it
local lastJoin: { [Player]: number } = {}
local invitedAt: { [string]: number } = {} -- "owner:guest" -> os.clock of the last invite toast
local window: { [Player]: { start: number, count: number } } = {}
local testFriends: { [string]: boolean } = {} -- tests: pairs made friends
local selfTarget = false -- tests (one player in Studio): a player may target themselves
local rng = Random.new()

local function key(a: number, b: number): string
	return if a < b then a .. ":" .. b else b .. ":" .. a
end

-- Whether two players are Roblox friends (asked of Roblox, kept a few minutes; a failed answer is no).
function FriendsService.areFriends(a: Player, b: Player): boolean
	if notFriendsForTest then
		return false
	end
	if a == b then
		return selfTarget
	end
	local k = key(a.UserId, b.UserId)
	if testFriends[k] then
		return true
	end
	local cached = friendCache[k]
	if cached and os.clock() - cached.at < FRIEND_CACHE then
		return cached.yes
	end
	local ok, yes = pcall(function()
		return a:IsFriendsWith(b.UserId)
	end)
	local answer = ok and yes == true
	friendCache[k] = { at = os.clock(), yes = answer }
	return answer
end

-- Whether a friend is here, from what is already known (never waits on Roblox: a takedown asks
-- this). The answers are kept fresh in the background (on join and every FRIEND_CACHE s).
function FriendsService.knownFriendHere(player: Player): boolean
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local k = key(player.UserId, other.UserId)
			local cached = friendCache[k]
			if testFriends[k] or (cached and cached.yes) then
				return true
			end
		end
	end
	return false
end

-- Lab guests (round 3, M1): the owner Player's "LabGuests" attribute, ",id,id," (Shared/Zones reads
-- it on the server and every client).
function FriendsService.isLabGuest(owner: Player, userId: number): boolean
	return Zones.isGuest(owner, userId)
end
function FriendsService.setLabGuest(owner: Player, userId: number, on: boolean)
	local list = owner:GetAttribute("LabGuests")
	local text = if type(list) == "string" and list ~= "" then list else ","
	local key = "," .. tostring(userId) .. ","
	-- (Plain find: a Studio test player's id is negative, and "-" means something in a pattern.)
	local at = string.find(text, key, 1, true)
	if at then
		text = string.sub(text, 1, at) .. string.sub(text, at + #key)
	end
	if on then
		text ..= tostring(userId) .. ","
	end
	owner:SetAttribute("LabGuests", if text == "," then nil else text)
end

local function friendsHere(player: Player): { Player }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and FriendsService.areFriends(player, other) then
			table.insert(list, other)
		end
	end
	return list
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

local function sendState(player: Player)
	local now = os.clock()
	local here = {}
	for _, f in friendsHere(player) do
		table.insert(here, { userId = f.UserId, name = f.DisplayName, pranks = f:GetAttribute("Pranks") ~= false, invited = FriendsService.isLabGuest(player, f.UserId) })
	end
	remote:FireClient(player, "State", {
		here = here,
		nukeIn = math.max(0, math.ceil((lastNuke[player.UserId] or -math.huge) + FriendsService.NUKE_COOLDOWN - now)),
		prankIn = math.max(0, math.ceil((lastPrank[player.UserId] or -math.huge) + FriendsService.PRANK_COOLDOWN - now)),
		pranks = player:GetAttribute("Pranks") ~= false,
		boost = #here > 0,
	})
end

local function sendAll()
	for _, p in Players:GetPlayers() do
		task.spawn(sendState, p)
	end
end

------------------------------------------------------------------------------------------------
-- Nukes and pranks

-- Why `from` cannot nuke or prank `target` now (nil: it can).
function FriendsService.refusal(from: Player, target: Player?, kind: string): string?
	if kind ~= "Nuke" and kind ~= "Prank" then
		return "Unknown"
	end
	if not target or not target.Parent or (target == from and not selfTarget) then
		return "They are not in this server"
	end
	if not FriendsService.areFriends(from, target) then
		return "Only your Roblox friends"
	end
	if target:GetAttribute("Pranks") == false then
		return target.DisplayName .. " turned pranks off"
	end
	local now = os.clock()
	local last = if kind == "Nuke" then lastNuke[from.UserId] else lastPrank[from.UserId]
	local cooldown = if kind == "Nuke" then FriendsService.NUKE_COOLDOWN else FriendsService.PRANK_COOLDOWN
	if last and now - last < cooldown then
		local left = math.ceil(cooldown - (now - last))
		return string.format("Your next %s in %d:%02d", string.lower(kind), left // 60, left % 60)
	end
	if now - (lastHitOn[target.UserId] or -math.huge) < FriendsService.TARGET_GAP then
		return target.DisplayName .. " was just hit. Give them a minute!"
	end
	-- Never in the middle of someone's arena round (it would spoil their score).
	local MinigameService = require(script.Parent.MinigameService) :: any
	if target:GetAttribute("Place") == "Arena" and MinigameService.current() ~= nil then
		return target.DisplayName .. " is in a game. Try after it!"
	end
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return "They are not in this server"
	end
	return nil
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function effects(): Folder
	local f = Workspace:FindFirstChild("FriendFx")
	if not f then
		f = Instance.new("Folder")
		f.Name = "FriendFx"
		f.Parent = Workspace
	end
	return f :: Folder
end

local function nuke(from: Player, target: Player)
	local root = rootOf(target)
	if not root then
		return
	end
	-- The warning: a red ring at their feet, following them, and the bomb coming down.
	local ring = Instance.new("Part")
	ring.Name = "NukeRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 16, 16)
	ring.Color = Color3.fromRGB(255, 50, 50)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.4
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	local bomb = Instance.new("Part")
	bomb.Name = "Nuke"
	bomb.Shape = Enum.PartType.Ball
	bomb.Size = Vector3.new(5, 5, 5)
	bomb.Color = Color3.fromRGB(60, 70, 60)
	bomb.Material = Enum.Material.Metal
	bomb.Anchored = true
	bomb.CanCollide = false
	bomb.CanQuery = false
	bomb.CanTouch = false
	local fin = Instance.new("Part")
	fin.Name = "Fin"
	fin.Size = Vector3.new(4, 3, 0.4)
	fin.Color = Color3.fromRGB(240, 200, 40)
	fin.Anchored = true
	fin.CanCollide = false
	fin.CanQuery = false
	fin.CanTouch = false
	local folder = effects()
	ring.Parent = folder
	bomb.Parent = folder
	fin.Parent = folder
	local started = os.clock()
	local landAt = started + FriendsService.NUKE_WARNING
	local at = root.Position
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		local r = rootOf(target)
		if r then
			at = r.Position
		end
		local t = math.clamp((os.clock() - started) / FriendsService.NUKE_WARNING, 0, 1)
		local floor = at - Vector3.new(0, 2.9, 0)
		ring.CFrame = CFrame.new(floor) * CFrame.Angles(0, 0, math.rad(90))
		ring.Size = Vector3.new(0.2, 16 - 6 * t, 16 - 6 * t)
		local height = 140 * (1 - t) ^ 2 + 2
		bomb.CFrame = CFrame.new(floor + Vector3.new(0, height, 0))
		fin.CFrame = bomb.CFrame * CFrame.new(0, 3.2, 0)
		if os.clock() >= landAt then
			connection:Disconnect()
			ring:Destroy()
			bomb:Destroy()
			fin:Destroy()
			local e = Instance.new("Explosion")
			e.Position = floor
			e.BlastPressure = 0
			e.BlastRadius = 0
			e.DestroyJointRadiusPercent = 0
			e.Parent = Workspace
			FxService.hit(floor, 220, "BigBoom", from.UserId)
			-- (Switched pranks off during the countdown: the boom is only a show.)
			if target.Parent and target:GetAttribute("Pranks") ~= false then
				local flat = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
				PlayerRagdoll.launch(target, (flat.Unit * 0.35 + Vector3.new(0, 1, 0)).Unit * 110)
				remote:FireClient(target, "Hit", { by = from.DisplayName, kind = "Nuke" })
			end
		end
	end)
	remote:FireClient(target, "Incoming", { by = from.DisplayName, kind = "Nuke", seconds = FriendsService.NUKE_WARNING })
end

local PRANKS = { "Balloon", "Banana", "Spin" }

local function prank(from: Player, target: Player): string
	local which = PRANKS[rng:NextInteger(1, #PRANKS)]
	local root = rootOf(target)
	if not root then
		return which
	end
	if which == "Balloon" then
		-- Up and away on a balloon, then the drop.
		PlayerRagdoll.knock(target, Vector3.new(0, 70, 0))
		FxService.hit(root.Position + Vector3.new(0, 4, 0), 0, "Balloon", from.UserId)
	elseif which == "Banana" then
		local look = root.CFrame.LookVector
		PlayerRagdoll.knock(target, Vector3.new(look.X * 30, 22, look.Z * 30))
		FxService.hit(root.Position - Vector3.new(0, 2.5, 0), 30, "Slap", from.UserId)
	else
		local side = root.CFrame.RightVector
		PlayerRagdoll.knock(target, side * 45 + Vector3.new(0, 55, 0))
		FxService.hit(root.Position, 60, "Shockwave", from.UserId)
	end
	return which
end

-- Nukes or pranks a friend (checked). Returns whether it went, or why not.
function FriendsService.send(from: Player, target: Player?, kind: string): (boolean, string?)
	local why = FriendsService.refusal(from, target, kind)
	if why then
		return false, why
	end
	local t = target :: Player
	local now = os.clock()
	lastHitOn[t.UserId] = now
	local what = kind
	if kind == "Nuke" then
		lastNuke[from.UserId] = now
		nuke(from, t)
	else
		lastPrank[from.UserId] = now
		what = prank(from, t)
	end
	if kind ~= "Nuke" then
		remote:FireClient(t, "Hit", { by = from.DisplayName, kind = what }) -- (a nuke tells when it lands)
	end
	remote:FireClient(from, "Sent", { to = t.DisplayName, kind = what })
	sendState(from)
	log.info(string.format("%s -> %s: %s", from.Name, t.Name, what))
	return true, nil
end

------------------------------------------------------------------------------------------------
-- Joining a friend's server

function FriendsService.join(player: Player, userId: unknown): (boolean, string?)
	if type(userId) ~= "number" or userId ~= userId or userId <= 0 or userId % 1 ~= 0 then
		return false, "Unknown friend"
	end
	local now = os.clock()
	if now - (lastJoin[player] or -math.huge) < JOIN_GAP then
		return false, "Wait a moment"
	end
	lastJoin[player] = now
	local okFriend, friends = pcall(function()
		return player:IsFriendsWith(userId)
	end)
	if not okFriend or friends ~= true then
		return false, "Only your Roblox friends"
	end
	local ok, _current, _err, placeId, jobId = pcall(function()
		return TeleportService:GetPlayerPlaceInstanceAsync(userId)
	end)
	if not ok or placeId ~= game.PlaceId or type(jobId) ~= "string" or jobId == "" then
		return false, "They are not in Ragdoll Havoc right now"
	end
	if jobId == game.JobId then
		return false, "They are already here!"
	end
	local options = Instance.new("TeleportOptions")
	options.ServerInstanceId = jobId
	local teleported = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	return teleported, if teleported then nil else "Could not join. Try again!"
end

------------------------------------------------------------------------------------------------

local function onRequest(player: Player, kind: unknown, arg: unknown)
	if not allowed(player) then
		return
	end
	if kind == "LabInvite" and type(arg) == "number" then
		-- Your lab is private (round 3): a Roblox friend in this server can be let in, and out again.
		local guest = Players:GetPlayerByUserId(arg)
		if not guest or guest == player or not FriendsService.areFriends(player, guest) then
			remote:FireClient(player, "Refused", { text = "Only friends in this server can come into your lab" })
			return
		end
		local inviting = not FriendsService.isLabGuest(player, guest.UserId)
		FriendsService.setLabGuest(player, guest.UserId, inviting)
		-- (The friend hears of it once a while per inviter: tapping on and off never floods them.)
		local key = player.UserId .. ":" .. guest.UserId
		if inviting and os.clock() - (invitedAt[key] or -math.huge) >= FriendsService.INVITE_TOAST_GAP then
			invitedAt[key] = os.clock()
			remote:FireClient(guest, "LabInvited", { name = player.DisplayName })
		end
		sendState(player)
	elseif kind == "Pranks" and type(arg) == "boolean" then
		player:SetAttribute("Pranks", arg)
		ProgressService.setNoPranks(player, not arg) -- kept for the next visit
		sendAll()
	elseif (kind == "Nuke" or kind == "Prank") and type(arg) == "number" then
		local target = Players:GetPlayerByUserId(arg)
		local ok, why = FriendsService.send(player, target, kind)
		if not ok and why then
			remote:FireClient(player, "Refused", { text = why })
		end
	elseif kind == "Join" then
		task.spawn(function()
			local ok, why = FriendsService.join(player, arg)
			if not ok and why then
				remote:FireClient(player, "Refused", { text = why })
			end
		end)
	elseif kind == "Hello" then
		sendState(player)
	end
end

-- Tests.
FriendsService.onRequest = onRequest
function FriendsService.makeFriendsForTest(a: number, b: number, on: boolean)
	testFriends[key(a, b)] = if on then true else nil
end
function FriendsService.resetForTest(player: Player)
	lastNuke[player.UserId] = nil
	lastPrank[player.UserId] = nil
	lastHitOn[player.UserId] = nil
	window[player] = nil
end
function FriendsService.notFriendsForTest(on: boolean)
	notFriendsForTest = on
end
function FriendsService.selfForTest(on: boolean)
	selfTarget = on
end
function FriendsService.hitOnForTest(player: Player, at: number?)
	lastHitOn[player.UserId] = at
end

function FriendsService.start()
	remote = Net.event(Net.Names.Friends)
	remote.OnServerEvent:Connect(onRequest)
	-- The friend boost: every second takedown counts one extra while a friend is here.
	ProgressService.boost = function(player: Player): boolean
		return FriendsService.knownFriendHere(player)
	end
	-- (The friendship answers the boost reads, asked in the background.)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				friendsHere(player)
			end
			task.wait(FRIEND_CACHE)
		end
	end)
	-- Once a profile is read, the switch is known: everyone's buttons show it.
	ProgressService.onLoaded(function()
		sendAll()
	end)
	Players.PlayerAdded:Connect(function(player)
		if player:GetAttribute("Pranks") == nil then
			-- Off until the profile says what this player chose (nobody can be pranked in the
			-- moment before an opt-out is known); ProgressService sets it on load.
			player:SetAttribute("Pranks", false)
		end
		task.delay(2, sendAll) -- everyone's list (a friend may have joined)
	end)
	for _, player in Players:GetPlayers() do
		-- (Already here when the server starts, as in Studio: off until their profile is read.)
		if not ProgressService.isLoaded(player) then
			player:SetAttribute("Pranks", false)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		lastJoin[player] = nil
		window[player] = nil
		-- Gone: off every guest list.
		for _, owner in Players:GetPlayers() do
			if owner ~= player and FriendsService.isLabGuest(owner, player.UserId) then
				FriendsService.setLabGuest(owner, player.UserId, false)
			end
		end
		-- Friendship answers about this player go (asked again if they come back).
		local id = tostring(player.UserId)
		for k in friendCache do
			local a, b = string.match(k, "^(%d+):(%d+)$")
			if a == id or b == id then
				friendCache[k] = nil
			end
		end
		task.delay(0.5, sendAll)
	end)
	-- A join that Roblox could not start is told, not left at "Joining...".
	TeleportService.TeleportInitFailed:Connect(function(player, _result, message)
		if remote and player.Parent then
			remote:FireClient(player, "Refused", { text = "Could not join. Try again!" })
		end
		log.warn("teleport failed: " .. tostring(message))
	end)
end

return FriendsService
