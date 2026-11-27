--!strict
-- BooMask (MILD_EXTRAS C3, Config.BOO_MASK; owner: "ja til A og C3"): sneak up behind a ragdoll and BOO! it. It
-- jumps out of its skin (a hop and a shocked face), screams "AAAH!" and runs away from you for a few seconds.
-- The client (Client/BooButton) shows a BOO! button only while you stand close behind a standing ragdoll that faces
-- away; the server checks it again: the body is a living ragdoll, within 7 studs of you, facing away (you are behind
-- it), and you BOO at most once every 1.5 s. Cartoony and silly, never gross; the questionnaire says fear: mild.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BooMask = {}

BooMask.REACH = 7 -- studs
BooMask.COOLDOWN = 1.5 -- s per player
BooMask.RUN = 5 -- s it runs from you

local last: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
local SHOUTS = { "AAAH!", "EEEK!", "WAAH!", "AAH, DON'T DO THAT!", "MY HEART!" }

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function boo(player: Player, model: any)
	local now = os.clock()
	if now - (last[player] or -math.huge) < BooMask.COOLDOWN then
		return
	end
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if not (dummies and model.Parent == dummies) then
		return
	end
	local state = model:GetAttribute("RagdollState")
	if not (state == "Standing" or state == "Walking") or model:GetAttribute("Vital") == "Dead" or model:GetAttribute("InMachine") ~= nil then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local chest = model:FindFirstChild("UpperTorso")
	if not (root and root:IsA("BasePart") and chest and chest:IsA("BasePart")) then
		return
	end
	local away = Vector3.new(root.Position.X - chest.Position.X, 0, root.Position.Z - chest.Position.Z)
	if away.Magnitude > BooMask.REACH or away.Magnitude < 0.1 then
		return
	end
	local look = Vector3.new(chest.CFrame.LookVector.X, 0, chest.CFrame.LookVector.Z)
	if look.Magnitude < 0.1 or look.Unit:Dot(away.Unit) > -0.1 then
		return -- (it can see you coming: no surprise)
	end
	last[player] = now
	-- jumps out of its skin: a hop, a shocked face, a scream, then it runs from you
	model:SetAttribute("Mood", "Shock")
	model:SetAttribute("MoodSay", SHOUTS[math.random(#SHOUTS)])
	pcall(function()
		lazy("DummyControl").push(model, Vector3.new(0, 22, 0) - away.Unit * 6, nil)
	end)
	task.delay(0.9, function()
		if model.Parent and model:GetAttribute("Mood") == "Shock" then
			model:SetAttribute("Mood", nil)
		end
		if model.Parent then
			model:SetAttribute("PanicFrom", root.Position)
			model:SetAttribute("PanicUntil", Workspace:GetServerTimeNow() + BooMask.RUN)
		end
	end)
	task.delay(3, function()
		if model.Parent and model:GetAttribute("MoodSay") ~= nil then
			model:SetAttribute("MoodSay", nil)
		end
	end)
	pcall(function()
		lazy("Playground").pop(chest.Position + Vector3.new(0, 4, 0), "BOO!", Color3.fromRGB(255, 240, 120))
	end)
	pcall(function()
		lazy("Funnels").event(player, "Boo")
	end)
end

function BooMask.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.BOO_MASK then
		return
	end
	local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any
	Net.event(Net.Names.Boo).OnServerEvent:Connect(function(player: Player, model: unknown)
		boo(player, model)
	end)
	Players.PlayerRemoving:Connect(function(p)
		last[p] = nil
	end)
end

return BooMask
