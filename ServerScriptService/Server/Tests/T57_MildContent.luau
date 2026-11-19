--!strict
-- Phase 0 (19 Nov 2026): mild content by default, every owner choice one Config switch away:
--   SEVERING off; BLOOD "off" makes every hit stars / sparks / dust (HitFxConfig "Stylised")
--   TOY_NAMES: no real-gun nicknames on any weapon card, the ids (saves, products) unchanged
--   MILD_TEXT: the hit line names a body region, never an organ
--   no weapon text promises cut-off limbs or blood

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config) :: any
local Toys = require(Shared.Toys) :: any
local HitFxConfig = require(Shared.HitFxConfig)
local Anatomy = require(Shared.Anatomy) :: any

local REAL = { "G17", "Glock", "Deagle", "AK", "M4", "Carbine", "SMG", "LMG", "RPG", "Uzi" }
local ORGANS = { "brain", "heart", "aorta", "lung", "liver", "kidney", "intestine", "stomach", "spine", "artery", "carotid", "stump", "skull" }

return {
	name = "T57_MildContent",
	timeout = 3,
	run = function(): string?
		assert(Config.SEVERING == false, "SEVERING should be off by default (phase 0)")
		assert(Config.BLOOD == "off" or Config.BLOOD == "purple", "Config.BLOOD must be \"off\" or \"purple\"")
		if Config.BLOOD == "off" then
			assert(HitFxConfig.MaxStyle == "Stylised", "BLOOD off but the ceiling is " .. HitFxConfig.MaxStyle)
			assert(HitFxConfig.effectiveStyle(nil) == "Stylised" and HitFxConfig.effectiveStyle("CartoonBlood") == "Stylised", "a player can still get blood")
		end
		local renamed = 0
		if Config.TOY_NAMES then
			for _, toy in Toys.list do
				for _, word in REAL do
					local text = " " .. toy.label .. " " .. toy.short .. " "
					assert(not string.find(text, "[^%a]" .. word .. "[^%a]"), toy.id .. " still shows the real name " .. word .. ": " .. toy.label .. " / " .. toy.short)
				end
			end
			for id in Toys.TOY_NAMES do
				assert(Toys.byId[id], "a renamed id is gone (saves would break): " .. id)
				renamed += 1
			end
			assert(not string.find(string.lower(Toys.byId.Blaster.blurb), "real"), "the first gun still says it is real")
		end
		for _, toy in Toys.list do
			local blurb = string.lower(toy.blurb)
			assert(not string.find(blurb, "blood") and not string.find(blurb, "limbs off") and not string.find(blurb, "tears"), toy.id .. ": " .. toy.blurb)
		end
		if Config.MILD_TEXT then
			for id in Anatomy.zones do
				local label = string.lower(Anatomy.mildLabel(id))
				for _, organ in ORGANS do
					assert(not string.find(label, organ), id .. " reads as " .. label)
				end
			end
			assert(Anatomy.mildLabel("LeftFemoral") == "Left leg" and Anatomy.mildLabel("Heart") == "Chest", "region names")
		end
		return string.format("severing off, blood %s, %d toy names, hit line by body region", Config.BLOOD, renamed)
	end,
}
