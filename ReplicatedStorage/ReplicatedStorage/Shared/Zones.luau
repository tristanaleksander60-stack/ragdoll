--!strict
-- Where a point is on the ground (round 3, M1), the same answer on the server and every client: the
-- shared PLAZA in the middle, or lab plot i (odd to the east, even to the west), or up in the rooms
-- (nil). Lab.luau lays the plots out with the same numbers; the plaza's middle is the Workspace's
-- LabOrigin attribute.
--
-- The rules that hang on it: a player's lab is private (only its owner and the friends they invite
-- see it or walk in: Lab, PlotPrivacy), and players can hit each other only in the plaza, where
-- nobody gets hurt (HitService, Blasts).

local Workspace = game:GetService("Workspace")

local Zones = {}

-- (V6-4, Config.LAB_V6: wider plots, 250 = about +50 % area, the new strips are the garden.)
local LAB_V6 = (require(script.Parent:WaitForChild("Config")) :: any).LAB_V6 == true
Zones.PLOT_SPACING = if LAB_V6 then 250 else 170 -- studs between the middles of two neighbouring labs (and the plaza)
Zones.PLOT_HALF = Zones.PLOT_SPACING / 2 -- half a plot's width
Zones.GROUND_TOP = 600 -- higher than this above the floor: up in the rooms
Zones.PLOT_COUNT = 10

local function origin(): Vector3
	local o = Workspace:GetAttribute("LabOrigin")
	return if typeof(o) == "Vector3" then o else Vector3.zero
end

-- 0 for the plaza, the plot's index for a lab, nil up in the rooms. (The open ground beyond the last
-- lab on each side counts with that lab: private like it, never a second plaza.)
function Zones.plotAt(position: Vector3): number?
	local o = origin()
	if position.Y > o.Y + Zones.GROUND_TOP then
		return nil
	end
	local dx = position.X - o.X
	local step = math.floor(math.abs(dx) / Zones.PLOT_SPACING + 0.5)
	if step == 0 then
		return 0
	end
	-- (Odd plots lie east, even ones west: each side has its own last one.)
	step = math.min(step, if dx > 0 then math.ceil(Zones.PLOT_COUNT / 2) else math.floor(Zones.PLOT_COUNT / 2))
	if step == 0 then
		return 0
	end
	return if dx > 0 then step * 2 - 1 else step * 2
end

function Zones.isPlaza(position: Vector3): boolean
	return Zones.plotAt(position) == 0
end

-- The x of the line between the plaza and the plot next to it on this side, and between plots.
-- A plot's middle on the x axis.
function Zones.plotCenterX(index: number): number
	local side = if index % 2 == 1 then 1 else -1
	return math.round(origin().X) + side * math.ceil(index / 2) * Zones.PLOT_SPACING
end

-- The guests a lab's owner let in (the owner Player's "LabGuests" attribute: ",id,id,").
function Zones.isGuest(owner: Instance, userId: number): boolean
	local list = owner:GetAttribute("LabGuests")
	return type(list) == "string" and string.find(list, "," .. tostring(userId) .. ",", 1, true) ~= nil
end

-- The player who owns plot i now (their LabPlot attribute), or nil.
function Zones.ownerOf(index: number): Player?
	for _, p in game:GetService("Players"):GetPlayers() do
		if p:GetAttribute("LabPlot") == index then
			return p
		end
	end
	return nil
end

-- Whether a player may be in plot i (0 or nil: the plaza or the rooms, open to all): its owner and
-- the friends they let in. The one rule the server (Lab.keepOut, HitService, Blasts) and every
-- screen (PlotPrivacy) follow.
function Zones.mayEnter(player: Player, index: number?): boolean
	if index == nil or index == 0 then
		return true
	end
	local owner = Zones.ownerOf(index)
	return owner ~= nil and (owner == player or Zones.isGuest(owner, player.UserId))
end

-- Release 0.20 (Config.PARTY_THROWS, passed in as `partyThrows`): whether `grabber` standing at `a`
-- may grab or throw `target` standing at `b`. Always in the plaza; with partyThrows also inside a lab
-- while a Prank Party runs there, between two of its members (ExperimentService sets their PartyLab
-- attribute to the lab owner's UserId) who both stand in that owner's plot. Server (PlayerGrab) and
-- client (PlayerGrabClient) ask the same question.
function Zones.mayGrab(grabber: Player, target: Player, a: Vector3, b: Vector3, partyThrows: boolean): boolean
	if Zones.isPlaza(a) and Zones.isPlaza(b) then
		return true
	end
	if not partyThrows then
		return false
	end
	local party = grabber:GetAttribute("PartyLab")
	if type(party) ~= "number" or target:GetAttribute("PartyLab") ~= party then
		return false
	end
	local plot = Zones.plotAt(a)
	if plot == nil or plot == 0 or Zones.plotAt(b) ~= plot then
		return false
	end
	local owner = Zones.ownerOf(plot)
	return owner ~= nil and owner.UserId == party
end

-- Whether a player may touch (hit, shoot, place on, blast) what is at a point.
function Zones.mayReach(player: Player, position: Vector3): boolean
	return Zones.mayEnter(player, Zones.plotAt(position))
end

return Zones
