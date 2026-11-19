--!strict
-- Tagged logging so output can be filtered from LogService and the MCP console.
-- Usage: local log = Log.new("Ragdoll"); log.info("hit", 12)

local RunService = game:GetService("RunService")

local Log = {}

export type Logger = {
	info: (...any) -> (),
	warn: (...any) -> (),
}

local side = if RunService:IsServer() then "S" else "C"

function Log.new(tag: string): Logger
	local prefix = string.format("[%s][%s]", side, tag)
	return {
		info = function(...: any)
			print(prefix, ...)
		end,
		warn = function(...: any)
			warn(prefix, ...)
		end,
	}
end

return Log
