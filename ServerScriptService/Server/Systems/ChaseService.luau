--!strict
-- Round 5 (the owner: "NPC Chase" for new players, often): CHASE_MIN..CHASE_MAX dummies in red run
-- into your own lab and go for you. You get a health bar (attributes ChaseHP / ChaseMax on the
-- player, drawn by Client/ChaseHud); every punch takes HIT_DAMAGE, so it takes a lot before you go
-- down. At 0 you ragdoll, and after RESPAWN s you are back at full health. Knock them down with
-- anything: each is a takedown as usual, and clearing them all gives BONUS takedowns. It ends when
-- they are all down, after DURATION s, or when you leave your lab.
--   When: a newer player (under NEW_TAKEDOWNS takedowns) FIRST_AFTER s into a visit, then every
--   EVERY_MIN..EVERY_MAX s; never while a horde, a server event or an arena game runs, never
--   outside your own lab. Your client simulates them (instant reactions, no server cost).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dummies = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Dummies"))

local DummyFactory = require(script.Parent.DummyFactory)
local Lab = require(script.Parent.Lab)
local ProgressService = require(script.Parent.ProgressService)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local EventService = require(script.Parent.EventService)
local MinigameService = require(script.Parent.MinigameService)
local Metrics = require(script.Parent.Metrics)

local ChaseService = {}

ChaseService.CHASE_MIN = 4
ChaseService.CHASE_MAX = 10
ChaseService.MAX_HP = 100
ChaseService.HIT_DAMAGE = 4
ChaseService.HIT_GAP = 0.9 -- s between two punches of one chaser
ChaseService.REACH = 4.5
ChaseService.RESPAWN = 1
ChaseService.DURATION = 50
ChaseService.BONUS = 3
ChaseService.FIRST_AFTER = 90
ChaseService.EVERY_MIN = 360
ChaseService.EVERY_MAX = 480
ChaseService.NEW_TAKEDOWNS = 300

type Chaser = { model: Model, down: boolean, lastHit: number }
type Chase = { player: Player, chasers: { Chaser }, endsAt: number, done: boolean }

local chases: { [Player]: Chase } = {}
local nextAt: { [Player]: number } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function inOwnLab(player: Player): boolean
	local root = rootOf(player)
	local index = Lab.plotIndex(player)
	if not root or not index then
		return false
	end
	local zone, at = Lab.zoneAt(root.Position)
	return zone == "Lab" and at == index
end

local function standing(model: Model): boolean
	local s = model:GetAttribute("RagdollState")
	return s == nil or s == "Standing" or s == "Walking" or s == "Fleeing" or s == "Recovering"
end

local function finish(c: Chase, why: string)
	if c.done then
		return
	end
	c.done = true
	chases[c.player] = nil
	local player = c.player
	player:SetAttribute("ChaseHP", nil)
	player:SetAttribute("ChaseMax", nil)
	player:SetAttribute("ChaseLeft", nil)
	if why == "Cleared" and player.Parent then
		ProgressService.addTakedowns(player, ChaseService.BONUS)
		ProgressService.notice(player, string.format("CHASE CLEARED! +%d takedowns", ChaseService.BONUS))
	elseif player.Parent then
		ProgressService.notice(player, "They gave up the chase!")
	end
	Metrics.event(player, "Chase_" .. why)
	task.delay(3, function()
		for _, ch in c.chasers do
			if ch.model.Parent and ch.model:GetAttribute("Vital") ~= "Dead" then
				ch.model:Destroy()
			end
		end
	end)
end

local function knockedOut(c: Chase)
	local player = c.player
	player:SetAttribute("ChaseHP", 0)
	local root = rootOf(player)
	if root then
		PlayerRagdoll.knock(player, Vector3.new(0, 30, 0))
	end
	ProgressService.notice(player, "KNOCKED OUT! Back in 1 second...")
	task.delay(ChaseService.RESPAWN, function()
		if player.Parent and not c.done then -- (a chase already over: no respawn, no stale health: review fix)
			player:LoadCharacter()
			player:SetAttribute("ChaseHP", ChaseService.MAX_HP)
		end
	end)
end

