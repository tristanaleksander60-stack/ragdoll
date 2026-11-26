--!strict
-- V9-0ab (owner, 21 Nov 2026: "if you fall out of your map you spawn back in your lab"; Config.OUT_OF_BOUNDS):
-- a player who has left every place, checked on the server every CHECK s, comes home to their own lab
-- (or the lab of the Prank Party they are in), standing, with a puff and a short line. No death screen;
-- tools and progress are kept, and a seated player leaves the seat first.
-- Where a player may be:
--   * on the ground row (the labs and the plaza): from GROUND_DROP studs under the labs' floor up to
--     GROUND_TOP over it (a cannon flight or a launch high over the lab is fine);
--   * over an open-air map (Places outdoor): inside its size plus MAP_MARGIN, from MAP_DROP under its floor
--     up to its height plus MAP_TOP.
-- Anywhere else (fallen under the floor, off a map's edge, launched far away) is out of bounds. Not
-- during Zero-G (low Workspace.Gravity), nor for a player already being sent home.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Places = require(Shared:WaitForChild("Places")) :: any

local OutOfBounds = {}

OutOfBounds.CHECK = 0.5 -- s
OutOfBounds.GROUND_DROP = 40
OutOfBounds.GROUND_TOP = 700
OutOfBounds.MAP_MARGIN = 60
OutOfBounds.MAP_DROP = 40
OutOfBounds.MAP_TOP = 400
OutOfBounds.HOLD = 0.25 -- s the root is held still at home (the fall's speed gone on every screen)

local busy: { [Player]: boolean } = {}

-- Whether a point is inside some place (pure: the labs' origin as given).
function OutOfBounds.inside(at: Vector3, labOrigin: Vector3): boolean
	local dy = at.Y - labOrigin.Y
	if dy > -OutOfBounds.GROUND_DROP and dy < OutOfBounds.GROUND_TOP then
		return true
	end
	for _, place in Places.list do
		if place.slot > 0 then -- (the open-air maps, and a room such as the Game Arena when it is on)
			local floor = Places.floorCenter(labOrigin, place.id)
			if floor then
				local half = place.size / 2
				local d = at - floor
				if math.abs(d.X) < half.X + OutOfBounds.MAP_MARGIN and math.abs(d.Z) < half.Z + OutOfBounds.MAP_MARGIN and d.Y > -OutOfBounds.MAP_DROP and d.Y < place.size.Y + OutOfBounds.MAP_TOP then
					return true
				end
			end
		end
	end
	return false
end

-- Sends a player home now: their lab (or their party's), standing, a puff, a line. True if sent.
function OutOfBounds.sendHome(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or busy[player] then
		return false
	end
	busy[player] = true
	local seatModel = humanoid and humanoid.SeatPart and humanoid.SeatPart:FindFirstAncestorOfClass("Model")
	if seatModel and (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).CAR_STAY then
		-- (F56: a driver is never pulled out of the car: the whole car goes home with them in it)
		local Lab = require(script.Parent:WaitForChild("Lab")) :: any
		local ok, at = pcall(Lab.originFor, player)
		if ok and typeof(at) == "Vector3" then
			seatModel:PivotTo(CFrame.new(at + Vector3.new(0, 6, -40)))
			for _, d in seatModel:GetDescendants() do
				if d:IsA("BasePart") then
					d.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end
		busy[player] = nil
		return true
	end
	if humanoid and humanoid.SeatPart then
		humanoid.Sit = false -- (out of the seat first)
		local weld = humanoid.SeatPart and humanoid.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	local Lab = require(script.Parent:WaitForChild("Lab")) :: any
	local sent = false
	local host = player:GetAttribute("PartyLab")
	local hostPlayer = if type(host) == "number" then Players:GetPlayerByUserId(host) else nil
	if hostPlayer and Lab.plotIndex(hostPlayer) then
		character:PivotTo(CFrame.new(Lab.originFor(hostPlayer) + Vector3.new(0, 4, 0)))
		sent = true
		player:SetAttribute("Place", if hostPlayer == player then "Lab" else Places.labId(Lab.plotIndex(hostPlayer)))
	else
		sent = Lab.sendHome(player)
		if sent then
			player:SetAttribute("Place", "Lab") -- (V9-0e fix round 1: the Map Board and the counts know you are home)
		end
	end
	-- (Its fall is over: no speed carried home. The player's own client simulates the body, so a speed set
	-- here would be overwritten: the root is held anchored a moment, which stops it on every screen.)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	-- (The whole body, not the root alone: a limp body's loose limbs would fall away from a held root.)
	local held: { BasePart } = {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			part.Anchored = true
			table.insert(held, part)
		end
	end
	task.delay(OutOfBounds.HOLD, function()
		for _, part in held do
			if part.Parent then
				part.Anchored = false
			end
		end
	end)
	if sent then
		-- (Home standing: a limp body is told to get up, again for a moment, as getting up is refused in
		-- the first instant of a fall.)
		task.spawn(function()
			local ok, PlayerRagdoll = pcall(function()
				return require(script.Parent:WaitForChild("PlayerRagdoll")) :: any
			end)
			if not ok then
				return
			end
			for _ = 1, 8 do
				if not player.Parent or player.Character ~= character or not PlayerRagdoll.isDown(player) then
					return
				end
				PlayerRagdoll.getUp(player)
				task.wait(0.5)
			end
		end)
		pcall(function()
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				(require(script.Parent:WaitForChild("FxService")) :: any).hit(root.Position, 20, "Shove")
			end
			(require(script.Parent:WaitForChild("ProgressService")) :: any).notice(player, "Back in your lab")
		end)
	end
	task.delay(1, function()
		busy[player] = nil
	end)
	return sent
end

function OutOfBounds.start()
	if not Config.OUT_OF_BOUNDS then
		return
	end
	task.spawn(function()
		while true do
			task.wait(OutOfBounds.CHECK)
			if Workspace.Gravity < 100 then -- (Zero-G, or the owner's low gravity: bodies float high on purpose)
				continue
			end
			local origin = Workspace:GetAttribute("LabOrigin")
			local labOrigin = if typeof(origin) == "Vector3" then origin else Vector3.zero
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") and not busy[player] and not OutOfBounds.inside(root.Position, labOrigin) then
					OutOfBounds.sendHome(player)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return OutOfBounds
