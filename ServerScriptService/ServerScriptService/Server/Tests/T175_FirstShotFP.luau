--!strict
-- V9-0w (owner, 21 Nov 2026: "when you shoot for the first time, send them into first person so they find
-- out they can"; Config.FIRST_SHOT_FP): the rules (Shared/FirstShotRules), the profile flags and the
-- Session_v1 notes.
--   * the first shot of a fresh profile teaches it; a taught profile (a second visit) does not; the
--     setting off does not; a phone (no way back) does not;
--   * never while guided, seated/driving, in the lab view, Build, Director or a window; then later;
--   * the pill names V on a keyboard and Select on a pad;
--   * the profile keeps fpShot (on unless off), fpStart and fpTaught; junk is cleaned;
--   * Session_v1 takes FpAuto and FpStay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Rules = require(Shared:WaitForChild("FirstShotRules")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T175_FirstShotFP",
	timeout = 10,
	run = function(): string?
		if not Config.FIRST_SHOT_FP then
			return "skipped (FIRST_SHOT_FP off)"
		end
		-- Once per profile, only with the setting on and a way back.
		assert(Rules.shouldTeach(true, true, false, true), "a fresh profile's first shot did not teach first person")
		assert(not Rules.shouldTeach(true, true, true, true), "a second visit (taught) switched again")
		assert(not Rules.shouldTeach(true, false, false, true), "it switched with the setting off")
		assert(not Rules.shouldTeach(true, true, false, false), "it switched on a phone with no way back")
		assert(not Rules.shouldTeach(false, true, false, true), "it switched with the switch off")
		-- Never in the wrong moment.
		local free = { lab = false, seated = false, building = false, director = false, window = false, guided = false, on = false }
		assert(Rules.blockedBy(free) == nil, "a free moment was blocked")
		for _, key in { "lab", "seated", "building", "director", "window", "guided", "on" } do
			local s = table.clone(free)
			s[key] = true
			assert(Rules.blockedBy(s) ~= nil, "it would switch while " .. key)
		end
		-- The pill per input.
		assert(string.find(Rules.hintFor(false, "V"), "V to switch back", 1, true), "the keyboard pill does not name V")
		assert(string.find(Rules.hintFor(true, "V"), "Select to switch back", 1, true), "the pad pill does not name Select")
		-- The profile's flags.
		local ProgressService = require(Systems:WaitForChild("ProgressService")) :: any
		local fresh = ProgressService.cleanSettings({})
		assert(fresh.fpShot == true and fresh.fpStart == false and fresh.fpTaught == false, "a fresh profile's first-person choices are wrong")
		local kept = ProgressService.cleanSettings({ fpShot = false, fpStart = true, fpTaught = true })
		assert(kept.fpShot == false and kept.fpStart == true and kept.fpTaught == true, "the first-person choices are not kept")
		local junk = ProgressService.cleanSettings({ fpShot = "no", fpStart = 1, fpTaught = "yes" })
		assert(junk.fpShot == true and junk.fpStart == false and junk.fpTaught == false, "junk first-person choices were kept")
		-- Session_v1 takes the notes (a player's record, when one plays).
		local SessionStats = require(Systems:WaitForChild("SessionStats")) :: any
		local p = game:GetService("Players"):GetPlayers()[1]
		local r = p and SessionStats.recordFor(p)
		if r then
			local before = { (r :: any).fpAuto, (r :: any).fpStay }
			;(r :: any).fpAuto, (r :: any).fpStay = nil, nil
			SessionStats.onClient(p, "FpAuto", nil)
			SessionStats.onClient(p, "FpStay", 42)
			local ok = type((r :: any).fpAuto) == "number" and (r :: any).fpStay == 42
			;(r :: any).fpAuto, (r :: any).fpStay = before[1], before[2]
			assert(ok, "Session_v1 does not take FpAuto / FpStay")
		end
		return "once per profile (fresh yes, taught no, setting off no, phone no); never guided, seated, lab, Build, Director, a window or already on; V / Select pills; fpShot/fpStart/fpTaught kept and cleaned; FpAuto/FpStay logged"
	end,
}
