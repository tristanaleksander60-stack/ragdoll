--!strict
-- Server bootstrap. Systems are required from here in a fixed order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Round 4, M10: Shift is the sprint key, never Roblox's mouse lock (set before anyone joins).
game:GetService("StarterPlayer").EnableMouseLockOption = false

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Log = require(Shared:WaitForChild("Log"))

local Systems = script.Parent:WaitForChild("Systems")
local FxService = require(Systems:WaitForChild("FxService"))
local VitalsService = require(Systems:WaitForChild("VitalsService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local ToyService = require(Systems:WaitForChild("ToyService"))
local OnboardingService = require(Systems:WaitForChild("OnboardingService"))
local HitService = require(Systems:WaitForChild("HitService"))
local Lab = require(Systems:WaitForChild("Lab"))
local BuildService = require(Systems:WaitForChild("BuildService"))
local BuildStore = require(Systems:WaitForChild("BuildStore"))
local PlayerRagdoll = require(Systems:WaitForChild("PlayerRagdoll"))
local Playground = require(Systems:WaitForChild("Playground"))
local Purchases = require(Systems:WaitForChild("Purchases"))
local EventService = require(Systems:WaitForChild("EventService"))
local LoadoutStore = require(Systems:WaitForChild("LoadoutStore"))
local HeldService = require(Systems:WaitForChild("HeldService"))
local CrowdService = require(Systems:WaitForChild("CrowdService"))
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local LeaderboardService = require(Systems:WaitForChild("LeaderboardService"))
local ChristmasService = require(Systems:WaitForChild("ChristmasService"))
local AdminService = require(Systems:WaitForChild("AdminService"))
local MinigameService = require(Systems:WaitForChild("MinigameService"))
local FriendsService = require(Systems:WaitForChild("FriendsService"))
local HordeService = require(Systems:WaitForChild("HordeService"))
local StreamerService = require(Systems:WaitForChild("StreamerService"))
local Metrics = require(Systems:WaitForChild("Metrics"))
local MoneyService = require(Systems:WaitForChild("MoneyService"))
local WeaponShop = require(Systems:WaitForChild("WeaponShop"))

local log = Log.new("Boot")
log.info(string.format("%s %s (phase %d) server started", Config.GameName, Config.Version, Config.Phase))
-- (V8-6.2: the build stamp, tools/stamp.pl: which commit this server runs.)
pcall(function()
	local stamp = require(script.Parent:WaitForChild("BuildStamp", 5)) :: any
	log.info(string.format("build %s (%s)", tostring(stamp.commit), tostring(stamp.made)))
	workspace:SetAttribute("Build", stamp.commit)
end)

-- V8-0.9 (safe boot): every system starts under pcall (Shared\SafeStart), so one error no longer
-- stops the systems after it (saving above all). A failure is listed in workspace attribute
-- BootFailed. Purchases starts first: it needs nothing else, and receipts for products not yet
-- registered come back later (NotProcessedYet).
local safe = require(Shared:WaitForChild("SafeStart")).new(function(failedList: string)
	workspace:SetAttribute("BootFailed", failedList)
end)
safe("Purchases", function() Purchases.start() end) -- the one ProcessReceipt; finds out whether orders live in a DataStore
-- V8-1.7 (phone diet): with the birds off, their models leave ReplicatedStorage (every client loaded
-- them for nothing); Config.BIRDS on brings them back at the next server start.
safe("BirdModels", function()
	local birds = game:GetService("ReplicatedStorage"):FindFirstChild("BirdModels")
	if birds and not (Config :: any).BIRDS then
		birds.Parent = game:GetService("ServerStorage")
	end
end)

-- Round 5, phase 00: one record per visit (Session_v1) for the first-minute numbers.
safe("AimService", function() require(Systems:WaitForChild("AimService")).start() end) -- the gun follows the mouse, for everyone to see (round 5)
local SessionStats = require(Systems:WaitForChild("SessionStats"))
SessionStats.hasLab = function(player: Player): boolean
	return Lab.plotIndex(player) ~= nil
end
safe("SessionStats", function() SessionStats.start() end)
safe("StuntScore", function() require(Systems:WaitForChild("StuntScore")).start() end) -- V8-1.1: the CRASH score of your own flights
safe("DummySpawn", function() require(Systems:WaitForChild("DummySpawn")).start() end) -- V8-2.5: spawn a dummy of a type where you aim
safe("OutOfBounds", function() require(Systems:WaitForChild("OutOfBounds")).start() end) -- V9-0ab: off any map: home to your lab
safe("ExperimentService", function() require(Systems:WaitForChild("ExperimentService")).start() end) -- phase 1: Experiment cards (Shared\Experiments)
safe("EconomyService", function() require(Systems:WaitForChild("EconomyService")).start() end) -- phase 2: bolts, bone journal, daily experiments, codes
safe("PartyService", function() require(Systems:WaitForChild("PartyService")).start() end) -- phase 3: Prank Party shared experiment cards
safe("FxService", function() FxService.start() end)
safe("VitalsService", function() VitalsService.start() end) -- blood, pulse and wounds (round 2, N2)
safe("DummyControl", function() DummyControl.start() end)
DummyControl.onShatter = FxService.shatter
safe("ToyService", function() ToyService.start() end)
safe("OnboardingService", function() OnboardingService.start() end)
safe("HitService", function() HitService.start() end)
safe("LoadoutStore", function() LoadoutStore.start() end)
safe("HeldService", function() HeldService.start() end)
safe("Lab", function() Lab.build() end)
safe("BuildService", function() BuildService.start() end)
safe("BuildStore", function() BuildStore.start() end)
safe("PlayerRagdoll", function() PlayerRagdoll.start() end)
safe("PlayerGrab", function() require(Systems:WaitForChild("PlayerGrab")).start() end) -- grab and throw other players in the plaza
safe("Playground", function() Playground.build(workspace:GetAttribute("LabOrigin") or Vector3.zero, "Plaza") end) -- the plaza's own
safe("Lab", function() Lab.setPlaygroundBuilder(Playground.build) end) -- and one in every lab once someone owns it
safe("WorldMaps", function() WorldMaps.build(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- the places (before their crowds)
safe("MapActivities", function() require(Systems:WaitForChild("MapActivities")).start(WorldMaps.folder() or workspace) end) -- v3: the open-air maps' launchers
safe("GroundGuard", function() require(Systems:WaitForChild("GroundGuard")).start() end) -- v4 A2: lifts buried bodies onto the ground
safe("NpcCommand", function() require(Systems:WaitForChild("NpcCommand")).start() end) -- v4 B4: talk to NPCs and command them
safe("LabZones", function() require(Systems:WaitForChild("LabZones")).start() end) -- v4 C1: today's machine and NEW tags follow the UTC day
do -- LOOK_V3: grass, hills and trees round the labs (after WorldMaps: it repaints the baseplate)
	local ok, err = pcall(function()
		require(Systems:WaitForChild("Landscape")).build(workspace:GetAttribute("LabOrigin") or Vector3.zero, Lab.PLOT_SPACING, Lab.PLOT_COUNT)
	end)
	if not ok then
		warn("[Landscape] " .. tostring(err))
	end
end
safe("MapShopService", function() require(Systems:WaitForChild("MapShopService")).start(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- V6-7: showcase booths and the map items' effects
safe("ShopModels", function() require(Systems:WaitForChild("ShopModels")).start() end) -- V9-0i: the SHOP's 3D models for the screens
safe("PathBuilder", function() require(Systems:WaitForChild("PathBuilder")).start(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- V7-2: paths on the plaza and the open-air maps
-- A trip to a room counts towards the day's goals (round 3, M9).
WorldMaps.onTrip = function(player: Player, landed: string)
	local place = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Places")).byId[landed]
	if place and place.slot > 0 then
		require(Systems:WaitForChild("ProgressService")).goal(player, "Trips", 1)
	end
end
safe("CrowdService", function() CrowdService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero) end)
safe("ProgressService", function() ProgressService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- takedowns, eggs, hats, the profile
safe("LeaderboardService", function() LeaderboardService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- the plaza's four boards (round 3, M6)
safe("LeaderboardService", function() LeaderboardService.buildLabBoards() end) -- and two in every lab, by the spawn (10 Nov 2026)
safe("ChristmasService", function() ChristmasService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- the Christmas theme (round 3, M7)
safe("AdminService", function() AdminService.start() end) -- the owner's own controls (round 3, M7)
safe("ScheduleService", function() require(Systems:WaitForChild("ScheduleService")).start() end) -- the weekly ADMIN SHOW and the free weekend (round 3, M9)
safe("MinigameService", function() MinigameService.boot(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- the arena games
safe("FriendsService", function() FriendsService.start() end) -- nukes and pranks between friends, PvP switch, friend boost, joining friends
safe("HordeService", function() HordeService.boot(workspace:GetAttribute("LabOrigin") or Vector3.zero) end) -- the co-op horde every 10 minutes
-- (Purchases started first, at the top: V8-0.9.)
safe("EventService", function() EventService.start() end) -- registers its products and claims orders owed from other servers
safe("WeaponShop", function() WeaponShop.start() end) -- weapons for Robux: one product per price tier (round 2, N4)
safe("MoneyService", function() MoneyService.start() end) -- passes, free ULTRA minutes, What's New, admin events
safe("LaunchGift", function() require(Systems:WaitForChild("LaunchGift")).start() end) -- one free weapon egg for everyone while we launch
safe("PlaytimeGifts", function() require(Systems:WaitForChild("PlaytimeGifts")).start() end) -- a weapon egg at 2, 5, 10 and 15 min of play a day
safe("PortalService", function() require(Systems:WaitForChild("PortalService")).start() end) -- portals + the server list (round 5, phase 4)
safe("VisitorService", function() require(Systems:WaitForChild("VisitorService")).start() end) -- a living lab: visitor ragdolls try the things (round 5, phase 3)
safe("ChaseService", function() require(Systems:WaitForChild("ChaseService")).start_() end) -- NPC Chase: a pack runs at a newer player, with a health bar (round 5)
safe("TrialService", function() require(Systems:WaitForChild("TrialService")).start() end) -- TRY FREE: a locked weapon for 2 min, once a day each (round 5)
safe("SandboxService", function() require(Systems:WaitForChild("SandboxService")).start() end) -- SLOW-MO / REVIVE ALL / RESET in your own lab (round 5)
safe("RewardsService", function() require(Systems:WaitForChild("RewardsService")).start() end) -- REWARDS: the group gift and trophies (round 5)
safe("OfferService", function() require(Systems:WaitForChild("OfferService")).start() end) -- release 0.20.0: Shop.OFFERS products and passes (Shared\Offers)
require(Systems:WaitForChild("BadgeAwards")).start() -- badges (ids in Shared/Badges; 0 = not made yet)
safe("Metrics", function() Metrics.start() end) -- counts for the Creator Dashboard (phase Å)
safe("StreamerService", function() StreamerService.start() end) -- Streamer Mode: gift keys set off fun things (private servers, no lasting value)
