--!strict
-- 3.18 BOXING (docs/MACHINES_10.md "3.18 BOXING RING"; owner's answer 27 Nov: a free "PICK THE WINNER", no BOLTS stake;
-- Config.BOXING_MATCH): a "START A FIGHT" prompt on the ring. Two free lab ragdolls walk over and hop into the corners,
-- RED and BLUE. For PICK_TIME s everyone near can pick the winner (a prompt on each boxer). Then the bell: they box
-- (Mood "Box": fists up, the "Punch" attribute swings an arm on every screen), each landed punch knocks the other back
-- a little and adds damage; enough damage and a big punch knocks it DOWN, and the referee counts to 10 over it. Up
-- before 10: the fight goes on. Not up: the other one WINS (it cheers, confetti, "RED WINS!"). Picked right: a cheer
-- and a streak (player attribute BoxStreak, this visit). Free for everyone; nothing is sold or staked.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BoxingMatch = {}

BoxingMatch.PICK_TIME = 7
BoxingMatch.MAX_FIGHT = 70 -- s, then the one with less damage wins on points
BoxingMatch.FETCH = 70 -- studs: boxers come from this close to the ring
BoxingMatch.BELL = "rbxassetid://9125390319" -- (the PSE bell the bicycle rings, pitched down: a ring bell)

local busy: { [BasePart]: boolean } = {}

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pop(at: Vector3, text: string, color: Color3)
	pcall(function()
		lazy("Playground").pop(at, text, color)
	end)
end

local function free(m: Model): boolean
	local state = m:GetAttribute("RagdollState")
	local vital = m:GetAttribute("Vital")
	return m.Parent ~= nil and (state == nil or state == "Standing" or state == "Walking") and vital ~= "Dead" and vital ~= "Unconscious"
		and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("Mood") == nil and m:GetAttribute("InMachine") == nil
		and m:GetAttribute("MachineHidden") == nil and m:GetAttribute("Held") ~= true and m:GetAttribute("TryFor") == nil
		and m:GetAttribute("Seat") == nil
end

