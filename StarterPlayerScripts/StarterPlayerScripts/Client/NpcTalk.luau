--!strict
-- v4 B4: the talk panel. Press E (pad: L3, the prompt's own key) on an NPC (the server's Talk
-- prompt) and this small card opens right of the crosshair:
--   FOLLOW ME / STAY HERE / ATTACK… / BYE (once it is yours) / CLOSE
-- ATTACK asks who (the nearest others) and with what (your bar's weapons first; the server sorts
-- them). BACK goes up one page; CLOSE, Escape or pad B shut it. It also shuts by itself when you
-- walk away (TALK_REACH), respawn or change place. The server (NpcCommand) checks every choice; a
-- refusal shows as a toast. The Talk prompts are hidden on this screen in the lab view and in Build
-- (E turns the camera / picks the next part there).

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local TalkRules = require(Shared:WaitForChild("TalkRules")) -- (V9-0a: a hit never opens Talk)
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))
local ViewMode = require(Client:WaitForChild("ViewMode"))

local NpcTalk = {}

NpcTalk.TALK_REACH = 16 -- studs: further from the NPC the panel shuts
NpcTalk.CLOSE_ACTION = "NpcTalkClose"
NpcTalk.attacked = function() end :: () -> () -- (V9-0a: set in start; hides the Talk prompts after an attack)

local player = Players.LocalPlayer
local remote: RemoteEvent
local gui: ScreenGui
local list: Frame
local title: TextLabel
local current: Model? = nil
local firstButton: GuiObject? = nil
local firstOrder = math.huge
local buildActive: (() -> boolean)? = nil
local lastAttack = -math.huge -- (os.clock of the last click, tap, R2 or own shot: TalkRules)
local isGrabbing: (() -> boolean)? = nil

local BUTTON_W, BUTTON_H = 260, 44

local function clear()
	firstButton = nil
	firstOrder = math.huge
	for _, c in list:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
end

local function close()
	if not gui.Enabled then
		return
	end
	gui.Enabled = false
	current = nil
	clear()
	ContextActionService:UnbindAction(NpcTalk.CLOSE_ACTION)
	local selected = GuiService.SelectedObject
	if selected and selected:IsDescendantOf(gui) then
		GuiService.SelectedObject = nil
	end
end

local function button(text: string, role: string, order: number, onActivated: () -> ())
	local b = C.Button({ text = text, role = role, size = UDim2.fromOffset(BUTTON_W, BUTTON_H), layoutOrder = order, parent = list, onActivated = onActivated })
	if order < firstOrder then
		firstOrder = order
		firstButton = b.hit
	end
end

-- After a page is drawn: a pad selects its first button.
local function focus()
	if UserInputService.GamepadEnabled then
		task.defer(function()
			local b = firstButton
			if gui.Enabled and b and b.Parent then
				GuiService.SelectedObject = b
			end
		end)
	end
end

local pageMain: (data: any) -> ()

local function pageWeapons(data: any, target: any)
	clear()
	title.Text = "WITH WHAT?"
	local shown = 0
	for _, id in if type(data.weapons) == "table" then data.weapons else {} do
		local toy = Toys.byId[id]
		if toy and shown < 5 then
			shown += 1
			button(string.upper(toy.short or toy.label), "danger", shown, function()
				remote:FireServer("Attack", data.npc, target.model, id)
				close()
			end)
		end
	end
	button("BACK", "neutral", 9, function()
		pageMain(data)
	end)
	focus()
end

local function pageTargets(data: any)
	clear()
	title.Text = "ATTACK WHO?"
	for i, t in if type(data.targets) == "table" then data.targets else {} do
		if i > 4 then
			break
		end
		button(string.upper(tostring(t.name)), "neutral", i, function()
			pageWeapons(data, t)
		end)
	end
	button("BACK", "neutral", 9, function()
		pageMain(data)
	end)
	focus()
end

pageMain = function(data: any)
	clear()
	title.Text = string.upper(tostring(data.name or "Dummy"))
	local function send(action: string)
		remote:FireServer(action, data.npc)
		close()
	end
	button("FOLLOW ME", "go", 1, function()
		send("Follow")
	end)
	button("STAY HERE", "neutral", 2, function()
		send("Stay")
	end)
	local targets = if type(data.targets) == "table" then data.targets else {}
	local weapons = if type(data.weapons) == "table" then data.weapons else {}
	if #targets > 0 and #weapons > 0 then
		button("ATTACK…", "danger", 3, function()
			pageTargets(data)
		end)
	end
	if data.mode ~= nil then
		button("LET GO", "neutral", 4, function()
			send("Bye")
		end)
	end
	button("CLOSE", "neutral", 5, close)
	focus()
end

local function open(data: any)
	if type(data) ~= "table" or typeof(data.npc) ~= "Instance" or not (data.npc :: Instance):IsA("Model") then
		return
	end
	-- (V9-0a: a prompt that fired in the middle of a fight is ignored.)
	if not TalkRules.mayOpen(os.clock(), lastAttack) then
		return
	end
	current = data.npc :: Model
	gui.Enabled = true
	pageMain(data)
	ContextActionService:BindActionAtPriority(NpcTalk.CLOSE_ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			close()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 50, Enum.KeyCode.ButtonB, Enum.KeyCode.Escape)
end

