--!strict
-- 3.34 CPR (docs/MACHINES_10.md "PLAYER ACTIONS: CPR"; Config.PLAYER_CPR): a "CPR" prompt on every dead or knocked-out
-- lab ragdoll. You kneel in: a small rhythm game on your screen (Client/CprGame: push on the beat, 5 beats, a heart line
-- on a little monitor). A good rhythm raises the chance (0.25 + 0.14 per good beat: 5 good = 95 %): it comes back with
-- "IT'S ALIVE!", else "Flatline... try again". The body waits (BeingHelped) while you try.
-- Remote Cpr (Net): server -> client "Start" (the body); client -> server "Result" (the body, the beats 0-5), checked:
-- your open session, that body, 2.5-15 s after the start, within 15 studs, once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerCPR = {}

type Session = { model: Model, t0: number }
local sessions: { [Player]: Session } = {}
local lastEnd: { [Player]: number } = {}

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function pop(at: Vector3, text: string, color: Color3)
	pcall(function()
		lazy("Playground").pop(at, text, color)
	end)
end

local function down(m: Model): boolean
	local v = m:GetAttribute("Vital")
	return v == "Dead" or v == "Unconscious"
end

function PlayerCPR.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.PLAYER_CPR then
		return
	end
	local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any
	local remote = Net.event(Net.Names.Cpr)
	local function close(player: Player, model: Model?)
		sessions[player] = nil
		lastEnd[player] = os.clock()
		if model and model.Parent then
			model:SetAttribute("BeingHelped", nil)
		end
	end
	local function watch(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		local m = inst :: Model
		local prompt: ProximityPrompt? = nil
		local function update()
			local torso = m:FindFirstChild("UpperTorso")
			if down(m) and torso and torso:IsA("BasePart") then
				if not prompt then
					local pp = Instance.new("ProximityPrompt")
					pp.Name = "CprPrompt"
					pp.ActionText = "CPR"
					pp.ObjectText = "Save it"
					pp.MaxActivationDistance = 9
					pp.RequiresLineOfSight = false
					pp.Parent = torso
					pp.Triggered:Connect(function(player: Player)
						if sessions[player] or os.clock() - (lastEnd[player] or -math.huge) < 1 or not down(m) then
							return
						end
						if m:GetAttribute("BeingHelped") == true then
							return -- (someone is on it)
						end
						sessions[player] = { model = m, t0 = os.clock() }
						m:SetAttribute("BeingHelped", true)
						remote:FireClient(player, "Start", m)
						-- (no answer in 15 s: the session closes)
						task.delay(15, function()
							local s = sessions[player]
							if s and s.model == m then
								close(player, m)
							end
						end)
					end)
					prompt = pp
				end
			elseif prompt then
				prompt:Destroy()
				prompt = nil
			end
		end
		m:GetAttributeChangedSignal("Vital"):Connect(update)
		update()
	end
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		for _, m in dummies:GetChildren() do
			watch(m)
		end
		dummies.ChildAdded:Connect(watch)
	end)
	remote.OnServerEvent:Connect(function(player: Player, kind: any, model: any, score: any)
		local s = sessions[player]
		if typeof(kind) ~= "string" or kind ~= "Result" or typeof(model) ~= "Instance" or not s or model ~= s.model or typeof(score) ~= "number" or score ~= score then
			return
		end
		local elapsed = os.clock() - s.t0
		if elapsed < 2.5 or elapsed > 15 then
			return
		end
		local beats = math.clamp(math.floor(score + 0.5), 0, 5)
		local m = s.model
		local torso = m:FindFirstChild("UpperTorso")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		close(player, m)
		if not (torso and torso:IsA("BasePart") and root and root:IsA("BasePart")) or (root.Position - torso.Position).Magnitude > 15 then
			return
		end
		if math.random() < 0.25 + 0.14 * beats and down(m) then
			pcall(function()
				lazy("VitalsService").reviveNow(m)
			end)
			pop(torso.Position + Vector3.new(0, 5, 0), "IT'S ALIVE! (" .. beats .. "/5)", Color3.fromRGB(120, 255, 160))
		else
			pop(torso.Position + Vector3.new(0, 5, 0), "Flatline... try again (" .. beats .. "/5)", Color3.fromRGB(255, 160, 160))
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		local s = sessions[p]
		close(p, if s then s.model else nil)
		lastEnd[p] = nil
	end)
end

return PlayerCPR
