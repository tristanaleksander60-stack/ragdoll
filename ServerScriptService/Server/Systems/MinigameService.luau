--!strict
-- The arena games (phase F), played against the NPCs in the Game Arena:
--
-- RED LIGHT, GREEN LIGHT: runners walk from the start line towards you. On green they go, on
-- yellow they get ready, on red they must freeze, but a few sneak on. You are the guard: knock down
-- the ones that move on red (+100), never one standing still (-50) or anyone on green (-25). A
-- runner that crosses the red line costs a life; three and it is over. 60 seconds.
--
-- SHOOT 'EM: people stroll across the far half of the arena; knock them down for 10 points times
-- your combo (another within 2 s raises it, up to x5). 45 seconds.
--
-- One game at a time, started by standing on its button (a ProximityPrompt: E on a keyboard, a
-- tap on a phone). Only the host's knock-downs score (the server's blame on the body); everyone in
-- the arena sees the game bar. Your best score is kept in your profile (ProgressService), and the
-- knock-downs are takedowns like any other.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local Places = require(Shared:WaitForChild("Places"))
local Dummies = require(Shared:WaitForChild("Dummies"))

local DummyFactory = require(script.Parent.DummyFactory)
local ProgressService = require(script.Parent.ProgressService)
local Metrics = require(script.Parent.Metrics)
local WorldMaps = require(script.Parent.WorldMaps)

local log = Log.new("Games")

local MinigameService = {}

MinigameService.RLGL = {
	duration = 60,
	runners = 8,
	lives = 5, -- (3 with 30% sneaking ended the round at 35 s with no catches; PC play test 20 Nov)
	green = { 2.5, 4.5 }, -- s
	yellow = 0.9,
	red = { 2.2, 3.6 },
	sneak = 0.12, -- of the runners, each red, keep walking (0.3: two or three cheaters every red)
	caught = 100,
	wrongRed = -50,
	wrongGreen = -25,
	pace = 0.55, -- (1.1 crossed the arena in two greens: the round ended in 12 s, PC play test 20 Nov)
	respawnAfter = 1.5, -- s: a runner through the line is replaced at the start (the round lasts its minute)
}
MinigameService.SHOOT = {
	duration = 45,
	alive = 5,
	points = 10,
	comboGap = 2, -- s
	comboMax = 5,
}
local START_Z = 56 -- the start line, from the arena's middle
local FINISH_Z = -40 -- the red line
local COOLDOWN = 3 -- s between games
local TICK = 0.1

type Runner = { model: Model, sneaking: boolean, done: boolean, laneX: number, moving: boolean?, cheated: boolean?, replaced: boolean? }
type Session = {
	game: string,
	host: Player,
	endsAt: number,
	score: number,
	lives: number,
	light: string,
	lightUntil: number,
	combo: number,
	lastHitAt: number,
	runners: { Runner },
	ended: boolean,
	hits: number,
	pending: number?, -- RLGL: runners waiting to be replaced
}

local remote: RemoteEvent
local centre = Vector3.zero
local session: Session? = nil
local cooldownUntil = 0
local rng = Random.new()
local lamps: { [string]: BasePart } = {}

local LAMP_ON = {
	Red = Color3.fromRGB(255, 50, 60),
	Yellow = Color3.fromRGB(255, 205, 40),
	Green = Color3.fromRGB(60, 230, 110),
}
local LAMP_OFF = Color3.fromRGB(51, 51, 56)

local function inArena(player: Player): boolean
	return player:GetAttribute("Place") == "Arena"
end

