--!strict
-- V9-0ac (owner, 21 Nov 2026: "they should not fall from being shot, they should fall when they die, e.g. by a
-- pistol"; Config.SHOT_FLINCH), fix round 1:
--   * the rule: every round flinches a living body (never a Stumble, never down); a leg round limps it;
--   * live, through HitService (the way a shot arrives): 3 fast Popper rounds in the chest, a 3-round AK
--     burst, both legs: the body is never down while alive; the 4th Popper round knocks it out (blood under
--     Anatomy.UNCONSCIOUS_AT) and it falls away from the shot;
--   * the damage: Popper drops it in 4-6 body rounds; a headshot, a Sniper and a Golden Deagle body round
--     at once; a newcomer's boost (HitService.boostFor) only for a newcomer under FIRST_HITS, and it drops
--     a dummy within 3 rounds;
--   * a big force (a blast) still ragdolls a standing body at once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

local function isDown(m: Model): boolean
	local s = m:GetAttribute("RagdollState")
	return s == "Ragdoll" or s == "Out"
end

return {
	name = "T181_FlinchNotFall",
	timeout = 90,
	run = function(): string?
		if not Config.SHOT_FLINCH then
			return "skipped (SHOT_FLINCH off)"
		end
		-- The rule: every round flinches.
		local rig: any = { model = nil }
		local now = os.clock()
		for _, case in { { "arm", 1.0 }, { "leg", 1.0 }, { "head", 1.0 }, { "torso", 0.5 }, { "torso", 1.6 }, { "torso", 3.0 } } do
			local r = ActiveRagdoll.gunReaction(rig, case[1], case[2], now, 1)
			assert(r == "Flinch", string.format("a %s round (power %.1f) gave %s, not a flinch", case[1], case[2], tostring(r)))
		end
		assert(ActiveRagdoll.gunReaction(rig, "leg", 1.0, now, -1) == "Flinch", "both legs shot knocked it down")
		assert(type(rig.limpUntil) == "number" and rig.limpUntil > now + 3, "a leg round does not make it limp on")
		-- The newcomer's boost.
		local HitService = require(Systems:WaitForChild("HitService")) :: any
		assert(HitService.boostFor(true, 0) == Config.NEWCOMER_DAMAGE and HitService.boostFor(true, (Config.FIRST_HITS or 3) - 1) == Config.NEWCOMER_DAMAGE, "a newcomer's first hits are not boosted")
		assert(HitService.boostFor(true, Config.FIRST_HITS or 3) == nil and HitService.boostFor(false, 0) == nil, "the boost reaches past FIRST_HITS or a player who is no newcomer")
		-- Bodies of their own, server-simulated, each on its own spot of the bench.
		local VitalsService = require(Systems:WaitForChild("VitalsService")) :: any
		local Bench = require(script.Parent:WaitForChild("Lib"):WaitForChild("PhysicsBench")) :: any
		Bench.build()
		local spot = 0
		local function fresh(): Model
			spot += 1
			return Bench.body(Bench.ORIGIN + Vector3.new((spot - 4) * 9, 0, 0))
		end
		local function part(m: Model, name: string): BasePart
			return m:WaitForChild(name) :: BasePart
		end
		local function wound(m: Model, partName: string, toyId: string, boost: number?)
			local p = part(m, partName)
			VitalsService.wound(m, p, p.Position, nil, Toys.byId[toyId].wound, { round = true, boost = boost })
		end
		-- A round the way a shot arrives (from 12 studs in front of the body).
		local function shoot(m: Model, partName: string, toyId: string)
			local p = part(m, partName)
			local from = p.Position + p.CFrame.LookVector * 12
			HitService.applyToy(Toys.byId[toyId], p, p.Position, (p.Position - from).Unit)
		end
		-- Fires `n` rounds `gap` s apart and watches the body the whole time (and `after` s more): whether
		-- it was ever down while alive.
		local function burst(m: Model, partNames: { string }, toyId: string, n: number, gap: number, after: number): boolean
			local downAlive = false
			local t0 = os.clock()
			local fired = 0
			while os.clock() - t0 < n * gap + after do
				if fired < n and os.clock() - t0 >= fired * gap then
					fired += 1
					shoot(m, partNames[(fired - 1) % #partNames + 1], toyId)
				end
				RunService.Heartbeat:Wait()
				if isDown(m) and m:GetAttribute("Vital") == "Alive" then
					downAlive = true
				end
			end
			return downAlive
		end
		local results = {}
		VitalsService.liveForTest(true) -- (kills count in this test)
		local ok, err = pcall(function()
			-- Live: 3 fast Popper rounds in the chest.
			local a = fresh()
			task.wait(0.8)
			assert(not burst(a, { "UpperTorso" }, "Blaster", 3, 0.12, 1.0), "3 fast Popper rounds knocked a living body down")
			assert(a:GetAttribute("Vital") == "Alive", "3 Popper body rounds took it out: " .. tostring(a:GetAttribute("Vital")))
			-- The 4th takes it out: it falls, away from the shot.
			local pelvis = part(a, "LowerTorso")
			local before = pelvis.Position
			local chest = part(a, "UpperTorso")
			local away = -chest.CFrame.LookVector
			shoot(a, "UpperTorso", "Blaster")
			local fell = false
			local t0 = os.clock()
			while os.clock() - t0 < 2 do
				RunService.Heartbeat:Wait()
				if isDown(a) then
					fell = true
				end
			end
			assert(a:GetAttribute("Vital") ~= "Alive" and fell, "the 4th Popper round did not drop it (Vital " .. tostring(a:GetAttribute("Vital")) .. ")")
			local moved = (pelvis.Position - before):Dot(away)
			assert(moved > 0.3, string.format("it did not fall away from the shot (%.2f studs that way)", moved))
			table.insert(results, string.format("3 fast Popper rounds: up; the 4th: out (%s), down, %.1f studs away from the shot", tostring(a:GetAttribute("Vital")), moved))
			-- Live: a 5-round AK burst, then both legs.
			local b = fresh()
			task.wait(0.8)
			assert(not burst(b, { "UpperTorso" }, "AK", 3, 0.11, 1.0), "an AK burst knocked a living body down")
			local c = fresh()
			task.wait(0.8)
			assert(not burst(c, { "RightUpperLeg", "LeftUpperLeg" }, "Blaster", 2, 0.3, 1.2), "rounds in both legs knocked a living body down")
			table.insert(results, "an AK burst and both legs: still up")
			-- The damage alone.
			local d = fresh()
			task.wait(0.3)
			local shots = 0
			while d:GetAttribute("Vital") ~= "Dead" and shots < 8 do
				shots += 1
				wound(d, "UpperTorso", "Blaster")
			end
			assert(shots >= 4 and shots <= 6, "Popper body rounds to drop it: " .. shots)
			table.insert(results, "Popper: dead after " .. shots .. " body rounds")
			for _, case in { { "Head", "Blaster" }, { "UpperTorso", "Sniper" }, { "UpperTorso", "GoldenDeagle" } } do
				local m = fresh()
				task.wait(0.2)
				wound(m, case[1], case[2])
				assert(m:GetAttribute("Vital") == "Dead", string.format("a %s round in the %s did not kill at once", case[2], case[1]))
			end
			local e = fresh()
			task.wait(0.2)
			local n = 0
			while e:GetAttribute("Vital") ~= "Dead" and n < 6 do
				n += 1
				wound(e, "UpperTorso", "Blaster", HitService.boostFor(true, 0))
			end
			assert(n <= 3, "a newcomer's dummy took " .. n .. " rounds")
			table.insert(results, "newcomer " .. n)
			-- A blast: a standing body (on its own spot) goes down at once.
			local f = fresh()
			task.wait(0.8)
			local Blasts = require(Systems:WaitForChild("Blasts")) :: any
			Blasts.explode(f:GetPivot().Position + Vector3.new(5, -2, 0), nil, nil)
			local t1 = os.clock()
			local down = false
			while os.clock() - t1 < 1.5 do
				RunService.Heartbeat:Wait()
				if isDown(f) then
					down = true
					break
				end
			end
			assert(down, "a blast did not knock a standing body down")
		end)
		VitalsService.liveForTest(false)
		Bench.clear()
		assert(ok, err)
		return "every round flinches (a leg limps on); " .. table.concat(results, "; ") .. "; a headshot, a Sniper and a Golden Deagle body round kill at once; the boost only for a newcomer under FIRST_HITS; a blast downs at once"
	end,
}
