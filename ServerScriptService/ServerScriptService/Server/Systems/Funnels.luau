--!strict
-- Funnels (24 Nov 2026, owner: "better funnels that fit us now"). What the Creator Dashboard's funnels show. From the
-- server only, nothing in Studio, every step logged in order and once, a failing call never breaks the game.
--   Onboarding (new players, once): 1 Joined  2 Loaded  3 FirstTool  4 FirstTakedown  5 SecondTool  6 FiveTakedowns
--     7 ThirdTool
--   PlaytimeNew / PlaytimeAll (each visit): 1 Joined  2 30s  3 1min  4 2min  5 5min  6 10min  7 20min
--   TakedownsNew (new players): 1 Joined  2 1  3 5  4 10  5 25  6 50  7 100
--   ShopVisit (each opening of the shop): 1 Opened  2 Prompt  3 Bought
--   Multiplayer (per player and day): 1 InSingleplayer  2 Travelled  3 Arrived
-- And the custom event "FirstUse" (which machine, creature or map a player used, once a visit each).
-- A hop between our own two places is the same visit: no new Joined or playtime there.

local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local Funnels = {}

Funnels.ONBOARDING = { "Joined", "Loaded", "FirstTool", "FirstTakedown", "SecondTool", "FiveTakedowns", "ThirdTool" }
Funnels.PLAYTIME = { { 30, "30s" }, { 60, "1min" }, { 120, "2min" }, { 300, "5min" }, { 600, "10min" }, { 1200, "20min" } }
Funnels.TAKEDOWNS = { 1, 5, 10, 25, 50, 100 }
Funnels.SHOP_WINDOW = 300 -- s after the shop opened that a prompt still belongs to it

type State = {
	new: boolean,
	done: { [string]: boolean }, -- the onboarding marks reached (in any order)
	step: number, -- the last onboarding step logged
	visit: string,
	tools: { [string]: boolean },
	toolCount: number,
	takedownStep: number,
	shop: string?,
	shopAt: number,
	shopStep: number,
	used: { [string]: boolean },
}
local states: { [Player]: State } = {}

local function live(): boolean
	return not RunService:IsStudio()
end

-- Came from our other place, so this is the same visit.
local function hopped(player: Player): boolean
	local ok, data = pcall(function()
		return player:GetJoinData()
	end)
	return ok and type(data) == "table" and data.SourceGameId == game.GameId
end

local function day(player: Player): string
	return player.UserId .. "-" .. os.date("!%Y%m%d")
end

local function funnel(player: Player, name: string, session: string, step: number, label: string)
	if not live() then
		return
	end
	pcall(function()
		AnalyticsService:LogFunnelStepEvent(player, name, session, step, label)
	end)
end

local function stateOf(player: Player): State
	local s = states[player]
	if not s then
		s = { new = false, done = {}, step = 0, visit = HttpService:GenerateGUID(false), tools = {}, toolCount = 0, takedownStep = 0, shop = nil, shopAt = 0, shopStep = 0, used = {} }
		states[player] = s
	end
	return s :: State
end

-- The onboarding's steps that are reached with every one before them, in order.
local function climb(player: Player, s: State)
	while s.new and s.step < #Funnels.ONBOARDING and s.done[Funnels.ONBOARDING[s.step + 1]] do
		s.step += 1
		if live() then
			local step = s.step
			pcall(function()
				AnalyticsService:LogOnboardingFunnelStepEvent(player, step, Funnels.ONBOARDING[step])
			end)
		end
	end
end

local function mark(player: Player, name: string)
	local s = stateOf(player)
	if not s.done[name] then
		s.done[name] = true
		climb(player, s)
	end
end

local function takedowns(player: Player)
	local s = stateOf(player)
	local n = player:GetAttribute("Takedowns")
	if type(n) ~= "number" or not s.new then
		return
	end
	if n >= 1 then
		mark(player, "FirstTakedown")
	end
	if n >= 5 then
		mark(player, "FiveTakedowns")
	end
	while s.takedownStep < #Funnels.TAKEDOWNS and n >= Funnels.TAKEDOWNS[s.takedownStep + 1] do
		s.takedownStep += 1
		funnel(player, "TakedownsNew", tostring(player.UserId), s.takedownStep + 1, tostring(Funnels.TAKEDOWNS[s.takedownStep]))
	end