-- Starts a chase on a player now. Returns it (nil: not now).
function ChaseService.start(player: Player, count: number?): Chase?
	if chases[player] or not inOwnLab(player) then
		return nil
	end
	local n = math.min(count or math.random(ChaseService.CHASE_MIN, ChaseService.CHASE_MAX), EventService.dummyRoom())
	if n < ChaseService.CHASE_MIN and not count then
		return nil
	end
	local root = rootOf(player) :: BasePart
	local c: Chase = { player = player, chasers = {}, endsAt = os.clock() + ChaseService.DURATION, done = false }
	chases[player] = c
	player:SetAttribute("ChaseMax", ChaseService.MAX_HP)
	player:SetAttribute("ChaseHP", ChaseService.MAX_HP)
	player:SetAttribute("ChaseLeft", n)
	ProgressService.notice(player, "\u{26A0}\u{FE0F} NPC CHASE! They're coming for you. Knock them down!")
	local center = Lab.focusFor(player)
	for i = 1, n do
		local angle = (i / n) * math.pi * 2
		local at = center + Vector3.new(math.cos(angle) * 34, 3, math.sin(angle) * 34)
		local model = DummyFactory.spawn(at, root.Position, player)
		model.Name = "Chaser"
		model:SetAttribute("Chaser", player.UserId)
		model:SetAttribute("Role", "Charging")
		model:SetAttribute("Pace", 1.35)
		model:SetAttribute("Personality", "Brave") -- (never runs from a gun)
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") and (string.find(d.Name, "Torso") or string.find(d.Name, "Arm")) then
				d.Color = Color3.fromRGB(210, 40, 50)
			end
		end
		local ch: Chaser = { model = model, down = false, lastHit = 0 }
		table.insert(c.chasers, ch)
		model:GetAttributeChangedSignal("RagdollState"):Connect(function()
			local state = model:GetAttribute("RagdollState")
			if not ch.down and (state == "Ragdoll" or state == "Out") and Dummies.blame(model) == player.UserId then
				ch.down = true
				local left = 0
				for _, other in c.chasers do
					if not other.down then
						left += 1
					end
				end
				player:SetAttribute("ChaseLeft", left)
				if left == 0 then
					finish(c, "Cleared")
				end
			end
		end)
	end
	-- The chase: they keep coming for you, and hit when they reach you.
	task.spawn(function()
		while not c.done do
			task.wait(0.25)
			if not player.Parent then
				finish(c, "Left")
				break
			end
			if os.clock() > c.endsAt then
				finish(c, "Time")
				break
			end
			local r = rootOf(player)
			if not r or not inOwnLab(player) then
				if r and Lab.plotIndex(player) then
					finish(c, "Escaped")
					break
				end
				continue
			end
			local now = os.clock()
			for _, ch in c.chasers do
				local pelvis = ch.model:FindFirstChild("LowerTorso")
				if ch.model.Parent and pelvis and pelvis:IsA("BasePart") then
					if ch.down and standing(ch.model) then
						ch.down = false -- (got up again: still in the chase)
					end
					ch.model:SetAttribute("Home", Vector3.new(r.Position.X, pelvis.Position.Y, r.Position.Z))
					ch.model:SetAttribute("HomeLook", Vector3.new(r.Position.X, pelvis.Position.Y, r.Position.Z))
					local close = (pelvis.Position - r.Position).Magnitude <= ChaseService.REACH
					local hp = (player:GetAttribute("ChaseHP") :: number?) or 0
					if close and standing(ch.model) and now - ch.lastHit >= ChaseService.HIT_GAP and hp > 0 and not PlayerRagdoll.isDown(player) then
						ch.lastHit = now
						hp = math.max(0, hp - ChaseService.HIT_DAMAGE)
						player:SetAttribute("ChaseHP", hp)
						if hp <= 0 then
							knockedOut(c)
						elseif hp % 20 == 0 then
							-- (Now and then a punch throws you: it is a ragdoll game.)
							PlayerRagdoll.knock(player, (r.Position - pelvis.Position).Unit * 35 + Vector3.new(0, 18, 0))
						end
					end
				end
			end
		end
	end)
	return c
end

function ChaseService.current(player: Player): Chase?
	return chases[player]
end
function ChaseService.stopForTest(player: Player)
	local c = chases[player]
	if c then
		finish(c, "Stopped")
	end
end

function ChaseService.start_()
	-- (Never in the self-tests: they set their own scenes.)
	local function testing(): boolean
		return game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true
	end
	Players.PlayerAdded:Connect(function(player)
		nextAt[player] = os.clock() + ChaseService.FIRST_AFTER
	end)
	for _, player in Players:GetPlayers() do
		nextAt[player] = os.clock() + ChaseService.FIRST_AFTER
	end
	Players.PlayerRemoving:Connect(function(player)
		nextAt[player] = nil
		local c = chases[player]
		if c then
			finish(c, "Left")
		end
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			if testing() then
				continue
			end
			local busy = Workspace:GetAttribute("HordeOn") == true or EventService.current() ~= nil or MinigameService.current() ~= nil
			for _, player in Players:GetPlayers() do
				local due = nextAt[player]
				local td = ProgressService.takedownsOf(player)
				if due and os.clock() >= due and not busy and not chases[player] and td ~= nil and td < ChaseService.NEW_TAKEDOWNS then
					if ChaseService.start(player) then
						nextAt[player] = os.clock() + math.random(ChaseService.EVERY_MIN, ChaseService.EVERY_MAX)
					else
						nextAt[player] = os.clock() + 20 -- (not in the lab, or no room: soon again)
					end
				end
			end
		end
	end)
end

return ChaseService
