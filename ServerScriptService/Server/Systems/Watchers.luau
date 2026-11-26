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

Watchers.NEAR = 4
Watchers.REACH = 70
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
	return usable(m) and m:GetAttribute("Watch") == nil
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
			if not usable(m) then
				release(m)
				-- the nearest free ragdoll takes the spot
				local best, bestD = nil :: Model?, math.huge
				for _, d in dummies:GetChildren() do
					local pe = d:FindFirstChild("LowerTorso")
					if d:IsA("Model") and pe and pe:IsA("BasePart") and free(d) then
						local dist = (pe.Position - r.w).Magnitude
						if dist < bestD then
							best, bestD = d, dist
						end
					end
				end
				if best then
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

function Watchers.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.MACHINE_WATCHERS or not Config.LAB_OWNERMAP then
		return
	end
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(step)
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
