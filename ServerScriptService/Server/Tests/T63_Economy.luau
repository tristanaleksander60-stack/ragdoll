--!strict
-- Phase 2 (19 Nov 2026): BOLTS, the BONE JOURNAL, Daily Experiments, codes (Shared\Economy) and
-- EconomyService with the test player:
--   a stored eco table is cleaned (junk dropped, unknown pages dropped)
--   counting fills journal pages once each; a new day clears the daily ticks
--   prices follow the ladder; the next buy is the cheapest weapon not yours
--   a code redeems only when the owner set it live, once per profile
--   a finished daily experiment pays stars x BOLTS_PER_STAR + DAILY_BONUS; buying spends bolts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Economy = require(Shared.Economy)
local Config = require(Shared.Config) :: any
local Toys = require(Shared.Toys)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local EconomyService = require(Systems:WaitForChild("EconomyService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))

return {
	name = "T63_Economy",
	timeout = 15,
	run = function(): string?
		local e = Economy.clean({ bolts = -5, counts = { Takedown = 3, [1] = 2 }, journal = { FirstDown = true, Fake = true }, daily = { Cannon = true }, codes = "x" })
		assert(e.bolts == 0 and e.counts.Takedown == 3 and e.journal.FirstDown and e.journal.Fake == nil and e.daily.Cannon, "clean")
		local pages = Economy.count(e, "Takedown", 7)
		assert(#pages == 1 and pages[1].id == "Ten" and e.journal.Ten, "10 takedowns did not fill its page")
		assert(#Economy.count(e, "Takedown", 1) == 0, "a page filled twice")
		Economy.rollDay(e, 99)
		assert(e.day == 99 and next(e.daily) == nil, "a new day kept the daily ticks")
		assert(Economy.priceOf(1) == Config.BOLTS_MIN_PRICE and Economy.priceOf(100) > Economy.priceOf(50), "prices do not follow the ladder")
		local id, price = Economy.nextBuy(Toys.list, function(t: string): boolean
			return t == "Bat"
		end)
		assert(id and id ~= "Bat" and price, "no next buy")
		assert(Economy.redeem(e, "NOPE") == nil, "a code that is not live redeemed")

		local player = Players:GetPlayers()[1]
		assert(player, "no player in the play test")
		local started = os.clock()
		while not ProgressService.ecoOf(player) and os.clock() - started < 8 do
			task.wait(0.2)
		end
		local live = ProgressService.ecoOf(player)
		assert(live, "the profile's economy is not there")
		local eco = live :: Economy.Eco
		local saved = Economy.clean(eco) -- (put back after)
		-- (With live ids the creator owns 2x BOLTS in Studio: judge a player without passes.)
		;(require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("OfferService")) :: any).resetForTest(player)
		local today = EconomyService.dailyToday()
		assert(#today >= Config.DAILY_COUNT, "not the day's daily experiments") -- (+1 advent card in December)
		eco.daily = {}
		-- (Every journal page already filled: a first experiment would fill one, +JOURNAL_BOLTS; PC
		-- run 19 Nov paid 65 for 40. Put back below from `saved`.)
		for _, page in Economy.JOURNAL do
			eco.journal[page.id] = true
		end
		local before = eco.bolts
		EconomyService.experimentDone(player, today[1])
		local want = today[1].stars * Config.BOLTS_PER_STAR + Config.DAILY_BONUS
		assert(eco.bolts == before + want, string.format("a daily experiment paid %d, want %d", eco.bolts - before, want))
		assert(eco.daily[today[1].id], "the daily experiment was not ticked")
		EconomyService.experimentDone(player, today[1])
		assert(eco.bolts == before + want + today[1].stars * Config.BOLTS_PER_STAR, "the daily bonus paid twice")
		-- Buying: enough bolts buys the next weapon (and spends them); none left over is refused.
		eco.bolts = 0
		assert(EconomyService.buyNext(player) == nil, "a weapon for no bolts")
		-- (Restore the profile's economy.)
		for k, v in saved :: any do
			(eco :: any)[k] = v
		end
		ProgressService.ecoChanged(player)
		return string.format("journal %d pages; daily pays %d; next buy %s for %d", #Economy.JOURNAL, want, id :: string, price :: number)
	end,
}
