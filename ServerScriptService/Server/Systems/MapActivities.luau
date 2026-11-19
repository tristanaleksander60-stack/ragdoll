--!strict
-- v3 phase C (19 Nov 2026): the open-air maps' launchers. OutdoorMaps marks a part with the
-- attribute `Launch` (a world velocity, studs/s) and `What` (its name on screen, "the CATAPULT");
-- a player touching it is thrown ragdoll with that velocity, once per COOLDOWN, with a bang and an
-- experiment event (like the lab's hazards: Playground.throwOnTouch). The server decides: the
-- velocity is the part's own attribute, never the client's. Behind Config.MAP_ACTIVITIES.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local FxService = require(script.Parent.FxService)
local ExperimentService = require(script.Parent.ExperimentService)

local MapActivities = {}

MapActivities.COOLDOWN = 2.5 -- s between two throws of one player by one launcher
MapActivities.MAX_SPEED = 260 -- studs/s: a launcher's speed is capped here (a typo can't fling to the void)
MapActivities.EVENT_GAP = 30 -- s: one experiment event per player per launcher in this time (no farming)

local wired: { [BasePart]: boolean } = {}

-- A lift pad: `TeleportTo` (a world point) puts whoever steps on it there (the top of the throw
-- tower, the crane's jib), once per COOLDOWN. Server-placed points only.
local function wireLift(p: BasePart, to: Vector3)
	local last: { [Player]: number } = {}
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
	p.Touched:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not character or PlayerRagdoll.isDown(player) then
			return
		end
		local now = os.clock()
		if last[player] and now - last[player] < MapActivities.COOLDOWN then
			return
		end
		last[player] = now
		local root = character:FindFirstChild("HumanoidRootPart")
		local look = if root and root:IsA("BasePart") then root.CFrame.LookVector else Vector3.zAxis
		character:PivotTo(CFrame.lookAt(to, to + Vector3.new(look.X, 0, look.Z)))
		FxService.hit(to, 40, "CannonPad")
	end)
end

function MapActivities.wire(p: BasePart)
	if not Config.MAP_ACTIVITIES then
		return
	end
	if wired[p] then
		return
	end
	local lift = p:GetAttribute("TeleportTo")
	if typeof(lift) == "Vector3" then
		wired[p] = true
		wireLift(p, lift)
		return
	end
	local launch = p:GetAttribute("Launch")
	if typeof(launch) ~= "Vector3" then
		return
	end
	wired[p] = true
	local velocity = if launch.Magnitude > MapActivities.MAX_SPEED then launch.Unit * MapActivities.MAX_SPEED else launch
	local what = p:GetAttribute("What")
	local label = if type(what) == "string" then what else "the LAUNCHER"
	local kindAttr = p:GetAttribute("Kind")
	local kind = if type(kindAttr) == "string" then kindAttr else "Map" -- (Experiments: "Map", "Tower")
	local last: { [Player]: number } = {}
	local counted: { [Player]: number } = {}
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
		counted[player] = nil
	end)
	p.Touched:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not character then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end
		local now = os.clock()
		-- (Not while down: a limp body landing back on a straight-up pad would be thrown again and
		-- again. Blind review 19 Nov.)
		if PlayerRagdoll.isDown(player) or (last[player] and now - last[player] < MapActivities.COOLDOWN) then
			return
		end
		last[player] = now
		PlayerRagdoll.launch(player, velocity)
		FxService.hit(root.Position, math.min(velocity.Magnitude, 140), "CannonPad")
		if not counted[player] or now - counted[player] >= MapActivities.EVENT_GAP then
			counted[player] = now
			ExperimentService.event(player, kind, 1, label)
		end
	end)
	p.Destroying:Connect(function()
		wired[p] = nil
	end)
end

-- Every launcher under `root` (WorldMaps' Places folder).
function MapActivities.start(root: Instance)
	if not Config.MAP_ACTIVITIES then
		return
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			MapActivities.wire(d)
		end
	end
end

return MapActivities
