--!strict
-- AUDIT 27 Nov 8 (Config.JOIN_SIGN): TeleportData can be forged by a client (a client may teleport itself with any data).
-- Our servers SIGN what they send (sign: a keyed hash of from, code, target and the time, with a secret that lives only
-- in this server script), and a server READS it only when the signature fits, it is under MAX_AGE s old, and the join
-- came from one of our own places (SourcePlaceId). Anything else is read as no TeleportData at all.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JoinSign = {}

JoinSign.MAX_AGE = 120
-- The secret is NOT in the code (nor in git): it is an attribute on ServerStorage in the place file ("JoinSignSecret",
-- server only). Without it nothing is signed or checked (a warning says so).
local function secret(): string?
	local v = game:GetService("ServerStorage"):GetAttribute("JoinSignSecret")
	return if type(v) == "string" and #v >= 16 then v else nil
end

-- Two FNV-1a passes over the text with the secret mixed in: a keyed 64-bit-ish tag (not readable without the secret).
local function tag(text: string, SECRET: string): string
	local function fnv(s: string, seed: number): number
		local h = seed
		for i = 1, #s do
			h = bit32.bxor(h, string.byte(s, i))
			h = (h * 16777619) % 4294967296
		end
		return h
	end
	local a = fnv(SECRET .. "|" .. text, 2166136261)
	local b = fnv(text .. "|" .. SECRET, a)
	return string.format("%08x%08x", a, b)
end

local function body(d: { [string]: any }): string
	return string.format("%s|%s|%s|%s", tostring(d.from), tostring(d.code), tostring(d.target), tostring(d.t))
end

-- Adds the time and the signature to TeleportData we send.
function JoinSign.sign(d: { [string]: any }): { [string]: any }
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.JOIN_SIGN then
		return d
	end
	local key = secret()
	if not key then
		warn("[JoinSign] no JoinSignSecret on ServerStorage: TeleportData is sent unsigned")
		return d
	end
	d.t = os.time()
	d.sig = tag(body(d), key)
	return d
end

-- The TeleportData of a join, or nil when it is not ours (unsigned, wrong signature, too old, from another place).
function JoinSign.data(player: Player): { [string]: any }?
	local okJ, join = pcall(function()
		return player:GetJoinData()
	end)
	if not (okJ and type(join) == "table") then
		return nil
	end
	local data = (join :: any).TeleportData
	if type(data) ~= "table" then
		return nil
	end
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	local key = secret()
	if not Config.JOIN_SIGN or not key then
		return data
	end
	local from = (join :: any).SourcePlaceId
	local ours = from == game.PlaceId or from == (Config.MULTI_PLACE or 0) or from == 126037745825106
	if not ours or type(data.sig) ~= "string" or type(data.t) ~= "number" or math.abs(os.time() - data.t) > JoinSign.MAX_AGE then
		return nil
	end
	if tag(body(data), key) ~= data.sig then
		warn("[JoinSign] a TeleportData with a wrong signature from " .. player.Name .. " was ignored")
		return nil
	end
	return data
end

return JoinSign
