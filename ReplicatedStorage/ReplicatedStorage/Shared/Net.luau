--!strict
-- Remote lookup. The server creates remotes at startup (Script Sync carries only scripts);
-- clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local Net = {}

Net.Names = table.freeze({
	HitRequest = "HitRequest",
	Fx = "Fx",
	Onboarding = "Onboarding",
	DummyCmd = "DummyCmd", -- server -> owner client: Hit / Push / Reset
	Topology = "Topology", -- owner client -> server: state changes of simulated dummies
	FxRelay = "FxRelay", -- owner client -> server: effects of its own simulation, for the others
	CleanUp = "CleanUp", -- client -> server: remove all my props
	PropCmd = "PropCmd", -- server -> prop owner client: Push (blasts and wind reach props you simulate)
	BuildRequest = "BuildRequest", -- RemoteFunction, client -> server: workshop operations
	BuildState = "BuildState", -- server -> client: mode, piece count, playing, messages
	BuildSignal = "BuildSignal", -- client -> server: pressed a button / a sensor saw a dummy
	BuildStore = "BuildStore", -- RemoteFunction, client -> server: save slots and share codes
	Body = "Body", -- both ways: your own avatar as a ragdoll (client: State; server: Knock / Limp / GetUp)
	EventState = "EventState", -- server -> clients: the running event (who set it off, until when) and the queue
	EventBuy = "EventBuy", -- client -> server: open the purchase prompt for an event (or run it, in Studio)
	EventNotice = "EventNotice", -- server -> one client: what happened to your event (queued #n, queue full, wait)
	ToyRefused = "ToyRefused", -- server -> one client: why a tool use was refused (so the tap is never silent)
	Loadout = "Loadout", -- both ways: the client sets its tool bar ("Set"), the server restores it on join ("Load")
	DummyBlame = "DummyBlame", -- simulating client -> server: whose thing just sent one of its dummies flying
	Hold = "Hold", -- client -> server: the tool now picked (a held one shows in the avatar's hand)
	PlayerGrab = "PlayerGrab", -- both ways: grabber Grab / Throw / Drop, held Wriggle; server Held / Free / Holding / Refused (phase D)
	Progress = "Progress", -- both ways: client Open (an egg) / Wear (a hat) / Hello; server State / Egg / Rank / Opened
	Minigame = "Minigame", -- server -> clients: the arena game's state (phase F)
	Friends = "Friends", -- both ways: client LabInvite / Pranks / Nuke / Prank / Join / Hello; server State / Hit / Sent / Incoming / Refused
	Horde = "Horde", -- server -> clients: the co-op horde (warning, start, how many left, end)
	Streamer = "Streamer", -- both ways: client Mode / Action / Hello; server Mode / Ran / NextTool / Hello / Refused
	Money = "Money", -- both ways: client Buy / Admin / SeenNew / Hello; server Owned / Free / FreeOver / WhatsNew / Admin / Refused
	Travel = "Travel", -- both ways: client asks to go to a place; server answers Arrived / Refused
	HitInfo = "HitInfo", -- server -> the hitter: what was hit, the body's blood and pulse (one short line)
	Weapons = "Weapons", -- both ways: client Buy (a weapon id); server Bought / Refused
	Shot = "Shot", -- client -> server: a gun fired at nothing (the ground, a wall, the air)
	Portal = "Portal", -- both ways: client List / PlayNow / Join / Own / Solo; server Open / List / Going / Refused (round 5)
	Ammo = "Ammo", -- client -> server: Reload (a gun id) early with R (round 5; HitService counts rounds)
	Trial = "Trial", -- both ways: client Try (a weapon id); server Started / Refused (round 5, TrialService)
	Sandbox = "Sandbox", -- client -> server: SlowMo / Revive / Reset (round 5, SandboxService; own lab only)
	Rewards = "Rewards", -- both ways: client Hello / ClaimGroup; server State (round 5, RewardsService)
	Session = "Session", -- client -> server: Hello (device, screen, boot time) / EggCard / FirstShot (round 5, SessionStats)
	Aim = "Aim", -- client -> server (unreliable, ~10/s): where your gun points (pitch, yaw); the server shares it as the character's Aim attribute
	Experiment = "Experiment", -- server -> client: Card (def, count, ends) / Done (stars) / Late; client -> server: Skip (phase 1)
	Economy = "Economy", -- both ways: client Hello / BuyNext / Redeem; server State (phase 2: bolts, journal, daily, codes)
	Admin = "Admin", -- both ways, the owner only: client Theme (and M8's tricks); server Theme / Refused
})

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if RunService:IsServer() then
		local f = Instance.new("Folder")
		f.Name = FOLDER_NAME
		f.Parent = ReplicatedStorage
		return f
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Net.event(name: string): RemoteEvent
	local f = folder()
	local existing = f:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	if RunService:IsServer() then
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = f
		return e
	end
	return f:WaitForChild(name) :: RemoteEvent
end

-- An unreliable remote (often-sent, losable: the aim of a gun).
function Net.unreliable(name: string): UnreliableRemoteEvent
	local f = folder()
	local existing = f:FindFirstChild(name)
	if existing and existing:IsA("UnreliableRemoteEvent") then
		return existing
	end
	if RunService:IsServer() then
		local e = Instance.new("UnreliableRemoteEvent")
		e.Name = name
		e.Parent = f
		return e
	end
	return f:WaitForChild(name) :: UnreliableRemoteEvent
end

function Net.func(name: string): RemoteFunction
	local f = folder()
	local existing = f:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end
	if RunService:IsServer() then
		local fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = f
		return fn
	end
	return f:WaitForChild(name) :: RemoteFunction
end

return Net
