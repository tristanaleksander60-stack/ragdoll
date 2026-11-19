--!strict
-- Builds as data, and the compact binary format they are saved and shared in.
--
-- A blueprint is a list of pieces and wires. Pieces are ordered so a piece's parent always comes
-- before it (the parent is what it was placed on; 0 = the lab floor). Positions are relative to the
-- lab origin, on a half-stud grid.
--
-- Binary layout, version 1 (all little-endian):
--   "RLB" u8 version
--   u16 pieceCount, then per piece (14 bytes):
--     u8 item code, i16 x, i16 y, i16 z (half-studs), u8 rotation (0-23), u8 color (0 = item
--     default, else palette index), u8 setting (1-based), u8 flags (bit 0: pinned),
--     u16 parent (0 = floor, else 1-based piece index), u8 parent part (1-based)
--   u16 wireCount, then per wire: u16 from, u16 to (1-based piece indices)
-- Saved and shared builds are this, zstd-compressed and base64-encoded.
--
-- decode never trusts its input: every field is range-checked, so a broken or hand-made save is
-- rejected with a reason instead of building something strange.

local Catalog = require(script.Parent.Catalog)

local EncodingService = game:GetService("EncodingService")

export type Piece = {
	item: string,
	pos: Vector3, -- studs from the lab origin
	rot: number, -- 0-23
	color: number, -- 0 = item default
	setting: number, -- 1-based
	pinned: boolean,
	parent: number, -- 0 = floor
	parentPart: number, -- 1-based part of the parent it is attached to
}

export type Wire = { from: number, to: number }

export type Blueprint = { pieces: { Piece }, wires: { Wire } }

local MAGIC = "RLB"
local VERSION = 1
local PIECE_BYTES = 14
local WIRE_BYTES = 4
local MAX_PARENT_PARTS = 8

local Codec = {}

function Codec.empty(): Blueprint
	return { pieces = {}, wires = {} }
end

local function half(v: number): number
	return math.round(v * 2)
end

-- Checks a blueprint against every rule a build must follow. Returns (true) or (false, reason).
function Codec.validate(bp: any): (boolean, string?)
	if type(bp) ~= "table" or type(bp.pieces) ~= "table" or type(bp.wires) ~= "table" then
		return false, "not a blueprint"
	end
	local pieces = bp.pieces :: { any }
	if #pieces > Catalog.MAX_PARTS then
		return false, "too many parts"
	end
	if #bp.wires > Catalog.MAX_WIRES then
		return false, "too many wires"
	end
	for i, p in pieces do
		if type(p) ~= "table" then
			return false, "piece " .. i .. " is not a table"
		end
		local item = Catalog.byId[p.item]
		if not item then
			return false, "piece " .. i .. " has an unknown item"
		end
		if typeof(p.pos) ~= "Vector3" then
			return false, "piece " .. i .. " has no position"
		end
		local pos = p.pos :: Vector3
		for _, c in { pos.X, pos.Y, pos.Z } do
			if c ~= c or math.abs(c) == math.huge or math.abs(half(c) - c * 2) > 1e-3 then
				return false, "piece " .. i .. " is off the grid"
			end
		end
		if Vector3.new(pos.X, 0, pos.Z).Magnitude > Catalog.BUILD_RADIUS or pos.Y < -2 or pos.Y > Catalog.BUILD_HEIGHT then
			return false, "piece " .. i .. " is outside the build area"
		end
		if type(p.rot) ~= "number" or p.rot % 1 ~= 0 or p.rot < 0 or p.rot > 23 then
			return false, "piece " .. i .. " has a bad rotation"
		end
		if type(p.color) ~= "number" or p.color % 1 ~= 0 or p.color < 0 or p.color > #Catalog.palette then
			return false, "piece " .. i .. " has a bad color"
		end
		local settingCount = if item.settings then #item.settings else 1
		if type(p.setting) ~= "number" or p.setting % 1 ~= 0 or p.setting < 1 or p.setting > settingCount then
			return false, "piece " .. i .. " has a bad setting"
		end
		if type(p.pinned) ~= "boolean" then
			return false, "piece " .. i .. " has a bad pin flag"
		end
		if type(p.parent) ~= "number" or p.parent % 1 ~= 0 or p.parent < 0 or p.parent >= i then
			return false, "piece " .. i .. " is attached to a piece placed after it"
		end
		if type(p.parentPart) ~= "number" or p.parentPart % 1 ~= 0 or p.parentPart < 1 or p.parentPart > MAX_PARENT_PARTS then
			return false, "piece " .. i .. " has a bad attachment"
		end
	end
	local seen: { [number]: boolean } = {}
	for i, w in bp.wires :: { any } do
		if type(w) ~= "table" or type(w.from) ~= "number" or type(w.to) ~= "number" then
			return false, "wire " .. i .. " is broken"
		end
		local from, to = pieces[w.from], pieces[w.to]
		if not from or not to or w.from == w.to then
			return false, "wire " .. i .. " points nowhere"
		end
		if not Catalog.byId[from.item].output or not Catalog.byId[to.item].input then
			return false, "wire " .. i .. " connects parts that cannot be wired"
		end
		local key = w.from * 65536 + w.to
		if seen[key] then
			return false, "wire " .. i .. " is a duplicate"
		end
		seen[key] = true
	end
	return true, nil