-- The Talk prompts show only where E is free (not in the lab view or Build), and (V9-0a,
-- TalkRules) not during a fight: after a click, tap, R2 or shot, while Grab holds a body, and on
-- touch only while you stand still.
local function promptsAllowed(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local v = if root and root:IsA("BasePart") then root.AssemblyLinearVelocity else Vector3.zero
	return TalkRules.show({
		now = os.clock(),
		lastAttack = lastAttack,
		touch = ViewMode.isTouch(),
		speed = Vector3.new(v.X, 0, v.Z).Magnitude,
		grabbing = isGrabbing ~= nil and isGrabbing(),
		viewOk = not ViewMode.isLab() and not (buildActive and buildActive()),
	})
end

local function setPrompt(p: ProximityPrompt, allowed: boolean)
	-- (Local only: hides it on this screen. The server's "Talkable" says whether it can be used.)
	p.Enabled = allowed and p:GetAttribute("Talkable") ~= false
	-- (Not clickable with a mouse; on touch a short hold, so a quick tap meant as a hit never talks.)
	local clickable, hold = TalkRules.promptStyle(ViewMode.isTouch())
	p.ClickablePrompt = clickable
	p.HoldDuration = hold
end

function NpcTalk.start()
	remote = Net.event(Net.Names.NpcCommand)
	pcall(function()
		local BuildController = require(Client:WaitForChild("BuildController", 5)) :: any
		buildActive = BuildController.isActive
	end)
	pcall(function()
		isGrabbing = (require(Client:WaitForChild("GrabController", 5)) :: any).isGrabbing
	end)
	gui = Instance.new("ScreenGui")
	gui.Name = "NpcTalk"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- (the kit's buttons layer by siblings)
	gui.Enabled = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local card = Instance.new("Frame")
	card.Name = "Card"
	-- (Right of the crosshair, so the aim point and the touch fire area stay free.)
	card.AnchorPoint = Vector2.new(0, 0.5)
	card.Position = UDim2.new(0.5, 48, 0.5, 0)
	card.Size = UDim2.fromOffset(BUTTON_W + 28, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.Palette.dusk or Color3.fromRGB(24, 28, 44)
	card.BackgroundTransparency = 0.05
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = card
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = card
	title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 0
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromOffset(BUTTON_W, 26)
	title.FontFace = Theme.Fonts.display
	title.TextSize = 22
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = card
	list = Instance.new("Frame")
	list.Name = "List"
	list.LayoutOrder = 1
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromOffset(BUTTON_W, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list
	list.Parent = card
	-- (Short or narrow screens: the card shrinks to fit. Its tallest page is about 360 px, and it
	-- needs half the width plus 48 px.)
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local function fit()
		local cam = Workspace.CurrentCamera
		local view = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min((view.Y - 40) / 360, (view.X / 2 - 60) / (BUTTON_W + 28)), 0.6, 1)
	end
	fit()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	card.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "Open" then
			open(data)
		elseif kind == "Refused" and type(data) == "table" and type(data.text) == "string" then
			Toast.show(data.text, Color3.fromRGB(255, 140, 110))
		elseif kind == "Done" and type(data) == "table" then
			local words = { Follow = "Following you!", Stay = "Staying here.", Attack = "On it!", Bye = "Off they go." }
			local w = words[tostring(data.action)]
			if w then
				Toast.show(w)
			end
		end
	end)
	-- Shut on respawn and on a change of place.
	player.CharacterAdded:Connect(close)
	player:GetAttributeChangedSignal("Place"):Connect(close)
	-- New prompts follow the current mode.
	local allowed = promptsAllowed()
	local folder = Workspace:WaitForChild("Dummies", 30)
	if folder then
		folder.DescendantAdded:Connect(function(d)
			if d:IsA("ProximityPrompt") and d.Name == "TalkPrompt" then
				setPrompt(d, allowed)
				d:GetAttributeChangedSignal("Talkable"):Connect(function()
					setPrompt(d, allowed)
				end)
			end
		end)
		for _, d in folder:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Name == "TalkPrompt" then
				setPrompt(d, allowed)
				d:GetAttributeChangedSignal("Talkable"):Connect(function()
					setPrompt(d, allowed)
				end)
			end
		end
	end
	-- V9-0a: an attack hides every Talk prompt at once; the check below brings them back after
	-- TalkRules' quiet time.
	local function attacked()
		lastAttack = os.clock()
		if allowed and folder then
			allowed = false
			for _, d in folder:GetDescendants() do
				if d:IsA("ProximityPrompt") and d.Name == "TalkPrompt" then
					setPrompt(d, false)
				end
			end
		end
	end
	NpcTalk.attacked = attacked -- (tests and other attack paths)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and TalkRules.isAttack(input.UserInputType, input.KeyCode) then
			attacked()
		end
	end)
	pcall(function()
		(require(Client:WaitForChild("FeelBus", 5)) :: any).on("Shot", function(data: any)
			if type(data) == "table" and data.own then
				attacked()
			end
		end)
	end)
	-- Shut when you walk away or the NPC goes; the prompts follow the camera mode.
	local checkAt = 0
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now < checkAt then
			return
		end
		checkAt = now + 0.25
		if gui.Enabled then
			local npc = current
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local pelvis = npc and npc.Parent and npc:FindFirstChild("LowerTorso")
			if not (root and root:IsA("BasePart") and pelvis and pelvis:IsA("BasePart")) or (root.Position - pelvis.Position).Magnitude > NpcTalk.TALK_REACH then
				close()
			end
		end
		local nowAllowed = promptsAllowed()
		if nowAllowed ~= allowed and folder then
			allowed = nowAllowed
			for _, d in folder:GetDescendants() do
				if d:IsA("ProximityPrompt") and d.Name == "TalkPrompt" then
					setPrompt(d, allowed)
				end
			end
		end
	end)
end

return NpcTalk
