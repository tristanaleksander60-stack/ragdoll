--!strict
-- Server bootstrap. Systems are required from here in a fixed order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Log = require(Shared:WaitForChild("Log"))

local log = Log.new("Boot")
log.info(string.format("%s %s (phase %d) server started", Config.GameName, Config.Version, Config.Phase))
