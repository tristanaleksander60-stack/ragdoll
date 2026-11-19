--!strict
-- v4 A3 (owner: "all sound in place, right volumes"): the mix. Every game sound plays in one of a
-- few SoundGroups under the player's Effects group (Settings: NORMAL / QUIET / OFF), each at its
-- Config.SOUND_MIX volume:
--   Weapons  guns, reloads, dry clicks
--   Impacts  hits, landings, bats, blades, ricochets, bodies
--   Blasts   explosions, debris, the cannon
--   World    whooshes, magic, toys, vehicles, animals
--   UI       the kit's clicks and pops (quieter than any gun)
--   Ambient  loops in the world (the place's hum)
-- A light compressor on Effects keeps a big moment from clipping, and a big blast ducks World and
-- Ambient for a moment so it reads.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Client = script.Parent
local Settings = require(Client:WaitForChild("Settings"))

local SoundMix = {}

local DEFAULT_MIX = { Weapons = 0.95, Impacts = 0.8, Blasts = 1, World = 0.7, UI = 0.45, Ambient = 0.5 }
local MIX: { [string]: number } = (Config :: any).SOUND_MIX or DEFAULT_MIX

local BY_BANK: { [string]: string } = {}
for _, b in { "deagle", "shotgun", "shotgunPump", "dryfire", "revolver", "ak", "lmg", "minigun", "tommy", "smg", "dmr", "doubleBarrel", "sniper", "flare", "laser", "rail", "nail", "crossbow" } do
	BY_BANK[b] = "Weapons"
end
for _, b in { "hit", "land", "flesh", "slam", "bat", "golf", "chop", "saw", "clang", "ricMetal", "ricHard", "shatter", "arrow", "noodle" } do
	BY_BANK[b] = "Impacts"
end
for _, b in { "boom", "boomPop", "boomMid", "boomBig", "debris", "cannonShot", "whistle" } do
	BY_BANK[b] = "Blasts"
end

local groups: { [string]: SoundGroup } = {}

local function build()
	local effects = Settings.effects()
	if not effects:FindFirstChild("Compressor") then
		local comp = Instance.new("CompressorSoundEffect")
		comp.Name = "Compressor"
		comp.Threshold = -14
		comp.Ratio = 3
		comp.Attack = 0.01
		comp.Release = 0.25
		comp.Parent = effects
	end
	for name, volume in MIX do
		local g = effects:FindFirstChild(name)
		if not (g and g:IsA("SoundGroup")) then
			local made = Instance.new("SoundGroup")
			made.Name = name
			made.Parent = effects
			g = made
		end
		(g :: SoundGroup).Volume = volume
		groups[name] = g :: SoundGroup
	end
end

-- The group a bank's sounds play in (reloads are weapons; anything else is the world).
function SoundMix.groupFor(bank: string): SoundGroup
	if not next(groups) then
		build()
	end
	local name = BY_BANK[bank] or (if string.sub(bank, 1, 6) == "reload" then "Weapons" else "World")
	return groups[name] or Settings.effects()
end

function SoundMix.group(name: string): SoundGroup
	if not next(groups) then
		build()
	end
	return groups[name] or Settings.effects()
end

-- A big blast: World and Ambient dip for `seconds`, then come back.
local ducking = false
function SoundMix.duck(seconds: number)
	if ducking or not next(groups) then
		return
	end
	ducking = true
	for _, name in { "World", "Ambient" } do
		local g = groups[name]
		if g then
			TweenService:Create(g, TweenInfo.new(0.06), { Volume = MIX[name] * 0.45 }):Play()
			task.delay(seconds, function()
				TweenService:Create(g, TweenInfo.new(0.5), { Volume = MIX[name] }):Play()
			end)
		end
	end
	task.delay(seconds + 0.5, function()
		ducking = false
	end)
end

function SoundMix.start()
	build()
	-- The kit's clicks in the UI group (quieter than the guns).
	local ok, C = pcall(function()
		return require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIComponents")) :: any
	end)
	if ok and C then
		C.soundGroup = groups.UI
	end
end

return SoundMix
