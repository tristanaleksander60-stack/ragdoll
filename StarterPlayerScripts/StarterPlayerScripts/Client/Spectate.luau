--!strict
-- SPECTATE (10 Nov 2026, the owner's admin menu): the owner's camera follows another player in
-- this server, into their own lab too (PlotPrivacy.setPeek shows that lab on this screen only; the
-- server streams the world around them, AdminService). A bar at the bottom says who is watched,
-- with NEXT (the next player here) and STOP. The owner's own avatar stays where it is. Only the
-- admin window (owner only) starts it; switching to the lab view stops it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Zones = require(Shared:WaitForChild("Zones"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Theme = require(UI:WaitForChild("LihFolkUITheme"))

local Client = script.Parent
local PlotPrivacy = require(Client:WaitForChild("PlotPrivacy"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local PokeController = require(Client:WaitForChild("PokeController"))
local Toast = require(Client:WaitForChild("Toast"))

local Spectate = {}

local player = Players.LocalPlayer
local target: Player? = nil
local viewBefore: string? = nil
local gui: ScreenGui? = nil
local nameLabel: TextLabel? = nil
local follow: RBXScriptConnection? = nil
local switching = false
local lastPeekCheck = 0

local function admin(): RemoteEvent
	return Net.event(Net.Names.Admin)
end

local function ownHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function buildBar()
	local g = Instance.new("ScreenGui")
	g.Name = "Spectate"
	g.ResetOnSpawn = false
	g.DisplayOrder = 40
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	g.Enabled = false
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Size = UDim2.new(1, -24, 0, 60) -- (380 wide, less on a narrow screen)
	local most = Instance.new("UISizeConstraint")
	most.MaxSize = Vector2.new(380, 60)
	most.Parent = bar
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Parent = bar
	bar.BackgroundColor3 = Theme.Palette.dusk
	bar.BackgroundTransparency = 0.05
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.card)
	corner.Parent = bar
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Palette.gold
	stroke.Thickness = 2
	stroke.Parent = bar
	local label = Instance.new("TextLabel")
	label.Name = "Who"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -220, 1, 0)
	label.FontFace = Theme.Fonts.display
	label.TextScaled = true
	label.TextColor3 = Theme.Palette.textHi
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "WATCHING"
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 20
	fit.Parent = label
	label.Parent = bar
	nameLabel = label
	local nextButton = C.Button({
		text = "NEXT",
		role = "neutral",
		size = UDim2.fromOffset(96, 44),
		parent = bar,
		onActivated = function()
			Spectate.next()
		end,
	})
	nextButton.root.AnchorPoint = Vector2.new(1, 0.5)
	nextButton.root.Position = UDim2.new(1, -112, 0.5, 0)
	local stopButton = C.Button({
		text = "STOP",
		role = "danger",
		size = UDim2.fromOffset(92, 44),
		parent = bar,
		onActivated = function()
			Spectate.stop()
		end,
	})
	stopButton.root.AnchorPoint = Vector2.new(1, 0.5)
	stopButton.root.Position = UDim2.new(1, -10, 0.5, 0)
	bar.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
end

local function placeBar()
	local g = gui
	if not g then
		return
	end
	local bar = g:FindFirstChild("Bar")
	if bar and bar:IsA("Frame") then
		bar.Position = UDim2.new(0.5, 0, 1, -(PokeController.height() + 12))
	end
end

-- Every frame while watching: the camera on them, their lab shown (looked up twice a second).
local function step()
	local who = target
	if not who or not who.Parent then
		Spectate.stop()
		return
	end
	local camera = workspace.CurrentCamera
	local character = who.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if camera and humanoid then
		if camera.CameraType ~= Enum.CameraType.Custom and camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Custom
		end
		if camera.CameraSubject ~= humanoid then
			camera.CameraSubject = humanoid
		end
	end
	if os.clock() - lastPeekCheck > 0.5 then
		lastPeekCheck = os.clock()
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local plot = if root and root:IsA("BasePart") then Zones.plotAt(root.Position) else nil
		if root == nil then
			-- (Not streamed in yet, or hidden on this screen in a lab: their own lab first.)
			local own = who:GetAttribute("LabPlot")
			plot = if type(own) == "number" and own > 0 then own else nil
		end
		PlotPrivacy.setPeek(if plot and plot > 0 then plot else nil)
	end
end

function Spectate.isWatching(): Player?
	return target
end

function Spectate.watch(who: Player)
	if who == player or not who.Parent then
		return
	end
	if not gui then
		buildBar()
	end
	if not target then
		viewBefore = ViewMode.get()
	end
	target = who
	switching = true
	if ViewMode.isLab() then
		ViewMode.set("Player") -- (the walk camera follows a subject; the lab view does not)
	end
	switching = false
	admin():FireServer("Spectate", who.UserId)
	local label = nameLabel
	if label then
		label.Text = "WATCHING " .. string.upper(who.DisplayName)
	end
	placeBar()
	local g = gui :: ScreenGui
	if not g.Enabled then
		-- In with a small pop (none under Reduced Motion).
		local bar = g:FindFirstChild("Bar")
		local pop = bar and bar:FindFirstChild("Pop")
		if pop and pop:IsA("UIScale") and not Theme.isReducedMotion() then
			pop.Scale = 0.85
			TweenService:Create(pop, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end
	g.Enabled = true
	lastPeekCheck = 0
	if not follow then
		follow = RunService.RenderStepped:Connect(step)
	end
end

function Spectate.stop()
	if not target then
		return
	end
	target = nil
	if follow then
		follow:Disconnect()
		follow = nil
	end
	if player:GetAttribute("SpectateTarget") ~= nil then
		Net.event(Net.Names.Portal):FireServer("Solo") -- (come only to watch: back to a server of your own)
	end
	PlotPrivacy.setPeek(nil)
	admin():FireServer("Spectate", nil)
	local camera = workspace.CurrentCamera
	local humanoid = ownHumanoid()
	if camera and humanoid then
		camera.CameraSubject = humanoid
	end
	if gui then
		gui.Enabled = false
	end
	local before = viewBefore
	viewBefore = nil
	if before == "Lab" then
		ViewMode.set("Lab")
	end
end

-- The next player here (by join order), round and round.
function Spectate.next()
	local others = {}
	for _, p in Players:GetPlayers() do
		if p ~= player then
			table.insert(others, p)
		end
	end
	if #others == 0 then
		Toast.show("Nobody else is here")
		Spectate.stop()
		return
	end
	local at = if target then table.find(others, target) else nil
	Spectate.watch(others[((at or 0) % #others) + 1])
end

function Spectate.start()
	-- (23 Nov 2026: the owner sent into someone's singleplayer server watches them at once.)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 30 do
			local id = player:GetAttribute("SpectateTarget")
			local who = if type(id) == "number" then Players:GetPlayerByUserId(id) else nil
			if who and who.Character then
				Spectate.watch(who)
				return
			end
			if type(id) ~= "number" and os.clock() - t0 > 5 then
				return
			end
			task.wait(0.5)
		end
		if player:GetAttribute("SpectateTarget") ~= nil then
			Toast.show("They left")
			Net.event(Net.Names.Portal):FireServer("Solo")
		end
	end)
	ViewMode.onChanged(function()
		if target and not switching and ViewMode.isLab() then
			Spectate.stop() -- (the owner went to the lab view: the watching ends)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if p == target then
			Toast.show(p.DisplayName .. " left")
			task.defer(Spectate.next)
		end
	end)
end

return Spectate
