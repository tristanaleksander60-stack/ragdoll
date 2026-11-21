--!strict
-- V9-P3/P4/P5 (owner, 21 Nov 2026: "the best ragdoll physics on Roblox"):
--   * P4: what a body lands on answers in its own way (FeelTuning.surface): grass soft, metal a clang,
--     water no dust, a floor a slap;
--   * P3: a hurt body's muscles give: one low on blood sways on its feet, a whole one stands still;
--   * P5: a lab body launched across its lab keeps one network owner the whole flight (no
--     teleport-snap from an ownership flip).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local FeelTuning = require(Shared:WaitForChild("FeelTuning")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

local function tiltOf(m: Model): number
	local chest = m:FindFirstChild("UpperTorso")
	if not (chest and chest:IsA("BasePart")) then
		return 0
	end
	return math.deg(math.acos(math.clamp(chest.CFrame.UpVector.Y, -1, 1)))
end

return {
	name = "T185_PhysicsFeel",
	timeout = 60,
	run = function(): string?
		-- P4: the surfaces.
		assert(FeelTuning.surface("Grass") == "soft" and FeelTuning.surface("Sand") == "soft", "grass or sand is not soft")
		assert(FeelTuning.surface("Metal") == "metal" and FeelTuning.surface("DiamondPlate") == "metal", "metal does not clang")
		assert(FeelTuning.surface("Water") == "water" and FeelTuning.surface("Concrete") == "hard" and FeelTuning.surface("SmoothPlastic") == "hard", "water or a hard floor is wrong")
		if not Config.PHYSICS_V9 then
			return "surfaces checked; skipped the rest (PHYSICS_V9 off)"
		end
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil and Lab.plotIndex(p) ~= nil
		end, 20)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "surfaces checked; skipped the bodies (no player with a lab)"
		end
		local DummyFactory = require(Systems:WaitForChild("DummyFactory")) :: any
		local DummyControl = require(Systems:WaitForChild("DummyControl")) :: any
		local origin = Lab.originFor(p)
		local made: { Model } = {}
		local results = {}
		local ok, err = pcall(function()
			-- P3: hurt sways, whole stands. Two bodies the player's client simulates, side by side.
			local whole = DummyFactory.spawn(origin + Vector3.new(-14, 4, 20), origin + Vector3.new(-14, 4, 30), p)
			local hurt = DummyFactory.spawn(origin + Vector3.new(-8, 4, 20), origin + Vector3.new(-8, 4, 30), p)
			table.insert(made, whole)
			table.insert(made, hurt)
			for _, m in { whole, hurt } do
				m:SetAttribute("Home", nil) -- (they stay where they are)
			end
			TestLib.waitFor(function()
				return whole:GetAttribute("SimulatedBy") == p.UserId and hurt:GetAttribute("SimulatedBy") == p.UserId
			end, 5)
			task.wait(1.5)
			-- (Two Popper rounds' worth of wounds, straight through VitalsService: damage about 34 of 100, alive.)
			local VitalsService = require(Systems:WaitForChild("VitalsService")) :: any
			local Toys = require(Shared:WaitForChild("Toys")) :: any
			VitalsService.liveForTest(true) -- (quiet test mode holds the blood back)
			local belly = hurt:WaitForChild("LowerTorso") :: BasePart
			for _ = 1, 2 do
				VitalsService.wound(hurt, belly, belly.Position, nil, Toys.byId.Blaster.wound, { round = true })
			end
			assert(TestLib.waitFor(function()
				local d = hurt:GetAttribute("Damage")
				return type(d) == "number" and d >= 25
			end, 2), "the wounds did not show as damage: " .. tostring(hurt:GetAttribute("Damage")))
			task.wait(0.5)
			local swings = { whole = { lo = math.huge, hi = -math.huge }, hurt = { lo = math.huge, hi = -math.huge } }
			local t0 = os.clock()
			while os.clock() - t0 < 4 do
				RunService.Heartbeat:Wait()
				for name, m in { whole = whole, hurt = hurt } do
					local a = tiltOf(m)
					local s = (swings :: any)[name]
					s.lo = math.min(s.lo, a)
					s.hi = math.max(s.hi, a)
				end
			end
			local wholeSwing = swings.whole.hi - swings.whole.lo
			local hurtSwing = swings.hurt.hi - swings.hurt.lo
			assert(hurt:GetAttribute("RagdollState") == "Standing", "the hurt body fell: " .. tostring(hurt:GetAttribute("RagdollState")))
			assert(hurtSwing > 2.5 and hurtSwing > wholeSwing * 2, string.format("a hurt body does not sway (%.1f deg against a whole one's %.1f)", hurtSwing, wholeSwing))
			assert(wholeSwing < 2.5, string.format("a whole body sways %.1f deg", wholeSwing))
			table.insert(results, string.format("hurt (damage %s) sways %.1f deg, whole %.1f deg", tostring(hurt:GetAttribute("Damage")), hurtSwing, wholeSwing))
			-- P5: one owner the whole flight.
			local flyer = DummyFactory.spawn(origin + Vector3.new(10, 4, 20), origin + Vector3.new(10, 4, 30), p)
			table.insert(made, flyer)
			TestLib.waitFor(function()
				return flyer:GetAttribute("SimulatedBy") == p.UserId
			end, 5)
			task.wait(0.8)
			local pelvis = flyer:WaitForChild("LowerTorso") :: BasePart
			DummyControl.hit(flyer, pelvis, Vector3.new(30, 90, -40) * ((flyer:GetAttribute("Mass") :: number?) or 6.4), pelvis.Position)
			local flips, frames = 0, 0
			local maxY = pelvis.Position.Y
			local t1 = os.clock()
			while os.clock() - t1 < 3 do
				RunService.Heartbeat:Wait()
				frames += 1
				maxY = math.max(maxY, pelvis.Position.Y)
				local owner: Player? = nil
				pcall(function()
					owner = pelvis:GetNetworkOwner()
				end)
				if owner ~= p or flyer:GetAttribute("SimulatedBy") ~= p.UserId then
					flips += 1
				end
			end
			assert(maxY > origin.Y + 15, string.format("the launch did not fly (top %.0f studs up)", maxY - origin.Y))
			assert(flips == 0, flips .. " of " .. frames .. " frames had another owner mid-flight")
			table.insert(results, string.format("a launch %.0f studs up kept one owner all %d frames", maxY - origin.Y, frames))
		end)
		pcall(function()
			(require(Systems:WaitForChild("VitalsService")) :: any).liveForTest(false)
		end)
		for _, m in made do
			m:Destroy()
		end
		assert(ok, err)
		return "surfaces: grass soft, metal clang, water no dust, floor slap; " .. table.concat(results, "; ")
	end,
}
