--!strict
-- Round 5 (the owner: the gun follows the mouse): each client says where its gun points (pitch and
-- yaw from the body's front, radians; Net Aim, unreliable, about 10 a second) and the server puts it
-- on the character as the attribute Aim (a Vector2), so every screen draws the arm pointing there
-- (AvatarMoves). Nothing else is trusted from it: shots are checked as before (HitService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local AimService = {}

AimService.MAX_RATE = 20 -- messages a second, at most (more are dropped)
AimService.PITCH = 1.3 -- radians up or down, at most
AimService.STEP = 0.02 -- radians: finer changes are not worth an attribute write

local budget: { [Player]: { at: number, n: number } } = {}

local function finite(x: unknown): boolean
	return type(x) == "number" and x == x and x > -math.huge and x < math.huge
end

-- Sets (or clears, with nil) a player's aim. Returns whether the attribute changed.
function AimService.set(player: Player, pitch: number?, yaw: number?): boolean
	local character = player.Character
	if not character then
		return false
	end
	if pitch == nil or yaw == nil then
		if character:GetAttribute("Aim") ~= nil then
			character:SetAttribute("Aim", nil)
			return true
		end
		return false
	end
	local q = AimService.STEP
	local p = math.floor(math.clamp(pitch, -AimService.PITCH, AimService.PITCH) / q + 0.5) * q
	local y = math.floor(math.clamp(yaw, -math.pi, math.pi) / q + 0.5) * q
	local now = Vector2.new(p, y)
	local before = character:GetAttribute("Aim")
	if typeof(before) == "Vector2" and (before :: Vector2 - now).Magnitude < q / 2 then
		return false
	end
	character:SetAttribute("Aim", now)
	return true
end

function AimService.start()
	local remote = Net.unreliable(Net.Names.Aim)
	-- lihfolk-ignore: remote-unvalidated-args (both checked below: nil pair or finite numbers, then clamped in set)
	remote.OnServerEvent:Connect(function(player: Player, pitch: unknown, yaw: unknown)
		local now = os.clock()
		local b = budget[player]
		if not b or now - b.at >= 1 then
			b = { at = now, n = 0 }
			budget[player] = b
		end
		b.n += 1
		if b.n > AimService.MAX_RATE then
			return
		end
		if pitch == nil and yaw == nil then
			AimService.set(player, nil, nil)
		elseif finite(pitch) and finite(yaw) then
			AimService.set(player, pitch :: number, yaw :: number)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		budget[player] = nil
	end)
end

return AimService
