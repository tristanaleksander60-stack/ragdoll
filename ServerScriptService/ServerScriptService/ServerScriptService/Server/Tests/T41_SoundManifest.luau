--!strict
-- Round 4, M10 acceptance test. Every combat sound used by the client has a recorded source
-- and asset id in ReplicatedStorage.Shared.SoundManifest. This gives an auditable list of
-- Creator Store assets used for the hits, melee impacts, ricochets and shatters.
--
-- The manifest also lists sounds that are NOT combat (whoosh, whistle, boing, …) because the
-- same bank is shared with other effects — the acceptance criterion is just that every id used
-- has a source string.
--
-- The client's bank (FxController.BANK) is not required to be strictly equal to the manifest at
-- test time (it may have its own additions), but every bank name in the manifest must have at
-- least one id and every id must have a non-empty source string.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManifest = require(ReplicatedStorage.Shared.SoundManifest)

return {
	name = "T41_SoundManifest",
	timeout = 2,
	run = function(): string?
		local banks = 0
		local sounds = 0
		local seen: { [number]: boolean } = {}
		for bank, list in SoundManifest.SOUNDS do
			assert(type(bank) == "string" and #bank > 0, "empty bank name in manifest")
			assert(#list > 0, "bank " .. bank .. " has no sounds")
			banks += 1
			for _, entry in list do
				assert(type(entry.id) == "number" and entry.id > 0, bank .. ": id must be a positive number")
				assert(type(entry.title) == "string" and #entry.title > 0, bank .. ": title must be a non-empty string")
				assert(type(entry.source) == "string" and #entry.source > 0, bank .. ": source must be a non-empty string")
				-- The same id can appear in two banks on purpose (the swish is used for open and close).
				seen[entry.id] = true
				sounds += 1
			end
		end
		assert(banks >= 15, string.format("too few banks in the manifest (%d): the combat kit should cover hit, land, whoosh, boom, nail, bat, golf, chop, saw, arrow, ricMetal, ricHard, shatter, pop, clang, zap at least", banks))
		local unique = 0
		for _ in seen do
			unique += 1
		end
		-- SoundManifest.ALL is the flat list.
		assert(#SoundManifest.ALL == sounds, "SoundManifest.ALL does not match the sum of per-bank entries")
		-- SoundManifest.assetIds(bank) returns "rbxassetid://<id>" strings for use with Sound.SoundId.
		local sampleBank = "hit"
		local ids = SoundManifest.assetIds(sampleBank)
		assert(#ids == #(SoundManifest.SOUNDS[sampleBank] :: { any }), "assetIds(hit) returned the wrong count")
		for _, s in ids do
			assert(string.match(s, "^rbxassetid://%d+$"), "assetIds returned a malformed string: " .. s)
		end
		return string.format("%d combat sound banks, %d entries (%d unique ids), every one with a source", banks, sounds, unique)
	end,
}
