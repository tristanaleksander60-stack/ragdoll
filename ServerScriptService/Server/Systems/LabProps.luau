--!strict
-- LabProps (RUN 2.7): the real models drawn over LabOwnerMap's plain-part machines (the gyro, the Tesla coil, the
-- archery target, the shredder). Moved out of LabOwnerMap because Studio caps one script at 200000 characters. Each
-- function is called from the spot in LabOwnerMap where that machine is built, with the same names it used there.

local LabProps = {}

function LabProps.gyro(into: Instance, gc: Vector3)
	-- (GYRO_MODELS, RUN 2.7: the gyro stood on a grey concrete disc between two plain blocks, with a plain red cylinder
	-- for its button. Now a real ride platform (a round steel deck with a yellow railing and a gate: V3Assets
	-- "GyroPlatform"), a striped control booth with its desk and red button (V3Assets "GyroBooth") at the old button,
	-- and painted steel stands. The old pad and button stay as the invisible gameplay parts (the pad's spot, the prompt).)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).GYRO_MODELS then
		local assets = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
		local function put(name: string, at: CFrame): Model?
			local src = assets and assets:FindFirstChild(name)
			if not (src and src:IsA("Model")) then
				return nil
			end
			local m = src:Clone()
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanQuery = false
					d.CanTouch = false
				elseif d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			m:PivotTo(at)
			m.Parent = into
			return m
		end
		local deck = put("GyroPlatform", CFrame.new(gc + Vector3.new(0, -0.6, 0)) * CFrame.Angles(0, math.pi, 0))
		if deck then
			for _, d in deck:GetDescendants() do
				if d:IsA("BasePart") then
					d.CanCollide = false -- (the railing is drawn only: ragdolls are thrown in and out over it)
				end
			end
			for _, n in { "GyroPad" } do
				for _, p in into:GetChildren() do
					if p.Name == n and p:IsA("BasePart") and (p.Position - gc).Magnitude < 2 then
						p.Transparency = 1
					end
				end
			end
		end
		local booth = put("GyroBooth", CFrame.lookAt(gc + Vector3.new(0, 0, -16), gc + Vector3.new(0, 0, -1)))
		if booth then
			for _, p in into:GetChildren() do
				if p.Name == "GyroButton" and p:IsA("BasePart") and (p.Position - (gc + Vector3.new(0, 1, -12))).Magnitude < 1 then
					p.Transparency = 1
				end
			end
		end
		for _, p in into:GetChildren() do
			if p.Name == "GyroStand" and p:IsA("BasePart") and (p.Position - gc).Magnitude < 12 then
				p.Shape = Enum.PartType.Cylinder
				p.Size = Vector3.new(10, 1.4, 1.4)
				p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, 0, math.rad(90))
				p.Color = Color3.fromRGB(246, 186, 40)
				p.Material = Enum.Material.SmoothPlastic
				p.Reflectance = 0.1
			end
		end
	end
end

function LabProps.tesla(into: Instance, tc: Vector3)
	-- (TESLA_MODEL, RUN 2.7: the Tesla coil was a dark block, an orange cylinder and a grey disc. Now a real Tesla coil (a
	-- metal base, a tall copper-wound column and a horizontal toroid ring: V3Assets "TeslaTower", a Studio-generated mesh);
	-- the old three parts stay as the invisible gameplay parts (the base's spot, the top's sparks).)
	do
		local src = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).TESLA_MODEL
			and game:GetService("ServerStorage"):FindFirstChild("V3Assets") and game:GetService("ServerStorage").V3Assets:FindFirstChild("TeslaTower")
		if src then
			local tower = src:Clone()
			for _, d in tower:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanQuery = false
					d.CanTouch = false
				elseif d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			tower:PivotTo(CFrame.new(tc))
			tower.Parent = into
			for _, p in into:GetChildren() do
				if (p.Name == "TeslaBase" or p.Name == "TeslaColumn" or p.Name == "TeslaTop") and p:IsA("BasePart") and (Vector3.new(p.Position.X, tc.Y, p.Position.Z) - tc).Magnitude < 2 then
					p.Transparency = 1
					p.CastShadow = false
				end
			end
		end
	end
