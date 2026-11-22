--!strict
-- PurchaseChat (V11 B7, owner 22 Nov 2026: "Robux purchases shown in chat on every server"). A real purchase (a
-- developer product receipt that is new, or a game pass bought) is published on the MessagingService topic
-- TOPIC with the buyer's display name, the item's name and its price; every server (this one too) passes it to
-- its players on the Remotes.BoughtChat event, and Client/BoughtChat writes it in chat as a system line:
-- "Name bought X for R$N". Names only, nothing else. At most one line per buyer per GAP s, and Studio says it
-- only on its own server.

local MarketplaceService = game:GetService("MarketplaceService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PurchaseChat = {}

PurchaseChat.TOPIC = "BoughtChat_v1"
PurchaseChat.GAP = 5

local remote: RemoteEvent? = nil
local last: { [number]: number } = {}
local started = false

local function event(): RemoteEvent
	local r = remote
	if r and r.Parent then
		return r
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local made = (remotes and remotes:FindFirstChild("BoughtChat")) :: RemoteEvent?
	if not made then
		local e = Instance.new("RemoteEvent")
		e.Name = "BoughtChat"
		e.Parent = remotes or ReplicatedStorage
		made = e
	end
	remote = made
	return made :: RemoteEvent
end

local function deliver(data: any)
	if type(data) ~= "table" or type(data.n) ~= "string" or type(data.i) ~= "string" or type(data.p) ~= "number" then
		return
	end
	event():FireAllClients(string.sub(data.n, 1, 40), string.sub(data.i, 1, 60), math.floor(data.p))
end

-- `player` paid `price` Robux for `id` (an asset of `infoType`). Looks the name up, then tells every server.
function PurchaseChat.bought(player: Player, id: number, infoType: Enum.InfoType, price: number?)
	local now = os.clock()
	if now - (last[player.UserId] or -math.huge) < PurchaseChat.GAP then
		return
	end
	last[player.UserId] = now
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		local name = if ok and type(info) == "table" and type((info :: any).Name) == "string" then (info :: any).Name else nil
		local robux = price or (if ok and type(info) == "table" then (info :: any).PriceInRobux else nil)
		if not name or type(robux) ~= "number" or robux <= 0 then
			return
		end
		local data = { n = player.DisplayName, i = name, p = robux }
		local sent = false
		if not RunService:IsStudio() then
			sent = pcall(MessagingService.PublishAsync, MessagingService, PurchaseChat.TOPIC, data)
		end
		if not sent then
			deliver(data) -- (Studio, or the publish failed: at least this server)
		end
	end)
end

function PurchaseChat.start()
	if started then
		return
	end
	started = true
	event()
	if not RunService:IsStudio() then
		task.spawn(function()
			pcall(MessagingService.SubscribeAsync, MessagingService, PurchaseChat.TOPIC, function(message)
				deliver(message.Data)
			end)
		end)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		if purchased then
			PurchaseChat.bought(player, passId, Enum.InfoType.GamePass, nil)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player.UserId] = nil
	end)
end

return PurchaseChat
