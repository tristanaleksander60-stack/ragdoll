--!strict
-- V9-0d (Config.PLAZA_V9): the town square's things to do together, on this screen.
--   * MEET STAGE, "Dance": your avatar plays Roblox's dance emote (wave if the dance is not there).
--   * PHOTO SPOT, "Take a photo": you step into the gold frame, wave, the camera frames you with the
--     square behind, the HUD steps away for a few seconds with a shutter flash, so a screenshot is a
--     clean picture; then everything comes back.
--   * The square's sounds: the fountain's water and a soft outdoor murmur, played here on the Ambient
--     bus (SoundMix: Settings' effects volume reaches them), positional, silent away from the plaza.
--     No music (owner rule). Pro Sound Effects, Roblox-licensed (Creator Store).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local PlazaClient = {}

PlazaClient.PHOTO_HOLD = 3.5 -- s the clean frame stays for a screenshot
PlazaClient.SOUNDS = {
	-- (source: Creator Store, Roblox-licensed, Pro Sound Effects: "Waterfall Steady Stream 2 (SFX)")
	{ id = "rbxassetid://9120552671", volume = 0.32, near = 10, far = 70 },
	-- (source: Creator Store, Roblox-licensed, Pro Sound Effects: "High School 2 (SFX)", exterior walla)
	{ id = "rbxassetid://9114800838", volume = 0.12, near = 28, far = 110 },
}

local player = Players.LocalPlayer
local busy = false

local function humanoidOf(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function dance()
	local humanoid = humanoidOf()
	if not humanoid then
		return
	end
	local ok, played = pcall(function()
		return humanoid:PlayEmote("dance")
	end)
	if not (ok and played) then
		pcall(function()
			humanoid:PlayEmote("wave")
		end)
	end
end

local function photo(prompt: ProximityPrompt)
	if busy then
		return
	end
	local spot = prompt:FindFirstAncestorOfClass("Model")
	local cameraAt = spot and spot:GetAttribute("CameraAt")
	local lookAt = spot and spot:GetAttribute("LookAt")
	local character = player.Character
	local step = prompt.Parent
	local humanoid = humanoidOf()
	if typeof(cameraAt) ~= "Vector3" or typeof(lookAt) ~= "Vector3" or not character or not humanoid or not (step and step:IsA("BasePart")) then
		return
	end
	-- (Only standing free: never pulled out of a ragdoll, a friend's grab or a seat to pose.)
	local free = humanoid.SeatPart == nil and humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Physics
	pcall(function()
		local PlayerBody = require(script.Parent:WaitForChild("PlayerBody")) :: any
		free = free and not PlayerBody.isDown() and not PlayerBody.isHeld()
	end)
	if not free then
		return
	end
	busy = true
	player:SetAttribute("PhotoPose", true) -- (AvatarMoves: no turning to the mouse while posing)
	-- Into the frame, facing the camera.
	local standAt = step.Position + Vector3.new(0, step.Size.Y / 2 + 3, 0)
	character:PivotTo(CFrame.lookAt(standAt, Vector3.new(cameraAt.X, standAt.Y, cameraAt.Z)))
	pcall(function()
		humanoid:PlayEmote("wave")
	end)
	-- The clean frame: every ScreenGui off while the photo is up. What each one's owner wants meanwhile
	-- (on or off) is followed and put back after: never a stale window brought back, never one lost.
	local gui = player:WaitForChild("PlayerGui")
	local intent: { [ScreenGui]: boolean } = {}
	local writing = false
	local watches: { RBXScriptConnection } = {}
	local function keepOff(g: ScreenGui)
		if g.Enabled then
			writing = true
			g.Enabled = false
			writing = false
		end
	end
	local function track(g: Instance)
		if not g:IsA("ScreenGui") or g.Name == "PhotoFlash" or intent[g] ~= nil then
			return
		end
		intent[g] = g.Enabled
		table.insert(watches, g:GetPropertyChangedSignal("Enabled"):Connect(function()
			if writing then
				return
			end
			intent[g] = g.Enabled -- (its owner turned it on or off while the photo was up)
			keepOff(g)
		end))
		keepOff(g)
	end
	for _, g in gui:GetChildren() do
		track(g)
	end
	table.insert(watches, gui.ChildAdded:Connect(track))
	-- Roblox's own pieces (chat, player list, backpack...), each put back as it was.
	local core: { [Enum.CoreGuiType]: boolean } = {}
	for _, kind in Enum.CoreGuiType:GetEnumItems() do
		if kind ~= Enum.CoreGuiType.All then
			local ok, on = pcall(function()
				return StarterGui:GetCoreGuiEnabled(kind)
			end)
			if ok then
				core[kind] = on
			end
		end
	end
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	local camera = Workspace.CurrentCamera
	local oldType, oldFov = camera.CameraType, camera.FieldOfView
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 50
	RunService:BindToRenderStep("PlazaPhoto", Enum.RenderPriority.Camera.Value + 1, function()
		camera.CFrame = CFrame.lookAt(cameraAt, lookAt)
	end)
	-- The shutter: a white flash.
	local flashGui = Instance.new("ScreenGui")
	flashGui.Name = "PhotoFlash"
	flashGui.IgnoreGuiInset = true
	flashGui.DisplayOrder = 100
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Parent = flashGui
	flashGui.Parent = gui
	task.delay(0.8, function()
		pcall(function()
			local Kit = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIComponents")) :: any
			Kit.playSound("click")
		end)
		flash.BackgroundTransparency = 0.1
		TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	end)
	task.delay(0.8 + PlazaClient.PHOTO_HOLD, function()
		RunService:UnbindFromRenderStep("PlazaPhoto")
		camera.CameraType = oldType
		camera.FieldOfView = oldFov
		for _, c in watches do
			c:Disconnect()
		end
		for g, on in intent do
			if g.Parent then
				g.Enabled = on
			end
		end
		for kind, on in core do
			pcall(function()
				StarterGui:SetCoreGuiEnabled(kind, on)
			end)
		end
		flashGui:Destroy()
		player:SetAttribute("PhotoPose", nil)
		busy = false
	end)
end

local function sounds()
	task.spawn(function()
		local dressing = Workspace:WaitForChild("PlazaDressing", 60)
		local fountain = dressing and dressing:WaitForChild("Fountain", 30)
		local source: BasePart? = nil
		for _, d in if fountain then fountain:GetDescendants() else {} do
			if d:IsA("BasePart") then
				source = d
				break
			end
		end
		if not source then
			return
		end
		local group: SoundGroup? = nil
		pcall(function()
			group = (require(script.Parent:WaitForChild("SoundMix")) :: any).group("Ambient")
		end)
		for _, spec in PlazaClient.SOUNDS do
			local s = Instance.new("Sound")
			s.Name = "PlazaAmbience"
			s.SoundId = spec.id
			s.Volume = spec.volume
			s.Looped = true
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMinDistance = spec.near
			s.RollOffMaxDistance = spec.far
			s.SoundGroup = group
			s.Parent = source
			s:Play()
		end
	end)
end

function PlazaClient.start()
	if not Config.PLAZA_V9 then
		return
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
		if who ~= player then
			return
		end
		if prompt.Name == "PlazaDance" then
			dance()
		elseif prompt.Name == "PlazaPhoto" then
			photo(prompt)
		end
	end)
	sounds()
end

return PlazaClient
