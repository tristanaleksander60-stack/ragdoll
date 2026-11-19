--!strict
-- Round 5, phase 2b: turns a Creator Store gun (a MeshPart or a Model) into a held weapon the game
-- uses (ReplicatedStorage.N7Assets.Weapons.<id>): a "Grip" part at the origin (PrimaryPart), -Z
-- forward, +Y up, a "Body" model with every visual piece welded to the Grip, a "Tip" at the muzzle;
-- no scripts, sounds, lights or effects; nothing collides, is tapped or weighs anything (T36).
-- Run from Studio (execute_luau, Edit) with the global `JOBS` set; it returns one line per weapon.
--   JOBS = { { id = "M4", source = <Instance>, length = 4.9, flip = false, upside = false,
--              grip = 0.62, gold = false } }
--   length  the finished length in studs (the old model's: it already fits the hand)
--   flip    the muzzle is the other end; upside: up is the other way; roll: turn it 90 degrees
--   grip    where the hand closes, as a share of the length from the muzzle (0.62: a rifle)

local W = game:GetService("ReplicatedStorage"):WaitForChild("N7Assets"):WaitForChild("Weapons")
local keep = game:GetService("ServerStorage"):FindFirstChild("OldWeapons") or Instance.new("Folder")
keep.Name = "OldWeapons"
keep.Parent = game:GetService("ServerStorage")

local STRIP = { "LuaSourceContainer", "Sound", "ParticleEmitter", "Light", "Beam", "Trail", "ProximityPrompt", "ClickDetector", "Tool", "Humanoid", "Fire", "Smoke", "Sparkles", "BillboardGui", "SurfaceGui", "JointInstance", "WeldConstraint", "NoCollisionConstraint", "Attachment", "Folder", "Configuration", "ValueBase", "PostEffect", "Camera", "Atmosphere", "Sky", "Highlight" }

local function strip(root: Instance)
	for _, d in root:GetDescendants() do
		for _, class in STRIP do
			if d:IsA(class) then
				d:Destroy()
				break
			end
		end
	end
end

local results = {}
for _, job in (_G.JOBS or {}) :: { any } do
	local src = job.source :: Instance
	local body = Instance.new("Model")
	body.Name = "Body"
	local copy = src:Clone()
	-- (A Tool's handle and parts: just the parts.)
	if copy:IsA("BasePart") then
		copy.Parent = body
	else
		for _, d in copy:GetDescendants() do
			if d:IsA("BasePart") then
				d.Parent = body
			end
		end
	end
	strip(body)
	local parts = {}
	for _, d in body:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			table.insert(parts, d)
		end
	end
	if #parts == 0 then
		table.insert(results, job.id .. ": no parts")
		continue
	end
	-- The box around it and its axes: the longest is the barrel, the middle one is up.
	-- (Measured in the biggest piece's own axes: a world-aligned box of a turned gun lies.)
	local biggest, bv = nil :: BasePart?, -1
	for _, p in parts do
		local v = p.Size.X * p.Size.Y * p.Size.Z
		if v > bv then
			biggest, bv = p, v
		end
	end
	body.WorldPivot = (biggest :: BasePart).CFrame
	local cf, size = body:GetBoundingBox()
	local axes = { { v = cf.RightVector, s = size.X }, { v = cf.UpVector, s = size.Y }, { v = cf.LookVector, s = size.Z } }
	table.sort(axes, function(a, b)
		return a.s > b.s
	end)
	local long, up = axes[1].v, axes[2].v
	if job.roll then
		up = axes[3].v
	end
	-- Muzzle end: the end with less of the gun's volume (the stock and receiver are behind).
	local front, back = 0, 0
	for _, p in parts do
		local along = (p.Position - cf.Position):Dot(long)
		local vol = p.Size.X * p.Size.Y * p.Size.Z
		if along > 0 then
			front += vol
		else
			back += vol
		end
	end
	local forward = if #parts > 1 and front > back then -long else long
	if job.flip then
		forward = -forward
	end
	if job.upside then
		up = -up
	end
	local right = forward:Cross(up)
	-- The gun's own frame: -Z forward, +Y up, at the box's middle.
	local frame = CFrame.fromMatrix(cf.Position, right, up, -forward)
	-- Scale to its length.
	local scale = (job.length or axes[1].s) / axes[1].s
	-- Turn the gun so its own frame becomes the world's (-Z forward, +Y up).
	body:PivotTo(CFrame.new(cf.Position) * frame:Inverse() * body:GetPivot())
	right, up, forward = Vector3.xAxis, Vector3.yAxis, -Vector3.zAxis
	if math.abs(scale - 1) > 0.01 then
		body:ScaleTo(body:GetScale() * scale)
	end
	local len = axes[1].s * scale
	local height = axes[2].s * scale
	-- Where things go, in the gun's frame (origin: the box's middle).
	local frameNow = CFrame.fromMatrix((body:GetBoundingBox()).Position, right, up, -forward)
	local gripShare = job.grip or 0.62
	local gripLocal = Vector3.new(0, -height * 0.18, -len / 2 + len * gripShare)
	local tipLocal = Vector3.new(0, height * (job.tipY or 0.18), -len / 2)
	local model = Instance.new("Model")
	model.Name = job.id
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Size = Vector3.new(0.2, 0.2, 0.2)
	grip.Transparency = 1
	grip.CFrame = frameNow * CFrame.new(gripLocal)
	grip.Parent = model
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.1, 0.1, 0.1)
	tip.Transparency = 1
	tip.CFrame = frameNow * CFrame.new(tipLocal)
	tip.Parent = model
	body.Parent = model
	model.PrimaryPart = grip
	-- Grip at the world origin, -Z forward (as every N7 weapon is stored).
	model:PivotTo(CFrame.new())
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			if job.gold and p ~= grip and p ~= tip then
				if p:IsA("MeshPart") then
					p.TextureID = ""
				end
				for _, sa in p:GetChildren() do
					if sa:IsA("SurfaceAppearance") or sa:IsA("Decal") or sa:IsA("Texture") then
						sa:Destroy()
					end
				end
				p.Color = Color3.fromRGB(255, 196, 50)
				p.Material = Enum.Material.Foil
			end
			if p ~= grip then
				-- (A Weld on the piece, from the grip: the convention T36 and HeldService read.)
				local w = Instance.new("Weld")
				w.Part0 = grip
				w.Part1 = p
				w.C0 = grip.CFrame:ToObjectSpace(p.CFrame)
				w.Parent = p
			end
		end
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
		end
	end
	local old = W:FindFirstChild(job.id)
	if old then
		for k, v in old:GetAttributes() do
			if k ~= "AssetId" then
				model:SetAttribute(k, v)
			end
		end
		local was = keep:FindFirstChild(job.id)
		if was then
			was:Destroy()
		end
		old.Parent = keep
	end
	model:SetAttribute("Length", len)
	model:SetAttribute("AssetId", tostring(job.assetId or ""))
	model:SetAttribute("Round5", true)
	model.Parent = W
	table.insert(results, string.format("%s: %d parts, %.1f long (x%.2f)", job.id, #parts, len, scale))
end
return table.concat(results, "\n")
