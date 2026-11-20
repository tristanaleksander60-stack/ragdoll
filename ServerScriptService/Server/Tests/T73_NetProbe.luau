--!strict
-- A measuring tool, not a check (round 3, M9): what the server sends each player during each busy
-- thing alone (calm, a horde, a Dummy Rain, a Mega Bomb), in 2 s steps. Runs only when asked
-- (Studio: ServerStorage "NetProbe" = true); otherwise it reports itself skipped.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local Systems = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Systems")
local EventService = require(Systems:WaitForChild("EventService"))
local HordeService = require(Systems:WaitForChild("HordeService"))

local function measure(seconds: number): string
	local parts = {}
	local t0 = os.clock()
	local bucket, sum, n = 1, 0, 0
	local c = RunService.Heartbeat:Connect(function()
		local s = Stats.DataSendKbps / math.max(#Players:GetPlayers(), 1)
		local b = math.floor((os.clock() - t0) / 2) + 1
		if b ~= bucket then
			table.insert(parts, string.format("%.0f", sum / math.max(n, 1)))
			bucket, sum, n = b, 0, 0
		end
		sum += s
		n += 1
	end)
	task.wait(seconds)
	c:Disconnect()
	table.insert(parts, string.format("%.0f", sum / math.max(n, 1)))
	return table.concat(parts, "/")
end

return {
	name = "net-probe",
	timeout = 120,
	run = function(): string?
		if game:GetService("ServerStorage"):GetAttribute("NetProbe") ~= true then
			return "skipped (a measuring tool: set ServerStorage NetProbe to run it)"
		end
		while Workspace.DistributedGameTime < 25 do
			task.wait(0.5)
		end
		local out = {}
		table.insert(out, "calm " .. measure(4))
		HordeService.start(0)
		table.insert(out, "horde " .. measure(10))
		HordeService.stopForTest()
		task.wait(4)
		table.insert(out, "after " .. measure(4))
		EventService.trigger("DummyRain", "Test", "Test", true)
		table.insert(out, "rain " .. measure(12))
		task.wait(4)
		EventService.trigger("MegaBomb", "Test", "Test", true)
		table.insert(out, "bomb " .. measure(10))
		return table.concat(out, "; ") .. " (KB/s per 2 s)"
	end,
}
