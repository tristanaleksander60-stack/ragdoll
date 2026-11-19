--!strict
-- Grab and throw other players in the plaza: this client's two sides (phase D; the server's
-- PlayerGrab checks every step).
--
--   You grab: with Grab picked, hold the left button on a player near you in the plaza (phone: aim
--     the dot, GRAB). They hang in front of you; let go (THROW on a phone) to throw them where you
--     look, or tap DROP to put them down.
--   You are grabbed: you go limp in front of them; jump three times to wriggle free. You are let
--     go after a few seconds anyway, and nobody can grab you again straight after landing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Zones = require(Shared:WaitForChild("Zones"))
local Config = require(Shared:WaitForChild("Config"))
-- (Release 0.20: friends in a Prank Party may toss each other inside its lab too: Zones.mayGrab.)
local PARTY_THROWS = Config.PARTY_THROWS == true and Config.PRANK_PARTY == true

local Client = script.Parent
local PlayerBody = require(Client:WaitForChild("PlayerBody"))
local Toast = require(Client:WaitForChild("Toast"))
local FxController = require(Client:WaitForChild("FxController"))

local player = Players.LocalPlayer

local PlayerGrabClient = {}

local REACH = 14 -- studs (the server checks the same)
local AIM_RANGE = 60
local PENDING_FOR = 1.2 -- s an asked-for grab waits for the server's answer
local GREEN = Color3.fromRGB(120, 230, 140)

local remote: RemoteEvent
local pendingSince = -math.huge
local releaseWanted = false -- let go before the server's answer came: throw the moment it comes
local holding: { target: Player, highlight: Highlight, a0: Attachment?, a1: Attachment? }? = nil
local lastRefusal = -math.huge
local toldHow = false

local function myRoot(): BasePart?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

local function look(): Vector3
	return Workspace.CurrentCamera.CFrame.LookVector
end

local function clearHolding()
	local h = holding
	if not h then
		return
	end
	holding = nil
	h.highlight:Destroy()
	if h.a0 then
		h.a0:Destroy()
	end
	if h.a1 then
		h.a1:Destroy()
	end
end

local function showHolding(target: Player)
	clearHolding()
	local character = target.Character
	if not character then
		return
	end
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.85
	highlight.FillColor = GREEN
	highlight.OutlineColor = GREEN
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = character
	highlight.Parent = character
	local a0, a1 = nil, nil
	local mine = player.Character
	local hand = mine and (mine:FindFirstChild("RightHand") or mine:FindFirstChild("HumanoidRootPart"))
	local chest = character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
	if hand and hand:IsA("BasePart") and chest and chest:IsA("BasePart") then
		a0 = Instance.new("Attachment")
		a0.Name = "GrabTether"
		a0.Parent = hand
		a1 = Instance.new("Attachment")
		a1.Name = "GrabTether"
		a1.Parent = chest
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 0.18
		beam.Width1 = 0.1
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Segments = 12
		beam.CurveSize0 = 2
		beam.Transparency = NumberSequence.new(0.15, 0.45)
		beam.Color = ColorSequence.new(GREEN)
		beam.Parent = a0
	end
	holding = { target = target, highlight = highlight, a0 = a0, a1 = a1 }
end

-- The other player under this viewport point, if they could be grabbed from here.
local function playerAt(screen: Vector2): Player?
	local root = myRoot()
	if not root or (not Zones.isPlaza(root.Position) and player:GetAttribute("PartyLab") == nil) then
		return nil
	end
	local camera = Workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character :: Instance)
	end
	local fx = Workspace:FindFirstChild("LocalFx")
	if fx then
		table.insert(ignore, fx)
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * AIM_RANGE, params)
	if not hit then
		return nil
	end
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	local other = model and Players:GetPlayerFromCharacter(model)
	if not other or other == player then
		return nil
	end
	local theirs = model and model:FindFirstChild("HumanoidRootPart")
	if not theirs or not theirs:IsA("BasePart") or not Zones.mayGrab(player, other, root.Position, theirs.Position, PARTY_THROWS) then
		return nil
	end
	if (theirs.Position - root.Position).Magnitude > REACH then
		if os.clock() - lastRefusal > 4 then
			lastRefusal = os.clock()
			Toast.show("Too far away. Walk closer to grab them")
		end
		return nil
	end
	return other
