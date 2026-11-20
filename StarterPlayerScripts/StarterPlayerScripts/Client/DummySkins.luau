--!strict
-- The dummies' sculpted mannequin bodies, on this screen only (10 Nov 2026, the owner: dummies that
-- look like the big Steam ragdoll games, no gaps at the joints, holes where they are hit).
--
-- The server's dummy is the engine's R15 block body (simulated, hit and jointed as before) marked
-- Mannequin. Here each limb gets the sculpted mesh of ReplicatedStorage.DummySkin worn over it, in
-- the limb's own colour, a little longer than the block so neighbouring limbs overlap (no gaps at
-- elbows, knees, hips or shoulders), and the block is hidden on this screen only
-- (LocalTransparencyModifier: everything that asks the part itself still sees it). Nothing of this
-- crosses the network. A person in the crowd (Mannequin off) keeps the plain body under its clothes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DummySkins = {}

DummySkins.OVERLAP = 1.12 -- each skin this much longer than its limb: the joints close up

local template: Instance? = nil
local skins: { [BasePart]: MeshPart } = {}

-- The sculpted surface over a limb, if it has one (BulletHoles puts holes on it).
function DummySkins.skinOf(part: BasePart): MeshPart?
	local s = skins[part]
	if s and s.Parent then
		return s
	end
	return nil
end

local function strip(model: Model)
	local folder = model:FindFirstChild("Skins")
	if folder then
		folder:Destroy()
	end
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") then
			skins[d] = nil
			d.LocalTransparencyModifier = 0
		end
	end
end

local function dress(model: Model)
	local source = template
	if not source or model:FindFirstChild("Skins") then
		return
	end
	-- (Worn, like a hat: the ragdoll leaves it out of the body it simulates.)
	local folder = Instance.new("Model")
	folder.Name = "Skins"
	folder:SetAttribute("Worn", true)
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "Head" and d.Name ~= "HumanoidRootPart" then
			local src = source:FindFirstChild(d.Name, true)
			if src and src:IsA("MeshPart") then
				local skin = src:Clone()
				skin:ClearAllChildren()
				skin.Name = d.Name
				skin.Anchored = false
				skin.CanCollide = false
				skin.CanQuery = false
				skin.CanTouch = false
				skin.Massless = true
				skin.TextureID = ""
				skin.Material = Enum.Material.SmoothPlastic
				skin.Reflectance = 0.04
				skin.Color = d.Color
				skin.Size = Vector3.new(d.Size.X, d.Size.Y * DummySkins.OVERLAP, d.Size.Z)
				skin.CFrame = d.CFrame
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = d
				weld.Part1 = skin
				weld.Parent = skin
				skin.Parent = folder
				skins[d] = skin
				d.LocalTransparencyModifier = 1
				-- (A limb recoloured later, a frozen one, keeps its skin the same colour.)
				d:GetPropertyChangedSignal("Color"):Connect(function()
					skin.Color = d.Color
				end)
			end
		end
	end
	folder.Parent = model
	-- (V6-5: a body inside a lab creature (the plant, the egg, the washer, the vacuum) is hidden on
	-- every screen through its skins too: the server sets MachineHidden on the model.)
	local function machineHide()
		local hidden = model:GetAttribute("MachineHidden") == true
		for _, s in folder:GetChildren() do
			if s:IsA("BasePart") then
				s.LocalTransparencyModifier = if hidden then 1 else 0
			end
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and not skins[d] and not d:IsDescendantOf(folder) and d.Name ~= "HumanoidRootPart" then
				d.LocalTransparencyModifier = if hidden then 1 else 0
			end
		end
	end
	model:GetAttributeChangedSignal("MachineHidden"):Connect(machineHide)
	-- (A body that goes for good takes its entries with it: the table never keeps dead limbs.)
	model.Destroying:Once(function()
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") then
				skins[d] = nil
			end
		end
	end)
end

local followed: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function follow(model: Instance)
	-- (Once each: a lab hidden and shown again brings its dummies back through ChildAdded.)
	if not model:IsA("Model") or followed[model] then
		return
	end
	followed[model] = true
	local function update()
		if model:GetAttribute("Mannequin") == true then
			dress(model)
		else
			strip(model)
		end
	end
	model:GetAttributeChangedSignal("Mannequin"):Connect(update)
	-- (The limbs arrive with the model; a beat later is enough for all of them.)
	task.defer(update)
end

function DummySkins.start()
	template = ReplicatedStorage:WaitForChild("DummySkin", 15)
	if not template then
		return -- (no template in the place: the block bodies stay as they are)
	end
	local function watch(folder: Instance)
		folder.ChildAdded:Connect(follow)
		for _, m in folder:GetChildren() do
			follow(m)
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		watch(dummies)
	end
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Dummies" then
			watch(child)
		end
	end)
end

return DummySkins
