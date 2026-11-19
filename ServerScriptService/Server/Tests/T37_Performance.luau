--!strict
-- No lag (round 3, M1): the budgets the game holds itself to, measured where a test can measure
-- them. A dummy is light (what it never uses is taken off before it is sent to every client); the
-- server keeps its pace with 120 dummies in the world shared as in a live game of 10 labs (the 60
-- lab dummies are computed by the devices of their labs' owners: here the one player in Studio has
-- them, standing, since Studio runs that player's device in the same process as the server), the
-- server's own bodies (the plaza's people, a horde, an event's bodies: SERVER_BUSY of them besides the
-- walking people) knocked about all the time, the rest standing (a stress beyond the game, reported);
-- and, with the 120 still there, at the busiest the game gets: a horde charging the plaza while a
-- Dummy Rain and a Mega Bomb go off (pace and the network budget held here).

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Systems = ServerScriptService:WaitForChild("Server"):WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local EventService = require(Systems:WaitForChild("EventService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local HordeService = require(Systems:WaitForChild("HordeService"))

local DUMMY_BUDGET = 220 -- instances in one dummy (an avatar rig straight from Roblox has about 320)
local PACE_FLOOR = 55 -- Hz the server's heartbeat keeps on average at the game's busiest (the owner's goal)
local STRESS_FLOOR = 50 -- Hz it keeps in the stress beyond anything the game does (reported, with headroom)
local CROWD = 120 -- dummies on the ground at once
local LAB_SHARE = 60 -- of them, computed by players' devices (10 labs of 6)
local SERVER_BUSY = 24 -- new bodies on the server knocked about all the time (with its 12 walking
-- people: more than the game ever has there at once, a horde of 11 and a Dummy Rain of 8 included)
local WORST_STEP = 0.1 -- s: no step longer than this

local NET_BUDGET = 50 -- KB/s the server may send each player
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local lastSend = { avg = 0, peak = 0 } -- KB/s per player over the last pace()

-- The server's heartbeat over a few seconds: average Hz and the longest step (and what it sends,
-- per player, at its most).
local function pace(seconds: number): (number, number)
	local n, sum, worst = 0, 0, 0
	local sendSum, sendN, sendPeak = 0, 0, 0
	local c = RunService.Heartbeat:Connect(function(dt)
		n += 1
		sum += dt
		worst = math.max(worst, dt)
		local send = Stats.DataSendKbps / math.max(#Players:GetPlayers(), 1)
		sendSum += send
		sendN += 1
		sendPeak = math.max(sendPeak, send)
	end)
	task.wait(seconds)
	c:Disconnect()
	lastSend = { avg = sendSum / math.max(sendN, 1), peak = sendPeak }
	return n / math.max(sum, 0.001), worst
end

return {
	name = "performance-light-dummies-server-pace",
	timeout = 90,
	run = function(): string?
		-- (Run on its own it may start while the server is still building the world: it waits for
		-- the labs and for the start-up work to pass, as a live server has long before a load.)
		while Workspace:GetAttribute("LabOrigin") == nil do
			task.wait(0.2)
		end
		while Workspace.DistributedGameTime < 20 do
			task.wait(0.5)
		end
		local origin = Workspace:GetAttribute("LabOrigin") :: Vector3
		local model = DummyFactory.spawn(origin + Vector3.new(30, 0, 120))
		local count = #model:GetDescendants()
		model:Destroy()
		assert(count <= DUMMY_BUDGET, string.format("a dummy has %d instances (budget %d)", count, DUMMY_BUDGET))
		local calmHz = pace(2)
		-- 120 dummies: the ones already here and a grid of new ones in the plaza.
		local dummies = Workspace:FindFirstChild("Dummies")
		local have = if dummies then #dummies:GetChildren() else 0
		local extra: { Model } = {}
		local busyCount = 0
		local owner = Players:GetPlayers()[1]
		local ownedNow = 0
		if dummies then
			for _, m in dummies:GetChildren() do
				if m:GetAttribute("LabOwner") then
					ownedNow += 1
				end
			end
		end
		for i = 0, math.max(0, CROWD - have) - 1 do
			local at = origin + Vector3.new(-72 + (i % 17) * 9, 0, 50 + math.floor(i / 17) * 9) -- (9 studs apart: the plaza's people and a horde never stand closer)
			local byPlayer = owner ~= nil and ownedNow + i < LAB_SHARE
			local m = DummyFactory.spawn(at, at + Vector3.new(0, 0, -10), if byPlayer then owner else nil)
			if not byPlayer then
				busyCount += 1
				m:SetAttribute("T37Busy", busyCount <= SERVER_BUSY or nil)
			end
			table.insert(extra, m)
		end
		task.wait(3) -- (settled on their feet)
		-- The server's own never idle: a third of them knocked about every half second while it is
		-- measured (bodies falling, getting up, walking back home), so none of them sleeps.
		local busy = true
		task.spawn(function()
			local rng = Random.new(7)
			while busy do
				for i, m in extra do
					if m.Parent and m:GetAttribute("T37Busy") == true and (i + math.floor(os.clock() * 2)) % 3 == 0 then
						local pelvis = m:FindFirstChild("LowerTorso")
						local mass = (m:GetAttribute("Mass") :: number?) or 10
						if pelvis and pelvis:IsA("BasePart") then
							local dir = Vector3.new(rng:NextNumber(-1, 1), 0.3, rng:NextNumber(-1, 1)).Unit
							DummyControl.hit(m, pelvis, dir * 34 * mass, pelvis.Position)
						end
					end
				end
				task.wait(0.5)
			end
		end)
		local serverBodies = math.min(busyCount, SERVER_BUSY)
		local crowdHz, crowdWorst = pace(6)
		busy = false
		local crowdSend = lastSend
		local crowdCount = if dummies then #dummies:GetChildren() else #extra
		-- (Checked after everything is cleared away below: a failure leaves nothing for later tests.)
		-- The busiest the game itself gets: a horde of runners charging the plaza while a Dummy Rain
		-- and a Mega Bomb go off (the network budget is held here; the stress above is reported).
		HordeService.start(0)
		task.wait(1)
		EventService.trigger("DummyRain", "Test", "Test", true)
		task.wait(1.5)
		EventService.trigger("MegaBomb", "Test", "Test", true)
		local busyHz, worst = pace(8)
		local busySend = lastSend
		HordeService.stopForTest()
		for _, m in extra do
			m:Destroy()
		end
		assert(crowdHz >= STRESS_FLOOR, string.format("the server fell to %.1f Hz with %d dummies knocked about", crowdHz, crowdCount))
		assert(crowdWorst <= WORST_STEP, string.format("a server step took %.0f ms with %d dummies", crowdWorst * 1000, crowdCount))
		assert(busyHz >= PACE_FLOOR, string.format("the server fell to %.0f Hz under a horde, a Dummy Rain and a Mega Bomb", busyHz))
		assert(worst <= WORST_STEP, string.format("a server step took %.0f ms under load", worst * 1000))
		assert(busySend.avg <= NET_BUDGET, string.format("the server sent %.1f KB/s per player under a horde, the rain and the bomb (peak %.1f)", busySend.avg, busySend.peak))
		return string.format("a dummy is %d instances (budget %d); server %.0f Hz calm, %.0f Hz with %d dummies in the world, the server's %d new bodies (and its 12 walking people) knocked about all the time (longest step %.0f ms), %.0f Hz under a horde, a Dummy Rain and a Mega Bomb (longest step %.0f ms); the server sent each player %.1f KB/s under the horde, the rain and the bomb (peak %.1f, budget %d), and %.1f (peak %.1f) in the stress of %d bodies knocked about all the time, more than the game ever has", count, DUMMY_BUDGET, calmHz, crowdHz, crowdCount, serverBodies, crowdWorst * 1000, busyHz, worst * 1000, busySend.avg, busySend.peak, NET_BUDGET, crowdSend.avg, crowdSend.peak, serverBodies)
	end,
}