end

-- A press with Grab picked that found no dummy: a player there? Asks the server; true if asked.
function PlayerGrabClient.tryAt(screen: Vector2): boolean
	if holding or PlayerBody.isHeld() or PlayerBody.isDown() or os.clock() - pendingSince < PENDING_FOR then
		return false
	end
	local other = playerAt(screen)
	if not other then
		return false
	end
	pendingSince = os.clock()
	releaseWanted = false
	remote:FireServer("Grab", other)
	return true
end

-- True while holding a player, or waiting for the server to say so.
function PlayerGrabClient.busy(): boolean
	return holding ~= nil or os.clock() - pendingSince < PENDING_FOR
end

function PlayerGrabClient.isHolding(): boolean
	return holding ~= nil
end

function PlayerGrabClient.throw()
	if holding then
		remote:FireServer("Throw", look())
		local h = holding
		local c = h and h.target.Character
		local chest = c and c:FindFirstChild("UpperTorso")
		if chest and chest:IsA("BasePart") then
			FxController.localEvent("Hit", chest.Position, 90, "Throw")
		end
		clearHolding()
	elseif os.clock() - pendingSince < PENDING_FOR then
		releaseWanted = true
	end
end

function PlayerGrabClient.drop()
	if holding then
		remote:FireServer("Drop")
		clearHolding()
	end
	pendingSince = -math.huge
end

PlayerGrabClient.onChanged = nil :: (() -> ())? -- GrabController's pad (GRAB / DROP)

local function changed()
	local f = PlayerGrabClient.onChanged
	if f then
		f()
	end
end

function PlayerGrabClient.start()
	remote = Net.event(Net.Names.PlayerGrab)
	PlayerBody.onWriggle = function()
		remote:FireServer("Wriggle")
	end
	remote.OnClientEvent:Connect(function(kind: unknown, arg: unknown)
		if kind == "Held" and typeof(arg) == "Instance" and (arg :: Instance):IsA("Player") then
			local grabber = arg :: Player
			if PlayerBody.setHeld(grabber) then
				-- (A phone hides the jump button while the body is limp: RAGDOLL is the button there.)
				local how = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
					then "Tap RAGDOLL 3 times" else "Jump 3 times"
				Toast.show(grabber.DisplayName .. " grabbed you! " .. how .. " to wriggle free")
			else
				-- (Cannot hang now: the lab view. Ask to be let go as soon as the server allows.)
				task.delay(1.3, function()
					remote:FireServer("Wriggle")
				end)
			end
		elseif kind == "Holding" and typeof(arg) == "Instance" and (arg :: Instance):IsA("Player") then
			pendingSince = -math.huge
			showHolding(arg :: Player)
			local root = myRoot()
			if root then
				FxController.localEvent("Hit", root.Position, 8, "Grab")
			end
			if releaseWanted then
				releaseWanted = false
				PlayerGrabClient.throw()
			elseif not toldHow then
				toldHow = true
				Toast.show("Got them! Let go to throw them where you look")
			end
			changed()
		elseif kind == "Free" then
			if PlayerBody.isHeld() then
				PlayerBody.freeHeld(if typeof(arg) == "Vector3" then arg :: Vector3 else nil)
			end
			clearHolding()
			pendingSince = -math.huge
			changed()
		elseif kind == "Refused" and type(arg) == "string" then
			pendingSince = -math.huge
			if os.clock() - lastRefusal > 3 then
				lastRefusal = os.clock()
				Toast.show(arg :: string)
			end
			changed()
		end
	end)
end

return PlayerGrabClient