local function pelvis(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function standing(m: Model): boolean
	local s = m:GetAttribute("RagdollState")
	return s == nil or s == "Standing" or s == "Walking"
end

local function bell(at: BasePart, times: number)
	task.spawn(function()
		for _ = 1, times do
			local s = Instance.new("Sound")
			s.SoundId = BoxingMatch.BELL
			s.PlaybackSpeed = 0.62
			s.Volume = 0.9
			s.RollOffMaxDistance = 160
			s.Parent = at
			s:Play()
			game:GetService("Debris"):AddItem(s, 3)
			task.wait(0.35)
		end
	end)
end

local function confetti(at: BasePart)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, at.Size.Y / 2 + 6, 0)
	a.Parent = at
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 60)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 255, 120)),
	})
	e.Size = NumberSequence.new(0.35)
	e.Speed = NumberRange.new(18, 30)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Lifetime = NumberRange.new(1.5, 2.5)
	e.Acceleration = Vector3.new(0, -25, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.Rate = 0
	e.Parent = a
	e:Emit(120)
	game:GetService("Debris"):AddItem(a, 4)
end

local function fight(canvas: BasePart, starter: Player)
	busy[canvas] = true
	local Lab = lazy("Lab")
	local DC = lazy("DummyControl")
	local owner = Lab.ownerAt(canvas.Position) or starter
	local center = canvas.Position
	local topY = center.Y + canvas.Size.Y / 2
	local spots = {
		Vector3.new(center.X - 5, topY + 3.2, center.Z),
		Vector3.new(center.X + 5, topY + 3.2, center.Z),
	}
	-- the two nearest free ragdolls of this lab
	local pool = {}
	for _, m in Lab.dummiesOf(owner) do
		local pe = pelvis(m)
		if pe and free(m) then
			local d = (pe.Position - center).Magnitude
			if d < BoxingMatch.FETCH then
				table.insert(pool, { m = m, d = d })
			end
		end
	end
	table.sort(pool, function(a, b)
		return a.d < b.d
	end)
	if #pool < 2 then
		pop(center + Vector3.new(0, 8, 0), "No boxers free right now", Color3.fromRGB(255, 200, 120))
		busy[canvas] = nil
		return
	end
	local boxers: { Model } = { pool[1].m, pool[2].m }
	local names = { "RED", "BLUE" }
	local colors = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(80, 150, 255) }
	for i, m in boxers do
		m:SetAttribute("InMachine", "Boxing")
		m:SetAttribute("Watch", "Boxing")
		m:SetAttribute("Pace", 1.8)
		-- (walk to the ring's side by its corner, then hop up: never a teleport from afar)
		local side = Vector3.new(spots[i].X + (if i == 1 then -8 else 8), center.Y, spots[i].Z)
		m:SetAttribute("Home", side)
	end
	local function cleanup(cheer: Model?)
		for i, m in boxers do
			if m.Parent then
				m:SetAttribute("Mood", if m == cheer then "Cheer" else nil)
				m:SetAttribute("HomeLook", nil)
				m:SetAttribute("Pace", nil)
				m:SetAttribute("Watch", nil)
				m:SetAttribute("InMachine", nil)
				m:SetAttribute("BoxSide", nil)
				if standing(m) then
					-- hop down off its side of the ring
					pcall(DC.move, m, CFrame.new(Vector3.new(spots[i].X + (if i == 1 then -9 else 9), center.Y + 3.2, spots[i].Z)))
				end
				if m == cheer then
					task.delay(4, function()
						if m.Parent and m:GetAttribute("Mood") == "Cheer" then
							m:SetAttribute("Mood", nil)
						end
					end)
				end
			end
		end
		busy[canvas] = nil
	end
	-- wait for both at the ring (20 s), then hop them into their corners
	local t0 = os.clock()
	while os.clock() - t0 < 20 do
		local ready = true
		for _, m in boxers do
			local pe = pelvis(m)
			if not (pe and m.Parent and (Vector3.new(pe.Position.X, 0, pe.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude < 16) then
				ready = false
			end
		end
		if ready then
			break
		end
		task.wait(0.5)
	end
	for i, m in boxers do
		local pe = pelvis(m)
		if not (pe and m.Parent and (pe.Position - center).Magnitude < 22) then
			pop(center + Vector3.new(0, 8, 0), "A boxer got lost on the way", Color3.fromRGB(255, 200, 120))
			cleanup(nil)
			return
		end
		pcall(DC.move, m, CFrame.lookAt(spots[i], spots[3 - i]))
		m:SetAttribute("Home", spots[i])
		m:SetAttribute("HomeLook", spots[3 - i])
		m:SetAttribute("BoxSide", names[i])
	end
	-- PICK THE WINNER
	local picks: { [Player]: number } = {}
	local prompts: { ProximityPrompt } = {}
	for i, m in boxers do
		pop(spots[i] + Vector3.new(0, 4.5, 0), names[i], colors[i])
		local torso = m:FindFirstChild("UpperTorso")
		if torso and torso:IsA("BasePart") then
			local pp = Instance.new("ProximityPrompt")
			pp.Name = "PickWinner"
			pp.ActionText = "Pick " .. names[i]
			pp.ObjectText = "Who wins?"
			pp.MaxActivationDistance = 30
			pp.RequiresLineOfSight = false
			pp.Parent = torso
			pp.Triggered:Connect(function(p: Player)
				if picks[p] == nil then
					picks[p] = i
					lazy("ProgressService").notice(p, "You picked " .. names[i] .. "!")
				end
			end)
			table.insert(prompts, pp)
		end
	end
	pop(center + Vector3.new(0, 9, 0), "PICK THE WINNER!", Color3.fromRGB(255, 230, 90))
	task.wait(BoxingMatch.PICK_TIME)
	for _, pp in prompts do
		pp:Destroy()
	end
	-- THE BELL
	bell(canvas, 1)
	pop(center + Vector3.new(0, 9, 0), "FIGHT!", Color3.fromRGB(255, 120, 60))
	local damage = { 0, 0 }
	local needs = { math.random(4, 7), math.random(4, 7) }
	local punches = { 0, 0 }
	local winner: number? = nil
	local started = os.clock()
	for _, m in boxers do
		m:SetAttribute("Mood", "Box")
	end
	while os.clock() - started < BoxingMatch.MAX_FIGHT and not winner do
		task.wait(0.9 + math.random() * 0.6)
		if not (boxers[1].Parent and boxers[2].Parent) then
			break
		end
		local a = if math.random() < 0.5 then 1 else 2
		local b = 3 - a
		local ma, mb = boxers[a], boxers[b]
		local pa, pb = pelvis(ma), pelvis(mb)
		if not (pa and pb) then
			break
		end
		if not standing(ma) then
			continue
		end
		-- step in and swing
		local dir = Vector3.new(pb.Position.X - pa.Position.X, 0, pb.Position.Z - pa.Position.Z)
		dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.xAxis
		ma:SetAttribute("Home", pb.Position - dir * 2.4)
		ma:SetAttribute("HomeLook", pb.Position)
		mb:SetAttribute("HomeLook", pa.Position)
		punches[a] += 1
		ma:SetAttribute("Punch", punches[a])
		task.wait(0.18)
		pa, pb = pelvis(ma), pelvis(mb)
		if pa and pb and (pa.Position - pb.Position).Magnitude < 4.6 and standing(mb) and math.random() < 0.75 then
			damage[b] += 1
			local big = damage[b] >= needs[b]
			pcall(DC.push, mb, dir * (if big then 46 else 13 + damage[b] * 3) + Vector3.new(0, if big then 18 else 4, 0), nil)
			pop(pb.Position + Vector3.new(0, 4, 0), if big then "KNOCKDOWN!" else "POW!", if big then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(255, 230, 120))
			if big then
				-- the referee's count
				task.wait(1)
				local up = false
				for n = 1, 10 do
					local p2 = pelvis(mb)
					if p2 then
						pop(p2.Position + Vector3.new(0, 3.5, 0), tostring(n), Color3.fromRGB(255, 255, 255))
					end
					task.wait(1)
					if standing(mb) then
						up = true
						break
					end
				end
				if up then
					damage[b] = math.max(0, damage[b] - 3)
					needs[b] += 2
					pop(center + Vector3.new(0, 9, 0), names[b] .. " IS UP!", colors[b])
					mb:SetAttribute("Home", spots[b])
				else
					winner = a
				end
			end
		end
		-- back to its spot (and the other one squares up)
		ma:SetAttribute("Home", spots[a])
	end
	if not winner then
		winner = if damage[1] < damage[2] then 1 elseif damage[2] < damage[1] then 2 else math.random(1, 2)
	end
	local w = winner :: number
	bell(canvas, 3)
	pop(center + Vector3.new(0, 10, 0), names[w] .. " WINS!", colors[w])
	confetti(canvas)
	for p, side in picks do
		if p.Parent then
			if side == w then
				local streak = ((p:GetAttribute("BoxStreak") :: number?) or 0) + 1
				p:SetAttribute("BoxStreak", streak)
				lazy("ProgressService").notice(p, "You picked the winner!" .. (if streak > 1 then " Streak " .. streak .. "!" else ""))
			else
				p:SetAttribute("BoxStreak", 0)
				lazy("ProgressService").notice(p, names[w] .. " won. Better luck next fight!")
			end
		end
	end
	cleanup(boxers[w])
end

local function adopt(canvas: BasePart)
	if canvas:FindFirstChild("StartFight") then
		return
	end
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "StartFight"
	pp.ActionText = "START A FIGHT"
	pp.ObjectText = "Boxing"
	pp.MaxActivationDistance = 16
	pp.RequiresLineOfSight = false
	pp.Parent = canvas
	pp.Triggered:Connect(function(player: Player)
		if busy[canvas] then
			return
		end
		pp.Enabled = false
		task.spawn(function()
			local ok, err = pcall(fight, canvas, player)
			if not ok then
				warn("[BoxingMatch] " .. tostring(err))
				busy[canvas] = nil
			end
			task.wait(3)
			pp.Enabled = true
		end)
	end)
end

function BoxingMatch.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.BOXING_MATCH then
		return
	end
	task.spawn(function()
		for _ = 1, 60 do -- (the labs are built in the first minutes; a rebuilt lab is found again)
			local root = Workspace:FindFirstChild("Playground")
			if root then
				for _, d in root:GetDescendants() do
					if d.Name == "RingCanvas" and d:IsA("BasePart") then
						adopt(d)
					end
				end
			end
			task.wait(5)
		end
	end)
end

return BoxingMatch
