--!strict
-- V9-0ac (owner, 21 Nov 2026: "they should not fall from being shot, they should fall when they die, e.g. by a
-- pistol"; Config.SHOT_FLINCH):
--   * a round never knocks a living body down: arm, leg, head and light body rounds flinch, strong body
--     rounds stagger (ActiveRagdoll.gunReaction);
--   * the damage drops it: 3 Popper body rounds leave it alive, the 6th kills; a headshot kills at once;
--     a Sniper body round kills at once; a newcomer's dummy drops within 3 rounds;
--   * a big force (a blast) still ragdolls a standing body at once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T181_FlinchNotFall",
	timeout = 60,
	run = function(): string?
		if not Config.SHOT_FLINCH then
			return "skipped (SHOT_FLINCH off)"
		end
		-- The reaction: never down from a round.
		local rig = { model = nil }
		local now = os.clock()
		for _, case in { { "arm", 1.0 }, { "leg", 1.0 }, { "head", 1.0 }, { "torso", 0.5 }, { "torso", 1.6 }, { "torso", 3.0 } } do
			local r = ActiveRagdoll.gunReaction(rig, case[1], case[2], now, 1)
			assert(r ~= "Ragdoll", string.format("a %s round (power %.1f) knocked a living body down", case[1], case[2]))
		end
		assert(ActiveRagdoll.gunReaction(rig, "torso", 1.6, now, 1) == "Stumble", "a strong body round did not stagger it")
		assert(ActiveRagdoll.gunReaction(rig, "leg", 1.0, now, 1) == "Flinch" and ActiveRagdoll.gunReaction(rig, "leg", 1.0, now, -1) == "Flinch", "both legs shot knocked it down")
		-- The damage: a dummy of its own, server-simulated, high over the map.
		local VitalsService = require(Systems:WaitForChild("VitalsService")) :: any
		local Bench = require(script.Parent:WaitForChild("Lib"):WaitForChild("PhysicsBench")) :: any
		Bench.build()
		local function fresh(): Model
			return Bench.body(Bench.ORIGIN + Vector3.new(0, 0, 0))
		end
		local function shoot(m: Model, partName: string, toyId: string, by: Player?, boost: number?)
			local part = m:WaitForChild(partName) :: BasePart
			local toy = Toys.byId[toyId]
			VitalsService.wound(m, part, part.Position, by, toy.wound, { round = true, boost = boost })
		end
		local results = {}
		VitalsService.liveForTest(true) -- (kills count in this test)
		local ok, err = pcall(function()
			-- Popper: 3 body rounds, still alive; dead by the 6th.
			local a = fresh()
			task.wait(0.3)
			for _ = 1, 3 do
				shoot(a, "UpperTorso", "Blaster")
			end
			assert(a:GetAttribute("Vital") ~= "Dead", "3 Popper body rounds killed it")
			local shots = 3
			while a:GetAttribute("Vital") ~= "Dead" and shots < 8 do
				shots += 1
				shoot(a, "UpperTorso", "Blaster")
			end
			assert(a:GetAttribute("Vital") == "Dead" and shots >= 4 and shots <= 6, "Popper body rounds to drop it: " .. shots)
			table.insert(results, "Popper " .. shots)
			-- A headshot: dead at once.
			local b = fresh()
			task.wait(0.2)
			shoot(b, "Head", "Blaster")
			assert(b:GetAttribute("Vital") == "Dead", "a headshot did not kill at once")
			-- A Sniper body round: dead at once.
			local c = fresh()
			task.wait(0.2)
			shoot(c, "UpperTorso", "Sniper")
			assert(c:GetAttribute("Vital") == "Dead", "a Sniper body round did not kill at once")
			-- A newcomer's rounds: within 3.
			local d = fresh()
			task.wait(0.2)
			local n = 0
			while d:GetAttribute("Vital") ~= "Dead" and n < 6 do
				n += 1
				shoot(d, "UpperTorso", "Blaster", nil, Config.NEWCOMER_DAMAGE)
			end
			assert(n <= 3, "a newcomer's dummy took " .. n .. " rounds")
			table.insert(results, "newcomer " .. n)
			-- A blast: a standing body goes down at once.
			local e = fresh()
			task.wait(0.6)
			local Blasts = require(Systems:WaitForChild("Blasts")) :: any
			Blasts.explode(e:GetPivot().Position + Vector3.new(5, -2, 0), nil, nil)
			local t0 = os.clock()
			local down = false
			while os.clock() - t0 < 1.5 do
				RunService.Heartbeat:Wait()
				if e:GetAttribute("RagdollState") == "Ragdoll" or e:GetAttribute("RagdollState") == "Out" then
					down = true
					break
				end
			end
			assert(down, "a blast did not knock a standing body down")
		end)
		VitalsService.liveForTest(false)
		Bench.clear()
		assert(ok, err)
		return "rounds never knock a living body down (arm, leg, head, both legs, light and strong body); dropped by the damage: " .. table.concat(results, ", ") .. " rounds; a headshot and a Sniper body round at once; a blast at once"
	end,
}