end

-- Blueprint -> raw binary (uncompressed). The blueprint must be valid.
function Codec.encode(bp: Blueprint): buffer
	local ok, err = Codec.validate(bp)
	assert(ok, err)
	local n, w = #bp.pieces, #bp.wires
	local buf = buffer.create(4 + 2 + n * PIECE_BYTES + 2 + w * WIRE_BYTES)
	buffer.writestring(buf, 0, MAGIC)
	buffer.writeu8(buf, 3, VERSION)
	buffer.writeu16(buf, 4, n)
	local o = 6
	for _, p in bp.pieces do
		buffer.writeu8(buf, o, Catalog.byId[p.item].code)
		buffer.writei16(buf, o + 1, half(p.pos.X))
		buffer.writei16(buf, o + 3, half(p.pos.Y))
		buffer.writei16(buf, o + 5, half(p.pos.Z))
		buffer.writeu8(buf, o + 7, p.rot)
		buffer.writeu8(buf, o + 8, p.color)
		buffer.writeu8(buf, o + 9, p.setting)
		buffer.writeu8(buf, o + 10, if p.pinned then 1 else 0)
		buffer.writeu16(buf, o + 11, p.parent)
		buffer.writeu8(buf, o + 13, p.parentPart)
		o += PIECE_BYTES
	end
	buffer.writeu16(buf, o, w)
	o += 2
	for _, wire in bp.wires do
		buffer.writeu16(buf, o, wire.from)
		buffer.writeu16(buf, o + 2, wire.to)
		o += WIRE_BYTES
	end
	return buf
end

-- Raw binary -> blueprint, or (nil, reason).
function Codec.decode(buf: buffer): (Blueprint?, string?)
	local len = buffer.len(buf)
	if len < 8 or buffer.readstring(buf, 0, 3) ~= MAGIC then
		return nil, "not a Ragdoll Lab build"
	end
	if buffer.readu8(buf, 3) ~= VERSION then
		return nil, "made by a newer version"
	end
	local n = buffer.readu16(buf, 4)
	if n > Catalog.MAX_PARTS then
		return nil, "too many parts"
	end
	local o = 6
	if len < o + n * PIECE_BYTES + 2 then
		return nil, "cut short"
	end
	local pieces: { Piece } = {}
	for _ = 1, n do
		local item = Catalog.byCode[buffer.readu8(buf, o)]
		if not item then
			return nil, "unknown part"
		end
		table.insert(pieces, {
			item = item.id,
			pos = Vector3.new(buffer.readi16(buf, o + 1), buffer.readi16(buf, o + 3), buffer.readi16(buf, o + 5)) / 2,
			rot = buffer.readu8(buf, o + 7),
			color = buffer.readu8(buf, o + 8),
			setting = buffer.readu8(buf, o + 9),
			pinned = bit32.band(buffer.readu8(buf, o + 10), 1) == 1,
			parent = buffer.readu16(buf, o + 11),
			parentPart = buffer.readu8(buf, o + 13),
		})
		o += PIECE_BYTES
	end
	local w = buffer.readu16(buf, o)
	o += 2
	if w > Catalog.MAX_WIRES or len ~= o + w * WIRE_BYTES then
		return nil, "wires do not add up"
	end
	local wires: { Wire } = {}
	for _ = 1, w do
		table.insert(wires, { from = buffer.readu16(buf, o), to = buffer.readu16(buf, o + 2) })
		o += WIRE_BYTES
	end
	local bp: Blueprint = { pieces = pieces, wires = wires }
	local ok, err = Codec.validate(bp)
	if not ok then
		return nil, err
	end
	return bp, nil
end

-- Blueprint -> text for a DataStore (compressed, base64).
function Codec.pack(bp: Blueprint): string
	local raw = Codec.encode(bp)
	local packed = EncodingService:CompressBuffer(raw, Enum.CompressionAlgorithm.Zstd, 9)
	return buffer.tostring(EncodingService:Base64Encode(packed))
end

local MAX_RAW = 6 + Catalog.MAX_PARTS * PIECE_BYTES + 2 + Catalog.MAX_WIRES * WIRE_BYTES

-- Text from a DataStore -> blueprint, or (nil, reason). Safe on any input.
function Codec.unpack(text: unknown): (Blueprint?, string?)
	if type(text) ~= "string" or #text == 0 or #text > 64000 then
		return nil, "empty or oversized"
	end
	local ok, result = pcall(function()
		local packed = EncodingService:Base64Decode(buffer.fromstring(text :: string))
		local size = EncodingService:GetDecompressedBufferSize(packed, Enum.CompressionAlgorithm.Zstd)
		if not size or size > MAX_RAW then
			error("oversized")
		end
		return EncodingService:DecompressBuffer(packed, Enum.CompressionAlgorithm.Zstd)
	end)
	if not ok then
		return nil, "damaged save"
	end
	return Codec.decode(result :: buffer)
end

-- Deep copy (blueprints are edited in place by the build service).
function Codec.clone(bp: Blueprint): Blueprint
	local pieces = {}
	for _, p in bp.pieces do
		table.insert(pieces, table.clone(p))
	end
	local wires = {}
	for _, w in bp.wires do
		table.insert(wires, table.clone(w))
	end
	return { pieces = pieces, wires = wires }
end

return Codec
