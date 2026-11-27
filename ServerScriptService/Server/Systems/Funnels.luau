--!strict
-- Funnels (24 Nov 2026, owner: "better funnels that fit us now"). What the Creator Dashboard's funnels show. From the
-- server only, nothing in Studio, every step logged in order and once, a failing call never breaks the game.
-- (FIXES_27NOV_LATE 4, owner: "Sæt funnels op så de passer til alt det nye": rebuilt round the new first minutes.)
--   Onboarding (new players, once): 1 Joined  2 Loaded  3 BowlingTry  4 FirstStrike  5 FirstShot  6 FirstKO
--     7 FirstXray  8 SecondMachine  9 ThirdMachine  10 FirstCare  11 FiveMinutes
--   PlaytimeNew / PlaytimeAll and NewPhone/NewTablet/NewPC/NewConsole (each visit): 1 Joined  2 30s ... 7 20min
--   ShopVisit (each opening of the shop): 1 Opened  2 Prompt  3 Bought
--   Vehicles (per player and day): 1 Pressed (a vehicle's prompt)  2 SatFree  3 PassPrompt (a paid one)  4 Bought
--   Multiplayer (per player and day): 1 InSingleplayer  2 Travelled  3 Arrived
--   (retired: Tutorial and TakedownsNew measured the old game)
-- Custom events: "FirstUse" (a machine, creature or map, once a visit), "XrayToggle", "BodyCardHidden", "CPRDone",
-- "BowlingScore" (the frame's score in 0-9 / 10-19 / 20-30).
-- A hop between our own two places is the same visit: no new Joined or playtime there.

local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local Funnels = {}

Funnels.ONBOARDING = { "Joined", "Loaded", "BowlingTry", "FirstStrike", "FirstShot", "FirstKO", "FirstXray", "SecondMachine", "ThirdMachine", "FirstCare", "FiveMinutes" }
-- What counts as a machine for SecondMachine / ThirdMachine (bowling is the first one).
Funnels.MACHINES = { Cannon = true, Wrecking = true, Spider = true, Plant = true, Frog = true, Whale = true, Chicken = true, Washer = true, Slingshot = true, Mole = true, Vacuum = true, Tower = true, Compressor = true, Shredder = true, Gyro = true, Fan = true } :: { [string]: boolean }
Funnels.PLAYTIME = { { 30, "30s" }, { 60, "1min" }, { 120, "2min" }, { 300, "5min" }, { 600, "10min" }, { 1200, "20min" } }
Funnels.DEVICE_FUNNEL = { phone = "NewPhone", tablet = "NewTablet", pc = "NewPC", console = "NewConsole" } :: { [string]: string }
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
	machines: number?,
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
		mark(player, "FirstKO")
	end
end

-- A step of the new onboarding reached (Bowling, VitalsService, PlayerCPR, SessionStats ...): logged in order, once.
function Funnels.step(player: Player, name: string)
	if table.find(Funnels.ONBOARDING, name) then
		mark(player, name)
	end
end

-- A custom event (Metrics), never in Studio.
function Funnels.event(player: Player, name: string, label: string?)
	pcall(function()
		(require(script.Parent:WaitForChild("Metrics")) :: any).event(player, name, 1, label)
	end)
end

-- The Vehicles funnel: "Pressed", "SatFree", "PassPrompt", "Bought" (per player and day, each step once; only the
-- steps really taken are logged, so a pass bought without the free bike first never counts a false SatFree).
Funnels.VEHICLE_STEPS = { "Pressed", "SatFree", "PassPrompt", "Bought" }
local vehicleDone: { [Player]: { [string]: boolean } } = setmetatable({}, { __mode = "k" }) :: any
function Funnels.vehicle(player: Player, what: string)
	local i = table.find(Funnels.VEHICLE_STEPS, what)
	local done = vehicleDone[player] or {}
	vehicleDone[player] = done
	if not i or done[what] then
		return
	end
	done[what] = true
	funnel(player, "Vehicles", day(player), i, what)
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
	local ok, gun = pcall(function()
		local toy = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Toys")) :: any).byId[id]
		return toy ~= nil and toy.gun == true
	end)
	if ok and gun then
		mark(player, "FirstShot")
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

-- NOW 7 (owner, 26 Nov 2026): the tutorial's steps (Client/FirstVisit), each logged once, in order, on
-- the "Tutorial" funnel. Unknown step names are ignored.
Funnels.TUTORIAL = { "Takedown", "Throw", "Cannon", "Wrecking", "Weapons", "Maps" }
local tutorialDone: { [Player]: { [string]: boolean } } = setmetatable({}, { __mode = "k" }) :: any
function Funnels.tutorial(player: Player, id: string)
	if true then
		return -- (FIXES_27NOV_LATE 4: the "Tutorial" funnel is retired; it measured the old game)
	end
	local index = table.find(Funnels.TUTORIAL, id)
	if not index then
		return
	end
	local done = tutorialDone[player] or {}
	tutorialDone[player] = done
	if done[id] then
		return
	end
	done[id] = true
	funnel(player, "Tutorial", tostring(player.UserId), index, id)
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
	if Funnels.MACHINES[what] then
		s.machines = (s.machines or 0) + 1
		mark(player, "SecondMachine")
		if (s.machines :: number) >= 2 then
			mark(player, "ThirdMachine")
		end
	end
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
	-- (The device and whether the player is new are known a moment after the join.)
	task.delay(8, function()
		local device = player:GetAttribute("Device")
		if s.new and player.Parent and type(device) == "string" and Funnels.DEVICE_FUNNEL[device] then
			funnel(player, Funnels.DEVICE_FUNNEL[device], s.visit, 1, "Joined")
		end
	end)
	local began = os.clock()
	for i, mark_ in Funnels.PLAYTIME do
		task.delay(math.max(0, (mark_[1] :: number) - (os.clock() - began)), function()
			if player.Parent and states[player] == s then
				if (mark_[1] :: number) >= 300 then
					mark(player, "FiveMinutes")
				end
				funnel(player, "PlaytimeAll", s.visit, i + 1, mark_[2] :: string)
				if s.new then
					funnel(player, "PlaytimeNew", s.visit, i + 1, mark_[2] :: string)
					-- (NOW 1/4, 26 Nov 2026: the same steps per device, so the phone gap shows: NewPhone, NewTablet, NewPC, NewConsole.)
					local device = player:GetAttribute("Device")
					if type(device) == "string" and Funnels.DEVICE_FUNNEL[device] then
						funnel(player, Funnels.DEVICE_FUNNEL[device], s.visit, i + 1, mark_[2] :: string)
					end
				end
			end
		end)
	end
end

function Funnels.start()
	-- (Vehicles funnel, step 4: a vehicle pass bought)
	game:GetService("MarketplaceService").PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
		if not bought then
			return
		end
		pcall(function()
			for _, id in (require(script.Parent:WaitForChild("VehicleService")) :: any).PASSES do
				if id == passId then
					Funnels.vehicle(player, "Bought")
					break
				end
			end
		end)
	end)
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
