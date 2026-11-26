--!strict
-- Round 3, M6: the plaza's leaderboards and what feeds them, and SETTINGS kept in the profile.
--   the four boards stand in the plaza (MOST TAKEDOWNS, MOST TIME PLAYED, VIP TAKEDOWNS, VIP TIME
--     PLAYED), on the floor, facing its middle, clear of its lamps, benches and fountain
--   a board's ten: every server's top with everyone here merged on top (their number now), best
--     first, ten at most; a VIP board takes VIPs only; time reads "2h 05m"
--   the player here is on the takedown board with their avatar; time played is counted on the
--     server's clock (a stalled step never counts more than a minute), kept by the save (the most
--     of two servers; added on top after a late read) and on the time board
--   SETTINGS: junk is cleaned to the defaults; a request keeps the choice in the profile and the
--     save, and it is sent back with the radio and the keys

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local LeaderboardService = require(Systems:WaitForChild("LeaderboardService"))

local function boards(results: { string })
	local folder = Workspace:WaitForChild("Boards", 15) -- (run first, it can start before the boards are up)
	assert(folder, "no Boards folder")
	local labOrigin = Workspace:GetAttribute("LabOrigin") or Vector3.zero
	local middle = (labOrigin :: Vector3) + Vector3.new(0, 0, 85)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = { folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	for _, name in { "Dummies", "Christmas" } do -- (the Christmas snow caps sit on the boards)
		local f = Workspace:FindFirstChild(name)
		if f then
			table.insert(skip, f)
		end
	end
	params.FilterDescendantsInstances = skip
	local count = 0
	for _, board in LeaderboardService.BOARDS do
		local model = folder:FindFirstChild("Board_" .. board.id)
		assert(model and model:IsA("Model"), "no board " .. board.id)
		local panel = model:FindFirstChild("Panel") :: BasePart
		local toMiddle = Vector3.new(middle.X - panel.Position.X, 0, middle.Z - panel.Position.Z).Unit
		local facing = Vector3.new(panel.CFrame.LookVector.X, 0, panel.CFrame.LookVector.Z).Unit
		assert(facing:Dot(toMiddle) > 0.99, board.id .. " does not face the plaza")
		-- Standing: its posts reach the floor.
		local lowest = math.huge
		for _, post in model:GetChildren() do
			if post:IsA("BasePart") and post.Name == "Post" then
				lowest = math.min(lowest, post.Position.Y - post.Size.Y / 2)
			end
		end
		local floor = Workspace:Raycast(panel.Position + toMiddle * 2, Vector3.new(0, -60, 0), RaycastParams.new())
		assert(floor and math.abs(lowest - floor.Position.Y) < 0.6, string.format("%s floats or sinks (posts end %.1f, floor %.1f)", board.id, lowest, if floor then floor.Position.Y else -1))
		-- Clear: nothing else in its panel (1 stud round it).
		local inside = Workspace:GetPartBoundsInBox(panel.CFrame, panel.Size + Vector3.new(2, 0, 2), params)
		local names = {}
		for _, part in inside do
			table.insert(names, part:GetFullName())
		end
		assert(#inside == 0, board.id .. " stands in " .. table.concat(names, ", "))
		count += 1
	end
	-- Not on each other either.
	local list = folder:GetChildren()
	for i = 1, #list do
		for j = i + 1, #list do
			local a = (list[i] :: Model):FindFirstChild("Panel") :: BasePart
			local b = (list[j] :: Model):FindFirstChild("Panel") :: BasePart
			assert((a.Position - b.Position).Magnitude > a.Size.X + 0.5, a.Parent.Name .. " overlaps " .. b.Parent.Name)
		end
	end
	table.insert(results, string.format("%d boards in the plaza, standing, facing its middle, clear of everything", count))
end

local function merging(results: { string })
	local global = {}
	for i = 1, 10 do
		table.insert(global, { userId = 1000 + i, name = "G" .. i, value = 200 - i * 10 })
	end
	local here = {
		{ userId = 1005, name = "Moved", value = 500 }, -- on the list: their number now wins
		{ userId = 7, name = "Newcomer", value = 175 }, -- not on it: in at their place
		{ userId = 8, name = "Nothing", value = 0 }, -- nothing yet: not shown
	}
	local rows = LeaderboardService.merge(global, here)
	assert(#rows == LeaderboardService.TOP, "not " .. LeaderboardService.TOP .. " rows: " .. #rows)
	assert(rows[1].userId == 1005 and rows[1].value == 500 and rows[1].name == "Moved", "a player here is not at their number now")
	local found7 = false
	for i, row in rows do
		if i > 1 then
			assert(row.value <= rows[i - 1].value, "not best first")
		end
		assert(row.userId ~= 8, "a zero made the board")
		found7 = found7 or row.userId == 7
	end
	assert(found7, "a newcomer above the last place was left off")
	assert(LeaderboardService.formatTime(7500) == "2h 05m" and LeaderboardService.formatTime(720) == "12m" and LeaderboardService.formatTime(45) == "45s", "time reads wrong")
	table.insert(results, string.format("a board's top %d: global top with the players here merged at their number now, best first, zeros left off; 7500 s reads 2h 05m", LeaderboardService.TOP))
end

local function player(results: { string }, p: Player)
	local profile = ProgressService.profileForTest(p) :: any
	assert(profile, "the player has no profile")
	local takedownsBefore = profile.takedowns
	profile.takedowns = math.max(profile.takedowns, 3)
	local text = LeaderboardService.textForTest("Takedowns")
	assert(string.find(text, p.DisplayName, 1, true), "the takedown board does not list the player: " .. text)
	assert(string.find(text, "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId, 1, true), "no avatar for the player")

	-- Time played: counted on the server, capped, saved and merged.
	local before = profile.playSeconds
	local added = ProgressService.countPlayForTest(p, 20)
	assert(math.abs(added - 20) < 0.5 and math.abs(profile.playSeconds - before - 20) < 0.5, string.format("20 s counted as %.1f", added))
	local stalled = ProgressService.countPlayForTest(p, 600)
	assert(stalled <= 60, string.format("a 600 s stall counted %.0f s", stalled))
	local timeText = LeaderboardService.textForTest("Time")
	assert(string.find(timeText, p.DisplayName, 1, true), "the time board does not list the player")
	local m = ProgressService.merge(ProgressService.clean({ playSeconds = 900 }), ProgressService.clean({ playSeconds = 400 }))
	assert(m.playSeconds == 900, "the merge lost time played")
	local late = ProgressService.addOntoForTest(ProgressService.clean({ playSeconds = 900 }), ProgressService.clean({ playSeconds = 60 }))
	assert(late.playSeconds == 960, "a late read lost time played")
	assert(ProgressService.clean({ playSeconds = -5 }).playSeconds == 0 and ProgressService.clean({ playSeconds = 0 / 0 }).playSeconds == 0, "bad time kept")
	assert(ProgressService.saveNowForTest(p), "saving failed")
	local stored = ProgressService.storedForTest(p) :: any
	assert(stored and math.abs(stored.playSeconds - profile.playSeconds) < 1, "time played was not saved")

	-- VIP boards: VIPs only.
	local wasVip = p:GetAttribute("VIP")
	p:SetAttribute("VIP", false)
	assert(not string.find(LeaderboardService.textForTest("VipTakedowns"), p.DisplayName, 1, true), "a non-VIP is on the VIP board")
	p:SetAttribute("VIP", true)
	assert(string.find(LeaderboardService.textForTest("VipTakedowns"), p.DisplayName, 1, true), "a VIP is not on the VIP board")
	assert(string.find(LeaderboardService.textForTest("VipTime"), p.DisplayName, 1, true), "a VIP is not on the VIP time board")
	p:SetAttribute("VIP", wasVip)
	profile.takedowns = takedownsBefore
	table.insert(results, string.format("the player on the takedown board with their avatar; 20 s played counted (a 600 s stall: %.0f s), saved, the most of two servers, added on top after a late read; VIP boards take VIPs only", stalled))

	-- SETTINGS.
	local clean = ProgressService.cleanSettings({ sfx = 9, blood = "no", shake = false, motion = 2.5, ui = 3, extra = "x" }) :: any
	assert(clean.sfx == 1 and clean.blood == true and clean.shake == false and clean.motion == 1 and clean.ui == 3 and clean.extra == nil, "junk settings kept")
	assert(ProgressService.cleanSettings("nope") == nil, "a string became settings")
	-- The dead monitor switch (10 Nov 2026, the owner): OFF unless chosen, also for an old profile
	-- that kept the old ON default under 'monitor'; ON kept when chosen.
	assert(clean.deadMon == false, "the dead monitor is on without being chosen")
	assert((ProgressService.cleanSettings({ monitor = true }) :: any).deadMon == false, "an old saved monitor = true turned the dead monitor on")
	assert((ProgressService.cleanSettings({ deadMon = true }) :: any).deadMon == true, "the dead monitor switched on was not kept")
	ProgressService.requestForTest(p, "Settings", { sfx = 2, blood = false, shake = true, motion = 3, ui = 2, deadMon = true })
	local s = profile.settings
	assert(s and s.sfx == 2 and s.blood == false and s.motion == 3 and s.ui == 2, "a settings request was not kept")
	assert((s :: any).deadMon == true, "the dead monitor switch was not kept with the profile")
	assert(ProgressService.saveNowForTest(p), "saving failed")
	local kept = (ProgressService.storedForTest(p) :: any).settings
	assert(kept and kept.sfx == 2 and kept.blood == false, "settings were not saved")
	local back = ProgressService.clean({ settings = { sfx = 3, blood = true, shake = false, motion = 1, ui = 1 } }) :: any
	assert(back.settings.sfx == 3 and back.settings.shake == false, "stored settings were not read back")
	ProgressService.requestForTest(p, "Settings", { sfx = 1, blood = true, shake = true, motion = 1, ui = 1 })
	table.insert(results, "SETTINGS: junk cleaned to the defaults, a request kept in the profile and the save, read back")
end

return {
	name = "menu-boards-time-settings",
	timeout = 30,
	run = function(): string?
		local results = {}
		boards(results)
		merging(results)
		local p = Players:GetPlayers()[1]
		if p then
			local started = os.clock()
			while not ProgressService.isLoaded(p) and os.clock() - started < 10 do
				task.wait(0.1)
			end
			player(results, p)
		else
			table.insert(results, "player checks skipped (no player)")
		end
		return table.concat(results, "; ")
	end,
}
