--!strict
-- Round 4, M10 acceptance test. Every weapon in N7Assets.Weapons must sit naturally in the
-- avatar's hand: its Grip part must be within 0.3 studs of at least one Body mesh piece so the
-- hand closes on the weapon instead of the weapon floating above the fist.
--
-- The signed-distance check is against the mesh piece's oriented bounding box (its local Size),
-- so a weapon whose Grip is INSIDE a mesh piece scores 0. A weapon whose Grip hangs away from
-- every piece scores the gap.
--
-- The test does NOT weld weapons to a live character: it reads the source models directly from
-- ReplicatedStorage.N7Assets.Weapons, which is what HeldService clones at attach time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Toys = require(ReplicatedStorage.Shared.Toys)

local MAX_DRIFT = 0.3 -- studs: the acceptance floor

-- Signed distance from a world point to a part's OBB (0 if inside).
local function gripToPart(gripPos: Vector3, piece: BasePart): number
	local localPos = piece.CFrame:PointToObjectSpace(gripPos)
	local half = piece.Size / 2
	local dx = math.max(0, math.abs(localPos.X) - half.X)
	local dy = math.max(0, math.abs(localPos.Y) - half.Y)
	local dz = math.max(0, math.abs(localPos.Z) - half.Z)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

return {
	name = "T70_GripAlignment",
	timeout = 5,
	run = function(): string?
		local weapons = ReplicatedStorage:FindFirstChild("N7Assets") and (ReplicatedStorage.N7Assets :: Instance):FindFirstChild("Weapons")
		assert(weapons and weapons:IsA("Folder"), "N7Assets.Weapons is missing")
		local checked = 0
		local worst = 0
		local worstName = ""
		for _, toy in Toys.list do
			local model = weapons:FindFirstChild(toy.id)
			assert(model and model:IsA("Model"), toy.id .. ": no weapon model in N7Assets.Weapons")
			local grip = (model :: Model).PrimaryPart
			assert(grip and grip.Name == "Grip", toy.id .. ": no Grip PrimaryPart")
			local best = math.huge
			for _, p in (model :: Model):GetDescendants() do
				if p:IsA("BasePart") and p ~= grip and p.Name ~= "Tip" then
					local d = gripToPart((grip :: BasePart).Position, p :: BasePart)
					if d < best then
						best = d
					end
				end
			end
			assert(best <= MAX_DRIFT, string.format("%s: Grip is %.3f studs from the nearest body piece (must be <= %.2f)", toy.id, best, MAX_DRIFT))
			if best > worst then
				worst = best
				worstName = toy.id
			end
			checked += 1
		end
		return string.format("%d weapon grips within %.2f studs of body mesh (worst: %s at %.3f)", checked, MAX_DRIFT, worstName, worst)
	end,
}
