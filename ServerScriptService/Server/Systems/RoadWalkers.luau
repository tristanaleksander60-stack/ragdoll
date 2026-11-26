--!strict
-- OVERVIEW 1c (owner, 26 Nov 2026: "der skal gå ragdolls rundt på vejene derude og snakke med hinanden"; docs/LIFE_IDLE.md
-- section 3; Config.ROAD_WALKERS): groups of 2-3 free lab ragdolls walk the roads side by side (the outer ring of
-- NorthCross, AvenueE, SouthCross and AvenueW, either way round, or up and down the boulevard), at a calm pace. Every
-- 20-40 s a group stops for 6-12 s and chats (bubble lines in turn, looking at each other), then walks on. One says
-- "Hi!" when the player passes close. A walker carries the attribute Watch "Walk" (so the roaming, the watchers and
-- NEVER ZERO leave it alone); a knocked, grabbed or borrowed one simply drops out, and the group fills up again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RoadWalkers = {}

RoadWalkers.GROUPS = 2
RoadWalkers.RESERVE = 4
RoadWalkers.SIZE = Vector2.new(2, 3)
RoadWalkers.PACE = 0.8
RoadWalkers.CHAT_EVERY = Vector2.new(20, 40)
RoadWalkers.CHAT_FOR = Vector2.new(6, 12)
RoadWalkers.SMALL_TALK = {
	"Nice day for it.", "Did you see the T-rex?", "I'm going to the race later.", "My cousin went in the washer once.",
	"Is that the new tower?", "I heard the cannon is fun.", "Have you been to the Fun Fair?", "My legs hurt. Again.",
	"Ha! Good one.", "No way.", "I know, right?", "Let's go see the shark.",
}

type Group = { members: { Model }, route: { Vector2 }, idx: number, dir: number, loop: boolean, mode: string, untilT: number, nextChat: number, lastLine: number, speaker: number }

local RING = { Vector2.new(-30, -150), Vector2.new(190, -150), Vector2.new(412, -150), Vector2.new(412, 55), Vector2.new(412, 260), Vector2.new(190, 260),
	Vector2.new(-30, 260), Vector2.new(-250, 260), Vector2.new(-472, 260), Vector2.new(-472, 55), Vector2.new(-472, -150), Vector2.new(-250, -150) }