end

function LabProps.archery(into: Instance, tg: Vector3)
	-- (ARCHERY_MODEL, RUN 2.7: the target was 2 sticks and 4 flat coloured cylinders. Now a real archery target (a straw boss
	-- with a printed ring face on a wooden easel: V3Assets "ArcheryTarget", a Studio-generated mesh), facing the same way;
	-- the old legs and faces stay as the invisible parts the hit checks and TargetRun look for.)
	do
		local src = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ARCHERY_MODEL
			and game:GetService("ServerStorage"):FindFirstChild("V3Assets") and game:GetService("ServerStorage").V3Assets:FindFirstChild("ArcheryTarget")
		if src then
			local t = src:Clone()
			for _, d in t:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
				elseif d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			t:PivotTo(CFrame.lookAt(tg, tg - Vector3.zAxis))
			t.Parent = into
			for _, p in into:GetChildren() do
				if (p.Name == "TargetLeg" or p.Name == "TargetFace") and p:IsA("BasePart") and (Vector3.new(p.Position.X, tg.Y, p.Position.Z) - tg).Magnitude < 4 then
					p.Transparency = 1
					p.CastShadow = false
				end
			end
		end
	end
end

function LabProps.shredder(into: Instance, sp: Vector3, PW: number)
	-- (SHREDDER_MODEL, RUN 2.7: the rollers were two plain grey cylinders and the lever a yellow cube with a stick. Now a
	-- real toothed shredder pair (V3Assets "ShredderRollers") down in the pit and a real control box with its lever and
	-- red button (V3Assets "ShredderControl") at the lever; the old parts are invisible (the button keeps its prompt).)
	do
		local cfgOn = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).SHREDDER_MODEL
		local V = game:GetService("ServerStorage"):FindFirstChild("V3Assets")
		local function put(name: string, at: CFrame, size: Vector3): boolean
			local src = cfgOn and V and V:FindFirstChild(name)
			if not (src and src:IsA("Model")) then
				return false
			end
			local m = src:Clone()
			local _, ls = m:GetBoundingBox()
			local k = Vector3.new(size.X / ls.X, size.Y / ls.Y, size.Z / ls.Z)
			local pv = m:GetPivot()
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					local o = pv:ToObjectSpace(d.CFrame)
					d.Size = d.Size * k
					d.CFrame = pv * CFrame.new(o.Position * k) * o.Rotation
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
				elseif d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			m:PivotTo(at)
			m.Parent = into
			return true
		end
		local function hide(names: { [string]: boolean }, near: Vector3, r: number)
			for _, p in into:GetChildren() do
				if names[p.Name] and p:IsA("BasePart") and (p.Position - near).Magnitude < r then
					p.Transparency = 1
					p.CastShadow = false
				end
			end
		end
		local rolled = false
		for _, dz in { -2.4, 2.4 } do -- (the model is one toothed roller with its bearings: one at each roller)
			rolled = put("ShredderRollers", CFrame.new(sp + Vector3.new(0, -3, dz)) * CFrame.Angles(math.rad(if dz < 0 then 0 else 15), 0, 0), Vector3.new(PW - 2, 4.6, 4.6)) or rolled
		end
		if rolled then
			hide({ ShredderRoller = true }, sp + Vector3.new(0, -3, 0), 6)
		end
		local lv = sp + Vector3.new(PW / 2 + 5, 0, 0)
		-- (its front, with the red button, faces the pit)
		if put("ShredderControl", CFrame.new(lv + Vector3.new(0, 3.25, 0)) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(3, 6.5, 3)) then
			hide({ ShredderLeverBox = true, ShredderLever = true }, lv + Vector3.new(0, 3, 0), 4)
		end
	end
end

return LabProps
