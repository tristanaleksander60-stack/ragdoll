--!strict
-- 3.31 WEAPON RANGE, part 1 (docs/MACHINES_10.md "3.31 WEAPON RANGE"; Config.TARGET_RUN): the archery target becomes a
-- timed course. A prompt on it ("30 s TARGET RUN"): for 30 s the target slides from side to side (faster as the time
-- runs down), every shot of yours that lands on it scores by ring (BULLSEYE 50 / 30 / 20 / 10, a pop at the hole), and
-- at the end "TARGET RUN: 230 pts" with a NEW BEST per weapon (attribute TargetBest_<weapon>) and overall (TargetBest).
-- One run at a time per target; the target goes back to its spot after.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TargetRun = {}

TargetRun.TIME = 30
TargetRun.SWAY = 4.5 -- studs to each side

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pop(at: Vector3, text: string, color: Color3)
	pcall(function()
		lazy("Playground").pop(at, text, color)
	end)
end

type Target = { faces: { BasePart }, base: { [BasePart]: CFrame }, centre: BasePart, running: Player?, score: number, offset: Vector3 }
local targets: { Target } = {}

local function weaponOf(player: Player): string
	local char = player.Character
	local tool = char and char:FindFirstChildWhichIsA("Tool")
	return if tool then tool.Name else "Hands"
end

local function run(t: Target, player: Player)
	t.running = player
	t.score = 0
	local centre = t.centre
	local side = centre.CFrame.LookVector
	side = Vector3.new(side.X, 0, side.Z)
	side = if side.Magnitude > 0.01 then side.Unit else Vector3.xAxis
	pop(centre.Position + Vector3.new(0, 7, 0), "GO! 30 s", Color3.fromRGB(255, 220, 80))
	local t0 = os.clock()
	local phase = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		local left = TargetRun.TIME - (os.clock() - t0)
		phase += dt * (1.2 + 1.6 * (1 - math.max(left, 0) / TargetRun.TIME))
		t.offset = side * math.sin(phase) * TargetRun.SWAY
		for _, f in t.faces do
			f.CFrame = t.base[f] + t.offset
		end
	end)
	for k = TargetRun.TIME - 1, 1, -1 do
		task.wait(1)
		if not player.Parent then
			break
		end
		if k <= 5 or k % 10 == 0 then
			pop(centre.Position + Vector3.new(0, 7, 0), tostring(k), Color3.fromRGB(255, 255, 255))
		end
	end
	task.wait(1)
	conn:Disconnect()
	for _, f in t.faces do
		f.CFrame = t.base[f]
	end
	t.offset = Vector3.zero
	local score = t.score
	local weapon = weaponOf(player)
	local text = "TARGET RUN: " .. score .. " pts"
	if player.Parent then
		local key = "TargetBest_" .. string.gsub(weapon, "[^%w]", "")
		local best = (player:GetAttribute(key) :: number?) or 0
		if score > best and score > 0 then
			player:SetAttribute(key, score)
			text ..= " NEW BEST (" .. weapon .. ")!"
		end
		local all = (player:GetAttribute("TargetBest") :: number?) or 0
		if score > all then
			player:SetAttribute("TargetBest", score)
		end
	end
	pop(centre.Position + Vector3.new(0, 8, 0), text, Color3.fromRGB(255, 220, 80))
	t.running = nil
end

local function onShot(point: Vector3, from: Vector3)
	for _, t in targets do
		local player = t.running
		local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not (player and root and root:IsA("BasePart") and (root.Position - from).Magnitude < 8) then
			continue
		end
		local c = t.centre
		local rel = c.CFrame:PointToObjectSpace(point)
		-- (the face is a cylinder lying along its X: the hole is on its plane, at a radius in Y/Z)
		if math.abs(rel.X) > 1.5 then
			continue
		end
		local r = Vector2.new(rel.Y, rel.Z).Magnitude
		local pts = if r < 1.1 then 50 elseif r < 2.2 then 30 elseif r < 3.3 then 20 elseif r < 4.5 then 10 else 0
		if pts > 0 then
			t.score += pts
			pop(point + Vector3.new(0, 1.5, 0), if pts == 50 then "BULLSEYE +50" else "+" .. pts, if pts == 50 then Color3.fromRGB(255, 220, 60) else Color3.fromRGB(255, 255, 255))
		end
	end
end

local function adopt(group: { BasePart })
	table.sort(group, function(a, b)
		return a.Size.Y < b.Size.Y
	end)
	local t: Target = { faces = group, base = {}, centre = group[1], running = nil, score = 0, offset = Vector3.zero }
	for _, f in group do
		t.base[f] = f.CFrame
	end
	local big = group[#group]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TargetRunPrompt"
	prompt.ActionText = "30 s TARGET RUN"
	prompt.ObjectText = "Target"
	prompt.MaxActivationDistance = 40
	prompt.RequiresLineOfSight = false
	prompt.Parent = big
	prompt.Triggered:Connect(function(player: Player)
		if t.running then
			return
		end
		task.spawn(run, t, player)
	end)
	table.insert(targets, t)
end

function TargetRun.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.TARGET_RUN then
		return
	end
	pcall(function()
		table.insert(lazy("Knockables").listeners, { shot = onShot, blast = function() end, reset = function() end })
	end)
	task.spawn(function()
		local seen: { [BasePart]: boolean } = {}
		for _ = 1, 24 do -- (the map is built in the first minute; then it stops looking)
			task.wait(5)
			if #targets > 0 then
				break
			end
			local folder = Workspace
			local fresh: { BasePart } = {}
			for _, d in folder:GetDescendants() do
				if d.Name == "TargetFace" and d:IsA("BasePart") and not seen[d] then
					table.insert(fresh, d)
				end
			end
			-- group the faces of one target (all within 1 stud of each other's centre)
			while #fresh > 0 do
				local first = table.remove(fresh, 1) :: BasePart
				local group = { first }
				seen[first] = true
				for i = #fresh, 1, -1 do
					if (fresh[i].Position - first.Position).Magnitude < 1 then
						seen[fresh[i]] = true
						table.insert(group, table.remove(fresh, i) :: BasePart)
					end
				end
				if #group >= 2 then
					adopt(group)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		for _, t in targets do
			if t.running == p then
				t.running = nil
			end
		end
	end)
end

return TargetRun
