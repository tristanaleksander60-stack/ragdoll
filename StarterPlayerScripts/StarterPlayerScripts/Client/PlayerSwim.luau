--!strict
-- PlayerSwim (owner 27 Nov late: "Falder man selv ned i akvariet så står man her bare og er stuck, man svømmer ikke selv";
-- Config.PLAYER_SWIM). The aquarium and the other tanks are PART water (an invisible box tagged WaterVolume), so the
-- Humanoid never swims in them and a player stood stuck on the bottom. On this screen (the player owns their own body):
--   * inside a tank: you float and swim: move with the stick/WASD, hold JUMP to rise, let go and you sink slowly;
--   * at the surface, JUMP climbs you out over the nearest side onto the floor outside (no glass wall can trap you);
--   * a safety net: stuck in a tank for 25 s (or on its bottom for 6 s without moving), you are set outside it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local PlayerSwim = {}
PlayerSwim.SWIM_SPEED = 14 -- studs/s sideways in the water
PlayerSwim.RISE = 12 -- studs/s up while JUMP is held
PlayerSwim.SINK = 2.5 -- studs/s down when nothing is held
PlayerSwim.MAX_IN = 25 -- s in a tank before the safety net
PlayerSwim.STUCK_FOR = 6 -- s still on the bottom before the safety net

local player = Players.LocalPlayer
local jumpHeld = false

local function tankOf(at: Vector3): BasePart?
	for _, v in CollectionService:GetTagged("WaterVolume") do
		if v:IsA("BasePart") and v:IsDescendantOf(Workspace) then
			local l = v.CFrame:PointToObjectSpace(at)
			local h = v.Size / 2
			if math.abs(l.X) < h.X and math.abs(l.Z) < h.Z and l.Y < h.Y + 0.5 and l.Y > -h.Y - 3 then
				return v
			end
		end
	end
	return nil
end

-- The floor just outside the tank's nearest side, found from just above (never a roof: CARRY_FLOOR_RAY's lesson).
local function outside(tank: BasePart, root: BasePart, character: Model): CFrame?
	local l = tank.CFrame:PointToObjectSpace(root.Position)
	local h = tank.Size / 2
	local dx, dz = h.X - math.abs(l.X), h.Z - math.abs(l.Z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, tank }
	for _, extra in { 4, 7, 10 } do
		local out = if dx < dz
			then Vector3.new((if l.X >= 0 then 1 else -1) * (h.X + extra), h.Y, l.Z)
			else Vector3.new(l.X, h.Y, (if l.Z >= 0 then 1 else -1) * (h.Z + extra))
		local top = tank.CFrame:PointToWorldSpace(out)
		local hit = Workspace:Raycast(top + Vector3.new(0, 3, 0), Vector3.new(0, -80, 0), params)
		if hit and hit.Normal.Y > 0.7 and not tankOf(hit.Position + Vector3.new(0, 1, 0)) then
			local stand = hit.Position + Vector3.new(0, 3.2, 0)
			local away = Vector3.new(stand.X - tank.Position.X, 0, stand.Z - tank.Position.Z)
			return CFrame.lookAt(stand, stand + (if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis))
		end
	end
	return nil
end

function PlayerSwim.start()
	if not Config.PLAYER_SWIM then
		return
	end
	UserInputService.JumpRequest:Connect(function()
		jumpHeld = true
	end)
	local inSince: number? = nil
	local stillSince: number? = nil
	local lastJumpAt = 0
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA or input.UserInputType == Enum.UserInputType.Touch then
			jumpHeld = false
		end
	end)
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if not (character and root and root:IsA("BasePart") and hum and hum.Health > 0) then
			inSince = nil
			return
		end
		local tank = tankOf(root.Position)
		if not tank or root.Anchored or character:GetAttribute("Ragdolled") == true then
			inSince, stillSince = nil, nil
			return
		end
		local now = os.clock()
		inSince = inSince or now
		if jumpHeld then
			lastJumpAt = now
		end
		local l = tank.CFrame:PointToObjectSpace(root.Position)
		local atTop = l.Y > tank.Size.Y / 2 - 2.5
		-- Out: JUMP at the surface, or the safety net.
		local moving = root.AssemblyLinearVelocity.Magnitude > 1.5
		stillSince = if moving then nil else (stillSince or now)
		if (atTop and now - lastJumpAt < 0.2) or now - (inSince :: number) > PlayerSwim.MAX_IN
			or (stillSince and now - stillSince > PlayerSwim.STUCK_FOR) then
			local cf = outside(tank, root, character)
			if cf then
				character:PivotTo(cf)
				root.AssemblyLinearVelocity = Vector3.zero
				inSince, stillSince, jumpHeld = nil, nil, false
				return
			end
		end
		-- Swim.
		local move = hum.MoveDirection * PlayerSwim.SWIM_SPEED
		local up = if jumpHeld then PlayerSwim.RISE elseif atTop then 0 else -PlayerSwim.SINK
		root.AssemblyLinearVelocity = Vector3.new(move.X, up, move.Z)
		if move.Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(move.X, 0, move.Z))
		end
	end)
end

return PlayerSwim
