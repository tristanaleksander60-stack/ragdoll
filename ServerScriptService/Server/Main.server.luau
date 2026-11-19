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

-- Round 5, phase 00: one record per visit (Session_v1) for the first-minute numbers.
require(Systems:WaitForChild("AimService")).start() -- the gun follows the mouse, for everyone to see (round 5)
local SessionStats = require(Systems:WaitForChild("SessionStats"))
SessionStats.hasLab = function(player: Player): boolean
	return Lab.plotIndex(player) ~= nil
end
SessionStats.start()
require(Systems:WaitForChild("ExperimentService")).start() -- phase 1: Experiment cards (Shared\Experiments)
require(Systems:WaitForChild("EconomyService")).start() -- phase 2: bolts, bone journal, daily experiments, codes
require(Systems:WaitForChild("PartyService")).start() -- phase 3: Prank Party shared experiment cards
FxService.start()
VitalsService.start() -- blood, pulse and wounds (round 2, N2)
DummyControl.start()
DummyControl.onShatter = FxService.shatter
ToyService.start()
OnboardingService.start()
HitService.start()
LoadoutStore.start()
HeldService.start()
Lab.build()
BuildService.start()
BuildStore.start()
PlayerRagdoll.start()
require(Systems:WaitForChild("PlayerGrab")).start() -- grab and throw other players in the plaza
Playground.build(workspace:GetAttribute("LabOrigin") or Vector3.zero, "Plaza") -- the plaza's own
Lab.setPlaygroundBuilder(Playground.build) -- and one in every lab once someone owns it
WorldMaps.build(workspace:GetAttribute("LabOrigin") or Vector3.zero) -- the places (before their crowds)
require(Systems:WaitForChild("MapActivities")).start(WorldMaps.folder() or workspace) -- v3: the open-air maps' launchers
require(Systems:WaitForChild("GroundGuard")).start() -- v4 A2: lifts buried bodies onto the ground
require(Systems:WaitForChild("NpcCommand")).start() -- v4 B4: talk to NPCs and command them
do -- LOOK_V3: grass, hills and trees round the labs (after WorldMaps: it repaints the baseplate)
	local ok, err = pcall(function()
		require(Systems:WaitForChild("Landscape")).build(workspace:GetAttribute("LabOrigin") or Vector3.zero, Lab.PLOT_SPACING, Lab.PLOT_COUNT)
	end)
	if not ok then
		warn("[Landscape] " .. tostring(err))
	end
end
-- A trip to a room counts towards the day's goals (round 3, M9).
WorldMaps.onTrip = function(player: Player, landed: string)
	local place = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Places")).byId[landed]
	if place and place.slot > 0 then
		require(Systems:WaitForChild("ProgressService")).goal(player, "Trips", 1)
	end
end
CrowdService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero)
ProgressService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero) -- takedowns, eggs, hats, the profile
LeaderboardService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero) -- the plaza's four boards (round 3, M6)
LeaderboardService.buildLabBoards() -- and two in every lab, by the spawn (10 Nov 2026)
ChristmasService.start(workspace:GetAttribute("LabOrigin") or Vector3.zero) -- the Christmas theme (round 3, M7)
AdminService.start() -- the owner's own controls (round 3, M7)
require(Systems:WaitForChild("ScheduleService")).start() -- the weekly ADMIN SHOW and the free weekend (round 3, M9)
MinigameService.boot(workspace:GetAttribute("LabOrigin") or Vector3.zero) -- the arena games
FriendsService.start() -- nukes and pranks between friends, PvP switch, friend boost, joining friends
HordeService.boot(workspace:GetAttribute("LabOrigin") or Vector3.zero) -- the co-op horde every 10 minutes
Purchases.start() -- the one ProcessReceipt; finds out whether orders live in a DataStore
EventService.start() -- registers its products and claims orders owed from other servers
WeaponShop.start() -- weapons for Robux: one product per price tier (round 2, N4)
MoneyService.start() -- passes, free ULTRA minutes, What's New, admin events
require(Systems:WaitForChild("LaunchGift")).start() -- one free weapon egg for everyone while we launch
require(Systems:WaitForChild("PlaytimeGifts")).start() -- a weapon egg at 2, 5, 10 and 15 min of play a day
require(Systems:WaitForChild("PortalService")).start() -- portals + the server list (round 5, phase 4)
require(Systems:WaitForChild("VisitorService")).start() -- a living lab: visitor ragdolls try the things (round 5, phase 3)
require(Systems:WaitForChild("ChaseService")).start_() -- NPC Chase: a pack runs at a newer player, with a health bar (round 5)
require(Systems:WaitForChild("TrialService")).start() -- TRY FREE: a locked weapon for 2 min, once a day each (round 5)
require(Systems:WaitForChild("SandboxService")).start() -- SLOW-MO / REVIVE ALL / RESET in your own lab (round 5)
require(Systems:WaitForChild("RewardsService")).start() -- REWARDS: the group gift and trophies (round 5)
require(Systems:WaitForChild("OfferService")).start() -- release 0.20.0: Shop.OFFERS products and passes (Shared\Offers)
require(Systems:WaitForChild("BadgeAwards")).start() -- badges (ids in Shared/Badges; 0 = not made yet)
Metrics.start() -- counts for the Creator Dashboard (phase Å)
StreamerService.start() -- Streamer Mode: gift keys set off fun things (private servers, no lasting value)
