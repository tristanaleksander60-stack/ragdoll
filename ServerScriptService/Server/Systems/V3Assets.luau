--!strict
-- v3 (19 Nov 2026, the owner: code-built props "look like AI junk"): real models from the Creator
-- Store, kept in the place file under ServerStorage.V3Assets.<Role> (put there, cleaned and
-- measured by tools\ImportV3Assets.luau in Studio; docs/V3_ASSETS.md lists the picks). The game
-- code asks for a role and places a copy; with no model for a role it gets nil and keeps its own
-- code-built fallback, so the game runs the same before the import.

local ServerStorage = game:GetService("ServerStorage")

local V3Assets = {}

local function source(role: string): Model?
	local folder = ServerStorage:FindFirstChild("V3Assets")
	local m = folder and folder:FindFirstChild(role)
	return if m and m:IsA("Model") then m else nil
end

function V3Assets.has(role: string): boolean
	return source(role) ~= nil
end

export type Options = {
	size: number?, -- the model's biggest side after placing (studs); nil keeps the imported size
	height: number?, -- or: its height (studs)
	collide: boolean?, -- default true
	anchored: boolean?, -- default true
	name: string?,
}

-- A copy of `role` standing on `at` (its bottom middle on at's position, turned as at), or nil.
function V3Assets.place(role: string, parent: Instance, at: CFrame, options: Options?): Model?
	local src = source(role)
	if not src then
		return nil
	end
	local o: Options = options or {}
	local copy = src:Clone()
	copy.Name = o.name or role
	local _, size = copy:GetBoundingBox()
	local k = 1
	if o.height and size.Y > 0.01 then
		k = o.height / size.Y
	elseif o.size then
		k = o.size / math.max(size.X, size.Y, size.Z, 0.01)
	end
	if math.abs(k - 1) > 0.001 then
		pcall(function()
			copy:ScaleTo(copy:GetScale() * k)
		end)
	end
	local collide = o.collide ~= false
	local anchored = o.anchored ~= false
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = anchored
			if not collide then
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
	end
	-- (The import set each model's pivot to its bottom middle, and its "Yaw" attribute turns its
	-- front to -Z, so a pivot at `at` stands it there facing where `at` looks.)
	local yaw = src:GetAttribute("Yaw")
	copy:PivotTo(at * CFrame.Angles(0, math.rad(if type(yaw) == "number" then yaw else 0), 0))
	copy.Parent = parent
	return copy
end

-- Roles present (tests, the report).
function V3Assets.roles(): { string }
	local out = {}
	local folder = ServerStorage:FindFirstChild("V3Assets")
	for _, m in if folder then folder:GetChildren() else {} do
		if m:IsA("Model") then
			table.insert(out, m.Name)
		end
	end
	table.sort(out)
	return out
end

return V3Assets
