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

local TONE = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).DUMMY_TONE

local DummySkins = {}

DummySkins.OVERLAP = 1.0 -- (V10, owner: "the body must not overlap in several places": each skin its limb's own length; was 1.12)
DummySkins.LEG_REACH = 0 -- (V10: was 0.22: the thigh tops stuck out round at the hips; the hips reach down instead, HIP_REACH)
DummySkins.HIP_REACH = 0.3 -- (V10: the hips this much longer, downward over the tops of the thighs)
DummySkins.DETAILS = true -- V7-4: crash-test joint rings, belt and test targets on the mannequins
DummySkins.TARGET = "rbxassetid://91578612138787" -- the yellow and black crash-test target (art/dummy/target.png)
-- V9-0o (Config.DUMMY_TONE): matte skins, no shine in the bright sun.
DummySkins.MATERIAL = if TONE then TONE.material else Enum.Material.SmoothPlastic -- (V10, owner: "exactly the same as their head", not fabric: the head's material, DUMMY_TONE)
DummySkins.REFLECTANCE = if TONE then (TONE.reflectance or 0) else 0.04 -- (V10: glossy)

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
				skin.Material = DummySkins.MATERIAL
				skin.Reflectance = DummySkins.REFLECTANCE
				for _, sa in skin:GetChildren() do
					if sa:IsA("SurfaceAppearance") then
						sa:Destroy() -- (V10: a surface appearance would bring its own shine back)
					end
				end
				skin.Color = d.Color
				-- (V10, owner: "legs and hips must hang together"): the thighs reach up into the hips (LEG_REACH of their
				-- length, upward only, so the knees stay where they are).
				local up = if d.Name == "LeftUpperLeg" or d.Name == "RightUpperLeg" then DummySkins.LEG_REACH elseif d.Name == "LowerTorso" then -DummySkins.HIP_REACH else 0
				skin.Size = Vector3.new(d.Size.X, d.Size.Y * (DummySkins.OVERLAP + math.abs(up)), d.Size.Z)
				skin.CFrame = d.CFrame * CFrame.new(0, d.Size.Y * up / 2, 0)
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = d
				weld.Part1 = skin
				weld.Parent = skin
				skin.Parent = folder
				skins[d] = skin
				d.LocalTransparencyModifier = 1
				-- (A limb recoloured later, a frozen one, keeps its skin the same colour.)
				local recolour = d:GetPropertyChangedSignal("Color"):Connect(function()
					skin.Color = d.Color
				end)
				skin.Destroying:Once(function()
					recolour:Disconnect() -- (stripped and dressed again: no pile of old connections)
				end)
			end
		end
	end
	-- V7-4 (the owner: "every ragdoll must look better, details and all"): the white mannequin gets
	-- crash-test details: dark joint rings at the elbows, knees and ankles,
	-- and the yellow and black test targets on both sides of the head and on
	-- the chest. All of it welded to the limbs on this screen only (no network, no physics).
	if DummySkins.DETAILS then
		local DARK = Color3.fromRGB(56, 60, 68)
		local function ring(limbName: string, top: boolean, thick: number, grow: number)
			local limb = model:FindFirstChild(limbName)
			if not limb or not limb:IsA("BasePart") then
				return
			end
			local d = math.min(limb.Size.X, limb.Size.Z) * grow
			local r = Instance.new("Part")
			r.Name = "JointRing"
			local at = limb.CFrame * CFrame.new(0, (if top then 1 else -1) * (limb.Size.Y / 2 - thick / 2), 0)
			if limbName == "LowerTorso" then
				-- (The belt follows the waist's own shape: a band, not a round disc on an oval waist.)
				r.Size = Vector3.new(limb.Size.X * grow, thick, limb.Size.Z * grow)
				r.CFrame = at
			else
				r.Shape = Enum.PartType.Cylinder
				r.Size = Vector3.new(thick, d, d)
				r.CFrame = at * CFrame.Angles(0, 0, math.rad(90))
			end
			r.Color = DARK
			r.Material = DummySkins.MATERIAL
			r.Reflectance = if TONE then 0 else 0.06
			r.CanCollide, r.CanQuery, r.CanTouch, r.Massless, r.Anchored = false, false, false, true, false
			r.CastShadow = false
			local w = Instance.new("WeldConstraint")
			w.Part0 = limb
			w.Part1 = r
			w.Parent = r
			r.Parent = folder
		end
		-- (V9-NOW 8, owner 21 Nov 2026: "a black thing through the arms": the rings are sized on the hidden limb
		-- blocks, wider than the sculpted grey skin, so at the elbow they stuck out as a dark bar. The grey matte
		-- dummies (DUMMY_TONE) wear none; the old white mannequins keep them.)
		for _, side in if TONE then {} else { "Left", "Right" } do
			ring(side .. "LowerArm", true, 0.14, 1.16) -- elbow
			ring(side .. "LowerLeg", true, 0.16, 1.14) -- knee
			ring(side .. "Foot", true, 0.12, 1.12) -- ankle
		end
		-- (No belt: the waist block is wider than the sculpted waist, so any belt stuck out like a tray.)
		-- The test targets: thin plates with the target picture.
		local function mark(limbName: string, offset: CFrame, size: number)
			if true then
				return -- (V10, owner: "remove the yellow and black logo on the ragdolls")
			end
			local limb = model:FindFirstChild(limbName)
			if not limb or not limb:IsA("BasePart") then
				return
			end
			local p = Instance.new("Part")
			p.Name = "TestMark"
			p.Size = Vector3.new(size, size, 0.04)
			p.Transparency = 1
			p.CFrame = limb.CFrame * offset
			p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.Anchored = false, false, false, true, false
			local decal = Instance.new("Decal")
			decal.Texture = DummySkins.TARGET
			decal.Face = Enum.NormalId.Front
			decal.Parent = p
			local w = Instance.new("WeldConstraint")
			w.Part0 = limb
			w.Part1 = p
			w.Parent = p
			p.Parent = folder
		end
		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			-- (V10, owner: "the yellow-black logo hangs a little off the body, shots do not show through it": on the
			-- round head, inside its box, and just behind the bullet holes, BulletHoles.SKIN_FIT 0.86.)
			local hx = head.Size.X / 2 * 0.8
			mark("Head", CFrame.new(-hx, 0.05, 0) * CFrame.Angles(0, math.rad(90), 0), math.min(head.Size.Y, head.Size.Z) * 0.62)
			mark("Head", CFrame.new(hx, 0.05, 0) * CFrame.Angles(0, math.rad(-90), 0), math.min(head.Size.Y, head.Size.Z) * 0.62)
		end
		local chest = model:FindFirstChild("UpperTorso")
		if chest and chest:IsA("BasePart") then
			mark("UpperTorso", CFrame.new(chest.Size.X * 0.22, chest.Size.Y * 0.12, -(chest.Size.Z / 2 * 0.8)), chest.Size.Y * 0.32) -- (V10: on the chest, behind the holes)
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
			-- (0.37.19, owner: "the yellow and black marks on the head come up before the ragdoll": the crash-test
			-- marks are decals on see-through parts, which the modifier does not hide; they go with the body.)
			for _, d in s:GetDescendants() do
				if d:IsA("Decal") then
					d.Transparency = if hidden then 1 else 0
				end
			end
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and not skins[d] and not d:IsDescendantOf(folder) and d.Name ~= "HumanoidRootPart" then
				d.LocalTransparencyModifier = if hidden then 1 else 0
			end
			-- (0.37.6, owner: "the face goes up before the ragdoll": the face is a SurfaceGui, which the modifier
			-- does not hide; it goes with the body.)
			if d:IsA("SurfaceGui") then
				d.Enabled = not hidden
			end
		end
	end
	model:GetAttributeChangedSignal("MachineHidden"):Connect(machineHide)
	if model:GetAttribute("MachineHidden") == true then
		machineHide() -- (dressed while already inside a machine: hidden at once)
	end
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
