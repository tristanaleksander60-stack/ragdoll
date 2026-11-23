--!strict
-- Round 5, phase 4: SINGLEPLAYER and MULTIPLAYER portals in every lab, and the server list.
--   Every public server tells a shared list (MemoryStore sorted map SERVERS) who it is every
--   BEAT s: a fun name from a fixed word list (never typed by anyone), a region (the country of its
--   first player, LocalizationService), how many are in it of how many fit. Entries expire after
--   EXPIRE s, so a closed server drops off by itself.
--   MULTIPLAYER: the list window (Client/PortalUI). PLAY NOW goes to the fullest public server with
--   room (never this one); JOIN a named one; MAKE MY OWN reserves a private server (friends join
--   you through Roblox's own join); new players still start in a shared server (the owner).
--   SINGLEPLAYER: a reserved server of your own ("GOING BACK TO SOLO"); from solo or your own
--   server, MULTIPLAYER's PLAY NOW goes back to a shared one.
-- Teleports cannot run in Studio: there the request is answered "Studio" and the client shows it;
-- the choices themselves are pure functions the tests run (PortalService.fullest, nameOf, entry).

local LocalizationService = game:GetService("LocalizationService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Log"))

local log = Log.new("Portal")

local PortalService = {}

PortalService.MAP = "Servers_v1"
PortalService.BEAT = 15
PortalService.EXPIRE = 50
PortalService.LIST_MAX = 30
PortalService.GAP = 3 -- s between two requests from one player

local ADJECTIVES = { "ZIPPY", "FUZZY", "WOBBLY", "CRISPY", "SNEAKY", "BOUNCY", "SPICY", "GOOFY", "TURBO", "SLEEPY", "MIGHTY", "SQUISHY", "LUCKY", "FROSTY", "JOLLY", "RUSTY" }
local ANIMALS = { "PUFFIN", "OTTER", "LLAMA", "WOMBAT", "GECKO", "PANDA", "BADGER", "GOOSE", "KOALA", "LOBSTER", "MOOSE", "NARWHAL", "PENGUIN", "RACCOON", "SLOTH", "WALRUS" }

export type Entry = { id: string, name: string, region: string, players: number, max: number, t: number, shared: number? }

