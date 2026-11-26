--!strict
-- F19 (owner, 26 Nov 2026: "maskinerne viser hvad de gør, én gang hver, langt fra hinanden, med RIGTIGE ragdolls";
-- Config.DEMO_REAL): instead of the client's yellow test dummies (LabShowcase attract mode, now off), now and then a
-- REAL lab ragdoll shows a machine: it is set at the machine and the machine throws it (the same arc, spin, drop or
-- lift the old demo had), it lands with the normal physics and gets up again. No extra dummies.
--   * One demo in a player's lab at a time, every GAP (45-60 s), the first after FIRST s.
--   * Each machine once per visit (per player).
--   * Never at a machine the player is within BUSY studs of, never while a TRY runs (a ragdoll has TryFor), never
--     while an event or surprise runs.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MachineDemos = {}

MachineDemos.GAP = Vector2.new(45, 60)
MachineDemos.FIRST = 50
MachineDemos.BUSY = 14
MachineDemos.PICK_REACH = 70 -- studs: the ragdoll that shows it is taken from this close

type Machine = { kind: string, path: { string }, demo: string, velocity: Vector3?, lift: number }
MachineDemos.MACHINES = {
	{ kind = "Cannon", path = { "CannonBarrel" }, demo = "arc", velocity = Vector3.new(-0.45, 0.8, -0.4).Unit * 62, lift = 2 },
	{ kind = "Wrecking", path = { "SwingBall" }, demo = "arc", velocity = Vector3.new(0, 34, -46), lift = 0 },
	{ kind = "Rocket", path = { "Dress", "Rocket" }, demo = "rise", lift = 3 },
	{ kind = "Spider", path = { "CreatureYard", "Spider" }, demo = "spin", lift = 9 },
	{ kind = "Whale", path = { "CreatureYard", "Whale" }, demo = "arc", velocity = Vector3.new(6, 58, 10), lift = 2 },
	{ kind = "Vacuum", path = { "CreatureYard", "Compressor" }, demo = "drop", lift = 16 },
	{ kind = "Washer", path = { "CreatureYard", "Washer" }, demo = "spin", lift = 4 },
	{ kind = "Slingshot", path = { "CreatureYard", "Slingshot" }, demo = "arc", velocity = Vector3.new(30, 56, -34), lift = 6 },
	{ kind = "Plant", path = { "CreatureYard", "Plant" }, demo = "drop", lift = 22 },
	{ kind = "Frog", path = { "CreatureYard", "Frog" }, demo = "arc", velocity = Vector3.new(0, 40, 22), lift = 1 },
	{ kind = "Chicken", path = { "CreatureYard", "Chicken" }, demo = "arc", velocity = Vector3.new(-18, 44, 0), lift = 1 },
	{ kind = "Mole", path = { "CreatureYard", "Mole" }, demo = "arc", velocity = Vector3.new(0, 52, 0), lift = 0 },
} :: { Machine }

local shown: { [Player]: { [string]: boolean } } = setmetatable({}, { __mode = "k" }) :: any
local nextAt: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function find(root: Instance, path: { string }): Instance?
	local at: Instance? = root
	for _, name in path do
		at = at and at:FindFirstChild(name)
	end
	return at
end

local function where(thing: Instance?): Vector3?
	if not thing then
		return nil
	elseif thing:IsA("BasePart") then
		return thing.Position
	elseif thing:IsA("Model") then
		return thing:GetPivot().Position
	end
	return nil
end

local function busy(player: Player): boolean
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		for _, m in dummies:GetChildren() do
			if m:GetAttribute("TryFor") ~= nil then
				return true -- (a TRY lesson runs)
			end
		end
	end
	local ok, running = pcall(function()
		local Events = require(script.Parent:WaitForChild("EventService")) :: any
		return Events.miniRunning()
	end)
	return ok and running == true
end

local function pickDummy(at: Vector3): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return nil
	end
	local best, bestD = nil :: Model?, MachineDemos.PICK_REACH
	for _, m in dummies:GetChildren() do
		local pelvis = m:FindFirstChild("LowerTorso")
		if m:IsA("Model") and pelvis and pelvis:IsA("BasePart") and m:GetAttribute("Held") ~= true and m:GetAttribute("Vital") ~= "Dead"
			and m:GetAttribute("TryFor") == nil and m:GetAttribute("Role3") == nil and m:GetAttribute("MachineHidden") ~= true
			and (m:GetAttribute("RagdollState") or "Standing") == "Standing" then
			local d = (pelvis.Position - at).Magnitude
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

local function show(player: Player, lab: Instance): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local list = shown[player] or {}
	shown[player] = list
	for _, mc in MachineDemos.MACHINES do
		if not list[mc.kind] then
			local at = where(find(lab, mc.path))
			if at and (root.Position - at).Magnitude > MachineDemos.BUSY then
				local m = pickDummy(at)
				if m then
					list[mc.kind] = true
					local DummyControl = require(script.Parent:WaitForChild("DummyControl")) :: any
					local start = at + Vector3.new(0, mc.lift + 2, 0)
					DummyControl.move(m, CFrame.new(start))
					task.wait(0.1)
					if mc.demo == "arc" and mc.velocity then
						DummyControl.push(m, mc.velocity)
					elseif mc.demo == "rise" then
						DummyControl.push(m, Vector3.new(0, 70, 0))
					elseif mc.demo == "spin" then
						DummyControl.push(m, Vector3.new(math.random(-12, 12), 34, math.random(-12, 12)))
					else -- "drop": it falls from the machine's top
						DummyControl.push(m, Vector3.new(0, -10, 0))
					end
					pcall(function()
						require(script.Parent:WaitForChild("FxService")).hit(start, 60, "CannonPad")
					end)
					return true
				end
			end
		end
	end
	return false
end

function MachineDemos.start()
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.DEMO_REAL then
		return
	end
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local due = nextAt[player]
				if not due then
					nextAt[player] = now + MachineDemos.FIRST
				elseif now >= due then
					nextAt[player] = now + math.random(MachineDemos.GAP.X, MachineDemos.GAP.Y)
					local ok, idx = pcall(function()
						return (require(script.Parent:WaitForChild("Lab")) :: any).plotIndex(player)
					end)
					local root = Workspace:FindFirstChild("Playground")
					local lab = ok and idx and root and root:FindFirstChild("Lab" .. tostring(idx))
					if lab and not busy(player) then
						pcall(show, player, lab)
					end
				end
			end
		end
	end)
end

MachineDemos.showFor = show -- (for a quick check)

return MachineDemos
