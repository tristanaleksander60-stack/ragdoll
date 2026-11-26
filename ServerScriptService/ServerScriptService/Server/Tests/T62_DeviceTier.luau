--!strict
-- Phase 1 (tech): a device simulates its own lab's bodies, so a phone gets fewer extra ragdolls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeviceTier = require(ReplicatedStorage.Shared.DeviceTier)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local ChaseService = require(Systems:WaitForChild("ChaseService"))
local VisitorService = require(Systems:WaitForChild("VisitorService"))

return {
	name = "T62_DeviceTier",
	timeout = 3,
	run = function(): string?
		assert(DeviceTier.of("phone") == "low" and DeviceTier.of("pc") == "high" and DeviceTier.of("tablet") == "mid" and DeviceTier.of(nil) == "mid", "tiers")
		local low, mid, high = DeviceTier.caps("low"), DeviceTier.caps("mid"), DeviceTier.caps("high")
		assert(low.visitors <= mid.visitors and mid.visitors <= high.visitors, "visitors do not grow with the tier")
		assert(low.chasers <= mid.chasers and mid.chasers <= high.chasers, "chasers do not grow with the tier")
		assert(high.visitors <= VisitorService.VISITORS and high.chasers <= ChaseService.CHASE_MAX, "a cap over the service's own most")
		assert(low.chasers >= ChaseService.CHASE_MIN, "a phone's chase would be too small to start")
		return string.format("phone %d/%d, mid %d/%d, pc %d/%d (visitors/chasers)", low.visitors, low.chasers, mid.visitors, mid.chasers, high.visitors, high.chasers)
	end,
}
