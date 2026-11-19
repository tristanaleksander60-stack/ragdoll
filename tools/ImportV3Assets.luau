--!strict
-- v3 (19 Nov 2026): fetches the hand-picked Creator Store models (docs/V3_ASSETS.md) into
-- ServerStorage.V3Assets.<Role>, ready for the game code (Server/Systems/V3Assets).
-- Run it in Studio, in EDIT mode (not Play): paste into the Command Bar, or run it with the Studio
-- MCP's run_code. Then SAVE the place: the models live only in the place file.
--
-- For each pick it:
--   1. loads the model (game:GetObjects, Studio only);
--   2. MALWARE PASS: deletes every Script, LocalScript and ModuleScript, plus anything hidden
--      (names with spaces or invisible characters that are scripts, Sounds set to play, remote
--      events), and prints what it removed;
--   3. anchors every part and turns off CastShadow on tiny bits;
--   4. sets the pivot to the bottom middle of its bounding box, with the "Yaw" attribute from the
--      list (degrees that turn its front to -Z);
--   5. puts it in ServerStorage.V3Assets under its role name (an older one is replaced).
-- A pick that fails to load is reported and skipped (its backup id is tried).

local ServerStorage = game:GetService("ServerStorage")

-- single: the asset is a pack of several models: keep only its first model (the PC session may
-- change which one by name: childName).
type Pick = { role: string, id: number, backup: number?, yaw: number?, single: boolean?, childName: string? }

-- Filled from docs/V3_ASSETS.md (role = the name the game code asks for).
local PICKS: { Pick } = {
	-- PICKS_START (docs/V3_ASSETS.md, 19 Nov 2026; yaw: fill in after looking, so the front faces -Z)
	-- Used by the game code now:
	{ role = "Cannon", id = 4558839272, backup = 18435394013, yaw = -90 },
	{ role = "Car", id = 6418239833, backup = 6418234850, yaw = 0, single = true, childName = "Sedan (white)" }, -- Roblox Sedan (its A-Chassis scripts go)
	{ role = "MonsterTruck", id = 1222491712, backup = 6418225759, yaw = 180 },
	{ role = "Gorilla", id = 10594810401, backup = 1421609150, yaw = 90 },
	{ role = "Bull", id = 5035521514, backup = 11162919482, yaw = 90 }, -- (a bison: no real bull exists)
	{ role = "BigFan", id = 104680325645946, backup = 290574315 },
	{ role = "Rocket", id = 220664616, backup = 5380747922 },
	{ role = "Barrel", id = 9021582812, backup = 14452389275 },
	{ role = "Crate", id = 8458216263, backup = 3272950683, single = true },
	{ role = "Bench", id = 185280084, backup = 14874085291 },
	{ role = "StreetLamp", id = 11146095708, backup = 404475960 },
	{ role = "Cone", id = 23153487, backup = 12094920818 },
	{ role = "Fence", id = 9083814252, backup = 4831942116 },
	{ role = "TreeRound", id = 3755594081 },
	{ role = "TreePine", id = 11664016667, backup = 5392132809, single = true },
	{ role = "Bush", id = 8647777369, backup = 8344171779 },
	{ role = "Rock", id = 1192366796, backup = 8421400545, single = true },
	-- For the maps (Phase B) and later:
	{ role = "Tank", id = 1379706428, backup = 11036026075 }, -- (check the hull for insignia)
	{ role = "SlideTower", id = 3699248235, backup = 5706899551 },
	{ role = "BoxingRing", id = 10218162623, backup = 1404734428 },
	{ role = "CastleTower", id = 899477954, backup = 101559450428915 },
	{ role = "Train", id = 302873713, backup = 10570360936 },
	{ role = "Rails", id = 925820578, backup = 388174618, single = true },
	{ role = "Barrier", id = 8325588430, backup = 2766525411 },
	{ role = "Trampoline", id = 7829441554, backup = 89910882365911 },
	{ role = "BigButton", id = 14087568246, backup = 15240203293 },
	{ role = "TreePalm", id = 1567799120, backup = 10562894034, single = true, childName = "Coconut Tree 1" },
	{ role = "Mountain", id = 10606824320, backup = 8761896930 },
	{ role = "BrickWall", id = 1425120075, backup = 104053043839965 },
	-- PICKS_END
}

local folder = ServerStorage:FindFirstChild("V3Assets")
if not folder then
	local f = Instance.new("Folder")
	f.Name = "V3Assets"
	f.Parent = ServerStorage
	folder = f
end
assert(folder)

