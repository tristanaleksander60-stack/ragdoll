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

-- (24 Nov 2026, fps on phones, tablets and consoles: a car far off is drawn without its inside and its smallest pieces.)
-- (The truck alone is a million triangles up close, in pieces of some 9 000 each, and has no lighter version: on every
-- device now; a computer keeps the pieces longer.)
PhoneDiet.CAR_FAR = if UserInputService.KeyboardEnabled then 75 else 42
PhoneDiet.CAR_SMALL = if UserInputService.KeyboardEnabled then 1.6 else 2.6
local INSIDE = { "inter", "leather", "seat", "steer", "engine", "dash", "king_ranch", "mirror_inner", "bulb" }
local function carDiet()
	local pieces: { [Model]: { BasePart } } = {}
	local hidden: { [Model]: boolean } = {}
	while true do
		task.wait(0.5)
		local camera = Workspace.CurrentCamera
		local ground = Workspace:FindFirstChild("Playground")
		if not camera or not ground then
			continue
		end
		for car in pieces do
			if not car.Parent then
				pieces[car], hidden[car] = nil, nil
			end
		end
		for _, lab in ground:GetChildren() do
			local cars = lab:FindFirstChild("Vehicles")
			for _, car in if cars then cars:GetChildren() else {} do
				if not car:IsA("Model") then
					continue
				end
				local far = (car:GetPivot().Position - camera.CFrame.Position).Magnitude > PhoneDiet.CAR_FAR
				if far == (hidden[car] == true) then
					continue
				end
				hidden[car] = far
				if far then
					local list: { BasePart } = {}
					for _, d in car:GetDescendants() do
						if d:IsA("BasePart") and d.Transparency < 0.9 and d.LocalTransparencyModifier == 0 then
							local small = math.max(d.Size.X, d.Size.Y, d.Size.Z) < PhoneDiet.CAR_SMALL and d:FindFirstChild("WheelWeld") == nil
							local name = string.lower(d.Name)
							for _, word in INSIDE do
								small = small or string.find(name, word, 1, true) ~= nil
							end
							if small then
								d.LocalTransparencyModifier = 1
								table.insert(list, d)
							end
						end
					end
					pieces[car] = list
				else
					for _, d in pieces[car] or {} do
						d.LocalTransparencyModifier = 0
					end
					pieces[car] = nil
				end
			end
		end
	end
end

local function screenDiet()
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
end

function PhoneDiet.start()
	task.spawn(carDiet)
	if not PhoneDiet.wanted() then
		-- (LAG-FREE 2 item 10, Config.LAGFREE_IPAD: an iPad with a keyboard is still a tablet (the server's Device), and
		-- its big screen pays most for the full-screen extras: no Bloom, SunRays, depth of field or shadows there either)
		local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
		if Config.LAGFREE_IPAD and UserInputService.TouchEnabled then
			task.spawn(function()
				local lp = game:GetService("Players").LocalPlayer
				local dev: any = nil
				for _ = 1, 20 do
					dev = lp:GetAttribute("Device")
					if dev ~= nil then
						break
					end
					task.wait(0.5)
				end
				if dev == "tablet" or dev == "phone" then
					screenDiet()
				end
			end)
		end
		return
	end
	screenDiet()
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
