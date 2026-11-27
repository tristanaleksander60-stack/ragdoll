--!strict
-- 3.2 TOWER part 1 (docs/MACHINES_10.md 3.2 "Score"; Config.DROP_SCORE): a body that lands hard near the TOWER (within
-- REACH studs of the plan's Tower, in a player's lab) shows its fall height where it lands, "64 stud DROP!", from its
-- landing speed (h = v^2 / 2g), and a NEW BEST for the lab's owner (player attribute DropBest). Drops under MIN studs
-- show nothing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DropScore = {}

DropScore.MIN = 20
DropScore.REACH = 60

local lastAt = 0

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function heard(at: Vector3, speed: number)
	local now = os.clock()
	if now - lastAt < 0.8 then
		return
	end
	local h = math.floor(speed * speed / (2 * Workspace.Gravity) + 0.5)
	if h < DropScore.MIN then
		return
	end
	local Lab = lazy("Lab")
	local owner = Lab.ownerAt(at)
	if not owner then
		return
	end
	local okT, tower = pcall(function()
		return (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).at("Tower", Vector2.new(0, 40))
	end)
	if not okT then
		return
	end
	local o = Lab.originFor(owner)
	if Vector3.new(at.X - (o.X + tower.X), 0, at.Z - (o.Z + tower.Y)).Magnitude > DropScore.REACH then
		return
	end
	lastAt = now
	local best = (owner:GetAttribute("DropBest") :: number?) or 0
	local newBest = h > best
	if newBest then
		owner:SetAttribute("DropBest", h)
	end
	pcall(function()
		lazy("Playground").pop(at, tostring(h) .. " stud DROP!" .. (if newBest then "\nNEW BEST!" else ""), if newBest then Color3.fromRGB(255, 220, 80) else Color3.new(1, 1, 1))
	end)
end

function DropScore.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.DROP_SCORE then
		return
	end
	lazy("FxService").onMoment(function(kind: string, at: Vector3, speed: number, _toy: string, _who: number)
		if kind == "Land" and speed >= 40 then
			task.spawn(heard, at, speed)
		end
	end)
end

return DropScore
