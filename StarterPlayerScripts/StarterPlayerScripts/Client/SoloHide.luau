--!strict
-- OVERVIEW 2 / F30 (owner, 26 Nov 2026: "alle labs er singleplayer så man skal ikke kunne se andre"; Config.SOLO_HIDE): the
-- safety net for the START place (a server for one; the owner sets server size 1). If a server there ever holds 2+
-- players (a friend followed in), this screen hides everyone else: their characters (LocalTransparencyModifier),
-- their name tags and their sounds. The multiplayer place (Config.MULTI_PLACE) shows everyone as before.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local SoloHide = {}

local me = Players.LocalPlayer

local function hidePart(d: Instance)
	if d:IsA("BasePart") or d:IsA("Decal") then
		(d :: any).LocalTransparencyModifier = 1
		if d:IsA("BasePart") then
			-- (keep it hidden: the animator and tools set it back now and then)
			d:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
				if (d :: any).LocalTransparencyModifier ~= 1 then
					(d :: any).LocalTransparencyModifier = 1
				end
			end)
		end
	elseif d:IsA("Humanoid") then
		d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	elseif d:IsA("BillboardGui") then
		d.Enabled = false
	elseif d:IsA("Sound") then
		d.Volume = 0
	elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
		d.Enabled = false
	end
end

local function hideCharacter(char: Model)
	for _, d in char:GetDescendants() do
		hidePart(d)
	end
	char.DescendantAdded:Connect(hidePart)
end

local function watch(p: Player)
	if p == me then
		return
	end
	if p.Character then
		hideCharacter(p.Character)
	end
	p.CharacterAdded:Connect(hideCharacter)
end

function SoloHide.start()
	if not Config.SOLO_HIDE then
		return
	end
	local multi = Config.MULTI_PLACE or 0
	local start = Config.START_PLACE or 0
	if multi == 0 or game.PlaceId ~= start then
		return -- (only the start place is solo)
	end
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
end

return SoloHide
