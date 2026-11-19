--!strict
-- Phase 1 (tech): how many extra ragdolls a player's own device simulates. Every lab's bodies are
-- owned by that lab's player (DummyControl SetNetworkOwner, for the body's whole life), so a phone
-- carries its lab's visitors and chasers itself: a phone gets fewer. The tier comes from the visit
-- record's device (SessionStats plat). Pure; T62 checks it.

local Config = require(script.Parent:WaitForChild("Config"))

local DeviceTier = {}

export type Tier = "low" | "mid" | "high"
export type Caps = { visitors: number, chasers: number }

function DeviceTier.of(plat: string?): Tier
	if plat == "phone" then
		return "low"
	elseif plat == "tablet" or plat == "console" or plat == "?" or plat == nil then
		return "mid"
	end
	return "high"
end

function DeviceTier.caps(tier: Tier): Caps
	local all = Config.DEVICE_CAPS :: any
	return all[tier] or all.mid
end

return DeviceTier
