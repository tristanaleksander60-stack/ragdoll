--!strict
-- A gun pointed at a body (round 3, M3): the nearest player who holds a gun out (their HeldTool,
-- from HeldService, is one of the Toys with gun = true) within a reach of a point and faces it. The
-- same answer on the server and on every screen (characters, their held tools and the server's
-- GunFiredAt note replicate), so the body that simulates a dummy (ActiveRagdoll: a coward runs) and
-- every screen that draws it (DummyLife: hands up, a scared face, eyes on the gun) agree.
--
-- (M3 fix 1) A gun only carried (every player starts with the G17 in hand) is not a gun used: a gun
-- is RAISED for a few seconds after it fires (the server notes GunFiredAt on the character). A
-- coward runs from a raised gun pointed at it, or from one pushed right up to it; a gun only held
-- at it makes the others put their hands up for a while, then they get used to it and only watch
-- it (DummyLife), until it fires again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Toys = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Toys"))
-- (ALWAYS3 update, owner 26 Nov 2026: "Dummies skal ikke være bange for våben i sig selv": Config.FEAR_WEAPONS false = no
-- fleeing, hands up or scared face from a gun held, pointed or fired; they react only when really hit.)
local FEARLESS = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).FEAR_WEAPONS == false

local GunThreat = {}

GunThreat.SCARE_REACH = 14 -- studs: closer than this, a gun scares
GunThreat.RUN_REACH = 9 -- studs: closer than this, a coward runs from a raised gun
GunThreat.CLOSE_RUN = 5 -- studs: closer than this, a coward runs even from a gun only held
GunThreat.AIM_CONE = math.cos(math.rad(40)) -- the holder faces the body within 40 degrees: pointed at it
GunThreat.RAISED_FOR = 6 -- s after a shot that the gun counts as raised
GunThreat.CALM_AFTER = 10 -- s a gun only held at a body before it gets used to it (hands down)

-- The gun a character holds out (its tool id), or nil.
function GunThreat.heldGun(character: Model?): string?
	local held = character and character:FindFirstChild("HeldTool")
	local id = held and held:GetAttribute("Tool")
	if type(id) == "string" then
		local toy = Toys.byId[id]
		if toy and toy.gun then
			return id
		end
	end
	return nil
end

-- Server: this character just fired a gun.
function GunThreat.markFired(character: Model?)
	if character then
		character:SetAttribute("GunFiredAt", Workspace:GetServerTimeNow())
	end
end

-- Whether this character fired a gun in the last RAISED_FOR seconds.
function GunThreat.raised(character: Model?): boolean
	local at = character and character:GetAttribute("GunFiredAt")
	return type(at) == "number" and Workspace:GetServerTimeNow() - at < GunThreat.RAISED_FOR
end

-- Every player holding a gun within `reach` of `position` and facing it (the gun pointed at it, not
-- just carried past): calls `each(head, player, distance, raised)`.
local function eachAimed(position: Vector3, reach: number, each: (Vector3, Player, number, boolean) -> ())
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local head = character and character:FindFirstChild("Head")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if head and head:IsA("BasePart") and root and root:IsA("BasePart") and GunThreat.heldGun(character) then
			local offset = position - head.Position
			local d = offset.Magnitude
			if d < reach then
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local facing = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				if flat.Magnitude < 1 or facing.Magnitude < 0.01 or flat.Unit:Dot(facing.Unit) >= GunThreat.AIM_CONE then
					each(head.Position, p, d, GunThreat.raised(character))
				end
			end
		end
	end
end

-- The head of the nearest player pointing a gun at `position` within `reach`, that player, how far,
-- and whether ANY gun pointed at it within that reach is raised (several players: one fires, the
-- fright is back, whoever is nearest); or nil.
function GunThreat.near(position: Vector3, reach: number): (Vector3?, Player?, number, boolean)
	if FEARLESS then
		return nil, nil, reach, false
	end
	local best: Vector3? = nil
	local bestPlayer: Player? = nil
	local bestDistance = reach
	local anyRaised = false
	eachAimed(position, reach, function(head, p, d, raised)
		anyRaised = anyRaised or raised
		if d < bestDistance then
			best, bestPlayer, bestDistance = head, p, d
		end
	end)
	return best, bestPlayer, bestDistance, anyRaised
end

-- Where a coward at `position` runs from: the nearest gun pointed at it that is raised (within
-- RUN_REACH) or pushed right up to it (within CLOSE_RUN), whoever holds it; or nil.
function GunThreat.cowardRunsFrom(position: Vector3): Vector3?
	if FEARLESS then
		return nil
	end
	local best: Vector3? = nil
	local bestDistance = math.huge
	eachAimed(position, GunThreat.RUN_REACH, function(head, _, d, raised)
		if (raised or d < GunThreat.CLOSE_RUN) and d < bestDistance then
			best, bestDistance = head, d
		end
	end)
	return best
end

return GunThreat
