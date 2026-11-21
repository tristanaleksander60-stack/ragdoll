--!strict
-- V9-2b / Phase T (owner, 21 Nov 2026: "a little computer terminal you walk up to and press FEED, and spam it
-- if you like"; Config.FEED_TERMINAL):
--   * every guided spot (9 creatures, the stations, the cannon, the lava, the trampoline) has a terminal,
--     with its screen and the E / pad prompt, facing the way you come (towards the spawn);
--   * one press = one dummy sent in;
--   * 20 presses at once: at most TERM_RATE taken in a second, never more than TERM_QUEUE queued;
--   * a press from far away is refused;
--   * with no free dummy, a spare drops from the chute, and the lab's body cap holds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T154_FeedTerminal",
	timeout = 90,
	run = function(): string?
		if not (Config.FEED_TERMINAL and Config.LAB_GUIDE) then
			return "skipped (FEED_TERMINAL or LAB_GUIDE off)"
		end
		local LabGuide = require(Systems:WaitForChild("LabGuide")) :: any
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil and Lab.plotIndex(p) ~= nil
		end, 20)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "skipped (no player with a lab)"
		end
		local lab = Workspace.Playground:FindFirstChild("Lab" .. Lab.plotIndex(p))
		local guide = lab and lab:FindFirstChild("Guide")
		assert(guide, "the lab has no guide")
		local origin = Lab.originFor(p)
		local terminals, rings = {}, 0
		for _, d in (guide :: Instance):GetDescendants() do
			if d:IsA("Model") and d.Name == "FeedTerminal" then
				table.insert(terminals, d)
				local screen = d:FindFirstChild("Screen") :: BasePart?
				local button = d:FindFirstChild("Button")
				-- lihfolk-ignore: findfirstchild-chain (guarded: button and ...)
				assert(screen and button and button:FindFirstChildOfClass("ProximityPrompt"), "a terminal has no screen or no button prompt")
				local toward = Vector3.new(origin.X - (screen :: BasePart).Position.X, 0, origin.Z - (screen :: BasePart).Position.Z)
				local facing = d:GetPivot().LookVector
				assert(toward.Magnitude < 1 or facing:Dot(toward.Unit) > 0.3, tostring(d:GetAttribute("GuideId")) .. "'s terminal does not face the way you come")
			elseif d:IsA("BasePart") and d.Name == LabGuide.TAG then
				rings += 1
			end
		end
		assert(#terminals >= 12 and #terminals == rings, string.format("%d terminals for %d spots", #terminals, rings))
		-- (Fix round 1: no terminal stands in the lava, a trigger box or a creature.)
		for _, d in (lab :: Instance):GetDescendants() do
			local boxCf, boxSize = nil :: CFrame?, nil :: Vector3?
			if d:IsA("BasePart") and (string.find(d.Name, "Trigger", 1, true) or string.find(d.Name, "Lava", 1, true)) then
				boxCf, boxSize = d.CFrame, d.Size
			elseif d:IsA("Model") and d:GetAttribute("Creature") ~= nil then
				boxCf, boxSize = d:GetBoundingBox()
			end
			if boxCf and boxSize then
				for _, t in terminals do
					local rel = boxCf:PointToObjectSpace(t:GetPivot().Position)
					assert(not (math.abs(rel.X) < boxSize.X / 2 and math.abs(rel.Z) < boxSize.Z / 2), tostring(t:GetAttribute("GuideId")) .. "'s terminal stands inside " .. d:GetFullName())
				end
			end
		end
		local results = { string.format("%d terminals, one per spot, facing the way you come", #terminals) }
		local character = p.Character :: Model
		local home = character:GetPivot()
		local held: { Model } = {}
		local ok, err = pcall(function()
			-- A creature's terminal (the spider's if it is there).
			local term = terminals[1]
			for _, t in terminals do
				if t:GetAttribute("GuideId") == "Spider" then
					term = t
				end
			end
			local screen = term:WaitForChild("Screen") :: BasePart
			local stand = term:GetPivot() * CFrame.new(0, 3, -4)
			character:PivotTo(CFrame.lookAt(stand.Position, term:GetPivot().Position + Vector3.new(0, 3, 0)))
			task.wait(1.1) -- (past the last second's presses)
			-- One press = one toss.
			local before = LabGuide.termTossedForTest()
			local took = LabGuide.press(p, screen)
			assert(took, "a press by the lab's player was refused")
			assert(TestLib.waitFor(function()
				return LabGuide.termTossedForTest() == before + 1
			end, 3), "one press did not send one dummy in")
			table.insert(results, "one press, one dummy in")
			-- (Fix round 1: the next press sends another dummy, not the one just thrown.)
			task.wait(0.3)
			LabGuide.press(p, screen)
			task.wait(0.6)
			local thrown = 0
			for _, m in Lab.dummiesOf(p) do
				if ((m:GetAttribute("GuideTossUntil") :: number?) or 0) > os.clock() then
					thrown += 1
				end
			end
			assert(thrown >= 2, thrown .. " different dummies in flight after two presses (want 2)")
			table.insert(results, "two presses, two different dummies")
			-- 20 at once.
			task.wait(1.1)
			local taken = 0
			for _ = 1, 20 do
				if LabGuide.press(p, screen) then
					taken += 1
				end
			end
			local rec = LabGuide.terminalsForTest()[screen]
			assert(taken <= LabGuide.TERM_RATE and taken >= 1, taken .. " of 20 presses in an instant were taken (rate " .. LabGuide.TERM_RATE .. ")")
			assert(rec.queue <= LabGuide.TERM_QUEUE, "the queue grew past " .. LabGuide.TERM_QUEUE)
			assert(screen:GetAttribute("Combo") ~= nil and (screen:GetAttribute("Combo") :: number) >= 2, "the run of presses is no combo")
			table.insert(results, string.format("20 at once: %d taken, combo x%s", taken, tostring(screen:GetAttribute("Combo"))))
			-- Far away: refused.
			task.wait(1.1)
			character:PivotTo(CFrame.new(term:GetPivot().Position + Vector3.new(0, 3, 0) + term:GetPivot().LookVector * (LabGuide.TERM_REACH + 15)))
			task.wait(0.2)
			local farTook, why = LabGuide.press(p, screen)
			assert(not farTook and why == "too far", "a press from far away was taken: " .. tostring(why))
			table.insert(results, "refused from far away")
			-- No free dummy: a spare from the chute, within the cap.
			character:PivotTo(CFrame.lookAt(stand.Position, term:GetPivot().Position + Vector3.new(0, 3, 0)))
			TestLib.waitFor(function()
				return rec.queue == 0
			end, 6)
			task.wait(1.1)
			for _, m in Lab.dummiesOf(p) do
				if m:GetAttribute("InMachine") == nil then
					m:SetAttribute("InMachine", "Test")
					table.insert(held, m)
				end
			end
			local VisitorService = require(Systems:WaitForChild("VisitorService")) :: any
			local cap = VisitorService.capFor(p)
			local spareTook = LabGuide.press(p, screen)
			assert(spareTook, "the press with no free dummy was refused")
			local spare: Model? = nil
			TestLib.waitFor(function()
				for _, d in Workspace:WaitForChild("Dummies"):GetChildren() do
					if d:GetAttribute("Spare") == true then
						spare = d :: Model
						return true
					end
				end
				return false
			end, 3)
			local spareCount = #LabGuide.sparesForTest(p)
			local bodies = #VisitorService.bodiesOf(p) + spareCount
			assert(bodies <= cap and spareCount <= LabGuide.SPARE_MAX, string.format("%d bodies (%d spares) in a lab capped at %d", bodies, spareCount, cap))
			if spare then
				table.insert(results, string.format("no free dummy: a spare from the chute (%d of %d bodies)", bodies, cap))
				spare:Destroy()
			else
				table.insert(results, string.format("no free dummy and the lab full (%d of %d): no spare, the cap held", bodies, cap))
			end
		end)
		for _, m in held do
			if m.Parent and m:GetAttribute("InMachine") == "Test" then
				m:SetAttribute("InMachine", nil)
			end
		end
		character:PivotTo(home)
		assert(ok, err)
		return table.concat(results, "; ")
	end,
}
