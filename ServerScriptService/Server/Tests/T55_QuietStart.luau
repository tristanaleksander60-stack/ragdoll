--!strict
-- Phase 0 (19 Nov 2026): no interruptions in a new visit's first 90 s (the 15-60 s leave spike).
-- The client side (the egg card's calm(), tips after afterQuiet, the hint stepping aside for a
-- toast, LAB VIEW / RUN later on a phone) reads Config.QUIET_START; this checks the server's half
-- and the switches:
--   the quiet start is at least 90 s and the view card is off
--   the first egg that opens by itself comes after it, and so do the NPC Chase and the first
--   playtime gift; the like / favourite ask waits even longer
--   the client Toast module ships (it steps a long text down until it fits: checked by hand and
--   by LayoutCheck's longest-message list)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local ChaseService = require(Systems:WaitForChild("ChaseService"))
local PlaytimeGifts = require(Systems:WaitForChild("PlaytimeGifts"))
local Config = require(ReplicatedStorage.Shared.Config)

return {
	name = "T55_QuietStart",
	timeout = 3,
	run = function(): string?
		local quiet = Config.QUIET_START
		-- (20 Nov 2026, Session_v1: the median visit ended at about 120 s, so the quiet start is short
		-- and the first hooks land well before that: the HUD, a mission, a wow, the next weapons.)
		assert(type(quiet) == "number" and quiet >= 20 and quiet <= 45, "Config.QUIET_START must be 20-45 s")
		for _, key in { "EXPERIMENT_FIRST_AT", "FIRST_WOW_AT", "NEXT_UNLOCKS_AFTER" } do
			local at = (Config :: any)[key]
			assert(type(at) == "number" and at >= quiet and at <= 60, key .. " must land between the quiet start and 60 s")
		end
		assert(ChaseService.FIRST_AFTER <= 110, "the NPC Chase starts after most visits have ended")
		assert(Config.VIEW_CARD == false, "the view card should be off (Config.VIEW_CARD)")
		assert(ProgressService.FIRST_EGG_AFTER >= quiet, "the first egg opens itself inside the quiet start")
		assert(ChaseService.FIRST_AFTER > quiet, "the NPC Chase starts inside the quiet start")
		assert(PlaytimeGifts.AT[1] > quiet, "the first playtime gift comes inside the quiet start")
		local client = (StarterPlayer :: any).StarterPlayerScripts.Client
		local toast = client:FindFirstChild("Toast")
		assert(toast and toast:IsA("ModuleScript"), "Client.Toast is missing")
		return string.format("quiet %d s; first egg %d s, chase %d s, first gift %d s", quiet, ProgressService.FIRST_EGG_AFTER, ChaseService.FIRST_AFTER, PlaytimeGifts.AT[1])
	end,
}
