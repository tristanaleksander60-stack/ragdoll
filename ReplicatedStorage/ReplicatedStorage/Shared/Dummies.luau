--!strict
-- Small helpers every system that touches dummies shares (server and client):
--   Dummies.of(part)        the dummy a part belongs to, if any
--   Dummies.gate()          a per-dummy cooldown ("has this dummy been hit in the last n seconds?")
--   Dummies.blame(model)    who last sent this dummy flying, and when (set by the server)
--   Dummies.finite(v)       a Vector3 from a client is a real, sane number

local Workspace = game:GetService("Workspace")

local Dummies = {}

-- How long a dummy that was sent flying still counts as "sent by" that player (it can knock them
-- over when it lands on them; nobody else).
Dummies.BLAME_TIME = 5

function Dummies.of(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:GetAttribute("IsDummy") == true then
			return model
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- A cooldown per dummy. The table is strong (weak Instance keys get dropped at random) and forgets
-- dummies that are gone, so it stays small.
function Dummies.gate(): (model: Model, cooldown: number) -> boolean
	local last: { [Model]: number } = {}
	return function(model: Model, cooldown: number): boolean
		local now = os.clock()
		local t = last[model]
		if t and now - t < cooldown then
			return false
		end
		last[model] = now
		for m in last do
			if not m.Parent then
				last[m] = nil
			end
		end
		return true
	end
end

-- Who last hit, threw, blew up or blew on this dummy (user id, 0 = nobody: an event, a test), and
-- the server time it happened. On a client, what that client's own simulation did since (a prop
-- contact, a throw) counts too: it is newer than anything the server has heard of yet.
function Dummies.blame(model: Model): (number, number)
	local who = (model:GetAttribute("HitBy") :: number?) or 0
	local at = (model:GetAttribute("HitAt") :: number?) or -math.huge
	local localAt = model:GetAttribute("LocalHitAt") :: number?
	if localAt and localAt > at then
		return (model:GetAttribute("LocalHitBy") :: number?) or 0, localAt
	end
	return who, at
end

-- Whether a dummy is flying because of this player (and recently enough to still count).
function Dummies.sentBy(model: Model, userId: number): boolean
	local who, at = Dummies.blame(model)
	return who == userId and Workspace:GetServerTimeNow() - at < Dummies.BLAME_TIME
end

-- Client: the simulating client's own moment (only that client sees the attribute).
function Dummies.blameLocal(model: Model, userId: number)
	model:SetAttribute("LocalHitBy", userId)
	model:SetAttribute("LocalHitAt", Workspace:GetServerTimeNow())
end

-- Server: records who is behind a hit or push (replicates to every client). Pushes arrive many
-- times a second; the attribute only changes when the player changes or half a second passed.
function Dummies.setBlame(model: Model, userId: number)
	local now = Workspace:GetServerTimeNow()
	local who, at = Dummies.blame(model)
	if who == userId and now - at < 0.5 then
		return
	end
	model:SetAttribute("HitBy", userId)
	model:SetAttribute("HitAt", now)
end

function Dummies.finite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

return Dummies
