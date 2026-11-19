--!strict
-- Phase 1: a SHARE CODE for a replayed hit: which toy and the score, in 6 letters a friend can
-- type into EXPERIMENTS ("Beat 140 with the Rattler!"). Pure; T61 round-trips it. No free text: the
-- code only ever decodes to a toy id from Toys and a number. Letters without look-alikes (no 0/O,
-- 1/I/L). A checksum letter catches typos.

local ShareCode = {}

local ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789" -- 31 letters
local BASE = #ALPHABET
local MAX_SCORE = 9999

local function digit(i: number): string
	return string.sub(ALPHABET, i + 1, i + 1)
end

local function value(c: string): number?
	local i = string.find(ALPHABET, c, 1, true)
	return if i then i - 1 else nil
end

-- toyIndex: the toy's place in Toys.list (1..BASE*BASE); score 0..MAX_SCORE.
function ShareCode.encode(toyIndex: number, score: number): string
	local s = math.clamp(math.floor(score), 0, MAX_SCORE)
	local t = math.clamp(math.floor(toyIndex), 1, BASE * BASE)
	-- 2 letters toy, 3 letters score, 1 checksum.
	local parts = { (t - 1) // BASE, (t - 1) % BASE, s // (BASE * BASE), (s // BASE) % BASE, s % BASE }
	local sum = 0
	local out = {}
	for i, p in parts do
		sum += p * (i + 2)
		table.insert(out, digit(p))
	end
	table.insert(out, digit(sum % BASE))
	return table.concat(out)
end

-- Returns the toy index and the score, or nil for anything that is not a valid code.
function ShareCode.decode(text: string): (number?, number?)
	local code = string.upper(string.gsub(text, "[%s%-]", ""))
	if #code ~= 6 then
		return nil, nil
	end
	local parts = {}
	for i = 1, 6 do
		local v = value(string.sub(code, i, i))
		if v == nil then
			return nil, nil
		end
		parts[i] = v
	end
	local sum = 0
	for i = 1, 5 do
		sum += parts[i] * (i + 2)
	end
	if sum % BASE ~= parts[6] then
		return nil, nil
	end
	local toy = parts[1] * BASE + parts[2] + 1
	local score = parts[3] * BASE * BASE + parts[4] * BASE + parts[5]
	if score > MAX_SCORE then
		return nil, nil
	end
	return toy, score
end

-- The replay's score for a hit: how far and how high the body went in the window. "+N" and a word.
function ShareCode.scoreOf(distance: number, rise: number): (number, string)
	local score = math.floor(math.max(0, distance) * 2 + math.max(0, rise) * 4 + 10)
	local word = if score >= 300 then "MEGA CRACK!" elseif score >= 120 then "CRACK!" elseif score >= 50 then "BONK!" else "BOP!"
	return math.min(score, MAX_SCORE), word
end

return ShareCode