local function audience(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if inArena(player) then
			table.insert(list, player)
		end
	end
	return list
end

local function tell(kind: string, data: { [string]: any })
	for _, player in audience() do
		remote:FireClient(player, kind, data)
	end
end

local function stateOf(s: Session): { [string]: any }
	return {
		game = s.game,
		host = s.host.DisplayName,
		hostId = s.host.UserId,
		endsAt = s.endsAt,
		score = s.score,
		lives = s.lives,
		light = s.light,
		combo = s.combo,
	}
end

local function setLight(s: Session, light: string, seconds: number)
	s.light = light
	s.lightUntil = os.clock() + seconds
	for name, part in lamps do
		local on = name == light
		part.Color = if on then LAMP_ON[name] else LAMP_OFF
		part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
	tell("State", stateOf(s))
end

local function pelvisOf(model: Model): BasePart?
	local p = model:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function goTo(model: Model, spot: Vector3, facing: Vector3)
	local pelvis = pelvisOf(model)
	local y = if pelvis then pelvis.Position.Y else spot.Y
	model:SetAttribute("Home", Vector3.new(spot.X, y, spot.Z))
	model:SetAttribute("HomeLook", Vector3.new(facing.X, y, facing.Z))
end

local SHIRTS = { Color3.fromRGB(40, 160, 130), Color3.fromRGB(230, 90, 120), Color3.fromRGB(80, 120, 220), Color3.fromRGB(240, 180, 40) }

local function spawnNpc(at: Vector3, facing: Vector3, number: number?): Model
	local model = DummyFactory.spawn(at, facing)
	model.Name = "Player" .. (number or 0)
	model:SetAttribute("Minigame", true)
	-- A tracksuit with a number: a runner, not a test dummy.
	local shirt = SHIRTS[(number or rng:NextInteger(1, 4)) % #SHIRTS + 1]
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") then
			if string.find(d.Name, "Torso") or string.find(d.Name, "Arm") or string.find(d.Name, "Leg") then
				d.Color = shirt
			elseif d.Name == "Head" or string.find(d.Name, "Hand") then
				d.Color = Color3.fromRGB(234, 190, 140)
			elseif string.find(d.Name, "Foot") then
				d.Color = Color3.fromRGB(245, 245, 245)
			end
		end
	end
	if number then
		model:SetAttribute("PersonName", string.format("%03d", number))
		model:SetAttribute("Role", "Runner")
	else
		model:SetAttribute("PersonName", "Target")
		model:SetAttribute("Role", "Shoot 'em")
	end
	return model
end

local function pop(text: string, good: boolean)
	tell("Pop", { text = text, good = good })
end

-- Round 4, M10: up to MAX_DEAD_KEPT dead runners lie their whole DEAD_HOLD (VitalsService takes
-- them); the rest, and every living one, go now (no pile of ragdolls).
local MAX_DEAD_KEPT = 6
MinigameService.MAX_DEAD_KEPT = MAX_DEAD_KEPT
local keptDead: { [Model]: boolean } = {}

local function clearAway(model: Model)
	if not model.Parent or keptDead[model] then
		return
	end
	local kept = 0
	for _ in keptDead do
		kept += 1
	end
	if model:GetAttribute("Vital") == "Dead" and kept < MAX_DEAD_KEPT then
		keptDead[model] = true
		model.Destroying:Once(function()
			keptDead[model] = nil
		end)
		return
	end
	model:Destroy()
end

local function finish(s: Session, why: string)
	if s.ended then
		return
	end
	s.ended = true
	session = nil
	cooldownUntil = os.clock() + COOLDOWN
	for _, part in lamps do
		part.Color = LAMP_OFF
		part.Material = Enum.Material.SmoothPlastic
	end
	local score = math.max(0, s.score)
	local newBest = s.host.Parent ~= nil and ProgressService.setBest(s.host, s.game, score)
	if s.host.Parent ~= nil and why ~= "The player left" then
		ProgressService.goal(s.host, "Arena", 1) -- (a round played to its end: the daily goals; walking out never counts)
	end
	tell("End", { game = s.game, host = s.host.DisplayName, hostId = s.host.UserId, score = score, best = ProgressService.best(s.host, s.game), newBest = newBest, why = why })
	-- The runners and targets leave a moment later (the last fall plays out; the dead: clearAway).
	task.delay(2.5, function()
		for _, r in s.runners do
			clearAway(r.model)
		end
	end)
	log.info(string.format("%s by %s: %d (%s)", s.game, s.host.Name, score, why))
	Metrics.event(s.host, "Game_" .. s.game, score)
end

-- A body in the game went down: who knocked it, and was it right?
local function onDown(s: Session, runner: Runner)
	if s.ended or runner.done then
		return
	end
	-- Only the host's own knock-downs, fresh, play: anyone else's (or an old blame) changes nothing
	-- and the runner gets up and carries on (nobody can end someone's round by knocking them all).
	local who, at = Dummies.blame(runner.model)
	if who ~= s.host.UserId or Workspace:GetServerTimeNow() - at > Dummies.BLAME_TIME then
		return
	end
	runner.done = true
	-- A body that is down is out of the game: gone a moment later (a few dead ones stay: clearAway).
	task.delay(if s.game == "Shoot" then 2.5 else 4, clearAway, runner.model)
	s.hits += 1
	if s.game == "RLGL" then
		local cfg = MinigameService.RLGL
		if s.light == "Green" or s.light == "Yellow" then
			-- (On yellow they are still allowed to move: only red catches.)
			s.score += cfg.wrongGreen
			pop(string.format("%d  Only on RED!", cfg.wrongGreen), false)
		elseif runner.sneaking then
			s.score += cfg.caught
			pop(string.format("+%d  CAUGHT!", cfg.caught), true)
		else
			s.score += cfg.wrongRed
			pop(string.format("%d  They stood still!", cfg.wrongRed), false)
		end
	else
		local cfg = MinigameService.SHOOT
		local now = os.clock()
		s.combo = if now - s.lastHitAt <= cfg.comboGap then math.min(cfg.comboMax, s.combo + 1) else 1
		s.lastHitAt = now
		local points = cfg.points * s.combo
		s.score += points
		pop(if s.combo > 1 then string.format("+%d  COMBO x%d", points, s.combo) else string.format("+%d", points), true)
	end
	tell("State", stateOf(s))
end

local function watchRunner(s: Session, runner: Runner)
	runner.model:GetAttributeChangedSignal("RagdollState"):Connect(function()
		local state = runner.model:GetAttribute("RagdollState")
		if state == "Ragdoll" or state == "Out" then
			onDown(s, runner)
		end
	end)
end

local function addRunner(s: Session, at: Vector3, facing: Vector3, number: number?): Runner
	local model = spawnNpc(at, facing, number)
	model:SetAttribute("GameHost", s.host.UserId) -- (a takedown here is the host's only: ProgressService)
	local runner: Runner = { model = model, sneaking = false, done = false, laneX = at.X - centre.X }
	table.insert(s.runners, runner)
	watchRunner(s, runner)
	return runner
end

------------------------------------------------------------------------------------------------
-- The games

local function startRLGL(s: Session)
	local cfg = MinigameService.RLGL
	for i = 1, cfg.runners do
		local x = (i - (cfg.runners + 1) / 2) * 9
		local at = centre + Vector3.new(x, 0, START_Z)
		local runner = addRunner(s, at, at - Vector3.zAxis, 100 + rng:NextInteger(1, 899))
		runner.model:SetAttribute("Pace", cfg.pace)
	end
	setLight(s, "Red", 2) -- a beat to get ready
end

local function stepRLGL(s: Session, now: number)
	local cfg = MinigameService.RLGL
	if now >= s.lightUntil then
		if s.light == "Green" then
			setLight(s, "Yellow", cfg.yellow)
		elseif s.light == "Yellow" then
			-- Red: the honest freeze, a few sneak on.
			for _, r in s.runners do
				r.sneaking = not r.done and rng:NextNumber() < cfg.sneak
				if r.sneaking then
					r.cheated = true -- (moved on red: it may not get through)
				end
			end
			setLight(s, "Red", rng:NextNumber(cfg.red[1], cfg.red[2]))
		else
			for _, r in s.runners do
				r.sneaking = false
			end
			setLight(s, "Green", rng:NextNumber(cfg.green[1], cfg.green[2]))
		end
	end
	local alive = 0
	for _, r in s.runners do
		local pelvis = pelvisOf(r.model)
		if not r.done and r.model.Parent and pelvis then
			alive += 1
			local z = pelvis.Position.Z - centre.Z
			if z < FINISH_Z then
				r.done = true
				-- (PC play test 20 Nov: every runner through cost a life, honest ones too, so the round
				-- could not be won. Only a cheater, one that moved on RED, costs a life now; an honest
				-- one is safe home. Either way a fresh runner starts in its lane.)
				if r.cheated then
					s.lives -= 1
					pop("A cheater got past you!", false)
				else
					pop("Safe! (they played fair)", true)
				end
				tell("State", stateOf(s))
				goTo(r.model, centre + Vector3.new(r.laneX, 0, FINISH_Z - 10), centre + Vector3.new(r.laneX, 0, FINISH_Z - 20))
				task.delay(cfg.respawnAfter + 1, clearAway, r.model)
			else
				local moving = s.light == "Green" or s.light == "Yellow" or r.sneaking
				local state = r.model:GetAttribute("RagdollState")
				-- (Home is only rewritten when the plan changes: go, or freeze where it stands.)
				if (state == "Standing" or state == "Walking") and r.moving ~= moving then
					r.moving = moving
					if moving then
						goTo(r.model, centre + Vector3.new(r.laneX, 0, FINISH_Z - 6), centre + Vector3.new(r.laneX, 0, FINISH_Z - 20))
					else
						goTo(r.model, pelvis.Position, pelvis.Position - Vector3.zAxis)
					end
				elseif state ~= "Standing" and state ~= "Walking" then
					r.moving = nil -- knocked about: plan again once up
				end
			end
		end
	end
	-- A runner that is out (caught, or through the line) is replaced in its lane after a beat, so
	-- the round lasts its minute (not in its last seconds).
	for _, r in s.runners do
		if r.done and not r.replaced then
			r.replaced = true
			if Workspace:GetServerTimeNow() < s.endsAt - 6 then
				s.pending = (s.pending or 0) + 1
				local lane = r.laneX
				task.delay(cfg.respawnAfter, function()
					s.pending = (s.pending or 1) - 1
					if session == s and not s.ended then
						local at = centre + Vector3.new(lane, 0, START_Z)
						local fresh = addRunner(s, at, at - Vector3.zAxis, 100 + rng:NextInteger(1, 899))
						fresh.model:SetAttribute("Pace", cfg.pace)
					end
				end)
			end
		end
	end
	if s.lives <= 0 then
		finish(s, "Out of lives")
	elseif alive == 0 and (s.pending or 0) == 0 then
		finish(s, "Every runner is down or through")
	end
end

local function spawnTarget(s: Session)
	local fromLeft = rng:NextNumber() < 0.5
	local side = if fromLeft then -1 else 1
	local z = rng:NextNumber(4, 46)
	local at = centre + Vector3.new(side * 50, 0, z)
	local runner = addRunner(s, at, at - Vector3.new(side, 0, 0), nil)
	runner.laneX = -side * 52 -- where it heads
	runner.model:SetAttribute("Pace", rng:NextNumber(0.8, 1.2))
	goTo(runner.model, centre + Vector3.new(runner.laneX, 0, z), centre + Vector3.new(runner.laneX * 2, 0, z))
end

local function stepShoot(s: Session, _now: number)
	local cfg = MinigameService.SHOOT
	local alive = 0
	for _, r in s.runners do
		if not r.done and r.model.Parent then
			local pelvis = pelvisOf(r.model)
			if pelvis and math.abs((pelvis.Position.X - centre.X) - r.laneX) < 4 then
				-- Made it across: gone (no points lost; it just got away).
				r.done = true
				r.model:Destroy()
			else
				alive += 1
			end
		end
	end
	for _ = alive + 1, cfg.alive do
		spawnTarget(s)
	end
end

------------------------------------------------------------------------------------------------

-- Why a game cannot start now (nil: it can).
function MinigameService.refusal(player: Player, gameId: unknown): string?
	if not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ARENA_ENABLED then
		return "The Game Arena is closed for now" -- (V9-0s)
	end
	if gameId ~= "RLGL" and gameId ~= "Shoot" then
		return "Unknown game"
	end
	if not inArena(player) then
		return "Go to the Game Arena first"
	end
	if session then
		return string.format("%s is playing. Wait for the next round!", (session :: Session).host.DisplayName)
	end
	if Workspace:GetAttribute("HordeOn") == true then
		return "A horde is charging the lab! Next round after it"
	end
	if os.clock() < cooldownUntil then
		return "Next round in a moment"
	end
	return nil
end

function MinigameService.start(player: Player, gameId: string): (boolean, string?)
	local why = MinigameService.refusal(player, gameId)
	if why then
		return false, why
	end
	local cfg: any = if gameId == "RLGL" then MinigameService.RLGL else MinigameService.SHOOT
	local s: Session = {
		game = gameId,
		host = player,
		endsAt = Workspace:GetServerTimeNow() + cfg.duration,
		score = 0,
		lives = if gameId == "RLGL" then MinigameService.RLGL.lives else 0,
		light = "",
		lightUntil = 0,
		combo = 0,
		lastHitAt = -math.huge,
		runners = {},
		ended = false,
		hits = 0,
	}
	session = s
	-- Round 4, M10: a new round starts on a clear arena (the last round's kept dead go).
	for model in keptDead do
		keptDead[model] = nil
		if model.Parent then
			model:Destroy()
		end
	end
	if gameId == "RLGL" then
		startRLGL(s)
	else
		stepShoot(s, os.clock())
	end
	tell("State", stateOf(s))
	pop(if gameId == "RLGL" then "Knock down the ones that move on RED!" else "Knock them down! Quick hits build a combo.", true)
	return true, nil
end

-- Tests and the live loop.
function MinigameService.current(): Session?
	return session
end

function MinigameService.stopForTest()
	local s = session
	if s then
		finish(s, "Stopped")
	end
	cooldownUntil = 0
end

function MinigameService.stepForTest()
	local s = session
	if s then
		if s.game == "RLGL" then
			stepRLGL(s, os.clock())
		else
			stepShoot(s, os.clock())
		end
	end
end

function MinigameService.downForTest(model: Model)
	local s = session
	if s then
		for _, r in s.runners do
			if r.model == model then
				onDown(s, r)
			end
		end
	end
end

function MinigameService.setLightForTest(light: string, seconds: number)
	local s = session
	if s then
		setLight(s, light, seconds)
	end
end

function MinigameService.boot(labOrigin: Vector3)
	centre = Places.floorCenter(labOrigin, "Arena") or Vector3.zero
	remote = Net.event(Net.Names.Minigame) -- (made even while hidden: clients wait for it)
	-- (V9-0s: no arena while it is hidden: no games, no listener, nothing ticking.)
	if not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ARENA_ENABLED then
		return
	end
	local maps = WorldMaps.folder()
	local arena = maps and maps:FindFirstChild("Arena")
	if arena then
		for _, d in arena:GetDescendants() do
			local lamp = d:GetAttribute("Lamp")
			if d:IsA("BasePart") and type(lamp) == "string" then
				lamps[lamp] = d
			end
			if d:IsA("ProximityPrompt") and d.Parent then
				local gameId = (d.Parent :: Instance):GetAttribute("Game")
				d.Triggered:Connect(function(player)
					local ok, why = MinigameService.start(player, gameId :: string)
					if not ok and why then
						remote:FireClient(player, "Refused", { text = why })
					end
				end)
			end
		end
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < TICK then
			return
		end
		acc = 0
		local s = session
		if not s then
			return
		end
		if not s.host.Parent or not inArena(s.host) then
			finish(s, "The player left")
			return
		end
		if Workspace:GetServerTimeNow() >= s.endsAt then
			finish(s, "Time")
			return
		end
		if s.game == "RLGL" then
			stepRLGL(s, os.clock())
		else
			stepShoot(s, os.clock())
		end
	end)
	-- A player arriving mid-game sees the bar.
	Players.PlayerAdded:Connect(function(player)
		player:GetAttributeChangedSignal("Place"):Connect(function()
			local s = session
			if s and inArena(player) then
				remote:FireClient(player, "State", stateOf(s))
			end
		end)
	end)
	for _, player in Players:GetPlayers() do
		player:GetAttributeChangedSignal("Place"):Connect(function()
			local s = session
			if s and inArena(player) then
				remote:FireClient(player, "State", stateOf(s))
			end
		end)
	end
end

return MinigameService
