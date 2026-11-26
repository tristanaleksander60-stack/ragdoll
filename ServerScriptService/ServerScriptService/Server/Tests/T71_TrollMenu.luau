--!strict
-- Round 3, M8: the owner's troll menu (AdminService).
--   only the owner (refused for anyone else); fixed choices only: a target that is not a player
--     here, an unknown action or junk is refused; the same action on the same player waits
--     COOLDOWN s; every action done is in the log with who did what to whom
--   every action happens to the player: ragdoll, fling and sky launch (sent to their screen);
--     frozen in ice for FREEZE_TIME s then free; tiny or giant then their own size again (one at
--     a time); a spin that stops; a dummy rain and NPC chasers, all guests marked NoCredit, the
--     chasers after the player and gone when it ends; a present that pops and holds nothing
--   nothing touches their profile: takedowns, eggs, hats, weapons are the same after all of it

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local AdminService = require(Systems:WaitForChild("AdminService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local ChristmasService = require(Systems:WaitForChild("ChristmasService"))
local Owner = require(Systems:WaitForChild("Owner"))

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function waitFor(check: () -> boolean, seconds: number): boolean
	local started = os.clock()
	while not check() do
		if os.clock() - started > seconds then
			return false
		end
		task.wait(0.1)
	end
	return true
end

return {
	name = "troll-menu-owner-only-harmless",
	timeout = 80,
	run = function(): string?
		-- (Run on its own, the suite can start before the player is in.)
		waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		local results = {}
		local saved = { AdminService.FREEZE_TIME, AdminService.SIZE_TIME, AdminService.CHASE_TIME, AdminService.SPIN_TIME }
		AdminService.FREEZE_TIME, AdminService.SIZE_TIME, AdminService.CHASE_TIME, AdminService.SPIN_TIME = 1.5, 1.5, 3, 1
		local ok, err = pcall(function()
			assert(waitFor(function()
				local c = p.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				return h ~= nil and h.Health > 0 and c:FindFirstChild("HumanoidRootPart") ~= nil
			end, 10), "no live avatar")
			-- (Loaded, and the day's egg in, 4 s after: the game's own, not a troll's.)
			assert(waitFor(function()
				return ProgressService.isLoaded(p)
			end, 10), "the profile never loaded")
			task.wait(5)
			local profile = ProgressService.profileForTest(p) :: any
			assert(profile, "no profile")
			local before = { profile.takedowns, profile.eggs, count(profile.hats), count(profile.owned), profile.hat }
			local function ask(kind: string, arg: any): boolean
				AdminService.resetPaceForTest(p)
				return AdminService.request(p, kind, arg)
			end
			local function troll(action: string): boolean
				return ask("Troll", { target = p.UserId, action = action })
			end

			-- The owner only, fixed choices only.
			Owner.studioOwnerForTest = false
			assert(not troll("Fling"), "a non-owner trolled")
			Owner.studioOwnerForTest = true
			assert(not ask("Troll", { target = tostring(p.UserId), action = "Fling" }), "a target as text was taken")
			assert(not ask("Troll", { target = 1, action = "Fling" }), "a player not here was trolled")
			assert(not ask("Troll", { target = p.UserId, action = "Ban" }), "an unknown action was taken")
			assert(not ask("Troll", "Fling"), "junk was taken")
			table.insert(results, "a non-owner, a target as text, someone not here, an unknown action and junk refused")

			-- Ragdoll, fling, launch.
			for _, action in { "Ragdoll", "Fling", "Launch" } do
				assert(troll(action), action .. " did not happen")
			end
			assert(not troll("Fling"), "the same action again inside the cooldown")
			table.insert(results, "ragdoll, fling, sky launch sent; the same again within " .. AdminService.COOLDOWN .. " s refused")
			-- (Down and up again before the next.)
			task.wait(4)

			-- Freeze.
			local root = (p.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
			assert(troll("Freeze"), "freeze did not happen")
			assert(root.Anchored and Workspace:FindFirstChild("TrollIce"), "not frozen in ice")
			assert(not troll("Fling"), "flung while frozen in ice")
			assert(waitFor(function()
				return not root.Anchored and not Workspace:FindFirstChild("TrollIce")
			end, 3), "still frozen after the time")
			table.insert(results, "frozen in ice (no fling meanwhile), free again after the time")

			-- Tiny, giant, one at a time.
			local character = p.Character :: Model
			assert(troll("Small"), "tiny did not happen")
			assert(math.abs(character:GetScale() - 0.5) < 0.01, "not tiny")
			assert(not troll("Giant"), "giant on top of tiny")
			assert(waitFor(function()
				return math.abs(character:GetScale() - 1) < 0.01
			end, 3), "still tiny after the time")
			task.wait(0.2)
			assert(troll("Giant") and math.abs(character:GetScale() - 2) < 0.01, "giant did not happen")
			assert(waitFor(function()
				return math.abs(character:GetScale() - 1) < 0.01
			end, 3), "still giant after the time")
			table.insert(results, "tiny then their size, giant then their size, never both at once")

			-- Spin.
			assert(troll("Spin") and root:FindFirstChild("TrollSpin"), "no spin")
			assert(waitFor(function()
				return root:FindFirstChild("TrollSpin") == nil
			end, 3), "still spinning after the time")
			table.insert(results, "a spin that stops")

			-- A new body is a fresh start: frozen and tiny, then respawned: no ice, a new size at once.
			AdminService.resetCooldownsForTest(p)
			assert(troll("Freeze") and troll("Small"), "freeze and tiny did not happen")
			local old = p.Character
			p:LoadCharacter()
			assert(waitFor(function()
				local c = p.Character
				return c ~= nil and c ~= old and c:FindFirstChild("HumanoidRootPart") ~= nil and (c:FindFirstChildOfClass("Humanoid") :: Humanoid).Health > 0
			end, 10), "no new body")
			task.wait(0.5)
			assert(not Workspace:FindFirstChild("TrollIce"), "the ice stayed after a new body")
			AdminService.resetCooldownsForTest(p)
			assert(troll("Giant"), "a new body was still 'another size'")
			assert(troll("Fling"), "a new body was still 'frozen'")
			task.wait(AdminService.SIZE_TIME + 0.5)
			root = (p.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
			character = p.Character :: Model
			table.insert(results, "a new body clears it all (no ice, a new size and a fling at once)")

			-- Dummy rain and chasers: guests, NoCredit.
			local dummies = Workspace:FindFirstChild("Dummies")
			local function guests(name: string?): { Model }
				local list = {}
				for _, m in (if dummies then dummies:GetChildren() else Workspace:GetChildren()) do
					if m:IsA("Model") and m:GetAttribute("Guest") == true and (not name or m.Name == name) then
						table.insert(list, m)
					end
				end
				return list
			end
			local guestsBefore = #guests()
			assert(troll("Rain"), "no dummy rain")
			assert(#guests() > guestsBefore, "the rain brought no bodies")
			for _, m in guests() do
				assert(m:GetAttribute("NoCredit") == true, "a guest body earns credit")
			end
			assert(troll("Chase"), "no chase")
			local chasers = guests("TrollChaser")
			assert(#chasers >= 1, "no chasers")
			task.wait(0.7)
			local r = (p.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
			for _, m in chasers do
				local home = m:GetAttribute("Home")
				assert(m:GetAttribute("NoCredit") == true and typeof(home) == "Vector3" and ((home :: Vector3) - r.Position).Magnitude < 6, "a chaser is not after the player")
			end
			assert(waitFor(function()
				return #guests("TrollChaser") == 0
			end, 5), "chasers left after the chase")
			table.insert(results, string.format("dummy rain and %d chasers, all guests with no credit, the chasers after the player and gone when it ends", #chasers))

			-- Present: pops, holds nothing.
			local eggs = profile.eggs
			assert(troll("Present"), "no present")
			assert(Workspace:FindFirstChild("PrankPresent"), "no present falling")
			assert(waitFor(function()
				return Workspace:FindFirstChild("PrankPresent") == nil
			end, ChristmasService.PRANK_POP + 2), "the present did not pop")
			assert(profile.eggs == eggs, "the prank present gave an egg")
			table.insert(results, "a present falls and pops, no egg")

			-- Nothing of theirs touched, all of it logged.
			local after = { profile.takedowns, profile.eggs, count(profile.hats), count(profile.owned), profile.hat }
			for i = 1, #before do
				assert(before[i] == after[i], "the profile changed (" .. i .. ")")
			end
			local log = AdminService.logForTest()
			assert(#log >= 5 and string.find(log[1], p.DisplayName, 1, true) and string.find(log[1], "dropped a present on", 1, true), "the log is missing actions")
			table.insert(results, "takedowns, eggs, hats and weapons the same after all of it; logged (\"" .. log[1] .. "\")")
		end)
		AdminService.FREEZE_TIME, AdminService.SIZE_TIME, AdminService.CHASE_TIME, AdminService.SPIN_TIME = saved[1], saved[2], saved[3], saved[4]
		Owner.studioOwnerForTest = true
		AdminService.resetPaceForTest(p)
		AdminService.resetCooldownsForTest(p)
		assert(ok, err)
		return table.concat(results, "; ")
	end,
}
