--!strict
-- 21 Nov 2026 (the owner's list): every weapon its own sound; the big moments as a banner; a lab a
-- 9-year-old understands (a sign, a drop ring and a FEED button at every creature and station, and
-- the button really throws a dummy in); lamps along the lab paths.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys")) :: any
local SoundManifest = require(Shared:WaitForChild("SoundManifest")) :: any
local BannerRules = require(Shared:WaitForChild("BannerRules")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")
local LabGuide = require(Systems:WaitForChild("LabGuide")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

-- Tools whose own sound lives in FxController's WEAPON_HITS (a bat's crack, an axe's chop) or is the
-- punch itself (the shared thud is the Punch Kit).
local HAND_BANKS = { Punch = true, Bat = true, Golf = true, Axe = true, Chainsaw = true, Crowbar = true }

return {
	name = "T147_SoundsGuide",
	timeout = 45,
	run = function(): string?
		-- 1. Every weapon its own sound.
		local usedBanks: { [string]: string } = {}
		local tools = 0
		for _, toy in Toys.list do
			tools += 1
			local bank: string? = nil
			if toy.gun then
				local g = SoundManifest.GUNS[toy.id]
				assert(g, toy.id .. " (a gun) has no GUNS entry")
				bank = g.fire
			elseif SoundManifest.TOOLS[toy.id] then
				bank = SoundManifest.TOOLS[toy.id].bank
			else
				assert(HAND_BANKS[toy.id], toy.id .. " has no sound of its own")
			end
			if bank then
				assert(SoundManifest.SOUNDS[bank] and #SoundManifest.SOUNDS[bank] > 0, toy.id .. "'s bank " .. bank .. " is empty")
				assert(usedBanks[bank] == nil, toy.id .. " shares its sound with " .. tostring(usedBanks[bank]))
				usedBanks[bank] = toy.id
			end
		end
		for id, s in SoundManifest.TOOLS do
			assert(Toys.byId[id], "TOOLS names an unknown tool " .. id)
			assert(s.on == "Hit" or s.on == "Place", id .. " plays on an unknown event " .. tostring(s.on))
		end

		-- 2. The banner's lines.
		local s1 = BannerRules.of("SURPRISE! Rocket Rain")
		assert(s1 and s1.title == "SURPRISE!" and s1.sub == "ROCKET RAIN", "SURPRISE! is not a banner")
		local s2 = BannerRules.of("\u{1F3AF} BULLSEYE!")
		assert(s2 and s2.title == "BULLSEYE!", "BULLSEYE! with its emoji is not a banner")
		assert(BannerRules.of("Walking again") == nil, "a plain line became a banner")
		assert(BannerRules.ENTER >= 0.18 and BannerRules.ENTER <= 0.3 and BannerRules.EXIT < BannerRules.ENTER, "the banner's timing is off the vault's range")

		-- 3. The lab guide and the paths, in the first lab.
		if not Config.LAB_GUIDE then
			return string.format("%d tools, each its own sound; banners ok; guide off", tools)
		end
		local guide: Instance? = nil
		local paths: Instance? = nil
		assert(TestLib.waitFor(function()
			local pg = Workspace:FindFirstChild("Playground")
			local lab = pg and pg:FindFirstChild("Lab1")
			guide = lab and lab:FindFirstChild("Guide")
			paths = lab and lab:FindFirstChild("Paths")
			return guide ~= nil and paths ~= nil
		end, 20), "the lab has no guide or no paths")
		local rings, prompts, signs = 0, 0, 0
		for _, d in (guide :: Instance):GetDescendants() do
			if d:IsA("BasePart") and d.Name == LabGuide.TAG then
				rings += 1
				assert(not d.CanCollide and not d.CanQuery, "a drop ring blocks something")
			elseif d:IsA("ProximityPrompt") then
				prompts += 1
				assert(#d.ActionText > 0 and #d.ActionText <= 8 and #d.ObjectText > 0, "a guide button's words are off: " .. d.ActionText)
			elseif d:IsA("BillboardGui") and d.Name == "GuideSign" then
				signs += 1
				assert(d.Size.X.Offset == 0 and d.Size.X.Scale > 0, "a guide sign is a pixel card")
			end
		end
		assert(rings >= 12 and prompts == rings, string.format("%d rings and %d buttons (want 12 each: 9 creatures, 3 stations)", rings, prompts))
		assert(signs >= 9, string.format("%d creature signs (want 9)", signs))
		local lamps = 0
		if Config.PATHS_V3 then
			for _, d in (paths :: Instance):GetChildren() do
				if d.Name == "PathLampPost" then
					lamps += 1
				end
			end
			assert(lamps >= 4, string.format("%d lamp posts along the lab paths", lamps))
		end

		-- 4. The button throws a dummy in: an arc that lands where it aims, and a real toss.
		local from, to = Vector3.new(0, 5, 0), Vector3.new(40, 2, 30)
		local v = LabGuide.arc(from, to)
		local g = Workspace.Gravity
		local t = math.clamp(Vector3.new(40, 0, 30).Magnitude / LabGuide.FLIGHT_SPEED, 0.8, 1.5)
		local landed = from + v * t - Vector3.new(0, 0.5 * g * t * t, 0)
		assert((landed - to).Magnitude < 0.1, "the toss arc misses its target by " .. (landed - to).Magnitude)
		local player = Players:GetPlayers()[1]
		if not player then
			return string.format("%d tools, each its own sound; banners ok; %d rings/buttons, %d signs, %d lamps; toss not run (no player)", tools, rings, signs, lamps)
		end
		local before = LabGuide.tossedForTest()
		local point = (guide :: Instance):FindFirstChild("GuidePoint", true)
		local aim = if point and point:IsA("BasePart") then point.Position else to
		local okToss = LabGuide.toss(player, player, aim)
		assert(okToss and LabGuide.tossedForTest() == before + 1, "the FEED button threw no dummy")
		return string.format("%d tools, each its own sound; banners ok; %d rings/buttons, %d signs, %d lamps; a dummy tossed", tools, rings, signs, lamps)
	end,
}
