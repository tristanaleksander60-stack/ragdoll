--!strict
-- Round 5, phase 1b: TRY FREE, through TrialService and ProgressService.isUnlocked.
--   a locked weapon opens for the try; one try at a time; the same weapon once a day; a weapon
--   already yours is refused; junk is ignored; the end of the try locks it again

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local TrialService = require(Systems:WaitForChild("TrialService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

local function body(player: Player): string
	local p = ProgressService.profileForTest(player) :: any
	assert(p, "no profile")
	local keep = { takedowns = p.takedowns, owned = table.clone(p.owned) }
	player:SetAttribute("UnlockAll", nil)
	-- (With live ids the creator owns every pass in Studio: judge a player with none.)
	;(require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("OfferService")) :: any).resetForTest(player)
	p.takedowns = 0
	ProgressService.setOwnedForTest(player, {})
	TrialService.resetForTest(player)
	local ok, err = pcall(function()
		local katana, axe = Toys.byId.Katana, Toys.byId.Axe
		assert(not ProgressService.isUnlocked(player, katana), "the Katana was open before the try")
		assert(TrialService.try(player, 42) == "junk" and TrialService.try(player, "Nope") == "junk" and TrialService.try(player, "Blaster") == "junk", "junk or a free weapon was tried")
		assert(TrialService.try(player, "Katana") == nil, "the try did not start")
		assert(ProgressService.isUnlocked(player, katana), "the Katana is not open during its try")
		assert(not ProgressService.isUnlocked(player, katana, true), "a try counted as owning it")
		assert(TrialService.try(player, "Axe") ~= nil and not ProgressService.isUnlocked(player, axe), "a second try ran at once")
		-- The end: locked again, and the Katana not again today.
		player:SetAttribute("TrialUntil", workspace:GetServerTimeNow() - 1)
		assert(not ProgressService.isUnlocked(player, katana), "the Katana stayed open after the try")
		player:SetAttribute("TrialWeapon", nil)
		player:SetAttribute("TrialUntil", nil)
		assert(TrialService.try(player, "Katana") ~= nil, "the Katana was tried twice in a day")
		assert(TrialService.try(player, "Axe") == nil, "another weapon could not be tried after the first ended")
		ProgressService.setOwnedForTest(player, { Cleaver = true })
		player:SetAttribute("TrialWeapon", nil)
		player:SetAttribute("TrialUntil", nil)
		assert(TrialService.try(player, "Cleaver") ~= nil, "a weapon already owned was tried")
	end)
	TrialService.resetForTest(player)
	player:SetAttribute("TrialWeapon", nil)
	player:SetAttribute("TrialUntil", nil)
	p.takedowns = keep.takedowns
	ProgressService.setOwnedForTest(player, keep.owned)
	player:SetAttribute("UnlockAll", true)
	if not ok then
		error(err, 0)
	end
	return "a locked weapon opens for its try (not owned), one at a time, once a day each, an owned one refused, junk ignored, locked again after"
end

return {
	name = "try-free",
	timeout = 30,
	run = function(): string?
		local started = os.clock()
		while os.clock() - started < 25 and not (Players:GetPlayers()[1] and ProgressService.isLoaded(Players:GetPlayers()[1])) do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		if not player or not ProgressService.isLoaded(player) then
			return "skipped (no player)"
		end
		return body(player)
	end,
}