local function load(id: number): Model?
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. id)
	end)
	if not ok or type(objects) ~= "table" or #objects == 0 then
		return nil
	end
	local model = Instance.new("Model")
	for _, o in objects do
		o.Parent = model
	end
	return model
end

local function clean(model: Model, label: string): number
	local removed = 0
	for _, d in model:GetDescendants() do
		local bad = d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent")
		if d:IsA("Sound") then
			(d :: Sound).Playing = false
		end
		if bad then
			print(string.format("[V3Import] %s: removed %s '%s'", label, d.ClassName, d:GetFullName()))
			d:Destroy()
			removed += 1
		end
	end
	-- Props are scenery: no seats to sit in, no prompts, clicks, sounds, fire or headlights, and
	-- no brand marks (found on the PC import, 19 Nov: a Chevrolet emblem on the truck, logo decals
	-- on the rocket and truck, a train name board).
	for _, d in model:GetDescendants() do
		if d:IsA("Seat") or d:IsA("VehicleSeat") then
			d.Disabled = true
		elseif
			d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("Sound") or d:IsA("Fire") or d:IsA("Smoke")
			or d:IsA("ParticleEmitter") or d:IsA("SurfaceLight") or d:IsA("Camera")
		then
			d:Destroy()
			removed += 1
		elseif d:IsA("Decal") and (label == "Rocket" or label == "MonsterTruck" or (d.Parent and d.Parent.Name == "Decal Holder")) then
			d:Destroy()
		elseif d:IsA("BasePart") and (d.Name:lower():find("emblem") or d.Name:lower():find("logo")) then
			d:Destroy()
		elseif d:IsA("Model") and d.Name:lower():find("emblem") then
			d:Destroy()
		end
	end
	if label == "Rocket" then
		-- (Its launch-site ground: camo strips and flat plates far from the pad.)
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and (d.BrickColor.Name == "Camo" or (math.min(d.Size.X, d.Size.Y, d.Size.Z) <= 1.5 and math.max(d.Size.X, d.Size.Y, d.Size.Z) >= 100)) then
				d:Destroy()
			end
		end
	end
	if label == "Fence" then
		-- (One mesh panel turned 152 degrees: square it to the X axis.)
		local p = model:FindFirstChildWhichIsA("BasePart", true)
		if p then
			p.CFrame = CFrame.new(p.Position)
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d.Size.Magnitude < 1 then
				d.CastShadow = false
			end
		end
	end
	return removed
end

local function settle(model: Model, yaw: number?)
	-- (The world box of the visible parts: GetBoundingBox follows a pack's own turn and once put
	-- the rocket 21 studs in the air.)
	local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = d.CFrame:PointToWorldSpace(d.Size / 2 * Vector3.new(sx, sy, sz))
						mn = mn:Min(p)
						mx = mx:Max(p)
					end
				end
			end
		end
	end
	model.WorldPivot = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
	if yaw then
		model:SetAttribute("Yaw", yaw)
	end
	model:PivotTo(CFrame.new(0, 0, 0))
end

local ok, failed = 0, {}
for _, pick in PICKS do
	local model = load(pick.id)
	local used = pick.id
	if not model and pick.backup then
		model = load(pick.backup)
		used = pick.backup
	end
	if not model then
		table.insert(failed, pick.role)
		warn("[V3Import] could not load " .. pick.role .. " (" .. pick.id .. ")")
		continue
	end
	if pick.single then
		-- (A pack: the named model, else the first model in it, alone.)
		local one: Instance? = nil
		for _, d in model:GetDescendants() do
			if d:IsA("Model") and (pick.childName == nil or d.Name == pick.childName) then
				one = d
				break
			end
		end
		if one then
			local keep = Instance.new("Model")
			for _, c in one:GetChildren() do
				c.Parent = keep
			end
			model:Destroy()
			model = keep
		end
	end
	assert(model)
	local removed = clean(model, pick.role)
	settle(model, pick.yaw)
	model.Name = pick.role
	model:SetAttribute("AssetId", used)
	local old = folder:FindFirstChild(pick.role)
	if old then
		old:Destroy()
	end
	model.Parent = folder
	ok += 1
	local _, size = model:GetBoundingBox()
	print(string.format("[V3Import] %s <- %d (%d scripts removed, %.0fx%.0fx%.0f studs)", pick.role, used, removed, size.X, size.Y, size.Z))
end
print(string.format("[V3Import] done: %d loaded, %d failed %s. SAVE THE PLACE.", ok, #failed, table.concat(failed, ", ")))
