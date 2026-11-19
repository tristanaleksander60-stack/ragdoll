--!strict
-- 10 Nov 2026, after the launch numbers: free gifts for time played, and the owner's SPECTATE.
--   gifts: a weapon egg at 2, 5, 10 and 15 min of play a day, each once (a second look at the same
--     minute gives nothing), shown on the player (GiftAt counts down, GiftLeft), none past full
--     egg slots (the clock waits and gives it once there is room), all four done: no clock
--   spectate: owner only; the owner's streaming follows the one watched (ReplicationFocus), STOP
--     clears it, someone not here is refused

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Progress = require(Shared:WaitForChild("Progress"))
local Systems = script.Parent.Parent:WaitForChild("Systems")
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local PlaytimeGifts = require(Systems:WaitForChild("PlaytimeGifts"))
local AdminService = require(Systems:WaitForChild("AdminService"))
local Owner = require(Systems:WaitForChild("Owner"))

local function gifts(results: { string }, p: Player)
	local profile = ProgressService.profileForTest(p) :: any
	assert(profile, "no profile")
	local eggsBefore = profile.eggs
	local ok, err = pcall(function()
		profile.eggs = 0
		PlaytimeGifts.joinForTest(p)
		assert(p:GetAttribute("GiftLeft") == 4, "not 4 gifts a day")
		local at = p:GetAttribute("GiftAt")
		assert(type(at) == "number" and math.abs(at - workspace:GetServerTimeNow() - 120) < 3, "the first gift is not 2 minutes away")
		PlaytimeGifts.addForTest(p, 119)
		assert(profile.eggs == 0, "a gift before 2 minutes")
		PlaytimeGifts.addForTest(p, 1)
		assert(profile.eggs == 1 and p:GetAttribute("GiftLeft") == 3, "no egg at 2 minutes")
		PlaytimeGifts.addForTest(p, 0)
		assert(profile.eggs == 1, "the same gift twice")
		local next = p:GetAttribute("GiftAt") :: number
		assert(math.abs(next - workspace:GetServerTimeNow() - 180) < 3, "the second gift is not at 5 minutes")
		-- Full slots: the clock waits at 5 minutes, then gives with room.
		profile.eggs = Progress.MAX_EGGS
		PlaytimeGifts.addForTest(p, 180)
		assert(profile.eggs == Progress.MAX_EGGS and p:GetAttribute("GiftLeft") == 3, "a gift past full egg slots")
		profile.eggs = 0
		PlaytimeGifts.addForTest(p, 0)
		assert(profile.eggs == 1 and p:GetAttribute("GiftLeft") == 2, "the gift that waited did not come with room")
		PlaytimeGifts.addForTest(p, 300)
		PlaytimeGifts.addForTest(p, 300)
		assert(profile.eggs == 3 and p:GetAttribute("GiftLeft") == 0 and p:GetAttribute("GiftAt") == nil, "the day's last gifts")
		PlaytimeGifts.addForTest(p, 3600)
		assert(profile.eggs == 3, "a fifth gift")
	end)
	PlaytimeGifts.leaveForTest(p)
	profile.eggs = eggsBefore
	assert(ok, err)
	table.insert(results, "gifts: eggs at 2, 5, 10, 15 min, once each, the clock on the player, none past full slots (it waits), none after the fourth")
end

local function spectate(results: { string }, p: Player)
	Owner.studioOwnerForTest = false
	local refused = not AdminService.request(p, "Spectate", p.UserId)
	Owner.studioOwnerForTest = true -- (back before any assert: later tests need the owner)
	assert(refused, "a non-owner could spectate")
	-- (The only player here is the owner: watching themselves or someone gone is refused.)
	assert(not AdminService.request(p, "Spectate", p.UserId) and AdminService.watchingOf(p) == nil, "the owner watched themselves")
	assert(not AdminService.request(p, "Spectate", 1) and p.ReplicationFocus == nil, "someone not here was watched")
	assert(AdminService.request(p, "Spectate", nil) and p.ReplicationFocus == nil, "STOP failed")
	table.insert(results, "spectate: owner only, never yourself or someone not here, STOP always works")
end

return {
	name = "playtime-gifts-spectate",
	timeout = 30,
	run = function(): string?
		local results = {}
		local waited = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - waited < 20 do
			task.wait(0.2) -- (a short run can start before the player has joined)
		end
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		local started = os.clock()
		while not ProgressService.isLoaded(p) and os.clock() - started < 10 do
			task.wait(0.1)
		end
		gifts(results, p)
		spectate(results, p)
		return table.concat(results, "; ")
	end,
}
