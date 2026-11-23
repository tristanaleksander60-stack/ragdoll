--!strict
-- PhoneDiet (23 Nov 2026, owner: "fix the fps and the load time at the start on phones"): what a touch device without a
-- keyboard does not draw. No sun shadows, no full-screen effects (bloom, sun rays, blur), no world lamps, and the
-- smallest dressing (solid-looking bits no one can touch, under TINY studs) is not drawn. Pictures only: nothing that
-- collides, takes a ray or moves changes. Kept up when ZoneLighting sets its look again.

local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PhoneDiet = {}
PhoneDiet.TINY = 0.9 -- studs: the biggest side of a bit that is left out
PhoneDiet.ROOTS = { "Playground", "Labs", "PlazaDressing", "MapBooths", "Landscape" }

function PhoneDiet.wanted(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function effect(d: Instance)
	if d:IsA("BloomEffect") or d:IsA("SunRaysEffect") or d:IsA("DepthOfFieldEffect") then
		local function off()
			if d.Enabled then
				d.Enabled = false
			end
		end
		off()
		d:GetPropertyChangedSignal("Enabled"):Connect(off)
	end
end

local function trim(d: Instance)
	if d:IsA("SpotLight") or d:IsA("SurfaceLight") or d:IsA("PointLight") then
		d.Enabled = false
	elseif d:IsA("SurfaceGui") then
		d.MaxDistance = if d.MaxDistance > 0 then math.min(d.MaxDistance, 80) else 80 -- (a sign further off cannot be read on a phone)
	elseif d:IsA("BillboardGui") then
		d.MaxDistance = if d.MaxDistance > 0 and d.MaxDistance < math.huge then math.min(d.MaxDistance, 80) else 80
	elseif d:IsA("ParticleEmitter") then
		d.Rate *= 0.5
	elseif d:IsA("Beam") then
		d.Segments = math.min(d.Segments, 4)
	elseif d:IsA("BasePart") and d.Anchored and not d.CanCollide and not d.CanQuery and not d.CanTouch and d.Transparency < 1 then
		local s = d.Size
		if math.max(s.X, s.Y, s.Z) < PhoneDiet.TINY then
			d.LocalTransparencyModifier = 1
		end
	end
end

local function watch(root: Instance)
	root.DescendantAdded:Connect(trim)
	for i, d in root:GetDescendants() do
		trim(d)
		if i % 1500 == 0 then
			task.wait()
		end
	end
end

function PhoneDiet.start()
	if not PhoneDiet.wanted() then
		return
	end
	local function noShadows()
		if Lighting.GlobalShadows then
			Lighting.GlobalShadows = false
		end
	end
	noShadows()
	Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(noShadows)
	for _, d in Lighting:GetChildren() do
		effect(d)
	end
	Lighting.ChildAdded:Connect(effect)
	Workspace.ChildAdded:Connect(function(c)
		if table.find(PhoneDiet.ROOTS, c.Name) then
			watch(c)
		end
	end)
	for _, name in PhoneDiet.ROOTS do
		local root = Workspace:FindFirstChild(name)
		if root then
			task.spawn(watch, root)
		end
	end
end

return PhoneDiet
