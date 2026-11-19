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

type Pick = { role: string, id: number, backup: number?, yaw: number? }

-- Filled from docs/V3_ASSETS.md (role = the name the game code asks for).
local PICKS: { Pick } = {
	-- PICKS_START
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
	local cf, size = model:GetBoundingBox()
	local bottom = Vector3.new(cf.Position.X, cf.Position.Y - size.Y / 2, cf.Position.Z)
	model.WorldPivot = CFrame.new(bottom)
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
