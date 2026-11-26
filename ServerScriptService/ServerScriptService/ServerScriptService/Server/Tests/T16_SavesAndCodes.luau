--!strict
-- Saves and share codes: save a build to a slot, change it, load the slot back exactly; share it and
-- load it by its code (also typed in lower case with a space); the same build shares to the same
-- code; bad slots, bad codes and unknown codes are refused; codes never contain vowels or
-- look-alike characters. Needs a player in the session.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local BuildService = require(Systems:WaitForChild("BuildService"))
local BuildStore = require(Systems:WaitForChild("BuildStore"))
local Build = ReplicatedStorage.Shared.Build
local Orientation = require(Build.Orientation)
local Codec = require(Build.Codec)
local ShareCode = require(Build.ShareCode)

local function ok(player: Player, op: string, args: { [string]: any }?)
	local success, message = BuildService.request(player, op, args)
	assert(success, op .. " failed: " .. tostring(message))
end

local function store(player: Player, op: string, arg: any?): (boolean, string?, any)
	return BuildStore.direct(player, op, arg)
end

return {
	name = "workshop-saves-and-share-codes",
	timeout = 40,
	run = function(): string?
		local waited = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player, "needs a player in the session")

		-- Codes
		local rng = Random.new(11)
		for _ = 1, 500 do
			local code = ShareCode.generate(rng)
			assert(#code == ShareCode.LENGTH and ShareCode.normalize(code) == code, "bad code " .. code)
			assert(not string.find(code, "[AEIOUY015SLO]"), "code with a vowel or look-alike: " .. code)
		end
		assert(ShareCode.normalize(" bcd-fg h") == "BCDFGH", "typed code not cleaned up")
		assert(ShareCode.normalize("BCDFG") == nil and ShareCode.normalize("BCDFGHJ") == nil, "wrong length accepted")
		assert(ShareCode.normalize("BCDFGA") == nil and ShareCode.normalize(42) == nil, "bad characters accepted")
		assert(ShareCode.filter("ab1c-dxyz9") == "BCDXZ9", "filter kept the wrong characters: " .. ShareCode.filter("ab1c-dxyz9"))

		ok(player, "stop")
		ok(player, "clear")
		local up = Orientation.facingUp(Vector3.yAxis, 0)
		ok(player, "place", { item = "Plate", pos = Vector3.new(-40, 0.5, 30), rot = 0, parent = 0 })
		ok(player, "place", { item = "Motor", pos = Vector3.new(-40, 2, 30), rot = up, parent = 1, parentPart = 1 })
		ok(player, "place", { item = "Beam", pos = Vector3.new(-40, 3.5, 30), rot = 0, parent = 2, parentPart = 2 })
		ok(player, "tune", { index = 2 })
		ok(player, "paint", { index = 3, color = 5 })
		local original = BuildService.blueprintOf(player)
		local originalPacked = Codec.pack(original)

		-- Slots
		local saved, message, payload = store(player, "save", 2)
		assert(saved, "save failed: " .. tostring(message))
		assert(type(payload) == "table" and payload.slots[2] and payload.slots[2].pieces == 3 and payload.slots[1] == false,
			"slot list after saving is wrong")
		assert(not store(player, "save", 0) and not store(player, "save", 4) and not store(player, "save", 1.5)
			and not store(player, "save", "1"), "a bad slot was accepted")
		ok(player, "clear")
		ok(player, "place", { item = "Block", pos = Vector3.new(-30, 1, 30), rot = 0, parent = 0 })
		assert(not store(player, "load", 1), "loading an empty slot worked")
		local loaded, why = store(player, "load", 2)
		assert(loaded, "load failed: " .. tostring(why))
		assert(Codec.pack(BuildService.blueprintOf(player)) == originalPacked, "the loaded build is not the saved one")
		local listed, _, list = store(player, "list")
		assert(listed and list.slots[2] and list.slots[2].pieces == 3, "list does not show the save")

		-- Loading while playing stops the machine first.
		ok(player, "play")
		assert(store(player, "load", 2), "load while playing failed")
		assert(not BuildService.isPlaying(player), "still playing after a load")

		-- Share codes
		local shared, shareWhy, share = store(player, "share")
		assert(shared and type(share) == "table" and ShareCode.normalize(share.code) == share.code, "share failed: " .. tostring(shareWhy))
		local again, _, share2 = store(player, "share")
		assert(again and share2.code == share.code, "the same build got a new code")
		ok(player, "clear")
		local typed = string.lower(string.sub(share.code, 1, 3)) .. " " .. string.sub(share.code, 4)
		local byCode, codeWhy = store(player, "code", typed)
		assert(byCode, "loading by code failed: " .. tostring(codeWhy))
		assert(Codec.pack(BuildService.blueprintOf(player)) == originalPacked, "the build from the code is not the shared one")
		local unknown = "BCDFGH"
		if unknown == share.code then
			unknown = "BCDFGJ"
		end
		assert(not store(player, "code", unknown), "an unknown code loaded something")
		assert(not store(player, "code", "hello!") and not store(player, "code", nil), "a bad code was accepted")

		-- A changed build shares to a new code.
		ok(player, "paint", { index = 1, color = 2 })
		local _, _, share3 = store(player, "share")
		assert(share3 and share3.code ~= share.code, "a changed build kept the old code")

		-- An empty table cannot be saved or shared.
		ok(player, "clear")
		assert(not store(player, "save", 3) and not store(player, "share"), "an empty build was saved or shared")
		assert(store(player, "delete", 2), "delete failed")
		local _, _, after = store(player, "list")
		assert(after.slots[2] == false, "the slot is not empty after delete")

		return string.format("slot save/load exact, codes %s and %s, bad input refused%s", share.code, share3.code,
			if BuildStore.isInMemory() then " (Studio memory store)" else " (DataStore)")
	end,
}
