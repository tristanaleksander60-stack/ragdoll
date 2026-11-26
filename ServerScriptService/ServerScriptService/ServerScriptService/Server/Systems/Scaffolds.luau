--!strict
-- Scaffolds (24 Nov 2026, owner: the scaffolds lagged, "just a few wooden posts round about"): some single posts of three
-- pieces each in every lab. Anchored at rest. A shot takes off the piece it hit and what is over it; so does a car, a
-- thrown ragdoll, a running player or a blast. After a while they stand again. Knockables tells of shots, blasts, RESET.

local Workspace = game:GetService("Workspace")

local Knockables = require(script.Parent:WaitForChild("Knockables")) :: any

local Scaffolds = {}

Scaffolds.POSTS = 9
Scaffolds.PIECES = 3
Scaffolds.HEIGHT = 2.6 -- one piece
Scaffolds.WIDE = 1
Scaffolds.TOUCH_SPEED = 19
Scaffolds.BACK_AFTER = 14
Scaffolds.KNOCKS = { 9126254743, 9120871246 } -- (Pro Sound Effects)

type Post = { parts: { BasePart }, homes: { CFrame }, loose: { boolean }, hitAt: number }
local posts: { Post } = {}

local function back(post: Post)
	for i, p in post.parts do
		if post.loose[i] and p.Parent then
			p.Anchored = true
			p.CFrame = post.homes[i]
			post.loose[i] = false
		end
	end
end

-- Piece `from` and all over it come off, the lowest one the hardest.
local function breakAt(post: Post, from: number, velocity: Vector3)
	if post.loose[from] then
		return
	end
	for i = from, #post.parts do
		local p = post.parts[i]
		if not post.loose[i] then
			post.loose[i] = true
			p.Anchored = false
			pcall(function()
				p:SetNetworkOwner(nil)
			end)
			p.AssemblyLinearVelocity = velocity * (if i == from then 1 else 0.45) + Vector3.new(0, 3, 0)
			p.AssemblyAngularVelocity = Vector3.yAxis:Cross(velocity) * 0.2
		end
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. Scaffolds.KNOCKS[math.random(#Scaffolds.KNOCKS)]
	s.Volume = 0.8
	s.RollOffMaxDistance = 100
	s.Parent = post.parts[from]
	s:Play()
	game:GetService("Debris"):AddItem(s, 4)
	local at = os.clock()
	post.hitAt = at
	task.delay(Scaffolds.BACK_AFTER, function()
		if post.hitAt == at then
			back(post)
		end
	end)
end

local function build(folder: Instance, floor: Vector3)
	local post: Post = { parts = {}, homes = {}, loose = {}, hitAt = 0 }
	local model = Instance.new("Model")
	model.Name = "WoodPost"
	for i = 1, Scaffolds.PIECES do
		local p = Instance.new("Part")
		p.Name = "WoodPost"
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(Scaffolds.HEIGHT, Scaffolds.WIDE, Scaffolds.WIDE)
		p.CFrame = CFrame.new(floor + Vector3.new(0, (i - 0.5) * Scaffolds.HEIGHT, 0)) * CFrame.Angles(0, 0, math.rad(90))
		p.Color = Color3.fromRGB(150 + i * 8, 108 + i * 8, 66 + i * 6)
		p.Material = Enum.Material.Wood
		p.Anchored = true
		p.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.6, 0.12)
		p.Parent = model
		post.parts[i], post.homes[i], post.loose[i] = p, p.CFrame, false
		p.Touched:Connect(function(other: BasePart)
			if not post.loose[i] and not other.Anchored and other.AssemblyLinearVelocity.Magnitude >= Scaffolds.TOUCH_SPEED then
				local v = other.AssemblyLinearVelocity
				breakAt(post, i, v.Unit * math.min(v.Magnitude * 0.6, 34))
			end
		end)
	end
	model.Parent = folder
	table.insert(posts, post)
	model.Destroying:Connect(function()
		post.hitAt = -1
		local at = table.find(posts, post)
		if at then
			table.remove(posts, at)
		end
	end)
end

local function onShot(point: Vector3, from: Vector3)
	for _, post in posts do
		for i, p in post.parts do
			if not post.loose[i] then
				local l = p.CFrame:PointToObjectSpace(point)
				if math.abs(l.X) <= p.Size.X / 2 + 0.2 and Vector2.new(l.Y, l.Z).Magnitude <= Scaffolds.WIDE / 2 + 0.5 then
					local way = point - from
					breakAt(post, i, (if way.Magnitude > 0.1 then way.Unit else Vector3.xAxis) * 18)
					return
				end
			end
		end
	end
end

local function onBlast(center: Vector3, radius: number)
	for _, post in posts do
		for i, p in post.parts do
			local gap = p.Position - center
			if not post.loose[i] and gap.Magnitude < radius then
				breakAt(post, i, (if gap.Magnitude > 0.1 then gap.Unit else Vector3.yAxis) * 34)
				break
			end
		end
	end
end

local function onReset(center: Vector3, radius: number)
	for _, post in posts do
		if (post.homes[1].Position - center).Magnitude <= radius then
			back(post)
		end
	end
end

-- The posts of one lab: on free ground round it, well apart.
function Scaffolds.buildLab(folder: Instance, origin: Vector3)
	local skip: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = skip
	local over = OverlapParams.new()
	over.FilterType = Enum.RaycastFilterType.Exclude
	over.FilterDescendantsInstances = skip
	local made: { Vector3 } = {}
	for _, r in { 44, 62, 78, 53, 70 } do
		for k = 0, 8 do
			if #made >= Scaffolds.POSTS then
				return
			end
			local a = (k + r * 0.13) / 9 * math.pi * 2
			local at = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local ok = true
			for _, m in made do
				ok = ok and (m - at).Magnitude > 24
			end
			local hit = if ok then Workspace:Raycast(at + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), ray) else nil
			if hit and math.abs(hit.Position.Y - at.Y) < 2 and hit.Normal.Y > 0.96 then
				local free = true
				for _, p in Workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 5, 0)), Vector3.new(5, 8, 5), over) do
					free = free and p.Transparency >= 1 and not p.CanCollide
				end
				if free then
					build(folder, hit.Position)
					table.insert(made, at)
				end
			end
		end
	end
end

table.insert(Knockables.listeners, { shot = onShot, blast = onBlast, reset = onReset })

return Scaffolds
