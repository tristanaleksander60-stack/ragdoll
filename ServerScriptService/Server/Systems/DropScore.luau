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

-- 3.5 TRAMPOLINE part 1 (Config.BOUNCE_SCORE): landings within 12 studs of the plan's Trampoline less than 3 s apart count
-- as one bounce chain: "BOUNCE x3!" from the second bounce on, and a NEW BEST chain for the lab's owner (BounceBest).
local chain, chainAt = 0, 0
local function bounce(at: Vector3): boolean
	local Lab = lazy("Lab")
	local owner = Lab.ownerAt(at)
	local okT, tramp = pcall(function()
		return (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any).at("Trampoline", Vector2.new(50, 100))
	end)
	if not (owner and okT) then
		return false
	end
	local o = Lab.originFor(owner)
	if Vector3.new(at.X - (o.X + tramp.X), 0, at.Z - (o.Z + tramp.Y)).Magnitude > 12 then
		return false
	end
	local now = os.clock()
	chain = if now - chainAt < 3 then chain + 1 else 1
	chainAt = now
	if chain >= 2 then
		local best = (owner:GetAttribute("BounceBest") :: number?) or 0
		local newBest = chain > best
		if newBest then
			owner:SetAttribute("BounceBest", chain)
		end
		pcall(function()
			lazy("Playground").pop(at, "BOUNCE x" .. chain .. "!" .. (if newBest then " NEW BEST!" else ""), Color3.fromRGB(140, 255, 160))
		end)
	end
	return true
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
		if kind == "Land" and speed >= 14 and (Config :: any).BOUNCE_SCORE then
			local okB, was = pcall(bounce, at)
			if okB and was then
				return
			end
		end
		if kind == "Land" and speed >= 40 then
			task.spawn(heard, at, speed)
		end
	end)
end

return DropScore
