--!strict
-- V9-2c (owner, 21 Nov 2026: "Z opens a small menu where you turn time faster or slower in a bubble round
-- yourself"; Config.TIME_DIAL): SandboxService.setTime and Client/SlowMotion.
--   * bad speeds, sizes and flags are refused; outside your own lab it is refused;
--   * in your lab the bubble comes on with its speed and size, and follows you;
--   * a dummy launched inside at 0.25x stays in the air about 4x as long as outside (+-15 %), at 2x
--     less, and back to normal once the bubble is off.
-- The fall is measured on real bodies, which the player's own client simulates (as live).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

return {
	name = "T157_TimeBubble",
	timeout = 90,
	run = function(): string?
		if not Config.TIME_DIAL then
			return "skipped (TIME_DIAL off)"
		end
		local SandboxService = require(Systems:WaitForChild("SandboxService")) :: any
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
		local character = p.Character :: Model
		local home = character:GetPivot()
		local function wait()
			task.wait(SandboxService.TIME_GAP + 0.05)
		end
		local airtimes: { [string]: number } = {}
		local spans: { [string]: number } = {} -- (seen falling until near the floor, s)
		local ok, err = pcall(function()
			SandboxService.resetForTest(p)
			-- Bad requests.
			for _, bad in { { 0.33, 20, true }, { 0.25, 99, true }, { 0.25, 20, "yes" }, { "0.25", 20, true } } do
				wait()
				local got, why = SandboxService.setTime(p, bad[1], bad[2], bad[3])
				assert(got == nil and why == "bad request", "a bad time request was not refused: " .. tostring(why))
			end
			-- Outside your lab: refused.
			character:PivotTo(CFrame.new(Lab.plazaOrigin() + Vector3.new(0, 4, 20)))
			task.wait(0.4)
			wait()
			local outside, whyOut = SandboxService.setTime(p, 0.25, 20, true)
			assert(outside == nil and whyOut == "not your lab", "a bubble came on outside the player's lab: " .. tostring(whyOut))
			-- In your lab: on, with its speed and size, following you.
			local origin = Lab.originFor(p)
			character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, 0)))
			task.wait(0.5)
			wait()
			assert(SandboxService.setTime(p, 0.25, 20, true) == "on", "the bubble did not come on in the player's lab")
			local bubble = SandboxService.bubbleOf(p)
			assert(bubble and bubble:GetAttribute("Scale") == 0.25 and bubble:GetAttribute("Radius") == 20 and p:GetAttribute("TimeScale") == 0.25, "the bubble has the wrong speed or size")
			character:PivotTo(CFrame.new(origin + Vector3.new(12, 4, 0)))
			task.wait(0.5)
			assert(((bubble :: BasePart).Position - (origin + Vector3.new(12, 4, 0))).Magnitude < 4, "the bubble does not follow the player")
			character:PivotTo(CFrame.new(origin + Vector3.new(0, 4, 0)))
			task.wait(0.4)
			-- Airtime of a dummy launched straight up beside the player (simulated by their client).
			local DummyFactory = require(Systems:WaitForChild("DummyFactory")) :: any
			local DummyControl = require(Systems:WaitForChild("DummyControl")) :: any
			local peaks: { [string]: number } = {}
			local function airtime(name: string): number
				local at = origin + Vector3.new(6, 4, 0)
				local dummy = DummyFactory.spawn(at, origin, p)
				local pelvis = dummy:WaitForChild("LowerTorso") :: BasePart
				local t0 = os.clock()
				while dummy:GetAttribute("SimulatedBy") ~= p.UserId and os.clock() - t0 < 4 do
					task.wait(0.1)
				end
				task.wait(1.2) -- (settled on the floor)
				local floorY = pelvis.Position.Y
				-- Dropped DROP studs up. Every new position the server sees on the way down (after the
				-- top, above the floor's reach) is fitted to y = c0 + c1 t + c2 t^2: the gravity it fell
				-- with is -2 c2, whatever the replication delay or speed at the first sighting.
				-- Returned: the time a full DROP-stud fall takes at that gravity.
				local DROP = 16
				DummyControl.reset(dummy, dummy:GetPivot() + Vector3.new(0, DROP, 0))
				local t1 = os.clock()
				local samples: { { t: number, y: number } } = {}
				local maxY, lastY = -math.huge, math.huge
				while os.clock() - t1 < 10 do
					RunService.Heartbeat:Wait()
					local y = pelvis.Position.Y
					local now = os.clock() - t1
					local falling = maxY > floorY + DROP * 0.6 and y < maxY - 0.3
					if not falling and #samples == 0 then
						maxY = math.max(maxY, y)
					elseif y <= floorY + 4.5 then
						break
					elseif y ~= lastY then
						table.insert(samples, { t = now, y = y })
					end
					lastY = y
				end
				local why = string.format("the dropped dummy (%s) was seen falling only %d times: %.1f studs over the floor", name, #samples, pelvis.Position.Y - floorY)
				dummy:Destroy()
				assert(#samples >= 3, why)
				spans[name] = samples[#samples].t - samples[1].t
				-- Least squares for a parabola (normal equations, 3x3, by Cramer).
				local n, st, st2, st3, st4, sy, sty, st2y = #samples, 0, 0, 0, 0, 0, 0, 0
				local t0s = samples[1].t
				for _, smp in samples do
					local t = smp.t - t0s
					st += t
					st2 += t * t
					st3 += t * t * t
					st4 += t * t * t * t
					sy += smp.y
					sty += t * smp.y
					st2y += t * t * smp.y
				end
				local function det(a: number, b: number, c: number, d: number, e: number, f: number, gg: number, h: number, i: number): number
					return a * (e * i - f * h) - b * (d * i - f * gg) + c * (d * h - e * gg)
				end
				local D = det(n, st, st2, st, st2, st3, st2, st3, st4)
				local c2 = det(n, st, sy, st, st2, sty, st2, st3, st2y) / D
				local g = -2 * c2
				peaks[name] = g
				return math.sqrt(2 * DROP / math.max(g, 0.01))
			end
			wait()
			assert(SandboxService.setTime(p, 0.25, 20, false) == "off", "the bubble did not go off")
			task.wait(0.3)
			airtimes.normal = airtime("normal")
			wait()
			SandboxService.setTime(p, 0.25, 20, true)
			task.wait(0.3)
			airtimes.slow = airtime("slow")
			wait()
			SandboxService.setTime(p, 2, 20, true)
			task.wait(0.3)
			airtimes.fast = airtime("fast")
			wait()
			SandboxService.setTime(p, 2, 20, false)
			task.wait(0.3)
			airtimes.after = airtime("after")
			local ratio = airtimes.slow / airtimes.normal
			assert(ratio > 4 * 0.85 and ratio < 4 * 1.15, string.format("at 0.25x a fall takes %.2f s (g %.0f) against %.2f s (g %.0f) outside (%.2fx, want 4x +-15%%)", airtimes.slow, peaks.slow or 0, airtimes.normal, peaks.normal or 0, ratio))
			-- (2x: too quick for the server's interpolated view to fit a curve; the time it is seen falling is shorter.)
			assert(spans.fast < spans.normal * 0.8, string.format("at 2x it was seen falling %.2f s against %.2f s", spans.fast, spans.normal))
			assert(math.abs(airtimes.after / airtimes.normal - 1) < 0.25, string.format("after the bubble it fell in %.2f s against %.2f s", airtimes.after, airtimes.normal))
		end)
		SandboxService.setTime(p, 0.25, 20, false)
		SandboxService.resetForTest(p)
		character:PivotTo(home)
		assert(ok, err)
		return string.format("bad speeds/sizes/flags and a stranger's ground refused; on in the lab with its speed and size, following the player; a 16-stud fall %.2f s outside, %.2f s at 0.25x (%.1fx), seen falling %.2f s at 2x against %.2f s, %.2f s after", airtimes.normal, airtimes.slow, airtimes.slow / airtimes.normal, spans.fast or 0, spans.normal or 0, airtimes.after)
	end,
}
