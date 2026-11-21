--!strict
-- V9-NOW 23 (owner, 21 Nov 2026: "a bow on the start bar"): the Bow is on a new player's bar in Launch's place (Launch
-- the first present at 3); a short draw is slow and lobbed, a full draw fast and straight (BowMath); the server never
-- takes more draw than the time held gives; an arrow wounds by its draw.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local BowMath = require(Shared:WaitForChild("BowMath")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T190_Bow",
	timeout = 40,
	run = function(): string?
		if not Config.BOW then
			return "skipped (BOW off)"
		end
		local bow = Toys.byId.Bow
		assert(bow and bow.gun and bow.held and (bow.unlockAt or 0) == 0, "the Bow is not a gun open from the start")
		assert(table.find(Toys.defaultLoadout, "Bow") and not table.find(Toys.defaultLoadout, "Launch"), "the Bow is not on the start bar in Launch's place")
		assert(Toys.byId.Launch.unlockAt == 3, "Launch is not the first present at 3 (" .. tostring(Toys.byId.Launch.unlockAt) .. ")")
		-- The draw.
		assert(BowMath.drawOf(0) == 0 and BowMath.drawOf(BowMath.FULL_DRAW) == 1 and BowMath.drawOf(9) == 1, "the draw curve is wrong")
		local soft, hard = BowMath.launch(Vector3.new(0, 0, -1), 0.2), BowMath.launch(Vector3.new(0, 0, -1), 1)
		assert(soft.Magnitude < hard.Magnitude and soft.Unit.Y > hard.Unit.Y + 0.1 and math.abs(hard.Unit.Y) < 1e-3, "a short draw is not slower and higher than a full one")
		assert(BowMath.serverCap(0.2) < 0.4 and BowMath.serverCap(BowMath.FULL_DRAW) == 1 and BowMath.serverCap(nil) <= 0.25, "the server cap is wrong")
		local results = { "on the start bar (Launch at 3); short draw slow and high, full draw fast and flat; server caps the draw" }
		-- Server: a full draw claimed after 0.15 s of holding is cut down; a real full draw is kept; no draw seen: light.
		local p = Players:GetPlayers()[1]
		if not p then
			return table.concat(results, "; ") .. "; skipped live (no player)"
		end
		local HitService = require(Systems:WaitForChild("HitService")) :: any
		HitService.drawStartForTest(p, 0.15)
		local faked = HitService.bowDrawForTest(p, 1)
		HitService.drawStartForTest(p, BowMath.FULL_DRAW + 0.05)
		local real = HitService.bowDrawForTest(p, 1)
		local unseen = HitService.bowDrawForTest(p, 1)
		assert(faked < 0.3 and real == 1 and unseen <= 0.25, string.format("draws: faked %.2f, real %.2f, unseen %.2f", faked, real, unseen))
		table.insert(results, string.format("server draw: faked full after 0.15 s -> %.2f, held full -> %.2f, no draw seen -> %.2f; wound x%.2f..x%.2f", faked, real, unseen, BowMath.woundScale(0), BowMath.woundScale(1)))
		return table.concat(results, "; ")
	end,
}
