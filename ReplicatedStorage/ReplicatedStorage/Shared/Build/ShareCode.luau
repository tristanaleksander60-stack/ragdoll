--!strict
-- Share codes: 6 characters from consonants and digits. No vowels, so a code never spells a word;
-- no 0/O, 1/I/L or 5/S look-alikes, so a code read off a phone screen is typed right.

local ShareCode = {}

ShareCode.ALPHABET = "BCDFGHJKMNPQRTVWXZ2346789"
ShareCode.LENGTH = 6

local allowed: { [string]: boolean } = {}
for i = 1, #ShareCode.ALPHABET do
	allowed[string.sub(ShareCode.ALPHABET, i, i)] = true
end

function ShareCode.generate(rng: Random): string
	local chars = table.create(ShareCode.LENGTH)
	for i = 1, ShareCode.LENGTH do
		local k = rng:NextInteger(1, #ShareCode.ALPHABET)
		chars[i] = string.sub(ShareCode.ALPHABET, k, k)
	end
	return table.concat(chars)
end

-- What a player typed, made into a code: upper case, spaces and dashes dropped. Returns nil if it
-- cannot be a code.
function ShareCode.normalize(raw: unknown): string?
	if type(raw) ~= "string" or #raw > 24 then
		return nil
	end
	local text = string.upper(raw :: string)
	text = string.gsub(text, "[%s%-]", "")
	if #text ~= ShareCode.LENGTH then
		return nil
	end
	for i = 1, #text do
		if not allowed[string.sub(text, i, i)] then
			return nil
		end
	end
	return text
end

-- Keeps only characters that can be in a code (for live filtering of a text box), at most LENGTH.
function ShareCode.filter(raw: string): string
	local out = {}
	local text = string.upper(raw)
	for i = 1, #text do
		local c = string.sub(text, i, i)
		if allowed[c] then
			table.insert(out, c)
			if #out >= ShareCode.LENGTH then
				break
			end
		end
	end
	return table.concat(out)
end

return ShareCode
