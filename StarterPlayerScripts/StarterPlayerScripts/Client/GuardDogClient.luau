--!strict
-- GUARD_DOG on this screen (docs/GUARD_DOG.md; Systems/GuardDog decides). While your dog is out (player attribute
-- DogOut): tap (or click) a ragdoll right on a limb and the dog is sent to bite exactly that limb. The head and neck
-- are never bitten: a tap there picks the nearest arm. The picked limb gets a short yellow outline. A round dog
-- button (64 px, left, under the launchers) sends the dog home; "GOOD BOY!" on the goal line after a bite. The first
-- time a short hint: "Tap a ragdoll's arm or leg!". On a phone a tap on a ragdoll bites instead of grabbing while the
-- dog is out (GrabController.tapAt).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any

local GuardDogClient = {}

GuardDogClient.NEAR_HOUSE = 15

local player = Players.LocalPlayer
local ARMS = { "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
local BITABLE = {
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	LowerTorso = true,
}

local function say(text: string)
	pcall(function()
		(require(script.Parent:WaitForChild("HudV3")) :: any).moment(text, 2)
	end)
end

-- The ragdoll limb under a screen point, or nil.
local function limbAt(screen: Vector2): (Model?, BasePart?)
	local camera = Workspace.CurrentCamera
	local dummies = Workspace:FindFirstChild("Dummies")
	if not camera or not dummies then
		return nil, nil
	end
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { dummies }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	if not hit then
		return nil, nil
	end
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	while model and model.Parent ~= dummies do
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	if not model then
		return nil, nil
	end
	-- The limb itself (a skin's limb is its parent part's name too), else the nearest bitable one.
	local name = hit.Instance.Name
	local part = model:FindFirstChild(name)
	if not (part and part:IsA("BasePart") and BITABLE[name]) then
		local best, bestD = nil, math.huge
		local list = if name == "Head" or name == "Neck" or name == "UpperTorso" then ARMS else nil
		for limbName in if list then {} else BITABLE do
			local p = model:FindFirstChild(limbName)
			if p and p:IsA("BasePart") then
				local d = (p.Position - hit.Position).Magnitude
				if d < bestD then
					best, bestD = p, d
				end
			end
		end
		for _, limbName in list or {} do
			local p = model:FindFirstChild(limbName)
			if p and p:IsA("BasePart") then
				local d = (p.Position - hit.Position).Magnitude
				if d < bestD then
					best, bestD = p, d
				end
			end
		end
		part = best
	end
	if part and part:IsA("BasePart") then
		return model, part
	end
	return nil, nil
end

local lastOrder = 0
function GuardDogClient.order(screen: Vector2): boolean
	if player:GetAttribute("DogOut") ~= true or os.clock() - lastOrder < 1.5 then
		return false
	end
	local model, limb = limbAt(screen)
	if not model or not limb then
		return false
	end
	lastOrder = os.clock()
	local h = Instance.new("Highlight")
	h.FillTransparency = 1
	h.OutlineColor = Color3.fromRGB(255, 220, 60)
	h.Adornee = limb
	h.Parent = player:WaitForChild("PlayerGui")
	task.delay(1.2, function()
		h:Destroy()
	end)
	Net.event(Net.Names.GuardDog):FireServer("Bite", model, limb.Name)
	return true
end

function GuardDogClient.start()
	if not Config.GUARD_DOG then
		return
	end
	local remote = Net.event(Net.Names.GuardDog)
	remote.OnClientEvent:Connect(function(kind: unknown)
		if kind == "GoodBoy" then
			say("GOOD BOY!")
		end
	end)
	-- The dog button (send it home), only while it is out.
	local gui = Instance.new("ScreenGui")
	gui.Name = "GuardDog"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4
	gui.Enabled = false
	local b = Instance.new("TextButton")
	b.Name = "Dog"
	b.AnchorPoint = Vector2.new(0, 0)
	b.Position = UDim2.fromOffset(18, 190)
	b.Size = UDim2.fromOffset(64, 64)
	b.BackgroundColor3 = Color3.fromRGB(150, 104, 64)
	b.TextScaled = true
	b.Text = "\u{1F415}"
	b.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = b
	gui.Parent = player:WaitForChild("PlayerGui")
	b.Activated:Connect(function()
		remote:FireServer("Home")
	end)
	local hinted = false
	-- (F9, owner 26 Nov 2026: the dog button only within NEAR_HOUSE studs of a doghouse; elsewhere walk back to send it home.)
	local function nearHouse(): boolean
		local c = player.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if not r or not r:IsA("BasePart") then
			return false
		end
		for _, h in game:GetService("CollectionService"):GetTagged("Doghouse") do
			if h:IsA("BasePart") and (h.Position - r.Position).Magnitude <= GuardDogClient.NEAR_HOUSE then
				return true
			end
		end
		return false
	end
	local function refresh()
		local out = player:GetAttribute("DogOut") == true
		gui.Enabled = out and nearHouse()
		if out and not hinted then
			hinted = true
			say("Tap a ragdoll's arm or leg!")
		end
	end
	player:GetAttributeChangedSignal("DogOut"):Connect(refresh)
	refresh()
	task.spawn(function()
		while true do
			task.wait(0.5)
			gui.Enabled = player:GetAttribute("DogOut") == true and nearHouse()
		end
	end)
	-- A computer: a click on a ragdoll orders the bite (the gun still does what it does).
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		GuardDogClient.order(UserInputService:GetMouseLocation() - Vector2.new(0, 0))
	end)
end

return GuardDogClient
