--!strict
-- V9-0i: the models the SHOP turns in 3D (Shared/ShopArt.MODELS: the crate, the big red button, the
-- pets, the trampoline, the fan, the spider) live in ServerStorage.V3Assets, which no screen can see.
-- At start a clean, anchored, non-colliding copy of each goes to ReplicatedStorage.ShopModels, about
-- 300 small parts in all; Client/ShopShowcase clones them into the cards' ViewportFrames. A role the
-- place has not got is simply left out (the card shows its picture).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ShopArt = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopArt")) :: any

local ShopModels = {}

ShopModels.FOLDER = "ShopModels"

-- Only what draws: parts, meshes, decals and textures (no scripts, sounds, prompts, lights, joints).
local KEEP = { "BasePart", "DataModelMesh", "Decal", "Texture", "SurfaceAppearance", "Model", "Folder" }
local function keep(d: Instance): boolean
	for _, c in KEEP do
		if d:IsA(c) then
			return true
		end
	end
	return false
end

function ShopModels.start()
	local folder = ReplicatedStorage:FindFirstChild(ShopModels.FOLDER)
	if folder then
		folder:Destroy()
	end
	local made = Instance.new("Folder")
	made.Name = ShopModels.FOLDER
	local source = ServerStorage:FindFirstChild("V3Assets")
	for _, role in ShopArt.MODELS do
		local src = source and source:FindFirstChild(role)
		if src and src:IsA("Model") then
			local copy = src:Clone()
			for _, d in copy:GetDescendants() do
				if not keep(d) then
					d:Destroy()
				end
			end
			for _, d in copy:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
					d.CastShadow = false
				end
			end
			copy.Name = role
			copy.Parent = made
		end
	end
	made.Parent = ReplicatedStorage
end

return ShopModels
