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
	NpcCommand = "NpcCommand", -- both ways (v4 B4): server Open (talked to) / Done; client Follow / Stay / Attack / Bye
	VehicleAction = "VehicleAction", -- client -> server: the action string of the vehicle you drive (Boost, Jump, Siren, Spray, Blade); checked in VehicleService (you sit in a lab vehicle whose kind has that feature, 1 every 0.35 s) (F76)
	Advent = "Advent", -- client -> server: "State" or "Open" (nothing else read; 1 a second); server -> client: "State" {day, opened, next}, "Opened" {door, text}, "Refused" why (AUDIT 27 Nov 2, Systems/AdventService)
	Cpr = "Cpr", -- server -> client: Start (the body); client -> server: Result (the body, the good beats 0-5); checked in PlayerCPR (your open session, that body, 2.5-15 s after the start, within 15 studs, once) (3.34)
	VehicleHorn = "VehicleHorn", -- client -> server (v4 C2): the driver honks (server checks the seat, plays the car's Horn)
	HitInfo = "HitInfo", -- server -> the hitter: what was hit, the body's blood and pulse (one short line)
	Weapons = "Weapons", -- both ways: client Buy (a weapon id); server Bought / Refused
	Shot = "Shot", -- client -> server: a gun fired at nothing (the ground, a wall, the air)
	Portal = "Portal", -- both ways: client List / PlayNow / Join / Own / Solo; server Open / List / Going / Refused (round 5)
	Ammo = "Ammo", -- client -> server: Reload (a gun id) early with R (round 5; HitService counts rounds)
	Boo = "Boo", -- client -> server: the ragdoll you BOO (MILD_EXTRAS C3); checked in BooMask (a living ragdoll within 7 studs that faces away, once every 1.5 s)
	Trial = "Trial", -- both ways: client Try (a weapon id); server Started / Refused (round 5, TrialService)
	Sandbox = "Sandbox", -- client -> server: SlowMo / Revive / Reset (round 5, SandboxService; own lab only); V9-2c: Time (speed, size, on) for the time bubble (SandboxService.setTime: listed speeds and sizes, paced, own or party lab)
	Rewards = "Rewards", -- both ways: client Hello / ClaimGroup; server State (round 5, RewardsService)
	Session = "Session", -- client -> server: Hello (device, screen, boot time) / EggCard / FirstShot (round 5, SessionStats)
	GuardDog = "GuardDog", -- client -> server: Bite (ragdoll, limb) / Home; server -> client: GoodBoy (GUARD_DOG, Systems/GuardDog)
	Stunt = "Stunt", -- server -> client: Begin / Live (score) / Land (score, tricks, best); client -> server: Again (V8-1.1, StuntScore)
	Spawn = "Spawn", -- client -> server: Spawn (type, at), V9-0l SpawnMany (type, at, pattern, count, spacing, yaw), Clear, Claim, Seen, Try; server -> client: Refused (why), Granted (first | asked | chip) (V8-2.5, DummySpawn)
	Aim = "Aim", -- client -> server (unreliable, ~10/s): where your gun points (pitch, yaw); the server shares it as the character's Aim attribute
	Experiment = "Experiment", -- server -> client: Card (def, count, ends) / Done (stars) / Late; client -> server: Skip (phase 1)
	Offers = "Offers", -- client -> server: Buy (an offer key); server -> client: Refused (release 0.20.0, OfferService)
	Economy = "Economy", -- both ways: client Hello / BuyNext / Redeem; server State (phase 2: bolts, journal, daily, codes)
	Admin = "Admin", -- both ways, the owner only: client Theme (and M8's tricks); server Theme / Refused
	Terminal = "Terminal", -- client -> server: Press (the terminal's screen part); checked in LabGuide (owner or party, within reach, 4 a second, a queue of 6) (V9-2b)
	Teleport = "Teleport", -- client -> server: Spawn (no arguments; F80 BACK TO SPAWN, Systems/BackToSpawn: a 5 s cooldown, the server picks the spot)
	PathSwap = "PathSwap", -- client -> server: (position Vector3, look Vector3) a path walker you come near or aim at becomes a real ragdoll in its place (F90, Systems/PathSwap: on a walkway within 70 studs of you, 1 per 1.5 s); server -> client: (position, model) the real one now stands there
	CameraView = "CameraView", -- client -> server (unreliable): the camera's position and look, twice a second (OVERVIEW 0.158 the "in view" report); checked in RagdollDirector (Vector3s, finite, within 400 studs of the character, a unit look, at most 4 a second)
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
