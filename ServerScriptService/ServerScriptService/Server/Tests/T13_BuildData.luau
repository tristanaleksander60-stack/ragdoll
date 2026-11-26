--!strict
-- Workshop data: the 24 orientations, every catalog piece's geometry, and the save format
-- (round trip, compression, and rejecting anything malformed).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = ReplicatedStorage.Shared.Build
local Catalog = require(Build.Catalog)
local Orientation = require(Build.Orientation)
local Codec = require(Build.Codec)
local Factory = require(Build.Factory)

local function piece(item: string, pos: Vector3, parent: number?): Codec.Piece
	return { item = item, pos = pos, rot = 0, color = 0, setting = 1, pinned = parent == nil, parent = parent or 0, parentPart = 1 }
end

local function same(a: Codec.Blueprint, b: Codec.Blueprint): boolean
	if #a.pieces ~= #b.pieces or #a.wires ~= #b.wires then
		return false
	end
	for i, p in a.pieces do
		local q = b.pieces[i]
		if p.item ~= q.item or not p.pos:FuzzyEq(q.pos, 1e-4) or p.rot ~= q.rot or p.color ~= q.color
			or p.setting ~= q.setting or p.pinned ~= q.pinned or p.parent ~= q.parent or p.parentPart ~= q.parentPart then
			return false
		end
	end
	for i, w in a.wires do
		if w.from ~= b.wires[i].from or w.to ~= b.wires[i].to then
			return false
		end
	end
	return true
end

return {
	name = "workshop-data-and-save-format",
	timeout = 20,
	run = function(): string?
		-- Orientations
		for i = 0, 23 do
			assert(Orientation.indexOf(Orientation.get(i)) == i, "orientation " .. i .. " does not round trip")
		end
		for _, up in { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis } do
			for q = 0, 3 do
				local r = Orientation.get(Orientation.facingUp(up, q))
				assert(r.YVector:FuzzyEq(up, 1e-3), "facingUp " .. tostring(up) .. " points elsewhere")
			end
		end

		-- Every piece builds, in order, inside its own bounding box, in several orientations.
		local origin = Vector3.new(0, 500, 0)
		local partCount = 0
		for _, item in Catalog.list do
			for _, rot in { 0, 5, 13, 22 } do
				local p = piece(item.id, Vector3.zero)
				p.rot = rot
				local model = Factory.build(p, origin)
				local parts = Factory.parts(model)
				assert(#parts >= 1, item.id .. " built no parts")
				assert(model.PrimaryPart == parts[1], item.id .. " has the wrong attach part")
				local frame = Factory.cframeOf(p, origin)
				local half = item.size / 2 + Vector3.one * 0.15
				for _, part in parts do
					assert(part.Anchored, item.id .. " " .. part.Name .. " is not frozen")
					local corners = part.Size / 2
					for _, sx in { -1, 1 } do
						for _, sy in { -1, 1 } do
							for _, sz in { -1, 1 } do
								local world = part.CFrame:PointToWorldSpace(Vector3.new(sx * corners.X, sy * corners.Y, sz * corners.Z))
								local l = frame:PointToObjectSpace(world)
								-- Round parts poke out at the corners of their box; the ball itself stays inside.
								local slack = if part:IsA("Part") and part.Shape ~= Enum.PartType.Block then corners.Magnitude else 0
								assert(math.abs(l.X) <= half.X + slack and math.abs(l.Y) <= half.Y + slack and math.abs(l.Z) <= half.Z + slack,
									string.format("%s part %s sticks out of its box (rot %d)", item.id, part.Name, rot))
							end
						end
					end
				end
				if rot == 0 then
					partCount += #parts
				end
				model:Destroy()
			end
		end

		-- A blueprint using every item, wired up.
		local bp = Codec.empty()
		for i, item in Catalog.list do
			local p = piece(item.id, Vector3.new((i % 10) * 6 - 27, 3.5, math.floor(i / 10) * 8 - 10))
			p.rot = i % 24
			p.color = if item.paintable then (i % #Catalog.palette) + 1 else 0
			p.setting = if item.settings then #item.settings else 1
			table.insert(bp.pieces, p)
		end
		local button, timer, motor, cannon
		for i, p in bp.pieces do
			if p.item == "Button" then button = i end
			if p.item == "Timer" then timer = i end
			if p.item == "Motor" then motor = i end
			if p.item == "Cannon" then cannon = i end
		end
		table.insert(bp.wires, { from = button, to = motor })
		table.insert(bp.wires, { from = timer, to = cannon })
		-- One piece attached to another.
		table.insert(bp.pieces, piece("Block", Vector3.new(0, 6, 0), 1))

		local ok, err = Codec.validate(bp)
		assert(ok, "valid blueprint rejected: " .. tostring(err))
		local raw = Codec.encode(bp)
		local back, why = Codec.decode(raw)
		assert(back and same(bp, back), "binary round trip failed: " .. tostring(why))
		local text = Codec.pack(bp)
		local unpacked, why2 = Codec.unpack(text)
		assert(unpacked and same(bp, unpacked), "packed round trip failed: " .. tostring(why2))

		-- Malformed input is rejected, never crashes.
		local function rejects(label: string, value: any)
			local result, reason = Codec.unpack(value)
			assert(result == nil and reason ~= nil, label .. " was accepted")
		end
		rejects("nil", nil)
		rejects("empty", "")
		rejects("garbage", "hello there")
		rejects("huge", string.rep("A", 70000))
		local rng = Random.new(7)
		for _ = 1, 200 do
			local junk = buffer.create(rng:NextInteger(0, 300))
			for i = 0, buffer.len(junk) - 1 do
				buffer.writeu8(junk, i, rng:NextInteger(0, 255))
			end
			local okCall, result = pcall(Codec.decode, junk)
			assert(okCall, "decode crashed on random bytes: " .. tostring(result))
		end
		-- Truncated and tampered saves.
		local short = buffer.create(buffer.len(raw) - 3)
		buffer.copy(short, 0, raw, 0, buffer.len(short))
		assert(Codec.decode(short) == nil, "truncated save accepted")
		local function tampered(offset: number, value: number): boolean
			local copy = buffer.create(buffer.len(raw))
			buffer.copy(copy, 0, raw)
			buffer.writeu8(copy, offset, value)
			return Codec.decode(copy) == nil
		end
		assert(tampered(0, 0), "bad magic accepted")
		assert(tampered(6, 250), "unknown part accepted")
		assert(tampered(6 + 7, 99), "bad rotation accepted")
		-- Validation rules.
		local bad = Codec.clone(bp)
		bad.pieces[1].parent = 5
		assert(not Codec.validate(bad), "parent placed after child accepted")
		bad = Codec.clone(bp)
		bad.pieces[1].pos = Vector3.new(0.3, 0, 0)
		assert(not Codec.validate(bad), "off-grid position accepted")
		bad = Codec.clone(bp)
		bad.pieces[1].pos = Vector3.new(500, 0, 0)
		assert(not Codec.validate(bad), "position outside the build area accepted")
		bad = Codec.clone(bp)
		table.insert(bad.wires, { from = motor, to = button })
		assert(not Codec.validate(bad), "wire into an output accepted")
		bad = Codec.clone(bp)
		table.insert(bad.wires, { from = button, to = motor })
		assert(not Codec.validate(bad), "duplicate wire accepted")

		return string.format("%d items (%d parts), save %d bytes raw, %d packed; malformed input rejected",
			#Catalog.list, partCount, buffer.len(raw), #text)
	end,
}
