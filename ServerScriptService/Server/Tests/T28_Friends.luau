--!strict
-- Friends (phase G), through the server's own code (Studio has one player, so the player stands
-- in for their own friend where a second one is needed):
--   only Roblox friends: a player who is not a friend, nobody, or an unknown kind is refused
--   a nuke: the warning ring and the bomb come down for 3 s, then the boom sends the friend flying
--     (ragdolled, not hurt); a prank sends them flying a silly way
--   one nuke per 10 minutes and one prank per 5 from each player, one hit per minute on anyone,
--     and "friends can prank me" off refuses both
--   switches only take a true or false; joining checks the id and the friendship
--   the friend boost: every second takedown counts one extra

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local FriendsService = require(Systems:WaitForChild("FriendsService"))
local HordeService = require(Systems:WaitForChild("HordeService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local PlayerRagdoll = require(Systems:WaitForChild("PlayerRagdoll"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local Blasts = require(Systems:WaitForChild("Blasts"))
local Dummies = require(game:GetService("ReplicatedStorage").Shared.Dummies)

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.05)
	end
	return check()
end

local function body(results: { string }, player: Player)
	FriendsService.resetForTest(player)
	-- 1. Only friends.
	FriendsService.selfForTest(false)
	assert(FriendsService.refusal(player, player, "Nuke") ~= nil, "a player nuked themselves (not a friend)")
	assert(FriendsService.refusal(player, nil, "Nuke") ~= nil, "a nuke on nobody was allowed")
	FriendsService.selfForTest(true)
	FriendsService.notFriendsForTest(true)
	local notFriends = FriendsService.refusal(player, player, "Nuke")
	FriendsService.notFriendsForTest(false)
	assert(notFriends == "Only your Roblox friends", "a nuke on someone who is not a Roblox friend: " .. tostring(notFriends))
	assert(FriendsService.refusal(player, player, "Hug") ~= nil, "an unknown kind was allowed")
	assert(FriendsService.refusal(player, player, "Nuke") == nil, "a nuke on a friend was refused: " .. tostring(FriendsService.refusal(player, player, "Nuke")))
	table.insert(results, "not friends, nobody and unknown kinds refused")

	-- 2. A nuke, for real: the ring and bomb, then the friend goes flying.
	local ok = FriendsService.send(player, player, "Nuke")
	assert(ok, "the nuke was not sent")
	local fx = Workspace:FindFirstChild("FriendFx")
	assert(fx and fx:FindFirstChild("NukeRing") and fx:FindFirstChild("Nuke"), "no warning ring or bomb")
	local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
	local health = humanoid.Health
	task.wait(1)
	assert(not PlayerRagdoll.isDown(player), "the friend went flying before the nuke landed")
	assert(waitFor(function()
		return PlayerRagdoll.isDown(player)
	end, 4), "the nuke did not send the friend flying")
	assert(not (fx :: Folder):FindFirstChild("NukeRing"), "the warning ring stayed")
	assert(humanoid.Health >= health, "the nuke hurt the friend")
	table.insert(results, "nuke: ring and bomb for 3 s, then the friend flies (not hurt)")

	-- 3. Limits.
	local again = FriendsService.refusal(player, player, "Nuke")
	assert(again and string.find(again, "next nuke"), "a second nuke straight after was allowed: " .. tostring(again))
	local soon = FriendsService.refusal(player, player, "Prank")
	assert(soon and string.find(soon, "minute"), "a prank on someone just nuked was allowed: " .. tostring(soon))
	FriendsService.hitOnForTest(player, nil)
	PlayerRagdoll.getUp(player)
	waitFor(function()
		return not PlayerRagdoll.isDown(player)
	end, 6)
	local okPrank = FriendsService.send(player, player, "Prank")
	assert(okPrank, "a prank was refused")
	FriendsService.hitOnForTest(player, nil)
	local prankAgain = FriendsService.refusal(player, player, "Prank")
	assert(prankAgain and string.find(prankAgain, "next prank"), "a second prank straight after was allowed")
	FriendsService.resetForTest(player)
	FriendsService.onRequest(player, "Pranks", false)
	assert(player:GetAttribute("Pranks") == false, "the prank switch did not turn off")
	local kept = ProgressService.profileForTest(player)
	assert(kept and kept.noPranks == true, "the prank switch is not kept for the next visit")
	assert(FriendsService.refusal(player, player, "Prank") ~= nil, "a prank on someone with pranks off was allowed")
	FriendsService.onRequest(player, "Pranks", "no")
	assert(player:GetAttribute("Pranks") == false, "a switch took a value that is not true or false")
	FriendsService.onRequest(player, "Pranks", true)
	-- Players hitting players (round 3, M1): only when both stand in the plaza; never from or into
	-- a lab (two stand-ins with positions; Studio has one player).
	local a, b = Instance.new("Folder"), Instance.new("Folder")
	local Zones = require(game:GetService("ReplicatedStorage").Shared.Zones)
	local plaza = (workspace:GetAttribute("LabOrigin") :: Vector3) + Vector3.new(10, 3, 30)
	local inLab = Vector3.new(Zones.plotCenterX(1), plaza.Y, plaza.Z)
	assert(Blasts.pvpReaches(a, b, plaza, plaza + Vector3.new(4, 0, 0)), "a blast between two players in the plaza did not reach")
	assert(not Blasts.pvpReaches(a, b, plaza, inLab) and not Blasts.pvpReaches(b, a, inLab, plaza), "a blast reached into (or out of) a lab")
	assert(not Blasts.pvpReaches(a, a, plaza, plaza), "the player path reached the one who set it off")
	-- A hit on a player in the plaza knocks them over once, then not again for HitService.PLAZA_GAP
	-- (lying, getting up and a moment after), and never from further than PLAYER_REACH (the player
	-- stands in for both: Studio has one).
	do
		local HitService = require(script.Parent.Parent:WaitForChild("Systems"):WaitForChild("HitService"))
		local Toys = require(game:GetService("ReplicatedStorage").Shared.Toys)
		local punch = Toys.byId.Punch
		local wasAt = player.Character:GetPivot() -- (put back after: the horde below runs at the player)
		PlayerRagdoll.getUp(player) -- (still down from the nuke above)
		waitFor(function()
			return not PlayerRagdoll.isDown(player)
		end, 6)
		player.Character:PivotTo(CFrame.new(plaza))
		task.wait(HitService.PLAZA_GAP) -- (and clear of any knock before)
		local root = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart
		assert(HitService.plazaHit(player, player, punch, root.Position, Vector3.new(1, 0, 0)), "a plaza hit did not land (down: " .. tostring(PlayerRagdoll.isDown(player)) .. ")")
		assert(not HitService.plazaHit(player, player, punch, root.Position, Vector3.new(1, 0, 0)), "a second plaza hit straight after landed")
		local told = HitService.lastRefusal[player]
		assert(told and told.reason == "GettingUp", "the second hit was refused without a word")
		assert(type(player:GetAttribute("KnockSafeUntil")) == "number", "screens are not told the player is safe for a moment")
		-- Blasts share the same wait (firecrackers at someone's feet cannot keep them down).
		assert(not PlayerRagdoll.plazaKnock(player, Vector3.new(0, 30, 0)), "a blast knocked the player again during the wait")
		PlayerRagdoll.getUp(player)
		waitFor(function()
			return not PlayerRagdoll.isDown(player)
		end, 4)
		task.wait(0.3)
		assert(not HitService.plazaHit(player, player, punch, root.Position, Vector3.new(1, 0, 0)) or HitService.PLAZA_GAP < 2, "knocked again right after getting up")
		task.wait(HitService.PLAZA_GAP)
		assert(not HitService.plazaHit(player, player, punch, root.Position + Vector3.new(HitService.PLAYER_REACH + 10, 0, 0), Vector3.new(1, 0, 0)), "a plaza hit from beyond the reach landed")
		PlayerRagdoll.getUp(player)
		waitFor(function()
			return not PlayerRagdoll.isDown(player)
		end, 4)
		player.Character:PivotTo(wasAt)
		table.insert(results, string.format("a plaza hit knocks once, then not for %.1f s (getting up included; told GettingUp; blasts share the wait), never from beyond %d studs", HitService.PLAZA_GAP, HitService.PLAYER_REACH))
	end
	-- Pranks switched off while a nuke falls: it lands on nobody.
	FriendsService.resetForTest(player)
	PlayerRagdoll.getUp(player)
	waitFor(function()
		return not PlayerRagdoll.isDown(player)
	end, 6)
	assert(FriendsService.send(player, player, "Nuke"), "the second nuke was not sent")
	task.wait(0.5)
	FriendsService.onRequest(player, "Pranks", false)
	task.wait(3.5)
	assert(not PlayerRagdoll.isDown(player), "a nuke landed on someone who switched pranks off while it fell")
	FriendsService.onRequest(player, "Pranks", true)
	table.insert(results, "players reach players only in the plaza; pranks off during the countdown: the nuke lands on nobody")
	-- Your lab is private: a friend let in may enter it, and not once let out again; nobody else
	-- (a stand-in guest: Studio has one player). Only friends in this server can be invited.
	FriendsService.resetForTest(player)
	local Zones2 = require(game:GetService("ReplicatedStorage").Shared.Zones)
	local mine = player:GetAttribute("LabPlot") :: number
	assert(type(mine) == "number", "the player has no lab")
	local guest = { UserId = 424242 } :: any
	local stranger = { UserId = 515151 } :: any
	assert(Zones2.mayEnter(player, mine) and not Zones2.mayEnter(guest, mine), "before the invite: owner in, guest out")
	FriendsService.setLabGuest(player, 424242, true)
	assert(Zones2.mayEnter(guest, mine) and not Zones2.mayEnter(stranger, mine), "invited: the guest may enter, nobody else")
	assert(Zones2.mayReach(guest, Vector3.new(Zones2.plotCenterX(mine), 3, 0)), "an invited guest cannot reach into the lab")
	FriendsService.setLabGuest(player, 424242, false)
	assert(not Zones2.mayEnter(guest, mine), "uninvited, the guest may still enter")
	-- (Studio's test players have negative ids.)
	FriendsService.setLabGuest(player, -2, true)
	assert(Zones2.isGuest(player, -2), "a negative id was not let in")
	FriendsService.setLabGuest(player, -2, false)
	assert(not Zones2.isGuest(player, -2), "a negative id was not let out again")
	FriendsService.onRequest(player, "LabInvite", 99999999)
	assert(not string.find((player:GetAttribute("LabGuests") :: string?) or "", "99999999", 1, true), "someone not in the server was invited")
	FriendsService.onRequest(player, "LabInvite", player.UserId)
	assert(not Zones2.isGuest(player, player.UserId), "a player invited themselves")
	assert(FriendsService.INVITE_TOAST_GAP >= 10, "invite toasts are not spaced")
	-- Leaving and coming back does not reset a cooldown (kept by user id).
	FriendsService.send(player, player, "Prank")
	FriendsService.hitOnForTest(player, nil)
	local still = FriendsService.refusal(player, player, "Prank")
	assert(still and string.find(still, "next prank"), "the prank cooldown was not kept")
	table.insert(results, "one nuke per 10 min, one prank per 5 (by user id), one hit per minute on a player; pranks off refuses and is kept; a lab guest let in and out again (nobody else, never yourself, never someone not here); switches take only true/false")

	-- 4. Joining.
	assert(not FriendsService.join(player, "abc"), "a join with a text id went ahead")
	assert(not FriendsService.join(player, -5), "a join with a negative id went ahead")
	FriendsService.resetForTest(player)
	table.insert(results, "joins with a bad id refused")

	-- 5. The friend boost.
	local profile = assert(ProgressService.profileForTest(player), "no profile")
	local boost = ProgressService.boost
	ProgressService.boost = function()
		return true
	end
	ProgressService.resetComboForTest(player)
	local before = profile.takedowns
	local origin = (Workspace:GetAttribute("LabOrigin") :: Vector3?) or Vector3.zero
	for i = 1, 2 do
		local d = DummyFactory.spawn(origin + Vector3.new(30 + i * 6, 0, -70), origin + Vector3.new(30 + i * 6, 0, -69))
		task.wait(0.2)
		Dummies.setBlame(d, player.UserId)
		d:SetAttribute("ServerHitAt", Workspace:GetServerTimeNow())
		d:SetAttribute("ServerHitBy", player.UserId)
		ProgressService.onDownForTest(d, "Ragdoll")
		d:Destroy()
	end
	ProgressService.boost = boost
	assert(profile.takedowns == before + 3, string.format("two takedowns with a friend here counted %d", profile.takedowns - before))
	table.insert(results, "friend boost: two takedowns counted 3")

	-- 6. The co-op horde: runners charge from the plaza; knocking one down earns the bonus at the end.
	HordeService.stopForTest()
	local h = assert(HordeService.start(0), "the horde did not start")
	assert(waitFor(function()
		return #h.runners > 0
	end, 3), "no runners came")
	local expectedCount = math.min(HordeService.MAX_RUNNERS, HordeService.BASE_RUNNERS + HordeService.PER_PLAYER * #Players:GetPlayers())
	assert(#h.runners == expectedCount, string.format("%d runners (expected %d)", #h.runners, expectedCount))
	local first = h.runners[1].model
	local startZ = (first:FindFirstChild("LowerTorso") :: BasePart).Position.Z
	task.wait(2)
	assert((first:FindFirstChild("LowerTorso") :: BasePart).Position.Z < startZ - 4, "the horde does not charge at the lab")
	local chest = first:FindFirstChild("UpperTorso") :: BasePart
	DummyControl.hit(first, chest, Vector3.new(0, 70, 0) * ((first:GetAttribute("Mass") :: number?) or 10), chest.Position, nil, player)
	assert(waitFor(function()
		return h.runners[1].down
	end, 3), "a runner knocked down was not counted")
	local beforeBonus = profile.takedowns
	HordeService.finishForTest(h, "Time")
	assert(profile.takedowns >= beforeBonus + HordeService.BONUS, "the helper got no bonus")
	assert(waitFor(function()
		return first.Parent == nil
	end, 5), "the horde stayed after it ended")
	table.insert(results, string.format("horde: %d runners charge the lab; a knock-down counts; +%d for the helper at the end; then they go", expectedCount, HordeService.BONUS))
end

return {
	name = "friends-nuke-prank-limits-boost",
	timeout = 90,
	run = function(): string?
		waitFor(function()
			local first = Players:GetPlayers()[1]
			return first ~= nil and first.Character ~= nil and ProgressService.profileForTest(first) ~= nil
		end, 20)
		local player = Players:GetPlayers()[1]
		assert(player, "no player")
		local results = {}
		local ok, err = pcall(body, results, player)
		FriendsService.selfForTest(false)
		FriendsService.resetForTest(player)
		player:SetAttribute("Pranks", true)
		player:SetAttribute("PvP", false)
		pcall(PlayerRagdoll.getUp, player)
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
