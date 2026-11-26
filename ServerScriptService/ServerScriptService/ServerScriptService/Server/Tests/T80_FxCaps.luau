--!strict
-- World/Feel v2 (performance guard): every device tier has a budget for lamps, flashes, particles,
-- trails, casings and the ragdolls it simulates; the budgets grow with the tier, the lab's bodies fit
-- under the ragdoll budget on every tier, the feel numbers keep light hits quiet and big stops inside
-- HitFeel's budget, every gun has its feel, and the lamp picker never lights more than its budget.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local DeviceTier = require(Shared.DeviceTier)
local FeelTuning = require(Shared.FeelTuning)
local HitFeel = require(Shared.HitFeel)
local Toys = require(Shared.Toys)
local ActiveRagdoll = require(Shared.Ragdoll.ActiveRagdoll) :: any
local RagdollConfig = require(Shared.Ragdoll.Config)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local Lab = require(Systems:WaitForChild("Lab")) :: any
local ChaseService = require(Systems:WaitForChild("ChaseService"))
local VisitorService = require(Systems:WaitForChild("VisitorService"))
local VitalsService = require(Systems:WaitForChild("VitalsService")) :: any

local FIELDS = { "lights", "flashes", "particles", "trails", "casings", "ragdolls" }

return {
	name = "T80_FxCaps",
	timeout = 5,
	run = function(): string?
		local tiers: { DeviceTier.Tier } = { "low" :: DeviceTier.Tier, "mid" :: DeviceTier.Tier, "high" :: DeviceTier.Tier }
		local caps = {}
		for _, tier in tiers do
			local c = FeelTuning.caps(tier :: any) :: any
			for _, f in FIELDS do
				assert(type(c[f]) == "number" and c[f] >= 1, tier .. " has no " .. f .. " cap")
			end
			caps[tier] = c
		end
		for _, f in FIELDS do
			assert(caps.low[f] <= caps.mid[f] and caps.mid[f] <= caps.high[f], f .. " does not grow with the tier")
		end
		-- The bodies a device simulates for its own lab fit its ragdoll budget.
		local dummies = Lab.DUMMY_COUNT or 6
		for _, tier in tiers do
			local d = DeviceTier.caps(tier :: any)
			local bodies = dummies + math.min(d.visitors, VisitorService.VISITORS) + Config.VIP_LAB_VISITORS + math.min(d.chasers, ChaseService.CHASE_MAX)
			assert(bodies <= caps[tier].ragdolls, string.format("%s simulates %d bodies (budget %d)", tier, bodies, caps[tier].ragdolls))
		end
		assert((VitalsService.MAX_CORPSES or 16) <= 16, "more corpses kept than the server's budget")
		-- The device guess.
		assert(DeviceTier.of(FeelTuning.platOf(true, false, false, 390)) == "low", "a phone is not low")
		assert(DeviceTier.of(FeelTuning.platOf(true, false, false, 820)) == "mid", "a tablet is not mid")
		assert(DeviceTier.of(FeelTuning.platOf(false, false, true, 1080)) == "mid", "a console is not mid")
		assert(DeviceTier.of(FeelTuning.platOf(false, true, false, 1080)) == "high", "a computer is not high")
		-- Feel numbers: light hits do nothing, stops stay in HitFeel's budget, trauma grows.
		assert(FeelTuning.trauma(FeelTuning.strength(10)) == 0 and FeelTuning.stop(FeelTuning.strength(10)) == 0, "a light hit shakes or stops")
		local last = -1
		for speed = 0, 200, 10 do
			local s = FeelTuning.strength(speed)
			local t = FeelTuning.trauma(s)
			assert(t >= last and t <= 1, "trauma does not grow with the hit")
			last = t
			assert(FeelTuning.stop(s) <= HitFeel.STOP_BUDGET, "a stop longer than the whole budget")
			assert(FeelTuning.burst(s, caps.low.particles) <= caps.low.particles, "a burst over a phone's cap")
		end
		assert(FeelTuning.shakeHz(30) <= 12 + 1e-6, "the shake aliases on a 30 fps phone")
		assert(FeelTuning.flop(5) == nil and FeelTuning.flop(20) and FeelTuning.flop(120), "flop tiers")
		assert(not FeelTuning.slowmoAt(Config.COMBO_SLOWMO - 1) and FeelTuning.slowmoAt(Config.COMBO_SLOWMO) and FeelTuning.slowmoAt(Config.COMBO_SLOWMO * 2), "the slow-mo beat is not on the combo steps")
		-- Every gun has its feel.
		local guns = 0
		for _, toy in Toys.list do
			if (toy :: any).gun then
				guns += 1
				local fx = FeelTuning.GUN_FX[toy.id]
				assert(fx, toy.id .. " has no GUN_FX (recoil, flash, casing)")
				assert(fx.kick >= 0 and fx.kick <= FeelTuning.KICK_MAX and fx.flash >= 0, toy.id .. ": odd feel numbers")
			end
		end
		-- The ragdoll guard leaves launches alone and keeps limbs on the body.
		assert(ActiveRagdoll.LIMB_REL_MAX and ActiveRagdoll.LIMB_REL_MAX < RagdollConfig.MAX_LINEAR_SPEED, "the limb guard is missing or looser than the body's own cap")
		-- The lamp picker (client WorldLights) never lights more than its budget, nearest first.
		local client = StarterPlayer:FindFirstChild("StarterPlayerScripts")
		local mod = client and client:FindFirstChild("WorldLights", true)
		local lampNote = "lamp picker not found"
		if mod and mod:IsA("ModuleScript") then
			local WorldLights = require(mod) :: any
			local lamps = {}
			for i = 1, 20 do
				local l = Instance.new("PointLight")
				table.insert(lamps, { light = l, position = Vector3.new(i * 5, 0, 0) })
			end
			local on = WorldLights.pick(lamps, Vector3.zero, caps.low.lights)
			local n = 0
			for l in on do
				n += 1
				assert(l == lamps[1].light or l == lamps[2].light or l == lamps[3].light or l == lamps[4].light, "a far lamp lit before a near one")
			end
			assert(n == caps.low.lights, string.format("%d lamps lit on a phone (budget %d)", n, caps.low.lights))
			for _, l in lamps do
				l.light:Destroy()
			end
			lampNote = string.format("lamps lit on a phone: %d of 20", n)
		end
		return string.format("%d guns with feel; phone %d lamps/%d particles/%d trails/%d ragdolls, pc %d/%d/%d/%d; %s", guns, caps.low.lights, caps.low.particles, caps.low.trails, caps.low.ragdolls, caps.high.lights, caps.high.particles, caps.high.trails, caps.high.ragdolls, lampNote)
	end,
}
