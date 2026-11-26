--!strict
-- Surface finishes (10 Nov 2026, the owner: "much more Steam-like, not plastic"): real PBR materials
-- instead of flat SmoothPlastic. Each finish is a base material plus a MaterialVariant made in
-- MaterialService (AssistantMaterials: generated textures, saved in the place file). A missing
-- variant just shows the base material, so the game never breaks without the place's variants.

local Finish = {}

export type Kind = "Painted" | "Brushed" | "Floor" | "Rubber" | "Wall"

local KINDS: { [Kind]: { material: Enum.Material, variant: string, reflectance: number } } = {
	Painted = { material = Enum.Material.Metal, variant = "PaintedSteel", reflectance = 0 }, -- tinted by Color
	Brushed = { material = Enum.Material.Metal, variant = "BrushedSteel", reflectance = 0.3 }, -- (also chrome on meshes)
	Floor = { material = Enum.Material.Concrete, variant = "LabFloorTiles", reflectance = 0 },
	Rubber = { material = Enum.Material.Rubber, variant = "SafetyRubber", reflectance = 0 },
	Wall = { material = Enum.Material.Plaster, variant = "LabWallPanels", reflectance = 0 },
}

function Finish.apply(p: BasePart, kind: Kind)
	local k = KINDS[kind]
	p.Material = k.material
	p.MaterialVariant = k.variant
	p.Reflectance = k.reflectance
end

-- What a builder's plain default (SmoothPlastic, or an untextured Metal) becomes.
function Finish.forMaterial(p: BasePart, material: Enum.Material?)
	if material == nil or material == Enum.Material.SmoothPlastic or material == Enum.Material.Plastic or material == Enum.Material.Metal then
		Finish.apply(p, "Painted")
	else
		p.Material = material
	end
end

return Finish
