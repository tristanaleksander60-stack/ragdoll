--!strict
-- DropSpots (owner 27 Nov late: "der er slet ingen DROP HERE ved hver maskine når du holder en ragdoll ... kun ved 1 maskine
-- ad gangen"). Every machine, ride or station that takes a ragdoll you carry marks WHERE it goes with one invisible anchored
-- part tagged "DropSpot". Client/LabGuideClient shows the DROP HERE sign (a fixed size on screen) over the ONE nearest spot
-- within 40 studs while you carry a body (DROP_HERE_V2), and never over two at once.
-- Use: DropSpots.add(machineModel, worldPosition, "Bowling") once when the machine is built; the spot is parented to the
-- machine, so it goes with it (a hidden lab takes it off the screen too).

local CollectionService = game:GetService("CollectionService")

local DropSpots = {}

function DropSpots.add(parent: Instance, at: Vector3, name: string): BasePart
	local old = parent:FindFirstChild("DropSpot_" .. name)
	if old and old:IsA("BasePart") then
		old.Position = at
		return old
	end
	local p = Instance.new("Part")
	p.Name = "DropSpot_" .. name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.CastShadow = false
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.Position = at
	p:SetAttribute("Machine", name)
	CollectionService:AddTag(p, "DropSpot")
	p.Parent = parent
	return p
end

return DropSpots
