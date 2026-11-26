--!strict
-- OVERVIEW 0.7 (owner, 26 Nov 2026: "ragdolls at EVERY machine"; docs/ALWAYS3.md "Spectators at every machine";
-- Config.MACHINE_WATCHERS): every attraction has a watcher. The real ones: the NEAR attractions closest to a player
-- (within REACH studs) each get a real lab ragdoll that walks to its spot (Shared/WatchSpots) and stands looking at the
-- machine (attribute Watch, so the roaming leaves it alone); it says a line when the player comes close (one every
-- LINE_GAP s); if it is knocked out, used, held or called away, another free one takes the spot within about 10 s. The
-- rest of the attractions show a light stand-in on the player's own screen (Client/WatcherStandIns); the player
-- attribute WatchedIds lists the spots that have a real one, so the stand-in steps aside there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Watchers = {}

Watchers.NEAR = 3
Watchers.KEEP_FREE = 4 -- (OVERVIEW 0.15: a watcher is only taken while this many free ones stay for the 3 near the player)
Watchers.REACH = 90 -- (F45: no stand-ins any more, so real watchers come a little further out)
Watchers.LINE_GAP = 6
Watchers.LINES = { "Have you tried it?", "Go on, press it.", "I'm not going in there.", "I've seen things.", "It's my turn next. Maybe.", "Did you see that one fly?" }

local assigned: { [Player]: { [string]: Model } } = setmetatable({}, { __mode = "k" }) :: any
local lastLine: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function labOrigin(player: Player): Vector3?
	local ok, idx = pcall(function()
		return (require(script.Parent:WaitForChild("Lab")) :: any).plotIndex(player)
	end)
	local root = Workspace:FindFirstChild("Playground")
	local lab = ok and idx and root and root:FindFirstChild("Lab" .. tostring(idx))
	local grass = lab and lab:FindFirstChild("OwnerMap") and lab.OwnerMap:FindFirstChild("OwnerGrass")
	if not (grass and grass:IsA("BasePart")) then
		return nil
	end
	local LabOwnerMap = require(script.Parent:WaitForChild("LabOwnerMap")) :: any
	local c = LabOwnerMap.CENTER :: Vector2
	return Vector3.new(grass.Position.X - c.X, grass.Position.Y + 1.05, grass.Position.Z - c.Y)
end

local function usable(m: Model?): boolean
	if not m or not m.Parent then
		return false
	end
	local state = m:GetAttribute("RagdollState")
	return m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("Held") ~= true and m:GetAttribute("TryFor") == nil and m:GetAttribute("Role3") == nil
		and m:GetAttribute("MachineHidden") ~= true and (state == nil or state == "Standing" or state == "Walking")
end

local function free(m: Model): boolean
	if not (usable(m) and m:GetAttribute("Watch") == nil) then
		return false
	end
	-- (OVERVIEW 0.15: one within 35 studs of a player belongs to the 3 near them; never taken away to a machine)
	local pe = m:FindFirstChild("LowerTorso")
	if pe and pe:IsA("BasePart") then
		for _, p in Players:GetPlayers() do
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if r and r:IsA("BasePart") and (r.Position - pe.Position).Magnitude < 35 then
				return false
			end
		end
	end
	return true
end

local function release(m: Model?)
	if m and m.Parent and m:GetAttribute("Watch") ~= nil then
		m:SetAttribute("Watch", nil)
		m:SetAttribute("HomeLook", nil)
		m:SetAttribute("Pace", nil)
	end
end