end

-- The player is new (OnboardingService knows once the saved record is read).
function Funnels.newPlayer(player: Player)
	local s = stateOf(player)
	if s.new or not player.Parent then
		return
	end
	s.new = true
	s.done.Joined = true
	climb(player, s)
	if not hopped(player) then
		funnel(player, "PlaytimeNew", s.visit, 1, "Joined")
		funnel(player, "TakedownsNew", tostring(player.UserId), 1, "Joined")
	end
	takedowns(player)
end

-- The load cover lifted.
function Funnels.loaded(player: Player)
	mark(player, "Loaded")
end

-- A tool was used and the server accepted it.
function Funnels.tool(player: Player, id: string)
	local s = stateOf(player)
	if s.tools[id] then
		return
	end
	s.tools[id] = true
	s.toolCount += 1
	mark(player, "Loaded") -- (whoever uses a tool is in)
	mark(player, "FirstTool")
	if s.toolCount >= 2 then
		mark(player, "SecondTool")
	end
	if s.toolCount >= 3 then
		mark(player, "ThirdTool")
	end
end

-- The shop: "open", "prompt" (a buy window closed without a buy) or "bought".
function Funnels.shop(player: Player, what: string)
	local s = stateOf(player)
	local now = os.clock()
	if what == "open" then
		if s.shop and now - s.shopAt < 20 and s.shopStep <= 1 then
			return -- (shut and opened again: the same look)
		end
		s.shop, s.shopAt, s.shopStep = HttpService:GenerateGUID(false), now, 1
		funnel(player, "ShopVisit", s.shop :: string, 1, "Opened")
	elseif s.shop and now - s.shopAt < Funnels.SHOP_WINDOW then
		if s.shopStep < 2 then
			s.shopStep = 2
			funnel(player, "ShopVisit", s.shop :: string, 2, "Prompt")
		end
		if what == "bought" and s.shopStep < 3 then
			s.shopStep = 3
			funnel(player, "ShopVisit", s.shop :: string, 3, "Bought")
		end
	end
end

-- On the way to the multiplayer place.
function Funnels.travelled(player: Player)
	funnel(player, "Multiplayer", day(player), 2, "Travelled")
end

-- A machine, creature, map ... used for the first time this visit.
function Funnels.used(player: Player, what: string)
	local s = stateOf(player)
	if s.used[what] then
		return
	end
	s.used[what] = true
	pcall(function()
		(require(script.Parent:WaitForChild("Metrics")) :: any).event(player, "FirstUse", 1, what)
	end)
end

local function join(player: Player)
	local s = stateOf(player)
	player:GetAttributeChangedSignal("Takedowns"):Connect(function()
		takedowns(player)
	end)
	local hop = hopped(player)
	if game.PlaceId == Config.MULTI_PLACE then
		if hop then
			funnel(player, "Multiplayer", day(player), 3, "Arrived")
		end
	elseif game.PlaceId == Config.START_PLACE then
		funnel(player, "Multiplayer", day(player), 1, "InSingleplayer")
	end
	if hop then
		return
	end
	funnel(player, "PlaytimeAll", s.visit, 1, "Joined")
	local began = os.clock()
	for i, mark_ in Funnels.PLAYTIME do
		task.delay(math.max(0, (mark_[1] :: number) - (os.clock() - began)), function()
			if player.Parent and states[player] == s then
				funnel(player, "PlaytimeAll", s.visit, i + 1, mark_[2] :: string)
				if s.new then
					funnel(player, "PlaytimeNew", s.visit, i + 1, mark_[2] :: string)
				end
			end
		end)
	end
end

function Funnels.start()
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do
		task.spawn(join, p)
	end
	Players.PlayerRemoving:Connect(function(player)
		task.delay(5, function()
			states[player] = nil
		end)
	end)
end

return Funnels
