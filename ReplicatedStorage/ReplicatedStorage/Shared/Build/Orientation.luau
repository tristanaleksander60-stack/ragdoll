--!strict
-- The 24 axis-aligned rotations a build part can have. Builds store an index (0-23) instead of a
-- full rotation, so saves stay tiny and every part sits exactly on the grid.

local Orientation = {}

local list: { CFrame } = {}

local function same(a: CFrame, b: CFrame): boolean
	return a.XVector:FuzzyEq(b.XVector, 1e-3) and a.YVector:FuzzyEq(b.YVector, 1e-3)
end

do
	local quarter = math.pi / 2
	for x = 0, 3 do
		for y = 0, 3 do
			for z = 0, 3 do
				local r = CFrame.Angles(x * quarter, y * quarter, z * quarter)
				-- Snap the matrix to exact 0/±1 so rounding never creeps in.
				local function snap(v: Vector3): Vector3
					return Vector3.new(math.round(v.X), math.round(v.Y), math.round(v.Z))
				end
				local xv, yv = snap(r.XVector), snap(r.YVector)
				local zv = xv:Cross(yv)
				local clean = CFrame.fromMatrix(Vector3.zero, xv, yv, zv)
				local seen = false
				for _, existing in list do
					if same(existing, clean) then
						seen = true
						break
					end
				end
				if not seen then
					table.insert(list, clean)
				end
			end
		end
	end
	assert(#list == 24, "expected 24 orientations")
end

Orientation.COUNT = 24

-- Rotation for an index (0-based).
function Orientation.get(index: number): CFrame
	return list[(index % 24) + 1]
end

-- Index of the orientation closest to a rotation.
function Orientation.indexOf(rotation: CFrame): number
	local best, bestScore = 0, -math.huge
	for i, r in list do
		local score = r.XVector:Dot(rotation.XVector) + r.YVector:Dot(rotation.YVector)
		if score > bestScore then
			best, bestScore = i - 1, score
		end
	end
	return best
end

-- Turns an orientation a quarter turn around a world axis (snapped to the nearest main axis).
function Orientation.turn(index: number, worldAxis: Vector3, quarters: number): number
	local axis = Orientation.snapAxis(worldAxis)
	local rotated = CFrame.fromAxisAngle(axis, quarters * math.pi / 2) * Orientation.get(index)
	return Orientation.indexOf(rotated)
end

-- The main axis (±X, ±Y, ±Z) closest to a direction.
function Orientation.snapAxis(v: Vector3): Vector3
	local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
	if ax >= ay and ax >= az then
		return Vector3.new(math.sign(v.X), 0, 0)
	elseif ay >= az then
		return Vector3.new(0, math.sign(v.Y), 0)
	end
	return Vector3.new(0, 0, math.sign(v.Z))
end

-- An orientation whose local +Y points along `up` (a main axis), turned `quarters` around it.
function Orientation.facingUp(up: Vector3, quarters: number): number
	local u = Orientation.snapAxis(up)
	local other = if math.abs(u.Y) > 0.5 then Vector3.zAxis else Vector3.yAxis
	local x = other:Cross(u).Unit
	local z = x:Cross(u)
	local base = CFrame.fromMatrix(Vector3.zero, x, u, z)
	return Orientation.indexOf(CFrame.fromAxisAngle(u, quarters * math.pi / 2) * base)
end

-- Size of a box after rotation (axis-aligned extents).
function Orientation.extents(index: number, size: Vector3): Vector3
	local r = Orientation.get(index)
	local function extent(axis: Vector3): number
		return math.abs(r.XVector:Dot(axis)) * size.X + math.abs(r.YVector:Dot(axis)) * size.Y + math.abs(r.ZVector:Dot(axis)) * size.Z
	end
	return Vector3.new(extent(Vector3.xAxis), extent(Vector3.yAxis), extent(Vector3.zAxis))
end

return table.freeze(Orientation)