local function step()
	local WatchSpots = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WatchSpots")) :: any
	local dummies = Workspace:FindFirstChild("Dummies")
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local o = labOrigin(player)
		local mine = assigned[player] or {}
		assigned[player] = mine
		if not (root and root:IsA("BasePart") and o and dummies) then
			continue
		end
		-- the NEAR closest spots within REACH
		local ranked = {}
		for _, s in WatchSpots.LIST do
			local w = Vector3.new(o.X + s.at.X, o.Y, o.Z + s.at.Y)
			local d = (Vector3.new(w.X, 0, w.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
			if d < Watchers.REACH then
				table.insert(ranked, { s = s, w = w, d = d })
			end
		end
		table.sort(ranked, function(a, b)
			return a.d < b.d
		end)
		local want: { [string]: boolean } = {}
		for i = 1, math.min(Watchers.NEAR, #ranked) do
			local r = ranked[i]
			want[r.s.id] = true
			local m = mine[r.s.id]
			if not usable(m) or (m :: Model):GetAttribute("Watch") ~= r.s.id then
				release(m)
				-- the nearest free ragdoll takes the spot
				local best, bestD = nil :: Model?, math.huge
				local freeCount = 0
				for _, d in dummies:GetChildren() do
					if d:IsA("Model") and usable(d) and d:GetAttribute("Watch") == nil then
						freeCount += 1
					end
				end
				for _, d in dummies:GetChildren() do
					local pe = d:FindFirstChild("LowerTorso")
					if d:IsA("Model") and pe and pe:IsA("BasePart") and free(d) then
						local dist = (pe.Position - r.w).Magnitude
						if dist < bestD then
							best, bestD = d, dist
						end
					end
				end
				if best and freeCount > Watchers.KEEP_FREE then
					mine[r.s.id] = best
					best:SetAttribute("Watch", r.s.id)
					best:SetAttribute("Home", r.w)
					best:SetAttribute("HomeLook", Vector3.new(o.X + r.s.look.X, o.Y, o.Z + r.s.look.Y))
					best:SetAttribute("Pace", 1.8)
				else
					mine[r.s.id] = nil
				end
			end
			-- a line when the player is close to it
			local w = mine[r.s.id]
			local wp = w and w:FindFirstChild("LowerTorso")
			if w and wp and wp:IsA("BasePart") and (wp.Position - root.Position).Magnitude < 14 and os.clock() - (lastLine[player] or 0) > Watchers.LINE_GAP then
				lastLine[player] = os.clock()
				local line = Watchers.LINES[math.random(1, #Watchers.LINES)]
				w:SetAttribute("MoodSay", line)
				task.delay(3, function()
					if w.Parent and w:GetAttribute("MoodSay") == line then
						w:SetAttribute("MoodSay", nil)
					end
				end)
			end
		end
		-- the ones no longer near go back to roaming
		local ids = {}
		for id, m in mine do
			if not want[id] then
				release(m)
				mine[id] = nil
			elseif m then
				table.insert(ids, id)
			end
		end
		player:SetAttribute("WatchedIds", table.concat(ids, ","))
	end
end

-- OVERVIEW 0.8 NEVER ZERO (docs/ALWAYS3.md, Config.NEVER_ZERO): if a player has no living ragdoll within ZERO_RANGE studs for
-- ZERO_WAIT s, the nearest free one comes RUNNING (Pace 2.4) to a spot beside the player; it is let go to roam once it is
-- there (or after 15 s). Not while the player sits (a car, the bike, a seat).
Watchers.ZERO_RANGE = 35
Watchers.ZERO_WAIT = 1
local emptySince: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
local runner: { [Player]: { m: Model, since: number } } = setmetatable({}, { __mode = "k" }) :: any
local function neverZero()
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (root and root:IsA("BasePart") and hum) or hum.SeatPart ~= nil then
			emptySince[player] = nil
			continue
		end
		-- the runner on its way: let it go when it is there
		local r = runner[player]
		if r then
			local pe = r.m:FindFirstChild("LowerTorso")
			if not r.m.Parent or not pe or not pe:IsA("BasePart") or (pe.Position - root.Position).Magnitude < 8 or (pe.Position - root.Position).Magnitude > 160 or now - r.since > 15 then
				if r.m.Parent and r.m:GetAttribute("Watch") == "NeverZero" then
					release(r.m)
				end
				runner[player] = nil
			end
		end
		local near = 0
		local best, bestD = nil :: Model?, math.huge
		for _, d in dummies:GetChildren() do
			local pe = d:FindFirstChild("LowerTorso")
			if d:IsA("Model") and pe and pe:IsA("BasePart") and d:GetAttribute("Vital") ~= "Dead" then
				local dist = (pe.Position - root.Position).Magnitude
				if dist < Watchers.ZERO_RANGE then
					near += 1
				elseif free(d) and dist < bestD then
					best, bestD = d, dist
				end
			end
		end
		if near > 0 then
			emptySince[player] = nil
		else
			emptySince[player] = emptySince[player] or now
			if now - (emptySince[player] :: number) >= Watchers.ZERO_WAIT and not runner[player] and best then
				best:SetAttribute("Watch", "NeverZero")
				-- (Too far to run: over 150 studs it is not even streamed in on the player's screen. It is set down out of view,
				-- about 55 studs behind the player, and runs in from there.)
				if bestD > 150 then
					local back = -root.CFrame.LookVector * Vector3.new(1, 0, 1)
					local at = root.Position + (if back.Magnitude > 0.1 then back.Unit else Vector3.zAxis) * 55
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = { dummies, char :: Instance }
					local hit = Workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), params)
					if hit then
						local DummyControl = require(script.Parent:WaitForChild("DummyControl")) :: any
						local p = hit.Position + Vector3.new(0, 3.2, 0)
						pcall(DummyControl.move, best, CFrame.lookAt(p, Vector3.new(root.Position.X, p.Y, root.Position.Z)))
					end
				end
				best:SetAttribute("Home", root.Position + root.CFrame.RightVector * 4 + root.CFrame.LookVector * 3)
				best:SetAttribute("HomeLook", root.Position)
				best:SetAttribute("Pace", 2.4)
				runner[player] = { m = best, since = now }
			end
		end
	end
end

function Watchers.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.MACHINE_WATCHERS or not Config.LAB_OWNERMAP then
		return
	end
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(0.5)
			tick += 1
			if Config.NEVER_ZERO then
				pcall(neverZero)
			end
			if tick % 2 == 0 then
				pcall(step)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		for _, m in assigned[p] or {} do
			release(m)
		end
		assigned[p] = nil
	end)
end

return Watchers