-- (M4: the compact plan's walkway ring and spine, when the plan is compact)
local PS = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlanSpot")) :: any
if PS.compact then
	RING = { Vector2.new(-150, -80), Vector2.new(0, -80), Vector2.new(150, -80), Vector2.new(150, 20), Vector2.new(150, 120), Vector2.new(0, 120), Vector2.new(-150, 120), Vector2.new(-150, 20) }
end
local BOULEVARD = { Vector2.new(-30, -262), Vector2.new(-30, -200), Vector2.new(-30, -150), Vector2.new(-30, -100), Vector2.new(-30, -62) }
if PS.compact then
	BOULEVARD = { Vector2.new(0, -115), Vector2.new(0, -80), Vector2.new(0, -45), Vector2.new(0, -10) }
end

local groups: { [Player]: { Group } } = setmetatable({}, { __mode = "k" }) :: any
local lastHi: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function labOrigin(player: Player): Vector3?
	local ok, idx = pcall(function()
		return (require(script.Parent:WaitForChild("Lab")) :: any).plotIndex(player)
	end)
	local root = Workspace:FindFirstChild("Playground")
	local lab = ok and idx and root and root:FindFirstChild("Lab" .. tostring(idx))
	local om = lab and lab:FindFirstChild("OwnerMap")
	local grass = om and om:FindFirstChild("OwnerGrass")
	if not (grass and grass:IsA("BasePart")) then
		return nil
	end
	local c = (require(script.Parent:WaitForChild("LabOwnerMap")) :: any).CENTER :: Vector2
	return Vector3.new(grass.Position.X - c.X, grass.Position.Y + 1.05, grass.Position.Z - c.Y)
end

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function ok(m: Model): boolean
	local st = m:GetAttribute("RagdollState")
	return m.Parent ~= nil and m:GetAttribute("Watch") == "Walk" and m:GetAttribute("Held") ~= true and m:GetAttribute("Vital") ~= "Dead"
		and m:GetAttribute("InMachine") == nil and m:GetAttribute("Role3") == nil and (st == nil or st == "Standing" or st == "Walking")
end

local function nearAPlayer(m: Model): boolean
	-- (OVERVIEW 0.15: within 35 studs of a player it belongs to the 3 near them)
	local pe = m:FindFirstChild("LowerTorso")
	if pe and pe:IsA("BasePart") then
		for _, p in Players:GetPlayers() do
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if r and r:IsA("BasePart") and (r.Position - pe.Position).Magnitude < 35 then
				return true
			end
		end
	end
	return false
end

local function free(m: Model): boolean
	local st = m:GetAttribute("RagdollState")
	return not nearAPlayer(m) and m:GetAttribute("Watch") == nil and m:GetAttribute("Held") ~= true and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("TryFor") == nil
		and m:GetAttribute("InMachine") == nil and m:GetAttribute("Role3") == nil and m:GetAttribute("MachineHidden") == nil
		and (st == nil or st == "Standing" or st == "Walking")
end

local function letGo(m: Model)
	if m.Parent and m:GetAttribute("Watch") == "Walk" then
		m:SetAttribute("Watch", nil)
		m:SetAttribute("HomeLook", nil)
		m:SetAttribute("Pace", nil)
	end
end

local function say(m: Model, line: string)
	m:SetAttribute("MoodSay", line)
	task.delay(2.8, function()
		if m.Parent and m:GetAttribute("MoodSay") == line then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

local function world(o: Vector3, v: Vector2): Vector3
	return Vector3.new(o.X + v.X, o.Y, o.Z + v.Y)
end

local function newGroup(o: Vector3, dummies: Instance, plot: number?): Group?
	-- the first free one, then its nearest free neighbours
	local pool = {}
	for _, d in dummies:GetChildren() do
		if d:IsA("Model") and pelvisOf(d) and free(d) and (plot == nil or d:GetAttribute("Plot") == plot) then
			table.insert(pool, d)
		end
	end
	if #pool < 2 + RoadWalkers.RESERVE then
		return nil -- (OVERVIEW 0.15: always keep RESERVE free ones for the 3 near the player)
	end
	local lead = pool[math.random(1, #pool)]
	local lp = (pelvisOf(lead) :: BasePart).Position
	table.sort(pool, function(a, b)
		return ((pelvisOf(a) :: BasePart).Position - lp).Magnitude < ((pelvisOf(b) :: BasePart).Position - lp).Magnitude
	end)
	local n = math.min(#pool, math.random(RoadWalkers.SIZE.X, RoadWalkers.SIZE.Y))
	local members = {}
	for i = 1, n do
		table.insert(members, pool[i])
		pool[i]:SetAttribute("Watch", "Walk")
		pool[i]:SetAttribute("Pace", RoadWalkers.PACE)
	end
	local ring = math.random() < 0.75
	local route = if ring then RING else BOULEVARD
	-- start at the route point nearest the leader
	local best, bestD = 1, math.huge
	for i, v in route do
		local d = (world(o, v) - lp).Magnitude
		if d < bestD then
			best, bestD = i, d
		end
	end
	return { members = members, route = route, idx = best, dir = if math.random() < 0.5 then 1 else -1, loop = ring, mode = "walk",
		untilT = 0, nextChat = os.clock() + math.random(RoadWalkers.CHAT_EVERY.X, RoadWalkers.CHAT_EVERY.Y), lastLine = 0, speaker = 1 }
end

local function stepGroup(g: Group, o: Vector3, root: BasePart?, player: Player)
	-- drop the ones that are gone or busy
	for i = #g.members, 1, -1 do
		if not ok(g.members[i]) then
			letGo(g.members[i])
			table.remove(g.members, i)
		end
	end
	if #g.members < 2 then
		for _, m in g.members do
			letGo(m)
		end
		g.members = {}
		return
	end
	local now = os.clock()
	local lead = pelvisOf(g.members[1])
	if not lead then
		return
	end
	if g.mode == "walk" then
		local target = world(o, g.route[g.idx])
		if (Vector3.new(lead.Position.X, 0, lead.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < 6 then
			local nxt = g.idx + g.dir
			if nxt < 1 or nxt > #g.route then
				if g.loop then
					nxt = if nxt < 1 then #g.route else 1
				else
					g.dir = -g.dir
					nxt = g.idx + g.dir
				end
			end
			g.idx = nxt
			target = world(o, g.route[g.idx])
		end
		local along = Vector3.new(target.X - lead.Position.X, 0, target.Z - lead.Position.Z)
		local side = if along.Magnitude > 0.1 then Vector3.new(-along.Z, 0, along.X).Unit else Vector3.xAxis
		for i, m in g.members do
			local off = (i - (#g.members + 1) / 2) * 3.2 -- (side by side)
			m:SetAttribute("Home", target + side * off)
			m:SetAttribute("HomeLook", nil)
		end
		if now >= g.nextChat then
			g.mode = "chat"
			g.untilT = now + math.random(RoadWalkers.CHAT_FOR.X, RoadWalkers.CHAT_FOR.Y)
			-- stop where they are, in a little circle, looking at its middle
			local mid = Vector3.zero
			for _, m in g.members do
				mid += (pelvisOf(m) :: BasePart).Position
			end
			mid /= #g.members
			for i, m in g.members do
				local a = i / #g.members * math.pi * 2
				local spot = Vector3.new(mid.X + math.cos(a) * 2.4, o.Y, mid.Z + math.sin(a) * 2.4)
				m:SetAttribute("Home", spot)
				m:SetAttribute("HomeLook", Vector3.new(mid.X, o.Y, mid.Z))
			end
		end
	else -- chat
		if now - g.lastLine > 3 then
			g.lastLine = now
			g.speaker = g.speaker % #g.members + 1
			say(g.members[g.speaker], RoadWalkers.SMALL_TALK[math.random(1, #RoadWalkers.SMALL_TALK)])
		end
		if now >= g.untilT then
			g.mode = "walk"
			g.nextChat = now + math.random(RoadWalkers.CHAT_EVERY.X, RoadWalkers.CHAT_EVERY.Y)
		end
	end
	-- "Hi!" when the player passes close
	if root and now - (lastHi[player] or 0) > 10 then
		for _, m in g.members do
			local pe = pelvisOf(m)
			if pe and (pe.Position - root.Position).Magnitude < 9 then
				lastHi[player] = now
				say(m, "Hi!")
				break
			end
		end
	end
end

function RoadWalkers.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.ROAD_WALKERS or not Config.LAB_OWNERMAP then
		return
	end
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(function()
				local dummies = Workspace:FindFirstChild("Dummies")
				if not dummies then
					return
				end
				for _, player in Players:GetPlayers() do
					local o = labOrigin(player)
					if not o then
						continue
					end
					local list = groups[player] or {}
					groups[player] = list
					for i = #list, 1, -1 do
						if #list[i].members == 0 then
							table.remove(list, i)
						end
					end
					if #list < RoadWalkers.GROUPS then
						local plotIdx = (require(script.Parent:WaitForChild("Lab")) :: any).plotIndex(player)
						local g = newGroup(o, dummies, plotIdx)
						if g then
							table.insert(list, g)
						end
					end
					local char = player.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					for _, g in list do
						stepGroup(g, o, if root and root:IsA("BasePart") then root else nil, player)
					end
				end
			end)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		for _, g in groups[p] or {} do
			for _, m in g.members do
				letGo(m)
			end
		end
		groups[p] = nil
	end)
end

return RoadWalkers
