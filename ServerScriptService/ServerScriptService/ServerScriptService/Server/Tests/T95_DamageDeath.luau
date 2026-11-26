--!strict
-- v4 A5 (owner): bodies die from enough hits, not only headshots. Six Popper rounds to the body
-- kill; a revive clears the count; ten punches kill; six rounds in a leg do not (limbs count less).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Anatomy = require(ReplicatedStorage.Shared.Anatomy)
local Toys = require(ReplicatedStorage.Shared.Toys)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local VitalsService = require(Systems:WaitForChild("VitalsService"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))

return {
	name = "T95_DamageDeath",
	timeout = 20,
	run = function(): string?
		local popper = Toys.byId.Blaster.wound
		local punch = Toys.byId.Punch.wound
		VitalsService.liveForTest(true)
		local result: string? = nil
		local ok, err = pcall(function()
			local body = DummyFactory.spawn(Vector3.new(-60, 3, -300))
			task.wait(0.3)
			local chestPart = body:WaitForChild("UpperTorso", 2)
			assert(chestPart and chestPart:IsA("BasePart"), "no chest")
			local chest: BasePart = chestPart
			local function shots(n: number, zone: Anatomy.Zone, power: number, blunt: boolean): number
				for i = 1, n do
					VitalsService.wound(body, chest, chest.Position, nil, power, { zone = zone, blunt = blunt, round = not blunt })
					if body:GetAttribute("Vital") == "Dead" then
						return i
					end
				end
				return n + 1
			end
			-- Rounds to the body.
			local needed = shots(12, Anatomy.zones.Stomach, popper, false)
			assert(needed >= 4 and needed <= 8, string.format("Popper rounds to the body killed after %d (want about 6)", needed))
			-- Revive: alive, count cleared.
			assert(VitalsService.reviveNow(body), "the dead body did not revive")
			local waited = os.clock()
			while body:GetAttribute("Vital") == "Dead" and os.clock() - waited < 3 do
				task.wait(0.1)
			end
			assert(body:GetAttribute("Vital") ~= "Dead" and (body:GetAttribute("Damage") == nil or body:GetAttribute("Damage") == 0), "the revive kept the damage")
			-- Punches.
			local punches = shots(16, Anatomy.zones.Stomach, punch, true)
			assert(punches >= 7 and punches <= 13, string.format("punches killed after %d (want about 10)", punches))
			VitalsService.reviveNow(body)
			local again = os.clock()
			while body:GetAttribute("Vital") == "Dead" and os.clock() - again < 3 do
				task.wait(0.1)
			end
			-- A leg: six rounds are not enough.
			local legZone: Anatomy.Zone? = nil
			for _, z in Anatomy.zones do
				if z.limb and (not legZone or z.loss < (legZone :: Anatomy.Zone).loss) then -- (the mildest limb zone: no artery)
					legZone = z
				end
			end
			assert(legZone, "no limb zone")
			local leg = shots(6, legZone :: Anatomy.Zone, popper, false)
			assert(leg > 6, "six rounds in a limb killed")
			body:Destroy()
			result = string.format("body dead after %d Popper rounds, %d punches (BODY_HP %d); revived clean; six rounds in a %s do not kill", needed, punches, Config.BODY_HP, (legZone :: Anatomy.Zone).id)
		end)
		VitalsService.liveForTest(false)
		if not ok then
			error(err, 0)
		end
		return result
	end,
}
