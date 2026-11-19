--!strict
-- Round 3, M7: the Christmas theme.
--   the season by date: on from the owner's first day (7 November 2026) to 6 January, then every
--     year 1 December - 6 January; ON and OFF win over the date
--   on: the plaza dressed (snow on the ground, the tree with its lights and star, presents, a
--     garland on every lamp, snow on the boards and the plaza sign), every dummy in a Santa hat and scarf (the ones
--     that came back during the suite too); off: all of it gone, nothing left behind
--   the switch is the owner's only (refused for anyone else, junk refused), and it says the state
--   a present drop: an egg for the first present a player opens, nothing for a second in that drop
--   the dressing is cheap: a few hundred parts at most, none of them simulated

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Christmas = require(Shared:WaitForChild("Christmas"))
local Systems = script.Parent.Parent:WaitForChild("Systems")
local ChristmasService = require(Systems:WaitForChild("ChristmasService"))
local AdminService = require(Systems:WaitForChild("AdminService"))
local ProgressService = require(Systems:WaitForChild("ProgressService"))
local Owner = require(Systems:WaitForChild("Owner"))

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

local function d(y: number, m: number, day: number)
	return { year = y, month = m, day = day }
end

local function dates(results: { string })
	local cases = {
		-- (Phase 3: Config.CHRISTMAS_FROM_DEC1 moves the first day to 1 December 2026.)
		{ d(2026, 11, 6), false }, { d(2026, 11, 7), Christmas.FIRST_START.month == 11 }, { d(2026, 12, 24), true },
		{ d(2026, 11, 30), Christmas.FIRST_START.month == 11 }, { d(2026, 12, 1), true },
		{ d(2027, 1, 6), true }, { d(2027, 1, 7), false }, { d(2027, 6, 1), false },
		{ d(2027, 11, 30), false }, { d(2027, 12, 1), true }, { d(2028, 1, 6), true },
		{ d(2028, 1, 7), false }, { d(2026, 1, 3), false }, { d(2025, 12, 25), false },
	}
	for _, c in cases do
		local date, want = c[1] :: any, c[2]
		local got = Christmas.isOn("auto", date)
		assert(got == want, string.format("%d-%02d-%02d is %s, should be %s", date.year, date.month, date.day, tostring(got), tostring(want)))
		assert(Christmas.isOn("on", date) == true and Christmas.isOn("off", date) == false, "ON or OFF did not win over the date")
	end
	assert(not Christmas.validMode("ON") and not Christmas.validMode(nil) and not Christmas.validMode(1) and Christmas.validMode("auto"), "a junk mode was valid")
	table.insert(results, #cases .. " dates right (7 Nov 2026 - 6 Jan, then 1 Dec - 6 Jan), ON and OFF win")
end

local function count(folder: Instance): (number, number)
	local parts, loose = 0, 0
	for _, x in folder:GetDescendants() do
		if x:IsA("BasePart") then
			parts += 1
			if not x.Anchored and x.AssemblyRootPart == x then
				loose += 1
			end
		end
	end
	return parts, loose
end

local function dressed(on: boolean): number
	local dummies = Workspace:FindFirstChild("Dummies")
	local n = 0
	if dummies then
		for _, body in dummies:GetChildren() do
			if body:IsA("Model") and body:FindFirstChild("Head") then
				local hat = body:FindFirstChild("XmasHat")
				local ownHat = false -- (a chef, a guard or a tourist keeps their own hat)
				local outfit = body:FindFirstChild("Outfit")
				if outfit then
					for _, name in { "ChefHat", "Cap", "GuardCap", "BucketHat", "HatTop" } do
						if outfit:FindFirstChild(name) then
							ownHat = true
						end
					end
					-- (Hair too tall for a Santa hat counts too: ChristmasService.hasOwnHat, TallHair.)
					for _, item in outfit:GetChildren() do
						if item:IsA("Accessory") and item:GetAttribute("TallHair") == true then
							ownHat = true
						end
					end
				end
				if on and ownHat then
					assert(not hat, body.Name .. " wears a Santa hat on top of its own hat")
					assert(body:FindFirstChild("XmasScarf"), body.Name .. " has no scarf")
					n += 1
				elseif on then
					assert(hat and hat:GetAttribute("Worn") == true, body.Name .. " has no Santa hat")
					assert(body:FindFirstChild("XmasScarf") or not body:FindFirstChild("UpperTorso"), body.Name .. " has no scarf")
					n += 1
				else
					assert(not hat and not body:FindFirstChild("XmasScarf"), body.Name .. " still wears Christmas")
				end
			end
		end
	end
	return n
end

local function plazaOn(): (number, number)
	assert(Workspace:GetAttribute("Christmas") == true, "the Christmas attribute is not on")
	local f = Workspace:FindFirstChild("Christmas")
	assert(f, "no Christmas folder")
	assert(f:FindFirstChild("SnowGround"), "no snow on the ground")
	local tree = f:FindFirstChild("Tree")
	assert(tree, "no tree")
	local lights, star = 0, false
	for _, x in tree:GetDescendants() do
		if x:IsA("PointLight") then
			star = true
		elseif x:IsA("BasePart") and x.Material == Enum.Material.Neon then
			lights += 1
		end
	end
	assert(lights >= 20 and star, string.format("the tree has %d lights, star %s", lights, tostring(star)))
	local presents, garlands, caps = 0, 0, 0
	for _, x in f:GetChildren() do
		if x.Name == "Present" then
			presents += 1
		elseif x.Name == "Garland" then
			garlands += 1
		elseif x.Name == "SnowCap" then
			caps += 1
		end
	end
	assert(presents >= 8, presents .. " presents under the tree")
	assert(garlands >= 1, "no garlands on the lamps")
	local boards = Workspace:FindFirstChild("Boards")
	assert(not boards or caps == #boards:GetChildren(), caps .. " snow caps on the boards")
	assert(f:FindFirstChild("SignSnow"), "no snow on the plaza sign")
	local parts, loose = count(f)
	assert(parts <= 400 and loose == 0, string.format("the dressing is %d parts, %d loose", parts, loose))
	return parts, garlands
end

return {
	name = "christmas-theme",
	timeout = 40,
	run = function(): string?
		local results = {}
		dates(results)
		local p = Players:GetPlayers()[1]
		local ok, err = pcall(function()
			-- Today (7 November 2026 or later in the season) it is on, from the start of the suite.
			ChristmasService.setDateForTest(d(2026, 12, 1)) -- (in the season either way: phase 3)
			local parts, garlands = plazaOn()
			local worn = dressed(true)
			table.insert(results, string.format("on: the plaza dressed (%d parts, none loose; %d garland beads on the lamps), %d dummies in hats and scarves", parts, garlands, worn))
			-- Off by date, on again.
			ChristmasService.setDateForTest(d(2027, 1, 7))
			assert(Workspace:GetAttribute("Christmas") == false and not Workspace:FindFirstChild("Christmas"), "7 January left the dressing up")
			dressed(false)
			ChristmasService.setDateForTest(d(2027, 12, 1))
			plazaOn()
			dressed(true)
			table.insert(results, "off by date (7 Jan): everything gone; on again by date (1 Dec)")
			if p then
				-- The switch: the owner's only.
				Owner.studioOwnerForTest = false
				AdminService.resetPaceForTest(p)
				assert(not AdminService.request(p, "Theme", "off"), "a non-owner switched the theme")
				Owner.studioOwnerForTest = true
				assert(ChristmasService.isOn(), "a refused request changed the theme")
				AdminService.resetPaceForTest(p)
				assert(not AdminService.request(p, "Theme", "OFF!"), "a junk mode was taken")
				AdminService.resetPaceForTest(p)
				assert(AdminService.request(p, "Theme", "off"), "the owner could not switch it off")
				assert(not ChristmasService.isOn() and not Workspace:FindFirstChild("Christmas") and Workspace:GetAttribute("ChristmasMode") == "off", "OFF did not take it down")
				dressed(false)
				assert(not AdminService.request(p, "Theme", "on"), "a second request inside the gap was taken")
				AdminService.resetPaceForTest(p)
				ChristmasService.setDateForTest(d(2027, 6, 1))
				assert(AdminService.request(p, "Theme", "on") and ChristmasService.isOn(), "ON did not win over June")
				plazaOn()
				-- Choices from other servers: the newest wins, an older one never takes it back.
				local now = Workspace:GetServerTimeNow()
				assert(not ChristmasService.adoptForTest({ mode = "off", at = now - 100 }) and ChristmasService.mode() == "on", "an older choice took over")
				assert(not ChristmasService.adoptForTest("off") and ChristmasService.mode() == "on", "an old plain choice took over")
				assert(not ChristmasService.adoptForTest({ mode = "nope", at = now + 5 }), "junk from another server was taken")
				assert(ChristmasService.adoptForTest({ mode = "off", at = now + 5 }) and ChristmasService.mode() == "off" and not ChristmasService.isOn(), "a newer choice from another server was not taken")
				ChristmasService.setMode("on")
				table.insert(results, "the switch: refused for a non-owner, junk and a flood refused; OFF takes it down, ON wins over June; from other servers the newest choice wins, an older or junk one never")

				-- A present drop: one egg per player per drop.
				local profile = ProgressService.profileForTest(p) :: any
				assert(profile, "no profile")
				local eggsBefore = profile.eggs
				profile.eggs = 0
				local gifts = ChristmasService.drop(2)
				assert(#gifts == 2, #gifts .. " presents dropped")
				assert(Workspace:GetAttribute("GiftDrop") == gifts[1]:GetAttribute("Drop"), "the drop was not told to the screens")
				for _, g in gifts do
					assert(g.Parent and g:GetAttribute("Drop"), "a dropped present is not in the plaza")
				end
				assert(ChristmasService.open(p, gifts[1]) and profile.eggs == 1, "the first present gave no egg")
				assert(not ChristmasService.open(p, gifts[2]) and profile.eggs == 1, "a second present in the same drop gave an egg")
				assert(gifts[1].Parent == nil and gifts[2].Parent ~= nil, "an opened present stayed, or a second one was used up for nothing")
				assert(not ChristmasService.open(p, gifts[1]), "an opened present opened again")
				-- Full egg slots: nothing, and the player is not marked (a present after making room gives).
				local Progress = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Progress"))
				local full = ChristmasService.drop(2)
				profile.eggs = Progress.MAX_EGGS
				assert(not ChristmasService.open(p, full[1]) and profile.eggs == Progress.MAX_EGGS and full[1].Parent ~= nil, "a present gave past the full slots, or was used up")
				profile.eggs = 1
				assert(ChristmasService.open(p, full[1]) and profile.eggs == 2, "after making room the same present gave no egg")
				-- The real way: a present falls and the player touches it.
				local r = (p.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
				local touched = ChristmasService.drop(1)[1]
				local box = touched.PrimaryPart :: BasePart
				box.AssemblyLinearVelocity = Vector3.zero
				touched:PivotTo(r.CFrame)
				assert(waitFor(function()
					return touched.Parent == nil
				end, 3) and profile.eggs == 3, "touching a present did not open it")
				-- Never in the tree: 40 drops' spots all clear of its foot.
				local tree = (Workspace:FindFirstChild("Christmas") :: Instance):FindFirstChild("Tree") :: Model
				local foot = tree:GetPivot().Position
				local floorParams = RaycastParams.new()
				floorParams.FilterType = Enum.RaycastFilterType.Exclude
				floorParams.FilterDescendantsInstances = { Workspace:FindFirstChild("Christmas") :: Instance, Workspace:FindFirstChild("Dummies") :: Instance, p.Character :: Instance }
				local mid = Workspace:Raycast(Vector3.new(foot.X + 22, foot.Y + 30, foot.Z), Vector3.new(0, -60, 0), floorParams)
				local floorY = if mid then mid.Position.Y else foot.Y
				for _ = 1, 8 do
					for _, g in ChristmasService.drop(5) do
						local at = (g.PrimaryPart :: BasePart).Position
						assert(Vector3.new(at.X - foot.X, 0, at.Z - foot.Z).Magnitude > 12, "a present dropped into the tree")
						local below = Workspace:Raycast(Vector3.new(at.X, foot.Y + 30, at.Z), Vector3.new(0, -60, 0), floorParams)
						assert(below and math.abs(below.Position.Y - floorY) < 0.3, "a present dropped onto something (" .. (if below then below.Instance:GetFullName() else "nothing") .. ")")
						g:Destroy()
					end
				end
				profile.eggs = eggsBefore
				table.insert(results, "presents: an egg for the first one a player opens in a drop, nothing for a second (told), none past full slots (told, and the player can still get it after making room), touching one opens it; 40 drops all onto the open floor (never the tree, the fountain, a bench, a sign or a lamp); a present nobody can take an egg from is left for the others")
			else
				table.insert(results, "switch and present checks skipped (no player)")
			end
		end)
		-- Back as it was: the owner's choice AUTO, today's date.
		Owner.studioOwnerForTest = true
		if p then
			AdminService.resetPaceForTest(p)
		end
		ChristmasService.setMode("auto")
		ChristmasService.setDateForTest(nil)
		assert(ok, err)
		return table.concat(results, "; ")
	end,
}
