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

export type Entry = { id: string, name: string, region: string, players: number, max: number, t: number }

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
	return { id = jobId(), name = PortalService.nameOf(jobId()), region = region, players = #Players:GetPlayers(), max = Players.MaxPlayers, t = os.time() }
end

-- PLAY NOW's choice: the fullest server with room that is not this one (nil: none).
function PortalService.fullest(list: { Entry }, selfId: string): Entry?
	local best: Entry? = nil
	for _, e in list do
		if e.id ~= selfId and e.players < e.max and (best == nil or e.players > (best :: Entry).players) then
			best = e
		end
	end
	return best
end

local map: MemoryStoreSortedMap? = nil
local listCache: { Entry } = {}
local listAt = 0

local function isPublic(): boolean
	return game.PrivateServerId == "" and game.JobId ~= ""
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

local function go(player: Player, how: string, target: Entry?)
	if RunService:IsStudio() then
		remote:FireClient(player, "Refused", { text = "Teleports work in the live game (not in Studio)" })
		return
	end
	remote:FireClient(player, "Going", { kind = how })
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ from = how })
	local ok, err = pcall(function()
		if how == "Solo" or how == "Own" then
			local code = TeleportService:ReserveServer(game.PlaceId)
			options.ReservedServerAccessCode = code
		elseif target then
			options.ServerInstanceId = target.id
		end
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		log.warn("teleport failed: " .. tostring(err))
		remote:FireClient(player, "Refused", { text = "Could not get there. Try again!" })
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
	arch("PortalSolo", -7, Color3.fromRGB(70, 220, 110), "SINGLEPLAYER")
	arch("PortalMulti", 7, Color3.fromRGB(80, 170, 255), "MULTIPLAYER")
end

function PortalService.start()
	remote = Net.event(Net.Names.Portal)
	remote.OnServerEvent:Connect(onRequest)
	if not RunService:IsStudio() then
		local ok, m = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, PortalService.MAP)
		map = if ok then m else nil
	end
	Players.PlayerAdded:Connect(function(player)
		if region == "?" then
			local ok, code = pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, player)
			if ok and type(code) == "string" then
				region = code
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAsk[player] = nil
		lastList[player] = nil
		for _, t in portalTouch do
			t[player] = nil
		end
		task.defer(beat)
	end)
	task.spawn(function()
		while true do
			beat()
			task.wait(PortalService.BEAT)
		end
	end)
	game:BindToClose(function()
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