-- A server's fun name from its job id (the same on every machine, never typed by anyone).
function PortalService.nameOf(jobId: string): string
	local h = 0
	for i = 1, #jobId do
		h = (h * 31 + string.byte(jobId, i)) % 1000003
	end
	return ADJECTIVES[h % #ADJECTIVES + 1] .. " " .. ANIMALS[(h // #ADJECTIVES) % #ANIMALS + 1]
end

local region = "?"
local function jobId(): string
	return if game.JobId ~= "" then game.JobId else "studio"
end

-- What this server tells the list.
function PortalService.entry(): Entry
	-- (shared: how many play in this server's one shared lab, the multiplayer crowd.)
	local shared = 0
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("SharedHost") == true or p:GetAttribute("SharedGuest") ~= nil then
			shared += 1
		end
	end
	return { id = jobId(), name = PortalService.nameOf(jobId()), region = region, players = #Players:GetPlayers(), max = Players.MaxPlayers, t = os.time(), shared = shared }
end

-- PLAY NOW's choice: the fullest server with room that is not this one (nil: none).
function PortalService.fullest(list: { Entry }, selfId: string): Entry?
	local best: Entry? = nil
	for _, e in list do
		-- (The most players in a shared lab first, then the most players: 23 Nov 2026, "nobody feels alone".)
		local b = best
		local better = b == nil or (e.shared or 0) > (b.shared or 0) or ((e.shared or 0) == (b.shared or 0) and e.players > b.players)
		if e.id ~= selfId and e.players < e.max and better then
			best = e
		end
	end
	return best
end

local map: MemoryStoreSortedMap? = nil
local listCache: { Entry } = {}
local listAt = 0

-- (23 Nov 2026, owner: "load straight into singleplayer": Roblox cannot put a Play into a reserved server, so the
-- start place is the singleplayer (server size 1: Play is a server of your own, one load) and multiplayer is a second
-- place of the same experience, Config.MULTI_PLACE. 0 = one place only: Play is sent on, a second load.)
local START_PLACE: number = (require(ReplicatedStorage.Shared.Config) :: any).START_PLACE
local MULTI: number = (require(ReplicatedStorage.Shared.Config) :: any).MULTI_PLACE
local multiPlace = if MULTI ~= 0 then MULTI else game.PlaceId
local function isPublic(): boolean
	return game.PrivateServerId == "" and game.JobId ~= "" and (MULTI == 0 or game.PlaceId == MULTI)
end

local function beat()
	local m = map
	if not m or not isPublic() then
		return
	end
	local e = PortalService.entry()
	pcall(function()
		-- (Sorted by how full it is: the fullest first in a read.)
		-- lihfolk-ignore: datastore-setasync-player (a MemoryStore server heartbeat, this server's own key, no player data)
		(m :: MemoryStoreSortedMap):SetAsync(e.id, e, PortalService.EXPIRE, -e.players)
	end)
end

function PortalService.list(): { Entry }
	local m = map
	if not m then
		return {}
	end
	if os.clock() - listAt < 5 then
		return listCache
	end
	listAt = os.clock()
	local ok, items = pcall(function()
		return (m :: MemoryStoreSortedMap):GetRangeAsync(Enum.SortDirection.Ascending, PortalService.LIST_MAX)
	end)
	local out: { Entry } = {}
	if ok and type(items) == "table" then
		for _, item in items do
			local v = item.value
			if type(v) == "table" and type(v.id) == "string" and type(v.players) == "number" then
				table.insert(out, v :: any)
			end
		end
	end
	listCache = out
	return out
end

local remote: RemoteEvent
local lastAsk: { [Player]: number } = {}
local lastList: { [Player]: number } = {}
local portalTouch: { { [Player]: number } } = {} -- (each portal's last touch per player; cleared on leave)

-- (23 Nov 2026, owner: "let me spectate people in singleplayer"): a server of one's own is reserved, so only its
-- access code opens it. Whoever reserves it lists the code under the player's id (server memory only, never sent
-- to a client); the server itself keeps it fresh while they are in it. Read only for the owner.
PortalService.SOLO_MAP = "SoloServers_v1"
PortalService.SOLO_EXPIRE = 150
local soloMap: MemoryStoreSortedMap? = nil
local function listSolo(player: Player, code: string, sid: string)
	local m = soloMap
	if m then
		pcall(function()
			-- lihfolk-ignore: datastore-setasync-player (a MemoryStore listing that expires, not player data)
			m:SetAsync(tostring(player.UserId), { code = code, sid = sid, n = player.DisplayName, t = os.time() }, PortalService.SOLO_EXPIRE)
		end)
	end
end
-- Who is in a server of their own now (for the owner's admin menu; no codes in it).
function PortalService.soloList(): { { id: number, name: string } }
	local out = {}
	local m = soloMap
	local ok, items = pcall(function()
		return (m :: any):GetRangeAsync(Enum.SortDirection.Ascending, 100)
	end)
	if ok and type(items) == "table" then
		for _, it in items :: any do
			local id = tonumber(it.key)
			if id and type(it.value) == "table" then
				table.insert(out, { id = id, name = tostring(it.value.n) })
			end
		end
	end
	return out
end
-- The owner goes to watch `userId` in their server. Returns what to tell the owner, or nil when on the way.
function PortalService.spectateSolo(owner: Player, userId: number): string?
	if RunService:IsStudio() then
		return "Teleports work in the live game (not in Studio)"
	end
	local ok, entry = pcall(function()
		return (soloMap :: any):GetAsync(tostring(userId))
	end)
	if not ok or type(entry) ~= "table" or type(entry.code) ~= "string" then
		return "They are not in singleplayer any more. REFRESH the list"
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = entry.code
	options:SetTeleportData({ from = "Spectate", target = userId })
	remote:FireClient(owner, "Going", { kind = "Join" })
	local sent = pcall(TeleportService.TeleportAsync, TeleportService, if MULTI ~= 0 then START_PLACE else game.PlaceId, { owner }, options)
	if not sent then
		remote:FireClient(owner, "Refused", { text = "Could not get there. Try again!" })
	end
	return nil
end

local passing: { [Player]: number } = {} -- (on the way from a public server to their own: teleports tried)

-- A player whose way on failed stays after all: a body and a lab here.
local function stayHere(player: Player)
	if passing[player] then
		passing[player] = nil
		pcall(function()
			player:LoadCharacter()
		end)
	end
	pcall(function()
		(require(script.Parent:WaitForChild("Lab")) :: any).ensureLab(player)
	end)
end

-- (23 Nov 2026, owner: "it is like joining twice"): a public server keeps one reserved server ready, so the way on
-- does not wait for a new one.
local ready: { code: string, sid: string }? = nil
local refilling = false
local function refill()
	if MULTI ~= 0 or refilling or ready or RunService:IsStudio() or game.PrivateServerId ~= "" then
		return
	end
	refilling = true
	task.spawn(function()
		local ok, code, sid = pcall(function()
			return TeleportService:ReserveServer(game.PlaceId)
		end)
		if ok then
			ready = { code = code, sid = sid }
		end
		refilling = false
	end)
end
local function ownServer(): (string, string)
	local r = ready
	if r then
		ready = nil
		refill()
		return r.code, r.sid
	end
	local code, sid = TeleportService:ReserveServer(multiPlace)
	return code, sid
end

local function go(player: Player, how: string, target: Entry?, auto: boolean?)
	if RunService:IsStudio() then
		remote:FireClient(player, "Refused", { text = "Teleports work in the live game (not in Studio)" })
		return
	end
	remote:FireClient(player, "Going", { kind = if auto then "Join" else how })
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ from = how })
	local ok, err = pcall(function()
		local place = multiPlace
		if how == "Solo" and MULTI ~= 0 then
			place = START_PLACE -- (a server of size 1: your own)
		elseif how == "Solo" or how == "Own" then
			local code, sid = ownServer()
			options.ReservedServerAccessCode = code
			task.spawn(listSolo, player, code, sid)
		elseif target then
			options.ServerInstanceId = target.id
		end
		TeleportService:TeleportAsync(place, { player }, options)
	end)
	if not ok then
		log.warn("teleport failed: " .. tostring(err))
		stayHere(player) -- (a lab after all)
		remote:FireClient(player, "Refused", { text = "Could not get there. Try again!" })
	end
end

-- (V11 C10, owner: "multiplayer = a server where everyone shares one lab, and a way back"): shared-lab servers
-- are reserved servers listed in the MemoryStore map SHARED_MAP (access code -> players), each beating its count
-- every BEAT s. MULTIPLAYER goes to the fullest one with room, or reserves a new one; the arrivals carry
-- TeleportData { from = "Shared", code } and Lab makes that server's first lab everyone's. SINGLEPLAYER from
-- there goes back to an ordinary public server (your own lab).
PortalService.SHARED_MAP = "SharedLabs_v1"
local sharedMap: MemoryStoreSortedMap? = nil
local sharedCode: string? = nil

local function sharedTarget(): string?
	local m = sharedMap
	if not m then
		return nil
	end
	local ok, items = pcall(function()
		return (m :: MemoryStoreSortedMap):GetRangeAsync(Enum.SortDirection.Ascending, 50)
	end)
	if not ok or type(items) ~= "table" then
		return nil
	end
	local best, bestN = nil :: string?, -1
	for _, it in items :: any do
		local v = it.value
		local n = if type(v) == "table" and type(v.n) == "number" then v.n else 99
		if n < Players.MaxPlayers and n > bestN and it.key ~= sharedCode then
			best, bestN = it.key, n
		end
	end
	return best
end

local function goShared(player: Player)
	if RunService:IsStudio() then
		remote:FireClient(player, "Refused", { text = "Teleports work in the live game (not in Studio)" })
		return
	end
	remote:FireClient(player, "Going", { kind = "Shared" })
	local ok, err = pcall(function()
		local code = sharedTarget()
		if not code then
			-- (A new shared server: listed at once, so a player picking MULTIPLAYER on another server a moment later
			-- finds this one instead of making a second.)
			code = TeleportService:ReserveServer(multiPlace)
			local m = sharedMap
			if m then
				pcall(function()
					-- lihfolk-ignore: datastore-setasync-player (a MemoryStore server listing that expires, not player data)
					(m :: MemoryStoreSortedMap):SetAsync(code :: string, { n = 0 }, PortalService.EXPIRE)
				end)
			end
		end
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = code
		options:SetTeleportData({ from = "Shared", code = code })
		TeleportService:TeleportAsync(multiPlace, { player }, options)
	end)
	if not ok then
		log.warn("shared teleport failed: " .. tostring(err))
		remote:FireClient(player, "Refused", { text = "Could not get there. Try again!" })
	end
end

local function sharedBeat()
	local m, code = sharedMap, sharedCode
	if m and code then
		pcall(function()
			-- lihfolk-ignore: datastore-setasync-player (a MemoryStore server count that expires, not player data)
			(m :: MemoryStoreSortedMap):SetAsync(code, { n = #Players:GetPlayers() }, PortalService.EXPIRE)
		end)
	end
end

local function onRequest(player: Player, kind: unknown, arg: unknown)
	if type(kind) ~= "string" then
		return
	end
	local now = os.clock()
	-- (The list has its own short pace; it never holds up PLAY NOW: review fix.)
	if kind == "List" then
		if now - (lastList[player] or -math.huge) < 1 then
			return
		end
		lastList[player] = now
	else
		if now - (lastAsk[player] or -math.huge) < PortalService.GAP then
			return
		end
		lastAsk[player] = now
	end
	if kind == "List" then
		local list = PortalService.list()
		local rows = {}
		for _, e in list do
			if e.id ~= jobId() then
				table.insert(rows, { id = e.id, name = e.name, region = e.region, players = e.players, max = e.max })
			end
		end
		remote:FireClient(player, "List", { rows = rows, here = PortalService.entry(), solo = not isPublic() })
	elseif kind == "PlayNow" then
		local target = PortalService.fullest(PortalService.list(), jobId())
		if target then
			go(player, "Multi", target)
		elseif not isPublic() then
			-- (From solo or a private server with no list yet: any shared server.)
			go(player, "Multi", nil)
		else
			remote:FireClient(player, "Refused", { text = "You are in the busiest server already!" })
		end
	elseif kind == "Join" and type(arg) == "string" and #arg <= 64 then
		for _, e in PortalService.list() do
			if e.id == arg and e.players < e.max then
				go(player, "Multi", e)
				return
			end
		end
		remote:FireClient(player, "Refused", { text = "That server is full or gone. Pick another!" })
	elseif kind == "Own" then
		go(player, "Own", nil)
	elseif kind == "PickSingle" then
		-- (23 Nov 2026, owner: "I picked singleplayer but stay on the same server as multiplayer: I only hold a place
		-- others could use"): on a public server, singleplayer is a server of your own (a reserved one, "Solo");
		-- already on a private one, or in Studio, you stay.
		if isPublic() and not RunService:IsStudio() then
			go(player, "Solo", nil)
		else
			remote:FireClient(player, "Stay")
		end
	elseif kind == "LeaveShared" then
		-- (23 Nov 2026: the MULTIPLAYER portal again, from inside a shared lab: back to a lab of your own here.)
		pcall(function()
			(require(script.Parent:WaitForChild("Lab")) :: any).leaveShared(player)
		end)
	elseif kind == "JoinShared" then
		-- (23 Nov 2026: the start menu's MULTIPLAYER. Owner: "2 accounts picked multiplayer and did not end up in the same
		-- lab": they were on two servers. A shared lab already on this server (or this is a shared server, or Studio):
		-- join it here, Lab.joinShared. Otherwise to the shared-lab server everyone who picks MULTIPLAYER goes to
		-- (goShared: the fullest one with room, or a new one).)
		-- (23 Nov 2026, owner: "multiplayer sends you to the fullest server already, nobody feels alone; switching
		-- servers must always land you in the same lab"): a fuller public server with room: there (TeleportData from
		-- "Multi"; on arrival Lab puts every multiplayer arrival in that server's one shared lab). Otherwise this
		-- server is the fullest: the shared lab here.
			-- (23 Nov 2026, owner: "load in as fast and lag-free as possible"): with anyone else on this server, the shared
		-- lab here (no teleport); alone, the fullest multiplayer server.
		if MULTI ~= 0 and game.PlaceId ~= MULTI then
			go(player, "Multi", PortalService.fullest(PortalService.list(), jobId()))
			return
		end
		local alone = #Players:GetPlayers() <= 1
		local target = if RunService:IsStudio() or not alone then nil else PortalService.fullest(PortalService.list(), jobId())
		local here = PortalService.entry()
		local there = if target then (target.shared or 0) else -1
		if target and (there > (here.shared or 0) or (there == (here.shared or 0) and target.players >= here.players)) then
			go(player, "Multi", target)
		else
			pcall(function()
				(require(script.Parent:WaitForChild("Lab")) :: any).joinShared(player)
			end)
		end
	elseif kind == "Shared" then
		goShared(player)
	elseif kind == "Friend" and type(arg) == "string" and #arg <= 64 and string.match(arg, "^[%x%-]+$") then
		-- (23 Nov 2026, owner: "join your friends"): to a friend's server (its job id, from Roblox's friends list).
		go(player, "Multi", { id = arg, name = "", region = "", players = 0, max = 0, t = 0 })
	elseif kind == "Solo" then
		go(player, "Solo", nil)
	end
end
PortalService.onRequestForTest = onRequest

-- The two portals in a lab (Playground calls this for each lab it builds).
function PortalService.buildPortals(folder: Instance, origin: Vector3)
	local function arch(name: string, x: number, color: Color3, text: string)
		local m = Instance.new("Model")
		m.Name = name
		local function piece(size: Vector3, at: Vector3, neon: boolean): Part
			local p = Instance.new("Part")
			p.Anchored = true
			p.Size = size
			p.CFrame = CFrame.new(origin + at)
			p.Color = if neon then color else Color3.fromRGB(45, 47, 58)
			p.Material = if neon then Enum.Material.Neon else Enum.Material.Metal
			p.Parent = m
			return p
		end
		piece(Vector3.new(1.2, 10, 1.2), Vector3.new(x - 4, 5, 24), false)
		piece(Vector3.new(1.2, 10, 1.2), Vector3.new(x + 4, 5, 24), false)
		piece(Vector3.new(9.2, 1.2, 1.2), Vector3.new(x, 10.6, 24), false)
		local field = piece(Vector3.new(6.8, 9.4, 0.3), Vector3.new(x, 4.9, 24), true)
		field.Name = "Field"
		field.Transparency = 0.35
		field.CanCollide = false
		field:SetAttribute("Portal", name)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.new(12, 0, 2.2, 0)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
		gui.MaxDistance = 120
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = color
		label.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(10, 10, 14)
		stroke.Parent = label
		label.Parent = gui
		gui.Parent = field
		local last: { [Player]: number } = {}
		table.insert(portalTouch, last)
		field.Touched:Connect(function(other)
			local character = other:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player or os.clock() - (last[player] or -math.huge) < 4 then
				return
			end
			last[player] = os.clock()
			remote:FireClient(player, "Open", { portal = name })
		end)
		m.Parent = folder
	end
	-- V5-1 (owner: "improve everything"): with Config.UI_CLEAN the doors stand by the lab's west side,
	-- turned to its middle (the view from the spawn stays open), as a steel frame with a dark glass
	-- door, a thin light strip and a small plate sign; no neon-filled doorway, no floating words.
	local Config = require(game:GetService("ReplicatedStorage").Shared.Config) :: any
	if Config.UI_CLEAN then
		local function door(name: string, z: number, color: Color3, text: string)
			if Config.MAP_BOARD then
				-- (V9-0e: the same ring family as the gold PLACES portal: SINGLEPLAYER blue, MULTIPLAYER
				-- green, each with its word and glyph on the keystone; same spot, same touch.)
				local MapBoard = require(script.Parent:WaitForChild("MapBoard")) :: any
				local at = origin + Vector3.new(-66, 0, z)
				local faceTo = origin + Vector3.new(0, 0, z)
				-- (V9-NOW 20 + 22: with Config.TRAVEL_CORNER the two portals stand either side of the MAPS board on the
				-- west rim (MapBoard.TRAVEL_SPOTS): one travel corner, out of the spawn's way.)
				if Config.TRAVEL_CORNER then
					at, faceTo = MapBoard.travelSpot(origin, name)
				end
				local gm, swirl = MapBoard.gate(folder, at, faceTo, if name == "PortalSolo" then "Solo" else "Multi", MapBoard.RING_SMALL)
				gm.Name = name
				swirl:SetAttribute("Portal", name)
				local lastTouch: { [Player]: number } = {}
				table.insert(portalTouch, lastTouch)
				swirl.Touched:Connect(function(other)
					local character = other:FindFirstAncestorOfClass("Model")
					local player = character and Players:GetPlayerFromCharacter(character)
					if not player or os.clock() - (lastTouch[player] or -math.huge) < 4 then
						return
					end
					lastTouch[player] = os.clock()
					remote:FireClient(player, "Open", { portal = name })
				end)
				return
			end
			local m = Instance.new("Model")
			m.Name = name
			local base = CFrame.new(origin + Vector3.new(-66, 0, z)) * CFrame.Angles(0, math.rad(-90), 0)
			local steel = Color3.fromRGB(58, 61, 68)
			local function piece(pname: string, size: Vector3, at: CFrame, color3: Color3, material: Enum.Material): Part
				local p = Instance.new("Part")
				p.Name = pname
				p.Anchored = true
				p.Size = size
				p.CFrame = base * at
				p.Color = color3
				p.Material = material
				p.Parent = m
				return p
			end
			piece("Post", Vector3.new(1, 10, 1.4), CFrame.new(-4, 5, 0), steel, Enum.Material.Metal)
			piece("Post", Vector3.new(1, 10, 1.4), CFrame.new(4, 5, 0), steel, Enum.Material.Metal)
			piece("Lintel", Vector3.new(9, 1.2, 1.4), CFrame.new(0, 10.6, 0), steel, Enum.Material.Metal)
			piece("Step", Vector3.new(10, 0.4, 3), CFrame.new(0, 0.2, 0), Color3.fromRGB(44, 46, 52), Enum.Material.DiamondPlate)
			for _, sx in { -3.35, 3.35 } do
				local strip = piece("Strip", Vector3.new(0.15, 9.2, 0.2), CFrame.new(sx, 4.9, -0.1), color, Enum.Material.Neon)
				strip.CanCollide = false
			end
			local field = piece("Field", Vector3.new(6.6, 9.4, 0.25), CFrame.new(0, 4.9, 0), Color3.fromRGB(24, 28, 36), Enum.Material.Glass)
			field.Transparency = 0.25
			field.Reflectance = 0.15
			field.CanCollide = false
			field:SetAttribute("Portal", name)
			local glow = Instance.new("PointLight")
			glow.Color = color
			glow.Range = 10
			glow.Brightness = 0.8
			glow.Parent = field
			-- The plate sign over the lintel.
			local plate = piece("Plate", Vector3.new(8, 1.6, 0.2), CFrame.new(0, 12, -0.2), Color3.fromRGB(30, 32, 38), Enum.Material.Metal)
			plate.CanCollide = false
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Front
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 40
			gui.LightInfluence = 0.2
			gui.Parent = plate
			local dot = Instance.new("Frame")
			dot.Size = UDim2.fromOffset(22, 22)
			dot.Position = UDim2.new(0, 16, 0.5, -11)
			dot.BackgroundColor3 = color
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent = dot
			dot.Parent = gui
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, -60, 1, -12)
			label.Position = UDim2.fromOffset(48, 6)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(236, 236, 232)
			label.Text = text
			label.Parent = gui
			local last: { [Player]: number } = {}
			table.insert(portalTouch, last)
			field.Touched:Connect(function(other)
				local character = other:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player or os.clock() - (last[player] or -math.huge) < 4 then
					return
				end
				last[player] = os.clock()
				remote:FireClient(player, "Open", { portal = name })
			end)
			m.Parent = folder
		end
		-- (23 Nov 2026, owner: "a singleplayer portal in the multiplayer lab": out of the shared lab, back to your own.)
		-- (Only on a multiplayer server: on your own server you are in singleplayer already.)
		if isPublic() then
			door("PortalSolo", 30, Color3.fromRGB(80, 210, 120), "SINGLEPLAYER")
		end
		door("PortalMulti", 44, Color3.fromRGB(90, 170, 250), "MULTIPLAYER")
		return
	end
	if isPublic() then
		arch("PortalSolo", -7, Color3.fromRGB(70, 220, 110), "SINGLEPLAYER")
	end
	arch("PortalMulti", 7, Color3.fromRGB(80, 170, 255), "MULTIPLAYER")
end

function PortalService.start()
	remote = Net.event(Net.Names.Portal)
	remote.OnServerEvent:Connect(onRequest)
	refill()
	-- (A teleport that fails after it set off: the player stays here, so they get a lab.)
	TeleportService.TeleportInitFailed:Connect(function(player)
		local tries = passing[player]
		if tries and tries < 2 and player.Parent then
			passing[player] = tries + 1
			task.wait(1)
			go(player, "Solo", nil, true)
			return
		end
		remote:FireClient(player, "Refused", { text = "Could not get there. Try again!" })
		stayHere(player)
	end)
	if not RunService:IsStudio() then
		local ok, m = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, PortalService.MAP)
		map = if ok then m else nil
		local ok2, m2 = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, PortalService.SHARED_MAP)
		sharedMap = if ok2 then m2 else nil
		local ok3, m3 = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, PortalService.SOLO_MAP)
		soloMap = if ok3 then m3 else nil
	end
	local function added(player: Player)
		-- (23 Nov 2026, owner: "you load into singleplayer automatically: nobody else in your server; multiplayer only
		-- through the portal"): a player who comes in through Roblox's Play onto a public server (the multiplayer
		-- servers) goes straight on to a server of their own. Arrivals through the multiplayer portal stay.
		if MULTI == 0 and isPublic() and not RunService:IsStudio() then
			local okJ, join = pcall(function()
				return player:GetJoinData()
			end)
			local data = if okJ and type(join) == "table" then (join :: any).TeleportData else nil
			local from = if type(data) == "table" then data.from else nil
			if from ~= "Multi" and from ~= "Shared" and player.FollowUserId == 0 then -- (a friend who joined someone through Roblox stays with them)
				-- (Owner: "you still come into multiplayer for a second": no body here meanwhile, and the same
				-- loading screen all the way, PortalUI "Join".)
				passing[player] = 1
				local function noBody(character: Model)
					task.defer(function()
						if passing[player] and character.Parent then
							character:Destroy()
						end
					end)
				end
				player.CharacterAdded:Connect(noBody)
				if player.Character then
					noBody(player.Character)
				end
				task.spawn(go, player, "Solo", nil, true)
			end
		elseif not RunService:IsStudio() then
			-- The owner come to watch someone in their own server (checked here, not by what the data says).
			local okJ, join = pcall(function()
				return player:GetJoinData()
			end)
			local data = if okJ and type(join) == "table" then (join :: any).TeleportData else nil
			local Owner = require(script.Parent:WaitForChild("Owner")) :: any
			if type(data) == "table" and data.from == "Spectate" and type(data.target) == "number" and Owner.isOwner(player) then
				player:SetAttribute("SpectateTarget", data.target)
				local function unseen(character: Model)
					local root = character:WaitForChild("HumanoidRootPart", 10)
					if root and root:IsA("BasePart") then
						root.Anchored = true
						character:PivotTo(CFrame.new(0, 600, 0))
					end
					local function hide(d: Instance)
						if d:IsA("BasePart") or d:IsA("Decal") then
							d.Transparency = 1
						end
						if d:IsA("BasePart") then
							d.CanCollide = false
							d.CanQuery = false
						end
					end
					for _, d in character:GetDescendants() do
						hide(d)
					end
					character.DescendantAdded:Connect(hide)
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					end
				end
				player.CharacterAdded:Connect(unseen)
				if player.Character then
					task.spawn(unseen, player.Character)
				end
			end
		end
		if not sharedCode then
			local okJ, join = pcall(function()
				return player:GetJoinData()
			end)
			local data = if okJ and type(join) == "table" then (join :: any).TeleportData else nil
			if type(data) == "table" and data.from == "Shared" and type(data.code) == "string" and #data.code < 200 then
				sharedCode = data.code
				task.spawn(sharedBeat)
			end
		end
		if region == "?" then
			local ok, code = pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, player)
			if ok and type(code) == "string" then
				region = code
			end
		end
	end
	Players.PlayerAdded:Connect(added)
	-- (Bug, 23 Nov 2026: the first player of a fresh server is often in before this starts; they were never sent
	-- on, and had no lab.)
	for _, player in Players:GetPlayers() do
		task.spawn(added, player)
	end
	-- A server of someone's own keeps its listing fresh.
	if not RunService:IsStudio() and game.PrivateServerId ~= "" then
		task.spawn(function()
			local codes: { [number]: string } = {}
			while true do
				for _, p in Players:GetPlayers() do
					if not codes[p.UserId] then
						local ok, entry = pcall(function()
							return (soloMap :: any):GetAsync(tostring(p.UserId))
						end)
						if ok and type(entry) == "table" and entry.sid == game.PrivateServerId then
							codes[p.UserId] = entry.code
						end
					else
						listSolo(p, codes[p.UserId], game.PrivateServerId)
					end
				end
				task.wait(60)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastAsk[player] = nil
		lastList[player] = nil
		passing[player] = nil
		for _, t in portalTouch do
			t[player] = nil
		end
		task.defer(beat)
	end)
	task.spawn(function()
		while true do
			beat()
			sharedBeat()
			task.wait(PortalService.BEAT)
		end
	end)
	game:BindToClose(function()
		local sm, sc = sharedMap, sharedCode
		if sm and sc then
			pcall(function()
				(sm :: MemoryStoreSortedMap):RemoveAsync(sc)
			end)
		end
		local m = map
		if m and isPublic() then
			pcall(function()
				(m :: MemoryStoreSortedMap):RemoveAsync(jobId())
			end)
		end
	end)
	Workspace:SetAttribute("ServerName", PortalService.nameOf(jobId()))
end

return PortalService
