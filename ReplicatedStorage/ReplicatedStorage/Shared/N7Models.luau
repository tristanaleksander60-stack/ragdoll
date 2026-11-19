--!strict
-- The real models (round 2, N7): where they are kept, and the only way code takes one out.
--
-- They live in the place file only (Script Sync carries scripts, not models):
--   ReplicatedStorage.N7Assets.Weapons.<tool id>  every client draws them (bar, catalog, egg card)
--   ReplicatedStorage.N7Assets.Fx.<name>          what clients animate themselves (the Mega Bomb)
--   ServerStorage.N7Assets.Props.<name>           room and plaza props (only the server places them;
--   ServerStorage.N7Assets.Wear.<name>            the crowd's clothes)    phones never download these)
--
-- Every model came from the Creator Store or Studio's AI generation. They were cleaned when they
-- were kept, and every copy is cleaned again here: only what draws a model survives (parts,
-- meshes, textures, joints, attachments, lights), never a script, a package link that could
-- update itself, a sound, a click or proximity prompt, a GUI, a value or a remote. A model that is
-- missing is said once in the log (the place was saved without it); callers fall back to a built
-- stand-in.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local N7Models = {}

export type Kind = "Weapons" | "Fx" | "Props" | "Wear"

-- What a kept model may hold. Anything else is taken out of every copy.
N7Models.ALLOWED = {
	"Model",
	"Folder",
	"BasePart", -- Part, MeshPart, WedgePart, UnionOperation...
	"DataModelMesh", -- SpecialMesh, BlockMesh, CylinderMesh
	"Decal",
	"Texture",
	"SurfaceAppearance",
	"Attachment",
	"Weld",
	"WeldConstraint",
	"Light", -- PointLight, SpotLight, SurfaceLight
}

function N7Models.allowed(inst: Instance): boolean
	for _, class in N7Models.ALLOWED do
		if inst:IsA(class) then
			return true
		end
	end
	return false
end

-- Takes out everything that does not draw the model. Returns how many were taken out. (A seat in
-- a chair stays a part of the chair, but nobody can be sat in it.)
function N7Models.clean(root: Instance): number
	local removed = 0
	for _, d in root:GetDescendants() do
		if d.Parent and not N7Models.allowed(d) then
			d:Destroy()
			removed += 1
		elseif d:IsA("Seat") or d:IsA("VehicleSeat") then
			(d :: any).Disabled = true
		end
	end
	return removed
end

local function folderOf(kind: Kind): Instance?
	local root: Instance? = nil
	if kind == "Props" or kind == "Wear" then
		if RunService:IsServer() then
			root = game:GetService("ServerStorage"):FindFirstChild("N7Assets")
		end
	else
		root = ReplicatedStorage:FindFirstChild("N7Assets")
	end
	return root and root:FindFirstChild(kind)
end

local told: { [string]: boolean } = {}

-- The kept model (not a copy: never change it), or nil.
function N7Models.source(kind: Kind, name: string): Model?
	local folder = folderOf(kind)
	local found = folder and folder:FindFirstChild(name)
	if found and found:IsA("Model") then
		return found
	end
	local key = kind .. "." .. name
	if not told[key] then
		told[key] = true
		warn(string.format("[N7Models] no %s model '%s' in this place (saved without its models?): the built stand-in is used", kind, name))
	end
	return nil
end

-- A clean copy of a kept model, or nil.
function N7Models.clone(kind: Kind, name: string): Model?
	local source = N7Models.source(kind, name)
	if not source then
		return nil
	end
	local copy = source:Clone()
	N7Models.clean(copy)
	return copy
end

return N7Models
