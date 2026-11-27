--!strict
-- T1 part 3 (docs/FTUE_10.md "about 2:00 the first SURPRISE"; Config.GOLDEN_RUN): once a session, about AFTER s after a
-- player joins, a free ragdoll 30-90 studs away turns GOLDEN (a gold glow) and runs off. The player has WINDOW s to knock
-- it down (their hit: Dummies.blame): +BONUS KOs and a line. The player attribute GoldenUntil (server time) lets the
-- screen show "Catch the GOLDEN one!" with a countdown on the goal line (Client/FirstTwo).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GoldenRun = {}

GoldenRun.AFTER = 120
GoldenRun.WINDOW = 10
GoldenRun.BONUS = 10

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pickRunner(root: BasePart): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	local best, bestD = nil :: Model?, math.huge
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = m:FindFirstChild("LowerTorso")
		local st = m:GetAttribute("RagdollState")
		if m:IsA("Model") and pe and pe:IsA("BasePart") and (st == "Standing" or st == "Walking") and m:GetAttribute("Vital") ~= "Dead"
			and m:GetAttribute("Watch") == nil and m:GetAttribute("Role3") == nil and m:GetAttribute("TryFor") == nil
			and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("InMachine") == nil and m:GetAttribute("Held") ~= true
			and m:GetAttribute("Bowling") == nil then
			local d = (pe.Position - root.Position).Magnitude
			if d > 30 and d < 90 and math.abs(d - 55) < bestD then
				best, bestD = m, math.abs(d - 55)
			end
		end
	end
	return best
end

local function run(player: Player)
	task.wait(GoldenRun.AFTER)
	for _ = 1, 12 do -- (up to a minute more if nobody is free, or the player is busy in a menu or a machine)
		if not player.Parent then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local m = root and root:IsA("BasePart") and pickRunner(root) or nil
		if m and root and root:IsA("BasePart") then
			local glow = Instance.new("Highlight")
			glow.Name = "GoldenGlow"
			glow.FillColor = Color3.fromRGB(255, 200, 40)
			glow.OutlineColor = Color3.fromRGB(255, 240, 150)
			glow.FillTransparency = 0.35
			glow.Parent = m
			m:SetAttribute("Golden", player.UserId)
			m:SetAttribute("MoodSay", "Catch me if you can!")
			m:SetAttribute("PanicFrom", root.Position)
			local untilT = Workspace:GetServerTimeNow() + GoldenRun.WINDOW
			m:SetAttribute("PanicUntil", untilT)
			player:SetAttribute("GoldenUntil", untilT)
			local caught = false
			local t0 = os.clock()
			while os.clock() - t0 < GoldenRun.WINDOW and m.Parent do
				task.wait(0.2)
				local st = m:GetAttribute("RagdollState")
				if st == "Ragdoll" or st == "Out" or m:GetAttribute("Vital") == "Unconscious" or m:GetAttribute("Vital") == "Dead" then
					local who = 0
					pcall(function()
						who = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Dummies")) :: any).blame(m)
					end)
					caught = who == player.UserId
					break
				end
			end
			if glow.Parent then
				glow:Destroy()
			end
			m:SetAttribute("Golden", nil)
			m:SetAttribute("MoodSay", nil)
			player:SetAttribute("GoldenUntil", nil)
			player:SetAttribute("GoldenCaught", if caught then true else false)
			if caught then
				pcall(function()
					lazy("ProgressService").addTakedowns(player, GoldenRun.BONUS)
				end)
			end
			return
		end
		task.wait(5)
	end
end

function GoldenRun.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.GOLDEN_RUN then
		return
	end
	Players.PlayerAdded:Connect(function(p)
		task.spawn(run, p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(run, p)
	end
end

return GoldenRun
