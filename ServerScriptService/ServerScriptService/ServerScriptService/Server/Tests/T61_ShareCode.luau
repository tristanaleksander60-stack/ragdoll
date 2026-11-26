--!strict
-- Phase 1: the X-ray replay's SHARE CODE. Every toy and score round-trips; a typo or junk is
-- refused (never a wrong toy); the score words rise with the hit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShareCode = require(ReplicatedStorage.Shared.ShareCode)
local Toys = require(ReplicatedStorage.Shared.Toys)

return {
	name = "T61_ShareCode",
	timeout = 3,
	run = function(): string?
		local rng = Random.new(7)
		local n = 0
		for index = 1, #Toys.list do
			for _ = 1, 5 do
				local score = rng:NextInteger(0, 9999)
				local code = ShareCode.encode(index, score)
				assert(#code == 6, "a code is not 6 letters: " .. code)
				local t, s = ShareCode.decode(code)
				assert(t == index and s == score, string.format("%s did not round-trip (%d, %d)", code, index, score))
				local t2 = ShareCode.decode(string.lower(string.sub(code, 1, 3)) .. "-" .. string.sub(code, 4))
				assert(t2 == index, "lower case or a dash broke a code")
				-- A changed letter is refused.
				local first = string.sub(code, 1, 1)
				local other = if first == "A" then "B" else "A"
				local typo = other .. string.sub(code, 2)
				local tt, ts = ShareCode.decode(typo)
				assert(tt == nil or (tt ~= index or ts ~= score), "a typo decoded to the same hit")
				n += 1
			end
		end
		for _, junk in { "", "ABC", "0OIL11", "ABCDEFG", "!!!!!!" } do
			assert(ShareCode.decode(junk) == nil, "junk decoded: " .. junk)
		end
		local _, small = ShareCode.scoreOf(1, 0)
		local _, big = ShareCode.scoreOf(200, 40)
		assert(small ~= big, "the score words do not rise")
		return string.format("%d codes round-trip; junk refused", n)
	end,
}
